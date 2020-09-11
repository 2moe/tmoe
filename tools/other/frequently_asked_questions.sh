frequently_asked_questions() {
    RETURN_TO_WHERE='frequently_asked_questions'
    DEPENDENCY_01=''
    
    #17 50 7
    TMOE_FAQ=$(whiptail --title "FAQ(よくある質問)" --menu \
        "您有哪些疑问？\nWhat questions do you have?" 0 0 0 \
        "1" "软件禁止以root权限运行" \
        "2" "android chroot无法执行ping命令" \
        "3" "修复xfce配置文件无法写入" \
        "4" "udisks2/gvfs配置失败" \
        "5" "linuxQQ闪退" \
        "6" "VNC/X11闪退" \
        "7" "无法打开Baidu Netdisk" \
        "8" "mlocate数据库初始化失败" \
        "9" "TTY下中文字体乱码" \
        "10" "Linux与win10双系统时间不一致" \
        "0" "Back to the main menu 返回主菜单" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_FAQ}" in
    0 | "") tmoe_linux_tool_menu ;;
    1)
        notes_of_tmoe_sudo_01
        ;;
    2)
        notes_of_tmoe_sudo_02
        ;;
    3)
        echo "chown -Rv ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${HOME}/.config/xfce4"
        echo "若您遇到其他权限问题，还可以手动执行chown -Rv ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${HOME}"
        do_you_want_to_continue
        chown -Rv ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${HOME}/.config/xfce4
        ;;
    4)
        echo "${YELLOW}按回车键卸载gvfs和udisks2${RESET}"
        RETURN_TO_WHERE='frequently_asked_questions'
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} --allow-change-held-packages ^udisks2 ^gvfs
        ;;
    5)
        echo "如果版本更新后登录出现闪退的情况，那么您可以输rm -rf ~/.config/tencent-qq/ 后重新登录。"
        echo "${YELLOW}按回车键自动执行上述命令${RESET}"
        RETURN_TO_WHERE='frequently_asked_questions'
        do_you_want_to_continue
        rm -rvf ~/.config/tencent-qq/
        ;;
    6)
        fix_vnc_dbus_launch
        ;;
    7)
        can_not_open_baidu_netdisk
        ;;
    8)
        echo "您是否需要卸载mlocate和catfish"
        echo "Do you want to remove mlocate and catfish?"
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} mlocate catfish
        apt autopurge 2>/dev/null
        ;;
    9)
        tty_chinese_code
        ;;
    10)
        fix_linux_utc_timezone
        ;;
    esac
    ##################
    press_enter_to_return
    frequently_asked_questions
}
##############
notes_of_tmoe_sudo_01() {
    echo 'deb系创建用户的说明'
    echo "部分软件出于安全性考虑，禁止以root权限运行。权限越大，责任越大。若root用户不慎操作，将有可能破坏系统。"
    echo "您可以使用以下命令来新建普通用户"
    echo "#创建一个用户名为moe的新用户"
    echo "${YELLOW}adduser moe${RESET}"
    echo "#输入的密码是隐藏的，根据提示创建完成后，您可以在本工具内将该用户加入sudo用户组"
    #echo "#将mo2加入到sudo用户组"
    #echo "${YELLOW}adduser mo2 sudo${RESET}"
    echo "之后，若需要提权，则只需输sudo 命令"
    echo "例如${YELLOW}sudo apt update${RESET}"
    echo "--------------------"
    echo "切换用户的说明"
    echo "您可以输${YELLOW}su - ${RESET}或${YELLOW}sudo su - ${RESET}亦或者是${YELLOW}sudo -i ${RESET}切换至root用户"
    echo "亦可输${YELLOW}su - moe${RESET}或${YELLOW}sudo -iu moe${RESET}切换回mo2用户"
    echo "若需要以普通用户身份启动VNC，请先切换至普通用户，再输${YELLOW}startvnc${RESET}"
    echo '--------------------'
    echo 'arch系创建新用户的命令为useradd -m miku'
    echo '其中miku为用户名'
    echo '输passwd miku修改该用户密码'
    echo '如需将其添加至sudo用户组，那么您可以使用本工具自带的sudo用户组管理功能(位于秘密花园的系统管理选项)'
    echo '--------------------'
}
##############
notes_of_tmoe_sudo_02() {
    cat <<-EOF
    在Android termux上运行的chroot容器（非proot），以root身份执行${GREEN}ping 127.0.0.1${RESET}可以能会遇到${RED}socket 权限不够 Permission denied${RESET}的问题
    解决方法如下：
    方法1：
    输入${GREEN}newgrp aid_inet${RESET}切换到aid_inet用户组，该用户组具有安卓系统的联网权限。
    方法2：
    新建一名普通用户，再前往本工具的秘密花园的系统管理选项，将该用户添加至sudo用户组。
    当检测到TMOE_CHROOT='true'时，将会自动把该用户加入aid_inet和aid_net_raw等用户组。
    若您的宿主机为Android系统，则需要加入这些用户组。
    ---------------
    若部分程序无法联网，则请将相关用户加入aid_inet用户组，例如${GREEN}usermod -a -G aid_inet mysql${RESET}
EOF
}
###########
can_not_open_baidu_netdisk() {
    #echo "若无法打开，则请手动输rm -f ~/baidunetdisk/baidunetdiskdata.db"
    echo "若无法打开，则请手动输rm -rf ~/baidunetdisk"
    echo "按回车键自动执行${YELLOW}rm -vf ~/baidunetdisk/baidunetdiskdata.db${RESET}"
    RETURN_TO_WHERE='frequently_asked_questions'
    do_you_want_to_continue
    rm -vf ~/baidunetdisk/baidunetdiskdata.db
}
##############
fix_linux_utc_timezone() {
    timedatectl status
    echo "是否需要将硬件时钟设置为本地时区,并开启NTP时间同步？"
    echo "${GREEN}timedatectl set-local-rtc 1 --adjust-system-clock${RESET}"
    do_you_want_to_continue
    #timedatectl set-local-rtc true
    #hwclock --localtime --systohc
    if [ ! $(command -v ntpdate) ]; then
        DEPENDENCY_02='ntpdate'
        beta_features_quick_install
    fi
    if [ ! $(command -v chronyc) ]; then
        DEPENDENCY_02='chrony'
        beta_features_quick_install
    fi
    echo "正在与microsoft ntp时间同步服务器进行同步..."
    echo "${GREEN}ntpdate time.windows.com${RESET}"
    ntpdate time.windows.com
    echo "${GREEN}timedatectl set-ntp true${RESET}"
    echo "If you want to close it,then enter ${GREEN}timedatectl set-ntp false${RESET}"
    echo "正在配置时间自动同步服务..."
    timedatectl set-ntp true
    echo "${GREEN}systemctl enable chrony${RESET}"
    systemctl enable chrony 2>/dev/null || systemctl enable chronyd 2>/dev/null || rc-update add chrony
    echo "If you want to disable it,then enter ${GREEN}systemctl disable chrony${RESET}"
    echo "${GREEN}chronyc sourcestats -v${RESET}"
    chronyc sourcestats -v
}
##############
tty_chinese_code() {
    if (whiptail --title "您想要对这个小可爱执行哪项方案?" --yes-button 'fbterm' --no-button '修改$LANG' --yesno "目前有两种简单的解决方法(っ °Д °)\n前者提供了一个快速的终端仿真器，它直接运行在你的系统中的帧缓冲 (framebuffer) 之上；而后者则是修改语言变量。" 11 45); then
        if [ ! $(command -v fbterm) ]; then
            DEPENDENCY_01='fbterm'
            ${TMOE_INSTALLATON_COMMAND} ${DEPENDENCY_01}
        fi
        echo '若启动失败，则请手动执行fbterm'
        fbterm
    else
        export LANG='C.UTF-8'
        echo "请手动执行${GREEN}export LANG=C.UTF-8${RESET}"
    fi
}
################
frequently_asked_questions
