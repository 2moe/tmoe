#!/data/data/com.termux/files/usr/bin/bash

#检测架构

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

#安装必要依赖
#apt update
#apt install -y curl openssl proot aria2 procps

#requirements and dependencies.

dependencies=""

if [ "$(uname -o)" = "Android" ]; then
  termux-setup-storage
  if [ ! -e $PREFIX/bin/proot ]; then
    dependencies="${dependencies} proot"
  fi

  if [ ! -e $PREFIX/bin/pkill ]; then
    dependencies="${dependencies} procps"
  fi

  if [ ! -e $PREFIX/bin/pv ]; then
    dependencies="${dependencies} pv"
  fi

  if [ ! -e $PREFIX/bin/curl ]; then
    dependencies="${dependencies} curl"
  fi

  if [ ! -e $PREFIX/bin/aria2c ]; then
    dependencies="${dependencies} aria2"
  fi

  if [ ! -z "$dependencies" ]; then
    echo "正在安装相关依赖..."
    apt install -y ${dependencies}
  fi

fi
####################
#卸载chroot挂载目录
if [ -e "${DebianCHROOT}/etc/tmp/.ChrootInstallationDetectionFile" ]; then
  su -c "umount -lf ${DebianCHROOT}/dev >/dev/null 2>&1"
  su -c "umount -lf ${DebianCHROOT}/dev/shm  >/dev/null 2>&1"
  su -c "umount -lf ${DebianCHROOT}/dev/pts  >/dev/null 2>&1"
  su -c "umount -lf ${DebianCHROOT}/proc  >/dev/null 2>&1"
  su -c "umount -lf ${DebianCHROOT}/sys  >/dev/null 2>&1"
  su -c "umount -lf ${DebianCHROOT}/tmp  >/dev/null 2>&1"
  su -c "umount -lf ${DebianCHROOT}/root/sd  >/dev/null 2>&1 "
  su -c "umount -lf ${DebianCHROOT}/root/tf  >/dev/null 2>&1"
  su -c "umount -lf ${DebianCHROOT}/root/termux >/dev/null 2>&1"
fi
##############################
if [ "$(uname -o)" != "Android" ]; then
  PREFIX=/data/data/com.termux/files/usr
fi
#创建必要文件夹，防止挂载失败
mkdir -p ~/storage/external-1
DebianFolder=debian_${archtype}
DebianCHROOT=${HOME}/${DebianFolder}
#DebianFolder=debian_arm64

echo "                                        "
echo "                 .::::..                "
echo "      ::::rrr7QQJi::i:iirijQBBBQB.      "
echo "      BBQBBBQBP. ......:::..1BBBB       "
echo "      .BuPBBBX  .........r.  vBQL  :Y.  "
echo "       rd:iQQ  ..........7L   MB    rr  "
echo "        7biLX .::.:....:.:q.  ri    .   "
echo "         JX1: .r:.r....i.r::...:.  gi5  "
echo "         ..vr .7: 7:. :ii:  v.:iv :BQg  "
echo "         : r:  7r:i7i::ri:DBr..2S       "
echo "      i.:r:. .i:XBBK...  :BP ::jr   .7. "
echo "      r  i....ir r7.         r.J:   u.  "
echo "     :..X: .. .v:           .:.Ji       "
echo "    i. ..i .. .u:.     .   77: si   1Q  "
echo "   ::.. .r .. :P7.r7r..:iLQQJ: rv   ..  "
echo "  7  iK::r  . ii7r LJLrL1r7DPi iJ     r "
echo "    .  ::.:   .  ri 5DZDBg7JR7.:r:   i. "
echo "   .Pi r..r7:     i.:XBRJBY:uU.ii:.  .  "
echo "   QB rJ.:rvDE: .. ri uv . iir.7j r7.   "
echo "  iBg ::.7251QZ. . :.      irr:Iu: r.   "
echo "   QB  .:5.71Si..........  .sr7ivi:U    "
echo "   7BJ .7: i2. ........:..  sJ7Lvr7s    "
echo "    jBBdD. :. ........:r... YB  Bi      "
echo "       :7j1.                 :  :       "

echo "Detected that your current architecture is ${archtype}"
echo "检测到您当前的架构为${archtype} ，debian系统将安装至~/${DebianFolder}"

cd ~

if [ -d "${DebianFolder}" ]; then
  downloaded=1
  echo "Detected that you have debian installed 检测到您已安装debian"
fi

mkdir -p ~/${DebianFolder}

DebianTarXz="debian-sid-rootfs.tar.xz"

