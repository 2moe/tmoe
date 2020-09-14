#!/data/data/com.termux/files/usr/bin/env bash
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
######################
#安装必要依赖
#apt update
#apt install -y curl openssl proot aria2 procps
#gentoo_arm64在下一行修改ARCH_TYPE的变量为armhf

#requirements and DEPENDENCIES.
TRUE_ARCH_TYPE=${ARCH_TYPE}
QEMU_ARCH=''
CONFIG_FOLDER="${HOME}/.config/tmoe-linux"
ACROSS_ARCH_FILE="${CONFIG_FOLDER}/across_architecture_container.txt"
if [ -e "${ACROSS_ARCH_FILE}" ]; then
	ARCH_TYPE="$(cat ${ACROSS_ARCH_FILE} | head -n 1)"
	QEMU_ARCH="$(cat ${ACROSS_ARCH_FILE} | sed -n 2p)"
fi

LINUX_CONTAINER_DISTRO_FILE="${CONFIG_FOLDER}/linux_container_distro.txt"
DEBIAN_FOLDER=debian_${ARCH_TYPE}
if [ -e "${LINUX_CONTAINER_DISTRO_FILE}" ]; then
	LINUX_CONTAINER_DISTRO=$(cat ${LINUX_CONTAINER_DISTRO_FILE} | head -n 1)
	if [ ! -z "${LINUX_CONTAINER_DISTRO}" ]; then
		DEBIAN_FOLDER="${LINUX_CONTAINER_DISTRO}_${ARCH_TYPE}"
	fi
fi
DEBIAN_CHROOT=${HOME}/${DEBIAN_FOLDER}

#mkdir -p ~/storage/external-1
if [ -e "${CONFIG_FOLDER}/chroot_container" ]; then
	TMOE_CHROOT='true'
	if [ $(command -v sudo) ]; then
		TMOE_CHROOT_PREFIX=sudo
	elif [ $(command -v tsudo) ]; then
		TMOE_CHROOT_PREFIX=tsudo
	fi
else
	TMOE_CHROOT_PREFIX=''
fi
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
	TF_CARD_PATH="${HOME}/storage/external-1"
	if [ -h "${TF_CARD_PATH}" ]; then
		if [ ! -e "${TF_CARD_PATH}/path.txt" ]; then
			echo "$(readlink ${TF_CARD_PATH})" >${TF_CARD_PATH}/path.txt
		fi
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
		echo "检测到termux配色文件不存在，正在自动生成..."
		echo "如需還原，則請輸${RED}rm${RESET} ${BLUE}${HOME}/.termux/colors.properties${RESET}"
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
		echo "如需還原，則請輸${RED}rm${RESET} ${BLUE}${HOME}/.termux/termux.properties${RESET}"
		aria2c --allow-overwrite=true -o "termux.properties" 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/.termux/termux.properties'
	fi
	#REMOTEP10KFONT='8597c76c4d2978f4ba022dfcbd5727a1efd7b34a81d768362a83a63b798f70e5'
	#LOCALFONT="$(sha256sum font.ttf | cut -c 1-64)" || LOCALFONT="0"
	if [ ! -e "font.ttf" ]; then
		#if [ "${REMOTEP10KFONT}" != "${LOCALFONT}" ]; then
		echo -e 'Detected that the font file does not exist.\n检测到字体文件不存在，正在自动配置字体...'
		aria2c --allow-overwrite=true -o Iosevka.tar.xz 'https://gitee.com/mo2/Termux-zsh/raw/p10k/Iosevka.tar.xz'
		echo "只有少部分字体能显示powerlevel10k的特殊字符，例如Iosevka和MesloLGS"
		echo "如需還原，則請輸${RED}rm${RESET} ${BLUE}${HOME}/.termux/font.ttf${RESET}"
		#仓库为Termux-zsh/raw/p10k，批量重命名的时候要小心一点。
		#mv -f font.ttf font.ttf.bak
		tar -Jxvf Iosevka.tar.xz
		rm -f Iosevka.tar.xz
		sleep 1
		termux-reload-settings
		#fi
	fi
else
	if grep -q 'alias debian=' "/etc/profile"; then
		sed -i '/alias debian=/d' "/etc/profile"
		sed -i '/alias startvnc=/d' "/etc/profile"
		sed -i '/alias stopvnc=/d' "/etc/profile"
		sed -i '/alias debian-i=/d' "/etc/profile"
	fi

	if grep -q 'alias debian=' "${HOME}/.zshrc"; then
		sed -i '/alias debian=/d' "${HOME}/.zshrc"
		sed -i '/alias startvnc=/d' "${HOME}/.zshrc"
		sed -i '/alias stopvnc=/d' "${HOME}/.zshrc"
		sed -i '/alias debian-i=/d' "${HOME}/.zshrc"
	fi
fi
#旧版将相关命令设立了alias，新版需要删掉。
####################
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
	echo "检测到您选择的是树莓派系统"
	echo "已将您的架构临时识别为armhf"
	echo "若您需要安装${YELLOW}arm64${RESET}版的树莓派系统，则请将arm64版的RaspiOS rootfs文件重命名为${GREEN}raspios-buster_armhf_lite-rootfs.tar.xz${RESET},并将其移动到${BLUE}${HOME}${RESET}"
	#将通过debian buster来间接安装raspbian buster
	rm -f "${HOME}/.RASPBIANARMHFDetectionFILE"
fi
###############
cd ${HOME}
if [ -d "${DEBIAN_FOLDER}" ]; then
	echo "Detected that you have debian installed 检测到您已安装debian"
fi
mkdir -p ~/${DEBIAN_FOLDER}
############
TUNA_LXC_IMAGE_MIRROR_REPO="https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/sid/${ARCH_TYPE}/default"
TMOE_ROOTFS_TAR_XZ="debian-sid_${ARCH_TYPE}-rootfs.tar.xz"
TMOE_MIPSEL_ROOTFS_URL='https://webdav.tmoe.me/down/share/Tmoe-linux/chroot/debian_mipsel.tar.xz'
TMOE_PROOT_PROC_FILE_URL='https://gitee.com/ak2/proot_proc/raw/master/proc.tar.xz'
###########
cat <<-EOF
	現在可公開的情報:
	${BOLD}Tmoe-linux 小提示${RESET}:
			01:不同远程桌面的体验有可能是不同的呢！ヽ(✿ﾟ▽ﾟ)ノ
			-------------------
			Different remote desktops may have different experiences.
			-------------------
			02:在某种环境下执行某条命令，将同时调用宿主机的VNC viewer和容器的vnc server。
			-------------------
			Executing a certain command in a certain environment will call the processes of the host and the container almost simultaneously.
			---------------
			03:所有容器的启动命令都是一样的哦！o( =•ω•= )m
			但是呢！输那条启动命令仅支持启动${BLUE}${DEBIAN_FOLDER}容器${RESET}，不会自动启动远程桌面服务。
			-------------------
			The start command of the container supports starting and attaching the ${DEBIAN_FOLDER} container.
			-------------------
			04:并非所有${YELLOW}字体${RESET}都支持${BLUE}powerlevel 10k${RESET}的特殊字符哦！🍥
			-------------------
			Some fonts do not support powerlevel10k special characters.
			-------------------
