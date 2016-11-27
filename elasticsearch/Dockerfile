FROM elasticsearch:5

MAINTAINER Quirino Brizi <quirino.brizi@gmail.com>

ENV MAX_MAP_COUNT 262144

RUN echo "* - nofile 65535" >> /etc/security/limits.conf && \
	echo "* - memlock unlimited" >> /etc/security/limits.conf