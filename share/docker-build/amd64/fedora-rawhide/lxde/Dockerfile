FROM amd64/fedora:rawhide
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
WORKDIR /root
ENV HOME=/root \
    PULSE_SERVER=172.17.0.1 \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN dnf update -y \
    ; dnf install -y --skip-broken glibc-all-langpacks glibc-minimal-langpack iproute lolcat newt systemd dnf-utils passwd findutils man-db procps-ng procps-ng-i18n tar hostname neofetch \
    ; dnf install -y --skip-broken newt aria2 zstd curl wget systemd \
    ; mkdir -p /run/systemd \
    ; printf "%s\n" "docker" > /run/systemd/container \
    ; cd /tmp \
    ; curl -LO 'https://github.com/2moe/tmoe-zsh/raw/master/zsh.sh' \
    ; bash zsh.sh --tmoe_container_auto_configure \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; cd /usr/local/etc/tmoe-linux \
    ; git clone --depth=1 https://github.com/2moe/tmoe-linux git || git clone --depth=1 git://github.com/2moe/tmoe-linux git \
    ; cp -fv git/tool.sh /tmp \
    ; cd /tmp \
    ; sed -i 's@*) #main@2333)@g' tool.sh \
    ; printf "%s\n%s\n%s\n" "source /tmp/tool.sh -install-deps"  "cd /usr/local/etc/tmoe-linux/git/tools/gui/" "source gui.sh --auto-install-gui-lxde" > install-gui.sh \
    ; export AUTO_INSTALL_GUI=true \
    ; bash install-gui.sh \
    ; dnf update -y \
    ; rm -rfv /tmp/* ~/.vnc/*passwd \
    ; dnf clean all

CMD [ "/usr/local/bin/startvnc" ]
