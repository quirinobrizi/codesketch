#!/bin/sh

echo "* configuring openldap"
dc=$1;
echo "* configuring openldap for DC $dc"
mkdir -p ./openldap/bootstrap/ldif
sed -e "s/%{ldap_domain}/$dc/" \
	/templates/codesketch.tpl.ldif > /container/service/slapd/assets/config/bootstrap/ldif/06-cs-users.ldif
sed -e "s/%{ldap_domain}/$dc/" \
	/templates/groups.tpl.ldif > /container/service/slapd/assets/config/bootstrap/ldif/07-cs-groups.ldif

ls /container/service/slapd/assets/config/bootstrap/ldif/