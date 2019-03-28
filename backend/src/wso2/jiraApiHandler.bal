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

http:Client clientEP = new("https://support.wso2.com/jira/rest/api/latest");

function getAllIssues(string product, string authKey) returns (json[]) {
    http:Request req = new;

    req.addHeader("Authorization", "Basic " + authKey);

    string reqURL = "";

    reqURL = "/search?jql=project=" + product;


    json[]|error issueDetailsJson = getissuesFromJira(reqURL, req);


    json[] issuesJson = [];
    int jiraIssueIterator = 0;
    int i = 0;
    if (issueDetailsJson is json[]) {

        int numberOfissues = issueDetailsJson.length();

        while (jiraIssueIterator < numberOfissues) {

            issuesJson[i] = {};
            issuesJson[i].issueTitle = issueDetailsJson[jiraIssueIterator].key;
            issuesJson[i].label = issueDetailsJson[jiraIssueIterator].fields.labels;
            issuesJson[i].status = issueDetailsJson[jiraIssueIterator].fields.status.name;
            jiraIssueIterator = jiraIssueIterator + 1;
            i = i + 1;

        }
        return issuesJson;
    } else {
        log:printError("Error converting response payload to json for issues in product");
    }
    return issuesJson;
}

function getissuesFromJira(string path, http:Request req) returns json[]|error {
    int page = 0;
    json[] finalIssueArray = [];
    json respJson;
    json issuesArray;
    var response = clientEP->get(path + "&startAt=" + page + "&maxResults=" + 50, message = req);

    if (response is http:Response) {
        respJson = check response.getJsonPayload();
        issuesArray = respJson.issues;

        // If JIRA issues exist
        if issuesArray.length() > 0 {
            finalIssueArray = check json[].convert(issuesArray);
            page = page + 50;
        } else {
            return finalIssueArray;
        }

        int|error max = int.convert(respJson.maxResults.toString());
        int|error total = int.convert(respJson.total.toString());

        if (total is int && max is int) {
            if (total > max) {
                http:Response response2 = check clientEP->get(path + "&startAt=" + page
                        + "&maxResults=" + (page + 50), message = req);
                respJson = check response2.getJsonPayload();
                issuesArray = respJson.issues;
                if (issuesArray.length() > 0) {
                    var z = check json[].convert(issuesArray);
                    foreach var issue in z {
                        finalIssueArray[finalIssueArray.length()] = issue;
                    }
                    page = page + 50;
                } else {
                    return finalIssueArray;
                }
            }
        }
        return finalIssueArray;


    } else {
        log:printError("Error occured while retrieving data from JIRA API", err = response);
    }
    return finalIssueArray;
}

