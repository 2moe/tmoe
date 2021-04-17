FROM arm64v8/golang:latest
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
WORKDIR /go
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN apt update \
    ; apt dist-upgrade -y \
    ; dpkg --configure -a \
    ; apt install -y sudo locales \
    ; apt install -y whiptail curl wget apt-utils \
    ; apt install -y --no-install-recommends neofetch \
    ; mkdir -p /run/systemd \
    ; printf "%s\n" "docker" > /run/systemd/container \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; cd /usr/local/etc/tmoe-linux \
    ; printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=go_nogui-debian" > /usr/local/etc/tmoe-linux/container.txt  \
    ; apt clean

CMD [ "/bin/bash" ]
