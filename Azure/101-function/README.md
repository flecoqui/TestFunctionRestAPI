# Deployment of a REST API  hosted on Azure Function

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2FTestRESTAPIServices%2Fmaster%2FAzure%2F101-function%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2FTestRESTAPIServices%2Fmaster%2FAzure%2F101-function%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template allows you to deploy from Github a REST API  hosted on Azure App Service, Azure Function, Azure Virtual Machine, Azure Container Instance and Azure Kubernetes Service. Moreover, the REST API service will be directly deployed from github towards Azure App Service, Azure Function, Azure Virtual Machine and Azure Container Registry.

The REST API (api/values) is actually an JSON echo service, if you send a Json string in the http content, you will receive the same Json string in the http response.
Below a curl command line to send the request:


          curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   https://<hostname>/api/values


Moreover, you can get some information about the performances of this service using another REST API (api/test).
Below a curl command line to retrieve the performance counters:


          curl  -H "Content-Type: application/json"  -X POST   https://<hostname>/api/test




# DEPLOYING THE REST API ON AZURE SERVICES

## PRE-REQUISITES
First you need an Azure subscription.
You can subscribe here:  https://azure.microsoft.com/en-us/free/ . </p>
Moreover, we will use Azure CLI v2.0 to deploy the resources in Azure.
You can install Azure CLI on your machine running Linux, MacOS or Windows from here: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest 



## CREATE RESOURCE GROUP:
First you need to create the resource group which will be associated with this deployment. For this step, you can use Azure CLI v1 or v2.

* **Azure CLI 1.0:** azure group create "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:** az group create an "ResourceGroupName" -l "RegionName"

For instance:

    azure group create TestRESTAPIServicesrg eastus2

    az group create -n TestRESTAPIServicesrg -l eastus2

## DEPLOY THE SERVICES:

### DEPLOY REST API ON AZURE FUNCTION, APP SERVICE, VIRTUAL MACHINE:
You can deploy Azure Function, Azure App Service and Virtual Machine using ARM (Azure Resource Manager) Template and Azure CLI v1 or v2

* **Azure CLI 1.0:** azure group deployment create "ResourceGroupName" "DeploymentName"  -f azuredeploy.json -e azuredeploy.parameters.json*

* **Azure CLI 2.0:** az group deployment create -g "ResourceGroupName" -n "DeploymentName" --template-file "templatefile.json" --parameters @"templatefile.parameter..json"  --verbose -o json

For instance:

    azure group deployment create TestRESTAPIServicesrg TestRESTAPIServicesdep -f azuredeploy.json -e azuredeploy.parameters.json -vv

    az group deployment create -g TestRESTAPIServicesrg -n TestRESTAPIServicesdep --template-file azuredeploy.json --parameter @azuredeploy.parameters.json --verbose -o json


When you deploy the service you can define the following parameters:</p>
* **namePrefix:** The name prefix which will be used for all the services deployed with this ARM Template</p>
* **azFunctionAppSku:** The Azure Function App Sku Capacity, by defualt F1</p>
* **repoURL:** The github repository url</p>
* **branch:** The branch name in the repository</p>
* **repoFunctionPath:** The path to the Azure Function code, by default "TestFunctionApp"</p>


The services has been deployed with 2 command lines.


# TEST THE SERVICES:

## TEST THE SERVICES WITH CURL
Once the services are deployed, you can test the REST API using Curl. You can download curl from here https://curl.haxx.se/download.html 
For instance :

     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   https://<namePrefix>function.azurewebsites.net/api/values
     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   https://<namePrefix>web.azurewebsites.net/api/values
     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   https://<namePrefix>vm.<Region>.cloudapp.azure.com/api/values
     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   https://<namePrefix>aci.<Region>.azurecontainer.io/api/values
     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   https://<namePrefix>aks.<Region>.cloudapp.azure.com/api/values

</p>

## TEST THE SERVICES WITH VEGETA
You can also test the scalability of the REST API using Vegeta. 
You can deploy a Virtual Machine running Vageta using the ARM Template here: https://github.com/flecoqui/101-vm-simple-vegeta-universal 
While deploying Vegeta, you can select the type of Virtual Machine: Windows, Debian, Ubuntu, RedHat, Centos.

Vegeta will be pre-installed on those virtual machines.

Once connected with the Vegate Virtual Machine, open the Command Shell and launch the following command for instance :</p>


         vegeta attack -duration=10s -rate 1000 -targets=targets.txt | vegeta report 



where the file targets.txt contains the following lines: </p>


          POST http://testrestfunction.azurewebsites.net/api/values
          Content-Type: application/json
          @data.json



where the file data.json contains the following lines: </p>


         '{"name":"0123456789"}'


# DELETE THE REST API SERVICES 


## DELETE THE RESOURCE GROUP:

* **Azure CLI 1.0:**      azure group delete "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:**  az group delete -n "ResourceGroupName" "RegionName"

For instance:

    azure group delete TestRESTAPIServicesrg eastus2

    az group delete -n TestRESTAPIServicesrg 





# Next Steps

1. Automate the Vegeta Tests  
