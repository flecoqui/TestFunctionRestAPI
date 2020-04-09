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

* **Linux Pre-requisite installation script:** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-software.sh </p>
* **Windows Pre-requisite installation powershell script:** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-software-windows.ps1 </p>
* **Azure Function ARM Template Linux:** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/azuredeploy.json </p>
* **Linux Installation script for Function stored on Docker Hub and deployed on AKS:** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-dockerhub-function.sh </p>
* **Windows Installation script for Function stored on Docker Hub and deployed on AKS:** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-dockerhub-function-windows.ps1 </p>
* **Linux Installation script for Function stored on Azure Container Registry and deployed on AKS:** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-acr-function.sh </p>
* **Windows Installation script for Function stored on Azure Container Registry and deployed on AKS:** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-acr-function-windows.ps1 </p>
* **Linux Installation script for .Net Core 3.1 Web Api stored on Azure Container Registry and deployed on AKS:** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-acr-webapi.sh </p>
* **Windows Installation script for .Net Core 3.1 Web Api stored on Azure Container Registry and deployed on AKS:** https://github.com/flecoqui/TestFunctionRestAPI/blob/master/install-aks-acr-webapi-windows.ps1 </p>


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



Below the final architecture with the different pods:

![](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/1-architecture-webapi.png)


### DEPLOY TWO DIFFERENT .Net Core 3.1 WEBAPI SERVICES ON AZURE KUBERNETES SERVICE USING AZURE CONTAINER REGISTRY AND A SPECIFIC SCALABILTY RULE FOR EACH SERVICE:

The objective of this chapter is to show how to:
- deploy two different .Net Core 3.1 Web API services on the same AKS Cluster
- define scalabilty rule specific to each service using Prometheus

In order to deploy the 2 REST API on Azure Container Instance or Azure Kubernetes, you will use a Powershell script on Windows and a Bash script on Linux with the following parameters:</p>
* **ResourceGroupName:**						The name of the resource group used to deploy Azure Function, Azure App Service and Virtual Machine</p>
* **namePrefix:**						The name prefix which has been used to deploy the 2 Web API Service, the first service will be called: "{namePrefix}acrwebapia" and the second service "{namePrefix}acrwebapib" .</p>
* **aksVMSize:**                        The size of the Virtual Machine running on the Kubernetes Cluster, for instance: Standard_D4s_v3, by default Standard_D2s_v3</p>
* **aksNodeCount:**                         The number of node for the Kubernetes Cluster</p>
</p>
</p>


The service called: "{namePrefix}acrwebapia" will expose a prometheus counter called "{namePrefix}acrwebapia_http_request".
The service called: "{namePrefix}acrwebapib" will expose a prometheus counter called "{namePrefix}acrwebapib_http_request".

Those counter will be used to trigger the autoscale mechanism. The autoscale rule is define the file keda-prometheus.yaml


        apiVersion: keda.k8s.io/v1alpha1
        kind: ScaledObject
        metadata:
            name: prometheus-scaledobject
            namespace: ingress-nginx
            labels:
                deploymentName: function-<FunctionName>-http
        spec:
            scaleTargetRef:
                deploymentName: function-<FunctionName>-http
            pollingInterval: 15
            cooldownPeriod:  30
            minReplicaCount: 1
            maxReplicaCount: 10
            triggers:
            - type: prometheus
            metadata:
                serverAddress: http://prometheus-server.ingress-nginx.svc.cluster.local:9090
                metricName: access_frequency
                threshold: '1'
                query: sum(rate(<FunctionName>_http_request[1m]))


Below the command lines for Windows and Linux, before launching the command line below check that the Docker Deamon is running on your machine:

* **Powershell Windows:** C:\git\Me\TestFunctionRestAPI> .\install-aks-acr-webapi-prometheus-windows.ps1  "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" 

* **Bash Linux:** ./install-aks-acr-webapi-prometheus.sh "ResourceGroupName" "NamePrefix" "aksVMSize" "aksNodeCount" 


For instance:

    ./install-aks-acr-webapi-prometheus.sh TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 

    C:\git\Me\TestFunctionRestAPI> .\install-aks-acr-webapi-prometheus-windows.ps1 TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 



Below the final architecture with the different pods:

![](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/1-architecture-multi-webapi.png)


Once the solution is deployed, you can check whether the prometheus counter exposed by the 2 REST API are visible on the prometheus server running the following kubectl commands:

