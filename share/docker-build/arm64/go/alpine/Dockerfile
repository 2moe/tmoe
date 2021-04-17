FROM arm64v8/golang:alpine
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
ADD README.go /root
WORKDIR /go
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN apk update \
    ; apk upgrade \
    ; apk add sudo tar grep curl wget bash tzdata newt \
    ; ln -svf /usr/share/zoneinfo/UTC /etc/localtime \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=go_nogui-alpine" > /usr/local/etc/tmoe-linux/container.txt  \
    ; rm -rf /var/cache/apk/* ~/.cache/* 2>/dev/null
#apk -v cache clean

CMD [ "/bin/bash" ]