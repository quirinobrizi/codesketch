FROM osixia/phpldapadmin:0.6.9
MAINTAINER Quirino Brizi <quirino.brizi@gmail.com>

ENV SERVER_NAME "codesketch.internal"
ENV LDAP_BASEDN "dc=codesketch,dc=internal"

COPY ./scripts/entrypoint /
COPY ./templates/* /templates/

RUN chmod +x /entrypoint

ENTRYPOINT /entrypoint "${SERVER_NAME}" "${LDAP_BASEDN}"