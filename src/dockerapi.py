import docker
import util

client = docker.from_env()


def get_top_level_domain(container, tld):
    return client.containers.get(container).exec_run(f'sh -c "echo {tld}"').output.strip().decode("utf-8")


def get_exposed_port(container):
    return client.containers.get(container).ports


def get_ip(container):
    return client.containers.get(container).attrs['NetworkSettings']['IPAddress']
