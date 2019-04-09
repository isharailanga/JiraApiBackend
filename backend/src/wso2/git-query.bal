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

//when we pass the required arible this query willretirve the total open issue count for given milestone and given lables
public const string QUERY_PR = "query ($owner: String!, $name: String!, $milestoneNumber: Int!, $label: [String!]) {
  repository(owner: $owner, name: $name) {
    milestone(number: $milestoneNumber) {
      title
      issues(first: 100, states: [OPEN], orderBy: {field: CREATED_AT, direction: DESC}, labels: $label) {
        pageInfo {
          hasNextPage
          endCursor
        }
        totalCount
      }
    }
  }
}" ;

// input variables
//{"owner": "wso2","name":"product-is","milestoneNumber": 75,"label": "Affected/5.7.0"}


//retrieve latest 100 open milstones for a given repo, milestone number
public const string QUERY_MILESTONES = "
query {
  organization(login: \"wso2\") {
    repository(name: \"product-is\") {
      milestones(first: 100, states: [OPEN], orderBy: {field: CREATED_AT, direction: DESC}) {
        edges {
          node {
            number
          }
        }
      }
    }
  }
}
";