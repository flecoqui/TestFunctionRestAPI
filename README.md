# Deployment of a REST API  hosted on Azure Function and/or Azure Kubernetes Service

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2FTestFunctionRestAPI%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2FTestFunctionRestAPI%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template allows you to deploy from Github a REST API  hosted on Azure Function and Azure Kubernetes Service. Moreover, the REST API scalability will be tested on Azure Function and Azure Kubernetes. For Azure Kubernetes, Keda and Prometheus will be deployed to support the scalability.

The REST API (api/values) is actually an JSON echo service, if you send a Json string in the http content, you will receive the same Json string in the http response.
Below a curl command line to send the request:


          curl -v -d "{\"name\":\"0123456789\"}" -H "Content-Type: application/json"  -X POST   https://<hostname>/api/values

          curl -v -H "Content-Type: application/json"  -X GET https://<hostname>/api/values?name=0123456789



Moreover, you can get some information about the performances of this service using another REST API (api/test).
Below a curl command line to retrieve the performance counters:


          curl  -H "Content-Type: application/json"  -X GET   https://<hostname>/api/test



![](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/1-architecture.png)


# DEPLOYING THE REST API ON AZURE SERVICES

This chapter describes how to deploy the rest API automatically on :</p>
* **Azure Function**</p>
* **Azure Kubernetes Service**</p>

The following resources are available to complete this step:

* **Linux Pre-requisite installation script: ** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-software.sh </p>
* **Windows Pre-requisite installation powershell script: ** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-software-windows.ps1 </p>
* **Azure Function ARM Template Linux: ** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/azuredeploy.json </p>
* **Linux Installation script for Function stored on Docker Hub and deployed on AKS: ** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-dockerhub-function.sh </p>
* **Windows Installation script for Function stored on Docker Hub and deployed on AKS: ** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-dockerhub-function-windows.ps1 </p>
* **Linux Installation script for Function stored on Azure Container Registry and deployed on AKS: ** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-acr-function.sh </p>
* **Windows Installation script for Function stored on Azure Container Registry and deployed on AKS: ** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-acr-function-windows.ps1 </p>
* **Linux Installation script for .Net Core 3.1 Web Api stored on Azure Container Registry and deployed on AKS: ** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-acr-webapi.sh </p>
* **Windows Installation script for .Net Core 3.1 Web Api stored on Azure Container Registry and deployed on AKS: ** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-acr-webapi-windows.ps1 </p>


## PRE-REQUISITES

### Azure Subscription

First you need an Azure subscription.
You can subscribe here:  https://azure.microsoft.com/en-us/free/ . </p>

### Azure CLI

Moreover, we will use Azure CLI v2.0 to deploy the resources in Azure.
You can install Azure CLI on your machine running Linux, MacOS or Windows from here: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest 

The first Azure CLI command will create a resource group.
The second  Azure CLI command will deploy an Azure Function, an Azure App Service and a Virtual Machine using an Azure Resource Manager Template.
In order to deploy Azure Container Instance or Azure Kubernetes Service a Service Principal is required to pull the container image from Azure Container Registry, unfortunately as today it's not possible to create Azure Service Principal with an Azure Resource Manager Template, we will use a PowerShell script on Windows or a Bash script on Linux to deploy the Azure Container Instance and  Azure Kubernetes Service.  

### Kubectl

Kubectl will be required to manager the Kubernetes cluster. Kubectl will be installed from Azure CLI.

### Helm v3

Helm v3 will be required for the AKS deployment
You can download the binaries from there: https://github.com/helm/helm/releases

### Azure Function Core Tools v3

Azure Function Core Tools v3 will be used to create and deploy Azure Functions.
All the instructions to install Azure Function Core Tool on Windows, Linux and MacOS here: https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Ccsharp%2Cbash

### Docker and Docker Hub Account

As the Azure Function Docker Image will be stored on Docker Hub, Docker must be installed on your machine with a Docker Hub Account.
All the instructions to install Docker on Windows, Linux and MacOS here: https://docs.docker.com/install/
All the instructions to create a Docker Hub Account here: https://hub.docker.com/ 

### Curl