#if [ "$downloaded" != 1 ];then
if [ ! -f ${DebianTarXz} ]; then
  echo "正在从清华大学开源镜像站下载debian容器镜像"
  echo "Downloading rootfs.tar.xz from Tsinghua University Open Source Mirror Station."
  curl -L "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${archtype}/default/" -o get-date-tmp.html >/dev/null 2>&1
  ttime=$(cat get-date-tmp.html | tail -n2 | head -n1 | cut -d\" -f4)
  rm -f get-date-tmp.html

  aria2c -x 16 -k 1M --split 16 -o $DebianTarXz "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${archtype}/default/${ttime}rootfs.tar.xz"

fi
cur=$(pwd)
cd ~/${DebianFolder}
echo "正在解压debian-sid-rootfs.tar.xz，Decompressing Rootfs, please be patient."
if [ "$(uname -o)" = "Android" ]; then
  pv ${cur}/${DebianTarXz} | proot --link2symlink tar -pJx
else
  pv ${cur}/${DebianTarXz} | tar -pJx
fi
#proot --link2symlink tar -Jxvf ${cur}/${DebianTarXz}||:
cd "$cur"
echo "                                        "
echo "                            .:7E        "
echo "            .iv7vrrrrr7uQBBBBBBB:       "
echo "           v17::.........:SBBBUg        "
echo "        vKLi.........:. .  vBQrQ        "
echo "   sqMBBBr.......... :i. .  SQIX        "
echo "   BBQBBr.:...:....:. 1:.....v. ..      "
echo "    UBBB..:..:i.....i YK:: ..:   i:     "
echo "     7Bg.... iv.....r.ijL7...i. .Lu     "
echo "  IB: rb...i iui....rir :Si..:::ibr     "
echo "  J7.  :r.is..vrL:..i7i  7U...Z7i..     "
echo "  ...   7..I:.: 7v.ri.755P1. .S  ::     "
echo "    :   r:.i5KEv:.:.  :.  ::..X..::     "
echo "   7is. :v .sr::.         :: :2. ::     "
echo "   2:.  .u: r.     ::::   r: ij: .r  :  "
echo "   ..   .v1 .v.    .   .7Qr: Lqi .r. i  "
echo "   :u   .iq: :PBEPjvviII5P7::5Du: .v    "
echo "    .i  :iUr r:v::i:::::.:.:PPrD7: ii   "
echo "    :v. iiSrr   :..   s i.  vPrvsr. r.  "
echo "     ...:7sv:  ..PL  .Q.:.   IY717i .7. "
echo "      i7LUJv.   . .     .:   YI7bIr :ur "
echo "     Y rLXJL7.:jvi:i:::rvU:.7PP XQ. 7r7 "
echo "    ir iJgL:uRB5UPjriirqKJ2PQMP :Yi17.v "
echo "         :   r. ..      .. .:i  ...     "

if [ -f "${HOME}/.ChrootInstallationDetectionFile" ]; then
  rm -f ${HOME}/.ChrootInstallationDetectionFile
  mkdir -p ${DebianCHROOT}/etc/tmp
  echo "Creating chroot startup script"
  echo "正在创建chroot启动脚本/data/data/com.termux/files/usr/bin/debian "
  if [ -d "/sdcard" ]; then
    mkdir -p ${DebianCHROOT}/root/sd
  fi
  if [ -L '/data/data/com.termux/files/home/storage/external-1' ]; then
    mkdir -p ${DebianCHROOT}/root/tf
  fi
  if [ -d "/data/data/com.termux/files/home" ]; then
    mkdir -p ${DebianCHROOT}/root/termux
  fi
  if [ ! -f "${DebianCHROOT}/etc/profile" ]; then
    echo "" >>${DebianCHROOT}/etc/profile
  fi

  grep 'export PATH=' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "1 a\export PATH='/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games'" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep 'export PATH=' ${DebianCHROOT}/root/.zshenv >/dev/null 2>&1 || echo "export PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games" >>${DebianCHROOT}/root/.zshenv

  grep 'unset LD_PRELOAD' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "1 a\unset LD_PRELOAD" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep 'zh_CN.UTF-8' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\export LANG=zh_CN.UTF-8" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep 'HOME=/root' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\export HOME=/root" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep 'cd /root' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\cd /root" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  #此处EndOfChrootFile不要加单引号
  cat >/data/data/com.termux/files/usr/bin/debian <<-EndOfChrootFile
  #!/data/data/com.termux/files/usr/bin/bash
  DebianCHROOT=${HOME}/${DebianFolder}
  if [ ! -e "${DebianCHROOT}/etc/tmp/.ChrootInstallationDetectionFile" ]; then
    echo "本文件为chroot容器检测文件 Please do not delete this file!" >>${DebianCHROOT}/etc/tmp/.ChrootInstallationDetectionFile
  fi
  #sed替换匹配行,加密内容为chroot登录shell。为防止匹配行被替换，故采用base64加密。
  DEFAULTZSHLOGIN="\$(echo 'Y2hyb290ICR7RGViaWFuQ0hST09UfSAvYmluL3pzaCAtLWxvZ2luCg==' | base64 -d)"
  DEFAULTBASHLOGIN="\$(echo 'Y2hyb290ICR7RGViaWFuQ0hST09UfSAvYmluL2Jhc2ggLS1sb2dpbgo=' | base64 -d)"

  if [ -f ${DebianCHROOT}/bin/zsh ]; then

    sed -i "s:\${DEFAULTBASHLOGIN}:\${DEFAULTZSHLOGIN}:g" /data/data/com.termux/files/usr/bin/debian
  else
    sed -i "s:\${DEFAULTZSHLOGIN}:\${DEFAULTBASHLOGIN}:g" /data/data/com.termux/files/usr/bin/debian
  fi

  if [ "\$(whoami)" != "root" ]; then
    su -c "/bin/sh /data/data/com.termux/files/usr/bin/debian"
    exit
  fi
  mount -o bind /dev ${DebianCHROOT}/dev >/dev/null 2>&1
  mount -o bind /dev /dev >/dev/null 2>&1

  mount -t proc proc ${DebianCHROOT}/proc >/dev/null 2>&1
  mount -t proc proc /proc >/dev/null 2>&1

  #mount -t sysfs sysfs ${DebianCHROOT}/sys >/dev/null 2>&1
  mount -t sysfs sys ${DebianCHROOT}/sys >/dev/null 2>&1

  mount -t devpts devpts ${DebianCHROOT}/dev/pts >/dev/null 2>&1
  mount -t devpts devpts /dev/pts >/dev/null 2>&1

  #mount --bind /dev/shm ${DebianCHROOT}/dev/shm >/dev/null 2>&1
  mount -o rw,nosuid,nodev,mode=1777 -t tmpfs tmpfs /dev/shm >/dev/null 2>&1

  #mount -t tmpfs tmpfs ${DebianCHROOT}/tmp  >/dev/null 2>&1

  if [ -d "/sdcard" ]; then
    mount -o bind /sdcard ${DebianCHROOT}/root/sd >/dev/null 2>&1
  fi
  if [ "$(uname -o)" = "Android" ]; then
    if [ -d "/mnt/media_rw/${TFcardFolder}" ]; then
      TFcardFolder=$(su -c 'ls /mnt/media_rw/ 2>/dev/null | head -n 1')
      mount -o bind /mnt/media_rw/${TFcardFolder} ${DebianCHROOT}/root/tf >/dev/null 2>&1
    fi
    if [ -d "/data/data/com.termux/files/home" ]; then
      mount -o bind /data/data/com.termux/files/home ${DebianCHROOT}/root/termux >/dev/null 2>&1
    fi
  fi
  chroot \${DebianCHROOT} /bin/bash --login

EndOfChrootFile
#上面那行不要有空格
else

  echo "Creating proot startup script"
  echo "正在创建proot启动脚本/data/data/com.termux/files/usr/bin/debian "
  #此处EndOfFile不要加单引号
  cat >/data/data/com.termux/files/usr/bin/debian <<-EndOfFile
#!/data/data/com.termux/files/usr/bin/bash
cd ~
pulseaudio --start
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r ${DebianFolder}"
command+=" -b /dev"
command+=" -b /proc"
command+=" -b ${DebianFolder}/root:/dev/shm"
#您可以在此处修改挂载目录
command+=" -b /sdcard:/root/sd"
command+=" -b /data/data/com.termux/files/home/storage/external-1:/root/tf"
command+=" -b /data/data/com.termux/files/home:/root/termux"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=zh_CN.UTF-8"
command+=" /bin/bash --login"
com="\$@"
#为防止匹配行被替换，故采用base64加密。
DEFAULTZSHLOGIN="\$(echo 'Y29tbWFuZCs9IiAvYmluL3pzaCAtLWxvZ2luIgo=' | base64 -d)"
DEFAULTBASHLOGIN="\$(echo 'Y29tbWFuZCs9IiAvYmluL2Jhc2ggLS1sb2dpbiIK' | base64 -d)"

if [ -f ~/${DebianFolder}/bin/zsh ];then
    sed -i "s:\${DEFAULTBASHLOGIN}:\${DEFAULTZSHLOGIN}:g" /data/data/com.termux/files/usr/bin/debian
else
    sed -i "s:\${DEFAULTZSHLOGIN}:\${DEFAULTBASHLOGIN}:g" /data/data/com.termux/files/usr/bin/debian
fi

if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EndOfFile
fi
#######################################################

cat >/data/data/com.termux/files/usr/bin/startvnc <<-EndOfFile
#!/data/data/com.termux/files/usr/bin/bash
am start -n com.realvnc.viewer.android/com.realvnc.viewer.android.app.ConnectionChooserActivity
touch ~/${DebianFolder}/root/.vnc/startvnc
/data/data/com.termux/files/usr/bin/debian
EndOfFile
#debian前若加上bash

cat >/data/data/com.termux/files/usr/bin/stopvnc <<-'EndOfFile'
#!/data/data/com.termux/files/usr/bin/bash
pkill -u $(whoami)
EndOfFile

#不要单引号
cat >/data/data/com.termux/files/usr/bin/startxsdl <<-EndOfFile
#!/data/data/com.termux/files/usr/bin/bash
am start -n x.org.server/x.org.server.MainActivity
touch ~/${DebianFolder}/root/.vnc/startxsdl
/data/data/com.termux/files/usr/bin/debian
EndOfFile

#wget -qO /data/data/com.termux/files/usr/bin/debian-i 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh'
aria2c --allow-overwrite=true -d $PREFIX/bin -o debian-i 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh'
cat >/data/data/com.termux/files/usr/bin/debian-rm <<-EndOfFile
    #!/data/data/com.termux/files/usr/bin/bash
	  YELLOW=\$(printf '\033[33m')
	  RESET=\$(printf '\033[m')
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
  df -h |grep debian
  echo '移除系统前，请先确保您已卸载chroot挂载目录。'
  echo '建议您在移除前进行备份，若因操作不当导致数据丢失，开发者概不负责！！！'
  echo "Before removing the system, make sure you have unmounted the chroot mount directory.
It is recommended that you back up the entire system before removal. If the data is lost due to improper operation, the developer is not responsible! "
  fi
  ps -e | grep proot
  ps -e | grep startvnc
  echo "移除系统前，请先确保您已停止debian容器。"
  pkill proot 2>/dev/null
  echo "若容器未停止运行，则建议你先手动在termux原系统中执行stopvnc，再进行移除操作。"
	echo 'Detecting Debian system footprint... 正在检测debian系统占用空间大小'
  	du -sh ./${DebianFolder} --exclude=./${DebianFolder}/root/tf --exclude=./${DebianFolder}/root/sd --exclude=./${DebianFolder}/root/termux
	if [ ! -d ~/${DebianFolder} ]; then
		echo "\${YELLOW}Detected that you are not currently installed 检测到您当前未安装debian\${RESET}"
	fi
	echo "\${YELLOW}按回车键确认移除 Press enter to confirm.\${RESET} "
  pkill proot 2>/dev/null
	read
    chmod 777 -R ${DebianFolder}
	rm -rf "${DebianFolder}" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc $PREFIX/bin/startxsdl $PREFIX/bin/debian-rm $PREFIX/bin/code 2>/dev/null || tsudo rm -rf "${DebianFolder}" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc $PREFIX/bin/startxsdl $PREFIX/bin/debian-rm $PREFIX/bin/code 2>/dev/null

    sed -i '/alias debian=/d' $PREFIX/etc/profile
	  sed -i '/alias debian-rm=/d' $PREFIX/etc/profile
	source profile >/dev/null 2>&1
	echo 'The debian system has been removed. If you want to uninstall aria2, enter "apt remove aria2" or "apt purge aria2"'
  echo '移除完成，如需卸载aria2,请手动输apt remove aria2'
	echo 'If you want to reinstall, it is not recommended to remove the image file.'
	echo '若需要重装，则不建议移除镜像文件。'
	echo "\${YELLOW}是否需要删除镜像文件？[Y/n]\${RESET} "
	echo 'Do you need to delete the image file (debian-sid-rootfs.tar.xz)?[Y/n]'

    read opt
	case \$opt in
		y*|Y*|"") rm -f ~/debian-sid-rootfs.tar.xz $PREFIX/bin/debian-rm  
    rm -f ~/debian-buster-rootfs.tar.xz 
    echo "Deleted已删除" ;;
		n*|N*) echo "skipped." ;;
		*) echo "Invalid choice. skipped." ;;
	esac

