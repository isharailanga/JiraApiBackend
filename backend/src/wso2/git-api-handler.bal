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

http:Client gitClientEP = new(GIT_REST_API);

function getProductVersions(string productName) returns (json) {
    http:Request req = new;
    req.addHeader("Authorization", "token " + GITHUB_AUTH_KEY);
    json versions = [];

    string productRepo = mapProductToRepo(productName);

    string reqURL = "/repos" + "/" + GIT_REPO_OWNER + "/" + productRepo + "/milestones?state=active";
    json|error productMilestones = getProductMilestones(reqURL, req);

    if (productMilestones is json) {
        versions = productMilestones;
        return versions;
    }
    else {
        log:printError("Error converting response payload to json for product versions.");
    }
    return versions;
}

function getProductMilestones(string path, http:Request req) returns (json|error) {
    json respJson;
    json milestonesArray = [];
    var response = gitClientEP->get(path, message = req);

    if (response is http:Response) {
        respJson = check response.getJsonPayload();

        int i = 0;
        if (respJson.length() > 0)
        {
            while (i < respJson.length()) {
                milestonesArray[i] = {};
                milestonesArray[i].title = respJson[i].title;
                milestonesArray[i].number = respJson[i].number;
                i = i + 1;
            }
        }
        return milestonesArray;
    } else {
        log:printError("Error occured while retrieving data from GitHub API.", err = response);
    }
    return milestonesArray;
}

public function getGitIssueCount(string productName, string milestoneNo) returns (json) {
    string repo = mapProductToRepo(productName);

    json[] count = [];
    count[0] = getGitIssuesByLabel(repo, milestoneNo, L1_LABEL);
    count[1] = getGitIssuesByLabel(repo, milestoneNo, L2_LABEL);
    count[2] = getGitIssuesByLabel(repo, milestoneNo, L3_LABEL);

    int x=0;
    while(x<count.length()) {
        if(count[x] == null){
            count[x]=0;
        }
        x=x+1;
    }

    json issueCount = {
        L1Issues: count[0],
        L2Issues: count[1],
        L3Issues: count[2],
        refLink: GIT_ISSUE_DASHBOARD_URL
    };
    return issueCount;

}

public function getGitIssuesByLabel(string repo, string milestoneNo, string label) returns (json) {

    http:Request req = new;
    string graphQLquery = getIssueQuery(GIT_REPO_OWNER, repo, milestoneNo, label);
    json jsonPayLoad = { "query": graphQLquery };
    json|error result = null;

    req.addHeader("Authorization", "Bearer " + GITHUB_AUTH_KEY);
    req.setJsonPayload(jsonPayLoad);
    var resp = gitGraphQLEP->post("", req);

    json issueCount = {};
    if (resp is http:Response) {
        result = resp.getJsonPayload();
        if (result is json) {
            json temp = result;
            issueCount = temp["data"]["repository"]["milestone"]["issues"]["totalCount"];
            return issueCount;
        } else {
            log:printError("Error converting response payload to json for GIT issue count.");
        }
    } else {
        log:printError("Error occured while retrieving data from GIT API.", err = resp);
    }
    return issueCount;
}

//This function will map the given JIRA project to the GIT product-repo name
function mapProductToRepo(string product) returns (string) {
    string repo = "";
    if (product.equalsIgnoreCase(PRODUCT_APIM)) {
        repo = "product-apim";
    } else if (product.equalsIgnoreCase(PRODUCT_IS)) {
        repo = "product-is";
    } else if (product.equalsIgnoreCase(PRODUCT_EI)) {
        repo = "product-ei";
    } else if (product.equalsIgnoreCase("Analytics")) {
        repo = "product-sp";
    } else if (product.equalsIgnoreCase(PRODUCT_OB)) {
        repo = "financial-open-banking";
    } else if (product.equalsIgnoreCase("Cloud")) {
        repo = "cloud";
    }
    return repo;
}
