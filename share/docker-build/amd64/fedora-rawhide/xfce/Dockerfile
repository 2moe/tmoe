FROM amd64/fedora:rawhide
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
WORKDIR /root
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN dnf update -y \
    ; dnf install -y --skip-broken glibc-all-langpacks glibc-minimal-langpack iproute lolcat newt systemd dnf-utils passwd findutils man-db procps-ng procps-ng-i18n tar hostname neofetch \
    ; dnf install -y newt aria2 zstd curl wget \
    ; cd /tmp \
    ; curl -LO 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh' \
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
    ; dnf clean all

CMD [ "/bin/bash" ]