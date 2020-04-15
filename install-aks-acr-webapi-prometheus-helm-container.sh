#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script is used to deploy nginx, keda, prometheus and webapi containers 
#- Parameters are:
# Parameter 1: resourceGroupName - resource group where the component will be depoyed
# Parameter 2 aksClusterName - AKS Cluster name
# Parameter 3 acrDNSName - Azure Container Registry DNS name
# Parameter 4 imageName - WebAPI Container Image name
# Parameter 5 imageTag - WebAPI Container Image Tag
# Parameter 6 acrPassword - Azure Container Registry secret to pull the image
# Parameter 7 functionAName - WebAPI service A name
# Parameter 8 functionBName - WebAPI service A name
# Parameter 9 nameSpace - kubernetes namespace
###########################################################################################################################################################################################


parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
source_file="$(basename "${BASH_SOURCE[0]}")"

cd "$parent_path"

# Parameter 1 resourceGroupName 
# Parameter 2 aksClusterName 
# Parameter 3 acrDNSName
# Parameter 4 imageName
# Parameter 5 imageTag
# Parameter 6 acrPassword
# Parameter 7 functionAName
# Parameter 8 functionBName
# Parameter 9 nameSpace
resourceGroupName=$1
aksClusterName=$2 
acrDNSName=$3
imageName=$4
imageTag=$5
acrPassword=$6
functionAName=$7
functionAName=$8
nameSpace=$9

#######################################################
#- function used to print out script usage
#######################################################
function usage() {
    echo
    echo "Arguments:"
    echo -e "\tParameter 1: resourceGroupName - resource group where the component will be depoyed"
    echo -e "\tParameter 2: prefixName - prefix name which will be used to name the azure resources"
    echo -e "\tParameter 3: aksVMSize - size of the Virtual Machine in the AKS cluster"
    echo -e "\tParameter 4: aksNodeCount - number of virtual Machnine in the AKS cluster"
    echo
    echo "Example:"
    echo -e "./"$source_file" TestFunctionRestAPIrg testrestapi  Standard_D2_v2 3 "
}

#######################################################
#- function used to log strings
#######################################################
WriteLog()
{
	echo "$1"
	echo "$1" >> "./"$source_file".log"
}
#######################################################
#- function used to get the first line of a file
#######################################################
function Get-FirstLine()
{
        local file=$1

        while read p; do
                echo $p
                return
        done < $file
		echo ''
}

#######################################################
#- function used to get the value of a password field in 
#           a file
#######################################################
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
#######################################################
#- function used to get public IP address in a kubectl 
#           response
#######################################################
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
#######################################################
#- function used to check the operating system 
#######################################################
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
   usage
   exit 1
fi
if [ -z "$aksClusterName" ]; then
   WriteLog 'aksClusterName not set'
   usage
   exit 1
fi
if [ -z "$acrDNSName" ]; then
   WriteLog 'acrDNSName not set'
   usage
   exit 1
fi
if [ -z "$imageName" ]; then
   WriteLog 'imageName not set'
   usage
   exit 1
fi
if [ -z "$imageTag" ]; then
   WriteLog 'imageTag not set'
   usage
   exit 1
fi
if [ -z "$acrPassword" ]; then
   WriteLog 'acrPassword not set'
   usage
   exit 1
fi
if [ -z "$functionAName" ]; then
   WriteLog '$functionAName not set'
   usage
   exit 1
fi
if [ -z "$functionBName" ]; then
   WriteLog '$functionBName not set'
   usage
   exit 1
fi
if [ -z "$nameSpace" ]; then
   WriteLog 'nameSpace not set'
   usage
   exit 1
fi



environ=`env`
WriteLog "Environment before installation: $environ"

check_os
if [ $iscentos -ne 0 ] && [ $isredhat -ne 0 ] && [ $isubuntu -ne 0 ] && [ $isdebian -ne 0 ];
then
    WriteLog "unsupported operating system"
    exit 1 
else

WriteLog "Getting kubernetes cluster credentials" 
az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName --overwrite-existing 


WriteLog "Creating the name space: "$nameSpace 
kubectl create namespace $nameSpace

