import os
import sys
import socket
import platform
import util


APP = os.path.basename(sys.argv[0])

WHO = os.environ["USER"]
HOME = os.path.expanduser("~")
HOME_ROOT = os.path.expanduser("~root")
PWD = os.getcwd
HOSTNAME = socket.gethostname()
HOSTUNAME = platform.uname().system

if util.on_macos or util.on_windows:
    NAME = platform.uname()[0]
elif util.on_wsl:
    NAME = 'wsl2'
else:
    NAME = open('/etc/os-release',
                'r').read().split('NAME="')[1].split('"')[0]

if util.on_macos:
    VERSION_MAJOR_ID = '.'.join(platform.mac_ver()[0].split('.')[0:2])
    version = platform.mac_ver()[0].split('.')
    OS_VERSION = int(version[1]) + int(version[0]) * 1000
    del(version)
elif util.on_windows:
    VERSION_MAJOR_ID = '.'
    OS_VERSION = 0
else:
    VERSION_MAJOR_ID = open(
        '/etc/os-release', 'r').read().split('VERSION_ID="')[1].split('.')[0]
    OS_VERSION = int(VERSION_MAJOR_ID)
OS = f'{HOSTUNAME}_{NAME}'

TOP_LEVEL_DOMAIN = (util.read_cache('tld') or 'docker').strip()
DOCKER_CONTAINER_TAG = (util.read_cache('tag') or 'ns0').strip()
DOCKER_CONTAINER_NAME = (util.read_cache(
    'name') or DOCKER_CONTAINER_TAG).strip()
