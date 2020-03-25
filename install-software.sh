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
configure_network(){
# firewall configuration 
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
}

#############################################################################
install_netcore(){
wget -q packages-microsoft-prod.deb https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get -y install apt-transport-https
apt-get -y update
apt-get -y install dotnet-sdk-2.2
}
install_netcore_centos(){
rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
yum -y clean all
yum -y makecache
yum -y update --exclude=WALinuxAgent
yum -y install dotnet-sdk-2.2

}
install_netcore_redhat(){
yum install rh-dotnet22 -y
scl enable rh-dotnet22 bash
}
install_netcore_debian(){
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
wget -q https://packages.microsoft.com/config/debian/9/prod.list
mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
chown root:root /etc/apt/sources.list.d/microsoft-prod.list
apt-get -y install apt-transport-https --force-yes
apt-get update
apt-get -y install dotnet-sdk-2.2
}
#############################################################################
install_git_ubuntu(){
apt-get -y install git
}
install_git_centos(){
yum -y install git
}
#############################################################################

build_testrest(){
# Download source code
cd /git
git clone https://github.com/flecoqui/TestRESTAPIServices.git
log "dotnet publish --self-contained -c Release -r linux-x64 --output bin"
export HOME=/root
env  > /testrest/log/env.log
# the generation of ASTOOL build could fail (dotnet bug)
/usr/bin/dotnet publish /git/TestRESTAPIServices/TestWebApp --self-contained -c Release -r linux-x64 --output /git/TestRESTAPIServices/TestWebApp/bin > /testrest/log/dotnet.log 2> /testrest/log/dotneterror.log
log "dotnet publish done"

}
build_testrest_rhel(){
# Download source code
cd /git
git clone https://github.com/flecoqui/TestRESTAPIServices.git
log "dotnet publish --self-contained -c Release -r rhel-x64 --output bin"
export HOME=/root
env  > /testrest/log/env.log
# the generation of ASTOOL build could fail (dotnet bug)
/opt/rh/rh-dotnet22/root/usr/bin/dotnet publish /git/TestRESTAPIServices/TestWebApp --self-contained -c Release -r rhel-x64 --output /git/TestRESTAPIServices/TestWebApp/bin > /testrest/log/dotnet.log 2> /testrest/log/dotneterror.log
log "dotnet publish done"

}
#############################################################################
build_testrest_post(){
log "installing the service which will build testrest after VM reboot"
cat <<EOF > /etc/systemd/system/buildtestrest.service
[Unit]
Description=build testrest 

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/dotnet publish /git/TestRESTAPIServices/TestWebApp  --self-contained -c Release -r ubuntu.16.10-x64 --output /git/TestRESTAPIServices/TestWebApp/bin 

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable buildtestrest.service
log "Rebooting"
reboot
}

