#!/bin/bash
# Parameter 1 resourceGroupName 
# Parameter 2 prefixName 
# Parameter 3 aksVMSize
# Parameter 4 aksNodeCount
# Parameter 5 dockerHubAccountName
resourceGroupName=$1
prefixName=$2 
aksVMSize=$3
aksNodeCount=$4
dockerHubAccountName=$5


#############################################################################
WriteLog()
{
	echo "$1"
	echo "$1" >> ./install-aks-dockerhub-function.log
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
if [ -z "$dockerHubAccountName" ]; then
   WriteLog 'Docker Hub Account Name not set'
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

WriteLog "Installation script is starting for resource group: $resourceGroupName with prefixName: $prefixName AKS VM Size: $aksVMSize AKS node count: $aksNodeCount Docker Hub Account: $dockerHubAccountName "
check_os
if [ $iscentos -ne 0 ] && [ $isredhat -ne 0 ] && [ $isubuntu -ne 0 ] && [ $isdebian -ne 0 ];
then
    WriteLog "unsupported operating system"
    exit 1 
else
# To be completed
functionName=$prefixName'hubfunc' 
acrName=$prefixName'acr'
acrDeploymentName=$prefixName'acrdep'
acrSPName=$prefixName'acrsp'
akvName=$prefixName'akv'
aksName=$prefixName'aks'
aksSPName=$prefixName'akssp'
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



WriteLog "Deploying a kubernetes cluster" 
WriteLog "Creating Service Principal for AKS cluster" 
az ad sp create-for-rbac --name http://$aksSPName --query password --output tsv > akssppassword.txt
az ad sp show --id http://$aksSPName --query appId --output tsv > aksspappid.txt
aksSPPassword=$(Get-FirstLine ./akssppassword.txt) 
aksSPAppId=$(Get-FirstLine ./aksspappid.txt) 
WriteLog "Creating AKS cluster" 
az aks create --resource-group $resourceGroupName --name $aksClusterName --dns-name-prefix $aksName --node-vm-size $aksVMSize   --node-count $aksNodeCount --generate-ssh-keys --service-principal $aksSPAppId --client-secret $aksSPPassword
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
cd ./TestFunctionApp
# func init --docker-only
func kubernetes deploy --name function-$functionName --namespace ingress-nginx --service-type ClusterIP --registry $dockerHubAccountName
cd ..
WriteLog "Deploying an Ingress resource pointing to the function" 
sed 's/<FunctionName>/'$functionName'/g' ./TestFunctionApp/testfunctionapp.yaml > local_func.yaml
sed -i 's/<AKSDnsName>/'$PublicDNSName'/g' local_func.yaml
kubectl apply -f local_func.yaml

WriteLog "Deploying an Ingress resource pointing to prometheus server" 
kubectl apply -f ./TestFunctionApp/ingress-prometheus.yaml

WriteLog "Deploying an Ingress resource pointing to the function" 
sed 's/<FunctionName>/'$functionName'/g' ./TestFunctionApp/keda-prometheus.yaml > local_keda.yaml
kubectl apply -f local_keda.yaml

WriteLog "curl -d \"{\\\"name\\\":\\\"0123456789\\\"}\" -H \""Content-Type: application/json\""  -X POST   http://"$PublicDNSName"/"$functionName"/api/values"
WriteLog "curl -H \"Content-Type: application/json\"  -X GET   http://"$PublicDNSName"/"$functionName"/api/test"

WriteLog "Installation completed !" 


fi
exit 0 


