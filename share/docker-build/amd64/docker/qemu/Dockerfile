FROM amd64/debian:sid
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
ADD README.rb /root
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true \
    BLK_DEVICE="VIRTIO_DISK_01" \
    RTC_BASE=utc \
    GPU_MODEL=virtio-vga \
    QEMU_NAME="alpine_x64-tmoe-202011" \
    QEMU_FILE="/usr/local/etc/tmoe-linux/qemu/list/alpine_x64-tmoe-202011" \
    TMOE_FILE_ABSOLUTE_PATH="/opt/qemu-img/alpine_x64-tmoe_202011.qcow2"

RUN apt update \
    ; apt dist-upgrade -y \
    ; dpkg --configure -a \
    ; apt install -y sudo locales qemu-system-x86 qemu-system-gui xz-utils git git-lfs \
    ; apt install -y whiptail curl eatmydata apt-utils procps \
    ; apt install -y --no-install-recommends neofetch nano lolcat \
    ; mkdir -p /run/systemd \
    ; printf "%s\n" "docker" > /run/systemd/container \
    ; mkdir /opt/qemu-img \
    ; cd /opt/qemu-img \
    ; git lfs clone --depth=1 -b master https://github.com/2moe/alpine-qemu-image.git || git lfs clone --depth=1 git://github.com/2moe/alpine-qemu-image.git \
    ; cd alpine-qemu-image \
    ; tar -Jxvf qcow2.tar.xz \
    ; mv *.qcow2 .. \
    ; cd .. \
    ; rm -rfv alpine-qemu-image \
    ; cd /tmp \
    ; mkdir -pv /usr/local/etc/tmoe-linux/qemu/list \
    ; cd /usr/local/etc/tmoe-linux \
    ; git clone --depth=1 -b master https://github.com/2moe/tmoe-linux git || git clone --depth=1 git://github.com/2moe/tmoe-linux git \
    ; printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=docker-nogui_qemu" > container.txt  \
    ; mkdir -p environment \
    ; printf "%s\n" "${QEMU_FILE}" > environment/entrypoint \
    ; chmod -v a+x environment/* \
    ; cp -vf ${PWD}/git/tools/virtualization/qemu/startqemu ${QEMU_FILE} \
    ; chmod -v 777 ${QEMU_FILE} \
    ; sed -E -e "s@^(QEMU_NAME=).*@\1${QEMU_NAME}@g" \
    -e "s@^(RTC_BASE=).*@\1${RTC_BASE}@g" \
    -e "s@^(GPU_MODEL=).*@\1${GPU_MODEL}@g" \
    -e "s@^(NET_CARD_02_ENABLED=).*@\1false@g" \
    -e "s@^(NET_CARD_03_ENABLED=).*@\1false@g" \
    -e "s@^(${BLK_DEVICE}=).*@\1"${TMOE_FILE_ABSOLUTE_PATH}"@g;s@^(${BLK_DEVICE}_ENABLED=).*@\1true@g" \
    -i ${QEMU_FILE} \
    ; egrep --color=auto "^QEMU_NAME=|^${BLK_DEVICE}_ENABLED=|^${BLK_DEVICE}=|^RTC_BASE=|^GPU_MODEL=" ${QEMU_FILE} \
    ; ln -svf ${QEMU_FILE} /usr/local/bin/startqemu \
    ; ln -svf ${QEMU_FILE} /usr/local/bin/startvnc \
    ; cd /root \
    ; mkdir Downloads \
    ; ln -svf /opt/qemu-img ${PWD}/Downloads \
    ; ln -svf ${QEMU_FILE} ${PWD}/startqemu \
    ; apt clean
EXPOSE 5905
CMD [ "startqemu" ]
