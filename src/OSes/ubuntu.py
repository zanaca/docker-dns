import os

import config


FLAVOR = 'ubuntu'
DOCKER_CONF_FOLDER = '/etc/docker'
DNSMASQ_LOCAL_CONF = '/etc/NetworkManager/dnsmasq.d/01_docker'
DOCKER_BUILD_TARGET = 'base'
RESOLVCONF_HEAD = '/etc/resolvconf/resolv.conf.d/head'


if not os.path.exists(DNSMASQ_LOCAL_CONF):
    DNSMASQ_LOCAL_CONF = DNSMASQ_LOCAL_CONF.replace('dnsmasq.d', 'conf.d')


def setup(tld=config.TOP_LEVEL_DOMAIN):
    return None


def install(tld=config.TOP_LEVEL_DOMAIN):
    return None


def uninstall(tld=config.TOP_LEVEL_DOMAIN):
    if os.path.exists(DNSMASQ_LOCAL_CONF):
        os.unlink(DNSMASQ_LOCAL_CONF)

    try:
        lines = open(RESOLVCONF_HEAD).readlines()
        lines = [l for l in lines if l.startswith('#')]
        open(RESOLVCONF_HEAD).writelines(lines)
    except FileNotFoundError:
        pass
