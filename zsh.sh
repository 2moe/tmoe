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

elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
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
    curl -Lo /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
else
    wget -qO /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
fi
chmod +x /usr/local/bin/debian-i
#########################
rm -rf ${HOME}/.oh-my-zsh
echo "github.com/ohmyzsh/ohmyzsh"
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ${HOME}/.oh-my-zsh || git clone --depth=1 git://github.com/ohmyzsh/ohmyzsh.git ${HOME}/.oh-my-zsh
#chmod 755 -R "${HOME}/.oh-my-zsh"
if [ ! -f "${HOME}/.zshrc" ]; then
    cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc" || curl -Lo "${HOME}/.zshrc" 'https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/templates/zshrc.zsh-template'
    #https://github.com/ohmyzsh/ohmyzsh/raw/master/templates/zshrc.zsh-template
fi
######################
chsh -s /usr/bin/zsh || chsh -s /bin/zsh

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
printf "$BLUE"
cat <<-'EndOFneko'
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
    rm -rf "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" || git clone --depth=1 git://github.com/romkatv/powerlevel10k "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
    sed -i '/^ZSH_THEME/d' "${HOME}/.zshrc"
    sed -i "1 i\ZSH_THEME='powerlevel10k/powerlevel10k'" "${HOME}/.zshrc"
    # sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnosterzak"/g' ~/.zshrc
    echo '您可以输p10k configure来配置powerlevel10k'
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
chroot_export_language_and_home() {
    grep -q 'unset LD_PRELOAD' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "1 a\unset LD_PRELOAD" ${HOME}/.zshrc >/dev/null 2>&1
    grep -q 'en_US.UTF-8' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\export LANG=en_US.UTF-8" ${HOME}/.zshrc >/dev/null 2>&1
    grep -q 'HOME=/root' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\export HOME=/root" ${HOME}/.zshrc >/dev/null 2>&1
    grep -q 'cd /root' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\cd /root" ${HOME}/.zshrc >/dev/null 2>&1
}
#######################
if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
    chroot_export_language_and_home
fi
#######################
cd ~
cat >~/.zlogin <<-'EndOfFile'
cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2
locale_gen_tmoe_language() {
    if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
        cd /etc
        sed -i "s/^#.*${TMOE_LANG} UTF-8/${TMOE_LANG} UTF-8/" locale.gen
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
#########################
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
######################
if [ "${LINUX_DISTRO}" != "redhat" ]; then
    sed -i "1 c\cat /etc/issue" .zlogin
fi
#######################
if [ "${LINUX_DISTRO}" = "debian" ]; then
    configure_command_not_found
fi
############################
echo "正在克隆zsh-syntax-highlighting语法高亮插件..."
echo "github.com/zsh-users/zsh-syntax-highlighting"
rm -rf ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 2>/dev/null
mkdir -p ${HOME}/.oh-my-zsh/custom/plugins

git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting || git clone --depth=1 git://github.com/zsh-users/zsh-syntax-highlighting ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

grep -q 'zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' ${HOME}/.zshrc >/dev/null 2>&1 || sed -i "$ a\source ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ${HOME}/.zshrc
#echo -e "\nsource ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${HOME}/.zshrc
#######################
echo "正在克隆zsh-autosuggestions自动补全插件..."
echo "github.com/zsh-users/zsh-autosuggestions"
rm -rf ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions 2>/dev/null

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions || git clone --depth=1 git://github.com/zsh-users/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestionszsh-autosuggestions

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
            grep -q 'custom/plugins/fzf-tab/fzf-tab.zsh' "${HOME}/.zshrc" >/dev/null 2>&1 || sed -i "$ a\source ${HOME}/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.zsh" "${HOME}/.zshrc"
        fi
    fi
}
##############
if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "alpine" ] || [ "${LINUX_DISTRO}" = "redhat" ] || [ "${LINUX_DISTRO}" = "arch" ]; then
    configure_fzf_tab_plugin
fi
#######################
if grep -Eq 'Bionic|buster|Xenial' /etc/os-release; then
    sed -i 's/plugins=(git)/plugins=(git extract)/g' ~/.zshrc
fi

if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "arch" ]; then
    sed -i 's/plugins=(git)/plugins=(git extract z)/g' ~/.zshrc
else
    sed -i 's/plugins=(git)/plugins=(git extract)/g' ~/.zshrc
fi
############################
if [ -f "/tmp/.openwrtcheckfile" ]; then
    ADMINACCOUNT="$(ls -l /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')"
    cp -rf /root/.z* /root/.oh-my-zsh /root/*sh /home/${ADMINACCOUNT}
    rm -f /tmp/.openwrtcheckfile
fi
########################
echo 'All optimization steps have been completed, enjoy it!'
echo 'zsh配置完成，2s后将为您启动Tmoe-linux工具'
echo "您也可以手动输${YELLOW}debian-i${RESET}进入"
echo 'After 2 seconds, Tmoe-linux tool will be launched.'
echo 'You can also enter debian-i manually to start it.'
sleep 2s
bash /usr/local/bin/debian-i
exec zsh -l || source ~/.zshrc
