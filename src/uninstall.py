import os
import shutil
import json
import sys

import config
import dockerapi as docker
import install
import util

if util.on_macos:
    import OSes.macos as OS

elif util.on_wsl:
    import OSes.wsl as OS

elif util.on_linux:
    if config.NAME == 'Ubuntu':
        import OSes.ubuntu as OS
    # else:
    #    import OSes.debian as OS


def main(name=config.DOCKER_CONTAINER_NAME, tag=config.DOCKER_CONTAINER_TAG, tld=config.TOP_LEVEL_DOMAIN):
    if not util.check_if_installed():
        print('No installation found')
        sys.exit(1)

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
