#!/usr/bin/env bash
#######################
qemu_main() {
	case "$1" in
	-x64qemu)
		start_tmoe_qemu_manager
		;;
	-arm64qemu)
		start_tmoe_qemu_aarch64_manager
		;;
	-m | *)
		install_container_and_virtual_machine
		;;
	esac
}
#############################
install_aqemu() {
	DEPENDENCY_02='aqemu'
	#qemu-block-extra
	beta_features_quick_install
}
#########################
install_virt_manager() {
	DEPENDENCY_02='virt-manager'
	beta_features_quick_install
}
############
install_gnome_boxes() {
	DEPENDENCY_02='gnome-boxes'
	beta_features_quick_install
}
############
qemu_system_menu() {
	RETURN_TO_WHERE='qemu_system_menu'
	DEPENDENCY_01=''
	VIRTUAL_TECH=$(
		whiptail --title "qemu-system" --menu "您想要选择哪一项呢？" 0 0 0 \
			"1" "tmoe-qemu:x86_64虚拟机管理" \
			"2" "tmoe-qemu:arm64虚拟机管理" \
			"3" "aqemu(QEMU和KVM的Qt5前端)" \
			"4" "virt-manager(红帽共享的GUI虚拟机管理器)" \
			"5" "gnome-boxes(简单地管理远程和本地虚拟系统)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) start_tmoe_qemu_manager ;;
	2) start_tmoe_qemu_aarch64_manager ;;
	3) install_aqemu ;;
	4) install_virt_manager ;;
	5) install_gnome_boxes ;;
	esac
	###############
	press_enter_to_return
	qemu_system_menu
}
#############
install_container_and_virtual_machine() {
	RETURN_TO_WHERE='install_container_and_virtual_machine'

	VIRTUAL_TECH=$(
		whiptail --title "虚拟化与api的转换" --menu "Which option do you want to choose?" 0 0 0 \
			"1" "💻 qemu:开源、跨平台的虚拟机" \
			"2" "🐳 docker:开源的应用容器引擎" \
			"3" "📀 download iso:下载镜像(Android,linux等)" \
			"4" "🖥️ VirtualBox(甲骨文开源虚拟机{x64})" \
			"5" "🍷 wine:调用win api并即时转换" \
			"6" "🥡 anbox(Android in a box)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"00" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") beta_features ;;
	00) tmoe_linux_tool_menu ;;
	1) qemu_system_menu ;;
	2) tmoe_docker_menu ;;
	3) download_virtual_machine_iso_file ;;
	4) install_virtual_box ;;
	5) wine_menu ;;
	6) install_anbox ;;
	esac
	###############
	press_enter_to_return
	install_container_and_virtual_machine
}
#"4" "OpenMediaVault(基于debian的NAS网络连接存储解决方案)" \
#4) install_open_media_vault ;;
#####################
check_qemu_aarch64_install() {
	if [ ! $(command -v qemu-system-aarch64) ]; then
		if grep -q 'VERSION_CODENAME=buster' /etc/os-release; then
			DEPENDENCY_01='-t buster-backports qemu-system-arm'
		else
			DEPENDENCY_01='qemu-system-arm'
		fi
		DEPENDENCY_02='qemu'
		printf "%s\n" "请按回车键安装qemu-system-arm,否则您将无法使用本功能"
		beta_features_quick_install
	fi
}
###########
creat_qemu_aarch64_startup_script() {
	mkdir -p ${CONFIG_FOLDER}
	cd ${CONFIG_FOLDER}
	cat >startqemu_aarch64_2020060314 <<-'EndOFqemu'
		#!/usr/bin/env bash
		export DISPLAY=127.0.0.1:0
		export PULSE_SERVER=127.0.0.1
		START_QEMU_SCRIPT_PATH='/usr/local/bin/startqemu'
		if grep -q '\-vnc \:' "${START_QEMU_SCRIPT_PATH}"; then
			CURRENT_PORT=$(sed -n p ${START_QEMU_SCRIPT_PATH} | grep '\-vnc ' | tail -n 1 | awk '{print $2}' | cut -d ':' -f 2 | tail -n 1)
			CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
			printf "%s\n" "正在为您启动qemu虚拟机，本机默认VNC访问地址为localhost:${CURRENT_VNC_PORT}"
			echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${CURRENT_VNC_PORT}
		else
			printf "%s\n" "检测到您当前没有使用VNC服务，若您使用的是Xserver则可无视以下说明"
			printf "%s\n" "请自行添加端口号"
			printf "%s\n" "spice默认端口号为5931"
			printf "%s\n" "正在为您启动qemu虚拟机"
			printf "%s\n" "本机localhost"
			echo The LAN ip 局域网ip $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2)
		fi

		/usr/bin/qemu-system-aarch64 \
			-monitor stdio \
			-smp 4 \
			-cpu max \
			-machine virt \
			--accel tcg \
			-vga virtio \
			-m 2048 \
			-hda ${HOME}/sd/Download/backup/debian-10.4.1-20200515-tmoe_arm64.qcow2 \
			-virtfs local,id=shared_folder_dev_0,path=${HOME},security_model=none,mount_tag=shared0 \
			-boot order=cd,menu=on \
			-net nic \
			-net user,hostfwd=tcp::2888-0.0.0.0:22,hostfwd=tcp::5903-0.0.0.0:5901,hostfwd=tcp::49080-0.0.0.0:80 \
			-rtc base=localtime \
			-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
			-vnc :2 \
			-usb \
			-name "tmoe-linux-aarch64-qemu"
	EndOFqemu
	chmod +x startqemu_aarch64_2020060314
	cp -pf startqemu_aarch64_2020060314 /usr/local/bin/startqemu
}
######################
tmoe_qemu_aarch64_cpu_manager() {
	RETURN_TO_WHERE='tmoe_qemu_aarch64_cpu_manager'
	VIRTUAL_TECH=$(
		whiptail --title "CPU" --menu "Which configuration do you want to modify?" 15 50 6 \
			"1" "CPU cores处理器核心数" \
			"2" "cpu model/type(型号/类型)" \
			"3" "multithreading多线程" \
			"4" "machine机器类型" \
			"5" "kvm/tcg/xen加速类型" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) modify_qemu_cpu_cores_number ;;
	2) modify_qemu_aarch64_tmoe_cpu_type ;;
	3) enable_tmoe_qemu_cpu_multi_threading ;;
	4) modify_qemu_aarch64_tmoe_machine_model ;;
	5) modify_qemu_machine_accel ;;
	esac
	###############
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
start_tmoe_qemu_aarch64_manager() {
	RETURN_TO_WHERE='start_tmoe_qemu_aarch64_manager'
	RETURN_TO_MENU='start_tmoe_qemu_aarch64_manager'
	check_qemu_aarch64_install
	cd /usr/local/bin/
	if [ ! -e "${HOME}/.config/tmoe-linux/startqemu_aarch64_2020060314" ]; then
		printf "%s\n" "启用arm64虚拟机将重置startqemu为arm64的配置"
		rm -fv ${HOME}/.config/tmoe-linux/startqemu*
		creat_qemu_aarch64_startup_script
	fi

	VIRTUAL_TECH=$(
		whiptail --title "aarch64 qemu虚拟机管理器" --menu "v2020-06-02 beta" 0 50 0 \
			"1" "Creat a new VM 新建虚拟机" \
			"2" "Multi-VM多虚拟机管理" \
			"3" "edit script manually手动修改配置脚本" \
			"4" "CPU管理" \
			"5" "Display and audio显示与音频" \
			"6" "RAM运行内存" \
			"7" "💾 disk manager磁盘管理器" \
			"8" "FAQ常见问题" \
			"9" "exposed ports端口映射/转发" \
			"10" "network card model网卡" \
			"11" "restore to default恢复到默认" \
			"12" "uefi/legacy bios(开机引导固件)" \
			"13" "Input devices输入设备" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) creat_a_new_tmoe_qemu_vm ;;
	2) multi_qemu_vm_management ;;
	3) nano startqemu ;;
	4) tmoe_qemu_aarch64_cpu_manager ;;
	5) tmoe_qemu_display_settings ;;
	6) modify_qemu_ram_size ;;
	7) tmoe_qemu_disk_manager ;;
	8) tmoe_qemu_faq ;;
	9) modify_qemu_exposed_ports ;;
	10) modify_qemu_tmoe_network_card ;;
	11) creat_qemu_startup_script ;;
	12) choose_qemu_bios_or_uefi_file ;;
	13) tmoe_qemu_input_devices ;;
	esac
	###############
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
switch_tmoe_qemu_network_card_to_default() {
	sed -i 's/-net nic.*/-net nic \\/' startqemu
	printf "%s\n" "已经将默认网卡切换为未指定状态"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##########
modify_qemu_tmoe_network_card() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='modify_qemu_tmoe_network_card'
	if grep -q '\-net nic,model' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-net nic,model' | tail -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	else
		CURRENT_VALUE='未指定'
	fi
	VIRTUAL_TECH=$(
		whiptail --title "网卡型号" --menu "Please select the network card model.\n当前为${CURRENT_VALUE}" 16 50 7 \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"00" "未指定" \
			"01" "e1000:alias e1000-82540em" \
			"02" "e1000-82544gc:Intel Gigabit Ethernet" \
			"03" "e1000-82545em" \
			"04" "e1000e:Intel 82574L GbE Controller" \
			"05" "Realtek rtl8139" \
			"06" "virtio-net-pci" \
			"07" "i82550:Intel i82550 Ethernet" \
			"08" "i82551" \
			"09" "i82557a" \
			"10" "i82557b" \
			"11" "i82557c" \
			"12" "i82558a" \
			"13" "i82558b" \
			"14" "i82559a" \
			"15" "i82559b" \
			"16" "i82559er" \
			"17" "i82562" \
			"18" "i82801" \
			"19" "ne2k_pci" \
			"20" "ne2k_isa" \
			"21" "pcnet" \
			"22" "smc91c111" \
			"23" "lance" \
			"24" "mcf_fec" \
			"25" "vmxnet3:VMWare Paravirtualized" \
			"26" "rocker Switch" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") modify_tmoe_qemu_network_settings ;;
	00) switch_tmoe_qemu_network_card_to_default ;;
	01) TMOE_QEMU_NETWORK_CARD="e1000" ;;
	02) TMOE_QEMU_NETWORK_CARD="e1000-82544gc" ;;
	03) TMOE_QEMU_NETWORK_CARD="e1000-82545em" ;;
	04) TMOE_QEMU_NETWORK_CARD="e1000e" ;;
	05) TMOE_QEMU_NETWORK_CARD="rtl8139" ;;
	06) TMOE_QEMU_NETWORK_CARD="virtio-net-pci" ;;
	07) TMOE_QEMU_NETWORK_CARD="i82550" ;;
	08) TMOE_QEMU_NETWORK_CARD="i82551" ;;
	09) TMOE_QEMU_NETWORK_CARD="i82557a" ;;
	10) TMOE_QEMU_NETWORK_CARD="i82557b" ;;
	11) TMOE_QEMU_NETWORK_CARD="i82557c" ;;
	12) TMOE_QEMU_NETWORK_CARD="i82558a" ;;
	13) TMOE_QEMU_NETWORK_CARD="i82558b" ;;
	14) TMOE_QEMU_NETWORK_CARD="i82559a" ;;
	15) TMOE_QEMU_NETWORK_CARD="i82559b" ;;
	16) TMOE_QEMU_NETWORK_CARD="i82559er" ;;
	17) TMOE_QEMU_NETWORK_CARD="i82562" ;;
	18) TMOE_QEMU_NETWORK_CARD="i82801" ;;
	19) TMOE_QEMU_NETWORK_CARD="ne2k_pci" ;;
	20) TMOE_QEMU_NETWORK_CARD="ne2k_isa" ;;
	21) TMOE_QEMU_NETWORK_CARD="pcnet" ;;
	22) TMOE_QEMU_NETWORK_CARD="smc91c111" ;;
	23) TMOE_QEMU_NETWORK_CARD="lance" ;;
	24) TMOE_QEMU_NETWORK_CARD="mcf_fec" ;;
	25) TMOE_QEMU_NETWORK_CARD="vmxnet3" ;;
	26) TMOE_QEMU_NETWORK_CARD="rocker" ;;
	esac
	###############
	sed -i "s/-net nic.*/-net nic,model=${TMOE_QEMU_NETWORK_CARD} \\\/" startqemu
	printf "%s\n" "您已将network card修改为${TMOE_QEMU_NETWORK_CARD}"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
###########
modify_qemu_aarch64_tmoe_machine_model() {
	cd /usr/local/bin/
	#qemu-system-aarch64 -machine help  >001
	CURRENT_VALUE=$(cat startqemu | grep '\-machine' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	VIRTUAL_TECH=$(
		whiptail --title "机器型号" --menu "Please select the machine model.\n默认为virt,当前为${CURRENT_VALUE}" 0 0 0 \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"01" "akita:Sharp SL-C1000 (Akita) PDA (PXA270)" \
			"02" "ast2500-evb:Aspeed AST2500 EVB (ARM1176)" \
			"03" "ast2600-evb:Aspeed AST2600 EVB (Cortex A7)" \
			"04" "borzoi:Sharp SL-C3100 (Borzoi) PDA (PXA270)" \
			"05" "canon-a1100:Canon PowerShot A1100 IS" \
			"06" "cheetah:Palm Tungsten|E aka. Cheetah PDA (OMAP310)" \
			"07" "collie:Sharp SL-5500 (Collie) PDA (SA-1110)" \
			"08" "connex:Gumstix Connex (PXA255)" \
			"09" "cubieboard:cubietech cubieboard (Cortex-A8)" \
			"10" "emcraft-sf2:SmartFusion2 SOM kit from Emcraft (M2S010)" \
			"11" "highbank:Calxeda Highbank (ECX-1000)" \
			"12" "imx25-pdk:ARM i.MX25 PDK board (ARM926)" \
			"13" "integratorcp:ARM Integrator/CP (ARM926EJ-S)" \
			"14" "kzm:ARM KZM Emulation Baseboard (ARM1136)" \
			"15" "lm3s6965evb:Stellaris LM3S6965EVB" \
			"16" "lm3s811evb:Stellaris LM3S811EVB" \
			"17" "mainstone:Mainstone II (PXA27x)" \
			"18" "mcimx6ul-evk:Freescale i.MX6UL Evaluation Kit (Cortex A7)" \
			"19" "mcimx7d-sabre:Freescale i.MX7 DUAL SABRE (Cortex A7)" \
			"20" "microbit:BBC micro:bit" \
			"21" "midway:Calxeda Midway (ECX-2000)" \
			"22" "mps2-an385:ARM MPS2 with AN385 FPGA image for Cortex-M3" \
			"23" "mps2-an505:ARM MPS2 with AN505 FPGA image for Cortex-M33" \
			"24" "mps2-an511:ARM MPS2 with AN511 DesignStart FPGA image for Cortex-M3" \
			"25" "mps2-an521:ARM MPS2 with AN521 FPGA image for dual Cortex-M33" \
			"26" "musca-a:ARM Musca-A board (dual Cortex-M33)" \
			"27" "musca-b1:ARM Musca-B1 board (dual Cortex-M33)" \
			"28" "musicpal:Marvell 88w8618 / MusicPal (ARM926EJ-S)" \
			"29" "n800:Nokia N800 tablet aka. RX-34 (OMAP2420)" \
			"30" "n810:Nokia N810 tablet aka. RX-44 (OMAP2420)" \
			"31" "netduino2:Netduino 2 Machine" \
			"32" "netduinoplus2:Netduino Plus 2 Machine" \
			"33" "none:empty machine" \
			"34" "nuri:Samsung NURI board (Exynos4210)" \
			"35" "orangepi-pc:Orange Pi PC" \
			"36" "palmetto-bmc:OpenPOWER Palmetto BMC (ARM926EJ-S)" \
			"37" "raspi2:Raspberry Pi 2B" \
			"38" "raspi3:Raspberry Pi 3B" \
			"39" "realview-eb:ARM RealView Emulation Baseboard (ARM926EJ-S)" \
			"40" "realview-eb-mpcore:ARM RealView Emulation Baseboard (ARM11MPCore)" \
			"41" "realview-pb-a8:ARM RealView Platform Baseboard for Cortex-A8" \
			"42" "realview-pbx-a9:ARM RealView Platform Baseboard Explore for Cortex-A9" \
			"43" "romulus-bmc:OpenPOWER Romulus BMC (ARM1176)" \
			"44" "sabrelite:Freescale i.MX6 Quad SABRE Lite Board (Cortex A9)" \
			"45" "sbsa-ref:QEMU 'SBSA Reference' ARM Virtual Machine" \
			"46" "smdkc210:Samsung SMDKC210 board (Exynos4210)" \
			"47" "spitz:Sharp SL-C3000 (Spitz) PDA (PXA270)" \
			"48" "swift-bmc:OpenPOWER Swift BMC (ARM1176)" \
			"49" "sx1:Siemens SX1 (OMAP310) V2" \
			"50" "sx1-v1:Siemens SX1 (OMAP310) V1" \
			"51" "tacoma-bmc:Aspeed AST2600 EVB (Cortex A7)" \
			"52" "terrier:Sharp SL-C3200 (Terrier) PDA (PXA270)" \
			"53" "tosa:Sharp SL-6000 (Tosa) PDA (PXA255)" \
			"54" "verdex:Gumstix Verdex (PXA270)" \
			"55" "versatileab:ARM Versatile/AB (ARM926EJ-S)" \
			"56" "versatilepb:ARM Versatile/PB (ARM926EJ-S)" \
			"57" "vexpress-a15:ARM Versatile Express for Cortex-A15" \
			"58" "vexpress-a9:ARM Versatile Express for Cortex-A9" \
			"59" "virt-2.10:QEMU 2.10 ARM Virtual Machine" \
			"60" "virt-2.11:QEMU 2.11 ARM Virtual Machine" \
			"61" "virt-2.12:QEMU 2.12 ARM Virtual Machine" \
			"62" "virt-2.6:QEMU 2.6 ARM Virtual Machine" \
			"63" "virt-2.7:QEMU 2.7 ARM Virtual Machine" \
			"64" "virt-2.8:QEMU 2.8 ARM Virtual Machine" \
			"65" "virt-2.9:QEMU 2.9 ARM Virtual Machine" \
			"66" "virt-3.0:QEMU 3.0 ARM Virtual Machine" \
			"67" "virt-3.1:QEMU 3.1 ARM Virtual Machine" \
			"68" "virt-4.0:QEMU 4.0 ARM Virtual Machine" \
			"69" "virt-4.1:QEMU 4.1 ARM Virtual Machine" \
			"70" "virt-4.2:QEMU 4.2 ARM Virtual Machine" \
			"71" "virt:QEMU 5.0 ARM Virtual Machine (alias of virt-5.0)" \
			"72" "virt-5.0:QEMU 5.0 ARM Virtual Machine" \
			"73" "witherspoon-bmc:OpenPOWER Witherspoon BMC (ARM1176)" \
			"74" "xilinx-zynq-a9:Xilinx Zynq Platform Baseboard for Cortex-A9" \
			"75" "xlnx-versal-virt:Xilinx Versal Virtual development board" \
			"76" "xlnx-zcu102:Xilinx ZynqMP ZCU102 board with 4xA53s and 2xR5Fs based on the value of smp" \
			"77" "z2:Zipit Z2 (PXA27x)" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	01) TMOE_AARCH64_QEMU_MACHINE="akita" ;;
	02) TMOE_AARCH64_QEMU_MACHINE="ast2500-evb" ;;
	03) TMOE_AARCH64_QEMU_MACHINE="ast2600-evb" ;;
	04) TMOE_AARCH64_QEMU_MACHINE="borzoi" ;;
	05) TMOE_AARCH64_QEMU_MACHINE="canon-a1100" ;;
	06) TMOE_AARCH64_QEMU_MACHINE="cheetah" ;;
	07) TMOE_AARCH64_QEMU_MACHINE="collie" ;;
	08) TMOE_AARCH64_QEMU_MACHINE="connex" ;;
	09) TMOE_AARCH64_QEMU_MACHINE="cubieboard" ;;
	10) TMOE_AARCH64_QEMU_MACHINE="emcraft-sf2" ;;
	11) TMOE_AARCH64_QEMU_MACHINE="highbank" ;;
	12) TMOE_AARCH64_QEMU_MACHINE="imx25-pdk" ;;
	13) TMOE_AARCH64_QEMU_MACHINE="integratorcp" ;;
	14) TMOE_AARCH64_QEMU_MACHINE="kzm" ;;
	15) TMOE_AARCH64_QEMU_MACHINE="lm3s6965evb" ;;
	16) TMOE_AARCH64_QEMU_MACHINE="lm3s811evb" ;;
	17) TMOE_AARCH64_QEMU_MACHINE="mainstone" ;;
	18) TMOE_AARCH64_QEMU_MACHINE="mcimx6ul-evk" ;;
	19) TMOE_AARCH64_QEMU_MACHINE="mcimx7d-sabre" ;;
	20) TMOE_AARCH64_QEMU_MACHINE="microbit" ;;
	21) TMOE_AARCH64_QEMU_MACHINE="midway" ;;
	22) TMOE_AARCH64_QEMU_MACHINE="mps2-an385" ;;
	23) TMOE_AARCH64_QEMU_MACHINE="mps2-an505" ;;
	24) TMOE_AARCH64_QEMU_MACHINE="mps2-an511" ;;
	25) TMOE_AARCH64_QEMU_MACHINE="mps2-an521" ;;
	26) TMOE_AARCH64_QEMU_MACHINE="musca-a" ;;
	27) TMOE_AARCH64_QEMU_MACHINE="musca-b1" ;;
	28) TMOE_AARCH64_QEMU_MACHINE="musicpal" ;;
	29) TMOE_AARCH64_QEMU_MACHINE="n800" ;;
	30) TMOE_AARCH64_QEMU_MACHINE="n810" ;;
	31) TMOE_AARCH64_QEMU_MACHINE="netduino2" ;;
	32) TMOE_AARCH64_QEMU_MACHINE="netduinoplus2" ;;
	33) TMOE_AARCH64_QEMU_MACHINE="none" ;;
	34) TMOE_AARCH64_QEMU_MACHINE="nuri" ;;
	35) TMOE_AARCH64_QEMU_MACHINE="orangepi-pc" ;;
	36) TMOE_AARCH64_QEMU_MACHINE="palmetto-bmc" ;;
	37) TMOE_AARCH64_QEMU_MACHINE="raspi2" ;;
	38) TMOE_AARCH64_QEMU_MACHINE="raspi3" ;;
	39) TMOE_AARCH64_QEMU_MACHINE="realview-eb" ;;
	40) TMOE_AARCH64_QEMU_MACHINE="realview-eb-mpcore" ;;
	41) TMOE_AARCH64_QEMU_MACHINE="realview-pb-a8" ;;
	42) TMOE_AARCH64_QEMU_MACHINE="realview-pbx-a9" ;;
	43) TMOE_AARCH64_QEMU_MACHINE="romulus-bmc" ;;
	44) TMOE_AARCH64_QEMU_MACHINE="sabrelite" ;;
	45) TMOE_AARCH64_QEMU_MACHINE="sbsa-ref" ;;
	46) TMOE_AARCH64_QEMU_MACHINE="smdkc210" ;;
	47) TMOE_AARCH64_QEMU_MACHINE="spitz" ;;
	48) TMOE_AARCH64_QEMU_MACHINE="swift-bmc" ;;
	49) TMOE_AARCH64_QEMU_MACHINE="sx1" ;;
	50) TMOE_AARCH64_QEMU_MACHINE="sx1-v1" ;;
	51) TMOE_AARCH64_QEMU_MACHINE="tacoma-bmc" ;;
	52) TMOE_AARCH64_QEMU_MACHINE="terrier" ;;
	53) TMOE_AARCH64_QEMU_MACHINE="tosa" ;;
	54) TMOE_AARCH64_QEMU_MACHINE="verdex" ;;
	55) TMOE_AARCH64_QEMU_MACHINE="versatileab" ;;
	56) TMOE_AARCH64_QEMU_MACHINE="versatilepb" ;;
	57) TMOE_AARCH64_QEMU_MACHINE="vexpress-a15" ;;
	58) TMOE_AARCH64_QEMU_MACHINE="vexpress-a9" ;;
	59) TMOE_AARCH64_QEMU_MACHINE="virt-2.10" ;;
	60) TMOE_AARCH64_QEMU_MACHINE="virt-2.11" ;;
	61) TMOE_AARCH64_QEMU_MACHINE="virt-2.12" ;;
	62) TMOE_AARCH64_QEMU_MACHINE="virt-2.6" ;;
	63) TMOE_AARCH64_QEMU_MACHINE="virt-2.7" ;;
	64) TMOE_AARCH64_QEMU_MACHINE="virt-2.8" ;;
	65) TMOE_AARCH64_QEMU_MACHINE="virt-2.9" ;;
	66) TMOE_AARCH64_QEMU_MACHINE="virt-3.0" ;;
	67) TMOE_AARCH64_QEMU_MACHINE="virt-3.1" ;;
	68) TMOE_AARCH64_QEMU_MACHINE="virt-4.0" ;;
	69) TMOE_AARCH64_QEMU_MACHINE="virt-4.1" ;;
	70) TMOE_AARCH64_QEMU_MACHINE="virt-4.2" ;;
	71) TMOE_AARCH64_QEMU_MACHINE="virt" ;;
	72) TMOE_AARCH64_QEMU_MACHINE="virt-5.0" ;;
	73) TMOE_AARCH64_QEMU_MACHINE="witherspoon-bmc" ;;
	74) TMOE_AARCH64_QEMU_MACHINE="xilinx-zynq-a9" ;;
	75) TMOE_AARCH64_QEMU_MACHINE="xlnx-versal-virt" ;;
	76) TMOE_AARCH64_QEMU_MACHINE="xlnx-zcu102" ;;
	77) TMOE_AARCH64_QEMU_MACHINE="z2" ;;
	esac
	###############
	sed -i "s@-machine .*@-machine ${TMOE_AARCH64_QEMU_MACHINE} \\\@" startqemu
	printf "%s\n" "您已将machine修改为${TMOE_AARCH64_QEMU_MACHINE}"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##############
