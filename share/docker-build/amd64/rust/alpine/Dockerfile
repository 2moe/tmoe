FROM amd64/rust:alpine
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
ARG TMOE_DIR="/usr/local/etc/tmoe-linux"
ARG TZ_FILE="/usr/share/zoneinfo/UTC"

WORKDIR /root
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN apk update; \
    apk upgrade; \
    apk add openssl-dev musl-dev; \
    apk add sudo tar grep curl wget bash tzdata newt shadow; \
    printf "%s\n" "root:root" | chpasswd; \
    ln -svf "${TZ_FILE}" /etc/localtime; \
    rustup self update; \
    rustup update; \
    mkdir -pv ${TMOE_DIR}; \
    cd ${TMOE_DIR}; \
    printf "%s\n" \
    "CONTAINER_TYPE=podman" \
    "CONTAINER_NAME=rust_nogui-alpine" \
    > container.txt ; \
    mkdir -p environment; \
    printf "%s\n" \
    'export PATH="/usr/local/cargo/bin${PATH:+:${PATH}}"' \
    "export RUSTUP_HOME=/usr/local/rustup" \
    "export CARGO_HOME=/usr/local/cargo" \
    > environment/container.env; \
    chmod -R a+rx environment/; \
    cd /root; \
    printf "%s\n" \
    "RUSTUP_VERSION='$(rustup --version)'" \
    "CARGO_VERSION='$(cargo --version)'" \
    "RUSTC_VERSION='$(rustc --version)'" \
    > version.txt; \
    cat version.txt; \
    rm -rf /var/cache/apk/* ~/.cache/* 2>/dev/null 
#apk -v cache clean

# ENV PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     RUSTUP_HOME=/usr/local/rustup \
#     CARGO_HOME=/usr/local/cargo
CMD [ "/bin/bash" ]
