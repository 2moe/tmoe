#!/data/data/com.termux/files/usr/bin/bash


########################################################################
#-- 自动检测相关依赖

autoCheck(){

	dependencies=""


	if [ ! -e $PREFIX/bin/wget ]; then
		dependencies="${dependencies} wget"
	fi	
	
	if [ ! -e $PREFIX/bin/pv ]; then
		dependencies="${dependencies} pv"
	fi	
	
	if [ ! -e $PREFIX/bin/grep ]; then
		dependencies="${dependencies} grep"
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

	if [ ! -e $PREFIX/bin/openssl ]; then
		dependencies="${dependencies} openssl"
	fi

	if [ ! -e $PREFIX/bin/pkill ]; then
		dependencies="${dependencies} procps"
	fi

	if [ ! -e $PREFIX/bin/curl ]; then
		dependencies="${dependencies} curl"
	fi




	if [ ! -z "$dependencies" ]; then
	echo "正在安装相关依赖..."
	apt update ; apt install -y ${dependencies} 
	fi
	
    CheckArch
}

########################################################################
#检测架构
CheckArch(){

    case `uname -m` in
aarch64)
	archtype="arm64" ;;
arm64)
	archtype="arm64" ;;			
arm)
	archtype="armhf" ;;
armhf)
	archtype="armhf" ;;
armel)
	archtype="armel" ;;				
amd64)
	archtype="amd64" ;;
x86_64)
	archtype="amd64" ;;	
i*86)
	archtype="i386" ;;
x86)
	archtype="i386" ;;
*)
	echo "未知的架构 $(uname -m) unknown architecture"; exit 1 ;;
esac

DebianFolder=debian_${archtype}
YELLOW=$(printf '\033[33m')
RESET=$(printf '\033[m')
cur=$(pwd)
MainMenu

}

########################################################################
#-- 主菜单 main menu

MainMenu(){
OPTION=$(whiptail --title "Debian manager running on Termux" --backtitle "$(base64 -d <<-'DoYouWantToSeeWhatIsInside'
6L6TZGViaWFuLWnlkK/liqjmnKznqIvluo8sMjAyMC0wMizokIzns7vnlJ/niannoJTnqbblkZgs
UGxlYXNlIHVzZSB0aGUgYXJyb3cga2V5cyBhbmQgZW50ZXIga2V5IHRvIG9wZXJhdGUuIOivt+S9
v+eUqOaWueWQkemUruWSjOWbnui9pumUrui/m+ihjOaTjeS9nOOA
DoYouWantToSeeWhatIsInside
)" --menu "请使用方向键和回车键进行操作，Choose your option" 15 60 4 \
"1" "安装 install debian" \
"2" "root模式" \
"3" "移除 remove system" \
"4" "备份系统 backup system" \
"5" "还原 restore" \
"6" "查询空间占用 query space occupation" \
"7" "更新本管理器 update debian manager" \
"8" "配置zsh(优化termux) Configure zsh" \
"9" "Download VNC apk" \
"10" "退出 exit" \
3>&1 1>&2 2>&3)

if [ "$OPTION" == '1' ]; then

	installDebian

fi

if [ "$OPTION" == '2' ]; then

	
    RootMode
fi

if [ "$OPTION" == '3' ]; then

	REMOVESYSTEM

fi


if [ "$OPTION" == '4' ]; then

	BackupSystem

fi

if [ "$OPTION" == '5' ]; then

	RESTORESYSTEM

fi

if [ "$OPTION" == '6' ]; then

	SpaceOccupation

fi

if [ "$OPTION" == '7' ]; then

	UPDATEMANAGER
fi

if [ "$OPTION" == '8' ]; then
    bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-zsh/raw/master/termux-zsh.sh')"
   
fi


if [ "$OPTION" == '9' ]; then
     
	 DOWNLOADVNCAPK
   
fi

if [ "$OPTION" == '10' ]; then
    exit
   
fi

}

########################################################################

