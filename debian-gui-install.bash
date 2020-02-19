#!/bin/bash

########################################################################
#-- 自动检测相关依赖

CHECKdependencies(){

	dependencies=""


	if [ ! -e /usr/bin/whiptail ]; then
		dependencies="${dependencies} whiptail"
	fi	
		
	
	if [ ! -z "$dependencies" ]; then
	echo "正在安装相关依赖..."
	apt update ; apt install -y ${dependencies} 
	fi
YELLOW=$(printf '\033[33m')
RESET=$(printf '\033[m')

	
    DEBIANMENU
}
####################################################
DEBIANMENU(){
OPTION=$(whiptail --title "输debian-i启动本工具，版本号2020-02" --menu "请使用方向键和回车键进行操作。" 15 60 4 \
"1" "安装图形界面gui" \
"2" "安装浏览器browser" \
"3" "卸载图形界面" \
"4" "卸载浏览器" \
"5" "更新本工具" \
"6" "退出 exit" \
3>&1 1>&2 2>&3)

##############################
if [ "$OPTION" == '1' ]; then

	
    INSTALLGUI
fi

if [ "$OPTION" == '2' ]; then

	installBROWSER

fi

if [ "$OPTION" == '3' ]; then

	
    REMOVEGUI
fi

if [ "$OPTION" == '4' ]; then

	
    REMOVEBROWSER
fi

if [ "$OPTION" == '5' ]; then

wget -qO /usr/local/bin/debian-i 'https://gitee.com/mo2/Termux-Debian/raw/master/debian-gui-install.bash'
echo '更新完成，按回车键返回。'
echo 'Press enter to return.'
chmod +x /usr/local/bin/debian-i
read
bash /usr/local/bin/debian-i 
fi

if [ "$OPTION" == '6' ]; then

	exit

fi

}
#############################################
installBROWSER(){
    if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium"  --yesno "建议在安装完图形界面后，再来选择哦！'(　o=^•ェ•)o　┏━┓'我是火狐娘，选我啦！'♪(^∇^*)' 我是chrome娘的姐姐chromium娘，妾身和那些妖艳的货色不一样，选择妾身就没错呢！'(✿◕‿◕✿)'✨请做出您的选择！ " 10 60) then
        
	    if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox-ESR" --no-button "Firefox"  --yesno " 我是firefox，其实我还有个妹妹叫firefox-esr，您是选我还是选esr? “'(＃°Д°)'姐姐，我可是什么都没听你说啊！” 躲在姐姐背后的ESR瑟瑟发抖地说。✨请做出您的选择！ " 10 60) then 
			#echo 'esr可怜巴巴地说道:“我也想要得到更多的爱。”  '
	#什么乱七八糟的，2333333戏份真多。
	echo '“谢谢您选择了我，我一定会为您提供更好的上网服务的呢！”╰(*°▽°*)╯火狐娘坚定地说道。'
		apt install -y firefox-esr firefox-esr-l10n-zh-cn 
	    else
        apt install -y firefox firefox-l10n-zh-cn		
	    fi
	else
	    
	     echo '${YELLOW}妾身就知道你没有看走眼！${RESET} '
		 echo '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium --no-sandbox"'
		 echo "2s后将自动开始安装"
	     sleep 2
		 apt install -y chromium chromium-l10n
        sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
        grep 'chromium' /etc/profile || echo 'alias chromium="chromium --no-sandbox" >> /etc/profile'
	fi  
		DEBIANMENU
		
}		
######################################################		
INSTALLGUI(){
INSTALLDESKTOP=$(whiptail --title "单项选择题" --menu \
"您想要安装哪个桌面？按方向键选择，回车键确认，一次只可以装一个桌面哦！ \n Which desktop environment do you want to install? " 15 60 4 \
"0" "我一个都不要 =￣ω￣=" \
"1" "xfce：兼容性高" \
"2" "lxde：轻量化桌面" \
"3" "mate：基于GNOME 2" \
3>&1 1>&2 2>&3)

##########################
if [ "$INSTALLDESKTOP" == '1' ]; then	
apt-mark hold udisks2
apt update
echo '即将为您安装思源黑体(中文字体)、xfce4、xfce4-terminal和tightvncserver。'
apt install -y fonts-noto-cjk xfce4 xfce4-terminal tightvncserver
apt clean

mkdir -p ~/.vnc
cd ~/.vnc
cat >xstartup<<-'EndOfFile'
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EndOfFile
chmod +x ./xstartup


cd /usr/bin
cat >startvnc<<-'EndOfFile'
#!/bin/bash
stopvnc >/dev/null 2>&1
export USER=root
export HOME=/root
vncserver -geometry 720x1440 -depth 24 -name remote-desktop :1
echo "正在启动vnc服务,本机默认vnc地址localhost:5901"
echo The LAN VNC address 局域网地址 $(ip -4 -br -c a |tail -n 1 |cut -d '/' -f 1 |cut -d 'P' -f 2):5901
EndOfFile

cd /usr/bin
cat >startxsdl<<-'EndOfFile'
#!/bin/bash
stopvnc >/dev/null 2>&1
export DISPLAY=127.0.0.1:2
export PULSE_SERVER=tcp:127.0.0.1:4713
EndOfFile

cat >stopvnc<<-'EndOfFile'
#!/bin/bash
export USER=root
export HOME=/root
vncserver -kill :1
rm -rf /tmp/.X1-lock
rm -rf /tmp/.X11-unix/X1
pkill Xtightvnc
EndOfFile
chmod +x startvnc stopvnc startxsdl
echo 'The vnc service is about to start for you. The password you entered is hidden.'
echo '即将为您启动vnc服务，您需要输两遍（不可见的）密码。'
echo "When prompted for a view-only password, it is recommended that you enter 'n'"
echo '如果提示view-only,那么建议您输n,选择权在您自己的手上。'
startvnc

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

DEBIANMENU
   
}

REMOVEGUI(){
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



REMOVEBROWSER(){
    if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium"  --yesno '火狐娘:“虽然知道总有离别时，但我没想到这一天竟然会这么早。虽然很不舍，但还是很感激您曾选择了我。希望我们下次还会再相遇，呜呜...(;´༎ຶД༎ຶ`)”chromium娘：“哼(￢︿̫̿￢☆)，负心人，走了之后就别回来了！o(TヘTo) 。”  ✨请做出您的选择！' 10 60)  then
	echo '呜呜...我才...才不会为了这点小事而流泪呢！ヽ(*。>Д<)o゜'
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
########################################################################
CHECKdependencies
########################################################################