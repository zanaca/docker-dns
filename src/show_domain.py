import config
import dockerapi as docker


def main():
    domain = docker.get_top_level_domain(
        config.DOCKER_CONTAINER_NAME, config.TOP_LEVEL_DOMAIN)
    print(f'Working domain:\n{domain}')
