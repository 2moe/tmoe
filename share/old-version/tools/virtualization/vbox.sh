#!/usr/bin/env bash
#####################
debian_add_virtual_box_gpg() {
    if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
        VBOX_RELEASE='focal'
    else
        VBOX_RELEASE='buster'
    fi
    curl -L 'https://www.virtualbox.org/download/oracle_vbox_2016.asc' | gpg --dearmor >/tmp/oracle_vbox_2016.gpg
    install -o root -g root -m 644 /tmp/oracle_vbox_2016.gpg /usr/share/keyrings/oracle_vbox_2016-archive-keyring.gpg
    cd /etc/apt/sources.list.d/
    sed -i 's/deb /# &/g' virtualbox.list
    printf "%s\n" "deb [signed-by=/usr/share/keyrings/oracle_vbox_2016-archive-keyring.gpg] http://mirrors.bfsu.edu.cn/virtualbox/apt/ ${VBOX_RELEASE} contrib" >>virtualbox.list
}
###############
get_debian_vbox_latest_url() {
    TUNA_VBOX_LINK='https://mirrors.bfsu.edu.cn/virtualbox/apt/pool/contrib/v/'
    LATEST_VBOX_VERSION=$(curl -L ${TUNA_VBOX_LINK} | grep 'virtualbox-' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)

    if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
        DOCKER_RELEASE='Ubuntu'
    else
        DOCKER_RELEASE='Debian'
    fi

    DOCKER_TUNA_CODE_LIST=$(curl -L ${TUNA_VBOX_LINK}${LATEST_VBOX_VERSION} | grep ${DOCKER_RELEASE} | grep link | awk -F 'title=' '{print $2}' | cut -d '"' -f 2 | sed 's@\.deb@@')
    DOCKER_LIST=$(printf "%s\n" $DOCKER_TUNA_CODE_LIST | sed "s@\$@ .deb@g" | tr '\n' ' ')
    LATEST_VBOX_FILE=$(
        whiptail --title "DISTRO CODE & VBOX VERSION" --menu \
            "Which version do you want to choose?" 0 0 0 \
            ${DOCKER_LIST} \
            "Back" "🌚 返回" \
            3>&1 1>&2 2>&3
    )
    VBOX_DEB_FILE_URL="${TUNA_VBOX_LINK}${LATEST_VBOX_VERSION}${LATEST_VBOX_FILE}.deb"
    printf "%s\n" "获取到vbox的最新链接为${VBOX_DEB_FILE_URL},是否下载并安装？"
    RETURN_TO_WHERE='beta_features'
    do_you_want_to_continue
    cd /tmp
    curl -Lo .Oracle_VIRTUAL_BOX.deb "${VBOX_DEB_FILE_URL}"
    apt-cache show ./.Oracle_VIRTUAL_BOX.deb
    apt install -y ./.Oracle_VIRTUAL_BOX.deb
    rm -fv ./.Oracle_VIRTUAL_BOX.deb
}
################
install_debian_virtual_box() {
    if [ ! $(command -v virtualbox) ]; then
        get_debian_vbox_latest_url
    else
        printf "%s\n" "检测到您已安装virtual box，是否将其添加到软件源？"
        RETURN_TO_WHERE='beta_features'
        do_you_want_to_continue
        debian_add_virtual_box_gpg
    fi
}
#############
install_virtual_box_qt() {
    DEPENDENCY_01="virtualbox-qt"
    DEPENDENCY_02="virtualbox-ext-pack"
    beta_features_quick_install
}
##############
debian_download_latest_vbox_deb() {
    if (whiptail --title "VirtualBox" --yes-button 'virtualbox-qt' --no-button 'virtualbox' --yesno "Which software do you want to install?" 0 50); then
        install_virtual_box_qt
    else
        install_debian_virtual_box
    fi
}
#############
redhat_add_virtual_box_repo() {
    cat >/etc/yum.repos.d/virtualbox.repo <<-'EndOFrepo'
		[virtualbox]
		name=Virtualbox Repository
		baseurl=https://mirrors.bfsu.edu.cn/virtualbox/rpm/el$releasever/
		gpgcheck=0
		enabled=1
	EndOFrepo
}
################
install_virtual_box() {
    case "${ARCH_TYPE}" in
    "amd64") ;;
    *) arch_does_not_support ;;
    esac

    if [ ! $(command -v gpg) ]; then
        DEPENDENCY_01="gpg"
        DEPENDENCY_02="gnupg"
        beta_features_quick_insta
        #linux-headers
    fi
    DEPENDENCY_02="virtualbox-qt"
    DEPENDENCY_01="virtualbox"
    #apt remove docker docker-engine docker.io
    printf "%s\n" "If you find some problems, then run ${RED}sudo ${GREEN}chown -Rv ${YELLOW}$CURRENT_USER_NAME:$CURRENT_USER_GROUP ${PURPLE}~/.config/VirtualBox${RESET}${RESET}, see this ${BLUE}issue: ${YELLOW}https://gitee.com/mo2/linux/issues/I4TTND${RESET}"
    press_enter_to_continue
    if [ "${LINUX_DISTRO}" = 'debian' ]; then
        debian_download_latest_vbox_deb
    #$(#lsb_release -cs)
    elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
        redhat_add_virtual_box_repo
    elif [ "${LINUX_DISTRO}" = 'arch' ]; then
        DEPENDENCY_01="virtualbox virtualbox-guest-iso"
        DEPENDENCY_02="virtualbox-ext-oracle"
        printf "%s\n" "您可以在安装完成后，输usermod -G vboxusers -a 当前用户名称"
        printf "%s\n" "将当前用户添加至vboxusers用户组"
    fi
    printf "%s\n" "您可以输modprobe vboxdrv vboxnetadp vboxnetflt来加载内核模块"
    beta_features_quick_install
    if [ "${LINUX_DISTRO}" = 'arch' ]; then
        printf "%s\n" "usermod -G vboxusers -a ${CURRENT_USER_NAME}"
        do_you_want_to_continue
        usermod -G vboxusers -a ${CURRENT_USER_NAME}
    fi
    ####################
    if [ ! $(command -v virtualbox) ]; then
        printf "%s\n" "检测到virtual box安装失败，是否将其添加到软件源？"
        RETURN_TO_WHERE='beta_features'
        do_you_want_to_continue
        debian_add_virtual_box_gpg
        beta_features_quick_install
    fi
}
###################
install_virtual_box
