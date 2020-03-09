#!/data/data/com.termux/files/usr/bin/bash
########################################################################
#检测架构
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
	s390x)
		archtype="s390x"
		;;
	ppc64el)
		archtype="ppc64el"
		;;
	mips*)
		echo -e 'Embedded devices such as routers are not supported at this time\n暂不支持mips架构的嵌入式设备'
		exit 1
		;;
	risc*)
		echo '暂不支持risc-v'
		echo 'The RISC-V architecture you are using is too advanced and we do not support it yet.'
		exit 1
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
	if [ "$(uname -o)" != "GNU/Linux" ]; then
		termux-setup-storage
	fi

	autoCheck

}
#未来可能不会增加的功能:加入路由器(mipsel架构)支持，需要从软件源开始构建。
#路由器要把whiptail改成dialog，还要改一下opkg安装的依赖项目。
#########################################################
autoCheck() {

	if [ "$(uname -o)" = "Android" ]; then
		ANDROIDTERMUX
	else
		GNULINUX
	fi
}
########################################
GNULINUX() {
	dependencies=""

	if [ ! -e /bin/tar ]; then
		dependencies="${dependencies} tar"
	fi

	if [ ! -e /bin/grep ]; then
		dependencies="${dependencies} grep"
	fi

	if [ ! -e /usr/bin/pv ]; then
		dependencies="${dependencies} pv"
	fi

	if [ ! -e /usr/bin/proot ]; then
		dependencies="${dependencies} proot"
	fi

	if [ ! -e /usr/bin/git ]; then
		dependencies="${dependencies} git"
	fi

	if [ ! -e /usr/bin/xz ]; then
		dependencies="${dependencies} xz-utils"
	fi

	if [ ! -e /usr/bin/whiptail ]; then
		dependencies="${dependencies} whiptail"
	fi

	if [ ! -e /usr/bin/pkill ]; then
		dependencies="${dependencies} procps"
	fi

	if [ ! -e /usr/bin/curl ]; then
		dependencies="${dependencies} curl"
	fi

	if [ ! -e /usr/bin/aria2c ]; then
		dependencies="${dependencies} aria2"
	fi

	if [ ! -z "$dependencies" ]; then
		echo "正在安装相关依赖..."
		if grep -Eqii "Alpine" /etc/issue || grep -Eq "Alpine" /etc/*-release; then

			apk add -q xz newt tar procps git grep wget bash aria2 curl pv coreutils
		elif grep -Eqi "Arch" /etc/issue || grep -Eqi "Manjaro" /etc/issue; then

			pacman -Sy --noconfirm ${dependencies}

		elif grep -Eqi "Fedora" /etc/issue || grep -Eqii "CentOS" /etc/issue || grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue; then

			dnf install -y ${dependencies} || yum install -y ${dependencies}
		else
			apt update
			apt install -y ${dependencies} || port install ${dependencies} || zypper in ${dependencies} || emerge ${dependencies} || guix package -i ${dependencies} || pkg install ${dependencies} || pkg_add ${dependencies} || pkgutil -i ${dependencies} || opkg install -y ${dependencies}

		fi

	fi
	PREFIX=/data/data/com.termux/files/usr

	MainMenu
}
########################################
ANDROIDTERMUX() {
	dependencies=""

	if [ ! -e $PREFIX/bin/pv ]; then
		dependencies="${dependencies} pv"
	fi

	if [ ! -e $PREFIX/bin/termux-audio-info ]; then
		dependencies="${dependencies} termux-api"
	fi

	if [ ! -e $PREFIX/bin/pulseaudio ]; then
		dependencies="${dependencies} pulseaudio"
	fi

	if [ ! -e $PREFIX/bin/grep ]; then
		dependencies="${dependencies} grep"
	fi

	if [ ! -e $PREFIX/bin/aria2c ]; then
		dependencies="${dependencies} aria2"
	fi

	if [ ! -e $PREFIX/bin/proot ]; then
		dependencies="${dependencies} proot"
	fi

	if [ ! -e $PREFIX/bin/xz ]; then
		dependencies="${dependencies} xz-utils"
	fi

	if [ ! -e $PREFIX/bin/tar ]; then
		dependencies="${dependencies} tar"
	fi

	if [ ! -e $PREFIX/bin/whiptail ]; then
		dependencies="${dependencies} dialog"
	fi

	if [ ! -e $PREFIX/bin/pkill ]; then
		dependencies="${dependencies} procps"
	fi

	if [ ! -e $PREFIX/bin/curl ]; then
		dependencies="${dependencies} curl"
	fi

	if [ ! -z "$dependencies" ]; then
		echo "正在安装相关依赖..."
		apt update
		apt install -y ${dependencies}
	fi
	##来自andronix的vnc声音修复脚本,稍微修改了一下。

	grep -q "anonymous" ${HOME}/../usr/etc/pulse/default.pa || echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >>${HOME}/../usr/etc/pulse/default.pa

	if ! grep -q "exit-idle-time = 180" ${HOME}/../usr/etc/pulse/daemon.conf; then
		sed -i '/exit-idle/d' ${HOME}/../usr/etc/pulse/daemon.conf
		echo "exit-idle-time = 180" >>${HOME}/../usr/etc/pulse/daemon.conf
	fi

	if [ -e ${DebianCHROOT}/root/.vnc/xstartup ]; then
		grep -q "PULSE_SERVER" ${DebianCHROOT}/root/.vnc/xstartup || sed -i '2 a\export PULSE_SERVER=127.0.0.1' ${DebianCHROOT}/root/.vnc/xstartup
	fi

	if [ -e /data/data/com.termux/files/usr/bin/debian ]; then
		grep -q "pulseaudio" /data/data/com.termux/files/usr/bin/debian || sed -i '2 a\pulseaudio --start' /data/data/com.termux/files/usr/bin/debian
	fi

	MainMenu
}

########################################################################
#-- 主菜单 main menu

MainMenu() {
	OPTION=$(
		whiptail --title "Tmoe-Debian GNU/Linux manager(20200309)" --backtitle "$(
			base64 -d <<-'DoYouWantToSeeWhatIsInside'
				6L6TZGViaWFuLWnlkK/liqjmnKznqIvluo8sVHlwZSBkZWJpYW4taSB0byBzdGFydCB0aGUgdG9v
				bCzokIzns7vnlJ/niannoJTnqbblkZgK
			DoYouWantToSeeWhatIsInside
		)" --menu "Please use the enter and arrow keys to operate.当前主菜单下有十几个选项,请使用方向键和回车键进行操作" 15 60 4 \
			"0" "proot安装 install debian" \
			"1" "chroot安装" \
			"2" "Video tutorial" \
			"3" "移除 remove system" \
			"4" "备份系统 backup system" \
			"5" "还原 restore" \
			"6" "查询空间占用 query space occupation" \
			"7" "更新本管理器 update debian manager" \
			"8" "配置zsh(优化termux) Configure zsh" \
			"9" "Download VNC apk" \
			"10" "VSCode Server arm64" \
			"11" "赋予proot容器真实root权限" \
			"12" "退出 exit" \
			3>&1 1>&2 2>&3
	)

	if [ "${OPTION}" == '0' ]; then
		if [ "$(uname -o)" != "Android" ]; then
			echo "非常抱歉，本功能仅适配安卓系统。"
			echo "Linux系统请换用chroot容器。"
			echo "Press enter to return。"
			echo "${YELLOW}按回车键返回。${RESET} "
			read
			MainMenu
		fi

		installDebian

	fi

	if [ "${OPTION}" == '1' ]; then
		if [ "$(uname -o)" = "Android" ]; then
			echo "非常抱歉，本功能仅适配Linux系统，暂未适配Android。"
			echo "Android系统请换用proot容器。"
			echo "由于在测试过程中出现部分已挂载的目录无法强制卸载的情况，故建议您换用proot容器。"
			echo "Press enter to return。"
			echo "${YELLOW}按回车键返回。${RESET} "
			read
			MainMenu
		else
			CHROOTINSTALLDebian
		fi

	fi

	if [ "${OPTION}" == '2' ]; then

		DownloadVideoTutorial
	fi

	if [ "${OPTION}" == '3' ]; then

		REMOVESYSTEM

	fi

	if [ "${OPTION}" == '4' ]; then

		BackupSystem

	fi

	if [ "${OPTION}" == '5' ]; then

		RESTORESYSTEM

	fi

	if [ "${OPTION}" == '6' ]; then

		SpaceOccupation

	fi

	if [ "${OPTION}" == '7' ]; then

		UPDATEMANAGER
	fi

	if [ "${OPTION}" == '8' ]; then
		bash -c "$(curl -fLsS 'https://gitee.com/mo2/Termux-zsh/raw/master/termux-zsh.sh')"
		#bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-zsh/raw/master/termux-zsh.sh')"

	fi

	if [ "${OPTION}" == '9' ]; then

		DOWNLOADVNCAPK

	fi

	if [ "${OPTION}" == '10' ]; then
		STARTVSCODE

	fi

	if [ "${OPTION}" == '11' ]; then

		RootMode
	fi

	if [ "${OPTION}" == '12' ]; then
		exit

	fi

}

########################################################################

installDebian() {
	if [ -d ~/${DebianFolder} ]; then
		if (whiptail --title "检测到您已安装debian,请选择您需要执行的操作！" --yes-button 'Start启动o(*￣▽￣*)o' --no-button 'Reinstall重装(っ °Д °)' --yesno "Debian has been installed, please choose what you need to do!" 7 60); then
			debian
		else

			echo "${YELLOW}检测到您已安装debian,是否重新安装？[Y/n]${RESET} "
			echo "${YELLOW}您可以无需输"y"，直接按回车键确认。${RESET} "
			echo "Detected that you have debian installed, do you want to reinstall it?[Y/n]"
			read opt
			case $opt in
			y* | Y* | "")
				$PREFIX/bin/debian-rm && sed -i '/alias debian=/d' $PREFIX/etc/profile 2>/dev/null
				sed -i '/alias debian-rm=/d' $PREFIX/etc/profile 2>/dev/null
				source $PREFIX/etc/profile >/dev/null 2>&1
				bash -c "$(curl -fLsS 'https://gitee.com/mo2/Termux-Debian/raw/master/installDebian.sh')"
				#bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/installDebian.sh')"
				;;
			n* | N*)
				echo "skipped."
				echo "Press enter to return。"
				echo "${YELLOW}按回车键返回。${RESET} "
				read
				MainMenu
				;;
			*)
				echo "Invalid choice. skipped."
				echo "Press enter to return。"
				echo "${YELLOW}按回车键返回。${RESET} "
				read
				MainMenu
				;;
			esac
		fi

	else
		bash -c "$(curl -fLsS 'https://gitee.com/mo2/Termux-Debian/raw/master/installDebian.sh')"

	fi
}

########################################################################
#

RootMode() {
	if (whiptail --title "您真的要开启root模式吗" --yes-button '好哒o(*￣▽￣*)o' --no-button '不要(っ °Д °；)っ' --yesno "开启后将无法撤销，除非重装debian，建议您在开启前进行备份。若您的手机存在外置tf卡，则在开启后，会挂载整张卡。若无法备份和还原，请输tsudo debian-i启动本管理器。开启root模式后，绝对不要输破坏系统的危险命令！若在debian系统内输rm -rf /*删除根目录（格式化）命令，将有可能导致安卓原系统崩溃！！！请在本管理器内正常移除debian。" 10 60); then

		if [ ! -f /data/data/com.termux/files/usr/bin/tsu ]; then
			apt update
			apt install -y tsu
		fi

		mkdir -p /data/data/com.termux/files/usr/etc/storage/
		cd /data/data/com.termux/files/usr/etc/storage/

		rm -rf external-tf

		tsu -c 'ls /mnt/media_rw/*' 2>/dev/null || mkdir external-tf

		TFcardFolder=$(tsu -c 'ls /mnt/media_rw/| head -n 1')

		tsudo ln -s /mnt/media_rw/${TFcardFolder} ./external-tf

		sed -i 's:/home/storage/external-1:/usr/etc/storage/external-tf:g' /data/data/com.termux/files/usr/bin/debian

		cd $PREFIX/etc/
		if [ ! -f profile ]; then
			echo "" >>profile
		fi
		cp -pf profile profile.bak

		grep 'alias debian=' profile >/dev/null 2>&1 || sed -i '$ a\alias debian="tsudo debian"' profile
		grep 'alias debian-rm=' profile >/dev/null 2>&1 || sed -i '$ a\alias debian-rm="tsudo debian-rm"' profile

		source profile >/dev/null 2>&1
		alias debian="tsudo debian"
		alias debian-rm="tsudo debian-rm"

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
	if [ -e "${DebianCHROOT}/etc/tmp/.ChrootInstallationDetectionFile" ]; then
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
		echo '建议您在移除前进行备份，若因操作不当导致数据丢失，开发者概不负责！！！'
		echo "Before removing the system, make sure you have unmounted the chroot mount directory.
It is recommended that you back up the entire system before removal. If the data is lost due to improper operation, the developer is not responsible! "
	fi
	echo 'Detecting Debian system footprint... 正在检测debian系统占用空间大小'
	du -sh ./${DebianFolder} --exclude=./${DebianFolder}/root/tf --exclude=./${DebianFolder}/root/sd --exclude=./${DebianFolder}/root/termux
	if [ ! -d ~/${DebianFolder} ]; then
		echo "${YELLOW}Detected that you are not currently installed 检测到您当前未安装debian${RESET}"
	fi
	echo "移除系统前，请先确保您已停止debian容器。"
	echo "${YELLOW}按回车键确认移除,按Ctrl+C取消 Press enter to confirm.${RESET} "
	read

	chmod 777 -R ${DebianFolder}
	rm -rf "${DebianFolder}" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc $PREFIX/bin/startxsdl $PREFIX/bin/debian-rm $PREFIX/bin/code 2>/dev/null || tsudo rm -rf "${DebianFolder}" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc $PREFIX/bin/startxsdl $PREFIX/bin/debian-rm $PREFIX/bin/code 2>/dev/null
	sed -i '/alias debian=/d' $PREFIX/etc/profile
	sed -i '/alias debian-rm=/d' $PREFIX/etc/profile
	source profile >/dev/null 2>&1
	echo 'The debian system has been removed. If you want to uninstall aria2, enter "apt remove aria2" or "apt purge aria2"'
	echo '移除完成，如需卸载aria2,请手动输apt remove aria2'
	echo '其它相关依赖，如pv、dialog、procps、proot、wget等，均需手动卸载。'
	echo 'If you want to reinstall, it is not recommended to remove the image file.'
	echo '若需删除debian管理器，则请输rm -f $PREFIX/bin/debian-i'
	echo "${YELLOW}若您需要重装debian，则不建议删除镜像文件。${RESET} "
	ls -lh ~/debian-sid-rootfs.tar.xz
	printf "${YELLOW}请问您是否需要删除镜像文件？[Y/n]${RESET} "
	#printf之后分行
	echo ''
	echo 'Do you need to delete the image file (debian-sid-rootfs.tar.xz)?[Y/n]'

	read opt
	case $opt in
	y* | Y* | "") rm -f ~/debian-sid-rootfs.tar.xz $PREFIX/bin/debian-rm && echo "Deleted已删除" ;;
	n* | N*) echo "${YELLOW}Skipped,已跳过，按回车键返回。${RESET} " ;;
	*) echo "${YELLOW}Invalid choice，skipped.已跳过，按回车键返回。${RESET} " ;;
	esac
	MainMenu

}
########################################################################
#
BackupSystem() {
	if [ -e "${DebianCHROOT}/etc/tmp/.ChrootInstallationDetectionFile" ]; then
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
	OPTION=$(whiptail --title "Backup System" --menu "Choose your option" 15 60 4 \
		"0" "Back to the main menu 返回主菜单" \
		"1" "备份Debian" \
		"2" "备份Termux" \
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

		if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60); then

			echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read
			tar -PJpcf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} $PREFIX/bin/debian | (pv -p --timer --rate --bytes >${TMPtime}.tar.xz)
			#whiptail进度条已弃用
			#tar -PJpcf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} $PREFIX/bin/debian | (pv -n >${TMPtime}.tar.xz) 2>&1 | whiptail --gauge "Packaging into tar.xz" 10 70

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

			tar -Ppczf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} $PREFIX/bin/debian | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)

			#最新版弃用了whiptail的进度条！！！
			#tar -Ppczf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} $PREFIX/bin/debian | (pv -n >${TMPtime}.tar.gz) 2>&1 | whiptail --gauge "Packaging into tar.gz \n正在打包成tar.gz" 10 70

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

		#echo 'This operation will only backup the home directory of termux, not the debian system. If you need to backup debian, please select both options or backup debian separately.'
		#echo '本次操作将只备份termux的主目录，不包含主目录下的debian系统。如您需备份debian,请同时选择home和usr，或单独备份debian。'

		echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
		read

		echo $(date +%Y-%m-%d_%H-%M) >backuptime.tmp
		TMPtime=termux-home_$(cat backuptime.tmp)

		if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60); then

			echo "您选择了tar.xz,即将为您备份至/sdcard/Download/backup/${TMPtime}.tar.xz"
			echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
			read

			tar -PJpvcf ${TMPtime}.tar.xz --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/sd --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/termux --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/tf /data/data/com.termux/files/home

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

			tar -Ppvczf ${TMPtime}.tar.gz --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/sd --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/termux --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/tf /data/data/com.termux/files/home

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
			mkdir -p /sdcard/Download/backup && cd /sdcard/Download/backup
		else
			cd /sdcard/Download/backup
		fi

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
			tar -PJpcf - /data/data/com.termux/files/usr | (pv -p --timer --rate --bytes >${TMPtime}.tar.xz)
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
			tar -Ppczf - /data/data/com.termux/files/usr | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
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
			tar -PJpcf - /data/data/com.termux/files/home /data/data/com.termux/files/usr | (pv -p --timer --rate --bytes >${TMPtime}.tar.xz)
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
			tar -Ppczf - /data/data/com.termux/files/home /data/data/com.termux/files/usr | (pv -p --timer --rate --bytes >${TMPtime}.tar.gz)
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

####################################
#tar压缩进度条1、2

: '	#tar -czf - ~/${DebianFolder} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

	#tar -cf - ~/${DebianFolder} | pv -s $(du -sb ~/${DebianFolder} | awk '{print $1}') | gzip > ${TMPtime}.tar.gz

	#tar Pzcvf ${TMPtime}.tar.gz ~/${DebianFolder}'

########################################################################
#
RESTORESYSTEM() {
	if [ -e "${DebianCHROOT}/etc/tmp/.ChrootInstallationDetectionFile" ]; then
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
		"1" "Restore the latest debian backup 还原Debian" \
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
				pv ${RESTORE} | tar -PJx
			fi

			if [ "${RESTORE:0-6:6}" == 'tar.gz' ]; then
				echo 'tar.gz'
				pv ${RESTORE} | tar -Pzx
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
				pv ${RESTORE} | tar -PJx
			fi

			if [ "${RESTORE:0-6:6}" == 'tar.gz' ]; then
				echo 'tar.gz'
				pv ${RESTORE} | tar -Pzx
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
	#curl -L -o $PREFIX/bin/debian-i 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh'
	aria2c --allow-overwrite=true -d $PREFIX/bin -o debian-i 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh'
	#wget -qO $PREFIX/bin/debian-i 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh'
	echo "${YELLOW}更新完成，按回车键返回。${RESET}"
	echo 'Press enter to return.'
	chmod +x $PREFIX/bin/debian-i
	read
	bash $PREFIX/bin/debian-i

}
#################################
DOWNLOADVNCAPK() {
	if [ ! -e $PREFIX/bin/git ]; then
		apt update
		apt install -y git
	fi

	cd /sdcard/Download || mkdir -p /sdcard/Download && cd /sdcard/Download
	if (whiptail --title "您想要下载哪个软件?" --yes-button 'VNC Viewer' --no-button 'XServer XSDL' --yesno "vnc操作体验更好,当前版本已经可以通过pulse server来传输音频。xsdl对某些软件的兼容性更高，但操作体验没有vnc好。VNC has a better operating experience and is also smoother.XSDL is more compatible with some software， but the experience is not as good as VNC in every way.若Android VNC启动后仍无声音，则请安装termux:api.apk" 10 60); then
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
		#aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://cdn.tmoe.me/git/Termux-Debian/VNCViewer_com-realvnc-viewer-android-3-6-1-42089.tar.xz' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://m.tmoe.me/down/share/Android/VNC/VNCViewer_com-realvnc-viewer-android-3-6-1-42089.tar.xz'
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
		#		aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://cdn.tmoe.me/git/Termux-Debian/XServerXSDL-X-org-server_1-20-41.tar.xz' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://m.tmoe.me/down/share/Android/VNC/XServerXSDL-X-org-server_1-20-41.tar.xz'
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
	if [ ! -e $PREFIX/bin/git ]; then
		apt update
		apt install -y git
	fi

	if [ ! -d "${HOME}/${DebianFolder}" ]; then
		echo "未检测到${DebianFolder},请先安装debian_arm64"
		echo "Detected that you did not install ${DebianFolder}, please install debian first."
		echo "${YELLOW}按回车键返回。${RESET}"
		echo 'Press enter to return.'
		read
		MainMenu
	fi
	if [ ! -e "$PREFIX/bin/code" ]; then
		cat >$PREFIX/bin/code <<-EndOfFile
			#!/data/data/com.termux/files/usr/bin/bash
			touch "${HOME}/debian_arm64/tmp/startcode.tmp"
			am start -a android.intent.action.VIEW -d "http://localhost:8080"
			echo "本机默认vscode服务地址localhost:8080"
			echo The LAN VNC address 局域网地址\$(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):8080
			echo "Please paste the address into your browser!"
			echo "请将地址粘贴到浏览器的地址栏中"


			echo "您之后可以输code来启动VSCode Server."
			echo 'You can type "code" to start VScodeServer.'
			debian
		EndOfFile
		chmod +x $PREFIX/bin/code
	fi

	if [ ! -e "${HOME}/${DebianFolder}/etc/tmp/sed-vscode.tmp" ]; then
		mkdir -p ${HOME}/${DebianFolder}/etc/tmp/

		cat >${HOME}/${DebianFolder}/etc/tmp/sed-vscode.tmp <<-'EOF'
			if [ -e "/tmp/startcode.tmp" ]; then
				echo "正在为您启动VSCode服务(器),请复制密码，并在浏览器的密码框中粘贴。"
				echo "The VSCode service(server) is starting, please copy the password and paste it in your browser."

				rm -f /tmp/startcode.tmp
				code &
				echo "已为您启动VSCode服务!"
				echo "VScodeServer has been started,enjoy it !"
				echo "您可以输pkill code来停止服务(器)。"
				echo 'You can type "pkill code" to stop vscode service(server).'
			fi
		EOF
	fi

	if [ ! -f "${HOME}/${DebianFolder}/root/.zshrc" ]; then
		echo "" >>${HOME}/${DebianFolder}/root/.zshrc
	fi
	if [ ! -f "${HOME}/${DebianFolder}/root/.bashrc" ]; then
		echo "" >>${HOME}/${DebianFolder}/root/.bashrc
	fi

	grep '/tmp/startcode.tmp' ${HOME}/${DebianFolder}/root/.bashrc >/dev/null || sed -i "$ r ${HOME}/${DebianFolder}/etc/tmp/sed-vscode.tmp" ${HOME}/${DebianFolder}/root/.bashrc
	grep '/tmp/startcode.tmp' ${HOME}/${DebianFolder}/root/.zshrc >/dev/null || sed -i "$ r ${HOME}/${DebianFolder}/etc/tmp/sed-vscode.tmp" ${HOME}/${DebianFolder}/root/.zshrc

	if [ -e "${HOME}/${DebianFolder}/usr/bin/code" ]; then
		code
	else

		cd ${HOME}
		if [ -d ".VSCODESERVERTMPFILE" ]; then
			rm -rf .VSCODESERVERTMPFILE
		fi

		echo "server版商店中不包含所有插件，如需下载额外插件，请前往微软vscode官方在线商店下载vsix后缀的离线插件，并手动安装。 https://marketplace.visualstudio.com/vscode"
		git clone -b build --depth=1 https://gitee.com/mo2/vscode-server.git .VSCODESERVERTMPFILE
		cd .VSCODESERVERTMPFILE
		tar -Jxvf code-server-arm64.tar.xz
		chmod +x code
		mv -f code "${HOME}/${DebianFolder}/usr/bin/"
		cd ${cur}
		rm -rf ${HOME}/.VSCODESERVERTMPFILE
		echo "Congratulations, you have successfully installed vscode server!"
		echo "您已成功安装VSCode服务，如需卸载请输rm -f $PREFIX/bin/code  ${HOME}/${DebianFolder}/usr/bin/code"

		grep "keyCode" ${HOME}/${DebianFolder}/root/.local/share/code-server/User/settings.json >/dev/null || mkdir -p ${HOME}/${DebianFolder}/root/.local/share/code-server/User && cat >${HOME}/${DebianFolder}/root/.local/share/code-server/User/settings.json <<-'EndOfFile'
			{
			"keyboard.dispatch": "keyCode"
			}
		EndOfFile

		code
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
	aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "20200229vnc教程06.mp4" 'https://cdn.tmoe.me/Tmoe-Debian-Tool/20200229VNC%E6%95%99%E7%A8%8B06.mp4' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "20200229vnc教程06.mp4" 'https://m.tmoe.me/down/share/videos/20200229vnc%E6%95%99%E7%A8%8B06.mp4'
	PLAYVideoTutorial
}
PLAYVideoTutorial() {
	termux-open "20200229vnc教程06.mp4"
	echo "${YELLOW}若视频无法自动播放，则请进入下载目录手动播放。${RESET}"
	echo "If the video does not play automatically, please enter the download directory to play it manually."
	echo "转载视频须经原作者同意，请勿擅自将视频上传至B站等平台。"
	echo "Do not upload video to platforms such as YouTube without authorization."
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
	echo "This feature is currently in the beta stage. If you find that some directories cannot be unloaded forcibly before removing the debian system, please restart your device before uninstalling the chroot container to prevent the mounted directory from being deleted by mistake."
	echo "本功能目前仍处于测试阶段，移除debian系统前若发现部分已挂载目录无法强制卸载，请重启设备再卸载chroot容器，防止已挂载目录被误删！"
	echo "按回车键继续,按Ctrl+C取消。"
	echo "${YELLOW}Press enter to continue.${RESET}"
	read
	mkdir -p ${PREFIX}/bin
	#mkdir -p /data/data/com.termux/files/home
	#if [ ! -f "${PREFIX}/bin/bash" ]; then
	#	cp -f $(which bash) ${PREFIX}/bin
	#fi
	#grep "export PATH=\'" /etc/profile >/dev/null || sed -i "$ a\export PATH='${PREFIX}/bin:$PATH'" /etc/profile 2>/dev/null
	#grep "export PATH=\'" /root/.zshrc >/dev/null || sed -i "$ a\export PATH='${PREFIX}/bin:$PATH'" /root/.zshrc 2>/dev/null
	#export "PATH=${PREFIX}/bin:$PATH"

	grep 'alias debian=' /etc/profile >/dev/null || sed -i "$ a\alias debian='bash /data/data/com.termux/files/usr/bin/debian'" /etc/profile 2>/dev/null
	grep 'alias debian=' /root/.zshrc >/dev/null || sed -i "$ a\alias debian='bash /data/data/com.termux/files/usr/bin/debian'" /root/.zshrc 2>/dev/null
	grep 'alias debian-i=' /etc/profile >/dev/null || sed -i "$ a\alias debian-i='bash /data/data/com.termux/files/usr/bin/debian-i'" /etc/profile 2>/dev/null
	grep 'alias debian-i=' /root/.zshrc >/dev/null || sed -i "$ a\alias debian-i='bash /data/data/com.termux/files/usr/bin/debian-i'" /root/.zshrc 2>/dev/null
	grep 'alias startvnc=' /etc/profile >/dev/null || sed -i "$ a\alias startvnc='bash /data/data/com.termux/files/usr/bin/startvnc'" /etc/profile 2>/dev/null
	grep 'alias startvnc=' /root/.zshrc >/dev/null || sed -i "$ a\alias startvnc='bash /data/data/com.termux/files/usr/bin/startvnc'" /root/.zshrc 2>/dev/null
	grep 'alias stopvnc=' /etc/profile >/dev/null || sed -i "$ a\alias stopvnc='bash /data/data/com.termux/files/usr/bin/stopvnc'" /etc/profile 2>/dev/null
	grep 'alias stopvnc=' /root/.zshrc >/dev/null || sed -i "$ a\alias stopvnc='bash /data/data/com.termux/files/usr/bin/stopvnc'" /root/.zshrc 2>/dev/null
	alias debian='bash /data/data/com.termux/files/usr/debian'
	alias debian-i='bash /data/data/com.termux/files/usr/debian-i'
	alias startvnc='bash /data/data/com.termux/files/usr/startvnc'
	touch ~/.ChrootInstallationDetectionFile
	installDebian
}

#####################################
CheckArch
##取消注释，测试用。
##MainMenu
