# F8T (Feet On The Tarmac) - Infrastructure
![Project logo](./docs/f8t-logo.png)

## Table of contents
* [General info](#general-info)
* [Technologies](#technologies)
* [Setup](#setup)
* [Post-run configuration](#post-run-configuration)
* [F8T repositories](#f8t-repositories)

## General info
F8T is version of Feet On The Tarmac (FOTT) project for K8s. Originally FOTT project was built on Azure PaaS approach. It means was strongly related to Azure platform services such as Azure Functions for example. F8T based on the approach where all services are contenerizable and runnable in K8S.
This repository contains infrastructure for F8T project described in Azure Bicep templates. In the repo is a GitHub Actions workflow included which is responsible for create the infrastructure in Azure cloud.

## Technologies
Project is created with:
* Bicep
	
## Setup
To run this project from GitHub Actions:
* Create dedicated service principal in Azure and grab the result of it

```
az ad sp create-for-rbac --name "f8t-github-actions" --sdk-auth --role owner --scopes /subscriptions/{subscriptions-id}
```

* Define GitHub Actions secret named AZURE_CREDENTIALS and put there the value from the previous step

* Define GitHub Actions secret named AZURE_SUBSCRIPTION and put there the id of your Azure Subscription

* Define GitHub Actions secret named DB_ADMIN_LOGIN and put there your database username

* Define GitHub Actions secret named DB_ADMIN_PASSWORD and put there your database password

* Define GitHub Actions variable named AZURE_LOCATION and put there correct name of Azure region where do you want to deploy your resources

* Run GitHub workflow and pass the name of environment (dev, uat, prod)

## F8T repositories
* Infrastructure (this one): [github.com/beniaminzaborski/bz-f8t-infrastructure](https://github.com/beniaminzaborski/bz-f8t-infrastructure)
* Administration: [github.com/beniaminzaborski/bz-f8t-administration](https://github.com/beniaminzaborski/bz-f8t-administration)
* Registration: [github.com/beniaminzaborski/bz-f8t-registration](https://github.com/beniaminzaborski/bz-f8t-registration)