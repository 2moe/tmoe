#!/usr/bin/env bash
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

elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
    LINUX_DISTRO='arch'

elif grep -qi 'Void' '/etc/issue'; then
    LINUX_DISTRO='void'

elif grep -qi 'suse' '/etc/os-release'; then
    LINUX_DISTRO='suse'

elif grep -Eq "gentoo|funtoo" '/etc/os-release'; then
    LINUX_DISTRO='gentoo'

elif grep -Eq "Slackware" '/etc/os-release'; then
    LINUX_DISTRO='slackware'
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

if [ ! $(command -v fzf) ]; then
    if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "alpine" ] || [ "${REDHAT_DISTRO}" = "fedora" ] || [ "${LINUX_DISTRO}" = "arch" ]; then
        DEPENDENCIES="${DEPENDENCIES} fzf"
    fi
fi
###########################################
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
if [ ! $(command -v sudo) ]; then
    case "${LINUX_DISTRO}" in
    gentoo) DEPENDENCIES="${DEPENDENCIES} app-admin/sudo" ;;
    *) DEPENDENCIES="${DEPENDENCIES} sudo" ;;
    esac
fi
#######################
if [ ! $(command -v tar) ]; then
    case "${LINUX_DISTRO}" in
    gentoo) ;;
    *) DEPENDENCIES="${DEPENDENCIES} tar" ;;
    esac
fi
################
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
    echo "正在安装相关软件包及其依赖..."

    if [ "${LINUX_DISTRO}" = "debian" ]; then
        apt update
        apt install -y ${DEPENDENCIES} || apt install -y command-not-found zsh git wget whiptail

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

    elif [ "${LINUX_DISTRO}" = "suse" ]; then
        zypper in -y ${DEPENDENCIES}

    elif [ "${LINUX_DISTRO}" = "slackware" ]; then
        slackpkg install ${DEPENDENCIES}

    else
        apt update
        apt install -y command-not-found zsh git wget whiptail command-not-found || port install ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES}
    fi
fi
###############################
if [ -e /etc/apt/sources.list.d/armbian.list ]; then
    if grep -q 'Focal' /etc/os-release; then
        #此处不该用reinstall
        apt purge -y man-db
        apt install -y man-db
    fi
fi
############
if [ ! $(command -v debian-i) ]; then
    if [ -e "/usr/bin/curl" ]; then
        curl -Lo /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
    else
        wget -qO /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
    fi
fi
chmod 777 /usr/local/bin/debian-i
#########################
mkdir -p /run/dbus
##############
git_clone_oh_my_zsh() {
    ZSH_BAK_FILE='/tmp/zsh_bak.tar.gz'
    if [ -e "${ZSH_BAK_FILE}" ]; then
        tar -pzxvf ${ZSH_BAK_FILE} -C /
        rm -f ${ZSH_BAK_FILE}
    fi
    OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
    echo "github.com/ohmyzsh/ohmyzsh"
    if [ -e "${OH_MY_ZSH_DIR}/.git" ]; then
        cd ${OH_MY_ZSH_DIR}
        git reset --hard
        git pull --depth=1 --allow-unrelated-histories
    else
        rm -rf ${OH_MY_ZSH_DIR} 2>/dev/null
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ${HOME}/.oh-my-zsh || git clone --depth=1 git://github.com/ohmyzsh/ohmyzsh.git ${HOME}/.oh-my-zsh
    fi
    #chmod 755 -R "${HOME}/.oh-my-zsh"
    if [ ! -f "${HOME}/.zshrc" ]; then
        cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc" || curl -Lo "${HOME}/.zshrc" 'https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/templates/zshrc.zsh-template'
        #https://github.com/ohmyzsh/ohmyzsh/raw/master/templates/zshrc.zsh-template
    fi
}
######################
ps -e &>/dev/null
if [ "$?" != '0' ]; then
    TERMUX_BIN_PATH='/data/data/com.termux/files/usr/bin/'
    if [ -e "${TERMUX_BIN_PATH}/ps" ]; then
        ln -s ${TERMUX_BIN_PATH}/ps /usr/local/bin/ps 2>/dev/null
        ln -s ${TERMUX_BIN_PATH}/pstree /usr/local/bin/pstree 2>/dev/null
    fi
fi
###########
git_clone_oh_my_zsh
###########
if [ $(command -v chsh) ]; then
    chsh -s /usr/bin/zsh || chsh -s /bin/zsh
fi
RB_RED=$(printf '\033[38;5;196m')
RB_ORANGE=$(printf '\033[38;5;202m')
RB_YELLOW=$(printf '\033[38;5;226m')
RB_GREEN=$(printf '\033[38;5;082m')
RB_BLUE=$(printf '\033[38;5;021m')
RB_INDIGO=$(printf '\033[38;5;093m')
RB_VIOLET=$(printf '\033[38;5;163m')

RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
BLUE=$(printf '\033[34m')
BOLD=$(printf '\033[1m')
RESET=$(printf '\033[m')
printf '%s         %s__      %s           %s        %s       %s     %s__   %s\n' ${RB_RED} ${RB_ORANGE} ${RB_YELLOW} ${RB_GREEN} ${RB_BLUE} ${RB_INDIGO} ${RB_VIOLET} ${RB_RESET}
printf '%s  ____  %s/ /_    %s ____ ___  %s__  __  %s ____  %s_____%s/ /_  %s\n' ${RB_RED} ${RB_ORANGE} ${RB_YELLOW} ${RB_GREEN} ${RB_BLUE} ${RB_INDIGO} ${RB_VIOLET} ${RB_RESET}
printf '%s / __ \%s/ __ \  %s / __ `__ \%s/ / / / %s /_  / %s/ ___/%s __ \ %s\n' ${RB_RED} ${RB_ORANGE} ${RB_YELLOW} ${RB_GREEN} ${RB_BLUE} ${RB_INDIGO} ${RB_VIOLET} ${RB_RESET}
printf '%s/ /_/ /%s / / / %s / / / / / /%s /_/ / %s   / /_%s(__  )%s / / / %s\n' ${RB_RED} ${RB_ORANGE} ${RB_YELLOW} ${RB_GREEN} ${RB_BLUE} ${RB_INDIGO} ${RB_VIOLET} ${RB_RESET}
printf '%s\____/%s_/ /_/ %s /_/ /_/ /_/%s\__, / %s   /___/%s____/%s_/ /_/  %s\n' ${RB_RED} ${RB_ORANGE} ${RB_YELLOW} ${RB_GREEN} ${RB_BLUE} ${RB_INDIGO} ${RB_VIOLET} ${RB_RESET}
printf '%s    %s        %s           %s /____/ %s       %s     %s          %s\n' ${RB_RED} ${RB_ORANGE} ${RB_YELLOW} ${RB_GREEN} ${RB_BLUE} ${RB_INDIGO} ${RB_VIOLET} ${RB_RESET}
if [ -e /usr/games/lolcat ]; then
    CATCAT='/usr/games/lolcat'
elif [ $(command -v lolcat) ]; then
    CATCAT='lolcat'
else
    CATCAT='cat'
fi
printf "$BLUE"
${CATCAT} <<-'EndOFneko'
			               .::::..                
			    ::::rrr7QQJi::i:iirijQBBBQB.      
			    BBQBBBQBP. ......:::..1BBBB       
			    .BuPBBBX  .........r.  vBQL  :Y.  
			     rd:iQQ  ..........7L   MB    rr  
			      7biLX .::.:....:.:q.  ri    .   
			       JX1: .r:.r....i.r::...:.  gi5  
			       ..vr .7: 7:. :ii:  v.:iv :BQg  
			       : r:  7r:i7i::ri:DBr..2S       
			    i.:r:. .i:XBBK...  :BP ::jr   .7. 
			    r  i....ir r7.         r.J:   u.  
			   :..X: .. .v:           .:.Ji       
			  i. ..i .. .u:.     .   77: si   1Q  
			 ::.. .r .. :P7.r7r..:iLQQJ: rv   ..  
			7  iK::r  . ii7r LJLrL1r7DPi iJ     r 
			  .  ::.:   .  ri 5DZDBg7JR7.:r:   i. 
			 .Pi r..r7:     i.:XBRJBY:uU.ii:.  .  
			 QB rJ.:rvDE: .. ri uv . iir.7j r7.   
			iBg ::.7251QZ. . :.      irr:Iu: r.   
			 QB  .:5.71Si..........  .sr7ivi:U    
			 7BJ .7: i2. ........:..  sJ7Lvr7s    
			  jBBdD. :. ........:r... YB  Bi      
			     :7j1.                 :  :       

		EndOFneko
