####################################################################
#已废弃的内容
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

#中文手册
cat >man.sh <<-'EndOfFile'
#!/bin/bash
function install()
{
YELLOW=$(printf '\033[33m')
RESET=$(printf '\033[m')
echo '即将为您安装 debian-reference-zh-cn、manpages、manpages-zh和man-db'
apt install -y debian-reference-zh-cn manpages manpages-zh man-db 
echo "man一款帮助手册软件，它可以帮助您了解关于命令的详细用法。"
echo "man a help manual software, which can help you understand the detailed usage of the command."
echo "您可以输man 软件或命令名称来获取帮助信息，例如${YELLOW}man bash${RESET}或man zsh"

}
function remove()
{
apt purge -y manpages manpages-zh man-db
apt autopurge
}
function main()
{
                case "$1" in
                install|in|i)
                        install
                            ;;
                remove|rm|uninstall|un|purge)
                         remove
                        ;;
                   *)
			        install
			         ;;


        esac
}
main "$@"

EndOfFile
chmod +x man.sh
##################
if [ "${OPTION}" == '9' ]; then

    bash /usr/local/bin/zsh.sh

fi
################################################################
注销时自动卸载挂载目录
cat >.CHROOTtmplogout <<-'EndOfFile'
	umount -lf ${DebianCHROOT}/dev >/dev/null 2>&1 ||su -c "umount -lf ${DebianCHROOT}/dev >/dev/null 2>&1"
	umount -lf ${DebianCHROOT}/dev/shm  >/dev/null 2>&1 || su -c "umount -lf ${DebianCHROOT}/dev/shm  >/dev/null 2>&1"
	umount -lf ${DebianCHROOT}/dev/pts  >/dev/null 2>&1 || su -c "umount -lf ${DebianCHROOT}/dev/pts  >/dev/null 2>&1"
	umount -lf ${DebianCHROOT}/proc  >/dev/null 2>&1 || su -c "	umount -lf ${DebianCHROOT}/proc  >/dev/null 2>&1"
	umount -lf ${DebianCHROOT}/sys  >/dev/null 2>&1 || su -c "umount -lf ${DebianCHROOT}/sys  >/dev/null 2>&1"
	umount -lf ${DebianCHROOT}/tmp  >/dev/null 2>&1 || su -c "umount -lf ${DebianCHROOT}/tmp  >/dev/null 2>&1"
	umount -lf ${DebianCHROOT}/root/sd  >/dev/null 2>&1 || su -c "umount -lf ${DebianCHROOT}/root/sd  >/dev/null 2>&1 "
	umount -lf ${DebianCHROOT}/root/tf  >/dev/null 2>&1 || su -c "umount -lf ${DebianCHROOT}/root/tf  >/dev/null 2>&1"
	umount -lf ${DebianCHROOT}/root/termux >/dev/null 2>&1 || su -c "umount -lf ${DebianCHROOT}/root/termux >/dev/null 2>&1"
EndOfFile
cat .CHROOTtmplogout >>${DebianCHROOT}/root/.bash_logout
cat .CHROOTtmplogout >>${DebianCHROOT}/root/.zlogout
rm -f .CHROOTtmplogout
####################################################

####################################
if [ "${OPTION}" == '10' ]; then

    MODIFYXSDLCONF

fi
###################################################
MODIFYVNCORXSDLCONF() {
    if (whiptail --title "您想要对哪个小可爱下手呢 " --yes-button "VNC" --no-button "XSDL" --yesno "Which remote desktop configuration file do you want to modify？  ♪(^∇^*) " 8 50); then

        MODIFYVNCCONF
    else
        MODIFYXSDLCONF
    fi

}
#############################################
#下面那种压缩方式会有问题！
#xz -z -T0 -e -9 -v -f ${TMPtime}.tar
#tar -PJpcf - --exclude=~/${DebianFolder}/root/sd --exclude=~/${DebianFolder}/root/tf --exclude=~/${DebianFolder}/root/termux ~/${DebianFolder} $PREFIX/bin/debian | (pv -p --timer --rate --bytes >${TMPtime}.tar.xz)
#################################
#自动选择键盘布局可能会出问题(可能废弃)
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
echo keyboard-configuration keyboard-configuration/layout select 'English (US)' | debconf-set-selections
echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
###过渡期间移动文件，之后已经集成进脚本里。
if [ ! -e "/etc/tmp/xfce.sh" ]; then
    mkdir -p /etc/tmp
    cd /usr/local/bin
    mv -f xfce.sh mate.sh lxde.sh kali.sh /etc/tmp/ >/dev/null 2>&1
