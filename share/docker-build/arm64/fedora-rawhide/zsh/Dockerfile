FROM arm64v8/fedora:rawhide
#VOLUME /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static
WORKDIR /root

ARG DNF_RC=/etc/dnf/dnf.conf

# If you want to have sound, manually bind pulse or other audio server sockets and set environment variables.
# PULSE_SERVER="unix:/tmp/pulse/native"

ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true

# sed -i.bak -E 's@^(gpgcheck)=.*@\1=0@g' /etc/yum.repos.d/*.repo; \

RUN sed -E -e 's@^(gpgcheck)=.*@\1=0@g' \
    -e '$a\fastestmirror=True' \
    -e '$a\max_parallel_downloads=3' \
    -i ${DNF_RC}; \
    cat ${DNF_RC}; \
    yes | dnf update -y; \
    dnf install -y --skip-broken glibc-all-langpacks glibc-minimal-langpack iproute lolcat newt systemd dnf-utils passwd findutils man-db procps-ng procps-ng-i18n tar hostname neofetch; \
    dnf install -y --skip-broken newt aria2 zstd curl wget; \
    printf "%s\n" "root:root" | chpasswd; \
    mkdir -p /run/systemd; \
    printf "%s\n" "docker" > /run/systemd/container; \
    cd /tmp; \
    curl -LO 'https://github.com/2cd/zsh/raw/master/zsh.sh' || exit 1; \
    bash zsh.sh --tmoe_container_auto_configure; \
    mkdir -pv /usr/local/etc/tmoe-linux; \
    cd /usr/local/etc/tmoe-linux; \
    printf "%s\n%s\n" "CONTAINER_TYPE=podman" "CONTAINER_NAME=fedora_nogui-zsh" > container.txt ; \
    git clone -b master --depth=1 https://github.com/2moe/tmoe-linux git || git clone -b master --depth=1 git://github.com/2moe/tmoe-linux git; \
    cp -fv git/share/old-version/tools/app/tool /tmp/docker_tool ; \
    cd /tmp; \
    sed -i 's@*) #main@2333)@g' docker_tool; \
    dnf update -y; \
    rm -rfv /tmp/* ~/.vnc/*passwd ~/.cache/* 2>/dev/null; \
    dnf clean all

CMD [ "/bin/zsh" ]
