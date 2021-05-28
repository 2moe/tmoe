FROM arm64v8/debian:unstable-slim
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
ADD README.js /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true \
    ARCH_TYPE=arm64
#  sed -E -i 's@(configure)@pre\1@g' /var/lib/dpkg/info/libc-bin.postinst; \
RUN apt update; \
    apt dist-upgrade -y; \
    dpkg --configure -a; \
    apt install -y sudo locales curl; \
    apt install -y whiptail eatmydata procps apt-utils; \
    apt install -y --no-install-recommends neofetch nano bat; \
    if [ $(command -v batcat) ];then ln -svf $(command -v batcat) /usr/bin/bat;fi; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    cd /tmp; \
    THE_LATEST_LINK=$(curl -L https://api.github.com/repos/cdr/code-server/releases | grep "${ARCH_TYPE}" | grep browser_download_url | grep \.deb | head -n 1 | awk -F ' ' '$0=$NF' | cut -d '"' -f 2); \
    curl -Lo code.deb ${THE_LATEST_LINK} || exit 1; \
    apt install -y ./code.deb; \
    rm -fv code.deb; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=code_web-debian" > container.txt ; \
    mkdir -p environment; \
    printf "%s\n%s\n" 'cd ~' "/usr/local/bin/code" > environment/entrypoint; \
    chmod -v a+rx environment/*; \
    printf "%s\n%s\n%s\n%s\n" '#!/usr/bin/env bash' "code-server &" "bat -ppnl yaml ~/.config/code-server/config.yaml || cat ~/.config/code-server/config.yaml" 'printf "You can type; \033[32m%s\033[m or; \033[32m%s\033[m to start it, type; \033[32m%s\033[m to; \033[31m%s\033[m it.\n" "code" "code-server" "pkill node" "stop"' > /usr/local/bin/code; \
    chmod a+rx /usr/local/bin/code; \
    cd /root; \
    code-server --version; \
    printf "%s\n" "CODE_VERSION='$(code-server --version)'" > version.txt; \
    rm -fv '/var/cache/apt/archives/* \
    /var/cache/apt/* \
    /var/log/* \
    /var/log/apt/* \
    /var/lib/apt/lists/*' 2>/dev/null; \
    apt clean
EXPOSE 8080
CMD [ "code-server" ]
