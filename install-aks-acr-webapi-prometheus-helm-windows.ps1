
#usage install-aks-acr-windows.ps1 dnsname

param
(
      [string]$resourceGroupName = $null,
      [string]$prefixName = $null,
      [string]$aksVMSize = $null,
      [string]$aksNodeCount = $null
)
function WriteLog($msg)
{
Write-Host $msg
$msg >> install-aks-acr-webapi-windows.log
}

if($prefixName -eq $null) {
     WriteLog "Installation failed prefixName parameter not set "
     throw "Installation failed prefixName parameter not set "
}
if($resourceGroupName -eq $null) {
     WriteLog "Installation failed resourceGroupName parameter not set "
     throw "Installation failed resourceGroupName parameter not set "
}

if($aksVMSize -eq $null) {
     $aksVMSize=Standard_D2_v2
}
if($aksNodeCount -eq $null) {
     $aksNodeCount=1
}
# WARNING As the image name of the function must be different between DockerHub image and Azure Container Registry image
# The function name are different for DockerHub  function name and Container Registry function name
$functionAName = $prefixName + 'acrwebapia' 
$functionBName = $prefixName + 'acrwebapib' 
$containerName = $prefixName + 'acrwebapi' 
$acrName = $prefixName + 'acr'
$acrDNSName = $acrName + '.azurecr.io'
$acrDeploymentName = $prefixName + 'acrdep'
$acrSPName = $prefixName + 'acrsp'
$akvName = $prefixName + 'akv'
$aksName = $prefixName + 'aks'
$aksClusterName = $prefixName + 'akscluster'
$acrSPPassword = ''
$acrSPAppId = ''
$acrSPObjectId = ''
$akvDeploymentName = $prefixName + 'akvdep'
$aciDeploymentName = $prefixName + 'acidep'
$aksDeploymentName = $prefixName + 'aksdep'
$imageName = 'function-' + $containerName
$imageNameId = $imageName + ':{{.Run.ID}}'
$imageTag = 'latest'
$latestImageName = $imageName+ ':' + $imageTag
$imageTask =  $imageName + 'task'
$githubrepo = 'https://github.com/flecoqui/TestFunctionRestAPI.git'
$githubbranch = 'master'
$dockerfilepath = 'TestFunctionPrometheusAppv3.1\Dockerfile'

function WriteLog($msg)
{
    Write-Host $msg
    $msg >> install-aks-windows.log
}
function Get-Password($file)
{
    foreach($line in (Get-Content $file  ))
    {
	    $nline = $line.Split(':", ',[System.StringSplitOptions]::RemoveEmptyEntries)
	    if($nline.Length -gt 1) 
	    {
  	    if($nline[0] -eq "password")
  	        {
		        return $nline[1]
      		        break
  	        }
  	    }
    }
    return $null
}
function Get-PublicIP($file)
{
    foreach($line in (Get-Content $file  ))
    {
	    $nline = $line.Split(' ',[System.StringSplitOptions]::RemoveEmptyEntries)
	    if($nline.Length -gt 3) 
	    {
  	    if($nline[1] -eq "LoadBalancer")
  	        {
		        return $nline[3]
      		        break
  	        }
  	    }
    }
    return $null
}
WriteLog ("Installation script is starting for resource group: " + $resourceGroupName + " with prefixName: " + $prefixName + " AKS VM size: " + $aksVMSize + " AKS Node count: " + $aksNodeCount )
WriteLog "Creating Azure Container Registry" 
az deployment group create -g $resourceGroupName -n $acrDeploymentName --template-file azuredeploy.acr.json --parameter namePrefix=$prefixName --verbose -o json 
az group deployment show -g $resourceGroupName -n $acrDeploymentName --query properties.outputs

WriteLog "Building and registrying the image in Azure Container Registry"
# Command line below is used to build image directly from github
WriteLog "Creating task to build and register the image in Azure Container Registry"
az acr task create --image $imageNameId --image $latestImageName --name $imageTask --registry $acrName  --context $githubrepo --branch $githubbranch --file $dockerfilepath --commit-trigger-enabled false --pull-request-trigger-enabled false
WriteLog "Launching the task "
az acr task run  -n $imageTask -r $acrName

