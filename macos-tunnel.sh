#!/usr/bin/env sh

while [ `nc -z 127.0.0.1 2200 2>&1 | wc -l` -eq 0 ]; do
    sleep 1;
done
/usr/local/bin/sshuttle -vv -r root@127.0.0.1:2200 172.17.0.0/24