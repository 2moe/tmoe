#!/bin/bash
########################################################################
main() {
	case "$1" in
	i | -i)
		tmoe_linux_tool_menu
		;;
	up | -u)
		tmoe_linux_tool_upgrade
		;;
	h | -h | --help)
		frequently_asked_questions
		;;
	file | filebrowser)
		filebrowser_restart
		;;
	*)
		check_root
		;;
	esac
}
################
check_root() {
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
	check_dependencies
}
#############################
check_dependencies() {
	if grep -Eq 'debian|ubuntu' "/etc/os-release"; then
		LINUX_DISTRO='debian'
		PACKAGES_INSTALL_COMMAND='apt install -y'
		PACKAGES_REMOVE_COMMAND='apt purge -y'
		if grep -q 'ubuntu' /etc/os-release; then
			DEBIAN_DISTRO='ubuntu'
		elif [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
			DEBIAN_DISTRO='kali'
		fi
		###################
	elif grep -Eq "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		LINUX_DISTRO='openwrt'
		PACKAGES_INSTALL_COMMAND='opkg install'
		PACKAGES_REMOVE_COMMAND='opkg remove'
		##################
	elif grep -Eqi "Fedora|CentOS|Red Hat|redhat" "/etc/os-release"; then
		LINUX_DISTRO='redhat'
		PACKAGES_INSTALL_COMMAND='dnf install -y'
		PACKAGES_REMOVE_COMMAND='dnf remove -y'
		if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHAT_DISTRO='centos'
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHAT_DISTRO='fedora'
		fi
		###################
	elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" "/etc/os-release"; then
		LINUX_DISTRO='alpine'
		PACKAGES_INSTALL_COMMAND='apk add'
		PACKAGES_REMOVE_COMMAND='apk del'
		######################
	elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
		LINUX_DISTRO='arch'
		PACKAGES_INSTALL_COMMAND='pacman -Sy'
		PACKAGES_REMOVE_COMMAND='pacman -Rsc'
		######################
	elif grep -Eq "gentoo|funtoo" "/etc/os-release"; then
		LINUX_DISTRO='gentoo'
		PACKAGES_INSTALL_COMMAND='pacman -vk'
		PACKAGES_REMOVE_COMMAND='pacman -C'
		########################
	elif grep -qi 'suse' '/etc/os-release'; then
		LINUX_DISTRO='suse'
		PACKAGES_INSTALL_COMMAND='zypper in -y'
		PACKAGES_REMOVE_COMMAND='zypper rm'
		########################
	elif [ "$(cat /etc/issue | cut -c 1-4)" = "Void" ]; then
		LINUX_DISTRO='void'
		PACKAGES_INSTALL_COMMAND='xbps-install -S -y'
		PACKAGES_REMOVE_COMMAND='xbps-remove -R'
	fi
	#####################
	DEPENDENCIES=""

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ ! -e /usr/bin/aptitude ]; then
			DEPENDENCIES="${DEPENDENCIES} aptitude"
		fi
	fi

	if [ ! -e /bin/bash ]; then
		DEPENDENCIES="${DEPENDENCIES} bash"
	fi

	if [ ! $(command -v busybox) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sys-apps/busybox"
		elif [ "${LINUX_DISTRO}" = "redhat" ]; then
			if [ "${REDHAT_DISTRO}" = "fedora" ]; then
				DEPENDENCIES="${DEPENDENCIES} busybox"
			fi
		else
			DEPENDENCIES="${DEPENDENCIES} busybox"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/catimg ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			if grep -q 'VERSION_ID' "/etc/os-release"; then
				DEBIANVERSION="$(grep 'VERSION_ID' "/etc/os-release" | cut -d '"' -f 2 | cut -d '.' -f 1)"
			else
				DEBIANVERSION="10"
			fi
			if ((${DEBIANVERSION} <= 9)); then
				echo "检测到您的系统版本低于debian10，跳过安装catimg"
			else
				DEPENDENCIES="${DEPENDENCIES} catimg"
			fi

		elif [ "${REDHAT_DISTRO}" = "fedora" ] || [ "${LINUX_DISTRO}" = "arch" ] || [ "${LINUX_DISTRO}" = "void" ]; then
			DEPENDENCIES="${DEPENDENCIES} catimg"
		fi
	fi

	if [ ! -e /usr/bin/curl ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/curl"
		else
			DEPENDENCIES="${DEPENDENCIES} curl"
		fi
	fi
	######################
	if [ ! -e /usr/bin/fc-cache ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} fontconfig"
		fi
	fi
	###################
	#manjaro基础容器里无grep
	if [ ! $(command -v grep) ]; then
		if [ "${LINUX_DISTRO}" != "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} grep"
		fi
	fi
	####################
	if [ ! -e /usr/bin/git ]; then
		if [ "${LINUX_DISTRO}" = "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} git git-http"
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} dev-vcs/git"
		else
			DEPENDENCIES="${DEPENDENCIES} git"
		fi
	fi
	####################
	if [ ! -e /usr/bin/mkfontscale ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} xfonts-utils"
		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			DEPENDENCIES="${DEPENDENCIES} xorg-mkfontscale"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/xz ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} xz-utils"
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} app-arch/xz-utils"
		else
			DEPENDENCIES="${DEPENDENCIES} xz"
		fi
	fi

	if [ ! -e /usr/bin/pkill ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sys-process/procps"
		elif [ "${LINUX_DISTRO}" != "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} procps"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/sudo ]; then
		if [ "${LINUX_DISTRO}" != "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sudo"
		fi
	fi
	###################
	#centos8基础容器里无tar
	if [ ! $(command -v tar) ]; then
		if [ "${LINUX_DISTRO}" != "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} tar"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/whiptail ] && [ ! -e /bin/whiptail ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} whiptail"
		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			DEPENDENCIES="${DEPENDENCIES} libnewt"
		elif [ "${LINUX_DISTRO}" = "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} dialog"
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} dev-libs/newt"
		else
			DEPENDENCIES="${DEPENDENCIES} newt"
		fi
	fi
	##############
	if [ ! -e /usr/bin/wget ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/wget"
		else
			DEPENDENCIES="${DEPENDENCIES} wget"
		fi
	fi
	##############

	if [ ! -z "${DEPENDENCIES}" ]; then
		echo "正在安装相关依赖..."

		if [ "${LINUX_DISTRO}" = "debian" ]; then
			apt update
			apt install -y ${DEPENDENCIES}
			#创建文件夹防止aptitude报错
			mkdir -p /run/lock /var/lib/aptitude
			touch /var/lib/aptitude/pkgstates

		elif [ "${LINUX_DISTRO}" = "alpine" ]; then
			apk update
			apk add ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "redhat" ]; then
			dnf install -y ${DEPENDENCIES} || yum install -y ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "openwrt" ]; then
			#opkg update
			opkg install ${DEPENDENCIES} || opkg install whiptail

		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			emerge -avk ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "suse" ]; then
			zypper in -y ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "void" ]; then
			xbps-install -S -y ${DEPENDENCIES}

		else
			apt update
			apt install -y ${DEPENDENCIES} || port install ${DEPENDENCIES} || zypper in ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES}
		fi
	fi
	################
	case $(uname -m) in
	aarch64)
		ARCH_TYPE="arm64"
		;;
	armv7l)
		ARCH_TYPE="armhf"
		;;
	armv6l)
		ARCH_TYPE="armel"
		;;
	x86_64)
		ARCH_TYPE="amd64"
		;;
	i*86)
		ARCH_TYPE="i386"
		;;
	x86)
		ARCH_TYPE="i386"
		;;
	s390*)
		ARCH_TYPE="s390x"
		;;
	ppc*)
		ARCH_TYPE="ppc64el"
		;;
	mips*)
		ARCH_TYPE="mipsel"
		;;
	risc*)
		ARCH_TYPE="riscv"
		;;
	esac
	################
	if [ ! -e /usr/bin/catimg ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			CATIMGlatestVersion="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/' | grep arm64 | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '_' -f 2)"
			cd /tmp
			curl -Lvo 'catimg.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/catimg_${CATIMGlatestVersion}_${ARCH_TYPE}.deb"
			apt install -y ./catimg.deb
			rm -f catimg.deb
		fi
	fi

	if [ ! $(command -v busybox) ]; then
		cd /tmp
		wget --no-check-certificate -O "busybox" "https://gitee.com/mo2/busybox/raw/master/busybox-$(uname -m)"
		chmod +x busybox
		LatestBusyboxDEB="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/busybox/ | grep static | grep ${ARCH_TYPE} | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		curl -Lvo 'busybox.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/busybox/${LatestBusyboxDEB}"
		mkdir -p busybox-static
		./busybox dpkg-deb -X busybox.deb ./busybox-static
		mv -f ./busybox-static/bin/busybox /usr/local/bin/
		chmod +x /usr/local/bin/busybox
		rm -rvf busybox busybox-static busybox.deb
	fi

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
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
	##############
	RED=$(printf '\033[31m')
	GREEN=$(printf '\033[32m')
	YELLOW=$(printf '\033[33m')
	BLUE=$(printf '\033[34m')
	BOLD=$(printf '\033[1m')
	RESET=$(printf '\033[m')
	cur=$(pwd)
	tmoe_linux_tool_menu
}
####################################################
tmoe_linux_tool_menu() {
	cd ${cur}
	TMOE_OPTION=$(
		whiptail --title "Tmoe-linux Tool输debian-i启动(20200511-13)" --menu "Type 'debian-i' to start this tool.Please use the enter and arrow keys to operate.请使用方向键和回车键操作,更新日志:0501支持解析并下载B站视频,0502支持搭建个人云网盘,0503优化code-server的配置,0507支持配置wayland,0510更新文件选择功能,0511支持配置x11vnc" 20 50 7 \
			"1" "Install GUI 安装图形界面" \
			"2" "Install browser 安装浏览器" \
			"3" "Download theme 下载主题" \
			"4" "Other software/games 其它软件/游戏" \
			"5" "Modify vnc/xsdl/rdp(远程桌面)conf" \
			"6" "Download video 解析视频链接" \
			"7" "Personal netdisk 个人云网盘/文件共享" \
			"8" "Update tmoe-linux tool 更新本工具" \
			"9" "VSCode" \
			"10" "Start zsh tool 启动zsh管理工具" \
			"11" "Remove GUI 卸载图形界面" \
			"12" "Remove browser 卸载浏览器" \
			"13" "FAQ 常见问题" \
			"14" "Modify to Kali sources list 配置kali源" \
			"15" "Beta Features 测试版功能" \
			"0" "Exit 退出" \
			3>&1 1>&2 2>&3
	)
	###############################
	if [ "${TMOE_OPTION}" == '0' ]; then
		exit 0
	fi
	##############################
	if [ "${TMOE_OPTION}" == '1' ]; then
		install_gui
	fi
	###################################
	if [ "${TMOE_OPTION}" == '2' ]; then
		install_browser
	fi
	###################################
	if [ "${TMOE_OPTION}" == '3' ]; then
		configure_theme
	fi
	###################################
	if [ "${TMOE_OPTION}" == '4' ]; then
		other_software
	fi
	####################
	if [ "${TMOE_OPTION}" == '5' ]; then
		modify_remote_desktop_config
		#MODIFYVNCORXSDLCONF
	fi
	####################
	if [ "${TMOE_OPTION}" == '6' ]; then
		download_videos
		#MODIFYVNCORXSDLCONF
	fi
	#######################################
	if [ "${TMOE_OPTION}" == '7' ]; then
		personal_netdisk
	fi
	###################################
	if [ "${TMOE_OPTION}" == '8' ]; then
		tmoe_linux_tool_upgrade
	fi
	###################################
	if [ "${TMOE_OPTION}" == '9' ]; then
		which_vscode_edition
	fi
	#################################
	if [ "${TMOE_OPTION}" == '10' ]; then
		bash -c "$(curl -LfsS 'https://gitee.com/mo2/zsh/raw/master/zsh.sh')"
	fi
	###################################
	if [ "${TMOE_OPTION}" == '11' ]; then
		remove_gui
	fi
	###############################
	if [ "${TMOE_OPTION}" == '12' ]; then
		remove_browser
	fi
	###############################
	if [ "${TMOE_OPTION}" == '13' ]; then
		frequently_asked_questions
	fi
	############
	if [ "${TMOE_OPTION}" == '14' ]; then
		modify_to_kali_sources_list
	fi
	###############################
	if [ "${TMOE_OPTION}" == '15' ]; then
		beta_features
	fi
	#########################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
############################
############################
arch_does_not_support() {
	echo "${RED}WARNING！${RESET}检测到${YELLOW}架构${RESET}${RED}不支持！${RESET}"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
}
##########################
do_you_want_to_continue() {
	echo "${YELLOW}Do you want to continue?[Y/n]${RESET}"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET},type ${YELLOW}n${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}继续${RESET}，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
	read opt
	case $opt in
	y* | Y* | "") ;;

	n* | N*)
		echo "skipped."
		${RETURN_TO_WHERE}
		;;
	*)
		echo "Invalid choice. skipped."
		${RETURN_TO_WHERE}
		#beta_features
		;;
	esac
}
######################
different_distro_software_install() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		apt update
		apt install -y ${DEPENDENCY_01} || aptitude install ${DEPENDENCY_01}
		apt install -y ${DEPENDENCY_02} || aptitude install ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		apk update
		apk add ${DEPENDENCY_01}
		apk add ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm ${DEPENDENCY_01} || yay -S ${DEPENDENCY_01}
		pacman -S --noconfirm ${DEPENDENCY_02} || yay -S ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		dnf install -y ${DEPENDENCY_01} || yum install -y ${DEPENDENCY_01}
		dnf install -y ${DEPENDENCY_02} || yum install -y ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "openwrt" ]; then
		#opkg update
		opkg install ${DEPENDENCY_01}
		opkg install ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		emerge -vk ${DEPENDENCY_01}
		emerge -vk ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		zypper in -y ${DEPENDENCY_01}
		zypper in -y ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		xbps-install -S -y ${DEPENDENCY_01}
		xbps-install -S -y ${DEPENDENCY_02}
		################
	else
		apt update
		apt install -y ${DEPENDENCY_01} || port install ${DEPENDENCY_01} || guix package -i ${DEPENDENCY_01} || pkg install ${DEPENDENCY_01} || pkg_add ${DEPENDENCY_01} || pkgutil -i ${DEPENDENCY_01}
	fi
}
############################
############################
tmoe_linux_tool_upgrade() {
	curl -Lvo /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
	echo "Update ${YELLOW}completed${RESET}, Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}更新完成，按回车键返回。${RESET}"
	chmod +x /usr/local/bin/debian-i
	read
	#bash /usr/local/bin/debian-i
	source /usr/local/bin/debian-i
}
#####################
#####################
download_videos() {
	VIDEOTOOL=$(
		whiptail --title "DOWNLOAD VIDEOS" --menu "你想要使用哪个工具来下载视频呢" 14 50 6 \
			"1" "Annie" \
			"2" "You-get" \
			"3" "Youtube-dl" \
			"4" "cookie说明" \
			"5" "upgrade更新下载工具" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${VIDEOTOOL}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	##############################
	if [ "${VIDEOTOOL}" == '1' ]; then
		golang_annie
		#https://gitee.com/mo2/annie
		#AnnieVersion=$(annie -v | cut -d ':' -f 2 | cut -d ',' -f 1 | awk -F ' ' '$0=$NF')
	fi
	##############################
	if [ "${VIDEOTOOL}" == '2' ]; then
		python_you_get
	fi
	##############################
	if [ "${VIDEOTOOL}" == '3' ]; then
		python_youtube_dl
	fi
	##############################
	if [ "${VIDEOTOOL}" == '4' ]; then
		cookies_readme
	fi
	##############################
	if [ "${VIDEOTOOL}" == '5' ]; then
		upgrade_video_download_tool
	fi
	#########################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
###########
golang_annie() {
	if [ ! -e "/usr/local/bin/annie" ]; then
		echo "检测到您尚未安装annie，将为您跳转至更新管理中心"
		upgrade_video_download_tool
		exit 0
	fi

	if [ ! -e "${HOME}/sd/Download/Videos" ]; then
		mkdir -p ${HOME}/sd/Download/Videos
	fi

	cd ${HOME}/sd/Download/Videos

	AnnieVideoURL=$(whiptail --inputbox "Please enter a url.请输入视频链接,例如https://www.bilibili.com/video/av号,或者直接输入avxxx(av号或BV号)。您可以在url前加-f参数来指定清晰度，-p来下载整个播放列表。Press Enter after the input is completed." 12 50 --title "请在地址栏内输入 视频链接" 3>&1 1>&2 2>&3)

	# echo ${AnnieVideoURL} >> ${HOME}/.video_history
	if [ "$(echo ${AnnieVideoURL} | grep 'b23.tv')" ]; then
		AnnieVideoURL="$(echo ${AnnieVideoURL} | sed 's@b23.tv@www.bilibili.com/video@')"
	elif [ "$(echo ${AnnieVideoURL} | grep '^BV')" ]; then
		AnnieVideoURL="$(echo ${AnnieVideoURL} | sed 's@^BV@https://www.bilibili.com/video/&@')"
	fi
	#当未添加http时，将自动修复。
	if [ "$(echo ${AnnieVideoURL} | grep -E 'www|com')" ] && [ ! "$(echo ${AnnieVideoURL} | grep 'http')" ]; then
		ls
		AnnieVideoURL=$(echo ${AnnieVideoURL} | sed 's@www@http://&@')
	fi
	echo ${AnnieVideoURL}
	echo "正在解析中..."
	echo "Parsing ..."
	#if [ ! $(echo ${AnnieVideoURL} | grep -E '^BV|^av|^http') ]; then
	#	AnnieVideoURL=$(echo ${AnnieVideoURL} | sed 's@^@http://&@')
	#fi

	annie -i ${AnnieVideoURL}
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		VideoCookies=$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)
		annie -c ${VideoCookies} -d ${AnnieVideoURL}
	else
		annie -d ${AnnieVideoURL}
	fi
	ls -lAth ./ | head -n 3
	echo "视频文件默认下载至$(pwd)"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	download_videos
}
###########
python_you_get() {
	if [ ! $(command -v you-get) ]; then
		echo "检测到您尚未安装you-get,将为您跳转至更新管理中心"
		upgrade_video_download_tool
		exit 0
	fi

	if [ ! -e "${HOME}/sd/Download/Videos" ]; then
		mkdir -p ${HOME}/sd/Download/Videos
	fi

	cd ${HOME}/sd/Download/Videos

	AnnieVideoURL=$(whiptail --inputbox "Please enter a url.请输入视频链接,例如https://www.bilibili.com/video/av号,您可以在url前加--format参数来指定清晰度，-l来下载整个播放列表。Press Enter after the input is completed." 12 50 --title "请在地址栏内输入 视频链接" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		download_videos
	fi
	echo ${AnnieVideoURL}
	echo "正在解析中..."
	echo "Parsing ..."
	you-get -i ${AnnieVideoURL}
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		VideoCookies=$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)
		you-get -c ${VideoCookies} -d ${AnnieVideoURL}
	else
		you-get -d ${AnnieVideoURL}
	fi
	ls -lAth ./ | head -n 3
	echo "视频文件默认下载至$(pwd)"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	download_videos
}
############
python_youtube_dl() {
	if [ ! $(command -v youtube-dl) ]; then
		echo "检测到您尚未安装youtube-dl,将为您跳转至更新管理中心"
		upgrade_video_download_tool
		exit 0
	fi

	if [ ! -e "${HOME}/sd/Download/Videos" ]; then
		mkdir -p ${HOME}/sd/Download/Videos
	fi

	cd ${HOME}/sd/Download/Videos

	AnnieVideoURL=$(whiptail --inputbox "Please enter a url.请输入视频链接,例如https://www.bilibili.com/video/av号,您可以在url前加--yes-playlist来下载整个播放列表。Press Enter after the input is completed." 12 50 --title "请在地址栏内输入 视频链接" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		download_videos
	fi
	echo ${AnnieVideoURL}
	echo "正在解析中..."
	echo "Parsing ..."
	youtube-dl -e --get-description --get-duration ${AnnieVideoURL}
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		VideoCookies=$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)
		youtube-dl --merge-output-format mp4 --all-subs --cookies ${VideoCookies} -v ${AnnieVideoURL}
	else
		youtube-dl --merge-output-format mp4 --all-subs -v ${AnnieVideoURL}
	fi
	ls -lAth ./ | head -n 3
	echo "视频文件默认下载至$(pwd)"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	download_videos
}
#############
check_file_selection_items() {
	if [[ -d "${SELECTION}" ]]; then # 目录是否已被选择
		tmoe_file "$1" "${SELECTION}"
	elif [[ -f "${SELECTION}" ]]; then # 文件已被选择？
		if [[ ${SELECTION} == *${FILE_EXT_01} ]] || [[ ${SELECTION} == *${FILE_EXT_02} ]]; then
			# 检查文件扩展名
			if (whiptail --title "Confirm Selection" --yes-button "Confirm确认" --no-button "Back返回" --yesno "目录: $CURRENT_DIR\n文件: ${SELECTION}" 0 0); then
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
		DIR_LIST=$(ls -lhp | awk -F ' ' ' { print $9 " " $5 } ')
	else
		cd "$2"
		DIR_LIST=$(ls -lhp | awk -F ' ' ' { print $9 " " $5 } ')
	fi
	###########################
	CURRENT_DIR=$(pwd)
	# 检测是否为根目录
	if [ "$CURRENT_DIR" == "/" ]; then
		SELECTION=$(whiptail --title "$1" \
			--menu "${MENU_01}\n$CURRENT_DIR" 0 0 0 \
			--cancel-button Cancel取消 \
			--ok-button Select选择 $DIR_LIST 3>&1 1>&2 2>&3)
	else
		SELECTION=$(whiptail --title "$1" \
			--menu "${MENU_01}\n$CURRENT_DIR" 0 0 0 \
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
tmoe_file_manager() {
	#START_DIR="/root"
	#FILE_EXT_01='tar.gz'
	#FILE_EXT_02='tar.xz'
	TMOE_TITLE="${FILE_EXT_01} & ${FILE_EXT_02} 文件选择Tmoe-linux管理器"
	MENU_01="请使用方向键和回车键进行操作"
	########################################
	#-bak_rootfs.tar.xz
	###################
	#tmoe_file
	###############
	tmoe_file "$TMOE_TITLE" "$START_DIR"

	EXIT_STATUS=$?
	if [ ${EXIT_STATUS} -eq 0 ]; then
		if [ "${SELECTION}" == "" ]; then
			echo "检测到您取消了操作,User Pressed Esc with No File Selection"
		else
			whiptail --msgbox "文件属性 :  $(ls -lh ${FILE_NAME})\n路径 : ${FILE_PATH}" 0 0
			COOKIE_FILE_PATH="${CURRENT_DIR}/${SELECTION}"
			#uncompress_tar_file
		fi
	else
		echo "检测到您取消了操作，没有文件被选择,with No File Selected."
		#press_enter_to_return
	fi
}
###########
where_is_start_dir() {
	if [ -d "/root/sd" ]; then
		START_DIR='/root/sd/Download'
	elif [ -d "/sdcard" ]; then
		START_DIR='/sdcard/'
	else
		START_DIR="$(pwd)"
	fi
	tmoe_file_manager
}
###################################
cookies_readme() {
	cat <<-'EndOFcookies'
		若您需要下载大会员视频，则需要指定cookie文件路径。
		加载cookie后，即使您不是大会员，也能提高部分网站的下载速度。
		cookie文件包含了会员身份认证凭据，请勿将该文件泄露出去！
		一个cookie文件可以包含多个网站的cookies，您只需要手动将包含cookie数据的纯文本复制至cookies.txt文件即可。
		您需要安装浏览器扩展插件来导出cookie，部分插件还需手动配置导出格式为Netscape，并将后缀名修改为txt
		对于不同平台(windows、linux和macos)导出的cookie文件，如需跨平台加载，则需要转换为相应系统的换行符。
		浏览器商店中包含多个相关扩展插件，但不同插件导出的cookie文件可能存在兼容性的差异。
		例如火狐扩展cookies-txt（适用于you-get v0.4.1432，不适用于annie v0.9.8）
		https://addons.mozilla.org/zh-CN/firefox/addon/cookies-txt/
		再次提醒，cookie非常重要!
		希望您能仔细甄别，堤防恶意插件。
		同时希望您能够了解，将cookie文件泄露出去等同于将账号泄密！
		请妥善保管好该文件及相关数据！
	EndOFcookies
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		echo "您当前的cookie路径为$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)"
	fi
	RETURN_TO_WHERE='download_videos'
	do_you_want_to_continue
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		COOKIESTATUS="检测到您已启用加载cookie功能"
		CurrentCOOKIESpath="您当前的cookie路径为$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)"
	else
		COOKIESTATUS="检测到cookie处于禁用状态"
	fi

	mkdir -p "${HOME}/.config/tmoe-linux"
	if (whiptail --title "modify cookie path and status" --yes-button '指定cookie file' --no-button 'disable禁用cookie' --yesno "您想要修改哪些配置信息？${COOKIESTATUS} Which configuration do you want to modify?" 9 50); then
		FILE_EXT_01='txt'
		FILE_EXT_02='sqlite'
		where_is_start_dir
		if [ -z ${COOKIE_FILE_PATH} ]; then
			echo "没有指定有效的文件，请重新选择"
		else
			echo ${COOKIE_FILE_PATH} >"${HOME}/.config/tmoe-linux/videos.cookiepath"
			echo "您当前的cookie文件路径为${COOKIE_FILE_PATH}"
			ls -lah ${COOKIE_FILE_PATH}
		fi
	else
		rm -f "${HOME}/.config/tmoe-linux/videos.cookiepath"
		echo "已禁用加载cookie功能"
	fi
	press_enter_to_return
	download_videos
}
#########
check_latest_video_download_tool_version() {
	echo "正在${YELLOW}检测${RESET}${GREEN}版本信息${RESET}..."
	cat <<-ENDofnote
		如需${YELLOW}卸载${RESET}${BLUE}annie${RESET},请输${GREEN}rm /usr/local/bin/annie${RESET}
		如需${YELLOW}卸载${RESET}${BLUE}you-get${RESET},请输${GREEN}pip3 uninstall you-get${RESET}
		如需${YELLOW}卸载${RESET}${BLUE}youtube-dl${RESET},请输${GREEN}pip3 uninstall youtube-dl${RESET}
	ENDofnote

	LATEST_ANNIE_VERSION=$(curl -LfsS https://gitee.com/mo2/annie/raw/linux_amd64/annie_version.txt | head -n 1)

	####################
	if [ $(command -v you-get) ]; then
		YouGetVersion=$(you-get -V 2>&1 | head -n 1 | cut -d ':' -f 2 | cut -d ',' -f 1 | awk -F ' ' '$0=$NF')
	else
		YouGetVersion='您尚未安装you-get'
	fi
	#LATEST_YOU_GET_VERSION=$(curl -LfsS https://github.com/soimort/you-get/releases | grep 'muted-link css-truncate' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f 5)

	#######################
	if [ $(command -v youtube-dl) ]; then
		YOTUBEdlVersion=$(youtube-dl --version 2>&1 | head -n 1)
	else
		YOTUBEdlVersion='您尚未安装youtube-dl'
	fi
	#LATEST_YOUTUBE_DL_VERSION=$(curl -LfsS https://github.com/ytdl-org/youtube-dl/releases | grep 'muted-link css-truncate' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f 5)
	LATEST_YOUTUBE_DL_VERSION=$(curl -LfsS https://pypi.tuna.tsinghua.edu.cn/simple/youtube-dl/ | grep .whl | tail -n 1 | cut -d '=' -f 3 | cut -d '>' -f 2 | cut -d '<' -f 1 | cut -d '-' -f 2)
	##################
	cat <<-ENDofTable
		╔═══╦══════════╦═══════════════════╦════════════════════
		║   ║          ║                   ║                    
		║   ║ software ║ 最新版本          ║   本地版本 🎪
		║   ║          ║latest version✨   ║  Local version     
		║---║----------║-------------------║--------------------
		║ 1 ║   annie  ║                   ║  ${AnnieVersion}
		║   ║          ║${LATEST_ANNIE_VERSION}║
		║---║----------║-------------------║--------------------
		║   ║          ║                   ║ ${YouGetVersion}                   
		║ 2 ║ you-get  ║                   ║  
		║---║----------║-------------------║--------------------
		║   ║          ║                   ║  ${YOTUBEdlVersion}                  
		║ 3 ║youtube-dl║${LATEST_YOUTUBE_DL_VERSION}           ║  

		annie: github.com/iawia002/annie
		you-get : github.com/soimort/you-get
		youtube-dl：github.com/ytdl-org/youtube-dl
	ENDofTable
	#对原开发者iawia002的代码进行自动编译
	echo "为避免加载超时，故${RED}隐藏${RESET}了部分软件的${GREEN}版本信息。${RESET}"
	echo "annie将于每月1号凌晨4点自动编译并发布最新版"
	echo "您可以按${GREEN}回车键${RESET}来${BLUE}获取更新${RESET}，亦可前往原开发者的仓库来${GREEN}手动下载${RESET}新版"
}
##################
upgrade_video_download_tool() {
	cat <<-'ENDofTable'
		╔═══╦════════════╦════════╦════════╦═════════╦
		║   ║     💻     ║    🎬  ║   🌁   ║   📚   ║
		║   ║  website   ║ Videos ║ Images ║Playlist ║
		║   ║            ║        ║        ║         ║
		║---║------------║--------║--------║---------║
		║ 1 ║  bilibili  ║  ✓     ║        ║   ✓     ║
		║   ║            ║        ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 2 ║  tiktok    ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 3 ║ youku      ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 4 ║ youtube    ║  ✓     ║        ║   ✓     ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 5 ║ iqiyi      ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 6 ║  weibo     ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║ netease    ║        ║        ║         ║
		║ 7 ║ 163music   ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║ tencent    ║        ║        ║         ║
		║ 8 ║ video      ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 9 ║ instagram  ║  ✓     ║  ✓     ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║10 ║  twitter   ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║11 ║ douyu      ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║12 ║pixivision  ║        ║  ✓     ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║13 ║ pornhub    ║  ✓     ║        ║         ║

	ENDofTable

	if [ -e "/usr/local/bin/annie" ]; then
		#AnnieVersion=$(annie -v | cut -d ':' -f 2 | cut -d ',' -f 1 | awk -F ' ' '$0=$NF')
		AnnieVersion=$(cat ~/.config/tmoe-linux/annie_version.txt | head -n 1)
		check_latest_video_download_tool_version

	else
		AnnieVersion='您尚未安装annie'
		echo "检测到您${RED}尚未安装${RESET}annie，跳过${GREEN}版本检测！${RESET}"
	fi

	echo "按${GREEN}回车键${RESET}将同时更新${YELLOW}annie、you-get和youtube-dl${RESET}"
	echo 'Press Enter to update'
	RETURN_TO_WHERE='download_videos'
	do_you_want_to_continue
	NON_DEBIAN=false
	DEPENDENCY_01=""
	DEPENDENCY_02=""

	if [ ! $(command -v python3) ]; then
		DEPENDENCY_01="${DEPENDENCY_01} python3"
	fi

	if [ ! $(command -v ffmpeg) ]; then
		if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "arm64" ]; then
			cd /tmp
			rm -rf .FFMPEGTEMPFOLDER
			git clone -b linux_$(uname -m) --depth=1 https://gitee.com/mo2/ffmpeg.git ./.FFMPEGTEMPFOLDER
			cd /usr/local/bin
			tar -Jxvf /tmp/.FFMPEGTEMPFOLDER/ffmpeg.tar.xz ffmpeg
			chmod +x ffmpeg
			rm -rf /tmp/.FFMPEGTEMPFOLDER
		else
			DEPENDENCY_01="${DEPENDENCY_01} ffmpeg"
		fi
	fi
	#检测两次
	if [ ! $(command -v ffmpeg) ]; then
		if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "arm64" ]; then
			DEPENDENCY_01="${DEPENDENCY_01} ffmpeg"
		fi
	fi

	if [ ! $(command -v pip3) ]; then
		if [ "${LINUX_DISTRO}" = 'debian' ]; then
			apt update 2>/dev/null
			apt install -y python3 python3-distutils 2>/dev/null
		else
			${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
		fi
		cd /tmp
		curl -LO https://gitee.com/mo2/get-pip/raw/master/.get-pip.tar.gz.00
		curl -LO https://gitee.com/mo2/get-pip/raw/master/.get-pip.tar.gz.01
		cat .get-pip.tar.gz.* >.get-pip.tar.gz
		tar -zxvf .get-pip.tar.gz
		python3 get-pip.py -i https://pypi.tuna.tsinghua.edu.cn/simple
		rm -f .get-pip.tar.gz* get-pip.py
	fi
	#检测两次
	if [ ! $(command -v pip3) ]; then
		if [ "${LINUX_DISTRO}" = 'debian' ]; then
			DEPENDENCY_02="${DEPENDENCY_02} python3-pip"
		else
			DEPENDENCY_02="${DEPENDENCY_02} python-pip"
		fi
	fi

	if [ ! -z "${DEPENDENCY_01}" ] && [ ! -z "${DEPENDENCY_02}" ]; then
		beta_features_quick_install
	fi

	cd /tmp
	if [ ! $(command -v pip3) ]; then
		curl -LO https://gitee.com/mo2/get-pip/raw/master/.get-pip.tar.gz.00
		curl -LO https://gitee.com/mo2/get-pip/raw/master/.get-pip.tar.gz.01
		cat .get-pip.tar.gz.* >.get-pip.tar.gz
		tar -zxvf .get-pip.tar.gz
		if [ -f "get-pip.py" ]; then
			rm -f .get-pip.tar.gz*
		else
			curl -LO https://bootstrap.pypa.io/get-pip.py
		fi
		python3 get-pip.py -i https://pypi.tuna.tsinghua.edu.cn/simple
		rm -f get-pip.py
	fi

	rm -rf ./.ANNIETEMPFOLDER
	git clone -b linux_${ARCH_TYPE} --depth=1 https://gitee.com/mo2/annie ./.ANNIETEMPFOLDER
	cd ./.ANNIETEMPFOLDER
	tar -Jxvf annie.tar.xz
	chmod +x annie
	mkdir -p ~/.config/tmoe-linux/
	mv -f annie_version.txt ~/.config/tmoe-linux/
	mv -f annie /usr/local/bin/
	annie -v
	cd ..
	rm -rf ./.ANNIETEMPFOLDER
	#mkdir -p ${HOME}/.config
	pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
	pip3 install pip -U -i https://pypi.tuna.tsinghua.edu.cn/simple 2>/dev/null
	pip3 install you-get -U -i https://pypi.tuna.tsinghua.edu.cn/simple
	you-get -V
	pip3 install youtube-dl -U -i https://pypi.tuna.tsinghua.edu.cn/simple
	youtube-dl -v 2>&1 | grep version
	echo "更新完毕，如需${YELLOW}卸载${RESET}annie,请输${YELLOW}rm /usr/local/bin/annie${RESET}"
	echo "如需卸载you-get,请输${YELLOW}pip3 uninstall you-get${RESET}"
	echo "如需卸载youtube-dl,请输${YELLOW}pip3 uninstall youtube-dl${RESET}"
	echo 'Press Enter to start annie'
	echo "${YELLOW}按回车键启动annie。${RESET}"
	read
	golang_annie
}
##################
which_vscode_edition() {
	ps -e >/dev/null 2>&1 || VSCODEtips=$(echo "检测到您无权读取/proc分区的部分内容，请选择Server版，或使用XSDL打开VSCode本地版")
	VSCODE_EDITION=$(whiptail --title "Visual Studio Code" --menu \
		"${VSCODEtips} Which edition do you want to install" 15 60 5 \
		"1" "VS Code Server(web版)" \
		"2" "VS Codium" \
		"3" "VS Code OSS" \
		"4" "Microsoft Official(x64,官方版)" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${VSCODE_EDITION}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	##############################
	if [ "${VSCODE_EDITION}" == '1' ]; then
		if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "x86_64" ]; then
			install_vscode_server
		else
			echo "非常抱歉，Tmoe-linux的开发者未对您的架构进行适配。"
			echo "请选择其它版本"
			arch_does_not_support
			which_vscode_edition
		fi
	fi
	##############################
	if [ "${VSCODE_EDITION}" == '2' ]; then
		install_vscodium
	fi
	##############################
	if [ "${VSCODE_EDITION}" == '3' ]; then
		install_vscode_oss
	fi
	##############################
	if [ "${VSCODE_EDITION}" == '4' ]; then
		install_vscode_official
	fi
	#########################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
#################################
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
		whiptail --title "CONFIGURE VSCODE_SERVER" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
			"1" "upgrade code-server更新/升级" \
			"2" "password 设定密码" \
			"3" "stop 停止" \
			"4" "remove 卸载/移除" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${CODE_SERVER_OPTION}" == '0' ]; then
		which_vscode_edition
	fi
	##############################
	if [ "${CODE_SERVER_OPTION}" == '1' ]; then
		pkill node
		#service code-server stop 2>/dev/null
		vscode_server_upgrade
	fi
	##############################
	if [ "${CODE_SERVER_OPTION}" == '2' ]; then
		vscode_server_password
	fi
	##############################
	if [ "${CODE_SERVER_OPTION}" == '3' ]; then
		echo "正在停止服务进程..."
		echo "Stopping..."
		pkill node
		#service code-server stop 2>/dev/null
		#service vscode_server status
	fi
	##############################
	if [ "${CODE_SERVER_OPTION}" == '4' ]; then
		vscode_server_remove
	fi
	########################################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	configure_vscode_server
}
##############
vscode_server_upgrade() {
	echo "正在检测版本信息..."
	if [ -e "/usr/local/bin/code-server-data/code-server" ]; then
		LOCAL_VSCODE_VERSION=$(code-server --version | cut -d ' ' -f 1)
	else
		LOCAL_VSCODE_VERSION='您尚未安装code-server'
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
	grep '/tmp/startcode.tmp' /root/.bashrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" /root/.bashrc
	grep '/tmp/startcode.tmp' /root/.zshrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" /root/.zshrc
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
		cd ${cur}
		rm -rf /tmp/.VSCODE_SERVER_TEMP_FOLDER
	elif [ "${ARCH_TYPE}" = "amd64" ]; then
		mkdir -p .VSCODE_SERVER_TEMP_FOLDER
		cd .VSCODE_SERVER_TEMP_FOLDER
		LATEST_VSCODE_SERVER_LINK=$(curl -Lv https://api.github.com/repos/cdr/code-server/releases | grep 'x86_64' | grep browser_download_url | grep linux | head -n 1 | awk -F ' ' '$0=$NF' | cut -d '"' -f 2)
		curl -Lvo .VSCODE_SERVER.tar.gz ${LATEST_VSCODE_SERVER_LINK}
		tar -zxvf .VSCODE_SERVER.tar.gz
		VSCODE_FOLDER_NAME=$(ls -l ./ | grep '^d' | awk -F ' ' '$0=$NF')
		mv ${VSCODE_FOLDER_NAME} code-server-data
		rm -rvf /usr/local/bin/code-server-data /usr/local/bin/code-server
		mv code-server-data /usr/local/bin/
		ln -sf /usr/local/bin/code-server-data/code-server /usr/local/bin/code-server
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		vscode_server_password
	fi

	if [ ! -e "${HOME}/.profile" ]; then
		echo '' >>~/.profile
	fi
	sed -i '/export PASSWORD=/d' ~/.profile
	sed -i '/export PASSWORD=/d' ~/.zshrc
	sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.profile
	sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.zshrc
	export PASSWORD=${TARGET_USERPASSWD}
	vscode_server_restart
	########################################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	configure_vscode_server
	#此处的返回步骤并非多余
}
############
vscode_server_restart() {
	echo "即将为您启动code-server,请复制密码，并在浏览器中粘贴。"
	echo "The VSCode server is starting, please copy the password and paste it in your browser."
	echo "您之后可以输code-server来启动Code Server."
	echo 'You can type "code-server" to start Code Server.'
	/usr/local/bin/code-server-data/code-server &
	echo "正在为您启动code-server，本机默认访问地址为localhost:8080"
	echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):8080
	echo "您可以输${YELLOW}pkill node${RESET}来停止进程"
}
#############
vscode_server_password() {
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，操作取消"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		configure_vscode_server
	fi
	sed -i '/export PASSWORD=/d' ~/.profile
	sed -i '/export PASSWORD=/d' ~/.zshrc
	sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.profile
	sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.zshrc
	export PASSWORD=${TARGET_USERPASSWD}
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
	sed -i '/export PASSWORD=/d' ~/.profile
	sed -i '/export PASSWORD=/d' ~/.zshrc
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
		#echo 'codium --user-data-dir=${HOME}/.config/VSCodium'
		echo "codium --user-data-dir=${HOME}"
		echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} codium"
	elif [ -e "/usr/local/bin/vscodium-data/codium" ]; then
		echo "检测到您已安装VSCodium,请输codium --no-sandbox启动"
		echo "如需卸载，请手动输rm -rvf /usr/local/bin/vscodium-data/ /usr/local/bin/vscodium"
	fi

	if [ $(command -v codium) ]; then
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	fi

	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		LatestVSCodiumLink="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${ARCH_TYPE} | grep -v '.sha256' | grep '.deb' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		curl -Lvo 'VSCodium.deb' "https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
		apt install -y ./VSCodium.deb
		rm -vf VSCodium.deb
		#echo '安装完成,请输codium --user-data-dir=${HOME}/.config/VSCodium启动'
		echo "安装完成,请输codium --user-data-dir=${HOME}启动"
	else
		LatestVSCodiumLink="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${CodiumARCH} | grep -v '.sha256' | grep '.tar' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		curl -Lvo 'VSCodium.tar.gz' "https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
		mkdir -p /usr/local/bin/vscodium-data
		tar -zxvf VSCodium.tar.gz -C /usr/local/bin/vscodium-data
		rm -vf VSCodium.tar.gz
		ln -sf /usr/local/bin/vscodium-data/codium /usr/local/bin/codium
		echo "安装完成，输codium --no-sandbox启动"
	fi
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	which_vscode_edition
}
########################
install_vscode_oss() {
	if [ -e "/usr/bin/code-oss" ]; then
		echo "检测到您已安装VSCode OSS,请手动输以下命令启动"
		#echo 'code-oss --user-data-dir=${HOME}/.config/Code\ -\ OSS\ \(headmelted\)'
		echo "code-oss --user-data-dir=${HOME}"
		echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} code-oss"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	fi

	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		apt update
		apt install -y gpg
		bash -c "$(wget -O- https://code.headmelted.com/installers/apt.sh)"
	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		. <(wget -O- https://code.headmelted.com/installers/yum.sh)
	else
		echo "检测到您当前使用的可能不是deb系或红帽系发行版，跳过安装"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	fi
	echo "安装完成,请手动输以下命令启动"
	echo "code-oss --user-data-dir=${HOME}"
	echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} code-oss"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	which_vscode_edition
}
#######################
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
		echo 'code --user-data-dir=${HOME}'
		echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} code"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	elif [ -e "/usr/local/bin/vscode-data/code" ]; then
		echo "检测到您已安装VSCode,请输code --no-sandbox启动"
		echo "如需卸载，请手动输rm -rvf /usr/local/bin/VSCode-linux-x64/ /usr/local/bin/code"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	fi

	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		curl -Lvo 'VSCODE.deb' "https://go.microsoft.com/fwlink/?LinkID=760868"
		apt install -y ./VSCODE.deb
		rm -vf VSCODE.deb
		echo "安装完成,请输code --user-data-dir=${HOME}启动"

	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		curl -Lvo 'VSCODE.rpm' "https://go.microsoft.com/fwlink/?LinkID=760867"
		rpm -ivh ./VSCODE.rpm
		rm -vf VSCODE.rpm
		echo "安装完成,请输code --user-data-dir=${HOME}启动"
	else
		curl -Lvo 'VSCODE.tar.gz' "https://go.microsoft.com/fwlink/?LinkID=620884"
		#mkdir -p /usr/local/bin/vscode-data
		tar -zxvf VSCODE.tar.gz -C /usr/local/bin/

		rm -vf VSCode.tar.gz
		ln -sf /usr/local/bin/VSCode-linux-x64/code /usr/local/bin/code
		echo "安装完成，输code --no-sandbox启动"
	fi
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	which_vscode_edition
}
###############################
###############################
modify_other_vnc_conf() {
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
		tmoe_linux_tool_menu
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '1' ]; then
		modify_vnc_pulse_audio
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
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		modify_other_vnc_conf
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '3' ]; then
		nano ~/.vnc/xstartup
		stopvnc 2>/dev/null
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		modify_other_vnc_conf
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '4' ]; then
		nano_startvnc_manually
	fi
	#########################
	if [ "${MODIFYOTHERVNCCONF}" == '5' ]; then
		fix_vnc_dbus_launch
	fi
	##########
}
#########################
modify_vnc_pulse_audio() {
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
		modify_other_vnc_conf
	else
		modify_other_vnc_conf
	fi
}
##################
nano_startvnc_manually() {
	echo '您可以手动修改vnc的配置信息'
	echo 'If you want to modify the resolution, please change the 1440x720 (default resolution，landscape) to another resolution, such as 1920x1080 (vertical screen).'
	echo '若您想要修改分辨率，请将默认的1440x720（横屏）改为其它您想要的分辨率，例如720x1440（竖屏）。'
	echo "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"
	echo '改完后按Ctrl+S保存，Ctrl+X退出。'
	RETURN_TO_WHERE='modify_other_vnc_conf'
	do_you_want_to_continue
	nano /usr/local/bin/startvnc || nano $(command -v startvnc)
	echo "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"

	stopvnc 2>/dev/null
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	modify_other_vnc_conf
}
#############################################
#############################################
ubuntu_install_chromium_browser() {
	if ! grep -q '^deb.*bionic-update' "/etc/apt/sources.list"; then
		if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "i386" ]; then
			sed -i '$ a\deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
		else
			sed -i '$ a\deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
		fi
		DEPENDENCY_01="chromium-browser/bionic-updates"
		DEPENDENCY_02="chromium-browser-l10n/bionic-updates"
	fi
}
#########
fix_chromium_root_ubuntu_no_sandbox() {
	sed -i 's/chromium-browser %U/chromium-browser --no-sandbox %U/g' /usr/share/applications/chromium-browser.desktop
	grep 'chromium-browser' /etc/profile || sed -i '$ a\alias chromium="chromium-browser --no-sandbox"' /etc/profile
}
#####################
fix_chromium_root_no_sandbox() {
	sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
	grep 'chromium' /etc/profile || sed -i '$ a\alias chromium="chromium --no-sandbox"' /etc/profile
}
#################
install_chromium_browser() {
	echo "${YELLOW}妾身就知道你没有看走眼！${RESET}"
	echo '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium --no-sandbox"'
	echo "1s后将自动开始安装"
	sleep 1
	NON_DEBIAN='false'
	DEPENDENCY_01="chromium"
	DEPENDENCY_02="chromium-l10n"

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		#新版Ubuntu是从snap商店下载chromium的，为解决这一问题，将临时换源成ubuntu 18.04LTS.
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			ubuntu_install_chromium_browser
		fi
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		DEPENDENCY_01="www-client/chromium"
		DEPENDENCY_02=""
	#emerge -avk www-client/google-chrome-unstable
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02=""
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_02="chromium-plugin-widevinecdm chromium-ffmpeg-extra"
	fi
	beta_features_quick_install
	#####################
	if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
		sed -i '$ d' "/etc/apt/sources.list"
		apt-mark hold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg-extra
		apt update
	fi
	####################
	echo "请问您是否需要关闭沙盒模式？"
	echo "若您需要以root权限运行chromium，则需要关闭，否则请保持开启状态。"
	echo "${YELLOW}Do you need to turn off the sandbox mode?[Y/n]${RESET}"
	echo "Press enter to close this mode,type n to cancel."
	echo "按${YELLOW}回车${RESET}键${RED}关闭${RESET}该模式，输${YELLOW}n${RESET}取消"
	read opt
	case $opt in
	y* | Y* | "")
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			fix_chromium_root_ubuntu_no_sandbox
		else
			fix_chromium_root_no_sandbox
		fi
		;;
	n* | N*)
		echo "skipped."
		;;
	*)
		echo "Invalid choice. skipped."
		;;
	esac
}
############
install_firefox_esr_browser() {
	echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
	echo "${YELLOW} “谢谢您选择了我，我一定会比姐姐向您提供更好的上网服务的！”╰(*°▽°*)╯火狐ESR娘坚定地说道。 ${RESET}"
	echo "1s后将自动开始安装"
	sleep 1

	NON_DEBIAN='false'
	DEPENDENCY_01="firefox-esr"
	DEPENDENCY_02="firefox-esr-l10n-zh-cn"

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			add-apt-repository -y ppa:mozillateam/ppa
			DEPENDENCY_02="firefox-esr-locale-zh-hans"
		fi
		#################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02="firefox-esr-i18n-zh-cn"
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		DEPENDENCY_01='www-client/firefox'
		DEPENDENCY_02=""
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="MozillaFirefox-esr"
		DEPENDENCY_02="MozillaFirefox-esr-translations-common"
	fi
	beta_features_quick_install
	#################
	if [ ! $(command -v firefox-esr) ]; then
		echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫姐姐来代替了。${RESET}"
		echo 'Press Enter to confirm.'
		RETURN_TO_WHERE='install_browser'
		do_you_want_to_continue
		install_firefox_browser
	fi
}
#####################
install_firefox_browser() {
	echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
	echo " ${YELLOW}“谢谢您选择了我，我一定会比妹妹向您提供更好的上网服务的！”╰(*°▽°*)╯火狐娘坚定地说道。${RESET}"
	echo "1s后将自动开始安装"
	sleep 1
	NON_DEBIAN='false'
	DEPENDENCY_01="firefox"
	DEPENDENCY_02="firefox-l10n-zh-cn"

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			DEPENDENCY_02="firefox-locale-zh-hans"
		fi
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02="firefox-i18n-zh-cn"
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_02="firefox-x11"
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		DEPENDENCY_01="www-client/firefox-bin"
		DEPENDENCY_02=""
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="MozillaFirefox"
		DEPENDENCY_02="MozillaFirefox-translations-common"
	fi
	beta_features_quick_install
	################
	if [ ! $(command -v firefox) ]; then
		echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫妹妹ESR来代替了。${RESET}"
		RETURN_TO_WHERE='install_browser'
		do_you_want_to_continue
		install_firefox_esr_browser
	fi
}
#####################
install_browser() {
	if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno "建议在安装完图形界面后，再来选择哦！(　o=^•ェ•)o　┏━┓\n我是火狐娘，选我啦！♪(^∇^*) \n妾身是chrome娘的姐姐chromium娘，妾身和那些妖艳的货色不一样，选择妾身就没错呢！(✿◕‿◕✿)✨\n请做出您的选择！ " 15 50); then

		if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox-ESR" --no-button "Firefox" --yesno " 我是firefox，其实我还有个妹妹叫firefox-esr，您是选我还是选esr?\n “(＃°Д°)姐姐，我可是什么都没听你说啊！” 躲在姐姐背后的ESR瑟瑟发抖地说。\n✨请做出您的选择！ " 15 50); then
			#echo 'esr可怜巴巴地说道:“我也想要得到更多的爱。”  '
			#什么乱七八糟的，2333333戏份真多。
			install_firefox_esr_browser
		else
			install_firefox_browser
		fi
		echo "若无法正常加载HTML5视频，则您可能需要安装火狐扩展${YELLOW}User-Agent Switcher and Manager${RESET}，并将浏览器UA修改为windows版chrome"
	else
		install_chromium_browser
	fi
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	tmoe_linux_tool_menu
}
######################################################
######################################################
install_gui() {
	cd /tmp
	echo 'lxde预览截图'
	#curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png' | catimg -
	if [ ! -f 'LXDE_BUSYeSLZRqq3i3oM.png' ]; then
		curl -sLo 'LXDE_BUSYeSLZRqq3i3oM.png' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png'
	fi
	catimg 'LXDE_BUSYeSLZRqq3i3oM.png'

	echo 'mate预览截图'
	#curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/1frRp1lpOXLPz6mO.jpg' | catimg -
	if [ ! -f 'MATE_1frRp1lpOXLPz6mO.jpg' ]; then
		curl -sLo 'MATE_1frRp1lpOXLPz6mO.jpg' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/1frRp1lpOXLPz6mO.jpg'
	fi
	catimg 'MATE_1frRp1lpOXLPz6mO.jpg'
	echo 'xfce预览截图'

	if [ ! -f 'XFCE_a7IQ9NnfgPckuqRt.jpg' ]; then
		curl -sLo 'XFCE_a7IQ9NnfgPckuqRt.jpg' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/a7IQ9NnfgPckuqRt.jpg'
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
			curl -Lo 'Iosevka.tar.xz' 'https://gitee.com/mo2/Termux-zsh/raw/p10k/Iosevka.tar.xz'
			tar -xvf 'Iosevka.tar.xz'
			rm -f 'Iosevka.tar.xz'
			mv -f font.ttf '/usr/share/fonts/Iosevka.ttf'
		fi
		cd /usr/share/fonts/
		mkfontscale 2>/dev/null
		mkfontdir 2>/dev/null
		fc-cache 2>/dev/null
	fi
	#curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/a7IQ9NnfgPckuqRt.jpg' | catimg -
	#echo "建议缩小屏幕字体，并重新加载图片，以获得更优的显示效果。"
	echo "按${GREEN}回车键${RESET}${RED}选择${RESET}您需要${YELLOW}安装${RESET}的${BLUE}图形桌面环境${RESET}"
	RETURN_TO_WHERE="tmoe_linux_tool_menu"
	do_you_want_to_continue
	standand_desktop_install
}
########################
preconfigure_gui_dependecies_02() {
	NON_DEBIAN='false'
	DEPENDENCY_02="tigervnc"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_02="dbus-x11 fonts-noto-cjk tightvncserver"
		#上面的依赖摆放的位置是有讲究的。
		##############
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_02="tigervnc-server google-noto-sans-cjk-ttc-fonts"
		##################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02="noto-fonts-cjk tigervnc"
		##################
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		DEPENDENCY_02="xorg tigervnc wqy-microhei"
		#################
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		etc-update
		DEPENDENCY_02="media-fonts/wqy-bitmapfont net-misc/tigervnc"
		#################
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_02="tigervnc-x11vnc noto-sans-sc-fonts"
		##################
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_02="curl openssl xvfb dbus-x11 bash font-noto-cjk x11vnc"
		#ca-certificates
		##############
	fi
}
########################
standand_desktop_install() {
	preconfigure_gui_dependecies_02
	INSTALLDESKTOP=$(whiptail --title "单项选择题" --menu \
		"您想要安装哪个桌面？按方向键选择，回车键确认！仅xfce桌面支持在本工具内便捷下载主题。 \n Which desktop environment do you want to install? " 15 60 5 \
		"1" "xfce：兼容性高" \
		"2" "lxde：轻量化桌面" \
		"3" "mate：基于GNOME 2" \
		"4" "Other其它桌面(内测版新功能):lxqt,kde" \
		"0" "我一个都不要 =￣ω￣=" \
		3>&1 1>&2 2>&3)
	##########################
	if [ "$INSTALLDESKTOP" == '1' ]; then
		install_xfce4_desktop
	fi
	##########################
	if [ "$INSTALLDESKTOP" == '2' ]; then
		install_lxde_desktop
	fi
	##########################
	if [ "$INSTALLDESKTOP" == '3' ]; then
		install_mate_desktop
	fi
	##########################
	if [ "$INSTALLDESKTOP" == '4' ]; then
		other_desktop
	fi
	##########################
	if [ "$INSTALLDESKTOP" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	##########################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	tmoe_linux_tool_menu
}
#######################
auto_select_keyboard_layout() {
	echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
	echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
	echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
}
##################
other_desktop() {
	BETA_DESKTOP=$(whiptail --title "Alpha features" --menu \
		"WARNING！本功能仍处于测试阶段,可能无法正常运行。部分桌面依赖systemd,无法在chroot环境中运行\nBeta features may not work properly." 15 60 6 \
		"1" "lxqt" \
		"2" "kde plasma 5" \
		"3" "gnome 3" \
		"4" "cinnamon" \
		"5" "dde (deepin desktop)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${BETA_DESKTOP}" == '0' ]; then
		standand_desktop_install
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '1' ]; then
		install_lxqt_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '2' ]; then
		install_kde_plasma5_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '3' ]; then
		install_gnome3_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '4' ]; then
		install_cinnamon_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '5' ]; then
		install_deepin_desktop
	fi
	##########################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	tmoe_linux_tool_menu
}
#####################
#####################
download_kali_themes_common() {
	mkdir -p /tmp/.kali-themes-common
	cd /tmp/.kali-themes-common
	KaliTHEMElatestLINK="$(curl -L 'https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes/' | grep kali-themes-common | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	curl -Lvo 'kali-themes-common.deb' "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes/${KaliTHEMElatestLINK}"
	busybox ar xv 'kali-themes-common.deb'
	update-icon-caches /usr/share/icons/Flat-Remix-Blue-Dark /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/desktop-base
	cd /
	tar -Jxvf /tmp/.kali-themes-common/data.tar.xz ./usr
	rm -rf /tmp/.kali-themes-common
}
################
configure_xfce4_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
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
	touch /tmp/.Tmoe-XFCE4-Desktop-Detection-FILE
	first_configure_startvnc
}
####################
configure_x11vnc_remote_desktop_session() {
	cd /usr/local/bin/
	cat >startx11vnc <<-EOF
		#!/bin/bash
		#stopvnc 2>/dev/null
		stopx11vnc
		export PULSE_SERVER=127.0.0.1
		export DISPLAY=:1
		/usr/bin/Xvfb :1 -screen 0 1440x720x24 -ac +extension GLX +render -noreset & 
		sleep 1s
		${REMOTE_DESKTOP_SESSION} &
		#export LANG="en_US.UTF8"
		x11vnc -xkb -noxrecord -noxfixes -noxdamage -display :1 -forever -bg -rfbauth \${HOME}/.vnc/passwd -users \$(whoami) -rfbport 5901 -noshm &
		sleep 2s
		echo "正在启动x11vnc服务,本机默认vnc地址localhost:5901"
		echo The LAN VNC address 局域网地址 \$(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):5901
		echo "您可能会经历长达10多秒的黑屏"
		echo "您之后可以输startx11vnc启动，stopx11vnc停止"
	EOF
	cat >stopx11vnc <<-'EOF'
		#!/bin/bash
		pkill dbus
		pkill Xvfb
		pkill pulse
	EOF
	cat >x11vncpasswd <<-'EOF'
		#!/bin/bash
		echo "Configuring x11vnc..."
		echo "正在配置x11vnc server..."
		read -sp "请输入6至8位密码，Please enter the new VNC password: " PASSWORD
		mkdir -p ${HOME}/.vnc
		x11vnc -storepasswd $PASSWORD ${HOME}/.vnc/passwd
	EOF
	chmod +x ./*
	x11vncpasswd
	startx11vnc
}
##########################
kali_xfce4_extras() {
	apt install -y kali-menu
	apt install -y kali-undercover
	apt install -y zenmap
	apt install -y kali-themes-common
	if [ "${ARCH_TYPE}" = "arm64" ] || [ "${ARCH_TYPE}" = "armhf" ]; then
		apt install -y kali-linux-arm
		if [ $(command -v chromium) ]; then
			apt install -y chromium-l10n
			fix_chromium_root_no_sandbox
		fi
		apt search kali-linux
	fi
}
###################
apt_purge_libfprint() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		apt purge -y ^libfprint
		apt clean
		apt autoclean
	fi
}
##################
install_xfce4_desktop() {
	echo '即将为您安装思源黑体(中文字体)、xfce4、xfce4-terminal、xfce4-goodies和tightvncserver等软件包。'
	DEPENDENCY_01="xfce4"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01="xfce4 xfce4-goodies xfce4-terminal"
		dpkg --configure -a
		auto_select_keyboard_layout
		##############
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01="@xfce"
		rm -rf /etc/xdg/autostart/xfce-polkit.desktop
		##################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="xfce4 xfce4-terminal xfce4-goodies"
		##################
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		DEPENDENCY_01="xfce4"
		#################
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		etc-update
		DEPENDENCY_01="xfce4-meta x11-terms/xfce4-terminal"
		#################
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="patterns-xfce-xfce xfce4-terminal"
		###############
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="faenza-icon-theme xfce4 xfce4-terminal"
		REMOTE_DESKTOP_SESSION='startxfce4'
		##############
	fi
	##################
	beta_features_quick_install
	####################
	if [ "${DEBIAN_DISTRO}" = "kali" ]; then
		kali_xfce4_extras
	fi
	apt_purge_libfprint
	#################
	if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
		download_kali_themes_common
	fi

	if [ ! -e "/usr/share/xfce4/terminal/colorschemes/Monokai Remastered.theme" ]; then
		cd /usr/share/xfce4/terminal
		echo "正在配置xfce4终端配色..."
		curl -Lo "colorschemes.tar.xz" 'https://gitee.com/mo2/xfce-themes/raw/terminal/colorschemes.tar.xz'
		tar -Jxvf "colorschemes.tar.xz"
	fi
	#########
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		configure_x11vnc_remote_desktop_session
		configure_startxsdl
	else
		configure_xfce4_xstartup
	fi
}
###############
###############
configure_lxde_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
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
	first_configure_startvnc
}
###############
install_lxde_desktop() {
	echo '即将为您安装思源黑体(中文字体)、lxde-core、lxterminal、tightvncserver。'
	DEPENDENCY_01='lxde'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="lxde-core lxterminal"
		#############
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='@lxde-desktop'
		#############
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='lxde'
		############
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		DEPENDENCY_01='lxde'
		#############
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_01='media-fonts/wqy-bitmapfont lxde-base/lxde-meta'
		##################
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01='noto-sans-sc-fonts patterns-lxde-lxde'
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="fvwm"
		REMOTE_DESKTOP_SESSION='fvwm'
	###################
	fi
	############
	beta_features_quick_install
	apt_purge_libfprint
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		configure_x11vnc_remote_desktop_session
		configure_startxsdl
	else
		configure_lxde_xstartup
	fi
}
###########################
configure_mate_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
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
	first_configure_startvnc
}
############################
install_mate_desktop() {
	echo '即将为您安装思源黑体(中文字体)、tightvncserver、mate-desktop-environment和mate-terminal等软件包'
	DEPENDENCY_01='mate'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		#apt-mark hold gvfs
		apt update
		apt install -y udisks2 2>/dev/null
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			echo "" >/var/lib/dpkg/info/udisks2.postinst
		fi
		#apt-mark hold udisks2
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01='mate-desktop-environment mate-terminal'
		#apt autopurge -y ^libfprint
		apt clean
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='--skip-broken @mate-desktop'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前使用的是${YELLOW}Arch系发行版${RESET}"
		echo "mate-session在远程桌面下可能${RED}无法正常运行${RESET}"
		echo "建议您${BLUE}更换${RESET}其他桌面！"
		echo "按${GREEN}回车键${RESET}${BLUE}继续安装${RESET}"
		echo "${YELLOW}Do you want to continue?[Y/l/x/q/n]${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET},type n to return."
		echo "Type q to install lxqt,type l to install lxde,type x to install xfce."
		echo "按${GREEN}回车键${RESET}${RED}继续${RESET}，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
		echo "输${YELLOW}q${RESET}安装lxqt,输${YELLOW}l${RESET}安装lxde,输${YELLOW}x${RESET}安装xfce"
		read opt
		case $opt in
		y* | Y* | "") ;;

		n* | N*)
			echo "skipped."
			standand_desktop_install
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
			echo "Invalid choice. skipped."
			standand_desktop_install
			#beta_features
			;;
		esac
		DEPENDENCY_01='mate mate-extra'
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_01='mate-base/mate-desktop mate-base/mate'
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01='patterns-mate-mate'
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="mate-desktop-environment"
		REMOTE_DESKTOP_SESSION='mate-session'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		configure_x11vnc_remote_desktop_session
		configure_startxsdl
	else
		configure_mate_xstartup
	fi
}
#############
configure_lxqt_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
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
	first_configure_startvnc
}
######################
#DEPENDENCY_02="dbus-x11 fonts-noto-cjk tightvncserver"
install_lxqt_desktop() {
	DEPENDENCY_01="lxqt"
	echo '即将为您安装思源黑体(中文字体)、lxqt-core、lxqt-config、qterminal和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="lxqt-core lxqt-config qterminal"
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01="@lxqt"
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="lxqt xorg"
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_01="lxqt-base/lxqt-meta"
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="tigervnc-x11vnc patterns-lxqt-lxqt"
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="openbox pcmfm rxvt-unicode tint2"
		REMOTE_DESKTOP_SESSION='openbox'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		configure_x11vnc_remote_desktop_session
		configure_startxsdl
	else
		configure_lxqt_xstartup
	fi
}
####################
configure_kde_plasma5_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
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
	first_configure_startvnc
}
##################
install_kde_plasma5_desktop() {
	DEPENDENCY_01="plasma-desktop"
	echo '即将为您安装思源黑体(中文字体)、kde-plasma-desktop和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="kde-plasma-desktop"
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		#yum groupinstall kde-desktop
		#dnf groupinstall -y "KDE" || yum groupinstall -y "KDE"
		#dnf install -y sddm || yum install -y sddm
		DEPENDENCY_01="@KDE"
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="plasma-desktop phonon-qt5-vnc xorg kdebase sddm sddm-kcm"
		#pacman -S --noconfirm sddm sddm-kcm
		#中文输入法
		#pacman -S fcitx fcitx-rime fcitx-im kcm-fcitx fcitx-sogoupinyin
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		DEPENDENCY_01="kde"
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		PLASMAnoSystemd=$(eselect profile list | grep plasma | grep -v systemd | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2)
		eselect profile set ${PLASMAnoSystemd}
		dispatch-conf
		etc-update
		#emerge -auvDN --with-bdeps=y @world
		DEPENDENCY_01="plasma-desktop plasma-nm plasma-pa sddm konsole"
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="patterns-kde-kde_plasma"
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="plasma-desktop"
		REMOTE_DESKTOP_SESSION='startplasma-x11'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		configure_x11vnc_remote_desktop_session
		configure_startxsdl
	else
		configure_kde_plasma5_xstartup
	fi

}
##################
gnome3_warning() {
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

	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
		echo "若您的宿主机为${BOLD}Android${RESET}系统，则${RED}无法${RESET}${BLUE}保障${RESET}GNOME桌面安装后可以正常运行。"
		RETURN_TO_WHERE='other_desktop'
		do_you_want_to_continue
	fi
	#DEPENDENCY_01="plasma-desktop"
	RETURN_TO_WHERE="other_desktop"
	do_you_want_to_continue
}
###############
configure_gnome3_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
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
	first_configure_startvnc
}
####################
install_gnome3_desktop() {
	gnome3_warning
	DEPENDENCY_01="gnome"
	echo '即将为您安装思源黑体(中文字体)、gnome-session、gnome-menus、gnome-tweak-tool、gnome-shell和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		#aptitude install -y task-gnome-desktop || apt install -y task-gnome-desktop
		#apt install --no-install-recommends xorg gnome-session gnome-menus gnome-tweak-tool gnome-shell || aptitude install -y gnome-core
		DEPENDENCY_01='--no-install-recommends xorg gnome-session gnome-menus gnome-tweak-tool gnome-shell'
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		#yum groupinstall "GNOME Desktop Environment"
		#dnf groupinstall -y "GNOME" || yum groupinstall -y "GNOME"
		DEPENDENCY_01='@GNOME'

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='gnome gnome-extra'

	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		GNOMEnoSystemd=$(eselect profile list | grep gnome | grep -v systemd | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2)
		eselect profile set ${GNOMEnoSystemd}
		#emerge -auvDN --with-bdeps=y @world
		dispatch-conf
		etc-update
		DEPENDENCY_01='gnome-shell gdm gnome-terminal'
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01='patterns-gnome-gnome_x11'
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="gnome-desktop"
		REMOTE_DESKTOP_SESSION='gnome-session'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		configure_x11vnc_remote_desktop_session
		configure_startxsdl
	else
		configure_gnome3_xstartup
	fi
}
#################
configure_cinnamon_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
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
	first_configure_startvnc
}
#################
install_cinnamon_desktop() {
	DEPENDENCY_01="cinnamon"
	echo '即将为您安装思源黑体(中文字体)、cinnamon和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="cinnamon cinnamon-desktop-environment"

	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01="@Cinnamon Desktop"

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="sddm cinnamon xorg"

	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_01="gnome-extra/cinnamon gnome-extra/cinnamon-desktop gnome-extra/cinnamon-translations"

	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="cinnamon cinnamon-control-center"
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="adapta-cinnamon"
	fi
	##############
	beta_features_quick_install
	apt_purge_libfprint
	configure_cinnamon_xstartup
}
####################
deepin_desktop_warning() {
	if [ "${ARCH_TYPE}" != "i386" ] && [ "${ARCH_TYPE}" != "amd64" ]; then
		echo "非常抱歉，深度桌面不支持您当前的架构。"
		echo "建议您在换用x86_64或i386架构的设备后，再来尝试。"
		echo "${YELLOW}警告！deepin桌面可能无法正常运行${RESET}"
		arch_does_not_support
		other_desktop
	fi
}
#################
deepin_desktop_debian() {
	if [ ! -e "/usr/bin/gpg" ]; then
		apt update
		apt install gpg -y
	fi
	DEPENDENCY_01="deepin-desktop"

	if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
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
	echo '即将为您安装思源黑体(中文字体)、和tightvncserver等软件包。'
	dpkg --configure -a
	apt update
	auto_select_keyboard_layout
	aptitude install -y dde
	sed -i 's/^deb/#&/g' /etc/apt/sources.list.d/deepin.list
	apt update
}
################
configure_deepin_desktop_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
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
	first_configure_startvnc
}
################
install_deepin_desktop() {
	deepin_desktop_warning
	DEPENDENCY_01="deepin-desktop"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		deepin_desktop_debian
		DEPENDENCY_01="dde"

	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01="deepin-desktop"

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		#pacman -S --noconfirm deepin-kwin
		#pacman -S --noconfirm file-roller evince
		#rm -v ~/.pam_environment 2>/dev/null
		DEPENDENCY_01="deepin deepin-extra lightdm lightdm-deepin-greeter xorg"
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	configure_deepin_desktop_xstartup
}
############################
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
		${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
	fi
}
##########################
remove_browser() {
	if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno '火狐娘:“虽然知道总有离别时，但我没想到这一天竟然会这么早。虽然很不舍，但还是很感激您曾选择了我。希望我们下次还会再相遇，呜呜...(;´༎ຶД༎ຶ`)”chromium娘：“哼(￢︿̫̿￢☆)，负心人，走了之后就别回来了！o(TヘTo) 。”  ✨请做出您的选择！' 10 60); then
		echo '呜呜...我...我才...才不会为了这点小事而流泪呢！ヽ(*。>Д<)o゜'
		echo "${YELLOW}按回车键确认卸载firefox${RESET}"
		echo 'Press enter to remove firefox,press Ctrl + C to cancel'
		RETURN_TO_WHERE='tmoe_linux_tool_menu'
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} firefox-esr firefox-esr-l10n-zh-cn
		${PACKAGES_REMOVE_COMMAND} firefox firefox-l10n-zh-cn
		${PACKAGES_REMOVE_COMMAND} firefox-locale-zh-hans
		apt autopurge 2>/dev/null
		#dnf remove -y firefox 2>/dev/null
		#pacman -Rsc firefox 2>/dev/null
		emerge -C firefox-bin firefox 2>/dev/null

	else
		echo '小声嘀咕：“妾身不在的时候，你一定要好好照顾好自己。” '
		echo "${YELLOW}按回车键确认卸载chromium${RESET}"
		echo 'Press enter to confirm uninstall chromium,press Ctrl + C to cancel'
		RETURN_TO_WHERE='tmoe_linux_tool_menu'
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} chromium chromium-l10n
		apt-mark unhold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg-extra
		${PACKAGES_REMOVE_COMMAND} chromium-browser chromium-browser-l10n
		apt autopurge
		dnf remove -y chromium 2>/dev/null
		pacman -Rsc chromium 2>/dev/null
		emerge -C chromium 2>/dev/null

	fi
	tmoe_linux_tool_menu
}
#############################################
#############################################
configure_theme() {
	INSTALL_THEME=$(whiptail --title "桌面环境主题" --menu \
		"您想要下载哪个主题？按方向键选择！下载完成后，您需要手动修改外观设置中的样式和图标。注：您需修改窗口管理器样式才能解决标题栏丢失的问题。\n Which theme do you want to download? " 15 60 5 \
		"1" "ukui：国产优麒麟ukui桌面主题" \
		"2" "win10：kali卧底模式主题" \
		"3" "MacOS：Mojave" \
		"4" "UOS：国产统一操作系统图标包" \
		"5" "breeze：plasma桌面微风gtk+版主题" \
		"6" "Kali：kali-Flat-Remix-Blue主题" \
		"0" "我一个都不要 =￣ω￣=" \
		3>&1 1>&2 2>&3)
	########################
	if [ "${INSTALL_THEME}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	########################
	if [ "${INSTALL_THEME}" == '1' ]; then
		download_ukui_theme
	fi
	######################
	if [ "${INSTALL_THEME}" == '2' ]; then
		install_kali_undercover
	fi
	##########################
	if [ "${INSTALL_THEME}" == '3' ]; then
		download_macos_mojave_theme
	fi
	##########################
	if [ "${INSTALL_THEME}" == '4' ]; then
		download_uos_icon_theme
	fi
	###########################################
	if [ "${INSTALL_THEME}" == '5' ]; then
		install_breeze_theme
	fi
	######################################
	if [ "${INSTALL_THEME}" == '6' ]; then
		if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
			download_kali_themes_common
		else
			echo "检测到kali_themes_common已下载，是否重新下载？"
			RETURN_TO_WHERE='configure_theme'
			do_you_want_to_continue
		fi
		echo "Download completed.如需删除，请手动输rm -rf /usr/share/desktop-base/kali-theme /usr/share/icons/desktop-base /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/Flat-Remix-Blue-Dark"
	fi
	##############################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	tmoe_linux_tool_menu
}
################################
download_uos_icon_theme() {
	DEPENDENCY_01="deepin-icon-theme"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install

	if [ -d "/usr/share/icons/Uos" ]; then
		echo "检测到Uos图标包已下载，是否继续。"
		RETURN_TO_WHERE='configure_theme'
		do_you_want_to_continue
	fi

	if [ -d "/tmp/UosICONS" ]; then
		rm -rf /tmp/UosICONS
	fi

	git clone -b Uos --depth=1 https://gitee.com/mo2/xfce-themes.git /tmp/UosICONS
	cd /tmp/UosICONS
	cat url.txt
	tar -Jxvf Uos.tar.xz -C /usr/share/icons 2>/dev/null
	rm -rf /tmp/UosICONS
	echo "Download completed.如需删除，请手动输rm -rf /usr/share/icons/Uos ; ${PACKAGES_REMOVE_COMMAND} deepin-icon-theme"
}
#####################
download_macos_mojave_theme() {
	if [ -d "/usr/share/themes/Mojave-dark" ]; then
		echo "检测到主题已下载，是否重新下载？"
		RETURN_TO_WHERE='configure_theme'
		do_you_want_to_continue
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
}
#######################
download_ukui_theme() {
	DEPENDENCY_01="ukui-themes"
	DEPENDENCY_02="ukui-greeter"
	NON_DEBIAN='false'
	beta_features_quick_install

	if [ ! -e '/usr/share/icons/ukui-icon-theme-default' ] && [ ! -e '/usr/share/icons/ukui-icon-theme' ]; then
		mkdir -p /tmp/.ukui-gtk-themes
		cd /tmp/.ukui-gtk-themes
		UKUITHEME="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/u/ukui-themes/' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		curl -Lvo 'ukui-themes.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/u/ukui-themes/${UKUITHEME}"
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
		#apt install -y ukui-greeter
	else
		echo '请前往外观设置手动修改图标'
	fi
	#gtk-update-icon-cache /usr/share/icons/ukui-icon-theme/ 2>/dev/null
	#echo "安装完成，如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} ukui-themes"
}
#################################
install_breeze_theme() {
	DEPENDENCY_01="breeze-icon-theme"
	DEPENDENCY_02="breeze-cursor-theme breeze-gtk-theme xfwm4-theme-breeze"
	NON_DEBIAN='false'

	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="breeze-icons breeze-gtk"
		DEPENDENCY_02="xfwm4-theme-breeze"
		if [ $(command -v grub-install) ]; then
			DEPENDENCY_02="${DEPENDENCY_02} breeze-grub"
		fi
	fi
	beta_features_quick_install
}
####################
install_kali_undercover() {
	if [ -e "/usr/share/icons/Windows-10-Icons" ]; then
		echo "检测到您已安装win10主题"
		echo "如需移除，请手动输${PACKAGES_REMOVE_COMMAND} kali-undercover;rm -rf /usr/share/icons/Windows-10-Icons"
		echo "是否重新下载？"
		RETURN_TO_WHERE='configure_theme'
		do_you_want_to_continue
	fi
	DEPENDENCY_01="kali-undercover"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		beta_features_quick_install
	fi
	#此处需做两次判断
	if [ "${DEBIAN_DISTRO}" = "kali" ]; then
		beta_features_quick_install
	else
		mkdir -p /tmp/.kali-undercover-win10-theme
		cd /tmp/.kali-undercover-win10-theme
		UNDERCOVERlatestLINK="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover/' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		curl -Lvo kali-undercover.deb "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover/${UNDERCOVERlatestLINK}"
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
}
############################################
modify_to_kali_sources_list() {
	if [ "${LINUX_DISTRO}" != "debian" ]; then
		echo "${YELLOW}非常抱歉，检测到您使用的不是deb系linux，按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		tmoe_linux_tool_menu
	fi

	if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
		echo "${YELLOW}非常抱歉，暂不支持Ubuntu，按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		tmoe_linux_tool_menu
	fi

	if ! grep -q "^deb.*kali" /etc/apt/sources.list; then
		echo "检测到您当前为debian源，是否修改为kali源？"
		echo "Detected that your current software sources list is debian, do you need to modify it to kali source?"
		RETURN_TO_WHERE='tmoe_linux_tool_menu'
		do_you_want_to_continue
		kali_sources_list
	else
		echo "检测到您当前为kali源，是否修改为debian源？"
		echo "Detected that your current software sources list is kali, do you need to modify it to debian source?"
		RETURN_TO_WHERE='tmoe_linux_tool_menu'
		do_you_want_to_continue
		debian_sources_list
	fi
}
################################
kali_sources_list() {
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
		deb http://mirrors.tuna.tsinghua.edu.cn/kali/ kali-rolling main contrib non-free
		deb http://mirrors.tuna.tsinghua.edu.cn/debian/ stable main contrib non-free
		# deb https://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
		# deb http://mirrors.tuna.tsinghua.edu.cn/kali/ kali-last-snapshot main contrib non-free
	EOF
	apt update
	apt list --upgradable
	apt dist-upgrade -y
	apt search kali-linux
	echo 'You have successfully replaced your debian source with a kali source.'
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
#######################
debian_sources_list() {
	sed -i 's/^deb/#&/g' /etc/apt/sources.list
	cat >>/etc/apt/sources.list <<-'EOF'
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
	EOF
	apt update
	apt list --upgradable
	echo '您已换回debian源'
	apt dist-upgrade -y
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
############################################
############################################
other_software() {
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
			"14" "Install Chinese manual 安装中文手册" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	#(已移除)"12" "Tasksel:轻松,快速地安装组软件" \
	##############################
	if [ "${SOFTWARE}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	##############################
	if [ "${SOFTWARE}" == '1' ]; then
		install_mpv
	fi
	##############################
	if [ "${SOFTWARE}" == '2' ]; then
		install_linux_qq
	fi
	##############################
	if [ "${SOFTWARE}" == '3' ]; then
		install_wesnoth_game
	fi
	##############################
	if [ "${SOFTWARE}" == '4' ]; then
		install_nds_game_mayomonogatari
	fi
	##########################
	if [ "${SOFTWARE}" == '5' ]; then
		install_game_cataclysm
	fi
	##############################
	if [ "${SOFTWARE}" == '6' ]; then
		install_package_manager_gui
	fi
	###############################
	if [ "${SOFTWARE}" == '7' ]; then
		install_gimp
	fi
	##########################
	if [ "${SOFTWARE}" == '8' ]; then
		install_libre_office
	fi
	##############################
	if [ "${SOFTWARE}" == '9' ]; then
		install_parole
	fi
	##########################
	if [ "${SOFTWARE}" == '10' ]; then
		install_baidu_netdisk
	fi
	###########################
	if [ "${SOFTWARE}" == '11' ]; then
		install_netease_163_cloud_music
	fi
	###########################
	if [ "${SOFTWARE}" == '12' ]; then
		install_android_debug_bridge
	fi
	###########################
	if [ "${SOFTWARE}" == '13' ]; then
		install_bleachbit_cleaner
	fi
	########################
	if [ "${SOFTWARE}" == '14' ]; then
		install_chinese_manpages
	fi
	############################################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	other_software
	#tmoe_linux_tool_menu
}
###########
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
	if [ -e "/usr/share/applications/qq.desktop" ]; then
		press_enter_to_reinstall
	fi
	cd /tmp
	if [ "${ARCH_TYPE}" = "arm64" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			curl -Lvo LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb"
			apt install -y ./LINUXQQ.deb
		else
			curl -Lvo LINUXQQ.sh http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.sh
			chmod +x LINUXQQ.sh
			sudo ./LINUXQQ.sh
			#即使是root用户也需要加sudo
		fi
	elif [ "${ARCH_TYPE}" = "amd64" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			curl -Lvo LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_amd64.deb"
			apt install -y ./LINUXQQ.deb
			#http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb
		else
			curl -Lvo LINUXQQ.sh "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_x86_64.sh"
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
		echo "检测到您已下载游戏文件，路径为/root/斯隆与马克贝尔的谜之物语"
		press_enter_to_reinstall
	fi
	cd ${HOME}
	mkdir -p '斯隆与马克贝尔的谜之物语'
	cd '斯隆与马克贝尔的谜之物语'
	curl -Lvo slymkbr1.zip http://k73dx1.zxclqw.com/slymkbr1.zip
	curl -Lvo mayomonogatari2.zip http://k73dx1.zxclqw.com/mayomonogatari2.zip
	7za x slymkbr1.zip
	7za x mayomonogatari2.zip
	mv -f 斯隆与马克贝尔的谜之物语k73/* ./
	mv -f 迷之物语/* ./
	rm -f *url *txt
	rm -rf 迷之物语 斯隆与马克贝尔的谜之物语k73
	rm -f slymkbr1.zip* mayomonogatari2.zip*

	echo "安装完成，您需要手动进入'/root/斯隆与马克贝尔的谜之物语'目录加载游戏"
	echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} desmume ; rm -rf ~/斯隆与马克贝尔的谜之物语"
	echo 'Press enter to start the nds emulator.'
	echo "${YELLOW}按回车键启动游戏。${RESET}"
	read
	desmume "${HOME}/斯隆与马克贝尔的谜之物语/3782.nds" 2>/dev/null &
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
		sed -i 's/synaptic-pkexec/synaptic/g' /usr/share/applications/synaptic.desktop
		echo "synaptic和gdebi安装完成，您可以将deb文件的默认打开程序修改为gdebi"
	else
		echo "${YELLOW}您真的要离开我么？哦呜。。。${RESET}"
		echo "Do you really want to remove synaptic?"
		RETURN_TO_WHERE='other_software'
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} synaptic
		${PACKAGES_REMOVE_COMMAND} gdebi
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
		curl -Lvo 'debian-handbook.deb' 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/d/debian-handbook/debian-handbook_8.20180830_all.deb'
		busybox ar xv 'debian-handbook.deb'
		tar -Jxvf data.tar.xz ./usr/share/doc/debian-handbook/html
		ls | grep -v usr | xargs rm -rf
		ln -sf ./usr/share/doc/debian-handbook/html/zh-CN/index.html ./
	fi
	echo "man一款帮助手册软件，它可以帮助您了解关于命令的详细用法。"
	echo "man a help manual software, which can help you understand the detailed usage of the command."
	echo "您可以输${YELLOW}man 软件或命令名称${RESET}来获取帮助信息，例如${YELLOW}man bash${RESET}或${YELLOW}man zsh${RESET}"
}
#####################
install_libre_office() {
	#ps -e >/dev/null || echo "/proc分区未挂载，请勿安装libreoffice,赋予proot容器真实root权限可解决相关问题，但强烈不推荐！"
	ps -e >/dev/null || echo "${RED}WARNING！${RESET}检测到您无权读取${GREEN}/proot${RESET}分区的某些数据！"
	RETURN_TO_WHERE='other_software'
	do_you_want_to_continue
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01='--no-install-recommends libreoffice'
	else
		DEPENDENCY_01="libreoffice"
	fi
	DEPENDENCY_02="libreoffice-l10n-zh-cn libreoffice-gtk3"
	NON_DEBIAN='false'
	beta_features_quick_install
	if [ ! -e "/tmp/.Chroot-Container-Detection-File" ] && [ "${ARCH_TYPE}" != "amd64" ] && [ "${ARCH_TYPE}" != "i386" ]; then
		mkdir -p /prod/version
		cd /usr/lib/libreoffice/program
		rm -f oosplash
		curl -Lo 'oosplash' https://gitee.com/mo2/patch/raw/libreoffice/oosplash
		chmod +x oosplash
	fi
	beta_features_install_completed
}
###################
install_baidu_netdisk() {
	DEPENDENCY_01="baidunetdisk"
	DEPENDENCY_02=""
	if [ "${ARCH_TYPE}" != "amd64" ] && [ "${ARCH_TYPE}" != "i386" ]; then
		arch_does_not_support
		other_software
	fi

	if [ -e "/usr/share/applications/baidunetdisk.desktop" ]; then
		press_enter_to_reinstall
	fi
	cd /tmp
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="baidunetdisk-bin"
		beta_features_quick_install
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		curl -Lvo 'baidunetdisk.rpm' "http://wppkg.baidupcs.com/issue/netdisk/LinuxGuanjia/3.0.1/baidunetdisk_linux_3.0.1.2.rpm"
		rpm -ivh 'baidunetdisk.rpm'
	else
		curl -Lvo baidunetdisk.deb "http://wppkg.baidupcs.com/issue/netdisk/LinuxGuanjia/3.0.1/baidunetdisk_linux_3.0.1.2.deb"
		apt install -y ./baidunetdisk.deb
	fi
	echo "若安装失败，则请前往官网手动下载安装"
	echo "url：https://pan.baidu.com/download"
	rm -fv ./baidunetdisk.deb
	beta_features_install_completed
}
######################
install_netease_163_cloud_music() {
	DEPENDENCY_01="netease-cloud-music"
	DEPENDENCY_02=""

	if [ "${ARCH_TYPE}" != "amd64" ] && [ "${ARCH_TYPE}" != "i386" ]; then
		arch_does_not_support
		other_software
	fi
	if [ -e "/usr/share/applications/netease-cloud-music.desktop" ]; then
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
		if [ "${ARCH_TYPE}" = "amd64" ]; then
			curl -Lvo netease-cloud-music.deb "http://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb"
		else
			curl -Lvo netease-cloud-music.deb "http://mirrors.ustc.edu.cn/debiancn/pool/main/n/netease-cloud-music/netease-cloud-music_1.0.0%2Brepack.debiancn-1_i386.deb"
		fi
		apt install -y ./netease-cloud-music.deb
		echo "若安装失败，则请前往官网手动下载安装。"
		echo 'url: https://music.163.com/st/download'
		rm -fv ./netease-cloud-music.deb
		beta_features_install_completed
	fi
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
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
##########################
modify_remote_desktop_config() {
	if [ ! $(command -v nano) ]; then
		DEPENDENCY_01='nano'
		DEPENDENCY_02=""
		NON_DEBIAN='false'
		beta_features_quick_install
	fi
	##################
	REMOTE_DESKTOP=$(whiptail --title "远程桌面" --menu \
		"您想要修改哪个远程桌面的配置？\nWhich remote desktop configuration do you want to modify?" 15 60 4 \
		"1" "tightvnc/tigervnc" \
		"2" "x11vnc" \
		"3" "XSDL" \
		"4" "XRDP" \
		"5" "Xwayland(测试版)" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${REMOTE_DESKTOP}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	##########################
	if [ "${REMOTE_DESKTOP}" == '1' ]; then
		modify_vnc_conf
	fi
	##########################
	if [ "${REMOTE_DESKTOP}" == '2' ]; then
		configure_x11vnc
	fi
	##########################
	if [ "${REMOTE_DESKTOP}" == '3' ]; then
		modify_xsdl_conf
	fi
	##########################
	if [ "${REMOTE_DESKTOP}" == '4' ]; then
		modify_xrdp_conf
	fi
	##########################
	if [ "${REMOTE_DESKTOP}" == '5' ]; then
		modify_xwayland_conf
	fi
	#######################
	press_enter_to_return
	modify_remote_desktop_config
}
#########################
configure_x11vnc() {
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE x11vnc" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
			"1" "one-key configure初始化一键配置" \
			"2" "pulse_server音频服务" \
			"3" "resolution分辨率" \
			"4" "startx11vnc启动脚本" \
			"5" "stopx11vnc停止脚本" \
			"6" "remove 卸载/移除" \
			"7" "readme 进程管理说明" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${TMOE_OPTION}" == '0' ]; then
		#tmoe_linux_tool_menu
		modify_remote_desktop_config
	fi
	##############################
	if [ "${TMOE_OPTION}" == '1' ]; then
		x11vnc_onekey
	fi
	##############################
	if [ "${TMOE_OPTION}" == '2' ]; then
		x11vnc_pulse_server
	fi
	##############################
	if [ "${TMOE_OPTION}" == '3' ]; then
		x11vnc_resolution
	fi
	##############################
	if [ "${TMOE_OPTION}" == '4' ]; then
		nano /usr/local/bin/startx11vnc
	fi
	##############################
	if [ "${TMOE_OPTION}" == '5' ]; then
		nano /usr/local/bin/stopx11vnc
	fi
	###################
	if [ "${TMOE_OPTION}" == '6' ]; then
		remove_X11vnc
	fi
	##############################
	if [ "${TMOE_OPTION}" == '7' ]; then
		echo "输startx11vnc启动x11vnc"
		echo "输stop11vnc停止x11vnc"
	fi
	########################################
	press_enter_to_return
	configure_x11vnc
	####################
}
############
x11vnc_onekey() {
	echo "注：x11vnc和tightvnc是有${RED}区别${RESET}的！"
	echo "配置完x11vnc后，输${GREEN}startx11vnc${RESET}${BLUE}启动${RESET},输${GREEN}stopx11vnc${RESET}${BLUE}停止${RESET}"
	RETURN_TO_WHERE='configure_x11vnc'
	do_you_want_to_continue
	stopvnc 2>/dev/null
	NON_DEBIAN='false'
	DEPENDENCY_01=''
	DEPENDENCY_02=''
	if [ ! $(command -v x11vnc) ]; then
		DEPENDENCY_01='x11vnc'
	fi
	#注意下面那处的大小写
	if [ ! $(command -v xvfb) ] && [ ! $(command -v Xvfb) ]; then
		DEPENDENCY_02='xvfb'
	fi

	if [ ! -z "${DEPENDENCY_01}" ] || [ ! -z "${DEPENDENCY_02}" ]; then
		beta_features_quick_install
	fi
	################
	X11_OR_WAYLAND_DESKTOP='x11vnc'
	configure_remote_desktop_enviroment
}
#############
remove_X11vnc() {
	echo "正在停止x11vnc进程..."
	echo "Stopping x11vnc..."
	stopx11vnc
	echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
	RETURN_TO_WHERE='configure_x11vnc'
	do_you_want_to_continue
	rm -rfv /usr/local/bin/startx11vnc /usr/local/bin/stopx11vnc
	echo "即将为您卸载..."
	${PACKAGES_REMOVE_COMMAND} x11vnc
}
################
x11vnc_pulse_server() {
	cd /usr/local/bin/
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。当前为$(grep 'PULSE_SERVER' startx11vnc | grep -v '^#' | cut -d '=' -f 2) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if grep '^export.*PULSE_SERVER' startx11vnc; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startx11vnc
		else
			sed -i "3 a\export PULSE_SERVER=$TARGET" startx11vnc
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' startx11vnc | grep -v '^#' | cut -d '=' -f 2)
	else
		configure_x11vnc
	fi
}
##################
x11vnc_resolution() {
	TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,720x1140,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为1440x720,当前为$(cat $(command -v startx11vnc) | grep '/usr/bin/Xvfb' | head -n 1 | cut -d ':' -f 2 | cut -d '+' -f 1 | cut -d '-' -f 2 | cut -d 'x' -f -2 | awk -F ' ' '$0=$NF')。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		#/usr/bin/Xvfb :1 -screen 0 1440x720x24 -ac +extension GLX +render -noreset &
		sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :1 -screen 0 ${TARGET}x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)"
		echo 'Your current resolution has been modified.'
		echo '您当前的分辨率已经修改为'
		echo $(cat $(command -v startx11vnc) | grep '/usr/bin/Xvfb' | head -n 1 | cut -d ':' -f 2 | cut -d '+' -f 1 | cut -d '-' -f 2 | cut -d 'x' -f -2 | awk -F ' ' '$0=$NF')
		#echo $(sed -n \$p "$(command -v startx11vnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
		#$p表示最后一行，必须用反斜杠转义。
		stopx11vnc
	else
		echo "您当前的分辨率为$(cat $(command -v startx11vnc) | grep '/usr/bin/Xvfb' | head -n 1 | cut -d ':' -f 2 | cut -d '+' -f 1 | cut -d '-' -f 2 | cut -d 'x' -f -2 | awk -F ' ' '$0=$NF')"
	fi
}
############################
######################
modify_vnc_conf() {
	if [ ! -e /usr/local/bin/startvnc ]; then
		echo "/usr/local/bin/startvnc is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startvnc,您可能尚未安装图形桌面，是否继续编辑?'
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		RETURN_TO_WHERE='modify_remote_desktop_config'
		do_you_want_to_continue
	fi

	if (whiptail --title "modify vnc configuration" --yes-button '分辨率resolution' --no-button '其它other' --yesno "您想要修改哪项配置信息？Which configuration do you want to modify?" 9 50); then
		TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,720x1140,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为1440x720,当前为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1) 。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			sed -i '/vncserver -geometry/d' "$(command -v startvnc)"
			sed -i "$ a\vncserver -geometry $TARGET -depth 24 -name tmoe-linux :1" "$(command -v startvnc)"
			echo 'Your current resolution has been modified.'
			echo '您当前的分辨率已经修改为'
			echo $(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			#echo $(sed -n \$p "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			#$p表示最后一行，必须用反斜杠转义。
			stopvnc 2>/dev/null
			echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			tmoe_linux_tool_menu
		else
			echo '您当前的分辨率为'
			echo $(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
		fi
	else
		modify_other_vnc_conf
	fi
}

############################
modify_xsdl_conf() {
	if [ ! -f /usr/local/bin/startxsdl ]; then
		echo "/usr/local/bin/startxsdl is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startxsdl,您可能尚未安装图形桌面，是否继续编辑。'
		RETURN_TO_WHERE='modify_remote_desktop_config'
		do_you_want_to_continue
	fi
	XSDL_XSERVER=$(whiptail --title "Modify x server conf" --menu "Choose your option" 15 60 5 \
		"1" "音频端口 Pulse server port " \
		"2" "显示编号 Display number" \
		"3" "ip address" \
		"4" "手动编辑 Edit manually" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	###########
	if [ "${XSDL_XSERVER}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	###########
	if [ "${XSDL_XSERVER}" == '1' ]; then
		modify_pulse_server_port
	fi
	###########
	if [ "${XSDL_XSERVER}" == '2' ]; then
		modify_display_port
	fi
	###########
	if [ "${XSDL_XSERVER}" == '3' ]; then
		modify_xsdl_ip_address
	fi
	###########
	if [ "${XSDL_XSERVER}" == '4' ]; then
		modify_startxsdl_manually
	fi
	###########
}
#################
modify_startxsdl_manually() {
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
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	modify_xsdl_conf
}

######################
modify_pulse_server_port() {

	TARGET=$(whiptail --inputbox "若xsdl app显示的端口非4713，则您可在此处修改。默认为4713，当前为$(sed -n 4p $(command -v startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2) \n请以xsdl app显示的pulse server地址的最后几位数字为准，输入完成后按回车键确认。" 20 50 --title "MODIFY PULSE SERVER PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "4 c export PULSE_SERVER=tcp:127.0.0.1:$TARGET" "$(command -v startxsdl)"
		echo 'Your current PULSE SERVER port has been modified.'
		echo '您当前的音频端口已修改为'
		echo $(sed -n 4p $(command -v startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		modify_xsdl_conf
	else
		modify_xsdl_conf
	fi
}

########################################################
modify_display_port() {

	TARGET=$(whiptail --inputbox "若xsdl app显示的Display number(输出显示的端口数字) 非0，则您可在此处修改。默认为0，当前为$(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2) \n请以xsdl app显示的DISPLAY=:的数字为准，输入完成后按回车键确认。" 20 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "3 c export DISPLAY=127.0.0.1:$TARGET" "$(command -v startxsdl)"
		echo 'Your current DISPLAY port has been modified.'
		echo '您当前的显示端口已修改为'
		echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2)
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		modify_xsdl_conf
	else
		modify_xsdl_conf
	fi
}
###############################################
modify_xsdl_ip_address() {
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
		modify_xsdl_conf
	else
		modify_xsdl_conf
	fi
}
#################
press_enter_to_continue() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}继续${RESET}"
	read
}
#############################################
press_enter_to_return() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
}
#############################################
press_enter_to_return_configure_xrdp() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	configure_xrdp
}
##############
modify_xwayland_conf() {
	if [ ! -e "/etc/xwayland" ] && [ ! -L "/etc/xwayland" ]; then
		echo "${RED}WARNING！${RESET}检测到wayland目录${YELLOW}不存在${RESET}"
		echo "请先在termux里进行配置，再返回此处选择您需要配置的桌面环境"
		echo "若您无root权限，则有可能配置失败！"
		press_enter_to_return
		modify_remote_desktop_config
	fi
	if (whiptail --title "你想要对这个小可爱做什么" --yes-button "启动" --no-button 'Configure配置' --yesno "您是想要启动桌面还是配置wayland？" 9 50); then
		if [ ! -e "/usr/local/bin/startw" ] || [ ! $(command -v weston) ]; then
			echo "未检测到启动脚本，请重新配置"
			echo "Please reconfigure xwayland"
			sleep 2s
			xwayland_onekey
		fi
		/usr/local/bin/startw
	else
		configure_xwayland
	fi
}
##################
#############
press_enter_to_return_configure_xwayland() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	configure_xwayland
}
#######################
xwayland_desktop_enviroment() {
	X11_OR_WAYLAND_DESKTOP='xwayland'
	configure_remote_desktop_enviroment
}
#############
configure_xwayland() {
	#进入xwayland配置文件目录
	cd /etc/xwayland/
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE xwayland" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
			"1" "One-key conf 初始化一键配置" \
			"2" "指定xwayland桌面环境" \
			"3" "pulse_server音频服务" \
			"4" "remove 卸载/移除" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${TMOE_OPTION}" == '0' ]; then
		#tmoe_linux_tool_menu
		modify_remote_desktop_config
	fi
	##############################
	if [ "${TMOE_OPTION}" == '1' ]; then
		xwayland_onekey
	fi
	##############################
	if [ "${TMOE_OPTION}" == '2' ]; then
		#X11_OR_WAYLAND_DESKTOP='xwayland'
		xwayland_desktop_enviroment
	fi
	##############################
	if [ "${TMOE_OPTION}" == '3' ]; then
		xwayland_pulse_server
	fi
	##############################
	if [ "${TMOE_OPTION}" == '4' ]; then
		echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
		#service xwayland restart
		RETURN_TO_WHERE='configure_xwayland'
		do_you_want_to_continue
		DEPENDENCY_01='weston'
		DEPENDENCY_02='xwayland'
		NON_DEBIAN='false'
		if [ "${LINUX_DISTRO}" = "arch" ]; then
			DEPENDENCY_02='xorg-server-xwayland'
		elif [ "${LINUX_DISTRO}" = "redhat" ]; then
			DEPENDENCY_02='xorg-x11-server-Xwayland'
		fi
		rm -fv /etc/xwayland/startw
		echo "${YELLOW}已删除xwayland启动脚本${RESET}"
		echo "即将为您卸载..."
		${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
	fi
	########################################
	press_enter_to_return_configure_xwayland
}
#####################
##############
xwayland_pulse_server() {
	cd /usr/local/bin/
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可以在此处修改。当前为$(grep 'PULSE_SERVER' startw | grep -v '^#' | cut -d '=' -f 2) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if grep '^export.*PULSE_SERVER' startw; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startw
		else
			sed -i "3 a\export PULSE_SERVER=$TARGET" startw
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' startw | grep -v '^#' | cut -d '=' -f 2)
		press_enter_to_return_configure_xwayland
	else
		configure_xwayland
	fi
}
##############
xwayland_onekey() {
	RETURN_TO_WHERE='configure_xwayland'
	do_you_want_to_continue

	DEPENDENCY_01='weston'
	DEPENDENCY_02='xwayland'
	NON_DEBIAN='false'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ $(command -v startplasma-x11) ]; then
			DEPENDENCY_02='xwayland plasma-workspace-wayland'
		fi
	fi
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02='xorg-server-xwayland'
	fi
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
		#!/bin/bash
		chmod +x -R /etc/xwayland
		XDG_RUNTIME_DIR=/etc/xwayland Xwayland &
		export PULSE_SERVER=127.0.0.1:0
		export DISPLAY=:0
		startxfce4
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
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
		echo "若您的宿主机为${BOLD}Android${RESET}系统，则${RED}无法${RESET}${BLUE}保障${RESET}xrdp可以正常连接！"
		RETURN_TO_WHERE='modify_remote_desktop_config'
		do_you_want_to_continue
	fi

	pgrep xrdp &>/dev/null
	if [ "$?" = "0" ]; then
		FILEBROWSER_STATUS='检测到xrdp进程正在运行'
		FILEBROWSER_PROCESS='Restart重启'
	else
		FILEBROWSER_STATUS='检测到xrdp进程未运行'
		FILEBROWSER_PROCESS='Start启动'
	fi

	if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${FILEBROWSER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${FILEBROWSER_STATUS}" 9 50); then
		if [ ! -e "${HOME}/.config/tmoe-linux/xrdp.ini" ]; then
			echo "未检测到已备份的xrdp配置文件，请重新配置"
			echo "Please reconfigure xrdp"
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
	#进入xrdp配置文件目录
	cd /etc/xrdp/
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE XRDP" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
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
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${TMOE_OPTION}" == '0' ]; then
		#tmoe_linux_tool_menu
		modify_remote_desktop_config
	fi
	##############################
	if [ "${TMOE_OPTION}" == '1' ]; then
		service xrdp stop 2>/dev/null
		xrdp_onekey
	fi
	##############################
	if [ "${TMOE_OPTION}" == '2' ]; then
		X11_OR_WAYLAND_DESKTOP='xrdp'
		#xrdp_desktop_enviroment
		configure_remote_desktop_enviroment
	fi
	##############################
	if [ "${TMOE_OPTION}" == '3' ]; then
		xrdp_port
	fi
	##############################
	if [ "${TMOE_OPTION}" == '4' ]; then
		nano /etc/xrdp/xrdp.ini
	fi
	##############################
	if [ "${TMOE_OPTION}" == '5' ]; then
		nano /etc/xrdp/startwm.sh
	fi
	##############################
	if [ "${TMOE_OPTION}" == '6' ]; then
		service xrdp stop 2>/dev/null
		service xrdp status | head -n 24
	fi
	##############################
	if [ "${TMOE_OPTION}" == '7' ]; then
		echo "Type ${GREEN}q${RESET} to ${BLUE}return.${RESET}"
		service xrdp status
	fi
	##############################
	if [ "${TMOE_OPTION}" == '8' ]; then
		xrdp_pulse_server
	fi
	##############################
	if [ "${TMOE_OPTION}" == '9' ]; then
		xrdp_reset
	fi
	##############################
	if [ "${TMOE_OPTION}" == '10' ]; then
		pkill xrdp
		echo "正在停止xrdp进程..."
		echo "Stopping xrdp..."
		service xrdp stop 2>/dev/null
		echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
		#service xrdp restart
		RETURN_TO_WHERE='configure_xrdp'
		do_you_want_to_continue
		rm -fv /etc/xrdp/xrdp.ini /etc/xrdp/startwm.sh
		echo "${YELLOW}已删除xrdp配置文件${RESET}"
		echo "即将为您卸载..."
		${PACKAGES_REMOVE_COMMAND} xrdp
	fi
	########################################
	if [ "${TMOE_OPTION}" == '11' ]; then
		xrdp_systemd
	fi
	##############################
	press_enter_to_return_configure_xrdp
}
#############
configure_remote_desktop_enviroment() {
	BETA_DESKTOP=$(whiptail --title "REMOTE_DESKTOP" --menu \
		"您想要配置哪个桌面？按方向键选择，回车键确认！\n Which desktop environment do you want to configure? " 15 60 5 \
		"1" "xfce：兼容性高" \
		"2" "lxde：轻量化桌面" \
		"3" "mate：基于GNOME 2" \
		"4" "lxqt" \
		"5" "kde plasma 5" \
		"6" "gnome 3" \
		"7" "cinnamon" \
		"8" "dde (deepin desktop)" \
		"0" "我一个都不选 =￣ω￣=" \
		3>&1 1>&2 2>&3)
	##########################
	if [ "${BETA_DESKTOP}" == '1' ]; then
		REMOTE_DESKTOP_SESSION='xfce4-session'
		#configure_remote_xfce4_desktop
	fi
	##########################
	if [ "${BETA_DESKTOP}" == '2' ]; then
		REMOTE_DESKTOP_SESSION='lxde-session'
		#configure_remote_lxde_desktop
	fi
	##########################
	if [ "${BETA_DESKTOP}" == '3' ]; then
		REMOTE_DESKTOP_SESSION='mate-session'
		#configure_remote_mate_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '4' ]; then
		REMOTE_DESKTOP_SESSION='startlxqt'
		#configure_remote_lxqt_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '5' ]; then
		#REMOTE_DESKTOP_SESSION='plasma-x11-session'
		#configure_remote_kde_plasma5_desktop
		if [ $(command -v startkde) ]; then
			REMOTE_DESKTOP_SESSION="startkde"
		else
			REMOTE_DESKTOP_SESSION='startplasma-x11'
		fi
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '6' ]; then
		REMOTE_DESKTOP_SESSION='gnome-session'
		#configure_remote_gnome3_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '7' ]; then
		REMOTE_DESKTOP_SESSION='cinnamon-session'
		#configure_remote_cinnamon_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '8' ]; then
		REMOTE_DESKTOP_SESSION='startdde'
		#configure_remote_deepin_desktop
	fi
	##########################
	if [ "$INSTALLDESKTOP" == '0' ]; then
		modify_remote_desktop_config
	fi
	##########################
	configure_remote_desktop_session
	press_enter_to_return
	modify_remote_desktop_config
}
##############
configure_xrdp_remote_desktop_session() {
	echo "${REMOTE_DESKTOP_SESSION}" >~/.xsession
	#touch ~/.session
	cd /etc/xrdp
	sed -i '/session/d' startwm.sh
	sed -i '/start/d' startwm.sh
	if grep 'exec' startwm.sh; then
		sed -i '$ d' startwm.sh
		sed -i '$ d' startwm.sh
	fi
	#sed -i '/X11\/Xsession/d' startwm.sh
	cat >>startwm.sh <<-'EnfOfStartWM'
		test -x /etc/X11/Xsession && exec /etc/X11/Xsession
		exec /bin/sh /etc/X11/Xsession
	EnfOfStartWM
	sed -i "s@exec /etc/X11/Xsession@exec ${REMOTE_DESKTOP_SESSION}@g" /etc/xrdp/startwm.sh
	sed -i "s@exec /bin/sh /etc/X11/Xsession@exec /bin/sh ${REMOTE_DESKTOP_SESSION}@g" /etc/xrdp/startwm.sh
	echo "修改完成，若无法生效，则请使用强制配置功能[Y/f]"
	echo "输f启用，一般情况下无需启用，因为这可能会造成一些问题。"
	echo "若root用户无法连接，则请使用${GREEN}adduser${RESET}命令新建一个普通用户"
	echo 'If the configuration fails, please use the mandatory configuration function！'
	echo "Press enter to return,type f to force congigure."
	echo "按${GREEN}回车键${RESET}${RED}返回${RESET}，输${YELLOW}f${RESET}启用${BLUE}强制配置功能${RESET}"
	read opt
	case $opt in
	y* | Y* | "") ;;
	f* | F*)
		sed -i "s@/etc/X11/Xsession@${REMOTE_DESKTOP_SESSION}@g" startwm.sh
		;;
	*)
		echo "Invalid choice. skipped."
		${RETURN_TO_WHERE}
		#beta_features
		;;
	esac
	service xrdp restart
	service xrdp status
}
##############
configure_xwayland_remote_desktop_session() {
	cd /usr/local/bin
	cat >startw <<-EndOFwayland
		#!/bin/bash
		chmod +x -R /etc/xwayland
		XDG_RUNTIME_DIR=/etc/xwayland Xwayland &
		export PULSE_SERVER=127.0.0.1:0
		export DISPLAY=:0
		${REMOTE_DESKTOP_SESSION}
	EndOFwayland
	echo ${REMOTE_DESKTOP_SESSION}
	chmod +x startw
	echo "配置完成，请先打开sparkle app，点击Start"
	echo "然后在GNU/Linux容器里输startw启动xwayland"
	echo "在使用过程中，您可以按音量+调出键盘"
	echo "执行完startw后,您可能需要经历长达30s的黑屏"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET}"
	echo "按${GREEN}回车键${RESET}执行${BLUE}startw${RESET}"
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
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。linux默认为127.0.0.1,WSL2默认为宿主机ip,当前为$(grep 'PULSE_SERVER' startwm.sh | grep -v '^#' | cut -d '=' -f 2) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then

		if grep ! '^export.*PULSE_SERVER' startwm.sh; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startwm.sh
			#sed -i "4 a\export PULSE_SERVER=$TARGET" startwm.sh
		fi
		sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startwm.sh
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' startwm.sh | grep -v '^#' | cut -d '=' -f 2)
		press_enter_to_return_configure_xrdp
	else
		configure_xrdp
	fi
}
##############
xrdp_onekey() {
	RETURN_TO_WHERE='configure_xrdp'
	do_you_want_to_continue

	DEPENDENCY_01='xrdp'
	DEPENDENCY_02='nano'
	NON_DEBIAN='false'
	if [ "${LINUX_DISTRO}" = "gentoo" ]; then
		emerge -avk layman
		layman -a bleeding-edge
		layman -S
		#ACCEPT_KEYWORDS="~amd64" USE="server" emerge -a xrdp
	fi
	beta_features_quick_install
	##############
	mkdir -p /etc/polkit-1/localauthority.conf.d /etc/polkit-1/localauthority/50-local.d/
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
		mkdir -p ${HOME}/.config/tmoe-linux/
		cd /etc/xrdp/
		cp -p startwm.sh xrdp.ini ${HOME}/.config/tmoe-linux/
	fi
	####################
	if [ -e "/usr/bin/xfce4-session" ]; then
		if [ ! -e " ~/.xsession" ]; then
			echo 'xfce4-session' >~/.xsession
			touch ~/.session
			sed -i 's:exec /bin/sh /etc/X11/Xsession:exec /bin/sh xfce4-session /etc/X11/Xsession:g' /etc/xrdp/startwm.sh
		fi
	fi

	if ! grep -q '^export PULSE_SERVER' /etc/xrdp/startwm.sh; then
		sed -i '/test -x \/etc\/X11/i\export PULSE_SERVER=127.0.0.1' /etc/xrdp/startwm.sh
	fi
	###########################
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		if grep -q '172..*1' "/etc/resolv.conf"; then
			echo "检测到您当前使用的可能是WSL2"
			WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
			sed -i "s/^export PULSE_SERVER=.*/export PULSE_SERVER=${WSL2IP}/g" /etc/xrdp/startwm.sh
			echo "已将您的音频服务ip修改为${WSL2IP}"
		fi
		echo '检测到您使用的是WSL,为防止与windows自带的远程桌面的3389端口冲突，请您设定一个新的端口'
		sleep 2s
	fi
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
	service xrdp restart 2>/dev/null
	if [ "$?" != "0" ]; then
		/etc/init.d/xrdp restart
	fi
	service xrdp status | head -n 24
	echo "您可以输${YELLOW}service xrdp stop${RESET}来停止进程"
	echo "您当前的IP地址为"
	ip -4 -br -c a | cut -d '/' -f 1
	echo "端口号为${RDP_PORT}"
	echo "正在为您启动xrdp服务，本机默认访问地址为localhost:${RDP_PORT}"
	echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${RDP_PORT}
	echo "如需停止xrdp服务，请输service xrdp stop或systemctl stop xrdp"
	echo "如需修改当前用户密码，请输passwd"
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		echo "检测到您使用的是arch系发行版，您之后可以输xrdp来启动xrdp服务"
		xrdp
	fi
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		echo '检测到您使用的是WSL，正在为您打开音频服务'
		export PULSE_SERVER=tcp:127.0.0.1
		if grep -q '172..*1' "/etc/resolv.conf"; then
			echo "检测到您当前使用的可能是WSL2"
			WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
			export PULSE_SERVER=tcp:${WSL2IP}
			echo "已将您的音频服务ip修改为${WSL2IP}"
		fi
		cd "/mnt/c/Users/Public/Downloads/pulseaudio/bin"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat" 2>/dev/null
		echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
	fi
}
#################
xrdp_port() {
	cd /etc/xrdp/
	RDP_PORT=$(cat xrdp.ini | grep 'port=' | head -n 1 | cut -d '=' -f 2)
	TARGET_PORT=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,不建议您将其设置为22、80、443或3389,检测到您当前的端口为${RDP_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		press_enter_to_return_configure_xrdp
	fi
	sed -i "s@port=${RDP_PORT}@port=${TARGET_PORT}@" xrdp.ini
	ls -l $(pwd)/xrdp.ini
	cat xrdp.ini | grep 'port=' | head -n 1
	/etc/init.d/xrdp restart
}
#################
xrdp_systemd() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
		echo "检测到您当前处于chroot容器环境下，无法使用systemctl命令"
	elif [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前处于${BLUE}proot容器${RESET}环境下，无法使用systemctl命令"
	fi

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
	echo "正在停止xrdp进程..."
	echo "Stopping xrdp..."
	pkill xrdp
	service xrdp stop 2>/dev/null
	echo "${YELLOW}WARNING！继续执行此操作将丢失xrdp配置信息！${RESET}"
	RETURN_TO_WHERE='configure_xrdp'
	do_you_want_to_continue
	rm -f /etc/polkit-1/localauthority/50-local.d/45-allow.colord.pkla /etc/polkit-1/localauthority.conf.d/02-allow-colord.conf
	cd ${HOME}/.config/tmoe-linux
	cp -pf xrdp.ini startwm.sh /etc/xrdp/
}
#################################
#################################
configure_startxsdl() {
	cd /usr/local/bin
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
}
#################
configure_startvnc() {
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
		vncserver -geometry 1440x720 -depth 24 -name tmoe-linux :1
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
}
###############
first_configure_startvnc() {
	if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "redhat" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			sed -i 's:dbus-launch::' ~/.vnc/xstartup
		fi
	fi

	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ] && [ -f "/tmp/.Tmoe-XFCE4-Desktop-Detection-FILE" ]; then
		echo "检测到您处于${BLUE}proot容器${RESET}环境下，即将为您${RED}卸载${RESET}${YELLOW}udisk2${RESET}和${GREEN}gvfs${RESET}"
		if [ "${LINUX_DISTRO}" = 'debian' ]; then
			apt purge -y --allow-change-held-packages ^udisks2 ^gvfs
		#else
		#	${PACKAGES_REMOVE_COMMAND} udisks2 gvfs
		fi
	fi
	configure_startvnc
	configure_startxsdl
	###############################
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
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			sed -i 's:dbus-launch::' startxsdl
		fi
	fi
	#下面那行需放在检测完成之后才执行
	rm -f /tmp/.Tmoe-*Desktop-Detection-FILE 2>/dev/null

	######################
	chmod +x startvnc stopvnc startxsdl
	dpkg --configure -a 2>/dev/null
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
	echo "The vnc service is about to start for you. The password you entered is hidden."
	echo "即将为您启动vnc服务，您需要输两遍${RED}（不可见的）${RESET}密码。"
	echo "When prompted for a view-only password, it is recommended that you enter${YELLOW} 'n'${RESET}"
	echo "如果提示${BLUE}view-only${RESET},那么建议您输${YELLOW}n${RESET},选择权在您自己的手上。"
	echo "请输入${RED}6至8位${RESET}${BLUE}密码${RESET}"
	startvnc
	echo "您之后可以输${GREEN}startvnc${RESET}来${BLUE}启动${RESET}vnc服务，输${GREEN}stopvnc${RESET}${RED}停止${RESET}"
	echo "您还可以在termux原系统或windows的linux子系统里输${GREEN}startxsdl${RESET}来启动xsdl，按${YELLOW}Ctrl+C${RESET}或在termux原系统里输${GREEN}stopvnc${RESET}来${RED}停止${RESET}进程"
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
			curl -Lvo "Firewall-pulseaudio.png" 'https://gitee.com/mo2/pic_api/raw/test/2020/03/31/rXLbHDxfj1Vy9HnH.png'
		fi
		/mnt/c/WINDOWS/system32/cmd.exe /c "start Firewall.cpl"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\Firewall-pulseaudio.png" 2>/dev/null
		############
		if [ ! -e 'XserverHightDPI.png' ]; then
			curl -Lvo 'XserverHightDPI.png' https://gitee.com/mo2/pic_api/raw/test/2020/03/27/jvNs2JUIbsSQQInO.png
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
	echo "${GREEN}tightvnc/tigervnc & xserver${RESET}配置${BLUE}完成${RESET},将为您配置${GREEN}x11vnc${RESET}"
	x11vnc_onekey
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	tmoe_linux_tool_menu
}
########################
########################
frequently_asked_questions() {
	TMOE_FAQ=$(whiptail --title "FAQ(よくある質問)" --menu \
		"您有哪些疑问？\nWhat questions do you have?" 15 60 5 \
		"1" "Cannot open Baidu Netdisk" \
		"2" "udisks2/gvfs配置失败" \
		"3" "linuxQQ闪退" \
		"4" "VNC/X11闪退" \
		"5" "软件禁止以root权限运行" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${TMOE_FAQ}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	############################
	if [ "${TMOE_FAQ}" == '1' ]; then
		#echo "若无法打开，则请手动输rm -f ~/baidunetdisk/baidunetdiskdata.db"
		echo "若无法打开，则请手动输rm -rf ~/baidunetdisk"
		echo "按回车键自动执行${YELLOW}rm -vf ~/baidunetdisk/baidunetdiskdata.db${RESET}"
		RETURN_TO_WHERE='frequently_asked_questions'
		do_you_want_to_continue
		rm -vf ~/baidunetdisk/baidunetdiskdata.db
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
	fi
	#######################
	if [ "${TMOE_FAQ}" == '2' ]; then
		echo "${YELLOW}按回车键卸载gvfs和udisks2${RESET}"
		RETURN_TO_WHERE='frequently_asked_questions'
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} --allow-change-held-packages ^udisks2 ^gvfs
		tmoe_linux_tool_menu
	fi
	############################
	if [ "${TMOE_FAQ}" == '3' ]; then
		echo "如果版本更新后登录出现闪退的情况，那么您可以输rm -rf ~/.config/tencent-qq/ 后重新登录。"
		echo "${YELLOW}按回车键自动执行上述命令${RESET}"
		RETURN_TO_WHERE='frequently_asked_questions'
		do_you_want_to_continue
		rm -rvf ~/.config/tencent-qq/
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		tmoe_linux_tool_menu
	fi
	#######################
	if [ "${TMOE_FAQ}" == '4' ]; then
		fix_vnc_dbus_launch
	fi
	#######################
	if [ "${TMOE_FAQ}" == '5' ]; then
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
		echo "您可以输${YELLOW}sudo su - ${RESET}或${YELLOW}sudo -i ${RESET}切换至root用户"
		echo "亦可输${YELLOW}sudo su - mo2${RESET}或${YELLOW}sudo -iu mo2${RESET}切换回mo2用户"
		echo "若需要以普通用户身份启动VNC，请先切换至普通用户，再输${YELLOW}startvnc${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		tmoe_linux_tool_menu
	fi
}
#################
fix_vnc_dbus_launch() {
	echo "由于在2020-0410至0411的更新中给所有系统的桌面都加入了dbus-launch，故在部分安卓设备的${BLUE}proot容器${RESET}上出现了兼容性问题。"
	echo "注1：该操作在linux虚拟机及win10子系统上没有任何问题"
	echo "注2：2020-0412更新的版本已加入检测功能，理论上不会再出现此问题。"
	if [ ! -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前可能处于非proot环境下，是否继续修复？"
		echo "如需重新配置vnc启动脚本，请更新debian-i后再覆盖安装gui"
	fi
	RETURN_TO_WHERE='frequently_asked_questions'
	do_you_want_to_continue

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
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	read
	tmoe_linux_tool_menu
}
###################
###################
beta_features_management_menu() {
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "reinstall重装" --no-button "remove移除" --yesno "检测到您已安装${DEPENDENCY_01} ${DEPENDENCY_02} \nDo you want to reinstall or remove it? ♪(^∇^*) " 10 50); then
		echo "${GREEN} ${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
		echo "即将为您重装..."
	else
		${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
	fi
}
##############
non_debian_function() {
	if [ "${LINUX_DISTRO}" != 'debian' ]; then
		echo "非常抱歉，本功能仅适配deb系发行版"
		echo "Sorry, this feature is only suitable for debian based distributions"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键退出。${RESET}"
		read
		beta_features
	fi
}
############
press_enter_to_reinstall() {
	echo "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
	echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
	press_enter_to_reinstall_yes_or_no
}
################
press_enter_to_reinstall_yes_or_no() {
	echo "按${GREEN}回车键${RESET}${RED}重新安装${RESET},输${YELLOW}n${RESET}${BLUE}返回${RESET}"
	echo "输${YELLOW}m${RESET}打开${BLUE}管理菜单${RESET}"
	echo "${YELLOW}Do you want to reinstall it?[Y/m/n]${RESET}"
	echo "Press enter to reinstall,type n to return,type m to open management menu"
	read opt
	case $opt in
	y* | Y* | "") ;;
	n* | N*)
		echo "skipped."
		beta_features
		;;
	m* | M*)
		beta_features_management_menu
		;;
	*)
		echo "Invalid choice. skipped."
		beta_features
		;;
	esac
}
#######################
beta_features_install_completed() {
	echo "安装${GREEN}完成${RESET}，如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
	echo "The installation is complete. If you want to remove, please enter the above highlighted command."
}
####################
beta_features_quick_install() {
	if [ "${NON_DEBIAN}" = 'true' ]; then
		non_debian_function
	fi
	#############
	if [ ! -z "${DEPENDENCY_01}" ]; then
		DEPENDENCY_01_COMMAND=$(echo ${DEPENDENCY_01} | awk -F ' ' '$0=$NF')
		if [ $(command -v ${DEPENDENCY_01_COMMAND}) ]; then
			echo "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_01} ${RESET}"
			echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${RESET}"
			EXISTS_COMMAND='true'
		fi
	fi
	#############
	if [ ! -z "${DEPENDENCY_02}" ]; then
		DEPENDENCY_02_COMMAND=$(echo ${DEPENDENCY_02} | awk -F ' ' '$0=$NF')
		if [ $(command -v ${DEPENDENCY_02_COMMAND}) ]; then
			echo "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_02} ${RESET}"
			echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_02} ${RESET}"
			EXISTS_COMMAND='true'
		fi
	fi
	###############
	echo "即将为您安装相关依赖..."
	echo "${GREEN} ${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
	echo "Tmoe-linux tool will install relevant dependencies for you."
	############
	if [ "${EXISTS_COMMAND}" = "true" ]; then
		EXISTS_COMMAND='false'
		press_enter_to_reinstall_yes_or_no
	fi

	############
	different_distro_software_install
	#############
	beta_features_install_completed
}
####################
beta_features() {
	TMOE_BETA=$(
		whiptail --title "Beta features" --menu "测试版功能可能无法正常运行\nBeta features may not work properly." 15 60 5 \
			"1" "sunpinyin+google拼音+搜狗拼音" \
			"2" "WPS office(办公软件)" \
			"3" "docker-ce:开源的应用容器引擎" \
			"4" "VirtualBox:甲骨文开源虚拟机(x64)" \
			"5" "gparted:磁盘分区工具" \
			"6" "OBS-Studio(录屏软件)" \
			"7" "typora(markdown编辑器)" \
			"8" "electronic-wechat(第三方微信客户端)" \
			"9" "qbittorrent(P2P下载工具)" \
			"10" "plasma-discover:KDE发现(软件中心)" \
			"11" "gnome-software软件商店" \
			"12" "calibre:电子书转换器和库管理" \
			"13" "文件管理器:thunar/nautilus/dolphin" \
			"14" "krita(数字绘画)" \
			"15" "openshot(视频剪辑)" \
			"16" "fbreader(epub阅读器)" \
			"17" "gnome-system-monitor(资源监视器)" \
			"18" "telegram(注重保护隐私的社交app)" \
			"19" "Grub Customizer(图形化开机引导编辑器)" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${TMOE_BETA}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	####################
	if [ "${TMOE_BETA}" == '1' ]; then
		install_pinyin_input_method
	fi
	####################
	if [ "${TMOE_BETA}" == '2' ]; then
		install_wps_office
	fi
	####################
	if [ "${TMOE_BETA}" == '3' ]; then
		install_docker_ce
	fi
	####################
	if [ "${TMOE_BETA}" == '4' ]; then
		install_virtual_box
	fi
	###################
	if [ "${TMOE_BETA}" == '5' ]; then
		install_gparted
	fi
	####################
	if [ "${TMOE_BETA}" == '6' ]; then
		install_obs_studio
	fi
	############################
	if [ "${TMOE_BETA}" == '7' ]; then
		install_typora
	fi
	############################
	if [ "${TMOE_BETA}" == '8' ]; then
		install_electronic_wechat
	fi
	##############################
	if [ "${TMOE_BETA}" == '9' ]; then
		install_qbitorrent
	fi
	##################################
	if [ "${TMOE_BETA}" == '10' ]; then
		install_plasma_discover
	fi
	##################################
	if [ "${TMOE_BETA}" == '11' ]; then
		install_gnome_software
	fi
	############################
	if [ "${TMOE_BETA}" == '12' ]; then
		install_calibre
	fi
	######################
	if [ "${TMOE_BETA}" == '13' ]; then
		thunar_nautilus_dolphion
	fi
	##############################
	if [ "${TMOE_BETA}" == '14' ]; then
		install_krita
	fi
	################################
	if [ "${TMOE_BETA}" == '15' ]; then
		install_openshot
	fi
	# Blender在WSL2（Xserver）下测试失败，Kdenlive在VNC远程下测试成功。
	##############################
	if [ "${TMOE_BETA}" == '16' ]; then
		install_fbreader
	fi
	##############################
	if [ "${TMOE_BETA}" == '17' ]; then
		install_gnome_system_monitor
	fi
	############################
	if [ "${TMOE_BETA}" == '18' ]; then
		install_telegram
	fi
	############################
	if [ "${TMOE_BETA}" == '19' ]; then
		install_grub_customizer
	fi
	########################################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	beta_features
}
####################
install_pinyin_input_method() {
	DEPENDENCY_01="fcitx"
	DEPENDENCY_02='fcitx-sunpinyin fcitx-googlepinyin'
	NON_DEBIAN='false'
	beta_features_quick_install
	#apt install -y fcitx-sunpinyin  fcitx fcitx-googlepinyin
	#################
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="fcitx-sogoupinyin"
		DEPENDENCY_02=''
		beta_features_quick_install
		echo "fcitx-sogoupinyin安装完成,按回车键返回"
		read
		beta_features
	fi
	#################
	non_debian_function
	echo "检测到您的系统支持安装sogou-pinyin"
	RETURN_TO_WHERE='beta_features'
	do_you_want_to_continue
	DEPENDENCY_02="${DEPENDENCY_02} sogoupinyin"
	###################
	if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "i386" ]; then
		cd /tmp
		LatestSogouPinyinLink=$(curl -L 'https://pinyin.sogou.com/linux' | grep ${ARCH_TYPE} | grep 'deb' | head -n 1 | cut -d '=' -f 3 | cut -d '?' -f 1 | cut -d '"' -f 2)
		curl -Lvo 'sogou_pinyin.deb' "${LatestSogouPinyinLink}"
	else
		echo "架构不支持，跳过安装搜狗输入法。"
		arch_does_not_support
		beta_features
	fi
	apt install -y ./sogou_pinyin.deb
	echo "若安装失败，则请前往官网手动下载安装。"
	echo 'url: https://pinyin.sogou.com/linux/'
	rm -fv sogou_pinyin.deb
	beta_features_install_completed
}
############
install_gnome_system_monitor() {
	DEPENDENCY_01="gnome-system-monitor"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
###############
debian_add_docker_gpg() {
	if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
		DOCKER_RELEASE='ubuntu'
	else
		DOCKER_RELEASE='debian'
	fi

	curl -Lv https://download.docker.com/linux/${DOCKER_RELEASE}/gpg | apt-key add -
	cd /etc/apt/sources.list.d/
	sed -i 's/^deb/# &/g' docker.list
	DOCKER_CODE="$(lsb_release -cs)"

	if [ ! $(command -v lsb_release) ]; then
		DOCKER_CODE="buster"
	fi

	if [ "$(lsb_release -cs)" = "focal" ]; then
		DOCKER_CODE="eoan"
	#2020-05-05：暂没有focal的仓库
	elif [ "$(lsb_release -cs)" = "bullseye" ]; then
		DOCKER_CODE="buster"
	elif [ "$(lsb_release -cs)" = "bookworm" ]; then
		DOCKER_CODE="bullseye"
	fi
	echo "deb https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/${DOCKER_RELEASE} ${DOCKER_CODE} stable" >>docker.list
	#$(#lsb_release -cs)
}
#################
install_docker_ce() {
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
		echo "若您使用的是${BOLD}Android${RESET}系统，则请在安装前${BLUE}确保${RESET}您的Linux内核支持docker"
		echo "否则请直接退出安装！！！"
		RETURN_TO_WHERE='beta_features'
		do_you_want_to_continue
	fi

	NON_DEBIAN='false'
	if [ ! $(command -v gpg) ]; then
		DEPENDENCY_01=""
		DEPENDENCY_02="gpg"
		beta_features_quick_install
	else
		DEPENDENCY_02=""
	fi
	DEPENDENCY_01="docker-ce"
	#apt remove docker docker-engine docker.io
	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		debian_add_docker_gpg
	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		curl -Lvo /etc/yum.repos.d/docker-ce.repo "https://download.docker.com/linux/${REDHAT_DISTRO}/docker-ce.repo"
		sed -i 's@download.docker.com@mirrors.tuna.tsinghua.edu.cn/docker-ce@g' /etc/yum.repos.d/docker-ce.repo
	elif [ "${LINUX_DISTRO}" = 'arch' ]; then
		DEPENDENCY_01="docker"
	fi
	beta_features_quick_install
	if [ ! $(command -v docker) ]; then
		echo "安装失败，请执行${PACKAGES_INSTALL_COMMAND} docker.io"
	fi

}
#################
debian_add_virtual_box_gpg() {
	if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
		VBOX_RELEASE='bionic'
	else
		VBOX_RELEASE='buster'
	fi
	curl -Lv https://www.virtualbox.org/download/oracle_vbox_2016.asc | apt-key add -
	cd /etc/apt/sources.list.d/
	sed -i 's/^deb/# &/g' virtualbox.list
	echo "deb http://mirrors.tuna.tsinghua.edu.cn/virtualbox/apt/ ${VBOX_RELEASE} contrib" >>virtualbox.list
}
###############
get_debian_vbox_latest_url() {
	TUNA_VBOX_LINK='https://mirrors.tuna.tsinghua.edu.cn/virtualbox/apt/pool/contrib/v/'
	LATEST_VBOX_VERSION=$(curl -L ${TUNA_VBOX_LINK} | grep 'virtualbox-' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
		LATEST_VBOX_FILE=$(curl -L ${TUNA_VBOX_LINK}${LATEST_VBOX_VERSION} | grep -E "Ubuntu" | head -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	else
		LATEST_VBOX_FILE=$(curl -L ${TUNA_VBOX_LINK}${LATEST_VBOX_VERSION} | grep -E "Debian" | head -n 1 | cut -d '=' -f 7 | cut -d '"' -f 2)
	fi
	VBOX_DEB_FILE_URL="${TUNA_VBOX_LINK}${LATEST_VBOX_VERSION}${LATEST_VBOX_FILE}"
	echo "获取到vbox的最新链接为${VBOX_DEB_FILE_URL},是否下载并安装？"
	RETURN_TO_WHERE='beta_features'
	do_you_want_to_continue
	cd /tmp
	curl -Lo .Oracle_VIRTUAL_BOX.deb "${VBOX_DEB_FILE_URL}"
	apt install -y ./.Oracle_VIRTUAL_BOX.deb
	rm -fv ./.Oracle_VIRTUAL_BOX.deb
}
################
debian_download_latest_vbox_deb() {
	if [ ! $(command -v virtualbox) ]; then
		get_debian_vbox_latest_url
	else
		echo "检测到您已安装virtual box，是否将其添加到软件源？"
		RETURN_TO_WHERE='beta_features'
		do_you_want_to_continue
		debian_add_virtual_box_gpg
	fi
}
#############
redhat_add_virtual_box_repo() {
	cat >/etc/yum.repos.d/virtualbox.repo <<-'EndOFrepo'
		[virtualbox]
		name=Virtualbox Repository
		baseurl=https://mirrors.tuna.tsinghua.edu.cn/virtualbox/rpm/el$releasever/
		gpgcheck=0
		enabled=1
	EndOFrepo
}
###############
install_virtual_box() {
	if [ "${ARCH_TYPE}" != "amd64" ]; then
		arch_does_not_support
		beta_features
	fi

	NON_DEBIAN='false'
	if [ ! $(command -v gpg) ]; then
		DEPENDENCY_01=""
		DEPENDENCY_02="gpg"
		beta_features_quick_install
	else
		DEPENDENCY_02=""
		#linux-headers
	fi
	DEPENDENCY_01="virtualbox"
	#apt remove docker docker-engine docker.io
	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		debian_download_latest_vbox_deb
	#$(#lsb_release -cs)
	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		redhat_add_virtual_box_repo
	elif [ "${LINUX_DISTRO}" = 'arch' ]; then
		DEPENDENCY_01="virtualbox virtualbox-guest-iso"
		DEPENDENCY_02="virtualbox-ext-oracle"
		echo "您可以在安装完成后，输usermod -G vboxusers -a 当前用户名称"
		echo "将当前用户添加至vboxusers用户组"
		#
	fi
	echo "您可以输modprobe vboxdrv vboxnetadp vboxnetflt来加载内核模块"
	beta_features_quick_install
	####################
	if [ ! $(command -v virtualbox) ]; then
		echo "检测到virtual box安装失败，是否将其添加到软件源？"
		RETURN_TO_WHERE='beta_features'
		do_you_want_to_continue
		debian_add_virtual_box_gpg
		beta_features_quick_install
	fi
}
################
install_gparted() {
	DEPENDENCY_01="gparted"
	DEPENDENCY_02="baobab"
	NON_DEBIAN='false'
	beta_features_quick_install
}
################
install_typora() {
	DEPENDENCY_01="typora"
	DEPENDENCY_02=""
	NON_DEBIAN='true'
	beta_features_quick_install
	cd /tmp
	if [ "$(uname -m)" = "x86_64" ]; then
		curl -Lvo 'typora.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/t/typora/typora_0.9.67-1_amd64.deb'
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		curl -Lvo 'typora.deb' 'https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/non-free/t/typora/typora_0.9.22-1_i386.deb'
	else
		arch_does_not_support
	fi
	apt install -y ./typora.deb
	rm -vf ./typora.deb
	beta_features_install_completed
}
####################
install_wps_office() {
	DEPENDENCY_01="wps-office"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	cd /tmp
	if [ -e "/usr/share/applications/wps-office-wps.desktop" ]; then
		press_enter_to_reinstall
	fi

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		LatestWPSLink=$(curl -L https://linux.wps.cn/ | grep '\.deb' | grep -i "${ARCH_TYPE}" | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
		curl -Lvo WPSoffice.deb "${LatestWPSLink}"
		apt install -y ./WPSoffice.deb

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="wps-office-cn"
		beta_features_quick_install
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		LatestWPSLink=$(curl -L https://linux.wps.cn/ | grep '\.rpm' | grep -i "$(uname -m)" | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
		curl -Lvo WPSoffice.rpm "https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9505/wps-office-11.1.0.9505-1.x86_64.rpm"
		rpm -ivh ./WPSoffice.rpm
	fi

	echo "若安装失败，则请前往官网手动下载安装。"
	echo "url: https://linux.wps.cn"
	rm -fv ./WPSoffice.deb ./WPSoffice.rpm 2>/dev/null
	beta_features_install_completed
}
###################
thunar_nautilus_dolphion() {
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前使用的是${BLUE}proot容器${RESET}，请勿安装${RED}dolphion${RESET}"
		echo "安装后将有可能导致VNC黑屏"
		echo "请选择${GREEN}thunar${RESET}或${GREEN}nautilus${RESET}"
	fi
	DEPENDENCY_02=""
	echo "${YELLOW}Which file manager do you want to install?[t/n/d/r]${RESET}"
	echo "请选择您需要安装的${BLUE}文件管理器${RESET}，输${YELLOW}t${RESET}安装${GREEN}thunar${RESET},输${YELLOW}n${RESET}安装${GREEN}nautilus${RESET}，输${YELLOW}d${RESET}安装${GREEN}dolphion${RESET}，输${YELLOW}r${RESET}${BLUE}返回${RESET}。"
	echo "Type t to install thunar,type n to install nautils,type d to install dolphin,type r to return."
	read opt
	case $opt in
	t* | T* | "")
		DEPENDENCY_01="thunar"
		;;
	n* | N*)
		DEPENDENCY_01="nautilus"
		;;
	d* | D*)
		DEPENDENCY_02="dolphin"
		;;
	r* | R*)
		beta_features
		;;
	*)
		echo "Invalid choice. skipped."
		beta_features
		#beta_features
		;;
	esac
	NON_DEBIAN='false'
	beta_features_quick_install
}
##################
install_electronic_wechat() {
	DEPENDENCY_01="electronic-wechat"
	DEPENDENCY_02=""
	NON_DEBIAN='true'
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="electron-wechat"
		NON_DEBIAN='false'
	fi
	beta_features_quick_install
	non_debian_function
	cd /tmp
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		curl -Lvo 'electronic-wechat.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/e/electronic-wechat/electronic-wechat_2.0~repack0~debiancn0_amd64.deb'
		#curl -Lvo 'electronic-wechat.deb' 'http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/electronic-wechat_2.0.1_amd64.deb'
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		curl -Lvo 'electronic-wechat.deb' 'http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/electronic-wechat_2.0.1_i386.deb'
	else
		arch_does_not_support
	fi

	apt install -y ./electronic-wechat.deb
	rm -vf ./electronic-wechat.deb
	beta_features_install_completed
}
#############
install_gnome_software() {
	DEPENDENCY_01="gnome-software"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
#############
install_obs_studio() {
	if [ ! $(command -v ffmpeg) ]; then
		DEPENDENCY_01="ffmpeg"
	else
		DEPENDENCY_01=""
	fi

	if [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_02="media-video/obs-studio"
	else
		DEPENDENCY_02="obs-studio"
	fi

	NON_DEBIAN='false'
	beta_features_quick_install

	if [ "${LINUX_DISTRO}" = "redhat" ]; then
		if [ $(command -v dnf) ]; then
			dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
			dnf install -y obs-studio
		else
			yum install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
			yum install -y obs-studio
		fi
		#dnf install xorg-x11-drv-nvidia-cuda
	fi
	echo "若安装失败，则请前往官网阅读安装说明。"
	echo "url: https://obsproject.com/wiki/install-instructions#linux"
	beta_features_install_completed
}
################
install_openshot() {
	DEPENDENCY_01="openshot"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	echo "您亦可选择其他视频剪辑软件，Blender在Xserver下测试失败，Kdenlive在VNC远程下测试成功。"
	beta_features_quick_install
}
############################
install_telegram() {
	DEPENDENCY_01="telegram-desktop"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
######################
install_grub_customizer() {
	DEPENDENCY_01="grub-customizer"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
############################
install_qbitorrent() {
	DEPENDENCY_01="qbittorrent"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}

############################
install_plasma_discover() {
	DEPENDENCY_01="plasma-discover"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}

############################
install_calibre() {
	DEPENDENCY_01="calibre"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}

############################
install_krita() {
	DEPENDENCY_01="krita"
	DEPENDENCY_02="krita-l10n"
	NON_DEBIAN='false'
	beta_features_quick_install
}
############################
install_fbreader() {
	DEPENDENCY_01="fbreader"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
################
################
personal_netdisk() {
	WHICH_NETDISK=$(whiptail --title "FILE SHARE SERVER" --menu "你想要使用哪个软件来共享文件呢" 14 50 6 \
		"1" "Filebrowser:简单轻量的个人网盘" \
		"2" "Nginx WebDAV:比ftp更适合用于传输流媒体" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${WHICH_NETDISK}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	############################
	if [ "${WHICH_NETDISK}" == '1' ]; then
		install_filebrowser
	fi
	###########################
	if [ "${WHICH_NETDISK}" == '2' ]; then
		install_nginx_webdav
	fi
	#########################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
################################
################################
install_nginx_webdav() {

	pgrep nginx &>/dev/null
	if [ "$?" = "0" ]; then
		FILEBROWSER_STATUS='检测到nginx进程正在运行'
		FILEBROWSER_PROCESS='Restart重启'
	else
		FILEBROWSER_STATUS='检测到nginx进程未运行'
		FILEBROWSER_PROCESS='Start启动'
	fi

	if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${FILEBROWSER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${FILEBROWSER_STATUS}" 9 50); then
		if [ ! -e "/etc/nginx/conf.d/webdav.conf" ]; then
			echo "检测到配置文件不存在，2s后将为您自动配置服务。"
			sleep 2s
			nginx_onekey
		fi
		nginx_restart
	else
		configure_nginx_webdav
	fi
}

#############
configure_nginx_webdav() {
	#进入nginx webdav配置文件目录
	cd /etc/nginx/conf.d/
	TMOE_OPTION=$(whiptail --title "CONFIGURE WEBDAV" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
		"1" "One-key conf 初始化一键配置" \
		"2" "管理访问账号" \
		"3" "view logs 查看日志" \
		"4" "WebDAV port 修改webdav端口" \
		"5" "Nginx port 修改nginx端口" \
		"6" "进程管理说明" \
		"7" "stop 停止" \
		"8" "Root dir修改根目录" \
		"9" "reset nginx重置nginx" \
		"10" "remove 卸载/移除" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${TMOE_OPTION}" == '0' ]; then
		#tmoe_linux_tool_menu
		personal_netdisk
	fi
	##############################
	if [ "${TMOE_OPTION}" == '1' ]; then
		pkill nginx
		service nginx stop 2>/dev/null
		nginx_onekey
	fi
	##############################
	if [ "${TMOE_OPTION}" == '2' ]; then
		nginx_add_admin
	fi
	##############################
	if [ "${TMOE_OPTION}" == '3' ]; then
		nginx_logs
	fi
	##############################
	if [ "${TMOE_OPTION}" == '4' ]; then
		nginx_webdav_port
	fi
	##############################
	if [ "${TMOE_OPTION}" == '5' ]; then
		nginx_port
	fi
	##############################
	if [ "${TMOE_OPTION}" == '6' ]; then
		nginx_systemd
	fi
	##############################
	if [ "${TMOE_OPTION}" == '7' ]; then
		echo "正在停止服务进程..."
		echo "Stopping..."
		pkill nginx
		service nginx stop 2>/dev/null
		service nginx status
	fi
	##############################
	if [ "${TMOE_OPTION}" == '8' ]; then
		nginx_webdav_root_dir
	fi
	##############################
	if [ "${TMOE_OPTION}" == '9' ]; then
		echo "正在停止nginx进程..."
		echo "Stopping nginx..."
		pkill nginx
		service nginx stop 2>/dev/null
		nginx_reset
	fi
	##############################
	if [ "${TMOE_OPTION}" == '10' ]; then
		pkill nginx
		echo "正在停止nginx进程..."
		echo "Stopping nginx..."
		service nginx stop 2>/dev/null
		rm -fv /etc/nginx/conf.d/webdav.conf
		echo "${YELLOW}已删除webdav配置文件,${RESET}"
		echo "是否继续卸载nginx?"
		echo "您正在执行危险操作，卸载nginx将导致您部署的所有网站无法访问！！！"
		echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
		service nginx restart
		RETURN_TO_WHERE='configure_nginx_webdav'
		do_you_want_to_continue
		service nginx stop
		${PACKAGES_REMOVE_COMMAND} nginx nginx-extras
	fi
	########################################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	configure_nginx_webdav
}
##############
nginx_onekey() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ] || [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您处于${BLUE}chroot/proot容器${RESET}环境下，部分功能可能出现异常。"
		echo "部分系统可能会出现failed，但仍能正常连接。"
		CHROOT_STATUS='1'
	fi
	echo "本服务依赖于软件源仓库的nginx,可能无法与宝塔等第三方面板的nginx相互兼容"
	echo "若80和443端口被占用，则有可能导致nginx启动失败，请修改nginx为1000以上的高位端口。"
	echo "安装完成后，若浏览器测试连接成功，则您可以换用文件管理器进行管理。"
	echo "例如Android端的Solid Explorer,windows端的RaiDrive"
	echo 'Press Enter to confirm.'
	echo "默认webdav根目录为/media，您可以在安装完成后自行修改。"
	RETURN_TO_WHERE='configure_nginx_webdav'
	do_you_want_to_continue

	DEPENDENCY_01='nginx'
	DEPENDENCY_02='apache2-utils'
	NON_DEBIAN='false'

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01="${DEPENDENCY_01} nginx-extras"
	fi
	beta_features_quick_install
	##############
	mkdir -p /media
	touch "/media/欢迎使用tmoe-linux-webdav_你可以将文件复制至根目录下的media文件夹"
	if [ -e "/root/sd" ]; then
		ln -sf /root/sd /media/
	fi

	if [ -e "/root/tf" ]; then
		ln -sf /root/tf /media/
	fi

	if [ -e "/root/termux" ]; then
		ln -sf /root/sd /media/
	fi

	if [ "${CHROOT_STATUS}" = "1" ]; then
		echo "检测到您处于容器环境下"
		cd /etc/nginx/sites-available
		if [ ! -f "default.tar.gz" ]; then
			tar -zcvf default.tar.gz default
		fi
		tar -zxvf default.tar.gz default
		ls -lh /etc/nginx/sites-available/default
		sed -i 's@80 default_server@2086 default_server@g' default
		sed -i 's@443 ssl default_server@8443 ssl default_server@g' default
		echo "已将您的nginx的http端口从80修改为2086，https端口从443修改为8443"
	fi

	cd /etc/nginx/conf.d/
	cat >webdav.conf <<-'EndOFnginx'
		server {
		    listen       28080;
		    server_name  webdav;
		    error_log /var/log/nginx/webdav.error.log error;
		    access_log  /var/log/nginx/webdav.access.log combined;
		    location / {
		        root /media;
		        charset utf-8;
		        autoindex on;
		        dav_methods PUT DELETE MKCOL COPY MOVE;
		        dav_ext_methods PROPFIND OPTIONS;
		        create_full_put_path  on;
		        dav_access user:rw group:r all:r;
		        auth_basic "Not currently available";
		        auth_basic_user_file /etc/nginx/conf.d/.htpasswd.webdav;
		    }
		    error_page   500 502 503 504  /50x.html;
		    location = /50x.html {
		        root   /usr/share/nginx/html;
		    }
		}
	EndOFnginx
	#############
	TARGET_USERNAME=$(whiptail --inputbox "请自定义webdav用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "用户名无效，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		nginx_onekey
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		nginx_onekey
	fi
	htpasswd -mbc /etc/nginx/conf.d/.htpasswd.webdav ${TARGET_USERNAME} ${TARGET_USERPASSWD}
	nginx -t
	if [ "$?" != "0" ]; then
		sed -i 's@dav_methods@# &@' webdav.conf
		sed -i 's@dav_ext_methods@# &@' webdav.conf
		nginx -t
	fi
	nginx_restart
	########################################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	configure_nginx_webdav
	#此处的返回步骤并非多余
}
############
nginx_restart() {
	cd /etc/nginx/conf.d/
	NGINX_WEBDAV_PORT=$(cat webdav.conf | grep listen | head -n 1 | cut -d ';' -f 1 | awk -F ' ' '$0=$NF')
	service nginx restart 2>/dev/null
	if [ "$?" != "0" ]; then
		/etc/init.d/nginx reload
	fi
	service nginx status 2>/dev/null
	if [ "$?" = "0" ]; then
		echo "您可以输${YELLOW}service nginx stop${RESET}来停止进程"
	else
		echo "您可以输${YELLOW}/etc/init.d/nginx stop${RESET}来停止进程"
	fi
	cat /var/log/nginx/webdav.error.log | tail -n 10
	cat /var/log/nginx/webdav.access.log | tail -n 10
	echo "正在为您启动nginx服务，本机默认访问地址为localhost:${NGINX_WEBDAV_PORT}"
	echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${NGINX_WEBDAV_PORT}
	echo The WAN VNC address 外网地址 $(curl -sL ip.sb | head -n 1):${NGINX_WEBDAV_PORT}
	echo "${YELLOW}您可以使用文件管理器或浏览器来打开WebDAV访问地址${RESET}"
	echo "Please use your browser to open the access address"
}
#############
nginx_add_admin() {
	TARGET_USERNAME=$(whiptail --inputbox "您正在重置webdav访问用户,请输入新用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "用户名无效，操作取消"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		configure_nginx_webdav
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		nginx_add_admin
	fi
	htpasswd -mbc /etc/nginx/conf.d/.htpasswd.webdav ${TARGET_USERNAME} ${TARGET_USERPASSWD}
	nginx_restart
}
#################
nginx_webdav_port() {
	NGINX_WEBDAV_PORT=$(cat webdav.conf | grep listen | head -n 1 | cut -d ';' -f 1 | awk -F ' ' '$0=$NF')
	TARGET_PORT=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,检测到您当前的端口为${NGINX_WEBDAV_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		configure_nginx_webdav
	fi
	sed -i "s@${NGINX_WEBDAV_PORT}\;@${TARGET_PORT}\;@" webdav.conf
	ls -l $(pwd)/webdav.conf
	cat webdav.conf | grep listen
	/etc/init.d/nginx reload
}
#################
nginx_port() {
	cd /etc/nginx/sites-available
	NGINX_PORT=$(cat default | grep -E 'listen|default' | head -n 1 | cut -d ';' -f 1 | cut -d 'd' -f 1 | awk -F ' ' '$0=$NF')
	TARGET_PORT=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,检测到您当前的Nginx端口为${NGINX_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		configure_nginx_webdav
	fi
	cp -pvf default default.bak
	tar -zxvf default.tar.gz default
	sed -i "s@80 default_server@${TARGET_PORT} default_server@g" default
	ls -l $(pwd)/default
	cat default | grep -E 'listen|default' | grep -v '#'
	/etc/init.d/nginx reload
}
############
nginx_logs() {
	cat /var/log/nginx/webdav.error.log | tail -n 10
	if [ $(command -v less) ]; then
		cat /var/log/nginx/webdav.access.log | less -meQ
	else
		cat /var/log/nginx/webdav.access.log | tail -n 10
	fi
	ls -lh /var/log/nginx/webdav.error.log
	ls -lh /var/log/nginx/webdav.access.log
}
#############
nginx_webdav_root_dir() {
	NGINX_WEBDAV_ROOT_DIR=$(cat webdav.conf | grep root | head -n 1 | cut -d ';' -f 1 | awk -F ' ' '$0=$NF')
	TARGET_PATH=$(whiptail --inputbox "请输入新的路径,例如/media/root,检测到您当前的webDAV根目录为${NGINX_WEBDAV_ROOT_DIR}\n Please enter the port number." 12 50 --title "PATH" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		configure_nginx_webdav
	fi
	sed -i "s@${NGINX_WEBDAV_ROOT_DIR}\;@${TARGET_PATH}\;@" webdav.conf
	ls -l $(pwd)/webdav.conf
	echo "您当前的webdav根目录已修改为$(cat webdav.conf | grep root | head -n 1 | cut -d ';' -f 1 | awk -F ' ' '$0=$NF')"
	/etc/init.d/nginx reload
}
#################
nginx_systemd() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
		echo "检测到您当前处于chroot容器环境下，无法使用systemctl命令"
	elif [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前处于${BLUE}proot容器${RESET}环境下，无法使用systemctl命令"
	fi

	cat <<-'EOF'
		    systemd管理
			输systemctl start nginx启动
			输systemctl stop nginx停止
			输systemctl status nginx查看进程状态
			输systemctl enable nginx开机自启
			输systemctl disable nginx禁用开机自启

			service命令
			输service nginx start启动
			输service nginx stop停止
			输service nginx status查看进程状态

		    init.d管理
			/etc/init.d/nginx start启动
			/etc/init.d/nginx restart重启
			/etc/init.d/nginx stop停止
			/etc/init.d/nginx statuss查看进程状态
			/etc/init.d/nginx reload重新加载

	EOF
}
###############
nginx_reset() {
	echo "${YELLOW}WARNING！继续执行此操作将丢失nginx配置信息！${RESET}"
	RETURN_TO_WHERE='configure_nginx_webdav'
	do_you_want_to_continue
	cd /etc/nginx/sites-available
	tar zcvf default.tar.gz default
}
###############
install_filebrowser() {
	if [ ! $(command -v filebrowser) ]; then
		cd /tmp
		if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "arm64" ]; then
			rm -rf .FileBrowserTEMPFOLDER
			git clone -b linux_${ARCH_TYPE} --depth=1 https://gitee.com/mo2/filebrowser.git ./.FileBrowserTEMPFOLDER
			cd /usr/local/bin
			tar -Jxvf /tmp/.FileBrowserTEMPFOLDER/filebrowser.tar.xz filebrowser
			chmod +x filebrowser
			rm -rf /tmp/.FileBrowserTEMPFOLDER
		else
			#https://github.com/filebrowser/filebrowser/releases
			#curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
			if [ "${ARCH_TYPE}" = "armhf" ]; then
				curl -Lvo .filebrowser.tar.gz 'https://github.com/filebrowser/filebrowser/releases/download/v2.1.0/linux-armv7-filebrowser.tar.gz'
			elif [ "${ARCH_TYPE}" = "i386" ]; then
				curl -Lvo .filebrowser.tar.gz 'https://github.com/filebrowser/filebrowser/releases/download/v2.1.0/linux-386-filebrowser.tar.gz'
			fi
			cd /usr/local/bin
			tar -zxvf /tmp/.filebrowser.tar.gz filebrowser
			chmod +x filebrowser
			rm -rf /tmp/.filebrowser.tar.gz
		fi
	fi
	pgrep filebrowser &>/dev/null
	if [ "$?" = "0" ]; then
		FILEBROWSER_STATUS='检测到filebrowser进程正在运行'
		FILEBROWSER_PROCESS='Restart重启'
	else
		FILEBROWSER_STATUS='检测到filebrowser进程未运行'
		FILEBROWSER_PROCESS='Start启动'
	fi

	if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${FILEBROWSER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${FILEBROWSER_STATUS}" 9 50); then
		if [ ! -e "/etc/filebrowser.db" ]; then
			echo "检测到数据库文件不存在，2s后将为您自动配置服务。"
			sleep 2s
			filebrowser_onekey
		fi
		filebrowser_restart
	else
		configure_filebrowser
	fi
}
############
configure_filebrowser() {
	#先进入etc目录，防止database加载失败
	cd /etc
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE FILEBROWSER" --menu "您想要修改哪项配置？修改配置前将自动停止服务。" 14 50 5 \
			"1" "One-key conf 初始化一键配置" \
			"2" "add admin 新建管理员" \
			"3" "port 修改端口" \
			"4" "view logs 查看日志" \
			"5" "language语言环境" \
			"6" "listen addr/ip 监听ip" \
			"7" "进程管理说明" \
			"8" "stop 停止" \
			"9" "reset 重置所有配置信息" \
			"10" "remove 卸载/移除" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${TMOE_OPTION}" == '0' ]; then
		#tmoe_linux_tool_menu
		personal_netdisk
	fi
	##############################
	if [ "${TMOE_OPTION}" == '1' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_onekey
	fi
	##############################
	if [ "${TMOE_OPTION}" == '2' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_add_admin
	fi
	##############################
	if [ "${TMOE_OPTION}" == '3' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_port
	fi
	##############################
	if [ "${TMOE_OPTION}" == '4' ]; then
		filebrowser_logs
	fi
	##############################
	if [ "${TMOE_OPTION}" == '5' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_language
	fi
	##############################
	if [ "${TMOE_OPTION}" == '6' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_listen_ip
	fi
	##############################
	if [ "${TMOE_OPTION}" == '7' ]; then
		filebrowser_systemd
	fi
	##############################
	if [ "${TMOE_OPTION}" == '8' ]; then
		echo "正在停止服务进程..."
		echo "Stopping..."
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		service filebrowser status 2>/dev/null
	fi
	##############################
	if [ "${TMOE_OPTION}" == '9' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_reset
	fi
	##############################
	if [ "${TMOE_OPTION}" == '10' ]; then
		RETURN_TO_WHERE='configure_filebrowser'
		do_you_want_to_continue
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		rm -fv /usr/local/bin/filebrowser
		rm -fv /etc/systemd/system/filebrowser.service
		rm -fv /etc/filebrowser.db
	fi
	########################################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	configure_filebrowser
}
##############
filebrowser_onekey() {
	cd /etc
	#初始化数据库文件
	filebrowser -d filebrowser.db config init
	#监听0.0.0.0
	filebrowser config set --address 0.0.0.0
	#设定根目录为当前主目录
	filebrowser config set --root ${HOME}
	filebrowser config set --port 38080
	#设置语言环境为中文简体
	filebrowser config set --locale zh-cn
	#修改日志文件路径
	#filebrowser config set --log /var/log/filebrowser.log
	TARGET_USERNAME=$(whiptail --inputbox "请输入自定义用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "用户名无效，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		filebrowser_onekey
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定管理员密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		filebrowser_onekey
	fi
	filebrowser users add ${TARGET_USERNAME} ${TARGET_USERPASSWD} --perm.admin
	#filebrowser users update ${TARGET_USERNAME} ${TARGET_USERPASSWD}

	cat >/etc/systemd/system/filebrowser.service <<-'EndOFsystemd'
		[Unit]
		Description=FileBrowser
		After=network.target
		Wants=network.target

		[Service]
		Type=simple
		PIDFile=/var/run/filebrowser.pid
		ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser.db
		Restart=on-failure

		[Install]
		WantedBy=multi-user.target
	EndOFsystemd
	chmod +x /etc/systemd/system/filebrowser.service
	systemctl daemon-reload 2>/dev/null
	#systemctl start filebrowser
	#service filebrowser start
	if (whiptail --title "systemctl enable filebrowser？" --yes-button 'Yes' --no-button 'No！' --yesno "是否需要将此服务设置为开机自启？" 9 50); then
		systemctl enable filebrowser
	fi
	filebrowser_restart
	########################################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	configure_filebrowser
	#此处的返回步骤并非多余
}
############
filebrowser_restart() {
	FILEBROWSER_PORT=$(cat /etc/filebrowser.db | grep -a port | sed 's@,@\n@g' | grep -a port | head -n 1 | cut -d ':' -f 2 | cut -d '"' -f 2)
	service filebrowser restart 2>/dev/null
	if [ "$?" != "0" ]; then
		pkill filebrowser
		nohup /usr/local/bin/filebrowser -d /etc/filebrowser.db 2>&1 >/var/log/filebrowser.log &
		cat /var/log/filebrowser.log | tail -n 20
	fi
	service filebrowser status 2>/dev/null
	if [ "$?" = "0" ]; then
		echo "您可以输${YELLOW}service filebrowser stop${RESET}来停止进程"
	else
		echo "您可以输${YELLOW}pkill filebrowser${RESET}来停止进程"
	fi
	echo "正在为您启动filebrowser服务，本机默认访问地址为localhost:${FILEBROWSER_PORT}"
	echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${FILEBROWSER_PORT}
	echo The WAN VNC address 外网地址 $(curl -sL ip.sb | head -n 1):${FILEBROWSER_PORT}
	echo "${YELLOW}请使用浏览器打开上述地址${RESET}"
	echo "Please use your browser to open the access address"
}
#############
filebrowser_add_admin() {
	pkill filebrowser
	service filebrowser stop 2>/dev/null
	echo "Stopping filebrowser..."
	echo "正在停止filebrowser进程..."
	echo "正在检测您当前已创建的用户..."
	filebrowser -d /etc/filebrowser.db users ls
	echo 'Press Enter to continue.'
	echo "${YELLOW}按回车键继续。${RESET}"
	read
	TARGET_USERNAME=$(whiptail --inputbox "请输入自定义用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "用户名无效，操作取消"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		configure_filebrowser
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定管理员密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		filebrowser_add_admin
	fi
	cd /etc
	filebrowser users add ${TARGET_USERNAME} ${TARGET_USERPASSWD} --perm.admin
	#filebrowser users update ${TARGET_USERNAME} ${TARGET_USERPASSWD} --perm.admin
}
#################
filebrowser_port() {
	FILEBROWSER_PORT=$(cat /etc/filebrowser.db | grep -a port | sed 's@,@\n@g' | grep -a port | head -n 1 | cut -d ':' -f 2 | cut -d '"' -f 2)
	TARGET_PORT=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,检测到您当前的端口为${FILEBROWSER_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		configure_filebrowser
	fi
	filebrowser config set --port ${TARGET_PORT}
}
############
filebrowser_logs() {
	if [ ! -f "/var/log/filebrowser.log" ]; then
		echo "日志文件不存在，您可能没有启用记录日志的功能"
		echo "${YELLOW}按回车键启用。${RESET}"
		read
		filebrowser -d /etc/filebrowser.db config set --log /var/log/filebrowser.log
	fi
	ls -lh /var/log/filebrowser.log
	echo "按Ctrl+C退出日志追踪，press Ctrl+C to exit."
	tail -Fvn 35 /var/log/filebrowser.log
	#if [ $(command -v less) ]; then
	#	cat /var/log/filebrowser.log | less -meQ
	#else
	#	cat /var/log/filebrowser.log
	#fi

}
#################
filebrowser_language() {
	TARGET_LANG=$(whiptail --inputbox "Please enter the language format, for example en,zh-cn" 12 50 --title "LANGUAGE" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		configure_filebrowser
	fi
	filebrowser config set --port ${TARGET_LANG}
}
###############
filebrowser_listen_ip() {
	TARGET_IP=$(whiptail --inputbox "Please enter the listen address, for example 0.0.0.0\n默认情况下无需修改。" 12 50 --title "listen" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		configure_filebrowser
	fi
	filebrowser config set --address ${TARGET_IP}
}
##################
filebrowser_systemd() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
		echo "检测到您当前处于chroot容器环境下，无法使用systemctl命令"
	elif [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前处于${BLUE}proot容器${RESET}环境下，无法使用systemctl命令"
	fi

	cat <<-'EOF'
		systemd管理
			输systemctl start filebrowser启动
			输systemctl stop filebrowser停止
			输systemctl status filebrowser查看进程状态
			输systemctl enable filebrowser开机自启
			输systemctl disable filebrowser禁用开机自启

			service命令
			输service filebrowser start启动
			输service filebrowser stop停止
			输service filebrowser status查看进程状态
		        
		    其它命令(适用于service和systemctl都无法使用的情况)
			输debian-i file启动
			pkill filebrowser停止
	EOF
}
###############
filebrowser_reset() {
	echo "${YELLOW}WARNING！继续执行此操作将丢失所有配置信息！${RESET}"
	RETURN_TO_WHERE='configure_filebrowser'
	do_you_want_to_continue
	rm -vf filebrowser.db
	filebrowser -d filebrowser.db config init
}

###########################################
main "$@"
########################################################################
