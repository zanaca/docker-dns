import os
import subprocess

import config
import dockerapi as docker
import install
import util

if util.on_macos:
    import OSes.macos as OS

elif util.on_wsl:
    import OSes.windows_wsl2 as OS

elif util.on_linux:
    if config.NAME == 'ubuntu':
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

    docker_daemon_file = f"{install.OS.DOCKER_CONF_FOLDER}/daemon.json"
    if os.path.exists(docker_daemon_file):
        os.remove(docker_daemon_file)

    resolvconf_head = '/etc/resolvconf/resolv.conf.d/head'
    try:
        lines = open(resolvconf_head).readlines()
        original_lines = [line for line in lines if not line.endswith('docker-dns\n')]
        open(resolvconf_head, 'w').writelines(original_lines)
        subprocess.run(['resolvconf', '-u'])
    except FileNotFoundError:
        pass

    OS.uninstall(tld)
    return 0