fi
########################
cat >xfce.sh <<-'Matryoshka'
#!/bin/bash
function install()
{
apt-mark hold udisks2
apt update
echo '即将为您安装思源黑体(中文字体)、xfce4、xfce4-terminal、xfce4-goodies和tightvncserver等软件包。'
apt install -y fonts-noto-cjk xfce4 xfce4-terminal xfce4-goodies tightvncserver
apt install -y xfwm4-theme-breeze  xcursor-themes
apt clean

mkdir -p ~/.vnc
cd ~/.vnc
cat >xstartup<<-'EndOfFile'
#!/bin/bash
xrdb ${HOME}/.Xresources
export PULSE_SERVER=127.0.0.1
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
#上面那条显示LAN IP的命令不要加双引号


cat >startxsdl<<-'EndOfFile'
#!/bin/bash
stopvnc >/dev/null 2>&1
export DISPLAY=127.0.0.1:0
export PULSE_SERVER=tcp:127.0.0.1:4712
echo '正在为您启动xsdl,请将display number改为0'
echo 'Starting xsdl, please change display number to 0'
echo '默认为前台运行，您可以按Ctrl+C终止，或者在termux原系统内输stopvnc'
echo 'The default is to run in the foreground, you can press Ctrl + C to terminate, or type "stopvnc" in the original termux system.'
startxfce4
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
echo '请输入6至8位密码'
startvnc
echo '您之后可以输startvnc来启动vnc服务，输stopvnc停止'
echo '您还可以在termux原系统里输startxsdl来启动xsdl，按Ctrl+C或在termux原系统里输stopvnc停止进程'
echo '若xsdl音频端口不是4712，而是4713，则请输xsdl-4713进行修复。'
}
function remove()
{
apt purge -y xfce4 xfce4-terminal tightvncserver
apt purge -y ^xfce
apt autopurge
}
function main()
{
                case "$1" in
                install|in|i)
                        install
                            ;;
                remove|rm|uninstall|un|purge)
                         remove
                        ;;
                    help|man)
                        man xfce-session 2>&1 >/dev/null
						xfce-session --help
                        ;;

                   *)
			        install
			         ;;


        esac
}

main "$@"
Matryoshka
chmod +x xfce.sh

cat >lxde.sh <<-'Matryoshka'
#!/bin/bash
function install()
{
apt-mark hold udisks2
apt update
echo '即将为您安装思源黑体(中文字体)、lxde-core、lxterminal、tightvncserver。'
apt install -y fonts-noto-cjk lxde-core lxterminal tightvncserver
apt clean

mkdir -p ~/.vnc
cd ~/.vnc
cat >xstartup<<-'EndOfFile'
#!/bin/bash
xrdb ${HOME}/.Xresources
export PULSE_SERVER=127.0.0.1
startlxde &
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

#############
cat >startxsdl<<-'EndOfFile'
#!/bin/bash
stopvnc >/dev/null 2>&1
export DISPLAY=127.0.0.1:0
export PULSE_SERVER=tcp:127.0.0.1:4712
echo '正在为您启动xsdl,请将display number改为0'
echo 'Starting xsdl, please change display number to 0'
echo '默认为前台运行，您可以按Ctrl+C终止，或者在termux原系统内输stopvnc'
echo 'The default is to run in the foreground, you can press Ctrl + C to terminate, or type "stopvnc" in the original termux system.'
startlxde
EndOfFile


##############
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
echo '请输入6至8位密码'
startvnc
echo '您之后可以输startvnc来启动vnc服务，输stopvnc停止'
echo '您还可以在termux原系统里输startxsdl来启动xsdl，按Ctrl+C或在termux原系统里输stopvnc停止进程'
echo '若xsdl音频端口不是4712，而是4713，则请输xsdl-4713进行修复。'
}

