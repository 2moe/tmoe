#!/data/data/com.termux/files/usr/bin/bash
########################################################################
#检测架构 CHECK architecture
CheckArch() {

	case $(uname -m) in
	aarch64)
		archtype="arm64"
		;;
	arm64)
		archtype="arm64"
		;;
	armv8a)
		archtype="arm64"
		;;
	arm)
		archtype="armhf"
		;;
	armv7l)
		archtype="armhf"
		;;
	armhf)
		archtype="armhf"
		;;
	armv6l)
		archtype="armel"
		;;
	armel)
		archtype="armel"
		;;
	amd64)
		archtype="amd64"
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
		#经测试uname -m输出的结果为s390x
		;;
	ppc*)
		archtype="ppc64el"
		#经测试uname -m输出的结果为ppc64le，而不是ppc64el
		;;
	mips*)
		archtype="mipsel"
		#echo -e 'Embedded devices such as routers are not supported at this time\n暂不支持mips架构的嵌入式设备'
		#20200323注：手动构建了mipsel架构的debian容器镜像，现在已经支持了。
		#经测试uname -m输出的结果为mips，而不是mipsel
		#exit 1
		;;
	risc*)
		archtype="riscv"
		#20200323注：riscv靠qemu实现跨cpu架构运行chroot容器
		#echo 'The RISC-V architecture you are using is too advanced and we do not support it yet.'
		#exit 1
		;;
	*)
		echo "未知的架构 $(uname -m) unknown architecture"
		exit 1
		;;
	esac
	DebianFolder=debian_${archtype}
	DebianCHROOT=${HOME}/${DebianFolder}
	YELLOW=$(printf '\033[33m')
	RESET=$(printf '\033[m')
	cur=$(pwd)
	ANDROIDVERSION=$(getprop ro.build.version.release 2>/dev/null) || ANDROIDVERSION=6
	autoCheck
}
#########################################################
autoCheck() {

	if [ "$(uname -o)" = "Android" ]; then
		LINUXDISTRO='Android'
		termux-setup-storage
		ANDROIDTERMUX
	elif [ "$(uname -v | cut -c 1-3)" = "iSH" ]; then
		LINUXDISTRO='iSH'
		if grep -q 'cdn.alpinelinux.org' "/etc/apk/repositories"; then
			sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g'
		fi
		GNULINUX
	else
		GNULINUX
	fi
	##当检测到ish后一定要加上GNULINUX，且不能在最后一个fi后添加。
}
########################################
GNULINUX() {

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
		LINUXDISTRO='debian'

	elif grep -Eq "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		LINUXDISTRO='openwrt'
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
		LINUXDISTRO='redhat'
		if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHATDISTRO='centos'
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHATDISTRO='fedora'
		fi

	elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" '/etc/os-release'; then
		LINUXDISTRO='alpine'

	elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
		LINUXDISTRO='arch'

	elif grep -Eq "gentoo|funtoo" '/etc/os-release'; then
		LINUXDISTRO='gentoo'

	elif grep -qi 'suse' '/etc/os-release'; then
		LINUXDISTRO='suse'

	elif [ "$(cat /etc/issue | cut -c 1-4)" = "Void" ]; then
		LINUXDISTRO='void'
	fi

	######################################
	dependencies=""

	if [ ! -e /usr/bin/aria2c ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} net-misc/aria2"
		else
			dependencies="${dependencies} aria2"
		fi
	fi

	if [ ! -e /bin/bash ]; then
		if [ "${LINUXDISTRO}" = "alpine" ] || [ "${LINUXDISTRO}" = "openwrt" ]; then
			dependencies="${dependencies} bash"
		fi
	fi

	if [ ! -e /usr/bin/curl ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} net-misc/curl"
		else
			dependencies="${dependencies} curl"
		fi
	fi

	#####################

	if [ ! -e /usr/bin/git ]; then
		if [ "${LINUXDISTRO}" = "openwrt" ]; then
			dependencies="${dependencies} git git-http"
		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} dev-vcs/git"
		else
			dependencies="${dependencies} git"
		fi
	fi

	if [ ! -e /bin/grep ] && [ ! -e /usr/bin/grep ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} sys-apps/grep"
		else
			dependencies="${dependencies} grep"
		fi
	fi
	########################
	if [ ! -e "/usr/bin/less" ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} sys-apps/less"
		else
			dependencies="${dependencies} less"
		fi
	fi

	if [ -L "/usr/bin/less" ]; then
		if [ "${LINUXDISTRO}" = "openwrt" ]; then
			dependencies="${dependencies} less"
		fi
	fi
	####################

	if [ ! -e /usr/bin/pv ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} sys-apps/pv"
		elif [ "${LINUXDISTRO}" = 'redhat' ]; then
			if [ "${REDHATDISTRO}" = 'fedora' ]; then
				dependencies="${dependencies} pv"
			fi
		else
			dependencies="${dependencies} pv"
		fi
	fi

	if [ ! -e /usr/bin/proot ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			dependencies="${dependencies} proot"
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
		if [ "${LINUXDISTRO}" = "debian" ]; then
			dependencies="${dependencies} sudo"
		fi
	fi
	#####################
	if [ ! -e /bin/tar ]; then
		if [ "${LINUXDISTRO}" = "gentoo" ]; then
			dependencies="${dependencies} app-arch/tar"
		else
			dependencies="${dependencies} tar"
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
	if [ "${archtype}" = "riscv" ]; then
		dependencies="${dependencies} qemu qemu-user-static debootstrap"
	fi
	##############
	if [ ! -z "${dependencies}" ]; then
		if [ "${LINUXDISTRO}" = "debian" ]; then
			if ! grep -q '^deb.*edu.cn' "/etc/apt/sources.list"; then
				echo "${YELLOW}检测到您当前使用的sources.list不是清华源,是否需要更换为清华源[Y/n]${RESET} "
				echo "更换后可以加快国内的下载速度,${YELLOW}按回车键确认，输n拒绝。${RESET}"
				echo "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .[Y/n]"
				read opt
				case $opt in
				y* | Y* | "")
					GNULINUXTUNASOURCESLIST
					;;
				n* | N*) echo "skipped." ;;
				*) echo "Invalid choice. skipped." ;;
				esac
			fi
		fi
		echo "正在安装相关依赖..."

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
			opkg install ${dependencies} || opkg install whiptail

		elif [ "${LINUXDISTRO}" = "gentoo" ]; then
			emerge -vk ${dependencies}

		elif [ "${LINUXDISTRO}" = "suse" ]; then
			zypper in -y ${dependencies}

		elif [ "${LINUXDISTRO}" = "void" ]; then
			xbps-install -S -y ${dependencies}

		else

			apt update
			apt install -y ${dependencies} || port install ${dependencies} || guix package -i ${dependencies} || pkg install ${dependencies} || pkg_add ${dependencies} || pkgutil -i ${dependencies}
		fi
	fi
	##################
	#解决乱码问题
	CurrentLANG=$LANG
	export LANG=$(echo 'emhfQ04uVVRGLTgK' | base64 -d)
	########################
	if [ "${LINUXDISTRO}" = "openwrt" ]; then
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
			if [ -e "${DebianCHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
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
					if [ ! -e "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO" ]; then
						echo "即将为您下载10.0.19041.172 iso镜像文件..."
						echo "目录C:\Users\Public\Downloads"
						aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO" 'https://cdn.tmoe.me/windows/20H1/19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO" 'https://m.tmoe.me/down/share/windows/20H1/19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO'
					fi
					/mnt/c/WINDOWS/system32/cmd.exe /c "start ."
					#下面那处需要再次if,而不是else
					if [ -e "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO" ]; then
						echo "正在校验sha256sum..."
						echo 'Verifying sha256sum ...'
						SHA256SUMDEBIAN="$(sha256sum '19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO' | cut -c 1-64)"
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
						/mnt/c/WINDOWS/explorer.exe '19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO'
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

	if [ ! -z "${LINUXDISTRO}" ]; then
		if grep -q 'PRETTY_NAME=' /etc/os-release; then
			OSRELEASE="$(cat /etc/os-release | grep 'PRETTY_NAME=' | head -n 1 | cut -d '=' -f 2)"
		else
			OSRELEASE="$(cat /etc/os-release | grep -v 'VERSION' | grep 'ID=' | head -n 1 | cut -d '=' -f 2)"
		fi

		if (whiptail --title "您想要对这个小可爱做什么 " --yes-button "Tool" --no-button "Manager" --yesno "检测到您使用的是${OSRELEASE} ${WSL}您是想要启动software安装工具，还是system管理工具？ ♪(^∇^*) " 10 50); then
			#bash <(curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian-gui-install.bash')
			curl -sLo /tmp/.debian-gui-install.bash 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian-gui-install.bash'
			bash /tmp/.debian-gui-install.bash
			exit 0
		fi
	fi

	MainMenu
}
########################################
ANDROIDTERMUX() {
	dependencies=""

	if [ ! -e ${PREFIX}/bin/pv ]; then
		dependencies="${dependencies} pv"
	fi

	if [ ! -e ${PREFIX}/bin/git ]; then
		dependencies="${dependencies} git"
	fi

	if [ ! -e ${PREFIX}/bin/termux-audio-info ]; then
		dependencies="${dependencies} termux-api"
	fi

	if [ ! -e ${PREFIX}/bin/pulseaudio ]; then
		dependencies="${dependencies} pulseaudio"
	fi

	if [ ! -e ${PREFIX}/bin/grep ]; then
		dependencies="${dependencies} grep"
	fi

	if [ ! -e ${PREFIX}/bin/aria2c ]; then
		dependencies="${dependencies} aria2"
	fi

	if [ ! -e ${PREFIX}/bin/proot ]; then
		dependencies="${dependencies} proot"
	fi

	if [ ! -e ${PREFIX}/bin/xz ]; then
		dependencies="${dependencies} xz-utils"
	fi

	if [ ! -e ${PREFIX}/bin/tar ]; then
		dependencies="${dependencies} tar"
	fi

	if [ ! -e ${PREFIX}/bin/whiptail ]; then
		dependencies="${dependencies} dialog"
	fi

	if [ ! -e ${PREFIX}/bin/pkill ]; then
		dependencies="${dependencies} procps"
	fi

	if [ ! -e ${PREFIX}/bin/curl ]; then
		dependencies="${dependencies} curl"
	fi

	if [ ! -z "${dependencies}" ]; then
		if (("${ANDROIDVERSION}" >= '7')); then
			if ! grep -q '^deb.*edu.cn.*termux-packages-24' '/data/data/com.termux/files/usr/etc/apt/sources.list'; then
				echo "${YELLOW}检测到您当前使用的sources.list不是清华源,是否需要更换为清华源[Y/n]${RESET} "
				echo "更换后可以加快国内的下载速度,${YELLOW}按回车键确认，输n拒绝。${RESET}"
				echo "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .[Y/n]"
				read opt
				case $opt in
				y* | Y* | "")
					TERMUXTUNASOURCESLIST
					;;
				n* | N*) echo "skipped." ;;
				*) echo "Invalid choice. skipped." ;;
				esac
			fi
		fi
		echo "正在安装相关依赖..."
		apt update
		apt install -y ${dependencies}
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

	if [ -e ${DebianCHROOT}/root/.vnc/xstartup ]; then
		grep -q "PULSE_SERVER" ${DebianCHROOT}/root/.vnc/xstartup || sed -i '2 a\export PULSE_SERVER=127.0.0.1' ${DebianCHROOT}/root/.vnc/xstartup
	fi

	if [ -e ${PREFIX}/bin/debian ]; then
		grep -q "pulseaudio" ${PREFIX}/bin/debian || sed -i '3 a\pulseaudio --start' ${PREFIX}/bin/debian
	fi

	MainMenu
}

