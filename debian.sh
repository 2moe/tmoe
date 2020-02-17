#!/data/data/com.termux/files/usr/bin/bash


########################################################################
#-- 自动检测相关依赖

autoCheck(){

	dependencies=""

	if [ ! -e $PREFIX/bin/proot ]; then
		dependencies="${dependencies} proot"
	fi
	
	if [ ! -e $PREFIX/bin/wget ]; then
		dependencies="${dependencies} wget"
	fi	
	
	if [ ! -e $PREFIX/bin/pv ]; then
		dependencies="${dependencies} pv"
	fi	
		
	if [ ! -e $PREFIX/bin/xz ]; then
		dependencies="${dependencies} xz-utils"
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

	if [ ! -e $PREFIX/bin/aria2c ]; then
		dependencies="${dependencies} aria2"
	fi


	if [ ! -z "$dependencies" ]; then
	echo "正在安装相关依赖..."
	apt update ; apt install ${dependencies} 
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
MainMenu

}

########################################################################
#-- 主菜单 main menu

MainMenu(){
OPTION=$(whiptail --title "Debian manager running on Termux" --backtitle "输debian-i启动本程序,2020-02,萌系生物研究员,Please use the arrow keys and enter key to operate. 请使用方向键和回车键进行操作。" --menu "请使用方向键和回车键进行操作，Choose your option" 15 60 4 \
"1" "安装install debian" \
"2" "root模式" \
"3" "移除remove system" \
"4" "备份系统backup system" \
"5" "还原restore" \
"6" "退出exit" \
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

	exit

fi

}

########################################################################

installDebian(){
	
	if [ -d ~/debian_* ]; then
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
    chmod 777 -R debian_$archtype
    rm -rf "debian_$archtype" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc $PREFIX/bin/debian-root || tsudo rm -rf "debian_$archtype" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc $PREFIX/bin/debian-root 
    sed -i '/alias debian=/d' $PREFIX/etc/profile
	sed -i '/alias debian-rm=/d' $PREFIX/etc/profile
	source profile >/dev/null 2>&1
	echo 'The debian system has been removed. If you want to uninstall aria2, enter "apt remove aria2" or "apt purge aria2"'
    echo '移除完成，如需卸载aria2,请手动输apt remove aria2'
	echo 'If you want to reinstall, it is not recommended to remove the image file.'
	echo '若您需要重装debian，则不建议删除镜像文件。'
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
mkdir -p /sdcard/backup
cd /sdcard/backup

    if [ -f *.tar.* ]; then
  echo '您当前已备份的系统如下：'  
	ls -lth ./*.tar.* |head -n 10 
    fi
	
	echo $(date +%Y-%m-%d_%H-%M) > backuptime.tmp
	TMPtime=debian_$(cat backuptime.tmp)
	
if (whiptail --title "Select compression type 选择压缩类型 " --yes-button "tar.xz" --no-button "tar.gz" --yesno "Which do yo like better? \n tar.xz压缩率高，但速度慢。\n tar.gz压缩率低，但速度快。\n 压缩过程中，进度条倒着跑是正常现象。" 10 60) then

	echo "您选择了tar.xz,即将为您备份至/sdcard/backup/${TMPtime}.tar.xz"
	echo '按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.'
	read

	tar -PJpcf - ~/${DebianFolder} | (pv -n > ${TMPtime}.tar.xz) 2>&1 | whiptail --gauge "Packaging into tar.xz" 10 70
	
	#xz -z -T0 -e -9 -f -v ${TMPtime}.tar
		echo "部分挂载的目录无权限备份是正常现象。"
	rm -f backuptime.tmp
	ls -lth ./*tar* | grep ^- | head -n 1
	echo '备份完成,按任意键返回。'
    read
   MainMenu
   
else

    echo "您选择了tar.gz,即将为您备份至/sdcard/backup/${TMPtime}.tar.gz"
	echo '按回车键开始备份,按Ctrl+C取消。Press Enter to start the backup.'
	read
	    
	tar -Ppczf - ~/${DebianFolder} | (pv -n > ${TMPtime}.tar.gz) 2>&1 | whiptail --gauge "Packaging into tar.gz \n正在打包成tar.gz" 10 70
	

	echo "部分挂载的目录无权限备份是正常现象。"
	rm -f backuptime.tmp 
	#  whiptail --gauge "正在备份,可能需要几分钟的时间请稍后.........." 6 60 0 
	ls -lth ./*tar* | grep ^- | head -n 1
	echo 'gzip压缩至60%完成是正常现象。'
	echo '备份完成,按任意键返回。'
    read
  MainMenu
   fi
}
####################################
#tar压缩进度条1、2

: '	#tar -czf - ~/${DebianFolder} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)
	
	#tar -cf - ~/${DebianFolder} | pv -s $(du -sb ~/${DebianFolder} | awk '{print $1}') | gzip > ${TMPtime}.tar.gz
	
	#tar Pzcvf ${TMPtime}.tar.gz ~/${DebianFolder}'
	
########################################################################
#
RESTORESYSTEM(){

OPTION=$(whiptail --title "RESTORESYSTEM" --menu "Choose your option" 15 60 4 \
"1" "还原最新备份" \
"2" "Return返回主菜单" \
3>&1 1>&2 2>&3)
###########################################################################
if [ "$OPTION" == '1' ]; then
termux-setup-storage 
    if [ ! -f /sdcard/backup/*tar* ]; then
	   echo '未检测到备份文件,按回车键返回。'
	   read
   MainMenu
	
    else
    echo '目前仅支持还原最新的备份，如需还原旧版，请手动输以下命令'
	
	echo 'cd /sdcard/backup ;ls ; tar -JPxvf 文件名.tar.xz 或 tar -Pzxvf 文件名.tar.gz'
    echo '请注意大小写，并把文件名改成具体名称'
    cd /sdcard/backup
    RESTORE=$(ls -lth ./*tar* | grep ^- | head -n 1 |cut -d '/' -f 2)
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
	
	echo "按回车键返回。Press enter to return."
    read
   MainMenu
	#'下面那个fi对应! -f /sdcard/backup/*tar*'
	fi
fi

   
   if [ "$OPTION" == '2' ]; then

	MainMenu
    fi
}

########################################################################
#
autoCheck
##取消注释，测试用。
##MainMenu