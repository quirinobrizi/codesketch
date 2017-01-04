#!/usr/bin/env bash -e

CONTROL_FILE=.codesketch
LDAP_ADMIN_PASSWORD=password

function configure {
	echo "* configuring Codesketch"
	configure_usage() {
		echo "" 
		echo "bash codesketch [start|config] -s server name -c certificate path -k certificate key path [-w]" 1>&2; 
		echo "when provided -c option -k must be provided and vice versa."
		echo "when -w flag is provided a docker swarm is created and services deployed on it, requires docker-machine to be installed"
		echo ""
		exit 1; 
	}
	local compose_files="-f docker-compose-nginx.yml -f docker-compose-codesketch.yml -f docker-compose-openldap.yml -f docker-compose-elk.yml"
    local OPTIND opts server_name certificate certificate_key email swarm swarm_provider
    while getopts ":s:c:k:e:w:" opts; do
        case "${opts}" in
            s)
                server_name="${OPTARG}"
                ;;
            c)
                certificate="${OPTARG}"
                ;;
            k)
                certificate_key="${OPTARG}"
                ;;
            e) 
				email="${OPTARG}"
				;;
			w)
				swarm="1"
				swarm_provider="${OPTARG:-virtualbox}"
				;;
            *)
                configure_usage
                ;;
        esac
    done
    shift $((OPTIND-1))

    if [[ -z "$server_name" ]] || [[ -z "$certificate" ]] || [[ -z "$certificate_key" ]]; then
    	echo "* not all of server name, certificate and certificate key has been provided using defaults"
    	server_name="codesketch.internal"
    	certificate_folder=./nginx/certs 
	    certificate="codesketch.crt" 
	    certificate_key="codesketch.key"
    fi

    if [ "${swarm}" == "1" ]; then
    	echo " * creating swarm 2 - ${server_name}"
    	bash swarm/setup-${swarm_provider} 2 ${server_name}
    	[ "$?" != "0" ] && exit 1
    	eval $(docker-machine env --swarm codesketch-swarm-master)
    	compose_files="${compose_files} -f docker-compose-elk-swarm.yml -f docker-compose-openldap-swarm.yml -f docker-compose-nginx-swarm.yml -f docker-compose-codesketch-swarm.yml"
    fi

	echo "* configuring openldap"
	local dc; 
	for v in ${server_name//./ }; do 
		if [[ -z "$dc" ]]; then 
			dc="dc=$v"; 
		else 
			dc="$dc,dc=$v";
		fi 
	done;
	echo "* evaluated DC string as $dc"
	
	echo "* creating environment file"
	touch environment
	echo "SERVER_NAME=${server_name}" >> environment
	echo "EMAIL=${email}" >> environment
	echo "LDAP_ORGANISATION=${server_name}" >> environment
	echo "LDAP_DOMAIN=${server_name}" >> environment 
	echo "LDAP_BASEDN=${dc}" >> environment
	echo "LDAP_ADMIN_PASSWORD=${LDAP_ADMIN_PASSWORD}" >> environment
	echo "JENKINS_LDAP_BASEDN=${dc}" >> environment
	echo "JENKINS_LDAP_MANAGER_DN=cn=admin,${dc}" >> environment
	echo "JENKINS_LDAP_MANAGER_PASSWORD=${LDAP_ADMIN_PASSWORD}" >> environment
	
	echo "* creating .env file"
	touch .env
	echo "SERVER_NAME=${server_name}" >> .env
	echo "LOGSTASH_HOST=$(ip route get 1 | awk '{print $NF;exit}')" >> .env
	echo "PROXY_HOST=$(ip route get 1 | awk '{print $NF;exit}')" >> .env

	if [ "${swarm}" != "1" ]; then
		echo "* setting vm.max_map_count=262144"
		sysctl -w vm.max_map_count=262144
		cp ./nginx/certs/codesketch.crt /usr/local/share/ca-certificates/
		update-ca-certificates
		service docker restart
		echo "* creating codesketch network"
		docker network create codesketch || true
	fi
	echo "* updating images"
	docker-compose ${compose_files} pull
	
	echo "* configuring default LDAP users and groups (default - username: codesketch, password: codesketch)"
	echo "* configuring openldap"
	mkdir -p ./openldap/bootstrap/ldif
	sed -e "s/%{ldap_domain}/$dc/" \
		./openldap/templates/codesketch.tpl.ldif > ./openldap/bootstrap/ldif/codesketch.ldif
	sed -e "s/%{ldap_domain}/$dc/" \
		./openldap/templates/groups.tpl.ldif > ./openldap/bootstrap/ldif/groups.ldif
	docker-compose ${compose_files} up -d openldap
	sleep 20s
	docker cp ./openldap/bootstrap/ldif/groups.ldif openldap:/groups.ldif 
	docker cp ./openldap/bootstrap/ldif/codesketch.ldif openldap:/codesketch.ldif 
	docker-compose ${compose_files} exec openldap ldapadd -c -x -D "cn=admin,${dc}" -w ${LDAP_ADMIN_PASSWORD} -f /groups.ldif -h openldap
	docker-compose ${compose_files} exec openldap ldapadd -c -x -D "cn=admin,${dc}" -w ${LDAP_ADMIN_PASSWORD} -f /codesketch.ldif -h openldap
	docker-compose ${compose_files} stop openldap
	echo "* default user configuration completed."

	touch $CONTROL_FILE
	echo "* Codesketch configured"
}

