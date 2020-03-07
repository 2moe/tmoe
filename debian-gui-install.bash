#!/bin/bash

########################################################################
#-- 自动检测相关依赖

CHECKdependencies() {

	dependencies=""

	if [ ! -e /usr/bin/whiptail ]; then
		dependencies="${dependencies} whiptail"
	fi

	if [ ! -e /usr/bin/xz ]; then
		dependencies="${dependencies} xz-utils"
	fi

	if [ ! -e /usr/bin/wget ]; then
		dependencies="${dependencies} wget"
	fi

	if [ ! -z "$dependencies" ]; then
		echo "正在安装相关依赖..."
		apt update
		apt install -y ${dependencies}
	fi
	YELLOW=$(printf '\033[33m')
	RESET=$(printf '\033[m')
	cur=$(pwd)
	DEBIANMENU
}
####################################################
DEBIANMENU() {
	OPTION=$(whiptail --title "Tmoe-Debian Tool输debian-i启动(20200307)" --menu "Type 'debian-i' to start this tool.Please use the enter and arrow keys to operate.当前主菜单有十几个选项，请使用方向键或触屏上下滑动，按回车键确认。" 15 50 4 \
		"1" "Install GUI 安装图形界面" \
		"2" "Install browser 安装浏览器" \
		"3" "Remove GUI 卸载图形界面" \
		"4" "Remove browser 卸载浏览器" \
		"5" "Update Debian tool 更新本工具" \
		"6" "Modify to Kali sources list 配置kali源" \
		"7" "Restore to Debian sources list 还原debian源" \
		"8" "Install Chinese manual 安装中文手册" \
		"9" "Modify VNC config 修改vnc配置" \
		"10" "Modify XSDL config 修改xsdl配置" \
		"11" "Enable zsh tool 启用zsh管理工具" \
		"12" "Start VScode server" \
		"13" "Remove VScode server" \
		"14" "Synaptic(新立得软件包管理器/软件商店)" \
		"15" "Install theme 安装主题" \
		"16" "Exit 退出" \
		3>&1 1>&2 2>&3)

	##############################
	if [ "${OPTION}" == '1' ]; then

		INSTALLGUI
	fi

	if [ "${OPTION}" == '2' ]; then

		installBROWSER

	fi

	if [ "${OPTION}" == '3' ]; then

		REMOVEGUI
	fi

	if [ "${OPTION}" == '4' ]; then

		REMOVEBROWSER
	fi

	if [ "${OPTION}" == '5' ]; then

		wget -qO /usr/local/bin/debian-i 'https://gitee.com/mo2/Termux-Debian/raw/master/debian-gui-install.bash'
		echo 'Update completed, press Enter to return.'
		echo "${YELLOW}更新完成，按回车键返回。${RESET}"
		chmod +x /usr/local/bin/debian-i
		read
		bash /usr/local/bin/debian-i
	fi
	################
	if [ "${OPTION}" == '6' ]; then

		bash /usr/local/bin/kali.sh

	fi

	if [ "${OPTION}" == '7' ]; then

		bash /usr/local/bin/kali.sh rm

	fi
	############
	if [ "${OPTION}" == '8' ]; then

		CHINESEMANPAGES
		#bash /usr/local/bin/man.sh

	fi

	####################
	if [ "${OPTION}" == '9' ]; then
		MODIFYVNCCONF

	fi
	####################################
	if [ "${OPTION}" == '10' ]; then

		MODIFYXSDLCONF

	fi

	#################################
	if [ "${OPTION}" == '11' ]; then

		bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-zsh/raw/master/termux-zsh.sh')"

	fi

	###################################
	if [ "${OPTION}" == '12' ]; then

		VSCODESERVER

	fi
	################################
	if [ "${OPTION}" == '13' ]; then
		echo "按任意键确认移除，按Ctrl+C取消。"
		echo "${YELLOW}Press any key to remove VSCode Server. ${RESET}"
		read
		rm -f /usr/bin/code /etc/tmp/sed-vscode.tmp
		echo "${YELLOW}移除成功，按回车键返回。${RESET}"
		echo "Remove successfully.Press enter to return."
		read
		DEBIANMENU

	fi
	###############################
	if [ "${OPTION}" == '14' ]; then

		INSTALLsynaptic

	fi
	###############################
	if [ "${OPTION}" == '15' ]; then

		CONFIGTHEMES

	fi
	###############################
	if [ "${OPTION}" == '16' ]; then

		exit

	fi

}

