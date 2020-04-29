#!/bin/bash
########################################################################
#-- 自动检测相关依赖和发行版

CHECKdependencies() {

	if [ "$(id -u)" != "0" ]; then
		if [ -e "/usr/bin/curl" ]; then
			sudo bash -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)" ||
				su -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
		else
			sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)" ||
				su -c "$(wget -qO- https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
		fi
		exit 0
	fi
	#############################

	if grep -Eq 'debian|ubuntu' "/etc/os-release"; then
		LINUXDISTRO='debian'
		if grep -q 'ubuntu' /etc/os-release; then
			DEBIANDISTRO='ubuntu'
		elif [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
			DEBIANDISTRO='kali'
		fi

	elif grep -Eq "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		LINUXDISTRO='openwrt'

	elif grep -Eqi "Fedora|CentOS|Red Hat|redhat" "/etc/os-release"; then
		LINUXDISTRO='redhat'
		if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHATDISTRO='centos'
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHATDISTRO='fedora'
		fi

	elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" "/etc/os-release"; then
		LINUXDISTRO='alpine'

	elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
		LINUXDISTRO='arch'

	elif grep -Eq "gentoo|funtoo" "/etc/os-release"; then
		LINUXDISTRO='gentoo'

	elif grep -qi 'suse' '/etc/os-release'; then
		LINUXDISTRO='suse'

	elif [ "$(cat /etc/issue | cut -c 1-4)" = "Void" ]; then
		LINUXDISTRO='void'
	fi

	#####################
	dependencies=""

	if [ "${LINUXDISTRO}" = "debian" ]; then
		if [ ! -e /usr/bin/aptitude ]; then
			dependencies="${dependencies} aptitude"
		fi
	fi

	if [ ! -e /bin/bash ]; then
		dependencies="${dependencies} bash"
	fi

	if [ ! -e /usr/bin/busybox ] && [ ! -e /bin/busybox ] && [ ! -e /sbin/busybox ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} sys-apps/busybox"
		elif [ "${LINUXDISTRO}" = "redhat" ]; then
			if [ "${REDHATDISTRO}" = "fedora" ]; then
				dependencies="${dependencies} busybox"
			fi
		else
			dependencies="${dependencies} busybox"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/catimg ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			if grep -q 'VERSION_ID' "/etc/os-release"; then
				DEBIANVERSION="$(grep 'VERSION_ID' "/etc/os-release" | cut -d '"' -f 2 | cut -d '.' -f 1)"
			else
				DEBIANVERSION="10"
			fi
			if ((${DEBIANVERSION} <= 9)); then
				echo "检测到您的系统版本低于debian10，跳过安装catimg"
			else
				dependencies="${dependencies} catimg"
			fi

		elif [ "${REDHATDISTRO}" = "fedora" ] || [ "${LINUXDISTRO}" = "arch" ]; then
			dependencies="${dependencies} catimg"
		fi
	fi

	if [ ! -e /usr/bin/curl ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} net-misc/curl"
		else
			dependencies="${dependencies} curl"
		fi
	fi
	######################
	if [ ! -e /usr/bin/fc-cache ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			dependencies="${dependencies} fontconfig"
		fi
	fi
	###################

	if [ ! -e /usr/bin/git ]; then
		if [ "${LINUXDISTRO}" = "openwrt" ]; then
			dependencies="${dependencies} git git-http"
		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} dev-vcs/git"
		else
			dependencies="${dependencies} git"
		fi
	fi
	####################
	if [ ! -e /usr/bin/mkfontscale ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			dependencies="${dependencies} xfonts-utils"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/xz ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			dependencies="${dependencies} xz-utils"
		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} app-arch/xz-utils"
		else
			dependencies="${dependencies} xz"
		fi
	fi

	if [ ! -e /usr/bin/pkill ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} sys-process/procps"
		elif [ "${LINUXDISTRO}" != "openwrt" ]; then
			dependencies="${dependencies} procps"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/sudo ]; then
		if [ "${LINUXDISTRO}" != "gentoo" ]; then
			dependencies="${dependencies} sudo"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/whiptail ] && [ ! -e /bin/whiptail ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			dependencies="${dependencies} whiptail"
		elif [ "${LINUXDISTRO}" = "arch" ]; then
			dependencies="${dependencies} libnewt"
		elif [ "${LINUXDISTRO}" = "openwrt" ]; then
			dependencies="${dependencies} dialog"
		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} dev-libs/newt"
		else
			dependencies="${dependencies} newt"
		fi
	fi
	##############
	if [ ! -e /usr/bin/wget ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} net-misc/wget"
		else
			dependencies="${dependencies} wget"
		fi
	fi
	##############

	if [ ! -z "${dependencies}" ]; then
		echo "正在安装相关依赖..."

		if [ "${LINUXDISTRO}" = "debian" ]; then
			apt update
			apt install -y ${dependencies}
			#创建文件夹防止aptitude报错
			mkdir -p /run/lock /var/lib/aptitude
			touch /var/lib/aptitude/pkgstates

		elif [ "${LINUXDISTRO}" = "alpine" ]; then
			apk update
			apk add ${dependencies}

		elif [ "${LINUXDISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm ${dependencies}

		elif [ "${LINUXDISTRO}" = "redhat" ]; then
			dnf install -y ${dependencies} || yum install -y ${dependencies}

		elif [ "${LINUXDISTRO}" = "openwrt" ]; then
			#opkg update
			opkg install ${dependencies} || opkg install whiptail

		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			emerge -avk ${dependencies}

		elif [ "${LINUXDISTRO}" = "suse" ]; then
			zypper in -y ${dependencies}

		elif [ "${LINUXDISTRO}" = "void" ]; then
			xbps-install -S -y ${dependencies}

		else

			apt update
			apt install -y ${dependencies} || port install ${dependencies} || zypper in ${dependencies} || guix package -i ${dependencies} || pkg install ${dependencies} || pkg_add ${dependencies} || pkgutil -i ${dependencies}
		fi
	fi
	################
	case $(uname -m) in
	aarch64)
		archtype="arm64"
		;;
	armv7l)
		archtype="armhf"
		;;
	armv6l)
		archtype="armel"
		;;
	x86_64)
		archtype="amd64"
		;;
	i*86)
		archtype="i386"
		;;
	x86)
		archtype="i386"
		;;
	s390*)
		archtype="s390x"
		;;
	ppc*)
		archtype="ppc64el"
		;;
	mips*)
		archtype="mipsel"
		;;
	risc*)
		archtype="riscv"
		;;
	esac
	################

	if [ ! -e /usr/bin/catimg ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			CATIMGlatestVersion="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/' | grep arm64 | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '_' -f 2)"
			cd /tmp
			wget -O 'catimg.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/catimg_${CATIMGlatestVersion}_${archtype}.deb"
			apt install -y ./catimg.deb
			rm -f catimg.deb
		fi
	fi

	if [ ! -e /usr/bin/busybox ] && [ ! -e /bin/busybox ] && [ ! -e /usr/local/bin/busybox ]; then
		cd /tmp
		wget --no-check-certificate -O "busybox" "https://gitee.com/mo2/busybox/raw/master/busybox-$(uname -m)"
		chmod +x busybox
		LatestBusyboxDEB="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/busybox/ | grep static | grep ${archtype} | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		wget -O '.busybox.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/busybox/${LatestBusyboxDEB}"
		mkdir -p .busybox-static
		./busybox dpkg-deb -X .busybox.deb ./.busybox-static
		mv -f ./.busybox-static/bin/busybox /usr/local/bin/
		chmod +x /usr/local/bin/busybox
		rm -rf busybox .busybox-static .busybox.deb
	fi

	if [ "${LINUXDISTRO}" = "debian" ]; then
		if [ "${DEBIANDISTRO}" = "ubuntu" ]; then
			if [ ! -e "/bin/add-apt-repository" ] && [ ! -e "/usr/bin/add-apt-repository" ]; then
				apt install -y software-properties-common
			fi
		fi

		if ! grep -q "^zh_CN" "/etc/locale.gen"; then
			if [ ! -e "/usr/sbin/locale-gen" ]; then
				apt install -y locales
			fi
			sed -i 's/^#.*zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
			locale-gen
			apt install -y language-pack-zh-hans 2>/dev/null
		fi
	fi

	if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
		WINDOWSDISTRO='WSL'
	fi

	if [ "${LINUXDISTRO}" != "debian" ]; then
		TMOENODEBIAN="$(echo WARNING！检测到您当前使用的不是deb系linux，可能无法正常运行！)"
	else
		TMOENODEBIAN=""
	fi

	YELLOW=$(printf '\033[33m')
	RESET=$(printf '\033[m')
	cur=$(pwd)
	DEBIANMENU
}
####################################################
DEBIANMENU() {
	cd ${cur}
	OPTION=$(
		whiptail --title "Tmoe-linux Tool输debian-i启动(20200429-18)" --menu "Type 'debian-i' to start this tool.Please use the enter and arrow keys to operate.当前主菜单有十几个选项，请使用方向键或触屏上下滑动，按回车键确认。${TMOENODEBIAN} 更新日志:0411支持修复VNC闪退,0420增加其它版本的VSCode" 20 50 6 \
			"1" "Install GUI 安装图形界面" \
			"2" "Install browser 安装浏览器" \
			"3" "Download theme 下载主题" \
			"4" "Other software/games 其它软件/游戏" \
			"5" "Modify VNC/XSDL/XRDP(远程桌面)conf" \
			"6" "Modify to Kali sources list 配置kali源" \
			"7" "Update Debian tool 更新本工具" \
			"8" "Install Chinese manual 安装中文手册" \
			"9" "Enable zsh tool 启用zsh管理工具" \
			"10" "VSCode" \
			"11" "Remove GUI 卸载图形界面" \
			"12" "Remove browser 卸载浏览器" \
			"13" "FAQ 常见问题" \
			"14" "Beta Features 测试版功能" \
			"0" "Exit 退出" \
			3>&1 1>&2 2>&3
	)
	###############################
	if [ "${OPTION}" == '0' ]; then
		exit 0
	fi
	##############################
	if [ "${OPTION}" == '1' ]; then

		INSTALLGUI
	fi
	###################################
	if [ "${OPTION}" == '2' ]; then

		installBROWSER

	fi
	###################################
	if [ "${OPTION}" == '3' ]; then

		CONFIGTHEMES

	fi
	###################################
	if [ "${OPTION}" == '4' ]; then

		OTHERSOFTWARE

	fi
	####################
	if [ "${OPTION}" == '5' ]; then
		MODIFYREMOTEDESKTOP
		#MODIFYVNCORXSDLCONF
	fi
	############

	if [ "${OPTION}" == '6' ]; then

		MODIFYTOKALISourcesList

	fi
	###################################
	if [ "${OPTION}" == '7' ]; then

		wget -O /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian-gui-install.bash'
		echo 'Update completed, press Enter to return.'
		echo "${YELLOW}更新完成，按回车键返回。${RESET}"
		chmod +x /usr/local/bin/debian-i
		read
		#bash /usr/local/bin/debian-i
		source /usr/local/bin/debian-i
	fi
	################

	if [ "${OPTION}" == '8' ]; then

		CHINESEMANPAGES

	fi

	#################################
	if [ "${OPTION}" == '9' ]; then

		bash -c "$(curl -LfsS 'https://gitee.com/mo2/zsh/raw/master/zsh.sh')"

	fi
	###################################
	if [ "${OPTION}" == '10' ]; then
		WHICHVSCODEedition
	fi
	###################################
	if [ "${OPTION}" == '11' ]; then

		REMOVEGUI
	fi

	###############################

	if [ "${OPTION}" == '12' ]; then

		REMOVEBROWSER
	fi

	###############################
	if [ "${OPTION}" == '13' ]; then

		FrequentlyAskedQuestions

	fi
	###############################
	if [ "${OPTION}" == '14' ]; then

		BetaFeatures

	fi
}
############################
WHICHVSCODEedition() {
	ps -e >/dev/null 2>&1 || VSCODEtips=$(echo "检测到您无权读取/proc分区的部分内容，请选择Server版，或使用XSDL打开VSCode本地版")
	VSCODEedition=$(whiptail --title "Visual Studio Code" --menu \
		"${VSCODEtips} Which edition do you want to install" 15 60 5 \
		"1" "VS Code Server(arm64,web版)" \
		"2" "VS Codium" \
		"3" "VS Code OSS" \
		"4" "Microsoft Official(x64,官方版)" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${VSCODEedition}" == '0' ]; then
		DEBIANMENU
	fi
	##############################
	if [ "${VSCODEedition}" == '1' ]; then
		if [ "$(uname -m)" = "aarch64" ]; then
			INSTALLORREMOVEVSCODE
		else
			echo "非常抱歉，Tmoe-linux的开发者未对您的架构进行适配。"
			echo "请选择其它版本"
			echo "${YELLOW}按回车键返回。${RESET}"
			echo "Press enter to return."
			read
			DEBIANMENU
		fi
	fi
	##############################
	if [ "${VSCODEedition}" == '2' ]; then
		InstallVScodium
	fi
	##############################
	if [ "${VSCODEedition}" == '3' ]; then
		InstallVScodeOSS
	fi
	##############################
	if [ "${VSCODEedition}" == '4' ]; then
		InstallVSCodeOfficial
	fi
	#########################
	echo "${YELLOW}按回车键返回。${RESET}"
	echo "Press enter to return."
	read
	DEBIANMENU
}
#################################
InstallVScodium() {
	cd /tmp
	if [ "${archtype}" = 'arm64' ]; then
		CodiumARCH=arm64
	elif [ "${archtype}" = 'armhf' ]; then
		CodiumARCH=arm
		#CodiumDebArch=armhf
	elif [ "${archtype}" = 'amd64' ]; then
		CodiumARCH=x64
	elif [ "${archtype}" = 'i386' ]; then
		echo "暂不支持i386 linux"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		WHICHVSCODEedition
	fi

	if [ -e "/usr/bin/codium" ]; then
		echo '检测到您已安装VSCodium,请手动输以下命令启动'
		#echo 'codium --user-data-dir=${HOME}/.config/VSCodium'
		echo "codium --user-data-dir=${HOME}"
		echo "如需卸载，请手动输apt purge -y codium"
	elif [ -e "/usr/local/bin/vscodium-data/codium" ]; then
		echo "检测到您已安装VSCodium,请输codium --no-sandbox启动"
		echo "如需卸载，请手动输rm -rvf /usr/local/bin/vscodium-data/ /usr/local/bin/vscodium"
	fi

	if [ $(command -v codium) ]; then
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		WHICHVSCODEedition
	fi

	if [ "${LINUXDISTRO}" = 'debian' ]; then
		LatestVSCodiumLink="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${archtype} | grep -v '.sha256' | grep '.deb' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		wget -O 'VSCodium.deb' "https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
		apt install -y ./VSCodium.deb
		rm -vf VSCodium.deb
		#echo '安装完成,请输codium --user-data-dir=${HOME}/.config/VSCodium启动'
		echo "安装完成,请输codium --user-data-dir=${HOME}启动"
	else
		LatestVSCodiumLink="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${CodiumARCH} | grep -v '.sha256' | grep '.tar' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		wget -O 'VSCodium.tar.gz' "https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
		mkdir -p /usr/local/bin/vscodium-data
		tar -zxvf VSCodium.tar.gz -C /usr/local/bin/vscodium-data
		rm -vf VSCodium.tar.gz
		ln -sf /usr/local/bin/vscodium-data/codium /usr/local/bin/codium
		echo "安装完成，输codium --no-sandbox启动"
	fi
	echo "${YELLOW}按回车键返回。${RESET}"
	echo "Press enter to return."
	read
	WHICHVSCODEedition
}
########################
InstallVScodeOSS() {

	if [ -e "/usr/bin/code-oss" ]; then
		echo "检测到您已安装VSCode OSS,请手动输以下命令启动"
		#echo 'code-oss --user-data-dir=${HOME}/.config/Code\ -\ OSS\ \(headmelted\)'
		echo "code-oss --user-data-dir=${HOME}"
		echo "如需卸载，请手动输apt purge -y code-oss"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		WHICHVSCODEedition
	fi

	if [ "${LINUXDISTRO}" = 'debian' ]; then
		apt update
		apt install -y gpg
		bash -c "$(wget -O- https://code.headmelted.com/installers/apt.sh)"
	elif [ "${LINUXDISTRO}" = 'redhat' ]; then
		. <(wget -O - https://code.headmelted.com/installers/yum.sh)
	else
		echo "检测到您当前使用的可能不是deb系或红帽系发行版，跳过安装"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		WHICHVSCODEedition
	fi
	echo "安装完成,请手动输以下命令启动"
	echo "code-oss --user-data-dir=${HOME}"
	echo "如需卸载，请手动输apt purge -y code-oss"
	echo "${YELLOW}按回车键返回。${RESET}"
	echo "Press enter to return."
	read
	WHICHVSCODEedition

}
#######################
InstallVSCodeOfficial() {

	cd /tmp
	if [ "${archtype}" != 'amd64' ]; then
		echo "当前仅支持x86_64架构"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		WHICHVSCODEedition
	fi

	if [ -e "/usr/bin/code" ]; then
		echo '检测到您已安装VSCode,请手动输以下命令启动'
		#echo 'code --user-data-dir=${HOME}/.vscode'
		echo 'code --user-data-dir=${HOME}'
		echo "如需卸载，请手动输apt purge -y code"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		WHICHVSCODEedition
	elif [ -e "/usr/local/bin/vscode-data/code" ]; then
		echo "检测到您已安装VSCode,请输code --no-sandbox启动"
		echo "如需卸载，请手动输rm -rvf /usr/local/bin/VSCode-linux-x64/ /usr/local/bin/code"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		WHICHVSCODEedition
	fi

	if [ "${LINUXDISTRO}" = 'debian' ]; then
		wget -O 'VSCODE.deb' "https://go.microsoft.com/fwlink/?LinkID=760868"
		apt install -y ./VSCODE.deb
		rm -vf VSCODE.deb
		echo "安装完成,请输code --user-data-dir=${HOME}启动"

	elif [ "${LINUXDISTRO}" = 'redhat' ]; then
		wget -O 'VSCODE.rpm' "https://go.microsoft.com/fwlink/?LinkID=760867"
		rpm -ivh ./VSCODE.rpm
		rm -vf VSCODE.rpm
		echo "安装完成,请输code --user-data-dir=${HOME}启动"
	else
		wget -O 'VSCODE.tar.gz' "https://go.microsoft.com/fwlink/?LinkID=620884"
		#mkdir -p /usr/local/bin/vscode-data
		tar -zxvf VSCODE.tar.gz -C /usr/local/bin/

		rm -vf VSCode.tar.gz
		ln -sf /usr/local/bin/VSCode-linux-x64/code /usr/local/bin/code
		echo "安装完成，输code --no-sandbox启动"
	fi
	echo "${YELLOW}按回车键返回。${RESET}"
	echo "Press enter to return."
	read
	WHICHVSCODEedition
}

#######################
MODIFYVNCCONF() {
	if [ ! -e /bin/nano ]; then
		apt update
		apt install -y nano
	fi

	if [ ! -e /usr/local/bin/startvnc ]; then
		echo "/usr/local/bin/startvnc is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startvnc,您可能尚未安装图形桌面，是否继续编辑?'
		echo "Press Enter to confirm."
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		read
	fi
	if (whiptail --title "modify vnc configuration" --yes-button '分辨率resolution' --no-button '其它other' --yesno "您想要修改哪些配置信息？What configuration do you want to modify?" 9 50); then
		TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,1440x720,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为720x1440,当前为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1) 。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			sed -i '/vncserver -geometry/d' "$(command -v startvnc)"
			sed -i "$ a\vncserver -geometry $TARGET -depth 24 -name remote-desktop :1" "$(command -v startvnc)"
			echo 'Your current resolution has been modified.'
			echo '您当前的分辨率已经修改为'
			echo $(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			#echo $(sed -n \$p "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			#$p表示最后一行，必须用反斜杠转义。
			stopvnc 2>/dev/null
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			DEBIANMENU

		else
			echo '您当前的分辨率为'
			echo $(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
		fi

	else
		MODIFYOTHERCONF
	fi
}
################################
MODIFYOTHERCONF() {

	MODIFYOTHERVNCCONF=$(whiptail --title "Modify vnc server conf" --menu "Choose your option" 15 60 5 \
		"1" "音频地址 Pulse server address" \
		"2" "VNC密码 password" \
		"3" "Edit xstartup manually 手动编辑xstartup" \
		"4" "Edit startvnc manually 手动编辑vnc启动脚本" \
		"5" "修复VNC闪退" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '0' ]; then
		DEBIANMENU
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '1' ]; then
		EDITVNCPULSEAUDIO
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '2' ]; then
		echo 'The password you entered is hidden.'
		echo '您需要输两遍（不可见的）密码。'
		echo "When prompted for a view-only password, it is recommended that you enter 'n'"
		echo '如果提示view-only,那么建议您输n,选择权在您自己的手上。'
		echo '请输入6至8位密码'
		/usr/bin/vncpasswd
		echo '修改完成，您之后可以输startvnc来启动vnc服务，输stopvnc停止'
		echo "正在为您停止VNC服务..."
		sleep 1
		stopvnc 2>/dev/null
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		MODIFYOTHERCONF
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '3' ]; then
		nano ~/.vnc/xstartup
		stopvnc 2>/dev/null
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		MODIFYOTHERCONF
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '4' ]; then
		NANOSTARTVNCMANUALLY
	fi
	#########################
	if [ "${MODIFYOTHERVNCCONF}" == '5' ]; then
		FIXVNCdbusLaunch
	fi
	##########
}
#########################
EDITVNCPULSEAUDIO() {
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。linux默认为127.0.0.1,WSL2默认为宿主机ip,当前为$(grep 'PULSE_SERVER' ~/.vnc/xstartup | cut -d '=' -f 2) \n本功能适用于局域网传输，本机操作无需任何修改。若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：您需要手动启动音频服务端,Android-Termux需输pulseaudio --start,win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat' \n至于其它第三方app,例如安卓XSDL,若其显示的PULSE_SERVER地址为192.168.1.3:4713,那么您需要输入192.168.1.3:4713" 20 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		#sed -i '/PULSE_SERVER/d' ~/.vnc/xstartup
		#sed -i "2 a\export PULSE_SERVER=$TARGET" ~/.vnc/xstartup
		if grep '^export.*PULSE_SERVER' "${HOME}/.vnc/xstartup"; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" ~/.vnc/xstartup
		else
			sed -i "4 a\export PULSE_SERVER=$TARGET" ~/.vnc/xstartup
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' ~/.vnc/xstartup | cut -d '=' -f 2)
		echo "请输startvnc重启vnc服务，以使配置生效"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		MODIFYOTHERCONF
	else
		MODIFYOTHERCONF
	fi
}
##################
NANOSTARTVNCMANUALLY() {
	echo '您可以手动修改vnc的配置信息'
	echo 'If you want to modify the resolution, please change the 720x1440 (default resolution , vertical screen) to another resolution, such as 1920x1080 (landscape).'
	echo '若您想要修改分辨率，请将默认的720x1440（竖屏）改为其它您想要的分辨率，例如1920x1080（横屏）。'
	echo "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"
	echo '改完后按Ctrl+S保存，Ctrl+X退出。'
	echo "Press Enter to confirm."
	echo "${YELLOW}按回车键确认编辑。${RESET}"
	read
	nano /usr/local/bin/startvnc || nano $(command -v startvnc)
	echo "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"

	stopvnc 2>/dev/null
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	MODIFYOTHERCONF
}

