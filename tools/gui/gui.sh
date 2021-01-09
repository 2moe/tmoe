#!/usr/bin/env bash
############################################
gui_main() {
    case "$1" in
    --install-gui | install-gui)
        install_gui
        ;;
    -b)
        tmoe_desktop_beautification
        ;;
    -c)
        modify_remote_desktop_config
        ;;
    -x)
        modify_xsdl_conf
        ;;
    --vncpasswd) set_vnc_passwd ;;
    --fix-dbus) fix_vnc_dbus_launch ;;
    *)
        install_gui
        ;;
    esac
}
#############################
modify_other_vnc_conf() {
    #15 60 7
    MODIFYOTHERVNCCONF=$(whiptail --title "Modify vnc server conf" --menu "Type startvnc to start vncserver,输入startvnc启动vnc服务" 0 0 0 \
        "1" "Pulseaudio server address音频地址" \
        "2" "VNC password密码" \
        "3" "switch tiger/tightvnc切换服务端" \
        "4" "Edit xsession 编辑xsession" \
        "5" "Edit startvnc 编辑vnc启动脚本" \
        "6" "Edit tigervnc-config 编辑tigervnc配置" \
        "7" "fix vnc crash修复VNC闪退" \
        "8" "window scaling factor调整屏幕缩放比例(仅支持xfce)" \
        "9" "display port显示端口" \
        "10" "WSL pulseaudio(only for windows)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ###########
    case "${MODIFYOTHERVNCCONF}" in
    0 | "") modify_remote_desktop_config ;;
    1) modify_vnc_pulse_audio ;;
    2) set_vnc_passwd ;;
    3) switch_tight_or_tiger_vncserver ;;
    4)
        nano ${XSESSION_FILE}
        stopvnc 2>/dev/null
        ;;
    5) nano_startvnc_manually ;;
    6) nano_tigervnc_default_config_manually ;;
    7) fix_vnc_dbus_launch ;;
    8) modify_xfce_window_scaling_factor ;;
    9) modify_tightvnc_display_port ;;
    10) nano ${TMOE_LINUX_DIR}/wsl_pulse_audio ;;
    esac
    #########
    press_enter_to_return
    modify_other_vnc_conf
    ##########
}
##############
nano_tigervnc_default_config_manually() {
    nano /etc/tigervnc/vncserver-config-defaults
}
#############
switch_tight_or_tiger_vncserver() {
    DEPENDENCY_01=''
    #NON_DEBIAN='true'
    non_debian_function
    #优先检测tiger
    if [ $(command -v Xtigervnc) ]; then
        tight_vnc_variable
    elif [ $(command -v Xtightvnc) ]; then
        tiger_vnc_variable
        #检测到tight,询问是否需要切换为tiger
    fi
    VNC_SERVER_BIN_STATUS="检测到您当前使用的是${VNC_SERVER_BIN_NOW}"
    if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Back返回" --no-button "${VNC_SERVER_BIN}" --yesno "${VNC_SERVER_BIN_STATUS}\n请问您是否需要切换为${VNC_SERVER_BIN}♪(^∇^*)\nDo you want to switch to ${VNC_SERVER_BIN}?" 0 0); then
        modify_other_vnc_conf
    else
        non_debian_function
        #printf "%s\n" "${RED}apt remove -y ${VNC_SERVER_BIN_NOW}${RESET}"
        #apt remove -y ${VNC_SERVER_BIN_NOW}
        #beta_features_quick_install
        apt update
        case_debian_distro_and_install_vnc
    fi
}
#################
check_tightvnc_port() {
    CURRENT_PORT=$(grep 'TMOE_VNC_DISPLAY_NUMBER=' $(command -v startvnc) | head -n 1 | awk 'BEGIN{FS="="} {print $2}' | cut -d '"' -f 2)
    CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
}
#########################
modify_tightvnc_display_port() {
    check_tightvnc_port
    TARGET=$(whiptail --inputbox "默认显示编号为1,当前为${CURRENT_PORT}\nVNC服务以5900端口为起始,若显示编号为1,则端口为5901，请输入显示编号.Please type the display number." 13 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        modify_other_vnc_conf
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        sed -i "s@tmoe-linux.*:.*@tmoe-linux :${TARGET}@" "$(command -v startvnc)"
        sed -i "s@TMOE_VNC_DISPLAY_NUMBER=.*@TMOE_VNC_DISPLAY_NUMBER=${TARGET}@" "$(command -v startvnc)"
        printf '%s\n' 'Your current VNC port has been modified.'
        check_tightvnc_port
        printf "%s\n" "Current display number is ${BLUE}${CURRENT_PORT}${RESET}"
        printf '%s\n' '您当前的VNC端口已修改为'
        printf "%s\n" "${CURRENT_VNC_PORT}"
    fi
}
######################
modify_xfce_window_scaling_factor() {
    XFCE_CONFIG_FILE="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
    if grep 'WindowScalingFactor' ${XFCE_CONFIG_FILE}; then
        CURRENT_VALUE=$(grep 'WindowScalingFactor' ${XFCE_CONFIG_FILE} | grep 'value=' | awk '{print $4}' | cut -d '"' -f 2)
    else
        CURRENT_VALUE='1'
    fi
    TARGET=$(whiptail --inputbox "请输入您需要缩放的比例大小(纯数字)，当前仅支持整数倍，例如1和2，不支持1.5,当前为${CURRENT_VALUE}" 10 50 --title "Window Scaling Factor" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        modify_other_vnc_conf
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
        printf '%s\n' '检测到您取消了操作'
        grep 'WindowScalingFactor' ${XFCE_CONFIG_FILE} | grep 'value='
    else
        dbus-launch xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s ${TARGET} || dbus-launch xfconf-query -t int -c xsettings -np /Gdk/WindowScalingFactor -s ${TARGET}
        if ((${TARGET} > 1)); then
            if grep -q 'Focal Fossa' "/etc/os-release"; then
                dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Kali-Light-xHiDPI 2>/dev/null
            else
                dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Default-xhdpi 2>/dev/null
            fi
        fi
        printf "%s\n" "修改完成，请输${GREEN}startvnc${RESET}重启进程"
    fi
}
##################
modify_vnc_pulse_audio() {
    TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。linux默认为127.0.0.1,WSL2默认为宿主机ip,当前为$(grep 'PULSE_SERVER=' $(command -v startvnc) | cut -d '=' -f 2 | head -n 1) \n本功能适用于局域网传输，本机操作无需任何修改。若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：您需要手动启动音频服务端,Android-Termux需输pulseaudio --start,win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat' \n至于其它第三方app,例如安卓XSDL,若其显示的PULSE_SERVER地址为192.168.1.3:4713,那么您需要输入192.168.1.3:4713" 20 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        modify_other_vnc_conf
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        #sed -i '/PULSE_SERVER/d' ~/.vnc/xstartup
        #sed -i "2 a\export PULSE_SERVER=${TARGET}" ~/.vnc/xstartup
        if grep '^export.*PULSE_SERVER' "$(command -v startvnc)"; then
            sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=${TARGET}@" $(command -v startvnc)
        else
            sed -i "4 a\export PULSE_SERVER=${TARGET}" $(command -v startvnc)
        fi
        printf '%s\n' 'Your current PULSEAUDIO SERVER address has been modified.'
        printf '%s\n' '您当前的音频地址已修改为'
        printf "%s\n" "$(grep 'PULSE_SERVER' $(command -v startvnc) | cut -d '=' -f 2 | head -n 1)"
        printf "%s\n" "请输startvnc重启vnc服务，以使配置生效"
    fi
}
##################
nano_startvnc_manually() {
    printf '%s\n' '您可以手动修改vnc的配置信息'
    printf '%s\n' 'If you want to modify the resolution, please change the 1440x720 (default resolution，landscape) to another resolution, such as 1920x1080 (vertical screen).'
    printf '%s\n' '若您想要修改分辨率，请将默认的1440x720（横屏）改为其它您想要的分辨率，例如720x1440（竖屏）。'
    printf "%s\n" "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1 | tail -n 1)"
    printf '%s\n' '改完后按Ctrl+S保存，Ctrl+X退出。'
    RETURN_TO_WHERE='modify_other_vnc_conf'
    do_you_want_to_continue
    nano /usr/local/bin/startvnc || nano $(command -v startvnc)
    printf "%s\n" "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1 | tail -n 1)"

    stopvnc 2>/dev/null
    press_enter_to_return
    modify_other_vnc_conf
}
#############################################
catimg_preview_lxde_mate_xfce_01() {
    printf '%s\n' 'lxde预览截图'
    #curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png' | catimg -
    if [ ! -f 'LXDE_BUSYeSLZRqq3i3oM.png' ]; then
        curl -Lo 'LXDE_BUSYeSLZRqq3i3oM.png' ${LXDE_ICON_URL}
    fi
    catimg 'LXDE_BUSYeSLZRqq3i3oM.png'

    printf '%s\n' 'mate预览截图'
    #curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/1frRp1lpOXLPz6mO.jpg' | catimg -
    if [ ! -f 'MATE_1frRp1lpOXLPz6mO.jpg' ]; then
        curl -sLo 'MATE_1frRp1lpOXLPz6mO.jpg' ${MATE_ICON_URL}
    fi
    catimg 'MATE_1frRp1lpOXLPz6mO.jpg'
    printf '%s\n' 'xfce预览截图'
}
catimg_preview_lxde_mate_xfce_02() {
    if [ ! -f 'XFCE_a7IQ9NnfgPckuqRt.jpg' ]; then
        curl -sLo 'XFCE_a7IQ9NnfgPckuqRt.jpg' ${XFCE_ICON_URL}
    fi
    catimg 'XFCE_a7IQ9NnfgPckuqRt.jpg' 2>/dev/null
    if [ "${WINDOWS_DISTRO}" = 'WSL' ]; then
        if [ ! -e "/mnt/c/Users/Public/Downloads/VcXsrv/XFCE_a7IQ9NnfgPckuqRt.jpg" ]; then
            cp -f 'XFCE_a7IQ9NnfgPckuqRt.jpg' "/mnt/c/Users/Public/Downloads/VcXsrv"
        fi
        cd "/mnt/c/Users/Public/Downloads/VcXsrv"
        /mnt/c/WINDOWS/system32/cmd.exe /c "start .\XFCE_a7IQ9NnfgPckuqRt.jpg" 2>/dev/null
    fi
}
install_gui() {
    IOSEVKA_TTF_FILE="/usr/share/fonts/truetype/iosevka/Iosevka.ttf"
    [[ "${WINDOWS_DISTRO}" != 'WSL' ]] || source ${TMOE_TOOL_DIR}/gui/wsl
    [[ ! -s "${IOSEVKA_TTF_FILE}" ]] || standand_desktop_installation #该字体检测两次
    check_zstd
    random_neko
    cd /tmp
    case ${WINDOWS_DISTRO} in
    WSL)
        LXDE_ICON_URL='https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png'
        MATE_ICON_URL='https://gitee.com/mo2/pic_api/raw/test/2020/03/15/1frRp1lpOXLPz6mO.jpg'
        XFCE_ICON_URL='https://gitee.com/mo2/pic_api/raw/test/2020/03/15/a7IQ9NnfgPckuqRt.jpg'
        ;;
    *)
        LXDE_ICON_URL='https://gitee.com/ak2/icons/raw/master/raspbian-lxde.jpg'
        MATE_ICON_URL='https://gitee.com/ak2/icons/raw/master/ubuntu-mate.jpg'
        XFCE_ICON_URL='https://gitee.com/ak2/icons/raw/master/debian-xfce.jpg'
        ;;
    esac
    if [ $(command -v catimg) ]; then
        catimg_preview_lxde_mate_xfce_01
        catimg_preview_lxde_mate_xfce_02
    elif [[ ${WINDOWS_DISTRO} = 'WSL' ]]; then
        catimg_preview_lxde_mate_xfce_02
    fi
    if [ ! -f "${IOSEVKA_TTF_FILE}" ]; then
        printf "${BLUE}%s${RESET}\n" "${IOSEVKA_TTF_FILE}"
        printf "${YELLOW}%s${RESET}\n" '正在刷新字体缓存...'
        mkdir -pv /usr/share/fonts/truetype/iosevka/
        cd /tmp
        if [ -e "font.ttf" ]; then
            mv -f font.ttf "${IOSEVKA_TTF_FILE}"
        else
            curl -Lo 'Iosevka.tar.xz' "https://gitee.com/ak2/iosevka-bold/raw/master/Iosevka.tar.xz"
            tar -Jxvf 'Iosevka.tar.xz'
            rm -f 'Iosevka.tar.xz'
            mv -f Iosevka.ttf "${IOSEVKA_TTF_FILE}"
        fi
        cd /usr/share/fonts/truetype/iosevka/
        mkfontscale 2>/dev/null
        mkfontdir 2>/dev/null
        fc-cache 2>/dev/null
    fi
    #curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/a7IQ9NnfgPckuqRt.jpg' | catimg -
    #printf "%s\n" "建议缩小屏幕字体，并重新加载图片，以获得更优的显示效果。"
    printf "%s\n" "按${GREEN}回车键${RESET}${RED}选择${RESET}您需要${YELLOW}安装${RESET}的${BLUE}图形桌面环境${RESET}"
    RETURN_TO_WHERE="tmoe_linux_tool_menu"
    do_you_want_to_continue
    standand_desktop_installation
}
########################
preconfigure_gui_dependecies_02() {
    unset AUTO_INSTALL_FCITX4
    unset AUTO_INSTALL_KALI_TOOLS
    unset AUTO_INSTALL_ELECTRON_APPS
    unset UBUNTU_DESKTOP
    DEPENDENCY_02="tigervnc"
    case "${LINUX_DISTRO}" in
    debian)
        case "${TMOE_PROOT}" in
        true | no) NON_DBUS='true' ;;
        esac
        #if egrep -q 'Focal Fossa|focal|Eoan Ermine' "/etc/os-release"; then
        #    DEPENDENCY_02="dbus-x11 fonts-noto-cjk tightvncserver"
        #else
        DEPENDENCY_02="dbus-x11 fonts-noto-cjk"
        #fi
        #if grep -q '^PRETTY_NAME.*sid' "/etc/os-release"; then
        #	DEPENDENCY_02="${DEPENDENCY_02} tigervnc-standalone-server"
        #else
        #	DEPENDENCY_02="${DEPENDENCY_02} tightvncserver"
        #fi
        #上面的依赖摆放的位置是有讲究的。
        ;;
    redhat)
        case "${TMOE_PROOT}" in
        true | no) NON_DBUS='true' ;;
        esac
        DEPENDENCY_02="google-noto-sans-cjk-ttc-fonts google-noto-emoji-color-fonts tigervnc-server"
        ;;
    arch)
        DEPENDENCY_02="tigervnc"
        if [ ! -e "/usr/share/fonts/noto-cjk" ]; then
            DEPENDENCY_02="noto-fonts-cjk ${DEPENDENCY_02}"
        fi
        if [ ! -e "/usr/share/fonts/noto/NotoColorEmoji.ttf" ]; then
            DEPENDENCY_02="noto-fonts-emoji ${DEPENDENCY_02}"
        fi
        ;;
    void) DEPENDENCY_02="xorg tigervnc wqy-microhei" ;;
    gentoo)
        dispatch-conf
        etc-update
        DEPENDENCY_02="media-fonts/wqy-bitmapfont net-misc/tigervnc"
        ;;
    suse) DEPENDENCY_02="tigervnc-x11vnc noto-sans-sc-fonts perl-base" ;;
    alpine)
        DEPENDENCY_02="xvfb dbus-x11 font-noto-cjk x11vnc"
        #ca-certificates openssl
        ;;
    esac
}
########################
standand_desktop_installation() {
    NON_DBUS='false'
    REMOVE_UDISK2='false'
    RETURN_TO_WHERE='standand_desktop_installation'
    preconfigure_gui_dependecies_02
    standand_desktop_installation_zh() {
        INSTALLDESKTOP=$(whiptail --title "GUI" --menu \
            "Desktop environment(简称DE)是一种多功能和多样化的图形界面。\n若您使用的是容器，则只需选择第一或者第三项。\nIf you are using a container,then choose proot_DE or WM.\n若您使用的是虚拟机，则可以任意挑选项目。" 0 0 0 \
            "1" "🍰 proot_DE(proot容器可运行:xfce,mate,lxde)" \
            "2" "🍔 chroot/docker_DE(kde,dde)" \
            "3" "🍙 window manager窗口管理器(ice,fvwm)" \
            "4" "🍱 VM_DE(虚拟机/systemd容器可运行:gnome,cinnamon)" \
            "5" "🍣 display manager显示/登录管理器:lightdm,sddm" \
            "6" "🍤 FAQ:vnc和gui的常见问题" \
            "0" "🌚 none我一个都不要 =￣ω￣=" \
            3>&1 1>&2 2>&3)
    }
    standand_desktop_installation_en() {
        INSTALLDESKTOP=$(whiptail --title "GUI" --menu \
            "If you are using a container,then choose proot_DE or WM.\nIf you are using a virtual machine,you can choose any one" 0 0 0 \
            "1" "🍰 proot_DE(xfce,mate,lxde)" \
            "2" "🍔 chroot/docker_DE(kde,dde)" \
            "3" "🍙 window manager(ice,fvwm)" \
            "4" "🍱 VM/nspawn_DE(gnome,cinnamon,budgie)" \
            "5" "🍣 display manager(lightdm,sddm)" \
            "6" "🍤 FAQ" \
            "0" "🌚 none=￣ω￣=" \
            3>&1 1>&2 2>&3)
    }
    case ${TMOE_MENU_LANG} in
    zh_*UTF-8) standand_desktop_installation_zh ;;
    *) standand_desktop_installation_en ;;
    esac
    ##########################
    case "${INSTALLDESKTOP}" in
    0 | "") tmoe_linux_tool_menu ;;
    1) tmoe_container_desktop ;;
    2) tmoe_docker_and_chroot_container_desktop ;;
    3) window_manager_install ;;
    4) tmoe_virtual_machine_desktop ;;
    5) tmoe_display_manager_install ;;
    6) tmoe_desktop_faq ;;
    esac
    ##########################
    press_enter_to_return
    standand_desktop_installation
}
#######################
tmoe_desktop_faq() {
    source ${TMOE_TOOL_DIR}/gui/faq.sh
}
######################
tmoe_docker_and_chroot_container_desktop() {
    INSTALLDESKTOP=$(whiptail --title "Desktop environment" --menu \
        "您可以在docker或chroot容器中运行这些桌面\nYou can run these DEs on docker or chroot container." 0 0 0 \
        "1" "🦖 kde plasma5(风格华丽的桌面环境)" \
        "2" "dde(深度deepin桌面,崭新视界,创无止境)" \
        "3" "ukui(优麒麟ukui桌面,简繁取易,温润灵性)" \
        "0" "🌚 none我一个都不要 =￣ω￣=" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${INSTALLDESKTOP}" in
    0 | "") standand_desktop_installation ;;
    1) install_kde_plasma5_desktop ;;
    2) install_deepin_desktop ;;
    3) install_ukui_desktop ;;
    esac
    ##########################
    press_enter_to_return
    standand_desktop_installation
}
####################
tmoe_container_desktop() {
    tmoe_container_desktop_zh() {
        INSTALLDESKTOP=$(whiptail --title "Desktop environment" --menu \
            "您想要安装哪个桌面环境?\n仅GTK+环境(如xfce和gnome3等)支持在本工具内便捷下载主题。\nWhich desktop environment do you want to install? " 0 0 0 \
            "1" "🐭 xfce(兼容性高,简单优雅)" \
            "2" "🐦 lxqt(lxde原团队基于QT开发的桌面)" \
            "3" "🕊️ lxde(轻量化桌面,资源占用低)" \
            "4" "🌿 mate(GNOME2的延续,让用户体验更舒适的环境)" \
            "0" "🌚 none我一个都不要 =￣ω￣=" \
            3>&1 1>&2 2>&3)
    }
    tmoe_container_desktop_en() {
        INSTALLDESKTOP=$(whiptail --title "Desktop environment" --menu \
            "Which desktop environment do you want to install? " 0 0 0 \
            "1" "🐭 xfce(elegant, high compatibility)" \
            "2" "🐦 lxqt" \
            "3" "🕊️ lxde(lightweight)" \
            "4" "🌿 mate(the continuation of GNOME 2)" \
            "0" "🌚 none =￣ω￣=" \
            3>&1 1>&2 2>&3)
    }
    case ${TMOE_MENU_LANG} in
    zh_*UTF-8) tmoe_container_desktop_zh ;;
    *) tmoe_container_desktop_en ;;
    esac
    ##########################
    case "${INSTALLDESKTOP}" in
    0 | "") standand_desktop_installation ;;
    1)
        REMOVE_UDISK2='true'
        install_xfce4_desktop
        ;;
    2)
        REMOVE_UDISK2='true'
        install_lxqt_desktop
        ;;
    3)
        REMOVE_UDISK2='true'
        install_lxde_desktop
        ;;
    4) install_mate_desktop ;;
    esac
    ##########################
    press_enter_to_return
    standand_desktop_installation
}
####################
tmoe_display_manager_install() {
    DEPENDENCY_01=''
    RETURN_TO_WHERE='tmoe_display_manager_install'
    INSTALLDESKTOP=$(whiptail --title "单项选择题" --menu \
        "显示管理器(简称DM)是一个在启动最后显示的图形界面,负责管理登录会话。\n Which display manager do you want to install? " 17 50 6 \
        "1" "lightdm:支持跨桌面,可以使用各种前端写的工具" \
        "2" "sddm:现代化DM,替代KDE4的KDM" \
        "3" "gdm:GNOME默认DM" \
        "4" "slim:Lightweight轻量" \
        "5" "lxdm:LXDE默认DM(独立于桌面环境)" \
        "0" "Back to the main menu 返回主菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${INSTALLDESKTOP}" in
    0 | "") tmoe_linux_tool_menu ;;
    1)
        if [ "${LINUX_DISTRO}" = "alpine" ]; then
            setup-xorg-base
            DEPENDENCY_01='lightdm-gtk-greeter xf86-input-mouse xf86-input-keyboard polkit consolekit2'
        else
            DEPENDENCY_01='ukui-greeter lightdm-gtk-greeter-settings'
        fi

        DEPENDENCY_02='lightdm'
        ;;
    2)
        DEPENDENCY_01='sddm-theme-breeze'
        DEPENDENCY_02='sddm'
        ;;
    3)
        DEPENDENCY_01='gdm'
        DEPENDENCY_02='gdm3'
        ;;
    4) DEPENDENCY_02='slim' ;;
    5) DEPENDENCY_02='lxdm' ;;
    esac
    ##########################
    tmoe_display_manager_systemctl
}
##################
tmoe_display_manager_systemctl() {
    RETURN_TO_WHERE='tmoe_display_manager_systemctl'
    if [ "${DEPENDENCY_02}" = 'gdm3' ]; then
        TMOE_DEPENDENCY_SYSTEMCTL='gdm'
    else
        TMOE_DEPENDENCY_SYSTEMCTL="${DEPENDENCY_02}"
    fi
    INSTALLDESKTOP=$(whiptail --title "你想要对这个小可爱做什么？" --menu \
        "显示管理器软件包基础配置" 0 50 0 \
        "1" "install/remove 安装/卸载" \
        "2" "start启动" \
        "3" "stop停止" \
        "4" "systemctl enable开机自启" \
        "5" "systemctl disable禁用自启" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${INSTALLDESKTOP}" in
    0 | "") standand_desktop_installation ;;
    1)
        beta_features_quick_install
        ;;
    2)
        printf "%s\n" "您可以输${GREEN}systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}或${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} start${RESET}来启动"
        printf "%s\n" "${GREEN}systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
        printf "%s\n" "按回车键启动"
        do_you_want_to_continue
        systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL} || service ${TMOE_DEPENDENCY_SYSTEMCTL} restart
        ;;
    3)
        printf "%s\n" "您可以输${GREEN}systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}或${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} stop${RESET}来停止"
        printf "%s\n" "${GREEN}systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
        printf "%s\n" "按回车键停止"
        do_you_want_to_continue
        systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL} || service ${TMOE_DEPENDENCY_SYSTEMCTL} stop
        ;;
    4)
        printf "%s\n" "您可以输${GREEN}rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}或${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}来添加开机自启任务"
        printf "%s\n" "${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
        systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}
        if [ "$?" = "0" ]; then
            printf "%s\n" "已添加至自启任务"
        else
            printf "%s\n" "添加自启任务失败"
        fi
        ;;
    5)
        printf "%s\n" "您可以输${GREEN}rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}或${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}来禁止开机自启"
        printf "%s\n" "${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
        systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}
        if [ "$?" = "0" ]; then
            printf "%s\n" "已禁用开机自启"
        else
            printf "%s\n" "禁用自启任务失败"
        fi
        ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_display_manager_systemctl
}
#######################
auto_select_keyboard_layout() {
    printf '%s\n' 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
    printf "%s\n" "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
    echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
}
#################
will_be_installed_for_you() {
    printf "%s\n" "即将为您安装思源黑体(中文字体)、${REMOTE_DESKTOP_SESSION_01}、tightvncserver等软件包"
}
########################
window_manager_install() {
    #NON_DBUS='true'
    REMOTE_DESKTOP_SESSION_02='x-window-manager'
    BETA_DESKTOP=$(
        whiptail --title "WINDOW MANAGER" --menu \
            "Window manager窗口管理器(简称WM)\n是一种比桌面环境更轻量化的图形界面.\n您想要安装哪个WM呢?您可以同时安装多个\nWhich WM do you want to install?" 0 0 0 \
            "0" "Return to previous menu 返回上级菜单" \
            "1" "ice(意在提升感观和体验,兼顾轻量和可定制性)" \
            "2" "openbox(快速,轻巧,可扩展)" \
            "3" "fvwm(强大的、与ICCCM2兼容的WM)" \
            "4" "awesome(平铺式WM)" \
            "5" "enlightenment(X11 WM based on EFL)" \
            "6" "fluxbox(高度可配置,低资源占用)" \
            "7" "i3(改进的动态平铺WM)" \
            "8" "xmonad(基于Haskell开发的平铺式WM)" \
            "9" "9wm(X11 WM inspired by Plan 9's rio)" \
            "10" "metacity(轻量的GTK+ WM)" \
            "11" "twm(Tab WM)" \
            "12" "aewm(极简主义WM for X11)" \
            "13" "aewm++(最小的 WM written in C++)" \
            "14" "afterstep(拥有NEXTSTEP风格的WM)" \
            "15" "blackbox(WM for X)" \
            "16" "dwm(dynamic window manager)" \
            "17" "mutter(轻量的GTK+ WM)" \
            "18" "bspwm(Binary space partitioning WM)" \
            "19" "clfswm(Another Common Lisp FullScreen WM)" \
            "20" "ctwm(Claude's Tab WM)" \
            "21" "evilwm(极简主义WM for X11)" \
            "22" "flwm(Fast Light WM)" \
            "23" "herbstluftwm(manual tiling WM for X11)" \
            "24" "jwm(very small & pure轻量,纯净)" \
            "25" "kwin-x11(KDE默认WM,X11 version)" \
            "26" "lwm(轻量化WM)" \
            "27" "marco(轻量化GTK+ WM for MATE)" \
            "28" "matchbox-window-manager(低配机福音)" \
            "29" "miwm(极简主义WM with virtual workspaces)" \
            "30" "muffin(轻量化window and compositing manager)" \
            "31" "mwm(Motif WM)" \
            "32" "oroborus(a 轻量化 themeable WM)" \
            "33" "pekwm(very light)" \
            "34" "ratpoison(keyboard-only WM)" \
            "35" "sapphire(a 最小的 but configurable X11R6 WM)" \
            "36" "sawfish" \
            "37" "spectrwm(dynamic tiling WM)" \
            "38" "stumpwm(tiling,keyboard driven Common Lisp)" \
            "39" "subtle(grid-based manual tiling)" \
            "40" "sugar-session(Sugar Learning Platform)" \
            "41" "tinywm" \
            "42" "ukwm(轻量化 GTK+ WM)" \
            "43" "vdesk(manages virtual desktops for 最小的WM)" \
            "44" "vtwm(Virtual Tab WM)" \
            "45" "w9wm(enhanced WM based on 9wm)" \
            "46" "wm2(small,unconfigurable)" \
            "47" "wmaker(NeXTSTEP-like WM for X)" \
            "48" "wmii(轻量化 tabbed and tiled WM)" \
            "49" "xfwm4(xfce4默认WM)" \
            3>&1 1>&2 2>&3
    )
    ##################
    case "${BETA_DESKTOP}" in
    0 | "") standand_desktop_installation ;;
    1)
        DEPENDENCY_01='icewm'
        REMOTE_DESKTOP_SESSION_01='icewm-session'
        REMOTE_DESKTOP_SESSION_02='icewm'
        ;;
    2)
        DEPENDENCY_01='openbox'
        REMOTE_DESKTOP_SESSION_01='openbox-session'
        REMOTE_DESKTOP_SESSION_02='openbox'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='openbox openbox-menu' ;;
        esac
        ;;
    3)
        install_fvwm
        ;;
    4)
        DEPENDENCY_01='awesome'
        REMOTE_DESKTOP_SESSION_01='awesome'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='awesome awesome-extra' ;;
        esac
        ;;
    5)
        DEPENDENCY_01='enlightenment'
        REMOTE_DESKTOP_SESSION_01='enlightenment'
        ;;
    6)
        DEPENDENCY_01='fluxbox'
        REMOTE_DESKTOP_SESSION_01='fluxbox'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='bbmail bbpager bbtime fbpager fluxbox' ;;
        esac
        ;;
    7)
        DEPENDENCY_01='i3'
        REMOTE_DESKTOP_SESSION_01='i3'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='i3 i3-wm i3blocks' ;;
        esac
        ;;
    8)
        DEPENDENCY_01='xmonad'
        REMOTE_DESKTOP_SESSION_01='xmonad'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='xmobar dmenu xmonad' ;;
        esac
        ;;
    9)
        DEPENDENCY_01='9wm'
        REMOTE_DESKTOP_SESSION_01='9wm'
        ;;
    10)
        DEPENDENCY_01='metacity'
        REMOTE_DESKTOP_SESSION_01='metacity'
        ;;
    11)
        DEPENDENCY_01='twm'
        REMOTE_DESKTOP_SESSION_01='twm'
        ;;
    12)
        DEPENDENCY_01='aewm'
        REMOTE_DESKTOP_SESSION_01='aewm'
        ;;
    13)
        DEPENDENCY_01='aewm++'
        REMOTE_DESKTOP_SESSION_01='aewm++'
        ;;
    14)
        DEPENDENCY_01='afterstep'
        REMOTE_DESKTOP_SESSION_01='afterstep'
        ;;
    15)
        DEPENDENCY_01='blackbox'
        REMOTE_DESKTOP_SESSION_01='blackbox'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='bbmail bbpager bbtime blackbox' ;;
        esac
        ;;
    16)
        DEPENDENCY_01='dwm'
        REMOTE_DESKTOP_SESSION_01='dwm'
        ;;
    17)
        DEPENDENCY_01='mutter'
        REMOTE_DESKTOP_SESSION_01='mutter'
        ;;
    18)
        DEPENDENCY_01='bspwm'
        REMOTE_DESKTOP_SESSION_01='bspwm'
        ;;
    19)
        DEPENDENCY_01='clfswm'
        REMOTE_DESKTOP_SESSION_01='clfswm'
        ;;
    20)
        DEPENDENCY_01='ctwm'
        REMOTE_DESKTOP_SESSION_01='ctwm'
        ;;
    21)
        DEPENDENCY_01='evilwm'
        REMOTE_DESKTOP_SESSION_01='evilwm'
        ;;
    22)
        DEPENDENCY_01='flwm'
        REMOTE_DESKTOP_SESSION_01='flwm'
        ;;
    23)
        DEPENDENCY_01='herbstluftwm'
        REMOTE_DESKTOP_SESSION_01='herbstluftwm'
        ;;
    24)
        DEPENDENCY_01='jwm'
        REMOTE_DESKTOP_SESSION_01='jwm'
        ;;
    25)
        case "${TMOE_PROOT}" in
        true | no)
            printf "%s\n" "检测到您处于proot容器环境下，kwin可能无法正常运行"
            RETURN_TO_WHERE="window_manager_install"
            do_you_want_to_continue
            ;;
        esac
        if [ "${LINUX_DISTRO}" = "alpine" ]; then
            DEPENDENCY_01='kwin'
        else
            DEPENDENCY_01='kwin-x11'
        fi
        REMOTE_DESKTOP_SESSION_01='kwin'
        ;;
    26)
        DEPENDENCY_01='lwm'
        REMOTE_DESKTOP_SESSION_01='lwm'
        ;;
    27)
        DEPENDENCY_01='marco'
        REMOTE_DESKTOP_SESSION_01='marco'
        ;;
    28)
        DEPENDENCY_01='matchbox-window-manager'
        REMOTE_DESKTOP_SESSION_01='matchbox-window-manager'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='matchbox-themes-extra matchbox-window-manager' ;;
        esac
        ;;
    29)
        DEPENDENCY_01='miwm'
        REMOTE_DESKTOP_SESSION_01='miwm'
        ;;
    30)
        DEPENDENCY_01='muffin'
        REMOTE_DESKTOP_SESSION_01='muffin'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='murrine-themes muffin' ;;
        esac
        ;;
    31)
        DEPENDENCY_01='mwm'
        REMOTE_DESKTOP_SESSION_01='mwm'
        ;;
    32)
        DEPENDENCY_01='oroborus'
        REMOTE_DESKTOP_SESSION_01='oroborus'
        ;;
    33)
        DEPENDENCY_01='pekwm'
        REMOTE_DESKTOP_SESSION_01='pekwm'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='pekwm-themes pekwm' ;;
        esac
        ;;
    34)
        DEPENDENCY_01='ratpoison'
        REMOTE_DESKTOP_SESSION_01='ratpoison'
        ;;
    35)
        DEPENDENCY_01='sapphire'
        REMOTE_DESKTOP_SESSION_01='sapphire'
        ;;
    36)
        DEPENDENCY_01='sawfish'
        REMOTE_DESKTOP_SESSION_01='sawfish'
        case "${LINUX_DISTRO}" in
        "debian") DEPENDENCY_01='sawfish-themes sawfish' ;;
        esac
        ;;
    37)
        DEPENDENCY_01='spectrwm'
        REMOTE_DESKTOP_SESSION_01='spectrwm'
        ;;
    38)
        DEPENDENCY_01='stumpwm'
        REMOTE_DESKTOP_SESSION_01='stumpwm'
        ;;
    39)
        DEPENDENCY_01='subtle'
        REMOTE_DESKTOP_SESSION_01='subtle'
        ;;
    40)
        DEPENDENCY_01='sugar-session'
        REMOTE_DESKTOP_SESSION_01='sugar-session'
        ;;
    41)
        DEPENDENCY_01='tinywm'
        REMOTE_DESKTOP_SESSION_01='tinywm'
        ;;
    42)
        DEPENDENCY_01='ukwm'
        REMOTE_DESKTOP_SESSION_01='ukwm'
        ;;
    43)
        DEPENDENCY_01='vdesk'
        REMOTE_DESKTOP_SESSION_01='vdesk'
        ;;
    44)
        DEPENDENCY_01='vtwm'
        REMOTE_DESKTOP_SESSION_01='vtwm'
        ;;
    45)
        DEPENDENCY_01='w9wm'
        REMOTE_DESKTOP_SESSION_01='w9wm'
        ;;
    46)
        DEPENDENCY_01='wm2'
        REMOTE_DESKTOP_SESSION_01='wm2'
        ;;
    47)
        DEPENDENCY_01='wmaker'
        REMOTE_DESKTOP_SESSION_01='wmaker'
        ;;
    48)
        DEPENDENCY_01='wmii'
        REMOTE_DESKTOP_SESSION_01='wmii'
        ;;
    49)
        DEPENDENCY_01='xfwm4'
        REMOTE_DESKTOP_SESSION_01='xfwm4'
        ;;
    esac
    #############
    will_be_installed_for_you
    beta_features_quick_install
    configure_vnc_xstartup
    press_enter_to_return
    tmoe_linux_tool_menu
}
##########################
install_fvwm() {
    DEPENDENCY_01='fvwm'
    REMOTE_DESKTOP_SESSION_01='fvwm'
    case "${LINUX_DISTRO}" in
    "debian")
        DEPENDENCY_01='fvwm fvwm-icons'
        #REMOTE_DESKTOP_SESSION_01='fvwm'
        if egrep -q 'buster|bullseye|bookworm' /etc/os-release; then
            DEPENDENCY_01='fvwm fvwm-icons fvwm-crystal'
        else
            REPO_URL='https://mirrors.bfsu.edu.cn/debian/pool/main/f/fvwm-crystal/'
            GREP_NAME='all'
            grep_deb_comman_model_01
            if [ $(command -v fvwm-crystal) ]; then
                REMOTE_DESKTOP_SESSION_01='fvwm-crystal'
            fi
        fi
        ;;
    esac
}
#################
tmoe_virtual_machine_desktop() {
    RETURN_TO_WHERE='tmoe_virtual_machine_desktop'
    BETA_DESKTOP=$(whiptail --title "DE" --menu \
        "您可以在虚拟机或实体机上安装以下桌面\nYou can install the following desktop in \na physical or virtual machine environment." 0 0 0 \
        "1" "👣 gnome3(GNU网络对象模型环境)" \
        "2" "🌲 cinnamon(肉桂基于gnome3,对用户友好)" \
        "3" "🦜 budgie(虎皮鹦鹉基于gnome3,优雅且现代化)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${BETA_DESKTOP}" in
    0 | "") standand_desktop_installation ;;
    1) install_gnome3_desktop ;;
    2) install_cinnamon_desktop ;;
    3) install_budgie_desktop ;;
    esac
    ##################
    press_enter_to_return
    standand_desktop_installation
}
################
configure_vnc_xstartup() {
    auto_install_and_configure_fcitx4
    #[[ -d "/var/run/dbus" ]] || mkdir -pv /var/run/dbus
    mkdir -pv /run/dbus /var/run/dbus /var/lib/dbus/
    #if [ ! -s "/etc/machine-id" ]; then
    if [[ -n $(command -v dbus-uuidgen) ]]; then
        printf "%s\n" "$(dbus-uuidgen)" >"/etc/machine-id" 2>/dev/null
    else
        printf "%s\n" "0ecb780817003d3342d16adb5ff1dfa9" >"/etc/machine-id"
    fi
    ln -svf "/etc/machine-id" /var/lib/dbus/
    #fi
    case ${LINUX_DISTRO} in
    debian) [[ -e /usr/share/doc/fonts-noto-color-emoji ]] || apt install -y fonts-noto-color-emoji ;;
    esac
    mkdir -pv ~/.vnc
    cd ${HOME}/.vnc
    #由于跨架构模拟时，桌面启动过慢，故下面先启动终端。
    mkdir -pv /etc/X11/xinit /etc/tigervnc
    rm -f ${XSESSION_FILE} 2>/dev/null
    cat >${XSESSION_FILE} <<-EndOfFile
		#!/usr/bin/env bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
        [[ ! -s /etc/environment ]] || . /etc/environment
        for i in x-terminal-emulator xfce4-terminal konsole qterminal lxterminal gnome-terminal lxterm xterm;do
            if [[ \$(command -v \${i}) ]];then
                \${i} &
                break
            fi
        done
		unset i
		if [ \$(command -v ${REMOTE_DESKTOP_SESSION_01}) ]; then
			dbus-launch ${REMOTE_DESKTOP_SESSION_01}
		elif [ \$(command -v ${REMOTE_DESKTOP_SESSION_02}) ]; then
			dbus-launch ${REMOTE_DESKTOP_SESSION_02}
        else
            printf "\033[0;35m%s\033[m%s\n"  "ERROR！" "Xsession start failed."
            printf "\033[34m%s\033[0;35m%s\033[m%s\n"  "Xsession" "启动失败！" "您可以向开发者反馈。"
		fi
	EndOfFile
    #--exit-with-session
    chmod 777 ${XSESSION_FILE}
    #xrdb \${HOME}/.Xresources
    #dbus-launch startxfce4 &
    #chmod +x ./xstartup
    rm ./xstartup 2>/dev/null
    ln -svf ${XSESSION_FILE} ./xstartup
    cp -f ${TMOE_TOOL_DIR}/gui/wsl_pulse_audio ${TMOE_LINUX_DIR}
    congigure_xvnc
    first_configure_startvnc
}
####################
congigure_xvnc() {
    #cp -f ~/.vnc/xstartup /etc/X11/xinit/Xsession
    cp -f ${TMOE_TOOL_DIR}/gui/vncserver-config-defaults /etc/tigervnc
    if [ -s "/etc/os-release" ]; then
        if grep -q '^PRETTY_NAME=' /etc/os-release; then
            GREP_NAME='PRETTY_NAME'
        else
            GREP_NAME='NAME'
        fi
        VNC_DESKTOP_NAME=$(grep "^${GREP_NAME}=" /etc/os-release | head -n 1 | awk -F '=' '{print $2}' | cut -d '"' -f 2 | sed 's@ @-@g;s@$@\_tmoe-linux-vnc@g')
        [[ -z ${VNC_DESKTOP_NAME} ]] || sed -i "s@^desktop=.*@desktop=\'${VNC_DESKTOP_NAME}\'@" /etc/tigervnc/vncserver-config-defaults
    fi
}
############
configure_x11vnc_remote_desktop_session() {
    cd /usr/local/bin/
    rm -f startx11vnc
    cp -f ${TMOE_TOOL_DIR}/gui/startx11vnc ${TMOE_TOOL_DIR}/gui/x11vncpasswd ./

    if [ "${NON_DBUS}" != "true" ]; then
        enable_dbus_launch
    fi
    chmod +x ./*

    if [ -e "${HOME}/.vnc/passwd" ]; then
        cd ${HOME}/.vnc
        cp -pvf passwd x11passwd
    else
        x11vncpasswd
    fi
    printf "%s\n" "${BLUE}x11vnc${RESET}配置完成，您可以输${GREEN}startx11vnc${RESET}来重启${BLUE}x11vnc服务${RESET},输${RED}stopvnc${RESET}停止。"
    printf "%s\n" "You can type ${GREEN}startx11vnc${RESET} to restart it,type ${RED}stopvnc${RESET} to stop it."
    printf "%s\n" "输${GREEN}startvnc${RESET}切换到${BLUE}tight/tigervnc服务${RESET}。"
    #startx11vnc
}
##########################
install_tmoe_electron_app_pack() {
    if [[ "${AUTO_INSTALL_ELECTRON_APPS}" = true ]]; then
        check_electron
        install_electron_v8
        DEPENDENCY_01=''
        for DEPENDENCY_01 in electron-netease-cloud-music bilibili-web listen1 lx-music-desktop cocomusic petal zy-player; do
            download_tmoe_electron_app
        done
    fi
}
##########################
install_kali_linux_tools() {
    if [[ "${AUTO_INSTALL_KALI_TOOLS}" = true ]]; then
        if [[ ! -n $(command -v zenmap) ]]; then
            printf "%s\n" "${GREEN}apt install ${YELLOW}-y ${BLUE}zenmap${RESET}"
            apt install -y zenmap
        fi
        printf "%s\n" "${GREEN}apt install ${YELLOW}-y ${BLUE}kali-menu${RESET}"
        apt install -y kali-menu || aptitude install -y kali-menu
        case ${ARCH_TYPE} in
        arm64 | armhf | armel)
            printf "%s\n" "${GREEN}apt install ${YELLOW}-y ${BLUE}kali-linux-arm${RESET}"
            apt install -y kali-linux-arm || aptitude install -y kali-linux-arm
            ;;
        *)
            printf "%s\n" "${GREEN}apt install ${YELLOW}-y ${BLUE}kali-linux-default${RESET}"
            apt install -y kali-linux-default || aptitude install -y kali-linux-default
            ;;
        esac
    fi
}
###########################
kali_xfce4_extras() {
    printf "%s\n" "${GREEN}apt install ${YELLOW}-y ${BLUE}kali-undercover${RESET}"
    apt install -y kali-themes-common
    if [ $(command -v chromium) ]; then
        apt install -y chromium-l10n
        fix_chromium_root_no_sandbox
    fi
    apt search kali-linux
    dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s Windows-10-Icons
}
###################
apt_purge_libfprint() {
    case ${TMOE_PROOT} in
    false) ;;
    true | no)
        case "${LINUX_DISTRO}" in
        "debian")
            printf "%s\n" "${PURPLE}apt purge ${YELLOW}-y ${BLUE}^libfprint${RESET}"
            apt purge -y ^libfprint
            apt clean
            apt autoclean
            ;;
        esac
        ;;
    esac
}
###################
build_xfce4_panel_profiles() {
    CURRENT_DIR=$(pwd)
    #intltool-merge命令依赖于intltool
    for i in make automake python-gobject intltool pamac; do
        if [[ ! $(command -v ${i}) ]]; then
            printf "%s\n" "${GREEN}pacman ${YELLOW}-Sy --noconfirm ${BLUE}${i}${RESET}"
            pacman -Sy --noconfirm ${i}
        fi
    done
    FAKEROOT_SRC_REPO='https://mirrors.bfsu.edu.cn/ubuntu/pool/universe/x/xfce4-panel-profiles/'
    FAKEROOT_SRC_VERSION=$(curl -L ${FAKEROOT_SRC_REPO} | grep \.orig\.tar | tail -n 1 | awk -F '<a href=' '{print $2}' | cut -d '"' -f 2)
    FAKEROOT_SRC_URL="${FAKEROOT_SRC_REPO}${FAKEROOT_SRC_VERSION}"
    FAKEROOT_SRC_FILE=$(printf "%s\n" ${FAKEROOT_SRC_VERSION} | sed 's@profiles_@profiles-@g')
    cd /tmp
    curl -Lv -o ${FAKEROOT_SRC_FILE} ${FAKEROOT_SRC_URL}
    tar -xvf ${FAKEROOT_SRC_FILE}
    cd ${FAKEROOT_SRC_FILE%.*.*.*}
    ./configure --prefix=/usr --python=python
    make -j4
    make install
    cd /tmp
    rm -rv ${FAKEROOT_SRC_FILE%.*.*.*} ${FAKEROOT_SRC_FILE}
    cd ${CURRENT_DIR}
}
###################
debian_xfce4_extras() {
    case ${LINUX_DISTRO} in
    debian)
        for i in qt5ct mugshot; do
            if [ ! $(command -v ${i}) ]; then
                printf "%s\n" "${GREEN}apt install ${YELLOW}-y ${BLUE}${i}${RESET}"
                apt install -y ${i}
            fi
        done
        if [ ! -e "/usr/share/themes/Breeze/xfwm4/themerc" ]; then
            #printf "${BLUE}%s${RESET}\n" "apt install -y xfwm4-theme-breeze"
            printf "%s\n" "${GREEN}apt install ${YELLOW}-y ${BLUE}xfwm4-theme-breeze${RESET}"
            apt install -y xfwm4-theme-breeze
        fi
        case ${DEBIAN_DISTRO} in
        kali) kali_xfce4_extras ;;
        esac
        if [ ! $(command -v xfce4-panel-profiles) ]; then
            case ${DEBIAN_DISTRO} in
            ubuntu)
                if ! grep -q 'Bionic' /etc/os-release; then
                    GREP_NAME="xfce4-panel-profiles"
                else
                    GREP_NAME="xfpanel-switch"
                fi
                apt install -y ${GREP_NAME}
                ;;
            *)
                REPO_URL='https://mirrors.bfsu.edu.cn/ubuntu/pool/universe/x/xfce4-panel-profiles/'
                GREP_NAME="xfce4-panel-profiles"
                THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '\.deb' | grep "${GREP_NAME}" | grep -v '1.0.9' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
                download_deb_comman_model_02
                ;;
            esac
        fi
        ;;
    redhat)
        if [ ! $(command -v qt5ct) ]; then
            printf "%s\n" "${GREEN}dnf install ${YELLOW}--skip-broken -y ${BLUE}qt5ct${RESET}"
            yum install --skip-broken -y qt5ct
        fi
        [[ $(command -v startxfce4) ]] || yum install --skip-broken -y @xfce
        ;;
    arch)
        i=qt5ct
        if [ ! $(command -v ${i}) ]; then
            printf "%s\n" "${GREEN}pacman ${YELLOW}-Sy --noconfirm ${BLUE}${i}${RESET}"
            pacman -Sy --noconfirm qt5ct 2>/dev/null
        fi
        [[ $(command -v xfce4-panel-profiles) ]] || build_xfce4_panel_profiles
        ;;
    esac
    if [ $(command -v qt5ct) ]; then
        if ! egrep -q '^[^#]*QT_QPA_PLATFORMTHEME=' /etc/environment; then
            printf "%s\n" "export QT_QPA_PLATFORMTHEME=qt5ct" >>/etc/environment
            printf "%s\n" "/etc/environment :export QT_QPA_PLATFORMTHEME=qt5ct"
            printf "${GREEN}%s${RESET}\n" "/etc/environment:"
            grep -n --color=auto "QT_QPA_PLATFORMTHEME=" /etc/environment
        fi
    fi
    apt_purge_libfprint
}
#############
touch_xfce4_terminal_rc() {
    cat >terminalrc <<-'ENDOFTERMIANLRC'
		[Configuration]
		ColorForeground=#e6e1cf
		ColorBackground=#0f1419
		ColorCursor=#f29718
		ColorPalette=#000000;#ff3333;#b8cc52;#e7c547;#36a3d9;#f07178;#95e6cb;#ffffff;#323232;#ff6565;#eafe84;#fff779;#68d5ff;#ffa3aa;#c7fffd;#ffffff
		MiscAlwaysShowTabs=FALSE
		MiscBell=FALSE
		MiscBellUrgent=FALSE
		MiscBordersDefault=TRUE
		MiscCursorBlinks=FALSE
		MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
		MiscDefaultGeometry=80x24
		MiscInheritGeometry=FALSE
		MiscMenubarDefault=TRUE
		MiscMouseAutohide=FALSE
		MiscMouseWheelZoom=TRUE
		MiscToolbarDefault=TRUE
		MiscConfirmClose=TRUE
		MiscCycleTabs=TRUE
		MiscTabCloseButtons=TRUE
		MiscTabCloseMiddleClick=TRUE
		MiscTabPosition=GTK_POS_TOP
		MiscHighlightUrls=TRUE
		MiscMiddleClickOpensUri=FALSE
		MiscCopyOnSelect=FALSE
		MiscShowRelaunchDialog=TRUE
		MiscRewrapOnResize=TRUE
		MiscUseShiftArrowsToScroll=FALSE
		MiscSlimTabs=FALSE
		MiscNewTabAdjacent=FALSE
		BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
		BackgroundDarkness=0.730000
		ScrollingUnlimited=TRUE
	ENDOFTERMIANLRC
}
###################
xfce4_color_scheme() {
    if [ ! -e "/usr/share/xfce4/terminal/colorschemes/Monokai Remastered.theme" ]; then
        cd /usr/share/xfce4/terminal
        printf "%s\n" "正在配置xfce4终端配色..."
        curl -Lo "colorschemes.tar.xz" 'https://gitee.com/mo2/xfce-themes/raw/terminal/colorschemes.tar.xz'
        tar -Jxvf "colorschemes.tar.xz"
    fi

    XFCE_TERMINAL_PATH="${HOME}/.config/xfce4/terminal/"
    if [ ! -e "${XFCE_TERMINAL_PATH}/terminalrc" ]; then
        mkdir -pv ${XFCE_TERMINAL_PATH}
        cd ${XFCE_TERMINAL_PATH}
        touch_xfce4_terminal_rc
    fi

    #/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc
    #/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc
    #/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc
    cd ${XFCE_TERMINAL_PATH}
    if ! grep -q '^ColorPalette' terminalrc; then
        sed -i '/ColorPalette=/d' terminalrc
        sed -i '/ColorForeground=/d' terminalrc
        sed -i '/ColorBackground=/d' terminalrc
        cat >>terminalrc <<-'EndofAyu'
			ColorPalette=#000000;#ff3333;#b8cc52;#e7c547;#36a3d9;#f07178;#95e6cb;#ffffff;#323232;#ff6565;#eafe84;#fff779;#68d5ff;#ffa3aa;#c7fffd;#ffffff
			ColorForeground=#e6e1cf
			ColorBackground=#0f1419
		EndofAyu
    fi

    if ! grep -q '^FontName' terminalrc; then
        sed -i '/FontName=/d' terminalrc
        if [ -e "/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc" ]; then
            sed -i '$ a\FontName=Noto Sans Mono CJK SC Bold Italic 12' terminalrc
        elif [ -e "/usr/share/fonts/noto-cjk/NotoSansCJK-Bold.ttc" ]; then
            sed -i '$ a\FontName=Noto Sans Mono CJK SC Bold 12' terminalrc
        elif [ -e "/usr/share/fonts/google-noto-cjk/NotoSansCJK-Bold.ttc" ]; then
            sed -i '$ a\FontName=Noto Sans Mono CJK SC Bold 13' terminalrc
        fi
    fi
}
##################
xfce_warning() {
    ICON_URL='https://gitee.com/ak2/icons/raw/master/xfce4.jpg'
    ICON_FILE_NAME='xfce4.jpg'
    download_and_cat_icon_img
    cat <<-'ENDofTable'
    xfce4桌面支持表格 
    以下数据仅代表tmoe-linux tool所安装的xfce，您可自行编译源代码，并修复bug。
  ╔═══╦════════════╦════════╦════════╦═════════╦
  ║   ║vnc/xserver ║        ║        ║         ║
  ║   ║----------- ║ x11vnc ║tigervnc║ xserver ║
  ║   ║System      ║        ║        ║         ║
  ║---║------------║--------║--------║---------║
  ║ 1 ║ Debian,Kali║  ✓     ║    ✓   ║   ✓     ║
  ║   ║ Ubuntu     ║        ║        ║         ║
  ║---║------------║--------║--------║---------║
  ║   ║Fedora      ║        ║        ║         ║
  ║ 2 ║CentOS      ║  ✓     ║   ✓    ║   ✓     ║
  ║---║------------║--------║--------║---------║
  ║   ║ArchLinux   ║        ║        ║         ║
  ║ 3 ║Manjaro     ║   ✓    ║    ✓   ║    ✓    ║
  ║---║------------║--------║--------║---------║
  ║   ║ Alpine     ║        ║        ║         ║
  ║ 4 ║            ║  ✓     ║   X    ║   ✓     ║ 
  ║---║------------║--------║--------║---------║
  ║   ║  Void      ║        ║        ║         ║
  ║ 5 ║            ║  ?     ║   ✓    ║   ✓     ║ 
  ║---║------------║--------║--------║---------║
  ║   ║OpenSUSE    ║        ║        ║         ║
  ║ 6 ║            ║  ✓     ║   ✓    ║   ✓     ║

ENDofTable
    printf '%s\n' '即将为您安装fonts-noto-cjk（思源黑体）、fonts-noto-color-emoji、xfce4、xfce4-terminal、xfce4-goodies、xfce4-panel-profiles、qt5ct、xfwm4-theme-breeze、mugshot和tightvncserver等软件包。'
    do_you_want_to_continue
}
##########
git_clone_kali_themes_common() {
    check_update_icon_caches_sh
    if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
        TEMP_FOLDER="/tmp/.KALI_THEME_COMMON_TEMP_FOLDER"
        git clone --depth=1 https://gitee.com/ak2/kali-theme.git ${TEMP_FOLDER}
        tar -pJxvf ${TEMP_FOLDER}/kali-theme.tar.xz -C /
        rm -rvf ${TEMP_FOLDER}
        dbus-launch xfconf-query -c xsettings -t string -np /Gtk/CursorThemeName -s "Breeze-Adapta-Cursor" 2>/dev/null
        ICON_NAME='Flat-Remix-Blue-Dark /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/desktop-base'
        update-icon-caches /usr/share/icons/${ICON_NAME} 2>/dev/null &
    fi
}
##########
do_you_want_to_install_electron_apps_zh() {
    case ${LINUX_DISTRO} in
    alpine) ;;
    *)
        if [[ ! -n $(command -v electron) ]]; then
            if (whiptail --title "Electron apps" --yes-button "YES" --no-button "NO" --yesno '请问您是否需要安装开发者推荐的electron软件包合集?\n该合集包含electron-netease-cloud-music,bilibili-web,listen1,\nlx-music-desktop,cocomusic,petal和zy-player\n您可以选择NO跳过,之后可以单独安装electron app.' 0 0); then
                AUTO_INSTALL_ELECTRON_APPS='true'
            fi
        fi
        ;;
    esac
}
#########
do_you_want_to_install_electron_apps_en() {
    case ${LINUX_DISTRO} in
    alpine) ;;
    *)
        if [[ ! -n $(command -v electron) ]]; then
            if (whiptail --title "Electron apps" --yes-button "YES" --no-button "NO" --yesno 'Do you want to install electron apps pack?\nIt includes electron-netease-cloud-music,bilibili-web,listen1,\nlx-music-desktop,cocomusic,petal & zy-player.' 0 0); then
                AUTO_INSTALL_ELECTRON_APPS='true'
            fi
        fi
        ;;
    esac
}
##########
do_you_want_to_install_fcitx4() {
    unset AUTO_INSTALL_HARD_INFO
    case ${TMOE_MENU_LANG} in
    zh_*UTF-8)
        case "${LINUX_DISTRO}" in
        "debian" | "arch")
            #fedora proot不要自动配置fcitx
            if [[ ! -n $(command -v fcitx) && ! -n $(command -v fcitx5) ]]; then
                if (whiptail --title "input method" --yes-button "YES" --no-button "NO" --yesno '檢測到您當前的語言環境爲中文，是否需要安裝中文輸入法?\nDo you want to install fcitx4?\n安裝完成後,在桌面環境下按Ctrl+空格切換輸入法\n你亦可以選擇NO跳過,之後可以單獨安裝fcitx5' 0 0); then
                    AUTO_INSTALL_FCITX4='true'
                fi
            fi
            ;;
        esac
        do_you_want_to_install_electron_apps_zh
        ;;
    *) do_you_want_to_install_electron_apps_en ;;
    esac
    case "${LINUX_DISTRO}" in
    "debian" | "arch")
        if [[ ! -n $(command -v hardinfo) ]]; then
            if (whiptail --title "HARDINFO" --yes-button "YES" --no-button "NO" --yesno 'Do you want to install hardinfo?\nIt can display system information.' 0 0); then
                AUTO_INSTALL_HARD_INFO='true'
            fi
        fi
        ;;
    esac
    do_you_want_to_install_kali_tools
}
#########
do_you_want_to_install_kali_tools() {
    case "${LINUX_DISTRO}" in
    "debian")
        case "${DEBIAN_DISTRO}" in
        "kali")
            if (whiptail --title "KALI LINUX TOOLS" --yes-button "YES" --no-button "NO" --yesno 'Do you want to install kali-linux tools?' 0 0); then
                AUTO_INSTALL_KALI_TOOLS='true'
            fi
            ;;
        esac
        ;;
    esac
}
auto_install_and_configure_fcitx4() {
    case ${LINUX_DISTRO} in
    debian)
        case ${UBUNTU_DESKTOP} in
        true)
            printf "%s\n" "apt install -y \$(check-language-support)"
            [[ -e ${TMOE_LINUX_DIR}/check-ubuntu-language-support.txt ]] || printf "%s\n" $(check-language-support) >${TMOE_LINUX_DIR}/check-ubuntu-language-support.txt
            apt install -y $(check-language-support) || aptitude install -y $(check-language-support)
            ;;
        esac
        ;;
    esac
    #在安裝完桌面後再配置輸入法
    [[ ${AUTO_INSTALL_FCITX4} != true ]] || source ${TMOE_TOOL_DIR}/app/input-method.sh --auto-install-fcitx4
    install_tmoe_electron_app_pack
    install_kali_linux_tools
    if [[ ${AUTO_INSTALL_HARD_INFO} = true ]]; then
        printf "%s\n" "${GREEN}${TMOE_INSTALLATION_COMMAND} ${BLUE}hardinfo${RESET}"
        ${TMOE_INSTALLATION_COMMAND} hardinfo
        printf "%s\n" "You can type ${PURPLE}${TMOE_REMOVAL_COMMAND} ${BLUE}hardinfo${RESET} to remove it."
    fi
}
#######
install_xfce4_desktop() {
    xfce_warning
    do_you_want_to_install_fcitx4
    REMOTE_DESKTOP_SESSION_01='xfce4-session'
    REMOTE_DESKTOP_SESSION_02='startxfce4'
    DEPENDENCY_01="xfce4"
    case "${LINUX_DISTRO}" in
    "debian")
        DEPENDENCY_01="xfce4 xfce4-goodies xfce4-terminal"
        case ${DEBIAN_DISTRO} in
        ubuntu)
            if (whiptail --title "Xfce or Xubuntu-desktop" --yes-button "xfce" --no-button "xubuntu" --yesno 'The former is more streamlined, and the latter includes some extra software of xubuntu.\n前者为普通xfce,后者为xubuntu' 0 0); then
                printf ""
            else
                UBUNTU_DESKTOP=true
                DEPENDENCY_01="xubuntu-desktop"
                case ${TMOE_PROOT} in
                false) ;;
                true | no)
                    #mkdir -pv /var/lib/mlocate/
                    #touch /var/lib/mlocate/mlocate.db /run/mlocate.daily.lock
                    if [ ! $(command -v mlocate) ]; then
                        CUR=$(pwd)
                        TEMP_DIR='/tmp/.MLOCATE_TEMP_FOLDER'
                        mkdir -pv ${TEMP_DIR}
                        cd ${TEMP_DIR}
                        apt-get download mlocate
                        dpkg --unpack ./mlocate*.deb
                        cd ${CUR}
                        rm -rvf ${TEMP_DIR}
                        cp -f ${TMOE_TOOL_DIR}/gui/config/mlocate.postinst /var/lib/dpkg/info/
                        chmod a+x -v /var/lib/dpkg/info/mlocate.postinst
                        apt-mark hold mlocate
                        #sed -i 's@flock@#&@g;s@/usr/bin/updatedb.mlocate || true@#&@' /var/lib/dpkg/info/mlocate.postinst
                    fi
                    ;;
                esac
            fi
            ;;
        esac
        dpkg --configure -a
        auto_select_keyboard_layout
        ;;
        ##############
    "redhat")
        DEPENDENCY_01='@xfce xfce*-plugin xfce4-panel-profiles'
        rm -v /etc/xdg/autostart/xfce-polkit.desktop 2>/dev/null
        ;;
        ##################
    "arch") DEPENDENCY_01="xfce4 xfce4-terminal xfce4-goodies" ;;
        ##################
    "void") DEPENDENCY_01="xfce4" ;;
        #################
    "gentoo")
        dispatch-conf
        etc-update
        DEPENDENCY_01="xfce4-meta x11-terms/xfce4-terminal"
        ;;
        #################
    "suse") DEPENDENCY_01="patterns-xfce-xfce xfce4-terminal" ;;
        ###############
    "alpine") DEPENDENCY_01="faenza-icon-theme xfce4-whiskermenu-plugin xfce4 xfce4-terminal" ;;
    esac
    ##################
    beta_features_quick_install
    ####################
    case ${LINUX_DISTRO} in
    alpine) ;;
    *) git_clone_kali_themes_common ;;
    esac
    debian_xfce4_extras
    if [ ! -e "/usr/share/icons/Breeze-Adapta-Cursor" ]; then
        download_arch_breeze_adapta_cursor_theme
    fi
    mkdir -pv ${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/
    cd ${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/
    if [ ! -e "xfce4-desktop.xml" ]; then
        modify_the_default_xfce_wallpaper
    fi
    dbus-launch xfconf-query -c xsettings -t string -np /Gtk/CursorThemeName -s "Breeze-Adapta-Cursor" 2>/dev/null

    #XFCE_WORK_SPACE_01=$(cat xfce4-desktop.xml | grep -n workspace1 | awk '{print $1}' | cut -d ':' -f 1)
    #if [ "$(cat xfce4-desktop.xml | sed -n 1,${XFCE_WORK_SPACE_01}p | egrep 'xfce-stripes|xfce-blue|xfce-teal|0.svg')" ]; then
    #	modify_the_default_xfce_wallpaper
    #fi
    if [ ! -e "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" ]; then
        auto_configure_xfce4_panel
    fi
    #xml配置不包含base-directory
    #################
    if [ "${LINUX_DISTRO}" = "alpine" ]; then
        dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s Faenza
    else
        #if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
        #    download_kali_themes_common
        #fi
        if [ "${DEBIAN_DISTRO}" != "kali" ]; then
            dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s Flat-Remix-Blue-Light
        fi
    fi
    ##############
    xfce4_color_scheme
    dbus-launch xfconf-query -c xfwm4 -t int -np /general/workspace_count -s 2
    #########
    case ${TMOE_PROOT} in
    true)
        case "${LINUX_DISTRO}" in
        "debian")
            case "${DEBIAN_DISTRO}" in
            "kali") ;;
            *)
                if [ ! -e "/usr/share/icons/Windows-10-Icons/128x128/mimetypes/" ]; then
                    apt autoremove --purge -y ^xfce4-power-manager
                fi
                ;;
            esac
            ;;
        arch) pacman -Rsc --noconfirm xfce4-power-manager ;;
        redhat) dnf remove -y xfce4-power-manager ;;
        esac
        ;;
    esac
    configure_vnc_xstartup
}
###############
xfce_papirus_icon_theme() {
    if [ ! -e "/usr/share/icons/Papirus" ]; then
        download_papirus_icon_theme
        if [ "${DEBIAN_DISTRO}" != "kali" ]; then
            dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus
        fi
    fi
}
###########
creat_xfce4_desktop_wallpaper_config() {
    cd ${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml
    cat >xfce4-desktop.xml <<-'EOF'
		<?xml version="1.0" encoding="UTF-8"?>

		<channel name="xfce4-desktop" version="1.0">
		    <property name="backdrop" type="empty">
		        <property name="screen0" type="empty">
		            <property name="monitor0" type="empty">
		                <property name="brightness" type="empty"/>
		                <property name="color1" type="empty"/>
		                <property name="color2" type="empty"/>
		                <property name="color-style" type="empty"/>
		                <property name="image-path" type="empty"/>
		                <property name="image-show" type="empty"/>
		                <property name="last-image" type="empty"/>
		                <property name="last-single-image" type="empty"/>
		                <property name="workspace0" type="empty">
		                    <property name="last-image" type="string" value="/usr/share/backgrounds/xfce/xfce-stripes.png"/>
		                    <property name="backdrop-cycle-enable" type="bool" value="true"/>
		                    <property name="backdrop-cycle-random-order" type="bool" value="true"/>
		                </property>
		            </property>
		            <property name="monitor1" type="empty">
		                <property name="brightness" type="empty"/>
		                <property name="color1" type="empty"/>
		                <property name="color2" type="empty"/>
		                <property name="color-style" type="empty"/>
		                <property name="image-path" type="empty"/>
		                <property name="image-show" type="empty"/>
		                <property name="last-image" type="empty"/>
		                <property name="last-single-image" type="empty"/>
		            </property>
		            <property name="monitorVNC-0" type="empty">
		                <property name="workspace0" type="empty">
		                    <property name="last-image" type="string" value="/usr/share/backgrounds/xfce/xfce-stripes.png"/>
		                    <property name="backdrop-cycle-enable" type="bool" value="true"/>
		                    <property name="backdrop-cycle-random-order" type="bool" value="true"/>
		                </property>
		            </property>
		            <property name="monitorrdp0" type="empty">
		                <property name="workspace0" type="empty">
		                    <property name="color-style" type="empty"/>
		                    <property name="image-style" type="empty"/>
		                    <property name="last-image" type="string" value="/usr/share/backgrounds/xfce/xfce-stripes.png"/>
		                    <property name="backdrop-cycle-enable" type="bool" value="true"/>
		                    <property name="backdrop-cycle-random-order" type="bool" value="true"/>
		                </property>
		            </property>
		            <property name="monitorscreen" type="empty">
		                <property name="workspace0" type="empty">
		                    <property name="color-style" type="empty"/>
		                    <property name="image-style" type="empty"/>
		                    <property name="last-image" type="string" value="/usr/share/backgrounds/xfce/xfce-stripes.png"/>
		                    <property name="backdrop-cycle-enable" type="bool" value="true"/>
		                    <property name="backdrop-cycle-random-order" type="bool" value="true"/>
		                </property>
		            </property>
		        </property>
		    </property>
		</channel>
	EOF
    cat xfce4-desktop.xml
}
#############
modify_xfce_vnc0_wallpaper() {
    #if [ "${LINUX_DISTRO}" = "debian" ]; then
    #if [ "${VNC_SERVER_BIN}" = "tigervnc" ]; then
    #	dbus-launch xfconf-query -c xfce4-desktop -t string -np /backdrop/screen0/monitorVNC-0/workspace0/last-image -s "${WALLPAPER_FILE}"
    #else
    #	dbus-launch xfconf-query -c xfce4-desktop -t string -np /backdrop/screen0/monitor0/workspace0/last-image -s "${WALLPAPER_FILE}"
    #fi
    creat_xfce4_desktop_wallpaper_config
    sed -i "s@/usr/share/backgrounds/xfce/xfce-stripes.png@${WALLPAPER_FILE}@" xfce4-desktop.xml
    #else
    #	dbus-launch xfconf-query -c xfce4-desktop -t string -np /backdrop/screen0/monitorVNC-0/workspace0/last-image -s "${WALLPAPER_FILE}"
    #fi
}
##################
debian_download_mint_wallpaper() {
    SET_MINT_AS_WALLPAPER='true'
    download_mint_backgrounds
}
#############
debian_xfce_wallpaper() {
    if [ ! -e "${WALLPAPER_FILE}" ]; then
        #debian_download_xubuntu_xenial_wallpaper
        printf "%s\n" "壁纸包将保存至/usr/share/backgrounds"
        debian_download_mint_wallpaper
    fi
    modify_xfce_vnc0_wallpaper
}
#################
check_mate_wallpaper_pack() {
    if [ ! -e "${WALLPAPER_FILE}" ]; then
        printf "%s\n" "壁纸包将保存至/usr/share/backgrounds"
        debian_download_ubuntu_mate_wallpaper
    fi
    modify_xfce_vnc0_wallpaper
}
###############
if_exists_other_debian_distro_wallpaper() {
    if [ -e "${WALLPAPER_FILE}" ]; then
        modify_xfce_vnc0_wallpaper
    else
        debian_xfce_wallpaper
    fi
}
###############
linuxmint_serena_wallpaper_var() {
    MINT_CODE='serena'
    WALLPAPER_FILE='/usr/share/backgrounds/rlukeman_skye.jpg'
}
linuxmint_sonya_wallpaper_var() {
    MINT_CODE='sonya'
    WALLPAPER_FILE='/usr/share/backgrounds/shontz_valley.jpg'
}
linuxmint_sylvia_wallpaper_var() {
    MINT_CODE='sylvia'
    WALLPAPER_FILE='/usr/share/backgrounds/thomasb_glass_ball.jpg'
}
linuxmint_tara_wallpaper_var() {
    MINT_CODE='tara'
    WALLPAPER_FILE='/usr/share/backgrounds/jowens_kauai.jpg'
}
linuxmint_tessa_wallpaper_var() {
    MINT_CODE='tessa'
    WALLPAPER_FILE="/usr/share/backgrounds/dking_autumn_in_japan.jpg"
}
linuxmint_tina_wallpaper_var() {
    MINT_CODE="tina"
    WALLPAPER_FILE='/usr/share/backgrounds/adeole_yosemite.jpg'
}
linuxmint_tricia_wallpaper_var() {
    MINT_CODE="tricia"
    WALLPAPER_FILE='/usr/share/backgrounds/amarttinen_argentina.jpg'
}
linuxmint_ulyana_wallpaper_var() {
    MINT_CODE="ulyana"
    WALLPAPER_FILE='/usr/share/backgrounds/dmcquade_whitsundays.jpg'
}
linuxmint_sarah_wallpaper_var() {
    MINT_CODE="sarah"
    WALLPAPER_FILE='/usr/share/backgrounds/bartosova_aurora.jpg'
}
###########
random_wallpaper_pack_01() {
    case "$(($RANDOM % 20 + 1))" in
    [6-9]) linuxmint_tina_wallpaper_var ;;
    [10-12]) linuxmint_tricia_wallpaper_var ;;
    13 | 14) linuxmint_tessa_wallpaper_var ;;
    15 | 16) linuxmint_tara_wallpaper_var ;;
    17) linuxmint_serena_wallpaper_var ;;
    18) linuxmint_sonya_wallpaper_var ;;
    19) linuxmint_sylvia_wallpaper_var ;;
    20) linuxmint_sarah_wallpaper_var ;;
    [1-5] | *) linuxmint_ulyana_wallpaper_var ;;
    esac
}
############
random_wallpaper_pack_02() {
    case "$(($RANDOM % 22 + 1))" in
    [6-9]) linuxmint_tara_wallpaper_var ;;
    [10-12]) linuxmint_tricia_wallpaper_var ;;
    13 | 14) linuxmint_sylvia_wallpaper_var ;;
    15 | 16) linuxmint_serena_wallpaper_var ;;
    17 | 18) linuxmint_sonya_wallpaper_var ;;
    19) linuxmint_tina_wallpaper_var ;;
    20) linuxmint_ulyana_wallpaper_var ;;
    21 | 22) linuxmint_sarah_wallpaper_var ;;
    [1-5] | *) linuxmint_tessa_wallpaper_var ;;
    esac
}
############
random_wallpaper_pack_03() {
    case "$(($RANDOM % 20 + 1))" in
    [6-9]) linuxmint_ulyana_wallpaper_var ;;
    [10-12]) linuxmint_tina_wallpaper_var ;;
    13 | 14) linuxmint_tessa_wallpaper_var ;;
    15 | 16) linuxmint_tara_wallpaper_var ;;
    17) linuxmint_serena_wallpaper_var ;;
    18) linuxmint_sonya_wallpaper_var ;;
    19) linuxmint_sylvia_wallpaper_var ;;
    20) linuxmint_sarah_wallpaper_var ;;
    [1-5] | *) linuxmint_tricia_wallpaper_var ;;
    esac
}
############
random_wallpaper_pack_04() {
    case "$(($RANDOM % 20 + 1))" in
    [4-6]) linuxmint_tina_wallpaper_var ;;
    [7-9]) linuxmint_tricia_wallpaper_var ;;
    [10-12]) linuxmint_tessa_wallpaper_var ;;
    [13-15]) linuxmint_tara_wallpaper_var ;;
    [16-17]) linuxmint_serena_wallpaper_var ;;
    18) linuxmint_sonya_wallpaper_var ;;
    19) linuxmint_sylvia_wallpaper_var ;;
    20) linuxmint_sarah_wallpaper_var ;;
    [1-3] | *) linuxmint_ulyana_wallpaper_var ;;
    esac
}
############
random_wallpaper_pack_05() {
    RANDOM_WALLPAPER_PACK="$(($RANDOM % 27 + 1))"
    case ${RANDOM_WALLPAPER_PACK} in
    [6-9]) linuxmint_sonya_wallpaper_var ;;
    [10-12]) linuxmint_sarah_wallpaper_var ;;
    13 | 14) linuxmint_sylvia_wallpaper_var ;;
    15 | 16) linuxmint_tessa_wallpaper_var ;;
    17 | 18) linuxmint_tara_wallpaper_var ;;
    19) linuxmint_tina_wallpaper_var ;;
    20) linuxmint_ulyana_wallpaper_var ;;
    21 | 22) linuxmint_tricia_wallpaper_var ;;
    [23-27]) ubuntu_mate_wallpaper_var ;;
    [1-5] | *) linuxmint_serena_wallpaper_var ;;
    esac
    case ${RANDOM_WALLPAPER_PACK} in
    [23-27]) ;;
    *) debian_xfce_wallpaper ;;
    esac
}
############
ubuntu_mate_wallpaper_var() {
    WALLPAPER_FILE='/usr/share/backgrounds/johann-siemens-591.jpg'
    check_mate_wallpaper_pack
}
############
modify_the_default_xfce_wallpaper() {
    FORCIBLY_DOWNLOAD='true'
    case "${LINUX_DISTRO}" in
    "debian")
        random_wallpaper_pack_01
        case "${DEBIAN_DISTRO}" in
        ubuntu) random_wallpaper_pack_03 ;;
        "kali")
            cp -sv /usr/share/backgrounds/kali-16x9/* /usr/share/backgrounds/ 2>/dev/null
            random_wallpaper_pack_04
            ;;
        esac
        debian_xfce_wallpaper
        ;;
    "arch")
        #WALLPAPER_FILE="/usr/share/backgrounds/xfce/Violet.jpg"
        mv -f /usr/share/backgrounds/xfce/* /usr/share/backgrounds/
        mv -f /usr/share/backgrounds/xfce-* /usr/share/backgrounds/xfce/ 2>/dev/null
        random_wallpaper_pack_02
        debian_xfce_wallpaper
        ;;
    "redhat")
        random_wallpaper_pack_02
        debian_xfce_wallpaper
        ;;
    *) random_wallpaper_pack_05 ;;
    esac
}
#################
debian_download_ubuntu_mate_wallpaper() {
    SET_MINT_AS_WALLPAPER='true'
    download_ubuntu-mate_wallpaper
}
#####################
debian_download_xubuntu_xenial_wallpaper() {
    REPO_URL='https://mirrors.bfsu.edu.cn/ubuntu/pool/universe/x/xubuntu-community-artwork/'
    GREP_NAME_01='xubuntu-community-wallpapers-xenial'
    GREP_NAME_02='all.deb'
    grep_deb_comman_model_02
}
###############
auto_configure_xfce4_panel() {
    XFCE_CONFIG_FOLDER="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml"
    mkdir -pv ${XFCE_CONFIG_FOLDER}
    cd ${XFCE_CONFIG_FOLDER}
    cp -f ${TMOE_TOOL_DIR}/gui/config/xfce4-panel.xml ./
    CURRENT_USER_FILE=$(pwd)
    fix_non_root_permissions
}
############
install_lxde_desktop() {
    REMOTE_DESKTOP_SESSION_01='lxsession'
    REMOTE_DESKTOP_SESSION_02='startlxde'
    printf '%s\n' '即将为您安装fonts-noto-cjk（思源黑体）、fonts-noto-color-emoji、lxde-core、lxterminal、tightvncserver。'
    do_you_want_to_continue
    do_you_want_to_install_fcitx4
    DEPENDENCY_01='lxde'
    case "${LINUX_DISTRO}" in
    "debian")
        dpkg --configure -a
        auto_select_keyboard_layout
        DEPENDENCY_01="lxde-core lxterminal"
        ;;
        #############
    "redhat") DEPENDENCY_01='@lxde-desktop' ;;
        #############
    "arch") DEPENDENCY_01='lxde' ;;
        ############
    "void") DEPENDENCY_01='lxde' ;;
        #############
    "gentoo") DEPENDENCY_01='media-fonts/wqy-bitmapfont lxde-base/lxde-meta' ;;
        ##################
    "suse") DEPENDENCY_01='patterns-lxde-lxde' ;;
    "alpine")
        DEPENDENCY_01="lxsession"
        REMOTE_DESKTOP_SESSION='lxsession'
        ;;
    esac
    ###################
    beta_features_quick_install
    apt_purge_libfprint
    configure_vnc_xstartup
}
##########################
arch_linux_mate_warning() {
    printf "%s\n" "${RED}WARNING！${RESET}检测到您当前使用的是${YELLOW}Arch系发行版${RESET},并且处于${GREEN}proot容器${RESET}环境下！"
    printf "%s\n" "mate-session在当前容器环境下可能会出现${RED}屏幕闪烁${RESET}的现象"
    printf "%s\n" "按${GREEN}回车键${RESET}${BLUE}继续安装${RESET}"
    printf "%s\n" "${YELLOW}Do you want to continue?[Y/l/x/q/n]${RESET}"
    printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET},type n to return."
    printf "%s\n" "Type q to install lxqt,type l to install lxde,type x to install xfce."
    printf "%s\n" "按${GREEN}回车键${RESET}${RED}继续${RESET}安装mate，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
    printf "%s\n" "输${YELLOW}q${RESET}安装lxqt,输${YELLOW}l${RESET}安装lxde,输${YELLOW}x${RESET}安装xfce"
    read opt
    case $opt in
    y* | Y* | "") ;;

    n* | N*)
        printf "%s\n" "skipped."
        standand_desktop_installation
        ;;
    l* | L*)
        install_lxde_desktop
        ;;
    q* | Q*)
        install_lxqt_desktop
        ;;
    x* | X*)
        install_xfce4_desktop
        ;;
    *)
        printf "%s\n" "Invalid choice. skipped."
        standand_desktop_installation
        #beta_features
        ;;
    esac
    DEPENDENCY_01='mate mate-extra'
}
###############
install_mate_desktop() {
    REMOTE_DESKTOP_SESSION_01='mate-session'
    REMOTE_DESKTOP_SESSION_02='mate-panel'
    printf '%s\n' '即将为您安装fonts-noto-cjk（思源黑体）、fonts-noto-color-emoji、tightvncserver、mate-desktop-environment和mate-terminal等软件包'
    do_you_want_to_continue
    do_you_want_to_install_fcitx4
    DEPENDENCY_01='mate'
    case "${LINUX_DISTRO}" in
    "debian")
        DEPENDENCY_01='mate-desktop-environment mate-terminal'
        #apt autopurge -y ^libfprint
        #apt autoclean
        case ${DEBIAN_DISTRO} in
        ubuntu)
            if (whiptail --title "Mate or Ubuntu-MATE-full-desktop" --yes-button "mate" --no-button "ubuntu-mate" --yesno 'The former is more streamlined, and the latter includes some extra software of ubuntu-mate.\n前者为普通mate,后者为ubuntu-mate' 0 0); then
                printf ""
            else
                UBUNTU_DESKTOP=true
                DEPENDENCY_01="ubuntu-mate-desktop"
            fi
            ;;
        esac
        dpkg --configure -a
        auto_select_keyboard_layout
        apt clean
        apt autoclean
        #apt-mark hold gvfs
        #apt update
        #apt install -y udisks2 2>/dev/null
        #if [ "${TMOE_PROOT}" = 'true' ]; then
        #    printf "%s\n" "" >/var/lib/dpkg/info/udisks2.postinst
        #fi
        #apt-mark hold udisks2
        ;;
    "redhat") DEPENDENCY_01='@mate-desktop' ;;
    "arch")
        #if [ "${TMOE_PROOT}" = 'true' ]; then
        #    arch_linux_mate_warning
        #else
        DEPENDENCY_01='mate mate-extra'
        #fi
        ;;
    "gentoo") DEPENDENCY_01='mate-base/mate-desktop mate-base/mate' ;;
    "suse") DEPENDENCY_01='patterns-mate-mate' ;;
    "alpine")
        DEPENDENCY_01="mate-desktop-environment"
        REMOTE_DESKTOP_SESSION='mate-session'
        ;;
    esac
    ####################
    beta_features_quick_install
    apt_purge_libfprint
    configure_vnc_xstartup
}
#############
######################
#DEPENDENCY_02="dbus-x11 fonts-noto-cjk tightvncserver"
install_lxqt_desktop() {
    REMOTE_DESKTOP_SESSION_01='startlxqt'
    REMOTE_DESKTOP_SESSION_02='lxqt-session'
    DEPENDENCY_01="lxqt"
    printf '%s\n' '即将为您安装fonts-noto-cjk（思源黑体）、fonts-noto-color-emoji、lxqt-core、lxqt-config、qterminal和tightvncserver等软件包。'
    do_you_want_to_continue
    do_you_want_to_install_fcitx4
    case "${LINUX_DISTRO}" in
    "debian")
        DEPENDENCY_01="lxqt-core qterminal xfwm4 xfwm4-theme-breeze lxqt-config"
        case ${DEBIAN_DISTRO} in
        ubuntu)
            if (whiptail --title "Lxqt or Lubuntu-desktop" --yes-button "lxqt" --no-button "lubuntu" --yesno 'The former is more streamlined, and the latter includes some extra software of lubuntu.\n前者为普通lxqt,后者为lubuntu' 0 0); then
                printf ""
            else
                UBUNTU_DESKTOP=true
                DEPENDENCY_01="lubuntu-desktop"
            fi
            ;;
        esac
        dpkg --configure -a
        auto_select_keyboard_layout
        ;;
    "redhat") DEPENDENCY_01='@lxqt' ;;
    "arch") DEPENDENCY_01="lxqt xorg" ;;
    "gentoo") DEPENDENCY_01="lxqt-base/lxqt-meta" ;;
    "suse") DEPENDENCY_01="patterns-lxqt-lxqt" ;;
    "alpine")
        DEPENDENCY_01="openbox pcmfm rxvt-unicode tint2"
        REMOTE_DESKTOP_SESSION='openbox'
        ;;
    esac
    ####################
    beta_features_quick_install
    apt_purge_libfprint
    configure_vnc_xstartup
}
####################
kde_warning() {
    ICON_URL='https://gitee.com/ak2/icons/raw/master/plasma5.jpg'
    ICON_FILE_NAME='plasma5.jpg'
    download_and_cat_icon_img
    cat <<-'ENDofTable'
    KDE plasma 5桌面支持表格
    以下数据不适用于proot容器
  ╔═══╦════════════╦════════╦════════╦═════════╦
  ║   ║vnc/xserver ║        ║        ║         ║
  ║   ║----------- ║ x11vnc ║tigervnc║ xserver ║
  ║   ║System      ║        ║        ║         ║
  ║---║------------║--------║--------║---------║
  ║ 1 ║Debian sid  ║  ✓     ║    ✓   ║   ?     ║
  ║   ║            ║        ║        ║         ║
  ║---║------------║--------║--------║---------║
  ║   ║            ║        ║        ║         ║
  ║ 2 ║Ubuntu 20.10║  ✓     ║   ✓    ║   ?     ║
  ║---║------------║--------║--------║---------║
  ║   ║            ║        ║        ║         ║
  ║ 3 ║ArchLinux   ║   ✓    ║    ✓   ║   ✓     ║
  ║---║------------║--------║--------║---------║
  ║   ║            ║        ║        ║         ║
  ║ 4 ║Manjaro     ║  ✓     ║   ✓    ║   ?     ║
  ║---║------------║--------║--------║---------║
  ║   ║            ║        ║        ║         ║
  ║ 5 ║Fedora      ║  ✓     ║   ✓    ║   ?     ║
  ║---║------------║--------║--------║---------║
  ║   ║            ║        ║        ║         ║
  ║ 6 ║Alpine      ║  X     ║   ✓    ║   ?     ║
ENDofTable

    case "${TMOE_PROOT}" in
    true | no)
        printf "%s\n" "${RED}WARNING！${RESET}检测到您当前可能处于${BLUE}PROOT容器${RESET}环境下！"
        if ! grep -qi 'Bionic' /etc/os-release; then
            printf "%s\n" "${YELLOW}KDE plasma 5可能无法正常运行${RESET},建议您换用虚拟机或实体机进行安装。"
            printf "%s\n" "如需在proot容器中安装，请换用${YELLOW}旧版本${RESET}系统，例如${BLUE}Ubuntu 18.04${RESET}。"
            printf "%s\n" "您也可以换用chroot容器,再安装本桌面。"
        fi
        ;;
    false) printf "%s\n" "检测到您当前可能处于${BLUE}chroot容器${RESET}环境，尽情享受Plasma桌面带来的乐趣吧！" ;;
    esac
    tips_of_tiger_vnc_server
    do_you_want_to_continue
}
###############
install_kde_plasma5_desktop() {
    kde_warning
    do_you_want_to_install_fcitx4
    REMOTE_DESKTOP_SESSION_01='startplasma-x11'
    REMOTE_DESKTOP_SESSION_02='startkde'
    DEPENDENCY_01="plasma-desktop"
    printf '%s\n' '即将为您安装kde-plasma-desktop、tigervnc-standalone-server、fonts-noto-cjk（思源黑体）和fonts-noto-color-emoji等软件包。'
    case "${LINUX_DISTRO}" in
    "debian")
        #printf "默认为最小安装，如需安装kde完整套件，则请手动输${GREEN}apt install${RESET} ${PURPLE}kde-full${RESET}"
        #printf "在配置vnc服务的过程中，当提示tiger/tight时，请选择前者。"
        DEPENDENCY_01="kde-plasma-desktop"
        case ${DEBIAN_DISTRO} in
        ubuntu)
            if (whiptail --title "KDE-plasma or Kubuntu-desktop" --yes-button "KDE" --no-button "kubuntu" --yesno 'The former is more streamlined, and the latter\n includes some extra software of kubuntu.\n前者为普通KDE,后者为kubuntu' 0 0); then
                if (whiptail --title "kde-plasma or kde-full" --yes-button "minimal" --no-button "full" --yesno 'The former is minimal installation.\n前者为最简安装，后者为KDE全家桶' 0 0); then
                    DEPENDENCY_01="kde-plasma-desktop"
                else
                    DEPENDENCY_01="kde-full"
                fi
            else
                UBUNTU_DESKTOP=true
                DEPENDENCY_01="kubuntu-desktop"
            fi
            ;;
        *)
            if (whiptail --title "kde-plasma or kde-standard" --yes-button "plasma" --no-button "standard" --yesno 'The former is minimal installation\n前者为最简安装,后者为标准安装' 0 0); then
                DEPENDENCY_01="tigervnc-standalone-server kde-plasma-desktop"
            else
                if (whiptail --title "kde-standard or kde-full" --yes-button "standard" --no-button "full" --yesno 'The former is standard installation,and the latter\n includes some extra software of kde.\n前者包含KDE标准套件，后者为KDE全家桶' 0 0); then
                    DEPENDENCY_01="tigervnc-standalone-server kde-standard"
                else
                    DEPENDENCY_01="tigervnc-standalone-server kde-full"
                fi
            fi
            ;;
        esac
        dpkg --configure -a
        auto_select_keyboard_layout
        apt clean
        ;;
    "redhat")
        #yum groupinstall kde-desktop
        #dnf groupinstall -y "KDE" || yum groupinstall -y "KDE"
        #dnf install -y sddm || yum install -y sddm
        DEPENDENCY_01='@KDE'
        ;;
    "arch")
        DEPENDENCY_01="plasma-desktop xorg konsole sddm sddm-kcm"
        if (whiptail --title "kde-plasma or kde-standard" --yes-button "plasma" --no-button "plasma+apps" --yesno 'The former is more streamlined, and the latter\n includes some extra software of kde.\n前者为plasma基础桌面，后者包含kde全家桶' 0 0); then
            DEPENDENCY_01="plasma-desktop xorg konsole discover"
        else
            DEPENDENCY_01="plasma-meta plasma-wayland-session kde-applications-meta sddm sddm-kcm"
        fi
        #printf "%s\n" "如需安装额外软件包，请手动输pacman -S plasma plasma-wayland-session kde-applications"
        #kdebase
        #phonon-qt5
        #pacman -S --noconfirm sddm sddm-kcm
        #中文输入法
        #pacman -S fcitx fcitx-rime fcitx-im kcm-fcitx fcitx-sogoupinyin
        ;;
    "void") DEPENDENCY_01="kde" ;;
    "gentoo")
        PLASMAnoSystemd=$(eselect profile list | grep plasma | grep -v systemd | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2)
        eselect profile set ${PLASMAnoSystemd}
        dispatch-conf
        etc-update
        #emerge -auvDN --with-bdeps=y @world
        DEPENDENCY_01="plasma-desktop plasma-nm plasma-pa sddm konsole"
        ;;
    "suse") DEPENDENCY_01="-t pattern kde kde_plasma" ;;
    "alpine")
        DEPENDENCY_01="plasma-desktop breeze breeze-icons"
        REMOTE_DESKTOP_SESSION='startplasma-x11'
        ;;
    esac
    ####################
    beta_features_quick_install
    apt_purge_libfprint
    configure_vnc_xstartup
}
##################
tips_of_tiger_vnc_server() {
    printf "%s\n" "在您使用虚拟机安装本桌面的过程中，当提示tight/tiger vnc时,请选择tiger。若未弹出提示内容，则您可以前往本工具的vnc配置选项手动切换服务端，或使用x11vnc"
    printf "%s\n" "Since tightvnc may not be able to connect to this desktop normally, please choose tiger or x11vnc server."
}
##################
tmoe_desktop_warning() {
    case "${TMOE_PROOT}" in
    true) printf "%s\n" "${RED}WARNING！${RESET}检测到您当前可能处于${BLUE}PROOT容器${RESET}环境下！${YELLOW}本桌面可能无法正常运行${RESET},建议您换用虚拟机或实体机进行安装。" ;;
    false) printf "%s\n" "检测到您当前可能处于${BLUE}chroot容器${RESET}环境，不建议在当前环境下安装本桌面。" ;;
    no) printf "%s\n" "检测到您无权读取${YELLOW}/proc${RESET}的部分数据，${RED}请勿安装${RESET}" ;;
    esac
    tips_of_tiger_vnc_server
    do_you_want_to_continue
}
###############
install_ukui_desktop() {
    tmoe_desktop_warning
    case ${TMOE_PROOT} in
    true | no)
        REMOTE_DESKTOP_SESSION_01='ukui-panel'
        REMOTE_DESKTOP_SESSION_02='ukui-session'
        ;;
    false | *)
        REMOTE_DESKTOP_SESSION_01='ukui-session'
        REMOTE_DESKTOP_SESSION_02='ukui-panel'
        ;;
    esac

    DEPENDENCY_01="ukui-session-manager"
    printf '%s\n' '即将为您安装fonts-noto-cjk（思源黑体）、fonts-noto-color-emoji、ukui-session-manager、ukui-menu、ukui-control-center、ukui-screensaver、ukui-themes、peony和tightvncserver等软件包。'
    case "${LINUX_DISTRO}" in
    "debian")
        DEPENDENCY_01='ukui-session-manager ukui-menu ukui-control-center ukui-screensaver ukui-themes peony'
        case ${DEBIAN_DISTRO} in
        ubuntu)
            if (whiptail --title "ukui or ubuntukylin-desktop" --yes-button "ukui" --no-button "kylin" --yesno 'The former is more streamlined, and the latter\n includes some extra software of  ubuntu-kylin.\n前者为普通ukui,后者为ubuntukylin-desktop' 0 0); then
                printf "%s" ""
            else
                DEPENDENCY_01="ubuntukylin-desktop"
            fi
            ;;
        esac
        dpkg --configure -a
        auto_select_keyboard_layout
        ;;
    "arch") DEPENDENCY_01='ukui' ;;
    *)
        printf "%s\n" "Sorry,未适配${LINUX_DISTRO}"
        press_enter_to_return
        ${RETURN_TO_WHERE}
        ;;
    esac
    ####################
    beta_features_quick_install
    apt_purge_libfprint
    configure_vnc_xstartup
}
##############
install_budgie_desktop() {
    tmoe_desktop_warning
    case ${TMOE_PROOT} in
    true | no)
        REMOTE_DESKTOP_SESSION_01='budgie-panel'
        REMOTE_DESKTOP_SESSION_02='budgie-wm'
        ;;
    false | *)
        REMOTE_DESKTOP_SESSION_01='budgie-desktop'
        REMOTE_DESKTOP_SESSION_02='budgie-panel'
        ;;
    esac

    DEPENDENCY_01="budgie-desktop"
    printf '%s\n' '即将为您安装fonts-noto-cjk（思源黑体）、fonts-noto-color-emoji、budgie-desktop、budgie-indicator-applet和tightvncserver等软件包。'
    case ${LINUX_DISTRO} in
    debian)
        dpkg --configure -a
        auto_select_keyboard_layout
        DEPENDENCY_01='budgie-desktop budgie-indicator-applet'
        ;;
    arch | void) DEPENDENCY_01='budgie-desktop' ;;
    *)
        printf "%s\n" "Sorry,暂未适配${LINUX_DISTRO}"
        press_enter_to_return
        ${RETURN_TO_WHERE}
        ;;
    esac
    ####################
    beta_features_quick_install
    apt_purge_libfprint
    configure_vnc_xstartup
}
##############
gnome3_warning() {
    case "${TMOE_PROOT}" in
    true) printf "%s\n" "${RED}WARNING！${RESET}检测到您当前可能处于${BLUE}PROOT容器${RESET}环境下！${YELLOW}GNOME3可能无法正常运行${RESET},建议您换用虚拟机或实体机进行安装。" ;;
    false) printf "%s\n" "检测到您当前可能处于${BLUE}chroot容器${RESET}环境，不建议在当前环境下安装本桌面。" ;;
    no) printf "%s\n" "检测到您无权读取${YELLOW}/proc${RESET}的部分数据，${RED}请勿安装${RESET}" ;;
    esac
    tips_of_tiger_vnc_server
    do_you_want_to_continue
}
###############
install_gnome3_desktop() {
    if [ $(command -v neofetch) ]; then
        neofetch --logo --ascii_distro GNOME
    fi
    gnome3_warning
    do_you_want_to_install_fcitx4
    case ${TMOE_PROOT} in
    true | no)
        REMOTE_DESKTOP_SESSION_01='gnome-panel'
        REMOTE_DESKTOP_SESSION_02='gnome-session'
        ;;
    false | *)
        REMOTE_DESKTOP_SESSION_01='gnome-session'
        REMOTE_DESKTOP_SESSION_02='gnome-panel'
        ;;
    esac
    DEPENDENCY_01="gnome"
    printf '%s\n' '即将为您安装fonts-noto-cjk（思源黑体）、fonts-noto-color-emoji、gnome-session、gnome-menus、gnome-tweak-tool、gnome-shell和tightvncserver等软件包。'
    case "${LINUX_DISTRO}" in
    "debian")
        #aptitude install -y task-gnome-desktop || apt install -y task-gnome-desktop
        #apt install --no-install-recommends xorg gnome-session gnome-menus gnome-tweak-tool gnome-shell || aptitude install -y gnome-core
        case ${DEBIAN_DISTRO} in
        ubuntu)
            if (whiptail --title "gnome-core or ubuntu-desktop" --yes-button "gnome" --no-button "ubuntu-desktop" --yesno 'The former is more streamlined, and the latter\n includes some extra software of gnome.\n前者为gnome基础桌面，后者为ubuntu-desktop' 0 0); then
                DEPENDENCY_01='--no-install-recommends xorg gnome-menus gnome-tweak-tool gnome-core gnome-shell gnome-session'
            else
                UBUNTU_DESKTOP=true
                DEPENDENCY_01="ubuntu-desktop"
            fi
            ;;
        *)
            if (whiptail --title "gnome-core or gnome-extra" --yes-button "gnome-core" --no-button "gnome-extra" --yesno 'The former is more streamlined, and the latter\n includes some extra software of gnome.\n前者为gnome基础桌面，后者包含gnome软件包套件' 0 0); then
                DEPENDENCY_01='--no-install-recommends xorg gnome-menus gnome-tweak-tool gnome-core gnome-shell-extension-dashtodock gnome-shell gnome-session'
            else
                DEPENDENCY_01='task-gnome-desktop'
            fi
            ;;
        esac
        dpkg --configure -a
        auto_select_keyboard_layout
        #若不包含gnome-core，则为最简化安装
        ;;
    "redhat")
        #yum groupinstall "GNOME Desktop Environment"
        #dnf groupinstall -y "GNOME" || yum groupinstall -y "GNOME"
        DEPENDENCY_01='@GNOME'
        ;;
    "arch")
        if (whiptail --title "gnome or gnome-extra" --yes-button "gnome" --no-button "gnome-extra" --yesno 'The former is more streamlined, and the latter\n includes some extra software of gnome.\n前者为gnome基础桌面，后者包含gnome全家桶' 0 0); then
            DEPENDENCY_01='gnome'
        else
            DEPENDENCY_01='gnome-extra gnome'
        fi
        ;;
    "gentoo")
        GNOMEnoSystemd=$(eselect profile list | grep gnome | grep -v systemd | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2)
        eselect profile set ${GNOMEnoSystemd}
        #emerge -auvDN --with-bdeps=y @world
        dispatch-conf
        etc-update
        DEPENDENCY_01='gnome-shell gdm gnome-terminal'
        ;;
    "suse") DEPENDENCY_01='patterns-gnome-gnome_x11' ;;
    "alpine")
        DEPENDENCY_01="gnome"
        REMOTE_DESKTOP_SESSION='gnome-session'
        ;;
    esac
    ####################
    beta_features_quick_install
    apt_purge_libfprint
    configure_vnc_xstartup
}
##################
cinnamon_warning() {
    case "${TMOE_PROOT}" in
    true) printf "%s\n" "${RED}WARNING！${RESET}检测到您当前可能处于${BLUE}PROOT容器${RESET}环境下！${YELLOW}cinnamon可能无法正常运行${RESET},建议您换用虚拟机或实体机进行安装。" ;;
    false) printf "%s\n" "检测到您当前可能处于${BLUE}chroot容器${RESET}环境，不建议在当前环境下安装本桌面。" ;;
    no) printf "%s\n" "检测到您无权读取${YELLOW}/proc${RESET}的部分数据，${RED}请勿安装${RESET}" ;;
    esac
    tips_of_tiger_vnc_server
    do_you_want_to_continue
}
###############
install_cinnamon_desktop() {
    cinnamon_warning
    case ${TMOE_PROOT} in
    true | no)
        REMOTE_DESKTOP_SESSION_01='cinnamon-panel'
        REMOTE_DESKTOP_SESSION_02='cinnamon-session'
        ;;
    false | *)
        REMOTE_DESKTOP_SESSION_01='cinnamon-session'
        REMOTE_DESKTOP_SESSION_02='cinnamon-launcher'
        ;;
    esac
    DEPENDENCY_01="cinnamon"
    printf '%s\n' '即将为您安装fonts-noto-cjk（思源黑体）、fonts-noto-color-emoji、cinnamon和tightvncserver等软件包。'
    case "${LINUX_DISTRO}" in
    "debian")
        dpkg --configure -a
        auto_select_keyboard_layout
        DEPENDENCY_01="--no-install-recommends cinnamon cinnamon-desktop-environment"
        ;;
    "redhat") DEPENDENCY_01='@Cinnamon Desktop' ;;
    "arch") DEPENDENCY_01="sddm cinnamon xorg" ;;
    "gentoo") DEPENDENCY_01="gnome-extra/cinnamon gnome-extra/cinnamon-desktop gnome-extra/cinnamon-translations" ;;
    "suse") DEPENDENCY_01="cinnamon cinnamon-control-center" ;;
    "alpine") DEPENDENCY_01="adapta-cinnamon" ;;
    esac
    ##############
    beta_features_quick_install
    apt_purge_libfprint
    configure_vnc_xstartup
}
####################
deepin_desktop_warning() {
    case "${ARCH_TYPE}" in
    "i386" | "amd64") ;;
    *)
        printf "%s\n" "非常抱歉，深度桌面不支持您当前的架构。"
        printf "%s\n" "建议您在换用x86_64或i386架构的设备后，再来尝试。"
        printf "%s\n" "${YELLOW}警告！deepin桌面可能无法正常运行${RESET}"
        arch_does_not_support
        tmoe_virtual_machine_desktop
        ;;
    esac
}
#################
dde_old_version() {
    if [ ! $(command -v gpg) ]; then
        DEPENDENCY_01="gnupg"
        DEPENDENCY_02=""
        printf "%s\n" "${GREEN} ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
        printf "%s\n" "即将为您安装gpg..."
        ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCY_01}
    fi
    DEPENDENCY_01="deepin-desktop"

    case "${DEBIAN_DISTRO}" in
    "ubuntu") add-apt-repository ppa:leaeasy/dde ;;
    *)
        cd /etc/apt/
        if ! grep -q '^deb.*deepin' sources.list.d/deepin.list 2>/dev/null; then
            cat >/etc/apt/sources.list.d/deepin.list <<-'EOF'
				   #如需使用apt upgrade命令，请禁用deepin软件源,否则将有可能导致系统崩溃。
					deb [by-hash=force] https://mirrors.bfsu.edu.cn/deepin unstable main contrib non-free
			EOF
        fi
        ;;
    esac
    wget https://mirrors.bfsu.edu.cn/deepin/project/deepin-keyring.gpg
    gpg --import deepin-keyring.gpg
    gpg --export --armor 209088E7 | apt-key add -
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 425956BB3E31DF51
    dpkg --configure -a
    apt update
    auto_select_keyboard_layout
    aptitude install -y dde
    sed -i 's/^deb/#&/g' /etc/apt/sources.list.d/deepin.list
    apt update
}
################
ubuntu_dde_distro_code() {
    aria2c --no-conf --allow-overwrite=true -o .ubuntu_ppa_tmoe_cache 'http://ppa.launchpad.net/ubuntudde-dev/stable/ubuntu/dists/'
    TARGET_CODE=$(cat .ubuntu_ppa_tmoe_cache | grep '\[DIR' | tail -n 1 | cut -d '=' -f 5 | cut -d '/' -f 1 | cut -d '"' -f 2)
    if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
        if [ "$(cat .ubuntu_ppa_tmoe_cache | grep '\[DIR' | grep "${SOURCELISTCODE}")" ]; then
            TARGET_CODE=${SOURCELISTCODE}
        fi
    fi
    rm -f .ubuntu_ppa_tmoe_cache
}
####################
deepin_desktop_debian() {
    if [ ! $(command -v add-apt-repository) ]; then
        apt update
        apt install -y software-properties-common
    fi
    add-apt-repository ppa:ubuntudde-dev/stable
    #84C8BB5C8E93FFC280EAC512C27BE3D0F0FE09DA
    DEV_TEAM_NAME='ubuntudde-dev'
    PPA_SOFTWARE_NAME='stable'
    if [ "${DEBIAN_DISTRO}" != 'ubuntu' ]; then
        get_ubuntu_ppa_gpg_key
    else
        SOURCELISTCODE=$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2 | head -n 1)
    fi
    ubuntu_dde_distro_code
    check_ubuntu_ppa_list
    sed -i "s@ ${CURRENT_UBUNTU_CODE}@ ${TARGET_CODE}@g" ${PPA_LIST_FILE}
}
###################
dde_warning() {
    ICON_URL='https://gitee.com/ak2/icons/raw/master/deepin.jpg'
    ICON_FILE_NAME='deepin.jpg'
    download_and_cat_icon_img

    cat <<-'ENDofTable'
    Deepin桌面支持表格

    1.因proot无权启动dbus-daemon --system,故不支持proot容器。
    2.已测试过的系统：
    ubuntu 20.04和fedora32 arm64 chroot容器(宿主Android)
    deepin 15.5 arm64 chroot容器(宿主Android)
    archlinux amd64 qemu虚拟机(宿主Debian)+chroot容器(宿主WSL)
    3.本表格有效期截至2020年10月中旬,仅供参考，后期会发生变更。
    4.以下数据仅代表tmoe-linux tool所安装的dde，您可自行编译源代码，并修复bug。
  ╔═══╦════════════╦════════╦════════╦═════════╦
  ║   ║vnc/xserver ║        ║        ║         ║
  ║   ║----------- ║ x11vnc ║tigervnc║ xserver ║
  ║   ║System      ║        ║        ║         ║
  ║---║------------║--------║--------║---------║
  ║ 1 ║ Ubuntu     ║  ✓     ║    ？  ║   ？    ║ 
  ║   ║ 20.04 LTS  ║        ║        ║         ║
  ║---║------------║--------║--------║---------║
  ║   ║Fedora      ║        ║        ║         ║ 
  ║ 2 ║ 32         ║  ✓     ║   ✓    ║   ？    ║
  ║---║------------║--------║--------║---------║
  ║   ║ArchLinux   ║        ║        ║         ║ 
  ║ 3 ║ arm64      ║   X    ║    X   ║    X    ║
  ║---║------------║--------║--------║---------║
  ║   ║ArchLinux   ║        ║        ║         ║ 
  ║ 4 ║ amd64      ║  ✓     ║   ✓    ║   ？    ║ 
  ║---║------------║--------║--------║---------║
  ║   ║Deepin      ║        ║        ║         ║ 
  ║ 5 ║ arm64      ║  ✓     ║   ✓    ║   ？    ║ 
ENDofTable

    cat <<-EOF
    若您使用的是deepin，则可直接从软件源安装。
    对于除deepin外的其他debian系发行版，本工具调用的是${BLUE}Ubuntu DDE${RESET}的软件源,而非${YELLOW}UOS${RESET}。
    您可以使用新版的Ubuntu LTS系统来安装DDE，旧版系统可能存在依赖关系问题。
    过新的系统亦存在此问题,例如debian sid。
    而对于其他系发行版，请尽量选择最新的发行版。
    例如红帽系,请选fedora,勿选centos。
    若您需要在arm64容器环境中运行,则建议您使用fedora。
    若您需要在x64容器环境中运行，则建议您使用arch。
EOF

    case "${TMOE_PROOT}" in
    true) printf "%s\n" "${RED}WARNING！${RESET}检测到您当前可能处于${BLUE}PROOT容器${RESET}环境下！${YELLOW}DDE可能无法正常运行${RESET},您可以换用deepin或fedora chroot容器进行安装。" ;;
    false)
        printf "%s\n" "检测到您当前可能处于${BLUE}chroot容器${RESET}环境"
        case ${LINUX_DISTRO} in
        redhat) printf "%s\n" "尽情享受dde带来的乐趣吧！" ;;
        debian | *) printf "%s\n" "若无法运行，则请更换为fedora容器" ;;
        esac
        ;;
    no) printf "%s\n" "检测到您无权读取${YELLOW}/proc${RESET}的部分数据，${RED}请勿安装${RESET}" ;;
    esac
    printf '%s\n' "即将为您安装dde、fonts-noto-cjk（思源黑体）、fonts-noto-color-emoji软件包。"
    tips_of_tiger_vnc_server
    do_you_want_to_continue
}
################
install_deepin_desktop() {
    #deepin_desktop_warning
    dde_warning
    REMOTE_DESKTOP_SESSION_01='startdde'
    #REMOTE_DESKTOP_SESSION_02='/usr/sbin/deepin-session'
    REMOTE_DESKTOP_SESSION_02='dde-launcher'
    DEPENDENCY_01="deepin-desktop"
    case "${LINUX_DISTRO}" in
    "debian")
        case ${DEBIAN_DISTRO} in
        deepin) DEPENDENCY_01="dde" ;;
        *)
            deepin_desktop_debian
            DEPENDENCY_01="ubuntudde-dde deepin-terminal"
            ;;
        esac
        dpkg --configure -a
        auto_select_keyboard_layout
        apt clean
        ;;
    "redhat") DEPENDENCY_01='deepin-desktop' ;;
    "arch")
        #pacman -S --noconfirm deepin-kwin
        #pacman -S --noconfirm file-roller evince
        #rm -v ~/.pam_environment 2>/dev/null
        DEPENDENCY_01="deepin xorg deepin-extra lightdm lightdm-deepin-greeter"
        case ${ARCH_TYPE} in
        amd64)
            printf "%s\n" "clutter 与 deepin-clutter 有冲突 ; cogl 与 deepin-cogl 有冲突。"
            printf "%s\n" "您可以使用${GREEN}pacman -Rs ${BLUE}clutter cogl${RESET}来解决"
            printf "%s\n" "若已解决，则请忽略上述提示。"
            ;;
        *)
            #DEPENDENCY_01="deepin xorg"
            #printf "%s\n" "如需安装额外组件，请手动输${GREEN}pacman -Syu${RESET} ${BLUE}deepin-extra lightdm lightdm-deepin-greeter${RESET}"
            printf "%s\n" "${RED}WARNING！${RESET}检测到您使用的是arch系发行版，${ARCH_TYPE}的仓库可能缺失了deepin-desktop-base，建议您换用x64架构的设备。"
            printf "%s\n" "若您需要在arm64容器中安装dde,则您可以换用fedora_arm64 chroot容器。"
            do_you_want_to_continue
            ;;
        esac
        ;;
    esac
    ####################
    beta_features_quick_install
    apt_purge_libfprint
    configure_vnc_xstartup
}
############################
set_default_xfce_icon_theme() {
    dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s ${XFCE_ICON_NAME} 2>/dev/null
    case ${HOME} in
    /root) ;;
    *) chown -Rv ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${HOME}/.config/xfce4 ;;
    esac

}
###############
creat_update_icon_caches() {
    cd /usr/local/bin/
    cat >update-icon-caches <<-'EndofFile'
		#!/bin/sh
		case "$1" in
		    ""|-h|--help)
		        printf "%s\n" "Usage: $0 directory [ ... ]"
		        exit 1
		        ;;
		esac

		for dir in "$@"; do
		    if [ ! -d "$dir" ]; then
		        continue
		    fi
		    if [ -f "$dir"/index.theme ]; then
		        if ! gtk-update-icon-cache --force --quiet "$dir"; then
		            printf "%s\n" "WARNING: icon cache generation failed for $dir"
		        fi
		    else
		        rm -f "$dir"/icon-theme.cache
		        rmdir -p --ignore-fail-on-non-empty "$dir"
		    fi
		done
		exit 0
	EndofFile
    chmod +x update-icon-caches
}
check_update_icon_caches_sh() {
    if [ ! $(command -v update-icon-caches) ]; then
        creat_update_icon_caches
    fi
}
##############
tmoe_desktop_beautification() {
    DEPENDENCY_01=''
    RETURN_TO_WHERE='tmoe_desktop_beautification'
    check_zstd
    BEAUTIFICATION=$(whiptail --title "beautification" --menu \
        "你想要如何美化桌面？\nHow do you want to beautify the DE? " 0 50 0 \
        "1" "🍨 themes:主题(你有一双善于发现美的眼睛)" \
        "2" "🎀 icon-theme:图标包(点缀出惊艳绝伦)" \
        "3" "🍹 wallpaper:壁纸(感受万物之息)" \
        "4" "↗ mouse cursor(璀璨夺目的鼠标指针)" \
        "5" "💫 dock栏(plank)" \
        "6" "🎇 compiz(如花火般绚烂)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${BEAUTIFICATION}" in
    0 | "") tmoe_linux_tool_menu ;;
    1) configure_theme ;;
    2) download_icon_themes ;;
    3) download_wallpapers ;;
    4) configure_mouse_cursor ;;
    5) install_docky ;;
    6) install_compiz ;;
    esac
    #        "5" "⛈ conky(显示资源占用情况,还有...天气预报)" \    5) install_conky ;;
    ##########################
    press_enter_to_return
    tmoe_desktop_beautification
}
###########
configure_conky() {
    cd ${HOME}
    mkdir -pv github
    cd github
    git clone --depth=1 https://github.com/zagortenay333/Harmattan.git || git clone --depth=1 git://github.com/zagortenay333/Harmattan.git
    printf "%s\n" "进入${HOME}/github/Harmattan"
    printf "%s\n" "执行bash preview"
    printf '%s\n' 'To get more help info,please go to github.'
    printf '%s\n' 'https://github.com/zagortenay333/Harmattan'
}
###############
install_conky() {
    DEPENDENCY_01="bc jq"
    DEPENDENCY_02="conky"
    beta_features_quick_install
    configure_conky
    if [ -e "${HOME}/github/Harmattan" ]; then
        configure_conky
    fi
}
###########
install_docky() {
    DEPENDENCY_01=""
    DEPENDENCY_02="plank"
    beta_features_quick_install
}
###########
install_compiz() {
    DEPENDENCY_01="emerald emerald-themes"
    DEPENDENCY_02="compiz"
    beta_features_quick_install
}
##################
configure_theme() {
    #\n下载完成后，您需要手动修改外观设置中的样式和图标。\n注：您需修改窗口管理器样式才能解决标题栏丢失的问题。
    check_update_icon_caches_sh
    cd /tmp
    RETURN_TO_WHERE='configure_theme'
    INSTALL_THEME=$(whiptail --title "桌面环境主题" --menu \
        "您想要下载哪个主题？\n Which theme do you want to download? " 0 50 0 \
        "1" "🌈 XFCE-LOOK-parser主题链接解析器" \
        "2" "⚡ local-theme-installer本地主题安装器" \
        "3" "🎭 win10:kali卧底模式主题" \
        "4" "🚥 MacOS:Mojave" \
        "5" "🍎 MacOS:Big Sur" \
        "6" "🎋 breeze:plasma桌面微风gtk+版主题" \
        "7" "Kali:Flat-Remix-Blue主题" \
        "8" "ukui:国产优麒麟ukui桌面主题" \
        "9" "arc:融合透明元素的平面主题" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ########################
    case "${INSTALL_THEME}" in
    0 | "") tmoe_desktop_beautification ;;
    1) xfce_theme_parsing ;;
    2) local_theme_installer ;;
    3) install_kali_undercover ;;
    4) download_macos_mojave_theme ;;
    5) download_macos_bigsur_theme ;;
    6) install_breeze_theme ;;
    7) download_kali_theme ;;
    8) download_ukui_theme ;;
    9) install_arc_gtk_theme ;;
    esac
    ######################################
    press_enter_to_return
    configure_theme
}
#######################
local_theme_installer() {
    FILE_EXT_01='tar.gz'
    FILE_EXT_02='tar.xz'
    #where_is_tmoe_file_dir
    START_DIR='/tmp'
    IMPORTANT_TIPS='您可以选择已经下载至本地的主题或图标压缩包'
    tmoe_file_manager
    if [ -z ${SELECTION} ]; then
        printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
    else
        printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
        ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
        TMOE_THEME_ITEM=${TMOE_FILE_ABSOLUTE_PATH}
        tar -tf ${TMOE_THEME_ITEM} | cut -d '/' -f 1 | sort -u
        do_you_want_to_continue
        tmoe_theme_installer
    fi
}
#################
check_theme_url() {
    if [ "$(printf '%s\n' "${THEME_TMOE_URL}" | grep -v 'xfce-look.org')" ]; then
        printf "%s\n" "原始链接中不包含xfce-look，可能会出现错误。"
    fi

    if [ "$(printf '%s\n' "${THEME_TMOE_URL}" | grep 'XFCE/p')" ]; then
        TMOE_THEME_STATUS='检测到当前文件可能是图标包'
    elif [ "$(printf '%s\n' "${THEME_TMOE_URL}" | grep 'Gnome/p')" ]; then
        TMOE_THEME_STATUS='检测到当前文件可能是Gnome图标包'
    else
        TMOE_THEME_STATUS='主题和图标包的解压路径不同，请手动判断'
    fi

    #当未添加http时，将自动修复。
    if [ "$(printf '%s\n' "${THEME_TMOE_URL}" | egrep 'www')" ] && [ ! "$(printf '%s\n' "${THEME_TMOE_URL}" | grep 'http')" ]; then
        THEME_TMOE_URL=$(printf '%s\n' "${THEME_TMOE_URL}" | sed 's@www@https://&@')
    fi
}
###############
xfce_theme_parsing() {
    THEME_TMOE_URL=$(whiptail --inputbox "请输入主题链接Please enter a url\n例如https://gnome-look.org/xx或https://xfce-look.org/xx" 0 50 --title "Tmoe xfce&gnome theme parser" 3>&1 1>&2 2>&3)

    if [ "$?" != "0" ]; then
        configure_theme
    elif [ -z ${THEME_TMOE_URL} ]; then
        printf "%s\n" "请输入有效的url"
        printf "%s\n" "Please enter a valid url."
    else
        check_theme_url
    fi

    cd /tmp/
    printf "%s\n" "正在下载网页文件.."
    printf "%s\n" "Downloading index.html..."
    aria2c --no-conf --allow-overwrite=true -o .theme_index_cache_tmoe.html ${THEME_TMOE_URL}

    cat .theme_index_cache_tmoe.html | sed 's@,@\n@g' | egrep 'tar.xz|tar.gz' | grep '"title"' | sed 's@"@ @g' | awk '{print $3}' | sort -um >.tmoe-linux_cache.01
    THEME_LINE=$(cat .tmoe-linux_cache.01 | wc -l)
    cat .theme_index_cache_tmoe.html | sed 's@,@\n@g' | sed 's@%2F@/@g' | sed 's@%3A@:@g' | sed 's@%2B@+@g' | sed 's@%3D@=@g' | sed 's@%23@#@g' | sed 's@%26@\&@g' | egrep '"downloaded_count"' | sed 's@"@ @g' | awk '{print $3}' | head -n ${THEME_LINE} | sed 's/ /-/g' | sed 's/$/次/g' >.tmoe-linux_cache.02
    TMOE_THEME_FILE_LIST=$(paste -d ' ' .tmoe-linux_cache.01 .tmoe-linux_cache.02 | sed ":a;N;s/\n/ /g;ta")
    rm -f .tmoe-linux_cache.0*

    TMOE_THEME_ITEM=$(whiptail --title "THEME" --menu \
        "您想要下载哪个主题？\nWhich theme do you want to download?\n文件名称                 下载次数(可能有严重偏差)" 0 0 0 \
        ${TMOE_THEME_FILE_LIST} \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    case ${TMOE_THEME_ITEM} in
    0 | "") configure_theme ;;
    esac
    DOWNLOAD_FILE_URL=$(cat .theme_index_cache_tmoe.html | sed 's@,@\n@g' | sed 's@%2F@/@g' | sed 's@%3A@:@g' | sed 's@%2B@+@g' | sed 's@%3D@=@g' | sed 's@%23@#@g' | sed 's@%26@\&@g' | egrep 'tar.xz|tar.gz' | grep '"url"' | grep ${TMOE_THEME_ITEM} | sed 's@"@ @g' | awk '{print $3}' | sort -um | head -n 1)
    DOWNLOAD_PATH=/tmp
    aria2c_download_normal_file_s3
    tmoe_theme_installer
}
###################
tmoe_theme_installer() {
    if (whiptail --title "Please choose the file type" --yes-button 'THEME主题' --no-button 'ICON图标包' --yesno "Is this file a theme or an icon pack?\n这个文件是主题包还是图标包呢?(っ °Д °)\n${TMOE_THEME_STATUS}" 0 50); then
        EXTRACT_FILE_PATH='/usr/share/themes'
        check_tar_ext_format
    else
        EXTRACT_FILE_PATH='/usr/share/icons'
        check_tar_ext_format
        cd ${EXTRACT_FILE_PATH}
        update-icon-caches ${EXTRACT_FILE_FOLDER} &
        cd /tmp
    fi
    printf "%s\n" "解压完成，如需删除该主题，请手动输${YELLOW}cd ${EXTRACT_FILE_PATH} ; ls ;rm -rv ${EXTRACT_FILE_FOLDER} ${RESET}"
    printf "%s\n" "是否${RED}删除${RESET}主题压缩包${BLUE}原文件？${RESET}"
    printf "%s\n" "Do you want to delete the original compressed file？${PURPLE}[Y/n]${RESET}"
    do_you_want_to_continue
    rm -fv ${TMOE_THEME_ITEM} .theme_index_cache_tmoe.html
}
#########################
install_arc_gtk_theme() {
    DEPENDENCY_01="arc-icon-theme"
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02="arc-gtk-theme"
    else
        DEPENDENCY_02="arc-theme"
    fi
    beta_features_quick_install
}
################
download_icon_themes() {
    check_update_icon_caches_sh
    cd /tmp
    RETURN_TO_WHERE='download_icon_themes'
    INSTALL_THEME=$(whiptail --title "图标包" --menu \
        "您想要下载哪个图标包？\n Which icon-theme do you want to download? " 0 50 0 \
        "1" "win10x:更新颖的UI设计" \
        "2" "UOS:国产统一操作系统图标包" \
        "3" "pixel:raspberrypi树莓派" \
        "4" "paper:简约、灵动、现代化的图标包" \
        "5" "papirus:优雅的图标包,基于paper" \
        "6" "numix:modern现代化" \
        "7" "moka:简约一致的美学" \
        "0" "Back to the main menu 返回主菜单" \
        3>&1 1>&2 2>&3)
    ########################
    case "${INSTALL_THEME}" in
    0 | "") tmoe_desktop_beautification ;;
    1) download_win10x_theme ;;
    2) download_uos_icon_theme ;;
    3) download_raspbian_pixel_icon_theme ;;
    4) download_paper_icon_theme ;;
    5) download_papirus_icon_theme ;;
    6) install_numix_theme ;;
    7) install_moka_theme ;;
    esac
    ######################################
    press_enter_to_return
    download_icon_themes
}
###################
install_moka_theme() {
    DEPENDENCY_01=""
    DEPENDENCY_02="moka-icon-theme"
    beta_features_quick_install
}
################
install_numix_theme() {
    DEPENDENCY_01="numix-gtk-theme"
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02="numix-circle-icon-theme-git"
    else
        DEPENDENCY_02="numix-icon-theme-circle"
    fi
    beta_features_quick_install
}
################
xubuntu_wallpapers() {
    RETURN_TO_WHERE='xubuntu_wallpapers'
    INSTALL_THEME=$(whiptail --title "桌面壁纸" --menu \
        "您想要下载哪套xubuntu壁纸包？\n Which xubuntu wallpaper-pack do you want to download? " 0 50 0 \
        "1" "xubuntu-trusty" \
        "2" "xubuntu-xenial" \
        "3" "xubuntu-bionic" \
        "4" "xubuntu-focal" \
        "0" "Back to the main menu 返回主菜单" \
        3>&1 1>&2 2>&3)
    ########################
    case "${INSTALL_THEME}" in
    0 | "") ubuntu_wallpapers_and_photos ;;
    1)
        GREP_NAME_02='xubuntu-community-wallpapers-trusty'
        CUSTOM_WALLPAPER_NAME='xubuntu-community-artwork/trusty'
        download_xubuntu_wallpaper
        ;;
    2)
        GREP_NAME_02='xubuntu-community-wallpapers-xenial'
        CUSTOM_WALLPAPER_NAME='xubuntu-community-artwork/xenial'
        download_xubuntu_wallpaper
        ;;
    3)
        GREP_NAME_02='xubuntu-community-wallpapers-bionic'
        CUSTOM_WALLPAPER_NAME='xubuntu-community-artwork/bionic'
        download_xubuntu_wallpaper
        ;;
    4)
        GREP_NAME_02='xubuntu-community-wallpapers-focal'
        CUSTOM_WALLPAPER_NAME='xubuntu-community-artwork/focal'
        download_xubuntu_wallpaper
        ;;
    esac
    ######################################
    press_enter_to_return
    xubuntu_wallpapers
}
###############
download_xubuntu_wallpaper() {
    if [ -d "${HOME}/图片" ]; then
        mkdir -pv ${HOME}/图片/xubuntu-community-artwork
    else
        mkdir -pv ${HOME}/Pictures/xubuntu-community-artwork
    fi
    THEME_NAME='xubuntu_wallpaper'
    WALLPAPER_NAME='xfce4/backdrops'
    GREP_NAME_01='all.deb'
    THEME_URL='https://mirrors.bfsu.edu.cn/ubuntu/pool/universe/x/xubuntu-community-artwork/'
    grep_theme_model_03
    move_wallpaper_model_01
}
###############
ubuntu_gnome_walllpapers() {
    RETURN_TO_WHERE='ubuntu_gnome_walllpapers'
    #cat index.html | sort -u | grep 20.04 | grep all.deb | cut -d '=' -f 4 | cut -d '"' -f 2 |cut -d '_' -f 1 | cut -d '-' -f 3
    INSTALL_THEME=$(whiptail --title "UBUNTU壁纸" --menu \
        "Download ubuntu wallpaper-packs" 0 50 0 \
        "0" "Back返回" \
        "1" "artful" \
        "2" "bionic" \
        "3" "cosmic" \
        "4" "disco" \
        "5" "eoan" \
        "6" "focal" \
        "7" "karmic" \
        "8" "lucid" \
        "9" "maverick" \
        "10" "natty" \
        "11" "oneiric" \
        "12" "precise" \
        "13" "quantal" \
        "14" "raring" \
        "15" "saucy" \
        "16" "trusty" \
        "17" "utopic" \
        "18" "vivid" \
        "19" "wily" \
        "20" "xenial" \
        "21" "yakkety" \
        "22" "zesty" \
        3>&1 1>&2 2>&3)
    ########################
    case "${INSTALL_THEME}" in
    0 | "") ubuntu_wallpapers_and_photos ;;
    1) UBUNTU_CODE="artful" ;;
    2) UBUNTU_CODE="bionic" ;;
    3) UBUNTU_CODE="cosmic" ;;
    4) UBUNTU_CODE="disco" ;;
    5) UBUNTU_CODE="eoan" ;;
    6) UBUNTU_CODE="focal" ;;
    7) UBUNTU_CODE="karmic" ;;
    8) UBUNTU_CODE="lucid" ;;
    9) UBUNTU_CODE="maverick" ;;
    10) UBUNTU_CODE="natty" ;;
    11) UBUNTU_CODE="oneiric" ;;
    12) UBUNTU_CODE="precise" ;;
    13) UBUNTU_CODE="quantal" ;;
    14) UBUNTU_CODE="raring" ;;
    15) UBUNTU_CODE="saucy" ;;
    16) UBUNTU_CODE="trusty" ;;
    17) UBUNTU_CODE="utopic" ;;
    18) UBUNTU_CODE="vivid" ;;
    19) UBUNTU_CODE="wily" ;;
    20) UBUNTU_CODE="xenial" ;;
    21) UBUNTU_CODE="yakkety" ;;
    22) UBUNTU_CODE="zesty" ;;
    esac
    ######################################
    GREP_NAME_02="ubuntu-wallpapers-${UBUNTU_CODE}"
    CUSTOM_WALLPAPER_NAME="ubuntu-wallpapers/${UBUNTU_CODE}"
    download_ubuntu_wallpaper
    press_enter_to_return
    ubuntu_gnome_walllpapers
}
###############
download_ubuntu_wallpaper() {
    if [ -d "${HOME}/图片" ]; then
        mkdir -pv ${HOME}/图片/ubuntu-wallpapers
    else
        mkdir -pv ${HOME}/Pictures/ubuntu-wallpapers
    fi
    THEME_NAME='ubuntu_wallpaper'
    WALLPAPER_NAME='backgrounds'
    GREP_NAME_01='all.deb'
    THEME_URL='https://mirrors.bfsu.edu.cn/ubuntu/pool/universe/u/ubuntu-wallpapers/'
    grep_theme_model_03
    move_wallpaper_model_01
}
###############
ubuntu_wallpapers_and_photos() {
    RETURN_TO_WHERE='ubuntu_wallpapers_and_photos'
    INSTALL_THEME=$(whiptail --title "Ubuntu壁纸包" --menu \
        "您想要下载哪套Ubuntu壁纸包？\n Which ubuntu wallpaper-pack do you want to download? " 0 50 0 \
        "1" "ubuntu-gnome:(bionic,cosmic,etc.)" \
        "2" "xubuntu-community:(bionic,focal,etc.)" \
        "3" "ubuntu-mate" \
        "4" "ubuntu-kylin 优麒麟" \
        "0" "Back to the main menu 返回主菜单" \
        3>&1 1>&2 2>&3)
    ########################
    case "${INSTALL_THEME}" in
    0 | "") download_wallpapers ;;
    1) ubuntu_gnome_walllpapers ;;
    2) xubuntu_wallpapers ;;
    3) download_ubuntu-mate_wallpaper ;;
    4) download_ubuntu_kylin_walllpaper ;;
    esac
    ######################################
    press_enter_to_return
    ubuntu_wallpapers_and_photos
}
#######################
#ubuntukylin-wallpapers_20.04.2.tar.xz
download_ubuntu_kylin_walllpaper() {
    THEME_NAME='ubuntukylin_wallpapers'
    WALLPAPER_NAME='ubuntukylin-wallpapers'
    CUSTOM_WALLPAPER_NAME='ubuntukylin-wallpapers'
    GREP_NAME_01='.tar.xz'
    GREP_NAME_02='ubuntukylin-wallpapers_'
    THEME_URL='https://mirrors.bfsu.edu.cn/ubuntu/pool/universe/u/ubuntukylin-wallpapers/'
    grep_theme_model_04
    move_wallpaper_model_02
}
#############
download_ubuntu-mate_wallpaper() {
    GREP_NAME_02='ubuntu-mate-wallpapers-photos'
    THEME_NAME='ubuntu_wallpapers_and_photos'
    WALLPAPER_NAME='backgrounds/ubuntu-mate-photos'
    GREP_NAME_01='all.deb'
    THEME_URL='https://mirrors.bfsu.edu.cn/ubuntu/pool/universe/u/ubuntu-mate-artwork/'
    if [ "${SET_MINT_AS_WALLPAPER}" = 'true' ]; then
        CUSTOM_WALLPAPER_NAME="backgrounds"
    else
        CUSTOM_WALLPAPER_NAME='ubuntu-mate-photos'
    fi
    grep_theme_model_03
    move_wallpaper_model_01
}
#####################
linux_mint_backgrounds() {
    RETURN_TO_WHERE='linux_mint_backgrounds'
    SET_MINT_AS_WALLPAPER='false'
    #cat index.html | grep mint-backgrounds | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '/' -f 1 | cut -d '-' -f 3,4
    GREP_NAME_02="mint-backgrounds"
    INSTALL_THEME=$(whiptail --title "MINT壁纸包" --menu \
        "Download Mint wallpaper-packs" 0 50 0 \
        "0" "Back返回" \
        "1" "ulyana" \
        "2" "tricia" \
        "3" "tina" \
        "4" "tessa" \
        "5" "tara" \
        "6" "sylvia" \
        "7" "sonya" \
        "8" "serena" \
        "9" "sarah" \
        "10" "rosa" \
        "11" "retro" \
        "12" "rebecca" \
        "13" "rafaela" \
        "14" "qiana" \
        "15" "petra" \
        "16" "olivia" \
        "17" "nadia" \
        "18" "maya" \
        "19" "lisa-extra" \
        "20" "katya-extra" \
        "21" "xfce-2014" \
        3>&1 1>&2 2>&3)
    ########################
    case "${INSTALL_THEME}" in
    0 | "") download_wallpapers ;;
    1) MINT_CODE="ulyana" ;;
    2) MINT_CODE="tricia" ;;
    3) MINT_CODE="tina" ;;
    4) MINT_CODE="tessa" ;;
    5) MINT_CODE="tara" ;;
    6) MINT_CODE="sylvia" ;;
    7) MINT_CODE="sonya" ;;
    8) MINT_CODE="serena" ;;
    9) MINT_CODE="sarah" ;;
    10) MINT_CODE="rosa" ;;
    11) MINT_CODE="retro" ;;
    12) MINT_CODE="rebecca" ;;
    13) MINT_CODE="rafaela" ;;
    14) MINT_CODE="qiana" ;;
    15) MINT_CODE="petra" ;;
    16) MINT_CODE="olivia" ;;
    17) MINT_CODE="nadia" ;;
    18) MINT_CODE="maya" ;;
    19) MINT_CODE="lisa-extra" ;;
    20) MINT_CODE="katya-extra" ;;
    21)
        MINT_CODE="xfce"
        GREP_NAME_02="_2014.06.09"
        ;;
    esac
    ######################################
    download_mint_backgrounds
    press_enter_to_return
    linux_mint_backgrounds
}
###############
download_mint_backgrounds() {
    if [ "${MINT_CODE}" = 'xfce' ]; then
        WALLPAPER_NAME='xfce4/backdrops'
    else
        WALLPAPER_NAME="backgrounds/linuxmint-${MINT_CODE}"
    fi
    if [ "${SET_MINT_AS_WALLPAPER}" = 'true' ]; then
        CUSTOM_WALLPAPER_NAME="backgrounds"
    else
        CUSTOM_WALLPAPER_NAME="mint-backgrounds/linuxmint-${MINT_CODE}"
        if [ -d "${HOME}/图片" ]; then
            mkdir -pv ${HOME}/图片/mint-backgrounds
        else
            mkdir -pv ${HOME}/Pictures/mint-backgrounds
        fi
    fi
    THEME_NAME="mint_backgrounds_${MINT_CODE}"
    GREP_NAME_01='all.deb'
    THEME_URL="https://mirrors.bfsu.edu.cn/linuxmint/pool/main/m/mint-backgrounds-${MINT_CODE}/"
    grep_theme_model_03
    move_wallpaper_model_01
}
###############
download_wallpapers() {
    cd /tmp
    SET_MINT_AS_WALLPAPER='false'
    FORCIBLY_DOWNLOAD='false'
    RETURN_TO_WHERE='download_wallpapers'
    INSTALL_THEME=$(whiptail --title "桌面壁纸" --menu \
        "您想要下载哪套壁纸包？\n Which wallpaper-pack do you want to download? " 0 50 0 \
        "1" "ubuntu:汇聚了官方及社区的绝赞壁纸包" \
        "2" "Mint:聆听自然的律动与风之呼吸,感受清新而唯美" \
        "3" "deepin-community+official 深度" \
        "4" "elementary(如沐春风)" \
        "5" "raspberrypi pixel树莓派(美如画卷)" \
        "6" "manjaro-2017+2018" \
        "7" "gnome-backgrounds(简单而纯粹)" \
        "8" "xfce-artwork" \
        "9" "arch(领略别样艺术)" \
        "0" "Back to the main menu 返回主菜单" \
        3>&1 1>&2 2>&3)
    ########################
    case "${INSTALL_THEME}" in
    0 | "") tmoe_desktop_beautification ;;
    1) ubuntu_wallpapers_and_photos ;;
    2) linux_mint_backgrounds ;;
    3) download_deepin_wallpaper ;;
    4) download_elementary_wallpaper ;;
    5) download_raspbian_pixel_wallpaper ;;
    6) download_manjaro_wallpaper ;;
    7) download_debian_gnome_wallpaper ;;
    8) download_arch_xfce_artwork ;;
    9) download_arch_wallpaper ;;
    esac
    ######################################
    press_enter_to_return
    download_wallpapers
}
############
configure_mouse_cursor() {
    printf "%s\n" "chameleon:现代化鼠标指针主题"
    printf '%s\n' 'Do you want to download it?'
    do_you_want_to_continue
    download_chameleon_cursor_theme
}
################################
download_paper_icon_theme() {
    THEME_NAME='paper_icon_theme'
    ICON_NAME='Paper /usr/share/icons/Paper-Mono-Dark'
    GREP_NAME='paper-icon-theme'
    THEME_URL='https://mirrors.bfsu.edu.cn/manjaro/pool/overlay/'
    grep_theme_model_02
    update_icon_caches_model_02
    XFCE_ICON_NAME='Paper'
    set_default_xfce_icon_theme
}
#############
download_papirus_icon_theme() {
    THEME_NAME='papirus_icon_theme'
    ICON_NAME='Papirus /usr/share/icons/Papirus-Dark /usr/share/icons/Papirus-Light /usr/share/icons/ePapirus'
    GREP_NAME='papirus-icon-theme'
    THEME_URL='https://mirrors.bfsu.edu.cn/debian/pool/main/p/papirus-icon-theme/'
    grep_theme_model_01
    update_icon_caches_model_01
    XFCE_ICON_NAME='Papirus'
    set_default_xfce_icon_theme
}
############################
download_raspbian_pixel_wallpaper() {
    THEME_NAME='raspberrypi_pixel_wallpaper'
    WALLPAPER_NAME='pixel-wallpaper'
    CUSTOM_WALLPAPER_NAME='raspberrypi-pixel-wallpapers'
    GREP_NAME='pixel-wallpaper'
    THEME_URL='https://mirrors.bfsu.edu.cn/raspberrypi/pool/ui/p/pixel-wallpaper/'
    grep_theme_model_01
    move_wallpaper_model_01
}
########
download_debian_gnome_wallpaper() {
    THEME_NAME='gnome_backgrounds'
    WALLPAPER_NAME='backgrounds/gnome'
    CUSTOM_WALLPAPER_NAME='gnome-backgrounds'
    GREP_NAME='gnome-backgrounds'
    THEME_URL='https://mirrors.bfsu.edu.cn/debian/pool/main/g/gnome-backgrounds/'
    grep_theme_model_01
    move_wallpaper_model_01
}
##############
download_deepin_wallpaper() {
    THEME_NAME='deepin-wallpapers'
    WALLPAPER_NAME='wallpapers/deepin'
    GREP_NAME='deepin-community-wallpapers'
    CUSTOM_WALLPAPER_NAME='deepin-community'
    THEME_URL='https://mirrors.bfsu.edu.cn/deepin/pool/main/d/deepin-wallpapers/'
    grep_theme_model_01
    move_wallpaper_model_01
    GREP_NAME='deepin-wallpapers_'
    CUSTOM_WALLPAPER_NAME='deepin-wallpapers'
    grep_theme_model_01
    move_wallpaper_model_01
}
##########
download_manjaro_pkg() {
    check_theme_folder
    mkdir -pv /tmp/.${THEME_NAME}
    cd /tmp/.${THEME_NAME}
    printf "%s\n" "${THEME_URL}"
    aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'data.tar.xz' "${THEME_URL}"
}
############
link_to_debian_wallpaper() {
    if [ -e "/usr/share/backgrounds/kali/" ]; then
        if [ -d "${HOME}/图片" ]; then
            ln -sf /usr/share/backgrounds/kali/ ${HOME}/图片/kali
        else
            mkdir -pv ${HOME}/Pictures
            ln -sf /usr/share/backgrounds/kali/ ${HOME}/Pictures/kali
        fi
    fi
    #########
    DEBIAN_MOONLIGHT='/usr/share/desktop-base/moonlight-theme/wallpaper/contents/images/'
    if [ -e "${DEBIAN_MOONLIGHT}" ]; then
        if [ -d "${HOME}/图片" ]; then
            ln -sf ${DEBIAN_MOONLIGHT} ${HOME}/图片/debian-moonlight
        else
            ln -sf ${DEBIAN_MOONLIGHT} ${HOME}/Pictures/debian-moonlight
        fi
    fi
    DEBIAN_LOCK_SCREEN='/usr/share/desktop-base/lines-theme/lockscreen/contents/images/'
    if [ -e "${DEBIAN_LOCK_SCREEN}" ]; then
        if [ -d "${HOME}/图片" ]; then
            ln -sf ${DEBIAN_LOCK_SCREEN} ${HOME}/图片/debian-lockscreen
        else
            ln -sf ${DEBIAN_LOCK_SCREEN} ${HOME}/Pictures/debian-lockscreen
        fi
    fi
}
#########
download_manjaro_wallpaper() {
    THEME_NAME='manjaro-2018'
    THEME_URL='https://mirrors.bfsu.edu.cn/manjaro/pool/overlay/wallpapers-2018-1.2-1-any.pkg.tar.xz'
    WALLPAPER_NAME='backgrounds/wallpapers-2018'
    CUSTOM_WALLPAPER_NAME='manjaro-2018'
    download_manjaro_pkg
    move_wallpaper_model_01
    ##############
    THEME_NAME='manjaro-2017'
    THEME_URL='https://mirrors.bfsu.edu.cn/manjaro/pool/overlay/manjaro-sx-wallpapers-20171023-1-any.pkg.tar.xz'
    WALLPAPER_NAME='backgrounds'
    CUSTOM_WALLPAPER_NAME='manjaro-2017'
    download_manjaro_pkg
    move_wallpaper_model_01
    ##################
}
#########
download_arch_wallpaper() {
    link_to_debian_wallpaper
    GREP_NAME='archlinux-wallpaper'
    #https://mirrors.bfsu.edu.cn/archlinux/pool/community/archlinux-wallpaper-1.4-6-any.pkg.tar.xz
    WALLPAPER_NAME='backgrounds/archlinux'
    CUSTOM_WALLPAPER_NAME='archlinux'
    THEME_URL='https://mirrors.bfsu.edu.cn/archlinux/pool/community/'
    check_theme_folder
    download_arch_community_repo_html
    grep_arch_linux_pkg_02
    move_wallpaper_model_01
}
##############
download_arch_xfce_artwork() {
    #check_zstd
    GREP_NAME='xfce4-artwork'
    #https://mirrors.bfsu.edu.cn/archlinux/pool/community/archlinux-wallpaper-1.4-6-any.pkg.tar.xz
    WALLPAPER_NAME='backgrounds/xfce'
    CUSTOM_WALLPAPER_NAME='xfce-artwork'
    THEME_URL='https://mirrors.bfsu.edu.cn/archlinux/extra/os/x86_64/'
    check_theme_folder
    download_arch_community_repo_html
    grep_arch_linux_pkg_02
    move_wallpaper_model_01
}
########################
download_elementary_wallpaper() {
    #https://mirrors.bfsu.edu.cn/archlinux/pool/community/elementary-wallpapers-5.5.0-1-any.pkg.tar.xz
    GREP_NAME='elementary-wallpapers'
    WALLPAPER_NAME='wallpapers/elementary'
    CUSTOM_WALLPAPER_NAME='elementary'
    THEME_URL='https://mirrors.bfsu.edu.cn/archlinux/pool/community/'
    check_theme_folder
    download_arch_community_repo_html
    grep_arch_linux_pkg
    #该包无zst格式
    move_wallpaper_model_01
    #elementary-wallpapers-5.5.0-1-any.pkg.tar.xz
}
################
download_kali_themes_common() {
    check_update_icon_caches_sh
    THEME_NAME='kali-themes-common'
    GREP_NAME='kali-themes-common'
    ICON_NAME='Flat-Remix-Blue-Dark /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/desktop-base'
    THEME_URL='https://mirrors.bfsu.edu.cn/kali/pool/main/k/kali-themes/'
    grep_theme_model_01
    update_icon_caches_model_01
}
####################
download_kali_theme() {
    if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
        download_kali_themes_common
    else
        printf "%s\n" "检测到kali_themes_common已下载，是否重新下载？"
        do_you_want_to_continue
        download_kali_themes_common
    fi
    printf "%s\n" "Download completed.如需删除，请手动输rm -rf /usr/share/desktop-base/kali-theme /usr/share/icons/desktop-base /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/Flat-Remix-Blue-Dark"
    XFCE_ICON_NAME='Flat-Remix-Blue-Light'
    set_default_xfce_icon_theme
}
##################
download_win10x_theme() {
    if [ -d "/usr/share/icons/We10X-dark" ]; then
        printf "%s\n" "检测到图标包已下载，是否重新下载？"
        RETURN_TO_WHERE='configure_theme'
        do_you_want_to_continue
    fi

    if [ -d "/tmp/.WINDOWS_10X_ICON_THEME" ]; then
        rm -rf /tmp/.WINDOWS_10X_ICON_THEME
    fi

    git clone -b win10x --depth=1 https://gitee.com/mo2/xfce-themes.git /tmp/.WINDOWS_10X_ICON_THEME
    cd /tmp/.WINDOWS_10X_ICON_THEME
    GITHUB_URL=$(cat url.txt)
    tar -Jxvf We10X.tar.xz -C /usr/share/icons 2>/dev/null
    update-icon-caches /usr/share/icons/We10X-dark /usr/share/icons/We10X 2>/dev/null &
    printf "%s\n" "${GITHUB_URL}"
    rm -rf /tmp/McWe10X
    printf "%s\n" "Download completed.如需删除，请手动输rm -rf /usr/share/icons/We10X-dark /usr/share/icons/We10X"
    XFCE_ICON_NAME='We10X'
    set_default_xfce_icon_theme
}
###################
download_uos_icon_theme() {
    DEPENDENCY_01="deepin-icon-theme"
    DEPENDENCY_02=""

    beta_features_quick_install

    if [ -d "/usr/share/icons/Uos" ]; then
        printf "%s\n" "检测到Uos图标包已下载,是否继续？${PURPLE}[Y/n]${RESET}"
        RETURN_TO_WHERE='configure_theme'
        do_you_want_to_continue
    fi

    if [ -d "/tmp/UosICONS" ]; then
        rm -rf /tmp/UosICONS
    fi

    git clone -b Uos --depth=1 https://gitee.com/mo2/xfce-themes.git /tmp/UosICONS
    cd /tmp/UosICONS
    GITHUB_URL=$(cat url.txt)
    tar -Jxvf Uos.tar.xz -C /usr/share/icons 2>/dev/null
    update-icon-caches /usr/share/icons/Uos 2>/dev/null &
    printf "%s\n" "${GITHUB_URL}"
    rm -rf /tmp/UosICONS
    printf "%s\n" "Download completed.如需删除，请手动输rm -rf /usr/share/icons/Uos ; ${TMOE_REMOVAL_COMMAND} deepin-icon-theme"
    XFCE_ICON_NAME='Uos'
    set_default_xfce_icon_theme
}
#####################
download_macos_bigsur_theme() {
    if [ -d "/usr/share/icons/WhiteSur-dark" ]; then
        printf "%s\n" "检测到主题已下载，是否重新下载？"
        RETURN_TO_WHERE='configure_theme'
        do_you_want_to_continue
    fi
    TEMP_FOLDER='/tmp/BIGSUR_TEMP_FOLDER'
    if [ -e "${TEMP_FOLDER}" ]; then
        rm -rvf ${TEMP_FOLDER}
    fi
    git clone -b master --depth=1 https://gitee.com/ak2/bigsur-gtk-theme.git ${TEMP_FOLDER}
    cd ${TEMP_FOLDER}
    GITHUB_URL=$(cat url.txt)
    tar -Jxvf WhiteSur.tar.xz -C /usr/share/icons 2>/dev/null
    tar -Jxvf WhiteSur-light-alt.tar.xz -C /usr/share/themes 2>/dev/null
    tar -Jxvf WhiteSur-dark.tar.xz -C /usr/share/themes 2>/dev/null
    update-icon-caches /usr/share/icons/WhiteSur /usr/share/icons/WhiteSur-dark 2>/dev/null &
    rm -rvf ${TEMP_FOLDER}
    printf "%s\n" "${GITHUB_URL}"
    printf "%s\n" "Download completed.如需删除，请手动输rm -rf /usr/share/themes/WhiteSur-dark /usr/share/themes/WhiteSur-light-alt /usr/share/icons/WhiteSur /usr/share/icons/WhiteSur-dark"
    XFCE_ICON_NAME='WhiteSur'
    set_default_xfce_icon_theme
}
#######################
download_macos_mojave_theme() {
    if [ -d "/usr/share/themes/Mojave-dark" ]; then
        printf "%s\n" "检测到主题已下载，是否重新下载？"
        RETURN_TO_WHERE='configure_theme'
        do_you_want_to_continue
    fi

    if [ -d "/tmp/McMojave" ]; then
        rm -rf /tmp/McMojave
    fi

    git clone -b McMojave --depth=1 https://gitee.com/mo2/xfce-themes.git /tmp/McMojave
    cd /tmp/McMojave
    GITHUB_URL=$(cat url.txt)
    tar -Jxvf 01-Mojave-dark.tar.xz -C /usr/share/themes 2>/dev/null
    tar -Jxvf 01-McMojave-circle.tar.xz -C /usr/share/icons 2>/dev/null
    update-icon-caches /usr/share/icons/McMojave-circle-dark /usr/share/icons/McMojave-circle 2>/dev/null &
    printf "%s\n" "${GITHUB_URL}"
    rm -rf /tmp/McMojave
    printf "%s\n" "Download completed.如需删除，请手动输rm -rf /usr/share/themes/Mojave-dark /usr/share/icons/McMojave-circle-dark /usr/share/icons/McMojave-circle"
    XFCE_ICON_NAME='McMojave-circle'
    set_default_xfce_icon_theme
}
########################
download_ukui_theme() {
    DEPENDENCY_01="ukui-themes"
    DEPENDENCY_02="ukui-greeter"

    beta_features_quick_install

    if [ ! -e '/usr/share/icons/ukui-icon-theme-default' ] && [ ! -e '/usr/share/icons/ukui-icon-theme' ]; then
        mkdir -pv /tmp/.ukui-gtk-themes
        cd /tmp/.ukui-gtk-themes
        UKUITHEME="$(curl -LfsS 'https://mirrors.bfsu.edu.cn/debian/pool/main/u/ukui-themes/' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
        aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'ukui-themes.deb' "https://mirrors.bfsu.edu.cn/debian/pool/main/u/ukui-themes/${UKUITHEME}"
        ar xv 'ukui-themes.deb'
        cd /
        tar -Jxvf /tmp/.ukui-gtk-themes/data.tar.xz ./usr
        #if which update-icon-caches >/dev/null 2>&1; then
        update-icon-caches /usr/share/icons/ukui-icon-theme-basic /usr/share/icons/ukui-icon-theme-classical /usr/share/icons/ukui-icon-theme-default 2>/dev/null &
        update-icon-caches /usr/share/icons/ukui-icon-theme 2>/dev/null &
        #fi
        rm -rf /tmp/.ukui-gtk-themes
        #apt install -y ./ukui-themes.deb
        #rm -f ukui-themes.deb
        #apt install -y ukui-greeter
    else
        printf '%s\n' '请前往外观设置手动修改图标'
    fi
    XFCE_ICON_NAME='ukui-icon-theme'
    set_default_xfce_icon_theme
    #update-icon-caches /usr/share/icons/ukui-icon-theme/ 2>/dev/null
    #printf "%s\n" "安装完成，如需卸载，请手动输${TMOE_REMOVAL_COMMAND} ukui-themes"
}
#################################
download_arch_breeze_adapta_cursor_theme() {
    mkdir -pv /tmp/.breeze_theme
    cd /tmp/.breeze_theme
    THEME_URL='https://mirrors.bfsu.edu.cn/archlinuxcn/any/'
    curl -Lo index.html ${THEME_URL}
    GREP_NAME='breeze-adapta-cursor-theme-git'
    grep_arch_linux_pkg_02
    #tar -Jxvf data.tar.xz 2>/dev/null
    tar -I zstd -xvf data.tar.zst
    cp -rf usr /
    rm -rf /tmp/.breeze_theme
}
#############
install_breeze_theme() {
    DEPENDENCY_01="breeze-icon-theme"
    DEPENDENCY_02="breeze-cursor-theme breeze-gtk-theme xfwm4-theme-breeze"
    download_arch_breeze_adapta_cursor_theme
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_01="breeze-icons breeze-gtk"
        DEPENDENCY_02="xfwm4-theme-breeze capitaine-cursors"
        if [ $(command -v grub-install) ]; then
            DEPENDENCY_02="${DEPENDENCY_02} breeze-grub"
        fi
    fi
    beta_features_quick_install
}
#################
download_chameleon_cursor_theme() {
    CUSTOM_WALLPAPER_NAME='breeze-cursor-theme'
    THEME_NAME='breeze-cursor-theme'
    GREP_NAME="${THEME_NAME}"
    THEME_URL='https://mirrors.bfsu.edu.cn/debian/pool/main/b/breeze/'
    grep_theme_model_01
    upcompress_deb_file
    #############
    GREP_NAME='all'
    THEME_NAME='chameleon-cursor-theme'
    THEME_URL='https://mirrors.bfsu.edu.cn/debian/pool/main/c/chameleon-cursor-theme/'
    grep_theme_model_01
    upcompress_deb_file
    ##############
    THEME_NAME='moblin-cursor-theme'
    THEME_URL='https://mirrors.bfsu.edu.cn/debian/pool/main/m/moblin-cursor-theme/'
    grep_theme_model_01
    upcompress_deb_file
    ##########
}
##########
install_kali_undercover() {
    if [ -e "/usr/share/icons/Windows-10-Icons" ]; then
        printf "%s\n" "检测到您已安装win10主题"
        printf "%s\n" "如需移除，请手动输${TMOE_REMOVAL_COMMAND} kali-undercover;rm -rf /usr/share/icons/Windows-10-Icons"
        printf "%s\n" "是否重新下载？"
        RETURN_TO_WHERE='configure_theme'
        do_you_want_to_continue
    fi
    DEPENDENCY_01="kali-undercover"
    DEPENDENCY_02=""

    case "${LINUX_DISTRO}" in
    "debian") beta_features_quick_install ;;
    esac
    #此处需做两次判断
    if [ "${DEBIAN_DISTRO}" = "kali" ]; then
        beta_features_quick_install
    else
        mkdir -pv /tmp/.kali-undercover-win10-theme
        cd /tmp/.kali-undercover-win10-theme
        UNDERCOVERlatestLINK="$(curl -LfsS 'https://mirrors.bfsu.edu.cn/kali/pool/main/k/kali-undercover/' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
        aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o kali-undercover.deb "https://mirrors.bfsu.edu.cn/kali/pool/main/k/kali-undercover/${UNDERCOVERlatestLINK}"
        #apt-cache show ./kali-undercover.deb
        #apt install -y ./kali-undercover.deb
        if [ ! -e "/usr/share/icons/Windows-10-Icons" ]; then
            THE_LATEST_DEB_FILE='kali-undercover.deb'
            ar xv ${THE_LATEST_DEB_FILE}
            cd /
            tar -Jxvf /tmp/.kali-undercover-win10-theme/data.tar.xz ./usr
            #if which gtk-update-icon-cache >/dev/null 2>&1; then
            update-icon-caches /usr/share/icons/Windows-10-Icons 2>/dev/null &
            #fi
        fi
        rm -rfv /tmp/.kali-undercover-win10-theme
        #rm -f ./kali-undercover.deb
    fi
    #XFCE_ICON_NAME='Windows 10'
}
#################
modify_remote_desktop_config() {
    RETURN_TO_WHERE='modify_remote_desktop_config'
    RETURN_TO_TMOE_MENU_01='modify_remote_desktop_config'
    ##################
    REMOTE_DESKTOP=$(whiptail --title "REMOTE DESKTOP" --menu \
        "您想要修改哪个远程桌面的配置？\nWhich remote desktop config do you want to modify?" 0 50 0 \
        "1" "🐯 tightvnc/tigervnc:应用广泛" \
        "2" "⚔️ x11vnc:通过VNC来连接真实X桌面" \
        "3" "⚒️ Xserver:(XSDL/VcXsrv)" \
        "4" "novnc(HTML5 vnc client)" \
        "5" "⚛️ XRDP:基于microsoft开发的rdp协议" \
        "0" "Back to the main menu 返回主菜单" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${REMOTE_DESKTOP}" in
    0 | "") tmoe_linux_tool_menu ;;
    1) modify_vnc_conf ;;
    2) configure_x11vnc ;;
    3) modify_xsdl_conf ;;
    4) modify_novnc_conf ;;
    5) modify_xrdp_conf ;;
    esac
    #######################
    #  "5" "Wayland:(测试版,取代X Window)" \    5) modify_xwayland_conf ;;
    press_enter_to_return
    modify_remote_desktop_config
}
#########################
modify_novnc_conf() {
    source ${TMOE_TOOL_DIR}/gui/configure_novnc
}
#################
configure_x11vnc() {
    #17 50 8
    TMOE_OPTION=$(
        whiptail --title "CONFIGURE x11vnc" --menu "Type startx11vnc to start vncserver,输入startx11vnc启动x11vnc服务" 0 0 0 \
            "1" "one-key configure初始化一键配置" \
            "2" "pulse_server音频服务" \
            "3" "resolution分辨率" \
            "4" "port端口" \
            "5" "修改startx11vnc启动脚本" \
            "6" "remove 卸载/移除" \
            "7" "readme 进程管理说明" \
            "8" "password 密码" \
            "9" "read doc阅读文档" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") modify_remote_desktop_config ;;
    1) x11vnc_onekey ;;
    2) x11vnc_pulse_server ;;
    3) x11vnc_resolution ;;
    4) x11vnc_port ;;
    5) nano /usr/local/bin/startx11vnc ;;
    6) remove_X11vnc ;;
    7) x11vnc_process_readme ;;
    8) x11vncpasswd ;;
    9) x11vnc_doc ;;
    esac
    ########################################
    press_enter_to_return
    configure_x11vnc
    ####################
}
############
x11vnc_doc() {
    X11VNC_DOC_URL='http://www.karlrunge.com/x11vnc/x11vnc_opts.html'
    printf "%s\n" "url: ${X11VNC_DOC_URL}"
    su "${CURRENT_USER_NAME}" -c "xdg-open ${X11VNC_DOC_URL}"
    man x11vnc Xvfb
}
###########
x11vnc_process_readme() {
    printf "%s\n" "输startx11vnc启动x11vnc服务。"
    printf "%s\n" "You can type ${GREEN}startx11vnc${RESET} to start it,type ${RED}stopvnc${RESET} to stop it."
    printf "%s\n" "输stopvnc停止x11vnc"
    printf "%s\n" "若您的音频服务端为Android系统，且发现音频服务无法启动,请在启动完成后，新建一个termux session会话窗口，然后手动在termux原系统里输${GREEN}pulseaudio -D${RESET}来启动音频服务后台进程"
    printf "%s\n" "您亦可输${GREEN}pulseaudio --start${RESET}"
    printf "%s\n" "若您无法记住该命令，则只需输${GREEN}debian${RESET}"
}
###################
x11vnc_warning() {
    cat <<-EOF
		    ${YELLOW}关于X11VNC服务的启动说明${RESET}：
			There are many differences between x11vnc and tightvnc. Mainly reflected in the fluency and special effects of the picture.
			After configuring x11vnc, you can type ${GREEN}startx11vnc${RESET} to ${BLUE}start${RESET} it.
			------------------------
			注：x11vnc和tightvnc是有${RED}区别${RESET}的！
			x11vnc可以运行tightvnc无法打开的某些应用，在WSL2/Linux实体机上的体验优于tightvnc，但在Android设备上运行的流畅度可能不如tightvnc
			
			若您已安装了${GREEN}tight${RESET},但未安装${PURPLE}tiger${RESET},则可使用${BLUE}x11vnc${RESET};
			若您已安装了${GREEN}tiger${RESET},则建议使用${YELLOW}tiger${RESET},而不是${PURPLE}x11vnc${RESET}。

			${BOLD}${YELLOW}vnc服务端推荐程度：${RESET}
			${BLUE}tiger > x11vnc > tight${RESET}

			${BOLD}${YELLOW}流畅程度（Zlib compression level为最低,且无法进行加速渲染时）:${RESET}
			${BLUE}tight > tiger > x11vnc${RESET}
			
			${BOLD}${YELLOW}流畅程度（Zlib compression level为最低,且支持加速渲染时）:${RESET}
			${BLUE}tiger > tight ? x11vnc${RESET}

			${BOLD}${YELLOW}流畅程度（Zlib compression level为最高时）:${RESET}
			${BLUE}tight > x11vnc > tiger${RESET}

			注：${GREEN}过高${RESET}的压缩级别将增大${BLUE}CPU负担${RESET}，并${PURPLE}严重拖慢${RESET}渲染速度。
			以上为${PURPLE}主观数据${RESET}，影响流畅度的因素不止压缩算法、级别和硬件加速，请以${GREEN}实际体验${RESET}为准。
			------------------------
			配置完x11vnc后，您可以在容器里输${GREEN}startx11vnc${RESET}${BLUE}启动${RESET},输${GREEN}stopvnc${RESET}${RED}停止${RESET}
			若超过一分钟黑屏，则请输${GREEN}startx11vnc${RESET}重启该服务。
			您若觉得x11vnc体验不佳，则可随时输${GREEN}startvnc${RESET}重启并切换到${BLUE}tight/tigervnc${RESET}服务。
			------------------------
			建议您配置${YELLOW}多个${RESET}VNC服务，以备${PURPLE}不时之需${RESET}。
			您是否需要配置${BLUE}X11VNC${RESET}服务？
			Do you want to configure x11vnc? 
	EOF
    RETURN_TO_WHERE='configure_x11vnc'
    do_you_want_to_continue
    #stopvnc 2>/dev/null

    #suse的x11vnc默认由tigervnc提供，此处remove掉
    case ${LINUX_DISTRO} in
    suse) zypper rm -y tigervnc-x11vnc ;;
    esac

    DEPENDENCY_01=''
    DEPENDENCY_02=''
    if [ ! $(command -v x11vnc) ]; then
        case ${LINUX_DISTRO} in
        gentoo) DEPENDENCY_01='x11-misc/x11vnc' ;;
        *) DEPENDENCY_01="x11vnc" ;;
        esac
    fi
    #注意下面那处的大小写
    if [ ! $(command -v xvfb) ] && [ ! $(command -v Xvfb) ]; then
        if [ "${LINUX_DISTRO}" = "arch" ]; then
            DEPENDENCY_02='xorg-server-xvfb'
        elif [ "${LINUX_DISTRO}" = "redhat" ]; then
            DEPENDENCY_02='xorg-x11-server-Xvfb'
        elif [ "${LINUX_DISTRO}" = "suse" ]; then
            DEPENDENCY_02='xorg-x11-server-Xvfb'
        elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
            DEPENDENCY_02='x11-misc/xvfb-run'
        else
            DEPENDENCY_02='xvfb'
        fi
    fi

    if [ ! -z "${DEPENDENCY_01}" ] || [ ! -z "${DEPENDENCY_02}" ]; then
        beta_features_quick_install
    fi
    #音频控制器单独检测
    if [[ ! $(command -v pavucontrol) && ! $(command -v pavucontrol-qt) ]]; then
        ${TMOE_INSTALLATION_COMMAND} pavucontrol
    fi
}
############
x11vnc_onekey() {
    x11vnc_warning
    ################
    X11_OR_WAYLAND_DESKTOP='x11vnc'
    configure_remote_desktop_enviroment
}
#############
remove_X11vnc() {
    printf "%s\n" "正在停止x11vnc进程..."
    printf "%s\n" "Stopping x11vnc..."
    stopvnc -x11
    printf "%s\n" "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
    RETURN_TO_WHERE='configure_x11vnc'
    do_you_want_to_continue
    rm -rfv /usr/local/bin/startx11vnc
    printf "%s\n" "即将为您卸载..."
    ${TMOE_REMOVAL_COMMAND} x11vnc
}
################
x11vnc_pulse_server() {
    cd /usr/local/bin/
    TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。当前为$(grep 'PULSE_SERVER' startx11vnc | grep -v '^#' | cut -d '=' -f 2 | head -n 1) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        configure_x11vnc
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        if grep -q '^export.*PULSE_SERVER' startx11vnc; then
            sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=${TARGET}@" startx11vnc
        else
            sed -i "3 a\export PULSE_SERVER=${TARGET}" startx11vnc
        fi
        printf '%s\n' 'Your current PULSEAUDIO SERVER address has been modified.'
        printf '%s\n' '您当前的音频地址已修改为'
        printf "%s\n" "$(grep 'PULSE_SERVER' startx11vnc | grep -v '^#' | cut -d '=' -f 2 | head -n 1)"
    fi
}
##################
check_x11vnc_port() {
    CURRENT_VALUE=$(grep '^TCP_PORT_FOR_RFB_PROTOCOL=' $(command -v startx11vnc) | head -n 1 | awk -F '=' '{print $2}' | cut -d '"' -f 2)
}
#############
x11vnc_port() {
    check_x11vnc_port
    TARGET=$(whiptail --inputbox "Please type the x11vnc tcp port,the default is 5901,current port is ${CURRENT_VALUE}" 10 50 --title "请输入端口" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        configure_x11vnc
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
        check_x11vnc_port
        printf "%s\n" "Current port is ${BLUE}${CURRENT_VALUE}${RESET}"
    else
        sed -i -E "s@^(TCP_PORT_FOR_RFB_PROTOCOL)=.*@\1=${TARGET}@" "$(command -v startx11vnc)"
        printf '%s\n' 'Your current port has been modified.'
        check_x11vnc_port
        printf "%s\n" "Current port is ${BLUE}${CURRENT_VALUE}${RESET}"
        printf "%s\n" "You can type ${GREEN}startx11vnc${RESET} to restart it."
    fi
}
#################
x11vnc_resolution() {
    TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,720x1140,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为1440x720,当前为$(grep 'TMOE_X11_RESOLUTION=' $(command -v startx11vnc) | head -n 1 | cut -d '=' -f 2)。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        configure_x11vnc
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
        #printf "%s\n" "您当前的分辨率为$(sed -n p $(command -v startx11vnc) | grep '/usr/bin/Xvfb' | head -n 1 | cut -d ':' -f 2 | cut -d '+' -f 1 | cut -d '-' -f 2 | cut -d 'x' -f -2 | awk -F ' ' '$0=$NF')"
        printf "%s\n" "您当前的分辨率为$(grep 'TMOE_X11_RESOLUTION=' $(command -v startx11vnc) | head -n 1 | cut -d '=' -f 2)"
    else
        #/usr/bin/Xvfb :1 -screen 0 1440x720x24 -ac +extension GLX +render -noreset &
        #sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :233 -screen 0 ${TARGET}x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)"
        sed -i "s@TMOE_X11_RESOLUTION=.*@TMOE_X11_RESOLUTION=${TARGET}@" "$(command -v startx11vnc)"
        printf '%s\n' 'Your current resolution has been modified.'
        printf "%s\n" "您当前的分辨率已经修改为$(grep 'TMOE_X11_RESOLUTION=' $(command -v startx11vnc) | head -n 1 | cut -d '=' -f 2)"
        printf "%s\n" "You can type startx11vnc to restart it."
    fi
}
############################
######################
check_vnc_resolution() {
    CURRENT_VNC_RESOLUTION=$(grep '\-geometry' "$(command -v startvnc)" | tail -n 1 | cut -d 'y' -f 2 | cut -d '-' -f 1)
}
modify_vnc_conf() {
    if [ ! -e /usr/local/bin/startvnc ]; then
        printf "%s\n" "/usr/local/bin/startvnc is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
        printf '%s\n' '未检测到startvnc,您可能尚未安装图形桌面，是否继续编辑?'
        printf "%s\n" "${YELLOW}按回车键确认编辑。${RESET}"
        RETURN_TO_WHERE='modify_remote_desktop_config'
        do_you_want_to_continue
    fi
    check_vnc_resolution
    if (whiptail --title "modify vnc configuration" --yes-button '分辨率resolution' --no-button '其它other' --yesno "Which configuration do you want to modify?" 9 50); then
        TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,720x1140,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为1440x720,当前为${CURRENT_VNC_RESOLUTION}。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
        if [ "$?" != "0" ]; then
            modify_other_vnc_conf
        elif [ -z "${TARGET}" ]; then
            printf "%s\n" "请输入有效的数值"
            printf "%s\n" "Please enter a valid value"
        else
            sed -i '/vncserver -geometry/d' "$(command -v startvnc)"
            sed -i "$ a\vncserver -geometry ${TARGET} -depth 24 -name tmoe-linux :1" "$(command -v startvnc)"
            sed -i "s@geometry=.*@geometry=${TARGET}@" ${TIGER_VNC_DEFAULT_CONFIG_FILE}
            printf '%s\n' 'Your current resolution has been modified.'
            check_vnc_resolution
            printf "%s\n" "您当前的分辨率已经修改为${CURRENT_VNC_RESOLUTION}"
            stopvnc 2>/dev/null
            press_enter_to_return
            modify_remote_desktop_config
        fi
    else
        modify_other_vnc_conf
    fi
    #printf "%s\n" "您当前的分辨率为${CURRENT_VNC_RESOLUTION}"
}
############################
modify_xsdl_conf() {
    if [ "${RETURN_TO_TMOE_MENU_01}" = 'modify_remote_desktop_config' ]; then
        if [ ! -f /usr/local/bin/startxsdl ]; then
            printf "%s\n" "/usr/local/bin/startxsdl is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
            printf '%s\n' '未检测到startxsdl,您可能尚未安装图形桌面，是否继续编辑。'
            RETURN_TO_WHERE='modify_remote_desktop_config'
            do_you_want_to_continue
        fi
        TMOE_XSDL_SCRIPT_PATH='/usr/local/bin/startxsdl'
    else
        TMOE_XSDL_SCRIPT_PATH='/usr/local/bin/startqemu'
    fi
    XSDL_XSERVER=$(whiptail --title "Modify x server conf" --menu "Type startxsdl to start x11.输startxsdl启动x11" 0 50 0 \
        "1" "Pulse server port音频端口" \
        "2" "Display number显示编号" \
        "3" "ip address" \
        "4" "Edit manually手动编辑" \
        "5" "DISPLAY switch转发显示开关(仅qemu)" \
        "6" "VcXsrv显示端口(仅win10)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ###########
    case "${XSDL_XSERVER}" in
    0 | "") ${RETURN_TO_TMOE_MENU_01} ;;
    1) modify_pulse_server_port ;;
    2) modify_display_port ;;
    3) modify_xsdl_ip_address ;;
    4) modify_startxsdl_manually ;;
    5) disable_tmoe_qemu_remote_display ;;
    6) modify_vcxsrv_display_port ;;
    esac
    ########################################
    press_enter_to_return
    modify_xsdl_conf
}
#################
disable_tmoe_qemu_remote_display() {
    if grep -q '^export.*DISPLAY' "${TMOE_XSDL_SCRIPT_PATH}"; then
        XSDL_DISPLAY_STATUS='检测到您已经启用了转发X显示画面的功能，打开qemu时，画面将转发至远程XServer'
        printf "%s\n" "${XSDL_DISPLAY_STATUS}"
        printf "%s\n" "是否需要禁用?"
        printf "%s\n" "Do you want to disable it"
        do_you_want_to_continue
        sed -i '/export DISPLAY=/d' ${TMOE_XSDL_SCRIPT_PATH}
        printf "%s\n" "禁用完成"
    else
        XSDL_DISPLAY_STATUS='检测到您尚未启用转发X显示画面的功能，打开qemu时，将直接调用当前显示器的窗口。'
        printf "%s\n" "${XSDL_DISPLAY_STATUS}"
        printf "%s\n" "是否需要启用？"
        printf "%s\n" "Do you want to enable it"
        do_you_want_to_continue
        sed -i "1 a\export DISPLAY=127.0.0.1:0" ${TMOE_XSDL_SCRIPT_PATH}
        printf "%s\n" "启用完成"
    fi
}
#################
modify_startxsdl_manually() {
    nano ${TMOE_XSDL_SCRIPT_PATH}
    printf '%s\n' 'See your current xsdl configuration information below.'

    check_tmoe_xsdl_display_ip
    printf "%s\n" "您当前的显示服务的ip地址为${CURRENT_DISPLAY_IP}"

    check_tmoe_xsdl_display_port
    printf "%s\n" "您当前的显示端口为${CURRENT_DISPLAY_PORT}"

    check_tmoe_xsdl_pulse_audio_port
    printf "%s\n" "您当前的音频(ip/端口)为${CURRENT_PULSE_AUDIO_PORT}"
}
######################
check_tmoe_xsdl_display_ip() {
    CURRENT_DISPLAY_IP=$(grep 'export DISPLAY' ${TMOE_XSDL_SCRIPT_PATH} | head -n 1 | cut -d '=' -f 2 | cut -d ':' -f 1)
}
######
check_tmoe_vcxsrv_display_port() {
    CURRENT_VSCSRV_DISPLAY_PORT=$(grep 'VCXSRV_DISPLAY_PORT=' ${TMOE_XSDL_SCRIPT_PATH} | head -n 1 | cut -d '=' -f 2)
}
######
check_tmoe_xsdl_display_port() {
    CURRENT_DISPLAY_PORT=$(grep 'export DISPLAY' ${TMOE_XSDL_SCRIPT_PATH} | head -n 1 | cut -d '=' -f 2 | cut -d ':' -f 2)
}
#######
check_tmoe_xsdl_pulse_audio_port() {
    CURRENT_PULSE_AUDIO_PORT=$(grep 'export PULSE_SERVER' ${TMOE_XSDL_SCRIPT_PATH} | head -n 1 | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
}
#################
modify_pulse_server_port() {
    check_tmoe_xsdl_pulse_audio_port
    TARGET=$(whiptail --inputbox "若xsdl app显示的端口非4713，则您可在此处修改。默认为4713，当前为${CURRENT_PULSE_AUDIO_PORT}\n请以xsdl app显示的pulse_server地址的最后几位数字为准。若您的宿主机系统非Android,而是win10,且使用了tmoe-linux自带的pulseaudio，则端口为0,输入完成后按回车键确认。" 15 50 --title "MODIFY PULSE SERVER PORT " 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        modify_xsdl_conf
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        #sed -i "4 c export PULSE_SERVER=tcp:127.0.0.1:${TARGET}" "$(command -v startxsdl)"
        PULSE_LINE=$(grep 'export PULSE_SERVER' -n "${TMOE_XSDL_SCRIPT_PATH}" | head -n 1 | awk '{print $1}' | cut -d ':' -f 1)
        CURRENT_PULSE_IP=$(grep 'export PULSE_SERVER' ${TMOE_XSDL_SCRIPT_PATH} | head -n 1 | cut -d '=' -f 2 | cut -d ':' -f 2)
        sed -i "${PULSE_LINE} c\export PULSE_SERVER=tcp:${CURRENT_PULSE_IP}:${TARGET}" ${TMOE_XSDL_SCRIPT_PATH}
        printf '%s\n' 'Your current PULSE SERVER port has been modified.'
        check_tmoe_xsdl_pulse_audio_port
        printf "%s\n" "您当前的音频端口已修改为${CURRENT_PULSE_AUDIO_PORT}"
    fi
}
########################################################
modify_vcxsrv_display_port() {
    check_tmoe_vcxsrv_display_port
    TARGET=$(whiptail --inputbox "若您需要指定vcxsrv的显示端口,\n则可在此处修改。默认为37985，当前为${CURRENT_VSCSRV_DISPLAY_PORT}" 0 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        modify_xsdl_conf
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        DISPLAY_LINE=$(grep 'VCXSRV_DISPLAY_PORT=' -n "${TMOE_XSDL_SCRIPT_PATH}" | head -n 1 | awk '{print $1}' | cut -d ':' -f 1)
        sed -i "${DISPLAY_LINE} c\VCXSRV_DISPLAY_PORT=${TARGET}" "${TMOE_XSDL_SCRIPT_PATH}"
        printf '%s\n' 'Your current DISPLAY port has been modified.'
        check_tmoe_vcxsrv_display_port
        printf "%s\n" "您当前的VcXsrv显示端口已经修改为${CURRENT_VSCSRV_DISPLAY_PORT}"
        press_enter_to_return
        modify_xsdl_conf
    fi
}
###########
modify_display_port() {
    check_tmoe_xsdl_display_ip
    check_tmoe_xsdl_display_port
    TARGET=$(whiptail --inputbox "若xsdl app显示的Display number(输出显示的端口数字) 非0，则您可在此处修改。默认为0，当前为${CURRENT_DISPLAY_PORT}\n请以xsdl app显示的DISPLAY=:的数字为准，输入完成后按回车键确认。" 15 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        modify_xsdl_conf
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        DISPLAY_LINE=$(grep 'export DISPLAY' -n "${TMOE_XSDL_SCRIPT_PATH}" | head -n 1 | awk '{print $1}' | cut -d ':' -f 1)
        sed -i "${DISPLAY_LINE} c\export DISPLAY=${CURRENT_DISPLAY_IP}:${TARGET}" "${TMOE_XSDL_SCRIPT_PATH}"
        printf '%s\n' 'Your current DISPLAY port has been modified.'
        check_tmoe_xsdl_display_port
        printf "%s\n" "您当前的显示端口已经修改为${CURRENT_DISPLAY_PORT}"
        press_enter_to_return
        modify_xsdl_conf
    fi
}
###############################################
modify_xsdl_ip_address() {
    check_tmoe_xsdl_display_ip
    #XSDLIP=$(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)
    TARGET=$(whiptail --inputbox "若您需要用局域网其它设备来连接，则您可在下方输入该设备的IP地址。本机连接请勿修改，默认为127.0.0.1 ,当前为${CURRENT_DISPLAY_IP}\n windows设备输 ipconfig，linux设备输ip -4 -br -c a获取ip address，获取到的地址格式类似于192.168.123.234，输入获取到的地址后按回车键确认。" 15 50 --title "MODIFY DISPLAY IP" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        modify_xsdl_conf
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        sed -i "s/${CURRENT_DISPLAY_IP}/${TARGET}/g" "${TMOE_XSDL_SCRIPT_PATH}"
        printf '%s\n' 'Your current ip address has been modified.'
        check_tmoe_xsdl_display_ip
        printf "%s\n" "您当前的显示服务的ip地址已经修改为${CURRENT_DISPLAY_IP}"
        press_enter_to_return
        modify_xsdl_conf
    fi
}
#################
modify_xwayland_conf() {
    if [ ! -e "/etc/xwayland" ] && [ ! -L "/etc/xwayland" ]; then
        printf "%s\n" "${RED}WARNING！${RESET}检测到wayland目录${YELLOW}不存在${RESET}"
        printf "%s\n" "请先在termux里进行配置，再返回此处选择您需要配置的桌面环境"
        printf "%s\n" "若您无root权限，则有可能配置失败！"
        press_enter_to_return
        modify_remote_desktop_config
    fi
    if (whiptail --title "你想要对这个小可爱做什么" --yes-button "启动" --no-button 'Configure配置' --yesno "您是想要启动桌面还是配置wayland？" 9 50); then
        if [ ! -e "/usr/local/bin/startw" ] || [ ! $(command -v weston) ]; then
            printf "%s\n" "未检测到启动脚本，请重新配置"
            printf "%s\n" "Please reconfigure xwayland"
            sleep 2s
            xwayland_onekey
        fi
        /usr/local/bin/startw
    else
        configure_xwayland
    fi
}
##################
xwayland_desktop_enviroment() {
    X11_OR_WAYLAND_DESKTOP='xwayland'
    configure_remote_desktop_enviroment
}
#############
configure_xwayland() {
    RETURN_TO_WHERE='configure_xwayland'
    #进入xwayland配置文件目录
    cd /etc/xwayland/
    TMOE_OPTION=$(
        whiptail --title "CONFIGURE xwayland" --menu "您想要修改哪项配置？\nWhich configuration do you want to modify?" 0 50 0 \
            "1" "One-key conf 初始化一键配置" \
            "2" "指定xwayland桌面环境" \
            "3" "pulse_server音频服务" \
            "4" "remove 卸载/移除" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") modify_remote_desktop_config ;;
    1) xwayland_onekey ;;
    2) xwayland_desktop_enviroment ;;
    3) xwayland_pulse_server ;;
    4) remove_xwayland ;;
    esac
    ##############################
    press_enter_to_return_configure_xwayland
}
#####################
remove_xwayland() {
    printf "%s\n" "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
    #service xwayland restart
    RETURN_TO_WHERE='configure_xwayland'
    do_you_want_to_continue
    DEPENDENCY_01='weston'
    DEPENDENCY_02='xwayland'

    if [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCY_02='xorg-server-xwayland'
    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        DEPENDENCY_02='xorg-x11-server-Xwayland'
    fi
    rm -fv /etc/xwayland/startw
    printf "%s\n" "${YELLOW}已删除xwayland启动脚本${RESET}"
    printf "%s\n" "即将为您卸载..."
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
}
##############
xwayland_pulse_server() {
    cd /usr/local/bin/
    TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可以在此处修改。当前为$(grep 'PULSE_SERVER' startw | grep -v '^#' | cut -d '=' -f 2 | head -n 1) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        configure_xwayland
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        if grep '^export.*PULSE_SERVER' startw; then
            sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=${TARGET}@" startw
        else
            sed -i "3 a\export PULSE_SERVER=${TARGET}" startw
        fi
        printf '%s\n' 'Your current PULSEAUDIO SERVER address has been modified.'
        printf '%s\n' '您当前的音频地址已修改为'
        printf "%s\n" "$(grep 'PULSE_SERVER' startw | grep -v '^#' | cut -d '=' -f 2 | head -n 1)"
        press_enter_to_return_configure_xwayland
    fi
}
##############
xwayland_onekey() {
    RETURN_TO_WHERE='configure_xwayland'
    do_you_want_to_continue

    DEPENDENCY_01='weston'
    DEPENDENCY_02='xwayland'

    case "${LINUX_DISTRO}" in
    "debian")
        if [ $(command -v startplasma-x11) ]; then
            DEPENDENCY_02='xwayland plasma-workspace-wayland'
        fi
        ;;
    "arch") DEPENDENCY_02='xorg-server-xwayland' ;;
    esac
    beta_features_quick_install
    ###################
    cat >${HOME}/.config/weston.ini <<-'EndOFweston'
		[core]
		### uncomment this line for xwayland support ###
		modules=xwayland.so

		[shell]
		background-image=/usr/share/backgrounds/gnome/Aqua.jpg
		background-color=0xff002244
		panel-color=0x90ff0000
		locking=true
		animation=zoom
		#binding-modifier=ctrl
		#num-workspaces=6
		### for cursor themes install xcursor-themes pkg from Extra. ###
		#cursor-theme=whiteglass
		#cursor-size=24

		### tablet options ###
		#lockscreen-icon=/usr/share/icons/gnome/256x256/actions/lock.png
		#lockscreen=/usr/share/backgrounds/gnome/Garden.jpg
		#homescreen=/usr/share/backgrounds/gnome/Blinds.jpg
		#animation=fade

		[keyboard]
		keymap_rules=evdev
		#keymap_layout=gb
		#keymap_options=caps:ctrl_modifier,shift:both_capslock_cancel
		### keymap_options from /usr/share/X11/xkb/rules/base.lst ###

		[terminal]
		#font=DroidSansMono
		#font-size=14

		[screensaver]
		# Uncomment path to disable screensaver
		path=/usr/libexec/weston-screensaver
		duration=600

		[input-method]
		path=/usr/libexec/weston-keyboard

		###  for Laptop displays  ###
		#[output]
		#name=LVDS1
		#mode=1680x1050
		#transform=90

		#[output]
		#name=VGA1
		# The following sets the mode with a modeline, you can get modelines for your preffered resolutions using the cvt utility
		#mode=173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
		#transform=flipped

		#[output]
		#name=X1
		mode=1440x720
		#transform=flipped-270
	EndOFweston
    cd /usr/local/bin
    cat >startw <<-'EndOFwayland'
		#!/usr/bin/env bash
		chmod +x -R /etc/xwayland
		XDG_RUNTIME_DIR=/etc/xwayland Xwayland &
		export PULSE_SERVER=127.0.0.1:0
		export DISPLAY=:0
		xfce4-session
	EndOFwayland
    chmod +x startw
    xwayland_desktop_enviroment
    ###########################
    press_enter_to_return_configure_xwayland
    #此处的返回步骤并非多余
}
###########
##################
modify_xrdp_conf() {
    case "${TMOE_PROOT}" in
    true | no)
        printf "%s\n" "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
        printf "%s\n" "若您的宿主机为${BOLD}Android${RESET}系统，则${RED}无法${RESET}${BLUE}保障${RESET}xrdp可以正常连接！"
        RETURN_TO_WHERE='modify_remote_desktop_config'
        do_you_want_to_continue
        ;;
    esac
    pgrep xrdp &>/dev/null
    if [ "$?" = "0" ]; then
        FILEBROWSER_STATUS='检测到xrdp进程正在运行'
        FILEBROWSER_PROCESS='Restart重启'
    else
        FILEBROWSER_STATUS='检测到xrdp进程未运行'
        FILEBROWSER_PROCESS='Start启动'
    fi

    if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${FILEBROWSER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${FILEBROWSER_STATUS}" 9 50); then
        if [[ ! -e "${HOME}/.config/tmoe-linux/xrdp.ini" && ! -e /usr/sbin/xrdp ]]; then
            printf "%s\n" "未检测到已备份的xrdp配置文件，请重新配置"
            printf "%s\n" "Please reconfigure xrdp"
            sleep 2s
            xrdp_onekey
        fi
        xrdp_restart
    else
        configure_xrdp
    fi
}
#############
xrdp_desktop_enviroment() {
    X11_OR_WAYLAND_DESKTOP='xrdp'
    configure_remote_desktop_enviroment
}
#############
configure_xrdp() {
    #16 50 7
    #进入xrdp配置文件目录
    RETURN_TO_WHERE='configure_xrdp'
    [[ -e /etc/xrdp/ ]] || mkdir -pv /etc/xrdp
    cd /etc/xrdp/
    TMOE_OPTION=$(
        whiptail --title "CONFIGURE XRDP" --menu "Type service xrdp start to start it" 0 0 0 \
            "1" "One-key conf 初始化一键配置" \
            "2" "指定xrdp桌面环境" \
            "3" "xrdp port 修改xrdp端口" \
            "4" "xrdp.ini修改配置文件" \
            "5" "startwm.sh修改启动脚本" \
            "6" "stop 停止" \
            "7" "status 进程状态" \
            "8" "pulse_server音频服务" \
            "9" "reset 重置" \
            "10" "remove 卸载/移除" \
            "11" "进程管理说明" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") modify_remote_desktop_config ;;
    1)
        service xrdp stop 2>/dev/null || systemctl stop xrdp
        xrdp_onekey
        ;;
    2)
        X11_OR_WAYLAND_DESKTOP='xrdp'
        #xrdp_desktop_enviroment
        configure_remote_desktop_enviroment
        ;;
    3) xrdp_port ;;
    4) nano /etc/xrdp/xrdp.ini ;;
    5) nano /etc/xrdp/startwm.sh ;;
    6) service xrdp stop 2>/dev/null || systemctl stop xrdp ;;
    7) check_xrdp_status ;;
    8) xrdp_pulse_server ;;
    9) xrdp_reset ;;
    10) remove_xrdp ;;
    11) xrdp_systemd ;;
    esac
    ##############################
    press_enter_to_return_configure_xrdp
}
#############
check_xrdp_status() {
    if [ $(command -v service) ]; then
        service xrdp status | head -n 24
    else
        #printf "%s\n" "Type ${GREEN}q${RESET} to ${BLUE}return.${RESET}"
        systemctl status xrdp | head -n 24
    fi
}
####################
remove_xrdp() {
    pkill xrdp
    printf "%s\n" "正在停止xrdp进程..."
    printf "%s\n" "Stopping xrdp..."
    service xrdp stop 2>/dev/null || systemctl stop xrdp
    printf "%s\n" "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
    #service xrdp restart
    RETURN_TO_WHERE='configure_xrdp'
    do_you_want_to_continue
    rm -fv /etc/xrdp/xrdp.ini /etc/xrdp/startwm.sh
    printf "%s\n" "${YELLOW}已删除xrdp配置文件${RESET}"
    printf "%s\n" "即将为您卸载..."
    ${TMOE_REMOVAL_COMMAND} xrdp
}
################
configure_remote_desktop_enviroment() {
    #15 60 5
    BETA_DESKTOP=$(whiptail --title "REMOTE_DESKTOP" --menu \
        "您想要配置哪个桌面？按方向键选择，回车键确认！\n Which desktop environment do you want to configure? " 0 0 0 \
        "1" "auto 自动选择" \
        "2" "xfce：兼容性高" \
        "3" "lxde：轻量化桌面" \
        "4" "mate：基于GNOME 2" \
        "5" "lxqt" \
        "6" "kde plasma 5" \
        "7" "gnome 3" \
        "8" "cinnamon" \
        "9" "dde (deepin desktop)" \
        "0" "我一个都不选 =￣ω￣=" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${BETA_DESKTOP}" in
    0 | "") modify_remote_desktop_config ;;
    1)
        REMOTE_DESKTOP_SESSION_01='/etc/X11/xinit/Xsession'
        REMOTE_DESKTOP_SESSION_02='/etc/X11/xinit/Xsession'
        ;;
    2)
        REMOTE_DESKTOP_SESSION_01='xfce4-session'
        REMOTE_DESKTOP_SESSION_02='startxfce4'
        ;;
    3)
        REMOTE_DESKTOP_SESSION_01='lxsession'
        REMOTE_DESKTOP_SESSION_02='startlxde'
        #configure_remote_lxde_desktop
        ;;
    4)
        REMOTE_DESKTOP_SESSION_01='mate-session'
        REMOTE_DESKTOP_SESSION_02='mate-panel'
        #configure_remote_mate_desktop
        ;;
    5)
        REMOTE_DESKTOP_SESSION_01='startlxqt'
        REMOTE_DESKTOP_SESSION_02='lxqt-session'
        #configure_remote_lxqt_desktop
        ;;
    6)
        #REMOTE_DESKTOP_SESSION='plasma-x11-session'
        #configure_remote_kde_plasma5_desktop
        REMOTE_DESKTOP_SESSION_01='startplasma-x11'
        REMOTE_DESKTOP_SESSION_02='startkde'
        ;;
    7)
        REMOTE_DESKTOP_SESSION_01='gnome-session'
        REMOTE_DESKTOP_SESSION_02='gnome-panel'
        #configure_remote_gnome3_desktop
        ;;
    8)
        REMOTE_DESKTOP_SESSION_01='cinnamon-session'
        REMOTE_DESKTOP_SESSION_02='cinnamon-launcher'
        ;;
    9)
        REMOTE_DESKTOP_SESSION_01='startdde'
        REMOTE_DESKTOP_SESSION_02='dde-launcher'
        #configure_remote_deepin_desktop
        ;;
    esac
    case "${TMOE_PROOT}" in
    true | no)
        case "${LINUX_DISTRO}" in
        "debian" | "redhat""redhat") NON_DBUS='true' ;;
        esac
        ;;
    esac

    if [ $(command -v ${REMOTE_DESKTOP_SESSION_01}) ]; then
        REMOTE_DESKTOP_SESSION="${REMOTE_DESKTOP_SESSION_01}"
    else
        REMOTE_DESKTOP_SESSION="${REMOTE_DESKTOP_SESSION_02}"
    fi
    configure_remote_desktop_session
    press_enter_to_return
    modify_remote_desktop_config
}
##############
configure_xrdp_remote_desktop_session() {
    #printf "%s\n" "${REMOTE_DESKTOP_SESSION}" >~/.xsession
    #touch ~/.session
    cd /etc/xrdp
    sed -i '/Xsession/d' startwm.sh
    #sed -i '/start/d' startwm.sh
    if grep 'exec' startwm.sh; then
        sed -i '$ d' startwm.sh
        sed -i '$ d' startwm.sh
    fi
    #sed -i '/X11\/Xsession/d' startwm.sh
    cat >>startwm.sh <<-'EnfOfStartWM'
		test -x /etc/X11/Xsession && exec /etc/X11/Xsession
		exec /etc/X11/xinit/Xsession
	EnfOfStartWM
    sed -i "s@exec /etc/X11/Xsession@exec dbus-launch ${REMOTE_DESKTOP_SESSION}@g" /etc/xrdp/startwm.sh
    if [ $(command -v bat) ]; then
        bat startwm.sh
    else
        sed -n p startwm.sh
    fi
    #sed -i "s@exec /bin/sh /etc/X11/Xsession@exec ${REMOTE_DESKTOP_SESSION}@g" /etc/xrdp/startwm.sh
    press_enter_to_return
    systemctl restart xrdp || service xrdp restart
    check_xrdp_status
}
##############
configure_xwayland_remote_desktop_session() {
    cd /usr/local/bin
    cat >startw <<-EndOFwayland
		#!/usr/bin/env bash
		chmod +x -R /etc/xwayland
		XDG_RUNTIME_DIR=/etc/xwayland Xwayland &
		export PULSE_SERVER=127.0.0.1:0
		export DISPLAY=:0
		${REMOTE_DESKTOP_SESSION}
	EndOFwayland
    printf "%s\n" "${REMOTE_DESKTOP_SESSION}"
    chmod +x startw
    printf "%s\n" "配置完成，请先打开sparkle app，点击Start"
    printf "%s\n" "然后在GNU/Linux容器里输startw启动xwayland"
    printf "%s\n" "在使用过程中，您可以按音量+调出键盘"
    printf "%s\n" "执行完startw后,您可能需要经历长达30s的黑屏"
    printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET}"
    printf "%s\n" "按${GREEN}回车键${RESET}执行${BLUE}startw${RESET}"
    read
    startw
}
#################
configure_remote_desktop_session() {
    if [ "${X11_OR_WAYLAND_DESKTOP}" == 'xrdp' ]; then
        configure_xrdp_remote_desktop_session
    elif [ "${X11_OR_WAYLAND_DESKTOP}" == 'xwayland' ]; then
        configure_xwayland_remote_desktop_session
    elif [ "${X11_OR_WAYLAND_DESKTOP}" == 'x11vnc' ]; then
        configure_x11vnc_remote_desktop_session
    fi
}
#####################
xrdp_pulse_server() {
    cd /etc/xrdp
    TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。linux默认为127.0.0.1,WSL2默认为宿主机ip,当前为$(grep 'PULSE_SERVER' startwm.sh | grep -v '^#' | cut -d '=' -f 2 | head -n 1) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        configure_xrdp
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        if ! grep -q '^export.*PULSE_SERVER' startwm.sh; then
            sed -i "1 a\export PULSE_SERVER=${TARGET}" startwm.sh
        fi
        sed -i -E "s@(export.*PULSE_SERVER=).*@\1${TARGET}@" startwm.sh
        printf '%s\n' 'Your current PULSEAUDIO SERVER address has been modified.'
        printf '%s\n' '您当前的音频地址已修改为'
        printf "%s\n" "$(grep 'PULSE_SERVER' startwm.sh | grep -v '^#' | cut -d '=' -f 2 | head -n 1)"
        press_enter_to_return_configure_xrdp
    fi
}
##############
xrdp_onekey() {
    RETURN_TO_WHERE='configure_xrdp'
    do_you_want_to_continue
    if [[ ! $(command -v xrdp-keygen) && ! -e /usr/sbin/xrdp ]]; then
        case "${LINUX_DISTRO}" in
        gentoo)
            emerge -avk layman
            layman -a bleeding-edge
            layman -S
            #ACCEPT_KEYWORDS="~amd64" USE="server" emerge -a xrdp
            ;;
        *)
            DEPENDENCY_01=''
            DEPENDENCY_02='xrdp'
            ;;
        esac
        printf "Do you want to install xrdp?"
        beta_features_quick_install
    fi
    ##############
    mkdir -pv /etc/polkit-1/localauthority.conf.d /etc/polkit-1/localauthority/50-local.d/
    cat >/etc/polkit-1/localauthority.conf.d/02-allow-colord.conf <<-'EndOfxrdp'
		polkit.addRule(function(action, subject) {
		if ((action.id == “org.freedesktop.color-manager.create-device” || action.id == “org.freedesktop.color-manager.create-profile” || action.id == “org.freedesktop.color-manager.delete-device” || action.id == “org.freedesktop.color-manager.delete-profile” || action.id == “org.freedesktop.color-manager.modify-device” || action.id == “org.freedesktop.color-manager.modify-profile”) && subject.isInGroup(“{group}”))
		{
		return polkit.Result.YES;
		}
		});
	EndOfxrdp
    #############
    cat >/etc/polkit-1/localauthority/50-local.d/45-allow.colord.pkla <<-'ENDofpolkit'
		[Allow Colord all Users]
		Identity=unix-user:*
		Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
		ResultAny=no
		ResultInactive=no
		ResultActive=yes

		[Allow Package Management all Users]
		Identity=unix-user:*
		Action=org.debian.apt.*;io.snapcraft.*;org.freedesktop.packagekit.*;com.ubuntu.update-notifier.*
		ResultAny=no
		ResultInactive=no
		ResultActive=yes
	ENDofpolkit
    ###################
    if [ ! -e "${HOME}/.config/tmoe-linux/xrdp.ini" ]; then
        mkdir -pv ${HOME}/.config/tmoe-linux/
        cd /etc/xrdp/
        cp -p startwm.sh xrdp.ini ${HOME}/.config/tmoe-linux/
    fi
    ####################
    #printf '%s\n' 'xfce4-session' >~/.xsession
    #touch ~/.session
    sed -i 's@exec /etc/X11/Xsession@exec /etc/X11/xinit/Xsession@g;s:exec /bin/sh /etc/X11/Xsession:exec /etc/X11/xinit/Xsession:g' /etc/xrdp/startwm.sh
    if ! grep -q '^export PULSE_SERVER' /etc/xrdp/startwm.sh; then
        sed -i '/test -x \/etc\/X11/i\export PULSE_SERVER=127.0.0.1' /etc/xrdp/startwm.sh
    fi
    if [ $(command -v bat) ]; then
        bat /etc/xrdp/startwm.sh
    else
        sed -n p /etc/xrdp/startwm.sh
    fi
    ###########################
    if [ "${WINDOWS_DISTRO}" = 'WSL' ]; then
        #if grep -q '172..*1' "/etc/resolv.conf"; then
        if [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
            printf "%s\n" "检测到您当前使用的可能是WSL2"
            #WSL2IP=$(sed -n p /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
            #sed -i "s/^export PULSE_SERVER=.*/export PULSE_SERVER=${WSL2IP}/g" /etc/xrdp/startwm.sh
            sed -i "s/^export PULSE_SERVER=.*/export PULSE_SERVER=\$(ip route list table 0 | head -n 1 | awk -F 'default via ' '{print \$2}' |awk '{print \$1}')/g" /etc/xrdp/startwm.sh
        fi
        #printf "%s\n" "已将您的音频服务ip修改为${WSL2IP}"
        #fi
        printf '%s\n' '检测到您使用的是WSL,为防止与windows自带的远程桌面的3389端口冲突，请您设定一个新的端口'
        sleep 2s
    fi
    case ${TMOE_CHROOT} in
    true) usermod -a -G aid_inet xrdp ;;
    esac
    xrdp_port
    xrdp_restart
    ################
    press_enter_to_return_configure_xrdp
    #此处的返回步骤并非多余
}
############
xrdp_restart() {
    cd /etc/xrdp/
    RDP_PORT=$(cat xrdp.ini | grep 'port=' | head -n 1 | cut -d '=' -f 2)
    service xrdp restart 2>/dev/null || systemctl restart xrdp
    if [ "$?" != "0" ]; then
        /etc/init.d/xrdp restart
    fi
    check_xrdp_status
    printf "%s\n" "您可以输${YELLOW}service xrdp stop${RESET}来停止进程"
    printf "%s\n" "您当前的IP地址为"
    ip -4 -br -c a | cut -d '/' -f 1
    printf "%s\n" "端口号为${RDP_PORT}"
    printf "%s\n" "正在为您启动xrdp服务，本机默认访问地址为localhost:${RDP_PORT}"
    TMOE_IP_ADDR=$(ip -4 -br -c a | awk '{print $NF}' | cut -d '/' -f 1 | grep -v '127\.0\.0\.1')
    echo The LAN VNC address 局域网地址 ${TMOE_IP_ADDR} | sed "s@\$@:${RDP_PORT}@"
    #echo The LAN address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${RDP_PORT}
    printf "%s\n" "如需停止xrdp服务，请输service xrdp stop或systemctl stop xrdp"
    printf "%s\n" "如需修改当前用户密码，请输passwd"
    if [ "${LINUX_DISTRO}" = "arch" ]; then
        printf "%s\n" "检测到您使用的是arch系发行版，您之后可以输xrdp来启动xrdp服务"
        xrdp
    fi
    if [ "${WINDOWS_DISTRO}" = 'WSL' ]; then
        printf '%s\n' '检测到您使用的是WSL，正在为您打开音频服务'
        export PULSE_SERVER=127.0.0.1
        #if grep -q '172..*1' "/etc/resolv.conf"; then
        if [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
            printf "%s\n" "检测到您当前使用的可能是WSL2"
            #WSL2IP=$(sed -n p /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
            export PULSE_SERVER=$(ip route list table 0 | head -n 1 | awk -F 'default via ' '{print $2}' | awk '{print $1}')
            printf "%s\n" "已将您的音频服务ip修改为${PULSE_SERVER}"
        fi
        cd "/mnt/c/Users/Public/Downloads/pulseaudio/bin"
        /mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat" 2>/dev/null
        printf "%s\n" "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
    fi
}
#################
xrdp_port() {
    cd /etc/xrdp/
    RDP_PORT=$(cat xrdp.ini | grep 'port=' | head -n 1 | cut -d '=' -f 2)
    TARGET=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,不建议您将其设置为22、80、443或3389,检测到您当前的端口为${RDP_PORT}\n Please type the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        #printf "%s\n" "检测到您取消了操作"
        ${RETURN_TO_WHERE}
        #printf "%s\n" "检测到您取消了操作，请返回重试。"
        #press_enter_to_return_configure_xrdp
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        sed -i "s@port=${RDP_PORT}@port=${TARGET}@" xrdp.ini
        ls -l $(pwd)/xrdp.ini
        cat xrdp.ini | grep 'port=' | head -n 1
        /etc/init.d/xrdp restart
    fi
}
#################
xrdp_systemd() {
    case "${TMOE_PROOT}" in
    true | no)
        printf "%s\n" "检测到您当前处于${BLUE}proot容器${RESET}环境下，无法使用systemctl命令"
        ;;
    false) printf "%s\n" "检测到您当前处于chroot容器环境下，无法使用systemctl命令" ;;
    esac
    cat <<-'EOF'
		    systemd管理
			输systemctl start xrdp启动
			输systemctl stop xrdp停止
			输systemctl status xrdp查看进程状态
			输systemctl enable xrdp开机自启
			输systemctl disable xrdp禁用开机自启

			service命令
			输service xrdp start启动
			输service xrdp stop停止
			输service xrdp status查看进程状态

		    init.d管理
			/etc/init.d/xrdp start启动
			/etc/init.d/xrdp restart重启
			/etc/init.d/xrdp stop停止
			/etc/init.d/xrdp statuss查看进程状态
			/etc/init.d/xrdp force-reload重新加载
	EOF
}
###############
xrdp_reset() {
    printf "%s\n" "正在停止xrdp进程..."
    printf "%s\n" "Stopping xrdp..."
    pkill xrdp
    service xrdp stop 2>/dev/null
    printf "%s\n" "${YELLOW}WARNING！继续执行此操作将丢失xrdp配置信息！${RESET}"
    RETURN_TO_WHERE='configure_xrdp'
    do_you_want_to_continue
    rm -f /etc/polkit-1/localauthority/50-local.d/45-allow.colord.pkla /etc/polkit-1/localauthority.conf.d/02-allow-colord.conf
    cd ${HOME}/.config/tmoe-linux
    cp -pvf xrdp.ini startwm.sh /etc/xrdp/
}
#################################
#################################
configure_startxsdl() {
    cd /usr/local/bin
    cp -f ${TMOE_TOOL_DIR}/gui/startxsdl ./
    #--exit-with-session
    #启动命令结尾无&
    ###############################
    #debian禁用dbus分两次，并非重复
    if [ "${NON_DBUS}" = "true" ]; then
        case "${TMOE_PROOT}" in
        true | no) #sed -i 's:dbus-launch --exit-with-session::' startxsdl ${XSESSION_FILE} ;;
            sed -i 's:dbus-launch::' ${XSESSION_FILE} ;;
        esac
    fi
}
#################
configure_startvnc() {
    cd /usr/local/bin
    #rm -f startvnc
    cp -f ${TMOE_TOOL_DIR}/gui/startvnc ${TMOE_TOOL_DIR}/gui/stopvnc ./
}
###############
fix_non_root_permissions() {
    if [ ${HOME} != '/root' ]; then
        printf "%s\n" "检测到${HOME}目录不为/root，为避免权限问题，正在将${CURRENT_USER_FILE}的权限归属修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        sudo -E chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} "${CURRENT_USER_FILE}" || su -c "chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${CURRENT_USER_FILE}"
    fi
}
################
tiger_vnc_variable() {
    VNC_SERVER_BIN="tigervnc"
    VNC_SERVER_BIN_NOW="tightvncserver"
    #无需安装tigervnc-xorg-extension
    DEPENDENCY_01="tigervnc-viewer"
    DEPENDENCY_02="tigervnc-standalone-server"
}
#######
tight_vnc_variable() {
    VNC_SERVER_BIN="tightvnc"
    VNC_SERVER_BIN_NOW="tigervnc-standalone-server"
    DEPENDENCY_01="tigervnc-viewer xfonts-100dpi xfonts-75dpi xfonts-scalable"
    DEPENDENCY_02="tightvncserver"
}
######
debian_remove_vnc_server() {
    printf "%s\n" "${RED}apt remove -y ${VNC_SERVER_BIN_NOW}${RESET}"
    apt remove -y ${VNC_SERVER_BIN_NOW}
}
debian_install_vnc_server() {
    debian_remove_vnc_server
    printf "%s\n" "${BLUE}${TMOE_INSTALLATION_COMMAND} ${DEPENDENCY_02} ${DEPENDENCY_01}${RESET}"
    ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCY_02}
    ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCY_01}
    if [ -e "/usr/share/fonts/X11/Type1" ] && [ ! -e /usr/share/fonts/X11/Speedo ]; then
        ln -svf /usr/share/fonts/X11/Type1 /usr/share/fonts/X11/Speedo
    fi
}
#######
grep_tiger_vnc_deb_file() {
    LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '\.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME_01}" | grep "${GREP_NAME_02}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
    LATEST_DEB_URL="${LATEST_DEB_REPO}${LATEST_DEB_VERSION}"
}
#######
ubuntu_install_tiger_vnc_server() {
    apt-mark unhold tigervnc-common tigervnc-standalone-server
    debian_install_vnc_server
    LATEST_DEB_REPO="https://mirrors.bfsu.edu.cn/debian/pool/main/t/tigervnc/"
    GREP_NAME_01='tigervnc-common'
    GREP_NAME_02='deb10'
    TEMP_FOLDER='/tmp/.TIGER_VNC_TEMP_FOLDER'
    mkdir ${TEMP_FOLDER}
    cd ${TEMP_FOLDER}
    grep_tiger_vnc_deb_file
    aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "tigervnc-common_ubuntu-focal.deb" "${LATEST_DEB_URL}"
    GREP_NAME_01='tigervnc-standalone-server'
    grep_tiger_vnc_deb_file
    aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "tigervnc-standalone-server_ubuntu-focal.deb" "${LATEST_DEB_URL}"
    LATEST_DEB_REPO="https://mirrors.bfsu.edu.cn/debian/pool/main/libj/libjpeg-turbo/"
    GREP_NAME_01='libjpeg62-turbo_'
    GREP_NAME_02='deb'
    grep_tiger_vnc_deb_file
    aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "libjpeg62-turbo_ubuntu-focal.deb" "${LATEST_DEB_URL}"
    dpkg -i ./libjpeg62-turbo_ubuntu-focal.deb ./tigervnc-common_ubuntu-focal.deb ./tigervnc-standalone-server_ubuntu-focal.deb
    apt-mark hold tigervnc-common tigervnc-standalone-server
    cd ~
    rm -rv ${TEMP_FOLDER}
}
###########
modify_to_xfwm4_breeze_theme() {
    case ${TMOE_HIGH_DPI} in
    true) ;;
    *) [[ ! -e "/usr/share/themes/Breeze/xfwm4/themerc" ]] || dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Breeze 2>/dev/null ;;
    esac
}
##########
which_vnc_server_do_you_prefer() {
    case "${REMOTE_DESKTOP_SESSION_01}" in
    startplasma* | startlxqt | gnome* | cinnamon* | startdde | ukui* | budgie*)
        if (whiptail --title "Which vnc server do you prefer" --yes-button 'tiger' --no-button 'tight' --yesno "您想要选择哪个VNC服务端?(っ °Д °)\n检测到桌面的session/startup文件为${REMOTE_DESKTOP_SESSION_01},请选择tiger！\nPlease choose tiger vncserver！" 0 50); then
            tiger_vnc_variable
            modify_to_xfwm4_breeze_theme
        else
            tight_vnc_variable
        fi
        ;;
    *)
        if (whiptail --title "Which vnc server do you prefer" --yes-button 'tiger' --no-button 'tight' --yesno "您想要选择哪个VNC服务端?(っ °Д °)\n尽管tight可能更加流畅,但是tiger比tight支持更多的特效和选项,例如鼠标指针和背景透明等\nAlthough tiger can show more special effects,tight may be smoother.\nIt is recommended that you use tiger." 0 50); then
            tiger_vnc_variable
            modify_to_xfwm4_breeze_theme
        else
            tight_vnc_variable
        fi
        ;;
    esac
    case_debian_distro_and_install_vnc
}
###################
case_debian_distro_and_install_vnc() {
    case ${DEBIAN_DISTRO} in
    ubuntu)
        if egrep -q 'Focal Fossa|focal|Eoan Ermine' "/etc/os-release"; then
            case ${VNC_SERVER_BIN} in
            tigervnc)
                case $(apt list --installed 2>&1 | grep 'tigervnc-standalone-server' | awk '{print $2}') in
                1.9.*) debian_remove_vnc_server ;;
                *) ubuntu_install_tiger_vnc_server ;;
                esac
                ;;
            *)
                apt-mark unhold tigervnc-common tigervnc-standalone-server
                debian_install_vnc_server
                ;;
            esac
        else
            debian_install_vnc_server
        fi
        ;;
    *) debian_install_vnc_server ;;
    esac
}
#########
first_configure_startvnc() {
    #卸载udisks2，会破坏mate和plasma的依赖关系。
    case "${TMOE_PROOT}" in
    true | no)
        if [ ${REMOVE_UDISK2} = 'true' ]; then
            if [ "${LINUX_DISTRO}" = 'debian' ]; then
                if egrep -q 'Focal Fossa|focal|bionic|Bionic Beaver|Eoan Ermine|buster|stretch|jessie|Deepin 20|Uos 20' "/etc/os-release"; then
                    printf "%s\n" "检测到您处于${BLUE}proot容器${RESET}环境下，即将为您${RED}卸载${RESET}${YELLOW}udisk2${RESET}和${GREEN}gvfs${RESET}"
                    #umount .gvfs
                    apt purge -y --allow-change-held-packages ^udisks2 ^gvfs
                fi
            fi
        fi
        ;;
    esac

    configure_startvnc
    configure_startxsdl
    chmod +x startvnc stopvnc startxsdl
    #if [ "${LINUX_DISTRO}" != "debian" ]; then
    #sed -i 's@--exit-with-session@@' ${XSESSION_FILE}
    #/usr/local/bin/startxsdl
    #else
    #|stretch|jessie    #if ! egrep -q 'Focal Fossa|focal|Eoan Ermine' "/etc/os-release"; then
    case ${LINUX_DISTRO} in
    debian) which_vnc_server_do_you_prefer ;;
    esac
    #fi
    ######################
    dpkg --configure -a 2>/dev/null
    if [ ! -s "${HOME}/.vnc/passwd" ]; then
        set_vnc_passwd
    fi
    choose_vnc_port_5901_or_5902
    printf "$BLUE"
    cat <<-'EndOFneko'
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
    printf '%s\n' '------------------------'
    TMOE_HIGH_DPI='default'
    if [ -e "${TMOE_LINUX_DIR}/wm_size.txt" ]; then
        RESOLUTION=$(awk -F 'x' '{print $2,$1}' ${TMOE_LINUX_DIR}/wm_size.txt | sed 's@ @x@')
        HORIZONTAL_PIXELS=$(awk -F 'x' '{print $2}' ${TMOE_LINUX_DIR}/wm_size.txt | head -n 1)
        if ((${HORIZONTAL_PIXELS} >= 2340)); then
            TMOE_HIGH_DPI='true'
        else
            TMOE_HIGH_DPI='false'
        fi
        expr ${HORIZONTAL_PIXELS} + 0 &>/dev/null
        case "$?" in
        0) ;;
        *) RESOLUTION='' ;;
        esac
    else
        RESOLUTION=''
    fi
    ##########
    if [ ! -z "${RESOLUTION}" ]; then
        if (whiptail --title "Is your resolution ${RESOLUTION}?" --yes-button 'YES' --no-button 'NO' --yesno "检测到您的宿主机为Android系统,且分辨率为${RESOLUTION}" 0 50); then
            printf "%s\n" "Your resolution is ${RESOLUTION}"
        else
            RESOLUTION='1440x720'
            TMOE_HIGH_DPI='default'
        fi
    fi
    ###########
    case "${REMOTE_DESKTOP_SESSION_01}" in
    xfce4-session)
        if [ -z "${RESOLUTION}" ]; then
            if (whiptail --title "Are you using a 720P/1080P monitor" --yes-button 'YES' --no-button 'NO' --yesno "您当前是否使用720P/1080P分辨率的屏幕/显示器?(っ °Д °)\n设屏幕分辨率为x,若720P<=x<=1080p,则选择YES;若2K<=x<=4K,则选择NO\nIf you are using a high-dpi monitor, then choose NO" 0 50); then
                RESOLUTION='1440x720'
                TMOE_HIGH_DPI='default'
            else
                RESOLUTION='2880x1440'
                TMOE_HIGH_DPI='true'
            fi
        fi
        ;;
    lxsession)
        for i in /etc/xdg/autostart/lxpolkit.desktop /usr/bin/lxpolkit; do
            if [ -f "${i}" ]; then
                mv -f ${i} ${i}.bak 2>/dev/null
            fi
        done
        unset i
        ;;
    esac
    #######
    if [ -z "${RESOLUTION}" ]; then
        RESOLUTION='1440x720'
        TMOE_HIGH_DPI='default'
    fi
    case ${TMOE_HIGH_DPI} in
    true) xfce4_tightvnc_hidpi_settings ;;
    false) tmoe_gui_normal_dpi ;;
    default) tmoe_gui_default_dpi ;;
    esac
    ######
    if [ ${HOME} != '/root' ]; then
        printf "%s\n" "检测到${HOME}目录不为/root，为避免权限问题，正在将${HOME}目录下的.ICEauthority, .Xauthority, .config, .cache, .dbus以及.vnc的权限归属修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        cd ${HOME}
        sudo -E chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ".ICEauthority" ".Xauthority" ".vnc" ".config" ".cache" ".dbus" || su -c "chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} .ICEauthority .Xauthority .vnc .config .cache .dbus"
    fi
    ######
    cat <<-EOF
		------------------------
		一：
		${YELLOW}关于音频服务无法自动启动的说明${RESET}：
		------------------------
		If you find that you cannot connect to the audio server after starting vnc, please create a new termux session and type ${GREEN}pulseaudio --start${RESET}.
		正常情况下，音频服务会自动启用。若因某些特殊原因导致启动或调用异常，则请您阅读以下说明。
		------------------------
		若您的音频服务端为${BLUE}Android系统${RESET}，请在图形界面启动完成后，新建一个termux会话窗口，然后手动在termux原系统里输${GREEN}pulseaudio -D${RESET}来启动音频服务后台进程。若您无法记住该命令，则只需输${GREEN}debian${RESET}。
		------------------------
		若您的音频服务端为${BLUE}windows10系统${RESET}，则请手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'。
		注：您无需修改PULSE_SERVER变量,WSL2的音频服务地址将根据NAT网关自动生成。
		------------------------
		若您使用的是${BLUE}Android版${RESET}${YELLOW}Linux Deploy${RESET}或${YELLOW}Userland${RESET}，则您可以使用本脚本${RED}覆盖安装${RESET}图形界面。之后,您可以在${BLUE}Termux${RESET}上输${GREEN}debian-i${RESET}运行Tmoe-linux manager,查看${YELLOW}FAQ${RESET}并配置Linux Deploy的${BLUE}音频服务启动脚本。${RESET}
		------------------------
	EOF
    printf "%s\n" "二："
    printf "%s\n" "${YELLOW}关于VNC和X的启动说明${RESET}"
    printf '%s\n' '------------------------'
    printf "%s\n" "You can type ${GREEN}startvnc${RESET} to ${YELLOW}start ${BLUE}vncserver${RESET},type ${GREEN}stopvnc${RESET} to ${RED}stop${RESET} it."
    printf "%s\n" "You can also type ${GREEN}startxsdl${RESET} to ${YELLOW}start ${BLUE}X client and server${RESET}."
    printf '%s\n' '------------------------'
    printf "%s\n" "您之后可以在原系统里输${BOLD}${GREEN}startvnc${RESET}${YELLOW}同时启动${BLUE}vnc服务端和客户端${RESET}。"
    printf "%s\n" "在容器里输${BOLD}${GREEN}startvnc${RESET}${PURPLE}(仅支持)${YELLOW}启动${BLUE}vnc服务端${RESET}，输${GREEN}stopvnc${RED}停止${RESET}"
    printf "%s\n" "在原系统里输${BOLD}${GREEN}startxsdl${RESET}同时启动X客户端与服务端"
    printf '%s\n' '------------------------'
    printf '%s\n' '------------------------'
    if [ "${HOME}" != "/root" ]; then
        cp -rpf ~/.vnc /root/
        chown -R 0:0 /root/.vnc
    fi
    if [ "${WINDOWS_DISTRO}" = 'WSL' ]; then
        #printf "%s\n" "若无法自动打开X服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe"
        printf "%s\n" "Win10 ${YELLOW}xserver bin file${RESET}: ${BLUE}C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe${RESET}"
        cd "/mnt/c/Users/Public/Downloads"
        #if grep -q '172..*1' "/etc/resolv.conf"; then
        if [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
            printf "%s\n" "检测到您当前使用的可能是WSL2，如需手动启动，请在xlaunch.exe中勾选Disable access control"
            printf "%s\n" "You can type ${GREEN}startxsdl${RESET} to ${BLUE}start${RESET} X client and win10 xserver(VcXsrv)."
            WSL2IP=$(ip route list table 0 | head -n 1 | awk -F 'default via ' '{print $2}' | awk '{print $1}')
            export PULSE_SERVER=${WSL2IP}
            export DISPLAY=${WSL2IP}:0
            printf "%s\n" "已将您的X和音频服务ip修改为${YELLOW}${WSL2IP}${RESET}"
            printf "%s\n" "You are using WSL2,and your host ip is ${YELLOW}${WSL2IP}${RESET}"
        else
            printf "%s\n" "${YELLOW}检测到您使用的是WSL1(初代win10的Linux子系统)${RESET}"
            printf "%s\n" "${YELLOW}若无法启动x服务，则请在退出脚本后，以非root身份手动输startxsdl来启动windows的x服务${RESET}"
            printf "%s\n" "您也可以手动输startvnc来启动vnc服务"
            printf "%s\n" "You are using${YELLOW}WSL1${RESET}."
            printf "%s\n" "You can type ${GREEN}startxsdl${RESET} to start windows xserver and linux xclient."
        fi
        cd ./VcXsrv
        printf "%s\n" "请在启动音频服务前，确保您已经允许pulseaudio.exe通过Windows Defender防火墙"
        printf "%s\n" "You need to allow pulseaudio to pass through the defender firewall, otherwise you will not be able to use the local audio service."
        if [ ! -e "Firewall-pulseaudio.png" ]; then
            aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "Firewall-pulseaudio.png" 'https://gitee.com/mo2/pic_api/raw/test/2020/03/31/rXLbHDxfj1Vy9HnH.png'
        fi
        /mnt/c/WINDOWS/system32/cmd.exe /c "start Firewall.cpl"
        /mnt/c/WINDOWS/system32/cmd.exe /c "start .\Firewall-pulseaudio.png" 2>/dev/null
        ############
        if [ ! -e 'XserverhighDPI.png' ]; then
            aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'XserverhighDPI.png' https://gitee.com/mo2/pic_api/raw/test/2020/03/27/jvNs2JUIbsSQQInO.png
        fi
        /mnt/c/WINDOWS/system32/cmd.exe /c "start .\XserverhighDPI.png" 2>/dev/null
        printf "%s\n" "若X服务的画面过于模糊，则您需要右击vcxsrv.exe，并手动修改兼容性设定中的高Dpi选项。"
        printf "%s\n" "vcxsrv文件位置为C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe"
        printf "%s\n" "You can right-click vcxsrv.exe and modify the high-dpi setting."
        #printf "%s\n" "${YELLOW}按回车键启动X${RESET}"
        #printf "%s\n" "${YELLOW}Press enter to startx${RESET}"
        printf '%s\n' '运行过程中，您可以输stopvnc停止X和vnc，输pkill -u $(whoami)终止当前用户所有进程'
        printf '%s\n' 'You can type pkill -u $(whoami) to kill all processes.'
        #上面那行必须要单引号
        #read
        cd "/mnt/c/Users/Public/Downloads"
        /mnt/c/WINDOWS/system32/cmd.exe /c "start ."
        #startxsdl &
    fi
    printf "%s\n" "若您的宿主机为${YELLOW}Android${RESET},则在${PURPLE}termux原系统${RESET}下输入${GREEN}startvnc${RESET}将同时启动${BLUE}Realvnc viewer${RESET}客户端和容器的VNC服务端。注：需手动连接。"
    printf '%s\n' '------------------------'
    printf "%s\n" "若您的宿主机为${YELLOW}Win10${RESET},则在${PURPLE}WSL2${RESET}(非容器环境)下输入${GREEN}startvnc${RESET}将同时启动${BLUE}Tigervnc viewer(win_x64)${RESET}客户端和tigervnc服务端，并自动连接。此外，还将启动windows版powershell,并调用pulseaudio(win_x86)音频服务+进程守护脚本。"
    printf '%s\n' '------------------------'
    printf "%s\n" "${GREEN}tightvnc/tigervnc & x window${RESET}配置${BLUE}完成${RESET},将为您配置${GREEN}x11vnc${RESET}"
    printf "%s\n" "按${YELLOW}回车键${RESET}查看x11vnc的${BLUE}启动说明${RESET}"
    printf "%s\n" "If you don't want to read these instructions, then you only need to remember 4 commands.${GREEN}startvnc, startxsdl, startx11vnc${RESET} & ${PURPLE}stopvnc${RESET}"
    press_enter_to_continue
    printf '%s\n' "注：${GREEN}配置完${RESET}本工具所支持的所有VNC,将${BLUE}解锁成就*°▽°*${RESET}"
    printf '%s\n' '------------------------'
    printf '%s\n' '三：'
    x11vnc_warning
    configure_x11vnc_remote_desktop_session
    xfce4_x11vnc_hidpi_settings
    [[ ! ${X11VNC_PORT} =~ ^[0-9]+$ ]] || sed -i -E "s@^(TCP_PORT_FOR_RFB_PROTOCOL)=.*@\1=${X11VNC_PORT}@" "$(command -v startx11vnc)"
    printf '%s\n' '------------------------'
    printf '%s\n' '四：'
    do_you_want_to_configure_novnc
}
########################
########################
do_you_want_to_configure_novnc() {
    printf "%s\n" "You can type ${GREEN}novnc${RESET} to ${YELLOW}start${RESET} ${BLUE}novnc+websockify${RESET}"
    printf "%s\n" "配置完成后，您可以输${BOLD}${GREEN}novnc${RESET}来${YELLOW}启动${BLUE}novnc${RESET},在浏览器里输入novnc访问地址进行连接。"
    printf '%s\n' '------------------------'
    printf "%s\n" "Do you want to configure novnc?"
    printf "%s\n" "您是否需要配置${BLUE}novnc${RESET}？"
    RETURN_TO_WHERE='software_center'
    do_you_want_to_continue
    source ${TMOE_TOOL_DIR}/gui/install_novnc
    cd /usr/local/bin/
    [[ ! -e novnc ]] || rm -f novnc 2>/dev/null
    cp -f ${TMOE_TOOL_DIR}/gui/novnc ./
    ln -sf novnc startnovnc
    printf "%s\n" "当前已经配置的命令分别为${GREEN}startvnc, startxsdl, startx11vnc, novnc${RESET} & ${RED}stopvnc${RESET}"
    if [ ! -s "${TMOE_LINUX_DIR}/achievement01" ]; then
        printf "%s\n" "Congratulations！恭喜您获得新成就: ${BOLD}${YELLOW}vnc大师${RESET}"
        printf "%s\n" "由于您获得了该成就，故解锁了本工具的vnc(所有可配置)选项。"
        printf "%s\n" "vnc master" >${TMOE_LINUX_DIR}/achievement01
    fi
    printf "%s\n" "${YELLOW}*°▽°* ${RESET}You are a ${BOLD}${BLUE}VNC Master${RESET}！"
    printf "%s\n" "You can type ${GREEN}novnc${RESET} to ${YELLOW}start${RESET} ${BLUE}novnc+websockify${RESET}"
}
################
set_vnc_passwd() {
    TARGET_VNC_PASSWD=$(whiptail --inputbox "請設定6至8位VNC訪問密碼\nPlease type the password, the length is 6 to 8 digits" 0 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        printf "%s\n" "请重新输入密码"
        printf "%s\n" "Please type the password again."
        press_enter_to_return
        set_vnc_passwd
    elif [ -z "${TARGET_VNC_PASSWD}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please type a valid value"
        press_enter_to_return
        set_vnc_passwd
    else
        check_vnc_passsword_length
    fi
}
###########
choose_vnc_port_5901_or_5902() {
    if (whiptail --title "VNC PORT" --yes-button "5901" --no-button "5902" --yesno "請選擇VNC端口✨\nPlease choose the vnc port" 0 50); then
        X11VNC_PORT=5901
        DISPLAY_PORT=1
    else
        X11VNC_PORT=5902
        DISPLAY_PORT=2
    fi
    sed -i -E "s@(tmoe-linux) :.*@\1 :${DISPLAY_PORT}@" "$(command -v startvnc)"
    sed -i -E "s@(TMOE_VNC_DISPLAY_NUMBER)=.*@\1=${DISPLAY_PORT}@" "$(command -v startvnc)"
}
check_vnc_passsword_length() {
    PASSWORD_LENGTH=$(printf '%s' ${TARGET_VNC_PASSWD} | wc -L)
    if ((${PASSWORD_LENGTH} > 8)); then
        printf "%s\n" "${PASSWORD_LENGTH}"
        printf "%s\n" "密码超过${RED}8个字符${RESET}，请${BLUE}重新输入${RESET}"
        printf "%s\n" "${RED}WARNING！${RESET}The maximum password length is ${RED}8 digits.${RESET}"
        press_enter_to_return
        set_vnc_passwd
    elif ((${PASSWORD_LENGTH} < 6)); then
        printf "%s\n" "${PASSWORD_LENGTH}"
        printf "%s\n" "密码少于${RED}6个字符${RESET}，请${BLUE}重新输入${RESET}"
        printf "%s\n" "${RED}WARNING！${RESET}The minimum password length is ${RED}6 digits.${RESET}"
        press_enter_to_return
        set_vnc_passwd
    else
        mkdir -pv ${HOME}/.vnc
        cd ${HOME}/.vnc
        #case ${LINUX_DISTRO} in
        if [ $(command -v vncpasswd) ]; then
            printf "%s\n" "${TARGET_VNC_PASSWD}" | vncpasswd -f >passwd
        else
            x11vnc -storepasswd ${TARGET_VNC_PASSWD} passwd
            cp passwd x11passwd
            chmod 600 x11passwd
        fi
        chmod 600 passwd
        if [ $? = 0 ]; then
            printf "%s\n" "密码设定完成，您可以输${GREEN}startvnc${RESET}来重启服务"
            printf "%s\n" "You can type ${GREEN}startvnc${RESET} to restart it. "
            printf "%s\n" "若您想要修改其它vnc选项，那么您可以输${BLUE}debian-i${RESET}"
            printf "%s\n" "You can also type ${BLUE}debian-i${RESET} to start tmoe-linux tool."
        else
            printf "%s\n" "密码设定失败，内部发生错误。"
        fi
    fi
}
###################
tmoe_gui_dpi_01() {
    printf "%s\n" "默认分辨率为${RESOLUTION}，窗口缩放大小为1x"
    dbus-launch xfconf-query -c xsettings -t int -np /Gdk/WindowScalingFactor -s 1 2>/dev/null
    case ${VNC_SERVER_BIN} in
    tigervnc) ;;
    *)
        #|focal|bionic|Bionic Beaver|Eoan Ermine|buster|stretch|jessie
        if grep -q 'Focal Fossa' "/etc/os-release"; then
            dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Kali-Light-HiDPI 2>/dev/null
        else
            [[ ! -e "/usr/share/themes/Breeze/xfwm4/themerc" ]] || dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Breeze 2>/dev/null
        fi
        ;;
    esac
}
##########
tmoe_gui_dpi_02() {
    sed -i '/vncserver -geometry/d' "$(command -v startvnc)"
    sed -i "$ a\vncserver -geometry ${RESOLUTION} -depth 24 -name tmoe-linux :1" "$(command -v startvnc)"
    sed -i "s@geometry=.*@geometry=${RESOLUTION}@" ${TIGER_VNC_DEFAULT_CONFIG_FILE}
    #sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :233 -screen 0 ${RESOLUTION}x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)" 2>/dev/null
    sed -i "s@TMOE_X11_RESOLUTION=.*@TMOE_X11_RESOLUTION=${RESOLUTION}@" "$(command -v startx11vnc)" 2>/dev/null
}
##########
tmoe_gui_dpi_03() {
    printf "%s\n" "若分辨率不合，则请在脚本执行完成后，手动输${GREEN}debian-i${RESET}，然后在${BLUE}vnc${RESET}选项里进行修改。"
    printf "%s\n" "You can type debian-i to start tmoe-linux tool,and modify the vnc screen resolution."
}
##########
tmoe_gui_default_dpi() {
    tmoe_gui_dpi_01
    tmoe_gui_dpi_03
}
#############
tmoe_gui_normal_dpi() {
    tmoe_gui_dpi_01
}
#############
xfce4_tightvnc_hidpi_settings() {
    printf "%s\n" "Tmoe-linux tool将为您自动调整高分屏设定"
    printf "%s\n" "若分辨率不合，则请在脚本执行完成后，手动输${GREEN}debian-i${RESET}，然后在${BLUE}vnc${RESET}选项里进行修改。"
    #stopvnc >/dev/null 2>&1
    tmoe_gui_dpi_02
    printf "%s\n" "已将默认分辨率修改为${RESOLUTION}，窗口缩放大小调整为2x"
    dbus-launch xfconf-query -c xsettings -t int -np /Gdk/WindowScalingFactor -s 2 2>/dev/null
    #-n创建一个新属性，类型为int
    #|focal|bionic|Bionic Beaver|Eoan Ermine|buster|stretch|jessie
    if grep -q 'Focal Fossa' "/etc/os-release"; then
        dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Kali-Light-xHiDPI 2>/dev/null
    else
        dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Default-xhdpi 2>/dev/null
    fi
    #Default-xhdpi默认处于未激活状态
}
################
xfce4_x11vnc_hidpi_settings() {
    case ${TMOE_HIGH_DPI} in
    true | false)
        #if [ "${REMOTE_DESKTOP_SESSION_01}" = 'xfce4-session' ]; then
        #sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :233 -screen 0 ${RESOLUTION}x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)"
        case ${RESOLUTION} in
        "") ;;
        *) sed -i "s@TMOE_X11_RESOLUTION=.*@TMOE_X11_RESOLUTION=${RESOLUTION}@" "$(command -v startx11vnc)" 2>/dev/null ;;
        esac
        #startx11vnc >/dev/null 2>&1
        #fi
        ;;
    esac
}
####################
enable_dbus_launch() {
    XSTARTUP_LINE=$(cat -n ${XSESSION_FILE} | grep -v 'command' | grep "${REMOTE_DESKTOP_SESSION_01}" | awk -F ' ' '{print $1}' | head -n 1)
    #sed -i "${XSTARTUP_LINE} c\ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01}" ${XSESSION_FILE}
    sed -i "${XSTARTUP_LINE} c\  dbus-launch ${REMOTE_DESKTOP_SESSION_01}" ${XSESSION_FILE}
    XSTARTUP_LINE_02=$((${XSTARTUP_LINE} + 2))
    sed -i "${XSTARTUP_LINE_02} c\  dbus-launch ${REMOTE_DESKTOP_SESSION_02}" ${XSESSION_FILE}
    #XSTARTUP_LINE_02=$((${XSTARTUP_LINE} + 2))
    #sed -i "${XSTARTUP_LINE_02} c\  dbus-launch ${REMOTE_DESKTOP_SESSION_02}" ${XSESSION_FILE}
    #################
    #START_X11VNC_LINE=$(cat -n /usr/local/bin/startx11vnc | grep -v 'command' | grep ${REMOTE_DESKTOP_SESSION_01} | awk -F ' ' '{print $1}')
    #sed -i "${START_X11VNC_LINE} c\ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01} \&" /usr/local/bin/startx11vnc
    #sed -i "${START_X11VNC_LINE} c\  dbus-launch ${REMOTE_DESKTOP_SESSION_01} \&" /usr/local/bin/startx11vnc
    ##################
    #START_XSDL_LINE=$(cat -n /usr/local/bin/startxsdl | grep -v 'command' | grep ${REMOTE_DESKTOP_SESSION_01} | awk -F ' ' '{print $1}')
    #sed -i "${START_XSDL_LINE} c\  dbus-launch ${REMOTE_DESKTOP_SESSION_01}" /usr/local/bin/startxsdl
    #################
    #sed -i "s/.*${REMOTE_DESKTOP_SESSION_02}.*/ dbus-launch ${REMOTE_DESKTOP_SESSION_02} \&/" "/usr/local/bin/startx11vnc"
    #sed -i "s/.*${REMOTE_DESKTOP_SESSION_02}.*/  dbus-launch ${REMOTE_DESKTOP_SESSION_02}/" ${XSESSION_FILE}
    #sed -i "s/.*${REMOTE_DESKTOP_SESSION_02}.*/ dbus-launch ${REMOTE_DESKTOP_SESSION_02}/" "/usr/local/bin/startxsdl"
    #if [ "${LINUX_DISTRO}" != "debian" ]; then
    #    sed -i 's@--exit-with-session@@' ${XSESSION_FILE} /usr/local/bin/startxsdl /usr/local/bin/startx11vnc
    #fi
}
#################
fix_vnc_dbus_launch() {
    printf "%s\n" "由于在2020-0410至0411的更新中给所有系统的桌面都加入了dbus-launch，故在部分安卓设备的${BLUE}proot容器${RESET}上出现了兼容性问题。"
    printf "%s\n" "注1：该操作在linux虚拟机及win10子系统上没有任何问题"
    printf "%s\n" "注2：2020-0412更新的版本已加入检测功能，理论上不会再出现此问题。"
    case "${TMOE_PROOT}" in
    true | no) ;;
    *)
        printf "%s\n" "检测到您当前可能处于非proot环境下，是否继续修复？"
        printf "%s\n" "如需重新配置vnc启动脚本，请更新debian-i后再覆盖安装gui"
        ;;
    esac
    do_you_want_to_continue

    if grep 'dbus-launch' ${XSESSION_FILE}; then
        DBUSstatus="$(echo 检测到dbus-launch当前在VNC脚本中处于启用状态)"
    else
        DBUSstatus="$(echo 检测到dbus-launch当前在vnc脚本中处于禁用状态)"
    fi

    if (whiptail --title "您想要对这个小可爱中做什么 " --yes-button "Disable" --no-button "Enable" --yesno "您是想要禁用dbus-launch，还是启用呢？${DBUSstatus} \n请做出您的选择！✨" 10 50); then
        #sed -i 's@--exit-with-session@@' ${XSESSION_FILE} /usr/local/bin/startxsdl /usr/local/bin/startx11vnc
        sed -i 's@dbus-launch@@' ${XSESSION_FILE}
    else
        #for i in startxfce4 startlxde startlxqt mate-session startplasma gnome-session cinnamon budgie-desktop startdde; do
        #    if grep ${i} ${XSESSION_FILE}; then
        #        printf "%s\n" "检测您当前的VNC配置为${i}，正在将dbus-launch加入至启动脚本中..."
        #    fi
        #done
        #unset i
        if grep 'startxfce4' ${XSESSION_FILE}; then
            printf "%s\n" "检测您当前的VNC配置为xfce4，正在将dbus-launch加入至启动脚本中..."
            REMOTE_DESKTOP_SESSION_02='startxfce4'
            REMOTE_DESKTOP_SESSION_01='xfce4-session'
        elif grep 'startlxde' ${XSESSION_FILE}; then
            printf "%s\n" "检测您当前的VNC配置为lxde，正在将dbus-launch加入至启动脚本中..."
            REMOTE_DESKTOP_SESSION_02='startlxde'
            REMOTE_DESKTOP_SESSION_01='lxsession'
        elif grep 'startlxqt' ${XSESSION_FILE}; then
            printf "%s\n" "检测您当前的VNC配置为lxqt，正在将dbus-launch加入至启动脚本中..."
            REMOTE_DESKTOP_SESSION_01='startlxqt'
            REMOTE_DESKTOP_SESSION_02='lxqt-session'
        elif grep 'mate-session' ${XSESSION_FILE}; then
            printf "%s\n" "检测您当前的VNC配置为mate，正在将dbus-launch加入至启动脚本中..."
            REMOTE_DESKTOP_SESSION_01='mate-session'
            REMOTE_DESKTOP_SESSION_02='mate-panel'
        elif grep 'startplasma' ${XSESSION_FILE}; then
            printf "%s\n" "检测您当前的VNC配置为KDE Plasma5，正在将dbus-launch加入至启动脚本中..."
            REMOTE_DESKTOP_SESSION_01='startplasma-x11'
            REMOTE_DESKTOP_SESSION_02='startkde'
        elif grep 'gnome-session' ${XSESSION_FILE}; then
            printf "%s\n" "检测您当前的VNC配置为GNOME3，正在将dbus-launch加入至启动脚本中..."
            REMOTE_DESKTOP_SESSION_01='gnome-session'
            REMOTE_DESKTOP_SESSION_02='gnome-panel'
        elif grep 'cinnamon' ${XSESSION_FILE}; then
            printf "%s\n" "检测您当前的VNC配置为cinnamon，正在将dbus-launch加入至启动脚本中..."
            REMOTE_DESKTOP_SESSION_01='cinnamon-session'
            REMOTE_DESKTOP_SESSION_02='cinnamon-launcher'
        elif grep 'startdde' ${XSESSION_FILE}; then
            printf "%s\n" "检测您当前的VNC配置为deepin desktop，正在将dbus-launch加入至启动脚本中..."
            REMOTE_DESKTOP_SESSION_01='startdde'
            REMOTE_DESKTOP_SESSION_02='dde-launcher'
        else
            printf "%s\n" "未检测到vnc相关配置或您安装的桌面环境不被支持，请更新tmoe linux tool后再覆盖安装gui"
        fi
        enable_dbus_launch
    fi

    printf "%s\n" "${YELLOW}修改完成，按回车键返回${RESET}"
    printf "%s\n" "若无法修复，则请前往${TMOE_GIT_URL}提交issue，并附上报错截图和详细说明。"
    printf "%s\n" "还建议您附上sed -n p /usr/local/bin/startxsdl 和 sed -n p ${XSESSION_FILE} 的启动脚本截图"
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
###################
gui_main "$@"
###############################
