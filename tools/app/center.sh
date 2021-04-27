#!/usr/bin/env bash
####################
remove_browser() {
    if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno '火狐娘:“虽然知道总有离别时，但我没想到这一天竟然会这么早。虽然很不舍，但还是很感激您曾选择了我。希望我们下次还会再相遇，呜呜...(;´༎ຶД༎ຶ`)”chromium娘：“哼(￢︿̫̿￢☆)，负心人，走了之后就别回来了！o(TヘTo) 。”  ✨请做出您的选择！' 10 60); then
        printf '%s\n' '呜呜...我...我才...才不会为了这点小事而流泪呢！ヽ(*。>Д<)o゜'
        printf "%s\n" "${YELLOW}按回车键确认卸载firefox${RESET}"
        printf '%s\n' 'Press enter to remove firefox,press Ctrl + C to cancel'
        RETURN_TO_WHERE='tmoe_linux_tool_menu'
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} firefox-esr firefox-esr-l10n-zh-cn
        ${TMOE_REMOVAL_COMMAND} firefox firefox-l10n-zh-cn
        ${TMOE_REMOVAL_COMMAND} firefox-locale-zh-hans
        apt autopurge 2>/dev/null
        emerge -C firefox-bin firefox 2>/dev/null
    else
        printf '%s\n' '小声嘀咕：“妾身不在的时候，你一定要好好照顾好自己。” '
        printf "%s\n" "${YELLOW}按回车键确认卸载chromium${RESET}"
        printf '%s\n' 'Press enter to confirm uninstall chromium,press Ctrl + C to cancel'
        RETURN_TO_WHERE='tmoe_linux_tool_menu'
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} chromium chromium-l10n
        apt-mark unhold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg-extra
        ${TMOE_REMOVAL_COMMAND} chromium-browser chromium-browser-l10n
        apt autopurge
        dnf remove -y chromium 2>/dev/null
        pacman -Rsc chromium 2>/dev/null
        emerge -C chromium 2>/dev/null

    fi
    tmoe_linux_tool_menu
}
############################################
software_center() {
    RETURN_TO_WHERE='software_center'
    RETURN_TO_MENU='software_center'
    SOFTWARE=$(
        whiptail --title "Software center-01" --menu \
            "您想要安装哪个软件？\n Which software do you want to install?" 0 50 0 \
            "1" "🦊 Browser:浏览器(edge,firefox,chromium)" \
            "2" "📘 Dev:开发(VScode,Pycharm,Android-Studio,idea)" \
            "3" "⚛️ electron-apps(云音乐,哔哩哔哩,cocomusic)" \
            "4" "🎵 Multimedia:图像与影音(gimp,mpv)" \
            "5" "🐧 SNS:社交类(qq,wechat,skype)" \
            "6" "🎮 Games:游戏(steam,kdegames小游戏合集)" \
            "7" "📚 Documents:文档(libreoffice,wps)" \
            "8" "🎁 Download:下载类(aria2,baidu,迅雷)" \
            "9" "🏤 debian-opt仓库" \
            "10" "🔯 Packages&system:软件包与系统管理" \
            "11" "🥙 Start zsh tool:启动zsh管理工具" \
            "12" "🥗 File shared:文件共享与网盘(Webdav)" \
            "13" "💔 remove:卸载管理" \
            "0" "🌚 Back to the main menu 返回主菜单" \
            3>&1 1>&2 2>&3
    )
    case "${SOFTWARE}" in
    0 | "") tmoe_linux_tool_menu ;;
    1) install_browser ;;
    2) dev_menu ;;
    3) tmoe_electron_repo ;;
    4) tmoe_multimedia_menu ;;
    5) tmoe_social_network_service ;;
    6) tmoe_games_menu ;;
    7) source_tmoe_document_app ;;
    8) tmoe_download_class ;;
    9) explore_debian_opt_repo ;;
    10) tmoe_software_package_menu ;;
    11) start_tmoe_zsh_manager ;;
    12) personal_netdisk ;;
    13) tmoe_other_options_menu ;;
    esac
    ############################################
    #install_bilibili_electron
    #"5" "🎬 腾讯视频(Linux在线视频软件)" \
    # 6) install_tencent_video ;;
    ###########
    press_enter_to_return
    software_center
}
###########
tmoe_electron_repo() {
    source ${TMOE_TOOL_DIR}/sources/electron-apps
}
source_tmoe_document_app() {
    source ${TMOE_TOOL_DIR}/app/office
}
#############
dev_menu() {
    source ${TMOE_TOOL_DIR}/code/dev-menu
}
###########
normally_start_zsh() {
    if [ $(command -v zsh-i) ]; then
        zsh-i
    elif [ -e "${TMOE_ZSH_SCRIPT}" ]; then
        bash ${TMOE_ZSH_SCRIPT}
    else
        bash -c "$(curl -LfsS ${ZSH_TOOL_URL})"
    fi
}
start_zsh_tool_as_current_user() {
    if [ $(command -v zsh-i) ]; then
        su - ${CURRENT_USER_NAME} -c zsh-i
    elif [ -e "${TMOE_ZSH_SCRIPT}" ]; then
        su - ${CURRENT_USER_NAME} -c "bash ${TMOE_ZSH_SCRIPT}"
    else
        curl -Lo /tmp/.zsh-i.sh ${ZSH_TOOL_URL}
        su - ${CURRENT_USER_NAME} -c "bash /tmp/.zsh-i.sh"
    fi
}
start_tmoe_zsh_manager() {
    TMOE_ZSH_SCRIPT="${HOME}/.config/tmoe-zsh/git/zsh.sh"
    ZSH_TOOL_URL="https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh"
    case $(id -u) in
    0) normally_start_zsh ;;
    *)
        case ${LINUX_DISTRO} in
        Android) normally_start_zsh ;;
        *) start_zsh_tool_as_current_user ;;
        esac
        ;;
    esac
}
##########
tmoe_software_package_menu() {
    RETURN_TO_WHERE='tmoe_software_package_menu'
    DEPENDENCY_01=""
    TMOE_APP=$(
        whiptail --title "PACKAGES MANAGER" --menu \
            "How do you want to manage software package?" 0 50 0 \
            "1" "deb-batch-installer:软件包批量安装器" \
            "2" "Synaptic(新立得软件包管理器)" \
            "3" "ADB(Android Debug Bridge,用于调试安卓)" \
            "4" "BleachBit(垃圾清理)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) tmoe_deb_batch_installer ;;
    2) install_package_manager_gui ;;
    3) install_android_debug_bridge ;;
    4) install_bleachbit_cleaner ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_software_package_menu
}
#############
tmoe_deb_batch_installer() {
    source ${TMOE_TOOL_DIR}/sources/deb-installer
}
############
tmoe_social_network_service() {
    RETURN_TO_WHERE='tmoe_social_network_service'
    RETURN_TO_MENU='tmoe_social_network_service'
    DEPENDENCY_01=""
    DEPENDENCY_02=""
    TMOE_APP=$(
        whiptail --title "SNS" --menu \
            "Which software do you want to install?" 0 50 0 \
            "1" "LinuxQQ(腾讯开发的IM软件,从心出发,趣无止境)" \
            "2" "Wechat(arm64,x64)" \
            "3" "Thunderbird(雷鸟是Mozilla开发的email客户端)" \
            "4" "Kmail(KDE邮件客户端)" \
            "5" "Evolution(GNOME邮件客户端)" \
            "6" "Empathy(GNOME多协议语音、视频聊天软件)" \
            "7" "Pidgin(IM即时通讯软件)" \
            "8" "Xchat(IRC客户端,类似于Amiga的AmIRC)" \
            "9" "Skype(x64,微软出品的IM软件)" \
            "10" "米聊(x64,小米科技出品的即时通讯工具)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1)
        install_linux_qq
        DEPENDENCY_01=""
        ;;
    2) install_wechat_arm64 ;;
    3) install_thunder_bird ;;
    4) DEPENDENCY_01="kmail" ;;
    5) DEPENDENCY_01="evolution" ;;
    6) DEPENDENCY_01="empathy" ;;
    7) DEPENDENCY_01="pidgin" ;;
    8) DEPENDENCY_01="xchat" ;;
    9)
        install_skype
        DEPENDENCY_01=""
        ;;
    10) mitalk_env ;;
    esac
    ##########################
    case ${DEPENDENCY_01} in
    "") ;;
    *) beta_features_quick_install ;;
    esac
    press_enter_to_return
    tmoe_social_network_service
}
###################
install_wechat_arm64() {
    printf "%s\n" "若安装失败，则请前往uos商店在线安装。"
    printf "%s\n" "注：当前版本v2.0.0-2不支持proot容器。"
    printf "%s\n" "执行${GREEN}wechat${RESET}命令启动com.qq.weixin"
    printf "%s\n" "如需卸载，请手动执行${RED}rm -rv ${BLUE}/opt/com.qq.weixin ${APPS_LNK_DIR}/com.qq.weixin.desktop /usr/lib/license/libuosdevicea.so /usr/local/bin/wechat${RESET}"
    cat <<-EOF
Package: com.qq.weixin
Version: 2.0.0-2
Architecture: arm64,amd64
Maintainer: arminchen
Installed-Size: 118814
Depends: libgtk2.0-0, libnotify4, libnss3, libxss1, libxtst6, xdg-utils, libgconf-2-4 | libgconf2-4, kde-cli-tools | kde-runtime | trash-cli | libglib2.0-bin | gvfs-bin
Recommends: pulseaudio | libasound2
Suggests: gir1.2-gnomekeyring-1.0, libgnome-keyring0, lsb-release
Section: net
Priority: optional
Description: 微信
EOF
    do_you_want_to_continue
    case ${TMOE_PROOT} in
    false) ;;
    true)
        printf "%s\n" "Sorry,检测到您使用的是${YELLOW}proot容器,${PURPLE}无法安装${RESET}本应用。若您使用是Android设备，则建议您换用${GREEN}chroot容器${RESET}。"
        press_enter_to_return
        tmoe_social_network_service
        ;;
    esac

    case ${LINUX_DISTRO} in
    debian) ;;
    arch)
        printf "%s\n" "Sorry,自动安装wechat的功能仅支持deb系发行版。"
        printf "%s\n" "您可以用普通用户身份来手动执行${GREEN}yay -S ${BLUE}wechat-uos${RESET}"
        non_debian_function
        ;;
    *) non_debian_function ;;
    esac
    DEPENDENCY_01='com.qq.weixin'
    case ${ARCH_TYPE} in
    arm64) download_tmoe_electron_app ;;
    amd64)
        DEPENDENCY_01='wechat-electron'
        download_tmoe_electron_app
        DEPENDENCY_01='com.qq.weixin'
        cd /opt/${DEPENDENCY_01}
        pwd
        cp -vf .${APPS_LNK_DIR}/${DEPENDENCY_01}.desktop ${APPS_LNK_DIR}
        ;;
    *)
        printf "%s\n" "Sorry,暂仅支持arm64和amd64架构。如需安装其他架构的版本，请前往uos商店或其他商店在线安装。"
        press_enter_to_return
        tmoe_social_network_service
        ;;
    esac
    cp -rfv /opt/${DEPENDENCY_01}/usr/lib/license /usr/lib
    ln -svf /opt/${DEPENDENCY_01}/usr/bin/${DEPENDENCY_01} /usr/local/bin/wechat
    unset DEPENDENCY_01
    if [ ! $(command -v bwrap) ]; then
        DEPENDENCY_01='bubblewrap'
    fi
    DEPENDENCY_02='libgtk2.0-0 libgconf-2-4'
    beta_features_quick_install
    case ${DEBIAN_DISTRO} in
    ubuntu)
        apt install -y libgconf2-4 libgtk2.0-0 #ubuntu-21.04
        ;;
    esac
    printf "%s\n" "您可以在终端内输入${GREEN}nohup wechat${RESET}命令来启动com.qq.weixin"
}
####################
install_thunder_bird() {
    DEPENDENCY_01="thunderbird"
    case ${LINUX_DISTRO} in
    debian)
        DEPENDENCY_02="thunderbird-l10n-zh-cn"
        case ${DEBIAN_DISTRO} in
        ubuntu) DEPENDENCY_02="thunderbird-locale-zh-hans" ;;
        esac
        ;;
    arch) DEPENDENCY_02="thunderbird-i18n-zh-cn" ;;
    suse) DEPENDENCY_02="thunderbird-translations-common" ;;
    esac
}
###############
mitalk_env() {
    DEPENDENCY_01='mitalk'
    GREP_NAME='mitalk'
    OFFICIAL_URL='http://www.miliao.com/#download-content'
    tmoe_app_menu_01
    DEPENDENCY_01=''
}
############
install_mitalk() {
    REPO_URL='https://aur.tuna.tsinghua.edu.cn/packages/mitalk/'
    THE_LATEST_DEB_URL=$(curl -L ${REPO_URL} | grep deb | cut -d '=' -f 2 | cut -d '"' -f 2 | head -n 1)
    #https://s1.zb.mi.com/miliao/apk/miliao/8.8/MiTalk_4.0.100.deb
    #https://s1.zb.mi.com/miliao/apk/miliao/8.8/MiTalk_4.0.100.AppImage
    case ${LINUX_DISTRO} in
    debian | arch) ;;
    *) THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@.deb@.AppImage@") ;;
    esac
    THE_LATEST_DEB_FILE=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | awk -F '/' '{print $NF}')
    THE_LATEST_DEB_VERSION=$(printf '%s\n' "${THE_LATEST_DEB_FILE}" | sed 's@.deb@@' | sed "s@MiTalk_@@")
    ICON_FILE='/usr/share/icons/hicolor/128x128/apps/mitalk.png'
    if [ -e "${ICON_FILE}" ]; then
        catimg "${ICON_FILE}" 2>/dev/null
    fi
    check_deb_version
    case ${ARCH_TYPE} in
    amd64) ;;
    *) arch_does_not_support ;;
    esac
    case ${LINUX_DISTRO} in
    debian | arch) ;;
    *)
        printf "%s\n" "请手动下载AppImage软件包"
        non_debian_function
        ;;
    esac
    download_and_install_deb
}
###############
tmoe_download_class() {
    RETURN_TO_WHERE='tmoe_download_class'

    DEPENDENCY_01=""
    TMOE_APP=$(
        whiptail --title "documents" --menu \
            "Which software do you want to install?" 0 50 0 \
            "1" "🍨 aria2(linux平台超强文件下载器)" \
            "2" "🖼 work_crawler:漫畫、小説下載工具@kanasimi" \
            "3" "迅雷(基于多资源超线程技术的下载软件)" \
            "4" "📉 百度网盘(x64,提供文件的网络备份,同步和分享服务)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) tmoe_aria2_manager ;;
    2) start_kanasimi_work_crawler ;;
    3) source_thunder ;;
    4) install_baidu_netdisk ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_download_class
}
####################
source_thunder() {
    source ${TMOE_TOOL_DIR}/downloader/thunder
}
##################
start_kanasimi_work_crawler() {
    RETURN_TO_WHERE='check_kanasimi_work_crawler'
    install_nodejs
    check_kanasimi_work_crawler
}
###############
install_skype() {
    #https://go.skype.com/skypeforlinux-64.deb
    THE_LATEST_DEB_URL='https://repo.skype.com/latest/skypeforlinux-64.deb'
    DEPENDENCY_01='skypeforlinux'
    if [ $(command -v skypeforlinux) ]; then
        press_enter_to_reinstall
    fi
    case ${LINUX_DISTRO} in
    redhat) THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed 's@64.deb@64.rpm@') ;;
    debian) ;;
    arch) DEPENDENCY_01='skypeforlinux-stable-bin' ;;
    *) non_debian_function ;;
    esac
    printf "%s\n" "${THE_LATEST_DEB_URL}"
    case ${ARCH_TYPE} in
    amd64) ;;
    *) arch_does_not_support ;;
    esac
    do_you_want_to_continue
    cd /tmp
    THE_LATEST_DEB_FILE=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | awk -F '/' '{print $NF}')

    case ${LINUX_DISTRO} in
    redhat | debian) aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_FILE}" "${THE_LATEST_DEB_URL}" ;;
    arch) beta_features_quick_install ;;
    esac

    case ${LINUX_DISTRO} in
    redhat) yum install "${THE_LATEST_DEB_FILE}" ;;
    debian)
        apt-cache show ./${THE_LATEST_DEB_FILE}
        apt install -y ./${THE_LATEST_DEB_FILE}
        ;;
    esac
    rm -vf ${THE_LATEST_DEB_FILE} 2>/dev/null
}
#############
install_nodejs() {
    DEPENDENCY_01=""
    DEPENDENCY_02=""
    if [ ! $(command -v 7za) ]; then
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01="p7zip-full" ;;
        *) DEPENDENCY_01="p7zip" ;;
        esac
    fi
    if [ ! $(command -v node) ]; then
        DEPENDENCY_02="nodejs"
    fi
    if [[ ! -z "${DEPENDENCY_01}" || ! -z "${DEPENDENCY_02}" ]]; then
        beta_features_quick_install
    fi

    if [ ! $(command -v npm) ]; then
        bash -c "$(curl -Lv https://npmjs.org/install.sh | sed 's@registry.npmjs.org@registry.npm.taobao.org@g')"
        [[ $(command -v npm) ]] || ${TMOE_INSTALLATION_COMMAND} npm
        cat <<-'EOF'
			npm config set registry https://registry.npm.taobao.org
			npm config set disturl https://npm.taobao.org/dist
			npm config set electron_mirror https://npm.taobao.org/mirrors/electron/
		EOF
        printf "%s\n" "${YELLOW}是否需要将npm官方源更换为淘宝源[Y/n]${RESET} "
        printf "%s\n" "更换后可以加快国内的下载速度,${YELLOW}按回车键确认，输n拒绝。${RESET}"
        printf "%s\n" "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .${PURPLE}[Y/n]${RESET}"
        do_you_want_to_continue
        npm config set registry https://registry.npm.taobao.org
        npm config set disturl https://npm.taobao.org/dist
        npm config set electron_mirror https://npm.taobao.org/mirrors/electron/
    fi
}
############
check_kanasimi_work_crawler() {
    #if [ ! -h "/usr/local/bin/work-i" ]; then
    #    rm /usr/local/bin/work-i
    #    ln -sf "${TMOE_TOOL_DIR}/downloader/work_crawler@kanasimi.sh" /usr/local/bin/work-i
    #fi
    #此处为bash而非source
    bash "${TMOE_TOOL_DIR}/downloader/work_crawler@kanasimi.sh"
}
####################
install_clementine() {
    DEPENDENCY_02="clementine"
    beta_features_quick_install
}
##########
install_audacity() {
    DEPENDENCY_02="audacity"
    beta_features_quick_install
}
##########
install_ardour() {
    DEPENDENCY_02="ardour"
    beta_features_quick_install
}
############
batch_compression_of_pictures() {
    source ${TMOE_TOOL_DIR}/optimization/compress_pictures
}
############
tmoe_multimedia_menu() {
    RETURN_TO_WHERE='tmoe_multimedia_menu'
    DEPENDENCY_01=""
    DEPENDENCY_02=""
    TMOE_APP=$(whiptail --title "Picture&Video&Music" --menu \
        "Which software do you want to install?" 0 50 0 \
        "1" "🗜️ Batch compression of pics批量压缩图片" \
        "2" "📽️ MPV(开源、跨平台的音视频播放器)" \
        "3" "🎥 SMPlayer(MPlayer的前端)" \
        "4" "🇵 Peek(简单易用的Gif录制软件)" \
        "5" "🖼 GIMP(GNU 图像处理程序)" \
        "6" "kolourpaint(KDE图像编辑)" \
        "7" "🍊 Clementine(小柑橘音乐播放器)" \
        "8" "🎞️ Parole(xfce默认媒体播放器,风格简洁)" \
        "9" "🎧 网易云音乐(x64,专注于发现与分享的音乐产品)" \
        "10" "🎼 Audacity(类似于cooledit的音频处理软件)" \
        "11" "🎶 Ardour(数字音频工作站,用于录制,编辑和混合多轨音频)" \
        "12" "Spotify(x64,声破天是一个正版流媒体音乐服务平台)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) batch_compression_of_pictures ;;
    2) install_mpv ;;
    3) install_smplayer ;;
    4) install_peek ;;
    5) install_gimp ;;
    6) install_kolourpaint ;;
    7) install_clementine ;;
    8) install_parole ;;
    9) install_netease_163_cloud_music ;;
    10) install_audacity ;;
    11) install_ardour ;;
    12) install_spotify ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_multimedia_menu
}
#############
install_spotify() {
    printf "%s\n" "https://www.spotify.com/tw/download/linux/"
    case ${ARCH_TYPE} in
    amd64) ;;
    *) arch_does_not_support ;;
    esac
    DEPENDENCY_02='spotify'
    case ${LINUX_DISTRO} in
    debian)
        cat <<-'EOF'
    若安装失败，则请手动执行以下命令
    curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add - 
    curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo apt-key add - 
    printf "%s\n" "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    apt update
    apt install spotify-client
    如需卸载，则请输apt purge spotify-client ;rm /etc/apt/sources.list.d/spotify.list