Curl command line tool can be used to test your REST API hosted either locally, on Azure Function or on Azure Kubernetes Services.
You can download curl for Windows, Linux and MacOS from there: https://curl.haxx.se/download.html

### Git

Git command line tool can be used to clone locally this repository.
You can download git for Windows, Linux and MacOS from there: https://git-scm.com/downloads


## CLONING THE CURRENT REPOSITORY 

First you need to copy the current repository on your machine.
Run the following commands:

1. Clone the current repository:

        C:\git\me> git clone https://github.com/flecoqui/TestFunctionRestAPI.git



2. Change directory :

        C:\git\me> cd TestFunctionRestAPI
        C:\git\me\TestFunctionRestAPI> 



## DEPLOYING AND TESTING A FUNCTION REST API LOCALLY

In order to test locally the function, you can use Azure Function core Tool to run the REST API locally.

1. Change directory :

        C:\git\me\TestFunctionRestAPI> cd TestFunctionApp

2. Launch the function locally :

        C:\git\me\TestFunctionRestAPI\TestFunctionApp> func start 

3. After few seconds the functions should be launched locally exposing both REST API values and test

        Http Functions:
                test: [GET,DELETE] http://localhost:7071/api/test
                values: [POST,GET] http://localhost:7071/api/values

4. Open another Command Shell windows, and launch the following curl commands


          curl -d "{\"name\":\"0123456789\"}" -H "Content-Type: application/json"  -X POST   http://localhost:7071/api/values

          curl -H "Content-Type: application/json"  -X GET http://localhost:7071/api/values?name=0123456789

          curl  -H "Content-Type: application/json"  -X GET   http://localhost:7071/api/test


If the commands above do not return any strings, use the curl option -v to display the http Error Code:


          curl -v -d "{\"name\":\"0123456789\"}" -H "Content-Type: application/json"  -X POST   http://localhost:7071/api/values

          curl -v -H "Content-Type: application/json"  -X GET http://localhost:7071/api/values?name=0123456789

          curl -v  -H "Content-Type: application/json"  -X GET   http://localhost:7071/api/test



## DEPLOYING AND TESTING A FUNCTION REST API ON AZURE FUNCTION

### CREATE RESOURCE GROUP:
First you need to create the resource group which will be associated with this deployment. For this step, you can use Azure CLI v1 or v2.

* **Azure CLI 1.0:** azure group create "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:** az group create an "ResourceGroupName" -l "RegionName"

For instance:

    azure group create TestFunctionRestAPIrg eastus2

    az group create -n TestFunctionRestAPIrg -l eastus2

### DEPLOY THE SERVICES:

### DEPLOY REST API ON AZURE FUNCTION:
You can deploy Azure Function, Azure App Service and Virtual Machine using ARM (Azure Resource Manager) Template and Azure CLI v1 or v2

* **Azure CLI 1.0:** azure group deployment create "ResourceGroupName" "DeploymentName"  -f azuredeploy.json -e azuredeploy.parameters.json

* **Azure CLI 2.0:** az group deployment create -g "ResourceGroupName" -n "DeploymentName" --template-file "templatefile.json" --parameters @"templatefile.parameter..json"  --verbose -o json

For instance:

    azure group deployment create TestFunctionRestAPIrg TestFunctionRestAPIdep -f azuredeploy.json -e azuredeploy.parameters.json -vv

    az deployment group create -g TestFunctionRestAPIrg -n TestFunctionRestAPIdep --template-file azuredeploy.json --parameter @azuredeploy.parameters.json --verbose -o json


When you deploy the service you can define the following parameters:</p>
* **namePrefix:** The name prefix which will be used for all the services deployed with this ARM Template</p>
* **azFunctionAppSku:** The Azure Function App Sku Capacity, by default Y1 (consumption plan)</p>
* **repoURL:** The github repository url</p>
* **branch:** The branch name in the repository</p>
* **repoFunctionPath:** The path to the Azure Function code, by default "TestFunctionAppv2" as currently it seems not possible to directly deploy Azure Function v3 from github</p>
</p>

### DELETE THE RESOURCE GROUP:

* **Azure CLI 1.0:**      azure group delete "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:**  az group delete -n "ResourceGroupName" "RegionName"

