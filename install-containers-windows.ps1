
#usage install-software-windows.ps1 dnsname

param
(
      [string]$resourceGroupName = $null,
      [string]$prefixName = $null,
      [string]$cpuCores = $null,
      [string]$memoryInGb = $null,
      [string]$aksVMSize = $null,
      [string]$aksNodeCount = $null
)
function WriteLog($msg)
{
Write-Host $msg
$msg >> install-aks-windows.log
}

if($prefixName -eq $null) {
     WriteLog "Installation failed prefixName parameter not set "
     throw "Installation failed prefixName parameter not set "

}
if($resourceGroupName -eq $null) {
     WriteLog "Installation failed resourceGroupName parameter not set "
     throw "Installation failed resourceGroupName parameter not set "
}
if($cpuCores -eq $null) {
     $cpuCores=0.4
}
if($memoryInGb -eq $null) {
     $memoryInGb=0.3
}
if($aksVMSize -eq $null) {
     $aksVMSize=Standard_D2s_v3
}
if($aksNodeCount -eq $null) {
     $aksNodeCount=1
}

$acrName = $prefixName + 'acr'
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
$imageName = 'testwebapp.linux'
$imageNameId = $imageName + ':{{.Run.ID}}'
$imageTag = 'latest'
$latestImageName = $imageName+ ':' + $imageTag
$imageTask = 'testwebapplinuxtask'
$githubrepo = 'https://github.com/flecoqui/TestRESTAPIServices.git'
$githubbranch = 'master'
$dockerfilepath = 'Docker\Dockerfile.linux'

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
WriteLog ("Installation script is starting for resource group: " + $resourceGroupName + " with prefixName: " + $prefixName + " cpuCores: " + $cpuCores + " memoryInGb: " + $memoryInGb + " AKS VM size: " + $aksVMSize + " AKS Node count: " + $aksNodeCount)
WriteLog "Creating Azure Container Registry" 
az group deployment create -g $resourceGroupName -n $acrDeploymentName --template-file azuredeploy.acr.json --parameter namePrefix=$prefixName --verbose -o json 
az group deployment show -g $resourceGroupName -n $acrDeploymentName --query properties.outputs

WriteLog "Building and registrying the image in Azure Container Registry"
# Command line below is used to build image from the local disk 
# echo az acr build --registry $acrName   --image $imageName ..\..\. -f ..\..\Docker\Dockerfile.linux >> install-aks-windows.log
# 
#
# az acr build --registry $acrName   --image $imageName ..\..\. -f ..\..\Docker\Dockerfile.linux

# Command line below is used to build image directly from github
WriteLog "Creating task to build and register the image in Azure Container Registry"
az acr task create --image $imageNameId --image $latestImageName --name $imageTask --registry $acrName  --context $githubrepo --branch $githubbranch --file $dockerfilepath --commit-trigger-enabled false --pull-request-trigger-enabled false
WriteLog "Launching the task "
az acr task run  -n $imageTask -r $acrName


WriteLog "Creating Service Principal with role acrpull" 
az acr show --name $acrName --query id --output tsv > acrid.txt
$acrID = Get-Content .\acrid.txt -Raw 
az ad sp create-for-rbac --name http://$acrSPName --scopes $acrID --role acrpull --query password --output tsv > sppassword.txt
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
az group deployment create -g $resourceGroupName -n $akvDeploymentName --template-file azuredeploy.akv.json --parameter namePrefix=$prefixName objectId=$acrSPObjectId  appId=$acrSPAppId  password=$acrSPPassword --verbose -o json
az group deployment show -g $resourceGroupName -n $akvDeploymentName --query properties.outputs

$pullusr = $acrName + '-pull-usr'
$pullpwd = $acrName + '-pull-pwd'

az keyvault secret show --vault-name $akvName --name $pullusr --query value -o tsv > akvappid.txt
az keyvault secret show --vault-name $akvName --name $pullpwd --query value -o tsv > akvpassword.txt

WriteLog "Deploying a container on Azure Container Instance" 
#$cmdtest = "az group deployment create -g " + $resourceGroupName +" -n " + $aciDeploymentName + "--template-file azuredeploy.aci.json --parameter namePrefix=" + $prefixName + " imageName=" + $imageName +" appId=" + $acrSPAppId + " password=" + $acrSPPassword +"  cpuCores='0.4' memoryInGb='0.3' --verbose -o json"
#WriteLog $cmdtest


az group deployment create -g $resourceGroupName -n $aciDeploymentName --template-file azuredeploy.aci.json --parameter namePrefix=$prefixName imageName=$latestImageName  appId=$acrSPAppId  password=$acrSPPassword cpuCores=$cpuCores memoryInGb=$memoryInGb --verbose -o json
az group deployment show -g $resourceGroupName -n $aciDeploymentName --query properties.outputs


WriteLog "Deploying a kubernetes cluster" 
az aks create --resource-group $resourceGroupName --name $aksClusterName --dns-name-prefix $aksName --node-vm-size $aksVMSize   --node-count $aksNodeCount --service-principal $acrSPAppId   --client-secret $acrSPPassword --generate-ssh-keys

az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName --overwrite-existing 

WriteLog "Deploying a container in the kubernetes cluster" 
get-content Docker\testwebapp.linux.aks.yaml | %{$_ -replace "<ACRName>",$acrName} | %{$_ -replace "<cpuCores>",$cpuCores}  | %{$_ -replace "<memoryInGb>",$memoryInGb} > local.yaml
kubectl apply -f local.yaml
WriteLog "Waiting for Public IP address during 10 minutes max" 
$count = 0
Do
{
$count = $count+1
WriteLog "Waiting for Public IP address" 
Start-Sleep -s 15
kubectl get services > services.txt 
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

writelog ("curl -d '{""name"":""0123456789""}' -H ""Content-Type: application/json""  -X POST   http://" + $PublicDNSName + "/api/values")

writelog ("curl -H ""Content-Type: application/json""  -X GET   http://" + $PublicDNSName + "/api/test")

WriteLog "Installation completed !" 

