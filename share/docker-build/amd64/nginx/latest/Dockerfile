FROM amd64/nginx:latest
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
WORKDIR /root
ADD README.txt /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN apt update; \
    apt dist-upgrade -y; \
    dpkg --configure -a; \
    apt install -y sudo locales; \
    apt install -y whiptail curl eatmydata apt-utils procps; \
    apt install -y --no-install-recommends neofetch; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=nginx_nogui-debian" > container.txt ; \
    mkdir -p environment; \
    printf "%s\n%s\n" 'cd ~' "nginx -g 'daemon off;'" > environment/entrypoint; \
    chmod -R a+rx environment/; \
    cd /root; \
    printf "%s\n" "NGINX_VERSION='${NGINX_VERSION}'" > version.txt; \
    printf "%s\n" "NJS_VERSION='${NJS_VERSION}'" >> version.txt; \
    printf "%s\n" "PKG_RELEASE='${PKG_RELEASE}'" >> version.txt; \
    cat version.txt; \
    apt clean

CMD ["nginx", "-g", "daemon off;"]
