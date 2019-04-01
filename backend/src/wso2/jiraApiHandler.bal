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
import ballerina/mime;

# Constant field `QUESTION_MARK`. Holds the value of "?".
final string QUESTION_MARK = "?";

# Constant field `EMPTY_STRING`. Holds the value of "".
final string EMPTY_STRING = "";

# Constant field `EQUAL_SIGN`. Holds the value of "=".
final string EQUAL_SIGN = "=";

# Constant field `AMPERSAND`. Holds the value of "&".
final string AMPERSAND = "&";

// For URL encoding
# Constant field `ENCODING_CHARSET`. Holds the value for the encoding charset.
final string ENCODING_CHARSET = "utf-8";

http:Client clientEP = new("https://support.wso2.com");

function getAllIssues(string product, string labels, string authKey) returns (json[]) {
    http:Request req = new;

    req.addHeader("Authorization", "Basic " + authKey);

    string reqURL = "";

    reqURL = "/jira/rest/api/latest/search";


    json[]|error issueDetailsJson = getissuesFromJira(reqURL, product, labels, req);


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

function getissuesFromJira(string path, string product, string labels, http:Request req) returns json[]|error {
    int page = 0;
    json[] finalIssueArray = [];
    json respJson;
    json issuesArray;

    var searchPath = path + "&startAt=" + page + "&maxResults=" + 50;

    // prepare jql
    string jql = "project=" + product + " and labels in (" + labels + ")";

    // creating array of query parameters key & values
    string[] queryParamNames = ["jql", "startAt", "maxResults"];
    string[] queryParamValues = [jql, intToString(page), intToString((page + 50))];

    string queryUrl = prepareQueryUrl(path, queryParamNames, queryParamValues);

    var response = clientEP->get(queryUrl, message = req);

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

# Returns the prepared URL with encoded query.
# + paths - An array of paths prefixes
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
            if (name.equalsIgnoreCase("jql")) {
                var temp = encoded.replace("%3D", "=");
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

function intToString(int num) returns string {
    string|error str = string.convert(num);
    if (str is string) {
        return str;
    }
    return EMPTY_STRING;
}