#############################################################################
install_testrest(){
cd /git/TestRESTAPIServices/TestWebApp/bin
export PATH=$PATH:/git/TestRESTAPIServices/TestWebApp/bin
echo "export PATH=$PATH:/git/TestRESTAPIServices/TestWebApp/bin" >> /etc/profile
apt-get -y install authbind
touch /etc/authbind/byport/80
touch /etc/authbind/byport/443
chmod 777 /etc/authbind/byport/80
chmod 777 /etc/authbind/byport/443

chmod +x  /git/TestRESTAPIServices/TestWebApp/bin/TestWebApp

adduser testrestuser --disabled-login
cat <<EOF > /etc/systemd/system/testrest.service
[Unit]
Description=testrest Service
After=network.target

[Service]
WorkingDirectory=/git/TestRESTAPIServices/TestWebApp/bin
User=testrestuser
ExecStart=/usr/bin/authbind /git/TestRESTAPIServices/TestWebApp/bin/TestWebApp --url http://*:80/
Restart=always
RestartSec=10
SyslogIdentifier=TestWebApp
KillSignal=SIGINT
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOF
}
#############################################################################
install_testrest_centos(){
cd /git/TestRESTAPIServices/TestWebApp/bin
export PATH=$PATH:/git/TestRESTAPIServices/TestWebApp/bin
echo "export PATH=$PATH:/git/TestRESTAPIServices/TestWebApp/bin" >> /etc/profile

rpm -Uvh https://s3.amazonaws.com/aaronsilber/public/authbind-2.1.1-0.1.x86_64.rpm
touch /etc/authbind/byport/80
touch /etc/authbind/byport/443
chmod 777 /etc/authbind/byport/80
chmod 777 /etc/authbind/byport/443


chmod +x  /git/TestRESTAPIServices/TestWebApp/bin/TestWebApp
adduser testrestuser -s /sbin/nologin
cat <<EOF > /etc/systemd/system/testrest.service
[Unit]
Description=testrest Service

[Service]
WorkingDirectory=/git/TestRESTAPIServices/TestWebApp/bin
User=testrestuser
ExecStart=/usr/bin/authbind /git/TestRESTAPIServices/TestWebApp/bin/TestWebApp --url http://*:80/
Restart=always
RestartSec=10
SyslogIdentifier=TestWebApp
KillSignal=SIGINT
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOF
}


#############################################################################
configure_network_centos(){
# firewall configuration 
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT


service firewalld start
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
}



#############################################################################

environ=`env`
# Create folders
mkdir /git
mkdir /testrest
mkdir /testrest/log
mkdir /testrest/config

# Write access in log subfolder
chmod -R a+rw /testrest/log
log "Environment before installation: $environ"

log "Installation script start : $(date)"
log "Net Core Installation: $(date)"
log "#####  azure_hostname: $azure_hostname"
log "Installation script start : $(date)"
check_os
if [ $iscentos -ne 0 ] && [ $isredhat -ne 0 ] && [ $isubuntu -ne 0 ] && [ $isdebian -ne 0 ];
then
    log "unsupported operating system"
    exit 1 
else
	if [ $iscentos -eq 0 ] ; then
	    log "configure network centos"
		configure_network_centos
	    log "install netcore centos"		
		install_netcore_centos
	    log "install git centos"
		install_git_centos
	elif [ $isredhat -eq 0 ] ; then
	    log "configure network redhat"
		configure_network_centos
	    log "install netcore redhat"
		install_netcore_redhat
	    log "install git redhat"
		install_git_centos
	elif [ $isubuntu -eq 0 ] ; then
	    log "configure network ubuntu"
		configure_network
		log "install netcore ubuntu"
		install_netcore
	    log "install git ubuntu"
		install_git_ubuntu
	elif [ $isdebian -eq 0 ] ; then
	    log "configure network"
		configure_network
		log "install netcore debian"
		install_netcore_debian
	    log "install git debian"
		install_git_ubuntu
	fi
	log "build TestWebApp"
	if [ $isredhat -eq 0 ] ; then
	    log "build testrest redhat"
		build_testrest_rhel
	else
	    log "build testrest "
		build_testrest
	fi

	if [ $iscentos -eq 0 ] ; then
	    log "install testrest centos"
		install_testrest_centos
	elif [ $isredhat -eq 0 ] ; then
	    log "install testrest redhat"
		install_testrest_centos
	elif [ $isubuntu -eq 0 ] ; then
	    log "install testrest ubuntu"
		install_testrest
	elif [ $isdebian -eq 0 ] ; then
	    log "install testrest debian"
		install_testrest
	fi
	log "Start TestWebApp service"
	systemctl enable testrest.service
	systemctl start testrest.service 
	if [ -f /git/TestRESTAPIServices/TestWebApp/bin/TestWebApp ] ; then
		log "Installation successful, TestWebApp correctly generated"
	else	
		log "Installation not successful, reboot required to build TestWebApp"
		# build_testrest_post
	fi
fi
exit 0 

