#!/usr/bin/env sh

while [ `nc -z 127.0.0.1 2200 2>&1 | wc -l` -eq 0 ]; do
    echo `date` - Waiting for docker-dns container to be ready
    sleep 1;
done
echo `date` - Starting sshuttle
/usr/local/bin/sshuttle -vv -r root@127.0.0.1:2200 172.17.0.0/24 ||  echo `date` - Error loading sshuttle