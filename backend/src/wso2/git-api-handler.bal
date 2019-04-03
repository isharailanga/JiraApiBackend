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

final string GIT_REPO_OWNER = "wso2";

http:Client gitClientEP = new("https://api.github.com");

function getProductVersions(string product, string authKey) returns (json) {
    http:Request req = new;
    req.addHeader("Authorization", "token " + authKey);
    json versions = [];

    string productRepo = mapProductToRepo(product);

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
                milestonesArray[i] = respJson[i].title;
                i = i + 1;
            }
        }
        return milestonesArray;
    } else {
        log:printError("Error occured while retrieving data from GitHub API.", err = response);
    }
    return milestonesArray;
}

//This function will map the given JIRA project to the GIT product-repo name
function mapProductToRepo(string product) returns (string) {
    string repo = "";
    if (product.equalsIgnoreCase("APIMINTERNAL")) {
        repo = "product-apim";
    } else if (product.equalsIgnoreCase("IAMINTERNAL")) {
        repo = "product-is";
    } else if (product.equalsIgnoreCase("EIINTERNAL")) {
        repo = "product-ei";
    } else if (product.equalsIgnoreCase("ANALYTICSINTERNAL")) {
        repo = "product-sp";
    } else if (product.equalsIgnoreCase("OBINTERNAL")) {
        repo = "financial-open-banking";
    } else if (product.equalsIgnoreCase("CLOUDINTERNAL")) {
        repo = "cloud";
    }
    return repo;
}