function start {
	source .env
	start_usage() {
		echo "" 
		echo "bash codesketch [start] [-w]" 1>&2; 
		echo " * -w, enable swarm mode"
		echo ""
		exit 1
	}
	local compose_elk="-f docker-compose-elk.yml"
	local compose_openldap="-f docker-compose-openldap.yml"
	local compose_codesketch="-f docker-compose-codesketch.yml"
	local compose_nginx="-f docker-compose-nginx.yml"
	local codesketch_ip=${PROXY_HOST}
	local OPTIND opts swarm
    while getopts ":w" opts; do
        case "${opts}" in
			w)
				swarm="1"
				;;
            *)
                start_usage
                ;;
        esac
    done
    shift $((OPTIND-1))
    if [ "${swarm}" == "1" ]; then
    	echo "* * start Codesketch on swarm"
    	compose_elk="${compose_elk} -f docker-compose-elk-swarm.yml"
    	compose_openldap="${compose_openldap} -f docker-compose-openldap-swarm.yml"
    	compose_codesketch="${compose_codesketch} -f docker-compose-codesketch-swarm.yml"
    	compose_nginx="${compose_nginx} -f docker-compose-nginx-swarm.yml"
    	codesketch_ip=$(docker-machine ip codesketch-swarm-master)
    	eval $(docker-machine env --swarm codesketch-swarm-master)
    fi
	source ./environment
	echo "* starting Codesketch in your machine using docker compose ..."
	docker-compose ${compose_elk} up -d
	sleep 30s
	docker-compose ${compose_openldap} up -d
	sleep 10s
	docker-compose ${compose_codesketch} up -d
	echo "* waiting for Codesketch to start (Please be patient this can take few minutes...)"
	sleep 120s
	docker-compose ${compose_nginx} up -d
	echo "* Codesketch has started"
	echo " * * navigate to https://${codesketch_ip} for accessing the services"
}

function stop {
	echo "* stopping Codesketch"
	eval $(docker-machine env --swarm codesketch-swarm-master)
	docker-compose -f docker-compose-elk.yml stop
	docker-compose -f docker-compose-openldap.yml stop
	docker-compose -f docker-compose-codesketch.yml stop
	docker-compose -f docker-compose-nginx.yml stop
	echo "* Codesketch stopped"
}

