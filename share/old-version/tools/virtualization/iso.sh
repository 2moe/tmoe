#!/usr/bin/env bash
#######################
choose_qcow2_or_iso() {
    if (whiptail --title "QEMU QCOW OR COMMON ISO" --yes-button 'qcow2' --no-button 'iso' --yesno "Do you want to choose qemu qcow2 repo or iso repo(っ °Д °)?" 0 0); then
        tmoe_qemu_templates_repo
    else
        download_virtual_machine_iso_file
    fi
}
#####################
download_virtual_machine_iso_file() {
    RETURN_TO_WHERE='download_virtual_machine_iso_file'
    DOWNLOAD_PATH="${HOME}/sd/Download"
    mkdir -pv ${DOWNLOAD_PATH}
    cd ${DOWNLOAD_PATH}
    TMOE_VIRTUALIZATION=$(whiptail --title "IMAGE FILE" --menu "Which image file do you want to download?" 0 50 0 \
        "1" "alpine(latest-stable)" \
        "2" "Android x86_64(latest)" \
        "3" "debian-iso(每周自动构建,包含non-free)" \
        "4" "ubuntu" \
        "5" "windows 11" \
        "6" "LMDE(Linux Mint Debian Edition)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    #############
    case ${TMOE_VIRTUALIZATION} in
    0 | "") install_container_and_virtual_machine ;;
    1) download_alpine_virtual_iso ;;
    2) download_android_x86_file ;;
    3) download_debian_iso_file ;;
    4) download_ubuntu_iso_file ;;
    5) download_windows_10_iso ;;
    6) download_linux_mint_debian_edition_iso ;;
    esac
    ###############
    press_enter_to_return
    download_virtual_machine_iso_file
}
###########
download_tmoe_iso_file_again() {
    printf "%s\n" "即将为您下载win10 iso镜像文件..."
    aria2c --console-log-level=warn --no-conf -x 6 -k 1M --split=6 --allow-overwrite=true -o "${ISO_FILE_NAME}" "${TMOE_ISO_URL}"
    qemu-img info ${ISO_FILE_NAME}
}
##########
download_win11_x64_iso() {
    ISO_FILE_NAME='win11_x64.iso'
    TMOE_FILE_ABSOLUTE_PATH=$(pwd)/${ISO_FILE_NAME}
    # TMOE_ISO_URL="https://m.tmoe.me/win10_x64-latest-iso"
    TMOE_ISO_URL="https://packages.tmoe.me/iso/21996.1.210529-1541.co_release_CLIENT_CONSUMER_x64FRE_en-us.iso"
    download_windows_tmoe_iso_model
}
#############################
download_win10_arm64_iso() {
    ISO_FILE_NAME='win10-19042_arm64.iso'
    TMOE_FILE_ABSOLUTE_PATH=$(pwd)/${ISO_FILE_NAME}
    TMOE_ISO_URL="https://m.tmoe.me/win10_arm64-latest-iso"
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
        if (whiptail --title "检测到iso已下载,请选择您需要执行的操作！" --yes-button 'back' --no-button 'DL again重新下载' --yesno "Detected that the file has been downloaded" 7 60); then
            ${RETURN_TO_WHERE}
        else
            download_tmoe_iso_file_again
        fi
    else
        download_tmoe_iso_file_again
    fi
}
#########
download_windows_10_iso() {
    RETURN_TO_WHERE='download_windows_10_iso'
    TMOE_VIRTUALIZATION=$(whiptail --title "ISO FILE" --menu "Which win version do you want to download?" 12 55 4 \
        "1" "win11_21996_x64" \
        "2" "win10_20h2_arm64(uup)" \
        "3" "other" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    #############
    case ${TMOE_VIRTUALIZATION} in
    0 | "") install_container_and_virtual_machine ;;
    1) download_win11_x64_iso ;;
    2) download_win10_arm64_iso ;;
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
            "4" "xen(虚拟化版)" \
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
    #aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_ISO_VERSION}" "${THE_LATEST_ISO_LINK}"
    aria2c_download_file
}
download_debian_iso_file() {
    DEBIAN_FREE='unknown'
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
        DEBIAN_FREE=false
        download_debian_nonfree_iso
        ;;
    2)
        GREP_ARCH='i386'
        DEBIAN_FREE=false
        download_debian_nonfree_iso
        ;;
    3)
        GREP_ARCH='amd64'
        DEBIAN_FREE=true
        download_debian_nonfree_iso
        ;;
    4)
        GREP_ARCH='i386'
        DEBIAN_FREE=true
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
    if [ ${DEBIAN_FREE} = 'unknown' ]; then
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
    aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-testing-${GREP_ARCH}-netinst.iso" "${THE_LATEST_ISO_LINK}"
}
##################
download_debian_free_live_iso() {
    THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/weekly-live-builds/${GREP_ARCH}/iso-hybrid/debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}.iso"
    printf "%s\n" "${THE_LATEST_ISO_LINK}"
    aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}.iso" "${THE_LATEST_ISO_LINK}"
}
############
download_debian_nonfree_live_iso() {
    THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/unofficial/non-free/cd-including-firmware/weekly-live-builds/${GREP_ARCH}/iso-hybrid/debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}%2Bnonfree.iso"
    printf "%s\n" "${THE_LATEST_ISO_LINK}"
    aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}-nonfree.iso" "${THE_LATEST_ISO_LINK}"
}
####################
################
################
note_of_empty_root_password() {
    printf '%s\n' 'user:root'
    printf '%s\n' 'The password is empty.'
    printf '%s\n' '用户名root，密码为空'
}
###################
download_win10_qcow2_file() {
    cd ${DOWNLOAD_PATH}
    QEMU_NAME="win10-20h2_x64-tmoe_202011"
    QEMU_DISK_FILE_NAME="${QEMU_NAME}.qcow2"
    DOWNLOAD_FILE_NAME="${QEMU_NAME}.qcow2.tar.xz"
    printf '%s\n' 'Download size(下载大小)约5.4GiB，解压后约为‪15GiB。若宿主磁盘空间不足，或不支持单文件大于4G,则将下载/解压失败。'
    printf "%s\n" "为增强virtio-blk-device的兼容性，故关闭了win10的快速启动。若您使用的是KVM加速，则预计开机时间为2-3分钟;若为跨cpu架构+TCG，则开机时间可能长达数小时。当开机时出现磁盘检查的提示时，请按任意键跳过。"
    printf "%s\n" "本镜像为${PURPLE}完整${RESET}win10系统，并且内置了${BLUE}VC++ 2015-2019,Net3.5,DirectX${RESET}等组件。"
    THE_LATEST_ISO_LINK="https://redirect.tmoe.me/down/share/Tmoe-linux/qemu/202011/${DOWNLOAD_FILE_NAME}?download=1"
    note_of_empty_root_password
    do_you_want_to_continue
    check_arch_linux_qemu_qcow2_file
}
##################
download_arch_linux_qcow2_file() {
    cd ${DOWNLOAD_PATH}
    QEMU_NAME="arch_x64-tmoe-202011"
    QEMU_DISK_FILE_NAME="${QEMU_NAME}.qcow2"
    DOWNLOAD_FILE_NAME="${QEMU_NAME}.qcow2.tar.xz"
    printf '%s\n' 'Download size(下载大小)约995.2MiB，解压后约为‪2.7GiB'
    THE_LATEST_ISO_LINK="https://redirect.tmoe.me/down/share/Tmoe-linux/qemu/202011/${DOWNLOAD_FILE_NAME}?download=1"
    note_of_empty_root_password
    do_you_want_to_continue
    check_arch_linux_qemu_qcow2_file
}
################
download_ubuntu_linux_qcow2_file() {
    cd ${DOWNLOAD_PATH}
    QEMU_NAME="ubuntu_x64-tmoe-202011"
    DOWNLOAD_FILE_NAME='ubuntu-focal_amd64-tmoe_20201118.tar.xz'
    QEMU_DISK_FILE_NAME='ubuntu-focal_amd64-tmoe_20201118.qcow2'
    printf '%s\n' 'Download size(下载大小)约1.4GiB，解压后约为‪5.14GiB'
    THE_LATEST_ISO_LINK="https://redirect.tmoe.me/down/share/Tmoe-linux/qemu/202011/${DOWNLOAD_FILE_NAME}?download=1"
    note_of_empty_root_password
    do_you_want_to_continue
    check_arch_linux_qemu_qcow2_file
}
####################
download_kali_linux_qcow2_file() {
    cd ${DOWNLOAD_PATH}
    QEMU_NAME="kali_x64-tmoe-202011"
    DOWNLOAD_FILE_NAME='kali_linux_x64_tmoe_20201117.tar.xz'
    QEMU_DISK_FILE_NAME='kali_linux_x64_tmoe_20201117.qcow2'
    printf '%s\n' 'Download size(下载大小)约3.3GiB，解压后约为‪11.64GiB'
    THE_LATEST_ISO_LINK="https://redirect.tmoe.me/down/share/Tmoe-linux/qemu/202011/${DOWNLOAD_FILE_NAME}?download=1"
    note_of_empty_root_password
    do_you_want_to_continue
    check_arch_linux_qemu_qcow2_file
}
####################
check_arch_linux_qemu_qcow2_file() {
    TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
    if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
        if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it, or download it again?" 0 0); then
            printf "%s\n" "解压后将重置磁盘文件的所有数据"
            do_you_want_to_continue
        else
            aria2c_download_tmoe_qemu_file
        fi
    else
        aria2c_download_tmoe_qemu_file
    fi
    uncompress_alpine_and_docker_x64_img_file
}
################
aria2c_download_tmoe_qemu_file() {
    printf "%s\n" "The file is ${YELLOW}${TMOE_FILE_ABSOLUTE_PATH}${RESET}"
    do_you_want_to_continue
    aria2c_download_file_00
    aria2c --console-log-level=warn --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M "${THE_LATEST_ISO_LINK}"
}
download_debian_qcow2_file() {
    DOWNLOAD_PATH="${HOME}/sd/Download/qemu"
    QEMU_NAME="debian_x64-tmoe-202011"
    mkdir -pv ${DOWNLOAD_PATH}
    cd ${DOWNLOAD_PATH}
    if (whiptail --title "Edition" --yes-button "bullseye-tmoe" --no-button 'buster-openstack' --yesno "您想要下载哪个版本的磁盘镜像文件?\nWhich edition do you want to download?" 0 50); then
        tmoe_qemu_debian_qcow2
    else
        GREP_ARCH='amd64'
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
##############
tmoe_qemu_debian_qcow2() {
    TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
    QEMU_ARCH=$(
        whiptail --title "Debian qcow2 tmoe edition" --menu "${QEMU_ARCH_STATUS}" 0 0 0 \
            "1" "Bullseye amd64" \
            "2" "关于ssh-server的说明" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ####################
    case ${QEMU_ARCH} in
    0 | "") tmoe_qemu_templates_repo ;;
    1)
        DOWNLOAD_FILE_NAME='debian-bullseye_amd64-20201117_tmoe.tar.xz'
        QEMU_DISK_FILE_NAME='debian-bullseye_amd64-20201117_tmoe.qcow2'
        printf '%s\n' 'Download size(下载大小)约766.6MiB，解压后约为‪3.5GiB'
        THE_LATEST_ISO_LINK="https://redirect.tmoe.me/down/share/Tmoe-linux/qemu/202011/${DOWNLOAD_FILE_NAME}?download=1"
        ;;
    2)
        cat <<-'EOF'
			       若sshd启动失败，则请执行dpkg-reconfigure openssh-server
				   如需使用密码登录ssh，则您需要手动修改sshd配置文件
				   cd /etc/ssh
				   sed -i 's@PermitRootLogin.*@PermitRootLogin yes@' sshd_config
			       sed -i 's@PasswordAuthentication.*@PasswordAuthentication yes@' sshd_config
		EOF
        press_enter_to_return
        tmoe_qemu_debian_qcow2
        ;;
    esac
    ###############
    do_you_want_to_continue
    download_debian_tmoe_qemu_qcow2_file
    press_enter_to_return
    tmoe_qemu_debian_qcow2
}
#####################
download_debian_tmoe_qemu_qcow2_file() {
    TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
    if [ -f "${DOWNLOAD_FILE_NAME}" ]; then
        if (whiptail --title "检测到压缩包已下载,请选择您需要执行的操作！" --yes-button '解压uncompress' --no-button '重下DL again' --yesno "Detected that the file has been downloaded.\nDo you want to unzip it, or download it again?" 0 0); then
            printf "%s\n" "解压后将重置虚拟机的所有数据"
            do_you_want_to_continue
        else
            aria2c_download_file
        fi
    else
        aria2c_download_file
    fi
    uncompress_alpine_and_docker_x64_img_file
}
#############
tmoe_qemu_templates_repo() {
    RETURN_TO_WHERE='tmoe_qemu_templates_repo'
    DOWNLOAD_PATH="${HOME}/sd/Download/qemu"
    mkdir -pv ${DOWNLOAD_PATH}
    BLK_DEVICE="VIRTIO_DISK_01"
    cd ${DOWNLOAD_PATH}
    RTC_BASE=utc
    GPU_MODEL=virtio-vga
    TMOE_VIRTUALIZATION=$(
        whiptail --title "QEMU TEMPLATES" --menu "以下所有linux image均内置docker容器引擎" 0 50 0 \
            "1" "Alpine-3.12_x64(213M->1.1G,legacy)" \
            "2" "Arch_x64(1G->3G,legacy)" \
            "3" "Debian-bullseye_x64(766M->3G,legacy)" \
            "4" "Ubuntu-focal_x64(1.4G->5G,legacy)" \
            "5" "Kali_x64(xfce4,3.3G->11.6G,legacy)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    #############
    #	"2" "Server2012r2转win8.1_x64" \
    #以下所有镜像均支持virtio-blk-device;\n
    #"2" "Win10-20h2_x64 RD-server(5.4G->15G,legacy)" \	9999) download_win10_qcow2_file ;;
    case ${TMOE_VIRTUALIZATION} in
    0 | "") ${RETURN_TO_MENU} ;;
    1) download_alpine_and_docker_x64_img_file ;;
    2) download_arch_linux_qcow2_file ;;
    3) download_debian_qcow2_file ;;
    4) download_ubuntu_linux_qcow2_file ;;
    5) download_kali_linux_qcow2_file ;;
    esac
    press_enter_to_return
    tmoe_qemu_templates_repo
}
##########
#zstd -z -22 -T0 -v --ultra
#old已废弃
download_alpine_and_docker_x64_img_file_again_old() {
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
    cd /tmp
    git clone --depth=1 https://gitee.com/ak2/alpine-3.12_amd64-qemu .ALPINE_QEMU_TEMP_FOLDER
    cd .ALPINE_QEMU_TEMP_FOLDER
    cat .qemu_image* >alpine-3.12_amd64-tmoe_20201118.tar.xz
    mv alpine-3.12_amd64-tmoe_20201118.tar.xz ${DOWNLOAD_PATH}
    cd ../
    rm -rvf .ALPINE_QEMU_TEMP_FOLDER
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
    QEMU_DIR="${TMOE_LINUX_DIR}/qemu/list"
    [[ -e ${QEMU_DIR} ]] || mkdir -pv ${QEMU_DIR}
    QEMU_FILE="${QEMU_DIR}/${QEMU_NAME}"
    cp -vf ${TMOE_TOOL_DIR}/virtualization/qemu/startqemu ${QEMU_FILE}
    chmod -v 777 ${QEMU_FILE}
    sed -E -i "s@^(QEMU_NAME=).*@\1${QEMU_NAME}@g" ${QEMU_FILE}
    sed -E -i "s@^(RTC_BASE=).*@\1${RTC_BASE}@g" ${QEMU_FILE}
    sed -E -i "s@^(GPU_MODEL=).*@\1${GPU_MODEL}@g" ${QEMU_FILE}
    sed -E -i "s@^(${BLK_DEVICE}=).*@\1"${TMOE_FILE_ABSOLUTE_PATH}"@g;s@^(${BLK_DEVICE}_ENABLED=).*@\1true@g" ${QEMU_FILE}
    grep -E --color=auto "^QEMU_NAME=|^${BLK_DEVICE}_ENABLED=|^${BLK_DEVICE}=|^RTC_BASE=|^GPU_MODEL=" ${QEMU_FILE}
    ln -svf ${QEMU_FILE} /usr/local/bin/startqemu
    printf "%s\n" "You can type ${GREEN}startqemu${RESET} to start ${BLUE}${QEMU_NAME}${RESET}."
    #TMOE_FILE_ABSOLUTE_PATH
    printf "%s\n" "您之后可以输${GREEN}startqemu${RESET}来启动${BLUE}${QEMU_NAME}${RESET}."
}
##############
download_alpine_and_docker_x64_img_file() {
    cat <<-EOF
		You can use this image to run docker on Android system.
		The password of the root account is empty. After starting the qemu virtual machine, open the vnc client and enter localhost:5905. 
		The default root passwd is empty.
		After entering the system,you should type ${GREEN}passwd${RESET} to change your password.
		If you want to use ssh connection, please create a new termux session, and then install openssh client. Finally, you can type ${GREEN}ssh -p 2888 root@localhost${RESET}

		您可以使用本镜像在宿主机为Android系统的设备上运行alpine_x64并使用docker
		您可以直接使用vnc客户端连接，访问地址为localhost:5905
		默认root密码为空。
		请在登录完成后，输入${GREEN}passwd${RESET}修改root密码。
		如果您想要使用ssh连接，那么请新建一个termux会话窗口，并输入${GREEN}apt update ;apt install -y openssh${RESET}
		您也可以直接在linux容器里使用ssh客户端，输入${TMOE_INSTALLATION_COMMAND} openssh-client
		在安装完ssh客户端后，使用${GREEN}ssh -p 2888 root@localhost${RESET}连接
		Download size(下载大小)约244MiB，解压后约为1GiB
	EOF
    do_you_want_to_continue
    QEMU_NAME='alpine_x64-tmoe_202011'
    QEMU_DISK_FILE_NAME="${QEMU_NAME}.qcow2"
    DOWNLOAD_FILE_NAME="${QEMU_NAME}.qcow2.tar.xz"
    DOWNLOAD_PATH="${HOME}/sd/Download/qemu"
    TMOE_FILE_ABSOLUTE_PATH="${DOWNLOAD_PATH}/${QEMU_DISK_FILE_NAME}"
    mkdir -pv ${DOWNLOAD_PATH}
    cd ${DOWNLOAD_PATH}
    printf '%s\n' 'Download size(下载大小)约213.1MiB，解压后约为1.1GiB'
    THE_LATEST_ISO_LINK="https://redirect.tmoe.me/down/share/Tmoe-linux/qemu/202011/${DOWNLOAD_FILE_NAME}?download=1"
    note_of_empty_root_password
    do_you_want_to_continue
    check_arch_linux_qemu_qcow2_file
    #printf "%s\n" "默认VNC访问地址为localhost:5905"
}
#############
choose_qcow2_or_iso
##############
