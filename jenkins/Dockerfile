FROM jenkins:2.3-alpine

COPY plugins.txt /usr/share/jenkins/ref/
COPY scripts/* /usr/share/jenkins/ref/init.groovy.d/

RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt
RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state