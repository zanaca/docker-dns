FROM alpine:latest AS base
    LABEL maintainer="carlos@zanaca.com"

    VOLUME /var/run
    EXPOSE 53/udp 53 22

    RUN apk --no-cache add dnsmasq openssl openssh python3

    ENV DOCKER_GEN_VERSION 0.7.4
    ENV DOCKER_HOST unix:///var/run/docker.sock
    ENV HOSTUNAME Linux
    RUN echo "nameserver 1.1.1.1" > /etc/resolv.conf; \
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf

    RUN wget -qO- https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz | tar xvz -C /usr/local/bin
    ADD src/templates/dnsmasq.tpl /root/dnsmasq.tpl
    ADD Dockerfile_entrypoint.sh /root/entrypoint.sh

    ENTRYPOINT ["/root/entrypoint.sh"]

    RUN /bin/sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config; \
        /bin/sed -i s/#Compression.*/Compression\ no/ /etc/ssh/sshd_config; \
        /bin/sed -i s/#PermitEmptyPasswords.*/PermitEmptyPasswords\ yes/ /etc/ssh/sshd_config; \
        /bin/sed -i s/#PermitTunnel.*/PermitTunnel\ yes/ /etc/ssh/sshd_config; \
        /bin/sed -i s/#UseDNS.*/UseDNS\ no/ /etc/ssh/sshd_config; \
        /bin/sed -i s/AllowTcpForwarding\ no/AllowTcpForwarding\ yes/ /etc/ssh/sshd_config; \
        /bin/sed -i s/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication\ no/ /etc/ssh/sshd_config; \
        ssh-keygen -A

    RUN passwd -d root
    RUN echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf; \
        echo net.ipv4.ip_forward = 1 >> /etc/sysctl.d/ipv4.conf

FROM base AS windows
    EXPOSE 1194/udp
    ENV OPENVPN_EXISTS 1

    RUN apk add --no-cache openvpn git openssl iptables && \
    # Get easy-rsa
        git clone https://github.com/OpenVPN/easy-rsa.git /tmp/easy-rsa && \
        cd && \
    # Cleanup
        apk del git && \
        rm -rf /tmp/easy-rsa/.git && cp -a /tmp/easy-rsa /usr/local/share/ && \
        rm -rf /tmp/easy-rsa/ && \
        ln -s /usr/local/share/easy-rsa/easyrsa3/easyrsa /usr/local/bin

    #RUN modprobe tun
    #    echo "tun" >> /etc/modules-load.d/tun.conf

    ADD /tmp/openvpn.conf /etc/openvpn/openvpn.conf
    RUN mkdir /etc/openvpn/certs.d
    ADD certs.d/ovpn/* /etc/openvpn/certs.d/
    RUN chmod 600 /etc/openvpn/certs.d/*.key