EndOfFile

#tfcard=$(ls -l /data/data/com.termux/files/home/storage/external-1 |cut -c 1)

#if [ "$tfcard" == 'l' ]; then

#   sed -i '/external-1/d' /data/data/com.termux/files/usr/bin/debian

#fi

if [ ! -L '/data/data/com.termux/files/home/storage/external-1' ]; then

  sed -i 's@^command+=" -b /data/data/com.termux/files/home/storage/external-1@#&@g' /data/data/com.termux/files/usr/bin/debian 2>/dev/null
  sed -i 's@^mount -o bind /mnt/media_rw/@#&@g' /data/data/com.termux/files/usr/bin/debian 2>/dev/null
fi
echo 'Giving startup script execution permission'
echo "正在赋予启动脚本($PREFIX/bin/debian)执行权限"
#termux-fix-shebang /data/data/com.termux/files/usr/bin/debian
cd /data/data/com.termux/files/usr/bin

chmod +x debian startvnc stopvnc debian-rm debian-i startxsdl

#设定alias,防止debian-root的alias依旧在生效。
alias debian="/data/data/com.termux/files/usr/bin/debian"
alias debian-rm="/data/data/com.termux/files/usr/bin/debian-rm"

echo "You can type rm ~/${DebianTarXz} to delete the image file"
echo "您可以输rm ~/${DebianTarXz}来删除容器镜像文件"
ls -lh ~/${DebianTarXz}

cd ~/${DebianFolder}
#配置卸载脚本
cat >remove-debian.sh <<-EOF
#!/data/data/com.termux/files/usr/bin/bash
cd ~
chmod 777 -R debian_$archtype
rm -rf "debian_$archtype" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc 2>/dev/null || tsudo rm -rf "debian_$archtype" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc
grep 'alias debian' $PREFIX/etc/profile && sed -i '/alias debian=/d' $PREFIX/etc/profile
sed -i '/alias debian-rm=/d' $PREFIX/etc/profile
source profile >/dev/null 2>&1
echo '删除完成，如需卸载aria2,请输apt remove aria2'
echo '如需删除镜像文件，请输rm -f ~/debian-sid-rootfs.tar.xz'


EOF
chmod +x remove-debian.sh

cd ~/${DebianFolder}/root

#配置zsh
cat >zsh.sh <<-'ADDZSHSHELL'
#!/bin/bash

