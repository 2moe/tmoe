FROM arm64v8/rust:alpine
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
WORKDIR /root
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN apk update \
    ; apk upgrade \
    ; apk add sudo tar grep curl wget bash tzdata newt \
    ; ln -svf /usr/share/zoneinfo/UTC /etc/localtime \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=rust_nogui-alpine" > /usr/local/etc/tmoe-linux/container.txt  \
    ; cd /root \
    ; printf "%s\n" "RUSTUP_VERSION='$(rustup --version)'" > version.txt \
    ; printf "%s\n" "CARGO_VERSION='$(cargo --version)'" >> version.txt \
    ; printf "%s\n" "RUSTC_VERSION='$(rustc --version)'" >> version.txt \
    ; cat version.txt \
    ; rm -rf /var/cache/apk/* ~/.cache/* 2>/dev/null 
#apk -v cache clean

# ENV PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     RUSTUP_HOME=/usr/local/rustup \
#     CARGO_HOME=/usr/local/cargo
CMD [ "/bin/bash" ]