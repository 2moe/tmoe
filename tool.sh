#!/usr/bin/env bash
############################################
main() {
	check_linux_distro
	check_architecture
	gnu_linux_env
	source ${TMOE_TOOL_DIR}/environment.sh 2>/dev/null
	check_current_user_name_and_group 2>/dev/null
	case "$1" in
	i | -i) tmoe_linux_tool_menu ;;
	aria2) tmoe_aria2_manager ;;
	docker) tmoe_docker_menu ;;
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
		if [ -e "${TMOE_TOOL_DIR}/sources/mirror.sh" ]; then
			source ${TMOE_TOOL_DIR}/sources/mirror.sh
		elif [ -e "/tmp/.tmoe-linux-mirror.sh" ]; then
			source /tmp/.tmoe-linux-mirror.sh
		else
			curl -Lv -o /tmp/.tmoe-linux-mirror.sh "https://raw.githubusercontent.com/2moe/tmoe-linux/master/tools/sources/mirror.sh" || wget -O /tmp/.tmoe-linux-mirror.sh "https://raw.githubusercontent.com/2moe/tmoe-linux/master/tools/sources/mirror.sh"
			chmod +x /tmp/.tmoe-linux-mirror.sh
			source /tmp/.tmoe-linux-mirror.sh
		fi
		;;
	up* | -u*)
		tmoe_linux_tool_upgrade
		;;
	passwd | -passwd)
		source ${TMOE_TOOL_DIR}/gui/gui.sh --vncpasswd
		check_win10x_icon
		;;
	h | -h | --help)
		cat <<-'EOF'
			-ppa     --添加ppa软件源(add ppa source)   
			-u       --更新(update tmoe-linux tool)
			-m       --切换镜像源
			-tuna    --切换为tuna源
			file     --运行文件浏览器(run filebrowser)
			qemu     --x64 qemu虚拟机管理
			docker  --tmoe docker tool
			aria2   --tmoe_aria2_manager
		EOF
		;;
	file | filebrowser)
		source ${TMOE_TOOL_DIR}/filebrowser.sh -r
		;;
	tuna | -tuna | --tuna | t | -t)
		SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn'
		if [ -e "${TMOE_TOOL_DIR}/sources/mirror.sh" ]; then
			source ${TMOE_TOOL_DIR}/sources/mirror.sh --autoswitch
		elif [ -e "/tmp/.tmoe-linux-mirror.sh" ]; then
			source /tmp/.tmoe-linux-mirror.sh --autoswitch
		else
			curl -Lvo /tmp/.tmoe-linux-mirror.sh "https://raw.githubusercontent.com/2moe/tmoe-linux/master/tools/sources/mirror.sh"
			chmod +x /tmp/.tmoe-linux-mirror.sh
			source /tmp/.tmoe-linux-mirror.sh --autoswitch
		fi
		;;
	ppa* | -ppa*)
		source ${TMOE_TOOL_DIR}/sources/mirror.sh -p
		;;
	*)
		check_root
		check_dependencies
		tmoe_locale_settings
		check_tmoe_git_folder
		tmoe_linux_tool_menu
		;;
	esac
}
################
check_ps_command() {
	ps &>/dev/null
	if [ "$?" != '0' ]; then
		TMOE_PROOT='no'
	fi
}
################
gnu_linux_env() {
	if [ -z "${TMOE_PROOT}" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			TMOE_PROOT='true'
		elif [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
			TMOE_PROOT='false'
		else
			check_ps_command
		fi
	fi
	if [ -z ${TMPDIR} ]; then
		TMPDIR=/tmp
		mkdir -p ${TMPDIR}
	fi
	check_release_version
	TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
	if [ ! -e "/usr/local/bin" ]; then
		mkdir -p /usr/local/bin
	fi
	TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
	TMOE_TOOL_DIR="${TMOE_GIT_DIR}/tools"
	TMOE_OPT_BIN_DIR="${TMOE_TOOL_DIR}/sources/opt-bin"
	TMOE_GIT_URL='github.com/2moe/tmoe-linux'
	APPS_LNK_DIR='/usr/share/applications'
	CONFIG_FOLDER="${HOME}/.config/tmoe-linux"
}
############
set_terminal_color() {
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
######################
check_release_version() {
	if [ "${LINUX_DISTRO}" = "Android" ]; then
		OSRELEASE="Android"
	elif grep -q 'NAME=' /etc/os-release; then
		OSRELEASE=$(cat /etc/os-release | grep -v 'PRETTY' | grep 'NAME=' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
	elif grep -q 'ID=' /etc/os-release; then
		OSRELEASE=$(cat /etc/os-release | grep -v 'VERSION' | grep 'ID=' | head -n 1 | cut -d '=' -f 2)
	else
		OSRELEASE=LINUX
	fi
}
##############
check_win10x_icon() {
	if [ -e "/usr/share/icons/We10X" ]; then
		dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s We10X
	fi
}
##########
check_mouse_cursor() {
	if [ -e "/usr/share/icons/breeze" ]; then
		dbus-launch xfconf-query -c xsettings -t string -np /Gtk/CursorThemeName -s breeze_cursors 2>/dev/null
	elif [ -e "/usr/share/icons/Breeze-Adapta-Cursor" ]; then
		dbus-launch xfconf-query -c xsettings -t string -np /Gtk/CursorThemeName -s "Breeze-Adapta-Cursor" 2>/dev/null
	fi
}
#############
press_enter_to_continue() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}继续${RESET}"
	read
}
#############################################
check_root() {
	if [ "$(id -u)" != "0" ]; then
		export PATH=${PATH}:/usr/sbin:/sbin
		if [ -e "${TMOE_GIT_DIR}/tool.sh" ]; then
			sudo -E bash ${TMOE_GIT_DIR}/tool.sh || su -c "bash ${TMOE_GIT_DIR}/tool.sh"
		else
			if [ $(command -v curl) ]; then
				sudo -E bash -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)" || su -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
			elif [ $(command -v aria2c) ]; then
				aria2c --allow-overwrite=true -o /tmp/.tmoe-linux-tool.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh
				su -c "$(bash /tmp/.tmoe-linux-tool.sh)"
			else
				su -c "$(wget -qO- https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
			fi
		fi
		exit 0
	fi
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
	TRUE_ARCH_TYPE=${ARCH_TYPE}
}
#####################
tmoe_locale_settings() {
	TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
	if [ -e "${TMOE_LOCALE_FILE}" ]; then
		TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
		TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
		TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
	else
		TMOE_LANG="en_US.UTF-8"
		TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
		TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
	fi

	case "${LINUX_DISTRO}" in
	debian)
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
		;;
	esac

	if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
		cd /etc
		sed -i "s/^#.*${TMOE_LANG} UTF-8/${TMOE_LANG} UTF-8/" locale.gen
		if ! grep -qi "^${TMOE_LANG_HALF}" "locale.gen"; then
			echo '' >>locale.gen
			#sed -i 's@^@#@g' locale.gen 2>/dev/null
			#sed -i 's@##@#@g' locale.gen 2>/dev/null
			sed -i "$ a ${TMOE_LANG} UTF-8" locale.gen
		fi
		locale-gen ${TMOE_LANG} 2>/dev/null
	fi
}
#####################
check_linux_distro() {
	set_terminal_color
	if grep -Eq 'debian|ubuntu|deepin' "/etc/os-release"; then
		LINUX_DISTRO='debian'
		TMOE_INSTALLATON_COMMAND='apt install -y'
		TMOE_REMOVAL_COMMAND='apt purge -y'
		TMOE_UPDATE_COMMAND='apt update'
		if grep -q 'ubuntu' /etc/os-release; then
			DEBIAN_DISTRO='ubuntu'
		elif [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
			DEBIAN_DISTRO='kali'
		elif grep -q 'deepin' /etc/os-release; then
			DEBIAN_DISTRO='deepin'
		fi
		###################
	elif grep -Eq "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		LINUX_DISTRO='openwrt'
		TMOE_UPDATE_COMMAND='opkg update'
		TMOE_INSTALLATON_COMMAND='opkg install'
		TMOE_REMOVAL_COMMAND='opkg remove'
		##################
	elif grep -Eqi "Fedora|CentOS|Red Hat|redhat" "/etc/os-release"; then
		LINUX_DISTRO='redhat'
		TMOE_UPDATE_COMMAND='dnf update'
		TMOE_INSTALLATON_COMMAND='dnf install -y --skip-broken'
		TMOE_REMOVAL_COMMAND='dnf remove -y'
		if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHAT_DISTRO='centos'
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHAT_DISTRO='fedora'
		fi
		###################
	elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" "/etc/os-release"; then
		LINUX_DISTRO='alpine'
		TMOE_UPDATE_COMMAND='apk update'
		TMOE_INSTALLATON_COMMAND='apk add'
		TMOE_REMOVAL_COMMAND='apk del'
		######################
	elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
		LINUX_DISTRO='arch'
		TMOE_UPDATE_COMMAND='pacman -Syy'
		TMOE_INSTALLATON_COMMAND='pacman -Syu --noconfirm'
		TMOE_REMOVAL_COMMAND='pacman -Rsc'
		######################
	elif grep -Eq "gentoo|funtoo" "/etc/os-release"; then
		LINUX_DISTRO='gentoo'
		TMOE_INSTALLATON_COMMAND='emerge -avk'
		TMOE_REMOVAL_COMMAND='emerge -C'
		########################
	elif grep -qi 'suse' '/etc/os-release'; then
		LINUX_DISTRO='suse'
		TMOE_INSTALLATON_COMMAND='zypper in -y'
		TMOE_REMOVAL_COMMAND='zypper rm'
		########################
	elif [ "$(cat /etc/issue | cut -c 1-4)" = "Void" ]; then
		LINUX_DISTRO='void'
		export LANG='en_US.UTF-8'
		TMOE_INSTALLATON_COMMAND='xbps-install -S -y'
		TMOE_REMOVAL_COMMAND='xbps-remove -R'
		#########################
	elif grep -Eq "Slackware" '/etc/os-release'; then
		LINUX_DISTRO='slackware'
		TMOE_UPDATE_COMMAND='slackpkg update'
		TMOE_INSTALLATON_COMMAND='slackpkg install'
		TMOE_REMOVAL_COMMAND='slackpkg remove'
		#########################
	elif [ "$(uname -o)" = 'Android' ]; then
		echo "${RED}不支持${RESET}${BLUE}Android${RESET}系统！"
		exit 1
	fi
}
#############################
check_dependencies() {
	DEPENDENCIES=""
	case "${LINUX_DISTRO}" in
	debian)
		if [ ! $(command -v aptitude) ]; then
			DEPENDENCIES="${DEPENDENCIES} aptitude"
		fi
		;;
	esac

	if [ ! $(command -v aria2c) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} net-misc/aria2" ;;
		*) DEPENDENCIES="${DEPENDENCIES} aria2" ;;
		esac
	fi

	if [ ! $(command -v bash) ]; then
		DEPENDENCIES="${DEPENDENCIES} bash"
	fi

	if [ ! $(command -v busybox) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} sys-apps/busybox" ;;
		redhat)
			if [ "${REDHAT_DISTRO}" = "fedora" ]; then
				DEPENDENCIES="${DEPENDENCIES} busybox"
			fi
			;;
		*) DEPENDENCIES="${DEPENDENCIES} busybox" ;;
		esac
	fi
	#####################
	if [ ! $(command -v catimg) ] && [ ! -e "${TMOE_LINUX_DIR}/not_install_catimg" ]; then
		case "${LINUX_DISTRO}" in
		debian)
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
			;;
		arch | void) DEPENDENCIES="${DEPENDENCIES} catimg" ;;
		esac
		if [ "${REDHAT_DISTRO}" = "fedora" ]; then
			DEPENDENCIES="${DEPENDENCIES} catimg"
		fi
	fi

	if [ ! $(command -v curl) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} net-misc/curl" ;;
		*) DEPENDENCIES="${DEPENDENCIES} curl" ;;
		esac
	fi
	######################
	if [ ! $(command -v fc-cache) ]; then
		case "${LINUX_DISTRO}" in
		debian) DEPENDENCIES="${DEPENDENCIES} fontconfig" ;;
		esac
	fi
	###################
	#manjaro基础容器里无grep
	if [ ! $(command -v grep) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) ;;
		*) DEPENDENCIES="${DEPENDENCIES} grep" ;;
		esac
	fi
	####################
	if [ ! $(command -v git) ]; then
		case "${LINUX_DISTRO}" in
		openwrt) DEPENDENCIES="${DEPENDENCIES} git git-http" ;;
		gentoo) DEPENDENCIES="${DEPENDENCIES} dev-vcs/git" ;;
		*) DEPENDENCIES="${DEPENDENCIES} git" ;;
		esac
	fi
	########################
	if [ ! $(command -v less) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} sys-apps/less" ;;
		*) DEPENDENCIES="${DEPENDENCIES} less" ;;
		esac
	fi
	####################
	if [ ! $(command -v mkfontscale) ]; then
		case "${LINUX_DISTRO}" in
		debian) DEPENDENCIES="${DEPENDENCIES} xfonts-utils" ;;
		arch) DEPENDENCIES="${DEPENDENCIES} xorg-mkfontscale" ;;
		esac
	fi
	################
	if [ ! $(command -v nano) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) ;;
		*) DEPENDENCIES="${DEPENDENCIES} nano" ;;
		esac
	fi
	#####################
	if [ ! $(command -v xz) ]; then
		case "${LINUX_DISTRO}" in
		debian) DEPENDENCIES="${DEPENDENCIES} xz-utils" ;;
		gentoo) DEPENDENCIES="${DEPENDENCIES} app-arch/xz-utils" ;;
		*) DEPENDENCIES="${DEPENDENCIES} xz" ;;
		esac
	fi

	if [ ! $(command -v pkill) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} sys-process/procps" ;;
		*) DEPENDENCIES="${DEPENDENCIES} procps" ;;
		esac
	fi
	#####################
	if [ ! $(command -v sudo) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) ;;
		*) DEPENDENCIES="${DEPENDENCIES} sudo" ;;
		esac
	fi
	###################
	#centos8基础容器里无tar
	if [ ! $(command -v tar) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) ;;
		*) DEPENDENCIES="${DEPENDENCIES} tar" ;;
		esac
	fi
	#####################
	if [ "$(command -v whiptail)" = "/data/data/com.termux/files/usr/bin/whiptail" ] || [ ! $(command -v whiptail) ]; then
		case "${LINUX_DISTRO}" in
		debian) DEPENDENCIES="${DEPENDENCIES} whiptail" ;;
		arch) DEPENDENCIES="${DEPENDENCIES} libnewt" ;;
		gentoo) DEPENDENCIES="${DEPENDENCIES} dev-libs/newt" ;;
		openwrt) DEPENDENCIES="${DEPENDENCIES} dialog" ;;
		*) DEPENDENCIES="${DEPENDENCIES} newt" ;;
		esac
	fi
	##############
	if [ ! $(command -v wget) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} net-misc/wget" ;;
		*) DEPENDENCIES="${DEPENDENCIES} wget" ;;
		esac
	fi
	##############
	if [ ! -z "${DEPENDENCIES}" ]; then
		cat <<-EOF
			正在${YELLOW}安装${RESET}相关${GREEN}软件包${RESET}及其${BLUE}依赖...${RESET}
			${GREEN}${TMOE_INSTALLATON_COMMAND}${BLUE}${DEPENDENCIES}${RESET}
			如需${BOLD}${RED}卸载${RESET}${RESET}，请${YELLOW}手动${RESET}输${RED}${TMOE_REMOVAL_COMMAND}${RESET}${BLUE}${DEPENDENCIES}${RESET}
		EOF
		case "${LINUX_DISTRO}" in
		debian)
			${TMOE_UPDATE_COMMAND}
			${TMOE_INSTALLATON_COMMAND} ${DEPENDENCIES} || ${TMOE_INSTALLATON_COMMAND} git wget curl whiptail aria2 xz-utils nano aptitude sudo less
			#创建文件夹防止aptitude报错
			mkdir -p /run/lock /var/lib/aptitude
			touch /var/lib/aptitude/pkgstates
			;;
		alpine | openwrt | slackware)
			${TMOE_UPDATE_COMMAND}
			${TMOE_INSTALLATON_COMMAND} ${DEPENDENCIES}
			;;
		arch | gentoo | redhat | suse | void) ${TMOE_INSTALLATON_COMMAND} ${DEPENDENCIES} ;;
		*)
			apt update
			${TMOE_INSTALLATON_COMMAND} ${DEPENDENCIES}
			apt install -y ${DEPENDENCIES} || port install ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES} || pacman -Syu ${DEPENDENCIES}
			;;
		esac
	fi
	################
	if [ ! $(command -v catimg) ] && [ ! -e "${TMOE_LINUX_DIR}/not_install_catimg" ]; then
		touch ${TMOE_LINUX_DIR}/not_install_catimg
		case "${LINUX_DISTRO}" in
		debian)
			CATIMGlatestVersion="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/' | grep ${ARCH_TYPE} | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '_' -f 2)"
			cd /tmp
			wget --no-check-certificate -O 'catimg.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/catimg_${CATIMGlatestVersion}_${ARCH_TYPE}.deb"
			apt install -y ./catimg.deb
			rm -f catimg.deb
			;;
		esac
	fi
	################
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
			echo ${TMOE_INSTALLATON_COMMAND} ${DEPENDENCY_01}
			${TMOE_INSTALLATON_COMMAND} ${DEPENDENCY_01}
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
	CurrentLANG=${LANG}
	if [ ! $(echo ${LANG} | grep -E 'UTF-8|UTF8') ]; then
		export LANG=C.UTF-8
	fi
}
####################################################
git_clone_tmoe_linux_repo() {
	if [ ! -e "${TMOE_LINUX_DIR}" ]; then
		mkdir -p ${TMOE_LINUX_DIR}
	fi
	git clone -b master --depth=1 https://github.com/2moe/tmoe-linux.git ${TMOE_GIT_DIR}
}
#################
do_you_want_to_git_clone_tmoe_linux_repo() {
	echo "Do you want to ${GREEN}git clone${RESET} this repo to ${BLUE}${TMOE_GIT_DIR}${RESET}?"
	echo "您需要克隆本項目倉庫方能繼續使用"
	#RETURN_TO_WHERE='exit 1'
	#do_you_want_to_continue
	press_enter_to_continue
	git_clone_tmoe_linux_repo
}
#################
check_tmoe_git_folder_00() {
	if [ $(command -v git) ]; then
		check_tmoe_git_folder
	fi
}
####################
check_tmoe_git_folder() {
	if [ ! -e ${TMOE_GIT_DIR}/.git ]; then
		echo 'https://gitee.com/mo2/linux'
		case ${TMOE_PROOT} in
		true | false) git_clone_tmoe_linux_repo ;;
		*) do_you_want_to_git_clone_tmoe_linux_repo ;;
		esac
		source ${TMOE_TOOL_DIR}/environment.sh
		check_current_user_name_and_group
	fi
}
###########################
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
#######################
tmoe_linux_tool_menu() {
	IMPORTANT_TIPS=""
	#窗口大小20 50 7
	TMOE_OPTION=$(
		whiptail --title "Tmoe-linux running on ${OSRELEASE}(202008)" --menu "Type 'debian-i' to start this tool.\nPlease use the enter and arrow keys to operate." 0 50 0 \
			"1" "🍭 GUI:图形界面(桌面,WM,登录管理器)" \
			"2" "🥝 Software center:软件(浏览器,游戏,影音)" \
			"3" "🌈 Desktop beautification:桌面美化(主题)" \
			"4" "🌌 vnc/x/rdp:远程桌面" \
			"5" "📺 Download video:解析视频链接(bili,Y2B)" \
			"6" "🐳 docker:开源的应用容器引擎" \
			"7" "🍧 *°▽°*Update tmoe-linux tool(更新本工具)" \
			"8" "🍩 FAQ:常见问题" \
			"9" "🍥 software sources:软件镜像源管理" \
			"10" "💻 qemu:x86_64虚拟机管理" \
			"11" "🌺 The Secret Garden秘密花园" \
			"0" "🌚 Exit 退出" \
			3>&1 1>&2 2>&3
	)
	########
	#faq的emoji为🏫学校，原意是希望大家能从中学到东西。后来觉得太丑了，就删掉了。。。
	#🌡️
	case "${TMOE_OPTION}" in
	0 | "")
		#export LANG=${CurrentLANG}
		exit 0
		;;
	1) install_gui ;;
	2) software_center ;;
	3) tmoe_desktop_beautification ;;
	4) modify_remote_desktop_config ;;
	5) download_videos ;;
	6) tmoe_docker_menu ;;
	7) tmoe_linux_tool_upgrade ;;
	8) frequently_asked_questions ;;
	9) tmoe_sources_list_manager ;;
	10) start_tmoe_qemu_manager ;;
	11) beta_features ;;
	esac
	#########################
	press_enter_to_return
	tmoe_linux_tool_menu
}
#########################
press_enter_to_return() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
}
#############
software_center() {
	source ${TMOE_TOOL_DIR}/app/center.sh
}
###################
start_tmoe_qemu_manager() {
	source ${TMOE_TOOL_DIR}/virtualization/qemu-system.sh -x64qemu
}
########################
tmoe_sources_list_manager() {
	source ${TMOE_TOOL_DIR}/sources/mirror.sh
}
#######################
download_videos() {
	source ${TMOE_TOOL_DIR}/downloader/videos.sh
}
####################
modify_remote_desktop_config() {
	source ${TMOE_TOOL_DIR}/gui/gui.sh -c
}
########################
tmoe_desktop_beautification() {
	source ${TMOE_TOOL_DIR}/gui/gui.sh -b
}
########################
install_gui() {
	source ${TMOE_TOOL_DIR}/gui/gui.sh --install-gui
}
######################
frequently_asked_questions() {
	source ${TMOE_TOOL_DIR}/other/frequently_asked_questions.sh
}
####################
beta_features() {
	source ${TMOE_TOOL_DIR}/app/beta_features.sh
}
######################
tmoe_docker_menu() {
	source ${TMOE_TOOL_DIR}/virtualization/docker.sh
}
#####################
tmoe_linux_tool_upgrade() {
	check_tmoe_linux_desktop_link
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		wget -O /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
	else
		curl -Lv -o /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
	fi
	chmod +x /usr/local/bin/debian-i
	check_tmoe_git_folder
	cd ${TMOE_GIT_DIR}
	git reset --hard origin/master
	git pull origin master --allow-unrelated-histories
	if [ "$?" != '0' ]; then
		git fetch --all
		git reset --hard origin/master
		git pull origin master --allow-unrelated-histories
	fi
	if [ -e "/usr/local/bin/work-i" ]; then
		cp "${TMOE_TOOL_DIR}/downloader/work_crawler@kanasimi.sh" /usr/local/bin
	fi
	if [ -e "/usr/local/bin/aria2-i" ]; then
		cp "${TMOE_TOOL_DIR}/downloader/aria2.sh" /usr/local/bin
	fi
	echo "${TMOE_GIT_URL}"
	echo "Update ${YELLOW}completed${RESET}, press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}更新完成，按回车键返回。${RESET}"
	#bash /usr/local/bin/debian-i
	read
	source /usr/local/bin/debian-i
}
#############################################
main "$@"
###############################
