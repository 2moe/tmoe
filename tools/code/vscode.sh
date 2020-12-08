#!/usr/bin/env bash
#####################
which_vscode_edition() {
    RETURN_TO_WHERE='which_vscode_edition'
    ps -e >/dev/null 2>&1 || VSCODEtips=$(printf "%s\n" "检测到您无权读取/proc的部分内容，请选择Server版，或使用x11vnc打开VSCode本地版")
    #15 60 5
    VSCODE_EDITION=$(whiptail --title "Visual Studio Code" --menu \
        "${VSCODEtips} Which edition do you want to install" 0 50 0 \
        "1" "Microsoft Official(x64,arm64,armhf官方版)" \
        "2" "VS Code Server:web版,含配置选项" \
        "3" "VS Codium(不跟踪你的使用数据)" \
        "4" "VS Code OSS(headmelted编译版)" \
        "5" "修复tightvnc无法打开codeoss/codium" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${VSCODE_EDITION}" in
    0 | "") development_programming_tools ;;
    1) install_vscode_official ;;
    2) check_vscode_server_arch ;;
    3) install_vscodium ;;
    4) install_vscode_oss ;;
    5) fix_tightvnc_oss ;;
    esac
    #########################
    press_enter_to_return
    which_vscode_edition
}
#################################
copy_gnu_lib_xcb_so() {
    where_is_gnu_libxcb
    if [ ! -s "${TMOE_LINUX_DIR}/lib/libxcb.so.1" ]; then
        mkdir -p ${TMOE_LINUX_DIR}/lib
        cp ${GNU_LIBXCB} ${TMOE_LINUX_DIR}/lib/libxcb.so.1
        sed -i 's@BIG-REQUESTS@_IG-REQUESTS@' ${TMOE_LINUX_DIR}/lib/libxcb.so.1
    fi
}
###########
fix_tightvnc_vscode_lnk() {
    if [ -s "${TMOE_LINUX_DIR}/lib/libxcb.so.1" ]; then
        sed -i "s@Exec=/usr/share/code-oss/code-oss@Exec=env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib /usr/share/code-oss/code-oss@g" ${APPS_LNK_DIR}/code-oss.desktop 2>/dev/null
        sed -i "s@Exec=/usr/share/codium/codium@Exec=env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib /usr/share/codium/codium@g" ${APPS_LNK_DIR}/codium.desktop 2>/dev/null
        sed -i "s@Exec=/usr/share/code/code@Exec=env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib /usr/share/code/code@g" ${APPS_LNK_DIR}/code.desktop 2>/dev/null
    else
        printf "${RED}%s${RESET}\n" "ERROR！无法修复。"
    fi
}
#########
fix_tightvnc_oss() {
    cat <<-EOF
    本功能仅支持deb系发行版。
    若无法自动修复，则请手动使用以下命令来启动。
    env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib codium --user-data-dir=${HOME}/.codium
    env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib code-oss --user-data-dir=${HOME}/.codeoss
    env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib code --user-data-dir=${HOME}/.vscode
EOF
    non_debian_function
    copy_gnu_lib_xcb_so
    fix_tightvnc_vscode_lnk
}
##############
check_vscode_server_arch() {
    case ${ARCH_TYPE} in
    arm64 | amd64) install_vscode_server ;;
    *)
        printf "%s\n" "非常抱歉，Tmoe-linux的开发者未对您的架构进行适配。"
        printf "%s\n" "请选择其它版本"
        arch_does_not_support
        ;;
    esac
}
###################
install_vscode_server() {
    if [ ! -e "/usr/local/bin/code-server-data/code-server" ]; then
        if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "install安装" --no-button "Configure配置" --yesno "检测到您尚未安装vscode-server\nVisual Studio Code is a lightweight but powerful source code editor which runs on your desktop and is available for Windows, macOS and Linux. It comes with built-in support for JavaScript, TypeScript and Node.js and has a rich ecosystem of extensions for other languages (such as C++, C#, Java, Python, PHP, Go) and runtimes (such as .NET and Unity).  ♪(^∇^*) " 16 50); then
            vscode_server_upgrade
        else
            configure_vscode_server
        fi
    else
        check_vscode_server_status
    fi
}
#################
check_vscode_server_status() {
    #pgrep code-server &>/dev/null
    pgrep node &>/dev/null
    if [ "$?" = "0" ]; then
        VSCODE_SERVER_STATUS='检测到code-server进程正在运行'
        VSCODE_SERVER_PROCESS='Restart重启'
    else
        VSCODE_SERVER_STATUS='检测到code-server进程未运行'
        VSCODE_SERVER_PROCESS='Start启动'
    fi

    if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${VSCODE_SERVER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${VSCODE_SERVER_STATUS}" 9 50); then
        vscode_server_restart
    else
        configure_vscode_server
    fi
}
###############
configure_vscode_server() {
    CODE_SERVER_OPTION=$(
        whiptail --title "CONFIGURE VSCODE_SERVER" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 0 50 0 \
            "1" "upgrade code-server更新/升级" \
            "2" "password 设定密码" \
            "3" "edit config manually手动编辑配置" \
            "4" "stop 停止" \
            "5" "remove 卸载/移除" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ################
    case "${CODE_SERVER_OPTION}" in
    0 | "") which_vscode_edition ;;
    1)
        pkill node
        vscode_server_upgrade
        ;;
    2) vscode_server_password ;;
    3) edit_code_server_config_manually ;;
    4)
        printf "%s\n" "正在停止服务进程..."
        printf "%s\n" "Stopping..."
        pkill node
        ;;
    5) vscode_server_remove ;;
    esac
    ##############
    press_enter_to_return
    configure_vscode_server
}
##############
edit_code_server_config_manually() {
    nano ~/.config/code-server/config.yaml
}
####################
vscode_server_upgrade() {
    random_neko
    printf "%s\n" "正在检测版本信息..."
    if [ -e "/usr/local/bin/code-server-data/bin/code-server" ]; then
        LOCAL_VSCODE_VERSION=$(code-server --version | grep -v info | head -n 1 | awk '{print $1}')
    else
        LOCAL_VSCODE_VERSION='NOT-INSTALLED未安装'
    fi
    LATEST_VSCODE_VERSION=$(curl -sL https://gitee.com/mo2/vscode-server/raw/aarch64/version.txt | head -n 1)

    cat <<-ENDofTable
		╔═══╦══════════╦═══════════════════╦════════════════════
		║   ║          ║                   ║                    
		║   ║ software ║    ✨最新版本     ║   本地版本 🎪
		║   ║          ║  Latest version   ║  Local version     
		║---║----------║-------------------║--------------------
		║ 1 ║ vscode   ║                      ${LOCAL_VSCODE_VERSION} 
		║   ║ server   ║${LATEST_VSCODE_VERSION} 

After the update is complete, you can type ${GREEN}code-server${RESET} to start it.
您可以输入${GREEN}code-server${RESET}来启动vscode web服务器。
	ENDofTable
    RETURN_TO_WHERE='configure_vscode_server'
    do_you_want_to_continue
    #与原系统的联动功能已经废弃，故startup函数将不会被加载。
    code_server_auto_startup() {
        if [ ! -e "/tmp/sed-vscode.tmp" ]; then
            cat >"/tmp/sed-vscode.tmp" <<-'EOF'
			if [ -e "/tmp/startcode.tmp" ]; then
				printf "%s\n" "正在为您启动VSCode服务(器),请复制密码，并在浏览器的密码框中粘贴。"
				printf "%s\n" "The VSCode service(server) is starting, please copy the password and paste it in your browser."

				rm -f /tmp/startcode.tmp
				code-server &
				printf "%s\n" "已为您启动VS Code Server!"
				printf "%s\n" "VS Code Server has been started,enjoy it !"
				printf "%s\n" "您可以输pkill node来停止服务(器)。"
				printf '%s\n' 'You can type "pkill node" to stop vscode service(server).'
			fi
		EOF
        fi
        grep '/tmp/startcode.tmp' ${HOME}/.bashrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" ${HOME}/.bashrc
        grep '/tmp/startcode.tmp' ${HOME}/.zshrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" ${HOME}/.zshrc
    }
    if [ ! -x "/usr/local/bin/code-server-data/code-server" ]; then
        chmod +x /usr/local/bin/code-server-data/code-server 2>/dev/null
    fi

    cd /tmp
    rm -rvf .VSCODE_SERVER_TEMP_FOLDER
    case "${ARCH_TYPE}" in
    "arm64")
        git clone -b aarch64 --depth=1 https://gitee.com/mo2/vscode-server.git .VSCODE_SERVER_TEMP_FOLDER
        cd .VSCODE_SERVER_TEMP_FOLDER
        tar -PpJxvf code.tar.xz
        cd ..
        rm -rf /tmp/.VSCODE_SERVER_TEMP_FOLDER
        ;;
    "amd64")
        mkdir -p .VSCODE_SERVER_TEMP_FOLDER
        cd .VSCODE_SERVER_TEMP_FOLDER
        LATEST_VSCODE_SERVER_LINK=$(curl -Lv https://api.github.com/repos/cdr/code-server/releases | grep 'x86_64' | grep browser_download_url | grep linux | head -n 1 | awk -F ' ' '$0=$NF' | cut -d '"' -f 2)
        aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o .VSCODE_SERVER.tar.gz ${LATEST_VSCODE_SERVER_LINK}
        tar -zxvf .VSCODE_SERVER.tar.gz
        VSCODE_FOLDER_NAME=$(ls -l ./ | grep '^d' | awk -F ' ' '$0=$NF')
        mv ${VSCODE_FOLDER_NAME} code-server-data
        rm -rvf /usr/local/bin/code-server-data /usr/local/bin/code-server
        mv code-server-data /usr/local/bin/
        ln -sf /usr/local/bin/code-server-data/bin/code-server /usr/local/bin/code-server
        ;;
    esac
    vscode_server_restart
    vscode_server_password
    printf "%s\n" "若您是初次安装，则请重启code-server"
    if grep -q '127.0.0.1:8080' "${HOME}/.config/code-server/config.yaml"; then
        sed -i 's@bind-addr:.*@bind-addr: 0.0.0.0:18080@' "${HOME}/.config/code-server/config.yaml"
    fi
    ########################################
    press_enter_to_return
    configure_vscode_server
    #此处的返回步骤并非多余
}
############
vscode_server_restart() {
    printf "%s\n" "即将为您启动code-server"
    printf "%s\n" "The VSCode server is starting"
    printf "%s\n" "您之后可以输code-server来启动Code Server."
    printf '%s\n' 'You can type "code-server" to start Code Server.'
    /usr/local/bin/code-server-data/bin/code-server &
    SERVER_PORT=$(sed -n p ${HOME}/.config/code-server/config.yaml | grep bind-addr | cut -d ':' -f 3)
    if [ -z "${SERVER_PORT}" ]; then
        SERVER_PORT='18080'
    fi
    printf "%s\n" "正在为您启动code-server，本机默认访问地址为localhost:${SERVER_PORT}"
    echo The LAN address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${SERVER_PORT}
    printf "%s\n" "您可以输${YELLOW}pkill node${RESET}来停止进程"
}
#############
vscode_server_password() {
    TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password.您的密码将以明文形式保存至~/.config/code-server/config.yaml" 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        configure_vscode_server
    elif [ -z "${TARGET_USERPASSWD}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
    else
        sed -i "s@^password:.*@password: ${TARGET_USERPASSWD}@" ~/.config/code-server/config.yaml
    fi
}
#################
vscode_server_remove() {
    pkill node
    #service code-server stop 2>/dev/null
    printf "%s\n" "正在停止code-server进程..."
    printf "%s\n" "Stopping code-server..."
    #service vscode-server stop 2>/dev/null
    printf "%s\n" "按回车键确认移除"
    printf "%s\n" "${YELLOW}Press enter to remove VSCode Server. ${RESET}"
    RETURN_TO_WHERE='configure_vscode_server'
    do_you_want_to_continue
    #sed -i '/export PASSWORD=/d' ~/.profile
    #sed -i '/export PASSWORD=/d' ~/.zshrc
    rm -rvf /usr/local/bin/code-server-data/ /usr/local/bin/code-server /tmp/sed-vscode.tmp
    printf "%s\n" "${YELLOW}移除成功${RESET}"
    printf "%s\n" "Remove successfully"
}
##########################
install_vscodium() {
    cd /tmp
    case "${ARCH_TYPE}" in
    "arm64") CodiumARCH=arm64 ;;
    "armhf") CodiumARCH=arm ;;
    "amd64") CodiumARCH=x64 ;;
    "i386")
        printf "%s\n" "暂不支持${RED}i386${RESET}架构"
        arch_does_not_support
        which_vscode_edition
        ;;
    esac

    if [ -e "/usr/bin/codium" ]; then
        printf '%s\n' '检测到您已安装VSCodium,请手动输以下命令启动'
        printf "%s\n" "codium --user-data-dir=${HOME}/.codium"
        printf "%s\n" "如需卸载，请手动输${TMOE_REMOVAL_COMMAND} codium"
    elif [ -e "/opt/vscodium-data/codium" ]; then
        printf "%s\n" "检测到您已安装VSCodium,请输codium启动"
        printf "%s\n" "如需卸载，请手动输rm -rv /opt/vscodium-data /usr/local/bin/codium ${APPS_LNK_DIR}/codium.desktop"
    fi
    [[ ! $(command -v codium) ]] || codium --no-sandbox
    printf "%s\n" "请问您是否需要下载最新版安装包？"
    printf "%s\n" "Do you want to download the latest codium?"
    do_you_want_to_continue

    if [ "${LINUX_DISTRO}" = 'debian' ]; then
        LatestVSCodiumLink="$(curl -L https://mirrors.bfsu.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${ARCH_TYPE} | grep -v '.sha256' | grep '\.deb' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
        CODIUM_FILE_URL="https://mirrors.bfsu.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
        printf "%s\n" "${YELLOW}${CODIUM_FILE_URL}${RESET}"
        aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCodium.deb' ${CODIUM_FILE_URL}
        apt-cache show ./VSCodium.deb
        #apt install -y ./VSCodium.deb
        dpkg -i ./VSCodium.deb
        rm -vf VSCodium.deb
        copy_gnu_lib_xcb_so
        fix_tightvnc_vscode_lnk
        printf "%s\n" "安装完成,您可以输codium --user-data-dir=${HOME}/.codium启动"
    else
        fix_fedora_electron_libxssl
        LatestVSCodiumLink="$(curl -L https://mirrors.bfsu.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${CodiumARCH} | grep -v '.sha256' | grep '.tar' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
        CODIUM_FILE_URL="https://mirrors.bfsu.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
        printf "%s\n" "${YELLOW}${CODIUM_FILE_URL}${RESET}"
        aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCodium.tar.gz' ${CODIUM_FILE_URL}
        mkdir -p /opt/vscodium-data
        tar -zxvf VSCodium.tar.gz -C /opt/vscodium-data
        rm -vf VSCodium.tar.gz
        cp -f ${TMOE_TOOL_DIR}/code/bin/codium /usr/local/bin
        cp -f ${TMOE_TOOL_DIR}/code/lnk/codium.desktop ${APPS_LNK_DIR}
        if [ ! -e "/usr/share/icons/vscodium.png" ]; then
            aria2c --no-conf -d '/usr/share/icons' -o 'vscodium.png' 'https://gitee.com/ak2/icons/raw/master/vscodium.png'
        fi
        #ln -sf /opt/vscodium-data/codium /usr/local/bin/codium
        printf "%s\n" "安装完成，您可以输codium启动"
    fi
}
########################
install_vscode_oss() {
    if [ -e "/usr/bin/code-oss" ]; then
        printf "%s\n" "检测到您已安装VSCode OSS,请手动输以下命令启动"
        #printf '%s\n' 'code-oss --user-data-dir=${HOME}/.config/Code\ -\ OSS\ \(headmelted\)'
        printf "%s\n" "code-oss --user-data-dir=${HOME}/.codeoss"
        printf "%s\n" "如需卸载，请手动输${TMOE_REMOVAL_COMMAND} code-oss"
        press_enter_to_return
        which_vscode_edition
    fi

    if [ "${LINUX_DISTRO}" = 'debian' ]; then
        install_gpg
        copy_gnu_lib_xcb_so
        fix_tightvnc_vscode_lnk
        if [ ! -s "/etc/apt/trusted.gpg.d/code-oss.gpg" ]; then
            curl -L https://packagecloud.io/headmelted/codebuilds/gpgkey | gpg --dearmor >/tmp/code-oss.gpg
            install -o root -g root -m 644 /tmp/code-oss.gpg /etc/apt/trusted.gpg.d/
            apt update
        fi
        bash -c "$(wget -O- https://code.headmelted.com/installers/apt.sh)"
    elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
        . <(wget -O- https://code.headmelted.com/installers/yum.sh)
    else
        printf "%s\n" "检测到您当前使用的可能不是deb系或红帽系发行版，跳过安装"
        press_enter_to_return
        which_vscode_edition
    fi
    printf "%s\n" "安装完成,请手动输以下命令启动"
    printf "%s\n" "code-oss --user-data-dir=${HOME}/.codeoss"
    printf "%s\n" "如需卸载，请手动输${TMOE_REMOVAL_COMMAND} code-oss"
}
#######################
download_vscode_x64_deb() {
    aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.deb' "${CODE_BIN_URL}"
    apt-cache show ./VSCODE.deb
    dpkg -i ./VSCODE.deb || apt install -y ./VSCODE.deb
    rm -vf VSCODE.deb
    case ${TMOE_PROOT} in
    true | false)
        copy_gnu_lib_xcb_so
        fix_tightvnc_vscode_lnk
        ;;
    esac
}
##########
install_vscode_official() {
    cd /tmp
    case "${ARCH_TYPE}" in
    amd64)
        case ${LINUX_DISTRO} in
        debian) CODE_BIN_URL="https://go.microsoft.com/fwlink/?LinkID=760868" ;;
        redhat) CODE_BIN_URL="https://go.microsoft.com/fwlink/?LinkID=760867" ;;
        *)
            CODE_BIN_URL="https://go.microsoft.com/fwlink/?LinkID=620884"
            CODE_BIN_FOLDER='VSCode-linux-x64'
            ;;
        esac
        ;;
    arm64)
        case ${LINUX_DISTRO} in
        debian) CODE_BIN_URL="https://aka.ms/linux-arm64-deb" ;;
        redhat) CODE_BIN_URL="https://aka.ms/linux-arm64-rpm" ;;
        *)
            CODE_BIN_URL="https://aka.ms/linux-arm64"
            CODE_BIN_FOLDER='VSCode-linux-arm64'
            ;;
        esac
        ;;
    armhf)
        case ${LINUX_DISTRO} in
        debian) CODE_BIN_URL="https://aka.ms/linux-armhf-deb" ;;
        redhat) CODE_BIN_URL="https://aka.ms/linux-armhf-rpm" ;;
        *)
            CODE_BIN_URL="https://aka.ms/linux-armhf"
            CODE_BIN_FOLDER='VSCode-linux-armhf'
            ;;
        esac
        ;;
    *)
        arch_does_not_support
        which_vscode_edition
        ;;
    esac

    if [ -e "/usr/share/code/.electron" ]; then
        printf "%s\n" "检测到您已安装VSCode,请输${GREEN}code --user-data-dir=${HOME}/.vscode${RESET}启动"
        printf "%s\n" "如需卸载，请手动输${RED}rm -rv${RESET} ${BLUE}/usr/share/zsh/vendor-completions /usr/share/zsh/vendor-completions/_code /usr/share/applications/code.desktop /usr/share/applications/code-url-handler.desktop /usr/share/code /usr/share/appdata/code.appdata.xml /usr/share/mime/packages/code-workspace.xml /usr/share/bash-completion/completions/code /usr/share/pixmaps/com.visualstudio.code.png${RESET}"
    elif [ -e "/usr/bin/code" ]; then
        printf '%s\n' '检测到您已安装VSCode,请手动输以下命令启动'
        printf '%s\n' 'code --user-data-dir=${HOME}/.vscode'
        printf "%s\n" "如需卸载，请手动输${TMOE_REMOVAL_COMMAND} code"
    fi
    [[ ! $(command -v code) ]] || code --version --user-data-dir=/tmp/.code
    printf "%s\n" "请问您是否需要下载最新版安装包？"
    printf "%s\n" "Do you want to download the latest vscode?"
    printf "${YELLOW}%s${RESET}\n" "${CODE_BIN_URL}"
    do_you_want_to_continue

    case ${LINUX_DISTRO} in
    debian)
        download_vscode_x64_deb
        printf "%s\n" "安装完成,请输code --user-data-dir=${HOME}/.vscode启动"
        ;;
    redhat)
        aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.rpm' "${CODE_BIN_URL}"
        yum install ./VSCODE.rpm
        rm -vf VSCODE.rpm
        printf "%s\n" "安装完成,请输code --user-data-dir=${HOME}/.vscode启动"
        ;;
    *)
        fix_fedora_electron_libxssl
        aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.tar.gz' "${CODE_BIN_URL}"
        tar -zxvf VSCODE.tar.gz -C /usr/share
        rm -rv /usr/share/code 2>/dev/null
        mv /usr/share/${CODE_BIN_FOLDER} /usr/share/code
        rm -vf VSCode.tar.gz
        #if [ ! -e "/usr/share/code/.electron" ]; then
        printf "%s\n" "${CODE_BIN_FOLDER}" >/usr/share/code/.electron
        CODE_SHARE_FILE='.VSCODE_USR_SHARE.tar.gz'
        aria2c --no-conf --allow-overwrite=true -s 1 -x 1 -o ${CODE_SHARE_FILE} https://gitee.com/ak2/vscode-share/raw/master/code.tar.xz
        tar -Jxvf ${CODE_SHARE_FILE} -C /
        #chown 0:0 /usr/share/zsh /usr/share/mime /usr/share/applications /usr/share/appdata /usr/share/bash-completion /usr/share/pixmaps /usr/share/zsh/vendor-completions /usr/share/zsh/vendor-completions/_code /usr/share/applications/code.desktop /usr/share/applications/code-url-handler.desktop /usr/share/code /usr/share/appdata/code.appdata.xml /usr/share/mime/packages/code-workspace.xml /usr/share/bash-completion/completions/code /usr/share/pixmaps/com.visualstudio.code.png
        rm -vf ${CODE_SHARE_FILE}
        #fi
        ln -sfv /usr/share/code/bin/code /usr/bin
        printf "%s\n" "安装完成,请输code --user-data-dir=${HOME}/.vscode启动"
        ;;
    esac
}
###############################
which_vscode_edition
