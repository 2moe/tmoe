FROM scratch
ADD arch.tar /
VOLUME /usr/bin/qemu-arm-static:/usr/bin/qemu-arm-static

# If you want to have sound, manually bind pulse or other audio server sockets and set environment variables.
# PULSE_SERVER="unix:/tmp/pulse/native"

WORKDIR /root
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN mkdir -pv /var/cache/pacman/pkg; \
    pacman-key --init; \
    pacman-key --populate; \
    pacman -Syu --noconfirm base base-devel; \
    pacman -S --noconfirm systemd; \
    pacman -S --noconfirm --needed wget curl git; \
    pacman -S --noconfirm --needed unzip neofetch iproute man-db man-pages 2>/dev/null; \
    printf "%s\n" "root:root" | chpasswd; \
    mkdir -pv /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    export LANG=$(printf '%s\n' 'emhfQ04uVVRGLTgK' | base64 -d); \
    sed -i -E "s@^#*(${LANG} UTF-8)@\1@g" /etc/locale.gen; \
    sed -i -E "s@^#*(en_US.UTF-8 UTF-8)@\1@g" /etc/locale.gen; \
    grep "^[^#]*${LANG}" /etc/locale.gen || printf "%s\n" "${LANG} UTF-8" >> /etc/locale.gen; \
    locale-gen; \
    sed -i "s@^${LANG} UTF-8@#&@" /etc/locale.gen; \
    export LANG=en_US.UTF-8; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=arch_gui-xfce" > container.txt ; \
    git clone -b master --depth=1 https://github.com/2moe/tmoe-linux git || git clone -b master --depth=1 git://github.com/2moe/tmoe-linux git; \
    cp -fv git/share/old-version/tools/app/tool /tmp/docker_tool ; \
    cp -fv git/share/old-version/tools/sources/yay/build_fakeroot /tmp; \
    cd /tmp; \
    curl -LO 'https://github.com/2cd/zsh/raw/master/zsh.sh' || exit 1; \
    bash zsh.sh --tmoe_container_auto_configure; \
    cd /tmp; \
    sed -i 's@*) #main@2333)@g' docker_tool; \
    printf "%s\n%s\n%s\n" "source /tmp/docker_tool -install-deps"  "cd /usr/local/etc/tmoe-linux/git/share/old-version/tools/gui/" "source gui --auto-install-gui-xfce" > install-gui.sh; \
    export AUTO_INSTALL_GUI=true; \
    chmod a+rx -v build_fakeroot; \
    ./build_fakeroot --add-arch_for_edu-repo; \
    ./build_fakeroot --add-archlinuxcn-repo; \
    bash install-gui.sh; \
    ./build_fakeroot --install-yay; \
    ./build_fakeroot --install-fakeroot; \
    ./build_fakeroot --archlinux-repo-mirror; \
    cat /etc/pacman.conf; \
    rm -rfv /tmp/* ~/.vnc/*passwd; \
    pacman -R --noconfirm $(pacman -Qdtq); \
    rm -rfv /var/cache/pacman/pkg/* ~/.cache/* 2>/dev/null; \
    pacman -Scc --noconfirm

EXPOSE 5902 36080
CMD [ "/bin/zsh" ]
