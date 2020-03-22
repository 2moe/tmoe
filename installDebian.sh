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

  if [ ! -e $PREFIX/bin/fzf ]; then
    dependencies="${dependencies} fzf"
  fi

  if [ ! -z "$dependencies" ]; then
    echo "正在安装相关依赖..."
    apt install -y ${dependencies}
  fi
  cd ~/.termux
  REMOTEP10KFONT='8597c76c4d2978f4ba022dfcbd5727a1efd7b34a81d768362a83a63b798f70e5'
  LOCALFONT="$(sha256sum font.ttf | cut -c 1-64)" || LOCALFONT="0"
  if [ "${REMOTEP10KFONT}" != "${LOCALFONT}" ]; then
    echo '正在配置字体...'
    aria2c --allow-overwrite=true -o Iosevka.tar.xz 'https://gitee.com/mo2/Termux-zsh/raw/p10k/Iosevka.tar.xz'
    rm -f font.ttf
    tar -Jxf Iosevka.tar.xz
    rm -f Iosevka.tar.xz
    termux-reload-settings
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
echo "检测到您当前的架构为${archtype} ，GNU/Linux系统将安装至~/${DebianFolder}"

cd ~

if [ -d "${DebianFolder}" ]; then
  downloaded=1
  echo "Detected that you have debian installed 检测到您已安装debian"
fi

mkdir -p ~/${DebianFolder}

DebianTarXz="debian-sid-rootfs.tar.xz"

#if [ "$downloaded" != 1 ];then
if [ ! -f ${DebianTarXz} ]; then
  echo "正在从清华大学开源镜像站下载容器镜像"
  echo "Downloading debian-sid-rootfs.tar.xz from Tsinghua University Open Source Mirror Station."
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
cp -f ~/.termux/font.ttf ~/${DebianFolder}/tmp/ 2>/dev/null
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
  #此处若不创建，将有可能导致chromium无法启动。
  mkdir -p ${DebianCHROOT}/run/shm
  chmod 1777 ${DebianCHROOT}/dev/shm 2>/dev/null
  grep -q 'export PATH=' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "1 a\export PATH='/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games'" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep -q 'export PATH=' ${DebianCHROOT}/root/.zshenv >/dev/null 2>&1 || echo "export PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games" >>${DebianCHROOT}/root/.zshenv

  grep -q 'unset LD_PRELOAD' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "1 a\unset LD_PRELOAD" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep -q 'zh_CN.UTF-8' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\export LANG=zh_CN.UTF-8" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep -q 'HOME=/root' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\export HOME=/root" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep -q 'cd /root' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\cd /root" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  #此处EndOfChrootFile不要加单引号
  cat >/data/data/com.termux/files/usr/bin/debian <<-EndOfChrootFile
  #!/data/data/com.termux/files/usr/bin/bash
  DebianCHROOT=${HOME}/${DebianFolder}
  if [ ! -e "${DebianCHROOT}/etc/tmp/.ChrootInstallationDetectionFile" ]; then
    mkdir -p "${DebianCHROOT}/etc/tmp"
    echo "本文件为chroot容器检测文件 Please do not delete this file!" >>${DebianCHROOT}/etc/tmp/.ChrootInstallationDetectionFile 2>/dev/null
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
pkill pulseaudio 2>/dev/null
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
  echo "移除系统前，请先确保您已停止容器的进程。"
  pkill proot 2>/dev/null
  echo "若容器未停止运行，则建议你先手动在termux原系统中执行stopvnc，再进行移除操作。"
	echo 'Detecting debian system footprint... 正在检测debian system占用空间大小'
  	du -sh ./${DebianFolder} --exclude=./${DebianFolder}/root/tf --exclude=./${DebianFolder}/root/sd --exclude=./${DebianFolder}/root/termux
	if [ ! -d ~/${DebianFolder} ]; then
		echo "\${YELLOW}Detected that you are not currently installed 检测到您当前未安装debian\${RESET}"
	fi
	echo "\${YELLOW}按回车键确认移除 Press enter to confirm.\${RESET} "
  pkill proot 2>/dev/null
	read
    chmod 777 -R ${DebianFolder}
	rm -rfv "${DebianFolder}" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc $PREFIX/bin/startxsdl $PREFIX/bin/debian-rm $PREFIX/bin/code 2>/dev/null || tsudo rm -rfv "${DebianFolder}" $PREFIX/bin/debian $PREFIX/bin/startvnc $PREFIX/bin/stopvnc $PREFIX/bin/startxsdl $PREFIX/bin/debian-rm $PREFIX/bin/code 2>/dev/null

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
		y*|Y*|"") rm -vf ~/debian-sid-rootfs.tar.xz 2>/dev/null
    rm -f $PREFIX/bin/debian-rm
		rm -vf ~/debian-buster-rootfs.tar.xz 2>/dev/null
		rm -vf ~/ubuntu-focal-rootfs.tar.xz 2>/dev/null
		rm -vf ~/kali-rolling-rootfs.tar.xz 2>/dev/null
		rm -vf ~/funtoo-1.3-rootfs.tar.xz 2>/dev/null
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
grep -q 'alias debian' $PREFIX/etc/profile && sed -i '/alias debian=/d' $PREFIX/etc/profile
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

