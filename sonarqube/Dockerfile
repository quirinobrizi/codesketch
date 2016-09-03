FROM sonarqube:5.6.1-alpine
MAINTAINER Quirino Brizi <quirino.brizi@gmail.com>

ENV LDAP_BASEDN "dc=codesketch,dc=internal"

COPY ./scripts/entrypoint /entrypoint
COPY ./templates/* /templates/
COPY ./extensions/plugins/* /opt/sonarqube/extensions/plugins/

RUN chmod +x /entrypoint

ENTRYPOINT /entrypoint ${LDAP_BASEDN}