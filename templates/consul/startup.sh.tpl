#!/bin/bash
# https://github.com/hashicorp/f5-terraform-consul-sd-webinar/blob/master/scripts/consul.sh
# debian install consul
#Utils
sudo apt update
sudo apt-get install unzip jq -y

#Get IP
# aws
#local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
# azure
#local_ipv4="$(curl -s http://169.254.169.254/metadata/instance?api-version=2019-06-01 -H "Metadata:true" | jq -r .network.interface[0].ipv4.ipAddress[0].privateIpAddress)"
# google
local_ipv4="$(curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google')"

#Download Consul
CONSUL_VERSION=${CONSUL_VERSION}
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

#Install Consul
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
consul -autocomplete-install
complete -C /usr/local/bin/consul consul

#Create Consul User
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul

#Create Systemd Config
sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl
[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=always
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

#Create config dir
sudo mkdir --parents /etc/consul.d
sudo touch /etc/consul.d/consul.hcl
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

cat << EOF > /etc/consul.d/consul.hcl
datacenter = "dc1"
data_dir = "/opt/consul"
ui = true
EOF

# aws
#cat << EOF > /etc/consul.d/client.hcl
#advertise_addr = "$${local_ipv4}"
#retry_join = ["provider=aws tag_key=Env tag_value=consul"]
#EOF
# cat << EOF > /etc/consul.d/server.hcl
# server = true
# bootstrap_expect = 1
# client_addr = "0.0.0.0"
# retry_join = ["provider=aws tag_key=Env tag_value=consul"]
# EOF
#
# azure
#cat << EOF > /etc/consul.d/client.hcl
#bind_addr = "$${local_ipv4}"
#advertise_addr = "$${local_ipv4}"
#client_addr = "0.0.0.0"
#retry_join = ["provider=azure tag_name=environment tag_value=f5env tenant_id=1 client_id=1 subscription_id=1 secret_access_key=123"]
#EOF
#cat << EOF > /etc/consul.d/server.hcl
#server = true
#bootstrap_expect = 1
#client_addr = "0.0.0.0"
#retry_join = ["provider=azure tag_name=environment tag_value=f5env tenant_id=1 client_id=1 subscription_id=1 secret_access_key=123"]
#EOF
#
#google
cat << EOF > /etc/consul.d/client.hcl
bind_addr = "$${local_ipv4}"
advertise_addr = "$${local_ipv4}"
client_addr = "0.0.0.0"
retry_join = ["provider=gce tag_value=consul-demo project_name=${project} zone_pattern=${zone}"]
EOF
cat << EOF > /etc/consul.d/server.hcl
server = true
bootstrap_expect = 1
client_addr = "0.0.0.0"
retry_join = ["provider=gce tag_value=consul-demo project_name=${project} zone_pattern=${zone}"]
EOF
#Enable the service
sudo systemctl enable consul
sudo service consul start
sudo service consul status