if [ ! -d /usr/share/command-not-found ]; then
  dependencies="${dependencies} command-not-found"
fi

if [ ! -e /usr/bin/git ]; then
  dependencies="${dependencies} git"
fi

if [ ! -e /usr/bin/fzf ]; then
  dependencies="${dependencies} fzf"
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
" ~/.zshrc >~/.zshrc-omztemp
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
  *com.termux*)
    termux=true
    zsh=zsh
    ;;
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
    echo $SHELL >~/.shell.pre-oh-my-zsh
  else
    grep "^$USER:" /etc/passwd | awk -F: '{print $7}' >~/.shell.pre-oh-my-zsh
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
    --unattended)
      RUNZSH=no
      CHSH=no
      ;;
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
  echo "Configuring zsh theme 正在配置zsh主题(powerlevel 10k)..."
  cd /root/.oh-my-zsh/custom/themes || mkdir -p /root/.oh-my-zsh/custom/themes && cd /root/.oh-my-zsh/custom/themes
  rm -rf "/root/.oh-my-zsh/custom/themes/powerlevel10k"
  git clone https://gitee.com/mo2/powerlevel10k.git "/root/.oh-my-zsh/custom/themes/powerlevel10k" --depth=1
  sed -i '/^ZSH_THEME/d' "/root/.zshrc"
  sed -i "1 i\ZSH_THEME='powerlevel10k/powerlevel10k'" "/root/.zshrc"
 # sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnosterzak"/g' ~/.zshrc
  echo '检测到您选择的是powerlevel 10k主题,若无法弹出配置面板，则请拉宽屏幕显示大小，然后输p10k configure'
