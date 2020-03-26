# Deployment of a REST API  hosted on Azure Function and Azure Kubernetes Service

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2FTestFunctionRestAPI%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2FTestFunctionRestAPI%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template allows you to deploy from Github a REST API  hosted on Azure Function and Azure Kubernetes Service. Moreover, the REST API scalability will be tested on Azure Function and Azure Kubernetes. For Azure Kubernetes, Keda and Prometheus will be deployed to support the scalability.

The REST API (api/values) is actually an JSON echo service, if you send a Json string in the http content, you will receive the same Json string in the http response.
Below a curl command line to send the request:


          curl -v -d "{'name':'0123456789'}" -H "Content-Type: application/json"  -X POST   https://<hostname>/api/values

          curl -v -H "Content-Type: application/json"  -X GET https://<hostname>/api/values?name=0123456789



Moreover, you can get some information about the performances of this service using another REST API (api/test).
Below a curl command line to retrieve the performance counters:


          curl  -H "Content-Type: application/json"  -X GET   https://<hostname>/api/test



![](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/1-architecture.png)


# DEPLOYING THE REST API ON AZURE SERVICES

This chapter describes how to deploy the rest API automatically on :</p>
* **Azure Function**</p>
* **Azure Kubernetes Service**</p>
in **3 command lines**.

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


          curl -d "{'name':'0123456789'}" -H "Content-Type: application/json"  -X POST   http://localhost:7071/api/values

          curl -H "Content-Type: application/json"  -X GET http://localhost:7071/api/values?name=0123456789

          curl  -H "Content-Type: application/json"  -X GET   http://localhost:7071/api/test


If the commands above do not return any strings, use the curl option -v to display the http Error Code:


          curl -v -d "{'name':'0123456789'}" -H "Content-Type: application/json"  -X POST   http://localhost:7071/api/values

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

### DEPLOY REST API ON AZURE KUBERNETES SERVICE:

In order to deploy the REST API on Azure Container Instance or Azure Kubernetes you will use a Powershell script on Windows and a Bash script on Linux with the following parameters:</p>
* **ResourceGroupName:**						The name of the resource group used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **namePrefix:**						The name prefix which has been used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **aksVMSize:**                        The size of the Virtual Machine running on the Kubernetes Cluster, for instance: Standard_D4s_v3, by default Standard_D2s_v3</p>
* **aksNodeCount:**                         The number of node for the Kubernetes Cluster</p>
* **dockerHubAccountName:**						The name of the Docker Hub Account where the Function Image will be stored</p>
</p>
</p>

Below the command lines for Windows and Linux:

* **Powershell Windows:** .\install-containers-windows.ps1  "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" "dockerHubAccountName"

* **Bash Linux:** ./install-containers.sh "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" "dockerHubAccountName"


For instance:

    ./install-containers.sh TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 flecoqui

    .\install-containers-windows.ps1 TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 flecoqui

Once deployed, the following services are available in the resource group:


![](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/1-deploy.png)


The services has been deployed with 3 command lines.

If you want to deploy the REST API on only one single service, you can use the resources below:</p>

* **Azure Function:** Template ARM to deploy Azure Function https://github.com/flecoqui/TestFunctionRestAPI/tree/master/Azure/101-function </p>
* **Azure Kubernetes Service:** Template ARM and scripts to deploy Azure Kubernetes Service https://github.com/flecoqui/TestFunctionRestAPI/tree/master/Azure/101-aks</p>


# TEST THE SERVICES:

## TEST THE SERVICES WITH CURL
Once the services are deployed, you can test the REST API using Curl. You can download curl from here https://curl.haxx.se/download.html 
For instance :

     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   https://<namePrefix>function.azurewebsites.net/api/values
     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   https://<namePrefix>web.azurewebsites.net/api/values
     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   http://<namePrefix>vm.<Region>.cloudapp.azure.com/api/values
     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   http://<namePrefix>aci.<Region>.azurecontainer.io/api/values
     curl -d '{"name":"0123456789"}' -H "Content-Type: application/json"  -X POST   http://<namePrefix>aks.<Region>.cloudapp.azure.com/api/values

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

