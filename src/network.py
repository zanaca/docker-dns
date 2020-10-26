import socket
import netifaces
import dns.resolver

import config


LOOPBACK_NETWORK_NAME = netifaces.interfaces()[0]


def is_valid_ipv4_address(address):
    try:
        socket.inet_pton(socket.AF_INET, address)
    except AttributeError:  # no inet_pton here, sorry
        try:
            socket.inet_aton(address)
        except socket.error:
            return False
        return address.count('.') == 3
    except socket.error:  # not a valid address
        return False

    return True


def get_dns_servers():
    return dns.resolver.Resolver().nameservers


def is_resolving_tld(tld = config.TOP_LEVEL_DOMAIN):
    try:
        return socket.gethostbyname_ex(tld)
    except:
        return False