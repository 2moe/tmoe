#!/usr/bin/env bash
####################
ubuntu_install_chromium_browser() {
    if ! grep -q '^deb.*bionic-update' "/etc/apt/sources.list"; then
        if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "i386" ]; then
            sed -i '$ a\deb https://mirrors.bfsu.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
        else
            sed -i '$ a\deb https://mirrors.bfsu.edu.cn/ubuntu-ports/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
        fi
    fi
    DEPENDENCY_01="chromium-browser/bionic-updates"
    DEPENDENCY_02="chromium-browser-l10n/bionic-updates"
}
#########
fix_chromium_root_ubuntu_no_sandbox() {
    sed -i 's/chromium-browser %U/chromium-browser --no-sandbox %U/g' ${APPS_LNK_DIR}/chromium-browser.desktop
    grep 'chromium-browser' /root/.zshrc || sed -i '$ a\alias chromium="chromium-browser --no-sandbox"' /root/.zshrc
}
fix_chromium_root_alpine_no_sandbox() {
    sed -i 's/chromium-browser %U/chromium-browser --no-sandbox %U/g' ${APPS_LNK_DIR}/chromium.desktop
    grep 'chromium-browser' /root/.zshrc || sed -i '$ a\alias chromium="chromium-browser --no-sandbox"' /root/.zshrc
}
#####################
fix_chromium_root_no_sandbox() {
    sed -i 's/chromium %U/chromium --no-sandbox %U/g' ${APPS_LNK_DIR}/chromium.desktop
    grep 'chromium' /root/.zshrc || sed -i '$ a\alias chromium="chromium --no-sandbox"' /root/.zshrc
}
#################
install_chromium_browser() {
    printf "%s\n" "${YELLOW}妾身就知道你没有看走眼！${RESET}"
    printf '%s\n' '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium --no-sandbox"'
    printf "%s\n" "1s后将自动开始安装"
    sleep 1

    DEPENDENCY_01="chromium"
    DEPENDENCY_02="chromium-l10n"
    #chromium-chromedriver

    case "${LINUX_DISTRO}" in
    debian)
        #新版Ubuntu是从snap商店下载chromium的，为解决这一问题，将临时换源成ubuntu 18.04LTS.
        if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
            ubuntu_install_chromium_browser
        fi
        ;;
    gentoo)
        dispatch-conf
        DEPENDENCY_01="www-client/chromium"
        DEPENDENCY_02=""
        #emerge -avk www-client/google-chrome-unstable
        ;;
    arch) DEPENDENCY_02="" ;;
    suse) DEPENDENCY_02="chromium-plugin-widevinecdm chromium-ffmpeg-extra" ;;
    redhat) DEPENDENCY_02="fedora-chromium-config" ;;
    alpine) DEPENDENCY_02="" ;;
    esac
    beta_features_quick_install
    #####################
    if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
        sed -i '$ d' "/etc/apt/sources.list"
        apt-mark hold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg-extra
        apt update
    fi
    ####################
    do_you_want_to_close_the_sandbox_mode
    read opt
    case $opt in
    y* | Y* | "")
        case ${LINUX_DISTRO} in
        debian)
            case "${DEBIAN_DISTRO}" in
            ubuntu) fix_chromium_root_ubuntu_no_sandbox ;;
            *) fix_chromium_root_no_sandbox ;;
            esac
            ;;
        redhat) fix_chromium_root_ubuntu_no_sandbox ;;
        alpine) fix_chromium_root_alpine_no_sandbox ;;
        *) fix_chromium_root_no_sandbox ;;
        esac
        ;;
    n* | N*)
        printf "%s\n" "skipped."
        ;;
    *)
        printf "%s\n" "Invalid choice. skipped."
        ;;
    esac
}
############
install_firefox_esr_browser() {
    printf '%s\n' 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
    printf "%s\n" "${YELLOW} “谢谢您选择了我，我一定会比姐姐向您提供更好的上网服务的！”╰(*°▽°*)╯火狐ESR娘坚定地说道。 ${RESET}"
    printf "%s\n" "1s后将自动开始安装"
    sleep 1

    DEPENDENCY_01="firefox-esr"
    DEPENDENCY_02="firefox-esr-l10n-zh-cn"

    if [ "${LINUX_DISTRO}" = "debian" ]; then
        if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
            add-apt-repository -y ppa:mozillateam/ppa
            DEPENDENCY_02="firefox-esr-locale-zh-hans ffmpeg"
            #libavcodec58
        fi
        #################
    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02="firefox-esr-i18n-zh-cn"
    elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
        dispatch-conf
        DEPENDENCY_01='www-client/firefox'
        DEPENDENCY_02=""
    elif [ "${LINUX_DISTRO}" = "suse" ]; then
        DEPENDENCY_01="MozillaFirefox-esr"
        DEPENDENCY_02="MozillaFirefox-esr-translations-common"
    fi
    beta_features_quick_install
    #################
    if [ ! $(command -v firefox) ] && [ ! $(command -v firefox-esr) ]; then
        printf "%s\n" "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫姐姐来代替了。${RESET}"
        printf '%s\n' 'Press Enter to install firefox.'
        do_you_want_to_continue
        install_firefox_browser
    fi
}
#####################
install_firefox_browser() {
    printf '%s\n' 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
    printf "%s\n" " ${YELLOW}“谢谢您选择了我，我一定会比妹妹向您提供更好的上网服务的！”╰(*°▽°*)╯火狐娘坚定地说道。${RESET}"
    printf "%s\n" "1s后将自动开始安装"
    sleep 1

    DEPENDENCY_01="firefox"
    DEPENDENCY_02="firefox-l10n-zh-cn"

    if [ "${LINUX_DISTRO}" = "debian" ]; then
        if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
            DEPENDENCY_02="firefox-locale-zh-hans ffmpeg"
        fi
    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02="firefox-i18n-zh-cn"
    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        DEPENDENCY_02="firefox-x11"
    elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
        dispatch-conf
        DEPENDENCY_01="www-client/firefox-bin"
        DEPENDENCY_02=""
    elif [ "${LINUX_DISTRO}" = "suse" ]; then
        DEPENDENCY_01="MozillaFirefox"
        DEPENDENCY_02="MozillaFirefox-translations-common"
    fi
    beta_features_quick_install
    ################
    if [ ! $(command -v firefox) ]; then
        printf "%s\n" "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫妹妹ESR来代替了。${RESET}"
        do_you_want_to_continue
        install_firefox_esr_browser
    fi
}
#####################
firefox_or_chromium() {
    if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno "建议在安装完图形界面后，再来选择哦！(　o=^•ェ•)o　┏━┓\nI am Firefox, choose me.\n我是火狐娘，选我啦！♪(^∇^*) \nI'm chrome's elder sister chromium, be sure to choose me.\n妾身是chrome娘的姐姐chromium娘，妾身和那些妖艳的货色不一样，选择妾身就没错呢！(✿◕‿◕✿)✨\n请做出您的选择！ " 15 50); then

        if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "Firefox-ESR" --yesno "I am Firefox,I have a younger sister called ESR.\n我是firefox，其实我还有个妹妹叫firefox-esr，您是选我还是选esr?\n “(＃°Д°)姐姐，我可是什么都没听你说啊！” 躲在姐姐背后的ESR瑟瑟发抖地说。\n✨请做出您的选择！ " 12 53); then
            #printf '%s\n' 'esr可怜巴巴地说道:“我也想要得到更多的爱。”  '
            #什么乱七八糟的，2333333戏份真多。
            install_firefox_browser
        else
            install_firefox_esr_browser
        fi
        #printf "%s\n" "若无法正常加载HTML5视频，则您可能需要安装火狐扩展${YELLOW}User-Agent Switcher and Manager${RESET}，并将浏览器UA修改为windows版chrome"
        #firefox将自动安装视频解码器
    else
        install_chromium_browser
        printf "%s\n" "如需拖拽安装插件，则请在启动命令后加上 --enable-easy-off-store-extension-install"
    fi
}
##############
install_vivaldi_browser() {
    REPO_URL='https://vivaldi.com/zh-hans/download/'
    THE_LATEST_DEB_URL="$(curl -L ${REPO_URL} | grep deb | sed 's@ @\n@g' | grep 'deb' | grep 'amd64' | cut -d '"' -f 2 | head -n 1)"
    case ${ARCH_TYPE} in
    amd64) ;;
    i386 | arm64 | armhf) THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@amd64.deb@${ARCH_TYPE}.deb@") ;;
    *) arch_does_not_support ;;
    esac

    case ${LINUX_DISTRO} in
    debian | arch) ;;
    redhat)
        case ${ARCH_TYPE} in
        amd64)
            #THE_LATEST_DEB_URL="$(curl -L ${REPO_URL} | grep rpm | sed 's@ @\n@g' | grep 'rpm' | grep 'x86_64' | cut -d '"' -f 2 | head -n 1)"
            THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@${DEPENDENCY_01}_@${DEPENDENCY_01}-@" | sed "s@_amd64.deb@.x86_64.rpm@")
            ;;
        i386)
            THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@${DEPENDENCY_01}_@${DEPENDENCY_01}-@" | sed "s@_amd64.deb@.i386.rpm@")
            ;;
        *) arch_does_not_support ;;
        esac
        ;;
    esac
    #) non_debian_function ;;
    THE_LATEST_DEB_FILE=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | awk -F '/' '{print $NF}')
    THE_LATEST_DEB_VERSION=$(printf '%s\n' "${THE_LATEST_DEB_FILE}" | sed 's@.deb@@' | sed "s@${DEPENDENCY_01}-@@" | sed "s@vivaldi-stable_@@")
    check_deb_version
    download_and_install_deb
    rm -v /etc/apt/sources.list.d/vivaldi.list 2>/dev/null
    cd ${APPS_LNK_DIR}
    if ! grep -q 'vivaldi-stable --no-sandbox' vivaldi-stable.desktop; then
        do_you_want_to_close_the_sandbox_mode
        do_you_want_to_continue
        sed -i 's@Exec=/usr/bin/vivaldi-stable@& --no-sandbox@g' vivaldi-stable.desktop
        cat vivaldi-stable.desktop | grep --color=auto 'no-sandbox'
    fi
}
#############
install_360_browser() {
    REPO_URL='https://aur.tuna.tsinghua.edu.cn/packages/browser360/'
    THE_LATEST_DEB_URL=$(curl -L ${REPO_URL} | grep deb | cut -d '=' -f 2 | cut -d '"' -f 2 | head -n 1)
    case ${ARCH_TYPE} in
    amd64) ;;
    arm64) THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@amd64.deb@arm64.deb@") ;;
    *) arch_does_not_support ;;
    esac
    #https://down.360safe.com/gc/browser360-cn-stable_12.2.1070.0-1_amd64.deb
    #http://down.360safe.com/gc/browser360-cn-stable-10.2.1005.3-1.aarch64.rpm

    case ${LINUX_DISTRO} in
    debian | arch) ;;
    redhat)
        case ${ARCH_TYPE} in
        amd64)
            THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed 's@stable_@stable-@' | sed 's@12.2.1070.0-1@10.2.1005.3-1@' | sed "s@_amd64.deb@.x86_64.rpm@")
            ;;
        arm64)
            THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed 's@stable_@stable-@' | sed 's@12.2.1070.0-1@10.2.1005.3-1@' | sed "s@_arm64.deb@.aarch64.rpm@")
            ;;
        esac
        ;;
    esac
    #) non_debian_function ;;
    THE_LATEST_DEB_FILE=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | awk -F '/' '{print $NF}')
    THE_LATEST_DEB_VERSION=$(printf '%s\n' "${THE_LATEST_DEB_FILE}" | sed 's@.deb@@' | sed "s@${GREP_NAME}-@@" | sed "s@${GREP_NAME}_@@")
    check_deb_version
    download_and_install_deb
}
##############
install_microsoft_edge_debian() {
    cd /tmp
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo su -c 'printf "%s\n" "deb https://packages.microsoft.com/repos/edge stable main" >/etc/apt/sources.list.d/microsoft-edge-dev.list'
    sudo rm microsoft.gpg
    sudo apt update
    sudo apt install microsoft-edge-dev
}
install_microsoft_edge_redhat() {
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
    sudo mv /etc/yum.repos.d/packages.microsoft.com_yumrepos_edge.repo /etc/yum.repos.d/microsoft-edge-dev.repo
    sudo dnf install microsoft-edge-dev
}
install_microsoft_edge_suse() {
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo zypper ar https://packages.microsoft.com/yumrepos/edge microsoft-edge-dev
    sudo zypper refresh
    sudo zypper install microsoft-edge-dev
}
install_microsoft_edge_arch() {
    beta_features_quick_install
}
install_microsoft_edge() {
    cat <<-'EOF'
Package: microsoft-edge-dev
Priority: optional
Section: web
Installed-Size: 301311
Maintainer: Microsoft Edge for Linux Team
Architecture: amd64
Provides: www-browser
Depends: ca-certificates, fonts-liberation, libasound2 (>= 1.0.16), libatk-bridge2.0-0 (>= 2.5.3), libatk1.0-0 (>= 2.2.0), libatomic1 (>= 4.8), libatspi2.0-0 (>= 2.9.90), libc6 (>= 2.16), libcairo2 (>= 1.6.0), libcups2 (>= 1.4.0), libdbus-1-3 (>= 1.5.12), libdrm2 (>= 2.4.38), libexpat1 (>= 2.0.1), libgbm1 (>= 8.1~0), libgcc1 (>= 1:3.0), libgdk-pixbuf2.0-0 (>= 2.22.0), libglib2.0-0 (>= 2.39.4), libgtk-3-0 (>= 3.9.10), libnspr4 (>= 2:4.9-2~), libnss3 (>= 2:3.22), libpango-1.0-0 (>= 1.14.0), libuuid1 (>= 2.16), libx11-6 (>= 2:1.4.99.1), libx11-xcb1, libxcb1 (>= 1.9.2), libxcomposite1 (>= 1:0.3-1), libxdamage1 (>= 1:1.1), libxext6, libxfixes3, libxkbcommon0 (>= 0.4.1), libxrandr2, wget, xdg-utils (>= 1.0.2)
Pre-Depends: dpkg (>= 1.14.0)
Recommends: libu2f-udev, libvulkan1
Description: The web browser from Microsoft
 Microsoft Edge is a browser that combines a minimal design with sophisticated technology to make the web faster, safer, and easier.
EOF

    printf "%s\n" "If you can not download edge browser,then go to microsoft official website."
    printf "${YELLOW}%s${RESET}\n" "https://www.microsoftedgeinsider.com/download"
    printf "%s'n" "If you are a ${RED}root user${RESET},try to run ${GREEN}microsoft-edge-dev --no-sandbox${RESET} to open it."
    printf "${PURPLE}%s${RESET}\n" "Do you want to install microsoft-edge-dev?"
    do_you_want_to_continue
    case ${LINUX_DISTRO} in
    debian) install_microsoft_edge_debian ;;
    redhat) install_microsoft_edge_redhat ;;
    arch) install_microsoft_edge_arch ;;
    suse) install_microsoft_edge_suse ;;
    *)
        beta_features_quick_install
        printf "%s\n" "Sorry, it does not s-
        upport your system."
        ;;
    esac
}
############
remove_microsoft_edge() {
    printf "${RED}%s ${BLUE}%s${RESET}\n" "${TMOE_REMOVAL_COMMAND}" "${DEPENDENCY_02}"
    do_you_want_to_continue
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_02}
    case ${LINUX_DISTRO} in
    debian)
        rm -vf /etc/apt/sources.list.d/microsoft-edge-dev.list
        apt update
        ;;
    redhat) rm -vf /etc/yum.repos.d/microsoft-edge-dev.repo ;;
    suse) zypper removerepo microsoft-edge-dev ;;
    *) ;;
    esac
}
##########
microsoft_edge_menu() {
    DEPENDENCY_01=''
    DEPENDENCY_02='microsoft-edge-dev'
    case ${ARCH_TYPE} in
    amd64) TMOE_TIPS_02="You are using amd64 architecture,enjoy the fun experience brought by edge." ;;
    *) TMOE_TIPS_02="You are using ${ARCH_TYPE} architecture, please switch to amd64." ;;
    esac

    if (whiptail --title "Do you want to install or remove edge?" --yes-button "install安装" --no-button "remove移除" --yesno "Microsoft Edge is a cross-platform web browser developed by Microsoft.\n${TMOE_TIPS_02}" 10 50); then
        install_microsoft_edge
    else
        remove_microsoft_edge
    fi
}
##############
tmoe_browser_menu() {
    RETURN_TO_WHERE='tmoe_browser_menu'
    RETURN_TO_MENU='tmoe_browser_menu'
    DEPENDENCY_02=""
    TMOE_APP=$(whiptail --title "Browsers" --menu \
        "Which browser do you want to install?" 0 50 0 \
        "1" "Mozilla Firefox & Google Chromium" \
        "2" "Microsoft Edge(x64,享受出色的浏览体验)" \
        "3" "Falkon(Qupzilla的前身,来自KDE,使用QtWebEngine)" \
        "4" "Vivaldi(一切皆可定制)" \
        "5" "360安全浏览器(arm64,x64)" \
        "6" "Epiphany(GNOME默认浏览器,基于Mozilla的Gecko)" \
        "7" "Midori(轻量级,开源浏览器)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1)
        firefox_or_chromium
        DEPENDENCY_01=""
        ;;
    2) microsoft_edge_menu ;;
    3)
        DEPENDENCY_01="falkon"
        restore_debian_gnu_libxcb_so
        ;;
    4)
        DEPENDENCY_01='vivaldi-stable'
        case ${LINUX_DISTRO} in
        arch)
            case ${ARCH_TYPE} in
            amd64) DEPENDENCY_01='vivaldi' ;;
            arm64) DEPENDENCY_01='vivaldi-arm64' ;;
            esac
            ;;
        esac
        GREP_NAME='vivaldi'
        OFFICIAL_URL='https://vivaldi.com/download/'
        tmoe_app_menu_01
        DEPENDENCY_01=""
        ;;
    5)
        case ${LINUX_DISTRO} in
        arch) DEPENDENCY_01='browser360' ;;
        *) DEPENDENCY_01='browser360-cn-stable' ;;
        esac
        GREP_NAME='browser360-cn-stable'
        OFFICIAL_URL='https://browser.360.cn/se/linux/'
        tmoe_app_menu_01
        DEPENDENCY_01=""
        ;;
    6) DEPENDENCY_01="epiphany-browser" ;;
    7) DEPENDENCY_01="midori" ;;
    esac
    #    5) DEPENDENCY_01="konqueror" ;;
    #    "5" "konqueror(KDE默认浏览器,支持文件管理)" \
    ##########################
    case ${DEPENDENCY_01} in
    "") ;;
    falkon)
        beta_features_quick_install
        cd ${APPS_LNK_DIR}
        if ! grep -q 'falkon --no-sandbox' org.kde.falkon.desktop; then
            do_you_want_to_close_the_sandbox_mode
            do_you_want_to_continue
            sed -i 's@Exec=falkon@& --no-sandbox@g' org.kde.falkon.desktop
            cat org.kde.falkon.desktop | grep --color=auto 'no-sandbox'
        fi
        ;;
    *) beta_features_quick_install ;;
    esac
    ##############
    press_enter_to_return
    tmoe_browser_menu
}
#############
tmoe_browser_menu
