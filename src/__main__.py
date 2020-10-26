#!/usr/bin/env python3

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



parser = ArgumentParser(
    prog=config.APP,
    usage="%(prog)s COMMAND [-t tag] [-n name] [-d tld] -h",
    fromfile_prefix_chars="@"
)

parser.add_argument(
    "COMMAND",
    choices=["install", "uninstall", "show-domain", "status", "tunnel"],
    default='status',
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

def root_check():
    if not util.check_if_root():
        print("You need to have root privileges to run this script.\nPlease try again, this time using 'sudo'. Exiting.")
        sys.exit(1)


def run():
    if not util.is_supported():
        print('Sorry, your OS is not supported.')
        return 1

    opt = parser.parse_args()

    try:
        if opt.COMMAND == 'show-domain':
            show_domain.main()

        elif opt.COMMAND == 'install':
            root_check()
            status = install.main(name=opt.name, tag=opt.tag, tld=opt.tld)
            if status == 0:
                status.main()
                return 0
            return 1

        elif opt.COMMAND == 'uninstall':
            root_check()
            uninstall.main()

        elif opt.COMMAND == 'tunnel':
            root_check()
            tunnel.connect()

        else:
            status.main()
        return 0

    except Fatal as e:
        print(f'fatal: {e}')
        return 1
    except KeyboardInterrupt:
        print('Keyboard interrupt: exiting.')
        return 1

if __name__ == '__main__':
    sys.exit(run())