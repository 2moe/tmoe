#!/usr/bin/env bash
###################
tmoe_container_zsh_main() {
	case "$1" in
	*)
		set_tmoe_zsh_env
		set_terminal_color
		check_tmoe_locale_file
		do_you_want_to_configure_tmoe_zsh
		check_tmoe_linux_tool
		copy_git_status
		auto_configure_tmoe_tools
		check_ps_command
		creat_zlogin_file
		fix_sudo
		auto_configure_tmoe_tool_02
		;;
	esac
}
############
set_tmoe_zsh_env() {
	TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
	TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
	TMOE_SHARE_DIR="${TMOE_GIT_DIR}/share"
}
set_terminal_color() {
	RED=$(printf '\033[31m')
	GREEN=$(printf '\033[32m')
	YELLOW=$(printf '\033[33m')
	BLUE=$(printf '\033[34m')
	BOLD=$(printf '\033[1m')
	PURPLE=$(printf '\033[0;35m')
	RESET=$(printf '\033[m')
}
#######
check_tmoe_locale_file() {
	TMOE_LOCALE_FILE=/usr/local/etc/tmoe-linux/locale.txt
	if [ -e "${TMOE_LOCALE_FILE}" ]; then
		TMOE_LANG=$(head -n 1 ${TMOE_LOCALE_FILE})
	else
		TMOE_LANG=${LANG}
	fi
	if [[ -n $(command -v debian-i) && ! -n $(command -v tmoe) ]]; then
		cp -pf $(command -v debian-i) /usr/local/bin/tmoe
	fi
}
#######
do_you_want_to_delete_the_zsh_script_file() {
	if [[ -e ~/zsh.sh || -e ~/zsh-i.sh ]]; then
		if (whiptail --title "zsh.sh & zsh-i.sh" --yes-button "YES" --no-button "NO" --yesno 'Do you want to delete ~/zsh.sh & ~/zsh-i.sh after configruation.' 0 0); then
			DELETE_ZSH_SCRIPT=true
		fi
	fi
}
set_your_vnc_passwd() {
	${TMOE_GIT_DIR}/tool.sh -passwd
}
do_you_want_to_configure_tmoe_zsh() {
	cd ${HOME}
	unset CONFIGURE_ZSH CONFIGURE_FACE_ICON CONFIGURE_TMOE_LINUX_TOOL DEFAULT_FACE_ICON DELETE_ZSH_SCRIPT FACE_ICON_DIR
	for i in "/storage/emulated/0/Android/data/com.tencent.mobileqq/Tencent/MobileQQ/head/_SSOhd" "/storage/emulated/0/Pictures/Telegram" "/storage/emulated/0/DCIM/Camera" "/sd" "/sd/Pictures" "/storage/emulated/0/DCIM/.thumbnails"; do
		if [[ -e ${i} ]]; then
			if [[ -n $(ls -l ${i} | grep '^-' | egrep '\.png|\.jpg') ]]; then
				FACE_ICON_DIR="${i}"
				break
			fi
		fi
	done
	case ${TMOE_LANG} in
	zh_*UTF-8)
		if [[ ! -e /.dockerenv ]]; then
			if (whiptail --title "zsh" --yes-button "YES" --no-button "NO" --yesno '是否需要配置zsh?\nDo you need to configure zsh?' 0 0); then
				CONFIGURE_ZSH=true
			fi
		fi
		do_you_want_to_delete_the_zsh_script_file
		if [ -n "${FACE_ICON_DIR}" ]; then
			if (whiptail --title "FACE ICON" --yes-button "YES" --no-button "NO" --yesno "是否需要读取${FACE_ICON_DIR}目录下的jpg/png文件,并自动生成头像?\n本操作仅在本机内执行。\n若选NO,则将不会读取该目录,并使用tmoe-linux的默认头像" 0 0); then
				CONFIGURE_FACE_ICON=true
			else
				CONFIGURE_FACE_ICON=false
			fi
		fi
		if (whiptail --title "TMOE-LINUX-TOOL" --yes-button "YES" --no-button "NO" --yesno '是否需要启动tmoe-linux tool?\nDo you need to start tmoe-linux tool?' 0 0); then
			CONFIGURE_TMOE_LINUX_TOOL=true
		fi
		;;
	*)
		if [[ ! -e /.dockerenv ]]; then
			if (whiptail --title "zsh" --yes-button "YES" --no-button "NO" --yesno 'Do you want to configure zsh?' 0 0); then
				CONFIGURE_ZSH=true
			fi
		fi
		do_you_want_to_delete_the_zsh_script_file
		if [ -n "${FACE_ICON_DIR}" ]; then
			if (whiptail --title "FACE ICON" --yes-button "YES" --no-button "NO" --yesno "Do you want to read the jpg/png files in the ${FACE_ICON_DIR} directory and auto generate an avatar?\nThis operation is only performed locally." 0 0); then
				CONFIGURE_FACE_ICON=true
			fi
		fi
		if (whiptail --title "TMOE-LINUX-TOOL" --yes-button "YES" --no-button "NO" --yesno 'Do you want to start tmoe-linux tool?' 0 0); then
			CONFIGURE_TMOE_LINUX_TOOL=true
		fi
		;;
	esac
	if [[ -z ${CONFIGURE_FACE_ICON} && ${CONFIGURE_TMOE_LINUX_TOOL} = true ]]; then
		if (whiptail --title "\${HOME}/.face.icon" --yes-button "YES" --no-button "NO" --yesno 'Do you want to use the default face.icon?' 0 0); then
			DEFAULT_FACE_ICON=true
		fi
	fi
}
##################
auto_configure_tmoe_tools() {
	[[ ${CONFIGURE_FACE_ICON} != true ]] || auto_check_face_icon
	[[ ${CONFIGURE_ZSH} != true ]] || configure_tmoe_zsh
	[[ ${DELETE_ZSH_SCRIPT} != true ]] || rm -fv ~/zsh.sh ~/zsh-i.sh
	if [[ -e /.dockerenv ]]; then
		set_your_vnc_passwd
	else
		if [[ ${CONFIGURE_ZSH} = true || ${CONFIGURE_TMOE_LINUX_TOOL} = true ]]; then
			install_lolcat_and_neofetch
		fi
	fi
}
################
install_lolcat_and_neofetch() {
	for i in lolcat neofetch; do
		if [[ -n $(command -v apt) ]]; then
			printf "%s\n" "${GREEN}apt ${YELLOW}install -y ${BLUE}${i}${RESET}"
			apt install -y ${i}
		elif [[ -n $(command -v pacman) ]]; then
			printf "%s\n" "${GREEN}pacman ${YELLOW}-Sy --noconfirm ${BLUE}${i}${RESET}"
			pacman -Sy --noconfirm ${i}
		fi
	done
	#fedora neofetch (X)
	if [[ -n $(command -v dnf) && ! -n $(command -v lolcat) ]]; then
		printf "%s\n" "${GREEN}dnf ${YELLOW}install -y ${BLUE}lolcat${RESET}"
		dnf install -y lolcat
	fi
	if [[ -n $(command -v zypper) ]]; then
		printf "%s\n" "${GREEN}zypper ${YELLOW}in -y ${BLUE}ruby2.7-rubygem-lolcat neofetch${RESET}"
		zypper in -y ruby2.7-rubygem-lolcat
		zypper in -y neofetch
	fi
	i=neofetch
	[[ ! -e /usr/bin/${i} ]] || rm -fv /usr/local/bin/${i}
	printf "%s\n" "${GREEN}neofetch | lolcat${RESET}"
	if [ -e /usr/games/lolcat ]; then
		neofetch | /usr/games/lolcat
	elif [ "$(command -v lolcat)" ]; then
		neofetch | lolcat
	else
		neofetch
	fi
}
auto_configure_tmoe_tool_02() {
	if [[ ${CONFIGURE_TMOE_LINUX_TOOL} = true ]]; then
		git_clone_tmoe_linux
	else
		for i in zsh bash ash; do
			if [ $(command -v ${i}) ]; then
				exec ${i}
				break
			fi
		done
	fi
}
auto_check_face_icon() {
	FACE_ICON_FILE_NAME=$(ls -t ${FACE_ICON_DIR} | egrep '\.jpg|\.png' | head -n 1)
	cp -vf ${FACE_ICON_DIR}/${FACE_ICON_FILE_NAME} ${HOME}/.face
	ln -svf ${HOME}/.face ${HOME}/.face.icon
}
################
check_tmoe_linux_tool() {
	if [ ! $(command -v debian-i) ]; then
		if [ -e "/usr/bin/curl" ]; then
			curl -Lo /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		else
			wget -qO /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
		fi
	fi
	chmod 777 /usr/local/bin/debian-i
	mkdir -pv /run/dbus
}
##############
copy_git_status() {
	if [ -e "/etc/gitstatus" ]; then
		mkdir -pv ${HOME}/.cache
		cp -rf /etc/gitstatus ${HOME}/.cache
	fi
}
################
check_ps_command() {
	ps -e &>/dev/null
	if [ "$?" != '0' ]; then
		TERMUX_BIN_PATH='/data/data/com.termux/files/usr/bin/'
		if [ -e "${TERMUX_BIN_PATH}/ps" ]; then
			ln -sv ${TERMUX_BIN_PATH}/ps /usr/local/bin/ps 2>/dev/null
			ln -sv ${TERMUX_BIN_PATH}/pstree /usr/local/bin/pstree 2>/dev/null
		fi
	fi
}
##########
configure_tmoe_zsh() {
	#此处不要source脚本
	TMOE_ZSH_TOOL_BIN=/usr/local/bin/zsh-i
	TMOE_ZSH_SCRIPT_URL='https://raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh'
	if [[ -e "${TMOE_ZSH_TOOL_BIN}" ]]; then
		chmod a+x -v ${TMOE_ZSH_TOOL_BIN}
		bash ${TMOE_ZSH_TOOL_BIN} --tmoe_container_automatic_configure
	else
		if [[ $(command -v curl) ]]; then
			curl -Lo ${TMOE_ZSH_TOOL_BIN} ${TMOE_ZSH_SCRIPT_URL}
		elif [[ $(command -v wget) ]]; then
			wget -O ${TMOE_ZSH_TOOL_BIN} ${TMOE_ZSH_SCRIPT_URL}
		fi
		chmod 777 ${TMOE_ZSH_TOOL_BIN}
		bash ${TMOE_ZSH_TOOL_BIN} --tmoe_container_automatic_configure
	fi

	if [[ ! $(command -v zsh) ]]; then
		if [[ -e "${HOME}/zsh-i.sh" ]]; then
			bash ${HOME}/zsh-i.sh --tmoe_container_automatic_configure
		fi
	fi

	if egrep -qi 'fedora|redhat|Alpine|centos' /etc/os-release; then
		[[ ! -e /bin/zsh ]] || sed -E -i '1s@(root:x:0:0:root:/root:/bin/)(ash|bash)@\1zsh@' /etc/passwd
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
			08.输入${GREEN}debian-i${RESET}启动${BLUE}tmoe-linux tool${RESET}.

			You can type ${GREEN}debian-i${RESET} to start ${BLUE}tmoe-linux tool${RESET}.
	EOF
	##################
	if [ -e "/usr/bin/sudo" ]; then
		chmod 4755 -v /usr/bin/sudo
	elif [ -e "/bin/sudo" ]; then
		chmod 4755 -v /bin/sudo
	fi
	##################
	if [ -f "/tmp/.openwrtcheckfile" ]; then
		ADMINACCOUNT="$(ls -l /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')"
		cp -rf /root/.z* /root/.oh-my-zsh /root/*sh /home/${ADMINACCOUNT}
		rm -f /tmp/.openwrtcheckfile
	fi
	########################
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
	SOURCELISTCODE=$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2 | head -n 1)
	if egrep -q 'debian|ubuntu' /etc/os-release; then
		SOURCELISTCODE=$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2 | head -n 1)
		BACKPORTCODE=$(grep PRETTY_NAME /etc/os-release | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | awk -F ' ' '$0=$NF' | cut -d '/' -f 1 | cut -d '(' -f 2 | cut -d ')' -f 1)
		if grep -q 'Debian' /etc/issue 2>/dev/null; then
			if ! grep -q '#Official' ${SOURCE_LIST}; then
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
		fi
	elif grep -q 'Arch' /etc/issue 2>/dev/null; then
		if ! grep -q '## Worldwide' ${MIRROR_LIST}; then
			case $(uname -m) in
			i*86 | x86_64) sed -i "$ r ${TMOE_MIRROR_DIR}/arch/x86_64/mirrorlist" ${MIRROR_LIST} ;;
			*) sed -i "$ r ${TMOE_MIRROR_DIR}/arch/aarch64/mirrorlist" ${MIRROR_LIST} ;;
			esac
		fi
	fi
}
###############
git_clone_tmoe_linux() {
	TMOE_MIRROR_DIR="${TMOE_SHARE_DIR}/configuration/mirror-list"
	mkdir -pv ${TMOE_LINUX_DIR}
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
	if [[ ! -e "${HOME}/.face" && ${DEFAULT_FACE_ICON} = true ]]; then
		cp -v ${TMOE_GIT_DIR}/.mirror/icon.png ${HOME}/.face
		ln -svf ${HOME}/.face ${HOME}/.face.icon
		printf "%s\n" "You can type cp /xxx/xxx/FACE_ICON.png ${HOME}/.face to set your face.icon"
	fi
	mkdir -pv /usr/share/applications
	cp -v ${TMOE_GIT_DIR}/tools/app/lnk/tmoe-linux.desktop /usr/share/applications
	#exec zsh &
	if [ -e ${TMOE_GIT_DIR}/share/app/tmoe ]; then
		rm -vf /usr/local/bin/tmoe 2>/dev/null
		ln -svf ${TMOE_GIT_DIR}/share/app/tmoe /usr/local/bin
	fi
	if [ ! $(command -v startvnc) ]; then
		printf "%s\n" "${TMOE_GIT_DIR}/tool.sh --install-gui" >/usr/local/bin/startvnc
		chmod +x /usr/local/bin/startvnc
	fi
	case ${TMOE_LANG} in
	zh_*UTF-8)
		cat <<-ENDOFTTMOEZSH
			All optimization steps have been completed, enjoy it!
			zsh配置完成，即将为您启动Tmoe-linux工具
			您也可以手动输${YELLOW}tmoe t${RESET}进入
			Tmoe-linux tool will be launched.
			You can also type ${GREEN}tmoe t${RESET} to start it.
		ENDOFTTMOEZSH
		;;
	*)
		cat <<-ENDOFTTMOEZSH
			All optimization steps have been completed, enjoy it!
			Tmoe-linux tool will be launched.
			You can also type ${GREEN}tmoe t${RESET} to start it.
		ENDOFTTMOEZSH
		;;
	esac
	bash /usr/local/bin/debian-i
	for i in zsh bash ash; do
		if [ $(command -v ${i}) ]; then
			exec ${i} -l
			break
		fi
	done
}
###################
tmoe_container_zsh_main "$@"
