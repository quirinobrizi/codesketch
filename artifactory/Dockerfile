FROM jfrog-docker-reg2.bintray.io/jfrog/artifactory-oss:4.7.1
MAINTAINER Quirino Brizi <quirino.brizi@gmail.com>

ENV LDAP_BASEDN "dc=codesketch,dc=internal"
ENV LDAP_ADMIN_PASSWORD ""

COPY ./scripts/entrypoint /entrypoint
COPY ./templates/* /templates/

RUN chmod +x /entrypoint

ENTRYPOINT /entrypoint ${LDAP_BASEDN} ${LDAP_ADMIN_PASSWORD}
