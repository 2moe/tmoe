#!/usr/bin/env bash
tmoe_uefi_boot_manager() {
	NON_DEBIAN='false'
	if [ ! $(command -v efibootmgr) ]; then
		echo "本工具能对UEFI开机引导的顺序进行排序，但不支持容器和WSL"
		echo "按回车键确认安装"
		do_you_want_to_continue
		DEPENDENCY_01=''
		DEPENDENCY_02='efibootmgr'
		beta_features_quick_install
	fi
	#RETURN变量不要放在本函数开头
	RETURN_TO_WHERE='tmoe_uefi_boot_manager'
	CURRENT_UEFI_BOOT_ORDER=$(efibootmgr | grep 'BootOrder:' | cut -d ':' -f 2 | awk '{print $1}')
	TMOE_BOOT_MGR=$(
		whiptail --title "开机启动项管理" --menu "Note: efibootmgr requires that the kernel module efivars be loaded prior to use. 'modprobe efivars' should do the trick if it does not automatically load." 16 50 5 \
			"1" "first boot item修改第一启动项" \
			"2" "boot order自定义排序" \
			"3" "Backup efi备份" \
			"4" "Restore efi恢复" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${TMOE_BOOT_MGR} in
	0 | "") tmoe_system_app_menu ;;
	1) modify_first_uefi_boot_item ;;
	2) custom_uefi_boot_order ;;
	3) tmoe_backup_efi ;;
	4) tmoe_restore_efi ;;
	esac
	###############
	press_enter_to_return
	tmoe_uefi_boot_manager
}
###########
tmoe_backup_efi() {
	mkdir -p ${CONFIG_FOLDER}
	cd ${CONFIG_FOLDER}
	CURRENT_EFI_DISK=$(df -h | grep '/boot/efi' | awk '{print $1}')
	EFI_BACKUP_NAME='efi_backup.img'
	if [ -e "${EFI_BACKUP_NAME}" ]; then
		stat ${EFI_BACKUP_NAME}
		ls -lh ${EFI_BACKUP_NAME}
		echo "备份文件已存在，是否覆盖？"
		do_you_want_to_continue
	fi

	echo "正在将${CURRENT_EFI_DISK}备份至${CONFIG_FOLDER}/${EFI_BACKUP_NAME}"
	dd <${CURRENT_EFI_DISK} >${EFI_BACKUP_NAME}
	echo "备份完成"
	stat ${EFI_BACKUP_NAME}
	ls -lh $(pwd)/${EFI_BACKUP_NAME}
}
############
tmoe_restore_efi() {
	cd ${CONFIG_FOLDER}
	df -h | grep '/boot/efi'
	CURRENT_EFI_DISK=$(df -h | grep '/boot/efi' | awk '{print $1}')
	fdisk -l 2>&1 | grep ${CURRENT_EFI_DISK}
	EFI_BACKUP_NAME='efi_backup.img'
	ls -lh /boot/efi/EFI
	echo "您真的要将${EFI_BACKUP_NAME}烧录至${CURRENT_EFI_DISK}？这将重置${CURRENT_EFI_DISK}的所有数据"
	echo "请谨慎操作"
	do_you_want_to_continue
	echo "正在将${CONFIG_FOLDER}/${EFI_BACKUP_NAME}烧录至${CURRENT_EFI_DISK}"
	dd <${EFI_BACKUP_NAME} >${CURRENT_EFI_DISK}
	echo "恢复完成"
	stat ${EFI_BACKUP_NAME}
	ls -lh $(pwd)/${EFI_BACKUP_NAME}
}
##########
remove_boot_mgr() {
	if [ $? != 0 ]; then
		echo "本工具不支持您当前所处的环境，是否卸载？"
		echo "Do you want to remove it?"
		do_you_want_to_continue
		${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_02}
		beta_features
	else
		echo "修改完成，重启系统生效"
	fi
}
###########
modify_first_uefi_boot_item() {
	cd /tmp/
	efibootmgr | grep -Ev 'BootCurrent:|Timeout:|BootOrder:' | cut -d '*' -f 1 | sed 's@Boot@@g' >.tmoe-linux_cache.01
	efibootmgr | grep -Ev 'BootCurrent:|Timeout:|BootOrder:' | cut -d '*' -f 2 | sed 's/ //g' | sed 's/^/\"&/g' | sed 's/$/&\"/g' >.tmoe-linux_cache.02
	TMOE_UEFI_LIST=$(paste -d ' ' .tmoe-linux_cache.01 .tmoe-linux_cache.02 | sed ":a;N;s/\n/ /g;ta")
	rm -f .tmoe-linux_cache.0*
	TMOE_UEFI_BOOT_ITEM=$(whiptail --title "BOOT ITEM" --menu \
		"检测当前的第一启动项为$(efibootmgr | grep 'BootOrder:' | awk '{print $2}' | cut -d ',' -f 1)" 0 0 0 \
		${TMOE_UEFI_LIST} \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	case ${TMOE_UEFI_BOOT_ITEM} in
	0 | "") tmoe_uefi_boot_manager ;;
	esac
	if [ $(efibootmgr | grep 'BootOrder:' | cut -d ':' -f 2 | awk '{print $1}' | grep ^${TMOE_UEFI_BOOT_ITEM}) ]; then
		NEW_TMOE_UEFI_BOOT_ORDER=$(efibootmgr | grep 'BootOrder:' | cut -d ':' -f 2 | awk '{print $1}' | sed "s@${TMOE_UEFI_BOOT_ITEM},@@" | sed "s@${TMOE_UEFI_BOOT_ITEM}@@" | sed "s@^@${TMOE_UEFI_BOOT_ITEM},&@")
	else
		NEW_TMOE_UEFI_BOOT_ORDER=$(efibootmgr | grep 'BootOrder:' | cut -d ':' -f 2 | awk '{print $1}' | sed "s@,${TMOE_UEFI_BOOT_ITEM}@@" | sed "s@${TMOE_UEFI_BOOT_ITEM}@@" | sed "s@^@${TMOE_UEFI_BOOT_ITEM},&@")
	fi
	echo "已将启动规则修改为${NEW_TMOE_UEFI_BOOT_ORDER}"
	efibootmgr -o ${NEW_TMOE_UEFI_BOOT_ORDER}
	remove_boot_mgr
}
################
custom_uefi_boot_order() {
	TARGET=$(whiptail --inputbox "$(efibootmgr | sed 's@Boot0@0@g' | sed 's@* @:@g')\n请输入启动顺序规则,以半角逗号分开,当前为${CURRENT_UEFI_BOOT_ORDER}\nPlease enter the order, separated by commas." 0 0 --title "BOOT ORDER" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		#echo "检测到您取消了操作"
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		echo "请输入有效的数值"
		echo "Please enter a valid value"
	else
		echo "错误的规则将会导致系统无法正常引导，请确保您的输入无误"
		echo "您输入的规则为${TARGET}"
		echo "若无误，则按回车键确认"
		echo "If it is correct, press Enter to confirm"
		do_you_want_to_continue
		echo "已将启动规则修改为${TARGET}"
		efibootmgr -o ${TARGET}
		remove_boot_mgr
	fi
}
####################
tmoe_system_app_menu() {
	RETURN_TO_WHERE='tmoe_system_app_menu'
	NON_DEBIAN='false'
	DEPENDENCY_01=""
	DEPENDENCY_02=""
	TMOE_APP=$(whiptail --title "SYSTEM" --menu \
		"Which software do you want to install？" 0 50 0 \
		"1" "sudo user group management:sudo用户组管理" \
		"2" "rc.local-systemd:修改开机自启动脚本" \
		"3" "UEFI bootmgr:开机启动项管理" \
		"4" "gnome-system-monitor(资源监视器)" \
		"5" "Grub Customizer(图形化开机引导编辑器)" \
		"6" "gnome log(便于查看系统日志信息)" \
		"7" "boot repair(开机引导修复)" \
		"8" "neofetch(显示当前系统信息和发行版logo)" \
		"9" "yasat:简单的安全审计工具" \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${TMOE_APP}" in
	0 | "") beta_features ;;
	1) tmoe_linux_sudo_user_group_management ;;
	2) modify_rc_local_script ;;
	3) tmoe_uefi_boot_manager ;;
	4)
		DEPENDENCY_01="gnome-system-monitor"
		DEPENDENCY_02=''
		;;
	5) DEPENDENCY_01="grub-customizer" ;;
	6)
		DEPENDENCY_01='gnome-system-tools'
		DEPENDENCY_02='gnome-logs'
		;;
	7) install_boot_repair ;;
	8) start_neofetch ;;
	9) start_yasat ;;
	esac
	##########################
	if [ ! -z "${DEPENDENCY_01}" ]; then
		beta_features_quick_install
	fi
	press_enter_to_return
	tmoe_system_app_menu
}
#############
tmoe_linux_sudo_user_group_management() {
	RETURN_TO_WHERE='tmoe_linux_sudo_user_group_management'
	cd /tmp/
	cat /etc/passwd | grep -Ev 'nologin|halt|shutdown|0:0' | awk -F ':' '{ print $1}' >.tmoe-linux_cache.01
	cat /etc/passwd | grep -Ev 'nologin|halt|shutdown|0:0' | awk -F ':' '{ print $3"|"$4 }' >.tmoe-linux_cache.02
	TMOE_USER_LIST=$(paste -d ' ' .tmoe-linux_cache.01 .tmoe-linux_cache.02 | sed ":a;N;s/\n/ /g;ta")
	rm -f .tmoe-linux_cache.0*
	TMOE_USER_NAME=$(whiptail --title "USER LIST" --menu \
		"您想要将哪个小可爱添加至sudo用户组？\n Which member do you want to add to the sudo group?" 0 0 0 \
		${TMOE_USER_LIST} \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	case ${TMOE_USER_NAME} in
	0 | "") tmoe_system_app_menu ;;
	esac

	SUDO_YES='back返回'
	SUDO_RETURN='true'
	if [ $(cat /etc/sudoers | awk '{print $1}' | grep ${TMOE_USER_NAME}) ]; then
		SUDO_USER_STATUS="检测到${TMOE_USER_NAME}已经是这个家庭的成员啦,ta位于/etc/sudoers文件中"
	elif [ $(cat /etc/group | grep sudo | cut -d ':' -f 4 | grep ${TMOE_USER_NAME}) ]; then
		SUDO_USER_STATUS="检测到${TMOE_USER_NAME}已经是这个家庭的成员啦,ta位于/etc/group文件中"
	else
		SUDO_USER_STATUS="检测到${TMOE_USER_NAME}可能不在sudo用户组里"
		SUDO_YES='add添加♪^∇^*'
		SUDO_RETURN='false'
	fi

	if (whiptail --title "您想要对这个小可爱做什么" --yes-button "${SUDO_YES}" --no-button "del踢走っ °Д °;" --yesno "Do you want to add it to sudo group,or remove it from sudo?\n${SUDO_USER_STATUS}\n您是想要把ta加进sudo这个小家庭，还是踢走ta呢？" 0 50); then
		if [ "${SUDO_RETURN}" = "true" ]; then
			tmoe_linux_sudo_user_group_management
		else
			add_tmoe_sudo
		fi
	else
		del_tmoe_sudo
	fi
	##########################
	press_enter_to_return
	tmoe_linux_sudo_user_group_management
}
##################
del_tmoe_sudo() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		deluser ${TMOE_USER_NAME} sudo || remove_him_from_sudoers
	else
		remove_him_from_sudoers
	fi

	if [ "$?" = '0' ]; then
		echo "${YELLOW}${TMOE_USER_NAME}${RESET}小可爱非常伤心（；´д｀）ゞ，因为您将其移出了${BLUE}sudo${RESET}用户组"
	else
		echo "Sorry,移除${RED}失败${RESET}"
	fi
}
#################
add_tmoe_sudo() {
	#if [ "${LINUX_DISTRO}" = "debian" ]; then
	#	adduser ${TMOE_USER_NAME} sudo
	#else
	add_him_to_sudoers
	#fi

	if [ "$?" = '0' ]; then
		echo "Congratulations,已经将${YELLOW}${TMOE_USER_NAME}${RESET}小可爱添加至${BLUE}sudo${RESET}用户组(｡･∀･)ﾉﾞ"
	else
		echo "Sorry,添加${RED}失败${RESET}"
	fi
}
############
remove_him_from_sudoers() {
	cd /etc
	TMOE_USER_SUDO_LINE=$(cat sudoers | grep -n "^${TMOE_USER_NAME}.*ALL" | tail -n 1 | cut -d ':' -f 1)
	if [ -z "${TMOE_USER_SUDO_LINE}" ]; then
		echo "检测到${YELLOW}${TMOE_USER_NAME}${RESET}不在${BLUE}sudo${RESET}用户组中，此事将不会被报告||o(*°▽°*)o|Юﾞ"
	else
		sed -i "${TMOE_USER_SUDO_LINE}d" sudoers
	fi
}
############
add_him_to_sudoers() {
	TMOE_ROOT_SUDO_LINE=$(cat /etc/sudoers | grep 'root.*ALL' -n | tail -n 1 | cut -d ':' -f 1)
	#TMOE_USER_SUDO_LINE=$((${TMOE_ROOT_SUDO_LINE} + 1))
	if [ -z "${TMOE_ROOT_SUDO_LINE}" ]; then
		sed -i "$ a ${TMOE_USER_NAME}    ALL=(ALL:ALL) ALL" /etc/sudoers
	else
		sed -i "${TMOE_ROOT_SUDO_LINE}a ${TMOE_USER_NAME}    ALL=(ALL:ALL) ALL" /etc/sudoers
	fi
	#usermod -a -G aid_bt,aid_bt_net,aid_inet,aid_net_raw,aid_admin ${TMOE_USER_NAME} 2>/dev/null
	usermod -a -G aid_system,aid_radio,aid_bluetooth,aid_graphics,aid_input,aid_audio,aid_camera,aid_log,aid_compass,aid_mount,aid_wifi,aid_adb,aid_install,aid_media,aid_dhcp,aid_sdcard_rw,aid_vpn,aid_keystore,aid_usb,aid_drm,aid_mdnsr,aid_gps,aid_media_rw,aid_mtp,aid_drmrpc,aid_nfc,aid_sdcard_r,aid_clat,aid_loop_radio,aid_media_drm,aid_package_info,aid_sdcard_pics,aid_sdcard_av,aid_sdcard_all,aid_logd,aid_shared_relro,aid_dbus,aid_tlsdate,aid_media_ex,aid_audioserver,aid_metrics_coll,aid_metricsd,aid_webserv,aid_debuggerd,aid_media_codec,aid_cameraserver,aid_firewall,aid_trunks,aid_nvram,aid_dns,aid_dns_tether,aid_webview_zygote,aid_vehicle_network,aid_media_audio,aid_media_video,aid_media_image,aid_tombstoned,aid_media_obb,aid_ese,aid_ota_update,aid_automotive_evs,aid_lowpan,aid_hsm,aid_reserved_disk,aid_statsd,aid_incidentd,aid_secure_element,aid_lmkd,aid_llkd,aid_iorapd,aid_gpu_service,aid_network_stack,aid_shell,aid_cache,aid_diag,aid_oem_reserved_start,aid_oem_reserved_end,aid_net_bt_admin,aid_net_bt,aid_inet,aid_net_raw,aid_net_admin,aid_net_bw_stats,aid_net_bw_acct,aid_readproc,aid_wakelock,aid_uhid,aid_everybody,aid_misc,aid_nobody,aid_app_start,aid_app_end,aid_cache_gid_start,aid_cache_gid_end,aid_ext_gid_start,aid_ext_gid_end,aid_ext_cache_gid_start,aid_ext_cache_gid_end,aid_shared_gid_start,aid_shared_gid_end,aid_overflowuid,aid_isolated_start,aid_isolated_end,aid_user_offset ${TMOE_USER_NAME} 2>/dev/null
	cat /etc/sudoers
}
###############
creat_rc_local_startup_script() {
	cat >rc.local <<'ENDOFRCLOCAL'
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
# 请在 exit0 这一行(最末行)以上之处添加您在开机时需要执行的脚本或命令。
# 例如:您写了一个开机自动挂载硬盘的脚本，该文件位于/usr/local/bin/mount-zfs-filesystem
# 注：对于外置USB硬盘盒而言，若将其写进/etc/fstab，且硬盘在系统开机前未连接或连接不稳定，则有可能导致开机出现异常，故您使用了脚本来解决。
# 若您需要在开机时自动执行该脚本，则您可以输入以下那一行命令。
# bash /usr/local/bin/mount-zfs-filesystem
# '#'为注释符号，去掉该符号生效。

exit 0
ENDOFRCLOCAL
	chmod +x rc.local
	systemctl daemon-reload 2>/dev/null
}
#################
creat_rc_local_systemd_script() {
	cat >/etc/systemd/system/rc-local.service <<-'ENDOFSYSTEMD'
		[Unit]
		Description=/etc/rc.local
		ConditionPathExists=/etc/rc.local
		 
		[Service]
		Type=forking
		ExecStart=/etc/rc.local start
		TimeoutSec=0
		StandardOutput=tty
		RemainAfterExit=yes
		SysVStartPriority=99
		 
		[Install]
		WantedBy=multi-user.target
	ENDOFSYSTEMD
}
#################
modify_rc_local_script() {
	cd /etc
	if [ ! -e "rc.local" ]; then
		creat_rc_local_startup_script
	fi
	cat <<-EOF
		${GREEN}systemctl enable rc-local${RESET}  ${BLUE}--开机自启${RESET}
		${GREEN}systemctl disable rc-local${RESET}  ${BLUE}--禁用开机自启${RESET}
		${GREEN}systemctl status rc-local${RESET}  ${BLUE}--查看该服务进程状态${RESET}
		${GREEN}systemctl start rc-local${RESET}  ${BLUE}--启动${RESET}
		${GREEN}systemctl stop rc-local${RESET}  ${BLUE}--停止${RESET}
	EOF

	if [ ! -e "/etc/systemd/system/rc-local.service" ]; then
		creat_rc_local_systemd_script
		nano rc.local
		echo "是否将其设置为开机自启？"
		do_you_want_to_continue
		systemctl enable rc-local.service
	else
		nano rc.local
	fi
}
##################
start_neofetch() {
	if [ ! $(command -v neofetch) ]; then
		cd /usr/local/bin
		aria2c --allow-overwrite=true -o neofetch 'https://gitee.com/mirrors/neofetch/raw/master/neofetch'
		chmod +x neofetch
	fi
	neofetch
}
#############
start_yasat() {
	if [ ! $(command -v yasat) ]; then
		DEPENDENCY_01=''
		DEPENDENCY_02='yasat'
		beta_features_quick_install
	fi
	yasat --full-scan
}
############
install_boot_repair() {
	non_debian_function
	if [ ! $(command -v add-apt-repository) ]; then
		apt update
		apt install -y software-properties-common
	fi
	add-apt-repository ppa:yannubuntu/boot-repair
	if [ "${DEBIAN_DISTRO}" != 'ubuntu' ]; then
		apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 60D8DA0B
	fi
	apt update
	apt install -y boot-repair
}
#################
tmoe_system_app_menu
