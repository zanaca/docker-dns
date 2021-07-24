import os
import shutil
import json

import config
import dockerapi as docker
import install
import util

if util.on_macos:
    import OSes.macos as OS

elif util.on_wsl:
    import OSes.windows_wsl2 as OS

elif util.on_linux:
    if config.NAME == 'Ubuntu':
        import OSes.ubuntu as OS
    elif config.NAME.lower() == 'linux mint':
        import OSes.mint as OS


def main(name=config.DOCKER_CONTAINER_NAME, tag=config.DOCKER_CONTAINER_TAG, tld=config.TOP_LEVEL_DOMAIN):
    if not util.check_if_installed():
        print('No installation found')
        return 1

    print('Uninstalling docker dns exposure')
    if docker.check_exists(name):
        print("Removing existing container...")
        docker.purge(name)

    docker_conf_file = f"{install.OS.DOCKER_CONF_FOLDER}/daemon.json"
    if os.path.exists(docker_conf_file):
        shutil.copy2('src/templates/daemon.json', docker_conf_file)
        docker_json = json.loads(open(docker_conf_file, 'r').read())
        docker_json['bip'] = ''
        docker_json['dns'] = []
        json.dump(docker_json, open(docker_conf_file, 'w'))

    resolvconf_head = '/etc/resolvconf/resolv.conf.d/head'
    resolvconf_tail = '/etc/resolvconf/resolv.conf.d/tail'

    try:
        lines = open(resolvconf_head).readlines()
        lines = [l for l in lines if l.startswith('#')]
        open(resolvconf_head, 'w').writelines(lines)
        open(resolvconf_tail, 'w').write('')
    except FileNotFoundError:
        pass

    OS.uninstall(tld)
    return 0
