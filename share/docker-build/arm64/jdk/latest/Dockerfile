FROM arm64v8/openjdk:jdk-slim
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN apt update; \
    apt dist-upgrade -y; \
    dpkg --configure -a; \
    apt install -y sudo locales curl; \
    apt install -y whiptail eatmydata procps apt-utils; \
    apt install -y --no-install-recommends neofetch; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=openjdk_nogui-debian" > container.txt ; \
    mkdir -p environment; \
    JAVA_DIR=$(command -v java); \
    JAVA_PATH=${JAVA_DIR%/*}; \
    printf "%s\n%s\n" "export PATH=\"${JAVA_PATH}\${PATH:+:\${PATH}}\"" "export JAVA_HOME=${JAVA_HOME}" > environment/container.env; \
    printf "%s\n%s\n" 'cd ~' "jshell" > environment/entrypoint; \
    chmod -R a+rx environment/; \
    cd /root; \
    printf "%s\n%s\n" "JAVA_VERSION='$(java --version)'" "JAVAC_VERSION='$(javac --version)'" > version.txt; \
    cat version.txt; \
    apt clean
CMD [ "jshell" ]
