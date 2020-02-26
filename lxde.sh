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
xrdb $HOME/.Xresources
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

