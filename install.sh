#!/data/data/com.termux/files/usr/bin/bash
#检测架构
case $(uname -m) in
armv7* | armv8l)
	ARCH_TYPE="armhf"
	;;
armv6* | armv5*)
	ARCH_TYPE="armel"
	;;
aarch64 | armv8* | arm64)
	ARCH_TYPE="arm64"
	;;
x86_64 | amd64)
	ARCH_TYPE="amd64"
	;;
i*86 | x86)
	ARCH_TYPE="i386"
	;;
s390*)
	ARCH_TYPE="s390x"
	;;
ppc*)
	ARCH_TYPE="ppc64el"
	;;
mips*)
	ARCH_TYPE="mipsel"
	#echo -e 'Embedded devices such as routers are not supported at this time\n暂不支持mips架构的嵌入式设备'
	#exit 1
	;;
risc*)
	#ARCH_TYPE="riscv"
	echo "检测到您当前的架构为risc-v，将为您安装arm64版的容器。"
	ARCH_TYPE="arm64"
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
#gentoo_arm64在下一行修改ARCH_TYPE的变量为armhf

#requirements and DEPENDENCIES.
TRUE_ARCH_TYPE=${ARCH_TYPE}
QEMU_ARCH=''
CONFIG_FOLDER="${HOME}/.config/tmoe-linux/"
ACROSS_ARCH_FILE="${CONFIG_FOLDER}across_architecture_container.txt"
if [ -e "${ACROSS_ARCH_FILE}" ]; then
	ARCH_TYPE="$(cat ${ACROSS_ARCH_FILE} | head -n 1)"
	QEMU_ARCH="$(cat ${ACROSS_ARCH_FILE} | sed -n 2p)"
fi

LINUX_CONTAINER_DISTRO_FILE="${CONFIG_FOLDER}linux_container_distro.txt"
DEBIAN_FOLDER=debian_${ARCH_TYPE}
if [ -e "${LINUX_CONTAINER_DISTRO_FILE}" ]; then
	LINUX_CONTAINER_DISTRO=$(cat ${LINUX_CONTAINER_DISTRO_FILE} | head -n 1)
	if [ ! -z "${LINUX_CONTAINER_DISTRO}" ]; then
		DEBIAN_FOLDER="${LINUX_CONTAINER_DISTRO}_${ARCH_TYPE}"
	fi
fi
DEBIAN_CHROOT=${HOME}/${DEBIAN_FOLDER}

#创建必要文件夹，防止挂载失败
mkdir -p ~/storage/external-1
#DEBIAN_FOLDER=debian_arm64
RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
BLUE=$(printf '\033[34m')
BOLD=$(printf '\033[1m')
RESET=$(printf '\033[m')