function status {
	source .env
	statususage() {
		echo "" 
		echo "bash codesketch [status] [-w]" 1>&2; 
		echo " * -w, swarm mode"
		echo ""
		exit 1
	}
	local compose_elk="-f docker-compose-elk.yml"
	local compose_openldap="-f docker-compose-openldap.yml"
	local compose_codesketch="-f docker-compose-codesketch.yml"
	local compose_nginx="-f docker-compose-nginx.yml"
	local codesketch_ip=${PROXY_HOST}
	local OPTIND opts swarm
    while getopts ":w" opts; do
        case "${opts}" in
			w)
				swarm="1"
				;;
            *)
                status_usage
                ;;
        esac
    done
    shift $((OPTIND-1))
    if [ "${swarm}" == "1" ]; then
    	compose_elk="${compose_elk} -f docker-compose-elk-swarm.yml"
    	compose_openldap="${compose_openldap} -f docker-compose-openldap-swarm.yml"
    	compose_codesketch="${compose_codesketch} -f docker-compose-codesketch-swarm.yml"
    	compose_nginx="${compose_nginx} -f docker-compose-nginx-swarm.yml"
    	eval $(docker-machine env --swarm codesketch-swarm-master)
    fi
    compose="${compose_elk} ${compose_openldap} ${compose_codesketch} ${compose_nginx}"
	docker-compose ${compose} ps
}

function clean {
	stop
	eval $(docker-machine env --swarm codesketch-swarm-master)
	docker network rm codesketch
	docker-compose -f docker-compose-elk.yml rm -f
	docker-compose -f docker-compose-openldap.yml rm -f
	docker-compose -f docker-compose-codesketch.yml rm -f
	docker-compose -f docker-compose-nginx.yml rm -f
	rm -f ./php-openldap/environment/env.yml
	rm -rf ./openldap/bootstrap
	rm -rf ./artifactory/etc
	rm -f ./sonarqube/sonar.properties
	rm -f ${CONTROL_FILE}
	rm -f ./.env
	rm -f ./environment
}

function down {
	clean
	rm -rf ./openldap/config/*
	docker-compose -f docker-compose-elk.yml down -v
	docker-compose -f docker-compose-openldap.yml down -v
	docker-compose -f docker-compose-codesketch.yml down -v
	docker-compose -f docker-compose-nginx.yml down -v
}

function logs {
	docker-compose -f docker-compose-codesketch.yml -f docker-compose-nginx.yml -f docker-compose-openldap.yml -f docker-compose-elk.yml logs -f $1
}

function restart {
	stop
	start
}

#
# Add a new user
#
function user {
	echo "Adding new user for DN $2"
	uid=$(($RANDOM + 10002))
	[[ "$1" == "jenkins" ]] && gid="501" || gid="504"
	sed -e "s/%{ldap_domain}/$2/" \
		-e "s/%{user}/$3/" \
		-e "s/%{uidNumber}/$uid" \
		-e "s/%{gidNumber}/$gid" \
			./user.tpl.ldif > ./user.ldif
	docker cp ./user.ldif openldap:/user.ldif
	docker exec openldap ldapadd -x -D "cn=admin,$1" -w ${LDAP_ADMIN_PASSWORD} -f /user.ldif -h openldap
	docker exec openldap rm -f /user.ldif
	rm -f user.ldif
}

function usage {
  echo "Usage:"
  echo "    ${0} stop <stop the platform> | start <start the platfom> | restart <redeploy the platform>"
  exit 1
}

if [ "$EUID" -ne 0 ]
  then echo "* Please codesketch run as root"
  exit 1
fi

case ${1} in
  start|stop|status|clean|config|logs|restart|down|user)
	case ${1} in
      start)
		if [[ ! -e ${CONTROL_FILE} ]]; then
			configure ${@:2}
		fi
		start ${@:2}
	  ;;
      stop)
		stop
	  ;;
	  status)
		status ${@:2}
	  ;;
	  clean)
		clean
	  ;;
	  config)
		configure ${@:2}
	  ;;
	  logs)
		logs ${@:2}
	  ;;
	  restart)
		restart ${@:2}
	  ;;
	  down)
		down
	  ;;
	  user)
		user ${@:2}
	  ;;
	  *)
        echo "Invalid parameter(s) or option(s)."
        usage
      ;;
    esac
    exit 0
esac
