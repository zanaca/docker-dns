import os
import time

import config
import dockerapi as docker
import util


def update_cache():
    util.write_cache('tld', config.TOP_LEVEL_DOMAIN)
    util.write_cache('tag', config.DOCKER_CONTAINER_TAG)
    util.write_cache('name', config.DOCKER_CONTAINER_NAME)


def main(name=config.DOCKER_CONTAINER_NAME, tag=config.DOCKER_CONTAINER_TAG, tld=config.TOP_LEVEL_DOMAIN):
    if os.path.exists('.cache/INSTALLED'):
        os.unlink('.cache/INSTALLED')
    if docker.check_exists(name):
        print("Stopping existing instance...")
        docker.purge(name)
        time.sleep(2)

    print(
        f'Building and starting container "{tag}:latest"')
    docker.build_container(name, tag, tld)
    update_cache()
    print('built')
    print('WIP')
    open('.cache/INSTALLED', 'w').write('')


def check_if_installed():
    return os.path.exists('.cache/INSTALLED')