########################################################################
#-- 主菜单 main menu

MainMenu() {
	OPTION=$(
		whiptail --title "Tmoe-Debian GNU/Linux manager(20200501-14)" --backtitle "$(
			base64 -d <<-'DoYouWantToSeeWhatIsInside'
				6L6TZGViaWFuLWnlkK/liqjmnKznqIvluo8sVHlwZSBkZWJpYW4taSB0byBzdGFydCB0aGUgdG9v
				bCzokIzns7vnlJ/niannoJTnqbblkZgK
			DoYouWantToSeeWhatIsInside
		)" --menu "Please use the enter and arrow keys to operate.当前主菜单下有十几个选项,请使用方向键和回车键进行操作" 15 60 4 \
			"1" "proot安装" \
			"2" "chroot安装" \
			"3" "GUI,audio & sources.list" \
			"4" "novnc(web端控制)" \
			"5" "remove system移除" \
			"6" "backup system备份系统" \
			"7" "restore还原" \
			"8" "query space occupation查询空间占用" \
			"9" "update更新" \
			"10" "Configure zsh" \
			"11" "Download VNC apk" \
			"12" "VSCode Server arm64" \
			"13" "赋予proot容器真实root权限" \
			"14" "Video tutorial" \
			"0" "exit退出" \
			3>&1 1>&2 2>&3
	)

	if [ "${OPTION}" == '1' ]; then
		if [ "$(uname -o)" != "Android" ]; then
			echo "非常抱歉，本功能仅适配安卓系统。"
			echo "Linux系统请换用chroot容器。"
			echo "Press enter to return."
			echo "${YELLOW}按回车键返回。${RESET} "
			read
			MainMenu

		fi
		rm -f ~/.Chroot-Container-Detection-File
		rm -f "${DebianCHROOT}/tmp/.Chroot-Container-Detection-File" 2>/dev/null
		touch ~/.Tmoe-Proot-Container-Detection-File
		installDebian

	fi

	if [ "${OPTION}" == '2' ]; then
		if [ "$(uname -o)" = "Android" ]; then
			su -c "ls ${HOME} >/dev/null"
			if [ "$?" != "0" ]; then
				echo '检测到root权限授予失败，您无法安装chroot容器'
				echo "${YELLOW}按回车键返回。${RESET}"
				echo "Press enter to return."
				read
				MainMenu
			else
				echo "检测到您使用的是Android系统"
				echo "您在安装chroot容器前必须知悉已挂载目录无法强制卸载的严重性！"
			fi
		fi
		CHROOTINSTALLDebian
	fi

	if [ "${OPTION}" == '3' ]; then

		TERMUXINSTALLXFCE
	fi
	if [ "${OPTION}" == '4' ]; then

		INSTALLWEBNOVNC
	fi

	if [ "${OPTION}" == '5' ]; then

		REMOVESYSTEM

	fi

	if [ "${OPTION}" == '6' ]; then

		BackupSystem

	fi

	if [ "${OPTION}" == '7' ]; then

		RESTORESYSTEM

	fi

	if [ "${OPTION}" == '8' ]; then

		SpaceOccupation

	fi

	if [ "${OPTION}" == '9' ]; then

		UPDATEMANAGER
	fi

	if [ "${OPTION}" == '10' ]; then
		bash -c "$(curl -fLsS 'https://gitee.com/mo2/zsh/raw/master/zsh.sh')"

	fi

	if [ "${OPTION}" == '11' ]; then

		DOWNLOADVNCAPK

	fi

	if [ "${OPTION}" == '12' ]; then
		STARTVSCODE

	fi

	if [ "${OPTION}" == '13' ]; then

		RootMode
	fi

	if [ "${OPTION}" == '14' ]; then

		DownloadVideoTutorial
	fi

	if [ "${OPTION}" == '0' ]; then
		exit

	fi

}

########################################################################

installDebian() {
	if [ -d ~/${DebianFolder} ]; then
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
				INSTALLDEBIANORDOWNLOADRECOVERYTARXZ
				;;
			n* | N*)
				echo "skipped."
				echo "Press enter to return."
				echo "${YELLOW}按回车键返回。${RESET} "
				read
				MainMenu
				;;
			*)
				echo "Invalid choice. skipped."
				echo "Press enter to return."
				echo "${YELLOW}按回车键返回。${RESET} "
				read
				MainMenu
				;;
			esac
		fi

	else
		INSTALLDEBIANORDOWNLOADRECOVERYTARXZ
		#bash -c "$(curl -fLsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh')"

	fi
}

########################################################################
#

