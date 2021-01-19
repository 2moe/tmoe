FROM arm64v8/alpine:edge
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
ENV HOME=/root \
    PULSE_SERVER=172.17.0.1 \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN apk update \
    ; apk upgrade \
    ; apk add tar grep curl wget zstd bash tzdata newt git \
    ; ln -svf /usr/share/zoneinfo/UTC /etc/localtime \
    ; cd /tmp \
    ; curl -LO 'https://github.com/2moe/tmoe-zsh/raw/master/zsh.sh' \
    ; bash zsh.sh --tmoe_container_automatic_configure \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; cd /usr/local/etc/tmoe-linux \
    ; git clone --depth=1 https://github.com/2moe/tmoe-linux git || git clone --depth=1 git://github.com/2moe/tmoe-linux git \
    ; cp -fv git/tool.sh /tmp \
    ; cd /tmp \
    ; sed -i 's@*) #main@2333)@g' tool.sh \
    ; printf "%s\n%s\n%s\n" "source /tmp/tool.sh -install-deps"  "cd /usr/local/etc/tmoe-linux/git/tools/gui/" "source gui.sh --auto-install-gui-kde" > install-gui.sh \
    ; export AUTO_INSTALL_GUI=true \
    ; bash install-gui.sh \
    ; rm -rfv /tmp/* ~/.vnc/*passwd

CMD [ "/usr/local/bin/startx11vnc" ]