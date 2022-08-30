import os
import sys
import socket
import platform
import util
import json
import re


APP = os.path.basename(sys.argv[0])
USER = os.environ.get('SUDO_USER') or os.environ.get('USER')
HOME = os.path.expanduser(f"~{USER}")
HOME_ROOT = os.path.expanduser("~root")
BASE_PATH = os.path.dirname(os.path.dirname(__file__))
HOSTNAME = socket.gethostname()
HOSTUNAME = platform.uname().system

if util.on_macos or util.on_windows:
    NAME = platform.uname()[0].lower()

else:
    name_pattern = re.compile(r'-(\w*)')
    NAME = re.search(pattern=name_pattern, string=platform.uname().version).group(1).lower()

if util.on_macos:
    # OS_VERSION example: '12.0.1'
    OS_VERSION = platform.mac_ver()[0]

elif util.on_windows:
    # OS_VERSION example: '10.0.19042'
    OS_VERSION = platform.win32_ver()[1]

elif util.on_wsl:
    # OS_VERSION example: '10.0.19044.0'
    powershell_path = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0//powershell.exe'
    version_path = '[Environment]::OSVersion.VersionString'
    OS_VERSION = os.popen(f'{powershell_path} {version_path}').read().split(' ')[-1].replace('\n', '')

else:
    # OS_VERSION example: '20.04'
    release_lines = open('/etc/os-release').readlines()
    release_info = {
        k.lower(): v.replace('"', '').replace('\n', '')
        for k, v in [line.split('=') for line in release_lines]
    }
    OS_VERSION = release_info.get('version_id')

OS = f'{HOSTUNAME}_{NAME}'
TOP_LEVEL_DOMAIN = (util.read_cache('tld') or 'docker').strip()
DOCKER_CONTAINER_TAG = (util.read_cache('tag') or 'ns0').strip()
DOCKER_CONTAINER_NAME = (util.read_cache('name') or DOCKER_CONTAINER_TAG).strip()
SUPPORTED_OS_VERSIONS = json.load(open(f'{BASE_PATH}/supported_os.json', 'r'))
