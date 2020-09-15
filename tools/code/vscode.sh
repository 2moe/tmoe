#!/usr/bin/env bash
#####################
which_vscode_edition() {
    RETURN_TO_WHERE='which_vscode_edition'
    ps -e >/dev/null 2>&1 || VSCODEtips=$(echo "检测到您无权读取/proc的部分内容，请选择Server版，或使用x11vnc打开VSCode本地版")
    #15 60 5
    VSCODE_EDITION=$(whiptail --title "Visual Studio Code" --menu \
        "${VSCODEtips} Which edition do you want to install" 0 50 0 \
        "1" "VS Code Server:web版,含配置选项" \
        "2" "VS Codium(不跟踪你的使用数据)" \
        "3" "VS Code OSS(headmelted编译版)" \
        "4" "Microsoft Official(x64,官方版)" \
        "5" "修复tightvnc无法打开codeoss/codium" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${VSCODE_EDITION}" in
    0 | "") development_programming_tools ;;
    1) check_vscode_server_arch ;;
    2) install_vscodium ;;
    3) install_vscode_oss ;;
    4) install_vscode_official ;;
    5) fix_tightvnc_oss ;;
    esac
    #########################
    press_enter_to_return
    which_vscode_edition
}
#################################
copy_gnu_lib_xcb_so() {
    GNU_LIBXCB="/usr/lib/$(uname -m)-linux-gnu/libxcb.so.1.1.0"
    if [ ! -e "${TMOE_LINUX_DIR}/lib/libxcb.so.1" ]; then
        mkdir -p ${TMOE_LINUX_DIR}/lib
        cp ${GNU_LIBXCB} ${TMOE_LINUX_DIR}/lib/libxcb.so.1
        sed -i 's@BIG-REQUESTS@_IG-REQUESTS@' ${TMOE_LINUX_DIR}/lib/libxcb.so.1
    fi
}
###########
fix_tightvnc_vscode_lnk() {
    sed -i "s@Exec=/usr/share/code-oss/code-oss@Exec=env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib /usr/share/code-oss/code-oss@g" ${APPS_LNK_DIR}/code-oss.desktop 2>/dev/null
    sed -i "s@Exec=/usr/share/codium/codium@Exec=env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib /usr/share/codium/codium@g" ${APPS_LNK_DIR}/codium.desktop 2>/dev/null
    sed -i "s@Exec=/usr/share/code/code@Exec=env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib /usr/share/code/code@g" ${APPS_LNK_DIR}/code.desktop 2>/dev/null
}
#########
fix_tightvnc_oss() {
    cat <<-EOF
    deb系发行版在安装时会自动修复。
    若无法自动修复，则请手动使用以下命令来启动。
    env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib codium --user-data-dir=${HOME}/.codium
    env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib code-oss --user-data-dir=${HOME}/.codeoss
    env LD_LIBRARY_PATH=${TMOE_LINUX_DIR}/lib code --user-data-dir=${HOME}/.code
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
        echo "非常抱歉，Tmoe-linux的开发者未对您的架构进行适配。"
        echo "请选择其它版本"
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
        echo "正在停止服务进程..."
        echo "Stopping..."
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
    echo "正在检测版本信息..."
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

	ENDofTable
    RETURN_TO_WHERE='configure_vscode_server'
    do_you_want_to_continue
    if [ ! -e "/tmp/sed-vscode.tmp" ]; then
        cat >"/tmp/sed-vscode.tmp" <<-'EOF'
			if [ -e "/tmp/startcode.tmp" ]; then
				echo "正在为您启动VSCode服务(器),请复制密码，并在浏览器的密码框中粘贴。"
				echo "The VSCode service(server) is starting, please copy the password and paste it in your browser."

				rm -f /tmp/startcode.tmp
				code-server &
				echo "已为您启动VS Code Server!"
				echo "VS Code Server has been started,enjoy it !"
				echo "您可以输pkill node来停止服务(器)。"
				echo 'You can type "pkill node" to stop vscode service(server).'
			fi
		EOF
    fi
    grep '/tmp/startcode.tmp' ${HOME}/.bashrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" ${HOME}/.bashrc
    grep '/tmp/startcode.tmp' ${HOME}/.zshrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" ${HOME}/.zshrc
    if [ ! -x "/usr/local/bin/code-server-data/code-server" ]; then
        chmod +x /usr/local/bin/code-server-data/code-server 2>/dev/null
        #echo -e "检测到您未安装vscode server\nDetected that you do not have vscode server installed."
    fi

    cd /tmp
    rm -rvf .VSCODE_SERVER_TEMP_FOLDER

    if [ "${ARCH_TYPE}" = "arm64" ]; then
        git clone -b aarch64 --depth=1 https://gitee.com/mo2/vscode-server.git .VSCODE_SERVER_TEMP_FOLDER
        cd .VSCODE_SERVER_TEMP_FOLDER
        tar -PpJxvf code.tar.xz
        cd ..
        rm -rf /tmp/.VSCODE_SERVER_TEMP_FOLDER
    elif [ "${ARCH_TYPE}" = "amd64" ]; then
        mkdir -p .VSCODE_SERVER_TEMP_FOLDER
        cd .VSCODE_SERVER_TEMP_FOLDER
        LATEST_VSCODE_SERVER_LINK=$(curl -Lv https://api.github.com/repos/cdr/code-server/releases | grep 'x86_64' | grep browser_download_url | grep linux | head -n 1 | awk -F ' ' '$0=$NF' | cut -d '"' -f 2)
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o .VSCODE_SERVER.tar.gz ${LATEST_VSCODE_SERVER_LINK}
        tar -zxvf .VSCODE_SERVER.tar.gz
        VSCODE_FOLDER_NAME=$(ls -l ./ | grep '^d' | awk -F ' ' '$0=$NF')
        mv ${VSCODE_FOLDER_NAME} code-server-data
        rm -rvf /usr/local/bin/code-server-data /usr/local/bin/code-server
        mv code-server-data /usr/local/bin/
        ln -sf /usr/local/bin/code-server-data/bin/code-server /usr/local/bin/code-server
    fi
    vscode_server_restart
    vscode_server_password
    echo "若您是初次安装，则请重启code-server"
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
    echo "即将为您启动code-server"
    echo "The VSCode server is starting"
    echo "您之后可以输code-server来启动Code Server."
    echo 'You can type "code-server" to start Code Server.'
    /usr/local/bin/code-server-data/bin/code-server &
    SERVER_PORT=$(cat ${HOME}/.config/code-server/config.yaml | grep bind-addr | cut -d ':' -f 3)
    if [ -z "${SERVER_PORT}" ]; then
        SERVER_PORT='18080'
    fi
    echo "正在为您启动code-server，本机默认访问地址为localhost:${SERVER_PORT}"
    echo The LAN address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${SERVER_PORT}
    echo "您可以输${YELLOW}pkill node${RESET}来停止进程"
}
#############
vscode_server_password() {
    TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password.您的密码将以明文形式保存至~/.config/code-server/config.yaml" 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        configure_vscode_server
    elif [ -z "${TARGET_USERPASSWD}" ]; then
        echo "请输入有效的数值"
        echo "Please enter a valid value"
    else
        sed -i "s@^password:.*@password: ${TARGET_USERPASSWD}@" ~/.config/code-server/config.yaml
    fi
}
#################
vscode_server_remove() {
    pkill node
    #service code-server stop 2>/dev/null
    echo "正在停止code-server进程..."
    echo "Stopping code-server..."
    #service vscode-server stop 2>/dev/null
    echo "按回车键确认移除"
    echo "${YELLOW}Press enter to remove VSCode Server. ${RESET}"
    RETURN_TO_WHERE='configure_vscode_server'
    do_you_want_to_continue
    #sed -i '/export PASSWORD=/d' ~/.profile
    #sed -i '/export PASSWORD=/d' ~/.zshrc
    rm -rvf /usr/local/bin/code-server-data/ /usr/local/bin/code-server /tmp/sed-vscode.tmp
    echo "${YELLOW}移除成功${RESET}"
    echo "Remove successfully"
}
##########################
install_vscodium() {
    cd /tmp
    if [ "${ARCH_TYPE}" = 'arm64' ]; then
        CodiumARCH=arm64
    elif [ "${ARCH_TYPE}" = 'armhf' ]; then
        CodiumARCH=arm
        #CodiumDebArch=armhf
    elif [ "${ARCH_TYPE}" = 'amd64' ]; then
        CodiumARCH=x64
    elif [ "${ARCH_TYPE}" = 'i386' ]; then
        echo "暂不支持i386 linux"
        arch_does_not_support
        which_vscode_edition
    fi

    if [ -e "/usr/bin/codium" ]; then
        echo '检测到您已安装VSCodium,请手动输以下命令启动'
        echo "codium --user-data-dir=${HOME}/.codium"
        echo "如需卸载，请手动输${TMOE_REMOVAL_COMMAND} codium"
    elif [ -e "/opt/vscodium-data/codium" ]; then
        echo "检测到您已安装VSCodium,请输codium启动"
        echo "如需卸载，请手动输rm -rv /opt/vscodium-data /usr/local/bin/codium ${APPS_LNK_DIR}/codium.desktop"
    fi

    if [ $(command -v codium) ]; then
        press_enter_to_return
        which_vscode_edition
    fi

    if [ "${LINUX_DISTRO}" = 'debian' ]; then
        LatestVSCodiumLink="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${ARCH_TYPE} | grep -v '.sha256' | grep '.deb' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
        CODIUM_FILE_URL="https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
        echo "${YELLOW}${CODIUM_FILE_URL}${RESET}"
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCodium.deb' ${CODIUM_FILE_URL}
        apt show ./VSCodium.deb
        apt install -y ./VSCodium.deb
        rm -vf VSCodium.deb
        copy_gnu_lib_xcb_so
        fix_tightvnc_vscode_lnk
        echo "安装完成,您可以输codium --user-data-dir=${HOME}/.codium启动"
    else
        LatestVSCodiumLink="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${CodiumARCH} | grep -v '.sha256' | grep '.tar' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
        CODIUM_FILE_URL="https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
        echo "${YELLOW}${CODIUM_FILE_URL}${RESET}"
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCodium.tar.gz' ${CODIUM_FILE_URL}
        mkdir -p /opt/vscodium-data
        tar -zxvf VSCodium.tar.gz -C /opt/vscodium-data
        rm -vf VSCodium.tar.gz
        cp -f ${TMOE_TOOL_DIR}/code/bin/codium /usr/local/bin
        cp -f ${TMOE_TOOL_DIR}/code/lnk/codium.desktop ${APPS_LNK_DIR}
        if [ -e "/usr/share/icons/vscodium.png" ]; then
            aria2c -d '/usr/share/icons' -o 'vscodium.png' 'https://gitee.com/ak2/icons/raw/master/vscodium.png'
        fi
        #ln -sf /opt/vscodium-data/codium /usr/local/bin/codium
        echo "安装完成，您可以输codium启动"
    fi
}
########################
install_vscode_oss() {
    if [ -e "/usr/bin/code-oss" ]; then
        echo "检测到您已安装VSCode OSS,请手动输以下命令启动"
        #echo 'code-oss --user-data-dir=${HOME}/.config/Code\ -\ OSS\ \(headmelted\)'
        echo "code-oss --user-data-dir=${HOME}/.codeoss"
        echo "如需卸载，请手动输${TMOE_REMOVAL_COMMAND} code-oss"
        press_enter_to_return
        which_vscode_edition
    fi

    if [ "${LINUX_DISTRO}" = 'debian' ]; then
        install_gpg
        copy_gnu_lib_xcb_so
        fix_tightvnc_vscode_lnk
        bash -c "$(wget -O- https://code.headmelted.com/installers/apt.sh)"
    elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
        . <(wget -O- https://code.headmelted.com/installers/yum.sh)
    else
        echo "检测到您当前使用的可能不是deb系或红帽系发行版，跳过安装"
        press_enter_to_return
        which_vscode_edition
    fi
    echo "安装完成,请手动输以下命令启动"
    echo "code-oss --user-data-dir=${HOME}/.codeoss"
    echo "如需卸载，请手动输${TMOE_REMOVAL_COMMAND} code-oss"
}
#######################
download_vscode_x64_deb() {
    aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.deb' "https://go.microsoft.com/fwlink/?LinkID=760868"
    apt show ./VSCODE.deb
    apt install -y ./VSCODE.deb
    rm -vf VSCODE.deb
}
##########
install_vscode_official() {
    cd /tmp
    if [ "${ARCH_TYPE}" != 'amd64' ]; then
        echo "当前仅支持x86_64架构"
        arch_does_not_support
        which_vscode_edition
    fi

    if [ -e "/usr/bin/code" ]; then
        echo '检测到您已安装VSCode,请手动输以下命令启动'
        #echo 'code --user-data-dir=${HOME}/.vscode'
        echo 'code --user-data-dir=${HOME}/.vsode'
        echo "如需卸载，请手动输${TMOE_REMOVAL_COMMAND} code"
        #echo "${YELLOW}按回车键返回。${RESET}"
        #echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
        #read
        code --version
        echo "请问您是否需要下载最新版安装包？"
        echo "Do you want to download the latest vscode?"
        do_you_want_to_continue
        #download_vscode_x64_deb
        #which_vscode_edition
    elif [ -e "/usr/local/bin/vscode-data/code" ]; then
        echo "检测到您已安装VSCode,请输code --no-sandbox启动"
        echo "如需卸载，请手动输rm -rvf /usr/local/bin/VSCode-linux-x64/ /usr/local/bin/code"
        echo "${YELLOW}按回车键返回。${RESET}"
        echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
        read
        which_vscode_edition
    fi

    if [ "${LINUX_DISTRO}" = 'debian' ]; then
        download_vscode_x64_deb
        echo "安装完成,请输code --user-data-dir=${HOME}/.vscode启动"

    elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.rpm' "https://go.microsoft.com/fwlink/?LinkID=760867"
        rpm -ivh ./VSCODE.rpm
        rm -vf VSCODE.rpm
        echo "安装完成,请输code --user-data-dir=${HOME}/.vscode启动"
    else
        aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.tar.gz' "https://go.microsoft.com/fwlink/?LinkID=620884"
        #mkdir -p /usr/local/bin/vscode-data
        tar -zxvf VSCODE.tar.gz -C /usr/local/bin/

        rm -vf VSCode.tar.gz
        ln -sf /usr/local/bin/VSCode-linux-x64/code /usr/local/bin/code
        echo "安装完成，输code --no-sandbox启动"
    fi
}
###############################
which_vscode_edition
