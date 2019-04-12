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

import ballerina/http;
import ballerina/log;
import ballerina/io;

http:Client jiraClientEP = new(JIRA_API);

function getIssueMetaDetails(string productName, string labels) returns (json) {
    http:Request req = new;
    req.addHeader("Authorization", "Basic " + JIRA_AUTH_KEY);

    string reqURL = "/jira/rest/api/2/search";

    string product = mapToProductJiraProject(productName);
    json|error totalIssueCountJson = getTotalIssueCount(reqURL, product, labels, req);
    json|error openIssueCountJson = getOpenIssueCount(reqURL, product, labels, req);

    json issuesMetaDetails = {
        totalIssues: 0,
        openIssues: 0
    };

    if (totalIssueCountJson is json && openIssueCountJson is json) {
        if (totalIssueCountJson.total == null) {
            totalIssueCountJson.total = 0;
        }
        if (openIssueCountJson.total == null) {
            openIssueCountJson.total = 0;
        }
        issuesMetaDetails.totalIssues = totalIssueCountJson.total;
        issuesMetaDetails.openIssues = openIssueCountJson.total;
        issuesMetaDetails.refLink = openIssueCountJson.jql;
        return issuesMetaDetails;
    } else {
        log:printError("Error converting response payload to json for JIRA issue count.");
    }
    return issuesMetaDetails;
}

function getTotalIssueCount(string path, string product, string labels, http:Request req) returns json|error {
    int page = 0;
    json respJson;
    json issuesMetaDetails = [];

    // prepare jql
    string jql = "project=" + product + " and labels in (" + labels + ")";


    // creating array of query parameters key & values
    string[] queryParamNames = ["jql", "startAt", "maxResults"];
    string[] queryParamValues = [jql, "0", "0"];

    string queryUrl = prepareQueryUrl(path, queryParamNames, queryParamValues);

    var response = jiraClientEP->get(queryUrl, message = req);

    if (response is http:Response) {
        issuesMetaDetails = check response.getJsonPayload();
        return issuesMetaDetails;
    } else {
        log:printError("Error occured while retrieving data from JIRA API", err = response);
    }
    return issuesMetaDetails;
}

function getOpenIssueCount(string path, string product, string labels, http:Request req) returns json|error {
    int page = 0;
    json respJson;
    json issuesMetaDetails = [];

    // prepare jql to query open issues
    string jql = "project=" + product + " and labels in (" + labels + ") " +
        "and (resolution not in (Answered,Completed,Done,Duplicate,Fixed) or resolution = Unresolved )";

    // creating array of query parameters key & values
    string[] queryParamNames = ["jql", "startAt", "maxResults"];
    string[] queryParamValues = [jql, "0", "0"];

    string queryUrl = prepareQueryUrl(path, queryParamNames, queryParamValues);

    var response = jiraClientEP->get(queryUrl, message = req);

    if (response is http:Response) {

        issuesMetaDetails = check response.getJsonPayload();
        issuesMetaDetails.jql = JIRA_API + "/jira/issues/?jql=" + jql;
        return issuesMetaDetails;
    } else {
        log:printError("Error occured while retrieving data from JIRA API", err = response);
    }
    return issuesMetaDetails;
}

# Returns the prepared URL with encoded query.
# + paths - A string of path
# + queryParamNames - An array of query param names
# + queryParamValues - An array of query param values
# + return - The prepared URL with encoded query
function prepareQueryUrl(string paths, string[] queryParamNames, string[] queryParamValues) returns string {

    string url = paths;
    url = url + QUESTION_MARK;
    boolean first = true;
    int i = 0;
    foreach var name in queryParamNames {
        string value = queryParamValues[i];

        string|error encoded = http:encode(value, ENCODING_CHARSET);

        if (encoded is string) {

            // jql queries must contain EQUAL_SIGN
            if (name.equalsIgnoreCase("jql")) {
                var temp = encoded.replace("%3D", EQUAL_SIGN);
                encoded = temp;
            }
            if (first) {
                url = url + name + EQUAL_SIGN + encoded;
                first = false;
            } else {
                url = url + AMPERSAND + name + EQUAL_SIGN + encoded;
            }
        } else {
            log:printError("Unable to encode value: " + value, err = encoded);
            break;
        }
        i = i + 1;
    }
    return url;
}