if ! grep -q '.p10k.zsh' '/root/.zshrc'; then
   wget -qO /root/.p10k.zsh 'https://gitee.com/mo2/Termux-zsh/raw/p10k/.p10k.zsh'
   cat >>'/root/.zshrc'<<-'EndOfp10K'
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh 
EndOfp10K
fi 
  if [ -e "/etc/tmp/.ChrootInstallationDetectionFile" ]; then
    grep -q 'unset LD_PRELOAD' /root/.zshrc >/dev/null 2>&1 || sed -i "1 a\unset LD_PRELOAD" /root/.zshrc >/dev/null 2>&1
    grep -q 'zh_CN.UTF-8' /root/.zshrc >/dev/null 2>&1 || sed -i "$ a\export LANG=zh_CN.UTF-8" /root/.zshrc >/dev/null 2>&1
    grep -q 'HOME=/root' /root/.zshrc >/dev/null 2>&1 || sed -i "$ a\export HOME=/root" /root/.zshrc >/dev/null 2>&1
    grep -q 'cd /root' /root/.zshrc >/dev/null 2>&1 || sed -i "$ a\cd /root" /root/.zshrc >/dev/null 2>&1
  fi

  cd ~
  sed -i '1 r vnc-autostartup-zsh' ~/.zshrc


  rm -f vnc-autostartup-zsh

  if [ -e "/usr/lib/command-not-found" ]; then
    grep -q 'command-not-found/command-not-found.plugin.zsh' /root/.zshrc 2>/dev/null || sed -i "$ a\source /root/.oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh" /root/.zshrc
    if ! grep -qi 'Ubuntu' '/etc/os-release'; then
      echo "正在配置command-not-found插件..."
      apt-file update 2>/dev/null
      update-command-not-found 2>/dev/null
    fi
  fi

  echo "正在克隆zsh-syntax-highlighting语法高亮插件..."

  rm -rf /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 2>/dev/null
  mkdir -p /root/.oh-my-zsh/custom/plugins

  # git clone --depth=1 git://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh-syntax-highlighting
  git clone --depth=1 https://gitee.com/mo2/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

  grep -q 'zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' /root/.zshrc >/dev/null 2>&1 || sed -i "$ a\source /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" /root/.zshrc
  #echo -e "\nsource /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> /root/.zshrc

  echo "正在克隆zsh-autosuggestions自动补全插件..."
  rm -rf /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions 2>/dev/null

  #git clone --depth=1 git://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone --depth=1 https://gitee.com/mo2/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions

  grep -q '/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' /root/.zshrc >/dev/null 2>&1 || sed -i "$ a\source /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" /root/.zshrc
  #echo -e "\nsource /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> /root/.zshrc

  echo "正在克隆fzf-tab插件..."
  rm -rf /root/.oh-my-zsh/custom/plugins/fzf-tab 2>/dev/null
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab.git /root/.oh-my-zsh/custom/plugins/fzf-tab || git clone --depth=1 https://gitee.com/mo2/fzf-tab.git /root/.oh-my-zsh/custom/plugins/fzf-tab 
  
  grep -q 'custom/plugins/fzf-tab/fzf-tab.zsh' '/root/.zshrc' >/dev/null 2>&1 || sed -i "$ a\source /root/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.zsh" /root/.zshrc
if ! grep -q 'extract=' "/root/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.zsh"; then
    cat >>"/root/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.zsh" <<-'EndOFfzfTab'
    local extract="
