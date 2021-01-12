FROM archlinux:base-devel
#VOLUME /usr/bin/qemu-x86_64-static:/usr/bin/qemu-x86_64-static
#先添加archlinuxcn源，待安装完成后，再来安装yay,并重新编译fakeroot
WORKDIR /root
ENV HOME=/root \
    TMOE_PROOT=false \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true
#RUN sed -i '1a Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist \
RUN pacman -Syu --noconfirm \
    ; pacman -S --noconfirm wget \
    ; cd /tmp \
    ; curl -LO 'https://github.com/2moe/tmoe-zsh/raw/master/zsh.sh' \
    ; bash zsh.sh --tmoe_container_automatic_configure \
    ; mkdir -pv /usr/local/etc/tmoe-linux \
    ; cd /usr/local/etc/tmoe-linux \
    ; git clone --depth=1 https://github.com/2moe/tmoe-linux git || git clone --depth=1 git://github.com/2moe/tmoe-linux git \
    ; cp -fv git/tool.sh /tmp \
    ; cd /tmp \
    ; sed -i 's@*) #main@2333)@g' tool.sh \
    ; printf "%s\n%s\n%s\n" "source /tmp/tool.sh -install-deps"  "cd /usr/local/etc/tmoe-linux/git/tools/gui/" "source gui.sh --auto-install-gui-lxde" > install-gui.sh \
    ; bash install-gui.sh
CMD [ "/bin/bash" ]
