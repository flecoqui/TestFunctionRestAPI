#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script is used to deploy nginx, keda, prometheus and webapi containers 
#- Parameters are:
# Parameter 1: resourceGroupName - resource group where the component will be depoyed
# Parameter 2: aksClusterName - AKS Cluster name
# Parameter 3: functionAName - WebAPI service A name
# Parameter 4: functionBName - WebAPI service A name
# Parameter 5: nameSpace - kubernetes namespace
###########################################################################################################################################################################################


parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
source_file="$(basename "${BASH_SOURCE[0]}")"

cd "$parent_path"

# Parameter 1 resourceGroupName 
# Parameter 2 aksClusterName 
# Parameter 3 functionAName
# Parameter 4 functionBName
# Parameter 5 nameSpace
resourceGroupName=$1
aksClusterName=$2 
functionAName=$3
functionBName=$4
nameSpace=$5

#######################################################
#- function used to print out script usage
#######################################################
function usage() {
    echo
    echo "Arguments:"
    echo -e "\tParameter 1: resourceGroupName - resource group where the component will be depoyed"
    echo -e "\tParameter 2: aksClusterName - AKS Cluster name"
    echo -e "\tParameter 3: functionAName - WebAPI service A name"
    echo -e "\tParameter 4: functionBName - WebAPI service A name"
    echo -e "\tParameter 5: nameSpace - kubernetes namespace"
    echo
    echo "Example:"
    echo -e "./"$source_file" TestFunctionRestAPIrg testrestapiakscluster testrestapiacrwebapia testrestapiacrwebapib ingress-nginx"
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


WriteLog "Uninstalling nginx Ingress controller with Helm" 
helm uninstall ingress-controller -n $nameSpace 


WriteLog "Uninstalling Prometheus to monitor nginx Ingress controller" 
helm uninstall prometheus-server -n $nameSpace

WriteLog "Uninstalling Keda with Helm" 
helm uninstall keda -n $nameSpace 

WriteLog "Uninstalling WebAPI Net Core 3.1 container hosting the function A" 
helm uninstall $functionAName -n $nameSpace 

WriteLog "Uninstalling WebAPI Net Core 3.1 container hosting the function B" 
helm uninstall $functionBName -n $nameSpace 

WriteLog "Deleting namespace: "$nameSpace
kubectl delete namespaces $nameSpace


WriteLog "Uninstallation completed !" 

fi
exit 0 


