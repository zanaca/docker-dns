import os
import sys
import socket
import platform
import util
import netifaces


APP = os.path.basename(sys.argv[0])

DOCKER_INTERFACE = 'docker0'
WHO = os.environ["USER"]
HOME = os.environ["HOME"]
HOME_ROOT = '/root'
PWD = os.getcwd
HOSTNAME = socket.gethostname()
HOSTUNAME = platform.uname().system
LOOPBACK = netifaces.interfaces()[0]

if util.on_macos:
    NAME = 'macOS'
elif util.on_windows:
    NAME = 'Windows'
elif util.on_wsl:
    NAME = 'wsl2'
else:
    NAME = open('/etc/os-release',
                'r').read().split('NAME="')[1].split('.')[0]

if util.on_macos:
    VERSION_MAJOR_ID = '.'.join(platform.mac_ver()[0].split('.')[0:2])
elif util.on_windows:
    VERSION_MAJOR_ID = '.'
else:
    VERSION_MAJOR_ID = open(
        '/etc/os-release', 'r').read().split('VERSION_ID="')[1].split('.')[0]

TOP_LEVEL_DOMAIN = (util.read_cache('tld') or 'docker').strip()
DOCKER_CONTAINER_TAG = (util.read_cache('tag') or 'ns0').strip()
DOCKER_CONTAINER_NAME = (util.read_cache(
    'name') or DOCKER_CONTAINER_TAG).strip()