dependencies=""

    if [ ! -e /bin/zsh ]; then
		dependencies="${dependencies} zsh"
	fi

	if [ ! -d /usr/share/doc/fonts-powerline ]; then
	  dependencies="${dependencies} fonts-powerline"

	fi

	if [ ! -e /usr/bin/git ]; then
		dependencies="${dependencies} git"
	fi

	if [ ! -e /usr/bin/wget ]; then
		dependencies="${dependencies} wget"
	fi

	if [ ! -z "$dependencies" ]; then
	echo "正在安装相关依赖..."
	 apt install -y ${dependencies}
	fi

wget -qO /usr/local/bin/debian-i 'https://gitee.com/mo2/Termux-Debian/raw/master/debian-gui-install.bash'
chmod +x /usr/local/bin/debian-i

rm -rf /root/.oh-my-zsh
chsh -s /usr/bin/zsh
#
# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
#   sh install.sh
#
# You can tweak the install behavior by setting variables when running the script. For
# example, to change the path to the Oh My Zsh repository:
#   ZSH=~/.zsh sh install.sh
#
# Respects the following environment variables:
#   ZSH     - path to the Oh My Zsh repository folder (default: ${HOME}/.oh-my-zsh)
#   REPO    - name of the GitHub repo to install from (default: ohmyzsh/ohmyzsh)
#   REMOTE  - full remote URL of the git repo to install (default: GitHub via HTTPS)
#   BRANCH  - branch to check out immediately after install (default: master)
#
# Other options:
#   CHSH    -'no' means the installer will not change the default shell (default: yes)
#   RUNZSH  -'no' means the installer will not run zsh after the install (default: yes)
#
# You can also pass some arguments to the install script to set some these options:
#   --skip-chsh: has the same behavior as setting CHSH to 'no'
#   --unattended: sets both CHSH and RUNZSH to 'no'
# For example:
#   sh install.sh --unattended
#
set -e
#change the default repo
#https://github.com/ohmyzsh/ohmyzsh
#https://gitee.com/mirrors/oh-my-zsh
# Default settings
ZSH=${ZSH:-~/.oh-my-zsh}

REPO=${REPO:-mirrors/oh-my-zsh}
REMOTE=${REMOTE:-https://gitee.com/${REPO}.git}

#REPO=${REPO:-ohmyzsh/ohmyzsh}
#REMOTE=${REMOTE:-https://github.com/${REPO}.git}
BRANCH=${BRANCH:-master}





# Other options
CHSH=${CHSH:-yes}
RUNZSH=${RUNZSH:-yes}


command_exists() {
	command -v "$@" >/dev/null 2>&1
}

error() {
	echo ${RED}"Error: $@"${RESET} >&2
}

setup_color() {
	# Only use colors if connected to a terminal
	if [ -t 1 ]; then
		RED=$(printf '\033[31m')
		GREEN=$(printf '\033[32m')
		YELLOW=$(printf '\033[33m')
		BLUE=$(printf '\033[34m')
		BOLD=$(printf '\033[1m')
		RESET=$(printf '\033[m')
	else
		RED=""
		GREEN=""
		YELLOW=""
		BLUE=""
		BOLD=""
		RESET=""
	fi
}

setup_ohmyzsh() {
	# Prevent the cloned repository from having insecure permissions. Failing to do
	# so causes compinit() calls to fail with "command not found: compdef" errors
	# for users with insecure umasks (e.g., "002", allowing group writability). Note
	# that this will be ignored under Cygwin by default, as Windows ACLs take
	# precedence over umasks except for filesystems mounted with option "noacl".
	umask g-w,o-w

	echo "${BLUE}Cloning Oh My Zsh...${RESET}"

	command_exists git || {
		error "git is not installed"
		exit 1
	}

	if [ "$OSTYPE" = cygwin ] && git --version | grep -q msysgit; then
		error "Windows/MSYS Git is not supported on Cygwin"
		error "Make sure the Cygwin git package is installed and is first on the \$PATH"
		exit 1
	fi

	git clone -c core.eol=lf -c core.autocrlf=false \
		-c fsck.zeroPaddedFilemode=ignore \
		-c fetch.fsck.zeroPaddedFilemode=ignore \
		-c receive.fsck.zeroPaddedFilemode=ignore \
		--depth=1 --branch "$BRANCH" "$REMOTE" "$ZSH" || {
		error "git clone of oh-my-zsh repo failed"
		exit 1
	}

	echo
}

setup_zshrc() {
	# Keep most recent old .zshrc at .zshrc.pre-oh-my-zsh, and older ones
	# with datestamp of installation that moved them aside, so we never actually
	# destroy a user's original zshrc
	echo "${BLUE}Looking for an existing zsh config...${RESET}"

	# Must use this exact name so uninstall.sh can find it
	OLD_ZSHRC=~/.zshrc.pre-oh-my-zsh
	if [ -f ~/.zshrc ] || [ -h ~/.zshrc ]; then
		if [ -e "$OLD_ZSHRC" ]; then
			OLD_OLD_ZSHRC="${OLD_ZSHRC}-$(date +%Y-%m-%d_%H-%M-%S)"
			if [ -e "$OLD_OLD_ZSHRC" ]; then
				error "$OLD_OLD_ZSHRC exists. Can't back up ${OLD_ZSHRC}"
				error "re-run the installer again in a couple of seconds"
				exit 1
			fi
			mv "$OLD_ZSHRC" "${OLD_OLD_ZSHRC}"

			echo "${YELLOW}Found old ~/.zshrc.pre-oh-my-zsh." \
				"${GREEN}Backing up to ${OLD_OLD_ZSHRC}${RESET}"
		fi
		echo "${YELLOW}Found ~/.zshrc.${RESET} ${GREEN}Backing up to ${OLD_ZSHRC}${RESET}"
		mv ~/.zshrc "$OLD_ZSHRC"
	fi

	echo "${GREEN}Using the Oh My Zsh template file and adding it to ~/.zshrc.${RESET}"

	cp "$ZSH/templates/zshrc.zsh-template" ~/.zshrc
	sed "/^export ZSH=/ c\\
export ZSH=\"$ZSH\"
" ~/.zshrc > ~/.zshrc-omztemp
	mv -f ~/.zshrc-omztemp ~/.zshrc

	echo
}

setup_shell() {
	# Skip setup if the user wants or stdin is closed (not running interactively).
	if [ $CHSH = no ]; then
		return
	fi

	# If this user's login shell is already "zsh", do not attempt to switch.
	if [ "$(basename "$SHELL")" = "zsh" ]; then
		return
	fi

	# If this platform doesn't provide a "chsh" command, bail out.
	if ! command_exists chsh; then
		cat <<-EOF
			I can't change your shell automatically because this system does not have chsh.
			${BLUE}Please manually change your default shell to zsh${RESET}
		EOF
		return
	fi

	echo "${BLUE}Time to change your default shell to zsh:${RESET}"

	# Prompt for user choice on changing the default login shell
	printf "${YELLOW}Changing the default shell to zsh for you.${RESET} "


	# Check if we're running on Termux
	case "$PREFIX" in
		*com.termux*) termux=true; zsh=zsh ;;
		*) termux=false ;;
	esac

	if [ "$termux" != true ]; then
		# Test for the right location of the "shells" file
		if [ -f /etc/shells ]; then
			shells_file=/etc/shells
		elif [ -f /usr/share/defaults/etc/shells ]; then # Solus OS
			shells_file=/usr/share/defaults/etc/shells
		else
			error "could not find /etc/shells file. Change your default shell manually."
			return
		fi

		# Get the path to the right zsh binary
		# 1. Use the most preceding one based on $PATH, then check that it's in the shells file
		# 2. If that fails, get a zsh path from the shells file, then check it actually exists
		if ! zsh=$(which zsh) || ! grep -qx "$zsh" "$shells_file"; then
			if ! zsh=$(grep '^/.*/zsh$' "$shells_file" | tail -1) || [ ! -f "$zsh" ]; then
				error "no zsh binary found or not present in '$shells_file'"
				error "change your default shell manually."
				return
			fi
		fi
	fi

	# We're going to change the default shell, so back up the current one
	if [ -n "$SHELL" ]; then
		echo $SHELL > ~/.shell.pre-oh-my-zsh
	else
		grep "^$USER:" /etc/passwd | awk -F: '{print $7}' > ~/.shell.pre-oh-my-zsh
	fi

	# Actually change the default shell to zsh
	if ! chsh -s "$zsh"; then
		error "chsh command unsuccessful. Change your default shell manually."
	else
		export SHELL="$zsh"
		echo "${GREEN}Shell successfully changed to '$zsh'.${RESET}"
	fi

	echo
}

