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
	--install-gui | install-gui) install_gui ;;
	--modify_remote_desktop_config) modify_remote_desktop_config ;;
	qemu) start_tmoe_qemu_manager ;;
	--remove_gui) remove_gui ;;
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
	--choose-vnc-port) source ${TMOE_TOOL_DIR}/gui/gui.sh --choose-vnc-port ;;
	h | -h | --help)
		cat <<-'EOF'
			-ppa     --添加ppa软件源(add ppa source)   
			-u       --更新(update tmoe-linux tool)
			-m       --切换镜像源
			-tuna    --切换为bfsu源
			file     --运行文件浏览器(run filebrowser)
			qemu     --x64 qemu虚拟机管理
			docker  --tmoe docker tool
			aria2   --tmoe_aria2_manager
		EOF
		;;
	file | filebrowser)
		source ${TMOE_TOOL_DIR}/webserver/filebrowser.sh -r
		;;
	tuna | -tuna | --tuna | t | -t)
		SOURCE_MIRROR_STATION='mirrors.bfsu.edu.cn'
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
	ppa* | -ppa*) source ${TMOE_TOOL_DIR}/sources/mirror.sh -p ;;
	-install-deps)
		check_dependencies
		;;
	*) #main #勿删此注释 #export AUTO_INSTALL_GUI=true;
		#sed -i 's@*) #main@2333)@g' /tmp/tool.sh
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
check_tmoe_command() {
	if [ $(command -v zsh) ]; then
		if egrep -q '^[^#]*alias t=tmoe' ~/.zshrc 2>/dev//null; then
			TMOE_TIPS_01="t t"
		else
			TMOE_TIPS_01="tmoe t"
		fi
	else
		TMOE_TIPS_01="tmoe t"
	fi
	TMOE_TIPS_00="Welcome to tmoe linux tool v1.4190,type ${TMOE_TIPS_01} to start this tool."
	#勿改00变量
}
#########
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
	if grep -q 'Linux Deploy' /etc/motd 2>/dev/null; then
		export TMOE_CHROOT='true'
	fi
	if [ -z ${TMPDIR} ]; then
		TMPDIR=/tmp
		mkdir -pv ${TMPDIR}
	fi
	check_release_version
	check_tmoe_command
	TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
	if [ ! -e "/usr/local/bin" ]; then
		mkdir -pv /usr/local/bin
	fi
	TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
	TMOE_ICON_DIR="${TMOE_LINUX_DIR}/icons"
	TMOE_TOOL_DIR="${TMOE_GIT_DIR}/tools"
	TMOE_OPT_BIN_DIR="${TMOE_TOOL_DIR}/sources/opt-bin"
	TMOE_GIT_URL="github.com/2moe/tmoe-linux"
	APPS_LNK_DIR='/usr/share/applications'
	if [ ! -e "${APPS_LNK_DIR}" ]; then
		mkdir -pv ${APPS_LNK_DIR}
	fi

	CONFIG_FOLDER="${HOME}/.config/tmoe-linux"
	if [ ! -e "${CONFIG_FOLDER}" ]; then
		mkdir -pv ${CONFIG_FOLDER}
	fi
	DEBIAN_I_FILE="/usr/local/bin/debian-i"
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
	PURPLE=$(printf '\033[0;35m')
	RESET=$(printf '\033[m')
}
######################
check_release_version() {
	case "${LINUX_DISTRO}" in
	Android) OSRELEASE="Android" ;;
	*)
		if grep -q 'NAME=' /etc/os-release; then
			OSRELEASE=$(grep -v 'PRETTY' /etc/os-release | grep 'NAME=' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
		elif grep -q 'ID=' /etc/os-release; then
			OSRELEASE=$(grep -v 'VERSION' /etc/os-release | grep 'ID=' | head -n 1 | cut -d '=' -f 2)
		else
			OSRELEASE=LINUX
		fi
		;;
	esac
}
##############
check_win10x_icon() {
	if [ -e "/usr/share/icons/We10X" ]; then
		dbus-launch xfconf-query -c xsettings -np /Net/IconThemeName -s We10X
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
	printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET}"
	printf "%s\n" "按${GREEN}回车键${RESET}${BLUE}继续${RESET}"
	read
}
#############################################
check_root() {
	case $(id -u) in
	0) ;;
	*)
		if [ $(command -v fortune) ]; then
			fortune 2>/dev/null
		elif [ -e /usr/games/fortune ]; then
			/usr/games/fortune 2>/dev/null
		fi
		export PATH=${PATH}:/usr/sbin:/sbin
		if [ -e "${TMOE_GIT_DIR}/tool.sh" ]; then
			sudo -E bash ${TMOE_GIT_DIR}/tool.sh || su -c "bash ${TMOE_GIT_DIR}/tool.sh"
		else
			if [ $(command -v curl) ]; then
				sudo -E bash -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)" || su -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
			elif [ $(command -v aria2c) ]; then
				aria2c --console-log-level=warn --no-conf --allow-overwrite=true -o /tmp/.tmoe-linux-tool.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh
				su -c "$(bash /tmp/.tmoe-linux-tool.sh)"
			else
				su -c "$(wget -qO- https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
			fi
		fi
		exit 0
		;;
	esac
}
#####################
check_architecture() {
	case $(uname -m) in
	armv7* | armv8l) ARCH_TYPE="armhf" ;;
	armv6* | armv5*) ARCH_TYPE="armel" ;;
	aarch64 | armv8* | arm64) ARCH_TYPE="arm64" ;;
	x86_64 | amd64) ARCH_TYPE="amd64" ;;
	i*86 | x86) ARCH_TYPE="i386" ;;
	s390*) ARCH_TYPE="s390x" ;;
	ppc*) ARCH_TYPE="ppc64el" ;;
	mips64) ARCH_TYPE="mips64el" ;;
	mips*) ARCH_TYPE="mipsel" ;;
	risc*) ARCH_TYPE="riscv64" ;;
	esac
	TRUE_ARCH_TYPE=${ARCH_TYPE}
}
#####################
ubuntu_ppa_and_locale_gen() {
	case "${DEBIAN_DISTRO}" in
	ubuntu)
		if [ ! $(command -v add-apt-repository) ]; then
			apt install -y software-properties-common
		fi
		if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen" 2>/dev/null; then
			apt install -y ^language-pack-${TMOE_LANG_QUATER} 2>/dev/null
		fi
		;;
	esac
}
#############
tmoe_locale_settings() {
	TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
	if [ -e "${TMOE_LOCALE_FILE}" ]; then
		TMOE_LANG=$(head -n 1 ${TMOE_LOCALE_FILE})
		TMOE_LANG_HALF=$(printf '%s\n' "${TMOE_LANG}" | cut -d '.' -f 1)
		TMOE_LANG_QUATER=$(printf '%s\n' "${TMOE_LANG}" | cut -d '.' -f 1 | cut -d '_' -f 1)
	else
		TMOE_LANG="en_US.UTF-8"
		TMOE_LANG_HALF=$(printf '%s\n' "${TMOE_LANG}" | cut -d '.' -f 1)
		TMOE_LANG_QUATER=$(printf '%s\n' "${TMOE_LANG}" | cut -d '.' -f 1 | cut -d '_' -f 1)
	fi

	case "${LINUX_DISTRO}" in
	debian)
		if [ ! -e "/usr/sbin/locale-gen" ]; then
			apt install -y locales
		fi
		ubuntu_ppa_and_locale_gen
		if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen" 2>/dev/null; then
			cd /etc
			sed -i "s/^#.*${TMOE_LANG} UTF-8/${TMOE_LANG} UTF-8/" locale.gen 2>/dev/null
			if ! grep -qi "^${TMOE_LANG_HALF}" "locale.gen" 2>/dev/null; then
				printf "\n" >>locale.gen
				#sed -i 's@^@#@g' locale.gen 2>/dev/null
				#sed -i 's@##@#@g' locale.gen 2>/dev/null
				sed -i "$ a ${TMOE_LANG} UTF-8" locale.gen
			fi
			locale-gen ${TMOE_LANG} 2>/dev/null
		fi
		;;
	esac
}
#####################
check_linux_distro() {
	set_terminal_color
	if egrep -q 'debian|ubuntu|deepin|uos\.com' "/etc/os-release"; then
		LINUX_DISTRO='debian'
		TMOE_INSTALLATION_COMMAND='apt install -y'
		TMOE_REMOVAL_COMMAND='apt purge -y'
		TMOE_UPDATE_COMMAND='apt update'
		if grep -q 'ubuntu' /etc/os-release; then
			DEBIAN_DISTRO='ubuntu'
		elif [ "$(cut -c 1-4 /etc/issue)" = "Kali" ]; then
			DEBIAN_DISTRO='kali'
		elif egrep -q 'deepin|uos' /etc/os-release; then
			DEBIAN_DISTRO='deepin'
		fi
		###################
	elif egrep -q "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		LINUX_DISTRO='openwrt'
		TMOE_UPDATE_COMMAND='opkg update'
		TMOE_INSTALLATION_COMMAND='opkg install'
		TMOE_REMOVAL_COMMAND='opkg remove'
		##################
	elif egrep -qi "Fedora|CentOS|Red Hat|redhat" "/etc/os-release"; then
		LINUX_DISTRO='redhat'
		if [ $(command -v dnf) ]; then
			TMOE_UPDATE_COMMAND='dnf update'
			TMOE_INSTALLATION_COMMAND='dnf install -y --skip-broken'
			TMOE_REMOVAL_COMMAND='dnf remove -y'
		else
			TMOE_UPDATE_COMMAND='yum update'
			TMOE_INSTALLATION_COMMAND='yum install -y --skip-broken'
			TMOE_REMOVAL_COMMAND='yum remove -y'
		fi
		if [ "$(grep 'ID=' /etc/os-release | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHAT_DISTRO='centos'
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHAT_DISTRO='fedora'
		fi
		###################
	elif grep -q "Alpine" '/etc/issue' 2>/dev/null || grep -q "Alpine" "/etc/os-release"; then
		LINUX_DISTRO='alpine'
		TMOE_UPDATE_COMMAND='apk update'
		TMOE_INSTALLATION_COMMAND='apk add'
		TMOE_REMOVAL_COMMAND='apk del'
		######################
	elif egrep -q "Arch|Manjaro" '/etc/os-release' || egrep -q "Arch|Manjaro" '/etc/issue' 2>/dev/null; then
		LINUX_DISTRO='arch'
		TMOE_UPDATE_COMMAND='pacman -Syy'
		TMOE_INSTALLATION_COMMAND='pacman -Syu --noconfirm'
		TMOE_REMOVAL_COMMAND='pacman -Rsc'
		######################
	elif egrep -q "gentoo|funtoo" "/etc/os-release"; then
		LINUX_DISTRO='gentoo'
		TMOE_INSTALLATION_COMMAND='emerge -avk'
		TMOE_REMOVAL_COMMAND='emerge -C'
		########################
	elif grep -qi 'suse' '/etc/os-release'; then
		LINUX_DISTRO='suse'
		TMOE_INSTALLATION_COMMAND='zypper in -y'
		TMOE_REMOVAL_COMMAND='zypper rm'
		########################
	elif [ "$(cut -c 1-4 /etc/issue 2>/dev/null)" = "Void" ]; then
		LINUX_DISTRO='void'
		export LANG='en_US.UTF-8'
		TMOE_INSTALLATION_COMMAND='xbps-install -S -y'
		TMOE_REMOVAL_COMMAND='xbps-remove -R'
		#########################
	elif egrep -q "Slackware" '/etc/os-release'; then
		LINUX_DISTRO='slackware'
		TMOE_UPDATE_COMMAND='slackpkg update'
		TMOE_INSTALLATION_COMMAND='slackpkg install'
		TMOE_REMOVAL_COMMAND='slackpkg remove'
		#########################
	elif [ "$(uname -o)" = 'Android' ]; then
		printf "%s\n" "${RED}不支持${RESET}${BLUE}Android${RESET}系统！"
		exit 1
	fi
}
#############################
check_dependencies() {
	DEPENDENCIES=""
	case "${LINUX_DISTRO}" in
	redhat)
		if [ $(command -v dnf) ]; then
			if [ ! -e "${TMOE_LINUX_DIR}/not_install_dnf_plugins_core" ]; then
				dnf config-manager --help &>/dev/null
				case "${?}" in
				0) ;;
				*) dnf install -y dnf-plugins-core ;;
				esac
				printf "%s\n" "If you want to use dnf config-manager,you should install dnf-plugins-core." >"${TMOE_LINUX_DIR}/not_install_dnf_plugins_core"
			fi
		fi
		;;
	esac

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

	if [ ! $(command -v ar) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} sys-devel/binutils" ;;
		*) DEPENDENCIES="${DEPENDENCIES} binutils" ;;
		esac
	fi
	#####################
	if [ ! $(command -v catimg) ] && [ ! -e "${TMOE_LINUX_DIR}/not_install_catimg" ]; then
		case "${LINUX_DISTRO}" in
		debian)
			if grep -q 'VERSION_ID=' "/etc/os-release"; then
				DEBIANVERSION="$(grep 'VERSION_ID=' "/etc/os-release" | cut -d '"' -f 2 | cut -d '.' -f 1 | awk '{print $1}')"
			else
				DEBIANVERSION="10"
			fi
			if ((${DEBIANVERSION} <= 9)); then
				printf "%s\n" "检测到您的系统版本低于debian10，跳过安装catimg"
			else
				DEPENDENCIES="${DEPENDENCIES} catimg"
			fi
			;;
		arch | void) DEPENDENCIES="${DEPENDENCIES} catimg" ;;
		redhat)
			case "${REDHAT_DISTRO}" in
			"fedora") DEPENDENCIES="${DEPENDENCIES} catimg" ;;
			esac
			;;
		esac
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
		gentoo) DEPENDENCIES="${DEPENDENCIES} sys-apps/grep" ;;
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
	if [ ! $(command -v ip) ]; then
		case "${LINUX_DISTRO}" in
		debian) DEPENDENCIES="${DEPENDENCIES} iproute2" ;;
		arch | redhat) DEPENDENCIES="${DEPENDENCIES} iproute" ;;
		esac
	fi

	case "${LINUX_DISTRO}" in
	alpine)
		if [ ! $(command -v ctstat) ]; then
			DEPENDENCIES="${DEPENDENCIES} iproute2"
		fi
		if [[ $(readlink /bin/tar) = /bin/busybox ]]; then
			DEPENDENCIES="${DEPENDENCIES} tar"
		fi
		;;
	esac

	if [ ! $(command -v hostname) ]; then
		case "${LINUX_DISTRO}" in
		arch) DEPENDENCIES="${DEPENDENCIES} inetutils" ;;
		redhat) DEPENDENCIES="${DEPENDENCIES} hostname" ;;
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
		gentoo) DEPENDENCIES="${DEPENDENCIES} app-editors/nano" ;;
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

	if [ ! $(command -v pkill) ] && [ ! -e ${CONFIG_FOLDER}/non-install-procps ]; then
		printf '%s\n' 'OpenWRT可能无此软件包' >${CONFIG_FOLDER}/non-install-procps
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} sys-process/procps" ;;
		redhat) DEPENDENCIES="${DEPENDENCIES} procps procps-ng procps-ng-i18n" ;;
		*) DEPENDENCIES="${DEPENDENCIES} procps" ;;
		esac
	fi
	#####################
	if [ ! $(command -v sudo) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} app-admin/sudo" ;;
		*) DEPENDENCIES="${DEPENDENCIES} sudo" ;;
		esac
	fi
	###################
	#centos8基础容器里无tar
	if [ ! $(command -v tar) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} app-arch/tar" ;;
		*) DEPENDENCIES="${DEPENDENCIES} tar" ;;
		esac
	fi
	#####################
	if [ "$(command -v whiptail)" = "/data/data/com.termux/files/usr/bin/whiptail" ] || [ ! $(command -v whiptail) ]; then
		case "${LINUX_DISTRO}" in
		debian) DEPENDENCIES="${DEPENDENCIES} whiptail" ;;
		arch) DEPENDENCIES="${DEPENDENCIES} libnewt" ;;
		gentoo) DEPENDENCIES="${DEPENDENCIES} dev-libs/newt" ;;
		openwrt) DEPENDENCIES="${DEPENDENCIES} whiptail" ;;
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
	if [ ! $(command -v whereis) ]; then
		case "${LINUX_DISTRO}" in
		debian) DEPENDENCIES="${DEPENDENCIES} util-linux" ;;
		esac
	fi
	if [ ! $(command -v zstd) ]; then
		#arch无需额外安装zstd
		case "${LINUX_DISTRO}" in
		debian | redhat | alpine) DEPENDENCIES="${DEPENDENCIES} zstd" ;;
		esac
	fi
	##############
	if [ ! -z "${DEPENDENCIES}" ]; then
		[[ -s ${TMOE_LINUX_DIR}/TOOL_DEPENDENCIES.txt ]] || printf "%s\n" ${DEPENDENCIES} >${TMOE_LINUX_DIR}/TOOL_DEPENDENCIES.txt
		cat <<-EOF
			正在${YELLOW}安装${RESET}相关${GREEN}软件包${RESET}及其${BLUE}依赖...${RESET}
			${GREEN}${TMOE_INSTALLATION_COMMAND}${BLUE}${DEPENDENCIES}${RESET}
			如需${BOLD}${RED}卸载${RESET}${RESET}，请${YELLOW}手动${RESET}输${RED}${TMOE_REMOVAL_COMMAND}${RESET}${BLUE}${DEPENDENCIES}${RESET}
		EOF
		case "${LINUX_DISTRO}" in
		debian)
			${TMOE_UPDATE_COMMAND} || ${TMOE_UPDATE_COMMAND}
			${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES} || ${TMOE_INSTALLATION_COMMAND} git wget curl whiptail aria2 xz-utils nano aptitude sudo less binutils || ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES}
			#创建文件夹防止aptitude报错
			mkdir -pv /run/lock /var/lib/aptitude
			touch /var/lib/aptitude/pkgstates
			;;
		alpine | openwrt | slackware)
			${TMOE_UPDATE_COMMAND}
			${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES} || ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES}
			;;
		arch | gentoo | suse | void) ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES} || ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES} || ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES} ;;
		redhat)
			if [ $(command -v dnf) ]; then
				${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES} || ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES}
			else
				yum install -y --skip-broken ${DEPENDENCIES} || yum install -y --skip-broken ${DEPENDENCIES}
			fi
			;;
		*)
			apt update
			${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES}
			apt install -y ${DEPENDENCIES} || port install ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES} || pacman -Syu ${DEPENDENCIES}
			;;
		esac
	fi
	################
	install_cat_img_deb() {
		cd /tmp
		wget --no-check-certificate -O 'catimg.deb' "${CATIMG_REPO}catimg_${CATIMGlatestVersion}_${ARCH_TYPE}.deb"
		apt install -y ./catimg.deb
		rm -f catimg.deb
	}
	#############
	case ${LINUX_DISTRO} in
	redhat)
		case "${REDHAT_DISTRO}" in
		"fedora") ;;
		*)
			if [ ! -e "/etc/yum.repos.d/epel.repo" ]; then
				yum install -y epel-release
				if [ ! -e "/etc/yum.repos.d/epel.repo" ]; then
					if (whiptail --title "Please choose RHEL version" --yes-button "7" --no-button "8" --yesno "You should import the epel source." 0 50); then
						RHEL_VERSION='7'
					else
						RHEL_VERSION='8'
					fi
					yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL_VERSION}.noarch.rpm
				fi
				printf "${YELLOW}%s\n${RESET}" "请问您是否需要将EPEL源更换为北外源${PURPLE}[Y/n]${RESET}"
				printf "更换后可以加快国内的下载速度,${YELLOW}按回车键确认，输n拒绝。${RESET}\n"
				printf "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .[Y/n]\n"
				read opt
				case $opt in
				y* | Y* | "")
					cp -pvf /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
					cp -pvf /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
					sed -e 's!^metalink=!#metalink=!g' \
						-e 's!^#baseurl=!baseurl=!g' \
						-e 's!//download\.fedoraproject\.org/pub!//mirrors.bfsu.edu.cn!g' \
						-e 's!http://mirrors\.bfsu!https://mirrors.bfsu!g' \
						-i /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel-testing.repo
					;;
				n* | N*) echo "skipped." ;;
				*) echo "Invalid choice. skipped." ;;
				esac
				if [ ! $(command -v dnf) ]; then
					yum install -y dnf
					yum update
				fi
				check_dependencies
			fi
			;;
		esac
		;;
	esac
	if [ ! $(command -v catimg) ] && [ ! -e "${TMOE_LINUX_DIR}/not_install_catimg" ]; then
		mkdir -pv ${TMOE_LINUX_DIR}
		touch ${TMOE_LINUX_DIR}/not_install_catimg
		case "${LINUX_DISTRO}" in
		debian)
			CATIMG_REPO="https://mirrors.bfsu.edu.cn/debian/pool/main/c/catimg/"
			CATIMGlatestVersion="$(curl -LfsS "${CATIMG_REPO}" | grep ${ARCH_TYPE} | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '_' -f 2)"
			install_cat_img_deb
			if [ ! $(command -v catimg) ]; then
				CATIMGlatestVersion="$(curl -LfsS "${CATIMG_REPO}" | grep ${ARCH_TYPE} | head -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '_' -f 2)"
				install_cat_img_deb
			fi
			;;
		esac
	fi
	################
	if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
		WINDOWS_DISTRO='WSL'
	fi
	##############
	CurrentLANG=${LANG}
	if [ ! $(printf '%s\n' "${LANG}" | egrep 'UTF-8|UTF8') ]; then
		export LANG=C.UTF-8
	fi
}
####################################################
git_clone_tmoe_linux_repo() {
	if [ ! -e "${TMOE_LINUX_DIR}" ]; then
		mkdir -pv ${TMOE_LINUX_DIR}
	fi
	git clone -b master --depth=1 https://${TMOE_GIT_URL} ${TMOE_GIT_DIR}
}
#################
do_you_want_to_git_clone_tmoe_linux_repo() {
	printf "%s\n" "Do you want to ${GREEN}git clone${RESET} this repo to ${BLUE}${TMOE_GIT_DIR}${RESET}?"
	printf "%s\n" "您需要克隆本項目倉庫方能繼續使用"
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
		rm -rfv ${TMOE_GIT_DIR}
		printf "%s\n" "https://${TMOE_GIT_URL}"
		case ${TMOE_PROOT} in
		true | false) git_clone_tmoe_linux_repo ;;
		*) do_you_want_to_git_clone_tmoe_linux_repo ;;
		esac
		source ${TMOE_TOOL_DIR}/environment.sh
		check_current_user_name_and_group
	fi
}
#######################
tmoe_linux_tool_menu() {
	IMPORTANT_TIPS=""
	RETURN_TO_MENU='tmoe_linux_tool_menu'
	#窗口大小20 50 7
	tmoe_linux_tool_menu_zh() {
		TMOE_OPTION=$(
			whiptail --title "Tmoe-Tool running on ${OSRELEASE}" \
				--menu "${TMOE_TIPS_00}\nPlease use the enter and arrow keys to operate." 0 50 0 \
				"1" "🍭 GUI:图形界面(桌面,WM,登录管理器)" \
				"2" "🥝 Software center:软件(浏览器,游戏,影音)" \
				"3" "🌺 Secret Garden秘密花园(教育,系统,实验功能)" \
				"4" "🌈 Desktop beautification:桌面美化(主题)" \
				"5" "🌌 vnc/x/rdp:远程桌面" \
				"6" "📺 Download video:解析视频链接(bili,Y2B)" \
				"7" "🍥 Software sources:软件镜像源管理" \
				"8" "🐳 Docker:开源的应用容器引擎" \
				"9" "💻 Qemu:x64虚拟机管理" \
				"10" "🍧 *°▽°*Update tmoe-linux tool(更新本工具)" \
				"11" "🍩 FAQ:常见问题" \
				"0" "🌚 Exit 退出" \
				3>&1 1>&2 2>&3
		)
	}
	tmoe_linux_tool_menu_ja() {
		TMOE_OPTION=$(
			whiptail --title "Tmoe-Tool running on ${OSRELEASE}" \
				--menu "${TMOE_TIPS_00}\nEnterキーと矢印キーを使用して操作できます" 0 50 0 \
				"1" "🍭 GUI:グラフィカル・ユーザ・インターフェース(DE,WM,LM)" \
				"2" "🥝 アプリストア(ブラウザ、ゲーム、メディアアプリ)" \
				"3" "🌺 秘密の花園(教育、システム、beta機能)" \
				"4" "🌈 デスクトップ環境の美化(テーマとアイコンパック)" \
				"5" "🌌 vnc/x/rdp:リモートデスクトップサーバー" \
				"6" "📺 ニコニコ動画ダウンローダー" \
				"7" "🍥 ソフトウェアミラーソース" \
				"8" "🐳 Docker:コンテナ仮想化を用いたOSレベルの仮想化" \
				"9" "💻 Qemu:x64 仮想マシン" \
				"10" "🍧 *°▽°*更新" \
				"11" "🍩 よくある質問" \
				"0" "🌚 終了する" \
				3>&1 1>&2 2>&3
		)
	}
	tmoe_linux_tool_menu_en() {
		TMOE_OPTION=$(
			whiptail --title "Tmoe-Tool running on ${OSRELEASE}" \
				--menu "${TMOE_TIPS_00}\nPlease use the enter and arrow keys to operate." 0 50 0 \
				"1" "🍭 Graphical User Interface(DE,WM,LM)" \
				"2" "🥝 App center(browsers,games,media apps)" \
				"3" "🌺 Secret Garden(education,system,beta feature)" \
				"4" "🌈 Desktop beautification(theme and icon-pack)" \
				"5" "🌌 vnc/x/rdp:remote desktop server" \
				"6" "📺 Download video:Y2B" \
				"7" "🍥 Software sources:Worldwide mirror sites" \
				"8" "🐳 Docker：use OS-level virtualization to deliver software" \
				"9" "💻 Qemu:x64 virtual machine" \
				"10" "🍧 *°▽°*Update tmoe-linux tool" \
				"11" "🍩 Frequently Asked Questions" \
				"0" "🌚 Exit" \
				3>&1 1>&2 2>&3
		)
	}
	########
	case ${TMOE_MENU_LANG} in
	zh_*UTF-8) tmoe_linux_tool_menu_zh ;;
	ja_JP.UTF-8) tmoe_linux_tool_menu_ja ;;
	*) tmoe_linux_tool_menu_en ;;
	esac
	##########
	case "${TMOE_OPTION}" in
	0 | "") exit 0 ;;
	1) install_gui ;;
	2) software_center ;;
	3) beta_features ;;
	4) tmoe_desktop_beautification ;;
	5) modify_remote_desktop_config ;;
	6) download_videos ;;
	7) tmoe_sources_list_manager ;;
	8) tmoe_docker_menu ;;
	9) start_tmoe_qemu_manager ;;
	10) tmoe_linux_tool_upgrade ;;
	11) frequently_asked_questions ;;
	esac
	#########################
	press_enter_to_return
	tmoe_linux_tool_menu
}
#########################
press_enter_to_return() {
	printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}return${RESET},press ${YELLOW}Ctrl+C${RESET} to ${RED}exit.${RESET}"
	printf "%s\n" "按${GREEN}回车键${RESET}${BLUE}返回${RESET},按${YELLOW}Ctrl+C${RESET}${RED}退出${RESET}。"
	read
}
#############
software_center() {
	source ${TMOE_TOOL_DIR}/app/center.sh
}
###################
start_tmoe_qemu_manager() {
	source ${TMOE_TOOL_DIR}/virtualization/qemu/tmoe-qemu
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
	if [ ! -h "${DEBIAN_I_FILE}" ]; then
		rm -fv ${DEBIAN_I_FILE} 2>/dev/null
		ln -sfv ${TMOE_GIT_DIR}/tool.sh ${DEBIAN_I_FILE}
	else
		ln -sf ${TMOE_GIT_DIR}/tool.sh ${DEBIAN_I_FILE}
	fi
	check_tmoe_git_folder
	cd ${TMOE_GIT_DIR}
	git reset --hard origin/master
	git pull --rebase --stat origin master --allow-unrelated-histories || git rebase --skip
	if [ "$?" != '0' ]; then
		git fetch --all
		git reset --hard
		git pull --rebase --stat --allow-unrelated-histories || git rebase --skip
	fi
	if [ -e "/usr/local/bin/work-i" ]; then
		cp "${TMOE_TOOL_DIR}/downloader/work_crawler@kanasimi.sh" /usr/local/bin
	fi
	if [ -e "/usr/local/bin/aria2-i" ]; then
		cp "${TMOE_TOOL_DIR}/downloader/aria2.sh" /usr/local/bin
	fi
	if [ ! -h $(command -v tmoe) ]; then
		ln -sfv ${TMOE_GIT_DIR}/share/app/tmoe /usr/local/bin
	fi
	if [ -n $(command -v startvnc) ]; then
		if grep -q 'set.*-depth.*16' $(command -v startvnc); then
			sed -i 's@"-depth" "16"@"-depth" "24"@g' $(command -v startvnc)
		fi
	fi
	#printf "%s\n" "${TMOE_GIT_URL}"
	printf '%s\n' '(o゜▽゜)o☆  Thank you for using Tmoe-linux tool.'
	printf "%s\n" "Update ${YELLOW}completed${RESET}, press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	printf "%s\n" "${YELLOW}更新完成，按回车键返回。${RESET}"
	#bash ${DEBIAN_I_FILE}
	read
	source ${DEBIAN_I_FILE}
}
#############################################
main "$@"
###############################
