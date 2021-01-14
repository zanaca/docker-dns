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
    if config.NAME.lower() == 'linux mint':
        import OSes.mint as OS


def main(name=config.DOCKER_CONTAINER_NAME, tag=config.DOCKER_CONTAINER_TAG, tld=config.TOP_LEVEL_DOMAIN):
    if not util.check_if_installed():
        print('No installation found')
        return 1

    print('Uninstalling docker dns exposure')
    if docker.check_exists(name):
        print("Removing existing container...")
        docker.purge(name)

    DOCKER_CONF_FILE = f"{install.OS.DOCKER_CONF_FOLDER}/daemon.json"
    if os.path.exists(DOCKER_CONF_FILE):
        shutil.copy2('src/templates/daemon.json', DOCKER_CONF_FILE)
        docker_json = json.loads(open(DOCKER_CONF_FILE, 'r').read())
        docker_json['bip'] = ''
        docker_json['dns'] = []
        json.dump(docker_json, open(DOCKER_CONF_FILE, 'w'))

    OS.uninstall(tld)
    return 0
