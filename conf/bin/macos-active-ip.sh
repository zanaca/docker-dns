#!/usr/bin/env bash

EN=$(./macos-active-interface.sh | head -n1)
IP=$(ifconfig $EN | grep inet\  | cit -d\  -f2)

echo $IP

echo $1
echo $2
exit
if [[ "$1" == "update-resolver" ]]; then
    echo "nameserver $IP" | sudo cat - /etc/resolver/$2 > /tmp/docker-dns-resolv; mv /tmp/docker-dns-resolv /etc/resolver/$2
fi