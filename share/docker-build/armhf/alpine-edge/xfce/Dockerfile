FROM arm32v7/alpine:edge
VOLUME /usr/bin/qemu-arm-static:/usr/bin/qemu-arm-static

# If you want to have sound, manually bind pulse or other audio server sockets and set environment variables.
# PULSE_SERVER="unix:/tmp/pulse/native"

ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN apk update; \
    apk upgrade; \
    apk add tar grep curl wget zstd bash tzdata newt shadow git; \
    printf "%s\n" "root:root" | chpasswd; \
    ln -svf /usr/share/zoneinfo/UTC /etc/localtime; \
    cd /tmp; \
    curl -LO 'https://github.com/2cd/zsh/raw/master/zsh.sh' || exit 1; \
    bash zsh.sh --tmoe_container_auto_configure; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=alpine_gui-xfce" > container.txt; \
    git clone -b master --depth=1 https://github.com/2moe/tmoe-linux git || git clone -b master --depth=1 git://github.com/2moe/tmoe-linux git; \
    cp -fv git/share/old-version/tools/app/tool /tmp/docker_tool ; \
    cd /tmp; \
    sed -i 's@*) #main@2333)@g' docker_tool; \
    printf "%s\n%s\n%s\n" "source /tmp/docker_tool -install-deps"  "cd /usr/local/etc/tmoe-linux/git/share/old-version/tools/gui/" "source gui --auto-install-gui-xfce" > install-gui.sh; \
    export AUTO_INSTALL_GUI=true; \
    bash install-gui.sh; \
    rm -rf /var/cache/apk/* ~/.cache/* 2>/dev/null; \
    rm -rfv /tmp/* ~/.vnc/*passwd
#apk -v cache clean
EXPOSE 5902 36080
CMD [ "/bin/zsh" ]