List the pods running in the ingress-nginx namespace:


        kubectl get pods  -n ingress-nginx

        NAME                                                              READY   STATUS    RESTARTS   AGE
        function-testrestapiacrwebapia-http-6cf4c7bbdc-p7n2m              1/1     Running   0          9m17s
        function-testrestapiacrwebapib-http-6cf99dd85b-n77rq              1/1     Running   0          46m
        ingress-controller-nginx-ingress-controller-5bb68d7957-8ftss      1/1     Running   0          48m
        ingress-controller-nginx-ingress-controller-5bb68d7957-qtdd5      1/1     Running   0          48m
        ingress-controller-nginx-ingress-default-backend-7cdd9c96fss6vv   1/1     Running   0          48m
        keda-operator-6bdf8cbb68-n98hk                                    1/1     Running   0          46m
        keda-operator-metrics-apiserver-78cd458bf-dh29z                   1/1     Running   0          46m
        prometheus-server-7f56b89f78-pjdhc                                1/1     Running   0          46m

Note the name of the prometheus server pod and forward the tcp port 9090 to yuor machine:

        kubectl port-forward  prometheus-server-7f56b89f78-pjdhc -n ingress-nginx 9090:9090

In another command shell run the following command to display the value of the counter which will trigger the autoscale mechanism:

        curl -g http://localhost:9090/api/v1/query?query=sum(rate(<functionName>_http_request[1m]))

        {"status":"success","data":{"resultType":"vector","result":[{"metric":{},"value":[1585926783.956,"0"]}]}}


### COLLECTING PROMETHEUS METRICS WITH AZURE MONITOR

Now your AKS deployment is running using Prometheus and Keda to trigger the autoscale.
As Prometheus has been deployed, you can collect all the Prometheus metrics using Azune Monitor.

First you need to enable Azure Monitor on your AKS Cluster with the following Azure CLI command:

        az aks enable-addons -a monitoring -n MyExistingManagedCluster -g MyExistingManagedClusterRG  

For instance:

        az aks enable-addons -a monitoring -n testrestapiaksCluster -g TestFunctionRestAPIrg  

Check if the omsagent has been deployed on your AKS Cluster runnning the following command:


        kubectl get pods -n kube-system

You should see a pod with a name starting with omsagent-rs:

        C:\git\me\TestFunctionRestAPI\TestFunctionAppv3.1>kubectl get pods -n kube-system
        NAME                                    READY   STATUS    RESTARTS   AGE
        coredns-698c77c5d7-p4qgj                1/1     Running   1          2d3h
        coredns-698c77c5d7-tzzb6                1/1     Running   1          2d3h
        coredns-autoscaler-79b778686c-cxfjm     1/1     Running   1          2d3h
        kube-proxy-5kxzq                        1/1     Running   1          2d3h
        kube-proxy-kh925                        1/1     Running   1          2d3h
        kube-proxy-xj7w8                        1/1     Running   1          2d3h
        kubernetes-dashboard-74d8c675bc-pwx27   1/1     Running   3          2d3h
        metrics-server-69df9f75bf-mhb9w         1/1     Running   2          2d3h
        omsagent-rs-68c66868fd-cjfkl            1/1     Running   2          2d3h
        tunnelfront-d9656675f-pgwhf             1/1     Running   1          2d3h

Now, you can define which metrics you want to collect in editing the file configmap.yaml here: https://github.com/flecoqui/TestFunctionRestAPI/blob/master/TestFunctionAppv3.1/configmap.yaml

