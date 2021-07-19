FROM amd64/golang:rc-buster
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
ADD README.go /root
WORKDIR /go
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN apt update; \
    apt dist-upgrade -y; \
    dpkg --configure -a; \
    apt install -y sudo locales curl; \
    apt install -y whiptail eatmydata procps apt-utils; \
    apt install -y --no-install-recommends neofetch; \
    printf "%s\n" "root:root" | chpasswd; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=go_nogui-debian" > container.txt ; \
    mkdir -p environment; \
    printf "%s\n%s\n" 'export PATH="/go/bin:/usr/local/go/bin${PATH:+:${PATH}}"' "export GOPATH=/go" > environment/container.env; \
    chmod -R a+rx environment/; \
    cd /root; \
    printf "%s\n" "GO_VERSION='$(go version)'" > version.txt; \
    cat version.txt; \
    rm -fv /var/cache/apt/archives/* \
    /var/cache/apt/* \
    /var/mail/* \
    /var/log/* \
    /var/log/apt/* \
    /var/log/journal/* \
    /var/lib/apt/lists/* \
    2>/dev/null; \
    apt clean
# ENV PATH=/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     GOPATH=/go
CMD [ "/bin/bash" ]
