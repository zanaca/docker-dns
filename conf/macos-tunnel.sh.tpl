#!/usr/bin/env sh

ifconfig lo0 alias 172.17.0.1

while [ $(docker port {DOCKER_CONTAINER_NAME} 2>&1 | grep 22/ | cut -d: -f2 | wc -l)  -eq 0 ]; do
    echo $(date) - Waiting for docker-dns container to be ready
    sleep 1;
done
echo $(date) - Starting sshuttle
PORT=$(docker port {DOCKER_CONTAINER_NAME} 2>&1 | grep 22/ | cut -d: -f2)
/usr/local/bin/sshuttle -vv -r root@127.0.0.1:$PORT 172.17.0.0/24 ||  echo $(date) - Error loading sshuttle