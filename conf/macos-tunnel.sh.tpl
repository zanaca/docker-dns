#!/usr/bin/env sh

HOME_ROOT=$(shell echo ~root)

ifconfig lo0 alias 172.17.0.1

while [ $(docker port {DOCKER_CONTAINER_NAME} 2>&1 | grep 22/ | cut -d: -f2 | wc -l)  -eq 0 ]; do
    echo $(date) - Waiting for docker-dns container to be ready
    sleep 1;
done

grep -v ecdsa-sha2-nistp256 $HOME_ROOT/.ssh/known_hosts > .known_hosts
ssh-keyscan -p `docker port {DOCKER_CONTAINER_NAME} | grep 22/ | cut -d: -f2` 127.0.0.1 | grep ecdsa-sha2-nistp256 >> .known_hosts
mv .known_hosts $HOME_ROOT/.ssh/known_hosts

echo $(date) - Starting sshuttle
PORT=$(docker port {DOCKER_CONTAINER_NAME} 2>&1 | grep 22/ | cut -d: -f2)
/usr/local/bin/sshuttle --pidfile=/tmp/sshuttle.pid -r root@127.0.0.1:$PORT 172.17.0.0/24 ||  echo $(date) - Error loading sshuttle