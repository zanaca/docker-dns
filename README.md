# Docker DNS

Docker DNS creates a container that works as a DNS for docker containers in you machine. Every running container will be accessible by `$container_name.docker` for example. You could inform you own domain if you like. Your domains are available *inside* and *outside* docker, but just for you machine. For example, you could access *http://nginx.docker* from your browser window OR from inside a container.

It was created to allow you to work in a container as if was a "real" server setup. You will have access to all ports/services inside the container without need to expose all the ports. You can publish ports as well to access it like the old way. E.g.: 127.0.0.1:8080 -> container_ip:80

It was tested on linux and macOS sierra. macOS environment has a downside that you will always run the `make tunnel` every time you boot the host machine,

The main usage is for development environment only, should not be used in production environment.

By default it will enable create that hosts: *ns0.docker* and *ns0.$YOUR_HOSTNAME.docker*.



### Supported commands
 - `make install` - Set up all environment;

 - `make uninstall` - Remove configuration files from your system;

 - `make show-domain` - Show the working domain of your installation;

 - `make tunnel` - Create a tunnel to route all traffic to you docker containers. Available only in macOS, on linux you don't need that feature.



### Options
In `make install` you can pass some variables to change how setup is done. You can change the working domain for example.
 - *tld*: working domain. It can be any domain name but the domains designed to work in loopback network. For example `yourmachine.dev` will create names like `CONTAINER_NAME.yourmachine.dev`. You can have `docker.your_real_domain.com` as well so it will create names like `CONTAINER_NAME.docker.your_real_domain.com . Default value: `docker`;

 - *tag*: Tag name for the created docker image. It should be changed only if you have a name conflict  Default value: `ns0`

 - *name*: Running container name. Default value: the *tag* name

Example:
     `make install tld=docker.dev tag=dns`
Will create a docker image name *dns* and it will be available as *dns.docker.dev* so you could run `dig www.google.com @dns.docker.dev`

### Requirements
 - [Docker CE](https://www.docker.com) or [Docker for mac](https://www.docker.com/docker-mac)
 - [Homebrew](https://brew.sh/) for macOS machines


### Tested enviroment
 - Docker 17.0.4.0-ce
 - Docker for mac 17.06.0-ce, 17.09.1-ce-mac42
 - Ubuntu: 16.04, 17.04, 17.10, 18.04
 - Fedora: 27
 - macOS: Sierra, High Sierra



### Troubleshooting

If you are using macOS, on restart, you will loose access to your containers. You need to recreate a tunnel to route all traffic to docker network through it on every boot. Just execute `sudo make tunnel` from docker-dns folder


### License

[MIT](LICENSE.md)


### Thanks

- Thanks to https://github.com/apenwarr/sshuttle for the great poor's man VPN service! An easy way to setup tunneling on macOS
