#!/usr/bin/env sh

ssh-keygen -A
export HOST_IP=`cat /etc/resolv.conf  | grep ^nameserver | cut -d\  -f2 | head -n1`

/usr/sbin/sshd
docker-gen -watch -only-exposed -notify "/root/dnsmasq-restart.sh -u root $@" /root/dnsmasq.tpl /etc/dnsmasq.conf
