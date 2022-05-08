FROM alpine:3.15.0 AS base
    LABEL maintainer="carlos@zanaca.com"

    VOLUME /var/run
    EXPOSE 53/udp 53 22

    RUN apk --no-cache add dnsmasq openssl openssh python3

    ENV DOCKER_GEN_VERSION 0.7.4
    ENV DOCKER_HOST unix:///var/run/docker.sock
    ENV HOSTUNAME Linux

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