function remove()
{
   apt purge -y lxde-core lxterminal tightvncserver
   apt purge -y ^lxde
   apt autopurge
}

function main()
{
                case "$1" in
                install|in|i)
                        install
                            ;;
                remove|rm|uninstall|un|purge)
                         remove
                        ;;
                    help|man)
                        man lxde-session 2>&1 >/dev/null
						lxde-session --help
                        ;;

                   *)
			        install
			         ;;


        esac
}


main "$@"

Matryoshka
chmod +x lxde.sh

cat >mate.sh <<-'Matryoshka'
#!/bin/bash
function install()
{
apt-mark hold udisks2
apt update
echo '即将为您安装思源黑体(中文字体)、tightvncserver、mate-desktop-environment-core和mate-terminal等软件包'
apt install -y aptitude
mkdir -p /run/lock /var/lib/aptitude
touch /var/lib/aptitude/pkgstates
aptitude install -y mate-desktop-environment-core mate-terminal 2>/dev/null || apt install -y mate-desktop-environment-core mate-terminal 2>/dev/null
apt install -y fonts-noto-cjk tightvncserver
apt clean

mkdir -p ~/.vnc
cd ~/.vnc
cat >xstartup<<-'EndOfFile'
#!/bin/bash
xrdb ${HOME}/.Xresources
export PULSE_SERVER=127.0.0.1
mate-session &
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

#############
cat >startxsdl<<-'EndOfFile'
#!/bin/bash
stopvnc >/dev/null 2>&1
export DISPLAY=127.0.0.1:0
export PULSE_SERVER=tcp:127.0.0.1:4712
echo '正在为您启动xsdl,请将display number改为0'
echo 'Starting xsdl, please change display number to 0'
echo '默认为前台运行，您可以按Ctrl+C终止，或者在termux原系统内输stopvnc'
echo 'The default is to run in the foreground, you can press Ctrl + C to terminate, or type "stopvnc" in the original termux system.'
mate-session
EndOfFile


##############
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
dpkg --configure -a 
#暂不卸载。若卸载则将破坏其依赖关系。
#umount .gvfs
#apt purge "gvfs*" "udisks2*"
echo 'The vnc service is about to start for you. The password you entered is hidden.'
echo '即将为您启动vnc服务，您需要输两遍（不可见的）密码。'
echo "When prompted for a view-only password, it is recommended that you enter 'n'"
echo '如果提示view-only,那么建议您输n,选择权在您自己的手上。'
echo '请输入6至8位密码'
startvnc
echo '您之后可以输startvnc来启动vnc服务，输stopvnc停止'
echo '您还可以在termux原系统里输startxsdl来启动xsdl，按Ctrl+C或在termux原系统里输stopvnc停止进程'
echo '若xsdl音频端口不是4712，而是4713，则请输xsdl-4713进行修复。'
}


function remove()
{
  apt purge -y mate-desktop-environment-core mate-terminal tightvncserver
  apt purge -y ^mate
  apt autopurge
}

function main()
{
                case "$1" in
                install|in|i)
                        install
                            ;;
                remove|rm|uninstall|un|purge)
                         remove
                        ;;
                    help|man)
                        man mate-session 2>&1 >/dev/null
						mate-session --help
                        ;;

                   *)
			        install
			         ;;


        esac
}
main "$@"
Matryoshka
chmod +x mate.sh

