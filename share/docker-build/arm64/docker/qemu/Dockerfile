FROM arm64v8/debian:experimental
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
ADD README.rb /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true \
    BLK_DEVICE="VIRTIO_DISK_01" \
    RTC_BASE=utc \
    GPU_MODEL=virtio-vga \
    QEMU_NAME="arch_x64-tmoe-202105" \
    QEMU_FILE="/usr/local/etc/tmoe-linux/qemu/list/arch_x64-tmoe-202105" \
    TMOE_FILE_ABSOLUTE_PATH="/opt/qemu-img/arch_x64-tmoe-202105.qcow2" \
    QEMU_IMAGE_REPO=arch-qemu-image
# sed -E -i 's@(configure)@pre\1@g' /var/lib/dpkg/info/libc-bin.postinst; \
RUN apt update; \
    apt dist-upgrade -y; \
    dpkg --configure -a; \
    apt install -y sudo locales xz-utils git aptitude; \
    yes | apt install -t experimental qemu-system-x86 qemu-system-gui -y; \
    apt install -y whiptail curl eatmydata apt-utils procps iproute2; \
    apt install -y --no-install-recommends neofetch nano lolcat; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    mkdir -pv /opt/qemu-img; \
    cd /opt/qemu-img; \
    URL="https://github.com/2moe/${QEMU_IMAGE_REPO}/releases/download/latest/qcow2.tar.xz"; \
    curl -LO "${URL}" || curl -Lo qcow2.tar.xz "${URL}"; \
    tar -Jxvf qcow2.tar.xz; \
    rm -fv qcow2.tar.xz; \
    cd /tmp; \
    mkdir -pv /usr/local/etc/tmoe-linux/qemu/list; \
    cd /usr/local/etc/tmoe-linux; \
    git clone -b master --depth=1 https://github.com/2moe/tmoe-linux git || git clone -b master --depth=1 git://github.com/2moe/tmoe-linux git; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=docker_nogui-qemu" > container.txt ; \
    mkdir -p environment; \
    printf "%s\n%s\n" 'cd ~' "${QEMU_FILE}" > environment/entrypoint; \
    chmod -v a+rx environment/*; \
    cp -vf ${PWD}/git/share/old-version/tools/virtualization/qemu/startqemu ${QEMU_FILE}; \
    chmod -v 777 ${QEMU_FILE}; \
    sed -E -e "s@^(QEMU_NAME=).*@\1${QEMU_NAME}@g"; \
    -e "s@^(RTC_BASE=).*@\1${RTC_BASE}@g"; \
    -e "s@^(GPU_MODEL=).*@\1${GPU_MODEL}@g"; \
    -e "s@^(NET_CARD_02_ENABLED=).*@\1false@g"; \
    -e "s@^(NET_CARD_03_ENABLED=).*@\1false@g"; \
    -e "s@^(SOUND_CARD_02_ENABLED=).*@\1false@g"; \
    -e "s@^(SOUND_CARD_ENABLED=).*@\1false@g"; \
    -e "s@^(${BLK_DEVICE}=).*@\1"${TMOE_FILE_ABSOLUTE_PATH}"@g;s@^(${BLK_DEVICE}_ENABLED=).*@\1true@g"; \
    -i ${QEMU_FILE}; \
    egrep --color=auto "^QEMU_NAME=|^${BLK_DEVICE}_ENABLED=|^${BLK_DEVICE}=|^RTC_BASE=|^GPU_MODEL=" ${QEMU_FILE}; \
    ln -svf ${QEMU_FILE} /usr/local/bin/startqemu; \
    ln -svf ${QEMU_FILE} /usr/local/bin/startvnc; \
    cd /root; \
    mkdir Downloads; \
    ln -svf /opt/qemu-img ${PWD}/Downloads; \
    ln -svf ${QEMU_FILE} ${PWD}/startqemu; \
    yes | apt dist-upgrade -t experimental -y || yes | aptitude full-upgrade -t experimental -y; \
    printf "%s\n" "QEMU_VERSION='$(qemu-system-x86_64 --version)'" > version.txt; \
    apt autopurge -y; \
    rm -fv /etc/apt/sources.list.d/experimental.list; \
    rm -fv '/var/cache/apt/archives/* \
    /var/cache/apt/* \
    /var/log/* \
    /var/log/apt/* \
    /var/lib/apt/lists/*' 2>/dev/null; \
    apt clean
EXPOSE 5905
CMD [ "startqemu" ]