modify_qemu_aarch64_tmoe_cpu_type() {
	cd /usr/local/bin/
	CURRENT_VALUE=$(cat startqemu | grep '\-cpu' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	VIRTUAL_TECH=$(
		whiptail --title "CPU" --menu "默认为max,当前为${CURRENT_VALUE}" 0 0 0 \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"01" "arm1026" \
			"02" "arm1136" \
			"03" "arm1136-r2" \
			"04" "arm1176" \
			"05" "arm11mpcore" \
			"06" "arm926" \
			"07" "arm946" \
			"08" "cortex-a15" \
			"09" "cortex-a53" \
			"10" "cortex-a57" \
			"11" "cortex-a7" \
			"12" "cortex-a72" \
			"13" "cortex-a8" \
			"14" "cortex-a9" \
			"15" "cortex-m0" \
			"16" "cortex-m3" \
			"17" "cortex-m33" \
			"18" "cortex-m4" \
			"19" "cortex-m7" \
			"20" "cortex-r5" \
			"21" "cortex-r5f" \
			"22" "host" \
			"23" "max" \
			"24" "pxa250" \
			"25" "pxa255" \
			"26" "pxa260" \
			"27" "pxa261" \
			"28" "pxa262" \
			"29" "pxa270-a0" \
			"30" "pxa270-a1" \
			"31" "pxa270" \
			"32" "pxa270-b0" \
			"33" "pxa270-b1" \
			"34" "pxa270-c0" \
			"35" "pxa270-c5" \
			"36" "sa1100" \
			"37" "sa1110" \
			"38" "ti925t" \
			3>&1 1>&2 2>&3
	)
	#############
	#00) disable_tmoe_qemu_cpu ;;F
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	01) TMOE_AARCH64_QEMU_CPU_TYPE="arm1026" ;;
	02) TMOE_AARCH64_QEMU_CPU_TYPE="arm1136" ;;
	03) TMOE_AARCH64_QEMU_CPU_TYPE="arm1136-r2" ;;
	04) TMOE_AARCH64_QEMU_CPU_TYPE="arm1176" ;;
	05) TMOE_AARCH64_QEMU_CPU_TYPE="arm11mpcore" ;;
	06) TMOE_AARCH64_QEMU_CPU_TYPE="arm926" ;;
	07) TMOE_AARCH64_QEMU_CPU_TYPE="arm946" ;;
	08) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a15" ;;
	09) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a53" ;;
	10) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a57" ;;
	11) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a7" ;;
	12) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a72" ;;
	13) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a8" ;;
	14) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-a9" ;;
	15) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m0" ;;
	16) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m3" ;;
	17) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m33" ;;
	18) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m4" ;;
	19) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-m7" ;;
	20) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-r5" ;;
	21) TMOE_AARCH64_QEMU_CPU_TYPE="cortex-r5f" ;;
	22) TMOE_AARCH64_QEMU_CPU_TYPE="host" ;;
	23) TMOE_AARCH64_QEMU_CPU_TYPE="max" ;;
	24) TMOE_AARCH64_QEMU_CPU_TYPE="pxa250" ;;
	25) TMOE_AARCH64_QEMU_CPU_TYPE="pxa255" ;;
	26) TMOE_AARCH64_QEMU_CPU_TYPE="pxa260" ;;
	27) TMOE_AARCH64_QEMU_CPU_TYPE="pxa261" ;;
	28) TMOE_AARCH64_QEMU_CPU_TYPE="pxa262" ;;
	29) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-a0" ;;
	30) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-a1" ;;
	31) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270" ;;
	32) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-b0" ;;
	33) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-b1" ;;
	34) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-c0" ;;
	35) TMOE_AARCH64_QEMU_CPU_TYPE="pxa270-c5" ;;
	36) TMOE_AARCH64_QEMU_CPU_TYPE="sa1100" ;;
	37) TMOE_AARCH64_QEMU_CPU_TYPE="sa1110" ;;
	38) TMOE_AARCH64_QEMU_CPU_TYPE="ti925t" ;;
	esac
	###############
	sed -i "s@-cpu .*@-cpu ${TMOE_AARCH64_QEMU_CPU_TYPE} \\\@" startqemu
	printf "%s\n" "您已将cpu修改为${TMOE_AARCH64_QEMU_CPU_TYPE}"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
disable_tmoe_qemu_sound_card() {
	sed -i '/-soundhw /d' startqemu
	printf "%s\n" "禁用完成"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
tmoe_modify_qemu_sound_card() {
	sed -i '/-soundhw /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -soundhw tmoe_cpu_config_test \\\n/' startqemu
	sed -i "s@-soundhw tmoe_cpu_config_test@-soundhw ${QEMU_SOUNDHW}@" startqemu
	printf "%s\n" "您已将soundhw修改为${QEMU_SOUNDHW}"
	printf "%s\n" "修改完成，将在下次启动qemu虚拟机时生效"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
###########
modify_qemu_aarch64_tmoe_sound_card() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='modify_qemu_aarch64_tmoe_sound_card'
	if grep -q '\-soundhw ' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-soundhw ' | tail -n 1 | awk '{print $2}')
	else
		CURRENT_VALUE='默认'
	fi
	VIRTUAL_TECH=$(
		whiptail --title "声卡型号" --menu "Please select the sound card model.\n默认未启用,当前为${CURRENT_VALUE}" 16 50 7 \
			"1" "es1370(ENSONIQ AudioPCI ES1370)" \
			"2" "ac97(Intel 82801AA AC97)" \
			"3" "adlib:Yamaha YM3812 (OPL2)" \
			"4" "hda(Intel HD Audio)" \
			"5" "disable禁用声卡" \
			"6" "all启用所有" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) QEMU_SOUNDHW='es1370' ;;
	2) QEMU_SOUNDHW='ac97' ;;
	3) QEMU_SOUNDHW='adlib' ;;
	4) QEMU_SOUNDHW='hda' ;;
	5) disable_tmoe_qemu_sound_card ;;
	6) QEMU_SOUNDHW='all' ;;
	esac
	###############
	#-soundhw cs4231a \
	#sed -i "s@-soundhw .*@-soundhw ${QEMU_SOUNDHW} \\\@" startqemu
	tmoe_modify_qemu_sound_card
}
#############
check_qemu_install() {
	DEPENDENCY_01='qemu'
	DEPENDENCY_02=''
	if [ ! $(command -v qemu-system-x86_64) ]; then
		if [ "${LINUX_DISTRO}" = 'debian' ]; then
			if grep -q 'VERSION_CODENAME=buster' /etc/os-release; then
				DEPENDENCY_01='-t buster-backports qemu qemu-system-x86'
			else
				DEPENDENCY_01='qemu qemu-system-x86'
			fi
			DEPENDENCY_01='qemu qemu-system-x86'
			DEPENDENCY_02='qemu-system-gui'
		elif [ "${LINUX_DISTRO}" = 'alpine' ]; then
			DEPENDENCY_01='qemu qemu-system-x86_64 qemu-system-i386'
			DEPENDENCY_02='qemu-system-aarch64'
		elif [ "${LINUX_DISTRO}" = 'arch' ]; then
			DEPENDENCY_02='qemu-arch-extra'
		fi
		beta_features_quick_install
	fi
}
#############
creat_qemu_startup_script() {
	mkdir -p ${CONFIG_FOLDER}
	cd ${CONFIG_FOLDER}
	cat >startqemu_amd64_2020060314 <<-'EndOFqemu'
		#!/usr/bin/env bash
		export DISPLAY=127.0.0.1:0
		export PULSE_SERVER=127.0.0.1
		START_QEMU_SCRIPT_PATH='/usr/local/bin/startqemu'
		if grep -q '\-vnc \:' "${START_QEMU_SCRIPT_PATH}"; then
			CURRENT_PORT=$(sed -n p ${START_QEMU_SCRIPT_PATH} | grep '\-vnc ' | tail -n 1 | awk '{print $2}' | cut -d ':' -f 2 | tail -n 1)
			CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
			printf "%s\n" "正在为您启动qemu虚拟机，本机默认VNC访问地址为localhost:${CURRENT_VNC_PORT}"
			echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${CURRENT_VNC_PORT}
		else
			printf "%s\n" "检测到您当前没有使用VNC服务，若您使用的是Xserver则可无视以下说明"
			printf "%s\n" "请自行添加端口号"
			printf "%s\n" "spice默认端口号为5931"
			printf "%s\n" "正在为您启动qemu虚拟机"
			printf "%s\n" "本机localhost"
			echo The LAN ip 局域网ip $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2)
		fi

		/usr/bin/qemu-system-x86_64 \
			-monitor stdio \
			-smp 4 \
			-cpu max \
			-vga virtio \
			--accel tcg \
			-m 2048 \
			-hda ${HOME}/sd/Download/backup/alpine_v3.11_x64.qcow2 \
			-virtfs local,id=shared_folder_dev_0,path=${HOME},security_model=none,mount_tag=shared0 \
			-boot order=cd,menu=on \
			-net nic,model=e1000 \
			-net user,hostfwd=tcp::2888-0.0.0.0:22,hostfwd=tcp::5903-0.0.0.0:5901,hostfwd=tcp::49080-0.0.0.0:80 \
			-rtc base=localtime \
			-vnc :2 \
			-usb \
			-device usb-tablet \
			-name "tmoe-linux-qemu"
	EndOFqemu
	chmod +x startqemu_amd64_2020060314
	cp -pf startqemu_amd64_2020060314 /usr/local/bin/startqemu
}
###########
modify_qemu_machine_accel() {
	if egrep -q 'vmx|smx' /proc/cpuinfo; then
		if [ "$(lsmod | grep kvm)" ]; then
			KVM_STATUS='检测到您的CPU可能支持硬件虚拟化,并且已经启用了KVM内核模块。'
		else
			KVM_STATUS='检测到您的CPU可能支持硬件虚拟化，但未检测到KVM内核模块。'
		fi
	else
		KVM_STATUS='检测到您的CPU可能不支持硬件虚拟化'
	fi
	cd /usr/local/bin/
	CURRENT_VALUE=$(cat startqemu | grep '\--accel ' | head -n 1 | awk '{print $2}' | cut -d ',' -f 1)
	VIRTUAL_TECH=$(
		whiptail --title "加速类型" --menu "KVM要求cpu支持硬件虚拟化,进行同架构模拟运行时能得到比tcg更快的速度,若您的CPU不支持KVM加速,则请勿修改为此项。${KVM_STATUS}\n检测到当前为${CURRENT_VALUE}" 17 50 5 \
			"1" "tcg(default)" \
			"2" "kvm(Intel VT-d/AMD-V)" \
			"3" "xen" \
			"4" "hax(Intel VT-x)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	1) MACHINE_ACCEL=tcg ;;
	2) MACHINE_ACCEL=kvm ;;
	3) MACHINE_ACCEL=xen ;;
	4) MACHINE_ACCEL=hax ;;
	esac
	###############
	if grep -q '\,thread=multi' startqemu; then
		sed -i "s@--accel .*@--accel ${MACHINE_ACCEL},thread=multi \\\@" startqemu
		printf "%s\n" "您已将accel修改为${MACHINE_ACCEL},并启用了多线程加速功能"
	else
		sed -i "s@--accel .*@--accel ${MACHINE_ACCEL} \\\@" startqemu
		printf "%s\n" "您已将accel修改为${MACHINE_ACCEL},但并未启用多线程加速功能"
	fi
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
modify_qemnu_graphics_card() {
	cd /usr/local/bin/
	CURRENT_VALUE=$(cat startqemu | grep '\-vga' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	VIRTUAL_TECH=$(
		whiptail --title "GPU/VGA" --menu "Please select the graphics card model.\n默认为std,当前为${CURRENT_VALUE}" 16 50 7 \
			"1" "vmware(VMWare SVGA)" \
			"2" "std(standard VGA,vesa2.0)" \
			"3" "cirrus clgd5446" \
			"4" "qxl(QXL VGA)" \
			"5" "xenfb(Xen paravirtualized framebuffer)" \
			"6" "tcx" \
			"7" "cg3" \
			"8" "none无显卡" \
			"9" "virtio" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_display_settings ;;
	1)
		printf "%s\n" " VMWare SVGA-II compatible adapter. Use it if you have sufficiently recent XFree86/XOrg server or Windows guest with a driver for this card."
		QEMU_VGA='vmware'
		;;
	2)
		printf "%s\n" "std Standard VGA card with Bochs VBE extensions.  If your guest OS supports the VESA 2.0 VBE extensions (e.g. Windows XP) and if you want to use high resolution modes (>= 1280x1024x16) then you should use this option. (This card is the default since QEMU 2.2)"
		QEMU_VGA='std'
		;;
	3)
		printf "%s\n" "Cirrus Logic GD5446 Video card. All Windows versions starting from Windows 95 should recognize and use this graphic card. For optimal performances, use 16 bit color depth in the guest and the host OS.  (This card was the default before QEMU 2.2) "
		QEMU_VGA='cirrus'
		;;
	4)
		printf "%s\n" "QXL paravirtual graphic card.  It is VGA compatible (including VESA 2.0 VBE support).  Works best with qxl guest drivers installed though.  Recommended choice when using the spice protocol."
		QEMU_VGA='qxl'
		;;
	5)
		QEMU_VGA='xenfb'
		;;
	6)
		printf "%s\n" "tcx (sun4m only) Sun TCX framebuffer. This is the default framebuffer for sun4m machines and offers both 8-bit and 24-bit colour depths at a fixed resolution of 1024x768."
		QEMU_VGA='tcx'
		;;
	7)
		printf "%s\n" " cg3 (sun4m only) Sun cgthree framebuffer. This is a simple 8-bit framebuffer for sun4m machines available in both 1024x768 (OpenBIOS) and 1152x900 (OBP) resolutions aimed at people wishing to run older Solaris versions."
		QEMU_VGA='cg3'
		;;
	8) QEMU_VGA='none' ;;
	9) QEMU_VGA='virtio' ;;
	esac
	###############
	sed -i "s@-vga .*@-vga ${QEMU_VGA} \\\@" startqemu
	printf "%s\n" "您已将graphics_card修改为${QEMU_VGA}"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
