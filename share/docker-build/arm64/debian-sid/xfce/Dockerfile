FROM arm64v8/debian:unstable
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
WORKDIR /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    PULSE_SERVER=172.17.0.1 \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
#RUN sed -i "s@deb.debian.org@mirrors.bfsu.edu.cn@g" /etc/apt/sources.list \
#    ; apt update \
RUN apt update \
    ; apt dist-upgrade -y \
    ; apt install -y locales-all locales \
    ; apt install -y whiptail dialog aria2 zstd curl wget \
    ; apt install -y neofetch lolcat apt-utils \
    ; cd /tmp \
    ; curl -LO 'https://github.com/2moe/tmoe-zsh/raw/master/zsh.sh' \
    ; bash zsh.sh --tmoe_container_automatic_configure \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; cd /usr/local/etc/tmoe-linux \
    ; git clone --depth=1 https://github.com/2moe/tmoe-linux git || git clone --depth=1 git://github.com/2moe/tmoe-linux git \
    ; cp -fv git/tool.sh /tmp \
    ; cd /tmp \
    ; sed -i 's@*) #main@2333)@g' tool.sh \
    ; printf "%s\n%s\n%s\n" "source /tmp/tool.sh -install-deps"  "cd /usr/local/etc/tmoe-linux/git/tools/gui/" "source gui.sh --auto-install-gui-xfce" > install-gui.sh \
    ; bash install-gui.sh \
    ; rm -rfv /tmp/* /tmp/.* ~/.vnc/x11passwd ~/.vnc/passwd \
    ; apt clean \
    ; apt autoclean \
    ; apt autopurge -y 

CMD [ "/usr/local/bin/startvnc" ]
