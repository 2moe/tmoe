FROM amd64/golang:alpine
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
ADD README.go /root
ENV HOME=/go \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN apk update \
    ; apk upgrade \
    ; apk add tar grep curl wget zstd bash tzdata newt \
    ; ln -svf /usr/share/zoneinfo/UTC /etc/localtime \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; printf "%s\n" "podman" > /usr/local/etc/tmoe-linux/container.txt  \
    ; rm -rf /var/cache/apk/* ~/.cache/* 2>/dev/null \
    ; apk -v cache clean

CMD [ "/bin/bash" ]