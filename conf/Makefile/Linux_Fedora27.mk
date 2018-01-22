OS_VERSION=Ubuntu17
LOOPBACK := $(shell ifconfig | grep -i LOOPBACK  | head -n1 | cut -d\  -f1 | sed -e 's\#:\#\#')
IP := $(shell ifconfig docker0 | grep "inet " | cut -dt -f2 | cut -d: -f2 | sed -e 's\# \#\#' | cut -d\  -f1)
DOCKER_CONF_FOLDER := /etc/docker
DNSs := $(shell nmcli dev show | grep DNS|  cut -d\: -f2 | sort | uniq | sed s/\ //g | sed ':a;N;$!ba;s/\\\n/","/g');
DNSs := $(shell echo "${DNSs}" | sed s/\ /\",\"/g | sed s/\;//g)
DNSMASQ_LOCAL_CONF := /etc/NetworkManager/dnsmasq.d/01_docker
PUBLISH_IP_MASK = $(IP):
RESOLVCONF := /run/systemd/resolve/stub-resolv.conf

install-dependencies-os:

install-os:

uninstall-os:
	@if [ -d /etc/resolver ] then; \
	grep -v "nameserver ${IP}" /etc/resolver/resolv.conf.d/head > /tmp/resolv.conf.tmp ; sudo mv /tmp/resolv.conf.tmp /etc/resolver/resolv.conf.d/head; \
	fi
	@sudo resolvconf -u