WriteLog "Getting ACR ID" 
az acr show --name $acrName --query id --output tsv > acrid.txt
$acrID = Get-Content .\acrid.txt -Raw 
WriteLog "Removing previous Service Principal " 
az ad sp delete --id http://$acrSPName 
WriteLog "Creating Service Principal with role acrpull" 
az ad sp create-for-rbac --name http://$acrSPName --scopes $acrID --role acrpull --query password --output tsv > .\sppassword.txt
$acrSPPassword  = Get-Password .\sppassword.txt 
if($acrSPPassword -eq $null) {
     WriteLog "ACR SP Password not found "
     throw "ACR SP Password not found "
}
#WriteLog ("SPPassword: " + $acrSPPassword)


az ad sp show --id http://$acrSPName --query appId --output tsv > spappid.txt
$acrSPAppId  = Get-Content  .\spappid.txt -Raw  
$acrSPAppId = $acrSPAppId.replace("`n","").replace("`r","")

#WriteLog ("SPAppId: " + $acrSPAppId)

az ad signed-in-user show --query objectId --output tsv > spobjectid.txt
$acrSPObjectId  = Get-Content  .\spobjectid.txt -Raw  
$acrSPObjectId = $acrSPObjectId.replace("`n","").replace("`r","")
#WriteLog ("SPObjectId: " + $acrSPObjectId)


WriteLog "Adding role Reader for Service Principal" 
az role assignment create --role Reader --assignee $acrSPAppId --scope $acrID 


WriteLog "Creating Azure Key Vault" 
az deployment group create -g $resourceGroupName -n $akvDeploymentName --template-file azuredeploy.akv.json --parameter namePrefix=$prefixName objectId=$acrSPObjectId  appId=$acrSPAppId  password=$acrSPPassword --verbose -o json
az deployment group show -g $resourceGroupName -n $akvDeploymentName --query properties.outputs

$pullusr = $acrName + '-pull-usr'
$pullpwd = $acrName + '-pull-pwd'

az keyvault secret show --vault-name $akvName --name $pullusr --query value -o tsv > akvappid.txt
az keyvault secret show --vault-name $akvName --name $pullpwd --query value -o tsv > akvpassword.txt

WriteLog ("Azure Container Registry Getting password for : " +  $acrName)
$acrPassword  = Get-Content  .\akvpassword.txt -Raw  
$acrPassword = $acrPassword.replace("`n","").replace("`r","")


WriteLog "Deploying a kubernetes cluster" 
az aks create --resource-group $resourceGroupName --name $aksClusterName --dns-name-prefix $aksName --node-vm-size $aksVMSize   --node-count $aksNodeCount --service-principal $acrSPAppId   --client-secret $acrSPPassword --generate-ssh-keys
az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName --overwrite-existing 

#WriteLog "Deploying a Tiller" 
#kubectl --namespace kube-system create serviceaccount tiller
#kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

#WriteLog "Preparing Helm repository" 
#helm repo add stable https://kubernetes-charts.storage.googleapis.com/
#helm repo add kedacore https://kedacore.github.io/charts

WriteLog "Creating the name space" 
kubectl create namespace ingress-nginx

WriteLog "Deploying nginx Ingress controller with Helm" 
#helm install ingress-controller stable/nginx-ingress --namespace ingress-nginx --set controller.replicaCount=2 --set controller.metrics.enabled=true --set controller.podAnnotations."prometheus\.io/scrape"="true" --set controller.podAnnotations."prometheus\.io/port"="10254"
helm install ingress-controller ./charts/nginx-ingress -n ingress-nginx --set controller.replicaCount=2 --set controller.metrics.enabled=true --set controller.podAnnotations."prometheus\.io/scrape"="true" --set controller.podAnnotations."prometheus\.io/port"="10254"



