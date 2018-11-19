#!/usr/bin/env sh

HOME_ROOT=$(echo ~root)
DOCKER=/usr/local/bin/docker

function create_tunnel() {
    ifconfig lo0 alias 172.17.0.1

    while [ $($DOCKER port {DOCKER_CONTAINER_NAME} 2>&1 | grep 22/ | cut -d: -f2 | wc -l)  -eq 0 ]; do
        echo $(date) - Waiting for docker-dns container to be ready
        sleep 1;
    done

    grep -v ecdsa-sha2-nistp256 $HOME_ROOT/.ssh/known_hosts > .known_hosts
    ssh-keyscan -p `$DOCKER port {DOCKER_CONTAINER_NAME} | grep 22/ | cut -d: -f2` 127.0.0.1 | grep ecdsa-sha2-nistp256 >> .known_hosts
    mv .known_hosts $HOME_ROOT/.ssh/known_hosts

    echo $(date) - Starting sshuttle
    PORT=$($DOCKER port {DOCKER_CONTAINER_NAME} 2>&1 | grep 22/ | cut -d: -f2)
    /usr/local/bin/sshuttle --pidfile=/tmp/sshuttle.pid -r root@127.0.0.1:$PORT 172.17.0.0/24 ||  echo $(date) - Error loading sshuttle
}

if [ "$(id -u)" -eq "0" ]; then
    create_tunnel
else
    echo "Will prompt for admin password to start tunnel as \"ifconfig lo0\" needs root privileges."
    osascript -e "do shell script \"$0\" with administrator privileges"
fi
