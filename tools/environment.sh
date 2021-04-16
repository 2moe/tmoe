#!/usr/bin/env bash
########################
check_current_user_name_and_group() {
    CURRENT_USER_NAME=$(grep "${HOME}" /etc/passwd | awk -F ':' '{print $1}' | head -n 1)
    CURRENT_USER_GROUP=$(grep "${HOME}" /etc/passwd | awk -F ':' '{print $4}' | cut -d ',' -f 1 | head -n 1)
    if [ -z "${CURRENT_USER_GROUP}" ]; then
        CURRENT_USER_GROUP=${CURRENT_USER_NAME}
    fi
}
#########################
gnu_linux_env_02() {
    OPT_URL_01='https://bintray.proxy.ustclug.org/debianopt/debianopt'
    OPT_URL_02='https://dl.bintray.com/debianopt/debianopt'
    OPT_REPO_LIST='/etc/apt/sources.list.d/debianopt.list'
    ELECTRON_MIRROR_STATION='https://mirrors.huaweicloud.com/electron'
    #ELECTRON_MIRROR_STATION_02='https://npm.taobao.org/mirrors/electron'
    TIGER_VNC_DEFAULT_CONFIG_FILE='/etc/tigervnc/vncserver-config-tmoe'
    XSESSION_FILE='/etc/X11/xinit/Xsession'
    GIT_AK2='https://gitee.com/ak2'
    TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
    XDG_AUTOSTART_DIR='/etc/xdg/autostart'
    if [ -e "${TMOE_LOCALE_FILE}" ]; then
        TMOE_LANG=$(head -n 1 ${TMOE_LOCALE_FILE})
        TMOE_MENU_LANG=${TMOE_LANG}
    fi
}
########################
uncompress_theme_file() {
    case "${TMOE_THEME_ITEM:0-6:6}" in
    tar.xz) tar -Jxvf ${TMOE_THEME_ITEM} -C ${EXTRACT_FILE_PATH} 2>/dev/null ;;
    tar.gz) tar -zxvf ${TMOE_THEME_ITEM} -C ${EXTRACT_FILE_PATH} 2>/dev/null ;;
    ar.zst) tar -I zstd -xvf ${TMOE_THEME_ITEM} -C ${EXTRACT_FILE_PATH} 2>/dev/null ;;
    *) tar -xvf ${TMOE_THEME_ITEM} -C ${EXTRACT_FILE_PATH} 2>/dev/null ;;
    esac
}
############
check_tar_ext_format() {
    case "${TMOE_THEME_ITEM:0-6:6}" in
    tar.xz) EXTRACT_FILE_FOLDER=$(tar -Jtf ${TMOE_THEME_ITEM} | cut -d '/' -f 1 | sort -u | sed ":a;N;s/\n/ /g;ta") ;;
    tar.gz) EXTRACT_FILE_FOLDER=$(tar -ztf ${TMOE_THEME_ITEM} | cut -d '/' -f 1 | sort -u | sed ":a;N;s/\n/ /g;ta") ;;
    ar.zst) EXTRACT_FILE_FOLDER=$(tar -I zstd -tf ${TMOE_THEME_ITEM} | cut -d '/' -f 1 | sort -u | sed ":a;N;s/\n/ /g;ta") ;;
    *) EXTRACT_FILE_FOLDER=$(tar -tf ${TMOE_THEME_ITEM} | cut -d '/' -f 1 | sort -u | sed ":a;N;s/\n/ /g;ta") ;;
    esac
    EXTRACT_FILE_FOLDER_HEAD_01=$(printf '%s\n' "${EXTRACT_FILE_FOLDER}" | awk '{print $1}')
    check_theme_folder_exists_status
}
################
check_theme_folder_exists_status() {
    if [ -e "${EXTRACT_FILE_PATH}/${EXTRACT_FILE_FOLDER_HEAD_01}" ]; then
        printf "%s\n" "检测到您已安装该主题，如需删除，请手动输${YELLOW}cd ${EXTRACT_FILE_PATH} ; ls ;rm -rv ${EXTRACT_FILE_FOLDER} ${RESET}"
        printf "%s\n" "是否重新解压？"
        printf "%s\n" "Do you want to uncompress again?"
        do_you_want_to_continue
    fi
    uncompress_theme_file
}
###################
check_theme_folder() {
    if [ -e "${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}" ] || [ -e ${HOME}/图片/${CUSTOM_WALLPAPER_NAME} ]; then
        printf "%s\n" "检测到您${RED}已经下载过${RESET}该壁纸包了"
        printf "%s\n" "壁纸包位于${BLUE}${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}${RESET}(图片)目录"
        printf "%s\n" "Do you want to ${RED}download again?${RESET}"
        printf "%s\n" "是否想要重新下载？"
        do_you_want_to_continue
    fi
}
##############
move_wallpaper_model_01() {
    if [ -e "data.tar.xz" ]; then
        tar -Jxvf data.tar.xz 2>/dev/null
    elif [ -e "data.tar.gz" ]; then
        tar -zxvf data.tar.gz 2>/dev/null
    elif [ -e "data.tar.zst" ]; then
        tar -I zstd -xvf data.tar.zst &>/dev/null || zstdcat "data.tar.zst" | tar xvf -
    else
        tar -xvf data.* 2>/dev/null
    fi
    if [ "${SET_MINT_AS_WALLPAPER}" = 'true' ]; then
        if [ ! -e "/usr/share/backgrounds" ]; then
            mkdir -pv /usr/share/backgrounds
        fi
        mv ./usr/share/${WALLPAPER_NAME}/* /usr/share/${CUSTOM_WALLPAPER_NAME}
        rm -rf /tmp/.${THEME_NAME}
        printf "%s\n" "${BLUE}壁纸包${RESET}已经保存至/usr/share/${CUSTOM_WALLPAPER_NAME}${RESET}"
        printf "%s\n" "${BLUE}The wallpaper-pack${RESET} have been saved to ${YELLOW}/usr/share/${CUSTOM_WALLPAPER_NAME}${RESET}"
    else
        if [ -d "${HOME}/图片" ]; then
            mv ./usr/share/${WALLPAPER_NAME} ${HOME}/图片/${CUSTOM_WALLPAPER_NAME}
            WALLPAPER_DIR="${HOME}/图片/${CUSTOM_WALLPAPER_NAME}"
        else
            mkdir -pv ${HOME}/Pictures/
            mv ./usr/share/${WALLPAPER_NAME} ${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}
            WALLPAPER_DIR="${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}"
        fi
        [[ ${HOME} = /root ]] || chown -Rv ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${WALLPAPER_DIR}
        rm -rfv /tmp/.${THEME_NAME}
        printf "%s\n" "${BLUE}壁纸包${RESET}已经保存至${YELLOW}${HOME}/图片/${CUSTOM_WALLPAPER_NAME}${RESET}"
        printf "%s\n" "${BLUE}The wallpaper-pack${RESET} have been saved to ${YELLOW}${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}${RESET}"
    fi
}
#################
move_wallpaper_model_02() {
    if [ -d "${HOME}/图片" ]; then
        tar -Jxvf data.tar.xz -C ${HOME}/图片
        WALLPAPER_DIR="${HOME}/图片"
    else
        mkdir -pv ${HOME}/Pictures/
        tar -Jxvf data.tar.xz -C ${HOME}/Pictures/
        WALLPAPER_DIR="${HOME}/Pictures/"
    fi
    [[ ${HOME} = /root ]] || chown -Rv ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${WALLPAPER_DIR}
    rm -rfv /tmp/.${THEME_NAME}
    printf "%s\n" "${BLUE}壁纸包${RESET}已经保存至${YELLOW}${HOME}/图片/${CUSTOM_WALLPAPER_NAME}${RESET}"
    printf "%s\n" "${BLUE}The wallpaper-pack${RESET} have been saved to ${YELLOW}${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}${RESET}"
}
#################
grep_theme_model_01() {
    check_theme_folder
    mkdir -pv /tmp/.${THEME_NAME}
    cd /tmp/.${THEME_NAME}
    THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL} | grep '\.deb' | grep "${GREP_NAME}" | awk -F '<a href=' '{print $2}' | cut -d '"' -f 2 | tail -n 1)"
    if [[ -z ${THE_LATEST_THEME_VERSION} ]]; then
        THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL_02} | grep '\.deb' | grep "${GREP_NAME}" | awk -F '<a href=' '{print $2}' | cut -d '"' -f 2 | tail -n 1)"
    fi
    download_theme_deb_and_extract_01
}
###############
aria2c_download_theme_file() {
    THE_LATEST_THEME_LINK="${THEME_URL}${THE_LATEST_THEME_VERSION}"
    THE_LATEST_THEME_LINK_02="${THEME_URL_02}${THE_LATEST_THEME_VERSION}"
    case ${AUTO_INSTALL_GUI} in
    true)
        printf "${YELLOW}%s${RESET}\n" "${THE_LATEST_THEME_LINK_02}"
        aria2c --console-log-level=info --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_THEME_VERSION}" "${THE_LATEST_THEME_LINK_02}" || aria2c --console-log-level=info --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_THEME_VERSION}" "${THE_LATEST_THEME_LINK}" || curl -L -o "${THE_LATEST_THEME_VERSION}" "${THE_LATEST_THEME_LINK}"
        ;;
    *)
        printf "${YELLOW}%s${RESET}\n" "${THE_LATEST_THEME_LINK}"
        aria2c --console-log-level=info --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_THEME_VERSION}" "${THE_LATEST_THEME_LINK}" || aria2c --console-log-level=info --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_THEME_VERSION}" "${THE_LATEST_THEME_LINK_02}" || curl -L -o "${THE_LATEST_THEME_VERSION}" "${THE_LATEST_THEME_LINK_02}"
        ;;
    esac
}
##########
download_theme_deb_and_extract_01() {
    aria2c_download_theme_file
    ar xv ${THE_LATEST_THEME_VERSION}
}
###############
#多GREP
grep_theme_model_03() {
    if [ ${FORCIBLY_DOWNLOAD} != 'true' ]; then
        check_theme_folder
    fi
    mkdir -pv /tmp/.${THEME_NAME}
    cd /tmp/.${THEME_NAME}
    THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL} | grep "${GREP_NAME_01}" | grep "${GREP_NAME_02}" | awk -F '<a href=' '{print $2}' | tail -n 1 | cut -d '"' -f 2)"
    if [[ -z ${THE_LATEST_THEME_VERSION} ]]; then
        THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL_02} | grep "${GREP_NAME_01}" | grep "${GREP_NAME_02}" | awk -F '<a href=' '{print $2}' | tail -n 1 | cut -d '"' -f 2)"
    fi
    download_theme_deb_and_extract_01
}
############################
grep_theme_model_04() {
    check_theme_folder
    mkdir -pv /tmp/.${THEME_NAME}
    cd /tmp/.${THEME_NAME}
    THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL_02} | grep "${GREP_NAME_01}" | grep "${GREP_NAME_02}" | awk -F '<a href=' '{print $2}' | tail -n 1 | cut -d '"' -f 2)"
    if [[ -z ${THE_LATEST_THEME_VERSION} ]]; then
        THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL_02} | grep "${GREP_NAME_01}" | grep "${GREP_NAME_02}" | awk -F '<a href=' '{print $2}' | tail -n 1 | cut -d '"' -f 2)"
    fi
    aria2c_download_theme_file
    mv ${THE_LATEST_THEME_VERSION} data.tar.xz
}
############################
#tar.xz
#manjaro仓库
grep_theme_model_02() {
    check_theme_folder
    mkdir -pv /tmp/.${THEME_NAME}
    cd /tmp/.${THEME_NAME}
    THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL} | egrep -v '\.xz\.sig|\.zst\.sig' | grep "${GREP_NAME}" | awk -F'<a href=' '{print $2}' | tail -n 1 | cut -d '"' -f 2)"
    if [[ -z ${THE_LATEST_THEME_VERSION} ]]; then
        THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL_02} | egrep -v '\.xz\.sig|\.zst\.sig' | grep "${GREP_NAME}" | awk -F'<a href=' '{print $2}' | tail -n 1 | cut -d '"' -f 2)"
    fi
    aria2c_download_theme_file
}
###########
update_icon_caches_model_01() {
    cd /
    tar -Jxvf /tmp/.${THEME_NAME}/data.tar.xz ./usr
    rm -rf /tmp/.${THEME_NAME}
    printf "%s\n" "updating icon caches..."
    printf "%s\n" "正在刷新图标缓存..."
    update-icon-caches /usr/share/icons/${ICON_NAME} 2>/dev/null &
    tips_of_delete_icon_theme
}
############
tips_of_delete_icon_theme() {
    printf "%s\n" "解压${BLUE}完成${RESET}，如需${RED}删除${RESET}，请手动输${YELLOW}rm -rf /usr/share/icons/${ICON_NAME} ${RESET}"
    printf "%s\n" "If you want to ${RED}delete it${RESET}，please ${YELLOW}manually type ${PURPLE}rm -rf ${BLUE}/usr/share/icons/${ICON_NAME} ${RESET}"
}
###################
update_icon_caches_model_02() {
    tar -Jxvf /tmp/.${THEME_NAME}/${THE_LATEST_THEME_VERSION} 2>/dev/null
    cp -rf usr /
    cd /
    rm -rf /tmp/.${THEME_NAME}
    printf "%s\n" "updating icon caches..."
    printf "%s\n" "正在刷新图标缓存..."
    update-icon-caches /usr/share/icons/${ICON_NAME} 2>/dev/null &
    tips_of_delete_icon_theme
}
####################
download_raspbian_pixel_icon_theme() {
    THEME_NAME='raspbian_pixel_icon_theme'
    ICON_NAME='PiX'
    GREP_NAME='all.deb'
    THEME_URL='https://mirrors.bfsu.edu.cn/raspberrypi/pool/ui/p/pix-icons/'
    THEME_URL_02='https://mirrors.tuna.tsinghua.edu.cn/raspberrypi/pool/ui/p/pix-icons/'
    grep_theme_model_01
    update_icon_caches_model_01
    XFCE_ICON_NAME='PiX'
    set_default_xfce_icon_theme
}
################
#non-zst
grep_arch_linux_pkg() {
    ARCH_WALLPAPER_VERSION=$(cat index.html | egrep -v '\.xz\.sig|\.zst\.sig|.pkg.tar.zst' | egrep "${GREP_NAME}" | tail -n 1 | awk -F '<a href=' '{print $2}' | cut -d '"' -f 2)
    ARCH_WALLPAPER_URL="${THEME_URL}${ARCH_WALLPAPER_VERSION}"
    ARCH_WALLPAPER_URL_02="${THEME_URL_02}${ARCH_WALLPAPER_VERSION}"
    printf "%s\n" "${ARCH_WALLPAPER_URL}"
    aria2c --console-log-level=info --no-conf --allow-overwrite=true -o data.tar.xz -x 5 -s 5 -k 1M ${ARCH_WALLPAPER_URL} || aria2c --console-log-level=info --no-conf --allow-overwrite=true -o data.tar.xz -x 5 -s 5 -k 1M ${ARCH_WALLPAPER_URL_02}
}
################
#grep zst
grep_arch_linux_pkg_02() {
    ARCH_WALLPAPER_VERSION=$(cat index.html | grep '\.pkg\.tar\.zst' | egrep -v '\.xz\.sig|\.zst\.sig' | grep "${GREP_NAME}" | tail -n 1 | awk -F '<a href=' '{print $2}' | cut -d '"' -f 2)
    ARCH_WALLPAPER_URL="${THEME_URL}${ARCH_WALLPAPER_VERSION}"
    ARCH_WALLPAPER_URL_02="${THEME_URL_02}${ARCH_WALLPAPER_VERSION}"
    printf "%s\n" "${ARCH_WALLPAPER_URL}"
    aria2c --console-log-level=info --no-conf --allow-overwrite=true -o data.tar.zst -x 5 -s 5 -k 1M ${ARCH_WALLPAPER_URL} || aria2c --console-log-level=info --no-conf --allow-overwrite=true -o data.tar.zst -x 6 -s 6 -k 1M ${ARCH_WALLPAPER_URL_02}
}
###################
grep_arch_linux_pkg_03() {
    ARCH_WALLPAPER_VERSION=$(cat index.html | grep '\.pkg\.tar\.zst' | egrep -v '\.xz\.sig|\.zst\.sig' | grep "${GREP_NAME}" | grep -v "${GREP_NAME_V}" | tail -n 1 | awk -F '<a href=' '{print $2}' | cut -d '"' -f 2)
    ARCH_WALLPAPER_URL="${THEME_URL}${ARCH_WALLPAPER_VERSION}"
    ARCH_WALLPAPER_URL_02="${THEME_URL_02}${ARCH_WALLPAPER_VERSION}"
    printf "%s\n" "${YELLOW}${ARCH_WALLPAPER_URL}${RESET}"
    aria2c --console-log-level=info --no-conf --allow-overwrite=true -o data.tar.zst -x 5 -s 5 -k 1M ${ARCH_WALLPAPER_URL} || aria2c --console-log-level=info --no-conf --allow-overwrite=true -o data.tar.zst -x 6 -s 6 -k 1M ${ARCH_WALLPAPER_URL_02}
}
#################
grep_arch_linux_pkg_04() {
    #JetBrains IDE
    ARCH_WALLPAPER_VERSION=$(cat index.html | grep '\.pkg\.tar\.zst' | egrep -v '\.xz\.sig|\.zst\.sig' | grep -v '\-jre\-' | grep "${GREP_NAME}" | tail -n 1 | awk -F '<a href=' '{print $2}' | cut -d '"' -f 2)
    cd ${DOWNLOAD_PATH}
    LOCAL_ARCH_PKG_VERSION=$(ls -t ${GREP_NAME}*.pkg.tar.zst 2>/dev/null | head -n 1)
    case ${LOCAL_ARCH_PKG_VERSION} in
    ${ARCH_WALLPAPER_VERSION}) printf "%s\n" "检测到您已经下载最新版的${LOCAL_ARCH_PKG_VERSION},如需删除安装包，请输${RED}rm -v${RESET} ${BLUE}${DOWNLOAD_PATH}/${LOCAL_ARCH_PKG_VERSION}${RESET}" ;;
    *)
        ARCH_WALLPAPER_URL="${THEME_URL}${ARCH_WALLPAPER_VERSION}"
        #printf "%s\n" "${YELLOW}${ARCH_WALLPAPER_URL}${RESET}"
        aria2c --console-log-level=info --no-conf --allow-overwrite=true -d ${DOWNLOAD_PATH} -o ${ARCH_WALLPAPER_VERSION} -x 5 -s 5 -k 1M ${ARCH_WALLPAPER_URL}
        ;;
    esac
    printf "%s\n" "${ARCH_WALLPAPER_VERSION}" | sed "s@${GREP_NAME}-@@g" | sed 's@4%3A@@' | sed 's@.pkg.tar.zst@@' >"${LOCAL_APP_VERSION_TXT}"
}
#################
check_opt_app_version() {
    LOCAL_APP_VERSION_TXT="${TMOE_LINUX_DIR}/${GREP_NAME}-version"
    if [ -e "${LOCAL_APP_VERSION_TXT}" ]; then
        LOCAL_OPT_APP_VERSION=$(head -n 1 ${LOCAL_APP_VERSION_TXT})
    else
        LOCAL_OPT_APP_VERSION="NOT-INSTALLED未安装"
    fi
}
##############
check_archlinux_cn_html_date() {
    THEME_URL='https://mirrors.bfsu.edu.cn/archlinuxcn/x86_64/'
    THEME_URL_02='https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/x86_64/'
    ARCH_LINUX_CN_REPO_DIR='/tmp/.ARCH_LINUX_CN_REPO'
    ARCH_LINUX_CN_REPO_HTML="${ARCH_LINUX_CN_REPO_DIR}/index.html"
    if [ ! -e "${ARCH_LINUX_CN_REPO_DIR}" ]; then
        mkdir -pv ${ARCH_LINUX_CN_REPO_DIR}
    fi
    cd ${ARCH_LINUX_CN_REPO_DIR}

    if [ -e "${ARCH_LINUX_CN_REPO_HTML}" ]; then
        FILE_TIME=$(date -d "$(stat -c '%y' ${ARCH_LINUX_CN_REPO_HTML})" +"%Y%m%d")
        case ${FILE_TIME} in
        "$(date +%Y%m%d)") ;;
        *) download_arch_linux_cn_repo_html ;;
        esac
    else
        download_arch_linux_cn_repo_html
    fi
}
check_archlinux_community_html_date() {
    THEME_URL='https://mirrors.bfsu.edu.cn/archlinux/community/os/x86_64/'
    THEME_URL_02='https://mirrors.tuna.tsinghua.edu.cn/archlinux/community/os/x86_64/'
    ARCH_LINUX_CN_REPO_DIR='/tmp/.ARCH_LINUX_COMMUNITY_REPO'
    ARCH_LINUX_CN_REPO_HTML="${ARCH_LINUX_CN_REPO_DIR}/index.html"
    if [ ! -e "${ARCH_LINUX_CN_REPO_DIR}" ]; then
        mkdir -pv ${ARCH_LINUX_CN_REPO_DIR}
    fi
    cd ${ARCH_LINUX_CN_REPO_DIR}

    if [ -e "${ARCH_LINUX_CN_REPO_HTML}" ]; then
        FILE_TIME=$(date -d "$(stat -c '%y' ${ARCH_LINUX_CN_REPO_HTML})" +"%Y%m%d")
        case ${FILE_TIME} in
        "$(date +%Y%m%d)") ;;
        *) download_arch_linux_cn_repo_html ;;
        esac
    else
        download_arch_linux_cn_repo_html
    fi
}
##########
check_opt_dir_01() {
    APP_OPT_DIR="/opt/${GREP_NAME}"
    if [ -e "${APP_OPT_DIR}" ]; then
        printf "%s\n" "安装完成，如需卸载，请输${RED}rm -rv${RESET}${BLUE}${APP_OPT_DIR} ${APPS_LNK_DIR}/${GREP_NAME}.desktop ${LOCAL_OPT_APP_VERSION}${RESET}"
        printf "%s\n" "是否需要强制更新？"
        printf "%s\n" "Do you want to mandatory upgrade ${GREP_NAME}?"
        do_you_want_to_continue
    fi
}
###########
check_download_path() {
    if [ -d "${HOME}/sd" ]; then
        DOWNLOAD_PATH=${HOME}/sd/Download
    elif [ -d "/sdcard" ]; then
        DOWNLOAD_PATH=/sdcard/Download
    elif [ -d "/sd" ]; then
        DOWNLOAD_PATH=/sd/Download
    else
        DOWNLOAD_PATH=${HOME}/sd/Download
    fi
    mkdir -pv ${DOWNLOAD_PATH}
}
###########
download_arch_linux_cn_repo_html() {
    aria2c --console-log-level=info --no-conf -o index.html --allow-overwrite=true ${THEME_URL} || aria2c --console-log-level=info --no-conf -o index.html --allow-overwrite=true ${THEME_URL_02}
}
############
download_arch_community_repo_html() {
    THEME_NAME=${GREP_NAME}
    mkdir -pv /tmp/.${THEME_NAME}
    cd /tmp/.${THEME_NAME}
    aria2c --console-log-level=info --no-conf --allow-overwrite=true -o index.html "${THEME_URL}" || aria2c --console-log-level=info --no-conf --allow-overwrite=true -o index.html "${THEME_URL_02}"
}
##############
upcompress_deb_file() {
    if [ -e "data.tar.xz" ]; then
        cd /
        tar -Jxvf /tmp/.${THEME_NAME}/data.tar.xz ./usr
    elif [ -e "data.tar.gz" ]; then
        cd /
        tar -zxvf /tmp/.${THEME_NAME}/data.tar.gz ./usr
    fi
    rm -rf /tmp/.${THEME_NAME}
}
####################
do_you_want_to_close_the_sandbox_mode() {
    printf "%s\n" "请问您是否需要关闭沙盒模式？"
    printf "%s\n" "若您需要以root权限运行该应用，则需要关闭，否则请保持开启状态。"
    printf "%s\n" "${YELLOW}Do you need to turn off the sandbox mode?${PURPLE}[Y/n]${RESET}"
    printf "%s\n" "Press enter to turn off this mode,type n to cancel."
    printf "%s\n" "按${YELLOW}回车${RESET}键${RED}关闭${RESET}该模式，输${YELLOW}n${RESET}取消"
}
#######################
check_file_selection_items() {
    if [[ -d "${SELECTION}" ]]; then # 目录是否已被选择
        tmoe_file "$1" "${SELECTION}"
    elif [[ -f "${SELECTION}" ]]; then # 文件已被选择？
        if [[ ${SELECTION} == *${FILE_EXT_01} ]] || [[ ${SELECTION} == *${FILE_EXT_02} ]]; then
            # 检查文件扩展名
            if (whiptail --title "Confirm Selection" --yes-button "Confirm确认" --no-button "Back返回" --yesno "目录: $CURRENT_DIR\n文件: ${SELECTION}" 10 55 4); then
                FILE_NAME="${SELECTION}"
                FILE_PATH="${CURRENT_DIR}"
                #将文件路径作为已经选择的变量
            else
                tmoe_file "$1" "$CURRENT_DIR"
            fi
        else
            whiptail --title "WARNING: File Must have ${FILE_EXT_01} or ${FILE_EXT_02} Extension" \
                --msgbox "${SELECTION}\n您必须选择${FILE_EXT_01}或${FILE_EXT_02}格式的文件。You Must Select a ${FILE_EXT_01} or ${FILE_EXT_02} file" 0 0
            tmoe_file "$1" "$CURRENT_DIR"
        fi
    else
        whiptail --title "WARNING: Selection Error" \
            --msgbox "无法选择该文件或文件夹，请返回。Error Changing to Path ${SELECTION}" 0 0
        tmoe_file "$1" "$CURRENT_DIR"
    fi
}
#####################
tmoe_file() {
    if [ -z $2 ]; then
        DIR_LIST=$(ls -lAhp | awk -F ' ' ' { print $9 " " $5 } ')
    else
        cd "$2"
        DIR_LIST=$(ls -lAhp | awk -F ' ' ' { print $9 " " $5 } ')
    fi
    ###########################
    CURRENT_DIR=$(pwd)
    # 检测是否为根目录
    if [ "$CURRENT_DIR" == "/" ]; then
        SELECTION=$(whiptail --title "$1" \
            --menu "${MENU_01}\n$CURRENT_DIR" 0 0 0 \
            --title "$TMOE_TITLE" \
            --cancel-button Cancel取消 \
            --ok-button Select选择 $DIR_LIST 3>&1 1>&2 2>&3)
    else
        SELECTION=$(whiptail --title "$1" \
            --menu "${MENU_01}\n$CURRENT_DIR" 0 0 0 \
            --title "$TMOE_TITLE" \
            --cancel-button Cancel取消 \
            --ok-button Select选择 ../ 返回 $DIR_LIST 3>&1 1>&2 2>&3)
    fi
    ########################
    EXIT_STATUS=$?
    if [ ${EXIT_STATUS} = 1 ]; then # 用户是否取消操作？
        return 1
    elif [ ${EXIT_STATUS} = 0 ]; then
        check_file_selection_items
    fi
    ############
}
################
install_deb_file_common_model_02() {
    cd /tmp
    printf "%s\n" "${LATEST_DEB_URL}"
    aria2c --console-log-level=info --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${LATEST_DEB_VERSION}" "${LATEST_DEB_URL}"
    apt-cache show ./${LATEST_DEB_VERSION}
    apt install -y ./${LATEST_DEB_VERSION}
    rm -fv ./${LATEST_DEB_VERSION}
}
###############
install_deb_file_common_model_01() {
    LATEST_DEB_URL="${LATEST_DEB_REPO}${LATEST_DEB_VERSION}"
    install_deb_file_common_model_02
}
###################
download_ubuntu_kylin_deb_file_model_02() {
    LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '\.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 5 | cut -d '"' -f 2)
    install_deb_file_common_model_01
}
################
download_debian_cn_repo_deb_file_model_01() {
    LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '\.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
    install_deb_file_common_model_01
}
######################
download_tuna_repo_deb_file_model_03() {
    LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '\.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
    install_deb_file_common_model_01
}
################
download_tuna_repo_deb_file_all_arch() {
    LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '\.deb' | grep "all" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
    LATEST_DEB_URL="${LATEST_DEB_REPO}${LATEST_DEB_VERSION}"
    printf "%s\n" "${LATEST_DEB_URL}"
    aria2c --console-log-level=info --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${LATEST_DEB_VERSION}" "${LATEST_DEB_URL}"
    apt-cache show ./${LATEST_DEB_VERSION} 2>/dev/null
}
##此处不要自动安装deb包
######################
press_enter_to_return_configure_xrdp() {
    press_enter_to_return
    configure_xrdp
}
#############
press_enter_to_return_configure_xwayland() {
    press_enter_to_return
    configure_xwayland
}
#######################
beta_features_management_menu() {
    if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "reinstall重装" --no-button "remove移除" --yesno "检测到您已安装${DEPENDENCY_01} ${DEPENDENCY_02} \nDo you want to reinstall or remove it? ♪(^∇^*) " 0 50); then
        printf "%s\n" "${GREEN} ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
        printf "%s\n" "即将为您重装..."
    else
        ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
        press_enter_to_return
        #tmoe_linux_tool_menu
        ${RETURN_TO_WHERE}
    fi
}
##############
non_debian_function() {
    if [ "${LINUX_DISTRO}" != 'debian' ]; then
        printf "%s\n" "非常抱歉，本功能仅适配deb系发行版"
        printf "%s\n" "Sorry, this feature is only suitable for debian based distributions"
        press_enter_to_return
        if [ ! -z ${RETURN_TO_WHERE} ]; then
            ${RETURN_TO_WHERE}
        else
            beta_features
        fi
    fi
}
############
press_enter_to_reinstall() {
    printf "%s\n" "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
    printf "%s\n" "If you want to ${RED}remove it${RESET}，please ${YELLOW}manually type ${PURPLE}${TMOE_REMOVAL_COMMAND}${RESET} ${BLUE}${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
    press_enter_to_reinstall_yes_or_no
}
################
if_return_to_where_no_empty() {
    if [ ! -z ${RETURN_TO_WHERE} ]; then
        ${RETURN_TO_WHERE}
    else
        beta_features
    fi
}
##########
press_enter_to_reinstall_yes_or_no() {
    printf "%s\n" "按${GREEN}回车键${RESET}${RED}重新安装${RESET},输${YELLOW}n${RESET}${BLUE}返回${RESET}"
    printf "%s\n" "输${YELLOW}m${RESET}打开${BLUE}管理菜单${RESET}"
    printf "%s\n" "${YELLOW}Do you want to reinstall it?[Y/m/n]${RESET}"
    printf "%s\n" "Press enter to reinstall,type n to return,type m to open management menu."
    read opt
    case $opt in
    y* | Y* | "") ;;
    n* | N*)
        printf "%s\n" "skipped."
        if_return_to_where_no_empty
        ;;
    m* | M*)
        beta_features_management_menu
        ;;
    *)
        printf "%s\n" "Invalid choice. skipped."
        if_return_to_where_no_empty
        ;;
    esac
}
#######################
beta_features_install_completed() {
    printf "%s\n" "安装${GREEN}完成${RESET},如需${RED}卸载${RESET}，请手动输${RED}${TMOE_REMOVAL_COMMAND}${RESET} ${BLUE}${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
    printf "%s\n" "The installation is complete. If you want to remove, please enter the above highlighted command."
}
####################
beta_features_quick_install() {
    #if [ "${NON_DEBIAN}" = 'true' ]; then
    #   non_debian_function
    #fi
    #############
    if [ ! -z "${DEPENDENCY_01}" ]; then
        DEPENDENCY_01_COMMAND=$(printf '%s\n' "${DEPENDENCY_01}" | awk -F ' ' '$0=$NF')
        if [ $(command -v ${DEPENDENCY_01_COMMAND}) ]; then
            printf "%s\n" "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_01} ${RESET}"
            printf "%s\n" "If you want to ${RED}remove it${RESET}，please ${YELLOW}manually type ${PURPLE}${TMOE_REMOVAL_COMMAND} ${BLUE}${DEPENDENCY_01}${RESET}"
            EXISTS_COMMAND=true
        fi
    fi
    #############
    if [ ! -z "${DEPENDENCY_02}" ]; then
        DEPENDENCY_02_COMMAND=$(printf '%s\n' "${DEPENDENCY_02}" | awk -F ' ' '$0=$NF')
        if [ $(command -v ${DEPENDENCY_02_COMMAND}) ]; then
            printf "%s\n" "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_02} ${RESET}"
            printf "%s\n" "If you want to ${RED}remove it${RESET}，please ${YELLOW}manually type ${PURPLE}${TMOE_REMOVAL_COMMAND} ${BLUE}${DEPENDENCY_02}${RESET}"
            EXISTS_COMMAND=true
        fi
    fi
    ###############
    printf "%s\n" "正在${YELLOW}安装${RESET}相关${GREEN}软件包${RESET}及其${BLUE}依赖...${RESET}"
    printf "%s\n" "${GREEN}${TMOE_INSTALLATION_COMMAND}${RESET} ${BLUE}${DEPENDENCY_01}${RESET} ${YELLOW}${DEPENDENCY_02}${RESET}"
    printf "%s\n" "Tmoe-linux tool will ${YELLOW}install${RESET} relevant ${BLUE}dependencies${RESET} for you."
    ############
    if [ "${EXISTS_COMMAND}" = "true" ]; then
        EXISTS_COMMAND=false
        press_enter_to_reinstall_yes_or_no
    fi
    ############
    different_distro_software_install
    #############
    beta_features_install_completed
}
################
check_tmoe_linux_desktop_link() {
    if [ ! -e "${APPS_LNK_DIR}/tmoe-linux.desktop" ]; then
        mkdir -pv ${APPS_LNK_DIR}
        create_tmoe_linux_desktop_icon
    fi
    TMOE_ICON_FILE='/usr/share/icons/tmoe-linux.png'
    if [ -e "${TMOE_ICON_FILE}" ]; then
        rm ${TMOE_ICON_FILE}
        create_tmoe_linux_desktop_icon
    fi
}
###################
create_tmoe_linux_desktop_icon() {
    if [ ! $(command -v debian-i) ]; then
        cd /usr/local/bin
        curl -Lv -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
        chmod a+x debian-i
    fi
    cp ${TMOE_TOOL_DIR}/app/lnk/tmoe-linux.desktop ${APPS_LNK_DIR}/tmoe-linux.desktop
}
####################
arch_does_not_support() {
    printf "%s\n" "${RED}WARNING！${RESET}检测到${YELLOW}架构${RESET}${RED}不支持！${RESET}"
    printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
    printf "%s\n" "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
    read
    ${RETURN_TO_WHERE}
}
##########################
do_you_want_to_continue() {
    TMOE_TIPS_01="Do you want to continue?${YELLOW}[Y/n]${RESET}"
    if [ -e /usr/games/lolcat ]; then
        printf "%s\n" "${TMOE_TIPS_01}" | /usr/games/lolcat -a -d 8
    elif [ "$(command -v lolcat)" ]; then
        printf "%s\n" "${TMOE_TIPS_01}" | lolcat
    else
        printf "%s\n" "${TMOE_TIPS_01}"
    fi
    printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET},type ${YELLOW}n${RESET} to ${BLUE}return.${RESET}"
    printf "%s\n" "按${GREEN}回车键${RESET}${BLUE}继续${RESET}，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
    read opt
    case $opt in
    y* | Y* | "") ;;

    n* | N*)
        printf "%s\n" "skipped."
        ${RETURN_TO_WHERE}
        ;;
    *)
        printf "%s\n" "Invalid choice. skipped."
        ${RETURN_TO_WHERE}
        #beta_features
        ;;
    esac
}
######################
different_distro_software_install() {
    case "${LINUX_DISTRO}" in
    "debian")
        apt update
        if [ ! -z "${DEPENDENCY_01}" ]; then
            eatmydata apt install -y ${DEPENDENCY_01} || eatmydata apt-get install -f -y ${DEPENDENCY_01} || aptitude install -y ${DEPENDENCY_01}
        fi
        if [ ! -z "${DEPENDENCY_02}" ]; then
            eatmydata apt install -y ${DEPENDENCY_02} || eatmydata apt-get install -f -y ${DEPENDENCY_02} || aptitude install -y ${DEPENDENCY_02}
        fi
        ;;
        ################
    "alpine")
        apk update
        apk add ${DEPENDENCY_01} || apk add ${DEPENDENCY_01}
        apk add ${DEPENDENCY_02} || apk add ${DEPENDENCY_02}
        ;;
        ################
    "arch")
        if [ ! -z "${DEPENDENCY_01}" ]; then
            case ${AUTO_INSTALL_GUI} in
            true) #自动构建时pacman可能执行失败
                pacman -Syu --noconfirm --needed ${DEPENDENCY_01} || pacman -Syu --noconfirm ${DEPENDENCY_01} || pacman -Syu --noconfirm ${DEPENDENCY_01} || yay -S --noconfirm ${DEPENDENCY_01} ;;
            *) pacman -Syu --noconfirm --needed ${DEPENDENCY_01} || su ${CURRENT_USER_NAME} -c "yay -S ${DEPENDENCY_01}" || printf "%s\n" "无法以${RED}${CURRENT_USER_NAME}${RESET}身份运行${GREEN}yay -S${RESET} ${BLUE}${DEPENDENCY_01}${RESET}" ;;
            esac
        fi
        if [ ! -z "${DEPENDENCY_02}" ]; then
            case ${AUTO_INSTALL_GUI} in
            true) pacman -Syu --noconfirm --needed ${DEPENDENCY_02} || pacman -Syu --noconfirm ${DEPENDENCY_02} || pacman -Syu --noconfirm ${DEPENDENCY_02} || yay -S --noconfirm ${DEPENDENCY_02} ;;
            *) pacman -S --noconfirm --needed ${DEPENDENCY_02} || su ${CURRENT_USER_NAME} -c "yay -S ${DEPENDENCY_02}" || printf "%s\n" "无法以${RED}${CURRENT_USER_NAME}${RESET}身份运行${GREEN}yay -S${RESET} ${BLUE}${DEPENDENCY_02}${RESET},请手动执行" ;;
            esac
        fi
        ;;
        ################
    "redhat")
        if [ ! -z "${DEPENDENCY_01}" ]; then
            dnf install -y --skip-broken ${DEPENDENCY_01} || yum install -y --skip-broken ${DEPENDENCY_01}
        fi
        if [ ! -z "${DEPENDENCY_02}" ]; then
            dnf install -y --skip-broken ${DEPENDENCY_02} || yum install -y --skip-broken ${DEPENDENCY_02}
        fi
        ;;
        ################
    "openwrt")
        #opkg update
        opkg install ${DEPENDENCY_01}
        opkg install ${DEPENDENCY_02}
        ;;
        ################
    "gentoo")
        emerge -vk ${DEPENDENCY_01}
        emerge -vk ${DEPENDENCY_02}
        ;;
        ################
    "suse")
        zypper in -y ${DEPENDENCY_01} || zypper in -y ${DEPENDENCY_01}
        zypper in -y ${DEPENDENCY_02} || zypper in -y ${DEPENDENCY_02}
        ;;
        ################
    "void")
        xbps-install -S -y ${DEPENDENCY_01} || xbps-install -Sy ${DEPENDENCY_01}
        xbps-install -S -y ${DEPENDENCY_02} || xbps-install -Sy ${DEPENDENCY_02}
        ;;
        ################
    "slackware")
        slackpkg update
        slackpkg install ${DEPENDENCY_01}
        slackpkg install ${DEPENDENCY_02}
        ;;
        #########################
    *)
        apt update
        apt install -y ${DEPENDENCY_01} || port install ${DEPENDENCY_01} || guix package -i ${DEPENDENCY_01} || pkg install ${DEPENDENCY_01} || pkg_add ${DEPENDENCY_01} || pkgutil -i ${DEPENDENCY_01}
        ;;
    esac
}
######################
tmoe_file_manager() {
    #START_DIR="/root"
    #FILE_EXT_01='tar.gz'
    #FILE_EXT_02='tar.xz'
    TMOE_TITLE="${FILE_EXT_01} & ${FILE_EXT_02} 文件选择Tmoe-linux管理器"
    if [ -z ${IMPORTANT_TIPS} ]; then
        MENU_01="请使用方向键和回车键进行操作"
    else
        MENU_01=${IMPORTANT_TIPS}
    fi
    ########################################
    #-bak_rootfs.tar.xz
    ###################
    #tmoe_file
    ###############
    tmoe_file "$TMOE_TITLE" "$START_DIR"

    EXIT_STATUS=$?
    if [ ${EXIT_STATUS} -eq 0 ]; then
        if [ "${SELECTION}" == "" ]; then
            printf "%s\n" "检测到您取消了操作,User Pressed Esc with No File Selection"
        else
            whiptail --msgbox "文件属性 :  $(ls -lh ${FILE_NAME})\n路径 : ${FILE_PATH}" 0 0
            TMOE_FILE_ABSOLUTE_PATH="${CURRENT_DIR}/${SELECTION}"
            #uncompress_tar_file
        fi
    else
        printf "%s\n" "检测到您${RED}取消了${RESET}${YELLOW}操作${RESET}，没有文件${BLUE}被选择${RESET},with No File ${BLUE}Selected.${RESET}"
        #press_enter_to_return
    fi
}
###########
where_is_start_dir() {
    for i in /media/sd/Download /sdcard/Download ${HOME}/sd/Download ${HOME}/sdcard/Download /media/sd ${HOME}/sd ${HOME}/sdcard /sd /sdcard /media/docker ${HOME}; do
        if [[ -d ${i} ]]; then
            START_DIR=${i}
            break
        fi
    done
    tmoe_file_manager
}
###################################
#兩處調用到gnome software,故將其置於env
install_gnome_software() {
    DEPENDENCY_01="gnome-software"
    DEPENDENCY_02=""
    beta_features_quick_install
}
########################
random_neko() {
    case "$(($RANDOM % 3 + 1))" in
    1) neko_01_blue ;;
    2) neko_02_blue ;;
    3 | *) neko_03_blue ;;
    esac
}
###########
neko_ascii_env() {
    if [ ! $(command -v lolcat) ] && [ ! -e /usr/games/lolcat ]; then
        case ${LINUX_DISTRO} in
        debian)
            printf "%s\n" "${GREEN}eatmydata apt ${YELLOW}install -y --no-install-recommends ${BLUE}lolcat${RESET}"
            eatmydata apt install -y --no-install-recommends lolcat || apt install -y lolcat
            ;;
        arch)
            printf "%s\n" "${GREEN}pacman ${YELLOW}-Sy --noconfirm ${BLUE}lolcat${RESET}"
            pacman -Sy --noconfirm lolcat
            ;;
        esac
    fi
    if [ -e /usr/games/lolcat ]; then
        CATCAT='/usr/games/lolcat'
    elif [ "$(command -v lolcat)" ]; then
        CATCAT='lolcat'
    else
        CATCAT='cat'
    fi
}
##################
neko_01_blue() {
    neko_ascii_env
    printf "$BLUE"
    ${CATCAT} <<-'EndOFneko'
		                                        
		                            .:7E        
		            .iv7vrrrrr7uQBBBBBBB:       
		           v17::.........:SBBBUg        
		        vKLi.........:. .  vBQrQ        
		   sqMBBBr.......... :i. .  SQIX        
		   BBQBBr.:...:....:. 1:.....v. ..      
		    UBBB..:..:i.....i YK:: ..:   i:     
		     7Bg.... iv.....r.ijL7...i. .Lu     
		  IB: rb...i iui....rir :Si..:::ibr     
		  J7.  :r.is..vrL:..i7i  7U...Z7i..     
		  ...   7..I:.: 7v.ri.755P1. .S  ::     
		    :   r:.i5KEv:.:.  :.  ::..X..::     
		   7is. :v .sr::.         :: :2. ::     
		   2:.  .u: r.     ::::   r: ij: .r  :  
		   ..   .v1 .v.    .   .7Qr: Lqi .r. i  
		   :u   .iq: :PBEPjvviII5P7::5Du: .v    
		    .i  :iUr r:v::i:::::.:.:PPrD7: ii   
		    :v. iiSrr   :..   s i.  vPrvsr. r.  
		     ...:7sv:  ..PL  .Q.:.   IY717i .7. 
		      i7LUJv.   . .     .:   YI7bIr :ur 
		     Y rLXJL7.:jvi:i:::rvU:.7PP XQ. 7r7 
		    ir iJgL:uRB5UPjriirqKJ2PQMP :Yi17.v 
		         :   r. ..      .. .:i  ...     
	EndOFneko
    printf "$RESET"
}
##############
neko_02_blue() {
    neko_ascii_env
    printf "$BLUE"
    ${CATCAT} <<-'EndOFneko'
	       DL.                           
	       QBBBBBKv:rr77ri:.             
	       gBBQdY7::::..::i7vv.          
	       UBd. . .:.........rBBBQBBBB5  
	       Pu  :..r......i:....BBBQBBB:  
	       ri.i:.j:...:. i7... uBBZrd:   
	 :     7.:7.7U.:..r: Yr:.. iQ1:qU    
	.Qi   .7.ii.X7:...L.:qr:...iB7ZQ     
	 .27. :r.r:L7i::.7r:vri:...rr  .     
	  v   ::.Yrviri:7v7v: ::...i.   i    
	      r:ir: r.iiiir..:7r...r   :P.2Y 
	      v:vi::.      :  ::. .qI7U1U :1 
	Qr    7.7.         :.i::. :Di:. i .v:
	v7..  s.r7.   ...   .:7i: rDi...r .. 
	 vi: .7.iDBBr  .r   .:.7. rPr:..r    
	 i   :virZBgi  :vrYJ1vYY .ruY:..i    
	     YrivEv. 7BBRBqj21I7 .77J:.:.PQ  
	    .1r:q.   rB52SKrj.:i i5isi.:i :.r
	    YvrY7    r.  . ru :: PIrj7.:r..v 
	   rSviYI..iuU .:.:i:.7.KPPiSr.:vr   
	  .u:Y:JQMSsJUv...   .rDE1P71:.7X7   
	  5  Ivr:QJ7JYvi....ir1dq vYv.7L.Y   
	  S  7Z  Qvr:.iK55SqS1PX  Xq7u2 :7   
	         .            i   7          
EndOFneko
    printf "$RESET"
}
###########
neko_03_blue() {
    neko_ascii_env
    printf "$BLUE"
    ${CATCAT} <<-'EndOFneko'
                     .::::..                
          ::::rrr7QQJi::i:iirijQBBBQB.      
          BBQBBBQBP. ......:::..1BBBB       
          .BuPBBBX  .........r.  vBQL  :Y.  
           rd:iQQ  ..........7L   MB    rr  
            7biLX .::.:....:.:q.  ri    .   
             JX1: .r:.r....i.r::...:.  gi5  
             ..vr .7: 7:. :ii:  v.:iv :BQg  
             : r:  7r:i7i::ri:DBr..2S       
          i.:r:. .i:XBBK...  :BP ::jr   .7. 
          r  i....ir r7.         r.J:   u.  
         :..X: .. .v:           .:.Ji       
        i. ..i .. .u:.     .   77: si   1Q  
       ::.. .r .. :P7.r7r..:iLQQJ: rv   ..  
      7  iK::r  . ii7r LJLrL1r7DPi iJ     r 
        .  ::.:   .  ri 5DZDBg7JR7.:r:   i. 
       .Pi r..r7:     i.:XBRJBY:uU.ii:.  .  
       QB rJ.:rvDE: .. ri uv . iir.7j r7.   
      iBg ::.7251QZ. . :.      irr:Iu: r.   
       QB  .:5.71Si..........  .sr7ivi:U    
       7BJ .7: i2. ........:..  sJ7Lvr7s    
        jBBdD. :. ........:r... YB  Bi      
           :7j1.                 :  :       
EndOFneko
    printf "$RESET"
}
############
modify_xsdl_conf() {
    source ${TMOE_TOOL_DIR}/gui/gui.sh -x
}
########
install_virtual_box() {
    source ${TMOE_TOOL_DIR}/virtualization/vbox.sh
}
#############
wine_menu() {
    source ${TMOE_TOOL_DIR}/virtualization/wine32.sh
}
###########
install_anbox() {
    source ${TMOE_TOOL_DIR}/virtualization/anbox.sh
}
###########
install_browser() {
    source ${TMOE_TOOL_DIR}/app/browser.sh
}
###########
explore_debian_opt_repo() {
    source ${TMOE_TOOL_DIR}/sources/debian-opt.sh
}
#################
install_filebrowser() {
    source ${TMOE_TOOL_DIR}/webserver/filebrowser.sh
}
##########
install_nginx_webdav() {
    source ${TMOE_TOOL_DIR}/webserver/nginx-webdav.sh
}
##########
add_debian_opt_gpg_key() {
    cd /etc/apt/trusted.gpg.d
    if [[ ! -s "debian-opt.gpg" ]]; then
        curl -L 'https://bintray.com/user/downloadSubjectPublicKey?username=bintray' | gpg --dearmor >/tmp/debian-opt.gpg
        install -o root -g root -m 644 /tmp/debian-opt.gpg /etc/apt/trusted.gpg.d/
    fi
    printf "%s\n%s\n" "deb ${OPT_URL_01} buster main" "#deb ${OPT_URL_02} buster main" >${OPT_REPO_LIST}
    chmod a+r -v ${OPT_REPO_LIST}
    apt update
}
###########
install_container_and_virtual_machine() {
    source ${TMOE_TOOL_DIR}/virtualization/virt-menu -m
}
#############
tmoe_education_app_menu() {
    source ${TMOE_TOOL_DIR}/app/education.sh
}
###########
install_pinyin_input_method() {
    source ${TMOE_TOOL_DIR}/app/input-method.sh
}
###########
network_manager_tui() {
    source ${TMOE_TOOL_DIR}/system/network.sh
}
##########
tmoe_system_app_menu() {
    source ${TMOE_TOOL_DIR}/system/sys-menu.sh
}
##########
where_is_tmoe_file_dir() {
    CURRENT_QEMU_ISO_FILENAME="$(printf '%s\n' "${CURRENT_QEMU_ISO}" | awk -F '/' '{print $NF}')"
    if [ -n "${CURRENT_QEMU_ISO}" ]; then
        CURRENT_QEMU_ISO_FILEPATH="$(printf '%s\n' "${CURRENT_QEMU_ISO}" | sed "s@${CURRENT_QEMU_ISO_FILENAME}@@")"
    fi

    if [ -d "${CURRENT_QEMU_ISO_FILEPATH}" ]; then
        START_DIR="${CURRENT_QEMU_ISO_FILEPATH}"
        tmoe_file_manager
    else
        where_is_start_dir
    fi
}
##############
uncompress_tar_gz_file() {
    printf '%s\n' '正在解压中...'
    if [ $(command -v pv) ]; then
        pv ${DOWNLOAD_FILE_NAME} | tar -pzx
    else
        tar -zpxvf ${DOWNLOAD_FILE_NAME}
    fi
}
###################
download_deb_comman_model_02() {
    cd /tmp/
    THE_LATEST_DEB_LINK="${REPO_URL}${THE_LATEST_DEB_VERSION}"
    printf "%s\n" "${THE_LATEST_DEB_LINK}"
    aria2c --console-log-level=info --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_VERSION}" "${THE_LATEST_DEB_LINK}"
    apt-cache show ./${THE_LATEST_DEB_VERSION}
    apt install -y ./${THE_LATEST_DEB_VERSION}
    rm -fv ${THE_LATEST_DEB_VERSION}
}
#########################
grep_deb_comman_model_02() {
    THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '\.deb' | grep "${GREP_NAME_01}" | grep "${GREP_NAME_02}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
    download_deb_comman_model_02
}
###################
grep_deb_comman_model_01() {
    THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '\.deb' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
    download_deb_comman_model_02
}
###################
tmoe_debian_add_ubuntu_ppa_source() {
    non_debian_function
    if [ ! $(command -v add-apt-repository) ]; then
        apt update
        apt install -y software-properties-common
    fi
    TARGET=$(whiptail --inputbox "请输入ppa软件源,以ppa开头,格式为ppa:xxx/xxx\nPlease type the ppa source name,the format is ppa:xx/xx" 0 50 --title "ppa:xxx/xxx" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        tmoe_sources_list_manager
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的名称"
        printf "%s\n" "Please enter a valid name."
    else
        add_ubuntu_ppa_source
    fi
}
####################
add_ubuntu_ppa_source() {
    if [ "$(printf '%s\n' "${TARGET}" | grep 'sudo add-apt-repository')" ]; then
        TARGET="$(printf '%s\n' "${TARGET}" | sed 's@sudo add-apt-repository@@')"
    elif [ "$(printf '%s\n' "${TARGET}" | grep 'add-apt-repository ')" ]; then
        TARGET="$(printf '%s\n' "${TARGET}" | sed 's@add-apt-repository @@')"
    fi
    add-apt-repository ${TARGET}
    if [ "$?" != "0" ]; then
        tmoe_sources_list_manager
    fi
    DEV_TEAM_NAME=$(printf '%s\n' "${TARGET}" | cut -d '/' -f 1 | cut -d ':' -f 2)
    PPA_SOFTWARE_NAME=$(printf '%s\n' "${TARGET}" | cut -d ':' -f 2 | cut -d '/' -f 2)
    if [ "${DEBIAN_DISTRO}" != 'ubuntu' ]; then
        get_ubuntu_ppa_gpg_key
    fi
    modify_ubuntu_sources_list_d_code
    apt update
    printf "%s\n" "添加软件源列表完成，是否需要执行${GREEN}apt install ${PPA_SOFTWARE_NAME}${RESET}"
    do_you_want_to_continue
    apt install ${PPA_SOFTWARE_NAME}
}
###########
get_ubuntu_ppa_gpg_key() {
    DESCRIPTION_PAGE="https://launchpad.net/~${DEV_TEAM_NAME}/+archive/ubuntu/${PPA_SOFTWARE_NAME}"
    cd /tmp
    aria2c --console-log-level=info --no-conf --allow-overwrite=true -o .ubuntu_ppa_tmoe_cache ${DESCRIPTION_PAGE}
    FALSE_FINGERPRINT_LINE=$(cat .ubuntu_ppa_tmoe_cache | grep -n 'Fingerprint:' | awk '{print $1}' | cut -d ':' -f 1)
    TRUE_FINGERPRINT_LINE=$((${FALSE_FINGERPRINT_LINE} + 1))
    PPA_GPG_KEY=$(cat .ubuntu_ppa_tmoe_cache | sed -n ${TRUE_FINGERPRINT_LINE}p | cut -d '<' -f 2 | cut -d '>' -f 2)
    rm -f .ubuntu_ppa_tmoe_cache
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com ${PPA_GPG_KEY}
    #press_enter_to_return
    #tmoe_sources_list_manager
}
###################
check_ubuntu_ppa_list() {
    cd /etc/apt/sources.list.d
    GREP_NAME="${DEV_TEAM_NAME}-ubuntu-${PPA_SOFTWARE_NAME}"
    PPA_LIST_FILE=$(ls ${GREP_NAME}-* | head -n 1)
    CURRENT_UBUNTU_CODE=$(grep -v '^#' ${PPA_LIST_FILE} | awk '{print $3}' | head -n 1)
}
#################
modify_ubuntu_sources_list_d_code() {
    check_ubuntu_ppa_list
    if [ "${DEBIAN_DISTRO}" = 'ubuntu' ] || egrep -q 'sid|testing' /etc/issue; then
        TARGET_BLANK_CODE="${CURRENT_UBUNTU_CODE}"
    else
        TARGET_BLANK_CODE="bionic"
    fi

    TARGET_CODE=$(whiptail --inputbox "请输入您当前使用的debian系统对应的ubuntu版本代号,例如focal\n当前ppa软件源的ubuntu代号为${CURRENT_UBUNTU_CODE}\n若取消则不修改,若留空则设定为${TARGET_BLANK_CODE}\nPlease type the ubuntu code name.\nFor example,buster corresponds to bionic." 0 50 --title "Ubuntu code(groovy,focal,etc.)" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        TARGET_CODE="${CURRENT_UBUNTU_CODE}"
    elif [ -z "${TARGET_CODE}" ]; then
        TARGET_CODE=${TARGET_BLANK_CODE}
    fi

    if [ ${TARGET_CODE} = ${CURRENT_UBUNTU_CODE} ]; then
        printf "%s\n" "您没有修改ubuntu code，当前使用Ubuntu ${TARGET_CODE}的ppa软件源"
    else
        sed -i "s@ ${CURRENT_UBUNTU_CODE}@ ${TARGET_CODE}@g" ${PPA_LIST_FILE}
        printf "%s\n" "已将${CURRENT_UBUNTU_CODE}修改为${TARGET_CODE},若更新错误，则请手动修改$(pwd)/${PPA_LIST_FILE}"
    fi
}
###################
fix_vnc_dbus_launch() {
    source ${TMOE_TOOL_DIR}/gui/gui.sh --fix-dbus
}
#################
source_vscode_script() {
    source ${TMOE_TOOL_DIR}/code/vscode.sh
}
#################
#吾欲将其分离，立为独项
tmoe_aria2_manager() {
    bash ${TMOE_TOOL_DIR}/downloader/aria2.sh
}
#############
install_gnome_system_monitor() {
    DEPENDENCY_01=''
    DEPENDENCY_02="gnome-system-monitor"
    beta_features_quick_install
}
###############
install_typora() {
    DEPENDENCY_01="typora"
    DEPENDENCY_02=""
    #NON_DEBIAN=true
    non_debian_function
    beta_features_quick_install
    cd /tmp
    GREP_NAME='typora'
    case "${ARCH_TYPE}" in
    "amd64")
        LATEST_DEB_REPO='http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/t/typora/'
        download_debian_cn_repo_deb_file_model_01
        #aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'typora.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/t/typora/typora_0.9.67-1_amd64.deb'
        ;;
    "i386")
        LATEST_DEB_REPO='https://mirrors.bfsu.edu.cn/deepin/pool/non-free/t/typora/'
        download_tuna_repo_deb_file_model_03
        #aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'typora.deb' 'https://mirrors.bfsu.edu.cn/deepin/pool/non-free/t/typora/typora_0.9.22-1_i386.deb'
        ;;
    *) arch_does_not_support ;;
    esac
    apt-cache show ./typora.deb
    apt install -y ./typora.deb
    #rm -vf ./typora.deb
    beta_features_install_completed
}
################
chmod_4755_chrome_sandbox() {
    printf "%s\n" "${GREEN}find ${YELLOW}/opt/electron ${BLUE}-type d -print${RESET} | ${GREEN}xargs ${BLUE}chmod -v a+x${RESET}"
    find /opt/electron -type d -print | xargs chmod -v a+x
    find /opt/electron -type f -print | xargs chmod a+r
    SANDBOX_FILE='/opt/electron/chrome-sandbox'
    chmod -v 4755 ${SANDBOX_FILE}
}
##############
download_the_latest_electron() {
    latest_electron
    download_electron
    #twice
    if [ ! -e "/opt/electron/electron" ]; then
        ELECTRON_MIRROR_STATION='https://npm.taobao.org/mirrors/electron'
        latest_electron_ali
        download_electron
    fi

    if [ ! -e "/usr/bin/electron" ]; then
        ln -svf /opt/electron/electron /usr/bin/
    fi
    chmod_4755_chrome_sandbox
    electron -v --no-sandbox | head -n 1 >${TMOE_LINUX_DIR}/electron_version.txt
}
##########
fix_fedora_electron_libxssl() {
    case ${LINUX_DISTRO} in
    redhat) dnf install -y libXScrnSaver || yum install -y libXScrnSaver ;;
    arch) [[ -e /usr/lib/libnss3.so ]] || pacman -Syu --noconfirm --needed nss ;;
    suse)
        #if [[ ! -e /usr/lib/libnss3.so && ! -e /usr/lib64/libnss3.so ]]; then
        zypper in -y mozilla-nss
        #fi
        ;;
    debian) [[ -n $(whereis libnss3.so) ]] || apt install -y libnss3 ;;
    *) [[ -e /usr/lib/libnss3.so ]] || ${TMOE_INSTALLATION_COMMAND} nss ;;
        #void的nss3.so的pkg name为nss
    esac
}
##########
check_electron() {
    if [ ! -e "/opt/electron/electron" ]; then
        mkdir -pv /opt
        fix_fedora_electron_libxssl
        download_the_latest_electron
    fi
    if [ ! $(command -v electron) ]; then
        chmod +x /opt/electron/electron
        ln -sf /opt/electron/electron /usr/bin
    fi
}
##########
install_electron_v8() {
    #v8不要创建soft link
    electron_v8_env
    if [ ! -e "${DOWNLOAD_PATH}/electron" ]; then
        fix_fedora_electron_libxssl
        download_electron
        printf "%s\n" "${GREEN}find ${YELLOW}${DOWNLOAD_PATH} ${BLUE}-type d -print${RESET} | ${GREEN}xargs ${BLUE}chmod -v a+x${RESET}"
        find ${DOWNLOAD_PATH} -type d -print | xargs chmod -v a+x
        find ${DOWNLOAD_PATH} -type f -print | xargs chmod a+r
        chmod -v 755 ${DOWNLOAD_PATH}
        chmod -v 4755 ${DOWNLOAD_PATH}/chrome-sandbox
    fi
    #检测twice
    if [ ! -e "${DOWNLOAD_PATH}/electron" ]; then
        ELECTRON_MIRROR_STATION='https://npm.taobao.org/mirrors/electron'
        download_electron
    fi
    chmod 4755 ${DOWNLOAD_PATH}/chrome-sandbox
}
##############
download_tmoe_electron_app() {
    DOWNLOAD_PATH="/tmp/.${DEPENDENCY_01}_TEMP_FOLDER"
    [[ ! -e "${DOWNLOAD_PATH}" ]] || rm -rv ${DOWNLOAD_PATH}
    [[ -e /opt ]] || mkdir -pv /opt
    git clone --depth=1 ${GIT_AK2}/${DEPENDENCY_01}_build ${DOWNLOAD_PATH}
    cd ${DOWNLOAD_PATH}
    tar -Jxvf app.tar.xz -C /opt
    if [ -n "${OPT_APP_VERSION_TXT}" ]; then
        [[ -e ${OPT_APP_VERSION_TXT} ]] || printf "%s\n" "${THE_LATEST_DEB_FILE}" >${OPT_APP_VERSION_TXT}
    fi
    if [ -e "/opt/${DEPENDENCY_01}" ]; then
        #case ${DEPENDENCY_01} in
        #zy-player | netron)
        printf "%s\n" "${GREEN}find ${YELLOW}/opt/${DEPENDENCY_01} ${BLUE}-type d -print${RESET} | ${GREEN}xargs ${BLUE}chmod -v a+x${RESET}"
        chmod -Rv 755 /opt/${DEPENDENCY_01}/usr/bin/ 2>/dev/null
        find /opt/${DEPENDENCY_01} -type d -print | xargs chmod -v a+x
        find /opt/${DEPENDENCY_01} -type f -print | xargs chmod a+r
        #   ;;
        #esac
        cd /opt/${DEPENDENCY_01}
        pwd
        cp -vf .${APPS_LNK_DIR}/${DEPENDENCY_01}.desktop ${APPS_LNK_DIR}
    else
        cd /tmp
    fi
    rm -rfv ${DOWNLOAD_PATH}
}
###################
aria2c_download_normal_file_s3() {
    printf "%s\n" "${YELLOW}${DOWNLOAD_FILE_URL}${RESET}"
    cd ${DOWNLOAD_PATH}
    #aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 3 -x 3 -k 1M "${DOWNLOAD_FILE_URL}"
    #此处用wget会自动转义url
    wget "${DOWNLOAD_FILE_URL}"
}
######################
aria2c_download_file_00() {
    if [ -z "${DOWNLOAD_PATH}" ]; then
        cd ~
    else
        if [ ! -e "${DOWNLOAD_PATH}" ]; then
            mkdir -pv ${DOWNLOAD_PATH}
        fi
        cd ${DOWNLOAD_PATH}
    fi
}
###############
aria2c_download_file() {
    printf "%s\n" "${YELLOW}${THE_LATEST_ISO_LINK}${RESET}"
    do_you_want_to_continue
    aria2c_download_file_00
    aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M "${THE_LATEST_ISO_LINK}"
}
############
aria2c_download_file_no_confirm() {
    printf "%s\n" "${YELLOW}${ELECTRON_FILE_URL}${RESET}"
    aria2c_download_file_00
    aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M "${ELECTRON_FILE_URL}"
}
############
extract_electron() {
    if [ ! $(command -v unzip) ]; then
        ${TMOE_INSTALLATION_COMMAND} unzip
    fi
    unzip -o ${ELECTRON_ZIP_FILE} || unzip ${ELECTRON_ZIP_FILE}
    rm -fv ${ELECTRON_ZIP_FILE}
    chmod a+x -v electron
}
#########
latest_electron() {
    unset ELECTRON_VERSION
    #ELECTRON_VERSION_PREFIX=$(curl -Lv "${ELECTRON_MIRROR_STATION}" | grep 'mirrors/electron' | awk -F '/' '{print $4}' | grep -v '^0' | grep '^[0-9]' | sort -n | tail -n 4 | sort -n -k 4 -t . | tail -n 1 | awk -F '.' '{print $1}')
    #ELECTRON_VERSION=$(curl -L "${ELECTRON_MIRROR_STATION}" | grep 'mirrors/electron' | awk -F '/' '{print $4}' | grep -v '^0' | grep '^[0-9]' | grep "^${ELECTRON_VERSION_PREFIX}\." | sort -n | tail -n 50 | sort -n -k 4 -t . | tail -n 1)
    ELECTRON_VERSION="$(curl -L "${ELECTRON_MIRROR_STATION}" | awk -F '<a href=' '{print $2}' | cut -d '"' -f 2 | grep -v '^0' | grep '^[0-9]' | sort -n | cut -d '/' -f 1 | grep '^11\.' | tail -n 1)"
    #ELECTRON_VERSION=11.1.1
    DOWNLOAD_PATH="/opt/electron"
    [[ -n ${ELECTRON_VERSION} ]] || latest_electron_ali
}
########
latest_electron_ali() {
    ELECTRON_MIRROR_STATION='https://npm.taobao.org/mirrors/electron'
    #ELECTRON_VERSION_PREFIX=$(curl -Lv "${ELECTRON_MIRROR_STATION}" | grep 'mirrors/electron' | awk -F '/' '{print $4}' | grep -v '^0' | grep '^[0-9]' | sort -n | tail -n 4 | sort -n -k 4 -t . | tail -n 1 | awk -F '.' '{print $1}')
    #ELECTRON_VERSION=$(curl -L "${ELECTRON_MIRROR_STATION}" | grep 'mirrors/electron' | awk -F '/' '{print $4}' | grep -v '^0' | grep '^[0-9]' | grep "^${ELECTRON_VERSION_PREFIX}\." | sort -n | tail -n 50 | sort -n -k 4 -t . | tail -n 1)
    ELECTRON_VERSION=$(curl -L "${ELECTRON_MIRROR_STATION}" | grep 'mirrors/electron' | awk -F '/' '{print $4}' | grep -v '^0' | grep '^[0-9]' | grep "^11\." | sort -n | tail -n 1)
    DOWNLOAD_PATH="/opt/electron"
}
download_electron() {
    case ${ARCH_TYPE} in
    amd64) ARCH_TYPE_02='x64' ;;
    arm64) ARCH_TYPE_02="${ARCH_TYPE}" ;;
    armhf) ARCH_TYPE_02='armv7l' ;;
    i386) ARCH_TYPE_02='ia32' ;;
    *) arch_does_not_support ;;
    esac
    [[ -n ${ELECTRON_VERSION} ]] || ELECTRON_VERSION="11.2.0"
    #https://github.com/electron/electron/releases/download/v11.2.0/electron-v11.2.0-linux-arm64.zip
    ELECTRON_ZIP_FILE="electron-v${ELECTRON_VERSION}-linux-${ARCH_TYPE_02}.zip"
    ELECTRON_FILE_URL="${ELECTRON_MIRROR_STATION}/${ELECTRON_VERSION}/${ELECTRON_ZIP_FILE}"
    ELECTRON_GIT_RELEASE_URL="https://github.com/electron/electron/releases/download/v${ELECTRON_VERSION}/${ELECTRON_ZIP_FILE}"
    #aria2c_download_file_no_confirm
    printf "${YELLOW}%s\n%s${RESET}\n" "${ELECTRON_FILE_URL}" "${ELECTRON_GIT_RELEASE_URL}"
    aria2c_download_file_00
    case ${AUTO_INSTALL_GUI} in
    true)
        printf "%s\n" "${BLUE}${ELECTRON_GIT_RELEASE_URL}${RESET}"
        aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 3 -x 3 -k 1M "${ELECTRON_GIT_RELEASE_URL}" || aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M "${ELECTRON_FILE_URL}"
        ;;
    *) aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M "${ELECTRON_FILE_URL}" || aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 10 -x 10 -k 1M "${ELECTRON_GIT_RELEASE_URL}" ;;
    esac
    extract_electron
}
###########
electron_v8_env() {
    ELECTRON_VERSION="8.5.5"
    DOWNLOAD_PATH="/opt/electron-v8"
}
#########
extract_deb_file_01() {
    ar xv ${THE_LATEST_DEB_FILE}
    if [ -e "data.tar.xz" ]; then
        DEB_FILE_TYPE='tar.xz'
    elif [ -e "data.tar.gz" ]; then
        DEB_FILE_TYPE='tar.gz'
    else
        DEB_FILE_TYPE='tar'
    fi
}
###########
extract_deb_file_02() {
    cd /
    case "${DEB_FILE_TYPE}" in
    tar.xz) tar -PpJxvf ${DOWNLOAD_PATH}/data.tar.xz ".${APPS_LNK_DIR}" ./opt ./usr/share/icons ;;
    tar.gz) tar -Ppzxvf ${DOWNLOAD_PATH}/data.tar.gz ".${APPS_LNK_DIR}" ./opt ./usr/share/icons ;;
    ar.zst) tar -I zstd -Ppxvf ${DOWNLOAD_PATH}/data.tar.zst ".${APPS_LNK_DIR}" ./opt ./usr/share/icons ;;
    *) tar -Ppxvf ${DOWNLOAD_PATH}/data.* ".${APPS_LNK_DIR}" ./opt ./usr/share/icons ;;
    esac
    cd /tmp
    rm -rv ${DOWNLOAD_PATH}
}
#############
install_gpg() {
    if [ ! $(command -v gpg) ]; then
        DEPENDENCY_01=""
        DEPENDENCY_02="gnupg"
        beta_features_quick_install
    fi
}
#########
install_java() {
    if [ ! $(command -v java) ]; then
        DEPENDENCY_01=''
        case "${LINUX_DISTRO}" in
        arch)
            DEPENDENCY_01='jre-openjdk'
            DEPENDENCY_02='jdk-openjdk'
            ;;
        debian | "")
            DEPENDENCY_01='default-jre'
            DEPENDENCY_02='default-jdk'
            ;;
        alpine)
            DEPENDENCY_01='openjdk11-jre'
            DEPENDENCY_02='openjdk11-jdk'
            ;;
        void)
            DEPENDENCY_01='openjdk11'
            DEPENDENCY_02='openjdk11-bin'
            ;;
        redhat)
            case ${REDHAT_DISTRO} in
            fedora)
                DEPENDENCY_01='java-latest-openjdk'
                DEPENDENCY_02='java-latest-openjdk-devel'
                ;;
            *)
                #java-11-openjdk-devel
                DEPENDENCY_02=$(yum search openjdk-devel 2>&1 | grep Develop | head -n 1 | awk '{print $1}' | cut -d '.' -f 1)
                ;;
            esac
            ;;
        *)
            DEPENDENCY_01='openjdk'
            DEPENDENCY_02='java'
            ;;
        esac
        beta_features_quick_install
    fi

    case "${LINUX_DISTRO}" in
    debian)
        if [ ! -e "/usr/share/doc/default-jdk" ]; then
            DEPENDENCY_01=''
            DEPENDENCY_02='default-jdk'
            beta_features_quick_install
        fi
        ;;
    esac
}
#######
check_zenity() {
    if [ ! $(command -v zenity) ]; then
        DEPENDENCY_01='zenity'
        DEPENDENCY_02=''
        beta_features_quick_install
    fi
}
###########
add_debian_old_source() {
    case ${DEBIAN_DISTRO} in
    ubuntu) ;;
    *)
        if ! grep -q '^deb.*buster' /etc/apt/sources.list; then
            printf '%s\n' 'deb https://mirrors.huaweicloud.com/debian/ buster main' >>/etc/apt/sources.list.d/tmoe_old_debian_source.list
            apt update
        fi
        ;;
    esac
}
##########
del_debian_old_source() {
    DEBIAN_OLD_SOURCE='/etc/apt/sources.list.d/tmoe_old_debian_source.list'
    if [ -e "${DEBIAN_OLD_SOURCE}" ]; then
        rm -f ${DEBIAN_OLD_SOURCE}
        apt update
    fi
}
###############
tmoe_apt_update() {
    case ${LINUX_DISTRO} in
    arch | fedora) ;;
    *) ${TMOE_UPDATE_COMMAND} 2>/dev/null ;;
    esac
}
############
check_zstd() {
    if [ ! $(command -v zstd) ]; then
        printf "%s\n" "正在安装相关依赖..."
        printf "%s\n" "${GREEN}${TMOE_INSTALLATION_COMMAND}${RESET} ${BLUE}zstd${RESET}"
        tmoe_apt_update
        ${TMOE_INSTALLATION_COMMAND} zstd
        printf "%s\n" "If you want to ${RED}remove it${RESET}，please ${YELLOW}manually type ${PURPLE}${TMOE_REMOVAL_COMMAND} ${BLUE}zstd${RESET}"
    fi
}
##############
cat_icon_img() {
    if [ -e "${ICON_FILE}" ]; then
        if [ $(command -v catimg) ]; then
            catimg "${ICON_FILE}"
        else
            random_neko
        fi
    else
        random_neko
    fi
}
##############
do_you_want_to_upgrade_it() {
    UPGRADE_TIPS="您是否需要更新${GREP_NAME}?"
    if [ -e /usr/games/lolcat ]; then
        printf "%s\n" "${UPGRADE_TIPS}" | /usr/games/lolcat -a -d 7
    elif [ "$(command -v lolcat)" ]; then
        printf "%s\n" "${UPGRADE_TIPS}" | lolcat
    else
        printf "%s\n" "${UPGRADE_TIPS}"
    fi
    do_you_want_to_continue
}
##################
do_you_want_to_upgrade_it_02() {
    UPGRADE_TIPS="您是否需要更新${DEPENDENCY_01}?"
    if [ -e /usr/games/lolcat ]; then
        printf "%s\n" "${UPGRADE_TIPS}" | /usr/games/lolcat
    elif [ "$(command -v lolcat)" ]; then
        printf "%s\n" "${UPGRADE_TIPS}" | lolcat
    else
        printf "%s\n" "${UPGRADE_TIPS}"
    fi
}
##################
check_deb_version() {
    cat <<-ENDofTable
		╔═══╦══════════╦═══════════════════╦════════════════════
		║   ║          ║                   ║                    
		║   ║ software ║    ✨最新版本     ║   本地版本 🎪
		║   ║          ║  Latest version   ║  Local version     
		║---║----------║-------------------║--------------------
		║ 1 ║${GREP_NAME}                    
		║   ║          ║${THE_LATEST_DEB_VERSION}
		║   ║          ║                   ${LOCAL_OPT_APP_VERSION} 
	ENDofTable
    printf "%s\n" "最新版链接为${BLUE}${THE_LATEST_DEB_URL}${RESET}"
}
################
install_tmoe_app_01() {
    random_neko
    printf "%s\n" "正在检测版本更新信息..."
    printf "%s\n" "若安装失败，则请前往官网手动下载安装。"
    printf "%s\n" "url: ${YELLOW}${OFFICIAL_URL}${RESET}"
    case ${DEPENDENCY_01} in
    vivaldi-stable | vivaldi | vivaldi-arm64) install_vivaldi_browser ;;
    browser360-cn-stable | browser360) install_360_browser ;;
    yozo-office) install_yozo_office ;;
    freeoffice) install_free_office ;;
    mitalk) install_mitalk ;;
    xunlei-bin | com.xunlei.download) install_thunder_bin ;;
    esac
}
###########
remove_tmoe_app_01() {
    printf "%s\n" "${RED}rm -v${RESET} ${BLUE}${LOCAL_APP_VERSION_TXT}${RESET};${RED}${TMOE_REMOVAL_COMMAND}${RESET} ${BLUE}${DEPENDENCY_01} ${DEPENDENCY_02}${RESET}"
    do_you_want_to_continue
    case ${GREP_NAME} in
    com.xunlei.download) remove_thunder_opt_app ;;
    *)
        rm -v ${LOCAL_APP_VERSION_TXT}
        ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
        ;;
    esac
}
###########
tmoe_app_menu_01() {
    check_opt_app_version
    #check_download_path
    RETURN_TO_WHERE='tmoe_app_menu_01'
    SOFTWARE=$(
        whiptail --title "${GREP_NAME}" --menu \
            "您想要对${GREP_NAME}小可爱做什么？" 0 50 0 \
            "1" "install/upgrade(安装/更新)" \
            "2" "remove(卸载${GREP_NAME})" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case "${SOFTWARE}" in
    0 | "") ${RETURN_TO_MENU} ;;
    1) install_tmoe_app_01 ;;
    2) remove_tmoe_app_01 ;;
    esac
    #############################
    press_enter_to_return
    tmoe_app_menu_01
}
###########
lolcat_tmoe_tips_01() {
    if [ -e /usr/games/lolcat ]; then
        printf "%s\n" "${TMOE_TIPS_01}" | /usr/games/lolcat -a -d 9
    elif [ "$(command -v lolcat)" ]; then
        printf "%s\n" "${TMOE_TIPS_01}" | lolcat
    else
        printf "%s\n" "${TMOE_TIPS_01}"
    fi
    case ${LINUX_DISTRO} in
    debian) ;;
    arch) printf "%s\n" "检测到您使用的是arch系发行版，若安装失败，则请通过AUR来安装软件包" ;;
    redhat) printf "%s\n" "检测到您使用的是红帽系发行版，将为您下载rpm软件包" ;;
    esac
    #do_you_want_to_upgrade_it_02
    printf "%s\n" "您是否需要${GREEN}更新${RESET}${BLUE}${DEPENDENCY_01}${RESET}?"
}
###################
download_and_install_deb() {
    do_you_want_to_upgrade_it_02
    do_you_want_to_continue
    cd /tmp
    case ${LINUX_DISTRO} in
    debian | redhat) aria2c --console-log-level=info --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_FILE}" "${THE_LATEST_DEB_URL}" ;;
    esac
    case ${LINUX_DISTRO} in
    debian)
        apt-cache show ./${THE_LATEST_DEB_FILE}
        apt install -y ./${THE_LATEST_DEB_FILE}
        ;;
    redhat) yum install -y ./${THE_LATEST_DEB_FILE} ;;
    arch | *) beta_features_quick_install ;;
    esac
    rm -v ./${THE_LATEST_DEB_FILE} 2>/dev/null
    printf "%s\n" "${THE_LATEST_DEB_VERSION}" >${LOCAL_APP_VERSION_TXT}
    case ${LINUX_DISTRO} in
    arch) ;;
    *) beta_features_install_completed ;;
    esac
}
############
this_app_may_non_support_running_on_proot() {
    case ${TMOE_PROOT} in
    false) ;;
    true | no)
        printf "%s\n" "本软件可能不支持在proot容器环境中运行"
        printf "%s\n" "This application may not support running on a proot container."
        do_you_want_to_continue
        ;;
    esac
}
#############
download_and_cat_icon_img() {
    if [ ! -e "${TMOE_ICON_DIR}/${ICON_FILE_NAME}" ]; then
        mkdir -pv ${TMOE_ICON_DIR}
        aria2c --console-log-level=error --no-conf -d ${TMOE_ICON_DIR} -o ${ICON_FILE_NAME} ${ICON_URL}
    fi
    if [ $(command -v catimg) ]; then
        catimg "${TMOE_ICON_DIR}/${ICON_FILE_NAME}" 2>/dev/null
    fi
}
###########
where_is_arm_gnu_libxcb() {
    case $(uname -m) in
    armv7* | armv6*) GNU_LIBXCB="/usr/lib/arm-linux-gnueabihf/libxcb.so.1.1.0" ;;
    *) GNU_LIBXCB="/usr/lib/$(uname -m)-linux-gnu/libxcb.so.1.1.0" ;;
    esac
}
where_is_gnu_libxcb() {
    if [ $(command -v whereis) ]; then
        GNU_LIBXCB="$(whereis libxcb.so.1.1.0 | awk '{print $2}')"
        case ${GNU_LIBXCB} in
        "") where_is_arm_gnu_libxcb ;;
        esac
    else
        where_is_arm_gnu_libxcb
    fi
}
###########
restore_debian_gnu_libxcb_so() {
    case ${TMOE_PROOT} in
    true | false)
        case ${LINUX_DISTRO} in
        debian)
            where_is_gnu_libxcb
            if [ -e "${ORIGINAL_LIBXCB_FILE}" ]; then
                mv -f ${ORIGINAL_LIBXCB_FILE} ${GNU_LIBXCB}
            fi
            ;;
        esac
        ;;
    esac
}
###########
check_mozilla_fake_no_sandbox() {
    case ${TMOE_PROOT} in
    false) ;;
    true | no)
        if (whiptail --title "MOZ_FAKE_NO_SANDBOX ENV" --yes-button "YES" --no-button "NO" --yesno "Do you want to add MOZ_FAKE_NO_SANDBOX=1 to /etc/environment" 8 50); then
            if ! egrep -q '^[^#]*export.*MOZ_FAKE_NO_SANDBOX.*1' /etc/environment; then
                printf "%s\n" "export MOZ_FAKE_NO_SANDBOX=1" >>/etc/environment
            fi
        else
            sed -i '/MOZ_FAKE_NO_SANDBOX=/d' /etc/environment
        fi
        sed -n p /etc/environment
        ;;
    esac
}
###########
gnu_linux_env_02
