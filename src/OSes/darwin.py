import os

import config
import dockerapi as docker
import util
import network
import tunnel


def setup(tld=config.TOP_LEVEL_DOMAIN):
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



def install(tld=config.TOP_LEVEL_DOMAIN):
    """
	@sed -i '' 's/\s#bind-interfaces//' $(DNSMASQ_LOCAL_CONF)
	@sed -i '' 's/interface=docker.*//' $(DNSMASQ_LOCAL_CONF)
	@echo Generating known_hosts backup for user "root", if necessary
	@sudo test -d $(HOME_ROOT)/.ssh || (sudo mkdir $(HOME_ROOT)/.ssh; sudo chmod 700 $(HOME_ROOT)/.ssh)
	@if sudo sh -c "[ -e $(HOME_ROOT)/.ssh/known_hosts ]"; then sudo cp $(HOME_ROOT)/.ssh/known_hosts $(HOME_ROOT)/.ssh/known_hosts_pre_hud; fi
	@echo Adding key to known_hosts for user "root"
	@sleep 3 && ssh-keyscan -p `docker port $(DOCKER_CONTAINER_NAME) | grep 22/ | cut -d: -f2` 127.0.0.1 | grep ecdsa-sha2-nistp256 | sudo tee -a $(HOME_ROOT)/.ssh/known_hosts

    """
    print('Adding key to known_hosts for user "root"')

    # copy macos Application
    tunnel.connect(daemon=True)