WriteLog "Deploying nginx Ingress controller with Helm" 
#helm install ingress-controller stable/nginx-ingress --namespace $nameSpace --set controller.replicaCount=2 --set controller.metrics.enabled=true --set controller.podAnnotations."prometheus\.io/scrape"="true" --set controller.podAnnotations."prometheus\.io/port"="10254"
helm install ingress-controller ./charts/nginx-ingress -n $nameSpace --set controller.replicaCount=2 --set controller.metrics.enabled=true --set controller.podAnnotations."prometheus\.io/scrape"="true" --set controller.podAnnotations."prometheus\.io/port"="10254"


WriteLog "Waiting for Public IP address during 10 minutes max" 
count=0
IP='<pending>'
while [[ $IP = '<pending>' ]] || [[ $IP = '' ]] && [[ $count -lt 40 ]]
do
count=$((count+1))
#WriteLog "count"$count
WriteLog "Waiting for Public IP address"
sleep 15
kubectl get services -n $nameSpace > services.txt
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
az network public-ip update --ids $PublicIPId --dns-name $aksClusterName

# get the full dns name
PublicDNSName=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[dnsSettings.fqdn]" --output tsv)
WriteLog "Public DNS Name: "$PublicDNSName 

WriteLog "Deploying Prometheus to monitor nginx Ingress controller" 
#kubectl apply --kustomize github.com/kubernetes/ingress-nginx/deploy/prometheus/ 
helm install prometheus-server ./charts/prometheus -n $nameSpace

WriteLog "Deploying Keda with Helm" 
#helm install keda kedacore/keda --namespace ingress-nginx
helm install keda ./charts/keda -n $nameSpace

WriteLog "Deploying WebAPI Net Core 3.1 container hosting the function A" 
helm install $functionAName ./charts/webapiapp -n $nameSpace --set deployment.image.repository=$acrDNSName --set deployment.image.imageName=$imageName  --set deployment.image.tag=$imageTag  --set deployment.imagePullSecrets[0]."name"="$acrPassword"   --set deployment.deploymentAnnotations."prometheus\.io/scrape"="true" --set deployment.deploymentAnnotations."prometheus\.io/port"="80" --set deployment.deploymentAnnotations."prometheus\.io/path"="/metrics"

WriteLog "Deploying WebAPI Net Core 3.1 container hosting the function B" 
helm install $functionBName ./charts/webapiapp -n $nameSpace --set deployment.image.repository=$acrDNSName --set deployment.image.imageName=$imageName  --set deployment.image.tag=$imageTag  --set deployment.imagePullSecrets[0]."name"="$acrPassword"   --set deployment.deploymentAnnotations."prometheus\.io/scrape"="true" --set deployment.deploymentAnnotations."prometheus\.io/port"="80" --set deployment.deploymentAnnotations."prometheus\.io/path"="/metrics"


WriteLog "curl -d \"{\\\"name\\\":\\\"0123456789\\\"}\" -H \"Content-Type: application/json\"  -X POST   http://"$PublicDNSName"/"$functionAName"/api/values"
WriteLog "curl -H \"Content-Type: application/json\"  -X GET   http://"$PublicDNSName"/"$functionAName"/api/test"

WriteLog "curl -d \"{\\\"name\\\":\\\"0123456789\\\"}\" -H \"Content-Type: application/json\"  -X POST   http://"$PublicDNSName"/"$functionBName"/api/values"
WriteLog "curl -H \"Content-Type: application/json\"  -X GET   http://"$PublicDNSName"/"$functionBName"/api/test"


WriteLog "curl -d \"{\\\"name\\\":\\\"0123456789\\\"}\" -H \"Content-Type: application/json\"  -X POST   http://"$IP"/"$functionAName"/api/values"
WriteLog "curl -H \"Content-Type: application/json\"  -X GET   http://"$IP"/"$functionAName"/api/test"

WriteLog "curl -d \"{\\\"name\\\":\\\"0123456789\\\"}\" -H \"Content-Type: application/json\"  -X POST   http://"$IP"/"$functionBName"/api/values"
WriteLog "curl -H \"Content-Type: application/json\"  -X GET   http://"$IP"/"$functionBName"/api/test"



WriteLog "Installation completed !" 

fi
exit 0 