printf "$RESET"
###############
configure_power_level_10k() {
    echo "Configuring zsh theme 正在配置zsh主题(powerlevel 10k)..."
    echo "github.com/romkatv/powerlevel10k"
    mkdir -p ${HOME}/.oh-my-zsh/custom/themes
    cd ${HOME}/.oh-my-zsh/custom/themes

    if [ -e "powerlevel10k/.git" ]; then
        cd powerlevel10k
        git reset --hard
        git pull --depth=1 --allow-unrelated-histories
    else
        rm -rf powerlevel10k 2>/dev/null
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" || git clone --depth=1 git://github.com/romkatv/powerlevel10k "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
    fi
    sed -i '/^ZSH_THEME/d' "${HOME}/.zshrc"
    sed -i "1 i\ZSH_THEME='powerlevel10k/powerlevel10k'" "${HOME}/.zshrc"
    # sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnosterzak"/g' ~/.zshrc
    echo "您可以输${GREEN}p10k configure${RESET}来配置${BLUE}powerlevel10k${RESET}"
    echo "You can type ${GREEN}p10k configure${RESET} to configure ${BLUE}powerlevel 10k${RESET}."
    if [ ! -e "${HOME}/.p10k.zsh" ]; then
        if [ $(command -v curl) ]; then
            curl -sLo ${HOME}/.p10k.zsh 'https://gitee.com/mo2/Termux-zsh/raw/p10k/.p10k.zsh'
        else
            wget -qO ${HOME}/.p10k.zsh 'https://gitee.com/mo2/Termux-zsh/raw/p10k/.p10k.zsh'
        fi
    fi

    if ! grep -q '.p10k.zsh' "${HOME}/.zshrc"; then
        #mkdir -p ~/.cache
        #rm -rv ~/.cache/gitstatus
        #ln -s ~/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/bin ~/.cache/gitstatus
        cat >>${HOME}/.zshrc <<-"ENDOFPOWERLEVEL"
		[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh 
		ENDOFPOWERLEVEL
    fi
}
###################
if [ "$(uname -m)" = "mips" ]; then
    echo "Configuring zsh theme 正在配置zsh主题(agnoster)..."
    sed -i '/^ZSH_THEME/d' "${HOME}/.zshrc"
    sed -i "1 i\ZSH_THEME='agnoster'" "${HOME}/.zshrc"
else
    configure_power_level_10k
fi
#############################
cd ${HOME}
cat >.zlogin <<-'EndOfFile'
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
		git reset --hard
		git pull --depth=1 --allow-unrelated-histories
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
    cd ${HOME}
    #############
	ps -e 2>/dev/null | grep -Ev 'bash|zsh' | tail -n 20
    ###########
    case ${TMOE_CHROOT} in
    true)
        rm -f /run/dbus/pid 2>/dev/null
        dbus-daemon --system --fork 2>/dev/null
        ;;
    esac
    ###########
    systemctl() {
		case ${TMOE_PROOT} in
		true) echo "Running in proot, ignoring request." ;;
		esac
		case "${#}" in
		0) /bin/systemctl ;;
		2)
			echo service $2 $1
			if [ -e "/usr/sbin/service" ]; then
				/usr/sbin/service $2 $1
			elif [ -e "/sbin/service" ]; then
				/sbin/service $2 $1
			else
				/bin/systemctl $1 $2
			fi
			;;
		*)
			set -- "/bin/systemctl" "${@}"
			"${@}"
			;;
		esac
	}
EndOfFile
#########################
cat <<-EOF
	少女祈禱中...
		現在可公開的情報:
		${BOLD}Tmoe-linux 小提示06${RESET}:

		在${YELLOW}Android-termux${RESET}上运行的GNU/Linux的Tmoe-linux tool支持使用${BLUE}触摸屏${RESET}上下滑动。
		运行于termux${YELLOW}原系统${RESET}的Tmoe-linux manager则支持使用${GREEN}数字键${RESET}快速跳转,但${RED}不支持${RESET}使用触摸屏上下滑动。
		-------------------
		You can use the ${BLUE}touch screen${RESET} on ${YELLOW}Android-termux${RESET} to slide the menu options of the tmoe-linux tool.
		-------------------
		07:容器的启动命令是${GREEN}debian${RESET}！o( =•ω•= )m
		-------------------
		You can type ${GREEN}debian${RESET} to start and attach the ${BLUE}container${RESET}.
		-------------------
EOF
##################
if [ -e "/usr/bin/sudo" ]; then
    chmod 4755 /usr/bin/sudo
elif [ -e "/bin/sudo" ]; then
    chmod 4755 /bin/sudo
fi
##################
configure_command_not_found() {
    if [ -e "/usr/lib/command-not-found" ]; then
        grep -q 'command-not-found/command-not-found.plugin.zsh' ${HOME}/.zshrc 2>/dev/null || sed -i "$ a\source ${HOME}/.oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh" ${HOME}/.zshrc
        if [ "${DEBIAN_DISTRO}" != "ubuntu" ]; then
            echo "正在配置command-not-found插件..."
            apt-file update 2>/dev/null
            update-command-not-found 2>/dev/null
        fi
    fi
}
#######################
if [ "${LINUX_DISTRO}" = "debian" ]; then
    configure_command_not_found
fi
############################
mkdir -p ${HOME}/.oh-my-zsh/custom/plugins
cd ${HOME}/.oh-my-zsh/custom/plugins
#########
echo "正在克隆zsh-syntax-highlighting语法高亮插件..."
echo "github.com/zsh-users/zsh-syntax-highlighting"
#########
if [ -e "zsh-syntax-highlighting/.git" ]; then
    cd zsh-syntax-highlighting
    git reset --hard
    git pull --depth=1 --allow-unrelated-histories
    cd ..
