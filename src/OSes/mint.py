import os

import config


FLAVOR = 'mint'
DOCKER_CONF_FOLDER = '/etc/docker'
DNSMASQ_LOCAL_CONF = '/etc/NetworkManager/dnsmasq.d/01_docker'
DOCKER_BUILD_TARGET = 'base'

if not os.path.exists(DNSMASQ_LOCAL_CONF):
    DNSMASQ_LOCAL_CONF = DNSMASQ_LOCAL_CONF.replace('dnsmasq.d', 'conf.d')


def setup(tld=config.TOP_LEVEL_DOMAIN):
    return None


def install(tld=config.TOP_LEVEL_DOMAIN):
    return None


def uninstall(tld=config.TOP_LEVEL_DOMAIN):
    if os.path.exists(DNSMASQ_LOCAL_CONF):
        os.unlink(DNSMASQ_LOCAL_CONF)