#kali源
cat >kali.sh <<-'EndOfFile'
#!/bin/bash
function install()
{
apt install gpg -y
#添加公钥
apt-key adv --keyserver keyserver.ubuntu.com --recv ED444FF07D8D0BF6

cd /etc/apt/
cp -f sources.list sources.list.bak

#sed  's/^/#&/g' /etc/apt/sources.list

echo 'deb https://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib' > /etc/apt/sources.list
apt update
apt list --upgradable
apt dist-upgrade -y
echo 'You have successfully replaced your debian source with a kali source.'
echo '您已更换为kali源，如需换回debian源，请手动执行bash ~/kali.sh rm'
apt install -y neofetch
apt clean
echo 'You can type "neofetch" to get the current system information'
echo '您可以输neofetch来获取当前系统信息'
neofetch
echo '若您使用的是xfce桌面，则您可以输apt install -y kali-undercover 来安装伪装成win10的主题'
echo '直接运行kali-undercover可能会报错，请直接在“设置管理器---外观”处，修改样式和图标。'
}
function remove()
{
echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free' > /etc/apt/sources.list
apt update
apt list --upgradable
echo '您已换回debian源'
apt dist-upgrade -y
}

function main()
{
                case "$1" in
                install|in|i)
                        install
                            ;;
                remove|rm|uninstall|un|purge)
                         remove
                        ;;
                   *)
			        install
			         ;;


        esac
}
main "$@"

EndOfFile
chmod +x kali.sh

cat >chromium.sh <<-'EOF'
#!/bin/bash
function install()
{
apt install -y chromium chromium-l10n
#string='exec $LIBDIR/$APPNAME $CHROMIUM_FLAGS "$@"'
#sed -i 's:${string}:${string} --user-data-dir --no-sandbox:' /bin/bash/chromium
sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
grep 'chromium' /etc/profile || echo 'alias chromium="chromium --no-sandbox"' >> /etc/profile
}
function remove()
{
apt purge -y chromium chromium-l10n
apt autopurge
}
function main()
{
                case "$1" in
                install|in|i)
                        install
                            ;;
                remove|rm|uninstall|un|purge)
                         remove
                        ;;
                   *)
			        install
			         ;;


        esac
}
main "$@"
EOF
chmod +x chromium.sh

cat >firefox.sh <<-'EOF'
#!/bin/bash
function install()
{
    echo "即将安装firefox浏览器长期支持版"
    apt install -y firefox-esr firefox-esr-l10n-zh-cn
}

function remove()
{
        echo "即将卸载firefox浏览器长期支持版"
        apt purge -y firefox-esr firefox-esr-l10n-zh-cn
        apt autopurge

}

function main()
{
                case "$1" in
                install|in|i)
                        install
                            ;;
                remove|rm|uninstall|un|purge)
                         remove
                        ;;
                   *)
			        install
			         ;;


        esac
}

main "$@"
EOF
chmod +x firefox.sh
####################
#debian替换为ubuntu的脚本
if [ "${archtype}" = 'amd64' ] || [ "${archtype}" = 'i386' ]; then
    bash -c "$(curl -LfsS gitee.com/mo2/Termux-Debian/raw/master/installDebian.sh |
        sed 's@#deb http@deb http@g' |
        sed 's/debian系统/ubuntu系统/g' |
        sed 's/.*sid main/#&/' |
        sed 's/main contrib non-free/main restricted universe multiverse/g' |
        sed 's:stable/updates:focal-security:g' |
        sed 's/stable/focal/g' |
        sed 's/buster-backports/focal-backports/' |
        sed 's:/ sid:/ focal-proposed:' |
        sed 's:debian-security:ubuntu/:' |
        sed 's:cn/debian:cn/ubuntu:g' |
        sed 's:debian-sid:ubuntu-focal:g' |
        sed 's:debian/sid:ubuntu/focal:g' |
        sed 's:Debian GNU/Linux:Ubuntu GNU/Linux:g')"
