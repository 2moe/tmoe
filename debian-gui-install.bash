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
"1" "install gui 安装图形界面" \
"2" "install browser 安装浏览器" \
"3" "remove gui 卸载图形界面" \
"4" "remove browser 卸载浏览器" \
"5" "update debian tool 更新本工具" \
"6" "Modify to Kali source list 配置kali源"  \
"7" "Restore to debian source list 还原debian源" \
"8" "install chinese manual 安装中文手册" \
"9" "Reconfigure zsh 重新配置zsh" \
"10" "exit 退出" \
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
echo "${YELLOW}更新完成，按回车键返回。${RESET}"
echo 'Press enter to return.'
chmod +x /usr/local/bin/debian-i
read
bash /usr/local/bin/debian-i 
fi
################
if [ "$OPTION" == '6' ]; then

	bash /usr/local/bin/kali.sh

fi

if [ "$OPTION" == '7' ]; then

	bash /usr/local/bin/kali.sh rm

fi
############
if [ "$OPTION" == '8' ]; then

	bash /usr/local/bin/man.sh

fi
##################
if [ "$OPTION" == '9' ]; then

	bash /usr/local/bin/zsh.sh

fi
#################################
if [ "$OPTION" == '10' ]; then

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
	    
	     echo "${YELLOW}妾身就知道你没有看走眼！${RESET}"
		 echo '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium --no-sandbox"'
		 echo "2s后将自动开始安装"
	     sleep 2
		 apt install -y chromium chromium-l10n
        sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
        grep 'chromium' /etc/profile || echo 'alias chromium="chromium --no-sandbox"' >> /etc/profile
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