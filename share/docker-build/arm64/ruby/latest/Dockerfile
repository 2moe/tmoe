FROM arm64v8/ruby:latest
VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
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
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=ruby_nogui-debian" > container.txt ; \
    mkdir -p environment; \
    printf "%s\n%s\n%s\n%s\n" 'export PATH="/usr/local/bundle/bin${PATH:+:${PATH}}"' "export GEM_HOME=/usr/local/bundle" "export BUNDLE_SILENCE_ROOT_WARNING=1" "export BUNDLE_APP_CONFIG=/usr/local/bundle" > environment/container.env; \
    printf "%s\n%s\n" 'cd ~' "irb" > environment/entrypoint; \
    chmod -R a+rx environment/; \
    gem install webrick; \
    cd /root; \
    printf "%s\n" "RUBY_VERSION='$(ruby --version)'" > version.txt; \
    printf "%s\n" "GEM_VERSION='$(gem --version)'" >> version.txt; \
    printf "%s\n" "BUNDLE_VERSION='$(bundle --version)'" >> version.txt; \
    cat version.txt; \
    apt clean
# ENV PATH=/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; \
#     GEM_HOME=/usr/local/bundle; \
#     BUNDLE_SILENCE_ROOT_WARNING=1; \
#     BUNDLE_APP_CONFIG=/usr/local/bundle

CMD [ "irb" ]
