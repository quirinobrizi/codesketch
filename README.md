# Codesketch

Codesketch proposess a collection of tools that allow code quality and delivery management, it is based on [Docker](https://www.docker.com) for easy portability and evaluation. 

## Tool

The following tools are inclided:
* [Jenkins](https://jenkins.io/)
* [Artifactory](https://www.jfrog.com/open-source/)
* [SonarQube](http://www.sonarqube.org/)
* [Docker registry v2](https://docs.docker.com/registry/)
* [OpenLDAP](http://www.openldap.org)
* [PHP OpenLDAP](http://phpldapadmin.sourceforge.net/wiki/index.php/Main_Page)
* [ELK Stack](https://www.elastic.co/webinars/introduction-elk-stack)

## Getting started

This section describes how to install and run Codesketch.

### Prerequisite

In order to install Codesketch the following software need to be present on your machine, please refer to the software documentation for information on how to install.

* [Docker](https://docs.docker.com/engine/quickstart/)
* [Docker Compose](https://docs.docker.com/compose/overview/)

When started the Codesketch requires 3GB of RAM, for a 6GB is recommended.

### Authentication

Codeskectch uses LDAP to manage access, at startup a defualt user is created with username codeskectch and password codeskecth. More users can be added via PHP OpenLDAP user interface. 

Jenkins and Sonarqube authentication is based on groups, as per [Artifactory OSS limitations](https://www.jfrog.com/confluence/display/RTF/Artifactory+Comparison+Matrix) groups based authentocation is not enabled for Artifactory, maning that whane creating new users the user need to be added to the relative group(s).
LDAP groups are defined as following:

 * *administrators* groups contains Jenkins administrators
 * *developers* group contains Jenkins developers
 * *sonar-administrators* group containins Sonarqube administrators
 * *sonar-users* group containins Sonarqube users

Default account are provided for PHP OpenLDAP and Artifactory (artifactory allows login using codesketch user as well):
* [Artifactory](https://www.jfrog.com/open-source/) - username: admin password: password, this is in addition to codesketch user and dedicated to administration activities.
* [PHP OpenLDAP](http://phpldapadmin.sourceforge.net/wiki/index.php/Main_Page) - username: admin password: password

### Installation

#### Vagrant
1. Download Codesketch latest release from th [releases page](https://github.com/quirinobrizi/codesketch/releases)
2. Extract the downloaded archive in your preferred folder (i.e. /opt/codeskech)
3. Move to the vagrant directory (i.e. cd /opt/codeskecth/vagrant)
4. [Install vagrant](https://www.vagrantup.com/docs/installation/) 
5. Start vagrant using ``` bash vagrant up ``` command

#### Manual
1. Download Codesketch latest release from th [releases page](https://github.com/quirinobrizi/codesketch/releases)
2. Extract the downloaded archive in your preferred folder (i.e. /opt/codeskech)
3. Move to the newly created directory (i.e. cd /opt/codeskecth)
4. issue the following command ```bash bash codesketch start ```

All the tools will be pulled and installed in you machine.

### Access the tools

To access the provided tools, map your machine or the vagrant guest machine IP address to the codesketch.internal DNS using  your hosts file.
One done tools are accessible from your browser access https://codesketch.internal.

### Limitations

* Data are stored in local volumes
* Codesketch is not high available 

## Management

Following instruction describe how to manage Codesketch tools platform.

### Start

Start Codesketch tools.

``` bash
bash codesketch start
```

### Stop

Start Codesketch tools.

``` bash
bash codesketch stop
```

### Logs

Codesketch logs are made available trhought Kibana.

### Restart
Restart all containers or a subset of conatainers. The container argument is optional, if provided only the container(s) provided will be restarted.

```bash
bash codesketch restart [container <nginx|jenkins-master|jenkins-slave|artifactory|registry|lighthouse|sonarqube|postgresql>]
```

This command is usefull if additional configuration need to be provided for NginX, in this case the command should be run as following:

```bash
bash codesketch restart nginx
```

### Use NginX to proxy your site

To use codesketch NginX to proxy request for your application all you need is to provide additional configuration for NginX. The new configuration can be provided on the *nginx/conf.d* part of this installation folder and it will automatically loadded when NginX is reloaded (the easisest is to restart NginX container).

A simple configuration for NginX can be as following:

```bash
server {
  listen   80;
  server_name   my-application.com;
  access_log /var/log/nginx/access.log;

  location / {
    proxy_pass  http://internal.my-application.com;
  }
}
```

One the configuration is made available on *nginx/conf.d* folder the following command need to be issued in order to activate it:

```bash
bash codesketch restart nginx
```

### Push your images to docker registry

To push an image to the private registry you need to tag it using your DNS, default codesketch.internal, and push the image.

```bash
docker tag my-image:latest codesketch.internal/my-image:latest
docker push codesketch.internal/my-image:latest
```

## Future features

* Introduce agile management tool
* Docker Swarm integration
* Distributed volumes
* High availability
* Introduce GitLab
