DEBUG_COLOR=\033[0;37m
DNSMASQ_LOCAL_CONF:=/etc/NetworkManager/dnsmasq.d/01_docker
NETWORKMANAGER_CONF_D:=/etc/NetworkManager/conf.d/01_docker
DOCKER_CONF_FOLDER:=/etc/docker
INFO_COLOR=\033[0;32m
NO_COLOR=\033[0m
OS_VERSION=Ubuntu20
PACKAGE_MANAGER=apt
RESOLVCONF_D=/etc/resolvconf/resolv.conf.d
WARNING_COLOR=\033[1;33m

DNSs:=$(shell echo "${DNSs}" | sed s/\ /\",\"/g | sed s/\;//g)
DNSs:=$(shell nmcli dev show | grep DNS|  cut -d\: -f2 | sort | uniq | sed s/\ //g | sed ':a;N;$!ba;s/\\\n/","/g');
IP:=$(shell ifconfig ${DOCKER_INTERFACE} | grep "inet " | cut -dt -f2 | cut -d: -f2 | sed -e 's\# \#\#' | cut -d\  -f1)
LOOPBACK:=$(shell ifconfig | grep -i LOOPBACK  | head -n1 | cut -d\  -f1 | sed -e 's\#:\#\#')
PUBLISH_IP_MASK = $(IP):
RESOLVCONF_HEAD=${RESOLVCONF_D}/head
RESOLVCONF:=$(shell readlink -f /etc/resolv.conf)

create-resolvconf-head:
	@-sudo mkdir -p ${RESOLVCONF_D}
	@if [ ! -f "${RESOLVCONF_HEAD}" ]; then \
		echo "${WARNING_COLOR}Creating resolvconf head file${NO_COLOR}"; \
		sudo touch "${RESOLVCONF_HEAD}"; \
		echo "${DEBUG_COLOR}create-resolvconf-head done${NO_COLOR}"; \
	fi
	@echo "${DEBUG_COLOR}create-resolvconf-head done${NO_COLOR}"

add-entries-resolvconf-head:
	@echo "${WARNING_COLOR}Adding entries to resolvconf head${NO_COLOR}"
	@echo "options timeout:1 #@docker-dns\nnameserver $(IP) #@docker-dns" | sudo tee -a ${RESOLVCONF_HEAD}
	@echo "${DEBUG_COLOR}add-entries-resolvconf-head done${NO_COLOR}"

clear-resolvconf:
ifneq ($(grep -c "docker-dns" ${RESOLVCONF_HEAD}),0)
	@echo "${WARNING_COLOR}Removing old docker-dns entries in resolvconf${NO_COLOR}"
	@grep -v "@docker-dns" ${RESOLVCONF_HEAD} | sudo tee ${RESOLVCONF_HEAD}
else
	@echo "${INFO_COLOR}Not found docker-dns entries in resolvconf${NO_COLOR}"
endif
	@echo "${DEBUG_COLOR}clear-resolvconf done${NO_COLOR}"

print-resolvconf:
	@echo "${INFO_COLOR}"
	@cat ${RESOLVCONF}
	@echo "${NO_COLOR}"
	@echo "${DEBUG_COLOR}print-resolvconf done${NO_COLOR}"

resolvconf-update:
	@echo "${WARNING_COLOR}Running resolvconf update${NO_COLOR}"
	@sudo resolvconf -u
	@echo "${DEBUG_COLOR}resolvconf-update done${NO_COLOR}"

install-dependencies-os: create-resolvconf-head clear-resolvconf add-entries-resolvconf-head resolvconf-update print-resolvconf
	@echo "${DEBUG_COLOR}install-dependencies-os done${NO_COLOR}"

install-os:

uninstall-os: clear-resolvconf resolvconf-update print-resolvconf
	@-sudo rm ${DNSMASQ_LOCAL_CONF} ${NETWORKMANAGER_CONF_D}
	@echo "${DEBUG_COLOR}uninstall-os done${NO_COLOR}"
