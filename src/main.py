#!/usr/bin/env python3


import os
import getopt
import sys
import util
import dockerdns

APP = os.path.basename(__file__)

SUPPORTED_COMMANDS = ['install', 'uninstall', 'show-domain']
if True or util.is_tunnel_needed():
    SUPPORTED_COMMANDS.append('tunnel')


def help(error):
    if error:
        print("%s\n" % error)

    tunnel_help = " tunnel       Create a tunnel from your machine to docker virtualized containers" if util.is_tunnel_needed() else ""

    print(f"""Docker DNS
Enables container name resolution inside and outside docker

Usage: {APP} COMMAND [OPTIONS]

Commands:
 install      Setup DNS container to resolve ENV.TLD domain inside and outside docker in your machine
 uninstall    Remove all files from docker-dns from you system
 show-domain  View the docker domain installed
{tunnel_help}

Options:
 -t or --tag        Tag of Docker container
 -n or --name       Name of Docker container
 -d or --tld        Domain that will be used when resolving containers name. Example, if you have an container running with name "memcached", it will be availble resolving "memcached.docker" if your TLD is "docker"
""")
    sys.exit(1 if error else 0)


if __name__ == '__main__':
    try:
        opts, args = getopt.getopt(sys.argv[1:], "ht:n:d:", [
                                   "tag=", "name=", "tld="])

    except getopt.GetoptError as e:
        help(e)

    for opt, arg in opts:
        if opt == '-h':
            help()

        if opt in ("-t", "--tag"):
            docker_container_tag = arg

        if opt in ("-n", "--name"):
            docker_container_name = arg

        if opt in ("-d", "--tld"):
            top_level_domain = arg

    if len(args) != 1:
        help('Expected 1 command.')

    args_check = list(
        set(args) - set(SUPPORTED_COMMANDS))
    if len(args_check) > 0:
        help(f'Command "{args_check[0]}" is not supported.')

    if args[0] == 'tunnel':
        dockerdns.tunnel()
    elif args[0] == 'uninstall':
        dockerdns.uninstall()
    elif args[0] == 'show-domain':
        dockerdns.show_domain()
    else:
        dockerdns.install()
