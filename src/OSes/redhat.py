import os

import config
import dockerapi as docker
import util
import network
import tunnel


def setup(tld=config.TOP_LEVEL_DOMAIN):
    output = {
        'DOCKER_CONF_FOLDER': '/etc/docker',
        'DNSMASQ_LOCAL_CONF': '/etc/NetworkManager/dnsmasq.d/01_docker'
    }
    if not os.path.exists(output['DNSMASQ_LOCAL_CONF']):
        output['DNSMASQ_LOCAL_CONF'] = output['DNSMASQ_LOCAL_CONF'].replace(
            'dnsmasq.d', 'conf.d')

    return output


def install(tld=config.TOP_LEVEL_DOMAIN):
    True