RootMode() {
	if [ "$(uname -o)" != "Android" ]; then
		echo "非常抱歉，本功能仅适配安卓系统。"
		echo "chroot容器默认即为真实root权限。"
		echo "Press enter to return."
		echo "${YELLOW}按回车键返回。${RESET} "
		read
		MainMenu
	fi

	if (whiptail --title "您真的要开启root模式吗" --yes-button '好哒o(*￣▽￣*)o' --no-button '不要(っ °Д °；)っ' --yesno "开启后将无法撤销，除非重装容器，建议您在开启前进行备份。若您的手机存在外置tf卡，则在开启后，会挂载整张卡。若无法备份和还原，请输tsudo debian-i启动本管理器。开启root模式后，绝对不要输破坏系统的危险命令！若在容器内输rm -rf /*删除根目录（格式化）命令，将有可能导致安卓原系统崩溃！！！请在本管理器内正常移除容器。" 10 60); then

		if [ ! -f ${PREFIX}/bin/tsu ]; then
			apt update
			apt install -y tsu
		fi
		if ! grep -q 'pulseaudio --system' ${PREFIX}/bin/debian; then
			#sed -i '/pulseaudio/d' ${PREFIX}/bin/debian
			sed -i '4 c\pulseaudio --system --start' ${PREFIX}/bin/debian
		fi
		if ! grep -q 'tsudo touch' ${PREFIX}/bin/startvnc; then
			sed -i 's/^touch ~/tsudo &/' ${PREFIX}/bin/startvnc
			sed -i 's:/data/data/com.termux/files/usr/bin/debian:tsudo /data/data/com.termux/files/usr/bin/debian:' ${PREFIX}/bin/startvnc
		fi
		#上面那个是Termux专用的，勿改。

		mkdir -p /data/data/com.termux/files/usr/etc/storage/
		cd /data/data/com.termux/files/usr/etc/storage/

		rm -rf external-tf

		tsu -c 'ls /mnt/media_rw/*' 2>/dev/null || mkdir external-tf

		TFcardFolder=$(tsu -c 'ls /mnt/media_rw/| head -n 1')

		tsudo ln -s /mnt/media_rw/${TFcardFolder} ./external-tf

		sed -i 's:/home/storage/external-1:/usr/etc/storage/external-tf:g' ${PREFIX}/bin/debian

		cd ${PREFIX}/etc/
		if [ ! -f profile ]; then
			echo "" >>profile
		fi
		cp -pf profile profile.bak

		grep 'alias debian=' profile >/dev/null 2>&1 || sed -i '$ a\alias debian="tsudo debian"' profile
		grep 'alias debian-rm=' profile >/dev/null 2>&1 || sed -i '$ a\alias debian-rm="tsudo debian-rm"' profile

		source profile >/dev/null 2>&1
		alias debian="tsudo debian"
		alias debian-rm="tsudo debian-rm"
		echo "Modifying folder permissions"
		echo "正在修改文件权限..."
		tsudo chown root:root -R "${DebianCHROOT}" 2>/dev/null || su -c "chown root:root -R ${DebianCHROOT}"
		if [ -d "${HOME}/debian_armhf" ]; then
			tsudo chown root:root -R "${HOME}/debian_armhf" 2>/dev/null || su -c "chown root:root -R ${HOME}/debian_armhf"
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
		tsudo debian
		MainMenu
		#############
	else
		MainMenu
	fi
	#不要忘记此处的fi
}
########################################################################
#
REMOVESYSTEM() {

	cd ~
	if [ -e "${DebianCHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
		su -c "umount -lf ${DebianCHROOT}/dev >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/dev/shm  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/dev/pts  >/dev/null 2>&1"
		su -c "	umount -lf ${DebianCHROOT}/proc  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/sys  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/tmp  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/root/sd  >/dev/null 2>&1 "
		su -c "umount -lf ${DebianCHROOT}/root/tf  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/root/termux >/dev/null 2>&1"
		ls -lah ${DebianCHROOT}/dev 2>/dev/null
		ls -lah ${DebianCHROOT}/dev/shm 2>/dev/null
		ls -lah ${DebianCHROOT}/dev/pts 2>/dev/null
		ls -lah ${DebianCHROOT}/proc 2>/dev/null
		ls -lah ${DebianCHROOT}/sys 2>/dev/null
		ls -lah ${DebianCHROOT}/tmp 2>/dev/null
		ls -lah ${DebianCHROOT}/root/sd 2>/dev/null
		ls -lah ${DebianCHROOT}/root/tf 2>/dev/null
		ls -lah ${DebianCHROOT}/root/termux 2>/dev/null
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
	ls -l ${DebianCHROOT}/root/sd/*
	if [ "$?" = "0" ]; then
		echo 'WARNING！检测到/root/sd 无法强制卸载，您当前使用的可能是chroot容器'
		echo "若为误报，则请先停止容器进程，再手动移除${DebianCHROOT}/root/sd"
		echo '建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！'
		echo '为防止数据丢失，禁止移除容器！请重启设备后再重试。'
		echo "Press enter to return."
		echo "${YELLOW}按回车键返回。${RESET} "
		read
		MainMenu
	fi
	echo "若容器未停止运行，则建议你先手动在termux原系统中执行stopvnc，再进行移除操作。"
	echo 'Detecting container size... 正在检测容器占用空间大小'
	du -sh ./${DebianFolder} --exclude=./${DebianFolder}/root/tf --exclude=./${DebianFolder}/root/sd --exclude=./${DebianFolder}/root/termux
	if [ ! -d ~/${DebianFolder} ]; then
		echo "${YELLOW}Detected that you are not currently installed 检测到您当前未安装debian${RESET}"
	fi
	echo "${YELLOW}按回车键确认移除,按Ctrl+C取消 Press enter to confirm.${RESET} "
	read

	chmod 777 -R ${DebianFolder}
	rm -rfv "${DebianFolder}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code 2>/dev/null || tsudo rm -rfv "${DebianFolder}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code 2>/dev/null
	if [ -d "${HOME}/debian_armhf" ]; then
		echo "检测到疑似存在树莓派armhf系统，正在移除..."
		chmod 777 -R "${HOME}/debian_armhf"
		rm -rf "${HOME}/debian_armhf" 2>/dev/null || tsudo rm -rfv "${HOME}/debian_armhf"
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
	cd ~
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
	MainMenu

}
########################################################################
#
BackupSystem() {
	if [ -e "${DebianCHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
		su -c "umount -lf ${DebianCHROOT}/dev >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/dev/shm  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/dev/pts  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/proc  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/sys  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/tmp  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/root/sd  >/dev/null 2>&1 "
		su -c "umount -lf ${DebianCHROOT}/root/tf  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/root/termux >/dev/null 2>&1"
	fi
	OPTION=$(whiptail --title "Backup System" --menu "Choose your option" 15 60 4 \
		"0" "Back to the main menu 返回主菜单" \
		"1" "备份GNU/Linux容器" \
		"2" "备份Termux" \
		"3" "使用Timeshift备份宿主机系统" \
		3>&1 1>&2 2>&3)
	###########################################################################
	if [ "${OPTION}" == '1' ]; then
		if [ ! -d /sdcard/Download/backup ]; then
			mkdir -p /sdcard/Download/backup && cd /sdcard/Download/backup
		else
			cd /sdcard/Download/backup
		fi

		ls -lth ./debian*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'

		echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
		read

		echo $(date +%Y-%m-%d_%H-%M) >backuptime.tmp
		TMPtime=debian_$(cat backuptime.tmp)

		if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 12 50); then

			echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read
			tar -PJpcvf ${TMPtime}.tar.xz --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc
			#whiptail进度条已弃用
			#tar -PJpcf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} ${PREFIX}/bin/debian | (pv -n >${TMPtime}.tar.xz) 2>&1 | whiptail --gauge "Packaging into tar.xz" 10 70

			#xz -z -T0 -e -9 -f -v ${TMPtime}.tar
			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			pwd
			ls -lth ./*tar* | grep ^- | head -n 1
			echo '备份完成,按回车键返回。'
			read
			MainMenu

		else

			echo "您选择了tar.gz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.gz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read
			if [ ! -z "$(command -v pv)" ]; then
				tar -Ppczf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
			else
				tar -Ppczvf ${TMPtime}.tar.gz --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc
			fi
			#最新版弃用了whiptail的进度条！！！
			#tar -Ppczf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} ${PREFIX}/bin/debian | (pv -n >${TMPtime}.tar.gz) 2>&1 | whiptail --gauge "Packaging into tar.gz \n正在打包成tar.gz" 10 70

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0
			pwd
			ls -lth ./*tar* | grep ^- | head -n 1
			echo 'gzip压缩至60%完成是正常现象。'
			echo '备份完成,按回车键返回。'
			read
			MainMenu
		fi
	fi
	###################
	if [ "${OPTION}" == '2' ]; then
		BACKUPTERMUX

	fi
	###################
	if [ "${OPTION}" == '3' ]; then
		if [ "${LINUXDISTRO}" = "Android" ]; then
			echo 'Sorry,本功能不支持Android系统'
			echo "${YELLOW}按回车键返回。${RESET}"
			echo "Press enter to return."
			read
			MainMenu
		fi

		if [ ! -e "/usr/bin/timeshift" ]; then
			if [ "${LINUXDISTRO}" = "debian" ]; then
				apt update
				apt install -y timeshift
			elif [ "${LINUXDISTRO}" = "arch" ]; then
				pacman -Syu --noconfirm timeshift
			elif [ "${LINUXDISTRO}" = "redhat" ]; then
				dnf install timeshift
			fi
		fi

		if [ -e "/usr/bin/timeshift" ]; then
			timeshift-launcher &
			echo "安装完成，如需卸载，请手动输apt purge -y timeshift"
			echo "${YELLOW}按回车键返回。${RESET}"
			echo "Press enter to return."
			read
			BackupSystem
		fi
	fi
	##########################################
	if [ "${OPTION}" == '0' ]; then

		MainMenu
	fi
	MainMenu
}

BACKUPTERMUX() {
	TERMUXBACKUP=$(whiptail --title "多项选择题" --checklist \
		"您想要备份哪个目录？按空格键选择，*为选中状态，回车键确认 \n Which directory do you want to backup? Please press the space to select and press Enter to confirm." 15 60 4 \
		"home" "Termux主目录,主要用来保存用户文件" ON \
		"usr" "保存软件、命令和其它东西" OFF \
		3>&1 1>&2 2>&3)

	#####################################
	#$TERMUXBACKUP=$(whiptail --title "选择您需要备份的目录" --menu "Choose your $TERMUXBACKUP" 15 60 4 \
	#"0" "Back to previous menu 返回上层菜单" \
	#"1" "备份home目录" \
	#"2" "备份usr目录 " \
	#"3" "我全都要" \
	#3>&1 1>&2 2>&3)'
	##########################
	if [ "$TERMUXBACKUP" == 'home' ]; then

		if [ ! -d /sdcard/Download/backup ]; then
			mkdir -p /sdcard/Download/backup && cd /sdcard/Download/backup
		else
			cd /sdcard/Download/backup
		fi

		##tar -czf - ~/${DebianFolder} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

		ls -lth ./termux-home*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'

		#echo 'This operation will only backup the home directory of termux, not the container. If you need to backup debian, please select both options or backup debian separately.'
		#echo '本次操作将只备份termux的主目录，不包含主目录下的容器。如您需备份GNU/Linux容器,请同时选择home和usr，或单独备份GNU/Linux容器。'

		echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
		read

		echo $(date +%Y-%m-%d_%H-%M) >backuptime.tmp
		TMPtime=termux-home_$(cat backuptime.tmp)

		if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60); then

			echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read

			tar -PJpvcf ${TMPtime}.tar.xz --exclude=${DebianCHROOT}/root/sd --exclude=${DebianCHROOT}/root/termux --exclude=${DebianCHROOT}/root/tf ${HOME}

			#xz -z -T0 -e -9 -v ${TMPtime}.tar

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			pwd
			ls -lth ./termux-home*tar* | grep ^- | head -n 1
			echo '备份完成,按回车键返回。'
			read
			MainMenu

		else

			echo "您选择了tar.gz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.gz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read

			tar -Ppvczf ${TMPtime}.tar.gz --exclude=${DebianCHROOT}/root/sd --exclude=${DebianCHROOT}/root/termux --exclude=${DebianCHROOT}/root/tf ${HOME}

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0
			pwd
			ls -lth ./termux-home*tar* | grep ^- | head -n 1
			echo '备份完成,按回车键返回。'
			read
			MainMenu
		fi

	fi

	##########################
	if [ "$TERMUXBACKUP" == 'usr' ]; then

		if [ ! -d /sdcard/Download/backup ]; then
			mkdir -p /sdcard/Download/backup
		fi
		cd /sdcard/Download/backup

		ls -lth ./termux-usr*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'

		echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
		read

		echo $(date +%Y-%m-%d_%H-%M) >backuptime.tmp
		TMPtime=termux-usr_$(cat backuptime.tmp)

		if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60); then

			echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read

			#tar -PJpcf ${TMPtime}.tar /data/data/com.termux/files/usr
			echo '正在压缩成tar.xz'

			if [ ! -z "$(command -v pv)" ]; then
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
			ls -lth ./termux-usr*tar* | grep ^- | head -n 1
			echo '备份完成,按回车键返回。'
			read
			MainMenu

		else

			echo "您选择了tar.gz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.gz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read

			#tar -Ppczf ${TMPtime}.tar.gz   /data/data/com.termux/files/usr

			if [ ! -z "$(command -v pv)" ]; then
				tar -Ppczf - ${PREFIX} | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
			else
				tar -Ppczvf ${TMPtime}.tar.gz ${PREFIX}
			fi

			##tar -czf - ~/${DebianFolder} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0
			pwd
			ls -lth ./*tar* | grep ^- | head -n 1
			echo '备份完成,按回车键返回。'
			read
			MainMenu
		fi

	fi

	##########################
	if [ "$TERMUXBACKUP" == 'home usr' ]; then

		if [ ! -d /sdcard/Download/backup ]; then
			mkdir -p /sdcard/Download/backup && cd /sdcard/Download/backup
		else
			cd /sdcard/Download/backup
		fi

		ls -lth ./termux-home+usr*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'

		echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
		read

		echo $(date +%Y-%m-%d_%H-%M) >backuptime.tmp
		TMPtime=termux-home+usr_$(cat backuptime.tmp)

		if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ratio, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60); then
			echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read

			#tar -PJpcf ${TMPtime}.tar /data/data/com.termux/files/usr
			echo '正在压缩成tar.xz'
			if [ ! -z "$(command -v pv)" ]; then
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
			ls -lth ./termux-home+usr*tar* | grep ^- | head -n 1
			echo '备份完成,按回车键返回。'
			read
			MainMenu

		else

			echo "您选择了tar.gz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.gz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read

			#tar -Ppczf ${TMPtime}.tar.gz   /data/data/com.termux/files/usr
			if [ ! -z "$(command -v pv)" ]; then
				tar -Ppczf - ${HOME} ${PREFIX} | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
			else
				tar -Ppczvf ${TMPtime}.tar.gz ${HOME} ${PREFIX}
			fi
			##tar -czf - ~/${DebianFolder} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

			echo "Don't worry too much, it is normal for some directories to backup without permission."
			echo "部分目录无权限备份是正常现象。"
			rm -f backuptime.tmp
			#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0
			pwd
			ls -lth ./termux-home+usr*tar* | grep ^- | head -n 1
			echo '备份完成,按回车键返回。'
			read
			MainMenu
		fi

	fi

	################################
	if [ $exitstatus = 1 ]; then
		BackupSystem

	fi

}

########################################################################
#
RESTORESYSTEM() {
	if [ -e "${DebianCHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
		su -c "umount -lf ${DebianCHROOT}/dev >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/dev/shm  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/dev/pts  >/dev/null 2>&1"
		su -c "	umount -lf ${DebianCHROOT}/proc  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/sys  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/tmp  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/root/sd  >/dev/null 2>&1 "
		su -c "umount -lf ${DebianCHROOT}/root/tf  >/dev/null 2>&1"
		su -c "umount -lf ${DebianCHROOT}/root/termux >/dev/null 2>&1"
	fi
	OPTION=$(whiptail --title "Restore System" --menu "Choose your option" 15 60 4 \
		"0" "Back to the main menu 返回主菜单" \
		"1" "Restore the latest debian backup 还原GNU/Linux容器" \
		"2" "Restore the latest termux backup 还原Termux" \
		3>&1 1>&2 2>&3)
	###########################################################################
	if [ "${OPTION}" == '1' ]; then
		cd /sdcard/Download/backup
		ls -lth debian*tar* | head -n 10 2>/dev/null || echo '未检测到备份文件'

		echo '目前仅支持还原最新的备份，如需还原旧版，请手动输以下命令'

		echo 'cd /sdcard/Download/backup ;ls ; tar -JPxvf 文件名.tar.xz 或 tar -Pzxvf 文件名.tar.gz'
		echo '请注意大小写，并把文件名改成具体名称'

		RESTORE=$(ls -lth ./debian*tar* | grep ^- | head -n 1 | cut -d '/' -f 2)
		echo " "
		ls -lh ${RESTORE}
		printf "${YELLOW}即将为您还原${RESTORE}，请问是否确认？[Y/n]${RESET} "
		#printf之后分行
		echo ''
		echo 'Do you want to restore it?[Y/n]'

		read opt
		case $opt in
		y* | Y* | "")

			#0-6是截取字符
			if [ "${RESTORE:0-6:6}" == 'tar.xz' ]; then
				echo 'tar.xz'
				if [ ! -z "$(command -v pv)" ]; then
					pv ${RESTORE} | tar -PJx
				else
					tar -PpJxvf ${RESTORE}
				fi
			fi

			if [ "${RESTORE:0-6:6}" == 'tar.gz' ]; then
				echo 'tar.gz'
				if [ ! -z "$(command -v pv)" ]; then
					pv ${RESTORE} | tar -Pzx
				else
					tar -Ppzxvf ${RESTORE}
				fi
			fi

			;;

		\
			\
			n* | N*) echo "skipped." ;;
		*) echo "Invalid choice. skipped." ;;

			#tar xfv $pathTar -C $path
			#(pv -n $pathTar | tar xfv $pathTar -C $path ) 2>&1 | dialog --gauge "Extracting file..." 6 50

		esac

		echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
		read
		MainMenu

	fi

	###################
	if [ "${OPTION}" == '2' ]; then

		cd /sdcard/Download/backup
		ls -lth termux*tar* 2>/dev/null || echo '未检测到备份文件' | head -n 10

		echo '目前仅支持还原最新的备份，如需还原旧版，请手动输以下命令'

		echo 'cd /sdcard/Download/backup ;ls ; tar -JPxvf 文件名.tar.xz 或 tar -Pzxvf 文件名.tar.gz'
		echo '请注意大小写，并把文件名改成具体名称'

		RESTORE=$(ls -lth ./termux*tar* | grep ^- | head -n 1 | cut -d '/' -f 2)
		echo " "
		ls -lh ${RESTORE}
		printf "${YELLOW}即将为您还原${RESTORE}，请问是否确认？[Y/n]${RESET} "
		#printf之后分行
		echo ''
		echo 'Do you want to restore it?[Y/n]'

		read opt
		case $opt in
		y* | Y* | "")

			if [ "${RESTORE:0-6:6}" == 'tar.xz' ]; then
				echo 'tar.xz'
				if [ ! -z "$(command -v pv)" ]; then
					pv ${RESTORE} | tar -PJx
				else
					tar -PpJxvf ${RESTORE}
				fi
			fi

			if [ "${RESTORE:0-6:6}" == 'tar.gz' ]; then
				echo 'tar.gz'
				if [ ! -z "$(command -v pv)" ]; then
					pv ${RESTORE} | tar -Pzx
				else
					tar -Ppzxvf ${RESTORE}
				fi
			fi

			;;

		\
			\
			n* | N*) echo "skipped." ;;
		*) echo "Invalid choice. skipped." ;;

			#tar xfv $pathTar -C $path
			#(pv -n $pathTar | tar xfv $pathTar -C $path ) 2>&1 | dialog --gauge "Extracting file..." 6 50

		esac

		echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
		read
		MainMenu

	fi

	#####################################
	if [ "${OPTION}" == '0' ]; then

		MainMenu
	fi
	MainMenu
}

########################################################################
SpaceOccupation() {
	cd ~/..
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
		echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
		read
		SpaceOccupation

	fi
	###############################
	if [ "${OPTION}" == '2' ]; then
		echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
		echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
		echo "${YELLOW}termux 文件大小排行榜(30名)${RESET}"

		find ./ -type f -print0 2>/dev/null | xargs -0 du | sort -n | tail -30 | cut -f2 | xargs -I{} du -sh {}
		echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
		read
		SpaceOccupation

	fi

	if [ "${OPTION}" == '3' ]; then
		cd /sdcard
		echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
		echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
		echo "${YELLOW}sdcard 目录 TOP15${RESET}"
		du -hsx ./* ./.* 2>/dev/null | sort -rh | head -n 15

		echo "${YELLOW}sdcard文件大小排行榜(30名)${RESET}"

		find ./ -type f -print0 2>/dev/null | xargs -0 du | sort -n | tail -30 | cut -f2 | xargs -I{} du -sh {}

		echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
		read
		SpaceOccupation
	fi

	if [ "${OPTION}" == '4' ]; then
		echo "${YELLOW}Disk usage${RESET}"
		df -h | grep G | grep -v tmpfs
		echo "${YELLOW}按回车键返回。Press enter to return.${RESET} "
		read
		SpaceOccupation
	fi

	#####################################
	if [ "${OPTION}" == '0' ]; then

		MainMenu
	fi

	MainMenu

}

########################################################################
UPDATEMANAGER() {
	#curl -L -o ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh'
	aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh' || curl -Lo ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh' || sudo aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh'
	if [ "${LINUXDISTRO}" != "Android" ]; then
		sed -i '1 c\#!/bin/bash' ${PREFIX}/bin/debian-i
	fi

	echo "${YELLOW}更新完成，按回车键返回。${RESET}"
	echo 'Press enter to return.'
	chmod +x ${PREFIX}/bin/debian-i
	read
	#bash ${PREFIX}/bin/debian-i
	source ${PREFIX}/bin/debian-i

}
#################################
DOWNLOADVNCAPK() {
	if [ ! -e ${PREFIX}/bin/git ]; then
		apt update
		apt install -y git
	fi

	cd /sdcard/Download || mkdir -p /sdcard/Download && cd /sdcard/Download
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
#########################################
STARTVSCODE() {
	if [ "${archtype}" != 'arm64' ]; then
		echo "It is detected that your current architecture is not arm64, please install the server version yourself."
		echo "${YELLOW}按回车键返回。${RESET}"
		echo 'Press enter to return.'
		read
		MainMenu
	fi

	if [ ! -d "${HOME}/${DebianFolder}" ]; then
		echo "未检测到${DebianFolder},请先安装GNU/Linux容器"
		echo "Detected that you did not install ${DebianFolder}, please install container first."
		echo "${YELLOW}按回车键返回。${RESET}"
		echo 'Press enter to return.'
		read
		MainMenu
	fi

	if [ ! -e "${PREFIX}/bin/code-server" ]; then
		cat >${PREFIX}/bin/code-server <<-EndOfFile
			#!/data/data/com.termux/files/usr/bin/bash
			touch "${DebianCHROOT}/tmp/startcode.tmp"
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

	if [ ! -e "${DebianCHROOT}/tmp/sed-vscode.tmp" ]; then
		cat >${DebianCHROOT}/tmp/sed-vscode.tmp <<-'EOF'
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

	if [ ! -f "${DebianCHROOT}/root/.zshrc" ]; then
		echo "" >>${DebianCHROOT}/root/.zshrc
	fi
	if [ ! -f "${DebianCHROOT}/root/.bashrc" ]; then
		echo "" >>${DebianCHROOT}/root/.bashrc
	fi

	grep '/tmp/startcode.tmp' ${DebianCHROOT}/root/.bashrc >/dev/null || sed -i "$ r ${DebianCHROOT}/tmp/sed-vscode.tmp" ${DebianCHROOT}/root/.bashrc
	grep '/tmp/startcode.tmp' ${DebianCHROOT}/root/.zshrc >/dev/null || sed -i "$ r ${DebianCHROOT}/tmp/sed-vscode.tmp" ${DebianCHROOT}/root/.zshrc

	if [ -e "${DebianCHROOT}/usr/local/bin/code-server" ] || [ -L "${DebianCHROOT}/usr/local/bin/code-server" ]; then
		code-server
	else

		cd ${HOME}
		if [ -d ".VSCODESERVERTMPFILE" ]; then
			rm -rf .VSCODESERVERTMPFILE
		fi

		echo "server版商店中不包含所有插件，如需下载额外插件，请前往微软vscode官方在线商店下载vsix后缀的离线插件，并手动安装。 https://marketplace.visualstudio.com/vscode"
		git clone -b aarch64 --depth=1 https://gitee.com/mo2/vscode-server.git .VSCODESERVERTMPFILE
		cd ${DebianCHROOT}
		tar -Jpxvf ${HOME}/.VSCODESERVERTMPFILE/code.tar.xz
		rm -rf ${HOME}/.VSCODESERVERTMPFILE
		echo "Congratulations, you have successfully installed vscode server!"
		echo "您已成功安装VSCode服务，如需卸载请输rm -rf ${PREFIX}/bin/code-server ${DebianCHROOT}/usr/local/bin/code-server ${DebianCHROOT}/usr/local/bin/code-server-data"

		grep "keyCode" ${DebianCHROOT}/root/.local/share/code-server/User/settings.json >/dev/null || mkdir -p ${DebianCHROOT}/root/.local/share/code-server/User && cat >${DebianCHROOT}/root/.local/share/code-server/User/settings.json <<-'EndOfFile'
			{
			"keyboard.dispatch": "keyCode"
			}
		EndOfFile

		code-server
	fi

}
#####################################
DownloadVideoTutorial() {
	cd /sdcard/Download
	if [ -f "20200229vnc教程06.mp4" ]; then

		if (whiptail --title "检测到视频已下载,请选择您需要执行的操作！" --yes-button 'Play播放o(*￣▽￣*)o' --no-button '重新下载(っ °Д °)' --yesno "Detected that the video has been downloaded, do you want to play it, or download it again?" 7 60); then
			PLAYVideoTutorial
		else
			DOWNLOADVideoTutorialAGAIN
		fi
	else
		DOWNLOADVideoTutorialAGAIN

	fi

}

##########################
DOWNLOADVideoTutorialAGAIN() {
	aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "20200229vnc教程06.mp4" 'https://cdn.tmoe.me/Tmoe-Debian-Tool/20200229VNC%E6%95%99%E7%A8%8B06.mp4' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "20200229vnc教程06.mp4" 'https://m.tmoe.me/down/share/videos/20200229vnc%E6%95%99%E7%A8%8B06.mp4' || curl -Lo "20200229vnc教程06.mp4" 'https://cdn.tmoe.me/Tmoe-Debian-Tool/20200229VNC%E6%95%99%E7%A8%8B06.mp4'
	PLAYVideoTutorial
}
PLAYVideoTutorial() {
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
CHROOTINSTALLDebian() {
	echo "This feature currently only supports Linux systems and is still in beta."
	echo "本功能目前仅对Linux系统测试开放。"
	echo "This feature is currently in the beta stage. If you find that some directories cannot be unmounted forcibly before removing the container, please restart your device before uninstalling the chroot container to prevent the mounted directory from being deleted by mistake."
	echo "本功能目前仍处于测试阶段，移除容器前若发现部分已挂载目录无法强制卸载，请重启设备再卸载chroot容器，防止已挂载目录被误删！"
	echo "按回车键继续,按Ctrl+C取消。"
	echo "${YELLOW}Press enter to continue.${RESET}"
	read
	rm -f "${DebianCHROOT}/tmp/.Tmoe-Proot-Container-Detection-File" 2>/dev/null
	rm -f ~/.Tmoe-Proot-Container-Detection-File 2>/dev/null
	touch ~/.Chroot-Container-Detection-File
	installDebian
}
#################################
INSTALLDEBIANORDOWNLOADRECOVERYTARXZ() {
	if [ ! -d "${DebianCHROOT}" ]; then
		less -meQ <<-'EndOfFile'
			                              End-user license agreement 
						   Tmoe-linux Tool（以下简称“本工具”）尊重并保护所有使用服务的用户的个人隐私权。
						本工具遵循GNU General Public License v2.0 （开源许可协议）,旨在追求开放和自由。
						由于恢复包未存储于git仓库，而存储于天萌网盘，故您必须承担并知悉其中的风险。
						强烈建议您选择更为安全的安装方式，即从软件源镜像站下载容器镜像，再自行选择安装内容。
						本工具的开发者郑重承诺：恢复包内的系统不会使用和披露您的个人信息，也不存在任何侵害您个人隐私的行为。
						本工具会不时更新本协议，您在同意本工具服务使用协议之时，即视为您已经同意本协议全部内容。本协议属于本工具服务使用协议不可分割的一部分。
						This tool will update this agreement from time to time. When you agree to this tool service use agreement, you are deemed to have agreed to the entire contents of this agreement. This agreement is an integral part of the tool service agreement.

						1.禁止条例
						(a)禁止将本工具安装的GNU/Linux用于违法行为，例如：网络渗透、社会工程、域名未备案私自设立商用web服务等。
						Do not use GNU/Linux installed by this tool for illegal behavior!

						2. 适用范围
						(a)在您使用本工具时，通过天萌网盘下载的恢复包系统；
						(b)在您使用本工具时，通过清华镜像站安装的基础系统。
						您了解并同意，以下信息不适用本许可协议：
						(a)您在本工具的相关网站发布的有关信息数据，包括但不限于参与活动、点赞信息及评价详情；
						(b)违反法律规定或违反本工具规则行为及本工具已对您采取的措施。

						3. 信息使用
						(a)本工具不会收集或向任何无关第三方提供、出售、出租、分享或交易您的个人信息。
						This tool will not collect or provide, sell, rent, share or trade your personal information to an unrelated third party.
						(b)本工具亦不允许任何第三方以任何手段收集、编辑、出售或者无偿传播您的个人信息。
						                 
						4.下载说明
						(a)天萌网盘内的文件有可能由于网站被黑、文件失效、文件被替换、网站服务器出错等原因而导致下载出错或下载内容被劫持,故本工具在解压前会自动校验文件的sha256哈希值。
						(b)强烈建议您选择更为安全的安装方式，即从软件源镜像站下载容器镜像，再自行选择安装内容。

						5. 恢复包的使用
						(a)在您未拒绝接受恢复包的情况下，本工具会将恢复包下载至内置存储设备，并将其解压出来，以便您能快速安装并使用Debian GNU/Linux的图形桌面环境。本工具下载的恢复包不会为您提供个性化服务，您需要自行安装、配置第三方软件和主题美化。
						(b)您有权选择接受或拒绝使用恢复包或本工具。

						6. 信息安全
						(a)本工具安装的是原生GNU/Linux 系统，截至2020-03-12，默认没有开启安全保护和防火墙功能，请您妥善保管root密码及其它重要账号信息。
						同时希望您能注意在信息网络上不存在“绝对完善的安全措施”。

						7.其它说明
						(a)若您需要在开源项目中引用本脚本，建议您先与原开发者联系，若无法联系，则只需附上本git-repo的链接gitee.com/mo2/linux
						If you want to reference this script in an open source project,it is recommended that you contact the original developer.If you can't contact the developer, just attach the github link: https://github.com/2moe/tmoe-linux

						8.最终用户许可协议的更改
						(a)如果决定更改最终用户许可协议，我们会在本协议中、本工具网站中以及我们认为适当的位置发布这些更改，以便您了解如何保障我们双方的权益。
						(b)本工具开发者保留随时修改本协议的权利，因此请经常查看。 
						The developer of this tool reserves the right to modify this agreement at any time.
		EndOfFile
		echo 'You must agree to EULA to use this tool.'
		echo 'Press Enter to agree, otherwise press Ctrl + C or close the terminal directly.'
		echo "${YELLOW}按回车键同意《最终用户许可协议》，否则请按Ctrl+C或直接关闭终端。${RESET} "
		#if [ "${LINUXDISTRO}" != 'Android' ]; then
		#export LANG=${CurrentLANG}
		#fi
		read
	fi
	CHOOSEWHICHGNULINUX
}

###################################################
DOWNLOADDEBIANXFCETARXZ() {
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
	UNXZDEBIANRECOVERYKIT

}
#####################################
UNXZDEBIANRECOVERYKIT() {
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
TERMUXINSTALLXFCE() {
	if [ "${LINUXDISTRO}" = 'Android' ]; then
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
		MainMenu
	fi
	#####################################
	if [ "${OPTION}" == '1' ]; then
		if [ "${LINUXDISTRO}" != 'Android' ]; then
			bash -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian-gui-install.bash)"
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
		if [ "${LINUXDISTRO}" != 'Android' ]; then
			bash -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian-gui-install.bash)"
			exit 0
		fi
		MODIFYANDROIDTERMUXVNCCONF
	fi
	##################
	if [ "${OPTION}" == '3' ]; then
		TERMUXPULSEAUDIOLAN
	fi
	##################
	if [ "${OPTION}" == '4' ]; then
		SWITCHvncPULSEaudio
	fi
	##################
	if [ "${OPTION}" == '7' ]; then
		if [ "${LINUXDISTRO}" != 'Android' ]; then
			bash -c "$(curl -LfsS https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian-gui-install.bash)"
			exit 0
		fi
		REMOVEANDROIDTERMUXXFCE
	fi
	##################
	if [ "${OPTION}" == '5' ]; then
		if [ "${LINUXDISTRO}" = 'Android' ]; then
			TERMUXTUNASOURCESLIST
		else
			GNULINUXTUNASOURCESLIST
		fi
	fi
	##################
	if [ "${OPTION}" == '6' ]; then
		ARIA2CDOWNLOADTERMUXAPK
	fi
}
#####################################
SWITCHvncPULSEaudio() {
	cd ${DebianCHROOT}/root
	if grep -Eq '4712|4713' ./.vnc/xstartup; then
		PULSEtransportMethon='检测到您当前使用的可能是XSDL音频传输'
	else
		PULSEtransportMethon='检测到您当前使用的是termux音频传输'
	fi

	if (whiptail --title "您想用哪个软件来传输VNC音频？(｡･∀･)ﾉﾞ" --yes-button 'Termux(*￣▽￣*)o' --no-button 'XSDL(っ °Д °)' --yesno "${PULSEtransportMethon},请选择您需要切换的传输类型！注：您必须先安装XSDL app才能使用XSDL的音频服务，切换成XSDL后，启动VNC时将自动打开XSDL,此时不会转发X,您也无需执行任何操作。" 11 50); then

		sed -i 's/^export.*PULSE.*/export PULSE_SERVER=127.0.0.1/' ${DebianCHROOT}/root/.vnc/xstartup || echo "没有找到vnc xstartup呢！请确保您已安装gui"
		sed -i '/x.org.server.MainActivity/d' $PREFIX/bin/startvnc
		sed -i '/sleep 5/d' $PREFIX/bin/startvnc
	else
		sed -i 's/^export.*PULSE.*/export PULSE_SERVER=127.0.0.1:4713/' ${DebianCHROOT}/root/.vnc/xstartup || echo "没有找到vnc xstartup呢！请确保您已安装gui"
		cd $PREFIX/bin/
		grep -q 'x.org.server' startvnc || sed -i '2 a\am start -n x.org.server/x.org.server.MainActivity \nsleep 5' startvnc
	fi
	echo "修改完成！(￣▽￣),您需要输startvnc来启动vnc"
	echo 'press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	TERMUXINSTALLXFCE
}
###############################
TERMUXPULSEAUDIOLAN() {
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
	echo 'press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	TERMUXINSTALLXFCE
}
#############################
ARIA2CDOWNLOADTERMUXAPK() {
	cd /sdcard/Download
	if [ -f "com.termux_Fdroid.apk" ]; then

		if (whiptail --title "检测到文件已下载,请选择您需要执行的操作！" --yes-button 'install(*￣▽￣*)o' --no-button 'Download again(っ °Д °)' --yesno "Detected that the file has been downloaded, do you want to install it, or download it again?" 7 60); then
			INSTALLTERMUXAPK
		else
			DOWNLOADTERMUXAPKAGAIN
		fi
	else
		DOWNLOADTERMUXAPKAGAIN

	fi
	echo 'press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	MainMenu
}
#######################################
DOWNLOADTERMUXAPKAGAIN() {
	echo 'Press enter to start the download, and press Ctrl + C to cancel.'
	echo "${YELLOW}按回车键开始下载，按Ctrl+C取消。${RESET}"
	read
	echo 'Downloading termux apk...'
	echo '正在为您下载至/sdcard/Download目录...'
	echo '下载完成后，需要您手动安装。'
	aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "com.termux_Fdroid.apk" 'https://apk.tmoe.me/termux' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "com.termux_Fdroid.apk" 'https://mirrors.tuna.tsinghua.edu.cn/fdroid/repo/com.termux_94.apk'
	INSTALLTERMUXAPK
}
INSTALLTERMUXAPK() {
	echo "${YELLOW}下载完成，请进入下载目录手动安装。${RESET}"
	am start -n com.android.documentsui/com.android.documentsui.ViewDownloadsActivity
	cd ${cur}
}

##################################
INSTALLWEBNOVNC() {
	if [ "${LINUXDISTRO}" = 'Android' ]; then
		if [ ! -e "${PREFIX}/bin/python" ]; then
			apt update
			apt install -y python
		fi
	elif [ "${LINUXDISTRO}" = 'debian' ]; then
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
	STARTWEBNOVNC
}
#######################
STARTWEBNOVNC() {
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
	if [ "${LINUXDISTRO}" = 'Android' ]; then
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
	if [ -d "${DebianCHROOT}" ]; then
		touch ~/${DebianFolder}/root/.vnc/startvnc
		${PREFIX}/bin/debian
	else
		if [ "${LINUXDISTRO}" = 'Android' ]; then
			${PREFIX}/bin/startvnc
		else
			bash -c "$(sed 's:^export HOME=.*:export HOME=/root:' $(command -v startvnc))"
		fi
	fi
	#注：必须要先启动novnc后，才能接着启动VNC。
	#否则将导致安卓proot容器提前启动。
}

#################
MODIFYANDROIDTERMUXVNCCONF() {
	if [ ! -e ${PREFIX}/bin/startvnc ]; then
		echo "${PREFIX}/bin/startvnc is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startvnc,您可能尚未安装图形桌面，是否继续编辑?'
		echo "Press Enter to confirm."
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		read
	fi
	CURRENTTERMUXVNCRES=$(sed -n 7p "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
	if (whiptail --title "modify vnc configuration" --yes-button '分辨率resolution' --no-button '其它other' --yesno "您想要修改哪些配置信息？What configuration do you want to modify?" 9 50); then
		if grep -q 'debian_' "$(command -v startvnc)"; then
			echo "您当前使用的startvnc配置为Linux容器系统专用版，请输debian进入容器后再输debian-i修改"
			echo "本选项仅适用于termux原系统。"
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			MainMenu
		fi
		TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,1440x720,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为720x1440,当前为${CURRENTTERMUXVNCRES}。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
		#此处termux的whiptail跟debian不同，必须截取Error前的字符。
		TRUETARGET="$(echo ${TARGET} | cut -d 'E' -f 1)"
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
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	MainMenu

}
###############
REMOVEANDROIDTERMUXXFCE() {
	echo "${YELLOW}按回车键确认卸载,按Ctrl+C取消${RESET} "
	echo 'Press enter to confirm ,press Ctrl + C to cancel'
	read
	apt purge -y ^xfce tigervnc aterm
	apt purge -y x11-repo
	apt autoremove
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	MainMenu

}
#################
TERMUXTUNASOURCESLIST() {
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
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	ANDROIDTERMUX
	#此处要返回依赖检测处！

}
##################
CHOOSEWHICHGNULINUX() {
	SELECTGNULINUX=$(whiptail --title "GNU/Linux distros" --menu "Which distribution do you want to install? 您想要安装哪个GNU/Linux发行版?" 15 50 6 \
		"1" "Debian:最早的发行版之一" \
		"2" "Ubuntu 20.04:我的存在是因為大家的存在" \
		"3" "Kali Rolling:设计用于数字取证和渗透测试" \
		"4" "Other其它系统(公测版新功能):mint,centos" \
		"5" "fedora 31(红帽社区版,新技术试验场)" \
		"6" "arch(系统设计以KISS为总体指导原则)" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)

	##############################
	if [ "${SELECTGNULINUX}" == '0' ]; then
		MainMenu
	fi
	#########################
	if [ "${SELECTGNULINUX}" == '1' ]; then

		INSTALLDEBIANGNULINUXDISTRO
	fi
	##############################
	if [ "${SELECTGNULINUX}" == '2' ]; then
		INSTALLUBUNTUDISTRO2004
	fi
	##############################
	if [ "${SELECTGNULINUX}" == '3' ]; then
		INSTALLKALIROLLING
	fi
	##############################
	if [ "${SELECTGNULINUX}" == '4' ]; then
		INSTALLotherSystems
	fi
	##############################
	if [ "${SELECTGNULINUX}" == '5' ]; then
		touch ~/.REDHATDetectionFILE
		if [ "${archtype}" = 'armhf' ]; then
			echo "检测到您使用的是armhf架构，将为您降级至Fedora 29"
			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed 's/debian系统/fedora系统/g' |
				sed 's/debian system/fedora system/g' |
				sed 's:debian-sid:fedora-29:g' |
				sed 's:debian/sid:fedora/29:g' |
				sed 's:Debian GNU/Linux:Fedora GNU/Linux:g')"
		elif [ "${archtype}" = 'i386' ]; then
			echo "Fedora不支持您的架构"
		else
			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed 's/debian系统/fedora系统/g' |
				sed 's/debian system/fedora system/g' |
				sed 's:debian-sid:fedora-31:g' |
				sed 's:debian/sid:fedora/31:g' |
				sed 's:Debian GNU/Linux:Fedora GNU/Linux:g')"
		fi
	fi
	##############################
	if [ "${SELECTGNULINUX}" == '6' ]; then
		if [ "${archtype}" = 'armhf' ] || [ "${archtype}" = 'i386' ]; then
			echo "检测到Arch Linux不支持您当前的架构"
		else
			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed 's/debian系统/arch系统/g' |
				sed 's/debian system/arch system/g' |
				sed 's:debian-sid:archlinux-current:g' |
				sed 's:debian/sid:archlinux/current:g' |
				sed 's:Debian GNU/Linux:Arch GNU/Linux:g')"
		fi
	fi
	####################

	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	MainMenu
}
##############################
INSTALLotherSystems() {
	BETASYSTEM=$(
		whiptail --title "Beta features" --menu "WARNING！本功能仍处于测试阶段,可能无法正常运行。\nBeta features may not work properly." 17 55 7 \
			"1" "Funtoo:专注于改进Gentoo" \
			"2" "Void:基于xbps包管理器的独立发行版" \
			"3" "centos 8(基于红帽的社区企业操作系统)" \
			"4" "gentoo(追求极限配置和极高自由,armhf,x86,x64)" \
			"5" "alpine edge(非glibc的精简系统)" \
			"6" "opensuse tumbleweed(小蜥蜴风滚草)" \
			"7" "raspbian樹莓派 buster(armhf)" \
			"8" "mint tricia(简单易用的系统,x86,x64)" \
			"9" "openwrt(常见于路由器,arm64,x64)" \
			"10" "devuan ascii(不使用systemd,基于debian)" \
			"11" "apertis 18.12" \
			"12" "alt p9" \
			"13" "slackware(armhf,x64)" \
			"14" "armbian bullseye(arm64,armhf)" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${BETASYSTEM}" == '0' ]; then
		MainMenu
	fi
	####################

	if [ "${BETASYSTEM}" == '1' ]; then
		INSTALLFuntooDISTRO
	fi
	#############################
	if [ "${BETASYSTEM}" == '2' ]; then
		INSTALLVOIDLINUXDISTRO
	fi
	####################
	if [ "${BETASYSTEM}" == '3' ]; then
		touch ~/.REDHATDetectionFILE
		if [ "${archtype}" = 'armhf' ] || [ "${archtype}" = 'i386' ]; then
			echo "检测到CentOS 8不支持您当前的架构，将为您降级至CentOS 7"
			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed 's/debian系统/centos系统/g' |
				sed 's/debian system/centos system/g' |
				sed 's:debian-sid:centos-7:g' |
				sed 's:debian/sid:centos/7:g' |
				sed 's:Debian GNU/Linux:CentOS GNU/Linux:g')"
		else
			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed 's/debian系统/centos系统/g' |
				sed 's/debian system/centos system/g' |
				sed 's:debian-sid:centos-8:g' |
				sed 's:debian/sid:centos/8:g' |
				sed 's:Debian GNU/Linux:CentOS GNU/Linux:g')"
		fi
	fi
	####################
	if [ "${BETASYSTEM}" == '4' ]; then
		if [ "${archtype}" = 'arm64' ]; then
			echo "检测到您当前使用的是arm64架构，将为您下载armhf版容器"
			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed '72 a\archtype="armhf"' |
				sed 's/debian系统/gentoo系统/g' |
				sed 's/debian system/gentoo system/g' |
				sed 's:debian-sid:gentoo-current:g' |
				sed 's:debian/sid:gentoo/current:g' |
				sed 's:Debian GNU/Linux:Gentoo GNU/Linux:g')"
		else
			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed 's/debian系统/gentoo系统/g' |
				sed 's/debian system/gentoo system/g' |
				sed 's:debian-sid:gentoo-current:g' |
				sed 's:debian/sid:gentoo/current:g' |
				sed 's:Debian GNU/Linux:Gentoo GNU/Linux:g')"
		fi
	fi

	####################
	if [ "${BETASYSTEM}" == '5' ]; then
		touch ~/.ALPINELINUXDetectionFILE
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
			sed 's/debian系统/alpine系统/g' |
			sed 's/debian system/alpine system/g' |
			sed 's:debian-sid:alpine-edge:g' |
			sed 's:debian/sid:alpine/edge:g' |
			sed 's:Debian GNU/Linux:Alpine Linux:g')"
	fi
	####################
	if [ "${BETASYSTEM}" == '6' ]; then
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
			sed 's/debian系统/opensuse系统/g' |
			sed 's/debian system/opensuse system/g' |
			sed 's:debian-sid:opensuse-tumbleweed:g' |
			sed 's:debian/sid:opensuse/tumbleweed:g' |
			sed 's:Debian GNU/Linux:Opensuse GNU/Linux:g')"
	fi

	####################
	if [ "${BETASYSTEM}" == '7' ]; then
		if [ "${archtype}" != 'arm64' ] && [ "${archtype}" != 'armhf' ]; then
			apt install -y qemu qemu-user-static debootstrap
		fi
		touch ~/.RASPBIANARMHFDetectionFILE
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
			sed '72 a\archtype="armhf"' |
			sed 's:/sid:/buster:g' |
			sed 's:extract z:extract:' |
			sed 's@#deb http@deb http@g' |
			sed 's/.*sid main/#&/' |
			sed 's/debian系统/raspbian系统/g' |
			sed 's/debian system/raspbian system/g' |
			sed 's:debian-sid:raspbian-buster:g' |
			sed 's:debian/sid:debian/buster:g' |
			sed 's:Debian GNU/Linux:Raspbian GNU/Linux:g')"
	fi
	#先下载debian buster容器镜像，再换源成树莓派。
	####################
	if [ "${BETASYSTEM}" == '8' ]; then
		if [ "${archtype}" = 'amd64' ] || [ "${archtype}" = 'i386' ]; then

			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed 's/debian系统/mint系统/g' |
				sed 's/debian system/mint system/g' |
				sed 's:debian-sid:mint-tricia:g' |
				sed 's:debian/sid:mint/tricia:g' |
				sed 's:Debian GNU/Linux:Mint GNU/Linux:g')"
		else
			echo "Linux Mint不支持您的架构"
		fi
	fi

	####################
	if [ "${BETASYSTEM}" == '9' ]; then
		if [ ! -e "openwrt-snapshot-rootfs.tar.xz" ]; then
			cd ~
			if [ "${archtype}" = 'arm64' ]; then
				aria2c -x 16 -s 16 -k 1M -o "openwrt-snapshot-rootfs.tar.xz" "https://cdn.tmoe.me/Tmoe-Debian-Tool/chroot/archive/openwrt_arm64.tar.xz" || aria2c -x 16 -s 16 -k 1M -o "openwrt-snapshot-rootfs.tar.xz" "https://m.tmoe.me/show/share/Tmoe-linux/chroot/openwrt_arm64.tar.xz"
			fi
		fi
		touch ~/.ALPINELINUXDetectionFILE
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
			sed 's/debian系统/openwrt系统/g' |
			sed 's/debian system/openwrt system/g' |
			sed 's:debian-sid:openwrt-snapshot:g' |
			sed 's:debian/sid:openwrt/snapshot:g' |
			sed 's:Debian GNU/Linux:OpenWRT Linux:g')"
	fi
	####################
	if [ "${BETASYSTEM}" == '10' ]; then
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
			sed 's/debian系统/devuan系统/g' |
			sed 's/debian system/devuan system/g' |
			sed 's:debian-sid:devuan-ascii:g' |
			sed 's:debian/sid:devuan/ascii:g' |
			sed 's:Debian GNU/Linux:Devuan GNU/Linux:g')"
	fi
	####################
	if [ "${BETASYSTEM}" == '11' ]; then
		if [ "${archtype}" = 'armhf' ] || [ "${archtype}" = 'i386' ]; then
			echo "检测到apertis不支持您当前的架构"
		else
			touch ~/.ALPINELINUXDetectionFILE
			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed 's/debian系统/apertis系统/g' |
				sed 's/debian system/apertis system/g' |
				sed 's:debian-sid:apertis-18.12:g' |
				sed 's:debian/sid:apertis/18.12:g' |
				sed 's:Debian GNU/Linux:Apertis Linux:g')"
		fi
	fi
	####################
	if [ "${BETASYSTEM}" == '12' ]; then
		if [ "${archtype}" = 'armhf' ]; then
			echo "检测到alt不支持您当前的架构"
		else
			bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
				sed 's/debian系统/alt系统/g' |
				sed 's/debian system/alt system/g' |
				sed 's:debian-sid:alt-p9:g' |
				sed 's:debian/sid:alt/p9:g' |
				sed 's:Debian GNU/Linux:Alt GNU/Linux:g')"
		fi
	fi
	###########################
	if [ "${BETASYSTEM}" == '13' ]; then
		cd ~
		#touch .SLACKDetectionFILE
		if [ "${archtype}" = 'amd64' ]; then
			if [ ! -e "slackware-current-rootfs.tar.xz" ]; then
				aria2c -x 16 -s 16 -k 1M -o "slackware-current-rootfs.tar.xz" "https://cdn.tmoe.me/Tmoe-Debian-Tool/chroot/archive/slackware_amd64.tar.xz" || aria2c -x 16 -s 16 -k 1M -o "slackware-current-rootfs.tar.xz" "https://m.tmoe.me/down/share/Tmoe-linux/chroot/slackware_amd64.tar.xz"
			fi
		else

			if [ ! -e "slackware-current-rootfs.tar.xz" ]; then
				LatestSlack="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/slackwarearm/slackwarearm-devtools/minirootfs/roots/ | grep 'tar.xz' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
				aria2c -x 5 -s 5 -k 1M -o "slackware-current-rootfs.tar.xz" "https://mirrors.tuna.tsinghua.edu.cn/slackwarearm/slackwarearm-devtools/minirootfs/roots/${LatestSlack}"
			fi
		fi

		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
			sed 's/debian系统/slackware系统/g' |
			sed 's/debian system/slackware system/g' |
			sed 's:debian-sid:slackware-current:g' |
			sed 's:debian/sid:slackware/current:g' |
			sed 's:Debian GNU/Linux:Slackware GNU/Linux:g')"
	fi
	###########################
	if [ "${BETASYSTEM}" == '14' ]; then
		cd ~
		#touch .SLACKDetectionFILE
		if [ "${archtype}" != 'armhf' ] && [ "${archtype}" != 'arm64' ]; then
			if [ ! -e "/usr/bin/qemu-arm-static" ]; then
				apt update
				apt install qemu-user-static
			fi
		fi
		echo "armbian-bullseye-desktop已预装xfce4"
		if [ ! -e "armbian-bullseye-rootfs.tar.lz4" ]; then
			if [ "${archtype}" = 'armhf' ]; then
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

		mkdir -p ${DebianCHROOT}
		rm -vf ~/armbian-bullseye-rootfs.tar
		lz4 -d ~/armbian-bullseye-rootfs.tar.lz4
		cd ${DebianCHROOT}
		if [ "${LINUXDISTRO}" = "Android" ]; then
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

		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
			sed 's/debian系统/armbian系统/g' |
			sed 's/debian system/armbian system/g' |
			sed 's:debian-sid:armbian-bullseye:g' |
			sed 's:debian/sid:armbian/bullseye:g' |
			sed 's:rootfs.tar.xz:rootfs.tar.lz4:g' |
			sed 's:Debian GNU/Linux:Armbian GNU/Linux:g')"
	fi
	####################
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	MainMenu
}

