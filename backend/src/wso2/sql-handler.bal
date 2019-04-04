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

mysql:Client productTable = new({
        host: config:getAsString("DB_HOST"),
        port: config:getAsInt("DB_PORT"),
        name: config:getAsString("DB_NAME"),
        username: config:getAsString("USERNAME"),
        password: config:getAsString("PASSWORD"),
        poolOptions: { maximumPoolSize: 10 },
        dbOptions: { useSSL: false }
    });


function getAllProductNames() returns (json) {
    var productNames = productTable->select("SELECT PRODUCT_NAME FROM PRODUCT", ());
    if (productNames is table< record {} >) {
        var productNamesJson = json.convert(productNames);
        if (productNamesJson is json) {

            int i=0;
            while(i<productNamesJson.length()){
                    productNamesJson[i]=productNamesJson[i].PRODUCT_NAME;
                    i=i+1;
            }

            return productNamesJson;
        } else {
            log:printError("Error occured while converting the retreaved product names to json", err = productNamesJson)
            ;
        }
    } else {
        log:printError("Error occured while retreaving the product names from Database", err = productNames);
    }
}