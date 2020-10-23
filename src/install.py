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


def __macos_setup(tld=config.TOP_LEVEL_DOMAIN):
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


def __debian_setup(tld=config.TOP_LEVEL_DOMAIN):
    output = {
     'DOCKER_CONF_FOLDER': '/etc/docker',
     'DNSMASQ_LOCAL_CONF': '/etc/NetworkManager/dnsmasq.d/01_docker'
    }
    if not os.path.exists(output['DNSMASQ_LOCAL_CONF']):
        output['DNSMASQ_LOCAL_CONF'] = output['DNSMASQ_LOCAL_CONF'].replace('dnsmasq.d', 'conf.d')

    return output


def __redhat_setup(tld=config.TOP_LEVEL_DOMAIN):
    output = {
     'DOCKER_CONF_FOLDER': '/etc/docker'
     'DNSMASQ_LOCAL_CONF': '/etc/NetworkManager/dnsmasq.d/01_docker'
    }
    if not os.path.exists(output['DNSMASQ_LOCAL_CONF']):
        output['DNSMASQ_LOCAL_CONF'] = output['DNSMASQ_LOCAL_CONF'].replace('dnsmasq.d', 'conf.d')

    return output

def __os_setup(tld=config.TOP_LEVEL_DOMAIN):
    if util.on_macos:
        return __macos_setup(tld)

    if util.on_wsl:
        return __debian_setup(tld)

    if util.on_linux:
        if config.HOSTUNAME == 'Ubuntu':
            return __debian_setup(tld)
        else:
            return __redhat_setup(tld)

def __macos_install(tld):
    """
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

    """

def __debian_install(tld):
    True

def __redhat_install(tld):
    True

def __os_install(tld):
    if util.on_macos:
        return __macos_install(tld)

    if util.on_wsl:
        return __debian_install(tld)

    if util.on_linux:
        if config.HOSTUNAME == 'Ubuntu':
            return __debian_install(tld)
        else:
            return __redhat_install(tld)

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
        f'Building and starting container "{tag}:latest"... Please wait')
    docker.build_container(name, tag, tld)
    update_cache()

    # dnsmasq
    if not util.on_macos:
        print("Setting up dnsmasq")

        dnsmasq_local = open(os_config['DNSMASQ_LOCAL_CONF'], 'r').read()
        dnsmasq_local = dnsmasq_local.replace('${IP}', docker.NETWORK_GATEWAY)
        dnsmasq_local = dnsmasq_local.replace('${HOSTNAME}', config.HOSTNAME)
        dnsmasq_local = dnsmasq_local.replace('${LOOPBACK}', network.LOOPBACK_NETWORK)
        json.dump(dnsmasq_local, open(os_config['DNSMASQ_LOCAL_CONF'], 'w'))

    # TLD domain ceriticate
    cert_file=f'conf/certs.d/{tld}.cert'
    key_file=f'conf/certs.d/{tld}.key'
    util.generate_certificate(tld, cert_file=cert_file, key_file=key_file)
    shutil.copy2(cert_file, os_config['DOCKER_CONF_FOLDER'])
    shutil.copy2(key_file, os_config['DOCKER_CONF_FOLDER'])

    __os_install()
    open('.cache/INSTALLED', 'w').write('')


def check_if_installed():
    return os.path.exists('.cache/INSTALLED')
