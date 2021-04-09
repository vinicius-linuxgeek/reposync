#!/bin/bash
# Created by VBOAS

## Funcs
register(){

# Infos
user='<your user>'
pass='<your pass>'
pool='<your pool>'

# Subscription management
subscription-manager clean
subscription-manager unregister
subscription-manager register --username="${user}" --password="${pass}"
subscription-manager attach --pool="${pool}"
}

list(){
repolist="/tmp/repolist"

# Create repolist file
# Include the repos in the list
if [ -f ${repolist} ] ; then
        rm -f ${repolist}
        echo 'rhel-7-server-rpms' > ${repolist} 
        echo 'rhel-7-server-extras-rpms' >> ${repolist}
        echo 'rhel-7-server-ansible-2.9-rpms' >> ${repolist}
        echo 'rhel-7-server-ose-3.11-rpms' >> ${repolist}
else
        echo 'rhel-7-server-rpms' > ${repolist} 
        echo 'rhel-7-server-extras-rpms' >> ${repolist}
        echo 'rhel-7-server-ansible-2.9-rpms' >> ${repolist}
        echo 'rhel-7-server-ose-3.11-rpms' >> ${repolist}
fi
}

repos(){
# Disable all repos
subscription-manager repos --disable="*"

# Enable repo based in your list
for repos in $(cat ${repolist}) ;
do
        subscription-manager repos --enable="${repos}"
done
}

packages(){
# Install necessary packages
yum -y install yum-utils createrepo docker git
}

sync(){
# Apache or Nginx?
httpd=$(systemctl status httpd | grep active | awk -F'(' '{ print $2 }' | awk -F')' '{ print $1 }')
nginx=$(systemctl status nginx | grep active | awk -F'(' '{ print $2 }' | awk -F')' '{ print $1 }')

# Check Web Service
# In the case of error, maybe you need change manually!
if [ "${httpd}" == 'running' ] ; then
        directory="/var/www/html" # Apache
else
        if [ "${nginx}" == 'running' ] ; then
                directory="/usr/share/nginx/html" # Nginx
        fi
fi

# Sync repositories
for repo in $(cat ${repolist}) ;
do
  mkdir -p ${directory}/${repo}
  reposync --gpgcheck -lm --repoid=${repo} --download_path=${directory}
  createrepo -v ${directory}/${repo} -o ${directory}/${repo} 
done
rm -f ${repolist}
}

## Exec Funcs
register
list
repos
packages
sync
