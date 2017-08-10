# docker DNS

Docker DNS creates a container that works as a DNS for docker containers in you machine. Every running container will be accessible by `$container_name.docker` for example. You could inform you own domain if you like. Your domains are available *inside* and *outside* docker, but just for you machine.

It was created to allow you to work in a container as if was a "real" server setup. You will have access to all ports/services inside the container without need to expose all the ports. You can publish ports as well to access it like the old way. E.g.: 127.0.0.1:8080 -> container_ip:80

It was tested on linux and macOS sierra. macOS environment has a downside that you will always run the `make tunnel` every time you boot the host machine,

The main usage is for development only, should not be used in production environment.

By default it will enable create that hosts: *ns0.docker* and *ns0.$YOUR_HOSTNAME.docker*.



### Supported commands
 - `make install` - Sets up all environment;

 - `make uninstall` - Removes configuration files from your system;

 - `make show-domain` - Show the working domain of your installation;

 - `make tunnel` - *WORKS ONLY IN macOS* Creates a tunnel to route all traffic to you docker containers. On linux you do not need that feature.



### Options
In `make install` you can pass some variables to change how setup is done. You can change the working domain for example.
 - *tld*: working domain. It can be any domain name but the domains designed to work in loopback network. For example `yourmachine.dev` will create names like `CONTAINER_NAME.yourmachine.dev`. You can have `docker.yourdomain_real_domain.com` as well so it will create names like `CONTAINER_NAME.docker.yourdomain_real_domain.com . Default value: `docker`;

 - *tag*: Tag name for the created docker image. It should be changed only if you have a name conflict  Default value: `ns0`

 - *name*: Running container name. Default value: the *tag* name

Example:
     `make install tld=mymachine.dev tag=dns`
Will create a docker image name *dns* and it will be available as *dns.mymachine.dev* so you could run `dig www.google.com @dns.mymachine.dev`

### Requirements
 - [Docker](https://www.docker.com/docker-ubuntu) or [Docker for mac](https://www.docker.com/docker-mac)
 - [Homebrew](https://brew.sh/) for macOS machines


### Tested enviroment
 - Docker 17.0.4.0-ce
 - Docker for mac 17.06.0-ce
 - Linux (Ubuntu, CentOS)
 - macOS Sierra



### Troubleshooting

If you are using macOS, on restart, you will loose access to your containers because by macOS network design docker is unable to create a interface, so you need to create a tunnel to route all traffic to docker network through it. To recreate that tunnel you must run:
`make tunnel`


### Thanks

Thanks to https://github.com/apenwarr/sshuttle for the great poor's man VPN service! An easy way to setup tunneling on macOS
