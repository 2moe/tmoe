#!/usr/bin/env bash
#####################
install_dxvk() {
    DEPENDENCY_01='dxvk'
    DEPENDENCY_02='wine-development'
    beta_features_quick_install
    dxvk-setup i -s || dxvk-setup i -d
    dxvk-setup
}
###########
install_wine64() {
    # INSTALL_WINE=true
    DEPENDENCY_01='wine'
    DEPENDENCY_02='wine64'
    beta_features_quick_install
    case "${ARCH_TYPE}" in
    "i386") ;;
    *)
        cat <<-'EOF'
			如需完全卸载wine，那么您还需要移除i386架构的软件包。
			aptitude remove ~i~ri386
			dpkg  --remove-architecture i386
			apt update
		EOF
        ;;
    esac
}
#########
import_wine_hq_key() {
    if [ ! $(command -v gpg) ]; then
        apt install -y gpg
    fi
    curl https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor >winehq.gpg
    sudo install -o root -g root -m 644 winehq.gpg /usr/share/keyrings/winehq-archive-keyring.gpg
    printf "%s\n" "deb [signed-by=/usr/share/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/${WINE_DISTRO}/ ${VERSION_CODENAME} main" >/etc/apt/sources.list.d/wine-hq.list
    ls -lah /usr/share/keyrings/winehq-archive-keyring.gpg /etc/apt/sources.list.d/wine-hq.list
    sudo rm winehq.gpg
}
type_your_debian_version() {
    unset TARGET
    TARGET=$(whiptail --inputbox "请输入debian/ubuntu版本代号，例如bookworm(英文小写)\nPlease type the debian/ubuntu version code." 9 50 --title "DEBIAN/UBUNTU CODE" 3>&1 1>&2 2>&3)
    if [ -z "${TARGET}" ]; then
        printf "%s\n" "ERROR, the value is empty."
        press_enter_to_return
        check_debian_version_codename
    else
        VERSION_CODENAME=${TARGET}
    fi
}
install_libfaudio0_deb() {
    GREP_NAME="libfaudio0_"
    THE_LATEST_DEB_VERSION="$(curl -L ${THE_LATEST_DEB_REPO} | grep -Ev '\.dsc|\.tar\.xz' | grep 'deb' | awk -F '<a href=' '{print $2}' | grep ${GREP_NAME} | grep deb | tail -n 1 | cut -d '"' -f 2)"
    FULL_URL="${THE_LATEST_DEB_REPO}/${THE_LATEST_DEB_VERSION}"
    printf "%s\n" "${YELLOW}${FULL_URL}${RESET}"
    curl -Lo libfaudio0.deb ${FULL_URL}
    apt install -y ./libfaudio0.deb || dpkg -i ./libfaudio0.deb
    rm -fv ./libfaudio0.deb
}
install_libfaudio0() {
    cd /tmp
    case ${ARCH_TYPE} in
    amd64)
        dpkg --add-architecture i386
        apt update
        WINE_ARCH=${ARCH_TYPE}
        install_libfaudio0_deb
        WINE_ARCH=i386
        case ${VERSION_CODENAME} in
        buster) THE_LATEST_DEB_REPO="https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/${WINE_ARCH}" ;;
        bionic) THE_LATEST_DEB_REPO="https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/${WINE_ARCH}" ;;
        esac
        install_libfaudio0_deb
        ;;
    i386)
        WINE_ARCH=${ARCH_TYPE}
        install_libfaudio0_deb
        ;;
    *)
        printf "%s\n" "${RED}ERROR${RESET}, you are using ${BLUE}${ARCH_TYPE}${RESET}, 架构${PURPLE}不支持${RESET}"
        do_you_want_to_continue
        WINE_ARCH=i386
        install_libfaudio0_deb
        ;;
    esac

}
check_debian_version_codename() {
    VERSION_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2 | head -n 1)
    [[ -n ${VERSION_CODENAME} ]] || VERSION_CODENAME=$(grep VERSION_CODENAME /etc/os-release | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | awk -F ' ' '$0=$NF' | cut -d '/' -f 1 | cut -d '(' -f 2 | cut -d ')' -f 1)
    if (whiptail --title "VERSION" --yesno "您当前的版本是否为${VERSION_CODENAME}?" 8 50); then
        printf ""
    else
        type_your_debian_version
    fi
    case ${ARCH_TYPE} in
    amd64 | i386) WINE_ARCH=${ARCH_TYPE} ;;
    *) WINE_ARCH=i386 ;;
    esac
    cd /tmp
    case ${VERSION_CODENAME} in
    buster)
        THE_LATEST_DEB_REPO="https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/${WINE_ARCH}"
        install_libfaudio0
        ;;
    bionic)
        THE_LATEST_DEB_REPO="https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/${WINE_ARCH}"
        install_libfaudio0
        ;;
    esac
}
install_winehq() {
    case ${DEBIAN_DISTRO} in
    ubuntu) WINE_DISTRO=ubuntu ;;
    *) WINE_DISTRO=debian ;;
    esac
    check_debian_version_codename
    import_wine_hq_key
    apt update
    apt show ${WINE_VERSION}
    printf "%s\n" "${GREEN}dpkg ${YELLOW}--add-architecture ${BLUE}i386"
    printf "%s\n" "${GREEN}apt ${YELLOW}install --install-recommends -y ${BLUE}${WINE_VERSION}${RESET}"
    do_you_want_to_continue
    dpkg --add-architecture i386
    DEPENDENCY_01="${WINE_VERSION}"
    DEPENDENCY_02=""
    beta_features_quick_install
}
install_wine32() {
    if [ ! $(command -v apt-get) ]; then
        printf "%s\n" "${RED}Sorry${RESET}, please go to the official website."
        printf "${YELLOW}%s${RESET}\n" "https://www.winehq.org/"
        press_enter_to_return
        wine_menu
    fi
    unset WINE_VERSION
    RETURN_TO_WHERE='install_wine32'
    VIRTUAL_TECH=$(
        whiptail --title "WINE-HQ(i386)" --menu "安装wine-hq需要添加对i386的支持，以下三者任选一个即可。" 0 50 0 \
            "1" "Devel 开发版" \
            "2" "Staging" \
            "3" "Stable 稳定版" \
            "0" "🌚 Back 返回" \
            3>&1 1>&2 2>&3
    )
    #############
    case ${VIRTUAL_TECH} in
    0 | "") wine_menu ;;
    1) WINE_VERSION="winehq-devel" ;;
    2) WINE_VERSION="winehq-staging" ;;
    3) WINE_VERSION="winehq-stable" ;;
    esac
    ###############
    [[ -z ${WINE_VERSION} ]] || install_winehq
    press_enter_to_return
    wine_menu
}
#########
install_winetricks() {
    DEPENDENCY_01='winetricks zenity'
    DEPENDENCY_02='winetricks-zh'
    beta_features_quick_install
}
install_q4wine() {
    DEPENDENCY_01='q4wine'
    DEPENDENCY_02=''
    beta_features_quick_install
}
install_play_on_linux() {
    DEPENDENCY_01='playonlinux'
    DEPENDENCY_02=''
    case "${LINUX_DISTRO}" in
    "arch") DEPENDENCY_02='playonlinux5-git' ;;
    esac
    beta_features_quick_install
}
wine_menu() {
    RETURN_TO_WHERE='wine_menu'
    VIRTUAL_TECH=$(
        whiptail --title "WINE" --menu "Wine is not an emulator" 0 50 0 \
            "1" "winehq/wine32(本体)" \
            "2" "wine64(可选)" \
            "3" "winetricks(wine辅助配置工具)" \
            "4" "q4wine(qt图形界面wine前端)" \
            "5" "play on linux(图形化wine前端)" \
            "6" "remove卸载wine32" \
            "7" "wine-dxvk(将DirectX转换为Vulkan api)" \
            "8" "wine-wechat微信" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    #############
    case ${VIRTUAL_TECH} in
    0 | "") install_container_and_virtual_machine ;;
    1) install_wine32 ;;
    2) install_wine64 ;;
    3) install_winetricks ;;
    4) install_q4wine ;;
    5) install_play_on_linux ;;
    6) remove_wine_bin ;;
    7) install_dxvk ;;
    8) install_wine_wechat ;;
    esac
    ###############
    press_enter_to_return
    wine_menu
}
##########
remove_wine_bin() {
    case "${ARCH_TYPE}" in
    "i386") ;;
    *)
        printf '%s\n' '正在移除对i386软件包的支持 ...'
        printf "%s\n" "aptitude remove ~i~ri386"
        printf '%s\n' 'dpkg  --remove-architecture i386'
        printf "%s\n" "It will remove all i386 packages."
        do_you_want_to_continue
        #apt purge ".*:i386"
        aptitude remove ~i~ri386
        dpkg --remove-architecture i386
        apt update
        ;;
    esac
    # INSTALL_WINE=false
    # wine_dependencies
    DEPENDENCY_01='wine winetricks q4wine libfaudio0'
    DEPENDENCY_02='playonlinux wine32'
    DEPENDENCY_03='winehq-devel winehq-staging winehq-stable'
    printf "%s\n" "${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${DEPENDENCY_03}"
    do_you_want_to_continue
    for i in /etc/apt/sources.list.d/wine-hq.list /usr/share/keyrings/winehq-archive-keyring.gpg; do
        [[ ! -e ${i} ]] || rm -fv ${i}
    done
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01}
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_02}
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_03}
}
############
install_wine_wechat() {
    cat <<-'EOF'
		url: https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe
		微信安装包将下载至/tmp目录
		若安装失败，请手动执行wine /tmp/WeChatSetup.exe
		建议您在安装完成后执行winecfg,并选择“函数库”.接着添加riched20，最后选择"原装先于内建"。
	EOF
    do_you_want_to_continue
    cd /tmp
    if [ ! -e "/tmp/WeChatSetup.exe" ]; then
        aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o WeChatSetup.exe 'https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe'
    fi
    case ${HOME} in
    /root)
        wine /tmp/WeChatSetup.exe
        winetricks riched20
        winecfg
        ;;
    *)
        sudo -iu ${CURRENT_USER_NAME} wine /tmp/WeChatSetup.exe
        sudo -iu ${CURRENT_USER_NAME} winetricks riched20
        sudo -iu ${CURRENT_USER_NAME} winecfg
        ;;
    esac
}
################
wine_menu
