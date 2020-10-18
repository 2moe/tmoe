#!/usr/bin/env bash
###################
tmoe_container_zsh_main() {
	case "$1" in
	*)
		check_tmoe_linux_tool
		copy_git_status
		configure_tmoe_zsh
		check_ps_command
		creat_zlogin_file
		fix_sudo
		git_clone_tmoe_linux
		;;
	esac
}
############
check_tmoe_linux_tool() {
	if [ ! $(command -v debian-i) ]; then
		if [ -e "/usr/bin/curl" ]; then
			curl -Lo /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		else
			wget -qO /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		fi
	fi
	chmod 777 /usr/local/bin/debian-i
	mkdir -p /run/dbus
}
##############
copy_git_status() {
	if [ -e "/etc/gitstatus" ]; then
		mkdir -p ${HOME}/.cache
		cp -rf /etc/gitstatus ${HOME}/.cache
	fi
}
################
check_ps_command() {
	ps -e &>/dev/null
	if [ "$?" != '0' ]; then
		TERMUX_BIN_PATH='/data/data/com.termux/files/usr/bin/'
		if [ -e "${TERMUX_BIN_PATH}/ps" ]; then
			ln -s ${TERMUX_BIN_PATH}/ps /usr/local/bin/ps 2>/dev/null
			ln -s ${TERMUX_BIN_PATH}/pstree /usr/local/bin/pstree 2>/dev/null
		fi
	fi
}
##########
configure_tmoe_zsh() {
	#此处不要source脚本
	TMOE_ZSH_TOOL_BIN=/usr/local/bin/zsh-i
	TMOE_ZSH_SCRIPT_URL='https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh'
	if [ -e "${HOME}/zsh-i" ]; then
		bash ${HOME}/zsh-i --tmoe_container_automatic_configure
	elif [ -e "${TMOE_ZSH_TOOL_BIN}" ]; then
		chmod +x ${TMOE_ZSH_TOOL_BIN}
		bash ${TMOE_ZSH_TOOL_BIN} --tmoe_container_automatic_configure
	else
		if [ -e "/usr/bin/curl" ]; then
			curl -Lo ${TMOE_ZSH_TOOL_BIN} ${TMOE_ZSH_SCRIPT_URL}
		else
			wget -O ${TMOE_ZSH_TOOL_BIN} ${TMOE_ZSH_SCRIPT_URL}
		fi
		chmod 777 ${TMOE_ZSH_TOOL_BIN}
		bash ${TMOE_ZSH_TOOL_BIN} --tmoe_container_automatic_configure
	fi
}
############
creat_zlogin_file() {
	cd ${HOME}
	cp .bash_login .zlogin
	sed -i '/source ~\/\.profile/d' .zlogin
}
#########################
fix_sudo() {
	cat <<-EOF
		少女祈禱中...
			現在可公開的情報:
			${BOLD}Tmoe-linux 小提示06${RESET}:

			在${YELLOW}Android-termux${RESET}上运行的GNU/Linux的Tmoe-linux tool支持使用${BLUE}触摸屏${RESET}上下滑动。
			运行于termux${YELLOW}原系统${RESET}的Tmoe-linux manager支持使用${BLUE}触摸屏${RESET}进行点击，还支持使用${GREEN}数字键${RESET}进行快速跳转,但${RED}不支持${RESET}使用触摸屏上下滑动。
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
	if [ -f "/tmp/.openwrtcheckfile" ]; then
		ADMINACCOUNT="$(ls -l /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')"
		cp -rf /root/.z* /root/.oh-my-zsh /root/*sh /home/${ADMINACCOUNT}
		rm -f /tmp/.openwrtcheckfile
	fi
	########################
	cat <<-ENDOFTTMOEZSH
		All optimization steps have been completed, enjoy it!
		zsh配置完成，即将为您启动Tmoe-linux工具
		您也可以手动输${YELLOW}tmoe t${RESET}进入
		Tmoe-linux tool will be launched.
		You can also type ${GREEN}tmoe t${RESET} to start it.
	ENDOFTTMOEZSH
	###########
	if grep -q 'SUSE' /etc/os-release; then
		printf "%s\n" "zypper in -y yast2 yast2-packager"
		zypper in -y yast2 yast2-packager
	fi
}
########################
sed_a_debian_testing_source() {
	#sed -i "$ r ${TMOE_MIRROR_DIR}/debian/sources.list;s@testing@${BACKPORTCODE}@g" ${SOURCE_LIST}
	cp -f ${TMOE_MIRROR_DIR}/debian/sources.list /tmp
	sed -i "s@testing@${BACKPORTCODE}@g" /tmp/sources.list
	sed -i '$ r /tmp/sources.list' ${SOURCE_LIST}
}
#########
sed_a_source_list() {
	SOURCE_LIST='/etc/apt/sources.list'
	MIRROR_LIST='/etc/pacman.d/mirrorlist'
	SOURCELISTCODE=$(sed -n p /etc/os-release | grep VERSION_CODENAME | cut -d '=' -f 2 | head -n 1)
	if egrep -q 'debian|ubuntu' /etc/os-release; then
		SOURCELISTCODE=$(sed -n p /etc/os-release | grep VERSION_CODENAME | cut -d '=' -f 2 | head -n 1)
		BACKPORTCODE=$(sed -n p /etc/os-release | grep PRETTY_NAME | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | awk -F ' ' '$0=$NF' | cut -d '/' -f 1 | cut -d '(' -f 2 | cut -d ')' -f 1)
		if grep -q 'Debian' /etc/issue 2>/dev/null; then
			if [ $(command -v lsb_release) ]; then
				if [ "$(lsb_release -r | awk '{print $2}' | awk -F '/' '{print $1}')" = 'unstable' ]; then
					sed -i "$ r ${TMOE_MIRROR_DIR}/debian/sid.list" ${SOURCE_LIST}
				else
					sed_a_debian_testing_source
				fi
			else
				sed_a_debian_testing_source
			fi
		elif grep -q "ubuntu" /etc/os-release; then
			case $(uname -m) in
			i*86 | x86_64)
				#sed -i "$ r ${TMOE_MIRROR_DIR}/ubuntu/amd64/sources.list;s@focal@${SOURCELISTCODE}@g" ${SOURCE_LIST}
				cp -f ${TMOE_MIRROR_DIR}/ubuntu/amd64/sources.list /tmp
				sed -i "s@focal@${SOURCELISTCODE}@g" /tmp/sources.list
				sed -i '$ r /tmp/sources.list' ${SOURCE_LIST}
				;;
			esac
		fi
	elif grep -q 'Arch' /etc/issue 2>/dev/null; then
		case $(uname -m) in
		i*86 | x86_64) sed -i "$ r ${TMOE_MIRROR_DIR}/arch/x86_64/mirrorlist" ${MIRROR_LIST} ;;
		*) sed -i "$ r ${TMOE_MIRROR_DIR}/arch/aarch64/mirrorlist" ${MIRROR_LIST} ;;
		esac
	fi
}
###############
git_clone_tmoe_linux() {
	TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
	TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
	TMOE_SHARE_DIR="${TMOE_GIT_DIR}/share"
	TMOE_MIRROR_DIR="${TMOE_SHARE_DIR}/configuration/mirror-list"
	mkdir -p ${TMOE_LINUX_DIR}
	TMOE_GIT_URL='https://github.com/2moe/tmoe-linux.git'
	printf "%s\n" "github.com/2moe/tmoe-linux"
	if [ ! -e "${TMOE_GIT_DIR}/.git" ]; then
		rm -rv ${TMOE_GIT_DIR} 2>/dev/null
		git clone --depth=1 ${TMOE_GIT_URL} ${TMOE_GIT_DIR}
	fi
	######################
	#TMOE_LANG=$(head -n 1 ${TMOE_LINUX_DIR}/locale.txt)
	if [ -e "/etc/os-release" ]; then
		sed_a_source_list
	fi
	mkdir -p /usr/share/applications
	cp ${TMOE_GIT_DIR}/tools/app/lnk/tmoe-linux.desktop /usr/share/applications
	#exec zsh &
	if [ ! $(command -v tmoe) ]; then
		ln -sf ${TMOE_GIT_DIR}/share/app/tmoe /usr/local/bin
	fi
	bash /usr/local/bin/debian-i
	exec zsh -l
}
###################
tmoe_container_zsh_main "$@"