Content below:

        kind: ConfigMap
        apiVersion: v1
        data:
        schema-version:
            #string.used by agent to parse config. supported versions are {v1}. Configs with other schema versions will be rejected by the agent.
            v1
        config-version:
            #string.used by customer to keep track of this config file's version in their source control/repository (max allowed 10 chars, other chars will be truncated)
            ver1
        log-data-collection-settings: |-
            # Log data collection settings
            # Any errors related to config map settings can be found in the KubeMonAgentEvents table in the Log Analytics workspace that the cluster is sending data to.

            [log_collection_settings]
            [log_collection_settings.stdout]
                # In the absense of this configmap, default value for enabled is true
                enabled = true
                # exclude_namespaces setting holds good only if enabled is set to true
                # kube-system log collection is disabled by default in the absence of 'log_collection_settings.stdout' setting. If you want to enable kube-system, remove it from the following setting.
                # If you want to continue to disable kube-system log collection keep this namespace in the following setting and add any other namespace you want to disable log collection to the array.
                # In the absense of this configmap, default value for exclude_namespaces = ["kube-system"]
                exclude_namespaces = ["kube-system"]

            [log_collection_settings.stderr]
                # Default value for enabled is true
                enabled = true
                # exclude_namespaces setting holds good only if enabled is set to true
                # kube-system log collection is disabled by default in the absence of 'log_collection_settings.stderr' setting. If you want to enable kube-system, remove it from the following setting.
                # If you want to continue to disable kube-system log collection keep this namespace in the following setting and add any other namespace you want to disable log collection to the array.
                # In the absense of this cofigmap, default value for exclude_namespaces = ["kube-system"]
                exclude_namespaces = ["kube-system"]

            [log_collection_settings.env_var]
                # In the absense of this configmap, default value for enabled is true
                enabled = true
            [log_collection_settings.enrich_container_logs]
                # In the absense of this configmap, default value for enrich_container_logs is false
                enabled = false
                # When this is enabled (enabled = true), every container log entry (both stdout & stderr) will be enriched with container Name & container Image
            [log_collection_settings.collect_all_kube_events]
                # In the absense of this configmap, default value for collect_all_kube_events is false
                # When the setting is set to false, only the kube events with !normal event type will be collected
                enabled = false
                # When this is enabled (enabled = true), all kube events including normal events will be collected
        prometheus-data-collection-settings: |-
            # Custom Prometheus metrics data collection settings
            [prometheus_data_collection_settings.cluster]
                # Cluster level scrape endpoint(s). These metrics will be scraped from agent's Replicaset (singleton)
                # Any errors related to prometheus scraping can be found in the KubeMonAgentEvents table in the Log Analytics workspace that the cluster is sending data to.

                #Interval specifying how often to scrape for metrics. This is duration of time and can be specified for supporting settings by combining an integer value and time unit as a string value. Valid time units are ns, us (or µs), ms, s, m, h.
                interval = "1m"

                ## Uncomment the following settings with valid string arrays for prometheus scraping
                #fieldpass = ["metric_to_pass1", "metric_to_pass12"]

                #fielddrop = ["metric_to_drop"]

                # An array of urls to scrape metrics from.
                urls = ["http://10.244.2.13:10254/metrics","http://10.244.1.9:10254/metrics","http://10.244.1.13:8383/metrics","http://10.244.2.12:9090/metrics"]

                # An array of Kubernetes services to scrape metrics from.
                # kubernetes_services = ["http://my-service-dns.my-namespace:9102/metrics"]

                # When monitor_kubernetes_pods = true, replicaset will scrape Kubernetes pods for the following prometheus annotations:
                # - prometheus.io/scrape: Enable scraping for this pod
                # - prometheus.io/scheme: If the metrics endpoint is secured then you will need to
                #     set this to `https` & most likely set the tls config.
                # - prometheus.io/path: If the metrics path is not /metrics, define it with this annotation.
                # - prometheus.io/port: If port is not 9102 use this annotation
                monitor_kubernetes_pods = true

                ## Restricts Kubernetes monitoring to namespaces for pods that have annotations set and are scraped using the monitor_kubernetes_pods setting.
                ## This will take effect when monitor_kubernetes_pods is set to true
                ##   ex: monitor_kubernetes_pods_namespaces = ["default1", "default2", "default3"]
                # monitor_kubernetes_pods_namespaces = ["default1"]

            [prometheus_data_collection_settings.node]
                # Node level scrape endpoint(s). These metrics will be scraped from agent's DaemonSet running in every node in the cluster
                # Any errors related to prometheus scraping can be found in the KubeMonAgentEvents table in the Log Analytics workspace that the cluster is sending data to.

                #Interval specifying how often to scrape for metrics. This is duration of time and can be specified for supporting settings by combining an integer value and time unit as a string value. Valid time units are ns, us (or µs), ms, s, m, h.
                interval = "1m"

                ## Uncomment the following settings with valid string arrays for prometheus scraping

                # An array of urls to scrape metrics from. $NODE_IP (all upper case) will substitute of running Node's IP address
                # urls = ["http://$NODE_IP:9103/metrics"]

                #fieldpass = ["metric_to_pass1", "metric_to_pass12"]

                #fielddrop = ["metric_to_drop"]
        metadata:
        name: container-azm-ms-agentconfig
        namespace: kube-system

You can for instance define the list of pods to scrape in updating the field urls:
             
             
             urls = ["http://10.244.2.13:10254/metrics","http://10.244.1.9:10254/metrics","http://10.244.1.13:8383/metrics","http://10.244.2.12:9090/metrics"]

You can also activate the default prometheus scrape in updating the variable monitor_kubernetes_pods

                monitor_kubernetes_pods = true

When the file configmap.yaml is ready, apply this file with the following command:


        C:\git\me\TestFunctionRestAPI\TestFunctionAppv3.1>Kubectl apply -f  configmap.yaml


After few minutes, if you select Azure Logs for the AKS Cluster on the Azure portal:

![](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/azurelogs-1.png)


You can try to launch the following query :

        InsightsMetrics | where Namespace == "prometheus" and Name == "<FunctionName>_http_request"

And you should see a result like this one:

![](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/azurelogs-2.png)


below the architecture  with the omsagent:

![](https://raw.githubusercontent.com/flecoqui/TestFunctionRestAPI/master/Docs/1-architecture-webapi-omsagent.png)



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
