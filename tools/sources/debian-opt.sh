#!/usr/bin/env bash
##################
add_debian_opt_repo() {
    notes_of_debian_opt_repo
    printf "%s\n" "检测到您未添加debian_opt软件源，是否添加？"
    do_you_want_to_continue
    add_debian_opt_gpg_key
}
##############
notes_of_debian_opt_repo() {
    printf "%s\n" "debian_opt_repo列表的所有软件均来自于开源项目"
    printf "%s\n" "感谢https://github.com/coslyk/debianopt-repo 仓库的维护者coslyk，以及各个项目的原开发者。"
    printf "%s\n" "非deb系发行版软件由2moe进行适配,并制作补丁。"
    printf "%s\n" "截至2020年8月中旬，在proot容器环境下,部分软件(例如cocomusic)必须打补丁,否则将有可能出现白屏现象。"
}
#############
switch_debian_opt_repo_sources() {
    non_debian_function
    if grep '^deb.*ustc' ${OPT_REPO_LIST}; then
        OPT_REPO_NAME='USTC'
    else
        OPT_REPO_NAME='bintray'
    fi
    if (whiptail --title "您想要对这个小可爱做什么呢" --yes-button "USTC" --no-button "bintray" --yesno "检测到您当前的软件源为${OPT_REPO_NAME}\n您想要切换为哪个软件源?♪(^∇^*) " 0 0); then
        printf "%s\n%s\n" "deb ${OPT_URL_01} buster main" "#deb ${OPT_URL_02} buster main" >${OPT_REPO_LIST}
    else
        printf "%s\n%s\n" "#deb ${OPT_URL_01} buster main" "deb ${OPT_URL_02} buster main" >${OPT_REPO_LIST}
    fi
    apt update
}
#######################
explore_debian_opt_repo() {
    case "${LINUX_DISTRO}" in
    debian)
        install_gpg
        if [ ! -e "${OPT_REPO_LIST}" ]; then
            add_debian_opt_repo
        fi
        ;;
    *)
        if [ ! $(command -v electron) ]; then
            notes_of_debian_opt_repo
            do_you_want_to_continue
        fi
        ;;
    esac
    debian_opt_menu
}
#################
debian_opt_menu() {

    RETURN_TO_WHERE='debian_opt_menu'
    RETURN_TO_MENU='debian_opt_menu'
    DEPENDENCY_02=""
    cd ${APPS_LNK_DIR}
    #16 50 7
    INSTALL_APP=$(whiptail --title "DEBIAN OPT REPO" --menu \
        "您想要安装哪个软件？\n Which software do you want to install? " 0 0 0 \
        "1" "🎶 music:以雅以南,以龠不僭" \
        "2" "📝 notes笔记:记录灵感,撰写文档,整理材料,回顾日记" \
        "3" "📺 videos视频:全网影视搜索,无损切割视频" \
        "4" "🖼️ pictures图像:bing壁纸,流程图绘制" \
        "5" "📖 reader:悦享生活,品味阅读" \
        "6" "🎮 games游戏:Minecraft启动器" \
        "7" "🍎 virtual machine虚拟机:win95,macos8" \
        "8" "👾 development程序开发:神经网络,深度学习,GUI设计" \
        "9" "⚛️ other:其他软件(electron及软件列表)" \
        "10" "fix sandbox(修复已安装应用的沙盒模式)" \
        "11" "switch source repo:切换软件源仓库" \
        "12" "remove(移除本仓库)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") software_center ;;
    1) debian_opt_music_app ;;
    2) debian_opt_note_app ;;
    3) debian_opt_video_app ;;
    4) debian_opt_picture_app ;;
    5) debian_opt_reader_app ;;
    6) debian_opt_game_app ;;
    7) debian_opt_virtual_machine_app ;;
    8) debian_opt_development_app ;;
    9) debian_opt_other_apps ;;
    10) fix_debian_opt_app_sandbox_mode ;;
    11) switch_debian_opt_repo_sources ;;
    12) remove_debian_opt_repo ;;
    esac
    ##########################
    press_enter_to_return
    debian_opt_menu
}
################
debian_opt_install_or_remove_01() {
    RETURN_TO_WHERE='debian_opt_install_or_remove_01'
    NOTICE_OF_REPAIR='false'
    OPT_APP_VERSION_TXT="${TMOE_LINUX_DIR}/${DEPENDENCY_01}_version.txt"
    INSTALL_APP=$(whiptail --title "${DEPENDENCY_01} manager" --menu \
        "您要对${DEPENDENCY_01}小可爱做什么?\nWhat do you want to do with the software?" 0 0 0 \
        "1" "install 安装" \
        "2" "upgrade 更新" \
        "3" "fix 修复" \
        "4" "remove 卸载" \
        "0" "🌚 Back 返回" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") ${RETURN_TO_MENU} ;;
    1) install_opt_app_01 ;;
    2) upgrade_opt_app_01 ;;
    3)
        NOTICE_OF_REPAIR='true'
        copy_debian_opt_usr_bin_file
        ;;
    4) remove_opt_app_01 ;;
    esac
    ##########################
    press_enter_to_return
    ${RETURN_TO_MENU}
}
################
debian_opt_install_or_remove_02() {
    RETURN_TO_WHERE='debian_opt_install_or_remove_02'
    NOTICE_OF_REPAIR='false'
    #OPT_APP_VERSION_TXT="${TMOE_LINUX_DIR}/${DEPENDENCY_01}_version.txt"
    INSTALL_APP=$(whiptail --title "${DEPENDENCY_01} manager" --menu \
        "您要对${DEPENDENCY_01}小可爱做什么?\nWhat do you want to do with the software?" 0 0 0 \
        "1" "install&fix 安装并修复" \
        "2" "remove 卸载" \
        "0" "🌚 Back 返回" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") ${RETURN_TO_MENU} ;;
    1) install_opt_app_02 ;;
    2) remove_opt_app_02 ;;
    esac
    ##########################
    press_enter_to_return
    ${RETURN_TO_MENU}
}
################
fix_debian_opt_app_sandbox_mode() {
    printf "%s\n" "${GREEN}chmod 4755${RESET} ${BLUE}/opt/electron/chrome-sandbox${RESET}"
    chmod 4755 /opt/electron/chrome-sandbox
    printf "%s\n" "正在修复您当前已安装的electron应用..."
    for i in chord cocomusic electron-netease-cloud-music hmcl iease-music listen1 lossless-cut lx-music-desktop marktext netron petal picgo simplenote zy-player; do
        if [ -f "/usr/bin/${i}" ]; then
            cp -pfv ${TMOE_OPT_BIN_DIR}/usr/bin/${i} /usr/bin
        fi
    done
    unset i
    if [ -e "/opt/draw.io/drawio" ]; then
        cp -pvf ${TMOE_OPT_BIN_DIR}/opt/draw.io/drawio /opt/draw.io
    fi
    if [ -e "/opt/Gridea/gridea" ]; then
        cp -pvf ${TMOE_OPT_BIN_DIR}/opt/Gridea/gridea /opt/Gridea
    fi
    if [ -e "/opt/Listen1/app.asar" ]; then
        sed -i "s@/app'@/app.asar'@g" /usr/bin/listen1
    fi
    printf "%s\n" "修复完成"
}
###########
check_debian_opt_app_version() {
    DEBIAN_OPT_REPO_POOL_URL="${OPT_URL_02}/pool/main/"
    APP_NAME_PREFIX="$(printf '%s\n' "${DEPENDENCY_01}" | cut -c 1)"
    DEBIAN_OPT_APP_PATH_URL="${DEBIAN_OPT_REPO_POOL_URL}${APP_NAME_PREFIX}/${DEPENDENCY_01}"
    THE_LATEST_DEB_FILE=$(curl -Lv "${DEBIAN_OPT_APP_PATH_URL}" | grep '.deb' | grep -v '.asc' | grep "${ARCH_TYPE}" | tail -n 1 | cut -d '"' -f 4 | cut -d ':' -f 2)
}
###############
download_debian_opt_app() {
    printf "%s\n" "${THE_LATEST_DEB_FILE}" >${OPT_APP_VERSION_TXT}
    DEBIAN_OPT_APP_URL="${DEBIAN_OPT_APP_PATH_URL}/${THE_LATEST_DEB_FILE}"
    DOWNLOAD_PATH='/tmp/.DEB_OPT_TEMP_FOLDER'
    ELECTRON_FILE_URL="${DEBIAN_OPT_APP_URL}"
    if [ -e "${DOWNLOAD_PATH}" ]; then
        rm -rv ${DOWNLOAD_PATH}
    fi
    aria2c_download_file_no_confirm
    extract_deb_file_01
    extract_deb_file_02
}
###################
copy_debian_opt_usr_bin_file() {
    case ${DEPENDENCY_01} in
    draw.io) cp -pf ${TMOE_OPT_BIN_DIR}/opt/draw.io/drawio /opt/draw.io ;;
    gridea) cp -pf ${TMOE_OPT_BIN_DIR}/opt/Gridea/gridea /opt/Gridea ;;
    *) cp -pf ${TMOE_OPT_BIN_DIR}/usr/bin/${DEPENDENCY_01} /usr/bin 2>/dev/null ;;
    esac
    case ${NOTICE_OF_REPAIR} in
    true) printf "%s\n" "修复完成" ;;
    *)
        printf "%s\n" "${BOLD}${DEPENDENCY_01}${RESET}在启动时，将根据您的用户权限来自动判断${BLUE}沙盒模式${RESET}的关闭与否。"
        case "${LINUX_DISTRO}" in
        debian)
            cat <<-ENDOFOPT
    若您在执行${YELLOW}apt upgrade${RESET}后无法启动${DEPENDENCY_01}，则请执行${GREEN}修复${RESET}操作。
    If you cannot start this app after executing ${YELLOW}apt upgrade${RESET},then please select the ${GREEN}fix${RESET} option.
