FROM alpine:latest
MAINTAINER Zanaca "carlos@zanaca.com"

VOLUME /var/run
EXPOSE 53/udp 53 22

RUN apk --no-cache add dnsmasq openssl openssh python

ENV DOCKER_GEN_VERSION 0.7.3
ENV DOCKER_HOST unix:///var/run/docker.sock
ENV HOSTUNAME Linux
RUN echo "nameserver 1.1.1.1" > /etc/resolv.conf \
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf

RUN wget -qO- https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz | tar xvz -C /usr/local/bin
ADD conf/dnsmasq.tpl /root/dnsmasq.tpl
ADD dnsmasq-restart.sh /root/dnsmasq-restart.sh
ADD Dockerfile_entrypoint.sh /root/entrypoint.sh
ADD Dockerfile_id_rsa.pub /root/.ssh/authorized_keys
RUN /bin/chmod 700 /root/.ssh; \
    /bin/chmod 600 /root/.ssh/authorized_keys
ENTRYPOINT ["/root/entrypoint.sh"]

RUN /bin/sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config; \
    /bin/sed -i s/#Compression.*/Compression\ no/ /etc/ssh/sshd_config; \
    /bin/sed -i s/#PermitEmptyPasswords.*/PermitEmptyPasswords\ yes/ /etc/ssh/sshd_config; \
    /bin/sed -i s/#PermitTunnel.*/PermitTunnel\ yes/ /etc/ssh/sshd_config; \
    /bin/sed -i s/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication\ no/ /etc/ssh/sshd_config

RUN passwd -d root
RUN echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
