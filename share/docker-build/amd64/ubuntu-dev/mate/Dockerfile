FROM scratch
ADD ubuntu.tar /
#FROM amd64/ubuntu:devel 
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
WORKDIR /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    PULSE_SERVER=172.17.0.1 \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN apt update; \
    apt dist-upgrade -y; \
    dpkg --configure -a; \
    apt install -y locales-all locales; \
    apt install -y whiptail dialog aria2 zstd curl wget; \
    apt install -y --no-install-recommends neofetch lolcat unzip; \
    apt install -y apt-utils software-properties-common systemd procps; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    cd /tmp; \
    curl -LO 'https://github.com/2cd/zsh/raw/master/zsh.sh'; \
    bash zsh.sh --tmoe_container_auto_configure; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=ubuntu_gui-mate" > container.txt ; \
    git clone -b master --depth=1 https://github.com/2moe/tmoe-linux git || git clone -b master --depth=1 git://github.com/2moe/tmoe-linux git; \
    cp -fv git/share/old-version/tools/app/tool /tmp/docker_tool ; \
    cd /tmp; \
    sed -i 's@*) #main@2333)@g' docker_tool; \
    printf "%s\n%s\n%s\n" "source /tmp/docker_tool -install-deps"  "cd /usr/local/etc/tmoe-linux/git/share/old-version/tools/gui/" "source gui --auto-install-gui-mate" > install-gui.sh; \
    export AUTO_INSTALL_GUI=true; \
    bash install-gui.sh; \
    rm -rfv /tmp/* ~/.vnc/*passwd ~/.cache/* 2>/dev/null; \
    rm -fv '/var/cache/apt/archives/* \
    /var/cache/apt/* \
    /var/log/* \
    /var/log/apt/* \
    /var/lib/apt/lists/*' 2>/dev/null; \
    apt clean

EXPOSE 5902 36080
CMD [ "/bin/zsh" ]
