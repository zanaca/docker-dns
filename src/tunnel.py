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


def connect(daemon=False, verbose=False):
    if not util.is_tunnel_needed():
        print("You do not need to run tunnel")
        sys.exit(0)

    util.check_if_root()
    docker_container_name = config.DOCKER_CONTAINER_NAME

    # alias network ip
    os.system(
        f'ifconfig {network.LOOPBACK_NETWORK_NAME} alias {docker.NETWORK_GATEWAY}')

    # prepare tunnel
    port = False
    while not port:
        ports = docker.get_exposed_port(docker_container_name)
        if '22/tcp' in ports:
            port = ports['22/tcp'][0]['HostPort']
    sys.argv = [shutil.which('sshuttle'), '--pidfile=/tmp/sshuttle.pid',
                '-r', f'root@127.0.0.1:{port}', docker.NETWORK_SUBNET]
    if verbose:
        sys.argv.append('-vv')
    if daemon:
        sys.argv.append('-D')

    ok = False
    while not ok:
        sshuttle_fake_caller()
        time.sleep(1)
        if daemon:
            ok = True


def check_if_running():
    try:
        port = False
        ports = docker.get_exposed_port(config.DOCKER_CONTAINER_NAME)
        if '22/tcp' in ports:
            port = int(ports['22/tcp'][0]['HostPort'])

        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        code = s.connect_ex(
            ('127.0.0.1', port))
        s.close()
        return code == 0

    except Exception as e:
        print(f'Error: {e}')
        return False


def check_if_connected():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        code = s.connect_ex(
            (docker.NETWORK_GATEWAY, 53))
        s.close()
        return code == 0

    except Exception as e:
        print(f'Error: {e}')
        return False
