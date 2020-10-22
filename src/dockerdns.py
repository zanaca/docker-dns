
import util
import dockerapi as docker
#import socket
#import struct
#import fcntl
import config
import sys
from sshuttle.cmdline import main as sshuttle_fake_caller
import shutil

#SIOCSIFADDR = 0x8916
#sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

top_level_domain = (util.read_cache('tld') or 'docker').strip()
docker_container_tag = (util.read_cache('tag') or 'ns0').strip()
docker_container_name = (util.read_cache(
    'name') or docker_container_tag).strip()

try:
    ip_address = docker.get_ip(docker_container_name).split('.')
    ip_address[3] = '1'
    ip_address = '.'.join(ip_address)
except:
    print(f'ERROR. Container "{docker_container_name}" is not running.')
    sys.exit(1)


def install():
    util.check_if_root()
    False


def uninstall():
    util.check_if_root()
    False


def tunnel():
    util.check_if_root()
    network = ip_address.split('.')
    network[3] = '0'
    network = f'{".".join(network)}/24'

    # ETHERN = bytes(config.LOOPBACK, 'utf-8')
    # bin_ip = socket.inet_aton(ip_address)
    # ifreq = struct.pack('16sH2s4s8s', ETHERN, socket.AF_INET,
    #                     b'\x00' * 2, bin_ip, b'\x00' * 8)
    # fcntl.ioctl(sock, SIOCSIFADDR, ifreq)

    port = False
    while not port:
        ports = docker.get_exposed_port(docker_container_name)
        if '22/tcp' in ports:
            port = ports['22/tcp'][0]['HostPort']

    sys.argv = [shutil.which('sshuttle'), '-vv','--pidfile=/tmp/sshuttle.pid','-r',f'root@127.0.0.1:{port}', network]
    sys.exit(sshuttle_fake_caller())


def show_domain():
    domain = docker.get_top_level_domain(
        docker_container_name, top_level_domain)
    print(f'Working domain:\n{domain}')