ENDOFOPT
            ;;
        esac
        ;;
    esac
}
##############
remove_opt_app_01() {
    case "${LINUX_DISTRO}" in
    debian)
        printf "%s\n" "${RED}${TMOE_REMOVAL_COMMAND}${RESET} ${BLUE}${DEPENDENCY_01}${RESET}"
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01}
        ;;
    *)
        case ${DEPENDENCY_01} in
        cocomusic) DEBIAN_OPT_APP_DIR='/opt/CocoMusic' ;;
        gridea) DEBIAN_OPT_APP_DIR='/opt/Gridea' ;;
        listen1) DEBIAN_OPT_APP_DIR='/opt/Listen1' ;;
        hmcl) DEBIAN_OPT_APP_DIR='/opt/HMCL' ;;
        *) DEBIAN_OPT_APP_DIR="/opt/${DEPENDENCY_01}" ;;
        esac
        printf "%s\n" "${RED}rm -rv${RESET} ${BLUE}${DEBIAN_OPT_APP_DIR} ${OPT_APP_VERSION_TXT} ${APPS_LNK_DIR}/${DEPENDENCY_01}.desktop${RESET}"
        do_you_want_to_continue
        rm -rv ${DEBIAN_OPT_APP_DIR} ${OPT_APP_VERSION_TXT} ${APPS_LNK_DIR}/${DEPENDENCY_01}.desktop
        ;;
    esac
}
################
remove_opt_app_02() {
    printf "%s\n" "${RED}${TMOE_REMOVAL_COMMAND}${RESET} ${BLUE}${DEPENDENCY_01}${RESET}"
    case ${DEPENDENCY_01} in
    cocomusic) DEBIAN_OPT_APP_DIR='/opt/CocoMusic' ;;
    gridea) DEBIAN_OPT_APP_DIR='/opt/Gridea' ;;
    listen1) DEBIAN_OPT_APP_DIR='/opt/Listen1' ;;
    hmcl) DEBIAN_OPT_APP_DIR='/opt/HMCL' ;;
    *) DEBIAN_OPT_APP_DIR="/opt/${DEPENDENCY_01}" ;;
    esac
    printf "%s\n" "${RED}rm -rv${RESET} ${BLUE}${DEBIAN_OPT_APP_DIR} ${OPT_APP_VERSION_TXT} ${APPS_LNK_DIR}/${DEPENDENCY_01}.desktop${RESET}"
    do_you_want_to_continue
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01}
    rm -rv ${DEBIAN_OPT_APP_DIR} ${OPT_APP_VERSION_TXT} ${APPS_LNK_DIR}/${DEPENDENCY_01}.desktop
}
################
install_opt_app_01() {
    case "${LINUX_DISTRO}" in
    debian) beta_features_quick_install ;;
    *)
        check_electron
        check_debian_opt_app_version
        download_debian_opt_app
        ;;
    esac
    copy_debian_opt_usr_bin_file
    case ${DEPENDENCY_01} in
    electron-netease-cloud-music)
        check_electron_netease_cloud_music
        check_163_music_icon
        ;;
    listen1) check_listen1 ;;
    esac
}
################
check_163_music_icon() {
    NETEASE_MUSIC_ICON="/usr/share/icons/hicolor/scalable/apps/${DEPENDENCY_01}.svg"
    if [ -e "${NETEASE_MUSIC_ICON}" ]; then
        sed -i "s@Icon=${DEPENDENCY_01}@Icon=${NETEASE_MUSIC_ICON}@g" "${APPS_LNK_DIR}/${DEPENDENCY_01}.desktop"
    fi
}
#########
patch_opt_music_app() {
    install_electron_v8
    cd /tmp
    GIT_TEMP_FOLDER=".${DEPENDENCY_01}_TEMP_FOLDER"
    git clone --depth=1 ${GIT_PATCH_URL} ${GIT_TEMP_FOLDER}
    tar -PpJxvf ${GIT_TEMP_FOLDER}/patch.tar.xz
    rm -rv ${GIT_TEMP_FOLDER}
}
##############
git_clone_electron_virtual_machine() {
    cd /tmp
    TEMP_FOLDER=".${DEPENDENCY_01}_TEMP_FOLDER"
    rm -rv ${TEMP_FOLDER} 2>/dev/null
    git clone --depth=1 ${GIT_REPO_URL} ${TEMP_FOLDER}
    cd ${TEMP_FOLDER}
    cat .vm_* >vm.tar.xz
    tar -PpJxvf vm.tar.xz
    cd ..
    rm -rv ${TEMP_FOLDER}
}
#############
install_electron_macintosh_8() {
    printf "%s\n" "下载大小约131.09MiB,解压后约占658M"
    do_you_want_to_continue
    GIT_REPO_URL='https://gitee.com/ak2/electron_macos8.git'
    git_clone_electron_virtual_machine
}
#############
install_electron_windows_95() {
    printf "%s\n" "下载大小约166.19MiB,解压后约占1.2G"
    do_you_want_to_continue
    GIT_REPO_URL='https://gitee.com/ak2/electron_win95.git'
    git_clone_electron_virtual_machine
}
##############
install_opt_app_02() {
    case ${DEPENDENCY_01} in
    macintosh.js) ;;
    windows95) ;;
    *)
        case "${LINUX_DISTRO}" in
        debian) beta_features_quick_install ;;
        *) ;;
        esac
        ;;
    esac

    case ${DEPENDENCY_01} in
    cocomusic)
        GIT_PATCH_URL='https://gitee.com/ak2/cocomusic-patch.git'
        patch_opt_music_app
        #printf "%s\n" "在${YELLOW}tightvnc服务${RESET}下，cocomusic可能仍存在${RED}白屏${RESET}现象。对于deb系发行版，您可以换用${BLUE}x11vnc服务${RESET};对于arch系发行版，您可以换用${BLUE}tigervnc服务${RESET}来运行本app。"
        #202008注：已经修复了tightvnc无法启动cocomusic的问题
        ;;
    iease-music)
        GIT_PATCH_URL='https://gitee.com/ak2/iease-music-patch.git'
        patch_opt_music_app
        ;;
    macintosh.js) install_electron_macintosh_8 ;;
    windows95) install_electron_windows_95 ;;
    esac
    copy_debian_opt_usr_bin_file
}
################
display_debian_opt_app_version() {
    printf "%s\n" "正在检测版本信息..."
    if [ -e "${OPT_APP_VERSION_TXT}" ]; then
        LOCAL_OPT_APP_VERSION=$(sed -n p ${OPT_APP_VERSION_TXT} | head -n 1)
    else
        LOCAL_OPT_APP_VERSION="您尚未安装${DEPENDENCY_01}"
    fi
    cat <<-ENDofTable
		╔═══╦═══════════════════╦════════════════
		║   ║                   ║                    
		║   ║    ✨最新版本     ║   本地版本 🎪
		║   ║  Latest version   ║  Local version     
		║---║-------------------║--------------------
		║ 1 ║                     ${LOCAL_OPT_APP_VERSION} 
		║   ║${THE_LATEST_DEB_FILE} 

	ENDofTable
    printf "%s\n" "Do you want to upgrade it?"
    do_you_want_to_continue
}
#################
upgrade_opt_app_01() {
    if [ -e "/usr/share/icons/${DEPENDENCY_01}.png" ]; then
        if [ $(command -v catimg) ]; then
            catimg /usr/share/icons/${DEPENDENCY_01}.png
        else
            random_neko
        fi
    else
        random_neko
    fi

    case "${LINUX_DISTRO}" in
    debian)
        apt update
        apt install -y ${DEPENDENCY_01}
        copy_debian_opt_usr_bin_file
        ;;
    *)
        check_debian_opt_app_version
        display_debian_opt_app_version
        install_opt_app_01
        ;;
    esac
}
###############
remove_electron_stable() {
    printf "%s\n" "卸载后将导致依赖electron的应用无法正常运行。"
    case "${LINUX_DISTRO}" in
    debian)
        printf "%s\n" "${RED}apt remove -y${RESET} ${BLUE}${DEPENDENCY_01} ; rm -v ${OPT_APP_VERSION_TXT}${RESET}"
        do_you_want_to_continue
        apt remove -y ${DEPENDENCY_01}
        ;;
    *)
        printf "%s\n" "${RED}rm -rv${RESET} ${BLUE}/opt/electron /usr/bin/electron ${OPT_APP_VERSION_TXT}${RESET}"
        do_you_want_to_continue
        rm -rv /opt/electron
        ;;
    esac
}
############
install_electronic_stable() {
    if [ ! $(command -v electron) ]; then
        download_the_latest_electron
    else
        case "${LINUX_DISTRO}" in
        debian)
            apt update
            apt install -y ${DEPENDENCY_01}
            ;;
        *)
            check_electron_version
            ;;
        esac
    fi
}
############
check_electron_version() {
    electron -v --no-sandbox | head -n 1 >${OPT_APP_VERSION_TXT}
    latest_electron
    THE_LATEST_DEB_FILE=${ELECTRON_VERSION}
    display_debian_opt_app_version
    download_the_latest_electron
}
########
electron_manager() {
    RETURN_TO_WHERE='electron_manager'
    DEPENDENCY_01='electron'
    OPT_APP_VERSION_TXT="${TMOE_LINUX_DIR}/${DEPENDENCY_01}_version.txt"
    INSTALL_APP=$(whiptail --title "${DEPENDENCY_01} manager" --menu \
        "您要对${DEPENDENCY_01}小可爱做什么?\nWhat do you want to do with the software?" 0 0 0 \
        "1" "install/upgrade 安装/更新" \
        "2" "remove electron-stable" \
        "3" "remove electron-v8.x" \
        "0" "🌚 Back 返回" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") ${RETURN_TO_MENU} ;;
    1) check_electron_version ;;
    2) remove_electron_stable ;;
    3)
        printf "%s\n" "部分软件依赖于旧版electron,卸载后将导致这些软件无法正常运行。"
        printf "%s\n" "${RED}rm -rv${RESET} ${BLUE}/opt/electron-v8${RESET}"
        do_you_want_to_continue
        rm -rv /opt/electron-v8
        ;;
    esac
    ##########################
    press_enter_to_return
    ${RETURN_TO_MENU}
}
#############
debian_opt_game_app() {
    DEPENDENCY_02=''
    RETURN_TO_WHERE='debian_opt_game_app'
    RETURN_TO_MENU='debian_opt_game_app'
    DEBIAN_INSTALLATION_MENU='00'
    INSTALL_APP=$(whiptail --title "GAMES" --menu \
        "您想要安装哪个软件?\nWhich software do you want to install? " 0 0 0 \
        "1" "#hmcl:跨平台且广受欢迎的Minecraft(我的世界)启动器" \
        "2" "#gamehub:管理Steam,GOG,Humble Bundle等平台的游戏" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") debian_opt_menu ;;
    1)
        DEPENDENCY_01='hmcl'
        ORIGINAL_URL='https://github.com/huanghongxun/HMCL'
        printf "%s\n" "${YELLOW}${ORIGINAL_URL}${RESET}"
        case ${ARCH_TYPE} in
        amd64 | i386) ;;
        *)
            this_app_may_non_support_running_on_proot
            printf "%s\n" "hmcl依赖于openjfx,如需安装，则请自行解决依赖问题。"
            non_debian_function
            add_debian_old_source
            #printf "%s\n" "${GREEN}apt install -y${RESET} ${BLUE}hmcl${RESET}"
            #apt install -y hmcl
            beta_features_quick_install
            del_debian_old_source
            #arch_does_not_support
            press_enter_to_return
            ${RETURN_TO_WHERE}
            ;;
        esac
        ;;
    2)
        printf "%s\n" "${YELLOW}${ORIGINAL_URL}${RESET}"
        DEPENDENCY_01='gamehub'
        ORIGINAL_URL='https://tkashkin.tk/projects/gamehub'
        ;;
    esac
    ##########################
    case ${DEBIAN_INSTALLATION_MENU} in
    00)
        non_debian_function
        beta_features_quick_install
        ;;
    01) debian_opt_install_or_remove_01 ;;
    esac
    ########################
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
############
debian_opt_development_app() {
    DEPENDENCY_02=''
    RETURN_TO_WHERE='debian_opt_development_app'
    RETURN_TO_MENU='debian_opt_development_app'
    DEBIAN_INSTALLATION_MENU='01'
    INSTALL_APP=$(whiptail --title "DEVELOPMENT" --menu \
        "您想要安装哪个软件?\nWhich software do you want to install? " 0 0 0 \
        "1" "netron:用于神经网络,深度学习和机器学习模型的可视化工具" \
        "2" "wxformbuilder:用于wxWidgets GUI设计的RAD工具" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") debian_opt_menu ;;
    1)
        DEPENDENCY_01='netron'
        ORIGINAL_URL='https://github.com/lutzroeder/netron'
        ;;
    2)
        DEPENDENCY_01='wxformbuilder'
        ORIGINAL_URL='https://github.com/wxFormBuilder/wxFormBuilder'
        ;;
    esac
    ##########################
    printf "%s\n" "${YELLOW}${ORIGINAL_URL}${RESET}"
    case ${DEBIAN_INSTALLATION_MENU} in
    01) debian_opt_install_or_remove_01 ;;
    esac
    ########################
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
###############
debian_opt_virtual_machine_app() {
    DEPENDENCY_02=''
    RETURN_TO_WHERE='debian_opt_virtual_machine_app'
    RETURN_TO_MENU='debian_opt_virtual_machine_app'
    DEBIAN_INSTALLATION_MENU='02'
    INSTALL_APP=$(whiptail --title "VIRTUAL MACHINE APP" --menu \
        "您想要安装哪个软件?\nWhich software do you want to install? " 0 0 0 \
        "1" "MacOS8:上古时期苹果Macintosh系统" \
        "2" "Win95:微软windows操作系统" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") debian_opt_menu ;;
    1)
        DEPENDENCY_01='macintosh.js'
        ORIGINAL_URL='https://github.com/felixrieseberg/macintosh.js'
        ;;
    2)
        DEPENDENCY_01='windows95'
        ORIGINAL_URL='https://github.com/felixrieseberg/windows95'
        ;;
    esac
    ##########################
    printf "%s\n" "${YELLOW}${ORIGINAL_URL}${RESET}"
    case ${DEBIAN_INSTALLATION_MENU} in
    02) debian_opt_install_or_remove_02 ;;
    esac
    ########################
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
##################
debian_opt_video_app() {
    DEPENDENCY_02=''
    RETURN_TO_WHERE='debian_opt_video_app'
    RETURN_TO_MENU='debian_opt_video_app'
    DEBIAN_INSTALLATION_MENU='00'
    INSTALL_APP=$(whiptail --title "VIDEO APP" --menu \
        "您想要安装哪个软件?\nWhich software do you want to install? " 0 0 0 \
        "1" "zy-player:搜索全网影视" \
        "2" "lossless-cut:无损剪切音视频工具" \
        "3" "#ciano:多媒体音视频格式转换器" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") debian_opt_menu ;;
    1)
        DEBIAN_INSTALLATION_MENU='01'
        DEPENDENCY_01='zy-player'
        ORIGINAL_URL='http://zyplayer.fun/'
        ;;
    2)
        DEBIAN_INSTALLATION_MENU='01'
        DEPENDENCY_01='lossless-cut'
        ORIGINAL_URL='https://github.com/mifi/lossless-cut'
        ;;
    3)
        DEPENDENCY_01='ciano'
        ORIGINAL_URL='https://robertsanseries.github.io/ciano'
        ;;
    esac
    ##########################
    printf "%s\n" "${YELLOW}${ORIGINAL_URL}${RESET}"
    case ${DEBIAN_INSTALLATION_MENU} in
    00)
        non_debian_function
        beta_features_quick_install
        ;;
    01) debian_opt_install_or_remove_01 ;;
    esac
    ########################
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
#############
debian_opt_reader_app() {
    DEPENDENCY_02=''
    RETURN_TO_WHERE='debian_opt_reader_app'
    RETURN_TO_MENU='debian_opt_reader_app'
    DEBIAN_INSTALLATION_MENU='00'
    INSTALL_APP=$(whiptail --title "READER APP" --menu \
        "您想要安装哪个软件?\nWhich software do you want to install? " 0 0 0 \
        "1" "#bookworm:简约的电子书阅读器" \
        "2" "#foliate:简单且现代化的电子书阅读器" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") debian_opt_menu ;;
    1)
        DEPENDENCY_01='bookworm'
        ORIGINAL_URL='https://github.com/babluboy/bookworm'
        ;;
    2)
        DEPENDENCY_01='foliate'
        ORIGINAL_URL='https://johnfactotum.github.io/foliate/'
        ;;
    esac
    ##########################
    printf "%s\n" "${YELLOW}${ORIGINAL_URL}${RESET}"
    case ${DEBIAN_INSTALLATION_MENU} in
    00)
        non_debian_function
        beta_features_quick_install
        ;;
    esac
    ########################
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
############
debian_opt_picture_app() {
    DEPENDENCY_02=''
    RETURN_TO_WHERE='debian_opt_picture_app'
    RETURN_TO_MENU='debian_opt_picture_app'
    DEBIAN_INSTALLATION_MENU='00'
    INSTALL_APP=$(whiptail --title "PIC APP" --menu \
        "您想要安装哪个软件?\nWhich software do you want to install? " 0 0 0 \
        "1" "draw.io:思维导图绘制工具" \
        "2" "picgo:图床上传工具" \
        "3" "#bingle:下载微软必应每日精选壁纸" \
        "4" "#fondo:壁纸app" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") debian_opt_menu ;;
    1)
        DEBIAN_INSTALLATION_MENU='01'
        DEPENDENCY_01='draw.io'
        ORIGINAL_URL='https://github.com/jgraph/drawio-desktop'
        ;;
    2)
        DEBIAN_INSTALLATION_MENU='01'
        DEPENDENCY_01='picgo'
        ORIGINAL_URL='https://github.com/Molunerfinn/PicGo'
        ;;
    3)
        DEPENDENCY_01='bingle'
        ORIGINAL_URL='https://coslyk.github.io/bingle'
        ;;
    4)
        DEPENDENCY_01='fondo'
        ORIGINAL_URL='https://github.com/calo001/fondo'
        ;;
    esac
    ##########################
    printf "%s\n" "${YELLOW}${ORIGINAL_URL}${RESET}"
    case ${DEBIAN_INSTALLATION_MENU} in
    00)
        non_debian_function
        beta_features_quick_install
        ;;
    01) debian_opt_install_or_remove_01 ;;
    esac
    ########################
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
#####################
debian_opt_note_app() {
    DEPENDENCY_02=''
    RETURN_TO_WHERE='debian_opt_note_app'
    RETURN_TO_MENU='debian_opt_note_app'
    DEBIAN_INSTALLATION_MENU='00'
    INSTALL_APP=$(whiptail --title "NOTE APP" --menu \
        "您想要安装哪个软件?\nWhich software do you want to install? " 0 0 0 \
        "01" "gridea:静态博客写作app,你可以用它来记录你的生活、心情、知识和创意" \
        "02" "marktext:界面直观、功能出众、操作轻松的markdown编辑器" \
        "03" "simplenote:简单、轻量级的开源跨平台云笔记工具" \
        "04" "#vnote:一款更了解程序员和Markdown的笔记软件" \
        "05" "#go-for-it:简洁的备忘软件，借助定时提醒帮助您专注于工作" \
        "06" "#wiznote:为知笔记是一款基于云存储的笔记app" \
        "07" "#xournalpp:支持PDF手写注释的笔记软件" \
        "08" "#notes-up:Markdown编辑和管理器" \
        "09" "#qownnotes:开源Markdown笔记和待办事项软件,支持与owncloud云服务集成" \
        "10" "#quilter:轻量级markdown编辑器" \
        "11" "#textadept:极简、快速和可扩展的跨平台文本编辑器" \
        "00" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    00 | "") debian_opt_menu ;;
    01)
        DEBIAN_INSTALLATION_MENU='01'
        DEPENDENCY_01='gridea'
        ORIGINAL_URL='https://github.com/getgridea/gridea'
        ;;
    02)
        DEBIAN_INSTALLATION_MENU='01'
        DEPENDENCY_01='marktext'
        ORIGINAL_URL='https://marktext.app/'
        ;;
    03)
        DEBIAN_INSTALLATION_MENU='01'
        DEPENDENCY_01='simplenote'
        ORIGINAL_URL='https://simplenote.com/'
        ;;
    04)
        DEPENDENCY_01='vnote'
        ORIGINAL_URL='https://tamlok.gitee.io/vnote'
        ;;
    05)
        DEPENDENCY_01='go-for-it'
        ORIGINAL_URL='https://github.com/mank319/Go-For-It'
        ;;
    06)
        DEPENDENCY_01='wiznote'
        ORIGINAL_URL='https://www.wiz.cn/wiznote-linux.html'
        ;;
    07)
        DEPENDENCY_01='xournalpp'
        ORIGINAL_URL='https://xournalpp.github.io/'
        ;;
    08)
        DEPENDENCY_01='notes-up'
        ORIGINAL_URL='https://github.com/Philip-Scott/Notes-up'
        ;;
    09)
        DEPENDENCY_01='qownnotes'
        ORIGINAL_URL='https://www.qownnotes.org/'
        ;;
    10)
        DEPENDENCY_01='quilter'
        ORIGINAL_URL='https://github.com/lainsce/quilter'
        ;;
    11)
        DEPENDENCY_01='textadept'
        ORIGINAL_URL='https://foicica.com/textadept/'
        ;;
    esac
    ##########################
    printf "%s\n" "${YELLOW}${ORIGINAL_URL}${RESET}"
    case ${DEBIAN_INSTALLATION_MENU} in
    00)
        non_debian_function
        beta_features_quick_install
        ;;
    01) debian_opt_install_or_remove_01 ;;
    esac
    ########################
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
################
debian_opt_music_app() {
    #16 50 7
    DEPENDENCY_02=''
    RETURN_TO_WHERE='debian_opt_music_app'
    RETURN_TO_MENU='debian_opt_music_app'
    DEBIAN_INSTALLATION_MENU='01'
    INSTALL_APP=$(whiptail --title "MUSIC APP" --menu \
        "您想要安装哪个软件?\n Which software do you want to install? " 0 0 0 \
        "1" "lx-music-desktop(洛雪音乐助手)" \
        "2" "electron-netease-cloud-music(云音乐)" \
        "3" "#netease-cloud-music-gtk(云音乐)" \
        "4" "cocomusic(第三方QQ音乐+白屏修复补丁)" \
        "5" "listen1(免费音乐聚合)" \
        "6" "iease-music(界面华丽的云音乐客户端)" \
        "7" "petal(第三方豆瓣FM客户端)" \
        "8" "chord(支持虾米、云音乐、qq音乐多平台)" \
        "9" "#vocal(强大美观的播客app)" \
        "10" "#flacon(支持从专辑中提取音频文件)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") debian_opt_menu ;;
    1) install_lx_music_desktop ;;
    2) install_electron_netease_cloud_music ;;
    3) install_netease_cloud_music_gtk ;;
    4) install_coco_music ;;
    5) install_listen1 ;;
    6) install_iease_music ;;
    7) install_electron_petal ;;
    8) install_electron_chord ;;
    9)
        non_debian_function
        install_opt_vocal
        ;;
    10)
        non_debian_function
        install_opt_flacon
        ;;
    esac
    ##########################
    #"7" "feeluown(x64,支持网易云、虾米)" \
    case ${DEBIAN_INSTALLATION_MENU} in
    00) ;;
    01) debian_opt_install_or_remove_01 ;;
    02) debian_opt_install_or_remove_02 ;;
    esac
    #此处00菜单不要跳转到beta_features_quick_install
    ########################
    press_enter_to_return
    debian_opt_music_app
}
################
install_electron_chord() {
    DEPENDENCY_01='chord'
    printf "%s\n" "${DEPENDENCY_01}"
    printf "%s\n" "github url：${YELLOW}https://github.com/PeterDing/chord${RESET}"
}
##############
install_electron_petal() {
    DEPENDENCY_01='petal'
    printf "%s\n" "github url：${YELLOW}https://ilime.github.io/Petal${RESET}"
}
############
remove_debian_opt_repo() {
    non_debian_function
    rm -vf ${OPT_REPO_LIST} /etc/apt/trusted.gpg.d/bintray-public.key.asc
    apt update
}
##########
debian_opt_other_apps() {
    if (whiptail --title "Would you want to manage electron or view the software list?" --yes-button "electron" --no-button "list列表" --yesno "您想要管理electron还是查看软件列表?♪(^∇^*)" 0 0); then
        electron_manager
    else
        apt_list_debian_opt
    fi
}
##############
install_opt_vocal() {
    DEBIAN_INSTALLATION_MENU='00'
    DEPENDENCY_01='vocal'
    beta_features_quick_install
}
###############
install_opt_flacon() {
    DEBIAN_INSTALLATION_MENU='00'
    DEPENDENCY_01='flacon'
    beta_features_quick_install
}
##################
apt_list_debian_opt() {
    non_debian_function
    apt list | grep '~buster' | sed 's@~buster@@g'
    printf "%s\n" "请使用${YELLOW}apt install${RESET}软件包名称 来安装"
}
#############
install_coco_music() {
    DEBIAN_INSTALLATION_MENU='02'
    DEPENDENCY_01='cocomusic'
    printf "%s\n" "github url：${YELLOW}https://github.com/xtuJSer/CoCoMusic${RESET}"
}
#####################
install_iease_music() {
    DEBIAN_INSTALLATION_MENU='02'
    DEPENDENCY_01='iease-music'
    printf "%s\n" "github url：${YELLOW}https://github.com/trazyn/ieaseMusic${RESET}"
}
############
patch_electron_netease_cloud_music() {
    cd /tmp
    rm -rf /tmp/.electron-netease-cloud-music_TEMP_FOLDER
    git clone -b electron-netease-cloud-music --depth=1 https://gitee.com/mo2/patch ./.electron-netease-cloud-music_TEMP_FOLDER
    cd ./.electron-netease-cloud-music_TEMP_FOLDER
    tar -Jxvf app.asar.tar.xz
    mv -f app.asar /opt/electron-netease-cloud-music/
    cd ..
    rm -rf /tmp/.electron-netease-cloud-music_TEMP_FOLDER
}
######################
patch_listen1() {
    cd /tmp
    rm -rv .LISTEN1_TEMP_FOLDER 2>/dev/null
    git clone --depth=1 https://gitee.com/ak2/listen1_patch ./.LISTEN1_TEMP_FOLDER
    tar -PpJxvf ./.LISTEN1_TEMP_FOLDER/patch.tar.xz
    rm -rv .LISTEN1_TEMP_FOLDER
    sed -i "s@/app'@/app.asar'@g" /usr/bin/listen1
}
########################
check_listen1() {
    FILE_SIZE=$(du -s /opt/Listen1/app | awk '{print $1}')
    if ((${FILE_SIZE} < 500)); then
        patch_listen1
    fi
}
############
check_electron_netease_cloud_music() {
    FILE_SIZE=$(du -s /opt/electron-netease-cloud-music/app.asar | awk '{print $1}')
    if ((${FILE_SIZE} < 3000)); then
        patch_electron_netease_cloud_music
    fi
}
############
install_electron_netease_cloud_music() {
    DEPENDENCY_01='electron-netease-cloud-music'
    printf "%s\n" "github url：${YELLOW}https://github.com/Rocket1184/electron-netease-cloud-music${RESET}"
}
########################
install_listen1() {
    DEPENDENCY_01='listen1'
    printf "%s\n" "github url：${YELLOW}http://listen1.github.io/listen1${RESET}"
}
################
install_lx_music_desktop() {
    DEPENDENCY_01='lx-music-desktop'
    printf "%s\n" "github url：${YELLOW}https://github.com/lyswhut/lx-music-desktop${RESET}"
}
####################
install_opt_deb_file() {
    cd ".${OPT_APP_NAME}"
    apt show ./${OPT_DEB_NAME}
    apt install -y ./${OPT_DEB_NAME}
    cd /tmp
    rm -rv "${DOWNLOAD_PATH}/.${OPT_APP_NAME}"
    beta_features_install_completed
}
##########
git_clone_opt_deb_01() {
    cd ${DOWNLOAD_PATH}
    git clone --depth=1 -b "${OPT_BRANCH_NAME}" "${OPT_APP_GIT_REPO}" ".${OPT_APP_NAME}"
}
###########
install_debian_netease_cloud_music() {
    DEBIAN_INSTALLATION_MENU='00'
    OPT_APP_NAME='netease-cloud-music-gtk'
    OPT_APP_GIT_REPO="https://gitee.com/ak2/${OPT_APP_NAME}.git"
    OPT_DEB_NAME="${OPT_APP_NAME}_arm64.deb"
    DOWNLOAD_PATH='/tmp'
    git_clone_opt_deb_01
    install_opt_deb_file
}
##############
please_choose_netease_cloud_music_version() {
    if (whiptail --title "sid or buster" --yes-button "sid" --no-button "buster" --yesno "请选择版本！旧版系统(例如ubuntu18.04)请选择buster,\n新版系统(如kali rolling)请选择sid。\n不符合当前系统的版本将导致播放格式错误哦！♪(^∇^*) " 0 0); then
        OPT_BRANCH_NAME='sid_arm64'
    else
        OPT_BRANCH_NAME='arm64'
    fi
}
############
install_debian_buster_or_sid_netease_cloud_music() {
    if grep -q 'sid' /etc/os-release; then
        OPT_BRANCH_NAME='sid_arm64'
    elif grep -q 'buster' /etc/os-release; then
        OPT_BRANCH_NAME='arm64'
    else
        case "${DEBIAN_DISTRO}" in
        ubuntu)
            if ! egrep -q 'Bionic Beaver|Eoan Ermine|Xenial' "/etc/os-release"; then
                OPT_BRANCH_NAME='ubuntu_arm64'
            else
                OPT_BRANCH_NAME='arm64'
            fi
            ;;
        kali) OPT_BRANCH_NAME='sid_arm64' ;;
        *) please_choose_netease_cloud_music_version ;;
        esac
    fi
}
################
install_netease_cloud_music_gtk() {
    DEPENDENCY_01='netease-cloud-music-gtk'
    printf "%s\n" "github url：${YELLOW}https://github.com/gmg137/netease-cloud-music-gtk${RESET}"
    printf "%s\n" "本版本仅兼容debian sid,ubuntu 20.04/20.10及kali rooling,20200827已经修复了播放格式错误的问题。"
    printf "%s\n" "${DEBIAN_DISTRO}"
    non_debian_function
    if [ $(command -v ${DEPENDENCY_01}) ]; then
        beta_features_install_completed
        printf "%s\n" "是否需要重装？"
        do_you_want_to_continue
    fi
    case ${ARCH_TYPE} in
    arm64)
        install_debian_buster_or_sid_netease_cloud_music
        install_debian_netease_cloud_music
        ;;
    armhf) arch_does_not_support ;;
    *) beta_features_quick_install ;;
    esac
    if [ ! $(command -v netease-cloud-music-gtk) ]; then
        arch_does_not_support
    fi
}
###############
install_pic_go() {
    DEPENDENCY_01='picgo'
    printf "%s\n" "github url：${YELLOW}https://github.com/Molunerfinn/PicGo${RESET}"
}
############################################
explore_debian_opt_repo
