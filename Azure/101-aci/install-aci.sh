#!/bin/bash
# Parameter 1 resourceGroupName 
# Parameter 2 prefixName 
# Parameter 3 cpuCores 
# Parameter 4 memoryInGb
resourceGroupName=$1
prefixName=$2 
cpuCores=$3 
memoryInGb=$4



#############################################################################
WriteLog()
{
	echo "$1"
	echo "$1" >> ./install-aci.log
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
if [ -z "$cpuCores" ]; then
   cpuCores=0.4
   exit 1
fi
if [ -z "$memoryInGb" ]; then
   memoryInGb=0.3
   exit 1
fi



environ=`env`
WriteLog "Environment before installation: $environ"

WriteLog "Installation script is starting for resource group: $resourceGroupName with prefixName: $prefixName cpu: $cpuCores memory: $memoryInGb 
check_os
if [ $iscentos -ne 0 ] && [ $isredhat -ne 0 ] && [ $isubuntu -ne 0 ] && [ $isdebian -ne 0 ];
then
    WriteLog "unsupported operating system"
    exit 1 
else
# To be completed
acrName=$prefixName'acr'
acrDeploymentName=$prefixName'acrdep'
acrSPName=$prefixName'acrsp'
akvName=$prefixName'akv'
acrSPPassword=''
acrSPAppId=''
acrSPObjectId=''
akvDeploymentName=$prefixName'akvdep'
aciDeploymentName=$prefixName'acidep'
imageName='testwebapp.linux'
imageNameId=$imageName':{{.Run.ID}}'
imageTag='latest'
latestImageName=$imageName':'$imageTag
imageTask='testwebapplinuxtask'
githubrepo='https://github.com/flecoqui/TestRESTAPIServices.git'
githubbranch='master'
dockerfilepath='Docker/Dockerfile.linux'

WriteLog "Installation script is starting for resource group: " $resourceGroupName " with prefixName: " $prefixName " cpuCores: " $cpuCores " memoryInGb: " $memoryInGb 
WriteLog "Creating Azure Container Registry" 
az group deployment create -g $resourceGroupName -n $acrDeploymentName --template-file azuredeploy.acr.json --parameter namePrefix=$prefixName --verbose -o json 
az group deployment show -g $resourceGroupName -n $acrDeploymentName --query properties.outputs

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
az group deployment create -g $resourceGroupName -n $akvDeploymentName --template-file azuredeploy.akv.json --parameter namePrefix=$prefixName objectId=$acrSPObjectId  appId=$acrSPAppId  password=$acrSPPassword --verbose -o json
az group deployment show -g $resourceGroupName -n $akvDeploymentName --query properties.outputs

pullusr=$acrName'-pull-usr'
pullpwd=$acrName'-pull-pwd'

az keyvault secret show --vault-name $akvName --name $pullusr --query value -o tsv > akvappid.txt
az keyvault secret show --vault-name $akvName --name $pullpwd --query value -o tsv > akvpassword.txt

WriteLog "Deploying a container on Azure Container Instance" 
#$cmdtest = "az group deployment create -g " + $resourceGroupName +" -n " + $aciDeploymentName + "--template-file azuredeploy.aci.json --parameter namePrefix=" + $prefixName + " imageName=" + $imageName +" appId=" + $acrSPAppId + " password=" + $acrSPPassword +"  cpuCores='0.4' memoryInGb='0.3' --verbose -o json"
#WriteLog $cmdtest


az group deployment create -g $resourceGroupName -n $aciDeploymentName --template-file azuredeploy.aci.json --parameter namePrefix=$prefixName imageName=$latestImageName  appId=$acrSPAppId  password=$acrSPPassword cpuCores=$cpuCores memoryInGb=$memoryInGb --verbose -o json
az group deployment show -g $resourceGroupName -n $aciDeploymentName --query properties.outputs



WriteLog "Installation completed !" 


fi
exit 0 


