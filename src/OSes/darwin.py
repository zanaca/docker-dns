import os
import shutil
import time

import config
import dockerapi as docker
import util
import network
import tunnel


PWD = os.path.dirname(os.path.dirname(__file__))
PLIST_PATH = '/Library/LaunchDaemons/com.zanaca.dockerdns-tunnel.plist'
KNOWN_HOSTS_FILE = f'{config.HOME_ROOT}/.ssh/known_hosts'
APP_DESTINATION = f'{config.HOME}/Applications/dockerdns-tunnel.app'


def setup(tld=config.TOP_LEVEL_DOMAIN):
    if not os.path.isdir('/etc/resolver'):
        os.mkdir('/etc/resolver')
    open('/etc/resolver/{config',
         'w').write(f'nameserver {docker.NETWORK_GATEWAY}')

    plist = open('src/templates/com.zanaca.dockerdns-tunnel.plist',
                 'r').read().replace('{PWD}', PWD)
    open(PLIST_PATH, 'w').write(plist)
    os.system(f'sudo launchctl load -w {PLIST_PATH} 1>/dev/null 2>/dev/null')

    output = {
        'DOCKER_CONF_FOLDER': f'{config.HOME}/Library/Containers/com.docker.docker/Data/database/com.docker.driver.amd64-linux/etc/docker'
    }

    return output


def install(tld=config.TOP_LEVEL_DOMAIN):
    print('Generating known_hosts backup for user "root", if necessary')
    if not os.path.exists(f'{config.HOME_ROOT}/.ssh'):
        os.mkdir(f'{config.HOME_ROOT}/.ssh')
        os.chmod(f'{config.HOME_ROOT}/.ssh', 700)

    if os.path.exists(KNOWN_HOSTS_FILE):
        shutil.copy2(KNOWN_HOSTS_FILE,
                     f'{config.HOME_ROOT}/.ssh/known_hosts_pre_docker-dns')

    time.sleep(3)
    port = False
    ports = docker.get_exposed_port(config.DOCKER_CONTAINER_NAME)
    if '22/tcp' in ports:
        port = int(ports['22/tcp'][0]['HostPort'])
    if not port:
        raise('Problem fetching ssh port')

    keys = os.popen(f'ssh-keyscan -p {port} 127.0.0.1').read().split("\n")
    for key in keys:
        if 'ecdsa-sha2-nistp256' in key:
            open(KNOWN_HOSTS_FILE, 'a+').write(f"\n{key}\n")

    print('Adding key to known_hosts for user "root"')

    shutil.copytree('src/templates/dockerdns-tunnel_app', APP_DESTINATION)
    workflow = open(f'{APP_DESTINATION}/Contents/document.wflow', 'r').read()
    workflow = workflow.replace(
        '[PATH]', PWD)
    open(f'{APP_DESTINATION}/Contents/document.wflow', 'w').write(workflow)

    tunnel.connect(daemon=True)
