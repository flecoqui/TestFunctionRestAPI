#usage install-software-windows.ps1 
# This Power Shell file install the pre-requisites:
# - git
# - azure Cli
# - kubectl
# - helm
# - azure function tools
# - docker
#		
#
mkdir c:\git
mkdir c:\git\log
mkdir c:\git\download
mkdir c:\git\helm
$sourcedir = 'c:\git\download' 
$helmdir = 'c:\git\helm' 
$logdir = 'c:\git\log' 

function WriteLog($msg)
{
Write-Host $msg
$msg >> $logdir"\install-software-windows.log"
}
function WriteDateLog
{
date >> $logdir"\install-software-windows.log"
}
function DownloadAndUnzip($sourceUrl,$DestinationDir ) 
{
    $TempPath = [System.IO.Path]::GetTempFileName()
    if (($sourceUrl -as [System.URI]).AbsoluteURI -ne $null)
    {
        $handler = New-Object System.Net.Http.HttpClientHandler
        $client = New-Object System.Net.Http.HttpClient($handler)
        $client.Timeout = New-Object System.TimeSpan(0, 30, 0)
        $cancelTokenSource = [System.Threading.CancellationTokenSource]::new()
        $responseMsg = $client.GetAsync([System.Uri]::new($sourceUrl), $cancelTokenSource.Token)
        $responseMsg.Wait()
        if (!$responseMsg.IsCanceled)
        {
            $response = $responseMsg.Result
            if ($response.IsSuccessStatusCode)
            {
                $downloadedFileStream = [System.IO.FileStream]::new($TempPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
                $copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)
                $copyStreamOp.Wait()
                $downloadedFileStream.Close()
                if ($copyStreamOp.Exception -ne $null)
                {
                    throw $copyStreamOp.Exception
                }
            }
        }
    }
    else
    {
        throw "Cannot copy from $sourceUrl"
    }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($TempPath, $DestinationDir)
    Remove-Item $TempPath
}
function Download($sourceUrl,$DestinationDir ) 
{
    $TempPath = [System.IO.Path]::GetTempFileName()
    if (($sourceUrl -as [System.URI]).AbsoluteURI -ne $null)
    {
        $handler = New-Object System.Net.Http.HttpClientHandler
        $client = New-Object System.Net.Http.HttpClient($handler)
        $client.Timeout = New-Object System.TimeSpan(0, 30, 0)
        $cancelTokenSource = [System.Threading.CancellationTokenSource]::new()
        $responseMsg = $client.GetAsync([System.Uri]::new($sourceUrl), $cancelTokenSource.Token)
        $responseMsg.Wait()
        if (!$responseMsg.IsCanceled)
        {
            $response = $responseMsg.Result
            if ($response.IsSuccessStatusCode)
            {
                $downloadedFileStream = [System.IO.FileStream]::new($TempPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
                $copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)
                $copyStreamOp.Wait()
                $downloadedFileStream.Close()
                if ($copyStreamOp.Exception -ne $null)
                {
                    throw $copyStreamOp.Exception
                }
            }
        }
    }
    else
    {
        throw "Cannot copy from $sourceUrl"
    }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($TempPath, $DestinationDir)
    Remove-Item $TempPath
}
function Expand-ZIPFile($file, $destination) 
{ 
    $shell = new-object -com shell.application 
    $zip = $shell.NameSpace($file) 
    foreach($item in $zip.items()) 
    { 
        # Unzip the file with 0x14 (overwrite silently) 
        $shell.Namespace($destination).copyhere($item, 0x14) 
    } 
} 


WriteDateLog
WriteLog "Downloading NodeJS" 
$url = 'https://nodejs.org/dist/v12.16.1/node-v12.16.1-x64.msi' 
$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId
if (($EditionId -eq "ServerStandardNano") -or
    ($EditionId -eq "ServerDataCenterNano") -or
    ($EditionId -eq "NanoServer") -or
    ($EditionId -eq "ServerTuva")) {
	Download $url $sourcedir 
	WriteLog "node-v12.16.1-x64.msi copied" 
}
else
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	$webClient = New-Object System.Net.WebClient  
	$webClient.DownloadFile($url,$sourcedir + "\node-v12.16.1-x64.msi" )  
	WriteLog "node-v12.16.1-x64.msi copied" 
}
WriteLog "Installing NodeJS" 
msiexec.exe /i $sourcedir"\node-v12.16.1-x64.msi" /qn /l* $logdir"\node-install.log"
$Env:path += ";c:\Program Files\nodejs"


