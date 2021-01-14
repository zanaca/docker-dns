import os
import time
import shutil
import simplejson
import sys

import config
import dockerapi as docker
import util
import network

if util.on_macos:
    import OSes.macos as OS

elif util.on_wsl:
    import OSes.windows_wsl2 as OS

elif util.on_linux:
    if config.NAME == 'Ubuntu':
        import OSes.ubuntu as OS
    if config.NAME.lower() == 'linux mint':
        import OSes.mint as OS

RESOLVCONF = '/etc/resolv.conf'


def update_cache():
    util.write_cache('tld', config.TOP_LEVEL_DOMAIN)
    util.write_cache('tag', config.DOCKER_CONTAINER_TAG)
    util.write_cache('name', config.DOCKER_CONTAINER_NAME)


def main(name=config.DOCKER_CONTAINER_NAME, tag=config.DOCKER_CONTAINER_TAG, tld=config.TOP_LEVEL_DOMAIN):
    if not util.is_os_supported(OS.FLAVOR):
        return 1

    if os.path.exists('.cache/INSTALLED'):
        os.unlink('.cache/INSTALLED')

    # update resolv.conf
    if not hasattr(OS, 'DISABLE_MAIN_RESOLVCONF_ROUTINE'):
        if not os.path.exists(RESOLVCONF):
            open(RESOLVCONF, 'w').write('nameserver 1.1.1.1')

        dns = docker.NETWORK_GATEWAY
        try:
            dns = OS.DNS
        except:
            # no DNS
            pass

        RESOLVCONF_DATA = open(RESOLVCONF, 'r').read()
        if '#@docker-dns' not in RESOLVCONF_DATA:
            RESOLVCONF_DATA = f"options timeout:1 #@docker-dns\nnameserver {dns} #@docker-dns\n{RESOLVCONF_DATA}"
            open(RESOLVCONF, 'w').write(RESOLVCONF_DATA)

    # docker
    DOCKER_CONF_FILE = f"{OS.DOCKER_CONF_FOLDER}/daemon.json"
    if not os.path.exists(DOCKER_CONF_FILE) or os.stat(DOCKER_CONF_FILE).st_size == 0:
        if not os.path.isdir(OS.DOCKER_CONF_FOLDER):
            os.mkdir(OS.DOCKER_CONF_FOLDER)
        shutil.copy2('src/templates/daemon.json', DOCKER_CONF_FILE)

    docker_json = simplejson.loads(open(DOCKER_CONF_FILE, 'r').read())
    docker_json['bip'] = docker.NETWORK_SUBNET
    docker_json['dns'] = list(
        set([docker.NETWORK_GATEWAY] + network.get_dns_servers()))
    with open(DOCKER_CONF_FILE, 'w') as daemon_file:
    	daemon_file.write(simplejson.dumps(docker_json, indent=4, sort_keys=True))

    if docker.check_exists(name):
        print("Stopping existing container...")
        docker.purge(name)
        time.sleep(2)

    print(
        f'Building and running container "{tag}:latest"... Please wait')
    docker.build_container(
        name, tag, tld, bind_port_ip=util.on_linux and not util.on_wsl, target=OS.DOCKER_BUILD_TARGET)
    update_cache()

    # TLD domain ceriticate
    cert_file = f'certs.d/tld/{tld}.cert'
    key_file = f'certs.d/tld/{tld}.key'
    util.generate_certificate(tld, cert_file=cert_file, key_file=key_file)
    shutil.copy2(cert_file, OS.DOCKER_CONF_FOLDER)
    shutil.copy2(key_file, OS.DOCKER_CONF_FOLDER)

    original_arg = sys.argv
    install_status = OS.install(tld)
    if install_status and util.is_tunnel_needed():
        original_arg[1] = 'tunnel'
        original_arg.append('&')
        os.system(' '.join(original_arg))

    open('.cache/INSTALLED', 'w').write('')
    return 0
