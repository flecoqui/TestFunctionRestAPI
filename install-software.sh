#!/bin/bash
# This bash file install apache
# Parameter 1 hostname 
azure_hostname=$1
#############################################################################
log()
{
	# If you want to enable this logging, uncomment the line below and specify your logging key 
	#curl -X POST -H "content-type:text/plain" --data-binary "$(date) | ${HOSTNAME} | $1" https://logs-01.loggly.com/inputs/${LOGGING_KEY}/tag/redis-extension,${HOSTNAME}
	echo "$1"
	echo "$1" >> /testrest/log/install.log
}
#############################################################################
check_os() {
    grep#" ubuntu /proc/version > /dev/null 2>&1
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

	log "OS=$OS version $VER Architecture $ARCH"
}

#############################################################################
install_git_ubuntu(){
apt-get -y install git
}
install_git_centos(){
yum -y install git
}
#############################################################################
install_curl_ubuntu(){
apt-get -y install curl
}
install_curl_centos(){
yum -y install curl
}
#############################################################################
install_azurecli_ubuntu(){
apt-get -y update
apt-get -y install ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get -y update
sudo apt-get -y install azure-cli
}
install_azurecli_centos(){
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install azure-cli
}
#############################################################################
install_kubectl(){
az aks install-cli
}
#############################################################################
install_helm(){
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
}
#############################################################################
install_azurefunctool_ubuntu(){
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
apt-get -y update
apt-get -y install azure-functions-core-tools
}
install_azurefunctool_debian(){
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/debian/$(lsb_release -rs | cut -d'.' -f 1)/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
apt-get -y update
apt-get -y install azure-functions-core-tools
}
install_azurefunctool_centos(){
yum -y install unzip
mkdir /git/azure-functions-cli
curl -fsSL -o Azure.Functions.Cli.linux-x64.3.0.2358.zip https://github.com/Azure/azure-functions-core-tools/releases/download/3.0.2358/Azure.Functions.Cli.linux-x64.3.0.2358.zip 
unzip -d /git/azure-functions-cli Azure.Functions.Cli.linux-x64.*.zip
chmod +x /git/azure-functions-cli/func
chmod +x /git/azure-functions-cli/gozip
}
#############################################################################
install_azurefunctool_ubuntu(){
apt-get -y update
apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y update
apt-get -y install docker-ce docker-ce-cli containerd.io
docker run hello-world
}
install_azurefunctool_debian(){
apt-get -y update
apt-get -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get -y update
apt-get -y install docker-ce docker-ce-cli containerd.io
docker run hello-world

}
install_azurefunctool_centos(){
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
docker run hello-world
}
#############################################################################

environ=`env`
# Create folders
mkdir /git
mkdir /git/log

# Write access in log subfolder
chmod -R a+rw /git/log
log "Environment before installation: $environ"

log "Installation script start : $(date)"
check_os
if [ $iscentos -ne 0 ] && [ $isredhat -ne 0 ] && [ $isubuntu -ne 0 ] && [ $isdebian -ne 0 ];
then
    log "unsupported operating system"
    exit 1 
else
	if [ $iscentos -eq 0 ] ; then
	    log "install git centos"
		install_git_centos
	    log "install curl centos"
		install_curl_centos
	    log "install azurecli centos"
		install_azurecli_centos	
	    log "install kubectl centos"
		install_kubectl
		log "install helm centos"
		install_helm
		log "install azurefunctool centos"
		install_azurefunctool_centos
		log "install docker centos"
		install_docker_centos
	elif [ $isredhat -eq 0 ] ; then
	    log "install git redhat"
		install_git_centos
	    log "install curl redhat"
		install_curl_centos
	    log "install azurecli redhat"
		install_azurecli_centos	
	    log "install kubectl redhat"
		install_kubectl
		log "install helm redhat"
		install_helm
		log "install azurefunctool redhat"
		install_azurefunctool_centos
		log "install docker redhat"
		install_docker_centos
	elif [ $isubuntu -eq 0 ] ; then
	    log "install git ubuntu"
		install_git_ubuntu
	    log "install curl ubuntu"
		install_curl_ubuntu
	    log "install azurecli ubuntu"
		install_azurecli_ubuntu	
	    log "install kubectl ubuntu"
		install_kubectl
		log "install helm ubuntu"
		install_helm
		log "install azurefunctool ubuntu"
		install_azurefunctool_ubuntu
		log "install docker ubuntu"
		install_docker_ubuntu
	elif [ $isdebian -eq 0 ] ; then
	    log "install git debian"
		install_git_ubuntu
	    log "install curl debian"
		install_curl_ubuntu
	    log "install azurecli debian"
		install_azurecli_ubuntu	
	    log "install kubectl debian"
		install_kubectl
		log "install helm debian"
		install_helm
		log "install azurefunctool debian"
		install_azurefunctool_debian
		log "install docker debian"
		install_docker_debian
	fi
fi
exit 0 