Below the tests results for:
* **Azure Function:**   Plan P2 (2 Cores + 7 GB)
* **Azure App Service:**  Plan P2 (2 Cores + 7 GB)
* **Azure Virtual Machine:**  D2s_V3 VM (2 Cores + 8 GB)
* **Azure Virtual Machine:**  D2s_V3 VM (2 Cores + 8 GB)
* **Azure Container Instance:**  container with 2 Cores + 7 GB
* **Azure Kubernetes Service:**  D4s_V3 VM in the cluster and container with 2 Cores + 7 GB
 
Using the following command where "MaxRate" is the maximum rate where the REST API doesn't return any error while receiving a burst of request during 1 second:


           vegeta attack -duration=1s -rate <MaxRate> -targets=target-function.txt | vegeta report


Using the following command where "MaxRate" is the maximum rate where the REST API doesn't return any error while receiving  requests during 60 second:


           vegeta attack -duration=1s -rate <MaxRate> -targets=target-function.txt | vegeta report





|  Azure Function Plan | 1 second burst max http request rate | 60 seconds continuous max http request rate |
|:----------------------:|:--------------------------------------:|:---------------------------------------------:|
| P2 ((2 Cores + 7 GB))|        5000 requests/second          |           300 requests/second               |


|  Azure App Service Plan | 1 second burst max http request rate | 60 seconds continuous max http request rate |
|:-------------------------:|:--------------------------------------:|:---------------------------------------------:|
| P2 (2 Cores + 7 GB)     |        7000 requests/second          |          1000 requests/second               |


|  Azure VM Size          | 1 second burst max http request rate | 60 seconds continuous max http request rate |
|:-------------------------:|:--------------------------------------:|:---------------------------------------------:|
| D2s_v3 (2 Cores + 8 GB) |        9000 requests/second          |          8000 requests/second               |


|  Azure Container Instance | 1 second burst max http request rate | 60 seconds continuous max http request rate |
|:-------------------------:|:--------------------------------------:|:---------------------------------------------:|
|  2 Cores + 7 GB         |        6000 requests/second          |          6000 requests/second               |


|  Azure Kubernetes Service | 1 second burst max http request rate | 60 seconds continuous max http request rate |
|:-------------------------:|:--------------------------------------:|:---------------------------------------------:|
|  D4s_v3 - 2 Cores + 7 GB   |       12000 requests/second          |         10000 requests/second               |

# DELETE THE REST API SERVICES 

## DELETE AZURE CONTAINER REGISTRY SERVICE PRINCIPAL :

**Azure CLI 2.0:** az ad sp  delete --id "ServicePrincipalUrl"

For instance:

    az ad sp delete --id http://testrestacrsp

## DELETE AZURE KUBERNETES SERVICE :

**Azure CLI 2.0:** az aks delete --name "AKSClusterName" --resource-group "ResourceGroupName" 

For instance:

    az aks delete --name testrestaksCluster --resource-group TestFunctionRestAPIrg


## DELETE THE RESOURCE GROUP:

* **Azure CLI 1.0:**      azure group delete "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:**  az group delete -n "ResourceGroupName" "RegionName"

For instance:

    azure group delete TestFunctionRestAPIrg eastus2

    az group delete -n TestFunctionRestAPIrg 



# ANNEX A - Deploying REST API in Azure Containers manually

## Pre-requisites
First you need an Azure subscription.
You can subscribe here:  https://azure.microsoft.com/en-us/free/ . </p>
Moreover, we will use Azure CLI v2.0 to deploy the resources in Azure.
You can install Azure CLI on your machine running Linux, MacOS or Windows from here: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest 