installDebian(){
		
		
	if [ ! -e $PREFIX/bin/aria2c ]; then
		apt update ;apt install -y aria2
	 fi
	
	if [ ! -e $PREFIX/bin/proot ]; then
		apt update ;apt install -y proot
	fi
	
	if [ -d ~/${DebianFolder} ]; then
	printf "${YELLOW}检测到您已安装debian,是否重新安装？[Y/n]${RESET} "
	#分行
    echo ''
	echo "Detected that you have debian installed, do you want to reinstall it?[Y/n]"
	read opt
	case $opt in
		y*|Y*|"") $PREFIX/bin/debian-rm && sed -i '/alias debian=/d' $PREFIX/etc/profile ; sed -i '/alias debian-rm=/d' $PREFIX/etc/profile ;source profile >/dev/null 2>&1 ; bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/installDebian.sh')"	 ;;
		n*|N*) echo "skipped." ; read ;MainMenu ;;
		*) echo "Invalid choice. skipped.";read ;MainMenu ;;
	esac
	
	else
	    bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/installDebian.sh')"	
    fi

 
}

########################################################################
#

 RootMode(){
 if (whiptail --title "您真的要开启root模式吗" --yes-button '好哒o(*￣▽￣*)o' --no-button '不要(っ °Д °；)っ' --yesno "开启后将无法撤销，除非重装debian，建议您在开启前进行备份。若您的手机存在外置tf卡，则在开启后，会挂载整张卡。若无法备份和还原，请输tsudo debian-i启动本管理器。开启root模式后，绝对不要输破坏系统的危险命令！若在debian系统内输rm -rf /*删除根目录（格式化）命令，将有可能导致安卓原系统崩溃！！！请在本管理器内正常移除debian。" 10 60) then 
 
if [ ! -f /data/data/com.termux/files/usr/bin/tsu ]; then
        apt update
		apt install -y tsu
		fi
		
mkdir -p /data/data/com.termux/files/usr/etc/storage/
cd /data/data/com.termux/files/usr/etc/storage/

rm -rf external-tf

tsu -c 'ls /mnt/media_rw/*' 2>/dev/null || mkdir external-tf

TFcardFolder=$(tsu -c 'ls /mnt/media_rw/| head -n 1')

tsudo ln -s /mnt/media_rw/${TFcardFolder}  ./external-tf

sed -i 's:/home/storage/external-1:/usr/etc/storage/external-tf:g' /data/data/com.termux/files/usr/bin/debian


cd $PREFIX/etc/
if [ ! -f profile ]; then
        touch profile
		fi
cp -pf profile profile.bak

grep 'alias debian=' profile >/dev/null 2>&1 || sed -i  '$ a\alias debian="tsudo debian"' profile
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
echp '2s后将为您自动启动debian'
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
REMOVESYSTEM(){
    
	cd ~
	echo 'Detecting Debian system footprint... 正在检测debian系统占用空间大小'
	du -sh ./${DebianFolder} --exclude=./${DebianFolder}/root/tf --exclude=./${DebianFolder}/root/sd --exclude=./${DebianFolder}/root/termux
	if [ ! -d ~/${DebianFolder} ]; then
	printf "${YELLOW}Detected that you are not currently installed 检测到您当前未安装debian{RESET} "
	fi
	echo "${YELLOW}按回车键确认移除,按Ctrl+C取消 Press enter to confirm.${RESET} "
	read 
	
    chmod 777 -R ${DebianFolder}
    rm -rf "debian_$archtype" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc 2>/dev/null || tsudo rm -rf "debian_$archtype" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc 2>/dev/null
    sed -i '/alias debian=/d' $PREFIX/etc/profile
	sed -i '/alias debian-rm=/d' $PREFIX/etc/profile
	source profile >/dev/null 2>&1
	echo 'The debian system has been removed. If you want to uninstall aria2, enter "apt remove aria2" or "apt purge aria2"'
    echo '移除完成，如需卸载aria2,请手动输apt remove aria2'
	echo '其它相关依赖，如pv、dialog、openssl、procps、proot、wget、curl等，均需手动卸载。'
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
		y*|Y*|"") rm -f ~/debian-sid-rootfs.tar.xz $PREFIX/bin/debian-rm && echo "Deleted已删除" ;;
		n*|N*) echo "skipped." ;;
		*) echo "Invalid choice. skipped." ;;
	esac
	MainMenu

}
########################################################################
#
BackupSystem(){
termux-setup-storage
OPTION=$(whiptail --title "Backup System" --menu "Choose your option" 15 60 4 \
"0" "Back to the main menu 返回主菜单" \
"1" "备份Debian" \
"2" "备份Termux" \
3>&1 1>&2 2>&3)
###########################################################################
if [ "$OPTION" == '1' ]; then 
	if [ ! -d /sdcard/backup ]; then
	    mkdir -p /sdcard/backup && cd /sdcard/backup
	else
        cd /sdcard/backup
    fi		
	
	
	

	ls -lth ./debian*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'
	
	echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
	read
	
	echo $(date +%Y-%m-%d_%H-%M) > backuptime.tmp
	TMPtime=debian_$(cat backuptime.tmp)
	
    if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60) then

	echo "您选择了tar.xz,即将为您备份至/sdcard/backup/${TMPtime}.tar.xz"
	echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
	read

	tar -PJpcf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} | (pv -n > ${TMPtime}.tar.xz) 2>&1 | whiptail --gauge "Packaging into tar.xz" 10 70
	
	#xz -z -T0 -e -9 -f -v ${TMPtime}.tar
	echo "Don't worry too much, it is normal for some directories to backup without permission."
	echo "部分目录无权限备份是正常现象。"
	rm -f backuptime.tmp
	pwd
	ls -lth ./*tar* | grep ^- | head -n 1
	echo '备份完成,按任意键返回。'
    read
   MainMenu
   
    else

    echo "您选择了tar.gz,即将为您备份至/sdcard/backup/${TMPtime}.tar.gz"
	echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
	read
	    
	tar -Ppczf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux   ~/${DebianFolder}  | (pv -n > ${TMPtime}.tar.gz) 2>&1 | whiptail --gauge "Packaging into tar.gz \n正在打包成tar.gz" 10 70
	

	echo "Don't worry too much, it is normal for some directories to backup without permission."
	echo "部分目录无权限备份是正常现象。"
	rm -f backuptime.tmp 
	#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0 
	pwd
	ls -lth ./*tar* | grep ^- | head -n 1
	echo 'gzip压缩至60%完成是正常现象。'
	echo '备份完成,按任意键返回。'
    read
    MainMenu
    fi
fi   
###################
if [ "$OPTION" == '2' ]; then 
     BACKUPTERMUX
	 
fi
   
##########################################
   if [ "$OPTION" == '0' ]; then

	MainMenu
    fi
	MainMenu
}


BACKUPTERMUX(){	 
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
        
  	if [ ! -d /sdcard/backup ]; then
	    mkdir -p /sdcard/backup && cd /sdcard/backup
	else
        cd /sdcard/backup
    fi		
	
	##tar -czf - ~/${DebianFolder} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

	ls -lth ./termux-home*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'
	
	#echo 'This operation will only backup the home directory of termux, not the debian system. If you need to backup debian, please select both options or backup debian separately.'
	#echo '本次操作将只备份termux的主目录，不包含主目录下的debian系统。如您需备份debian,请同时选择home和usr，或单独备份debian。'
	
	echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
	read
	
	echo $(date +%Y-%m-%d_%H-%M) > backuptime.tmp
	TMPtime=termux-home_$(cat backuptime.tmp)
	
    if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz"  --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60) then

	echo "您选择了tar.xz,即将为您备份至/sdcard/backup/${TMPtime}.tar.xz"
	echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
	read
	
	tar -PJpvcf ${TMPtime}.tar.xz --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/sd --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/termux --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/tf /data/data/com.termux/files/home
	
	#xz -z -T0 -e -9 -v ${TMPtime}.tar
	
	echo "Don't worry too much, it is normal for some directories to backup without permission."
	echo "部分目录无权限备份是正常现象。"
	rm -f backuptime.tmp
	pwd
	ls -lth ./termux-home*tar* | grep ^- | head -n 1
	echo '备份完成,按任意键返回。'
    read
   MainMenu
   
    else

    echo "您选择了tar.gz,即将为您备份至/sdcard/backup/${TMPtime}.tar.gz"
	echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
	read
	    
	tar -Ppvczf ${TMPtime}.tar.gz --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/sd --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/termux --exclude=/data/data/com.termux/files/home/${DebianFolder}/root/tf /data/data/com.termux/files/home
	

	echo "Don't worry too much, it is normal for some directories to backup without permission."
	echo "部分目录无权限备份是正常现象。"
	rm -f backuptime.tmp 
	#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0 
	pwd
	ls -lth ./termux-home*tar* | grep ^- | head -n 1
	echo '备份完成,按任意键返回。'
    read
    MainMenu
    fi
  
        
		
		
		
		
		fi
##########################
    	if [ "$TERMUXBACKUP" == 'usr' ]; then
         
  	if [ ! -d /sdcard/backup ]; then
	    mkdir -p /sdcard/backup && cd /sdcard/backup
	else
        cd /sdcard/backup
    fi		
	


	ls -lth ./termux-usr*.tar.* 2>/dev/null  && echo '您之前所备份的(部分)文件如上所示'
	
	echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
	read
	
	echo $(date +%Y-%m-%d_%H-%M) > backuptime.tmp
	TMPtime=termux-usr_$(cat backuptime.tmp)
	
    if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz"  --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ration, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60) then

	echo "您选择了tar.xz,即将为您备份至/sdcard/backup/${TMPtime}.tar.xz"
	echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
	read
	
	#tar -PJpcf ${TMPtime}.tar /data/data/com.termux/files/usr
	echo '正在压缩成tar.xz'
	tar -PJpcf - /data/data/com.termux/files/usr | (pv -p --timer --rate --bytes > ${TMPtime}.tar.xz)
	#echo '正在压缩成xz'
	#xz -z -T0 -e -9 -v ${TMPtime}.tar
	
	echo "Don't worry too much, it is normal for some directories to backup without permission."
	echo "部分目录无权限备份是正常现象。"
	rm -f backuptime.tmp
	pwd
	ls -lth ./termux-usr*tar* | grep ^- | head -n 1
	echo '备份完成,按任意键返回。'
    read
   MainMenu
   
    else

    echo "您选择了tar.gz,即将为您备份至/sdcard/backup/${TMPtime}.tar.gz"
	echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
	read
	    
	#tar -Ppczf ${TMPtime}.tar.gz   /data/data/com.termux/files/usr
	tar -Ppczf - /data/data/com.termux/files/usr | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)
		##tar -czf - ~/${DebianFolder} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

	echo "Don't worry too much, it is normal for some directories to backup without permission."
	echo "部分目录无权限备份是正常现象。"
	rm -f backuptime.tmp 
	#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0 
	pwd
	ls -lth ./*tar* | grep ^- | head -n 1
	echo '备份完成,按任意键返回。'
    read
    MainMenu
    fi
  
        
		
		
		
		
		
		
		fi		
##########################
    	if [ "$TERMUXBACKUP" == 'home usr' ]; then
        
        
  	if [ ! -d /sdcard/backup ]; then
	    mkdir -p /sdcard/backup && cd /sdcard/backup
	else
        cd /sdcard/backup
    fi		
	


	ls -lth ./termux-home+usr*.tar.* 2>/dev/null && echo '您之前所备份的(部分)文件如上所示'
	
	echo "${YELLOW}按回车键选择压缩类型 Press enter to select compression type${RESET} "
	read
	
	echo $(date +%Y-%m-%d_%H-%M) > backuptime.tmp
	TMPtime=termux-home+usr_$(cat backuptime.tmp)
	
    if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz"  --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。tar.xz has a higher compression ratio, but is slower.\n tar.gz速度快,但压缩率低。tar.gz compresses faster, but with a lower compression ratio.\n 压缩过程中，进度条倒着跑是正常现象。" 10 60) then
	echo "您选择了tar.xz,即将为您备份至/sdcard/backup/${TMPtime}.tar.xz"
	echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
	read
	
	#tar -PJpcf ${TMPtime}.tar /data/data/com.termux/files/usr
	echo '正在压缩成tar.xz'
	tar -PJpcf - /data/data/com.termux/files/home /data/data/com.termux/files/usr | (pv -p --timer --rate --bytes > ${TMPtime}.tar.xz)
	#echo '正在压缩成xz'
	#xz -z -T0 -e -9 -v ${TMPtime}.tar
	
	echo "Don't worry too much, it is normal for some directories to backup without permission."
	echo "部分目录无权限备份是正常现象。"
	rm -f backuptime.tmp
	pwd
	ls -lth ./termux-home+usr*tar* | grep ^- | head -n 1
	echo '备份完成,按任意键返回。'
    read
   MainMenu
   
    else

    echo "您选择了tar.gz,即将为您备份至/sdcard/backup/${TMPtime}.tar.gz"
	echo "${YELLOW}按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.${RESET} "
	read
	    
	#tar -Ppczf ${TMPtime}.tar.gz   /data/data/com.termux/files/usr
	tar -Ppczf - /data/data/com.termux/files/home /data/data/com.termux/files/usr | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)
		##tar -czf - ~/${DebianFolder} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

	echo "Don't worry too much, it is normal for some directories to backup without permission."
	echo "部分目录无权限备份是正常现象。"
	rm -f backuptime.tmp 
	#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0 
	pwd
	ls -lth ./termux-home+usr*tar* | grep ^- | head -n 1
	echo '备份完成,按任意键返回。'
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
RESTORESYSTEM(){

OPTION=$(whiptail --title "Restore System" --menu "Choose your option" 15 60 4 \
"0" "Back to the main menu 返回主菜单" \
"1" "Restore the latest debian backup 还原Debian" \
"2" "Restore the latest termux backup 还原Termux" \
3>&1 1>&2 2>&3)
###########################################################################
if [ "$OPTION" == '1' ]; then
termux-setup-storage 
    cd /sdcard/backup
	ls -lth debian*tar* |head -n 10 2>/dev/null  || echo '未检测到备份文件'
   
    echo '目前仅支持还原最新的备份，如需还原旧版，请手动输以下命令' 
	
	echo 'cd /sdcard/backup ;ls ; tar -JPxvf 文件名.tar.xz 或 tar -Pzxvf 文件名.tar.gz'
    echo '请注意大小写，并把文件名改成具体名称'

    RESTORE=$(ls -lth ./debian*tar* | grep ^- | head -n 1 |cut -d '/' -f 2)
    echo " " 
	ls -lh ${RESTORE}
	printf "${YELLOW}即将为您还原${RESTORE}，请问是否确认？[Y/n]${RESET} "
	#printf之后分行
	echo ''
	echo 'Do you want to restore it?[Y/n]'

    read opt
	case $opt in
		y*|Y*|"")   
		
     #0-6是截取字符
     if [ "${RESTORE:0-6:6}" == 'tar.xz' ]; then
	 echo 'tar.xz'
          pv  ${RESTORE} | tar -PJx    		  
		fi
		
	if [ "${RESTORE:0-6:6}" == 'tar.gz' ]; then
	echo 'tar.gz'
          pv  ${RESTORE} | tar -Pzx 
		fi
		  	
		
		;;


		n*|N*) echo "skipped." ;;
		*) echo "Invalid choice. skipped." ;;
		
		
		#tar xfv $pathTar -C $path
		#(pv -n $pathTar | tar xfv $pathTar -C $path ) 2>&1 | dialog --gauge "Extracting file..." 6 50
		
		
	esac
	
	echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
    read
   MainMenu

fi


###################
if [ "$OPTION" == '2' ]; then 



termux-setup-storage 
    cd /sdcard/backup
	ls -lth termux*tar* 2>/dev/null  || echo '未检测到备份文件'  |head -n 10  
   
    echo '目前仅支持还原最新的备份，如需还原旧版，请手动输以下命令' 
	
	echo 'cd /sdcard/backup ;ls ; tar -JPxvf 文件名.tar.xz 或 tar -Pzxvf 文件名.tar.gz'
    echo '请注意大小写，并把文件名改成具体名称'

    RESTORE=$(ls -lth ./termux*tar* | grep ^- | head -n 1 |cut -d '/' -f 2)
    echo " " 
	ls -lh ${RESTORE}
	printf "${YELLOW}即将为您还原${RESTORE}，请问是否确认？[Y/n]${RESET} "
	#printf之后分行
	echo ''
	echo 'Do you want to restore it?[Y/n]'

    read opt
	case $opt in
		y*|Y*|"")   
		

     if [ "${RESTORE:0-6:6}" == 'tar.xz' ]; then
	 echo 'tar.xz'
          pv  ${RESTORE} | tar -PJx    		  
		fi
		
	if [ "${RESTORE:0-6:6}" == 'tar.gz' ]; then
	echo 'tar.gz'
          pv  ${RESTORE} | tar -Pzx 
		fi
		  	
		
		;;


		n*|N*) echo "skipped." ;;
		*) echo "Invalid choice. skipped." ;;
		
		
		#tar xfv $pathTar -C $path
		#(pv -n $pathTar | tar xfv $pathTar -C $path ) 2>&1 | dialog --gauge "Extracting file..." 6 50
		
		
	esac
	
	echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
    read
   MainMenu

fi


#####################################   
   if [ "$OPTION" == '0' ]; then

	MainMenu
    fi
	MainMenu
}

########################################################################
SpaceOccupation(){
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
if [ "$OPTION" == '1' ]; then
echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
echo "${YELLOW}主目录 TOP15${RESET}"

du -hsx ./home/* ./home/.*  2>/dev/null  | sort -rh| head -n 15

echo ''

echo "${YELLOW}usr 目录 TOP6${RESET}"

du -hsx ./usr/* 2>/dev/null  | sort -rh| head -n 6

echo ''

echo "${YELLOW}usr/lib 目录 TOP8${RESET}"

du -hsx ./usr/lib/* 2>/dev/null  | sort -rh| head -n 8

echo '' 

echo "${YELLOW}usr/share 目录 TOP8${RESET}"

du -hsx ./usr/share/* 2>/dev/null  | sort -rh| head -n 8

echo '' 
	echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
    read
   SpaceOccupation

fi
###############################
if [ "$OPTION" == '2' ]; then
echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
echo "${YELLOW}termux 文件大小排行榜(30名)${RESET}"

find ./ -type f -print0 2>/dev/null | xargs -0 du | sort -n | tail -30 | cut -f2 | xargs -I{} du -sh {}
	echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
    read
   SpaceOccupation

fi

if [ "$OPTION" == '3' ]; then
cd /sdcard
echo '正在加载中，可能需要几秒钟时间，加载时间取决于文件数量和闪存读写速度。'
echo 'Loading may take several seconds, depending on the number of files and the UFS or emmc flash read and write speed.'
echo "${YELLOW}sdcard 目录 TOP15${RESET}"
du -hsx ./* ./.* 2>/dev/null  | sort -rh| head -n 15

echo "${YELLOW}sdcard文件大小排行榜(30名)${RESET}"

find ./ -type f -print0 2>/dev/null | xargs -0 du | sort -n | tail -30 | cut -f2 | xargs -I{} du -sh {}

	echo "${YELLOW}按回车键返回。Press enter to return.${RESET}"
    read
   SpaceOccupation
fi

if [ "$OPTION" == '4' ]; then
echo "${YELLOW}Disk usage${RESET}"
df -h |grep G |grep -v tmpfs
	echo "${YELLOW}按回车键返回。Press enter to return.${RESET} "
    read
   SpaceOccupation
fi

#####################################   
   if [ "$OPTION" == '0' ]; then

	MainMenu
    fi
	
	
   MainMenu

}


########################################################################
UPDATEMANAGER(){

wget -qO $PREFIX/bin/debian-i 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh'
echo "${YELLOW}更新完成，按回车键返回。${RESET}"
echo 'Press enter to return.'
chmod +x $PREFIX/bin/debian-i
read
bash $PREFIX/bin/debian-i

}
#################################
DOWNLOADVNCAPK(){
         cd /sdcard/Download || mkdir -p /sdcard/Download && cd /sdcard/Download
    if (whiptail --title "您想要下载哪个软件?" --yes-button 'VNC Viewer' --no-button 'XServer XSDL' --yesno "vnc操作体验更好,但默认情况下不支持声音。xsdl支持声音，但操作体验没有vnc好。" 10 60) then 
        echo 'Press the Enter key to start the download, and press Ctrl + C to cancel.'
	    echo '按回车键开始下载，按Ctrl+C取消。'
		read 
		echo 'Downloading vnc viewer...'
		rm -f vnc36142089.tar* 2>/dev/null || rm -f "vnc36142089.tar*" 2>/dev/null
		echo '正在为您下载至/sdcard/Download目录...'
		echo 'Download size 11.1MB'
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar00
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar01
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar02
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar03
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar04
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar05
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar06
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar07
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar08
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar09
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar10
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/vnc/vnc36142089.tar11
        cat vnc36142089.tar* >vnc36142089.tar.xz		
		echo '正在解压...'
	    tar -Jxvf vnc36142089.tar.xz
        echo '正在删除压缩包...'
        echo 'Deleting vnc36142089.tar.xz...'
        rm -f vnc36142089.tar* || rm -f "vnc36142089.tar*"	
        rm -f vnc36142089.tar.xz  
		am start -n com.android.documentsui/com.android.documentsui.ViewDownloadsActivity
		echo '解压成功，请进入下载目录，手动安装。'
		echo '文件名称 VNC Viewer_com,realvnc,viewer,android_3,6,1,42089.apk'
		cd ${cur}
	else
        echo 'Press the Enter key to start the download, and press Ctrl + C to cancel.'
	    echo '按回车键开始下载，按Ctrl+C取消。'
		read 
        echo 'Downloading xsdl...'
		rm -f xsdl12041.tar* 2>/dev/null ||  rm -f "xsdl12041.tar*" 2>/dev/null
        echo '正在为您下载至/sdcard/Download目录...'
		echo 'Download size 28.3MB'
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar00 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar01 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar02 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar03 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar04 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar05 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar06 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar07 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar08 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar09 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar10 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar11 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar12 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar13 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar14 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar15 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar16 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar17 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar18 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar19 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar20 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar21 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar22 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar23 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar24 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar25 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar26 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar27 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar28 
        wget -q https://gitee.com/mo2/VncClient/raw/master/Android/xsdl/xsdl12041.tar29 
		cat xsdl12041.tar* >xsdl12041.tar.xz
		echo '正在解压...'
	    tar -Jxvf xsdl12041.tar.xz
        echo '正在删除压缩包...'
        echo 'Deleting xsdl12041.tar.xz...'	
        rm -f xsdl12041.tar* ||  rm -f "xsdl12041.tar*"		
        rm -f xsdl12041.tar.xz 
		echo '解压成功，请进入下载目录，手动安装。'
		echo '文件名称 XServer XSDL_x,org,server_1,20,41.apk'
		am start -n com.android.documentsui/com.android.documentsui.ViewDownloadsActivity
        cd ${cur}
	fi     

}
#########################################
autoCheck
##取消注释，测试用。
##MainMenu