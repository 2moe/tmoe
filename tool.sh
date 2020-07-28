#!/bin/bash
########################################################################
main() {
	check_linux_distro
	check_architecture
	check_current_user_name_and_group
	case "$1" in
	i | -i)
		tmoe_linux_tool_menu
		;;
	aria2)
		tmoe_aria2_manager
		;;
	--install-gui | install-gui)
		install_gui
		;;
	--modify_remote_desktop_config)
		modify_remote_desktop_config
		;;
	qemu)
		start_tmoe_qemu_manager
		;;
	--remove_gui)
		remove_gui
		;;
	--mirror-list | -m* | m*)
		tmoe_sources_list_manager
		;;
	up* | -u*)
		tmoe_linux_tool_upgrade
		;;
	passwd | -passwd)
		set_vnc_passwd
		check_mouse_cursor
		#check_libreoffice_patch
		#check_pic_go_sandbox
		;;
	h | -h | --help)
		cat <<-'EOF'
			-ppa     --添加ppa软件源(add ppa source)   
			-u       --更新(update tmoe-linux tool)
			-m       --切换镜像源
			-tuna    --切换为tuna源
			file     --运行文件浏览器(run filebrowser)
			qemu     --x64 qemu虚拟机管理
		EOF
		;;
	file | filebrowser)
		filebrowser_restart
		;;
	tuna | -tuna | t | -t)
		SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn'
		auto_check_distro_and_modify_sources_list
		;;
	ppa* | -ppa*)
		tmoe_debian_add_ubuntu_ppa_source
		;;
	*)
		check_root
		;;
	esac
}
################
check_mouse_cursor() {
	if [ -e "/usr/share/icons/breeze" ]; then
		dbus-launch xfconf-query -c xsettings -t string -np /Gtk/CursorThemeName -s breeze_cursors 2>/dev/null
	elif [ -e "/usr/share/icons/Breeze-Adapta-Cursor" ]; then
		dbus-launch xfconf-query -c xsettings -t string -np /Gtk/CursorThemeName -s "Breeze-Adapta-Cursor" 2>/dev/null
	fi
}
############
check_current_user_name_and_group() {
	CURRENT_USER_NAME=$(cat /etc/passwd | grep "${HOME}" | awk -F ':' '{print $1}')
	CURRENT_USER_GROUP=$(cat /etc/passwd | grep "${HOME}" | awk -F ':' '{print $5}' | cut -d ',' -f 1)
	if [ -z "${CURRENT_USER_GROUP}" ]; then
		CURRENT_USER_GROUP=${CURRENT_USER_NAME}
	fi
}
#################
check_pic_go_sandbox() {
	if [ $(command -v picgo) ]; then
		sed -i 's+picgo %U+picgo --no-sandbox %U+' /usr/share/applications/picgo.desktop
	fi
}
#############
check_root() {
	if [ "$(id -u)" != "0" ]; then
		export PATH=${PATH}:/usr/sbin:/sbin
		if [ -z ${TMPDIR} ]; then
			TMPDIR=/tmp
			#mkdir -p ${TMPDIR}
		fi
		cd ${TMPDIR}
		if [ -e ".tmoe-linux-tool.sh" ]; then
			sudo -E bash .tmoe-linux-tool.sh || su -c "bash .tmoe-linux-tool.sh"
		elif [ -e "/usr/local/bin/debian-i" ]; then
			sudo -E bash /usr/local/bin/debian-i
		else
			if [ $(command -v curl) ]; then
				su -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
			elif [ $(command -v aria2c) ]; then
				aria2c --allow-overwrite=true -o /tmp/.tmoe-linux-tool.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh
				bash /tmp/.tmoe-linux-tool.sh
			else
				su -c "$(wget -qO- https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
			fi
		fi
		exit 0
	fi
	check_dependencies
}
#####################
check_architecture() {
	case $(uname -m) in
	armv7* | armv8l)
		ARCH_TYPE="armhf"
		;;
	armv6* | armv5*)
		ARCH_TYPE="armel"
		;;
	aarch64 | armv8* | arm64)
		ARCH_TYPE="arm64"
		;;
	x86_64 | amd64)
		ARCH_TYPE="amd64"
		;;
	i*86 | x86)
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
}
#####################
check_linux_distro() {
	if grep -Eq 'debian|ubuntu' "/etc/os-release"; then
		LINUX_DISTRO='debian'
		PACKAGES_INSTALL_COMMAND='apt install -y'
		PACKAGES_REMOVE_COMMAND='apt purge -y'
		PACKAGES_UPDATE_COMMAND='apt update'
		if grep -q 'ubuntu' /etc/os-release; then
			DEBIAN_DISTRO='ubuntu'
		elif [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
			DEBIAN_DISTRO='kali'
		fi
		###################
	elif grep -Eq "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		LINUX_DISTRO='openwrt'
		PACKAGES_UPDATE_COMMAND='opkg update'
		PACKAGES_INSTALL_COMMAND='opkg install'
		PACKAGES_REMOVE_COMMAND='opkg remove'
		##################
	elif grep -Eqi "Fedora|CentOS|Red Hat|redhat" "/etc/os-release"; then
		LINUX_DISTRO='redhat'
		PACKAGES_UPDATE_COMMAND='dnf update'
		PACKAGES_INSTALL_COMMAND='dnf install -y --skip-broken'
		PACKAGES_REMOVE_COMMAND='dnf remove -y'
		if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHAT_DISTRO='centos'
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHAT_DISTRO='fedora'
		fi
		###################
	elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" "/etc/os-release"; then
		LINUX_DISTRO='alpine'
		PACKAGES_UPDATE_COMMAND='apk update'
		PACKAGES_INSTALL_COMMAND='apk add'
		PACKAGES_REMOVE_COMMAND='apk del'
		######################
	elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
		LINUX_DISTRO='arch'
		PACKAGES_UPDATE_COMMAND='pacman -Syy'
		PACKAGES_INSTALL_COMMAND='pacman -Syu --noconfirm'
		PACKAGES_REMOVE_COMMAND='pacman -Rsc'
		######################
	elif grep -Eq "gentoo|funtoo" "/etc/os-release"; then
		LINUX_DISTRO='gentoo'
		PACKAGES_INSTALL_COMMAND='emerge -vk'
		PACKAGES_REMOVE_COMMAND='emerge -C'
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
	###############
	RB_RED=$(printf '\033[38;5;196m')
	RB_ORANGE=$(printf '\033[38;5;202m')
	RB_YELLOW=$(printf '\033[38;5;226m')
	RB_GREEN=$(printf '\033[38;5;082m')
	RB_BLUE=$(printf '\033[38;5;021m')
	RB_INDIGO=$(printf '\033[38;5;093m')
	RB_VIOLET=$(printf '\033[38;5;163m')

	RED=$(printf '\033[31m')
	GREEN=$(printf '\033[32m')
	YELLOW=$(printf '\033[33m')
	BLUE=$(printf '\033[34m')
	BOLD=$(printf '\033[1m')
	RESET=$(printf '\033[m')
}
#############################
check_dependencies() {
	DEPENDENCIES=""

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ ! $(command -v aptitude) ]; then
			DEPENDENCIES="${DEPENDENCIES} aptitude"
		fi
	fi

	if [ ! $(command -v aria2c) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/aria2"
		else
			DEPENDENCIES="${DEPENDENCIES} aria2"
		fi
	fi

	if [ ! $(command -v bash) ]; then
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
	if [ ! $(command -v catimg) ]; then
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

	if [ ! $(command -v curl) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/curl"
		else
			DEPENDENCIES="${DEPENDENCIES} curl"
		fi
	fi
	######################
	if [ ! $(command -v fc-cache) ]; then
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
	if [ ! $(command -v git) ]; then
		if [ "${LINUX_DISTRO}" = "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} git git-http"
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} dev-vcs/git"
		else
			DEPENDENCIES="${DEPENDENCIES} git"
		fi
	fi
	########################
	if [ ! $(command -v less) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sys-apps/less"
		else
			DEPENDENCIES="${DEPENDENCIES} less"
		fi
	fi

	if [ -L "/usr/bin/less" ] || [ -L "/opt/bin/less" ]; then
		if [ "${LINUX_DISTRO}" = "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} less"
		fi
	fi
	####################
	if [ ! $(command -v mkfontscale) ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} xfonts-utils"
		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			DEPENDENCIES="${DEPENDENCIES} xorg-mkfontscale"
		fi
	fi
	################
	if [ ! $(command -v nano) ]; then
		if [ "${LINUX_DISTRO}" != "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} nano"
		fi
	fi
	#####################
	if [ ! $(command -v xz) ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} xz-utils"
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} app-arch/xz-utils"
		else
			DEPENDENCIES="${DEPENDENCIES} xz"
		fi
	fi

	if [ ! $(command -v pkill) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sys-process/procps"
		elif [ "${LINUX_DISTRO}" != "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} procps"
		fi
	fi
	#####################
	if [ ! $(command -v sudo) ]; then
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
	if [ ! $(command -v whiptail) ]; then
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
	if [ ! $(command -v wget) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/wget"
		else
			DEPENDENCIES="${DEPENDENCIES} wget"
		fi
	fi
	##############

	if [ ! -z "${DEPENDENCIES}" ]; then
		echo "正在${YELLOW}安装${RESET}相关${GREEN}软件包${RESET}及其${BLUE}依赖...${RESET}"
		echo "${GREEN}${PACKAGES_INSTALL_COMMAND}${BLUE}${DEPENDENCIES}${RESET}"
		echo "如需${BOLD}${RED}卸载${RESET}${RESET}，请${YELLOW}手动${RESET}输${RED}${PACKAGES_REMOVE_COMMAND}${RESET}${BLUE}${DEPENDENCIES}${RESET}"
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			apt update
			apt install -y ${DEPENDENCIES} || apt-get install -y git wget curl whiptail aria2 xz-utils nano aptitude sudo less
			#创建文件夹防止aptitude报错
			mkdir -p /run/lock /var/lib/aptitude
			touch /var/lib/aptitude/pkgstates

		elif [ "${LINUX_DISTRO}" = "alpine" ]; then
			apk update
			apk add ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "redhat" ]; then
			dnf install -y --skip-broken ${DEPENDENCIES} || yum install -y --skip-broken ${DEPENDENCIES}

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
			apt install -y ${DEPENDENCIES} || port install ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES}
		fi
	fi
	################
	################
	if [ ! $(command -v catimg) ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			CATIMGlatestVersion="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/' | grep ${ARCH_TYPE} | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '_' -f 2)"
			cd /tmp
			wget --no-check-certificate -O 'catimg.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/catimg_${CATIMGlatestVersion}_${ARCH_TYPE}.deb"
			apt install -y ./catimg.deb
			rm -f catimg.deb
		fi
	fi

	busybox --help 2>&1 | grep -q ', ar,'
	if [ "$?" != "0" ]; then
		/usr/local/bin/busybox --help 2>&1 | grep -q ', ar,'
		if [ "$?" != "0" ]; then
			#chmod +x /usr/local/bin/busybox 2>/dev/null
			BUSYBOX_AR='false'
		else
			BUSYBOX_AR='true'
		fi
	else
		BUSYBOX_AR='true'
	fi

	if [ ! $(command -v ar) ]; then
		if [ "${BUSYBOX_AR}" = 'false' ]; then
			DEPENDENCY_01='binutils'
			echo ${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01}
			${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01}
			if [ ! $(command -v ar) ]; then
				download_busybox_deb
				BUSYBOX_AR='true'
			fi
		fi
	fi
	if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
		WINDOWSDISTRO='WSL'
	fi
	##############
	CurrentLANG=$LANG
	TMOE_LOCALE_SETTINGS
	#export LANG=$(echo 'emhfQ04uVVRGLTgK' | base64 -d)
	#20200711為解決多區域設定問題，故不設定語言
	tmoe_linux_tool_menu
}
####################################################
download_busybox_deb() {
	cd /tmp
	wget --no-check-certificate -O "busybox" "https://gitee.com/mo2/busybox/raw/master/busybox-$(uname -m)"
	chmod +x busybox
	LatestBusyboxDEB="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/busybox/ | grep static | grep ${ARCH_TYPE} | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	wget --no-check-certificate -O 'busybox.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/busybox/${LatestBusyboxDEB}"
	mkdir -p busybox-static
	./busybox dpkg-deb -X busybox.deb ./busybox-static
	mv -f ./busybox-static/bin/busybox /usr/local/bin/
	chmod +x /usr/local/bin/busybox
	rm -rvf busybox busybox-static busybox.deb
}
######################
TMOE_LOCALE_SETTINGS() {
	TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
	if [ -e "${TMOE_LOCALE_FILE}" ]; then
		TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
		TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
		TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
		#cd /usr/local/bin
		#if grep -q '\^zh_CN' $(command -v debian-i); then
		#	sed -i "s@en_US@${TMOE_LANG_HALF}@" debian-i
		#else
		#	sed -i "s@en_US@${TMOE_LANG_HALF}@" debian-i
		#fi
	else
		TMOE_LANG="en_US.UTF-8"
		TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
		TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
	fi

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ ! -e "/usr/sbin/locale-gen" ]; then
			apt install -y locales
		fi
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			if [ ! $(command -v add-apt-repository) ]; then
				apt install -y software-properties-common
			fi
			if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
				apt install -y ^language-pack-${TMOE_LANG_QUATER} 2>/dev/null
			fi
		fi
	fi

	if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
		cd /etc
		sed -i "s/^#.*${TMOE_LANG} UTF-8/${TMOE_LANG} UTF-8/" locale.gen
		if ! grep -qi "^${TMOE_LANG_HALF}" "locale.gen"; then
			echo '' >>locale.gen
			sed -i 's@^@#@g' locale.gen 2>/dev/null
			sed -i 's@##@#@g' locale.gen 2>/dev/null
			sed -i "$ a ${TMOE_LANG}" locale.gen
		fi
		locale-gen ${TMOE_LANG}
	fi
}
#####################
check_tmoe_linux_desktop_link() {
	if [ ! -e "/usr/share/applications/tmoe-linux.desktop" ]; then
		mkdir -p /usr/share/applications /usr/share/icons
		cd /usr/share/icons
		curl -Lv -o tmoe-linux.png 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/.mirror/icon.png'
		chmod 644 tmoe-linux.png
		cd /usr/share/applications
		creat_tmoe_linux_desktop_icon
	fi
}
###################
creat_tmoe_linux_desktop_icon() {
	if [ ! $(command -v debian-i) ]; then
		cd /usr/local/bin
		curl -Lv -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		chmod +x debian-i
	fi
	cat >tmoe-linux.desktop <<-'EOF'
		[Desktop Entry]
		Name=Tmoe-linux tool
		Comment=Easily configure remote desktop server and qemu vm.
		Exec=/usr/local/bin/debian-i
		Terminal=true
		X-MultipleArgs=false
		Type=Application
		StartupNotify=false
		Categories=System;
		Icon=/usr/share/icons/tmoe-linux.png
		X-Ubuntu-Gettext-Domain=tmoe-linux
		X-KDE-SubstituteUID=true
		Keywords=tmoe;Tmoe;moe;vnc;aria2;xserver;xsdl;startvnc;debian-i;tool;manager;configuration;settings;menu;
	EOF
	chmod 644 tmoe-linux.desktop
}
#######################
tmoe_linux_tool_menu() {
	IMPORTANT_TIPS=""
	#窗口大小20 50 7
	TMOE_OPTION=$(
		whiptail --title "Tmoe-linux Tool输debian-i启动(20200722-23)" --menu "Type 'debian-i' to start this tool.Please use the enter and arrow keys to operate.请使用方向键和回车键操作,更新日志:0522修复ubuntu20.10和云音乐,0618支持解析主题链接,0711 fix qemu x64repo,0711-0714 aria2-tool,0718 scrcpy" 20 50 7 \
			"1" "🍭GUI:图形界面(桌面,WM,登录管理器)" \
			"2" "🎦Software center:软件(浏览器,游戏,影音)" \
			"3" "🌈Desktop beautification:桌面美化(主题)" \
			"4" "🌌vnc/x/rdp:远程桌面" \
			"5" "🍻Download video:解析视频链接(bili,Y2B)" \
			"6" "🥗File shared:文件共享与网盘(Webdav)" \
			"7" "🍧*°▽°*Update tmoe-linux tool(更新本工具)" \
			"8" "🏫FAQ:常见问题" \
			"9" "🍥software sources:软件镜像源管理" \
			"10" "💻qemu:x86_64虚拟机管理" \
			"11" "🌸The Secret Garden秘密花园" \
			"0" "🌚Exit 退出" \
			3>&1 1>&2 2>&3
	)
	########
	#if [ "${CurrentLANG}" != $(echo 'emhfQ04uVVRGLTgK' | base64 -d) ]; then
	#	export LANG=C.UTF-8
	#fi
	#if [ ! -z "${CurrentLANG}" ]; then
	#	export LANG=${CurrentLANG}
	#fi
	check_tmoe_linux_desktop_link
	case "${TMOE_OPTION}" in
	0 | "")
		#export LANG=${CurrentLANG}
		exit 0
		;;
	1) install_gui ;;
	2) other_software ;;
	3) tmoe_desktop_beautification ;;
	4) modify_remote_desktop_config ;;
	5) download_videos ;;
	6) personal_netdisk ;;
	7) tmoe_linux_tool_upgrade ;;
	8) frequently_asked_questions ;;
	9) tmoe_sources_list_manager ;;
	10) start_tmoe_qemu_manager ;;
	11) beta_features ;;
	esac
	#########################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
############################
############################
tmoe_other_options_menu() {
	RETURN_TO_WHERE='tmoe_other_options_menu'
	NON_DEBIAN='false'
	TMOE_APP=$(whiptail --title "其它选项" --menu \
		"Welcome to tmoe-linux tool.这里是其它选项的菜单." 0 50 0 \
		"1" "Remove GUI 卸载图形界面" \
		"2" "Remove browser 卸载浏览器" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") other_software ;;
	1) remove_gui ;;
	2) remove_browser ;;
	esac
	##########################
	press_enter_to_return
	tmoe_other_options_menu
}
###################
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
	#check_current_user_name_and_group
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		apt update
		if [ ! -z "${DEPENDENCY_01}" ]; then
			apt install -y ${DEPENDENCY_01} || aptitude install ${DEPENDENCY_01}
		fi
		if [ ! -z "${DEPENDENCY_02}" ]; then
			apt install -y ${DEPENDENCY_02} || aptitude install ${DEPENDENCY_02}
		fi
		################
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		apk update
		apk add ${DEPENDENCY_01}
		apk add ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		if [ ! -z "${DEPENDENCY_01}" ]; then
			pacman -Syu --noconfirm ${DEPENDENCY_01} || su ${CURRENT_USER_NAME} -c "yay -S ${DEPENDENCY_01}" || echo "无法以${CURRENT_USER_NAME}身份运行yay -S ${DEPENDENCY_01}"
		fi
		if [ ! -z "${DEPENDENCY_02}" ]; then
			pacman -S --noconfirm ${DEPENDENCY_02} || su ${CURRENT_USER_NAME} -c "yay -S ${DEPENDENCY_02}" || echo "无法以${CURRENT_USER_NAME}身份运行yay -S ${DEPENDENCY_02},请手动执行"
		fi
		################
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		if [ ! -z "${DEPENDENCY_01}" ]; then
			dnf install -y --skip-broken ${DEPENDENCY_01} || yum install -y --skip-broken ${DEPENDENCY_01}
		fi
		if [ ! -z "${DEPENDENCY_02}" ]; then
			dnf install -y --skip-broken ${DEPENDENCY_02} || yum install -y --skip-broken ${DEPENDENCY_02}
		fi
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
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		wget -O /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
	else
		curl -Lv -o /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
	fi
	cp -f /usr/local/bin/debian-i /tmp/.tmoe-linux-tool.sh
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
			"1" "🥂Annie" \
			"2" "🍷You-get" \
			"3" "🍾Youtube-dl" \
			"4" "🍹cookie说明" \
			"5" "🍺upgrade更新下载工具" \
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
	if [ -z "${VIDEOTOOL}" ]; then
		tmoe_linux_tool_menu
	fi
	###############
	press_enter_to_return
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
			echo "检测到您取消了操作,User Pressed Esc with No File Selection"
		else
			whiptail --msgbox "文件属性 :  $(ls -lh ${FILE_NAME})\n路径 : ${FILE_PATH}" 0 0
			TMOE_FILE_ABSOLUTE_PATH="${CURRENT_DIR}/${SELECTION}"
			#uncompress_tar_file
		fi
	else
		echo "检测到您${RED}取消了${RESET}${YELLOW}操作${RESET}，没有文件${BLUE}被选择${RESET},with No File ${BLUE}Selected.${RESET}"
		#press_enter_to_return
	fi
}
###########
where_is_start_dir() {
	if [ -d "${HOME}/sd" ]; then
		START_DIR="${HOME}/sd/Download"
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
		CURRENT_COOKIE_PATH=$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)
		CurrentCOOKIESpath="您当前的cookie路径为${CURRENT_COOKIE_PATH}"
	else
		COOKIESTATUS="检测到cookie处于禁用状态"
		CurrentCOOKIESpath="${COOKIESTATUS}"
	fi

	mkdir -p "${HOME}/.config/tmoe-linux"
	if (whiptail --title "modify cookie path and status" --yes-button '指定cookie file' --no-button 'disable禁用cookie' --yesno "您想要修改哪些配置信息？${COOKIESTATUS} Which configuration do you want to modify?" 9 50); then
		IMPORTANT_TIPS="${CurrentCOOKIESpath}"
		CURRENT_QEMU_ISO="${CURRENT_COOKIE_PATH}"
		FILE_EXT_01='txt'
		FILE_EXT_02='sqlite'
		where_is_tmoe_file_dir
		if [ -z ${SELECTION} ]; then
			echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
		else
			echo ${TMOE_FILE_ABSOLUTE_PATH} >"${HOME}/.config/tmoe-linux/videos.cookiepath"
			echo "您当前的cookie文件路径为${TMOE_FILE_ABSOLUTE_PATH}"
			ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
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
		║ 1 ║   annie  ║                   ║ ${AnnieVersion}
		║   ║          ║${LATEST_ANNIE_VERSION}
		║---║----------║-------------------║--------------------
		║   ║          ║                   ║ ${YouGetVersion}                   
		║ 2 ║ you-get  ║                   ║  
		║---║----------║-------------------║--------------------
		║   ║          ║                   ║ ${YOTUBEdlVersion}                  
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
		║   ║ 💻 type    ║    🎬  ║   🌁   ║   📚    ║
		║   ║----------- ║ Videos ║ Images ║Playlist ║
		║   ║ website    ║        ║        ║         ║
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
	#pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
	pip3 install pip -U -i https://pypi.tuna.tsinghua.edu.cn/simple 2>/dev/null
	pip3 install you-get -U -i https://pypi.tuna.tsinghua.edu.cn/simple
	you-get -V
	pip3 install youtube-dl -U -i https://pypi.tuna.tsinghua.edu.cn/simple
	youtube-dl -v 2>&1 | grep version
	echo "更新完毕，如需${YELLOW}卸载${RESET}annie,请输${YELLOW}rm /usr/local/bin/annie${RESET}"
	echo "如需卸载you-get,请输${YELLOW}pip3 uninstall you-get${RESET}"
	echo "如需卸载youtube-dl,请输${YELLOW}pip3 uninstall youtube-dl${RESET}"
	echo "请问您是否需要将pip源切换为清华源[Y/n]?"
	echo "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .[Y/n]"
	RETURN_TO_WHERE='download_videos'
	do_you_want_to_continue
	pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

	echo 'Press Enter to start annie'
	echo "${YELLOW}按回车键启动annie。${RESET}"
	read
	golang_annie
}
##################
which_vscode_edition() {
	RETURN_TO_WHERE='which_vscode_edition'
	ps -e >/dev/null 2>&1 || VSCODEtips=$(echo "检测到您无权读取/proc分区的部分内容，请选择Server版，或使用x11vnc打开VSCode本地版")
	VSCODE_EDITION=$(whiptail --title "Visual Studio Code" --menu \
		"${VSCODEtips} Which edition do you want to install" 15 60 5 \
		"1" "VS Code Server:web版,含配置选项" \
		"2" "VS Codium(不跟踪你的使用数据)" \
		"3" "VS Code OSS(headmelted编译版)" \
		"4" "Microsoft Official(x64,官方版)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${VSCODE_EDITION}" in
	0 | "") other_software ;;
	1) check_vscode_server_arch ;;
	2) install_vscodium ;;
	3) install_vscode_oss ;;
	4) install_vscode_official ;;
	esac
	#########################
	press_enter_to_return
	tmoe_linux_tool_menu
}
#################################
check_vscode_server_arch() {
	if [ "${ARCH_TYPE}" = "arm64" ] || [ "${ARCH_TYPE}" = "amd64" ]; then
		install_vscode_server
	else
		echo "非常抱歉，Tmoe-linux的开发者未对您的架构进行适配。"
		echo "请选择其它版本"
		arch_does_not_support
		which_vscode_edition
	fi
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
		whiptail --title "CONFIGURE VSCODE_SERVER" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
			"1" "upgrade code-server更新/升级" \
			"2" "password 设定密码" \
			"3" "edit config manually手动编辑配置" \
			"4" "stop 停止" \
			"5" "remove 卸载/移除" \
			"0" "Return to previous menu 返回上级菜单" \
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
	echo "正在检测版本信息..."
	if [ -e "/usr/local/bin/code-server-data/bin/code-server" ]; then
		LOCAL_VSCODE_VERSION=$(code-server --version | grep -v info | head -n 1 | awk '{print $1}')
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
	#sed -i '/export PASSWORD=/d' ~/.profile
	#sed -i '/export PASSWORD=/d' ~/.zshrc
	#sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.profile
	#sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.zshrc
	#export PASSWORD=${TARGET_USERPASSWD}
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
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCodium.deb' "https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
		apt show ./VSCodium.deb
		apt install -y ./VSCodium.deb
		rm -vf VSCodium.deb
		#echo '安装完成,请输codium --user-data-dir=${HOME}/.config/VSCodium启动'
		echo "安装完成,请输codium --user-data-dir=${HOME}启动"
	else
		LatestVSCodiumLink="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${CodiumARCH} | grep -v '.sha256' | grep '.tar' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCodium.tar.gz' "https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
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
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.deb' "https://go.microsoft.com/fwlink/?LinkID=760868"
		apt show ./VSCODE.deb
		apt install -y ./VSCODE.deb
		rm -vf VSCODE.deb
		echo "安装完成,请输code --user-data-dir=${HOME}启动"

	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.rpm' "https://go.microsoft.com/fwlink/?LinkID=760867"
		rpm -ivh ./VSCODE.rpm
		rm -vf VSCODE.rpm
		echo "安装完成,请输code --user-data-dir=${HOME}启动"
	else
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.tar.gz' "https://go.microsoft.com/fwlink/?LinkID=620884"
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
modify_other_vnc_conf() {
	MODIFYOTHERVNCCONF=$(whiptail --title "Modify vnc server conf" --menu "Which configuration do you want to modify?" 15 60 7 \
		"1" "Pulse server address音频地址" \
		"2" "VNC password密码" \
		"3" "switch tiger/tightvnc切换服务端" \
		"4" "Edit xstartup manually 手动编辑xstartup" \
		"5" "Edit startvnc manually 手动编辑vnc启动脚本" \
		"6" "fix vnc crash修复VNC闪退" \
		"7" "window scaling factor调整屏幕缩放比例(仅支持xfce)" \
		"8" "display port显示端口" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	###########
	case "${MODIFYOTHERVNCCONF}" in
	0 | "") modify_remote_desktop_config ;;
	1) modify_vnc_pulse_audio ;;
	2) set_vnc_passwd ;;
	3) switch_tight_or_tiger_vncserver ;;
	4)
		nano ~/.vnc/xstartup
		stopvnc 2>/dev/null
		press_enter_to_return
		modify_other_vnc_conf
		;;
	5) nano_startvnc_manually ;;
	6) fix_vnc_dbus_launch ;;
	7) modify_xfce_window_scaling_factor ;;
	8) modify_tightvnc_display_port ;;
	esac
	#########
	press_enter_to_return
	modify_other_vnc_conf
	##########
}
##############
switch_tight_or_tiger_vncserver() {
	DEPENDENCY_01=''
	NON_DEBIAN='true'
	if [ $(command -v Xtightvnc) ]; then
		VNC_SERVER_BIN_NOW="tightvncserver"
		VNC_SERVER_BIN="tigervnc"
		DEPENDENCY_02="tigervnc-standalone-server"
	elif [ $(command -v Xtigervnc) ]; then
		VNC_SERVER_BIN_NOW="tigervnc-standalone-server"
		VNC_SERVER_BIN="tightvnc"
		DEPENDENCY_02="tightvncserver"
	fi
	VNC_SERVER_BIN_STATUS="检测到您当前使用的是${VNC_SERVER_BIN_NOW}"
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Back返回" --no-button "${VNC_SERVER_BIN}" --yesno "${VNC_SERVER_BIN_STATUS}\n请问您是否需要切换为${VNC_SERVER_BIN}♪(^∇^*)\nDo you want to switch to ${VNC_SERVER_BIN}?" 0 0); then
		modify_other_vnc_conf
	else
		non_debian_function
		echo "${RED}${PACKAGES_REMOVE_COMMAND} ${VNC_SERVER_BIN_NOW}${RESET}"
		${PACKAGES_REMOVE_COMMAND} ${VNC_SERVER_BIN_NOW}
		beta_features_quick_install
	fi
}
#################
check_tightvnc_port() {
	CURRENT_PORT=$(cat /usr/local/bin/startvnc | grep '\-geometry' | awk -F ' ' '$0=$NF' | cut -d ':' -f 2 | tail -n 1)
	CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
}
#########################
modify_tightvnc_display_port() {
	check_tightvnc_port
	TARGET=$(whiptail --inputbox "默认显示编号为1，默认VNC服务端口为5901，当前为${CURRENT_VNC_PORT} \nVNC服务以5900端口为起始，若显示编号为1,则端口为5901，请输入显示编号.Please enter the display number." 13 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "s@tmoe-linux.*:.*@tmoe-linux :$TARGET@" "$(command -v startvnc)"
		echo 'Your current VNC port has been modified.'
		check_tightvnc_port
		echo '您当前的VNC端口已修改为'
		echo ${CURRENT_VNC_PORT}
		press_enter_to_return
	fi
	modify_other_vnc_conf
}
######################
modify_xfce_window_scaling_factor() {
	XFCE_CONFIG_FILE="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
	if grep 'WindowScalingFactor' ${XFCE_CONFIG_FILE}; then
		CURRENT_VALUE=$(cat ${XFCE_CONFIG_FILE} | grep 'WindowScalingFactor' | grep 'value=' | awk '{print $4}' | cut -d '"' -f 2)
	else
		CURRENT_VALUE='1'
	fi
	TARGET=$(whiptail --inputbox "请输入您需要缩放的比例大小(纯数字)，当前仅支持整数倍，例如1和2，不支持1.5,当前为${CURRENT_VALUE}" 10 50 --title "Window Scaling Factor" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		dbus-launch xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s ${TARGET} || dbus-launch xfconf-query -t int -c xsettings -np /Gdk/WindowScalingFactor -s ${TARGET}
		if ((${TARGET} > 1)); then
			if grep -q 'Focal Fossa' "/etc/os-release"; then
				dbus-launch xfconf-query -c xfwm4 -p /general/theme -s Kali-Light-xHiDPI 2>/dev/null
			else
				dbus-launch xfconf-query -c xfwm4 -p /general/theme -s Default-xhdpi 2>/dev/null
			fi
		fi
		echo "修改完成，请输${GREEN}startvnc${RESET}重启进程"
	else
		echo '检测到您取消了操作'
		cat ${XFCE_CONFIG_FILE} | grep 'WindowScalingFactor' | grep 'value='
	fi
}
##################
modify_vnc_pulse_audio() {
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。linux默认为127.0.0.1,WSL2默认为宿主机ip,当前为$(grep 'PULSE_SERVER' ~/.vnc/xstartup | cut -d '=' -f 2 | head -n 1) \n本功能适用于局域网传输，本机操作无需任何修改。若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：您需要手动启动音频服务端,Android-Termux需输pulseaudio --start,win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat' \n至于其它第三方app,例如安卓XSDL,若其显示的PULSE_SERVER地址为192.168.1.3:4713,那么您需要输入192.168.1.3:4713" 20 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		modify_other_vnc_conf
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		#sed -i '/PULSE_SERVER/d' ~/.vnc/xstartup
		#sed -i "2 a\export PULSE_SERVER=$TARGET" ~/.vnc/xstartup
		if grep '^export.*PULSE_SERVER' "${HOME}/.vnc/xstartup"; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" ~/.vnc/xstartup
		else
			sed -i "4 a\export PULSE_SERVER=$TARGET" ~/.vnc/xstartup
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' ~/.vnc/xstartup | cut -d '=' -f 2 | head -n 1)
		echo "请输startvnc重启vnc服务，以使配置生效"
	fi
}
##################
nano_startvnc_manually() {
	echo '您可以手动修改vnc的配置信息'
	echo 'If you want to modify the resolution, please change the 1440x720 (default resolution，landscape) to another resolution, such as 1920x1080 (vertical screen).'
	echo '若您想要修改分辨率，请将默认的1440x720（横屏）改为其它您想要的分辨率，例如720x1440（竖屏）。'
	echo "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1 | tail -n 1)"
	echo '改完后按Ctrl+S保存，Ctrl+X退出。'
	RETURN_TO_WHERE='modify_other_vnc_conf'
	do_you_want_to_continue
	nano /usr/local/bin/startvnc || nano $(command -v startvnc)
	echo "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1 | tail -n 1)"

	stopvnc 2>/dev/null
	press_enter_to_return
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
	fi
	DEPENDENCY_01="chromium-browser/bionic-updates"
	DEPENDENCY_02="chromium-browser-l10n/bionic-updates"
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
	do_you_want_to_close_the_sandbox_mode
	read opt
	case $opt in
	y* | Y* | "")
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ] || [ "${LINUX_DISTRO}" = "alpine" ]; then
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
do_you_want_to_close_the_sandbox_mode() {
	echo "请问您是否需要关闭沙盒模式？"
	echo "若您需要以root权限运行该应用，则需要关闭，否则请保持开启状态。"
	echo "${YELLOW}Do you need to turn off the sandbox mode?[Y/n]${RESET}"
	echo "Press enter to close this mode,type n to cancel."
	echo "按${YELLOW}回车${RESET}键${RED}关闭${RESET}该模式，输${YELLOW}n${RESET}取消"
}
#######################
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
			DEPENDENCY_02="firefox-esr-locale-zh-hans libavcodec58"
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
	if [ ! $(command -v firefox) ] && [ ! $(command -v firefox-esr) ]; then
		echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫姐姐来代替了。${RESET}"
		echo 'Press Enter to install firefox.'
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
			DEPENDENCY_02="firefox-locale-zh-hans libavcodec58"
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
		do_you_want_to_continue
		install_firefox_esr_browser
	fi
}
#####################
install_browser() {
	if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno "建议在安装完图形界面后，再来选择哦！(　o=^•ェ•)o　┏━┓\nI am Firefox, choose me.\n我是火狐娘，选我啦！♪(^∇^*) \nI'm chrome's elder sister chromium, be sure to choose me.\n妾身是chrome娘的姐姐chromium娘，妾身和那些妖艳的货色不一样，选择妾身就没错呢！(✿◕‿◕✿)✨\n请做出您的选择！ " 15 50); then

		if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox-ESR" --no-button "Firefox" --yesno "I am Firefox,I have a younger sister called ESR.\n我是firefox，其实我还有个妹妹叫firefox-esr，您是选我还是选esr?\n “(＃°Д°)姐姐，我可是什么都没听你说啊！” 躲在姐姐背后的ESR瑟瑟发抖地说。\n✨请做出您的选择！ " 12 53); then
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
}
######################################################
######################################################
install_gui() {
	#该字体检测两次
	if [ -f '/usr/share/fonts/Iosevka.ttf' ]; then
		standand_desktop_install
	fi
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
	DEPENDENCY_02="tigervnc"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			NON_DBUS='true'
		fi
		DEPENDENCY_02="dbus-x11 fonts-noto-cjk fonts-noto-color-emoji tightvncserver"

		#if grep -q '^PRETTY_NAME.*sid' "/etc/os-release"; then
		#	DEPENDENCY_02="${DEPENDENCY_02} tigervnc-standalone-server"
		#else
		#	DEPENDENCY_02="${DEPENDENCY_02} tightvncserver"
		#fi
		#上面的依赖摆放的位置是有讲究的。
		##############
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			NON_DBUS='true'
		fi
		DEPENDENCY_02="google-noto-sans-cjk-ttc-fonts google-noto-emoji-color-fonts tigervnc-server"
		##################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02="tigervnc"
		if [ ! -e "/usr/share/fonts/noto-cjk" ]; then
			DEPENDENCY_02="noto-fonts-cjk ${DEPENDENCY_02}"
		fi
		if [ ! -e "/usr/share/fonts/noto/NotoColorEmoji.ttf" ]; then
			DEPENDENCY_02="noto-fonts-emoji ${DEPENDENCY_02}"
		fi

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
		DEPENDENCY_02="xvfb dbus-x11 font-noto-cjk x11vnc"
		#ca-certificates openssl
		##############
	fi
}
########################
standand_desktop_install() {
	NON_DEBIAN='false'
	preconfigure_gui_dependecies_02
	REMOVE_UDISK2='false'
	RETURN_TO_WHERE='standand_desktop_install'
	INSTALLDESKTOP=$(whiptail --title "GUI" --menu \
		"Desktop environment(简称DE)是一种多功能和多样化的图形界面。\n若您使用的是容器，则只需选择第一或者第三项。\nIf you are using container,then choose container_DE or WM.\nWhich GUI do you want to install?\n若您使用的是虚拟机，则可以任意挑选项目。" 0 0 0 \
		"1" "🍰Container_DE(容器可运行:xfce,mate,lxde)" \
		"2" "🍱VM_DE(虚拟机可运行:lxqt,kde,gnome)" \
		"3" "🍙window manager窗口管理器:ice,fvwm" \
		"4" "🍣display manager显示/登录管理器:lightdm,sddm" \
		"5" "🍤FAQ:vnc和gui的常见问题" \
		"0" "🌚none我一个都不要 =￣ω￣=" \
		3>&1 1>&2 2>&3)
	##########################
	case "${INSTALLDESKTOP}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) tmoe_container_desktop ;;
	2) tmoe_virtual_machine_desktop ;;
	3) window_manager_install ;;
	4) tmoe_display_manager_install ;;
	5) tmoe_desktop_faq ;;
	esac
	##########################
	press_enter_to_return
	standand_desktop_install
}
#######################
tmoe_desktop_faq() {
	printf "$BLUE"
	cat <<-'EndOFneko'
		                                        
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
	cat <<-EOF
		     ------------------------
			Q:${YELLOW}我觉得你写的脚本很菜,适配不同发行版有什么难的？不就是apt install或pacman -S,再不然就是dnf、emerge或zypper，有什么难的？${RESET}

			A1：并非所有软件都可以直接通过包管理器来安装。

			对于proot容器而言，很有可能因权限不足而无法读取部分系统数据。

			在没有权限的情况下，必须要对软件进行打补丁操作，否则将导致软件无法正常运行。
			     
			另外最麻烦的一点在于：如果上游发生了变更，那么就有可能导致脚本的部分地方失效。
			
			举个例子：Termux在v0.95版中不再预装debianutils,导致novnc无法正常连接，其本质原因是novnc依赖于which这种最基础的命令。
			解决方法特别简单，把该依赖（debianutils）再装回来就可以了。

			注：novnc相当于浏览器版的vnc客户端，让您无需安装vnc app即可使用vnc连接。

			再举个例子:
			VScode server在之前某次更新中发生了重大变更。
			我必须要修改远程服务器的自动打包方案，并且几乎完全重写了配置脚本。

			另外，为了解决alpine软件源中无部分软件包的问题，我还做了很多繁琐的步骤。


			A2:除了软件维护以及包管理的区别之外，vnc服务的配置其实是有门道和不同之处的。

			${BLUE}一.不同系统的vncserver的配置方案是有点小区别的。${RESET}
			deb系(虚拟机/实体机)在xstartup脚本中启动de/wm的命令前可以加上dbus-launch --exit-with-session,不加的话可能会出现无法连接至设置服务的错误，而deb系的proot容器加上这个会很容易闪退，所以需要对proot容器和虚拟机分别进行适配。其他系用--exit-with-session参数可能会发生错误，比如arch系虚拟机只需要dbus-launch,不要加那个参数，而且arch系的proot容器最好也加上dbus-launch。
			在某些情况下，可能需要开启dbus，所以你还得要做一个开关。
			开关不就一开一关，你以为很简单。其实这里又涉及到另一个问题，就是多命令问题，下文会提到的。
			对于不同系统不同平台，这块只有一点小区别而已。


			${BLUE}二:不同vnc服务有很大的差距！${RESET}

			这个就不得不提alpine，因为官方软件源暂时还没有tight/tigervnc服务，所以建议你去配置x11vnc服务,而不是去手动编译tightvnc。话说回来，x11vnc跟tightvnc的配置步骤差距真的有点大。
			再说体验。
			x11vnc在windows子系统以及linux虚拟机上的表现非常优秀，但是到了Android的linux proot容器这边就不行了。

			还有tigervnc和tightvnc
			tigervnc的兼容性明显好于tightvnc,但是前者在Android手机上运行的流畅度却不如后者。

			debian系的tightvnc真的是太不给力了，我都替他们感到着急。
			在5月份之前的版本中，由于其对GTK+3的兼容性不佳，故导致标题栏丢失。
			你还要想办法修复这个bug，自动化的解决方法是用xfconf来指定GTK+2的窗口管理器样式。这个没有人给答案，只能靠自己去探究。

			尽管上面那个bug已经修复了，但是截止目前(2020年6月上旬),tightvnc+gnome3还是存在黑屏问题，人家tigervnc就不会。


			测试是一个很麻烦的过程，有很多系统都需要去测试。

			以deb系为例，一般优先测试的是debian(stable和sid)和Ubuntu lts(例如bionic和focal)。
			arch滚动发行就不用管旧版本了，直接测试最新版。
			红帽系就先搞软呢帽fedora吧，CentOS官方的软件仓库我是真的不想说它。
			至于Fedora的冷门分支sliverblue，什么rpm-ostree都放在一边吧！我真的没有时间和精力去适配和测试这么多东西。（大哭...ヽ(*。>Д<)o゜）

			不同平台,不同系统,同一桌面测试的结果都有可能出现不同的结果！！！
			举个例子：debian sid+tightvnc/tigervnc/x11vnc+gnome3,arch+tigervnc+gnome3
			在proot容器的测试结果都是黑屏，但在虚拟机中的测试结果就不一样了。
			再举个例子：如果要在Alpine实体机给装桌面（非远程），要配置的东西就要比alpine容器+远程桌面多很多。
			由于文档资料不全，因此很多东西都需要自己去探究。

			realvnc客户端对debian系(包括ubuntu)的新版tigervnc server(standalone)兼容性不佳，可能会出现无法连接的问题。

			如果你要在proot容器里配置realvnc 服务端的话，那么你还要解决文件权限问题。

			同理，如果你已经给root用户配置了tightvnc，还要接着给普通用户配置的话，同样需要解决权限问题。

			从为用户考虑的角度出发，你得要自动解决,而不是再配置一次脚本。
			(注:尽管这两个方案实现的难度差不多)

			${BLUE}三.同一桌面，不同版本的区别。${RESET}
			对于不同版本的DE，它的session名称/启动脚本还有可能不一样。比如在旧版系统(如Ubuntu 18.04 bionic和debian 10 buster）中，plasma桌面对应的是startkde,而在新版ubuntu，debian sid和arch等发行版中，plasma桌面分成了startplasma-x11和startplasma-wayland，最精简安装的话，可能没有startkde这个脚本了。
			对于同一个DE来说,它有可能有两个不同的启动命令。一个是启动脚本，另一个是会话名称。比如xfce有startxfce4和xfce4-session。
			究竟哪个才是最优解呢？你得要自己测试才能得出答案。偷偷告诉你，真的是有区别的。要不是有人跟我反馈，我都不知道其中一个竟然会产生新的bug。

			如果还要做转发音频和X的话，就要考虑到网络类型了。
			如果是桥接网络的话，那问题不大，但是WSL2的NAT网络，就要得要用到宿主机的ip了，一般都是B类内网地址。
			如果涉及到tcp端口映射，要搞自动化检测+配置就麻烦了，但是手动配置还是挺简单的，因此端口映射这块我只写了qemu虚拟机的配置方案。

			${BLUE}四.不同架构的区别。${RESET}

			对于x86_64独占，而其它平台没有的软件包来说，只需要简单地加上一个检测步骤即可。
			但是对于其它架构都有，唯独mipsel架构没有的来说，就有点麻烦，因为有可能连基础依赖都会缺失。
			一小步走错，导致全盘崩溃也是又有可能的。
			对于其它架构，例如s390x和ppc64el,我只是简单地用qemu测试了一下，所以反倒是没在这上面耽误太多时间。


			${BLUE}五.不同虚拟化平台的区别。${RESET}

			在不同的虚拟化平台进行测试，也是有区别的。
			对于linux程序而言，我个人觉得Linux平台的Qemu+kvm的测试环境要比Windows 平台的HyperV虚拟机好很多。
			应该说各有所长吧，HyperV更适合用来测试windows程序。
			我之前在HyperV上踩了好多坑，想起来就难受，浪费我那么多时间。
			尽管HyperV对于Debian和Ubuntu等大众发行版的兼容性极佳，但对于MX linux19.0以及LMDE4等小众发行版却并非如此，后者总会出现奇怪的BUG。

			如果是在容器环境中测试的话，那么你还得要考虑到systemd的问题。

			总的来说,linux远程桌面的bug不是一般的多。
			特别是在没有权限的情况下，解决起来就更麻烦了。
			真正让我生气和心痛的地方并不在于解决问题有多难，而在于测试这些鬼东西真的超级浪费时间！！！
			有时候一个小问题就浪费我一个下午的时间，我一想起来就很生气，超级生气。
			重要的事情说三遍！浪费时间！！！

			------------------------
			${RED}linux上最好用的桌面环境竟然是。。。${RESET}
			按回车键继续阅览
			------------------------
	EOF
	press_enter_to_continue
	cat <<-EOF
		            -----------------------------
			        Q:${YELLOW}哪个发行版最好用，最流畅，最适合新手？如何才能更好地使用linux系统？${RESET}

					A：要说哪个比较好用还是得要靠你自己体验啊！

					比如说gentoo，它有其独特的魅力，但是我觉得它有点浪费时间，编译软件太久了。（大哭...ヽ(*。>Д<)o゜）
					对于我来说，我更希望包管理器有个庞大的二进制文件仓库作为顶梁柱。

					你可以实际体验过后告诉我哪个发行版比较好用。

					proot容器与chroot容器一样，仅提供文件系统级的隔离。

					因为它与Android原系统共享相同的内核、硬件、进程空间和网络子系统，所以说它的效率已经算是非常高了。
					由于Android用的是阉割过的linux内核,所以可能会存在某些问题。

					对于你的问题，我给出三个回答吧！

					${BLUE}一.更流畅:把桌面环境(简称DE)换成窗口管理器(简称WM)试试。${RESET}
					温馨提醒:WM对于新手来说，可能没有DE好用。
					如果所有东西都需要自己配置的话，那么这些东西可能会变得很难用，不适合新手入门。
					而且绝大多数WM追求的是轻量，简约和纯净。
					我在写不同WM的配置方案时，就觉得每个WM都在说自己很lightweight,很pure。

					${BLUE}二.更适合新手:${RESET}
					Ubuntu在个人计算机上很适合新手使用，因为它对闭源驱动的兼容性可能会更好一点。
					既然你是在容器中运行，那么配合我的脚本使用debian也是不错的体验呢！
					还有的话，fedora也可以试试，我觉得它比centos好用很多。
					至于arch和manjaro，我是更推荐arch的，manjaro修bug真的是修到怕了。
					因为我已经解决了安装过程中存在的很多问题，所以你应该都可以无障碍上手。
			               
				   后期注：如果你使用的不是手机上的容器，而是实体机，追求的是轻办公、轻娱乐，让人用起来很舒适的环境。
				   那么我就推荐一下Mint吧！
				   基于Ubuntu的Linux Mint主要分支版本，以及基于Debian的LMDE(Linux Mint Debian Edition)都是不错的选择呢！§(*￣▽￣*)§
			                 

					对萌新来说，不同发行版最主要的区别可能不是包管理器，而是桌面环境(DE)。
					如果你经常用我的脚本，那么你也许会发现DE是可以自行安装的，你没必要非得使用发行版默认的DE，而且不同DE在不同发行版上的体验也是有所区别的。

					更适合新手的往往是那些大而全的DE，例如gnome和kde plasma。
					我之前看过统计数据，排名前三的DE分别是GNOME3,KDE plasma 5和xfce4。
					1.Gnome是许多发行版默认的DE，例如Ubuntu,Debian和Fedora,排名靠前不足为奇。
			                
					后期注：如果你正在使用带有触摸屏的实体机（例如：平板电脑或二合一PC），那么它的触屏体验在三者中可能是最佳的，相当不错。
					对于窗口的交互式体验，以及操作逻辑之处，我也是非常欣赏的。

					注2：proot容器暂时不要装此桌面。


					2.plasma桌面非常华丽，可配置选项多，拥有高度的可自定义性。

					默认配置就令人赏心悦目，非常美观。

					如果您使用的是proot容器的话，那么现阶段（2020年6月上旬）不建议安装。

					在上文中已经提过了，虚拟机和容器环境有很大的区别，此处不再赘述。

					之前曾在Android的Ubuntu 18.04 proot容器里体验过kde plasma，流畅度并不如xfce。
			                
					如果直接在proot容器里安装的话，那么很有可能遇到程序崩溃，无法正常启动的问题，此外你还得要自己解决很多问题，修bug可不是一件简单的事情。

					如果使用的是chroot容器的话，那么可以选择arch+kde+tigervnc。
			                

					3.综合来说，桌面环境三剑客中在手机上体验最好的是xfce4。
					至于其他桌面，例如lxde，或许它会比xfce更流畅，但是呢！个人觉得xfce更好用一点(逃...

					${BLUE}三.更好地使用linux: 可以用qemu虚拟机跑个alpine，不装GUI。${RESET}

					我写的脚本现在已经支持配置qemu了，可以很方便地在宿主机为Android的设备上安装x64虚拟机，并运行docker。

					受制于Android原系统的内核，绝大多数手机使用chroot/proot容器可能无法原生运行docker容器。而qemu虚拟机则不存在这些限制，但是效率会低一些。(此处指tcg加速，不是kvm)

					在arm64的Android手机用上alpine x64 docker，就能更好地发挥出linux系统的作用了。
					不嫌效率低，也可以用更全面的发行版，例如debian x64。
			                  
					alpine之所以如此高效和轻量化，是因为它有些东西是残缺的，更贴切一点来说是非标准的，当你把缺失的东西补回来后，它是否还会像之前那样轻量化呢？
					这是个值得思考的问题。
					-----------------------------
					${RED}最后一页是正经问答${RESET}
					-----------------------------
	EOF
	press_enter_to_continue
	cat <<-EOF
		    -----------------------------
			Q:${YELLOW}为什么绝大多数的命令和文件夹名称都跟debian有关,我有觉得很别扭，特别难受。${RESET}

			A:因为去年(2019年)只适配了termux和debian,今年(2020年)早些时候又适配debian系列的其它发行版，例如kali和ubuntu。
			后来，大概在四月初的时候才适配了其它系的发行版，例如：arch系，红帽系和alpine等。
			适配不同的发行版是一件非常浪费时间的事情，有时候修复一个小bug都要花上几个小时的时间。
			因为我不想把时间浪费在无所谓的事情上，所以就不想改了。
			虽然修改相关命令和文件夹名称很简单，但是需要花费大量的时间去调试。
			-----------------------
			Q:${YELLOW}安装过程中，当提示输入密码时，termux无法弹出虚拟键盘${RESET}

			A:有四种解决方法：
			① 先将termux切换至后台，再切换回来
			② 使用悬浮键盘
			③ 侧划termux底部小键盘至黑色区域，点击该区域即可弹出。
			④ 直接点击输入框
			------------------------
			Q:${YELLOW}I don't know how to use it?${RESET}

			A:Type ${GREEN}startvnc${RESET} to start vncserver,type ${GREEN}stopvnc${RESET} to stop it.
			You can also type ${GREEN}startxsdl${RESET} to startx.
			------------------------
			Q:${YELLOW}启动VNC的命令有点复杂，我记不住${RESET}🤣，欺负老年人么？st...什么来着😨

			A:完整命令是startvnc，您只需记住st，然后就能借助zsh的自动补全插件来解决。
			输完st后，您可以按下TAB键(⇆),即可生成补全内容。
			您也可以直接按方向键→或者是↑，此操作亦能自动补全。😋
		Q:啊，就这？
		不会吧，不会吧，不会真的有人认为我连这么简单的命令都记不住？🙂
		Linux Deploy它不香吗？什么命令都不用记。
		A:
		可是你刚刚。。。
		Q:
		可是什么可是！ 
		你在教我做事？
		哈哈，我在钓鱼，你上钩了。懂？
		你品，你细品。

		A:
		宁可真是位带阴阳师呢！

		Q:
		你急了，你急了
			------------------------
			Q:${YELLOW}我可以在Linux Deploy上使用这个脚本吗？${RESET}

			A:可以哒！ヾ(≧▽≦*)o 您可以在其它主流的GNU/Linux发行版，包括但不限于容器、虚拟机和实体机上使用这个脚本。
			------------------------
			END（完结）
			                                                                                 2020年6月初稿，7月修订
			                                                                                 Tmoe-linux开发者
			------------------------
	EOF
}
#####################
#Q:${YELLOW}有隐藏的彩蛋或功能吗？${RESET}

#A:应该算有吧！emmmmm...
#-----------------------
tmoe_container_desktop() {
	INSTALLDESKTOP=$(whiptail --title "Desktop environment" --menu \
		"您想要安装哪个桌面环境?\n仅GTK+环境(如xfce等)支持在本工具内便捷下载主题。 \n Which desktop environment do you want to install? " 0 0 0 \
		"1" "xfce(兼容性高,简单优雅)" \
		"2" "lxde(轻量化桌面,资源占用低)" \
		"3" "mate(GNOME2的延续,让用户体验更舒适的环境)" \
		"0" "none我一个都不要 =￣ω￣=" \
		3>&1 1>&2 2>&3)
	##########################
	case "${INSTALLDESKTOP}" in
	0 | "") standand_desktop_install ;;
	1)
		REMOVE_UDISK2='true'
		install_xfce4_desktop
		;;
	2)
		REMOVE_UDISK2='true'
		install_lxde_desktop
		;;
	3) install_mate_desktop ;;
	esac
	##########################
	press_enter_to_return
	tmoe_container_desktop
}
####################
tmoe_display_manager_install() {
	NON_DEBIAN='false'
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
		"显示管理器软件包基础配置" 14 50 6 \
		"1" "install/remove 安装/卸载" \
		"2" "start启动" \
		"3" "stop停止" \
		"4" "systemctl enable开机自启" \
		"5" "systemctl disable禁用自启" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${INSTALLDESKTOP}" in
	0 | "") standand_desktop_install ;;
	1)
		beta_features_quick_install
		;;
	2)
		echo "您可以输${GREEN}systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}或${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} start${RESET}来启动"
		echo "${GREEN}systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
		echo "按回车键启动"
		do_you_want_to_continue
		systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL} || service ${TMOE_DEPENDENCY_SYSTEMCTL} restart
		;;
	3)
		echo "您可以输${GREEN}systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}或${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} stop${RESET}来停止"
		echo "${GREEN}systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
		echo "按回车键停止"
		do_you_want_to_continue
		systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL} || service ${TMOE_DEPENDENCY_SYSTEMCTL} stop
		;;
	4)
		echo "您可以输${GREEN}rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}或${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}来添加开机自启任务"
		echo "${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
		systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}
		if [ "$?" = "0" ]; then
			echo "已添加至自启任务"
		else
			echo "添加自启任务失败"
		fi
		;;
	5)
		echo "您可以输${GREEN}rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}或${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}来禁止开机自启"
		echo "${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
		systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}
		if [ "$?" = "0" ]; then
			echo "已禁用开机自启"
		else
			echo "禁用自启任务失败"
		fi
		;;
	esac
	##########################
	press_enter_to_return
	tmoe_display_manager_systemctl
}
#######################
auto_select_keyboard_layout() {
	echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
	echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
	echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
}
##################
#################
will_be_installed_for_you() {
	echo "即将为您安装思源黑体(中文字体)、${REMOTE_DESKTOP_SESSION_01}、tightvncserver等软件包"
}
########################
#####################
window_manager_install() {
	NON_DBUS='true'
	REMOTE_DESKTOP_SESSION_02='x-window-manager'
	BETA_DESKTOP=$(
		whiptail --title "WINDOW MANAGER" --menu \
			"Window manager窗口管理器(简称WM)\n是一种比桌面环境更轻量化的图形界面.\n您想要安装哪个WM呢?您可以同时安装多个\nWhich WM do you want to install?" 0 0 0 \
			"00" "Return to previous menu 返回上级菜单" \
			"01" "ice(意在提升感观和体验,兼顾轻量和可定制性)" \
			"02" "openbox(快速,轻巧,可扩展)" \
			"03" "fvwm(强大的、与ICCCM2兼容的WM)" \
			"04" "awesome(平铺式WM)" \
			"05" "enlightenment(X11 WM based on EFL)" \
			"06" "fluxbox(高度可配置,低资源占用)" \
			"07" "i3(改进的动态平铺WM)" \
			"08" "xmonad(基于Haskell开发的平铺式WM)" \
			"09" "9wm(X11 WM inspired by Plan 9's rio)" \
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
	00 | "") standand_desktop_install ;;
	01)
		DEPENDENCY_01='icewm'
		REMOTE_DESKTOP_SESSION_01='icewm-session'
		REMOTE_DESKTOP_SESSION_02='icewm'
		;;
	02)
		DEPENDENCY_01='openbox'
		REMOTE_DESKTOP_SESSION_01='openbox-session'
		REMOTE_DESKTOP_SESSION_02='openbox'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='openbox openbox-menu'
		fi
		;;
	03)
		install_fvwm
		;;
	04)
		DEPENDENCY_01='awesome'
		REMOTE_DESKTOP_SESSION_01='awesome'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='awesome awesome-extra'
		fi
		;;
	05)
		DEPENDENCY_01='enlightenment'
		REMOTE_DESKTOP_SESSION_01='enlightenment'
		;;
	06)
		DEPENDENCY_01='fluxbox'
		REMOTE_DESKTOP_SESSION_01='fluxbox'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='bbmail bbpager bbtime fbpager fluxbox'
		fi
		;;
	07)
		DEPENDENCY_01='i3'
		REMOTE_DESKTOP_SESSION_01='i3'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='i3 i3-wm i3blocks'
		fi
		;;
	08)
		DEPENDENCY_01='xmonad'
		REMOTE_DESKTOP_SESSION_01='xmonad'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='xmobar dmenu xmonad'
		fi
		;;
	09)
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
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='bbmail bbpager bbtime blackbox'
		fi
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
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			echo "检测到您处于proot容器环境下，kwin可能无法正常运行"
			RETURN_TO_WHERE="window_manager_install"
			do_you_want_to_continue
		fi
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
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='matchbox-themes-extra matchbox-window-manager'
		fi
		;;
	29)
		DEPENDENCY_01='miwm'
		REMOTE_DESKTOP_SESSION_01='miwm'
		;;
	30)
		DEPENDENCY_01='muffin'
		REMOTE_DESKTOP_SESSION_01='muffin'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='murrine-themes muffin'
		fi
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
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='pekwm-themes pekwm'
		fi
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
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='sawfish-themes sawfish'
		fi
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
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01='fvwm fvwm-icons'
		#REMOTE_DESKTOP_SESSION_01='fvwm'
		if grep -Eq 'buster|bullseye|bookworm' /etc/os-release; then
			DEPENDENCY_01='fvwm fvwm-icons fvwm-crystal'
		else
			REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/f/fvwm-crystal/'
			GREP_NAME='all'
			grep_deb_comman_model_01
			if [ $(command -v fvwm-crystal) ]; then
				REMOTE_DESKTOP_SESSION_01='fvwm-crystal'
			fi
		fi
	fi
}
#################
download_deb_comman_model_02() {
	cd /tmp/
	THE_LATEST_DEB_LINK="${REPO_URL}${THE_LATEST_DEB_VERSION}"
	echo ${THE_LATEST_DEB_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_VERSION}" "${THE_LATEST_DEB_LINK}"
	apt show ./${THE_LATEST_DEB_VERSION}
	apt install -y ./${THE_LATEST_DEB_VERSION}
	rm -fv ${THE_LATEST_DEB_VERSION}
}
#########################
grep_deb_comman_model_02() {
	THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '.deb' | grep "${GREP_NAME_01}" | grep "${GREP_NAME_02}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	download_deb_comman_model_02
}
###################
grep_deb_comman_model_01() {
	THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '.deb' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	download_deb_comman_model_02
}
###################
tmoe_virtual_machine_desktop() {
	BETA_DESKTOP=$(whiptail --title "DE" --menu \
		"您可以在虚拟机或实体机上安装以下桌面\nYou can install the following desktop in \na physical or virtual machine environment." 0 0 0 \
		"1" "lxqt(lxde原作者基于QT开发的桌面)" \
		"2" "kde plasma5(风格华丽的桌面环境)" \
		"3" "gnome3(GNU网络对象模型环境)" \
		"4" "cinnamon(肉桂类似于GNOME,对用户友好)" \
		"5" "dde(国产deepin系统桌面)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${BETA_DESKTOP}" in
	0 | "") standand_desktop_install ;;
	1) install_lxqt_desktop ;;
	2) install_kde_plasma5_desktop ;;
	3) install_gnome3_desktop ;;
	4) install_cinnamon_desktop ;;
	5) install_deepin_desktop ;;
	esac
	##################
	press_enter_to_return
	tmoe_linux_tool_menu
}
#####################
################
configure_vnc_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
	#由于跨架构模拟时，桌面启动过慢，故下面先启动终端。
	cat >xstartup <<-EndOfFile
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb \${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		if [ \$(command -v x-terminal-emulator) ]; then
			x-terminal-emulator &
		fi
		if [ \$(command -v ${REMOTE_DESKTOP_SESSION_01}) ]; then
			dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01} &
		else
			dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_02} &
		fi
	EndOfFile
	#dbus-launch startxfce4 &
	chmod +x ./xstartup
	first_configure_startvnc
}
####################
configure_x11vnc_remote_desktop_session() {
	cd /usr/local/bin/
	rm -f startx11vnc
	cat >startx11vnc <<-EOF
		#!/bin/bash
		stopvnc 2>/dev/null
		stopx11vnc
		export PULSE_SERVER=127.0.0.1
		export DISPLAY=:233
		if [ ! -e "${HOME}/.vnc/x11passwd" ]; then
		          x11vncpasswd
		fi
		TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
		if [ -e "\${TMOE_LOCALE_FILE}" ]; then
		    TMOE_LANG=\$(cat ${TMOE_LOCALE_FILE} | head -n 1)
		    export LANG="\${TMOE_LANG}"
		else
		    export LANG="en_US.UTF-8"
		fi
		/usr/bin/Xvfb :233 -screen 0 1440x720x24 -ac +extension GLX +render -noreset & 
		if [ "$(uname -r | cut -d '-' -f 3 | head -n 1)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2 | head -n 1)" = "microsoft" ]; then
			echo '检测到您使用的是WSL,正在为您打开音频服务'
			cd "/mnt/c/Users/Public/Downloads/pulseaudio"
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat"
			echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
			if grep -q '172..*1' "/etc/resolv.conf"; then
				echo "检测到您当前使用的可能是WSL2"
				WSL2IP=\$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
				export PULSE_SERVER=\${WSL2IP}
				echo "已将您的音频服务ip修改为\${WSL2IP}"
			fi
		fi
		if [ \$(command -v ${REMOTE_DESKTOP_SESSION_01}) ]; then
		    ${REMOTE_DESKTOP_SESSION_01} &
		else
		    ${REMOTE_DESKTOP_SESSION_02} &
		fi
		x11vnc -ncache_cr -xkb -noxrecord -noxfixes -noxdamage -display :233 -forever -bg -rfbauth \${HOME}/.vnc/x11passwd -users \$(whoami) -rfbport 5901 -noshm &
		sleep 2s
		echo "正在启动x11vnc服务,本机默认vnc地址localhost:5901"
		echo The LAN VNC address 局域网地址 \$(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):5901
		echo "您可能会经历长达10多秒的黑屏"
		echo "You may experience a black screen for up to 10 seconds."
		echo "您之后可以输startx11vnc启动，输stopvnc或stopx11vnc停止"
		echo "You can type startx11vnc to start x11vnc,type stopx11vnc to stop it."
	EOF
	cat >stopx11vnc <<-'EOF'
		#!/bin/bash
		pkill dbus
		pkill Xvfb
	EOF
	#pkill pulse
	cat >x11vncpasswd <<-'EOF'
		#!/bin/bash
		echo "Configuring x11vnc..."
		echo "正在配置x11vnc server..."
		read -sp "请输入6至8位密码，Please enter the new VNC password: " PASSWORD
		mkdir -p ${HOME}/.vnc
		x11vnc -storepasswd $PASSWORD ${HOME}/.vnc/x11passwd
	EOF
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
	echo "x11vnc配置完成，您可以输${GREEN}startx11vnc${RESET}来重启服务"
	echo "You can type ${GREEN}startx11vnc${RESET} to restart it."
	#startx11vnc
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
	dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s Windows-10-Icons
}
###################
apt_purge_libfprint() {
	if [ "${LINUX_DISTRO}" = "debian" ] && [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		apt purge -y ^libfprint
		apt clean
		apt autoclean
	fi
}
###################
debian_xfce4_extras() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "kali" ]; then
			kali_xfce4_extras
		fi
		if [ ! $(command -v xfce4-panel-profiles) ]; then
			REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/universe/x/xfce4-panel-profiles/'
			GREP_NAME="xfce4-panel-profiles"
			THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '.deb' | grep "${GREP_NAME}" | grep -v '1.0.9' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			download_deb_comman_model_02
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
		echo "正在配置xfce4终端配色..."
		curl -Lo "colorschemes.tar.xz" 'https://gitee.com/mo2/xfce-themes/raw/terminal/colorschemes.tar.xz'
		tar -Jxvf "colorschemes.tar.xz"
	fi

	XFCE_TERMINAL_PATH="${HOME}/.config/xfce4/terminal/"
	if [ ! -e "${XFCE_TERMINAL_PATH}/terminalrc" ]; then
		mkdir -p ${XFCE_TERMINAL_PATH}
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
install_xfce4_desktop() {
	echo '即将为您安装思源黑体(中文字体)、xfce4、xfce4-terminal、xfce4-goodies和tightvncserver等软件包。'
	REMOTE_DESKTOP_SESSION_01='xfce4-session'
	REMOTE_DESKTOP_SESSION_02='startxfce4'
	DEPENDENCY_01="xfce4"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01="xfce4 xfce4-goodies xfce4-terminal"
		dpkg --configure -a
		auto_select_keyboard_layout
		##############
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='@xfce'
		rm -v /etc/xdg/autostart/xfce-polkit.desktop
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
		DEPENDENCY_01="faenza-icon-theme xfce4-whiskermenu-plugin xfce4 xfce4-terminal"
		##############
	fi
	##################
	beta_features_quick_install
	####################
	debian_xfce4_extras
	if [ ! -e "/usr/share/icons/Breeze-Adapta-Cursor" ]; then
		download_arch_breeze_adapta_cursor_theme
		dbus-launch xfconf-query -c xsettings -t string -np /Gtk/CursorThemeName -s "Breeze-Adapta-Cursor" 2>/dev/null
	fi
	mkdir -p ${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/
	cd ${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/
	if [ ! -e "xfce4-desktop.xml" ]; then
		modify_the_default_xfce_wallpaper
	fi

	#XFCE_WORK_SPACE_01=$(cat xfce4-desktop.xml | grep -n workspace1 | awk '{print $1}' | cut -d ':' -f 1)
	#if [ "$(cat xfce4-desktop.xml | sed -n 1,${XFCE_WORK_SPACE_01}p | grep -E 'xfce-stripes|xfce-blue|xfce-teal|0.svg')" ]; then
	#	modify_the_default_xfce_wallpaper
	#fi
	if [ ! -e "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" ]; then
		auto_configure_xfce4_panel
	fi
	#################
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s Faenza
	else
		if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
			download_kali_themes_common
		fi
		if [ "${DEBIAN_DISTRO}" != "kali" ]; then
			dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s Flat-Remix-Blue-Light
		fi
	fi
	##############
	xfce4_color_scheme
	#########
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
debian_xfce_wallpaper() {
	if [ ! -e "${WALLPAPER_FILE}" ]; then
		#debian_download_xubuntu_xenial_wallpaper
		if [ ${LANG} = "en_US.UTF-8" ]; then
			mkdir -p ${HOME}/图片
		fi
		echo "壁纸包将保存至/usr/share/backgrounds"
		debian_download_ubuntu_mate_wallpaper
	fi
	modify_xfce_vnc0_wallpaper
}
#################
if_exists_other_debian_distro_wallpaper() {
	if [ -e "${WALLPAPER_FILE}" ]; then
		modify_xfce_vnc0_wallpaper
	else
		debian_xfce_wallpaper
	fi
}
###############
modify_the_default_xfce_wallpaper() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		WALLPAPER_FILE='/usr/share/backgrounds/gabriele-diwald-201135.jpg'
		if [ "${DEBIAN_DISTRO}" = "kali" ]; then
			#WALLPAPER_FILE='/usr/share/backgrounds/kali/kali/kali-mesh-16x9.png'
			#if_exists_other_debian_distro_wallpaper
			WALLPAPER_FILE='/usr/share/backgrounds/nattu-adnan-328570.jpg'
		elif [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			#WALLPAPER_FILE='/usr/share/xfce4/backdrops/Campos_de_Castilla_by_David_Arias_Gutierrez.jpg'
			WALLPAPER_FILE='/usr/share/backgrounds/nattu-adnan-328570.jpg'
		fi
		debian_xfce_wallpaper
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		WALLPAPER_FILE="/usr/share/backgrounds/xfce/Violet.jpg"
		if [ -e "${WALLPAPER_FILE}" ]; then
			modify_xfce_vnc0_wallpaper
		else
			WALLPAPER_FILE='/usr/share/backgrounds/nasa-53884.jpg'
			debian_xfce_wallpaper
		fi
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		WALLPAPER_FILE='/usr/share/backgrounds/kristopher-roller-110203.jpg'
		debian_xfce_wallpaper
	else
		WALLPAPER_FILE='/usr/share/backgrounds/johann-siemens-591.jpg'
		debian_xfce_wallpaper
	fi
}
#################
debian_download_ubuntu_mate_wallpaper() {
	FORCIBLY_DOWNLOAD='true'
	download_ubuntu-mate_wallpaper
	if [ -e "${HOME}/Pictures/ubuntu-mate-photos" ]; then
		mv ${HOME}/Pictures/ubuntu-mate-photos/* /usr/share/backgrounds -f
		rm -rf ${HOME}/Pictures/ubuntu-mate-photos/
	elif [ -e "${HOME}/图片/ubuntu-mate-photos" ]; then
		mv ${HOME}/图片/ubuntu-mate-photos/* /usr/share/backgrounds -f
		rm -rf ${HOME}/图片/ubuntu-mate-photos/
	fi
}
#####################
debian_download_xubuntu_xenial_wallpaper() {
	REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/universe/x/xubuntu-community-artwork/'
	GREP_NAME_01='xubuntu-community-wallpapers-xenial'
	GREP_NAME_02='all.deb'
	grep_deb_comman_model_02
}
###############
auto_configure_xfce4_panel() {
	XFCE_CONFIG_FOLDER="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml"
	mkdir -p ${XFCE_CONFIG_FOLDER}
	cd ${XFCE_CONFIG_FOLDER}
	cat >>xfce4-panel.xml <<-'ENDOFXFCEPANEL'
		<?xml version="1.0" encoding="UTF-8"?>

		<channel name="xfce4-panel" version="1.0">
		<property name="configver" type="int" value="2"/>
		<property name="panels" type="array">
			<value type="int" value="1"/>
			<value type="int" value="2"/>
			<property name="panel-1" type="empty">
				<property name="autohide-behavior" type="uint" value="0"/>
				<property name="background-alpha" type="uint" value="100"/>
				<property name="background-style" type="uint" value="0"/>
				<property name="disable-struts" type="bool" value="false"/>
				<property name="enter-opacity" type="uint" value="88"/>
				<property name="leave-opacity" type="uint" value="74"/>
				<property name="length" type="uint" value="100"/>
				<property name="mode" type="uint" value="0"/>
				<property name="nrows" type="uint" value="1"/>
				<property name="plugin-ids" type="array">
					<value type="int" value="7"/>
					<value type="int" value="1"/>
					<value type="int" value="2"/>
					<value type="int" value="3"/>
					<value type="int" value="24"/>
					<value type="int" value="4"/>
					<value type="int" value="5"/>
					<value type="int" value="6"/>
					<value type="int" value="8"/>
					<value type="int" value="9"/>
					<value type="int" value="10"/>
					<value type="int" value="11"/>
					<value type="int" value="12"/>
					<value type="int" value="13"/>
					<value type="int" value="14"/>
				</property>
				<property name="position" type="string" value="p=6;x=0;y=0"/>
				<property name="position-locked" type="bool" value="true"/>
				<property name="size" type="uint" value="26"/>
			</property>
			<property name="panel-2" type="empty">
				<property name="autohide-behavior" type="uint" value="1"/>
				<property name="background-alpha" type="uint" value="100"/>
				<property name="background-style" type="uint" value="0"/>
				<property name="disable-struts" type="bool" value="false"/>
				<property name="enter-opacity" type="uint" value="88"/>
				<property name="leave-opacity" type="uint" value="77"/>
				<property name="length" type="uint" value="10"/>
				<property name="length-adjust" type="bool" value="true"/>
				<property name="mode" type="uint" value="0"/>
				<property name="nrows" type="uint" value="1"/>
				<property name="plugin-ids" type="array">
					<value type="int" value="15"/>
					<value type="int" value="16"/>
					<value type="int" value="17"/>
					<value type="int" value="18"/>
					<value type="int" value="19"/>
					<value type="int" value="20"/>
					<value type="int" value="21"/>
					<value type="int" value="22"/>
				</property>
				<property name="position" type="string" value="p=10;x=0;y=0"/>
				<property name="position-locked" type="bool" value="true"/>
				<property name="size" type="uint" value="48"/>
			</property>
		</property>
		<property name="plugins" type="empty">
			<property name="plugin-10" type="string" value="notification-plugin"/>
			<property name="plugin-11" type="string" value="separator">
				<property name="expand" type="bool" value="false"/>
				<property name="style" type="uint" value="0"/>
			</property>
			<property name="plugin-12" type="string" value="clock">
				<property name="digital-format" type="string" value="%a,%b %d,%R:%S"/>
				<property name="mode" type="uint" value="2"/>
				<property name="show-frame" type="bool" value="true"/>
				<property name="tooltip-format" type="string" value="%A %d %B %Y"/>
			</property>
			<property name="plugin-13" type="string" value="separator">
				<property name="expand" type="bool" value="false"/>
				<property name="style" type="uint" value="0"/>
			</property>
			<property name="plugin-14" type="string" value="actions">
				<property name="appearance" type="uint" value="1"/>
				<property name="ask-confirmation" type="bool" value="true"/>
			</property>
			<property name="plugin-15" type="string" value="showdesktop"/>
			<property name="plugin-16" type="string" value="separator">
				<property name="expand" type="bool" value="false"/>
				<property name="style" type="uint" value="1"/>
			</property>
			<property name="plugin-17" type="string" value="launcher">
				<property name="items" type="array">
					<value type="string" value="exo-terminal-emulator.desktop"/>
				</property>
			</property>
			<property name="plugin-18" type="string" value="launcher">
				<property name="items" type="array">
					<value type="string" value="exo-file-manager.desktop"/>
				</property>
			</property>
			<property name="plugin-19" type="string" value="launcher">
				<property name="items" type="array">
					<value type="string" value="exo-web-browser.desktop"/>
				</property>
			</property>
			<property name="plugin-2" type="string" value="tasklist">
				<property name="grouping" type="uint" value="1"/>
			</property>
			<property name="plugin-20" type="string" value="launcher">
				<property name="items" type="array">
					<value type="string" value="xfce4-appfinder.desktop"/>
				</property>
			</property>
			<property name="plugin-21" type="string" value="separator">
				<property name="expand" type="bool" value="false"/>
				<property name="style" type="uint" value="1"/>
			</property>
			<property name="plugin-22" type="string" value="directorymenu">
				<property name="expand" type="bool" value="true"/>
				<property name="style" type="uint" value="0"/>
			</property>
			<property name="plugin-3" type="string" value="separator">
				<property name="expand" type="bool" value="true"/>
				<property name="style" type="uint" value="0"/>
			</property>
			<property name="plugin-4" type="string" value="pager">
				<property name="miniature-view" type="bool" value="true"/>
				<property name="rows" type="uint" value="1"/>
				<property name="workspace-scrolling" type="bool" value="false"/>
			</property>
			<property name="plugin-5" type="string" value="separator">
				<property name="expand" type="bool" value="false"/>
				<property name="style" type="uint" value="0"/>
			</property>
			<property name="plugin-6" type="string" value="systray">
				<property name="show-frame" type="bool" value="false"/>
				<property name="size-max" type="uint" value="22"/>
				<property name="square-icons" type="bool" value="true"/>
				<property name="names-ordered" type="array">
				</property>
			</property>
			<property name="plugin-8" type="string" value="pulseaudio">
				<property name="enable-keyboard-shortcuts" type="bool" value="true"/>
				<property name="show-notifications" type="bool" value="true"/>
			</property>
			<property name="plugin-9" type="string" value="power-manager-plugin"/>
			<property name="plugin-7" type="string" value="whiskermenu"/>
			<property name="plugin-1" type="string" value="applicationsmenu"/>
			<property name="plugin-24" type="string" value="xfce4-clipman-plugin"/>
		</property>
		</channel>
	ENDOFXFCEPANEL
	CURRENT_USER_FILE=$(pwd)
	fix_non_root_permissions
}
############
install_lxde_desktop() {
	REMOTE_DESKTOP_SESSION_01='lxsession'
	REMOTE_DESKTOP_SESSION_02='startlxde'
	echo '即将为您安装思源黑体(中文字体)、lxde-core、lxterminal、tightvncserver。'
	DEPENDENCY_01='lxde'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="lxde-core lxterminal"
		#############
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='lxde-desktop'
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
		DEPENDENCY_01='patterns-lxde-lxde'
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="lxsession"
		REMOTE_DESKTOP_SESSION='lxsession'
	###################
	fi
	############
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
##########################
arch_linux_mate_warning() {
	echo "${RED}WARNING！${RESET}检测到您当前使用的是${YELLOW}Arch系发行版${RESET},并且处于${GREEN}proot容器${RESET}环境下！"
	echo "mate-session在当前容器环境下可能会出现${RED}屏幕闪烁${RESET}的现象"
	echo "按${GREEN}回车键${RESET}${BLUE}继续安装${RESET}"
	echo "${YELLOW}Do you want to continue?[Y/l/x/q/n]${RESET}"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET},type n to return."
	echo "Type q to install lxqt,type l to install lxde,type x to install xfce."
	echo "按${GREEN}回车键${RESET}${RED}继续${RESET}安装mate，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
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
}
###############
install_mate_desktop() {
	REMOTE_DESKTOP_SESSION_01='mate-session'
	REMOTE_DESKTOP_SESSION_02='x-window-manager'
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
		DEPENDENCY_01='@mate-desktop'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			arch_linux_mate_warning
		else
			DEPENDENCY_01='mate mate-extra'
		fi

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
	configure_vnc_xstartup
}
#############
######################
#DEPENDENCY_02="dbus-x11 fonts-noto-cjk tightvncserver"
install_lxqt_desktop() {
	REMOTE_DESKTOP_SESSION_02='startlxqt'
	REMOTE_DESKTOP_SESSION_01='lxqt-session'
	DEPENDENCY_01="lxqt"
	echo '即将为您安装思源黑体(中文字体)、lxqt-core、lxqt-config、qterminal和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="lxqt-core lxqt-config qterminal"
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='@lxqt'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="lxqt xorg"
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_01="lxqt-base/lxqt-meta"
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="patterns-lxqt-lxqt"
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="openbox pcmfm rxvt-unicode tint2"
		REMOTE_DESKTOP_SESSION='openbox'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
####################
install_kde_plasma5_desktop() {
	REMOTE_DESKTOP_SESSION_01='startkde'
	REMOTE_DESKTOP_SESSION_02='startplasma-x11'
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
		DEPENDENCY_01='@KDE'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="plasma-desktop xorg kdebase konsole sddm sddm-kcm"
		#phonon-qt5
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
	configure_vnc_xstartup
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
		RETURN_TO_WHERE='tmoe_virtual_machine_desktop'
		do_you_want_to_continue
	fi
	#DEPENDENCY_01="plasma-desktop"
	RETURN_TO_WHERE="tmoe_virtual_machine_desktop"
	do_you_want_to_continue
}
###############
install_gnome3_desktop() {
	gnome3_warning
	REMOTE_DESKTOP_SESSION_01='gnome-session'
	REMOTE_DESKTOP_SESSION_02='x-window-manager'
	DEPENDENCY_01="gnome"
	echo '即将为您安装思源黑体(中文字体)、gnome-session、gnome-menus、gnome-tweak-tool、gnome-shell和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		#aptitude install -y task-gnome-desktop || apt install -y task-gnome-desktop
		#apt install --no-install-recommends xorg gnome-session gnome-menus gnome-tweak-tool gnome-shell || aptitude install -y gnome-core
		DEPENDENCY_01='--no-install-recommends xorg gnome-session gnome-menus gnome-tweak-tool gnome-core gnome-shell-extension-dashtodock gnome-shell'
		#若不包含gnome-core，则为最简化安装
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		#yum groupinstall "GNOME Desktop Environment"
		#dnf groupinstall -y "GNOME" || yum groupinstall -y "GNOME"
		DEPENDENCY_01='@GNOME'

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='gnome-extra gnome'

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
		DEPENDENCY_01="gnome"
		REMOTE_DESKTOP_SESSION='gnome-session'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
#################
install_cinnamon_desktop() {
	REMOTE_DESKTOP_SESSION_01='cinnamon-session'
	REMOTE_DESKTOP_SESSION_02='cinnamon-launcher'
	DEPENDENCY_01="cinnamon"
	echo '即将为您安装思源黑体(中文字体)、cinnamon和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="--no-install-recommends cinnamon cinnamon-desktop-environment"

	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='@Cinnamon Desktop'

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
	configure_vnc_xstartup
}
####################
deepin_desktop_warning() {
	if [ "${ARCH_TYPE}" != "i386" ] && [ "${ARCH_TYPE}" != "amd64" ]; then
		echo "非常抱歉，深度桌面不支持您当前的架构。"
		echo "建议您在换用x86_64或i386架构的设备后，再来尝试。"
		echo "${YELLOW}警告！deepin桌面可能无法正常运行${RESET}"
		arch_does_not_support
		tmoe_virtual_machine_desktop
	fi
}
#################
dde_old_version() {
	if [ ! $(command -v gpg) ]; then
		DEPENDENCY_01="gpg"
		DEPENDENCY_02=""
		echo "${GREEN} ${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
		echo "即将为您安装gpg..."
		${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01}
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
	echo '即将为您安装思源黑体(中文字体)、dde和tightvncserver等软件包。'
	dpkg --configure -a
	apt update
	auto_select_keyboard_layout
	aptitude install -y dde
	sed -i 's/^deb/#&/g' /etc/apt/sources.list.d/deepin.list
	apt update
}
################
ubuntu_dde_distro_code() {
	aria2c --allow-overwrite=true -o .ubuntu_ppa_tmoe_cache 'http://ppa.launchpad.net/ubuntudde-dev/stable/ubuntu/dists/'
	TARGET_CODE=$(cat .ubuntu_ppa_tmoe_cache | grep '\[DIR' | tail -n 1 | cut -d '=' -f 5 | cut -d '/' -f 1 | cut -d '"' -f 2)
	if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
		if [ $(cat .ubuntu_ppa_tmoe_cache | grep '\[DIR' | grep "${SOURCELISTCODE}") ]; then
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
		SOURCELISTCODE=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d '=' -f 2 | head -n 1)
	fi
	ubuntu_dde_distro_code
	check_ubuntu_ppa_list
	sed -i "s@ ${CURRENT_UBUNTU_CODE}@ ${TARGET_CODE}@g" ${PPA_LIST_FILE}
}
###################
###############
################
install_deepin_desktop() {
	#deepin_desktop_warning
	REMOTE_DESKTOP_SESSION_01='startdde'
	REMOTE_DESKTOP_SESSION_02='x-window-manager'
	DEPENDENCY_01="deepin-desktop"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		deepin_desktop_debian
		#DEPENDENCY_01="dde"
		DEPENDENCY_01="ubuntudde-dde"

	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='deepin-desktop'

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		#pacman -S --noconfirm deepin-kwin
		#pacman -S --noconfirm file-roller evince
		#rm -v ~/.pam_environment 2>/dev/null
		DEPENDENCY_01="deepin deepin-extra lightdm lightdm-deepin-greeter xorg"
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
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
set_default_xfce_icon_theme() {
	dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s ${XFCE_ICON_NAME} 2>/dev/null
}
###############
creat_update_icon_caches() {
	cd /usr/local/bin/
	cat >update-icon-caches <<-'EndofFile'
		#!/bin/sh
		case "$1" in
		    ""|-h|--help)
		        echo "Usage: $0 directory [ ... ]"
		        exit 1
		        ;;
		esac

		for dir in "$@"; do
		    if [ ! -d "$dir" ]; then
		        continue
		    fi
		    if [ -f "$dir"/index.theme ]; then
		        if ! gtk-update-icon-cache --force --quiet "$dir"; then
		            echo "WARNING: icon cache generation failed for $dir"
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
#
tmoe_desktop_beautification() {
	NON_DEBIAN='false'
	DEPENDENCY_01=''
	RETURN_TO_WHERE='tmoe_desktop_beautification'
	BEAUTIFICATION=$(whiptail --title "beautification" --menu \
		"你想要如何美化桌面？\nHow do you want to beautify the DE? " 0 50 0 \
		"1" "🍨themes:主题(你有一双善于发现美的眼睛)" \
		"2" "🎀icon-theme:图标包(点缀出惊艳绝伦)" \
		"3" "🍹wallpaper:壁纸(感受万物之息)" \
		"4" "↗mouse cursor(璀璨夺目的鼠标指针)" \
		"5" "⛈conky(显示资源占用情况,还有...天气预报)" \
		"6" "💫dock栏(plank/docky)" \
		"7" "🎇compiz(如花火般绚烂)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${BEAUTIFICATION}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) configure_theme ;;
	2) download_icon_themes ;;
	3) download_wallpapers ;;
	4) configure_mouse_cursor ;;
	5) install_conky ;;
	6) install_docky ;;
	7) install_compiz ;;
	esac
	##########################
	press_enter_to_return
	tmoe_desktop_beautification
}
###########
configure_conky() {
	cd ${HOME}
	mkdir -p github
	cd github
	git clone --depth=1 https://github.com/zagortenay333/Harmattan.git || git clone --depth=1 git://github.com/zagortenay333/Harmattan.git
	echo "进入${HOME}/github/Harmattan"
	echo "执行bash preview"
	echo 'To get more help info,please go to github.'
	echo 'https://github.com/zagortenay333/Harmattan'
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
	DEPENDENCY_01="docky"
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
		"1" "🌈XFCE-LOOK-parser主题链接解析器" \
		"2" "⚡local-theme-installer本地主题安装器" \
		"3" "🎭win10:kali卧底模式主题" \
		"4" "🚥MacOS:Mojave" \
		"5" "🎋breeze:plasma桌面微风gtk+版主题" \
		"6" "Kali:Flat-Remix-Blue主题" \
		"7" "ukui:国产优麒麟ukui桌面主题" \
		"8" "arc:融合透明元素的平面主题" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	########################
	case "${INSTALL_THEME}" in
	0 | "") tmoe_desktop_beautification ;;
	1) xfce_theme_parsing ;;
	2) local_theme_installer ;;
	3) install_kali_undercover ;;
	4) download_macos_mojave_theme ;;
	5) install_breeze_theme ;;
	6) download_kali_theme ;;
	7) download_ukui_theme ;;
	8) install_arc_gtk_theme ;;
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
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		TMOE_THEME_ITEM=${TMOE_FILE_ABSOLUTE_PATH}
		tar -tf ${TMOE_THEME_ITEM} | cut -d '/' -f 1 | sort -u
		do_you_want_to_continue
		tmoe_theme_installer
	fi
}
#################
check_theme_url() {
	if [ "$(echo ${THEME_TMOE_URL} | grep -v 'xfce-look.org')" ]; then
		echo "原始链接中不包含xfce-look，可能会出现错误。"
	fi

	if [ "$(echo ${THEME_TMOE_URL} | grep 'XFCE/p')" ]; then
		TMOE_THEME_STATUS='检测到当前文件可能是图标包'
	elif [ "$(echo ${THEME_TMOE_URL} | grep 'Gnome/p')" ]; then
		TMOE_THEME_STATUS='检测到当前文件可能是Gnome图标包'
	else
		TMOE_THEME_STATUS='主题和图标包的解压路径不同，请手动判断'
	fi

	#当未添加http时，将自动修复。
	if [ "$(echo ${THEME_TMOE_URL} | grep -E 'www')" ] && [ ! "$(echo ${THEME_TMOE_URL} | grep 'http')" ]; then
		THEME_TMOE_URL=$(echo ${THEME_TMOE_URL} | sed 's@www@https://&@')
	fi
}
###############
xfce_theme_parsing() {
	THEME_TMOE_URL=$(whiptail --inputbox "Please enter a url.请输入主题链接\n例如https://www.xfce-look.org/p/xxxx \n Press Enter after the input is completed." 0 50 --title "请在地址栏内输入 主题链接" 3>&1 1>&2 2>&3)

	if [ "$?" != "0" ]; then
		configure_theme
	elif [ -z ${THEME_TMOE_URL} ]; then
		echo "请输入有效的url"
		echo "Please enter a valid url."
	else
		check_theme_url
	fi

	cd /tmp/
	echo "正在下载网页文件.."
	echo "Downloading index.html..."
	aria2c --allow-overwrite=true -o .theme_index_cache_tmoe.html ${THEME_TMOE_URL}

	cat .theme_index_cache_tmoe.html | sed 's@,@\n@g' | grep -E 'tar.xz|tar.gz' | grep '"title"' | sed 's@"@ @g' | awk '{print $3}' | sort -um >.tmoe-linux_cache.01
	THEME_LINE=$(cat .tmoe-linux_cache.01 | wc -l)
	cat .theme_index_cache_tmoe.html | sed 's@,@\n@g' | sed 's@%2F@/@g' | sed 's@%3A@:@g' | sed 's@%2B@+@g' | sed 's@%3D@=@g' | sed 's@%23@#@g' | sed 's@%26@\&@g' | grep -E '"downloaded_count"' | sed 's@"@ @g' | awk '{print $3}' | head -n ${THEME_LINE} | sed 's/ /-/g' | sed 's/$/次/g' >.tmoe-linux_cache.02
	TMOE_THEME_FILE_LIST=$(paste -d ' ' .tmoe-linux_cache.01 .tmoe-linux_cache.02 | sed ":a;N;s/\n/ /g;ta")
	rm -f .tmoe-linux_cache.0*

	TMOE_THEME_ITEM=$(whiptail --title "THEME" --menu \
		"您想要下载哪个主题？\nWhich theme do you want to download?\n文件名称                 下载次数(可能有严重偏差)" 0 0 0 \
		${TMOE_THEME_FILE_LIST} \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	case ${TMOE_THEME_ITEM} in
	0 | "") configure_theme ;;
	esac
	DOWNLOAD_FILE_URL=$(cat .theme_index_cache_tmoe.html | sed 's@,@\n@g' | sed 's@%2F@/@g' | sed 's@%3A@:@g' | sed 's@%2B@+@g' | sed 's@%3D@=@g' | sed 's@%23@#@g' | sed 's@%26@\&@g' | grep -E 'tar.xz|tar.gz' | grep '"url"' | grep ${TMOE_THEME_ITEM} | sed 's@"@ @g' | awk '{print $3}' | sort -um | head -n 1)
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
	echo "解压完成，如需删除该主题，请手动输${YELLOW}cd ${EXTRACT_FILE_PATH} ; ls ;rm -rv ${EXTRACT_FILE_FOLDER} ${RESET}"
	echo "是否${RED}删除${RESET}主题压缩包${BLUE}原文件？${RESET}"
	echo "Do you want to delete the original compressed file？[Y/n]"
	do_you_want_to_continue
	rm -fv ${TMOE_THEME_ITEM} .theme_index_cache_tmoe.html
}
#########################
check_theme_folder_exists_status() {
	if [ -e "${EXTRACT_FILE_PATH}/${EXTRACT_FILE_FOLDER_HEAD_01}" ]; then
		echo "检测到您已安装该主题，如需删除，请手动输${YELLOW}cd ${EXTRACT_FILE_PATH} ; ls ;rm -rv ${EXTRACT_FILE_FOLDER} ${RESET}"
		echo "是否重新解压？"
		echo "Do you want to uncompress again?"
		do_you_want_to_continue
	fi
	uncompress_theme_file
}
###################
uncompress_theme_file() {
	case "${TMOE_THEME_ITEM:0-6:6}" in
	tar.xz)
		tar -Jxvf ${TMOE_THEME_ITEM} -C ${EXTRACT_FILE_PATH} 2>/dev/null
		;;
	tar.gz)
		tar -zxvf ${TMOE_THEME_ITEM} -C ${EXTRACT_FILE_PATH} 2>/dev/null
		;;
	*)
		tar -xvf ${TMOE_THEME_ITEM} -C ${EXTRACT_FILE_PATH} 2>/dev/null
		;;
	esac
}
############
check_tar_ext_format() {
	case "${TMOE_THEME_ITEM:0-6:6}" in
	tar.xz)
		EXTRACT_FILE_FOLDER=$(tar -Jtf ${TMOE_THEME_ITEM} | cut -d '/' -f 1 | sort -u | sed ":a;N;s/\n/ /g;ta")
		;;
	tar.gz)
		EXTRACT_FILE_FOLDER=$(tar -ztf ${TMOE_THEME_ITEM} | cut -d '/' -f 1 | sort -u | sed ":a;N;s/\n/ /g;ta")
		;;
	*)
		EXTRACT_FILE_FOLDER=$(tar -tf ${TMOE_THEME_ITEM} | cut -d '/' -f 1 | sort -u | sed ":a;N;s/\n/ /g;ta")
		;;
	esac
	EXTRACT_FILE_FOLDER_HEAD_01=$(echo ${EXTRACT_FILE_FOLDER} | awk '{print $1}')
	check_theme_folder_exists_status
}
################
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
		mkdir -p ${HOME}/图片/xubuntu-community-artwork
	else
		mkdir -p ${HOME}/Pictures/xubuntu-community-artwork
	fi
	THEME_NAME='xubuntu_wallpaper'
	WALLPAPER_NAME='xfce4/backdrops'
	GREP_NAME_01='all.deb'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/universe/x/xubuntu-community-artwork/'
	grep_theme_model_03
	move_wallpaper_model_01
}
###############
ubuntu_gnome_walllpapers() {
	RETURN_TO_WHERE='ubuntu_gnome_walllpapers'
	#cat index.html | sort -u | grep 20.04 | grep all.deb | cut -d '=' -f 4 | cut -d '"' -f 2 |cut -d '_' -f 1 | cut -d '-' -f 3
	INSTALL_THEME=$(whiptail --title "UBUNTU壁纸" --menu \
		"Download ubuntu wallpapers" 0 50 0 \
		"00" "Back返回" \
		"01" "artful" \
		"02" "bionic" \
		"03" "cosmic" \
		"04" "disco" \
		"05" "eoan" \
		"06" "karmic" \
		"07" "lucid" \
		"08" "maverick" \
		"09" "natty" \
		"10" "oneiric" \
		"11" "precise" \
		"12" "quantal" \
		"13" "raring" \
		"14" "saucy" \
		"15" "trusty" \
		"16" "utopic" \
		"17" "vivid" \
		"18" "wily" \
		"19" "xenial" \
		"20" "yakkety" \
		"21" "zesty" \
		3>&1 1>&2 2>&3)
	########################
	case "${INSTALL_THEME}" in
	00 | "") ubuntu_wallpapers_and_photos ;;
	01) UBUNTU_CODE="artful" ;;
	02) UBUNTU_CODE="bionic" ;;
	03) UBUNTU_CODE="cosmic" ;;
	04) UBUNTU_CODE="disco" ;;
	05) UBUNTU_CODE="eoan" ;;
	06) UBUNTU_CODE="karmic" ;;
	07) UBUNTU_CODE="lucid" ;;
	08) UBUNTU_CODE="maverick" ;;
	09) UBUNTU_CODE="natty" ;;
	10) UBUNTU_CODE="oneiric" ;;
	11) UBUNTU_CODE="precise" ;;
	12) UBUNTU_CODE="quantal" ;;
	13) UBUNTU_CODE="raring" ;;
	14) UBUNTU_CODE="saucy" ;;
	15) UBUNTU_CODE="trusty" ;;
	16) UBUNTU_CODE="utopic" ;;
	17) UBUNTU_CODE="vivid" ;;
	18) UBUNTU_CODE="wily" ;;
	19) UBUNTU_CODE="xenial" ;;
	20) UBUNTU_CODE="yakkety" ;;
	21) UBUNTU_CODE="zesty" ;;
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
		mkdir -p ${HOME}/图片/ubuntu-wallpapers
	else
		mkdir -p ${HOME}/Pictures/ubuntu-wallpapers
	fi
	THEME_NAME='ubuntu_wallpaper'
	WALLPAPER_NAME='backgrounds'
	GREP_NAME_01='all.deb'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/universe/u/ubuntu-wallpapers/'
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
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/universe/u/ubuntukylin-wallpapers/'
	grep_theme_model_04
	move_wallpaper_model_02
}
#############
download_ubuntu-mate_wallpaper() {
	GREP_NAME_02='ubuntu-mate-wallpapers-photos'
	CUSTOM_WALLPAPER_NAME='ubuntu-mate-photos'
	THEME_NAME='ubuntu_wallpapers_and_photos'
	WALLPAPER_NAME='backgrounds/ubuntu-mate-photos'
	GREP_NAME_01='all.deb'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/universe/u/ubuntu-mate-artwork/'
	grep_theme_model_03
	move_wallpaper_model_01
}
#####################
linux_mint_backgrounds() {
	RETURN_TO_WHERE='linux_mint_backgrounds'
	#cat index.html | grep mint-backgrounds | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '/' -f 1 | cut -d '-' -f 3,4
	GREP_NAME_02="mint-backgrounds"
	INSTALL_THEME=$(whiptail --title "MINT壁纸包" --menu \
		"Download Mint Wallpapers" 0 50 0 \
		"00" "Back返回" \
		"01" "katya-extra" \
		"02" "lisa-extra" \
		"03" "maya" \
		"04" "nadia" \
		"05" "olivia" \
		"06" "petra" \
		"07" "qiana" \
		"08" "rafaela" \
		"09" "rebecca" \
		"10" "retro" \
		"11" "rosa" \
		"12" "sarah" \
		"13" "serena" \
		"14" "sonya" \
		"15" "sylvia" \
		"16" "tara" \
		"17" "tessa" \
		"18" "tina" \
		"19" "tricia" \
		"20" "ulyana" \
		"21" "xfce-2014" \
		3>&1 1>&2 2>&3)
	########################
	case "${INSTALL_THEME}" in
	00 | "") download_wallpapers ;;
	01) MINT_CODE="katya-extra" ;;
	02) MINT_CODE="lisa-extra" ;;
	03) MINT_CODE="maya" ;;
	04) MINT_CODE="nadia" ;;
	05) MINT_CODE="olivia" ;;
	06) MINT_CODE="petra" ;;
	07) MINT_CODE="qiana" ;;
	08) MINT_CODE="rafaela" ;;
	09) MINT_CODE="rebecca" ;;
	10) MINT_CODE="retro" ;;
	11) MINT_CODE="rosa" ;;
	12) MINT_CODE="sarah" ;;
	13) MINT_CODE="serena" ;;
	14) MINT_CODE="sonya" ;;
	15) MINT_CODE="sylvia" ;;
	16) MINT_CODE="tara" ;;
	17) MINT_CODE="tessa" ;;
	18) MINT_CODE="tina" ;;
	19) MINT_CODE="tricia" ;;
	20) MINT_CODE="ulyana" ;;
	21)
		MINT_CODE="xfce"
		GREP_NAME_02="_2014.06.09"
		;;
	esac
	######################################
	if [ "${MINT_CODE}" = 'xfce' ]; then
		WALLPAPER_NAME='xfce4/backdrops'
	else
		WALLPAPER_NAME="backgrounds/linuxmint-${MINT_CODE}"
	fi
	download_mint_backgrounds
	press_enter_to_return
	linux_mint_backgrounds
}
###############
download_mint_backgrounds() {
	CUSTOM_WALLPAPER_NAME="mint-backgrounds/linuxmint-${MINT_CODE}"
	if [ -d "${HOME}/图片" ]; then
		mkdir -p ${HOME}/图片/mint-backgrounds
	else
		mkdir -p ${HOME}/Pictures/mint-backgrounds
	fi
	THEME_NAME="mint_backgrounds_${MINT_CODE}"
	GREP_NAME_01='all.deb'
	THEME_URL="https://mirrors.tuna.tsinghua.edu.cn/linuxmint/pool/main/m/mint-backgrounds-${MINT_CODE}/"
	grep_theme_model_03
	move_wallpaper_model_01
}
###############
download_wallpapers() {
	cd /tmp
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
	echo "chameleon:现代化鼠标指针主题"
	echo 'Do you want to download it?'
	do_you_want_to_continue
	download_chameleon_cursor_theme
}
################################
check_theme_folder() {
	if [ -e "${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}" ] || [ -e ${HOME}/图片/${CUSTOM_WALLPAPER_NAME} ]; then
		echo "检测到您${RED}已经下载过${RESET}该壁纸包了"
		echo "壁纸包位于${BLUE}${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}${RESET}(图片)目录"
		echo "Do you want to ${RED}download again?${RESET}"
		echo "是否想要重新下载？"
		do_you_want_to_continue
	fi
}
##############
grep_theme_model_01() {
	check_theme_folder
	mkdir -p /tmp/.${THEME_NAME}
	cd /tmp/.${THEME_NAME}
	THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL} | grep '.deb' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	download_theme_deb_and_extract_01
}
###############
aria2c_download_theme_file() {
	THE_LATEST_THEME_LINK="${THEME_URL}${THE_LATEST_THEME_VERSION}"
	echo ${THE_LATEST_THEME_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_THEME_VERSION}" "${THE_LATEST_THEME_LINK}"
}
##########
download_theme_deb_and_extract_01() {
	aria2c_download_theme_file
	if [ "${BUSYBOX_AR}" = 'true' ]; then
		busybox ar xv ${THE_LATEST_THEME_VERSION}
	else
		ar xv ${THE_LATEST_THEME_VERSION}
	fi
}
###############
#多GREP
grep_theme_model_03() {
	if [ ${FORCIBLY_DOWNLOAD} != 'true' ]; then
		check_theme_folder
	fi
	mkdir -p /tmp/.${THEME_NAME}
	cd /tmp/.${THEME_NAME}
	THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL} | grep "${GREP_NAME_01}" | grep "${GREP_NAME_02}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	download_theme_deb_and_extract_01
}
############################
grep_theme_model_04() {
	check_theme_folder
	mkdir -p /tmp/.${THEME_NAME}
	cd /tmp/.${THEME_NAME}
	THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL} | grep "${GREP_NAME_01}" | grep "${GREP_NAME_02}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	aria2c_download_theme_file
	mv ${THE_LATEST_THEME_VERSION} data.tar.xz
}
############################
#tar.xz
#manjaro仓库
grep_theme_model_02() {
	check_theme_folder
	mkdir -p /tmp/.${THEME_NAME}
	cd /tmp/.${THEME_NAME}
	THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL} | grep -v '.xz.sig' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	aria2c_download_theme_file
}
###########
update_icon_caches_model_01() {
	cd /
	tar -Jxvf /tmp/.${THEME_NAME}/data.tar.xz ./usr
	rm -rf /tmp/.${THEME_NAME}
	echo "updating icon caches..."
	echo "正在刷新图标缓存..."
	update-icon-caches /usr/share/icons/${ICON_NAME} 2>/dev/null &
	tips_of_delete_icon_theme
}
############
download_paper_icon_theme() {
	THEME_NAME='paper_icon_theme'
	ICON_NAME='Paper /usr/share/icons/Paper-Mono-Dark'
	GREP_NAME='paper-icon-theme'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/manjaro/pool/overlay/'
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
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/p/papirus-icon-theme/'
	grep_theme_model_01
	update_icon_caches_model_01
	XFCE_ICON_NAME='Papirus'
	set_default_xfce_icon_theme
}
############################
tips_of_delete_icon_theme() {
	echo "解压${BLUE}完成${RESET}，如需${RED}删除${RESET}，请手动输${YELLOW}rm -rf /usr/share/icons/${ICON_NAME} ${RESET}"
}
###################
update_icon_caches_model_02() {
	tar -Jxvf /tmp/.${THEME_NAME}/${THE_LATEST_THEME_VERSION} 2>/dev/null
	cp -rf usr /
	cd /
	rm -rf /tmp/.${THEME_NAME}
	echo "updating icon caches..."
	echo "正在刷新图标缓存..."
	update-icon-caches /usr/share/icons/${ICON_NAME} 2>/dev/null &
	tips_of_delete_icon_theme
}
####################
download_raspbian_pixel_icon_theme() {
	THEME_NAME='raspbian_pixel_icon_theme'
	ICON_NAME='PiX'
	GREP_NAME='all.deb'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/raspberrypi/pool/ui/p/pix-icons/'
	grep_theme_model_01
	update_icon_caches_model_01
	XFCE_ICON_NAME='PiX'
	set_default_xfce_icon_theme
}
################
move_wallpaper_model_01() {
	if [ -e "data.tar.xz" ]; then
		tar -Jxvf data.tar.xz 2>/dev/null
	elif [ -e "data.tar.gz" ]; then
		tar -zxvf data.tar.gz 2>/dev/null
	elif [ -e "data.tar.zst" ]; then
		tar --zstd -xvf data.tar.zst &>/dev/null || zstdcat "data.tar.zst" | tar xvf -
	else
		tar -xvf data.* 2>/dev/null
	fi

	if [ -d "${HOME}/图片" ]; then
		mv ./usr/share/${WALLPAPER_NAME} ${HOME}/图片/${CUSTOM_WALLPAPER_NAME}
	else
		mkdir -p ${HOME}/Pictures/
		mv ./usr/share/${WALLPAPER_NAME} ${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}
	fi
	rm -rf /tmp/.${THEME_NAME}
	echo "${BLUE}壁纸包${RESET}已经保存至${YELLOW}${HOME}/图片/${CUSTOM_WALLPAPER_NAME}${RESET}"
	echo "${BLUE}The wallpaper-pack${RESET} have been saved to ${YELLOW}${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}${RESET}"
}
#################
move_wallpaper_model_02() {
	if [ -d "${HOME}/图片" ]; then
		tar -Jxvf data.tar.xz -C ${HOME}/图片
	else
		mkdir -p ${HOME}/Pictures/
		tar -Jxvf data.tar.xz -C ${HOME}/Pictures/
	fi
	rm -rf /tmp/.${THEME_NAME}
	echo "${BLUE}壁纸包${RESET}已经保存至${YELLOW}${HOME}/图片/${CUSTOM_WALLPAPER_NAME}${RESET}"
	echo "${BLUE}The wallpaper-pack${RESET} have been saved to ${YELLOW}${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}${RESET}"
}
#################
download_raspbian_pixel_wallpaper() {
	THEME_NAME='raspberrypi_pixel_wallpaper'
	WALLPAPER_NAME='pixel-wallpaper'
	CUSTOM_WALLPAPER_NAME='raspberrypi-pixel-wallpapers'
	GREP_NAME='pixel-wallpaper'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/raspberrypi/pool/ui/p/pixel-wallpaper/'
	grep_theme_model_01
	move_wallpaper_model_01
}
########
download_debian_gnome_wallpaper() {
	THEME_NAME='gnome_backgrounds'
	WALLPAPER_NAME='backgrounds/gnome'
	CUSTOM_WALLPAPER_NAME='gnome-backgrounds'
	GREP_NAME='gnome-backgrounds'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/g/gnome-backgrounds/'
	grep_theme_model_01
	move_wallpaper_model_01
}
##############
download_deepin_wallpaper() {
	THEME_NAME='deepin-wallpapers'
	WALLPAPER_NAME='wallpapers/deepin'
	GREP_NAME='deepin-community-wallpapers'
	CUSTOM_WALLPAPER_NAME='deepin-community'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/main/d/deepin-wallpapers/'
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
	mkdir -p /tmp/.${THEME_NAME}
	cd /tmp/.${THEME_NAME}
	echo "${THEME_URL}"
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'data.tar.xz' "${THEME_URL}"
}
############
link_to_debian_wallpaper() {
	if [ -e "/usr/share/backgrounds/kali/" ]; then
		if [ -d "${HOME}/图片" ]; then
			ln -sf /usr/share/backgrounds/kali/ ${HOME}/图片/kali
		else
			mkdir -p ${HOME}/Pictures
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
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/manjaro/pool/overlay/wallpapers-2018-1.2-1-any.pkg.tar.xz'
	WALLPAPER_NAME='backgrounds/wallpapers-2018'
	CUSTOM_WALLPAPER_NAME='manjaro-2018'
	download_manjaro_pkg
	move_wallpaper_model_01
	##############
	THEME_NAME='manjaro-2017'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/manjaro/pool/overlay/manjaro-sx-wallpapers-20171023-1-any.pkg.tar.xz'
	WALLPAPER_NAME='backgrounds'
	CUSTOM_WALLPAPER_NAME='manjaro-2017'
	download_manjaro_pkg
	move_wallpaper_model_01
	##################
}
#########
#non-zst
grep_arch_linux_pkg() {
	ARCH_WALLPAPER_VERSION=$(cat index.html | grep -Ev '.xz.sig|.zst.sig|.pkg.tar.zst' | egrep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	ARCH_WALLPAPER_URL="${THEME_URL}${ARCH_WALLPAPER_VERSION}"
	echo "${ARCH_WALLPAPER_URL}"
	aria2c --allow-overwrite=true -o data.tar.xz -x 5 -s 5 -k 1M ${ARCH_WALLPAPER_URL}
}
################
#grep zst
grep_arch_linux_pkg_02() {
	ARCH_WALLPAPER_VERSION=$(cat index.html | grep '.pkg.tar.zst' | grep -Ev '.xz.sig|.zst.sig' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	ARCH_WALLPAPER_URL="${THEME_URL}${ARCH_WALLPAPER_VERSION}"
	echo "${ARCH_WALLPAPER_URL}"
	aria2c --allow-overwrite=true -o data.tar.zst -x 5 -s 5 -k 1M ${ARCH_WALLPAPER_URL}
}
###################
grep_arch_linux_pkg_03() {
	ARCH_WALLPAPER_VERSION=$(cat index.html | grep '.pkg.tar.zst' | grep -Ev '.xz.sig|.zst.sig' | grep "${GREP_NAME}" | grep -v "${GREP_NAME_V}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	ARCH_WALLPAPER_URL="${THEME_URL}${ARCH_WALLPAPER_VERSION}"
	echo "${YELLOW}${ARCH_WALLPAPER_URL}${RESET}"
	aria2c --allow-overwrite=true -o data.tar.zst -x 5 -s 5 -k 1M ${ARCH_WALLPAPER_URL}
}
#################
download_arch_community_repo_html() {
	THEME_NAME=${GREP_NAME}
	mkdir -p /tmp/.${THEME_NAME}
	cd /tmp/.${THEME_NAME}
	aria2c --allow-overwrite=true -o index.html "${THEME_URL}"
}
##############
download_arch_wallpaper() {
	link_to_debian_wallpaper
	GREP_NAME='archlinux-wallpaper'
	#https://mirrors.tuna.tsinghua.edu.cn/archlinux/pool/community/archlinux-wallpaper-1.4-6-any.pkg.tar.xz
	WALLPAPER_NAME='backgrounds/archlinux'
	CUSTOM_WALLPAPER_NAME='archlinux'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/archlinux/pool/community/'
	check_theme_folder
	download_arch_community_repo_html
	grep_arch_linux_pkg
	move_wallpaper_model_01
}
##############
download_arch_xfce_artwork() {
	if [ ! $(command -v unzstd) ]; then
		echo "${PACKAGES_INSTALL_COMMAND} zstd"
		${PACKAGES_INSTALL_COMMAND} zstd
		echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} zstd"
	fi
	GREP_NAME='xfce4-artwork'
	#https://mirrors.tuna.tsinghua.edu.cn/archlinux/pool/community/archlinux-wallpaper-1.4-6-any.pkg.tar.xz
	WALLPAPER_NAME='backgrounds/xfce'
	CUSTOM_WALLPAPER_NAME='xfce-artwork'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/archlinux/extra/os/x86_64/'
	check_theme_folder
	download_arch_community_repo_html
	grep_arch_linux_pkg_02
	move_wallpaper_model_01
}
########################
download_elementary_wallpaper() {
	#https://mirrors.tuna.tsinghua.edu.cn/archlinux/pool/community/elementary-wallpapers-5.5.0-1-any.pkg.tar.xz
	GREP_NAME='elementary-wallpapers'
	WALLPAPER_NAME='wallpapers/elementary'
	CUSTOM_WALLPAPER_NAME='elementary'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/archlinux/pool/community/'
	check_theme_folder
	download_arch_community_repo_html
	grep_arch_linux_pkg
	move_wallpaper_model_01
	#elementary-wallpapers-5.5.0-1-any.pkg.tar.xz
}
################
download_kali_themes_common() {
	check_update_icon_caches_sh
	THEME_NAME='kali-themes-common'
	GREP_NAME='kali-themes-common'
	ICON_NAME='Flat-Remix-Blue-Dark /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/desktop-base'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes/'
	grep_theme_model_01
	update_icon_caches_model_01
}
####################
download_kali_theme() {
	if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
		download_kali_themes_common
	else
		echo "检测到kali_themes_common已下载，是否重新下载？"
		do_you_want_to_continue
		download_kali_themes_common
	fi
	echo "Download completed.如需删除，请手动输rm -rf /usr/share/desktop-base/kali-theme /usr/share/icons/desktop-base /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/Flat-Remix-Blue-Dark"
	XFCE_ICON_NAME='Flat-Remix-Blue-Light'
	set_default_xfce_icon_theme
}
##################
download_win10x_theme() {
	if [ -d "/usr/share/icons/We10X-dark" ]; then
		echo "检测到图标包已下载，是否重新下载？"
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
	echo ${GITHUB_URL}
	rm -rf /tmp/McWe10X
	echo "Download completed.如需删除，请手动输rm -rf /usr/share/icons/We10X-dark /usr/share/icons/We10X"
	XFCE_ICON_NAME='We10X'
	set_default_xfce_icon_theme
}
###################
download_uos_icon_theme() {
	DEPENDENCY_01="deepin-icon-theme"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install

	if [ -d "/usr/share/icons/Uos" ]; then
		echo "检测到Uos图标包已下载,是否继续？[Y/n]"
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
	echo ${GITHUB_URL}
	rm -rf /tmp/UosICONS
	echo "Download completed.如需删除，请手动输rm -rf /usr/share/icons/Uos ; ${PACKAGES_REMOVE_COMMAND} deepin-icon-theme"
	XFCE_ICON_NAME='Uos'
	set_default_xfce_icon_theme
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
	GITHUB_URL=$(cat url.txt)
	tar -Jxvf 01-Mojave-dark.tar.xz -C /usr/share/themes 2>/dev/null
	tar -Jxvf 01-McMojave-circle.tar.xz -C /usr/share/icons 2>/dev/null
	update-icon-caches /usr/share/icons/McMojave-circle-dark /usr/share/icons/McMojave-circle 2>/dev/null &
	echo ${GITHUB_URL}
	rm -rf /tmp/McMojave
	echo "Download completed.如需删除，请手动输rm -rf /usr/share/themes/Mojave-dark /usr/share/icons/McMojave-circle-dark /usr/share/icons/McMojave-circle"
	XFCE_ICON_NAME='McMojave-circle'
	set_default_xfce_icon_theme
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
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'ukui-themes.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/u/ukui-themes/${UKUITHEME}"
		if [ "${BUSYBOX_AR}" = 'true' ]; then
			busybox ar xv 'ukui-themes.deb'
		else
			ar xv 'ukui-themes.deb'
		fi
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
		echo '请前往外观设置手动修改图标'
	fi
	XFCE_ICON_NAME='ukui-icon-theme'
	set_default_xfce_icon_theme
	#update-icon-caches /usr/share/icons/ukui-icon-theme/ 2>/dev/null
	#echo "安装完成，如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} ukui-themes"
}
#################################
download_arch_breeze_adapta_cursor_theme() {
	mkdir -p /tmp/.breeze_theme
	cd /tmp/.breeze_theme
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/any/'
	curl -Lo index.html ${THEME_URL}
	GREP_NAME='breeze-adapta-cursor-theme-git'
	grep_arch_linux_pkg
	tar -Jxvf data.tar.xz 2>/dev/null
	cp -rf usr /
	rm -rf /tmp/.breeze_theme
}
#############
install_breeze_theme() {
	DEPENDENCY_01="breeze-icon-theme"
	DEPENDENCY_02="breeze-cursor-theme breeze-gtk-theme xfwm4-theme-breeze"
	NON_DEBIAN='false'
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
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/breeze/'
	grep_theme_model_01
	upcompress_deb_file
	#############
	GREP_NAME='all'
	THEME_NAME='chameleon-cursor-theme'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/chameleon-cursor-theme/'
	grep_theme_model_01
	upcompress_deb_file
	##############
	THEME_NAME='moblin-cursor-theme'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/m/moblin-cursor-theme/'
	grep_theme_model_01
	upcompress_deb_file
	##########
}
##########
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
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o kali-undercover.deb "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover/${UNDERCOVERlatestLINK}"
		apt show ./kali-undercover.deb
		apt install -y ./kali-undercover.deb
		if [ ! -e "/usr/share/icons/Windows-10-Icons" ]; then
			THE_LATEST_DEB_FILE='kali-undercover.deb'
			if [ "${BUSYBOX_AR}" = 'true' ]; then
				busybox ar xv ${THE_LATEST_DEB_FILE}
			else
				ar xv ${THE_LATEST_DEB_FILE}
			fi
			cd /
			tar -Jxvf /tmp/.kali-undercover-win10-theme/data.tar.xz ./usr
			#if which gtk-update-icon-cache >/dev/null 2>&1; then
			update-icon-caches /usr/share/icons/Windows-10-Icons 2>/dev/null &
			#fi
		fi
		rm -rf /tmp/.kali-undercover-win10-theme
		#rm -f ./kali-undercover.deb
	fi
	#XFCE_ICON_NAME='Windows 10'
}
#################
check_tmoe_sources_list_backup_file() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		SOURCES_LIST_PATH="/etc/apt/"
		SOURCES_LIST_FILE="/etc/apt/sources.list"
		SOURCES_LIST_FILE_NAME="sources.list"
		SOURCES_LIST_BACKUP_FILE="${HOME}/.config/tmoe-linux/sources.list.bak"
		SOURCES_LIST_BACKUP_FILE_NAME="sources.list.bak"
		EXTRA_SOURCE='debian更换为kali源'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		SOURCES_LIST_PATH="/etc/pacman.d/"
		SOURCES_LIST_FILE="/etc/pacman.d/mirrorlist"
		SOURCES_LIST_FILE_NAME="mirrorlist"
		SOURCES_LIST_BACKUP_FILE="${HOME}/.config/tmoe-linux/pacman.d_mirrorlist.bak"
		SOURCES_LIST_BACKUP_FILE_NAME="pacman.d_mirrorlist.bak"
		EXTRA_SOURCE='archlinux_cn源'
		SOURCES_LIST_FILE_02="/etc/pacman.conf"
		SOURCES_LIST_BACKUP_FILE_02="${HOME}/.config/tmoe-linux/pacman.conf.bak"
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		SOURCES_LIST_PATH="/etc/apk/"
		SOURCES_LIST_FILE="/etc/apk/repositories"
		SOURCES_LIST_FILE_NAME="repositories"
		SOURCES_LIST_BACKUP_FILE="${HOME}/.config/tmoe-linux/alpine_repositories.bak"
		SOURCES_LIST_BACKUP_FILE_NAME="alpine_repositories.bak"
		EXTRA_SOURCE='alpine额外源'
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		SOURCES_LIST_PATH="/etc/yum.repos.d"
		SOURCES_LIST_BACKUP_FILE="${HOME}/.config/tmoe-linux/yum.repos.d-backup.tar.gz"
		SOURCES_LIST_BACKUP_FILE_NAME="yum.repos.d-backup.tar.gz"
		EXTRA_SOURCE='epel源'
	else
		EXTRA_SOURCE='不支持修改${LINUX_DISTRO}源'
	fi

	if [ ! -e "${SOURCES_LIST_BACKUP_FILE}" ]; then
		mkdir -p "${HOME}/.config/tmoe-linux"
		if [ "${LINUX_DISTRO}" = "redhat" ]; then
			tar -Ppzcvf ${SOURCES_LIST_BACKUP_FILE} ${SOURCES_LIST_PATH}
		else
			cp -pf "${SOURCES_LIST_FILE}" "${SOURCES_LIST_BACKUP_FILE}"
		fi
	fi

	if [ "${LINUX_DISTRO}" = "arch" ]; then
		if [ ! -e "${SOURCES_LIST_BACKUP_FILE_02}" ]; then
			cp -pf "${SOURCES_LIST_FILE_02}" "${SOURCES_LIST_BACKUP_FILE_02}"
		fi
	fi
}
##########
modify_alpine_mirror_repositories() {
	ALPINE_VERSION=$(cat /etc/os-release | grep 'PRETTY_NAME=' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | awk -F ' ' '$0=$NF')
	cd /etc/apk/
	if [ ! -z ${ALPINE_VERSION} ]; then
		sed -i 's@http@#&@g' repositories
		cat >>repositories <<-ENDofRepositories
			http://${SOURCE_MIRROR_STATION}/alpine/${ALPINE_VERSION}/main
			http://${SOURCE_MIRROR_STATION}/alpine/${ALPINE_VERSION}/community
		ENDofRepositories
	else
		sed -i "s@^http.*/alpine/@http://${SOURCE_MIRROR_STATION}/alpine/@g" repositories
	fi
	${PACKAGES_UPDATE_COMMAND}
	apk upgrade
}
############################################
auto_check_distro_and_modify_sources_list() {
	if [ ! -z "${SOURCE_MIRROR_STATION}" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			check_debian_distro_and_modify_sources_list
		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			check_arch_distro_and_modify_mirror_list
		elif [ "${LINUX_DISTRO}" = "alpine" ]; then
			modify_alpine_mirror_repositories
		elif [ "${REDHAT_DISTRO}" = "fedora" ]; then
			check_fedora_version
		else
			echo "Sorry,本功能不支持${LINUX_DISTRO}"
		fi
	fi
	################
	press_enter_to_return
}
##############################
china_university_mirror_station() {
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='china_university_mirror_station'
	SOURCES_LIST=$(
		whiptail --title "软件源列表" --menu \
			"您想要切换为哪个镜像源呢？\n目前仅支持debian,ubuntu,kali,arch,manjaro,fedora和alpine" 0 50 0 \
			"1" "清华大学mirrors.tuna.tsinghua.edu.cn" \
			"2" "中国科学技术大学mirrors.ustc.edu.cn" \
			"3" "浙江大学mirrors.zju.edu.cn" \
			"4" "上海交通大学mirrors.zju.edu.cn" \
			"5" "北京外国语大学mirrors.bfsu.edu.cn" \
			"6" "华中科技大学mirrors.hust.edu.cn" \
			"7" "北京理工大学mirror.bit.edu.cn" \
			"8" "北京交通大学mirror.bjtu.edu.cn" \
			"9" "兰州大学mirror.lzu.edu.cn" \
			"10" "大连东软信息学院mirrors.neusoft.edu.cn" \
			"11" "南京大学mirrors.nju.edu.cn" \
			"12" "南京邮电大学mirrors.njupt.edu.cn" \
			"13" "西北农林科技大学mirrors.nwafu.edu.cn" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_sources_list_manager ;;
	1) SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn' ;;
	2) SOURCE_MIRROR_STATION='mirrors.ustc.edu.cn' ;;
	3) SOURCE_MIRROR_STATION='mirrors.zju.edu.cn' ;;
	4) SOURCE_MIRROR_STATION='mirror.sjtu.edu.cn' ;;
	5) SOURCE_MIRROR_STATION='mirrors.bfsu.edu.cn' ;;
	6) SOURCE_MIRROR_STATION='mirrors.hust.edu.cn' ;;
	7) SOURCE_MIRROR_STATION='mirror.bit.edu.cn' ;;
	8) SOURCE_MIRROR_STATION='mirror.bjtu.edu.cn' ;;
	9) SOURCE_MIRROR_STATION='mirror.lzu.edu.cn' ;;
	10) SOURCE_MIRROR_STATION='mirrors.neusoft.edu.cn' ;;
	11) SOURCE_MIRROR_STATION='mirrors.nju.edu.cn' ;;
	12) SOURCE_MIRROR_STATION='mirrors.njupt.edu.cn' ;;
	13) SOURCE_MIRROR_STATION='mirrors.nwafu.edu.cn' ;;
	esac
	######################################
	auto_check_distro_and_modify_sources_list
	##########
	china_university_mirror_station
}
#############
china_bussiness_mirror_station() {
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='china_bussiness_mirror_station'
	SOURCES_LIST=$(
		whiptail --title "软件源列表" --menu \
			"您想要切换为哪个镜像源呢？\n目前仅支持debian,ubuntu,kali,arch,manjaro,fedora和alpine" 0 50 0 \
			"1" "mirrors.huaweicloud.com华为云" \
			"2" "mirrors.cloud.tencent.com腾讯云" \
			"3" "mirrors.aliyun.com阿里云" \
			"4" "mirrors.163.com网易" \
			"5" "mirrors.cnnic.cn中国互联网络信息中心" \
			"6" "mirrors.sohu.com搜狐" \
			"7" "mirrors.yun-idc.com首都在线" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_sources_list_manager ;;
	1) SOURCE_MIRROR_STATION='mirrors.huaweicloud.com' ;;
	2) SOURCE_MIRROR_STATION='mirrors.cloud.tencent.com' ;;
	3) SOURCE_MIRROR_STATION='mirrors.aliyun.com' ;;
	4) SOURCE_MIRROR_STATION='mirrors.163.com' ;;
	5) SOURCE_MIRROR_STATION='mirrors.cnnic.cn' ;;
	6) SOURCE_MIRROR_STATION='mirrors.sohu.com' ;;
	7) SOURCE_MIRROR_STATION='mirrors.yun-idc.com' ;;
	esac
	######################################
	auto_check_distro_and_modify_sources_list
	china_bussiness_mirror_station
}
###########
worldwide_mirror_station() {
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='worldwide_mirror_station'
	DEBIAN_SECURITY_SOURCE='true'
	SOURCES_LIST=$(
		whiptail --title "www.debian.org/mirror/list.html" --menu \
			"Not only debian,but also ubuntu." 0 50 0 \
			"0" "Return to previous menu 返回上级菜单" \
			"00" "official官方:deb.debian.org+archive.ubuntu.com" \
			"01" "Armenia:ftp.am.debian.org" \
			"02" "Australia:ftp.au.debian.org" \
			"03" "Austria:ftp.at.debian.org" \
			"04" "Belarus:ftp.by.debian.org" \
			"05" "Belgium:ftp.be.debian.org" \
			"06" "Brazil:ftp.br.debian.org" \
			"07" "Bulgaria:ftp.bg.debian.org" \
			"08" "Canada:ftp.ca.debian.org" \
			"09" "Chile:ftp.cl.debian.org" \
			"10" "清华:ftp2.cn.debian.org" \
			"11" "中科大:ftp.cn.debian.org" \
			"12" "Croatia:ftp.hr.debian.org" \
			"13" "Czech Republic:ftp.cz.debian.org" \
			"14" "Denmark:ftp.dk.debian.org" \
			"15" "El Salvador:ftp.sv.debian.org" \
			"16" "Estonia:ftp.ee.debian.org" \
			"17" "France:ftp.fr.debian.org" \
			"18" "Germany:ftp2.de.debian.org" \
			"19" "Germany:ftp.de.debian.org" \
			"20" "Greece:ftp.gr.debian.org" \
			"21" "香港:ftp.hk.debian.org" \
			"22" "Hungary:ftp.hu.debian.org" \
			"23" "Italy:ftp.it.debian.org" \
			"24" "地球流体電脳倶楽部:ftp.jp.debian.org" \
			"25" "한국:ftp.kr.debian.org" \
			"26" "Lithuania:ftp.lt.debian.org" \
			"27" "Mexico:ftp.mx.debian.org" \
			"28" "Moldova:ftp.md.debian.org" \
			"29" "Netherlands:ftp.nl.debian.org" \
			"30" "New Caledonia:ftp.nc.debian.org" \
			"31" "New Zealand:ftp.nz.debian.org" \
			"32" "Norway:ftp.no.debian.org" \
			"33" "Poland:ftp.pl.debian.org" \
			"34" "Portugal:ftp.pt.debian.org" \
			"35" "Romania:ftp.ro.debian.org" \
			"36" "Russia:ftp.ru.debian.org" \
			"37" "Slovakia:ftp.sk.debian.org" \
			"38" "Slovenia:ftp.si.debian.org" \
			"39" "Spain:ftp.es.debian.org" \
			"40" "Sweden:ftp.fi.debian.org" \
			"41" "Sweden:ftp.se.debian.org" \
			"42" "Switzerland:ftp.ch.debian.org" \
			"43" "自由軟體實驗室:ftp.tw.debian.org" \
			"44" "Turkey:ftp.tr.debian.org" \
			"45" "United Kingdom:ftp.is.debian.org" \
			"46" "United Kingdom:ftp.uk.debian.org" \
			"47" "United States:ftp.us.debian.org" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_sources_list_manager ;;
	00)
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			SOURCE_MIRROR_STATION='deb.debian.org'
			if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
				SOURCE_MIRROR_STATION='archive.ubuntu.com'
			fi
		fi
		;;
	01) SOURCE_MIRROR_STATION='ftp.am.debian.org' ;;
	02) SOURCE_MIRROR_STATION='ftp.au.debian.org' ;;
	03) SOURCE_MIRROR_STATION='ftp.at.debian.org' ;;
	04) SOURCE_MIRROR_STATION='ftp.by.debian.org' ;;
	05) SOURCE_MIRROR_STATION='ftp.be.debian.org' ;;
	06) SOURCE_MIRROR_STATION='ftp.br.debian.org' ;;
	07) SOURCE_MIRROR_STATION='ftp.bg.debian.org' ;;
	08) SOURCE_MIRROR_STATION='ftp.ca.debian.org' ;;
	09) SOURCE_MIRROR_STATION='ftp.cl.debian.org' ;;
	10) SOURCE_MIRROR_STATION='ftp2.cn.debian.org' ;;
	11) SOURCE_MIRROR_STATION='ftp.cn.debian.org' ;;
	12) SOURCE_MIRROR_STATION='ftp.hr.debian.org' ;;
	13) SOURCE_MIRROR_STATION='ftp.cz.debian.org' ;;
	14) SOURCE_MIRROR_STATION='ftp.dk.debian.org' ;;
	15) SOURCE_MIRROR_STATION='ftp.sv.debian.org' ;;
	16) SOURCE_MIRROR_STATION='ftp.ee.debian.org' ;;
	17) SOURCE_MIRROR_STATION='ftp.fr.debian.org' ;;
	18) SOURCE_MIRROR_STATION='ftp2.de.debian.org' ;;
	19) SOURCE_MIRROR_STATION='ftp.de.debian.org' ;;
	20) SOURCE_MIRROR_STATION='ftp.gr.debian.org' ;;
	21) SOURCE_MIRROR_STATION='ftp.hk.debian.org' ;;
	22) SOURCE_MIRROR_STATION='ftp.hu.debian.org' ;;
	23) SOURCE_MIRROR_STATION='ftp.it.debian.org' ;;
	24) SOURCE_MIRROR_STATION='ftp.jp.debian.org' ;;
	25) SOURCE_MIRROR_STATION='ftp.kr.debian.org' ;;
	26) SOURCE_MIRROR_STATION='ftp.lt.debian.org' ;;
	27) SOURCE_MIRROR_STATION='ftp.mx.debian.org' ;;
	28) SOURCE_MIRROR_STATION='ftp.md.debian.org' ;;
	29) SOURCE_MIRROR_STATION='ftp.nl.debian.org' ;;
	30) SOURCE_MIRROR_STATION='ftp.nc.debian.org' ;;
	31) SOURCE_MIRROR_STATION='ftp.nz.debian.org' ;;
	32) SOURCE_MIRROR_STATION='ftp.no.debian.org' ;;
	33) SOURCE_MIRROR_STATION='ftp.pl.debian.org' ;;
	34) SOURCE_MIRROR_STATION='ftp.pt.debian.org' ;;
	35) SOURCE_MIRROR_STATION='ftp.ro.debian.org' ;;
	36) SOURCE_MIRROR_STATION='ftp.ru.debian.org' ;;
	37) SOURCE_MIRROR_STATION='ftp.sk.debian.org' ;;
	38) SOURCE_MIRROR_STATION='ftp.si.debian.org' ;;
	39) SOURCE_MIRROR_STATION='ftp.es.debian.org' ;;
	40) SOURCE_MIRROR_STATION='ftp.fi.debian.org' ;;
	41) SOURCE_MIRROR_STATION='ftp.se.debian.org' ;;
	42) SOURCE_MIRROR_STATION='ftp.ch.debian.org' ;;
	43) SOURCE_MIRROR_STATION='ftp.tw.debian.org' ;;
	44) SOURCE_MIRROR_STATION='ftp.tr.debian.org' ;;
	45) SOURCE_MIRROR_STATION='ftp.is.debian.org' ;;
	46) SOURCE_MIRROR_STATION='ftp.uk.debian.org' ;;
	47) SOURCE_MIRROR_STATION='ftp.us.debian.org' ;;
	esac
	######################################
	auto_check_distro_and_modify_sources_list
	worldwide_mirror_station
}
#####################################
tmoe_sources_list_manager() {
	DEBIAN_SECURITY_SOURCE='false'
	check_tmoe_sources_list_backup_file
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='tmoe_sources_list_manager'
	SOURCES_LIST=$(
		whiptail --title "software-sources tmoe-manager" --menu \
			"您想要对软件源进行何种管理呢？" 17 50 9 \
			"1" "business:国内商业镜像源" \
			"2" "university:国内高校镜像源" \
			"3" "worldwide mirror sites全球镜像站" \
			"4" "ping(镜像站延迟测试)" \
			"5" "speed(镜像站下载速度测试)" \
			"6" "+ppa:(🍥debian添加ubuntu ppa源)" \
			"7" "restore to default(还原默认源)" \
			"8" "edit list manually(手动编辑)" \
			"9" "${EXTRA_SOURCE}" \
			"10" "FAQ(常见问题)" \
			"11" "http/https" \
			"12" "delete invalid rows(去除无效行)" \
			"13" "trust(强制信任软件源)" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) china_bussiness_mirror_station ;;
    2) china_university_mirror_station ;;
	3) worldwide_mirror_station ;;
	4) ping_mirror_sources_list ;;
	5) mirror_sources_station_download_speed_test ;;
	6) tmoe_debian_add_ubuntu_ppa_source ;;
	7) restore_default_sources_list ;;
	8) edit_sources_list_manually ;;
	9) add_extra_source_list ;;
	10) sources_list_faq ;;
	11) switch_sources_http_and_https ;;
	12) delete_sources_list_invalid_rows ;;
	13) mandatory_trust_software_sources ;;
	esac
	##########
	press_enter_to_return
	tmoe_sources_list_manager
}
######################
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
		echo "请输入有效的名称"
		echo "Please enter a valid name."
	else
		add_ubuntu_ppa_source
	fi
}
####################
add_ubuntu_ppa_source() {
	if [ "$(echo ${TARGET} | grep 'sudo add-apt-repository')" ]; then
		TARGET="$(echo ${TARGET} | sed 's@sudo add-apt-repository@@')"
	elif [ "$(echo ${TARGET} | grep 'add-apt-repository ')" ]; then
		TARGET="$(echo ${TARGET} | sed 's@add-apt-repository @@')"
	fi
	add-apt-repository ${TARGET}
	if [ "$?" != "0" ]; then
		tmoe_sources_list_manager
	fi
	DEV_TEAM_NAME=$(echo ${TARGET} | cut -d '/' -f 1 | cut -d ':' -f 2)
	PPA_SOFTWARE_NAME=$(echo ${TARGET} | cut -d ':' -f 2 | cut -d '/' -f 2)
	if [ "${DEBIAN_DISTRO}" != 'ubuntu' ]; then
		get_ubuntu_ppa_gpg_key
	fi
	modify_ubuntu_sources_list_d_code
	apt update
	echo "添加软件源列表完成，是否需要执行${GREEN}apt install ${PPA_SOFTWARE_NAME}${RESET}"
	do_you_want_to_continue
	apt install ${PPA_SOFTWARE_NAME}
}
###########
get_ubuntu_ppa_gpg_key() {
	DESCRIPTION_PAGE="https://launchpad.net/~${DEV_TEAM_NAME}/+archive/ubuntu/${PPA_SOFTWARE_NAME}"
	cd /tmp
	aria2c --allow-overwrite=true -o .ubuntu_ppa_tmoe_cache ${DESCRIPTION_PAGE}
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
	CURRENT_UBUNTU_CODE=$(cat ${PPA_LIST_FILE} | grep -v '^#' | awk '{print $3}' | head -n 1)
}
#################
modify_ubuntu_sources_list_d_code() {
	check_ubuntu_ppa_list
	if [ "${DEBIAN_DISTRO}" = 'ubuntu' ] || grep -Eq 'sid|testing' /etc/issue; then
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
		echo "您没有修改ubuntu code，当前使用Ubuntu ${TARGET_CODE}的ppa软件源"
	else
		sed -i "s@ ${CURRENT_UBUNTU_CODE}@ ${TARGET_CODE}@g" ${PPA_LIST_FILE}
		echo "已将${CURRENT_UBUNTU_CODE}修改为${TARGET_CODE},若更新错误，则请手动修改$(pwd)/${PPA_LIST_FILE}"
	fi
}
###################
mandatory_trust_software_sources() {
	if (whiptail --title "您想要对这个小可爱做什么 " --yes-button "trust" --no-button "untrust" --yesno "您是想要强制信任还是取消信任呢？\nDo you want to trust sources list?♪(^∇^*) " 0 50); then
		trust_sources_list
	else
		untrust_sources_list
	fi
	${PACKAGES_UPDATE_COMMAND}
}
##############
untrust_sources_list() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		sed -i 's@^deb.*http@deb http@g' /etc/apt/sources.list
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		sed -i 's@SigLevel = Never@#SigLevel = Optional TrustAll@' "/etc/pacman.conf"
	else
		EXTRA_SOURCE='不支持修改${LINUX_DISTRO}源'
	fi
}
#######################
trust_sources_list() {
	echo "执行此操作可能会有未知风险"
	do_you_want_to_continue
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		sed -i 's@^deb.*http@deb [trusted=yes] http@g' /etc/apt/sources.list
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		sed -i 's@^#SigLevel.*@SigLevel = Never@' "/etc/pacman.conf"
	else
		EXTRA_SOURCE='不支持修改${LINUX_DISTRO}源'
	fi
}
#####################
delete_sources_list_invalid_rows() {
	echo "执行此操作将删除软件源列表内的所有注释行,并自动去除重复行"
	do_you_want_to_continue
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		sed -i '/^#/d' ${SOURCES_LIST_FILE}
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		sed -i '/^#Server.*=/d' ${SOURCES_LIST_FILE}
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		sed -i '/^#.*http/d' ${SOURCES_LIST_FILE}
	else
		EXTRA_SOURCE='不支持修改${LINUX_DISTRO}源'
	fi
	sort -u ${SOURCES_LIST_FILE} -o ${SOURCES_LIST_FILE}
	${PACKAGES_UPDATE_COMMAND}
}
###################
sources_list_faq() {
	echo "若换源后更新软件数据库失败，则请切换为http源"
	if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "arch" ]; then
		echo "然后选择强制信任软件源的功能。"
	fi
	echo "若再次出错，则请更换为其它镜像源。"
}
################
switch_sources_list_to_http() {
	if [ "${LINUX_DISTRO}" = "redhat" ]; then
		sed -i 's@https://@http://@g' ${SOURCES_LIST_PATH}/*repo
	else
		sed -i 's@https://@http://@g' ${SOURCES_LIST_FILE}
	fi
}
######################
switch_sources_list_to_http_tls() {
	if [ "${LINUX_DISTRO}" = "redhat" ]; then
		sed -i 's@http://@https://@g' ${SOURCES_LIST_PATH}/*repo
	else
		sed -i 's@http://@https://@g' ${SOURCES_LIST_FILE}
	fi
}
#################
switch_sources_http_and_https() {
	if (whiptail --title "您想要对这个小可爱做什么 " --yes-button "http" --no-button "https" --yesno "您是想要将软件源切换为http还是https呢？♪(^∇^*) " 0 50); then
		switch_sources_list_to_http
	else
		switch_sources_list_to_http_tls
	fi
	${PACKAGES_UPDATE_COMMAND}
}
###################
check_fedora_version() {
	FEDORA_VERSION="$(cat /etc/os-release | grep 'VERSION_ID' | cut -d '=' -f 2)"
	if ((${FEDORA_VERSION} >= 30)); then
		if ((${FEDORA_VERSION} >= 32)); then
			fedora_32_repos
		else
			fedora_31_repos
		fi
		fedora_3x_repos
		#${PACKAGES_UPDATE_COMMAND}
		dnf makecache
	else
		echo "Sorry,不支持fedora29及其以下的版本"
	fi
}
######################
add_extra_source_list() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		modify_to_kali_sources_list
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		add_arch_linux_cn_mirror_list
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		add_fedora_epel_yum_repo
	else
		non_debian_function
	fi
}
################
add_fedora_epel_yum_repo() {
	dnf install -y epel-release || yum install -y epel-release
	cp -pvf /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
	cp -pvf /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
	sed -e 's!^metalink=!#metalink=!g' \
		-e 's!^#baseurl=!baseurl=!g' \
		-e 's!//download\.fedoraproject\.org/pub!//mirrors.tuna.tsinghua.edu.cn!g' \
		-e 's!http://mirrors\.tuna!https://mirrors.tuna!g' \
		-i /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel-testing.repo
}
###############
add_arch_linux_cn_mirror_list() {
	if ! grep -q 'archlinuxcn' /etc/pacman.conf; then
		cat >>/etc/pacman.conf <<-'Endofpacman'
			[archlinuxcn]
			Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
		Endofpacman
		pacman -Syu --noconfirm archlinux-keyring
		pacman -Sy --noconfirm archlinuxcn-keyring
	else
		echo "检测到您已添加archlinux_cn源"
	fi

	if [ ! $(command -v yay) ]; then
		pacman -S --noconfirm yay
		yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
	fi
}
###############
check_debian_distro_and_modify_sources_list() {
	if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
		modify_ubuntu_mirror_sources_list
	elif [ "${DEBIAN_DISTRO}" = "kali" ]; then
		modify_kali_mirror_sources_list
	else
		modify_debian_mirror_sources_list
	fi
	check_ca_certificates_and_apt_update
}
##############
check_arch_distro_and_modify_mirror_list() {
	sed -i 's/^Server/#&/g' /etc/pacman.d/mirrorlist
	if [ "$(cat /etc/issue | cut -c 1-4)" = "Arch" ]; then
		modify_archlinux_mirror_list
	elif [ "$(cat /etc/issue | cut -c 1-7)" = "Manjaro" ]; then
		modify_manjaro_mirror_list
	fi
	#${PACKAGES_UPDATE_COMMAND}
	pacman -Syyu
}
##############
modify_manjaro_mirror_list() {
	if [ "${ARCH_TYPE}" = "arm64" ] || [ "${ARCH_TYPE}" = "armhf" ]; then
		cat >>/etc/pacman.d/mirrorlist <<-EndOfArchMirrors
			#Server = https://${SOURCE_MIRROR_STATION}/archlinuxarm/\$arch/\$repo
			Server = https://${SOURCE_MIRROR_STATION}/manjaro/arm-stable/\$repo/\$arch
		EndOfArchMirrors
	else
		cat >>/etc/pacman.d/mirrorlist <<-EndOfArchMirrors
			#Server = https://${SOURCE_MIRROR_STATION}/archlinux/\$repo/os/\$arch
			Server = https://${SOURCE_MIRROR_STATION}/manjaro/stable/\$repo/\$arch
		EndOfArchMirrors
	fi
}
###############
modify_archlinux_mirror_list() {
	if [ "${ARCH_TYPE}" = "arm64" ] || [ "${ARCH_TYPE}" = "armhf" ]; then
		cat >>/etc/pacman.d/mirrorlist <<-EndOfArchMirrors
			#Server = https://mirror.archlinuxarm.org/\$arch/\$repo
			Server = https://${SOURCE_MIRROR_STATION}/archlinuxarm/\$arch/\$repo
		EndOfArchMirrors
	else
		cat >>/etc/pacman.d/mirrorlist <<-EndOfArchMirrors
			#Server = http://mirrors.kernel.org/archlinux/\$repo/os/\$arch
			Server = https://${SOURCE_MIRROR_STATION}/archlinux/\$repo/os/\$arch
		EndOfArchMirrors
	fi
}
###############
edit_sources_list_manually() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		apt edit-sources || nano ${SOURCES_LIST_FILE}
		#SOURCES_LIST_FILE="/etc/apt/sources.list"
		if [ ! -z "$(ls /etc/apt/sources.list.d/)" ]; then
			nano /etc/apt/sources.list.d/*.list
		fi
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		nano ${SOURCES_LIST_PATH}/*repo
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		nano ${SOURCES_LIST_FILE} /etc/pacman.conf
	else
		nano ${SOURCES_LIST_FILE}
	fi
}
##########
download_debian_ls_lr() {
	echo ${BLUE}${SOURCE_MIRROR_STATION_NAME}${RESET}
	DOWNLOAD_FILE_URL="https://${SOURCE_MIRROR_STATION}/debian/ls-lR.gz"
	echo "${YELLOW}${DOWNLOAD_FILE_URL}${RESET}"
	aria2c --allow-overwrite=true -o ".tmoe_netspeed_test_${SOURCE_MIRROR_STATION_NAME}_temp_file" "${DOWNLOAD_FILE_URL}"
	rm -f ".tmoe_netspeed_test_${SOURCE_MIRROR_STATION_NAME}_temp_file"
	echo "---------------------------"
}
################
mirror_sources_station_download_speed_test() {
	echo "此操作可能会消耗您${YELLOW}数十至上百兆${RESET}的${BLUE}流量${RESET}"
	do_you_want_to_continue
	cd /tmp
	echo "---------------------------"
	SOURCE_MIRROR_STATION_NAME='清华镜像站'
	SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='中科大镜像站'
	SOURCE_MIRROR_STATION='mirrors.ustc.edu.cn'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='上海交大镜像站'
	SOURCE_MIRROR_STATION='mirror.sjtu.edu.cn'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='北外镜像站'
	SOURCE_MIRROR_STATION='mirrors.bfsu.edu.cn'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='华为云镜像站'
	SOURCE_MIRROR_STATION='mirrors.huaweicloud.com'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='阿里云镜像站'
	SOURCE_MIRROR_STATION='mirrors.aliyun.com'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='网易镜像站'
	SOURCE_MIRROR_STATION='mirrors.163.com'
	download_debian_ls_lr
	###此处一定要将SOURCE_MIRROR_STATION赋值为空
	SOURCE_MIRROR_STATION=""
	rm -f .tmoe_netspeed_test_*_temp_file
	echo "测试${YELLOW}完成${RESET}，已自动${RED}清除${RESET}${BLUE}临时文件。${RESET}"
	echo "下载${GREEN}速度快${RESET}并不意味着${BLUE}更新频率高。${RESET}"
	echo "请${YELLOW}自行${RESET}${BLUE}选择${RESET}"
}
######################
ping_mirror_sources_list_count_3() {
	echo ${YELLOW}${SOURCE_MIRROR_STATION}${RESET}
	echo ${BLUE}${SOURCE_MIRROR_STATION_NAME}${RESET}
	ping ${SOURCE_MIRROR_STATION} -c 3 | grep -E 'avg|time.*ms' --color=auto
	echo "---------------------------"
}
##############
ping_mirror_sources_list() {
	echo "时间越短，延迟越低"
	echo "---------------------------"
	SOURCE_MIRROR_STATION_NAME='清华镜像站'
	SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='中科大镜像站'
	SOURCE_MIRROR_STATION='mirrors.ustc.edu.cn'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='上海交大镜像站'
	SOURCE_MIRROR_STATION='mirror.sjtu.edu.cn'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='华为云镜像站'
	SOURCE_MIRROR_STATION='mirrors.huaweicloud.com'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='阿里云镜像站'
	SOURCE_MIRROR_STATION='mirrors.aliyun.com'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='网易镜像站'
	SOURCE_MIRROR_STATION='mirrors.163.com'
	ping_mirror_sources_list_count_3
	###此处一定要将SOURCE_MIRROR_STATION赋值为空
	SOURCE_MIRROR_STATION=""
	echo "测试${YELLOW}完成${RESET}"
	echo "延迟${GREEN}时间低${RESET}并不意味着${BLUE}下载速度快。${RESET}"
	echo "请${YELLOW}自行${RESET}${BLUE}选择${RESET}"
}
##############
modify_kali_mirror_sources_list() {
	echo "检测到您使用的是Kali系统"
	sed -i 's/^deb/# &/g' /etc/apt/sources.list
	cat >>/etc/apt/sources.list <<-EndOfSourcesList
		deb http://${SOURCE_MIRROR_STATION}/kali/ kali-rolling main contrib non-free
		deb http://${SOURCE_MIRROR_STATION}/debian/ stable main contrib non-free
		# deb http://${SOURCE_MIRROR_STATION}/kali/ kali-last-snapshot main contrib non-free
	EndOfSourcesList
	#注意：kali-rolling添加debian testing源后，可能会破坏系统依赖关系，可以添加stable源（暂未发现严重影响）
}
#############
check_ca_certificates_and_apt_update() {
	if [ "${DEBIAN_SECURITY_SOURCE}" != "true" ]; then
	  if [ -e "/usr/sbin/update-ca-certificates" ]; then
		echo "检测到您已安装ca-certificates"
		echo "Replacing http software source list with https."
		echo "正在将http源替换为https..."
		#update-ca-certificates
		sed -i 's@http:@https:@g' /etc/apt/sources.list
		sed -i 's@https://security@http://security@g' /etc/apt/sources.list
	  fi
	fi
	apt update
	apt dist-upgrade
	echo "修改完成，您当前的${BLUE}软件源列表${RESET}如下所示。"
	cat /etc/apt/sources.list
	cat /etc/apt/sources.list.d/* 2>/dev/null
	echo "您可以输${YELLOW}apt edit-sources${RESET}来手动编辑软件源列表"
}
#############
modify_ubuntu_mirror_sources_list() {
	if grep -q 'Bionic Beaver' "/etc/os-release"; then
		SOURCELISTCODE='bionic'
		echo '18.04 LTS'
	elif grep -q 'Focal Fossa' "/etc/os-release"; then
		SOURCELISTCODE='focal'
		echo '20.04 LTS'
	elif grep -q 'Xenial' "/etc/os-release"; then
		SOURCELISTCODE='xenial'
		echo '16.04 LTS'
	elif grep -q 'Cosmic' "/etc/os-release"; then
		SOURCELISTCODE='cosmic'
		echo '18.10'
	elif grep -q 'Disco' "/etc/os-release"; then
		SOURCELISTCODE='disco'
		echo '19.04'
	elif grep -q 'Eoan' "/etc/os-release"; then
		SOURCELISTCODE='eoan'
		echo '19.10'
	else
		SOURCELISTCODE=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d '=' -f 2 | head -n 1)
		echo $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f 2 | cut -d '"' -f 2 | head -n 1)
	fi
	echo "检测到您使用的是Ubuntu ${SOURCELISTCODE}系统"
	sed -i 's/^deb/# &/g' /etc/apt/sources.list
	#下面那行EndOfSourcesList不能有单引号
	cat >>/etc/apt/sources.list <<-EndOfSourcesList
		deb http://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE} main restricted universe multiverse
		deb http://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE}-updates main restricted universe multiverse
		deb http://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE}-backports main restricted universe multiverse
		deb http://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE}-security main restricted universe multiverse
		# proposed为预发布软件源，不建议启用
		# deb https://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE}-proposed main restricted universe multiverse
	EndOfSourcesList
	if [ "${ARCH_TYPE}" != 'amd64' ] && [ "${ARCH_TYPE}" != 'i386' ]; then
		sed -i 's:/ubuntu:/ubuntu-ports:g' /etc/apt/sources.list
	fi
}
#############
modify_debian_mirror_sources_list() {
	NEW_DEBIAN_SOURCES_LIST='false'
	if [ ! "$(command -v lsb_release)" ];then
	    echo 'apt install lsb-release'
	    apt install lsb-release
	fi
    if [ "$(lsb_release -rs | cut -d '/' -f 1)" = 'testing' ];then
        NEW_DEBIAN_SOURCES_LIST='true'
		SOURCELISTCODE='testing'
		BACKPORTCODE=$(cat /etc/os-release | grep PRETTY_NAME | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | awk -F ' ' '$0=$NF' | cut -d '/' -f 1)
	elif grep -q '^PRETTY_NAME.*sid' "/etc/os-release"; then
		SOURCELISTCODE='sid'

	elif ! grep -Eq 'buster|stretch|jessie' "/etc/os-release"; then
	       NEW_DEBIAN_SOURCES_LIST='true'
		if grep -q 'VERSION_CODENAME' "/etc/os-release"; then
			SOURCELISTCODE=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d '=' -f 2 | head -n 1)
		else
			echo "不支持您的系统！"
			press_enter_to_return
			tmoe_sources_list_manager
		fi
		BACKPORTCODE=${SOURCELISTCODE}

	elif grep -q 'buster' "/etc/os-release"; then
		SOURCELISTCODE='buster'
		BACKPORTCODE='buster'
		#echo "Debian 10 buster"

	elif grep -q 'stretch' "/etc/os-release"; then
		SOURCELISTCODE='stretch'
		BACKPORTCODE='stretch'
		#echo "Debian 9 stretch"

	elif grep -q 'jessie' "/etc/os-release"; then
		SOURCELISTCODE='jessie'
		BACKPORTCODE='jessie'
		#echo "Debian 8 jessie"
	fi
	echo $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f 2 | cut -d '"' -f 2 | head -n 1)
	echo "检测到您使用的是Debian ${SOURCELISTCODE}系统"
	sed -i 's/^deb/# &/g' /etc/apt/sources.list
	if [ "${SOURCELISTCODE}" = "sid" ]; then
		cat >>/etc/apt/sources.list <<-EndOfSourcesList
			deb http://${SOURCE_MIRROR_STATION}/debian/ sid main contrib non-free
			#deb http://${SOURCE_MIRROR_STATION}/debian/ experimental main contrib non-free
		EndOfSourcesList
	else
		if [ "${NEW_DEBIAN_SOURCES_LIST}" = "true" ]; then
			cat >>/etc/apt/sources.list <<-EndOfSourcesList
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${SOURCELISTCODE} main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${SOURCELISTCODE}-updates main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${BACKPORTCODE}-backports main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian-security/ ${SOURCELISTCODE}-security main contrib non-free
			EndOfSourcesList
			if [ "${DEBIAN_SECURITY_SOURCE}" = "true" ]; then
				sed -i 's@^deb.*debian-security@#&@' /etc/apt/sources.list
				cat >>/etc/apt/sources.list <<-EndOfsecuritySource
					deb http://security.debian.org/debian-security/ ${SOURCELISTCODE}-security main contrib non-free
				EndOfsecuritySource
			fi
		else
			#下面那行EndOfSourcesList不能加单引号
			cat >>/etc/apt/sources.list <<-EndOfSourcesList
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${SOURCELISTCODE} main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${SOURCELISTCODE}-updates main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${BACKPORTCODE}-backports main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian-security/ ${SOURCELISTCODE}/updates main contrib non-free
			EndOfSourcesList
			if [ "${DEBIAN_SECURITY_SOURCE}" = "true" ]; then
				sed -i 's@^deb.*debian-security@#&@' /etc/apt/sources.list
				cat >>/etc/apt/sources.list <<-EndOfsecuritySource
                deb http://security.debian.org/debian-security/ ${SOURCELISTCODE}/updates main contrib non-free
				EndOfsecuritySource
			fi
		fi
	fi
}
##############
restore_normal_default_sources_list() {
	if [ -e "${SOURCES_LIST_BACKUP_FILE}" ]; then
		cd ${SOURCES_LIST_PATH}
		cp -pvf ${SOURCES_LIST_FILE_NAME} ${SOURCES_LIST_BACKUP_FILE_NAME}
		cp -pf ${SOURCES_LIST_BACKUP_FILE} ${SOURCES_LIST_FILE}
		${PACKAGES_UPDATE_COMMAND}
		echo "您当前的软件源列表已经备份至${YELLOW}$(pwd)/${SOURCES_LIST_BACKUP_FILE_NAME}${RESET}"
		diff ${SOURCES_LIST_BACKUP_FILE_NAME} ${SOURCES_LIST_FILE_NAME} -y --color
		echo "${YELLOW}左侧${RESET}显示的是${RED}旧源${RESET}，${YELLOW}右侧${RESET}为${GREEN}当前的${RESET}${BLUE}软件源${RESET}"
	else
		echo "检测到备份文件不存在，还原失败。"
	fi
	###################
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		if [ -e "${SOURCES_LIST_BACKUP_FILE_02}" ]; then
			cp -pf "${SOURCES_LIST_BACKUP_FILE_02}" "${SOURCES_LIST_FILE_02}"
		fi
	fi
}
########
restore_default_sources_list() {
	if [ ! $(command -v diff) ]; then
		NON_DEBIAN='false'
		DEPENDENCY_01=""
		DEPENDENCY_02="diffutils"
		beta_features_quick_install
	fi

	if [ "${LINUX_DISTRO}" = "redhat" ]; then
		tar -Ppzxvf ${SOURCES_LIST_BACKUP_FILE}
	else
		restore_normal_default_sources_list
	fi
}
#############
fedora_31_repos() {
	curl -o /etc/yum.repos.d/fedora.repo http://${SOURCE_MIRROR_STATION}/repo/fedora.repo
	curl -o /etc/yum.repos.d/fedora-updates.repo http://${SOURCE_MIRROR_STATION}/repo/fedora-updates.repo
}
###########
#fedora清华源mirrors.tuna.tsinghua.edu.cn/fedora/releases/
fedora_32_repos() {
	cat >/etc/yum.repos.d/fedora.repo <<-EndOfYumRepo
		[fedora]
		name=Fedora \$releasever - \$basearch
		failovermethod=priority
		baseurl=https://${SOURCE_MIRROR_STATION}/fedora/releases/\$releasever/Everything/\$basearch/os/
		metadata_expire=28d
		gpgcheck=1
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
		skip_if_unavailable=False
	EndOfYumRepo

	cat >/etc/yum.repos.d/fedora-updates.repo <<-EndOfYumRepo
		[updates]
		name=Fedora \$releasever - \$basearch - Updates
		failovermethod=priority
		baseurl=https://${SOURCE_MIRROR_STATION}/fedora/updates/\$releasever/Everything/\$basearch/
		enabled=1
		gpgcheck=1
		metadata_expire=6h
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
		skip_if_unavailable=False
	EndOfYumRepo
}
#########################
fedora_3x_repos() {
	cat >/etc/yum.repos.d/fedora-modular.repo <<-EndOfYumRepo
		[fedora-modular]
		name=Fedora Modular \$releasever - \$basearch
		failovermethod=priority
		baseurl=https://${SOURCE_MIRROR_STATION}/fedora/releases/\$releasever/Modular/\$basearch/os/
		enabled=1
		metadata_expire=7d
		gpgcheck=1
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
		skip_if_unavailable=False
	EndOfYumRepo

	cat >/etc/yum.repos.d/fedora-updates-modular.repo <<-EndOfYumRepo
		[updates-modular]
		name=Fedora Modular \$releasever - \$basearch - Updates
		failovermethod=priority
		baseurl=https://${SOURCE_MIRROR_STATION}/fedora/updates/\$releasever/Modular/\$basearch/
		enabled=1
		gpgcheck=1
		metadata_expire=6h
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
		skip_if_unavailable=False
	EndOfYumRepo
}
###############
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
add_debian_opt_gpg_key() {
	cd /tmp
	curl -Lv -o bintray-public.key.asc 'https://bintray.com/user/downloadSubjectPublicKey?username=bintray'
	apt-key add bintray-public.key.asc
	echo -e "deb https://bintray.proxy.ustclug.org/debianopt/debianopt/ buster main\n#deb https://dl.bintray.com/debianopt/debianopt buster main" >/etc/apt/sources.list.d/debianopt.list
	apt update
}
###########
add_debian_opt_repo() {
	echo "检测到您未添加debian_opt软件源，是否添加？"
	echo "debian_opt_repo列表的所有软件均来自于开源项目"
	echo "感谢https://github.com/coslyk/debianopt-repo 仓库的维护者，以及各个项目的原开发者。"
	RETURN_TO_WHERE='other_software'
	do_you_want_to_continue
	add_debian_opt_gpg_key
}
###################
debian_install_electron() {
	if [ "${LINUX_DISTRO}" = "debian" ] && [ ! $(command -v electron) ]; then
		OPT_REPO='/etc/apt/sources.list.d/debianopt.list'
		if [ ! -e "${OPT_REPO}" ]; then
			add_debian_opt_gpg_key
		fi
		cat <<-EOF
			即将为您安装electron
			apt install -y electron
			如需卸载，请手动执行apt purge electron
		EOF
		apt install -y electron
	fi
}
##############
switch_debian_opt_repo_sources() {
	OPT_REPO='/etc/apt/sources.list.d/debianopt.list'
	if grep '^deb.*ustc' ${OPT_REPO}; then
		OPT_REPO_NAME='USTC'
	else
		OPT_REPO_NAME='bintray'
	fi
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "USTC" --no-button "bintray" --yesno "检测到您当前的软件源为${OPT_REPO_NAME}\n您想要切换为哪个软件源?♪(^∇^*) " 10 50); then
		#sed -i 's@^#deb@deb@' ${OPT_REPO}
		#sed -i 's@^deb.*bintray@#&@' ${OPT_REPO}
		echo -e "deb https://bintray.proxy.ustclug.org/debianopt/debianopt/ buster main\n#deb https://dl.bintray.com/debianopt/debianopt buster main" >${OPT_REPO}
	else
		echo -e "#deb https://bintray.proxy.ustclug.org/debianopt/debianopt/ buster main\ndeb https://dl.bintray.com/debianopt/debianopt buster main" >${OPT_REPO}
	fi
	apt update
}
#######################
explore_debian_opt_repo() {
	if [ ! $(command -v gpg) ]; then
		DEPENDENCY_01=""
		DEPENDENCY_02="gpg"
		beta_features_quick_install
	fi
	DEPENDENCY_02=""

	if [ ! -e "/etc/apt/sources.list.d/debianopt.list" ]; then
		add_debian_opt_repo
	fi

	NON_DEBIAN='true'
	RETURN_TO_WHERE='explore_debian_opt_repo'
	cd /usr/share/applications/
	INSTALL_APP=$(whiptail --title "DEBIAN OPT REPO" --menu \
		"您想要安装哪个软件？按方向键选择，回车键确认！\n Which software do you want to install? " 16 50 7 \
		"1" "listen1(免费音乐聚合)" \
		"2" "electron-netease-cloud-music(云音乐客户端)" \
		"3" "lx-music-desktop(洛雪音乐助手)" \
		"4" "iease-music(界面华丽的云音乐客户端)" \
		"5" "cocomusic(第三方QQ音乐客户端)" \
		"6" "feeluown(x64,支持网易云、虾米)" \
		"7" "netease-cloud-music-gtk(x64,云音乐)" \
		"8" "picgo(图床上传工具)" \
		"9" "other:其他软件" \
		"10" "remove(移除本仓库)" \
		"11" "switch source repo:切换软件源仓库" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##############
	case "${INSTALL_APP}" in
	0 | "") tmoe_multimedia_menu ;;
	1) install_listen1 ;;
	2) install_electron_netease_cloud_music ;;
	3) install_lx_music_desktop ;;
	4) install_iease_music ;;
	5) install_coco_music ;;
	6) install_feeluown ;;
	7) install_netease_cloud_music_gtk ;;
	8) install_pic_go ;;
	9) apt_list_debian_opt ;;
	10) remove_debian_opt_repo ;;
	11) switch_debian_opt_repo_sources ;;
	esac
	##########################
	press_enter_to_return
	explore_debian_opt_repo
}
################
debian_opt_quick_install() {
	beta_features_quick_install
	do_you_want_to_close_the_sandbox_mode
	RETURN_TO_WHERE='explore_debian_opt_repo'
	do_you_want_to_continue
}
############
with_no_sandbox_model_01() {
	sed -i "s+${DEPENDENCY_01} %U+${DEPENDENCY_01} --no-sandbox %U+" ${DEPENDENCY_01}.desktop
}
########
with_no_sandbox_model_02() {
	if ! grep 'sandbox' "${DEPENDENCY_01}.desktop"; then
		sed -i "s@/usr/bin/${DEPENDENCY_01}@& --no-sandbox@" ${DEPENDENCY_01}.desktop
	fi
}
##################
remove_debian_opt_repo() {
	rm -vf /etc/apt/sources.list.d/debianopt.list
	apt update
}
##########
apt_list_debian_opt() {
	apt list | grep '~buster'
	echo "请使用apt install 软件包名称 来安装"
}
#############
install_coco_music() {
	DEPENDENCY_01='cocomusic'
	echo "github url：https://github.com/xtuJSer/CoCoMusic"
	debian_opt_quick_install
	#sed -i 's+cocomusic %U+electron /opt/CocoMusic --no-sandbox "$@"+' /usr/share/applications/cocomusic.desktop
	with_no_sandbox_model_01
}
#####################
install_iease_music() {
	DEPENDENCY_01='iease-music'
	echo "github url：https://github.com/trazyn/ieaseMusic"
	debian_opt_quick_install
	with_no_sandbox_model_02
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
proot_warning() {
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
		echo "在当前环境下，安装后可能无法正常运行。"
		RETURN_TO_WHERE='explore_debian_opt_repo'
		do_you_want_to_continue
	fi
}
################
install_electron_netease_cloud_music() {
	DEPENDENCY_01='electron-netease-cloud-music'
	echo "github url：https://github.com/Rocket1184/electron-netease-cloud-music"
	beta_features_quick_install
	FILE_SIZE=$(du -s /opt/electron-netease-cloud-music/app.asar | awk '{print $1}')
	if ((${FILE_SIZE} < 3000)); then
		patch_electron_netease_cloud_music
	fi
	do_you_want_to_close_the_sandbox_mode
	do_you_want_to_continue
	#with_no_sandbox_model_02
	if ! grep -q 'sandbox' "$(command -v electron-netease-cloud-music)"; then
		sed -i 's@exec electron /opt/electron-netease-cloud-music/app.asar@& --no-sandbox@' $(command -v electron-netease-cloud-music)
	fi
}
########################
install_listen1() {
	DEPENDENCY_01='listen1'
	echo "github url：http://listen1.github.io/listen1/"
	debian_opt_quick_install
	#sed -i 's+listen1 %U+listen1 --no-sandbox %U+' listen1.desktop
	with_no_sandbox_model_01
}
################
install_lx_music_desktop() {
	DEPENDENCY_01='lx-music-desktop'
	echo "github url：https://github.com/lyswhut/lx-music-desktop"
	debian_opt_quick_install
	#sed -i 's+lx-music-desktop %U+lx-music-desktop --no-sandbox %U+' lx-music-desktop.desktop
	with_no_sandbox_model_01
}
####################
install_feeluown() {
	DEPENDENCY_01='feeluown'
	echo "url：https://feeluown.readthedocs.io/en/latest/"
	beta_features_quick_install
	if [ ! $(command -v feeluown-launcher) ]; then
		arch_does_not_support
	fi
}
###########
install_netease_cloud_music_gtk() {
	DEPENDENCY_01='netease-cloud-music-gtk'
	echo "github url：https://github.com/gmg137/netease-cloud-music-gtk"
	beta_features_quick_install
	if [ ! $(command -v netease-cloud-music-gtk) ]; then
		arch_does_not_support
	fi
}
###############
install_pic_go() {
	DEPENDENCY_01='picgo'
	echo "github url：https://github.com/Molunerfinn/PicGo"
	debian_opt_quick_install
	#sed -i 's+picgo %U+picgo --no-sandbox %U+' picgo.desktop
	with_no_sandbox_model_01
}
############################################
############################################
other_software() {
	RETURN_TO_WHERE='other_software'
	SOFTWARE=$(
		whiptail --title "Software center-01" --menu \
			"您想要安装哪个软件？\n Which software do you want to install?" 0 50 0 \
			"1" "🦊Browser:浏览器(firefox,chromium)" \
			"2" "🎵Multimedia:图像与影音(mpv,云音乐)" \
			"3" "🐧SNS:社交类(qq)" \
			"4" "🎮Games:游戏(steam,wesnoth)" \
			"5" "🔯Packages&system:软件包与系统管理" \
			"6" "📚Documents:文档(libreoffice)" \
			"7" "📘VSCode 现代化代码编辑器" \
			"8" "🎁Download:下载类(aria2,baidu)" \
			"9" "🥙Start zsh tool:启动zsh管理工具" \
			"10" "🌚remove:卸载管理" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	#(已移除)"12" "Tasksel:轻松,快速地安装组软件" \
	case "${SOFTWARE}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) install_browser ;;
	2) tmoe_multimedia_menu ;;
	3) tmoe_social_network_service ;;
	4) tmoe_games_menu ;;
	5) tmoe_software_package_menu ;;
	6) tmoe_documents_menu ;;
	7) which_vscode_edition ;;
	8) tmoe_download_class ;;
	9) bash -c "$(curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh')" ;;
	10) tmoe_other_options_menu ;;
	esac
	############################################
	press_enter_to_return
	other_software
}
###########
tmoe_software_package_menu() {
	RETURN_TO_WHERE='tmoe_software_package_menu'
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	TMOE_APP=$(
		whiptail --title "PACKAGES MANAGER" --menu \
			"How do you want to manage software package?" 0 50 0 \
			"1" "Tmoe-deb-installer:软件包安装器" \
			"2" "Synaptic(新立得软件包管理器)" \
			"3" "ADB(Android Debug Bridge,用于调试安卓)" \
			"4" "BleachBit(垃圾清理)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##########################
	case "${TMOE_APP}" in
	0 | "") other_software ;;
	1) tmoe_deb_file_installer ;;
	2) install_package_manager_gui ;;
	3) install_android_debug_bridge ;;
	4) install_bleachbit_cleaner ;;
	esac
	##########################
	press_enter_to_return
	tmoe_software_package_menu
}
#############
tmoe_social_network_service() {
	RETURN_TO_WHERE='tmoe_social_network_service'
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	TMOE_APP=$(
		whiptail --title "SNS" --menu \
			"Which software do you want to install?" 0 50 0 \
			"1" "LinuxQQ(在线聊天软件)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##########################
	case "${TMOE_APP}" in
	0 | "") other_software ;;
	1) install_linux_qq ;;
	esac
	##########################
	press_enter_to_return
	tmoe_social_network_service
}
###################
tmoe_download_class() {
	RETURN_TO_WHERE='tmoe_download_class'
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	TMOE_APP=$(
		whiptail --title "documents" --menu \
			"Which software do you want to install?" 0 50 0 \
			"1" "🍨aria2(linux平台超强文件下载器)" \
			"2" "🖼work_crawler:漫畫、小説下載工具@kanasimi" \
			"3" "📉百度网盘(x64,提供文件的网络备份,同步和分享服务)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##########################
	case "${TMOE_APP}" in
	0 | "") other_software ;;
	1) tmoe_aria2_manager ;;
	2) start_kanasimi_work_crawler ;;
	3) install_baidu_netdisk ;;
	esac
	##########################
	press_enter_to_return
	tmoe_download_class
}
####################
start_kanasimi_work_crawler() {
	RETURN_TO_WHERE='check_kanasimi_work_crawler'
	install_nodejs
	check_kanasimi_work_crawler
}
###############
install_nodejs() {
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	DEPENDENCY_02=""
	if [ ! $(command -v 7za) ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01="p7zip-full"
		else
			DEPENDENCY_01="p7zip"
		fi
	fi
	if [ ! $(command -v node) ]; then
		DEPENDENCY_02="nodejs"
	fi
	if [ ! -z "${DEPENDENCY_01}" ] || [ ! -z "${DEPENDENCY_02}" ]; then
		beta_features_quick_install
	fi

	if [ ! $(command -v npm) ]; then
		bash -c "$(curl -Lv https://npmjs.org/install.sh | sed 's@registry.npmjs.org@registry.npm.taobao.org@g')"
		cat <<-'EOF'
			npm config set registry https://registry.npm.taobao.org
			npm config set disturl https://npm.taobao.org/dist
			npm config set electron_mirror https://npm.taobao.org/mirrors/electron/
		EOF
		echo "${YELLOW}是否需要将npm官方源更换为淘宝源[Y/n]${RESET} "
		echo "更换后可以加快国内的下载速度,${YELLOW}按回车键确认，输n拒绝。${RESET}"
		echo "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .[Y/n]"
		do_you_want_to_continue
		npm config set registry https://registry.npm.taobao.org
		npm config set disturl https://npm.taobao.org/dist
		npm config set electron_mirror https://npm.taobao.org/mirrors/electron/
	fi
}
############
download_kanasimi_work_crawler() {
	cd /usr/local/bin/
	aria2c --allow-overwrite=true -o work-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool/work_crawler@kanasimi.sh'
	chmod +x work-i
}
############
check_kanasimi_work_crawler() {
	cd /usr/local/bin/
	if [ -e "work-i" ]; then
		FILE_SIZE=$(du -s work-i | awk '{print $1}')
		if ((${FILE_SIZE} < 10)); then
			download_kanasimi_work_crawler
		fi
	fi

	if [ ! "$(command -v work-i)" ]; then
		download_kanasimi_work_crawler
	fi
	bash work-i
}
####################
download_tmoe_aria2() {
	cd /usr/local/bin/
	aria2c --allow-overwrite=true -o aria2-i https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool/aria2.sh
	chmod +x aria2-i
}
############
tmoe_aria2_manager() {
	cd /usr/local/bin/
	if [ -e "aria2-i" ]; then
		FILE_SIZE=$(du -s aria2-i | awk '{print $1}')
		if ((${FILE_SIZE} < 50)); then
			download_tmoe_aria2
		fi
	fi

	if [ ! "$(command -v aria2-i)" ]; then
		download_tmoe_aria2
	fi
	bash aria2-i
}
#############
tmoe_documents_menu() {
	RETURN_TO_WHERE='tmoe_documents_menu'
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	TMOE_APP=$(
		whiptail --title "documents" --menu \
			"Which software do you want to install?" 0 50 0 \
			"1" "LibreOffice(开源、自由的办公文档软件)" \
			"2" "Chinese manual(中文手册)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##########################
	case "${TMOE_APP}" in
	0 | "") other_software ;;
	1) install_libre_office ;;
	2) install_chinese_manpages ;;
	esac
	##########################
	press_enter_to_return
	tmoe_documents_menu
}
####################
tmoe_multimedia_menu() {
	RETURN_TO_WHERE='tmoe_multimedia_menu'
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	TMOE_APP=$(whiptail --title "Picture&Video&Music" --menu \
		"Which software do you want to install?" 0 50 0 \
		"1" "Music:debian-opt仓库(QQ音乐,云音乐)" \
		"2" "MPV(开源、跨平台的音视频播放器)" \
		"3" "GIMP(GNU 图像处理程序)" \
		"4" "Parole(xfce默认媒体播放器,风格简洁)" \
		"5" "网易云音乐(x86_64,专注于发现与分享的音乐产品)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") other_software ;;
	1)
		non_debian_function
		explore_debian_opt_repo
		;;
	2) install_mpv ;;
	3) install_gimp ;;
	4) install_parole ;;
	5) install_netease_163_cloud_music ;;
	esac
	##########################
	press_enter_to_return
	tmoe_multimedia_menu
}
#############
tmoe_games_menu() {
	RETURN_TO_WHERE='tmoe_games_menu'
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	TMOE_APP=$(whiptail --title "GAMES" --menu \
		"Which game do you want to install?" 0 50 0 \
		"1" "install Steam-x86_64(安装蒸汽游戏平台)" \
		"2" "remove Steam(卸载)" \
		"3" "cataclysm大灾变-劫后余生(末日幻想背景的探索生存游戏)" \
		"4" "mayomonogatari斯隆与马克贝尔的谜之物语(nds解谜游戏)" \
		"5" "wesnoth韦诺之战(奇幻背景的回合制策略战棋游戏)" \
		"6" "SuperTuxKart(3D卡丁车)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") other_software ;;
	1) install_steam_app ;;
	2) remove_steam_app ;;
	3) install_game_cataclysm ;;
	4) install_nds_game_mayomonogatari ;;
	5) install_wesnoth_game ;;
	6) install_supertuxkart_game ;;
	esac
	##########################
	press_enter_to_return
	tmoe_games_menu
}
#############
remove_debian_steam_app() {
	if [ "${ARCH_TYPE}" != "i386" ]; then
		echo 'dpkg  --remove-architecture i386'
		echo '正在移除对i386软件包的支持'
		#apt purge ".*:i386"
		aptitude remove ~i~ri386
		dpkg --remove-architecture i386
		apt update
	fi
}
###############
remove_steam_app() {
	echo "${PACKAGES_REMOVE_COMMAND} steam-launcher steam"
	${PACKAGES_REMOVE_COMMAND} steam-launcher steam
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		remove_debian_steam_app
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		#remove_fedora_steam_app
		rm -fv /etc/yum.repos.d/steam.repo
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		remove_arch_steam_app
	fi
}
###############
install_debian_steam_app() {
	LATEST_DEB_REPO='https://mirrors.tuna.tsinghua.edu.cn/steamos/steam/pool/steam/s/steam/'
	GREP_NAME='steam-launcher'
	cd /tmp
	download_tuna_repo_deb_file_all_arch
	dpkg --add-architecture i386
	apt update
	apt install ./${LATEST_DEB_VERSION}
	rm -fv ./${LATEST_DEB_VERSION}
	beta_features_install_completed
}
#################
install_fedora_steam_app() {
	cat >/etc/yum.repos.d/steam.repo <<-'ENDOFFEDORASTEAM'
		[steam]
		name=Steam RPM packages (and dependencies) for Fedora
		baseurl=http://spot.fedorapeople.org/steam/fedora-$releasever/
		enabled=1
		skip_if_unavailable=1
		gpgcheck=0
	ENDOFFEDORASTEAM
}
####################
check_arch_multi_lib_line() {
	cd /etc
	ARCH_MULTI_LIB_LINE=$(cat pacman.conf | grep '\[multilib\]' -n | cut -d ':' -f 1 | tail -n 1)
	ARCH_MULTI_LIB_INCLUDE_LINE=$((${ARCH_MULTI_LIB_LINE} + 1))
}
#################
install_arch_steam_app() {
	check_arch_multi_lib_line
	echo "正在修改/etc/pacman.conf中第${ARCH_MULTI_LIB_LINE}行中的multilib"
	sed -i "${ARCH_MULTI_LIB_LINE}c\[multilib]" pacman.conf
	sed -i "${ARCH_MULTI_LIB_INCLUDE_LINE}c\Include = /etc/pacman.d/mirrorlist" pacman.conf
}
#################
remove_arch_steam_app() {
	check_arch_multi_lib_line
	echo "正在注释掉/etc/pacman.conf中第${ARCH_MULTI_LIB_LINE}行中的multilib"
	sed -i "${ARCH_MULTI_LIB_LINE}c\#[multilib]" pacman.conf
	sed -i "${ARCH_MULTI_LIB_INCLUDE_LINE}c\#Include = /etc/pacman.d/mirrorlist" pacman.conf
}
################
install_steam_app() {
	DEPENDENCY_01='steam-launcher'
	DEPENDENCY_02="steam"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		install_debian_steam_app
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		install_fedora_steam_app
		beta_features_quick_install
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='steam-native-runtime'
		install_arch_steam_app
		#此处需要选择显卡驱动，故不要使用quick_install_function
		echo "pacman -Syu ${DEPENDENCY_01} ${DEPENDENCY_02}"
		pacman -Syu ${DEPENDENCY_01} ${DEPENDENCY_02}
	else
		beta_features_quick_install
	fi
}
####################
install_supertuxkart_game() {
	DEPENDENCY_02="supertuxkart"
	beta_features_quick_install
}
###################
remove_deb_package() {
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Back返回" --no-button "Remove移除" --yesno "${PACKAGE_NAME}\n您是想要返回还是卸载这个软件包？Do you want to return,or remove this package?♪(^∇^*) " 10 50); then
		other_software
	else
		apt purge ${PACKAGE_NAME}
		delete_tmoe_deb_file
		other_software
	fi
}
#############
deb_file_installer() {
	#进入deb文件目录
	cd ${CURRENT_DIR}
	#./${SELECTION}
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		file ./${SELECTION} 2>/dev/null
		apt show ./${SELECTION}
		PACKAGE_NAME=$(apt show ./${SELECTION} 2>&1 | grep Package | head -n 1 | awk -F ' ' '$0=$NF')
		echo "您是否需要安装此软件包？"
		echo "Do you want to install it?"
		RETURN_TO_WHERE='remove_deb_package'
		do_you_want_to_continue
		RETURN_TO_WHERE='other_software'
		apt install -y ./${SELECTION}
		DEPENDENCY_01=${PACKAGE_NAME}
		DEPENDENCY_02=""
		beta_features_install_completed
	else
		if [ ! $(command -v dpkg) ]; then
			DEPENDENCY_01='dpkg'
			DEPENDENCY_02=''
			echo ${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01}
			${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01}
			beta_features_install_completed
		fi
		if [ $(command -v dpkg) ]; then
			dpkg -i ./${SELECTION}
		else
			uncompress_deb_file
		fi
	fi
	delete_tmoe_deb_file
}
######################
uncompress_deb_file() {
	mkdir -p .DEB_TEMP_FOLDER
	mv ${SELECTION} .DEB_TEMP_FOLDER
	cd ./.DEB_TEMP_FOLDER
	if [ "${BUSYBOX_AR}" = 'true' ]; then
		busybox ar xv ${SELECTION}
	else
		ar xv ${SELECTION}
	fi
	mv ${SELECTION} ../
	if [ -e "data.tar.xz" ]; then
		cd /
		tar -Jxvf ${CURRENT_DIR}/.DEB_TEMP_FOLDER/data.tar.xz ./usr
	elif [ -e "data.tar.gz" ]; then
		cd /
		tar -zxvf ${CURRENT_DIR}/.DEB_TEMP_FOLDER/data.tar.gz ./usr
	fi
	rm -rf ${CURRENT_DIR}/.DEB_TEMP_FOLDER
}
########################
delete_tmoe_deb_file() {
	echo "请问是否需要${RED}删除${RESET}安装包文件"
	ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
	echo "Do you want to ${RED}delete${RESET} it?"
	do_you_want_to_continue
	rm -fv ${TMOE_FILE_ABSOLUTE_PATH}
}
#################
tmoe_deb_file_installer() {
	FILE_EXT_01='deb'
	FILE_EXT_02='DEB'
	START_DIR="${HOME}"
	tmoe_file_manager
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的deb文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		deb_file_installer
	fi
}
##################
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
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb"
			apt show ./LINUXQQ.deb
			apt install -y ./LINUXQQ.deb
		else
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o LINUXQQ.sh http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.sh
			chmod +x LINUXQQ.sh
			sudo ./LINUXQQ.sh
			#即使是root用户也需要加sudo
		fi
	elif [ "${ARCH_TYPE}" = "amd64" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_amd64.deb"
			apt show ./LINUXQQ.deb
			apt install -y ./LINUXQQ.deb
			#http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb
		else
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o LINUXQQ.sh "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_x86_64.sh"
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
		echo "检测到您已下载游戏文件，路径为${HOME}/斯隆与马克贝尔的谜之物语"
		press_enter_to_reinstall
	fi
	cd ${HOME}
	mkdir -p '斯隆与马克贝尔的谜之物语'
	cd '斯隆与马克贝尔的谜之物语'
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o slymkbr1.zip http://k73dx1.zxclqw.com/slymkbr1.zip
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o mayomonogatari2.zip http://k73dx1.zxclqw.com/mayomonogatari2.zip
	7za x slymkbr1.zip
	7za x mayomonogatari2.zip
	mv -f 斯隆与马克贝尔的谜之物语k73/* ./
	mv -f 迷之物语/* ./
	rm -f *url *txt
	rm -rf 迷之物语 斯隆与马克贝尔的谜之物语k73
	rm -f slymkbr1.zip* mayomonogatari2.zip*

	echo "安装完成，您需要手动执行${GREEN}/usr/games/desmume${RESER}，并进入'${HOME}/斯隆与马克贝尔的谜之物语'目录加载游戏"
	echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} desmume ; rm -rf ~/斯隆与马克贝尔的谜之物语"
	echo 'Press enter to start the nds emulator.'
	echo "${YELLOW}按回车键启动游戏。${RESET}"
	do_you_want_to_continue
	/usr/games/desmume "${HOME}/斯隆与马克贝尔的谜之物语/3782.nds" 2>/dev/null &
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
		GREP_NAME='debian-handbook'
		LATEST_DEB_REPO='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/d/debian-handbook/'
		download_tuna_repo_deb_file_all_arch
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'debian-handbook.deb' 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/d/debian-handbook/debian-handbook_8.20180830_all.deb'
		THE_LATEST_DEB_FILE='kali-undercover.deb'
		if [ "${BUSYBOX_AR}" = 'true' ]; then
			busybox ar xv ${LATEST_DEB_VERSION}
		else
			ar xv ${LATEST_DEB_VERSION}
		fi
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
	ps -e >/dev/null
	EXIT_STATUS="$?"
	if [ "${EXIT_STATUS}" != "0" ]; then
		echo "${RED}WARNING！${RESET}检测到您无权读取${GREEN}/proc${RESET}目录的某些数据！"
		echo "本工具将为此软件自动打补丁以解决无法运行的问题，但无法保证补丁有效。"
	fi

	#RETURN_TO_WHERE='other_software'
	#do_you_want_to_continue
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01='--no-install-recommends libreoffice'
	else
		DEPENDENCY_01="libreoffice"
	fi
	DEPENDENCY_02="libreoffice-l10n-zh-cn libreoffice-gtk3"
	NON_DEBIAN='false'
	beta_features_quick_install
	if [ "${EXIT_STATUS}" != "0" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			patch_libreoffice
		fi
		echo "打补丁完成"
	fi
}

###################
patch_libreoffice() {
	mkdir -p /prod/version
	cd /usr/lib/libreoffice/program
	rm -f oosplash
	curl -Lo 'oosplash' https://gitee.com/mo2/patch/raw/libreoffice/oosplash
	chmod +x oosplash
}
##################
check_libreoffice_patch() {
	if [ $(command -v libreoffice) ]; then
		patch_libreoffice
	fi
}
############
install_baidu_netdisk() {
	DEPENDENCY_01="baidunetdisk"
	DEPENDENCY_02=""
	if [ "${ARCH_TYPE}" != "amd64" ]; then
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
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'baidunetdisk.rpm' "http://wppkg.baidupcs.com/issue/netdisk/LinuxGuanjia/3.0.1/baidunetdisk_linux_3.0.1.2.rpm"
		rpm -ivh 'baidunetdisk.rpm'
	elif [ "${LINUX_DISTRO}" = "debian" ]; then
		GREP_NAME='baidunetdisk'
		LATEST_DEB_REPO='http://archive.ubuntukylin.com/software/pool/'
		download_ubuntu_kylin_deb_file_model_02
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o baidunetdisk.deb "http://wppkg.baidupcs.com/issue/netdisk/LinuxGuanjia/3.0.1/baidunetdisk_linux_3.0.1.2.deb"
		#apt show ./baidunetdisk.deb
		#apt install -y ./baidunetdisk.deb
	fi
	echo "若安装失败，则请前往官网手动下载安装"
	echo "url：https://pan.baidu.com/download"
	#rm -fv ./baidunetdisk.deb
	beta_features_install_completed
}
######################
#####################
install_deb_file_common_model_01() {
	cd /tmp
	LATEST_DEB_URL="${LATEST_DEB_REPO}${LATEST_DEB_VERSION}"
	echo ${LATEST_DEB_URL}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${LATEST_DEB_VERSION}" "${LATEST_DEB_URL}"
	apt show ./${LATEST_DEB_VERSION}
	apt install -y ./${LATEST_DEB_VERSION}
	rm -fv ./${LATEST_DEB_VERSION}
}
###################
download_ubuntu_kylin_deb_file_model_02() {
	LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 5 | cut -d '"' -f 2)
	install_deb_file_common_model_01
}
################
download_debian_cn_repo_deb_file_model_01() {
	LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
	install_deb_file_common_model_01
}
######################
download_tuna_repo_deb_file_model_03() {
	LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	install_deb_file_common_model_01
}
################
download_tuna_repo_deb_file_all_arch() {
	LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '.deb' | grep "all" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	LATEST_DEB_URL="${LATEST_DEB_REPO}${LATEST_DEB_VERSION}"
	echo ${LATEST_DEB_URL}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${LATEST_DEB_VERSION}" "${LATEST_DEB_URL}"
	apt show ./${LATEST_DEB_VERSION} 2>/dev/null
}
##此处不要自动安装deb包
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
		GREP_NAME='netease-cloud-music'
		if [ "${ARCH_TYPE}" = "amd64" ]; then
			LATEST_DEB_REPO='http://archive.ubuntukylin.com/software/pool/'
			download_ubuntu_kylin_deb_file_model_02
			#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o netease-cloud-music.deb "http://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb"
		else
			LATEST_DEB_REPO='http://mirrors.ustc.edu.cn/debiancn/pool/main/n/netease-cloud-music/'
			download_debian_cn_repo_deb_file_model_01
			#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o netease-cloud-music.deb "http://mirrors.ustc.edu.cn/debiancn/pool/main/n/netease-cloud-music/netease-cloud-music_1.0.0%2Brepack.debiancn-1_i386.deb"
		fi
		echo "若安装失败，则请前往官网手动下载安装。"
		echo 'url: https://music.163.com/st/download'
		beta_features_install_completed
	fi
	press_enter_to_return
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
	RETURN_TO_WHERE='modify_remote_desktop_config'
	RETURN_TO_TMOE_MENU_01='modify_remote_desktop_config'
	##################
	REMOTE_DESKTOP=$(whiptail --title "远程桌面" --menu \
		"您想要修改哪个远程桌面的配置？\nWhich remote desktop config do you want to modify?" 0 50 0 \
		"1" "tightvnc/tigervnc:应用广泛" \
		"2" "x11vnc:通过VNC来连接真实X桌面" \
		"3" "X服务:(XSDL/VcXsrv)" \
		"4" "XRDP:使用microsoft微软开发的rdp协议" \
		"5" "Wayland:(测试版,取代X Window)" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${REMOTE_DESKTOP}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) modify_vnc_conf ;;
	2) configure_x11vnc ;;
	3) modify_xsdl_conf ;;
	4) modify_xrdp_conf ;;
	5) modify_xwayland_conf ;;
	esac
	#######################
	press_enter_to_return
	modify_remote_desktop_config
}
#########################
configure_x11vnc() {
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE x11vnc" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 17 50 8 \
			"1" "one-key configure初始化一键配置" \
			"2" "pulse_server音频服务" \
			"3" "resolution分辨率" \
			"4" "修改startx11vnc启动脚本" \
			"5" "修改stopx11vnc停止脚本" \
			"6" "remove 卸载/移除" \
			"7" "readme 进程管理说明" \
			"8" "password 密码" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${TMOE_OPTION}" in
	0 | "") modify_remote_desktop_config ;;
	1) x11vnc_onekey ;;
	2) x11vnc_pulse_server ;;
	3) x11vnc_resolution ;;
	4) nano /usr/local/bin/startx11vnc ;;
	5) nano /usr/local/bin/stopx11vnc ;;
	6) remove_X11vnc ;;
	7) x11vnc_process_readme ;;
	8) x11vncpasswd ;;
	esac
	########################################
	press_enter_to_return
	configure_x11vnc
	####################
}
############
x11vnc_process_readme() {
	echo "输startx11vnc启动x11vnc"
	echo "输stopvnc或stopx11vnc停止x11vnc"
	echo "若您的音频服务端为Android系统，且发现音频服务无法启动,请在启动完成后，新建一个termux session会话窗口，然后手动在termux原系统里输${GREEN}pulseaudio -D${RESET}来启动音频服务后台进程"
	echo "您亦可输${GREEN}pulseaudio --start${RESET}"
	echo "若您无法记住该命令，则只需输${GREEN}debian${RESET}"
}
###################
x11vnc_warning() {
	cat <<-EOF
		    ${YELLOW}关于X11VNC服务的启动说明${RESET}：
			There are many differences between x11vnc and tightvnc. Mainly reflected in the fluency and special effects of the picture.
			After configuring x11vnc, you can type ${GREEN}startx11vnc${RESET} to ${BLUE}start${RESET} it.
			------------------------
			注：x11vnc和tightvnc是有${RED}区别${RESET}的！
			x11vnc可以打开tightvnc无法打开的某些应用，在WSL2/Linux虚拟机上的体验优于tightvnc，但在Android设备上运行的流畅度可能不如tightvnc
			------------------------
			配置完x11vnc后，您可以在容器里输${GREEN}startx11vnc${RESET}${BLUE}启动${RESET},输${GREEN}stopvnc${RESET}${RED}停止${RESET}
			若超过一分钟黑屏，则请输${GREEN}startx11vnc${RESET}重启该服务
			------------------------
			Do you want to configure x11vnc? 
			您是否需要配置${BLUE}X11VNC${RESET}服务？
	EOF

	RETURN_TO_WHERE='configure_x11vnc'
	do_you_want_to_continue
	#stopvnc 2>/dev/null
	NON_DEBIAN='false'
	DEPENDENCY_01=''
	DEPENDENCY_02=''
	if [ ! $(command -v x11vnc) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCY_01='x11-misc/x11vnc'
		else
			DEPENDENCY_01="${DEPENDENCY_01} x11vnc"
		fi
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
	if [ ! $(command -v pavucontrol) ]; then
		${PACKAGES_INSTALL_COMMAND} pavucontrol
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
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。当前为$(grep 'PULSE_SERVER' startx11vnc | grep -v '^#' | cut -d '=' -f 2 | head -n 1) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if grep -q '^export.*PULSE_SERVER' startx11vnc; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startx11vnc
		else
			sed -i "3 a\export PULSE_SERVER=$TARGET" startx11vnc
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' startx11vnc | grep -v '^#' | cut -d '=' -f 2 | head -n 1)
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
		sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :233 -screen 0 ${TARGET}x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)"
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
check_vnc_resolution() {
	CURRENT_VNC_RESOLUTION=$(grep '\-geometry' "$(command -v startvnc)" | tail -n 1 | cut -d 'y' -f 2 | cut -d '-' -f 1)
}
modify_vnc_conf() {
	if [ ! -e /usr/local/bin/startvnc ]; then
		echo "/usr/local/bin/startvnc is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startvnc,您可能尚未安装图形桌面，是否继续编辑?'
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		RETURN_TO_WHERE='modify_remote_desktop_config'
		do_you_want_to_continue
	fi
	check_vnc_resolution
	if (whiptail --title "modify vnc configuration" --yes-button '分辨率resolution' --no-button '其它other' --yesno "您想要修改哪项配置信息？Which configuration do you want to modify?" 9 50); then
		TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,720x1140,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为1440x720,当前为${CURRENT_VNC_RESOLUTION}。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			sed -i '/vncserver -geometry/d' "$(command -v startvnc)"
			sed -i "$ a\vncserver -geometry $TARGET -depth 24 -name tmoe-linux :1" "$(command -v startvnc)"
			echo 'Your current resolution has been modified.'
			check_vnc_resolution
			echo "您当前的分辨率已经修改为${CURRENT_VNC_RESOLUTION}"
			#echo $(sed -n \$p "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			#$p表示最后一行，必须用反斜杠转义。
			stopvnc 2>/dev/null
			press_enter_to_return
			modify_remote_desktop_config
		else
			echo "您当前的分辨率为${CURRENT_VNC_RESOLUTION}"
		fi
	else
		modify_other_vnc_conf
	fi
}
############################
modify_xsdl_conf() {
	if [ "${RETURN_TO_TMOE_MENU_01}" = 'modify_remote_desktop_config' ]; then
		if [ ! -f /usr/local/bin/startxsdl ]; then
			echo "/usr/local/bin/startxsdl is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
			echo '未检测到startxsdl,您可能尚未安装图形桌面，是否继续编辑。'
			RETURN_TO_WHERE='modify_remote_desktop_config'
			do_you_want_to_continue
		fi
		TMOE_XSDL_SCRIPT_PATH='/usr/local/bin/startxsdl'
	else
		TMOE_XSDL_SCRIPT_PATH='/usr/local/bin/startqemu'
	fi
	XSDL_XSERVER=$(whiptail --title "Modify x server conf" --menu "Which configuration do you want to modify?" 0 50 0 \
		"1" "Pulse server port音频端口" \
		"2" "Display number显示编号" \
		"3" "ip address" \
		"4" "Edit manually手动编辑" \
		"5" "DISPLAY switch转发显示开关(仅qemu)" \
		"6" "VcXsrv显示端口(仅win10)" \
		"0" "Return to previous menu 返回上级菜单" \
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
		echo ${XSDL_DISPLAY_STATUS}
		echo "是否需要禁用?"
		echo "Do you want to disable it"
		do_you_want_to_continue
		sed -i '/export DISPLAY=/d' ${TMOE_XSDL_SCRIPT_PATH}
		echo "禁用完成"
	else
		XSDL_DISPLAY_STATUS='检测到您尚未启用转发X显示画面的功能，打开qemu时，将直接调用当前显示器的窗口。'
		echo ${XSDL_DISPLAY_STATUS}
		echo "是否需要启用？"
		echo "Do you want to enable it"
		do_you_want_to_continue
		sed -i "1 a\export DISPLAY=127.0.0.1:0" ${TMOE_XSDL_SCRIPT_PATH}
		echo "启用完成"
	fi
}
#################
modify_startxsdl_manually() {
	nano ${TMOE_XSDL_SCRIPT_PATH}
	echo 'See your current xsdl configuration information below.'

	check_tmoe_xsdl_display_ip
	echo "您当前的显示服务的ip地址为${CURRENT_DISPLAY_IP}"

	#echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)

	check_tmoe_xsdl_display_port
	echo "您当前的显示端口为${CURRENT_DISPLAY_PORT}"
	#echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2)

	check_tmoe_xsdl_pulse_audio_port
	echo "您当前的音频(ip/端口)为${CURRENT_PULSE_AUDIO_PORT}"
	#echo $(sed -n 4p $(command -v startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
}
######################
check_tmoe_xsdl_display_ip() {
	CURRENT_DISPLAY_IP=$(cat ${TMOE_XSDL_SCRIPT_PATH} | grep 'export DISPLAY' | head -n 1 | cut -d '=' -f 2 | cut -d ':' -f 1)
}
######
check_tmoe_vcxsrv_display_port() {
	CURRENT_VSCSRV_DISPLAY_PORT=$(cat ${TMOE_XSDL_SCRIPT_PATH} | grep 'VCXSRV_DISPLAY_PORT=' | head -n 1 | cut -d '=' -f 2)
}
######
check_tmoe_xsdl_display_port() {
	CURRENT_DISPLAY_PORT=$(cat ${TMOE_XSDL_SCRIPT_PATH} | grep 'export DISPLAY' | head -n 1 | cut -d '=' -f 2 | cut -d ':' -f 2)
}
#######
check_tmoe_xsdl_pulse_audio_port() {
	CURRENT_PULSE_AUDIO_PORT=$(cat ${TMOE_XSDL_SCRIPT_PATH} | grep 'export PULSE_SERVER' | head -n 1 | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
}
#################
modify_pulse_server_port() {
	check_tmoe_xsdl_pulse_audio_port
	TARGET=$(whiptail --inputbox "若xsdl app显示的端口非4713，则您可在此处修改。默认为4713，当前为${CURRENT_PULSE_AUDIO_PORT}\n请以xsdl app显示的pulse_server地址的最后几位数字为准。若您的宿主机系统非Android,而是win10,且使用了tmoe-linux自带的pulseaudio，则端口为0,输入完成后按回车键确认。" 15 50 --title "MODIFY PULSE SERVER PORT " 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		modify_xsdl_conf
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		#sed -i "4 c export PULSE_SERVER=tcp:127.0.0.1:$TARGET" "$(command -v startxsdl)"
		PULSE_LINE=$(cat "${TMOE_XSDL_SCRIPT_PATH}" | grep 'export PULSE_SERVER' -n | head -n 1 | awk '{print $1}' | cut -d ':' -f 1)
		CURRENT_PULSE_IP=$(cat ${TMOE_XSDL_SCRIPT_PATH} | grep 'export PULSE_SERVER' | head -n 1 | cut -d '=' -f 2 | cut -d ':' -f 2)
		sed -i "${PULSE_LINE} c\export PULSE_SERVER=tcp:${CURRENT_PULSE_IP}:${TARGET}" ${TMOE_XSDL_SCRIPT_PATH}
		echo 'Your current PULSE SERVER port has been modified.'
		check_tmoe_xsdl_pulse_audio_port
		echo "您当前的音频端口已修改为${CURRENT_PULSE_AUDIO_PORT}"
	fi
}
########################################################
modify_vcxsrv_display_port (){ 
    check_tmoe_vcxsrv_display_port
	TARGET=$(whiptail --inputbox "若您需要指定vcxsrv显示的Display number(输出显示的端口数字),\n则可在此处修改。默认为37985，当前为${CURRENT_VSCSRV_DISPLAY_PORT}" 0 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		modify_xsdl_conf
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		DISPLAY_LINE=$(cat "${TMOE_XSDL_SCRIPT_PATH}" | grep 'VCXSRV_DISPLAY_PORT=' -n | head -n 1 | awk '{print $1}' | cut -d ':' -f 1)
		sed -i "${DISPLAY_LINE} c\VCXSRV_DISPLAY_PORT=${TARGET}" "${TMOE_XSDL_SCRIPT_PATH}"
		echo 'Your current DISPLAY port has been modified.'
		check_tmoe_vcxsrv_display_port
		echo "您当前的VcXsrv显示端口已经修改为${CURRENT_VSCSRV_DISPLAY_PORT}"
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
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		DISPLAY_LINE=$(cat "${TMOE_XSDL_SCRIPT_PATH}" | grep 'export DISPLAY' -n | head -n 1 | awk '{print $1}' | cut -d ':' -f 1)
		sed -i "${DISPLAY_LINE} c\export DISPLAY=${CURRENT_DISPLAY_IP}:${TARGET}" "${TMOE_XSDL_SCRIPT_PATH}"
		echo 'Your current DISPLAY port has been modified.'
		check_tmoe_xsdl_display_port
		echo "您当前的显示端口已经修改为${CURRENT_DISPLAY_PORT}"
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
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		sed -i "s/${CURRENT_DISPLAY_IP}/${TARGET}/g" "${TMOE_XSDL_SCRIPT_PATH}"
		echo 'Your current ip address has been modified.'
		check_tmoe_xsdl_display_ip
		echo "您当前的显示服务的ip地址已经修改为${CURRENT_DISPLAY_IP}"
		press_enter_to_return
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
	press_enter_to_return
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
	press_enter_to_return
	configure_xwayland
}
#######################
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
			"0" "Return to previous menu 返回上级菜单" \
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
}
##############
xwayland_pulse_server() {
	cd /usr/local/bin/
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可以在此处修改。当前为$(grep 'PULSE_SERVER' startw | grep -v '^#' | cut -d '=' -f 2 | head -n 1) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if grep '^export.*PULSE_SERVER' startw; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startw
		else
			sed -i "3 a\export PULSE_SERVER=$TARGET" startw
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' startw | grep -v '^#' | cut -d '=' -f 2 | head -n 1)
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
	RETURN_TO_WHERE='configure_xrdp'
	cd /etc/xrdp/
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE XRDP" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 16 50 7 \
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
		#echo "Type ${GREEN}q${RESET} to ${BLUE}return.${RESET}"
		systemctl status xrdp | head -n 24
	fi
}
####################
remove_xrdp() {
	pkill xrdp
	echo "正在停止xrdp进程..."
	echo "Stopping xrdp..."
	service xrdp stop 2>/dev/null || systemctl stop xrdp
	echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
	#service xrdp restart
	RETURN_TO_WHERE='configure_xrdp'
	do_you_want_to_continue
	rm -fv /etc/xrdp/xrdp.ini /etc/xrdp/startwm.sh
	echo "${YELLOW}已删除xrdp配置文件${RESET}"
	echo "即将为您卸载..."
	${PACKAGES_REMOVE_COMMAND} xrdp
}
################
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
		REMOTE_DESKTOP_SESSION_01='xfce4-session'
		REMOTE_DESKTOP_SESSION_02='startxfce4'
		#configure_remote_xfce4_desktop
	fi
	##########################
	if [ "${BETA_DESKTOP}" == '2' ]; then
		REMOTE_DESKTOP_SESSION_01='lxsession'
		REMOTE_DESKTOP_SESSION_02='startlxde'
		#configure_remote_lxde_desktop
	fi
	##########################
	if [ "${BETA_DESKTOP}" == '3' ]; then
		REMOTE_DESKTOP_SESSION_01='mate-session'
		REMOTE_DESKTOP_SESSION_02='x-windows-manager'
		#configure_remote_mate_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '4' ]; then
		REMOTE_DESKTOP_SESSION_01='lxqt-session'
		REMOTE_DESKTOP_SESSION_02='startlxqt'
		#configure_remote_lxqt_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '5' ]; then
		#REMOTE_DESKTOP_SESSION='plasma-x11-session'
		#configure_remote_kde_plasma5_desktop
		REMOTE_DESKTOP_SESSION_01='startkde'
		REMOTE_DESKTOP_SESSION_02='startplasma-x11'
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '6' ]; then
		REMOTE_DESKTOP_SESSION_01='gnome-session'
		REMOTE_DESKTOP_SESSION_02='x-window-manager'
		#configure_remote_gnome3_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '7' ]; then
		#configure_remote_cinnamon_desktop
		REMOTE_DESKTOP_SESSION_01='cinnamon-session'
		REMOTE_DESKTOP_SESSION_02='cinnamon-launcher'
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '8' ]; then
		REMOTE_DESKTOP_SESSION_01='startdde'
		REMOTE_DESKTOP_SESSION_02='x-window-manager'
		#configure_remote_deepin_desktop
	fi
	##########################
	if [ "${BETA_DESKTOP}" == '0' ] || [ -z ${BETA_DESKTOP} ]; then
		modify_remote_desktop_config
	fi
	##########################
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "redhat" ]; then
			NON_DBUS='true'
		fi
	fi
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
	sed -i "s@exec /bin/sh /etc/X11/Xsession@exec ${REMOTE_DESKTOP_SESSION}@g" /etc/xrdp/startwm.sh
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
	systemctl stop xrdp || service xrdp restart
	check_xrdp_status
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
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。linux默认为127.0.0.1,WSL2默认为宿主机ip,当前为$(grep 'PULSE_SERVER' startwm.sh | grep -v '^#' | cut -d '=' -f 2 | head -n 1) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then

		if grep ! '^export.*PULSE_SERVER' startwm.sh; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startwm.sh
			#sed -i "4 a\export PULSE_SERVER=$TARGET" startwm.sh
		fi
		sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startwm.sh
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' startwm.sh | grep -v '^#' | cut -d '=' -f 2 | head -n 1)
		press_enter_to_return_configure_xrdp
	else
		configure_xrdp
	fi
}
##############
xrdp_onekey() {
	RETURN_TO_WHERE='configure_xrdp'
	do_you_want_to_continue

	DEPENDENCY_01=''
	DEPENDENCY_02='xrdp'
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
	service xrdp restart 2>/dev/null || systemctl restart xrdp
	if [ "$?" != "0" ]; then
		/etc/init.d/xrdp restart
	fi
	check_xrdp_status
	echo "您可以输${YELLOW}service xrdp stop${RESET}来停止进程"
	echo "您当前的IP地址为"
	ip -4 -br -c a | cut -d '/' -f 1
	echo "端口号为${RDP_PORT}"
	echo "正在为您启动xrdp服务，本机默认访问地址为localhost:${RDP_PORT}"
	echo The LAN address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${RDP_PORT}
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
	TARGET=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,不建议您将其设置为22、80、443或3389,检测到您当前的端口为${RDP_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		#echo "检测到您取消了操作"
		${RETURN_TO_WHERE}
		#echo "检测到您取消了操作，请返回重试。"
		#press_enter_to_return_configure_xrdp
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		sed -i "s@port=${RDP_PORT}@port=${TARGET}@" xrdp.ini
		ls -l $(pwd)/xrdp.ini
		cat xrdp.ini | grep 'port=' | head -n 1
		/etc/init.d/xrdp restart
	fi
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
			VCXSRV_DISPLAY_PORT=37985
			export PULSE_SERVER=tcp:127.0.0.1
			cd "/mnt/c/Users/Public/Downloads/pulseaudio"
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat"
			echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
			cd "/mnt/c/Users/Public/Downloads/VcXsrv/"
			#/mnt/c/WINDOWS/system32/cmd.exe /c "start .\config.xlaunch"
			/mnt/c/WINDOWS/system32/taskkill.exe /f /im vcxsrv.exe 2>/dev/null
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\vcxsrv.exe :${VCXSRV_DISPLAY_PORT} -multiwindow -clipboard -wgl -ac"
			echo "若无法自动打开X服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe"
			if grep -q '172..*1' "/etc/resolv.conf"; then
				echo "检测到您当前使用的可能是WSL2，如需手动启动，请在xlaunch.exe中勾选Disable access control"
				WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
				export PULSE_SERVER=${WSL2IP}
				export DISPLAY=${WSL2IP}:${VCXSRV_DISPLAY_PORT}
				echo "已将您的显示和音频服务ip修改为${WSL2IP}"
			else
                export DISPLAY="$(echo ${DISPLAY} | cut -d ':' -f 1):${VCXSRV_DISPLAY_PORT}"
			fi
			sleep 2
		fi
		TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
		if [ -e "${TMOE_LOCALE_FILE}" ]; then
		    TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
		    export LANG="${TMOE_LANG}"
		else
		    export LANG="en_US.UTF-8"
		fi
	EndOfFile
	cat >>startxsdl <<-ENDofStartxsdl
		if [ \$(command -v ${REMOTE_DESKTOP_SESSION_01}) ]; then
			dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01}
		else
			dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_02}
		fi
	ENDofStartxsdl
	#启动命令结尾无&
	###############################
	#debian禁用dbus分两次，并非重复
	if [ "${NON_DBUS}" = "true" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			sed -i 's:dbus-launch --exit-with-session::' startxsdl ~/.vnc/xstartup
		fi
	fi
}
#################
configure_startvnc() {
	cd /usr/local/bin
	rm -f startvnc
	cat >startvnc <<-'EndOfFile'
		#!/bin/bash
		stopvnc >/dev/null 2>&1
		export USER="$(whoami)"
		export HOME="${HOME}"
		if [ ! -e "${HOME}/.vnc/xstartup" ]; then
			sudo -E cp -rvf "/root/.vnc" "${HOME}" || su -c "cp -rvf /root/.vnc ${HOME}"
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
			sleep 2
		fi
		if [ ${HOME} != '/root' ]; then
		CURRENT_USER_NAME=$(cat /etc/passwd | grep "${HOME}" | awk -F ':' '{print $1}')
		CURRENT_USER_GROUP=$(cat /etc/passwd | grep "${HOME}" | awk -F ':' '{print $5}' | cut -d ',' -f 1)
		if [ -z "${CURRENT_USER_GROUP}" ]; then
		   CURRENT_USER_GROUP=${CURRENT_USER_NAME}
		fi
		CURRENT_USER_VNC_FILE_PERMISSION=$(ls -l ${HOME}/.vnc/passwd | awk -F ' ' '{print $3}')
		if [ "${CURRENT_USER_VNC_FILE_PERMISSION}" != "${CURRENT_USER_NAME}" ];then
		   echo "检测到${HOME}目录不为/root，为避免权限问题，正在将${HOME}目录下的.ICEauthority、.Xauthority以及.vnc 的权限归属修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
		   cd ${HOME}
		   sudo -E chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ".ICEauthority" ".ICEauthority" ".vnc" || su -c "chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} .ICEauthority .ICEauthority .vnc"
		fi
		fi
		CURRENT_PORT=$(cat /usr/local/bin/startvnc | grep '\-geometry' | awk -F ' ' '$0=$NF' | cut -d ':' -f 2 | tail -n 1)
		CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
		echo "正在启动vnc服务,本机默认vnc地址localhost:${CURRENT_VNC_PORT}"
		echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${CURRENT_VNC_PORT}
		TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
		if [ -e "${TMOE_LOCALE_FILE}" ]; then
		    TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
		    export LANG="${TMOE_LANG}"
		else
		    export LANG="en_US.UTF-8"
		fi
		#启动VNC服务的命令为最后一行
		vncserver -geometry 1440x720 -depth 24 -name tmoe-linux :1
	EndOfFile
	##############
	cat >stopvnc <<-'EndOfFile'
		#!/bin/bash
		export USER="$(whoami)"
		export HOME="${HOME}"
		CURRENT_PORT=$(cat /usr/local/bin/startvnc | grep '\-geometry' | awk -F ' ' '$0=$NF' | cut -d ':' -f 2 | tail -n 1)
		vncserver -kill :${CURRENT_PORT}
		rm -rf /tmp/.X1-lock
		rm -rf /tmp/.X11-unix/X1
		pkill Xtightvnc
		stopx11vnc 2>/dev/null
	EndOfFile
}
###############
fix_non_root_permissions() {
	if [ ${HOME} != '/root' ]; then
		#check_current_user_name_and_group
		echo "检测到${HOME}目录不为/root，为避免权限问题，正在将${CURRENT_USER_FILE}的权限归属修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
		sudo -E chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} "${CURRENT_USER_FILE}" || su -c "chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${CURRENT_USER_FILE}"
	fi
}
################
which_vnc_server_do_you_prefer() {
	if (whiptail --title "Which vnc server do you prefer" --yes-button 'tiger' --no-button 'tight' --yesno "您想要选择哪个VNC服务端?(っ °Д °)\ntiger比tight支持更多的特效和选项,例如鼠标指针和背景透明等。\n因前者的流畅度可能不如后者,故默认情况下为后者。\nTiger can show more special effects." 0 50); then
		VNC_SERVER_BIN="tigervnc"
		VNC_SERVER_BIN_NOW="tightvncserver"
		DEPENDENCY_02="tigervnc-standalone-server"
	else
		VNC_SERVER_BIN="tightvnc"
		VNC_SERVER_BIN_NOW="tigervnc-standalone-server"
		DEPENDENCY_02="tightvncserver"
	fi
	echo "${RED}${PACKAGES_REMOVE_COMMAND} ${VNC_SERVER_BIN_NOW}${RESET}"
	${PACKAGES_REMOVE_COMMAND} ${VNC_SERVER_BIN_NOW}
	echo "${BLUE}${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_02}${RESET}"
	${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_02}
}
###################
first_configure_startvnc() {
	#卸载udisks2，会破坏mate和plasma的依赖关系。
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ] && [ ${REMOVE_UDISK2} = 'true' ]; then
		if [ "${LINUX_DISTRO}" = 'debian' ]; then
			if grep -Eq 'Focal Fossa|focal|bionic|Bionic Beaver|Eoan Ermine|buster|stretch|jessie' "/etc/os-release"; then
				echo "检测到您处于${BLUE}proot容器${RESET}环境下，即将为您${RED}卸载${RESET}${YELLOW}udisk2${RESET}和${GREEN}gvfs${RESET}"
				#umount .gvfs
				apt purge -y --allow-change-held-packages ^udisks2 ^gvfs
			fi
		fi
	fi
	configure_startvnc
	configure_startxsdl
	chmod +x startvnc stopvnc startxsdl
	if [ "${LINUX_DISTRO}" != "debian" ]; then
		sed -i 's@--exit-with-session@@' ~/.vnc/xstartup /usr/local/bin/startxsdl
	else
		if ! grep -Eq 'Focal Fossa|focal|bionic|Bionic Beaver|Eoan Ermine|buster|stretch|jessie' "/etc/os-release"; then
			which_vnc_server_do_you_prefer
		fi
	fi
	######################
	dpkg --configure -a 2>/dev/null
	if [ ${HOME} != '/root' ]; then
		#check_current_user_name_and_group
		echo "检测到${HOME}目录不为/root，为避免权限问题，正在将${HOME}目录下的.ICEauthority、.Xauthority以及.vnc 的权限归属修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
		cd ${HOME}
		sudo -E chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ".ICEauthority" ".ICEauthority" ".vnc" || su -c "chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} .ICEauthority .ICEauthority .vnc"
	fi
	#仅针对WSL修改语言设定
	#/etc/default/locale
	#if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
	#	if [ "${LANG}" != 'en_US.UTF-8' ]; then
	#grep -q 'LANG=\"en_US' "/etc/profile" || sed -i '$ a\export LANG="en_US.UTF-8"' "/etc/profile"
	#grep -q 'LANG=\"en_US' "${HOME}/.zlogin" || echo 'export LANG="en_US.UTF-8"' >>"${HOME}/.zlogin"
	#	fi
	#fi
	if [ ! -e "${HOME}/.vnc/passwd" ]; then
		set_vnc_passwd
	fi
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
	echo '------------------------'
	TMOE_HIGH_DPI='false'
	if [ "${REMOTE_DESKTOP_SESSION_01}" = 'xfce4-session' ]; then
		if (whiptail --title "Are you using a high-resolution monitor" --yes-button 'YES' --no-button 'NO' --yesno "您当前是否使用高分辨率屏幕/显示器?(っ °Д °)\n设屏幕分辨率为x,若x>=2K,则选择YES;\n若x<=1080p,则选择NO。" 0 50); then
			TMOE_HIGH_DPI='true'
			xfce4_tightvnc_hidpi_settings
		else
			TMOE_HIGH_DPI='false'
			echo "默认分辨率为1440x720，窗口缩放大小为1x"
			dbus-launch xfconf-query -c xsettings -t int -np /Gdk/WindowScalingFactor -s 1 2>/dev/null
			if grep -Eq 'Focal Fossa|focal|bionic|Bionic Beaver|Eoan Ermine|buster|stretch|jessie' "/etc/os-release"; then
				dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Kali-Light-DPI 2>/dev/null
			fi
			echo "若分辨率不合，则请在脚本执行完成后，手动输${GREEN}debian-i${RESET}，然后在${BLUE}vnc${RESET}选项里进行修改。"
			echo "You can type debian-i to start tmoe-linux tool,and modify the vnc screen resolution."
		fi
	fi
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
		若您的音频服务端为${BLUE}windows10系统${RESET}，则请手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'，并修改音频服务地址。
		------------------------
		若您使用的是${BLUE}Android版${RESET}${YELLOW}Linux Deploy${RESET}或${YELLOW}Userland${RESET}，则您可以使用本脚本${RED}覆盖安装${RESET}图形界面。之后,您可以在${BLUE}Termux${RESET}上输${GREEN}debian-i${RESET}运行Tmoe-linux manager,查看${YELLOW}FAQ${RESET}并配置Linux Deploy的${BLUE}音频服务启动脚本。${RESET}
		------------------------
	EOF
	echo "二："
	echo "${YELLOW}关于VNC和X的启动说明${RESET}"
	echo '------------------------'
	echo "You can type ${GREEN}startvnc${RESET} to ${BLUE}start${RESET} vncserver,type stopvnc to ${RED}stop${RESET} it."
	echo "You can also type ${GREEN}startxsdl${RESET} to ${BLUE}start${RESET} X client and server."
	echo '------------------------'
	echo "您之后可以在原系统里输${BOLD}${GREEN}startvnc${RESET}${RESET}${BLUE}同时启动${RESET}vnc服务端和客户端。"
	echo "在容器里输${BOLD}${GREEN}startvnc${RESET}${RESET}(仅支持)${BLUE}启动${RESET}vnc服务端，输${GREEN}stopvnc${RESET}${RED}停止${RESET}"
	echo "在原系统里输${GREEN}startxsdl${RESET}同时启动X客户端与服务端，按${YELLOW}Ctrl+C${RESET}或在termux原系统里输${GREEN}stopvnc${RESET}来${RED}停止${RESET}进程"
	echo "注：同时启动tight/tigervnc服务端和realvnc客户端仅适配Termux,同时启动X客户端和服务端还适配了win10的linux子系统"
	echo '------------------------'
	echo '------------------------'
	if [ "${HOME}" != "/root" ]; then
		cp -rpf ~/.vnc /root/
		chown -R root:root /root/.vnc
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
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "Firewall-pulseaudio.png" 'https://gitee.com/mo2/pic_api/raw/test/2020/03/31/rXLbHDxfj1Vy9HnH.png'
		fi
		/mnt/c/WINDOWS/system32/cmd.exe /c "start Firewall.cpl"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\Firewall-pulseaudio.png" 2>/dev/null
		############
		if [ ! -e 'XserverhighDPI.png' ]; then
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'XserverhighDPI.png' https://gitee.com/mo2/pic_api/raw/test/2020/03/27/jvNs2JUIbsSQQInO.png
		fi
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\XserverhighDPI.png" 2>/dev/null
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
	echo "按${YELLOW}回车键${RESET}查看x11vnc的${BLUE}启动说明${RESET}"
	press_enter_to_continue
	echo '------------------------'
	echo '三：'
	x11vnc_warning
	configure_x11vnc_remote_desktop_session
	xfce4_x11vnc_hidpi_settings
}
########################
########################
set_vnc_passwd() {
	TARGET_VNC_PASSWD=$(whiptail --inputbox "请设定6至8位VNC访问密码\n Please enter the password, the length is 6 to 8 digits" 0 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		echo "请重新输入密码"
		echo "Please enter the password again."
		press_enter_to_return
		set_vnc_passwd
	elif [ -z "${TARGET_VNC_PASSWD}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
		press_enter_to_return
		set_vnc_passwd
	else
		check_vnc_passsword_length
	fi
}
###########
check_vnc_passsword_length() {
	PASSWORD_LENGTH=$(echo -n ${TARGET_VNC_PASSWD} | wc -L)
	if ((${PASSWORD_LENGTH} > 8)); then
		echo ${PASSWORD_LENGTH}
		echo "密码超过${RED}8个字符${RESET}，请${BLUE}重新输入${RESET}"
		echo "${RED}WARNING！${RESET}The maximum password length is ${RED}8 digits.${RESET}"
		press_enter_to_return
		set_vnc_passwd
	elif ((${PASSWORD_LENGTH} < 6)); then
		echo ${PASSWORD_LENGTH}
		echo "密码少于${RED}6个字符${RESET}，请${BLUE}重新输入${RESET}"
		echo "${RED}WARNING！${RESET}The minimum password length is ${RED}6 digits.${RESET}"
		press_enter_to_return
		set_vnc_passwd
	else
		mkdir -p ${HOME}/.vnc
		cd ${HOME}/.vnc
		echo "${TARGET_VNC_PASSWD}" | vncpasswd -f >passwd
		chmod 600 passwd
		if [ $? = 0 ]; then
			echo "密码设定完成，您可以输${GREEN}startvnc${RESET}来重启服务"
			echo "You can type ${GREEN}startvnc${RESET} to restart it. "
			echo "若您想要修改其它vnc选项，那么您可以输${BLUE}debian-i${RESET}"
			echo "You can also type ${BLUE}debian-i${RESET} to start tmoe-linux tool."
		else
			echo "密码设定失败，内部发生错误。"
		fi
	fi
}
###################
xfce4_tightvnc_hidpi_settings() {
	echo "检测到您当前的桌面环境为xfce4，将为您自动调整高分屏设定"
	echo "若分辨率不合，则请在脚本执行完成后，手动输${GREEN}debian-i${RESET}，然后在${BLUE}vnc${RESET}选项里进行修改。"
	stopvnc >/dev/null 2>&1
	sed -i '/vncserver -geometry/d' "$(command -v startvnc)"
	sed -i "$ a\vncserver -geometry 2880x1440 -depth 24 -name tmoe-linux :1" "$(command -v startvnc)"
	sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :233 -screen 0 2880x1440x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)" 2>/dev/null
	echo "已将默认分辨率修改为2880x1440，窗口缩放大小调整为2x"
	dbus-launch xfconf-query -c xsettings -t int -np /Gdk/WindowScalingFactor -s 2 2>/dev/null
	#-n创建一个新属性，类型为int
	if grep -Eq 'Focal Fossa|focal|bionic|Bionic Beaver|Eoan Ermine|buster|stretch|jessie' "/etc/os-release"; then
		dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Kali-Light-xHiDPI 2>/dev/null
	else
		dbus-launch xfconf-query -c xfwm4 -t string -np /general/theme -s Default-xhdpi 2>/dev/null
	fi
	#dbus-launch xfconf-query -c xfce4-panel -p /plugins/plugin-1 -s whiskermenu
	#startvnc >/dev/null 2>&1
	#Default-xhdpi默认处于未激活状态
}
################
xfce4_x11vnc_hidpi_settings() {
	if [ ${TMOE_HIGH_DPI} = 'true' ]; then
		if [ "${REMOTE_DESKTOP_SESSION_01}" = 'xfce4-session' ]; then
			#stopx11vnc >/dev/null 2>&1
			sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :233 -screen 0 2880x1440x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)"
			#startx11vnc >/dev/null 2>&1
		fi
	fi
}
####################
frequently_asked_questions() {
	RETURN_TO_WHERE='frequently_asked_questions'
	DEPENDENCY_01=''
	NON_DEBIAN='false'
	TMOE_FAQ=$(whiptail --title "FAQ(よくある質問)" --menu \
		"您有哪些疑问？\nWhat questions do you have?" 17 50 7 \
		"1" "Cannot open Baidu Netdisk" \
		"2" "udisks2/gvfs配置失败" \
		"3" "linuxQQ闪退" \
		"4" "VNC/X11闪退" \
		"5" "软件禁止以root权限运行" \
		"6" "mlocate数据库初始化失败" \
		"7" "TTY下中文字体乱码" \
		"8" "Linux与win10双系统时间不一致" \
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
	fi
	#######################
	if [ "${TMOE_FAQ}" == '2' ]; then
		echo "${YELLOW}按回车键卸载gvfs和udisks2${RESET}"
		RETURN_TO_WHERE='frequently_asked_questions'
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} --allow-change-held-packages ^udisks2 ^gvfs
	fi
	############################
	if [ "${TMOE_FAQ}" == '3' ]; then
		echo "如果版本更新后登录出现闪退的情况，那么您可以输rm -rf ~/.config/tencent-qq/ 后重新登录。"
		echo "${YELLOW}按回车键自动执行上述命令${RESET}"
		RETURN_TO_WHERE='frequently_asked_questions'
		do_you_want_to_continue
		rm -rvf ~/.config/tencent-qq/
	fi
	#######################
	if [ "${TMOE_FAQ}" == '4' ]; then
		fix_vnc_dbus_launch
	fi
	#######################
	if [ "${TMOE_FAQ}" == '5' ]; then
		echo 'deb系创建用户的说明'
		echo "部分软件出于安全性考虑，禁止以root权限运行。权限越大，责任越大。若root用户不慎操作，将有可能破坏系统。"
		echo "您可以使用以下命令来新建普通用户"
		echo "#创建一个用户名为mo2的新用户"
		echo "${YELLOW}adduser mo2${RESET}"
		echo "#输入的密码是隐藏的，根据提示创建完成后，接着输以下命令"
		echo "#将mo2加入到sudo用户组"
		echo "${YELLOW}adduser mo2 sudo${RESET}"
		echo "之后，若需要提权，则只需输sudo 命令"
		echo "例如${YELLOW}sudo apt update${RESET}"
		echo "--------------------"
		echo "切换用户的说明"
		echo "您可以输${YELLOW}su - ${RESET}或${YELLOW}sudo su - ${RESET}亦或者是${YELLOW}sudo -i ${RESET}切换至root用户"
		echo "亦可输${YELLOW}su - mo2${RESET}或${YELLOW}sudo -iu mo2${RESET}切换回mo2用户"
		echo "若需要以普通用户身份启动VNC，请先切换至普通用户，再输${YELLOW}startvnc${RESET}"
		echo '--------------------'
		echo 'arch系创建新用户的命令为useradd -m loveyou'
		echo '其中loveyou为用户名'
		echo '输passwd loveyou修改该用户密码'
		echo '如需将其添加至sudo用户组，那么您可以使用本工具自带的sudo用户组管理功能(位于测试功能的系统管理选项)'
	fi
	###################
	if [ "${TMOE_FAQ}" == '6' ]; then
		echo "您是否需要卸载mlocate和catfish"
		echo "Do you want to remove mlocate and catfish?"
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} mlocate catfish
		apt autopurge 2>/dev/null
	fi
	###################
	if [ "${TMOE_FAQ}" == '7' ]; then
		tty_chinese_code
	fi
	###################
	if [ "${TMOE_FAQ}" == '8' ]; then
		fix_linux_utc_timezone
	fi
	##################
	if [ -z "${TMOE_FAQ}" ]; then
		tmoe_linux_tool_menu
	fi
	###########
	press_enter_to_return
	frequently_asked_questions
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
			${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01}
		fi
		echo '若启动失败，则请手动执行fbterm'
		fbterm
	else
		export LANG='C.UTF-8'
		echo '请手动执行LANG=C.UTF-8'
	fi
}
################
enable_dbus_launch() {
	XSTARTUP_LINE=$(cat -n ~/.vnc/xstartup | grep -v 'command' | grep ${REMOTE_DESKTOP_SESSION_01} | awk -F ' ' '{print $1}')
	sed -i "${XSTARTUP_LINE} c\ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01} \&" ~/.vnc/xstartup
	#################
	START_X11VNC_LINE=$(cat -n /usr/local/bin/startx11vnc | grep -v 'command' | grep ${REMOTE_DESKTOP_SESSION_01} | awk -F ' ' '{print $1}')
	sed -i "${START_X11VNC_LINE} c\ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01} \&" /usr/local/bin/startx11vnc
	##################
	START_XSDL_LINE=$(cat -n /usr/local/bin/startxsdl | grep -v 'command' | grep ${REMOTE_DESKTOP_SESSION_01} | awk -F ' ' '{print $1}')
	sed -i "${START_XSDL_LINE} c\ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01}" /usr/local/bin/startxsdl
	#################
	sed -i "s/.*${REMOTE_DESKTOP_SESSION_02}.*/ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_02} \&/" ~/.vnc/xstartup "/usr/local/bin/startx11vnc"
	sed -i "s/.*${REMOTE_DESKTOP_SESSION_02}.*/ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_02}/" "/usr/local/bin/startxsdl"
	if [ "${LINUX_DISTRO}" != "debian" ]; then
		sed -i 's@--exit-with-session@@' ~/.vnc/xstartup /usr/local/bin/startxsdl /usr/local/bin/startx11vnc
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
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			sed -i 's:dbus-launch --exit-with-session::' "/usr/local/bin/startxsdl" "${HOME}/.vnc/xstartup" "/usr/local/bin/startx11vnc"
		else
			sed -i 's@--exit-with-session@@' ~/.vnc/xstartup /usr/local/bin/startxsdl /usr/local/bin/startx11vnc
		fi
	else
		if grep 'startxfce4' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为xfce4，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_02='startxfce4'
			REMOTE_DESKTOP_SESSION_01='xfce4-session'
		elif grep 'startlxde' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为lxde，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_02='startlxde'
			REMOTE_DESKTOP_SESSION_01='lxsession'
		elif grep 'startlxqt' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为lxqt，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_02='startlxqt'
			REMOTE_DESKTOP_SESSION_01='lxqt-session'
		elif grep 'mate-session' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为mate，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='mate-session'
			REMOTE_DESKTOP_SESSION_02='x-windows-manager'
		elif grep 'startplasma' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为KDE Plasma5，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='startkde'
			REMOTE_DESKTOP_SESSION_02='startplasma-x11'
		elif grep 'gnome-session' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为GNOME3，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='gnome-session'
			REMOTE_DESKTOP_SESSION_02='x-windows-manager'
		elif grep 'cinnamon' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为cinnamon，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='cinnamon-session'
			REMOTE_DESKTOP_SESSION_02='cinnamon-launcher'
		elif grep 'startdde' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为deepin desktop，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='startdde'
			REMOTE_DESKTOP_SESSION_02='x-windows-manager'
		else
			echo "未检测到vnc相关配置或您安装的桌面环境不被支持，请更新debian-i后再覆盖安装gui"
		fi
		enable_dbus_launch
	fi

	echo "${YELLOW}修改完成，按回车键返回${RESET}"
	echo "若无法修复，则请前往gitee.com/mo2/linux提交issue，并附上报错截图和详细说明。"
	echo "还建议您附上cat /usr/local/bin/startxsdl 和 cat ~/.vnc/xstartup 的启动脚本截图"
	press_enter_to_return
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
		press_enter_to_return
		tmoe_linux_tool_menu
	fi
}
##############
non_debian_function() {
	if [ "${LINUX_DISTRO}" != 'debian' ]; then
		echo "非常抱歉，本功能仅适配deb系发行版"
		echo "Sorry, this feature is only suitable for debian based distributions"
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
	echo "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
	echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
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
	echo "按${GREEN}回车键${RESET}${RED}重新安装${RESET},输${YELLOW}n${RESET}${BLUE}返回${RESET}"
	echo "输${YELLOW}m${RESET}打开${BLUE}管理菜单${RESET}"
	echo "${YELLOW}Do you want to reinstall it?[Y/m/n]${RESET}"
	echo "Press enter to reinstall,type n to return,type m to open management menu"
	read opt
	case $opt in
	y* | Y* | "") ;;
	n* | N*)
		echo "skipped."
		if_return_to_where_no_empty
		;;
	m* | M*)
		beta_features_management_menu
		;;
	*)
		echo "Invalid choice. skipped."
		if_return_to_where_no_empty
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
	echo "正在${YELLOW}安装${RESET}相关${GREEN}软件包${RESET}及其${BLUE}依赖...${RESET}"
	echo "${GREEN}${PACKAGES_INSTALL_COMMAND}${RESET} ${BLUE}${DEPENDENCY_01}${RESET} ${YELLOW}${DEPENDENCY_02}${RESET}"
	echo "Tmoe-linux tool will ${YELLOW}install${RESET} relevant ${BLUE}dependencies${RESET} for you."
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
#测试版功能可能无法正常运行\nBeta features may not work properly.
beta_features() {
	RETURN_TO_WHERE='beta_features'
	NON_DEBIAN='false'
	TMOE_BETA=$(
		whiptail --title "The Secret Garden" --menu "Welcome to the secret garden." 0 55 0 \
			"1" "💻container/vm:docker容器,qemu,vbox虚拟机" \
			"2" "⌨input method:输入法(搜狗,讯飞,百度)" \
			"3" "🥅network:网络(网卡驱动,WiFi扫描)" \
			"4" "📝read:墨纸留香,品味阅读" \
			"5" "🎬cut video:岁月静好,剪下佳刻" \
			"6" "🎨paint:融入意境,绘画真谛" \
			"7" "💾file:文件,浩如烟海" \
			"8" "👬SNS:进行物质和精神交流的社会活动的app" \
			"9" "🌼Store&download:繁花似锦,一切皆在此中" \
			"10" "🔨system:系统(启动项与用户组管理)" \
			"11" "🌌tech&edu:科技与教育" \
			"12" "🍕other:其它类(Android-studio,scrcpy)" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	##########
	case ${TMOE_BETA} in
	0 | "") tmoe_linux_tool_menu ;;
	1) install_container_and_virtual_machine ;;
	2) install_pinyin_input_method ;;
	3) network_manager_tui ;;
	4) tmoe_read_app_menu ;;
	5) tmoe_media_menu ;;
	6) tmoe_paint_app_menu ;;
	7) tmoe_file_browser_app_menu ;;
	8) tmoe_sns_app_menu ;;
	9) tmoe_store_app_menu ;;
	10) tmoe_system_app_menu ;;
	11) tmoe_education_app_menu ;;
	12) tmoe_other_app_menu ;;
	esac
	##############################
	press_enter_to_return
	beta_features
}
##########
tmoe_education_app_menu() {
	RETURN_TO_WHERE='tmoe_education_app_menu'
	NON_DEBIAN='false'
	DEPENDENCY_01=''
	TMOE_APP=$(whiptail --title "education" --menu \
		"Which software do you want to install？" 0 50 0 \
		"1" "geogebra(结合了“几何”、“代数”与“微积分”)" \
		"2" "kalzium(元素周期表)" \
		"3" "octave(GNU Octave语言,用于数值计算)" \
		"4" "scilab(用于数值计算的科学软件包)" \
		"5" "freemat(科学计算软件,类似于Matlab)" \
		"6" "maxima(数学软件,类似于Mathematica)" \
		"7" "goldendict(多功能字典查询程序)" \
		"8" "nwchem(运行在高性能工作站集群上的计算化学软件)" \
		"9" "avogadro(阿伏伽德罗-分子编辑器)" \
		"10" "pymol(分子三维结构显示软件)" \
		"11" "Psi4(量子化学程序集)" \
		"12" "gromacs(分子动力学模拟器)" \
		"13" "CP2K(第一性原理材料计算和模拟软件)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") beta_features ;;
	1) DEPENDENCY_02='geogebra' ;;
	2) DEPENDENCY_02='kalzium' ;;
	3) DEPENDENCY_02='octave' ;;
	4)
		DEPENDENCY_01='scilab-minimal-bin'
		DEPENDENCY_02='scilab'
		;;
	5)
		DEPENDENCY_01='freemat'
		DEPENDENCY_02='freemat-help'
		;;
	6)
		DEPENDENCY_01='maxima'
		DEPENDENCY_02='wxmaxima'
		;;
	7) DEPENDENCY_02='goldendict' ;;
	8) DEPENDENCY_02='nwchem' ;;
	9) DEPENDENCY_02='avogadro' ;;
	10) DEPENDENCY_02='pymol' ;;
	11) DEPENDENCY_02='psi4' ;;
	12) DEPENDENCY_02='gromacs' ;;
	13) DEPENDENCY_02='cp2k' ;;
	esac
	##########################
	beta_features_quick_install
	press_enter_to_return
	tmoe_education_app_menu
}
####################
tmoe_other_app_menu() {
	RETURN_TO_WHERE='tmoe_other_app_menu'
	NON_DEBIAN='false'
	DEPENDENCY_01=''
	TMOE_APP=$(
		whiptail --title "OTHER" --menu \
			"Which software do you want to install？" 0 50 0 \
			"1" "OBS-Studio(录屏软件)" \
			"2" "seahorse(密钥管理)" \
			"3" "kodi(家庭影院软件)" \
			"4" "Android-studio(安卓开发工具IDE)" \
			"5" "scrcpy(开源的Android投屏软件)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##########################
	case "${TMOE_APP}" in
	0 | "") beta_features ;;
	1) install_obs_studio ;;
	2) install_seahorse ;;
	3) install_kodi ;;
	4) install_android_studio ;;
	5) configure_scrcpy ;;
	esac
	##########################
	press_enter_to_return
	tmoe_other_app_menu
}
###################
configure_scrcpy() {
	RETURN_TO_WHERE='configure_scrcpy'
	DEPENDENCY_01=''
	SCRCPY_OPTION=$(
		whiptail --title "SCRCPY" --menu \
			"How do you want to configure the scrcpy?" 0 50 0 \
			"1" "install/remove(安装/卸载)" \
			"2" "connection连接管理" \
			"3" "switch device切换设备" \
			"4" "restart 重启adb" \
			"5" "readme连接说明" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##########################
	case "${SCRCPY_OPTION}" in
	0 | "") tmoe_other_app_menu ;;
	1) install_scrcpy ;;
	2) scrcpy_connect_to_android_device ;;
	3) switch_scrcpy_device ;;
	4) restart_adb ;;
	5) scrpy_faq ;;
	esac 
	#########################
	press_enter_to_return
	configure_scrcpy
}
##############
switch_scrcpy_device() {
	cd /tmp/
	adb devices 2>&1 | sed '1d;$d' | awk '{print $1}' >.tmoe-linux_cache.01
	adb devices -l 2>&1 | sed '1d;$d' | awk '{print $5,$4,$3}' | sed 's@model:@@g' | sed 's@-@_@g' | sed 's@product:@-@g' | sed 's@:@-@g' | sed 's@ @-@g' >.tmoe-linux_cache.02
	TMOE_ADB_DEVICE_LIST=$(paste -d ' ' .tmoe-linux_cache.01 .tmoe-linux_cache.02 | sed ":a;N;s/\n/ /g;ta")
	cat .tmoe-linux_cache.0*
	echo ${TMOE_ADB_DEVICE_LIST}
	TMOE_ADB_DEVICE_ITEM=$(whiptail --title "SCRCPY DEVICES" --menu \
		"您想要切换至哪个设备？\nWhich device do you want to switch?" 0 0 0 \
		${TMOE_ADB_DEVICE_LIST} \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	case ${TMOE_ADB_DEVICE_ITEM} in
	0 | "") configure_scrcpy ;;
	esac
	echo "scrcpy -s ${TMOE_ADB_DEVICE_ITEM}"
	scrcpy -s ${TMOE_ADB_DEVICE_ITEM}
}
#############
scrpy_faq() {
	cat <<-EOF
		    tightvnc可能无法正常启动本应用（scrcpy）,您可以在x11vnc环境下启动它。
		    启动前请先确保adb已正常连接至您的安卓设备。
		    若adb无法连接，则请重启adb服务。
			启动本应用的命令为${GREEN}scrcpy${RESET}
			使用说明详见https://github.com/Genymobile/scrcpy/blob/master/README.md
			https://www.iplaysoft.com/scrcpy.html
		关闭手机屏幕  scrcpy -S
		限制画面分辨率 scrcpy -m 1024 (比如限制为 1024)
		修改视频码率  scrcpy -b 4M (默认 8Mbps，改成 4Mbps)
		裁剪画面    scrcpy -c 1920:1080:0:0
		表示分辨率 1920x1080 并且偏移坐标为 (0,0)
		窗口置顶   scrcpy -T
		显示触摸点击 scrcpy -t
		在演示或录制教程时，可在画面上对应显示出点击动作
		全屏显示     scrcpy -f
		文件传输默认路径 scrcpy --push-target /你的/目录
		将文件拖放到 scrcpy 可以传输文件，此命令指定默认保存目录
		只读模式(仅显示不控制)  scrcpy -n
		屏幕录像          scrcpy -r 视频文件名.mp4 或 .mkv
		屏幕录像 (禁用电脑显示) scrcpy -Nr 文件名.mkv
		设置窗口标题        scrcpy --window-title '2333'
	EOF
}
###############
scrcpy_connect_to_android_device() {
	#请输入adb
	TARGET=$(whiptail --inputbox "① 若Android无root权限，且系统未自带ADB网络调试功能，则请开启USB调试功能，并使用USB数据线连接本机（Linux设备)。\n② 若Android无root权限，且系统自带ADB网络调试功能，则请同时开启USB和网络调试功能，您无需使用数据线即可连接。\n③ 若Android有root权限，则您可以通过安装网络ADB调试软件https://coolapk.com/apk/com.yaerin.wadb 来开启网络ADB调试功能。 \n请输入adb连接地址，例如192.168.99.3:5555。若不添加端口,则使用默认值" 0 0 --title "Please type the adb address" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
		echo "检测到您未输入有效的adb地址，已自动调整为localhost:5555"
	else
		if [ ! $(echo ${TARGET} | grep ':') ]; then
			TARGET=${TARGET}:5555
			echo "检测到您未添加端口，已将端口修改为5555"
		fi
	fi
	echo "正在通过ADB连接至Android设备..."
	echo "${BLUE}adb connect ${TARGET}${RESET}"
	echo "Connecting to adb device..."
	adb connect ${TARGET}
	adb devices -l
	echo "您可以在x11VNC下使用scrcpy来启动本应用"
	echo "您是否需要立刻启动scrcpy?"
	do_you_want_to_continue
	scrcpy
}
##################
restart_adb() {
	adb kill-server
	adb devices -l
}
###########
install_scrcpy() {
	DEPENDENCY_02='scrcpy'
	beta_features_quick_install
}
############
creat_android_studio_application_link() {
	cd /usr/share/applications
	#Icon=android-studio
	cat >android_studio.desktop <<-'EOF'
		[Desktop Entry]
		Name=Android Studio
		Type=Application
		Comment=Android Studio provides the fastest tools for building apps on every type of Android device.
		Exec=/opt/android-studio/bin/studio.sh %F
		Icon=/opt/android-studio/bin/studio.svg
		Categories=TextEditor;Development;IDE;
		MimeType=text/plain;inode/directory;
		Terminal=false
		Actions=new-empty-window;
		StartupNotify=true
		StartupWMClass=Android-Studio
	EOF
	chmod +x android_studio.desktop
}
#########################
download_android_studio() {
	THE_LATEST_DEB_LINK="$(curl -Lv 'https://developer.android.google.cn/studio/#downloads' | grep 'linux' | grep href | grep studio | tail -n 1 | cut -d '"' -f 2)"
	echo ${THE_LATEST_DEB_LINK}
	echo "Do you want to download and install it?"
	do_you_want_to_continue
	aria2c --allow-overwrite=true -s 10 -x 10 -k 1M -o android_studio_linux_64bit.tar.gz ${THE_LATEST_DEB_LINK}
}
###############
check_android_studio() {
	mkdir -p ${HOME}/sd/Download
	cd ${HOME}/sd/Download
	if [ -e "/opt/android-studio" ]; then
		echo '您已安装Android studio'
		echo "若您需要卸载，则请输${RED}rm -rv${RESET} ${HOME}/sd/Download/android_studio_linux_64bit.tar.gz ${BLUE}/opt/android-studio /usr/share/applications/android_studio.desktop${RESET};${RED}${PACKAGES_REMOVE_COMMAND}${RESET} ${BLUE}default-jre${RESET}"
		echo "是否需要重新安装？"
		echo "Do you want to reinstall it?"
		do_you_want_to_continue
	fi
	if [ ! -e "android_studio_linux_64bit.tar.gz" ]; then
		download_android_studio
	fi
	DEPENDENCY_01=''
	if [ ! $(command -v java) ]; then
		case "${LINUX_DISTRO}" in
		arch) DEPENDENCY_02='jre-openjdk' ;;
		debian | "") DEPENDENCY_02='default-jre' ;;
		alpine) DEPENDENCY_02='openjdk11-jre' ;;
		redhat | *) DEPENDENCY_02='java' ;;
		esac
		beta_features_quick_install
	fi
}
##############
install_android_studio() {
	check_android_studio
	tar -zxvf android_studio_linux_64bit.tar.gz -C /opt
	creat_android_studio_application_link
	echo "安装完成，如需卸载，则请输${RED}rm -rv${RESET} ${BLUE}/opt/android-studio /usr/share/applications/android_studio.desktop${RESET};${RED}${PACKAGES_REMOVE_COMMAND}${RESET} ${BLUE}default-jre${RESET}"
}
##################
install_seahorse() {
	DEPENDENCY_02='seahorse'
	beta_features_quick_install
}
###################
install_kodi() {
	DEPENDENCY_01='kodi'
	DEPENDENCY_02='kodi-wayland'
	beta_features_quick_install
}
######################
tmoe_system_app_menu() {
	RETURN_TO_WHERE='tmoe_system_app_menu'
	NON_DEBIAN='false'
	TMOE_APP=$(whiptail --title "SYSTEM" --menu \
		"Which software do you want to install？" 0 50 0 \
		"1" "UEFI bootmgr:开机启动项管理" \
		"2" "gnome-system-monitor(资源监视器)" \
		"3" "Grub Customizer(图形化开机引导编辑器)" \
		"4" "gnome log(便于查看系统日志信息)" \
		"5" "boot repair(开机引导修复)" \
		"6" "neofetch(显示当前系统信息和发行版logo)" \
		"7" "yasat:简单的安全审计工具" \
		"8" "rc.local-systemd:修改开机自启动脚本" \
		"9" "sudo user group management:sudo用户组管理" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") beta_features ;;
	1) tmoe_uefi_boot_manager ;;
	2) install_gnome_system_monitor ;;
	3) install_grub_customizer ;;
	4) install_gnome_logs ;;
	5) install_boot_repair ;;
	6) start_neofetch ;;
	7) start_yasat ;;
	8) modify_rc_local_script ;;
	9) tmoe_linux_sudo_user_group_management ;;
	esac
	##########################
	press_enter_to_return
	tmoe_system_app_menu
}
#############
tmoe_linux_sudo_user_group_management() {
	RETURN_TO_WHERE='tmoe_linux_sudo_user_group_management'
	cd /tmp/
	cat /etc/passwd | grep -Ev 'nologin|halt|shutdown|0:0' | awk -F ':' '{ print $1}' >.tmoe-linux_cache.01
	cat /etc/passwd | grep -Ev 'nologin|halt|shutdown|0:0' | awk -F ':' '{ print $3"|"$4 }' >.tmoe-linux_cache.02
	TMOE_USER_LIST=$(paste -d ' ' .tmoe-linux_cache.01 .tmoe-linux_cache.02 | sed ":a;N;s/\n/ /g;ta")
	rm -f .tmoe-linux_cache.0*
	TMOE_USER_NAME=$(whiptail --title "USER LIST" --menu \
		"您想要将哪个小可爱添加至sudo用户组？\n Which member do you want to add to the sudo group?" 0 0 0 \
		${TMOE_USER_LIST} \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	case ${TMOE_USER_NAME} in
	0 | "") tmoe_system_app_menu ;;
	esac

	SUDO_YES='back返回'
	SUDO_RETURN='true'
	if [ $(cat /etc/sudoers | awk '{print $1}' | grep ${TMOE_USER_NAME}) ]; then
		SUDO_USER_STATUS="检测到${TMOE_USER_NAME}已经是这个家庭的成员啦,ta位于/etc/sudoers文件中"
	elif [ $(cat /etc/group | grep sudo | cut -d ':' -f 4 | grep ${TMOE_USER_NAME}) ]; then
		SUDO_USER_STATUS="检测到${TMOE_USER_NAME}已经是这个家庭的成员啦,ta位于/etc/group文件中"
	else
		SUDO_USER_STATUS="检测到${TMOE_USER_NAME}可能不在sudo用户组里"
		SUDO_YES='add添加♪^∇^*'
		SUDO_RETURN='false'
	fi

	if (whiptail --title "您想要对这个小可爱做什么" --yes-button "${SUDO_YES}" --no-button "del踢走っ °Д °;" --yesno "Do you want to add it to sudo group,or remove it from sudo?\n${SUDO_USER_STATUS}\n您是想要把ta加进sudo这个小家庭，还是踢走ta呢？" 0 50); then
		if [ "${SUDO_RETURN}" = "true" ]; then
			tmoe_linux_sudo_user_group_management
		else
			add_tmoe_sudo
		fi
	else
		del_tmoe_sudo
	fi
	##########################
	press_enter_to_return
	tmoe_linux_sudo_user_group_management
}
##################
del_tmoe_sudo() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		deluser ${TMOE_USER_NAME} sudo || remove_him_from_sudoers
	else
		remove_him_from_sudoers
	fi

	if [ "$?" = '0' ]; then
		echo "${YELLOW}${TMOE_USER_NAME}${RESET}小可爱非常伤心（；´д｀）ゞ，因为您将其移出了${BLUE}sudo${RESET}用户组"
	else
		echo "Sorry,移除${RED}失败${RESET}"
	fi
}
#################
add_tmoe_sudo() {
	#if [ "${LINUX_DISTRO}" = "debian" ]; then
	#	adduser ${TMOE_USER_NAME} sudo
	#else
	add_him_to_sudoers
	#fi

	if [ "$?" = '0' ]; then
		echo "Congratulations,已经将${YELLOW}${TMOE_USER_NAME}${RESET}小可爱添加至${BLUE}sudo${RESET}用户组(｡･∀･)ﾉﾞ"
	else
		echo "Sorry,添加${RED}失败${RESET}"
	fi
}
############
remove_him_from_sudoers() {
	cd /etc
	TMOE_USER_SUDO_LINE=$(cat sudoers | grep -n "^${TMOE_USER_NAME}.*ALL" | tail -n 1 | cut -d ':' -f 1)
	if [ -z "${TMOE_USER_SUDO_LINE}" ]; then
		echo "检测到${YELLOW}${TMOE_USER_NAME}${RESET}不在${BLUE}sudo${RESET}用户组中，此事将不会被报告||o(*°▽°*)o|Юﾞ"
	else
		sed -i "${TMOE_USER_SUDO_LINE}d" sudoers
	fi
}
############
add_him_to_sudoers() {
	TMOE_ROOT_SUDO_LINE=$(cat /etc/sudoers | grep 'root.*ALL' -n | tail -n 1 | cut -d ':' -f 1)
	#TMOE_USER_SUDO_LINE=$((${TMOE_ROOT_SUDO_LINE} + 1))
	if [ -z "${TMOE_ROOT_SUDO_LINE}" ]; then
		sed -i "$ a ${TMOE_USER_NAME}    ALL=(ALL:ALL) ALL" /etc/sudoers
	else
		sed -i "${TMOE_ROOT_SUDO_LINE}a ${TMOE_USER_NAME}    ALL=(ALL:ALL) ALL" /etc/sudoers
	fi
	cat /etc/sudoers
}
###############
creat_rc_local_startup_script() {
	cat >rc.local <<'ENDOFRCLOCAL'
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
# 请在 exit0 这一行(最末行)以上之处添加您在开机时需要执行的脚本或命令。
# 例如:您写了一个开机自动挂载硬盘的脚本，该文件位于/usr/local/bin/mount-zfs-filesystem
# 注：对于外置USB硬盘盒而言，若将其写进/etc/fstab，且硬盘在系统开机前未连接或连接不稳定，则有可能导致开机出现异常，故您使用了脚本来解决。
# 若您需要在开机时自动执行该脚本，则您可以输入以下那一行命令。
# bash /usr/local/bin/mount-zfs-filesystem
# '#'为注释符号，去掉该符号生效。

exit 0
ENDOFRCLOCAL
	chmod +x rc.local
	systemctl daemon-reload 2>/dev/null
}
#################
creat_rc_local_systemd_script() {
	cat >/etc/systemd/system/rc-local.service <<-'ENDOFSYSTEMD'
		[Unit]
		Description=/etc/rc.local
		ConditionPathExists=/etc/rc.local
		 
		[Service]
		Type=forking
		ExecStart=/etc/rc.local start
		TimeoutSec=0
		StandardOutput=tty
		RemainAfterExit=yes
		SysVStartPriority=99
		 
		[Install]
		WantedBy=multi-user.target
	ENDOFSYSTEMD
}
#################
modify_rc_local_script() {
	cd /etc
	if [ ! -e "rc.local" ]; then
		creat_rc_local_startup_script
	fi
	cat <<-EOF
		${GREEN}systemctl enable rc-local${RESET}  ${BLUE}--开机自启${RESET}
		${GREEN}systemctl disable rc-local${RESET}  ${BLUE}--禁用开机自启${RESET}
		${GREEN}systemctl status rc-local${RESET}  ${BLUE}--查看该服务进程状态${RESET}
		${GREEN}systemctl start rc-local${RESET}  ${BLUE}--启动${RESET}
		${GREEN}systemctl stop rc-local${RESET}  ${BLUE}--停止${RESET}
	EOF

	if [ ! -e "/etc/systemd/system/rc-local.service" ]; then
		creat_rc_local_systemd_script
		nano rc.local
		echo "是否将其设置为开机自启？"
		do_you_want_to_continue
		systemctl enable rc-local.service
	else
		nano rc.local
	fi
}
##################
start_neofetch() {
	if [ ! $(command -v neofetch) ]; then
		cd /usr/local/bin
		aria2c --allow-overwrite=true -o neofetch 'https://gitee.com/mirrors/neofetch/raw/master/neofetch'
		chmod +x neofetch
	fi
	neofetch
}
#############
start_yasat() {
	if [ ! $(command -v yasat) ]; then
		DEPENDENCY_01=''
		DEPENDENCY_02='yasat'
		beta_features_quick_install
	fi
	yasat --full-scan
}
############
install_boot_repair() {
	non_debian_function
	if [ ! $(command -v add-apt-repository) ]; then
		apt update
		apt install -y software-properties-common
	fi
	add-apt-repository ppa:yannubuntu/boot-repair
	if [ "${DEBIAN_DISTRO}" != 'ubuntu' ]; then
		apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 60D8DA0B
	fi
	apt update
	apt install -y boot-repair
}
#################
tmoe_store_app_menu() {
	RETURN_TO_WHERE='tmoe_store_app_menu'
	NON_DEBIAN='false'
	TMOE_APP=$(whiptail --title "商店与下载工具" --menu \
		"Which software do you want to install？" 0 50 0 \
		"1" "aptitude:基于终端的软件包管理器" \
		"2" "deepin:深度软件" \
		"3" "gnome-software(软件商店)" \
		"4" "plasma-discover(KDE发现-软件中心)" \
		"5" "Flatpak(跨平台包管理,便捷安装tim等软件)" \
		"6" "snap(ubuntu母公司开发的跨平台商店)" \
		"7" "bauh(旨在处理Flatpak,Snap,AppImage和AUR)" \
		"8" "qbittorrent(P2P下载工具)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") beta_features ;;
	1)
		non_debian_function
		aptitude
		;;
	2) install_deepin_software_menu ;;
	3) install_gnome_software ;;
	4) install_plasma_discover ;;
	5) install_flatpak_store ;;
	6) install_snap_store ;;
	7) install_bauh_store ;;
	8) install_qbitorrent ;;
	esac
	##########################
	press_enter_to_return
	tmoe_store_app_menu
}
#############
#################
install_deepin_software_menu() {
	RETURN_TO_WHERE='install_deepin_software_menu'
	NON_DEBIAN='true'
	DEPENDENCY_01=""
	TMOE_APP=$(whiptail --title "deepin store" --menu \
		"Which software do you want to install？" 0 50 0 \
		"01" "dde-calendar(深度日历)" \
		"02" "dde-qt5integration(Qt5 theme integration)" \
		"03" "deepin-calculator(计算器)" \
		"04" "deepin-deb-installer(软件包安装器)" \
		"05" "deepin-gettext-tools(Deepin国际化工具)" \
		"06" "deepin-image-viewer(图像查看器)" \
		"07" "deepin-menu(Deepin 菜单服务)" \
		"08" "deepin-movie(电影播放器)" \
		"09" "deepin-music(音乐播放器 with brilliant and tweakful UI)" \
		"10" "deepin-notifications(系统通知)" \
		"11" "deepin-picker(深度取色器)" \
		"12" "deepin-screen-recorder(简单录屏工具)" \
		"13" "deepin-screenshot(高级截图工具)" \
		"14" "deepin-shortcut-viewer(弹出式快捷键查看器)" \
		"15" "deepin-terminal(深度终端模拟器)" \
		"16" "deepin-voice-recorder(录音器)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") tmoe_store_app_menu ;;
	01) DEPENDENCY_02="dde-calendar" ;;
	02) DEPENDENCY_02="dde-qt5integration" ;;
	03) DEPENDENCY_02="deepin-calculator" ;;
	04) DEPENDENCY_02="deepin-deb-installer" ;;
	05) DEPENDENCY_02="deepin-gettext-tools" ;;
	06) DEPENDENCY_02="deepin-image-viewer" ;;
	07) DEPENDENCY_02="deepin-menu" ;;
	08) DEPENDENCY_02="deepin-movie" ;;
	09) DEPENDENCY_02="deepin-music" ;;
	10) DEPENDENCY_02="deepin-notifications" ;;
	11) DEPENDENCY_02="deepin-picker" ;;
	12) DEPENDENCY_02="deepin-screen-recorder" ;;
	13) DEPENDENCY_02="deepin-screenshot" ;;
	14) DEPENDENCY_02="deepin-shortcut-viewer" ;;
	15) DEPENDENCY_02="deepin-terminal" ;;
	16) DEPENDENCY_02="deepin-voice-recorder" ;;
	esac
	##########################
	beta_features_quick_install
	press_enter_to_return
	install_deepin_software_menu
}
#######################
install_bauh_store() {
	if [ ! $(command -v pip3) ]; then
		DEPENDENCY_01="python3-pip"
		DEPENDENCY_02="python-pip"
		beta_features_quick_install
	fi
	pip3 install bauh
}
#############
install_snap_store() {
	echo 'web store url:https://snapcraft.io/store'
	DEPENDENCY_01="snapd"
	DEPENDENCY_02="gnome-software-plugin-snap"
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="snapd"
		DEPENDENCY_02="snapd-xdg-open-git"
	fi
	beta_features_quick_install
	echo '前往在线商店,获取更多应用'
	echo 'https://snapcraft.io/store'
	snap install snap-store
}
#############
install_flatpak_store() {
	DEPENDENCY_01="flatpak"
	DEPENDENCY_02="gnome-software-plugin-flatpak"
	echo 'web store url:https://flathub.org/'
	if [ "${LINUX_DISTRO}" = "gentoo" ]; then
		echo 'gentoo用户请前往此处阅读详细说明'
		echo 'https://github.com/fosero/flatpak-overlay'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02="gnome-software-packagekit-plugin"
	fi
	beta_features_quick_install
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	echo '前往在线商店,获取更多应用'
	echo 'https://flathub.org/apps'
}
#############
tmoe_sns_app_menu() {
	RETURN_TO_WHERE='tmoe_sns_app_menu'
	NON_DEBIAN='false'
	TMOE_APP=$(whiptail --title "SNS" --menu \
		"Which software do you want to install？" 0 50 0 \
		"1" "electronic-wechat(第三方微信客户端)" \
		"2" "telegram(注重保护隐私的社交app)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") beta_features ;;
	1) install_electronic_wechat ;;
	2) install_telegram ;;
	esac
	##########################
	press_enter_to_return
	tmoe_sns_app_menu
}
###################
tmoe_paint_app_menu() {
	RETURN_TO_WHERE='tmoe_paint_app_menu'
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	TMOE_APP=$(
		whiptail --title "绘图/制图app" --menu \
			"Which software do you want to install？" 0 50 0 \
			"1" "krita(由KDE社区驱动的开源数字绘画应用)" \
			"2" "inkscape(强大的矢量图绘制工具)" \
			"3" "kolourpaint(KDE画图程序,简单易用)" \
			"4" "R language:R语言用于统计分析,图形表示和报告" \
			"5" "latexdraw(用java开发的示意图绘制软件)" \
			"6" "LibreCAD(轻量化的2D CAD解决方案)" \
			"7" "FreeCAD(以构建机械工程和产品设计为目标)" \
			"8" "OpenCAD(通过解释代码来渲染可视化模型)" \
			"9" "KiCAD(开源的PCB设计工具)" \
			"10" "OpenSCAD(3D建模软件)" \
			"11" "gnuplot(命令行交互式绘图工具)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##########################
	case "${TMOE_APP}" in
	0 | "") beta_features ;;
	1)
		DEPENDENCY_01="krita"
		DEPENDENCY_02="krita-l10n"
		;;
	2)
		DEPENDENCY_01="inkscape-tutorials"
		DEPENDENCY_02="inkscape"
		;;
	3) DEPENDENCY_02="kolourpaint" ;;
	4) tmoe_r_language_menu ;;
	5) DEPENDENCY_02="latexdraw" ;;
	6) DEPENDENCY_02="librecad" ;;
	7) DEPENDENCY_02="freecad" ;;
	8) DEPENDENCY_02="opencad" ;;
	9)
		DEPENDENCY_01="kicad-templates"
		DEPENDENCY_02="kicad"
		;;
	10) DEPENDENCY_02="openscad" ;;
	11)
		DEPENDENCY_01="gnuplot"
		DEPENDENCY_02="gnuplot-x11"
		;;
	esac
	##########################
	beta_features_quick_install
	press_enter_to_return
	tmoe_paint_app_menu
}
###################
tmoe_r_language_menu() {
	RETURN_TO_WHERE='tmoe_r_language_menu'
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	TMOE_APP=$(
		whiptail --title "R" --menu \
			"Which software do you want to install?" 0 50 0 \
			"1" "r-base(GNU R statistical computation and graphics system)" \
			"2" "RStudio(x64,R语言IDE)" \
			"3" "r-recommended(kernsmooth,lattice,mgcv,nlme,rpart,matrix,etc.)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##########################
	case "${TMOE_APP}" in
	0 | "") tmoe_paint_app_menu ;;
	1) install_r_base ;;
	2) install_r_studio ;;
	3) install_r_recommended ;;
	esac
	##########################
	press_enter_to_return
	tmoe_r_language_menu
}
#############
check_rstudio_version() {
	THE_LATEST_ISO_LINK="$(curl -L ${REPO_URL} | grep ${GREP_NAME} | grep 'http' | sed -n 2p | cut -d '=' -f 2 | cut -d '"' -f 2)"
	THE_LATEST_DEB_VERSION=$(echo ${THE_LATEST_ISO_LINK} | sed 's@/@ @g' | awk -F ' ' '$0=$NF')
	aria2c_download_file
}
##############
install_r_studio() {
	if [ "${ARCH_TYPE}" != 'amd64' ]; then
		arch_does_not_support
	fi
	REPO_URL='https://rstudio.com/products/rstudio/download/#download'

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		GREP_NAME='amd64.deb'
		check_rstudio_version
		apt show ./${THE_LATEST_DEB_VERSION}
		apt install -y ./${THE_LATEST_DEB_VERSION}
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		GREP_NAME='x86_64.rpm'
		check_rstudio_version
		rpm -ivh ./${THE_LATEST_DEB_VERSION}
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02="rstudio-desktop-git"
		beta_features_quick_install
	else
		non_debian_function
	fi
}
#####################
install_r_base() {
	DEPENDENCY_02="r-base"
	beta_features_quick_install
}
#############
install_r_recommended() {
	DEPENDENCY_02="r-recommended"
	beta_features_quick_install
}
#############
tmoe_file_browser_app_menu() {
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	RETURN_TO_WHERE='tmoe_file_browser_app_menu'
	TMOE_APP=$(whiptail --title "文件与磁盘" --menu \
		"Which software do you want to install？" 0 50 0 \
		"1" "文件管理器:thunar/nautilus/dolphin" \
		"2" "catfish(文件搜索)" \
		"3" "gparted(强大的GNOME分区编辑器)" \
		"4" "baobab(直观易用的GNOME磁盘空间占用分析器)" \
		"5" "cfdisk:在终端下对磁盘进行分区" \
		"6" "partitionmanager(KDE磁盘分区工具)" \
		"7" "mc:终端下的文件管理器" \
		"8" "ranger:带有VI键绑定的控制台文件管理器" \
		"9" "gnome-disks(实用的磁盘管理工具)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	#"9" "disk-manager(简单易用的分区挂载工具)" \
	#此软件包依赖python2，已被移除
	case "${TMOE_APP}" in
	0 | "") beta_features ;;
	1) thunar_nautilus_dolphion ;;
	2) install_catfish ;;
	3) install_gparted ;;
	4) install_baobab ;;
	5) start_cfdisk ;;
	6) install_partitionmanager ;;
	7) install_mc_fm ;;
	8) install_ranger_fm ;;
	9) install_gnome_disk_utility ;;
	esac
	##########################
	press_enter_to_return
	tmoe_file_browser_app_menu
}
#############
install_mc_fm() {
	if [ ! $(command -v mc) ]; then
		DEPENDENCY_02="mc"
		beta_features_quick_install
		echo "安装完成，您之后可以输mc启动"
	fi
	mc
}
###########
install_ranger_fm() {
	if [ ! $(command -v ranger) ]; then
		DEPENDENCY_02="ranger"
		beta_features_quick_install
		echo "安装完成，您之后可以输ranger启动"
	fi
	ranger
}
#############
start_cfdisk() {
	if [ ! $(command -v cfdisk) ]; then
		DEPENDENCY_02="util-linux"
		beta_features_quick_install
	fi
	cfdisk
}
##################
install_gnome_disk_utility() {
	DEPENDENCY_02="gnome-disk-utility"
	beta_features_quick_install
}
##################
install_partitionmanager() {
	DEPENDENCY_02="partitionmanager"
	beta_features_quick_install
}
##################
install_baobab() {
	DEPENDENCY_02="baobab"
	beta_features_quick_install
}
############
install_gparted() {
	DEPENDENCY_02="gparted"
	beta_features_quick_install
}
##################
tmoe_read_app_menu() {
	RETURN_TO_WHERE='tmoe_read_app_menu'
	TMOE_APP=$(whiptail --title "TXET & OFFICE" --menu \
		"Which software do you want to install？" 0 50 0 \
		"1" "calibre(电子书转换器和库管理)" \
		"2" "fbreader(epub阅读器)" \
		"3" "WPS office(办公软件)" \
		"4" "typora(markdown编辑器)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") beta_features ;;
	1) install_calibre ;;
	2) install_fbreader ;;
	3) install_wps_office ;;
	4) install_typora ;;
	esac
	##########################
	#beta_features_quick_install
	press_enter_to_return
	tmoe_read_app_menu
}
#############
tmoe_media_menu() {
	RETURN_TO_WHERE='tmoe_media_menu'
	DEPENDENCY_01=''
	NON_DEBIAN='false'
	BEAUTIFICATION=$(whiptail --title "多媒体文件制作与剪辑" --menu \
		"Which software do you want to install？" 0 50 0 \
		"1" "openshot(界面简单,多用途)" \
		"2" "blender(工业级,用于电影制作和设计3D模型)" \
		"3" "kdenlive(来自KDE的开源视频编辑器)" \
		"4" "mkvtoolnix-gui(分割,编辑,混流,分离,合并和提取mkv)" \
		"5" "flowblade(旨在提供一个快速,精确的功能)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${BEAUTIFICATION}" in
	0 | "") beta_features ;;
	1) DEPENDENCY_02="openshot" ;;
	2) DEPENDENCY_02="blender" ;;
	3) DEPENDENCY_02="kdenlive" ;;
	4) DEPENDENCY_02="mkvtoolnix-gui" ;;
	5) DEPENDENCY_02='flowblade' ;;
	esac
	##########################
	beta_features_quick_install
	press_enter_to_return
	tmoe_media_menu
}
#############
network_manager_tui() {
	NON_DEBIAN='false'
	DEPENDENCY_01=''
	NON_DEBIAN='false'
	if [ ! $(command -v nmtui) ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_02='network-manager'
		elif [ "${LINUX_DISTRO}" = "redhat" ]; then
			DEPENDENCY_02='NetworkManager-tui'
		else
			DEPENDENCY_02='networkmanager'
		fi
		beta_features_quick_install
	fi

	if [ ! $(command -v ip) ]; then
		DEPENDENCY_02='iproute2'
		echo "${GREEN}${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_02}${RESET}"
		${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_02}
	fi

	if grep -q 'managed=false' /etc/NetworkManager/NetworkManager.conf; then
		sed -i 's@managed=false@managed=true@' /etc/NetworkManager/NetworkManager.conf
	fi
	pgrep NetworkManager >/dev/null
	if [ "$?" != "0" ]; then
		if [ "${LINUX_DISTRO}" = "alpine" ]; then
			service networkmanager start
		else
			systemctl start NetworkManager || service NetworkManager start || service networkmanager start
		fi
	fi
	RETURN_TO_WHERE='network_manager_tui'
	NETWORK_MANAGER=$(whiptail --title "NETWORK" --menu \
		"您想要如何配置网络？\n How do you want to configure the network? " 17 50 8 \
		"1" "manager:管理器" \
		"2" "enable device:启用设备" \
		"3" "WiFi scan:扫描" \
		"4" "device status:设备状态" \
		"5" "driver:网卡驱动" \
		"6" "View ip address:查看ip" \
		"7" "edit config manually:手动编辑" \
		"8" "systemctl enable NetworkManager开机自启" \
		"9" "blueman(蓝牙管理器,GTK+前端)" \
		"10" "gnome-nettool(网络工具)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${NETWORK_MANAGER}" in
	0 | "") beta_features ;;
	1)
		nmtui
		network_manager_tui
		;;
	2)
		enable_netword_card
		;;
	3)
		tmoe_wifi_scan
		;;
	4)
		network_devices_status
		;;
	5)
		install_debian_nonfree_network_card_driver
		;;
	6)
		ip a
		ip -br -c a
		if [ ! -z $(echo ${LANG} | grep zh) ]; then
			curl -L myip.ipip.net
		else
			curl -L ip.cip.cc
		fi
		;;
	7)
		nano /etc/NetworkManager/system-connections/*
		nano /etc/NetworkManager/NetworkManager.conf
		nano /etc/network/interfaces.d/*
		nano /etc/network/interfaces
		;;
	8)
		if [ "${LINUX_DISTRO}" = "alpine" ]; then
			TMOE_DEPENDENCY_SYSTEMCTL='networkmanager'
		else
			TMOE_DEPENDENCY_SYSTEMCTL='NetworkManager'
		fi

		if (whiptail --title "您想要对这个小可爱做什么" --yes-button "ENABLE启用" --no-button "DISABLE禁用" --yesno "您是否需要启用网络管理器开机自启的功能？♪(^∇^*) " 0 50); then
			echo "${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
			systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}
			if [ "$?" = "0" ]; then
				echo "已添加至自启任务"
			else
				echo "添加自启任务失败"
			fi
		else
			echo "${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
			systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}
		fi
		;;
	9) install_blueman ;;
	10) install_gnome_net_manager ;;
	esac
	##########################
	press_enter_to_return
	network_manager_tui
}
###########
################
install_gnome_net_manager() {
	DEPENDENCY_01="gnome-nettool"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_02="network-manager-gnome"
	else
		DEPENDENCY_02="gnome-network-manager"
	fi

	beta_features_quick_install
}
######################
install_blueman() {
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01='gnome-bluetooth'
	else
		DEPENDENCY_01='blueman-manager'
	fi
	DEPENDENCY_02='blueman'
	beta_features_quick_install
}
##################
tmoe_wifi_scan() {
	DEPENDENCY_01=''
	if [ ! $(command -v iw) ]; then
		DEPENDENCY_02='iw'
		beta_features_quick_install
	fi

	if [ ! $(command -v iwlist) ]; then
		if [ "${LINUX_DISTRO}" = "arch" ]; then
			DEPENDENCY_02='wireless_tools'
		else
			DEPENDENCY_02='wireless-tools'
		fi
		beta_features_quick_install
	fi

	if [ "${LINUX_DISTRO}" = "arch" ]; then
		if [ ! $(command -v wifi-menu) ]; then
			DEPENDENCY_01='wpa_supplicant'
			DEPENDENCY_02='netctl'
			beta_features_quick_install
		fi
		if [ ! $(command -v dialog) ]; then
			DEPENDENCY_01=''
			DEPENDENCY_02='dialog'
			beta_features_quick_install
		fi
		wifi-menu
	fi
	echo 'scanning...'
	echo '正在扫描中...'
	cd /tmp
	iwlist scan 2>/dev/null | tee .tmoe_wifi_scan_cache
	echo '-------------------------------'
	cat .tmoe_wifi_scan_cache | grep --color=auto -i 'SSID'
	rm -f .tmoe_wifi_scan_cache
}
##############
network_devices_status() {
	iw phy
	echo '-------------------------------'
	nmcli device show 2>&1 | head -n 100
	echo '-------------------------------'
	nmcli connection show
	echo '-------------------------------'
	iw dev
	echo '-------------------------------'
	nmcli radio
	echo '-------------------------------'
	nmcli device
}
#############
check_debian_nonfree_source() {
	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		if [ "${DEBIAN_DISTRO}" != 'ubuntu' ]; then
			if ! grep -q '^deb.*non-free' /etc/apt/sources.list; then
				echo '是否需要添加debian non-free软件源？'
				echo 'Do you want to add non-free source.list?'
				do_you_want_to_continue
				sed -i '$ a\deb https://mirrors.huaweicloud.com/debian/ stable non-free' /etc/apt/sources.list
				apt update
			fi
		fi
	fi
}
##################
install_debian_nonfree_network_card_driver() {
	RETURN_TO_WHERE='install_debian_nonfree_network_card_driver'
	check_debian_nonfree_source
	DEPENDENCY_01=''
	NETWORK_MANAGER=$(whiptail --title "你想要安装哪个驱动？" --menu \
		"Which driver do you want to install?" 15 50 7 \
		"1" "list devices查看设备列表" \
		"2" "Intel Wireless cards嘤(英)特尔" \
		"3" "Realtek wired/wifi/BT adapters瑞昱" \
		"4" "Marvell wireless cards美满" \
		"5" "TI Connectivity wifi/BT/FM/GPS" \
		"6" "Broadcom博通" \
		"7" "misc(Ralink,etc.)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${NETWORK_MANAGER}" in
	0 | "") network_manager_tui ;;
	1) list_network_devices ;;
	2) DEPENDENCY_02='firmware-iwlwifi' ;;
	3) DEPENDENCY_02='firmware-realtek' ;;
	4) DEPENDENCY_02='firmware-libertas' ;;
	5) DEPENDENCY_02='firmware-ti-connectivity' ;;
	6) DEPENDENCY_02='firmware-brcm80211' ;;
	7) install_linux_firmware_nonfree ;;
	esac
	##########################
	if (whiptail --title "您想要对这个小可爱做什么" --yes-button "install安装" --no-button "Download下载" --yesno "您是想要直接安装，还是下载驱动安装包? ♪(^∇^*) " 8 50); then
		do_you_want_to_continue
		beta_features_quick_install
	else
		download_network_card_driver
	fi
	press_enter_to_return
	install_debian_nonfree_network_card_driver
}
#############
install_linux_firmware_nonfree() {
	DEPENDENCY_02='firmware-misc-nonfree'
	case "${LINUX_DISTRO}" in
	debian | "") ;;
	*) DEPENDENCY_01='linux-firmware' ;;
	esac
}
###############
download_network_card_driver() {
	mkdir -p cd ${HOME}/sd/Download
	cd ${HOME}/sd/Download
	echo "即将为您下载至${HOME}/sd/Download"
	if [ $(command -v apt-get) ]; then
		apt show ${DEPENDENCY_02}
		apt download ${DEPENDENCY_02}
		THE_LATEST_DEB_VERSION="$(ls | grep "${DEPENDENCY_02}.*deb" | head -n 1)"
	else
		GREP_NAME=${DEPENDENCY_02}
		REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/non-free/f/firmware-nonfree/'
		THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '.deb' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		THE_LATEST_DEB_LINK="${REPO_URL}${THE_LATEST_DEB_VERSION}"
		echo ${THE_LATEST_DEB_LINK}
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_VERSION}" "${THE_LATEST_DEB_LINK}"
	fi

	mkdir -p "${DEPENDENCY_02}"
	cd "${DEPENDENCY_02}"
	if [ "${BUSYBOX_AR}" = 'true' ]; then
		busybox ar xv ../${THE_LATEST_DEB_VERSION}
	else
		ar xv ../${THE_LATEST_DEB_VERSION}
	fi
	tar -Jxvf ./data.tar.*
	rm *.tar.* debian-binary
	cd ..
	echo "Download completed,文件已保存至${HOME}/sd/Download"

}
###############
list_network_devices() {
	if [ ! $(command -v dmidecode) ]; then
		DEPENDENCY_02='dmidecode'
		beta_features_quick_install
	fi
	dmidecode | less -meQ
	dmidecode | grep --color=auto -Ei 'Wire|Net'
	press_enter_to_return
	install_debian_nonfree_network_card_driver
}
############
enable_netword_card() {
	cd /tmp/
	nmcli d | grep -Ev '^lo|^DEVICE' | awk '{print $1}' >.tmoe-linux_cache.01
	nmcli d | grep -Ev '^lo|^DEVICE' | awk '{print $2,$3}' | sed 's/ /-/g' >.tmoe-linux_cache.02
	TMOE_NETWORK_CARD_LIST=$(paste -d ' ' .tmoe-linux_cache.01 .tmoe-linux_cache.02 | sed ":a;N;s/\n/ /g;ta")
	rm -f .tmoe-linux_cache.0*
	#TMOE_NETWORK_CARD_LIST=$(nmcli d | grep -Ev '^lo|^DEVICE' | awk '{print $2,$3}')
	TMOE_NETWORK_CARD_ITEM=$(whiptail --title "NETWORK DEVICES" --menu \
		"您想要启用哪个网络设备？\nWhich network device do you want to enable?" 0 0 0 \
		${TMOE_NETWORK_CARD_LIST} \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	case ${TMOE_NETWORK_CARD_ITEM} in
	0 | "") network_manager_tui ;;
	esac
	ip link set ${TMOE_NETWORK_CARD_ITEM} up
	if [ "$?" = '0' ]; then
		echo "Congratulations,已经启用${TMOE_NETWORK_CARD_ITEM}"
	else
		echo 'Sorry,设备启用失败'
	fi
}
##################
tmoe_uefi_boot_manager() {
	NON_DEBIAN='false'
	if [ ! $(command -v efibootmgr) ]; then
		echo "本工具能对UEFI开机引导的顺序进行排序，但不支持容器和WSL"
		echo "按回车键确认安装"
		do_you_want_to_continue
		DEPENDENCY_01=''
		DEPENDENCY_02='efibootmgr'
		beta_features_quick_install
	fi
	#RETURN变量不要放在本函数开头
	RETURN_TO_WHERE='tmoe_uefi_boot_manager'
	CURRENT_UEFI_BOOT_ORDER=$(efibootmgr | grep 'BootOrder:' | cut -d ':' -f 2 | awk '{print $1}')
	CONFIG_FOLDER="${HOME}/.config/tmoe-linux/"
	TMOE_BOOT_MGR=$(
		whiptail --title "开机启动项管理" --menu "Note: efibootmgr requires that the kernel module efivars be loaded prior to use. 'modprobe efivars' should do the trick if it does not automatically load." 16 50 5 \
			"1" "first boot item修改第一启动项" \
			"2" "boot order自定义排序" \
			"3" "Backup efi备份" \
			"4" "Restore efi恢复" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${TMOE_BOOT_MGR} in
	0 | "") tmoe_system_app_menu ;;
	1) modify_first_uefi_boot_item ;;
	2) custom_uefi_boot_order ;;
	3) tmoe_backup_efi ;;
	4) tmoe_restore_efi ;;
	esac
	###############
	press_enter_to_return
	tmoe_uefi_boot_manager
}
###########
tmoe_backup_efi() {
	mkdir -p ${CONFIG_FOLDER}
	cd ${CONFIG_FOLDER}
	CURRENT_EFI_DISK=$(df -h | grep '/boot/efi' | awk '{print $1}')
	EFI_BACKUP_NAME='efi_backup.img'
	if [ -e "${EFI_BACKUP_NAME}" ]; then
		stat ${EFI_BACKUP_NAME}
		ls -lh ${EFI_BACKUP_NAME}
		echo "备份文件已存在，是否覆盖？"
		do_you_want_to_continue
	fi

	echo "正在将${CURRENT_EFI_DISK}备份至${CONFIG_FOLDER}${EFI_BACKUP_NAME}"
	dd <${CURRENT_EFI_DISK} >${EFI_BACKUP_NAME}
	echo "备份完成"
	stat ${EFI_BACKUP_NAME}
	ls -lh $(pwd)/${EFI_BACKUP_NAME}
}
############
tmoe_restore_efi() {
	cd ${CONFIG_FOLDER}
	df -h | grep '/boot/efi'
	CURRENT_EFI_DISK=$(df -h | grep '/boot/efi' | awk '{print $1}')
	fdisk -l 2>&1 | grep ${CURRENT_EFI_DISK}
	EFI_BACKUP_NAME='efi_backup.img'
	ls -lh /boot/efi/EFI
	echo "您真的要将${EFI_BACKUP_NAME}烧录至${CURRENT_EFI_DISK}？这将重置${CURRENT_EFI_DISK}的所有数据"
	echo "请谨慎操作"
	do_you_want_to_continue
	echo "正在将${CONFIG_FOLDER}${EFI_BACKUP_NAME}烧录至${CURRENT_EFI_DISK}"
	dd <${EFI_BACKUP_NAME} >${CURRENT_EFI_DISK}
	echo "恢复完成"
	stat ${EFI_BACKUP_NAME}
	ls -lh $(pwd)/${EFI_BACKUP_NAME}
}
##########
remove_boot_mgr() {
	if [ $? != 0 ]; then
		echo "本工具不支持您当前所处的环境，是否卸载？"
		echo "Do you want to remove it?"
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_02}
		beta_features
	else
		echo "修改完成，重启系统生效"
	fi
}
###########
modify_first_uefi_boot_item() {
	cd /tmp/
	efibootmgr | grep -Ev 'BootCurrent:|Timeout:|BootOrder:' | cut -d '*' -f 1 | sed 's@Boot@@g' >.tmoe-linux_cache.01
	efibootmgr | grep -Ev 'BootCurrent:|Timeout:|BootOrder:' | cut -d '*' -f 2 | sed 's/ //g' | sed 's/^/\"&/g' | sed 's/$/&\"/g' >.tmoe-linux_cache.02
	TMOE_UEFI_LIST=$(paste -d ' ' .tmoe-linux_cache.01 .tmoe-linux_cache.02 | sed ":a;N;s/\n/ /g;ta")
	rm -f .tmoe-linux_cache.0*
	TMOE_UEFI_BOOT_ITEM=$(whiptail --title "BOOT ITEM" --menu \
		"检测当前的第一启动项为$(efibootmgr | grep 'BootOrder:' | awk '{print $2}' | cut -d ',' -f 1)" 0 0 0 \
		${TMOE_UEFI_LIST} \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	case ${TMOE_UEFI_BOOT_ITEM} in
	0 | "") tmoe_uefi_boot_manager ;;
	esac
	if [ $(efibootmgr | grep 'BootOrder:' | cut -d ':' -f 2 | awk '{print $1}' | grep ^${TMOE_UEFI_BOOT_ITEM}) ]; then
		NEW_TMOE_UEFI_BOOT_ORDER=$(efibootmgr | grep 'BootOrder:' | cut -d ':' -f 2 | awk '{print $1}' | sed "s@${TMOE_UEFI_BOOT_ITEM},@@" | sed "s@${TMOE_UEFI_BOOT_ITEM}@@" | sed "s@^@${TMOE_UEFI_BOOT_ITEM},&@")
	else
		NEW_TMOE_UEFI_BOOT_ORDER=$(efibootmgr | grep 'BootOrder:' | cut -d ':' -f 2 | awk '{print $1}' | sed "s@,${TMOE_UEFI_BOOT_ITEM}@@" | sed "s@${TMOE_UEFI_BOOT_ITEM}@@" | sed "s@^@${TMOE_UEFI_BOOT_ITEM},&@")
	fi
	echo "已将启动规则修改为${NEW_TMOE_UEFI_BOOT_ORDER}"
	efibootmgr -o ${NEW_TMOE_UEFI_BOOT_ORDER}
	remove_boot_mgr
}
################
custom_uefi_boot_order() {
	TARGET=$(whiptail --inputbox "$(efibootmgr | sed 's@Boot0@0@g' | sed 's@* @:@g')\n请输入启动顺序规则,以半角逗号分开,当前为${CURRENT_UEFI_BOOT_ORDER}\nPlease enter the order, separated by commas." 0 0 --title "BOOT ORDER" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		#echo "检测到您取消了操作"
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		echo "错误的规则将会导致系统无法正常引导，请确保您的输入无误"
		echo "您输入的规则为${TARGET}"
		echo "若无误，则按回车键确认"
		echo "If it is correct, press Enter to confirm"
		do_you_want_to_continue
		echo "已将启动规则修改为${TARGET}"
		efibootmgr -o ${TARGET}
		remove_boot_mgr
	fi
}
####################
wine_menu(){ 
	RETURN_TO_WHERE='wine_menu'
	NON_DEBIAN='false'
	VIRTUAL_TECH=$(
		whiptail --title "WINE" --menu "Wine is not an emulator" 0 50 0 \
			"1" "install安装" \
			"2" "remove卸载" \
			"3" "wine-dxvk(将DirectX转换为Vulkan api)" \
			"4" "wine-wechat微信" \
			"0" "Return to previous menu 返回上级菜单" \
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
remove_wine_bin(){ 
	if [ "${ARCH_TYPE}" != "i386" ]; then
		echo 'dpkg  --remove-architecture i386'
		echo '正在移除对i386软件包的支持'
		#apt purge ".*:i386"
		aptitude remove ~i~ri386
		dpkg --remove-architecture i386
		apt update
	fi
	INSTALL_WINE='false'
	wine_depencies
	echo "${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}"
	${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
}
############
install_wine_wechat(){ 
cat <<-'EOF'
微信安装包将下载/tmp目录
若安装失败，请手动执行wine /tmp/WeChatSetup.exe
https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe
建议您在安装完成后执行winecfg,并选择“函数库”.接着添加riched20，最后选择"原装先于内建"。
EOF
cd /tmp
if [ ! -e "WeChatSetup.exe" ];then 
    aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o WeChatSetup.exe 'https://dldir1.qq.com/weixin/Windows/WeChatSetup.exe'
fi
sudo -iu master  wine /tmp/WeChatSetup.exe
sudo -iu ${CURRENT_USER_NAME} winetricks riched20
sudo -iu ${CURRENT_USER_NAME} winecfg
}
################
install_container_and_virtual_machine() {
	RETURN_TO_WHERE='install_container_and_virtual_machine'
	NON_DEBIAN='false'
	VIRTUAL_TECH=$(
		whiptail --title "虚拟化与api的转换" --menu "您想要选择哪一项呢？" 16 50 8 \
			"1" "aqemu(QEMU和KVM的Qt5前端)" \
			"2" "tmoe-qemu:x86_64虚拟机管理" \
			"3" "tmoe-qemu:arm64虚拟机管理" \
			"4" "download iso:下载镜像(Android,linux等)" \
			"5" "docker-ce(开源的应用容器引擎)" \
			"6" "portainer(docker图形化web端管理容器)" \
			"7" "VirtualBox(甲骨文开源虚拟机(x64)" \
			"8" "wine(调用win api并即时转换)" \
			"9" "anbox(Android in a box)" \
			"0" "Return to previous menu 返回上级菜单" \
			"00" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") beta_features ;;
	00) tmoe_linux_tool_menu ;;
	1) install_aqemu ;;
	2) start_tmoe_qemu_manager ;;
	3) start_tmoe_qemu_aarch64_manager ;;
	4) download_virtual_machine_iso_file ;;
	5) install_docker_ce ;;
	6) install_docker_portainer ;;
	7) install_virtual_box ;;
	8) wine_menu ;;
	9) install_anbox ;;
	esac
	###############
	press_enter_to_return
	beta_features
}
#####################
install_dxvk(){ 
	DEPENDENCY_01='dxvk'
	DEPENDENCY_02='wine-development'
	beta_features_quick_install
	dxvk-setup i -s || dxvk-setup i -d
	dxvk-setup
}
###########
check_qemu_aarch64_install() {
	if [ ! $(command -v qemu-system-aarch64) ]; then
		DEPENDENCY_01='qemu'
		DEPENDENCY_02='qemu-system-arm'
		echo "请按回车键安装qemu-system-arm,否则您将无法使用本功能"
		beta_features_quick_install
	fi
}
###########
creat_qemu_aarch64_startup_script() {
	CONFIG_FOLDER="${HOME}/.config/tmoe-linux/"
	mkdir -p ${CONFIG_FOLDER}
	cd ${CONFIG_FOLDER}
	cat >startqemu_aarch64_2020060314 <<-'EndOFqemu'
		#!/usr/bin/env bash
		export DISPLAY=127.0.0.1:0
		export PULSE_SERVER=127.0.0.1
		START_QEMU_SCRIPT_PATH='/usr/local/bin/startqemu'
		if grep -q '\-vnc \:' "${START_QEMU_SCRIPT_PATH}"; then
			CURRENT_PORT=$(cat ${START_QEMU_SCRIPT_PATH} | grep '\-vnc ' | tail -n 1 | awk '{print $2}' | cut -d ':' -f 2 | tail -n 1)
			CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
			echo "正在为您启动qemu虚拟机，本机默认VNC访问地址为localhost:${CURRENT_VNC_PORT}"
			echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${CURRENT_VNC_PORT}
		else
			echo "检测到您当前没有使用VNC服务，若您使用的是Xserver则可无视以下说明"
			echo "请自行添加端口号"
			echo "spice默认端口号为5931"
			echo "正在为您启动qemu虚拟机"
			echo "本机localhost"
			echo The LAN ip 局域网ip $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2)
		fi

		/usr/bin/qemu-system-aarch64 \
			-monitor stdio \
			-smp 4 \
			-cpu max \
			-machine virt \
			--accel tcg \
			-vga std \
			-m 2048 \
			-hda ${HOME}/sd/Download/backup/debian-10.4.1-20200515-tmoe_arm64.qcow2 \
			-virtfs local,id=shared_folder_dev_0,path=${HOME}/sd,security_model=none,mount_tag=shared0 \
			-boot order=cd,menu=on \
			-net nic \
			-net user,hostfwd=tcp::2888-0.0.0.0:22,hostfwd=tcp::5903-0.0.0.0:5901,hostfwd=tcp::49080-0.0.0.0:80 \
			-rtc base=localtime \
			-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
			-vnc :2 \
			-usb \
			-name "tmoe-linux-aarch64-qemu"
	EndOFqemu
	chmod +x startqemu_aarch64_2020060314
	cp -pf startqemu_aarch64_2020060314 /usr/local/bin/startqemu
}
######################
tmoe_qemu_aarch64_cpu_manager() {
	RETURN_TO_WHERE='tmoe_qemu_aarch64_cpu_manager'
	VIRTUAL_TECH=$(
		whiptail --title "CPU" --menu "Which configuration do you want to modify?" 15 50 6 \
			"1" "CPU cores处理器核心数" \
			"2" "cpu model/type(型号/类型)" \
			"3" "multithreading多线程" \
			"4" "machine机器类型" \
			"5" "kvm/tcg/xen加速类型" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) modify_qemu_cpu_cores_number ;;
	2) modify_qemu_aarch64_tmoe_cpu_type ;;
	3) enable_tmoe_qemu_cpu_multi_threading ;;
	4) modify_qemu_aarch64_tmoe_machine_model ;;
	5) modify_qemu_machine_accel ;;
	esac
	###############
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
start_tmoe_qemu_aarch64_manager() {
	RETURN_TO_WHERE='start_tmoe_qemu_aarch64_manager'
	RETURN_TO_MENU='start_tmoe_qemu_aarch64_manager'
	check_qemu_aarch64_install
	cd /usr/local/bin/
	if [ ! -e "${HOME}/.config/tmoe-linux/startqemu_aarch64_2020060314" ]; then
		echo "启用arm64虚拟机将重置startqemu为arm64的配置"
		rm -fv ${HOME}/.config/tmoe-linux/startqemu*
		creat_qemu_aarch64_startup_script
	fi

	VIRTUAL_TECH=$(
		whiptail --title "aarch64 qemu虚拟机管理器" --menu "v2020-06-02 beta" 17 55 8 \
			"1" "Creat a new VM 新建虚拟机" \
			"2" "Multi-VM多虚拟机管理" \
			"3" "edit script manually手动修改配置脚本" \
			"4" "CPU管理" \
			"5" "Display and audio显示与音频" \
			"6" "RAM运行内存" \
			"7" "💾disk manager磁盘管理器" \
			"8" "FAQ常见问题" \
			"9" "exposed ports端口映射/转发" \
			"10" "network card model网卡" \
			"11" "restore to default恢复到默认" \
			"12" "uefi/legacy bios(开机引导固件)" \
			"13" "Input devices输入设备" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) creat_a_new_tmoe_qemu_vm ;;
	2) multi_qemu_vm_management ;;
	3) nano startqemu ;;
	4) tmoe_qemu_aarch64_cpu_manager ;;
	5) tmoe_qemu_display_settings ;;
	6) modify_qemu_ram_size ;;
	7) tmoe_qemu_disk_manager ;;
	8) tmoe_qemu_faq ;;
	9) modify_qemu_exposed_ports ;;
	10) modify_qemu_tmoe_network_card ;;
	11) creat_qemu_startup_script ;;
	12) choose_qemu_bios_or_uefi_file ;;
	13) tmoe_qemu_input_devices ;;
	esac
	###############
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
switch_tmoe_qemu_network_card_to_default() {
	sed -i 's/-net nic.*/-net nic \\/' startqemu
	echo "已经将默认网卡切换为未指定状态"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##########
modify_qemu_tmoe_network_card() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='modify_qemu_tmoe_network_card'
	if grep -q '\-net nic,model' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-net nic,model' | tail -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	else
		CURRENT_VALUE='未指定'
	fi
	VIRTUAL_TECH=$(
		whiptail --title "网卡型号" --menu "Please select the network card model.\n当前为${CURRENT_VALUE}" 16 50 7 \
			"0" "Return to previous menu 返回上级菜单" \
			"00" "未指定" \
			"01" "e1000:alias e1000-82540em" \
			"02" "e1000-82544gc:Intel Gigabit Ethernet" \
			"03" "e1000-82545em" \
			"04" "e1000e:Intel 82574L GbE Controller" \
			"05" "Realtek rtl8139" \
			"06" "virtio-net-pci" \
			"07" "i82550:Intel i82550 Ethernet" \
			"08" "i82551" \
			"09" "i82557a" \
			"10" "i82557b" \
			"11" "i82557c" \
			"12" "i82558a" \
			"13" "i82558b" \
			"14" "i82559a" \
			"15" "i82559b" \
			"16" "i82559er" \
			"17" "i82562" \
			"18" "i82801" \
			"19" "ne2k_pci" \
			"20" "ne2k_isa" \
			"21" "pcnet" \
			"22" "smc91c111" \
			"23" "lance" \
			"24" "mcf_fec" \
			"25" "vmxnet3:VMWare Paravirtualized" \
			"26" "rocker Switch" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") modify_tmoe_qemu_network_settings ;;
	00) switch_tmoe_qemu_network_card_to_default ;;
	01) TMOE_QEMU_NETWORK_CARD="e1000" ;;
	02) TMOE_QEMU_NETWORK_CARD="e1000-82544gc" ;;
	03) TMOE_QEMU_NETWORK_CARD="e1000-82545em" ;;
	04) TMOE_QEMU_NETWORK_CARD="e1000e" ;;
	05) TMOE_QEMU_NETWORK_CARD="rtl8139" ;;
	06) TMOE_QEMU_NETWORK_CARD="virtio-net-pci" ;;
	07) TMOE_QEMU_NETWORK_CARD="i82550" ;;
	08) TMOE_QEMU_NETWORK_CARD="i82551" ;;
	09) TMOE_QEMU_NETWORK_CARD="i82557a" ;;
	10) TMOE_QEMU_NETWORK_CARD="i82557b" ;;
	11) TMOE_QEMU_NETWORK_CARD="i82557c" ;;
	12) TMOE_QEMU_NETWORK_CARD="i82558a" ;;
	13) TMOE_QEMU_NETWORK_CARD="i82558b" ;;
	14) TMOE_QEMU_NETWORK_CARD="i82559a" ;;
	15) TMOE_QEMU_NETWORK_CARD="i82559b" ;;
	16) TMOE_QEMU_NETWORK_CARD="i82559er" ;;
	17) TMOE_QEMU_NETWORK_CARD="i82562" ;;
	18) TMOE_QEMU_NETWORK_CARD="i82801" ;;
	19) TMOE_QEMU_NETWORK_CARD="ne2k_pci" ;;
	20) TMOE_QEMU_NETWORK_CARD="ne2k_isa" ;;
	21) TMOE_QEMU_NETWORK_CARD="pcnet" ;;
	22) TMOE_QEMU_NETWORK_CARD="smc91c111" ;;
	23) TMOE_QEMU_NETWORK_CARD="lance" ;;
	24) TMOE_QEMU_NETWORK_CARD="mcf_fec" ;;
	25) TMOE_QEMU_NETWORK_CARD="vmxnet3" ;;
	26) TMOE_QEMU_NETWORK_CARD="rocker" ;;
	esac
	###############
	sed -i "s/-net nic.*/-net nic,model=${TMOE_QEMU_NETWORK_CARD} \\\/" startqemu
	echo "您已将network card修改为${TMOE_QEMU_NETWORK_CARD}"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
###########
modify_qemu_aarch64_tmoe_machine_model() {
	cd /usr/local/bin/
	#qemu-system-aarch64 -machine help  >001
	CURRENT_VALUE=$(cat startqemu | grep '\-machine' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	VIRTUAL_TECH=$(
		whiptail --title "机器型号" --menu "Please select the machine model.\n默认为virt,当前为${CURRENT_VALUE}" 0 0 0 \
			"0" "Return to previous menu 返回上级菜单" \
			"01" "akita:Sharp SL-C1000 (Akita) PDA (PXA270)" \
			"02" "ast2500-evb:Aspeed AST2500 EVB (ARM1176)" \
			"03" "ast2600-evb:Aspeed AST2600 EVB (Cortex A7)" \
			"04" "borzoi:Sharp SL-C3100 (Borzoi) PDA (PXA270)" \
			"05" "canon-a1100:Canon PowerShot A1100 IS" \
			"06" "cheetah:Palm Tungsten|E aka. Cheetah PDA (OMAP310)" \
			"07" "collie:Sharp SL-5500 (Collie) PDA (SA-1110)" \
			"08" "connex:Gumstix Connex (PXA255)" \
			"09" "cubieboard:cubietech cubieboard (Cortex-A8)" \
			"10" "emcraft-sf2:SmartFusion2 SOM kit from Emcraft (M2S010)" \
			"11" "highbank:Calxeda Highbank (ECX-1000)" \
			"12" "imx25-pdk:ARM i.MX25 PDK board (ARM926)" \
			"13" "integratorcp:ARM Integrator/CP (ARM926EJ-S)" \
			"14" "kzm:ARM KZM Emulation Baseboard (ARM1136)" \
			"15" "lm3s6965evb:Stellaris LM3S6965EVB" \
			"16" "lm3s811evb:Stellaris LM3S811EVB" \
			"17" "mainstone:Mainstone II (PXA27x)" \
			"18" "mcimx6ul-evk:Freescale i.MX6UL Evaluation Kit (Cortex A7)" \
			"19" "mcimx7d-sabre:Freescale i.MX7 DUAL SABRE (Cortex A7)" \
			"20" "microbit:BBC micro:bit" \
			"21" "midway:Calxeda Midway (ECX-2000)" \
			"22" "mps2-an385:ARM MPS2 with AN385 FPGA image for Cortex-M3" \
			"23" "mps2-an505:ARM MPS2 with AN505 FPGA image for Cortex-M33" \
			"24" "mps2-an511:ARM MPS2 with AN511 DesignStart FPGA image for Cortex-M3" \
			"25" "mps2-an521:ARM MPS2 with AN521 FPGA image for dual Cortex-M33" \
			"26" "musca-a:ARM Musca-A board (dual Cortex-M33)" \
			"27" "musca-b1:ARM Musca-B1 board (dual Cortex-M33)" \
			"28" "musicpal:Marvell 88w8618 / MusicPal (ARM926EJ-S)" \
			"29" "n800:Nokia N800 tablet aka. RX-34 (OMAP2420)" \
			"30" "n810:Nokia N810 tablet aka. RX-44 (OMAP2420)" \
			"31" "netduino2:Netduino 2 Machine" \
			"32" "netduinoplus2:Netduino Plus 2 Machine" \
			"33" "none:empty machine" \
			"34" "nuri:Samsung NURI board (Exynos4210)" \
			"35" "orangepi-pc:Orange Pi PC" \
			"36" "palmetto-bmc:OpenPOWER Palmetto BMC (ARM926EJ-S)" \
			"37" "raspi2:Raspberry Pi 2B" \
			"38" "raspi3:Raspberry Pi 3B" \
			"39" "realview-eb:ARM RealView Emulation Baseboard (ARM926EJ-S)" \
			"40" "realview-eb-mpcore:ARM RealView Emulation Baseboard (ARM11MPCore)" \
			"41" "realview-pb-a8:ARM RealView Platform Baseboard for Cortex-A8" \
			"42" "realview-pbx-a9:ARM RealView Platform Baseboard Explore for Cortex-A9" \
			"43" "romulus-bmc:OpenPOWER Romulus BMC (ARM1176)" \
			"44" "sabrelite:Freescale i.MX6 Quad SABRE Lite Board (Cortex A9)" \
			"45" "sbsa-ref:QEMU 'SBSA Reference' ARM Virtual Machine" \
			"46" "smdkc210:Samsung SMDKC210 board (Exynos4210)" \
			"47" "spitz:Sharp SL-C3000 (Spitz) PDA (PXA270)" \
			"48" "swift-bmc:OpenPOWER Swift BMC (ARM1176)" \
			"49" "sx1:Siemens SX1 (OMAP310) V2" \
			"50" "sx1-v1:Siemens SX1 (OMAP310) V1" \
			"51" "tacoma-bmc:Aspeed AST2600 EVB (Cortex A7)" \
			"52" "terrier:Sharp SL-C3200 (Terrier) PDA (PXA270)" \
			"53" "tosa:Sharp SL-6000 (Tosa) PDA (PXA255)" \
			"54" "verdex:Gumstix Verdex (PXA270)" \
			"55" "versatileab:ARM Versatile/AB (ARM926EJ-S)" \
			"56" "versatilepb:ARM Versatile/PB (ARM926EJ-S)" \
			"57" "vexpress-a15:ARM Versatile Express for Cortex-A15" \
			"58" "vexpress-a9:ARM Versatile Express for Cortex-A9" \
			"59" "virt-2.10:QEMU 2.10 ARM Virtual Machine" \
			"60" "virt-2.11:QEMU 2.11 ARM Virtual Machine" \
			"61" "virt-2.12:QEMU 2.12 ARM Virtual Machine" \
			"62" "virt-2.6:QEMU 2.6 ARM Virtual Machine" \
			"63" "virt-2.7:QEMU 2.7 ARM Virtual Machine" \
			"64" "virt-2.8:QEMU 2.8 ARM Virtual Machine" \
			"65" "virt-2.9:QEMU 2.9 ARM Virtual Machine" \
			"66" "virt-3.0:QEMU 3.0 ARM Virtual Machine" \
			"67" "virt-3.1:QEMU 3.1 ARM Virtual Machine" \
			"68" "virt-4.0:QEMU 4.0 ARM Virtual Machine" \
			"69" "virt-4.1:QEMU 4.1 ARM Virtual Machine" \
			"70" "virt-4.2:QEMU 4.2 ARM Virtual Machine" \
			"71" "virt:QEMU 5.0 ARM Virtual Machine (alias of virt-5.0)" \
			"72" "virt-5.0:QEMU 5.0 ARM Virtual Machine" \
			"73" "witherspoon-bmc:OpenPOWER Witherspoon BMC (ARM1176)" \
			"74" "xilinx-zynq-a9:Xilinx Zynq Platform Baseboard for Cortex-A9" \
			"75" "xlnx-versal-virt:Xilinx Versal Virtual development board" \
			"76" "xlnx-zcu102:Xilinx ZynqMP ZCU102 board with 4xA53s and 2xR5Fs based on the value of smp" \
			"77" "z2:Zipit Z2 (PXA27x)" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	01) TMOE_AARCH64_QEMU_MACHINE="akita" ;;
	02) TMOE_AARCH64_QEMU_MACHINE="ast2500-evb" ;;
	03) TMOE_AARCH64_QEMU_MACHINE="ast2600-evb" ;;
	04) TMOE_AARCH64_QEMU_MACHINE="borzoi" ;;
	05) TMOE_AARCH64_QEMU_MACHINE="canon-a1100" ;;
	06) TMOE_AARCH64_QEMU_MACHINE="cheetah" ;;
	07) TMOE_AARCH64_QEMU_MACHINE="collie" ;;
	08) TMOE_AARCH64_QEMU_MACHINE="connex" ;;
	09) TMOE_AARCH64_QEMU_MACHINE="cubieboard" ;;
	10) TMOE_AARCH64_QEMU_MACHINE="emcraft-sf2" ;;
	11) TMOE_AARCH64_QEMU_MACHINE="highbank" ;;
	12) TMOE_AARCH64_QEMU_MACHINE="imx25-pdk" ;;
	13) TMOE_AARCH64_QEMU_MACHINE="integratorcp" ;;
	14) TMOE_AARCH64_QEMU_MACHINE="kzm" ;;
	15) TMOE_AARCH64_QEMU_MACHINE="lm3s6965evb" ;;
	16) TMOE_AARCH64_QEMU_MACHINE="lm3s811evb" ;;
	17) TMOE_AARCH64_QEMU_MACHINE="mainstone" ;;
	18) TMOE_AARCH64_QEMU_MACHINE="mcimx6ul-evk" ;;
	19) TMOE_AARCH64_QEMU_MACHINE="mcimx7d-sabre" ;;
	20) TMOE_AARCH64_QEMU_MACHINE="microbit" ;;
	21) TMOE_AARCH64_QEMU_MACHINE="midway" ;;
	22) TMOE_AARCH64_QEMU_MACHINE="mps2-an385" ;;
	23) TMOE_AARCH64_QEMU_MACHINE="mps2-an505" ;;
	24) TMOE_AARCH64_QEMU_MACHINE="mps2-an511" ;;
	25) TMOE_AARCH64_QEMU_MACHINE="mps2-an521" ;;
	26) TMOE_AARCH64_QEMU_MACHINE="musca-a" ;;
	27) TMOE_AARCH64_QEMU_MACHINE="musca-b1" ;;
	28) TMOE_AARCH64_QEMU_MACHINE="musicpal" ;;
	29) TMOE_AARCH64_QEMU_MACHINE="n800" ;;
	30) TMOE_AARCH64_QEMU_MACHINE="n810" ;;
	31) TMOE_AARCH64_QEMU_MACHINE="netduino2" ;;
	32) TMOE_AARCH64_QEMU_MACHINE="netduinoplus2" ;;
	33) TMOE_AARCH64_QEMU_MACHINE="none" ;;
	34) TMOE_AARCH64_QEMU_MACHINE="nuri" ;;
	35) TMOE_AARCH64_QEMU_MACHINE="orangepi-pc" ;;
	36) TMOE_AARCH64_QEMU_MACHINE="palmetto-bmc" ;;
	37) TMOE_AARCH64_QEMU_MACHINE="raspi2" ;;
	38) TMOE_AARCH64_QEMU_MACHINE="raspi3" ;;
	39) TMOE_AARCH64_QEMU_MACHINE="realview-eb" ;;
	40) TMOE_AARCH64_QEMU_MACHINE="realview-eb-mpcore" ;;
	41) TMOE_AARCH64_QEMU_MACHINE="realview-pb-a8" ;;
	42) TMOE_AARCH64_QEMU_MACHINE="realview-pbx-a9" ;;
	43) TMOE_AARCH64_QEMU_MACHINE="romulus-bmc" ;;
	44) TMOE_AARCH64_QEMU_MACHINE="sabrelite" ;;
	45) TMOE_AARCH64_QEMU_MACHINE="sbsa-ref" ;;
	46) TMOE_AARCH64_QEMU_MACHINE="smdkc210" ;;
	47) TMOE_AARCH64_QEMU_MACHINE="spitz" ;;
	48) TMOE_AARCH64_QEMU_MACHINE="swift-bmc" ;;
	49) TMOE_AARCH64_QEMU_MACHINE="sx1" ;;
	50) TMOE_AARCH64_QEMU_MACHINE="sx1-v1" ;;
	51) TMOE_AARCH64_QEMU_MACHINE="tacoma-bmc" ;;
	52) TMOE_AARCH64_QEMU_MACHINE="terrier" ;;
	53) TMOE_AARCH64_QEMU_MACHINE="tosa" ;;
	54) TMOE_AARCH64_QEMU_MACHINE="verdex" ;;
	55) TMOE_AARCH64_QEMU_MACHINE="versatileab" ;;
	56) TMOE_AARCH64_QEMU_MACHINE="versatilepb" ;;
	57) TMOE_AARCH64_QEMU_MACHINE="vexpress-a15" ;;
	58) TMOE_AARCH64_QEMU_MACHINE="vexpress-a9" ;;
	59) TMOE_AARCH64_QEMU_MACHINE="virt-2.10" ;;
	60) TMOE_AARCH64_QEMU_MACHINE="virt-2.11" ;;
	61) TMOE_AARCH64_QEMU_MACHINE="virt-2.12" ;;
	62) TMOE_AARCH64_QEMU_MACHINE="virt-2.6" ;;
	63) TMOE_AARCH64_QEMU_MACHINE="virt-2.7" ;;
	64) TMOE_AARCH64_QEMU_MACHINE="virt-2.8" ;;
	65) TMOE_AARCH64_QEMU_MACHINE="virt-2.9" ;;
	66) TMOE_AARCH64_QEMU_MACHINE="virt-3.0" ;;
	67) TMOE_AARCH64_QEMU_MACHINE="virt-3.1" ;;
	68) TMOE_AARCH64_QEMU_MACHINE="virt-4.0" ;;
	69) TMOE_AARCH64_QEMU_MACHINE="virt-4.1" ;;
	70) TMOE_AARCH64_QEMU_MACHINE="virt-4.2" ;;
	71) TMOE_AARCH64_QEMU_MACHINE="virt" ;;
	72) TMOE_AARCH64_QEMU_MACHINE="virt-5.0" ;;
	73) TMOE_AARCH64_QEMU_MACHINE="witherspoon-bmc" ;;
	74) TMOE_AARCH64_QEMU_MACHINE="xilinx-zynq-a9" ;;
	75) TMOE_AARCH64_QEMU_MACHINE="xlnx-versal-virt" ;;
	76) TMOE_AARCH64_QEMU_MACHINE="xlnx-zcu102" ;;
	77) TMOE_AARCH64_QEMU_MACHINE="z2" ;;
	esac
	###############
	sed -i "s@-machine .*@-machine ${TMOE_AARCH64_QEMU_MACHINE} \\\@" startqemu
	echo "您已将machine修改为${TMOE_AARCH64_QEMU_MACHINE}"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##############
modify_qemu_aarch64_tmoe_cpu_type() {
	cd /usr/local/bin/
	CURRENT_VALUE=$(cat startqemu | grep '\-cpu' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	VIRTUAL_TECH=$(
		whiptail --title "CPU" --menu "默认为max,当前为${CURRENT_VALUE}" 0 0 0 \
			"0" "Return to previous menu 返回上级菜单" \
			"01" "arm1026" \
			"02" "arm1136" \
			"03" "arm1136-r2" \
			"04" "arm1176" \
			"05" "arm11mpcore" \
			"06" "arm926" \
			"07" "arm946" \
			"08" "cortex-a15" \
			"09" "cortex-a53" \
			"10" "cortex-a57" \
			"11" "cortex-a7" \
			"12" "cortex-a72" \
			"13" "cortex-a8" \
			"14" "cortex-a9" \
			"15" "cortex-m0" \
			"16" "cortex-m3" \
			"17" "cortex-m33" \
			"18" "cortex-m4" \
			"19" "cortex-m7" \
			"20" "cortex-r5" \
			"21" "cortex-r5f" \
			"22" "host" \
			"23" "max" \
			"24" "pxa250" \
			"25" "pxa255" \
			"26" "pxa260" \
			"27" "pxa261" \
			"28" "pxa262" \
			"29" "pxa270-a0" \
			"30" "pxa270-a1" \
			"31" "pxa270" \
			"32" "pxa270-b0" \
			"33" "pxa270-b1" \
			"34" "pxa270-c0" \
			"35" "pxa270-c5" \
			"36" "sa1100" \
			"37" "sa1110" \
			"38" "ti925t" \
			3>&1 1>&2 2>&3
	)
	#############
	#00) disable_tmoe_qemu_cpu ;;F
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	01) TMOE_AARCH64_QEMU_CPU_TYPE="arm1026" ;;
	02) TMOE_AARCH64_QEMU_CPU_TYPE="arm1136" ;;
	03) TMOE_AARCH64_QEMU_CPU_TYPE="arm1136-r2" ;;
	04) TMOE_AARCH64_QEMU_CPU_TYPE="arm1176" ;;
	05) TMOE_AARCH64_QEMU_CPU_TYPE="arm11mpcore" ;;
	06) TMOE_AARCH64_QEMU_CPU_TYPE="arm926" ;;
	07) TMOE_AARCH64_QEMU_CPU_TYPE="arm946" ;;
	08) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a15" ;;
	09) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a53" ;;
	10) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a57" ;;
	11) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a7" ;;
	12) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a72" ;;
	13) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a8" ;;
	14) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a9" ;;
	15) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m0" ;;
	16) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m3" ;;
	17) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m33" ;;
	18) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m4" ;;
	19) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m7" ;;
	20) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-r5" ;;
	21) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-r5f" ;;
	22) TMOE_AARCH64_QEMU_CPU_TYPE="host" ;;
	23) TMOE_AARCH64_QEMU_CPU_TYPE="max" ;;
	24) TMOE_AARCH64_QEMU_CPU_TYPE="pxa250" ;;
	25) TMOE_AARCH64_QEMU_CPU_TYPE="pxa255" ;;
	26) TMOE_AARCH64_QEMU_CPU_TYPE="pxa260" ;;
	27) TMOE_AARCH64_QEMU_CPU_TYPE="pxa261" ;;
	28) TMOE_AARCH64_QEMU_CPU_TYPE="pxa262" ;;
	29) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-a0" ;;
	30) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-a1" ;;
	31) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270" ;;
	32) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-b0" ;;
	33) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-b1" ;;
	34) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-c0" ;;
	35) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-c5" ;;
	36) TMOE_AARCH64_QEMU_CPU_TYPE="sa1100" ;;
	37) TMOE_AARCH64_QEMU_CPU_TYPE="sa1110" ;;
	38) TMOE_AARCH64_QEMU_CPU_TYPE="ti925t" ;;
	esac
	###############
	sed -i "s@-cpu .*@-cpu ${TMOE_AARCH64_QEMU_CPU_TYPE} \\\@" startqemu
	echo "您已将cpu修改为${TMOE_AARCH64_QEMU_CPU_TYPE}"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
disable_tmoe_qemu_sound_card() {
	sed -i '/-soundhw /d' startqemu
	echo "禁用完成"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
tmoe_modify_qemu_sound_card() {
	sed -i '/-soundhw /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -soundhw tmoe_cpu_config_test \\\n/' startqemu
	sed -i "s@-soundhw tmoe_cpu_config_test@-soundhw ${QEMU_SOUNDHW}@" startqemu
	echo "您已将soundhw修改为${QEMU_SOUNDHW}"
	echo "修改完成，将在下次启动qemu虚拟机时生效"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
###########
modify_qemu_aarch64_tmoe_sound_card() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='modify_qemu_aarch64_tmoe_sound_card'
	if grep -q '\-soundhw ' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-soundhw ' | tail -n 1 | awk '{print $2}')
	else
		CURRENT_VALUE='默认'
	fi
	VIRTUAL_TECH=$(
		whiptail --title "声卡型号" --menu "Please select the sound card model.\n默认未启用,当前为${CURRENT_VALUE}" 16 50 7 \
			"1" "es1370(ENSONIQ AudioPCI ES1370)" \
			"2" "ac97(Intel 82801AA AC97)" \
			"3" "adlib:Yamaha YM3812 (OPL2)" \
			"4" "hda(Intel HD Audio)" \
			"5" "disable禁用声卡" \
			"6" "all启用所有" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) QEMU_SOUNDHW='es1370' ;;
	2) QEMU_SOUNDHW='ac97' ;;
	3) QEMU_SOUNDHW='adlib' ;;
	4) QEMU_SOUNDHW='hda' ;;
	5) disable_tmoe_qemu_sound_card ;;
	6) QEMU_SOUNDHW='all' ;;
	esac
	###############
	#-soundhw cs4231a \
	#sed -i "s@-soundhw .*@-soundhw ${QEMU_SOUNDHW} \\\@" startqemu
	tmoe_modify_qemu_sound_card
}
#############
check_qemu_install() {
	DEPENDENCY_01='qemu'
	DEPENDENCY_02=''
	if [ ! $(command -v qemu-system-x86_64) ]; then
		if [ "${LINUX_DISTRO}" = 'debian' ]; then
			DEPENDENCY_01='qemu qemu-system-x86'
			DEPENDENCY_02='qemu-system-gui'
		elif [ "${LINUX_DISTRO}" = 'alpine' ]; then
			DEPENDENCY_01='qemu qemu-system-x86_64 qemu-system-i386'
			DEPENDENCY_02='qemu-system-aarch64'
		elif [ "${LINUX_DISTRO}" = 'arch' ]; then
			DEPENDENCY_02='qemu-arch-extra'
		fi
		beta_features_quick_install
	fi
}
#############
creat_qemu_startup_script() {
	CONFIG_FOLDER="${HOME}/.config/tmoe-linux/"
	mkdir -p ${CONFIG_FOLDER}
	cd ${CONFIG_FOLDER}
	cat >startqemu_amd64_2020060314 <<-'EndOFqemu'
		#!/usr/bin/env bash
		export DISPLAY=127.0.0.1:0
		export PULSE_SERVER=127.0.0.1
		START_QEMU_SCRIPT_PATH='/usr/local/bin/startqemu'
		if grep -q '\-vnc \:' "${START_QEMU_SCRIPT_PATH}"; then
			CURRENT_PORT=$(cat ${START_QEMU_SCRIPT_PATH} | grep '\-vnc ' | tail -n 1 | awk '{print $2}' | cut -d ':' -f 2 | tail -n 1)
			CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
			echo "正在为您启动qemu虚拟机，本机默认VNC访问地址为localhost:${CURRENT_VNC_PORT}"
			echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${CURRENT_VNC_PORT}
		else
			echo "检测到您当前没有使用VNC服务，若您使用的是Xserver则可无视以下说明"
			echo "请自行添加端口号"
			echo "spice默认端口号为5931"
			echo "正在为您启动qemu虚拟机"
			echo "本机localhost"
			echo The LAN ip 局域网ip $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2)
		fi

		/usr/bin/qemu-system-x86_64 \
			-monitor stdio \
			-smp 4 \
			-cpu max \
			-vga std \
			--accel tcg \
			-m 2048 \
			-hda ${HOME}/sd/Download/backup/alpine_v3.11_x64.qcow2 \
			-virtfs local,id=shared_folder_dev_0,path=${HOME}/sd,security_model=none,mount_tag=shared0 \
			-boot order=cd,menu=on \
			-net nic,model=e1000 \
			-net user,hostfwd=tcp::2888-0.0.0.0:22,hostfwd=tcp::5903-0.0.0.0:5901,hostfwd=tcp::49080-0.0.0.0:80 \
			-rtc base=localtime \
			-vnc :2 \
			-usb \
			-device usb-tablet \
			-name "tmoe-linux-qemu"
	EndOFqemu
	chmod +x startqemu_amd64_2020060314
	cp -pf startqemu_amd64_2020060314 /usr/local/bin/startqemu
}
###########
modify_qemu_machine_accel() {
	if grep -Eq 'vmx|smx' /proc/cpuinfo; then
		if [ "$(lsmod | grep kvm)" ]; then
			KVM_STATUS='检测到您的CPU可能支持硬件虚拟化,并且已经启用了KVM内核模块。'
		else
			KVM_STATUS='检测到您的CPU可能支持硬件虚拟化，但未检测到KVM内核模块。'
		fi
	else
		KVM_STATUS='检测到您的CPU可能不支持硬件虚拟化'
	fi
	cd /usr/local/bin/
	CURRENT_VALUE=$(cat startqemu | grep '\--accel ' | head -n 1 | awk '{print $2}' | cut -d ',' -f 1)
	VIRTUAL_TECH=$(
		whiptail --title "加速类型" --menu "KVM要求cpu支持硬件虚拟化,进行同架构模拟运行时能得到比tcg更快的速度,若您的CPU不支持KVM加速,则请勿修改为此项。${KVM_STATUS}\n检测到当前为${CURRENT_VALUE}" 17 50 5 \
			"1" "tcg(default)" \
			"2" "kvm(Intel VT-d/AMD-V)" \
			"3" "xen" \
			"4" "hax(Intel VT-x)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	1) MACHINE_ACCEL=tcg ;;
	2) MACHINE_ACCEL=kvm ;;
	3) MACHINE_ACCEL=xen ;;
	4) MACHINE_ACCEL=hax ;;
	esac
	###############
	if grep -q '\,thread=multi' startqemu; then
		sed -i "s@--accel .*@--accel ${MACHINE_ACCEL},thread=multi \\\@" startqemu
		echo "您已将accel修改为${MACHINE_ACCEL},并启用了多线程加速功能"
	else
		sed -i "s@--accel .*@--accel ${MACHINE_ACCEL} \\\@" startqemu
		echo "您已将accel修改为${MACHINE_ACCEL},但并未启用多线程加速功能"
	fi
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
modify_qemnu_graphics_card() {
	cd /usr/local/bin/
	CURRENT_VALUE=$(cat startqemu | grep '\-vga' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	VIRTUAL_TECH=$(
		whiptail --title "GPU/VGA" --menu "Please select the graphics card model.\n默认为std,当前为${CURRENT_VALUE}" 16 50 7 \
			"1" "vmware(VMWare SVGA)" \
			"2" "std(standard VGA,vesa2.0)" \
			"3" "cirrus clgd5446" \
			"4" "qxl(QXL VGA)" \
			"5" "xenfb(Xen paravirtualized framebuffer)" \
			"6" "tcx" \
			"7" "cg3" \
			"8" "none无显卡" \
			"9" "virtio" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_display_settings ;;
	1)
		echo " VMWare SVGA-II compatible adapter. Use it if you have sufficiently recent XFree86/XOrg server or Windows guest with a driver for this card."
		QEMU_VGA='vmware'
		;;
	2)
		echo "std Standard VGA card with Bochs VBE extensions.  If your guest OS supports the VESA 2.0 VBE extensions (e.g. Windows XP) and if you want to use high resolution modes (>= 1280x1024x16) then you should use this option. (This card is the default since QEMU 2.2)"
		QEMU_VGA='std'
		;;
	3)
		echo "Cirrus Logic GD5446 Video card. All Windows versions starting from Windows 95 should recognize and use this graphic card. For optimal performances, use 16 bit color depth in the guest and the host OS.  (This card was the default before QEMU 2.2) "
		QEMU_VGA='cirrus'
		;;
	4)
		echo "QXL paravirtual graphic card.  It is VGA compatible (including VESA 2.0 VBE support).  Works best with qxl guest drivers installed though.  Recommended choice when using the spice protocol."
		QEMU_VGA='qxl'
		;;
	5)
		QEMU_VGA='xenfb'
		;;
	6)
		echo "tcx (sun4m only) Sun TCX framebuffer. This is the default framebuffer for sun4m machines and offers both 8-bit and 24-bit colour depths at a fixed resolution of 1024x768."
		QEMU_VGA='tcx'
		;;
	7)
		echo " cg3 (sun4m only) Sun cgthree framebuffer. This is a simple 8-bit framebuffer for sun4m machines available in both 1024x768 (OpenBIOS) and 1152x900 (OBP) resolutions aimed at people wishing to run older Solaris versions."
		QEMU_VGA='cg3'
		;;
	8) QEMU_VGA='none' ;;
	9) QEMU_VGA='virtio' ;;
	esac
	###############
	sed -i "s@-vga .*@-vga ${QEMU_VGA} \\\@" startqemu
	echo "您已将graphics_card修改为${QEMU_VGA}"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
###############
modify_qemu_exposed_ports() {
	cd /usr/local/bin/
	HOST_PORT_01=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 2 | cut -d '-' -f 1 | cut -d ':' -f 3)
	GUEST_PORT_01=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 2 | cut -d '-' -f 2 | cut -d ':' -f 2 | awk '{print $1}')
	HOST_PORT_02=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 3 | cut -d '-' -f 1 | cut -d ':' -f 3)
	GUEST_PORT_02=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 3 | cut -d '-' -f 2 | cut -d ':' -f 2 | awk '{print $1}')
	HOST_PORT_03=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 4 | cut -d '-' -f 1 | cut -d ':' -f 3)
	GUEST_PORT_03=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 4 | cut -d '-' -f 2 | cut -d ':' -f 2 | awk '{print $1}')

	VIRTUAL_TECH=$(
		whiptail --title "TCP端口转发规则" --menu "如需添加更多端口，请手动修改配置文件" 15 55 4 \
			"1" "主${HOST_PORT_01}虚${GUEST_PORT_01}" \
			"2" "主${HOST_PORT_02}虚${GUEST_PORT_02}" \
			"3" "主${HOST_PORT_03}虚${GUEST_PORT_03}" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1)
		HOST_PORT=${HOST_PORT_01}
		GUEST_PORT=${GUEST_PORT_01}
		;;
	2)
		HOST_PORT=${HOST_PORT_02}
		GUEST_PORT=${GUEST_PORT_02}
		;;
	3)
		HOST_PORT=${HOST_PORT_03}
		GUEST_PORT=${GUEST_PORT_03}
		;;
	esac
	###############
	modify_qemu_host_and_guest_port
	if [ ! -z ${TARGET_HOST_PORT} ]; then
		echo "您已将虚拟机的${TARGET_GUEST_PORT}端口映射到宿主机的${TARGET_HOST_PORT}端口"
	fi
	press_enter_to_return
	modify_qemu_exposed_ports
}
#################
modify_qemu_host_and_guest_port() {
	TARGET_HOST_PORT=$(whiptail --inputbox "请输入宿主机端口，若您无root权限，则请将其修改为1024以上的高位端口" 10 50 --title "host port" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		modify_qemu_exposed_ports
	elif [ -z "${TARGET_HOST_PORT}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		sed -i "s@::${HOST_PORT}-@::${TARGET_HOST_PORT}-@" startqemu
	fi

	TARGET_GUEST_PORT=$(whiptail --inputbox "请输入虚拟机端口" 10 50 --title "guest port" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		modify_qemu_exposed_ports
	elif [ -z "${TARGET_GUEST_PORT}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		sed -i "s@0.0.0.0:${GUEST_PORT}@0.0.0.0:${TARGET_GUEST_PORT}@" startqemu
	fi
}
########
modify_qemu_shared_folder() {
	cd /usr/local/bin
	if (whiptail --title "您当前处于哪个环境" --yes-button 'Host' --no-button 'Guest' --yesno "您当前处于宿主机还是虚拟机环境？\nAre you in a host or guest environment?" 8 50); then
		modify_qemu_host_shared_folder
	else
		mount_qemu_guest_shared_folder
	fi
}
#############
disable_qemu_host_shared_folder() {
	sed -i '/-virtfs local,id=shared_folder/d' startqemu
	echo "如需还原，请重置配置文件"
}
############
modify_qemu_host_shared_folder_sdcard() {
	echo "Sorry,当前暂不支持修改挂载目录"
}
###############
#-hdd fat:rw:${HOME}/sd \
modify_qemu_host_shared_folder() {
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "shared folder" --menu "如需添加更多共享文件夹，请手动修改配置文件" 15 55 4 \
			"1" "DISABLE SHARE禁用共享" \
			"2" "${HOME}/sd" \
			"3" "windows共享说明" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) disable_qemu_host_shared_folder ;;
	2) modify_qemu_host_shared_folder_sdcard ;;
	3) echo '请单独使用webdav或Filebrowser文件共享功能，并在windows浏览器内输入局域网访问地址' ;;
	esac
	###############
	press_enter_to_return
	modify_qemu_host_shared_folder
}
#################
configure_mount_script() {
	cat >mount-9p-filesystem <<-'EOF'
		#!/usr/bin/env sh

		MOUNT_FOLDER="${HOME}/sd"
		MOUNT_NAME="shared0"
		mount_tmoe_linux_9p() {
		    mkdir -p "${MOUNT_FOLDER}"
		    if [ $(id -u) != "0" ]; then
		        sudo mount -t 9p -o trans=virtio ${MOUNT_NAME} "${MOUNT_FOLDER}" -o version=9p2000.L,posixacl,cache=mmap
		    else
		        mount -t 9p -o trans=virtio ${MOUNT_NAME} "${MOUNT_FOLDER}" -o version=9p2000.L,posixacl,cache=mmap
		    fi
		}

		df | grep "${MOUNT_FOLDER}" >/dev/null 2>&1 || mount_tmoe_linux_9p
	EOF
	chmod +x mount-9p-filesystem
	cd ~
	if ! grep -q 'mount-9p-filesystem' .zlogin; then
		echo "" >>.zlogin
		sed -i '$ a\/usr/local/bin/mount-9p-filesystem' .zlogin
	fi

	if ! grep -q 'mount-9p-filesystem' .profile; then
		echo "" >>.profile
		sed -i '$ a\/usr/local/bin/mount-9p-filesystem' .profile
	fi
	echo "若无法自动挂载，则请手动输${GREEN}mount-9p-filesystem${RESET}"
	mount-9p-filesystem
}
#############
disable_automatic_mount_qemu_folder() {
	cd ~
	sed -i '/mount-9p-filesystem/d' .profile .zlogin
}
##############
mount_qemu_guest_shared_folder() {
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "挂载磁盘" --menu "请在虚拟机环境下使用以下配置" 15 55 4 \
			"1" "configure配置挂载脚本" \
			"2" "DISABLE禁用自动挂载" \
			"3" "EDIT MANUALLY手动编辑挂载脚本" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) configure_mount_script ;;
	2) disable_automatic_mount_qemu_folder ;;
	3) nano /usr/local/bin/mount-9p-filesystem ;;
	esac
	###############
	press_enter_to_return
	mount_qemu_guest_shared_folder
}
##############
check_qemu_vnc_port() {
	START_QEMU_SCRIPT_PATH='/usr/local/bin/startqemu'
	if grep -q '\-vnc \:' "${START_QEMU_SCRIPT_PATH}"; then
		CURRENT_PORT=$(cat ${START_QEMU_SCRIPT_PATH} | grep '\-vnc ' | tail -n 1 | awk '{print $2}' | cut -d ':' -f 2 | tail -n 1)
		CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
	fi
	#CURRENT_PORT=$(cat startqemu | grep '\-vnc ' | tail -n 1 | awk '{print $2}' | cut -d ':' -f 2)
	#CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
}
#########################
modify_qemu_vnc_display_port() {
	if ! grep -q '\-vnc \:' "startqemu"; then
		echo "检测到您未启用VNC服务，是否启用？"
		do_you_want_to_continue
		sed -i "/-vnc :/d" startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -vnc :2 \\\n/' startqemu
		sed -i 's@export PULSE_SERVER.*@export PULSE_SERVER=127.0.0.1@' startqemu
	fi
	check_qemu_vnc_port
	TARGET=$(whiptail --inputbox "默认显示编号为2，默认VNC服务端口为5902，当前为${CURRENT_VNC_PORT} \nVNC服务以5900端口为起始，若显示编号为3,则端口为5903，请输入显示编号.Please enter the display number." 13 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)

	if [ "$?" != "0" ]; then
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		sed -i "s@-vnc :.*@-vnc :${TARGET} \\\@" startqemu
	fi

	echo 'Your current VNC port has been modified.'
	check_qemu_vnc_port
	echo '您当前VNC端口已修改为'
	echo ${CURRENT_VNC_PORT}
}
###############
choose_qemu_iso_file() {
	cd /usr/local/bin/
	FILE_EXT_01='iso'
	FILE_EXT_02='img'
	if grep -q '\--cdrom' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\--cdrom' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的iso文件为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到您当前没有加载iso"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		stat ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		#-cdrom /root/alpine-standard-3.11.6-x86_64.iso \
		sed -i '/--cdrom /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    --cdrom tmoe_iso_file_test \\\n/' startqemu
		sed -i "s@tmoe_iso_file_test@${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	fi
}
###############
where_is_tmoe_file_dir() {
	CURRENT_QEMU_ISO_FILENAME="$(echo ${CURRENT_QEMU_ISO} | awk -F '/' '{print $NF}')"
	if [ ! -z "${CURRENT_QEMU_ISO}" ]; then
		CURRENT_QEMU_ISO_FILEPATH="$(echo ${CURRENT_QEMU_ISO} | sed "s@${CURRENT_QEMU_ISO_FILENAME}@@")"
	fi

	if [ -d "${CURRENT_QEMU_ISO_FILEPATH}" ]; then
		START_DIR="${CURRENT_QEMU_ISO_FILEPATH}"
		tmoe_file_manager
	else
		where_is_start_dir
	fi
}
##############
choose_qemu_qcow2_or_img_file() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='img'
	cd /usr/local/bin
	if grep -q '\-hda' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hda' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到您当前没有加载虚拟磁盘"
	fi
	where_is_tmoe_file_dir

	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		#-hda /root/.aqemu/alpine_v3.11_x64.qcow2 \
		sed -i '/-hda /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hda tmoe_hda_config_test \\\n/' startqemu
		sed -i "s@-hda tmoe_hda_config_test@-hda ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
		#sed -i "s@-hda .*@-hda ${TMOE_FILE_ABSOLUTE_PATH} \\\@" startqemu
	fi
}
##########
choose_hdb_disk_image_file() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='vhd'
	if grep -q '\-hdb' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hdb' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的第二块虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到第二块虚拟磁盘的槽位为空"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		sed -i '/-hdb /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hdb tmoe_hda_config_test \\\n/' startqemu
		sed -i "s@-hdb tmoe_hda_config_test@-hdb ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	fi
}
##########
choose_hdc_disk_image_file() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='vmdk'
	if grep -q '\-hdc' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hdc' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的第三块虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到第三块虚拟磁盘的槽位为空"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		sed -i '/-hdc /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hdc tmoe_hda_config_test \\\n/' startqemu
		sed -i "s@-hdc tmoe_hda_config_test@-hdc ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	fi
}
##########
choose_hdd_disk_image_file() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='vdi'
	if grep -q '\-hdd' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hdd' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的第四块虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到第四块虚拟磁盘的槽位为空"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		sed -i '/-hdd /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hdd tmoe_hda_config_test \\\n/' startqemu
		sed -i "s@-hdd tmoe_hda_config_test@-hdd ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	fi
}
############
creat_blank_virtual_disk_image() {
	TARGET_FILE_NAME=$(whiptail --inputbox "请输入磁盘文件名称.\nPlease enter the filename." 10 50 --title "FILENAME" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET_FILE_NAME}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
		TARGET_FILE_NAME=$(date +%Y-%m-%d_%H-%M).qcow2
	else
		TARGET_FILE_NAME="${TARGET_FILE_NAME}.qcow2"
	fi
	DISK_FILE_PATH="${HOME}/sd/Download"
	mkdir -p ${DISK_FILE_PATH}
	cd ${DISK_FILE_PATH}
	TMOE_FILE_ABSOLUTE_PATH="${DISK_FILE_PATH}/${TARGET_FILE_NAME}"
	TARGET_FILE_SIZE=$(whiptail --inputbox "请设定磁盘空间大小,例如500M,10G,1T(需包含单位)\nPlease enter the disk size." 10 50 --title "SIZE" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET_FILE_SIZE}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
		echo "您输入了一个无效的数值，将为您自动创建16G大小的磁盘"
		do_you_want_to_continue
		#qemu-img create -f qcow2 -o preallocation=metadata ${TARGET_FILE_NAME} 16G
		qemu-img create -f qcow2 ${TARGET_FILE_NAME} 16G
	else
		qemu-img create -f qcow2 ${TARGET_FILE_NAME} ${TARGET_FILE_SIZE}
	fi
	stat ${TARGET_FILE_NAME}
	qemu-img info ${TARGET_FILE_NAME}
	ls -lh ${DISK_FILE_PATH}/${TARGET_FILE_NAME}
	echo "是否需要将其设置为默认磁盘？"
	echo "Do you need to set it as the default disk?"
	do_you_want_to_continue
	#sed -i "s@-hda .*@-hda ${DISK_FILE_PATH}/${TARGET_FILE_NAME} \\\@" /usr/local/bin/startqemu
	cd /usr/local/bin
	sed -i '/-hda /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hda tmoe_hda_config_test \\\n/' startqemu
	sed -i "s@-hda tmoe_hda_config_test@-hda ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
}
################
#-spice port=5931,image-compression=quic,renderer=cairo+oglpbuf+oglpixmap,disable-ticketing \
enable_qemnu_spice_remote() {
	cd /usr/local/bin/
	if grep -q '\-spice port=' startqemu; then
		TMOE_SPICE_STATUS='检测到您已启用speic'
	else
		TMOE_SPICE_STATUS='检测到您已禁用speic'
	fi
	###########
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？启用后将禁用vnc服务。${TMOE_SPICE_STATUS},默认spice端口为5931" 10 45); then
		sed -i '/-spice port=/d' startqemu
		sed -i "/-vnc :/d" startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -spice tmoe_spice_config_test \\\n/' startqemu
		sed -i "s@-spice tmoe_spice_config_test@-spice port=5931,image-compression=quic,disable-ticketing@" startqemu
		echo "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i '/-spice port=/d' startqemu
		echo "禁用完成"
	fi
}
############
enable_qemnu_win2k_hack() {
	cd /usr/local/bin/
	if grep -q '\-win2k-hack' startqemu; then
		TMOE_SPICE_STATUS='检测到您已启用win2k-hack'
	else
		TMOE_SPICE_STATUS='检测到您已禁用win2k-hack'
	fi
	###########
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？${TMOE_SPICE_STATUS}" 11 45); then
		sed -i '/-win2k-hack/d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -win2k-hack \\\n/' startqemu
		echo "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i '/-win2k-hack/d' startqemu
		echo "禁用完成"
	fi
}
##############
modify_qemu_sound_card() {
	RETURN_TO_WHERE='modify_qemu_sound_card'
	cd /usr/local/bin/
	if grep -q '\-soundhw ' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-soundhw ' | tail -n 1 | awk '{print $2}')
	else
		CURRENT_VALUE='未启用'
	fi
	VIRTUAL_TECH=$(
		whiptail --title "声卡型号" --menu "Please select the sound card model.\n检测到当前为${CURRENT_VALUE}" 16 50 7 \
			"1" "cs4312a" \
			"2" "sb16(Creative Sound Blaster 16)" \
			"3" "es1370(ENSONIQ AudioPCI ES1370)" \
			"4" "ac97(Intel 82801AA AC97)" \
			"5" "adlib:Yamaha YM3812 (OPL2)" \
			"6" "gus(Gravis Ultrasound GF1)" \
			"7" "hda(Intel HD Audio)" \
			"8" "pcspk(PC speaker)" \
			"9" "disable禁用声卡" \
			"10" "all启用所有" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_display_settings ;;
	1) QEMU_SOUNDHW='cs4312a' ;;
	2) QEMU_SOUNDHW='sb16' ;;
	3) QEMU_SOUNDHW='es1370' ;;
	4) QEMU_SOUNDHW='ac97' ;;
	5) QEMU_SOUNDHW='adlib' ;;
	6) QEMU_SOUNDHW='gus' ;;
	7) QEMU_SOUNDHW='hda' ;;
	8) QEMU_SOUNDHW='pcspk' ;;
	9) disable_tmoe_qemu_sound_card ;;
	10) QEMU_SOUNDHW='all' ;;
	esac
	###############
	tmoe_modify_qemu_sound_card
}
#############
qemu_snapshoots_manager() {
	echo "Sorry,请在qemu monitor下手动管理快照"
}
############
tmoe_qemu_todo_list() {
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "not todo list" --menu "以下功能可能不会适配，请手动管理qemu" 0 0 0 \
			"1" "snapshoots快照管理" \
			"2" "GPU pci passthrough显卡硬件直通" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	1) qemu_snapshoots_manager ;;
	2) tmoe_qemu_gpu_passthrough ;;
	esac
	press_enter_to_return
	tmoe_qemu_todo_list
}
##########
tmoe_qemu_gpu_passthrough() {
	echo "本功能需要使用双显卡，因开发者没有测试条件，故不会适配"
	echo "请自行研究qemu gpu passthrough"
}
##############
modify_qemu_amd64_tmoe_cpu_type() {
	cd /usr/local/bin/
	if grep -q '\-cpu' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-cpu' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	else
		CURRENT_VALUE='未指定'
	fi
	#qemu-system-x86_64 -cpu help >001
	#cat 001 | awk '{print $2}' >002
	#去掉:$
	#将\r替换为\n
	VIRTUAL_TECH=$(
		whiptail --title "CPU" --menu "默认为max,当前为${CURRENT_VALUE}" 0 0 0 \
			"0" "Return to previous menu 返回上级菜单" \
			"000" "disable禁用指定cpu参数" \
			"001" "486:(alias configured by machine type)" \
			"002" "486-v1" \
			"003" "Broadwell:(alias configured by machine type)" \
			"004" "Broadwell-IBRS:(alias of Broadwell-v3)" \
			"005" "Broadwell-noTSX:(alias of Broadwell-v2)" \
			"006" "Broadwell-noTSX-IBRS:(alias of Broadwell-v4)" \
			"007" "Broadwell-v1:Intel Core Processor (Broadwell)" \
			"008" "Broadwell-v2:Intel Core Processor (Broadwell, no TSX)" \
			"009" "Broadwell-v3:Intel Core Processor (Broadwell, IBRS)" \
			"010" "Broadwell-v4:Intel Core Processor (Broadwell, no TSX, IBRS)" \
			"011" "Cascadelake-Server:(alias configured by machine type)" \
			"012" "Cascadelake-Server-noTSX:(alias of Cascadelake-Server-v3)" \
			"013" "Cascadelake-Server-v1:Intel Xeon Processor (Cascadelake)" \
			"014" "Cascadelake-Server-v2:Intel Xeon Processor (Cascadelake)" \
			"015" "Cascadelake-Server-v3:Intel Xeon Processor (Cascadelake)" \
			"016" "Conroe:(alias configured by machine type)" \
			"017" "Conroe-v1:Intel Celeron_4x0 (Conroe/Merom Class Core 2)" \
			"018" "Cooperlake:(alias configured by machine type)" \
			"019" "Cooperlake-v1:Intel Xeon Processor (Cooperlake)" \
			"020" "Denverton:(alias configured by machine type)" \
			"021" "Denverton-v1:Intel Atom Processor (Denverton)" \
			"022" "Denverton-v2:Intel Atom Processor (Denverton)" \
			"023" "Dhyana:(alias configured by machine type)" \
			"024" "Dhyana-v1:Hygon Dhyana Processor" \
			"025" "EPYC:(alias configured by machine type)" \
			"026" "EPYC-IBPB:(alias of EPYC-v2)" \
			"027" "EPYC-Rome:(alias configured by machine type)" \
			"028" "EPYC-Rome-v1:AMD EPYC-Rome Processor" \
			"029" "EPYC-v1:AMD EPYC Processor" \
			"030" "EPYC-v2:AMD EPYC Processor (with IBPB)" \
			"031" "EPYC-v3:AMD EPYC Processor" \
			"032" "Haswell:(alias configured by machine type)" \
			"033" "Haswell-IBRS:(alias of Haswell-v3)" \
			"034" "Haswell-noTSX:(alias of Haswell-v2)" \
			"035" "Haswell-noTSX-IBRS:(alias of Haswell-v4)" \
			"036" "Haswell-v1:Intel Core Processor (Haswell)" \
			"037" "Haswell-v2:Intel Core Processor (Haswell, no TSX)" \
			"038" "Haswell-v3:Intel Core Processor (Haswell, IBRS)" \
			"039" "Haswell-v4:Intel Core Processor (Haswell, no TSX, IBRS)" \
			"040" "Icelake-Client:(alias configured by machine type)" \
			"041" "Icelake-Client-noTSX:(alias of Icelake-Client-v2)" \
			"042" "Icelake-Client-v1:Intel Core Processor (Icelake)" \
			"043" "Icelake-Client-v2:Intel Core Processor (Icelake)" \
			"044" "Icelake-Server:(alias configured by machine type)" \
			"045" "Icelake-Server-noTSX:(alias of Icelake-Server-v2)" \
			"046" "Icelake-Server-v1:Intel Xeon Processor (Icelake)" \
			"047" "Icelake-Server-v2:Intel Xeon Processor (Icelake)" \
			"048" "Icelake-Server-v3:Intel Xeon Processor (Icelake)" \
			"049" "IvyBridge:(alias configured by machine type)" \
			"050" "IvyBridge-IBRS:(alias of IvyBridge-v2)" \
			"051" "IvyBridge-v1:Intel Xeon E3-12xx v2 (Ivy Bridge)" \
			"052" "IvyBridge-v2:Intel Xeon E3-12xx v2 (Ivy Bridge, IBRS)" \
			"053" "KnightsMill:(alias configured by machine type)" \
			"054" "KnightsMill-v1:Intel Xeon Phi Processor (Knights Mill)" \
			"055" "Nehalem:(alias configured by machine type)" \
			"056" "Nehalem-IBRS:(alias of Nehalem-v2)" \
			"057" "Nehalem-v1:Intel Core i7 9xx (Nehalem Class Core i7)" \
			"058" "Nehalem-v2:Intel Core i7 9xx (Nehalem Core i7, IBRS update)" \
			"059" "Opteron_G1:(alias configured by machine type)" \
			"060" "Opteron_G1-v1:AMD Opteron 240 (Gen 1 Class Opteron)" \
			"061" "Opteron_G2:(alias configured by machine type)" \
			"062" "Opteron_G2-v1:AMD Opteron 22xx (Gen 2 Class Opteron)" \
			"063" "Opteron_G3:(alias configured by machine type)" \
			"064" "Opteron_G3-v1:AMD Opteron 23xx (Gen 3 Class Opteron)" \
			"065" "Opteron_G4:(alias configured by machine type)" \
			"066" "Opteron_G4-v1:AMD Opteron 62xx class CPU" \
			"067" "Opteron_G5:(alias configured by machine type)" \
			"068" "Opteron_G5-v1:AMD Opteron 63xx class CPU" \
			"069" "Penryn:(alias configured by machine type)" \
			"070" "Penryn-v1:Intel Core 2 Duo P9xxx (Penryn Class Core 2)" \
			"071" "SandyBridge:(alias configured by machine type)" \
			"072" "SandyBridge-IBRS:(alias of SandyBridge-v2)" \
			"073" "SandyBridge-v1:Intel Xeon E312xx (Sandy Bridge)" \
			"074" "SandyBridge-v2:Intel Xeon E312xx (Sandy Bridge, IBRS update)" \
			"075" "Skylake-Client:(alias configured by machine type)" \
			"076" "Skylake-Client-IBRS:(alias of Skylake-Client-v2)" \
			"077" "Skylake-Client-noTSX-IBRS:BRS  (alias of Skylake-Client-v3)" \
			"078" "Skylake-Client-v1:Intel Core Processor (Skylake)" \
			"079" "Skylake-Client-v2:Intel Core Processor (Skylake, IBRS)" \
			"080" "Skylake-Client-v3:Intel Core Processor (Skylake, IBRS, no TSX)" \
			"081" "Skylake-Server:(alias configured by machine type)" \
			"082" "Skylake-Server-IBRS:(alias of Skylake-Server-v2)" \
			"083" "Skylake-Server-noTSX-IBRS:BRS  (alias of Skylake-Server-v3)" \
			"084" "Skylake-Server-v1:Intel Xeon Processor (Skylake)" \
			"085" "Skylake-Server-v2:Intel Xeon Processor (Skylake, IBRS)" \
			"086" "Skylake-Server-v3:Intel Xeon Processor (Skylake, IBRS, no TSX)" \
			"087" "Snowridge:(alias configured by machine type)" \
			"088" "Snowridge-v1:Intel Atom Processor (SnowRidge)" \
			"089" "Snowridge-v2:Intel Atom Processor (Snowridge, no MPX)" \
			"090" "Westmere:(alias configured by machine type)" \
			"091" "Westmere-IBRS:(alias of Westmere-v2)" \
			"092" "Westmere-v1:Westmere E56xx/L56xx/X56xx (Nehalem-C)" \
			"093" "Westmere-v2:Westmere E56xx/L56xx/X56xx (IBRS update)" \
			"094" "athlon:(alias configured by machine type)" \
			"095" "athlon-v1:QEMU Virtual CPU version 2.5+" \
			"096" "core2duo:(alias configured by machine type)" \
			"097" "core2duo-v1:Intel(R) Core(TM)2 Duo CPU     T7700  @ 2.40GHz" \
			"098" "coreduo:(alias configured by machine type)" \
			"099" "coreduo-v1:Genuine Intel(R) CPU           T2600  @ 2.16GHz" \
			"100" "kvm32:(alias configured by machine type)" \
			"101" "kvm32-v1:Common 32-bit KVM processor" \
			"102" "kvm64:(alias configured by machine type)" \
			"103" "kvm64-v1:Common KVM processor" \
			"104" "n270:(alias configured by machine type)" \
			"105" "n270-v1:Intel(R) Atom(TM) CPU N270   @ 1.60GHz" \
			"106" "pentium:(alias configured by machine type)" \
			"107" "pentium-v1" \
			"108" "pentium2:(alias configured by machine type)" \
			"109" "pentium2-v1" \
			"110" "pentium3:(alias configured by machine type)" \
			"111" "pentium3-v1" \
			"112" "phenom:(alias configured by machine type)" \
			"113" "phenom-v1:AMD Phenom(tm) 9550 Quad-Core Processor" \
			"114" "qemu32:(alias configured by machine type)" \
			"115" "qemu32-v1:QEMU Virtual CPU version 2.5+" \
			"116" "qemu64:(alias configured by machine type)" \
			"117" "qemu64-v1:QEMU Virtual CPU version 2.5+" \
			"118" "base:base CPU model type with no features enabled" \
			"119" "host:KVM processor with all supported host features" \
			"120" "max:Enables all features supported by the accelerator in the current host" \
			"121" "3dnow" \
			"122" "3dnowext" \
			"123" "3dnowprefetch" \
			"124" "abm" \
			"125" "ace2" \
			"126" "ace2-en" \
			"127" "acpi" \
			"128" "adx" \
			"129" "aes" \
			"130" "amd-no-ssb" \
			"131" "amd-ssbd" \
			"132" "amd-stibp" \
			"133" "apic" \
			"134" "arat" \
			"135" "arch-capabilities" \
			"136" "avx" \
			"137" "avx2" \
			"138" "avx512-4fmaps" \
			"139" "avx512-4vnniw" \
			"140" "avx512-bf16" \
			"141" "avx512-vpopcntdq" \
			"142" "avx512bitalg" \
			"143" "avx512bw" \
			"144" "avx512cd" \
			"145" "avx512dq" \
			"146" "avx512er" \
			"147" "avx512f" \
			"148" "avx512ifma" \
			"149" "avx512pf" \
			"150" "avx512vbmi" \
			"151" "avx512vbmi2" \
			"152" "avx512vl" \
			"153" "avx512vnni" \
			"154" "bmi1" \
			"155" "bmi2" \
			"156" "cid" \
			"157" "cldemote" \
			"158" "clflush" \
			"159" "clflushopt" \
			"160" "clwb" \
			"161" "clzero" \
			"162" "cmov" \
			"163" "cmp-legacy" \
			"164" "core-capability" \
			"165" "cr8legacy" \
			"166" "cx16" \
			"167" "cx8" \
			"168" "dca" \
			"169" "de" \
			"170" "decodeassists" \
			"171" "ds" \
			"172" "ds-cpl" \
			"173" "dtes64" \
			"174" "erms" \
			"175" "est" \
			"176" "extapic" \
			"177" "f16c" \
			"178" "flushbyasid" \
			"179" "fma" \
			"180" "fma4" \
			"181" "fpu" \
			"182" "fsgsbase" \
			"183" "fxsr" \
			"184" "fxsr-opt" \
			"185" "gfni" \
			"186" "hle" \
			"187" "ht" \
			"188" "hypervisor" \
			"189" "ia64" \
			"190" "ibpb" \
			"191" "ibrs-all" \
			"192" "ibs" \
			"193" "intel-pt" \
			"194" "invpcid" \
			"195" "invtsc" \
			"196" "kvm-asyncpf" \
			"197" "kvm-hint-dedicated" \
			"198" "kvm-mmu" \
			"199" "kvm-nopiodelay" \
			"200" "kvm-poll-control" \
			"201" "kvm-pv-eoi" \
			"202" "kvm-pv-ipi" \
			"203" "kvm-pv-sched-yield" \
			"204" "kvm-pv-tlb-flush" \
			"205" "kvm-pv-unhalt" \
			"206" "kvm-steal-time" \
			"207" "kvmclock" \
			"208" "kvmclock" \
			"209" "kvmclock-stable-bit" \
			"210" "la57" \
			"211" "lahf-lm" \
			"212" "lbrv" \
			"213" "lm" \
			"214" "lwp" \
			"215" "mca" \
			"216" "mce" \
			"217" "md-clear" \
			"218" "mds-no" \
			"219" "misalignsse" \
			"220" "mmx" \
			"221" "mmxext" \
			"222" "monitor" \
			"223" "movbe" \
			"224" "movdir64b" \
			"225" "movdiri" \
			"226" "mpx" \
			"227" "msr" \
			"228" "mtrr" \
			"229" "nodeid-msr" \
			"230" "npt" \
			"231" "nrip-save" \
			"232" "nx" \
			"233" "osvw" \
			"234" "pae" \
			"235" "pat" \
			"236" "pause-filter" \
			"237" "pbe" \
			"238" "pcid" \
			"239" "pclmulqdq" \
			"240" "pcommit" \
			"241" "pdcm" \
			"242" "pdpe1gb" \
			"243" "perfctr-core" \
			"244" "perfctr-nb" \
			"245" "pfthreshold" \
			"246" "pge" \
			"247" "phe" \
			"248" "phe-en" \
			"249" "pku" \
			"250" "pmm" \
			"251" "pmm-en" \
			"252" "pn" \
			"253" "pni" \
			"254" "popcnt" \
			"255" "pschange-mc-no" \
			"256" "pse" \
			"257" "pse36" \
			"258" "rdctl-no" \
			"259" "rdpid" \
			"260" "rdrand" \
			"261" "rdseed" \
			"262" "rdtscp" \
			"263" "rsba" \
			"264" "rtm" \
			"265" "sep" \
			"266" "sha-ni" \
			"267" "skinit" \
			"268" "skip-l1dfl-vmentry" \
			"269" "smap" \
			"270" "smep" \
			"271" "smx" \
			"272" "spec-ctrl" \
			"273" "split-lock-detect" \
			"274" "ss" \
			"275" "ssb-no" \
			"276" "ssbd" \
			"277" "sse" \
			"278" "sse2" \
			"279" "sse4.1" \
			"280" "sse4.2" \
			"281" "sse4a" \
			"282" "ssse3" \
			"283" "stibp" \
			"284" "svm" \
			"285" "svm-lock" \
			"286" "syscall" \
			"287" "taa-no" \
			"288" "tbm" \
			"289" "tce" \
			"290" "tm" \
			"291" "tm2" \
			"292" "topoext" \
			"293" "tsc" \
			"294" "tsc-adjust" \
			"295" "tsc-deadline" \
			"296" "tsc-scale" \
			"297" "tsx-ctrl" \
			"298" "umip" \
			"299" "vaes" \
			"300" "virt-ssbd" \
			"301" "vmcb-clean" \
			"302" "vme" \
			"303" "vmx" \
			"304" "vmx-activity-hlt" \
			"305" "vmx-activity-shutdown" \
			"306" "vmx-activity-wait-sipi" \
			"307" "vmx-apicv-register" \
			"308" "vmx-apicv-vid" \
			"309" "vmx-apicv-x2apic" \
			"310" "vmx-apicv-xapic" \
			"311" "vmx-cr3-load-noexit" \
			"312" "vmx-cr3-store-noexit" \
			"313" "vmx-cr8-load-exit" \
			"314" "vmx-cr8-store-exit" \
			"315" "vmx-desc-exit" \
			"316" "vmx-encls-exit" \
			"317" "vmx-entry-ia32e-mode" \
			"318" "vmx-entry-load-bndcfgs" \
			"319" "vmx-entry-load-efer" \
			"320" "vmx-entry-load-pat" \
			"321" "vmx-entry-load-perf-global-ctrl" \
			"322" "vmx-entry-load-rtit-ctl" \
			"323" "vmx-entry-noload-debugctl" \
			"324" "vmx-ept" \
			"325" "vmx-ept-1gb" \
			"326" "vmx-ept-2mb" \
			"327" "vmx-ept-advanced-exitinfo" \
			"328" "vmx-ept-execonly" \
			"329" "vmx-eptad" \
			"330" "vmx-eptp-switching" \
			"331" "vmx-exit-ack-intr" \
			"332" "vmx-exit-clear-bndcfgs" \
			"333" "vmx-exit-clear-rtit-ctl" \
			"334" "vmx-exit-load-efer" \
			"335" "vmx-exit-load-pat" \
			"336" "vmx-exit-load-perf-global-ctrl" \
			"337" "vmx-exit-nosave-debugctl" \
			"338" "vmx-exit-save-efer" \
			"339" "vmx-exit-save-pat" \
			"340" "vmx-exit-save-preemption-timer" \
			"341" "vmx-flexpriority" \
			"342" "vmx-hlt-exit" \
			"343" "vmx-ins-outs" \
			"344" "vmx-intr-exit" \
			"345" "vmx-invept" \
			"346" "vmx-invept-all-context" \
			"347" "vmx-invept-single-context" \
			"348" "vmx-invept-context" \
			"349" "vmx-invept-single-context-noglobals" \
			"350" "vmx-invlpg-exit" \
			"351" "vmx-invpcid-exit" \
			"352" "vmx-invvpid" \
			"353" "vmx-invvpid-all-context" \
			"354" "vmx-invvpid-single-addr" \
			"355" "vmx-io-bitmap" \
			"356" "vmx-io-exit" \
			"357" "vmx-monitor-exit" \
			"358" "vmx-movdr-exit" \
			"359" "vmx-msr-bitmap" \
			"360" "vmx-mtf" \
			"361" "vmx-mwait-exit" \
			"362" "vmx-nmi-exit" \
			"363" "vmx-page-walk-4" \
			"364" "vmx-page-walk-5" \
			"365" "vmx-pause-exit" \
			"366" "vmx-ple" \
			"367" "vmx-pml" \
			"368" "vmx-posted-intr" \
			"369" "vmx-preemption-timer" \
			"370" "vmx-rdpmc-exit" \
			"371" "vmx-rdrand-exit" \
			"372" "vmx-rdseed-exit" \
			"373" "vmx-rdtsc-exit" \
			"374" "vmx-rdtscp-exit" \
			"375" "vmx-secondary-ctls" \
			"376" "vmx-shadow-vmcs" \
			"377" "vmx-store-lma" \
			"378" "vmx-true-ctls" \
			"379" "vmx-tsc-offset" \
			"380" "vmx-unrestricted-guest" \
			"381" "vmx-vintr-pending" \
			"382" "vmx-vmfunc" \
			"383" "vmx-vmwrite-vmexit-fields" \
			"384" "vmx-vnmi" \
			"385" "vmx-vnmi-pending" \
			"386" "vmx-vpid" \
			"387" "vmx-wbinvd-exit" \
			"388" "vmx-xsaves" \
			"389" "vmx-zero-len-inject" \
			"390" "vpclmulqdq" \
			"391" "waitpkg" \
			"392" "wbnoinvd" \
			"393" "wdt" \
			"394" "x2apic" \
			"395" "xcrypt" \
			"396" "xcrypt-en" \
			"397" "xgetbv1" \
			"398" "xop" \
			"399" "xsave" \
			"400" "xsavec" \
			"401" "xsaveerptr" \
			"402" "xsaveopt" \
			"403" "xsaves" \
			"404" "xstore" \
			"405" "xstore-en" \
			"406" "xtpr" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	000) disable_tmoe_qemu_cpu ;;
	001) TMOE_AMD64_QEMU_CPU_TYPE="486" ;;
	002) TMOE_AMD64_QEMU_CPU_TYPE="486-v1" ;;
	003) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell" ;;
	004) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-IBRS" ;;
	005) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-noTSX" ;;
	006) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-noTSX-IBRS" ;;
	007) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-v1" ;;
	008) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-v2" ;;
	009) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-v3" ;;
	010) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-v4" ;;
	011) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server" ;;
	012) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server-noTSX" ;;
	013) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server-v1" ;;
	014) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server-v2" ;;
	015) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server-v3" ;;
	016) TMOE_AMD64_QEMU_CPU_TYPE="Conroe" ;;
	017) TMOE_AMD64_QEMU_CPU_TYPE="Conroe-v1" ;;
	018) TMOE_AMD64_QEMU_CPU_TYPE="Cooperlake" ;;
	019) TMOE_AMD64_QEMU_CPU_TYPE="Cooperlake-v1" ;;
	020) TMOE_AMD64_QEMU_CPU_TYPE="Denverton" ;;
	021) TMOE_AMD64_QEMU_CPU_TYPE="Denverton-v1" ;;
	022) TMOE_AMD64_QEMU_CPU_TYPE="Denverton-v2" ;;
	023) TMOE_AMD64_QEMU_CPU_TYPE="Dhyana" ;;
	024) TMOE_AMD64_QEMU_CPU_TYPE="Dhyana-v1" ;;
	025) TMOE_AMD64_QEMU_CPU_TYPE="EPYC" ;;
	026) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-IBPB" ;;
	027) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-Rome" ;;
	028) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-Rome-v1" ;;
	029) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-v1" ;;
	030) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-v2" ;;
	031) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-v3" ;;
	032) TMOE_AMD64_QEMU_CPU_TYPE="Haswell" ;;
	033) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-IBRS" ;;
	034) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-noTSX" ;;
	035) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-noTSX-IBRS" ;;
	036) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-v1" ;;
	037) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-v2" ;;
	038) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-v3" ;;
	039) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-v4" ;;
	040) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Client" ;;
	041) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Client-noTSX" ;;
	042) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Client-v1" ;;
	043) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Client-v2" ;;
	044) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server" ;;
	045) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server-noTSX" ;;
	046) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server-v1" ;;
	047) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server-v2" ;;
	048) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server-v3" ;;
	049) TMOE_AMD64_QEMU_CPU_TYPE="IvyBridge" ;;
	050) TMOE_AMD64_QEMU_CPU_TYPE="IvyBridge-IBRS" ;;
	051) TMOE_AMD64_QEMU_CPU_TYPE="IvyBridge-v1" ;;
	052) TMOE_AMD64_QEMU_CPU_TYPE="IvyBridge-v2" ;;
	053) TMOE_AMD64_QEMU_CPU_TYPE="KnightsMill" ;;
	054) TMOE_AMD64_QEMU_CPU_TYPE="KnightsMill-v1" ;;
	055) TMOE_AMD64_QEMU_CPU_TYPE="Nehalem" ;;
	056) TMOE_AMD64_QEMU_CPU_TYPE="Nehalem-IBRS" ;;
	057) TMOE_AMD64_QEMU_CPU_TYPE="Nehalem-v1" ;;
	058) TMOE_AMD64_QEMU_CPU_TYPE="Nehalem-v2" ;;
	059) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G1" ;;
	060) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G1-v1" ;;
	061) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G2" ;;
	062) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G2-v1" ;;
	063) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G3" ;;
	064) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G3-v1" ;;
	065) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G4" ;;
	066) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G4-v1" ;;
	067) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G5" ;;
	068) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G5-v1" ;;
	069) TMOE_AMD64_QEMU_CPU_TYPE="Penryn" ;;
	070) TMOE_AMD64_QEMU_CPU_TYPE="Penryn-v1" ;;
	071) TMOE_AMD64_QEMU_CPU_TYPE="SandyBridge" ;;
	072) TMOE_AMD64_QEMU_CPU_TYPE="SandyBridge-IBRS" ;;
	073) TMOE_AMD64_QEMU_CPU_TYPE="SandyBridge-v1" ;;
	074) TMOE_AMD64_QEMU_CPU_TYPE="SandyBridge-v2" ;;
	075) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client" ;;
	076) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-IBRS" ;;
	077) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-noTSX-IBRS" ;;
	078) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-v1" ;;
	079) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-v2" ;;
	080) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-v3" ;;
	081) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server" ;;
	082) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-IBRS" ;;
	083) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-noTSX-IBRS" ;;
	084) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-v1" ;;
	085) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-v2" ;;
	086) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-v3" ;;
	087) TMOE_AMD64_QEMU_CPU_TYPE="Snowridge" ;;
	088) TMOE_AMD64_QEMU_CPU_TYPE="Snowridge-v1" ;;
	089) TMOE_AMD64_QEMU_CPU_TYPE="Snowridge-v2" ;;
	090) TMOE_AMD64_QEMU_CPU_TYPE="Westmere" ;;
	091) TMOE_AMD64_QEMU_CPU_TYPE="Westmere-IBRS" ;;
	092) TMOE_AMD64_QEMU_CPU_TYPE="Westmere-v1" ;;
	093) TMOE_AMD64_QEMU_CPU_TYPE="Westmere-v2" ;;
	094) TMOE_AMD64_QEMU_CPU_TYPE="athlon" ;;
	095) TMOE_AMD64_QEMU_CPU_TYPE="athlon-v1" ;;
	096) TMOE_AMD64_QEMU_CPU_TYPE="core2duo" ;;
	097) TMOE_AMD64_QEMU_CPU_TYPE="core2duo-v1" ;;
	098) TMOE_AMD64_QEMU_CPU_TYPE="coreduo" ;;
	099) TMOE_AMD64_QEMU_CPU_TYPE="coreduo-v1" ;;
	100) TMOE_AMD64_QEMU_CPU_TYPE="kvm32" ;;
	101) TMOE_AMD64_QEMU_CPU_TYPE="kvm32-v1" ;;
	102) TMOE_AMD64_QEMU_CPU_TYPE="kvm64" ;;
	103) TMOE_AMD64_QEMU_CPU_TYPE="kvm64-v1" ;;
	104) TMOE_AMD64_QEMU_CPU_TYPE="n270" ;;
	105) TMOE_AMD64_QEMU_CPU_TYPE="n270-v1" ;;
	106) TMOE_AMD64_QEMU_CPU_TYPE="pentium" ;;
	107) TMOE_AMD64_QEMU_CPU_TYPE="pentium-v1" ;;
	108) TMOE_AMD64_QEMU_CPU_TYPE="pentium2" ;;
	109) TMOE_AMD64_QEMU_CPU_TYPE="pentium2-v1" ;;
	110) TMOE_AMD64_QEMU_CPU_TYPE="pentium3" ;;
	111) TMOE_AMD64_QEMU_CPU_TYPE="pentium3-v1" ;;
	112) TMOE_AMD64_QEMU_CPU_TYPE="phenom" ;;
	113) TMOE_AMD64_QEMU_CPU_TYPE="phenom-v1" ;;
	114) TMOE_AMD64_QEMU_CPU_TYPE="qemu32" ;;
	115) TMOE_AMD64_QEMU_CPU_TYPE="qemu32-v1" ;;
	116) TMOE_AMD64_QEMU_CPU_TYPE="qemu64" ;;
	117) TMOE_AMD64_QEMU_CPU_TYPE="qemu64-v1" ;;
	118) TMOE_AMD64_QEMU_CPU_TYPE="base" ;;
	119) TMOE_AMD64_QEMU_CPU_TYPE="host" ;;
	120) TMOE_AMD64_QEMU_CPU_TYPE="max" ;;
	121) TMOE_AMD64_QEMU_CPU_TYPE="3dnow" ;;
	122) TMOE_AMD64_QEMU_CPU_TYPE="3dnowext" ;;
	123) TMOE_AMD64_QEMU_CPU_TYPE="3dnowprefetch" ;;
	124) TMOE_AMD64_QEMU_CPU_TYPE="abm" ;;
	125) TMOE_AMD64_QEMU_CPU_TYPE="ace2" ;;
	126) TMOE_AMD64_QEMU_CPU_TYPE="ace2-en" ;;
	127) TMOE_AMD64_QEMU_CPU_TYPE="acpi" ;;
	128) TMOE_AMD64_QEMU_CPU_TYPE="adx" ;;
	129) TMOE_AMD64_QEMU_CPU_TYPE="aes" ;;
	130) TMOE_AMD64_QEMU_CPU_TYPE="amd-no-ssb" ;;
	131) TMOE_AMD64_QEMU_CPU_TYPE="amd-ssbd" ;;
	132) TMOE_AMD64_QEMU_CPU_TYPE="amd-stibp" ;;
	133) TMOE_AMD64_QEMU_CPU_TYPE="apic" ;;
	134) TMOE_AMD64_QEMU_CPU_TYPE="arat" ;;
	135) TMOE_AMD64_QEMU_CPU_TYPE="arch-capabilities" ;;
	136) TMOE_AMD64_QEMU_CPU_TYPE="avx" ;;
	137) TMOE_AMD64_QEMU_CPU_TYPE="avx2" ;;
	138) TMOE_AMD64_QEMU_CPU_TYPE="avx512-4fmaps" ;;
	139) TMOE_AMD64_QEMU_CPU_TYPE="avx512-4vnniw" ;;
	140) TMOE_AMD64_QEMU_CPU_TYPE="avx512-bf16" ;;
	141) TMOE_AMD64_QEMU_CPU_TYPE="avx512-vpopcntdq" ;;
	142) TMOE_AMD64_QEMU_CPU_TYPE="avx512bitalg" ;;
	143) TMOE_AMD64_QEMU_CPU_TYPE="avx512bw" ;;
	144) TMOE_AMD64_QEMU_CPU_TYPE="avx512cd" ;;
	145) TMOE_AMD64_QEMU_CPU_TYPE="avx512dq" ;;
	146) TMOE_AMD64_QEMU_CPU_TYPE="avx512er" ;;
	147) TMOE_AMD64_QEMU_CPU_TYPE="avx512f" ;;
	148) TMOE_AMD64_QEMU_CPU_TYPE="avx512ifma" ;;
	149) TMOE_AMD64_QEMU_CPU_TYPE="avx512pf" ;;
	150) TMOE_AMD64_QEMU_CPU_TYPE="avx512vbmi" ;;
	151) TMOE_AMD64_QEMU_CPU_TYPE="avx512vbmi2" ;;
	152) TMOE_AMD64_QEMU_CPU_TYPE="avx512vl" ;;
	153) TMOE_AMD64_QEMU_CPU_TYPE="avx512vnni" ;;
	154) TMOE_AMD64_QEMU_CPU_TYPE="bmi1" ;;
	155) TMOE_AMD64_QEMU_CPU_TYPE="bmi2" ;;
	156) TMOE_AMD64_QEMU_CPU_TYPE="cid" ;;
	157) TMOE_AMD64_QEMU_CPU_TYPE="cldemote" ;;
	158) TMOE_AMD64_QEMU_CPU_TYPE="clflush" ;;
	159) TMOE_AMD64_QEMU_CPU_TYPE="clflushopt" ;;
	160) TMOE_AMD64_QEMU_CPU_TYPE="clwb" ;;
	161) TMOE_AMD64_QEMU_CPU_TYPE="clzero" ;;
	162) TMOE_AMD64_QEMU_CPU_TYPE="cmov" ;;
	163) TMOE_AMD64_QEMU_CPU_TYPE="cmp-legacy" ;;
	164) TMOE_AMD64_QEMU_CPU_TYPE="core-capability" ;;
	165) TMOE_AMD64_QEMU_CPU_TYPE="cr8legacy" ;;
	166) TMOE_AMD64_QEMU_CPU_TYPE="cx16" ;;
	167) TMOE_AMD64_QEMU_CPU_TYPE="cx8" ;;
	168) TMOE_AMD64_QEMU_CPU_TYPE="dca" ;;
	169) TMOE_AMD64_QEMU_CPU_TYPE="de" ;;
	170) TMOE_AMD64_QEMU_CPU_TYPE="decodeassists" ;;
	171) TMOE_AMD64_QEMU_CPU_TYPE="ds" ;;
	172) TMOE_AMD64_QEMU_CPU_TYPE="ds-cpl" ;;
	173) TMOE_AMD64_QEMU_CPU_TYPE="dtes64" ;;
	174) TMOE_AMD64_QEMU_CPU_TYPE="erms" ;;
	175) TMOE_AMD64_QEMU_CPU_TYPE="est" ;;
	176) TMOE_AMD64_QEMU_CPU_TYPE="extapic" ;;
	177) TMOE_AMD64_QEMU_CPU_TYPE="f16c" ;;
	178) TMOE_AMD64_QEMU_CPU_TYPE="flushbyasid" ;;
	179) TMOE_AMD64_QEMU_CPU_TYPE="fma" ;;
	180) TMOE_AMD64_QEMU_CPU_TYPE="fma4" ;;
	181) TMOE_AMD64_QEMU_CPU_TYPE="fpu" ;;
	182) TMOE_AMD64_QEMU_CPU_TYPE="fsgsbase" ;;
	183) TMOE_AMD64_QEMU_CPU_TYPE="fxsr" ;;
	184) TMOE_AMD64_QEMU_CPU_TYPE="fxsr-opt" ;;
	185) TMOE_AMD64_QEMU_CPU_TYPE="gfni" ;;
	186) TMOE_AMD64_QEMU_CPU_TYPE="hle" ;;
	187) TMOE_AMD64_QEMU_CPU_TYPE="ht" ;;
	188) TMOE_AMD64_QEMU_CPU_TYPE="hypervisor" ;;
	189) TMOE_AMD64_QEMU_CPU_TYPE="ia64" ;;
	190) TMOE_AMD64_QEMU_CPU_TYPE="ibpb" ;;
	191) TMOE_AMD64_QEMU_CPU_TYPE="ibrs-all" ;;
	192) TMOE_AMD64_QEMU_CPU_TYPE="ibs" ;;
	193) TMOE_AMD64_QEMU_CPU_TYPE="intel-pt" ;;
	194) TMOE_AMD64_QEMU_CPU_TYPE="invpcid" ;;
	195) TMOE_AMD64_QEMU_CPU_TYPE="invtsc" ;;
	196) TMOE_AMD64_QEMU_CPU_TYPE="kvm-asyncpf" ;;
	197) TMOE_AMD64_QEMU_CPU_TYPE="kvm-hint-dedicated" ;;
	198) TMOE_AMD64_QEMU_CPU_TYPE="kvm-mmu" ;;
	199) TMOE_AMD64_QEMU_CPU_TYPE="kvm-nopiodelay" ;;
	200) TMOE_AMD64_QEMU_CPU_TYPE="kvm-poll-control" ;;
	201) TMOE_AMD64_QEMU_CPU_TYPE="kvm-pv-eoi" ;;
	202) TMOE_AMD64_QEMU_CPU_TYPE="kvm-pv-ipi" ;;
	203) TMOE_AMD64_QEMU_CPU_TYPE="kvm-pv-sched-yield" ;;
	204) TMOE_AMD64_QEMU_CPU_TYPE="kvm-pv-tlb-flush" ;;
	205) TMOE_AMD64_QEMU_CPU_TYPE="kvm-pv-unhalt" ;;
	206) TMOE_AMD64_QEMU_CPU_TYPE="kvm-steal-time" ;;
	207) TMOE_AMD64_QEMU_CPU_TYPE="kvmclock" ;;
	208) TMOE_AMD64_QEMU_CPU_TYPE="kvmclock" ;;
	209) TMOE_AMD64_QEMU_CPU_TYPE="kvmclock-stable-bit" ;;
	210) TMOE_AMD64_QEMU_CPU_TYPE="la57" ;;
	211) TMOE_AMD64_QEMU_CPU_TYPE="lahf-lm" ;;
	212) TMOE_AMD64_QEMU_CPU_TYPE="lbrv" ;;
	213) TMOE_AMD64_QEMU_CPU_TYPE="lm" ;;
	214) TMOE_AMD64_QEMU_CPU_TYPE="lwp" ;;
	215) TMOE_AMD64_QEMU_CPU_TYPE="mca" ;;
	216) TMOE_AMD64_QEMU_CPU_TYPE="mce" ;;
	217) TMOE_AMD64_QEMU_CPU_TYPE="md-clear" ;;
	218) TMOE_AMD64_QEMU_CPU_TYPE="mds-no" ;;
	219) TMOE_AMD64_QEMU_CPU_TYPE="misalignsse" ;;
	220) TMOE_AMD64_QEMU_CPU_TYPE="mmx" ;;
	221) TMOE_AMD64_QEMU_CPU_TYPE="mmxext" ;;
	222) TMOE_AMD64_QEMU_CPU_TYPE="monitor" ;;
	223) TMOE_AMD64_QEMU_CPU_TYPE="movbe" ;;
	224) TMOE_AMD64_QEMU_CPU_TYPE="movdir64b" ;;
	225) TMOE_AMD64_QEMU_CPU_TYPE="movdiri" ;;
	226) TMOE_AMD64_QEMU_CPU_TYPE="mpx" ;;
	227) TMOE_AMD64_QEMU_CPU_TYPE="msr" ;;
	228) TMOE_AMD64_QEMU_CPU_TYPE="mtrr" ;;
	229) TMOE_AMD64_QEMU_CPU_TYPE="nodeid-msr" ;;
	230) TMOE_AMD64_QEMU_CPU_TYPE="npt" ;;
	231) TMOE_AMD64_QEMU_CPU_TYPE="nrip-save" ;;
	232) TMOE_AMD64_QEMU_CPU_TYPE="nx" ;;
	233) TMOE_AMD64_QEMU_CPU_TYPE="osvw" ;;
	234) TMOE_AMD64_QEMU_CPU_TYPE="pae" ;;
	235) TMOE_AMD64_QEMU_CPU_TYPE="pat" ;;
	236) TMOE_AMD64_QEMU_CPU_TYPE="pause-filter" ;;
	237) TMOE_AMD64_QEMU_CPU_TYPE="pbe" ;;
	238) TMOE_AMD64_QEMU_CPU_TYPE="pcid" ;;
	239) TMOE_AMD64_QEMU_CPU_TYPE="pclmulqdq" ;;
	240) TMOE_AMD64_QEMU_CPU_TYPE="pcommit" ;;
	241) TMOE_AMD64_QEMU_CPU_TYPE="pdcm" ;;
	242) TMOE_AMD64_QEMU_CPU_TYPE="pdpe1gb" ;;
	243) TMOE_AMD64_QEMU_CPU_TYPE="perfctr-core" ;;
	244) TMOE_AMD64_QEMU_CPU_TYPE="perfctr-nb" ;;
	245) TMOE_AMD64_QEMU_CPU_TYPE="pfthreshold" ;;
	246) TMOE_AMD64_QEMU_CPU_TYPE="pge" ;;
	247) TMOE_AMD64_QEMU_CPU_TYPE="phe" ;;
	248) TMOE_AMD64_QEMU_CPU_TYPE="phe-en" ;;
	249) TMOE_AMD64_QEMU_CPU_TYPE="pku" ;;
	250) TMOE_AMD64_QEMU_CPU_TYPE="pmm" ;;
	251) TMOE_AMD64_QEMU_CPU_TYPE="pmm-en" ;;
	252) TMOE_AMD64_QEMU_CPU_TYPE="pn" ;;
	253) TMOE_AMD64_QEMU_CPU_TYPE="pni" ;;
	254) TMOE_AMD64_QEMU_CPU_TYPE="popcnt" ;;
	255) TMOE_AMD64_QEMU_CPU_TYPE="pschange-mc-no" ;;
	256) TMOE_AMD64_QEMU_CPU_TYPE="pse" ;;
	257) TMOE_AMD64_QEMU_CPU_TYPE="pse36" ;;
	258) TMOE_AMD64_QEMU_CPU_TYPE="rdctl-no" ;;
	259) TMOE_AMD64_QEMU_CPU_TYPE="rdpid" ;;
	260) TMOE_AMD64_QEMU_CPU_TYPE="rdrand" ;;
	261) TMOE_AMD64_QEMU_CPU_TYPE="rdseed" ;;
	262) TMOE_AMD64_QEMU_CPU_TYPE="rdtscp" ;;
	263) TMOE_AMD64_QEMU_CPU_TYPE="rsba" ;;
	264) TMOE_AMD64_QEMU_CPU_TYPE="rtm" ;;
	265) TMOE_AMD64_QEMU_CPU_TYPE="sep" ;;
	266) TMOE_AMD64_QEMU_CPU_TYPE="sha-ni" ;;
	267) TMOE_AMD64_QEMU_CPU_TYPE="skinit" ;;
	268) TMOE_AMD64_QEMU_CPU_TYPE="skip-l1dfl-vmentry" ;;
	269) TMOE_AMD64_QEMU_CPU_TYPE="smap" ;;
	270) TMOE_AMD64_QEMU_CPU_TYPE="smep" ;;
	271) TMOE_AMD64_QEMU_CPU_TYPE="smx" ;;
	272) TMOE_AMD64_QEMU_CPU_TYPE="spec-ctrl" ;;
	273) TMOE_AMD64_QEMU_CPU_TYPE="split-lock-detect" ;;
	274) TMOE_AMD64_QEMU_CPU_TYPE="ss" ;;
	275) TMOE_AMD64_QEMU_CPU_TYPE="ssb-no" ;;
	276) TMOE_AMD64_QEMU_CPU_TYPE="ssbd" ;;
	277) TMOE_AMD64_QEMU_CPU_TYPE="sse" ;;
	278) TMOE_AMD64_QEMU_CPU_TYPE="sse2" ;;
	279) TMOE_AMD64_QEMU_CPU_TYPE="sse4.1" ;;
	280) TMOE_AMD64_QEMU_CPU_TYPE="sse4.2" ;;
	281) TMOE_AMD64_QEMU_CPU_TYPE="sse4a" ;;
	282) TMOE_AMD64_QEMU_CPU_TYPE="ssse3" ;;
	283) TMOE_AMD64_QEMU_CPU_TYPE="stibp" ;;
	284) TMOE_AMD64_QEMU_CPU_TYPE="svm" ;;
	285) TMOE_AMD64_QEMU_CPU_TYPE="svm-lock" ;;
	286) TMOE_AMD64_QEMU_CPU_TYPE="syscall" ;;
	287) TMOE_AMD64_QEMU_CPU_TYPE="taa-no" ;;
	288) TMOE_AMD64_QEMU_CPU_TYPE="tbm" ;;
	289) TMOE_AMD64_QEMU_CPU_TYPE="tce" ;;
	290) TMOE_AMD64_QEMU_CPU_TYPE="tm" ;;
	291) TMOE_AMD64_QEMU_CPU_TYPE="tm2" ;;
	292) TMOE_AMD64_QEMU_CPU_TYPE="topoext" ;;
	293) TMOE_AMD64_QEMU_CPU_TYPE="tsc" ;;
	294) TMOE_AMD64_QEMU_CPU_TYPE="tsc-adjust" ;;
	295) TMOE_AMD64_QEMU_CPU_TYPE="tsc-deadline" ;;
	296) TMOE_AMD64_QEMU_CPU_TYPE="tsc-scale" ;;
	297) TMOE_AMD64_QEMU_CPU_TYPE="tsx-ctrl" ;;
	298) TMOE_AMD64_QEMU_CPU_TYPE="umip" ;;
	299) TMOE_AMD64_QEMU_CPU_TYPE="vaes" ;;
	300) TMOE_AMD64_QEMU_CPU_TYPE="virt-ssbd" ;;
	301) TMOE_AMD64_QEMU_CPU_TYPE="vmcb-clean" ;;
	302) TMOE_AMD64_QEMU_CPU_TYPE="vme" ;;
	303) TMOE_AMD64_QEMU_CPU_TYPE="vmx" ;;
	304) TMOE_AMD64_QEMU_CPU_TYPE="vmx-activity-hlt" ;;
	305) TMOE_AMD64_QEMU_CPU_TYPE="vmx-activity-shutdown" ;;
	306) TMOE_AMD64_QEMU_CPU_TYPE="vmx-activity-wait-sipi" ;;
	307) TMOE_AMD64_QEMU_CPU_TYPE="vmx-apicv-register" ;;
	308) TMOE_AMD64_QEMU_CPU_TYPE="vmx-apicv-vid" ;;
	309) TMOE_AMD64_QEMU_CPU_TYPE="vmx-apicv-x2apic" ;;
	310) TMOE_AMD64_QEMU_CPU_TYPE="vmx-apicv-xapic" ;;
	311) TMOE_AMD64_QEMU_CPU_TYPE="vmx-cr3-load-noexit" ;;
	312) TMOE_AMD64_QEMU_CPU_TYPE="vmx-cr3-store-noexit" ;;
	313) TMOE_AMD64_QEMU_CPU_TYPE="vmx-cr8-load-exit" ;;
	314) TMOE_AMD64_QEMU_CPU_TYPE="vmx-cr8-store-exit" ;;
	315) TMOE_AMD64_QEMU_CPU_TYPE="vmx-desc-exit" ;;
	316) TMOE_AMD64_QEMU_CPU_TYPE="vmx-encls-exit" ;;
	317) TMOE_AMD64_QEMU_CPU_TYPE="vmx-entry-ia32e-mode" ;;
	318) TMOE_AMD64_QEMU_CPU_TYPE="vmx-entry-load-bndcfgs" ;;
	319) TMOE_AMD64_QEMU_CPU_TYPE="vmx-entry-load-efer" ;;
	320) TMOE_AMD64_QEMU_CPU_TYPE="vmx-entry-load-pat" ;;
	321) TMOE_AMD64_QEMU_CPU_TYPE="vmx-entry-load-perf-global-ctrl" ;;
	322) TMOE_AMD64_QEMU_CPU_TYPE="vmx-entry-load-rtit-ctl" ;;
	323) TMOE_AMD64_QEMU_CPU_TYPE="vmx-entry-noload-debugctl" ;;
	324) TMOE_AMD64_QEMU_CPU_TYPE="vmx-ept" ;;
	325) TMOE_AMD64_QEMU_CPU_TYPE="vmx-ept-1gb" ;;
	326) TMOE_AMD64_QEMU_CPU_TYPE="vmx-ept-2mb" ;;
	327) TMOE_AMD64_QEMU_CPU_TYPE="vmx-ept-advanced-exitinfo" ;;
	328) TMOE_AMD64_QEMU_CPU_TYPE="vmx-ept-execonly" ;;
	329) TMOE_AMD64_QEMU_CPU_TYPE="vmx-eptad" ;;
	330) TMOE_AMD64_QEMU_CPU_TYPE="vmx-eptp-switching" ;;
	331) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-ack-intr" ;;
	332) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-clear-bndcfgs" ;;
	333) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-clear-rtit-ctl" ;;
	334) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-load-efer" ;;
	335) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-load-pat" ;;
	336) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-load-perf-global-ctrl" ;;
	337) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-nosave-debugctl" ;;
	338) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-save-efer" ;;
	339) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-save-pat" ;;
	340) TMOE_AMD64_QEMU_CPU_TYPE="vmx-exit-save-preemption-timer" ;;
	341) TMOE_AMD64_QEMU_CPU_TYPE="vmx-flexpriority" ;;
	342) TMOE_AMD64_QEMU_CPU_TYPE="vmx-hlt-exit" ;;
	343) TMOE_AMD64_QEMU_CPU_TYPE="vmx-ins-outs" ;;
	344) TMOE_AMD64_QEMU_CPU_TYPE="vmx-intr-exit" ;;
	345) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invept" ;;
	346) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invept-all-context" ;;
	347) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invept-single-context" ;;
	348) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invept-context" ;;
	349) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invept-single-context-noglobals" ;;
	350) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invlpg-exit" ;;
	351) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invpcid-exit" ;;
	352) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invvpid" ;;
	353) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invvpid-all-context" ;;
	354) TMOE_AMD64_QEMU_CPU_TYPE="vmx-invvpid-single-addr" ;;
	355) TMOE_AMD64_QEMU_CPU_TYPE="vmx-io-bitmap" ;;
	356) TMOE_AMD64_QEMU_CPU_TYPE="vmx-io-exit" ;;
	357) TMOE_AMD64_QEMU_CPU_TYPE="vmx-monitor-exit" ;;
	358) TMOE_AMD64_QEMU_CPU_TYPE="vmx-movdr-exit" ;;
	359) TMOE_AMD64_QEMU_CPU_TYPE="vmx-msr-bitmap" ;;
	360) TMOE_AMD64_QEMU_CPU_TYPE="vmx-mtf" ;;
	361) TMOE_AMD64_QEMU_CPU_TYPE="vmx-mwait-exit" ;;
	362) TMOE_AMD64_QEMU_CPU_TYPE="vmx-nmi-exit" ;;
	363) TMOE_AMD64_QEMU_CPU_TYPE="vmx-page-walk-4" ;;
	364) TMOE_AMD64_QEMU_CPU_TYPE="vmx-page-walk-5" ;;
	365) TMOE_AMD64_QEMU_CPU_TYPE="vmx-pause-exit" ;;
	366) TMOE_AMD64_QEMU_CPU_TYPE="vmx-ple" ;;
	367) TMOE_AMD64_QEMU_CPU_TYPE="vmx-pml" ;;
	368) TMOE_AMD64_QEMU_CPU_TYPE="vmx-posted-intr" ;;
	369) TMOE_AMD64_QEMU_CPU_TYPE="vmx-preemption-timer" ;;
	370) TMOE_AMD64_QEMU_CPU_TYPE="vmx-rdpmc-exit" ;;
	371) TMOE_AMD64_QEMU_CPU_TYPE="vmx-rdrand-exit" ;;
	372) TMOE_AMD64_QEMU_CPU_TYPE="vmx-rdseed-exit" ;;
	373) TMOE_AMD64_QEMU_CPU_TYPE="vmx-rdtsc-exit" ;;
	374) TMOE_AMD64_QEMU_CPU_TYPE="vmx-rdtscp-exit" ;;
	375) TMOE_AMD64_QEMU_CPU_TYPE="vmx-secondary-ctls" ;;
	376) TMOE_AMD64_QEMU_CPU_TYPE="vmx-shadow-vmcs" ;;
	377) TMOE_AMD64_QEMU_CPU_TYPE="vmx-store-lma" ;;
	378) TMOE_AMD64_QEMU_CPU_TYPE="vmx-true-ctls" ;;
	379) TMOE_AMD64_QEMU_CPU_TYPE="vmx-tsc-offset" ;;
	380) TMOE_AMD64_QEMU_CPU_TYPE="vmx-unrestricted-guest" ;;
	381) TMOE_AMD64_QEMU_CPU_TYPE="vmx-vintr-pending" ;;
	382) TMOE_AMD64_QEMU_CPU_TYPE="vmx-vmfunc" ;;
	383) TMOE_AMD64_QEMU_CPU_TYPE="vmx-vmwrite-vmexit-fields" ;;
	384) TMOE_AMD64_QEMU_CPU_TYPE="vmx-vnmi" ;;
	385) TMOE_AMD64_QEMU_CPU_TYPE="vmx-vnmi-pending" ;;
	386) TMOE_AMD64_QEMU_CPU_TYPE="vmx-vpid" ;;
	387) TMOE_AMD64_QEMU_CPU_TYPE="vmx-wbinvd-exit" ;;
	388) TMOE_AMD64_QEMU_CPU_TYPE="vmx-xsaves" ;;
	389) TMOE_AMD64_QEMU_CPU_TYPE="vmx-zero-len-inject" ;;
	390) TMOE_AMD64_QEMU_CPU_TYPE="vpclmulqdq" ;;
	391) TMOE_AMD64_QEMU_CPU_TYPE="waitpkg" ;;
	392) TMOE_AMD64_QEMU_CPU_TYPE="wbnoinvd" ;;
	393) TMOE_AMD64_QEMU_CPU_TYPE="wdt" ;;
	394) TMOE_AMD64_QEMU_CPU_TYPE="x2apic" ;;
	395) TMOE_AMD64_QEMU_CPU_TYPE="xcrypt" ;;
	396) TMOE_AMD64_QEMU_CPU_TYPE="xcrypt-en" ;;
	397) TMOE_AMD64_QEMU_CPU_TYPE="xgetbv1" ;;
	398) TMOE_AMD64_QEMU_CPU_TYPE="xop" ;;
	399) TMOE_AMD64_QEMU_CPU_TYPE="xsave" ;;
	400) TMOE_AMD64_QEMU_CPU_TYPE="xsavec" ;;
	401) TMOE_AMD64_QEMU_CPU_TYPE="xsaveerptr" ;;
	402) TMOE_AMD64_QEMU_CPU_TYPE="xsaveopt" ;;
	403) TMOE_AMD64_QEMU_CPU_TYPE="xsaves" ;;
	404) TMOE_AMD64_QEMU_CPU_TYPE="xstore" ;;
	405) TMOE_AMD64_QEMU_CPU_TYPE="xstore-en" ;;
	406) TMOE_AMD64_QEMU_CPU_TYPE="xtpr" ;;
	esac
	###############
	sed -i '/-cpu /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -cpu tmoe_cpu_config_test \\\n/' startqemu
	sed -i "s@-cpu tmoe_cpu_config_test@-cpu ${TMOE_AMD64_QEMU_CPU_TYPE}@" startqemu
	echo "您已将cpu修改为${TMOE_AMD64_QEMU_CPU_TYPE}"
	echo "修改完成，将在下次启动qemu虚拟机时生效"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
disable_tmoe_qemu_cpu() {
	sed -i '/-cpu /d' startqemu
	echo "禁用完成"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
modify_qemu_amd64_tmoe_machine_type() {
	cd /usr/local/bin/
	if grep -q '\-M ' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-M ' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	else
		CURRENT_VALUE='默认'
	fi
	#qemu-system-x86_64 -machine help >001
	#cat 001 |awk '{print $1}' >002
	#paste 002 003 -d ':'
	VIRTUAL_TECH=$(
		whiptail --title "MACHINE" --menu "Please select the machine type.\n默认为pc-i440fx,当前为${CURRENT_VALUE}" 0 0 0 \
			"0" "Return to previous menu 返回上级菜单" \
			"00" "disable禁用指定机器类型参数" \
			"01" "microvm:microvm (i386)" \
			"02" "xenfv-4.2:Xen Fully-virtualized PC" \
			"03" "xenfv:Xen Fully-virtualized PC (alias of xenfv-3.1)" \
			"04" "xenfv-3.1:Xen Fully-virtualized PC" \
			"05" "pc:Standard PC (i440FX + PIIX, 1996) (alias of pc-i440fx-5.0)" \
			"06" "pc-i440fx-5.0:Standard PC (i440FX + PIIX, 1996) (default)" \
			"07" "pc-i440fx-4.2:Standard PC (i440FX + PIIX, 1996)" \
			"08" "pc-i440fx-4.1:Standard PC (i440FX + PIIX, 1996)" \
			"09" "pc-i440fx-4.0:Standard PC (i440FX + PIIX, 1996)" \
			"10" "pc-i440fx-3.1:Standard PC (i440FX + PIIX, 1996)" \
			"11" "pc-i440fx-3.0:Standard PC (i440FX + PIIX, 1996)" \
			"12" "pc-i440fx-2.9:Standard PC (i440FX + PIIX, 1996)" \
			"13" "pc-i440fx-2.8:Standard PC (i440FX + PIIX, 1996)" \
			"14" "pc-i440fx-2.7:Standard PC (i440FX + PIIX, 1996)" \
			"15" "pc-i440fx-2.6:Standard PC (i440FX + PIIX, 1996)" \
			"16" "pc-i440fx-2.5:Standard PC (i440FX + PIIX, 1996)" \
			"17" "pc-i440fx-2.4:Standard PC (i440FX + PIIX, 1996)" \
			"18" "pc-i440fx-2.3:Standard PC (i440FX + PIIX, 1996)" \
			"19" "pc-i440fx-2.2:Standard PC (i440FX + PIIX, 1996)" \
			"20" "pc-i440fx-2.12:Standard PC (i440FX + PIIX, 1996)" \
			"21" "pc-i440fx-2.11:Standard PC (i440FX + PIIX, 1996)" \
			"22" "pc-i440fx-2.10:Standard PC (i440FX + PIIX, 1996)" \
			"23" "pc-i440fx-2.1:Standard PC (i440FX + PIIX, 1996)" \
			"24" "pc-i440fx-2.0:Standard PC (i440FX + PIIX, 1996)" \
			"25" "pc-i440fx-1.7:Standard PC (i440FX + PIIX, 1996)" \
			"26" "pc-i440fx-1.6:Standard PC (i440FX + PIIX, 1996)" \
			"27" "pc-i440fx-1.5:Standard PC (i440FX + PIIX, 1996)" \
			"28" "pc-i440fx-1.4:Standard PC (i440FX + PIIX, 1996)" \
			"29" "pc-1.3:Standard PC (i440FX + PIIX, 1996) (deprecated)" \
			"30" "pc-1.2:Standard PC (i440FX + PIIX, 1996) (deprecated)" \
			"31" "pc-1.1:Standard PC (i440FX + PIIX, 1996) (deprecated)" \
			"32" "pc-1.0:Standard PC (i440FX + PIIX, 1996) (deprecated)" \
			"33" "q35:Standard PC (Q35 + ICH9, 2009) (alias of pc-q35-5.0)" \
			"34" "pc-q35-5.0:Standard PC (Q35 + ICH9, 2009)" \
			"35" "pc-q35-4.2:Standard PC (Q35 + ICH9, 2009)" \
			"36" "pc-q35-4.1:Standard PC (Q35 + ICH9, 2009)" \
			"37" "pc-q35-4.0.1:Standard PC (Q35 + ICH9, 2009)" \
			"38" "pc-q35-4.0:Standard PC (Q35 + ICH9, 2009)" \
			"39" "pc-q35-3.1:Standard PC (Q35 + ICH9, 2009)" \
			"40" "pc-q35-3.0:Standard PC (Q35 + ICH9, 2009)" \
			"41" "pc-q35-2.9:Standard PC (Q35 + ICH9, 2009)" \
			"42" "pc-q35-2.8:Standard PC (Q35 + ICH9, 2009)" \
			"43" "pc-q35-2.7:Standard PC (Q35 + ICH9, 2009)" \
			"44" "pc-q35-2.6:Standard PC (Q35 + ICH9, 2009)" \
			"45" "pc-q35-2.5:Standard PC (Q35 + ICH9, 2009)" \
			"46" "pc-q35-2.4:Standard PC (Q35 + ICH9, 2009)" \
			"47" "pc-q35-2.12:Standard PC (Q35 + ICH9, 2009)" \
			"48" "pc-q35-2.11:Standard PC (Q35 + ICH9, 2009)" \
			"49" "pc-q35-2.10:Standard PC (Q35 + ICH9, 2009)" \
			"50" "isapc:ISA-only PC" \
			"51" "none:empty machine" \
			"52" "xenpv:Xen Para-virtualized PC" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	00) disable_tmoe_qemu_machine ;;
	01) TMOE_AMD64_QEMU_MACHINE="microvm" ;;
	02) TMOE_AMD64_QEMU_MACHINE="xenfv-4.2" ;;
	03) TMOE_AMD64_QEMU_MACHINE="xenfv" ;;
	04) TMOE_AMD64_QEMU_MACHINE="xenfv-3.1" ;;
	05) TMOE_AMD64_QEMU_MACHINE="pc" ;;
	06) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-5.0" ;;
	07) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-4.2" ;;
	08) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-4.1" ;;
	09) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-4.0" ;;
	10) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-3.1" ;;
	11) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-3.0" ;;
	12) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.9" ;;
	13) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.8" ;;
	14) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.7" ;;
	15) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.6" ;;
	16) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.5" ;;
	17) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.4" ;;
	18) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.3" ;;
	19) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.2" ;;
	20) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.12" ;;
	21) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.11" ;;
	22) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.10" ;;
	23) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.1" ;;
	24) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.0" ;;
	25) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-1.7" ;;
	26) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-1.6" ;;
	27) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-1.5" ;;
	28) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-1.4" ;;
	29) TMOE_AMD64_QEMU_MACHINE="pc-1.3" ;;
	30) TMOE_AMD64_QEMU_MACHINE="pc-1.2" ;;
	31) TMOE_AMD64_QEMU_MACHINE="pc-1.1" ;;
	32) TMOE_AMD64_QEMU_MACHINE="pc-1.0" ;;
	33) TMOE_AMD64_QEMU_MACHINE="q35" ;;
	34) TMOE_AMD64_QEMU_MACHINE="pc-q35-5.0" ;;
	35) TMOE_AMD64_QEMU_MACHINE="pc-q35-4.2" ;;
	36) TMOE_AMD64_QEMU_MACHINE="pc-q35-4.1" ;;
	37) TMOE_AMD64_QEMU_MACHINE="pc-q35-4.0.1" ;;
	38) TMOE_AMD64_QEMU_MACHINE="pc-q35-4.0" ;;
	39) TMOE_AMD64_QEMU_MACHINE="pc-q35-3.1" ;;
	40) TMOE_AMD64_QEMU_MACHINE="pc-q35-3.0" ;;
	41) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.9" ;;
	42) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.8" ;;
	43) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.7" ;;
	44) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.6" ;;
	45) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.5" ;;
	46) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.4" ;;
	47) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.12" ;;
	48) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.11" ;;
	49) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.10" ;;
	50) TMOE_AMD64_QEMU_MACHINE="isapc" ;;
	51) TMOE_AMD64_QEMU_MACHINE="none" ;;
	52) TMOE_AMD64_QEMU_MACHINE="xenpv" ;;
	esac
	###############
	sed -i '/-M /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -M tmoe_cpu_config_test \\\n/' startqemu
	sed -i "s@-M tmoe_cpu_config_test@-M ${TMOE_AMD64_QEMU_MACHINE}@" startqemu
	echo "您已将cpu修改为${TMOE_AMD64_QEMU_MACHINE}"
	echo "修改完成，将在下次启动qemu虚拟机时生效"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##############
disable_tmoe_qemu_machine() {
	sed -i '/-M /d' startqemu
	echo "禁用完成"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
################
enable_tmoe_qemu_cpu_multi_threading() {
	cd /usr/local/bin/
	if grep -q '\,thread=multi' startqemu; then
		TMOE_SPICE_STATUS='检测到您已启用多线程加速功能'
	else
		TMOE_SPICE_STATUS='检测到您已禁用多线程加速功能'
	fi
	###########
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？${TMOE_SPICE_STATUS}" 11 45); then
		#CURRENT_VALUE=$(cat startqemu | grep '\-machine accel' | head -n 1 | awk '{print $2}' | cut -d ',' -f 1 | cut -d '=' -f 2)
		CURRENT_VALUE=$(cat startqemu | grep '\--accel ' | head -n 1 | awk '{print $2}' | cut -d ',' -f 1)
		sed -i "s@--accel .*@--accel ${CURRENT_VALUE},thread=multi \\\@" startqemu
		echo "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i 's@,thread=multi@@' startqemu
		echo "禁用完成"
	fi
}
#################
tmoe_qemu_x64_cpu_manager() {
	RETURN_TO_WHERE='tmoe_qemu_x64_cpu_manager'
	VIRTUAL_TECH=$(
		whiptail --title "CPU & RAM" --menu "Which configuration do you want to modify?" 15 50 6 \
			"1" "CPU cores处理器核心数" \
			"2" "cpu model/type(型号/类型)" \
			"3" "RAM运行内存" \
			"4" "multithreading多线程" \
			"5" "machine机器类型" \
			"6" "kvm/tcg/xen加速类型" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) modify_qemu_cpu_cores_number ;;
	2) modify_qemu_amd64_tmoe_cpu_type ;;
	3) modify_qemu_ram_size ;;
	4) enable_tmoe_qemu_cpu_multi_threading ;;
	5) modify_qemu_amd64_tmoe_machine_type ;;
	6) modify_qemu_machine_accel ;;
	esac
	###############
	#-soundhw cs4231a \
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
##############
tmoe_qemu_storage_devices() {
	cd /usr/local/bin/
	#RETURN_TO_WHERE='tmoe_qemu_storage_devices'
	VIRTUAL_TECH=$(
		whiptail --title "storage devices" --menu "Sorry,本功能正在开发中,当前仅支持配置virtio磁盘，其它选项请自行修改配置文件" 0 0 0 \
			"0" "Return to previous menu 返回上级菜单" \
			"00" "virtio-disk" \
			"01" "am53c974:bus PCI,desc(AMD Am53c974 PCscsi-PCI SCSI adapter)" \
			"02" "dc390:bus PCI,desc(Tekram DC-390 SCSI adapter)" \
			"03" "floppy:bus floppy-bus,desc(virtual floppy drive)" \
			"04" "ich9-ahci:bus PCI,alias(ahci)" \
			"05" "ide-cd:bus IDE,desc(virtual IDE CD-ROM)" \
			"06" "ide-drive:bus IDE,desc(virtual IDE disk or CD-ROM (legacy))" \
			"07" "ide-hd:bus IDE,desc(virtual IDE disk)" \
			"08" "isa-fdc:bus ISA" \
			"09" "isa-ide:bus ISA" \
			"10" "lsi53c810:bus PCI" \
			"11" "lsi53c895a:bus PCI,alias(lsi)" \
			"12" "megasas:bus PCI,desc(LSI MegaRAID SAS 1078)" \
			"13" "megasas-gen2:bus PCI,desc(LSI MegaRAID SAS 2108)" \
			"14" "mptsas1068:bus PCI,desc(LSI SAS 1068)" \
			"15" "nvme:bus PCI,desc(Non-Volatile Memory Express)" \
			"16" "piix3-ide:bus PCI" \
			"17" "piix3-ide-xen:bus PCI" \
			"18" "piix4-ide:bus PCI" \
			"19" "pvscsi:bus PCI" \
			"20" "scsi-block:bus SCSI,desc(SCSI block device passthrough)" \
			"21" "scsi-cd:bus SCSI,desc(virtual SCSI CD-ROM)" \
			"22" "scsi-disk:bus SCSI,desc(virtual SCSI disk or CD-ROM (legacy))" \
			"23" "scsi-generic:bus SCSI,desc(pass through generic scsi device (/dev/sg*))" \
			"24" "scsi-hd:bus SCSI,desc(virtual SCSI disk)" \
			"25" "sdhci-pci:bus PCI" \
			"26" "usb-bot:bus usb-bus" \
			"27" "usb-mtp:bus usb-bus,desc(USB Media Transfer Protocol device)" \
			"28" "usb-storage:bus usb-bus" \
			"29" "usb-uas:bus usb-bus" \
			"30" "vhost-scsi:bus virtio-bus" \
			"31" "vhost-scsi-pci:bus PCI" \
			"32" "vhost-user-blk:bus virtio-bus" \
			"33" "vhost-user-blk-pci:bus PCI" \
			"34" "vhost-user-scsi:bus virtio-bus" \
			"35" "vhost-user-scsi-pci:bus PCI" \
			"36" "virtio-9p-device:bus virtio-bus" \
			"37" "virtio-9p-pci:bus PCI,alias(virtio-9p)" \
			"38" "virtio-blk-device:bus virtio-bus" \
			"39" "virtio-blk-pci:bus PCI,alias(virtio-blk)" \
			"40" "virtio-scsi-device:bus virtio-bus" \
			"41" "virtio-scsi-pci:bus PCI,alias(virtio-scsi)" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_disk_manager ;;
	00) tmoe_qemu_virtio_disk ;;
	*) tmoe_qemu_error_tips ;;
	esac
	###############
	press_enter_to_return
	tmoe_qemu_disk_manager
}
###############
tmoe_qemu_virtio_disk() {
	RETURN_TO_WHERE='tmoe_qemu_virtio_disk'
	cd /usr/local/bin/
	if ! grep -q 'drive-virtio-disk' startqemu; then
		VIRTIO_STATUS="检测到您当前未启用virtio-disk"
	else
		VIRTIO_STATUS="检测到您当前已经启用virtio-disk"
	fi
	VIRTUAL_TECH=$(
		whiptail --title "VIRTIO-DISK" --menu "${VIRTIO_STATUS}" 15 50 6 \
			"1" "choose a disk选择virtio磁盘" \
			"2" "Download virtIO drivers下载驱动" \
			"3" "readme使用说明" \
			"4" "disable禁用hda(IDE)磁盘" \
			"5" "disable禁用virtio磁盘" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_storage_devices ;;
	1) choose_drive_virtio_disk_01 ;;
	2) download_virtio_drivers ;;
	3) echo '请先以常规挂载方式(IDE磁盘)运行虚拟机系统，接着在虚拟机内安装virtio驱动，然后退出虚拟机，最后禁用IDE磁盘，并选择virtio磁盘' ;;
	4)
		sed -i '/-hda /d' startqemu
		echo '禁用完成'
		;;
	5)
		sed -i '/drive-virtio-disk/d' startqemu
		echo '禁用完成'
		;;
	esac
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##########
set_it_as_the_default_qemu_iso() {
	echo "文件已解压至${DOWNLOAD_PATH}"
	echo "是否将其设置为默认的qemu光盘？"
	do_you_want_to_continue
	cd /usr/local/bin
	sed -i '/--cdrom /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    --cdrom tmoe_hda_config_test \\\n/' startqemu
	sed -i "s@--cdrom tmoe_hda_config_test@--cdrom ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	#echo "设置完成，您之后可以输startqemu启动"
	#echo "若启动失败，则请检查qemu的相关设置选项"
}
#############
check_tmoe_qemu_iso_file_and_git() {
	cd ${DOWNLOAD_PATH}
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it  o(*￣▽￣*)o, or download it again?(っ °Д °)" 0 0); then
			echo "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			git_clone_tmoe_linux_qemu_qcow2_file
		fi
	else
		git_clone_tmoe_linux_qemu_qcow2_file
	fi
}
###############
download_virtio_drivers() {
	DOWNLOAD_PATH="${HOME}/sd/Download"
	mkdir -p ${DOWNLOAD_PATH}
	VIRTUAL_TECH=$(
		whiptail --title "VIRTIO" --menu "${VIRTIO_STATUS}" 15 50 4 \
			"1" "virtio-win" \
			"2" "virtio-win-latest(fedora)" \
			"3" "readme驱动说明" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_virtio_disk ;;
	1)
		#THE_LATEST_ISO_LINK='https://m.tmoe.me/down/share/windows/drivers/virtio-win-0.1.173.iso'
		#aria2c_download_file
		echo "即将为您下载至${DOWNLOAD_PATH}"
		BRANCH_NAME='win'
		TMOE_LINUX_QEMU_REPO='https://gitee.com/ak2/virtio'
		DOWNLOAD_FILE_NAME='virtio-win.tar.gz'
		QEMU_QCOW2_FILE_PREFIX='.virtio_'
		QEMU_DISK_FILE_NAME='virtio-win.iso'
		TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
		check_tmoe_qemu_iso_file_and_git
		uncompress_tar_gz_file
		set_it_as_the_default_qemu_iso
		;;
	2)
		#https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso
		THE_LATEST_ISO_LINK='https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso'
		aria2c_download_file
		;;
	3)
		echo 'url: https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/index.html'
		x-www-browser 'https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/index.html' 2>/dev/null
		;;
	4)
		sed -i '/-hda /d' startqemu
		echo '禁用完成'
		;;
	5)
		sed -i '/drive-virtio-disk/d' startqemu
		echo '禁用完成'
		;;
	esac
	press_enter_to_return
	download_virtio_drivers
}
#######################
choose_drive_virtio_disk_01() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='img'
	if grep -q 'drive-virtio-disk' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep 'id=drive-virtio-disk' | head -n 1 | awk '{print $2}' | cut -d ',' -f 1 | cut -d '=' -f 2)
		IMPORTANT_TIPS="您当前已加载的virtio磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到您当前没有加载virtio磁盘"
	fi
	where_is_start_dir
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		#-hda /root/.aqemu/alpine_v3.11_x64.qcow2 \
		sed -i '/=drive-virtio-disk/d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -virtio_disk tmoe_virtio_disk_config_test \\\n/' startqemu
		sed -i "s@-virtio_disk tmoe_virtio_disk_config_test@-drive file=${TMOE_FILE_ABSOLUTE_PATH},format=qcow2,if=virtio,id=drive-virtio-disk0@" startqemu
	fi
}
###############
#########################
tmoe_qemu_error_tips() {
	echo "Sorry，本功能正在开发中，暂不支持修改storage devices，如需启用相关参数，请手动修改配置文件"
}
#####################
start_tmoe_qemu_manager() {
	RETURN_TO_WHERE='start_tmoe_qemu_manager'
	RETURN_TO_MENU='start_tmoe_qemu_manager'
	check_qemu_install
	if [ ! -e "${HOME}/.config/tmoe-linux/startqemu_amd64_2020060314" ]; then
		echo "启用x86_64虚拟机将重置startqemu为x86_64的配置"
		rm -fv ${HOME}/.config/tmoe-linux/startqemu*
		creat_qemu_startup_script
	fi
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "x86_64 qemu虚拟机管理器" --menu "同架构/跨架构模拟运行系统" 17 55 8 \
			"1" "🍹Creat a new VM 新建虚拟机" \
			"2" "🏭qemu templates repo磁盘与模板在线仓库" \
			"3" "🍱Multi-VM多虚拟机管理" \
			"4" "🥗edit script manually手动修改配置脚本" \
			"5" "🍤FAQ常见问题" \
			"6" "🎵Display and audio显示与音频" \
			"7" "💾disk manager磁盘管理器" \
			"8" "🍭CPU & RAM 中央处理器与内存管理" \
			"9" "🥅network网络设定" \
			"10" "🖱Input devices输入设备" \
			"11" "🔌uefi/legacy bios(开机引导固件)" \
			"12" "😋extra options额外选项" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############🧺
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) creat_a_new_tmoe_qemu_vm ;;
	2) tmoe_qemu_templates_repo ;;
	3) multi_qemu_vm_management ;;
	4) nano startqemu ;;
	5) tmoe_qemu_faq ;;
	6) tmoe_qemu_display_settings ;;
	7) tmoe_qemu_disk_manager ;;
	8) tmoe_qemu_x64_cpu_manager ;;
	9) modify_tmoe_qemu_network_settings ;;
	10) tmoe_qemu_input_devices ;;
	11) choose_qemu_bios_or_uefi_file ;;
	12) modify_tmoe_qemu_extra_options ;;
	esac
	###############
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##############
creat_a_new_tmoe_qemu_vm() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='choose_qemu_qcow2_or_img_file'
	if (whiptail --title "是否需要创建虚拟磁盘" --yes-button 'creat新建' --no-button 'choose选择' --yesno "Do you want to creat a new disk?若您无虚拟磁盘，那就新建一个吧" 8 50); then
		creat_blank_virtual_disk_image
	else
		choose_qemu_qcow2_or_img_file
	fi
	SELECTION=""
	TMOE_QEMU_SCRIPT_FILE_PATH='/usr/local/bin/.tmoe-linux-qemu'
	THE_QEMU_STARTUP_SCRIPT='/usr/local/bin/startqemu'
	RETURN_TO_WHERE='save_current_qemu_conf_as_a_new_script'
	if (whiptail --title "是否需要选择启动光盘" --yes-button 'yes' --no-button 'skip跳过' --yesno "Do you want to choose a iso?启动光盘用于安装系统,若您无此文件,则请先下载iso;若磁盘内已安装了系统,则可跳过此选项。" 10 50); then
		choose_qemu_iso_file
	fi
	RETURN_TO_WHERE='multi_qemu_vm_management'
	save_current_qemu_conf_as_a_new_script
	echo "处于默认配置下的虚拟机的启动命令是startqemu"
	echo "是否需要启动虚拟机？"
	echo "您之后可以输startqemu来启动"
	echo "You can type startqemu to start the default qemu vm."
	echo "默认VNC访问地址为localhost:5902"
	echo "Do you want to start it now?"
	do_you_want_to_continue
	startqemu
}
##########################
modify_tmoe_qemu_extra_options() {
	RETURN_TO_WHERE='modify_tmoe_qemu_extra_options'
	VIRTUAL_TECH=$(
		whiptail --title "EXTRA OPTIONS" --menu "Which configuration do you want to modify？" 0 0 0 \
			"1" "windows2000 hack" \
			"2" "tmoe_qemu_not-todo-list" \
			"3" "restore to default恢复到默认" \
			"4" "switch architecture切换架构" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) enable_qemnu_win2k_hack ;;
	2) tmoe_qemu_todo_list ;;
	3)
		creat_qemu_startup_script
		echo "restore completed"
		;;
	4) switch_tmoe_qemu_architecture ;;
	esac
	###############
	press_enter_to_return
	modify_tmoe_qemu_extra_options
}
#################
switch_tmoe_qemu_architecture() {
	cd /usr/local/bin
	if grep -q '/usr/bin/qemu-system-x86_64' startqemu; then
		QEMU_ARCH_STATUS='检测到您当前启用的是x86_64架构'
		SED_QEMU_BIN_COMMAND='/usr/bin/qemu-system-x86_64'
	elif grep -q '/usr/bin/qemu-system-i386' startqemu; then
		QEMU_ARCH_STATUS='检测到您当前启用的是i386架构'
		SED_QEMU_BIN_COMMAND='/usr/bin/qemu-system-i386'
	fi
	QEMU_ARCH=$(
		whiptail --title "architecture" --menu "Which architecture do you want to switch？\n您想要切换为哪个架构?${QEMU_ARCH_STATUS}" 16 55 6 \
			"1" "x86_64" \
			"2" "i386" \
			"3" "mips" \
			"4" "sparc" \
			"5" "ppc" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${QEMU_ARCH} in
	0 | "") modify_tmoe_qemu_extra_options ;;
	1)
		SED_QEMU_BIN_COMMAND_SELECTED='/usr/bin/qemu-system-x86_64'
		sed -i "s@${SED_QEMU_BIN_COMMAND}@${SED_QEMU_BIN_COMMAND_SELECTED}@" startqemu
		echo "您已切换至${SED_QEMU_BIN_COMMAND_SELECTED}"
		;;
	2)
		SED_QEMU_BIN_COMMAND_SELECTED='/usr/bin/qemu-system-i386'
		sed -i "s@${SED_QEMU_BIN_COMMAND}@${SED_QEMU_BIN_COMMAND_SELECTED}@" startqemu
		echo "您已切换至${SED_QEMU_BIN_COMMAND_SELECTED}"
		;;
	*) echo "非常抱歉，本工具暂未适配此架构，请手动修改qemu启动脚本" ;;
	esac
	###############
	press_enter_to_return
	switch_tmoe_qemu_architecture
}
#####################
modify_tmoe_qemu_network_settings() {
	RETURN_TO_WHERE='modify_tmoe_qemu_network_settings'
	VIRTUAL_TECH=$(
		whiptail --title "network devices" --menu "Which configuration do you want to modify？" 0 0 0 \
			"1" "network card网卡" \
			"2" "exposed ports端口映射/转发" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) modify_qemu_tmoe_network_card ;;
	2) modify_qemu_exposed_ports ;;
	esac
	###############
	press_enter_to_return
	modify_tmoe_qemu_network_settings
}
##############
tmoe_qemu_disk_manager() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='tmoe_qemu_disk_manager'
	VIRTUAL_TECH=$(
		whiptail --title "DISK MANAGER" --menu "Which configuration do you want to modify?" 15 50 7 \
			"1" "💽choose iso选择启动光盘(CD)" \
			"2" "choose disk选择启动磁盘(IDE)" \
			"3" "compress压缩磁盘文件(真实大小)" \
			"4" "expand disk扩容磁盘(最大空间)" \
			"5" "mount shared folder挂载共享文件夹" \
			"6" "Storage devices存储设备" \
			"7" "creat disk创建(空白)虚拟磁盘" \
			"8" "second disk选择第二块IDE磁盘" \
			"9" "third disk选择第三块IDE磁盘" \
			"10" "fourth disk选择第四块IDE磁盘" \
			"11" "disable cdrom禁用光盘" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) choose_qemu_iso_file ;;
	2) choose_qemu_qcow2_or_img_file ;;
	3) compress_or_dd_qcow2_img_file ;;
	4) expand_qemu_qcow2_img_file ;;
	5) modify_qemu_shared_folder ;;
	6) tmoe_qemu_storage_devices ;;
	7) creat_blank_virtual_disk_image ;;
	8) choose_hdb_disk_image_file ;;
	9) choose_hdc_disk_image_file ;;
	10) choose_hdd_disk_image_file ;;
	11)
		sed -i '/--cdrom /d' startqemu
		echo "禁用完成"
		;;
	esac
	press_enter_to_return
	tmoe_qemu_disk_manager
}
################
tmoe_qemu_display_settings() {
	RETURN_TO_WHERE='tmoe_qemu_display_settings'
	RETURN_TO_TMOE_MENU_01='tmoe_qemu_display_settings'
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "DISPLAY" --menu "Which configuration do you want to modify?" 15 50 7 \
			"1" "Graphics card/VGA(显卡/显示器)" \
			"2" "sound card声卡" \
			"3" "Display devices显示设备" \
			"4" "VNC port端口" \
			"5" "VNC pulseaudio音频" \
			"6" "X服务(XSDL/VcXsrv)" \
			"7" "spice远程桌面" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) modify_qemnu_graphics_card ;;
	2) modify_qemu_sound_card ;;
	3) modify_tmoe_qemu_display_device ;;
	4) modify_qemu_vnc_display_port ;;
	5) modify_tmoe_qemu_vnc_pulse_audio_address ;;
	6) modify_tmoe_qemu_xsdl_settings ;;
	7) enable_qemnu_spice_remote ;;
	esac
	press_enter_to_return
	tmoe_qemu_display_settings
}
################
modify_tmoe_qemu_vnc_pulse_audio_address() {
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。本机默认为127.0.0.1,当前为$(cat startqemu | grep 'PULSE_SERVER' | cut -d '=' -f 2 | head -n 1)\n本功能适用于局域网传输，本机操作无需任何修改。若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：若您使用的不是WSL或tmoe-linux安装的容器，则您需要手动启动音频服务,Android-Termux需输pulseaudio --start,win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat' \n若qemu无法调用音频,则请检查qemu启动脚本的声卡参数和虚拟机内的声卡驱动。" 20 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		if grep -q '^export.*PULSE_SERVER' "startqemu"; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startqemu
		else
			sed -i "2 a\export PULSE_SERVER=$TARGET" startqemu
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo "您当前的音频地址已修改为$(grep 'PULSE_SERVER' startqemu | cut -d '=' -f 2 | head -n 1)"
		echo "重启qemu生效"
	fi
}
##################
modify_tmoe_qemu_xsdl_settings() {
	if grep -q '\-vnc \:' "startqemu"; then
		X_SERVER_STATUS="检测到您当前启用的是VNC,而非X服务"
	elif grep -q '\-spice port' "startqemu"; then
		X_SERVER_STATUS="检测到您当前启用的是spice,而非X服务"
	elif grep -q '^export.*DISPLAY' "startqemu"; then
		X_SERVER_STATUS="检测到您已经启用了转发X的功能"
	else
		X_SERVER_STATUS="检测到您已经启用了本地X,但未启用转发"
	fi

	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'configure配置' --yesno "Do you want to enable it?(っ °Д °)\n启用xserver后将禁用vnc和spice,您是想要启用还是配置呢?${X_SERVER_STATUS}" 9 50); then
		sed -i '/vnc :/d' startqemu
		sed -i '/-spice port=/d' startqemu
		if ! grep -q '^export.*DISPLAY' "startqemu"; then
			sed -i "1 a\export DISPLAY=127.0.0.1:0" startqemu
		fi
		sed -i 's@export PULSE_SERVER.*@export PULSE_SERVER=127.0.0.1:4713@' startqemu
		echo "启用完成，重启qemu生效"
		press_enter_to_return
		modify_tmoe_qemu_xsdl_settings
	else
		modify_xsdl_conf
	fi
}
##############
modify_tmoe_qemu_display_device() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='modify_tmoe_qemu_display_device'
	VIRTUAL_TECH=$(
		whiptail --title "display devices" --menu "您想要修改为哪个显示设备呢？此功能目前仍处于测试阶段，切换前需手动禁用之前的显示设备。" 0 0 0 \
			"0" "Return to previous menu 返回上级菜单" \
			"00" "list all enabled列出所有已经启用的设备" \
			"01" "ati-vga:bus PCI" \
			"02" "bochs-display:bus PCI" \
			"03" "cirrus-vga:bus PCI,desc(Cirrus CLGD 54xx VGA" \
			"04" "isa-cirrus-vga:bus ISA" \
			"05" "isa-vga:bus ISA" \
			"06" "qxl:bus PCI,desc(Spice QXL GPU (secondary)" \
			"07" "qxl-vga:bus PCI,desc(Spice QXL GPU (primary, vga compatible)" \
			"08" "ramfb:bus System,desc(ram framebuffer standalone device" \
			"09" "secondary-vga:bus PCI" \
			"10" "sga:bus ISA,desc(Serial Graphics Adapter" \
			"11" "VGA:bus PCI" \
			"12" "vhost-user-gpu:bus virtio-bus" \
			"13" "vhost-user-gpu-pci:bus PCI" \
			"14" "vhost-user-vga:bus PCI" \
			"15" "virtio-gpu-device:bus virtio-bus" \
			"16" "virtio-gpu-pci:bus PCI,alias(virtio-gpu" \
			"17" "virtio-vga:bus PCI" \
			"18" "vmware-svga:bus PCI" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_display_settings ;;
	00) list_all_enabled_qemu_display_devices ;;
	01) TMOE_QEMU_DISPLAY_DEVICES="ati-vga" ;;
	02) TMOE_QEMU_DISPLAY_DEVICES="bochs-display" ;;
	03) TMOE_QEMU_DISPLAY_DEVICES="cirrus-vga" ;;
	04) TMOE_QEMU_DISPLAY_DEVICES="isa-cirrus-vga" ;;
	05) TMOE_QEMU_DISPLAY_DEVICES="isa-vga" ;;
	06) TMOE_QEMU_DISPLAY_DEVICES="qxl" ;;
	07) TMOE_QEMU_DISPLAY_DEVICES="qxl-vga" ;;
	08) TMOE_QEMU_DISPLAY_DEVICES="ramfb" ;;
	09) TMOE_QEMU_DISPLAY_DEVICES="secondary-vga" ;;
	10) TMOE_QEMU_DISPLAY_DEVICES="sga" ;;
	11) TMOE_QEMU_DISPLAY_DEVICES="VGA" ;;
	12) TMOE_QEMU_DISPLAY_DEVICES="vhost-user-gpu" ;;
	13) TMOE_QEMU_DISPLAY_DEVICES="vhost-user-gpu-pci" ;;
	14) TMOE_QEMU_DISPLAY_DEVICES="vhost-user-vga" ;;
	15) TMOE_QEMU_DISPLAY_DEVICES="virtio-gpu-device" ;;
	16) TMOE_QEMU_DISPLAY_DEVICES="virtio-gpu-pci" ;;
	17) TMOE_QEMU_DISPLAY_DEVICES="virtio-vga" ;;
	18) TMOE_QEMU_DISPLAY_DEVICES="vmware-svga" ;;
	esac
	###############
	enable_qemnu_display_device
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##############
list_all_enabled_qemu_display_devices() {
	if ! grep -q '\-device' startqemu; then
		echo "未启用任何相关设备"
	else
		cat startqemu | grep '\-device' | awk '{print $2}'
	fi
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
enable_qemnu_display_device() {
	cd /usr/local/bin/
	if grep -q "device ${TMOE_QEMU_DISPLAY_DEVICES}" startqemu; then
		TMOE_SPICE_STATUS="检测到您已启用${TMOE_QEMU_DISPLAY_DEVICES}"
	else
		TMOE_SPICE_STATUS="检测到您已禁用${TMOE_QEMU_DISPLAY_DEVICES}"
	fi
	###########
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？${TMOE_SPICE_STATUS}" 11 45); then
		sed -i "/-device ${TMOE_QEMU_DISPLAY_DEVICES}/d" startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -device tmoe_config_test \\\n/' startqemu
		sed -i "s@-device tmoe_config_test@-device ${TMOE_QEMU_DISPLAY_DEVICES}@" startqemu
		echo "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i "/-device ${TMOE_QEMU_DISPLAY_DEVICES}/d" startqemu
		echo "禁用完成"
	fi
}
#####################
tmoe_qemu_templates_repo() {
	RETURN_TO_WHERE='tmoe_qemu_templates_repo'
	DOWNLOAD_PATH="${HOME}/sd/Download/backup"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	CURRENT_TMOE_QEMU_BIN='/usr/bin/qemu-system-aarch64'
	LATER_TMOE_QEMU_BIN='/usr/bin/qemu-system-x86_64'
	VIRTUAL_TECH=$(
		whiptail --title "QEMU TEMPLATES" --menu "Welcome to 施工现场(ﾟДﾟ*)ﾉ\nUEFI与legacy bios为开机引导类型" 0 50 0 \
			"1" "alpine_x64(含docker,217M,legacy)" \
			"2" "Debian buster_arm64/x64(300M,UEFI)" \
			"3" "Arch_x64(678M,legacy)" \
			"4" "FreeBSD_x64(500M,legacy)" \
			"5" "Winserver2008R2数据中心版_x64(2.2G,legacy)" \
			"6" "Ubuntu kylin优麒麟20.04_x64(1.8G,uefi)" \
			"7" "LMDE4_x64(linux mint,2.7G,legacy)" \
			"8" "Explore templates探索共享模板(未开放)" \
			"9" "share 分享你的qemu配置(未开放)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#Explore configuration templates
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) download_alpine_and_docker_x64_img_file ;;
	2) download_debian_qcow2_file ;;
	3) download_arch_linux_qcow2_file ;;
	4) download_freebsd_qcow2_file ;;
	5) download_windows_server_2008_data_center_qcow2_file ;;
	6) download_ubuntu_kylin_20_04_qcow2_file ;;
	7) download_lmde_4_qcow2_file ;;
	8) explore_qemu_configuration_templates ;;
	9) share_qemu_conf_to_git_branch_qemu ;;
	esac
	press_enter_to_return
	tmoe_qemu_templates_repo
}
##########
download_freebsd_qcow2_file() {
	DOWNLOAD_PATH="${HOME}/sd/Download/backup/freebsd"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	ISO_REPO='https://mirrors.huaweicloud.com/freebsd/releases/VM-IMAGES/'
	THE_LATEST_SYSTEM_VERSION=$(curl -L ${ISO_REPO} | grep -v 'README' | grep href | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	#https://mirrors.huaweicloud.com/freebsd/releases/VM-IMAGES/12.1-RELEASE/amd64/Latest/
	THE_LATEST_ISO_REPO="${ISO_REPO}${THE_LATEST_SYSTEM_VERSION}amd64/Latest/"
	THE_LATEST_FILE_VERSION=$(curl -L ${THE_LATEST_ISO_REPO} | grep -Ev 'vmdk|vhd|raw.xz|CHECKSUM' | grep qcow2 | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	DOWNLOAD_FILE_NAME="${THE_LATEST_FILE_VERSION}"
	THE_LATEST_ISO_LINK="${THE_LATEST_ISO_REPO}${THE_LATEST_FILE_VERSION}"
	# stat ${THE_LATEST_FILE_VERSION}
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to uncompress it, or download it again?" 0 0); then
			echo "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			aria2c_download_file
		fi
	else
		aria2c_download_file
	fi
	uncompress_qcow2_xz_file
	QEMU_DISK_FILE_NAME=$(ls -At | grep -v '.xz' | awk -F ' ' '$0=$NF' | head -n 1)
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	set_it_as_default_qemu_disk
}
########################
uncompress_qcow2_xz_file() {
	echo '正在解压中...'
	#unxz
	xz -dv ${DOWNLOAD_FILE_NAME}
}
####################
share_qemu_conf_to_git_branch_qemu() {
	echo "Welcome to 施工现场，这个功能还在开发中呢！咕咕咕，建议您明年再来o((>ω< ))o"
}
################
explore_qemu_configuration_templates() {
	RETURN_TO_WHERE='explore_qemu_configuration_templates'
	VIRTUAL_TECH=$(
		whiptail --title "奇怪的虚拟机又增加了" --menu "Welcome to 施工现场，这个功能还在开发中呢！\n咕咕咕，建议您明年再来o((>ω< ))o\n以下配置模板来自于他人的共享,与本工具开发者无关.\n希望大家多多支持原发布者ヽ(゜▽゜　)" 0 0 0 \
			"0" "Return to previous menu 返回上级菜单" \
			"001" "win7精简不卡,三分钟开机(bili@..)" \
			"002" "可能是全网最流畅的win10镜像(qq@..)" \
			"003" "kubuntu20.04 x64豪华配置，略卡(coolapk@..)" \
			"004" "lubuntu18.04内置wine,可玩游戏(github@..)" \
			"005" "win98 骁龙6系超级流畅(bili@..)" \
			"006" "winxp有网有声(tieba@..)" \
			"007" "vista装了许多好玩的东西,骁龙865流畅(tieba@..)" \
			"008" "macos ppc上古版本(coolapk@..)" \
			"009" "xubuntu个人轻度精简,内置qq和百度云(github@..)" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_templates_repo ;;
	001) win7_qemu_template_2020_06_02_17_38 ;;
	008) echo "非常抱歉，本工具暂未适配ppc架构" ;;
	*) echo "这个模板加载失败了呢！" ;;
	esac
	###############
	echo "暂未开放此功能！咕咕咕，建议您明年再来o((>ω< ))o"
	press_enter_to_return
	tmoe_qemu_templates_repo
}
##############
win7_qemu_template_2020_06_02_17_38() {
	whiptail --title "发布者的留言" \
		--msgbox "
      个人主页：https://space.bilibili.com/
      资源链接：https://pan.baidu.com/disk/home#/all?vmode=list&path=%2F%E6%88%91%E7%9A%84%E8%B5%84%E6%BA%90
      大家好，我是来自B站的..
      不知道今天是哪个幸运儿用到了我发布的镜像和配置脚本呢？萌新up主求三连😀
      " 0 0
	echo "是否将其设置为默认的qemu配置？"
	do_you_want_to_continue
	#if [ $? = 0]; then
	#fi
	echo "这个模板加载失败了呢！光有脚本还不够，您还需要下载镜像资源文件至指定目录呢！"
}
##################
tmoe_qemu_input_devices() {
	#qemu-system-x86_64 -device help
	cd /usr/local/bin/
	RETURN_TO_WHERE='tmoe_qemu_input_devices'
	VIRTUAL_TECH=$(
		whiptail --title "input devices" --menu "请选择您需要启用的输入设备,您可以同时启用多个设备" 0 0 0 \
			"0" "Return to previous menu 返回上级菜单" \
			"00" "list all enabled列出所有已经启用的设备" \
			"01" "ccid-card-emulated: bus ccid-bus, desc(emulated smartcard)" \
			"02" "ccid-card-passthru: bus ccid-bus, desc(passthrough smartcard)" \
			"03" "ipoctal232: bus IndustryPack, desc(GE IP-Octal 232 8-channel RS-232 IndustryPack)" \
			"04" "isa-parallel: bus ISA" \
			"05" "isa-serial: bus ISA" \
			"06" "pci-serial: bus PCI" \
			"07" "pci-serial-2x: bus PCI" \
			"08" "pci-serial-4x: bus PCI" \
			"09" "tpci200: bus PCI, desc(TEWS TPCI200 IndustryPack carrier)" \
			"10" "usb-braille: bus usb-bus" \
			"11" "usb-ccid: bus usb-bus, desc(CCID Rev 1.1 smartcard reader)" \
			"12" "usb-kbd: bus usb-bus" \
			"13" "usb-mouse: bus usb-bus" \
			"14" "usb-serial: bus usb-bus" \
			"15" "usb-tablet: bus usb-bus" \
			"16" "usb-wacom-tablet: bus usb-bus, desc(QEMU PenPartner Tablet)" \
			"17" "virtconsole: bus virtio-serial-bus" \
			"18" "virtio-input-host-device: bus virtio-bus" \
			"19" "virtio-input-host-pci: bus PCI, alias(virtio-input-host)" \
			"20" "virtio-keyboard-device: bus virtio-bus" \
			"21" "virtio-keyboard-pci: bus PCI, alias(virtio-keyboard)" \
			"22" "virtio-mouse-device: bus virtio-bus" \
			"23" "virtio-mouse-pci: bus PCI, alias(virtio-mouse)" \
			"24" "virtio-serial-device: bus virtio-bus" \
			"25" "virtio-serial-pci: bus PCI, alias(virtio-serial)" \
			"26" "virtio-tablet-device: bus virtio-bus" \
			"27" "virtio-tablet-pci: bus PCI, alias(virtio-tablet)" \
			"28" "virtserialport: bus virtio-serial-bus" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	00) list_all_enabled_qemu_input_devices ;;
	01) TMOE_QEMU_INPUT_DEVICE='ccid-card-emulated' ;;
	02) TMOE_QEMU_INPUT_DEVICE='ccid-card-passthru' ;;
	03) TMOE_QEMU_INPUT_DEVICE='ipoctal232' ;;
	04) TMOE_QEMU_INPUT_DEVICE='isa-parallel' ;;
	05) TMOE_QEMU_INPUT_DEVICE='isa-serial' ;;
	06) TMOE_QEMU_INPUT_DEVICE='pci-serial' ;;
	07) TMOE_QEMU_INPUT_DEVICE='pci-serial-2x' ;;
	08) TMOE_QEMU_INPUT_DEVICE='pci-serial-4x' ;;
	09) TMOE_QEMU_INPUT_DEVICE='tpci200' ;;
	10) TMOE_QEMU_INPUT_DEVICE='usb-braille' ;;
	11) TMOE_QEMU_INPUT_DEVICE='usb-ccid' ;;
	12) TMOE_QEMU_INPUT_DEVICE='usb-kbd' ;;
	13) TMOE_QEMU_INPUT_DEVICE='usb-mouse' ;;
	14) TMOE_QEMU_INPUT_DEVICE='usb-serial' ;;
	15) TMOE_QEMU_INPUT_DEVICE='usb-tablet' ;;
	16) TMOE_QEMU_INPUT_DEVICE='usb-wacom-tablet' ;;
	17) TMOE_QEMU_INPUT_DEVICE='virtconsole' ;;
	18) TMOE_QEMU_INPUT_DEVICE='virtio-input-host-device' ;;
	19) TMOE_QEMU_INPUT_DEVICE='virtio-input-host-pci' ;;
	20) TMOE_QEMU_INPUT_DEVICE='virtio-keyboard-device' ;;
	21) TMOE_QEMU_INPUT_DEVICE='virtio-keyboard-pci' ;;
	22) TMOE_QEMU_INPUT_DEVICE='virtio-mouse-device' ;;
	23) TMOE_QEMU_INPUT_DEVICE='virtio-mouse-pci' ;;
	24) TMOE_QEMU_INPUT_DEVICE='virtio-serial-device' ;;
	25) TMOE_QEMU_INPUT_DEVICE='virtio-serial-pci' ;;
	26) TMOE_QEMU_INPUT_DEVICE='virtio-tablet-device' ;;
	27) TMOE_QEMU_INPUT_DEVICE='virtio-tablet-pci' ;;
	28) TMOE_QEMU_INPUT_DEVICE='virtserialport' ;;
	esac
	###############
	enable_qemnu_input_device
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##########
list_all_enabled_qemu_input_devices() {
	if ! grep -q '\-device' startqemu; then
		echo "未启用任何相关设备"
	else
		cat startqemu | grep '\-device' | awk '{print $2}'
	fi
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
enable_qemnu_input_device() {
	cd /usr/local/bin/
	if grep -q "device ${TMOE_QEMU_INPUT_DEVICE}" startqemu; then
		TMOE_SPICE_STATUS="检测到您已启用${TMOE_QEMU_INPUT_DEVICE}"
	else
		TMOE_SPICE_STATUS="检测到您已禁用${TMOE_QEMU_INPUT_DEVICE}"
	fi
	###########
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？${TMOE_SPICE_STATUS}" 11 45); then
		sed -i "/-device ${TMOE_QEMU_INPUT_DEVICE}/d" startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -device tmoe_config_test \\\n/' startqemu
		sed -i "s@-device tmoe_config_test@-device ${TMOE_QEMU_INPUT_DEVICE}@" startqemu
		echo "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i "/-device ${TMOE_QEMU_INPUT_DEVICE}/d" startqemu
		echo "禁用完成"
	fi
}
##########################
tmoe_choose_a_qemu_bios_file() {
	FILE_EXT_01='fd'
	FILE_EXT_02='bin'
	IMPORTANT_TIPS="您当前已加载的bios为${CURRENT_VALUE}"
	CURRENT_QEMU_ISO="${CURRENT_VALUE}"
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
		press_enter_to_return
		${RETURN_TO_WHERE}
	else
		echo "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd ${FILE_PATH}
		file ${SELECTION}
	fi
	TMOE_QEMU_BIOS_FILE_PATH="${TMOE_FILE_ABSOLUTE_PATH}"
	do_you_want_to_continue
}
###########
choose_qemu_bios_or_uefi_file() {
	if [ ! -e "/usr/share/qemu-efi-aarch64/QEMU_EFI.fd" ]; then
		DEPENDENCY_01=''
		DEPENDENCY_02='qemu-efi-aarch64'
		beta_features_quick_install
	fi
	if [ ! -e "/usr/share/ovmf/OVMF.fd" ]; then
		DEPENDENCY_01=''
		DEPENDENCY_02='ovmf'
		beta_features_quick_install
	fi
	cd /usr/local/bin/
	RETURN_TO_WHERE='choose_qemu_bios_or_uefi_file'
	if grep -q '\-bios ' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-bios ' | tail -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	else
		CURRENT_VALUE='默认'
	fi
	VIRTUAL_TECH=$(
		whiptail --title "uefi/legacy bios" --menu "Please select the legacy bios or uefi file.若您使用的是legacy-bios，则可以在启动VNC后的3秒钟内按下ESC键选择启动项。若您使用的是uefi,则您可以在启动VNC后的几秒内按其他键允许从光盘启动。\n当前为${CURRENT_VALUE}" 18 50 5 \
			"1" "default默认" \
			"2" "qemu-efi-aarch64:UEFI firmware for arm64" \
			"3" "ovmf:UEFI firmware for x64" \
			"4" "choose a file自选文件" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) restore_to_default_qemu_bios ;;
	2)
		if [ "${RETURN_TO_MENU}" = "start_tmoe_qemu_manager" ]; then
			echo "检测到您选用的是x64虚拟机，不支持qemu-efi-aarch64，将为您自动切换至OVMF EFI"
			TMOE_QEMU_BIOS_FILE_PATH='/usr/share/ovmf/OVMF.fd'
		else
			TMOE_QEMU_BIOS_FILE_PATH='/usr/share/qemu-efi-aarch64/QEMU_EFI.fd'
		fi
		;;
	3)
		if ! grep -Eq 'std|qxl' /usr/local/bin/startqemu; then
			echo "请将显卡修改为qxl或std"
		fi
		TMOE_QEMU_BIOS_FILE_PATH='/usr/share/ovmf/OVMF.fd'
		;;
	4) tmoe_choose_a_qemu_bios_file ;;
	esac
	###############
	sed -i '/-bios /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -bios tmoe_bios_config_test \\\n/' startqemu
	sed -i "s@-bios tmoe_bios_config_test@-bios ${TMOE_QEMU_BIOS_FILE_PATH}@" startqemu
	echo "您已将启动引导固件修改为${TMOE_QEMU_BIOS_FILE_PATH}"
	echo "修改完成，将在下次启动qemu虚拟机时生效"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##########
restore_to_default_qemu_bios() {
	if [ "${RETURN_TO_MENU}" = "start_tmoe_qemu_manager" ]; then
		sed -i '/-bios /d' startqemu
	else
		#-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
		sed -i 's@-bios .*@-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \\@' startqemu
	fi
	press_enter_to_return
	${RETURN_TO_WHERE}
}
################
delete_current_qemu_vm_disk_file() {
	QEMU_FILE="$(cat ${THE_QEMU_STARTUP_SCRIPT} | grep '\-hda ' | head -n 1 | awk '{print $2}' | cut -d ':' -f 2)"
	stat ${QEMU_FILE}
	qemu-img info ${QEMU_FILE}
	echo "Do you want to delete it?"
	echo "删除后将无法撤销，请谨慎操作"
	do_you_want_to_continue
	rm -fv ${QEMU_FILE}
}
################
delete_current_qemu_vm_iso_file() {
	QEMU_FILE="$(cat ${THE_QEMU_STARTUP_SCRIPT} | grep '\--cdrom' | head -n 1 | awk '{print $2}')"
	stat ${QEMU_FILE}
	qemu-img info ${QEMU_FILE}
	echo "Do you want to delete it?"
	echo "删除后将无法撤销，请谨慎操作"
	do_you_want_to_continue
	rm -fv ${QEMU_FILE}
}
###############
how_to_creat_a_new_tmoe_qemu_vm() {
	cat <<-'EOF'
		   1.下载iso镜像文件 Download a iso file.
		   若虚拟磁盘内已经安装了系统，则可跳过此步。
		        
			2.新建一个虚拟磁盘
			Creat a vitual disk

			3.选择启动的iso
			Choose iso

			4.选择启动磁盘
			Choose disk

			5.修改相关参数

			6.输startqemu
			Type startqemu and press enter
	EOF
}
tmoe_qemu_faq() {
	RETURN_TO_WHERE='tmoe_qemu_faq'
	VIRTUAL_TECH=$(
		whiptail --title "FAQ(よくある質問)" --menu "您有哪些疑问？\nWhat questions do you have?" 13 55 3 \
			"1" "process进程管理说明" \
			"2" "creat a new vm如何新建虚拟机" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) qemu_process_management_instructions ;;
	2) how_to_creat_a_new_tmoe_qemu_vm ;;
	esac
	###############
	press_enter_to_return
	tmoe_qemu_faq
}
################
multi_qemu_vm_management() {
	SELECTION=""
	TMOE_QEMU_SCRIPT_FILE_PATH='/usr/local/bin/.tmoe-linux-qemu'
	THE_QEMU_STARTUP_SCRIPT='/usr/local/bin/startqemu'
	RETURN_TO_WHERE='multi_qemu_vm_management'
	VIRTUAL_TECH=$(
		whiptail --title "multi-vm" --menu "您可以管理多个虚拟机的配置" 17 55 8 \
			"1" "save conf保存当前虚拟机配置" \
			"2" "start多虚拟机启动管理" \
			"3" "delete conf多虚拟配置删除" \
			"4" "del vm disk删除当前虚拟机磁盘文件" \
			"5" "del iso删除当前虚拟机iso文件" \
			"6" "其它说明" \
			"7" "del special vm disk删除指定虚拟机的磁盘文件" \
			"8" "del special vm iso删除指定虚拟机的镜像文件" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) save_current_qemu_conf_as_a_new_script ;;
	2) multi_vm_start_manager ;;
	3) delete_multi_qemu_vm_conf ;;
	4) delete_current_qemu_vm_disk_file ;;
	5) delete_current_qemu_vm_iso_file ;;
	6) other_qemu_conf_related_instructions ;;
	7) delete_the_disk_file_of_the_specified_qemu_vm ;;
	8) delete_the_iso_file_of_the_specified_qemu_vm ;;
	esac
	###############
	press_enter_to_return
	multi_qemu_vm_management
}
################
save_current_qemu_conf_as_a_new_script() {
	mkdir -p ${TMOE_QEMU_SCRIPT_FILE_PATH}
	cd ${TMOE_QEMU_SCRIPT_FILE_PATH}
	TARGET_FILE_NAME=$(whiptail --inputbox "请自定义启动脚本名称\nPlease enter the script name." 10 50 --title "SCRIPT NAME" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		multi_qemu_vm_management
	elif [ "${TARGET_FILE_NAME}" = "startqemu" ] || [ "${TARGET_FILE_NAME}" = "debian-i" ] || [ "${TARGET_FILE_NAME}" = "startvnc" ]; then
		echo "文件已被占用，请重新输入"
		echo "Please re-enter."
		press_enter_to_return
		save_current_qemu_conf_as_a_new_script
	elif [ -z "${TARGET_FILE_NAME}" ]; then
		echo "请输入有效的名称"
		echo "Please enter a valid name"
		press_enter_to_return
		multi_qemu_vm_management
	else
		cp -pf /usr/local/bin/startqemu ${TMOE_QEMU_SCRIPT_FILE_PATH}/${TARGET_FILE_NAME}
		ln -sf ${TMOE_QEMU_SCRIPT_FILE_PATH}/${TARGET_FILE_NAME} /usr/local/bin/
		echo "您之后可以输${GREEN}${TARGET_FILE_NAME}${RESET}来启动该虚拟机"
	fi
}
#########
delete_the_iso_file_of_the_specified_qemu_vm() {
	START_DIR=${TMOE_QEMU_SCRIPT_FILE_PATH}
	BACKUP_FILE_NAME='*'
	echo "选中的虚拟机的iso镜像文件将被删除"
	echo "按Ctrl+C退出,若选项留空,则按回车键返回"
	echo "Press Ctrl+C to exit,press enter to return."
	select_file_manually
	TMOE_FILE_ABSOLUTE_PATH=${START_DIR}/${SELECTION}
	THE_QEMU_STARTUP_SCRIPT=${TMOE_FILE_ABSOLUTE_PATH}
	delete_current_qemu_vm_iso_file
}
############
delete_the_disk_file_of_the_specified_qemu_vm() {
	START_DIR=${TMOE_QEMU_SCRIPT_FILE_PATH}
	BACKUP_FILE_NAME='*'
	echo "选中的虚拟机的磁盘文件将被删除"
	echo "按Ctrl+C退出,若选项留空,则按回车键返回"
	echo "Press Ctrl+C to exit,press enter to return."
	select_file_manually
	TMOE_FILE_ABSOLUTE_PATH=${START_DIR}/${SELECTION}
	THE_QEMU_STARTUP_SCRIPT=${TMOE_FILE_ABSOLUTE_PATH}
	delete_current_qemu_vm_disk_file
}
############
select_file_manually() {
	count=0
	for restore_file in "${START_DIR}"/${BACKUP_FILE_NAME}; do
		restore_file_name[count]=$(echo $restore_file | awk -F'/' '{print $NF}')
		echo -e "($count) ${restore_file_name[count]}"
		count=$(($count + 1))
	done
	count=$(($count - 1))

	while true; do
		read -p "请输入${BLUE}选项数字${RESET},并按${GREEN}回车键。${RESET}Please type the ${BLUE}option number${RESET} and press ${GREEN}Enter:${RESET}" number
		if [[ -z "$number" ]]; then
			break
		elif ! [[ $number =~ ^[0-9]+$ ]]; then
			echo "Please enter the right number!"
			echo "请输正确的数字编号!"
		elif (($number >= 0 && $number <= $count)); then
			eval SELECTION=${restore_file_name[number]}
			# cp -fr "${START_DIR}/$choice" "$DIR/restore_file.properties"
			break
		else
			echo "Please enter the right number!"
			echo "请输正确的数字编号!"
		fi
	done
	if [ -z "${SELECTION}" ]; then
		echo "没有文件被选择"
		press_enter_to_return
		${RETURN_TO_WHERE}
	fi
}
#####################
multi_vm_start_manager() {
	START_DIR=${TMOE_QEMU_SCRIPT_FILE_PATH}
	BACKUP_FILE_NAME='*'
	echo "选中的配置将设定为startqemu的默认配置"
	echo "按Ctrl+C退出,若选项留空,则按回车键返回"
	echo "Press Ctrl+C to exit,press enter to return."
	select_file_manually
	TMOE_FILE_ABSOLUTE_PATH=${START_DIR}/${SELECTION}
	if [ ! -z "${SELECTION}" ]; then
		cp -pf ${TMOE_FILE_ABSOLUTE_PATH} /usr/local/bin/startqemu
	else
		echo "没有文件被选择"
	fi

	echo "您之后可以输startqemu来执行${SELECTION}"
	echo "是否需要启动${SELECTION}"
	do_you_want_to_continue
	${TMOE_FILE_ABSOLUTE_PATH}
}
############
delete_multi_qemu_vm_conf() {
	START_DIR=${TMOE_QEMU_SCRIPT_FILE_PATH}
	BACKUP_FILE_NAME='*'
	echo "选中的配置将被删除"
	echo "按Ctrl+C退出,若选项留空,则按回车键返回"
	echo "Press Ctrl+C to exit,press enter to return."
	select_file_manually
	TMOE_FILE_ABSOLUTE_PATH=${START_DIR}/${SELECTION}
	rm -fv ${TMOE_FILE_ABSOLUTE_PATH}
	TMOE_QEMU_CONFIG_LINK_FILE="/usr/local/bin/${SELECTION}"
	if [ -h "${TMOE_QEMU_CONFIG_LINK_FILE}" ]; then
		rm -f ${TMOE_QEMU_CONFIG_LINK_FILE}
	fi
}
###############
other_qemu_conf_related_instructions() {
	cat <<-ENDOFTMOEINST
		Q:${YELLOW}一个个删除配置太麻烦了，有没有更快速的方法？${RESET}
		A：有哒！rm -rfv /usr/local/bin/.tmoe-linux-qemu
		Q:${YELLOW}不知道为啥虚拟机启动不了${RESET}
		A：你可以看一下资源发布者所撰写的相关说明，再调整一下参数。
	ENDOFTMOEINST
}
############
qemu_process_management_instructions() {
	check_qemu_vnc_port
	echo "输startqemu启动qemu"
	echo "${BLUE}连接方式01${RESET}"
	echo "打开vnc客户端，输入访问地址localhost:${CURRENT_VNC_PORT}"
	echo "${BLUE}关机方式01${RESET}"
	echo "在qemu monitor界面下输system_powerdown关闭虚拟机电源，输stop停止"
	echo "按Ctrl+C退出qemu monitor"
	echo "Press Ctrl+C to exit qemu monitor."
	echo "${BLUE}连接方式02${RESET}"
	echo "若您需要使用ssh连接，则请新建一个termux会话窗口，并输入${GREEN}ssh -p 2888 root@localhost${RESET}"
	echo "本工具默认将虚拟机的22端口映射为宿主机的2888端口，若无法连接，则请在虚拟机下新建一个普通用户，再将上述命令中的root修改为普通用户名称"
	echo "若连接提示${YELLOW}REMOTE HOST IDENTIFICATION HAS CHANGED${RESET}，则请手动输${GREEN}ssh-keygen -f '/root/.ssh/known_hosts' -R '[localhost]:2888'${RESET}"
	echo "${BLUE}关机方式02${RESET}"
	echo "在linux虚拟机内输poweroff"
	echo "在windows虚拟机内输shutdown /s /t 0"
	echo "${BLUE}重启方式01${RESET}"
	echo "在linux虚拟机内输reboot"
	echo "在windows虚拟机内输shutdown /r /t 0"
}
#################
#sed '$!N;$!P;$!D;s/\(\n\)/\n    -test \\ \n/' startqemu
#sed "s@$(cat startqemu | tail -n 1)@& \\\@" startqemu
modify_qemu_cpu_cores_number() {
	CURRENT_CORES=$(cat startqemu | grep '\-smp ' | head -n 1 | awk '{print $2}')
	TARGET=$(whiptail --inputbox "请输入CPU核心数,默认为4,当前为${CURRENT_CORES}\nPlease enter the number of CPU cores, the default is 4" 10 50 --title "CPU" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		#echo "检测到您取消了操作"
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		sed -i "s@-smp .*@-smp ${TARGET} \\\@" startqemu
		echo "您已将CPU核心数修改为${TARGET}"
	fi
}
###########
modify_qemu_ram_size() {
	CURRENT_VALUE=$(cat startqemu | grep '\-m ' | head -n 1 | awk '{print $2}')
	TARGET=$(whiptail --inputbox "请输入运行内存大小,默认为2048(单位M),当前为${CURRENT_VALUE}\nPlease enter the RAM size, the default is 2048" 10 53 --title "RAM" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		#echo "检测到您取消了操作"
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
		echo "不建议超过本机实际内存"
	else
		sed -i "s@-m .*@-m ${TARGET} \\\@" startqemu
		echo "您已将RAM size修改为${TARGET}"
	fi
}
#################
download_alpine_and_docker_x64_img_file() {
	cat <<-EOF
		You can use this image to run docker on Android system.
		The password of the root account is empty. After starting the qemu virtual machine, open the vnc client and enter localhost:5902. If you want to use ssh connection, please create a new termux session, and then install openssh client. Finally, enter ${GREEN}ssh -p 2888 test@localhost${RESET}
		User: test, password: test
		您可以使用本镜像在宿主机为Android系统的设备上运行aline_x64并使用docker
		默认root密码为空
		您可以直接使用vnc客户端连接，访问地址为localhost:5902
		如果您想要使用ssh连接，那么请新建一个termux会话窗口，并输入apt update ;apt install -y openssh
		您也可以直接在linux容器里使用ssh客户端，输入${PACKAGES_INSTALL_COMMAND} openssh-client
		在安装完ssh客户端后，使用${GREEN}ssh -p 2888 test@localhost${RESET}连接
		由于root密码为空，故请使用普通用户连接，用户test,密码test
		在登录完普通用户后，您可以输${GREEN}su -${RESET}来切换至root用户
		为了您的安全着想，请在虚拟机启动完成后，输入${GREEN}passwd${RESET}来修改密码
		Download size(下载大小)约217MB，解压后约为1.2GB
	EOF
	do_you_want_to_continue
	DOWNLOAD_FILE_NAME='alpine_v3.11_x64-qemu.tar.xz'
	DOWNLOAD_PATH="${HOME}/sd/Download/backup"
	QEMU_DISK_FILE_NAME='alpine_v3.11_x64.qcow2'
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then

		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded\n Do you want to unzip it, or download it again?" 0 0); then
			echo "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			download_alpine_and_docker_x64_img_file_again
		fi
	else
		download_alpine_and_docker_x64_img_file_again
	fi
	uncompress_alpine_and_docker_x64_img_file
	echo "您之后可以输startqemu来启动"
	echo "默认VNC访问地址为localhost:5902"
	set_it_as_default_qemu_disk
	startqemu
}
#############
alpine_qemu_old() {
	echo "文件已解压至${DOWNLOAD_PATH}"
	qemu-img info ${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}
	echo "是否需要启动虚拟机？"
	do_you_want_to_continue
}
###########
download_alpine_and_docker_x64_img_file_again() {
	#THE_LATEST_ISO_LINK='https://m.tmoe.me/down/share/Tmoe-linux/qemu/alpine_v3.11_x64-qemu.tar.xz'
	#aria2c --allow-overwrite=true -s 16 -x 16 -k 1M "${THE_LATEST_ISO_LINK}"
	cd /tmp
	git clone --depth=1 -b x64 https://gitee.com/ak2/alpine_qemu .ALPINE_QEMU_TEMP_FOLDER
	cd .ALPINE_QEMU_TEMP_FOLDER
	cat alpine_v3.11_* >alpine_v3.11_x64-qemu.tar.xz
	mv alpine_v3.11_x64-qemu.tar.xz ${DOWNLOAD_PATH}
	cd ../
	rm -rf .ALPINE_QEMU_TEMP_FOLDER
	cd ${DOWNLOAD_PATH}
}
###########
uncompress_alpine_and_docker_x64_img_file() {
	#txz
	echo '正在解压中...'
	if [ $(command -v pv) ]; then
		pv ${DOWNLOAD_FILE_NAME} | tar -pJx
	else
		tar -Jpxvf ${DOWNLOAD_FILE_NAME}
	fi
}
##################
uncompress_tar_gz_file() {
	echo '正在解压中...'
	if [ $(command -v pv) ]; then
		pv ${DOWNLOAD_FILE_NAME} | tar -pzx
	else
		tar -zpxvf ${DOWNLOAD_FILE_NAME}
	fi
}
###################
dd_if_zero_of_qemu_tmp_disk() {
	rm -fv /tmp/tmoe_qemu
	echo "请在虚拟机内执行操作,不建议在宿主机内执行"
	echo "本操作将填充磁盘所有空白扇区"
	echo "若执行完成后，无法自动删除临时文件，则请手动输rm -f /tmp/tmoe_qemu"
	echo "请务必在执行完操作后,关掉虚拟机,并回到宿主机选择转换压缩"
	do_you_want_to_continue
	echo "此操作可能需要数分钟的时间..."
	echo "${GREEN}dd if=/dev/zero of=/tmp/tmoe_qemu bs=1M${RESET}"
	dd if=/dev/zero of=/tmp/tmoe_qemu bs=1M
	ls -lh /tmp/tmoe_qemu
	rm -fv /tmp/tmoe_qemu
}
##################
compress_or_dd_qcow2_img_file() {
	cd /usr/local/bin
	if (whiptail --title "您当前处于哪个环境" --yes-button 'Host' --no-button 'Guest' --yesno "您当前处于宿主机还是虚拟机环境？\nAre you in a host or guest environment?" 8 50); then
		compress_qcow2_img_file
	else
		dd_if_zero_of_qemu_tmp_disk
	fi
}
##########################
choose_tmoe_qemu_qcow2_model() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='img'
	if grep -q '\-hda' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hda' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到您当前没有加载虚拟磁盘"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
		press_enter_to_return
		${RETURN_TO_WHERE}
	else
		echo "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd ${FILE_PATH}
		stat ${SELECTION}
		qemu-img info ${SELECTION}
	fi
}
#########
expand_qemu_qcow2_img_file() {
	echo '建议您在调整容量前对磁盘文件进行备份。'
	echo '调整完成之后，您可以在虚拟机内部使用resize2fs命令对磁盘空间进行重新识别，例如resize2fs /dev/sda1'
	echo '在扩容之后，您必须在虚拟机系统内对该镜像进行分区并格式化后才能真正开始使用新空间。 在收缩磁盘映像前，必须先使用虚拟机内部系统的分区工具减少该分区的大小，然后相应地收缩磁盘映像，否则收缩磁盘映像将导致数据丢失'
	echo 'Arch wiki:After enlarging the disk image, you must use file system and partitioning tools inside the virtual machine to actually begin using the new space. When shrinking a disk image, you must first reduce the allocated file systems and partition sizes using the file system and partitioning tools inside the virtual machine and then shrink the disk image accordingly, otherwise shrinking the disk image will result in data loss! For a Windows guest, open the "create and format hard disk partitions" control panel.'
	do_you_want_to_continue
	choose_tmoe_qemu_qcow2_model
	CURRENT_VALUE=$(qemu-img info ${SELECTION} | grep 'virtual size' | awk '{print $3}')
	TARGET=$(whiptail --inputbox "请输入需要增加的空间大小,例如500M或10G(需包含单位),当前空间为${CURRENT_VALUE}\nPlease enter the size" 10 53 --title "virtual size" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		#echo "检测到您取消了操作"
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
		echo "不建议超过本机实际内存"
	else
		qemu-img resize ${SELECTION} +${TARGET}
		qemu-img check ${SELECTION}
		stat ${SELECTION}
		qemu-img info ${SELECTION}
		CURRENT_VALUE=$(qemu-img info ${SELECTION} | grep 'virtual size' | awk '{print $3}')
		echo "您已将virtual size修改为${CURRENT_VALUE}"
	fi
}
##############
compress_qcow2_img_file() {
	choose_tmoe_qemu_qcow2_model
	do_you_want_to_continue
	if (whiptail --title "请选择压缩方式" --yes-button "compress" --no-button "convert" --yesno "前者为常规压缩，后者转换压缩。♪(^∇^*) " 10 50); then
		echo 'compressing...'
		echo '正在压缩中...'
		qemu-img convert -c -O qcow2 ${SELECTION} ${SELECTION}_new-temp-file
	else
		echo 'converting...'
		echo '正在转换中...'
		qemu-img convert -O qcow2 ${SELECTION} ${SELECTION}_new-temp-file
	fi
	qemu-img info ${SELECTION}_new-temp-file
	mv -f ${SELECTION} original_${SELECTION}
	mv -f ${SELECTION}_new-temp-file ${SELECTION}
	echo '原文件大小'
	ls -lh original_${SELECTION} | tail -n 1 | awk '{print $5}'
	echo '压缩后的文件大小'
	ls -lh ${SELECTION} | tail -n 1 | awk '{print $5}'
	echo "压缩完成，是否删除原始文件?"
	qemu-img check ${SELECTION}
	echo "Do you want to delete the original file？"
	echo "请谨慎操作，在保证新磁盘数据无错前，不建议您删除原始文件，否则将导致原文件数据丢失"
	echo "若您取消操作，则请手动输rm ${FILE_PATH}/original_${SELECTION}"
	do_you_want_to_continue
	rm -fv original_${SELECTION}
}
################
download_virtual_machine_iso_file() {
	RETURN_TO_WHERE='download_virtual_machine_iso_file'
	NON_DEBIAN='false'
	DOWNLOAD_PATH="${HOME}/sd/Download"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	VIRTUAL_TECH=$(whiptail --title "IMAGE FILE" --menu "Which image file do you want to download?" 0 50 0 \
		"1" "alpine(latest-stable)" \
		"2" "Android x86_64(latest)" \
		"3" "debian-iso(每周自动构建,包含non-free)" \
		"4" "ubuntu" \
		"5" "flash iso烧录镜像文件至U盘" \
		"6" "windows" \
		"7" "LMDE(Linux Mint Debian Edition)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) download_alpine_virtual_iso ;;
	2) download_android_x86_file ;;
	3) download_debian_iso_file ;;
	4) download_ubuntu_iso_file ;;
	5) flash_iso_to_udisk ;;
	6) download_windows_10_iso ;;
	7) download_linux_mint_debian_edition_iso ;;
	esac
	###############
	press_enter_to_return
	download_virtual_machine_iso_file
}
###########
flash_iso_to_udisk() {
	FILE_EXT_01='iso'
	FILE_EXT_02='ISO'
	where_is_start_dir
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的iso文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		check_fdisk
	fi
}
################
check_fdisk() {
	if [ ! $(command -v fdisk) ]; then
		DEPENDENCY_01='fdisk'
		DEPENDENCY_02=''
		beta_features_quick_install
	fi
	lsblk
	df -h
	fdisk -l
	echo "${RED}WARNING！${RESET}您接下来需要选择一个${YELLOW}磁盘分区${RESET}，请复制指定磁盘的${RED}完整路径${RESET}（包含/dev）"
	echo "若选错磁盘，将会导致该磁盘数据${RED}完全丢失！${RESET}"
	echo "此操作${RED}不可逆${RESET}！请${GREEN}谨慎${RESET}选择！"
	echo "建议您在执行本操作前，对指定磁盘进行${BLUE}备份${RESET}"
	echo "若您因选错了磁盘而${YELLOW}丢失数据${RESET}，开发者${RED}概不负责！！！${RESET}"
	do_you_want_to_continue
	dd_flash_iso_to_udisk
}
################
dd_flash_iso_to_udisk() {
	DD_OF_TARGET=$(whiptail --inputbox "请输入磁盘路径，例如/dev/nvme0n1px或/dev/sdax,请以实际路径为准" 12 50 --title "DEVICES" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ] || [ -z "${DD_OF_TARGET}" ]; then
		echo "检测到您取消了操作"
		press_enter_to_return
		download_virtual_machine_iso_file
	fi
	echo "${DD_OF_TARGET}即将被格式化，所有文件都将丢失"
	do_you_want_to_continue
	umount -lf ${DD_OF_TARGET} 2>/dev/null
	echo "正在烧录中，这可能需要数分钟的时间..."
	dd <${TMOE_FILE_ABSOLUTE_PATH} >${DD_OF_TARGET}
}
############
download_win10_19041_x64_iso() {
	ISO_FILE_NAME='19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso'
	TMOE_FILE_ABSOLUTE_PATH=$(pwd)/${ISO_FILE_NAME}
	TMOE_ISO_URL="https://webdav.tmoe.me/down/share/windows/20H1/${ISO_FILE_NAME}"
	download_windows_tmoe_iso_model
}
##########
set_it_as_the_tmoe_qemu_iso() {
	cd /usr/local/bin
	sed -i '/--cdrom /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    --cdrom tmoe_iso_file_test \\\n/' startqemu
	sed -i "s@tmoe_iso_file_test@${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	echo "修改完成，相关配置将在下次启动qemu时生效"
}
########
download_tmoe_iso_file_again() {
	echo "即将为您下载win10 19041 iso镜像文件..."
	aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "${ISO_FILE_NAME}" "${TMOE_ISO_URL}"
	qemu-img info ${ISO_FILE_NAME}
}
################
download_win10_2004_x64_iso() {
	ISO_FILE_NAME='win10_2004_x64_tmoe.iso'
	TMOE_FILE_ABSOLUTE_PATH=$(pwd)/${ISO_FILE_NAME}
	TMOE_ISO_URL="https://webdav.tmoe.me/down/share/windows/20H1/${ISO_FILE_NAME}"
	download_windows_tmoe_iso_model
}
#############################
download_win10_19041_arm64_iso() {
	ISO_FILE_NAME='win10_2004_arm64_tmoe.iso'
	TMOE_FILE_ABSOLUTE_PATH=$(pwd)/${ISO_FILE_NAME}
	TMOE_ISO_URL="https://webdav.tmoe.me/down/share/windows/20H1/${ISO_FILE_NAME}"
	cat <<-'EOF'
		本文件为uupdump转换的原版iso
		若您需要在qemu虚拟机里使用，那么请手动制作Windows to Go启动盘
		您也可以阅览其它人所撰写的教程
		    https://zhuanlan.zhihu.com/p/32905265
	EOF
	download_windows_tmoe_iso_model
}
############
download_windows_tmoe_iso_model() {
	if [ -e "${ISO_FILE_NAME}" ]; then
		if (whiptail --title "检测到iso已下载,请选择您需要执行的操作！" --yes-button '设置为qemu iso' --no-button 'DL again重新下载' --yesno "Detected that the file has been downloaded" 7 60); then
			set_it_as_the_tmoe_qemu_iso
			${RETURN_TO_WHERE}
		else
			download_tmoe_iso_file_again
		fi
	else
		download_tmoe_iso_file_again
	fi
	echo "下载完成，是否将其设置为qemu启动光盘？[Y/n]"
	do_you_want_to_continue
	set_it_as_the_tmoe_qemu_iso
}
#########
download_windows_10_iso() {
	RETURN_TO_WHERE='download_windows_10_iso'
	VIRTUAL_TECH=$(whiptail --title "ISO FILE" --menu "Which win10 version do you want to download?" 12 55 4 \
		"1" "win10_2004_x64(多合一版)" \
		"2" "win10_2004_arm64" \
		"3" "other" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) download_win10_2004_x64_iso ;;
	2) download_win10_19041_arm64_iso ;;
	3)
		cat <<-'EOF'
			如需下载其他版本，请前往microsoft官网
			https://www.microsoft.com/zh-cn/software-download/windows10ISO
			您亦可前往uupdump.ml，自行转换iso文件。
		EOF
		;;
	esac
	###############
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#####################
download_linux_mint_debian_edition_iso() {
	if (whiptail --title "架构" --yes-button "x86_64" --no-button 'x86_32' --yesno "您想要下载哪个架构的版本？\n Which version do you want to download?" 9 50); then
		GREP_ARCH='64bit'
	else
		GREP_ARCH='32bit'
	fi
	#THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/linuxmint-cd/debian/lmde-4-cinnamon-64bit.iso"
	ISO_REPO='https://mirrors.huaweicloud.com/linuxmint-cd/debian/'
	THE_LATEST_FILE_VERSION=$(curl -L ${ISO_REPO} | grep "${GREP_ARCH}" | grep '.iso' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	THE_LATEST_ISO_LINK="${ISO_REPO}${THE_LATEST_FILE_VERSION}"
	aria2c_download_file
	stat ${THE_LATEST_FILE_VERSION}
	ls -lh ${DOWNLOAD_PATH}/${THE_LATEST_FILE_VERSION}
	echo "下载完成"
}
#####################
##########################
which_alpine_arch() {
	if (whiptail --title "请选择架构" --yes-button "x64" --no-button "arm64" --yesno "您是想要下载x86_64还是arm64架构的iso呢？♪(^∇^*) " 10 50); then
		ALPINE_ARCH='x86_64'
	else
		ALPINE_ARCH='aarch64'
	fi
}
####################
download_alpine_virtual_iso() {
	which_alpine_arch
	WHICH_ALPINE_EDITION=$(
		whiptail --title "alpine EDITION" --menu "请选择您需要下载的版本？Which edition do you want to download?" 16 55 6 \
			"1" "standard(标准版)" \
			"2" "extended(扩展版)" \
			"3" "virt(虚拟机版)" \
			"4" "xen(虚拟化)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${WHICH_ALPINE_EDITION} in
	0 | "") download_virtual_machine_iso_file ;;
	1) ALPINE_EDITION='standard' ;;
	2) ALPINE_EDITION='extended' ;;
	3) ALPINE_EDITION='virt' ;;
	4) ALPINE_EDITION='xen' ;;
	esac
	###############
	download_the_latest_alpine_iso_file
	press_enter_to_return
	download_virtual_machine_iso_file
}
###############
download_the_latest_alpine_iso_file() {
	ALPINE_ISO_REPO="https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/releases/${ALPINE_ARCH}/"
	RELEASE_FILE="${ALPINE_ISO_REPO}latest-releases.yaml"
	ALPINE_VERSION=$(curl -L ${RELEASE_FILE} | grep ${ALPINE_EDITION} | grep '.iso' | head -n 1 | awk -F ' ' '$0=$NF')
	THE_LATEST_ISO_LINK="${ALPINE_ISO_REPO}${ALPINE_VERSION}"
	aria2c_download_file
}
##################
download_ubuntu_iso_file() {
	if (whiptail --title "请选择版本" --yes-button "20.04" --no-button "自定义版本" --yesno "您是想要下载20.04还是自定义版本呢？♪(^∇^*) " 10 50); then
		UBUNTU_VERSION='20.04'
		download_ubuntu_latest_iso_file
	else
		TARGET=$(whiptail --inputbox "请输入版本号，例如18.04\n Please enter the version." 12 50 --title "UBUNTU VERSION" 3>&1 1>&2 2>&3)
		if [ "$?" != "0" ]; then
			echo "检测到您取消了操作"
			UBUNTU_VERSION='20.04'
		else
			UBUNTU_VERSION="$(echo ${TARGET} | head -n 1 | cut -d ' ' -f 1)"
		fi
	fi
	download_ubuntu_latest_iso_file
}
#############
download_ubuntu_latest_iso_file() {
	UBUNTU_MIRROR='tuna'
	UBUNTU_EDITION=$(
		whiptail --title "UBUNTU EDITION" --menu "请选择您需要下载的版本？Which edition do you want to download?" 16 55 6 \
			"1" "ubuntu-server(自动识别架构)" \
			"2" "ubuntu(gnome)" \
			"3" "xubuntu(xfce)" \
			"4" "kubuntu(kde plasma)" \
			"5" "lubuntu(lxqt)" \
			"6" "ubuntu-mate" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${UBUNTU_EDITION} in
	0 | "") download_virtual_machine_iso_file ;;
	1) UBUNTU_DISTRO='ubuntu-legacy-server' ;;
	2) UBUNTU_DISTRO='ubuntu-gnome' ;;
	3) UBUNTU_DISTRO='xubuntu' ;;
	4) UBUNTU_DISTRO='kubuntu' ;;
	5) UBUNTU_DISTRO='lubuntu' ;;
	6) UBUNTU_DISTRO='ubuntu-mate' ;;
	esac
	###############
	if [ ${UBUNTU_DISTRO} = 'ubuntu-gnome' ]; then
		download_ubuntu_huawei_mirror_iso
	else
		download_ubuntu_tuna_mirror_iso
	fi
	press_enter_to_return
	download_virtual_machine_iso_file
}
###############
ubuntu_arm_warning() {
	echo "请选择Server版"
	arch_does_not_support
	download_ubuntu_latest_iso_file
}
################
aria2c_download_normal_file_s3() {
	echo ${YELLOW}${DOWNLOAD_FILE_URL}${RESET}
	cd ${DOWNLOAD_PATH}
	#aria2c --allow-overwrite=true -s 3 -x 3 -k 1M "${DOWNLOAD_FILE_URL}"
	#此处用wget会自动转义url
	wget "${DOWNLOAD_FILE_URL}"
}
######################
aria2c_download_file() {
	echo ${THE_LATEST_ISO_LINK}
	do_you_want_to_continue
	if [ -z "${DOWNLOAD_PATH}" ]; then
		cd ~
	else
		cd ${DOWNLOAD_PATH}
	fi
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M "${THE_LATEST_ISO_LINK}"
}
############
download_ubuntu_huawei_mirror_iso() {
	if [ "${ARCH_TYPE}" = "i386" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/ubuntu-releases/16.04.6/ubuntu-16.04.6-desktop-i386.iso"
	else
		THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/ubuntu-releases/${UBUNTU_VERSION}/ubuntu-${UBUNTU_VERSION}-desktop-amd64.iso"
	fi
	aria2c_download_file
}
####################
get_ubuntu_server_iso_url() {
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/${UBUNTU_DISTRO}/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-legacy-server-${ARCH_TYPE}.iso"
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/ubuntu-releases/16.04.6/ubuntu-16.04.6-server-i386.iso"
	else
		THE_LATEST_ISO_LINK="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/ubuntu/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-live-server-${ARCH_TYPE}.iso"
	fi
}
##############
get_other_ubuntu_distros_url() {
	if [ "${ARCH_TYPE}" = "i386" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/${UBUNTU_DISTRO}/releases/18.04.4/release/${UBUNTU_DISTRO}-18.04.4-desktop-i386.iso"
	else
		THE_LATEST_ISO_LINK="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/${UBUNTU_DISTRO}/releases/${UBUNTU_VERSION}/release/${UBUNTU_DISTRO}-${UBUNTU_VERSION}-desktop-amd64.iso"
	fi
}
################
download_ubuntu_tuna_mirror_iso() {
	if [ ${UBUNTU_DISTRO} = 'ubuntu-legacy-server' ]; then
		get_ubuntu_server_iso_url
	else
		get_other_ubuntu_distros_url
	fi
	aria2c_download_file
}
#######################
download_android_x86_file() {
	REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/osdn/android-x86/'
	REPO_FOLDER=$(curl -L ${REPO_URL} | grep -v incoming | grep date | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	if [ "${ARCH_TYPE}" = 'i386' ]; then
		THE_LATEST_ISO_VERSION=$(curl -L ${REPO_URL}${REPO_FOLDER} | grep -v 'x86_64' | grep date | grep '.iso' | tail -n 1 | head -n 1 | cut -d '=' -f 4 | cut -d '"' -f 2)
	else
		THE_LATEST_ISO_VERSION=$(curl -L ${REPO_URL}${REPO_FOLDER} | grep date | grep '.iso' | tail -n 2 | head -n 1 | cut -d '=' -f 4 | cut -d '"' -f 2)
	fi
	THE_LATEST_ISO_LINK="${REPO_URL}${REPO_FOLDER}${THE_LATEST_ISO_VERSION}"
	#echo ${THE_LATEST_ISO_LINK}
	#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_ISO_VERSION}" "${THE_LATEST_ISO_LINK}"
	aria2c_download_file
}
################
download_debian_qcow2_file() {
	DOWNLOAD_PATH="${HOME}/sd/Download/backup"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	if (whiptail --title "Edition" --yes-button "tmoe" --no-button 'openstack_arm64' --yesno "您想要下载哪个版本的磁盘镜像文件？\nWhich edition do you want to download?" 9 50); then
		download_tmoe_debian_x64_or_arm64_qcow2_file
	else
		GREP_ARCH='arm64'
		QCOW2_REPO='https://mirrors.ustc.edu.cn/debian-cdimage/openstack/current/'
		THE_LATEST_FILE_VERSION=$(curl -L ${QCOW2_REPO} | grep "${GREP_ARCH}" | grep qcow2 | grep -v '.index' | cut -d '=' -f 2 | cut -d '"' -f 2 | tail -n 1)
		THE_LATEST_ISO_LINK="${QCOW2_REPO}${THE_LATEST_FILE_VERSION}"
		aria2c_download_file
		stat ${THE_LATEST_FILE_VERSION}
		qemu-img info ${THE_LATEST_FILE_VERSION}
		ls -lh ${DOWNLOAD_PATH}/${THE_LATEST_FILE_VERSION}
		echo "下载完成"
	fi
}
###################
note_of_qemu_boot_uefi() {
	echo '使用此磁盘需要将引导方式切换至UEFI'
	echo 'You should modify the boot method to uefi.'
}
############
note_of_qemu_boot_legacy_bios() {
	echo '使用此磁盘需要将引导方式切换回默认'
	echo 'You should modify the boot method to legacy bios.'
}
#############
note_of_tmoe_password() {
	echo "user:tmoe  password:tmoe"
	echo "用户：tmoe  密码：tmoe"
}
##############
note_of_empty_root_password() {
	echo 'user:root'
	echo 'The password is empty.'
	echo '用户名root，密码为空'
}
################
download_lmde_4_qcow2_file() {
	cd ${DOWNLOAD_PATH}
	DOWNLOAD_FILE_NAME='LMDE4_tmoe_x64.tar.xz'
	QEMU_DISK_FILE_NAME='LMDE4_tmoe_x64.qcow2'
	echo 'Download size(下载大小)约2.76GiB，解压后约为9.50GiB'
	THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/LMDE4_tmoe_x64.tar.xz'
	note_of_qemu_boot_legacy_bios
	note_of_tmoe_password
	do_you_want_to_continue
	download_debian_tmoe_qemu_qcow2_file
}
############
download_windows_server_2008_data_center_qcow2_file() {
	cd ${DOWNLOAD_PATH}
	DOWNLOAD_FILE_NAME='win2008_r2_tmoe_x64.tar.xz'
	QEMU_DISK_FILE_NAME='win2008_r2_tmoe_x64.qcow2'
	echo 'Download size(下载大小)约2.26GiB，解压后约为12.6GiB'
	THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/win2008_r2_tmoe_x64.tar.xz'
	note_of_qemu_boot_legacy_bios
	echo '进入虚拟机后，您需要自己设定一个密码'
	do_you_want_to_continue
	download_debian_tmoe_qemu_qcow2_file
}
#####################
download_ubuntu_kylin_20_04_qcow2_file() {
	cd ${DOWNLOAD_PATH}
	DOWNLOAD_FILE_NAME='ubuntu_kylin_20-04_tmoe_x64.tar.xz'
	QEMU_DISK_FILE_NAME='ubuntu_kylin_20-04_tmoe_x64.qcow2'
	echo 'Download size(下载大小)约1.81GiB，解压后约为7.65GiB'
	THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/ubuntu_kylin_20-04_tmoe_x64.tar.xz'
	note_of_qemu_boot_uefi
	note_of_tmoe_password
	do_you_want_to_continue
	download_debian_tmoe_qemu_qcow2_file
}
###################
download_arch_linux_qcow2_file() {
	cd ${DOWNLOAD_PATH}
	DOWNLOAD_FILE_NAME='arch_linux_x64_tmoe_20200605.tar.xz'
	QEMU_DISK_FILE_NAME='arch_linux_x64_tmoe_20200605.qcow2'
	echo 'Download size(下载大小)约678MiB，解压后约为‪1.755GiB'
	#THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/arch_linux_x64_tmoe_20200605.tar.xz'
	note_of_qemu_boot_legacy_bios
	note_of_empty_root_password
	do_you_want_to_continue
	check_arch_linux_qemu_qcow2_file
}
################
check_arch_linux_qemu_qcow2_file() {
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it, or download it again?" 0 0); then
			echo "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			git_clone_arch_linux_qemu_qcow2_file
		fi
	else
		git_clone_arch_linux_qemu_qcow2_file
	fi
	uncompress_alpine_and_docker_x64_img_file
	set_it_as_default_qemu_disk
}
#################
git_clone_arch_linux_qemu_qcow2_file() {
	cd /tmp
	mkdir -p .ARCH_QEMU_TEMP_FOLDER
	cd .ARCH_QEMU_TEMP_FOLDER
	git clone --depth=1 -b x64 https://gitee.com/ak2/arch_qemu_01 .ARCH_QEMU_TEMP_FOLDER_01
	cd .ARCH_QEMU_TEMP_FOLDER_01
	mv -f arch_linux_* ../
	cd ..
	git clone --depth=1 -b x64 https://gitee.com/ak2/arch_qemu_02 .ARCH_QEMU_TEMP_FOLDER_02
	cd .ARCH_QEMU_TEMP_FOLDER_02
	mv -f arch_linux_* ../
	cd ..
	cat arch_linux_* >${DOWNLOAD_FILE_NAME}
	mv -f ${DOWNLOAD_FILE_NAME} ${DOWNLOAD_PATH}
	cd ../
	rm -rf .ARCH_QEMU_TEMP_FOLDER
	cd ${DOWNLOAD_PATH}
}
################
git_clone_tmoe_linux_qemu_qcow2_file() {
	cd /tmp
	git clone --depth=1 -b ${BRANCH_NAME} ${TMOE_LINUX_QEMU_REPO} .${DOWNLOAD_FILE_NAME}_QEMU_TEMP_FOLDER
	cd .${DOWNLOAD_FILE_NAME}_QEMU_TEMP_FOLDER
	cat ${QEMU_QCOW2_FILE_PREFIX}* >${DOWNLOAD_FILE_NAME}
	mv -f ${DOWNLOAD_FILE_NAME} ${DOWNLOAD_PATH}
	cd ../
	rm -rf .${DOWNLOAD_FILE_NAME}_QEMU_TEMP_FOLDER
	cd ${DOWNLOAD_PATH}
}
################
download_tmoe_debian_x64_or_arm64_qcow2_file() {
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	QEMU_ARCH=$(
		whiptail --title "Debian qcow2 tmoe edition" --menu "Which version do you want to download？\n您想要下载哪个版本的磁盘文件?${QEMU_ARCH_STATUS}" 0 0 0 \
			"1" "Buster x86_64" \
			"2" "Buster arm64" \
			"3" "关于ssh-server的说明" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${QEMU_ARCH} in
	0 | "") tmoe_qemu_templates_repo ;;
	1)
		DOWNLOAD_FILE_NAME='debian-10.4-generic-20200604_tmoe_x64.tar.xz'
		QEMU_DISK_FILE_NAME='debian-10-generic-20200604_tmoe_x64.qcow2'
		CURRENT_TMOE_QEMU_BIN='/usr/bin/qemu-system-aarch64'
		LATER_TMOE_QEMU_BIN='/usr/bin/qemu-system-x86_64'
		echo 'Download size(下载大小)约282MiB，解压后约为‪1.257GiB'
		#THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/debian-10.4-generic-20200604_tmoe_x64.tar.xz'
		TMOE_LINUX_QEMU_REPO='https://gitee.com/ak2/debian_qemu'
		BRANCH_NAME='x64'
		QEMU_QCOW2_FILE_PREFIX='debian_linux_'
		;;
	2)
		DOWNLOAD_FILE_NAME='debian-10.4.1-20200515-tmoe_arm64.tar.xz'
		QEMU_DISK_FILE_NAME='debian-10.4.1-20200515-tmoe_arm64.qcow2'
		echo 'Download size(下载大小)约339MiB，解压后约为‪1.6779GiB'
		echo '本系统为arm64版，请在下载完成后，手动进入tmoe-qemu arm64专区选择磁盘文件'
		#THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/debian-10.4.1-20200515-tmoe_arm64.tar.xz'
		TMOE_LINUX_QEMU_REPO='https://gitee.com/ak2/debian_arm64_qemu'
		BRANCH_NAME='arm64'
		QEMU_QCOW2_FILE_PREFIX='debian_linux_'
		;;
	3)
		cat <<-'EOF'
			       若sshd启动失败，则请执行dpkg-reconfigure openssh-server
				   如需使用密码登录ssh，则您需要手动修改sshd配置文件
				   cd /etc/ssh
				   sed -i 's@PermitRootLogin.*@PermitRootLogin yes@' sshd_config
			       sed -i 's@PasswordAuthentication.*@PasswordAuthentication yes@' sshd_config
		EOF
		press_enter_to_return
		download_tmoe_debian_x64_or_arm64_qcow2_file
		;;
	esac
	###############
	do_you_want_to_continue
	#download_debian_tmoe_qemu_qcow2_file
	check_tmoe_qemu_qcow2_file_and_git
	press_enter_to_return
	download_tmoe_debian_x64_or_arm64_qcow2_file
}
#####################
#################
set_it_as_default_qemu_disk() {
	echo "文件已解压至${DOWNLOAD_PATH}"
	cd ${DOWNLOAD_PATH}
	qemu-img check ${QEMU_DISK_FILE_NAME}
	qemu-img info ${QEMU_DISK_FILE_NAME}
	echo "是否将其设置为默认的qemu磁盘？"
	do_you_want_to_continue
	cd /usr/local/bin
	sed -i '/-hda /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hda tmoe_hda_config_test \\\n/' startqemu
	sed -i "s@-hda tmoe_hda_config_test@-hda ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	sed -i "s@${CURRENT_TMOE_QEMU_BIN}@${LATER_TMOE_QEMU_BIN}@" startqemu
	if [ ${QEMU_DISK_FILE_NAME} = 'arch_linux_x64_tmoe_20200605.qcow2' ]; then
		sed -i '/-bios /d' startqemu
	fi
	# sed -i 's@/usr/bin/qemu-system-x86_64@/usr/bin/qemu-system-aarch64@' startqemu
	echo "设置完成，您之后可以输startqemu启动"
	echo "若启动失败，则请检查qemu的相关设置选项"
}
##################
download_debian_tmoe_qemu_qcow2_file() {
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it, or download it again?" 0 0); then
			echo "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			download_debian_tmoe_arm64_img_file_again
		fi
	else
		download_debian_tmoe_arm64_img_file_again
	fi
	uncompress_alpine_and_docker_x64_img_file
	set_it_as_default_qemu_disk
}
#############
check_tmoe_qemu_qcow2_file_and_git() {
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it, or download it again?" 0 0); then
			echo "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			git_clone_tmoe_linux_qemu_qcow2_file
		fi
	else
		git_clone_tmoe_linux_qemu_qcow2_file
	fi
	uncompress_alpine_and_docker_x64_img_file
	set_it_as_default_qemu_disk
}
##############################
download_debian_tmoe_arm64_img_file_again() {
	aria2c --allow-overwrite=true -s 16 -x 16 -k 1M "${THE_LATEST_ISO_LINK}"
}
##########
download_debian_iso_file() {
	DEBIAN_FREE='unkown'
	DEBIAN_ARCH=$(
		whiptail --title "architecture" --menu "请选择您需要下载的架构版本，non-free版包含了非自由固件(例如闭源无线网卡驱动等)" 18 55 9 \
			"1" "x64(non-free,unofficial)" \
			"2" "x86(non-free,unofficial)" \
			"3" "x64(free)" \
			"4" "x86(free)" \
			"5" "arm64" \
			"6" "armhf" \
			"7" "mips" \
			"8" "mipsel" \
			"9" "mips64el" \
			"10" "ppc64el" \
			"11" "s390x" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${DEBIAN_ARCH} in
	0 | "") download_virtual_machine_iso_file ;;
	1)
		GREP_ARCH='amd64'
		DEBIAN_FREE='false'
		download_debian_nonfree_iso
		;;
	2)
		GREP_ARCH='i386'
		DEBIAN_FREE='false'
		download_debian_nonfree_iso
		;;
	3)
		GREP_ARCH='amd64'
		DEBIAN_FREE='true'
		download_debian_nonfree_iso
		;;
	4)
		GREP_ARCH='i386'
		DEBIAN_FREE='true'
		download_debian_nonfree_iso
		;;
	5) GREP_ARCH='arm64' ;;
	6) GREP_ARCH='armhf' ;;
	7) GREP_ARCH='mips' ;;
	8) GREP_ARCH='mipsel' ;;
	9) GREP_ARCH='mips64el' ;;
	10) GREP_ARCH='ppc64el' ;;
	11) GREP_ARCH='s390x' ;;
	esac
	###############
	if [ ${DEBIAN_FREE} = 'unkown' ]; then
		download_debian_weekly_builds_iso
	fi
	press_enter_to_return
	download_virtual_machine_iso_file
}
##################
download_debian_nonfree_iso() {
	DEBIAN_LIVE=$(
		whiptail --title "architecture" --menu "您下载的镜像中需要包含何种桌面环境？" 16 55 8 \
			"1" "cinnamon" \
			"2" "gnome" \
			"3" "kde plasma" \
			"4" "lxde" \
			"5" "lxqt" \
			"6" "mate" \
			"7" "standard(默认无桌面)" \
			"8" "xfce" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${DEBIAN_LIVE} in
	0 | "") download_debian_iso_file ;;
	1) DEBIAN_DE='cinnamon' ;;
	2) DEBIAN_DE='gnome' ;;
	3) DEBIAN_DE='kde' ;;
	4) DEBIAN_DE='lxde' ;;
	5) DEBIAN_DE='lxqt' ;;
	6) DEBIAN_DE='mate' ;;
	7) DEBIAN_DE='standard' ;;
	8) DEBIAN_DE='xfce' ;;
	esac
	##############
	if [ ${DEBIAN_FREE} = 'false' ]; then
		download_debian_nonfree_live_iso
	else
		download_debian_free_live_iso
	fi
}
###############
download_debian_weekly_builds_iso() {
	#https://mirrors.ustc.edu.cn/debian-cdimage/weekly-builds/arm64/iso-cd/debian-testing-arm64-netinst.iso
	THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/weekly-builds/${GREP_ARCH}/iso-cd/debian-testing-${GREP_ARCH}-netinst.iso"
	echo ${THE_LATEST_ISO_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-testing-${GREP_ARCH}-netinst.iso" "${THE_LATEST_ISO_LINK}"
}
##################
download_debian_free_live_iso() {
	THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/weekly-live-builds/${GREP_ARCH}/iso-hybrid/debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}.iso"
	echo ${THE_LATEST_ISO_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}.iso" "${THE_LATEST_ISO_LINK}"
}
############
download_debian_nonfree_live_iso() {
	THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/unofficial/non-free/cd-including-firmware/weekly-live-builds/${GREP_ARCH}/iso-hybrid/debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}%2Bnonfree.iso"
	echo ${THE_LATEST_ISO_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}-nonfree.iso" "${THE_LATEST_ISO_LINK}"
}
#####################
wine_depencies(){ 
    DEPENDENCY_01='wine winetricks q4wine'
	DEPENDENCY_02='playonlinux wine32'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			DEPENDENCY_01='wine winetricks q4wine'
		fi
		if [ "${INSTALL_WINE}" = "true" ]; then
			dpkg --add-architecture i386
		    apt update
		    apt install winetricks-zh wine64
		else
		     apt purge winetricks-zh	
		fi
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='winetricks-zh'
		DEPENDENCY_02='playonlinux5-git q4wine'
	fi
}
##########
install_wine64() {
	INSTALL_WINE='true'
	wine_depencies
	beta_features_quick_install
	if [ "${ARCH_TYPE}" != "i386" ]; then
		cat <<-'EOF'
			如需完全卸载wine，那么您还需要移除i386架构的软件包。
			aptitude remove ~i~ri386
			dpkg  --remove-architecture i386
			apt update
		EOF
	fi
}
#########################
install_aqemu() {
	DEPENDENCY_01='aqemu virt-manager'
	DEPENDENCY_02='qemu gnome-boxes'
	#qemu-block-extra
	beta_features_quick_install
}
#########
download_ubuntu_ppa_deb_model_01() {
	cd /tmp/
	THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '.deb' | grep "${GREP_NAME}" | head -n 1 | cut -d '=' -f 5 | cut -d '"' -f 2)"
	THE_LATEST_DEB_LINK="${REPO_URL}${THE_LATEST_DEB_VERSION}"
	echo ${THE_LATEST_DEB_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_VERSION}" "${THE_LATEST_DEB_LINK}"
	apt install ./${THE_LATEST_DEB_VERSION}
	rm -fv ${THE_LATEST_DEB_VERSION}
}
##############
install_anbox() {
	cat <<-'EndOfFile'
		WARNING!本软件需要安装内核模块补丁,且无法保证可以正常运行!
		您亦可使用以下补丁，并将它们构建为模块。
		https://salsa.debian.org/kernel-team/linux/blob/master/debian/patches/debian/android-enable-building-ashmem-and-binder-as-modules.patch
		https://salsa.debian.org/kernel-team/linux/blob/master/debian/patches/debian/export-symbols-needed-by-android-drivers.patch
		若模块安装失败，则请前往官网阅读说明https://docs.anbox.io/userguide/install_kernel_modules.html
		如需卸载该模块，请手动输apt purge -y anbox-modules-dkms
	EndOfFile
	do_you_want_to_continue
	DEPENDENCY_01=''
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			add-apt-repository ppa:morphis/anbox-support
			apt update
			apt install anbox-modules-dkms
			apt install linux-headers-generic
		else
			REPO_URL='http://ppa.launchpad.net/morphis/anbox-support/ubuntu/pool/main/a/anbox-modules/'
			GREP_NAME='all'
			download_ubuntu_ppa_deb_model_01
		fi
		modprobe ashmem_linux
		modprobe binder_linux
		ls -1 /dev/{ashmem,binder}
		DEPENDENCY_02='anbox'
		beta_features_quick_install
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='anbox-modules-dkms-git'
		DEPENDENCY_02='anbox-git'
		beta_features_quick_install
	else
		non_debian_function
	fi
	if [ $(command -v anbox) ] && [ ! -f "/var/lib/anbox/android.img" ]; then
		download_anbox_rom
	fi
	service anbox-container-manager start
	echo "service anbox-container-manager start"
	service anbox-container-manager start || systemctl start anbox-container-manager
	service anbox-container-manager status || systemctl status anbox-container-manager
	echo 'anbox launch --package=org.anbox.appmgr --component=org.anbox.appmgr.AppViewActivity'
	echo 'Do you want to start it?'
	do_you_want_to_continue
	anbox launch --package=org.anbox.appmgr --component=org.anbox.appmgr.AppViewActivity
}
###########
download_anbox_rom() {
	lsmod | grep -e ashmem_linux -e binder_linux
	ls -lh /dev/binder /dev/ashmem
	anbox check-features
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		THE_LATEST_ISO_LINK="https://build.anbox.io/android-images/2018/07/19/android_amd64.img"
	elif [ "${ARCH_TYPE}" = "arm64" ]; then
		THE_LATEST_ISO_LINK="https://build.anbox.io/android-images/2017/08/04/android_1_arm64.img"
	fi
	echo ${THE_LATEST_ISO_LINK}
	do_you_want_to_continue
	aria2c --allow-overwrite=true -s 16 -x 16 -k 1M "${THE_LATEST_ISO_LINK}"
}
###############
install_catfish() {
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您处于proot环境下，可能无法成功创建索引数据库"
		echo "若安装时卡在mlocalte，请按Ctrl+C并强制重启终端，最后输${PACKAGES_REMOVE_COMMAND} mlocate catfish"
		do_you_want_to_continue
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			echo "检测到您使用的ubuntu，无法为您自动安装"
			read
			beta_features
		fi
	fi
	DEPENDENCY_01=''
	DEPENDENCY_02='catfish'
	beta_features_quick_install
}
##################
install_gnome_logs() {
	DEPENDENCY_01='gnome-system-tools'
	DEPENDENCY_02='gnome-logs'
	beta_features_quick_install
}
##################
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
tmoe_fcitx5_menu(){ 
	if [ ! $(command -v unzstd) ]; then
		echo "${PACKAGES_INSTALL_COMMAND} zstd"
		${PACKAGES_INSTALL_COMMAND} zstd
		echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} zstd"
	fi
    RETURN_TO_WHERE='tmoe_fcitx5_menu'
	NON_DEBIAN='false'
	INPUT_METHOD=$(
		whiptail --title "Fcitx5" --menu "Fcitx5 是继 Fcitx 后的新一代输入法框架。\n词库是输入法保存的一些流行词语、常用词语或专业术语等的信息,\n添加流行词库能增加流行候选词的命中率" 0 55 0 \
			"1" "fcitx5安装与卸载" \
			"2" "肥猫百万大词库@felixonmars" \
			"3" "萌娘百科词库@outloudvi" \
			"4" "fcitx5-rime" \
			"5" "beautification输入法美化主题" \
			"0" "Return to previous menu 返回上级菜单" \
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
input_method_beautification(){ 
    RETURN_TO_WHERE='input_method_beautification'
	DEPENDENCY_01=''
	NON_DEBIAN='false'
	FCIITX5_CLASSUI_CONF_PATH="${HOME}/.config/fcitx5/conf"
	FCIITX5_CLASSUI_CONF_FILE="${FCIITX5_CLASSUI_CONF_PATH}/classicui.conf"
	INPUT_METHOD=$(
		whiptail --title "Fcitx5" --menu "fcitx主题" 0 55 0 \
			"1" "Material Design(微软拼音风格)@hosxy" \
			"2" "kimpanel(支持kde-wayland)" \
			"3" "gnome-shell-extension-kimpanel(支持gnome-wayland)" \
			"4" "edit config编辑主题配置" \
			"0" "Return to previous menu 返回上级菜单" \
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
edit_fcitx_theme_config_file(){ 
	    if [ $(command -v editor) ]; then
			editor ${FCIITX5_CLASSUI_CONF_FILE}
		else
		    nano ${FCIITX5_CLASSUI_CONF_FILE}
		fi
		chown ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${FCIITX5_CLASSUI_CONF_FILE}
}
#############
configure_fcitx5_material_color_theme (){ 
    RETURN_TO_WHERE='install_fcitx5_material_color_theme'
	MATERIAL_COLOR_FOLDER="${HOME}/.local/share/fcitx5/themes/Material-Color"
	CURRENT_FCITX5_COLOR="$(ls -l ${MATERIAL_COLOR_FOLDER}/panel.png | awk -F ' ' '{print $NF}' | cut -d '-' -f 2 | cut -d '.' -f 1)"
	if [ ! -z "${CURRENT_FCITX5_COLOR}" ];then
	    FCITX_THEME_STATUS="检测到当前fcitx5-material主题配色为${CURRENT_FCITX5_COLOR}"
	else
        FCITX_THEME_STATUS="检测到您未指定fcitx5-material主题的配色"
	fi
	if [ ! -e "${MATERIAL_COLOR_FOLDER}" ];then
        FCITX_THEME_STATUS="检测您尚未下载fcitx5-material主题"
	fi
	PANEL_COLOR_PNG='' 
	#DEPENDENCY_01=''
	#NON_DEBIAN='false'
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
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	case ${INPUT_METHOD} in
	0 | "") input_method_beautification;;
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
	if [ ! -z "${PANEL_COLOR_PNG}" ];then
	    switch__fcitx5_material_color    
	fi
	press_enter_to_return
    configure_fcitx5_material_color_theme
}
##############
switch__fcitx5_material_color(){
	if [ ! -e "${MATERIAL_COLOR_FOLDER}" ];then
        install_fcitx5_material_color_theme
	fi
    cd ${MATERIAL_COLOR_FOLDER}
	if [ "$(command -v catimg)" ];then
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
delete_fcitx5_material_color_theme(){ 
    echo "是否需要删除该主题？"
	echo "${RED}rm -rv ${MATERIAL_COLOR_FOLDER}${RESET}"
	do_you_want_to_continue
	rm -rv ${MATERIAL_COLOR_FOLDER}
    sed -i 's@^Theme=@#&@' ${FCIITX5_CLASSUI_CONF_FILE}
}
###############
install_fcitx5_material_color_theme(){ 
    #DEPENDENCY_02='fcitx5-material-color'
	#beta_features_quick_install
	#echo '请前往github阅读使用说明'
	#echo 'https://github.com/hosxy/Fcitx5-Material-Color'
if [ ! -e ${MATERIAL_COLOR_FOLDER} ];then
    mkdir -p ${MATERIAL_COLOR_FOLDER}
	git clone --depth=1 https://github.com/hosxy/Fcitx5-Material-Color.git ${MATERIAL_COLOR_FOLDER}
else
    cd ${MATERIAL_COLOR_FOLDER}
	git pull
fi

mkdir -p ${FCIITX5_CLASSUI_CONF_PATH}
	cd ${FCIITX5_CLASSUI_CONF_PATH}
if ! grep -q 'Theme=Material-Color-Pink' 'classicui.conf';then
     write_to_fcitx_classui_conf
fi

	if [ ${HOME} != '/root' ]; then
		echo "正在将${MATERIAL_COLOR_FOLDER}和${FCIITX5_CLASSUI_CONF_PATH}的文件权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${MATERIAL_COLOR_FOLDER} ${FCIITX5_CLASSUI_CONF_PATH}
	fi
}
###########
write_to_fcitx_classui_conf(){ 
	if [ -e classicui.conf ];then
        sed -i 's@^Vertical Candidate List=@#&@' classicui.conf
        sed -i 's@^PerScreenDPI=@#&@' classicui.conf
        sed -i 's@^Theme=@#&@' classicui.conf
	fi
cat >>${FCIITX5_CLASSUI_CONF_FILE}<<-'EOF'
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
install_kimpanel(){ 
	NON_DEBIAN='true'
	DEPENDENCY_02='fcitx5-module-kimpanel'
	beta_features_quick_install
}
#############
install_gnome_shell_extension_kimpanel(){ 
    DEPENDENCY_02='gnome-shell-extension-kimpanel'
	beta_features_quick_install
}
############
check_fcitx5_dict(){ 
if [ ! -d ${FCITX5_DIICT_PATH} ];then
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
download_dict_model_01(){ 
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
outloudvi_fcitx5_moegirl_dict(){ 
     DICT_NAME='moegirl.dict'
     GREP_NAME='fcitx5-pinyin-moegirl'
     download_dict_model_01
	 echo 'https://github.com/outloudvi/fcitx5-pinyin-moegirl'
}
#################
felixonmars_fcitx5_wiki_dict(){ 
     DICT_NAME='zhwiki.dict'
     GREP_NAME='fcitx5-pinyin-zhwiki'
     download_dict_model_01
	 echo 'https://github.com/felixonmars/fcitx5-pinyin-zhwiki'
}
#################
install_fcitx5(){ 
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
install_fcitx5_rime(){ 
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
	NON_DEBIAN='false'
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
			"1" "fcitx-FAQ:常见问题与疑难诊断" \
			"2" "fcitx5(软件与词库)" \
			"3" "google谷歌拼音(引擎fork自Android版)" \
			"4" "sogou(搜狗拼音)" \
			"5" "iflyime(讯飞语音+拼音+五笔)" \
			"6" "rime中州韻(擊響中文之韻)" \
			"7" "baidu(百度输入法)" \
			"8" "libpinyin(提供智能整句输入算法核心)" \
			"9" "sunpinyin(基于统计学语言模型)" \
			"10" "fcitx-云拼音模块" \
			"11" "uim(Universal Input Method)" \
			"0" "Return to previous menu 返回上级菜单" \
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
	11) install_uim_pinyin ;;
	esac
	###############
	configure_arch_fcitx
	press_enter_to_return
	install_pinyin_input_method
}
########################
##################
tmoe_fcitx_faq() {
	NON_DEBIAN='false'
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
		"0" "Return to previous menu 返回上级菜单" \
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
	5) FCITX_ENV_FILE="${HOME}/.xprofile"
      edit_fcitx_env_file
		;;
	6) FCITX_ENV_FILE="${HOME}/.pam_environment"
      edit_fcitx_env_file
		;;
	7) FCITX_ENV_FILE="/etc/environment"
      edit_fcitx_env_file
		;;
	esac
	##########################
	press_enter_to_return
	tmoe_fcitx_faq
}
#################
edit_fcitx_env_file(){ 
        if [ $(command -v editor) ]; then
			editor ${FCITX_ENV_FILE}
		else
		    nano ${FCITX_ENV_FILE}
		fi
	chown ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${FCITX_ENV_FILE}
}
###########
remove_ibus_im() {
	${PACKAGES_REMOVE_COMMAND} ibus
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
	NON_DEBIAN='true'
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
		#check_current_user_name_and_group
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
		${PACKAGES_INSTALL_COMMAND} unzip
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
		beta_features
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
	echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_02} ${RESET}"
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
		beta_features
	fi
}
###################
install_debian_sogou_pinyin() {
	DEPENDENCY_02="sogouimebs"
	###################
	if [ -e "/usr/share/fcitx-sogoupinyin" ] || [ -e "/usr/share/sogouimebs/" ]; then
		install_pkg_warning
	fi
	if [ "${ARCH_TYPE}" = "i386" ]; then
		GREP_NAME='sogoupinyin'
		LATEST_DEB_REPO='http://archive.kylinos.cn/kylin/KYLIN-ALL/pool/main/s/sogoupinyin/'
	else
		GREP_NAME='sogouimebs'
		LATEST_DEB_REPO='http://archive.ubuntukylin.com/ukui/pool/main/s/sogouimebs/'
	fi
	download_ubuntu_kylin_deb_file_model_02
	#download_ubuntu_kylin_deb_file
	echo "若安装失败，则请前往官网手动下载安装。"
	echo 'url: https://pinyin.sogou.com/linux/'
	#rm -fv sogou_pinyin.deb
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
fcitx5_config_file(){ 
	if [ ! -e "${FCITX5_FILE}" ]; then
		echo '' >> ${FCITX5_FILE}
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
fix_fcitx5_permissions(){ 
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
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/non-free/i/iflyime/'
		GREP_NAME="${ARCH_TYPE}"
		grep_deb_comman_model_01
	else
		arch_does_not_support
		echo "请在更换x64架构的设备后，再来尝试"
	fi
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
install_gnome_system_monitor() {
	DEPENDENCY_01=''
	DEPENDENCY_02="gnome-system-monitor"
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
install_docker_portainer() {
	command -v docker >/dev/null
	if [ "$?" != "0" ]; then
		echo "检测到您尚未安装docker，请先安装docker"
		press_enter_to_return
		install_container_and_virtual_machine
	fi
	TARGET_PORT=$(whiptail --inputbox "请设定访问端口号,例如39080,默认内部端口为9000\n Please enter the port." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ] || [ -z "${TARGET_PORT}" ]; then
		echo "端口无效，请重新输入"
		press_enter_to_return
		install_container_and_virtual_machine
	fi
	service docker start 2>/dev/null || systemctl start docker
	docker stop portainer 2>/dev/null
	docker rm portainer 2>/dev/null
	#docker rmi portainer/portainer:latest 2>/dev/null
	docker pull portainer/portainer:latest
	docker run -d -p ${TARGET_PORT}:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer:latest
}
#####################
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
	fi
	DEPENDENCY_02=""
	DEPENDENCY_01="docker"
	#apt remove docker docker-engine docker.io
	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		DEPENDENCY_01="docker-ce"
		debian_add_docker_gpg
	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		curl -Lv -o /etc/yum.repos.d/docker-ce.repo "https://download.docker.com/linux/${REDHAT_DISTRO}/docker-ce.repo"
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
	apt show ./.Oracle_VIRTUAL_BOX.deb
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
		beta_features_quick_insta
		#linux-headers
	fi
	DEPENDENCY_02="virtualbox-qt"
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
	fi
	echo "您可以输modprobe vboxdrv vboxnetadp vboxnetflt来加载内核模块"
	beta_features_quick_install
	if [ "${LINUX_DISTRO}" = 'arch' ]; then
		echo "usermod -G vboxusers -a ${CURRENT_USER_NAME}"
		do_you_want_to_continue
		usermod -G vboxusers -a ${CURRENT_USER_NAME}
	fi
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
install_typora() {
	DEPENDENCY_01="typora"
	DEPENDENCY_02=""
	NON_DEBIAN='true'
	beta_features_quick_install
	cd /tmp
	GREP_NAME='typora'
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		LATEST_DEB_REPO='http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/t/typora/'
		download_debian_cn_repo_deb_file_model_01
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'typora.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/t/typora/typora_0.9.67-1_amd64.deb'
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		LATEST_DEB_REPO='https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/non-free/t/typora/'
		download_tuna_repo_deb_file_model_03
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'typora.deb' 'https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/non-free/t/typora/typora_0.9.22-1_i386.deb'
	else
		arch_does_not_support
	fi
	#apt show ./typora.deb
	#apt install -y ./typora.deb
	#rm -vf ./typora.deb
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
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o WPSoffice.deb "${LatestWPSLink}"
		apt show ./WPSoffice.deb
		apt install -y ./WPSoffice.deb

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="wps-office-cn"
		beta_features_quick_install
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		LatestWPSLink=$(curl -L https://linux.wps.cn/ | grep '\.rpm' | grep -i "$(uname -m)" | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o WPSoffice.rpm "https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9505/wps-office-11.1.0.9505-1.x86_64.rpm"
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
		echo "检测到您当前使用的是${BLUE}proot容器${RESET}，不建议您安装${RED}dolphion${RESET}"
		echo "dolphion在当前环境下可能无法正常启动"
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
		tmoe_file_browser_app_menu
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
	################
	beta_features_quick_install
	if [ -e "/opt/wechat/electronic-wechat" ] || [ "$(command -v electronic-wechat)" ]; then
		#beta_features_install_completed
		echo "按回车键重新安装"
		echo "Press enter to reinstall it?"
		do_you_want_to_continue
	fi
	non_debian_function
	cd /tmp
	GREP_NAME='electronic-wechat'
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		LATEST_DEB_REPO='http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/e/electronic-wechat/'
		download_debian_cn_repo_deb_file_model_01
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'electronic-wechat.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/e/electronic-wechat/electronic-wechat_2.0~repack0~debiancn0_amd64.deb'
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'electronic-wechat.deb' 'http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/electronic-wechat_2.0.1_amd64.deb'
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		LATEST_DEB_REPO='http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/'
		download_ubuntu_kylin_deb_file_model_02
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'electronic-wechat.deb' 'http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/electronic-wechat_2.0.1_i386.deb'
	elif [ "${ARCH_TYPE}" = "arm64" ]; then
		LATEST_DEB_REPO='http://archive.kylinos.cn/kylin/KYLIN-ALL/pool/main/e/electronic-wechat/'
		download_ubuntu_kylin_deb_file_model_02
		#LATEST_VERSION=$(curl -L "${REPO_URL}" | grep 'arm64.deb' | tail -n 1 | cut -d '=' -f 5 | cut -d '"' -f 2)
		#LATEST_URL="${REPO_URL}${LATEST_VERSION}"
		#echo ${LATEST_URL}
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'electronic-wechat.deb' "${LATEST_URL}"
	else
		arch_does_not_support
	fi
	#apt show ./electronic-wechat.deb
	#apt install -y ./electronic-wechat.deb
	#rm -vf ./electronic-wechat.deb
	if [ "${ARCH_TYPE}" = "arm64" ]; then
		debian_install_electron
		creat_electron_wechat_desktop_link
		cat <<-EOF
			electronic-wechat已经停止维护，访问项目主页了解更多详情。
			https://github.com/geeeeeeeeek/electronic-wechat
			tightvnc可能无法正常启动本应用，
			您可以使用x11vnc来启动。
		EOF
	fi
	beta_features_install_completed

}
#############
creat_electron_wechat_desktop_link() {
	cd /usr/share/applications
	sed -i 's@/opt/wechat/electronic-wechat@&.sh@' electronic-wechat.desktop
	cd /opt/wechat/
	if [ "${HOME}" = '/root' ]; then
		cat >electronic-wechat.sh <<-'EOF'
			#!/bin/bash
			export ELECTRON_IS_DEV=0
			exec electron /opt/wechat/resources/app.asar --no-sandbox "$@"
		EOF
	else
		cat >electronic-wechat.sh <<-'EOF'
			#!/bin/bash
			export ELECTRON_IS_DEV=0
			exec electron /opt/wechat/resources/app.asar "$@"
		EOF
	fi
	chmod +x electronic-wechat.sh
}
###########
install_gnome_software() {
	DEPENDENCY_01="gnome-software"
	DEPENDENCY_02=""
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
	press_enter_to_return
	tmoe_other_app_menu
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
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="discover"
	fi
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
install_fbreader() {
	DEPENDENCY_01="fbreader"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
################
################
personal_netdisk() {
	WHICH_NETDISK=$(whiptail --title "FILE SHARE SERVER" --menu "你想要使用哪个软件来共享文件呢" 11 50 3 \
		"1" "Filebrowser:简单轻量的个人网盘" \
		"2" "Nginx WebDAV:比ftp更适合用于传输流媒体" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${WHICH_NETDISK}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) install_filebrowser ;;
	2) install_nginx_webdav ;;
	esac
	##################
	press_enter_to_return
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
	case "${TMOE_OPTION}" in
	0 | "") personal_netdisk ;;
	1)
		pkill nginx
		service nginx stop 2>/dev/null || systemctl stop nginx
		nginx_onekey
		;;
	2) nginx_add_admin ;;
	3) nginx_logs ;;
	4) nginx_webdav_port ;;
	5) nginx_port ;;
	6) nginx_systemd ;;
	7)
		echo "正在停止服务进程..."
		echo "Stopping..."
		pkill nginx
		service nginx stop 2>/dev/null || systemctl stop nginx
		service nginx status || systemctl status nginx
		;;
	8) nginx_webdav_root_dir ;;
	9)
		echo "正在停止nginx进程..."
		echo "Stopping nginx..."
		pkill nginx
		service nginx stop 2>/dev/null || systemctl stop nginx
		nginx_reset
		;;
	10)
		remove_nginx
		;;
	esac
	##############################
	press_enter_to_return
	configure_nginx_webdav
}
##############
remove_nginx() {
	pkill nginx
	echo "正在停止nginx进程..."
	echo "Stopping nginx..."
	service nginx stop 2>/dev/null || systemctl stop nginx
	rm -fv /etc/nginx/conf.d/webdav.conf
	echo "${YELLOW}已删除webdav配置文件,${RESET}"
	echo "是否继续卸载nginx?"
	echo "您正在执行危险操作，卸载nginx将导致您部署的所有网站无法访问！！！"
	echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
	service nginx restart || systemctl restart nginx
	RETURN_TO_WHERE='configure_nginx_webdav'
	do_you_want_to_continue
	service nginx stop || systemctl stop nginx
	${PACKAGES_REMOVE_COMMAND} nginx nginx-extras
}
###################
nginx_onekey() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ] || [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您处于${BLUE}chroot/proot容器${RESET}环境下，部分功能可能出现异常。"
		echo "部分系统可能会出现failed，但仍能正常连接。"
		CHROOT_STATUS='1'
	fi
	echo "本服务依赖于软件源仓库的nginx,可能无法与宝塔等第三方面板的nginx相互兼容"
	echo "若80和443端口被占用，则有可能导致nginx启动失败，请修改nginx为1024以上的高位端口。"
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
	if [ -e "${HOME}/sd" ]; then
		ln -sf ${HOME}/sd /media/
	fi

	if [ -e "${HOME}/tf" ]; then
		ln -sf ${HOME}/tf /media/
	fi

	if [ -e "${HOME}/termux" ]; then
		ln -sf ${HOME}/termux /media/
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
		press_enter_to_return
		nginx_onekey
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		press_enter_to_return
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
	press_enter_to_return
	configure_nginx_webdav
	#此处的返回步骤并非多余
}
############
nginx_restart() {
	cd /etc/nginx/conf.d/
	NGINX_WEBDAV_PORT=$(cat webdav.conf | grep listen | head -n 1 | cut -d ';' -f 1 | awk -F ' ' '$0=$NF')
	service nginx restart 2>/dev/null || systemctl restart nginx
	if [ "$?" != "0" ]; then
		/etc/init.d/nginx reload
	fi
	service nginx status 2>/dev/null || systemctl status nginx
	if [ "$?" = "0" ]; then
		echo "您可以输${YELLOW}service nginx stop${RESET}来停止进程"
	else
		echo "您可以输${YELLOW}/etc/init.d/nginx stop${RESET}来停止进程"
	fi
	cat /var/log/nginx/webdav.error.log | tail -n 10
	cat /var/log/nginx/webdav.access.log | tail -n 10
	echo "正在为您启动nginx服务，本机默认访问地址为localhost:${NGINX_WEBDAV_PORT}"
	echo The LAN address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${NGINX_WEBDAV_PORT}
	echo The WAN address 外网地址 $(curl -sL ip.cip.cc | head -n 1):${NGINX_WEBDAV_PORT}
	echo "${YELLOW}您可以使用文件管理器或浏览器来打开WebDAV访问地址${RESET}"
	echo "Please use your browser to open the access address"
}
#############
nginx_add_admin() {
	TARGET_USERNAME=$(whiptail --inputbox "您正在重置webdav访问用户,请输入新用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "用户名无效，操作取消"
		press_enter_to_return
		configure_nginx_webdav
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		press_enter_to_return
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
		press_enter_to_return
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
		press_enter_to_return
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
		press_enter_to_return
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
				aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o .filebrowser.tar.gz 'https://github.com/filebrowser/filebrowser/releases/download/v2.1.0/linux-armv7-filebrowser.tar.gz'
			elif [ "${ARCH_TYPE}" = "i386" ]; then
				aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o .filebrowser.tar.gz 'https://github.com/filebrowser/filebrowser/releases/download/v2.1.0/linux-386-filebrowser.tar.gz'
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
		service filebrowser stop 2>/dev/null || systemctl stop filebrowser
		filebrowser_onekey
	fi
	##############################
	if [ "${TMOE_OPTION}" == '2' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null || systemctl stop filebrowser
		filebrowser_add_admin
	fi
	##############################
	if [ "${TMOE_OPTION}" == '3' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null || systemctl stop filebrowser
		filebrowser_port
	fi
	##############################
	if [ "${TMOE_OPTION}" == '4' ]; then
		filebrowser_logs
	fi
	##############################
	if [ "${TMOE_OPTION}" == '5' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null || systemctl stop filebrowser
		filebrowser_language
	fi
	##############################
	if [ "${TMOE_OPTION}" == '6' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null || systemctl stop filebrowser
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
		service filebrowser stop 2>/dev/null || systemctl stop filebrowser
		service filebrowser status 2>/dev/null || systemctl status filebrowser
	fi
	##############################
	if [ "${TMOE_OPTION}" == '9' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null || systemctl stop filebrowser
		filebrowser_reset
	fi
	##############################
	if [ "${TMOE_OPTION}" == '10' ]; then
		RETURN_TO_WHERE='configure_filebrowser'
		do_you_want_to_continue
		pkill filebrowser
		systemctl disable filebrowser
		service filebrowser stop 2>/dev/null || systemctl stop filebrowser
		rm -fv /usr/local/bin/filebrowser
		rm -fv /etc/systemd/system/filebrowser.service
		rm -fv /etc/filebrowser.db
	fi
	########################################
	if [ -z "${TMOE_OPTION}" ]; then
		personal_netdisk
	fi
	###########
	press_enter_to_return
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
		press_enter_to_return
		filebrowser_onekey
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定管理员密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		press_enter_to_return
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
	press_enter_to_return
	configure_filebrowser
	#此处的返回步骤并非多余
}
############
filebrowser_restart() {
	FILEBROWSER_PORT=$(cat /etc/filebrowser.db | grep -a port | sed 's@,@\n@g' | grep -a port | head -n 1 | cut -d ':' -f 2 | cut -d '"' -f 2)
	service filebrowser restart 2>/dev/null || systemctl restart filebrowser
	if [ "$?" != "0" ]; then
		pkill filebrowser
		nohup /usr/local/bin/filebrowser -d /etc/filebrowser.db 2>&1 >/var/log/filebrowser.log &
		cat /var/log/filebrowser.log | tail -n 20
	fi
	service filebrowser status 2>/dev/null || systemctl status filebrowser
	if [ "$?" = "0" ]; then
		echo "您可以输${YELLOW}service filebrowser stop${RESET}来停止进程"
	else
		echo "您可以输${YELLOW}pkill filebrowser${RESET}来停止进程"
	fi
	echo "正在为您启动filebrowser服务，本机默认访问地址为localhost:${FILEBROWSER_PORT}"
	echo The LAN address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${FILEBROWSER_PORT}
	echo The WAN address 外网地址 $(curl -sL ip.cip.cc | head -n 1):${FILEBROWSER_PORT}
	echo "${YELLOW}请使用浏览器打开上述地址${RESET}"
	echo "Please use your browser to open the access address"
}
#############
filebrowser_add_admin() {
	pkill filebrowser
	service filebrowser stop 2>/dev/null || systemctl stop filebrowser
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
		press_enter_to_return
		configure_filebrowser
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定管理员密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		press_enter_to_return
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
		press_enter_to_return
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
	# cat /var/log/filebrowser.log | less -meQ
	#else
	# cat /var/log/filebrowser.log
	#fi

}
#################
filebrowser_language() {
	TARGET_LANG=$(whiptail --inputbox "Please enter the language format, for example en,zh-cn" 12 50 --title "LANGUAGE" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		press_enter_to_return
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
		press_enter_to_return
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
#######################################################################