WriteLog "Waiting for Public IP address during 10 minutes max" 
$count = 0
Do
{
$count = $count+1
WriteLog "Waiting for Public IP address" 
Start-Sleep -s 15
kubectl get services -n ingress-nginx > services.txt 
# Public IP address of your ingress controller
$IP  = Get-PublicIP .\services.txt 
}While ((($IP -eq '<pending>') -or ($IP -eq $null)) -and ($count -lt 40))

if (($IP -eq '<pending>') -or ($IP -eq $null)){
	 WriteLog "Can't get the public IP address for container, stopping the installation"
     throw "Can't get the public IP address for container, stopping the installation"
}
WriteLog ("Public IP address: " + $IP) 

# Name to associate with public IP address
$dnsName=$aksName

# Get the resource-id of the public ip
$PublicIPId=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" --output tsv)
WriteLog ("Public IP address ID: " + $PublicIPId) 

# Update public ip address with DNS name
az network public-ip update --ids $PublicIPId --dns-name $dnsName
# get the full dns name
$PublicDNSName=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[dnsSettings.fqdn]" --output tsv)
WriteLog ("Public DNS Name: " +$PublicDNSName) 

WriteLog "Deploying Prometheus to monitor nginx Ingress controller" 
#kubectl apply --kustomize github.com/kubernetes/ingress-nginx/deploy/prometheus/ 
helm install prometheus-server ./charts/prometheus -n ingress-nginx

kubectl -n ingress-nginx get svc
kubectl -n ingress-nginx get pods

WriteLog "Deploying Keda with Helm" 
#helm install keda kedacore/keda --namespace ingress-nginx
helm install keda ./charts/keda -n ingress-nginx 
kubectl get pods -n ingress-nginx




WriteLog "Deploying WebAPI Net Core 3.1 container hosting the function A" 
helm install $functionAName ./charts/webapiapp -n ingress-nginx --set ingress.hosts[0]."host"="$PublicDNSName" --set deployment.image.repository=$acrDNSName --set deployment.image.imageName=$imageName  --set deployment.image.tag=$imageTag  --set deployment.imagePullSecrets[0]."name"="$acrPassword"   --set deployment.deploymentAnnotations."prometheus\.io/scrape"="true" --set deployment.deploymentAnnotations."prometheus\.io/port"="80" --set deployment.deploymentAnnotations."prometheus\.io/path"="/metrics"

WriteLog "Deploying WebAPI Net Core 3.1 container hosting the function B" 
helm install $functionBName ./charts/webapiapp -n ingress-nginx --set ingress.hosts[0]."host"="$PublicDNSName" --set deployment.image.repository=$acrDNSName --set deployment.image.imageName=$imageName  --set deployment.image.tag=$imageTag  --set deployment.imagePullSecrets[0]."name"="$acrPassword"   --set deployment.deploymentAnnotations."prometheus\.io/scrape"="true" --set deployment.deploymentAnnotations."prometheus\.io/port"="80" --set deployment.deploymentAnnotations."prometheus\.io/path"="/metrics"


#WriteLog "Deploying an Ingress resource pointing to prometheus server" 
#kubectl apply -f .\TestFunctionPrometheusAppv3.1\ingress-prometheus.yaml

writelog ("curl -d ""{\""name\"":\""0123456789\""}"" -H ""Content-Type: application/json""  -X POST   http://" + $PublicDNSName + "/" + $functionAName + "/api/values")
writelog ("curl -H ""Content-Type: application/json""  -X GET   http://" + $PublicDNSName + "/" + $functionAName + "/api/test")

writelog ("curl -d ""{\""name\"":\""0123456789\""}"" -H ""Content-Type: application/json""  -X POST   http://" + $PublicDNSName + "/" + $functionBName + "/api/values")
writelog ("curl -H ""Content-Type: application/json""  -X GET   http://" + $PublicDNSName + "/" + $functionBName + "/api/test")

WriteLog "Installation completed !" 

