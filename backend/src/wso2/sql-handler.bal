//Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/mysql;
import ballerina/log;
import ballerina/time;
import ballerina/config;
import ballerina/internal;

mysql:Client dashboardDB = new({
        host: config:getAsString("DB_HOST"),
        port: config:getAsInt("DB_PORT"),
        name: config:getAsString("DB_NAME"),
        username: config:getAsString("USERNAME"),
        password: config:getAsString("PASSWORD"),
        poolOptions: { maximumPoolSize: 10 },
        dbOptions: { useSSL: false }
    });


function getAllProductNames() returns (json) {
    var productNames = dashboardDB->select("SELECT PRODUCT_NAME FROM PRODUCT", ());
    if (productNames is table< record {} >) {
        var productNamesJson = json.convert(productNames);
        if (productNamesJson is json) {

            int i = 0;
            while (i < productNamesJson.length()) {
                productNamesJson[i] = productNamesJson[i].PRODUCT_NAME;
                i = i + 1;
            }

            return productNamesJson;
        } else {
            log:printError("Error occured while converting the retrieved product names to json.", err = productNamesJson
            )
            ;
        }
    } else {
        log:printError("Error occured while retrieving the product names from Database.", err = productNames);
    }
}

function getPendingDocTasks(string product, string milestone) returns (json) {
    string sqlQuery = "SELECT COUNT(PR_ID) AS mprCount FROM PRODUCT_PRS WHERE DOC_STATUS IN (0,1,2,3,4) AND" +
        " PRODUCT_ID=(SELECT PRODUCT_ID FROM PRODUCT WHERE PRODUCT_NAME = ? ) AND MILESTONE = ?";
    var prCount = dashboardDB->select(sqlQuery, (), product, milestone);
    if (prCount is table< record {} >) {
        json response = {};

        // Set the reference link
        string stringUrl = string `/portal/dashboards/mprdashboard/home`
            + string `#{"product":"{{product}}","version":"{{milestone}}"}`;

        var count = json.convert(prCount);

        if (count is json) {
            response.mprCount = count[0].mprCount;
            response.refLink = stringUrl;
            return response;
        } else {
            log:printError("Error occured while converting the retrieved " + product + " merged PR count to json.",
                err = count);
        }

    } else {
        log:printError("Error occured while retrieving the " + product + " merged PR count from database.", err =
            prCount);
    }
}

function getDependencySummary(string product) returns (json) {
    string sqlQuery = "SELECT IFNULL(CAST((SUM(DEPENDENCY_SUMMARY.NEXT_VERSION_AVAILABLE) +
		SUM(DEPENDENCY_SUMMARY.NEXT_INCREMENTAL_AVAILABLE) +
        SUM(DEPENDENCY_SUMMARY.NEXT_MINOR_AVAILABLE)) AS SIGNED),0) AS dependencySummary
        FROM DEPENDENCY_SUMMARY,PRODUCT_REPOS,PRODUCT
        WHERE PRODUCT.PRODUCT_NAME=? AND PRODUCT.PRODUCT_ID=PRODUCT_REPOS.PRODUCT_ID AND
            PRODUCT_REPOS.REPO_ID = DEPENDENCY_SUMMARY.REPO_ID;";
    var summary = dashboardDB->select(sqlQuery, (), product);

    if (summary is table< record {} >) {
        var count = json.convert(summary);
        if (count is json) {
            return count[0];
        } else {
            log:printError("Error occured while converting the retrieved " + product + " dependency summary to json.",
                err = count);
        }
    } else {
        log:printError("Error occured while retrieving the " + product + " dependency summary from database.", err =
            summary);
    }
}

