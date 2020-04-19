udo mkdir /influxdbdownload
sudo mkdir /influxdb

sudo yum update -y
sudo yum install -y vim curl

sudo wget https://dl.influxdata.com/influxdb/releases/influxdb-1.7.10.x86_64.rpm -P /influxdbdownload
sudo yum localinstall /influxdbdownload/influxdb-1.7.10.x86_64.rpm -y

sudo systemctl start influxdb && sudo systemctl enable influxdb

sudo rm -rf /influxdbdownload

while ! [ -e ${ebs_volume_name} ]
  do sleep 1 ;echo "waiting for EBS drive to appear"
done

sudo echo "${ebs_volume_name}   /influxdb/data   ext4   defaults  0  2" >> /etc/fstab

sudo mkfs.ext4 ${ebs_volume_name}
sudo mount -a
sudo mkdir /influxdb/data
sudo mkdir /influxdb/plugins

sudo chown -R influxdb:influxdb /influxdb/data
sudo sed -i 's|"/var/lib/influxdb/data"|"/influxdb/data"|' /etc/influxdb/influxdb.conf
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
sudo chown -R grafana:grafana /influxdb/plugins

curl -i -XPOST http://localhost:8086/query --data-urlencode "q=CREATE DATABASE grafana"
sudo sed -i '/[[:space:]]auth-enabled[[:space:]]=[[:space:]]false/c auth-enabled=true' /etc/influxdb/influxdb.conf
curl -i -XPOST http://localhost:8086/query --data-urlencode "q=CREATE USER admin WITH PASSWORD 'admin' WITH ALL PRIVILEGES"
sudo sed -i '/plugins[[:space:]]=/a plugins=/influxdb/plugins' /etc/grafana/grafana.ini
sudo sed -i '/\[auth.ldap\]/a allow_sign_up=true' /etc/grafana/grafana.ini
sudo sed -i '/\[auth.ldap\]/a config_file=/etc/grafana/ldap.toml' /etc/grafana/grafana.ini
sudo sed -i '/\[auth.ldap\]/a enabled=true' /etc/grafana/grafana.ini
sudo sed -i '/host[[:space:]]=/c host="ldap://ad-auth.dtc.prod.williamhill.plc"' /etc/grafana/ldap.toml
sudo sed -i '/port[[:space:]]=/c port=3269' /etc/grafana/ldap.toml
sudo sed -i '/^use_ssl[[:space:]]=/c use_ssl=true' /etc/grafana/ldap.toml
sudo sed -i '/start_tls[[:space:]]=/c start_tls=true' /etc/grafana/ldap.toml
sudo sed -i '/bind_dn[[:space:]]=/c bind_dn="cn=svcCX.join,ou=Service Accounts,ou=Servers,ou=WILLIAMHILL,dc=Group,dc=WilliamHill,dc=PLC"' /etc/grafana/ldap.toml
sudo sed -i '/^search_filter[[:space:]]=/c search_filter="(sAMAccountName=%s)"' /etc/grafana/ldap.toml
sudo sed -i '/^search_base_dns[[:space:]]=/c search_base_dns=["DC=group,DC=williamhill,DC=plc"]' /etc/grafana/ldap.toml
sudo sed -i '/^username[[:space:]]=/c username="sAMAccountName"' /etc/grafana/ldap.toml

sudo systemctl restart influxdb
sudo systemctl daemon-reload
sudo systemctl start grafana-server && sudo systemctl enable grafana-server