#########################
INSTALLDEBIANGNULINUXDISTRO() {
	if (whiptail --title "Install GNU/Linux" --yes-button 'Software source' --no-button 'Download Rec pkg' --yesno "Do you want to install via Tsinghua University open source mirror station, or download the recovery package (debian-xfce.tar.xz) to install?The latter only supports arm64.您想要通过软件源镜像站来安装，还是在线下载恢复包来安装？软件源获取的是最新版镜像，且支持arm64,armhf,x86,x64等架构，安装基础系统速度很快，但安装gui速度较慢。恢复包非最新版,仅支持aarch(arm64)架构,但安装gui速度较快，且更加方便。若您无使用GUI的需求，建议选择前者。" 15 50); then
		BUSTERORSID
	else
		if [ ! -d "/sdcard/Download/backup" ]; then
			mkdir -p /sdcard/Download/backup
		fi
		cd /sdcard/Download/backup
		if [ -e "debian_2020-03-11_17-31.tar.xz" ]; then
			if (whiptail --title "Install Debian" --yes-button '解压uncompress' --no-button 'Download again' --yesno "It was detected that the recovery package has been downloaded. Do you want to uncompress it, or download it again?检测到恢复包已经下载,您想要重新直接解压还是重新下载？" 14 50); then
				UNXZDEBIANRECOVERYKIT
			else
				DOWNLOADDEBIANXFCETARXZ

			fi
		else
			DOWNLOADDEBIANXFCETARXZ

		fi
	fi
}