EOF
        DEPENDENCY_02='spotify-client'
        ;;
    arch) printf "%s\n" "若安装失败，则请手动执行${GREEN}yay -S ${DEPENDENCY_02}${RESET}" ;;
    esac
    do_you_want_to_continue
    case ${LINUX_DISTRO} in
    debian | arch) beta_features_quick_install ;;
    *)
        printf "%s\n" "You can use snap store to install spotify."
        printf "%s\n" "${GREEN}snap install spotify${RESET}"
        ;;
    esac
}
#############
tmoe_games_menu() {
    RETURN_TO_WHERE='tmoe_games_menu'
    DEPENDENCY_01=""
    TMOE_APP=$(whiptail --title "GAMES" --menu \
        "Which game do you want to install?" 0 50 0 \
        "1" "🎮 KDE-games(KDE项目的小游戏合集)" \
        "2" "👣 GNOME-games" \
        "3" "🤓 Steam-x86_64(蒸汽游戏平台)" \
        "4" "cataclysm-大灾变-劫后余生(末日幻想背景的探索生存游戏)" \
        "5" "wesnoth韦诺之战(奇幻背景的回合制策略战棋游戏)" \
        "6" "retroarch(全能复古游戏模拟器)" \
        "7" "mayomonogatari斯隆与马克贝尔的谜之物语(nds解谜游戏)" \
        "8" "dolphin-emu(任天堂wii模拟器)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    #"6" "SuperTuxKart(3D卡丁车)" \    6) install_supertuxkart_game ;;
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) install_kde_games ;;
    2) install_gnome_games ;;
    3) install_or_remove_steam_app ;;
    4) install_game_cataclysm ;;
    5) install_wesnoth_game ;;
    6) install_retroarch ;;
    7) install_nds_game_mayomonogatari ;;
    8) install_dolphin-emu ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_games_menu
}
#############
install_or_remove_steam_app() {
    if (whiptail --title "安装或卸载STEAM" --yes-button "install" --no-button "remove" --yesno 'Do you want to install or remove steam?' 0 0); then
        install_steam_app
    else
        remove_steam_app
    fi
}
install_retroarch() {
    DEPENDENCY_01='retroarch'
    case "${LINUX_DISTRO}" in
    "debian") DEPENDENCY_02='^libretro' ;;
    "arch") DEPENDENCY_02='retroarch-assets-xmb' ;;
    *) DEPENDENCY_02='' ;;
    esac
    beta_features_quick_install
}
############
install_dolphin-emu() {
    DEPENDENCY_01='dolphin-emu'
    DEPENDENCY_02='dolphin-emu-git'
    case "${LINUX_DISTRO}" in
    "debian") DEPENDENCY_02='' ;;
    esac
    beta_features_quick_install
}
################
remove_debian_steam_app() {
    case "${ARCH_TYPE}" in
    "i386") ;;
    *)
        printf '%s\n' 'dpkg  --remove-architecture i386'
        printf '%s\n' '正在移除对i386软件包的支持'
        #apt purge ".*:i386"
        aptitude remove ~i~ri386
        dpkg --remove-architecture i386
        apt update
        ;;
    esac
}
###############
remove_steam_app() {
    printf "%s\n" "${TMOE_REMOVAL_COMMAND} steam-launcher steam"
    ${TMOE_REMOVAL_COMMAND} steam-launcher steam
    case "${LINUX_DISTRO}" in
    "debian") remove_debian_steam_app ;;
    "redhat")
        #remove_fedora_steam_app
        rm -fv /etc/yum.repos.d/steam.repo
        ;;
    "arch") remove_arch_steam_app ;;
    esac
}
###############
install_debian_steam_app() {
    LATEST_DEB_REPO='https://mirrors.bfsu.edu.cn/steamos/steam/pool/steam/s/steam/'
    GREP_NAME='steam-launcher'
    cd /tmp
    download_tuna_repo_deb_file_all_arch
    dpkg --add-architecture i386
    apt update
    apt install ./${LATEST_DEB_VERSION}
    rm -fv ./${LATEST_DEB_VERSION}
    beta_features_install_completed
}
#################
install_fedora_steam_app() {
    cat >/etc/yum.repos.d/steam.repo <<-'ENDOFFEDORASTEAM'
		[steam]
		name=Steam RPM packages (and dependencies) for Fedora
		baseurl=http://spot.fedorapeople.org/steam/fedora-$releasever/
		enabled=1
		skip_if_unavailable=1
		gpgcheck=0
	ENDOFFEDORASTEAM
}
####################
check_arch_multi_lib_line() {
    cd /etc
    ARCH_MULTI_LIB_LINE=$(cat pacman.conf | grep '\[multilib\]' -n | cut -d ':' -f 1 | tail -n 1)
    ARCH_MULTI_LIB_INCLUDE_LINE=$((${ARCH_MULTI_LIB_LINE} + 1))
}
#################
install_arch_steam_app() {
    check_arch_multi_lib_line
    printf "%s\n" "正在修改/etc/pacman.conf中第${ARCH_MULTI_LIB_LINE}行中的multilib"
    sed -i "${ARCH_MULTI_LIB_LINE}c\[multilib]" pacman.conf
    sed -i "${ARCH_MULTI_LIB_INCLUDE_LINE}c\Include = /etc/pacman.d/mirrorlist" pacman.conf
}
#################
remove_arch_steam_app() {
    check_arch_multi_lib_line
    printf "%s\n" "正在注释掉/etc/pacman.conf中第${ARCH_MULTI_LIB_LINE}行中的multilib"
    sed -i "${ARCH_MULTI_LIB_LINE}c\#[multilib]" pacman.conf
    sed -i "${ARCH_MULTI_LIB_INCLUDE_LINE}c\#Include = /etc/pacman.d/mirrorlist" pacman.conf
}
################
install_steam_app() {
    case "${ARCH_TYPE}" in
    amd64 | i386) ;;
    *)
        printf "%s\n" "${RED}WARNING！${RESET}检测到您使用的是${BLUE}${ARCH_TYPE}${RESET}架构，${RED}请勿${RESET}在该架构上安装steam！！！建议您换用${GREEN}amd64${RESET}架构的设备。"
        printf "%s\n" "Do not install steam on ${BLUE}${ARCH_TYPE}${RESET} architecture."
        printf "%s\n" "是否需要继续安装？"
        do_you_want_to_continue
        ;;
    esac
    DEPENDENCY_01='steam-launcher'
    DEPENDENCY_02="steam"
    case "${LINUX_DISTRO}" in
    "debian") install_debian_steam_app ;;
    "redhat")
        install_fedora_steam_app
        beta_features_quick_install
        ;;
    "arch")
        DEPENDENCY_01='steam-native-runtime'
        install_arch_steam_app
        #此处需要选择显卡驱动，故不要使用quick_install_function
        printf "%s\n" "pacman -Syu --needed ${DEPENDENCY_01} ${DEPENDENCY_02}"
        pacman -Syu --needed ${DEPENDENCY_01} ${DEPENDENCY_02}
        ;;
    *)
        beta_features_quick_install
        ;;
    esac
}
####################
install_gnome_games() {
    DEPENDENCY_01="gnome-games"
    DEPENDENCY_02="five-or-more four-in-a-row gnome-chess gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-tetravex hitori iagno lightsoff quadrapassel swell-foop tali"
    case ${LINUX_DISTRO} in
    debian) DEPENDENCY_01="gnome-games phosh-games gnustep-games" ;;
    esac
    beta_features_quick_install
}
########
install_kde_games() {
    DEPENDENCY_01="libkdegames"
    DEPENDENCY_02="bomber bovo granatier kapman katomic kblackbox kblocks kbounce kbreakout kdiamond kfourinline kgoldrunner kigo killbots kiriki kjumpingcube klickety klines kmahjongg kmines knavalbattle knetwalk knights kolf kollision konquest kreversi kshisen ksirk ksnakeduel kspaceduel ksquares ksudoku ktuberling kubrick lskat palapeli picmi kajongg"
    case ${LINUX_DISTRO} in
    debian) DEPENDENCY_01="kdegames" ;;
    redhat) DEPENDENCY_01="libkdegames4 kdegames3 libkdegames" ;;
    arch) DEPENDENCY_01="kde-games" ;;
    esac
    beta_features_quick_install
}
########
install_supertuxkart_game() {
    DEPENDENCY_02="supertuxkart"
    beta_features_quick_install
}
###################
install_wesnoth_game() {
    DEPENDENCY_01="wesnoth"
    DEPENDENCY_02=""

    beta_features_quick_install
}
###########
install_smplayer() {
    DEPENDENCY_02="smplayer"
    beta_features_quick_install
}
###########
install_mpv() {
    if [ "${LINUX_DISTRO}" = "redhat" ]; then
        DEPENDENCY_01="kmplayer"
    else
        DEPENDENCY_01="mpv"
    fi
    DEPENDENCY_02=""

    beta_features_quick_install
}
#############
install_linux_qq() {
    ICON_FILE='/usr/local/share/tencent-qq/qq.png'
    cat_icon_img
    DEPENDENCY_01="linuxqq"
    case ${LINUX_DISTRO} in
    arch) DEPENDENCY_02="gtk2" ;;
    *) unset DEPENDENCY_02 ;;
    esac

    printf "%s\n" "正在检测版本更新..."
    printf "%s\n" "若安装失败，则请前往官网手动下载安装。"
    printf "%s\n" "url: ${YELLOW}https://im.qq.com/linuxqq/download.html${RESET}"
    THE_LATEST_PACMAN_URL=$(curl -L https://aur.tuna.tsinghua.edu.cn/packages/linuxqq/ | grep x86_64 | grep qq | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
    THE_LATEST_DEB_VERSION=$(printf '%s\n' "${THE_LATEST_PACMAN_URL}" | awk -F '/' '{print $NF}' | sed 's@_x86_64.pkg.*$@@')
    case ${THE_LATEST_DEB_VERSION} in
    linuxqq_2.0.0-b2-1084 | "")
        THE_LATEST_DEB_VERSION='linuxqq_2.0.0-b2-1089'
        THE_LATEST_PACMAN_URL="http://down.qq.com/qqweb/LinuxQQ/linuxqq_2.0.0-b2-1089_x86_64.pkg.tar.xz"
        ;;
    esac

    THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_PACMAN_URL}" | sed "s@x86_64.pkg.*@${ARCH_TYPE}.deb@")
    case ${ARCH_TYPE} in
    amd64) TMP_ARCH_TYPE=x86_64 ;;
    arm64) TMP_ARCH_TYPE=arm64 ;;
    mips64el) TMP_ARCH_TYPE=mips64el ;;
    esac

    THE_LATEST_SH_URL=$(printf '%s\n' "${THE_LATEST_PACMAN_URL}" | sed "s@x86_64.pkg.*@${TMP_ARCH_TYPE}.sh@")
    #重复检测版本号
    THE_LATEST_DEB_VERSION=$(printf '%s\n' "${THE_LATEST_PACMAN_URL}" | awk -F '/' '{print $NF}' | sed 's@_x86_64.pkg.*$@@')

    TMOE_TIPS_01="检测到最新版本为${THE_LATEST_DEB_VERSION}"
    lolcat_tmoe_tips_01

    case ${LINUX_DISTRO} in
    debian) printf "%s\n" "最新版链接为${BLUE}${THE_LATEST_DEB_URL}${RESET}" ;;
    *) printf "%s\n" "最新版链接为${BLUE}${THE_LATEST_SH_URL}${RESET}" ;;
    esac

    if [ ! -e "${APPS_LNK_DIR}/qq.desktop" ]; then
        printf "%s\n" "未检测到本地版本，您可能尚未安装腾讯QQ linux版客户端。"
    elif [ -e "${TMOE_LINUX_DIR}/${DEPENDENCY_01}-version" ]; then
        printf "%s\n" "本地版本可能为${YELLOW}$(head -n 1 ${TMOE_LINUX_DIR}/${DEPENDENCY_01}-version)${RESET}"
        printf "%s\n" "如需${RED}卸载${RESET}，请手动输${BLUE} ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02};rm -rv /usr/local/bin/crashpad_handler /usr/share/applications/qq.desktop /usr/local/share/tencent-qq /usr/local/bin/qq${RESET}"
    else
        printf "%s\n" "未检测到本地版本，您可能不是通过tmoe-linux tool安装的。"
    fi
    do_you_want_to_continue
    #if [ -e "${APPS_LNK_DIR}/qq.desktop" ]; then
    #   press_enter_to_reinstall
    #fi
    cd /tmp
    case "${ARCH_TYPE}" in
    arm64 | amd64)
        case ${LINUX_DISTRO} in
        debian)
            aria2c --console-log-level=warn --no-conf --allow-overwrite=true -k 1M -o LINUXQQ.deb ${THE_LATEST_DEB_URL}
            apt-cache show ./LINUXQQ.deb
            apt install -y ./LINUXQQ.deb
            ;;
        *)
            aria2c --console-log-level=warn --no-conf --allow-overwrite=true -k 1M -o LINUXQQ.sh ${THE_LATEST_SH_URL}
            chmod a+rx LINUXQQ.sh
            sudo ./LINUXQQ.sh
            #即使是root用户也需要加sudo
            printf "%s\n" "${GREEN}${TMOE_INSTALLATION_COMMAND} ${BLUE}gtk2${RESET}"
            ${TMOE_INSTALLATION_COMMAND} gtk2 || ${TMOE_INSTALLATION_COMMAND} gtk2
            ;;
        esac
        ;;
    *) arch_does_not_support ;;
    esac
    printf "%s\n" "${THE_LATEST_DEB_VERSION}" >"${TMOE_LINUX_DIR}/${DEPENDENCY_01}-version"
    rm -fv ./LINUXQQ.deb ./LINUXQQ.sh 2>/dev/null
    beta_features_install_completed
}
###################
install_nds_game_mayomonogatari() {
    DEPENDENCY_01="desmume"
    if [ ! $(command -v 7za) ]; then
        case ${LINUX_DISTRO} in
        debian) DEPENDENCY_02="p7zip-full" ;;
        *) DEPENDENCY_02="p7zip" ;;
        esac
    else
        DEPENDENCY_02=""
    fi
    beta_features_quick_install
    if [ -e "斯隆与马克贝尔的谜之物语/3782.nds" ]; then
        printf "%s\n" "检测到您已下载游戏文件，路径为${HOME}/斯隆与马克贝尔的谜之物语"
        press_enter_to_reinstall
    fi
    cd ${HOME}
    mkdir -pv '斯隆与马克贝尔的谜之物语'
    cd '斯隆与马克贝尔的谜之物语'
    aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o slymkbr1.zip http://k73dx1.zxclqw.com/slymkbr1.zip
    aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o mayomonogatari2.zip http://k73dx1.zxclqw.com/mayomonogatari2.zip
    7za x slymkbr1.zip
    7za x mayomonogatari2.zip
    mv -f 斯隆与马克贝尔的谜之物语k73/* ./
    mv -f 迷之物语/* ./
    rm -f *url *txt
    rm -rf 迷之物语 斯隆与马克贝尔的谜之物语k73
    rm -f slymkbr1.zip* mayomonogatari2.zip*

    printf "%s\n" "安装完成，您需要手动执行${GREEN}/usr/games/desmume${RESER}或${GREEN}desmume${RESER}，并进入'${HOME}/斯隆与马克贝尔的谜之物语'目录加载游戏"
    printf "%s\n" "如需卸载,则请手动输${TMOE_REMOVAL_COMMAND} desmume ; rm -rf ~/斯隆与马克贝尔的谜之物语"
    printf '%s\n' 'Press enter to start the nds emulator.'
    printf "%s\n" "${YELLOW}按回车键启动游戏。${RESET}"
    do_you_want_to_continue
    /usr/games/desmume "${HOME}/斯隆与马克贝尔的谜之物语/3782.nds" 2>/dev/null &
}
##################
install_game_cataclysm() {
    case ${LINUX_DISTRO} in
    debian)
        DEPENDENCY_01="cataclysm-dda-curses"
        DEPENDENCY_02="cataclysm-dda-sdl"
        ;;
    *)
        DEPENDENCY_01="cataclysm-dda-curses"
        DEPENDENCY_02="cataclysm-dda cataclysm-dda-tiles"
        ;;
    esac
    beta_features_quick_install
    printf "%s\n" "在终端环境下，您需要缩小显示比例，并输入cataclysm来启动字符版游戏。"
    printf "%s\n" "在gui下，您需要输cataclysm-tiles来启动画面更为华丽的图形界面版游戏。"
    printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
    printf "%s\n" "${YELLOW}按回车键启动。${RESET}"
    read
    cataclysm
}
##############################################################
install_package_manager_gui() {
    case "${LINUX_DISTRO}" in
    "debian") install_synaptic ;;
    "arch")
        printf "%s\n" "检测到您使用的是arch系发行版，将为您安装pamac"
        install_pamac_gtk
        ;;
    *)
        printf "%s\n" "检测到您使用的不是deb系发行版，将为您安装gnome_software"
        install_gnome_software
        ;;
    esac
}
######################
install_gimp() {
    DEPENDENCY_01="gimp"
    DEPENDENCY_02=""
    beta_features_quick_install
}
install_kolourpaint() {
    DEPENDENCY_01="kolourpaint"
    DEPENDENCY_02=""
    beta_features_quick_install
}
##############
install_peek() {
    DEPENDENCY_01="peek"
    DEPENDENCY_02=""
    beta_features_quick_install
}
#############
install_parole() {
    DEPENDENCY_01="parole"
    DEPENDENCY_02=""
    beta_features_quick_install
}
###############
install_pamac_gtk() {
    DEPENDENCY_01="pamac"
    DEPENDENCY_02=""

    beta_features_quick_install
}
#####################
install_synaptic() {
    if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Install安装" --no-button "Remove移除" --yesno "新立德是一款使用apt的图形化软件包管理工具，您也可以把它理解为软件商店。Synaptic is a graphical package management program for apt. It provides the same features as the apt-get command line utility with a GUI front-end based on Gtk+.它提供与apt-get命令行相同的功能，并带有基于Gtk+的GUI前端。功能：1.安装、删除、升级和降级单个或多个软件包。 2.升级整个系统。 3.管理软件源列表。  4.自定义过滤器选择(搜索)软件包。 5.按名称、状态、大小或版本对软件包进行排序。 6.浏览与所选软件包相关的所有可用在线文档。♪(^∇^*) " 19 50); then
        DEPENDENCY_01="synaptic"
        DEPENDENCY_02="gdebi"
        #NON_DEBIAN=true
        non_debian_function
        beta_features_quick_install
        sed -i 's/synaptic-pkexec/synaptic/g' ${APPS_LNK_DIR}/synaptic.desktop
        printf "%s\n" "synaptic和gdebi安装完成，您可以将deb文件的默认打开程序修改为gdebi"
    else
        printf "%s\n" "${YELLOW}您真的要离开我么？哦呜。。。${RESET}"
        printf "%s\n" "Do you really want to remove synaptic?"
        RETURN_TO_WHERE='software_center'
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} synaptic
        ${TMOE_REMOVAL_COMMAND} gdebi
    fi
}
##########################################
install_chinese_manpages() {
    printf '%s\n' '即将为您安装 debian-reference-zh-cn、manpages、manpages-zh和man-db'
    case "${LINUX_DISTRO}" in
    "debian") DEPENDENCY_01="manpages manpages-zh man-db" ;;
    "arch") DEPENDENCY_01="man-pages-zh_cn man-pages-zh_tw" ;;
    "redhat" | *) DEPENDENCY_01="man-pages-zh-CN" ;;
    esac
    DEPENDENCY_02="debian-reference-zh-cn"

    beta_features_quick_install
    if [ ! -e "${HOME}/文档/debian-handbook/usr/share/doc/debian-handbook/html" ]; then
        mkdir -pv ${HOME}/文档/debian-handbook
        cd ${HOME}/文档/debian-handbook
        GREP_NAME='debian-handbook'
        LATEST_DEB_REPO='https://mirrors.bfsu.edu.cn/debian/pool/main/d/debian-handbook/'
        download_tuna_repo_deb_file_all_arch
        #aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'debian-handbook.deb' 'https://mirrors.bfsu.edu.cn/debian/pool/main/d/debian-handbook/debian-handbook_8.20180830_all.deb'
        THE_LATEST_DEB_FILE='kali-undercover.deb'
        ar xv ${LATEST_DEB_VERSION}
        tar -Jxvf data.tar.xz ./usr/share/doc/debian-handbook/html
        ls | grep -v usr | xargs rm -rf
        ln -sf ./usr/share/doc/debian-handbook/html/zh-CN/index.html ./
    fi
    printf "%s\n" "man一款帮助手册软件，它可以帮助您了解关于命令的详细用法。"
    printf "%s\n" "man a help manual software, which can help you understand the detailed usage of the command."
    printf "%s\n" "您可以输${YELLOW}man 软件或命令名称${RESET}来获取帮助信息，例如${YELLOW}man bash${RESET}或${YELLOW}man zsh${RESET}"
}
#########
install_baidu_netdisk() {
    DEPENDENCY_01="baidunetdisk"
    DEPENDENCY_02=""
    ICON_FILE_01="/usr/share/icons/hicolor/128x128/apps/${DEPENDENCY_01}.png"
    #ICON_FILE_02='/usr/share/icons/hicolor/scalable/apps/${DEPENDENCY_01}.svg'
    ICON_FILE_02="${TMOE_ICON_DIR}/${DEPENDENCY_01}.png"
    #ICON_FILE="/usr/local/etc/tmoe-linux/icons/baidunetdisk.png"
    ICON_FILE="${ICON_FILE_02}"
    if [ -e "${ICON_FILE_01}" ]; then
        ICON_FILE="${ICON_FILE_01}"
    elif [ -e "${ICON_FILE_02}" ]; then
        printf ""
    else
        mkdir -pv ${TMOE_ICON_DIR}
        aria2c --console-log-level=warn --no-conf --allow-overwrite=true -d ${TMOE_ICON_DIR} -o ${DEPENDENCY_01}.png "https://gitee.com/ak2/icons/raw/master/${DEPENDENCY_01}.png"
    fi

    cat_icon_img

    printf "%s\n" "若安装失败，则请前往官网手动下载安装"
    printf "%s\n" "url：${YELLOW}https://pan.baidu.com/download${RESET}"
    printf "%s\n" "正在检测版本更新..."
    THE_LATEST_DEB_URL=$(curl -L 'https://aur.tuna.tsinghua.edu.cn/packages/baidunetdisk-bin/?O=10&PP=10' | grep '\.deb' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
    THE_LATEST_DEB_VERSION=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | awk -F '/' '{print $NF}' | sed 's@.deb@@')
    case ${LINUX_DISTRO} in
    redhat)
        THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@${DEPENDENCY_01}_@${DEPENDENCY_01}-@" | sed 's@_amd64.deb@.x86_64.rpm@')
        ;;
    esac
    TMOE_TIPS_01="检测到最新版本为${THE_LATEST_DEB_VERSION}"
    lolcat_tmoe_tips_01
    printf "%s\n" "最新版链接为${YELLOW}${THE_LATEST_DEB_URL}${RESET}"
    if [ ! -e "${APPS_LNK_DIR}/baidunetdisk.desktop" ]; then
        printf "%s\n" "未检测到本地版本，您可能尚未安装百度网盘客户端。"
    elif [ -e "${TMOE_LINUX_DIR}/${DEPENDENCY_01}-version" ]; then
        printf "%s\n" "本地版本可能为${YELLOW}$(head -n 1 ${TMOE_LINUX_DIR}/${DEPENDENCY_01}-version)${RESET}"
        printf "%s\n" "如需${RED}卸载${RESET}，请手动输${BLUE} ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
    else
        printf "%s\n" "未检测到本地版本，您可能不是通过tmoe-linux tool安装的。"
    fi
    case "${ARCH_TYPE}" in
    "amd64") ;;
    *) arch_does_not_support ;;
    esac

    #if [ -e "${APPS_LNK_DIR}/baidunetdisk.desktop" ]; then
    #    press_enter_to_reinstall
    #fi
    do_you_want_to_continue
    cd /tmp
    case "${LINUX_DISTRO}" in
    "debian")
        #GREP_NAME='baidunetdisk'
        #LATEST_DEB_REPO='http://archive.ubuntukylin.com/software/pool/'
        #download_ubuntu_kylin_deb_file_model_02
        aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o baidunetdisk.deb "${THE_LATEST_DEB_URL}"
        apt-cache show ./baidunetdisk.deb
        apt install -y ./baidunetdisk.deb
        ;;
    "arch")
        DEPENDENCY_01="baidunetdisk-bin"
        beta_features_quick_install
        ;;
    "redhat")
        aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'baidunetdisk.rpm' "${THE_LATEST_RPM_URL}"
        yum install 'baidunetdisk.rpm'
        ;;
    esac
    printf "%s\n" "${THE_LATEST_DEB_VERSION}" >"${TMOE_LINUX_DIR}/${DEPENDENCY_01}-version"
    #rm -fv ./baidunetdisk.deb
    beta_features_install_completed
}
######################
install_netease_163_cloud_music() {
    #ICON_FILE_02='/usr/share/icons/hicolor/scalable/apps/netease-cloud-music.svg'
    ICON_FILE="${TMOE_ICON_DIR}/netease-cloud-music.jpg"
    if [ ! -e "${ICON_FILE}" ]; then
        mkdir -pv ${TMOE_ICON_DIR}
        aria2c --console-log-level=warn --no-conf --allow-overwrite=true -d ${TMOE_ICON_DIR} -o netease-cloud-music.jpg "https://gitee.com/ak2/icons/raw/master/netease-cloud-music.jpg"
    fi

    cat_icon_img
    DEPENDENCY_01="netease-cloud-music"
    DEPENDENCY_02=""
    printf "%s\n" "正在从优麒麟软件仓库获取最新的网易云音乐版本号..."
    printf "%s\n" "若安装失败，则请前往官网手动下载安装。"
    printf "%s\n" "url: ${YELLOW}https://music.163.com/st/download${RESET}"
    LATEST_DEB_REPO='http://archive.ubuntukylin.com/software/pool/'
    THE_LATEST_DEB_VERSION=$(curl -L ${LATEST_DEB_REPO} | grep "${DEPENDENCY_01}" | cut -d '=' -f 5 | cut -d '"' -f 2 | head -n 1)
    TMOE_TIPS_01="检测到最新版本为${THE_LATEST_DEB_VERSION}"
    lolcat_tmoe_tips_01
    if [ ! -e "${APPS_LNK_DIR}/netease-cloud-music.desktop" ]; then
        #press_enter_to_reinstall
        printf "%s\n" "未检测到本地版本，您可能尚未安装网易云音乐官方版客户端"
    elif [ -e "${TMOE_LINUX_DIR}/${DEPENDENCY_01}-version" ]; then
        printf "%s\n" "检测到本地版本为$(head -n 1 ${TMOE_LINUX_DIR}/${DEPENDENCY_01}-version)"
        printf "%s\n" "如需${RED}卸载${RESET}，请手动输${BLUE} ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
    fi
    case "${ARCH_TYPE}" in
    amd64 | i386) ;;
    *) arch_does_not_support ;;
    esac
    do_you_want_to_continue
    cd /tmp
    case "${LINUX_DISTRO}" in
    "arch")
        DEPENDENCY_01="netease-cloud-music"
        beta_features_quick_install
        ;;
    "redhat")
        curl -Lv https://dl.senorsen.com/pub/package/linux/add_repo.sh | sh -
        dnf install http://dl-http.senorsen.com/pub/package/linux/rpm/senorsen-repo-0.0.1-1.noarch.rpm
        dnf install -y netease-cloud-music
        #https://github.com/ZetaoYang/netease-cloud-music-appimage/releases
        #appimage格式
        ;;
    *)
        non_debian_function
        GREP_NAME='netease-cloud-music'
        case $(date +%Y%m) in
        202008)
            printf "%s\n" "优麒麟软件仓库于2020年8月份中下旬进行维护，您可能无法正常下载"
            do_you_want_to_continue
            ;;
        esac
        case "${ARCH_TYPE}" in
        "amd64")
            LATEST_DEB_REPO='http://archive.ubuntukylin.com/software/pool/'
            download_ubuntu_kylin_deb_file_model_02
            #aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o netease-cloud-music.deb "http://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb"
            ;;
        *)
            LATEST_DEB_REPO='http://mirrors.ustc.edu.cn/debiancn/pool/main/n/netease-cloud-music/'
            download_debian_cn_repo_deb_file_model_01
            ;;
        esac
        beta_features_install_completed
        ;;
    esac
    printf "%s\n" "${THE_LATEST_DEB_VERSION}" >"${TMOE_LINUX_DIR}/${DEPENDENCY_01}-version"
    press_enter_to_return
    tmoe_linux_tool_menu
}
############################
install_android_debug_bridge() {
    if [ ! $(command -v adb) ]; then
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01="adb" ;;
        *) DEPENDENCY_01="android-tools" ;;
        esac
    fi
    DEPENDENCY_02=""

    beta_features_quick_install
    adb --help
    printf "%s\n" "正在重启进程,您也可以手动输adb devices来获取设备列表"
    adb kill-server
    adb devices -l
    printf "%s\n" "即将为您自动进入adb shell模式，您也可以手动输adb shell来进入该模式"
    adb shell
}
####################
install_bleachbit_cleaner() {
    DEPENDENCY_01="bleachbit"
    DEPENDENCY_02=""

    beta_features_quick_install
}
##########################
personal_netdisk() {
    WHICH_NETDISK=$(whiptail --title "FILE SHARE SERVER" --menu "你想要使用哪个软件来共享文件呢" 0 50 0 \
        "1" "Filebrowser:简单轻量的个人网盘" \
        "2" "Nginx WebDAV:比ftp更适合用于传输流媒体" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${WHICH_NETDISK}" in
    0 | "") software_center ;;
    1) install_filebrowser ;;
    2) install_nginx_webdav ;;
    esac
    ##################
    press_enter_to_return
    personal_netdisk
}
################################
tmoe_other_options_menu() {
    RETURN_TO_WHERE='tmoe_other_options_menu'

    TMOE_APP=$(whiptail --title "其它选项" --menu \
        "Welcome to tmoe-linux tool.这里是其它选项的菜单." 0 50 0 \
        "1" "Remove GUI 卸载图形界面" \
        "2" "Remove browser 卸载浏览器" \
        "3" "Remove tmoe-linux tool" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) remove_gui ;;
    2) remove_browser ;;
    3) remove_tmoe_linux_tool ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_other_options_menu
}
############################
remove_gui() {
    DEPENDENCY_01="xfce lxde mate lxqt cinnamon gnome dde deepin-desktop kde-plasma"
    printf '%s\n' '"xfce" "呜呜，(≧﹏ ≦)您真的要离开我么"  '
    printf '%s\n' '"lxde" "很庆幸能与阁下相遇（；´д｀）ゞ "  '
    printf '%s\n' '"mate" "喔...喔呜...我不舍得你走/(ㄒoㄒ)/~~"  '
    #新功能预告：即将适配非deb系linux的gui卸载功能
    printf "%s\n" "${YELLOW}按回车键确认卸载${RESET}"
    printf '%s\n' 'Press enter to remove,press Ctrl + C to cancel'
    RETURN_TO_WHERE='tmoe_linux_tool_menu'
    do_you_want_to_continue
    case "${LINUX_DISTRO}" in
    "debian")
        apt purge -y xfce4 xfce4-terminal tightvncserver xfce4-goodies
        apt purge -y dbus-x11
        apt purge -y ^xfce
        #apt purge -y xcursor-themes
        apt purge -y lxde-core lxterminal
        apt purge -y ^lxde
        apt purge -y mate-desktop-environment-core mate-terminal || aptitude purge -y mate-desktop-environment-core 2>/dev/null
        umount .gvfs
        apt purge -y ^gvfs ^udisks
        apt purge -y ^mate
        apt purge -y -y kde-plasma-desktop
        apt purge -y ^kde-plasma
        apt purge -y ^gnome
        apt purge -y ^cinnamon
        apt purge -y dde
        apt autopurge || apt autoremove
        ;;
    "arch")
        pacman -Rsc xfce4 xfce4-goodies
        pacman -Rsc mate mate-extra
        pacman -Rsc lxde lxqt
        pacman -Rsc plasma-desktop
        pacman -Rsc gnome gnome-extra
        pacman -Rsc cinnamon
        pacman -Rsc deepin deepin-extra
        ;;
    "redhat")
        dnf groupremove -y xfce
        dnf groupremove -y mate-desktop
        dnf groupremove -y lxde-desktop
        dnf groupremove -y lxqt
        dnf groupremove -y "KDE" "GNOME" "Cinnamon Desktop"
        dnf remove -y deepin-desktop
        ;;
    *)
        ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
        ;;
    esac
}
##########################
remove_tmoe_linux_tool() {
    cd /usr/local/bin
    unset DEPENDENCIES
    DEPENDENCIES=$(sed ":a;N;s/\n/ /g;ta" ${TMOE_LINUX_DIR}/TOOL_DEPENDENCIES.txt)
    [[ -n ${DEPENDENCIES} ]] || DEPENDENCIES='git aria2 pv wget curl less xz-utils newt whiptail'
    printf "%s\n" "${RED}rm -rv ${APPS_LNK_DIR}/tmoe-linux.desktop ${HOME}/.config/tmoe-linux tmoe startvnc stopvnc novnc debian debian-i startx11vnc startxsdl x11vncpasswd .tmoe-linux-qemu startqemu ${TMOE_GIT_DIR}${RESET}"
    printf "%s\n" "${RED}${TMOE_REMOVAL_COMMAND} ${DEPENDENCIES}${RESET}"
    printf "%s\n" "${RED}WARNING！${RESET}删除${HOME}/.config/tmoe-linux文件夹将导致chroot容器无法正常移除，建议您在移除完容器后再来删除配置文件目录。"
    do_you_want_to_continue
    rm -rv ${APPS_LNK_DIR}/tmoe-linux.desktop tmoe startvnc stopvnc novnc debian debian-i startx11vnc ${TMOE_GIT_DIR} startxsdl x11vncpasswd ${HOME}/.config/tmoe-linux
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCIES}
    exit 1
}
############################
software_center