WriteDateLog
WriteLog "Downloading Git" 
$url = 'https://github.com/git-for-windows/git/releases/download/v2.26.0.windows.1/Git-2.26.0-32-bit.exe' 
$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId
if (($EditionId -eq "ServerStandardNano") -or
    ($EditionId -eq "ServerDataCenterNano") -or
    ($EditionId -eq "NanoServer") -or
    ($EditionId -eq "ServerTuva")) {
	Download $url $sourcedir 
	WriteLog "Git-2.26.0-32-bit.exe copied" 
}
else
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	$webClient = New-Object System.Net.WebClient  
	$webClient.DownloadFile($url,$sourcedir + "\Git-2.26.0-32-bit.exe" )  
	WriteLog "Git-2.26.0-32-bit.exe copied" 
}
WriteLog "Installing Git" 
Start-Process -FilePath $sourcedir"\Git-2.26.0-32-bit.exe" -Wait -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART","/NOCANCEL","/SP-","/LOG"

$count=0
while ((!(Test-Path "C:\Program Files\Git\bin\git.exe"))-and($count -lt 20)) { Start-Sleep 10; $count++}

WriteLog "git Installed" 

WriteDateLog
WriteLog ("Installing Azure CLI")
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
$Env:path += ";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
WriteDateLog
WriteLog ("Installing kubectl")
#az aks install-cli
#Start-Process -FilePath "az" -Wait -ArgumentList "aks","install-cli"
$output = az aks install-cli | ConvertFrom-Json
if (!$output) {
    writeLog "Error or Warning while installing kubectl"
}
$Env:path += ";"+$Env:USERPROFILE+"\.azure-kubectl"

WriteDateLog
WriteLog "Downloading Helm" 
$url = 'https://get.helm.sh/helm-v3.1.2-windows-amd64.zip' 
$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId
if (($EditionId -eq "ServerStandardNano") -or
    ($EditionId -eq "ServerDataCenterNano") -or
    ($EditionId -eq "NanoServer") -or
    ($EditionId -eq "ServerTuva")) {
	Download $url $sourcedir 
	WriteLog "helm-v3.1.2-windows-amd64.zip copied" 
}
else
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	$webClient = New-Object System.Net.WebClient  
	$webClient.DownloadFile($url,$sourcedir + "\helm-v3.1.2-windows-amd64.zip" )  
	WriteLog "helm-v3.1.2-windows-amd64.zip copied" 
}
WriteLog ("Installing Helm")
Expand-ZIPFile $sourcedir"\helm-v3.1.2-windows-amd64.zip" $helmdir
$Env:path += ";"+$helmdir+"\windows-amd64"
$Env:path += ";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
WriteDateLog
WriteLog ("Installing Azure Function Tools")
#npm i -g azure-functions-core-tools@3 --unsafe-perm true
#Start-Process -FilePath "npm" -Wait -ArgumentList "i","-g","azure-functions-core-tools@3","--unsafe-perm","true"
$output = npm i -g azure-functions-core-tools@3 --unsafe-perm true | ConvertFrom-Json


WriteDateLog
WriteLog "Downloading Docker" 
$url = 'https://download.docker.com/win/enterprise/DockerDesktop.msi' 
$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId
if (($EditionId -eq "ServerStandardNano") -or
    ($EditionId -eq "ServerDataCenterNano") -or
    ($EditionId -eq "NanoServer") -or
    ($EditionId -eq "ServerTuva")) {
	Download $url $sourcedir 
	WriteLog "DockerDesktop.msi copied" 
}
else
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	$webClient = New-Object System.Net.WebClient  
	$webClient.DownloadFile($url,$sourcedir + "\DockerDesktop.msi" )  
	WriteLog "DockerDesktop.msi copied" 
}
WriteLog "Installing Docker" 
#Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
#Enable-WindowsOptionalFeature -Online -FeatureName Containers -All
msiexec.exe /i $sourcedir"\DockerDesktop.msi" /qn /l* $logdir"\docker-install.log"
WriteLog "Docker Installed" 