############################
MODIFYXSDLCONF() {

	if [ ! -f /usr/local/bin/startxsdl ]; then
		echo "/usr/local/bin/startxsdl is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startxsdl,您可能尚未安装图形桌面，是否继续编辑。'
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		read

	fi

	XSDLXSERVER=$(whiptail --title "Modify x server conf" --menu "Choose your option" 15 60 5 \
		"1" "音频端口 Pulse server port " \
		"2" "显示编号 Display number" \
		"3" "ip address" \
		"4" "手动编辑 Edit manually" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)

	###########
	if [ "${XSDLXSERVER}" == '0' ]; then
		DEBIANMENU
	fi
	if [ "${XSDLXSERVER}" == '1' ]; then
		CHANGEPULSESERVERPORT
	fi
	if [ "${XSDLXSERVER}" == '2' ]; then
		CHANGEDISPLAYPORT
	fi
	if
		[ "${XSDLXSERVER}" == '3' ]
	then
		CHANGEIPADDRESS
	fi
	if [ "${XSDLXSERVER}" == '4' ]; then
		NANOMANUALLYMODIFY
	fi
}
#################
NANOMANUALLYMODIFY() {
	if [ ! -e /bin/nano ]; then
		apt update
		apt install -y nano
	fi
	nano /usr/local/bin/startxsdl || nano $(command -v startxsdl)
	echo 'See your current xsdl configuration information below.'
	echo '您当前的ip地址为'
	echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)

	echo '您当前的显示端口为'
	echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2)

	echo '您当前的音频端口为'
	echo $(sed -n 4p $(command -v startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	MODIFYXSDLCONF
}

######################
CHANGEPULSESERVERPORT() {

	TARGET=$(whiptail --inputbox "若xsdl app显示的端口非4713，则您可在此处修改。默认为4713，当前为$(sed -n 4p $(command -v startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2) \n请以xsdl app显示的pulse server地址的最后几位数字为准，输入完成后按回车键确认。" 20 50 --title "MODIFY PULSE SERVER PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "4 c export PULSE_SERVER=tcp:127.0.0.1:$TARGET" "$(command -v startxsdl)"
		echo 'Your current PULSE SERVER port has been modified.'
		echo '您当前的音频端口已修改为'
		echo $(sed -n 4p $(command -v startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		MODIFYXSDLCONF
	else
		MODIFYXSDLCONF
	fi
}

########################################################
CHANGEDISPLAYPORT() {

	TARGET=$(whiptail --inputbox "若xsdl app显示的Display number(输出显示的端口数字) 非0，则您可在此处修改。默认为0，当前为$(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2) \n请以xsdl app显示的DISPLAY=:的数字为准，输入完成后按回车键确认。" 20 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "3 c export DISPLAY=127.0.0.1:$TARGET" "$(command -v startxsdl)"
		echo 'Your current DISPLAY port has been modified.'
		echo '您当前的显示端口已修改为'
		echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2)
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		MODIFYXSDLCONF
	else
		MODIFYXSDLCONF
	fi
}

###############################################
CHANGEIPADDRESS() {

	XSDLIP=$(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)
	TARGET=$(whiptail --inputbox "若您需要用局域网其它设备来连接，则您可在下方输入该设备的IP地址。本机连接请勿修改，默认为127.0.0.1 ,当前为${XSDLIP} \n 请在修改完其它信息后，再来修改此项，否则将被重置为127.0.0.1。windows设备输 ipconfig，linux设备输ip -4 -br -c addr获取ip address，获取到的地址格式类似于192.168.123.234，输入获取到的地址后按回车键确认。" 20 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "s/${XSDLIP}/${TARGET}/g" "$(command -v startxsdl)"
		echo 'Your current ip address has been modified.'
		echo '您当前的ip地址已修改为'
		echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		MODIFYXSDLCONF
	else
		MODIFYXSDLCONF
	fi
}
#############################################
installBROWSER() {
	if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno "建议在安装完图形界面后，再来选择哦！(　o=^•ェ•)o　┏━┓\n我是火狐娘，选我啦！♪(^∇^*) \n妾身是chrome娘的姐姐chromium娘，妾身和那些妖艳的货色不一样，选择妾身就没错呢！(✿◕‿◕✿)✨\n请做出您的选择！ " 15 50); then

		if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox-ESR" --no-button "Firefox" --yesno " 我是firefox，其实我还有个妹妹叫firefox-esr，您是选我还是选esr?\n “(＃°Д°)姐姐，我可是什么都没听你说啊！” 躲在姐姐背后的ESR瑟瑟发抖地说。\n✨请做出您的选择！ " 15 50); then
			#echo 'esr可怜巴巴地说道:“我也想要得到更多的爱。”  '
			#什么乱七八糟的，2333333戏份真多。
			echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
			echo "${YELLOW} “谢谢您选择了我，我一定会比姐姐向您提供更好的上网服务的！”╰(*°▽°*)╯火狐ESR娘坚定地说道。 ${RESET} "
			echo "1s后将自动开始安装"
			sleep 1
			echo
			if [ "${LINUXDISTRO}" = "debian" ]; then
				if [ "${DEBIANDISTRO}" = "ubuntu" ]; then
					add-apt-repository -y ppa:mozillateam/ppa
				fi
				apt update
				#分项安装，防止ubuntu安装失败
				apt install -y firefox-esr
				apt install -y firefox-esr-l10n-zh-cn
				apt install -y firefox-esr-locale-zh-hans 2>/dev/null
			elif [ "${LINUXDISTRO}" = "arch" ]; then
				pacman -Sy --noconfirm firefox-esr-gtk2
				if [ ! -e "/usr/bin/firefox-esr" ]; then
					echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫姐姐来代替了。${RESET}"
					pacman -Syu --noconfirm firefox firefox-i18n-zh-cn
				fi

			elif [ "${LINUXDISTRO}" = "redhat" ]; then
				dnf install -y firefox-esr || yum install -y firefox-esr
				if [ ! -e "/usr/bin/firefox-esr" ]; then
					echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫姐姐来代替了。${RESET}"
					dnf install -y firefox || yum install -y firefox
				fi
			elif [ "${LINUXDISTRO}" = "gentoo" ]; then
				dispatch-conf
				emerge -avk www-client/firefox
			elif [ "${LINUXDISTRO}" = "suse" ]; then
				zypper in -y MozillaFirefox MozillaFirefox-translations-common
			fi
		else
			echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
			echo " ${YELLOW}“谢谢您选择了我，我一定会比妹妹向您提供更好的上网服务的！”╰(*°▽°*)╯火狐娘坚定地说道。${RESET} "
			echo "1s后将自动开始安装"
			sleep 1
			if [ "${LINUXDISTRO}" = "debian" ]; then
				apt update
				apt install -y firefox || apt install -y firefox-esr firefox-esr-l10n-zh-cn
				if [ -e "/usr/bin/firefox-esr" ]; then
					echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫妹妹ESR来代替了。${RESET}"
				fi
				apt install -y firefox-l10n-zh-cn 2>/dev/null
				apt install -y firefox-locale-zh-hans 2>/dev/null
			elif [ "${LINUXDISTRO}" = "arch" ]; then
				pacman -Syu --noconfirm firefox firefox-i18n-zh-cn
			elif [ "${LINUXDISTRO}" = "redhat" ]; then
				dnf install -y firefox || yum install -y firefox
			elif [ "${LINUXDISTRO}" = "gentoo" ]; then
				dispatch-conf
				emerge -avk www-client/firefox-bin
			elif [ "${LINUXDISTRO}" = "suse" ]; then
				zypper in -y MozillaFirefox MozillaFirefox-translations-common
			fi
		fi
		echo "若无法正常加载HTML5视频，则您可能需要安装火狐扩展${YELLOW}User-Agent Switcher and Manager${RESET}，并将浏览器UA修改为windows版chrome"
	else

		echo "${YELLOW}妾身就知道你没有看走眼！${RESET}"
		echo '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium --no-sandbox"'
		echo "1s后将自动开始安装"
		sleep 1
		if [ "${LINUXDISTRO}" = "debian" ]; then
			#新版Ubuntu是从snap商店下载chromium的，为解决这一问题，将临时换源成ubuntu 18.04LTS.
			if [ "${DEBIANDISTRO}" = "ubuntu" ]; then
				if ! grep -q '^deb.*bionic-update' "/etc/apt/sources.list"; then
					if [ $(uname -m) = "aarch64" ] || [ $(uname -m) = "armv7l" ] || [ $(uname -m) = "armv6l" ]; then
						sed -i '$ a\deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
					else
						sed -i '$ a\deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
					fi
					apt update
					apt install -y chromium-browser/bionic-updates
					apt install -y chromium-browser-l10n/bionic-updates
					sed -i '$ d' "/etc/apt/sources.list"
					apt-mark hold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg-extra
					apt update
				else
					apt install -y chromium-browser chromium-browser-l10n
				fi
				sed -i 's/chromium-browser %U/chromium-browser --no-sandbox %U/g' /usr/share/applications/chromium-browser.desktop
				grep 'chromium-browser' /etc/profile || sed -i '$ a\alias chromium="chromium-browser --no-sandbox"' /etc/profile
			else
				apt update
				apt install -y chromium chromium-l10n
				sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
				grep 'chromium' /etc/profile || sed -i '$ a\alias chromium="chromium --no-sandbox"' /etc/profile
			fi
		#echo 'alias chromium="chromium --no-sandbox"' >>/etc/profile
		elif [ "${LINUXDISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm chromium
			sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
			grep 'chromium' /etc/profile || sed -i '$ a\alias chromium="chromium --no-sandbox"' /etc/profile
		elif [ "${LINUXDISTRO}" = "redhat" ]; then
			dnf install -y chromium || yum install -y chromium
			sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
			grep 'chromium' /etc/profile || sed -i '$ a\alias chromium="chromium --no-sandbox"' /etc/profile
		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			dispatch-conf
			emerge -avk www-client/chromium
		#emerge -avk www-client/google-chrome-unstable
		elif [ "${LINUXDISTRO}" = "suse" ]; then
			zypper in -y chromium chromium-plugin-widevinecdm chromium-ffmpeg-extra
		fi
	fi
	echo 'Press enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	DEBIANMENU
}
######################################################
INSTALLGUI() {
	cd /tmp
	echo 'lxde预览截图'
	#curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png' | catimg -
	if [ ! -f 'LXDE_BUSYeSLZRqq3i3oM.png' ]; then
		wget -qO 'LXDE_BUSYeSLZRqq3i3oM.png' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png'
	fi
	catimg 'LXDE_BUSYeSLZRqq3i3oM.png'

	echo 'mate预览截图'
	#curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/1frRp1lpOXLPz6mO.jpg' | catimg -
	if [ ! -f 'MATE_1frRp1lpOXLPz6mO.jpg' ]; then
		wget -qO 'MATE_1frRp1lpOXLPz6mO.jpg' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/1frRp1lpOXLPz6mO.jpg'
	fi
	catimg 'MATE_1frRp1lpOXLPz6mO.jpg'
	echo 'xfce预览截图'

	if [ ! -f 'XFCE_a7IQ9NnfgPckuqRt.jpg' ]; then
		wget -qO 'XFCE_a7IQ9NnfgPckuqRt.jpg' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/a7IQ9NnfgPckuqRt.jpg'
	fi
	catimg 'XFCE_a7IQ9NnfgPckuqRt.jpg'
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		if [ ! -e "/mnt/c/Users/Public/Downloads/VcXsrv/XFCE_a7IQ9NnfgPckuqRt.jpg" ]; then
			cp -f 'XFCE_a7IQ9NnfgPckuqRt.jpg' "/mnt/c/Users/Public/Downloads/VcXsrv"
		fi
		cd "/mnt/c/Users/Public/Downloads/VcXsrv"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\XFCE_a7IQ9NnfgPckuqRt.jpg" 2>/dev/null
	fi

	if [ ! -f '/usr/share/fonts/Iosevka.ttf' ]; then
		echo '正在刷新字体缓存...'
		mkdir -p /usr/share/fonts/
		cd /tmp
		if [ -e "font.ttf" ]; then
			mv -f font.ttf '/usr/share/fonts/Iosevka.ttf'
		else
			wget -qO 'Iosevka.tar.xz' 'https://gitee.com/mo2/Termux-zsh/raw/p10k/Iosevka.tar.xz'
			tar -xvf 'Iosevka.tar.xz'
			rm -f 'Iosevka.tar.xz'
			mv -f font.ttf '/usr/share/fonts/Iosevka.ttf'
		fi
		cd /usr/share/fonts/
		mkfontscale
		mkfontdir
		fc-cache
	fi
	#curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/a7IQ9NnfgPckuqRt.jpg' | catimg -
	echo "建议缩小屏幕字体，并重新加载图片，以获得更优的显示效果。"
	echo "按回车键选择您需要安装的图形桌面环境"
	echo "${YELLOW}Press enter to continue.${RESET}"
	read
	INSTALLDESKTOP=$(whiptail --title "单项选择题" --menu \
		"您想要安装哪个桌面？按方向键选择，回车键确认，一次只可以装一个桌面哦！仅xfce桌面支持在本工具内便捷下载主题。 \n Which desktop environment do you want to install? " 15 60 5 \
		"1" "xfce：兼容性高" \
		"2" "lxde：轻量化桌面" \
		"3" "mate：基于GNOME 2" \
		"4" "Other其它桌面(内测版新功能):lxqt,kde" \
		"0" "我一个都不要 =￣ω￣=" \
		3>&1 1>&2 2>&3)
	#绝赞测试中
	##########################
	if [ "$INSTALLDESKTOP" == '1' ]; then
		INSTALLXFCE4DESKTOP
	fi

	if [ "$INSTALLDESKTOP" == '2' ]; then
		INSTALLLXDEDESKTOP
	fi

	if [ "$INSTALLDESKTOP" == '3' ]; then
		INSTALLMATEDESKTOP
	fi

	if [ "$INSTALLDESKTOP" == '4' ]; then
		OTHERDESKTOP
	fi

	if [ "$INSTALLDESKTOP" == '0' ]; then
		DEBIANMENU
	fi
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	DEBIANMENU
}
#######################
OTHERDESKTOP() {
	BETADESKTOP=$(whiptail --title "Alpha features" --menu \
		"WARNING！本功能仍处于测试阶段,可能无法正常运行。部分桌面依赖systemd,无法在chroot环境中运行\nBeta features may not work properly." 15 60 6 \
		"1" "lxqt" \
		"2" "kde plasma 5" \
		"3" "gnome 3" \
		"4" "cinnamon" \
		"5" "dde (deepin desktop)" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${BETADESKTOP}" == '0' ]; then
		DEBIANMENU
	fi
	##############################
	if [ "${BETADESKTOP}" == '1' ]; then
		INSTALL-lXQT-DESKTOP
	fi
	##############################
	if [ "${BETADESKTOP}" == '2' ]; then
		INSTALL-KDE-PLASMA5-DESKTOP
	fi
	##############################
	if [ "${BETADESKTOP}" == '3' ]; then
		if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
			echo "检测到您当前可能处于chroot容器环境！"
			echo "${YELLOW}警告！GNOME3可能无法正常运行${RESET}"
		fi
		ps -e >/dev/null 2>&1
		exitstatus=$?
		if [ "${exitstatus}" != "0" ]; then
			echo "检测到您当前可能处于容器环境！"
			echo "${YELLOW}警告！GNOME3可能无法正常运行${RESET}"
			echo "WARNING! 检测到您未挂载/proc分区，请勿安装！"
		fi
		echo 'Press Enter to continue，press Ctrl+C to cancel.'
		echo "${YELLOW}按回车键继续安装，按Ctrl+C取消${RESET}"
		read
		INSTALL-GNOME3-DESKTOP
	fi
	##############################
	if [ "${BETADESKTOP}" == '4' ]; then
		INSTALL-cinnamon-DESKTOP
	fi
	##############################
	if [ "${BETADESKTOP}" == '5' ]; then
		INSTALL-DEEPIN-DESKTOP
	fi
	##############################
}

####################
INSTALL-lXQT-DESKTOP() {
	if [ "${LINUXDISTRO}" = "debian" ]; then
		#apt-mark hold gvfs
		apt update
		apt-mark hold udisks2
		echo '即将为您安装思源黑体(中文字体)、lxqt-core、lxqt-config、qterminal和tightvncserver等软件包。'
		dpkg --configure -a
		echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
		echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
		echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections

		apt install -y fonts-noto-cjk lxqt-core lxqt-config qterminal
		apt install -y dbus-x11
		apt install -y tightvncserver
		apt purge -y ^libfprint
		apt clean

	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		dnf groupinstall -y lxqt || yum groupinstall -y lxqt
		dnf install -y tigervnc-server google-noto-cjk-fonts || yum install -y tigervnc-server google-noto-cjk-fonts

	elif [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm lxqt xorg
		pacman -S --noconfirm tigervnc
		pacman -S --noconfirm noto-fonts-cjk
	elif [ "${LINUXDISTRO}" = "void" ]; then
		xbps-install -S -y lxqt tigervnc
	elif [ "${LINUXDISTRO}" = "gentoo" ]; then
		dispatch-conf
		etc-update
		emerge -avk lxqt-base/lxqt-meta net-misc/tigervnc media-fonts/wqy-bitmapfont
	elif [ "${LINUXDISTRO}" = "suse" ]; then
		zypper in -y tigervnc-x11vnc noto-sans-sc-fonts patterns-lxqt-lxqt
	fi

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		dbus-launch startlxqt &
	EndOfFile
	chmod +x ./xstartup
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null 2>/dev/null
	touch /tmp/.Tmoe-LXQT-Desktop-Detection-FILE
	STARTVNCANDSTOPVNC
}
####################
INSTALL-KDE-PLASMA5-DESKTOP() {
	if [ "${LINUXDISTRO}" = "debian" ]; then
		#apt-mark hold gvfs
		apt update
		apt-mark hold udisks2
		echo '即将为您安装思源黑体(中文字体)、kde-plasma-desktop和tightvncserver等软件包。'
		dpkg --configure -a
		echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
		echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
		echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
		aptitude install -y kde-plasma-desktop || apt install -y kde-plasma-desktop
		apt install -y fonts-noto-cjk dbus-x11
		apt install -y tightvncserver
		apt purge -y ^libfprint
		apt clean

	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		#yum groupinstall kde-desktop
		dnf groupinstall -y "KDE" || yum groupinstall -y "KDE"
		dnf install -y sddm || yum install -y sddm
		dnf install -y tigervnc-server google-noto-cjk-fonts || yum install -y tigervnc-server google-noto-cjk-fonts

	elif [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -S --noconfirm phonon-qt5-vnc plasma-desktop xorg
		pacman -S --noconfirm sddm sddm-kcm
		#中文输入法
		#pacman -S fcitx fcitx-rime fcitx-im kcm-fcitx fcitx-sogoupinyin
		pacman -S --noconfirm kdebase
		#pacman -S pamac-aur
		pacman -S --noconfirm tigervnc
		pacman -S --noconfirm noto-fonts-cjk
	elif [ "${LINUXDISTRO}" = "void" ]; then
		xbps-install -S -y kde tigervnc

	elif [ "${LINUXDISTRO}" = "gentoo" ]; then
		PLASMAnoSystemd=$(eselect profile list | grep plasma | grep -v systemd | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2)
		eselect profile set ${PLASMAnoSystemd}
		dispatch-conf
		etc-update
		#emerge -auvDN --with-bdeps=y @world
		emerge -avk plasma-desktop plasma-nm plasma-pa sddm konsole net-misc/tigervnc
	elif [ "${LINUXDISTRO}" = "suse" ]; then
		zypper in -y tigervnc-x11vnc noto-sans-sc-fonts patterns-kde-kde_plasma
	fi

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		if command -v "startkde" >/dev/null; then
			dbus-launch startkde &
		else
			dbus-launch startplasma-x11 &
		fi
	EndOfFile
	#plasma_session
	chmod +x ./xstartup
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null 2>/dev/null
	touch /tmp/.Tmoe-KDE-PLASMA5-Desktop-Detection-FILE
	STARTVNCANDSTOPVNC
}
####################
INSTALL-GNOME3-DESKTOP() {
	if [ "${LINUXDISTRO}" = "debian" ]; then
		#apt-mark hold gvfs
		apt update
		apt-mark hold udisks2
		echo '即将为您安装思源黑体(中文字体)、gnome-session、gnome-menus、gnome-tweak-tool、gnome-shell和tightvncserver等软件包。'
		dpkg --configure -a
		echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
		echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
		echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
		#aptitude install -y task-gnome-desktop || apt install -y task-gnome-desktop
		apt install --no-install-recommends xorg gnome-session gnome-menus gnome-tweak-tool gnome-shell || aptitude install -y gnome-core
		apt install -y fonts-noto-cjk
		apt install -y dbus-x11 xinit
		apt install -y tightvncserver
		apt purge -y ^libfprint
		apt clean

	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		#yum groupremove "GNOME Desktop Environment"
		#yum groupinstall "GNOME Desktop Environment"
		dnf groupinstall -y "GNOME" || yum groupinstall -y "GNOME"
		dnf install -y tigervnc-server google-noto-cjk-fonts || yum install -y tigervnc-server google-noto-cjk-fonts

	elif [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm gnome gnome-extra
		pacman -S --noconfirm tigervnc
		pacman -S --noconfirm noto-fonts-cjk
	elif [ "${LINUXDISTRO}" = "void" ]; then
		xbps-install -S -y gnome tigervnc

	elif [ "${LINUXDISTRO}" = "gentoo" ]; then
		GNOMEnoSystemd=$(eselect profile list | grep gnome | grep -v systemd | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2)
		eselect profile set ${GNOMEnoSystemd}
		#emerge -auvDN --with-bdeps=y @world
		dispatch-conf
		etc-update
		emerge -avk gnome-shell gdm gnome-terminal net-misc/tigervnc media-fonts/wqy-bitmapfont
	elif [ "${LINUXDISTRO}" = "suse" ]; then
		zypper in -y tigervnc-x11vnc noto-sans-sc-fonts patterns-gnome-gnome_x11
	fi

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		dbus-launch gnome-session &
	EndOfFile
	chmod +x ./xstartup
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null 2>/dev/null
	touch /tmp/.Tmoe-GNOME3-Desktop-Detection-FILE
	STARTVNCANDSTOPVNC
}
####################
INSTALL-cinnamon-DESKTOP() {
	if [ "${LINUXDISTRO}" = "debian" ]; then
		#apt-mark hold gvfs
		apt update
		apt-mark hold udisks2
		echo '即将为您安装思源黑体(中文字体)、cinnamon和tightvncserver等软件包。'
		dpkg --configure -a
		echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
		echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
		echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
		#task-cinnamon-desktop
		aptitude install -y cinnamon
		aptitude install -y cinnamon-desktop-environment
		apt install -y fonts-noto-cjk
		apt install -y dbus-x11
		apt install -y tightvncserver
		apt purge -y ^libfprint
		apt clean

	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		dnf groupinstall -y "Cinnamon Desktop" || yum groupinstall -y "Cinnamon Desktop"
		dnf install -y tigervnc-server google-noto-cjk-fonts || yum install -y tigervnc-server google-noto-cjk-fonts

	elif [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm sddm cinnamon xorg
		pacman -S --noconfirm tigervnc
		pacman -S --noconfirm noto-fonts-cjk
	elif [ "${LINUXDISTRO}" = "gentoo" ]; then
		dispatch-conf
		etc-update
		emerge -avk gnome-extra/cinnamon gnome-extra/cinnamon-desktop gnome-extra/cinnamon-translations net-misc/tigervnc media-fonts/wqy-bitmapfont
	elif [ "${LINUXDISTRO}" = "suse" ]; then
		zypper in -y tigervnc-x11vnc noto-sans-sc-fonts cinnamon cinnamon-control-center
	fi

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		dbus-launch cinnamon-launcher &
	EndOfFile
	chmod +x ./xstartup
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null 2>/dev/null
	touch /tmp/.Tmoe-cinnamon-Desktop-Detection-FILE
	STARTVNCANDSTOPVNC
}
####################
INSTALL-DEEPIN-DESKTOP() {

	if [ "${archtype}" != "i386" ] && [ "${archtype}" != "amd64" ]; then
		echo "非常抱歉，深度桌面不支持您当前的架构。"
		echo "建议您在换用x86_64或i386架构的设备后，再来尝试。"
		#echo "${YELLOW}按回车键返回。${RESET}"
		#echo "Press enter to return."
		#read
		#DEBIANMENU
		echo "${YELLOW}警告！deepin桌面可能无法正常运行${RESET}"
		echo 'Press Enter to continue，press Ctrl+C to cancel.'
		echo "${YELLOW}按回车键继续安装，按Ctrl+C取消${RESET}"
		read
	fi

	if [ "${LINUXDISTRO}" = "debian" ]; then
		if [ ! -e "/usr/bin/gpg" ]; then
			apt update
			apt install gpg -y
		fi
		#apt-mark hold gvfs
		if [ "${DEBIANDISTRO}" = "ubuntu" ]; then
			add-apt-repository ppa:leaeasy/dde
		else
			cd /etc/apt/
			if ! grep -q '^deb.*deepin' sources.list.d/deepin.list 2>/dev/null; then
				cat >/etc/apt/sources.list.d/deepin.list <<-'EOF'
					   #如需使用apt upgrade命令，请禁用deepin软件源,否则将有可能导致系统崩溃。
						deb [by-hash=force] https://mirrors.tuna.tsinghua.edu.cn/deepin unstable main contrib non-free
				EOF
			fi
		fi
		wget https://mirrors.tuna.tsinghua.edu.cn/deepin/project/deepin-keyring.gpg
		gpg --import deepin-keyring.gpg
		gpg --export --armor 209088E7 | apt-key add -
		apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 425956BB3E31DF51

		apt update
		echo '即将为您安装思源黑体(中文字体)、和tightvncserver等软件包。'
		dpkg --configure -a
		echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
		echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
		echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
		aptitude install -y dde
		sed -i 's/^deb/#&/g' /etc/apt/sources.list.d/deepin.list
		apt update
		apt install -y fonts-noto-cjk
		apt install -y dbus-x11
		apt install -y tightvncserver
		apt purge -y ^libfprint
		apt clean

	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		dnf install -y deepin-desktop || yum install -y deepin-desktop
		dnf install -y tigervnc-server google-noto-cjk-fonts || yum install -y tigervnc-server google-noto-cjk-fonts

	elif [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm deepin deepin-extra lightdm lightdm-deepin-greeter xorg
		#pacman -S --noconfirm deepin-kwin
		#pacman -S --noconfirm file-roller evince
		pacman -S --noconfirm tigervnc
		pacman -S --noconfirm noto-fonts-cjk
		rm -v ~/.pam_environment 2>/dev/null
	fi

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		dbus-launch startdde &
	EndOfFile
	chmod +x ./xstartup
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null 2>/dev/null
	touch /tmp/.Tmoe-DEEPIN-Desktop-Detection-FILE
	STARTVNCANDSTOPVNC
}

############################
REMOVEGUI() {
	echo '"xfce" "呜呜，(≧﹏ ≦)您真的要离开我么"  '
	echo '"lxde" "很庆幸能与阁下相遇（；´д｀）ゞ "  '
	echo '"mate" "喔...喔呜...我不舍得你走/(ㄒoㄒ)/~~"  '
	#新功能预告：即将适配非deb系linux的gui卸载功能
	echo "${YELLOW}按回车键确认卸载,按Ctrl+C取消${RESET} "
	echo 'Press enter to confirm ,press Ctrl + C to cancel'
	read
	if [ "${LINUXDISTRO}" = "debian" ]; then
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
	elif [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -Rsc xfce4 xfce4-goodies
		pacman -Rsc mate mate-extra
		pacman -Rsc lxde lxqt
		pacman -Rsc plasma-desktop
		pacman -Rsc gnome gnome-extra
		pacman -Rsc cinnamon
		pacman -Rsc deepin deepin-extra
	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		dnf groupremove -y xfce
		dnf groupremove -y mate-desktop
		dnf groupremove -y lxde-desktop
		dnf groupremove -y lxqt
		dnf groupremove -y "KDE" "GNOME" "Cinnamon Desktop"
		dnf remove -y deepin-desktop
	fi

	DEBIANMENU
}

REMOVEBROWSER() {
	if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno '火狐娘:“虽然知道总有离别时，但我没想到这一天竟然会这么早。虽然很不舍，但还是很感激您曾选择了我。希望我们下次还会再相遇，呜呜...(;´༎ຶД༎ຶ`)”chromium娘：“哼(￢︿̫̿￢☆)，负心人，走了之后就别回来了！o(TヘTo) 。”  ✨请做出您的选择！' 10 60); then
		echo '呜呜...我...我才...才不会为了这点小事而流泪呢！ヽ(*。>Д<)o゜'
		echo "${YELLOW}按回车键确认卸载firefox,按Ctrl+C取消${RESET} "
		echo 'Press enter to confirm uninstall firefox,press Ctrl + C to cancel'
		read
		apt purge -y firefox-esr firefox-esr-l10n-zh-cn
		apt purge -y firefox firefox-l10n-zh-cn
		apt purge -y firefox-locale-zh-hans
		apt autopurge
		dnf remove -y firefox 2>/dev/null
		pacman -Rsc firefox 2>/dev/null
		emerge -C firefox-bin firefox 2>/dev/null

	else
		echo '小声嘀咕：“妾身不在的时候，你一定要好好照顾好自己。” '
		echo "${YELLOW}按回车键确认卸载chromium,按Ctrl+C取消${RESET} "
		echo 'Press enter to confirm uninstall chromium,press Ctrl + C to cancel'
		read
		apt purge -y chromium chromium-l10n
		apt-mark unhold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg-extra
		apt purge -y chromium-browser chromium-browser-l10n
		apt autopurge
		dnf remove -y chromium 2>/dev/null
		pacman -Rsc chromium 2>/dev/null
		emerge -C chromium 2>/dev/null

	fi
	DEBIANMENU
}
#############################################
VSCODESERVER() {

	if [ ! -e "/tmp/sed-vscode.tmp" ]; then

		cat >"/tmp/sed-vscode.tmp" <<-'EOF'
			if [ -e "/tmp/startcode.tmp" ]; then
				echo "正在为您启动VSCode服务(器),请复制密码，并在浏览器的密码框中粘贴。"
				echo "The VSCode service(server) is starting, please copy the password and paste it in your browser."

				rm -f /tmp/startcode.tmp
				code-server &
				echo "已为您启动VS Code Server!"
				echo "VS Code Server has been started,enjoy it !"
				echo "您可以输pkill code-server来停止服务(器)。"
				echo 'You can type "pkill code-server" to stop vscode service(server).'
			fi
		EOF
	fi
	grep '/tmp/startcode.tmp' /root/.bashrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" /root/.bashrc
	grep '/tmp/startcode.tmp' /root/.zshrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" /root/.zshrc
	if [ ! -x "/usr/local/bin/code-server-data/code-server" ]; then
		chmod +x /usr/local/bin/code-server-data/code-server 2>/dev/null || echo -e "检测到您未安装vscode server\nDetected that you do not have vscode server installed."
	fi
	if [ ! -e "/usr/local/bin/code-server-data/code-server" ]; then

		cd /tmp
		if [ -d ".VSCODESERVERTMPFILE" ]; then
			rm -rf .VSCODESERVERTMPFILE
		fi

		git clone -b aarch64 --depth=1 https://gitee.com/mo2/vscode-server.git .VSCODESERVERTMPFILE
		cd .VSCODESERVERTMPFILE
		tar -PpJxvf code.tar.xz
		cd ${cur}
		rm -rf /tmp/.VSCODESERVERTMPFILE
		echo "即将为您启动VSCode服务,请复制密码，并在浏览器中粘贴。"
		echo "The VSCode server is starting, please copy the password and paste it in your browser."
		echo "您之后可以输code-server来启动VSCode Server."
		echo 'You can type "code-server" to start VSCodeServer.'
		/usr/local/bin/code-server-data/code-server
	else
		/usr/local/bin/code-server-data/code-server

	fi

}
##############################################################
INSTALLsynaptic() {
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Install安装" --no-button "Remove移除" --yesno "新立德是一款使用apt的图形化软件包管理工具，您也可以把它理解为软件商店。Synaptic is a graphical package management program for apt. It provides the same features as the apt-get command line utility with a GUI front-end based on Gtk+.它提供与apt-get命令行相同的功能，并带有基于Gtk+的GUI前端。功能：1.安装、删除、升级和降级单个或多个软件包。 2.升级整个系统。 3.管理软件源列表。  4.自定义过滤器选择(搜索)软件包。 5.按名称、状态、大小或版本对软件包进行排序。 6.浏览与所选软件包相关的所有可用在线文档。♪(^∇^*) " 19 50); then
		apt update
		apt install -y synaptic
		apt install -y gdebi
		sed -i 's/synaptic-pkexec/synaptic/g' /usr/share/applications/synaptic.desktop
		echo "synaptic和gdebi安装完成，建议您将deb文件的默认打开程序修改为gdebi"
		echo "按回车键返回"
		echo "${YELLOW}Press enter to return! ${RESET}"
		read
	else

		echo "${YELLOW}您真的要离开我么？哦呜。。。${RESET}"
		echo "Do you really want to remove synaptic?"
		echo "按回车键继续，按Ctrl+C取消。"
		echo "${YELLOW}Press enter to continue! ${RESET}"
		read
		apt purge -y synaptic
		apt purge -y gdebi
	fi
	DEBIANMENU

}
##########################################
CHINESEMANPAGES() {

	echo '即将为您安装 debian-reference-zh-cn、manpages、manpages-zh和man-db'
	apt update
	apt install -y debian-reference-zh-cn manpages manpages-zh man-db
	if [ ! -e "${HOME}/文档/debian-handbook/usr/share/doc/debian-handbook/html" ]; then
		mkdir -p ${HOME}/文档/debian-handbook
		cd ${HOME}/文档/debian-handbook
		wget -O 'debian-handbook.deb' 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/d/debian-handbook/debian-handbook_8.20180830_all.deb'
		busybox ar xv 'debian-handbook.deb'
		tar -Jxvf data.tar.xz ./usr/share/doc/debian-handbook/html
		ls | grep -v usr | xargs rm -rf
		ln -sf ./usr/share/doc/debian-handbook/html/zh-CN/index.html ./
	fi
	echo "man一款帮助手册软件，它可以帮助您了解关于命令的详细用法。"
	echo "man a help manual software, which can help you understand the detailed usage of the command."
	echo "您可以输${YELLOW}man 软件或命令名称${RESET}来获取帮助信息，例如${YELLOW}man bash${RESET}或${YELLOW}man zsh${RESET}"
	echo "如需卸载，请手动输apt purge -y debian-reference-zh-cn manpages manpages-zh man-db "
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read

	DEBIANMENU
}
########################################################################
CONFIGTHEMES() {
	INSTALLTHEME=$(whiptail --title "桌面环境主题" --menu \
		"您想要下载哪个主题？按方向键选择！下载完成后，您需要手动修改外观设置中的样式和图标。注：您需修改窗口管理器样式才能解决标题栏丢失的问题。\n Which theme do you want to download? " 15 60 5 \
		"1" "ukui：国产优麒麟ukui桌面主题" \
		"2" "win10：kali卧底模式主题" \
		"3" "MacOS：Mojave" \
		"4" "UOS：国产统一操作系统图标包" \
		"5" "breeze：plasma桌面微风gtk+版主题" \
		"6" "Kali：kali-Flat-Remix-Blue主题" \
		"0" "我一个都不要 =￣ω￣=" \
		3>&1 1>&2 2>&3)

	if [ "$INSTALLTHEME" == '0' ]; then
		DEBIANMENU
	fi

	if [ "$INSTALLTHEME" == '1' ]; then
		apt update
		apt install ukui-themes

		if [ ! -e '/usr/share/icons/ukui-icon-theme-default' ] && [ ! -e '/usr/share/icons/ukui-icon-theme' ]; then
			mkdir -p /tmp/.ukui-gtk-themes
			cd /tmp/.ukui-gtk-themes
			UKUITHEME="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/u/ukui-themes/' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			wget -O 'ukui-themes.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/u/ukui-themes/${UKUITHEME}"
			busybox ar xv 'ukui-themes.deb'
			cd /
			tar -Jxvf /tmp/.ukui-gtk-themes/data.tar.xz ./usr
			#if which update-icon-caches >/dev/null 2>&1; then
			update-icon-caches /usr/share/icons/ukui-icon-theme-basic /usr/share/icons/ukui-icon-theme-classical /usr/share/icons/ukui-icon-theme-default
			update-icon-caches /usr/share/icons/ukui-icon-theme
			#fi
			rm -rf /tmp/.ukui-gtk-themes
			#apt install -y ./ukui-themes.deb
			#rm -f ukui-themes.deb
			apt install -y ukui-greeter
		else
			echo '请前往外观设置手动修改图标'
		fi
		#gtk-update-icon-cache /usr/share/icons/ukui-icon-theme/ 2>/dev/null
		echo "安装完成，如需卸载，请手动输apt purge -y ukui-themes"
	fi

	if [ "$INSTALLTHEME" == '2' ]; then
		Installkaliundercover
	fi

	if [ "$INSTALLTHEME" == '3' ]; then
		if [ -d "/usr/share/themes/Mojave-dark" ]; then
			echo "检测到主题已下载，是否继续。"
			echo 'Press Enter to continue.'
			echo "${YELLOW}按回车键继续。${RESET}"
			read
		fi

		if [ -d "/tmp/McMojave" ]; then
			rm -rf /tmp/McMojave
		fi

		git clone -b McMojave --depth=1 https://gitee.com/mo2/xfce-themes.git /tmp/McMojave
		cd /tmp/McMojave
		cat url.txt
		tar -Jxvf 01-Mojave-dark.tar.xz -C /usr/share/themes 2>/dev/null
		tar -Jxvf 01-McMojave-circle.tar.xz -C /usr/share/icons 2>/dev/null
		rm -rf /tmp/McMojave
		echo "Download completed.如需删除，请手动输rm -rf /usr/share/themes/Mojave-dark /usr/share/icons/McMojave-circle-dark /usr/share/icons/McMojave-circle"
	fi
	##########################
	if [ "$INSTALLTHEME" == '4' ]; then
		if [ -d "/usr/share/icons/Uos" ]; then
			echo "检测到Uos图标包已下载，是否继续。"
			echo 'Press Enter to continue.'
			echo "${YELLOW}按回车键继续。${RESET}"
			read
		fi

		if [ -d "/tmp/UosICONS" ]; then
			rm -rf /tmp/UosICONS
		fi

		git clone -b Uos --depth=1 https://gitee.com/mo2/xfce-themes.git /tmp/UosICONS
		cd /tmp/UosICONS
		cat url.txt
		tar -Jxvf Uos.tar.xz -C /usr/share/icons 2>/dev/null
		rm -rf /tmp/UosICONS
		apt update
		apt install -y deepin-icon-theme
		echo "Download completed.如需删除，请手动输rm -rf /usr/share/icons/Uos ; apt purge -y deepin-icon-theme"
	fi
	###########################################

	if [ "$INSTALLTHEME" == '5' ]; then
		apt update
		apt install -y breeze-cursor-theme breeze-gtk-theme
		apt install -y breeze-icon-theme
		apt install -y xfwm4-theme-breeze
		echo "Install completed.如需卸载，请手动输apt purge -y breeze-cursor-theme breeze-gtk-theme breeze-icon-theme xfwm4-theme-breeze"
	fi
	######################################
	if [ "$INSTALLTHEME" == '6' ]; then
		if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
			mkdir -p /tmp/.kali-themes-common
			cd /tmp/.kali-themes-common
			KaliTHEMElatestLINK="$(wget -O- 'https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes/' | grep kali-themes-common | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			wget -O 'kali-themes-common.deb' "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes/${KaliTHEMElatestLINK}"
			busybox ar xv 'kali-themes-common.deb'
			update-icon-caches /usr/share/icons/Flat-Remix-Blue-Dark /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/desktop-base
			cd /
			tar -Jxvf /tmp/.kali-themes-common/data.tar.xz ./usr
			rm -rf /tmp/.kali-themes-common
		fi
		echo "Download completed.如需删除，请手动输rm -rf /usr/share/desktop-base/kali-theme /usr/share/icons/desktop-base /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/Flat-Remix-Blue-Dark"
	fi
	##############################
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read

	DEBIANMENU

}
################################
Installkaliundercover() {

	if [ -e "/usr/share/icons/Windows-10-Icons" ]; then
		echo "检测到您已安装win10主题"
	else
		#if [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
		if grep -q 'kali' '/etc/apt/sources.list'; then
			apt update
			apt install -y kali-undercover
		else
			mkdir -p /tmp/.kali-undercover-win10-theme
			cd /tmp/.kali-undercover-win10-theme
			UNDERCOVERlatestLINK="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover/' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			wget -O kali-undercover.deb "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover/${UNDERCOVERlatestLINK}"
			apt install -y ./kali-undercover.deb
			if [ ! -e "/usr/share/icons/Windows-10-Icons" ]; then
				busybox ar xv kali-undercover.deb
				cd /
				tar -Jxvf /tmp/.kali-undercover-win10-theme/data.tar.xz ./usr
				#if which update-icon-caches >/dev/null 2>&1; then
				update-icon-caches /usr/share/icons/Windows-10-Icons
				#fi
			fi
			rm -rf /tmp/.kali-undercover-win10-theme
			#rm -f ./kali-undercover.deb
		fi
	fi
	echo "安装完成，如需卸载，请手动输apt purge -y kali-undercover"
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read

	DEBIANMENU

}
#####################################################
INSTALLORREMOVEVSCODE() {
	if [ -e "/usr/local/bin/code-server-data/code-server" ]; then
		VSCODEINSTALLSTATUS="检测到您已安装vscode."
		VSCODESTART='Start启动'
	else
		VSCODEINSTALLSTATUS="检测到您未安装vscode."
		VSCODESTART='Install安装'
	fi

	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "${VSCODESTART}" --no-button "Remove移除" --yesno "${VSCODEINSTALLSTATUS} \nVisual Studio Code is a lightweight but powerful source code editor which runs on your desktop and is available for Windows, macOS and Linux. It comes with built-in support for JavaScript, TypeScript and Node.js and has a rich ecosystem of extensions for other languages (such as C++, C#, Java, Python, PHP, Go) and runtimes (such as .NET and Unity).  ♪(^∇^*) " 16 50); then
		VSCODESERVER
	else
		echo "按回车键确认移除，按Ctrl+C取消。"
		echo "${YELLOW}Press enter to remove VSCode Server. ${RESET}"
		read
		rm -rvf /usr/local/bin/code-server-data/ /usr/local/bin/code-server /tmp/sed-vscode.tmp
		echo "${YELLOW}移除成功，按回车键返回。${RESET}"
		echo "Remove successfully.Press enter to return."
		read
		DEBIANMENU
	fi
}
############################################
MODIFYTOKALISourcesList() {
	if [ "${LINUXDISTRO}" != "debian" ]; then
		echo "${YELLOW}非常抱歉，检测到您使用的不是deb系linux，按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		DEBIANMENU
	fi

	if [ "${DEBIANDISTRO}" = "ubuntu" ]; then
		echo "${YELLOW}非常抱歉，暂不支持Ubuntu，按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		DEBIANMENU
	fi

	if ! grep -q "^deb.*kali" /etc/apt/sources.list; then
		echo "检测到您当前为debian源，是否修改为kali源？"
		echo "Detected that your current software sources list is debian, do you need to modify it to kali source?"
		echo 'Press Enter to confirm.'
		echo "${YELLOW}按回车键确认。${RESET}"
		read
		KALISOURCESLIST
	else
		echo "检测到您当前为kali源，是否修改为debian源？"
		echo "Detected that your current software sources list is kali, do you need to modify it to debian source?"
		echo 'Press Enter to confirm.'
		echo "${YELLOW}按回车键确认。${RESET}"
		read
		DEBIANSOURCESLIST
	fi
}
################################
KALISOURCESLIST() {
	if [ ! -e "/usr/bin/gpg" ]; then
		apt update
		apt install gpg -y
	fi
	#添加公钥
	apt-key adv --keyserver keyserver.ubuntu.com --recv ED444FF07D8D0BF6
	cd /etc/apt/
	cp -f sources.list sources.list.bak

	sed -i 's/^deb/#&/g' /etc/apt/sources.list
	cat >>/etc/apt/sources.list <<-'EOF'
		deb https://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
	EOF
	apt update
	apt list --upgradable
	apt dist-upgrade -y
	apt search kali-linux
	echo 'You have successfully replaced your debian source with a kali source.'
	echo "${YELLOW}按回车键返回。${RESET}"
	echo "Press enter to return."
	read
	DEBIANMENU
}
#######################
DEBIANSOURCESLIST() {
	sed -i 's/^deb/#&/g' /etc/apt/sources.list
	cat >>/etc/apt/sources.list <<-'EOF'
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
	EOF
	apt update
	apt list --upgradable
	echo '您已换回debian源'
	apt dist-upgrade -y
	echo "${YELLOW}按回车键返回。${RESET}"
	echo "Press enter to return."
	read
	DEBIANMENU
}
############################################
OTHERSOFTWARE() {
	SOFTWARE=$(
		whiptail --title "其它软件" --menu \
			"您想要安装哪个软件？\n Which software do you want to install? 您需要使用方向键或pgdown来翻页。 部分软件需要在安装gui后才能使用！" 17 60 6 \
			"1" "MPV：开源、跨平台的音视频播放器" \
			"2" "LinuxQQ：在线聊天软件" \
			"3" "韦诺之战：奇幻背景的回合制策略战棋游戏" \
			"4" "斯隆与马克贝尔的谜之物语：nds解谜游戏" \
			"5" "大灾变-劫后余生：末日幻想背景的探索生存游戏" \
			"6" "Synaptic：新立得软件包管理器/软件商店" \
			"7" "GIMP：GNU 图像处理程序" \
			"8" "LibreOffice:开源、自由的办公文档软件" \
			"9" "Parole：xfce默认媒体播放器，风格简洁" \
			"10" "百度网盘(x86_64):提供文件的网络备份、同步和分享服务" \
			"11" "网易云音乐(x86_64):专注于发现与分享的音乐产品" \
			"12" "ADB:Android Debug Bridge" \
			"13" "BleachBit:垃圾清理" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	#(已移除)"12" "Tasksel:轻松,快速地安装组软件" \
	##############################
	if [ "${SOFTWARE}" == '0' ]; then

		DEBIANMENU
	fi
	##############################
	if [ "${SOFTWARE}" == '1' ]; then
		if [ -e "/usr/bin/mpv" ]; then
			echo "检测到您已安装mpv,按回车键重新安装,按Ctrl+C取消"
			echo "Press enter to continue."
			read
		fi

		if [ "${LINUXDISTRO}" = "debian" ]; then
			apt update
			apt install -y mpv
		elif [ "${LINUXDISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm mpv
		elif [ "${LINUXDISTRO}" = "redhat" ]; then
			dnf install -y kmplayer || yum install -y kmplayer
		fi
		echo "安装完成，如需卸载，请手动输apt purge -y mpv"
	fi
	##############################
	if [ "${SOFTWARE}" == '2' ]; then
		cd /tmp
		if [ -e "/usr/share/tencent-qq" ]; then
			echo "检测到您已安装linuxQQ,按回车键重新安装,按Ctrl+C取消"
			echo "Press enter to continue."
			read
		fi

		if [ "${archtype}" = "arm64" ]; then
			if [ "${LINUXDISTRO}" = "debian" ]; then
				wget -O LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb"
				apt install -y ./LINUXQQ.deb
			else
				wget -O LINUXQQ.sh http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.sh
				chmod +x LINUXQQ.sh
				sudo ./LINUXQQ.sh
				#即使是root用户也需要加sudo
			fi
		elif [ "${archtype}" = "amd64" ]; then
			if [ "${LINUXDISTRO}" = "debian" ]; then
				wget -O LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_amd64.deb"
				apt install -y ./LINUXQQ.deb
				#http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb
			else
				wget -O LINUXQQ.sh "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_x86_64.sh"
				chmod +x LINUXQQ.sh
				sudo ./LINUXQQ.sh
			fi
		else
			echo "暂不支持您的架构"
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			OTHERSOFTWARE
		fi
		echo "若安装失败，则请前往官网手动下载安装。"
		echo "url: https://im.qq.com/linuxqq/download.html"
		rm -fv ./LINUXQQ.deb ./LINUXQQ.sh 2>/dev/null
		echo "安装完成，如需卸载，请手动输apt purge -y linuxqq"
	fi
	##############################

	if [ "${SOFTWARE}" == '3' ]; then
		apt update
		apt install -y wesnoth
		echo "安装完成，如需卸载，请手动输apt purge -y wesnoth"
	fi
	##############################
	if [ "${SOFTWARE}" == '4' ]; then
		if [ ! -e "/usr/games/desmume" ]; then
			apt update
			apt install -y desmume unzip p7zip-full
		fi
		cd ~
		if [ -e "斯隆与马克贝尔的谜之物语/3782.nds" ]; then
			echo "检测到您已安装。"

		else

			mkdir -p '斯隆与马克贝尔的谜之物语'
			cd '斯隆与马克贝尔的谜之物语'
			wget -O slymkbr1.zip http://k73dx1.zxclqw.com/slymkbr1.zip
			wget -O mayomonogatari2.zip http://k73dx1.zxclqw.com/mayomonogatari2.zip
			7za x slymkbr1.zip
			7za x mayomonogatari2.zip
			mv -f 斯隆与马克贝尔的谜之物语k73/* ./
			mv -f 迷之物语/* ./
			rm -f *url *txt
			rm -rf 迷之物语 斯隆与马克贝尔的谜之物语k73
			rm -f slymkbr1.zip* mayomonogatari2.zip*
		fi
		echo "安装完成，您需要手动进入'/root/斯隆与马克贝尔的谜之物语'目录加载游戏"
		echo "如需卸载，请手动输apt purge -y desmume ; rm -rf ~/斯隆与马克贝尔的谜之物语"
		echo 'Press enter to start the nds emulator.'
		echo "${YELLOW}按回车键启动游戏。${RESET}"
		read
		desmume "${HOME}/斯隆与马克贝尔的谜之物语/3782.nds" 2>/dev/null &
	fi
	##########################
	if [ "${SOFTWARE}" == '5' ]; then

		if [ ! -e "/usr/games/cataclysm-tiles" ]; then
			apt update
			apt install -y cataclysm-dda-curses cataclysm-dda-sdl
		fi

		echo "安装完成，如需卸载，请手动输apt purge -y ^cataclysm-dda"
		echo "在终端环境下，您需要缩小显示比例，并输入cataclysm来启动字符版游戏。"
		echo "在gui下，您需要输cataclysm-tiles来启动画面更为华丽的图形界面版游戏。"
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键启动。${RESET}"
		read
		cataclysm
	fi
	##############################
	if [ "${SOFTWARE}" == '6' ]; then
		INSTALLsynaptic
	fi
	###############################
	if [ "${SOFTWARE}" == '7' ]; then
		apt update
		apt install -y gimp
		gimp &
		echo "安装完成，如需卸载，请手动输apt purge -y gimp"
	fi
	##########################
	if [ "${SOFTWARE}" == '8' ]; then
		#ps -e >/dev/null || echo "/proc分区未挂载，请勿安装libreoffice,赋予proot容器真实root权限可解决相关问题，但强烈不推荐！"
		ps -e >/dev/null || echo "检测到/proc分区未挂载"
		echo 'Press Enter to confirm，press Ctrl+C to cancel.'
		echo "${YELLOW}按回车键确认安装,按Ctrl+C取消。${RESET}"
		read
		apt update
		apt install --no-install-recommends -y libreoffice-l10n-zh-cn
		apt install -y libreoffice-l10n-zh-cn libreoffice-gtk3
		if [ ! -e "/tmp/.Chroot-Container-Detection-File" ] && [ "${archtype}" != "amd64" ] && [ "${archtype}" != "i386" ]; then
			mkdir -p /prod/version
			cd /usr/lib/libreoffice/program
			rm -f oosplash
			wget -qO 'oosplash' https://gitee.com/mo2/patch/raw/libreoffice/oosplash
			chmod +x oosplash
		fi
		echo "安装完成，如需卸载，请手动输apt purge -y ^libreoffice"
	fi

	##############################
	if [ "${SOFTWARE}" == '9' ]; then
		apt update
		apt install -y parole
		echo "安装完成，如需卸载，请手动输apt purge -y parole"
	fi
	##########################
	if [ "${SOFTWARE}" == '10' ]; then
		if [ "${archtype}" != "amd64" ] && [ "${archtype}" != "i386" ]; then
			echo "暂不支持您的架构"
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			OTHERSOFTWARE
		fi
		if [ -e "/usr/share/applications/baidunetdisk.desktop" ]; then
			echo "检测到您已安装baidunetdisk,按回车键重新安装,按Ctrl+C取消"
			echo "Press enter to continue."
			read
		fi
		cd /tmp
		if [ "${LINUXDISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm baidunetdisk-bin
		elif [ "${LINUXDISTRO}" = "redhat" ]; then
			wget -O 'baidunetdisk.rpm' "http://wppkg.baidupcs.com/issue/netdisk/LinuxGuanjia/3.0.1/baidunetdisk_linux_3.0.1.2.rpm"
			rpm -ivh 'baidunetdisk.rpm'
		else
			wget -O baidunetdisk.deb "http://wppkg.baidupcs.com/issue/netdisk/LinuxGuanjia/3.0.1/baidunetdisk_linux_3.0.1.2.deb"
			apt install -y ./baidunetdisk.deb
			echo "安装完成，如需卸载，请手动输apt purge -y baidunetdisk"
			rm -fv ./baidunetdisk.deb
		fi
	fi
	###########################
	if [ "${SOFTWARE}" == '11' ]; then
		163NETEASEMUSIC
	fi
	###########################
	if [ "${SOFTWARE}" == '12' ]; then

		if [ ! -e /usr/bin/adb ]; then
			if [ "${LINUXDISTRO}" = "debian" ]; then
				apt update
				apt install -y adb

			elif [ "${LINUXDISTRO}" = "arch" ]; then
				pacman -Syu --noconfirm android-tools

			elif [ "${LINUXDISTRO}" = "redhat" ]; then
				dnf install -y android-tools || yum install -y android-tools
			fi
		fi

		if [ -e /usr/bin/adb ]; then
			adb --help
			echo "adb安装完成"
			echo "如需卸载，请手动输apt purge -y adb"
			echo "正在重启进程,您也可以手动输adb devices来获取设备列表"
			adb kill-server
			adb devices -l
			echo "即将为您自动进入adb shell模式，您也可以手动输adb shell来进入该模式"
			adb shell
		fi
	fi

	###########################
	if [ "${SOFTWARE}" == '13' ]; then

		if [ ! -e /usr/bin/bleachbit ]; then
			if [ "${LINUXDISTRO}" = "debian" ]; then
				apt update
				apt install -y bleachbit

			elif [ "${LINUXDISTRO}" = "arch" ]; then
				pacman -Syu --noconfirm bleachbit

			elif [ "${LINUXDISTRO}" = "redhat" ]; then
				dnf install -y bleachbit || yum install -y bleachbit
			fi
		fi

		if [ -e /usr/bin/bleachbit ]; then
			bleachbit --help
			echo "bleachbit安装完成，如需卸载，请手动输apt purge -y bleachbit"
		fi
	fi
	############################################
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	DEBIANMENU
}
######################
163NETEASEMUSIC() {
	if [ "${archtype}" != "amd64" ] && [ "${archtype}" != "i386" ]; then
		echo "暂不支持您的架构"
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		OTHERSOFTWARE
	fi
	if [ -e "/usr/share/applications/netease-cloud-music.desktop" ]; then
		echo "检测到您已安装netease-cloud-music,按回车键重新安装,按Ctrl+C取消"
		echo "Press enter to continue."
		read
	fi
	cd /tmp
	if [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm netease-cloud-music
	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		wget https://dl.senorsen.com/pub/package/linux/add_repo.sh -qO - | sudo sh
		sudo dnf install http://dl-http.senorsen.com/pub/package/linux/rpm/senorsen-repo-0.0.1-1.noarch.rpm
		sudo dnf install -y netease-cloud-music
	else
		if [ "${archtype}" = "amd64" ]; then
			wget -O netease-cloud-music.deb "http://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb"
		else
			wget -O netease-cloud-music.deb "http://mirrors.ustc.edu.cn/debiancn/pool/main/n/netease-cloud-music/netease-cloud-music_1.0.0%2Brepack.debiancn-1_i386.deb"
		fi
		apt install -y ./netease-cloud-music.deb
		echo "安装完成，如需卸载，请手动输apt purge -y netease-cloud-music"
		rm -fv ./netease-cloud-music.deb
	fi
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	DEBIANMENU

}

####################################
INSTALLXFCE4DESKTOP() {
	if [ "${LINUXDISTRO}" = "debian" ]; then
		#apt-mark hold gvfs
		apt update
		apt-mark hold udisks2
		echo '即将为您安装思源黑体(中文字体)、xfce4、xfce4-terminal、xfce4-goodies和tightvncserver等软件包。'
		dpkg --configure -a
		echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
		echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
		echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections

		apt install -y fonts-noto-cjk xfce4 xfce4-terminal xfce4-goodies
		apt install -y dbus-x11
		apt install -y tightvncserver
		apt purge -y ^libfprint
		apt install -y xcursor-themes
		if [ "${DEBIANDISTRO}" = "kali" ]; then
			apt install -y kali-menu
			apt install -y kali-undercover
			apt install -y zenmap
			apt install -y kali-themes-common
			if [ "${archtype}" = "arm64" ] || [ "${archtype}" = "armhf" ]; then
				apt install -y kali-linux-arm
			fi
			apt install -y chromium-l10n
			sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
			grep 'chromium' /etc/profile || sed -i '$ a\alias chromium="chromium --no-sandbox"' /etc/profile
			apt search kali-linux
		fi
		apt clean
	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		dnf groupinstall -y xfce || yum groupinstall -y xfce
		dnf install -y tigervnc-server google-noto-cjk-fonts || yum install -y tigervnc-server google-noto-cjk-fonts
		rm -rf /etc/xdg/autostart/xfce-polkit.desktop
	elif [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm xfce4 xfce4-goodies
		pacman -S --noconfirm tigervnc
		pacman -S --noconfirm noto-fonts-cjk
	elif [ "${LINUXDISTRO}" = "void" ]; then
		xbps-install -S -y xfce4 tigervnc
	elif [ "${LINUXDISTRO}" = "gentoo" ]; then
		dispatch-conf
		etc-update
		emerge -avk xfce4-meta x11-terms/xfce4-terminal net-misc/tigervnc media-fonts/wqy-bitmapfont
	elif [ "${LINUXDISTRO}" = "suse" ]; then
		zypper in -y tigervnc-x11vnc noto-sans-sc-fonts patterns-xfce-xfce xfce4-terminal
	fi

	if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
		mkdir -p /tmp/.kali-themes-common
		cd /tmp/.kali-themes-common
		#rm -f ./kali-themes-common.deb 2>/dev/null
		KaliTHEMElatestLINK="$(wget -O- 'https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes/' | grep kali-themes-common | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		wget -O 'kali-themes-common.deb' "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes/${KaliTHEMElatestLINK}"
		busybox ar xv 'kali-themes-common.deb'
		update-icon-caches /usr/share/icons/Flat-Remix-Blue-Dark /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/desktop-base
		#tar -Jxvf data.tar.xz -C /
		cd /
		tar -Jxvf /tmp/.kali-themes-common/data.tar.xz ./usr
		rm -rf /tmp/.kali-themes-common
	#apt install -y ./kali-themes-common.deb
	#rm -f ./kali-themes-common.deb
	fi
	cd /usr/share/xfce4/terminal
	echo "正在配置xfce4终端配色..."
	wget -qO "colorschemes.tar.xz" 'https://gitee.com/mo2/xfce-themes/raw/terminal/colorschemes.tar.xz'
	tar -Jxvf "colorschemes.tar.xz"

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		dbus-launch startxfce4 &
	EndOfFile
	#dbus-launch startxfce4 &
	chmod +x ./xstartup
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null 2>/dev/null
	#touch /tmp/.Tmoe-XFCE4-Desktop-Detection-FILE
	STARTVNCANDSTOPVNC
}

#############################
MODIFYREMOTEDESKTOP() {
	REMOTEDESKTOP=$(whiptail --title "远程桌面" --menu \
		"您想要修改哪个远程桌面的配置？\nWhich remote desktop configuration do you want to modify?" 15 60 4 \
		"1" "VNC" \
		"2" "XSDL" \
		"3" "RDP" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${REMOTEDESKTOP}" == '0' ]; then
		DEBIANMENU
	fi
	##########################
	if [ "${REMOTEDESKTOP}" == '1' ]; then
		MODIFYVNCCONF
	fi
	##########################
	if [ "${REMOTEDESKTOP}" == '2' ]; then
		MODIFYXSDLCONF
	fi
	##########################
	if [ "${REMOTEDESKTOP}" == '3' ]; then
		MODIFYXRDPCONF
	fi

}
#################################################
MODIFYXRDPCONF() {
	if [ ! -e "/usr/sbin/xrdp" ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			apt update
			apt install -y xrdp
		elif [ "${LINUXDISTRO}" = "alpine" ]; then
			apk update
			apk add xrdp

		elif [ "${LINUXDISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm xrdp

		elif [ "${LINUXDISTRO}" = "redhat" ]; then
			dnf install -y xrdp || yum install -y xrdp

		elif [ "${LINUXDISTRO}" = "openwrt" ]; then
			#opkg update
			opkg install xrdp

		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			emerge -av layman
			layman -a bleeding-edge
			layman -S
			#ACCEPT_KEYWORDS="~amd64" USE="server" emerge -a xrdp
			emerge -av xrdp
		fi

		if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
			echo '检测到您使用的是WSL,为防止与windows自带的远程桌面的端口冲突，建议您将默认的3389端口修改为其它'
		fi
	fi
	if [ ! -e "/etc/polkit-1/localauthority.conf.d/02-allow-colord.conf" ]; then
		mkdir -p /etc/polkit-1/localauthority.conf.d
		cat >/etc/polkit-1/localauthority.conf.d/02-allow-colord.conf <<-'EndOfFile'
			polkit.addRule(function(action, subject) {
			if ((action.id == “org.freedesktop.color-manager.create-device” || action.id == “org.freedesktop.color-manager.create-profile” || action.id == “org.freedesktop.color-manager.delete-device” || action.id == “org.freedesktop.color-manager.delete-profile” || action.id == “org.freedesktop.color-manager.modify-device” || action.id == “org.freedesktop.color-manager.modify-profile”) && subject.isInGroup(“{group}”))
			{
			return polkit.Result.YES;
			}
			});
		EndOfFile

	fi

	service xrdp restart || systemctl restart xrdp
	if [ -e /usr/bin/ufw ]; then
		ufw allow 3389
	fi
	if [ -e "/usr/bin/xfce4-session" ]; then
		if [ ! -e " ~/.xsession" ]; then
			echo 'xfce4-session' >~/.xsession
			touch ~/.session
			sed -i 's:exec /bin/sh /etc/X11/Xsession:exec /bin/sh xfce4-session /etc/X11/Xsession:g' /etc/xrdp/startwm.sh
		fi
	fi

	if ! grep -q 'PULSE_SERVER' /etc/xrdp/startwm.sh; then
		sed -i '/test -x \/etc\/X11/i\#export PULSE_SERVER=127.0.0.1' /etc/xrdp/startwm.sh
	fi

	service xrdp status || systemctl status xrdp
	echo "如需修改启动脚本，请输nano /etc/xrdp/startwm.sh"
	echo "如需修改配置文件，请输nano /etc/xrdp/xrdp.ini"
	echo "已经为您启动xrdp服务，默认端口为3389"
	echo "您当前的IP地址为"
	ip -4 -br -c a | cut -d '/' -f 1
	echo "如需停止xrdp服务，请输service xrdp stop或systemctl stop xrdp"
	echo "如需修改当前用户密码，请输passwd"
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		echo '检测到您使用的是WSL，正在为您打开音频服务'
		export PULSE_SERVER=tcp:127.0.0.1
		cd "/mnt/c/Users/Public/Downloads/pulseaudio/bin"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat" 2>/dev/null
		echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
	fi
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	DEBIANMENU

}
############################
INSTALLMATEDESKTOP() {
	if [ "${LINUXDISTRO}" = "debian" ]; then
		apt-mark hold gvfs
		apt update
		apt install -y udisks2 2>/dev/null
		if [ ! -e "/tmp/.Chroot-Container-Detection-File" ] && [ "${archtype}" != "amd64" ] && [ "${archtype}" != "i386" ]; then
			echo "" >/var/lib/dpkg/info/udisks2.postinst
		fi
		apt-mark hold udisks2
		echo '即将为您安装思源黑体(中文字体)、tightvncserver、mate-desktop-environment和mate-terminal等软件包'
		dpkg --configure -a
		aptitude install -y mate-desktop-environment mate-terminal 2>/dev/null || apt install -y mate-desktop-environment-core mate-terminal
		apt autopurge -y ^libfprint
		apt install -y fonts-noto-cjk tightvncserver
		apt install -y dbus-x11
		apt clean
	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		dnf groupinstall -y mate-desktop || yum groupinstall -y mate-desktop
		dnf install -y tigervnc-server google-noto-cjk-fonts || yum install -y tigervnc-server google-noto-cjk-fonts
	elif [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm mate mate-extra
		pacman -S --noconfirm tigervnc
		pacman -S --noconfirm noto-fonts-cjk
	elif [ "${LINUXDISTRO}" = "void" ]; then
		xbps-install -S -y mate tigervnc
	elif [ "${LINUXDISTRO}" = "gentoo" ]; then
		dispatch-conf
		etc-update
		emerge -avk mate-base/mate-desktop mate-base/mate x11-base/xorg-x11 mate-base/mate-panel net-misc/tigervnc media-fonts/wqy-bitmapfont
	elif [ "${LINUXDISTRO}" = "suse" ]; then
		zypper in -y tigervnc-x11vnc noto-sans-sc-fonts patterns-mate-mate
	fi
	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		dbus-launch mate-session &
	EndOfFile
	chmod +x ./xstartup
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null
	touch /tmp/.Tmoe-MATE-Desktop-Detection-FILE
	STARTVNCANDSTOPVNC

}
#################################
INSTALLLXDEDESKTOP() {
	if [ "${LINUXDISTRO}" = "debian" ]; then
		apt update
		apt-mark hold udisks2
		echo '即将为您安装思源黑体(中文字体)、lxde-core、lxterminal、tightvncserver。'
		dpkg --configure -a
		echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
		echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
		echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
		apt install -y fonts-noto-cjk lxde-core lxterminal tightvncserver
		apt install -y dbus-x11
		apt clean
	elif [ "${LINUXDISTRO}" = "redhat" ]; then
		dnf groupinstall -y lxde-desktop || yum groupinstall -y lxde-desktop
		dnf install -y tigervnc-server google-noto-cjk-fonts || yum install -y tigervnc-server google-noto-cjk-fonts
	elif [ "${LINUXDISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm lxde
		pacman -S --noconfirm tigervnc
		pacman -S --noconfirm noto-fonts-cjk
	elif [ "${LINUXDISTRO}" = "void" ]; then
		xbps-install -S -y lxde tigervnc
	elif [ "${LINUXDISTRO}" = "gentoo" ]; then
		dispatch-conf
		etc-update
		emerge -avk lxde-base/lxde-meta net-misc/tigervnc media-fonts/wqy-bitmapfont
	elif [ "${LINUXDISTRO}" = "suse" ]; then
		zypper in -y tigervnc-x11vnc noto-sans-sc-fonts patterns-lxde-lxde
	fi

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		dbus-launch startlxde &
	EndOfFile
	chmod +x ./xstartup
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null
	touch /tmp/.Tmoe-LXDE-Desktop-Detection-FILE
	STARTVNCANDSTOPVNC
}

#################################################
STARTVNCANDSTOPVNC() {
	if [ "${LINUXDISTRO}" = "debian" ] || [ "${LINUXDISTRO}" = "redhat" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			sed -i 's:dbus-launch::' ~/.vnc/xstartup
		fi
	fi
	cd /usr/local/bin
	cat >startvnc <<-'EndOfFile'
		#!/bin/bash
		stopvnc >/dev/null 2>&1
		export USER="$(whoami)"
		export HOME="${HOME}"
		if [ ! -e "${HOME}/.vnc/xstartup" ]; then
			sudo cp -rvf "/root/.vnc" "${HOME}" || su -c "cp -rvf /root/.vnc ${HOME}"
		fi
		if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
			echo '检测到您使用的是WSL,正在为您打开音频服务'
			export PULSE_SERVER=tcp:127.0.0.1
			cd "/mnt/c/Users/Public/Downloads/pulseaudio"
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat"
			echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
			if grep -q '172..*1' "/etc/resolv.conf"; then
				echo "检测到您当前使用的可能是WSL2"
				WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
				sed -i "s/^export PULSE_SERVER=.*/export PULSE_SERVER=${WSL2IP}/g" ~/.vnc/xstartup
				echo "已将您的音频服务ip修改为${WSL2IP}"
			fi
			#grep 无法从"~/.vnc"中读取文件，去掉双引号就可以了。
			sleep 2
		fi
		CURRENTuser=$(ls -lt /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')
		if [ ! -z "${CURRENTuser}" ] && [ "${HOME}" != "/root" ]; then
		if [ -e "${HOME}/.profile" ]; then
			CURRENTuser=$(ls -l ${HOME}/.profile | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.profile | cut -d ' ' -f 4)
		elif [ -e "${HOME}/.bashrc" ]; then
			CURRENTuser=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 4)
		elif [ -e "${HOME}/.zshrc" ]; then
			CURRENTuser=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 4)
		fi
		echo "检测到/home目录不为空，为避免权限问题，正在将${HOME}目录下的.ICEauthority、.Xauthority以及.vnc 的权限归属修改为${CURRENTuser}用户和${CURRENTgroup}用户组"
			cd ${HOME}
		chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null
		fi
		echo "正在启动vnc服务,本机默认vnc地址localhost:5901"
		echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):5901
		export LANG="en_US.UTF8"
		#启动VNC服务的命令为最后一行
		vncserver -geometry 720x1440 -depth 24 -name remote-desktop :1
	EndOfFile
	##############
	cat >stopvnc <<-'EndOfFile'
		#!/bin/bash
		export USER="$(whoami)"
		export HOME="${HOME}"
		vncserver -kill :1
		rm -rf /tmp/.X1-lock
		rm -rf /tmp/.X11-unix/X1
		pkill Xtightvnc
	EndOfFile
	###############################
	cat >startxsdl <<-'EndOfFile'
		#!/bin/bash
		stopvnc >/dev/null 2>&1
		export DISPLAY=127.0.0.1:0
		export PULSE_SERVER=tcp:127.0.0.1:4713
		echo '正在为您启动xsdl,请将display number改为0'
		echo 'Starting xsdl, please change display number to 0'
		echo '默认为前台运行，您可以按Ctrl+C终止，或者在termux原系统内输stopvnc'
		echo 'The default is to run in the foreground, you can press Ctrl + C to terminate, or type "stopvnc" in the original termux system.'
		if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
			echo '检测到您使用的是WSL,正在为您打开音频服务'
			export PULSE_SERVER=tcp:127.0.0.1
			cd "/mnt/c/Users/Public/Downloads/pulseaudio"
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat"
			echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
			cd "/mnt/c/Users/Public/Downloads/VcXsrv/"
			#/mnt/c/WINDOWS/system32/cmd.exe /c "start .\config.xlaunch"
			/mnt/c/WINDOWS/system32/taskkill.exe /f /im vcxsrv.exe 2>/dev/null
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\vcxsrv.exe :0 -multiwindow -clipboard -wgl -ac"
			echo "若无法自动打开X服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe"
			if grep -q '172..*1' "/etc/resolv.conf"; then
				echo "检测到您当前使用的可能是WSL2，如需手动启动，请在xlaunch.exe中勾选Disable access control"
				WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
				export PULSE_SERVER=${WSL2IP}
				export DISPLAY=${WSL2IP}:0
				echo "已将您的显示和音频服务ip修改为${WSL2IP}"
			fi
			sleep 2
		fi
		#不要将上面uname -r的检测修改为WINDOWSDISTRO
		#sudo下无法用whoami检测用户
		CURRENTuser=$(ls -lt /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')
		if [ ! -z "${CURRENTuser}" ] && [ "${HOME}" != "/root" ]; then
			if [ -e "${HOME}/.profile" ]; then
				CURRENTuser=$(ls -l ${HOME}/.profile | cut -d ' ' -f 3)
				CURRENTgroup=$(ls -l ${HOME}/.profile | cut -d ' ' -f 4)
			elif [ -e "${HOME}/.bashrc" ]; then
				CURRENTuser=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 3)
				CURRENTgroup=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 4)
			elif [ -e "${HOME}/.zshrc" ]; then
				CURRENTuser=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 3)
				CURRENTgroup=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 4)
			fi
			echo "检测到/home目录不为空，为避免权限问题，正在将${HOME}目录下的.ICEauthority、.Xauthority以及.vnc 的权限归属修改为${CURRENTuser}用户和${CURRENTgroup}用户组"
			cd ${HOME}
			chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null
		fi

		export LANG="en_US.UTF-8"
		dbus-launch startxfce4 
	EndOfFile

	if [ -f "/tmp/.Tmoe-MATE-Desktop-Detection-FILE" ]; then
		rm -f /tmp/.Tmoe-MATE-Desktop-Detection-FILE
		sed -i '/dbus-launch/d' startxsdl
		sed -i '$ a\dbus-launch mate-session' startxsdl
	elif [ -f "/tmp/.Tmoe-LXDE-Desktop-Detection-FILE" ]; then
		rm -f /tmp/.Tmoe-LXDE-Desktop-Detection-FILE
		sed -i '/dbus-launch/d' startxsdl
		sed -i '$ a\dbus-launch startlxde' startxsdl
	elif [ -f "/tmp/.Tmoe-LXQT-Desktop-Detection-FILE" ]; then
		rm -f /tmp/.Tmoe-LXQT-Desktop-Detection-FILE
		sed -i '/dbus-launch/d' startxsdl
		sed -i '$ a\dbus-launch startlxqt' startxsdl
	elif [ -f "/tmp/.Tmoe-KDE-PLASMA5-Desktop-Detection-FILE" ]; then
		rm -f /tmp/.Tmoe-KDE-PLASMA5-Desktop-Detection-FILE
		sed -i '/dbus-launch/d' startxsdl
		#sed -i '$ a\dbus-launch startplasma-x11' startxsdl
		cat >>startxsdl <<-'EndOfKDE'
			if command -v "startkde" >/dev/null; then
				dbus-launch startkde
			else
				dbus-launch startplasma-x11
			fi
		EndOfKDE
	elif [ -f "/tmp/.Tmoe-GNOME3-Desktop-Detection-FILE" ]; then
		rm -f /tmp/.Tmoe-GNOME3-Desktop-Detection-FILE
		sed -i '/dbus-launch/d' startxsdl
		sed -i '$ a\dbus-launch gnome-session' startxsdl
	elif [ -f "/tmp/.Tmoe-cinnamon-Desktop-Detection-FILE" ]; then
		rm -f /tmp/.Tmoe-cinnamon-Desktop-Detection-FILE
		sed -i '/dbus-launch/d' startxsdl
		sed -i '$ a\dbus-launch cinnamon-launcher' startxsdl
	elif [ -f "/tmp/.Tmoe-DEEPIN-Desktop-Detection-FILE" ]; then
		rm -f /tmp/.Tmoe-DEEPIN-Desktop-Detection-FILE
		sed -i '/dbus-launch/d' startxsdl
		sed -i '$ a\dbus-launch startdde' startxsdl
	fi
	if [ "${LINUXDISTRO}" = "debian" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			sed -i 's:dbus-launch::' startxsdl
		fi
	fi
	#下面那行需放在检测完成之后才执行
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null

	######################
	chmod +x startvnc stopvnc startxsdl
	dpkg --configure -a
	#暂不卸载。若卸载则将破坏其依赖关系。
	#umount .gvfs
	#apt purge "gvfs*" "udisks2*"
	CURRENTuser=$(ls -lt /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')
	if [ ! -z "${CURRENTuser}" ]; then
		if [ -e "${HOME}/.profile" ]; then
			CURRENTuser=$(ls -l ${HOME}/.profile | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.profile | cut -d ' ' -f 4)
		elif [ -e "${HOME}/.bashrc" ]; then
			CURRENTuser=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 4)
		elif [ -e "${HOME}/.zshrc" ]; then
			CURRENTuser=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 4)
		fi
		echo "检测到/home目录不为空，为避免权限问题，正在将${HOME}目录下的.ICEauthority、.Xauthority以及.vnc 的权限归属修改为${CURRENTuser}用户和${CURRENTgroup}用户组"
		cd ${HOME}
		chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null
	fi
	#仅针对WSL修改语言设定
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		if [ "${LANG}" != 'en_US.UTF8' ]; then
			grep -q 'LANG=\"en_US' "/etc/profile" || sed -i '$ a\export LANG="en_US.UTF-8"' "/etc/profile"
			grep -q 'LANG=\"en_US' "${HOME}/.zlogin" || echo 'export LANG="en_US.UTF-8"' >>"${HOME}/.zlogin"
		fi
	fi
	echo 'The vnc service is about to start for you. The password you entered is hidden.'
	echo '即将为您启动vnc服务，您需要输两遍（不可见的）密码。'
	echo "When prompted for a view-only password, it is recommended that you enter 'n'"
	echo '如果提示view-only,那么建议您输n,选择权在您自己的手上。'
	echo '请输入6至8位密码'
	startvnc
	echo '您之后可以输startvnc来启动vnc服务，输stopvnc停止'
	echo '您还可以在termux原系统或windows的linux子系统里输startxsdl来启动xsdl，按Ctrl+C或在termux原系统里输stopvnc来停止进程'
	if [ "${HOME}" != "/root" ]; then
		cp -rpf ~/.vnc /root/ &
		chown -R root:root /root/.vnc &
	fi

	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		echo "若无法自动打开X服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe"
		cd "/mnt/c/Users/Public/Downloads"
		if grep -q '172..*1' "/etc/resolv.conf"; then
			echo "检测到您当前使用的可能是WSL2，如需手动启动，请在xlaunch.exe中勾选Disable access control"
			WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
			export PULSE_SERVER=${WSL2IP}
			export DISPLAY=${WSL2IP}:0
			echo "已将您的X和音频服务ip修改为${WSL2IP}"
		else
			echo "${YELLOW}检测到您使用的是WSL1(第一代win10的Linux子系统)${RESET}"
			echo "${YELLOW}若无法启动x服务，则请在退出脚本后，以非root身份手动输startxsdl来启动windows的x服务${RESET}"
			echo "您也可以手动输startvnc来启动vnc服务"
		fi
		cd ./VcXsrv
		echo "请在启动音频服务前，确保您已经允许pulseaudio.exe通过Windows Defender防火墙"
		if [ ! -e "Firewall-pulseaudio.png" ]; then
			wget -O "Firewall-pulseaudio.png" 'https://gitee.com/mo2/pic_api/raw/test/2020/03/31/rXLbHDxfj1Vy9HnH.png'
		fi
		/mnt/c/WINDOWS/system32/cmd.exe /c "start Firewall.cpl"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\Firewall-pulseaudio.png" 2>/dev/null
		############
		if [ ! -e 'XserverHightDPI.png' ]; then
			wget -O 'XserverHightDPI.png' https://gitee.com/mo2/pic_api/raw/test/2020/03/27/jvNs2JUIbsSQQInO.png
		fi
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\XserverHightDPI.png" 2>/dev/null
		echo "若X服务的画面过于模糊，则您需要右击vcxsrv.exe，并手动修改兼容性设定中的高Dpi选项。"
		echo "vcxsrv文件位置为C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe"
		echo "${YELLOW}按回车键启动X${RESET}"
		echo "${YELLOW}Press enter to startx${RESET}"
		echo '运行过程中，您可以按Ctrl+C终止前台进程，输pkill -u $(whoami)终止当前用户所有进程'
		#上面那行必须要单引号
		read
		cd "/mnt/c/Users/Public/Downloads"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start ."
		startxsdl &
	fi
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	DEBIANMENU
}
########################
FrequentlyAskedQuestions() {
	TMOEFAQ=$(whiptail --title "FAQ(よくある質問)" --menu \
		"您有哪些疑问？\nWhat questions do you have?" 15 60 5 \
		"1" "Cannot open Baidu Netdisk" \
		"2" "udisks2/gvfs配置失败" \
		"3" "linuxQQ闪退" \
		"4" "VNC/X11闪退" \
		"5" "软件禁止以root权限运行" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${TMOEFAQ}" == '0' ]; then
		DEBIANMENU
	fi
	############################
	if [ "${TMOEFAQ}" == '1' ]; then
		#echo "若无法打开，则请手动输rm -f ~/baidunetdisk/baidunetdiskdata.db"
		echo "若无法打开，则请手动输rm -rf ~/baidunetdisk"
		echo "${YELLOW}按回车键自动执行上述命令，按Ctrl+C取消${RESET}"
		read
		rm -vf ~/baidunetdisk/baidunetdiskdata.db
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
	fi
	#######################
	if [ "${TMOEFAQ}" == '2' ]; then
		echo "${YELLOW}按回车键卸载gvfs和udisks2，按Ctrl+C取消${RESET}"
		read
		apt purge -y --allow-change-held-packages ^udisks2 ^gvfs
		DEBIANMENU
	fi
	############################
	if [ "${TMOEFAQ}" == '3' ]; then
		echo "如果版本更新后登录出现闪退的情况，那么您可以输rm -rf ~/.config/tencent-qq/ 后重新登录。"
		echo "${YELLOW}按回车键自动执行上述命令，按Ctrl+C取消${RESET}"
		read
		rm -rvf ~/.config/tencent-qq/
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
	fi
	#######################
	if [ "${TMOEFAQ}" == '4' ]; then
		FIXVNCdbusLaunch
	fi
	#######################
	if [ "${TMOEFAQ}" == '5' ]; then
		echo "部分软件出于安全性考虑，禁止以root权限运行。权限越大，责任越大。若root用户不慎操作，将有可能破坏系统。"
		echo "您可以使用以下命令来新建普通用户"
		echo "#创建一个用户名为mo2的新用户"
		echo "${YELLOW}adduser mo2${RESET}"
		echo "#输入的密码是隐藏的，根据提示创建完成后，接着输以下命令"
		echo "#将mo2加入到sudo用户组"
		echo "${YELLOW}adduser mo2 sudo${RESET}"
		echo "之后，若需要提权，则只需输sudo 命令"
		echo "例如${YELLOW}sudo apt update${RESET}"
		echo ""
		echo "切换用户的说明"
		echo "您可以输${YELLOW}sudo su - ${RESET}切换至root用户"
		echo "亦可输${YELLOW}sudo su - mo2${RESET}切换回mo2用户"
		echo "若需要以普通用户身份启动VNC，请先切换至普通用户，再输${YELLOW}startvnc${RESET}"
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
	fi
}
#################
FIXVNCdbusLaunch() {
	echo "由于在2020-0410至0411的更新中给所有系统的桌面都加入了dbus-launch，故在部分安卓设备的Proot容器上出现了兼容性问题。"
	echo "注1：该操作在linux虚拟机及win10子系统上没有任何问题"
	echo "注2：2020-0412更新的版本已加入检测功能，理论上不会再出现此问题。"
	if [ ! -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前可能处于非proot环境下，是否继续修复？"
		echo "如需重新配置vnc启动脚本，请更新debian-i后再覆盖安装gui"
	fi
	echo "${YELLOW}按回车键继续，按Ctrl+C取消${RESET}"
	echo "Press Enter to continue,press Ctrl+C to cancel."
	read

	if grep 'dbus-launch' ~/.vnc/xstartup; then
		DBUSstatus="$(echo 检测到dbus-launch当前在VNC脚本中处于启用状态)"
	else
		DBUSstatus="$(echo 检测到dbus-launch当前在vnc脚本中处于禁用状态)"
	fi

	if (whiptail --title "您想要对这个小可爱中做什么 " --yes-button "Disable" --no-button "Enable" --yesno "您是想要禁用dbus-launch，还是启用呢？${DBUSstatus} \n请做出您的选择！✨" 10 50); then
		sed -i 's:dbus-launch::' "/usr/local/bin/startxsdl"
		sed -i 's:dbus-launch::' ~/.vnc/xstartup
	else
		if grep 'startxfce4' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为xfce4，正在将dbus-launch加入至启动脚本中..."
			sed -i 's/.*startxfce.*/dbus-launch startxfce4 \&/' ~/.vnc/xstartup
			#sed -i 's/.*startxfce.*/dbus-launch startxfce4 \&/' "/usr/local/bin/startxsdl"
			sed -i '$ c\dbus-launch startxfce4 \&' "/usr/local/bin/startxsdl"
		elif grep 'startlxde' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为lxde，正在将dbus-launch加入至启动脚本中..."
			sed -i 's/.*startlxde.*/dbus-launch startlxde \&/' ~/.vnc/xstartup
			#sed -i 's/.*startlxde.*/dbus-launch startlxde \&/' "/usr/local/bin/startxsdl"
			sed -i '$ c\dbus-launch startlxde \&' "/usr/local/bin/startxsdl"
		elif grep 'startlxqt' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为lxqt，正在将dbus-launch加入至启动脚本中..."
			sed -i 's/.*startlxqt.*/dbus-launch startlxqt \&/' ~/.vnc/xstartup
			#sed -i 's/.*startlxqt.*/dbus-launch startlxqt \&/' "/usr/local/bin/startxsdl"
			sed -i '$ c\dbus-launch startlxqt \&' "/usr/local/bin/startxsdl"
		elif grep 'mate-session' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为mate，正在将dbus-launch加入至启动脚本中..."
			sed -i 's/.*mate-session.*/dbus-launch mate-session \&/' ~/.vnc/xstartup
			#sed -i 's/.*mate-session.*/dbus-launch mate-session \&/' "/usr/local/bin/startxsdl"
			sed -i '$ c\dbus-launch mate-session \&' "/usr/local/bin/startxsdl"
		elif grep 'startplasma' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为KDE Plasma5，正在将dbus-launch加入至启动脚本中..."
			sed -i 's/.*startplasma-x11.*/dbus-launch startplasma-x11 \&/' ~/.vnc/xstartup
			sed -i 's/.*startplasma-x11.*/dbus-launch startplasma-x11/' "/usr/local/bin/startxsdl"
			sed -i 's/.* startkde.*/ dbus-launch startkde \&/' ~/.vnc/xstartup
			sed -i 's/.* startkde.*/ dbus-launch startkde/' "/usr/local/bin/startxsdl"
			#sed -i 's/.*startkde.*/dbus-launch startkde \&/' "/usr/local/bin/startxsdl"
			#sed -i '$ c\dbus-launch startplasma-x11 \&' "/usr/local/bin/startxsdl"
		elif grep 'gnome-session' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为GNOME3，正在将dbus-launch加入至启动脚本中..."
			sed -i 's/.*gnome-session.*/dbus-launch gnome-session \&/' ~/.vnc/xstartup
			#sed -i 's/.*gnome-session.*/dbus-launch gnome-session \&/' "/usr/local/bin/startxsdl"
			sed -i '$ c\dbus-launch gnome-session \&' "/usr/local/bin/startxsdl"
		elif grep 'cinnamon' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为cinnamon，正在将dbus-launch加入至启动脚本中..."
			sed -i 's/.*cinnamon.*/dbus-launch cinnamon-launcher \&/' ~/.vnc/xstartup
			#sed -i 's/.*cinnamon.*/dbus-launch cinnamon \&/' "/usr/local/bin/startxsdl"
			sed -i '$ c\dbus-launch cinnamon-launcher \&' "/usr/local/bin/startxsdl"
		elif grep 'startdde' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为deepin desktop，正在将dbus-launch加入至启动脚本中..."
			sed -i 's/.*startdde.*/dbus-launch startdde \&/' ~/.vnc/xstartup
			#sed -i 's/.*startdde.*/dbus-launch startdde \&/' "/usr/local/bin/startxsdl"
			sed -i '$ c\dbus-launch startdde \&' "/usr/local/bin/startxsdl"
		else
			echo "未检测到vnc相关配置，请更新debian-i后再覆盖安装gui"
		fi
	fi

	echo "${YELLOW}修改完成，按回车键返回${RESET}"
	echo "若无法修复，则请前往gitee.com/mo2/linux提交issue，并附上报错截图和详细说明。"
	echo "还建议您附上cat /usr/local/bin/startxsdl 和 cat ~/.vnc/xstartup 的启动脚本截图"
	echo "Press Enter to return"
	read
	DEBIANMENU
}

####################
BetaFeatures() {
	TMOEBETA=$(
		whiptail --title "Beta features" --menu "测试版功能可能无法正常运行\nBeta features may not work properly." 15 60 5 \
			"1" "sunpinyin+google拼音+搜狗拼音" \
			"2" "WPS office(办公软件)" \
			"3" "gparted:磁盘分区工具" \
			"4" "gnome-system-monitor(资源监视器)" \
			"5" "openshot(视频剪辑)" \
			"6" "telegram(注重保护隐私的社交app)" \
			"7" "typora(markdown编辑器)" \
			"8" "electronic-wechat(第三方微信客户端)" \
			"9" "qbittorrent(P2P下载工具)" \
			"10" "plasma-discover:KDE发现(软件中心)" \
			"11" "gnome-software软件商店" \
			"12" "calibre:电子书转换器和库管理" \
			"13" "文件管理器:thunar/nautilus/dolphin" \
			"14" "krita(数字绘画)" \
			"15" "OBS-Studio(录屏软件)" \
			"16" "fbreader(epub阅读器)" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${TMOEBETA}" == '0' ]; then
		DEBIANMENU
	fi
	####################
	if [ "${TMOEBETA}" == '1' ]; then
		apt update
		apt install -y fcitx
		apt install -y fcitx-sunpinyin
		apt install -y fcitx-googlepinyin
		if [ "${LINUXDISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm fcitx-sogoupinyin
			echo "fcitx-sogoupinyin安装完成,按回车键返回"
			read
			BetaFeatures
		fi

		if [ "$(uname -m)" = "x86_64" ]; then
			cd /tmp
			wget -O 'sogou_pinyin.deb' 'http://cdn2.ime.sogou.com/dl/index/1571302197/sogoupinyin_2.3.1.0112_amd64.deb?st=LibLXDSBIhQIpXS1y64TXg&e=1585607434&fn=sogoupinyin_2.3.1.0112_amd64.deb'
			apt install -y ./sogou_pinyin.deb
			rm -f sogou_pinyin.deb
		elif [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "armv7l" ]; then
			echo "架构不支持，跳过安装搜狗输入法。"
		else
			wget -O 'sogou_pinyin.deb' 'http://cdn2.ime.sogou.com/dl/index/1524572032/sogoupinyin_2.2.0.0108_i386.deb?st=Y2AOqkQafg4B0WBAkItOyA&e=1585607434&fn=sogoupinyin_2.2.0.0108_i386.deb'
			apt install -y ./sogou_pinyin.deb
			rm -f sogou_pinyin.deb
		fi
		echo "如需卸载，请手动输apt purge -y sogoupinyin fcitx-sunpinyin fcitx-googlepinyin fcitx"
	fi

	##############################
	if [ "${TMOEBETA}" == '2' ]; then
		cd /tmp
		if [ -e "/usr/share/applications/wps-office-wps.desktop" ]; then
			echo "检测到您已安装WPS office,按回车键重新安装,按Ctrl+C取消"
			echo "Press enter to continue."
			read
		fi

		if [ "${LINUXDISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm wps-office
		fi

		if [ "${archtype}" = "arm64" ]; then
			if [ "${LINUXDISTRO}" = "debian" ]; then
				dpkg --configure -a
				wget -O WPSoffice.deb "https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9505/wps-office_11.1.0.9505_arm64.deb"
				apt install -y ./WPSoffice.deb
			elif [ "${LINUXDISTRO}" = "redhat" ]; then
				wget -O WPSoffice.rpm 'https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9505/wps-office-11.1.0.9505-1.aarch64.rpm'
				rpm -ivh ./WPSoffice.rpm
			fi
		elif [ "${archtype}" = "amd64" ]; then
			if [ "${LINUXDISTRO}" = "debian" ]; then
				dpkg --configure -a
				wget -O WPSoffice.deb "https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9505/wps-office_11.1.0.9505_amd64.deb"
				apt install -y ./WPSoffice.deb
			elif [ "${LINUXDISTRO}" = "redhat" ]; then
				wget -O WPSoffice.rpm "https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9505/wps-office-11.1.0.9505-1.x86_64.rpm"
				rpm -ivh ./WPSoffice.rpm
			fi
		else
			echo "暂不支持您的架构"
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			BetaFeatures
		fi
		echo "若安装失败，则请前往官网手动下载安装。"
		echo "url: https://linux.wps.cn"
		rm -fv ./WPSoffice.deb ./WPSoffice.rpm 2>/dev/null
		echo "安装完成，如需卸载，请手动输apt purge -y wps-office"
	fi
	##############################
	if [ "${TMOEBETA}" == '3' ]; then
		if [ ! -e "/usr/sbin/gparted" ]; then
			apt update
			apt install -y gparted
			apt install -y baobab
		fi
		gparted &
		echo "安装完成，如需卸载，请手动输apt purge -y gparted baobab"
	fi
	##############################
	if [ "${TMOEBETA}" == '4' ]; then

		if [ "${LINUXDISTRO}" = "debian" ]; then
			apt update
			apt install -y gnome-system-monitor

		elif [ "${LINUXDISTRO}" = "alpine" ]; then
			apk update
			apk add gnome-system-monitor

		elif [ "${LINUXDISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm gnome-system-monitor

		elif [ "${LINUXDISTRO}" = "redhat" ]; then
			dnf install -y gnome-system-monitor || yum install -y gnome-system-monitor

		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			emerge -vk gnome-system-monitor
		fi
		echo "安装完成，如需卸载，请手动输apt purge -y gnome-system-monitor"
	fi

	################################
	if [ "${TMOEBETA}" == '5' ]; then
		apt update
		apt install -y openshot
		echo "安装完成，如需卸载，请手动输apt purge -y openshot"
	fi
	# Blender在WSL2（Xserver）下测试失败，Kdenlive在VNC远程下测试成功。

	############################
	if [ "${TMOEBETA}" == '6' ]; then
		apt update
		apt install -y telegram-desktop
		echo "安装完成，如需卸载，请手动输apt purge -y telegram-desktop"
	fi
	############################
	if [ "${TMOEBETA}" == '7' ]; then
		cd /tmp
		if [ "$(uname -m)" = "x86_64" ]; then
			wget -O 'typora.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/t/typora/typora_0.9.67-1_amd64.deb'
			apt install -y ./typora.deb
			rm -vf ./typora.deb
			echo "安装完成，如需卸载，请手动输apt purge -y typora"
		elif [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "armv7l" ]; then
			echo "非常抱歉，暂不支持您的架构"
		else
			wget -O 'typora.deb' wget 'https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/non-free/t/typora/typora_0.9.22-1_i386.deb'
			apt install -y ./typora.deb
			rm -vf ./typora.deb
			echo "安装完成，如需卸载，请手动输apt purge -y typora"
		fi
	fi
	############################
	if [ "${TMOEBETA}" == '8' ]; then
		cd /tmp
		if [ "${archtype}" = "amd64" ]; then
			wget -O 'electronic-wechat.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/e/electronic-wechat/electronic-wechat_2.0~repack0~debiancn0_amd64.deb'
			#wget -O 'electronic-wechat.deb' 'http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/electronic-wechat_2.0.1_amd64.deb'
		elif [ "${archtype}" = "i386" ]; then
			wget -O 'electronic-wechat.deb' 'http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/electronic-wechat_2.0.1_i386.deb'
		else
			echo "非常抱歉，暂不支持您的架构"
		fi

		apt install -y ./electronic-wechat.deb
		rm -vf ./electronic-wechat.deb
		if [ -e "/usr/bin/electronic-wechat" ]; then
			echo "安装完成，如需卸载，请手动输apt purge -y electronic-wechat"
		fi
	fi
	##############################
	if [ "${TMOEBETA}" == '9' ]; then
		apt update
		apt install -y qbittorrent
		echo "安装完成，如需卸载，请手动输apt purge -y qbittorrent"
	fi

	################################
	##################################
	if [ "${TMOEBETA}" == '10' ]; then
		if [ ! -e "/usr/bin/plasma-discover" ]; then
			apt update
			apt install -y plasma-discover
		fi
		plasma-discover &
		echo "安装完成，如需卸载，请手动输apt purge -y plasma-discover"
	fi
	##################################
	if [ "${TMOEBETA}" == '11' ]; then
		if [ ! -e "/usr/bin/gnome-software" ]; then
			apt update
			apt install -y gnome-software
		fi
		gnome-software &
		echo "安装完成，如需卸载，请手动输apt purge -y gnome-software"
	fi

	############################
	if [ "${TMOEBETA}" == '12' ]; then
		apt update
		apt install -y calibre
		echo "安装完成，如需卸载，请手动输apt purge -y calibre"
	fi
	######################
	if [ "${TMOEBETA}" == '13' ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			echo "检测到您当前使用的是Proot容器，软件可能无法正常运行。"
			echo "安装后将有可能导致VNC黑屏,按Ctrl+C取消"
			echo "Press enter to continue,press Ctrl+C to canacel."
			read
		fi
		dependencies=""
		if [ ! -e /usr/bin/thunar ]; then
			dependencies="${dependencies} thunar"
		fi

		if [ ! -e /usr/bin/nautilus ]; then
			dependencies="${dependencies} nautilus"
		fi

		if [ ! -e /usr/bin/dolphin ]; then
			dependencies="${dependencies} dolphin"
		fi

		if [ ! -z "${dependencies}" ]; then
			if [ "${LINUXDISTRO}" = "debian" ]; then
				apt update
				apt install -y ${dependencies}

			elif [ "${LINUXDISTRO}" = "alpine" ]; then
				apk update
				apk add ${dependencies}

			elif [ "${LINUXDISTRO}" = "arch" ]; then
				pacman -Syu --noconfirm ${dependencies}

			elif [ "${LINUXDISTRO}" = "redhat" ]; then
				dnf install -y ${dependencies} || yum install -y ${dependencies}

			elif [ "${LINUXDISTRO}" = "openwrt" ]; then
				#opkg update
				opkg install ${dependencies} || opkg install ${dependencies}
			elif [ "${LINUXDISTRO}" = "void" ]; then
				xbps-install -S -y lxqt tigervnc

			elif [ "${LINUXDISTRO}" = "gentoo" ]; then
				emerge -vk ${dependencies}
			fi
		fi
		echo "安装完成，如需卸载，请手动输apt purge -y nautilus dolphin"
	fi
	##############################
	if [ "${TMOEBETA}" == '14' ]; then
		apt update
		apt install -y krita
		apt install -y krita-l10n
		echo "安装完成，如需卸载，请手动输apt purge -y ^krita"
	fi
	####################
	if [ "${TMOEBETA}" == '15' ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			apt update
			apt install -y ffmpeg obs-studio

		elif [ "${LINUXDISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm obs-studio

		elif [ "${LINUXDISTRO}" = "redhat" ]; then
			dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
			dnf install -y obs-studio || yum install -y obs-studio
			#dnf install xorg-x11-drv-nvidia-cuda
		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			emerge -vk media-video/obs-studio
		fi
		echo "若安装失败，则请前往官网阅读安装说明。"
		echo "url: https://obsproject.com/wiki/install-instructions#linux"
		echo "安装完成，如需卸载，请手动输apt purge -y ffmpeg obs-studio"
	fi
	##############################
	if [ "${TMOEBETA}" == '16' ]; then
		apt update
		apt install -y fbreader
		echo "安装完成，如需卸载，请手动输apt purge -y fbreader"
	fi
	########################################
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	BetaFeatures
}
###########################################
CHECKdependencies
########################################################################
