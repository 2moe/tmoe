FROM arm64v8/ruby:alpine
#VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
RUN apk update; \
    apk upgrade; \
    apk add sudo tar grep curl wget bash tzdata newt shadow; \
    printf "%s\n" "root:root" | chpasswd; \
    ln -svf /usr/share/zoneinfo/UTC /etc/localtime; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n" \
    "CONTAINER_TYPE=podman" \
    "CONTAINER_NAME=ruby_nogui-alpine" \
    > container.txt ; \
    mkdir -p environment; \
    printf "%s\n" \
    'export PATH="/usr/local/bundle/bin${PATH:+:${PATH}}"' \
    "export GEM_HOME=/usr/local/bundle" \
    "export BUNDLE_SILENCE_ROOT_WARNING=1"\
    "export BUNDLE_APP_CONFIG=/usr/local/bundle" \
    > environment/container.env; \
    printf "%s\n" \
    'cd ~' \
    "irb" \
    > environment/entrypoint; \
    chmod -R a+rx environment/; \
    gem install webrick; \
    cd /root; \
    printf "%s\n" "RUBY_VERSION='$(ruby --version)'" \
    "GEM_VERSION='$(gem --version)'" \
    "BUNDLE_VERSION='$(bundle --version)'" \
    > version.txt; \
    cat version.txt; \
    rm -rfv \
    /var/cache/apk/* \
    ~/.cache/* \
    2>/dev/null
#apk -v cache clean

# ENV PATH=/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
#     GEM_HOME=/usr/local/bundle \
#     BUNDLE_SILENCE_ROOT_WARNING=1 \
#     BUNDLE_APP_CONFIG=/usr/local/bundle
CMD [ "irb" ]
