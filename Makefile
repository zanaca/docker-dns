.DEFAULT_GOAL := help
.PHONY: help

tag ?= ns0
tld ?= docker
name ?= $(tag)

UNAME := $(shell uname)
WHO := $(shell whoami)
HOME := $(shell echo ~)
PWD := $(shell pwd | sed -e 's/\//\\\\\//g')
HOSTNAME := $(shell hostname)
SSHUTTLE := $(shell which sshuttle)
OS_VERSION := $(shell (cat /etc/issue 2> /dev/null || false) | cut -d\  -f2 | cut -d. -f1)

DOCKER_CONTAINER_TAG := $(tag)
DOCKER_CONTAINER_NAME := $(name)
TLD := $(tld)

ifeq ($(UNAME), Darwin)
    LOOPBACK := ''
	IP := $(shell ifconfig en0 | grep "inet " | cut -d\  -f2)
	DOCKER_CONF_FOLDER := $(HOME)/Library/Containers/com.docker.docker/Data/database/com.docker.driver.amd64-linux/etc/docker
	DNSs := $(shell scutil --dns | grep nameserver | cut -d: -f2 | sort | uniq | sed s/\ //g | sed ':a;N;$!ba;s/\\\n/","/g');
	DNSs := $(shell echo "${DNSs}" | sed s/\ /\",\"/g | sed s/\;//g)
	DNSMASQ_LOCAL_CONF := /usr/local/etc/dnsmasq.conf
	SSH_PORT = 2200
	PUBLISH_SSH_PORT = -p $(SSH_PORT):22
	RESOLVCONF := /etc/resolv.conf
else
	LOOPBACK := $(shell ifconfig | grep -i LOOPBACK  | head -n1 | cut -d\  -f1 | sed -e 's\#:\#\#')
	IP := $(shell ifconfig docker0 | grep "inet " | cut -dt -f2 | cut -d: -f2 | sed -e 's\# \#\#' | cut -d\  -f1)
	DOCKER_CONF_FOLDER := /etc/docker
	DNSs := $(shell nmcli dev show | grep DNS|  cut -d\: -f2 | sort | uniq | sed s/\ //g | sed ':a;N;$!ba;s/\\\n/","/g');
	DNSs := $(shell echo "${DNSs}" | sed s/\ /\",\"/g | sed s/\;//g)
	DNSMASQ_LOCAL_CONF := /etc/NetworkManager/dnsmasq.d/01_docker
	PUBLISH_IP_MASK = $(IP):
	ifeq ($(OS_VERSION), 17)
		RESOLVCONF := /run/systemd/resolve/stub-resolv.conf
	else ifeq ($(OS_VERSION), 16)
		RESOLVCONF := /etc/resolvconf/resolv.conf.d/head
	else
		RESOLVCONF := /etc/resolv.conf
	endif
endif

welcome:
	@printf "\033[33m     _            _                      _            \n"
	@printf "\033[33m  __| | ___   ___| | _____ _ __       __| |_ __  ___  \n"
	@printf "\033[33m / _\` |/ _ \ / __| |/ / _ \ '__|____ / _\` | '_ \/ __| \n"
	@printf "\033[33m| (_| | (_) | (__|   <  __/ | |_____| (_| | | | \__ \ \n"
	@printf "\033[33m \__,_|\___/ \___|_|\_\___|_|        \__,_|_| |_|___/ \n"
	@printf "\033[33m                                                      \n"
	@printf "\033[m\n"

build-docker-image:
	@[ -f Dockerfile_id_rsa ] || ssh-keygen -f Dockerfile_id_rsa -P ""
	@docker build . -t $(DOCKER_CONTAINER_TAG):latest

ifeq ($(UNAME), Darwin)
install-dependencies:
	@test -z `sudo -n test -d ~root 2> /dev/null || echo 1` ||  printf "\033[32mPlease type your sudo password, for network configuration.\033[m\n" && sudo true > /dev/null
ifeq ($(shell cat /usr/local/etc/dnsmasq.conf 2> /dev/null || echo no_dnsmasq), no_dnsmasq)
	@#sudo brew install dnsmasq
	@mkdir -pv $(brew --prefix)/etc/
	@#sudo sh -c "cp conf/com.zanaca.dockerdns-dnsmasq.plist /Library/LaunchDaemons/"
	@#sudo launchctl load -w /Library/LaunchDaemons/com.zanaca.dockerdns-dnsmasq.plist
endif
	@brew install `cat requirements.apt | grep net-tools -v` -y 1> /dev/null 1> /dev/null
	@[ shuttle ] || sudo easy install sshuttle
	@if [ ! -d /etc/resolver ]; then sudo mkdir /etc/resolver; sudo touch /etc/resolver/$(TLD); fi
	@echo "nameserver $(IP)" | sudo cat - /etc/resolver/$(TLD) > /tmp/docker-dns-resolv; sudo mv /tmp/docker-dns-resolv /etc/resolver/$(TLD)
	@sudo sh -c "cat conf/com.zanaca.dockerdns-tunnel.plist | sed s:\{SSHUTTLE\}:$(shell which sshuttle):g | sed s:\{SSH_PORT\}:$(SSH_PORT):g > /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist"
	@sudo launchctl load -w /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist

tunnel: ## Creates a tunnel between local machine and docker network - macOS only
	@# waiting docker-dns to load
	@while [ `nc -z 127.0.0.1 $(SSH_PORT) 2>&1 | wc -l` -eq 0 ] ; do sleep 1; done
	@$(SSHUTTLE) -D -r root@127.0.0.1:$(SSH_PORT) 172.17.0.0/24

else
install-dependencies:
	@[ `sudo -n true 2>/dev/null` ]; printf "\033[32mPlease type your sudo password, for network configuration.\033[m\n" && sudo ls > /dev/null
	@sudo apt-get install `cat requirements.apt` -y
ifneq ($(shell grep $(IP) $(RESOLVCONF)), nameserver $(IP))
	@echo "nameserver $(IP)" | sudo cat - $(RESOLVCONF) > /tmp/docker-dns-resolv; sudo mv /tmp/docker-dns-resolv $(RESOLVCONF)
endif
	@if [ ! -d /etc/resolver ]; then sudo mkdir -p /etc/resolver; sudo touch /etc/resolver/$(TLD); fi
	@echo "nameserver $(IP)" | sudo cat - /etc/resolver/$(TLD) > /tmp/docker-dns-resolv; sudo mv /tmp/docker-dns-resolv /etc/resolver/$(TLD)
	@if [ ! -d /etc/resolver/resolv.conf.d ]; then sudo mkdir -p /etc/resolver/resolv.conf.d; fi
	@if [ ! -f /etc/resolver/resolv.conf.d/head ]; then sudo touch /etc/resolver/resolv.conf.d/head; fi
	@echo "nameserver $(IP)" | sudo tee -a /etc/resolver/resolv.conf.d/head;
ifeq ($(OS_VERSION), 16)
		@if [ ! -d /etc/resolvconf/resolv.conf.d ]; then sudo mkdir -p /etc/resolvconf/resolv.conf.d; fi
		@if [ ! -f /etc/resolvconf/resolv.conf.d/head ]; then sudo touch /etc/resolvconf/resolv.conf.d/head; fi
		@echo "nameserver $(IP)" | sudo tee -a /etc/resolvconf/resolv.conf.d/head;
		@sudo resolvconf -u
endif
endif


install: welcome build-docker-image install-dependencies## Setup DNS container to resolve ENV.TLD domain inside and outside docker in your machine
	@if [ `docker container inspect $(DOCKER_CONTAINER_NAME) 2> /dev/null | head -n1` = "[" ]; then \
		docker stop $(DOCKER_CONTAINER_NAME) > /dev/null && docker rm $(DOCKER_CONTAINER_NAME) > /dev/null; \
	fi
	@if [ ! -f $(DOCKER_CONF_FOLDER)/daemon.json ]; then sudo sh -c "mkdir -p $(DOCKER_CONF_FOLDER); sudo cp conf/daemon.json.docker $(DOCKER_CONF_FOLDER)/daemon.json";  fi
	@sudo cat $(DOCKER_CONF_FOLDER)/daemon.json | jq '. + {"bip": "${IP}/24", "dns": ["${IP}", "${DNSs}"]}' > /tmp/daemon.docker.json.tmp; sudo mv /tmp/daemon.docker.json.tmp "$(DOCKER_CONF_FOLDER)/daemon.json"
	@cat conf/dnsmasq.local | sed s/\\$$\{IP\}/${IP}/g | sed s/\\$$\{TLD\}/${TLD}/ | sed s/\\$$\{HOSTNAME\}/${HOSTNAME}/ | sed s/\\$$\{LOOPBACK\}/${LOOPBACK}/ > /tmp/01_docker.tmp; sudo mv -f /tmp/01_docker.tmp "$(DNSMASQ_LOCAL_CONF)"
	@openssl req -x509 -newkey rsa:4096 -keyout conf/certs.d/$(TLD).key -out conf/certs.d/$(TLD).cert -days 365 -nodes -subj "/CN=*.$(TLD)"
	@sudo sh -c "cp -a conf/certs.d $(DOCKER_CONF_FOLDER)"
	@while [ `docker ps 1> /dev/null` ]; do \
		echo "Waiting for Docker..." \
		sleep 2; \
	done;
	@docker run -d --name $(DOCKER_CONTAINER_NAME) --restart always --security-opt apparmor:unconfined -p $(PUBLISH_IP_MASK)53:53/udp -p $(PUBLISH_IP_MASK)53:53 $(PUBLISH_SSH_PORT) -e TOP_LEVEL_DOMAIN=$(TLD) -e HOSTNAME=$(HOSTNAME) --volume /var/run/docker.sock:/var/run/docker.sock $(DOCKER_CONTAINER_TAG) -R
ifeq ($(UNAME), Darwin)
	@sed -i '' 's/\s#bind-interfaces//' $(DNSMASQ_LOCAL_CONF)
	@sed -i '' 's/interface=docker.*//' $(DNSMASQ_LOCAL_CONF)
	@sudo test -e `echo ~root`/.ssh/known_hosts_pre_hud || sudo cp `echo ~root`/.ssh/known_hosts `echo ~root`/.ssh/known_hosts_pre_hud
	@sleep 1 && ssh-keyscan -p $(SSH_PORT) 127.0.0.1 | grep ecdsa-sha2-nistp256 | sudo tee -a `echo ~root`/.ssh/known_hosts
	@echo Starting tunnel from host machine network to docker network
	@sudo make tunnel
endif
	@echo Now all of your containers are reachable using CONTAINER_NAME.$(TLD) inside and outside docker.  E.g.: nc -v $(DOCKER_CONTAINER_NAME).$(TLD) 53

uninstall: welcome ## Remove all files from docker-dns
	@echo "Uninstalling docker dns exposure"
ifneq ($(shell docker images | grep ${DOCKER_CONTAINER_NAME} | wc -l | bc), 0)
	@#docker stop $(DOCKER_CONTAINER_NAME) 2> /dev/null
	@docker rmi $(DOCKER_CONTAINER_NAME) -f 2> /dev/null
endif
	@sudo rm -Rf $(DNSMASQ_LOCAL_CONF)
	@if [ -f "$(DOCKER_CONF_FOLDER)/daemon.json" ]; then sudo cat $(DOCKER_CONF_FOLDER)/daemon.json | jq 'map(del(.bip, .dns)' > /tmp/daemon.docker.json.tmp 2>/dev/null; sudo mv /tmp/daemon.docker.json.tmp $(DOCKER_CONF_FOLDER)/daemon.json > /dev/null; fi
	@grep -v "nameserver ${IP}" ${RESOLVCONF} > /tmp/resolv.conf.tmp ; sudo mv /tmp/resolv.conf.tmp ${RESOLVCONF};
	@if [ -f "/Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist" ]; then rm -f /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist; fi
ifeq ($(UNAME), Darwin)
	@sudo test -e `echo ~root`/.ssh/known_hosts_pre_hud && sudo cp `echo ~root`/.ssh/known_hosts_pre_hud `echo ~root`/.ssh/known_hosts
	@sudo launchctl unload -w /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist 2> /dev/null
endif

show-domain: ## View the docker domain installed
ifeq ('$(docker images | grep $tag)', '')
	@echo "docker-dns not installed! Please install first"
else
	@echo Working domain:
	@docker inspect $(tag) | grep TOP_ | cut -d= -f2 | cut -d\" -f1
endif

help: welcome
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep ^help -v | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
