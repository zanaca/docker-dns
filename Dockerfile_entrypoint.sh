#!/usr/bin/env sh

cat <<EOF  > /root/dnsmasq-restart.sh
#!/bin/sh
killall dnsmasq
sleep 1
/usr/sbin/dnsmasq "\$@"
EOF
chmod +x /root/dnsmasq-restart.sh

export HOST_IP=`cat /etc/resolv.conf  | grep ^nameserver | cut -d\  -f2 | head -n1`

if [ ! -z "$OPENVPN_EXISTS" ]; then
    modprobe tun
    echo "tun" >> /etc/modules-load.d/tun.conf
    /usr/sbin/openvpn --config /etc/openvpn/openvpn.conf
fi

/usr/sbin/sshd

docker-gen -only-exposed /root/dnsmasq.tpl /etc/dnsmasq.conf
dnsmasq
docker-gen -watch -only-exposed -notify "/root/dnsmasq-restart.sh -u root $@" /root/dnsmasq.tpl /etc/dnsmasq.conf
