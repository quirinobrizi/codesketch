FROM nginx:1.11.3-alpine

MAINTAINER Quirino Brizi "quirino.brizi@gmail.com"

ENV SERVER_NAME "codesketch.internal"
ENV CERTIFICATE_FOLDER ./certs/
ENV CERTIFICATE codesketch.crt
ENV CERTIFICATE_KEY codesketch.key

COPY ./scripts/* /scripts/
COPY ./templates/* /templates/
COPY ${CERTIFICATE_FOLDER}/${CERTIFICATE} /certs/
COPY ${CERTIFICATE_FOLDER}/${CERTIFICATE_KEY} /certs/
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./public_html/* /usr/share/nginx/html/

RUN chmod +x /scripts/setup.sh
RUN cd /scripts && /bin/sh setup.sh ${SERVER_NAME} /certs/${CERTIFICATE} /certs/${CERTIFICATE_KEY}

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]