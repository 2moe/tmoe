FROM arm64v8/node:alpine
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
ADD README.js /root
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN apk update \
    ; apk upgrade \
    ; apk add sudo tar grep curl wget bash tzdata newt \
    ; ln -svf /usr/share/zoneinfo/UTC /etc/localtime \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=node_nogui-alpine" > /usr/local/etc/tmoe-linux/container.txt  \
    ; cd /root \
    ; printf "%s\n" "NODE_VERSION='$(node --version)'" > version.txt \
    ; printf "%s\n" "YARN_VERSION='$(yarn --version)'" >> version.txt \
    ; printf "%s\n" "NPM_VERSION='$(npm --version)'" >> version.txt \
    ; rm -rf /var/cache/apk/* ~/.cache/* 2>/dev/null
#apk -v cache clean
#npm i -g npm

CMD [ "node" ]
