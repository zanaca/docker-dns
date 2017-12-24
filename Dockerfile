FROM alpine:latest
MAINTAINER Zanaca "carlos@zanaca.com"

VOLUME /var/run
EXPOSE 53/udp 53 22

RUN apk --no-cache add dnsmasq openssl openssh python

ENV DOCKER_GEN_VERSION 0.7.3
ENV DOCKER_HOST unix:///var/run/docker.sock
ENV HOSTUNAME Linux
ENTRYPOINT ["/root/entrypoint.sh"]
RUN echo "nameserver 8.8.4.4" > /etc/resolv.conf
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf

RUN wget -qO- https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz | tar xvz -C /usr/local/bin
ADD conf/dnsmasq.tpl /root/dnsmasq.tpl
ADD dnsmasq-restart.sh /root/dnsmasq-restart.sh
ADD Dockerfile_entrypoint.sh /root/entrypoint.sh
RUN mkdir /root/.ssh && chmod 700 /root/.ssh
ADD Dockerfile_id_rsa.pub /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

RUN sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config
RUN sed -i s/#Compression.*/Compression\ no/ /etc/ssh/sshd_config
RUN sed -i s/#PermitEmptyPasswords.*/PermitEmptyPasswords\ yes/ /etc/ssh/sshd_config
RUN sed -i s/#PermitTunnel.*/PermitTunnel\ yes/ /etc/ssh/sshd_config
RUN sed -i s/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication\ no/ /etc/ssh/sshd_config

RUN echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
