#!/usr/bin/env bash

DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
EN=$($DIR/macos-active-interface.sh | head -n1)
IP=$(ifconfig $EN | grep inet\  | cut -d\  -f2)

echo $IP
if [[ "$1" == "update-resolver" ]]; then
    echo "nameserver $IP" > /tmp/docker-dns-resolv; mv /tmp/docker-dns-resolv /etc/resolver/$2
fi