EOF
############################
echo "Detected that your current architecture is ${YELLOW}${ARCH_TYPE}${RESET}"
echo "检测到您当前的架构为${YELLOW}${ARCH_TYPE}${RESET}，${GREEN}debian system${RESET}将安装至${BLUE}~/${DEBIAN_FOLDER}${RESET}"
##################
if [ ! -f ${TMOE_ROOTFS_TAR_XZ} ]; then
	if [ "${ARCH_TYPE}" != 'mipsel' ]; then
		echo "正在从${YELLOW}清华大学开源镜像站${RESET}${GREEN}下载${RESET}容器镜像..."
		echo "Downloading ${BLUE}${TMOE_ROOTFS_TAR_XZ}${RESET} from Tsinghua University Open Source Mirror Station."
		TTIME=$(curl -L "${TUNA_LXC_IMAGE_MIRROR_REPO}/" | grep date | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
		if [ "${LINUX_DISTRO}" != 'iSH' ]; then
			aria2c -x 5 -k 1M --split 5 -o ${TMOE_ROOTFS_TAR_XZ} "${TUNA_LXC_IMAGE_MIRROR_REPO}/${TTIME}rootfs.tar.xz"
		else
			wget -O ${TMOE_ROOTFS_TAR_XZ} "${TUNA_LXC_IMAGE_MIRROR_REPO}/${TTIME}rootfs.tar.xz"
		fi
	else
		aria2c -x 6 -k 1M --split 6 -o ${TMOE_ROOTFS_TAR_XZ} "${TMOE_MIPSEL_ROOTFS_URL}"
	fi
fi
##################
CURRENT_TMOE_DIR=$(pwd)
if [ ! -e "${CONFIG_FOLDER}/chroot_container" ]; then
	if [ ! -e "${CONFIG_FOLDER}/proc.tar.xz" ]; then
		aria2c -d ${CONFIG_FOLDER} -o proc.tar.xz --allow-overwrite=true "${TMOE_PROOT_PROC_FILE_URL}"
	fi
	cd ${DEBIAN_CHROOT}
	if [ -e "${CONFIG_FOLDER}/proc.tar.xz" ]; then
		tar -Jxf ${CONFIG_FOLDER}/proc.tar.xz 2>/dev/null
	fi
else
	cd ${DEBIAN_CHROOT}
fi
####################
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
	少女祈禱中...
	現在可公開的情報:
	${BOLD}Tmoe-linux 小提示05${RESET}(仅适用于GUI安装完成后):

			若您的宿主机为${BOLD}Android${RESET}系统,则在termux原系统下输${GREEN}startvnc${RESET}将${RED}同时启动${RESET}安卓版Realvnc${YELLOW}客户端${RESET}和${BOLD}${DEBIAN_FOLDER}${RESET}的${BLUE}VNC服务端${RESET}。
			------------------
			输${GREEN}startxsdl${RESET}将${RED}启动${RESET}安卓版${YELLOW}XSDL${RESET}，并于9秒后自动启动${BOLD}${DEBIAN_FOLDER}${RESET}的${BLUE}x11${RESET}。
			-------------------
			您也可以在${BOLD}${DEBIAN_FOLDER}${RESET}容器内输${GREEN}startvnc${RESET}来单独启动${BLUE}tight或tigervnc服务${RESET}，输${RED}stopvnc${RESET}停止
			-------------------
			You can type ${GREEN}startvnc${RESET} to start ${BLUE}tight/tigervnc server${RESET},type ${RED}stopvnc${RESET} to stop it.
			-------------------
			输${GREEN}startx11vnc${RESET}启动${BLUE}x11vnc服务${RESET},x11vnc能运行tightvnc无法打开的某些应用哦！
			-------------------
			You can also type ${GREEN}startx11vnc${RESET} to start ${BLUE}x11vnc server.${RESET}
			------------------
	${BOLD}小提示06${RESET}:

			在${BOLD}${DEBIAN_FOLDER}${RESET}容器内输${GREEN}debian-i${RESET}启动软件安装及远程桌面配置${BLUE}管理工具${RESET}。
			You can type ${GREEN}debian-i${RESET} to start ${BLUE}tmoe-linux tool.${RESET}
			-------------------
	${BOLD}小提示07${RESET}:

			在宿主机的终端里输${GREEN}debian${RESET}单独启动${BLUE}${BOLD}${DEBIAN_FOLDER}${RESET}容器${RESET}，此时将不会自动启动远程桌面服务。
			You can type ${GREEN}debian${RESET} to start ${BLUE}${BOLD}${DEBIAN_FOLDER}${RESET} container.${RESET}
			-------------------
EOF
################
uncompress_other_format_file() {
	if [ "${TMOE_CHROOT}" = "true" ]; then
		${TMOE_CHROOT_PREFIX} tar -pxvf ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ}
	elif [ "${LINUX_DISTRO}" = "Android" ]; then
		pv ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ} | proot --link2symlink tar -px
	else
		if [ $(command -v pv) ]; then
			pv ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ} | tar -px
		else
			tar -pxvf ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ}
		fi
	fi
}
##############
uncompress_tar_lz4_file() {
	TRUE_TMOE_ROOTFS_TAR_XZ=${TMOE_ROOTFS_TAR_XZ}
	TMOE_ROOTFS_TAR=$(echo ${TMOE_ROOTFS_TAR_XZ} | sed 's@.tar.lz4@.tar@')
	cd ${HOME}
	rm -fv ${TMOE_ROOTFS_TAR} 2>/dev/null
	lz4 -d ${TMOE_ROOTFS_TAR_XZ}
	cd ${DEBIAN_CHROOT}

	TMOE_ROOTFS_TAR_XZ=${TMOE_ROOTFS_TAR}
	uncompress_other_format_file
	TMOE_ROOTFS_TAR_XZ=${TRUE_TMOE_ROOTFS_TAR_XZ}

	rm -fv ${HOME}/${TMOE_ROOTFS_TAR}
}
###########
uncompress_tar_gz_file() {
	if [ "${TMOE_CHROOT}" = "true" ]; then
		${TMOE_CHROOT_PREFIX} tar -pzxvf ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ}
	elif [ "${LINUX_DISTRO}" = "Android" ]; then
		pv ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ} | proot --link2symlink tar -pzx
	else
		if [ $(command -v pv) ]; then
			pv ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ} | tar -pzx
		else
			tar -pzxvf ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ}
		fi
	fi
}
#####################
check_tar_xz_pv() {
	if [ $(command -v pv) ]; then
		pv ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ} | tar -pJx
	else
		tar -pJxvf ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ}
	fi
}
#############
uncompress_tar_xz_file() {
	echo "正在${GREEN}解压${RESET}${BLUE}${TMOE_ROOTFS_TAR_XZ}...${RESET}"
	echo "Extracting ${TMOE_ROOTFS_TAR_XZ}, please wait."
	if [ "${ARCH_TYPE}" = "mipsel" ]; then
		pv ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ} | tar -pJx
		mv -b ${DEBIAN_CHROOT}/debian_mipsel/* ${DEBIAN_CHROOT}
	elif [ "${TMOE_CHROOT}" = "true" ]; then
		${TMOE_CHROOT_PREFIX} tar -pJxvf ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ}
	elif [ "${LINUX_DISTRO}" = "Android" ]; then
		pv ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ} | proot --link2symlink tar -pJx
	elif [ "${LINUX_DISTRO}" = "iSH" ]; then
		tar -pJxvf ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ}
	else
		check_tar_xz_pv
	fi
}
#############
#解压前已进入$DEBIAN_CHROOT目录
uncompress_tar_file() {
	case "${TMOE_ROOTFS_TAR_XZ:0-6:6}" in
	tar.xz)
		uncompress_tar_xz_file
		;;
	tar.gz)
		uncompress_tar_gz_file
		;;
	ar.lz4)
		#此处不为tar.lz4
		uncompress_tar_lz4_file
		;;
	*)
		uncompress_other_format_file
		;;
	esac
}
#######################
uncompress_tar_file

REMOTEP10KFONT='8597c76c4d2978f4ba022dfcbd5727a1efd7b34a81d768362a83a63b798f70e5'
IOSEVKA_FONT='2b41066b8faea10f7f4356a280b011c2fa3cd007000e6eca25f2f9aaf8b44713'
MESLO_FONT='4ac3012945f484496c899dce3b6ff6ec1a7395a444e9bf5acdf004867334cd17'
MESLO_BOLD_FONT='43f8115a8432c29662cec5028cf39a1576cc312db115fe12f2b839d4345d42a9'
LOCALFONT="$(sha256sum ~/.termux/font.ttf 2>/dev/null | cut -c 1-64)" || LOCALFONT="0"
mkdir -p ${DEBIAN_CHROOT}/tmp
case ${LOCALFONT} in
${REMOTEP10KFONT} | ${IOSEVKA_FONT} | ${MESLO_FONT} | ${MESLO_BOLD_FONT}) cp -f ~/.termux/font.ttf ${DEBIAN_CHROOT}/tmp 2>/dev/null ;;
*)
	MESLO_FONT_DIR="${HOME}/.config/tmoe-zsh/fonts/fonts/MesloLGS-NF-Bold"
	if [ -e "${MESLO_FONT_DIR}" ]; then
		cd ${MESLO_FONT_DIR}
		${TMOE_CHROOT_PREFIX} cp -f 'MesloLGS NF Bold.ttf' ${DEBIAN_CHROOT}/tmp/font.ttf
	fi
	;;
esac

if [ "${LINUX_DISTRO}" = 'openwrt' ]; then
	${TMOE_CHROOT_PREFIX} touch ~/${DEBIAN_FOLDER}/tmp/.openwrtcheckfile
fi
#proot --link2symlink tar -Jxvf ${CURRENT_TMOE_DIR}/${TMOE_ROOTFS_TAR_XZ}||:
cd "${CURRENT_TMOE_DIR}"
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
cat_tmoe_chroot_script() {
	cat >${PREFIX}/bin/debian <<-ENDOFTMOECHROOT
		#!/data/data/com.termux/files/usr/bin/env bash
		get_tmoe_linux_help_info() {
		    cat <<-'ENDOFHELP'
												-i     --启动tmoe-linux manager
												-m     --更换为tuna镜像源(仅debian,ubuntu,kali,alpine和arch)
												-vnc   --启动VNC
												-n     --启动novnc
												-x     --启动x11
												-h     --get help info
											ENDOFHELP
		}
		############
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
		        startx11vnc
		        ;;
		    -n* | novnc*)
		        debian-i novnc
		        ;;
		    -x)
		        startxsdl
		        ;;
		    *) start_tmoe_gnu_linux_chroot_container ;;
		    esac
		}
		##############
		start_tmoe_gnu_linux_chroot_container() {
		    case \$(uname -o) in
		    Android) pulseaudio --start 2>/dev/null &;;
		    *)
		        case \$(id -u) in
		        0) ;;
		        *)
		            if [ \$(command -v sudo) ]; then
		                sudo su -c "bash ${PREFIX}/bin/debian"
		            else
		                su -c "bash ${PREFIX}/bin/debian"
		            fi
		            exit 1
		            ;;
		        esac
		        ;;
		    esac
		    ########
			if [ -e ${DEBIAN_CHROOT}/etc/os-release ];then
				cat ${DEBIAN_CHROOT}/etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d '"' -f 2
			else
				cat ${DEBIAN_CHROOT}/etc/issue 2>/dev/null
			fi
		    TMOE_LOCALE_FILE="${CONFIG_FOLDER}/locale.txt"
		    PROC_FD_PATH="/proc/self/fd"
		    #########
		    detect_mount() {
		        MOUNT_DIR="\$1"
		        if \$(grep -q " \${MOUNT_DIR%/} " /proc/mounts); then
		            return 0
		        else
		            return 1
		        fi
		    }
		    ##########
			#arch-linux挂载自身
			if ! detect_mount "${DEBIAN_CHROOT}/"; then
			   #echo ''
		       ##arch-chroot#
			   su -c "mount --rbind ${DEBIAN_CHROOT} ${DEBIAN_CHROOT}/ &>/dev/null"
			   su -c "mount -o remount,exec,suid,dev ${DEBIAN_CHROOT}"
			 fi
			 #########
		    if [ -f "${DEBIAN_CHROOT}/bin/zsh" ]; then
		        TMOE_SHELL="/bin/zsh"
		    elif [ -f "${DEBIAN_CHROOT}/bin/bash" ]; then
		        TMOE_SHELL="/bin/bash"
		    elif [ -f "${DEBIAN_CHROOT}/bin/ash" ]; then
		        TMOE_SHELL="/bin/ash"
		    else
		        TMOE_SHELL="/bin/su"
		    fi
		    set -- "\${TMOE_SHELL}" "-l" "\$@"
		    if [ -e "\${TMOE_LOCALE_FILE}" ]; then
		        set -- "LANG=\$(cat \${TMOE_LOCALE_FILE} | head -n 1)" "\$@"
		    else
		        set -- "LANG=en_US.UTF-8" "\$@"
		    fi
		    ############
		    mount_01() {
		        su -c "mount -o bind /\${i} ${DEBIAN_CHROOT}/\${i}"
		    }
		    #########
		    mkdir_01() {
		        if [ ! -e "/\${i}" ]; then
		            su -c "mkdir -p /\${i}"
		        fi
		    }
		    ########
		    #PS1='\u:\w$ '
		    set -- "/usr/bin/env" "-i" "HOME=/root" "PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games" "TMPDIR=/tmp" "TMOE_PROOT=false" "TMOE_CHROOT=true" "TERM=xterm-256color" "\$@"
		    for i in dev proc sys dev/pts dev/shm dev/tty0; do
		        if ! detect_mount "${DEBIAN_CHROOT}/\${i}"; then
		            case \${i} in
		            dev) mount_01 ;;
		            proc) su -c "mount -t \${i} \${i} ${DEBIAN_CHROOT}/\${i}" ;;
		            sys) su -c "mount -t \${i}fs \${i}fs ${DEBIAN_CHROOT}/\${i}" ;;
		            dev/pts)
		                if ! detect_mount "/\${i}"; then
		                    mkdir_01
		                    su -c "mount -o rw,nosuid,noexec,gid=5,mode=620,ptmxmode=000 -t devpts devpts /\${i}"
		                fi
		                su -c "mount -t devpts devpts ${DEBIAN_CHROOT}/\${i}"
		                ;;
		            dev/shm)
		                if ! detect_mount "/\${i}"; then
		                    mkdir_01
		                    su -c "mount -o rw,nosuid,nodev,mode=1777 -t tmpfs tmpfs /\${i}"
		                fi
		                mount_01
		                ;;
		            esac
		        fi
		    done
		    unset i
		    #dev/random) su -c "mount -o bind /dev/urandom ${DEBIAN_CHROOT}/\${i}" ;;
		    ########
		    for i in /dev/fd /dev/stdin /dev/stout /dev/sterr /dev/tty0; do
		        if [ ! -e \${i} ] && [ ! -h \${i} ]; then
		            case \${i} in
		            /dev/fd) su -c "ln -s \${PROC_FD_PATH} \${i} &>/dev/null" ;;
		            /dev/stdin) su -c "ln -s \${PROC_FD}/0 \${i} &>/dev/null" ;;
		            /dev/stdout) su -c "ln -s \${PROC_FD}/1 \${i} &>/dev/null" ;;
		            /dev/stderr) su -c "ln -s \${PROC_FD}/2 \${i} &>/dev/null" ;;
		            /dev/tty0)
		                #if [ -e "/dev/ttyGS0" ]; then
		                # su -c "ln -s /dev/ttyGS0 /\${i} &>/dev/null"
		                #else
		                su -c "ln -s /dev/null \${i} &>/dev/null"
		                #fi
		                ;;
		            esac
		        fi
		    done
		    unset i
		    ###############
		    mount_read_only_sd() {
		        ANDROID_EMULATED_0_DIR='/storage/emulated/0'
		        if [ -e "\${ANDROID_EMULATED_0_DIR}" ]; then
		            if [ ! -e "${DEBIAN_CHROOT}\${ANDROID_EMULATED_0_DIR}" ]; then
		                mkdir -p "${DEBIAN_CHROOT}\${ANDROID_EMULATED_0_DIR}"
		            fi
		            su -c "mount -o ro /storage/emulated/0 ${DEBIAN_CHROOT}\${ANDROID_EMULATED_0_DIR} &>/dev/null"
		        fi
		    }
		    ############
		    for i in tf termux sd; do
		        if ! detect_mount "${DEBIAN_CHROOT}/root/\${i}"; then
		            case \${i} in
		            tf)
		                TF_CARD_LINK="${HOME}/storage/external-1"
		                if [ -h "\${TF_CARD_LINK}" ]; then
		                    TF_CARD_FOLDER=\$(readlink \${TF_CARD_LINK} | awk -F '/' '{print \$3}')
		                    if [ "\$(su -c "ls /mnt/media_rw/\${TF_CARD_FOLDER}")" ]; then
		                        su -c "mount -o bind /mnt/media_rw/\${TF_CARD_FOLDER} ${DEBIAN_CHROOT}/root/\${i} &>/dev/null"
		                    else
		                        su -c "mount -o bind \${TF_CARD_LINK} ${DEBIAN_CHROOT}/root/\${i} &>/dev/null"
		                    fi
		                fi
		                ;;
		            #######
		            termux)
		                if [ -d "/data/data/com.termux/files/home" ]; then
		                    su -c "mount -o bind /data/data/com.termux/files/home ${DEBIAN_CHROOT}/root/\${i} &>/dev/null"
		                fi
		                ;;
		            ###########
		            sd)
		                if [ "\$(su -c "ls /data/media/0" 2>/dev/null)" ]; then
		                    su -c "mount -o bind /data/media/0 ${DEBIAN_CHROOT}/root/\${i} &>/dev/null"
		                    #su -c "mount -o bind /data/media/0/Download ${DEBIAN_CHROOT}/mnt/\${i} &>/dev/null"
		                elif [ -e "/storage/self/primary" ]; then
		                    su -c "mount -o bind /storage/self/primary ${DEBIAN_CHROOT}/root/\${i} &>/dev/null"
		                elif [ -e "/sdcard/Download" ] || [ -h "/sdcard/Download" ]; then
		                    su -c "mount -o bind /sdcard/Download ${DEBIAN_CHROOT}/root/\${i} &>/dev/null"
		                else
		                    mount_read_only_sd
		                fi
		                ;;
		            esac
		        fi
		    done
		    unset i
			 ###########
		     set -- "${DEBIAN_CHROOT}" "\$@"
		     set -- "chroot" "\$@"
		     unset LD_PRELOAD
			 TMOE_CHROOT_EXEC="exec \$@"
			 su -c "\${TMOE_CHROOT_EXEC}"
		    }
		    main "\$@"
	ENDOFTMOECHROOT
}
##############
creat_chroot_startup_script() {
	case ${LINUX_DISTRO} in
	Android)
		ANDROID_EMULATED_DIR='/storage/emulated'
		if [ ! -e "${DEBIAN_CHROOT}${ANDROID_EMULATED_DIR}" ]; then
			${TMOE_CHROOT_PREFIX} mkdir -p "${DEBIAN_CHROOT}${ANDROID_EMULATED_DIR}"
			#cd "${DEBIAN_CHROOT}${ANDROID_EMULATED_DIR}"
			#ln -s ../../root/sd ./0
			${TMOE_CHROOT_PREFIX} ln -s ../../root/sd ${DEBIAN_CHROOT}${ANDROID_EMULATED_DIR}/0
		fi
		;;
	esac
	cd ${CONFIG_FOLDER}
	if [ -e "/system/bin/wm" ]; then
		TMOE_CHROOT_ETC="${DEBIAN_CHROOT}/usr/local/etc/tmoe-linux"
		${TMOE_CHROOT_PREFIX} mkdir -p ${TMOE_CHROOT_ETC}
		WM_SIZE=$(su -c "/system/bin/wm size" | awk '{print $3}' | head -n 1)
		echo ${WM_SIZE} >wm_size.txt
		${TMOE_CHROOT_PREFIX} mv wm_size.txt ${TMOE_CHROOT_ETC}
	fi
	if [ $(command -v getprop) ]; then
		ANDROID_HOST_NAME=$(getprop ro.product.model)
		echo ${ANDROID_HOST_NAME} >hostname
		${TMOE_CHROOT_PREFIX} mv hostname ${DEBIAN_CHROOT}/etc/
		case $(hostname) in
		localhost | "")
			sudo hostname ${ANDROID_HOST_NAME}
			;;
		esac
	fi
	echo "Creating chroot startup script"
	echo "正在创建chroot容器启动脚本${PREFIX}/bin/debian "
	#if [ -e "/storage/self/primary" ] || [ -e "/sdcard" ]; then
	#mkdir -p /sdcard/Download ${DEBIAN_CHROOT}/root/sd ||
	mkdir -p /sdcard
	${TMOE_CHROOT_PREFIX} mkdir -p ${DEBIAN_CHROOT}/root/sd
	#fi
	if [ -d "/data/data/com.termux/files/home" ]; then
		#mkdir -p ${DEBIAN_CHROOT}/root/termux ||
		${TMOE_CHROOT_PREFIX} mkdir -p ${DEBIAN_CHROOT}/root/termux
		if [ -h "${HOME}/storage/external-1" ]; then
			#mkdir -p ${DEBIAN_CHROOT}/root/tf ||
			${TMOE_CHROOT_PREFIX} mkdir -p ${DEBIAN_CHROOT}/root/tf
		fi
	fi
	##################
	#for i in dev proc sys root/sd tmp root/termux root/tf; do
	#	if [ -e "${DEBIAN_CHROOT}/${i}" ]; then
	#		su -c "chattr +i ${i}"
	#	fi
	#done
	#unset i
	###############
	#此处若不创建，将有可能导致chromium无法启动。
	${TMOE_CHROOT_PREFIX} mkdir -p ${DEBIAN_CHROOT}/run/shm
	#chmod 1777 ${DEBIAN_CHROOT}/dev/shm 2>/dev/null
	cat_tmoe_chroot_script
}
###################
creat_tmoe_proot_stat_file() {
	cat >${TMOE_PROC_PREFIX}.${FILE_02} <<-'ENDOFSTAT'
		cpu  13543674 2263150 11590764 15571271 210309 1343827 851885 0 0 0
		cpu0 3629787 489276 3129188 15571051 210302 802654 516635 0 0 0
		cpu1 3221514 563397 2565534 19 0 168835 110203 0 0 0
		cpu2 2884314 491225 2361364 18 1 161981 92821 0 0 0
		cpu3 2664267 457057 2282166 21 0 166631 88732 0 0 0
		cpu4 365877 83980 417984 25 6 15600 10165 0 0 0
		cpu5 296831 71203 325638 39 0 9363 14383 0 0 0
		cpu6 262541 59844 288038 49 0 10350 10848 0 0 0
		cpu7 218543 47168 220852 49 0 8413 8098 0 0 0
		intr 1168051864 0 0 0 276005458 0 24952856 5 4 5 0 0 958 302 0 0 0 543988 116 0 1 0 92 184 0 0 0 0 0 0 0 2 0 145446 16538 11 11 358496 0 1779 0 0 0 0 0 1761 106944 0 221398 21826498 15065436 42829013 0 361294 4515 66197491 0 0 82 0 0 0 95 11438 0 0 0 0 0 0 0 0 0 0 288050 6 5498890 688446 388694 0 0 0 0 0 1674782 2042455 0 0 0 0 0 90 120387 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9 7 190 0 1434 3096 2536 13 13822 11167 0 0 485674 0 4 3244478 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9327 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 18 0 0 0 0 30003 0 0 0 1471954 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3975713 62570 292 1841582 5903677 88 1324421 35786 38 0 95 601 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 77575 30048 0 680 0 106 0 0 0 0 0 0 0 38 0 0 0 0 0 0 116 111 112 0 113 80 17256 201 0 0 0 0 0 0 0 0 1071 0 12984 5 151277 20 171 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6969 0 45 0 0 4309 20 0 10 4 0 0 0 0 618 0 0 587152 46371 1206 0 493 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
		ctxt 1941467212
		btime 1597149124
		processes 1324243
		procs_running 9
		procs_blocked 1
		softirq 268005113 132391 49905524 287215 24847758 108137456 132391 1472849 45583820 0 37505709
	ENDOFSTAT
}
###############
check_tmoe_proot_container_proc() {
	if [ ! -e "${TMOE_PROC_PATH}" ]; then
		mkdir -p ${TMOE_PROC_PATH}
	fi
	#######
	FILE_02=stat
	TMOE_PROC_FILE=$(cat /proc/${FILE_02} 2>/dev/null)
	if [ -z "${TMOE_PROC_FILE}" ]; then
		creat_tmoe_proot_stat_file
		sed -i "s@#test02@@" ${PREFIX}/bin/debian
	fi
	#######
	FILE_03='/proc/bus/pci/devices'
	TMOE_PROC_FILE=$(cat ${FILE_03} 2>/dev/null)
	if [ -z "${TMOE_PROC_FILE}" ]; then
		sed -i "s@#test04@@" ${PREFIX}/bin/debian
	fi
	######
	#不要读取kmsg
	for i in buddyinfo cgroups consoles crypto devices diskstats execdomains fb filesystems interrupts iomem ioports kallsyms keys key-users kpageflags loadavg locks misc modules pagetypeinfo partitions sched_debug softirqs timer_list uptime vmallocinfo vmstat zoneinfo; do
		TMOE_PROC_FILE=$(cat /proc/${i} 2>/dev/null)
		if [ -z "${TMOE_PROC_FILE}" ]; then
			echo "检测到您无权读取${BLUE}/proc/${i}${RESET},修复中..."
			echo "${GREEN}Fixing${RESET} ${YELLOW}/proc/${i}${RESET}..."
			sed -i "s@##${i}#@@" ${PREFIX}/bin/debian
		fi
	done
	unset i
	#######
	FILE_01=version
	TMOE_PROC_FILE=$(cat /proc/${FILE_01} 2>/dev/null)
	if [ -z "${TMOE_PROC_FILE}" ]; then
		echo "检测到您无权读取${BLUE}/proc/${FILE_01}${RESET},正在自动伪造新文件..."
		echo "你的version文件内容将被伪造成${YELLOW}$(uname -a) (gcc version 10.1.0 20200630 (prerelease) (GCC) )${RESET}"
		echo "$(uname -a) (gcc version 10.1.0 20200630 (prerelease) (GCC) )" >"${TMOE_PROC_PREFIX}.${FILE_01}"
		sed -i "s@#test01@@" ${PREFIX}/bin/debian
	fi
}
###########
check_proot_qemu() {
	if [ ! -z "${QEMU_ARCH}" ]; then
		sed -i 's@#test03@@' ${PREFIX}/bin/debian
		sed -i "s@qemu-x86_64-staic@qemu-${QEMU_ARCH}-static@" ${PREFIX}/bin/debian
	fi
}
############
creat_proot_startup_script() {
	#DEBIAN_CHROOT=~/debian-sid_arm64
	#DEBIAN_FOLDER=debian-sid_arm64
	#需要注释掉
	echo "Creating proot startup script"
	echo "正在创建proot容器启动脚本${PREFIX}/bin/debian "
	TMOE_PROC_PATH="${DEBIAN_CHROOT}/usr/local/etc/tmoe-linux/proot_proc"
	TMOE_PROC_PREFIX="${TMOE_PROC_PATH}/.tmoe-container"
	#此处ENDOFPROOT不要加单引号
	cat >${PREFIX}/bin/debian <<-ENDOFPROOT
		#!/data/data/com.termux/files/usr/bin/env bash
		get_tmoe_linux_help_info() {
		    cat <<-'ENDOFHELP'
										-i     --启动tmoe-linux manager
										-m     --更换为tuna镜像源(仅debian,ubuntu,kali,alpine和arch)
										-vnc   --启动VNC
										-n     --启动novnc
										-x     --启动x11
										-h     --get help info
									ENDOFHELP
		}
		############
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
		        startx11vnc
		        ;;
			-n | novnc*)
		        debian-i novnc
		        ;;
			-x)
				startxsdl
			;;
		    *) start_tmoe_gnu_linux_container ;;
		    esac
		}
		##############
		start_tmoe_gnu_linux_container() {
		    cd ${HOME}
			if [ -e ${DEBIAN_CHROOT}/etc/os-release ];then
				cat ${DEBIAN_CHROOT}/etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d '"' -f 2
			else
				cat ${DEBIAN_CHROOT}/etc/issue 2>/dev/null
			fi
		    #pulseaudio --kill 2>/dev/null &
		    #为加快启动速度，此处不重启音频服务
		    pulseaudio --start 2>/dev/null &
		    unset LD_PRELOAD
		    ############
		    FAKE_PROOT_PROC=true
		    TMOE_LOCALE_FILE="${CONFIG_FOLDER}/locale.txt"
		    PROC_FD_PATH="/proc/self/fd"
		    if [ -f "${DEBIAN_CHROOT}/bin/zsh" ]; then
		        TMOE_SHELL="/bin/zsh"
		    elif [ -f "${DEBIAN_CHROOT}/bin/bash" ]; then
		        TMOE_SHELL="/bin/bash"
		    elif [ -f "${DEBIAN_CHROOT}/bin/ash" ]; then
		        TMOE_SHELL="/bin/ash"
		    else
		        TMOE_SHELL="/bin/su"
		    fi
		    #考虑到alpine兼容性，此处应为-l,而非--login
		    set -- "\${TMOE_SHELL}" "-l" "\$@"
		    if [ -e "/data/data/com.termux" ]; then
		        set -- "PREFIX=/data/data/com.termux/files/usr" "\$@"
		    fi
		    if [ -e "\${TMOE_LOCALE_FILE}" ]; then
		        set -- "LANG=\$(cat \${TMOE_LOCALE_FILE} | head -n 1)" "\$@"
		    else
		        set -- "LANG=en_US.UTF-8" "\$@"
		    fi
		    set -- "/usr/bin/env" "-i" "HOME=/root" "PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games" "TMPDIR=/tmp" "TMOE_PROOT=true" "TERM=xterm-256color" "\$@"
		    set -- "--mount=/sys" "\$@"
		    set -- "--mount=/dev" "\$@"
		    set -- "--mount=${DEBIAN_CHROOT}/tmp:/dev/shm" "\$@"
		    set -- "--mount=\${PROC_FD_PATH}:/dev/fd" "\$@"
		    set -- "--mount=\${PROC_FD_PATH}/0:/dev/stdin" "\$@"
		    set -- "--mount=\${PROC_FD_PATH}/1:/dev/stdout" "\$@"
		    set -- "--mount=\${PROC_FD_PATH}/2:/dev/stderr" "\$@"
		    #勿删test注释
		    #test03set -- "--qemu=qemu-x86_64-staic" "\$@"
		    set -- "--mount=/dev/urandom:/dev/random" "\$@"
		    set -- "--mount=/proc" "\$@"
		    if [ -e "/storage/self/primary" ]; then
		        set -- "--mount=/storage/self/primary:/root/sd" "\$@"
		    elif [ -e "/sdcard" ] || [ -h "/sdcard" ]; then
		        set -- "--mount=/sdcard:/root/sd" "\$@"
		    elif [ -e "/storage/emulated/0" ]; then
		        set -- "--mount=/storage/emulated/0:/root/sd" "\$@"
		    fi
		    #######################
		    set_android_mount_dir() {
		        if [ -e "/vendor" ]; then
		            set -- "--mount=/vendor" "\$@"
		        fi
		        if [ -e "/apex" ]; then
		            #Android 10特性：APEX模块化
		            set -- "--mount=/apex" "\$@"
		        fi
		        if [ -e "/plat_property_contexts" ]; then
		            set -- "--mount=/plat_property_contexts" "\$@"
		        fi
		        if [ -e "/property_contexts" ]; then
		            set -- "--mount=/property_contexts" "\$@"
		        fi
		    }
		    #################
			#不同系统对文件权限的限制可能有所区别，以下文件在安装时会自动检测，仅当宿主机无权读取时,才会去除注释符号。
		    if [ "\${FAKE_PROOT_PROC}" = 'true' ]; then
		        #test01set -- "--mount=${TMOE_PROC_PREFIX}.stat:/proc/stat" "\$@"
		        #test02set -- "--mount=${TMOE_PROC_PREFIX}.version:/proc/version" "\$@"
		        if [ -e "${TMOE_PROC_PATH}/uptime" ]; then
					echo ""
		            #test04set -- "--mount=${TMOE_PROC_PATH}/bus:/proc/bus"  "\$@"
		            ##buddyinfo#set -- "--mount=${TMOE_PROC_PATH}/buddyinfo:/proc/buddyinfo"  "\$@"
		            ##cgroups#set -- "--mount=${TMOE_PROC_PATH}/cgroups:/proc/cgroups"  "\$@"
		            ##consoles#set -- "--mount=${TMOE_PROC_PATH}/consoles:/proc/consoles"  "\$@"
		            ##crypto#set -- "--mount=${TMOE_PROC_PATH}/crypto:/proc/crypto"  "\$@"
		            ##devices#set -- "--mount=${TMOE_PROC_PATH}/devices:/proc/devices"  "\$@"
		            ##diskstats#set -- "--mount=${TMOE_PROC_PATH}/diskstats:/proc/diskstats"  "\$@"
		            ##execdomains#set -- "--mount=${TMOE_PROC_PATH}/execdomains:/proc/execdomains"  "\$@"
		            ##fb#set -- "--mount=${TMOE_PROC_PATH}/fb:/proc/fb"  "\$@"
		            ##filesystems#set -- "--mount=${TMOE_PROC_PATH}/filesystems:/proc/filesystems"  "\$@"
		            ##interrupts#set -- "--mount=${TMOE_PROC_PATH}/interrupts:/proc/interrupts"  "\$@"
		            ##iomem#set -- "--mount=${TMOE_PROC_PATH}/iomem:/proc/iomem"  "\$@"
		            ##ioports#set -- "--mount=${TMOE_PROC_PATH}/ioports:/proc/ioports"  "\$@"
		            ##kallsyms#set -- "--mount=${TMOE_PROC_PATH}/kallsyms:/proc/kallsyms"  "\$@"
		            ##keys#set -- "--mount=${TMOE_PROC_PATH}/keys:/proc/keys"  "\$@"
		            ##key-users#set -- "--mount=${TMOE_PROC_PATH}/key-users:/proc/key-users"  "\$@"
		            ##kmsg#set -- "--mount=${TMOE_PROC_PATH}/kmsg:/proc/kmsg"  "\$@"
		            ##kpageflags#set -- "--mount=${TMOE_PROC_PATH}/kpageflags:/proc/kpageflags"  "\$@"
		            ##loadavg#set -- "--mount=${TMOE_PROC_PATH}/loadavg:/proc/loadavg"  "\$@"
		            ##locks#set -- "--mount=${TMOE_PROC_PATH}/locks:/proc/locks"  "\$@"
		            ##misc#set -- "--mount=${TMOE_PROC_PATH}/misc:/proc/misc"  "\$@"
		            ##modules#set -- "--mount=${TMOE_PROC_PATH}/modules:/proc/modules"  "\$@"
		            ##pagetypeinfo#set -- "--mount=${TMOE_PROC_PATH}/pagetypeinfo:/proc/pagetypeinfo"  "\$@"
		            ##partitions#set -- "--mount=${TMOE_PROC_PATH}/partitions:/proc/partitions"  "\$@"
		            ##sched_debug#set -- "--mount=${TMOE_PROC_PATH}/sched_debug:/proc/sched_debug"  "\$@"
		            ##softirqs#set -- "--mount=${TMOE_PROC_PATH}/softirqs:/proc/softirqs"  "\$@"
		            ##timer_list#set -- "--mount=${TMOE_PROC_PATH}/timer_list:/proc/timer_list"  "\$@"
		            ##uptime#set -- "--mount=${TMOE_PROC_PATH}/uptime:/proc/uptime"  "\$@"
		            ##vmallocinfo#set -- "--mount=${TMOE_PROC_PATH}/vmallocinfo:/proc/vmallocinfo"  "\$@"
		            ##vmstat#set -- "--mount=${TMOE_PROC_PATH}/vmstat:/proc/vmstat"  "\$@"
		            ##zoneinfo#set -- "--mount=${TMOE_PROC_PATH}/zoneinfo:/proc/zoneinfo"  "\$@"
		        fi
		    fi
		    set -- "--pwd=/root" "\$@"
		    set -- "--rootfs=${DEBIAN_CHROOT}" "\$@"
		    if [ "$(uname -o)" = 'Android' ]; then
		        #set_android_mount_dir
		        set -- "--kill-on-exit" "\$@"
		        if [ -e "/system" ]; then
		            set -- "--mount=/system" "\$@"
		        fi
		        if [ -h "${HOME}/storage/external-1" ]; then
		            set -- "--mount=${HOME}/storage/external-1:/root/tf" "\$@"
		        fi
				if [ -e "/storage" ]; then
		            set -- "--mount=/storage" "\$@"
		        fi
		        if [ -e "/data/data/com.termux/files/home" ]; then
		            set -- "--mount=/data/data/com.termux" "\$@"
		            set -- "--mount=/data/data/com.termux/files/home:/root/termux" "\$@"
		        fi
		        set -- "--link2symlink" "\$@"
		    fi
		    set -- "--root-id" "\$@"
		    set -- "proot" "\$@"
		    exec "\$@"
		}
		main "\$@"
	ENDOFPROOT
	#echo "" 空行不是多余的
}
#########
arch_mount_self() {
	CONTAINER_DISTRO=$(cat ${LINUX_CONTAINER_DISTRO_FILE} | head -n 1)
	case ${CONTAINER_DISTRO} in
	arch | manjaro)
		sed -i 's@##arch-chroot#@@g' ${PREFIX}/bin/debian
		;;
	esac
}
##########
fix_gnu_linux_chroot_exec() {
	case ${LINUX_DISTRO} in
	Android) ;;
	*)
		sed -i 's:su -c "exec $@":exec $@:' ${PREFIX}/bin/debian
		;;
	esac
}
###########
if [ -e "${CONFIG_FOLDER}/chroot_container" ]; then
	TMOE_CHROOT='true'
	creat_chroot_startup_script
	#arch_mount_self
	#fix_gnu_linux_chroot_exec
else
	creat_proot_startup_script
	check_proot_qemu
	check_tmoe_proot_container_proc
fi
#######################################################
creat_linux_container_remove_script() {
	cat >${PREFIX}/bin/debian-rm <<-EndOfFile
		    #!/data/data/com.termux/files/usr/bin/env bash
			  YELLOW=\$(printf '\033[33m')
			  RESET=\$(printf '\033[m')
		      cd ${HOME}
				   if grep -q 'TMOE_CHROOT=' ${PREFIX}/bin/debian || [ -e "${CONFIG_FOLDER}/chroot_container" ]; then
						TMOE_CHROOT='true'
						TMOE_PREFIX='sudo'
						su -c "umount -lvf ${DEBIAN_CHROOT}/* 2>/dev/null"
						su -c "umount -lvf ${DEBIAN_CHROOT}/*/*  2>/dev/null"
						su -c "umount -lvf ${DEBIAN_CHROOT}  2>/dev/null"
						su -c "ls -lAh  ${DEBIAN_CHROOT}/root/sd"
						#for i in dev proc sys root/sd tmp root/termux root/tf; do
						# if [ -e "${DEBIAN_CHROOT}/\${i}" ]; then
						#  su -c "chattr -i \${i}"
						# fi
						#done
						#unset i
					else
						TMOE_PREFIX=''
					fi
					for i in dev dev/shm dev/pts proc sys root/termux root/tf root/sd /*; do
						if [ -e "${DEBIAN_CHROOT}/\${i}" ]; then
							ls -lAh "${DEBIAN_CHROOT}\/${i}" 2>/dev/null
						fi
					done
					unset i
							cat <<-'EOF'
		              移除容器前，请先确保您已卸载容器挂载目录。
		              建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！
		              Before removing the system, make sure you have unmounted dev dev/shm dev/pts proc sys root/sd and other directories.
		              It is recommended that you backup the entire system before removal. 
					  If the data is lost due to improper operation, the developer is not responsible! 
							EOF
					##################
		  cat /proc/mounts | grep ${DEBIAN_FOLDER}
		  echo "移除容器前，请先确保您已停止容器的进程。"
		  pkill -9 proot 2>/dev/null
		  ps -e | grep proot
		  ps -e | grep startvnc
		  pgrep proot &> /dev/null
			if [ "\$?" = "0" ]; then
			    echo '检测到proot容器正在运行，请先输stopvnc或手动强制停止容器运行,亦或者是重启设备'
			fi
			##########
			ls -l ${DEBIAN_CHROOT}/root/termux/* 2>/dev/null
			if [ "\$?" = "0" ]; then
				echo 'WARNING！检测到/root/termux 无法强制卸载，您当前使用的可能是chroot容器'
				echo "若为误报，则请先停止容器进程，再手动移除${DEBIAN_CHROOT}/root/sd"
				echo '建议您在移除前进行备份，若因操作不当而导致数据丢失，开发者概不负责！！！'
			fi
			#############
			for i in root/sd root/tf proc sys; do
				if [ "$(ls ${DEBIAN_CHROOT}/\${i} 2>/dev/null)" ]; then
					echo "检测到~/${DEBIAN_FOLDER}/\${i}目录不为空，为防止该目录被清空，无法继续执行操作！"
					echo "Please restart the device to unmount the chroot directory."
					echo "Press enter to exit."
					echo "\${YELLOW}按回车键退出。\${RESET} "
					read
					exit 1
				fi
			done
			unset i
			##########
			cd ${HOME}
		    #echo '检测到chroot容器正在运行，您可以输pkill -u $(whoami) 来终止所有进程'    
		    #echo "若容器未停止运行，则建议你先手动在termux原系统中执行stopvnc，再进行移除操作。"
			echo 'Detecting debian system size... 正在检测debian system占用空间大小'
		    ${TMOE_PREFIX} du -sh ./${DEBIAN_FOLDER} --exclude=./${DEBIAN_FOLDER}/root/tf --exclude=./${DEBIAN_FOLDER}/root/sd --exclude=./${DEBIAN_FOLDER}/root/termux
			echo "Do you want to remove it?[Y/n]"
			echo "\${YELLOW}按回车键确认移除 Press enter to remove.\${RESET} "
		    pkill -9 proot 2>/dev/null
			read opt
			case \$opt in
				y*|Y*|"") 
		    chmod 777 -R ${DEBIAN_FOLDER} || sudo chmod 777 -R ${DEBIAN_FOLDER}
			rm -rfv "${DEBIAN_FOLDER}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/startx11vnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code ~/.config/tmoe-linux/across_architecture_container.txt ${PREFIX}/bin/startx11vnc "${CONFIG_FOLDER}/chroot_container" 2>/dev/null || sudo rm -rfv "${DEBIAN_FOLDER}" ${PREFIX}/bin/debian ${PREFIX}/bin/startvnc ${PREFIX}/bin/startx11vnc ${PREFIX}/bin/stopvnc ${PREFIX}/bin/startxsdl ${PREFIX}/bin/debian-rm ${PREFIX}/bin/code ~/.config/tmoe-linux/across_architecture_container.txt ${PREFIX}/bin/startx11vnc "${CONFIG_FOLDER}/chroot_container" 2>/dev/null
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
			echo "Do you need to delete the image file (${DEBIAN_NAME}*rootfs.tar.xz)?[Y/n]"

		    read opt
			case \$opt in
				y*|Y*|"") 
			rm -fv ~/\${ROOTFS_NAME}*-rootfs.tar.xz
		    echo "Deleted已删除" ;;
				n*|N*) echo "skipped." ;;
				*) echo "Invalid choice. skipped." ;;
			esac
	EndOfFile
}
########################
cat >${PREFIX}/bin/startvnc <<-ENDOFVNC
	#!/data/data/com.termux/files/usr/bin/env bash
	am start -n com.realvnc.viewer.android/com.realvnc.viewer.android.app.ConnectionChooserActivity 2>/dev/null
	if [ ! "\$(pgrep pulseaudio)" ];then
		pulseaudio --start 2>/dev/null &
	fi

	vnc_warning() {
		echo "Sorry,VNC server启动失败，请输debian-i重新配置GUI。"
		echo "Please type debian-i to start tmoe-linux tool and reconfigure GUI environment."
	}
	if [ -e "${CONFIG_FOLDER}/chroot_container" ]; then
		sudo touch ${DEBIAN_CHROOT}/root/.vnc/startvnc
		${PREFIX}/bin/debian
	elif [ -d "${DEBIAN_CHROOT}/root/.vnc" ];then
		touch ~/${DEBIAN_FOLDER}/root/.vnc/startvnc
		${PREFIX}/bin/debian
	else
		vnc_warning
	fi 
ENDOFVNC

#ln -sf ${PREFIX}/bin/startvnc ${PREFIX}/bin/startx11vnc
cat >${PREFIX}/bin/startx11vnc <<-ENDOFX11VNC
	#!/data/data/com.termux/files/usr/bin/env bash
	am start -n com.realvnc.viewer.android/com.realvnc.viewer.android.app.ConnectionChooserActivity 2>/dev/null
	if [ ! "\$(pgrep pulseaudio)" ];then
		pulseaudio --start 2>/dev/null &
	fi

	vnc_warning() {
		echo "Sorry,x11vnc server启动失败，请输debian-i重新配置GUI。"
		echo "Please type debian-i to start tmoe-linux tool and reconfigure GUI environment."
	}
	if [ -e "${CONFIG_FOLDER}/chroot_container" ]; then
		sudo touch ${DEBIAN_CHROOT}/root/.vnc/startx11vnc
		${PREFIX}/bin/debian
	elif [ -d "${DEBIAN_CHROOT}/root/.vnc" ];then
		touch ~/${DEBIAN_FOLDER}/root/.vnc/startx11vnc
		${PREFIX}/bin/debian
	else
		vnc_warning
	fi
ENDOFX11VNC
ln -s ${PREFIX}/bin/startx11vnc ${HOME}/vnc 2>/dev/null
###############
#此處僅適配Android,故shebang爲termux目錄
cat >${PREFIX}/bin/stopvnc <<-'ENDOFSTOPVNC'
	#!/data/data/com.termux/files/usr/bin/env bash
	pulseaudio --kill 2>/dev/null &
	sh -c "$(ps -e | grep -Ev "sshd|pkill|systemd" | awk '{print $4}' | sed '/(/d' | sed 's/^/pkill &/g')"
ENDOFSTOPVNC
#################
#不要单引号
cat >${PREFIX}/bin/startxsdl <<-ENDOFXSDL
	#!/data/data/com.termux/files/usr/bin/env bash
	am start -n x.org.server/x.org.server.MainActivity 2>/dev/null

	vnc_warning() {
		echo "Sorry,x11启动失败，请输debian-i重新配置GUI。"
		echo "Please type debian-i to start tmoe-linux tool and reconfigure GUI environment."
	}
	if [ -e "${CONFIG_FOLDER}/chroot_container" ]; then
		sudo touch ${DEBIAN_CHROOT}/root/.vnc/startxsdl
		${PREFIX}/bin/debian
	elif [ -d "${DEBIAN_CHROOT}/root/.vnc" ];then
		touch ~/${DEBIAN_FOLDER}/root/.vnc/startxsdl
		${PREFIX}/bin/debian
	else
		vnc_warning
	fi
ENDOFXSDL
creat_linux_container_remove_script
################
#wget -qO ${PREFIX}/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/debian.sh'
aria2c --allow-overwrite=true -d ${PREFIX}/bin -o debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh'
#############
if [ ! -L '/data/data/com.termux/files/home/storage/external-1' ]; then
	sed -i 's@^command+=" --mount=/data/data/com.termux/files/home/storage/external-1@#&@g' ${PREFIX}/bin/debian 2>/dev/null
	#sed -i 's@^mount -o bind /mnt/media_rw/@#&@g' ${PREFIX}/bin/debian 2>/dev/null
fi
echo 'Giving startup script execution permission'
echo "正在赋予启动脚本(${PREFIX}/bin/debian)执行权限"
#termux-fix-shebang ${PREFIX}/bin/debian
cd ${PREFIX}/bin

chmod +x debian startvnc stopvnc debian-rm debian-i startxsdl startx11vnc 2>/dev/null
#设定alias,防止debian-root的alias依旧在生效。
alias debian="${PREFIX}/bin/debian"
alias debian-rm="${PREFIX}/bin/debian-rm"
################
echo "You can type rm ~/${TMOE_ROOTFS_TAR_XZ} to delete the image file"
echo "您可以输${RED}rm ~/${TMOE_ROOTFS_TAR_XZ}${RESET}来删除容器镜像文件"
ls -lh ~/${TMOE_ROOTFS_TAR_XZ}
########################
if [ ! -d "${DEBIAN_CHROOT}/usr/local/bin" ]; then
	${TMOE_CHROOT_PREFIX} mkdir -p ${DEBIAN_CHROOT}/usr/local/bin
fi

#cd ${DEBIAN_CHROOT}/usr/local/bin
cd ${CONFIG_FOLDER}
if [ ! -e "neofetch" ]; then
	curl -Lo "neofetch" 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch'
fi
if [ ! -e "debian-i" ]; then
	curl -Lo "debian-i" 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
fi
chmod +x neofetch debian-i
${TMOE_CHROOT_PREFIX} cp neofetch debian-i ${DEBIAN_CHROOT}/usr/local/bin

${TMOE_CHROOT_PREFIX} chmod u+w "${DEBIAN_CHROOT}/root"

curl -sLo zsh-i.sh 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh'
sed -i 's:#!/data/data/com.termux/files/usr/bin/env bash:#!/usr/bin/env bash:' zsh-i.sh
curl -Lo zsh.sh 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/zsh.sh'
chmod +x zsh.sh zsh-i.sh
${TMOE_CHROOT_PREFIX} cp zsh-i.sh zsh.sh ${DEBIAN_CHROOT}/root
#chmod u+x ./*
###########
debian_stable_sources_list_and_gpg_key() {
	curl -Lo "raspbian-sources-gpg.tar.xz" 'https://gitee.com/mo2/patch/raw/raspbian/raspbian-sources-gpg.tar.xz'
	tar -Jxvf "raspbian-sources-gpg.tar.xz" -C ~/${DEBIAN_FOLDER}/etc/apt/
	rm -f "raspbian-sources-gpg.tar.xz"
}
############
#if [ -f "${HOME}/.RASPBIANARMHFDetectionFILE" ]; then
#	mv -f "${HOME}/.RASPBIANARMHFDetectionFILE" "${DEBIAN_CHROOT}/tmp/"
#树莓派换源
#debian_stable_sources_list_and_gpg_key
#if [ -f "${HOME}/.REDHATDetectionFILE" ]; then
#rm -f "${HOME}/.REDHATDetectionFILE"
#chmod u+w "${DEBIAN_CHROOT}/root"
if [ -f "${HOME}/.ALPINELINUXDetectionFILE" ]; then
	${TMOE_CHROOT_PREFIX} mv -f "${HOME}/.ALPINELINUXDetectionFILE" ${DEBIAN_CHROOT}/tmp
elif [ -f "${HOME}/.MANJARO_ARM_DETECTION_FILE" ]; then
	rm -f ${HOME}/.MANJARO_ARM_DETECTION_FILE
	${TMOE_CHROOT_PREFIX} sed -i 's@^#SigLevel.*@SigLevel = Never@' "${DEBIAN_CHROOT}/etc/pacman.conf"
fi
########
TMOE_LOCALE_FILE="${CONFIG_FOLDER}/locale.txt"
if [ -f "${TMOE_LOCALE_FILE}" ]; then
	TMOE_LOCALE_NEW_PATH="${DEBIAN_CHROOT}/usr/local/etc/tmoe-linux"
	${TMOE_CHROOT_PREFIX} mkdir -p ${TMOE_LOCALE_NEW_PATH}
	${TMOE_CHROOT_PREFIX} cp -f ${TMOE_LOCALE_FILE} ${TMOE_LOCALE_NEW_PATH}
	TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
	PROOT_LANG=$(cat $(command -v debian) | grep LANG= | cut -d '"' -f 2 | cut -d '=' -f 2 | tail -n 1)
	sed -i "s@${PROOT_LANG}@${TMOE_LANG}@" $(command -v debian)
fi
########################
#cd ${DEBIAN_CHROOT}/root
#无权限进入chroot容器的root目录
case ${TMOE_CHROOT} in
true)
	cd ${CONFIG_FOLDER}
	;;
*)
	cd ${DEBIAN_CHROOT}/root
	############
	if [ -f ".bash_profile" ] || [ -f ".bash_login" ]; then
		mv -f .bash_profile .bash_profile.bak 2>/dev/null
		mv -f .bash_login .bash_login.bak 2>/dev/null
	fi
	if [ ! -f ".profile" ]; then
		echo '' >>.profile
	else
		mv -f .profile .profile.bak
	fi
	;;
esac
#############
##################
#vnc自动启动
cat >vnc-autostartup <<-'EndOfFile'
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
	############
	check_tmoe_locale_file() {
		TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
		if [ -e "${TMOE_LOCALE_FILE}" ]; then
			TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
			TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
			TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
			locale_gen_tmoe_language
		fi
	}
	#############
	vnc_warning() {
		echo "Sorry,VNC server启动失败，请输debian-i重新安装并配置桌面环境。"
		echo "Please type debian-i to start tmoe-linux tool and reconfigure desktop environment."
	}
	###########
	LOCAL_BIN_DIR='/usr/local/bin'
	if [ -e "${HOME}/.vnc/xstartup" ] && [ ! -e "${HOME}/.vnc/passwd" ]; then
		check_tmoe_locale_file
		cd /usr/local/etc/tmoe-linux/git
		git fetch --depth=1
		git reset --hard origin/master
		git pull origin master --allow-unrelated-histories
		curl -Lv -o ${LOCAL_BIN_DIR}/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		chmod +x ${LOCAL_BIN_DIR}/debian-i
		${LOCAL_BIN_DIR}/debian-i passwd
	fi
	#########
	notes_of_android_xsdl() {
	    cat <<-'ENDOFSTARTXSDL'
		检测到您在termux原系统中输入了startxsdl，已为您打开xsdl安卓app
		Detected that you entered "startxsdl" from the termux original system, and the xsdl Android application has been opened.
		9s后将为您启动xsdl
		xsdl will start in 9 seconds
	ENDOFSTARTXSDL
	    sleep 9
	}
	#########
	CURRENT_TMOE_DIR=$(pwd)
	cd ${HOME}/.vnc 2>/dev/null
	case "$?" in
	0)
	    for i in startvnc startx11vnc startxsdl; do
	        if [ -f ${i} ]; then
	            rm ${i}
	            case ${i} in
	            startxsdl)
	                notes_of_android_xsdl
	                ;;
	            esac
	            if [ -f ${LOCAL_BIN_DIR}/${i} ]; then
					cd ${HOME}
	                ${LOCAL_BIN_DIR}/${i}
					echo "已为您启动vnc服务 Vnc server has been started, enjoy it ！"
	            else
	                vnc_warning
	            fi
	        fi
	    done
	    unset i
	    ;;
	esac
	##########
	case ${CURRENT_TMOE_DIR} in
	/) cd ${HOME};;
	*) cd ${CURRENT_TMOE_DIR} ;;
	esac
	###########
	ps -e 2>/dev/null | grep -Ev 'bash|zsh' | tail -n 20
	############
		case ${TMOE_CHROOT} in
	    true)
	        rm -f /run/dbus/pid 2>/dev/null
	        dbus-daemon --system --fork 2>/dev/null
	        ;;
		esac
	############
	systemctl(){
	    case $2 in
	        "") systemctl $1 ;;
	        *) 
	            if [ -e "/usr/sbin/service" ]; then
	                /usr/sbin/service $2 $1
	            elif [ -e "/sbin/service" ]; then
	                /sbin/service $2 $1
	            else
	                systemctl $1 $2
	            fi
	             ;;
	    esac
	}
	[ -e ~/.profile ] && . ~/.profile
EndOfFile
#curl -Lo '.profile' 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/profile.sh'
#chmod u+x .profile
#不要将profile转换为外部脚本，否则将影响sed
cat >'.profile' <<-'ENDOFbashPROFILE'
	YELLOW=$(printf '\033[33m')
	RESET=$(printf '\033[m')
	cd ${HOME}
	###############
	# sed -i '1 r ~/vnc-autostartup' ~/.bash_login
	cp -f vnc-autostartup .bash_login
	if [ -e "/etc/hostname" ]; then
		NEW_HOST_NAME=$(cat /etc/hostname | head -n 1)
		hostname ${NEW_HOST_NAME} 2>/dev/null
		sed -i "1s@LXC_NAME@${NEW_HOST_NAME}@" /etc/hosts 2>/dev/null
	fi
	if [ "${TMOE_CHROOT}" = 'true' ]; then
		groupadd aid_system -g 1000 || groupadd aid_system -g 1074
		groupadd aid_radio -g 1001
		groupadd aid_bluetooth -g 1002
		groupadd aid_graphics -g 1003
		groupadd aid_input -g 1004
		groupadd aid_audio -g 1005
		groupadd aid_camera -g 1006
		groupadd aid_log -g 1007
		groupadd aid_compass -g 1008
		groupadd aid_mount -g 1009
		groupadd aid_wifi -g 1010
		groupadd aid_adb -g 1011
		groupadd aid_install -g 1012
		groupadd aid_media -g 1013
		groupadd aid_dhcp -g 1014
		groupadd aid_sdcard_rw -g 1015
		groupadd aid_vpn -g 1016
		groupadd aid_keystore -g 1017
		groupadd aid_usb -g 1018
		groupadd aid_drm -g 1019
		groupadd aid_mdnsr -g 1020
		groupadd aid_gps -g 1021
		groupadd aid_media_rw -g 1023
		groupadd aid_mtp -g 1024
		groupadd aid_drmrpc -g 1026
		groupadd aid_nfc -g 1027
		groupadd aid_sdcard_r -g 1028
		groupadd aid_clat -g 1029
		groupadd aid_loop_radio -g 1030
		groupadd aid_media_drm -g 1031
		groupadd aid_package_info -g 1032
		groupadd aid_sdcard_pics -g 1033
		groupadd aid_sdcard_av -g 1034
		groupadd aid_sdcard_all -g 1035
		groupadd aid_logd -g 1036
		groupadd aid_shared_relro -g 1037
		groupadd aid_dbus -g 1038
		groupadd aid_tlsdate -g 1039
		groupadd aid_media_ex -g 1040
		groupadd aid_audioserver -g 1041
		groupadd aid_metrics_coll -g 1042
		groupadd aid_metricsd -g 1043
		groupadd aid_webserv -g 1044
		groupadd aid_debuggerd -g 1045
		groupadd aid_media_codec -g 1046
		groupadd aid_cameraserver -g 1047
		groupadd aid_firewall -g 1048
		groupadd aid_trunks -g 1049
		groupadd aid_nvram -g 1050
		groupadd aid_dns -g 1051
		groupadd aid_dns_tether -g 1052
		groupadd aid_webview_zygote -g 1053
		groupadd aid_vehicle_network -g 1054
		groupadd aid_media_audio -g 1055
		groupadd aid_media_video -g 1056
		groupadd aid_media_image -g 1057
		groupadd aid_tombstoned -g 1058
		groupadd aid_media_obb -g 1059
		groupadd aid_ese -g 1060
		groupadd aid_ota_update -g 1061
		groupadd aid_automotive_evs -g 1062
		groupadd aid_lowpan -g 1063
		groupadd aid_hsm -g 1064
		groupadd aid_reserved_disk -g 1065
		groupadd aid_statsd -g 1066
		groupadd aid_incidentd -g 1067
		groupadd aid_secure_element -g 1068
		groupadd aid_lmkd -g 1069
		groupadd aid_llkd -g 1070
		groupadd aid_iorapd -g 1071
		groupadd aid_gpu_service -g 1072
		groupadd aid_network_stack -g 1073
		groupadd aid_shell -g 2000
		groupadd aid_cache -g 2001
		groupadd aid_diag -g 2002
		groupadd aid_oem_reserved_start -g 2900
		groupadd aid_oem_reserved_end -g 2999
		groupadd aid_net_bt_admin -g 3001
		groupadd aid_net_bt -g 3002
		groupadd aid_inet -g 3003
		groupadd aid_net_raw -g 3004
		groupadd aid_net_admin -g 3005
		groupadd aid_net_bw_stats -g 3006
		groupadd aid_net_bw_acct -g 3007
		groupadd aid_readproc -g 3009
		groupadd aid_wakelock -g 3010
		groupadd aid_uhid -g 3011
		groupadd aid_everybody -g 9997
		groupadd aid_misc -g 9998
		groupadd aid_nobody -g 9999
		groupadd aid_app_start -g 10000
		groupadd aid_app_end -g 19999
		groupadd aid_cache_gid_start -g 20000
		groupadd aid_cache_gid_end -g 29999
		groupadd aid_ext_gid_start -g 30000
		groupadd aid_ext_gid_end -g 39999
		groupadd aid_ext_cache_gid_start -g 40000
		groupadd aid_ext_cache_gid_end -g 49999
		groupadd aid_shared_gid_start -g 50000
		groupadd aid_shared_gid_end -g 59999
		#groupadd aid_overflowuid -g 65534
		groupadd aid_overflowuid -g 65535
		groupadd aid_isolated_start -g 99000
		groupadd aid_isolated_end -g 99999
		groupadd aid_user_offset -g 100000
		#groupadd -g 3001 aid_bt
		#groupadd -g 3002 aid_bt_net
		#groupadd -g 3003 aid_inet
		#groupadd -g 3004 aid_net_raw
		#groupadd -g 3005 aid_admin
		#usermod -a -G aid_bt,aid_bt_net,aid_inet,aid_net_raw,aid_admin root
		usermod -a -G aid_system,aid_radio,aid_bluetooth,aid_graphics,aid_input,aid_audio,aid_camera,aid_log,aid_compass,aid_mount,aid_wifi,aid_adb,aid_install,aid_media,aid_dhcp,aid_sdcard_rw,aid_vpn,aid_keystore,aid_usb,aid_drm,aid_mdnsr,aid_gps,aid_media_rw,aid_mtp,aid_drmrpc,aid_nfc,aid_sdcard_r,aid_clat,aid_loop_radio,aid_media_drm,aid_package_info,aid_sdcard_pics,aid_sdcard_av,aid_sdcard_all,aid_logd,aid_shared_relro,aid_dbus,aid_tlsdate,aid_media_ex,aid_audioserver,aid_metrics_coll,aid_metricsd,aid_webserv,aid_debuggerd,aid_media_codec,aid_cameraserver,aid_firewall,aid_trunks,aid_nvram,aid_dns,aid_dns_tether,aid_webview_zygote,aid_vehicle_network,aid_media_audio,aid_media_video,aid_media_image,aid_tombstoned,aid_media_obb,aid_ese,aid_ota_update,aid_automotive_evs,aid_lowpan,aid_hsm,aid_reserved_disk,aid_statsd,aid_incidentd,aid_secure_element,aid_lmkd,aid_llkd,aid_iorapd,aid_gpu_service,aid_network_stack,aid_shell,aid_cache,aid_diag,aid_oem_reserved_start,aid_oem_reserved_end,aid_net_bt_admin,aid_net_bt,aid_inet,aid_net_raw,aid_net_admin,aid_net_bw_stats,aid_net_bw_acct,aid_readproc,aid_wakelock,aid_uhid,aid_everybody,aid_misc,aid_nobody,aid_app_start,aid_app_end,aid_cache_gid_start,aid_cache_gid_end,aid_ext_gid_start,aid_ext_gid_end,aid_ext_cache_gid_start,aid_ext_cache_gid_end,aid_shared_gid_start,aid_shared_gid_end,aid_overflowuid,aid_isolated_start,aid_isolated_end,aid_user_offset root
		usermod -g aid_inet _apt 2>/dev/null
		usermod -a -G aid_inet,aid_net_raw portage 2>/dev/null
	fi
	#函数放在前面
	debian_sources_list() {
	    sed -i 's/^deb/##&/g' /etc/apt/sources.list
	    #stable-backports会出错，需改为buster-backports
	    cat >>/etc/apt/sources.list <<-'EndOfFile'
				#deb http://mirrors.huaweicloud.com/debian/ stable main contrib non-free
				#deb http://mirrors.huaweicloud.com/debian/ stable-updates main contrib non-free
				#deb http://mirrors.huaweicloud.com/debian/ buster-backports main contrib non-free
				#deb http://mirrors.huaweicloud.com/debian-security/ stable/updates main contrib non-free
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
		touch /home/ubuntu/.hushlogin 2>/dev/null
	    if grep -q 'Bionic Beaver' "/etc/os-release"; then
	        sed -i 's/focal/bionic/g' /etc/apt/sources.list
	    fi
	}
	#########################
	mint_sources_list() {
	    echo "检测到您使用的是Linux Mint"
		CHINA_MIRROR='mirrors.huaweicloud.com'
		SOURCE_LIST=/etc/apt/sources.list
		cp ${SOURCE_LIST} ${SOURCE_LIST}.bak 2>/dev/null
		sed -i 's@^@#&@g' ${SOURCE_LIST}.bak 2>/dev/null
		sed -i "s@packages.linuxmint.com@${CHINA_MIRROR}/linuxmint@g" ${SOURCE_LIST} 2>/dev/null
		sed -i "s@archive.ubuntu.com@${CHINA_MIRROR}@g" ${SOURCE_LIST} 2>/dev/null
		cat ${SOURCE_LIST}.bak >>${SOURCE_LIST} 2>/dev/null
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
	if [ ! -e /etc/apt/sources.list.d/raspi.list ]; then
		if grep -q 'Debian' "/etc/issue"; then
	     debian_sources_list
			case $(uname -m) in
			arm*|mips*) sed -i 's@163.com@huaweicloud.com@g' /etc/apt/sources.list ;;
			esac
		fi
	fi
	###############
	TUNA_MIRROR_URL='mirrors.tuna.tsinghua.edu.cn'
	if [ -e /etc/apt/sources.list.d/armbian.list ]; then
			case $(uname -m) in
				aarch64) dpkg  --remove-architecture armhf ;;
			esac 
		cd /etc/apt/sources.list.d
		cp armbian.list armbian.list.bak
		sed -i 's/^/#&/g' armbian.list.bak
		sed -i 's@apt.armbian.com@mirrors.tuna.tsinghua.edu.cn/armbian@g' armbian.list
		#sed -i '$ a\deb http://mirrors.tuna.tsinghua.edu.cn/armbian/ bullseye main bullseye-utils bullseye-desktop' /etc/apt/sources.list.d/armbian.list
		cat armbian.list.bak >>armbian.list
		rm -f armbian.list.bak
		cd ~
	elif [ -e /etc/apt/sources.list.d/raspi.list ]; then
		cd /etc/apt/sources.list.d
		cp raspi.list raspi.list.bak
		sed -i 's/^/#&/g' raspi.list.bak
		#http://archive.raspberrypi.org/debian/ buster main
		#deb http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main non-free contrib rpi
		#mirrors.tuna.tsinghua.edu.cn/raspberrypi/

		sed -i "s@archive.raspberrypi.org/debian@${TUNA_MIRROR_URL}/raspberrypi@g" raspi.list
		cat raspi.list.bak >>raspi.list
		rm -f raspi.list.bak
		cd ..
		cp sources.list sources.list.bak
		sed -i "s@raspbian.raspberrypi.org/raspbian@${TUNA_MIRROR_URL}/raspbian/raspbian@g" sources.list
		sed -i 's/^/#&/g' sources.list.bak
		cat sources.list.bak >> sources.list
		cd ~
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
	    pacman -S --noconfirm diffutils iproute gawk
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
	    rm -f ~/.profile vnc-autostartup
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
	TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
	if [ -e "${TMOE_LOCALE_FILE}" ]; then
		TMOE_LANG=$(cat ${TMOE_LOCALE_FILE} | head -n 1)
	else
		TMOE_LANG="en_US.UTF-8"
	fi
	TMOE_LANG_HALF=$(echo ${TMOE_LANG} | cut -d '.' -f 1)
	TMOE_LANG_QUATER=$(echo ${TMOE_LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
	############################
	opensuse_linux_repo() {
	    LINUX_DISTRO='suse'
		if [ "$(uname -m)" = 'aarch64' ];then
			zypper mr -da
	        zypper addrepo -fcg  https://mirrors.tuna.tsinghua.edu.cn/opensuse/ports/aarch64/tumbleweed/repo/oss tuna-mirror-oss
	        zypper --gpg-auto-import-keys refresh
		elif [ "$(uname -m)" != 'armv7l' ] ;then
	        zypper mr -da
	        zypper addrepo -fcg https://mirrors.tuna.tsinghua.edu.cn/opensuse/tumbleweed/repo/oss/ tuna-mirror-oss
	        zypper addrepo -fcg https://mirrors.tuna.tsinghua.edu.cn/opensuse/tumbleweed/repo/non-oss/ tuna-mirror-non-oss
	        zypper addrepo -fcg https://mirrors.tuna.tsinghua.edu.cn/packman/suse/openSUSE_Tumbleweed/ tuna-mirror_Tumbleweed
	        zypper --gpg-auto-import-keys refresh
	        #zypper dup --no-allow-vendor-change -y
		fi
	    zypper in -y wget curl
	    sed -i "s@RC_LANG=.*@RC_LANG=${TMOE_LANG}@" /etc/sysconfig/language
	    sed -i "s@RC_LC_ALL=.*@RC_LC_ALL=${TMOE_LANG}@" /etc/sysconfig/language
	    sed -i "s@INSTALLED_LANGUAGES=@INSTALLED_LANGUAGES=${TMOE_LANG_HALF}@" /etc/sysconfig/language
	    zypper in -y glibc-locale glibc-i18ndata 
		zypper in -y translation-update-${TMOE_LANG_HALF}
	}
	################################
	if [ -f "/tmp/.ALPINELINUXDetectionFILE" ]; then
	    alpine_linux_configure
	elif grep -q 'openSUSE' "/etc/os-release"; then
	    opensuse_linux_repo
	fi
	##############################
	apt update 2>/dev/null
	#apt reinstall -y perl-base
	if [ ! -e /usr/lib/locale/en_US ];then
		apt install -y locales-all 2>/dev/null
	fi 
	if [ ! $(command -v locale-gen) ]; then
	    apt install -y locales 2>/dev/null
	fi

	if grep -q 'ubuntu' /etc/os-release; then
	   apt install -y ^language-pack-${TMOE_LANG_QUATER} 2>/dev/null
	fi

	echo "您已成功安装GNU/Linux,之后可以输${YELLOW}debian${RESET}来进入debian system."
	echo "Congratulations on your successful installation of GNU/Linux container. After that, you can type debian in termux to enter the container. "
	echo '正在执行优化步骤，请勿退出!'
	echo 'Optimization steps are in progress. Do not exit!'

	#配置时区
	echo 'Asia/Shanghai' >/etc/timezone
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	sed -i 's/^/#&/g' /etc/default/locale 2>/dev/null
	sed -i 's/##/#/g' /etc/default/locale 2>/dev/null
	if [ ! -e "/usr/local/etc/tmoe-linux/locale.txt" ]; then
	    echo "Tmoe-locale file not detected."
	fi
	echo "Configuring ${TMOE_LANG_HALF} environment..."
	sed -i "s/^#.*${TMOE_LANG} UTF-8/${TMOE_LANG} UTF-8/" /etc/locale.gen 2>/dev/null
	cat >>/etc/default/locale <<-EOF
			LANG=${TMOE_LANG}
			LANGUAGE=${TMOE_LANG_HALF}:${TMOE_LANG_QUATER}
			LC_ALL=${TMOE_LANG}
		EOF
	if ! grep -q "^${TMOE_LANG_HALF}" "/etc/locale.gen" 2>/dev/null; then
	    sed -i 's@^@#@g' /etc/locale.gen 2>/dev/null
	    sed -i 's@##@#@g' /etc/locale.gen 2>/dev/null
	    echo '' >>/etc/locale.gen
	    sed -i "$ a${TMOE_LANG} UTF-8" /etc/locale.gen
	fi
	locale-gen ${TMOE_LANG} 2>/dev/null
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
	if [ ! -e /etc/apt/sources.list.d/raspi.list ]; then
	    echo "Replacing http software source list with https."
	    echo "正在将http源替换为https..."
	    sed -i 's@http:@https:@g' /etc/apt/sources.list 2>/dev/null
	    sed -i 's@https://security@http://security@g' /etc/apt/sources.list 2>/dev/null
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
		if grep -q 'Funtoo' /etc/os-release;then
		   #同步过于耗时
	       emerge --sync
		   emerge emerge-webrsync
		fi 
	    emerge-webrsync
	    emerge --config sys-libs/timezone-data 2>/dev/null
	    #eselect profile list
	    GENTOOnosystemdStable="$(eselect profile list | grep -Ev 'desktop|hardened|developer|systemd|selinux|multilib' | grep stable | tail -n 1 | cut -d '[' -f 2 | cut -d ']' -f 1)"
	    eselect profile set "${GENTOOnosystemdStable}"
	    etc-update --automode -3
	    etc-update
	    #dispatch-conf
	    emerge -uvDN --with-bdeps=y @world
		emerge -avk sys-devel/binutils
	    emerge eix 2>/dev/null
	    echo '检测到您当前的系统为Gentoo GNU/Linux,将不会为您继续配置任何优化步骤！'
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
	    #sed -i '1 c\#!/usr/bin/env bash' zsh.sh
	    #chmod +x zsh.sh
	    echo '检测到您当前的系统为Void GNU/Linux,若配置出错，则请手动输debian-i'
		xbps-reconfigure -f glibc-locales
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
	apt update 2>/dev/null
	apt list --upgradable 2>/dev/null
	echo "正在升级所有软件包..."
	apt dist-upgrade -y 2>/dev/null
	apt install -y procps 2>/dev/null
	apt clean 2>/dev/null
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
	####################
	if [ ! "$(command -v lolcat)" ];then
		apt install -y lolcat 2>/dev/null || pacman -S --noconfirm lolcat 2>/dev/null || dnf install -y lolcat 2>/dev/null || apk add lolcat 2>/dev/null
	fi
	echo "Automatically configure zsh after 2 seconds,you can press Ctrl + C to cancel."
	echo "2s后将自动开始配置zsh，您可以按Ctrl+C取消，这将不会继续配置其它步骤，同时也不会启动Tmoe-linux工具。"
	#wget -qcO /usr/local/bin/neofetch 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch' || curl -sLo /usr/local/bin/neofetch 'https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch'
	chmod +x /usr/local/bin/neofetch
	if [ -e /usr/games/lolcat ]; then
		neofetch | /usr/games/lolcat
	elif [ "$(command -v lolcat)" ]; then
		neofetch | lolcat
	else
		neofetch
	fi
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
	fix_gnu_libxcb_debian(){
	GNU_LIBXCB="/usr/lib/$(uname -m)-linux-gnu/libxcb.so.1"
	if [ -e "${GNU_LIBXCB}" ]; then
		TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
	    mkdir -p ${TMOE_LINUX_DIR}
		cp ${GNU_LIBXCB} ${TMOE_LINUX_DIR}
	    sed -i 's@BIG-REQUESTS@_IG-REQUESTS@g' ${GNU_LIBXCB}
	fi
	}    
	####################
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
		TMOE_LANG_HALF=$(echo $LANG | cut -d '.' -f 1 |cut -d '_' -f 1)
		dnf install -y "glibc-langpack-${TMOE_LANG_HALF}*"
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
	    #echo "检测到您使用的不是deb系linux，优化步骤可能会出现错误"
	    echo "在脚本执行完成后，您可以手动输./zsh-i.sh来配置zsh，输 ${YELLOW}debian-i${RESET}打开软件安装工具"
	    bash zsh.sh
	    debian-i
	    #bash zsh-i.sh
	    #bash -c "$(curl -LfsS 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh')" || bash -c "$(wget -qO- 'https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh')"
	}
	################
	if ! grep -Eq 'debian|ubuntu' '/etc/os-release'; then
	    note_of_non_debian
	else
		fix_gnu_libxcb_debian
	    bash zsh.sh
	fi
ENDOFbashPROFILE
#####################
case ${TMOE_CHROOT} in
true)
	${TMOE_CHROOT_PREFIX} rm -f ${DEBIAN_CHROOT}/root/.bash_profile ${DEBIAN_CHROOT}/root/.bash_login
	${TMOE_CHROOT_PREFIX} mv ${DEBIAN_CHROOT}/root/.profile ${DEBIAN_CHROOT}/root/.profile.bak 2>/dev/null
	${TMOE_CHROOT_PREFIX} cp vnc-autostartup .profile ${DEBIAN_CHROOT}/root
	;;
esac
#sed -i '1 r vnc-autostartup' ./.bash_login
#####################
check_current_user_name_and_group() {
	CURRENT_USER_NAME=$(cat /etc/passwd | grep "${HOME}" | awk -F ':' '{print $1}')
	CURRENT_USER_GROUP=$(cat /etc/passwd | grep "${HOME}" | awk -F ':' '{print $5}' | cut -d ',' -f 1)
	if [ -z "${CURRENT_USER_GROUP}" ]; then
		CURRENT_USER_GROUP=${CURRENT_USER_NAME}
	fi
}
#################
if [ "${LINUX_DISTRO}" != 'Android' ]; then
	sed -i 's:#!/data/data/com.termux/files/usr/bin/env bash:#!/usr/bin/env bash:g' $(grep -rl 'com.termux' "${PREFIX}/bin")
	#sed -i 's:#!/data/data/com.termux/files/usr/bin/env bash:#!/usr/bin/env bash:' ${DEBIAN_CHROOT}/remove-debian.sh
fi
case ${TMOE_CHROOT} in
true) ;;
#su -c "chown -Rv root:root ${DEBIAN_CHROOT}"
*)
	case ${LINUX_DISTRO} in
	Android) ;;
	*)
		check_current_user_name_and_group
		case ${HOME} in
		/root) ;;
		*)
			chown -Rv ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${DEBIAN_CHROOT}
			su - ${CURRENT_USER_NAME} -c "bash ${PREFIX}/bin/debian"
			exit 0
			;;
		esac
		;;
	esac
	;;
esac
bash ${PREFIX}/bin/debian
