FROM amd64/ruby:latest
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
ARG DEBIAN_FRONTEND=noninteractive
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

RUN apt update \
    ; apt dist-upgrade -y \
    ; dpkg --configure -a \
    ; apt install -y sudo locales \
    ; apt install -y whiptail curl eatmydata apt-utils \
    ; apt install -y --no-install-recommends neofetch \
    ; mkdir -p /run/systemd \
    ; printf "%s\n" "docker" > /run/systemd/container \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=ruby_nogui-debian" > /usr/local/etc/tmoe-linux/container.txt  \
    ; cd /root \
    ; printf "%s\n" "RUBY_VERSION='$(ruby --version)'" > version.txt \
    ; apt clean
# ENV PATH=/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     RUBY_MAJOR=3.0 \
#     GEM_HOME=/usr/local/bundle \
#     BUNDLE_SILENCE_ROOT_WARNING=1 \
#     BUNDLE_APP_CONFIG=/usr/local/bundle

CMD [ "irb" ]
