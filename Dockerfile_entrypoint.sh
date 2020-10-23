#!/usr/bin/env sh

cat <<EOF  > /root/dnsmasq-restart.sh
#!/bin/sh
killall dnsmasq
/usr/sbin/dnsmasq "$@"
EOF
chmod +x /root/dnsmasq-restart.sh

ssh-keygen -A
export HOST_IP=`cat /etc/resolv.conf  | grep ^nameserver | cut -d\  -f2 | head -n1`

/usr/sbin/sshd

killall -1 dnsmasq
docker-gen -only-exposed /root/dnsmasq.tpl /etc/dnsmasq.conf
/root/dnsmasq-restart.sh
docker-gen -watch -only-exposed -notify "/root/dnsmasq-restart.sh -u root $@" /root/dnsmasq.tpl /etc/dnsmasq.conf
