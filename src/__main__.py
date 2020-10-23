#!/usr/bin/env python3

#import socket
#import struct
#import fcntl
import sys
import os
from argparse import ArgumentParser, Action, ArgumentTypeError as Fatal

import config
import util
import tunnel
import show_domain
import status
import install
import uninstall

#SIOCSIFADDR = 0x8916
#sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)


parser = ArgumentParser(
    prog=config.APP,
    usage="%(prog)s COMMAND [-t tag] [-n name] [-d tld] -h",
    fromfile_prefix_chars="@"
)


parser.add_argument(
    "COMMAND",
    choices=["install", "uninstall", "show-domain", "status", "tunnel"],
    default='status',
    # required=True,
    help="""
    command to be executed
    """
)

parser.add_argument(
    "-t", "--tag",
    default=config.DOCKER_CONTAINER_TAG,
    help="""
    tag of Docker container
    """
)

parser.add_argument(
    "-n", "--name",
    default=config.DOCKER_CONTAINER_NAME,
    help="""
    name of Docker container
    """
)

parser.add_argument(
    "-d", "--tld",
    default=config.TOP_LEVEL_DOMAIN,
    help="""
    domain that will be used when resolving containers name. Example, if you have an container running with name "memcached", it will be availble resolving "memcached.docker" if your TLD is "docker"
    """
)

x = 2
if __name__ == '__main__':
    if not util.is_supported():
        print('Sorry, your OS is not supported.')
        sys.exit(1)

    opt = parser.parse_args()

    try:
        if opt.COMMAND == 'show-domain':
            show_domain.main()

        elif opt.COMMAND == 'install':
            install.main(name=opt.name, tag=opt.tag, tld=opt.tld)
            status.main()

        elif opt.COMMAND == 'uninstall':
            uninstall.main()

        elif opt.COMMAND == 'tunnel':
            tunnel.connect()

        else:
            status.main()

    except Fatal as e:
        print(f'fatal: {e}')
        sys.exit(1)
    except KeyboardInterrupt:
        print('Keyboard interrupt: exiting.')
        sys.exit(0)
