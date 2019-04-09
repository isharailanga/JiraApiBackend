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

http:Client gitGraphQLEP = new("https://api.github.com/graphql");
//when we pass the required  this query willretirve the total open issue count for given milestone and given lables
public string QUERY_ISSUES = string `
query {
  repository(owner: "<OWNER>", name: "<REPONAME>") {
    milestone(number: <MILESTONENUMBER>) {
      title
      issues(first: 100, states: [OPEN], orderBy: {field: CREATED_AT, direction: DESC}, labels: "<LABELS>") {
        totalCount
      }
    }
  }
}
`;
public function getGitIssueCount(string productName,string milestoneNo) returns (json) {
    string repo = mapProductToRepo(productName);
    http:Request req = new;

    string graphQLquery = getIssueQuery(GIT_REPO_OWNER, repo, milestoneNo, "Type/Bug");
    json jsonPayLoad = { "query": graphQLquery };
    json|error result = null;

    req.addHeader("Authorization", "Bearer " + GITHUB_AUTH_KEY);
    req.setJsonPayload(jsonPayLoad);
    var resp = gitGraphQLEP->post("", req);

    json gitIssueCount = null;
    if (resp is http:Response) {
        result = resp.getJsonPayload();
        if (result is json) {
            json temp=result;
            json productVersion = temp["data"]["repository"]["milestone"]["title"];
            json issueCount = temp["data"]["repository"]["milestone"]["issues"]["totalCount"];

            gitIssueCount = {
                productVersion: productVersion,
                issueCount: issueCount
            };
            return gitIssueCount;
        }
    }
    return gitIssueCount;

}


public function getIssueQuery(string org, string repo, string milestoneNo, string label) returns (string) {
    string[] tokens = ["<OWNER>", "<REPONAME>", "<MILESTONENUMBER>", "<LABELS>"];
    string[] replaceTokens = [org, repo, milestoneNo, label];
    string queryForIssues = formatQuery(QUERY_ISSUES, tokens, replaceTokens);
    return queryForIssues;
}

function formatQuery(string queryForIssues, string[] tokens, string[] replaceTokens) returns (string) {
    int i = 0;
    string queryForIssuesFormatted = queryForIssues;
    foreach var token in tokens {
        string replaceToken = replaceTokens[i];
        queryForIssuesFormatted = queryForIssuesFormatted.replaceAll(token, replaceToken);
        i = i + 1;
    }
    return queryForIssuesFormatted;
}
