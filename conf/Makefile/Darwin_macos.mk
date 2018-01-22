OS_VERSION=Macos$(shell sw_vers -productVersion | cut -d. -f1-2)
LOOPBACK := ''
IP := $(shell ifconfig en0 | grep "inet " | cut -d\  -f2)
DOCKER_CONF_FOLDER := $(HOME)/Library/Containers/com.docker.docker/Data/database/com.docker.driver.amd64-linux/etc/docker
DNSs := $(shell scutil --dns | grep nameserver | cut -d: -f2 | sort | uniq | sed s/\ //g | sed ':a;N;$!ba;s/\\\n/","/g');
DNSs := $(shell echo "${DNSs}" | sed s/\ /\",\"/g | sed s/\;//g)
DNSMASQ_LOCAL_CONF := /usr/local/etc/dnsmasq.conf
RESOLVCONF := /etc/resolv.conf


tunnel: ## Creates a tunnel between local machine and docker network - macOS only
	@./macos-tunnel.sh