###############
modify_qemu_exposed_ports() {
	cd /usr/local/bin/
	HOST_PORT_01=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 2 | cut -d '-' -f 1 | cut -d ':' -f 3)
	GUEST_PORT_01=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 2 | cut -d '-' -f 2 | cut -d ':' -f 2 | awk '{print $1}')
	HOST_PORT_02=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 3 | cut -d '-' -f 1 | cut -d ':' -f 3)
	GUEST_PORT_02=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 3 | cut -d '-' -f 2 | cut -d ':' -f 2 | awk '{print $1}')
	HOST_PORT_03=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 4 | cut -d '-' -f 1 | cut -d ':' -f 3)
	GUEST_PORT_03=$(cat startqemu | grep '\-net user,hostfwd' | cut -d ',' -f 4 | cut -d '-' -f 2 | cut -d ':' -f 2 | awk '{print $1}')

	VIRTUAL_TECH=$(
		whiptail --title "TCP端口转发规则" --menu "如需添加更多端口，请手动修改配置文件" 15 55 4 \
			"1" "主${HOST_PORT_01}虚${GUEST_PORT_01}" \
			"2" "主${HOST_PORT_02}虚${GUEST_PORT_02}" \
			"3" "主${HOST_PORT_03}虚${GUEST_PORT_03}" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1)
		HOST_PORT=${HOST_PORT_01}
		GUEST_PORT=${GUEST_PORT_01}
		;;
	2)
		HOST_PORT=${HOST_PORT_02}
		GUEST_PORT=${GUEST_PORT_02}
		;;
	3)
		HOST_PORT=${HOST_PORT_03}
		GUEST_PORT=${GUEST_PORT_03}
		;;
	esac
	###############
	modify_qemu_host_and_guest_port
	if [ ! -z ${TARGET_HOST_PORT} ]; then
		printf "%s\n" "您已将虚拟机的${TARGET_GUEST_PORT}端口映射到宿主机的${TARGET_HOST_PORT}端口"
	fi
	press_enter_to_return
	modify_qemu_exposed_ports
}
#################
modify_qemu_host_and_guest_port() {
	TARGET_HOST_PORT=$(whiptail --inputbox "请输入宿主机端口，若您无root权限，则请将其修改为1024以上的高位端口" 10 50 --title "host port" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		modify_qemu_exposed_ports
	elif [ -z "${TARGET_HOST_PORT}" ]; then
		printf "%s\n" "请输入有效的数值"
		printf "%s\n" "Please enter a valid value"
	else
		sed -i "s@::${HOST_PORT}-@::${TARGET_HOST_PORT}-@" startqemu
	fi

	TARGET_GUEST_PORT=$(whiptail --inputbox "请输入虚拟机端口" 10 50 --title "guest port" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		modify_qemu_exposed_ports
	elif [ -z "${TARGET_GUEST_PORT}" ]; then
		printf "%s\n" "请输入有效的数值"
		printf "%s\n" "Please enter a valid value"
	else
		sed -i "s@0.0.0.0:${GUEST_PORT}@0.0.0.0:${TARGET_GUEST_PORT}@" startqemu
	fi
}
########
modify_qemu_shared_folder() {
	cd /usr/local/bin
	if (whiptail --title "您当前处于哪个环境" --yes-button 'Host' --no-button 'Guest' --yesno "您当前处于宿主机还是虚拟机环境？\nAre you in a host or guest environment?" 8 50); then
		modify_qemu_host_shared_folder
	else
		mount_qemu_guest_shared_folder
	fi
}
#############
disable_qemu_host_shared_folder() {
	sed -i '/-virtfs local,id=shared_folder/d' startqemu
	printf "%s\n" "如需还原，请重置配置文件"
}
############
modify_qemu_host_shared_folder_sdcard() {
	printf "%s\n" "Sorry,当前暂不支持修改挂载目录"
}
###############
#-hdd fat:rw:${HOME}/sd \
modify_qemu_host_shared_folder() {
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "shared folder" --menu "如需添加更多共享文件夹，请手动修改配置文件" 15 55 4 \
			"1" "DISABLE SHARE禁用共享" \
			"2" "${HOME}/sd" \
			"3" "windows共享说明" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) disable_qemu_host_shared_folder ;;
	2) modify_qemu_host_shared_folder_sdcard ;;
	3) printf '%s\n' '请单独使用webdav或Filebrowser文件共享功能，并在windows浏览器内输入局域网访问地址' ;;
	esac
	###############
	press_enter_to_return
	modify_qemu_host_shared_folder
}
#################
configure_mount_script() {
	cat >mount-9p-filesystem <<-'EOF'
		#!/usr/bin/env sh

		MOUNT_FOLDER="${HOME}/sd"
		MOUNT_NAME="shared0"
		mount_tmoe_linux_9p() {
		    mkdir -p "${MOUNT_FOLDER}"
		    if [ $(id -u) != "0" ]; then
		        sudo mount -t 9p -o trans=virtio ${MOUNT_NAME} "${MOUNT_FOLDER}" -o version=9p2000.L,posixacl,cache=mmap
		    else
		        mount -t 9p -o trans=virtio ${MOUNT_NAME} "${MOUNT_FOLDER}" -o version=9p2000.L,posixacl,cache=mmap
		    fi
		}

		df | grep "${MOUNT_FOLDER}" >/dev/null 2>&1 || mount_tmoe_linux_9p
	EOF
	chmod +x mount-9p-filesystem
	cd ~
	if ! grep -q 'mount-9p-filesystem' .zlogin; then
		printf "\n" >>.zlogin
		sed -i '$ a\/usr/local/bin/mount-9p-filesystem' .zlogin
	fi

	if ! grep -q 'mount-9p-filesystem' .profile; then
		printf "\n" >>.profile
		sed -i '$ a\/usr/local/bin/mount-9p-filesystem' .profile
	fi
	printf "%s\n" "若无法自动挂载，则请手动输${GREEN}mount-9p-filesystem${RESET}"
	mount-9p-filesystem
}
#############
disable_automatic_mount_qemu_folder() {
	cd ~
	sed -i '/mount-9p-filesystem/d' .profile .zlogin
}
##############
mount_qemu_guest_shared_folder() {
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "挂载磁盘" --menu "请在虚拟机环境下使用以下配置" 15 55 4 \
			"1" "configure配置挂载脚本" \
			"2" "DISABLE禁用自动挂载" \
			"3" "EDIT MANUALLY手动编辑挂载脚本" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) configure_mount_script ;;
	2) disable_automatic_mount_qemu_folder ;;
	3) nano /usr/local/bin/mount-9p-filesystem ;;
	esac
	###############
	press_enter_to_return
	mount_qemu_guest_shared_folder
}
##############
check_qemu_vnc_port() {
	START_QEMU_SCRIPT_PATH='/usr/local/bin/startqemu'
	if grep -q '\-vnc \:' "${START_QEMU_SCRIPT_PATH}"; then
		CURRENT_PORT=$(sed -n p ${START_QEMU_SCRIPT_PATH} | grep '\-vnc ' | tail -n 1 | awk '{print $2}' | cut -d ':' -f 2 | tail -n 1)
		CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
	fi
	#CURRENT_PORT=$(cat startqemu | grep '\-vnc ' | tail -n 1 | awk '{print $2}' | cut -d ':' -f 2)
	#CURRENT_VNC_PORT=$((${CURRENT_PORT} + 5900))
}
#########################
modify_qemu_vnc_display_port() {
	if ! grep -q '\-vnc \:' "startqemu"; then
		printf "%s\n" "检测到您未启用VNC服务，是否启用？"
		do_you_want_to_continue
		sed -i "/-vnc :/d" startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -vnc :2 \\\n/' startqemu
		sed -i 's@export PULSE_SERVER.*@export PULSE_SERVER=127.0.0.1@' startqemu
	fi
	check_qemu_vnc_port
	TARGET=$(whiptail --inputbox "默认显示编号为2，默认VNC服务端口为5902，当前为${CURRENT_VNC_PORT} \nVNC服务以5900端口为起始，若显示编号为3,则端口为5903，请输入显示编号.Please enter the display number." 13 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)

	if [ "$?" != "0" ]; then
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		printf "%s\n" "请输入有效的数值"
		printf "%s\n" "Please enter a valid value"
	else
		sed -i "s@-vnc :.*@-vnc :${TARGET} \\\@" startqemu
	fi

	printf '%s\n' 'Your current VNC port has been modified.'
	check_qemu_vnc_port
	printf '%s\n' '您当前VNC端口已修改为'
	printf "%s\n" "${CURRENT_VNC_PORT}"
}
###############
choose_qemu_iso_file() {
	cd /usr/local/bin/
	FILE_EXT_01='iso'
	FILE_EXT_02='ISO'
	if grep -q '\--cdrom' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\--cdrom' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的iso文件为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到您当前没有加载iso"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		stat ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		#-cdrom /root/alpine-standard-3.11.6-x86_64.iso \
		sed -i '/--cdrom /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    --cdrom tmoe_iso_file_test \\\n/' startqemu
		sed -i "s@tmoe_iso_file_test@${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	fi
}
###############
choose_qemu_qcow2_or_img_file() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='img'
	cd /usr/local/bin
	if grep -q '\-hda' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hda' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到您当前没有加载虚拟磁盘"
	fi
	where_is_tmoe_file_dir

	if [ -z ${SELECTION} ]; then
		printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		#-hda /root/.aqemu/alpine_v3.11_x64.qcow2 \
		sed -i '/-hda /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hda tmoe_hda_config_test \\\n/' startqemu
		sed -i "s@-hda tmoe_hda_config_test@-hda ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
		#sed -i "s@-hda .*@-hda ${TMOE_FILE_ABSOLUTE_PATH} \\\@" startqemu
	fi
}
##########
choose_hdb_disk_image_file() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='vhd'
	if grep -q '\-hdb' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hdb' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的第二块虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到第二块虚拟磁盘的槽位为空"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		sed -i '/-hdb /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hdb tmoe_hda_config_test \\\n/' startqemu
		sed -i "s@-hdb tmoe_hda_config_test@-hdb ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	fi
}
##########
choose_hdc_disk_image_file() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='vmdk'
	if grep -q '\-hdc' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hdc' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的第三块虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到第三块虚拟磁盘的槽位为空"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		sed -i '/-hdc /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hdc tmoe_hda_config_test \\\n/' startqemu
		sed -i "s@-hdc tmoe_hda_config_test@-hdc ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	fi
}
##########
choose_hdd_disk_image_file() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='vdi'
	if grep -q '\-hdd' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hdd' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的第四块虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到第四块虚拟磁盘的槽位为空"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		sed -i '/-hdd /d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hdd tmoe_hda_config_test \\\n/' startqemu
		sed -i "s@-hdd tmoe_hda_config_test@-hdd ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	fi
}
############
fix_qemu_vdisk_file_perssions() {
	if [ ${HOME} != '/root' ]; then
		printf "%s\n" "正在将${TARGET_FILE_NAME}的文件权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
		chown ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${TARGET_FILE_NAME}
	fi
}
##########
creat_blank_virtual_disk_image() {
	TARGET_FILE_NAME=$(whiptail --inputbox "请输入磁盘文件名称.\nPlease enter the filename." 10 50 --title "FILENAME" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET_FILE_NAME}" ]; then
		printf "%s\n" "请输入有效的数值"
		printf "%s\n" "Please enter a valid value"
		TARGET_FILE_NAME=$(date +%Y-%m-%d_%H-%M).qcow2
	else
		TARGET_FILE_NAME="${TARGET_FILE_NAME}.qcow2"
	fi
	DISK_FILE_PATH="${HOME}/sd/Download"
	mkdir -p ${DISK_FILE_PATH}
	cd ${DISK_FILE_PATH}
	TMOE_FILE_ABSOLUTE_PATH="${DISK_FILE_PATH}/${TARGET_FILE_NAME}"
	TARGET_FILE_SIZE=$(whiptail --inputbox "请设定磁盘空间大小,例如500M,10G,1T(需包含单位)\nPlease enter the disk size." 10 50 --title "SIZE" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET_FILE_SIZE}" ]; then
		printf "%s\n" "请输入有效的数值"
		printf "%s\n" "Please enter a valid value"
		printf "%s\n" "您输入了一个无效的数值，将为您自动创建16G大小的磁盘"
		do_you_want_to_continue
		#qemu-img create -f qcow2 -o preallocation=metadata ${TARGET_FILE_NAME} 16G
		qemu-img create -f qcow2 ${TARGET_FILE_NAME} 16G
	else
		qemu-img create -f qcow2 ${TARGET_FILE_NAME} ${TARGET_FILE_SIZE}
	fi
	fix_qemu_vdisk_file_perssions
	stat ${TARGET_FILE_NAME}
	qemu-img info ${TARGET_FILE_NAME}
	ls -lh ${DISK_FILE_PATH}/${TARGET_FILE_NAME}
	printf "%s\n" "是否需要将其设置为默认磁盘？"
	printf "%s\n" "Do you need to set it as the default disk?"
	do_you_want_to_continue
	#sed -i "s@-hda .*@-hda ${DISK_FILE_PATH}/${TARGET_FILE_NAME} \\\@" /usr/local/bin/startqemu
	cd /usr/local/bin
	sed -i '/-hda /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hda tmoe_hda_config_test \\\n/' startqemu
	sed -i "s@-hda tmoe_hda_config_test@-hda ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
}
################
#-spice port=5931,image-compression=quic,renderer=cairo+oglpbuf+oglpixmap,disable-ticketing \
enable_qemnu_spice_remote() {
	cd /usr/local/bin/
	if grep -q '\-spice port=' startqemu; then
		TMOE_SPICE_STATUS='检测到您已启用speic'
	else
		TMOE_SPICE_STATUS='检测到您已禁用speic'
	fi
	###########
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？启用后将禁用vnc服务。${TMOE_SPICE_STATUS},默认spice端口为5931" 10 45); then
		sed -i '/-spice port=/d' startqemu
		sed -i "/-vnc :/d" startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -spice tmoe_spice_config_test \\\n/' startqemu
		sed -i "s@-spice tmoe_spice_config_test@-spice port=5931,image-compression=quic,disable-ticketing@" startqemu
		printf "%s\n" "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i '/-spice port=/d' startqemu
		printf "%s\n" "禁用完成"
	fi
}
############
enable_qemnu_win2k_hack() {
	cd /usr/local/bin/
	if grep -q '\-win2k-hack' startqemu; then
		TMOE_SPICE_STATUS='检测到您已启用win2k-hack'
	else
		TMOE_SPICE_STATUS='检测到您已禁用win2k-hack'
	fi
	###########
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？${TMOE_SPICE_STATUS}" 11 45); then
		sed -i '/-win2k-hack/d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -win2k-hack \\\n/' startqemu
		printf "%s\n" "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i '/-win2k-hack/d' startqemu
		printf "%s\n" "禁用完成"
	fi
}
##############
modify_qemu_sound_card() {
	RETURN_TO_WHERE='modify_qemu_sound_card'
	cd /usr/local/bin/
	if grep -q '\-soundhw ' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-soundhw ' | tail -n 1 | awk '{print $2}')
	else
		CURRENT_VALUE='未启用'
	fi
	VIRTUAL_TECH=$(
		whiptail --title "声卡型号" --menu "Please select the sound card model.\n检测到当前为${CURRENT_VALUE}" 16 50 7 \
			"1" "cs4312a" \
			"2" "sb16(Creative Sound Blaster 16)" \
			"3" "es1370(ENSONIQ AudioPCI ES1370)" \
			"4" "ac97(Intel 82801AA AC97)" \
			"5" "adlib:Yamaha YM3812 (OPL2)" \
			"6" "gus(Gravis Ultrasound GF1)" \
			"7" "hda(Intel HD Audio)" \
			"8" "pcspk(PC speaker)" \
			"9" "disable禁用声卡" \
			"10" "all启用所有" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_display_settings ;;
	1) QEMU_SOUNDHW='cs4312a' ;;
	2) QEMU_SOUNDHW='sb16' ;;
	3) QEMU_SOUNDHW='es1370' ;;
	4) QEMU_SOUNDHW='ac97' ;;
	5) QEMU_SOUNDHW='adlib' ;;
	6) QEMU_SOUNDHW='gus' ;;
	7) QEMU_SOUNDHW='hda' ;;
	8) QEMU_SOUNDHW='pcspk' ;;
	9) disable_tmoe_qemu_sound_card ;;
	10) QEMU_SOUNDHW='all' ;;
	esac
	###############
	tmoe_modify_qemu_sound_card
}
#############
qemu_snapshoots_manager() {
	printf "%s\n" "Sorry,请在qemu monitor下手动管理快照"
}
############
tmoe_qemu_todo_list() {
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "not todo list" --menu "以下功能可能不会适配，请手动管理qemu" 0 0 0 \
			"1" "snapshoots快照管理" \
			"2" "GPU pci passthrough显卡硬件直通" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	1) qemu_snapshoots_manager ;;
	2) tmoe_qemu_gpu_passthrough ;;
	esac
	press_enter_to_return
	tmoe_qemu_todo_list
}
##########
tmoe_qemu_gpu_passthrough() {
	printf "%s\n" "本功能需要使用双显卡，因开发者没有测试条件，故不会适配"
	printf "%s\n" "请自行研究qemu gpu passthrough"
}
##############
modify_qemu_amd64_tmoe_cpu_type() {
	cd /usr/local/bin/
	if grep -q '\-cpu' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-cpu' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	else
		CURRENT_VALUE='未指定'
	fi
	#qemu-system-x86_64 -cpu help >001
	#cat 001 | awk '{print $2}' >002
	#去掉:$
	#将\r替换为\n
	VIRTUAL_TECH=$(
		whiptail --title "CPU" --menu "默认为max,当前为${CURRENT_VALUE}" 0 0 0 \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"000" "disable禁用指定cpu参数" \
			"001" "486:(alias configured by machine type)" \
			"002" "486-v1" \
			"003" "Broadwell:(alias configured by machine type)" \
			"004" "Broadwell-IBRS:(alias of Broadwell-v3)" \
			"005" "Broadwell-noTSX:(alias of Broadwell-v2)" \
			"006" "Broadwell-noTSX-IBRS:(alias of Broadwell-v4)" \
			"007" "Broadwell-v1:Intel Core Processor (Broadwell)" \
			"008" "Broadwell-v2:Intel Core Processor (Broadwell, no TSX)" \
			"009" "Broadwell-v3:Intel Core Processor (Broadwell, IBRS)" \
			"010" "Broadwell-v4:Intel Core Processor (Broadwell, no TSX, IBRS)" \
			"011" "Cascadelake-Server:(alias configured by machine type)" \
			"012" "Cascadelake-Server-noTSX:(alias of Cascadelake-Server-v3)" \
			"013" "Cascadelake-Server-v1:Intel Xeon Processor (Cascadelake)" \
			"014" "Cascadelake-Server-v2:Intel Xeon Processor (Cascadelake)" \
			"015" "Cascadelake-Server-v3:Intel Xeon Processor (Cascadelake)" \
			"016" "Conroe:(alias configured by machine type)" \
			"017" "Conroe-v1:Intel Celeron_4x0 (Conroe/Merom Class Core 2)" \
			"018" "Cooperlake:(alias configured by machine type)" \
			"019" "Cooperlake-v1:Intel Xeon Processor (Cooperlake)" \
			"020" "Denverton:(alias configured by machine type)" \
			"021" "Denverton-v1:Intel Atom Processor (Denverton)" \
			"022" "Denverton-v2:Intel Atom Processor (Denverton)" \
			"023" "Dhyana:(alias configured by machine type)" \
			"024" "Dhyana-v1:Hygon Dhyana Processor" \
			"025" "EPYC:(alias configured by machine type)" \
			"026" "EPYC-IBPB:(alias of EPYC-v2)" \
			"027" "EPYC-Rome:(alias configured by machine type)" \
			"028" "EPYC-Rome-v1:AMD EPYC-Rome Processor" \
			"029" "EPYC-v1:AMD EPYC Processor" \
			"030" "EPYC-v2:AMD EPYC Processor (with IBPB)" \
			"031" "EPYC-v3:AMD EPYC Processor" \
			"032" "Haswell:(alias configured by machine type)" \
			"033" "Haswell-IBRS:(alias of Haswell-v3)" \
			"034" "Haswell-noTSX:(alias of Haswell-v2)" \
			"035" "Haswell-noTSX-IBRS:(alias of Haswell-v4)" \
			"036" "Haswell-v1:Intel Core Processor (Haswell)" \
			"037" "Haswell-v2:Intel Core Processor (Haswell, no TSX)" \
			"038" "Haswell-v3:Intel Core Processor (Haswell, IBRS)" \
			"039" "Haswell-v4:Intel Core Processor (Haswell, no TSX, IBRS)" \
			"040" "Icelake-Client:(alias configured by machine type)" \
			"041" "Icelake-Client-noTSX:(alias of Icelake-Client-v2)" \
			"042" "Icelake-Client-v1:Intel Core Processor (Icelake)" \
			"043" "Icelake-Client-v2:Intel Core Processor (Icelake)" \
			"044" "Icelake-Server:(alias configured by machine type)" \
			"045" "Icelake-Server-noTSX:(alias of Icelake-Server-v2)" \
			"046" "Icelake-Server-v1:Intel Xeon Processor (Icelake)" \
			"047" "Icelake-Server-v2:Intel Xeon Processor (Icelake)" \
			"048" "Icelake-Server-v3:Intel Xeon Processor (Icelake)" \
			"049" "IvyBridge:(alias configured by machine type)" \
			"050" "IvyBridge-IBRS:(alias of IvyBridge-v2)" \
			"051" "IvyBridge-v1:Intel Xeon E3-12xx v2 (Ivy Bridge)" \
			"052" "IvyBridge-v2:Intel Xeon E3-12xx v2 (Ivy Bridge, IBRS)" \
			"053" "KnightsMill:(alias configured by machine type)" \
			"054" "KnightsMill-v1:Intel Xeon Phi Processor (Knights Mill)" \
			"055" "Nehalem:(alias configured by machine type)" \
			"056" "Nehalem-IBRS:(alias of Nehalem-v2)" \
			"057" "Nehalem-v1:Intel Core i7 9xx (Nehalem Class Core i7)" \
			"058" "Nehalem-v2:Intel Core i7 9xx (Nehalem Core i7, IBRS update)" \
			"059" "Opteron_G1:(alias configured by machine type)" \
			"060" "Opteron_G1-v1:AMD Opteron 240 (Gen 1 Class Opteron)" \
			"061" "Opteron_G2:(alias configured by machine type)" \
			"062" "Opteron_G2-v1:AMD Opteron 22xx (Gen 2 Class Opteron)" \
			"063" "Opteron_G3:(alias configured by machine type)" \
			"064" "Opteron_G3-v1:AMD Opteron 23xx (Gen 3 Class Opteron)" \
			"065" "Opteron_G4:(alias configured by machine type)" \
			"066" "Opteron_G4-v1:AMD Opteron 62xx class CPU" \
			"067" "Opteron_G5:(alias configured by machine type)" \
			"068" "Opteron_G5-v1:AMD Opteron 63xx class CPU" \
			"069" "Penryn:(alias configured by machine type)" \
			"070" "Penryn-v1:Intel Core 2 Duo P9xxx (Penryn Class Core 2)" \
			"071" "SandyBridge:(alias configured by machine type)" \
			"072" "SandyBridge-IBRS:(alias of SandyBridge-v2)" \
			"073" "SandyBridge-v1:Intel Xeon E312xx (Sandy Bridge)" \
			"074" "SandyBridge-v2:Intel Xeon E312xx (Sandy Bridge, IBRS update)" \
			"075" "Skylake-Client:(alias configured by machine type)" \
			"076" "Skylake-Client-IBRS:(alias of Skylake-Client-v2)" \
			"077" "Skylake-Client-noTSX-IBRS:BRS  (alias of Skylake-Client-v3)" \
			"078" "Skylake-Client-v1:Intel Core Processor (Skylake)" \
			"079" "Skylake-Client-v2:Intel Core Processor (Skylake, IBRS)" \
			"080" "Skylake-Client-v3:Intel Core Processor (Skylake, IBRS, no TSX)" \
			"081" "Skylake-Server:(alias configured by machine type)" \
			"082" "Skylake-Server-IBRS:(alias of Skylake-Server-v2)" \
			"083" "Skylake-Server-noTSX-IBRS:BRS  (alias of Skylake-Server-v3)" \
			"084" "Skylake-Server-v1:Intel Xeon Processor (Skylake)" \
			"085" "Skylake-Server-v2:Intel Xeon Processor (Skylake, IBRS)" \
			"086" "Skylake-Server-v3:Intel Xeon Processor (Skylake, IBRS, no TSX)" \
			"087" "Snowridge:(alias configured by machine type)" \
			"088" "Snowridge-v1:Intel Atom Processor (SnowRidge)" \
			"089" "Snowridge-v2:Intel Atom Processor (Snowridge, no MPX)" \
			"090" "Westmere:(alias configured by machine type)" \
			"091" "Westmere-IBRS:(alias of Westmere-v2)" \
			"092" "Westmere-v1:Westmere E56xx/L56xx/X56xx (Nehalem-C)" \
			"093" "Westmere-v2:Westmere E56xx/L56xx/X56xx (IBRS update)" \
			"094" "athlon:(alias configured by machine type)" \
			"095" "athlon-v1:QEMU Virtual CPU version 2.5+" \
			"096" "core2duo:(alias configured by machine type)" \
			"097" "core2duo-v1:Intel(R) Core(TM)2 Duo CPU     T7700  @ 2.40GHz" \
			"098" "coreduo:(alias configured by machine type)" \
			"099" "coreduo-v1:Genuine Intel(R) CPU           T2600  @ 2.16GHz" \
			"100" "kvm32:(alias configured by machine type)" \
			"101" "kvm32-v1:Common 32-bit KVM processor" \
			"102" "kvm64:(alias configured by machine type)" \
			"103" "kvm64-v1:Common KVM processor" \
			"104" "n270:(alias configured by machine type)" \
			"105" "n270-v1:Intel(R) Atom(TM) CPU N270   @ 1.60GHz" \
			"106" "pentium:(alias configured by machine type)" \
			"107" "pentium-v1" \
			"108" "pentium2:(alias configured by machine type)" \
			"109" "pentium2-v1" \
			"110" "pentium3:(alias configured by machine type)" \
			"111" "pentium3-v1" \
			"112" "phenom:(alias configured by machine type)" \
			"113" "phenom-v1:AMD Phenom(tm) 9550 Quad-Core Processor" \
			"114" "qemu32:(alias configured by machine type)" \
			"115" "qemu32-v1:QEMU Virtual CPU version 2.5+" \
			"116" "qemu64:(alias configured by machine type)" \
			"117" "qemu64-v1:QEMU Virtual CPU version 2.5+" \
			"118" "base:base CPU model type with no features enabled" \
			"119" "host:KVM processor with all supported host features" \
			"120" "max:Enables all features supported by the accelerator in the current host" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	000) disable_tmoe_qemu_cpu ;;
	001) TMOE_AMD64_QEMU_CPU_TYPE="486" ;;
	002) TMOE_AMD64_QEMU_CPU_TYPE="486-v1" ;;
	003) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell" ;;
	004) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-IBRS" ;;
	005) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-noTSX" ;;
	006) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-noTSX-IBRS" ;;
	007) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-v1" ;;
	008) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-v2" ;;
	009) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-v3" ;;
	010) TMOE_AMD64_QEMU_CPU_TYPE="Broadwell-v4" ;;
	011) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server" ;;
	012) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server-noTSX" ;;
	013) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server-v1" ;;
	014) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server-v2" ;;
	015) TMOE_AMD64_QEMU_CPU_TYPE="Cascadelake-Server-v3" ;;
	016) TMOE_AMD64_QEMU_CPU_TYPE="Conroe" ;;
	017) TMOE_AMD64_QEMU_CPU_TYPE="Conroe-v1" ;;
	018) TMOE_AMD64_QEMU_CPU_TYPE="Cooperlake" ;;
	019) TMOE_AMD64_QEMU_CPU_TYPE="Cooperlake-v1" ;;
	020) TMOE_AMD64_QEMU_CPU_TYPE="Denverton" ;;
	021) TMOE_AMD64_QEMU_CPU_TYPE="Denverton-v1" ;;
	022) TMOE_AMD64_QEMU_CPU_TYPE="Denverton-v2" ;;
	023) TMOE_AMD64_QEMU_CPU_TYPE="Dhyana" ;;
	024) TMOE_AMD64_QEMU_CPU_TYPE="Dhyana-v1" ;;
	025) TMOE_AMD64_QEMU_CPU_TYPE="EPYC" ;;
	026) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-IBPB" ;;
	027) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-Rome" ;;
	028) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-Rome-v1" ;;
	029) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-v1" ;;
	030) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-v2" ;;
	031) TMOE_AMD64_QEMU_CPU_TYPE="EPYC-v3" ;;
	032) TMOE_AMD64_QEMU_CPU_TYPE="Haswell" ;;
	033) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-IBRS" ;;
	034) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-noTSX" ;;
	035) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-noTSX-IBRS" ;;
	036) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-v1" ;;
	037) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-v2" ;;
	038) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-v3" ;;
	039) TMOE_AMD64_QEMU_CPU_TYPE="Haswell-v4" ;;
	040) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Client" ;;
	041) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Client-noTSX" ;;
	042) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Client-v1" ;;
	043) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Client-v2" ;;
	044) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server" ;;
	045) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server-noTSX" ;;
	046) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server-v1" ;;
	047) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server-v2" ;;
	048) TMOE_AMD64_QEMU_CPU_TYPE="Icelake-Server-v3" ;;
	049) TMOE_AMD64_QEMU_CPU_TYPE="IvyBridge" ;;
	050) TMOE_AMD64_QEMU_CPU_TYPE="IvyBridge-IBRS" ;;
	051) TMOE_AMD64_QEMU_CPU_TYPE="IvyBridge-v1" ;;
	052) TMOE_AMD64_QEMU_CPU_TYPE="IvyBridge-v2" ;;
	053) TMOE_AMD64_QEMU_CPU_TYPE="KnightsMill" ;;
	054) TMOE_AMD64_QEMU_CPU_TYPE="KnightsMill-v1" ;;
	055) TMOE_AMD64_QEMU_CPU_TYPE="Nehalem" ;;
	056) TMOE_AMD64_QEMU_CPU_TYPE="Nehalem-IBRS" ;;
	057) TMOE_AMD64_QEMU_CPU_TYPE="Nehalem-v1" ;;
	058) TMOE_AMD64_QEMU_CPU_TYPE="Nehalem-v2" ;;
	059) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G1" ;;
	060) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G1-v1" ;;
	061) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G2" ;;
	062) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G2-v1" ;;
	063) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G3" ;;
	064) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G3-v1" ;;
	065) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G4" ;;
	066) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G4-v1" ;;
	067) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G5" ;;
	068) TMOE_AMD64_QEMU_CPU_TYPE="Opteron_G5-v1" ;;
	069) TMOE_AMD64_QEMU_CPU_TYPE="Penryn" ;;
	070) TMOE_AMD64_QEMU_CPU_TYPE="Penryn-v1" ;;
	071) TMOE_AMD64_QEMU_CPU_TYPE="SandyBridge" ;;
	072) TMOE_AMD64_QEMU_CPU_TYPE="SandyBridge-IBRS" ;;
	073) TMOE_AMD64_QEMU_CPU_TYPE="SandyBridge-v1" ;;
	074) TMOE_AMD64_QEMU_CPU_TYPE="SandyBridge-v2" ;;
	075) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client" ;;
	076) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-IBRS" ;;
	077) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-noTSX-IBRS" ;;
	078) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-v1" ;;
	079) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-v2" ;;
	080) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Client-v3" ;;
	081) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server" ;;
	082) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-IBRS" ;;
	083) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-noTSX-IBRS" ;;
	084) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-v1" ;;
	085) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-v2" ;;
	086) TMOE_AMD64_QEMU_CPU_TYPE="Skylake-Server-v3" ;;
	087) TMOE_AMD64_QEMU_CPU_TYPE="Snowridge" ;;
	088) TMOE_AMD64_QEMU_CPU_TYPE="Snowridge-v1" ;;
	089) TMOE_AMD64_QEMU_CPU_TYPE="Snowridge-v2" ;;
	090) TMOE_AMD64_QEMU_CPU_TYPE="Westmere" ;;
	091) TMOE_AMD64_QEMU_CPU_TYPE="Westmere-IBRS" ;;
	092) TMOE_AMD64_QEMU_CPU_TYPE="Westmere-v1" ;;
	093) TMOE_AMD64_QEMU_CPU_TYPE="Westmere-v2" ;;
	094) TMOE_AMD64_QEMU_CPU_TYPE="athlon" ;;
	095) TMOE_AMD64_QEMU_CPU_TYPE="athlon-v1" ;;
	096) TMOE_AMD64_QEMU_CPU_TYPE="core2duo" ;;
	097) TMOE_AMD64_QEMU_CPU_TYPE="core2duo-v1" ;;
	098) TMOE_AMD64_QEMU_CPU_TYPE="coreduo" ;;
	099) TMOE_AMD64_QEMU_CPU_TYPE="coreduo-v1" ;;
	100) TMOE_AMD64_QEMU_CPU_TYPE="kvm32" ;;
	101) TMOE_AMD64_QEMU_CPU_TYPE="kvm32-v1" ;;
	102) TMOE_AMD64_QEMU_CPU_TYPE="kvm64" ;;
	103) TMOE_AMD64_QEMU_CPU_TYPE="kvm64-v1" ;;
	104) TMOE_AMD64_QEMU_CPU_TYPE="n270" ;;
	105) TMOE_AMD64_QEMU_CPU_TYPE="n270-v1" ;;
	106) TMOE_AMD64_QEMU_CPU_TYPE="pentium" ;;
	107) TMOE_AMD64_QEMU_CPU_TYPE="pentium-v1" ;;
	108) TMOE_AMD64_QEMU_CPU_TYPE="pentium2" ;;
	109) TMOE_AMD64_QEMU_CPU_TYPE="pentium2-v1" ;;
	110) TMOE_AMD64_QEMU_CPU_TYPE="pentium3" ;;
	111) TMOE_AMD64_QEMU_CPU_TYPE="pentium3-v1" ;;
	112) TMOE_AMD64_QEMU_CPU_TYPE="phenom" ;;
	113) TMOE_AMD64_QEMU_CPU_TYPE="phenom-v1" ;;
	114) TMOE_AMD64_QEMU_CPU_TYPE="qemu32" ;;
	115) TMOE_AMD64_QEMU_CPU_TYPE="qemu32-v1" ;;
	116) TMOE_AMD64_QEMU_CPU_TYPE="qemu64" ;;
	117) TMOE_AMD64_QEMU_CPU_TYPE="qemu64-v1" ;;
	118) TMOE_AMD64_QEMU_CPU_TYPE="base" ;;
	119) TMOE_AMD64_QEMU_CPU_TYPE="host" ;;
	120) TMOE_AMD64_QEMU_CPU_TYPE="max" ;;
	esac
	###############
	sed -i '/-cpu /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -cpu tmoe_cpu_config_test \\\n/' startqemu
	sed -i "s@-cpu tmoe_cpu_config_test@-cpu ${TMOE_AMD64_QEMU_CPU_TYPE}@" startqemu
	printf "%s\n" "您已将cpu修改为${TMOE_AMD64_QEMU_CPU_TYPE}"
	printf "%s\n" "修改完成，将在下次启动qemu虚拟机时生效"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
