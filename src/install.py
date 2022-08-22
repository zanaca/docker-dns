import json
import os
import shutil
import time

import config
import dockerapi as docker
import network
import util

if util.on_macos:
    import OSes.macos as OS

elif util.on_wsl:
    import OSes.windows_wsl2 as OS

elif util.on_linux:
    if config.NAME == 'ubuntu':
        import OSes.ubuntu as OS
    elif config.NAME == 'linux mint':
        import OSes.mint as OS


def update_cache():
    util.write_cache('tld', config.TOP_LEVEL_DOMAIN)
    util.write_cache('tag', config.DOCKER_CONTAINER_TAG)
    util.write_cache('name', config.DOCKER_CONTAINER_NAME)


def main(name=config.DOCKER_CONTAINER_NAME, tag=config.DOCKER_CONTAINER_TAG, tld=config.TOP_LEVEL_DOMAIN):
    if not util.is_os_supported(OS.FLAVOR):
        return 1

    # docker
    docker_conf_file = f"{OS.DOCKER_CONF_FOLDER}/daemon.json"
    if not os.path.exists(docker_conf_file) or os.stat(docker_conf_file).st_size == 0:
        if not os.path.isdir(OS.DOCKER_CONF_FOLDER):
            os.mkdir(OS.DOCKER_CONF_FOLDER)
        shutil.copy2('src/templates/daemon.json', docker_conf_file)

    docker_json = json.loads(open(docker_conf_file, 'r').read())
    docker_json['bip'] = docker.DAEMON_BIP
    docker_json['dns'] = list(set([docker.NETWORK_GATEWAY] + network.get_dns_servers()))
    with open(docker_conf_file, 'w') as daemon_file:
        daemon_file.write(json.dumps(docker_json, indent=4, sort_keys=True))

    if docker.check_exists(name):
        print("Stopping existing container...")
        docker.purge(name)
        time.sleep(2)

    print(f'Building and running container "{tag}:latest"... Please wait')
    docker.build_container(
        name, tag, tld, bind_port_ip=util.on_linux and not util.on_wsl, target=OS.DOCKER_BUILD_TARGET)
    update_cache()

    # TLD domain certificate
    cert_file = f'certs.d/tld/{tld}.cert'
    key_file = f'certs.d/tld/{tld}.key'
    util.generate_certificate(tld, cert_file=cert_file, key_file=key_file)
    shutil.copy2(cert_file, OS.DOCKER_CONF_FOLDER)
    shutil.copy2(key_file, OS.DOCKER_CONF_FOLDER)

    setup_status = OS.setup(tld)
    if setup_status:
        return setup_status

    install_status = OS.install(tld)
    if install_status:
        return install_status

    util.set_installed()
    return 0
