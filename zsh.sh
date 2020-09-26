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
		if [ -e "/etc/X11/xinit/Xsession" ] && [ ! -e "${HOME}/.vnc/passwd" ]; then
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
		    #ps -e 2>/dev/null | grep -Ev 'bash|zsh|TMOE_PROOT|TMOE_CHROOT|tmoe-linux' | tail -n 20
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
}
#########################
fix_sudo() {
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
	if [ -f "/tmp/.openwrtcheckfile" ]; then
		ADMINACCOUNT="$(ls -l /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')"
		cp -rf /root/.z* /root/.oh-my-zsh /root/*sh /home/${ADMINACCOUNT}
		rm -f /tmp/.openwrtcheckfile
	fi
	########################
	cat <<-ENDOFTTMOEZSH
		All optimization steps have been completed, enjoy it!
		zsh配置完成，即将为您启动Tmoe-linux工具
		您也可以手动输${YELLOW}debian-i${RESET}进入
		Tmoe-linux tool will be launched.
		You can also type ${GREEN}debian-i${RESET} to start it.
	ENDOFTTMOEZSH
}
########################
git_clone_tmoe_linux() {
	TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
	mkdir -p ${TMOE_LINUX_DIR}
	TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
	TMOE_GIT_URL='https://github.com/2moe/tmoe-linux.git'
	echo "gitee.com/mo2/linux"
	if [ ! -e "${TMOE_GIT_DIR}/.git" ]; then
		rm -rv ${TMOE_GIT_DIR} 2>/dev/null
		git clone --depth=1 ${TMOE_GIT_URL} ${TMOE_GIT_DIR}
	fi
	######################
	mkdir -p /usr/share/applications
	cp ${TMOE_GIT_DIR}/tools/app/lnk/tmoe-linux.desktop /usr/share/applications
	exec zsh &
	bash /usr/local/bin/debian-i
	exec zsh -l
}
###################
tmoe_container_zsh_main "$@"
