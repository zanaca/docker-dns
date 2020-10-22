import config
import dockerapi as docker

import install
import tunnel
import util


def main():
    is_installed = install.check_if_installed()
    is_running = docker.check_exists(config.DOCKER_CONTAINER_NAME)
    needs_tunnel = util.is_tunnel_needed()
    is_tunnel_up = tunnel.check_if_running()
    is_working = tunnel.check_if_connected()

    NO = "\033[1;31mNo\033[0m"
    YES = "\033[1;32mYes\033[0m"

    print(f"""{config.APP} status:

- Is installed: {YES if is_installed else NO} 
- Container "{config.DOCKER_CONTAINER_NAME}" is running: {YES if is_running else NO}
- Your OS needs tunnel: {YES if needs_tunnel else NO}
- Is tunnel running: {YES if is_tunnel_up else NO}
- Domain "{config.TOP_LEVEL_DOMAIN}" is working: {YES if is_working else NO}
""")
