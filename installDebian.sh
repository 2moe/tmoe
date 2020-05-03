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
s390*)
  archtype="s390x"
  ;;
ppc*)
  archtype="ppc64el"
  ;;
mips*)
  archtype="mipsel"
  #echo -e 'Embedded devices such as routers are not supported at this time\n暂不支持mips架构的嵌入式设备'
  #exit 1
  ;;
risc*)
  #archtype="riscv"
  echo "检测到您当前的架构为risc-v，将为您安装arm64版的容器。"
  archtype="arm64"
  #此处改为arm64，
  #2020-03-23加入riscv+qemu跨架构运行的测试版功能
  #echo '暂不支持risc-v'
  #echo 'The RISC-V architecture you are using is too advanced and we do not support it yet.'
  #exit 1
  ;;
*)
  echo "未知的架构 $(uname -m) unknown architecture"
  exit 1
  ;;
esac

#安装必要依赖
#apt update
#apt install -y curl openssl proot aria2 procps
#gentoo在下一行修改archtype的变量

#requirements and DEPENDENCIES.

DEPENDENCIES=""

if [ "$(uname -o)" = "Android" ]; then
  LINUX_DISTRO='Android'
  termux-setup-storage
  if [ ! -e ${PREFIX}/bin/proot ]; then
    DEPENDENCIES="${DEPENDENCIES} proot"
  fi

  if [ ! -e ${PREFIX}/bin/pkill ]; then
    DEPENDENCIES="${DEPENDENCIES} procps"
  fi

  if [ ! -e ${PREFIX}/bin/pv ]; then
    DEPENDENCIES="${DEPENDENCIES} pv"
  fi

  if [ ! -e ${PREFIX}/bin/curl ]; then
    DEPENDENCIES="${DEPENDENCIES} curl"
  fi

  if [ ! -e ${PREFIX}/bin/aria2c ]; then
    DEPENDENCIES="${DEPENDENCIES} aria2"
  fi

  if [ ! -z "${DEPENDENCIES}" ]; then
    echo "正在安装相关依赖..."
    apt install -y ${DEPENDENCIES}
  fi
  cd ~/.termux || mkdir -p ~/.termux && cd ~/.termux
  if [ ! -e "colors.properties" ]; then
    echo '检测到termux配色文件不存在，正在自动生成...'
    # aria2c --allow-overwrite=true -o "colors.properties" 'https://gitee.com/mo2/zsh/raw/master/.termux/colors.properties'
    cat >colors.properties <<-'EndofMonokai'
	# monokai.dark.colors
	# Color scheme from https://github.com/Mayccoll/Gogh
	color0=#75715e
	color1=#f92672
	color2=#a6e22e
	color3=#f4bf75
	color4=#66d9ef
	color5=#ae81ff
	color6=#2AA198
	color7=#f9f8f5
	color8=#272822
	color9=#f92672
	color10=#a6e22e
	color11=#f4bf75
	color12=#66d9ef
	color13=#ae81ff
	color14=#2AA198
	color15=#f8f8f2
	background=#272822
	foreground=#f8f8f2
	cursor=#f8f8f2
EndofMonokai
  fi

  if [ ! -e "termux.properties" ]; then
    echo "检测到termux属性文件不存在，正在为您下载..."
    aria2c --allow-overwrite=true -o "termux.properties" 'https://gitee.com/mo2/zsh/raw/master/.termux/termux.properties'
  fi
  REMOTEP10KFONT='8597c76c4d2978f4ba022dfcbd5727a1efd7b34a81d768362a83a63b798f70e5'
  LOCALFONT="$(sha256sum font.ttf | cut -c 1-64)" || LOCALFONT="0"
  if [ "${REMOTEP10KFONT}" != "${LOCALFONT}" ]; then
    echo '正在配置字体...'
    #仓库为Termux-zsh/raw/p10k，批量重命名的时候要小心一点。
    aria2c --allow-overwrite=true -o Iosevka.tar.xz 'https://gitee.com/mo2/Termux-zsh/raw/p10k/Iosevka.tar.xz'
    mv -f font.ttf font.ttf.bak
    tar -Jxf Iosevka.tar.xz
    rm -f Iosevka.tar.xz
    termux-reload-settings
  fi
else
  if grep -q 'alias debian=' "/etc/profile"; then
    sed -i '/alias debian-i=/d' "/etc/profile"
    sed -i '/alias startvnc=/d' "/etc/profile"
    sed -i '/alias stopvnc=/d' "/etc/profile"
    sed -i '/alias debian-i=/d' "/etc/profile"
  fi

  if grep -q 'alias debian=' "${HOME}/.zshrc"; then
    sed -i '/alias debian-i=/d' "${HOME}/.zshrc"
    sed -i '/alias startvnc=/d' "${HOME}/.zshrc"
    sed -i '/alias stopvnc=/d' "${HOME}/.zshrc"
    sed -i '/alias debian-i=/d' "${HOME}/.zshrc"
  fi
