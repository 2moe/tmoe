#!/data/data/com.termux/files/usr/bin/env bash
########################################################################
main() {
	case "$1" in
	i* | -i* | -I*)
		debian-i
		exit 0
		;;
	h* | -h* | --h*)
		cat <<-'EOF'
			-m      --更换为tuna镜像源(仅debian,ubuntu,kali,alpine和arch)
			-n      --启动novnc
			-v      --启动VNC
			-s      --停止vnc
			-x      --启动xsdl
			-h      --获取帮助信息
		EOF
		;;
	-m* | m* | -tuna*)
		gnu_linux_sources_list
		;;
	-novnc | novnc* | -n*)
		start_web_novnc
		;;
	-v | -vnc)
		startvnc
		;;
	-s | -stop*)
		stopvnc
		;;
	-x | -xsdl)
		startxsdl
		;;
	*)
		check_arch
		auto_check
		tmoe_manager_env
		tmoe_manager_main_menu
		;;
	esac
}
#########################
tmoe_manager_env() {
	check_release_version
	TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
	TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
	TMOE_TOOL_DIR="${TMOE_GIT_DIR}/tools"
	TMOE_OPT_BIN_DIR="${TMOE_TOOL_DIR}/sources/opt-bin"
	TMOE_GIT_URL='github.com/2moe/tmoe-linux'
	APPS_LNK_DIR='/usr/share/applications'
	check_tmoe_container_chroot
}
#######
check_tmoe_container_chroot() {
	if [ -e "${CONFIG_FOLDER}/chroot_container" ]; then
		TMOE_CHROOT='true'
	elif grep -q 'TMOE_CHROOT=' ${PREFIX}/bin/debian 2>/dev/null; then
		TMOE_CHROOT='true'
	fi
	case ${TMOE_CHROOT} in
	true)
		if [ $(command -v sudo) ]; then
			TMOE_PREFIX='sudo'
		elif [ $(command -v tsudo) ]; then
			TMOE_PREFIX='tsudo'
		fi
		;;
	*) TMOE_PREFIX='' ;;
	esac
}
######
check_arch() {
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
		#经测试uname -m输出的结果为s390x
		;;
	ppc*)
		ARCH_TYPE="ppc64el"
		#经测试uname -m输出的结果为ppc64le，而不是ppc64el
		;;
	mips*)
		ARCH_TYPE="mipsel"
		#echo -e 'Embedded devices such as routers are not supported at this time\n暂不支持mips架构的嵌入式设备'
		#20200323注：手动构建了mipsel架构的debian容器镜像，现在已经支持了。
		#经测试uname -m输出的结果为mips，而不是mipsel
		#exit 1
		;;
	risc*)
		ARCH_TYPE="riscv"
		#20200323注：riscv靠qemu实现跨cpu架构运行chroot容器
		#echo 'The RISC-V architecture you are using is too advanced and we do not support it yet.'
		#exit 1
		;;
	*)
		echo "未知的架构 $(uname -m) unknown architecture"
		#exit 1
		;;
	esac
	TRUE_ARCH_TYPE=${ARCH_TYPE}
	CONFIG_FOLDER="${HOME}/.config/tmoe-linux"
	if [ ! -e "${CONFIG_FOLDER}" ]; then
		mkdir -p ${CONFIG_FOLDER}
	fi
	ACROSS_ARCH_FILE="${CONFIG_FOLDER}/across_architecture_container.txt"
	if [ -e "${ACROSS_ARCH_FILE}" ]; then
		ARCH_TYPE="$(cat ${ACROSS_ARCH_FILE} | head -n 1)"
		QEMU_ARCH="$(cat ${ACROSS_ARCH_FILE} | sed -n 2p)"
	fi
	LINUX_CONTAINER_DISTRO_FILE="${CONFIG_FOLDER}/linux_container_distro.txt"
	DEBIAN_FOLDER=debian_${ARCH_TYPE}
	if [ -e "${LINUX_CONTAINER_DISTRO_FILE}" ]; then
		LINUX_CONTAINER_DISTRO=$(cat ${LINUX_CONTAINER_DISTRO_FILE} | head -n 1)
		if [ ! -z "${LINUX_CONTAINER_DISTRO}" ]; then
			DEBIAN_FOLDER="${LINUX_CONTAINER_DISTRO}_${ARCH_TYPE}"
		fi
	fi
	ROOTFS_NAME=$(echo ${DEBIAN_FOLDER} | cut -d '_' -f 1)
	DEBIAN_CHROOT=${HOME}/${DEBIAN_FOLDER}
	#echo $DEBIAN_FOLDER $DEBIAN_CHROOT
	RED=$(printf '\033[31m')
	GREEN=$(printf '\033[32m')
	YELLOW=$(printf '\033[33m')
	BLUE=$(printf '\033[34m')
	BOLD=$(printf '\033[1m')
	RESET=$(printf '\033[m')
	cur=$(pwd)
	ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null | cut -d '.' -f 1) || ANDROID_VERSION=6
}
###############
press_enter_to_return() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
}
#####################
press_enter_to_continue() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}继续${RESET}"
	read
}
#########################################################
auto_check() {
	if [ "$(uname -o)" = "Android" ]; then
		LINUX_DISTRO='Android'
		if [ ! -h "/data/data/com.termux/files/home/storage/shared" ]; then
			termux-setup-storage
		fi
		android_termux
	elif [ "$(uname -v | cut -c 1-3)" = "iSH" ]; then
		LINUX_DISTRO='iSH'
		if grep -q 'cdn.alpinelinux.org' "/etc/apk/repositories"; then
			sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g'
		fi
		gnu_linux
	else
		gnu_linux
	fi
	##当检测到ish后一定要加上gnu_linux，且不能在最后一个fi后添加。
}
########################################
gnu_linux() {
	TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
	TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
	if [ "$(id -u)" != "0" ]; then
		export PATH=${PATH}:/usr/sbin:/sbin
		if [ -e "${TMOE_GIT_DIR}/manager.sh" ]; then
			sudo -E bash ${TMOE_GIT_DIR}/manager.sh || su -c "bash manager.sh"
		else
			if [ -e "/usr/bin/curl" ]; then
				sudo -E bash -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)" ||
					su -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
			else
				sudo -E bash -c "$(wget -qO- https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)" ||
					su -c "$(wget -qO- https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
			fi
			#此处一定为debian.sh，而非manager.sh
		fi
		exit 0
	fi
	##############
	if grep -Eq 'debian|ubuntu|deepin' "/etc/os-release"; then
		LINUX_DISTRO='debian'
		TMOE_INSTALLATON_COMMAND='apt install -y'
		TMOE_REMOVAL_COMMAND='apt purge -y'
		if grep -q 'ubuntu' /etc/os-release; then
			DEBIAN_DISTRO='ubuntu'
		elif [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
			DEBIAN_DISTRO='kali'
		elif grep -q 'deepin' /etc/os-release; then
			DEBIAN_DISTRO='deepin'
		fi

	elif grep -Eq "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		LINUX_DISTRO='openwrt'
		TMOE_INSTALLATON_COMMAND='opkg install'
		TMOE_REMOVAL_COMMAND='opkg remove'
		cd /tmp
		wget --no-check-certificate -qO "router-debian.bash" https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
		chmod +x 'router-debian.bash'
		#bash -c "$(cat 'router-zsh.bash' |sed 's@/usr/bin@/opt/bin@g' |sed 's@-e /bin@-e /opt/bin@g' |sed 's@whiptail@dialog@g')"
		sed -i 's@/usr/bin@/opt/bin@g' 'router-debian.bash'
		sed -i 's@-e /bin@-e /opt/bin@g' 'router-debian.bash'
		sed -i 's@whiptail@dialog@g' 'router-debian.bash'
		sed -i 's@wget --no-check-certificate -qO "router-debian.bash"@#&@' 'router-debian.bash'
		sed -i 's@bash router-debian.bash@#&@' 'router-debian.bash'
		bash router-debian.bash

	elif grep -Eqi "Fedora|CentOS|Red Hat|redhat" '/etc/os-release'; then
		LINUX_DISTRO='redhat'
		TMOE_REMOVAL_COMMAND='dnf remove -y'
		TMOE_INSTALLATON_COMMAND='dnf install -y --skip-broken'
		if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHAT_DISTRO='centos'
		elif grep -q 'Sliverblue' "/etc/os-release"; then
			echo "Sorry,不支持Fedora SliverBlue"
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHAT_DISTRO='fedora'
		fi

	elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" '/etc/os-release'; then
		LINUX_DISTRO='alpine'
		TMOE_INSTALLATON_COMMAND='apk add'
		TMOE_REMOVAL_COMMAND='apk del'

	elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
		LINUX_DISTRO='arch'
		TMOE_REMOVAL_COMMAND='pacman -Rsc'
		TMOE_INSTALLATON_COMMAND='pacman -Syu --noconfirm'

	elif grep -Eq "gentoo|funtoo" '/etc/os-release'; then
		LINUX_DISTRO='gentoo'
		TMOE_INSTALLATON_COMMAND='emerge -vk'
		TMOE_REMOVAL_COMMAND='emerge -C'

	elif grep -qi 'suse' '/etc/os-release'; then
		LINUX_DISTRO='suse'
		TMOE_INSTALLATON_COMMAND='zypper in -y'
		TMOE_REMOVAL_COMMAND='zypper rm'

	elif [ "$(cat /etc/issue | cut -c 1-4)" = "Void" ]; then
		LINUX_DISTRO='void'
		TMOE_INSTALLATON_COMMAND='xbps-install -S -y'
		TMOE_REMOVAL_COMMAND='xbps-remove -R'
	fi

	######################################
	DEPENDENCIES=""

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

	if [ ! $(command -v curl) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/curl"
		else
			DEPENDENCIES="${DEPENDENCIES} curl"
		fi
	fi

	#####################
	if [ ! $(command -v git) ]; then
		if [ "${LINUX_DISTRO}" = "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} git git-http"
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} dev-vcs/git"
		else
			DEPENDENCIES="${DEPENDENCIES} git"
		fi
	fi

	if [ ! $(command -v grep) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sys-apps/grep"
		else
			DEPENDENCIES="${DEPENDENCIES} grep"
		fi
	fi
	####################
	if [ ! $(command -v pv) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sys-apps/pv"
		elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
			if [ "${REDHAT_DISTRO}" = 'fedora' ]; then
				DEPENDENCIES="${DEPENDENCIES} pv"
			fi
		else
			DEPENDENCIES="${DEPENDENCIES} pv"
		fi
	fi

	if [ ! $(command -v proot) ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} proot"
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
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} sudo"
		fi
	fi
	#####################
	if [ ! $(command -v tar) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} app-arch/tar"
		else
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
	if [ "${ARCH_TYPE}" = "riscv" ]; then
		DEPENDENCIES="${DEPENDENCIES} qemu qemu-user-static debootstrap"
	fi
	##############
	gnu_linux_tuna_mirror_list() {
		echo "${YELLOW}检测到您当前使用的sources.list不是清华源,是否需要更换为清华源[Y/n]${RESET} "
		echo "更换后可以加快国内的下载速度,${YELLOW}按回车键确认，输n拒绝。${RESET}"
		echo "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .[Y/n]"
		read opt
		case $opt in
		y* | Y* | "")
			gnu_linux_sources_list
			;;
		n* | N*) echo "skipped." ;;
		*) echo "Invalid choice. skipped." ;;
		esac
	}
	########################
	if [ ! -z "${DEPENDENCIES}" ]; then
		MIRROR_LIST='true'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			case ${DEBIAN_DISTRO} in
			deepin) ;;
			*)
				if ! grep -q '^deb.*mirrors' "/etc/apt/sources.list"; then
					MIRROR_LIST='false'
				fi
				;;
			esac
		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			if ! grep -q '^Server.*mirrors' "/etc/pacman.d/mirrorlist"; then
				MIRROR_LIST='false'
			fi
		elif [ "${LINUX_DISTRO}" = "alpine" ]; then
			if ! grep -q '^http.*mirrors' "/etc/apk/repositories"; then
				MIRROR_LIST='false'
			fi
		fi
		if [ "${MIRROR_LIST}" = 'false' ]; then
			gnu_linux_tuna_mirror_list
		fi
		notes_of_tmoe_package_installation

		if [ "${LINUX_DISTRO}" = "debian" ]; then
			apt update
			apt install -y ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "alpine" ]; then
			if ! grep -q '^http.*community' "/etc/apk/repositories"; then
				sed -i '$ a\http://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/community' "/etc/apk/repositories"
			fi
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
			emerge -vk ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "suse" ]; then
			zypper in -y ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "void" ]; then
			export LANG='en_US.UTF-8'
			xbps-install -S -y ${DEPENDENCIES}

		else
			apt update
			apt install -y ${DEPENDENCIES} || port install ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES}
		fi
	fi
	##################
	#解决乱码问题
	CurrentLANG=$LANG
	#export LANG=$(echo 'emhfQ04uVVRGLTgK' | base64 -d)
	if [ ! $(echo ${LANG} | grep -E 'UTF-8|UTF8') ]; then
		export LANG=C.UTF-8
	fi
	########################
	if [ "${LINUX_DISTRO}" = "openwrt" ]; then
		if [ -d "/opt/bin" ]; then
			PREFIX="/opt"
		else
			PREFIX=${HOME}
		fi
	else
		#PREFIX=/data/data/com.termux/files/usr
		PREFIX='/usr/local'
	fi

	if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
		WSL="[WSL(win10的linux子系统)]"
		WINDOWSDISTRO='WSL'
		export PATH="${PATH}:/mnt/c/WINDOWS/system32/:/mnt/c/WINDOWS/system32/WindowsPowerShell/v1.0/"
		#此处必须设定环境变量，因为sudo的环境变量会发生改变。
		#不能使用这条alias：alias sudo='sudo env PATH=$PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH'
		echo '检测到您使用的是WSL'
		if [ ! -e "/mnt/c/Users/Public/Downloads/pulseaudio/pulseaudio.bat" ]; then
			echo "正在为您下载windows版pulseaudio"
			echo "目录C:\Users\Public\Downloads\pulseaudio"
			mkdir -p /mnt/c/Users/Public/Downloads
			cd /mnt/c/Users/Public/Downloads
			rm -rf ./pulseaudio 2>/dev/null
			git clone -b pulseaudio --depth=1 https://gitee.com/mo2/wsl.git ./pulseaudio
		fi

		if [ ! -e "/mnt/c/Users/Public/Downloads/VcXsrv" ]; then
			if grep -q '172..*1' "/etc/resolv.conf"; then
				echo "检测到您当前使用的可能是WSL2，正在为您下载windows版VcXsrv"
			else
				echo "检测到您当前使用的可能是初代WSL，正在为您下载windows版VcXsrv"
			fi
			echo "目录C:\Users\Public\Downloads\VcXsrv"
			mkdir -p /mnt/c/Users/Public/Downloads
			cd /mnt/c/Users/Public/Downloads
			rm -rf ./.WSLXSERVERTEMPFILE 2>/dev/null
			git clone -b VcXsrv --depth=1 https://gitee.com/mo2/wsl.git ./.WSLXSERVERTEMPFILE
			mv ./.WSLXSERVERTEMPFILE/VcXsrv.tar.xz ./
			tar -Jxvf VcXsrv.tar.xz
			rm -rf ./.WSLXSERVERTEMPFILE VcXsrv.tar.xz
		fi
		#######此处download iso
		if ! grep -q '172..*1' "/etc/resolv.conf"; then
			if [ ! -e "/mnt/c/Users/Public/Downloads/wsl_update_x64.msi" ]; then
				cd /mnt/c/Users/Public/Downloads/
				cat <<-EOFKERNEL
					正在下载WSL2内核...
					目录C:\Users\Public\Downloads
					https://docs.microsoft.com/en-us/windows/wsl/wsl2-kernel
					https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
				EOFKERNEL
				aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "wsl_update_x64.msi" 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi'
				#/mnt/c/WINDOWS/system32/cmd.exe /c "start .\wsl_update_x64.msi"
			fi
			case ${TMOE_CHROOT} in
			true)
				echo "检测到您当前使用的是chroot容器，将不会自动调用Windows程序。"
				echo "请手动启动音频服务和X服务。"
				;;
			esac
			echo "您当前使用的可能不是WSL2,部分功能无法正常运行。"
			CURRENTwinVersion=$(/mnt/c/WINDOWS/system32/cmd.exe /c "VER" 2>/dev/null | cut -d '.' -f 3 | tail -n 1)
			echo "您当前的系统版本为${CURRENTwinVersion}"
			if (("${CURRENTwinVersion}" >= '19041')); then
				echo "您需要以管理员身份打开Powershell,并输入dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"
				echo "重启PC，然后输入以下命令"
				echo "wsl --set-default-version 2"
				echo "wsl --set-version 当前发行版名称 2"
				echo "您可以输wsl -l -v来获取发行版名称和版本号"
				#echo ${WSL_DISTRO_NAME}
				echo "wsl -l -v"
				echo "最后以管理员身份安装wsl_update_x64.msi（升级WSL2内核）"
				echo 'Press Enter to continue.'
				echo "${YELLOW}按回车键继续。${RESET}"
				read
			else
				echo "Do you want to download win10_2004_x64 iso and upgrade system?[Y/n]"
				echo "您的宿主机系统版本低于10.0.19041，需要更新系统。"
				echo "${YELLOW}是否需要下载10.0.19041 iso镜像文件，并更新系统？[Y/n]${RESET} "
				echo "${YELLOW}按回车键确认，输n拒绝。${RESET}"
				echo "若您不想通过此ISO来升级，则请输 ${YELLOW}n${RESET}拒绝下载,并使用microsoft windows update.[Y/n]"
				echo "请在更新完系统后，以管理员身份打开Powershell,并输入dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
				echo "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"
				echo "wsl --set-default-version 2"
				/mnt/c/WINDOWS/system32/control.exe /name Microsoft.WindowsUpdate
				echo "-------------------------------"
				read opt
				case $opt in
				y* | Y* | "")
					cd /mnt/c/Users/Public/Downloads/
					ISO_FILE_NAME='win10_2004_x64_tmoe.iso'
					TMOE_ISO_URL="https://webdav.tmoe.me/down/share/windows/20H1/${ISO_FILE_NAME}"
					if [ ! -e "${ISO_FILE_NAME}" ]; then
						echo "即将为您下载10.0.19041 iso镜像文件..."
						echo "目录C:\Users\Public\Downloads"
						aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "${ISO_FILE_NAME}" 'https://webdav.tmoe.me/down/share/windows/20H1/${ISO_FILE_NAME}' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "${ISO_FILE_NAME}" 'https://cdn.tmoe.me/windows/20H1/${ISO_FILE_NAME}'
					fi
					/mnt/c/WINDOWS/system32/cmd.exe /c "start ."
					echo "请手动运行${YELLOW}setup.exe${RESET}"
					/mnt/c/WINDOWS/explorer.exe ${ISO_FILE_NAME}
					echo "按任意键继续"
					echo "${YELLOW}Press any key to continue! ${RESET}"
					read
					;;
				n* | N*) echo "skipped." ;;
				*) echo "Invalid choice. skipped." ;;
				esac
			fi
		fi

	else
		WSL=""
	fi

	if [ ! -z "${LINUX_DISTRO}" ]; then
		if grep -q 'PRETTY_NAME=' /etc/os-release; then
			OSRELEASE="$(cat /etc/os-release | grep 'PRETTY_NAME=' | head -n 1 | cut -d '=' -f 2)"
		else
			OSRELEASE="$(cat /etc/os-release | grep -v 'VERSION' | grep 'ID=' | head -n 1 | cut -d '=' -f 2)"
		fi

		if (whiptail --title "您想要对这个小可爱做什么 " --yes-button "Tool" --no-button "Manager" --yesno "检测到您使用的是${OSRELEASE} ${WSL}\n您是想要启动software安装工具，\n还是system管理工具？\nDo you want to start the software installation tool \nor the system manager? ♪(^∇^*) " 0 50); then
			#bash <(curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh')
			if [ -e "${TMOE_GIT_DIR}/tool.sh" ]; then
				if [ $(command -v sudo) ]; then
					sudo -E bash ${TMOE_GIT_DIR}/tool.sh
				else
					su -c "bash ${TMOE_GIT_DIR}/tool.sh"
				fi
			else
				if [ "${LINUX_DISTRO}" = "alpine" ] || [ ! $(command -v curl) ]; then
					wget -O /tmp/.tmoe-linux-tool.sh 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
				else
					curl -Lv -o /tmp/.tmoe-linux-tool.sh 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
				fi
				source /tmp/.tmoe-linux-tool.sh
			fi
			exit 0
		fi
	fi
}
########################################
notes_of_tmoe_package_installation() {
	echo "正在${YELLOW}安装${RESET}相关${GREEN}软件包${RESET}及其${BLUE}依赖...${RESET}"
	echo "${GREEN}${TMOE_INSTALLATON_COMMAND}${BLUE}${DEPENDENCIES}${RESET}"
	echo "如需${BOLD}${RED}卸载${RESET}${RESET}，请${YELLOW}手动${RESET}输${RED}${TMOE_REMOVAL_COMMAND}${RESET}${BLUE}${DEPENDENCIES}${RESET}"
}
#####################
check_release_version() {
	CHROOT_NOTE=''
	if [ "${LINUX_DISTRO}" = "Android" ]; then
		OSRELEASE="Android"
		CHROOT_NOTE='(已向Android开放)'
	elif grep -q 'NAME=' /etc/os-release; then
		OSRELEASE=$(cat /etc/os-release | grep -v 'PRETTY' | grep 'NAME=' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
	elif grep -q 'ID=' /etc/os-release; then
		OSRELEASE=$(cat /etc/os-release | grep -v 'VERSION' | grep 'ID=' | head -n 1 | cut -d '=' -f 2)
	else
		OSRELEASE='GNU/Linux'
	fi
}
###################
android_termux() {
	TMOE_INSTALLATON_COMMAND='apt install -y'
	TMOE_REMOVAL_COMMAND='apt purge -y'
	DEPENDENCIES=""

	if [ ! -e ${PREFIX}/bin/pv ]; then
		DEPENDENCIES="${DEPENDENCIES} pv"
	fi

	if [ ! -e ${PREFIX}/bin/git ]; then
		DEPENDENCIES="${DEPENDENCIES} git"
	fi

	if [ ! -e ${PREFIX}/bin/termux-audio-info ]; then
		DEPENDENCIES="${DEPENDENCIES} termux-api"
	fi

	if [ ! -e ${PREFIX}/bin/pulseaudio ]; then
		DEPENDENCIES="${DEPENDENCIES} pulseaudio"
	fi

	if [ ! -e ${PREFIX}/bin/grep ]; then
		DEPENDENCIES="${DEPENDENCIES} grep"
	fi

	if [ ! -e ${PREFIX}/bin/aria2c ]; then
		DEPENDENCIES="${DEPENDENCIES} aria2"
	fi

	if [ ! -e ${PREFIX}/bin/proot ]; then
		DEPENDENCIES="${DEPENDENCIES} proot"
	fi

	if [ ! -e ${PREFIX}/bin/xz ]; then
		DEPENDENCIES="${DEPENDENCIES} xz-utils"
	fi

	if [ ! -e ${PREFIX}/bin/tar ]; then
		DEPENDENCIES="${DEPENDENCIES} tar"
	fi

	if [ ! -e ${PREFIX}/bin/whiptail ]; then
		DEPENDENCIES="${DEPENDENCIES} dialog"
	fi

	if [ ! -e ${PREFIX}/bin/pkill ]; then
		DEPENDENCIES="${DEPENDENCIES} procps"
	fi

	if [ ! -e ${PREFIX}/bin/curl ]; then
		DEPENDENCIES="${DEPENDENCIES} curl"
	fi

	if [ ! -z "${DEPENDENCIES}" ]; then
		if (("${ANDROID_VERSION}" >= '7')); then
			if ! grep -q '^deb.*edu.cn.*termux-packages-24' '/data/data/com.termux/files/usr/etc/apt/sources.list'; then
				echo "${YELLOW}检测到您当前使用的sources.list不是北外源,是否需要更换为北外源[Y/n]${RESET} "
				echo "更换后可以加快国内的下载速度,${YELLOW}按回车键确认，输n拒绝。${RESET}"
				echo "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .[Y/n]"
				read opt
				case $opt in
				y* | Y* | "")
					termux_tuna_sources_list
					;;
				n* | N*) echo "skipped." ;;
				*) echo "Invalid choice. skipped." ;;
				esac
			fi
		fi
		notes_of_tmoe_package_installation
		apt update
		apt install -y ${DEPENDENCIES}

	fi
	##The vnc sound repair script from andronix has been slightly modified and optimized.
	if ! grep -q 'anonymous=1' ${HOME}/../usr/etc/pulse/default.pa; then
		sed -i '/auth-ip-acl/d' ${HOME}/../usr/etc/pulse/default.pa
		sed -i '/module-native-protocol-tcp/d' ${HOME}/../usr/etc/pulse/default.pa
		#grep -q "anonymous" ${HOME}/../usr/etc/pulse/default.pa
		echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >>${HOME}/../usr/etc/pulse/default.pa
	fi
	#auth-ip-acl=127.0.0.1;192.168.0.0/16时允许局域网内其它设备连接。
	#auth-ip-acl不能是localhost，可以是127.0.0.1或0.0.0.0
	if ! grep -q "exit-idle-time = -1" ${HOME}/../usr/etc/pulse/daemon.conf; then
		sed -i '/exit-idle/d' ${HOME}/../usr/etc/pulse/daemon.conf
		echo "exit-idle-time = -1" >>${HOME}/../usr/etc/pulse/daemon.conf
	fi
	#exit-idle-time 可设为180

	if [ -e ${DEBIAN_CHROOT}/root/.vnc/xstartup ]; then
		grep -q "PULSE_SERVER" ${DEBIAN_CHROOT}/root/.vnc/xstartup || sed -i '2 a\export PULSE_SERVER=127.0.0.1' ${DEBIAN_CHROOT}/root/.vnc/xstartup
	fi

	if [ -e ${PREFIX}/bin/debian ]; then
		grep -q "pulseaudio" ${PREFIX}/bin/debian || sed -i '3 a\pulseaudio --start' ${PREFIX}/bin/debian
	fi

	if [ ! -e ${PREFIX}/bin/which ]; then
		echo "apt install -y debianutils"
		apt install -y debianutils
	fi
}
########################################################################
#-- 主菜单 main menu
#\n更新日志：0509升级备份与还原功能,0510修复sudo,\n0514支持最新的ubuntu20.10,0720优化跨架构运行
tmoe_manager_main_menu() {
	TMOE_OPTION=$(
		whiptail --title "Tmoe manager running on ${OSRELEASE}(2020-09)" --backtitle "$(
			base64 -d <<-'DoYouWantToSeeWhatIsInside'
				6L6TZGViaWFuLWnlkK/liqjmnKznqIvluo8sVHlwZSBkZWJpYW4taSB0byBzdGFydCB0aGUgdG9v
				bCzokIzns7vnlJ/niannoJTnqbblkZgK
			DoYouWantToSeeWhatIsInside
		)" --menu "Please use the enter and arrow keys to operate.\n请使用方向键和回车键进行操作" 0 50 0 \
			"1" "🍀 proot容器(๑•̀ㅂ•́)و✧" \
			"2" "🌸 chroot容器${CHROOT_NOTE}" \
			"3" "🌏 locales/区域/ロケール/로케일" \
			"4" "🍳 mirror sources镜像源(清华,北外,中科大)" \
			"5" "📱 Android-termux专区" \
			"6" "🍬 novnc:web端控制的vnc客户端" \
			"7" "🌈 Configure zsh美化终端" \
			"8" "🍹 backup 备份" \
			"9" "🔯 restore 还原/恢复" \
			"10" "🍧 *°▽°*update更新" \
			"11" "🍩 FAQ常见问题" \
			"12" "🍒 赋予proot容器真实root权限" \
			"13" "💔 remove 移除" \
			"0" "🌚 exit 退出" \
			3>&1 1>&2 2>&3
	)
	#"5" "GUI & audio 图形界面与音频" \
	##########################
	case "${TMOE_OPTION}" in
	0 | "") exit 0 ;;
	1) install_proot_container ;;
	2) install_chroot_container ;;
	3) tmoe_locale_settings ;;
	4) tmoe_switch_sources_list ;;
	5) android_termux_tmoe_area ;;
	6) install_web_novnc ;;
	7) start_tmoe_zsh_manager ;;
	8) backup_system ;;
	9) restore_gnu_linux_container ;;
	10) update_tmoe_linux_manager ;;
	11) frequently_asked_questions ;;
	12) enable_root_mode ;;
	13) tmoe_linux_remove_function ;;
	esac
}
##########################
start_tmoe_zsh_manager() {
	TMOE_ZSH_SCRIPT="${HOME}/.config/tmoe-zsh/git/zsh.sh"
	if [ $(command -v zsh-i) ]; then
		zsh-i
	elif [ -e "${TMOE_ZSH_SCRIPT}" ]; then
		bash ${TMOE_ZSH_SCRIPT}
	else
		bash -c "$(curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh')"
	fi
}
##########
remove_termux_linux_manager() {
	cd ${PREFIX}/bin
	echo "${RED}rm -rv ${HOME}/.config/tmoe-linux ${PREFIX}/bin/debian-i${RESET}"
	DEPENDENCIES='git aria2 pv wget xz newt whiptail dialog'
	echo "${RED}${TMOE_REMOVAL_COMMAND} ${DEPENDENCIES}${RESET}"
	do_you_want_to_continue
	rm -rfv rm -rv ${HOME}/.config/tmoe-linux debian-i
	${TMOE_REMOVAL_COMMAND} ${DEPENDENCIES}
	exit 1
}
############
tmoe_linux_remove_function() {
	RETURN_TO_WHERE='tmoe_linux_remove_function'
	OPTION=$(whiptail --title "Removable items" --menu "您想要移除哪个项目？\nWhich item do you want to remove?" 0 50 0 \
		"0" "🌚 Back to the main menu 返回主菜单" \
		"1" "Container 容器" \
		"2" "Tmoe-linux manager" \
		3>&1 1>&2 2>&3)
	##############################
	case "${OPTION}" in
	0 | "") tmoe_manager_main_menu ;;
	1) remove_gnu_linux_container ;;
	2) remove_termux_linux_manager ;;
	esac
	##########
	press_enter_to_return
	tmoe_linux_remove_function
}
##########
tmoe_locale_settings() {
	TMOE_LOCALE_FILE=${HOME}/.config/tmoe-linux/locale.txt
	if [ -e "${TMOE_LOCALE_FILE}" ]; then
		TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
		TMOE_LOCALE_STATUS="Your current locale is ${TMOE_LANG}"
	elif [ ${LINUX_DISTRO} != 'Android' ]; then
		TMOE_LANG=$(locale | grep 'LANG=' | cut -d '=' -f 2 | cut -d '"' -f 2)
		TMOE_LOCALE_STATUS="Your current locale is ${TMOE_LANG}"
	else
		TMOE_LOCALE_STATUS="Your current locale is default."
	fi

	#######################
	CONTAINER_LOCALE=$(
		whiptail --title "LOCALE SETTINGS" \
			--menu "${TMOE_LOCALE_STATUS}" 0 0 0 \
			"0" "🌚 Back 返回" \
			"00" "Edit manually手动编辑" \
			"01" "af_ZA.UTF-8 Afrikaans_South Africa" \
			"02" "sq_AL.UTF-8 Albanian_Albania" \
			"03" "ar_SA.UTF-8 Arabic_Saudi Arabia" \
			"04" "eu_ES.UTF-8 Basque_Spain" \
			"05" "be_BY.UTF-8 Belarusian_Belarus" \
			"06" "bs_BA.UTF-8 Bosnian (Latin)" \
			"07" "bg_BG.UTF-8 Bulgarian_Bulgaria" \
			"08" "ca_ES.UTF-8 Catalan_Spain" \
			"09" "hr_HR.UTF-8 Croatian_Croatia" \
			"10" "$(echo emhfQ04uVVRGLTgK | base64 -d) Chinese_China中国" \
			"11" "zh_TW.UTF-8 Chinese_Taiwan臺灣" \
			"12" "cs_CZ.UTF-8 Czech_Czech Republic" \
			"13" "da_DK.UTF-8 Danish_Denmark" \
			"14" "nl_NL.UTF-8 Dutch_Netherlands" \
			"15" "en_US.UTF-8 English_America" \
			"16" "et_EE.UTF-8 Estonian_Estonia" \
			"17" "fa_IR.UTF-8 Farsi_Iran" \
			"18" "fil_PH.UTF-8 Filipino_Philippines" \
			"19" "fi_FI.UTF-8 Finnish_Finland" \
			"20" "fr_FR.UTF-8 French_France" \
			"21" "ga.UTF-8 Gaelic;Scottish" \
			"22" "gl_ES.UTF-8 Galician_Spain" \
			"23" "ka_GE.UTF-8 Georgian_Georgia" \
			"24" "de_DE.UTF-8 German_Germany" \
			"25" "el_GR.UTF-8 Greek_Greece" \
			"26" "gu.UTF-8 Gujarati_India" \
			"27" "he_IL.utf8 Hebrew_Israel" \
			"28" "hi_IN.UTF-8 Hindi" \
			"29" "hu.UTF-8 Hungarian_Hungary" \
			"30" "is_IS.UTF-8 Icelandic_Iceland" \
			"31" "id_ID.UTF-8 Indonesian_indonesia" \
			"32" "it_IT.UTF-8 Italian_Italy" \
			"33" "ja_JP.UTF-8 Japanese_Japan日本" \
			"34" "kn_IN.UTF-8 Kannada" \
			"35" "km_KH.UTF-8 Khmer" \
			"36" "ko_KR.UTF-8 Korean_Korea한국" \
			"37" "lo_LA.UTF-8 Lao_Laos" \
			"38" "lt_LT.UTF-8 Lithuanian_Lithuania" \
			"39" "lat.UTF-8 Latvian_Latvia" \
			"40" "ml_IN.UTF-8 Malayalam_India.x-iscii-ma" \
			"41" "ms_MY.UTF-8 Malay_malaysia" \
			"42" "mi_NZ.UTF-8 Ngai_Tahu" \
			"43" "mi_NZ.UTF-8 Waikoto_Uni" \
			"44" "mn.UTF-8 Cyrillic_Mongolian" \
			"45" "no_NO.UTF-8 Norwegian_Norway" \
			"46" "nn_NO.UTF-8 Norwegian-Nynorsk_Norway" \
			"47" "pl.UTF-8 Polish_Poland" \
			"48" "pt_PT.UTF-8 Portuguese_Portugal" \
			"49" "pt_BR.UTF-8 Portuguese_Brazil(Brazil) " \
			"50" "ro_RO.UTF-8 Romanian_Romania" \
			"51" "ru_RU.UTF-8 Russian_Russia" \
			"52" "mi_NZ.UTF-8 Maori" \
			"53" "sr_CS.UTF-8 Bosnian(Cyrillic),Serbian" \
			"54" "sk_SK.UTF-8 Slovak_Slovakia" \
			"55" "sl_SI.UTF-8 Slovenian_Slovenia" \
			"56" "so_SO.UTF-8 Somali Somali" \
			"57" "es_ES.UTF-8 Spanish_Spain(International)" \
			"58" "sv_SE.UTF-8 Swedish_Sweden" \
			"59" "tl.UTF-8 Philippines" \
			"60" "ta_IN.UTF-8 English_Australia" \
			"61" "th_TH.UTF-8 Thai_Thailand" \
			"62" "tr_TR.UTF-8 Turkish_Turkey" \
			"63" "uk_UA.UTF-8 Ukrainian_Ukraine" \
			"63" "vi_VN.UTF-8 Vietnamese_Vietnam" \
			3>&1 1>&2 2>&3
	)
	##########################
	case "${CONTAINER_LOCALE}" in
	0 | "") tmoe_manager_main_menu ;;
	00) edit_tmoe_locale_file_manually ;;
	01) TMOE_LANG='af_ZA.UTF-8' ;;
	02) TMOE_LANG='sq_AL.UTF-8' ;;
	03) TMOE_LANG='ar_SA.UTF-8' ;;
	04) TMOE_LANG='eu_ES.UTF-8' ;;
	05) TMOE_LANG='be_BY.UTF-8' ;;
	06) TMOE_LANG='bs_BA.UTF-8' ;;
	07) TMOE_LANG='bg_BG.UTF-8' ;;
	08) TMOE_LANG='ca_ES.UTF-8' ;;
	09) TMOE_LANG='hr_HR.UTF-8' ;;
	10) TMOE_LANG="$(echo emhfQ04uVVRGLTgK | base64 -d)" ;;
	11) TMOE_LANG='zh_TW.UTF-8' ;;
	12) TMOE_LANG='cs_CZ.UTF-8' ;;
	13) TMOE_LANG='da_DK.UTF-8' ;;
	14) TMOE_LANG='nl_NL.UTF-8' ;;
	15) TMOE_LANG='en_US.UTF-8' ;;
	16) TMOE_LANG='et_EE.UTF-8' ;;
	17) TMOE_LANG='fa_IR.UTF-8' ;;
	18) TMOE_LANG='fil_PH.UTF-8' ;;
	19) TMOE_LANG='fi_FI.UTF-8' ;;
	20) TMOE_LANG='fr_FR.UTF-8' ;;
	21) TMOE_LANG='ga.UTF-8' ;;
	22) TMOE_LANG='gl_ES.UTF-8' ;;
	23) TMOE_LANG='ka_GE.UTF-8' ;;
	24) TMOE_LANG='de_DE.UTF-8' ;;
	25) TMOE_LANG='el_GR.UTF-8' ;;
	26) TMOE_LANG='gu.UTF-8' ;;
	27) TMOE_LANG='he_IL.utf8' ;;
	28) TMOE_LANG='hi_IN.UTF-8' ;;
	29) TMOE_LANG='hu.UTF-8' ;;
	30) TMOE_LANG='is_IS.UTF-8' ;;
	31) TMOE_LANG='id_ID.UTF-8' ;;
	32) TMOE_LANG='it_IT.UTF-8' ;;
	33) TMOE_LANG='ja_JP.UTF-8' ;;
	34) TMOE_LANG='kn_IN.UTF-8' ;;
	35) TMOE_LANG='km_KH.UTF-8' ;;
	36) TMOE_LANG='ko_KR.UTF-8' ;;
	37) TMOE_LANG='lo_LA.UTF-8' ;;
	38) TMOE_LANG='lt_LT.UTF-8' ;;
	39) TMOE_LANG='lat.UTF-8' ;;
	40) TMOE_LANG='ml_IN.UTF-8' ;;
	41) TMOE_LANG='ms_MY.UTF-8' ;;
	42) TMOE_LANG='mi_NZ.UTF-8' ;;
	43) TMOE_LANG='mi_NZ.UTF-8' ;;
	44) TMOE_LANG='mn.UTF-8' ;;
	45) TMOE_LANG='no_NO.UTF-8' ;;
	46) TMOE_LANG='nn_NO.UTF-8' ;;
	47) TMOE_LANG='pl.UTF-8' ;;
	48) TMOE_LANG='pt_PT.UTF-8' ;;
	49) TMOE_LANG='pt_BR.UTF-8' ;;
	50) TMOE_LANG='ro_RO.UTF-8' ;;
	51) TMOE_LANG='ru_RU.UTF-8' ;;
	52) TMOE_LANG='mi_NZ.UTF-8' ;;
	53) TMOE_LANG='sr_CS.UTF-8' ;;
	54) TMOE_LANG='sk_SK.UTF-8' ;;
	55) TMOE_LANG='sl_SI.UTF-8' ;;
	56) TMOE_LANG='so_SO.UTF-8' ;;
	57) TMOE_LANG='es_ES.UTF-8' ;;
	58) TMOE_LANG='sv_SE.UTF-8' ;;
	59) TMOE_LANG='tl.UTF-8' ;;
	60) TMOE_LANG='ta_IN.UTF-8' ;;
	61) TMOE_LANG='th_TH.UTF-8' ;;
	62) TMOE_LANG='tr_TR.UTF-8' ;;
	63) TMOE_LANG='uk_UA.UTF-8' ;;
	64) TMOE_LANG='vi_VN.UTF-8' ;;
	esac
	###############
	case ${TMOE_LANG} in
	"") tmoe_manager_main_menu ;;
	esac
	##############
	TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
	TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)

	mkdir -p ${HOME}/.config/tmoe-linux
	cd ${HOME}/.config/tmoe-linux
	echo ${TMOE_LANG} >locale.txt
	if [ $(command -v debian) ]; then
		PROOT_LANG=$(cat $(command -v debian) | grep LANG= | cut -d '"' -f 2 | cut -d '=' -f 2 | tail -n 1)
	fi
	if [ -e "${DEBIAN_CHROOT}" ]; then
		TMOE_SCRIPT_PATH=${DEBIAN_CHROOT}
	else
		if [ "${LINUX_DISTRO}" = "Android" ]; then
			#echo "Detected that you have not installed a container."
			echo "${RED}Congratulations${RESET},your current locale has been modified to ${BLUE}${TMOE_LANG}${RESET}"
			press_enter_to_return
			tmoe_manager_main_menu
		else
			TMOE_SCRIPT_PATH=''
		fi
	fi
	if [ ! -z "${PROOT_LANG}" ]; then
		sed -i "s@${PROOT_LANG}@${TMOE_LANG}@" $(command -v debian)
	fi
	cd ${TMOE_SCRIPT_PATH}/usr/local/bin/
	VNC_LANG=$(cat startvnc 2>/dev/null | grep LANG= | cut -d '"' -f 2 | cut -d '=' -f 2 | tail -n 1)
	if [ ! -z "${VNC_LANG}" ]; then
		sed -i "s@${VNC_LANG}@${TMOE_LANG}@" startvnc 2>/dev/null
	fi
	X_LANG=$(cat startxsdl 2>/dev/null | grep LANG= | cut -d '"' -f 2 | cut -d '=' -f 2 | tail -n 1)
	if [ ! -z "${X_LANG}" ]; then
		sed -i "s@${X_LANG}@${TMOE_LANG}@" startxsdl 2>/dev/null
	fi
	X11VNC_LANG=$(cat startx11vnc 2>/dev/null | grep LANG= | cut -d '"' -f 2 | cut -d '=' -f 2 | tail -n 1)
	if [ ! -z "${X11VNC_LANG}" ]; then
		sed -i "s@${X11VNC_LANG}@${TMOE_LANG}@" startx11vnc 2>/dev/null
	fi
	#DEBIAN_LOCALE_GEN=$(cat debian-i | grep '"/etc/locale.gen"; then' | head -n 1 | cut -d '"' -f 2 | cut -d '^' -f 2)
	#if [ ! -z "${DEBIAN_LOCALE_GEN}" ]; then
	#	sed -i "s@${DEBIAN_LOCALE_GEN}@${TMOE_LANG_HALF}@" debian-i
	#fi
	if [ -e "${DEBIAN_CHROOT}" ]; then
		mkdir -p ${DEBIAN_CHROOT}/usr/local/etc/tmoe-linux
		cd ${DEBIAN_CHROOT}/usr/local/etc/tmoe-linux
		cp -f ${HOME}/.config/tmoe-linux/locale.txt ./
		chmod +r locale.txt
	fi
	set_debian_default_locale
	#cd ${TMOE_SCRIPT_PATH}/etc
	if [ "${LINUX_DISTRO}" != "Android" ]; then
		if [ ! -z "${TMOE_SCRIPT_PATH}" ]; then
			TMOE_SCRIPT_PATH=''
			set_debian_default_locale
			source /etc/default/locale
		fi
		mkdir -p /usr/local/etc/tmoe-linux/
		cd /usr/local/etc/tmoe-linux/
		cp -f ${HOME}/.config/tmoe-linux/locale.txt ./
		chmod +r locale.txt
		cd /etc
		install_ubuntu_language_pack
		sed -i 's@^@#@g' locale.gen 2>/dev/null
		sed -i 's@##@#@g' locale.gen 2>/dev/null
		if ! grep -qi "^${TMOE_LANG_HALF}" locale.gen; then
			sed -i "s/^#.*${TMOE_LANG}.*/${TMOE_LANG} UTF-8/" locale.gen 2>/dev/null
		fi
		mv -f locale.gen locale.gen.bak
		sort -um locale.gen.bak >locale.gen
		if [ -z "${TMOE_SCRIPT_PATH}" ]; then
			locale-gen ${TMOE_LANG} 2>/dev/null
		fi
		echo "Please try running ${GREEN}source /etc/default/locale${RESET}"
		echo "請手動執行${GREEN}source /etc/default/locale${RESET}以刷新locale設定"
		echo "若无法生效，则请执行${GREEN}export LANG=${TMOE_LANG}${RESET}"
	fi
	#############
	echo "${RED}Congratulations${RESET},your current locale has been modified to ${BLUE}${TMOE_LANG}${RESET}"
	press_enter_to_return
	#tmoe_manager_main_menu
	tmoe_locale_settings
}
#####################
set_debian_default_locale() {
	cd ${TMOE_SCRIPT_PATH}/etc/default
	if grep -q 'LANG=' locale; then
		DEFAULT_LANG=$(cat locale | grep LANG= | cut -d '"' -f 2 | cut -d '=' -f 2 | tail -n 1 | cut -d '.' -f 1)
		DEFAULT_LANG_QUATER=$(echo ${DEFAULT_LANG} | cut -d '_' -f 1)
		sed -i "s@${DEFAULT_LANG}@${TMOE_LANG_HALF}@g" locale
		sed -i "s@${TMOE_LANG_HALF}:${DEFAULT_LANG_QUATER}@${TMOE_LANG_HALF}:${TMOE_LANG_QUATER}@g" locale
		source ./locale
	else
		if [ "$(pwd)" != "${HOME}" ]; then
			cp locale locale.bak 2>/dev/null
			sed -i 's@^@#&@g' locale
			sed -i 's@##@#@g' locale
			cat >>locale <<-EOF
				LANG=${TMOE_LANG_HALF}.UTF-8
				LANGUAGE=${TMOE_LANG_HALF}:${TMOE_LANG_QUATER}
				LC_ALL=${TMOE_LANG_HALF}.UTF-8
			EOF
		fi
	fi
}
##########
install_ubuntu_language_pack() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ ! -e "/usr/sbin/locale-gen" ]; then
			apt update
			apt install -y locales
		fi
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			#if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
			apt install -y ^language-pack-${TMOE_LANG_QUATER} 2>/dev/null
			#fi
			echo "You are using ubuntu and you can try running ${GREEN}sudo apt install \$(check-language-support)${RESET}"
			echo "檢測到您正在使用Ubuntu,您可以手動執行${GREEN}sudo apt install \$(check-language-support)${RESET}來安裝第三方程式的語言支持包"
		fi
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
			dnf install -y --skip-broken "glibc-langpack-${TMOE_LANG_QUATER}*" glibc-minimal-langpack || yum install -y --skip-broken "glibc-langpack-${TMOE_LANG_QUATER}*"
		fi
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
			pacman -S glibc
		fi
	fi
}
#############
edit_tmoe_locale_file_manually() {
	if [ -e "/etc/locale.gen" ]; then
		if [ $(command -v editor) ]; then
			editor /etc/default/locale
			editor /etc/locale.gen
		else
			nano /etc/default/locale
			nano /etc/locale.gen
		fi
	fi
	if [ $(command -v debian) ]; then
		if [ $(command -v editor) ]; then
			editor $(command -v debian)
		else
			nano $(command -v debian)
		fi
	fi
	if [ -e "${DEBIAN_CHROOT}/etc" ]; then
		if [ $(command -v editor) ]; then
			editor ${DEBIAN_CHROOT}/etc/default/locale
			editor ${DEBIAN_CHROOT}/etc/locale.gen
		else
			nano ${DEBIAN_CHROOT}/etc/default/locale
			nano ${DEBIAN_CHROOT}/etc/locale.gen
		fi
	fi
	press_enter_to_return
	#tmoe_manager_main_menu
	tmoe_locale_settings
}
############
vnc_can_not_call_pulse_audio() {
	echo "若您启动VNC后，发现无音频。首先请确保您的termux为最新版本，并安装了termux:api"
	echo "若您的宿主机为Android系统，且发现音频服务无法启动，请在启动完成后，新建一个termux session会话窗口，然后手动在termux原系统里输${GREEN}pulseaudio -D${RESET}来启动音频服务后台进程"
	echo "您亦可输${GREEN}pulseaudio --start${RESET}"
	echo "若您无法记住该命令，则只需输${GREEN}debian${RESET}"
	echo "按回车键自动启动音频服务"
	do_you_want_to_continue
	pulseaudio --start
}
###############
creat_start_linux_deploy_sh() {
	cd $PREFIX/bin
	echo ${CUT_TARGET}
	cat >"${CUT_TARGET}" <<-'EndofFile'
		#!/data/data/com.termux/files/usr/bin/env bash
		pulseaudio --start 2>/dev/null &
		echo "pulseaudio服务启动完成，将为您自动打开LinuxDeploy,请点击“启动”。"
		am start -n ru.meefik.linuxdeploy/ru.meefik.linuxdeploy.Launcher
		sleep 6
		am start -n com.realvnc.viewer.android/com.realvnc.viewer.android.app.ConnectionChooserActivity
	EndofFile
}
##############
linux_deploy_pulse_server() {
	echo "若您需要在Linux Deploy上配置VNC的音频转发功能，请使用本工具(Tmoe-linux tool)覆盖安装桌面环境"
	echo "您在安装Linux deploy的chroot容器前，可以将安装类型修改为目录，安装路径修改为/data/data/ru.meefik.linuxdeploy/linux"
	echo "脚本用法：ssh连接后，输入apt install -y curl;bash <(curl -L gitee.com/mo2/linux/raw/2/2)"
	#echo "覆盖安装之后，您需要通过本工具进行VNC和音频服务的配置"
	echo "接下来您需要设定一个您独有的启动命令，例如startl"
	echo "您之后可以在termux里输入此命令来启动Linux Deploy以及音频服务"
	do_you_want_to_continue
	TARGET=$(whiptail --inputbox "请自定义启动命令名称\n Please enter the command name." 12 50 --title "COMMAND" 3>&1 1>&2 2>&3)
	CUT_TARGET="$(echo ${TARGET} | head -n 1 | cut -d ' ' -f 1)"
	if [ -z "${CUT_TARGET}" ]; then
		echo "命令名称不能为空！！！"
	else
		creat_start_linux_deploy_sh
	fi
	if [ ! -z ${CUT_TARGET} ]; then
		chmod +x ${CUT_TARGET}
		ls -lh ${PREFIX}/bin/${CUT_TARGET}
		echo "Congratulations!配置成功，您之后可以输${CUT_TARGET}来启动"
	else
		echo "检测到您取消了操作"
	fi
}
##########################
frequently_asked_questions() {
	RETURN_TO_WHERE=frequently_asked_questions
	# 15 60 5
	TMOE_FAQ=$(whiptail --title "FAQ(よくある質問)" --menu \
		"您有哪些疑问？\nWhat questions do you have?" 0 50 0 \
		"1" "About auto conf(关于自动配置)" \
		"2" "VNC无法调用音频" \
		"3" "给Linux Deploy配置VNC音频" \
		"4" "disable qemu(禁用以适用于向下兼容)" \
		"0" "🌚 Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${TMOE_FAQ}" in
	0 | "") tmoe_manager_main_menu ;;
	1) questions_about_tmoe_automatic_configuration ;;
	2) vnc_can_not_call_pulse_audio ;;
	3) linux_deploy_pulse_server ;;
	4) disable_qemu_user_static ;;
	esac
	#############
	press_enter_to_return
	frequently_asked_questions
}
###########################
questions_about_tmoe_automatic_configuration() {
	cat <<-ENDOFFAQ
		    Q:${YELLOW}为什么会自动修改termux的配色、字体和小键盘布局${RESET}
			Why the color, font and keyboard layout of termux will be automatically modified during installation.
		    
			A:只有当${HOME}/.termux目录下的colors.properties、font.ttf和termux.properties${RED}不存在时${RESET}才会自动配置哦！
			Only when the relevant file in the ~/.termux directory does not exist will it be automatically configured.

			早期会强制更换字体,并自动备份,现在只有当字体不存在时才会自动配置。
			有人跟我反馈说字体显示异常。
			这是因为仅部分字体支持zsh的powerlevel 10k主题的特殊字符。

			而配色和键盘一直以来都是只有当文件不存在时，才会自动配置。

			由于本工具严重依赖方向键和回车键，因此修改默认布局稍微有点必要呢！
			您只需要执行${GREEN}rm ${HOME}/.termux/termux.properties${RESET}即可删除配置并还原回默认布局。
			You can type ${GREEN}rm ~/.termux/termux.properties${RESET} to delete it and restore to default.
			-----------------------
			Q:${YELLOW}为什么每次会自动加载EULA?${RESET}
		    
			A:添加许可协议是为了避免不必要的麻烦。
			作为一个开源项目，您可以随时审查其中的代码，而不必过多担心恶意代码。
			-----------------------
			Q:${YELLOW}为什么安装时会自动显示git仓库的链接?${RESET}
		    
			A:因为开源项目花了开发者很长的时间，希望大家能尊重原开发者。
			换位思考一下：假如你辛辛苦苦录制的视频被别人盗了，没有人知道那个视频真正的原作者是谁，而你的努力最终只能付诸于东流。
			听说尊重他人的劳动成果，会让世界变得更加美好呢！φ(≧ω≦*)♪
			-----------------------
	ENDOFFAQ
}
###########################
install_proot_container() {
	TMOE_CHROOT='false'
	install_gnu_linux_container
	#sed -i 's@^command+=" --link2sy@#&@' $(command -v debian)
}
##########################
notes_of_chroot() {
	#echo "This feature currently only supports GNU/Linux systems and is still in beta."
	#echo "本功能目前仅对GNU/Linux系统测试开放。"
	echo "If you find that some directories cannot be unmounted forcibly before removing the container,then please restart your device."
	echo "移除容器前若发现部分已挂载目录无法强制卸载，请重启设备再卸载chroot容器，防止已挂载目录被误删！"
	case ${LINUX_DISTRO} in
	Android)
		echo Android :${ANDROID_VERSION}
		echo "$(getprop ro.product.model)"
		su -c "ls ${HOME} >/dev/null"
		if [ "$?" != "0" ]; then
			echo '检测到root权限授予失败，您无法安装chroot容器'
			#else
			#	echo "检测到您使用的是Android系统"
			#	echo "非常抱歉，本功能仅适配GNU/Linux系统，暂未适配Android。"
			#echo "您在安装chroot容器前必须知悉已挂载目录无法强制卸载的严重性！"
			#echo "Android系统请换用proot容器。"
			press_enter_to_return
			tmoe_manager_main_menu
		else
			if [ ! "$(command -v sudo)" ] && [ ! "$(command -v tsu)" ]; then
				echo "${GREEN}apt install -y${RESET} ${BLUE}tsu${RESET}"
				echo "You can type ${RED}apt purge${RESET} ${BLUE}tsu${RESET} to remove it."
				apt update
				apt install -y tsu
			fi
		fi
		;;
	*)
		echo "由于在测试chroot容器的过程中出现了部分已挂载的目录${RED}无法强制卸载${RESET}的情况，故建议您换用${BLUE}docker${RESET}容器。"
		echo "We recommend that you run ${BLUE}docker${RESET} containers on GNU/Linux system instead of ${RED}chroot${RESET} containers."
		;;
	esac
	#else
	#fi
}
#############
install_chroot_container() {
	notes_of_chroot
	chroot_install_debian
}
########################
startvnc_or_enter_the_container() {
	if [ -e "${DEBIAN_CHROOT}/usr/local/bin/startvnc" ]; then
		cat <<-EOFVNC
			You can type ${GREEN}startvnc${RESET} to start ${BLUE}tight/tigervnc server${RESET},type ${RED}stopvnc${RESET} to stop it.
			You can also type ${GREEN}debian-i${RESET} to start ${BLUE}Tmoe-linux tool.${RESET}
		EOFVNC
		if [ "${LINUX_DISTRO}" = 'Android' ]; then
			echo "在Android宿主机的Termux原系统下输${GREEN}startvnc${RESET}将同时启动Android版Realvnc viewer和${DEBIAN_FOLDER}容器内的tight或tiger vnc服务，输${GREEN}debian${RESET}仅支持进入${BLUE}${DEBIAN_FOLDER}容器${RESET}。"
		fi
		startx11vnc
	else
		cat <<-EOFDEB
			You can type ${GREEN}debian${RESET} to enter the ${BLUE}${DEBIAN_FOLDER} container${RESET}.
			You can also type ${GREEN}debian-i${RESET} to start ${BLUE}Tmoe-linux tool${RESET}.
		EOFDEB
		debian
	fi
}
#######################
install_gnu_linux_container() {
	#此处不能用变量debian_chroot
	if [ -d ~/${DEBIAN_FOLDER} ]; then
		if (whiptail --title "检测到您已安装${ROOTFS_NAME}容器,请选择您需要执行的操作！" --yes-button 'Start启动o(*￣▽￣*)o' --no-button 'Reinstall重装(っ °Д °)' --yesno "${ROOTFS_NAME} has been installed, please choose what you need to do" 0 0); then
			#debian
			startvnc_or_enter_the_container
		else
			echo "${YELLOW}检测到您已安装${ROOTFS_NAME}容器,是否重新安装？[Y/n]${RESET} "
			echo "${YELLOW}您可以无需输"y"，直接按回车键确认。${RESET} "
			echo "Detected that you have ${ROOTFS_NAME} container installed, do you want to reinstall it?[Y/n]"
			read opt
			case $opt in
			y* | Y* | "")
				#bash ${PREFIX}/bin/debian-rm 2>/dev/null
				remove_gnu_linux_container
				if [ "$?" != '0' ]; then
					echo "${ROOTFS_NAME}容器没有被移除"
					press_enter_to_return
					tmoe_manager_main_menu
				else
					if [ -d "${HOME}/debian_arm64" ]; then
						echo '正在强制删除'
						remove_gnu_linux_container
					fi
					check_and_view_the_eula
				fi
				;;
			n* | N*)
				echo "skipped."
				press_enter_to_return
				tmoe_manager_main_menu
				;;
			*)
				echo "Invalid choice. skipped."
				press_enter_to_return
				tmoe_manager_main_menu
				;;
			esac
		fi

	else
		check_and_view_the_eula
		#bash -c "$(curl -fLsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh')"
	fi
}
################################################
################################################
enable_root_mode() {
	if [ "$(uname -o)" != "Android" ]; then
		echo "非常抱歉，本功能仅适配安卓系统。"
		echo "Linux系统请自行使用sudo，并修改相应目录的文件权限。"
		press_enter_to_return
		tmoe_manager_main_menu
	fi
	if (whiptail --title "您真的要开启root模式吗" --yes-button '好哒o(*￣▽￣*)o' --no-button '不要(っ °Д °；)っ' --yesno "开启后将无法撤销，除非重装容器，建议您在开启前进行备份。若您的手机存在外置tf卡，则在开启后，会挂载整张卡。若无法备份和还原，请输sudo debian-i启动本管理器。开启root模式后，绝对不要输破坏系统的危险命令！若在容器内输rm -rf /*删除根目录（格式化）命令，将有可能导致安卓原系统崩溃！！！请在本管理器内正常移除容器。" 10 60); then

		if [ ! -f ${PREFIX}/bin/tsu ]; then
			apt update
			apt install -y tsu
		fi
		#if ! grep -q 'pulseaudio --system' ${PREFIX}/bin/debian; then
		#sed -i '/pulseaudio/d' ${PREFIX}/bin/debian
		#	sed -i '4 c\pulseaudio --system --start' ${PREFIX}/bin/debian
		#fi
		ROOT_PERMISSION=$(sudo ls / 2>/dev/null)
		if [ -z "${ROOT_PERMISSION}" ]; then
			echo "${RED}ERROR!${RESET}未检测到root权限！"
			press_enter_to_return
			tmoe_manager_main_menu
		fi
		cd ${PREFIX}/bin/
		if ! grep -q 'sudo touch' startvnc; then
			sed -i 's/^touch ~/sudo &/' startvnc
			sed -i 's:/data/data/com.termux/files/usr/bin/debian:sudo &:' startvnc
			sed -i 's:/usr/local/bin/debian:sudo &:' startvnc
		fi
		###############
		sed -i 's@FAKE_PROOT_PROC=true@FAKE_PROOT_PROC=false@g' debian
		############
		if ! grep -q 'sudo touch' startxsdl; then
			sed -i 's/^touch ~/sudo &/' startxsdl
			sed -i 's:/data/data/com.termux/files/usr/bin/debian:sudo &:' startxsdl
		fi
		#pulseaudio --kill 2>/dev/null;pulseaudio --start 2>/dev/null;sudo debian
		#上面那个是Termux专用的，勿改。

		mkdir -p /data/data/com.termux/files/usr/etc/storage/
		cd /data/data/com.termux/files/usr/etc/storage/

		#rm -rf external-tf

		su -c 'ls /mnt/media_rw/*' 2>/dev/null || mkdir external-tf

		TFcardFolder=$(su -c 'ls /mnt/media_rw/| head -n 1')

		sudo ln -s /mnt/media_rw/${TFcardFolder} ./external-tf

		sed -i 's:/home/storage/external-1:/usr/etc/storage/external-tf:g' ${PREFIX}/bin/debian

		cd ${PREFIX}/etc/
		if [ ! -f profile ]; then
			echo "" >>profile
		fi
		cp -pf profile profile.bak

		sed -i '/alias debian=/d' profile
		sed -i '/alias debian-rm=/d' profile
		sed -i '/pulseaudio/d' $PREFIX/bin/debian
		#grep 'alias debian=' profile >/dev/null 2>&1 ||
		#sed -i '$ a\alias debian="sudo debian"' profile
		sed -i '$ a\alias debian="pulseaudio -D 2>/dev/null;sudo debian"' profile
		#grep 'alias debian-rm=' profile >/dev/null 2>&1 ||
		sed -i '$ a\alias debian-rm="sudo debian-rm"' profile
		#source profile >/dev/null 2>&1
		alias debian="sudo debian"
		alias debian-rm="sudo debian-rm"
		echo "Modifying folder permissions"
		echo "正在修改文件权限..."
		sudo chown root:root -R "${DEBIAN_CHROOT}" || su -c "chown root:root -R ${DEBIAN_CHROOT}"
		if [ -d "${HOME}/debian_armhf" ]; then
			sudo chown root:root -R "${HOME}/debian_armhf" || su -c "chown root:root -R ${HOME}/debian_armhf"
		fi

		echo "You have modified debian to run with root privileges, this action will destabilize debian."
		echo "If you want to restore, please reinstall container."
		echo "您已将container修改为以root权限运行，如需还原，请重新安装GNU/Linux 容器。"
		echo "The next time you start debian, it will automatically run as root."
		echo "下次启动容器，将自动以root权限运行。"

		echo 'Container will start automatically after 2 seconds.'
		echo '2s后将为您自动启动容器'
		echo 'If you do not need to display the task progress in the login interface, please manually add "#" (comment symbol) before the "ps -e" line in "~/.zshrc" or "~/.bashrc"'
		echo '如果您不需要在登录界面显示任务进程，请手动注释掉"~/.zshrc"里的"ps -e"'
		sleep 2
		pulseaudio -D 2>/dev/null
		sudo debian
		tmoe_manager_main_menu
		#############
	else
		tmoe_manager_main_menu
	fi
	#不要忘记此处的fi
}
################################
remove_gnu_linux_container() {
	cd ${HOME}
	unmount_proc_dev
	for i in dev dev/shm dev/pts proc sys root/termux root/tf root/sd storage/emulated/0/*; do
		if [ -e "${DEBIAN_CHROOT}/${i}" ]; then
			ls -lAh "${DEBIAN_CHROOT}/${i}" 2>/dev/null
		fi
	done
	unset i
	cat <<-EOF
		移除系统前，请先确保您已卸载容器挂载目录。
		建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者${RED}概不负责${RESET}！！！
		Before removing the system, make sure you have unmounted ${BLUE}dev dev/shm dev/pts proc sys root/sd${RESET} and other directories.
		It is recommended that you backup the entire system before removal. 
		If the data is lost due to improper operation, the developer is not responsible! 
	EOF
	#case ${TMOE_CHROOT} in
	#true)
	#	for i in dev proc sys root/sd tmp root/termux root/tf; do
	#		if [ -e "${DEBIAN_CHROOT}/${i}" ]; then
	#			su -c "chattr -i ${i}"
	#		fi
	#	done
	#	unset i
	#	;;
	#esac
	cat /proc/mounts | grep ${DEBIAN_FOLDER}
	ps -e | grep proot
	ps -e | grep startvnc
	echo "移除系统前，请先确保您已停止GNU/Linux容器。"
	pkill proot 2>/dev/null
	pgrep proot &>/dev/null
	if [ "$?" = "0" ]; then
		echo '检测到proot容器正在运行，请先输stopvnc或手动强制停止容器运行'
	fi
	ls -l ${DEBIAN_CHROOT}/root/termux/* 2>/dev/null
	if [ "$?" = "0" ]; then
		echo 'WARNING！检测到/root/termux无法强制卸载，您当前使用的可能是chroot容器'
		echo "若为误报，则请先停止容器进程，再手动移除${DEBIAN_CHROOT}/root/sd"
		echo '建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！'
		#echo '为防止数据丢失，建议您重启设备后再重试。'
		#echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		#echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
		#read
		#tmoe_manager_main_menu
	fi
	echo "若${ROOTFS_NAME}容器未停止运行，则建议你先手动在termux原系统中执行stopvnc，再进行移除操作。"
	echo "Detecting container size... 正在检测${ROOTFS_NAME}容器占用空间大小"
	${TMOE_PREFIX} du -sh ./${DEBIAN_FOLDER} --exclude=./${DEBIAN_FOLDER}/root/tf --exclude=./${DEBIAN_FOLDER}/root/sd --exclude=./${DEBIAN_FOLDER}/root/termux
	if [ ! -d ~/${DEBIAN_FOLDER} ]; then
		echo "${YELLOW}It is detected that you do not currently have GNU/Linux container installed. 检测到您当前未安装容器${RESET}"
	fi
	echo "Do you want to remove it?[Y/n]"
	echo "${YELLOW}按回车键确认移除 Press enter to remove.${RESET} "
	read opt
	case $opt in
	y* | Y* | "")
		chmod 777 -R ${DEBIAN_FOLDER} || sudo chmod 777 -R ${DEBIAN_FOLDER}
		rm -rfv "${DEBIAN_FOLDER}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/startx11vnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code ~/.config/tmoe-linux/across_architecture_container.txt ${PREFIX}/bin/startx11vnc 2>/dev/null || sudo rm -rfv "${DEBIAN_FOLDER}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/startx11vnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code ~/.config/tmoe-linux/across_architecture_container.txt ${PREFIX}/bin/startx11vnc 2>/dev/null
		if [ -d "${HOME}/debian_arm64" ]; then
			echo "检测到残留文件夹，正在移除..."
			chmod 777 -R "${HOME}/debian_arm64"
			rm -rf "${HOME}/debian_arm64" 2>/dev/null || sudo rm -rfv "${HOME}/debian_arm64"
		fi
		sed -i '/alias debian=/d' ${PREFIX}/etc/profile
		sed -i '/alias debian-rm=/d' ${PREFIX}/etc/profile
		source profile >/dev/null 2>&1
		echo 'The debian system has been removed. If you want to uninstall aria2, enter "apt remove aria2" or "apt purge aria2"'
		echo '移除完成，如需卸载aria2,请手动输apt remove aria2'
		echo "Deleted已删除"
		;;
	n* | N*) echo "skipped." ;;
	*) echo "Invalid choice. skipped." ;;
	esac
	echo "若需删除tmoe-linux管理器，则请输rm -f ${PREFIX}/bin/debian-i"
	echo 'If you want to reinstall, it is not recommended to remove the image file.'
	echo "${YELLOW}若您需要重装容器，则不建议删除镜像文件。${RESET} "
	#ls -lh ~/debian-sid-rootfs.tar.xz 2>/dev/null
	#ls -lh ~/debian-buster-rootfs.tar.xz 2>/dev/null
	#ls -lh ~/ubuntu-focal-rootfs.tar.xz 2>/dev/null
	#ls -lh ~/kali-rolling-rootfs.tar.xz 2>/dev/null
	#ls -lh ~/funtoo-1.3-rootfs.tar.xz 2>/dev/null
	cd ${HOME}
	ls -lh *-rootfs.tar.xz
	echo "${YELLOW}请问您是否需要删除容器镜像文件？[Y/n]${RESET} "
	echo "${RED}rm -fv ~/${ROOTFS_NAME}*rootfs.tar.xz${RESET}"
	echo "Do you need to delete the image file (${DEBIAN_FOLDER}*rootfs.tar.xz)?[Y/n]"
	read opt
	case $opt in
	y* | Y* | "")
		#rm -vf ~/debian-sid-rootfs.tar.xz ${PREFIX}/bin/debian-rm 2>/dev/null
		#rm -vf ~/debian-buster-rootfs.tar.xz 2>/dev/null
		#rm -vf ~/ubuntu-focal-rootfs.tar.xz 2>/dev/null
		#rm -vf ~/kali-rolling-rootfs.tar.xz 2>/dev/null
		#rm -vf ~/funtoo-1.3-rootfs.tar.xz 2>/dev/null
		#rm -vf *-rootfs.tar.xz 2>/dev/null
		rm -fv ~/${DEBIAN_FOLDER}-rootfs.tar.xz
		rm -fv ~/${ROOTFS_NAME}*rootfs.tar.xz
		echo "Deleted已删除"
		;;
	n* | N*) echo "${YELLOW}Skipped,已跳过，按回车键返回。${RESET} " ;;
	*) echo "${YELLOW}Invalid choice，skipped.已跳过，按回车键返回。${RESET} " ;;
	esac
	#tmoe_manager_main_menu

}
#######################
#######################
backup_filename() {
	TARGET_BACKUP_FILE_NAME=$(whiptail --inputbox "请自定义备份的文件名称\n Please enter the filename." 12 50 --title "FILENAME" 3>&1 1>&2 2>&3)
	TARGET_BACKUP_FILE_NAME="$(echo ${TARGET_BACKUP_FILE_NAME} | head -n 1 | cut -d ' ' -f 1)"
	echo $TARGET_BACKUP_FILE_NAME
	if [ -z ${TARGET_BACKUP_FILE_NAME} ]; then
		echo "文件名称不能为空！"
		press_enter_to_return
		backup_system
	fi
}
######################
backup_system() {
	unmount_proc_dev
	RETURN_TO_WHERE='backup_system'
	OPTION=$(whiptail --title "Backup System" --menu "Choose your option" 0 50 0 \
		"0" "🌚 Back to the main menu 返回主菜单" \
		"1" "Clean up container garbage清理容器垃圾" \
		"2" "backup container备份GNU/Linux容器" \
		"3" "备份Termux" \
		"4" "使用Timeshift备份宿主机系统" \
		3>&1 1>&2 2>&3)
	#########################################
	case "${OPTION}" in
	0 | "") tmoe_manager_main_menu ;;
	1) clean_up_container_garbage ;;
	2) backup_gnu_linux_container ;;
	3) backup_termux ;;
	4) install_timeshift ;;
	esac
	####################
	#echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	#echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	#read
	tmoe_manager_main_menu
}
###########################
clean_up_container_garbage() {
	if [ -e "${DEBIAN_CHROOT}" ]; then
		cd ${DEBIAN_CHROOT}
	else
		echo "未检测到容器目录，无法清理垃圾文件。"
		press_enter_to_return
		backup_system
	fi
	CONTAINER_GARBAGE_FILES='tmp/.* tmp/* root/.local root/.ICEauthority root/.Xauthority root/.bash_history root/.pki root/.cache root/.chord root/.cocomusic.json root/.dbus root/.gnupg root/.gridea root/.l2s..ICEauthority* root/.l2s..Xauthority* root/.local root/.mozilla root/.petal.db root/.vnc/passwd root/.vnc/x11passwd root/.vnc/localhost* root/.config/Electron root/.config/Netron root/.config/chord root/.config/electron-netease-cloud-music root/.config/go-for-it root/.config/gridea root/.config/listen1 root/.config/lx-music-desktop root/.config/neofetch root/.config/netease-cloud-music-gtk root/.config/pulse root/.config/tenvideo_universal root/.xfce4-session.verbose-log root/.xfce4-session.verbose-log.last root/.zcompdump-localhost* root/.z root/.zsh_history'
	if [ -e "root/.vnc/passwd" ]; then
		tree ${CONTAINER_GARBAGE_FILES} 2>/dev/null
	fi
	echo "${BOLD}${YELLOW}~/${DEBIAN_FOLDER}${RESET}${RESET}"
	cat <<-EOF
		${RED}rm -rv${RESET} ${BLUE}${CONTAINER_GARBAGE_FILES}${RESET}
	EOF
	echo "若您需要将容器分享给他人，则可以删除以上文件，否则请勿执行清理操作。"
	echo "若您使用的是deb系列发行版，则在清理前，可以在容器内以sudo或root权限执行${GREEN}apt clean;apt autoclean;apt autopurge || apt autoremove${RESET}"
	echo "开发者不对误删除的文件负责，请在清理前确保以上列表中无重要文件，否则请输n"
	echo "If you want to share the container with others, you can delete the above files, otherwise, please type n to return."
	do_you_want_to_continue
	rm -rv ${CONTAINER_GARBAGE_FILES}
	sed -i 's@^#.*DISABLE_AUTO_UPDATE=@DISABLE_AUTO_UPDATE=@g' root/.zshrc
	press_enter_to_return
	backup_system
}
#############
check_backup_file() {
	if [ -e "${BACKUP_FILE}" ]; then
		BACKUP_FOLDER="${BACKUP_FOLDER} ${BACKUP_FILE}"
	fi
}
############
backup_gnu_linux_container() {
	#ls -lth ./debian*.tar.* 2>/dev/null | head -n 5
	#echo '您之前所备份的(部分)文件如上所示'
	#echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
	#press_enter_to_continue
	termux_backup_pre
	TMPtime="${TARGET_BACKUP_FILE_NAME}_$(cat backuptime.tmp)-rootfs_bak"
	BACKUP_FOLDER="${DEBIAN_CHROOT} ${PREFIX}/bin/debian-rm ${PREFIX}/bin/startxsdl ${PREFIX}/bin/startvnc"
	BACKUP_FILE="${PREFIX}/bin/debian"
	check_backup_file
	BACKUP_FILE="${PREFIX}/bin/stopvnc"
	check_backup_file
	BACKUP_FILE="${PREFIX}/bin/startx11vnc"
	check_backup_file
	BACKUP_FILE="${ACROSS_ARCH_FILE}"
	check_backup_file
	BACKUP_FILE="${LINUX_CONTAINER_DISTRO_FILE}"
	check_backup_file
	BACKUP_FILE="${CONFIG_FOLDER}/chroot_container"
	check_backup_file

	if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 12 50); then

		echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
		echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
		press_enter_to_continue
		#stopvnc（pkill all）在linux不会自动生成
		${TMOE_PREFIX} tar -PJpcvf ${TMPtime}.tar.xz --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ${BACKUP_FOLDER}

		#whiptail进度条已弃用
		#tar -PJpcf - --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ~/${DEBIAN_FOLDER} ${PREFIX}/bin/debian | (pv -n >${TMPtime}.tar.xz) 2>&1 | whiptail --gauge "Packaging into tar.xz" 10 70

		#xz -z -T0 -e -9 -f -v ${TMPtime}.tar
		echo "Don't worry too much, it is normal for some directories to backup without permission."
		echo "部分目录无权限备份是正常现象。"
		rm -f backuptime.tmp
		pwd
		ls -lth ./*tar* | grep ^- | head -n 1
		echo '备份完成'
		press_enter_to_return
		tmoe_manager_main_menu

	else
		if (whiptail --title "Choose the type of backup选择备份类型" --yes-button "tar.gz" --no-button "tar" --yesno "Which do yo like better? \n tar只进行打包，不压缩，速度快。\ntar.gz在打包的基础上进行压缩。" 9 50); then
			echo "您选择了tar.gz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.gz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。${RESET} "
			press_enter_to_continue
			case ${TMOE_CHROOT} in
			true) ${TMOE_PREFIX} tar -Ppczvf ${TMPtime}.tar.gz --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ${BACKUP_FOLDER} ;;
			*)
				if [ "$(command -v pv)" ]; then
					tar -Ppczf - --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ${BACKUP_FOLDER} | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
				else
					tar -Ppczvf ${TMPtime}.tar.gz --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ${BACKUP_FOLDER}
				fi
				;;
			esac
		else
			echo "您选择了tar,只进行打包,不进行压缩，即将为您备份至/sdcard/Download/backup/${TMPtime}.tar"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。${RESET} "
			press_enter_to_continue
			${TMOE_PREFIX} tar -Ppcvf ${TMPtime}.tar --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ${BACKUP_FOLDER}
		fi

		#最新版弃用了whiptail的进度条！！！
		#tar -Ppczf - --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ~/${DEBIAN_FOLDER} ${PREFIX}/bin/debian | (pv -n >${TMPtime}.tar.gz) 2>&1 | whiptail --gauge "Packaging into tar.gz \n正在打包成tar.gz" 10 70

		echo "Don't worry too much, it is normal for some directories to backup without permission."
		echo "部分目录无权限备份是正常现象。"
		rm -f backuptime.tmp
		#  whiptail --gauge "正在备份,可能需要几分钟的时间请�������后.........." 6 60 0
		pwd
		ls -lth ./*tar* | grep ^- | head -n 1
		#echo 'gzip压缩至60%完成是正常现象。'
		echo '备份完成'
		press_enter_to_return
		tmoe_manager_main_menu
	fi
}
####################
install_timeshift() {
	if [ "${LINUX_DISTRO}" = "Android" ]; then
		echo 'Sorry,本功能不支持Android系统'
		press_enter_to_return
		tmoe_manager_main_menu
	fi

	if [ ! -e "/usr/bin/timeshift" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			apt update
			apt install -y timeshift
		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm timeshift
		elif [ "${LINUX_DISTRO}" = "redhat" ]; then
			dnf install timeshift
		fi
	fi

	if [ -e "/usr/bin/timeshift" ]; then
		timeshift-launcher &
		echo "安装完成，如需卸载，请手动输apt purge -y timeshift"
		press_enter_to_return
		backup_system
	fi
}
######################
termux_backup_pre() {
	if [ ! -d /sdcard/Download/backup ]; then
		mkdir -p /sdcard/Download/backup
	fi
	cd /sdcard/Download/backup
	backup_filename
	echo $(date +%Y-%m-%d_%H-%M) >backuptime.tmp
}
####################
backup_termux() {
	TERMUX_BACKUP=$(dialog --title "多项选择题" --checklist \
		"您想要备份哪个目录？按空格键选择，*为选中状态，回车键确认 \n Which directory do you want to backup? Please press the space to select and press Enter to confirm." 15 60 4 \
		"home" "Termux主目录,主要用来保存用户文件" ON \
		"usr" "保存软件、命令和其它东西" OFF \
		3>&1 1>&2 2>&3)
	echo ${TERMUX_BACKUP}
	##########################
	if [ "${TERMUX_BACKUP}" = "home" ]; then
		termux_backup_pre
		TMPtime="${TARGET_BACKUP_FILE_NAME}_$(cat backuptime.tmp)-termux_home_bak"
		##tar -czf - ~/${DEBIAN_FOLDER} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)
		#ls -lth ./termux-home*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'
		#echo 'This operation will only backup the home directory of termux, not the container. If you need to backup debian, please select both options or backup debian separately.'
		#echo '本次操作将只备份termux的主目录，不包含主目录下的容器。如您需备份GNU/Linux容器,请同时选择home和usr，或单独备份GNU/Linux容器。'
		#echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
		#		read
		if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60); then

			echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			press_enter_to_continue

			tar -PJpvcf ${TMPtime}.tar.xz --exclude=${DEBIAN_CHROOT}/root/sd --exclude=${DEBIAN_CHROOT}/root/termux --exclude=${DEBIAN_CHROOT}/root/tf ${HOME}

			#xz -z -T0 -e -9 -v ${TMPtime}.tar

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			pwd
			ls -lth ./*termux_home*tar* | grep ^- | head -n 1
			echo "备份${GREEN}完成${RESET}"
			press_enter_to_return
			tmoe_manager_main_menu

		else

			echo "您选择了tar.gz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.gz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			press_enter_to_continue

			tar -Ppvczf ${TMPtime}.tar.gz --exclude=${DEBIAN_CHROOT}/root/sd --exclude=${DEBIAN_CHROOT}/root/termux --exclude=${DEBIAN_CHROOT}/root/tf ${HOME}

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0
			pwd
			ls -lth ./*termux-home*tar* | grep ^- | head -n 1
			echo '备份完成'
			press_enter_to_return
			tmoe_manager_main_menu
		fi
	fi
	##########################
	if [ "${TERMUX_BACKUP}" == 'usr' ]; then

		termux_backup_pre
		TMPtime="${TARGET_BACKUP_FILE_NAME}_$(cat backuptime.tmp)-termux_usr_bak"
		#ls -lth ./termux-usr*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'

		#echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
		#read
		#TMPtime=termux-usr_$(cat backuptime.tmp)

		if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60); then

			echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read

			#tar -PJpcf ${TMPtime}.tar /data/data/com.termux/files/usr
			echo '正在压缩成tar.xz'

			if [ "$(command -v pv)" ]; then
				tar -PpJcf - ${PREFIX} | (pv -p --timer --rate --bytes >${TMPtime}.tar.xz)
			else
				tar -PpJcvf ${TMPtime}.tar.xz ${PREFIX}
			fi

			#echo '正在压缩成xz'
			#xz -z -T0 -e -9 -v ${TMPtime}.tar

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			pwd
			ls -lth ./*termux_usr*tar* | grep ^- | head -n 1
			echo "备份${GREEN}完成${RESET}"
			press_enter_to_return
			tmoe_manager_main_menu

		else

			echo "您选择了tar.gz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.gz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			press_enter_to_continue

			#tar -Ppczf ${TMPtime}.tar.gz   /data/data/com.termux/files/usr

			if [ "$(command -v pv)" ]; then
				tar -Ppczf - ${PREFIX} | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
			else
				tar -Ppczvf ${TMPtime}.tar.gz ${PREFIX}
			fi

			##tar -czf - ~/${DEBIAN_FOLDER} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0
			pwd
			ls -lth ./*tar* | grep ^- | head -n 1
			echo "备份${GREEN}完成${RESET}"
			press_enter_to_return
			tmoe_manager_main_menu
		fi
	fi
	##########################
	if [ "${TERMUX_BACKUP}" == 'home usr' ]; then

		#ls -lth ./termux-home+usr*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'
		termux_backup_pre
		TMPtime="${TARGET_BACKUP_FILE_NAME}_$(cat backuptime.tmp)-termux_home+usr_bak"
		#TMPtime=termux-home+usr_$(cat backuptime.tmp)

		if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ratio, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60); then
			echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			press_enter_to_continue

			#tar -PJpcf ${TMPtime}.tar /data/data/com.termux/files/usr
			echo '正在压缩成tar.xz'
			if [ "$(command -v pv)" ]; then
				tar -PpJcf - ${HOME} ${PREFIX} | (pv -p --timer --rate --bytes >${TMPtime}.tar.xz)
			else
				tar -PpJcvf ${TMPtime}.tar.xz ${HOME} ${PREFIX}
			fi

			#echo '正在压缩成xz'
			#xz -z -T0 -e -9 -v ${TMPtime}.tar

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			pwd
			ls -lth ./*termux_home+usr*tar* | grep ^- | head -n 1
			echo "备份${GREEN}完成${RESET}"
			press_enter_to_return
			tmoe_manager_main_menu

		else

			echo "您选择了tar.gz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.gz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			press_enter_to_continue

			#tar -Ppczf ${TMPtime}.tar.gz   /data/data/com.termux/files/usr
			if [ "$(command -v pv)" ]; then
				tar -Ppczf - ${HOME} ${PREFIX} | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
			else
				tar -Ppczvf ${TMPtime}.tar.gz ${HOME} ${PREFIX}
			fi
			##tar -czf - ~/${DEBIAN_FOLDER} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0
			pwd
			ls -lth ./*termux-home+usr*tar* | grep ^- | head -n 1
			echo "备份${GREEN}完成${RESET}"
			press_enter_to_return
			tmoe_manager_main_menu
		fi
	fi
	################################
	exitstatus="$?"
	if [ ${exitstatus} != 0 ]; then
		backup_system
	fi
}
##################################
uncompress_other_format_file() {
	pwd
	echo "即将为您解压..."
	if [ ! "$(command -v pv)" ] || [ "${COMPATIBILITY_MODE}" = 'true' ] || [ "${TMOE_CHROOT}" = 'true' ]; then
		echo "${GREEN} tar -Ppxvf ${RESTORE} ${RESET}"
		${TMOE_PREFIX} tar -Ppxvf ${RESTORE}
	else
		echo "${GREEN} pv ${RESTORE} | tar -Ppx ${RESET}"
		pv ${RESTORE} | tar -Ppx
	fi
}
##############
uncompress_tar_xz_file() {
	pwd
	echo 'tar.xz'
	echo "即将为您解压..."
	if [ ! "$(command -v pv)" ] || [ "${COMPATIBILITY_MODE}" = 'true' ] || [ "${TMOE_CHROOT}" = 'true' ]; then
		echo "${GREEN} tar -PpJxvf ${RESTORE} ${RESET}"
		${TMOE_PREFIX} tar -PpJxvf ${RESTORE}
	else
		echo "${GREEN} pv ${RESTORE} | tar -PpJx ${RESET}"
		pv ${RESTORE} | tar -PpJx
	fi
}
######################
uncompress_tar_gz_file() {
	pwd
	echo 'tar.gz'
	echo "即将为您解压..."
	if [ ! "$(command -v pv)" ] || [ "${COMPATIBILITY_MODE}" = 'true' ] || [ "${TMOE_CHROOT}" = 'true' ]; then
		echo "${GREEN} tar -Ppzxvf ${RESTORE} ${RESET}"
		${TMOE_PREFIX} tar -Ppzxvf ${RESTORE}
	else
		echo "${GREEN} pv ${RESTORE} | tar -Ppzx ${RESET}"
		pv ${RESTORE} | tar -Ppzx
	fi
}
#####################
uncompress_tar_file() {
	case "${RESTORE:0-6:6}" in
	tar.xz)
		uncompress_tar_xz_file
		;;
	tar.gz)
		uncompress_tar_gz_file
		;;
	*)
		uncompress_other_format_file
		;;
	esac
	if [ -e "${PREFIX}/bin/debian" ]; then
		check_proot_proc_permissions
	fi
	press_enter_to_return
	restore_gnu_linux_container
}
#######################
select_file_manually() {
	count=0
	echo '您可以在此列表中选择需要恢复的压缩包'
	for restore_file in "${START_DIR}"/${BACKUP_FILE_NAME}; do
		restore_file_name[count]=$(echo $restore_file | awk -F'/' '{print $NF}')
		echo -e "($count) ${restore_file_name[count]}"
		count=$(($count + 1))
	done
	count=$(($count - 1))

	while true; do
		read -p '请输入选项数字,并按回车键。Please type the option number and press Enter:' number
		if [[ -z "$number" ]]; then
			break
		elif ! [[ $number =~ ^[0-9]+$ ]]; then
			echo "Please enter the right number!"
			echo '请输入正确的数字编号！'
		elif (($number >= 0 && $number <= $count)); then
			eval RESTORE=${restore_file_name[number]}
			# cp -fr "${START_DIR}/$choice" "$DIR/restore_file.properties"
			RETURN_TO_WHERE='restore_gnu_linux_container'
			do_you_want_to_continue
			uncompress_tar_file
			break
		else
			echo "Please enter the right number!"
			echo '请输入正确的数字编号！'
		fi
	done
	press_enter_to_return
	restore_gnu_linux_container
}
################
restore_the_latest_backup_file() {
	#echo '目前仅支持还原最新的备份，如需还原旧版，请手动输以下命令'
	#echo 'cd /sdcard/Download/backup ;ls ; tar -JPxvf 文件名.tar.xz 或 tar -Pzxvf 文件名.tar.gz'
	#echo '请注意大小写，并把文件名改成具体名称'
	if [ -z "${RESTORE}" ]; then
		echo "${RED}未检测${RESTORE}到${BLUE}备份文件${RESTORE},请${GREEN}手动选择${RESTORE}"
		press_enter_to_continue
		BACKUP_FILE_NAME=*
		manually_select_the_file_directory
		select_file_manually
		# tmoe_file_manager
	else
		ls -lh ${RESTORE}
		RETURN_TO_WHERE='restore_gnu_linux_container'
		do_you_want_to_continue
		uncompress_tar_file
	fi
	press_enter_to_return
	restore_gnu_linux_container
}
#########################
unmount_proc_dev() {
	case ${TMOE_CHROOT} in
	true)
		su -c "umount -lvf ${DEBIAN_CHROOT}/* 2>/dev/null"
		su -c "umount -lvf ${DEBIAN_CHROOT}/*/*  2>/dev/null"
		su -c "umount -lvf ${DEBIAN_CHROOT}  2>/dev/null"
		su -c "ls -lAh  ${DEBIAN_CHROOT}/root/sd"
		;;
	esac
	#/dev内自带null
	for i in root/sd root/tf proc sys; do
		if [ "$(ls ${DEBIAN_CHROOT}/${i} 2>/dev/null)" ]; then
			echo "检测到~/${DEBIAN_FOLDER}/${i}目录不为空，为防止该目录被清空，无法继续执行操作！"
			echo "Please restart the device to unmount the chroot directory."
			press_enter_to_return
			${RETURN_TO_WHERE}
		fi
	done
	unset i
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
#########################
where_is_start_dir() {
	if [ -d "/sdcard" ]; then
		START_DIR='/sdcard/Download/backup'
	elif [ -d "/root/sd" ]; then
		START_DIR='/root/sd/Download/backup'
	else
		START_DIR="$(pwd)"
	fi
	cd ${START_DIR}
	select_file_manually
}
###############
file_directory_selection() {

	if (whiptail --title "FILE PATH" --yes-button '自动auto' --no-button '手动manually' --yesno "您想要手动指定文件目录还是自动选择?\nDo you want to automatically select the file directory" 9 50); then
		where_is_start_dir
	else
		manually_select_the_file_directory
		select_file_manually
	fi
}
###################
manually_select_the_file_directory() {
	#12 50
	TARGET_BACKUP_FILE_PATH=$(whiptail --inputbox "请输入文件路径(精确到目录名称)，默认为/sdcard/Download/backup\n Please enter the file path." 10 50 --title "FILEPATH" 3>&1 1>&2 2>&3)
	START_DIR="$(echo ${TARGET_BACKUP_FILE_PATH} | head -n 1 | cut -d ' ' -f 1)"
	echo ${START_DIR}
	if [ -z ${START_DIR} ]; then
		echo "文件目录不能为空"
		press_enter_to_return
		restore_gnu_linux_container
	else
		cd ${START_DIR}
	fi
}
###############
restore_gnu_linux_container() {
	unmount_proc_dev
	COMPATIBILITY_MODE='fasle'
	RETURN_TO_WHERE='restore_gnu_linux_container'
	OPTION=$(whiptail --title "Restore System" --menu "你想要恢复哪个小可爱到之前的备份状态" 13 55 5 \
		"1" "Restore GNU/Linux container容器" \
		"2" "Restore termux" \
		"3" "select path manually手动选择路径" \
		"4" "Compatibility mode兼容模式" \
		"0" "🌚 Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	###########################################################################
	if [ "${OPTION}" == '1' ]; then
		#ls -lth debian*tar* 2>/dev/null || echo '未检测到备份文件' | head -n 10
		if (whiptail --title "RESTORE FILE" --yes-button '最新latest' --no-button 'select manually' --yesno "您是想要还原最新文件，还是手动选择备份文件\nDo you want to restore the latest file or select the file manually?" 9 50); then
			#RESTORE=$(ls -lth ./*debian*tar* | grep ^- | head -n 1 | cut -d '/' -f 2)
			cd /sdcard/Download/backup
			RESTORE=$(ls -lth ./*-rootfs_bak.tar* | grep ^- | head -n 1 | awk -F ' ' '$0=$NF')
			restore_the_latest_backup_file
		else
			BACKUP_FILE_NAME="*-rootfs_bak.tar*"
			where_is_start_dir
		fi
	fi
	###################
	if [ "${OPTION}" == '2' ]; then
		if (whiptail --title "RESTORE FILE" --yes-button '最新latest' --no-button 'select manually' --yesno "您是想要还原最新文件，还是手动选择备份文件\nDo you want to restore the latest file or select the file manually?" 9 50); then
			#RESTORE=$(ls -lth ./termux*tar* | grep ^- | head -n 1 | cut -d '/' -f 2)
			cd /sdcard/Download/backup
			RESTORE=$(ls -lth ./*-termux*_bak.tar* | grep ^- | head -n 1 | awk -F ' ' '$0=$NF')
			restore_the_latest_backup_file
		else
			BACKUP_FILE_NAME="*-termux*_bak.tar*"
			where_is_start_dir
		fi
	fi
	###################
	if [ "${OPTION}" == '3' ]; then
		BACKUP_FILE_NAME="*tar*"
		file_directory_selection
	fi
	###################
	if [ "${OPTION}" == '4' ]; then
		BACKUP_FILE_NAME="*tar*"
		COMPATIBILITY_MODE='true'
		file_directory_selection
	fi
	##########################
	if [ "${OPTION}" == '0' ] || [ -z "${OPTION}" ]; then
		tmoe_manager_main_menu
	fi
	##########################
	#tmoe_manager_main_menu
}
############################
space_occupation() {
	cd ${HOME}/..
	OPTION=$(whiptail --title "Query space occupation ranking" --menu "查询空间占用排行" 15 60 4 \
		"0" "🌚 Back返回" \
		"1" "termux各目录" \
		"2" "termux文件" \
		"3" "sdcard" \
		"4" "总存储空间用量Disk usage" \
		3>&1 1>&2 2>&3)
	###########################################################################
	case ${OPTION} in
	0 | "") ${RETURN_TO_MENU} ;;
	1)
		echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
		echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
		echo "${YELLOW}主目录 TOP15${RESET}"
		du -hsx ./home/* ./home/.* 2>/dev/null | sort -rh | head -n 15
		echo '-------------------'
		echo "${YELLOW}usr 目录 TOP6${RESET}"
		du -hsx ./usr/* 2>/dev/null | sort -rh | head -n 6
		echo '-------------------'
		echo "${YELLOW}usr/lib 目录 TOP8${RESET}"
		du -hsx ./usr/lib/* 2>/dev/null | sort -rh | head -n 8
		echo '-------------------'
		echo "${YELLOW}usr/share 目录 TOP8${RESET}"
		du -hsx ./usr/share/* 2>/dev/null | sort -rh | head -n 8
		echo '-------------------'
		;;
	2)
		echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
		echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
		echo "${YELLOW}termux 文件大小排行榜(30名)${RESET}"
		find ./ -type f -print0 2>/dev/null | xargs -0 du | sort -n | tail -30 | cut -f2 | xargs -I{} du -sh {}
		;;
	3)
		cd /sdcard
		echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
		echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
		echo "${YELLOW}sdcard 目录 TOP15${RESET}"
		du -hsx ./* ./.* 2>/dev/null | sort -rh | head -n 15
		echo "${YELLOW}sdcard文件大小排行榜(30名)${RESET}"
		find ./ -type f -print0 2>/dev/null | xargs -0 du | sort -n | tail -30 | cut -f2 | xargs -I{} du -sh {}
		;;
	4)
		echo "${YELLOW}Disk usage${RESET}"
		df -h | grep G | grep -v tmpfs
		press_enter_to_return
		space_occupation
		;;
	esac
	#####################################
	press_enter_to_return
	space_occupation
}
########################################################################
update_tmoe_linux_manager() {
	#curl -L -o ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh'
	aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh' || curl -Lo ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh' || sudo -E aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh'
	if [ "${LINUX_DISTRO}" != "Android" ]; then
		sed -i '1 c\#!/usr/bin/env bash' ${PREFIX}/bin/debian-i
	fi
	echo "${TMOE_GIT_URL}"
	echo "${YELLOW}更新完成，按回车键返回。${RESET}"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	chmod +x ${PREFIX}/bin/debian-i
	read
	#bash ${PREFIX}/bin/debian-i
	source ${PREFIX}/bin/debian-i
}
#######################
download_vnc_or_xsdl_apk() {
	if (whiptail --title "您想要下载哪个软件?" --yes-button 'VNC Viewer' --no-button 'XServer XSDL' --yesno "vnc操作体验更好,当前版本已经可以通过pulse server来传输音频。xsdl对某些软件的兼容性更高，但操作体验没有vnc好。VNC has a better operating experience and is also smoother.XSDL is more compatible with some software， but the experience is not as good as VNC in every way.\n若VNC启动后仍无声音，则请前往Play商店或Fdroid更新termux至最新版本,再安装termux:api.apk" 16 50); then
		echo 'Press enter to start the download, and press Ctrl + C to cancel.'
		echo "${YELLOW}按回车键开始下载，按Ctrl+C取消。${RESET}"
		read
		echo 'Downloading vnc viewer...'
		#rm -f 'VNCViewer_com-realvnc-viewer-android-3-6-1-42089.tar.xz' 2>/dev/null
		echo '正在为您下载至/sdcard/Download目录...'
		echo 'Download size ≈11MB'
		if [ -d "/sdcard/Download/.GITCLONEVNCCLIENT" ]; then
			rm -rf /sdcard/Download/.GITCLONEVNCCLIENT
		fi

		git clone -b vnc --depth=1 https://gitee.com/mo2/VncClient.git .GITCLONEVNCCLIENT
		mv -f /sdcard/Download/.GITCLONEVNCCLIENT/vnc/vnc36142089.tar.xz ./
		echo '正在解压...'
		tar -Jxvf vnc36142089.tar.xz
		#tar -Jxvf 'VNCViewer_com-realvnc-viewer-android-3-6-1-42089.tar.xz'
		rm -rf /sdcard/Download/.GITCLONEVNCCLIENT
		rm -f /sdcard/Download/vnc36142089.tar.xz
		echo '正在删除压缩包...'
		echo 'Deleting ...'
		#rm -f 'VNCViewer_com-realvnc-viewer-android-3-6-1-42089.tar.xz'
		am start -n com.android.documentsui/com.android.documentsui.ViewDownloadsActivity
		echo "${YELLOW}解压成功，请进入下载目录手动安装。${RESET}"
		echo '文件名称 VNC Viewer_com,realvnc,viewer,android_3,6,1,42089.apk'
		cd ${cur}
	else
		echo 'Press enter to start the download, and press Ctrl + C to cancel.'
		echo '按回车键开始下载，按Ctrl+C取消。'
		read
		echo 'Downloading xsdl...'
		#rm -f 'XServerXSDL-X-org-server_1-20-41.tar.xz' 2>/dev/null
		echo '正在为您下载至/sdcard/Download目录...'
		echo 'Download size ≈29MB'
		if [ -d "/sdcard/Download/.GITCLONEVNCCLIENT" ]; then
			rm -rf /sdcard/Download/.GITCLONEVNCCLIENT
		fi

		git clone -b xsdl --depth=1 https://gitee.com/mo2/VncClient.git .GITCLONEVNCCLIENT
		mv -f /sdcard/Download/.GITCLONEVNCCLIENT/xsdl/XSERVERXSDLANDROID.tar.xz ./
		echo '正在解压...'
		tar -Jxvf XSERVERXSDLANDROID.tar.xz
		#tar -Jxvf 'XServerXSDL-X-org-server_1-20-41.tar.xz'
		rm -rf /sdcard/Download/.GITCLONEVNCCLIENT
		rm -f /sdcard/Download/XSERVERXSDLANDROID.tar.xz
		echo '正在删除压缩包...'
		echo 'Deleting ...'
		#rm -f 'XServerXSDL-X-org-server_1-20-41.tar.xz'

		echo '解压成功，请进入下载目录手动安装。'
		echo '文件名称 XServer XSDL*.apk'
		am start -n com.android.documentsui/com.android.documentsui.ViewDownloadsActivity
		cd ${cur}
	fi
}
###################
xwayland_warning() {
	echo "${RED}WARNING！${RESET}本功能目前仍处于${YELLOW}测试阶段${RESET}，且需要${RED}root权限${RESET}"
	echo "请在下载并安装完apk后，开启proot容器真实root权限功能！"
	echo "由于目前在Android设备上只能靠软件来渲染，故实际体验将会非常糟糕！"
	echo "同时，由于触控操作体验极差。若您无蓝牙鼠标等外接设备，则不建议您配置本服务。"
	echo "您在安装完apk后，还需进入GNU/Linux容器内，输debian-i，并选择配置xwayland的选项"
	download_xwayland_apk
}
############
configure_termux_xwayland_mount() {
	su -c "ls /data/data/com.sion.sparkle"
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "配置${RED}失败！${RESET}请先安装sparkle，并检查root权限设置"
		press_enter_to_return
		download_vnc_apk
	fi
	GET_DEBIAN_BIND_LINE=$(cat $PREFIX/bin/debian | grep -n 'mount=/sys' | cut -d ':' -f 1 | head -n 1)
	sed -i '/com.sion.sparkle/d' $PREFIX/bin/debian
	#rm ${DEBIAN_CHROOT}/etc/xwayland || sudo rm ${DEBIAN_CHROOT}/etc/xwayland
	sed -i "${GET_DEBIAN_BIND_LINE} i\set -- \"--mount=/data/data/com.sion.sparkle/files:/etc/xwayland\" \"\$@\"" $PREFIX/bin/debian
	#sed -i "${GET_DEBIAN_BIND_LINE} i\ command+=\" --mount=/data/data/com.sion.sparkle/files:/etc/xwayland\"" $PREFIX/bin/debian
	echo "termux配置完成，您还需要进入GNU/Linux容器环境内，单独选择xwayland桌面配置选项!"
	echo "按回车键打开wayland服务端app"
	read
	am start -n com.sion.sparkle/com.sion.sparkle.MainActivity
}
################
download_xwayland_apk() {
	echo "${YELLOW}Do you want to continue?[Y/n]${RESET}"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}download apk${RESET},type c to configure，type ${YELLOW}n${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}下载apk${RESET}，输${YELLOW}c${RESET}配置，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
	read opt
	case $opt in
	y* | Y* | "")
		rm -rf .X_WAYLAND_APK_TEMP_FOLDER
		git clone -b xwayland --depth=1 https://gitee.com/mo2/VncClient .X_WAYLAND_APK_TEMP_FOLDER
		cd .X_WAYLAND_APK_TEMP_FOLDER
		tar -Jxvf xwayland.tar.xz
		mv *apk ../
		cd ..
		rm -rf .X_WAYLAND_APK_TEMP_FOLDER
		echo '解压成功，请进入下载目录手动安装。'
		echo '文件名称 Sparkle*.apk'
		am start -n com.android.documentsui/com.android.documentsui.ViewDownloadsActivity
		echo "请在安装完成后，按回车键启用root权限"
		read
		#su -c "ln -sf /data/data/com.sion.sparkle/files ${DEBIAN_CHROOT}/etc/xwayland"
		configure_termux_xwayland_mount
		enable_root_mode
		;;
	c* | C*)
		#sudo ln -sf /data/data/com.sion.sparkle/files ${DEBIAN_CHROOT}/etc/xwayland || su -c "ln -sf /data/data/com.sion.sparkle/files ${DEBIAN_CHROOT}/etc/xwayland"
		configure_termux_xwayland_mount
		#sudo ls ${DEBIAN_CHROOT}/etc/xwayland/* >/dev/null || echo "配置${RED}失败${RESET}，请检查root权限设置"
		press_enter_to_return
		;;
	n* | N*)
		echo "skipped."
		download_vnc_apk
		;;
	*)
		echo "Invalid choice. skipped."
		download_vnc_apk
		;;
	esac
}
#################################
download_vnc_apk() {
	cd /sdcard/Download || mkdir -p /sdcard/Download && cd /sdcard/Download
	RETURN_TO_WHERE='download_vnc_apk'
	#15 60 4
	OPTION=$(whiptail --title "remote desktop apk" --menu "Which remote desktop software do you want to install?" 0 50 0 \
		"1" "vnc/xsdl" \
		"2" "xwayland" \
		"0" "🌚 Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${OPTION}" in
	0 | "") ${RETURN_TO_MENU} ;;
	1) download_vnc_or_xsdl_apk ;;
	2) xwayland_warning ;;
	esac
	###########
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#########################################
start_vscode() {
	if [ "${ARCH_TYPE}" != 'arm64' ]; then
		echo "It is detected that your current architecture is not arm64, please install the server version yourself."
		press_enter_to_return
		tmoe_manager_main_menu
	fi

	if [ ! -d "${HOME}/${DEBIAN_FOLDER}" ]; then
		echo "未检测到${DEBIAN_FOLDER},请先安装GNU/Linux容器"
		echo "Detected that you did not install ${DEBIAN_FOLDER}, please install container first."
		press_enter_to_return
		tmoe_manager_main_menu
	fi

	if [ ! -e "${PREFIX}/bin/code-server" ]; then
		cat >${PREFIX}/bin/code-server <<-EndOfFile
			#!/data/data/com.termux/files/usr/bin/env bash
			touch "${DEBIAN_CHROOT}/tmp/startcode.tmp"
			CODE_PORT=$(cat ${HOME}/${DEBIAN_FOLDER}/root/.config/code-server/config.yaml | grep bind-addr | head -n 1 | awk -F ' ' '$0=$NF' | cut -d ':' -f 2)
			am start -a android.intent.action.VIEW -d "http://localhost:\${CODE_PORT}"
			echo "本机默认vscode服务地址localhost:\${CODE_PORT}"
			echo The LAN VNC address 局域网地址\$(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):\${CODE_PORT}
			echo "Please paste the address into your browser!"
			echo "请将地址粘贴到浏览器的地址栏中"

			echo "您之后可以输code-server来启动VS Code."
			echo 'You can type "code-server" to start VS Code.'
			${PREFIX}/bin/debian
		EndOfFile
		chmod +x ${PREFIX}/bin/code-server
	fi

	if [ ! -e "${DEBIAN_CHROOT}/tmp/sed-vscode.tmp" ]; then
		cat >${DEBIAN_CHROOT}/tmp/sed-vscode.tmp <<-'EOF'
			if [ -e "/tmp/startcode.tmp" ]; then
				echo "正在为您启动VSCode服务(器),请复制密码，并在浏览器的密码框中粘贴。"
				echo "The VSCode service(server) is starting, please copy the password and paste it in your browser."

				rm -f /tmp/startcode.tmp
				code-server &
				echo "已为您启动VSCode服务!"
				echo "VScodeServer has been started,enjoy it !"
				echo "您可以输pkill code-server来停止服务(器)。"
				echo 'You can type "pkill code-server" to stop vscode service(server).'
			fi
		EOF
	fi

	if [ ! -f "${DEBIAN_CHROOT}/root/.zshrc" ]; then
		echo "" >>${DEBIAN_CHROOT}/root/.zshrc
	fi
	if [ ! -f "${DEBIAN_CHROOT}/root/.bashrc" ]; then
		echo "" >>${DEBIAN_CHROOT}/root/.bashrc
	fi

	grep '/tmp/startcode.tmp' ${DEBIAN_CHROOT}/root/.bashrc >/dev/null || sed -i "$ r ${DEBIAN_CHROOT}/tmp/sed-vscode.tmp" ${DEBIAN_CHROOT}/root/.bashrc
	grep '/tmp/startcode.tmp' ${DEBIAN_CHROOT}/root/.zshrc >/dev/null || sed -i "$ r ${DEBIAN_CHROOT}/tmp/sed-vscode.tmp" ${DEBIAN_CHROOT}/root/.zshrc

	if [ -e "${DEBIAN_CHROOT}/usr/local/bin/code-server" ] || [ -L "${DEBIAN_CHROOT}/usr/local/bin/code-server" ]; then
		code-server
	else

		cd ${HOME}
		if [ -d ".VSCODESERVERTMPFILE" ]; then
			rm -rf .VSCODESERVERTMPFILE
		fi

		echo "server版商店中不包含所有插件，如需下载额外插件，请前往微软vscode官方在线商店下载vsix后缀的离线插件，并手动安装。 https://marketplace.visualstudio.com/vscode"
		git clone -b aarch64 --depth=1 https://gitee.com/mo2/vscode-server.git .VSCODESERVERTMPFILE
		cd ${DEBIAN_CHROOT}
		tar -Jpxvf ${HOME}/.VSCODESERVERTMPFILE/code.tar.xz
		rm -rf ${HOME}/.VSCODESERVERTMPFILE
		echo "Congratulations, you have successfully installed vscode server!"
		echo "您已成功安装VSCode服务，如需卸载请输rm -rf ${PREFIX}/bin/code-server ${DEBIAN_CHROOT}/usr/local/bin/code-server ${DEBIAN_CHROOT}/usr/local/bin/code-server-data"

		grep "keyCode" ${DEBIAN_CHROOT}/root/.local/share/code-server/User/settings.json >/dev/null || mkdir -p ${DEBIAN_CHROOT}/root/.local/share/code-server/User && cat >${DEBIAN_CHROOT}/root/.local/share/code-server/User/settings.json <<-'EndOfFile'
			{
			"keyboard.dispatch": "keyCode"
			}
		EndOfFile

		code-server
	fi

}
#####################################
download_video_tutorial() {
	cd /sdcard/Download
	if [ -f "20200229vnc教程06.mp4" ]; then
		if (whiptail --title "检测到视频已下载,请选择您需要执行的操作！" --yes-button 'Play播放o(*￣▽￣*)o' --no-button '重新下载(っ °Д °)' --yesno "Detected that the video has been downloaded, do you want to play it, or download it again?" 7 60); then
			play_video_tutorial
		else
			download_video_tutorial_again
		fi
	else
		download_video_tutorial_again
	fi
}
##########################
download_video_tutorial_again() {
	aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "20200229vnc教程06.mp4" 'https://webdav.tmoe.me/down/share/videos/20200229vnc%E6%95%99%E7%A8%8B06.mp4' || curl -Lo "20200229vnc教程06.mp4" 'https://webdav.tmoe.me/down/share/videos/20200229vnc%E6%95%99%E7%A8%8B06.mp4'
	play_video_tutorial
}
#######################
play_video_tutorial() {
	termux-open "20200229vnc教程06.mp4"
	echo "${YELLOW}若视频无法自动播放，则请进入下载目录手动播放。${RESET}"
	echo "If the video does not play automatically, please enter the download directory to play it manually."
	echo "按回车键继续,按Ctrl+C取消。"
	echo "${YELLOW}Press enter to continue.${RESET}"
	read
	am start -n com.android.documentsui/com.android.documentsui.ViewDownloadsActivity
	cd ${cur}
}
#####################################
chroot_install_debian() {
	press_enter_to_continue
	#rm -f ~/.Tmoe-Proot-Container-Detection-File 2>/dev/null
	TMOE_CHROOT="true"
	install_gnu_linux_container
}
#################################
check_and_view_the_eula() {
	case ${TMOE_CHROOT} in
	false)
		rm -f ~/.Chroot-Container-Detection-File ${CONFIG_FOLDER}/chroot_container 2>/dev/null
		;;
	true)
		touch ${CONFIG_FOLDER}/chroot_container
		;;
	esac

	if [ ! -e "${CONFIG_FOLDER}/eula" ]; then
		tmoe_linux_container_eula
	fi
	case ${LINUX_DISTRO} in
	Android)
		case ${TMOE_CHROOT} in
		true)
			##部分Android系统无/proc/sys/fs/binfmt_misc, 故本工具移除了chroot跨架构的功能,请换用GNU/Linux系统，或自行使用modprobe binfmt_misc加载内核模块
			#Debian会自动注册qemu-user的binfmt_misc
			run_gnu_linux_container_on_same_arch
			;;
		*) same_arch_or_different_arch ;;
		esac
		;;
	*)
		same_arch_or_different_arch
		;;
	esac
}
########################
tmoe_linux_container_eula() {
	if [ ! -d "${DEBIAN_CHROOT}" ]; then
		#less -meQ
		cat <<-'EndOfFile'
			                              End-user license agreement 
						   Tmoe-linux Tool（以下简称“本工具”）尊重并保护所有使用服务的用户的个人隐私权。
						本工具遵循GNU General Public License v2.0 （开源许可协议）,旨在追求开放和自由。
						由于恢复包未存储于git仓库，而存储于第三方网盘，故您必须承担并知悉其中的风险。
						强烈建议您选择更为安全的安装方式，即从软件源镜像站下载容器镜像，再自行选择安装内容。
						本工具的开发者郑重承诺：恢复包内的系统不会使用和披露您的个人信息，也不存在任何侵害您个人隐私的行为。
						本工具会不时更新本协议，您在同意本工具服务使用协议之时，即视为您已经同意本协议全部内容。本协议属于本工具服务使用协议不可分割的一部分。
						This tool will update this agreement from time to time. When you agree to this tool service use agreement, you are deemed to have agreed to the entire contents of this agreement. This agreement is an integral part of the tool service agreement.

						1.禁止条例
						(a)禁止将本工具安装的GNU/Linux用于违法行为，例如：网络渗透、社会工程、域名未备案私自设立商用web服务等。
						Do not use GNU/Linux installed by this tool for illegal behavior!

						2. 适用范围
						(a)在您使用本工具时，通过第三方网盘下载的恢复包系统；
						(b)在您使用本工具时，通过清华镜像站安装的基础系统。
						您了解并同意，以下信息不适用本许可协议：
						(a)您在本工具的相关网站发布的有关信息数据，包括但不限于参与活动、点赞信息及评价详情；
						(b)违反法律规定或违反本工具规则行为及本工具已对您采取的措施。

						3. 信息使用
						(a)本工具不会收集或向任何无关第三方提供、出售、出租、分享或交易您的个人信息。
						This tool will not collect or provide, sell, rent, share or trade your personal information to an unrelated third party.
						(b)本工具亦不允许任何第三方以任何手段收集、编辑、出售或者无偿传播您的个人信息。
						                 
						4.下载说明
						(a)第三方网盘内的文件有可能由于网站被黑、文件失效、文件被替换、网站服务器出错等原因而导致下载出错或下载内容被劫持,故本工具在解压前会自动校验文件的sha256哈希值。
						(b)强烈建议您选择更为安全的安装方式，即从软件源镜像站下载容器镜像，再自行选择安装内容。

						5. 关于美化和配置功能
						(a)本工具会为您提供个性化服务，您可以安装、配置软件和主题美化。
						(b)本工具为部分第三方软件提供安装、配置和管理功能，并尽量保持此类软件的纯净性。
						(c)本工具同时提供了一些原创的内容，开发者不对您使用本工具所进行的任何行为负责。
						(d)请您自行承担使用第三方软件的后果，开发者不对这些软件造成的后果负责，也不对您使用这些软件进行的违法行为负责。

						6. 恢复包的使用
						(a)在您未拒绝接受恢复包的情况下，本工具会将恢复包下载至内置存储设备，并将其解压出来，以便您能快速安装并使用Debian GNU/Linux的图形桌面环境。
						(b)您有权选择接受或拒绝使用恢复包或本工具。

						7. 信息安全
						(a)本工具安装的是原生GNU/Linux 系统，截至2020-03-12，默认没有开启安全保护和防火墙功能，请您妥善保管root密码及其它重要账号信息。
						同时希望您能注意在信息网络上不存在“绝对完善的安全措施”。

						8.卸载说明
						(a)您在移除容器前，必须先停止容器进程。
						(b)由于在测试chroot容器的过程中，出现了部分已挂载目录无法强制卸载的情况，故本工具在移除容器前会进行检测，并给出相关提示。
						建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！

						9.最终用户许可协议的更改
						(a)如果决定更改最终用户许可协议，我们会在本协议中、本工具网站中以及我们认为适当的位置发布这些更改，以便您了解如何保障我们双方的权益。
						(b)本工具开发者保留随时修改本协议的权利,因此建议您不定期查看。
						The developer of this tool reserves the right to modify this agreement at any time.
		EndOfFile
		echo 'You must agree to the EULA to use this tool.'
		echo "Press ${GREEN}Enter${RESET} to agree ${BLUE}the EULA${RESET}, otherwise press ${YELLOW}Ctrl + C${RESET} or ${RED}close${RESET} the terminal directly."
		echo "按${GREEN}回车键${RESET}同意${BLUE}《最终用户许可协议》${RESET} ，否则请按${YELLOW}Ctrl+C${RESET} 或直接${RED}关闭${RESET}终端。 "
		#note_tmoe_linux_git_repo
		read
		touch ${CONFIG_FOLDER}/eula
	fi
}
###################################################
note_tmoe_linux_git_repo() {
	cat <<-'EndOfFile'
		本项目的原地址为https://gitee.com/mo2/linux
		有空的话，可以来看看哦！φ(≧ω≦*)♪
		听说尊重他人的劳动成果，会让世界变得更加美好呢！
		The original URL of this project is https://github.com/2moe/tmoe-linux
		If you give me a star, then I will feel very happy.
	EndOfFile
}
#################################################
run_gnu_linux_container_on_same_arch() {
	rm ~/.config/tmoe-linux/across_architecture_container.txt 2>/dev/null
	ARCH_TYPE=${TRUE_ARCH_TYPE}
	choose_which_gnu_linux_distro
}
##############
same_arch_or_different_arch() {
	if (whiptail --title "您是想要同架构运行,还是跨架构呢？" --yes-button 'same同' --no-button 'across跨' --yesno "Your current architecture is ${TRUE_ARCH_TYPE}.\nDo you want to run on the same architecture or across architectures?\n除向下兼容外,跨架构运行的效率可能偏低" 0 0); then
		run_gnu_linux_container_on_same_arch
	else
		tmoe_qemu_user_manager
	fi
	###################
}
###############
disable_qemu_user_static() {
	if (whiptail --title "若无法向下兼容，则尝试禁用该参数" --yes-button 'disable禁用' --no-button 'enable启用' --yesno "Do you want to disable it?" 0 0); then
		#sed -i "s@command.*qemu-.*-staic@#&@" ${PREFIX}/bin/debian
		#sed -i 's@command+=\" -q qemu-@#&@' ${PREFIX}/bin/debian
		sed -i 's@^set.*qemu=qemu@#test03&@g' ${PREFIX}/bin/debian
	else
		#sed -i 's@#command+=\" -q qemu-@command+=\" -q qemu@' ${PREFIX}/bin/debian
		sed -i 's@#test03@@g' ${PREFIX}/bin/debian
	fi
}
#############
tmoe_qemu_user_static() {
	qemu_user_env
	RETURN_TO_WHERE='tmoe_qemu_user_static'
	BETA_SYSTEM=$(
		whiptail --title "qemu_user_static" --menu "QEMU的user模式跨架构运行的效率可能比system模式更高，但存在更多的局限性" 0 50 0 \
			"1" "chart架构支持表格" \
			"2" "install/upgrade(安装/更新)" \
			"3" "remove(移除/卸载)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${BETA_SYSTEM}" in
	0 | "") tmoe_qemu_user_manager ;;
	1) tmoe_qemu_user_chart ;;
	2) install_qemu_user_static ;;
	3) remove_qemu_user_static ;;
	esac
	######################
	press_enter_to_return
	tmoe_qemu_user_static
}
#####################
tmoe_qemu_user_chart() {
	cat <<-'ENDofTable'
		下表中的所有系统均支持x64和arm64
		*表示仅旧版支持
			╔═══╦════════════╦════════╦════════╦═════════╦
			║   ║Architecture║        ║        ║         ║
			║   ║----------- ║ x86    ║armhf   ║ppc64el  ║
			║   ║System      ║        ║        ║         ║
			║---║------------║--------║--------║---------║
			║ 1 ║  Debian    ║  ✓     ║    ✓   ║   ✓     ║
			║   ║            ║        ║        ║         ║
			║---║------------║--------║--------║---------║
			║   ║            ║        ║        ║         ║
			║ 2 ║  Ubuntu    ║*<=19.10║  ✓     ║   ✓     ║
			║---║------------║--------║--------║---------║
			║   ║            ║        ║        ║         ║
			║ 3 ║ Kali       ║  ✓     ║   ✓    ║    X    ║
			║---║------------║--------║--------║---------║
			║   ║            ║        ║        ║         ║
			║ 4 ║ Arch       ║  X     ║   ✓    ║   X     ║
			║---║------------║--------║--------║---------║
			║   ║            ║        ║        ║         ║
			║ 5 ║ Fedora     ║ *<=29  ║ *<=29  ║  ✓      ║
			║---║------------║--------║--------║---------║
			║   ║            ║        ║        ║         ║
			║ 6 ║  Alpine    ║  ✓     ║    ✓   ║   ✓     ║
			║---║------------║--------║--------║---------║
			║   ║            ║        ║        ║         ║
			║ 7 ║ Centos     ║ *<=7   ║ *<=7   ║   ✓     ║
	ENDofTable
}
###############
check_gnu_linux_qemu_version() {
	if [ -e "${PREFIX}/bin/qemu-aarch64-static" ]; then
		LOCAL_QEMU_USER_FILE="${PREFIX}/bin/qemu-aarch64-static"
	elif [ -e "/usr/bin/qemu-aarch64-static" ]; then
		LOCAL_QEMU_USER_FILE='/usr/bin/qemu-aarch64-static'
	fi
	case ${LOCAL_QEMU_USER_FILE} in
	"") ;;
	*) LOCAL_QEMU_USER_VERSION=$(${LOCAL_QEMU_USER_FILE} --version | head -n 1 | awk '{print $5}' | cut -d ':' -f 2 | cut -d ')' -f 1) ;;
	esac
}
###########
install_qemu_user_static() {
	echo "正在检测版本信息..."
	LOCAL_QEMU_USER_FILE=''
	LOCAL_QEMU_USER_VERSION=''
	case ${LINUX_DISTRO} in
	Android)
		if [ -e "${QEMU_USER_LOCAL_VERSION_FILE}" ]; then
			LOCAL_QEMU_USER_VERSION=$(cat ${QEMU_USER_LOCAL_VERSION_FILE} | head -n 1)
		fi
		;;
	*) check_gnu_linux_qemu_version ;;
	esac

	case ${LOCAL_QEMU_USER_VERSION} in
	"") LOCAL_QEMU_USER_VERSION='您尚未安装QEMU-USER-STATIC' ;;
	*) ;;
	esac

	cat <<-'EOF'
		---------------------------
		一般来说，新版的qemu-user会引入新的功能，并带来性能上的提升。
		尽管有可能会引入一些新bug，但是也有可能修复了旧版的bug。
		We recommend that you to use the new version.
		---------------------------
	EOF
	check_qemu_user_version
	cat <<-ENDofTable
		╔═══╦══════════╦═══════════════════╦════════════════════
		║   ║          ║                   ║                    
		║   ║ software ║    ✨最新版本     ║   本地版本 🎪
		║   ║          ║  Latest version   ║  Local version     
		║---║----------║-------------------║--------------------
		║ 1 ║qemu-user ║                    ${LOCAL_QEMU_USER_VERSION} 
		║   ║ static   ║$(echo ${THE_LATEST_DEB_VERSION_CODE} | sed 's@%2B@+@')

	ENDofTable
	do_you_want_to_continue
	THE_LATEST_DEB_LINK="${REPO_URL}${THE_LATEST_DEB_VERSION}"
	echo "${YELLOW}${THE_LATEST_DEB_LINK}${RESET}"
	echo ${THE_LATEST_DEB_VERSION_CODE} | sed 's@%2B@+@' >${QEMU_USER_LOCAL_VERSION_FILE}
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		apt update
		echo 'apt install -y qemu-user-static'
		apt install -y qemu-user-static
	else
		download_qemu_user
	fi
}
##############
check_qemu_user_version() {
	REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/q/qemu/'
	THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '.deb' | grep 'qemu-user-static' | grep "${TRUE_ARCH_TYPE}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	THE_LATEST_DEB_VERSION_CODE=$(echo ${THE_LATEST_DEB_VERSION} | cut -d '_' -f 2)
}
###############
unxz_deb_file() {
	if [ ! $(command -v ar) ]; then
		DEPENDENCY_01='binutils'
		apt update
		echo "apt install -y ${DEPENDENCY_01}"
		apt install -y ${DEPENDENCY_01} || pacman -S ${DEPENDENCY_01} || dnf install ${DEPENDENCY_01} || apk add ${DEPENDENCY_01} || zypper in ${DEPENDENCY_01} || port install ${DEPENDENCY_01} || guix package -i ${DEPENDENCY_01} || pkg install ${DEPENDENCY_01} || pkg_add ${DEPENDENCY_01} || pkgutil -i ${DEPENDENCY_01} || eopkg install ${DEPENDENCY_01}
	fi
	ar xv ${THE_LATEST_DEB_VERSION}
	#tar -Jxvf data.tar.xz ./usr/bin -C $PREFIX/..
	tar -Jxvf data.tar.xz
}
########################
copy_qemu_user_bin_files() {
	cp -rf ./usr/bin ${QEMU_BIN_PREFIX}
	cd ..
	rm -rv ${TEMP_FOLDER}
}
######################
download_qemu_user() {
	if [ -z ${TMPDIR} ]; then
		TMPDIR=/tmp
		#mkdir -p ${TMPDIR}
		#chmod 777 /tmp
	fi
	cd ${TMPDIR}
	TEMP_FOLDER='.QEMU_USER_BIN'
	mkdir -p ${TEMP_FOLDER}
	cd ${TEMP_FOLDER}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_VERSION}" "${THE_LATEST_DEB_LINK}"
	unxz_deb_file
	copy_qemu_user_bin_files
}
##############
remove_qemu_user_static() {
	ls -lah /usr/bin/qemu-*-static ${QEMU_BIN_PREFIX}/bin/qemu-*-static 2>/dev/null
	echo "${RED}rm -rv${RESET} ${BLUE}${QEMU_BIN_PREFIX}/bin/qemu-*-static ${QEMU_USER_LOCAL_VERSION_FILE}${RESET}"
	echo "${RED}${TMOE_REMOVAL_COMMAND}${RESET} ${BLUE}qemu-user-static${RESET}"
	do_you_want_to_continue
	rm -rv ${QEMU_BIN_PREFIX}/bin/qemu-*-static "${QEMU_BIN_PREFIX}/bin/qemu-*-static" ${QEMU_USER_LOCAL_VERSION_FILE}
	${TMOE_REMOVAL_COMMAND} qemu-user-static
}
###############
qemu_user_env() {
	QEMU_USER_LOCAL_VERSION_FILE="${CONFIG_FOLDER}/qemu-user-static_version.txt"
	case ${LINUX_DISTRO} in
	Android) QEMU_BIN_PREFIX=${PREFIX} ;;
	*) QEMU_BIN_PREFIX=/usr ;;
	esac
}
##########
creat_tmoe_arch_file() {
	cat >${ACROSS_ARCH_FILE} <<-EOF
		${NEW_TMOE_ARCH}
		${TMOE_QEMU_ARCH}
	EOF
}
#############
tmoe_qemu_user_manager() {
	cd ${CONFIG_FOLDER}
	NEW_TMOE_ARCH=''
	RETURN_TO_WHERE='tmoe_qemu_user_manager'
	BETA_SYSTEM=$(
		whiptail --title "跨架构运行容器" --menu "您想要(模拟)运行哪个架构？\nWhich architecture do you want to simulate?" 0 50 0 \
			"0" "🌚 Back to the main menu 返回主菜单" \
			"00" "qemu-user-static管理(跨架构模拟所需的基础依赖)" \
			"01" "i386(常见于32位cpu的旧式传统pc)" \
			"02" "x64/amd64(2020年最主流的64位架构,应用于pc和服务器）" \
			"03" "arm64（2020年移动平台主流cpu架构）" \
			"04" "armhf(32位arm架构,支持硬浮点运算)" \
			"05" "armel(支持软浮点运算,常见于旧设备）" \
			"06" "ppc64el(PowerPC,应用于通信、工控、航天国防等领域)" \
			"07" "s390x(常见于IBM大型机)" \
			"08" "mipsel(暂仅适配debian stable,常见于龙芯cpu或和嵌入式设备)" \
			"09" "riscv64（开源架构,精简指令集）" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${BETA_SYSTEM}" in
	0 | "") tmoe_manager_main_menu ;;
	00) tmoe_qemu_user_static ;;
	01)
		NEW_TMOE_ARCH='i386'
		case ${TRUE_ARCH_TYPE} in
		amd64 | i386) TMOE_QEMU_ARCH="" ;;
		*) TMOE_QEMU_ARCH="${NEW_TMOE_ARCH}" ;;
		esac
		;;
	02)
		NEW_TMOE_ARCH='amd64'
		TMOE_QEMU_ARCH="x86_64"
		;;
	03)
		NEW_TMOE_ARCH='arm64'
		TMOE_QEMU_ARCH="aarch64"
		;;
	04)
		NEW_TMOE_ARCH='armhf'
		case ${TRUE_ARCH_TYPE} in
		arm64 | armhf) TMOE_QEMU_ARCH="" ;;
		*) TMOE_QEMU_ARCH="arm" ;;
		esac
		;;
	05)
		NEW_TMOE_ARCH='armel'
		case ${TRUE_ARCH_TYPE} in
		arm64 | armhf | armel) TMOE_QEMU_ARCH="" ;;
		*) TMOE_QEMU_ARCH="armeb" ;;
		esac
		;;
	06)
		NEW_TMOE_ARCH='ppc64el'
		TMOE_QEMU_ARCH="ppc64le"
		;;
	07)
		NEW_TMOE_ARCH='s390x'
		TMOE_QEMU_ARCH="${NEW_TMOE_ARCH}"
		;;
	08)
		NEW_TMOE_ARCH='mipsel'
		TMOE_QEMU_ARCH="${NEW_TMOE_ARCH}"
		;;
	09)
		if [ "${TRUE_ARCH_TYPE}" != 'riscv' ]; then
			echo '检测到您当前可能不是riscv架构'
			echo '本工具暂不对您的架构开放，且对于risc-v架构的设备，也将自动识别为其他架构'
			press_enter_to_return
			tmoe_qemu_user_manager
		fi
		NEW_TMOE_ARCH='riscv'
		TMOE_QEMU_ARCH="riscv64"
		;;
	esac
	######################
	if [ ! -z "${NEW_TMOE_ARCH}" ]; then
		if [ "${TRUE_ARCH_TYPE}" = "${NEW_TMOE_ARCH}" ]; then
			TMOE_QEMU_ARCH=""
		fi
		creat_tmoe_arch_file
		ARCH_TYPE=${NEW_TMOE_ARCH}

		if [ ! -e "$PREFIX/bin/qemu-x86_64-static" ] && [ ! -e "/usr/bin/qemu-x86_64-static" ]; then
			install_qemu_user_static
		fi
		choose_which_gnu_linux_distro
	fi
	press_enter_to_return
	tmoe_qemu_user_manager
}
#####################
git_clone_tmoe_linux_container_file() {
	if [ ! $(command -v debian-i) ]; then
		aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh' || curl -Lo ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh' || sudo -E aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh'
		chmod +x ${PREFIX}/bin/debian-i
	fi
	TMOE_TRUE_TEMP_FOLDER='.TMOE_LINUX_CONTAINER_TEMP_FOLDER'
	mkdir -p ${TMOE_TRUE_TEMP_FOLDER}
	cd ${TMOE_TRUE_TEMP_FOLDER}

	TMOE_TEMP_FOLDER=".${DOWNLOAD_FILE_NAME}_CONTAINER_TEMP_FOLDER_01"
	git clone --depth=1 -b ${BRANCH_NAME} ${TMOE_LINUX_CONTAINER_REPO_01} ${TMOE_TEMP_FOLDER}
	cd ${TMOE_TEMP_FOLDER}
	mv .container_linux_* ..
	cd ..
	if [ ! -z ${TMOE_LINUX_CONTAINER_REPO_02} ]; then
		TMOE_TEMP_FOLDER=".${DOWNLOAD_FILE_NAME}_CONTAINER_TEMP_FOLDER_02"
		git clone --depth=1 -b ${BRANCH_NAME} ${TMOE_LINUX_CONTAINER_REPO_02} ${TMOE_TEMP_FOLDER}
		cd ${TMOE_TEMP_FOLDER}
		mv .container_linux_* ..
		cd ..
	fi
	if [ ! -z ${TMOE_LINUX_CONTAINER_REPO_03} ]; then
		TMOE_TEMP_FOLDER=".${DOWNLOAD_FILE_NAME}_CONTAINER_TEMP_FOLDER_03"
		git clone --depth=1 -b ${BRANCH_NAME} ${TMOE_LINUX_CONTAINER_REPO_03} ${TMOE_TEMP_FOLDER}
		cd ${TMOE_TEMP_FOLDER}
		mv .container_linux_* ..
		cd ..
	fi
	echo "Debian恢复包内的数百张壁纸来自于影之音酱"
	cat .container_linux_* >${DOWNLOAD_FILE_NAME}
	mv -f ${DOWNLOAD_FILE_NAME} ../
	cd ../
	rm -rf ${TMOE_TRUE_TEMP_FOLDER}
}
#################
check_tmoe_linux_container_rec_pkg_file_and_git() {
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it, or download it again?\n检测到恢复包已经下载,\n您想要直接解压还是重新下载？" 0 0); then
			echo "解压后将覆盖容器的所有数据"
			do_you_want_to_continue
		else
			git_clone_tmoe_linux_container_file
		fi
	else
		git_clone_tmoe_linux_container_file
	fi
	verify_sha256sum
	un_xz_debian_recovery_kit
}
########################
debian_sid_arm64_xfce_recovery_package() {
	echo "即将为您下载至${DOWNLOAD_PATH}"
	echo '下载大小约1.5G,解压后约占5.8G'
	#echo "2020-07-11凌晨注：忘记给LibreOffice打补丁了 (ㄒoㄒ)/~~，请在安装完成后使用tmoe-linux tool给libreoffice打补丁"
	CORRENTSHA256SUM='5c85ec7857539025fc9744d89b10655219dcd2a535da0f20bd405d28512dfe59' #DevSkim: ignore DS173237
	BRANCH_NAME='arm64'
	TMOE_LINUX_CONTAINER_REPO_01='https://gitee.com/ak2/debian_sid_rootfs_01'
	TMOE_LINUX_CONTAINER_REPO_02='https://gitee.com/ak2/debian_sid_rootfs_02'
	TMOE_LINUX_CONTAINER_REPO_03='https://gitee.com/ak2/debian_sid_rootfs_03'
	DOWNLOAD_FILE_NAME='debian-sid+xfce4.14_2020-08-29_18-13-rootfs_bak.tar.xz'
	check_tmoe_linux_container_rec_pkg_file_and_git
}
##################
debian_buster_arm64_xfce_recovery_package() {
	echo "即将为您下载至${DOWNLOAD_PATH}"
	echo '下载大小约573MiB,解压后约占2.2G'
	CORRENTSHA256SUM='a7106647f7b4577c3e9868d790f1bea5464b38362785a592cb5283f44b976512' #DevSkim: ignore DS173237
	BRANCH_NAME='arm64'
	TMOE_LINUX_CONTAINER_REPO_01='https://gitee.com/ak2/debian_stable_rootfs_01'
	TMOE_LINUX_CONTAINER_REPO_02='https://gitee.com/ak2/debian_stable_rootfs_02'
	TMOE_LINUX_CONTAINER_REPO_03=''
	DOWNLOAD_FILE_NAME='debian-buster_arm64-xfce4.12+music-app_2020-08-28_18-27-rootfs_bak.tar.xz'
	check_tmoe_linux_container_rec_pkg_file_and_git
}
#################
install_debian_sid_via_tuna() {
	if [ "${LINUX_DISTRO}" != 'iSH' ]; then
		bash -c "$(curl -fLsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh')"
	else
		curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh' | bash
	fi
}
#################
install_debian_gnu_linux_container_via_rec_pkg() {
	#Do you want to install debian container via Tsinghua University open source mirror station,\nor download the recovery package (debian-xfce.tar.xz)?\n您想要通过软件源镜像站来安装，还是在线下载恢复包来安装？\n软件源获取的是最新版镜像，且支持arm64,armhf,x86,x64等架构,\n安装基础系统速度很快，但安装gui速度较慢。\n恢复包非最新版,软件包只更新至2020-07-10,且仅支持arm64架构,但安装gui速度较快。\n若您无使用GUI的需求，建议通过软件源镜像站来安装。" 0 50 0 \
	BETA_SYSTEM=$(whiptail --title "Download recovery package and install container" --menu "恢复包在解压完成后，将根据系统对权限的限制来判断特殊文件的挂载与否。" 0 50 0 \
		"1" "arm64 sid xfce,600+P,1.5G,20200829" \
		"2" "arm64 buster xfce,200+P,573M,20200828" \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##############################
	#"1" "netinstall(通过软件源在线安装)" \
	case "${BETA_SYSTEM}" in
	0 | "") install_debian_gnu_linux_distro ;;
	1) DISTRO_CODE='sid' ;;
	2) DISTRO_CODE='buster' ;;
	esac
	######################
	case ${TRUE_ARCH_TYPE} in
	arm64) ;;
	*)
		echo "Sorry，恢复包暂未支持跨架构运行"
		press_enter_to_return
		install_debian_gnu_linux_distro
		;;
	esac
	case ${TMOE_CHROOT} in
	true)
		echo "检测到您选择的是chroot容器,暂不支持恢复,请在线安装。"
		press_enter_to_return
		install_debian_gnu_linux_distro
		;;
	esac
	TMOE_LINUX_CONTAINER_DISTRO="${DISTRO_NAME}-${DISTRO_CODE}"
	creat_container_edition_txt
	echo "即将为您安装Debian ${DISTRO_CODE} GNU/Linux container"
	do_you_want_to_continue
	case "${DISTRO_CODE}" in
	buster) debian_buster_arm64_xfce_recovery_package ;;
	sid) debian_sid_arm64_xfce_recovery_package ;;
	esac
	###############
	exit 0
	#press_enter_to_return
	#tmoe_manager_main_menu
}
###########
install_debian_buster_via_tuna() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed "s:/sid:/${DISTRO_CODE}:g" |
		sed "s:-sid:-${DISTRO_CODE}:g" |
		sed "s@debian/ stable@debian/ ${DISTRO_CODE}@g" |
		sed "s@stable/updates@${DISTRO_CODE}/updates@g" |
		sed "s@buster-backports@${DISTRO_CODE}-backports@g" |
		sed 's@#deb http@deb http@g' |
		sed 's/.*sid main/#&/')"
}
############
install_debian_testing_via_tuna() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed "s:/sid:/${DISTRO_CODE}:g" |
		sed "s:-sid:-${DISTRO_CODE}:g" |
		sed "s@debian/ stable@debian/ ${DISTRO_CODE}@g" |
		sed "s@stable/updates@${DISTRO_CODE}-security@g" |
		sed "s@buster-backports@${DISTRO_CODE}-backports@g" |
		sed 's@#deb http@deb http@g' |
		sed 's/.*sid main/#&/')"
}
#################
#BUSTER更加稳定且bug较少,但软件包较旧,而sid较新。\nBuster is more stable and has fewer bugs
creat_container_edition_txt() {
	echo ${TMOE_LINUX_CONTAINER_DISTRO} >${LINUX_CONTAINER_DISTRO_FILE}
}
#############
install_debian_gnu_linux_distro() {
	RETURN_TO_WHERE='install_debian_gnu_linux_distro'
	DOWNLOAD_PATH="/sdcard/Download/backup"
	#DISTRO_CODE=''
	DISTRO_NAME='debian'
	LXC_IMAGES_REPO="https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/${DISTRO_NAME}/"
	#\nStable版更加稳定且bug较少,但stable的软件包较旧,而sid较新。\nBuster is more stable and has fewer bugs,\nbut the packages inside the buster software source are older.\nThe sid package is relatively new.
	BETA_SYSTEM=$(
		whiptail --title "请选择您需要安装的debian version" --menu "Buster为2019~2021年的stable版,sid永远都为unstable,sid的软件包较新。\nStable has fewer bugs,\nbut the packages inside the software source are older." 0 50 0 \
			"1" "👦Sid(滚动更新,隔壁的男孩席德,玩具终结者)" \
			"2" "recovery pkg 恢复包" \
			"3" "🐶10-buster(2019~2022,安弟一家养的小狗)" \
			"4" "Custom code手动输入版本代号" \
			"5" "🐎11-bullseye(2021~2024,胡迪骑的马)" \
			"6" "📕🐛12-bookworm(2023~2026,熊抱哥的手下)" \
			"7" "自动检测debian-13 (2025~2028)" \
			"8" "🐙9-stretch(2017~2020,玩具总动员3中的章鱼)" \
			"9" "🤠8-jessie(2015~2018,翠丝,女牛仔)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${BETA_SYSTEM}" in
	0 | "") choose_which_gnu_linux_distro ;;
	1) DISTRO_CODE='sid' ;;
	2)
		DISTRO_CODE=""
		install_debian_gnu_linux_container_via_rec_pkg
		;;
	3) DISTRO_CODE='buster' ;;
	4) custom_debian_version ;;
	5) DISTRO_CODE='bullseye' ;;
	6) check_debian_12 ;;
	7) check_debian_new_version ;;
	8) DISTRO_CODE='stretch' ;;
	9) DISTRO_CODE='jessie' ;;
	esac
	######################
	TMOE_LINUX_CONTAINER_DISTRO="${DISTRO_NAME}-${DISTRO_CODE}"
	creat_container_edition_txt
	echo "即将为您安装Debian ${DISTRO_CODE} GNU/Linux container"
	do_you_want_to_continue
	case "${DISTRO_CODE}" in
	squeeze | wheezy | jessie | stretch | buster) install_debian_buster_via_tuna ;;
	sid) install_debian_sid_via_tuna ;;
	"") ;;
	*) install_debian_testing_via_tuna ;;
	esac
	###############
	exit 0
	#press_enter_to_return
	#tmoe_manager_main_menu
}
#########################
#"9" "🐧7-wheezy(2013~2016,吱吱,带着领结的玩具企鹅)" \
#"10" "👽6-squeeze(2011~2014,三只眼的外星人)" \
############
check_debian_12() {
	#DISTRO_CODE='bookworm'
	DISTRO_CODE=$(curl -L ${LXC_IMAGES_REPO} | grep date | cut -d '=' -f 4 | cut -d '"' -f 2 | grep -Ev 'jessie|stretch|buster|bullseye|sid|size' | tail -n 1)
	if [ -z ${DISTRO_CODE} ]; then
		echo "检测到debian12尚未发布，建议您等到2023年时再来尝试"
		echo "如需体验最新版本，请安装debian sid，并添加experimental软件源"
		press_enter_to_return
		install_debian_gnu_linux_distro
	fi
}
#############
custom_debian_version() {
	TARGET=$(whiptail --inputbox "请输入最近四年的debian版本代号，例如buster(英文小写)\n Please enter the debian version code." 12 50 --title "DEBIAN CODE" 3>&1 1>&2 2>&3)
	DISTRO_CODE="$(echo ${TARGET} | head -n 1 | cut -d ' ' -f 1)"
	if [ -z "${DISTRO_CODE}" ]; then
		echo "检测到您取消了操作"
		echo "已自动切换为debian11(代号bullseye)"
		DISTRO_CODE='bullseye'
	fi
}
#################
check_debian_new_version() {
	DISTRO_CODE=$(curl -L ${LXC_IMAGES_REPO} | grep date | cut -d '=' -f 4 | cut -d '"' -f 2 | grep -Ev 'jessie|stretch|buster|bullseye|bookworm|sid|size' | tail -n 1)
	if [ -z ${DISTRO_CODE} ]; then
		echo "检测到debian13尚未发布，建议您等到2025年时再来尝试"
		echo "如需体验最新版本，请安装debian sid，并添加experimental软件源"
		press_enter_to_return
		install_debian_gnu_linux_distro
	fi
}
#####################################
verify_sha256sum() {
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
		現在可公開的情報:
			${BOLD}Tmoe-linux 小提示01${RESET}:

				输${GREEN}startx11vnc${RESET}启动${BLUE}x11vnc服务${RESET},x11vnc能运行tightvnc无法打开的某些应用哦！
				-------------------
				You can type ${GREEN}startx11vnc${RESET} to start ${BLUE}x11vnc server${RESET},type ${RED}stopvnc${RESET} to stop it.
				------------------
				在容器内输${GREEN}debian-i${RESET}启动软件安装及远程桌面配置${BLUE}管理工具${RESET}。
				-------------------
	EOF
	echo 'Verifying sha256hash...'
	echo '正在校验sha256哈希值...'
	echo "${GREEN}${CORRENTSHA256SUM}${RESET}"
	LOCAL_FILE_SHA256_SUM="$(sha256sum ${DOWNLOAD_FILE_NAME} | cut -c 1-64)"
	if [ "${LOCAL_FILE_SHA256_SUM}" != "${CORRENTSHA256SUM}" ]; then
		echo "当前文件的sha256校验值为${RED}${LOCAL_FILE_SHA256_SUM}${RESET}"
		echo "远程文件的sha256校验值为${CORRENTSHA256SUM}"
		echo 'sha256校验值不一致，请重新下载！'
		echo 'sha256hash value is inconsistent, please download again.'
		echo "按回车键无视错误并继续安装,按Ctrl+C取消。"
		do_you_want_to_continue
	else
		echo 'Congratulations,检测到sha256哈希值一致'
		echo 'Detected that sha256hash is the same as the source code, and your download is correct.'
	fi
}
##########################
copy_tmoe_locale_file_to_container() {
	TMOE_LOCALE_FILE="${HOME}/.config/tmoe-linux/locale.txt"
	if [ -e "${TMOE_LOCALE_FILE}" ]; then
		TMOE_LOCALE_NEW_PATH="${DEBIAN_CHROOT}/usr/local/etc/tmoe-linux"
		mkdir -p ${TMOE_LOCALE_NEW_PATH}
		cp -f ${TMOE_LOCALE_FILE} ${TMOE_LOCALE_NEW_PATH}
		TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
		PROOT_LANG=$(cat $(command -v debian) | grep LANG= | cut -d '"' -f 2 | cut -d '=' -f 2 | tail -n 1)
		sed -i "s@${PROOT_LANG}@${TMOE_LANG}@" $(command -v debian)
	fi
}
########################
un_xz_debian_recovery_kit() {
	printf "$BLUE"
	cat <<-'EndOFneko'
		       DL.                           
		       QBBBBBKv:rr77ri:.             
		       gBBQdY7::::..::i7vv.          
		       UBd. . .:.........rBBBQBBBB5  
		       Pu  :..r......i:....BBBQBBB:  
		       ri.i:.j:...:. i7... uBBZrd:   
		 :     7.:7.7U.:..r: Yr:.. iQ1:qU    
		.Qi   .7.ii.X7:...L.:qr:...iB7ZQ     
		 .27. :r.r:L7i::.7r:vri:...rr  .     
		  v   ::.Yrviri:7v7v: ::...i.   i    
		      r:ir: r.iiiir..:7r...r   :P.2Y 
		      v:vi::.      :  ::. .qI7U1U :1 
		Qr    7.7.         :.i::. :Di:. i .v:
		v7..  s.r7.   ...   .:7i: rDi...r .. 
		 vi: .7.iDBBr  .r   .:.7. rPr:..r    
		 i   :virZBgi  :vrYJ1vYY .ruY:..i    
		     YrivEv. 7BBRBqj21I7 .77J:.:.PQ  
		    .1r:q.   rB52SKrj.:i i5isi.:i :.r
		    YvrY7    r.  . ru :: PIrj7.:r..v 
		   rSviYI..iuU .:.:i:.7.KPPiSr.:vr   
		  .u:Y:JQMSsJUv...   .rDE1P71:.7X7   
		  5  Ivr:QJ7JYvi....ir1dq vYv.7L.Y   
		  S  7Z  Qvr:.iK55SqS1PX  Xq7u2 :7   
		         .            i   7          
	EndOFneko
	printf "$RESET"
	echo "正在解压${DOWNLOAD_FILE_NAME}，decompressing recovery package, please be patient."
	#pv "debian_2020-03-11_17-31.tar.xz" | tar -PpJx 2>/dev/null
	cat <<-EOF
		少女祈禱中...
			${BOLD}Tmoe-linux 小提示02${RESET}:

				若您的宿主机为${BOLD}Android${RESET}系统,则在termux原系统下输${GREEN}startvnc${RESET}将${RED}同时启动${RESET}安卓版Realvnc${YELLOW}客户端${RESET}和GNU/Linux的VNC${YELLOW}服务端${RESET}。
				-------------------
				输${GREEN}debian${RESET}仅启动${BLUE}GNU/Linux容器${RESET}，不会���动启动远程桌面服务。
				-------------------
				您可以在解压完成之后输${GREEN}startvnc${RESET}来启动${BLUE}tight或tigervnc服务${RESET}，输${RED}stopvnc${RESET}停止
				-------------------
				You can type ${GREEN}startvnc${RESET} to start ${BLUE}tight/tigervnc server${RESET},type ${RED}stopvnc${RESET} to stop it.
				-------------------
	EOF
	echo "正在${GREEN}解压${RESET}中..."
	echo "少女祈禱中..."
	if [ ! "$(command -v pv)" ] || [ "${TMOE_CHROOT}" = 'true' ]; then
		${TMOE_PREFIX} tar -PpJxvf ${DOWNLOAD_FILE_NAME}
	else
		pv ${DOWNLOAD_FILE_NAME} | tar -PpJx
	fi
	cd "$cur"
	#用绝对路径
	#if [ ! -h '/data/data/com.termux/files/home/storage/external-1' ]; then
	#	sed -i 's@^command+=" --mount=/data/data/com.termux/files/home/storage/external-1@#&@g' ${PREFIX}/bin/debian 2>/dev/null
	#	rm -f ${DEBIAN_CHROOT}/root/tf 2>/dev/null
	#fi
	#if [ -e "${HOME}/debian_arm64" ]; then
	#	sed -i 's@debian-sid_arm64@debian_arm64@g' ${PREFIX}/bin/startvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm
	#fi
	echo 'The vnc server is about to start for you.'
	# The password you entered is hidden.'
	#echo '即将为您启动vnc服务，您需要输两遍（不可见的）密码。'
	#echo "When prompted for a view-only password, it is recommended that you enter 'n'"
	#echo '如果提示view-only,那么建议您输n,选择权在您自己的手上。'
	copy_tmoe_locale_file_to_container
	echo '请输入6至8位的VNC密码'
	switch_termux_rootfs_to_linux
	check_proot_proc_permissions
	source ${PREFIX}/bin/startvnc
}
###############################
check_proot_proc_permissions() {
	TMOE_LINUX_ETC_DIR=$(cat ${PREFIX}/bin/debian | grep 'set.*mount.*proot_proc/' | head -n 1 | awk '{print $3}' | cut -d '=' -f 2 | cut -d '"' -f 1 | cut -d ':' -f 1 | sed 's@/proot_proc.*@@g')
	TMOE_PROC_PATH="${TMOE_LINUX_ETC_DIR}/proot_proc"
	TMOE_PROC_PREFIX="${TMOE_PROC_PATH}/.tmoe-container"
	#######
	for i in buddyinfo cgroups consoles crypto devices diskstats execdomains fb filesystems interrupts iomem ioports kallsyms keys key-users kpageflags loadavg locks misc modules pagetypeinfo partitions sched_debug softirqs timer_list uptime vmallocinfo vmstat zoneinfo; do
		TMOE_PROC_FILE=$(cat /proc/${i} 2>/dev/null)
		if [ ! -z "${TMOE_PROC_FILE}" ]; then
			sed -i "s@set.*tmoe-linux/proot_proc/${i}@#&@g" ${PREFIX}/bin/debian
		else
			echo "检测到您无权读取${BLUE}/proc/${i}${RESET},修复中..."
			echo "${GREEN}Fixing${RESET} ${YELLOW}/proc/${i}${RESET}..."
			#TMOE_PROC_LINE=$(cat debian | grep -n "set.*tmoe-linux/proot_proc/${i}" | awk '{print $1}' | cut -d ':' -f 1)
			#sed -i "${TMOE_PROC_LINE}s@#.*set --@set --@" ${PREFIX}/bin/debian
			sed -i "s@#.*set -- \"--mount=${TMOE_PROC_PATH}/${i}@set -- \"--mount=${TMOE_PROC_PATH}/${i}@" ${PREFIX}/bin/debian
		fi
	done
	unset i
	#####
	FILE_03='/proc/bus/pci/devices'
	TMOE_PROC_FILE=$(cat ${FILE_03} 2>/dev/null)
	if [ ! -z "${TMOE_PROC_FILE}" ]; then
		sed -i "s@set.*tmoe-linux/proot_proc/bus@#&@g" ${PREFIX}/bin/debian
	else
		#TMOE_PROC_LINE=$(cat debian | grep -n "set.*tmoe-linux/proot_proc/bus" | awk '{print $1}' | cut -d ':' -f 1)
		#sed -i "${TMOE_PROC_LINE}s@#.*set --@set --@" ${PREFIX}/bin/debian
		sed -i "s@#.*set -- \"--mount=${TMOE_PROC_PATH}/bus@set -- \"--mount=${TMOE_PROC_PATH}/bus@" ${PREFIX}/bin/debian
	fi
	#######
	FILE_02=stat
	TMOE_PROC_FILE=$(cat /proc/${FILE_02} 2>/dev/null)
	if [ -z "${TMOE_PROC_FILE}" ]; then
		sed -i "s@#.*set -- \"--mount=${TMOE_PROC_PREFIX}.${FILE_02}@set -- \"--mount=${TMOE_PROC_PREFIX}.${FILE_02}@" ${PREFIX}/bin/debian
	else
		sed -i "s@set.*tmoe-linux/proot_proc/${FILE_02}@#&@g" debian
	fi
	#####
	FILE_01=version
	TMOE_PROC_FILE=$(cat /proc/${FILE_01} 2>/dev/null)
	if [ -z "${TMOE_PROC_FILE}" ]; then
		echo "检测到您无权读取${BLUE}/proc/version${RESET},正在自动伪造新文件..."
		echo "你的version文件内容将被伪造成${YELLOW}$(uname -a) (gcc version 10.1.0 20200630 (prerelease) (GCC) )${RESET}"
		echo "$(uname -a) (gcc version 10.1.0 20200630 (prerelease) (GCC) )" >"${TMOE_PROC_PREFIX}.${FILE_01}"
	else
		sed -i "s@set.*tmoe-linux/proot_proc/${FILE_01}@#&@g" debian
	fi
}
############################
switch_termux_rootfs_to_linux() {
	if [ "${LINUX_DISTRO}" != 'Android' ]; then
		cd /data/data/com.termux/files/usr/bin
		sed -i 's:#!/data/data/com.termux/files/usr/bin/env bash:#!/usr/bin/env bash:g' $(grep -rl 'com.termux' ./)
		#sed -i 's:#!/data/data/com.termux/files/usr/bin/env bash:#!/usr/bin/env bash:' ${DEBIAN_CHROOT}/remove-debian.sh
		cp -pf ./* ${PREFIX}/bin/
	fi
}
####################
tmoe_install_xfce() {
	if [ "${LINUX_DISTRO}" != 'Android' ]; then
		aria2c --allow-overwrite=true -d /tmp -o '.tmoe-linux-tool.sh' 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		bash /tmp/.tmoe-linux-tool.sh --install-gui
		exit 0
	fi

	if [ -e "${PREFIX}/bin/xfwm4" ]; then
		echo "检测到您已安装，是否继续？"
		echo 'Press enter to continue'
		echo "${YELLOW}按回车键确认继续,按Ctrl+C取消。${RESET}"
		read
	fi
	apt update
	apt install -y x11-repo
	apt update
	apt dist-upgrade -y

	apt install -y xfce tigervnc aterm
	cat >${PREFIX}/bin/startvnc <<-'EndOfFile'
		#!/data/data/com.termux/files/usr/bin/env bash
		pkill Xvnc 2>/dev/null 
		pulseaudio --kill 2>/dev/null
		pulseaudio --start
		echo "正在启动vnc服务,本机默认vnc地址localhost:5901"
		echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):5901
		export DISPLAY=:1
		Xvnc -geometry 720x1440 -depth 24 --SecurityTypes=None $DISPLAY &
		export PULSE_SERVER=127.0.0.1
		am start -n com.realvnc.viewer.android/com.realvnc.viewer.android.app.ConnectionChooserActivity
		sleep 1s
		thunar &
		echo "已为您启动vnc服务 Vnc server has been started, enjoy it!"
		echo "默认为前台运行，您可以按Ctrl+C终止当前进程。"
		startxfce4

	EndOfFile
	chmod +x ${PREFIX}/bin/startvnc
	source ${PREFIX}/bin/startvnc
}
##########
tmoe_modify_vnc_conf() {
	if [ "${LINUX_DISTRO}" != 'Android' ]; then
		aria2c --allow-overwrite=true -d /tmp -o '.tmoe-linux-tool.sh' 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		bash /tmp/.tmoe-linux-tool.sh --modify_remote_desktop_config
		exit 0
	fi
	modify_android_termux_vnc_config
}
#########
tmoe_switch_sources_list() {
	if [ "${LINUX_DISTRO}" = 'Android' ]; then
		tmoe_sources_list_manager
		#termux_tuna_sources_list
	else
		gnu_linux_mirror_source_manager
	fi
}
##########
ustc_termux() {
	if (("${ANDROID_VERSION}" < '7')); then
		SOURCE_MIRROR_STATION='mirrors.ustc.edu.cn'
		modify_android_termux_old_mirror_sources_list
		press_enter_to_return
		tmoe_sources_list_manager
	else
		SOURCE_MIRROR_STATION='bintray.proxy.ustclug.org'
		official_termux_mirror_source_format
	fi
}
#######
standard_termux_mirror_source_format() {
	TERMUX_MAIN_SOURCE="https://${SOURCE_MIRROR_STATION}/termux-packages-24 stable main"
	TERMUX_ROOT_SOURCE="https://${SOURCE_MIRROR_STATION}/termux-root-packages-24 root stable"
	TERMUX_GAME_SOURCE="https://${SOURCE_MIRROR_STATION}/game-packages-24 games stable"
	TERMUX_SCIENCE_SOURCE="https://${SOURCE_MIRROR_STATION}/science-packages-24 science stable"
	TERMUX_UNSTABLE_SOURCE="https://${SOURCE_MIRROR_STATION}/unstable-packages unstable main"
	TERMUX_X11_SOURCE="https://${SOURCE_MIRROR_STATION}/x11-packages x11 main"
}
#########
official_termux_mirror_source_format() {
	TERMUX_MAIN_SOURCE="https://${SOURCE_MIRROR_STATION}/termux/termux-packages-24 stable main"
	TERMUX_ROOT_SOURCE="https://${SOURCE_MIRROR_STATION}/grimler/termux-root-packages-24 root stable"
	TERMUX_GAME_SOURCE="https://${SOURCE_MIRROR_STATION}/grimler/game-packages-24 games stable"
	TERMUX_SCIENCE_SOURCE="https://${SOURCE_MIRROR_STATION}/grimler/science-packages-24 science stable"
	TERMUX_UNSTABLE_SOURCE="https://${SOURCE_MIRROR_STATION}/xeffyr/unstable-packages unstable main"
	TERMUX_X11_SOURCE="https://${SOURCE_MIRROR_STATION}/xeffyr/x11-packages x11 main"
}
########
xeffyr_termux_mirror_source_format() {
	TERMUX_MAIN_SOURCE="https://main.${SOURCE_MIRROR_STATION} stable main"
	TERMUX_ROOT_SOURCE="https://root.${SOURCE_MIRROR_STATION} root stable"
	TERMUX_GAME_SOURCE="https://games.${SOURCE_MIRROR_STATION} games stable"
	TERMUX_SCIENCE_SOURCE="https://science.${SOURCE_MIRROR_STATION} science stable"
	TERMUX_UNSTABLE_SOURCE="https://unstable.${SOURCE_MIRROR_STATION} unstable main"
	TERMUX_X11_SOURCE="https://x11.${SOURCE_MIRROR_STATION} x11 main"
	#TERMUX_EXTRA_SOURCE="https://its-pointless.${SOURCE_MIRROR_STATION} termux extras"
}
########
china_university_mirror_station() {
	#NEW_TERMUX_SOURCES_LIST='true'
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='china_university_mirror_station'
	SOURCES_LIST=$(
		whiptail --title "软件源列表" --menu \
			"您想要切换为哪个镜像源呢？" 0 50 0 \
			"1" "清华大学mirrors.tuna.tsinghua.edu.cn" \
			"2" "北京外国语大学mirrors.bfsu.edu.cn" \
			"3" "中国科学技术大学mirrors.ustc.edu.cn" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_sources_list_manager ;;
	1)
		SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn/termux'
		standard_termux_mirror_source_format
		;;
	2)
		SOURCE_MIRROR_STATION='mirrors.bfsu.edu.cn/termux'
		standard_termux_mirror_source_format
		;;
	3) ustc_termux ;;
	esac
	######################################
	modify_android_termux_mirror_sources_list
	press_enter_to_return
	china_university_mirror_station
}
#############
worldwide_mirror_station() {
	NEW_TERMUX_SOURCES_LIST='true'
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='worldwide_mirror_station'
	SOURCES_LIST=$(
		whiptail --title "TERMUX MIRROR SOURCE" --menu \
			"Which mirror source do you want to switch to?" 0 50 0 \
			"1" "official官方:termux.org/packages" \
			"2" "a1batross:termux.mentality.rip" \
			"3" "Grimler:grimler.se" \
			"4" "Xeffyr:termux-mirror.ml" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_sources_list_manager ;;
	1)
		SOURCE_MIRROR_STATION='dl.bintray.com'
		official_termux_mirror_source_format
		;;
	2)
		SOURCE_MIRROR_STATION='termux.mentality.rip'
		standard_termux_mirror_source_format
		;;
	3)
		SOURCE_MIRROR_STATION='grimler.se'
		standard_termux_mirror_source_format
		;;
	4)
		SOURCE_MIRROR_STATION='termux-mirror.ml'
		xeffyr_termux_mirror_source_format
		;;
	esac
	######################################
	modify_android_termux_mirror_sources_list
	press_enter_to_return
	worldwide_mirror_station
}
############
check_tmoe_sources_list_backup_file() {
	SOURCES_LIST_PATH="${PREFIX}/etc/apt/"
	SOURCES_LIST_FILE="${PREFIX}/etc/apt/sources.list"
	SOURCES_LIST_FILE_NAME="sources.list"
	SOURCES_LIST_BACKUP_FILE="${CONFIG_FOLDER}/sources-list_bak.tar.xz"
	SOURCES_LIST_BACKUP_FILE_02="${SOURCES_LIST_FILE}.bak"
	EXTRA_SOURCE='TERMUX额外源'
	if [ ! -e "${SOURCES_LIST_BACKUP_FILE}" ]; then
		cp -pf "${SOURCES_LIST_FILE}" "${SOURCES_LIST_BACKUP_FILE_02}"
		tar -PpcJvf ${SOURCES_LIST_BACKUP_FILE} ${SOURCES_LIST_FILE} "${SOURCES_LIST_FILE}.d"
	fi
}
##########
restore_default_sources_list() {
	if [ -e "${SOURCES_LIST_BACKUP_FILE}" ]; then
		tar -PpJxvf ${SOURCES_LIST_BACKUP_FILE}
		cat ${SOURCES_LIST_FILE}.d/* ${SOURCES_LIST_FILE}
	else
		echo "${RED}File is missing, restore failed.${RESET}"
		echo "备份文件丢失,恢复失败"
	fi
}
######################
ping_mirror_sources_list_count_3() {
	echo ${YELLOW}${SOURCE_MIRROR_STATION}${RESET}
	echo ${BLUE}${SOURCE_MIRROR_STATION_NAME}${RESET}
	ping -c 3 ${SOURCE_MIRROR_STATION} | grep -E 'avg|time.*ms' --color=auto
	echo "---------------------------"
}
##############
ping_mirror_sources_list() {
	echo "时间越短，延迟越低"
	echo "---------------------------"
	SOURCE_MIRROR_STATION_NAME='清华镜像站'
	SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='中科大反向代理站'
	SOURCE_MIRROR_STATION='bintray.proxy.ustclug.org'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='北外镜像站'
	SOURCE_MIRROR_STATION='mirrors.bfsu.edu.cn'
	ping_mirror_sources_list_count_3
	#SOURCE_MIRROR_STATION_NAME='官方official'
	#SOURCE_MIRROR_STATION='dl.bintray.com'
	#ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='a1batross'
	SOURCE_MIRROR_STATION='termux.mentality.rip'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='Grimler'
	SOURCE_MIRROR_STATION='grimler.se'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='Xeffyr'
	SOURCE_MIRROR_STATION='main.termux-mirror.ml'
	ping_mirror_sources_list_count_3
	###此处一定要将SOURCE_MIRROR_STATION赋值为空
	SOURCE_MIRROR_STATION=""
	echo "测试${YELLOW}完成${RESET}"
	echo "延迟${GREEN}时间低${RESET}并不意味着${BLUE}下载速度快。${RESET}"
	echo "请${YELLOW}自行${RESET}${BLUE}选择${RESET}"
}
##############
download_termux_clang() {
	echo ${BLUE}${SOURCE_MIRROR_STATION_NAME}${RESET}
	DOWNLOAD_FILE_URL="https://${SOURCE_MIRROR_STATION}/termux-packages-24/aarch64/${CLANG_FILE}"
	echo "${YELLOW}${DOWNLOAD_FILE_URL}${RESET}"
	aria2c --allow-overwrite=true -o ".tmoe_netspeed_test_${SOURCE_MIRROR_STATION_NAME}_temp_file" "${DOWNLOAD_FILE_URL}"
	rm -f ".tmoe_netspeed_test_${SOURCE_MIRROR_STATION_NAME}_temp_file"
	echo "---------------------------"
}
################
mirror_sources_station_download_speed_test() {
	echo "此操作可能会消耗您${YELLOW}数十至上百兆${RESET}的${BLUE}流量${RESET}"
	echo "在测试过程中，您可以按${YELLOW}Ctrl+C${RESET}取消。"
	do_you_want_to_continue
	cd ${TMPDIR}
	CLANG_FILE="$(curl -L dl.bintray.com/termux/termux-packages-24/aarch64/ | grep clang | head -n 1 | cut -d '"' -f 4 | cut -d ':' -f 2)"
	echo "---------------------------"
	SOURCE_MIRROR_STATION_NAME='清华镜像站'
	SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn/termux'
	download_termux_clang
	SOURCE_MIRROR_STATION_NAME='中科大反向代理站'
	SOURCE_MIRROR_STATION='bintray.proxy.ustclug.org/termux'
	download_termux_clang
	SOURCE_MIRROR_STATION_NAME='北外镜像站'
	SOURCE_MIRROR_STATION='mirrors.bfsu.edu.cn/termux'
	download_termux_clang
	SOURCE_MIRROR_STATION_NAME='官方official'
	SOURCE_MIRROR_STATION='dl.bintray.com/termux'
	download_termux_clang
	SOURCE_MIRROR_STATION_NAME='a1batross'
	SOURCE_MIRROR_STATION='termux.mentality.rip'
	download_termux_clang
	SOURCE_MIRROR_STATION_NAME='Grimler'
	SOURCE_MIRROR_STATION='grimler.se'
	download_termux_clang
	###此处一定要将SOURCE_MIRROR_STATION赋值为空
	SOURCE_MIRROR_STATION=""
	rm -f .tmoe_netspeed_test_*_temp_file
	echo "测试${YELLOW}完成${RESET}，已自动${RED}清除${RESET}${BLUE}临时文件。${RESET}"
	echo "下载${GREEN}速度快${RESET}并不意味着${BLUE}更新频率高。${RESET}"
	echo "请${YELLOW}自行${RESET}${BLUE}选择${RESET}"
}
######################
delete_sources_list_invalid_rows() {
	echo "执行此操作将删除软件源列表内的所有注释行,并自动去除重复行"
	do_you_want_to_continue
	sed -i '/^#/d' ${SOURCES_LIST_FILE}
	sed -i '/^#/d' ${SOURCES_LIST_FILE}.d/*list
	sort -u ${SOURCES_LIST_FILE} -o ${SOURCES_LIST_FILE}
	cat ${SOURCES_LIST_FILE}
}
###################
check_termux_repo() {
	cd ${SOURCES_LIST_FILE}.d
	if grep -q '^deb' ${TERMUX_REPO}.list; then
		TERMUX_REPO_ENABLED_STATUS="检测到您已启用本仓库\nYou have enabled ${TERMUX_REPO}-repo."
	else
		TERMUX_REPO_ENABLED_STATUS="检测到您已禁用本仓库\nYou have disabled ${TERMUX_REPO}-repo"
	fi
}
##########
enable_or_disable_termux_repo() {
	check_termux_repo
	if (whiptail --title "您想要对${TERMUX_REPO}小可爱做什么" --yes-button "enable启用" --no-button "disable禁用" --yesno "Do you want to enable or disable it?\n您是想要启用${TERMUX_REPO}-repo还是禁用呢？♪(^∇^*)\n${TERMUX_REPO_ENABLED_STATUS}" 9 50); then
		apt update
		apt install -y ${TERMUX_REPO}-repo
		apt list | grep "/${TERMUX_REPO}"
		echo "启用完成,默认为官方源"
	else
		apt purge -y ${TERMUX_REPO}-repo
		apt update
	fi
}
###########
termux_repo_manager() {
	RETURN_TO_WHERE='termux_repo_manager'
	SOURCES_LIST=$(
		whiptail --title "TERMUX REPO" --menu \
			"Which repo do you want to enable?" 0 50 0 \
			"1" "game:游戏" \
			"2" "root:适用于已root设备" \
			"3" "science:科学软件仓库" \
			"4" "unstable:包含了最新/不稳定的包" \
			"5" "x11:包含了桌面应用和qemu虚拟机等" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_sources_list_manager ;;
	1) TERMUX_REPO='game' ;;
	2) TERMUX_REPO='root' ;;
	3) TERMUX_REPO='science' ;;
	4) TERMUX_REPO='unstable' ;;
	5) TERMUX_REPO='x11' ;;
	esac
	##########
	enable_or_disable_termux_repo
	press_enter_to_return
	termux_repo_manager
}
########
tmoe_sources_list_manager() {
	#NEW_TERMUX_SOURCES_LIST='true'
	check_tmoe_sources_list_backup_file
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='tmoe_sources_list_manager'
	SOURCES_LIST=$(
		whiptail --title "software-sources tmoe-manager" --menu \
			"Do you want to switch the mirror source?" 0 50 0 \
			"1" "university:国内高校镜像站" \
			"2" "worldwide mirror sites:全球镜像站" \
			"3" "enable/disable repo(启用/禁用仓库)" \
			"4" "edit list manually(手动编辑)" \
			"5" "ping(镜像站延迟测试)" \
			"6" "speed(镜像站下载速度测试)" \
			"7" "delete invalid rows(去除无效行)" \
			"8" "restore to default(恢复默认源)" \
			"0" "🌚 Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_manager_main_menu ;;
	1) china_university_mirror_station ;;
	2) worldwide_mirror_station ;;
	3) termux_repo_manager ;;
	4) edit_sources_list_manually ;;
	5) ping_mirror_sources_list ;;
	6) mirror_sources_station_download_speed_test ;;
	7) delete_sources_list_invalid_rows ;;
	8) restore_default_sources_list ;;
	esac
	##########
	press_enter_to_return
	tmoe_sources_list_manager
}
######################
edit_sources_list_manually() {
	apt edit-sources || nano ${SOURCES_LIST_FILE}
	if [ ! -z "$(ls ${SOURCES_LIST_FILE}.d/)" ]; then
		nano ${SOURCES_LIST_FILE}.d/*.list
	fi
}
#########
tmoe_remove_xfce() {
	if [ "${LINUX_DISTRO}" != 'Android' ]; then
		aria2c --allow-overwrite=true -d /tmp -o '.tmoe-linux-tool.sh' 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		bash /tmp/.tmoe-linux-tool.sh --remove_gui
		exit 0
	fi
	remove_android_termux_xfce
}
##########I
check_android_version() {
	ANDROID_6_FILE="${CONFIG_FOLDER}/android6_termux"
	if [ "${LINUX_DISTRO}" = 'Android' ] && [ ! -e "${ANDROID_6_FILE}" ]; then
		if (("${ANDROID_VERSION}" < '7')); then
			echo "检测到您当前的安卓系统版本低于7,如需换源,则请选择USTC。" >${ANDROID_6_FILE}
			cat ${ANDROID_6_FILE}
			echo "Your current Android system version is lower than 7."
			press_enter_to_continue
		fi
	fi
}
###########
termux_original_system_gui() {
	RETURN_TO_WHERE='termux_original_system_gui'
	#\n这里是termux原系统的配置区域,不是GNU/Linux容器的哦！\nThe following options only apply to termux original system.
	OPTION=$(whiptail --title "Termux" --menu "Termux native GUI has fewer software packages.It is recommended that you install a container.Termux原系统GUI可玩性较低,建议您安装GNU/Linux(proot/chroot)容器" 0 50 0 \
		"1" "modify termux-vnc conf" \
		"2" "🐹 install termux-xfce4" \
		"3" "💔 remove xfce4" \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	#####################################
	case "${OPTION}" in
	0 | "") android_termux_tmoe_area ;;
	1) tmoe_modify_vnc_conf ;;
	2) tmoe_install_xfce ;;
	3) tmoe_remove_xfce ;;
	esac
	####################################
	press_enter_to_return
	termux_original_system_gui
}
###############
android_termux_tmoe_area() {
	check_android_version
	RETURN_TO_MENU='android_termux_tmoe_area'
	RETURN_TO_WHERE='android_termux_tmoe_area'
	#17 60 6
	OPTION=$(whiptail --title "Termux" --menu "您可以通过VNC客户端来连接GNU/Linux(proot/chroot)容器的桌面,\n并在此处修改termux音频服务端的配置\nYou can use vncviewer to connect container DE." 0 50 0 \
		"1" "🎶 configure Termux LAN audio局域网音频传输" \
		"2" "🎧 switch VNC audio音频传输方式" \
		"3" "🍅 query space occupation查询空间占用" \
		"4" "🍑 vnc/xsdl/xwayland.apk下载远程桌面客户端" \
		"5" "🤖 termux_fdroid.apk下载termux" \
		"6" "VSCode Server arm64" \
		"7" "Video tutorial(2020-02,旧版教程)" \
		"8" "📺 termux original GUI:原系统GUI" \
		"0" "🌚 Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	########################################
	case "${OPTION}" in
	0 | "") tmoe_manager_main_menu ;;
	1) termux_pulse_audio_lan ;;
	2) switch_vnc_pulse_audio_transport_method ;;
	3) space_occupation ;;
	4) download_vnc_apk ;;
	5) aria2_download_termux_apk ;;
	6) start_vscode ;;
	7) download_video_tutorial ;;
	8) termux_original_system_gui ;;
	esac
	####################################
	press_enter_to_return
	android_termux_tmoe_area
}
#####################################
switch_vnc_pulse_audio_transport_method() {
	cd ${DEBIAN_CHROOT}/root
	if grep -Eq '4712|4713' ./.vnc/xstartup; then
		PULSEtransportMethon='检测到您当前使用的可能是XSDL音频传输'
	else
		PULSEtransportMethon='检测到您当前使用的是termux音频传输'
	fi

	if (whiptail --title "您想用哪个软件来传输VNC音频？(｡･∀･)ﾉﾞ" --yes-button 'Termux(*￣▽￣*)o' --no-button 'XSDL(っ °Д °)' --yesno "${PULSEtransportMethon},请选择您需要切换的传输类型！注：您必须先安装XSDL app才能使用XSDL的音频服务，切换成XSDL后，启动VNC时将自动打开XSDL,此时不会转发X,您也无需执行任何操作。\nWhich software do you want to use to transmit VNC audio?" 13 50); then

		sed -i 's/^export.*PULSE.*/export PULSE_SERVER=127.0.0.1/' ${DEBIAN_CHROOT}/root/.vnc/xstartup || echo "没有找到vnc xstartup呢！请确保您已安装gui"
		sed -i '/x.org.server.MainActivity/d' $PREFIX/bin/startvnc
		sed -i '/sleep 5/d' $PREFIX/bin/startvnc
	else
		sed -i 's/^export.*PULSE.*/export PULSE_SERVER=127.0.0.1:4713/' ${DEBIAN_CHROOT}/root/.vnc/xstartup || echo "没有找到vnc xstartup呢！请确保您已安装gui"
		cd $PREFIX/bin/
		grep -q 'x.org.server' startvnc || sed -i '2 a\am start -n x.org.server/x.org.server.MainActivity \nsleep 5' startvnc
	fi
	echo "修改完成！(￣▽￣),您需要输startvnc来启动vnc"
	press_enter_to_return
	android_termux_tmoe_area
}
###############################
termux_pulse_audio_lan() {
	if [ "${LINUX_DISTRO}" = 'Android' ]; then
		cd $PREFIX/etc/pulse
	else
		cd /etc/pulse
	fi
	if grep -q '192.168.0.0/16' default.pa; then
		LANPULSE='检测到您已启用局域网音频传输,you have enabled LAN audio transmission'
	else
		LANPULSE='检测到您未启用局域网音频传输，默认仅允许本机传输,you have disabled LAN audio transmission'
	fi
	#10 50
	if (whiptail --title "请问您是需要启用还是禁用此功能呢？(｡･∀･)ﾉﾞ" --yes-button 'yes(*￣▽￣*)o' --no-button 'no(っ °Д °)' --yesno "${LANPULSE},请选择您需要执行的操作！\nDo you want to enable LAN audio transmission?" 11 50); then
		sed -i '/auth-ip-acl/d' default.pa
		sed -i '/module-native-protocol-tcp/d' default.pa
		sed -i '$ a\load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;192.168.0.0/16;172.16.0.0/12 auth-anonymous=1' default.pa
	else
		sed -i '/auth-ip-acl/d' default.pa
		sed -i '/module-native-protocol-tcp/d' default.pa
		sed -i '$ a\load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1' default.pa
	fi
	echo "修改完成！(￣▽￣)"
	echo "如需单独启动音频服务，请输pulseaudio --start"
	echo "若无声音，则您需要安装termux:api的apk,并升级termux至最新版本"
	press_enter_to_return
	android_termux_tmoe_area
}
#############################
aria2_download_termux_apk() {
	cd /sdcard/Download
	if [ -f "com.termux_Fdroid.apk" ]; then

		if (whiptail --title "检测到文件已下载,请选择您需要执行的操作！" --yes-button 'install(*￣▽￣*)o' --no-button 'Download again(っ °Д °)' --yesno "Detected that the file has been downloaded, do you want to install it, or download it again?" 7 60); then
			install_termux_apk
		else
			download_termux_apk_again
		fi
	else
		download_termux_apk_again

	fi
	press_enter_to_return
	tmoe_manager_main_menu
}
#######################################
download_termux_apk_again() {
	echo 'Press enter to start the download, and press Ctrl + C to cancel.'
	echo "${YELLOW}按回车键开始下载，按Ctrl+C取消。${RESET}"
	read
	echo 'Downloading termux apk...'
	echo '正在为您下载至/sdcard/Download目录...'
	echo '下载完成后，需要您手动安装。'
	aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "com.termux_Fdroid.apk" 'https://apk.tmoe.me/termux' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "com.termux_Fdroid.apk" 'https://mirrors.tuna.tsinghua.edu.cn/fdroid/repo/com.termux_94.apk'
	install_termux_apk
}
install_termux_apk() {
	echo "${YELLOW}下载完成，请进入下载目录手动安装。${RESET}"
	am start -n com.android.documentsui/com.android.documentsui.ViewDownloadsActivity
	cd ${cur}
}

##################################
install_web_novnc() {
	if [ "${LINUX_DISTRO}" = 'Android' ]; then
		if [ ! -e "${PREFIX}/bin/python" ]; then
			apt update
			apt install -y python
		fi
	elif [ "${LINUX_DISTRO}" = 'debian' ]; then
		if [ ! -e "/usr/bin/python3" ]; then
			sudo apt install -y python3 || su -c 'apt install -y python3'
			sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1 || su -c "update-alternatives --install /usr/bin/python python /usr/bin/python3 1"
		fi

		if [ ! -e "/usr/bin/python" ]; then
			sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1 || su -c "update-alternatives --install /usr/bin/python python /usr/bin/python3 1"
		fi
	fi

	if [ ! -e "${HOME}/.vnc/utils/launch.sh" ]; then
		mkdir -p ${HOME}/.vnc
		cd ${HOME}/.vnc
		aria2c -x 3 -k 1M --split=5 --allow-overwrite=true -o 'novnc.deb' 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/n/novnc/novnc_1.0.0-3_all.deb' || sudo aria2c -x 3 -k 1M --split=5 --allow-overwrite=true -o 'novnc.deb' 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/n/novnc/novnc_1.0.0-3_all.deb'
		dpkg-deb -X novnc.deb ./ || sudo dpkg-deb -X novnc.deb ./
		cp -prf ./usr/share/novnc/* ./ || sudo cp -prf ./usr/share/novnc/* ./
		cp -rf ./usr/share/doc ./ || sudo cp -rf ./usr/share/doc ./
		rm -rf ./usr || sudo rm -rf ./usr
	fi
	start_web_novnc
}
#######################
start_web_novnc() {
	#pulseaudio --kill 2>/dev/null
	cd ${HOME}/.vnc/utils/
	if [ ! -d "websockify" ]; then
		git clone git://github.com/novnc/websockify.git --depth=1 ./websockify || sudo git clone git://github.com/novnc/websockify.git --depth=1 ./websockify
		#echo "克隆失败，请在退出脚本后，输sudo debian-i以root身份重新运行本脚本"
	fi
	echo 'Before starting novnc, you must know the following: 1. NOVNC can connect without installing a client. 2. You can use the Bluetooth mouse to operate on the local browser, or you can use the browser of other devices to open the local novnc address.'
	echo "在启动novnc之前，您必须知悉novnc无需安装客户端，您可以使用蓝牙鼠标在本机浏览器上进行操作，亦可使用其它设备的浏览器打开本机的novnc地址。"
	echo "如需启动vnc app，而非web端，那么您下次可以输startvnc"
	echo "若无声音，则请输stopvnc并重启终端。"
	echo '正在为您启动novnc'
	echo 'Starting novnc service,please be patient.'
	bash launch.sh --vnc localhost:5901 --listen 6080 &
	if [ "${LINUX_DISTRO}" = 'Android' ]; then
		am start -a android.intent.action.VIEW -d "http://localhost:6080/vnc.html"
	elif [ "${WINDOWSDISTRO}" = "WSL" ]; then
		/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe "start http://localhost:6080/vnc.html"
	else
		xdg-open 'http://localhost:6080/vnc.html' 2>/dev/null
	fi
	echo "本机默认novnc地址${YELLOW}http://localhost:6080/vnc.html${RESET}"
	echo The LAN VNC address 局域网地址$(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):6080/vnc.html
	echo "注意：novnc地址和vnc地址是${YELLOW}不同${RESET}的，请在${YELLOW}浏览器${RESET}中输入novnc地址。"
	echo 'Other devices in the LAN need to enter the novnc address of the LAN. Do not forget /vnc.html after the port number'
	echo "非本机（如局域网内的pc）需要输局域网novnc地址，不要忘记端口号后的/vnc.html"
	if [ -d "${DEBIAN_CHROOT}" ]; then
		touch ~/${DEBIAN_FOLDER}/root/.vnc/startvnc
		${PREFIX}/bin/debian
	else
		if [ "${LINUX_DISTRO}" = 'Android' ]; then
			${PREFIX}/bin/startvnc
		else
			bash -c "$(sed 's:^export HOME=.*:export HOME=/root:' $(command -v startvnc))"
		fi
	fi
	#注：必须要先启动novnc后，才能接着启动VNC。
	#否则将导致安卓proot容器提前启动。
}

#################
modify_android_termux_vnc_config() {
	if [ ! -e ${PREFIX}/bin/startvnc ]; then
		echo "${PREFIX}/bin/startvnc is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startvnc,您可能尚未安装图形桌面，是否继续编辑?'
		echo "Press Enter to confirm."
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		read
	fi
	CURRENTTERMUXVNCRES=$(sed -n 7p "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
	if (whiptail --title "modify vnc configuration" --yes-button '分辨率resolution' --no-button '其它other' --yesno "您想要修改哪项配置信息？Which configuration do you want to modify?" 9 50); then
		if grep -q 'debian_' "$(command -v startvnc)"; then
			echo "您当前使用的startvnc配置为Linux容器系统专用版，请输debian进入容器后再输debian-i修改"
			echo "本选项仅适用于termux原系统。"
			press_enter_to_return
			tmoe_manager_main_menu
		fi
		TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,1440x720,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为720x1440,当前为${CURRENTTERMUXVNCRES}。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
		#此处termux的whiptail跟debian不同，必须截取Error前的字符。
		#TRUETARGET="$(echo ${TARGET} | cut -d 'E' -f 1)"
		TRUETARGET="$(echo ${TARGET} | head -n 1 | cut -d ' ' -f 1)"
		#下面那条变量TRUETARGETTARGET前加空格
		#sed -i "s#${CURRENTTERMUXVNCRES}# ${TRUETARGETTARGET}#" "$(command -v startvnc)"
		sed -i "7 c Xvnc -geometry ${TRUETARGET} -depth 24 --SecurityTypes=None \$DISPLAY \&" "$(command -v startvnc)"
		echo 'Your current resolution has been modified.'
		echo '您当前的分辨率已经修改为'
		echo $(sed -n 7p "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
	else
		echo '您可以手动修改vnc的配置信息'
		echo 'If you want to modify the resolution, please change the 720x1440 (default resolution , vertical screen) to another resolution, such as 1920x1080 (landscape).'
		echo '若您想要修改分辨率，请将默认的720x1440（竖屏）改为其它您想要的分辨率，例如1920x1080（横屏）。'
		echo "您当前分辨率为${CURRENTTERMUXVNCRES}"
		echo '改完后按Ctrl+S保存，Ctrl+X退出。'
		echo "Press Enter to confirm."
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		read
		nano ${PREFIX}/bin/startvnc || nano $(command -v startvnc)
		echo "您当前分辨率为$(sed -n 7p "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"
	fi
	press_enter_to_return
	tmoe_manager_main_menu
}
###############
remove_android_termux_xfce() {
	#echo "${YELLOW}按回车键确认卸载,按Ctrl+C取消${RESET} "
	#echo 'Press enter to confirm ,press Ctrl + C to cancel'
	#read
	do_you_want_to_continue
	apt purge -y ^xfce tigervnc aterm
	apt purge -y x11-repo
	apt autoremove
	press_enter_to_return
	tmoe_manager_main_menu
}
#################
annotate_the_old_list() {
	if [ -e "${SOURCES_LIST_FILE_NAME}" ]; then
		sed -i 's@^@#&@g' ${SOURCES_LIST_FILE_NAME}
		sed -i 's@##@#@g' ${SOURCES_LIST_FILE_NAME}
		cat >>${SOURCES_LIST_FILE_NAME} <<-EndOfSourcesList
			deb ${TERMUX_SOUCRE_URL}
		EndOfSourcesList
	fi
}
############
modify_android_termux_old_mirror_sources_list() {
	cd ${PREFIX}/etc/apt
	SOURCES_LIST_FILE_NAME="sources.list"
	#deb https://mirrors.ustc.edu.cn/termux stable main
	TERMUX_SOUCRE_URL="https://${SOURCE_MIRROR_STATION}/termux stable main"
	annotate_the_old_list
	apt_dist_upgrade
}
#############
modify_android_termux_mirror_sources_list() {
	cd ${PREFIX}/etc/apt
	SOURCES_LIST_FILE_NAME="sources.list"
	TERMUX_SOUCRE_URL="${TERMUX_MAIN_SOURCE}"
	annotate_the_old_list
	#####
	cd sources.list.d
	SOURCES_LIST_FILE_NAME="root.list"
	TERMUX_SOUCRE_URL="${TERMUX_ROOT_SOURCE}"
	annotate_the_old_list
	#######
	SOURCES_LIST_FILE_NAME="game.list"
	TERMUX_SOUCRE_URL="${TERMUX_GAME_SOURCE}"
	annotate_the_old_list
	######
	SOURCES_LIST_FILE_NAME="science.list"
	TERMUX_SOUCRE_URL="${TERMUX_SCIENCE_SOURCE}"
	annotate_the_old_list
	######
	SOURCES_LIST_FILE_NAME="unstable.list"
	TERMUX_SOUCRE_URL="${TERMUX_UNSTABLE_SOURCE}"
	annotate_the_old_list
	########
	SOURCES_LIST_FILE_NAME="x11.list"
	TERMUX_SOUCRE_URL="${TERMUX_X11_SOURCE}"
	annotate_the_old_list
	######
	apt_dist_upgrade
}
#############
apt_dist_upgrade() {
	apt update
	apt dist-upgrade -y
	echo '修改完成，您当前的软件源列表如下所示。'
	cat /data/data/com.termux/files/usr/etc/apt/sources.list
	cat /data/data/com.termux/files/usr/etc/apt/sources.list.d/*
	echo "您可以输${YELLOW}apt edit-sources${RESET}来手动编辑main源"
	echo "您也可以输${YELLOW}cd ${PREFIX}/etc/apt/sources.list.d ; nano ./* ${RESET}来手动编辑其它源"
}
#########
termux_tuna_sources_list() {
	#if ! grep -q '^deb.*edu.cn.*termux-packages-24'
	if ! grep -q '^deb.*bfsu.*termux-packages-24' '/data/data/com.termux/files/usr/etc/apt/sources.list'; then
		sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.bfsu.edu.cn/termux/termux-packages-24 stable main@' /data/data/com.termux/files/usr/etc/apt/sources.list
		if ! grep -q '^deb' '/data/data/com.termux/files/usr/etc/apt/sources.list'; then
			echo -e '\ndeb https://mirrors.bfsu.edu.cn/termux/termux-packages-24 stable main' >>/data/data/com.termux/files/usr/etc/apt/sources.list
		fi
	fi

	if [ -e "/data/data/com.termux/files/usr/etc/apt/sources.list.d/game.list" ]; then
		if ! grep -q '^deb.*bfsu' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/game.list'; then
			sed -i 's@^\(deb.*games stable\)$@#\1\ndeb https://mirrors.bfsu.edu.cn/termux/game-packages-24 games stable@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/game.list
		fi
	fi

	if [ -e "/data/data/com.termux/files/usr/etc/apt/sources.list.d/science.list" ]; then
		if ! grep -q '^deb.*bfsu' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/science.list'; then
			sed -i 's@^\(deb.*science stable\)$@#\1\ndeb https://mirrors.bfsu.edu.cn/termux/science-packages-24 science stable@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/science.list
		fi
	fi
	if [ -e "/data/data/com.termux/files/usr/etc/apt/sources.list.d/x11.list" ]; then
		if ! grep -q '^deb.*bfsu' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/x11.list'; then
			sed -i 's@^\(deb.*x11 main\)$@#\1\ndeb https://mirrors.bfsu.edu.cn/termux/x11-packages x11 main@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/x11.list
		fi
	fi

	if [ -e "/data/data/com.termux/files/usr/etc/apt/sources.list.d/unstable.list" ]; then
		if ! grep -q '^deb.*bfsu' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/unstable.list'; then
			sed -i 's@^\(deb.*unstable main\)$@#\1\ndeb https://mirrors.bfsu.edu.cn/termux/unstable-packages unstable main@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/unstable.list
		fi
	fi

	if [ -e "/data/data/com.termux/files/usr/etc/apt/sources.list.d/root.list" ]; then
		if ! grep -q '^deb.*bfsu' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/root.list'; then
			sed -i 's@^\(deb.*root stable\)$@#\1\ndeb https://mirrors.bfsu.edu.cn/termux/termux-root-packages-24 root stable@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/root.list
		fi
	fi
	apt_dist_upgrade
	press_enter_to_return
	android_termux
	#此处要返回依赖检测处！
}
##################
choose_which_gnu_linux_distro() {
	RETURN_TO_WHERE='choose_which_gnu_linux_distro'
	TMOE_LINUX_CONTAINER_DISTRO=''
	SELECTED_GNU_LINUX=$(whiptail --title "GNU/Linux distros" --menu "Which distribution do you want to install? \n您想要安装哪个GNU/Linux发行版?" 0 50 0 \
		"1" "🍥 Debian:最早的发行版之一" \
		"2" "🍛 Ubuntu:我的存在是因為大家的存在" \
		"3" "🐉 Kali Rolling:设计用于数字取证和渗透测试" \
		"4" "🍱 beta公测版:manjaro,centos,alpine" \
		"5" "🌉 arch:系统设计以KISS为总体指导原则" \
		"6" "👒 fedora:红帽社区版,新技术试验场" \
		"7" "🦎 chroot专属:opensuse,gentoo" \
		"8" "experimental(体验版,不再维护):raspbian" \
		"0" "🌚 Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${SELECTED_GNU_LINUX}" in
	0 | "") tmoe_manager_main_menu ;;
	1)
		install_debian_gnu_linux_distro
		;;
	2)
		install_ubuntu_gnu_linux_distro
		;;
	3)
		TMOE_LINUX_CONTAINER_DISTRO='kali-rolling'
		creat_container_edition_txt
		install_kali_rolling_gnu_linux_distro
		;;
	4) install_beta_containers ;;
	5)
		TMOE_LINUX_CONTAINER_DISTRO='arch'
		creat_container_edition_txt
		install_arch_linux_distro
		;;
	6)
		TMOE_LINUX_CONTAINER_DISTRO='fedora'
		creat_container_edition_txt
		install_fedora_gnu_linux_distro
		;;
	7) install_chroot_exclusive_containers ;;
	8) install_alpha_containers ;;
	esac
	####################
	exit 0
	#press_enter_to_return
	#tmoe_manager_main_menu
}
##############################
install_chroot_exclusive_containers() {
	RETURN_TO_WHERE='install_chroot_exclusive_containers'
	#\nThe developer only maintains the chroot container in the following list.
	ALPHA_SYSTEM=$(
		whiptail --title "chroot exclusive containers" --menu "虽然您仍可以使用proot运行以下容器,但开发者仅维护了chroot容器。" 0 55 0 \
			"1" "opensuse tumbleweed(小蜥蜴风滚草)" \
			"2" "gentoo(追求极限配置和极高自由,armhf,x86,x64)" \
			"3" "Funtoo:专注于改进Gentoo(armhf,x86,x64)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${ALPHA_SYSTEM}" in
	0 | "") choose_which_gnu_linux_distro ;;
	1)
		TMOE_LINUX_CONTAINER_DISTRO='opensuse'
		creat_container_edition_txt
		install_opensuse_linux_distro
		;;
	2)
		TMOE_LINUX_CONTAINER_DISTRO='gentoo'
		creat_container_edition_txt
		install_gentoo_linux_distro
		;;
	3)
		TMOE_LINUX_CONTAINER_DISTRO='funtoo'
		creat_container_edition_txt
		install_funtoo_linux_distro
		;;
	esac
	###########################
	exit 0
	#press_enter_to_return
	#tmoe_manager_main_menu
	####################
}
###############
install_alpha_containers() {
	RETURN_TO_WHERE='install_alpha_containers'
	ALPHA_SYSTEM=$(
		whiptail --title "Maintenance has ceased" --menu "虽然您仍可以安装基础容器,但Tmoe-linux开发者已不再对以下容器进行维护" 0 55 0 \
			"1" "armbian bullseye(arm64,armhf)" \
			"2" "raspbian樹莓派 buster(armhf)" \
			"3" "devuan (不使用systemd,基于debian)" \
			"4" "slackware(armhf,x64)" \
			"5" "openwrt(常见于路由器,arm64,x64)" \
			"6" "apertis" \
			"7" "alt" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${ALPHA_SYSTEM}" in
	0 | "") choose_which_gnu_linux_distro ;;
	1)
		TMOE_LINUX_CONTAINER_DISTRO='armbian'
		creat_container_edition_txt
		install_armbian_linux_distro
		;;
	2)
		TMOE_LINUX_CONTAINER_DISTRO='raspbian'
		creat_container_edition_txt
		install_raspbian_linux_distro
		;;
	3)
		TMOE_LINUX_CONTAINER_DISTRO='devuan'
		creat_container_edition_txt
		install_devuan_linux_distro
		;;
	4)
		TMOE_LINUX_CONTAINER_DISTRO='slackware'
		creat_container_edition_txt
		install_slackware_linux_distro
		;;
	5)
		TMOE_LINUX_CONTAINER_DISTRO='openwrt'
		creat_container_edition_txt
		install_openwrt_linux_distro
		;;
	6)
		TMOE_LINUX_CONTAINER_DISTRO='apertis'
		creat_container_edition_txt
		install_apertis_linux_distro
		;;
	7)
		TMOE_LINUX_CONTAINER_DISTRO='alt'
		creat_container_edition_txt
		install_alt_linux_distro
		;;
	esac
	###########################
	exit 0
	#press_enter_to_return
	#tmoe_manager_main_menu
	####################
}
#########################
install_beta_containers() {
	BETA_SYSTEM=$(
		whiptail --title "Beta features" --menu "公测版容器将带给您别样的惊喜\nBeta container, endless fun." 0 55 0 \
			"1" "manjaro(让arch更方便用户使用,arm64)" \
			"2" "centos (基于红帽的社区企业操作系统)" \
			"3" "Void:基于xbps包管理器的独立发行版" \
			"4" "🏔️ alpine(非glibc的精简系统)" \
			"5" "mint(简单易用的系统,x86,x64)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${BETA_SYSTEM}" in
	0 | "") choose_which_gnu_linux_distro ;;
	1)
		TMOE_LINUX_CONTAINER_DISTRO='manjaro'
		creat_container_edition_txt
		install_manjaro_linux_distro
		;;
	2)
		TMOE_LINUX_CONTAINER_DISTRO='centos'
		creat_container_edition_txt
		install_centos_linux_distro
		;;
	3)
		TMOE_LINUX_CONTAINER_DISTRO='void'
		creat_container_edition_txt
		install_void_linux_distro
		;;
	4)
		TMOE_LINUX_CONTAINER_DISTRO='alpine'
		creat_container_edition_txt
		install_alpine_linux_distro
		;;
	5)
		TMOE_LINUX_CONTAINER_DISTRO='mint'
		creat_container_edition_txt
		install_mint_linux_distro
		;;
	esac
	######################
	exit 0
	#press_enter_to_return
	#tmoe_manager_main_menu
	####################
}
#####################
install_ubuntu_gnu_linux_distro() {
	DISTRO_NAME='ubuntu'
	BETA_SYSTEM=$(
		whiptail --title "Which version do you want to install?" --menu "您想要安装哪个版本?2020至2025年的LTS长期支持版为focal 20.04(2020年4月正式发布),上一个LTS为18.04(2018年4月),下一个LTS可能为22.04\n设当前年份为x,若x>=2022,则请手动输入版本代号。" 0 50 0 \
			"1" "🦍 20.10 Groovy Gorilla 時髦大猩猩" \
			"2" "🐱 20.04 Focal Fossa 焦點馬島長尾狸貓" \
			"3" "Custom code手动输入版本代号" \
			"4" "18.04 Bionic Beaver 仿生海狸" \
			"5" "🐿️ 16.04 Xenial Xerus 好客的非洲地松鼠" \
			"6" "Latest(自动检测21.04，测试中)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#🦦
	##############################
	case "${BETA_SYSTEM}" in
	0 | "") choose_which_gnu_linux_distro ;;
	1) DISTRO_CODE='groovy' ;;
	2) DISTRO_CODE='focal' ;;
	3) custom_ubuntu_version ;;
	4) DISTRO_CODE='bionic' ;;
	5) DISTRO_CODE='xenial' ;;
	6) check_the_latest_ubuntu_version ;;
	esac
	######################
	case ${DISTRO_CODE} in
	bionic | xenial | eoan) ;;
	*)
		if [ "${ARCH_TYPE}" = 'i386' ]; then
			echo "已不再提供${DISTRO_CODE}的i386镜像,将为您降级到18.04-bionic"
			DISTRO_CODE='bionic'
		fi
		;;
	esac
	TMOE_LINUX_CONTAINER_DISTRO="${DISTRO_NAME}-${DISTRO_CODE}"
	creat_container_edition_txt
	echo "即将为您安装Ubuntu ${DISTRO_CODE} GNU/Linux container"
	do_you_want_to_continue
	install_different_ubuntu_gnu_linux_distros
	####################
	exit 0
	#press_enter_to_return
	#tmoe_manager_main_menu
}
#########################
custom_ubuntu_version() {
	TARGET=$(whiptail --inputbox "请输入ubuntu版本代号，例如focal(英文小写)\nPlease enter the ubuntu version code." 12 50 --title "UBUNTU CODE" 3>&1 1>&2 2>&3)
	DISTRO_CODE="$(echo ${TARGET} | head -n 1 | cut -d ' ' -f 1)"
	if [ -z "${DISTRO_CODE}" ]; then
		echo "检测到您取消了操作"
		echo "已自动切换为ubuntu20.04(代号focal)"
		DISTRO_CODE='focal'
	fi
}
#################
ubuntu_distro_x64_model() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed "s/focal/${DISTRO_CODE}/g" |
		sed "s/debian system/${DISTRO_NAME} system/g" |
		sed "s:debian-sid:${DISTRO_NAME}-${DISTRO_CODE}:g" |
		sed "s:debian/sid:${DISTRO_NAME}/${DISTRO_CODE}:g" |
		sed "s:/${DISTRO_NAME}-ports:/${DISTRO_NAME}:g" |
		sed "s:Debian GNU/Linux:${DISTRO_NAME} GNU/Linux:g")"
}
############
ubuntu_distro_arm_model() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed "s/focal/${DISTRO_CODE}/g" |
		sed "s/debian system/${DISTRO_NAME} system/g" |
		sed "s:debian-sid:${DISTRO_NAME}-${DISTRO_CODE}:g" |
		sed "s:debian/sid:${DISTRO_NAME}/${DISTRO_CODE}:g" |
		sed "s:Debian GNU/Linux:${DISTRO_NAME} GNU/Linux:g")"
}
########
linux_distro_common_model_01() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed "s/debian system/${DISTRO_NAME} system/g" |
		sed "s:debian-sid:${DISTRO_NAME}-${DISTRO_CODE}:g" |
		sed "s:debian/sid:${DISTRO_NAME}/${DISTRO_CODE}:g" |
		sed "s:Debian GNU/Linux:${DISTRO_NAME} GNU/Linux:g")"
}
####################
linux_distro_common_model_02() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed "s/debian system/${DISTRO_NAME} system/g" |
		sed "s:debian-sid:${DISTRO_NAME}-${DISTRO_CODE}:g" |
		sed "s:debian/sid:${DISTRO_NAME}/${DISTRO_CODE_02}:g" |
		sed "s:Debian GNU/Linux:${DISTRO_NAME} GNU/Linux:g")"
}
#########################
install_different_ubuntu_gnu_linux_distros() {
	case "${ARCH_TYPE}" in
	amd64 | i386) ubuntu_distro_x64_model ;;
	*) ubuntu_distro_arm_model ;;
	esac
	#UBUNTU ppc64el/s390x/arm架构需使用ports源
}
############
check_the_latest_ubuntu_version() {
	LXC_IMAGES_REPO="https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/${DISTRO_NAME}/"
	DISTRO_CODE=$(curl -L ${LXC_IMAGES_REPO} | grep date | cut -d '=' -f 4 | cut -d '"' -f 2 | grep -Ev 'size|bionic|cosmic|disco|eoan|focal|trusty|xenial|groovy' | tail -n 1)
	if [ -z ${DISTRO_CODE} ]; then
		echo "未检测到最新版本，将自动获取ubuntu 20.10 groovy"
		DISTRO_CODE='groovy'
	fi
}
##########
install_kali_rolling_gnu_linux_distro() {
	DISTRO_NAME='kali'
	DISTRO_CODE='rolling'
	DISTRO_CODE_02='current'
	linux_distro_common_model_02
}
#####################
install_arch_linux_distro() {
	if [ "${ARCH_TYPE}" = 'armhf' ] || [ "${ARCH_TYPE}" = 'i386' ]; then
		echo "检测到Arch Linux不支持您当前的架构"
	else
		DISTRO_NAME='archlinux'
		DISTRO_CODE='latest'
		DISTRO_CODE_02='current'
		linux_distro_common_model_03
	fi
}
############
check_the_latest_distro_version() {
	LXC_IMAGES_REPO="https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/${DISTRO_NAME}/"
	DISTRO_CODE=$(curl -sL ${LXC_IMAGES_REPO} | grep date | tail -n 1 | cut -d '=' -f 4 | cut -d '"' -f 2)
	which_version_do_you_want_to_install
}
#################
which_version_do_you_want_to_install() {

	if (whiptail --title "${DISTRO_NAME} VERSION" --yes-button "${DISTRO_CODE}" --no-button "${OLD_STABLE_VERSION}" --yesno "您想要安装哪个版本？Which version do you want to install?检测到当前的最新版本(latest version)为${DISTRO_CODE}" 9 50); then
		linux_distro_common_model_01
	else
		DISTRO_CODE="${OLD_STABLE_VERSION}"
		linux_distro_common_model_01
	fi
}
######################
install_fedora_gnu_linux_distro() {
	touch ~/.REDHATDetectionFILE
	DISTRO_NAME='fedora'
	case "${ARCH_TYPE}" in
	armhf | armel | i386)
		#echo "检测到您使用的是armhf架构，将为您降级至Fedora 29"
		#DISTRO_CODE='29'
		#linux_distro_common_model_01
		distro_does_not_support
		;;
	*)
		#OLD_STABLE_VERSION='31'
		OLD_STABLE_VERSION=$(curl -L https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/fedora/ | grep date | tail -n 2 | head -n 1 | cut -d '=' -f 4 | cut -d '"' -f 2)
		check_the_latest_distro_version
		;;
	esac
}
################
install_funtoo_linux_distro() {
	DISTRO_NAME='funtoo'
	OLD_STABLE_VERSION='1.3'
	if [ "${ARCH_TYPE}" = 'arm64' ]; then
		echo "检测到您当前使用的是arm64架构，将为您下载armhf版容器"
		NEW_TMOE_ARCH='armhf'
		TMOE_QEMU_ARCH=""
		creat_tmoe_arch_file
	fi
	check_the_latest_distro_version
}
#######################
####################
linux_distro_common_model_03() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed "s/debian system/${DISTRO_NAME} system/g" |
		sed "s:debian-sid:${DISTRO_NAME}-${DISTRO_CODE}:g" |
		sed "s:debian/sid:${DISTRO_NAME}/${DISTRO_CODE_02}:g" |
		sed "s:Debian GNU/Linux:${DISTRO_NAME}:g")"
}
#################
install_void_linux_distro() {
	DISTRO_NAME='voidlinux'
	DISTRO_CODE='default'
	DISTRO_CODE_02='current'
	linux_distro_common_model_03
}
##########################
install_centos_linux_distro() {
	touch ~/.REDHATDetectionFILE
	DISTRO_NAME='centos'
	if [ "${ARCH_TYPE}" = 'armhf' ] || [ "${ARCH_TYPE}" = 'i386' ]; then
		echo "检测到CentOS 8不支持您当前的架构，将为您降级至CentOS 7"
		DISTRO_CODE='7'
		linux_distro_common_model_01
	else
		OLD_STABLE_VERSION='8'
		check_the_latest_distro_version
		#DISTRO_CODE='8'
		#linux_distro_common_model_01
	fi
}
######################
install_gentoo_linux_distro() {
	DISTRO_NAME='gentoo'
	if [ "${ARCH_TYPE}" = 'arm64' ]; then
		echo "检测到您当前使用的是arm64架构，将为您下载armhf版容器"
		NEW_TMOE_ARCH='armhf'
		TMOE_QEMU_ARCH=""
		creat_tmoe_arch_file
		#sed '45 a\ARCH_TYPE="armhf"' |
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
			sed 's/debian system/gentoo system/g' |
			sed 's:debian-sid:gentoo-current:g' |
			sed 's:debian/sid:gentoo/current:g' |
			sed 's:Debian GNU/Linux:Gentoo GNU/Linux:g')"
	else
		DISTRO_CODE='current'
		linux_distro_common_model_01
	fi
}
###########################
install_alpine_linux_distro() {
	touch ~/.ALPINELINUXDetectionFILE
	DISTRO_NAME='alpine'
	#DISTRO_CODE='3.11'
	DISTRO_CODE=$(curl -L https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/alpine/ | grep -Ev 'edge|3.7|3.8|3.9' | grep date | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | sed 's@/@@')
	OLD_STABLE_VERSION='edge'
	which_version_do_you_want_to_install
}
#####################
opensuse_warning() {
	case "${LINUX_DISTRO}" in
	Android)
		case ${TMOE_CHROOT} in
		true) ;;
		*)
			cat <<-EOF
				${RED}WARNING！${RESET}检测到您使用的是Android系统。
				本镜像支持GNU/Linux的proot/chroot容器,但不支持termux-proot。
				经测试在termux的proot环境下存在无法检索到软件包的情况，但GNU/Linux的proot却不存在此问题。
				若您执意要安装OpenSUSE tumbleweed,则请按回车键。
			EOF
			do_you_want_to_continue
			;;
		esac
		;;
	esac
}
########
install_opensuse_linux_distro() {
	opensuse_warning
	DISTRO_NAME='opensuse'
	DISTRO_CODE='tumbleweed'
	linux_distro_common_model_01
}
########################
install_raspbian_linux_distro() {
	case "${ARCH_TYPE}" in
	arm64 | armhf) ;;
	*) distro_does_not_support ;;
	esac
	NEW_TMOE_ARCH='armhf'
	TMOE_QEMU_ARCH=""
	creat_tmoe_arch_file
	touch ~/.RASPBIANARMHFDetectionFILE
	if (whiptail --title "RASPBIAN" --yes-button "直接" --no-button "间接" --yesno "您想要如何安装raspbian呢？How do you want to install raspbian?" 9 50); then
		install_raspbian_linux_distro_type01
	else
		install_raspbian_linux_distro_type02
	fi
}
############################
install_raspbian_linux_distro_type01() {
	#https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${ARCH_TYPE}/default/${ttime}rootfs.tar.xz
	#https://mirrors.tuna.tsinghua.edu.cn/raspbian-images/raspbian_full/root.tar.xz
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed 's@lxc-images.*rootfs.tar.xz@raspbian-images/raspbian_lite/root.tar.xz@g' |
		sed 's:/sid:/buster:g' |
		sed 's@#deb http@deb http@g' |
		sed 's/.*sid main/#&/' |
		sed 's/debian system/raspbian system/g' |
		sed 's:debian-sid:raspbian-buster:g' |
		sed 's:debian/sid:debian/buster:g' |
		sed 's:Debian GNU/Linux:Raspbian GNU/Linux:g')"
}
##################
install_raspbian_linux_distro_type02() {
	#sed '72 a\ARCH_TYPE="armhf"'
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed 's:/sid:/buster:g' |
		sed 's:extract z:extract:' |
		sed 's@#deb http@deb http@g' |
		sed 's/.*sid main/#&/' |
		sed 's/debian system/raspbian system/g' |
		sed 's:debian-sid:raspbian-buster:g' |
		sed 's:debian/sid:debian/buster:g' |
		sed 's:Debian GNU/Linux:Raspbian GNU/Linux:g')"
}
#############
install_manjaro_linux_distro() {
	case ${ARCH_TYPE} in
	arm64) ;;
	*)
		echo "非常抱歉，Tmoe-linux的开发者未对您的架构进行适配"
		press_enter_to_return
		tmoe_manager_main_menu
		;;
	esac

	#aria2c -x 5 -k 1M --split 5 -o manjaro-latest-rootfs.tar.gz "https://mirrors.tuna.tsinghua.edu.cn/osdn/storage/g/m/ma/manjaro-arm/.rootfs/Manjaro-ARM-aarch64-latest.tar.gz"
	#https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${ARCH_TYPE}/default/${ttime}rootfs.tar.xz
	touch ~/.MANJARO_ARM_DETECTION_FILE
	#echo "检测到您选择的是manajro,即将从第三方网盘下载容器镜像。"
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed 's@mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid.*xz@mirrors.tuna.tsinghua.edu.cn/osdn/storage/g/m/ma/manjaro-arm/.rootfs/Manjaro-ARM-aarch64-latest.tar.gz@g' |
		sed 's/debian system/manjaro system/g' |
		sed 's:debian-sid:manjaro-stable:g' |
		sed 's:debian/sid:manjaro/stable:g' |
		sed 's:rootfs.tar.xz:rootfs.tar.gz:g' |
		sed 's@tar -pJx@tar -pzx@g' |
		sed 's:Debian GNU/Linux:Manjaro GNU/Linux:g')"
}
#		sed 's@tar -pJxvf@tar -pzxvf@g'
############################
install_openwrt_linux_distro() {
	#if [ ! -e "openwrt-snapshot-rootfs.tar.xz" ]; then
	#	cd ${HOME}
	#aria2c -x 16 -s 16 -k 1M -o "openwrt-snapshot-rootfs.tar.xz" "https://cdn.tmoe.me/Tmoe-Debian-Tool/chroot/archive/openwrt_arm64.tar.xz" || aria2c -x 16 -s 16 -k 1M -o "openwrt-snapshot-rootfs.tar.xz" "https://m.tmoe.me/down/share/Tmoe-linux/chroot/openwrt_arm64.tar.xz"
	#fi
	touch ~/.ALPINELINUXDetectionFILE
	CONTAINER_REPO='https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/'
	THE_LATEST_VERSION=$(curl -L ${CONTAINER_REPO} | grep -Ev 'faillog|packages' | grep 'href' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '/' -f 1)
	THE_LATEST_ROOTFS_REPO="${CONTAINER_REPO}${THE_LATEST_VERSION}/targets/"

	if [ "${ARCH_TYPE}" = 'amd64' ]; then
		#https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/19.07.3/targets/x86/64/openwrt-19.07.3-x86-64-generic-rootfs.tar.gz
		THE_LATEST_ISO_LINK="${THE_LATEST_ROOTFS_REPO}x86/64/openwrt-${THE_LATEST_VERSION}-x86-64-generic-rootfs.tar.gz"
	elif [ "${ARCH_TYPE}" = 'i386' ]; then
		#https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/19.07.3/targets/x86/generic/openwrt-19.07.3-x86-generic-generic-rootfs.tar.gz
		THE_LATEST_ISO_LINK="${THE_LATEST_ROOTFS_REPO}x86/generic/openwrt-${THE_LATEST_VERSION}-x86-generic-generic-rootfs.tar.gz"
	elif [ "${ARCH_TYPE}" = 'arm64' ]; then
		#https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/19.07.3/targets/armvirt/64/openwrt-19.07.3-armvirt-64-default-rootfs.tar.gz
		THE_LATEST_ISO_LINK="${THE_LATEST_ROOTFS_REPO}armvirt/64/openwrt-${THE_LATEST_VERSION}-armvirt-64-default-rootfs.tar.gz"
	elif [ "${ARCH_TYPE}" = 'armhf' ]; then
		#https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/19.07.3/targets/armvirt/32/openwrt-19.07.3
		THE_LATEST_ISO_LINK="${THE_LATEST_ROOTFS_REPO}armvirt/32/openwrt-${THE_LATEST_VERSION}-armvirt-32-default-rootfs.tar.gz"
	fi

	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed "s@https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid.*xz@${THE_LATEST_ISO_LINK}@g" |
		sed 's/debian system/openwrt system/g' |
		sed 's:debian-sid:openwrt-latest:g' |
		sed 's:debian/sid:openwrt/snapshot:g' |
		sed 's:rootfs.tar.xz:rootfs.tar.gz:g' |
		sed 's@tar -pJx@tar -pzx@g' |
		sed 's:Debian GNU/Linux:OpenWRT Linux:g')"
}
######################
install_devuan_linux_distro() {
	DISTRO_NAME='devuan'
	#DISTRO_CODE='beowulf'
	DISTRO_CODE=$(curl -L https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/devuan/ | grep date | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | sed 's@/@@')
	linux_distro_common_model_01
}
######################
install_apertis_linux_distro() {
	if [ "${ARCH_TYPE}" = 'i386' ]; then
		echo "检测到apertis不支持您当前的架构"
	else
		touch ~/.ALPINELINUXDetectionFILE
		DISTRO_NAME='apertis'
		OLD_STABLE_VERSION='v2019.2'
		check_the_latest_distro_version
	fi
}
################################
install_alt_linux_distro() {
	if [ "${ARCH_TYPE}" = 'armhf' ]; then
		echo "检测到alt不支持您当前的架构"
	else
		DISTRO_NAME='alt'
		OLD_STABLE_VERSION='Sisyphus'
		check_the_latest_distro_version
	fi
}
##################
install_slackware_linux_distro() {
	cd ${HOME}
	#touch .SLACKDetectionFILE
	case "${ARCH_TYPE}" in
	amd64)
		if [ ! -e "slackware-current_amd64-rootfs.tar.xz" ]; then
			git clone -b x64 --depth=1 https://gitee.com/ak2/slackware_rootfs.git .SLACKWARE_AMD64_TEMP_FOLDER
			#aria2c -x 16 -s 16 -k 1M -o "slackware-current-rootfs.tar.xz" "https://cdn.tmoe.me/Tmoe-Debian-Tool/chroot/archive/slackware_amd64.tar.xz" || aria2c -x 16 -s 16 -k 1M -o "slackware-current-rootfs.tar.xz" "https://m.tmoe.me/down/share/Tmoe-linux/chroot/slackware_amd64.tar.xz"
			cd .SLACKWARE_AMD64_TEMP_FOLDER
			mv -f slackware_amd64.tar.xz ../slackware-current_amd64-rootfs.tar.xz
			cd ..
			rm -rf .SLACKWARE_AMD64_TEMP_FOLDER
		fi
		;;
	arm64 | armhf)
		NEW_TMOE_ARCH='armhf'
		TMOE_QEMU_ARCH=""
		creat_tmoe_arch_file
		if [ ! -e "slackware-current_armhf-rootfs.tar.xz" ]; then
			echo "检测到您当前使用的是${ARCH_TYPE}架构，将为您下载armhf版容器"
			LatestSlack="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/slackwarearm/slackwarearm-devtools/minirootfs/roots/ | grep 'tar.xz' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			aria2c -x 5 -s 5 -k 1M -o "slackware-current_armhf-rootfs.tar.xz" "https://mirrors.tuna.tsinghua.edu.cn/slackwarearm/slackwarearm-devtools/minirootfs/roots/${LatestSlack}"
		fi
		;;
	*) distro_does_not_support ;;
	esac
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed 's/debian system/slackware system/g' |
		sed 's:debian-sid:slackware-current:g' |
		sed 's:debian/sid:slackware/current:g' |
		sed 's:Debian GNU/Linux:Slackware GNU/Linux:g')"
}
#########################
distro_does_not_support() {
	echo "检测到您使用的是${ARCH_TYPE}架构，请换用其他发行版"
	press_enter_to_return
	choose_which_gnu_linux_distro
}
##############
install_armbian_linux_distro() {
	cd ${HOME}
	echo "armbian-bullseye-desktop已预装xfce4"

	case "${ARCH_TYPE}" in
	arm64 | armhf) ;;
	*) distro_does_not_support ;;
	esac

	ARMBIAN_ROOTFS="armbian-bullseye_${ARCH_TYPE}-rootfs.tar"
	DEBIAN_CHROOT="${HOME}/armbian_${ARCH_TYPE}"

	if [ ! -e "${ARMBIAN_ROOTFS}.lz4" ]; then
		LatestARMbian="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_rootfs/ | grep -E 'bullseye-desktop' | grep -v '.tar.lz4.asc' | grep ${ARCH_TYPE} | head -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		aria2c -x 5 -s 5 -k 1M -o "${ARMBIAN_ROOTFS}.lz4" "https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_rootfs/${LatestARMbian}"
	fi

	if [ ! $(command -v lz4) ]; then
		apt update 2>/dev/null
		apt install -y lz4 2>/dev/null || pacman -Syu --noconfirm lz4 2>/dev/null || zypper in -y lz4 2>/dev/null
	fi

	mkdir -p ${DEBIAN_CHROOT}
	rm -vf ~/${ARMBIAN_ROOTFS}
	lz4 -d ~/${ARMBIAN_ROOTFS}.lz4
	cd ${DEBIAN_CHROOT}
	if [ "${LINUX_DISTRO}" = "Android" ]; then
		pv ~/${ARMBIAN_ROOTFS} | proot --link2symlink tar -px
	else
		if [ $(command -v pv) ]; then
			pv ~/${ARMBIAN_ROOTFS} | tar -px
		else
			tar -pxvf ~/${ARMBIAN_ROOTFS}
		fi
	fi
	#相对路径，不是绝对路径
	sed -i 's/^deb/#&/g' ./etc/apt/sources.list.d/armbian.list
	sed -i '$ a\deb http://mirrors.tuna.tsinghua.edu.cn/armbian/ bullseye main bullseye-utils bullseye-desktop' ./etc/apt/sources.list.d/armbian.list
	rm -vf ~/${ARMBIAN_ROOTFS}

	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed 's/debian system/armbian system/g' |
		sed 's:debian-sid:armbian-bullseye:g' |
		sed 's:debian/sid:armbian/bullseye:g' |
		sed 's:rootfs.tar.xz:rootfs.tar.lz4:g' |
		sed 's@#deb http@deb http@g' |
		sed 's/.*sid main/#&/' |
		sed 's@debian/ stable@debian/ testing@g' |
		sed 's@buster-backports@bullseye-backports@g' |
		sed 's:Debian GNU/Linux:Armbian GNU/Linux:g')"
}
#######################
install_mint_linux_distro() {
	if [ "${ARCH_TYPE}" = 'amd64' ] || [ "${ARCH_TYPE}" = 'i386' ]; then
		DISTRO_NAME='mint'
		OLD_STABLE_VERSION='tina'
		LXC_IMAGES_REPO="https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/${DISTRO_NAME}/"
		DISTRO_CODE=$(curl -sL ${LXC_IMAGES_REPO} | grep date | cut -d '=' -f 4 | cut -d '"' -f 2 | grep -Ev 'size|sarah|serena|sonya|sylvia|tara|tessa|tina' | tail -n 1)
		which_linux_mint_distro
	else
		echo "${RED}WARNING！${RESET}检测到您使用的是${ARCH_TYPE}架构"
		echo "Linux Mint${RED}不支持${RESET}您的架构"
		echo "请换用${YELLOW}amd64${RESET}或${YELLOW}i386${RESET}设备后，再来尝试"
		press_enter_to_return
		install_beta_containers
	fi
}
################
which_linux_mint_distro() {
	RETURN_TO_WHERE='which_linux_mint_distro'
	DISTRO_NAME='mint'
	BETA_SYSTEM=$(
		whiptail --title "mint" --menu "您想要安装哪个Mint版本？\nWhich version do you want to install?" 0 0 0 \
			"1" "自动检测版本" \
			"2" "Custom code手动输入版本代号" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${BETA_SYSTEM}" in
	0 | "") choose_which_gnu_linux_distro ;;
	1) which_version_do_you_want_to_install ;;
	2) custom_mint_version ;;
	esac
	######################
	press_enter_to_return
	tmoe_manager_main_menu
}
#########################
custom_mint_version() {
	TARGET=$(whiptail --inputbox "请输入mint版本代号，例如tricia(英文小写)\n Please enter the mint version code." 12 50 --title "MINT CODE" 3>&1 1>&2 2>&3)
	DISTRO_CODE="$(echo ${TARGET} | head -n 1 | cut -d ' ' -f 1)"
	if [ -z "${DISTRO_CODE}" ]; then
		echo "检测到您取消了操作"
		echo "已自动切换为tricia"
		DISTRO_CODE='tricia'
	fi
	echo "即将为您安装mint ${DISTRO_CODE} GNU/Linux container"
	do_you_want_to_continue
	linux_distro_common_model_01
}
######################
######################
gnu_linux_mirror_source_manager() {
	aria2c --allow-overwrite=true -d /tmp -o '.tmoe-linux-tool.sh' 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
	bash /tmp/.tmoe-linux-tool.sh --mirror-list
}
##################
#初次安装时用curl或wget，之后用aria2c
###########
gnu_linux_sources_list() {
	if [ "${LINUX_DISTRO}" != "alpine" ]; then
		if [ ! $(command -v curl) ]; then
			wget -O /tmp/.tmoe-linux-tool.sh 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		else
			curl -sLo /tmp/.tmoe-linux-tool.sh 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		fi
		bash /tmp/.tmoe-linux-tool.sh -tuna
	else
		cp -af /etc/apk/repositories /etc/apk/repositories.bak
		#sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
		sed -i 's@http.*/alpine/@http://mirrors.tuna.tsinghua.edu.cn/alpine/@g' /etc/apk/repositories
	fi
	gnu_linux
	#此处要返回依赖检测处！
}
####################
main "$@"
##取消注释，测试用。
##tmoe_manager_main_menu
