#!/data/data/com.termux/files/usr/bin/bash
########################################################################
#检测架构 CHECK architecture
check_arch() {
	case $(uname -m) in
	aarch64)
		ARCH_TYPE="arm64"
		;;
	arm64)
		ARCH_TYPE="arm64"
		;;
	armv8a)
		ARCH_TYPE="arm64"
		;;
	arm)
		ARCH_TYPE="armhf"
		;;
	armv7l)
		ARCH_TYPE="armhf"
		;;
	armhf)
		ARCH_TYPE="armhf"
		;;
	armv6l)
		ARCH_TYPE="armel"
		;;
	armel)
		ARCH_TYPE="armel"
		;;
	amd64)
		ARCH_TYPE="amd64"
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
		exit 1
		;;
	esac
	DEBIAN_FOLDER=debian_${ARCH_TYPE}
	DEBIAN_CHROOT=${HOME}/${DEBIAN_FOLDER}
	RED=$(printf '\033[31m')
	GREEN=$(printf '\033[32m')
	YELLOW=$(printf '\033[33m')
	BLUE=$(printf '\033[34m')
	BOLD=$(printf '\033[1m')
	RESET=$(printf '\033[m')
	cur=$(pwd)
	ANDROIDVERSION=$(getprop ro.build.version.release 2>/dev/null) || ANDROIDVERSION=6
	auto_check
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
		termux-setup-storage
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
	##############
	if grep -Eq 'debian|ubuntu' "/etc/os-release"; then
		LINUX_DISTRO='debian'

	elif grep -Eq "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		LINUX_DISTRO='openwrt'
		cd /tmp
		wget --no-check-certificate -qO "router-debian.bash" https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh
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
		if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHAT_DISTRO='centos'
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHAT_DISTRO='fedora'
		fi

	elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" '/etc/os-release'; then
		LINUX_DISTRO='alpine'

	elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
		LINUX_DISTRO='arch'

	elif grep -Eq "gentoo|funtoo" '/etc/os-release'; then
		LINUX_DISTRO='gentoo'

	elif grep -qi 'suse' '/etc/os-release'; then
		LINUX_DISTRO='suse'

	elif [ "$(cat /etc/issue | cut -c 1-4)" = "Void" ]; then
		LINUX_DISTRO='void'
	fi

	######################################
	DEPENDENCIES=""

	if [ ! -e /usr/bin/aria2c ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/aria2"
		else
			DEPENDENCIES="${DEPENDENCIES} aria2"
		fi
	fi

	if [ ! -e /bin/bash ]; then
		if [ "${LINUX_DISTRO}" = "alpine" ] || [ "${LINUX_DISTRO}" = "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} bash"
		fi
	fi

	if [ ! -e /usr/bin/curl ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/curl"
		else
			DEPENDENCIES="${DEPENDENCIES} curl"
		fi
	fi

	#####################

	if [ ! -e /usr/bin/git ]; then
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
	########################
	if [ ! -e "/usr/bin/less" ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sys-apps/less"
		else
			DEPENDENCIES="${DEPENDENCIES} less"
		fi
	fi

	if [ -L "/usr/bin/less" ]; then
		if [ "${LINUX_DISTRO}" = "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} less"
		fi
	fi
	####################

	if [ ! -e /usr/bin/pv ]; then
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

	if [ ! -e /usr/bin/proot ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} proot"
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
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} sudo"
		fi
	fi
	#####################
	if [ ! -e /bin/tar ]; then
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
	if [ ! -z "${DEPENDENCIES}" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			if ! grep -q '^deb.*edu.cn' "/etc/apt/sources.list"; then
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
			fi
		fi
		echo "正在安装相关软件包及其依赖..."

		if [ "${LINUX_DISTRO}" = "debian" ]; then
			apt update
			apt install -y ${DEPENDENCIES}

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
			emerge -vk ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "suse" ]; then
			zypper in -y ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "void" ]; then
			xbps-install -S -y ${DEPENDENCIES}

		else

			apt update
			apt install -y ${DEPENDENCIES} || port install ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES}
		fi
	fi
	##################
	#解决乱码问题
	CurrentLANG=$LANG
	export LANG=$(echo 'emhfQ04uVVRGLTgK' | base64 -d)
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
				echo "正在下载WSL2内核..."
				echo "目录C:\Users\Public\Downloads"
				aria2c -x 5 -k 1M --split=5 --allow-overwrite=true -o "wsl_update_x64.msi" 'https://cdn.tmoe.me/windows/20H1/wsl_update_x64.msi' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "wsl_update_x64.msi" 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi' || aria2c -x 5 -k 1M --split=5 --allow-overwrite=true -o "wsl_update_x64.msi" 'https://m.tmoe.me/show/share/windows/20H1/wsl_update_x64.msi'
				#/mnt/c/WINDOWS/system32/cmd.exe /c "start .\wsl_update_x64.msi"
			fi
			if [ -e "${DEBIAN_CHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
				echo "检测到您当前使用的是chroot容器，将不会自动调用Windows程序。"
				echo "请手动启动音频服务和X服务。"
			fi
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
				echo "您的系统版本低于10.0.19041.1，需要更新系统。"
				echo "${YELLOW}是否需要下载10.0.19041.172 iso镜像文件，并更新系统？[Y/n]${RESET} "
				echo "该镜像只合成了专业和企业版,${YELLOW}按回车键确认，输n拒绝。${RESET}"
				echo "若您使用的不是这两个版本，则请使用windows update 或更换产品密钥，亦或者输 ${YELLOW}n${RESET}拒绝下载 .[Y/n]"
				echo "请在更新完系统后，以管理员身份打开Powershell,并输入dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
				echo "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"
				echo "wsl --set-default-version 2"
				/mnt/c/WINDOWS/system32/control.exe /name Microsoft.WindowsUpdate
				echo ""
				read opt
				case $opt in
				y* | Y* | "")
					cd /mnt/c/Users/Public/Downloads/
					if [ ! -e "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso" ]; then
						echo "即将为您下载10.0.19041.172 iso镜像文件..."
						echo "目录C:\Users\Public\Downloads"
						aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso" 'https://cdn.tmoe.me/windows/20H1/19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso" 'https://m.tmoe.me/down/share/windows/20H1/19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO'
					fi
					/mnt/c/WINDOWS/system32/cmd.exe /c "start ."
					#下面那处需要再次if,而不是else
					if [ -e "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso" ]; then
						echo "正在校验sha256sum..."
						echo 'Verifying sha256sum ...'
						SHA256SUMDEBIAN="$(sha256sum '19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso' | cut -c 1-64)"
						CORRENTSHA256SUM='f8972cf8e3d6e7ff1abff5f7f4e3e7deeef05422c33299d911253b21e6ee2b49'
						if [ "${SHA256SUMDEBIAN}" != "${CORRENTSHA256SUM}" ]; then
							echo "当前文件的sha256校验值为${SHA256SUMDEBIAN}"
							echo "远程文件的sha256校验值为${CORRENTSHA256SUM}"
							echo 'sha256校验值不一致，请重新下载！'
							echo 'sha256sum value is inconsistent, please download again.'
							echo "按回车键无视错误并继续打开镜像文件,按Ctrl+C取消。"
							echo "${YELLOW}Press enter to continue.${RESET}"
							read
						else
							echo 'Congratulations,检测到sha256sum一致'
							echo 'Detected that sha256sum is the same as the source code, and your download is correct.'
						fi
						echo "请手动运行${YELLOW}setup.exe${RESET}"
						/mnt/c/WINDOWS/explorer.exe '19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso'
						echo "按任意键继续"
						echo "${YELLOW}Press any key to continue! ${RESET}"
						read
					fi

					;;

				\
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

		if (whiptail --title "您想要对这个小可爱做什么 " --yes-button "Tool" --no-button "Manager" --yesno "检测到您使用的是${OSRELEASE} ${WSL}您是想要启动software安装工具，还是system管理工具？ ♪(^∇^*) " 10 50); then
			#bash <(curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh')
			if [ "${LINUX_DISTRO}" = "alpine" ]; then
				wget -O /tmp/.tmoe-linux-tool.sh 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
			else
				curl -sLo /tmp/.tmoe-linux-tool.sh 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
			fi
			bash /tmp/.tmoe-linux-tool.sh
			exit 0
		fi
	fi

	tmoe_manager_main_menu
}
########################################
android_termux() {
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
		if (("${ANDROIDVERSION}" >= '7')); then
			if ! grep -q '^deb.*edu.cn.*termux-packages-24' '/data/data/com.termux/files/usr/etc/apt/sources.list'; then
				echo "${YELLOW}检测到您当前使用的sources.list不是清华源,是否需要更换为清华源[Y/n]${RESET} "
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
		echo "正在安装相关软件包及其依赖..."
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

	tmoe_manager_main_menu
}

########################################################################
#-- 主菜单 main menu
tmoe_manager_main_menu() {
	OPTION=$(
		whiptail --title "GNU/Linux Tmoe manager(20200514-18)" --backtitle "$(
			base64 -d <<-'DoYouWantToSeeWhatIsInside'
				6L6TZGViaWFuLWnlkK/liqjmnKznqIvluo8sVHlwZSBkZWJpYW4taSB0byBzdGFydCB0aGUgdG9v
				bCzokIzns7vnlJ/niannoJTnqbblkZgK
			DoYouWantToSeeWhatIsInside
		)" --menu "Please use the enter and arrow keys to operate.当前主菜单下有十几个选项,请使用方向键和回车键进行操作。更新日志：0509升级备份与还原功能,0510修复sudo,0514支持最新的ubuntu20.10" 17 50 6 \
			"1" "proot安装" \
			"2" "chroot安装" \
			"3" "GUI,audio & sources.list" \
			"4" "FAQ常见问题" \
			"5" "novnc(web端控制)" \
			"6" "backup system备份系统" \
			"7" "restore还原" \
			"8" "query space occupation查询空间占用" \
			"9" "update更新" \
			"10" "Configure zsh" \
			"11" "Download VNC/xwayland/xsdl apk" \
			"12" "VSCode Server arm64" \
			"13" "赋予proot容器真实root权限" \
			"14" "Video tutorial" \
			"15" "remove system移除" \
			"0" "exit退出" \
			3>&1 1>&2 2>&3
	)
	##########################
	if [ "${OPTION}" == '1' ]; then
		install_proot_container
	fi
	##########################
	if [ "${OPTION}" == '2' ]; then
		install_chroot_container
	fi
	##########################
	if [ "${OPTION}" == '3' ]; then
		termux_install_xfce
	fi
	##########################
	if [ "${OPTION}" == '4' ]; then
		frequently_asked_questions
	fi
	##########################
	if [ "${OPTION}" == '5' ]; then
		install_web_novnc
	fi
	##########################
	if [ "${OPTION}" == '6' ]; then
		backup_system
	fi
	##########################
	if [ "${OPTION}" == '7' ]; then
		restore_gnu_linux_container
	fi
	##########################
	if [ "${OPTION}" == '8' ]; then
		space_occupation
	fi
	##########################
	if [ "${OPTION}" == '9' ]; then
		update_tmoe_linux_manager
	fi
	##########################
	if [ "${OPTION}" == '10' ]; then
		bash -c "$(curl -fLsS 'https://gitee.com/mo2/zsh/raw/master/zsh.sh')"
	fi
	##########################
	if [ "${OPTION}" == '11' ]; then
		download_vnc_apk
	fi
	##########################
	if [ "${OPTION}" == '12' ]; then
		start_vscode
	fi
	##########################
	if [ "${OPTION}" == '13' ]; then
		enable_root_mode
	fi
	##########################
	if [ "${OPTION}" == '14' ]; then
		download_video_tutorial
	fi
	##########################
	if [ "${OPTION}" == '15' ]; then
		remove_gnu_linux_container
	fi
	####################
	if [ "${OPTION}" == '0' ]; then
		exit
	fi
	########
}
##########################
vnc_can_not_call_pulse_audio() {
	echo "若您启动VNC后，发现无音频。首先请确保您的termux为最新版本，并安装了termux:api"
	echo "若您的宿主机为Android系统，且发现音频服务无法启动，请在启动完成后，新建一个termux窗口，然后手动在termux原系统里输${GREEN}pulseaudio -D${RESET}来启动音频服务后台进程"
	echo "您亦可输${GREEN}pulseaudio --start${RESET}"
	echo "按回车键自动执行上述命令"
	do_you_want_to_continue
	pulseaudio --start
}
###############
creat_start_linux_deploy_sh() {
	cd $PREFIX/bin
	echo ${CUT_TARGET}
	cat >"${CUT_TARGET}" <<-'EndofFile'
		#!/data/data/com.termux/files/usr/bin/bash
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
	echo "脚本用法：ssh连接后，输入apt install -y curl;bash <(curl -L raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh)"
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
	TMOE_FAQ=$(whiptail --title "FAQ(よくある質問)" --menu \
		"您有哪些疑问？\nWhat questions do you have?" 15 60 5 \
		"1" "VNC无法调用音频" \
		"2" "给Linux Deploy配置VNC音频" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${TMOE_FAQ}" in
	0 | "") tmoe_manager_main_menu ;;
	1) vnc_can_not_call_pulse_audio ;;
	2) linux_deploy_pulse_server ;;
	esac
	############################
	if [ -z ${TMOE_FAQ} ]; then
		tmoe_manager_main_menu
	fi
	#############
	press_enter_to_return
	tmoe_manager_main_menu
}
###########################
install_proot_container() {
	rm -f ~/.Chroot-Container-Detection-File
	rm -f "${DEBIAN_CHROOT}/tmp/.Chroot-Container-Detection-File" 2>/dev/null
	touch ~/.Tmoe-Proot-Container-Detection-File
	install_gnu_linux_container
	#sed -i 's@^command+=" --link2sy@#&@' $(command -v debian)
}
##########################
install_chroot_container() {
	if [ "$(uname -o)" = "Android" ]; then
		echo Android :${ANDROIDVERSION}
		echo "$(getprop ro.product.model)"
		su -c "ls ${HOME} >/dev/null"
		if [ "$?" != "0" ]; then
			echo '检测到root权限授予失败，您无法安装chroot容器'
		else
			echo "检测到您使用的是Android系统"
			echo "非常抱歉，本功能仅适配Linux系统，暂未适配Android。"
			#echo "您在安装chroot容器前必须知悉已挂载目录无法强制卸载的严重性！"
			echo "Android系统请换用proot容器。"
		fi
		echo "由于在测试过程中出现部分已挂载的目录无法强制卸载的情况，故建议您换用proot容器。"
		press_enter_to_return
		tmoe_manager_main_menu
	else
		chroot_install_debian
	fi
}
########################
install_gnu_linux_container() {
	if [ -d ~/${DEBIAN_FOLDER} ]; then
		if (whiptail --title "检测到您已安装GNU/Linux容器,请选择您需要执行的操作！" --yes-button 'Start启动o(*￣▽￣*)o' --no-button 'Reinstall重装(っ °Д °)' --yesno "Container has been installed, please choose what you need to do!" 7 60); then
			debian
		else

			echo "${YELLOW}检测到您已安装GNU/Linux容器,是否重新安装？[Y/n]${RESET} "
			echo "${YELLOW}您可以无需输"y"，直接按回车键确认。${RESET} "
			echo "Detected that you have debian installed, do you want to reinstall it?[Y/n]"
			read opt
			case $opt in
			y* | Y* | "")
				bash ${PREFIX}/bin/debian-rm 2>/dev/null
				sed -i '/alias debian=/d' ${PREFIX}/etc/profile 2>/dev/null
				sed -i '/alias debian-rm=/d' ${PREFIX}/etc/profile 2>/dev/null
				source ${PREFIX}/etc/profile >/dev/null 2>&1
				install_debian_or_download_recovery_pkg_tar_xz
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
		install_debian_or_download_recovery_pkg_tar_xz
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
		cd ${PREFIX}/bin/
		if ! grep -q 'sudo touch' startvnc; then
			sed -i 's/^touch ~/sudo &/' startvnc
			sed -i 's:/data/data/com.termux/files/usr/bin/debian:sudo &:' startvnc
		fi
		###############
		if ! grep -q 'sudo touch' startxsdl; then
			sed -i 's/^touch ~/sudo &/' startxsdl
			sed -i 's:/data/data/com.termux/files/usr/bin/debian:sudo &:' startxsdl
		fi
		#pulseaudio --kill 2>/dev/null;pulseaudio --start 2>/dev/null;sudo debian
		#上面那个是Termux专用的，勿改。

		mkdir -p /data/data/com.termux/files/usr/etc/storage/
		cd /data/data/com.termux/files/usr/etc/storage/

		rm -rf external-tf

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
		sed -i '$ a\alias debian="pulseaudio --kill 2>/dev/null;pulseaudio --start 2>/dev/null;sudo debian"' profile
		#grep 'alias debian-rm=' profile >/dev/null 2>&1 ||
		sed -i '$ a\alias debian-rm="sudo debian-rm"' profile
		#source profile >/dev/null 2>&1
		alias debian="sudo debian"
		alias debian-rm="sudo debian-rm"
		echo "Modifying folder permissions"
		echo "正在修改文件权限..."
		sudo chown root:root -R "${DEBIAN_CHROOT}" 2>/dev/null || su -c "chown root:root -R ${DEBIAN_CHROOT}"
		if [ -d "${HOME}/debian_armhf" ]; then
			sudo chown root:root -R "${HOME}/debian_armhf" 2>/dev/null || su -c "chown root:root -R ${HOME}/debian_armhf"
		fi

		echo "You have modified debian to run with root privileges, this action will destabilize debian."
		echo "If you want to restore, please reinstall debian."
		echo "您已将debian修改为以root权限运行，如需还原，请重新安装debian。"
		echo "The next time you start debian, it will automatically run as root."
		echo "下次启动debian，将自动以root权限运行。"

		echo 'Debian will start automatically after 2 seconds.'
		echo '2s后将为您自动启动debian'
		echo 'If you do not need to display the task progress in the login interface, please manually add "#" (comment symbol) before the "ps -e" line in "~/.zshrc" or "~/.bashrc"'
		echo '如果您不需要在登录界面显示任务进程，请手动注释掉"~/.zshrc"里的"ps -e"'
		sleep 2
		sudo debian
		tmoe_manager_main_menu
		#############
	else
		tmoe_manager_main_menu
	fi
	#不要忘记此处的fi
}
################################
################################
remove_gnu_linux_container() {
	cd ${HOME}
	if [ -e "${DEBIAN_CHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
		unmount_proc_dev
		ls -lah ${DEBIAN_CHROOT}/dev 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/dev/shm 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/dev/pts 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/proc 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/sys 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/tmp 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/root/sd 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/root/tf 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/root/termux 2>/dev/null
		df -h | grep debian
		echo '移除系统前，请先确保您已卸载chroot挂载目录。'
		echo '建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！'
		echo "Before removing the system, make sure you have unmounted the chroot mount directory."
		echo "It is recommended that you back up the entire system before removal. If the data is lost due to improper operation, the developer is not responsible! "
	fi
	ps -e | grep proot
	ps -e | grep startvnc
	echo "移除系统前，请先确保您已停止GNU/Linux容器。"
	pkill proot 2>/dev/null
	pgrep proot &>/dev/null
	if [ "$?" = "0" ]; then
		echo '检测到proot容器正在运行，请先输stopvnc停止运行'
	fi
	ls -l ${DEBIAN_CHROOT}/root/sd/* 2>/dev/null
	if [ "$?" = "0" ]; then
		echo 'WARNING！检测到/root/sd 无法强制卸载，您当前使用的可能是chroot容器'
		echo "若为误报，则请先停止容器进程，再手动移除${DEBIAN_CHROOT}/root/sd"
		echo '建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！'
		#echo '为防止数据丢失，建议您重启设备后再重试。'
		#echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		#echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
		#read
		#tmoe_manager_main_menu
	fi
	echo "若容器未停止运行，则建议你先手动在termux原系统中执行stopvnc，再进行移除操作。"
	echo 'Detecting container size... 正在检测容器占用空间大小'
	du -sh ./${DEBIAN_FOLDER} --exclude=./${DEBIAN_FOLDER}/root/tf --exclude=./${DEBIAN_FOLDER}/root/sd --exclude=./${DEBIAN_FOLDER}/root/termux
	if [ ! -d ~/${DEBIAN_FOLDER} ]; then
		echo "${YELLOW}Detected that you are not currently installed 检测到您当前未安装debian${RESET}"
	fi
	echo "${YELLOW}按回车键确认移除,按Ctrl+C取消 Press enter to confirm.${RESET} "
	read

	chmod 777 -R ${DEBIAN_FOLDER}
	rm -rfv "${DEBIAN_FOLDER}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code 2>/dev/null || sudo rm -rfv "${DEBIAN_FOLDER}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code 2>/dev/null
	if [ -d "${HOME}/debian_armhf" ]; then
		echo "检测到疑似存在树莓派armhf系统，正在移除..."
		chmod 777 -R "${HOME}/debian_armhf"
		rm -rf "${HOME}/debian_armhf" 2>/dev/null || sudo rm -rfv "${HOME}/debian_armhf"
	fi
	sed -i '/alias debian=/d' ${PREFIX}/etc/profile
	sed -i '/alias debian-rm=/d' ${PREFIX}/etc/profile
	source profile >/dev/null 2>&1
	echo 'The container has been removed. If you want to uninstall aria2, enter "apt remove aria2" or "apt purge aria2"'
	echo '移除完成，如需卸载aria2,请手动输apt remove aria2'
	echo '其它相关依赖，如pv、dialog、procps、proot、wget等，均需手动卸载。'
	echo 'If you want to reinstall, it is not recommended to remove the image file.'
	echo '若需删除debian管理器，则请输rm -f ${PREFIX}/bin/debian-i'
	echo "${YELLOW}若您需要重装debian，则不建议删除镜像文件。${RESET} "
	#ls -lh ~/debian-sid-rootfs.tar.xz 2>/dev/null
	#ls -lh ~/debian-buster-rootfs.tar.xz 2>/dev/null
	#ls -lh ~/ubuntu-focal-rootfs.tar.xz 2>/dev/null
	#ls -lh ~/kali-rolling-rootfs.tar.xz 2>/dev/null
	#ls -lh ~/funtoo-1.3-rootfs.tar.xz 2>/dev/null
	cd ${HOME}
	ls -lh *-rootfs.tar.xz
	echo "${YELLOW}请问您是否需要删除镜像文件？[Y/n]${RESET} "
	echo 'Do you need to delete the image file (debian-sid-rootfs.tar.xz)?[Y/n]'

	read opt
	case $opt in
	y* | Y* | "")
		#rm -vf ~/debian-sid-rootfs.tar.xz ${PREFIX}/bin/debian-rm 2>/dev/null
		#rm -vf ~/debian-buster-rootfs.tar.xz 2>/dev/null
		#rm -vf ~/ubuntu-focal-rootfs.tar.xz 2>/dev/null
		#rm -vf ~/kali-rolling-rootfs.tar.xz 2>/dev/null
		#rm -vf ~/funtoo-1.3-rootfs.tar.xz 2>/dev/null
		rm -vf *-rootfs.tar.xz 2>/dev/null
		echo "Deleted已删除"
		;;
	n* | N*) echo "${YELLOW}Skipped,已跳过，按回车键返回。${RESET} " ;;
	*) echo "${YELLOW}Invalid choice，skipped.已跳过，按回车键返回。${RESET} " ;;
	esac
	tmoe_manager_main_menu

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
	OPTION=$(whiptail --title "Backup System" --menu "Choose your option" 15 60 4 \
		"0" "Back to the main menu 返回主菜单" \
		"1" "备份GNU/Linux容器" \
		"2" "备份Termux" \
		"3" "使用Timeshift备份宿主机系统" \
		3>&1 1>&2 2>&3)
	#########################################
	if [ "${OPTION}" == '0' ]; then
		tmoe_manager_main_menu
	fi
	######################
	if [ "${OPTION}" == '1' ]; then
		backup_gnu_linux_container
	fi
	###################
	if [ "${OPTION}" == '2' ]; then
		backup_termux
	fi
	###################
	if [ "${OPTION}" == '3' ]; then
		install_timeshift
	fi
	####################
	#echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	#echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	#read
	tmoe_manager_main_menu
}
###########################
backup_gnu_linux_container() {

	#ls -lth ./debian*.tar.* 2>/dev/null | head -n 5
	#echo '您之前所备份的(部分)文件如上所示'

	#echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
	#press_enter_to_continue
	termux_backup_pre
	TMPtime="${TARGET_BACKUP_FILE_NAME}-$(cat backuptime.tmp)-rootfs_bak"

	if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 12 50); then

		echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
		echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
		press_enter_to_continue
		#stopvnc（pkill all）在linux不会自动生成
		if [ -e "${PREFIX}/bin/stopvnc" ]; then
			tar -PJpcvf ${TMPtime}.tar.xz --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ~/${DEBIAN_FOLDER} ${PREFIX}/bin/debian ${PREFIX}/bin/debian-rm ${PREFIX}/bin/startxsdl ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc
		else
			tar -PJpcvf ${TMPtime}.tar.xz --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ~/${DEBIAN_FOLDER} ${PREFIX}/bin/debian ${PREFIX}/bin/debian-rm ${PREFIX}/bin/startxsdl ${PREFIX}/bin/startvnc
		fi

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
		echo "您选择了tar.gz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.gz"
		echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
		press_enter_to_continue
		if [ "$(command -v pv)" ]; then
			if [ -e "${PREFIX}/bin/stopvnc" ]; then
				tar -Ppczf - --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ~/${DEBIAN_FOLDER} ${PREFIX}/bin/debian ${PREFIX}/bin/debian-rm ${PREFIX}/bin/startxsdl ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
			else
				tar -Ppczf - --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ~/${DEBIAN_FOLDER} ${PREFIX}/bin/debian ${PREFIX}/bin/debian-rm ${PREFIX}/bin/startxsdl ${PREFIX}/bin/startvnc | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
			fi
		else
			if [ -e "${PREFIX}/bin/stopvnc" ]; then
				tar -Ppczvf ${TMPtime}.tar.gz --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ~/${DEBIAN_FOLDER} ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc
			else
				tar -Ppczvf ${TMPtime}.tar.gz --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ~/${DEBIAN_FOLDER} ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc
			fi
		fi
		#最新版弃用了whiptail的进度条！！！
		#tar -Ppczf - --exclude=~/${DEBIAN_FOLDER}/root/sd --exclude=~/${DEBIAN_FOLDER}/root/tf --exclude=~/${DEBIAN_FOLDER}/root/termux ~/${DEBIAN_FOLDER} ${PREFIX}/bin/debian | (pv -n >${TMPtime}.tar.gz) 2>&1 | whiptail --gauge "Packaging into tar.gz \n正在打包成tar.gz" 10 70

		echo "Don't worry too much, it is normal for some directories to backup without permission."
		echo "部分目录无权限备份是正常现象。"
		rm -f backuptime.tmp
		#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0
		pwd
		ls -lth ./*tar* | grep ^- | head -n 1
		echo 'gzip压缩至60%完成是正常现象。'
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
		TMPtime="${TARGET_BACKUP_FILE_NAME}-$(cat backuptime.tmp)-termux_home_bak"
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
		TMPtime="${TARGET_BACKUP_FILE_NAME}-$(cat backuptime.tmp)-termux_usr_bak"
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
		TMPtime="${TARGET_BACKUP_FILE_NAME}-$(cat backuptime.tmp)-termux_home+usr_bak"
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
###############

##################################
##################################
uncompress_tar_xz_file() {
	echo 'tar.xz'
	echo "即将为您解压..."
	echo "${GREEN} tar -PpJxvf ${RESTORE} ${RESET}"
	if [ "$(command -v pv)" ]; then
		pv ${RESTORE} | tar -PpJx
	else
		tar -PpJxvf ${RESTORE}
	fi
}
######################
uncompress_tar_gz_file() {
	echo 'tar.gz'
	echo "即将为您解压..."
	echo "${GREEN} tar -Ppzxvf ${RESTORE} ${RESET}"
	if [ "$(command -v pv)" ]; then
		pv ${RESTORE} | tar -Ppzx
	else
		tar -Ppzxvf ${RESTORE}
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
	esac
	press_enter_to_return
	restore_gnu_linux_container
}
#######################
uncompress_tar_gz_file_test() {
	FILE_EXT_6="${RESTORE:0-6:6}"
	if [ "${FILE_EXT_6}" = 'tar.gz' ]; then
		uncompress_tar_gz_file
	elif [ "${FILE_EXT_6}" = 'tar.xz' ]; then
		uncompress_tar_xz_file
	fi
}
################
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
			echo "请输正确的数字编号!"
		elif (($number >= 0 && $number <= $count)); then
			eval RESTORE=${restore_file_name[number]}
			# cp -fr "${START_DIR}/$choice" "$DIR/restore_file.properties"
			RETURN_TO_WHERE='restore_gnu_linux_container'
			do_you_want_to_continue
			uncompress_tar_file
			break
		else
			echo "Please enter the right number!"
			echo "请输正确的数字编号!"
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
	if [ -e "${DEBIAN_CHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
		su -c "umount -lf ${DEBIAN_CHROOT}/dev >/dev/null 2>&1"
		su -c "umount -lf ${DEBIAN_CHROOT}/dev/shm  >/dev/null 2>&1"
		su -c "umount -lf ${DEBIAN_CHROOT}/dev/pts  >/dev/null 2>&1"
		su -c "	umount -lf ${DEBIAN_CHROOT}/proc  >/dev/null 2>&1"
		su -c "umount -lf ${DEBIAN_CHROOT}/sys  >/dev/null 2>&1"
		su -c "umount -lf ${DEBIAN_CHROOT}/tmp  >/dev/null 2>&1"
		su -c "umount -lf ${DEBIAN_CHROOT}/root/sd  >/dev/null 2>&1 "
		su -c "umount -lf ${DEBIAN_CHROOT}/root/tf  >/dev/null 2>&1"
		su -c "umount -lf ${DEBIAN_CHROOT}/root/termux >/dev/null 2>&1"
	fi
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
	select_file_manually
}
###############
file_directory_selection() {

	if (whiptail --title "FILE PATH" --yes-button '自动' --no-button '手动' --yesno "您想要手动指定文件目录还是自动选择？" 9 50); then
		where_is_start_dir
	else
		manually_select_the_file_directory
		select_file_manually
	fi
}
###################
manually_select_the_file_directory() {
	TARGET_BACKUP_FILE_PATH=$(whiptail --inputbox "请输入文件路径(精确到目录名称)，默认为/sdcard/Download/backup\n Please enter the file path." 12 50 --title "FILEPATH" 3>&1 1>&2 2>&3)
	START_DIR="$(echo ${TARGET_BACKUP_FILE_PATH} | head -n 1 | cut -d ' ' -f 1)"
	echo $START_DIR
	if [ -z ${START_DIR} ]; then
		echo "文件目录不能为空"
		press_enter_to_return
		restore_gnu_linux_container
	fi
}
###############
restore_gnu_linux_container() {
	unmount_proc_dev
	OPTION=$(whiptail --title "Restore System" --menu "你想要恢复哪个小可爱到之前的备份状态" 15 55 4 \
		"1" "Restore GNU/Linux container容器" \
		"2" "Restore termux" \
		"3" "select path manually手动选择路径" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	###########################################################################
	if [ "${OPTION}" == '1' ]; then
		#ls -lth debian*tar* 2>/dev/null || echo '未检测到备份文件' | head -n 10
		if (whiptail --title "RESTORE FILE" --yes-button '最新latest' --no-button 'select manually' --yesno "您是想要还原最新文件，还是手动选择备份文件？" 9 50); then
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
		if (whiptail --title "RESTORE FILE" --yes-button '最新latest' --no-button 'select manually' --yesno "您是想要还原最新文件，还是手动选择备份文件？" 9 50); then
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
	##########################
	if [ "${OPTION}" == '0' ]; then
		tmoe_manager_main_menu
	fi
	##########################
	#tmoe_manager_main_menu
}
############################
############################
space_occupation() {
	cd ${HOME}/..
	OPTION=$(whiptail --title "Query space occupation ranking" --menu "查询空间占用排行" 15 60 4 \
		"0" "Back to the main menu 返回主菜单" \
		"1" "termux各目录" \
		"2" "termux文件" \
		"3" "sdcard" \
		"4" "总存储空间用量Disk usage" \
		3>&1 1>&2 2>&3)
	###########################################################################
	#echo "${YELLOW}2333333333${RESET}"
	if [ "${OPTION}" == '1' ]; then
		echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
		echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
		echo "${YELLOW}主目录 TOP15${RESET}"

		du -hsx ./home/* ./home/.* 2>/dev/null | sort -rh | head -n 15

		echo ''

		echo "${YELLOW}usr 目录 TOP6${RESET}"

		du -hsx ./usr/* 2>/dev/null | sort -rh | head -n 6

		echo ''

		echo "${YELLOW}usr/lib 目录 TOP8${RESET}"

		du -hsx ./usr/lib/* 2>/dev/null | sort -rh | head -n 8

		echo ''

		echo "${YELLOW}usr/share 目录 TOP8${RESET}"

		du -hsx ./usr/share/* 2>/dev/null | sort -rh | head -n 8

		echo ''
		press_enter_to_return
		space_occupation

	fi
	###############################
	if [ "${OPTION}" == '2' ]; then
		echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
		echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
		echo "${YELLOW}termux 文件大小排行榜(30名)${RESET}"

		find ./ -type f -print0 2>/dev/null | xargs -0 du | sort -n | tail -30 | cut -f2 | xargs -I{} du -sh {}
		press_enter_to_return
		space_occupation

	fi

	if [ "${OPTION}" == '3' ]; then
		cd /sdcard
		echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
		echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
		echo "${YELLOW}sdcard 目录 TOP15${RESET}"
		du -hsx ./* ./.* 2>/dev/null | sort -rh | head -n 15

		echo "${YELLOW}sdcard文件大小排行榜(30名)${RESET}"

		find ./ -type f -print0 2>/dev/null | xargs -0 du | sort -n | tail -30 | cut -f2 | xargs -I{} du -sh {}

		press_enter_to_return
		space_occupation
	fi

	if [ "${OPTION}" == '4' ]; then
		echo "${YELLOW}Disk usage${RESET}"
		df -h | grep G | grep -v tmpfs
		press_enter_to_return
		space_occupation
	fi

	#####################################
	if [ "${OPTION}" == '0' ]; then

		tmoe_manager_main_menu
	fi
	tmoe_manager_main_menu
}

########################################################################
update_tmoe_linux_manager() {
	#curl -L -o ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh'
	aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh' || curl -Lo ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh' || sudo aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh'
	if [ "${LINUX_DISTRO}" != "Android" ]; then
		sed -i '1 c\#!/bin/bash' ${PREFIX}/bin/debian-i
	fi

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
		#aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://cdn.tmoe.me/git/linux/VNCViewer_com-realvnc-viewer-android-3-6-1-42089.tar.xz' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://m.tmoe.me/down/share/Android/VNC/VNCViewer_com-realvnc-viewer-android-3-6-1-42089.tar.xz'
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
		#		aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://cdn.tmoe.me/git/linux/XServerXSDL-X-org-server_1-20-41.tar.xz' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://m.tmoe.me/down/share/Android/VNC/XServerXSDL-X-org-server_1-20-41.tar.xz'
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
	GET_DEBIAN_BIND_LINE=$(cat $PREFIX/bin/debian | grep -n 'command+=" -b /data' | cut -d ':' -f 1 | head -n 1)
	sed -i '/com.sion.sparkle/d' $PREFIX/bin/debian
	#rm ${DEBIAN_CHROOT}/etc/xwayland || sudo rm ${DEBIAN_CHROOT}/etc/xwayland
	sed -i "${GET_DEBIAN_BIND_LINE} i\ command+=\" -b /data/data/com.sion.sparkle/files:/etc/xwayland\"" $PREFIX/bin/debian
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
	OPTION=$(whiptail --title "remote desktop apk" --menu "Which remote desktop software do you want to install?" 15 60 4 \
		"1" "vnc/xsdl" \
		"2" "xwayland" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##########################
	if [ "${OPTION}" == '0' ]; then
		tmoe_manager_main_menu
	fi
	####################
	if [ "${OPTION}" == '1' ]; then
		download_vnc_or_xsdl_apk
	fi
	##################
	if [ "${OPTION}" == '2' ]; then
		xwayland_warning
	fi
	#####################
	tmoe_manager_main_menu
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
			#!/data/data/com.termux/files/usr/bin/bash
			touch "${DEBIAN_CHROOT}/tmp/startcode.tmp"
			am start -a android.intent.action.VIEW -d "http://localhost:8080"
			echo "本机默认vscode服务地址localhost:8080"
			echo The LAN VNC address 局域网地址\$(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):8080
			echo "Please paste the address into your browser!"
			echo "请将地址粘贴到浏览器的地址栏中"

			echo "您之后可以输code-server来启动VS Code."
			echo 'You can type "code-server" to start VS Code.'
			debian
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
			paly_video_tutorial
		else
			download_video_tutorial_again
		fi
	else
		download_video_tutorial_again

	fi

}

##########################
download_video_tutorial_again() {
	aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "20200229vnc教程06.mp4" 'https://cdn.tmoe.me/Tmoe-Debian-Tool/20200229VNC%E6%95%99%E7%A8%8B06.mp4' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "20200229vnc教程06.mp4" 'https://m.tmoe.me/down/share/videos/20200229vnc%E6%95%99%E7%A8%8B06.mp4' || curl -Lo "20200229vnc教程06.mp4" 'https://cdn.tmoe.me/Tmoe-Debian-Tool/20200229VNC%E6%95%99%E7%A8%8B06.mp4'
	paly_video_tutorial
}
paly_video_tutorial() {
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
	echo "This feature currently only supports Linux systems and is still in beta."
	echo "本功能目前仅对Linux系统测试开放。"
	echo "This feature is currently in the beta stage. If you find that some directories cannot be unmounted forcibly before removing the container, please restart your device before uninstalling the chroot container to prevent the mounted directory from being deleted by mistake."
	echo "本功能目前仍处于测试阶段，移除容器前若发现部分已挂载目录无法强制卸载，请重启设备再卸载chroot容器，防止已挂载目录被误删！"
	echo "按回车键继续,按Ctrl+C取消。"
	echo "${YELLOW}Press enter to continue.${RESET}"
	read
	rm -f "${DEBIAN_CHROOT}/tmp/.Tmoe-Proot-Container-Detection-File" 2>/dev/null
	rm -f ~/.Tmoe-Proot-Container-Detection-File 2>/dev/null
	touch ~/.Chroot-Container-Detection-File
	install_gnu_linux_container
}
#################################
install_debian_or_download_recovery_pkg_tar_xz() {
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

						5. 恢复包的使用
						(a)在您未拒绝接受恢复包的情况下，本工具会将恢复包下载至内置存储设备，并将其解压出来，以便您能快速安装并使用Debian GNU/Linux的图形桌面环境。本工具下载的恢复包不会为您提供个性化服务，您需要自行安装、配置第三方软件和主题美化。
						(b)您有权选择接受或拒绝使用恢复包或本工具。

						6. 信息安全
						(a)本工具安装的是原生GNU/Linux 系统，截至2020-03-12，默认没有开启安全保护和防火墙功能，请您妥善保管root密码及其它重要账号信息。
						同时希望您能注意在信息网络上不存在“绝对完善的安全措施”。

						7.卸载说明
						(a)您在移除容器前，必须先停止容器进程。
						(b)由于在测试chroot容器的过程中，出现了部分已挂载目录无法强制卸载的情况，故本工具在移除容器前会进行检测，并给出相关提示。
						建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！

						8.其它说明
						(a)若您需要在开源项目中引用本脚本，建议您先与原开发者联系，若无法联系，则只需附上本git-repo的链接gitee.com/mo2/linux
						If you want to reference this script in an open source project,it is recommended that you contact the original developer.If you can't contact the developer, just attach the github link: https://github.com/2moe/tmoe-linux

						9.最终用户许可协议的更改
						(a)如果决定更改最终用户许可协议，我们会在本协议中、本工具网站中以及我们认为适当的位置发布这些更改，以便您了解如何保障我们双方的权益。
						(b)本工具开发者保留随时修改本协议的权利,因此建议您不定期查看。
						The developer of this tool reserves the right to modify this agreement at any time.
		EndOfFile
		echo 'You must agree to the EULA to use this tool.'
		echo "Press ${GREEN}Enter${RESET} to agree ${BLUE}the EULA${RESET}, otherwise press ${YELLOW}Ctrl + C${RESET} or ${RED}close${RESET} the terminal directly."
		echo "按${GREEN}回车键${RESET}同意${BLUE}《最终用户许可协议》${RESET} ，否则请按${YELLOW}Ctrl+C${RESET} 或直接${RED}关闭${RESET}终端。 "
		#if [ "${LINUX_DISTRO}" != 'Android' ]; then
		#export LANG=${CurrentLANG}
		#fi
		read
	fi
	choose_which_gnu_linux_distro
}

###################################################
download_debian_xfce_tar_xz() {
	aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "debian_2020-03-11_17-31.tar.xz" 'https://cdn.tmoe.me/Tmoe-Debian-Tool/proot/Debian-xfce/debian_2020-03-11_17-31.tar.xz' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "debian_2020-03-11_17-31.tar.xz" 'https://m.tmoe.me/show/share/Android/proot/Debian-xfce/debian_2020-03-11_17-31.tar.xz'
	echo 'Verifying sha256sum ...'
	echo '正在校验sha256sum...'
	SHA256SUMDEBIAN="$(sha256sum 'debian_2020-03-11_17-31.tar.xz' | cut -c 1-64)"
	CORRENTSHA256SUM='931565aa44cd12a7a5ed40c12715724d6bed51eb4fccf1a91a3c6a4346d12721' #DevSkim: ignore DS173237
	if [ "${SHA256SUMDEBIAN}" != "${CORRENTSHA256SUM}" ]; then
		echo "当前文件的sha256校验值为${SHA256SUMDEBIAN}"
		echo "远程文件的sha256校验值为${CORRENTSHA256SUM}"
		echo 'sha256校验值不一致，请重新下载！'
		echo 'sha256sum value is inconsistent, please download again.'
		echo "按回车键无视错误并继续安装,按Ctrl+C取消。"
		echo "${YELLOW}Press enter to continue.${RESET}"
		read

	else
		echo 'Congratulations,检测到sha256sum一致'
		echo 'Detected that sha256sum is the same as the source code, and your download is correct.'
	fi
	un_xz_debian_recovery_kit

}
#####################################
un_xz_debian_recovery_kit() {
	echo "                                        "
	echo "                            .:7E        "
	echo "            .iv7vrrrrr7uQBBBBBBB:       "
	echo "           v17::.........:SBBBUg        "
	echo "        vKLi.........:. .  vBQrQ        "
	echo "   sqMBBBr.......... :i. .  SQIX        "
	echo "   BBQBBr.:...:....:. 1:.....v. ..      "
	echo "    UBBB..:..:i.....i YK:: ..:   i:     "
	echo "     7Bg.... iv.....r.ijL7...i. .Lu     "
	echo "  IB: rb...i iui....rir :Si..:::ibr     "
	echo "  J7.  :r.is..vrL:..i7i  7U...Z7i..     "
	echo "  ...   7..I:.: 7v.ri.755P1. .S  ::     "
	echo "    :   r:.i5KEv:.:.  :.  ::..X..::     "
	echo "   7is. :v .sr::.         :: :2. ::     "
	echo "   2:.  .u: r.     ::::   r: ij: .r  :  "
	echo "   ..   .v1 .v.    .   .7Qr: Lqi .r. i  "
	echo "   :u   .iq: :PBEPjvviII5P7::5Du: .v    "
	echo "    .i  :iUr r:v::i:::::.:.:PPrD7: ii   "
	echo "    :v. iiSrr   :..   s i.  vPrvsr. r.  "
	echo "     ...:7sv:  ..PL  .Q.:.   IY717i .7. "
	echo "      i7LUJv.   . .     .:   YI7bIr :ur "
	echo "     Y rLXJL7.:jvi:i:::rvU:.7PP XQ. 7r7 "
	echo "    ir iJgL:uRB5UPjriirqKJ2PQMP :Yi17.v "
	echo "         :   r. ..      .. .:i  ...     "
	echo "正在解压debian_2020-03-11_17-31.tar.xz，Decompressing debian-xfce recovery package, please be patient."
	pv "debian_2020-03-11_17-31.tar.xz" | tar -PpJx 2>/dev/null
	cd "$cur"
	#用绝对路径
	if [ ! -L '/data/data/com.termux/files/home/storage/external-1' ]; then

		sed -i 's@^command+=" -b /data/data/com.termux/files/home/storage/external-1@#&@g' ${PREFIX}/bin/debian 2>/dev/null
		rm -f ${HOME}/debian_arm64/root/tf 2>/dev/null
	fi
	echo '解压完成，您之后可以输startvnc来启动vnc服务，输stopvnc停止'
	echo '在容器内输debian-i启动debian应用安装及远程桌面配置修改工具。'
	echo 'The vnc service is about to start for you. The password you entered is hidden.'
	echo '即将为您启动vnc服务，您需要输两遍（不可见的）密码。'
	echo "When prompted for a view-only password, it is recommended that you enter 'n'"
	echo '如果提示view-only,那么建议您输n,选择权在您自己的手上。'
	echo '请输入6至8位的VNC密码'
	source ${PREFIX}/bin/startvnc

}
###############################
termux_install_xfce() {
	if [ "${LINUX_DISTRO}" = 'Android' ]; then
		if (("${ANDROIDVERSION}" < '7')); then
			echo "检测到您当前的安卓系统版本低于7，继续操作可能存在问题，是否继续？"
			echo "Since termux has officially stopped maintaining the old system below android 7, it is not recommended that you continue to operate."
			echo 'Press Enter to continue.'
			echo "${YELLOW}按回车键继续，按Ctrl+C取消。${RESET}"
			read
		fi
	else
		echo "检测到您当前使用的系统非Android"
		echo 'Press Enter to continue.'
		echo "${YELLOW}按回车键继续${RESET}"
		read
	fi
	OPTION=$(whiptail --title "Termux GUI" --menu "Termux native GUI has fewer software packages. It is recommended that you install a container. Termux原系统GUI可玩性较低，建议您安装GNU/Linux容器" 17 60 6 \
		"1" "install xfce4" \
		"2" "modify vnc conf" \
		"3" "configure Termux LAN audio局域网音频传输" \
		"4" "switch VNC audio音频传输方式" \
		"5" "更换为清华源(支持termux、debian、ubuntu和kali)" \
		"6" "download termux_Fdroid.apk" \
		"7" "remove xfce4" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	###########################################################################
	if [ "${OPTION}" == '0' ]; then
		tmoe_manager_main_menu
	fi
	#####################################
	if [ "${OPTION}" == '1' ]; then
		if [ "${LINUX_DISTRO}" != 'Android' ]; then
			bash <(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh)
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
			#!/data/data/com.termux/files/usr/bin/bash
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
			echo "已为您启动vnc服务 Vnc service has been started, enjoy it!"
			echo "默认为前台运行，您可以按Ctrl+C终止当前进程。"
			startxfce4

		EndOfFile
		chmod +x ${PREFIX}/bin/startvnc
		source ${PREFIX}/bin/startvnc
	fi
	#######################
	if [ "${OPTION}" == '2' ]; then
		if [ "${LINUX_DISTRO}" != 'Android' ]; then
			bash <(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh)
			exit 0
		fi
		modify_android_termux_vnc_config
	fi
	##################
	if [ "${OPTION}" == '3' ]; then
		termux_pulse_audio_lan
	fi
	##################
	if [ "${OPTION}" == '4' ]; then
		switch_vnc_pulse_audio_transport_method
	fi
	##################
	if [ "${OPTION}" == '7' ]; then
		if [ "${LINUX_DISTRO}" != 'Android' ]; then
			bash <(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh)
			exit 0
		fi
		remove_android_termux_xfce
	fi
	##################
	if [ "${OPTION}" == '5' ]; then
		if [ "${LINUX_DISTRO}" = 'Android' ]; then
			termux_tuna_sources_list
		else
			gnu_linux_sources_list
		fi
	fi
	##################
	if [ "${OPTION}" == '6' ]; then
		aria2_download_termux_apk
	fi
}
#####################################
switch_vnc_pulse_audio_transport_method() {
	cd ${DEBIAN_CHROOT}/root
	if grep -Eq '4712|4713' ./.vnc/xstartup; then
		PULSEtransportMethon='检测到您当前使用的可能是XSDL音频传输'
	else
		PULSEtransportMethon='检测到您当前使用的是termux音频传输'
	fi

	if (whiptail --title "您想用哪个软件来传输VNC音频？(｡･∀･)ﾉﾞ" --yes-button 'Termux(*￣▽￣*)o' --no-button 'XSDL(っ °Д °)' --yesno "${PULSEtransportMethon},请选择您需要切换的传输类型！注：您必须先安装XSDL app才能使用XSDL的音频服务，切换成XSDL后，启动VNC时将自动打开XSDL,此时不会转发X,您也无需执行任何操作。" 11 50); then

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
	termux_install_xfce
}
###############################
termux_pulse_audio_lan() {
	cd $PREFIX/etc/pulse
	if grep -q '192.168.0.0/16' default.pa; then
		LANPULSE='检测到您已启用局域网音频传输'
	else
		LANPULSE='检测到您未启用局域网音频传输，默认仅允许本机传输'
	fi

	if (whiptail --title "请问您是需要启用还是禁用此功能呢？(｡･∀･)ﾉﾞ" --yes-button 'enable(*￣▽￣*)o' --no-button 'Disable(っ °Д °)' --yesno "${LANPULSE},请选择您需要执行的操作！" 8 50); then
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
	termux_install_xfce
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
	pulseaudio --kill 2>/dev/null
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
		firefox 'http://localhost:6080/vnc.html' 2>/dev/null
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
	echo "${YELLOW}按回车键确认卸载,按Ctrl+C取消${RESET} "
	echo 'Press enter to confirm ,press Ctrl + C to cancel'
	read
	apt purge -y ^xfce tigervnc aterm
	apt purge -y x11-repo
	apt autoremove
	press_enter_to_return
	tmoe_manager_main_menu

}
#################
termux_tuna_sources_list() {
	if ! grep -q '^deb.*edu.cn.*termux-packages-24' '/data/data/com.termux/files/usr/etc/apt/sources.list'; then
		sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main@' /data/data/com.termux/files/usr/etc/apt/sources.list
		if ! grep -q '^deb' '/data/data/com.termux/files/usr/etc/apt/sources.list'; then
			echo -e '\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main' >>/data/data/com.termux/files/usr/etc/apt/sources.list
		fi
	fi

	if ! grep -q '^deb.*tuna' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/game.list'; then
		sed -i 's@^\(deb.*games stable\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/game-packages-24 games stable@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/game.list
	fi

	if ! grep -q '^deb.*tuna' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/science.list'; then
		sed -i 's@^\(deb.*science stable\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/science-packages-24 science stable@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/science.list
	fi

	if [ -e "/data/data/com.termux/files/usr/etc/apt/sources.list.d/x11.list" ]; then
		if ! grep -q '^deb.*tuna' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/x11.list'; then
			sed -i 's@^\(deb.*x11 main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/x11-packages x11 main@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/x11.list
		fi
	fi

	if [ -e "/data/data/com.termux/files/usr/etc/apt/sources.list.d/unstable.list" ]; then
		if ! grep -q '^deb.*tuna' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/unstable.list'; then
			sed -i 's@^\(deb.*unstable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/unstable-packages unstable main@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/unstable.list
		fi
	fi

	if [ -e "/data/data/com.termux/files/usr/etc/apt/sources.list.d/root.list" ]; then
		if ! grep -q '^deb.*tuna' '/data/data/com.termux/files/usr/etc/apt/sources.list.d/root.list'; then
			sed -i 's@^\(deb.*root stable\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-root-packages-24 root stable@' /data/data/com.termux/files/usr/etc/apt/sources.list.d/root.list
		fi
	fi
	apt update
	apt dist-upgrade -y
	echo '修改完成，您当前的软件源列表如下所示。'
	cat /data/data/com.termux/files/usr/etc/apt/sources.list
	cat /data/data/com.termux/files/usr/etc/apt/sources.list.d/*
	echo "您可以输${YELLOW}apt edit-sources${RESET}来手动编辑main源"
	echo "您也可以输${YELLOW}cd ${PREFIX}/etc/apt/sources.list.d ; nano ./* ${RESET}来手动编辑其它源"
	press_enter_to_return
	android_termux
	#此处要返回依赖检测处！

}
##################
choose_which_gnu_linux_distro() {
	RETURN_TO_WHERE='choose_which_gnu_linux_distro'
	SELECTED_GNU_LINUX=$(whiptail --title "GNU/Linux distros" --menu "Which distribution do you want to install? 您想要安装哪个GNU/Linux发行版?" 15 50 6 \
		"1" "Debian:最早的发行版之一" \
		"2" "Ubuntu:我的存在是因為大家的存在" \
		"3" "Kali Rolling:设计用于数字取证和渗透测试" \
		"4" "beta公测版:manjaro,centos" \
		"5" "alpha内测版:gentoo,armbian" \
		"6" "arch:系统设计以KISS为总体指导原则" \
		"7" "fedora:红帽社区版,新技术试验场" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${SELECTED_GNU_LINUX}" in
	0 | "") tmoe_manager_main_menu ;;
	1) install_debian_gnu_linux_distro ;;
	2) install_ubuntu_gnu_linux_distro ;;
	3) install_kali_rolling_gnu_linux_distro ;;
	4) install_beta_containers ;;
	5) install_alpha_containers ;;
	6) install_arch_linux_distro ;;
	7) install_fedora_gnu_linux_distro ;;
	esac
	####################
	press_enter_to_return
	tmoe_manager_main_menu
}
##############################
install_alpha_containers() {
	ALPHA_SYSTEM=$(
		whiptail --title "Alpha features" --menu "WARNING！本功能仍处于测试阶段,可能无法正常运行。\nAlpha features may not work properly." 17 55 7 \
			"1" "armbian bullseye(arm64,armhf)" \
			"2" "opensuse tumbleweed(小蜥蜴风滚草)" \
			"3" "raspbian樹莓派 buster(armhf)" \
			"4" "gentoo(追求极限配置和极高自由,armhf,x86,x64)" \
			"5" "devuan ascii(不使用systemd,基于debian)" \
			"6" "slackware(armhf,x64)" \
			"7" "Funtoo:专注于改进Gentoo" \
			"8" "openwrt(常见于路由器,arm64,x64)" \
			"9" "apertis" \
			"10" "alt" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${ALPHA_SYSTEM}" in
	0 | "") choose_which_gnu_linux_distro ;;
	1) install_armbian_linux_distro ;;
	2) install_opensuse_linux_distro ;;
	3) install_raspbian_linux_distro ;;
	4) install_gentoo_linux_distro ;;
	5) install_devuan_linux_distro ;;
	6) install_slackware_linux_distro ;;
	7) install_funtoo_linux_distro ;;
	8) install_openwrt_linux_distro ;;
	9) install_apertis_linux_distro ;;
	10) install_alt_linux_distro ;;
	esac
	###########################
	press_enter_to_return
	tmoe_manager_main_menu
	####################
}
#########################
install_beta_containers() {
	BETA_SYSTEM=$(
		whiptail --title "Beta features" --menu "WARNING！本功能仍处于公测阶段,可能存在一些bug。\nBeta features may not work properly." 17 55 7 \
			"1" "manjaro(让arch更方便用户使用,arm64)" \
			"2" "centos (基于红帽的社区企业操作系统)" \
			"3" "Void:基于xbps包管理器的独立发行版" \
			"4" "alpine 3.11(非glibc的精简系统)" \
			"5" "mint tricia(简单易用的系统,x86,x64)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${BETA_SYSTEM}" in
	0 | "") choose_which_gnu_linux_distro ;;
	1) install_manjaro_linux_distro ;;
	2) install_centos_linux_distro ;;
	3) install_void_linux_distro ;;
	4) install_alpine_linux_distro ;;
	5) install_mint_linux_distro ;;
	esac
	######################
	press_enter_to_return
	tmoe_manager_main_menu
	####################
}
#########################
install_debian_gnu_linux_distro() {
	if (whiptail --title "Install GNU/Linux" --yes-button 'Software source' --no-button 'Download Rec pkg' --yesno "Do you want to install debian container via Tsinghua University open source mirror station, or download the recovery package (debian-xfce.tar.xz)?The latter only supports arm64.您想要通过软件源镜像站来安装，还是在线下载恢复包来安装？软件源获取的是最新版镜像，且支持arm64,armhf,x86,x64等架构，安装基础系统速度很快，但安装gui速度较慢。恢复包非最新版,软件包只更新至2020-03-11,且仅支持arm64架构,但安装gui速度较快。若您无使用GUI的需求，建议选择前者。" 16 55); then
		buster_or_sid
	else
		if [ ! -d "/sdcard/Download/backup" ]; then
			mkdir -p /sdcard/Download/backup
		fi
		cd /sdcard/Download/backup
		if [ -e "debian_2020-03-11_17-31.tar.xz" ]; then
			if (whiptail --title "Install Debian" --yes-button '解压uncompress' --no-button 'Download again' --yesno "It was detected that the recovery package has been downloaded. Do you want to uncompress it, or download it again?检测到恢复包已经下载,您想要直接解压还是重新下载？" 14 50); then
				un_xz_debian_recovery_kit
			else
				download_debian_xfce_tar_xz
			fi
		else
			download_debian_xfce_tar_xz
		fi
	fi
}
########################
buster_or_sid() {
	if (whiptail --title "Debian version" --yes-button 'Sid' --no-button 'Buster' --yesno "请选择您需要安装的debian版本，Please select the debian version you need to install.Buster为当前的stable版,sid为unstable。Buster更加稳定且bug较少,但buster的软件包较旧,而sid较新。Buster is more stable and has fewer bugs, but the packages inside the buster software source are older. The sid package is relatively new." 15 50); then
		if [ "${LINUX_DISTRO}" != 'iSH' ]; then
			bash -c "$(curl -fLsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh')"
		else
			curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh' | bash
		fi
	else
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh | sed 's:/sid:/buster:g' | sed 's:extract z:extract:' | sed 's:-sid:-buster:g' | sed 's@#deb http@deb http@g' | sed 's/.*sid main/#&/')"
	fi
}
###########
install_ubuntu_gnu_linux_distro() {
	DISTRO_NAME='ubuntu'
	BETA_SYSTEM=$(
		DISTRO_NAME='ubuntu'
		whiptail --title "UBUNTU" --menu "您想要安装哪个版本？Which version do you want to install?" 17 55 7 \
			"1" "20.10 Groovy Gorilla 時髦大猩猩" \
			"2" "20.04 Focal Fossa 焦點馬島長尾狸貓" \
			"3" "Custom code手动输入版本代号" \
			"4" "18.04 Bionic Beaver 仿生海狸" \
			"5" "16.04 Xenial Xerus 好客的非洲地松鼠" \
			"6" "Latest(自动检测最新版，测试中)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
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
	echo "即将为您安装Ubuntu ${DISTRO_CODE} GNU/Linux container"
	do_you_want_to_continue
	install_different_ubuntu_gnu_linux_distros
	press_enter_to_return
	tmoe_manager_main_menu
}
#########################
custom_ubuntu_version() {
	TARGET=$(whiptail --inputbox "请输入ubuntu版本代号，例如focal(英文小写)\n Please enter the ubuntu version code." 12 50 --title "UBUNTU CODE" 3>&1 1>&2 2>&3)
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
	if [ "${ARCH_TYPE}" = 'amd64' ] || [ "${ARCH_TYPE}" = 'i386' ]; then
		ubuntu_distro_x64_model
	else
		#ubuntu-ports
		ubuntu_distro_arm_model
	fi
}
############
check_the_latest_ubuntu_version() {
	LXC_IMAGES_REPO="https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/${DISTRO_NAME}/"
	DISTRO_CODE=$(curl -sL ${LXC_IMAGES_REPO} | grep date | cut -d '=' -f 4 | cut -d '"' -f 2 | grep -Ev 'size|bionic|cosmic|disco|eoan|focal|trusty|xenial|groovy' | tail -n 1)
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
	if [ "${ARCH_TYPE}" = 'armhf' ]; then
		echo "检测到您使用的是armhf架构，将为您降级至Fedora 29"
		DISTRO_CODE='29'
		linux_distro_common_model_01
	elif [ "${ARCH_TYPE}" = 'i386' ]; then
		echo "Fedora不支持您的架构"
	else
		OLD_STABLE_VERSION='31'
		check_the_latest_distro_version
	fi
}
################
install_funtoo_linux_distro() {
	DISTRO_NAME='funtoo'
	OLD_STABLE_VERSION='1.3'
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
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
			sed '70 a\ARCH_TYPE="armhf"' |
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
	DISTRO_CODE='3.11'
	OLD_STABLE_VERSION='edge'
	which_version_do_you_want_to_install
}
#####################
install_opensuse_linux_distro() {
	DISTRO_NAME='opensuse'
	DISTRO_CODE='tumbleweed'
	linux_distro_common_model_01
}
########################
install_raspbian_linux_distro() {
	if [ "${ARCH_TYPE}" != 'arm64' ] && [ "${ARCH_TYPE}" != 'armhf' ]; then
		apt install -y qemu qemu-user-static debootstrap
	fi

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
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed '72 a\ARCH_TYPE="armhf"' |
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
	if [ "${ARCH_TYPE}" != 'arm64' ] && [ "${ARCH_TYPE}" != 'amd64' ]; then
		echo "非常抱歉，Tmoe-linux的开发者未对您的架构进行适配"
		press_enter_to_return
		tmoe_manager_main_menu
	fi

	#aria2c -x 5 -k 1M --split 5 -o manjaro-latest-rootfs.tar.gz "https://mirrors.tuna.tsinghua.edu.cn/osdn/storage/g/m/ma/manjaro-arm/.rootfs/Manjaro-ARM-aarch64-latest.tar.gz"
	#https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${ARCH_TYPE}/default/${ttime}rootfs.tar.xz
	touch ~/.MANJARO_ARM_DETECTION_FILE
	echo "检测到您选择的是manajro,即将从第三方网盘下载容器镜像。"

	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed 's@mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid.*xz@cdn.tmoe.me/Tmoe-Debian-Tool/proot/Manjaro/manjaro_arm64.tar.xz@g' |
		sed '/清华大学开源镜像站/d' |
		sed '/Tsinghua University/d' |
		sed 's/debian system/manjaro system/g' |
		sed 's:debian-sid:manjaro-stable:g' |
		sed 's:debian/sid:manjaro/stable:g' |
		sed 's:rootfs.tar.xz:rootfs.tar.gz:g' |
		sed 's:Debian GNU/Linux:Manjaro GNU/Linux:g')"
}

############################
install_openwrt_linux_distro() {
	if [ ! -e "openwrt-snapshot-rootfs.tar.xz" ]; then
		cd ${HOME}
		if [ "${ARCH_TYPE}" = 'arm64' ]; then
			aria2c -x 16 -s 16 -k 1M -o "openwrt-snapshot-rootfs.tar.xz" "https://cdn.tmoe.me/Tmoe-Debian-Tool/chroot/archive/openwrt_arm64.tar.xz" || aria2c -x 16 -s 16 -k 1M -o "openwrt-snapshot-rootfs.tar.xz" "https://m.tmoe.me/show/share/Tmoe-linux/chroot/openwrt_arm64.tar.xz"
		fi
	fi
	touch ~/.ALPINELINUXDetectionFILE
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed 's/debian system/openwrt system/g' |
		sed 's:debian-sid:openwrt-snapshot:g' |
		sed 's:debian/sid:openwrt/snapshot:g' |
		sed 's:Debian GNU/Linux:OpenWRT Linux:g')"
}
######################
install_devuan_linux_distro() {
	DISTRO_NAME='devuan'
	DISTRO_CODE='ascii'
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
	if [ "${ARCH_TYPE}" = 'amd64' ]; then
		if [ ! -e "slackware-current-rootfs.tar.xz" ]; then
			aria2c -x 16 -s 16 -k 1M -o "slackware-current-rootfs.tar.xz" "https://cdn.tmoe.me/Tmoe-Debian-Tool/chroot/archive/slackware_amd64.tar.xz" || aria2c -x 16 -s 16 -k 1M -o "slackware-current-rootfs.tar.xz" "https://m.tmoe.me/down/share/Tmoe-linux/chroot/slackware_amd64.tar.xz"
		fi
	else
		if [ ! -e "slackware-current-rootfs.tar.xz" ]; then
			LatestSlack="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/slackwarearm/slackwarearm-devtools/minirootfs/roots/ | grep 'tar.xz' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			aria2c -x 5 -s 5 -k 1M -o "slackware-current-rootfs.tar.xz" "https://mirrors.tuna.tsinghua.edu.cn/slackwarearm/slackwarearm-devtools/minirootfs/roots/${LatestSlack}"
		fi
	fi
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed 's/debian system/slackware system/g' |
		sed 's:debian-sid:slackware-current:g' |
		sed 's:debian/sid:slackware/current:g' |
		sed 's:Debian GNU/Linux:Slackware GNU/Linux:g')"
}
#########################
install_armbian_linux_distro() {
	cd ${HOME}
	#touch .SLACKDetectionFILE
	if [ "${ARCH_TYPE}" != 'armhf' ] && [ "${ARCH_TYPE}" != 'arm64' ]; then
		if [ ! -e "/usr/bin/qemu-arm-static" ]; then
			apt update
			apt install qemu-user-static
		fi
	fi
	echo "armbian-bullseye-desktop已预装xfce4"
	if [ ! -e "armbian-bullseye-rootfs.tar.lz4" ]; then
		if [ "${ARCH_TYPE}" = 'armhf' ]; then
			LatestARMbian="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_rootfs/ | grep -E 'bullseye-desktop' | grep -v '.tar.lz4.asc' | grep 'armhf' | head -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			aria2c -x 5 -s 5 -k 1M -o "armbian-bullseye-rootfs.tar.lz4" "https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_rootfs/${LatestARMbian}"
		else
			LatestARMbian="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_rootfs/ | grep -E 'bullseye-desktop' | grep -v '.tar.lz4.asc' | grep 'arm64' | head -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			aria2c -x 5 -s 5 -k 1M -o "armbian-bullseye-rootfs.tar.lz4" "https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_rootfs/${LatestARMbian}"
		fi
	fi

	if [ ! -e "/usr/bin/lz4" ]; then
		apt update 2>/dev/null
		apt install -y lz4 2>/dev/null
		pacman -Syu --noconfirm lz4 2>/dev/null
		dnf install -y lz4 2>/dev/null
		zypper in -y lz4 2>/dev/null
	fi

	mkdir -p ${DEBIAN_CHROOT}
	rm -vf ~/armbian-bullseye-rootfs.tar
	lz4 -d ~/armbian-bullseye-rootfs.tar.lz4
	cd ${DEBIAN_CHROOT}
	if [ "${LINUX_DISTRO}" = "Android" ]; then
		pv ~/armbian-bullseye-rootfs.tar | proot --link2symlink tar -px
	else
		if [ -e "/usr/bin/pv" ]; then
			pv ~/armbian-bullseye-rootfs.tar | tar -px
		else
			tar -pxvf ~/armbian-bullseye-rootfs.tar
		fi
	fi
	#相对路径，不是绝对路径
	sed -i 's/^deb/#&/g' ./etc/apt/sources.list.d/armbian.list
	sed -i '$ a\deb http://mirrors.tuna.tsinghua.edu.cn/armbian/ bullseye main bullseye-utils bullseye-desktop' ./etc/apt/sources.list.d/armbian.list
	rm -vf ~/armbian-bullseye-rootfs.tar

	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/install.sh |
		sed 's/debian system/armbian system/g' |
		sed 's:debian-sid:armbian-bullseye:g' |
		sed 's:debian/sid:armbian/bullseye:g' |
		sed 's:rootfs.tar.xz:rootfs.tar.lz4:g' |
		sed 's:Debian GNU/Linux:Armbian GNU/Linux:g')"
}
#######################
install_mint_linux_distro() {
	if [ "${ARCH_TYPE}" = 'amd64' ] || [ "${ARCH_TYPE}" = 'i386' ]; then
		DISTRO_NAME='mint'
		OLD_STABLE_VERSION='tina'
		LXC_IMAGES_REPO="https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/${DISTRO_NAME}/"
		DISTRO_CODE=$(curl -sL ${LXC_IMAGES_REPO} | grep date | cut -d '=' -f 4 | cut -d '"' -f 2 | grep -Ev 'size|sarah|serena|sonya|sylvia|tara|tessa|tina' | tail -n 1)
		which_version_do_you_want_to_install
	else
		echo "${RED}WARNING！${RESET}检测到您使用的是${ARCH_TYPE}架构"
		echo "Linux Mint${RED}不支持${RESET}您的架构"
		echo "请换用${YELLOW}amd64${RESET}或${YELLOW}i386${RESET}设备后，再来尝试"
		press_enter_to_return
		install_beta_containers
	fi
}
######################
######################
gnu_linux_sources_list() {
	cp -pf /etc/apt/sources.list /etc/apt/sources.list.bak
	if grep -q 'Debian' "/etc/issue"; then
		if grep -q 'bullseye' "/etc/os-release"; then
			SOURCELISTCODE='sid'
			BACKPORTCODE='bullseye'
			echo "Debian 11 bullseye"

		elif grep -q 'buster' "/etc/os-release"; then
			SOURCELISTCODE='stable'
			BACKPORTCODE='bullseye'
			echo "Debian 10 buster"

		elif grep -q 'stretch' "/etc/os-release"; then
			SOURCELISTCODE='stretch'
			BACKPORTCODE='stretch'
			echo "Debian 9 stretch"

		elif grep -q 'jessie' "/etc/os-release"; then
			SOURCELISTCODE='jessie'
			BACKPORTCODE='jessie'
			echo "Debian 8 jessie"

		else
			echo '暂不支持您当前的系统版本'
			press_enter_to_return
			gnu_linux
		fi
		echo "检测到您使用的是Debian ${SOURCELISTCODE}系统"
		sed -i 's/^deb/# &/g' /etc/apt/sources.list
		if [ "${SOURCELISTCODE}" = "sid" ]; then
			cat >>/etc/apt/sources.list <<-"EndOfSourcesList"
				deb http://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
			EndOfSourcesList
		else
			#下面那行EndOfSourcesList不能加单引号
			cat >>/etc/apt/sources.list <<-EndOfSourcesList
				deb http://mirrors.tuna.tsinghua.edu.cn/debian/ ${SOURCELISTCODE} main contrib non-free
				deb http://mirrors.tuna.tsinghua.edu.cn/debian/ ${SOURCELISTCODE}-updates main contrib non-free
				deb http://mirrors.tuna.tsinghua.edu.cn/debian/ ${BACKPORTCODE}-backports main contrib non-free
				deb http://mirrors.tuna.tsinghua.edu.cn/debian-security ${SOURCELISTCODE}/updates main contrib non-free
			EndOfSourcesList

		fi
	fi
	###################
	if grep -q 'Kali' "/etc/issue"; then
		echo "检测到您使用的是Kali系统"
		sed -i 's/^deb/# &/g' /etc/apt/sources.list
		cat >>/etc/apt/sources.list <<-"EndOfSourcesList"
			deb http://mirrors.tuna.tsinghua.edu.cn/kali/ kali-rolling main contrib non-free
			deb http://mirrors.tuna.tsinghua.edu.cn/debian/ stable main contrib non-free
			# deb http://mirrors.tuna.tsinghua.edu.cn/kali/ kali-last-snapshot main contrib non-free
		EndOfSourcesList
		#注意：kali-rolling添加debian testing源后，可能会破坏系统依赖关系，可以添加stable源（暂未发现严重影响）
	fi
	#########################
	if grep -q 'Ubuntu' "/etc/issue"; then
		if grep -q 'Bionic Beaver' "/etc/os-release"; then
			SOURCELISTCODE='bionic'
			echo '18.04 LTS'
		elif grep -q 'Focal Fossa' "/etc/os-release"; then
			SOURCELISTCODE='focal'
			echo '20.04 LTS'
		elif grep -q 'Xenial' "/etc/os-release"; then
			SOURCELISTCODE='xenial'
			echo '16.04 LTS'
		elif grep -q 'Xenial' "/etc/os-release"; then
			SOURCELISTCODE='xenial'
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
			echo '暂不支持您当前的系统版本'
			press_enter_to_return
			gnu_linux
		fi
		echo "检测到您使用的是Ubuntu ${SOURCELISTCODE}系统"
		sed -i 's/^deb/# &/g' /etc/apt/sources.list
		#下面那行EndOfSourcesList不能有单引号
		cat >>/etc/apt/sources.list <<-EndOfSourcesList
			deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ ${SOURCELISTCODE} main restricted universe multiverse
			deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ ${SOURCELISTCODE}-updates main restricted universe multiverse
			deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ ${SOURCELISTCODE}-backports main restricted universe multiverse
			deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ ${SOURCELISTCODE}-security main restricted universe multiverse
			# 预发布软件源，不建议启用
			# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ ${SOURCELISTCODE}-proposed main restricted universe multiverse
		EndOfSourcesList
		if [ "${ARCH_TYPE}" != 'amd64' ] && [ "${ARCH_TYPE}" != 'i386' ]; then
			sed -i 's:/ubuntu:/ubuntu-ports:g' /etc/apt/sources.list
		fi
	fi
	#结束版本检测
	###################
	if [ -e "/usr/sbin/update-ca-certificates" ]; then
		echo "检测到您已安装ca-certificates"
		echo "Replacing http software source list with https."
		echo "正在将http源替换为https..."
		update-ca-certificates
		sed -i 's@http:@https:@g' /etc/apt/sources.list
	fi
	apt update
	apt dist-upgrade -y
	echo '修改完成，您当前的软件源列表如下所示。'
	cat /etc/apt/sources.list
	cat /etc/apt/sources.list.d/* 2>/dev/null
	echo "您可以输${YELLOW}apt edit-sources${RESET}来手动编辑软件源列表"
	press_enter_to_return
	gnu_linux
	#此处要返回依赖检测处！
}
####################
check_arch
##取消注释，测试用。
##tmoe_manager_main_menu
