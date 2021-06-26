FROM arm64v8/rust:latest
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
WORKDIR /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN apt update; \
    apt dist-upgrade -y; \
    dpkg --configure -a; \
    apt install -y sudo locales; \
    apt install -y whiptail curl eatmydata procps apt-utils; \
    apt install -y --no-install-recommends neofetch; \
    printf "%s\n" "root:root" | chpasswd; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    rustup self update; \
    rustup update; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=rust_nogui-debian" > container.txt ; \
    mkdir -p environment; \
    printf "%s\n%s\n%s\n" 'export PATH="/usr/local/cargo/bin${PATH:+:${PATH}}"' "export RUSTUP_HOME=/usr/local/rustup" "export CARGO_HOME=/usr/local/cargo" > environment/container.env; \
    chmod -R a+rx environment/; \
    cd /root; \
    printf "%s\n" "RUSTUP_VERSION='$(rustup --version)'" > version.txt; \
    printf "%s\n" "CARGO_VERSION='$(cargo --version)'" >> version.txt; \
    printf "%s\n" "RUSTC_VERSION='$(rustc --version)'" >> version.txt; \
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
# rustup default stable
# ENV PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     RUSTUP_HOME=/usr/local/rustup \
#     CARGO_HOME=/usr/local/cargo

CMD [ "/bin/bash" ]