DEPENDENCIES=""
if [ "$(uname -o)" = "Android" ]; then
	LINUX_DISTRO='Android'
	if [ ! -h "/data/data/com.termux/files/home/storage/shared" ]; then
		termux-setup-storage
	fi

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
	cd ${HOME}/.termux || mkdir -p ~/.termux && cd ${HOME}/.termux
	if [ ! -e "colors.properties" ]; then
		echo '检测到termux配色文件不存在，正在自动生成...'
		# aria2c --allow-overwrite=true -o "colors.properties" 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/.termux/colors.properties'
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
		echo -e "Detected that the termux.properties file does not exist.\n检测到termux属性文件不存在，正在为您下载..."
		aria2c --allow-overwrite=true -o "termux.properties" 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/.termux/termux.properties'
	fi
	#REMOTEP10KFONT='8597c76c4d2978f4ba022dfcbd5727a1efd7b34a81d768362a83a63b798f70e5'
	#LOCALFONT="$(sha256sum font.ttf | cut -c 1-64)" || LOCALFONT="0"
	if [ ! -e "font.ttf" ]; then
		#if [ "${REMOTEP10KFONT}" != "${LOCALFONT}" ]; then
		echo -e 'Detected that the font file does not exist.\n检测到字体文件不存在，正在自动配置字体...'
		echo "只有少部分字体能显示powerlevel10k的特殊字符，例如Iosevka"
		#仓库为Termux-zsh/raw/p10k，批量重命名的时候要小心一点。
		aria2c --allow-overwrite=true -o Iosevka.tar.xz 'https://gitee.com/mo2/Termux-zsh/raw/p10k/Iosevka.tar.xz'
		#mv -f font.ttf font.ttf.bak
		tar -Jxf Iosevka.tar.xz
		rm -f Iosevka.tar.xz
		termux-reload-settings
		#fi
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
#旧版将相关命令设立了alias，新版需要删掉。
####################
#卸载chroot挂载目录
if [ -e "${DEBIAN_CHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
	su -c "umount -lf ${DEBIAN_CHROOT}/dev >/dev/null 2>&1"
	su -c "umount -lf ${DEBIAN_CHROOT}/dev/shm  >/dev/null 2>&1"
	su -c "umount -lf ${DEBIAN_CHROOT}/dev/pts  >/dev/null 2>&1"
	su -c "umount -lf ${DEBIAN_CHROOT}/proc  >/dev/null 2>&1"
	su -c "umount -lf ${DEBIAN_CHROOT}/sys  >/dev/null 2>&1"
	su -c "umount -lf ${DEBIAN_CHROOT}/tmp  >/dev/null 2>&1"
	su -c "umount -lf ${DEBIAN_CHROOT}/root/sd  >/dev/null 2>&1 "
	su -c "umount -lf ${DEBIAN_CHROOT}/root/tf  >/dev/null 2>&1"
	su -c "umount -lf ${DEBIAN_CHROOT}/root/termux >/dev/null 2>&1"
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
cd ${HOME}

if [ -d "${DEBIAN_FOLDER}" ]; then
	echo "Detected that you have debian installed 检测到您已安装debian"
fi

mkdir -p ~/${DEBIAN_FOLDER}

DebianTarXz="debian-sid_${ARCH_TYPE}-rootfs.tar.xz"
cat <<-EOF
	現在可公開的情報:
	${BOLD}Tmoe-linux 小提示${RESET}:
			01:不同远程桌面的体验有可能是不同的哦！
			-------------------
			Different remote desktops may have different experiences.
			-------------------
			02:在某种环境下执行某条命令，将同时调用宿主机的VNC viewer和容器的vnc server。
			究竟是何种环境，以及哪条命令呢?
			-------------------
			Executing a certain command in a certain environment will call the processes of the host and the container almost simultaneously.
			---------------
			03:所有容器的启动命令皆为${GREEN}debian${RESET}
			但是呢！输${GREEN}debian${RESET}仅支持启动${BLUE}GNU/Linux容器${RESET}，不会自动启动远程桌面服务。
			-------------------
			You can type ${GREEN}debian${RESET} to start and enter this ${BLUE}container.${RESET}
			-------------------
			04:并非所有${YELLOW}字体${RESET}都支持${BLUE}powerlevel 10k${RESET}的特殊字符哦！🍥
			-------------------
			Some fonts do not support powerlevel10k special characters.
			-------------------
EOF
echo "Detected that your current architecture is ${YELLOW}${ARCH_TYPE}${RESET}"
echo "检测到您当前的架构为${YELLOW}${ARCH_TYPE}${RESET}，${GREEN}debian system${RESET}将安装至${BLUE}~/${DEBIAN_FOLDER}${RESET}"

if [ ! -f ${DebianTarXz} ]; then
	if [ "${ARCH_TYPE}" != 'mipsel' ]; then
		echo "正在从${YELLOW}清华大学开源镜像站${RESET}${GREEN}下载${RESET}容器镜像..."
		echo "Downloading ${BLUE}${DebianTarXz}${RESET} from Tsinghua University Open Source Mirror Station."
		TTIME=$(curl -L "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${ARCH_TYPE}/default/" | grep date | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
		if [ "${LINUX_DISTRO}" != 'iSH' ]; then
			aria2c -x 5 -k 1M --split 5 -o ${DebianTarXz} "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${ARCH_TYPE}/default/${TTIME}rootfs.tar.xz"
		else
			wget -O ${DebianTarXz} "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${ARCH_TYPE}/default/${TTIME}rootfs.tar.xz"
		fi
	else
		aria2c -x 6 -k 1M --split 6 -o ${DebianTarXz} 'https://webdav.tmoe.me/down/share/Tmoe-linux/chroot/debian_mipsel.tar.xz'
	fi
fi
cur=$(pwd)
cd ${DEBIAN_CHROOT}
printf "$BLUE"
cat <<-'EndOFneko'
	       DL.                           
	       QBBBBBKv:rr77ri:.             
	       gBBQdY7::::..::i7vv.          
	       UBd. . .:.........rBBBQBBBB5  
	       Pu  :..r......i:....BBBQBBB:  
	       ri.i:.j:...:. i7... uBBZrd:   
	 :     7.:7.7U.:..r: Yr:.. iQ1:qU    
	.Qi   .7.ii.X7:...L.:qr:...iB7ZQ     
	 .27. :r.r:L7i::.7r:vri:...rr  .     
	  v   ::.Yrviri:7v7v: ::...i.   i    
	      r:ir: r.iiiir..:7r...r   :P.2Y 
	      v:vi::.      :  ::. .qI7U1U :1 
	Qr    7.7.         :.i::. :Di:. i .v:
	v7..  s.r7.   ...   .:7i: rDi...r .. 
	 vi: .7.iDBBr  .r   .:.7. rPr:..r    
	 i   :virZBgi  :vrYJ1vYY .ruY:..i    
	     YrivEv. 7BBRBqj21I7 .77J:.:.PQ  
	    .1r:q.   rB52SKrj.:i i5isi.:i :.r
	    YvrY7    r.  . ru :: PIrj7.:r..v 
	   rSviYI..iuU .:.:i:.7.KPPiSr.:vr   
	  .u:Y:JQMSsJUv...   .rDE1P71:.7X7   
	  5  Ivr:QJ7JYvi....ir1dq vYv.7L.Y   
	  S  7Z  Qvr:.iK55SqS1PX  Xq7u2 :7   
	         .            i   7          
EndOFneko
printf "$RESET"
cat <<-EOF
	現在可公開的情報:
	${BOLD}Tmoe-linux 小提示05${RESET}(仅适用于GUI安装完成后):

			若您的宿主机为${BOLD}Android${RESET}系统,则在termux原系统下输${GREEN}startvnc${RESET}将${RED}同时启动${RESET}安卓版Realvnc${YELLOW}客户端${RESET}和GNU/Linux的VNC${YELLOW}服务端${RESET}。
			-------------------
			您可以输${GREEN}startvnc${RESET}来启动${BLUE}tight或tigervnc服务${RESET}，输${RED}stopvnc${RESET}停止
			-------------------
			You can type ${GREEN}startvnc${RESET} to start ${BLUE}tight/tigervnc server.${RESET}
			-------------------
			输${GREEN}startx11vnc${RESET}启动${BLUE}x11vnc服务${RESET},x11vnc能运行tightvnc无法打开的某些应用哦！
			-------------------
			You can also type ${GREEN}startx11vnc${RESET} to start ${BLUE}x11vnc server.${RESET}
			------------------
	${BOLD}小提示06${RESET}:

			在容器内输${GREEN}debian-i${RESET}启动软件安装及远程桌面配置${BLUE}管理工具${RESET}。
			You can type ${GREEN}debian-i${RESET} to start ${BLUE}tmoe-linux tool.${RESET}.
			-------------------
EOF
echo "正在${GREEN}解压${RESET}${BLUE}${DebianTarXz}...${RESET}"
echo "Decompressing ${DebianTarXz}, please be patient."
if [ "${ARCH_TYPE}" = "mipsel" ]; then
	pv ${cur}/${DebianTarXz} | tar -pJx
	mv -b ${DEBIAN_CHROOT}/debian_mipsel/* ${DEBIAN_CHROOT}
elif [ "${LINUX_DISTRO}" = "Android" ]; then
	pv ${cur}/${DebianTarXz} | proot --link2symlink tar -pJx
elif [ "${LINUX_DISTRO}" = "iSH" ]; then
	tar -pJxvf ${cur}/${DebianTarXz}
elif [ "${LINUX_DISTRO}" = "redhat" ]; then
	if [ "${REDHAT_DISTRO}" != "fedora" ]; then
		tar -pJxvf ${cur}/${DebianTarXz}
	else
		pv ${cur}/${DebianTarXz} | tar -pJx
	fi
else
	pv ${cur}/${DebianTarXz} | tar -pJx
fi
cp -f ~/.termux/font.ttf ~/${DEBIAN_FOLDER}/tmp/ 2>/dev/null
if [ "${LINUX_DISTRO}" = 'openwrt' ]; then
	touch ~/${DEBIAN_FOLDER}/tmp/.openwrtcheckfile
fi
#proot --link2symlink tar -Jxvf ${cur}/${DebianTarXz}||:
cd "$cur"
printf "$YELLOW"
cat <<-'EndOFneko'
	                                        
	                            .:7E        
	            .iv7vrrrrr7uQBBBBBBB:       
	           v17::.........:SBBBUg        
	        vKLi.........:. .  vBQrQ        
	   sqMBBBr.......... :i. .  SQIX        
	   BBQBBr.:...:....:. 1:.....v. ..      
	    UBBB..:..:i.....i YK:: ..:   i:     
	     7Bg.... iv.....r.ijL7...i. .Lu     
	  IB: rb...i iui....rir :Si..:::ibr     
	  J7.  :r.is..vrL:..i7i  7U...Z7i..     
	  ...   7..I:.: 7v.ri.755P1. .S  ::     
	    :   r:.i5KEv:.:.  :.  ::..X..::     
	   7is. :v .sr::.         :: :2. ::     
	   2:.  .u: r.     ::::   r: ij: .r  :  
	   ..   .v1 .v.    .   .7Qr: Lqi .r. i  
	   :u   .iq: :PBEPjvviII5P7::5Du: .v    
	    .i  :iUr r:v::i:::::.:.:PPrD7: ii   
	    :v. iiSrr   :..   s i.  vPrvsr. r.  
	     ...:7sv:  ..PL  .Q.:.   IY717i .7. 
	      i7LUJv.   . .     .:   YI7bIr :ur 
	     Y rLXJL7.:jvi:i:::rvU:.7PP XQ. 7r7 
	    ir iJgL:uRB5UPjriirqKJ2PQMP :Yi17.v 
	         :   r. ..      .. .:i  ...     
EndOFneko
printf "$RESET"
####################
creat_chroot_startup_script() {
	#rm -f ${HOME}/.Chroot-Container-Detection-File
	echo "Creating chroot startup script"
	echo "正在创建chroot启动脚本${PREFIX}/bin/debian "
	if [ -d "/sdcard" ]; then
		mkdir -p ${DEBIAN_CHROOT}/root/sd
	fi
	if [ -L '/data/data/com.termux/files/home/storage/external-1' ]; then
		mkdir -p ${DEBIAN_CHROOT}/root/tf
	fi
	if [ -d "/data/data/com.termux/files/home" ]; then
		mkdir -p ${DEBIAN_CHROOT}/root/termux
	fi
	if [ ! -f "${DEBIAN_CHROOT}/etc/profile" ]; then
		echo "" >>${DEBIAN_CHROOT}/etc/profile
	fi
	#此处若不创建，将有可能导致chromium无法启动。
	mkdir -p ${DEBIAN_CHROOT}/run/shm
	chmod 1777 ${DEBIAN_CHROOT}/dev/shm 2>/dev/null
	grep -q 'export PATH=' ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1 || sed -i "1 a\export PATH='/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games'" ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1

	grep -q 'export PATH=' ${DEBIAN_CHROOT}/root/.zshenv >/dev/null 2>&1 || echo "export PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games" >>${DEBIAN_CHROOT}/root/.zshenv

	grep -q 'unset LD_PRELOAD' ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1 || sed -i "1 a\unset LD_PRELOAD" ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1

	grep -q 'en_US.UTF-8' ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\export LANG=en_US.UTF-8" ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1

	grep -q 'HOME=/root' ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\export HOME=/root" ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1

	grep -q 'cd /root' ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1 || sed -i "$ a\cd /root" ${DEBIAN_CHROOT}/etc/profile >/dev/null 2>&1

	#此处EndOfChrootFile不要加单引号
	cat >${PREFIX}/bin/debian <<-EndOfChrootFile
		  #!/data/data/com.termux/files/usr/bin/bash
		  DEBIAN_CHROOT=${HOME}/${DEBIAN_FOLDER}
		  if [ ! -e "${DEBIAN_CHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
		    echo "本文件为chroot容器检测文件 Please do not delete this file!" >>${DEBIAN_CHROOT}/tmp/.Chroot-Container-Detection-File 2>/dev/null
		  fi
		  #sed替换匹配行,加密内容为chroot登录shell。为防止匹配行被替换，故采用base64加密。
		  DEFAULTZSHLOGIN="\$(echo 'Y2hyb290ICR7RGViaWFuQ0hST09UfSAvYmluL3pzaCAtLWxvZ2luCg==' | base64 -d)"
		  DEFAULTBASHLOGIN="\$(echo 'Y2hyb290ICR7RGViaWFuQ0hST09UfSAvYmluL2Jhc2ggLS1sb2dpbgo=' | base64 -d)"

		  if [ -f ${DEBIAN_CHROOT}/bin/zsh ]; then
		    sed -i "s:\${DEFAULTBASHLOGIN}:\${DEFAULTZSHLOGIN}:g" ${PREFIX}/bin/debian
		  else
		    sed -i "s:\${DEFAULTZSHLOGIN}:\${DEFAULTBASHLOGIN}:g" ${PREFIX}/bin/debian
		  fi

		  if [ "\$(id -u)" != "0" ]; then
		    su -c "/bin/sh ${PREFIX}/bin/debian"
		    exit
		  fi
		  mount -o bind /dev ${DEBIAN_CHROOT}/dev >/dev/null 2>&1
		  #mount -o bind /dev /dev >/dev/null 2>&1

		  mount -t proc proc ${DEBIAN_CHROOT}/proc >/dev/null 2>&1
		  #mount -t proc proc /proc >/dev/null 2>&1

		  mount -t sysfs sysfs ${DEBIAN_CHROOT}/sys >/dev/null 2>&1

		  mount -t devpts devpts ${DEBIAN_CHROOT}/dev/pts >/dev/null 2>&1
		  # mount -t devpts devpts /dev/pts >/dev/null 2>&1

		  #mount --bind /dev/shm ${DEBIAN_CHROOT}/dev/shm >/dev/null 2>&1
		  mount -o rw,nosuid,nodev,mode=1777 -t tmpfs tmpfs /dev/shm >/dev/null 2>&1

		  #mount -t tmpfs tmpfs ${DEBIAN_CHROOT}/tmp  >/dev/null 2>&1

		  mount --rbind ${DEBIAN_CHROOT} ${DEBIAN_CHROOT}/ >/dev/null 2>&1

		  if [ "$(uname -o)" = "Android" ]; then
		    TFcardFolder="\$(su -c 'ls /mnt/media_rw/ 2>/dev/null | head -n 1')"
		    if [ -d "/mnt/media_rw/\${TFcardFolder}" ]; then
		      mount -o bind /mnt/media_rw/\${TFcardFolder} ${DEBIAN_CHROOT}/root/tf >/dev/null 2>&1
		    fi
		    if [ -d "/data/data/com.termux/files/home" ]; then
		      mount -o bind /data/data/com.termux/files/home ${DEBIAN_CHROOT}/root/termux >/dev/null 2>&1
		    fi
		    if [ -d "/sdcard" ]; then
		      mount -o bind /sdcard ${DEBIAN_CHROOT}/root/sd >/dev/null 2>&1
		      #mount --rbind /sdcard ${DEBIAN_CHROOT}/root/sd >/dev/null 2>&1
		    fi
		  fi
		  chroot \${DEBIAN_CHROOT} /bin/bash --login

	EndOfChrootFile
	#上面那行不要有空格
}
###################
creat_proot_startup_script() {
	echo "Creating proot startup script"
	echo "正在创建proot容器启动脚本${PREFIX}/bin/debian "
	#DEBIAN_CHROOT=~/debian_arm64
	#DEBIAN_FOLDER=debian_arm64
	#此处EndOfFile不要加单引号
	cat >${PREFIX}/bin/debian <<-EndOfFile
		#!/data/data/com.termux/files/usr/bin/bash
		get_tmoe_linux_help_info() {
			cat <<-'ENDOFHELP'
				         -i      --启动tmoe-linux manager
						 -m      --更换为tuna镜像源(仅debian,ubuntu,kali,alpine和arch)
						-vnc     --启动VNC
			ENDOFHELP
		}
		main() {
			case "\$1" in
			i* | -i* | -I*)
				debian-i
				exit 0
				;;
			-h* | --h*)
				get_tmoe_linux_help_info
				;;
			-m* | m*)
				debian-i -m
				;;
			-vnc* | vnc*)
				startvnc
				;;
			*) start_tmoe_gnu_linux_container ;;
			esac
		}
		start_tmoe_gnu_linux_container() {
			cd ${HOME}
			#pulseaudio --kill 2>/dev/null &
			#为加快启动速度，此处不重启音频服务
			pulseaudio --start 2>/dev/null &
			unset LD_PRELOAD
			command="proot"
			command+=" --link2symlink"
			command+=" -0"
			command+=" -r ${DEBIAN_FOLDER}"
			#command+=" -q qemu-x86_64-staic"
			command+=" -b /dev"
			command+=" -b /proc"
			command+=" -b ${DEBIAN_FOLDER}/root:/dev/shm"
			#您可以在此处修改挂载目录
			command+=" -b /sdcard:/root/sd"
			command+=" -b /data/data/com.termux/files/home/storage/external-1:/root/tf"
			command+=" -b /data/data/com.termux/files/home:/root/termux"
			command+=" -w /root"
			command+=" /usr/bin/env -i"
			command+=" HOME=/root"
			command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
			command+=" TERM=xterm-256color"
			command+=" LANG=en_US.UTF-8"
			command+=" /bin/bash --login"
			com="\$@"
			#为防止匹配行被替换，故采用base64加密。
			DEFAULTZSHLOGIN="\$(echo 'Y29tbWFuZCs9IiAvYmluL3pzaCAtLWxvZ2luIgo=' | base64 -d)"
			DEFAULTBASHLOGIN="\$(echo 'Y29tbWFuZCs9IiAvYmluL2Jhc2ggLS1sb2dpbiIK' | base64 -d)"

			if [ -f ~/${DEBIAN_FOLDER}/bin/zsh ]; then
				sed -i "s:\${DEFAULTBASHLOGIN}:\${DEFAULTZSHLOGIN}:g" ${PREFIX}/bin/debian
			else
				sed -i "s:\${DEFAULTZSHLOGIN}:\${DEFAULTBASHLOGIN}:g" ${PREFIX}/bin/debian
			fi

			if [ ! -e "${DEBIAN_CHROOT}/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
				echo "本文件为Proot容器检测文件 Please do not delete this file!" >>${DEBIAN_CHROOT}/tmp/.Tmoe-Proot-Container-Detection-File 2>/dev/null
			fi

			if [ -z "\$1" ]; then
				exec \$command
			else
				\$command -c "\$com"
			fi
		}
		main "\$@"
	EndOfFile
	##################
	if [ "${LINUX_DISTRO}" != 'Android' ]; then
		sed -i 's@command+=" --link2sy@#&@' ${PREFIX}/bin/debian
	fi
	if [ ! -e "/sdcard" ]; then
		sed -i 's@command+=" -b /sdcard@#&@g' ${PREFIX}/bin/debian
	fi
	if [ ! -e "/data/data/com.termux/files/home" ]; then
		sed -i 's@command+=" -b /data/data/com.termux/files/home:/root/termux"@#&@g' ${PREFIX}/bin/debian
	fi
	if [ ! -z "${QEMU_ARCH}" ]; then
		sed -i 's@#command+=" -q qemu-x86_64-staic"@command+=" -q qemu-x86_64-staic"@' ${PREFIX}/bin/debian
		sed -i "s@qemu-x86_64-staic@qemu-${QEMU_ARCH}-static@" ${PREFIX}/bin/debian
	fi
}
######################
if [ -f "${HOME}/.Chroot-Container-Detection-File" ]; then
	creat_chroot_startup_script
else
	creat_proot_startup_script
fi
#######################################################
creat_linux_container_remove_script() {
	cat >${PREFIX}/bin/debian-rm <<-EndOfFile
		    #!/data/data/com.termux/files/usr/bin/bash
			  YELLOW=\$(printf '\033[33m')
			  RESET=\$(printf '\033[m')
		    cd ${HOME}
		    
		  if [ -e "${DEBIAN_CHROOT}/tmp/.Chroot-Container-Detection-File" ]; then
				su -c "umount -lf ${DEBIAN_CHROOT}/dev >/dev/null 2>&1"
				su -c "umount -lf ${DEBIAN_CHROOT}/dev/shm  >/dev/null 2>&1"
			  su -c "umount -lf ${DEBIAN_CHROOT}/dev/pts  >/dev/null 2>&1"
				su -c " umount -lf ${DEBIAN_CHROOT}/proc  >/dev/null 2>&1"
				su -c "umount -lf ${DEBIAN_CHROOT}/sys  >/dev/null 2>&1"
				su -c "umount -lf ${DEBIAN_CHROOT}/tmp  >/dev/null 2>&1"
				su -c "umount -lf ${DEBIAN_CHROOT}/root/sd  >/dev/null 2>&1 "
				su -c "umount -lf ${DEBIAN_CHROOT}/root/tf  >/dev/null 2>&1"
				su -c "umount -lf ${DEBIAN_CHROOT}/root/termux >/dev/null 2>&1"

		ls -lah ${DEBIAN_CHROOT}/dev 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/dev/shm 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/dev/pts 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/proc 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/sys 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/tmp 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/root/sd 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/root/tf 2>/dev/null
		ls -lah ${DEBIAN_CHROOT}/root/termux 2>/dev/null
		  df -h |grep debian
		  echo '移除容器前，请先确保您已卸载chroot挂载目录。'
		  echo '建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！'
		  echo "Before removing the system, make sure you have unmounted the chroot mount directory.
		It is recommended that you back up the entire system before removal. If the data is lost due to improper operation, the developer is not responsible! "
		  fi
		  echo "移除容器前，请先确保您已停止容器的进程。"
		  pkill proot 2>/dev/null
		  ps -e | grep proot
		  ps -e | grep startvnc
		  pgrep proot &> /dev/null
		if [ "\$?" = "0" ]; then
		    echo '检测到proot容器正在运行，请先输stopvnc或手动强制停止容器运行,亦或者是重启设备'
		fi
			ls -l ${DEBIAN_CHROOT}/root/sd/* 2>/dev/null
			if [ "\$?" = "0" ]; then
				echo 'WARNING！检测到/root/sd 无法强制卸载，您当前使用的可能是chroot容器'
				echo "若为误报，则请先停止容器进程，再手动移除${DEBIAN_CHROOT}/root/sd"
				echo '建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！'
			# echo '为防止数据丢失，禁止移除容器！请重启设备后再重试。'
			# echo "Press enter to exit."
			# echo "${YELLOW}按回车键退出。${RESET} "
			# read
			# exit 0
			fi

		 #echo '检测到chroot容器正在运行，您可以输pkill -u $(whoami) 来终止所有进程'    
		  #echo "若容器未停止运行，则建议你先手动在termux原系统中执行stopvnc，再进行移除操作。"
			echo 'Detecting debian system size... 正在检测debian system占用空间大小'
		   du -sh ./${DEBIAN_FOLDER} --exclude=./${DEBIAN_FOLDER}/root/tf --exclude=./${DEBIAN_FOLDER}/root/sd --exclude=./${DEBIAN_FOLDER}/root/termux
			echo "Do you want to remove it?[Y/n]"
			echo "\${YELLOW}按回车键确认移除 Press enter to remove.\${RESET} "
		    pkill proot 2>/dev/null
			read opt
			case \$opt in
				y*|Y*|"") 
		    chmod 777 -R ${DEBIAN_FOLDER}
			rm -rfv "${DEBIAN_FOLDER}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code ~/.config/tmoe-linux/across_architecture_container.txt 2>/dev/null || sudo rm -rfv "${DEBIAN_FOLDER}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code ~/.config/tmoe-linux/across_architecture_container.txt 2>/dev/null
		    sed -i '/alias debian=/d' ${PREFIX}/etc/profile
			  sed -i '/alias debian-rm=/d' ${PREFIX}/etc/profile
			source profile >/dev/null 2>&1
			echo 'The debian system has been removed. If you want to uninstall aria2, enter "apt remove aria2" or "apt purge aria2"'
		  echo '移除完成，如需卸载aria2,请手动输apt remove aria2'
		   echo "Deleted已删除" ;;
				n*|N*) echo "skipped."
				exit 1
				 ;;
				*) 
				echo "Invalid choice. skipped." 
				exit 1
				;;
			esac
			echo 'If you want to reinstall, it is not recommended to remove the image file.'
			echo '若需要重装，则不建议移除镜像文件。'
			#echo '若需要跨架构运行,则建议移除该文件,以便重新下载相应架构的镜像文件'
			ls -lah ~/*rootfs.tar.xz
			echo "\${YELLOW}是否需要删除容器镜像文件？[Y/n]\${RESET} "
			ROOTFS_NAME=$(echo ${DEBIAN_FOLDER} | cut -d '_' -f 1)
			echo "rm -fv ~/\${ROOTFS_NAME}*rootfs.tar.xz"
			echo "Do you need to delete the image file (${DEBIAN_FOLDER}*rootfs.tar.xz)?[Y/n]"

		    read opt
			case \$opt in
				y*|Y*|"") 
			rm -fv ~/${DEBIAN_FOLDER}-rootfs.tar.xz
			rm -fv ~/\${ROOTFS_NAME}*rootfs.tar.xz
			#rm -vf ~/debian-sid*rootfs.tar.xz 2>/dev/null
		    #rm -f ${PREFIX}/bin/debian-rm
			#rm -vf ~/fedora*rootfs.tar.xz 2>/dev/null
			#rm -vf ~/arch*rootfs.tar.xz 2>/dev/null
			#rm -vf ~/debian-buster*rootfs.tar.xz 2>/dev/null
			#rm -vf ~/ubuntu-focal*rootfs.tar.xz 2>/dev/null
			#rm -vf ~/kali-rolling*rootfs.tar.xz 2>/dev/null
			#rm -vf ~/funtoo*rootfs.tar.xz 2>/dev/null
		    echo "Deleted已删除" ;;
				n*|N*) echo "skipped." ;;
				*) echo "Invalid choice. skipped." ;;
			esac
	EndOfFile
}
########################
cat >${PREFIX}/bin/startvnc <<-EndOfFile
	#!/data/data/com.termux/files/usr/bin/bash
	am start -n com.realvnc.viewer.android/com.realvnc.viewer.android.app.ConnectionChooserActivity
	pulseaudio --start 2>/dev/null &
	touch ~/${DEBIAN_FOLDER}/root/.vnc/startvnc
	/data/data/com.termux/files/usr/bin/debian
EndOfFile
ln -sf ${PREFIX}/bin/startvnc ${PREFIX}/bin/startx11vnc
###############
#仅安卓支持终止所有进程
if [ "$(uname -o)" = 'Android' ]; then
	cat >${PREFIX}/bin/stopvnc <<-'EndOfFile'
		#!/data/data/com.termux/files/usr/bin/bash
		#pkill -u $(whoami)
		pulseaudio --kill 2>/dev/null &
		sh -c "$(ps -e | grep -Ev "sshd|pkill|systemd" | awk '{print $4}' | sed '/(/d' | sed 's/^/pkill &/g')"
	EndOfFile
fi
#################
#不要单引号
cat >${PREFIX}/bin/startxsdl <<-EndOfFile
	#!/data/data/com.termux/files/usr/bin/bash
	am start -n x.org.server/x.org.server.MainActivity
	touch ~/${DEBIAN_FOLDER}/root/.vnc/startxsdl
	/data/data/com.termux/files/usr/bin/debian
EndOfFile
creat_linux_container_remove_script
################
#wget -qO ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh'
aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh'
#############
if [ ! -L '/data/data/com.termux/files/home/storage/external-1' ]; then
	sed -i 's@^command+=" -b /data/data/com.termux/files/home/storage/external-1@#&@g' ${PREFIX}/bin/debian 2>/dev/null
	sed -i 's@^mount -o bind /mnt/media_rw/@#&@g' ${PREFIX}/bin/debian 2>/dev/null
fi
echo 'Giving startup script execution permission'
echo "正在赋予启动脚本(${PREFIX}/bin/debian)执行权限"
#termux-fix-shebang ${PREFIX}/bin/debian
cd ${PREFIX}/bin

chmod +x debian startvnc stopvnc debian-rm debian-i startxsdl 2>/dev/null
#设定alias,防止debian-root的alias依旧在生效。
alias debian="${PREFIX}/bin/debian"
alias debian-rm="${PREFIX}/bin/debian-rm"
################
echo "You can type rm ~/${DebianTarXz} to delete the image file"
echo "您可以输${RED}rm ~/${DebianTarXz}${RESET}来删除容器镜像文件"
ls -lh ~/${DebianTarXz}
########################
if [ ! -d "${DEBIAN_CHROOT}/usr/local/bin" ]; then
	mkdir -p ${DEBIAN_CHROOT}/usr/local/bin
fi

if [ -f "${HOME}/.Tmoe-Proot-Container-Detection-File" ]; then
	mv -f "${HOME}/.Tmoe-Proot-Container-Detection-File" ${DEBIAN_CHROOT}/tmp
	echo "本文件为Proot容器检测文件 Please do not delete this file!" >>${DEBIAN_CHROOT}/tmp/.Tmoe-Proot-Container-Detection-File 2>/dev/null
elif [ -f "${HOME}/.Chroot-Container-Detection-File" ]; then
	mv -f "${HOME}/.Chroot-Container-Detection-File" ${DEBIAN_CHROOT}/tmp
	echo "本文件为Chroot容器检测文件 Please do not delete this file!" >>${DEBIAN_CHROOT}/tmp/.Chroot-Container-Detection-File 2>/dev/null
fi
cd ${DEBIAN_CHROOT}/usr/local/bin

curl -Lo "neofetch" 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch'
curl -Lo "debian-i" 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
chmod +x neofetch debian-i

cd ${DEBIAN_CHROOT}/root
chmod u+w "${DEBIAN_CHROOT}/root"
curl -sLo zsh-i.sh 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh'
sed -i 's:#!/data/data/com.termux/files/usr/bin/bash:#!/bin/bash:' zsh-i.sh
chmod +x zsh-i.sh
###########
debian_stable_sources_list_and_gpg_key() {
	curl -Lo "raspbian-sources-gpg.tar.xz" 'https://gitee.com/mo2/patch/raw/raspbian/raspbian-sources-gpg.tar.xz'
	tar -Jxvf "raspbian-sources-gpg.tar.xz" -C ~/${DEBIAN_FOLDER}/etc/apt/
	rm -f "raspbian-sources-gpg.tar.xz"
}
############
if [ -f "${HOME}/.RASPBIANARMHFDetectionFILE" ]; then
	mv -f "${HOME}/.RASPBIANARMHFDetectionFILE" "${DEBIAN_CHROOT}/tmp/"
	#树莓派换源
	debian_stable_sources_list_and_gpg_key
elif [ -f "${HOME}/.REDHATDetectionFILE" ]; then
	rm -f "${HOME}/.REDHATDetectionFILE"
	chmod u+w "${DEBIAN_CHROOT}/root"
elif [ -f "${HOME}/.ALPINELINUXDetectionFILE" ]; then
	#sed -i '/DEFAULTZSHLOGIN/d' $(command -v debian)
	#sed -i '/DEFAULTZSHLOGIN/d' $(command -v debian)
	#sed -i 's@sed -i \"s:\${DE@#&@g' $(command -v debian)
	sed -i 's/bash --login/ash --login/g' $(command -v debian)
	sed -i 's/zsh --login/ash --login/g' $(command -v debian)
	mv -f "${HOME}/.ALPINELINUXDetectionFILE" ${DEBIAN_CHROOT}/tmp
elif [ -f "${HOME}/.MANJARO_ARM_DETECTION_FILE" ]; then
	rm -f ${HOME}/.MANJARO_ARM_DETECTION_FILE
	sed -i 's@^#SigLevel.*@SigLevel = Never@' "${DEBIAN_CHROOT}/etc/pacman.conf"
fi
########
TMOE_LOCALE_FILE="${HOME}/.config/tmoe-linux/locale.txt"
if [ -e "${TMOE_LOCALE_FILE}" ]; then
	TMOE_LOCALE_NEW_PATH="${DEBIAN_CHROOT}/usr/local/etc/tmoe-linux"
	mkdir -p ${TMOE_LOCALE_NEW_PATH}
	cp -f ${TMOE_LOCALE_FILE} ${TMOE_LOCALE_NEW_PATH}
	TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
	PROOT_LANG=$(cat $(command -v debian) | grep LANG= | cut -d '"' -f 2 | cut -d '=' -f 2 | tail -n 1)
	sed -i "s@${PROOT_LANG}@${TMOE_LANG}@" $(command -v debian)
fi
########################
#配置zsh
curl -Lo zsh.sh 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/zsh.sh'
chmod u+x ./*
#vnc自动启动
cat >vnc-autostartup <<-'EndOfFile'
	cat /etc/issue
	locale_gen_tmoe_language() {
		if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
			cd /etc
			sed -i "s/^#.*${TMOE_LANG} UTF-8/${TMOE_LANG} UTF-8/" locale.gen
			if grep -q ubuntu '/etc/os-release'; then
				    apt update
					apt install -y ^language-pack-${TMOE_LANG_QUATER} 2>/dev/null
			fi
			if ! grep -qi "^${TMOE_LANG_HALF}" "locale.gen"; then
				echo '' >>locale.gen
				sed -i 's@^@#@g' locale.gen 2>/dev/null
				sed -i 's@##@#@g' locale.gen 2>/dev/null
				sed -i "$ a ${TMOE_LANG}" locale.gen
			fi
			locale-gen ${TMOE_LANG}
		fi
	}
	check_tmoe_locale_file() {
		TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
		if [ -e "${TMOE_LOCALE_FILE}" ]; then
			TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
			TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
			TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
			locale_gen_tmoe_language
		fi
	}

	if [ -e "${HOME}/.vnc/xstartup" ] && [ ! -e "${HOME}/.vnc/passwd" ]; then
		check_tmoe_locale_file
		curl -Lv -o /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		chmod +x /usr/local/bin/debian-i
		/usr/local/bin/debian-i passwd
	fi
	grep 'cat /etc/issue' ~/.bashrc >/dev/null 2>&1 || sed -i '1 a\cat /etc/issue' ~/.bashrc
	if [ -f "/root/.vnc/startvnc" ]; then
		/usr/local/bin/startvnc
		echo "已为您启动vnc服务 Vnc server has been started, enjoy it!"
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
############
if [ ! -f ".bashrc" ]; then
	echo '' >>.bashrc || touch .bashrc
fi
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
#############
#curl -Lo '.profile' 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/profile.sh'
#chmod u+x .profile
#不要将profile转换为外部脚本，否则将影响sed
cat >'.profile' <<-'ENDOFbashPROFILE'
	YELLOW=$(printf '\033[33m')
	RESET=$(printf '\033[m')
	cd ${HOME}
	###############
	#函数放在前面
	debian_sources_list() {
	    sed -i 's/^deb/##&/g' /etc/apt/sources.list
	    #stable-backports会出错，需改为buster-backports
	    cat >>/etc/apt/sources.list <<-'EndOfFile'
				#deb http://mirrors.163.com/debian/ stable main contrib non-free
				#deb http://mirrors.163.com/debian/ stable-updates main contrib non-free
				#deb http://mirrors.163.com/debian/ buster-backports main contrib non-free
				#deb http://mirrors.163.com/debian-security/ stable/updates main contrib non-free
				deb http://mirrors.163.com/debian/ sid main contrib non-free
			EndOfFile
	}
	##############################
	kali_sources_list() {
	    echo "检测到您使用的是Kali系统"
	    sed -i 's/^deb/##&/g' /etc/apt/sources.list
	    cat >>/etc/apt/sources.list <<-"EndOfSourcesList"
				deb http://mirrors.tuna.tsinghua.edu.cn/kali/ kali-rolling main contrib non-free
				deb http://mirrors.huaweicloud.com/debian/ stable main contrib non-free
				# deb http://mirrors.huaweicloud.com/kali/ kali-last-snapshot main contrib non-free
			EndOfSourcesList
	    #注意：kali-rolling添加debian testing源后，可能会破坏系统依赖关系，可以添加stable源（暂未发现严重影响）
	}
	######################
	ubuntu_sources_list() {
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
	    if grep -q 'Bionic Beaver' "/etc/os-release"; then
	        sed -i 's/focal/bionic/g' /etc/apt/sources.list
	    fi
	}
	#########################
	mint_sources_list() {
	    echo "检测到您使用的是Linux Mint"
	    sed -i 's/^deb/##&/g' /etc/apt/sources.list
	    cat >>/etc/apt/sources.list <<-"EndOfSourcesList"
				deb http://mirrors.huaweicloud.com/linuxmint/ tricia main upstream import backport
				deb http://mirrors.huaweicloud.com/ubuntu/ bionic main restricted universe multiverse
				deb http://mirrors.huaweicloud.com/ubuntu/ bionic-updates main restricted universe multiverse
				deb http://mirrors.huaweicloud.com/ubuntu/ bionic-backports main restricted universe multiverse
				deb http://mirrors.huaweicloud.com/ubuntu/ bionic-security main restricted universe multiverse
			EndOfSourcesList
	}
	#################################
	#配置国内镜像源
	if [ "$(uname -m)" = "mips" ]; then
	    chattr +i /etc/apt/sources.list
	    sed -i 's:# en_US.UTF-8 UTF-8:en_US.UTF-8 UTF-8:' /etc/locale.gen
	fi
	##################
	if ! grep -Eqi 'debian|ubuntu|kali|raspbian|Mint' "/etc/issue"; then
	    chattr +i /etc/apt/sources.list 2>/dev/null
	fi
	####################
	if [ ! -f "/tmp/.RASPBIANARMHFDetectionFILE" ]; then
	    if grep -q 'Debian' "/etc/issue"; then
	        debian_sources_list
	    fi
	fi
	###############
	if grep -q 'Kali' "/etc/issue"; then
	    kali_sources_list
	elif [ "$(cat /etc/issue | cut -c 1-6)" = "Ubuntu" ]; then
	    ubuntu_sources_list
	elif grep -q 'Mint' "/etc/issue"; then
	    mint_sources_list
	elif grep -q 'OpenWrt' "/etc/os-release"; then
	    cp /etc/opkg/distfeeds.conf /etc/opkg/distfeeds.conf.bak
		sed -i 's@downloads.openwrt.org@mirrors.tuna.tsinghua.edu.cn/openwrt@g' /etc/opkg/distfeeds.conf
	fi
	#################
	 sed -i 's/^deb/# &/g' /etc/apt/sources.list && sed -i 's/^##deb/deb/g' /etc/apt/sources.list

	#配置dns解析
	rm -f /etc/resolv.conf
	cat >/etc/resolv.conf <<-'EndOfFile'
			nameserver 1.0.0.1
			nameserver 2606:4700:4700::1111
		EndOfFile
	######################
	###################
	arch_linux_mirror_list() {
	    sed -i 's/^Server/#&/g' /etc/pacman.d/mirrorlist
	    if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "armv7l" ]; then
	        cat >>/etc/pacman.d/mirrorlist <<-'EndOfArchMirrors'
					#Server = https://mirror.archlinuxarm.org/$arch/$repo
					#Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo
					Server = https://mirrors.163.com/archlinuxarm/$arch/$repo
				EndOfArchMirrors
	    else
	        cat >>/etc/pacman.d/mirrorlist <<-'EndOfArchMirrors'
					#Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch
					#Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
					Server = https://mirrors.huaweicloud.com/archlinux/$repo/os/$arch
				EndOfArchMirrors
	    fi
	}
	#############################
	manjaro_mirror_list() {
	    if [ "$(uname -m)" = "aarch64" ]; then
	        #sed -i 's/^Server/#&/g' /etc/pacman.d/mirrorlist
	        #清华镜像站的manjaro rootfs容器竟然没grep、awk和sed
	        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
	        cat >/etc/pacman.d/mirrorlist <<-'EndOfArchMirrors'
					#Server = https://mirror.archlinuxarm.org/$arch/$repo
					#Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo
					#Server = https://mirrors.tuna.tsinghua.edu.cn/manjaro/arm-stable/$repo/$arch
		            Server = https://mirrors.huaweicloud.com/manjaro/arm-stable/$repo/$arch
				EndOfArchMirrors
	        #curl -Lo 'archlinuxarm-keyring.pkg.tar.xz' https://mirrors.tuna.tsinghua.edu.cn/manjaro/arm-stable/core/aarch64/archlinuxarm-keyring-20140119-1-any.pkg.tar.xz
	        #pacman-key --init
	        #pacman -U --noconfirm ./archlinuxarm-keyring.pkg.tar.xz
	        #rm -fv ./archlinuxarm-keyring.pkg.tar.xz
	        #pacman-key --populate archlinux manjaro
	        #pacman -Sy --noconfirm archlinux-keyring
	        #pacman -S --noconfirm iputils
	    fi
	}
	#################
	arch_linux_yay() {
	    grep -q '^LANG=' /etc/locale.conf 2>/dev/null || echo 'LANG=en_US.UTF-8' >>/etc/locale.conf
	    pacman -Syyu --noconfirm
	    if ! grep -q 'archlinuxcn' /etc/pacman.conf; then
	        cat >>/etc/pacman.conf <<-'Endofpacman'
					[archlinuxcn]
					Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
				Endofpacman
	    fi
	    pacman -Syu --noconfirm archlinux-keyring
	    pacman -Sy --noconfirm archlinuxcn-keyring
	    pacman -S --noconfirm yay
	    yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
	    pacman -S --noconfirm diffutils iproute
	}
	#################
	#################
	if [ "$(cat /etc/issue | cut -c 1-4)" = "Arch" ]; then
	    arch_linux_mirror_list
	elif [ "$(cat /etc/issue | cut -c 1-7)" = "Manjaro" ]; then
	    manjaro_mirror_list
			pacman-key --init
	        pacman-key --populate
	    #pacman -Sy --noconfirm grep sed awk
		pacman -Syu --noconfirm base base-devel
	fi

	if [ -e "/etc/pacman.conf" ] && [ $(command -v grep) ]; then
	    arch_linux_yay
	fi
	#######################
	alpine_linux_configure() {
	    if [ "$(sed -n 2p /etc/os-release | cut -d '=' -f 2)" = "alpine" ]; then
		    echo "检测到您使用的不是deb系linux，优化步骤可能会出错，您可以单独输${YELLOW}debian-i${RESET}来启动软件安装工具。"
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
	        opkg install libustream-openssl ca-bundle ca-certificates bash
	    fi
	    bash zsh.sh
	    # ash -c "$(wget --no-check-certificate -O- 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh')"
	}
	########################
	opensuse_linux_repo() {
	    LINUX_DISTRO='suse'
	    if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "armv7l" ]; then
	        zypper mr -da
	        zypper addrepo -fcg https://mirrors.tuna.tsinghua.edu.cn/opensuse/tumbleweed/repo/oss/ tuna-mirrors-oss
	        zypper addrepo -fcg https://mirrors.tuna.tsinghua.edu.cn/opensuse/tumbleweed/repo/non-oss/ tuna-mirrors-non-oss
	        zypper addrepo -fcg https://mirrors.tuna.tsinghua.edu.cn/packman/suse/openSUSE_Tumbleweed/ tuna-mirrors_Tumbleweed
	        zypper --gpg-auto-import-keys refresh
	        #zypper dup --no-allow-vendor-change -y
	    fi
	    zypper install -y wget curl
	    sed -i 's@RC_LANG=.*@RC_LANG=en_US.UTF8@' /etc/sysconfig/language
	    sed -i 's@RC_LC_ALL=.*@RC_LC_ALL=en_US.UTF8@' /etc/sysconfig/language
	    sed -i 's@INSTALLED_LANGUAGES=@INSTALLED_LANGUAGES=en_US@' /etc/sysconfig/language
	    zypper install -y glibc-locale glibc-i18ndata translation-update-zh_CN
	}
	################################
	if [ -f "/tmp/.ALPINELINUXDetectionFILE" ]; then
	    alpine_linux_configure
	elif grep -q 'openSUSE' "/etc/issue"; then
	    opensuse_linux_repo
	fi
	##############################
	apt update 2>/dev/null
	if [ ! $(command -v locale-gen) ]; then
	    apt install -y locales 2>/dev/null
	fi

	TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
	if [ -e "${TMOE_LOCALE_FILE}" ]; then
		TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
		TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
		TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
	else
		TMOE_LANG="en_US.UTF-8"
		TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
		TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
	fi

	if grep -q 'ubuntu' /etc/os-release; then
	   apt install -y ^language-pack-${TMOE_LANG_QUATER} 2>/dev/null
	fi

	echo "您已成功安装GNU/Linux,之后可以输${YELLOW}debian${RESET}来进入debian system."
	echo "Congratulations on your successful installation of GNU/Linux container. After that, you can type debian in termux to enter the container. "
	echo '正在执行优化步骤，请勿退出!'
	echo 'Optimization steps are in progress. Do not exit!'

	#配置国内时区
	echo 'Asia/Shanghai' >/etc/timezone
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	sed -i 's/^/#&/g' /etc/default/locale
	sed -i 's/##/#/g' /etc/default/locale
	if [ ! -e "/usr/local/etc/tmoe-linux/locale.txt" ]; then
	  echo "Configuring Chinese environment..."
	  #sed -i 's/^#.*en_US.UTF-8.*/en_US.UTF-8 UTF-8/' /etc/locale.gen
	  sed -i 's/^#.*zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
	  cat >>/etc/default/locale <<-'EOF'
			LANG=en_US.UTF-8
			LANGUAGE=en_US:zh
			LC_ALL=en_US.UTF-8
		EOF
	  #locale-gen
	  locale-gen zh_CN.UTF-8
	else
	  TMOE_LANG=$(cat /usr/local/etc/tmoe-linux/locale.txt | head -n 1)
	  TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
	  TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
	  echo "Configuring ${TMOE_LANG_HALF} environment..."
	  sed -i "s/^#.*${TMOE_LANG} UTF-8/${TMOE_LANG} UTF-8/" /etc/locale.gen
	  cat >>/etc/default/locale <<-EOF
			LANG=${TMOE_LANG}
			LANGUAGE=${TMOE_LANG_HALF}:${TMOE_LANG_QUATER}
			LC_ALL=${TMOE_LANG}
		EOF
	  if ! grep -q "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
	    sed -i 's@^@#@g' /etc/locale.gen 2>/dev/null
	    sed -i 's@##@#@g' /etc/locale.gen 2>/dev/null
	    echo '' >>/etc/locale.gen
	    sed -i "$ a\${TMOE_LANG} UTF-8" /etc/locale.gen
	  fi
	  locale-gen ${TMOE_LANG}
	fi
	source /etc/default/locale 2>/dev/null
	#################
	printf "$YELLOW"
	cat <<-'EndOFneko'
			                                     
			       DL.                           
			       QBBBBBKv:rr77ri:.             
			       gBBQdY7::::..::i7vv.          
			       UBd. . .:.........rBBBQBBBB5  
			       Pu  :..r......i:....BBBQBBB:  
			       ri.i:.j:...:. i7... uBBZrd:   
			 :     7.:7.7U.:..r: Yr:.. iQ1:qU    
			.Qi   .7.ii.X7:...L.:qr:...iB7ZQ     
			 .27. :r.r:L7i::.7r:vri:...rr  .     
			  v   ::.Yrviri:7v7v: ::...i.   i    
			      r:ir: r.iiiir..:7r...r   :P.2Y 
			      v:vi::.      :  ::. .qI7U1U :1 
			Qr    7.7.         :.i::. :Di:. i .v:
			v7..  s.r7.   ...   .:7i: rDi...r .. 
			 vi: .7.iDBBr  .r   .:.7. rPr:..r    
			 i   :virZBgi  :vrYJ1vYY .ruY:..i    
			     YrivEv. 7BBRBqj21I7 .77J:.:.PQ  
			    .1r:q.   rB52SKrj.:i i5isi.:i :.r
			    YvrY7    r.  . ru :: PIrj7.:r..v 
			   rSviYI..iuU .:.:i:.7.KPPiSr.:vr   
			  .u:Y:JQMSsJUv...   .rDE1P71:.7X7   
			  5  Ivr:QJ7JYvi....ir1dq vYv.7L.Y   
			  S  7Z  Qvr:.iK55SqS1PX  Xq7u2 :7   
			         .            i   7          

		EndOFneko
	printf "$RESET"
	####################
	apt install -y apt-utils 2>/dev/null
	apt install -y ca-certificates wget curl 2>/dev/null
	if grep -Eq 'squeeze|wheezy|stretch|jessie' "/etc/os-release"; then
	     apt install -y apt-transport-https 2>/dev/null
	fi
	if [ ! -f "/tmp/.RASPBIANARMHFDetectionFILE" ]; then
	    echo "Replacing http software source list with https."
	    echo "正在将http源替换为https..."
	    sed -i 's@http:@https:@g' /etc/apt/sources.list
	    sed -i 's@https://security@http://security@g' /etc/apt/sources.list
	else
	    rm -f "/tmp/.RASPBIANARMHFDetectionFILE"
	fi
	##########################
	gentoo_gnu_linux_make_conf() {
	    LINUX_DISTRO=gentoo
	    grep -q 'en_US' /etc/locale.gen || echo -e '\nen_US.UTF-8 UTF-8\nen_US.UTF-8 UTF-8' >>/etc/locale.gen
	    locale-gen
	    GENTOOLOCALE="$(eselect locale list | grep 'en_US' | head -n 1 | cut -d '[' -f 2 | cut -d ']' -f 1)"
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
	}
	#############################
	void_linux_repository() {
	    LINUX_DISTRO='void'
	    cat >/etc/locale.conf <<-'EOF'
				LANG=en_US.UTF-8
				LANGUAGE=en_US:zh
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
	    #rm -f vnc* zsh* .profile
	    #mv -f .profile.bak .profile 2>/dev/null
	    #wget -qO zsh.sh 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh'
	    #sed -i '1 c\#!/bin/bash' zsh.sh
	    #chmod +x zsh.sh
	    echo '检测到您当前的系统为Void GNU/Linux,若配置出错，则请手动输debian-i'
	    #zsh 2>/dev/null || bash
	    #exit 0
	}
	##########################
	if grep -Eq 'Funtoo|Gentoo' '/etc/os-release'; then
	    gentoo_gnu_linux_make_conf
	elif grep -qi 'Void' '/etc/issue'; then
	    void_linux_repository
	elif [ "$(uname -m)" = "mips" ]; then
	    chattr -i /etc/apt/sources.list
	elif ! grep -Eqi 'debian|ubuntu|kali|raspbian|Mint' "/etc/issue"; then
	    chattr -i /etc/apt/sources.list 2>/dev/null
	fi
	####################
	apt update
	apt list --upgradable
	echo "正在升级所有软件包..."
	apt dist-upgrade -y
	apt install -y procps
	apt clean

	#############################
	#grep -q 'export DISPLAY' /etc/profile || echo "export DISPLAY=":1"" >>/etc/profile

	echo "Welcome to Debian GNU/Linux."
	cat /etc/issue 2>/dev/null || cat /etc/os-release
	uname -a
	rm -f vnc-autostartup .profile
	if [ -f ".profile.bak" ]; then
	    mv -f .profile.bak .profile
	fi
	#################
	if [ -f ".bash_profile.bak" ] || [ -f ".bash_login.bak" ]; then
	    mv -f .bash_profile.bak .bash_profile.bak 2>/dev/null
	    mv -f .bash_login.bak .basfh_login.bak 2>/dev/null
	fi
	####################
	echo "Automatically configure zsh after 2 seconds,you can press Ctrl + C to cancel."
	echo "2s后将自动开始配置zsh，您可以按Ctrl+C取消，这将不会继续配置其它步骤，同时也不会启动Tmoe-linux工具。"
	#wget -qcO /usr/local/bin/neofetch 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch' || curl -sLo /usr/local/bin/neofetch 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch'
	chmod +x /usr/local/bin/neofetch
	neofetch
	################
	################
	slackware_mirror_list() {
	    LINUX_DISTRO='slackware'
	    sed -i 's/^ftp/#&/g' /etc/slackpkg/mirrors
	    sed -i 's/^http/#&/g' /etc/slackpkg/mirrors
	    sed -i '$ a\https://mirrors.tuna.tsinghua.edu.cn/slackwarearm/slackwarearm-current/' /etc/slackpkg/mirrors
	    slackpkg update gpg
	    slackpkg update
	}
	###################
	if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '=' -f 2)" = "slackware" ]; then
	    slackware_mirror_list
	fi
	#############################################
	fedora_31_repos() {
	    curl -o /etc/yum.repos.d/fedora.repo http://mirrors.aliyun.com/repo/fedora.repo
	    curl -o /etc/yum.repos.d/fedora-updates.repo http://mirrors.aliyun.com/repo/fedora-updates.repo
	}
	###########
	#fedora清华源mirrors.tuna.tsinghua.edu.cn/fedora/releases/
	fedora_32_repos() {
	    cat >/etc/yum.repos.d/fedora.repo <<-'EndOfYumRepo'
				[fedora]
				name=Fedora $releasever - $basearch
				failovermethod=priority
				baseurl=https://mirrors.huaweicloud.com/fedora/releases/$releasever/Everything/$basearch/os/
				metadata_expire=28d
				gpgcheck=1
				gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
				skip_if_unavailable=False
			EndOfYumRepo

	    cat >/etc/yum.repos.d/fedora-updates.repo <<-'EndOfYumRepo'
				[updates]
				name=Fedora $releasever - $basearch - Updates
				failovermethod=priority
				baseurl=https://mirrors.huaweicloud.com/fedora/updates/$releasever/Everything/$basearch/
				enabled=1
				gpgcheck=1
				metadata_expire=6h
				gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
				skip_if_unavailable=False
			EndOfYumRepo
	}
	#########################
	fedora_3x_repos() {
	    cat >/etc/yum.repos.d/fedora-modular.repo <<-'EndOfYumRepo'
				[fedora-modular]
				name=Fedora Modular $releasever - $basearch
				failovermethod=priority
				baseurl=https://mirrors.huaweicloud.com/fedora/releases/$releasever/Modular/$basearch/os/
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
				baseurl=https://mirrors.huaweicloud.com/fedora/updates/$releasever/Modular/$basearch/
				enabled=1
				gpgcheck=1
				metadata_expire=6h
				gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
				skip_if_unavailable=False
			EndOfYumRepo
	    #dnf install -y glibc-langpack-zh
	    #localedef -c -f UTF-8 -i en_US zh_CN.utf8
	    #dnf clean packages
	}
	######################
	if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '=' -f 2 |cut -d '"' -f 2)" = "fedora" ]; then
	    tar -Ppzcf ~/yum.repos.d-backup.tar.gz /etc/yum.repos.d
	    mv -f ~/yum.repos.d-backup.tar.gz /etc/yum.repos.d
	    FEDORA_VERSION="$(cat /etc/os-release | grep 'VERSION_ID' | cut -d '=' -f 2)"
	    if ((${FEDORA_VERSION} >= 30)); then
	        if ((${FEDORA_VERSION} >= 32)); then
	            fedora_32_repos
	        else
	            fedora_31_repos
	        fi
	        fedora_3x_repos
	    fi

	elif grep -q 'CentOS' /etc/os-release; then
	    cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
	    #curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
		#curl -Lo /etc/yum.repos.d/CentOS-Base.repo https://mirrors.huaweicloud.com/repository/conf/CentOS-8-anon.repo
		dnf install -y epel-release
		#dnf update
		cp -a /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
	    cp -a /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
	   sed -e 's!^metalink=!#metalink=!g' \
	    -e 's!^#baseurl=!baseurl=!g' \
	    -e 's!//download\.fedoraproject\.org/pub!//mirrors.tuna.tsinghua.edu.cn!g' \
	    -e 's!http://mirrors\.tuna!https://mirrors.tuna!g' \
	    -i /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel-testing.repo
	fi
	############################
	note_of_non_debian() {
	    echo "检测到您使用的不是deb系linux，优化步骤可能会出现错误"
	    echo "在脚本执行完成后，您可以手动输./zsh-i.sh来配置zsh，输 ${YELLOW}debian-i${RESET}打开软件安装工具"
	    bash zsh.sh
	    debian-i
	    #bash zsh-i.sh
	    #bash -c "$(curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh')" || bash -c "$(wget -qO- 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh')"
	}
	################
	if ! grep -q 'debian' '/etc/os-release'; then
	    note_of_non_debian
	else
	    bash zsh.sh
	fi
ENDOFbashPROFILE
#####################
if [ "${LINUX_DISTRO}" != 'Android' ]; then
	sed -i 's:#!/data/data/com.termux/files/usr/bin/bash:#!/bin/bash:g' $(grep -rl 'com.termux' "${PREFIX}/bin")
	#sed -i 's:#!/data/data/com.termux/files/usr/bin/bash:#!/bin/bash:' ${DEBIAN_CHROOT}/remove-debian.sh
fi

bash ${PREFIX}/bin/debian
