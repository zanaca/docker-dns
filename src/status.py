import config
import dockerapi as docker

import tunnel
import util
import network


def main():
    is_installed = util.check_if_installed()
    is_running = docker.check_exists(config.DOCKER_CONTAINER_NAME)
    needs_tunnel = util.is_tunnel_needed()
    is_tunnel_up = tunnel.check_if_running()
    is_working = network.is_resolving_tld(config.TOP_LEVEL_DOMAIN)

    NO = "\033[1;31mNo\033[0m"
    YES = "\033[1;32mYes\033[0m"

    print(f"""{config.APP} status:

- Is installed: {YES if is_installed else NO}
- Container "{config.DOCKER_CONTAINER_NAME}" is running: {YES if is_running else NO}
- Your OS needs tunnel: {YES if needs_tunnel else NO}
- Is tunnel running: {YES if is_tunnel_up else NO}
- Domain "{config.TOP_LEVEL_DOMAIN}" is working: {YES if is_working else NO}
""")
    return 0
