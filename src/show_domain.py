import config
import dockerapi as docker


def main():
    try:
        domain = docker.get_top_level_domain(
            config.DOCKER_CONTAINER_NAME, config.TOP_LEVEL_DOMAIN)
        print(f'Working domain:\n{domain}')
        return 0

    except docker.errors.NotFound as e:
        print('docker-dns container is not running')
        return 1

    except Fatal as e:
        print(f'fatal: {e}')
        return 1
