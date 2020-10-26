import os
import shutil
import time

import config
import dockerapi as docker
import util
import network
import tunnel

DOCKER_CONF_FOLDER = '/etc/docker'
DNSMASQ_LOCAL_CONF = '/etc/NetworkManager/dnsmasq.d/01_docker'
KNOWN_HOSTS_FILE = f'{config.HOME_ROOT}/.ssh/known_hosts'
WSL_CONF = '/etc/wsl.conf'
DNS = '127.0.0.1'

if not os.path.exists(DNSMASQ_LOCAL_CONF):
    DNSMASQ_LOCAL_CONF = DNSMASQ_LOCAL_CONF.replace('dnsmasq.d', 'conf.d')


def setup(tld=config.TOP_LEVEL_DOMAIN):
    if not os.path.isdir('/etc/resolver'):
        os.mkdir('/etc/resolver')
    open(f'/etc/resolver/{tld}',
         'w').write(f'nameserver 127.0.0.1')

    #ini = ''
    # if os.path.exists(WSL_CONF):
    #    ini = open(WSL_CONF, 'r').read()

    # if '[network]' not in ini:
    #    ini += "\n[network]\ngenerateResolvConf = false\n"
    # else:
    #    if 'generateResolvConf' not in ini:
    #        ini = ini.replace('[network]', "[network]\ngenerateResolvConf = false\n")
    #    else:
    #        ini = ini.split("\n")
    #        i = 0
    #        for line in ini:
    #            if 'generateResolvConf' in line:
    #                ini[i] = "generateResolvConf = false\n"
    #                break
    #            i += 1
    #        ini = "\n".join(ini)
    #open(WSL_CONF, 'w').write(ini)

    return True


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

    os.system(
        f'ssh-keyscan -H -t ecdsa-sha2-nistp256 -p {port} 127.0.0.1 2> /dev/null >> {KNOWN_HOSTS_FILE}')

    return True


def uninstall(tld=config.TOP_LEVEL_DOMAIN):
    if os.path.exists(f'/etc/resolver/{tld}'):
        print('Removing resolver file')
        os.unlink(f'/etc/resolver/{tld}')

    ini = open(WSL_CONF, 'r').read()
    ini = ini.replace('ngenerateResolvConf = false',
                      'ngenerateResolvConf = true')
    open(WSL_CONF, 'w').write(ini)

    if os.path.exists(DNSMASQ_LOCAL_CONF):
        os.unlink(DNSMASQ_LOCAL_CONF)

    if os.path.exists(f'{config.HOME_ROOT}/.ssh/known_hosts_pre_docker-dns'):
        print('Removing kwown_hosts backup')
        os.unlink(f'{config.HOME_ROOT}/.ssh/known_hosts_pre_docker-dns')
