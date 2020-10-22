import os
import socket
import platform
import util
import netifaces


DOCKER_INTERFACE='docker0'
WHO=os.environ["USER"]
HOME=os.environ["HOME"]
HOME_ROOT='/root'
PWD=os.getcwd
HOSTNAME=socket.gethostname()
LOOPBACK=netifaces.interfaces()[0]

if util.on_macos:
    NAME='macOS'
elif util.on_windows:
    NAME='Windows'
elif util.wsl:
    NAME='wsl2'
else:
    NAME=open('/etc/os-release', 'r').release().split('NAME="')[1].split('.')[0]

if util.on_macos:
    VERSION_MAJOR_ID='.'.join(platform.mac_ver()[0].split('.')[0:2])
elif util.on_windows:
    VERSION_MAJOR_ID='.'
else:
    VERSION_MAJOR_ID=open('/etc/os-release', 'r').release().split('VERSION_ID="')[1].split('.')[0]