disable_tmoe_qemu_cpu() {
	sed -i '/-cpu /d' startqemu
	printf "%s\n" "禁用完成"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
modify_qemu_amd64_tmoe_machine_type() {
	cd /usr/local/bin/
	if grep -q '\-M ' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-M ' | head -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	else
		CURRENT_VALUE='默认'
	fi
	#qemu-system-x86_64 -machine help >001
	#cat 001 |awk '{print $1}' >002
	#paste 002 003 -d ':'
	VIRTUAL_TECH=$(
		whiptail --title "MACHINE" --menu "Please select the machine type.\n默认为pc-i440fx,当前为${CURRENT_VALUE}" 0 0 0 \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"00" "disable禁用指定机器类型参数" \
			"01" "microvm:microvm (i386)" \
			"02" "xenfv-4.2:Xen Fully-virtualized PC" \
			"03" "xenfv:Xen Fully-virtualized PC (alias of xenfv-3.1)" \
			"04" "xenfv-3.1:Xen Fully-virtualized PC" \
			"05" "pc:Standard PC (i440FX + PIIX, 1996) (alias of pc-i440fx-5.0)" \
			"06" "pc-i440fx-5.0:Standard PC (i440FX + PIIX, 1996) (default)" \
			"07" "pc-i440fx-4.2:Standard PC (i440FX + PIIX, 1996)" \
			"08" "pc-i440fx-4.1:Standard PC (i440FX + PIIX, 1996)" \
			"09" "pc-i440fx-4.0:Standard PC (i440FX + PIIX, 1996)" \
			"10" "pc-i440fx-3.1:Standard PC (i440FX + PIIX, 1996)" \
			"11" "pc-i440fx-3.0:Standard PC (i440FX + PIIX, 1996)" \
			"12" "pc-i440fx-2.9:Standard PC (i440FX + PIIX, 1996)" \
			"13" "pc-i440fx-2.8:Standard PC (i440FX + PIIX, 1996)" \
			"14" "pc-i440fx-2.7:Standard PC (i440FX + PIIX, 1996)" \
			"15" "pc-i440fx-2.6:Standard PC (i440FX + PIIX, 1996)" \
			"16" "pc-i440fx-2.5:Standard PC (i440FX + PIIX, 1996)" \
			"17" "pc-i440fx-2.4:Standard PC (i440FX + PIIX, 1996)" \
			"18" "pc-i440fx-2.3:Standard PC (i440FX + PIIX, 1996)" \
			"19" "pc-i440fx-2.2:Standard PC (i440FX + PIIX, 1996)" \
			"20" "pc-i440fx-2.12:Standard PC (i440FX + PIIX, 1996)" \
			"21" "pc-i440fx-2.11:Standard PC (i440FX + PIIX, 1996)" \
			"22" "pc-i440fx-2.10:Standard PC (i440FX + PIIX, 1996)" \
			"23" "pc-i440fx-2.1:Standard PC (i440FX + PIIX, 1996)" \
			"24" "pc-i440fx-2.0:Standard PC (i440FX + PIIX, 1996)" \
			"25" "pc-i440fx-1.7:Standard PC (i440FX + PIIX, 1996)" \
			"26" "pc-i440fx-1.6:Standard PC (i440FX + PIIX, 1996)" \
			"27" "pc-i440fx-1.5:Standard PC (i440FX + PIIX, 1996)" \
			"28" "pc-i440fx-1.4:Standard PC (i440FX + PIIX, 1996)" \
			"29" "pc-1.3:Standard PC (i440FX + PIIX, 1996) (deprecated)" \
			"30" "pc-1.2:Standard PC (i440FX + PIIX, 1996) (deprecated)" \
			"31" "pc-1.1:Standard PC (i440FX + PIIX, 1996) (deprecated)" \
			"32" "pc-1.0:Standard PC (i440FX + PIIX, 1996) (deprecated)" \
			"33" "q35:Standard PC (Q35 + ICH9, 2009) (alias of pc-q35-5.0)" \
			"34" "pc-q35-5.0:Standard PC (Q35 + ICH9, 2009)" \
			"35" "pc-q35-4.2:Standard PC (Q35 + ICH9, 2009)" \
			"36" "pc-q35-4.1:Standard PC (Q35 + ICH9, 2009)" \
			"37" "pc-q35-4.0.1:Standard PC (Q35 + ICH9, 2009)" \
			"38" "pc-q35-4.0:Standard PC (Q35 + ICH9, 2009)" \
			"39" "pc-q35-3.1:Standard PC (Q35 + ICH9, 2009)" \
			"40" "pc-q35-3.0:Standard PC (Q35 + ICH9, 2009)" \
			"41" "pc-q35-2.9:Standard PC (Q35 + ICH9, 2009)" \
			"42" "pc-q35-2.8:Standard PC (Q35 + ICH9, 2009)" \
			"43" "pc-q35-2.7:Standard PC (Q35 + ICH9, 2009)" \
			"44" "pc-q35-2.6:Standard PC (Q35 + ICH9, 2009)" \
			"45" "pc-q35-2.5:Standard PC (Q35 + ICH9, 2009)" \
			"46" "pc-q35-2.4:Standard PC (Q35 + ICH9, 2009)" \
			"47" "pc-q35-2.12:Standard PC (Q35 + ICH9, 2009)" \
			"48" "pc-q35-2.11:Standard PC (Q35 + ICH9, 2009)" \
			"49" "pc-q35-2.10:Standard PC (Q35 + ICH9, 2009)" \
			"50" "isapc:ISA-only PC" \
			"51" "none:empty machine" \
			"52" "xenpv:Xen Para-virtualized PC" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_WHERE} ;;
	00) disable_tmoe_qemu_machine ;;
	01) TMOE_AMD64_QEMU_MACHINE="microvm" ;;
	02) TMOE_AMD64_QEMU_MACHINE="xenfv-4.2" ;;
	03) TMOE_AMD64_QEMU_MACHINE="xenfv" ;;
	04) TMOE_AMD64_QEMU_MACHINE="xenfv-3.1" ;;
	05) TMOE_AMD64_QEMU_MACHINE="pc" ;;
	06) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-5.0" ;;
	07) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-4.2" ;;
	08) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-4.1" ;;
	09) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-4.0" ;;
	10) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-3.1" ;;
	11) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-3.0" ;;
	12) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.9" ;;
	13) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.8" ;;
	14) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.7" ;;
	15) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.6" ;;
	16) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.5" ;;
	17) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.4" ;;
	18) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.3" ;;
	19) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.2" ;;
	20) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.12" ;;
	21) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.11" ;;
	22) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.10" ;;
	23) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.1" ;;
	24) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-2.0" ;;
	25) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-1.7" ;;
	26) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-1.6" ;;
	27) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-1.5" ;;
	28) TMOE_AMD64_QEMU_MACHINE="pc-i440fx-1.4" ;;
	29) TMOE_AMD64_QEMU_MACHINE="pc-1.3" ;;
	30) TMOE_AMD64_QEMU_MACHINE="pc-1.2" ;;
	31) TMOE_AMD64_QEMU_MACHINE="pc-1.1" ;;
	32) TMOE_AMD64_QEMU_MACHINE="pc-1.0" ;;
	33) TMOE_AMD64_QEMU_MACHINE="q35" ;;
	34) TMOE_AMD64_QEMU_MACHINE="pc-q35-5.0" ;;
	35) TMOE_AMD64_QEMU_MACHINE="pc-q35-4.2" ;;
	36) TMOE_AMD64_QEMU_MACHINE="pc-q35-4.1" ;;
	37) TMOE_AMD64_QEMU_MACHINE="pc-q35-4.0.1" ;;
	38) TMOE_AMD64_QEMU_MACHINE="pc-q35-4.0" ;;
	39) TMOE_AMD64_QEMU_MACHINE="pc-q35-3.1" ;;
	40) TMOE_AMD64_QEMU_MACHINE="pc-q35-3.0" ;;
	41) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.9" ;;
	42) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.8" ;;
	43) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.7" ;;
	44) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.6" ;;
	45) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.5" ;;
	46) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.4" ;;
	47) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.12" ;;
	48) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.11" ;;
	49) TMOE_AMD64_QEMU_MACHINE="pc-q35-2.10" ;;
	50) TMOE_AMD64_QEMU_MACHINE="isapc" ;;
	51) TMOE_AMD64_QEMU_MACHINE="none" ;;
	52) TMOE_AMD64_QEMU_MACHINE="xenpv" ;;
	esac
	###############
	sed -i '/-M /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -M tmoe_cpu_config_test \\\n/' startqemu
	sed -i "s@-M tmoe_cpu_config_test@-M ${TMOE_AMD64_QEMU_MACHINE}@" startqemu
	printf "%s\n" "您已将cpu修改为${TMOE_AMD64_QEMU_MACHINE}"
	printf "%s\n" "修改完成，将在下次启动qemu虚拟机时生效"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##############
