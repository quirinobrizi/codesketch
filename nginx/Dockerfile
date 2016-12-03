FROM debian:8.2

MAINTAINER Quirino Brizi "quirino.brizi@gmail.com"

ENV NGINX_VERSION release-1.11.6

ENV SERVER_NAME "codesketch.internal"
ENV CERTIFICATE_FOLDER ./certs/
ENV CERTIFICATE codesketch.crt
ENV CERTIFICATE_KEY codesketch.key
ENV LDAP_BASEDN "dc=codesketch,dc=internal"
ENV LDAP_ADMIN_PASSWORD password

#
# Install needed packages, compile and install.
# Remove unused packages and cleanup some directories.
#
RUN \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates \
        git \
        gcc \
        make \
        libpcre3-dev \
        zlib1g-dev \
        libldap2-dev \
        libssl-dev \
        wget && \
    mkdir /var/log/nginx && \
    mkdir /etc/nginx && \
    cd /tmp && \
    git clone https://github.com/kvspb/nginx-auth-ldap.git && \
    git clone https://github.com/nginx/nginx.git && \
    cd /tmp/nginx && \
    git checkout tags/${NGINX_VERSION} && \
    ./auto/configure \
        --add-module=/tmp/nginx-auth-ldap \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-pcre \
        --with-debug \
        --conf-path=/etc/nginx/nginx.conf \ 
        --sbin-path=/usr/sbin/nginx \ 
        --pid-path=/var/log/nginx/nginx.pid \ 
        --error-log-path=/var/log/nginx/error.log \ 
        --http-log-path=/var/log/nginx/access.log && \ 
    make install && \
    apt-get purge -y \
        git \
        gcc \
        make \
        libpcre3-dev \
        zlib1g-dev \
        libldap2-dev \
        libssl-dev \
        wget && \
    apt-get autoremove -y && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/src/* && \
    rm -rf /tmp/* && \
    rm -rf /usr/share/doc/* && \
    rm -rf /usr/share/man/* && \
    rm -rf /usr/share/locale/*

#
# link access and error logs to docker log collector.
#
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY ./scripts/entrypoint /
COPY ./templates/* /templates/
COPY ${CERTIFICATE_FOLDER}/${CERTIFICATE} /certs/
COPY ${CERTIFICATE_FOLDER}/${CERTIFICATE_KEY} /certs/
COPY ./public_html/ /usr/share/nginx/html/

RUN chmod +x /entrypoint

EXPOSE 80 443

ENTRYPOINT /entrypoint ${SERVER_NAME} "/certs/${CERTIFICATE}" "/certs/${CERTIFICATE_KEY}" ${LDAP_BASEDN} ${LDAP_ADMIN_PASSWORD}