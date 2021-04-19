FROM arm32v7/debian:unstable
VOLUME /usr/bin/qemu-arm-static:/usr/bin/qemu-arm-static
WORKDIR /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    PULSE_SERVER=172.17.0.1 \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN apt update \
    ; apt dist-upgrade -y \
    ; sed -E -i 's@(configure)@pre\1@g' /var/lib/dpkg/info/libc-bin.postinst \
    ; dpkg --configure -a \
    ; apt install -y locales-all locales \
    ; apt install -y whiptail dialog aria2 zstd curl wget \
    ; apt install -y neofetch lolcat apt-utils systemd \
    ; mkdir -p /run/systemd \
    ; printf "%s\n" "docker" > /run/systemd/container \
    ; cd /tmp \
    ; curl -LO 'https://github.com/2moe/tmoe-zsh/raw/master/zsh.sh' \
    ; bash zsh.sh --tmoe_container_auto_configure \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; cd /usr/local/etc/tmoe-linux \
    ; printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=debian_gui-xfce" > container.txt  \
    ; git clone --depth=1 https://github.com/2moe/tmoe-linux git || git clone --depth=1 git://github.com/2moe/tmoe-linux git \
    ; cp -fv git/tool.sh /tmp \
    ; cd /tmp \
    ; sed -i 's@*) #main@2333)@g' tool.sh \
    ; printf "%s\n%s\n%s\n" "source /tmp/tool.sh -install-deps"  "cd /usr/local/etc/tmoe-linux/git/tools/gui/" "source gui.sh --auto-install-gui-xfce" > install-gui.sh \
    ; export AUTO_INSTALL_GUI=true \
    ; bash install-gui.sh \
    ; rm -rfv /tmp/* ~/.vnc/*passwd ~/.cache/* 2>/dev/null \
    ; apt clean

EXPOSE 5902 36080
CMD [ "/bin/zsh" ]
