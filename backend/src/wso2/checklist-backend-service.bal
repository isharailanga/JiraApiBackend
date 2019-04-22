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

listener http:Listener httpListener = new(6095);

@http:ServiceConfig {
    basePath: "/checklist"
}
service jiraIssueService on httpListener {
    // Resource that handles the HTTP GET requests that are directed to a specific endpoint

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/jiraIssues/{productName}"
    }
    resource function retrieveAllIssuesByProduct(http:Caller caller, http:Request request, string productName) {
        http:Response response = new;

        map<string> filterValues = request.getQueryParams();
        string? labelsString = filterValues["labels"];

        if (labelsString is string) {
            json issueMetaDetails = getIssueMetaDetails(untaint productName, untaint labelsString);
            response.setJsonPayload(untaint issueMetaDetails);
        }

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/versions/{productName}"
    }
    resource function retrieveProductVersions(http:Caller caller, http:Request request, string productName) {
        http:Response response = new;

        json versionArr = getProductVersions(untaint productName);
        json versions = { versions: versionArr };

        response.setJsonPayload(untaint versions);

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/productNames"
    }
    resource function retrieveProductNames(http:Caller caller, http:Request request) {

        http:Response response = new;

        json productNamesArr = getAllProductNames();
        json productNames = { products: productNamesArr };
        response.setJsonPayload(untaint productNames);

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/mprCount/{productName}"
    }
    resource function getPendingDocTaskCount(http:Caller caller, http:Request request, string productName) {

        http:Response response = new;

        map<string> filterValues = request.getQueryParams();
        string? versionString = filterValues["version"];

        if (versionString is string) {
            json count = getPendingDocTasks(productName, versionString);
            response.setJsonPayload(untaint count);
        }

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/dependency/{productName}"
    }
    resource function getDependencySummaryDetails(http:Caller caller, http:Request request, string productName) {
        http:Response response = new;

        json count = getDependencySummary(productName);
        response.setJsonPayload(untaint count);

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/codeCoverage/{productName}"
    }
    resource function getProductCodeCoverage(http:Caller caller, http:Request request, string productName) {
        http:Response response = new;

        json count = getCodeCoverage(productName);
        response.setJsonPayload(untaint count);

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/gitIssues/{productName}"
    }
    resource function getGitIssues(http:Caller caller, http:Request request, string productName) {
        http:Response response = new;

        map<string> filterValues = request.getQueryParams();
        string? versionString = filterValues["version"];

        if (versionString is string) {
            json count = getGitIssueCount(productName, versionString);
            response.setJsonPayload(untaint count);
        }

        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}
