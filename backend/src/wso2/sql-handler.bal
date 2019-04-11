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
        var count = json.convert(prCount);
        if (count is json) {
            return count[0];
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

function getLineCoverage(string product) returns (json) {
    string sqlQuery = "SELECT FORMAT ( (((TOTAL_LINES-MISSED_LINES)/TOTAL_LINES)*100) , 2  ) AS lineCoverage
                        FROM CODE_COVERAGE_SUMMARY,PRODUCT
                        WHERE CODE_COVERAGE_SUMMARY.PRODUCT_ID=PRODUCT.PRODUCT_ID
                        AND PRODUCT_NAME = ? AND
                        CODE_COVERAGE_SUMMARY.DATE LIKE
                        CONCAT('%', (SELECT MAX(DISTINCT CAST(DATE AS DATE)) AS DATE
                                    FROM CODE_COVERAGE_SUMMARY
                                    ORDER BY DATE DESC), '%');";

    var coverage = dashboardDB->select(sqlQuery, (), product);

    if (coverage is table< record {} >) {
        var count = json.convert(coverage);
        if (count is json) {
            return count[0];
        } else {
            log:printError("Error occured while converting the retrieved " + product + " line coverage to json.",
                err = count);
        }
    } else {
        log:printError("Error occured while retrieving the " + product + " line coverage from database.", err =
            coverage);
    }
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
