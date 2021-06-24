import docker
import config

errors = docker.errors

client = docker.from_env()

__network_config = client.networks.get(
    'bridge').attrs['IPAM']['Config'][0]
NETWORK_SUBNET = __network_config['Subnet']
NETWORK_GATEWAY = None
if 'Gateway' in __network_config:
    NETWORK_GATEWAY = __network_config['Gateway']
else:
    NETWORK_GATEWAY = NETWORK_SUBNET.split('.')
    NETWORK_GATEWAY[3] = '1'
    NETWORK_GATEWAY = '.'.join(NETWORK_GATEWAY)


def get_top_level_domain(container, tld):
    return client.containers.get(
        config.DOCKER_CONTAINER_NAME).exec_run(f'sh -c "echo {config.TOP_LEVEL_DOMAIN}"').output.strip().decode("utf-8")


def check_exists(name=config.DOCKER_CONTAINER_NAME):
    try:
        return True if client.containers.get(name) else False
    except:
        return False


def purge(name=config.DOCKER_CONTAINER_NAME):
    try:
        client.api.kill(name)
    except:
        pass
    client.api.remove_container(name)


def get_exposed_port(name=config.DOCKER_CONTAINER_NAME):
    return client.containers.get(name).ports


def get_ip(name=config.DOCKER_CONTAINER_NAME):
    return client.containers.get(name).attrs['NetworkSettings']['IPAddress']


def build_container(
        name=config.DOCKER_CONTAINER_NAME, tag=config.DOCKER_CONTAINER_TAG, tld=config.TOP_LEVEL_DOMAIN,
        bind_port_ip=False, target='base'):
    print('- Building...')

    docker_output = client.images.build(
        path='.', target=target, tag=f'{tag}:latest', nocache=False, rm=True)

    for line in docker_output[1]:
        if 'stream' in line:
            print(line['stream'], end='')

    port_53 = 53
    if bind_port_ip:
        port_53 = (NETWORK_GATEWAY, 53)

    host_config = client.api.create_host_config(
        restart_policy={'Name': 'always'},
        security_opt=['apparmor:unconfined'],
        port_bindings={
            '53/udp': port_53,
            53: port_53
        },
        publish_all_ports=True,
        binds=['/var/run/docker.sock:/var/run/docker.sock'],
    )

    docker_output = client.api.create_container(tag,
                                                name=name,
                                                volumes=[
                                                    '/var/run/docker.sock'],
                                                environment=[
                                                    f'TOP_LEVEL_DOMAIN={tld}', f'HOSTNAME={config.HOSTNAME}', f'HOSTUNAME={config.HOSTUNAME}'],
                                                host_config=host_config,
                                                detach=True
                                                )
    if len(docker_output['Warnings']) > 0:
        for line in line['Warnings']:
            print(line)

    print('- Starting...')
    client.api.start(name)


def check_if_tunnel_is_connected(name=config.DOCKER_CONTAINER_NAME):
    output = client.containers.get(
        config.DOCKER_CONTAINER_NAME).exec_run('ps').output.strip().decode("utf-8").split("python3")

    return len(output) > 1