else
    #ubuntu-ports
    bash -c "$(curl -LfsS gitee.com/mo2/Termux-Debian/raw/master/installDebian.sh |
        sed 's@#deb http@deb http@g' |
        sed 's/debian系统/ubuntu系统/g' |
        sed 's/.*sid main/#&/' |
        sed 's/main contrib non-free/main restricted universe multiverse/g' |
        sed 's:stable/updates:focal-security:g' |
        sed 's/stable/focal/g' |
        sed 's/buster-backports/focal-backports/' |
        sed 's:/ sid:/ focal-proposed:' |
        sed 's:debian-security:ubuntu-ports/:' |
        sed 's:cn/debian:cn/ubuntu-ports:g' |
        sed 's:debian-sid:ubuntu-focal:g' |
        sed 's:debian/sid:ubuntu/focal:g' |
        sed 's:Debian GNU/Linux:Ubuntu GNU/Linux:g')"

fi
#############
#	"5" "Void:基于xbps包管理器的独立发行版" \

###############
INSTALLVOIDLINUXDISTRO() {
    bash -c "$(curl -LfsS gitee.com/mo2/Termux-Debian/raw/master/installDebian.sh |
        sed 's:debian-sid:voidlinux-default:g' |
        sed 's:debian/sid:voidlinux/current:g' |
        sed 's/debian系统/void系统/g' |
        sed 's/debian system/void system/g' |
        sed 's/debian容器/void容器/g' |
        sed 's:Debian GNU/Linux:Void GNU/Linux:g')"
}

echo "                                        "
echo "                .iri                    "
echo "            .1BQBBBBBBBBBBBMrrr         "
echo "          LBBBBBBBBBQBBBBBBBBBBBZ:      "
echo "        KBBBBBBBL          :PBBQBQB:    "
echo "      :BBBBBd.                vBBBBBK   "
echo "     rBBBBj.                    QBBBBB  "
echo "  . .BBBv                        EBBQBK "
echo "   vBBQ              :77i.        BBQ . "
echo "   BBB             QQgu7r77:      .BBZ  "
echo "  BBB:           rB7               BBg  "
echo "  BB2           iB                 BBB  "
echo "  BB:           B.           ..    BBB  "
echo "  BB           .B                  BB.  "
echo "  BB            BU          :     YBg   "
echo "  BB            SB      .:       qBg    "
echo "  BBi            qBr           .BB5     "
echo "  BBb           . rBBv      .PBBQ       "
echo "  sBB              :gBBBBBBBBBL         "
echo "   BBBU                :ir.             "
echo "   :BBB7                                "
echo "    YBBB                                "
echo "     uBBK                               "
echo "      rBBX                              "
echo "        BBB                             "
echo "         LBBE                           "
echo "           1BBP                         "
echo "             iBBBP                      "
echo "                 r7:..                  "
screenfetch
wget -qO /tmp/screenfetch.tar.gz 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/s/screenfetch/screenfetch_3.9.1.orig.tar.gz'
tar -zxf /tmp/screenfetch.tar.gz -C /tmp
mv -f /tmp/screenfetch-3.9.1/screenfetch-dev /usr/local/bin/screenfetch
chmod +x /usr/local/bin/screenfetch
rm -rf /tmp/screenfetch*

#下载主题的注释
#其中,mojave主题还需要修改窗口管理器(标题栏)样式。

cat >xstartup <<-'EndOfFile'
#!/bin/bash
unset SESSION_MANAGER
export PULSE_SERVER=127.0.0.1
#exec /etc/X11/xinit/xinitrc
#[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
#[ -r ${HOME}/.Xresources ] && xrdb ${HOME}/.Xresources
#xsetroot -solid grey
#vncconfig -iconic &
#xterm -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop"&
#plasma_session &
dbus-launch startkde & || dbus-launch startplasma-x11 &
EndOfFile
chmod +x ./xstartup
######################
#alpine安装debian chroot依赖
apk add -q xz newt tar procps git grep wget bash aria2 curl pv coreutils less