else
    rm -rf zsh-syntax-highlighting 2>/dev/null
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting || git clone --depth=1 git://github.com/zsh-users/zsh-syntax-highlighting ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi
grep -q 'zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\source ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ${HOME}/.zshrc
#echo -e "\nsource ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${HOME}/.zshrc
#######################
echo "正在克隆zsh-autosuggestions自动补全插件..."
echo "github.com/zsh-users/zsh-autosuggestions"
if [ -e "zsh-autosuggestions/.git" ]; then
    cd zsh-autosuggestions
    git reset --hard
    git pull --depth=1 --allow-unrelated-histories
else
    rm -rf zsh-autosuggestions 2>/dev/null
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions || git clone --depth=1 git://github.com/zsh-users/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestionszsh-autosuggestions
fi
grep -q '/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\source ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ${HOME}/.zshrc
#echo -e "\nsource ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ${HOME}/.zshrc
#####################################
configure_fzf_tab_plugin() {
    if [ $(command -v fzf) ]; then
        echo "正在克隆fzf-tab自动补全插件..."
        echo "github.com/Aloxaf/fzf-tab"
        if [ ! -d "${HOME}/.oh-my-zsh/custom/plugins/fzf-tab" ]; then
            sed -i '/fzf-tab.zsh/d' "${HOME}/.zshrc"
            git clone --depth=1 https://github.com/Aloxaf/fzf-tab.git "${HOME}/.oh-my-zsh/custom/plugins/fzf-tab" || git clone --depth=1 git://github.com/Aloxaf/fzf-tab.git "${HOME}/.oh-my-zsh/custom/plugins/fzf-tab"
            chmod 755 -R "${HOME}/.oh-my-zsh/custom/plugins/fzf-tab"
        fi
    fi
    grep -q 'custom/plugins/fzf-tab/fzf-tab.zsh' "${HOME}/.zshrc" >/dev/null 2>&1 || sed -i "$ a\source ${HOME}/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.zsh" "${HOME}/.zshrc"
}
##############
case ${LINUX_DISTRO} in
debian | arch | redhat | alpine)
    configure_fzf_tab_plugin
    ;;
*) sed -i '/fzf-tab\/fzf-tab.zsh/d' ~/.zshrc ;;
esac
case ${LINUX_DISTRO} in
redhat)
    case ${REDHAT_DISTRO} in
    fedora) ;;
    *) sed -i '/fzf-tab\/fzf-tab.zsh/d' ~/.zshrc ;;
    esac
    ;;
esac
#######################
sed_zsh_plugin_01() {
    sed -i 's/plugins=(git)/plugins=(git extract)/g' ~/.zshrc
    sed -i 's/plugins=(git extract z)/plugins=(git extract)/g' ~/.zshrc
}
#########
sed_zsh_plugin_02() {
    sed -i 's/plugins=(git)/plugins=(git extract z)/g' ~/.zshrc
    sed -i 's/plugins=(git extract)/plugins=(git extract z)/g' ~/.zshrc
}
#########
case ${LINUX_DISTRO} in
debian | arch | alpine)
    if grep -Eq 'Bionic|buster|stretch|jessie|Xenial' /etc/os-release; then
        sed_zsh_plugin_01
    else
        sed_zsh_plugin_02
    fi
    ;;
*) sed_zsh_plugin_01 ;;
esac
############################
if [ -f "/tmp/.openwrtcheckfile" ]; then
    ADMINACCOUNT="$(ls -l /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')"
    cp -rf /root/.z* /root/.oh-my-zsh /root/*sh /home/${ADMINACCOUNT}
    rm -f /tmp/.openwrtcheckfile
fi
########################
echo 'All optimization steps have been completed, enjoy it!'
echo 'zsh配置完成，即将为您启动Tmoe-linux工具'
echo "您也可以手动输${YELLOW}debian-i${RESET}进入"
echo 'Tmoe-linux tool will be launched.'
echo 'You can also enter debian-i manually to start it.'
#sleep 1s
########################
TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
mkdir -p ${TMOE_LINUX_DIR}
TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
TMOE_GIT_URL='https://github.com/2moe/tmoe-linux.git'
echo "gitee.com/mo2/linux"
git clone --depth=1 ${TMOE_GIT_URL} ${TMOE_GIT_DIR}
mkdir -p /usr/share/applications
cp ${TMOE_GIT_DIR}/tools/app/lnk/tmoe-linux.desktop /usr/share/applications
bash /usr/local/bin/debian-i
exec zsh -l || source ~/.zshrc
