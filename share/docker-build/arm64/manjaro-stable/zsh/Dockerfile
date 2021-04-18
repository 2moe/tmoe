FROM abyo/manjaro_aarch64:latest
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
WORKDIR /root
ENV HOME=/root \
    PULSE_SERVER=172.17.0.1 \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN mkdir -pv /var/cache/pacman/pkg \
    ; pacman-key --init \
    ; pacman-key --populate \
    ; pacman -Syu --noconfirm --needed base base-devel \
    ; pacman -S --noconfirm --needed wget curl git \
    ; pacman -S --noconfirm --needed unzip neofetch man-db man-pages systemd 2>/dev/null \
    ; mkdir -pv /run/systemd \
    ; printf "%s\n" "docker" > /run/systemd/container \
    ; export LANG=$(printf '%s\n' 'emhfQ04uVVRGLTgK' | base64 -d) \
    ; sed -i -E "s@^#*(${LANG} UTF-8)@\1@g" /etc/locale.gen \
    ; sed -i -E "s@^#*(en_US.UTF-8 UTF-8)@\1@g" /etc/locale.gen \
    ; grep "^[^#]*${LANG}" /etc/locale.gen || printf "%s\n" "${LANG} UTF-8" >> /etc/locale.gen \
    ; locale-gen \
    ; sed -i "s@^${LANG} UTF-8@#&@" /etc/locale.gen \
    ; export LANG=en_US.UTF-8 \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; cd /usr/local/etc/tmoe-linux \
    ; printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=manjaro_nogui-zsh" > container.txt  \
    ; git clone --depth=1 https://github.com/2moe/tmoe-linux git || git clone --depth=1 git://github.com/2moe/tmoe-linux git \
    ; cp -fv git/tool.sh /tmp \
    ; cp -fv git/tools/sources/yay/build_fakeroot /tmp \
    ; cd /tmp \
    ; curl -LO 'https://github.com/2moe/tmoe-zsh/raw/master/zsh.sh' \
    ; bash zsh.sh --tmoe_container_auto_configure \
    ; cd /tmp \
    ; sed -i 's@*) #main@2333)@g' tool.sh \
    ; bash build_fakeroot --add-archlinuxcn-repo \
    ; bash build_fakeroot --build-fakeroot \
    ; bash build_fakeroot --install-yay \
    ; bash build_fakeroot --archlinux-repo-mirror \    
    ; rm -rfv /tmp/* ~/.vnc/*passwd \
    ; pacman -R --noconfirm $(pacman -Qdtq) \
    ; rm -rfv /var/cache/pacman/pkg/* ~/.cache/* 2>/dev/null \
    ; pacman -Scc --noconfirm 

CMD [ "/bin/zsh" ]
