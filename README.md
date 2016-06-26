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

## Getting started

This section describes how to install and run Codesketch.

### Prerequisite

In order to install Codesketch the following software need to be present on your machine, please refer to the software documentation for information on how to install.

* [Docker](https://docs.docker.com/engine/quickstart/)
* [Docker Compose](https://docs.docker.com/compose/overview/)

When started the Codesketch requires 3GB of RAM, for a 6GB is recommended.

### Authentication

COdeskectch uses LDAP to manage access, at startup a defualt user is created with username codeskectch and password codeskecth. More users can be added via PHP OpenLDAP user interface. 

Default account are provided for PHP OpenLDAP and Artifactory (artifactory allows login using codesketch user as well):
* [Artifactory](https://www.jfrog.com/open-source/) - username: admin password: password
* [PHP OpenLDAP](http://phpldapadmin.sourceforge.net/wiki/index.php/Main_Page) - username: admin password: password

### Installation

1. Download Codesketch latest release from th (releases page)[https://github.com/quirinobrizi/codesketch/releases]
2. Extract the downloaded archive in your preferred folder (i.e. /opt/codeskech)
3. Move to the newly created directory (i.e. cd /opt/codeskecth)
4. issue the following command ```bash bash codesketch start ```

All the tools will be pulled and installed in you machine.

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

Collect logs from codesketch tools. This command is temporary as a log collection stack will be introduced, as such a web based user interface will be available for log inspection.

The container argument is optional, if provided only logs for the requested container(s) will be shown provided.

``` bash
bash codesketch logs [container <nginx|jenkins-master|jenkins-slave|artifactory|registry|lighthouse|sonarqube|postgresql>]
```

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
## Future features

* Group based LDAP authentication
* Introduce agile management tool
* Docker Swarm integration
* Distributed volumes
* High availability
* Introduce GitLab
