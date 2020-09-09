#!/usr/bin/env bash
####################
ubuntu_install_chromium_browser() {
    if ! grep -q '^deb.*bionic-update' "/etc/apt/sources.list"; then
        if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "i386" ]; then
            sed -i '$ a\deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
        else
            sed -i '$ a\deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
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
#####################
fix_chromium_root_no_sandbox() {
    sed -i 's/chromium %U/chromium --no-sandbox %U/g' ${APPS_LNK_DIR}/chromium.desktop
    grep 'chromium' /root/.zshrc || sed -i '$ a\alias chromium="chromium --no-sandbox"' /root/.zshrc
}
#################
install_chromium_browser() {
    echo "${YELLOW}妾身就知道你没有看走眼！${RESET}"
    echo '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium --no-sandbox"'
    echo "1s后将自动开始安装"
    sleep 1
    NON_DEBIAN='false'
    DEPENDENCY_01="chromium"
    DEPENDENCY_02="chromium-l10n"

    if [ "${LINUX_DISTRO}" = "debian" ]; then
        #新版Ubuntu是从snap商店下载chromium的，为解决这一问题，将临时换源成ubuntu 18.04LTS.
        if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
            ubuntu_install_chromium_browser
        fi
    elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
        dispatch-conf
        DEPENDENCY_01="www-client/chromium"
        DEPENDENCY_02=""
    #emerge -avk www-client/google-chrome-unstable
    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02=""
    elif [ "${LINUX_DISTRO}" = "suse" ]; then
        DEPENDENCY_02="chromium-plugin-widevinecdm chromium-ffmpeg-extra"
    fi
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
        if [ "${DEBIAN_DISTRO}" = "ubuntu" ] || [ "${LINUX_DISTRO}" = "alpine" ]; then
            fix_chromium_root_ubuntu_no_sandbox
        else
            fix_chromium_root_no_sandbox
        fi
        ;;
    n* | N*)
        echo "skipped."
        ;;
    *)
        echo "Invalid choice. skipped."
        ;;
    esac
}
############
install_firefox_esr_browser() {
    echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
    echo "${YELLOW} “谢谢您选择了我，我一定会比姐姐向您提供更好的上网服务的！”╰(*°▽°*)╯火狐ESR娘坚定地说道。 ${RESET}"
    echo "1s后将自动开始安装"
    sleep 1

    NON_DEBIAN='false'
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
        echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫姐姐来代替了。${RESET}"
        echo 'Press Enter to install firefox.'
        do_you_want_to_continue
        install_firefox_browser
    fi
}
#####################
install_firefox_browser() {
    echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
    echo " ${YELLOW}“谢谢您选择了我，我一定会比妹妹向您提供更好的上网服务的！”╰(*°▽°*)╯火狐娘坚定地说道。${RESET}"
    echo "1s后将自动开始安装"
    sleep 1
    NON_DEBIAN='false'
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
        echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫妹妹ESR来代替了。${RESET}"
        do_you_want_to_continue
        install_firefox_esr_browser
    fi
}
#####################
firefox_or_chromium() {
    if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno "建议在安装完图形界面后，再来选择哦！(　o=^•ェ•)o　┏━┓\nI am Firefox, choose me.\n我是火狐娘，选我啦！♪(^∇^*) \nI'm chrome's elder sister chromium, be sure to choose me.\n妾身是chrome娘的姐姐chromium娘，妾身和那些妖艳的货色不一样，选择妾身就没错呢！(✿◕‿◕✿)✨\n请做出您的选择！ " 15 50); then

        if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "Firefox-ESR" --yesno "I am Firefox,I have a younger sister called ESR.\n我是firefox，其实我还有个妹妹叫firefox-esr，您是选我还是选esr?\n “(＃°Д°)姐姐，我可是什么都没听你说啊！” 躲在姐姐背后的ESR瑟瑟发抖地说。\n✨请做出您的选择！ " 12 53); then
            #echo 'esr可怜巴巴地说道:“我也想要得到更多的爱。”  '
            #什么乱七八糟的，2333333戏份真多。
            install_firefox_browser
        else
            install_firefox_esr_browser
        fi
        #echo "若无法正常加载HTML5视频，则您可能需要安装火狐扩展${YELLOW}User-Agent Switcher and Manager${RESET}，并将浏览器UA修改为windows版chrome"
        #firefox将自动安装视频解码器
    else
        install_chromium_browser
    fi
}
##############
install_vivaldi_browser() {
    REPO_URL='https://vivaldi.com/zh-hans/download/'
    THE_LATEST_DEB_URL="$(curl -L ${REPO_URL} | grep deb | sed 's@ @\n@g' | grep 'deb' | grep 'amd64' | cut -d '"' -f 2 | head -n 1)"
    case ${ARCH_TYPE} in
    amd64) ;;
    i386 | arm64 | armhf) THE_LATEST_DEB_URL=$(echo ${THE_LATEST_DEB_URL} | sed "s@amd64.deb@${ARCH_TYPE}.deb@") ;;
    *) arch_does_not_support ;;
    esac

    case ${LINUX_DISTRO} in
    debian | arch) ;;
    redhat)
        case ${ARCH_TYPE} in
        amd64)
            #THE_LATEST_DEB_URL="$(curl -L ${REPO_URL} | grep rpm | sed 's@ @\n@g' | grep 'rpm' | grep 'x86_64' | cut -d '"' -f 2 | head -n 1)"
            THE_LATEST_DEB_URL=$(echo ${THE_LATEST_DEB_URL} | sed "s@_amd64.deb@.x86_64.rpm@")
            ;;
        i386)
            THE_LATEST_DEB_URL=$(echo ${THE_LATEST_DEB_URL} | sed "s@_amd64.deb@.i386.rpm@")
            ;;
        *) arch_does_not_support ;;
        esac
        ;;
    *) non_debian_function ;;
    esac
    THE_LATEST_DEB_FILE=$(echo ${THE_LATEST_DEB_URL} | awk -F '/' '{print $NF}')
    THE_LATEST_DEB_VERSION=$(echo ${THE_LATEST_DEB_FILE} | sed 's@.deb@@' | sed "s@${GREP_NAME}-stable_@@")
    check_deb_version
    echo "最新版链接为${BLUE}${THE_LATEST_DEB_URL}${RESET}"
    download_and_install_deb
}
#############
download_and_install_deb() {
    do_you_want_to_upgrade_it_02
    do_you_want_to_continue
    cd /tmp
    case ${LINUX_DISTRO} in
    debian | redhat) aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_FILE}" "${THE_LATEST_DEB_URL}" ;;
    esac
    case ${LINUX_DISTRO} in
    debian)
        apt show ./${THE_LATEST_DEB_FILE}
        apt install -y ./${THE_LATEST_DEB_FILE}
        ;;
    redhat) rpm -ivh ./${THE_LATEST_DEB_FILE} ;;
    arch) beta_features_quick_install ;;
    esac
    rm -v ./${THE_LATEST_DEB_FILE} 2>/dev/null
    echo ${THE_LATEST_DEB_VERSION} >${LOCAL_APP_VERSION_TXT}
    beta_features_install_completed
}
############
install_360_browser() {
    REPO_URL='https://aur.tuna.tsinghua.edu.cn/packages/browser360/'
    THE_LATEST_DEB_URL=$(curl -L ${REPO_URL} | grep deb | cut -d '=' -f 2 | cut -d '"' -f 2 | head -n 1)
    case ${ARCH_TYPE} in
    amd64) ;;
    arm64) THE_LATEST_DEB_URL=$(echo ${THE_LATEST_DEB_URL} | sed "s@amd64.deb@${ARCH_TYPE}.deb@") ;;
    *) arch_does_not_support ;;
    esac

    case ${LINUX_DISTRO} in
    debian) ;;
    redhat)
        case ${ARCH_TYPE} in
        amd64)
            THE_LATEST_DEB_URL=$(echo ${THE_LATEST_DEB_URL} | sed "s@_amd64.deb@.x86_64.rpm@")
            ;;
        arm64)
            THE_LATEST_DEB_URL=$(echo ${THE_LATEST_DEB_URL} | sed "s@_amd64.deb@.aarch64.rpm@")
            ;;
        *) non_debian_function ;;
        esac
        ;;
    esac
    THE_LATEST_DEB_FILE=$(echo ${THE_LATEST_DEB_URL} | awk -F '/' '{print $NF}')
    THE_LATEST_DEB_VERSION=$(echo ${THE_LATEST_DEB_FILE} | sed 's@.deb@@' | sed "s@${GREP_NAME}_@@")
    check_deb_version
    echo "最新版链接为${BLUE}${THE_LATEST_DEB_URL}${RESET}"
    download_and_install_deb
}
##############
tmoe_browser_menu() {
    RETURN_TO_WHERE='tmoe_browser_menu'
    RETURN_TO_MENU='tmoe_browser_menu'
    NON_DEBIAN='false'
    DEPENDENCY_02=""
    TMOE_APP=$(whiptail --title "Browsers" --menu \
        "Which browser do you want to install?" 0 50 0 \
        "1" "Firefox & Chromium" \
        "2" "360安全浏览器" \
        "3" "midori(轻量级,开源浏览器)" \
        "4" "vivaldi(一切皆可定制)" \
        "5" "konqueror(KDE默认浏览器,支持文件管理)" \
        "6" "Falkon(Qupzilla的前身,来自KDE,使用QtWebEngine渲染引擎)" \
        "7" "Epiphany(GNOME默认浏览器,基于Mozilla的Gecko引擎)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1)
        firefox_or_chromium
        DEPENDENCY_01=""
        ;;
    2)
        case ${LINUX_DISTRO} in
        arch) DEPENDENCY_01='browser360' ;;
        *) DEPENDENCY_01='browser360-cn-stable' ;;
        esac
        GREP_NAME='browser360-cn-stable'
        OFFICIAL_URL='https://browser.360.cn/se/linux/'
        tmoe_app_menu_01
        DEPENDENCY_01=""
        ;;
    3) DEPENDENCY_01="midori" ;;
    4)
        DEPENDENCY_01='vivaldi'
        case ${LINUX_DISTRO} in
        arch)
            case ${ARCH_TYPE} in
            arm64) DEPENDENCY_01='vivaldi-arm64' ;;
            esac
            ;;
        esac
        GREP_NAME='vivaldi'
        OFFICIAL_URL='https://vivaldi.com/download/'
        tmoe_app_menu_01
        DEPENDENCY_01=""
        ;;
    5) DEPENDENCY_01="konqueror" ;;
    6) DEPENDENCY_01="falkon" ;;
    7) DEPENDENCY_01="epiphany-browser" ;;
    esac
    ##########################
    case ${DEPENDENCY_01} in
    "") ;;
    *) beta_features_quick_install ;;
    esac
    ##############
    press_enter_to_return
    tmoe_browser_menu
}
#############
tmoe_browser_menu
