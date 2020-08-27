#!/bin/bash
# logging
LOG_FILE="/status.log"
if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
else
    #if file exists, exit as only want to run once
    exit
fi
exec 1>$LOG_FILE 2>&1
echo "starting" >> /status.log
# install packages
apt-get update
apt-get install gettext bash jq gzip coreutils grep less sed tar python-pexpect socat conntrack -y
# docker settings
mkdir -p /etc/docker
cat << EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh
# install compose
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
#Run  services for controller
sleep 10
# access secret from secretsmanager
secrets=$(gcloud secrets versions access latest --secret="controller-secret")
cat << EOF > docker-compose.yml
version: "3.7"
services:
  controller-postgres:
    image: postgres:9.5
    ports:
    - "5432:5432"
    restart: always
    environment:
      POSTGRES_USER: "$(echo $secrets | jq -r .dbuser)"
      POSTGRES_PASSWORD: "$(echo $secrets | jq -r .dbpass)"
      POSTGRES_DB: "naas"
  controller-smtp:
    image: namshi/smtp
    ports:
    - "2587:25"
    restart: always
EOF
docker-compose up -d
echo "docker done" >> /status.log
# install controller
token=$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/${serviceAccount}/token' -H 'Metadata-Flavor: Google' | jq -r .access_token )
url="https://storage.googleapis.com/storage/v1/b/${bucket}/o/controller-installer-3.7.0.tar.gz?alt=media"
name=$(basename $url )
file=$${name}
file=$${file%"?alt=media"}
echo "$${file}"
curl -Lsk -H "Metadata-Flavor: Google" -H "Authorization: Bearer $token" $url -o /$file
tar xzf /$file
cd controller-installer
#local_ipv4="$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google')"
echo "controller dowloaded" >> /status.log
# k8s dependencies 
KUBE_VERSION=1.15.5
packages=(
    "kubeadm=$${KUBE_VERSION}-00"
    "kubelet=$${KUBE_VERSION}-00"
    "kubectl=$${KUBE_VERSION}-00"
)
apt-get update -qq && apt-get install -qq -y apt-transport-https curl gnupg2 >/dev/null
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list >/dev/null
apt-get update -qq

echo ""
echo "Fetch the following files:"
apt-get install --reinstall --print-uris -qq "$${packages[@]}" | cut -d"'" -f2

echo ""
echo "Install packages:"
echo "dpkg -i *.deb"
echo "k8s deps done" >> /status.log
# # Credentials
# echo "Retrieving password from Metadata secret"
# svcacct_token=$(curl -s -f --retry 20 "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -H "Metadata-Flavor: Google" | jq -r ".access_token")
# passwd=$(curl -s -f --retry 20 "https://secretmanager.googleapis.com/v1/projects/$projectId/secrets/$usecret/versions/1:access" -H "Authorization: Bearer $svcacct_token" | jq -r ".payload.data" | base64 --decode)

echo "creating user" >> /status.log
# create controller user
adduser controller
usermod -aG sudo,adm,docker controller
echo 'controller ALL=(ALL:ALL) NOPASSWD: ALL' | EDITOR='tee -a' visudo
# start install
echo "installing controller" >> /status.log
sudo tee /retry.sh <<EOF
# set vars
local_ipv4="$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google')"
pw="$(echo "$secrets" | jq -r .pass)"
admin="$(echo "$secrets" | jq -r .user)"
dbpass="$(echo "$secrets" | jq -r .dbpass)"
dbuser="$(echo "$secrets" | jq -r .dbuser)"
cd /controller-installer/
./install.sh \
--non-interactive \
--accept-license \
--self-signed-cert \
--db-host "\$local_ipv4" \
--db-port 5432 \
--db-user "\$dbuser" \
--db-pass "\$dbpass" \
--smtp-host "\$local_ipv4" \
--smtp-port 2587 \
--smtp-authentication false \
--smtp-use-tls false \
--noreply-address noreply@example.com \
--admin-email "\$admin" \
--admin-password "\$pw" \
--fqdn "\$local_ipv4" \
--admin-firstname Admin \
--admin-lastname Nginx \
--tsdb-volume-type local \
--organization-name F5
EOF
chmod +x /retry.sh
su - controller -c "/retry.sh"
#remove rights
sed -i "s/controller ALL=(ALL:ALL) NOPASSWD: ALL//g" /etc/sudoers
rm /retry.sh
# licence
# install cert key
echo "setting info from Metadata secret"
# license
cat << EOF > /controller_license.txt
$(echo $secrets | jq -r .license)
EOF
## payloads
payloadLicense=$(cat -<<EOF
{
  "content": "$(echo -n "$(cat /controller_license.txt)" | base64 -w 0)"
}
EOF
)
payload=$(cat -<<EOF
{
  "credentials": {
        "type": "BASIC",
        "username": "$(echo $secrets | jq -r .user)",
        "password": "$(echo $secrets | jq -r .pass)"
  }
}
EOF
)
function license() {
    # Check api Ready
    ip="$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google')"
    version="api/v1"
    loginUrl="/platform/login"
    count=0
    while [ $count -le 10 ]
    do
    status=$(curl -ksi https://$ip/$version$loginUrl  | grep HTTP | awk '{print $2}')
    if [[ $status == "401" ]]; then
        curl -sk --header "Content-Type:application/json"  --data "$payload" --url https://$ip/$version$loginUrl --dump-header /cookie.txt
        cookie=$(cat /cookie.txt | grep Set-Cookie: | awk '{print $2}')
        rm /cookie.txt
        curl -sk --header "Content-Type:application/json" --header "Cookie: $cookie" --data "$payloadLicense" --url https://$ip/$version/platform/license-file
        curl -sk --header "Content-Type:application/json" --header "Cookie: $cookie" --url https://$ip/$version/platform/license
        break
    else
        echo "Status $status"
        count=$[$count+1]
    fi
    sleep 60
    done
}
license
function environments() {
environmentsUri="/services/environments"
environments="development test production"
for env in $environments;
do
envPayload=$(cat -<<EOF
{
  "metadata": {
    "name": "$env",
    "displayName": "$env",
    "description": "",
    "tags": []
  },
  "desiredState": {}
}
EOF
)
echo $envPayload | jq .
curl -sk --header "Content-Type:application/json" --header "Cookie: $cookie" --data "$envPayload" --url https://$ip/$version$environmentsUri
done 
}
environments
echo "done" >> /status.log
exit

#vars:
#    - ctrl_tarball_src: "{{ctrl_install_path}}/{{controller_tarball}}"
#    - ctrl_install_path: /home/ubuntu
#    - remote_src: no
#    - db_host: 10.1.20.13
#    - db_port: "5432"
#    - db_user: "naas"
#    - db_password: 'naaspassword'
#    - tsdb_volume_type: local
#    - tsdb_nfs_path: "/controllerdb"
#    - tsdb_nfs_host: storage.internal
#    - smtp_host: "10.1.20.13"
#    - smtp_port: "25"
#    - smtp_authentication: false
#    - smtp_use_tls: false
#    - noreply_address: "noreply@example.com"
#    - fqdn:  10.1.20.13
#    - organization_name: "Nginx"
#    - admin_firstname: "Admin"
#    - admin_lastname: "Nginx"
#    - admin_email: "admin@nginx-gcp.internal"
#    - admin_password: 'admin123!'
#    - self_signed_cert: true
#    - overwrite_existing_configs: true
#    - auto_install_docker: false
#    - controller_tarball: "offline-controller-installer-1940006.tar.gz"
#    - ansible_python_interpreter: /usr/bin/python3