For instance:

    azure group delete TestFunctionRestAPIrg eastus2

    az group delete -n TestFunctionRestAPIrg 


## DEPLOYING AND TESTING A FUNCTION REST API ON AZURE KUBERNETES SERVICE WITH KEDA AND PROMETHEUS

### CREATE RESOURCE GROUP:
First you need to create the resource group which will be associated with this deployment. For this step, you can use Azure CLI v1 or v2.

* **Azure CLI 1.0:** azure group create "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:** az group create an "ResourceGroupName" -l "RegionName"

For instance:

    azure group create TestFunctionRestAPIrg eastus2

    az group create -n TestFunctionRestAPIrg -l eastus2

### DEPLOY REST API ON AZURE KUBERNETES SERVICE USING DOCKER HUB ACCOUNT:

In order to deploy the REST API on Azure Container Instance or Azure Kubernetes, you will use a Powershell script on Windows and a Bash script on Linux with the following parameters:</p>
* **ResourceGroupName:**						The name of the resource group used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **namePrefix:**						The name prefix which has been used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **aksVMSize:**                        The size of the Virtual Machine running on the Kubernetes Cluster, for instance: Standard_D4s_v3, by default Standard_D2s_v3</p>
* **aksNodeCount:**                         The number of node for the Kubernetes Cluster</p>
* **dockerHubAccountName:**						The name of the Docker Hub Account where the Function Image will be stored</p>
</p>
</p>

Below the command lines for Windows and Linux, before launching the command line below check that the Docker Deamon is running on your machine:

* **Powershell Windows:** C:\git\Me\TestFunctionRestAPI> .\install-aks-dockerhub-function-windows.ps1  "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" "dockerHubAccountName"

* **Bash Linux:** ./install-aks-dockerhub-function.sh "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" "dockerHubAccountName"


For instance:

    ./install-aks-dockerhub-function.sh TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 flecoqui

    C:\git\Me\TestFunctionRestAPI> .\install-aks-dockerhub-function-windows.ps1 TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 flecoqui

Once deployed, the following services are available in the resource group:


![](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/1-deploy.png)

The services has been deployed with 3 command lines.

If you want to deploy the REST API on only one single service, you can use the resources below:</p>

* **Azure Function:** Template ARM to deploy Azure Function https://github.com/flecoqui/TestFunctionRestAPI/tree/master/Azure/101-function </p>
* **Azure Kubernetes Service:** Template ARM and scripts to deploy Azure Kubernetes Service https://github.com/flecoqui/TestFunctionRestAPI/tree/master/Azure/101-aks</p>

### DEPLOY REST API IN A FUNCTION ON AZURE KUBERNETES SERVICE USING AZURE CONTAINER REGISTRY:

In order to deploy the REST API on Azure Container Instance or Azure Kubernetes, you will use a Powershell script on Windows and a Bash script on Linux with the following parameters:</p>
* **ResourceGroupName:**						The name of the resource group used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **namePrefix:**						The name prefix which has been used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **aksVMSize:**                        The size of the Virtual Machine running on the Kubernetes Cluster, for instance: Standard_D4s_v3, by default Standard_D2s_v3</p>
* **aksNodeCount:**                         The number of node for the Kubernetes Cluster</p>
</p>
</p>

Below the command lines for Windows and Linux, before launching the command line below check that the Docker Deamon is running on your machine:

* **Powershell Windows:** C:\git\Me\TestFunctionRestAPI> .\install-aks-acr-function-windows.ps1  "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" 

* **Bash Linux:** ./install-aks-acr-function.sh "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" 


For instance:

    ./install-aks-acr-function.sh TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 

    C:\git\Me\TestFunctionRestAPI> .\install-aks-acr-function-windows.ps1 TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 


### DEPLOY REST API IN A .Net Core 3.1 WEBAPI ON AZURE KUBERNETES SERVICE USING AZURE CONTAINER REGISTRY:

In order to deploy the REST API on Azure Container Instance or Azure Kubernetes, you will use a Powershell script on Windows and a Bash script on Linux with the following parameters:</p>
* **ResourceGroupName:**						The name of the resource group used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **namePrefix:**						The name prefix which has been used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **aksVMSize:**                        The size of the Virtual Machine running on the Kubernetes Cluster, for instance: Standard_D4s_v3, by default Standard_D2s_v3</p>
* **aksNodeCount:**                         The number of node for the Kubernetes Cluster</p>
</p>
</p>

