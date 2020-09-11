#!/usr/bin/env bash
##################################
kde_config_module_for_fcitx() {
    DEPENDENCY_01=""
    DEPENDENCY_02='kcm-fcitx'
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02='kcm-fcitx'
        #kcm-fcitx
    elif [ "${LINUX_DISTRO}" = "debian" ]; then
        DEPENDENCY_02='kde-config-fcitx'
        #kde-config-fcitx
    fi
    beta_features_quick_install
}
############
tmoe_fcitx5_menu() {
    check_zstd
    RETURN_TO_WHERE='tmoe_fcitx5_menu'
    
    INPUT_METHOD=$(
        whiptail --title "Fcitx5" --menu "Fcitx5 是继 Fcitx 后的新一代输入法框架。\n词库是输入法保存的一些流行词语、常用词语或专业术语等的信息,\n添加流行词库能增加流行候选词的命中率" 0 55 0 \
            "1" "fcitx5安装与卸载" \
            "2" "肥猫百万大词库@felixonmars" \
            "3" "萌娘百科词库@outloudvi" \
            "4" "fcitx5-rime" \
            "5" "beautification输入法美化主题" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") install_pinyin_input_method ;;
    1) install_fcitx5 ;;
    2) felixonmars_fcitx5_wiki_dict ;;
    3) outloudvi_fcitx5_moegirl_dict ;;
    4) install_fcitx5_rime ;;
    5) input_method_beautification ;;
    esac
    #"5" "Material Design质感主题@hosxy" \
    ###############
    press_enter_to_return
    tmoe_fcitx5_menu
}
############
input_method_beautification() {
    RETURN_TO_WHERE='input_method_beautification'
    DEPENDENCY_01=''
    
    FCIITX5_CLASSUI_CONF_PATH="${HOME}/.config/fcitx5/conf"
    FCIITX5_CLASSUI_CONF_FILE="${FCIITX5_CLASSUI_CONF_PATH}/classicui.conf"
    INPUT_METHOD=$(
        whiptail --title "Fcitx5" --menu "fcitx主题" 0 55 0 \
            "1" "Material Design(微软拼音风格)@hosxy" \
            "2" "kimpanel(支持kde-wayland)" \
            "3" "gnome-shell-extension-kimpanel(支持gnome-wayland)" \
            "4" "edit config编辑主题配置" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") tmoe_fcitx5_menu ;;
    1) configure_fcitx5_material_color_theme ;;
    2) install_kimpanel ;;
    3) install_gnome_shell_extension_kimpanel ;;
    4) edit_fcitx_theme_config_file ;;
    esac
    ###############
    press_enter_to_return
    input_method_beautification
}
##############
edit_fcitx_theme_config_file() {
    if [ $(command -v editor) ]; then
        editor ${FCIITX5_CLASSUI_CONF_FILE}
    else
        nano ${FCIITX5_CLASSUI_CONF_FILE}
    fi
    chown ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${FCIITX5_CLASSUI_CONF_FILE}
}
#############
configure_fcitx5_material_color_theme() {
    RETURN_TO_WHERE='configure_fcitx5_material_color_theme'
    MATERIAL_COLOR_FOLDER="${HOME}/.local/share/fcitx5/themes/Material-Color"
    CURRENT_FCITX5_COLOR="$(ls -l ${MATERIAL_COLOR_FOLDER}/panel.png | awk -F ' ' '{print $NF}' | cut -d '-' -f 2 | cut -d '.' -f 1)"
    if [ ! -z "${CURRENT_FCITX5_COLOR}" ]; then
        FCITX_THEME_STATUS="检测到当前fcitx5-material主题配色为${CURRENT_FCITX5_COLOR}"
    else
        FCITX_THEME_STATUS="检测到您未指定fcitx5-material主题的配色"
    fi
    if [ ! -e "${MATERIAL_COLOR_FOLDER}" ]; then
        FCITX_THEME_STATUS="检测您尚未下载fcitx5-material主题"
    fi
    PANEL_COLOR_PNG=''
    #DEPENDENCY_01=''
    #
    INPUT_METHOD=$(
        whiptail --title "Fcitx5 Material Design" --menu "https://github.com/hosxy/Fcitx5-Material-Color\n您可以在下载完成后，自由修改主题配色。\n${FCITX_THEME_STATUS}" 0 55 0 \
            "1" "download下载/更新" \
            "2" "delete删除" \
            "3" "Pink粉" \
            "4" "Blue蓝" \
            "5" "Brown棕" \
            "6" "DeepPurple深紫" \
            "7" "Indigo靛青" \
            "8" "Red红" \
            "9" "Teal水鸭绿" \
            "10" "origin原始" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") input_method_beautification ;;
    1) install_fcitx5_material_color_theme ;;
    2) delete_fcitx5_material_color_theme ;;
    3)
        PANEL_COLOR_PNG='panel-pink.png'
        HIGH_LIGHT_COLOR_PNG='highlight-pink.png'
        ;;
    4)
        PANEL_COLOR_PNG='panel-blue.png'
        HIGH_LIGHT_COLOR_PNG='highlight-blue.png'
        ;;
    5)
        PANEL_COLOR_PNG='panel-brown.png'
        HIGH_LIGHT_COLOR_PNG='highlight-brown.png'
        ;;
    6)
        PANEL_COLOR_PNG='panel-deepPurple.png'
        HIGH_LIGHT_COLOR_PNG='highlight-deepPurple.png'
        ;;
    7)
        PANEL_COLOR_PNG='panel-indigo.png'
        HIGH_LIGHT_COLOR_PNG='highlight-indigo.png'
        ;;
    8)
        PANEL_COLOR_PNG='panel-red.png'
        HIGH_LIGHT_COLOR_PNG='highlight-red.png'
        ;;
    9)
        PANEL_COLOR_PNG='panel-teal.png'
        HIGH_LIGHT_COLOR_PNG='highlight-teal.png'
        ;;
    10)
        PANEL_COLOR_PNG='panel-origin.png'
        HIGH_LIGHT_COLOR_PNG='highlight-origin.png'
        ;;
    esac
    ###############
    if [ ! -z "${PANEL_COLOR_PNG}" ]; then
        switch__fcitx5_material_color
    fi
    press_enter_to_return
    configure_fcitx5_material_color_theme
}
##############
switch__fcitx5_material_color() {
    if [ ! -e "${MATERIAL_COLOR_FOLDER}" ]; then
        install_fcitx5_material_color_theme
    fi
    cd ${MATERIAL_COLOR_FOLDER}
    if [ "$(command -v catimg)" ]; then
        catimg {PANEL_COLOR_PNG} 2>/dev/null
        catimg ${HIGH_LIGHT_COLOR_PNG} 2>/dev/null
    fi
    ln -sf ${PANEL_COLOR_PNG} panel.png
    ln -sf ${HIGH_LIGHT_COLOR_PNG} highlight.png
    if [ ${HOME} != '/root' ]; then
        echo "正在将panel.png和highlight.png的文件权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        chown ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} panel.png highlight.png
    fi
}
############
delete_fcitx5_material_color_theme() {
    echo "是否需要删除该主题？"
    echo "${RED}rm -rv ${MATERIAL_COLOR_FOLDER}${RESET}"
    do_you_want_to_continue
    rm -rv ${MATERIAL_COLOR_FOLDER}
    sed -i 's@^Theme=@#&@' ${FCIITX5_CLASSUI_CONF_FILE}
}
###############
install_fcitx5_material_color_theme() {
    #DEPENDENCY_02='fcitx5-material-color'
    #beta_features_quick_install
    #echo '请前往github阅读使用说明'
    #echo 'https://github.com/hosxy/Fcitx5-Material-Color'
    if [ ! -e ${MATERIAL_COLOR_FOLDER} ]; then
        mkdir -p ${MATERIAL_COLOR_FOLDER}
        git clone --depth=1 https://github.com/hosxy/Fcitx5-Material-Color.git ${MATERIAL_COLOR_FOLDER}
    else
        cd ${MATERIAL_COLOR_FOLDER}
        git pull
    fi

    mkdir -p ${FCIITX5_CLASSUI_CONF_PATH}
    cd ${FCIITX5_CLASSUI_CONF_PATH}
    if ! grep -q 'Theme=Material-Color-Pink' 'classicui.conf'; then
        write_to_fcitx_classui_conf
    fi

    if [ ${HOME} != '/root' ]; then
        echo "正在将${MATERIAL_COLOR_FOLDER}和${FCIITX5_CLASSUI_CONF_PATH}的文件权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${MATERIAL_COLOR_FOLDER} ${FCIITX5_CLASSUI_CONF_PATH}
    fi
}
###########
write_to_fcitx_classui_conf() {
    if [ -e classicui.conf ]; then
        sed -i 's@^Vertical Candidate List=@#&@' classicui.conf
        sed -i 's@^PerScreenDPI=@#&@' classicui.conf
        sed -i 's@^Theme=@#&@' classicui.conf
    fi
    cat >>${FCIITX5_CLASSUI_CONF_FILE} <<-'EOF'
		# 垂直候选列表
		Vertical Candidate List=False

		# 按屏幕 DPI 使用
		PerScreenDPI=True

		# 字体
		#Font="思源黑体 CN Medium 13"

		# 主题
		Theme=Material-Color-Pink
	EOF
}
###########
install_kimpanel() {
    #NON_DEBIAN='true'
    non_debian_function
    DEPENDENCY_02='fcitx5-module-kimpanel'
    beta_features_quick_install
}
#############
install_gnome_shell_extension_kimpanel() {
    DEPENDENCY_02='gnome-shell-extension-kimpanel'
    beta_features_quick_install
}
############
check_fcitx5_dict() {
    if [ ! -d ${FCITX5_DIICT_PATH} ]; then
        mkdir -p ${FCITX5_DIICT_PATH}
    fi
    DICT_FILE="${FCITX5_DIICT_PATH}/${DICT_NAME}"
    DICT_SHARE_FILE=".${FCITX5_DIICT_PATH}/${DICT_NAME}"
    #勿忘点
    #usr/share/fcitx5/pinyin/dictionaries/
    if [ -e "${DICT_FILE}" ]; then
        echo "检测到您${RED}已经下载过${RESET}${DICT_NAME}了"
        echo "该文件位于${BLUE}${FCITX5_DIICT_PATH}${RESET}"
        echo "如需删除，请手动执行${RED}rm -v ${DICT_FILE}${RESET}"
        ls -lah ${DICT_FILE}
        echo "sha256hash: $(sha256sum ${DICT_FILE})"
        echo "Do you want to ${RED}update it?${RESET}"
        echo "是否想要更新版本？"
        do_you_want_to_continue
    fi
}
#############
move_dict_model_01() {
    if [ -e "data.tar.zst" ]; then
        tar --zstd -xvf data.tar.zst &>/dev/null || zstdcat "data.tar.zst" | tar xvf -
    elif [ -e "data.tar.xz" ]; then
        tar -Jxvf data.tar.xz 2>/dev/null
    elif [ -e "data.tar.gz" ]; then
        tar -zxvf data.tar.gz 2>/dev/null
    else
        tar -xvf data.* 2>/dev/null
    fi
    #DICT_SHARE_PATH=fcitx5/pinyin/dictionaries/moegirl.dict
    mv -fv ${DICT_SHARE_FILE} ${FCITX5_DIICT_PATH}
    echo "chmod +r ${DICT_FILE}"
    chmod +r ${DICT_FILE}
    cd ..
    rm -rf /tmp/.${THEME_NAME}
    echo "${BLUE}文件${RESET}已经保存至${DICT_FILE}"
    echo "${BLUE}The file${RESET} have been saved to ${DICT_FILE}"
    ls -lah ${DICT_FILE}
    echo "如需删除，请手动执行rm -v ${DICT_FILE}"
}
###################
download_dict_model_01() {
    GREP_NAME_V='rime'
    THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/aarch64/'
    THEME_NAME="${GREP_NAME}"
    FCITX5_DIICT_PATH='/usr/share/fcitx5/pinyin/dictionaries'
    check_fcitx5_dict
    download_arch_community_repo_html
    grep_arch_linux_pkg_03
    move_dict_model_01
}
############
outloudvi_fcitx5_moegirl_dict() {
    DICT_NAME='moegirl.dict'
    GREP_NAME='fcitx5-pinyin-moegirl'
    download_dict_model_01
    echo 'https://github.com/outloudvi/fcitx5-pinyin-moegirl'
}
#################
felixonmars_fcitx5_wiki_dict() {
    DICT_NAME='zhwiki.dict'
    GREP_NAME='fcitx5-pinyin-zhwiki'
    download_dict_model_01
    echo 'https://github.com/felixonmars/fcitx5-pinyin-zhwiki'
}
#################
install_fcitx5() {
    DEPENDENCY_01="fcitx5-chinese-addons fcitx5"
    DEPENDENCY_02=""
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02='fcitx5-qt fcitx5-gtk kcm-fcitx5'
    elif [ "${LINUX_DISTRO}" = "debian" ]; then
        DEPENDENCY_02='kde-config-fcitx5'
    fi
    configure_system_fcitx5
    beta_features_quick_install
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        if [ ! $(command -v fcitx5-config-qt) ]; then
            DEPENDENCY_01=""
            echo '检测到您的软件源中不包含kde-config-fcitx5,您可以添加第三方ppa源来安装'
            echo "${GREEN}add-apt-repository ppa:hosxy/test${RESET}"
            echo '若ppa源添加失败，则请使用本工具内置的ppa源添加器'
            add-apt-repository ppa:hosxy/test
            beta_features_quick_install
        fi
    fi
}
##############
install_fcitx5_rime() {
    DEPENDENCY_01="fcitx5-rime"
    DEPENDENCY_02="fcitx5-pinyin-moegirl-rime"
    if [ "${LINUX_DISTRO}" != "arch" ]; then
        echo '截至20200723，本功能暂只适配Arch系发行版'
    fi
    configure_system_fcitx5
    beta_features_quick_install
}
#################
install_pinyin_input_method() {
    RETURN_TO_WHERE='install_pinyin_input_method'
    
    DEPENDENCY_01="fcitx"
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_01='fcitx-im fcitx-configtool'
        #kcm-fcitx
    elif [ "${LINUX_DISTRO}" = "debian" ]; then
        DEPENDENCY_01='fcitx fcitx-tools fcitx-config-gtk'
        #kde-config-fcitx
    fi
    INPUT_METHOD=$(
        whiptail --title "输入法" --menu "您想要安装哪个输入法呢？\nWhich input method do you want to install?" 17 55 8 \
            "1" "🍁 fcitx-FAQ:常见问题与疑难诊断" \
            "2" "🍀 fcitx5(软件与词库)" \
            "3" "google谷歌拼音(引擎fork自Android版)" \
            "4" "sogou(搜狗拼音)" \
            "5" "iflyime(讯飞语音+拼音+五笔)" \
            "6" "rime中州韻(擊響中文之韻)" \
            "7" "baidu(百度输入法)" \
            "8" "libpinyin(提供智能整句输入算法核心)" \
            "9" "sunpinyin(基于统计学语言模型)" \
            "10" "fcitx-云拼音模块" \
            "11" "onboard(屏幕虚拟键盘)" \
            "12" "uim(Universal Input Method)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") beta_features ;;
    1) tmoe_fcitx_faq ;;
    2) tmoe_fcitx5_menu ;;
    3) install_google_pinyin ;;
    4) install_sogou_pinyin ;;
    5) install_iflyime_pinyin ;;
    6) install_rime_pinyin ;;
    7) install_baidu_pinyin ;;
    8) install_lib_pinyin ;;
    9) install_sun_pinyin ;;
    10) install_fcitx_module_cloud_pinyin ;;
    11) install_onboard ;;
    12) install_uim_pinyin ;;
    esac
    ###############
    configure_arch_fcitx
    press_enter_to_return
    install_pinyin_input_method
}
########################
install_onboard() {
    DEPENDENCY_01=''
    DEPENDENCY_02='onboard'
    beta_features_quick_install
}
##################
tmoe_fcitx_faq() {
    
    DEPENDENCY_01=''
    RETURN_TO_WHERE='tmoe_fcitx_faq'
    TMOE_APP=$(whiptail --title "Fcitx FAQ" --menu \
        "你想要对这个小可爱做什么?" 0 50 5 \
        "1" "fcitx-diagnose:诊断" \
        "2" "KDE-fcitx4-模块" \
        "3" "remove ibus移除ibus(防止冲突)" \
        "4" "im-config:配置fcitx4输入法" \
        "5" "edit .xprofile(进入桌面后自动执行的配置)" \
        "6" "edit .pam_environment(用户环境变量配置文件)" \
        "7" "edit /etc/environment(系统环境变量配置文件)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${TMOE_APP}" in
    0 | "") install_pinyin_input_method ;;
    1)
        echo '若您无法使用fcitx,则请根据以下诊断信息自行解决'
        fcitx-diagnose
        ;;
    2) kde_config_module_for_fcitx ;;
    3) remove_ibus_im ;;
    4) input_method_config ;;
    5)
        FCITX_ENV_FILE="${HOME}/.xprofile"
        edit_fcitx_env_file
        ;;
    6)
        FCITX_ENV_FILE="${HOME}/.pam_environment"
        edit_fcitx_env_file
        ;;
    7)
        FCITX_ENV_FILE="/etc/environment"
        edit_fcitx_env_file
        ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_fcitx_faq
}
#################
edit_fcitx_env_file() {
    if [ $(command -v editor) ]; then
        editor ${FCITX_ENV_FILE}
    else
        nano ${FCITX_ENV_FILE}
    fi
    chown ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${FCITX_ENV_FILE}
}
###########
remove_ibus_im() {
    ${TMOE_REMOVAL_COMMAND} ibus
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        apt autoremove
    fi
}
##########
input_method_config() {
    cd ${HOME}
    if grep '^fcitx5' .xprofile; then
        sed -i 's@^fcitx5@#&@' .xprofile
        sed -i '1a\fcitx || fcitx5' .xprofile
    fi
    if ! grep '^fcitx' .xprofile; then
        sed -i '1a\fcitx || fcitx5' .xprofile
    fi
    #NON_DEBIAN='true'
    non_debian_function
    if [ ! $(command -v im-config) ]; then
        DEPENDENCY_01=''
        DEPENDENCY_02='im-config'
        beta_features_quick_install
    fi
    #检测两次
    if [ ! $(command -v im-config) ]; then
        echo 'Sorry，本功能只支持deb系发行版'
    fi
    im-config
    chmod 755 -R .config/fcitx .xprofile
    if [ ${HOME} != '/root' ]; then
        echo "正在将${HOME}/.config/fcitx和${HOME}/.xprofile的文件权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} .config/fcitx .xprofile
    fi
    fcitx &>/dev/null || fcitx5 &>/dev/null
    echo "请手动修改键盘布局，并打开fcitx-configtool"
}
####################
install_uim_pinyin() {
    DEPENDENCY_01='uim uim-mozc'
    DEPENDENCY_02='uim-pinyin'
    beta_features_quick_install
}
###########
install_fcitx_module_cloud_pinyin() {
    DEPENDENCY_01=''
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        DEPENDENCY_02='fcitx-module-cloudpinyin'
    else
        DEPENDENCY_02='fcitx-cloudpinyin'
    fi
    beta_features_quick_install
}
######################
install_rime_pinyin() {
    DEPENDENCY_02='fcitx-rime'
    beta_features_quick_install
}
#############
install_lib_pinyin() {
    DEPENDENCY_02='fcitx-libpinyin'
    beta_features_quick_install
}
######################
install_sun_pinyin() {
    DEPENDENCY_02='fcitx-sunpinyin'
    beta_features_quick_install
}
###########
install_google_pinyin() {
    DEPENDENCY_02='fcitx-googlepinyin'
    beta_features_quick_install
}
###########
install_debian_baidu_pinyin() {
    DEPENDENCY_02="fcitx-baidupinyin"
    if [ ! $(command -v unzip) ]; then
        ${TMOE_INSTALLATON_COMMAND} unzip
    fi
    ###################
    if [ "${ARCH_TYPE}" = "amd64" ]; then
        mkdir /tmp/.BAIDU_IME
        cd /tmp/.BAIDU_IME
        THE_Latest_Link='https://imeres.baidu.com/imeres/ime-res/guanwang/img/Ubuntu_Deepin-fcitx-baidupinyin-64.zip'
        echo ${THE_Latest_Link}
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'fcitx-baidupinyin.zip' "${THE_Latest_Link}"
        unzip 'fcitx-baidupinyin.zip'
        DEB_FILE_NAME="$(ls -l ./*deb | grep ^- | head -n 1 | awk -F ' ' '$0=$NF')"
        apt install ${DEB_FILE_NAME}
    else
        echo "架构不支持，跳过安装百度输入法。"
        arch_does_not_support
    fi
    apt show ./fcitx-baidupinyin.deb
    apt install -y ./fcitx-baidupinyin.deb
    echo "若安装失败，则请前往官网手动下载安装。"
    echo 'url: https://srf.baidu.com/site/guanwang_linux/index.html'
    cd /tmp
    rm -rfv /tmp/.BAIDU_IME
    beta_features_install_completed
}
########
install_pkg_warning() {
    echo "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_02} ${RESET}"
    echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_02} ${RESET}"
    press_enter_to_reinstall_yes_or_no
}
#############
install_baidu_pinyin() {
    DEPENDENCY_02="fcitx-baidupinyin"
    if [ -e "/opt/apps/com.baidu.fcitx-baidupinyin/" ]; then
        install_pkg_warning
    fi

    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02="fcitx-baidupinyin"
        beta_features_quick_install
    elif [ "${LINUX_DISTRO}" = "debian" ]; then
        install_debian_baidu_pinyin
    else
        non_debian_function
    fi
}
##########
#已废弃！
sougou_pinyin_amd64() {
    if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "i386" ]; then
        LatestSogouPinyinLink=$(curl -L 'https://pinyin.sogou.com/linux' | grep ${ARCH_TYPE} | grep 'deb' | head -n 1 | cut -d '=' -f 3 | cut -d '?' -f 1 | cut -d '"' -f 2)
        echo ${LatestSogouPinyinLink}
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'sogou_pinyin.deb' "${LatestSogouPinyinLink}"
    else
        echo "架构不支持，跳过安装搜狗输入法。"
        arch_does_not_support
    fi
}
###################
install_debian_sogou_pinyin() {
    #DEPENDENCY_02="sogouimebs"
    DEPENDENCY_02='sogoupinyin'
    ###################
    if [ -e "/usr/share/fcitx-sogoupinyin" ] || [ -e "/usr/share/sogouimebs/" ]; then
        install_pkg_warning
    fi
    case "${ARCH_TYPE}" in
    amd64 | i386)
        echo "本脚本提供的是搜狗官网的版本"
        echo "Debian sid、Kali rolling和ubuntu 20.04等高版本可能无法正常运行,您可以前往优麒麟软件仓库手动下载安装。"
        echo 'http://archive.ubuntukylin.com/ukui/pool/main/s/sogouimebs/'
        do_you_want_to_continue
        LATEST_DEB_URL=$(curl -L 'https://pinyin.sogou.com/linux/' | grep ${ARCH_TYPE} | grep deb | awk '{print $3}' | cut -d '"' -f 2)
        LATEST_DEB_VERSION="sogouimebs_${ARCH_TYPE}.deb"
        install_deb_file_common_model_02
        ;;
    arm64) echo "请手动前往优麒麟软件仓库手动下载安装arm64版sogouimebs" ;;
    esac
    echo "若安装失败，则请前往官网手动下载安装。"
    echo "url: ${YELLOW}https://pinyin.sogou.com/linux/${RESET}"
    beta_features_install_completed
}
########
install_sogou_pinyin() {
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02="fcitx-sogouimebs"
        beta_features_quick_install
    elif [ "${LINUX_DISTRO}" = "debian" ]; then
        install_debian_sogou_pinyin
    else
        non_debian_function
    fi
}
############
fcitx5_config_file() {
    if [ ! -e "${FCITX5_FILE}" ]; then
        echo '' >>${FCITX5_FILE}
    fi
    if ! grep -q '^export GTK_IM_MODULE=fcitx5' ${FCITX5_FILE}; then
        sed -i 's/^export INPUT_METHOD.*/#&/' ${FCITX5_FILE}
        sed -i 's/^export GTK_IM_MODULE.*/#&/' ${FCITX5_FILE}
        sed -i 's/^export QT_IM_MODULE=.*/#&/' ${FCITX5_FILE}
        sed -i 's/^export XMODIFIERS=.*/#&/' ${FCITX5_FILE}
        cat >>${FCITX5_FILE} <<-'EOF'
			export INPUT_METHOD=fcitx5
			export GTK_IM_MODULE=fcitx5
			export QT_IM_MODULE=fcitx5
			export XMODIFIERS="@im=fcitx5"
		EOF
    fi
}
############
fix_fcitx5_permissions() {
    if [ ${HOME} != '/root' ]; then
        echo "正在将${FCITX5_FILE}的文件权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${FCITX5_FILE}
    fi
}
############
configure_system_fcitx5() {
    FCITX5_FILE="${HOME}/.xprofile"
    cd ${HOME}
    fcitx5_config_file
    if ! grep -q '^fcitx5' .xprofile; then
        sed -i 's@^fcitx@#&@g' .xprofile
        sed -i '1a\fcitx5 || fcitx' .xprofile
    fi
    fix_fcitx5_permissions
    FCITX5_FILE='/etc/environment'
    fcitx5_config_file
    FCITX5_FILE="${HOME}/.pam_environment"
    fcitx5_config_file
    fix_fcitx5_permissions
}
##############
configure_arch_fcitx() {
    if [ ! -e "${HOME}/.xprofile" ]; then
        echo '' >${HOME}/.xprofile
    fi
    if grep -q '^export GTK_IM_MODULE=fcitx5' ${HOME}/.xprofile; then
        sed -i 's/^export GTK_IM_MODULE.*/#&/' ${HOME}/.xprofile ${HOME}/.pam_environment
        sed -i 's/^export QT_IM_MODULE=.*/#&/' ${HOME}/.xprofile ${HOME}/.pam_environment
        sed -i 's/^export XMODIFIERS=.*/#&/' ${HOME}/.xprofile ${HOME}/.pam_environment
    fi

    if ! grep -q '^export GTK_IM_MODULE=fcitx' ${HOME}/.xprofile; then
        sed -i 's/^export GTK_IM_MODULE.*/#&/' ${HOME}/.xprofile
        sed -i 's/^export QT_IM_MODULE=.*/#&/' ${HOME}/.xprofile
        sed -i 's/^export XMODIFIERS=.*/#&/' ${HOME}/.xprofile
        cat >>${HOME}/.xprofile <<-'EOF'
			export GTK_IM_MODULE=fcitx
			export QT_IM_MODULE=fcitx
			export XMODIFIERS="@im=fcitx"
		EOF
        #sort -u ${HOME}/.xprofile -o ${HOME}/.xprofile
    fi
    if ! grep -q '^export GTK_IM_MODULE=fcitx' /etc/environment; then
        sed -i 's/^export INPUT_METHOD.*/#&/' /etc/environment
        sed -i 's/^export GTK_IM_MODULE.*/#&/' /etc/environment
        sed -i 's/^export QT_IM_MODULE=.*/#&/' /etc/environment
        sed -i 's/^export XMODIFIERS=.*/#&/' /etc/environment
        cat >>/etc/environment <<-'EOF'
			export INPUT_METHOD=fcitx
			export GTK_IM_MODULE=fcitx
			export QT_IM_MODULE=fcitx
			export XMODIFIERS="@im=fcitx"
		EOF
        #sort -u /etc/environment -o /etc/environment
    fi
}
##############
install_debian_iflyime_pinyin() {
    DEPENDENCY_02="iflyime"
    beta_features_quick_install
    case "${ARCH_TYPE}" in
    amd64)
        REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/non-free/i/iflyime/'
        GREP_NAME="${ARCH_TYPE}"
        grep_deb_comman_model_01
        ;;
    *)
        echo "请在更换x64架构的设备后，再来尝试"
        arch_does_not_support
        ;;
    esac
}
#############
install_iflyime_pinyin() {
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02="iflyime"
        beta_features_quick_install
    elif [ "${LINUX_DISTRO}" = "debian" ]; then
        install_debian_iflyime_pinyin
    else
        non_debian_function
    fi
}
################
####################
install_pinyin_input_method
