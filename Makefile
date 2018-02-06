.DEFAULT_GOAL := help
.PHONY: help

tag ?= $(shell test -f .cache/tag && cat .cache/tag || echo 'ns0')
tld ?= $(shell test -f .cache/tld && cat .cache/tld || echo 'docker')
name ?= $(shell test -f .cache/name && cat .cache/name || echo '${tag}')

DOCKER_INTERFACE=docker0
UNAME := $(shell uname)
WHO := $(shell whoami)
HOME := $(shell echo ~)
HOME_ROOT := $(shell echo ~root)
PWD := $(shell pwd | sed -e 's/\//\\\\\//g')
HOSTNAME := $(shell hostname)
DOCKER := $(shell which docker)

DOCKER_CONTAINER_TAG := $(tag)
DOCKER_CONTAINER_NAME := $(name)
TLD := $(tld)

-include /etc/os-release
ifeq (${UNAME},Darwin)
	NAME=macOS
	VERSION_MAJOR_ID := $(shell sw_vers -productVersion | cut -d. -f1-2)
else
	NAME := $(shell echo ${NAME} | sed -e s/\"//g)
	VERSION_MAJOR_ID=$(shell echo ${VERSION_ID} | cut -d. -f1)
endif
include conf/Makefile/${UNAME}_${NAME}${VERSION_MAJOR_ID}.mk

_check-docker-is-up:
ifneq (${UNAME},Darwin)
ifeq ($(shell (ifconfig docker0 1> /dev/null 2> /dev/null && echo yes) || echo no),no)
	@echo "Docker is not up! Network docker0 interface was not found"
	@echo ""
	@exit 1
endif
ifeq ($(shell groups ${WHO} | grep -q -E ' docker' || echo no),no)
	@echo "You do not have permission to run Docker! Try logging out and on again."
	@echo ""
	@exit 1
endif
endif


welcome: _check-docker-is-up
	@printf "\033[33m     _            _                      _            \n"
	@printf "\033[33m  __| | ___   ___| | _____ _ __       __| |_ __  ___  \n"
	@printf "\033[33m / _\` |/ _ \ / __| |/ / _ \ '__|____ / _\` | '_ \/ __| \n"
	@printf "\033[33m| (_| | (_) | (__|   <  __/ | |_____| (_| | | | \__ \ \n"
	@printf "\033[33m \__,_|\___/ \___|_|\_\___|_|        \__,_|_| |_|___/ \n"
	@printf "\033[33m                                                      \n"
	@printf "\033[m\n"

build-docker-image:
	@[ -f Dockerfile_id_rsa ] || ssh-keygen -f Dockerfile_id_rsa -P ""
	@$(DOCKER) build . -t $(DOCKER_CONTAINER_TAG):latest

ifeq ($(UNAME), Darwin)
install-dependencies: install-dependencies-macos
else
install-dependencies:
	@[ `sudo -n true 2>/dev/null` ]; printf "\033[32mPlease type your sudo password, for network configuration.\033[m\n" && sudo ls > /dev/null
	@sudo ${PACKAGE_MANAGER} install `cat requirements.apt` -y
ifeq ($(shell grep @docker-dns $(RESOLVCONF) | wc -l | bc ),0)
	@echo "options timeout:1 #@docker-dns\nnameserver $(IP) #@docker-dns" | sudo cat - $(RESOLVCONF) > /tmp/docker-dns-resolv; sudo mv /tmp/docker-dns-resolv $(RESOLVCONF)
endif
	@make install-dependencies-os
endif

update-conf:
	@test -d .cache || mkdir .cache
	@echo ${DOCKER_CONTAINER_TAG} > .cache/tag
	@echo ${DOCKER_CONTAINER_NAME} > .cache/name
	@echo ${TLD} > .cache/tld
	

install: welcome update-conf build-docker-image install-dependencies ## Setup DNS container to resolve ENV.TLD domain inside and outside docker in your machine
	@if [ `$(DOCKER) container inspect $(DOCKER_CONTAINER_NAME) 1>&1 2>/dev/null | head -n1` = "[" ]; then \
		echo "Stopping existing instance"; \
		$(DOCKER) stop $(DOCKER_CONTAINER_NAME) 1> /dev/null 2> /dev/null; \
		$(DOCKER) rm $(DOCKER_CONTAINER_NAME) 1> /dev/null 2> /dev/null; \
	fi
	@if [ ! -f $(DOCKER_CONF_FOLDER)/daemon.json ]; then sudo sh -c "mkdir -p $(DOCKER_CONF_FOLDER); sudo cp conf/daemon.json.docker $(DOCKER_CONF_FOLDER)/daemon.json";  fi
	@sudo cat $(DOCKER_CONF_FOLDER)/daemon.json | jq '. + {"bip": "${IP}/24", "dns": ["${IP}", "${DNSs}"]}' > /tmp/daemon.docker.json.tmp; sudo mv /tmp/daemon.docker.json.tmp "$(DOCKER_CONF_FOLDER)/daemon.json"
	@echo Setting up dnsmasq
	@cat conf/dnsmasq.local | sed s/\\$$\{IP\}/${IP}/g | sed s/\\$$\{TLD\}/${TLD}/ | sed s/\\$$\{HOSTNAME\}/${HOSTNAME}/ | sed s/\\$$\{LOOPBACK\}/${LOOPBACK}/ > /tmp/01_docker.tmp; sudo mv -f /tmp/01_docker.tmp "$(DNSMASQ_LOCAL_CONF)"
	@echo Generating certificate for $(TLD) domain, if necessary
	@test -f conf/certs.d/$(TLD).key || openssl req -x509 -newkey rsa:4096 -keyout conf/certs.d/$(TLD).key -out conf/certs.d/$(TLD).cert -days 365 -nodes -subj "/CN=*.$(TLD)"
	@echo Copying certificate to $(DOCKER_CONF_FOLDER) if necessary
	@sudo sh -c "cp -a conf/certs.d/$(TLD).* $(DOCKER_CONF_FOLDER)"
	@while [ `$(DOCKER) ps 1> /dev/null` ]; do \
		echo "Waiting for Docker..."; \
		sleep 2; \
	done;
	@echo Starting $(DOCKER_CONTAINER_NAME) container...
	@$(DOCKER) run -d --name $(DOCKER_CONTAINER_NAME) --restart always --security-opt apparmor:unconfined -p $(PUBLISH_IP_MASK)53:53/udp -p $(PUBLISH_IP_MASK)53:53 -P -e TOP_LEVEL_DOMAIN=$(TLD) -e HOSTNAME=$(HOSTNAME) -e HOSTUNAME=$(shell uname) --volume /var/run/docker.sock:/var/run/docker.sock $(DOCKER_CONTAINER_TAG) -R
	@make install-os
	@echo Now all of your containers are reachable using CONTAINER_NAME.$(TLD) inside and outside docker.  E.g.: nc -v $(DOCKER_CONTAINER_NAME).$(TLD) 53

uninstall: welcome ## Remove all files from docker-dns
	@echo "Uninstalling docker dns exposure"
ifneq ($(shell docker images | grep "${DOCKER_CONTAINER_NAME}" | wc -l | bc), 0)
	@echo "- Stopping container if necessary"
	@$(DOCKER) stop $(DOCKER_CONTAINER_NAME) || echo Could not stop container $(DOCKER_CONTAINER_NAME)
	@$(DOCKER) rm $(DOCKER_CONTAINER_NAME) || echo Could not remove container $(DOCKER_CONTAINER_NAME)
	@echo "- Removing container image if necessary"
	@$(DOCKER) rmi $(DOCKER_CONTAINER_TAG) -f || echo Could not remove image $(DOCKER_CONTAINER_TAG)
endif
	@sudo rm -Rf $(DNSMASQ_LOCAL_CONF) 2> /dev/null 1> /dev/null
	@if [ -f "$(DOCKER_CONF_FOLDER)/daemon.json" ]; then sudo cat $(DOCKER_CONF_FOLDER)/daemon.json | jq 'map(del(.bip, .dns)' > /tmp/daemon.docker.json.tmp 2>/dev/null; sudo mv /tmp/daemon.docker.json.tmp $(DOCKER_CONF_FOLDER)/daemon.json > /dev/null; fi
	@make uninstall-os


show-domain: _check-docker-is-up ## View the docker domain installed
ifeq ('$(docker inspect ${DOCKER_CONTAINER_TAG})', '[]')
	@echo "docker-dns not installed! Please install first"
else
	@echo Working domain:
	@$(DOCKER) inspect $(DOCKER_CONTAINER_TAG) | grep TOP_ | cut -d= -f2 | cut -d\" -f1
endif

help: welcome
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep ^help -v | sort | awk 'BEGIN {FS = ":([^:]*)? ## "};  {gsub("Makefile:","",$$1); split($$1,a,".mk:"); if(length(a)>1){$$1=a[2]}; printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'