Below the command lines for Windows and Linux, before launching the command line below check that the Docker Deamon is running on your machine:

* **Powershell Windows:** C:\git\Me\TestFunctionRestAPI> .\install-aks-acr-webapi-windows.ps1  "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" 

* **Bash Linux:** ./install-aks-acr-webapi.sh "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" 


For instance:

    ./install-aks-acr-webapi.sh TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 

    C:\git\Me\TestFunctionRestAPI> .\install-aks-acr-webapi-windows.ps1 TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 

### DELETE THE RESOURCE GROUP:

* **Azure CLI 1.0:**      azure group delete "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:**  az group delete -n "ResourceGroupName" "RegionName"

For instance:

    azure group delete TestFunctionRestAPIrg eastus2

    az group delete -n TestFunctionRestAPIrg 


# TEST THE SERVICES:

## TEST THE SERVICES WITH CURL
Once the services are deployed, you can test the REST API using Curl. You can download curl from here https://curl.haxx.se/download.html 
For instance for the Azure Function:

     curl -d "{\"name\":\"0123456789\"}" -H "Content-Type: application/json"  -X POST   https://<namePrefix>function.azurewebsites.net/api/values

For instance for the Function in a container with image stored on DockerHub:

     curl -d "{\"name\":\"0123456789\"}" -H "Content-Type: application/json"  -X POST   http://<namePrefix>aks.<Region>.cloudapp.azure.com/<namePrefix>hubfunc/api/values

For instance for the Function in a container with image stored on Azure Container Registry:

     curl -d "{\"name\":\"0123456789\"}" -H "Content-Type: application/json"  -X POST   http://<namePrefix>aks.<Region>.cloudapp.azure.com/<namePrefix>acrfunc/api/values

For instance for the .Net Core 3.1 WebAPI in a container with image stored on Azure Container Registry:

     curl -d "{\"name\":\"0123456789\"}\" -H "Content-Type: application/json"  -X POST   http://<namePrefix>aks.<Region>.cloudapp.azure.com/<namePrefix>acrwebapi/api/values


</p>

## TEST THE SERVICES WITH VEGETA
You can also test the scalability of the REST API using Vegeta. 
You can deploy a Virtual Machine running Vageta using the ARM Template here: https://github.com/flecoqui/101-vm-simple-vegeta-universal 
Before deploying the virtual machine running Vegeta, you can select the type of Virtual Machine: Windows, Debian, Ubuntu, RedHat, Centos.

Vegeta will be pre-installed on those virtual machines.

Once connected with the Vegate Virtual Machine, open the Command Shell and launch the following command for instance :</p>


         vegeta attack -duration=10s -rate 1000 -targets=targets.txt | vegeta report 



where the file targets.txt contains the following lines for the Azure Function: </p>

          POST http://<namePrefix>function.azurewebsites.net/api/values
          Content-Type: application/json
          @data.json

where the file targets.txt contains the following lines for  the Function in a container with image stored on DockerHub: </p>

          POST http://<namePrefix>aks.<Region>.cloudapp.azure.com/<namePrefix>hubfunc/api/values
          Content-Type: application/json
          @data.json

where the file targets.txt contains the following lines  for the Function in a container with image stored on Azure Container Registry: </p>

          POST http://<namePrefix>aks.<Region>.cloudapp.azure.com/<namePrefix>acrfunc/api/values
          Content-Type: application/json
          @data.json

where the file targets.txt contains the following lines for the .Net Core 3.1 WebAPI in a container with image stored on Azure Container Registry: </p>

          POST http://<namePrefix>aks.<Region>.cloudapp.azure.com/<namePrefix>acrwebapi/api/values
          Content-Type: application/json
          @data.json



where the file data.json contains the following lines: </p>

         '{"name":"0123456789"}'


Before launching the test on the Vegeta virtual machine launch the following kubectl command on your machine to check how many instances of the pod running the Web API are running:

        kubectl get pods -n ingress-nginx

