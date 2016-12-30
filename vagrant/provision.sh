#!/bin/bash

CS_RELEASE=0.0.8

## Install driver for HTTPS repo
apt-get install -y --force-yes apt-transport-https

apt-get update
apt-get install -y --force-yes curl

echo "* Install docker"
wget -qO- https://get.docker.com/ | sh
sudo usermod -aG docker vagrant

echo "* Install docker compose"
curl -L https://github.com/docker/compose/releases/download/1.9.0/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "* Creating swap on file"
dd if=/dev/zero of=/swapfile bs=1024 count=2097152
chown root:root /swapfile
chmod 0600  /swapfile
mkswap  /swapfile
swapon  /swapfile

echo "* Install codesketch"
wget https://github.com/quirinobrizi/codesketch/archive/v${CS_RELEASE}.tar.gz
tar -xzf ${CS_RELEASE}.tar.gz
mv codesketch-${CS_RELEASE} codesketch
cd  codesketch
su - vagrant
export LOGSTASH_HOST=$(hostname)
bash codesketch start

echo "*************************************"
echo "******** Provision completed ********"
echo "*************************************"