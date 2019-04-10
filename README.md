# Checklist Backend

Backend for Checklist widget

Steps to deploy:

- Setup [Ballerina 0.990.2](https://ballerina.io/downloads/archived/) runtime on a local folder

- Add ballerina.conf to <REPO_HOME>/backend 

  Sample ballerina.conf :
```
  JIRA_AUTH_KEY = "xxxx"
  GITHUB_AUTH_KEY = "xxx"

  DB_HOST="localhost"
  DB_PORT="3306"
  DB_NAME="WSO2_PRODUCT_COMPONENT"
  USERNAME="root"
  PASSWORD="root"
```

- Go to <REPO_HOME>/backend/src and initialize the project ```ballerina init``` 

- Create the .balx files by  ``` ballerina build wso2```

- Run the created .balx files ```ballerina run -c ../ballerina.conf target/wso2.balx``` to start the service.