You could install Docker on your machine, but this installation is not mandatory, if you only deploy containers in Azure:
You can download Docker for Windows from there https://docs.docker.com/docker-for-windows/install/
You can also download Docker from there: https://hub.docker.com/editions/community/docker-ce-desktop-windows?tab=description  
Once Docker is installed you can deploy your application in a local container.

If you want to use Azure Kubernetes Service (AKS), you need to install kubectl.

From a Powershell window, launch the following command to install kubectl on your Windows 10 machine:


            Install-Script -Name install-kubectl -Scope CurrentUser -Force 


Launch the following command to check if kubectl is correctly installed:


            kubectl version


## BUILDING A CONTAINER IMAGE IN AZURE
Before deploying your application in a container running in Azure, you need to create a container image and deploy it in the cloud with Azure Container Registry:
https://docs.microsoft.com/en-us/azure/container-registry/container-registry-tutorial-quick-task


1. Open a command shell window in the project folder  


        C:\git\me\TestFunctionRestAPI> 

2. Create a resource group with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az group create --resource-group "ResourceGroupName" --location "RegionName"</p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az group create --resource-group TestFunctionRestAPIrg --location eastus2

3. Create an Azure Container Registry with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az acr create --resource-group "ResourceGroupName" --name "ACRName" --sku "ACRSku" --location "RegionName"</p>
For instance:

        C:\git\me\TestFunctionRestAPI>  az acr create --resource-group TestFunctionRestAPIrg --name testrestacreu2  --sku Standard --location eastus2  


