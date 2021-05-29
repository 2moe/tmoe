FROM amd64/node:latest
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
ADD README.js /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN apt update; \
    apt dist-upgrade -y; \
    dpkg --configure -a; \
    apt install -y sudo locales; \
    apt install -y whiptail curl eatmydata procps apt-utils; \
    apt install -y --no-install-recommends neofetch; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux/; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=node_nogui-debian" > container.txt ; \
    mkdir -p environment; \
    printf "%s\n%s\n" 'cd ~' "node" > environment/entrypoint; \
    chmod -R a+rx environment/; \
    cd /root; \
    printf "%s\n" "NODE_VERSION='$(node --version)'" > version.txt; \
    printf "%s\n" "YARN_VERSION='$(yarn --version)'" >> version.txt; \
    printf "%s\n" "NPM_VERSION='$(npm --version)'" >> version.txt; \
    rm -fv /var/cache/apt/archives/* \
    /var/cache/apt/* \
    /var/mail/* \
    /var/log/* \
    /var/log/apt/* \
    /var/log/journal/* \
    /var/lib/apt/lists/* \
    2>/dev/null; \
    apt clean

CMD [ "node" ]
