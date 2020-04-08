#!/bin/bash

########################################################################
#-- 自动检测相关依赖

CHECKdependencies() {

	if [ "$(id -u)" != "0" ]; then
		sudo bash -c "$(wget -qO- https://gitee.com/mo2/linux/raw/master/debian-gui-install.bash)" ||
			sudo bash -c "$(curl -LfsS https://gitee.com/mo2/linux/raw/master/debian-gui-install.bash)" ||
			su -c "$(wget -qO- https://gitee.com/mo2/linux/raw/master/debian-gui-install.bash)"
		exit 0
	fi

	dependencies=""

	if [ ! -e /usr/bin/whiptail ] && [ ! -e /bin/whiptail ]; then
		dependencies="${dependencies} whiptail"
	fi

	if [ ! -e /usr/bin/xz ]; then
		dependencies="${dependencies} xz-utils"
	fi

	if [ ! -e /usr/bin/mkfontscale ]; then
		dependencies="${dependencies} xfonts-utils"
	fi

	if [ ! -e /usr/bin/fc-cache ]; then
		dependencies="${dependencies} fontconfig"
	fi

	if [ ! -e /usr/bin/catimg ]; then
		if grep -q 'VERSION_ID' "/etc/os-release"; then
			DEBIANVERSION="$(grep 'VERSION_ID' "/etc/os-release" | cut -d '"' -f 2)"
		else
			DEBIANVERSION="10"
		fi
		if ((${DEBIANVERSION} <= 9)); then
			echo "检测到您的系统版本低于debian10，跳过安装catimg"
		else
			dependencies="${dependencies} catimg"
		fi
	fi

	if [ ! -e /usr/bin/sudo ]; then
		dependencies="${dependencies} sudo"
	fi

	if [ ! -e /usr/bin/wget ]; then
		dependencies="${dependencies} wget"
	fi

	if [ ! -z "$dependencies" ]; then
		echo "正在安装相关依赖..."
		apt update
		apt install -y ${dependencies}
	fi

	if grep -q 'ubuntu' /etc/os-release; then
		LINUXDISTRO='ubuntu'
		if [ ! -e "/bin/add-apt-repository" ] && [ ! -e "/usr/bin/add-apt-repository" ]; then
			apt install -y software-properties-common
		fi
	fi

	if ! grep -q "^zh_CN" "/etc/locale.gen"; then
		if [ ! -e "/usr/sbin/locale-gen" ]; then
			apt install -y locales
		fi
		sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
		locale-gen
		apt install -y language-pack-zh-hans 2>/dev/null
	fi

	if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
		WINDOWSDISTRO='WSL'
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
		whiptail --title "Tmoe-linux Tool输debian-i启动(20200408-10)" --menu "Type 'debian-i' to start this tool.Please use the enter and arrow keys to operate.当前主菜单有十几个选项，请使用方向键或触屏上下滑动，按回车键确认。0326本次更新在软件商店中加入了度盘和云音乐。0331优化WSL2" 19 50 7 \
			"1" "Install GUI 安装图形界面" \
			"2" "Install browser 安装浏览器" \
			"3" "Download theme 下载主题" \
			"4" "Other software/games 其它软件/游戏" \
			"5" "Modify VNC/XSDL/XRDP(远程桌面)conf" \
			"6" "Modify to Kali sources list 配置kali源" \
			"7" "Update Debian tool 更新本工具" \
			"8" "Install Chinese manual 安装中文手册" \
			"9" "Enable zsh tool 启用zsh管理工具" \
			"10" "VSCode server arm64" \
			"11" "Remove GUI 卸载图形界面" \
			"12" "Remove browser 卸载浏览器" \
			"13" "FAQ 常见问题" \
			"14" "Beta Features 测试版功能" \
			"0" "Exit 退出" \
			3>&1 1>&2 2>&3
	)

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

		wget -O /usr/local/bin/debian-i 'https://gitee.com/mo2/linux/raw/master/debian-gui-install.bash'
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

		bash -c "$(wget -qO- 'https://gitee.com/mo2/zsh/raw/master/zsh.sh')"

	fi
	###################################
	if [ "${OPTION}" == '10' ]; then
		if [ "$(uname -m)" = "aarch64" ]; then
			INSTALLORREMOVEVSCODE
		else
			echo "非常抱歉，Tmoe-linux的开发者未对您的架构进行适配。"
			echo "请自行安装VScode"
			echo "${YELLOW}按回车键返回。${RESET}"
			echo "Press enter to return."
			read
			DEBIANMENU
		fi
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
	###############################
	if [ "${OPTION}" == '0' ]; then

		exit 0

	fi
}

