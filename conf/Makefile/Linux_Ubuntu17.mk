OS_VERSION=Ubuntu17
LOOPBACK := $(shell ifconfig | grep -i LOOPBACK  | head -n1 | cut -d\  -f1 | sed -e 's\#:\#\#')
IP := $(shell ifconfig ${DOCKER_INTERFACE} | grep "inet " | cut -dt -f2 | cut -d: -f2 | sed -e 's\# \#\#' | cut -d\  -f1)
DOCKER_CONF_FOLDER := /etc/docker
DNSs := $(shell nmcli dev show | grep DNS|  cut -d\: -f2 | sort | uniq | sed s/\ //g | sed ':a;N;$!ba;s/\\\n/","/g');
DNSs := $(shell echo "${DNSs}" | sed s/\ /\",\"/g | sed s/\;//g)
DNSMASQ_LOCAL_CONF := /etc/NetworkManager/dnsmasq.d/01_docker
PUBLISH_IP_MASK = $(IP):
RESOLVCONF := /run/systemd/resolve/stub-resolv.conf
PACKAGE_MANAGER=apt-get

install-dependencies-os:
	@if [ ! -d /etc/resolvconf/resolv.conf.d ]; then sudo mkdir -p /etc/resolvconf/resolv.conf.d; fi
	@if [ ! -f /etc/resolvconf/resolv.conf.d/head ]; then sudo touch /etc/resolvconf/resolv.conf.d/head; fi
	@echo "options timeout:1 #@docker-dns\nnameserver $(IP) #@docker-dns" | sudo tee -a /etc/resolvconf/resolv.conf.d/head;
	@test resolvconf && sudo resolvconf -u

install-os:

uninstall-os:
	@sudo grep -v "@docker-dns" ${RESOLVCONF} > /tmp/resolv.conf.tmp; \
	sudo mv /tmp/resolv.conf.tmp ${RESOLVCONF};

	@if [ -f /etc/resolvconf/resolv.conf.d/head ]; then \
		sudo grep -v "@docker-dns" /etc/resolvconf/resolv.conf.d/head > /tmp/resolv.conf.tmp; \
	fi

