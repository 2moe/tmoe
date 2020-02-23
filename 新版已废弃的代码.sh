####################################################################

已废弃选项
mkdir -p /data/data/com.termux/files/usr/etc/storage/
wget -O /data/data/com.termux/files/usr/etc/storage/DebianManager.bash 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh' >/dev/null 2>&1
chmod +x /data/data/com.termux/files/usr/etc/storage/DebianManager.bash
cp -pf /data/data/com.termux/files/usr/etc/storage/DebianManager.bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash >/dev/null

#!/data/data/com.termux/files/usr/bin/bash
if [ ! -d /data/data/com.termux/files/usr/etc/storage/ ]; then
    mkdir -p /data/data/com.termux/files/usr/etc/storage/
fi

if [ ! -e $PREFIX/bin/wget ]; then
    apt update
    apt install -y wget
    wget -qO /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh' >/dev/null 2>&1 && bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash || bash /data/data/com.termux/files/usr/etc/storage/DebianManager.bash || bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash
else
    LAST_MODIFY_TIMESTAMP=$(stat -c %Y /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash)

    DEBIANMANAGERDATE=$(date '+%d' -d @${LAST_MODIFY_TIMESTAMP})
    if [ "${DEBIANMANAGERDATE}" == "$(date '+%d')" ]; then
        bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash || bash /data/data/com.termux/files/usr/etc/storage/DebianManager.bash
    else
        wget -qO /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh' >/dev/null 2>&1 && bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash || bash /data/data/com.termux/files/usr/etc/storage/DebianManager.bash || bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash
    fi
fi

EndOfFile

#下面的EndOfFile不要加单引号
cat >/data/data/com.termux/files/usr/bin/debian-root <<-EndOfFile

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
rm -f /data/data/com.termux/files/usr/bin/debian-root
tsudo debian
EndOfFile

#termux-zsh废弃code

if [ ! -d "$HOME/.termux/fonts/sarasa" ]; then
    rm -rf "$HOME/.termux/fonts"
    cd "$HOME/.termux"
    rm -f ZSHPOWERLINEFONTS.tar.xz 2>/dev/null
    echo "Downloading font archive..."
    echo "正在下载字体压缩包..."
    wget -qO 'https://cdn.tmoe.me/git/TermuxZsh/ZSHPOWERLINEFONTS.tar.xz' || wget -q 'https://m.tmoe.me/down/share/Android/Termux-zsh/ZSHPOWERLINEFONTS.tar.xz'

    echo "正在解压字体文件..."
    tar -Jxvf ZSHPOWERLINEFONTS.tar.xz
    echo 'Deleting font archive...'
    echo '正在删除字体压缩包...'
    rm -f ZSHPOWERLINEFONTS.tar.xz

fi

#zsh主题选择

if (whiptail --title "Choose zsh theme " --yes-button "agnosterzak" --no-button "agnoster" --yesno "Which do yo like better? \n 请选择您需要配置的zsh主题" 10 60); then
	if [ ! -f "$HOME/.oh-my-zsh/themes/agnosterzak.zsh-theme" ]; then

		mkdir -p ~/.oh-my-zsh/themes
		wget -qO ~/.oh-my-zsh/themes/agnosterzak.zsh-theme https://gitee.com/mo2/agnosterzak-ohmyzsh-theme/raw/master/agnosterzak.zsh-theme
	fi
	sed -i 's/ZSH_THEME="agnoster"/ZSH_THEME="agnosterzak"/g' "$HOME/.zshrc"

fi

#zsh下载字体文件
if [ ! -d "$HOME/.termux/fonts/Go" ]; then
	rm -rf "$HOME/.termux/fonts"
	cd "$HOME/.termux"
	rm -f ZSHPOWERLINEFONTS.tar.xz 2>/dev/null
	echo "Downloading font archive..."
	echo "正在下载字体压缩包..."
	#aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://cdn.tmoe.me/git/TermuxZsh/ZSHPOWERLINEFONTS.tar.xz' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true 'https://m.tmoe.me/down/share/Android/Termux-zsh/ZSHPOWERLINEFONTS.tar.xz'

	#echo "正在解压字体文件..."
	tar -Jxvf ZSHPOWERLINEFONTS.tar.xz
	echo 'Deleting font archive...'
	echo '正在删除字体压缩包...'
	rm -f ZSHPOWERLINEFONTS.tar.xz

fi