if grep -q "Fedora" /etc/os-release || grep -qi "CentOS" /etc/os-release || grep -qi "Red Hat" /etc/os-release; then
    LINUXDISTRO='redhat'
fi
dnf install -y git || yum install -y git
dnf install -y pv || yum install -y pv
dnf install -y wget || yum install -y wget
dnf install -y xz || yum install -y xz
dnf install -y tar || yum install -y tar
dnf install -y newt || yum install -y newt
dnf install -y tar || yum install -y tar
dnf install -y procps || yum install -y procps
dnf install -y aria2 || yum install -y aria2
dnf install -y curl || yum install -y curl
dnf install -y coreutils || yum install -y coreutils
dnf install -y less || yum install -y less
####################################
#tar压缩进度条1、2

: '	#tar -czf - ~/${DebianFolder} | (pv -p --timer --rate --bytes > ${TMPtime}.tar.gz)

	#tar -cf - ~/${DebianFolder} | pv -s $(du -sb ~/${DebianFolder} | awk '{print $1}') | gzip > ${TMPtime}.tar.gz

	#tar Pzcvf ${TMPtime}.tar.gz ~/${DebianFolder}'

#########
#mkdir -p /data/data/com.termux/files/home
#以下判定用于解决linux和termux的bash路径不同的问题。
if [ ! -f "${PREFIX}/bin/bash" ]; then
    mkdir -p ${PREFIX}/bin
    cp -pf $(which bash) ${PREFIX}/bin
fi
#1403行

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
##################################################

if [ "${LINUXDISTRO}" ='iSH' ]; then
    if (whiptail --title "您想要对这个小可爱做什么 " --yes-button "Alpine" --no-button "deb" --yesno "检测到您使用的是iOS系统，您是想要安装Alpine的GUI，还是其它系统(Debian、Ubuntu、Kali)？ ♪(^∇^*) " 9 50); then
        echo "该功能暂未开发"
        exit 0
    fi
fi

#ALPine xfce4
#ca-certificates curl xvfb x11vnc xfce4 xfce4-terminal dbus-x11 bash
#############################################
#/usr/local/bin/wsl-open
if [ ! -e /usr/local/bin/wsl-open ] && [ ! -e /usr/bin/wsl-open ]; then
    if [ ! -e /usr/bin/npm ]; then
        echo '正在为您安装nodejs、npm和npm模块（wsl-open）...'
        apt install -y nodejs
        bash -c "$(wget -O- https://npmjs.org/install.sh |
            sed 's:registry.npmjs.org:registry.npm.taobao.org:g')"
    fi
    npm install -g wsl-open
    #有可能会安装失败，所以需要再检测一遍
    if [ ! -e /usr/bin/npm ]; then
        sudo apt install -y npm || su -c "apt install -y npm"
        sudo npm install -g npm
        sudo npm install -g wsl-open || su -c "npm install -g wsl-open"
    fi
fi

INSTALLKALIROLLING() {
    bash -c "$(curl -LfsS gitee.com/mo2/linux/raw/master/installDebian.sh |
        sed 's/sid main/kali-rolling main/' |
        sed 's/stable/kali-last-snapshot/g' |
        sed '/buster-backports/d' |
        sed 's:cn/debian:cn/kali:g' |
        sed 's:debian-sid:kali-rolling:g' |
        sed 's:debian/sid:kali/current:g' |
        sed 's/debian系统/kali系统/g' |
        sed 's/debian system/kali system/g' |
        sed 's/debian容器/kali容器/g' |
        sed 's:Debian GNU/Linux:Kali GNU/Linux:g')"
}
#################
sudo bash -c "$(wget -qO- https://gitee.com/mo2/linux/raw/master/debian.sh)" && exit0 ||
    sudo bash -c "$(curl -LfsS https://gitee.com/mo2/linux/raw/master/debian.sh)" && exit0 ||
    sudo sh -c "$(wget --no-check-certificate -qO- https://gitee.com/mo2/linux/raw/master/debian.sh)"
