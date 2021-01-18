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
wine_dependencies() {
    DEPENDENCY_01='wine winetricks q4wine'
    DEPENDENCY_02='playonlinux wine32'
    case "${LINUX_DISTRO}" in
    "debian")
        case "${DEBIAN_DISTRO}" in
        "ubuntu") DEPENDENCY_01='wine winetricks q4wine' ;;
        esac
        if [ "${INSTALL_WINE}" = "true" ]; then
            dpkg --add-architecture i386
            apt update
            apt install winetricks-zh wine64
        else
            apt purge winetricks-zh
        fi
        ;;
    "arch")
        DEPENDENCY_01='winetricks-zh'
        DEPENDENCY_02='playonlinux5-git q4wine'
        ;;
    esac
}
##########
install_wine64() {
    INSTALL_WINE='true'
    wine_dependencies
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
wine_menu() {
    RETURN_TO_WHERE='wine_menu'

    VIRTUAL_TECH=$(
        whiptail --title "WINE" --menu "Wine is not an emulator" 0 50 0 \
            "1" "install安装" \
            "2" "remove卸载" \
            "3" "wine-dxvk(将DirectX转换为Vulkan api)" \
            "4" "wine-wechat微信" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    #############
    case ${VIRTUAL_TECH} in
    0 | "") install_container_and_virtual_machine ;;
    1) install_wine64 ;;
    2) remove_wine_bin ;;
    3) install_dxvk ;;
    4) install_wine_wechat ;;
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
        printf '%s\n' 'dpkg  --remove-architecture i386'
        printf '%s\n' '正在移除对i386软件包的支持'
        #apt purge ".*:i386"
        aptitude remove ~i~ri386
        dpkg --remove-architecture i386
        apt update
        ;;
    esac
    INSTALL_WINE='false'
    wine_dependencies
    printf "%s\n" "${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}"
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
}
############
install_wine_wechat() {
    cat <<-'EOF'
		微信安装包将下载/tmp目录
		若安装失败，请手动执行wine /tmp/WeChatSetup.exe
		https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe
		建议您在安装完成后执行winecfg,并选择“函数库”.接着添加riched20，最后选择"原装先于内建"。
	EOF
    cd /tmp
    if [ ! -e "WeChatSetup.exe" ]; then
        aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o WeChatSetup.exe 'https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe'
    fi
    sudo -iu master wine /tmp/WeChatSetup.exe
    sudo -iu ${CURRENT_USER_NAME} winetricks riched20
    sudo -iu ${CURRENT_USER_NAME} winecfg
}
################
wine_menu
