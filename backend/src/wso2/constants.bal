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

# Read ballerina.conf and get the Github and JIRA auth tokens
final string JIRA_AUTH_KEY = config:getAsString("JIRA_AUTH_KEY");
final string GITHUB_AUTH_KEY = config:getAsString("GITHUB_AUTH_KEY");

# GIT REPO Owner
final string GIT_REPO_OWNER = "wso2";

# REST APIs for Github, GraphQL and JIRA
final string GIT_REST_API = "https://api.github.com";
final string GIT_GRAPHQL_API = "https://api.github.com/graphql";
final string JIRA_API = "https://support.wso2.com";

# GITHUB Issue labelling
final string L1_LABEL = "Severity/Blocker";
final string L2_LABEL = "Severity/Critical";
final string L3_LABEL = "Severity/Major";

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

# Product Names
final string PRODUCT_APIM="API Management";
final string PRODUCT_IS="IAM";
final string PRODUCT_EI="Integration";
final string PRODUCT_OB="Financial Solutions";

# Internal JIRA Account names
final string JIRA_APIM="APIMINTERNAL";
final string JIRA_IS="IAMINTERNAL";
final string JIRA_EI="EIINTERNAL";
final string JIRA_OB="OBINTERNAL";

# Reference Links
final string CODE_COVERAGE_DASHBOARD_URL = "/portal/dashboards/codecoverage/home";
final string GIT_ISSUE_DASHBOARD_URL = "/portal/dashboards/gitissuedashboard/home";