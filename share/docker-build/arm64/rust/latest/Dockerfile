FROM arm64v8/debian:unstable
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
ARG TMOE_DIR="/usr/local/etc/tmoe-linux"

WORKDIR /root
ARG DEBIAN_FRONTEND=noninteractive
ARG RUSTUP_URL="https://static.rust-lang.org/rustup/dist/aarch64-unknown-linux-gnu/rustup-init"

ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN apt update; \
    apt dist-upgrade -y; \
    dpkg --configure -a; \
    apt install -y pkg-config libssl-dev; \
    apt install -y sudo locales; \
    apt install -y whiptail curl eatmydata procps apt-utils; \
    apt install \
    -y \
    --no-install-recommends \
    neofetch \
    gcc \
    libc6-dev; \
    printf "%s\n" "root:root" | chpasswd; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    curl -LO ${RUSTUP_URL} || exit 1 ; \
    chmod +x rustup-init; \
    ./rustup-init \
    -y \
    --no-modify-path \
    --default-toolchain \
    nightly; \
    rm rustup-init; \
    chmod -Rv a+w ${RUSTUP_HOME} ${CARGO_HOME}; \
    mkdir -pv ${TMOE_DIR}; \
    cd ${TMOE_DIR}; \
    printf "%s\n" \
    "CONTAINER_TYPE=podman" \
    "CONTAINER_NAME=rust_nogui-debian" \
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
    rm -fv /var/cache/apt/archives/* \
    /var/cache/apt/* \
    /var/mail/* \
    /var/log/* \
    /var/log/apt/* \
    /var/log/journal/* \
    /var/lib/apt/lists/* \
    2>/dev/null; \
    apt clean
# rustup default nightly

CMD [ "/bin/bash" ]
