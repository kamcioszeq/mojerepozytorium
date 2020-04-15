#!/bin/bash

sudo mkdir /influxdbdownload
sudo mkdir /influxdb 

sudo yum update -y 
sudo yum install -y vim curl

sudo wget https://dl.influxdata.com/influxdb/releases/influxdb-1.7.10.x86_64.rpm -P /influxdbdownload
sudo yum localinstall /influxdbdownload/influxdb-1.7.10.x86_64.rpm -y

sudo systemctl start influxdb && sudo systemctl enable influxdb

sudo rm -rf /influxdbdownload

while ! [ -e ${device_name} ]
  do sleep 1 ;echo "waiting for EBS drive to appear"
done

sudo echo "${device_name}   /influxdb/data   ext4   defaults  0  2" >> /etc/fstab

sudo mkfs.ext4 ${device_name}
sudo mkdir /influxdb/data
sudo mount -a

sed -i 's|"/var/lib/influxdb/data"|"/influxdb/data"|' /etc/influxdb/influxdb.conf

sudo chown -R influxdb:influxdb /influxdb/data

sudo service influxdb restart 

sudo cat <<EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

sudo yum install grafana -y 
sudo systemctl daemon-reload
sudo systemctl start grafana-server && sudo systemctl enable grafana-server

