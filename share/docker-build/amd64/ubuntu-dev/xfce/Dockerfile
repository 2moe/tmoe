FROM amd64/ubuntu:devel
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
SHELL [ "/bin/bash" ]
WORKDIR /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
#RUN sed -i "s@archive.ubuntu.com@mirrors.bfsu.edu.cn@g" /etc/apt/sources.list \
#    ; apt update \
RUN apt update \
    ; apt dist-upgrade -y \
    ; apt install -y locales-all \
    ; apt install -y whiptail dialog aria2 zstd curl wget \
    ; cd /tmp \
    ; curl -LO 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh' \
    ; bash zsh.sh --tmoe_container_automatic_configure \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; cd /usr/local/etc/tmoe-linux \
    ; git clone --depth=1 https://github.com/2moe/tmoe-linux git || git clone --depth=1 git://github.com/2moe/tmoe-linux git \
    ; cp -fv git/tool.sh /tmp \
    ; cd /tmp \
    ; sed -i 's@*) #main@2333)@g' tool.sh \
    ; printf "%s\n%s\n%s\n" "source /tmp/tool.sh -install-deps"  "cd /usr/local/etc/tmoe-linux/git/tools/gui/" "source gui.sh --auto-install-gui-lxde" > install-gui.sh \
    ; bash install-gui.sh \
    ; rm -rfv /tmp/* /tmp/.* \
    ; apt clean \
    ; apt autopurge -y 

CMD [ "/bin/bash" ]