import os
import time
import shutil
import json

import config
import dockerapi as docker
import util
import network

RESOLVCONF = '/etc/resolv.conf'

def update_cache():
    util.write_cache('tld', config.TOP_LEVEL_DOMAIN)
    util.write_cache('tag', config.DOCKER_CONTAINER_TAG)
    util.write_cache('name', config.DOCKER_CONTAINER_NAME)


def __macos(tld=config.TOP_LEVEL_DOMAIN):
    PLIST_PATH = '/Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist'

    if not os.path.isdir('/etc/resolver'):
        os.mkdir('/etc/resolver')
    open('/etc/resolver/{config', 'w').write(f'nameserver {docker.NETWORK_GATEWAY}')

    plist = open('src/templates/com.zanaca.dockerdns-tunnel.plist', 'r').read().replace('{PWD}', os.path.dirname(__file__))
    open(PLIST_PATH, 'w').write(plist)
    os.system(f'sudo launchctl load -w {PLIST_PATH} 1>/dev/null 2>/dev/null')

    output = {
     'DOCKER_CONF_FOLDER': f'{config.HOME}/Library/Containers/com.docker.docker/Data/database/com.docker.driver.amd64-linux/etc/docker'
    }

    return output


def __debian(tld=config.TOP_LEVEL_DOMAIN):
    output = {
     'DOCKER_CONF_FOLDER': '/etc/docker'
    }

    return output


def __redhat(tld=config.TOP_LEVEL_DOMAIN):
    output = {
     'DOCKER_CONF_FOLDER': '/etc/docker'
    }

    return output

def __os_setup(tld=config.TOP_LEVEL_DOMAIN):
    if util.on_macos:
        return __macos(tld)

    if util.on_wsl:
        return __debian(tld)

    if util.on_linux:
        if config.HOSTUNAME == 'Ubuntu':
            return __debian(tld)
        else:
            return __redhat(tld)


def main(name=config.DOCKER_CONTAINER_NAME, tag=config.DOCKER_CONTAINER_TAG, tld=config.TOP_LEVEL_DOMAIN):
    if os.path.exists('.cache/INSTALLED'):
        os.unlink('.cache/INSTALLED')

    # update resolv.conf
    RESOLVCONF_DATA = open(RESOLVCONF, 'r').read()
    if '#@docker-dns' not in RESOLVCONF_DATA:
        RESOLVCONF_DATA = f"options timeout:1 #@docker-dns\nnameserver {docker.NETWORK_GATEWAY} #@docker-dns\n{RESOLVCONF_DATA}"
        open(RESOLVCONF, 'w').write(RESOLVCONF_DATA)

    os_config = __os_setup(tld)
    DOCKER_CONF_FILE = f"{os_config['DOCKER_CONF_FOLDER']}/daemon.json"
    if not os.path.exists(DOCKER_CONF_FILE) or os.stat(DOCKER_CONF_FILE).st_size==0 :
        if not os.path.isdir(os_config['DOCKER_CONF_FOLDER']):
            os.mkdir(os_config['DOCKER_CONF_FOLDER'])
        shutil.copy2('src/templates/daemon.json', DOCKER_CONF_FILE)

    docker_json = json.loads(open(DOCKER_CONF_FILE, 'r').read())
    docker_json['bip'] = docker.NETWORK_SUBNET
    docker_json['dns'] = list(set([docker.NETWORK_GATEWAY] + network.get_dns_servers()))
    json.dump(docker_json, open(DOCKER_CONF_FILE, 'w'))

    # docker
    if docker.check_exists(name):
        print("Stopping existing container...")
        docker.purge(name)
        time.sleep(2)

    print(
        f'Building and starting container "{tag}:latest"')
    docker.build_container(name, tag, tld)
    update_cache()

    """
    @echo Setting up dnsmasq
	@echo ${DNSMASQ_LOCAL_CONF}
	@cat conf/dnsmasq.local | sed s/\\$$\{IP\}/${IP}/g | sed s/\\$$\{TLD\}/${TLD}/ | sed s/\\$$\{HOSTNAME\}/${HOSTNAME}/ | sed s/\\$$\{LOOPBACK\}/${LOOPBACK}/ > /tmp/01_docker.tmp
	@if [ -f "${DNSMASQ_LOCAL_CONF}" ]; then \
		sudo mv -f /tmp/01_docker.tmp "$(DNSMASQ_LOCAL_CONF)"; \
	else \
		sudo mv -f /tmp/01_docker.tmp "$(NETWORKMANAGER_CONF_D)"; \
	fi
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
    """
    open('.cache/INSTALLED', 'w').write('')


def check_if_installed():
    return os.path.exists('.cache/INSTALLED')