fi
#旧版将相关设立了alias，新版需要删掉。
####################
#卸载chroot挂载目录
if [ -e "${DebianCHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
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
  if grep -Eq "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
    LINUX_DISTRO='openwrt'
    if [ -d "/opt/bin" ]; then
      PREFIX="/opt"
    else
      PREFIX=${HOME}
    fi
  else
    #PREFIX=/data/data/com.termux/files/usr
    PREFIX='/usr/local'
  fi
  mkdir -p ${PREFIX}/bin
fi

if [ "$(uname -v | cut -c 1-3)" = "iSH" ]; then
  LINUX_DISTRO='iSH'
  echo "检测到您使用的是iOS系统"
elif grep -Eqi "Fedora|CentOS|Red Hat|redhat" '/etc/os-release' 2>/dev/null; then
  LINUX_DISTRO='redhat'
  if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
    REDHAT_DISTRO='centos'
  elif grep -q 'Fedora' "/etc/os-release"; then
    REDHAT_DISTRO='fedora'
  fi
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
if [ -f "${HOME}/.RASPBIANARMHFDetectionFILE" ]; then
  echo "检测到您选择的是raspbian树莓派系统，将通过debian buster来间接安装raspbian buster"
  echo "已将您的架构临时识别为armhf"
fi
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
  if [ "${archtype}" != 'mipsel' ]; then
    echo "正在从清华大学开源镜像站下载容器镜像"
    echo "Downloading debian-sid-rootfs.tar.xz from Tsinghua University Open Source Mirror Station."
    ttime=$(curl -L "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${archtype}/default/" | grep date | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
    if [ "${LINUX_DISTRO}" != 'iSH' ]; then
      aria2c -x 5 -k 1M --split 5 -o $DebianTarXz "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${archtype}/default/${ttime}rootfs.tar.xz"
    else
      wget -O $DebianTarXz "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${archtype}/default/${ttime}rootfs.tar.xz"
    fi
  else
    aria2c -x 16 -k 1M --split 16 -o $DebianTarXz 'https://cdn.tmoe.me/Tmoe-Debian-Tool/chroot/debian_mipsel.tar.xz' || aria2c -x 16 -k 1M --split 16 -o $DebianTarXz 'https://m.tmoe.me/show/share/Tmoe-linux/chroot/debian_mipsel.tar.xz'
  fi
fi
cur=$(pwd)
cd ${DebianCHROOT}
echo "正在解压debian-sid-rootfs.tar.xz，Decompressing Rootfs, please be patient."
if [ "${LINUX_DISTRO}" = "Android" ]; then
  pv ${cur}/${DebianTarXz} | proot --link2symlink tar -pJx
elif [ "${LINUX_DISTRO}" = "iSH" ]; then
  tar -pJxvf ${cur}/${DebianTarXz}
elif [ "${archtype}" = "mipsel" ]; then
  cd ~
  pv ${DebianTarXz} | tar -pJx
elif [ "${LINUX_DISTRO}" = "redhat" ]; then
  if [ "${REDHAT_DISTRO}" != "fedora" ]; then
    tar -pJxvf ${cur}/${DebianTarXz}
  else
    pv ${cur}/${DebianTarXz} | tar -pJx
  fi
else
  pv ${cur}/${DebianTarXz} | tar -pJx
fi
cp -f ~/.termux/font.ttf ~/${DebianFolder}/tmp/ 2>/dev/null
if [ "${LINUX_DISTRO}" = 'openwrt' ]; then
  touch ~/${DebianFolder}/tmp/.openwrtcheckfile
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

if [ -f "${HOME}/.Chroot-Container-Detection-File" ]; then
  #rm -f ${HOME}/.Chroot-Container-Detection-File
  echo "Creating chroot startup script"
  echo "正在创建chroot启动脚本${PREFIX}/bin/debian "
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

  grep -q 'en_US.UTF-8' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\export LANG=en_US.UTF-8" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep -q 'HOME=/root' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\export HOME=/root" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  grep -q 'cd /root' ${DebianCHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\cd /root" ${DebianCHROOT}/etc/profile >/dev/null 2>&1

  #此处EndOfChrootFile不要加单引号
  cat >${PREFIX}/bin/debian <<-EndOfChrootFile
  #!/data/data/com.termux/files/usr/bin/bash
  DebianCHROOT=${HOME}/${DebianFolder}
  if [ ! -e "${DebianCHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
    echo "本文件为chroot容器检测文件 Please do not delete this file!" >>${DebianCHROOT}/tmp/.Chroot-Container-Detection-File 2>/dev/null
  fi
  #sed替换匹配行,加密内容为chroot登录shell。为防止匹配行被替换，故采用base64加密。
  DEFAULTZSHLOGIN="\$(echo 'Y2hyb290ICR7RGViaWFuQ0hST09UfSAvYmluL3pzaCAtLWxvZ2luCg==' | base64 -d)"
  DEFAULTBASHLOGIN="\$(echo 'Y2hyb290ICR7RGViaWFuQ0hST09UfSAvYmluL2Jhc2ggLS1sb2dpbgo=' | base64 -d)"

  if [ -f ${DebianCHROOT}/bin/zsh ]; then
    sed -i "s:\${DEFAULTBASHLOGIN}:\${DEFAULTZSHLOGIN}:g" ${PREFIX}/bin/debian
  else
    sed -i "s:\${DEFAULTZSHLOGIN}:\${DEFAULTBASHLOGIN}:g" ${PREFIX}/bin/debian
  fi

  if [ "\$(id -u)" != "0" ]; then
    su -c "/bin/sh ${PREFIX}/bin/debian"
    exit
  fi
  mount -o bind /dev ${DebianCHROOT}/dev >/dev/null 2>&1
  #mount -o bind /dev /dev >/dev/null 2>&1

  mount -t proc proc ${DebianCHROOT}/proc >/dev/null 2>&1
  #mount -t proc proc /proc >/dev/null 2>&1

  mount -t sysfs sysfs ${DebianCHROOT}/sys >/dev/null 2>&1

  mount -t devpts devpts ${DebianCHROOT}/dev/pts >/dev/null 2>&1
  # mount -t devpts devpts /dev/pts >/dev/null 2>&1

  #mount --bind /dev/shm ${DebianCHROOT}/dev/shm >/dev/null 2>&1
  mount -o rw,nosuid,nodev,mode=1777 -t tmpfs tmpfs /dev/shm >/dev/null 2>&1

  #mount -t tmpfs tmpfs ${DebianCHROOT}/tmp  >/dev/null 2>&1

  mount --rbind ${DebianCHROOT} ${DebianCHROOT}/ >/dev/null 2>&1

  if [ "$(uname -o)" = "Android" ]; then
    TFcardFolder="\$(su -c 'ls /mnt/media_rw/ 2>/dev/null | head -n 1')"
    if [ -d "/mnt/media_rw/\${TFcardFolder}" ]; then
      mount -o bind /mnt/media_rw/\${TFcardFolder} ${DebianCHROOT}/root/tf >/dev/null 2>&1
    fi
    if [ -d "/data/data/com.termux/files/home" ]; then
      mount -o bind /data/data/com.termux/files/home ${DebianCHROOT}/root/termux >/dev/null 2>&1
    fi
    if [ -d "/sdcard" ]; then
      mount -o bind /sdcard ${DebianCHROOT}/root/sd >/dev/null 2>&1
      #mount --rbind /sdcard ${DebianCHROOT}/root/sd >/dev/null 2>&1
    fi
  fi
  chroot \${DebianCHROOT} /bin/bash --login

EndOfChrootFile
#上面那行不要有空格
else

  echo "Creating proot startup script"
  echo "正在创建proot启动脚本${PREFIX}/bin/debian "
  #此处EndOfFile不要加单引号
  cat >${PREFIX}/bin/debian <<-EndOfFile
#!/data/data/com.termux/files/usr/bin/bash
cd ~
pulseaudio --kill 2>/dev/null
pulseaudio --start
#pulseaudio需为第4行，否则将影响tsudo function
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
command+=" LANG=en_US.UTF-8"
command+=" /bin/bash --login"
com="\$@"
#为防止匹配行被替换，故采用base64加密。
DEFAULTZSHLOGIN="\$(echo 'Y29tbWFuZCs9IiAvYmluL3pzaCAtLWxvZ2luIgo=' | base64 -d)"
DEFAULTBASHLOGIN="\$(echo 'Y29tbWFuZCs9IiAvYmluL2Jhc2ggLS1sb2dpbiIK' | base64 -d)"

if [ -f ~/${DebianFolder}/bin/zsh ];then
    sed -i "s:\${DEFAULTBASHLOGIN}:\${DEFAULTZSHLOGIN}:g" ${PREFIX}/bin/debian
else
    sed -i "s:\${DEFAULTZSHLOGIN}:\${DEFAULTBASHLOGIN}:g" ${PREFIX}/bin/debian
fi

if [ ! -e "${DebianCHROOT}/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
  echo "本文件为Proot容器检测文件 Please do not delete this file!" >>${DebianCHROOT}/tmp/.Tmoe-Proot-Container-Detection-File 2>/dev/null
fi

if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EndOfFile
fi
#######################################################

cat >${PREFIX}/bin/startvnc <<-EndOfFile
#!/data/data/com.termux/files/usr/bin/bash
pulseaudio --kill 2>/dev/null
am start -n com.realvnc.viewer.android/com.realvnc.viewer.android.app.ConnectionChooserActivity
touch ~/${DebianFolder}/root/.vnc/startvnc
${PREFIX}/bin/debian
EndOfFile
#debian前不需要加上bash

cat >${PREFIX}/bin/stopvnc <<-'EndOfFile'
#!/data/data/com.termux/files/usr/bin/bash
#pkill -u $(whoami)
sh -c "$(ps -e | grep -Ev "sshd|pkill|systemd" | awk '{print $4}' | sed '/(/d' | sed 's/^/pkill &/g')"
EndOfFile

#不要单引号
cat >${PREFIX}/bin/startxsdl <<-EndOfFile
#!/data/data/com.termux/files/usr/bin/bash
am start -n x.org.server/x.org.server.MainActivity
touch ~/${DebianFolder}/root/.vnc/startxsdl
/data/data/com.termux/files/usr/bin/debian
EndOfFile

#wget -qO ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh'
aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh'
cat >${PREFIX}/bin/debian-rm <<-EndOfFile
    #!/data/data/com.termux/files/usr/bin/bash
	  YELLOW=\$(printf '\033[33m')
	  RESET=\$(printf '\033[m')
    cd ~
    
  if [ -e "${DebianCHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
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
  echo '建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！'
  echo "Before removing the system, make sure you have unmounted the chroot mount directory.
It is recommended that you back up the entire system before removal. If the data is lost due to improper operation, the developer is not responsible! "
  fi
  echo "移除系统前，请先确保您已停止容器的进程。"
  pkill proot 2>/dev/null
  ps -e | grep proot
  ps -e | grep startvnc
  pgrep proot &> /dev/null
if [ "\$?" = "0" ]; then
    echo '检测到proot容器正在运行，请先输stopvnc停止运行'
fi

	ls -l ${DebianCHROOT}/root/sd/* 2>/dev/null
	if [ "\$?" = "0" ]; then
		echo 'WARNING！检测到/root/sd 无法强制卸载，您当前使用的可能是chroot容器'
		echo "若为误报，则请先停止容器进程，再手动移除${DebianCHROOT}/root/sd"
		echo '建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！'
		echo '为防止数据丢失，禁止移除容器！请重启设备后再重试。'
		echo "Press enter to exit."
		echo "${YELLOW}按回车键退出。${RESET} "
		read
		exit 0
	fi

 #echo '检测到chroot容器正在运行，您可以输pkill -u $(whoami) 来终止所有进程'    
  #echo "若容器未停止运行，则建议你先手动在termux原系统中执行stopvnc，再进行移除操作。"
	echo 'Detecting debian system size... 正在检测debian system占用空间大小'
  	du -sh ./${DebianFolder} --exclude=./${DebianFolder}/root/tf --exclude=./${DebianFolder}/root/sd --exclude=./${DebianFolder}/root/termux
	if [ ! -d ~/${DebianFolder} ]; then
		echo "\${YELLOW}Detected that you are not currently installed 检测到您当前未安装debian\${RESET}"
	fi
	echo "\${YELLOW}按回车键确认移除 Press enter to confirm.\${RESET} "
  pkill proot 2>/dev/null
	read
    chmod 777 -R ${DebianFolder}
	rm -rfv "${DebianFolder}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code 2>/dev/null || tsudo rm -rfv "${DebianFolder}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code 2>/dev/null

    sed -i '/alias debian=/d' ${PREFIX}/etc/profile
	  sed -i '/alias debian-rm=/d' ${PREFIX}/etc/profile
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
    rm -f ${PREFIX}/bin/debian-rm
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

#   sed -i '/external-1/d' ${PREFIX}/bin/debian

#fi

if [ ! -L '/data/data/com.termux/files/home/storage/external-1' ]; then

  sed -i 's@^command+=" -b /data/data/com.termux/files/home/storage/external-1@#&@g' ${PREFIX}/bin/debian 2>/dev/null
  sed -i 's@^mount -o bind /mnt/media_rw/@#&@g' ${PREFIX}/bin/debian 2>/dev/null
fi
echo 'Giving startup script execution permission'
echo "正在赋予启动脚本(${PREFIX}/bin/debian)执行权限"
#termux-fix-shebang ${PREFIX}/bin/debian
cd ${PREFIX}/bin

chmod +x debian startvnc stopvnc debian-rm debian-i startxsdl

#设定alias,防止debian-root的alias依旧在生效。
alias debian="${PREFIX}/bin/debian"
alias debian-rm="${PREFIX}/bin/debian-rm"

echo "You can type rm ~/${DebianTarXz} to delete the image file"
echo "您可以输rm ~/${DebianTarXz}来删除容器镜像文件"
ls -lh ~/${DebianTarXz}

cd ~/${DebianFolder}
#配置卸载脚本
cat >remove-debian.sh <<-EOF
#!/data/data/com.termux/files/usr/bin/bash
cd ~
chmod 777 -R ${DebianFolder}
rm -rfv "${DebianFolder}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc 2>/dev/null || tsudo rm -rf "debian_$archtype" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc
if grep -q 'alias debian' "${PREFIX}/etc/profile"; then
  sed -i '/alias debian=/d' ${PREFIX}/etc/profile
  sed -i '/alias debian-rm=/d' ${PREFIX}/etc/profile
  source profile >/dev/null 2>&1
fi
echo '删除完成，如需卸载aria2,请输apt remove aria2'
echo '如需删除镜像文件，请输rm -f ~/debian-sid-rootfs.tar.xz'
EOF
chmod +x remove-debian.sh

########################

if [ -d "${DebianCHROOT}/usr/local/bin" ]; then
  mkdir -p ${DebianCHROOT}/usr/local/bin
fi

if [ -f "${HOME}/.Tmoe-Proot-Container-Detection-File" ]; then
  mv -f "${HOME}/.Tmoe-Proot-Container-Detection-File" ${DebianCHROOT}/tmp
  echo "本文件为Proot容器检测文件 Please do not delete this file!" >>${DebianCHROOT}/tmp/.Tmoe-Proot-Container-Detection-File 2>/dev/null
elif [ -f "${HOME}/.Chroot-Container-Detection-File" ]; then
  mv -f "${HOME}/.Chroot-Container-Detection-File" ${DebianCHROOT}/tmp
  echo "本文件为Chroot容器检测文件 Please do not delete this file!" >>${DebianCHROOT}/tmp/.Chroot-Container-Detection-File 2>/dev/null
fi
cd ${DebianCHROOT}/usr/local/bin

curl -sLo "neofetch" 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch'
curl -sLo "debian-i" 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian-gui-install.bash'
chmod +x neofetch debian-i

cd ${DebianCHROOT}/root
chmod u+w "${DebianCHROOT}/root"
curl -sLo zsh-i.sh 'https://gitee.com/mo2/zsh/raw/master/zsh.sh'
sed -i 's:#!/data/data/com.termux/files/usr/bin/bash:#!/bin/bash:' zsh-i.sh
chmod +x zsh-i.sh
#zsh-i和zsh是不同的

if [ -f "${HOME}/.RASPBIANARMHFDetectionFILE" ]; then
  mv -f "${HOME}/.RASPBIANARMHFDetectionFILE" "${DebianCHROOT}/tmp/"
  #树莓派换源
  curl -Lo "raspbian-sources-gpg.tar.xz" 'https://gitee.com/mo2/patch/raw/raspbian/raspbian-sources-gpg.tar.xz'
  tar -Jxvf "raspbian-sources-gpg.tar.xz" -C ~/${DebianFolder}/etc/apt/
  rm -f "raspbian-sources-gpg.tar.xz"
elif [ -f "${HOME}/.REDHATDetectionFILE" ]; then
  rm -f "${HOME}/.REDHATDetectionFILE"
  chmod u+w "${DebianCHROOT}/root"
  rm -f ../etc/resolv.conf
  #使用相对路径
  cat >../etc/resolv.conf <<-'EndOfFile'
nameserver 1.0.0.1
nameserver 2606:4700:4700::1111
EndOfFile
elif [ -f "${HOME}/.ALPINELINUXDetectionFILE" ]; then
  #sed -i '/DEFAULTZSHLOGIN/d' $(command -v debian)
  #sed -i '/DEFAULTZSHLOGIN/d' $(command -v debian)
  #sed -i 's@sed -i \"s:\${DE@#&@g' $(command -v debian)
  sed -i 's/bash --login/ash --login/g' $(command -v debian)
  sed -i 's/zsh --login/ash --login/g' $(command -v debian)
  mv -f "${HOME}/.ALPINELINUXDetectionFILE" ${DebianCHROOT}/tmp
fi

#配置zsh
cat >zsh.sh <<-'ADDZSHSHELL'
#!/bin/bash

if grep -Eq 'debian|ubuntu' "/etc/os-release"; then
    LINUX_DISTRO='debian'
    if grep -q 'ubuntu' /etc/os-release; then
        DEBIAN_DISTRO='ubuntu'
    elif [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
        DEBIAN_DISTRO='kali'
    fi

elif grep -Eqi "Fedora|CentOS|Red Hat|redhat" '/etc/os-release'; then
    LINUX_DISTRO='redhat'
    if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
        REDHAT_DISTRO='centos'
    elif grep -q 'Fedora' "/etc/os-release"; then
        REDHAT_DISTRO='fedora'
    fi

elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" '/etc/os-release'; then
    LINUX_DISTRO='alpine'

elif grep -Eq "Arch|Manjaro" '/etc/os-release'; then
    LINUX_DISTRO='arch'

elif grep -qi 'Void' '/etc/issue'; then
    LINUX_DISTRO='void'

elif grep -qi 'suse' '/etc/os-release'; then
    LINUX_DISTRO='suse'

elif grep -Eq "gentoo|funtoo" '/etc/os-release'; then
    LINUX_DISTRO='gentoo'
fi
#####################
DEPENDENCIES=""
if [ ! -e /bin/bash ]; then
    DEPENDENCIES="${DEPENDENCIES} bash"
fi

if [ ! -e "/usr/lib/command-not-found" ]; then
    if [ "${LINUX_DISTRO}" = "debian" ]; then
        DEPENDENCIES="${DEPENDENCIES} command-not-found"
    fi
fi
##################
if [ "${LINUX_DISTRO}" = "debian" ]; then
    if [ ! -f "/tmp/.openwrtcheckfile" ]; then
        if [ ! -d /usr/share/command-not-found ]; then
            DEPENDENCIES="${DEPENDENCIES} command-not-found"
        fi
    fi

    if [ ! -d /usr/share/doc/fonts-powerline ]; then
        DEPENDENCIES="${DEPENDENCIES} fonts-powerline"
    fi
fi
###########################################
if [ ! -e /usr/bin/fzf ]; then
    if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "alpine" ] || [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCIES="${DEPENDENCIES} fzf"
    fi
fi

if [ ! -e /usr/bin/git ]; then
    if [ "${LINUX_DISTRO}" = "openwrt" ]; then
        DEPENDENCIES="${DEPENDENCIES} git git-http"
    elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
        DEPENDENCIES="${DEPENDENCIES} dev-vcs/git"
    else
        DEPENDENCIES="${DEPENDENCIES} git"
    fi
fi
####################################
if [ ! -e /usr/bin/wget ]; then
    if [ "${LINUX_DISTRO}" = "gentoo" ]; then
        DEPENDENCIES="${DEPENDENCIES} net-misc/wget"
    else
        DEPENDENCIES="${DEPENDENCIES} wget"
    fi
fi
###########################

if [ ! -e /bin/zsh ]; then
    if [ "${LINUX_DISTRO}" = "alpine" ]; then
        DEPENDENCIES="${DEPENDENCIES} zsh zsh-vcs"
    elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
        DEPENDENCIES="${DEPENDENCIES} app-shells/zsh"
    else
        DEPENDENCIES="${DEPENDENCIES} zsh"
    fi
fi

#############################
if [ ! -z "${DEPENDENCIES}" ]; then
    echo "正在安装相关依赖..."

    if [ "${LINUX_DISTRO}" = "debian" ]; then
        apt update
        apt install -y ${DEPENDENCIES} || apt install -y command-not-found zsh git wget whiptail command-not-found

    elif [ "${LINUX_DISTRO}" = "alpine" ]; then
        apk add ${DEPENDENCIES}
        #apk add xz newt tar zsh git wget bash zsh-vcs pv

    elif [ "${LINUX_DISTRO}" = "arch" ]; then
        pacman -Syu --noconfirm ${DEPENDENCIES}

    elif [ "${LINUX_DISTRO}" = "redhat" ]; then
        dnf install -y ${DEPENDENCIES} || yum install -y ${DEPENDENCIES}
        #dnf install -y zsh git pv wget xz tar newt || yum install -y zsh git pv wget xz tar newt

    elif [ "${LINUX_DISTRO}" = "openwrt" ]; then
        #opkg update
        opkg install ${DEPENDENCIES} || opkg install whiptail

    elif [ "${LINUX_DISTRO}" = "void" ]; then
        xbps-install -S
        xbps-install -y ${DEPENDENCIES}

    elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
        emerge -avk ${DEPENDENCIES}

    elif
        [ "${LINUX_DISTRO}" = "suse" ]
    then
        zypper in -y ${DEPENDENCIES}

    else
        apt update
        apt install -y command-not-found zsh git wget whiptail command-not-found || port install ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES}

    fi

fi
###############################
if [ -e "/usr/bin/curl" ]; then
    curl -Lo /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian-gui-install.bash'
else
    wget -qO /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian-gui-install.bash'
fi

chmod +x /usr/local/bin/debian-i

rm -rf ${HOME}/.oh-my-zsh
chsh -s /usr/bin/zsh
set -e
#change the default repo
#https://github.com/ohmyzsh/ohmyzsh
#https://gitee.com/mirrors/oh-my-zsh
# Default settings
ZSH=${ZSH:-~/.oh-my-zsh}

## REPO=${REPO:-mirrors/oh-my-zsh}
## REMOTE=${REMOTE:-https://gitee.com/${REPO}.git}

REPO=${REPO:-ohmyzsh/ohmyzsh}
REMOTE=${REMOTE:-git://github.com/${REPO}.git}
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
    case "${PREFIX}" in
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
        if ! zsh=$(command -v zsh) || ! grep -qx "$zsh" "$shells_file"; then
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

    printf "$BLUE"
    cat <<-'EOF'
		         __                                     __
		  ____  / /_     ____ ___  __  __   ____  _____/ /_
		 / __ \/ __ \   / __ `__ \/ / / /  /_  / / ___/ __ \
		/ /_/ / / / /  / / / / / / /_/ /    / /_(__  ) / / /
		\____/_/ /_/  /_/ /_/ /_/\__, /    /___/____/_/ /_/
		                        /____/                       ....is now installed!
		Please look over the ~/.zshrc file to select plugins, themes, and options.
    p.s. Get stickers, shirts, and coffee mugs at https://shop.planetargon.com/collections/oh-my-zsh
		p.p.s. Follow us on https://twitter.com/ohmyzsh

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

    if [ "$(uname -m)" = "mips" ]; then
        echo "Configuring zsh theme 正在配置zsh主题(agnoster)..."
        sed -i '/^ZSH_THEME/d' "${HOME}/.zshrc"
        sed -i "1 i\ZSH_THEME='agnoster'" "${HOME}/.zshrc"
    else
        echo "Configuring zsh theme 正在配置zsh主题(powerlevel 10k)..."
        cd ${HOME}/.oh-my-zsh/custom/themes || mkdir -p ${HOME}/.oh-my-zsh/custom/themes && cd ${HOME}/.oh-my-zsh/custom/themes
        rm -rf "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" || git clone --depth=1 git://github.com/romkatv/powerlevel10k "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
        sed -i '/^ZSH_THEME/d' "${HOME}/.zshrc"
        sed -i "1 i\ZSH_THEME='powerlevel10k/powerlevel10k'" "${HOME}/.zshrc"
        # sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnosterzak"/g' ~/.zshrc
        echo '检测到您选择的是powerlevel 10k主题,若无法弹出配置面板，则请拉宽屏幕显示大小，然后输p10k configure'
if ! grep -q '.p10k.zsh' "${HOME}/.zshrc"; then
    if [ -e "/usr/bin/curl" ]; then
        curl -sLo /root/.p10k.zsh 'https://gitee.com/mo2/Termux-zsh/raw/p10k/.p10k.zsh'
    else
        wget -qO /root/.p10k.zsh 'https://gitee.com/mo2/Termux-zsh/raw/p10k/.p10k.zsh'
    fi

    cat >>${HOME}/.zshrc <<-"ENDOFPOWERLEVEL"
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh 
ENDOFPOWERLEVEL
fi

    fi

    if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
        grep -q 'unset LD_PRELOAD' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "1 a\unset LD_PRELOAD" ${HOME}/.zshrc >/dev/null 2>&1
        grep -q 'en_US.UTF-8' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\export LANG=en_US.UTF-8" ${HOME}/.zshrc >/dev/null 2>&1
        grep -q 'HOME=/root' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\export HOME=/root" ${HOME}/.zshrc >/dev/null 2>&1
        grep -q 'cd /root' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\cd /root" ${HOME}/.zshrc >/dev/null 2>&1
    fi

    cd ~

 cat >~/.zlogin <<-'EndOfFile'
cat /etc/os-release | grep PRETTY_NAME |cut -d '"' -f 2

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
ps -e 2>/dev/null | tail -n 20
EndOfFile

if [ "${LINUX_DISTRO}" != "redhat" ]; then
    sed -i "1 c\cat /etc/issue" .zlogin
fi


    if [ "${LINUX_DISTRO}" = "debian" ]; then
        if [ -e "/usr/lib/command-not-found" ]; then
            grep -q 'command-not-found/command-not-found.plugin.zsh' ${HOME}/.zshrc 2>/dev/null || sed -i "$ a\source ${HOME}/.oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh" ${HOME}/.zshrc
            if [ "${DEBIAN_DISTRO}" != "ubuntu" ]; then
                echo "正在配置command-not-found插件..."
                apt-file update 2>/dev/null
                update-command-not-found 2>/dev/null
            fi
        fi
    fi
    echo "正在克隆zsh-syntax-highlighting语法高亮插件..."

    rm -rf ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 2>/dev/null
    mkdir -p ${HOME}/.oh-my-zsh/custom/plugins

    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting || git clone --depth=1 git://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh-syntax-highlighting ${HOME}/.oh-my-zsh/custom/plugins/

    grep -q 'zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\source ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ${HOME}/.zshrc
    #echo -e "\nsource ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${HOME}/.zshrc

    echo "正在克隆zsh-autosuggestions自动补全插件..."
    rm -rf ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions 2>/dev/null


    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions || git clone --depth=1 git://github.com/zsh-users/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestionszsh-autosuggestions

    grep -q '/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\source ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ${HOME}/.zshrc
    #echo -e "\nsource ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ${HOME}/.zshrc

    echo "正在克隆fzf-tab插件..."
    if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "alpine" ] || [ "${LINUX_DISTRO}" = "arch" ]; then
        if [ -e /usr/bin/fzf ] || [ -e /bin/fzf ]; then
            rm -rf ${HOME}/.oh-my-zsh/custom/plugins/fzf-tab 2>/dev/null
            git clone --depth=1 https://gitee.com/mo2/fzf-tab.git ${HOME}/.oh-my-zsh/custom/plugins/fzf-tab || git clone --depth=1 git://github.com/Aloxaf/fzf-tab.git ${HOME}/.oh-my-zsh/custom/plugins/fzf-tab

            grep -q 'custom/plugins/fzf-tab/fzf-tab.zsh' "${HOME}/.zshrc" >/dev/null 2>&1 || sed -i "$ a\source ${HOME}/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.zsh" ${HOME}/.zshrc
        fi
    fi

    if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "arch" ]; then
        sed -i 's/plugins=(git)/plugins=(git extract z)/g' ~/.zshrc
    else
        sed -i 's/plugins=(git)/plugins=(git extract)/g' ~/.zshrc
    fi

    if [ -f "/tmp/.openwrtcheckfile" ]; then
        ADMINACCOUNT="$(ls -l /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')"
        cp -rf /root/.z* /root/.oh-my-zsh /root/*sh /home/${ADMINACCOUNT}
        rm -f /tmp/.openwrtcheckfile
    fi

    echo 'All optimization steps have been completed, enjoy it!'
    echo 'zsh配置完成，2s后将为您启动Tmoe-linux工具'
    echo "您也可以手动输${YELLOW}debian-i${RESET}进入"
    echo 'After 2 seconds, Tmoe-linux gui installation manager will be launched.'
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
#配置国内镜像源
if [ "$(uname -m)" = "mips" ]; then
  chattr +i /etc/apt/sources.list
  sed -i 's:# en_US.UTF-8 UTF-8:en_US.UTF-8 UTF-8:' /etc/locale.gen
fi

if ! grep -Eqi 'debian|ubuntu|kali|raspbian|Mint' "/etc/issue"; then
  chattr +i /etc/apt/sources.list 2>/dev/null
fi

if [ ! -f "/tmp/.RASPBIANARMHFDetectionFILE" ]; then
    if grep -q 'Debian' "/etc/issue"; then
        sed -i 's/^deb/##&/g' /etc/apt/sources.list
        #stable-backports会出错，需改为buster-backports
        cat >>/etc/apt/sources.list <<-'EndOfFile'
#deb http://mirrors.huaweicloud.com/debian/ stable main contrib non-free
#deb http://mirrors.huaweicloud.com/debian/ stable-updates main contrib non-free
#deb http://mirrors.huaweicloud.com/debian/ buster-backports main contrib non-free
#deb http://mirrors.huaweicloud.com/debian-security stable/updates main contrib non-free
deb http://mirrors.huaweicloud.com/debian/ sid main contrib non-free
EndOfFile
    fi
fi
	if grep -q 'Kali' "/etc/issue"; then
echo "检测到您使用的是Kali系统"
sed -i 's/^deb/##&/g' /etc/apt/sources.list
cat >>/etc/apt/sources.list <<-"EndOfSourcesList"
deb http://mirrors.tuna.tsinghua.edu.cn/kali/ kali-rolling main contrib non-free
deb http://mirrors.huaweicloud.com/debian/ stable main contrib non-free
# deb http://mirrors.huaweicloud.com/kali/ kali-last-snapshot main contrib non-free
EndOfSourcesList
    #注意：kali-rolling添加debian testing源后，可能会破坏系统依赖关系，可以添加stable源（暂未发现严重影响）
	fi

if [ "$(cat /etc/issue | cut -c 1-6)" = "Ubuntu" ]; then
sed -i 's/^deb/##&/g' /etc/apt/sources.list
    cat >>/etc/apt/sources.list <<-'EndOfFile'
deb http://mirrors.huaweicloud.com/ubuntu-ports/ focal main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu-ports/ focal-updates main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu-ports/ focal-backports main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu-ports/ focal-security main restricted universe multiverse
# proposed为预发布软件源，不建议启用
# deb http://mirrors.huaweicloud.com/ubuntu-ports/ focal-proposed main restricted universe multiverse
EndOfFile
    touch ~/.hushlogin
fi

	if grep -q 'Mint' "/etc/issue"; then
echo "检测到您使用的是Linux Mint"
sed -i 's/^deb/##&/g' /etc/apt/sources.list
cat >>/etc/apt/sources.list <<-"EndOfSourcesList"
deb http://mirrors.huaweicloud.com/linuxmint/ tricia main upstream import backport
deb http://mirrors.huaweicloud.com/ubuntu/ bionic main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu/ bionic-backports main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu/ bionic-security main restricted universe multiverse
EndOfSourcesList
	fi

 sed -i 's/^deb/# &/g' /etc/apt/sources.list && sed -i 's/^##deb/deb/g' /etc/apt/sources.list

#配置dns解析
rm -f /etc/resolv.conf
cat > /etc/resolv.conf <<-'EndOfFile'
nameserver 1.0.0.1
nameserver 2606:4700:4700::1111
EndOfFile

if [ -f "/tmp/.ALPINELINUXDetectionFILE" ]; then
  echo "检测到您使用的不是deb系linux，将不会为您配置额外优化步骤"
  if [ "$(sed -n 2p /etc/os-release | cut -d '=' -f 2)" = "alpine"  ]; then
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
    apk update 
    apk add bash
  fi
  rm -f "/tmp/.ALPINELINUXDetectionFILE"
  rm -f ~/.profile
  mv -f ~/.profile.bak ~/.profile 2>/dev/null
  if grep -q 'OpenWrt' "/etc/os-release"; then
    mkdir -p /var/lock/
    touch /var/lock/opkg.lock
    opkg update
    opkg install libustream-openssl  ca-bundle ca-certificates bash
  fi
 # ash -c "$(wget --no-check-certificate -O- 'https://gitee.com/mo2/zsh/raw/master/zsh.sh')"
fi

if grep -q 'openSUSE' "/etc/issue"; then
    LINUX_DISTRO='opensuse'
    if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "armv7l" ]; then
        zypper mr -da
        zypper addrepo -fcg https://mirrors.tuna.tsinghua.edu.cn/opensuse/tumbleweed/repo/oss/ tuna-mirrors-oss
        zypper addrepo -fcg https://mirrors.tuna.tsinghua.edu.cn/opensuse/tumbleweed/repo/non-oss/ tuna-mirrors-non-oss
        zypper addrepo -fcg https://mirrors.tuna.tsinghua.edu.cn/packman/suse/openSUSE_Tumbleweed/ tuna-mirrors_Tumbleweed
        zypper --gpg-auto-import-keys refresh
        #zypper dup --no-allow-vendor-change -y
    fi
    zypper install -y wget curl
    sed -i 's@RC_LANG=.*@RC_LANG="en_US.UTF8"@' /etc/sysconfig/language
    sed -i 's@RC_LC_ALL=.*@RC_LC_ALL="en_US.UTF8"@' /etc/sysconfig/language
    sed -i 's@INSTALLED_LANGUAGES=@INSTALLED_LANGUAGES="en_US"@' /etc/sysconfig/language
    zypper install -y glibc-locale glibc-i18ndata translation-update-zh_CN
fi

apt update
if [ ! -e "/usr/sbin/locale-gen" ] && [ ! -e "/sbin/locale-gen" ]; then
  apt install -y locales
fi

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

echo "Configuring Chinese environment..."
#sed -i 's/^#.*en_US.UTF-8.*/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#.*zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
cat >/etc/default/locale <<-'EOF'
LANG="en_US.UTF-8"
LANGUAGE="en_US:zh"
LC_ALL="en_US.UTF-8"
EOF
#locale-gen
locale-gen zh_CN.UTF-8
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
apt install -y ca-certificates wget curl
if [ ! -f "/tmp/.RASPBIANARMHFDetectionFILE" ]; then
  echo "Replacing http software source list with https."
  echo "正在将http源替换为https..."
  sed -i 's@http:@https:@g' /etc/apt/sources.list
  sed -i 's@https://security@http://security@g' /etc/apt/sources.list
else
   rm -f "/tmp/.RASPBIANARMHFDetectionFILE"  
fi

if grep -Eq 'Funtoo|Gentoo' '/etc/os-release'; then
    LINUX_DISTRO=gentoo
    grep -q 'en_US' /etc/locale.gen || echo -e '\nen_US.UTF-8 UTF-8\nen_US.UTF-8 UTF-8' >>/etc/locale.gen
    locale-gen
    GENTOOLOCALE="$(eselect locale list | grep 'en_US' | head -n 1| cut -d '[' -f 2 | cut -d ']' -f 1)"
    eselect locale set "${GENTOOLOCALE}"
    #bash /etc/profile
    mkdir -p '/usr/portage'
    #下面生成的文件不要留空格
cat >/etc/portage/make.conf <<-'Endofmakeconf'
#语言设定
L10N="zh-CN en-US"
LINGUAS="en_US zh_CN"

#FEATURES="${FEATURES} -userpriv -usersandbox -sandbox"
ACCEPT_LICENSE="*"
# GCC编译时所调用的配置
#指定CPU核心数
CFLAGS="-march=native -O4 -pipe"
CXXFLAGS="${CFLAGS}"

#与CFLAGS变量不同，CHOST变量是固定的，不能轻易更改。你需要选择合适的架构平台。
#CHOST="x86_64-pc-linux-gnu"
#CHOST="aarch64-pc-linux-gnu"
CPU_FLAGS_X86="aes avx avx2 fma3 mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
#线程数
MAKEOPTS="-j8"
#显卡
#VIDEO_CARDS="intel i965"

# USE
SUPPORT="pulseaudio btrfs mtp git chromium"
DESKTOP="infinality emoji cjk"
FUCK="-bindist -grub -plymouth -systemd consolekit -modemmanager -gnome-shell -gnome -gnome-keyring -nautilus -modules"
ELSE="client icu sudo python"

USE="${SUPPORT} ${DESKTOP} ${FUCK} ${ELSE}"

# Portage
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
#国内镜像源，用于快照更新（emerge-webrsync）
#GENTOO_MIRRORS="https://mirrors.ustc.edu.cn/gentoo/"
GENTOO_MIRRORS="https://mirrors.tuna.tsinghua.edu.cn/gentoo"

#执行emerge时所调用的参数
EMERGE_DEFAULT_OPTS="--keep-going --with-bdeps=y"
EMERGE_DEFAULT_OPTS="--ask --verbose=y --keep-going --with-bdeps=y --load-average"
# FEATURES="${FEATURES} -userpriv -usersandbox -sandbox"
PORTAGE_REPO_DUPLICATE_WARN="0"
# PORTAGE_TMPDIR="/var/tmp/notmpfs"

#ACCEPT_KEYWORDS="~amd64"
ACCEPT_LICENSE="*"


RUBY_TARGETS="ruby24 ruby25"
#LLVM_TARGETS="X86"
QEMU_SOFTMMU_TARGETS="alpha aarch64 arm i386 mips mips64 mips64el mipsel ppc ppc64 s390x sh4 sh4eb sparc sparc64 x86_64"
QEMU_USER_TARGETS="alpha aarch64 arm armeb i386 mips mipsel ppc ppc64 ppc64abi32 s390x sh4 sh4eb sparc sparc32plus sparc64"
#关于该配置文件的相关选项参数，详见wiki.gentoo.org/wiki//etc/portage/make.conf
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
    source /etc/portage/repos.conf/gentoo.conf 2>/dev/null
    #同步过于耗时，故注释掉
    #emerge --sync
    emerge-webrsync
    emerge --config sys-libs/timezone-data 2>/dev/null
    #eselect profile list
    GENTOOnosystemdStable="$(eselect profile list | grep -Ev 'desktop|hardened|developer|systemd|selinux|multilib' | grep stable | tail -n 1 | cut -d '[' -f 2 | cut -d ']' -f 1)"
    eselect profile set "${GENTOOnosystemdStable}"
    etc-update --automode -3
    etc-update
    #dispatch-conf
    emerge -uvDN --with-bdeps=y @world
    emerge eix 2>/dev/null
    echo '检测到您当前的系统为Funtoo GNU/Linux,将不会为您继续配置任何优化步骤！'
    #rm -f vnc* zsh* .profile
    mv -f .profile.bak .profile 2>/dev/null
    #wget -qcO /usr/local/bin/neofetch 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch'
    chmod +x /usr/local/bin/neofetch
    neofetch
    #bash
   # exit 0

elif grep -qi 'Void' '/etc/issue'; then
    LINUX_DISTRO='void'
    cat >/etc/locale.conf <<-'EOF'
LANG="en_US.UTF-8"
LANGUAGE="en_US:zh"
LC_COLLATE=C
EOF
    mkdir -p /etc/xbps.d
    cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
    sed -i 's|https://alpha.de.repo.voidlinux.org|https://mirrors.tuna.tsinghua.edu.cn/voidlinux|g' /etc/xbps.d/*-repository-*.conf
    xbps-install -S
    xbps-install -uy xbps
    xbps-install -y wget curl
    #wget -qO- 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch' | bash -
    neofetch
    rm -f vnc* zsh* .profile
    mv -f .profile.bak .profile 2>/dev/null
    #wget -qO zsh.sh 'https://gitee.com/mo2/zsh/raw/master/zsh.sh'
    #sed -i '1 c\#!/bin/bash' zsh.sh
    #chmod +x zsh.sh
    echo '检测到您当前的系统为Void GNU/Linux,将不会为您继续配置任何优化步骤！'
    #zsh 2>/dev/null || bash
    #exit 0
elif [ "$(uname -m)" = "mips" ]; then
  chattr -i /etc/apt/sources.list    
elif ! grep -Eqi 'debian|ubuntu|kali|raspbian|Mint' "/etc/issue"; then
  chattr -i /etc/apt/sources.list 2>/dev/null
fi
apt update
apt list --upgradable
echo "正在升级所有软件包..."
apt dist-upgrade -y
apt install -y procps
apt clean

#############################
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
echo "2s后将自动开始配置zsh，您可以按Ctrl+C取消，这将不会继续配置其它步骤，同时也不会启动Tmoe-linux工具。"
#wget -qcO /usr/local/bin/neofetch 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch' || curl -sLo /usr/local/bin/neofetch 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch'
chmod +x /usr/local/bin/neofetch
neofetch
#############################
if [ "$(cat /etc/issue | cut -c 1-4)" = "Arch" ]; then
  grep -q '^LANG=' /etc/locale.conf 2>/dev/null || echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf
  if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "armv7l" ]; then
    cat >/etc/pacman.d/mirrorlist <<-'EndOfArchMirrors'
#Server = https://mirror.archlinuxarm.org/$arch/$repo
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo
EndOfArchMirrors
  else
    cat >/etc/pacman.d/mirrorlist <<-'EndOfArchMirrors'
#Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
EndOfArchMirrors
  fi
  pacman -Syyu --noconfirm
  if ! grep -q 'archlinuxcn' /etc/pacman.conf; then
  cat >>/etc/pacman.conf<<-'Endofpacman'
[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
Endofpacman
  fi
  pacman -Syu --noconfirm archlinux-keyring
  pacman -Sy --noconfirm archlinuxcn-keyring
  pacman -S --noconfirm yay
  yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
fi
#################################
if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '=' -f 2)" = "slackware" ]; then
    LINUX_DISTRO='slackware'
    sed -i 's/^ftp/#&/g' /etc/slackpkg/mirrors
    sed -i 's/^http/#&/g' /etc/slackpkg/mirrors
    sed -i '$ a\https://mirrors.tuna.tsinghua.edu.cn/slackwarearm/slackwarearm-current/' /etc/slackpkg/mirrors
    slackpkg update gpg
    slackpkg update
fi
#############################################
if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '=' -f 2)" = "fedora" ]; then
    tar -Ppzcf ~/yum.repos.d-backup.tar.gz /etc/yum.repos.d
    mv -f ~/yum.repos.d-backup.tar.gz /etc/yum.repos.d
    FEDORAversion="$(cat /etc/os-release | grep 'VERSION_ID' | cut -d '=' -f 2)"
    if ((${FEDORAversion} >= 30)); then
        #curl -o /etc/yum.repos.d/fedora.repo http://mirrors.aliyun.com/repo/fedora.repo
        #curl -o /etc/yum.repos.d/fedora-updates.repo http://mirrors.aliyun.com/repo/fedora-updates.repo
        cat >/etc/yum.repos.d/fedora.repo <<-'EndOfYumRepo'
[fedora]
name=Fedora $releasever - $basearch
failovermethod=priority
baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora/releases/$releasever/Everything/$basearch/os/
metadata_expire=28d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EndOfYumRepo

cat >/etc/yum.repos.d/fedora-updates.repoo <<-'EndOfYumRepo'
[updates]
name=Fedora $releasever - $basearch - Updates
failovermethod=priority
baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora/updates/$releasever/Everything/$basearch/
enabled=1
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EndOfYumRepo

        cat >/etc/yum.repos.d/fedora-modular.repo <<-'EndOfYumRepo'
[fedora-modular]
name=Fedora Modular $releasever - $basearch
failovermethod=priority
baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora/releases/$releasever/Modular/$basearch/os/
enabled=1
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EndOfYumRepo

        cat >/etc/yum.repos.d/fedora-updates-modular.repo <<-'EndOfYumRepo'
[updates-modular]
name=Fedora Modular $releasever - $basearch - Updates
failovermethod=priority
baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora/updates/$releasever/Modular/$basearch/
enabled=1
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EndOfYumRepo
    fi
  #dnf install -y glibc-langpack-zh
  #localedef -c -f UTF-8 -i en_US zh_CN.utf8 
  #dnf clean packages

elif [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '=' -f 2)" = "centos" ]; then
    cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
fi

############################
if ! grep -q 'debian' '/etc/os-release'; then
  echo "检测到您使用的不是deb系linux，优化步骤可能会出现错误"
  echo "在脚本执行完成后，您可以手动输./zsh-i.sh来配置zsh，输 ${YELLOW}debian-i${RESET}打开软件安装工具"
  bash zsh.sh
  debian-i
  bash zsh-i.sh
  #bash -c "$(curl -LfsS 'https://gitee.com/mo2/zsh/raw/master/zsh.sh')" || bash -c "$(wget -qO- 'https://gitee.com/mo2/zsh/raw/master/zsh.sh')"
else
  bash zsh.sh
fi  
EDITBASHPROFILE

if [ "${LINUX_DISTRO}" != 'Android' ]; then
  sed -i 's:#!/data/data/com.termux/files/usr/bin/bash:#!/bin/bash:g' $(grep -rl 'com.termux' "${PREFIX}/bin")
  sed -i 's:#!/data/data/com.termux/files/usr/bin/bash:#!/bin/bash:' ${DebianCHROOT}/remove-debian.sh
fi

bash ${PREFIX}/bin/debian