4. Build the container image and register it in the new Azure Container Registry with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az acr build --registry "ACRName" --image "ImageName:ImageTag" "localFolder" -f "DockerFilePath"</p>
For instance below the creation of an image for Linux:

        C:\git\me\TestFunctionRestAPI>  az acr build --registry testrestacreu2   --image testwebapp.linux:latest . -f Docker\Dockerfile.linux


     After few minutes, the image should be available in the new registry:

     For instance:
        
		- image:
            registry: testrestacreu2.azurecr.io
            repository: testwebapp.linux
            tag: v1
            digest: sha256:26eb08c56b4ebd2c6b489754587c60b3aae9dbf1b06b297ae010cc60f3d525ea
          runtime-dependency:
            registry: registry.hub.docker.com
            repository: microsoft/dotnet
            tag: 2.2-runtime-deps
            digest: sha256:5318a6e0fb4dadc5c68c63e06469b2ebc2934ae60a90a917fe15497ed3e1c8ea
          buildtime-dependency:
          - registry: registry.hub.docker.com
            repository: microsoft/dotnet
            tag: 2.2.103-sdk
            digest: sha256:2074166f05123921602c68a46e710dc0be1ea18d968677a87e4276dac0746c70
          git: {}

        Run ID: ch2 was successful after 2m12s

     The image is built using the DockerFile below:

            
            FROM microsoft/dotnet:2.2.103-sdk AS build-env
            WORKDIR /app
   
            # copy csproj and restore as distinct layers
            COPY  TestWebApp/*.csproj ./TestWebApp/
            WORKDIR /app/TestWebApp
            RUN dotnet restore

            # copy everything else and build app
            WORKDIR /app

            COPY TestWebApp/. ./TestWebApp/
            WORKDIR /app/TestWebApp
            RUN dotnet publish --self-contained -r linux-x64 -c Release -o out
            #RUN dotnet publish  -c Release -o out

            FROM microsoft/dotnet:2.2-runtime-deps AS runtime
            WORKDIR /app
            COPY --from=build-env /app/TestWebApp/out ./
			RUN chmod +x ./TestWebApp
            ENTRYPOINT ["./TestWebApp", "--url", "http://*:80/"]



This DockerFile is available [here](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docker/Dockerfile.linux) on line. The image built from this DockerFile contains only the TestWebApp binary. 

For instance below the creation of an image for Linux Alpine which will consume less resource than the default Linux image:

        C:\git\me\TestFunctionRestAPI>  az acr build --registry testrestacreu2   --image testwebapp.linux-musl:latest . -f Docker\Dockerfile.linux-musl


After few minutes, the image should be available in the new registry:

The image is built using the DockerFile below:


            FROM microsoft/dotnet:2.2.103-sdk-alpine AS build-env
            WORKDIR /app
   
            # copy csproj and restore as distinct layers
            COPY  TestWebApp/*.csproj ./TestWebApp/
            WORKDIR /app/TestWebApp
            RUN dotnet restore

            # copy everything else and build app
            WORKDIR /app

            COPY TestWebApp/. ./TestWebApp/
            WORKDIR /app/TestWebApp
            RUN dotnet publish --self-contained -r linux-x64 -c Release -o out
            #RUN dotnet publish  -c Release -o out

            FROM microsoft/dotnet:2.2-runtime-deps-alpine AS runtime
            WORKDIR /app
            COPY --from=build-env /app/TestWebApp/out ./
			RUN chmod +x ./TestWebApp
            ENTRYPOINT ["./TestWebApp", "--url", "http://*:80/"]



This DockerFile is available [here](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docker/Dockerfile.linux-musl) on line. The image built from this DockerFile contains only the TestWebApp binary. 

## CONFIGURING REGISTRY AUTHENTICATION
In this sections, you create an Azure Key Vault and Service Principal, then deploy the container to Azure Container Instances (ACI) using Service Principal's credentials.

1. Create a key vault with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az keyvault create --resource-group "ResourceGroupName" --name "AzureKeyVaultName"</p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az keyvault create --resource-group TestFunctionRestAPIrg --name acrkv
 
2. Display the ID associated with the new Azure Container Registry using the following command:</p>
In order to create the Service Principal you need to know the ID associated with the new Azure Container Registry, you can display this information with the following command:</p>
**Azure CLI 2.0:** az acr show --name "ACRName" --query id --output tsv</p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az acr show --name testrestacreu2 --query id --output tsv


This command will display an ID like the one below:

/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/TestFunctionRestAPIrg/providers/Microsoft.ContainerRegistry/registries/testrestacreu2

3. Create a Service Principal and display the password with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az ad sp create-for-rbac --name "ACRSPName" --scopes "ACRID" --role acrpull --query password --output tsv</p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az ad sp create-for-rbac --name acrspeu2 --scopes /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/TestFunctionRestAPIrg/providers/Microsoft.ContainerRegistry/registries/testrestacreu2 --role acrpull --query password --output tsv

     After few seconds the result (ACR Password) is displayed:

        Changing "spacreu2" to a valid URI of "http://acrspeu2", which is the required format used for service principal names
        Retrying role assignment creation: 1/36
        Retrying role assignment creation: 2/36
        yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy


4. Store credentials (ACR password) with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az keyvault secret set  --vault-name "AzureKeyVaultName" --name "PasswordSecretName" --value "ServicePrincipalPassword" </p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az keyvault secret set  --vault-name acrkv --name acrspeu2-pull-pwd --value yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
 
5. Display the Application ID associated with the new Service Principal with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az ad sp show --id http://"ACRSPName" --query appId --output tsv</p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az ad sp show --id http://acrspeu2 --query appId --output tsv

     After few seconds the result (ACR AppId) is displayed:

        wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww



6. Store credentials (ACR AppID) with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az keyvault secret set  --vault-name "AzureKeyVaultName" --name "AppIDSecretName" --value "ServicePrincipalAppID" </p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az keyvault secret set  --vault-name acrkv --name acrspeu2-pull-usr --value wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww
 

     The Azure Key Vault contains now the Azure Container Registry AppID and Password. 


## Deploying TestWebApp in ACI (Azure Container Instance)
Your container image testwebapp:latest is now available from your container registry in Azure.
You can now deploy the image using the credentials stored in Azure Key Vault.


<img src="https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/aci.png"/>



1. You need first to retrieve the AppID from the Azure Key Vault with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az keyvault secret show --vault-name "AzureKeyVaultName" --name "AppIDSecretName" --query value -o tsv  </p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az keyvault secret show --vault-name acrkv --name acrspeu2-pull-usr --query value -o tsv
 
     After few seconds the result (ACR AppId) is displayed:

        wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww

2. You need also to retrieve the Password from the Azure Key Vault with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az keyvault secret show --vault-name "AzureKeyVaultName" --name "PasswordSecretName" --query value -o tsv  </p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az keyvault secret show --vault-name acrkv --name acrspeu2-pull-pwd --query value -o tsv
 
     After few seconds the result (Password) is displayed:

        yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy


3. With the AppID and the Password you can now deploy the image in a container with Azure CLI using the following command:</p>
**Azure CLI 2.0:** az container create --resource-group "ResourceGroupName"  --name "ContainerGroupName" -f "file.yaml" -o json --debug --restart-policy OnFailure</p>


Below the content of the file "file.yaml" :

          apiVersion: 2018-06-01
          location: <Region>
          name: <ContainerGroupName>
          properties:
            containers:
            - name: astool
              properties:
                image: <ACRName>.azurecr.io/testwebapp.linux:latest
                command: ["./TestWebApp","--url", "http://*:80"]
                resources:
                  requests:
                    cpu: .4
                    memoryInGb: .3
                ports:
                - port: 80          
            osType: Linux
            ipAddress:
              type: Public
              ports:
              - protocol: tcp
                port: '80'
			  dnsNameLabel: <DNSName>
            imageRegistryCredentials:
            - server: <ACRName>.azurecr.io
              username: <AppUserName>
              password: <AppPassword>
          tags: null
          type: Microsoft.ContainerInstance/containerGroups


For instance below the creation of a Linux container:

        C:\git\me\TestFunctionRestAPI>  az container create --resource-group TestFunctionRestAPIrg --name testwebapp.linux -f Docker\testwebapp.linux.aci.yaml  -o json --debug --restart-policy OnFailure


 
The content of the yaml file below:


            apiVersion: 2018-06-01
            location: eastus2
            name: testwebapp.linux
            properties:
              containers:
              - name: testwebapp
                properties:
                  image: testrestacreu2.azurecr.io/testwebapp.linux:latest
                  command: ["./TestWebApp","--url", "http://*:80/"]
                  resources:
                    requests:
                      cpu: .4
                      memoryInGb: .3          
                ports:
                - port: 80          
            osType: Linux
            ipAddress:
              type: Public
              ports:
              - protocol: tcp
                port: '80'
			  dnsNameLabel: testrestaci
              imageRegistryCredentials:
              - server: testrestacreu2.azurecr.io
                username: 315292d7-f644-43e6-b819-83e6758682a5
                password: 817da99e-ebbc-4277-8076-6bec3dd873d9
            tags: null
            type: Microsoft.ContainerInstance/containerGroups



For instance below the creation of an Alpine container:

        C:\git\me\TestFunctionRestAPI>  az container create --resource-group TestFunctionRestAPIrg --name testwebapp.linux-musl -f Docker\testwebapp.linux-musl.aci.yaml  -o json --debug --restart-policy OnFailure


 
The content of the yaml file below:


            apiVersion: 2018-06-01
            location: eastus2
            name: testwebapp.linux-musl
            properties:
              containers:
              - name: testwebapp
                properties:
                  image: testrestacreu2.azurecr.io/testwebapp.linux-musl:latest
                  command: ["./TestWebApp","--url", "http://*:80/"]
                  resources:
                    requests:
                      cpu: .4
                      memoryInGb: .3          
                ports:
                - port: 80          
            osType: Linux
            ipAddress:
              type: Public
              ports:
              - protocol: tcp
                port: '80'
			  dnsNameLabel: testrestaci
              imageRegistryCredentials:
              - server: testrestacreu2.azurecr.io
                username: 315292d7-f644-43e6-b819-83e6758682a5
                password: 817da99e-ebbc-4277-8076-6bec3dd873d9
            tags: null
            type: Microsoft.ContainerInstance/containerGroups






4. With your favorite Browser open the Azure portal https://portal.azure.com/ 
Navigate to the resource group where you deployed your container instance.
Check that the Container Instance has been created.


     <img src="https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/acicreate.png"/>
   


     Click on the new Container Instance, and check that the new instance is consuming CPU, Memory, ingress and egress:

     
     <img src="https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/acimonitor.png"/>
   


### VERIFYING THE CONTAINER RUNNING IN AZURE
You can receive on your local machine the logs from the Container running in Azure with Azure CLI with the following command: </p>
**Azure CLI 2.0:** az container attach --resource-group "ResourceGroupName" --name "ContainerGroupName"  </p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az container attach --resource-group TestFunctionRestAPIrg --name testwebapp.linux


If you want to browse the files and the folders in the container while the container instance is running, you can use the following command:</p>
**Azure CLI 2.0:** az container exec --resource-group "ResourceGroupName" --name "ContainerGroupName"  --exec-command "/bin/bash"</p>


        C:\git\me\TestFunctionRestAPI>  az container exec --resource-group TestFunctionRestAPIrg --name testwebapp.linux --exec-command "/bin/bash"


### TROUBLESHOOTING YOUR IMAGE
If your image keep on rebooting, you can troubleshoot the issue creating the following instance from the image:
**Azure CLI 2.0:** az container create -g "ResourceGroupName" --name "ContainerGroupName" --image "ACRName".azurecr.io/"ImageName:ImageTag" --command-line "tail -f /dev/null" --registry-username "UserName" --registry-password "Password" </p>
For instance:

        C:\git\me\TestFunctionRestAPI>  az container create -g TestFunctionRestAPIrg --name testwebapp.linux --image testrestacreu2.azurecr.io/testwebapp.linux:latest --command-line "tail -f /dev/null" --registry-username 40e21cbe-9b70-469f-80da-4369e02ebc58 --registry-password 783c8982-1c2b-4048-a70f-c9a21f5eba8f

After this command, your image should not keep on rebooting, and you could browse the files and the folders in the container while the container instance is running, with the following command:</p>
**Azure CLI 2.0:** az container exec --resource-group "ResourceGroupName" --name "ContainerGroupName"  --exec-command "/bin/bash"</p>


        C:\git\me\TestFunctionRestAPI>  az container exec --resource-group TestFunctionRestAPIrg --name testwebapp.linux --exec-command "/bin/bash"



## Deploying TestWebApp in AKS (Azure Kubernetes Service)
Using the same container image in the Azure Container Registry you can deploy the same container image in Azure Kubernetes Service (AKS).</p>
You'll find further information here:</p>
https://docs.microsoft.com/fr-fr/azure/aks/tutorial-kubernetes-deploy-cluster 


<img src="https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/aks.png"/>


### CREATING SERVICE PRINCIPAL FOR AKS DEPLOYMENT

1. With Azure CLI create an Service Principal:
**Azure CLI 2.0:** az ad sp create-for-rbac --skip-assignment </p>
For instance:


          C:\git\me\TestFunctionRestAPI>  az ad sp create-for-rbac --skip-assignment
 
      The command returns the following information associated with the new Service Principal:
      - appID
      - displayName
      - name
      - password
      - tenant

     For instance:


          AppId                                 Password                            
          ------------------------------------  ------------------------------------
          d604dc61-d8c0-41e2-803e-443415a62825  097df367-7472-4c23-96e1-9722e1d8270a



2. Display the ID associated with the new Azure Container Registry using the following command:</p>
In order to allow the Service Principal to have access to the Azure Container Registry you need to display the ACR resource ID with the following command:</p>
**Azure CLI 2.0:** az acr show --name "ACRName" --query id --output tsv</p>
For instance:


        C:\git\me\TestFunctionRestAPI>  az acr show --name testrestacreu2 --query id --output tsv

     The command returns ACR resource ID.

     For instance:

        /subscriptions/e5c9fc83-fbd0-4368-9cb6-1b5823479b6d/resourceGroups/acrrg/providers/Microsoft.ContainerRegistry/registries/testrestacreu2


3. Allow the Service Principal to have access to the Azure Container Registry with the following command:</p>
**Azure CLI 2.0:** az role assignment create --assignee "AppID" --scope "ACRReourceID" --role Reader
 For instance:

        C:\git\me\TestFunctionRestAPI>  az role assignment create --assignee d604dc61-d8c0-41e2-803e-443415a62825 --scope /subscriptions/e5c9fc83-fbd0-4368-9cb6-1b5823479b6d/resourceGroups/acrrg/providers/Microsoft.ContainerRegistry/registries/testrestacreu2 --role Reader


### CREATING A KUBERNETES CLUSTER
Now you can create the Kubernetes Cluster in Azure. </p>


1. With the following Azure CLI command create the Azure Kubernetes Cluster:</p>
**Azure CLI 2.0:** az aks create --resource-group "ResourceGroupName" --name "AKSClusterName" --dns-name-prefix testrestaks --node-vm-size Standard_D2s_v3   --node-count 1 --service-principal "SPAppID" --client-secret "SPPassword" --generate-ssh-keys </p>

     For instance:


        az aks create --resource-group TestFunctionRestAPIrg --name testnetcoreakscluster --dns-name-prefix testrestaks --node-vm-size Standard_D2s_v3   --node-count 1 --service-principal d604dc61-d8c0-41e2-803e-443415a62825   --client-secret 097df367-7472-4c23-96e1-9722e1d8270a --generate-ssh-keys

 
2. After few minutes, the Cluster is deployed. To connect to the cluster from your local computer, you use the Kubernetes Command Line Client. Use the following Azure CLI command to install the Kubernetes Command Line Client:
**Azure CLI 2.0:** az aks install-cli </p>


3. Connect the Kubernetes Command Line Client to your Cluster in Azure using the following Azure CLI command:
**Azure CLI 2.0:** az aks get-credentials --resource-group "ResourceGroupName" --name "AKSClusterName" </p>

     For instance:

        az aks get-credentials --resource-group TestFunctionRestAPIrg --name testnetcoreakscluster


4. Check the connection from the Kubernetes Command Line Client with the following command:
**kubectl:** kubectl get nodes

     The commmand will return information about the Kuberentes nodes.
     For instance:

        NAME                       STATUS    ROLES     AGE       VERSION
        aks-nodepool1-38201324-0   Ready     agent     16m       v1.12.8

     You are now connected to your cluster from your local machine.

### DEPLOYING THE IMAGE TO A KUBERNETES CLUSTER IN AZURE

1. You can list the Azure Container Registry per Resource Group using the following Azure CLI command: </p>
**Azure CLI 2.0:** az acr list --resource-group  "ResourceGroupName" </p>
For instance: 
 

        az acr list --resource-group  TestFunctionRestAPIrg

     it returns the list of ACR associated with this resource group.
     For instance:</p>


          NAME			  RESOURCE GROUP                LOCATION    SKU       LOGIN SERVER               CREATION DATE         ADMIN ENABLED
          ----------	  ----------------              ----------  --------  ---------------------      --------------------  ---------------
          testrestacreu2  TestFunctionRestAPIrg         eastus2     Standard  testrestacreu2.azurecr.io  2018-12-14T17:19:30Z



2. You can list the repository in each Azure Container Registry  using the following Azure CLI command: </p>
**Azure CLI 2.0:** az acr repository list --name "ACRName" --output table </p>

     For instance: 
 

        az acr repository list --name testrestacreu2 --output table


     It returns the list of images.

     For instance:

        Result
        --------------------
        testwebapp.linux
		testwebapp.linux-musl



3. You can deploy the same image in Azure Kubernetes Cluster using the YAML file testwebapp.linux.aks.yaml with Kubernetes Command Line Client: </p>
**kubectl:** kubectl apply -f "yamlfile" </p>

     For instance: 

          C:\git\me\TestFunctionRestAPI>  kubectl apply -f Docker\testwebapp.linux.aks.yaml
 
     Before launching this command you need to edit the file astool.pullpush.aks.yaml and update the line 28, and replace the field <AzureContainerRegistryName> with the Azure Container Registry Name. 

      - image: <AzureContainerRegistryName>.azurecr.io/testwebapp:latest
        name: testwebapp

     For instance:

      - image: testrestacreu2.azurecr.io/testwebapp:latest
        name: testwebapp
    

For instance below the content of a yaml file:


            apiVersion: apps/v1
            apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: testwebapplinux
              namespace: default
              labels: 
                 app: testwebapplinux
            spec:
              selector:
                matchLabels:
                  app: testwebapplinux
              replicas: 1
              template:
                metadata:
                  name: testwebapplinux
                  labels:
                    app: testwebapplinux
                spec:
                  containers:
                  - name: testwebapplinux
                    image: testrestacreu2.azurecr.io/testwebapp.linux:latest
                    command: ["./TestWebApp","--url", "http://*:80/"]
                    imagePullPolicy: IfNotPresent
                    resources: 
                      requests:
                        cpu: .4
                        memory: 300Mi
                    ports:
                    - containerPort: 80
            ---
            apiVersion: v1
            kind: Service
            metadata:
              name: testwebapplinux
              labels: 
                 app: testwebapplinux
            spec:
              type: LoadBalancer
              ports:
              - protocol: TCP 
                port: 80
              selector:
                app: testwebapplinux





4. You can check the new deployment with Kubernetes Command Line Client: </p>
**kubectl:** kubectl get deployments </p>

     For instance: 
 

        kubectl get deployments

     This command returns a result like this one below:


            NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
            testwebapplinux            0         0         0            0           35s




5. You can retrieve the IP address of the REST API services using the Kubernetes Command Line Client: </p>
**kubectl:** kubectl get services </p>

     For instance: 
 

        kubectl get services

     This command returns a result like the one below where the External IP is the public IP addresse associated with the REST API service:


			NAME              TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
            kubernetes        ClusterIP      10.0.0.1       <none>        443/TCP        14m
            testwebapplinux   LoadBalancer   10.0.207.148   40.79.57.4    80:30672/TCP   70s


### VERIFYING THE IMAGE DEPLOYMENT IN A KUBERNETES CLUSTER IN AZURE


1. You can list the pods associated with your AKS Deployment with Kubernetes Command Line Client: </p>
**kubectl:** kubectl get pods </p>

     It returns the list of pods associated with your deployment for instance:

            NAME                                        READY     STATUS    RESTARTS   AGE
            testwebapplinux-64556b657f-khct7            1/1       Running   2          79s


2. You can stop the pod using the following command with Kubernetes Command Line Client: </p>
**kubectl:** kubectl scale --replicas=0 deployment/testwebapplinux </p>

     If you run the command "kubectl get pods" again, you'll see the pod is not running anymore.


3. You can restart the pod using the following command with Kubernetes Command Line Client: </p>
**kubectl:** kubectl scale --replicas=1 deployment/testwebapplinux </p>

     If you run the command "kubectl get pods" again, you'll see the pod is running again.

     For instance:

            NAME                                        READY     STATUS    RESTARTS   AGE
            testwebapplinux-84556b657f-khct7            1/1       Running   2          43s


4. With your favorite Browser open the Azure portal https://portal.azure.com/ 
Navigate to the resource group where you deployed your Kubernetes service.
Check that the Kubernetes service has been created.


     <img src="https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/akscreate.png"/>
   


     Click on the new AKS cluster, select the Insights in the monitoring section and check that your container is still running:

     
     <img src="https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/aksmonitor.png"/>
   

# Next Steps

1. Automate the Vegeta Tests  
