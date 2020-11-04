#!/usr/bin/env sh
set -u

cat <<EOF  > /root/dnsmasq-restart.sh
#!/bin/sh
killall dnsmasq
sleep 1
/usr/sbin/dnsmasq "\$@"
EOF
chmod +x /root/dnsmasq-restart.sh

export HOST_IP=`cat /etc/resolv.conf  | grep ^nameserver | cut -d\  -f2 | head -n1`

/usr/sbin/sshd

docker-gen -only-exposed /root/dnsmasq.tpl /etc/dnsmasq.conf
dnsmasq
docker-gen -watch -only-exposed -notify "/root/dnsmasq-restart.sh -u root $@" /root/dnsmasq.tpl /etc/dnsmasq.conf &
syslogd -n -O /dev/stdout