.DEFAULT_GOAL := help
.PHONY: help

tag ?= ns0
tld ?= docker
name ?= $(tag)

UNAME := $(shell uname)
WHO := $(shell whoami)
PWD := $(shell pwd | sed -e 's/\//\\\\\//g')
HOSTNAME := $(shell hostname)

DOCKER_CONTAINER_TAG := $(tag)
DOCKER_CONTAINER_NAME := $(name)
TLD := $(tld)

ifeq ($(UNAME), Darwin)
	IP := $(shell ifconfig en0 | grep "inet " | cut -d\  -f2)
	DOCKER_CONF_FOLDER := ~/Library/Containers/com.docker.docker/Data/database/com.docker.driver.amd64-linux/etc/docker
	DNSs := $(shell scutil --dns | grep nameserver | cut -d: -f2 | sort | uniq | sed s/\ //g | sed ':a;N;$!ba;s/\\\n/","/g');
	DNSs := $(shell echo "${DNSs}" | sed s/\ /\",\"/g | sed s/\;//g)
	DNSMASQ_LOCAL_CONF := /usr/local/etc/dnsmasq.conf
	SSH_PORT = 2200
	PUBLISH_SSH_PORT = -p $(SSH_PORT):22
else
	IP := $(shell ifconfig docker0 | grep "inet " | cut -d\  -f10)
	DOCKER_CONF_FOLDER := /etc/docker
	DNSs := $(shell nmcli dev show | grep DNS|  cut -d\: -f2 | sort | uniq | sed s/\ //g | sed ':a;N;$!ba;s/\\\n/","/g');
	DNSs := $(shell echo "${DNSs}" | sed s/\ /\",\"/g | sed s/\;//g)
	DNSMASQ_LOCAL_CONF := /etc/NetworkManager/dnsmasq.d/01_docker
	PUBLISH_IP_MASK = $(IP):
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
	@docker build . -t $(DOCKER_CONTAINER_TAG):latest

ifeq ($(UNAME), Darwin)
install-dependencies:
	@[ `sudo -n true 2>/dev/null` ]; printf "\033[32mPlease type your sudo password, for network configuration.\033[m\n" && sudo ls > /dev/null
ifeq ($(shell cat /usr/local/etc/dnsmasq.conf 2> /dev/null || echo no_dnsmasq), no_dnsmasq)
	@#sudo brew install dnsmasq
	@mkdir -pv $(brew --prefix)/etc/
	@#sudo sh -c "cp conf/com.zanaca.dockerdns-dnsmasq.plist /Library/LaunchDaemons/"
	@#sudo launchctl load -w /Library/LaunchDaemons/com.zanaca.dockerdns-dnsmasq.plist
endif
	@brew install `cat requirements.apt` -y
	@[ shuttle ] || sudo easy install sshuttle
	@if [ ! -d /etc/resolver ]; then sudo mkdir /etc/resolver; fi
	@echo "nameserver $(IP)" | sudo tee /etc/resolver/$(TLD)
	@sudo sh -c "cat conf/com.zanaca.dockerdns-tunnel.plist | sed s:\{PWD\}:$(PWD):g > /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist"
	@sudo launchctl load -w /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist
	@ssh-keygen -f Dockerfile_id_rsa -P ""


tunnel: ## Creates a tunnel between local machine and docker network - macOS only
	@#ssh -D "*:2201" -f -C -q -N root@127.0.0.1 -p $(SSH_PORT) -i Dockerfile_id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
	@# sshuttle will run  in a daemon, so docker will no be running to discover it network IP
	@sudo sshuttle -r root@127.0.0.1:$(SSH_PORT) 172.17.0.0/24

else
install-dependencies:
	@[ `sudo -n true 2>/dev/null` ]; printf "\033[32mPlease type your sudo password, for network configuration.\033[m\n" && sudo ls > /dev/null
	@sudo apt-get install `cat requirements.apt` -y
ifneq ($(shell grep $(IP) /etc/resolv.conf), nameserver $(IP))
		@echo "nameserver $(IP)" | sudo tee -a /etc/resolv.conf;
		@echo "nameserver $(IP)" | sudo tee -a /etc/resolvconf/resolv.conf.d/head;
endif
	@if [ ! -d /etc/resolver ]; then sudo mkdir /etc/resolver; fi
	@echo "nameserver $(IP)" | sudo tee /etc/resolver/$(TLD)
endif
	@ssh-keygen -f Dockerfile_id_rsa -P ""


install: welcome install-dependencies build-docker-image ## Setup DNS container to resolve ENV.TLD domain inside and outside docker in your machine
	@if [ `docker container inspect $(DOCKER_CONTAINER_NAME) 2> /dev/null | head -n1` = "[" ]; then \
		docker stop $(DOCKER_CONTAINER_NAME) > /dev/null && docker rm $(DOCKER_CONTAINER_NAME) > /dev/null; \
	fi
	@if [ ! -f $(DOCKER_CONF_FOLDER)/daemon.json ]; then sudo sh -c "mkdir -p $(DOCKER_CONF_FOLDER); cp conf/daemon.json.docker $(DOCKER_CONF_FOLDER)/daemon.json";  fi
	@cat $(DOCKER_CONF_FOLDER)/daemon.json | jq '. + {"bip": "${IP}/24", "dns": ["${IP}", "${DNSs}"]}' > /tmp/daemon.docker.json.tmp; sudo mv /tmp/daemon.docker.json.tmp $(DOCKER_CONF_FOLDER)/daemon.json
	@cat conf/dnsmasq.local | sed s/\\$$\{IP\}/${IP}/g | sed s/\\$$\{TLD\}/${TLD}/ | sed s/\\$$\{HOSTNAME\}/${HOSTNAME}/ > /tmp/01_docker.tmp; sudo mv -f /tmp/01_docker.tmp $(DNSMASQ_LOCAL_CONF)
	@sudo sh -c "cp -a conf/certs.d $(DOCKER_CONF_FOLDER)"
	@while [ `docker ps 1> /dev/null` ]; do \
		echo "Waiting for Docker..." \
		sleep 2; \
	done;
	@docker run -d --name $(DOCKER_CONTAINER_NAME) --restart always --security-opt apparmor:unconfined -p $(PUBLISH_IP_MASK)53:53/udp -p $(PUBLISH_IP_MASK)53:53 $(PUBLISH_SSH_PORT) -e TOP_LEVEL_DOMAIN=$(TLD) -e HOSTNAME=$(HOSTNAME) --volume /var/run/docker.sock:/var/run/docker.sock $(DOCKER_CONTAINER_TAG) -R
	@echo Now all of your containers are reachable using CONTAINER_NAME.$(TLD) inside and outside docker. E.g.: ping $(DOCKER_CONTAINER_NAME).$(TLD)
ifeq ($(UNAME), Darwin)
	@cat ~/.ssh/known_hosts | grep 127.0.0.1]:$(SSH_PORT) -v > ~/.ssh/known_hosts_dd && mv ~/.ssh/known_hosts_dd ~/.ssh/known_hosts
	@sleep 1 && ssh-keyscan -p $(SSH_PORT) 127.0.0.1 | grep ecdsa-sha2-nistp256 >> ~/.ssh/known_hosts
	@make tunnel & > /dev/null
endif

uninstall: welcome ## Remove all files from docker-dns
	@echo "Uninstalling docker dns exposure"
	@docker stop $(DOCKER_CONTAINER_NAME)
	@sudo rm -Rf $(DNSMASQ_LOCAL_CONF)
	@cat $(DOCKER_CONF_FOLDER)/daemon.json | jq 'map(del(.bip, .dns)' > /tmp/daemon.docker.json.tmp 2>/dev/null; sudo mv /tmp/daemon.docker.json.tmp $(DOCKER_CONF_FOLDER)/daemon.json
	@if [ `grep ${IP} /etc/resolv.conf` ]; then grep -v "nameserver ${IP}" /etc/resolv.conf > /tmp/resolv.conf.tmp ; sudo mv /tmp/resolv.conf.tmp /tmp/resolv.conf; fi
	@#if [ -f "/Library/LaunchDaemons/com.zanaca.dockerdns-tuntap-up.plist" ]; then rm -f /Library/LaunchAgents/com.zanaca.dockerdns-tuntap-up.plist; fi
	@if [ -f "/Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist" ]; then rm -f /Library/LaunchAgents/com.zanaca.dockerdns-tunnel.plist; fi
ifeq ($(UNAME), Darwin)
	@sudo launchctl load -w /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist
endif

show-domain: ## View the docker domain installed
	@echo Working domain:
	@docker inspect ns0 | grep TOP_ | cut -d= -f2 | cut -d\" -f1

help: welcome
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep ^help -v | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
