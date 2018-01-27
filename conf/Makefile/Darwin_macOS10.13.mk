OS_VERSION=Macos$(shell sw_vers -productVersion | cut -d. -f1-2)
LOOPBACK := ''
IP=172.17.0.1
DOCKER_CONF_FOLDER := $(HOME)/Library/Containers/com.docker.docker/Data/database/com.docker.driver.amd64-linux/etc/docker
DNSs := $(shell scutil --dns | grep nameserver | cut -d: -f2 | sort | uniq | sed s/\ //g | sed ':a;N;$!ba;s/\\\n/","/g');
DNSs := $(shell echo "${DNSs}" | sed s/\ /\",\"/g | sed s/\;//g)
DNSMASQ_LOCAL_CONF := /usr/local/etc/dnsmasq.conf
RESOLVCONF := /etc/resolv.conf


install-dependencies-macos:
	@test -z `sudo -n test -d ~root 2> /dev/null || echo 1` ||  printf "\033[32mPlease type your sudo password, for network configuration.\033[m\n" && sudo true > /dev/null
ifeq ($(shell cat /usr/local/etc/dnsmasq.conf 2> /dev/null || echo no_dnsmasq), no_dnsmasq)
	@#sudo brew install dnsmasq
	@mkdir -pv $(brew --prefix)/etc/
	@#sudo sh -c "cp conf/com.zanaca.dockerdns-dnsmasq.plist /Library/LaunchDaemons/"
	@#sudo launchctl load -w /Library/LaunchDaemons/com.zanaca.dockerdns-dnsmasq.plist
endif
	@test jq || brew install `cat requirements.apt | grep net-tools -v` -y 1> /dev/null 1> /dev/null
	@which sshuttle || sudo easy_install sshuttle
	@if [ ! -d /etc/resolver ]; then \
		sudo mkdir /etc/resolver; \
	fi
	@sudo sh -c "rm -f /etc/resolver/$(TLD)";
	@echo "nameserver $(IP)" | sudo tee /etc/resolver/$(TLD);
	@sudo sh -c "cat conf/com.zanaca.dockerdns-tunnel.plist | sed s:\{PWD\}:$(PWD):g > /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist"
	@sudo sh -c "cat conf/com.zanaca.dockerdns-activeen.plist | sed s:\{PWD\}:$(PWD):g | sed s:\{TLD\}:$(TLD):g > /Library/LaunchDaemons/com.zanaca.dockerdns-activeen.plist"
	@echo Loading tunnel service
	@sudo launchctl load -w /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist 1>/dev/null 2>/dev/null
	@echo Loading active interface service
	@sudo launchctl load -w /Library/LaunchDaemons/com.zanaca.dockerdns-activeen.plist 1>/dev/null 2>/dev/null



tunnel: ## Creates a tunnel between local machine and docker network - macOS only
	@./macos-tunnel.sh

install-os:
	@sed -i '' 's/\s#bind-interfaces//' $(DNSMASQ_LOCAL_CONF)
	@sed -i '' 's/interface=docker.*//' $(DNSMASQ_LOCAL_CONF)
	@echo Generating known_hosts backup for user "root", if necessary
	@sudo test -d $(HOME_ROOT)/.ssh || (sudo mkdir $(HOME_ROOT)/.ssh; sudo chmod 700 $(HOME_ROOT)/.ssh)
	@if sudo sh -c "[ -e $(HOME_ROOT)/.ssh/known_hosts ]"; then sudo cp $(HOME_ROOT)/.ssh/known_hosts $(HOME_ROOT)/.ssh/known_hosts_pre_hud; fi
	@echo Adding key to known_hosts for user "root"
	@sleep 3 && ssh-keyscan -p `docker port $(DOCKER_CONTAINER_NAME) | grep 22/ | cut -d: -f2` 127.0.0.1 | grep ecdsa-sha2-nistp256 | sudo tee -a $(HOME_ROOT)/.ssh/known_hosts
	@echo Starting tunnel from host machine network to docker network
	@$(shell test -f macos-tunnel.sh && sudo rm macos-tunnel.sh 1> /dev/null 2> /dev/null)
	@cat conf/macos-tunnel.sh.tpl | sed s:\{DOCKER_CONTAINER_NAME\}:$(DOCKER_CONTAINER_NAME):g > macos-tunnel.sh;
	@sudo chmod +x macos-tunnel.sh
	@sudo make tunnel &


uninstall-os:
	@sudo sh -c "rm -f /etc/resolver/$(TLD)";
	@if sudo sh -c "[ -e $(HOME_ROOT)/.ssh/known_hosts_pre_hud ]"; then sudo cp `echo ~root`/.ssh/known_hosts_pre_hud `echo ~root`/.ssh/known_hosts; fi
	@echo Unloading tunnel service
	@sudo launchctl unload -w /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist 2> /dev/null
	@sudo launchctl unload -w /Library/LaunchDaemons/com.zanaca.dockerdns-activeen.plist 2> /dev/null
	@echo Deleting tunnel service
	@test -e /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist && sudo rm -f /Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist
	@test -e /Library/LaunchDaemons/com.zanaca.dockerdns-activeen.plist && sudo rm -f /Library/LaunchDaemons/com.zanaca.dockerdns-activeen.plist
	@echo Removing certifiactes for $(TLD) from $(DOCKER_CONF_FOLDER)
	@sudo sh -c "rm $(DOCKER_CONF_FOLDER)/$(TLD).* 1> /dev/null 2> /dev/null"
	@[[ -f /tmp/sshuttle.pid ]] && kill $(shell cat /tmp/sshuttle.pid)
