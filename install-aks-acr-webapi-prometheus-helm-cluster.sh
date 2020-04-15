#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script is used to deploy Azure Container Registry, Azure Key Vault, Azure kubernetes Cluster 
#- Parameters are:
# Parameter 1: resourceGroupName - resource group where the component will be depoyed
# Parameter 2: prefixName - prefix name which will be used to name the azure resources
# Parameter 3: aksVMSize - size of the Virtual Machine in the AKS cluster
# Parameter 4: aksNodeCount - number of virtual Machnine in the AKS cluster
###########################################################################################################################################################################################

set -eu
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
source_file="$(basename "${BASH_SOURCE[0]}")"

cd "$parent_path"

# Parameter 1 resourceGroupName 
# Parameter 2 prefixName 
# Parameter 3 aksVMSize
# Parameter 4 aksNodeCount
resourceGroupName=$1
prefixName=$2 
aksVMSize=$3
aksNodeCount=$4


# Parameter 1 resourceGroupName 
# Parameter 2 prefixName 
# Parameter 3 aksVMSize
# Parameter 4 aksNodeCount
resourceGroupName=$1
prefixName=$2 
aksVMSize=$3
aksNodeCount=$4

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
if [ -z "$prefixName" ]; then
   WriteLog 'prefixName not set'
   usage
   exit 1
fi
if [ -z "$aksVMSize" ]; then
   aksVMSize='Standard_D2s_v3'
   usage
   exit 1
fi
if [ -z "$aksNodeCount" ]; then
   aksNodeCount=1
   usage
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
functionAName=$prefixName'acrwebapia' 
functionBName=$prefixName'acrwebapib' 
containerName=$prefixName'acrwebapi' 
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
imageName='function-'$containerName
imageNameId=$imageName':{{.Run.ID}}'
imageTag='latest'
latestImageName=$imageName':'$imageTag
imageTask=$imageName'task'
githubrepo='https://github.com/flecoqui/TestFunctionRestAPI.git'
githubbranch='master'
dockerfilepath='TestFunctionPrometheusAppv3.1\Dockerfile'

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


WriteLog "Getting ACR ID" 
az acr show --name $acrName --query id --output tsv > acrid.txt
acrID=$(Get-FirstLine ./acrid.txt) 
WriteLog "Removing previous Service Principal" 
az ad sp delete --id http://$acrSPName 
WriteLog "Creating Service Principal with role acrpull" 
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

WriteLog "Azure Container Registry Getting password for : "$acrName
acrPassword=$(Get-FirstLine ./akvpassword.txt) 

WriteLog "Deploying a kubernetes cluster" 
az aks create --resource-group $resourceGroupName --name $aksClusterName --dns-name-prefix $aksName --node-vm-size $aksVMSize   --node-count $aksNodeCount --service-principal $acrSPAppId   --client-secret $acrSPPassword --generate-ssh-keys
az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName --overwrite-existing 



WriteLog "Installation completed !" 
WriteLog "Results:" 
WriteLog "Resource Group: "$resourceGroupName
WriteLog "Cluster Name: "$aksClusterName
WriteLog "Azure Container Registry: "$acrDNSName
WriteLog "Azure Container Registry Image: "$imageName
WriteLog "Azure Container Registry Tag: "$imageTag
WriteLog "Azure Container Registry Secret: "$acrPassword
WriteLog "WebAPI Service A Name: "$functionAName
WriteLog "WebAPI Service A Name: "$functionBName
fi
exit 0 