The result should be similar to the lines below for a .Net Core 3.1 WebAPI showing one signle instance:

        NAME                                                              READY   STATUS    RESTARTS   AGE
        function-testrestapiacrwebapi-http-6fb4c9f85b-g726f               1/1     Running   0          67m
        ingress-controller-nginx-ingress-controller-5bb68d7957-4r5vx      1/1     Running   0          69m
        ingress-controller-nginx-ingress-controller-5bb68d7957-vmprc      1/1     Running   0          69m
        ingress-controller-nginx-ingress-default-backend-7cdd9c96frjc6d   1/1     Running   0          69m
        keda-operator-6bdf8cbb68-jvffg                                    1/1     Running   0          67m
        keda-operator-metrics-apiserver-78cd458bf-f92hf                   1/1     Running   0          67m
        prometheus-server-7f56b89f78-h2xkp                                1/1     Running   0          67m

On the virtual machine running vegeta launch for instance the following command to send 3000 requests per second during 10 seconds: 

        C:\testvegeta>vegeta attack -duration=10s -rate 3000 -targets=targets.txt | vegeta report

As AKS, Keda and Promotheus will detect the incoming traffic normally the service should auto-scale and 100% of a http request should get a response:    

        Requests      [total, rate, throughput]         29995, 2999.77, 2998.27
        Duration      [total, attack, wait]             10.004s, 9.999s, 5.001ms
        Latencies     [min, mean, 50, 90, 95, 99, max]  999.8µs, 78.746ms, 39.51ms, 178.976ms, 311.516ms, 649.747ms, 1.785s
        Bytes In      [total, mean]                     1319780, 44.00
        Bytes Out     [total, mean]                     689885, 23.00
        Success       [ratio]                           100.00%
        Status Codes  [code:count]                      200:29995


If you launch again the kubectl command to know how many instances of the pod are running, you shoudl see a result similar to the one below:

        kubectl get pods -n ingress-nginx


        NAME                                                              READY   STATUS    RESTARTS   AGE
        function-testrestapiacrwebapi-http-6fb4c9f85b-59kkp               1/1     Running   0          3m35s
        function-testrestapiacrwebapi-http-6fb4c9f85b-5cvwm               1/1     Running   0          3m19s
        function-testrestapiacrwebapi-http-6fb4c9f85b-7bxxs               1/1     Running   0          3m19s
        function-testrestapiacrwebapi-http-6fb4c9f85b-cn5f7               1/1     Running   0          3m50s
        function-testrestapiacrwebapi-http-6fb4c9f85b-g2xkt               1/1     Running   0          3m35s
        function-testrestapiacrwebapi-http-6fb4c9f85b-g726f               1/1     Running   0          75m
        function-testrestapiacrwebapi-http-6fb4c9f85b-l6lvf               1/1     Running   0          3m35s
        function-testrestapiacrwebapi-http-6fb4c9f85b-n5zc9               1/1     Running   0          3m50s
        function-testrestapiacrwebapi-http-6fb4c9f85b-t4p59               1/1     Running   0          3m35s
        function-testrestapiacrwebapi-http-6fb4c9f85b-xw564               1/1     Running   0          3m50s
        ingress-controller-nginx-ingress-controller-5bb68d7957-4r5vx      1/1     Running   0          77m
        ingress-controller-nginx-ingress-controller-5bb68d7957-vmprc      1/1     Running   0          77m
        ingress-controller-nginx-ingress-default-backend-7cdd9c96frjc6d   1/1     Running   0          77m
        keda-operator-6bdf8cbb68-jvffg                                    1/1     Running   0          75m
        keda-operator-metrics-apiserver-78cd458bf-f92hf                   1/1     Running   0          75m
        prometheus-server-7f56b89f78-h2xkp                                1/1     Running   0          75m


# DELETE THE REST API SERVICES 

## DELETE THE RESOURCE GROUP:

* **Azure CLI 1.0:**      azure group delete "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:**  az group delete -n "ResourceGroupName" "RegionName"

For instance:

    azure group delete TestFunctionRestAPIrg eastus2

    az group delete -n TestFunctionRestAPIrg 

   
# Next Steps

1. Complete the Windows pre-requisite installation script 