############################

MODIFYVNCCONF() {
	if [ ! -e /bin/nano ]; then
		apt install -y nano
	fi

	if [ ! -e /usr/bin/startvnc ]; then
		echo "/usr/bin/startvnc is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startvnc,您可能尚未安装图形桌面，是否继续编辑?'
		echo "Press Enter to confirm."
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		read
	fi
	if (whiptail --title "modify vnc configuration" --yes-button '分辨率resolution' --no-button '其它other' --yesno "您想要修改哪些配置信息？What configuration do you want to modify?" 15 50); then
		TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,1440x720,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为720x1440,当前为$(sed -n 5p "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1) 。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 20 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			sed -i "5 c vncserver -geometry $TARGET  -depth 24 -name remote-desktop :1" "$(which startvnc)"
			echo 'Your current resolution has been modified.'
			echo '您当前的分辨率已经修改为'
			echo $(sed -n 5p "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			stopvnc 2>/dev/null
			echo 'Press Enter to return.'
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			DEBIANMENU

		else
			echo '您当前的分辨率为'
			echo $(sed -n 5p "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
		fi

	else

		echo '您可以手动修改vnc的配置信息'
		echo '若需修改vnc密码，请在新窗口下输vncpasswd'
		echo 'If you want to modify the resolution, please change the 720x1440 (default resolution , vertical screen) to another resolution, such as 1920x1080 (landscape).'
		echo '若您想要修改分辨率，请将默认的720x1440（竖屏）改为其它您想要的分辨率，例如1920x1080（横屏）。'
		echo "您当前分辨率为$(sed -n 5p "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"
		echo '改完后按Ctrl+O保存，Ctrl+X退出。'
		echo "Press Enter to confirm."
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		read
		nano /usr/bin/startvnc || nano $(which startvnc)
		echo "您当前分辨率为$(sed -n 5p "$(which startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"
		stopvnc 2>/dev/null
		echo 'Press Enter to return.'
		echo "${YELLOW}按回车键返回。${RESET}"
		read
		DEBIANMENU
	fi

}

############################
MODIFYXSDLCONF() {

	if [ ! -f /usr/bin/startxsdl ]; then
		echo "/usr/bin/startxsdl is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startxsdl,您可能尚未安装图形桌面，是否继续编辑。'
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		read

	fi

	XSDLXSERVER=$(whiptail --title "请选择您要修改的项目" --menu "Choose your option" 15 60 4 \
		"0" "Back to the main menu 返回主菜单" \
		"1" "音频端口 Pulse server port " \
		"2" "显示端口 Display number" \
		"3" "ip address" \
		"4" "手动编辑 Edit manually" \
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
		apt install -y nano
	fi
	nano /usr/bin/startxsdl || nano $(which startxsdl)
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

	TARGET=$(whiptail --inputbox "若xsdl app显示的端口非4712，则您可在此处修改。默认为4712，当前为$(sed -n 4p $(which startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2) \n请以xsdl app显示的pulse server地址的最后几位数字为准，输入完成后按回车键确认。" 20 50 --title "MODIFY PULSE SERVER PORT " 3>&1 1>&2 2>&3)
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
			echo "2s后将自动开始安装"
			sleep 2
			echo
			apt install -y firefox-esr firefox-esr-l10n-zh-cn
		else
			echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
			echo " ${YELLOW}“谢谢您选择了我，我一定会比妹妹向您提供更好的上网服务的！”╰(*°▽°*)╯火狐娘坚定地说道。${RESET} "
			echo "2s后将自动开始安装"
			sleep 2
			apt install -y firefox firefox-l10n-zh-cn
		fi
	else

		echo "${YELLOW}妾身就知道你没有看走眼！${RESET}"
		echo '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium --no-sandbox"'
		echo "2s后将自动开始安装"
		sleep 2
		apt install -y chromium chromium-l10n
		sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
		grep 'chromium' /etc/profile || sed -i '$ a\alias chromium="chromium --no-sandbox"' /etc/profile
		#echo 'alias chromium="chromium --no-sandbox"' >>/etc/profile

	fi
	DEBIANMENU

}
######################################################
INSTALLGUI() {
	INSTALLDESKTOP=$(whiptail --title "单项选择题" --menu \
		"您想要安装哪个桌面？按方向键选择，回车键确认，一次只可以装一个桌面哦！ \n Which desktop environment do you want to install? " 15 60 4 \
		"0" "我一个都不要 =￣ω￣=" \
		"1" "xfce：兼容性高" \
		"2" "lxde：轻量化桌面" \
		"3" "mate：基于GNOME 2" \
		3>&1 1>&2 2>&3)

	##########################
	if [ "$INSTALLDESKTOP" == '1' ]; then
		bash /usr/local/bin/xfce.sh
	fi

	if [ "$INSTALLDESKTOP" == '2' ]; then
		bash /usr/local/bin/lxde.sh
	fi

	if [ "$INSTALLDESKTOP" == '3' ]; then
		bash /usr/local/bin/mate.sh
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

	echo "${YELLOW}按回车键确认卸载,按Ctfl+C取消${RESET} "
	echo 'Press enter to confirm ,press Ctfl + C to cancel'
	read
	apt purge -y xfce4 xfce4-terminal tightvncserver
	apt purge -y lxde-core lxterminal
	apt purge -y mate-desktop-environment-core mate-terminal || aptitude purge -y mate-desktop-environment-core 2>/dev/null
	apt autopurge
	DEBIANMENU
}

REMOVEBROWSER() {
	if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno '火狐娘:“虽然知道总有离别时，但我没想到这一天竟然会这么早。虽然很不舍，但还是很感激您曾选择了我。希望我们下次还会再相遇，呜呜...(;´༎ຶД༎ຶ`)”chromium娘：“哼(￢︿̫̿￢☆)，负心人，走了之后就别回来了！o(TヘTo) 。”  ✨请做出您的选择！' 10 60); then
		echo '呜呜...我...我才...才不会为了这点小事而流泪呢！ヽ(*。>Д<)o゜'
		echo "${YELLOW}按回车键确认卸载firefox,按Ctfl+C取消${RESET} "
		echo 'Press enter to confirm uninstall firefox,press Ctfl + C to cancel'
		read
		apt purge -y firefox-esr firefox-esr-l10n-zh-cn
		apt purge -y firefox firefox-l10n-zh-cn
		apt autopurge
	else
		echo '小声嘀咕：“妾身不在的时候，你一定要好好照顾好自己。” '
		echo "${YELLOW}按回车键确认卸载chromium,按Ctfl+C取消${RESET} "
		echo 'Press enter to confirm uninstall chromium,press Ctfl + C to cancel'
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
		code
	else
		code

	fi

}
##############################################################
INSTALLsynaptic() {
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Install安装" --no-button "Remove移除" --yesno "新立德是一款使用apt的图形化软件包管理工具，您也可以把它理解为软件商店。Synaptic is a graphical package management program for apt. It provides the same features as the apt-get command line utility with a GUI front-end based on Gtk+.它提供与apt-get命令行相同的功能，并带有基于Gtk+的GUI前端。功能：1.安装、删除、升级和降级单个或多个软件包。 2.升级整个系统。 3.管理软件源列表。  4.自定义过滤器选择(搜索)软件包。 5.按名称、状态、大小或版本对软件包进行排序。 6.浏览与所选软件包相关的所有可用在线文档。♪(^∇^*) " 19 50); then

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
		"您想要安装哪个主题？按方向键选择，回车键确认，可安装多主题！ 安装完成后，需手动修改外观设置中的样式和图标。\n Which theme do you want to install? " 15 60 4 \
		"0" "我一个都不要 =￣ω￣=" \
		"1" "ukui：国产优麒麟ukui桌面默认主题" \
		"2" "win10：kali卧底模式主题(仅支持xfce)" \
		3>&1 1>&2 2>&3)

	if [ "$INSTALLTHEME" == '0' ]; then
		DEBIANMENU
	fi

	if [ "$INSTALLTHEME" == '1' ]; then
		apt install ukui-themes
		gtk-update-icon-cache /usr/share/icons/ukui-icon-theme/ 2>/dev/null
		echo "安装完成，如需卸载，请手动输apt purge -y ukui-themes"
	fi

	if [ "$INSTALLTHEME" == '2' ]; then
		Installkaliundercover
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
		if [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
			apt install -y kali-undercover
		else

			wget -O kali-undercover.deb https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover/kali-undercover_2020.2.0_all.deb
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

#################################################
CHECKdependencies
########################################################################