disable_tmoe_qemu_machine() {
	sed -i '/-M /d' startqemu
	printf "%s\n" "禁用完成"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
################
enable_tmoe_qemu_cpu_multi_threading() {
	cd /usr/local/bin/
	if grep -q '\,thread=multi' startqemu; then
		TMOE_SPICE_STATUS='检测到您已启用多线程加速功能'
	else
		TMOE_SPICE_STATUS='检测到您已禁用多线程加速功能'
	fi
	###########
	#11 45
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？${TMOE_SPICE_STATUS}" 0 0); then
		#CURRENT_VALUE=$(cat startqemu | grep '\-machine accel' | head -n 1 | awk '{print $2}' | cut -d ',' -f 1 | cut -d '=' -f 2)
		CURRENT_VALUE=$(cat startqemu | grep '\--accel ' | head -n 1 | awk '{print $2}' | cut -d ',' -f 1)
		sed -i "s@--accel .*@--accel ${CURRENT_VALUE},thread=multi \\\@" startqemu
		printf "%s\n" "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i 's@,thread=multi@@' startqemu
		printf "%s\n" "禁用完成"
	fi
}
#################
tmoe_qemu_x64_cpu_manager() {
	RETURN_TO_WHERE='tmoe_qemu_x64_cpu_manager'
	#15 50 6
	VIRTUAL_TECH=$(
		whiptail --title "CPU & RAM" --menu "Which configuration do you want to modify?" 0 0 0 \
			"1" "CPU cores处理器核心数" \
			"2" "cpu model/type(型号/类型)" \
			"3" "RAM运行内存" \
			"4" "multithreading多线程" \
			"5" "machine机器类型" \
			"6" "kvm/tcg/xen加速类型" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) modify_qemu_cpu_cores_number ;;
	2) modify_qemu_amd64_tmoe_cpu_type ;;
	3) modify_qemu_ram_size ;;
	4) enable_tmoe_qemu_cpu_multi_threading ;;
	5) modify_qemu_amd64_tmoe_machine_type ;;
	6) modify_qemu_machine_accel ;;
	esac
	###############
	#-soundhw cs4231a \
	press_enter_to_return
	${RETURN_TO_WHERE}
}
############
##############
tmoe_qemu_storage_devices() {
	cd /usr/local/bin/
	#RETURN_TO_WHERE='tmoe_qemu_storage_devices'
	VIRTUAL_TECH=$(
		whiptail --title "storage devices" --menu "Sorry,本功能正在开发中,当前仅支持配置virtio磁盘，其它选项请自行修改配置文件" 0 0 0 \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"00" "virtio-disk" \
			"01" "am53c974:bus PCI,desc(AMD Am53c974 PCscsi-PCI SCSI adapter)" \
			"02" "dc390:bus PCI,desc(Tekram DC-390 SCSI adapter)" \
			"03" "floppy:bus floppy-bus,desc(virtual floppy drive)" \
			"04" "ich9-ahci:bus PCI,alias(ahci)" \
			"05" "ide-cd:bus IDE,desc(virtual IDE CD-ROM)" \
			"06" "ide-drive:bus IDE,desc(virtual IDE disk or CD-ROM (legacy))" \
			"07" "ide-hd:bus IDE,desc(virtual IDE disk)" \
			"08" "isa-fdc:bus ISA" \
			"09" "isa-ide:bus ISA" \
			"10" "lsi53c810:bus PCI" \
			"11" "lsi53c895a:bus PCI,alias(lsi)" \
			"12" "megasas:bus PCI,desc(LSI MegaRAID SAS 1078)" \
			"13" "megasas-gen2:bus PCI,desc(LSI MegaRAID SAS 2108)" \
			"14" "mptsas1068:bus PCI,desc(LSI SAS 1068)" \
			"15" "nvme:bus PCI,desc(Non-Volatile Memory Express)" \
			"16" "piix3-ide:bus PCI" \
			"17" "piix3-ide-xen:bus PCI" \
			"18" "piix4-ide:bus PCI" \
			"19" "pvscsi:bus PCI" \
			"20" "scsi-block:bus SCSI,desc(SCSI block device passthrough)" \
			"21" "scsi-cd:bus SCSI,desc(virtual SCSI CD-ROM)" \
			"22" "scsi-disk:bus SCSI,desc(virtual SCSI disk or CD-ROM (legacy))" \
			"23" "scsi-generic:bus SCSI,desc(pass through generic scsi device (/dev/sg*))" \
			"24" "scsi-hd:bus SCSI,desc(virtual SCSI disk)" \
			"25" "sdhci-pci:bus PCI" \
			"26" "usb-bot:bus usb-bus" \
			"27" "usb-mtp:bus usb-bus,desc(USB Media Transfer Protocol device)" \
			"28" "usb-storage:bus usb-bus" \
			"29" "usb-uas:bus usb-bus" \
			"30" "vhost-scsi:bus virtio-bus" \
			"31" "vhost-scsi-pci:bus PCI" \
			"32" "vhost-user-blk:bus virtio-bus" \
			"33" "vhost-user-blk-pci:bus PCI" \
			"34" "vhost-user-scsi:bus virtio-bus" \
			"35" "vhost-user-scsi-pci:bus PCI" \
			"36" "virtio-9p-device:bus virtio-bus" \
			"37" "virtio-9p-pci:bus PCI,alias(virtio-9p)" \
			"38" "virtio-blk-device:bus virtio-bus" \
			"39" "virtio-blk-pci:bus PCI,alias(virtio-blk)" \
			"40" "virtio-scsi-device:bus virtio-bus" \
			"41" "virtio-scsi-pci:bus PCI,alias(virtio-scsi)" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_disk_manager ;;
	00) tmoe_qemu_virtio_disk ;;
	*) tmoe_qemu_error_tips ;;
	esac
	###############
	press_enter_to_return
	tmoe_qemu_disk_manager
}
###############
tmoe_qemu_virtio_disk() {
	RETURN_TO_WHERE='tmoe_qemu_virtio_disk'
	cd /usr/local/bin/
	if ! grep -q 'drive-virtio-disk' startqemu; then
		VIRTIO_STATUS="检测到您当前未启用virtio-disk"
	else
		VIRTIO_STATUS="检测到您当前已经启用virtio-disk"
	fi
	VIRTUAL_TECH=$(
		whiptail --title "VIRTIO-DISK" --menu "${VIRTIO_STATUS}" 15 50 6 \
			"1" "choose a disk选择virtio磁盘" \
			"2" "Download virtIO drivers下载驱动" \
			"3" "readme使用说明" \
			"4" "disable禁用hda(IDE)磁盘" \
			"5" "disable禁用virtio磁盘" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_storage_devices ;;
	1) choose_drive_virtio_disk_01 ;;
	2) download_virtio_drivers ;;
	3) printf '%s\n' '请先以常规挂载方式(IDE磁盘)运行虚拟机系统，接着在虚拟机内安装virtio驱动，然后退出虚拟机，最后禁用IDE磁盘，并选择virtio磁盘' ;;
	4)
		sed -i '/-hda /d' startqemu
		printf '%s\n' '禁用完成'
		;;
	5)
		sed -i '/drive-virtio-disk/d' startqemu
		printf '%s\n' '禁用完成'
		;;
	esac
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##########
set_it_as_the_default_qemu_iso() {
	printf "%s\n" "文件已解压至${DOWNLOAD_PATH}"
	printf "%s\n" "是否将其设置为默认的qemu光盘？"
	do_you_want_to_continue
	cd /usr/local/bin
	sed -i '/--cdrom /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    --cdrom tmoe_hda_config_test \\\n/' startqemu
	sed -i "s@--cdrom tmoe_hda_config_test@--cdrom ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	#printf "%s\n" "设置完成，您之后可以输startqemu启动"
	#printf "%s\n" "若启动失败，则请检查qemu的相关设置选项"
}
#############
check_tmoe_qemu_iso_file_and_git() {
	cd ${DOWNLOAD_PATH}
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it  o(*￣▽￣*)o, or download it again?(っ °Д °)" 0 0); then
			printf "%s\n" "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			git_clone_tmoe_linux_qemu_qcow2_file
		fi
	else
		git_clone_tmoe_linux_qemu_qcow2_file
	fi
}
###############
download_virtio_drivers() {
	DOWNLOAD_PATH="${HOME}/sd/Download"
	mkdir -p ${DOWNLOAD_PATH}
	VIRTUAL_TECH=$(
		whiptail --title "VIRTIO" --menu "${VIRTIO_STATUS}" 15 50 4 \
			"1" "virtio-win" \
			"2" "virtio-win-latest(fedora)" \
			"3" "readme驱动说明" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_virtio_disk ;;
	1)
		#THE_LATEST_ISO_LINK='https://m.tmoe.me/down/share/windows/drivers/virtio-win-0.1.173.iso'
		#aria2c_download_file
		printf "%s\n" "即将为您下载至${DOWNLOAD_PATH}"
		BRANCH_NAME='win'
		TMOE_LINUX_QEMU_REPO='https://gitee.com/ak2/virtio'
		DOWNLOAD_FILE_NAME='virtio-win.tar.gz'
		QEMU_QCOW2_FILE_PREFIX='.virtio_'
		QEMU_DISK_FILE_NAME='virtio-win.iso'
		TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
		check_tmoe_qemu_iso_file_and_git
		uncompress_tar_gz_file
		set_it_as_the_default_qemu_iso
		;;
	2)
		#https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso
		THE_LATEST_ISO_LINK='https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso'
		aria2c_download_file
		;;
	3)
		FEDORA_VIRTIO_URL='https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/index.html'
		printf "%s\n" "url: ${FEDORA_VIRTIO_URL}"
		su "${CURRENT_USER_NAME}" -c "xdg-open ${FEDORA_VIRTIO_URL}"
		#xdg-open 'https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/index.html' 2>/dev/null
		;;
	4)
		sed -i '/-hda /d' startqemu
		printf '%s\n' '禁用完成'
		;;
	5)
		sed -i '/drive-virtio-disk/d' startqemu
		printf '%s\n' '禁用完成'
		;;
	esac
	press_enter_to_return
	download_virtio_drivers
}
#######################
choose_drive_virtio_disk_01() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='img'
	if grep -q 'drive-virtio-disk' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep 'id=drive-virtio-disk' | head -n 1 | awk '{print $2}' | cut -d ',' -f 1 | cut -d '=' -f 2)
		IMPORTANT_TIPS="您当前已加载的virtio磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到您当前没有加载virtio磁盘"
	fi
	where_is_start_dir
	if [ -z ${SELECTION} ]; then
		printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		qemu-img info ${TMOE_FILE_ABSOLUTE_PATH}
		qemu-img check ${TMOE_FILE_ABSOLUTE_PATH}
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd /usr/local/bin
		#-hda /root/.aqemu/alpine_v3.11_x64.qcow2 \
		sed -i '/=drive-virtio-disk/d' startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -virtio_disk tmoe_virtio_disk_config_test \\\n/' startqemu
		sed -i "s@-virtio_disk tmoe_virtio_disk_config_test@-drive file=${TMOE_FILE_ABSOLUTE_PATH},format=qcow2,if=virtio,id=drive-virtio-disk0@" startqemu
	fi
}
###############
#########################
tmoe_qemu_error_tips() {
	printf "%s\n" "Sorry，本功能正在开发中，暂不支持修改storage devices，如需启用相关参数，请手动修改配置文件"
}
#####################
start_tmoe_qemu_manager() {
	RETURN_TO_WHERE='start_tmoe_qemu_manager'
	RETURN_TO_MENU='start_tmoe_qemu_manager'
	check_qemu_install
	if [ ! -e "${HOME}/.config/tmoe-linux/startqemu_amd64_2020060314" ]; then
		printf "%s\n" "启用x86_64虚拟机将重置startqemu为x86_64的配置"
		rm -fv ${HOME}/.config/tmoe-linux/startqemu*
		creat_qemu_startup_script
	fi
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "x86_64 qemu虚拟机管理器" --menu "同架构/跨架构模拟运行系统" 0 50 0 \
			"1" "🍹 Creat a new VM 新建虚拟机" \
			"2" "🏭 qemu templates repo磁盘与模板在线仓库" \
			"3" "🍱 Multi-VM多虚拟机管理" \
			"4" "🥗 edit script manually手动修改配置脚本" \
			"5" "🍤 FAQ常见问题" \
			"6" "📺 Display and audio显示与音频" \
			"7" "💾 disk manager磁盘管理器" \
			"8" "🍭 CPU & RAM 中央处理器与内存管理" \
			"9" "🥅 network网络设定" \
			"10" "🖱 Input devices输入设备" \
			"11" "🔌 uefi/legacy bios(开机引导固件)" \
			"12" "😋 extra options额外选项" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############🧺
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) creat_a_new_tmoe_qemu_vm ;;
	2) tmoe_qemu_templates_repo ;;
	3) multi_qemu_vm_management ;;
	4) nano startqemu ;;
	5) tmoe_qemu_faq ;;
	6) tmoe_qemu_display_settings ;;
	7) tmoe_qemu_disk_manager ;;
	8) tmoe_qemu_x64_cpu_manager ;;
	9) modify_tmoe_qemu_network_settings ;;
	10) tmoe_qemu_input_devices ;;
	11) choose_qemu_bios_or_uefi_file ;;
	12) modify_tmoe_qemu_extra_options ;;
	esac
	###############
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##############
creat_a_new_tmoe_qemu_vm() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='choose_qemu_qcow2_or_img_file'
	if (whiptail --title "是否需要创建虚拟磁盘" --yes-button 'creat新建' --no-button 'choose选择' --yesno "Do you want to creat a new disk?若您无虚拟磁盘，那就新建一个吧" 8 50); then
		creat_blank_virtual_disk_image
	else
		choose_qemu_qcow2_or_img_file
	fi
	SELECTION=""
	TMOE_QEMU_SCRIPT_FILE_PATH='/usr/local/bin/.tmoe-linux-qemu'
	THE_QEMU_STARTUP_SCRIPT='/usr/local/bin/startqemu'
	RETURN_TO_WHERE='save_current_qemu_conf_as_a_new_script'
	if (whiptail --title "是否需要选择启动光盘" --yes-button 'yes' --no-button 'skip跳过' --yesno "Do you want to choose a iso?启动光盘用于安装系统,若您无此文件,则请先下载iso;若磁盘内已安装了系统,则可跳过此选项。" 10 50); then
		choose_qemu_iso_file
	fi
	RETURN_TO_WHERE='multi_qemu_vm_management'
	save_current_qemu_conf_as_a_new_script
	printf "%s\n" "处于默认配置下的虚拟机的启动命令是startqemu"
	printf "%s\n" "是否需要启动虚拟机？"
	printf "%s\n" "您之后可以输startqemu来启动"
	printf "%s\n" "You can type startqemu to start the default qemu vm."
	printf "%s\n" "默认VNC访问地址为localhost:5902"
	printf "%s\n" "Do you want to start it now?"
	do_you_want_to_continue
	startqemu
}
##########################
modify_tmoe_qemu_extra_options() {
	RETURN_TO_WHERE='modify_tmoe_qemu_extra_options'
	VIRTUAL_TECH=$(
		whiptail --title "EXTRA OPTIONS" --menu "Which configuration do you want to modify？" 0 0 0 \
			"1" "windows2000 hack" \
			"2" "tmoe_qemu_not-todo-list" \
			"3" "restore to default恢复到默认" \
			"4" "switch architecture切换架构" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) enable_qemnu_win2k_hack ;;
	2) tmoe_qemu_todo_list ;;
	3)
		creat_qemu_startup_script
		printf "%s\n" "restore completed"
		;;
	4) switch_tmoe_qemu_architecture ;;
	esac
	###############
	press_enter_to_return
	modify_tmoe_qemu_extra_options
}
#################
switch_tmoe_qemu_architecture() {
	cd /usr/local/bin
	if grep -q '/usr/bin/qemu-system-x86_64' startqemu; then
		QEMU_ARCH_STATUS='检测到您当前启用的是x86_64架构'
		SED_QEMU_BIN_COMMAND='/usr/bin/qemu-system-x86_64'
	elif grep -q '/usr/bin/qemu-system-i386' startqemu; then
		QEMU_ARCH_STATUS='检测到您当前启用的是i386架构'
		SED_QEMU_BIN_COMMAND='/usr/bin/qemu-system-i386'
	fi
	QEMU_ARCH=$(
		whiptail --title "architecture" --menu "Which architecture do you want to switch？\n您想要切换为哪个架构?${QEMU_ARCH_STATUS}" 16 55 6 \
			"1" "x86_64" \
			"2" "i386" \
			"3" "mips" \
			"4" "sparc" \
			"5" "ppc" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${QEMU_ARCH} in
	0 | "") modify_tmoe_qemu_extra_options ;;
	1)
		SED_QEMU_BIN_COMMAND_SELECTED='/usr/bin/qemu-system-x86_64'
		sed -i "s@${SED_QEMU_BIN_COMMAND}@${SED_QEMU_BIN_COMMAND_SELECTED}@" startqemu
		printf "%s\n" "您已切换至${SED_QEMU_BIN_COMMAND_SELECTED}"
		;;
	2)
		SED_QEMU_BIN_COMMAND_SELECTED='/usr/bin/qemu-system-i386'
		sed -i "s@${SED_QEMU_BIN_COMMAND}@${SED_QEMU_BIN_COMMAND_SELECTED}@" startqemu
		printf "%s\n" "您已切换至${SED_QEMU_BIN_COMMAND_SELECTED}"
		;;
	*) printf "%s\n" "非常抱歉，本工具暂未适配此架构，请手动修改qemu启动脚本" ;;
	esac
	###############
	press_enter_to_return
	switch_tmoe_qemu_architecture
}
#####################
modify_tmoe_qemu_network_settings() {
	RETURN_TO_WHERE='modify_tmoe_qemu_network_settings'
	VIRTUAL_TECH=$(
		whiptail --title "network devices" --menu "Which configuration do you want to modify？" 0 0 0 \
			"1" "network card网卡" \
			"2" "exposed ports端口映射/转发" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) modify_qemu_tmoe_network_card ;;
	2) modify_qemu_exposed_ports ;;
	esac
	###############
	press_enter_to_return
	modify_tmoe_qemu_network_settings
}
##############
tmoe_qemu_disk_manager() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='tmoe_qemu_disk_manager'
	VIRTUAL_TECH=$(
		whiptail --title "DISK MANAGER" --menu "Which configuration do you want to modify?" 15 50 7 \
			"1" "💽choose iso选择启动光盘(CD)" \
			"2" "choose disk选择启动磁盘(IDE)" \
			"3" "compress压缩磁盘文件(真实大小)" \
			"4" "expand disk扩容磁盘(最大空间)" \
			"5" "mount shared folder挂载共享文件夹" \
			"6" "Storage devices存储设备" \
			"7" "creat disk创建(空白)虚拟磁盘" \
			"8" "second disk选择第二块IDE磁盘" \
			"9" "third disk选择第三块IDE磁盘" \
			"10" "fourth disk选择第四块IDE磁盘" \
			"11" "disable cdrom禁用光盘" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) choose_qemu_iso_file ;;
	2) choose_qemu_qcow2_or_img_file ;;
	3) compress_or_dd_qcow2_img_file ;;
	4) expand_qemu_qcow2_img_file ;;
	5) modify_qemu_shared_folder ;;
	6) tmoe_qemu_storage_devices ;;
	7) creat_blank_virtual_disk_image ;;
	8) choose_hdb_disk_image_file ;;
	9) choose_hdc_disk_image_file ;;
	10) choose_hdd_disk_image_file ;;
	11)
		sed -i '/--cdrom /d' startqemu
		printf "%s\n" "禁用完成"
		;;
	esac
	press_enter_to_return
	tmoe_qemu_disk_manager
}
################
tmoe_qemu_display_settings() {
	RETURN_TO_WHERE='tmoe_qemu_display_settings'
	RETURN_TO_TMOE_MENU_01='tmoe_qemu_display_settings'
	cd /usr/local/bin/
	VIRTUAL_TECH=$(
		whiptail --title "DISPLAY" --menu "Which configuration do you want to modify?" 15 50 7 \
			"1" "Graphics card/VGA(显卡/显示器)" \
			"2" "sound card声卡" \
			"3" "Display devices显示设备" \
			"4" "VNC port端口" \
			"5" "VNC pulseaudio音频" \
			"6" "X服务(XSDL/VcXsrv)" \
			"7" "spice远程桌面" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) modify_qemnu_graphics_card ;;
	2) modify_qemu_sound_card ;;
	3) modify_tmoe_qemu_display_device ;;
	4) modify_qemu_vnc_display_port ;;
	5) modify_tmoe_qemu_vnc_pulse_audio_address ;;
	6) modify_tmoe_qemu_xsdl_settings ;;
	7) enable_qemnu_spice_remote ;;
	esac
	press_enter_to_return
	tmoe_qemu_display_settings
}
################
modify_tmoe_qemu_vnc_pulse_audio_address() {
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。本机默认为127.0.0.1,当前为$(cat startqemu | grep 'PULSE_SERVER' | cut -d '=' -f 2 | head -n 1)\n本功能适用于局域网传输，本机操作无需任何修改。若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：若您使用的不是WSL或tmoe-linux安装的容器，则您需要手动启动音频服务,Android-Termux需输pulseaudio --start,win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat' \n若qemu无法调用音频,则请检查qemu启动脚本的声卡参数和虚拟机内的声卡驱动。" 20 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		printf "%s\n" "请输入有效的数值"
		printf "%s\n" "Please enter a valid value"
	else
		if grep -q '^export.*PULSE_SERVER' "startqemu"; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startqemu
		else
			sed -i "2 a\export PULSE_SERVER=$TARGET" startqemu
		fi
		printf '%s\n' 'Your current PULSEAUDIO SERVER address has been modified.'
		printf "%s\n" "您当前的音频地址已修改为$(grep 'PULSE_SERVER' startqemu | cut -d '=' -f 2 | head -n 1)"
		printf "%s\n" "重启qemu生效"
	fi
}
##################
modify_tmoe_qemu_xsdl_settings() {
	if grep -q '\-vnc \:' "startqemu"; then
		X_SERVER_STATUS="检测到您当前启用的是VNC,而非X服务"
	elif grep -q '\-spice port' "startqemu"; then
		X_SERVER_STATUS="检测到您当前启用的是spice,而非X服务"
	elif grep -q '^export.*DISPLAY' "startqemu"; then
		X_SERVER_STATUS="检测到您已经启用了转发X的功能"
	else
		X_SERVER_STATUS="检测到您已经启用了本地X,但未启用转发"
	fi

	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'configure配置' --yesno "Do you want to enable it?(っ °Д °)\n启用xserver后将禁用vnc和spice,您是想要启用还是配置呢?${X_SERVER_STATUS}" 9 50); then
		sed -i '/vnc :/d' startqemu
		sed -i '/-spice port=/d' startqemu
		if ! grep -q '^export.*DISPLAY' "startqemu"; then
			sed -i "1 a\export DISPLAY=127.0.0.1:0" startqemu
		fi
		sed -i 's@export PULSE_SERVER.*@export PULSE_SERVER=127.0.0.1:4713@' startqemu
		printf "%s\n" "启用完成，重启qemu生效"
		press_enter_to_return
		modify_tmoe_qemu_xsdl_settings
	else
		modify_xsdl_conf
	fi
}
##############
modify_tmoe_qemu_display_device() {
	cd /usr/local/bin/
	RETURN_TO_WHERE='modify_tmoe_qemu_display_device'
	VIRTUAL_TECH=$(
		whiptail --title "display devices" --menu "您想要修改为哪个显示设备呢？此功能目前仍处于测试阶段，切换前需手动禁用之前的显示设备。" 0 0 0 \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"00" "list all enabled列出所有已经启用的设备" \
			"01" "ati-vga:bus PCI" \
			"02" "bochs-display:bus PCI" \
			"03" "cirrus-vga:bus PCI,desc(Cirrus CLGD 54xx VGA" \
			"04" "isa-cirrus-vga:bus ISA" \
			"05" "isa-vga:bus ISA" \
			"06" "qxl:bus PCI,desc(Spice QXL GPU (secondary)" \
			"07" "qxl-vga:bus PCI,desc(Spice QXL GPU (primary, vga compatible)" \
			"08" "ramfb:bus System,desc(ram framebuffer standalone device" \
			"09" "secondary-vga:bus PCI" \
			"10" "sga:bus ISA,desc(Serial Graphics Adapter" \
			"11" "VGA:bus PCI" \
			"12" "vhost-user-gpu:bus virtio-bus" \
			"13" "vhost-user-gpu-pci:bus PCI" \
			"14" "vhost-user-vga:bus PCI" \
			"15" "virtio-gpu-device:bus virtio-bus" \
			"16" "virtio-gpu-pci:bus PCI,alias(virtio-gpu" \
			"17" "virtio-vga:bus PCI" \
			"18" "vmware-svga:bus PCI" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_display_settings ;;
	00) list_all_enabled_qemu_display_devices ;;
	01) TMOE_QEMU_DISPLAY_DEVICES="ati-vga" ;;
	02) TMOE_QEMU_DISPLAY_DEVICES="bochs-display" ;;
	03) TMOE_QEMU_DISPLAY_DEVICES="cirrus-vga" ;;
	04) TMOE_QEMU_DISPLAY_DEVICES="isa-cirrus-vga" ;;
	05) TMOE_QEMU_DISPLAY_DEVICES="isa-vga" ;;
	06) TMOE_QEMU_DISPLAY_DEVICES="qxl" ;;
	07) TMOE_QEMU_DISPLAY_DEVICES="qxl-vga" ;;
	08) TMOE_QEMU_DISPLAY_DEVICES="ramfb" ;;
	09) TMOE_QEMU_DISPLAY_DEVICES="secondary-vga" ;;
	10) TMOE_QEMU_DISPLAY_DEVICES="sga" ;;
	11) TMOE_QEMU_DISPLAY_DEVICES="VGA" ;;
	12) TMOE_QEMU_DISPLAY_DEVICES="vhost-user-gpu" ;;
	13) TMOE_QEMU_DISPLAY_DEVICES="vhost-user-gpu-pci" ;;
	14) TMOE_QEMU_DISPLAY_DEVICES="vhost-user-vga" ;;
	15) TMOE_QEMU_DISPLAY_DEVICES="virtio-gpu-device" ;;
	16) TMOE_QEMU_DISPLAY_DEVICES="virtio-gpu-pci" ;;
	17) TMOE_QEMU_DISPLAY_DEVICES="virtio-vga" ;;
	18) TMOE_QEMU_DISPLAY_DEVICES="vmware-svga" ;;
	esac
	###############
	enable_qemnu_display_device
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##############
list_all_enabled_qemu_display_devices() {
	if ! grep -q '\-device' startqemu; then
		printf "%s\n" "未启用任何相关设备"
	else
		cat startqemu | grep '\-device' | awk '{print $2}'
	fi
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
enable_qemnu_display_device() {
	cd /usr/local/bin/
	if grep -q "device ${TMOE_QEMU_DISPLAY_DEVICES}" startqemu; then
		TMOE_SPICE_STATUS="检测到您已启用${TMOE_QEMU_DISPLAY_DEVICES}"
	else
		TMOE_SPICE_STATUS="检测到您已禁用${TMOE_QEMU_DISPLAY_DEVICES}"
	fi
	###########
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？${TMOE_SPICE_STATUS}" 11 45); then
		sed -i "/-device ${TMOE_QEMU_DISPLAY_DEVICES}/d" startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -device tmoe_config_test \\\n/' startqemu
		sed -i "s@-device tmoe_config_test@-device ${TMOE_QEMU_DISPLAY_DEVICES}@" startqemu
		printf "%s\n" "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i "/-device ${TMOE_QEMU_DISPLAY_DEVICES}/d" startqemu
		printf "%s\n" "禁用完成"
	fi
}
#####################
tmoe_qemu_templates_repo() {
	RETURN_TO_WHERE='tmoe_qemu_templates_repo'
	DOWNLOAD_PATH="${HOME}/sd/Download/backup"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	CURRENT_TMOE_QEMU_BIN='/usr/bin/qemu-system-aarch64'
	LATER_TMOE_QEMU_BIN='/usr/bin/qemu-system-x86_64'
	VIRTUAL_TECH=$(
		whiptail --title "QEMU TEMPLATES" --menu "Welcome to 施工现场(ﾟДﾟ*)ﾉ\nUEFI与legacy bios为开机引导类型" 0 50 0 \
			"1" "alpine_x64(含docker,217M,legacy)" \
			"2" "Debian buster_arm64/x64(300M,UEFI)" \
			"3" "Arch_x64(678M,legacy)" \
			"4" "FreeBSD_x64(500M,legacy)" \
			"5" "Winserver2008R2数据中心版_x64(2.2G,legacy)" \
			"6" "Ubuntu kylin优麒麟20.04_x64(1.8G,uefi)" \
			"7" "LMDE4_x64(linux mint,2.7G,legacy)" \
			"8" "Explore templates探索共享模板(未开放)" \
			"9" "share 分享你的qemu配置(未开放)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#Explore configuration templates
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) download_alpine_and_docker_x64_img_file ;;
	2) download_debian_qcow2_file ;;
	3) download_arch_linux_qcow2_file ;;
	4) download_freebsd_qcow2_file ;;
	5) download_windows_server_2008_data_center_qcow2_file ;;
	6) download_ubuntu_kylin_20_04_qcow2_file ;;
	7) download_lmde_4_qcow2_file ;;
	8) explore_qemu_configuration_templates ;;
	9) share_qemu_conf_to_git_branch_qemu ;;
	esac
	press_enter_to_return
	tmoe_qemu_templates_repo
}
##########
download_freebsd_qcow2_file() {
	DOWNLOAD_PATH="${HOME}/sd/Download/backup/freebsd"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	ISO_REPO='https://mirrors.huaweicloud.com/freebsd/releases/VM-IMAGES/'
	THE_LATEST_SYSTEM_VERSION=$(curl -L ${ISO_REPO} | grep -v 'README' | grep href | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	#https://mirrors.huaweicloud.com/freebsd/releases/VM-IMAGES/12.1-RELEASE/amd64/Latest/
	THE_LATEST_ISO_REPO="${ISO_REPO}${THE_LATEST_SYSTEM_VERSION}amd64/Latest/"
	THE_LATEST_FILE_VERSION=$(curl -L ${THE_LATEST_ISO_REPO} | egrep -v 'vmdk|vhd|raw.xz|CHECKSUM' | grep qcow2 | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	DOWNLOAD_FILE_NAME="${THE_LATEST_FILE_VERSION}"
	THE_LATEST_ISO_LINK="${THE_LATEST_ISO_REPO}${THE_LATEST_FILE_VERSION}"
	# stat ${THE_LATEST_FILE_VERSION}
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to uncompress it, or download it again?" 0 0); then
			printf "%s\n" "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			aria2c_download_file
		fi
	else
		aria2c_download_file
	fi
	uncompress_qcow2_xz_file
	QEMU_DISK_FILE_NAME=$(ls -At | grep -v '.xz' | awk -F ' ' '$0=$NF' | head -n 1)
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	set_it_as_default_qemu_disk
}
########################
uncompress_qcow2_xz_file() {
	printf '%s\n' '正在解压中...'
	#unxz
	xz -dv ${DOWNLOAD_FILE_NAME}
}
####################
share_qemu_conf_to_git_branch_qemu() {
	printf "%s\n" "Welcome to 施工现场，这个功能还在开发中呢！咕咕咕，建议您明年再来o((>ω< ))o"
}
################
explore_qemu_configuration_templates() {
	RETURN_TO_WHERE='explore_qemu_configuration_templates'
	VIRTUAL_TECH=$(
		whiptail --title "奇怪的虚拟机又增加了" --menu "Welcome to 施工现场，这个功能还在开发中呢！\n咕咕咕，建议您明年再来o((>ω< ))o\n以下配置模板来自于他人的共享,与本工具开发者无关.\n希望大家多多支持原发布者ヽ(゜▽゜　)" 0 0 0 \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"001" "win7精简不卡,三分钟开机(bili@..)" \
			"002" "可能是全网最流畅的win10镜像(qq@..)" \
			"003" "kubuntu20.04 x64豪华配置，略卡(coolapk@..)" \
			"004" "lubuntu18.04内置wine,可玩游戏(github@..)" \
			"005" "win98 骁龙6系超级流畅(bili@..)" \
			"006" "winxp有网有声(tieba@..)" \
			"007" "vista装了许多好玩的东西,骁龙865流畅(tieba@..)" \
			"008" "macos ppc上古版本(coolapk@..)" \
			"009" "xubuntu个人轻度精简,内置qq和百度云(github@..)" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") tmoe_qemu_templates_repo ;;
	001) win7_qemu_template_2020_06_02_17_38 ;;
	008) printf "%s\n" "非常抱歉，本工具暂未适配ppc架构" ;;
	*) printf "%s\n" "这个模板加载失败了呢！" ;;
	esac
	###############
	printf "%s\n" "暂未开放此功能！咕咕咕，建议您明年再来o((>ω< ))o"
	press_enter_to_return
	tmoe_qemu_templates_repo
}
##############
win7_qemu_template_2020_06_02_17_38() {
	whiptail --title "发布者的留言" \
		--msgbox "
      个人主页：https://space.bilibili.com/
      资源链接：https://pan.baidu.com/disk/home#/all?vmode=list&path=%2F%E6%88%91%E7%9A%84%E8%B5%84%E6%BA%90
      大家好，我是来自B站的..
      不知道今天是哪个幸运儿用到了我发布的镜像和配置脚本呢？萌新up主求三连😀
      " 0 0
	printf "%s\n" "是否将其设置为默认的qemu配置？"
	do_you_want_to_continue
	#if [ $? = 0]; then
	#fi
	printf "%s\n" "这个模板加载失败了呢！光有脚本还不够，您还需要下载镜像资源文件至指定目录呢！"
}
##################
tmoe_qemu_input_devices() {
	#qemu-system-x86_64 -device help
	cd /usr/local/bin/
	RETURN_TO_WHERE='tmoe_qemu_input_devices'
	VIRTUAL_TECH=$(
		whiptail --title "input devices" --menu "请选择您需要启用的输入设备,您可以同时启用多个设备" 0 0 0 \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			"00" "list all enabled列出所有已经启用的设备" \
			"01" "ccid-card-emulated: bus ccid-bus, desc(emulated smartcard)" \
			"02" "ccid-card-passthru: bus ccid-bus, desc(passthrough smartcard)" \
			"03" "ipoctal232: bus IndustryPack, desc(GE IP-Octal 232 8-channel RS-232 IndustryPack)" \
			"04" "isa-parallel: bus ISA" \
			"05" "isa-serial: bus ISA" \
			"06" "pci-serial: bus PCI" \
			"07" "pci-serial-2x: bus PCI" \
			"08" "pci-serial-4x: bus PCI" \
			"09" "tpci200: bus PCI, desc(TEWS TPCI200 IndustryPack carrier)" \
			"10" "usb-braille: bus usb-bus" \
			"11" "usb-ccid: bus usb-bus, desc(CCID Rev 1.1 smartcard reader)" \
			"12" "usb-kbd: bus usb-bus" \
			"13" "usb-mouse: bus usb-bus" \
			"14" "usb-serial: bus usb-bus" \
			"15" "usb-tablet: bus usb-bus" \
			"16" "usb-wacom-tablet: bus usb-bus, desc(QEMU PenPartner Tablet)" \
			"17" "virtconsole: bus virtio-serial-bus" \
			"18" "virtio-input-host-device: bus virtio-bus" \
			"19" "virtio-input-host-pci: bus PCI, alias(virtio-input-host)" \
			"20" "virtio-keyboard-device: bus virtio-bus" \
			"21" "virtio-keyboard-pci: bus PCI, alias(virtio-keyboard)" \
			"22" "virtio-mouse-device: bus virtio-bus" \
			"23" "virtio-mouse-pci: bus PCI, alias(virtio-mouse)" \
			"24" "virtio-serial-device: bus virtio-bus" \
			"25" "virtio-serial-pci: bus PCI, alias(virtio-serial)" \
			"26" "virtio-tablet-device: bus virtio-bus" \
			"27" "virtio-tablet-pci: bus PCI, alias(virtio-tablet)" \
			"28" "virtserialport: bus virtio-serial-bus" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	00) list_all_enabled_qemu_input_devices ;;
	01) TMOE_QEMU_INPUT_DEVICE='ccid-card-emulated' ;;
	02) TMOE_QEMU_INPUT_DEVICE='ccid-card-passthru' ;;
	03) TMOE_QEMU_INPUT_DEVICE='ipoctal232' ;;
	04) TMOE_QEMU_INPUT_DEVICE='isa-parallel' ;;
	05) TMOE_QEMU_INPUT_DEVICE='isa-serial' ;;
	06) TMOE_QEMU_INPUT_DEVICE='pci-serial' ;;
	07) TMOE_QEMU_INPUT_DEVICE='pci-serial-2x' ;;
	08) TMOE_QEMU_INPUT_DEVICE='pci-serial-4x' ;;
	09) TMOE_QEMU_INPUT_DEVICE='tpci200' ;;
	10) TMOE_QEMU_INPUT_DEVICE='usb-braille' ;;
	11) TMOE_QEMU_INPUT_DEVICE='usb-ccid' ;;
	12) TMOE_QEMU_INPUT_DEVICE='usb-kbd' ;;
	13) TMOE_QEMU_INPUT_DEVICE='usb-mouse' ;;
	14) TMOE_QEMU_INPUT_DEVICE='usb-serial' ;;
	15) TMOE_QEMU_INPUT_DEVICE='usb-tablet' ;;
	16) TMOE_QEMU_INPUT_DEVICE='usb-wacom-tablet' ;;
	17) TMOE_QEMU_INPUT_DEVICE='virtconsole' ;;
	18) TMOE_QEMU_INPUT_DEVICE='virtio-input-host-device' ;;
	19) TMOE_QEMU_INPUT_DEVICE='virtio-input-host-pci' ;;
	20) TMOE_QEMU_INPUT_DEVICE='virtio-keyboard-device' ;;
	21) TMOE_QEMU_INPUT_DEVICE='virtio-keyboard-pci' ;;
	22) TMOE_QEMU_INPUT_DEVICE='virtio-mouse-device' ;;
	23) TMOE_QEMU_INPUT_DEVICE='virtio-mouse-pci' ;;
	24) TMOE_QEMU_INPUT_DEVICE='virtio-serial-device' ;;
	25) TMOE_QEMU_INPUT_DEVICE='virtio-serial-pci' ;;
	26) TMOE_QEMU_INPUT_DEVICE='virtio-tablet-device' ;;
	27) TMOE_QEMU_INPUT_DEVICE='virtio-tablet-pci' ;;
	28) TMOE_QEMU_INPUT_DEVICE='virtserialport' ;;
	esac
	###############
	enable_qemnu_input_device
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##########
list_all_enabled_qemu_input_devices() {
	if ! grep -q '\-device' startqemu; then
		printf "%s\n" "未启用任何相关设备"
	else
		cat startqemu | grep '\-device' | awk '{print $2}'
	fi
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#############
enable_qemnu_input_device() {
	cd /usr/local/bin/
	if grep -q "device ${TMOE_QEMU_INPUT_DEVICE}" startqemu; then
		TMOE_SPICE_STATUS="检测到您已启用${TMOE_QEMU_INPUT_DEVICE}"
	else
		TMOE_SPICE_STATUS="检测到您已禁用${TMOE_QEMU_INPUT_DEVICE}"
	fi
	###########
	if (whiptail --title "您想要对这个小可爱做什么?" --yes-button 'enable启用' --no-button 'disable禁用' --yesno "Do you want to enable it?(っ °Д °)\n您是想要启用还是禁用呢？${TMOE_SPICE_STATUS}" 11 45); then
		sed -i "/-device ${TMOE_QEMU_INPUT_DEVICE}/d" startqemu
		sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -device tmoe_config_test \\\n/' startqemu
		sed -i "s@-device tmoe_config_test@-device ${TMOE_QEMU_INPUT_DEVICE}@" startqemu
		printf "%s\n" "启用完成，将在下次启动qemu虚拟机时生效"
	else
		sed -i "/-device ${TMOE_QEMU_INPUT_DEVICE}/d" startqemu
		printf "%s\n" "禁用完成"
	fi
}
##########################
tmoe_choose_a_qemu_bios_file() {
	FILE_EXT_01='fd'
	FILE_EXT_02='bin'
	IMPORTANT_TIPS="您当前已加载的bios为${CURRENT_VALUE}"
	CURRENT_QEMU_ISO="${CURRENT_VALUE}"
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
		press_enter_to_return
		${RETURN_TO_WHERE}
	else
		printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd ${FILE_PATH}
		file ${SELECTION}
	fi
	TMOE_QEMU_BIOS_FILE_PATH="${TMOE_FILE_ABSOLUTE_PATH}"
	do_you_want_to_continue
}
###########
choose_qemu_bios_or_uefi_file() {
	if [ ! -e "/usr/share/qemu-efi-aarch64/QEMU_EFI.fd" ]; then
		DEPENDENCY_01=''
		DEPENDENCY_02='qemu-efi-aarch64'
		beta_features_quick_install
	fi
	if [ ! -e "/usr/share/ovmf/OVMF.fd" ]; then
		DEPENDENCY_01=''
		DEPENDENCY_02='ovmf'
		beta_features_quick_install
	fi
	cd /usr/local/bin/
	RETURN_TO_WHERE='choose_qemu_bios_or_uefi_file'
	if grep -q '\-bios ' startqemu; then
		CURRENT_VALUE=$(cat startqemu | grep '\-bios ' | tail -n 1 | awk '{print $2}' | cut -d '=' -f 2)
	else
		CURRENT_VALUE='默认'
	fi
	VIRTUAL_TECH=$(
		whiptail --title "uefi/legacy bios" --menu "Please select the legacy bios or uefi file.若您使用的是legacy-bios，则可以在启动VNC后的3秒钟内按下ESC键选择启动项。若您使用的是uefi,则您可以在启动VNC后的几秒内按其他键允许从光盘启动。\n当前为${CURRENT_VALUE}" 18 50 5 \
			"1" "default默认" \
			"2" "qemu-efi-aarch64:UEFI firmware for arm64" \
			"3" "ovmf:UEFI firmware for x64" \
			"4" "choose a file自选文件" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) restore_to_default_qemu_bios ;;
	2)
		if [ "${RETURN_TO_MENU}" = "start_tmoe_qemu_manager" ]; then
			printf "%s\n" "检测到您选用的是x64虚拟机，不支持qemu-efi-aarch64，将为您自动切换至OVMF EFI"
			TMOE_QEMU_BIOS_FILE_PATH='/usr/share/ovmf/OVMF.fd'
		else
			TMOE_QEMU_BIOS_FILE_PATH='/usr/share/qemu-efi-aarch64/QEMU_EFI.fd'
		fi
		;;
	3)
		if ! egrep -q 'std|qxl' /usr/local/bin/startqemu; then
			printf "%s\n" "请将显卡修改为qxl或std"
		fi
		TMOE_QEMU_BIOS_FILE_PATH='/usr/share/ovmf/OVMF.fd'
		;;
	4) tmoe_choose_a_qemu_bios_file ;;
	esac
	###############
	sed -i '/-bios /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -bios tmoe_bios_config_test \\\n/' startqemu
	sed -i "s@-bios tmoe_bios_config_test@-bios ${TMOE_QEMU_BIOS_FILE_PATH}@" startqemu
	printf "%s\n" "您已将启动引导固件修改为${TMOE_QEMU_BIOS_FILE_PATH}"
	printf "%s\n" "修改完成，将在下次启动qemu虚拟机时生效"
	press_enter_to_return
	${RETURN_TO_WHERE}
}
##########
restore_to_default_qemu_bios() {
	if [ "${RETURN_TO_MENU}" = "start_tmoe_qemu_manager" ]; then
		sed -i '/-bios /d' startqemu
	else
		#-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
		sed -i 's@-bios .*@-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \\@' startqemu
	fi
	press_enter_to_return
	${RETURN_TO_WHERE}
}
################
delete_current_qemu_vm_disk_file() {
	QEMU_FILE="$(sed -n p ${THE_QEMU_STARTUP_SCRIPT} | grep '\-hda ' | head -n 1 | awk '{print $2}' | cut -d ':' -f 2)"
	stat ${QEMU_FILE}
	qemu-img info ${QEMU_FILE}
	printf "%s\n" "Do you want to delete it?"
	printf "%s\n" "删除后将无法撤销，请谨慎操作"
	do_you_want_to_continue
	rm -fv ${QEMU_FILE}
}
################
delete_current_qemu_vm_iso_file() {
	QEMU_FILE="$(sed -n p ${THE_QEMU_STARTUP_SCRIPT} | grep '\--cdrom' | head -n 1 | awk '{print $2}')"
	stat ${QEMU_FILE}
	qemu-img info ${QEMU_FILE}
	printf "%s\n" "Do you want to delete it?"
	printf "%s\n" "删除后将无法撤销，请谨慎操作"
	do_you_want_to_continue
	rm -fv ${QEMU_FILE}
}
###############
how_to_creat_a_new_tmoe_qemu_vm() {
	cat <<-'EOF'
		   1.下载iso镜像文件 Download a iso file.
		   若虚拟磁盘内已经安装了系统，则可跳过此步。
		   If the qcow2 disk has a built-in system,then you can skip this step.
		        
			2.新建一个虚拟磁盘
			Creat a new vitual disk (qcow2 format).

			3.选择启动光盘iso
			Choose a iso file(CD-ROM)

			4.选择启动磁盘
			Choose a qcow2 disk

			5.修改相关参数
			Modify the parameters of qemu.

			6.输startqemu
			Type startqemu and press enter
			-------------------
			注：若您使用的是x86虚拟机镜像，则需要在额外选项中，将架构切换为i386。
			If you are using x86 image, please switch to i386 architecture in the extra options.
	EOF
}
tmoe_qemu_faq() {
	RETURN_TO_WHERE='tmoe_qemu_faq'
	VIRTUAL_TECH=$(
		whiptail --title "FAQ(よくある質問)" --menu "您有哪些疑问？\nWhat questions do you have?" 13 55 3 \
			"1" "qemu的cpu flags和device参数" \
			"2" "process进程管理说明" \
			"3" "creat a new vm如何新建虚拟机" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) tmoe_qemu_faq_01 ;;
	2) qemu_process_management_instructions ;;
	3) how_to_creat_a_new_tmoe_qemu_vm ;;
	esac
	###############
	press_enter_to_return
	tmoe_qemu_faq
}
################
tmoe_qemu_faq_01() {
	less -meQ ${TMOE_TOOL_DIR}/virtualization/qemu-faq
}
#############
multi_qemu_vm_management() {
	SELECTION=""
	TMOE_QEMU_SCRIPT_FILE_PATH='/usr/local/bin/.tmoe-linux-qemu'
	THE_QEMU_STARTUP_SCRIPT='/usr/local/bin/startqemu'
	RETURN_TO_WHERE='multi_qemu_vm_management'
	VIRTUAL_TECH=$(
		whiptail --title "multi-vm" --menu "您可以管理多个虚拟机的配置" 17 55 8 \
			"1" "save conf保存当前虚拟机配置" \
			"2" "start多虚拟机启动管理" \
			"3" "delete conf多虚拟配置删除" \
			"4" "del vm disk删除当前虚拟机磁盘文件" \
			"5" "del iso删除当前虚拟机iso文件" \
			"6" "其它说明" \
			"7" "del special vm disk删除指定虚拟机的磁盘文件" \
			"8" "del special vm iso删除指定虚拟机的镜像文件" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") ${RETURN_TO_MENU} ;;
	1) save_current_qemu_conf_as_a_new_script ;;
	2) multi_vm_start_manager ;;
	3) delete_multi_qemu_vm_conf ;;
	4) delete_current_qemu_vm_disk_file ;;
	5) delete_current_qemu_vm_iso_file ;;
	6) other_qemu_conf_related_instructions ;;
	7) delete_the_disk_file_of_the_specified_qemu_vm ;;
	8) delete_the_iso_file_of_the_specified_qemu_vm ;;
	esac
	###############
	press_enter_to_return
	multi_qemu_vm_management
}
################
save_current_qemu_conf_as_a_new_script() {
	mkdir -p ${TMOE_QEMU_SCRIPT_FILE_PATH}
	cd ${TMOE_QEMU_SCRIPT_FILE_PATH}
	TARGET_FILE_NAME=$(whiptail --inputbox "请自定义启动脚本名称,当前虚拟机的命令始终为startqemu\nPlease enter the script name." 10 50 --title "SCRIPT NAME" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		multi_qemu_vm_management
	elif [ "${TARGET_FILE_NAME}" = "startqemu" ] || [ "${TARGET_FILE_NAME}" = "debian-i" ] || [ "${TARGET_FILE_NAME}" = "startvnc" ]; then
		printf "%s\n" "文件已被占用，请重新输入"
		printf "%s\n" "Please re-enter."
		press_enter_to_return
		save_current_qemu_conf_as_a_new_script
	elif [ -z "${TARGET_FILE_NAME}" ]; then
		printf "%s\n" "请输入有效的名称"
		printf "%s\n" "Please enter a valid name"
		press_enter_to_return
		multi_qemu_vm_management
	else
		cp -pf /usr/local/bin/startqemu ${TMOE_QEMU_SCRIPT_FILE_PATH}/${TARGET_FILE_NAME}
		ln -sf ${TMOE_QEMU_SCRIPT_FILE_PATH}/${TARGET_FILE_NAME} /usr/local/bin/
		printf "%s\n" "您之后可以输${GREEN}${TARGET_FILE_NAME}${RESET}来启动该虚拟机"
	fi
}
#########
delete_the_iso_file_of_the_specified_qemu_vm() {
	START_DIR=${TMOE_QEMU_SCRIPT_FILE_PATH}
	BACKUP_FILE_NAME='*'
	printf "%s\n" "选中的虚拟机的iso镜像文件将被删除"
	printf "%s\n" "按Ctrl+C退出,若选项留空,则按回车键返回"
	printf "%s\n" "Press Ctrl+C to exit,press enter to return."
	select_file_manually
	TMOE_FILE_ABSOLUTE_PATH=${START_DIR}/${SELECTION}
	THE_QEMU_STARTUP_SCRIPT=${TMOE_FILE_ABSOLUTE_PATH}
	delete_current_qemu_vm_iso_file
}
############
delete_the_disk_file_of_the_specified_qemu_vm() {
	START_DIR=${TMOE_QEMU_SCRIPT_FILE_PATH}
	BACKUP_FILE_NAME='*'
	printf "%s\n" "选中的虚拟机的磁盘文件将被删除"
	printf "%s\n" "按Ctrl+C退出,若选项留空,则按回车键返回"
	printf "%s\n" "Press Ctrl+C to exit,press enter to return."
	select_file_manually
	TMOE_FILE_ABSOLUTE_PATH=${START_DIR}/${SELECTION}
	THE_QEMU_STARTUP_SCRIPT=${TMOE_FILE_ABSOLUTE_PATH}
	delete_current_qemu_vm_disk_file
}
############
select_file_manually() {
	count=0
	for restore_file in "${START_DIR}"/${BACKUP_FILE_NAME}; do
		restore_file_name[count]=$(printf '%s\n' "${restore_file}" | awk -F'/' '{print $NF}')
		echo -e "($count) ${restore_file_name[count]}"
		count=$(($count + 1))
	done
	count=$(($count - 1))

	while true; do
		read -p "请输入${BLUE}选项数字${RESET},并按${GREEN}回车键。${RESET}Please type the ${BLUE}option number${RESET} and press ${GREEN}Enter:${RESET}" number
		if [[ -z "$number" ]]; then
			break
		elif ! [[ $number =~ ^[0-9]+$ ]]; then
			printf "%s\n" "Please enter the right number!"
			printf "%s\n" "请输正确的数字编号!"
		elif (($number >= 0 && $number <= $count)); then
			eval SELECTION=${restore_file_name[number]}
			# cp -fr "${START_DIR}/$choice" "$DIR/restore_file.properties"
			break
		else
			printf "%s\n" "Please enter the right number!"
			printf "%s\n" "请输正确的数字编号!"
		fi
	done
	if [ -z "${SELECTION}" ]; then
		printf "%s\n" "没有文件被选择"
		press_enter_to_return
		${RETURN_TO_WHERE}
	fi
}
#####################
multi_vm_start_manager() {
	START_DIR=${TMOE_QEMU_SCRIPT_FILE_PATH}
	BACKUP_FILE_NAME='*'
	printf "%s\n" "选中的配置将设定为startqemu的默认配置"
	printf "%s\n" "按Ctrl+C退出,若选项留空,则按回车键返回"
	printf "%s\n" "Press Ctrl+C to exit,press enter to return."
	select_file_manually
	TMOE_FILE_ABSOLUTE_PATH=${START_DIR}/${SELECTION}
	if [ ! -z "${SELECTION}" ]; then
		cp -pf ${TMOE_FILE_ABSOLUTE_PATH} /usr/local/bin/startqemu
	else
		printf "%s\n" "没有文件被选择"
	fi

	printf "%s\n" "您之后可以输startqemu来执行${SELECTION}"
	printf "%s\n" "是否需要启动${SELECTION}"
	do_you_want_to_continue
	${TMOE_FILE_ABSOLUTE_PATH}
}
############
delete_multi_qemu_vm_conf() {
	START_DIR=${TMOE_QEMU_SCRIPT_FILE_PATH}
	BACKUP_FILE_NAME='*'
	printf "%s\n" "选中的配置将被删除"
	printf "%s\n" "按Ctrl+C退出,若选项留空,则按回车键返回"
	printf "%s\n" "Press Ctrl+C to exit,press enter to return."
	select_file_manually
	TMOE_FILE_ABSOLUTE_PATH=${START_DIR}/${SELECTION}
	rm -fv ${TMOE_FILE_ABSOLUTE_PATH}
	TMOE_QEMU_CONFIG_LINK_FILE="/usr/local/bin/${SELECTION}"
	if [ -h "${TMOE_QEMU_CONFIG_LINK_FILE}" ]; then
		rm -f ${TMOE_QEMU_CONFIG_LINK_FILE}
	fi
}
###############
other_qemu_conf_related_instructions() {
	cat <<-ENDOFTMOEINST
		Q:${YELLOW}一个个删除配置太麻烦了，有没有更快速的方法？${RESET}
		A：有哒！rm -rfv /usr/local/bin/.tmoe-linux-qemu
		Q:${YELLOW}不知道为啥虚拟机启动不了${RESET}
		A：你可以看一下资源发布者所撰写的相关说明，再调整一下参数。
	ENDOFTMOEINST
}
############
qemu_process_management_instructions() {
	check_qemu_vnc_port
	printf "%s\n" "输startqemu启动qemu"
	printf "%s\n" "${BLUE}连接方式01${RESET}"
	printf "%s\n" "打开vnc客户端，输入访问地址localhost:${CURRENT_VNC_PORT}"
	printf "%s\n" "${BLUE}关机方式01${RESET}"
	printf "%s\n" "在qemu monitor界面下输system_powerdown关闭虚拟机电源，输stop停止"
	printf "%s\n" "按Ctrl+C退出qemu monitor"
	printf "%s\n" "Press Ctrl+C to exit qemu monitor."
	printf "%s\n" "${BLUE}连接方式02${RESET}"
	printf "%s\n" "若您需要使用ssh连接，则请新建一个termux会话窗口，并输入${GREEN}ssh -p 2888 root@localhost${RESET}"
	printf "%s\n" "本工具默认将虚拟机的22端口映射为宿主机的2888端口，若无法连接，则请在虚拟机下新建一个普通用户，再将上述命令中的root修改为普通用户名称"
	printf "%s\n" "若连接提示${YELLOW}REMOTE HOST IDENTIFICATION HAS CHANGED${RESET}，则请手动输${GREEN}ssh-keygen -f '/root/.ssh/known_hosts' -R '[localhost]:2888'${RESET}"
	printf "%s\n" "${BLUE}关机方式02${RESET}"
	printf "%s\n" "在linux虚拟机内输poweroff"
	printf "%s\n" "在windows虚拟机内输shutdown /s /t 0"
	printf "%s\n" "${BLUE}重启方式01${RESET}"
	printf "%s\n" "在linux虚拟机内输reboot"
	printf "%s\n" "在windows虚拟机内输shutdown /r /t 0"
}
#################
#sed '$!N;$!P;$!D;s/\(\n\)/\n    -test \\ \n/' startqemu
#sed "s@$(cat startqemu | tail -n 1)@& \\\@" startqemu
modify_qemu_cpu_cores_number() {
	CURRENT_CORES=$(cat startqemu | grep '\-smp ' | head -n 1 | awk '{print $2}')
	TARGET=$(whiptail --inputbox "请输入CPU核心数,默认为4,当前为${CURRENT_CORES}\nPlease enter the number of CPU cores, the default is 4" 10 50 --title "CPU" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		#printf "%s\n" "检测到您取消了操作"
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		printf "%s\n" "请输入有效的数值"
		printf "%s\n" "Please enter a valid value"
	else
		sed -i "s@-smp .*@-smp ${TARGET} \\\@" startqemu
		printf "%s\n" "您已将CPU核心数修改为${TARGET}"
	fi
}
###########
modify_qemu_ram_size() {
	CURRENT_VALUE=$(cat startqemu | grep '\-m ' | head -n 1 | awk '{print $2}')
	TARGET=$(whiptail --inputbox "请输入运行内存大小,默认为2048(单位M),当前为${CURRENT_VALUE}\nPlease enter the RAM size, the default is 2048" 10 53 --title "RAM" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		#printf "%s\n" "检测到您取消了操作"
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		printf "%s\n" "请输入有效的数值"
		printf "%s\n" "Please enter a valid value"
		printf "%s\n" "不建议超过本机实际内存"
	else
		sed -i "s@-m .*@-m ${TARGET} \\\@" startqemu
		printf "%s\n" "您已将RAM size修改为${TARGET}"
	fi
}
#################
download_alpine_and_docker_x64_img_file() {
	cat <<-EOF
		You can use this image to run docker on Android system.
		The password of the root account is empty. After starting the qemu virtual machine, open the vnc client and enter localhost:5902. If you want to use ssh connection, please create a new termux session, and then install openssh client. Finally, enter ${GREEN}ssh -p 2888 test@localhost${RESET}
		User: test, password: test
		您可以使用本镜像在宿主机为Android系统的设备上运行aline_x64并使用docker
		默认root密码为空
		您可以直接使用vnc客户端连接，访问地址为localhost:5902
		如果您想要使用ssh连接，那么请新建一个termux会话窗口，并输入apt update ;apt install -y openssh
		您也可以直接在linux容器里使用ssh客户端，输入${TMOE_INSTALLATION_COMMAND} openssh-client
		在安装完ssh客户端后，使用${GREEN}ssh -p 2888 test@localhost${RESET}连接
		由于root密码为空，故请使用普通用户连接，用户test,密码test
		在登录完普通用户后，您可以输${GREEN}su -${RESET}来切换至root用户
		为了您的安全着想，请在虚拟机启动完成后，输入${GREEN}passwd${RESET}来修改密码
		Download size(下载大小)约217MB，解压后约为1.2GB
	EOF
	do_you_want_to_continue
	DOWNLOAD_FILE_NAME='alpine_v3.11_x64-qemu.tar.xz'
	DOWNLOAD_PATH="${HOME}/sd/Download/backup"
	QEMU_DISK_FILE_NAME='alpine_v3.11_x64.qcow2'
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then

		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded\n Do you want to unzip it, or download it again?" 0 0); then
			printf "%s\n" "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			download_alpine_and_docker_x64_img_file_again
		fi
	else
		download_alpine_and_docker_x64_img_file_again
	fi
	uncompress_alpine_and_docker_x64_img_file
	printf "%s\n" "您之后可以输startqemu来启动"
	printf "%s\n" "默认VNC访问地址为localhost:5902"
	set_it_as_default_qemu_disk
	startqemu
}
#############
alpine_qemu_old() {
	printf "%s\n" "文件已解压至${DOWNLOAD_PATH}"
	qemu-img info ${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}
	printf "%s\n" "是否需要启动虚拟机？"
	do_you_want_to_continue
}
###########
download_alpine_and_docker_x64_img_file_again() {
	#THE_LATEST_ISO_LINK='https://m.tmoe.me/down/share/Tmoe-linux/qemu/alpine_v3.11_x64-qemu.tar.xz'
	#aria2c --allow-overwrite=true -s 16 -x 16 -k 1M "${THE_LATEST_ISO_LINK}"
	cd /tmp
	git clone --depth=1 -b x64 https://gitee.com/ak2/alpine_qemu .ALPINE_QEMU_TEMP_FOLDER
	cd .ALPINE_QEMU_TEMP_FOLDER
	cat alpine_v3.11_* >alpine_v3.11_x64-qemu.tar.xz
	mv alpine_v3.11_x64-qemu.tar.xz ${DOWNLOAD_PATH}
	cd ../
	rm -rf .ALPINE_QEMU_TEMP_FOLDER
	cd ${DOWNLOAD_PATH}
}
###########
uncompress_alpine_and_docker_x64_img_file() {
	#txz
	printf '%s\n' '正在解压中...'
	if [ $(command -v pv) ]; then
		pv ${DOWNLOAD_FILE_NAME} | tar -pJx
	else
		tar -Jpxvf ${DOWNLOAD_FILE_NAME}
	fi
}
##################
dd_if_zero_of_qemu_tmp_disk() {
	rm -fv /tmp/tmoe_qemu
	printf "%s\n" "请在虚拟机内执行操作,不建议在宿主机内执行"
	printf "%s\n" "本操作将填充磁盘所有空白扇区"
	printf "%s\n" "若执行完成后，无法自动删除临时文件，则请手动输rm -f /tmp/tmoe_qemu"
	printf "%s\n" "请务必在执行完操作后,关掉虚拟机,并回到宿主机选择转换压缩"
	do_you_want_to_continue
	printf "%s\n" "此操作可能需要数分钟的时间..."
	printf "%s\n" "${GREEN}dd if=/dev/zero of=/tmp/tmoe_qemu bs=1M${RESET}"
	dd if=/dev/zero of=/tmp/tmoe_qemu bs=1M
	ls -lh /tmp/tmoe_qemu
	rm -fv /tmp/tmoe_qemu
}
##################
compress_or_dd_qcow2_img_file() {
	cd /usr/local/bin
	if (whiptail --title "您当前处于哪个环境" --yes-button 'Host' --no-button 'Guest' --yesno "您当前处于宿主机还是虚拟机环境？\nAre you in a host or guest environment?" 8 50); then
		compress_qcow2_img_file
	else
		dd_if_zero_of_qemu_tmp_disk
	fi
}
##########################
choose_tmoe_qemu_qcow2_model() {
	FILE_EXT_01='qcow2'
	FILE_EXT_02='img'
	if grep -q '\-hda' startqemu; then
		CURRENT_QEMU_ISO=$(cat startqemu | grep '\-hda' | tail -n 1 | awk '{print $2}')
		IMPORTANT_TIPS="您当前已加载的虚拟磁盘为${CURRENT_QEMU_ISO}"
	else
		IMPORTANT_TIPS="检测到您当前没有加载虚拟磁盘"
	fi
	where_is_tmoe_file_dir
	if [ -z ${SELECTION} ]; then
		printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
		press_enter_to_return
		${RETURN_TO_WHERE}
	else
		printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		cd ${FILE_PATH}
		stat ${SELECTION}
		qemu-img info ${SELECTION}
	fi
}
#########
expand_qemu_qcow2_img_file() {
	printf '%s\n' '建议您在调整容量前对磁盘文件进行备份。'
	printf '%s\n' '调整完成之后，您可以在虚拟机内部使用resize2fs命令对磁盘空间进行重新识别，例如resize2fs /dev/sda1'
	printf '%s\n' '在扩容之后，您必须在虚拟机系统内对该镜像进行分区并格式化后才能真正开始使用新空间。 在收缩磁盘映像前，必须先使用虚拟机内部系统的分区工具减少该分区的大小，然后相应地收缩磁盘映像，否则收缩磁盘映像将导致数据丢失'
	printf '%s\n' 'Arch wiki:After enlarging the disk image, you must use file system and partitioning tools inside the virtual machine to actually begin using the new space. When shrinking a disk image, you must first reduce the allocated file systems and partition sizes using the file system and partitioning tools inside the virtual machine and then shrink the disk image accordingly, otherwise shrinking the disk image will result in data loss! For a Windows guest, open the "create and format hard disk partitions" control panel.'
	do_you_want_to_continue
	choose_tmoe_qemu_qcow2_model
	CURRENT_VALUE=$(qemu-img info ${SELECTION} | grep 'virtual size' | awk '{print $3}')
	TARGET=$(whiptail --inputbox "请输入需要增加的空间大小,例如500M或10G(需包含单位),当前空间为${CURRENT_VALUE}\nPlease enter the size" 10 53 --title "virtual size" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		#printf "%s\n" "检测到您取消了操作"
		${RETURN_TO_WHERE}
	elif [ -z "${TARGET}" ]; then
		printf "%s\n" "请输入有效的数值"
		printf "%s\n" "Please enter a valid value"
		printf "%s\n" "不建议超过本机实际内存"
	else
		qemu-img resize ${SELECTION} +${TARGET}
		qemu-img check ${SELECTION}
		stat ${SELECTION}
		qemu-img info ${SELECTION}
		CURRENT_VALUE=$(qemu-img info ${SELECTION} | grep 'virtual size' | awk '{print $3}')
		printf "%s\n" "您已将virtual size修改为${CURRENT_VALUE}"
	fi
}
##############
compress_qcow2_img_file() {
	choose_tmoe_qemu_qcow2_model
	do_you_want_to_continue
	if (whiptail --title "请选择压缩方式" --yes-button "compress" --no-button "convert" --yesno "前者为常规压缩，后者转换压缩。♪(^∇^*) " 10 50); then
		printf '%s\n' 'compressing...'
		printf '%s\n' '正在压缩中...'
		qemu-img convert -c -O qcow2 ${SELECTION} ${SELECTION}_new-temp-file
	else
		printf '%s\n' 'converting...'
		printf '%s\n' '正在转换中...'
		qemu-img convert -O qcow2 ${SELECTION} ${SELECTION}_new-temp-file
	fi
	qemu-img info ${SELECTION}_new-temp-file
	mv -f ${SELECTION} original_${SELECTION}
	mv -f ${SELECTION}_new-temp-file ${SELECTION}
	printf '%s\n' '原文件大小'
	ls -lh original_${SELECTION} | tail -n 1 | awk '{print $5}'
	printf '%s\n' '压缩后的文件大小'
	ls -lh ${SELECTION} | tail -n 1 | awk '{print $5}'
	printf "%s\n" "压缩完成，是否删除原始文件?"
	qemu-img check ${SELECTION}
	printf "%s\n" "Do you want to delete the original file？"
	printf "%s\n" "请谨慎操作，在保证新磁盘数据无错前，不建议您删除原始文件，否则将导致原文件数据丢失"
	printf "%s\n" "若您取消操作，则请手动输rm ${FILE_PATH}/original_${SELECTION}"
	do_you_want_to_continue
	rm -fv original_${SELECTION}
}
################
download_virtual_machine_iso_file() {
	RETURN_TO_WHERE='download_virtual_machine_iso_file'

	DOWNLOAD_PATH="${HOME}/sd/Download"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	VIRTUAL_TECH=$(whiptail --title "IMAGE FILE" --menu "Which image file do you want to download?" 0 50 0 \
		"1" "alpine(latest-stable)" \
		"2" "Android x86_64(latest)" \
		"3" "debian-iso(每周自动构建,包含non-free)" \
		"4" "ubuntu" \
		"5" "flash iso烧录镜像文件至U盘" \
		"6" "windows" \
		"7" "LMDE(Linux Mint Debian Edition)" \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) download_alpine_virtual_iso ;;
	2) download_android_x86_file ;;
	3) download_debian_iso_file ;;
	4) download_ubuntu_iso_file ;;
	5) flash_iso_to_udisk ;;
	6) download_windows_10_iso ;;
	7) download_linux_mint_debian_edition_iso ;;
	esac
	###############
	press_enter_to_return
	download_virtual_machine_iso_file
}
###########
flash_iso_to_udisk() {
	FILE_EXT_01='iso'
	FILE_EXT_02='ISO'
	where_is_start_dir
	if [ -z ${SELECTION} ]; then
		printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		printf "%s\n" "您选择的iso文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		check_fdisk
	fi
}
################
check_fdisk() {
	if [ ! $(command -v fdisk) ]; then
		DEPENDENCY_01='fdisk'
		DEPENDENCY_02=''
		beta_features_quick_install
	fi
	lsblk
	df -h
	fdisk -l
	printf "%s\n" "${RED}WARNING！${RESET}您接下来需要选择一个${YELLOW}磁盘分区${RESET}，请复制指定磁盘的${RED}完整路径${RESET}（包含/dev）"
	printf "%s\n" "若选错磁盘，将会导致该磁盘数据${RED}完全丢失！${RESET}"
	printf "%s\n" "此操作${RED}不可逆${RESET}！请${GREEN}谨慎${RESET}选择！"
	printf "%s\n" "建议您在执行本操作前，对指定磁盘进行${BLUE}备份${RESET}"
	printf "%s\n" "若您因选错了磁盘而${YELLOW}丢失数据${RESET}，开发者${RED}概不负责！！！${RESET}"
	do_you_want_to_continue
	dd_flash_iso_to_udisk
}
################
dd_flash_iso_to_udisk() {
	DD_OF_TARGET=$(whiptail --inputbox "请输入磁盘路径，例如/dev/nvme0n1px或/dev/sdax,请以实际路径为准" 12 50 --title "DEVICES" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ] || [ -z "${DD_OF_TARGET}" ]; then
		printf "%s\n" "检测到您取消了操作"
		press_enter_to_return
		download_virtual_machine_iso_file
	fi
	printf "%s\n" "${DD_OF_TARGET}即将被格式化，所有文件都将丢失"
	do_you_want_to_continue
	umount -lf ${DD_OF_TARGET} 2>/dev/null
	printf "%s\n" "正在烧录中，这可能需要数分钟的时间..."
	dd <${TMOE_FILE_ABSOLUTE_PATH} >${DD_OF_TARGET}
}
############
download_win10_19041_x64_iso() {
	ISO_FILE_NAME='19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso'
	TMOE_FILE_ABSOLUTE_PATH=$(pwd)/${ISO_FILE_NAME}
	TMOE_ISO_URL="https://webdav.tmoe.me/down/share/windows/20H1/${ISO_FILE_NAME}"
	download_windows_tmoe_iso_model
}
##########
set_it_as_the_tmoe_qemu_iso() {
	cd /usr/local/bin
	sed -i '/--cdrom /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    --cdrom tmoe_iso_file_test \\\n/' startqemu
	sed -i "s@tmoe_iso_file_test@${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	printf "%s\n" "修改完成，相关配置将在下次启动qemu时生效"
}
########
download_tmoe_iso_file_again() {
	printf "%s\n" "即将为您下载win10 19041 iso镜像文件..."
	aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "${ISO_FILE_NAME}" "${TMOE_ISO_URL}"
	qemu-img info ${ISO_FILE_NAME}
}
################
download_win10_2004_x64_iso() {
	ISO_FILE_NAME='win10_2004_x64_tmoe.iso'
	TMOE_FILE_ABSOLUTE_PATH=$(pwd)/${ISO_FILE_NAME}
	TMOE_ISO_URL="https://webdav.tmoe.me/down/share/windows/20H1/${ISO_FILE_NAME}"
	download_windows_tmoe_iso_model
}
#############################
download_win10_19041_arm64_iso() {
	ISO_FILE_NAME='win10_2004_arm64_tmoe.iso'
	TMOE_FILE_ABSOLUTE_PATH=$(pwd)/${ISO_FILE_NAME}
	TMOE_ISO_URL="https://webdav.tmoe.me/down/share/windows/20H1/${ISO_FILE_NAME}"
	cat <<-'EOF'
		本文件为uupdump转换的原版iso
		若您需要在qemu虚拟机里使用，那么请手动制作Windows to Go启动盘
		您也可以阅览其它人所撰写的教程
		    https://zhuanlan.zhihu.com/p/32905265
	EOF
	download_windows_tmoe_iso_model
}
############
download_windows_tmoe_iso_model() {
	if [ -e "${ISO_FILE_NAME}" ]; then
		if (whiptail --title "检测到iso已下载,请选择您需要执行的操作！" --yes-button '设置为qemu iso' --no-button 'DL again重新下载' --yesno "Detected that the file has been downloaded" 7 60); then
			set_it_as_the_tmoe_qemu_iso
			${RETURN_TO_WHERE}
		else
			download_tmoe_iso_file_again
		fi
	else
		download_tmoe_iso_file_again
	fi
	printf "%s\n" "下载完成，是否将其设置为qemu启动光盘？${PURPLE}[Y/n]${RESET}"
	do_you_want_to_continue
	set_it_as_the_tmoe_qemu_iso
}
#########
download_windows_10_iso() {
	RETURN_TO_WHERE='download_windows_10_iso'
	VIRTUAL_TECH=$(whiptail --title "ISO FILE" --menu "Which win10 version do you want to download?" 12 55 4 \
		"1" "win10_2004_x64(多合一版)" \
		"2" "win10_2004_arm64" \
		"3" "other" \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) download_win10_2004_x64_iso ;;
	2) download_win10_19041_arm64_iso ;;
	3)
		cat <<-'EOF'
			如需下载其他版本，请前往microsoft官网
			https://www.microsoft.com/zh-cn/software-download/windows10ISO
			您亦可前往uupdump.ml，自行转换iso文件。
		EOF
		;;
	esac
	###############
	press_enter_to_return
	${RETURN_TO_WHERE}
}
#####################
download_linux_mint_debian_edition_iso() {
	if (whiptail --title "架构" --yes-button "x86_64" --no-button 'x86_32' --yesno "您想要下载哪个架构的版本？\n Which version do you want to download?" 9 50); then
		GREP_ARCH='64bit'
	else
		GREP_ARCH='32bit'
	fi
	#THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/linuxmint-cd/debian/lmde-4-cinnamon-64bit.iso"
	ISO_REPO='https://mirrors.huaweicloud.com/linuxmint-cd/debian/'
	THE_LATEST_FILE_VERSION=$(curl -L ${ISO_REPO} | grep "${GREP_ARCH}" | grep '.iso' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	THE_LATEST_ISO_LINK="${ISO_REPO}${THE_LATEST_FILE_VERSION}"
	aria2c_download_file
	stat ${THE_LATEST_FILE_VERSION}
	ls -lh ${DOWNLOAD_PATH}/${THE_LATEST_FILE_VERSION}
	printf "%s\n" "下载完成"
}
##########################
which_alpine_arch() {
	if (whiptail --title "请选择架构" --yes-button "x64" --no-button "arm64" --yesno "您是想要下载x86_64还是arm64架构的iso呢？\nDo you want to download x86_64 or arm64 iso?♪(^∇^*) " 0 50); then
		ALPINE_ARCH='x86_64'
	else
		ALPINE_ARCH='aarch64'
	fi
}
####################
download_alpine_virtual_iso() {
	which_alpine_arch
	WHICH_ALPINE_EDITION=$(
		whiptail --title "alpine EDITION" --menu "请选择您需要下载的版本？\nWhich edition do you want to download?" 0 50 0 \
			"1" "standard(标准版)" \
			"2" "extended(扩展版)" \
			"3" "virt(虚拟机版)" \
			"4" "xen(虚拟化)" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${WHICH_ALPINE_EDITION} in
	0 | "") download_virtual_machine_iso_file ;;
	1) ALPINE_EDITION='standard' ;;
	2) ALPINE_EDITION='extended' ;;
	3) ALPINE_EDITION='virt' ;;
	4) ALPINE_EDITION='xen' ;;
	esac
	###############
	download_the_latest_alpine_iso_file
	press_enter_to_return
	download_virtual_machine_iso_file
}
###############
download_the_latest_alpine_iso_file() {
	ALPINE_ISO_REPO="https://mirrors.bfsu.edu.cn/alpine/latest-stable/releases/${ALPINE_ARCH}/"
	RELEASE_FILE="${ALPINE_ISO_REPO}latest-releases.yaml"
	ALPINE_VERSION=$(curl -L ${RELEASE_FILE} | grep ${ALPINE_EDITION} | grep '.iso' | head -n 1 | awk -F ' ' '$0=$NF')
	THE_LATEST_ISO_LINK="${ALPINE_ISO_REPO}${ALPINE_VERSION}"
	aria2c_download_file
}
##################
download_ubuntu_iso_file() {
	if (whiptail --title "请选择版本" --yes-button "20.04" --no-button "custom" --yesno "您是想要下载20.04还是自定义版本呢？\nDo you want to download 20.04 or a custom version?♪(^∇^*) " 0 50); then
		UBUNTU_VERSION='20.04'
		download_ubuntu_latest_iso_file
	else
		TARGET=$(whiptail --inputbox "请输入版本号，例如18.04\n Please type the ubuntu version code." 0 50 --title "UBUNTU VERSION" 3>&1 1>&2 2>&3)
		if [ "$?" != "0" ]; then
			printf "%s\n" "检测到您取消了操作"
			UBUNTU_VERSION='20.04'
		else
			UBUNTU_VERSION="$(printf '%s\n' "${TARGET}" | head -n 1 | cut -d ' ' -f 1)"
		fi
	fi
	download_ubuntu_latest_iso_file
}
#############
download_ubuntu_latest_iso_file() {
	UBUNTU_MIRROR='tuna'
	UBUNTU_EDITION=$(
		whiptail --title "UBUNTU EDITION" --menu "请选择您需要下载的版本？\nWhich edition do you want to download?" 0 50 0 \
			"1" "ubuntu-server(自动识别架构)" \
			"2" "ubuntu(gnome)" \
			"3" "xubuntu(xfce)" \
			"4" "kubuntu(kde plasma)" \
			"5" "lubuntu(lxqt)" \
			"6" "ubuntu-mate" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${UBUNTU_EDITION} in
	0 | "") download_virtual_machine_iso_file ;;
	1) UBUNTU_DISTRO='ubuntu-legacy-server' ;;
	2) UBUNTU_DISTRO='ubuntu-gnome' ;;
	3) UBUNTU_DISTRO='xubuntu' ;;
	4) UBUNTU_DISTRO='kubuntu' ;;
	5) UBUNTU_DISTRO='lubuntu' ;;
	6) UBUNTU_DISTRO='ubuntu-mate' ;;
	esac
	###############
	if [ ${UBUNTU_DISTRO} = 'ubuntu-gnome' ]; then
		download_ubuntu_huawei_mirror_iso
	else
		download_ubuntu_tuna_mirror_iso
	fi
	press_enter_to_return
	download_virtual_machine_iso_file
}
###############
ubuntu_arm_warning() {
	printf "%s\n" "请选择Server版"
	arch_does_not_support
	download_ubuntu_latest_iso_file
}
################
download_ubuntu_huawei_mirror_iso() {
	case "${ARCH_TYPE}" in
	"i386") THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/ubuntu-releases/16.04.6/ubuntu-16.04.6-desktop-i386.iso" ;;
	*) THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/ubuntu-releases/${UBUNTU_VERSION}/ubuntu-${UBUNTU_VERSION}-desktop-amd64.iso" ;;
	esac
	aria2c_download_file
}
####################
get_ubuntu_server_iso_url() {
	case "${ARCH_TYPE}" in
	"amd64") THE_LATEST_ISO_LINK="https://mirrors.bfsu.edu.cn/ubuntu-cdimage/${UBUNTU_DISTRO}/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-legacy-server-${ARCH_TYPE}.iso" ;;
	"i386") THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/ubuntu-releases/16.04.6/ubuntu-16.04.6-server-i386.iso" ;;
	*) THE_LATEST_ISO_LINK="https://mirrors.bfsu.edu.cn/ubuntu-cdimage/ubuntu/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-live-server-${ARCH_TYPE}.iso" ;;
	esac
}
##############
get_other_ubuntu_distros_url() {
	case "${ARCH_TYPE}" in
	"i386") THE_LATEST_ISO_LINK="https://mirrors.bfsu.edu.cn/ubuntu-cdimage/${UBUNTU_DISTRO}/releases/18.04.4/release/${UBUNTU_DISTRO}-18.04.4-desktop-i386.iso" ;;
	*) THE_LATEST_ISO_LINK="https://mirrors.bfsu.edu.cn/ubuntu-cdimage/${UBUNTU_DISTRO}/releases/${UBUNTU_VERSION}/release/${UBUNTU_DISTRO}-${UBUNTU_VERSION}-desktop-amd64.iso" ;;
	esac
}
################
download_ubuntu_tuna_mirror_iso() {
	if [ ${UBUNTU_DISTRO} = 'ubuntu-legacy-server' ]; then
		get_ubuntu_server_iso_url
	else
		get_other_ubuntu_distros_url
	fi
	aria2c_download_file
}
#######################
download_android_x86_file() {
	REPO_URL='https://mirrors.bfsu.edu.cn/osdn/android-x86/'
	REPO_FOLDER=$(curl -L ${REPO_URL} | grep -v incoming | grep date | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	case "${ARCH_TYPE}" in
	"i386") THE_LATEST_ISO_VERSION=$(curl -L ${REPO_URL}${REPO_FOLDER} | grep -v 'x86_64' | grep date | grep '.iso' | tail -n 1 | head -n 1 | cut -d '=' -f 4 | cut -d '"' -f 2) ;;
	*) THE_LATEST_ISO_VERSION=$(curl -L ${REPO_URL}${REPO_FOLDER} | grep date | grep '.iso' | tail -n 1 | cut -d '=' -f 4 | cut -d '"' -f 2) ;;
	esac
	THE_LATEST_ISO_LINK="${REPO_URL}${REPO_FOLDER}${THE_LATEST_ISO_VERSION}"
	#printf "%s\n" "${THE_LATEST_ISO_LINK}"
	#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_ISO_VERSION}" "${THE_LATEST_ISO_LINK}"
	aria2c_download_file
}
################
download_debian_qcow2_file() {
	DOWNLOAD_PATH="${HOME}/sd/Download/backup"
	mkdir -p ${DOWNLOAD_PATH}
	cd ${DOWNLOAD_PATH}
	if (whiptail --title "Edition" --yes-button "tmoe" --no-button 'openstack_arm64' --yesno "您想要下载哪个版本的磁盘镜像文件？\nWhich edition do you want to download?" 0 50); then
		download_tmoe_debian_x64_or_arm64_qcow2_file
	else
		GREP_ARCH='arm64'
		QCOW2_REPO='https://mirrors.ustc.edu.cn/debian-cdimage/openstack/current/'
		THE_LATEST_FILE_VERSION=$(curl -L ${QCOW2_REPO} | grep "${GREP_ARCH}" | grep qcow2 | grep -v '.index' | cut -d '=' -f 2 | cut -d '"' -f 2 | tail -n 1)
		THE_LATEST_ISO_LINK="${QCOW2_REPO}${THE_LATEST_FILE_VERSION}"
		aria2c_download_file
		stat ${THE_LATEST_FILE_VERSION}
		qemu-img info ${THE_LATEST_FILE_VERSION}
		ls -lh ${DOWNLOAD_PATH}/${THE_LATEST_FILE_VERSION}
		printf "%s\n" "下载完成"
	fi
}
###################
note_of_qemu_boot_uefi() {
	printf '%s\n' '使用此磁盘需要将引导方式切换至UEFI'
	printf '%s\n' 'You should modify the boot method to uefi.'
}
############
note_of_qemu_boot_legacy_bios() {
	printf '%s\n' '使用此磁盘需要将引导方式切换回默认'
	printf '%s\n' 'You should modify the boot method to legacy bios.'
}
#############
note_of_tmoe_password() {
	printf "%s\n" "user:tmoe  password:tmoe"
	printf "%s\n" "用户：tmoe  密码：tmoe"
}
##############
note_of_empty_root_password() {
	printf '%s\n' 'user:root'
	printf '%s\n' 'The password is empty.'
	printf '%s\n' '用户名root，密码为空'
}
################
download_lmde_4_qcow2_file() {
	cd ${DOWNLOAD_PATH}
	DOWNLOAD_FILE_NAME='LMDE4_tmoe_x64.tar.xz'
	QEMU_DISK_FILE_NAME='LMDE4_tmoe_x64.qcow2'
	printf '%s\n' 'Download size(下载大小)约2.76GiB，解压后约为9.50GiB'
	THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/LMDE4_tmoe_x64.tar.xz'
	note_of_qemu_boot_legacy_bios
	note_of_tmoe_password
	do_you_want_to_continue
	download_debian_tmoe_qemu_qcow2_file
}
############
download_windows_server_2008_data_center_qcow2_file() {
	cd ${DOWNLOAD_PATH}
	DOWNLOAD_FILE_NAME='win2008_r2_tmoe_x64.tar.xz'
	QEMU_DISK_FILE_NAME='win2008_r2_tmoe_x64.qcow2'
	printf '%s\n' 'Download size(下载大小)约2.26GiB，解压后约为12.6GiB'
	THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/win2008_r2_tmoe_x64.tar.xz'
	note_of_qemu_boot_legacy_bios
	printf '%s\n' '进入虚拟机后，您需要自己设定一个密码'
	do_you_want_to_continue
	download_debian_tmoe_qemu_qcow2_file
}
#####################
download_ubuntu_kylin_20_04_qcow2_file() {
	cd ${DOWNLOAD_PATH}
	DOWNLOAD_FILE_NAME='ubuntu_kylin_20-04_tmoe_x64.tar.xz'
	QEMU_DISK_FILE_NAME='ubuntu_kylin_20-04_tmoe_x64.qcow2'
	printf '%s\n' 'Download size(下载大小)约1.81GiB，解压后约为7.65GiB'
	THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/ubuntu_kylin_20-04_tmoe_x64.tar.xz'
	note_of_qemu_boot_uefi
	note_of_tmoe_password
	do_you_want_to_continue
	download_debian_tmoe_qemu_qcow2_file
}
###################
download_arch_linux_qcow2_file() {
	cd ${DOWNLOAD_PATH}
	DOWNLOAD_FILE_NAME='arch_linux_x64_tmoe_20200605.tar.xz'
	QEMU_DISK_FILE_NAME='arch_linux_x64_tmoe_20200605.qcow2'
	printf '%s\n' 'Download size(下载大小)约678MiB，解压后约为‪1.755GiB'
	#THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/arch_linux_x64_tmoe_20200605.tar.xz'
	note_of_qemu_boot_legacy_bios
	note_of_empty_root_password
	do_you_want_to_continue
	check_arch_linux_qemu_qcow2_file
}
################
check_arch_linux_qemu_qcow2_file() {
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it, or download it again?" 0 0); then
			printf "%s\n" "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			git_clone_arch_linux_qemu_qcow2_file
		fi
	else
		git_clone_arch_linux_qemu_qcow2_file
	fi
	uncompress_alpine_and_docker_x64_img_file
	set_it_as_default_qemu_disk
}
#################
git_clone_arch_linux_qemu_qcow2_file() {
	cd /tmp
	mkdir -p .ARCH_QEMU_TEMP_FOLDER
	cd .ARCH_QEMU_TEMP_FOLDER
	git clone --depth=1 -b x64 https://gitee.com/ak2/arch_qemu_01 .ARCH_QEMU_TEMP_FOLDER_01
	cd .ARCH_QEMU_TEMP_FOLDER_01
	mv -f arch_linux_* ../
	cd ..
	git clone --depth=1 -b x64 https://gitee.com/ak2/arch_qemu_02 .ARCH_QEMU_TEMP_FOLDER_02
	cd .ARCH_QEMU_TEMP_FOLDER_02
	mv -f arch_linux_* ../
	cd ..
	cat arch_linux_* >${DOWNLOAD_FILE_NAME}
	mv -f ${DOWNLOAD_FILE_NAME} ${DOWNLOAD_PATH}
	cd ../
	rm -rf .ARCH_QEMU_TEMP_FOLDER
	cd ${DOWNLOAD_PATH}
}
################
git_clone_tmoe_linux_qemu_qcow2_file() {
	cd /tmp
	git clone --depth=1 -b ${BRANCH_NAME} ${TMOE_LINUX_QEMU_REPO} .${DOWNLOAD_FILE_NAME}_QEMU_TEMP_FOLDER
	cd .${DOWNLOAD_FILE_NAME}_QEMU_TEMP_FOLDER
	sed -n p ${QEMU_QCOW2_FILE_PREFIX}* >${DOWNLOAD_FILE_NAME}
	mv -f ${DOWNLOAD_FILE_NAME} ${DOWNLOAD_PATH}
	cd ../
	rm -rf .${DOWNLOAD_FILE_NAME}_QEMU_TEMP_FOLDER
	cd ${DOWNLOAD_PATH}
}
################
download_tmoe_debian_x64_or_arm64_qcow2_file() {
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	QEMU_ARCH=$(
		whiptail --title "Debian qcow2 tmoe edition" --menu "Which version do you want to download？\n您想要下载哪个版本的磁盘文件?${QEMU_ARCH_STATUS}" 0 0 0 \
			"1" "Buster x86_64" \
			"2" "Buster arm64" \
			"3" "关于ssh-server的说明" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${QEMU_ARCH} in
	0 | "") tmoe_qemu_templates_repo ;;
	1)
		DOWNLOAD_FILE_NAME='debian-10.4-generic-20200604_tmoe_x64.tar.xz'
		QEMU_DISK_FILE_NAME='debian-10-generic-20200604_tmoe_x64.qcow2'
		CURRENT_TMOE_QEMU_BIN='/usr/bin/qemu-system-aarch64'
		LATER_TMOE_QEMU_BIN='/usr/bin/qemu-system-x86_64'
		printf '%s\n' 'Download size(下载大小)约282MiB，解压后约为‪1.257GiB'
		#THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/debian-10.4-generic-20200604_tmoe_x64.tar.xz'
		TMOE_LINUX_QEMU_REPO='https://gitee.com/ak2/debian_qemu'
		BRANCH_NAME='x64'
		QEMU_QCOW2_FILE_PREFIX='debian_linux_'
		;;
	2)
		DOWNLOAD_FILE_NAME='debian-10.4.1-20200515-tmoe_arm64.tar.xz'
		QEMU_DISK_FILE_NAME='debian-10.4.1-20200515-tmoe_arm64.qcow2'
		printf '%s\n' 'Download size(下载大小)约339MiB，解压后约为‪1.6779GiB'
		printf '%s\n' '本系统为arm64版，请在下载完成后，手动进入tmoe-qemu arm64专区选择磁盘文件'
		#THE_LATEST_ISO_LINK='https://webdav.tmoe.me/down/share/Tmoe-linux/qemu/debian-10.4.1-20200515-tmoe_arm64.tar.xz'
		TMOE_LINUX_QEMU_REPO='https://gitee.com/ak2/debian_arm64_qemu'
		BRANCH_NAME='arm64'
		QEMU_QCOW2_FILE_PREFIX='debian_linux_'
		;;
	3)
		cat <<-'EOF'
			       若sshd启动失败，则请执行dpkg-reconfigure openssh-server
				   如需使用密码登录ssh，则您需要手动修改sshd配置文件
				   cd /etc/ssh
				   sed -i 's@PermitRootLogin.*@PermitRootLogin yes@' sshd_config
			       sed -i 's@PasswordAuthentication.*@PasswordAuthentication yes@' sshd_config
		EOF
		press_enter_to_return
		download_tmoe_debian_x64_or_arm64_qcow2_file
		;;
	esac
	###############
	do_you_want_to_continue
	#download_debian_tmoe_qemu_qcow2_file
	check_tmoe_qemu_qcow2_file_and_git
	press_enter_to_return
	download_tmoe_debian_x64_or_arm64_qcow2_file
}
#####################
#################
set_it_as_default_qemu_disk() {
	printf "%s\n" "文件已解压至${DOWNLOAD_PATH}"
	cd ${DOWNLOAD_PATH}
	qemu-img check ${QEMU_DISK_FILE_NAME}
	qemu-img info ${QEMU_DISK_FILE_NAME}
	printf "%s\n" "是否将其设置为默认的qemu磁盘？"
	do_you_want_to_continue
	cd /usr/local/bin
	sed -i '/-hda /d' startqemu
	sed -i '$!N;$!P;$!D;s/\(\n\)/\n    -hda tmoe_hda_config_test \\\n/' startqemu
	sed -i "s@-hda tmoe_hda_config_test@-hda ${TMOE_FILE_ABSOLUTE_PATH}@" startqemu
	sed -i "s@${CURRENT_TMOE_QEMU_BIN}@${LATER_TMOE_QEMU_BIN}@" startqemu
	if [ ${QEMU_DISK_FILE_NAME} = 'arch_linux_x64_tmoe_20200605.qcow2' ]; then
		sed -i '/-bios /d' startqemu
	fi
	# sed -i 's@/usr/bin/qemu-system-x86_64@/usr/bin/qemu-system-aarch64@' startqemu
	printf "%s\n" "设置完成，您之后可以输startqemu启动"
	printf "%s\n" "若启动失败，则请检查qemu的相关设置选项"
}
##################
download_debian_tmoe_qemu_qcow2_file() {
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it, or download it again?" 0 0); then
			printf "%s\n" "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			download_debian_tmoe_arm64_img_file_again
		fi
	else
		download_debian_tmoe_arm64_img_file_again
	fi
	uncompress_alpine_and_docker_x64_img_file
	set_it_as_default_qemu_disk
}
#############
check_tmoe_qemu_qcow2_file_and_git() {
	TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
	if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
		if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it, or download it again?" 0 0); then
			printf "%s\n" "解压后将重置虚拟机的所有数据"
			do_you_want_to_continue
		else
			git_clone_tmoe_linux_qemu_qcow2_file
		fi
	else
		git_clone_tmoe_linux_qemu_qcow2_file
	fi
	uncompress_alpine_and_docker_x64_img_file
	set_it_as_default_qemu_disk
}
##############################
download_debian_tmoe_arm64_img_file_again() {
	aria2c --allow-overwrite=true -s 16 -x 16 -k 1M "${THE_LATEST_ISO_LINK}"
}
##########
download_debian_iso_file() {
	DEBIAN_FREE='unkown'
	DEBIAN_ARCH=$(
		whiptail --title "architecture" --menu "请选择您需要下载的架构版本\nwhich architecture version do you want to download?\nnon-free版包含了非自由固件(例如闭源无线网卡驱动等)" 0 50 0 \
			"1" "x64(non-free,unofficial)" \
			"2" "x86(non-free,unofficial)" \
			"3" "x64(free)" \
			"4" "x86(free)" \
			"5" "arm64" \
			"6" "armhf" \
			"7" "mips" \
			"8" "mipsel" \
			"9" "mips64el" \
			"10" "ppc64el" \
			"11" "s390x" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${DEBIAN_ARCH} in
	0 | "") download_virtual_machine_iso_file ;;
	1)
		GREP_ARCH='amd64'
		DEBIAN_FREE='false'
		download_debian_nonfree_iso
		;;
	2)
		GREP_ARCH='i386'
		DEBIAN_FREE='false'
		download_debian_nonfree_iso
		;;
	3)
		GREP_ARCH='amd64'
		DEBIAN_FREE='true'
		download_debian_nonfree_iso
		;;
	4)
		GREP_ARCH='i386'
		DEBIAN_FREE='true'
		download_debian_nonfree_iso
		;;
	5) GREP_ARCH='arm64' ;;
	6) GREP_ARCH='armhf' ;;
	7) GREP_ARCH='mips' ;;
	8) GREP_ARCH='mipsel' ;;
	9) GREP_ARCH='mips64el' ;;
	10) GREP_ARCH='ppc64el' ;;
	11) GREP_ARCH='s390x' ;;
	esac
	###############
	if [ ${DEBIAN_FREE} = 'unkown' ]; then
		download_debian_weekly_builds_iso
	fi
	press_enter_to_return
	download_virtual_machine_iso_file
}
##################
download_debian_nonfree_iso() {
	#16 55 8
	DEBIAN_LIVE=$(
		whiptail --title "Desktop environment" --menu "您下载的镜像中需要包含何种桌面环境？\nWhich desktop environment do you prefer?" 0 0 0 \
			"1" "cinnamon" \
			"2" "gnome" \
			"3" "kde plasma" \
			"4" "lxde" \
			"5" "lxqt" \
			"6" "mate" \
			"7" "standard(默认无桌面)" \
			"8" "xfce" \
			"0" "🌚 Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${DEBIAN_LIVE} in
	0 | "") download_debian_iso_file ;;
	1) DEBIAN_DE='cinnamon' ;;
	2) DEBIAN_DE='gnome' ;;
	3) DEBIAN_DE='kde' ;;
	4) DEBIAN_DE='lxde' ;;
	5) DEBIAN_DE='lxqt' ;;
	6) DEBIAN_DE='mate' ;;
	7) DEBIAN_DE='standard' ;;
	8) DEBIAN_DE='xfce' ;;
	esac
	##############
	if [ ${DEBIAN_FREE} = 'false' ]; then
		download_debian_nonfree_live_iso
	else
		download_debian_free_live_iso
	fi
}
###############
download_debian_weekly_builds_iso() {
	#https://mirrors.ustc.edu.cn/debian-cdimage/weekly-builds/arm64/iso-cd/debian-testing-arm64-netinst.iso
	THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/weekly-builds/${GREP_ARCH}/iso-cd/debian-testing-${GREP_ARCH}-netinst.iso"
	printf "%s\n" "${THE_LATEST_ISO_LINK}"
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-testing-${GREP_ARCH}-netinst.iso" "${THE_LATEST_ISO_LINK}"
}
##################
download_debian_free_live_iso() {
	THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/weekly-live-builds/${GREP_ARCH}/iso-hybrid/debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}.iso"
	printf "%s\n" "${THE_LATEST_ISO_LINK}"
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}.iso" "${THE_LATEST_ISO_LINK}"
}
############
download_debian_nonfree_live_iso() {
	THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/unofficial/non-free/cd-including-firmware/weekly-live-builds/${GREP_ARCH}/iso-hybrid/debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}%2Bnonfree.iso"
	printf "%s\n" "${THE_LATEST_ISO_LINK}"
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}-nonfree.iso" "${THE_LATEST_ISO_LINK}"
}
####################
qemu_main "$@"
###############################
