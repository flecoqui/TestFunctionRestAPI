#!/bin/bash
# Parameter 1 resourceGroupName 
# Parameter 2 prefixName 
# Parameter 3 aksVMSize
# Parameter 4 aksNodeCount
resourceGroupName=$1
prefixName=$2 
aksVMSize=$3
aksNodeCount=$4


#############################################################################
WriteLog()
{
	echo "$1"
	echo "$1" >> ./install-aks-acr-webapi.log
}
#############################################################################
function Get-FirstLine()
{
        local file=$1

        while read p; do
                echo $p
                return
        done < $file
		echo ''
}

function Get-Password()
{
	local file=$1

	while read p; do 
		echo $p
		declare -a array=($(echo $p | tr ':' ' '| tr ',' ' '| tr '"' ' '))
		if [ ${#array[@]} > 1 ]; then
		  	if [ ${array[0]} = "password" ]; then
				echo ${array[1]}
				return
			fi
		fi
	done < $file
	echo ''
}
#############################################################################
function Get-PublicIP()
{
	local file=$1
	while read p; do 
		declare -a array=($(echo $p))
		if [ ${#array[@]} > 3 ]; then
		  	if [ ${array[1]} = "LoadBalancer" ]; then
				echo ${array[3]}
				return
			fi
		fi
	done < $file
	echo ''
}
#############################################################################
check_os() {
    grep ubuntu /proc/version > /dev/null 2>&1
    isubuntu=${?}
    grep centos /proc/version > /dev/null 2>&1
    iscentos=${?}
    grep redhat /proc/version > /dev/null 2>&1
    isredhat=${?}	
	if [ -f /etc/debian_version ]; then
    isdebian=0
	else
	isdebian=1	
    fi

	if [ $isubuntu -eq 0 ]; then
		OS=Ubuntu
		VER=$(lsb_release -a | grep Release: | sed  's/Release://'| sed -e 's/^[ \t]*//' | cut -d . -f 1)
	elif [ $iscentos -eq 0 ]; then
		OS=Centos
		VER=$(cat /etc/centos-release)
	elif [ $isredhat -eq 0 ]; then
		OS=RedHat
		VER=$(cat /etc/redhat-release)
	elif [ $isdebian -eq 0 ];then
		OS=Debian  # XXX or Ubuntu??
		VER=$(cat /etc/debian_version)
	else
		OS=$(uname -s)
		VER=$(uname -r)
	fi
	
	ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

	WriteLog "OS=$OS version $VER Architecture $ARCH"
}
if [ -z "$resourceGroupName" ]; then
   WriteLog 'resourceGroupName not set'
   exit 1
fi
if [ -z "$prefixName" ]; then
   WriteLog 'prefixName not set'
   exit 1
fi
if [ -z "$aksVMSize" ]; then
   aksVMSize='Standard_D2s_v3'
   exit 1
fi
if [ -z "$aksNodeCount" ]; then
   aksNodeCount=1
   exit 1
fi


environ=`env`
WriteLog "Environment before installation: $environ"

WriteLog "Installation script is starting for resource group: $resourceGroupName with prefixName: $prefixName  AKS VM Size: $aksVMSize and AKS node count: $aksNodeCount"
check_os
if [ $iscentos -ne 0 ] && [ $isredhat -ne 0 ] && [ $isubuntu -ne 0 ] && [ $isdebian -ne 0 ];
then
    WriteLog "unsupported operating system"
    exit 1 
else
# To be completed
functionName=$prefixName'acrwebapi' 
acrName=$prefixName'acr'
acrDNSName=$acrName'.azurecr.io'
acrDeploymentName=$prefixName'acrdep'
acrSPName=$prefixName'acrsp'
akvName=$prefixName'akv'
aksName=$prefixName'aks'
aksClusterName=$prefixName'akscluster'
acrSPPassword=''
acrSPAppId=''
acrSPObjectId=''
akvDeploymentName=$prefixName'akvdep'
aciDeploymentName=$prefixName'acidep'
aksDeploymentName=$prefixName'aksdep'
imageName='function-'$functionName
imageNameId=$imageName':{{.Run.ID}}'
imageTag='latest'
latestImageName=$imageName':'$imageTag
imageTask=$imageName'task'
githubrepo='https://github.com/flecoqui/TestFunctionRestAPI.git'
githubbranch='master'
dockerfilepath='TestFunctionAppv3.1\Dockerfile'

WriteLog "Installation script is starting for resource group: " $resourceGroupName " with prefixName: " $prefixName " AKS VM size: " $aksVMSize " AKS Node count: " $aksNodeCount
WriteLog "Creating Azure Container Registry" 
az deployment group create -g $resourceGroupName -n $acrDeploymentName --template-file azuredeploy.acr.json --parameter namePrefix=$prefixName --verbose -o json 
az deployment group show -g $resourceGroupName -n $acrDeploymentName --query properties.outputs

WriteLog "Building and registrying the image in Azure Container Registry"
# Command line below is used to build image directly from github
WriteLog "Creating task to build and register the image in Azure Container Registry"
az acr task create --image $imageNameId --image $latestImageName --name $imageTask --registry $acrName  --context $githubrepo --branch $githubbranch --file $dockerfilepath --commit-trigger-enabled false --pull-request-trigger-enabled false
WriteLog "Launching the task "
az acr task run  -n $imageTask -r $acrName


WriteLog "Creating Service Principal with role acrpull" 
az acr show --name $acrName --query id --output tsv > acrid.txt
acrID=$(Get-FirstLine ./acrid.txt) 
az ad sp create-for-rbac --name http://$acrSPName --scopes $acrID --role acrpull --query password --output tsv > sppassword.txt
#acrSPPassword=$(Get-Password ./sppassword.txt) 
acrSPPassword=$(Get-FirstLine ./sppassword.txt) 
if [ $acrSPPassword = "" ]; then
     WriteLog "ACR SP Password not found "
     exit 1
fi
WriteLog "SPPassword: "$acrSPPassword


az ad sp show --id http://$acrSPName --query appId --output tsv > spappid.txt
acrSPAppId=$(Get-FirstLine  ./spappid.txt)  
#$acrSPAppId = $acrSPAppId.replace("`n","").replace("`r","")

WriteLog "SPAppId: "$acrSPAppId

az ad signed-in-user show --query objectId --output tsv > spobjectid.txt
acrSPObjectId=$(Get-FirstLine  ./spobjectid.txt)  
#$acrSPObjectId = $acrSPObjectId.replace("`n","").replace("`r","")
WriteLog "SPObjectId: "$acrSPObjectId


WriteLog "Adding role Reader for Service Principal" 
az role assignment create --role Reader --assignee $acrSPAppId --scope $acrID 


WriteLog "Creating Azure Key Vault" 
az deployment group create -g $resourceGroupName -n $akvDeploymentName --template-file azuredeploy.akv.json --parameter namePrefix=$prefixName objectId=$acrSPObjectId  appId=$acrSPAppId  password=$acrSPPassword --verbose -o json
az deployment group show -g $resourceGroupName -n $akvDeploymentName --query properties.outputs

pullusr=$acrName'-pull-usr'
pullpwd=$acrName'-pull-pwd'

az keyvault secret show --vault-name $akvName --name $pullusr --query value -o tsv > akvappid.txt
az keyvault secret show --vault-name $akvName --name $pullpwd --query value -o tsv > akvpassword.txt

WriteLog "Deploying a kubernetes cluster" 
az aks create --resource-group $resourceGroupName --name $aksClusterName --dns-name-prefix $aksName --node-vm-size $aksVMSize   --node-count $aksNodeCount --service-principal $acrSPAppId   --client-secret $acrSPPassword --generate-ssh-keys
az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName --overwrite-existing 

WriteLog "Deploying a Tiller" 
kubectl --namespace kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

WriteLog "Preparing Helm repository" 
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo add kedacore https://kedacore.github.io/charts

WriteLog "Creating the name space" 
kubectl create namespace ingress-nginx

WriteLog "Deploying nginx Ingress controller with Helm" 
helm install ingress-controller stable/nginx-ingress --namespace ingress-nginx --set controller.replicaCount=2 --set controller.metrics.enabled=true --set controller.podAnnotations."prometheus\.io/scrape"="true" --set controller.podAnnotations."prometheus\.io/port"="10254"

WriteLog "Waiting for Public IP address during 10 minutes max" 
count=0
IP='<pending>'
while [[ $IP = '<pending>' ]] || [[ $IP = '' ]] && [[ $count -lt 40 ]]
do
count=$((count+1))
#WriteLog "count"$count
WriteLog "Waiting for Public IP address"
sleep 15
kubectl get services -n ingress-nginx > services.txt
# Public IP address of your ingress controller
IP=$(Get-PublicIP ./services.txt)
#WriteLog "ip"$IP
done


if  [[ $IP = '<pending>' ]]  || [[ $IP = '' ]];  then
	 WriteLog "Can't get the public IP address for container, stopping the installation"
     exit 1
fi
WriteLog "Public IP address: "$IP

# Name to associate with public IP address
dnsName=$aksName

# Get the resource-id of the public ip
PublicIPId=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" --output tsv)


WriteLog "Public IP address ID: "$PublicIPId 

# Update public ip address with DNS name
az network public-ip update --ids $PublicIPId --dns-name $dnsName

# get the full dns name
PublicDNSName=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[dnsSettings.fqdn]" --output tsv)
WriteLog "Public DNS Name: "$PublicDNSName 

WriteLog "Deploying Prometheus to monitor nginx Ingress controller" 
kubectl apply --kustomize github.com/kubernetes/ingress-nginx/deploy/prometheus/ 
kubectl -n ingress-nginx get svc
kubectl -n ingress-nginx get pods

WriteLog "Deploying Keda with Helm" 
helm install keda kedacore/keda --namespace ingress-nginx
kubectl get pods -n ingress-nginx

WriteLog "Creating Function App image and deploying it" 
# func init --docker-only
WriteLog "Azure Container Registry login for : "$acrName
az acr login --name $acrName
WriteLog "Azure Container Registry Getting password for : "$acrName
acrPassword=$(Get-FirstLine ./akvpassword.txt) 

WriteLog "Deploying WebAPI Net Core 3.1 container hosting the function" 
sed 's/<FunctionName>/'$functionName'/g' ./TestFunctionAppv3.1/webapideployment.yaml > local_webapi.yaml 
sed -i 's/<ACRName>/'$acrName'/g' local_webapi.yaml
sed -i 's/<ACRSecret>/'$acrPassword'/g' local_webapi.yaml
kubectl apply -f local_webapi.yaml


WriteLog "Deploying an Ingress resource pointing to the function" 
sed 's/<FunctionName>/'$functionName'/g' ./TestFunctionApp/testfunctionapp.yaml > local_func.yaml
sed -i 's/<AKSDnsName>/'$PublicDNSName'/g' local_func.yaml
kubectl apply -f local_func.yaml

WriteLog "Deploying an Ingress resource pointing to prometheus server" 
kubectl apply -f ./TestFunctionApp/ingress-prometheus.yaml

WriteLog "Deploying an Ingress resource pointing to the function" 
sed 's/<FunctionName>/'$functionName'/g' ./TestFunctionApp/keda-prometheus.yaml > local_keda.yaml
kubectl apply -f local_keda.yaml


WriteLog "curl -d \"{\\\"name\\\":\\\"0123456789\\\"}\" -H \"Content-Type: application/json\"  -X POST   http://"$PublicDNSName"/"$functionName"/api/values"
WriteLog "curl -H \"Content-Type: application/json\"  -X GET   http://"$PublicDNSName"/"$functionName"/api/test"


WriteLog "Installation completed !" 

fi
exit 0 


