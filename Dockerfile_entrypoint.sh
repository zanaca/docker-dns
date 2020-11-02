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

if [ ! -z ${OPENVPN_EXISTS+x} ]; then
    mkdir -p /dev/net
    if [ ! -c /dev/net/tun ]; then
        mknod /dev/net/tun c 10 200
    fi

    /usr/sbin/openvpn --config /etc/openvpn/openvpn.conf


    iptables -I INPUT -p udp --dport 1194 -j ACCEPT
    iptables -t nat -A POSTROUTING -s 172.17.0.0/24 -d 0.0.0.0/0 -o eth0 -j MASQUERADE
    iptables -I FORWARD -i eth0 -o tun0 -j ACCEPT
    iptables -I FORWARD -i tun0 -o eth0 -j ACCEPT
    iptables -t nat -P POSTROUTING ACCEPT
    iptables -t nat -P PREROUTING ACCEPT
    iptables -t nat -P OUTPUT ACCEPT

fi

/usr/sbin/sshd

docker-gen -only-exposed /root/dnsmasq.tpl /etc/dnsmasq.conf
dnsmasq
docker-gen -watch -only-exposed -notify "/root/dnsmasq-restart.sh -u root $@" /root/dnsmasq.tpl /etc/dnsmasq.conf &
syslogd -n -O /dev/stdout
