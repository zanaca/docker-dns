import time
import socket
import shutil
import os
import sys
from sshuttle.cmdline import main as sshuttle_fake_caller

import util
import config
import dockerapi as docker
import network

SIOCSIFADDR = 0x8916


def connect(verbose=False):
    if not util.is_tunnel_needed():
        print("You do not need to run tunnel")
        sys.exit(0)

    if not util.is_super_user():
        exit("You need to have root privileges to run this script.\nPlease try again, this time using 'sudo'. Exiting.")

    docker_container_name = config.DOCKER_CONTAINER_NAME

    # alias network ip
    if util.on_macos:
        os.system(
            f'ifconfig {network.LOOPBACK_NETWORK_NAME} alias {docker.NETWORK_GATEWAY}')

    # prepare tunnel
    port = False
    while not port:
        ports = docker.get_exposed_port(docker_container_name)
        if '22/tcp' in ports:
            port = ports['22/tcp'][0]['HostPort']
    sys.argv = [shutil.which('sshuttle')]
    if verbose:
        sys.argv.append('-vv')

    sys.argv += ['--pidfile=/tmp/sshuttle.pid',
                 '-r', f'root@127.0.0.1:{port}', docker.NETWORK_SUBNET]
    #           '-r', f'root@127.0.0.1:{port}', '-x', '10.0.0.0/8', '-x', '192.168.0.0/16', '0/0']
    # while True:
    sshuttle_fake_caller()
    #    time.sleep(1)


def check_if_running():
    try:
        return docker.check_if_tunnel_is_connected(config.DOCKER_CONTAINER_NAME)

    except docker.errors.NotFound as e:
        return Flase
    except Exception as e:
        print(f'Error: {e}')
        return False
