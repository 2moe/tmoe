FROM --platform=linux/amd64 lopsided/archlinux:devel
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
WORKDIR /root
ENV HOME=/root \
    PULSE_SERVER=172.17.0.1 \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN mkdir -pv /var/cache/pacman/pkg \
    ; pacman-key --init \
    ; pacman-key --populate \
    ; pacman -Syu --noconfirm \
    ; pacman -S --noconfirm wget curl git \
    ; pacman -S --noconfirm unzip neofetch iproute \
    ; pacman -S --noconfirm systemd \
    ; export LANG=$(printf '%s\n' 'emhfQ04uVVRGLTgK' | base64 -d) \
    ; sed -i -E "s@^#*(${LANG} UTF-8)@\1@g" /etc/locale.gen \
    ; grep "^[^#]*${LANG}" /etc/locale.gen || printf "%s\n" "${LANG} UTF-8" >> /etc/locale.gen \
    ; locale-gen \
    ; export LANG=en_US.UTF-8 \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; cd /usr/local/etc/tmoe-linux \
    ; git clone --depth=1 https://github.com/2moe/tmoe-linux git || git clone --depth=1 git://github.com/2moe/tmoe-linux git \
    ; cp -fv git/tool.sh /tmp \
    ; cp -fv git/tools/sources/yay/build_fakeroot /tmp \
    ; cd /tmp \
    ; curl -LO 'https://github.com/2moe/tmoe-zsh/raw/master/zsh.sh' \
    ; bash zsh.sh --tmoe_container_automatic_configure \
    ; cd /tmp \
    ; sed -i 's@*) #main@2333)@g' tool.sh \
    ; printf "%s\n%s\n%s\n" "source /tmp/tool.sh -install-deps"  "cd /usr/local/etc/tmoe-linux/git/tools/gui/" "source gui.sh --auto-install-gui-lxde" > install-gui.sh \
    ; export AUTO_INSTALL_GUI=true \
    ; bash build_fakeroot --add-archlinuxcn-repo \
    ; bash install-gui.sh \
    ; bash build_fakeroot --build-fakeroot \
    ; bash build_fakeroot --install-yay \
    ; bash build_fakeroot --archlinux-repo-mirror \
    ; rm -rfv /tmp/* ~/.vnc/*passwd \
    ; pacman -R --noconfirm $(pacman -Qdtq) \
    ; pacman -Scc --noconfirm 

CMD [ "/usr/local/bin/startvnc" ]