########################
BUSTERORSID() {
	if (whiptail --title "Debian version" --yes-button 'Sid' --no-button 'Buster' --yesno "请选择您需要安装的debian版本，Please select the debian version you need to install.Buster为当前的stable版,sid为unstable。Buster更加稳定且bug较少,但buster的软件包较旧,而sid较新。Buster is more stable and has fewer bugs, but the packages inside the buster software source are older. The sid package is relatively new." 15 50); then
		if [ "${LINUXDISTRO}" != 'iSH' ]; then
			bash -c "$(curl -fLsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh')"
		else
			curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh' | bash
		fi
	else
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh | sed 's:/sid:/buster:g' | sed 's:extract z:extract:' | sed 's:-sid:-buster:g' | sed 's@#deb http@deb http@g' | sed 's/.*sid main/#&/')"
	fi
}
#############
INSTALLUBUNTUDISTRO2004() {
	if [ "${archtype}" = 'amd64' ] || [ "${archtype}" = 'i386' ]; then
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
			sed 's/debian系统/ubuntu系统/g' |
			sed 's/debian system/ubuntu system/g' |
			sed 's:debian-sid:ubuntu-focal:g' |
			sed 's:debian/sid:ubuntu/focal:g' |
			sed 's:/ubuntu-ports:/ubuntu:g' |
			sed 's:Debian GNU/Linux:Ubuntu GNU/Linux:g')"
	else
		#ubuntu-ports
		bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
			sed 's/debian系统/ubuntu系统/g' |
			sed 's/debian system/ubuntu system/g' |
			sed 's:debian-sid:ubuntu-focal:g' |
			sed 's:debian/sid:ubuntu/focal:g' |
			sed 's:Debian GNU/Linux:Ubuntu GNU/Linux:g')"
	fi
}
##########
INSTALLKALIROLLING() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
		sed 's:debian-sid:kali-rolling:g' |
		sed 's:debian/sid:kali/current:g' |
		sed 's/debian系统/kali系统/g' |
		sed 's/debian system/kali system/g' |
		sed 's/debian容器/kali容器/g' |
		sed 's:Debian GNU/Linux:Kali GNU/Linux:g')"
}
################
INSTALLFuntooDISTRO() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
		sed 's:debian-sid:funtoo-1.3:g' |
		sed 's:debian/sid:funtoo/1.3:g' |
		sed 's/debian系统/funtoo系统/g' |
		sed 's/debian system/funtoo system/g' |
		sed 's/debian容器/funtoo容器/g' |
		sed 's:Debian GNU/Linux:Funtoo GNU/Linux:g')"
}
#######################
INSTALLVOIDLINUXDISTRO() {
	bash -c "$(curl -LfsS raw.githubusercontent.com/2moe/tmoe-linux/master/installDebian.sh |
		sed 's:debian-sid:voidlinux-default:g' |
		sed 's:debian/sid:voidlinux/current:g' |
		sed 's/debian系统/void系统/g' |
		sed 's/debian system/void system/g' |
		sed 's/debian容器/void容器/g' |
		sed 's:Debian GNU/Linux:Void GNU/Linux:g')"
}
######################
GNULINUXTUNASOURCESLIST() {
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
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			GNULINUX
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
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			GNULINUX
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
		if [ "${archtype}" != 'amd64' ] && [ "${archtype}" != 'i386' ]; then
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
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	GNULINUX
	#此处要返回依赖检测处！
}
####################
CheckArch
##取消注释，测试用。
##MainMenu
