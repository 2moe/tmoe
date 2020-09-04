#!/usr/bin/env bash
####################
remove_browser() {
    if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno '火狐娘:“虽然知道总有离别时，但我没想到这一天竟然会这么早。虽然很不舍，但还是很感激您曾选择了我。希望我们下次还会再相遇，呜呜...(;´༎ຶД༎ຶ`)”chromium娘：“哼(￢︿̫̿￢☆)，负心人，走了之后就别回来了！o(TヘTo) 。”  ✨请做出您的选择！' 10 60); then
        echo '呜呜...我...我才...才不会为了这点小事而流泪呢！ヽ(*。>Д<)o゜'
        echo "${YELLOW}按回车键确认卸载firefox${RESET}"
        echo 'Press enter to remove firefox,press Ctrl + C to cancel'
        RETURN_TO_WHERE='tmoe_linux_tool_menu'
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} firefox-esr firefox-esr-l10n-zh-cn
        ${TMOE_REMOVAL_COMMAND} firefox firefox-l10n-zh-cn
        ${TMOE_REMOVAL_COMMAND} firefox-locale-zh-hans
        apt autopurge 2>/dev/null
        emerge -C firefox-bin firefox 2>/dev/null

    else
        echo '小声嘀咕：“妾身不在的时候，你一定要好好照顾好自己。” '
        echo "${YELLOW}按回车键确认卸载chromium${RESET}"
        echo 'Press enter to confirm uninstall chromium,press Ctrl + C to cancel'
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
    SOFTWARE=$(
        whiptail --title "Software center-01" --menu \
            "您想要安装哪个软件？\n Which software do you want to install?" 0 50 0 \
            "1" "🦊 Browser:浏览器(firefox,chromium)" \
            "2" "🏤 debian-opt:qq音乐,云音乐(支持arch和fedora)" \
            "3" "🎵 Multimedia:图像与影音(腾讯视频,gimp,mpv)" \
            "4" "🐧 SNS:社交类(qq)" \
            "5" "🎮 Games:游戏(steam,wesnoth)" \
            "6" "🔯 Packages&system:软件包与系统管理" \
            "7" "📚 Documents:文档(libreoffice)" \
            "8" "📘 VSCode 现代化代码编辑器" \
            "9" "🎁 Download:下载类(aria2,baidu)" \
            "10" "🥙 Start zsh tool:启动zsh管理工具" \
            "11" "🥗 File shared:文件共享与网盘(Webdav)" \
            "12" "💔 remove:卸载管理" \
            "0" "🌚 Back to the main menu 返回主菜单" \
            3>&1 1>&2 2>&3
    )
    #(已移除)"12" "Tasksel:轻松,快速地安装组软件" \
    case "${SOFTWARE}" in
    0 | "") tmoe_linux_tool_menu ;;
    1) install_browser ;;
    2) explore_debian_opt_repo ;;
    3) tmoe_multimedia_menu ;;
    4) tmoe_social_network_service ;;
    5) tmoe_games_menu ;;
    6) tmoe_software_package_menu ;;
    7) tmoe_documents_menu ;;
    8) which_vscode_edition ;;
    9) tmoe_download_class ;;
    10) start_tmoe_zsh_manager ;;
    11) personal_netdisk ;;
    12) tmoe_other_options_menu ;;
    esac
    ############################################
    press_enter_to_return
    software_center
}
###########
start_tmoe_zsh_manager() {
    TMOE_ZSH_SCRIPT="${HOME}/.config/tmoe-zsh/git/zsh.sh"
    if [ -e /usr/local/bin/zsh-i ]; then
        bash /usr/local/bin/zsh-i
    elif [ -e "${TMOE_ZSH_SCRIPT}" ]; then
        bash ${TMOE_ZSH_SCRIPT}
    else
        bash -c "$(curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh')"
    fi
}
##########
tmoe_software_package_menu() {
    RETURN_TO_WHERE='tmoe_software_package_menu'
    NON_DEBIAN='false'
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
    NON_DEBIAN='false'
    DEPENDENCY_01=""
    TMOE_APP=$(
        whiptail --title "SNS" --menu \
            "Which software do you want to install?" 0 50 0 \
            "1" "LinuxQQ(在线聊天软件)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) install_linux_qq ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_social_network_service
}
###################
tmoe_download_class() {
    RETURN_TO_WHERE='tmoe_download_class'
    NON_DEBIAN='false'
    DEPENDENCY_01=""
    TMOE_APP=$(
        whiptail --title "documents" --menu \
            "Which software do you want to install?" 0 50 0 \
            "1" "🍨 aria2(linux平台超强文件下载器)" \
            "2" "🖼 work_crawler:漫畫、小説下載工具@kanasimi" \
            "3" "📉 百度网盘(x64,提供文件的网络备份,同步和分享服务)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) tmoe_aria2_manager ;;
    2) start_kanasimi_work_crawler ;;
    3) install_baidu_netdisk ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_download_class
}
####################
start_kanasimi_work_crawler() {
    RETURN_TO_WHERE='check_kanasimi_work_crawler'
    install_nodejs
    check_kanasimi_work_crawler
}
###############
install_nodejs() {
    NON_DEBIAN='false'
    DEPENDENCY_01=""
    DEPENDENCY_02=""
    if [ ! $(command -v 7za) ]; then
        if [ "${LINUX_DISTRO}" = "debian" ]; then
            DEPENDENCY_01="p7zip-full"
        else
            DEPENDENCY_01="p7zip"
        fi
    fi
    if [ ! $(command -v node) ]; then
        DEPENDENCY_02="nodejs"
    fi
    if [ ! -z "${DEPENDENCY_01}" ] || [ ! -z "${DEPENDENCY_02}" ]; then
        beta_features_quick_install
    fi

    if [ ! $(command -v npm) ]; then
        bash -c "$(curl -Lv https://npmjs.org/install.sh | sed 's@registry.npmjs.org@registry.npm.taobao.org@g')"
        if [ ! $(command -v npm) ]; then
            ${TMOE_INSTALLATON_COMMAND} npm
        fi
        cat <<-'EOF'
			npm config set registry https://registry.npm.taobao.org
			npm config set disturl https://npm.taobao.org/dist
			npm config set electron_mirror https://npm.taobao.org/mirrors/electron/
		EOF
        echo "${YELLOW}是否需要将npm官方源更换为淘宝源[Y/n]${RESET} "
        echo "更换后可以加快国内的下载速度,${YELLOW}按回车键确认，输n拒绝。${RESET}"
        echo "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .[Y/n]"
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
tmoe_documents_menu() {
    RETURN_TO_WHERE='tmoe_documents_menu'
    NON_DEBIAN='false'
    DEPENDENCY_01=""
    TMOE_APP=$(
        whiptail --title "documents" --menu \
            "Which software do you want to install?" 0 50 0 \
            "1" "LibreOffice(开源、自由的办公文档软件)" \
            "2" "WPS office(办公软件)" \
            "3" "GNU Emacs(著名的集成开发环境和文本编辑器)" \
            "4" "Chinese manual(中文手册)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) install_libre_office ;;
    2) install_wps_office ;;
    3) install_emacs ;;
    4) install_chinese_manpages ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_documents_menu
}
####################
install_emacs() {
    DEPENDENCY_02="emacs"
    beta_features_quick_install
}
#############
install_clementine() {
    DEPENDENCY_02="clementine"
    beta_features_quick_install
}
##########
batch_compression_of_pictures() {
    source ${TMOE_TOOL_DIR}/optimization/compress_pictures
}
############
tmoe_multimedia_menu() {
    RETURN_TO_WHERE='tmoe_multimedia_menu'
    NON_DEBIAN='false'
    DEPENDENCY_01=""
    TMOE_APP=$(whiptail --title "Picture&Video&Music" --menu \
        "Which software do you want to install?" 0 50 0 \
        "1" "🗜️ Batch compression of pics批量压缩图片" \
        "2" "📽️ MPV(开源、跨平台的音视频播放器)" \
        "3" "🎬 腾讯视频:国产Linux在线视频软件" \
        "4" "🖼 GIMP(GNU 图像处理程序)" \
        "5" "🍊 Clementine(小柑橘音乐播放器)" \
        "6" "🎞️ Parole(xfce默认媒体播放器,风格简洁)" \
        "7" "🎧 网易云音乐(x86_64,专注于发现与分享的音乐产品)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) batch_compression_of_pictures ;;
    2) install_mpv ;;
    3) install_tencent_video ;;
    4) install_gimp ;;
    5) install_clementine ;;
    6) install_parole ;;
    7) install_netease_163_cloud_music ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_multimedia_menu
}
#############
install_tencent_video() {
    echo "本文件提取自官方v1.0.10_amd64.deb,开发者分离了amd64的electron环境并对其进行重新打包,以适应arm64架构。"
    echo "本版本仅适配deb系和arch系发行版，红帽系用户请自行测试。"
    echo "若安装失败，则请手动前往官网下载安装"
    echo "URL: ${YELLOW}https://v.qq.com/download.html#Linux${RESET}"
    tenvideo_env
    check_electron
    git_clone_tenvideo
}
#############
git_clone_tenvideo() {
    cd /tmp
    rm -rv ${TENVIDEO_FOLDER} 2>/dev/null
    git clone --depth=1 ${TENVIDEO_GIT} ${TENVIDEO_FOLDER}
    tar -PpJxvf ${TENVIDEO_FOLDER}/app.tar.xz
    rm -rv ${TENVIDEO_FOLDER}
    echo "安装完成，如需卸载，请手动输${RED}rm -rv${RESET} ${BLUE}${TENTVIDEO_OPT} ${TENVIDEO_LNK}${RESET}"
}
############
tmoe_games_menu() {
    RETURN_TO_WHERE='tmoe_games_menu'
    NON_DEBIAN='false'
    DEPENDENCY_01=""
    TMOE_APP=$(whiptail --title "GAMES" --menu \
        "Which game do you want to install?" 0 50 0 \
        "1" "install Steam-x86_64(安装蒸汽游戏平台)" \
        "2" "remove Steam(卸载)" \
        "3" "cataclysm大灾变-劫后余生(末日幻想背景的探索生存游戏)" \
        "4" "mayomonogatari斯隆与马克贝尔的谜之物语(nds解谜游戏)" \
        "5" "wesnoth韦诺之战(奇幻背景的回合制策略战棋游戏)" \
        "6" "SuperTuxKart(3D卡丁车)" \
        "7" "retroarch(全能复古游戏模拟器)" \
        "8" "dolphin-emu(任天堂wii模拟器)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1) install_steam_app ;;
    2) remove_steam_app ;;
    3) install_game_cataclysm ;;
    4) install_nds_game_mayomonogatari ;;
    5) install_wesnoth_game ;;
    6) install_supertuxkart_game ;;
    7) install_retroarch ;;
    8) install_dolphin-emu ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_games_menu
}
#############
install_retroarch() {
    DEPENDENCY_01='retroarch'
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        DEPENDENCY_02='^libretro'
    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02='retroarch-assets-xmb'
    else
        DEPENDENCY_02=''
    fi
    beta_features_quick_install
}
############
install_dolphin-emu() {
    DEPENDENCY_01='dolphin-emu'
    DEPENDENCY_02='dolphin-emu-git'
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        DEPENDENCY_02=''
    fi
    beta_features_quick_install
}
################
remove_debian_steam_app() {
    if [ "${ARCH_TYPE}" != "i386" ]; then
        echo 'dpkg  --remove-architecture i386'
        echo '正在移除对i386软件包的支持'
        #apt purge ".*:i386"
        aptitude remove ~i~ri386
        dpkg --remove-architecture i386
        apt update
    fi
}
###############
remove_steam_app() {
    echo "${TMOE_REMOVAL_COMMAND} steam-launcher steam"
    ${TMOE_REMOVAL_COMMAND} steam-launcher steam
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        remove_debian_steam_app
    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        #remove_fedora_steam_app
        rm -fv /etc/yum.repos.d/steam.repo
    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        remove_arch_steam_app
    fi
}
###############
install_debian_steam_app() {
    LATEST_DEB_REPO='https://mirrors.tuna.tsinghua.edu.cn/steamos/steam/pool/steam/s/steam/'
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
    echo "正在修改/etc/pacman.conf中第${ARCH_MULTI_LIB_LINE}行中的multilib"
    sed -i "${ARCH_MULTI_LIB_LINE}c\[multilib]" pacman.conf
    sed -i "${ARCH_MULTI_LIB_INCLUDE_LINE}c\Include = /etc/pacman.d/mirrorlist" pacman.conf
}
#################
remove_arch_steam_app() {
    check_arch_multi_lib_line
    echo "正在注释掉/etc/pacman.conf中第${ARCH_MULTI_LIB_LINE}行中的multilib"
    sed -i "${ARCH_MULTI_LIB_LINE}c\#[multilib]" pacman.conf
    sed -i "${ARCH_MULTI_LIB_INCLUDE_LINE}c\#Include = /etc/pacman.d/mirrorlist" pacman.conf
}
################
install_steam_app() {
    case "${ARCH_TYPE}" in
    amd64 | i386) ;;
    *)
        echo "${RED}WARNING！${RESET}检测到您使用的是${BLUE}${ARCH_TYPE}${RESET}架构，请勿在该架构上安装steam"
        echo "Do not install steam on this architecture."
        echo "是否需要继续安装？"
        do_you_want_to_continue
        ;;
    esac
    DEPENDENCY_01='steam-launcher'
    DEPENDENCY_02="steam"
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        install_debian_steam_app
    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        install_fedora_steam_app
        beta_features_quick_install
    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_01='steam-native-runtime'
        install_arch_steam_app
        #此处需要选择显卡驱动，故不要使用quick_install_function
        echo "pacman -Syu ${DEPENDENCY_01} ${DEPENDENCY_02}"
        pacman -Syu ${DEPENDENCY_01} ${DEPENDENCY_02}
    else
        beta_features_quick_install
    fi
}
####################
install_supertuxkart_game() {
    DEPENDENCY_02="supertuxkart"
    beta_features_quick_install
}
###################
install_wesnoth_game() {
    DEPENDENCY_01="wesnoth"
    DEPENDENCY_02=""
    NON_DEBIAN='false'
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
    NON_DEBIAN='false'
    beta_features_quick_install
}
#############
install_linux_qq() {
    DEPENDENCY_01="linuxqq"
    DEPENDENCY_02=""
    if [ -e "${APPS_LNK_DIR}/qq.desktop" ]; then
        press_enter_to_reinstall
    fi
    cd /tmp
    if [ "${ARCH_TYPE}" = "arm64" ]; then
        if [ "${LINUX_DISTRO}" = "debian" ]; then
            aria2c --allow-overwrite=true -k 1M -o LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb"
            apt show ./LINUXQQ.deb
            apt install -y ./LINUXQQ.deb
        else
            aria2c --allow-overwrite=true -k 1M -o LINUXQQ.sh http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.sh
            chmod +x LINUXQQ.sh
            sudo ./LINUXQQ.sh
            #即使是root用户也需要加sudo
        fi
    elif [ "${ARCH_TYPE}" = "amd64" ]; then
        if [ "${LINUX_DISTRO}" = "debian" ]; then
            aria2c --allow-overwrite=true -k 1M -o LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_amd64.deb"
            apt show ./LINUXQQ.deb
            apt install -y ./LINUXQQ.deb
            #http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb
        else
            aria2c --allow-overwrite=true -k 1M -o LINUXQQ.sh "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_x86_64.sh"
            chmod +x LINUXQQ.sh
            sudo ./LINUXQQ.sh
        fi
    fi
    echo "若安装失败，则请前往官网手动下载安装。"
    echo "url: https://im.qq.com/linuxqq/download.html"
    rm -fv ./LINUXQQ.deb ./LINUXQQ.sh 2>/dev/null
    beta_features_install_completed
}
###################
install_nds_game_mayomonogatari() {
    DEPENDENCY_01="desmume"
    DEPENDENCY_02="p7zip-full"
    NON_DEBIAN='false'
    beta_features_quick_install
    if [ -e "斯隆与马克贝尔的谜之物语/3782.nds" ]; then
        echo "检测到您已下载游戏文件，路径为${HOME}/斯隆与马克贝尔的谜之物语"
        press_enter_to_reinstall
    fi
    cd ${HOME}
    mkdir -p '斯隆与马克贝尔的谜之物语'
    cd '斯隆与马克贝尔的谜之物语'
    aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o slymkbr1.zip http://k73dx1.zxclqw.com/slymkbr1.zip
    aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o mayomonogatari2.zip http://k73dx1.zxclqw.com/mayomonogatari2.zip
    7za x slymkbr1.zip
    7za x mayomonogatari2.zip
    mv -f 斯隆与马克贝尔的谜之物语k73/* ./
    mv -f 迷之物语/* ./
    rm -f *url *txt
    rm -rf 迷之物语 斯隆与马克贝尔的谜之物语k73
    rm -f slymkbr1.zip* mayomonogatari2.zip*

    echo "安装完成，您需要手动执行${GREEN}/usr/games/desmume${RESER}，并进入'${HOME}/斯隆与马克贝尔的谜之物语'目录加载游戏"
    echo "如需卸载,则请手动输${TMOE_REMOVAL_COMMAND} desmume ; rm -rf ~/斯隆与马克贝尔的谜之物语"
    echo 'Press enter to start the nds emulator.'
    echo "${YELLOW}按回车键启动游戏。${RESET}"
    do_you_want_to_continue
    /usr/games/desmume "${HOME}/斯隆与马克贝尔的谜之物语/3782.nds" 2>/dev/null &
}
##################
install_game_cataclysm() {
    DEPENDENCY_01="cataclysm-dda-curses"
    DEPENDENCY_02="cataclysm-dda-sdl"
    NON_DEBIAN='false'
    beta_features_quick_install
    echo "在终端环境下，您需要缩小显示比例，并输入cataclysm来启动字符版游戏。"
    echo "在gui下，您需要输cataclysm-tiles来启动画面更为华丽的图形界面版游戏。"
    echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
    echo "${YELLOW}按回车键启动。${RESET}"
    read
    cataclysm
}
##############################################################
install_package_manager_gui() {
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        install_synaptic
    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        echo "检测到您使用的是arch系发行版，将为您安装pamac"
        install_pamac_gtk
    else
        echo "检测到您使用的不是deb系发行版，将为您安装gnome_software"
        install_gnome_software
    fi
}
######################
install_gimp() {
    DEPENDENCY_01="gimp"
    DEPENDENCY_02=""
    NON_DEBIAN='false'
    beta_features_quick_install
}
##############
install_parole() {
    DEPENDENCY_01="parole"
    DEPENDENCY_02=""
    NON_DEBIAN='false'
    beta_features_quick_install
}
###############
install_pamac_gtk() {
    DEPENDENCY_01="pamac"
    DEPENDENCY_02=""
    NON_DEBIAN='false'
    beta_features_quick_install
}
#####################
install_synaptic() {
    if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Install安装" --no-button "Remove移除" --yesno "新立德是一款使用apt的图形化软件包管理工具，您也可以把它理解为软件商店。Synaptic is a graphical package management program for apt. It provides the same features as the apt-get command line utility with a GUI front-end based on Gtk+.它提供与apt-get命令行相同的功能，并带有基于Gtk+的GUI前端。功能：1.安装、删除、升级和降级单个或多个软件包。 2.升级整个系统。 3.管理软件源列表。  4.自定义过滤器选择(搜索)软件包。 5.按名称、状态、大小或版本对软件包进行排序。 6.浏览与所选软件包相关的所有可用在线文档。♪(^∇^*) " 19 50); then
        DEPENDENCY_01="synaptic"
        DEPENDENCY_02="gdebi"
        NON_DEBIAN='true'
        beta_features_quick_install
        sed -i 's/synaptic-pkexec/synaptic/g' ${APPS_LNK_DIR}/synaptic.desktop
        echo "synaptic和gdebi安装完成，您可以将deb文件的默认打开程序修改为gdebi"
    else
        echo "${YELLOW}您真的要离开我么？哦呜。。。${RESET}"
        echo "Do you really want to remove synaptic?"
        RETURN_TO_WHERE='software_center'
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} synaptic
        ${TMOE_REMOVAL_COMMAND} gdebi
    fi
}
##########################################
install_chinese_manpages() {
    echo '即将为您安装 debian-reference-zh-cn、manpages、manpages-zh和man-db'

    if [ "${LINUX_DISTRO}" = "debian" ]; then
        DEPENDENCY_01="manpages manpages-zh man-db"

    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_01="man-pages-zh_cn"

    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        DEPENDENCY_01="man-pages-zh-CN"
    else
        DEPENDENCY_01="man-pages-zh-CN"
    fi
    DEPENDENCY_02="debian-reference-zh-cn"
    NON_DEBIAN='false'
    beta_features_quick_install
    if [ ! -e "${HOME}/文档/debian-handbook/usr/share/doc/debian-handbook/html" ]; then
        mkdir -p ${HOME}/文档/debian-handbook
        cd ${HOME}/文档/debian-handbook
        GREP_NAME='debian-handbook'
        LATEST_DEB_REPO='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/d/debian-handbook/'
        download_tuna_repo_deb_file_all_arch
        #aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'debian-handbook.deb' 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/d/debian-handbook/debian-handbook_8.20180830_all.deb'
        THE_LATEST_DEB_FILE='kali-undercover.deb'
        if [ "${BUSYBOX_AR}" = 'true' ]; then
            busybox ar xv ${LATEST_DEB_VERSION}
        else
            ar xv ${LATEST_DEB_VERSION}
        fi
        tar -Jxvf data.tar.xz ./usr/share/doc/debian-handbook/html
        ls | grep -v usr | xargs rm -rf
        ln -sf ./usr/share/doc/debian-handbook/html/zh-CN/index.html ./
    fi
    echo "man一款帮助手册软件，它可以帮助您了解关于命令的详细用法。"
    echo "man a help manual software, which can help you understand the detailed usage of the command."
    echo "您可以输${YELLOW}man 软件或命令名称${RESET}来获取帮助信息，例如${YELLOW}man bash${RESET}或${YELLOW}man zsh${RESET}"
}
#####################
install_wps_office() {
    DEPENDENCY_01="wps-office"
    DEPENDENCY_02=""
    NON_DEBIAN='false'
    cd /tmp
    if [ -e "${APPS_LNK_DIR}/wps-office-wps.desktop" ]; then
        press_enter_to_reinstall
    fi

    if [ "${LINUX_DISTRO}" = "debian" ]; then
        dpkg --configure -a
        LatestWPSLink=$(curl -L https://linux.wps.cn/ | grep '\.deb' | grep -i "${ARCH_TYPE}" | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o WPSoffice.deb "${LatestWPSLink}"
        apt show ./WPSoffice.deb
        apt install -y ./WPSoffice.deb

    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_01="wps-office-cn"
        beta_features_quick_install
    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        LatestWPSLink=$(curl -L https://linux.wps.cn/ | grep '\.rpm' | grep -i "$(uname -m)" | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o WPSoffice.rpm "https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9505/wps-office-11.1.0.9505-1.x86_64.rpm"
        rpm -ivh ./WPSoffice.rpm
    fi

    echo "若安装失败，则请前往官网手动下载安装。"
    echo "url: https://linux.wps.cn"
    rm -fv ./WPSoffice.deb ./WPSoffice.rpm 2>/dev/null
    beta_features_install_completed
}
###################
install_libre_office() {
    #ps -e >/dev/null || echo "/proc分区未挂载，请勿安装libreoffice,赋予proot容器真实root权限可解决相关问题，但强烈不推荐！"
    case ${TMOE_PROOT} in
    no)
        echo "${RED}WARNING！${RESET}检测到您无权读取${GREEN}/proc${RESET}的某些数据！"
        echo "本工具将为此软件自动打补丁以解决无法运行的问题，但无法保证补丁有效。"
        ;;
    esac
    #RETURN_TO_WHERE='software_center'
    #do_you_want_to_continue
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        DEPENDENCY_01='--no-install-recommends libreoffice'
    else
        DEPENDENCY_01="libreoffice"
    fi
    DEPENDENCY_02="libreoffice-l10n-zh-cn libreoffice-gtk3"
    NON_DEBIAN='false'
    beta_features_quick_install
    case "${TMOE_PROOT}" in
    no)
        patch_libreoffice
        echo "打补丁完成"
        ;;
    esac
}
###################
patch_libreoffice() {
    mkdir -p /prod/version
    cd /usr/lib/libreoffice/program
    rm -f oosplash
    curl -Lo 'oosplash' https://gitee.com/mo2/patch/raw/libreoffice/oosplash
    chmod +x oosplash
}
##################
check_libreoffice_patch() {
    if [ $(command -v libreoffice) ]; then
        patch_libreoffice
    fi
}
############
install_baidu_netdisk() {
    DEPENDENCY_01="baidunetdisk"
    DEPENDENCY_02=""
    if [ "${ARCH_TYPE}" != "amd64" ]; then
        arch_does_not_support
    fi

    if [ -e "${APPS_LNK_DIR}/baidunetdisk.desktop" ]; then
        press_enter_to_reinstall
    fi
    cd /tmp
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_01="baidunetdisk-bin"
        beta_features_quick_install
    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'baidunetdisk.rpm' "http://wppkg.baidupcs.com/issue/netdisk/Linuxguanjia/3.3.2/baidunetdisk-3.3.2.x86_64.rpm"
        rpm -ivh 'baidunetdisk.rpm'
    elif [ "${LINUX_DISTRO}" = "debian" ]; then
        #GREP_NAME='baidunetdisk'
        #LATEST_DEB_REPO='http://archive.ubuntukylin.com/software/pool/'
        #download_ubuntu_kylin_deb_file_model_02
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o baidunetdisk.deb "http://wppkg.baidupcs.com/issue/netdisk/Linuxguanjia/3.3.2/baidunetdisk_3.3.2_amd64.deb"
        #apt show ./baidunetdisk.deb
        #apt install -y ./baidunetdisk.deb
    fi
    echo "若安装失败，则请前往官网手动下载安装"
    echo "url：https://pan.baidu.com/download"
    #rm -fv ./baidunetdisk.deb
    beta_features_install_completed
}
######################
install_netease_163_cloud_music() {
    DEPENDENCY_01="netease-cloud-music"
    DEPENDENCY_02=""
    case "${ARCH_TYPE}" in
    amd64 | i386) ;;
    *) arch_does_not_support ;;
    esac
    if [ -e "${APPS_LNK_DIR}/netease-cloud-music.desktop" ]; then
        press_enter_to_reinstall
    fi
    cd /tmp
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_01="netease-cloud-music"
        beta_features_quick_install
    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        curl -Lv https://dl.senorsen.com/pub/package/linux/add_repo.sh | sh -
        dnf install http://dl-http.senorsen.com/pub/package/linux/rpm/senorsen-repo-0.0.1-1.noarch.rpm
        dnf install -y netease-cloud-music
        #https://github.com/ZetaoYang/netease-cloud-music-appimage/releases
        #appimage格式
    else
        non_debian_function
        GREP_NAME='netease-cloud-music'
        case $(date +%Y%m) in
        202008 | 202009)
            echo "优麒麟软件仓库于2020年8月份中下旬进行维护，您可能无法正常下载"
            do_you_want_to_continue
            ;;
        esac
        if [ "${ARCH_TYPE}" = "amd64" ]; then
            LATEST_DEB_REPO='http://archive.ubuntukylin.com/software/pool/'
            download_ubuntu_kylin_deb_file_model_02
            #aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o netease-cloud-music.deb "http://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb"
        else
            LATEST_DEB_REPO='http://mirrors.ustc.edu.cn/debiancn/pool/main/n/netease-cloud-music/'
            download_debian_cn_repo_deb_file_model_01
            #aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o netease-cloud-music.deb "http://mirrors.ustc.edu.cn/debiancn/pool/main/n/netease-cloud-music/netease-cloud-music_1.0.0%2Brepack.debiancn-1_i386.deb"
        fi
        echo "若安装失败，则请前往官网手动下载安装。"
        echo 'url: https://music.163.com/st/download'
        beta_features_install_completed
    fi
    press_enter_to_return
    tmoe_linux_tool_menu
}
############################
install_android_debug_bridge() {
    if [ ! $(command -v adb) ]; then
        if [ "${LINUX_DISTRO}" = "debian" ]; then
            DEPENDENCY_01="adb"
        else
            DEPENDENCY_01="android-tools"
        fi
    fi
    DEPENDENCY_02=""
    NON_DEBIAN='false'
    beta_features_quick_install
    adb --help
    echo "正在重启进程,您也可以手动输adb devices来获取设备列表"
    adb kill-server
    adb devices -l
    echo "即将为您自动进入adb shell模式，您也可以手动输adb shell来进入该模式"
    adb shell
}
####################
install_bleachbit_cleaner() {
    DEPENDENCY_01="bleachbit"
    DEPENDENCY_02=""
    NON_DEBIAN='false'
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
    NON_DEBIAN='false'
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
    echo '"xfce" "呜呜，(≧﹏ ≦)您真的要离开我么"  '
    echo '"lxde" "很庆幸能与阁下相遇（；´д｀）ゞ "  '
    echo '"mate" "喔...喔呜...我不舍得你走/(ㄒoㄒ)/~~"  '
    #新功能预告：即将适配非deb系linux的gui卸载功能
    echo "${YELLOW}按回车键确认卸载${RESET}"
    echo 'Press enter to remove,press Ctrl + C to cancel'
    RETURN_TO_WHERE='tmoe_linux_tool_menu'
    do_you_want_to_continue
    if [ "${LINUX_DISTRO}" = "debian" ]; then
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
    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        pacman -Rsc xfce4 xfce4-goodies
        pacman -Rsc mate mate-extra
        pacman -Rsc lxde lxqt
        pacman -Rsc plasma-desktop
        pacman -Rsc gnome gnome-extra
        pacman -Rsc cinnamon
        pacman -Rsc deepin deepin-extra
    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        dnf groupremove -y xfce
        dnf groupremove -y mate-desktop
        dnf groupremove -y lxde-desktop
        dnf groupremove -y lxqt
        dnf groupremove -y "KDE" "GNOME" "Cinnamon Desktop"
        dnf remove -y deepin-desktop
    else
        ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
    fi
}
##########################
remove_tmoe_linux_tool() {
    cd /usr/local/bin
    echo "${RED}rm -rv ${APPS_LNK_DIR}/tmoe-linux.desktop ${HOME}/.config/tmoe-linux startvnc stopvnc debian-i startx11vnc startxsdl x11vncpasswd .tmoe-linux-qemu startqemu ${TMOE_GIT_DIR}${RESET}"
    DEPENDENCIES='git aria2 pv wget curl less xz-utils newt whiptail'
    echo "${RED}${TMOE_REMOVAL_COMMAND} ${DEPENDENCIES}${RESET}"
    do_you_want_to_continue
    rm -rfv ${APPS_LNK_DIR}/tmoe-linux.desktop ${HOME}/.config/tmoe-linux startvnc stopvnc debian-i startx11vnc ${TMOE_GIT_DIR} startxsdl x11vncpasswd
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCIES}
    exit 1
}
############################
software_center