function getCodeCoverage(string product) returns (json) {

    string strInstructionCov = "0";
    string strBranchCov = "0";
    string strComplexityCov = "0";
    string strLineCov = "0";
    string strMethodCov = "0";
    string strClassCov = "0";

    json codeCoverage = {};

    string sqlQuery = "SELECT TOTAL_INSTRUCTIONS, MISSED_INSTRUCTIONS, TOTAL_BRANCHES, MISSED_BRANCHES,
                        TOTAL_CXTY, MISSED_CXTY, TOTAL_LINES, MISSED_LINES,
                        TOTAL_METHODS, MISSED_METHODS, TOTAL_CLASSES,MISSED_CLASSES
                        FROM CODE_COVERAGE_SUMMARY, PRODUCT
                        WHERE CODE_COVERAGE_SUMMARY.PRODUCT_ID=PRODUCT.PRODUCT_ID
                        AND PRODUCT_NAME = ? AND
                        CODE_COVERAGE_SUMMARY.DATE LIKE
                        CONCAT('%', (SELECT MAX(DISTINCT CAST(DATE AS DATE)) AS DATE
                                    FROM CODE_COVERAGE_SUMMARY
                                    ORDER BY DATE DESC), '%');";

    var coverage = dashboardDB->select(sqlQuery, (), product);

    if (coverage is table< record {} >) {
        var result = json.convert(coverage);
        if (result is json) {
            if (result.length() > 0) {

                float instructionCov = 0;
                float branchCov = 0;
                float complexityCov = 0;
                float lineCov = 0;
                float methodCov = 0;
                float classCov = 0;

                // Instruction Coverage - casting the data to float
                string strTotInstrutions = result[0].TOTAL_INSTRUCTIONS.toString();
                float|error totInstructions = float.convert(strTotInstrutions);

                string strMissedInstructions = result[0].MISSED_INSTRUCTIONS.toString();
                float|error missedInstructions = float.convert(strMissedInstructions);

                //Instruction Coverage - calculating coverage
                if (totInstructions is float && missedInstructions is float) {
                    instructionCov = ((totInstructions - missedInstructions) / totInstructions) * 100;
                    strInstructionCov = io:sprintf("%.2f", instructionCov);
                }

                //Branch Coverage
                string strTotBranches = result[0].TOTAL_BRANCHES.toString();
                float|error totBranches = float.convert(strTotBranches);

                string strMissedBranches = result[0].MISSED_BRANCHES.toString();
                float|error missedBranches = float.convert(strMissedBranches);

                if (totBranches is float && missedBranches is float) {
                    branchCov = ((totBranches - missedBranches) / totBranches) * 100;
                    strBranchCov = io:sprintf("%.2f", branchCov);
                }

                //Complexity Coverage
                string strTotComplexity = result[0].TOTAL_CXTY.toString();
                float|error totComplexity = float.convert(strTotComplexity);

                string strMissedComplexity = result[0].MISSED_CXTY.toString();
                float|error missedComplexity = float.convert(strMissedComplexity);

                if (totComplexity is float && missedComplexity is float) {
                    complexityCov = ((totComplexity - missedComplexity) / totComplexity) * 100;
                    strComplexityCov = io:sprintf("%.2f", complexityCov);
                }

                //Line Coverage
                string strTotLines = result[0].TOTAL_LINES.toString();
                float|error totLines = float.convert(strTotLines);

                string strMissedLines = result[0].MISSED_LINES.toString();
                float|error missedLines = float.convert(strMissedLines);

                if (totLines is float && missedLines is float) {
                    lineCov = ((totLines - missedLines) / totLines) * 100;
                    strLineCov = io:sprintf("%.2f", lineCov);
                }

                //Method Coverage
                string strTotMethods = result[0].TOTAL_METHODS.toString();
                float|error totMethods = float.convert(strTotMethods);

                string strMissedMethods = result[0].MISSED_METHODS.toString();
                float|error missedMethods = float.convert(strMissedMethods);

                if (totMethods is float && missedMethods is float) {
                    methodCov = ((totMethods - missedMethods) / totMethods) * 100;
                    strMethodCov = io:sprintf("%.2f", methodCov);
                }

                //Class coverage
                string strTotClasses = result[0].TOTAL_CLASSES.toString();
                float|error totClasses = float.convert(strTotClasses);

                string strMissedClasses = result[0].MISSED_CLASSES.toString();
                float|error missedClasses = float.convert(strMissedClasses);

                if (totClasses is float && missedClasses is float) {
                    classCov = ((totClasses - missedClasses) / totClasses) * 100;
                    strClassCov = io:sprintf("%.2f", classCov);
                }
            }
        } else {
            log:printError("Error occured while converting the retrieved " + product + " code coverage to json.",
                err = result);
        }
    } else {
        log:printError("Error occured while retrieving the " + product + " code coverage from database.", err =
            coverage);
    }

    codeCoverage.instructionCov = strInstructionCov;
    codeCoverage.branchCov = strBranchCov;
    codeCoverage.complexityCov = strComplexityCov;
    codeCoverage.lineCov = strLineCov;
    codeCoverage.methodCov = strMethodCov;
    codeCoverage.classCov = strClassCov;
    codeCoverage.refLink = CODE_COVERAGE_DASHBOARD_URL;

    return codeCoverage;
}

//This function will map the given JIRA project to the product name
function mapJiraProjectToProduct(string project) returns (string) {
    string product = "";
    if (project.equalsIgnoreCase(JIRA_APIM)) {
        product = PRODUCT_APIM;
    } else if (project.equalsIgnoreCase(JIRA_IS)) {
        product = PRODUCT_IS;
    } else if (project.equalsIgnoreCase(JIRA_EI)) {
        product = PRODUCT_EI;
    } else if (project.equalsIgnoreCase("ANALYTICSINTERNAL")) {
        product = "Analytics";
    } else if (project.equalsIgnoreCase(JIRA_OB)) {
        product = PRODUCT_OB;
    } else if (project.equalsIgnoreCase("CLOUDINTERNAL")) {
        product = "Cloud";
    }
    return product;
}

//This function will map the given JIRA project to the product name
function mapToProductJiraProject(string product) returns (string) {
    string project = "";
    if (product.equalsIgnoreCase(PRODUCT_APIM)) {
        project = JIRA_APIM;
    } else if (product.equalsIgnoreCase(PRODUCT_IS)) {
        project = JIRA_IS;
    } else if (product.equalsIgnoreCase(PRODUCT_EI)) {
        project = JIRA_EI;
    } else if (product.equalsIgnoreCase("Analytics")) {
        project = "ANALYTICSINTERNAL";
    } else if (product.equalsIgnoreCase(PRODUCT_OB)) {
        project = JIRA_OB;
    } else if (product.equalsIgnoreCase("Cloud")) {
        project = "CLOUDINTERNAL";
    }
    return project;
}
