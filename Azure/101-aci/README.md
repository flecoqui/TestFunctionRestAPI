# Deployment of a REST API  hosted on Azure Container Instance 


This template allows you to deploy from Github a REST API  hosted on Azure Container Instance . Moreover, the REST API service will be directly deployed from github towards Azure Container Registry.

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



### DEPLOY REST API ON AZURE CONTAINER INSTANCE:

In order to deploy the REST API on Azure Container Instance or Azure Kubernetes you will use a Powershell script on Windows and a Bash script on Linux with the following parameters:</p>
* **ResourceGroupName:**						The name of the resource group used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **namePrefix:**						The name prefix which has been used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **cpuCores:**						The number of CPU cores used by the containers on Azure Container Instance or Kubernetes, for instance : 1, by default 0.4 </p>
* **memoryInGB:**				The amount of memory in GB used by the containers on Azure Container Instance or Kubernetes, for instance : 2, by defauylt 0.3 </p>
* **aksVMSize:**                        The size of the Virtual Machine running on the Kubernetes Cluster, for instance: Standard_D4s_v3, by default Standard_D2s_v3</p>
* **aksNodeCount:**                         The number of node for the Kubernetes Cluster</p>
</p>
</p>

Below the command lines for Windows and Linux:

* **Powershell Windows:** .\install-containers-windows.ps1  "ResourceGroupName" "NamePrefix" "cpuCores" "memoryInGB" "aksVMSize" "aksNodeCount"

* **Bash Linux:** ./install-containers.sh "ResourceGroupName" "NamePrefix" "cpuCores" "memoryInGB" "aksVMSize" "aksNodeCount"


For instance:

    ./install-containers.sh TestRESTAPIServicesrg testrest 0.4 0.5 Standard_D2s_v3 1

    .\install-containers-windows.ps1 TestRESTAPIServicesrg testrest 0.4 0.5 Standard_D2s_v3 1

Once deployed, the following services are available in the resource group:


![](https://raw.githubusercontent.com/flecoqui/TestRESTAPIServices/master/Docs/1-deploy.png)


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

## DELETE AZURE CONTAINER REGISTRY SERVICE PRINCIPAL :

**Azure CLI 2.0:** az ad sp  delete --id "ServicePrincipalUrl"

For instance:

    az ad sp delete --id http://testrestacrsp

## DELETE THE RESOURCE GROUP:

* **Azure CLI 1.0:**      azure group delete "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:**  az group delete -n "ResourceGroupName" "RegionName"

For instance:

    azure group delete TestRESTAPIServicesrg eastus2

    az group delete -n TestRESTAPIServicesrg 





# Next Steps

1. Automate the Vegeta Tests  
