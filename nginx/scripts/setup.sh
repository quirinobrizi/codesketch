#!/bin/bash

server_name=$1
certificate=$2
certificate_key=$3

echo "* configuring SSL engine, server name:${server_name}, certificate: ${certificate}, certificate key: ${certificate_key}"
rm -f /etc/nginx/conf.d/codesketch-ssl.conf
sed -e "s/%{server_name}/${server_name}/" \
  -e "s+%{ssl_certificate}+${certificate}+" \
  -e "s+%{ssl_certificate_key}+${certificate_key}+" \
  /templates/codesketch-ssl.tpl.conf > /etc/nginx/conf.d/codesketch-ssl.conf