# 提取当前选择的内容
in=\${\${\"\$(<{f})\"%\$'\0'*}#*\$'\0'}
# 获取当前补全状态的上下文
local -A ctxt=(\"\${(@ps:\2:)CTXT}\")
"
    zstyle ':fzf-tab:complete:*:*' extra-opts --preview=$extract'ls -A1 --color=always ${~ctxt[hpre]}$in 2>/dev/null'
EndOFfzfTab
fi

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

if [ "$(cat /etc/issue | cut -c 1-6)" = "Ubuntu" ]; then
    cat >/etc/apt/sources.list <<-'EndOfFile'
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ focal main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ focal-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ focal-backports main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ focal-security main restricted universe multiverse
# proposed为预发布软件源，不建议启用
# deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ focal-proposed main restricted universe multiverse
EndOfFile
    touch ~/.hushlogin
fi

#配置dns解析
rm -f /etc/resolv.conf
cat > /etc/resolv.conf <<-'EndOfFile'
nameserver 114.114.114.114
nameserver 240c::6666
EndOfFile

apt update
apt install -y locales
if grep -q 'ubuntu' /etc/os-release; then
    apt install -y language-pack-zh-hans
fi

echo "您已成功安装GNU/Linux,之后可以输${YELLOW}debian${RESET}来进入debian system."
echo 'Congratulations on your successful installation of Debian GNU/Linux. After that, you can enter debian in termux to enter the debian system. '
echo '正在执行优化步骤，请勿退出!'
echo 'Optimization steps are in progress. Do not exit!'

#配置国内时区
echo 'Asia/Shanghai' >/etc/timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "正在配置中文环境..."
echo "Configuring Chinese environment..."
sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen

cat >/etc/default/locale <<-'EOF'
LANG="zh_CN.UTF-8"
LANGUAGE="zh_CN:zh"
#LC_ALL=zh_CN.UTF-8
EOF
locale-gen
source /etc/default/locale 2>/dev/null

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
apt install -y ca-certificates wget

if grep -q 'Funtoo GNU/Linux' '/etc/os-release'; then
    GNULINUXOSRELEASE=FUNTOO
    grep -q 'zh_CN' /etc/locale.gen || echo -e '\nzh_CN.UTF-8 UTF-8\nen_US.UTF-8 UTF-8' >>/etc/locale.gen
    locale-gen
    mkdir -p '/usr/portage'
    #下面生成的文件不要留空格
cat >/etc/portage/make.conf <<-'Endofmakeconf'
L10N="zh-CN en-US"
LINGUAS="zh_CN en_US"
#GENTOO_MIRRORS="https://mirrors.ustc.edu.cn/gentoo/"
GENTOO_MIRRORS="https://mirrors.tuna.tsinghua.edu.cn/gentoo"
EMERGE_DEFAULT_OPTS="--keep-going --with-bdeps=y"
#FEATURES="${FEATURES} -userpriv -usersandbox -sandbox"
ACCEPT_LICENSE="*"
Endofmakeconf
    source /etc/portage/make.conf 2>/dev/null
    mkdir -p /etc/portage/repos.conf/
cat >/etc/portage/repos.conf/gentoo.conf <<-'EndofgentooConf'
[gentoo]
location = /usr/portage
sync-type = rsync
#sync-uri = rsync://rsync.mirrors.ustc.edu.cn/gentoo-portage/
sync-uri = rsync://mirrors.tuna.tsinghua.edu.cn/gentoo-portage/
auto-sync = yes
EndofgentooConf
    source /etc/portage/repos.conf/gentoo.conf
    #同步过于耗时，故注释掉
    #emerge --sync
    emerge --config sys-libs/timezone-data 2>/dev/null
    #etc-update
    emerge eix 2>/dev/null
    echo '检测到您当前的系统为Funtoo GNU/Linux,将不会为您继续配置任何优化步骤！'
    rm -f vnc* zsh* .profile
    mv -f .profile.bak .profile 2>/dev/null
    #wget -qO- 'https://gitee.com/mirrors/neofetch/raw/master/neofetch' | bash -
    wget -qcO /usr/local/bin/neofetch 'https://gitee.com/mirrors/neofetch/raw/master/neofetch'
    chmod +x /usr/local/bin/neofetch
    neofetch
    bash
    exit 0

elif grep -qi 'Void' '/etc/issue'; then
    LINUXDISTRO='void'
    cat >/etc/locale.conf <<-'EOF'
LANG="zh_CN.UTF-8"
LANGUAGE="zh_CN:zh"
LC_COLLATE=C
EOF
    mkdir -p /etc/xbps.d
    cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
    sed -i 's|https://alpha.de.repo.voidlinux.org|https://mirrors.tuna.tsinghua.edu.cn/voidlinux|g' /etc/xbps.d/*-repository-*.conf
    xbps-install -S
    xbps-install -y wget
    wget -qO- 'https://gitee.com/mirrors/neofetch/raw/master/neofetch' | bash -
    rm -f vnc* zsh* .profile
    mv -f .profile.bak .profile 2>/dev/null
    wget -qO zsh.sh 'https://gitee.com/mo2/Termux-zsh/raw/master/termux-zsh.sh'
    sed -i '1 c\#!/bin/bash' zsh.sh
    chmod +x zsh.sh
    echo '检测到您当前的系统为Void GNU/Linux,将不会为您继续配置任何优化步骤！'
    zsh 2>/dev/null || bash
    exit 0
fi


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
export PULSE_SERVER=tcp:127.0.0.1:4713
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
echo '若xsdl音频端口不是4713，而是4712，则请输xsdl-4712进行修复。'
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
apt-mark hold gvfs
apt update
echo "Gnome测试失败，请自行解决软件依赖和其它相关问题。"
echo '即将为您安装思源黑体(中文字体)、aptitude、tightvncserver和task-gnome-desktop'
apt install -y fonts-noto-cjk aptitude tightvncserver
mkdir -p /run/lock
touch /var/lib/aptitude/pkgstates
#aptitude install -y task-gnome-desktop || apt install -y task-gnome-desktop
apt-get install --no-install-recommends xorg gnome-session gnome-menus gnome-tweak-tool gnome-shell || aptitude install -y gnome-core
apt install -y xinit dbus-x11
apt clean

mkdir -p ~/.vnc
cd ~/.vnc
cat >xstartup<<-'EndOfFile'
#!/bin/bash
xrdb ${HOME}/.Xresources
export PULSE_SERVER=127.0.0.1
#xsetroot -solid grey
#x-terminal-emulator -geometry  80×24+10+10 -ls -title "$VNCDESKTOP Desktop" &
#x-window-manager &
# Fix to make GNOME work
#export XKL_XMODMAP_DISABLE=1
#/etc/X11/Xsession
dbus-launch gnome-session &
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
export PULSE_SERVER=tcp:127.0.0.1:4713
echo '正在为您启动xsdl,请将display number改为0'
echo 'Starting xsdl, please change display number to 0'
echo '默认为前台运行，您可以按Ctrl+C终止，或者在termux原系统内输stopvnc'
echo 'The default is to run in the foreground, you can press Ctrl + C to terminate, or type "stopvnc" in the original termux system.'
dbus-launch gnome-session
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
echo '若xsdl音频端口不是4713，而是4712，则请输xsdl-4712进行修复。'
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
#echo "KDE测试失败，请自行解决软件依赖和其它相关问题。"
#后期注：测试成功，但存在bug。
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
xrdb ${HOME}/.Xresources
export PULSE_SERVER=127.0.0.1
#plasma_session &
dbus-launch startkde & || dbus-launch startplasma-x11 &
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
export PULSE_SERVER=tcp:127.0.0.1:4713
echo '正在为您启动xsdl,请将display number改为0'
echo 'Starting xsdl, please change display number to 0'
echo '默认为前台运行，您可以按Ctrl+C终止，或者在termux原系统内输stopvnc'
echo 'The default is to run in the foreground, you can press Ctrl + C to terminate, or type "stopvnc" in the original termux system.'
#plasma_session &
dbus-launch startkde  || dbus-launch startplasma-x11 
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
echo '若xsdl音频端口不是4713，而是4712，则请输xsdl-4712进行修复。'
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
grep -q 'export DISPLAY' /etc/profile || echo "export DISPLAY=":1"" >>/etc/profile

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

echo "Automatically configure zsh after 2 seconds,you can press Ctrl + C to cancel."
echo "2s后将自动开始配置zsh，您可以按Ctrl+C取消，这将不会继续配置其它步骤，同时也不会启动Tmoe-debian工具。"
#wget -qO- 'https://gitee.com/mirrors/neofetch/raw/master/neofetch' | bash -
wget -qcO /usr/local/bin/neofetch 'https://gitee.com/mirrors/neofetch/raw/master/neofetch'
chmod +x /usr/local/bin/neofetch
neofetch
bash zsh.sh
EDITBASHPROFILE

bash /data/data/com.termux/files/usr/bin/debian
