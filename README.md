# Docker DNS for containers and host machine

Docker DNS creates a container that works as a DNS for docker containers in you machine. Every running container will be accessible by `$container_name.docker` for example. You could inform you own domain if you like. Your domains are available _inside_ and _outside_ docker, but just for you machine. For example, you could access *http://nginx.docker* from your browser window OR from inside a container.

It was created to allow you to work in a container as if was a "real" server setup. You will have access to all ports/services inside the container without need to expose all the ports. You can publish ports as well to access it like the old way. E.g.: 127.0.0.1:8080 -> container_ip:80

It was tested on linux and macOS Catalina. macOS environment has a downside that you will always run the `./bin/docker-dns tunnel` every time you boot the host machine. An service will be installed and loaded on every boot to handle that necessity or you can run the application 'dockerdns-tunnel', available on `~/Applications`.

The main usage is for development environment only, should not be used in production environment.

By default it will enable create that hosts: _ns0.docker_ and _ns0.\$YOUR_HOSTNAME.docker_.

## Requirements for host machine

-   [Docker](https://www.docker.com/products/docker-desktop)
-   Python3
-   pip
-   OpenSSH

## Tested enviroment

-   Docker 19.03.13
-   Ubuntu: 20.04
-   Linux Mint: 20, 20.1
-   macOS: Catalina, Big Sur
-   Windows: 10 (WSL2 - Ubuntu)

You can see a list of older OSes on version [1.x](https://www.github.com/zanaca/docker-dns/blob/version/1.x/README.md#tested-enviroment)

On Windows you don't have to install Docker inside WSL2 linux, you should work with Docker for windows and enable WSL2 integration.

#### \* _Windows caveat_

For Windows a socks5 proxy (using ssh to container ns0) will be used to handle the address from host machine to docker network.  Only addresses from `172.16.0.0` to `172.31.255.255` will be redirect to proxy. You will not be able to run a different proxy while using `docker-dns`. The socks5 proxy address is `127.0.0.1` using port `31080`

## Install

For an simple installation process, paste the command in a macOS Terminal, Linux or WSL shell prompt.

```
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/zanaca/docker-dns/install/run.sh)"
```

-   The script will place docker-dns inside `/usr/local/docker-dns`

Or you can checkout the code in any folder of your choice and:

-   Install all python dependencies by running `$ pip3 install -r requirements.txt`
-   Execute `$ ./bin/docker-dns install`

## Supported commands

-   `install` - Set up all environment;

-   `uninstall` - Remove configuration files from your system;

-   `show-domain` - Show the working domain of your installation;

-   `tunnel` - Create a tunnel to route all traffic to you docker containers. Available only in macOS, on linux you don't need that feature;

-   `status` - Show the current status for your machine.

You can see the list of all available commands and options running `$ ./bin/docker-dns -h`

## Options

On `install` command you can pass some variables to change how setup is done. You can change the working domain for example.

-   _tld_: working domain. It can be any domain name but the domains designed to work in loopback network. For example `yourmachine.dev` will create names like `CONTAINER_NAME.yourmachine.dev`. You can have `docker.your_real_domain.com` as well so it will create names like `CONTAINER_NAME.docker.your_real_domain.com . Default value: `docker`;

-   _tag_: Tag name for the created docker image. It should be changed only if you have a name conflict Default value: `ns0`;

-   _name_: Running container name. Default value: the _tag_ value.

Example:
```
$ ./bin/docker-dns install tld=docker.dev tag=dns
```

Will create a docker image name _dns_ and it will be available as _dns.docker.dev_ so you could run `dig www.google.com @dns.docker.dev`

## Troubleshooting

If you are using macOS or Windows, on restart, you can will loose access to your containers DNS. You need to recreate a tunnel to route all traffic to docker network through it on every boot. Just execute `sudo ./bin/docker-dns tunnel` from docker-dns folder

## License

[MIT](LICENSE.md)

## Thanks

-   Thanks to https://github.com/apenwarr/sshuttle for the great poor's man VPN service! An easy way to setup tunneling on macOS and Windows WSL
