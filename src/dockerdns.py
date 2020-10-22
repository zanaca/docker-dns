
import util
import dockercli as docker
import socket
import struct
import fcntl

SIOCSIFADDR = 0x8916
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

ip_address = docker.get_ip('ns0').split('.')
ip_address[3] = '1'
ip_address = '.'.join(ip_address)

top_level_domain = (util.read_cache('tld') or 'docker').strip()
docker_container_tag = (util.read_cache('tag') or 'ns0').strip()
docker_container_name = (util.read_cache(
    'name') or docker_container_tag).strip()


def install():
    False


def uninstall():
    False


def tunnel():
    ETH = 'lo0'
    network = ip_address.split('.')
    network[3] = '0'
    network = f'{".".join(network)}/24'

    bin_ip = socket.inet_aton(ip_address)
    ifreq = struct.pack(b'16sH2s4s8s', bytes(ETH, 'utf-8'), socket.AF_INET,
                        '\x00' * 2, bin_ip, '\x00' * 8)
    fcntl.ioctl(sock, SIOCSIFADDR, ifreq)

    port = False
    while not port:
        ports = docket.get_exposed_port(docker_container_name)
        if '22/tcp' in ports:
            port = ports['22/tcp'][0]['HostPort']

    print("Routing docker packages")
    os.system(
        f'sshuttle -vv --pidfile=/tmp/sshuttle.pid -r root@127.0.0.1:{port} {network}/24')


def show_domain():
    domain = docker.get_top_level_domain(
        docker_container_name, top_level_domain)
    print(f'Working domain:\n{domain}')