main() {
	# Run as unattended if stdin is closed
	if [ ! -t 0 ]; then
		RUNZSH=no
		CHSH=no
	fi

	# Parse arguments
	while [ $# -gt 0 ]; do
		case $1 in
			--unattended) RUNZSH=no; CHSH=no ;;
			--skip-chsh) CHSH=no ;;
		esac
		shift
	done

	setup_color

	if ! command_exists zsh; then
		echo "${YELLOW}Zsh is not installed.${RESET} Please install zsh first."
		exit 1
	fi

	if [ -d "$ZSH" ]; then
		cat <<-EOF
			${YELLOW}You already have Oh My Zsh installed.${RESET}
			You'll need to remove '$ZSH' if you want to reinstall.
		EOF
		exit 1
	fi

	setup_ohmyzsh
	setup_zshrc
	setup_shell

	printf "$GREEN"
	cat <<-'EOF'
		         __                                     __
		  ____  / /_     ____ ___  __  __   ____  _____/ /_
		 / __ \/ __ \   / __ `__ \/ / / /  /_  / / ___/ __ \
		/ /_/ / / / /  / / / / / / /_/ /    / /_(__  ) / / /
		\____/_/ /_/  /_/ /_/ /_/\__, /    /___/____/_/ /_/
		                        /____/                       ....is now installed!


		Please look over the ~/.zshrc file to select plugins, themes, and options.

		p.s. Follow us on https://twitter.com/ohmyzsh

		p.p.s. Get stickers, shirts, and coffee mugs at https://shop.planetargon.com/collections/oh-my-zsh

	EOF
	printf "$RESET"

	if [ $RUNZSH = no ]; then
		echo "${YELLOW}Run zsh to try it out.${RESET}"
		exit
	fi
echo "                                        "
echo "                 .::::..                "
echo "      ::::rrr7QQJi::i:iirijQBBBQB.      "
echo "      BBQBBBQBP. ......:::..1BBBB       "
echo "      .BuPBBBX  .........r.  vBQL  :Y.  "
echo "       rd:iQQ  ..........7L   MB    rr  "
echo "        7biLX .::.:....:.:q.  ri    .   "
echo "         JX1: .r:.r....i.r::...:.  gi5  "
echo "         ..vr .7: 7:. :ii:  v.:iv :BQg  "
echo "         : r:  7r:i7i::ri:DBr..2S       "
echo "      i.:r:. .i:XBBK...  :BP ::jr   .7. "
echo "      r  i....ir r7.         r.J:   u.  "
echo "     :..X: .. .v:           .:.Ji       "
echo "    i. ..i .. .u:.     .   77: si   1Q  "
echo "   ::.. .r .. :P7.r7r..:iLQQJ: rv   ..  "
echo "  7  iK::r  . ii7r LJLrL1r7DPi iJ     r "
echo "    .  ::.:   .  ri 5DZDBg7JR7.:r:   i. "
echo "   .Pi r..r7:     i.:XBRJBY:uU.ii:.  .  "
echo "   QB rJ.:rvDE: .. ri uv . iir.7j r7.   "
echo "  iBg ::.7251QZ. . :.      irr:Iu: r.   "
echo "   QB  .:5.71Si..........  .sr7ivi:U    "
echo "   7BJ .7: i2. ........:..  sJ7Lvr7s    "
echo "    jBBdD. :. ........:r... YB  Bi      "
echo "       :7j1.                 :  :       "
    echo "Configuring zsh theme 正在配置zsh主题(agnosterzak)"
cd ~/.oh-my-zsh/themes || mkdir -p ~/.oh-my-zsh/themes && cd ~/.oh-my-zsh/themes

cat >agnosterzak.zsh-theme<<-'themeEOF'
# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

# Characters
SEGMENT_SEPARATOR="\ue0b0"
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    print -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ -n "$SSH_CLIENT" ]]; then
    prompt_segment magenta white "%{$fg_bold[white]%(!.%{%F{white}%}.)%}$USER@%m%{$fg_no_bold[white]%}"
  else
    prompt_segment yellow magenta "%{$fg_bold[magenta]%(!.%{%F{magenta}%}.)%}@$USER%{$fg_no_bold[magenta]%}"
  fi
}

# Battery Level
prompt_battery() {
  HEART='♥ '

  if [[ $(uname) == "Darwin" ]] ; then

    function battery_is_charging() {
      [ $(ioreg -rc AppleSmartBattery | grep -c '^.*"ExternalConnected"\ =\ No') -eq 1 ]
    }

    function battery_pct() {
      local smart_battery_status="$(ioreg -rc "AppleSmartBattery")"
      typeset -F maxcapacity=$(echo $smart_battery_status | grep '^.*"MaxCapacity"\ =\ ' | sed -e 's/^.*"MaxCapacity"\ =\ //')
      typeset -F currentcapacity=$(echo $smart_battery_status | grep '^.*"CurrentCapacity"\ =\ ' | sed -e 's/^.*CurrentCapacity"\ =\ //')
      integer i=$(((currentcapacity/maxcapacity) * 100))
      echo $i
    }

    function battery_pct_remaining() {
      if battery_is_charging ; then
        battery_pct
      else
        echo "External Power"
      fi
    }

    function battery_time_remaining() {
      local smart_battery_status="$(ioreg -rc "AppleSmartBattery")"
      if [[ $(echo $smart_battery_status | grep -c '^.*"ExternalConnected"\ =\ No') -eq 1 ]] ; then
        timeremaining=$(echo $smart_battery_status | grep '^.*"AvgTimeToEmpty"\ =\ ' | sed -e 's/^.*"AvgTimeToEmpty"\ =\ //')
        if [ $timeremaining -gt 720 ] ; then
          echo "::"
        else
          echo "~$((timeremaining / 60)):$((timeremaining % 60))"
        fi
      fi
    }

    b=$(battery_pct_remaining)
    if [[ $(ioreg -rc AppleSmartBattery | grep -c '^.*"ExternalConnected"\ =\ No') -eq 1 ]] ; then
      if [ $b -gt 50 ] ; then
        prompt_segment green white
      elif [ $b -gt 20 ] ; then
        prompt_segment yellow white
      else
        prompt_segment red white
      fi
      echo -n "%{$fg_bold[white]%}$HEART$(battery_pct_remaining)%%%{$fg_no_bold[white]%}"
    fi
  fi

  if [[ $(uname) == "Linux" && -d /sys/module/battery ]] ; then

    function battery_is_charging() {
      ! [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]]
    }

    function battery_pct() {
      if (( $+commands[acpi] )) ; then
        echo "$(acpi | cut -f2 -d ',' | tr -cd '[:digit:]')"
      fi
    }

    function battery_pct_remaining() {
      if [ ! $(battery_is_charging) ] ; then
        battery_pct
      else
        echo "External Power"
      fi
    }

    function battery_time_remaining() {
      if [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]] ; then
        echo $(acpi | cut -f3 -d ',')
      fi
    }

    b=$(battery_pct_remaining)
    if [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]] ; then
      if [ $b -gt 40 ] ; then
        prompt_segment green white
      elif [ $b -gt 20 ] ; then
        prompt_segment yellow white
      else
        prompt_segment red white
      fi
      echo -n "%{$fg_bold[white]%}$HEART$(battery_pct_remaining)%%%{$fg_no_bold[white]%}"
    fi

  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
#«»±˖˗‑‐‒ ━ ✚‐↔←↑↓→↭⇎⇔⋆━◂▸◄►◆☀★☗☊✔✖❮❯⚑⚙
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR="$BRANCH"
  }
  local ref dirty mode repo_path clean has_upstream
  local modified untracked added deleted tagged stashed
  local ready_commit git_status bgclr fgclr
  local commits_diff commits_ahead commits_behind has_diverged to_push to_pull

  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    git_status=$(git status --porcelain 2> /dev/null)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      clean=''
      bgclr='yellow'
      fgclr='magenta'
    else
      clean=' ✔'
      bgclr='green'
      fgclr='white'
    fi

    local upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
    if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then has_upstream=true; fi

    local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

    local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
    # if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files◆"; fi
    if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files☀"; fi

    local number_added=$(\grep -c "^A" <<< "${git_status}")
    if [[ $number_added -gt 0 ]]; then added=" $number_added✚"; fi

    local number_modified=$(\grep -c "^.M" <<< "${git_status}")
    if [[ $number_modified -gt 0 ]]; then
      modified=" $number_modified●"
      bgclr='red'
      fgclr='white'
    fi

    local number_added_modified=$(\grep -c "^M" <<< "${git_status}")
    local number_added_renamed=$(\grep -c "^R" <<< "${git_status}")
    if [[ $number_modified -gt 0 && $number_added_modified -gt 0 ]]; then
      modified="$modified$((number_added_modified+number_added_renamed))±"
    elif [[ $number_added_modified -gt 0 ]]; then
      modified=" ●$((number_added_modified+number_added_renamed))±"
    fi

    local number_deleted=$(\grep -c "^.D" <<< "${git_status}")
    if [[ $number_deleted -gt 0 ]]; then
      deleted=" $number_deleted‒"
      bgclr='red'
      fgclr='white'
    fi

    local number_added_deleted=$(\grep -c "^D" <<< "${git_status}")
    if [[ $number_deleted -gt 0 && $number_added_deleted -gt 0 ]]; then
      deleted="$deleted$number_added_deleted±"
    elif [[ $number_added_deleted -gt 0 ]]; then
      deleted=" ‒$number_added_deleted±"
    fi

    local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
    if [[ -n $tag_at_current_commit ]]; then tagged=" ☗$tag_at_current_commit "; fi

    local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
    if [[ $number_of_stashes -gt 0 ]]; then
      stashed=" ${number_of_stashes##*(  )}⚙"
      bgclr='magenta'
      fgclr='white'
    fi

    if [[ $number_added -gt 0 || $number_added_modified -gt 0 || $number_added_deleted -gt 0 ]]; then ready_commit=' ⚑'; fi

    local upstream_prompt=''
    if [[ $has_upstream == true ]]; then
      commits_diff="$(git log --pretty=oneline --topo-order --left-right ${current_commit_hash}...${upstream} 2> /dev/null)"
      commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
      commits_behind=$(\grep -c "^>" <<< "$commits_diff")
      upstream_prompt="$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)"
      upstream_prompt=$(sed -e 's/\/.*$/ ☊ /g' <<< "$upstream_prompt")
    fi

    has_diverged=false
    if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then has_diverged=true; fi
    if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then
      if [[ $bgclr == 'red' || $bgclr == 'magenta' ]] then
        to_push=" $fg_bold[white]↑$commits_ahead$fg_bold[$fgclr]"
      else
        to_push=" $fg_bold[black]↑$commits_ahead$fg_bold[$fgclr]"
      fi
    fi
    if [[ $has_diverged == false && $commits_behind -gt 0 ]]; then to_pull=" $fg_bold[magenta]↓$commits_behind$fg_bold[$fgclr]"; fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    prompt_segment $bgclr $fgclr

    print -n "%{$fg_bold[$fgclr]%}${ref/refs\/heads\//$PL_BRANCH_CHAR $upstream_prompt}${mode}$to_push$to_pull$clean$tagged$stashed$untracked$modified$deleted$added$ready_commit%{$fg_no_bold[$fgclr]%}"
  fi
}

prompt_hg() {
  local rev status
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green black
      fi
      print -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^[MA]"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green black
      fi
      print -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment cyan white "%{$fg_bold[white]%}%~%{$fg_no_bold[white]%}"
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

prompt_time() {
  prompt_segment blue white "%{$fg_bold[white]%}%D{%a %e %b - %H:%M}%{$fg_no_bold[white]%}"
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$CROSS"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  print -n "\n"
  prompt_status
  prompt_battery
  prompt_time
  prompt_virtualenv
  prompt_dir
  prompt_git
  prompt_hg
  prompt_end
  CURRENT_BG='NONE'
  print -n "\n"
  prompt_context
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
themeEOF
if [ -e "/etc/tmp/.ChrootInstallationDetectionFile" ]; then
    grep 'unset LD_PRELOAD' /root/.zshrc >/dev/null 2>&1 || sed -i "1 a\unset LD_PRELOAD" /root/.zshrc >/dev/null 2>&1
    grep 'zh_CN.UTF-8' /root/.zshrc >/dev/null 2>&1 || sed -i "$ a\export LANG=zh_CN.UTF-8" /root/.zshrc >/dev/null 2>&1
    grep 'HOME=/root' /root/.zshrc >/dev/null 2>&1 || sed -i "$ a\export HOME=/root" /root/.zshrc >/dev/null 2>&1
    grep 'cd /root' /root/.zshrc >/dev/null 2>&1 || sed -i "$ a\cd /root" /root/.zshrc >/dev/null 2>&1
fi


cd ~
sed -i '1 r vnc-autostartup-zsh' ~/.zshrc
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnosterzak"/g' ~/.zshrc

rm -f vnc-autostartup-zsh



echo "正在安装zsh-syntax-highlighting语法高亮插件"

rm -rf /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 2>/dev/null
mkdir -p /root/.oh-my-zsh/custom/plugins

#git clone git://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh-syntax-highlighting
git clone https://gitee.com/mo2/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting


grep 'zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' /root/.zshrc >/dev/null 2>&1 || sed -i "$ a\source /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" /root/.zshrc
 #echo -e "\nsource /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> /root/.zshrc

echo "正在安装zsh-autosuggestions自动补全插件"
rm -rf /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions 2>/dev/null

#git clone git://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://gitee.com/mo2/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions


grep '/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' /root/.zshrc >/dev/null 2>&1 ||sed -i "$ a\source /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" /root/.zshrc
#echo -e "\nsource /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> /root/.zshrc

sed -i 's/plugins=(git)/plugins=(git extract z)/g' ~/.zshrc
echo 'All optimization steps have been completed, enjoy it!'
echo 'zsh配置完成，2s后将为您启动Tmoe-debian工具'
echo '您也可以手动输debian-i进入'
echo 'After 2 seconds, Tmoe-debian gui installation manager will be launched.'
echo 'You can also enter debian-i manually to start it.'
sleep 2
bash /usr/local/bin/debian-i
	exec zsh -l
	source ~/.zshrc
	zsh
}

main "$@"
ADDZSHSHELL
chmod +x zsh.sh

#vnc自动启动
cat >vnc-autostartup <<-'EndOfFile'
cat /etc/issue

grep  'cat /etc/issue' ~/.bashrc >/dev/null 2>&1 || sed -i '1 a\cat /etc/issue' ~/.bashrc
if [ -f "/root/.vnc/startvnc" ]; then
	/usr/local/bin/startvnc
	echo "已为您启动vnc服务 Vnc service has been started, enjoy it!"
	rm -f /root/.vnc/startvnc
fi

if [ -f "/root/.vnc/startxsdl" ]; then
    echo '检测到您在termux原系统中输入了startxsdl，已为您打开xsdl安卓app'
	echo 'Detected that you entered "startxsdl" from the termux original system, and the xsdl Android  application has been opened.'
	rm -f /root/.vnc/startxsdl
	echo '9s后将为您启动xsdl'
  echo 'xsdl will start in 9 seconds'
  sleep 9
  /usr/local/bin/startxsdl
fi
 ps -e 2>/dev/null | tail -n 25
EndOfFile

cat >vnc-autostartup-zsh <<-'EndOfFile'
cat /etc/issue

grep  'cat /etc/issue' ~/.zshrc >/dev/null 2>&1 || sed -i '1 a\cat /etc/issue' ~/.zshrc
if [ -f "/root/.vnc/startvnc" ]; then
	/usr/local/bin/startvnc
	echo "已为您启动vnc服务 Vnc service has been started, enjoy it!"
	rm -f /root/.vnc/startvnc
fi

if [ -f "/root/.vnc/startxsdl" ]; then
    echo '检测到您在termux原系统中输入了startxsdl，已为您打开xsdl安卓app'
	echo 'Detected that you entered "startxsdl" from the termux original system, and the xsdl Android application has been opened.'
	rm -f /root/.vnc/startxsdl
  echo '9s后将为您启动xsdl'
  echo 'xsdl will start in 9 seconds'
  sleep 9
	/usr/local/bin/startxsdl
fi
ps -e 2>/dev/null | tail -n 25

EndOfFile

sed -i '1 r vnc-autostartup' ./.bashrc
#cp -f .bashrc .bashrc.bak
if [ -f ".bash_profile" ] || [ -f ".bash_login" ]; then
  mv -f .bash_profile .bash_profile.bak 2>/dev/null
  mv -f .bash_login .basfh_login.bak 2>/dev/null
fi
if [ ! -f ".profile" ]; then
  echo '' >>.profile || touch .profle
else
  mv -f .profile .profile.bak
fi
cat >.profile <<-'EDITBASHPROFILE'
YELLOW=$(printf '\033[33m')
RESET=$(printf '\033[m')
cd ~
#配置清华源
#stable-backports会出错，需改为buster-backports
cat >/etc/apt/sources.list <<-'EndOfFile'
#deb http://mirrors.tuna.tsinghua.edu.cn/debian/ stable main contrib non-free
#deb http://mirrors.tuna.tsinghua.edu.cn/debian/ stable-updates main contrib non-free
#deb http://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
#deb http://mirrors.tuna.tsinghua.edu.cn/debian-security stable/updates main contrib non-free
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
EndOfFile

#配置dns解析
cat > /etc/resolv.conf <<-'EndOfFile'
nameserver 114.114.114.114
nameserver 240c::6666
EndOfFile

apt update
apt install -y locales

echo "您已成功安装Debian GNU/Linux,之后可以输${YELLOW}debian${RESET}来进入debian系统。"
echo 'Congratulations on your successful installation of Debian GNU/Linux. After that, you can enter debian in termux to enter the debian system. '
echo '正在执行优化步骤，请勿退出!'
echo 'Optimization steps are in progress. Do not exit!'
#配置中文环境
echo "正在配置中文环境..."
echo "Configuring Chinese environment..."
sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
cat >/etc/default/locale <<-'EOF'
LANG="zh_CN.UTF-8"
LANGUAGE="zh_CN:zh"
EOF
locale-gen
source /etc/default/locale

#配置国内时区
echo 'Asia/Shanghai' >/etc/timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "                                         "
echo "         DL.                             "
echo "         QBBBBBKv:rr77ri:.               "
echo "         gBBQdY7::::..::i7vv.            "
echo "         UBd. . .:.........rBBBQBBBB5    "
echo "         Pu  :..r......i:....BBBQBBB:    "
echo "         ri.i:.j:...:. i7... uBBZrd:     "
echo "   :     7.:7.7U.:..r: Yr:.. iQ1:qU      "
echo "  .Qi   .7.ii.X7:...L.:qr:...iB7ZQ       "
echo "   .27. :r.r:L7i::.7r:vri:...rr  .       "
echo "    v   ::.Yrviri:7v7v: ::...i.   i      "
echo "        r:ir: r.iiiir..:7r...r   :P.2Y   "
echo "        v:vi::.      :  ::. .qI7U1U :1   "
echo "  Qr    7.7.         :.i::. :Di:. i .v:  "
echo "  v7..  s.r7.   ...   .:7i: rDi...r ..   "
echo "   vi: .7.iDBBr  .r   .:.7. rPr:..r      "
echo "   i   :virZBgi  :vrYJ1vYY .ruY:..i      "
echo "       YrivEv. 7BBRBqj21I7 .77J:.:.PQ    "
echo "      .1r:q.   rB52SKrj.:i i5isi.:i :.r  "
echo "      YvrY7    r.  . ru :: PIrj7.:r..v   "
echo "     rSviYI..iuU .:.:i:.7.KPPiSr.:vr     "
echo "    .u:Y:JQMSsJUv...   .rDE1P71:.7X7     "
echo "    5  Ivr:QJ7JYvi....ir1dq vYv.7L.Y     "
echo "    S  7Z  Qvr:.iK55SqS1PX  Xq7u2 :7     "
echo "           .            i   7            "
apt install -y apt-utils

apt install -y ca-certificates

echo "Replacing http software source list with https."
echo "正在将http源替换为https..."
sed -i 's/http/https/' /etc/apt/sources.list

apt update
apt list --upgradable
echo "正在升级所有软件包..."
apt dist-upgrade -y
apt install -y procps
apt clean

##############
mkdir -p /usr/local/bin
cat >/usr/local/bin/xsdl-4712 <<-'EndOfFile'
#!/bin/bash
stopvnc >/dev/null 2>&1
sed -i 's/4713/4712/g' /usr/local/bin/startxsdl
EndOfFile

cat >/usr/local/bin/xsdl-4713 <<-'EndOfFile'
#!/bin/bash
stopvnc >/dev/null 2>&1
sed -i 's/4712/4713/g' /usr/local/bin/startxsdl
EndOfFile

chmod +x /usr/local/bin/xsdl-4712 /usr/local/bin/xsdl-4713
#############################
#桌面环境安装脚本
cat >lxqt.sh <<-'Matryoshka'
#!/bin/bash
function install()
{
apt-mark hold udisks2
apt update
echo '即将为您安装思源黑体(中文字体)、tightvncserver、lxqt-core、lxqt-config和qterminal  '
apt install -y fonts-noto-cjk tightvncserver lxqt-core lxqt-config qterminal
apt clean

mkdir -p ~/.vnc
cd ~/.vnc
cat >xstartup<<-'EndOfFile'
#!/bin/bash
xrdb ${HOME}/.Xresources
export PULSE_SERVER=127.0.0.1
startlxqt &
EndOfFile
chmod +x ./xstartup

cd /usr/local/bin
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
startlxqt
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
apt install -y lxqt-core lxqt-config qterminal tightvncserver
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
Matryoshka
chmod +x lxqt.sh

cat >gnome.sh <<-'Matryoshka'
#!/bin/bash
function install()
{
apt-mark hold udisks2
apt update
echo "Gnome测试失败，请自行解决软件依赖和其它相关问题。"
echo '即将为您安装思源黑体(中文字体)、aptitude、tightvncserver和task-gnome-desktop'
apt install -y fonts-noto-cjk aptitude tightvncserver
mkdir -p /run/lock
touch /var/lib/aptitude/pkgstates
aptitude install -y task-gnome-desktop || apt install -y task-gnome-desktop
apt install -y xinit dbus-x11
apt clean

mkdir -p ~/.vnc
cd ~/.vnc
cat >xstartup<<-'EndOfFile'
#!/bin/bash
xrdb ${HOME}/.Xresources
export PULSE_SERVER=127.0.0.1
xsetroot -solid grey
x-terminal-emulator -geometry  80×24+10+10 -ls -title "$VNCDESKTOP Desktop" &
#x-window-manager &
# Fix to make GNOME work
#export XKL_XMODMAP_DISABLE=1
#/etc/X11/Xsession
gnome-session &
EndOfFile
chmod +x ./xstartup


cd /usr/local/bin

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
gnome-session
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
apt purge -y tightvncserver
apt autopurge
aptitude purge -y task-gnome-desktop
apt purge -y task-gnome-desktop
apt purge -y ^gnome
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
Matryoshka
chmod +x gnome.sh

cat >kde.sh <<-'Matryoshka'
#!/bin/bash
function install()
{
apt-mark hold udisks2
apt update
echo "KDE测试失败，请自行解决软件依赖和其它相关问题。"
echo '即将为您安装思源黑体(中文字体)、aptitude、tightvncserver、kde-plasma-desktop等软件包'
apt install -y aptitude
mkdir -p /run/lock
touch /var/lib/aptitude/pkgstates
aptitude install -y kde-plasma-desktop || apt install -y kde-plasma-desktop
apt install -y fonts-noto-cjk tightvncserver 
#task-kde-desktop


apt clean

mkdir -p ~/.vnc
cd ~/.vnc
cat >xstartup<<-'EndOfFile'
#!/bin/bash
unset SESSION_MANAGER
export PULSE_SERVER=127.0.0.1
exec /etc/X11/xinit/xinitrc
[ -x /etc/vnc/xstartup ] && exec/etc/vnc/xstartup
[ -r ${HOME}/.Xresources ] && xrdb${HOME}/.Xresources
xsetroot -solid grey
vncconfig -iconic &
#xterm -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop"&
#plasma_session &
startplasma-x11 &
EndOfFile
chmod +x ./xstartup


cd /usr/local/bin
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
#plasma_session &
startplasma-x11 || startx
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
apt purge -y tightvncserver kde-plasma-desktop
aptitude purge -y  kde-plasma-desktop
apt purge -y  plasma-desktop
apt purge -y ^plasma
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
Matryoshka
chmod +x kde.sh
grep 'export DISPLAY' /etc/profile || echo "export DISPLAY=":1"" >>/etc/profile

echo "Welcome to Debian GNU/Linux."
cat /etc/issue
uname -a
rm -f vnc-autostartup .profile
if [ -f ".profile.bak" ]; then
  mv -f .profile.bak .profile
fi

if [ -f ".bash_profile.bak" ] || [ -f ".bash_login.bak" ]; then
  mv -f .bash_profile.bak .bash_profile.bak 2>/dev/null
  mv -f .bash_login.bak .basfh_login.bak 2>/dev/null
fi
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

echo "Automatically configure zsh after 2 seconds,you can press Ctrl + C to cancel."
echo "2s后将自动开始配置zsh，您可以按Ctrl+C取消，这将不会继续配置其它步骤，同时也不会启动Tmoe-debian工具。"
sleep 2
bash zsh.sh
EDITBASHPROFILE

bash /data/data/com.termux/files/usr/bin/debian
