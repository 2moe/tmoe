FROM arm64v8/nginx:alpine
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
WORKDIR /root
ADD README.txt /root
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN apk update; \
    apk upgrade; \
    apk add sudo tar grep curl wget bash tzdata newt; \
    ln -svf /usr/share/zoneinfo/UTC /etc/localtime; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=nginx_nogui-alpine" > container.txt ; \
    mkdir -p environment; \
    printf "%s\n%s\n" 'cd ~' "nginx -g 'daemon off;'" > environment/entrypoint; \
    chmod -R a+rx environment/; \
    cd /root; \
    printf "%s\n" "NGINX_VERSION='${NGINX_VERSION}'" > version.txt; \
    printf "%s\n" "NJS_VERSION='${NJS_VERSION}'" >> version.txt; \
    printf "%s\n" "PKG_RELEASE='${PKG_RELEASE}'" >> version.txt; \
    cat version.txt; \
    rm -rf /var/cache/apk/* ~/.cache/* 2>/dev/null 
#apk -v cache clean

CMD ["nginx", "-g", "daemon off;"]