############################

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
		TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,1440x720,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为720x1440,当前为$(grep '\-geometry' "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1) 。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			sed -i '/vncserver -geometry/d' "$(which startvnc)"
			sed -i "$ a\vncserver -geometry $TARGET -depth 24 -name remote-desktop :1" "$(which startvnc)"
			echo 'Your current resolution has been modified.'
			echo '您当前的分辨率已经修改为'
			echo $(grep '\-geometry' "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			#echo $(sed -n \$p "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			#$p表示最后一行，必须用反斜杠转义。
			stopvnc 2>/dev/null
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			DEBIANMENU

		else
			echo '您当前的分辨率为'
			echo $(grep '\-geometry' "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
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
	##########
}
#########################
EDITVNCPULSEAUDIO() {
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。linux默认为127.0.0.1,WSL2默认为宿主机ip,当前为$(grep 'PULSE_SERVER' ~/.vnc/xstartup | cut -d '=' -f 2) \n本功能适用于局域网传输，本机操作无需任何修改。若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：您需要手动启动音频服务端,Android-Termux需输pulseaudio --start,win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat' \n至于其它第三方app,例如安卓XSDL,若其显示的PULSE_SERVER地址为192.168.1.3:4713,那么您需要输入192.168.1.3:4713" 20 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i '/PULSE_SERVER/d' ~/.vnc/xstartup
		sed -i "2 a\export PULSE_SERVER=$TARGET" ~/.vnc/xstartup
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
	echo "您当前分辨率为$(grep '\-geometry' "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"
	echo '改完后按Ctrl+S保存，Ctrl+X退出。'
	echo "Press Enter to confirm."
	echo "${YELLOW}按回车键确认编辑。${RESET}"
	read
	nano /usr/local/bin/startvnc || nano $(which startvnc)
	echo "您当前分辨率为$(grep '\-geometry' "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"

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
	nano /usr/local/bin/startxsdl || nano $(which startxsdl)
	echo 'See your current xsdl configuration information below.'
	echo '您当前的ip地址为'
	echo $(sed -n 3p $(which startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)

	echo '您当前的显示端口为'
	echo $(sed -n 3p $(which startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2)

	echo '您当前的音频端口为'
	echo $(sed -n 4p $(which startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	MODIFYXSDLCONF
}

######################
CHANGEPULSESERVERPORT() {

	TARGET=$(whiptail --inputbox "若xsdl app显示的端口非4713，则您可在此处修改。默认为4713，当前为$(sed -n 4p $(which startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2) \n请以xsdl app显示的pulse server地址的最后几位数字为准，输入完成后按回车键确认。" 20 50 --title "MODIFY PULSE SERVER PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "4 c export PULSE_SERVER=tcp:127.0.0.1:$TARGET" "$(which startxsdl)"
		echo 'Your current PULSE SERVER port has been modified.'
		echo '您当前的音频端口已修改为'
		echo $(sed -n 4p $(which startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		MODIFYXSDLCONF
	else
		MODIFYXSDLCONF
	fi
}

########################################################
CHANGEDISPLAYPORT() {

	TARGET=$(whiptail --inputbox "若xsdl app显示的Display number(输出显示的端口数字) 非0，则您可在此处修改。默认为0，当前为$(sed -n 3p $(which startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2) \n请以xsdl app显示的DISPLAY=:的数字为准，输入完成后按回车键确认。" 20 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "3 c export DISPLAY=127.0.0.1:$TARGET" "$(which startxsdl)"
		echo 'Your current DISPLAY port has been modified.'
		echo '您当前的显示端口已修改为'
		echo $(sed -n 3p $(which startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2)
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		MODIFYXSDLCONF
	else
		MODIFYXSDLCONF
	fi
}

###############################################
CHANGEIPADDRESS() {

	XSDLIP=$(sed -n 3p $(which startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)
	TARGET=$(whiptail --inputbox "若您需要用局域网其它设备来连接，则您可在下方输入该设备的IP地址。本机连接请勿修改，默认为127.0.0.1 ,当前为${XSDLIP} \n 请在修改完其它信息后，再来修改此项，否则将被重置为127.0.0.1。windows设备输 ipconfig，linux设备输ip -4 -br -c addr获取ip address，获取到的地址格式类似于192.168.123.234，输入获取到的地址后按回车键确认。" 20 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "s/${XSDLIP}/${TARGET}/g" "$(which startxsdl)"
		echo 'Your current ip address has been modified.'
		echo '您当前的ip地址已修改为'
		echo $(sed -n 3p $(which startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)
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
			if [ "${LINUXDISTRO}" = 'ubuntu' ]; then
				add-apt-repository -y ppa:mozillateam/ppa
			fi
			apt update
			#分项安装，防止ubuntu安装失败
			apt install -y firefox-esr
			apt install -y firefox-esr-l10n-zh-cn
			apt install -y firefox-esr-locale-zh-hans 2>/dev/null
		else
			echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
			echo " ${YELLOW}“谢谢您选择了我，我一定会比妹妹向您提供更好的上网服务的！”╰(*°▽°*)╯火狐娘坚定地说道。${RESET} "
			echo "1s后将自动开始安装"
			sleep 1
			apt update
			apt install -y firefox || apt install -y firefox-esr firefox-esr-l10n-zh-cn
			if [ -e "/usr/bin/firefox-esr" ]; then
				echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫妹妹ESR来代替了。${RESET}"
			fi
			apt install -y firefox-l10n-zh-cn 2>/dev/null
			apt install -y firefox-locale-zh-hans 2>/dev/null
		fi
		echo "若无法正常加载HTML5视频，则您可能需要安装火狐扩展${YELLOW}User-Agent Switcher and Manager${RESET}，并将浏览器UA修改为windows版chrome"
	else

		echo "${YELLOW}妾身就知道你没有看走眼！${RESET}"
		echo '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium --no-sandbox"'
		echo "1s后将自动开始安装"
		sleep 1
		#新版Ubuntu是从snap商店下载chromium的，为解决这一问题，将临时换源成ubuntu 18.04LTS.
		if [ "${LINUXDISTRO}" = 'ubuntu' ]; then
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
		#echo 'alias chromium="chromium --no-sandbox"' >>/etc/profile
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
	#wget -qO- 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png' | catimg -
	if [ ! -f 'LXDE_BUSYeSLZRqq3i3oM.png' ]; then
		wget -qO 'LXDE_BUSYeSLZRqq3i3oM.png' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png'
	fi
	catimg 'LXDE_BUSYeSLZRqq3i3oM.png'

	echo 'mate预览截图'
	#wget -qO- 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/1frRp1lpOXLPz6mO.jpg' | catimg -
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
	#wget -qO- 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/a7IQ9NnfgPckuqRt.jpg' | catimg -
	echo "建议缩小屏幕字体，并重新加载图片，以获得更优的显示效果。"
	echo "按回车键选择您需要安装的图形桌面环境"
	echo "${YELLOW}Press enter to continue.${RESET}"
	read
	INSTALLDESKTOP=$(whiptail --title "单项选择题" --menu \
		"您想要安装哪个桌面？按方向键选择，回车键确认，一次只可以装一个桌面哦！仅xfce桌面支持在本工具内便捷下载主题。 \n Which desktop environment do you want to install? " 15 60 4 \
		"0" "我一个都不要 =￣ω￣=" \
		"1" "xfce：兼容性高" \
		"2" "lxde：轻量化桌面" \
		"3" "mate：基于GNOME 2" \
		3>&1 1>&2 2>&3)

	##########################
	if [ "$INSTALLDESKTOP" == '1' ]; then
		#bash /etc/tmp/xfce.sh
		INSTALLXFCE4DESKTOP
	fi

	if [ "$INSTALLDESKTOP" == '2' ]; then
		#bash /etc/tmp/lxde.sh
		INSTALLLXDEDESKTOP
	fi

	if [ "$INSTALLDESKTOP" == '3' ]; then
		INSTALLMATEDESKTOP
	fi

	if [ "$INSTALLDESKTOP" == '0' ]; then
		DEBIANMENU
	fi
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read

	DEBIANMENU

}

REMOVEGUI() {
	####################
	echo '"xfce" "呜呜，(≧﹏ ≦)您真的要离开我么"  '
	echo '"lxde" "很庆幸能与阁下相遇（；´д｀）ゞ "  '
	echo '"mate" "喔...喔呜...我不舍得你走/(ㄒoㄒ)/~~"  '

	echo "${YELLOW}按回车键确认卸载,按Ctrl+C取消${RESET} "
	echo 'Press enter to confirm ,press Ctrl + C to cancel'
	read
	apt purge -y xfce4 xfce4-terminal tightvncserver xfce4-goodies
	apt purge -y ^xfce
	apt purge -y xfwm4-theme-breeze xcursor-themes
	apt purge -y lxde-core lxterminal
	apt purge -y ^lxde
	apt purge -y mate-desktop-environment-core mate-terminal || aptitude purge -y mate-desktop-environment-core 2>/dev/null
	umount .gvfs
	apt purge -y ^gvfs ^udisks
	apt purge -y ^mate
	apt autopurge
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
		apt autopurge
	else
		echo '小声嘀咕：“妾身不在的时候，你一定要好好照顾好自己。” '
		echo "${YELLOW}按回车键确认卸载chromium,按Ctrl+C取消${RESET} "
		echo 'Press enter to confirm uninstall chromium,press Ctrl + C to cancel'
		read
		apt purge -y chromium chromium-l10n
		apt autopurge
	fi
	DEBIANMENU
}
#############################################
VSCODESERVER() {
	if [ ! -f "/usr/bin/git" ]; then
		apt update
		apt install -y git
	fi

	if [ ! -e "/etc/tmp/sed-vscode.tmp" ]; then
		mkdir -p /etc/tmp

		cat >"/etc/tmp/sed-vscode.tmp" <<-'EOF'
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
	grep '/tmp/startcode.tmp' /root/.bashrc >/dev/null || sed -i "$ r /etc/tmp/sed-vscode.tmp" /root/.bashrc
	grep '/tmp/startcode.tmp' /root/.zshrc >/dev/null || sed -i "$ r /etc/tmp/sed-vscode.tmp" /root/.zshrc
	if [ ! -x "/usr/bin/code" ]; then
		chmod +x /usr/bin/code 2>/dev/null || echo -e "检测到您未安装vscode server\nDetected that you do not have vscode server installed."
	fi
	if [ ! -f "/usr/bin/code" ]; then

		cd ${HOME}
		if [ -d ".VSCODESERVERTMPFILE" ]; then
			rm -rf .VSCODESERVERTMPFILE
		fi

		git clone -b build --depth=1 https://gitee.com/mo2/vscode-server.git .VSCODESERVERTMPFILE
		cd .VSCODESERVERTMPFILE
		tar -Jxvf code-server-arm64.tar.xz
		chmod +x code
		mv -f code "/usr/bin/"
		cd ${cur}
		rm -rf ${HOME}/.VSCODESERVERTMPFILE
		echo "即将为您启动VSCode服务,请复制密码，并在浏览器中粘贴。"
		echo "The VSCode server is starting, please copy the password and paste it in your browser."
		echo "您之后可以输code来启动VSCode Server."
		echo 'You can type "code" to start VSCodeServer.'
		/usr/bin/code
	else
		/usr/bin/code

	fi

}
##############################################################
INSTALLsynaptic() {
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Install安装" --no-button "Remove移除" --yesno "新立德是一款使用apt的图形化软件包管理工具，您也可以把它理解为软件商店。Synaptic is a graphical package management program for apt. It provides the same features as the apt-get command line utility with a GUI front-end based on Gtk+.它提供与apt-get命令行相同的功能，并带有基于Gtk+的GUI前端。功能：1.安装、删除、升级和降级单个或多个软件包。 2.升级整个系统。 3.管理软件源列表。  4.自定义过滤器选择(搜索)软件包。 5.按名称、状态、大小或版本对软件包进行排序。 6.浏览与所选软件包相关的所有可用在线文档。♪(^∇^*) " 19 50); then
		apt update
		apt install -y synaptic
		sed -i 's/synaptic-pkexec/synaptic/g' /usr/share/applications/synaptic.desktop

	else

		echo "${YELLOW}您真的要离开我么？哦呜。。。${RESET}"
		echo "Do you really want to remove synaptic?"
		echo "按任意键继续，按Ctrl+C取消。"
		echo "${YELLOW}Press any key to continue! ${RESET}"
		read
		apt purge -y synaptic
	fi
	DEBIANMENU

}
##########################################
CHINESEMANPAGES() {

	echo '即将为您安装 debian-reference-zh-cn、manpages、manpages-zh和man-db'
	apt update
	apt install -y debian-reference-zh-cn manpages manpages-zh man-db
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
		"您想要下载哪个主题？按方向键选择,当前可下载4个主题/图标包。下载完成后，您需要手动修改外观设置中的样式和图标。注：您需修改窗口管理器样式才能解决标题栏丢失的问题。\n Which theme do you want to download? " 15 60 4 \
		"1" "ukui：国产优麒麟ukui桌面默认主题" \
		"2" "win10：kali卧底模式主题(仅支持xfce)" \
		"3" "MacOS：Mojave" \
		"4" "UOS：国产统一操作系统图标包" \
		"0" "我一个都不要 =￣ω￣=" \
		3>&1 1>&2 2>&3)

	if [ "$INSTALLTHEME" == '0' ]; then
		DEBIANMENU
	fi

	if [ "$INSTALLTHEME" == '1' ]; then
		apt install ukui-themes

		if [ ! -e '/usr/share/icons/ukui-icon-theme-default' ] && [ ! -e '/usr/share/icons/ukui-icon-theme' ]; then
			cd /tmp
			UKUITHEME="$(wget -qO- 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/u/ukui-themes' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			wget -O 'ukui-themes.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/u/ukui-themes/${UKUITHEME}"
			apt install -y ./ukui-themes.deb
			rm -f ukui-themes.deb
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
		echo "Download completed.如需删除，请手动输rm -rf /usr/share/icons/Uos"
	fi

	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read

	DEBIANMENU

}
################################
Installkaliundercover() {

	if [ -f "/usr/bin/kali-undercover" ]; then
		echo "检测到您已安装win10主题"
	else
		#if [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
		if grep -q 'kali' '/etc/apt/sources.list'; then
			apt update
			apt install -y kali-undercover
		else
			cd /tmp
			UNDERCOVERlatestLINK="$(wget -qO- 'https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			wget -O kali-undercover.deb "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover/${UNDERCOVERlatestLINK}"
			apt install -y ./kali-undercover.deb
			rm -f ./kali-undercover.deb
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
	if [ -e "/usr/bin/code" ]; then
		VSCODEINSTALLSTATUS="检测到您已安装vscode."
		VSCODESTART='Start启动'
	else
		VSCODEINSTALLSTATUS="检测到您未安装vscode."
		VSCODESTART='Install安装'
	fi

	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "${VSCODESTART}" --no-button "Remove移除" --yesno "${VSCODEINSTALLSTATUS} \nVisual Studio Code is a lightweight but powerful source code editor which runs on your desktop and is available for Windows, macOS and Linux. It comes with built-in support for JavaScript, TypeScript and Node.js and has a rich ecosystem of extensions for other languages (such as C++, C#, Java, Python, PHP, Go) and runtimes (such as .NET and Unity).  ♪(^∇^*) " 16 50); then
		VSCODESERVER
	else
		echo "按任意键确认移除，按Ctrl+C取消。"
		echo "${YELLOW}Press any key to remove VSCode Server. ${RESET}"
		read
		rm -f /usr/bin/code /etc/tmp/sed-vscode.tmp
		echo "${YELLOW}移除成功，按回车键返回。${RESET}"
		echo "Remove successfully.Press enter to return."
		read
		DEBIANMENU
	fi
}
############################################
MODIFYTOKALISourcesList() {
	if grep -q 'ubuntu' /etc/os-release; then
		echo "${YELLOW}非常抱歉，暂不支持Ubuntu，按回车键返回。${RESET}"
		echo "Press enter to return."
		read
		DEBIANMENU
	fi

	if ! grep -q "kali" /etc/apt/sources.list; then
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

	#sed  's/^/#&/g' /etc/apt/sources.list

	echo 'deb https://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib' >/etc/apt/sources.list
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
	echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free' >/etc/apt/sources.list
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
			"您想要安装哪个软件？\n Which software do you want to install? 您需要使用方向键或pgdown来翻页。 您需要先安装gui才能安装里面的软件！" 17 60 6 \
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
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)

	##############################
	if [ "${SOFTWARE}" == '0' ]; then

		DEBIANMENU
	fi
	##############################
	if [ "${SOFTWARE}" == '1' ]; then
		apt update
		apt install -y mpv
		echo "安装完成，如需卸载，请手动输apt purge -y mpv"
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
	fi
	##############################
	if [ "${SOFTWARE}" == '2' ]; then
		cd /tmp
		if [ -e "/usr/share/tencent-qq" ]; then
			echo "检测到您已安装linuxQQ,按回车键继续,按Ctrl+C取消"
			echo "Press enter to continue."
			read
		fi

		if [ "$(uname -m)" = "aarch64" ]; then
			wget -O LINUXQQ.deb 'http://down.qq.com/qqweb/LinuxQQ/%E5%AE%89%E8%A3%85%E5%8C%85/linuxqq_2.0.0-b2-1076_arm64.deb'
		elif [ "$(uname -m)" = "x86_64" ]; then
			wget -O LINUXQQ.deb 'http://down.qq.com/qqweb/LinuxQQ/%E5%AE%89%E8%A3%85%E5%8C%85/linuxqq_2.0.0-b2-1076_amd64.deb'
		else
			echo "暂不支持您的架构"
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			OTHERSOFTWARE
		fi
		apt install -y ./LINUXQQ.deb
		echo "若安装失败，则请前往官网手动下载安装。"
		echo "url: https://im.qq.com/linuxqq/download.html"
		rm -fv ./LINUXQQ.deb
		echo "安装完成，如需卸载，请手动输apt purge -y linuxqq"
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
	fi
	##############################

	if [ "${SOFTWARE}" == '3' ]; then
		apt update
		apt install -y wesnoth
		echo "安装完成，如需卸载，请手动输apt purge -y wesnoth"
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
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
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
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
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
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
		if [ ! -e "/etc/tmp/.ChrootInstallationDetectionFile" ] && [ "$(uname -m)" != "x86_64" ] && [ "$(uname -m)" != "i686" ]; then
			mkdir -p /prod/version
			cd /usr/lib/libreoffice/program
			rm -f oosplash
			wget -qO 'oosplash' https://gitee.com/mo2/patch/raw/libreoffice/oosplash
			chmod +x oosplash
		fi
		echo "安装完成，如需卸载，请手动输apt purge -y ^libreoffice"
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
	fi

	##############################
	if [ "${SOFTWARE}" == '9' ]; then
		apt update
		apt install -y parole
		echo "安装完成，如需卸载，请手动输apt purge -y parole"
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
	fi
	##########################
	if [ "${SOFTWARE}" == '10' ]; then
		if [ "$(uname -m)" != "x86_64" ]; then
			echo "暂不支持您的架构"
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			OTHERSOFTWARE
		fi
		if [ -e "/usr/share/applications/baidunetdisk.desktop" ]; then
			echo "检测到您已安装baidunetdisk,按回车键继续,按Ctrl+C取消"
			echo "Press enter to continue."
			read
		fi
		cd /tmp
		wget -O baidunetdisk.deb "http://wppkg.baidupcs.com/issue/netdisk/LinuxGuanjia/3.0.1/baidunetdisk_linux_3.0.1.2.deb"
		apt install -y ./baidunetdisk.deb
		echo "安装完成，如需卸载，请手动输apt purge -y baidunetdisk"
		rm -fv ./baidunetdisk.deb
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
	fi
	###########################
	if [ "${SOFTWARE}" == '11' ]; then
		163NETEASEMUSIC
	fi
}
######################
163NETEASEMUSIC() {
	if [ "$(uname -m)" != "x86_64" ]; then
		echo "暂不支持您的架构"
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		OTHERSOFTWARE
	fi
	if [ -e "/usr/share/applications/netease-cloud-music.desktop" ]; then
		echo "检测到您已安装netease-cloud-music,按回车键继续,按Ctrl+C取消"
		echo "Press enter to continue."
		read
	fi
	cd /tmp
	wget -O netease-cloud-music.deb "http://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb"
	apt install -y ./netease-cloud-music.deb
	echo "安装完成，如需卸载，请手动输apt purge -y netease-cloud-music"
	rm -fv ./netease-cloud-music.deb
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	DEBIANMENU

}

####################################
INSTALLXFCE4DESKTOP() {
	#apt-mark hold gvfs
	apt update
	apt-mark hold udisks2
	echo '即将为您安装思源黑体(中文字体)、xfce4、xfce4-terminal、xfce4-goodies和tightvncserver等软件包。'
	dpkg --configure -a
	echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
	echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
	echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
	apt install -y fonts-noto-cjk xfce4 xfce4-terminal xfce4-goodies
	apt install -y tightvncserver
	apt autopurge -y ^libfprint || apt purge -y ^libfprint
	#apt install -y xfwm4-theme-breeze xcursor-themes
	if [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
		apt install -y kali-linux
		apt install -y kali-menu
		apt install -y kali-undercover
		apt install -y kali-linux-top10
		apt install -y kali-themes-common
		if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "armv7l" ]; then
			apt install -y kali-linux-arm
		fi
		apt install -y chromium-l10n
		sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
		grep 'chromium' /etc/profile || sed -i '$ a\alias chromium="chromium --no-sandbox"' /etc/profile
		apt search kali-linux
	else
		if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
			cd /tmp
			rm -f ./kali-themes-common.deb 2>/dev/null
			KaliTHEMElatestLINK="$(wget -qO- 'https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes' | grep kali-themes-common | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
			wget -O 'kali-themes-common.deb' "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes/${KaliTHEMElatestLINK}"
			apt install -y ./kali-themes-common.deb
			rm -f ./kali-themes-common.deb
		fi
	fi
	apt clean
	cd /usr/share/xfce4/terminal
	echo "正在配置xfce4终端配色..."
	wget -qO "colorschemes.tar.xz" 'https://gitee.com/mo2/xfce-themes/raw/terminal/colorschemes.tar.xz'
	tar -Jxvf "colorschemes.tar.xz"

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		startxfce4 &
	EndOfFile
	chmod +x ./xstartup

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
			chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} "${HOME}"
		fi

		export LANG="zh_CN.UTF-8"
		startxfce4
	EndOfFile
	if [ -e "/etc/tmp/.ChrootInstallationDetectionFile" ]; then
		grep -q 'dbus-launch' ~/.vnc/xstartup || sed -i 's:startxfce4:dbus-launch /usr/bin/startxfce4:' ~/.vnc/xstartup
		grep -q 'dbus-launch' /usr/local/bin/startxsdl || sed -i 's:startxfce4:dbus-launch /usr/bin/startxfce4:' /usr/local/bin/startxsdl
	fi

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
		apt update
		apt install -y xrdp
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
	apt-mark hold gvfs
	apt update
	apt install -y udisks2 2>/dev/null
	if [ ! -e "/etc/tmp/.ChrootInstallationDetectionFile" ] && [ "$(uname -m)" != "x86_64" ] && [ "$(uname -m)" != "i686" ]; then
		echo "" >/var/lib/dpkg/info/udisks2.postinst
	fi
	apt-mark hold udisks2
	echo '即将为您安装思源黑体(中文字体)、tightvncserver、mate-desktop-environment和mate-terminal等软件包'
	dpkg --configure -a
	apt install -y aptitude
	mkdir -p /run/lock /var/lib/aptitude
	touch /var/lib/aptitude/pkgstates
	aptitude install -y mate-desktop-environment mate-terminal 2>/dev/null || apt install -y mate-desktop-environment-core mate-terminal
	apt autopurge -y ^libfprint
	apt install -y fonts-noto-cjk tightvncserver
	apt clean

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		mate-session &
	EndOfFile
	chmod +x ./xstartup

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
			/mnt/c/WINDOWS/system32/taskkill.exe /f /im vcxsrv.exe 2>/dev/null
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat"
			echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
			cd "/mnt/c/Users/Public/Downloads/VcXsrv/"
			#/mnt/c/WINDOWS/system32/cmd.exe /c "start .\config.xlaunch"
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
			chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} "${HOME}"
		fi
		export LANG="zh_CN.UTF-8"
		mate-session
	EndOfFile
	if [ -e "/etc/tmp/.ChrootInstallationDetectionFile" ]; then
		grep -q 'dbus-launch' ~/.vnc/xstartup || sed -i 's:mate-session:dbus-launch /usr/bin/mate-session:' ~/.vnc/xstartup
		grep -q 'dbus-launch' /usr/local/bin/startxsdl || sed -i 's:mate-session:dbus-launch /usr/bin/mate-session:' /usr/local/bin/startxsdl
	fi

	echo "mate桌面可能存在gvfs和udisks2配置出错的问题，请直接无视"
	echo "您可以输umount .gvfs ; apt purge -y ^gvfs ^udisks来卸载出错的软件包，但这将破坏mate桌面的依赖关系。若在卸载后不慎输入apt autopurge -y将有可能导致mate桌面崩溃。"
	STARTVNCANDSTOPVNC

}
#################################
INSTALLLXDEDESKTOP() {
	apt update
	apt-mark hold udisks2
	echo '即将为您安装思源黑体(中文字体)、lxde-core、lxterminal、tightvncserver。'
	dpkg --configure -a
	echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
	echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
	echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
	apt install -y fonts-noto-cjk lxde-core lxterminal tightvncserver
	apt clean

	mkdir -p ~/.vnc
	cd ~/.vnc
	cat >xstartup <<-'EndOfFile'
		#!/bin/bash
		xrdb ${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		startlxde &
	EndOfFile
	chmod +x ./xstartup

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
		chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} "${HOME}"
		fi
		export LANG="zh_CN.UTF-8"
		startlxde
	EndOfFile
	STARTVNCANDSTOPVNC

}

#################################################
STARTVNCANDSTOPVNC() {
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
		chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} "${HOME}"
		fi
		echo "正在启动vnc服务,本机默认vnc地址localhost:5901"
		echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):5901
		export LANG="zh_CN.UTF8"
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
		chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} "${HOME}"
	fi
	#仅针对WSL修改语言设定
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		if [ "${LANG}" != 'zh_CN.UTF8' ]; then
			grep -q 'LANG=\"zh_' "/etc/profile" || sed -i '$ a\export LANG="zh_CN.UTF-8"' "/etc/profile"
			grep -q 'LANG=\"zh_' "${HOME}/.zlogin" || echo 'export LANG="zh_CN.UTF-8"' >>"${HOME}/.zlogin"
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
	echo '若xsdl音频端口不是4713，而是4712，则请输xsdl-4712进行修复。'
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
		"您有哪些疑问？\nWhat questions do you have?" 15 60 4 \
		"1" "Cannot open Baidu Netdisk" \
		"2" "udisks2/gvfs配置失败" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${TMOEFAQ}" == '0' ]; then
		DEBIANMENU
	fi
	############################
	if [ "${TMOEFAQ}" == '1' ]; then
		echo "若无法打开，则请手动输rm -f ~/baidunetdisk/baidunetdiskdata.db"
		echo "${YELLOW}按回车键自动执行，按Ctrl+C取消${RESET}"
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
	#############################
}
#################
BetaFeatures() {
	TMOEBETA=$(whiptail --title "Beta features" --menu \
		"测试版功能可能无法正常运行\nBeta features may not work properly." 15 60 5 \
		"1" "pinyin(拼音) input method" \
		"2" "calibre:电子书转换器和库管理" \
		"3" "fbreader(epub阅读器)" \
		"4" "krita(数字绘画)" \
		"5" "openshot(视频剪辑)" \
		"6" "telegram(注重保护隐私的社交app)" \
		"7" "typora(markdown编辑器)" \
		"8" "electronic-wechat(第三方微信客户端)" \
		"9" "qbittorrent(P2P下载工具)" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
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
		apt update
		apt install -y calibre
		echo "安装完成，如需卸载，请手动输apt purge -y calibre"
	fi
	##############################
	if [ "${TMOEBETA}" == '3' ]; then
		apt update
		apt install -y fbreader
		echo "安装完成，如需卸载，请手动输apt purge -y fbreader"
	fi
	##############################
	if [ "${TMOEBETA}" == '4' ]; then
		apt update
		apt install -y krita
		apt install -y krita-l10n
		echo "安装完成，如需卸载，请手动输apt purge -y ^krita"
	fi
	##############################
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
		if [ "$(uname -m)" = "x86_64" ]; then
			wget -O 'electronic-wechat.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/e/electronic-wechat/electronic-wechat_2.0~repack0~debiancn0_amd64.deb'
			apt install -y ./electronic-wechat.deb
			rm -vf ./electronic-wechat.deb
			echo "安装完成，如需卸载，请手动输apt purge -y electronic-wechat"
		else
			echo "非常抱歉，暂不支持您的架构"
		fi
	fi
	##############################
	if [ "${TMOEBETA}" == '9' ]; then
		apt update
		apt install -y qbittorrent
		echo "安装完成，如需卸载，请手动输apt purge -y qbittorrent"
	fi

	############################
	echo 'Press Enter to return.'
	echo "${YELLOW}按回车键返回。${RESET}"
	read
	DEBIANMENU

}
###########################################
CHECKdependencies
########################################################################
