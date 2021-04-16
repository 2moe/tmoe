#!/usr/bin/env bash
########################################################################
main() {
    tmoe_aria2_env
    check_dependencies
    check_current_user_name_and_group
    case "$1" in
    up* | -u*)
        upgrade_tmoe_aria2_tool
        ;;
    bt | -bt)
        update_aria2_bt_tracker
        ;;
    h | -h | --help)
        cat <<-'EOF'
			-u       --更新aria2工具(update aria2 tool)
            bt       --更新BT-tracker服务器
		EOF
        ;;
    *)
        tmoe_aria2_manager
        ;;
    esac
}
################
tmoe_aria2_env() {
    TMOE_ARIA2_PATH='/usr/local/etc/tmoe-linux/aria2'
    TMOE_ARIA2_FILE="${TMOE_ARIA2_PATH}/aria2.conf"
}
##########
check_current_user_name_and_group() {
    CURRENT_USER_NAME=$(grep "${HOME}" /etc/passwd | awk -F ':' '{print $1}' | head -n 1)
    CURRENT_USER_GROUP=$(grep "${HOME}" /etc/passwd | awk -F ':' '{print $4}' | cut -d ',' -f 1 | head -n 1)
    if [ -z "${CURRENT_USER_GROUP}" ]; then
        CURRENT_USER_GROUP=${CURRENT_USER_NAME}
    fi
}
##########
check_dependencies() {
    RED=$(printf '\033[31m')
    PURPLE=$(printf '\033[0;35m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[m')
    if [ ! $(command -v aria2c) ]; then
        printf '%s\n' '请先安装aria2'
    fi

    if [ ! $(command -v whiptail) ]; then
        printf '%s\n' '请安装whiptail'
    fi
}
################
##########################
do_you_want_to_continue() {
    printf "%s\n" "${YELLOW}Do you want to ${BLUE}continue?${PURPLE}[Y/n]${RESET}"
    printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET},type ${YELLOW}n${RESET} to ${BLUE}return.${RESET}"
    printf "%s\n" "按${GREEN}回车键${RESET}${BLUE}继续${RESET}，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
    read opt
    case $opt in
    y* | Y* | "") ;;

    n* | N*)
        printf "%s\n" "skipped."
        ${RETURN_TO_WHERE}
        ;;
    *)
        printf "%s\n" "Invalid choice. skipped."
        ${RETURN_TO_WHERE}
        #beta_features
        ;;
    esac
}
##################
press_enter_to_return() {
    printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
    printf "%s\n" "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
    read
}
################
upgrade_tmoe_aria2_tool() {
    cd /usr/local/bin
    curl -Lv -o aria2-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tools/downloader/aria2.sh'
    printf "%s\n" "Update ${YELLOW}completed${RESET}, Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
    printf "%s\n" "${YELLOW}更新完成，按回车键返回。${RESET}"
    chmod +x aria2-i
    read
    #bash /usr/local/bin/aria2-i
    source /usr/local/bin/aria2-i
}
################
check_file_selection_items() {
    if [[ -d "${SELECTION}" ]]; then # 目录是否已被选择
        tmoe_file "$1" "${SELECTION}"
    elif [[ -f "${SELECTION}" ]]; then # 文件已被选择？
        if [[ ${SELECTION} == *${FILE_EXT_01} ]] || [[ ${SELECTION} == *${FILE_EXT_02} ]]; then
            # 检查文件扩展名
            if (whiptail --title "Confirm Selection" --yes-button "Confirm确认" --no-button "Back返回" --yesno "目录: $CURRENT_DIR\n文件: ${SELECTION}" 10 55 4); then
                FILE_NAME="${SELECTION}"
                FILE_PATH="${CURRENT_DIR}"
                #将文件路径作为已经选择的变量
            else
                tmoe_file "$1" "$CURRENT_DIR"
            fi
        else
            whiptail --title "WARNING: File Must have ${FILE_EXT_01} or ${FILE_EXT_02} Extension" \
                --msgbox "${SELECTION}\n您必须选择${FILE_EXT_01}或${FILE_EXT_02}格式的文件。You Must Select a ${FILE_EXT_01} or ${FILE_EXT_02} file" 0 0
            tmoe_file "$1" "$CURRENT_DIR"
        fi
    else
        whiptail --title "WARNING: Selection Error" \
            --msgbox "无法选择该文件或文件夹，请返回。Error Changing to Path ${SELECTION}" 0 0
        tmoe_file "$1" "$CURRENT_DIR"
    fi
}
#####################
tmoe_file() {
    if [ -z $2 ]; then
        DIR_LIST=$(ls -lAhp | awk -F ' ' ' { print $9 " " $5 } ')
    else
        cd "$2"
        DIR_LIST=$(ls -lAhp | awk -F ' ' ' { print $9 " " $5 } ')
    fi
    ###########################
    CURRENT_DIR=$(pwd)
    # 检测是否为根目录
    if [ "$CURRENT_DIR" == "/" ]; then
        SELECTION=$(whiptail --title "$1" \
            --menu "${MENU_01}\n$CURRENT_DIR" 0 0 0 \
            --title "$TMOE_TITLE" \
            --cancel-button Cancel取消 \
            --ok-button Select选择 $DIR_LIST 3>&1 1>&2 2>&3)
    else
        SELECTION=$(whiptail --title "$1" \
            --menu "${MENU_01}\n$CURRENT_DIR" 0 0 0 \
            --title "$TMOE_TITLE" \
            --cancel-button Cancel取消 \
            --ok-button Select选择 ../ 返回 $DIR_LIST 3>&1 1>&2 2>&3)
    fi
    ########################
    EXIT_STATUS=$?
    if [ ${EXIT_STATUS} = 1 ]; then # 用户是否取消操作？
        return 1
    elif [ ${EXIT_STATUS} = 0 ]; then
        check_file_selection_items
    fi
    ############
}
################
tmoe_file_manager() {
    TMOE_TITLE="${FILE_EXT_01} & ${FILE_EXT_02} 文件选择Tmoe-linux管理器"
    if [ -z ${IMPORTANT_TIPS} ]; then
        MENU_01="请使用方向键和回车键进行操作"
    else
        MENU_01=${IMPORTANT_TIPS}
    fi
    ###############
    tmoe_file "$TMOE_TITLE" "$START_DIR"

    EXIT_STATUS=$?
    if [ ${EXIT_STATUS} -eq 0 ]; then
        if [ "${SELECTION}" == "" ]; then
            printf "%s\n" "检测到您取消了操作,User Pressed Esc with No File Selection"
        else
            whiptail --msgbox "文件属性 :  $(ls -lh ${FILE_NAME})\n路径 : ${FILE_PATH}" 0 0
            TMOE_FILE_ABSOLUTE_PATH="${CURRENT_DIR}/${SELECTION}"
            #uncompress_tar_file
        fi
    else
        printf "%s\n" "检测到您${RED}取消了${RESET}${YELLOW}操作${RESET}，没有文件${BLUE}被选择${RESET},with No File ${BLUE}Selected.${RESET}"
        #press_enter_to_return
    fi
}
###########
where_is_start_dir() {
    if [ -d "${HOME}/sd" ]; then
        START_DIR="${HOME}/sd/Download"
    elif [ -d "/sdcard" ]; then
        START_DIR='/sdcard/'
    else
        START_DIR="$(pwd)"
    fi
    tmoe_file_manager
}
###################################
tmoe_aria2_manager() {
    pgrep aria2 &>/dev/null
    if [ "$?" = "0" ]; then
        TMOE_ARIA2_STATUS='检测到aria2进程正在运行'
        TMOE_ARIA2_PROCESS='Restart重启'
    else
        TMOE_ARIA2_STATUS='检测到aria2进程未运行'
        TMOE_ARIA2_PROCESS='Start启动'
    fi
    if [ "${CURRENT_USER_NAME}" = 'root' ]; then
        TMOE_ARIA2_WARNING="检测到您以root权限运行,这可能会破坏您的系统"
    else
        if ! grep -q "${CURRENT_USER_NAME}" /etc/systemd/system/aria2.service; then
            TMOE_ARIA2_WARNING="请重新配置aria2,以使用${CURRENT_USER_NAME}身份运行aria2"
        else
            TMOE_ARIA2_WARNING="您将以${CURRENT_USER_NAME}身份运行aria2"
        fi
    fi
    if [ ! -e "${TMOE_ARIA2_FILE}" ]; then
        mkdir -pv ${TMOE_ARIA2_PATH}
    fi
    if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${TMOE_ARIA2_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？\n${TMOE_ARIA2_STATUS}\n${TMOE_ARIA2_WARNING}" 0 50); then
        if [ ! -e "${TMOE_ARIA2_FILE}" ]; then
            printf "%s\n" "检测到配置文件不存在，1s后将为您自动配置服务。"
            sleep 1s
            tmoe_aria2_onekey
        fi
        aria2_restart
    else
        configure_aria2_rpc_server
    fi
}
#############
case_tmoe_aria2_settings_model() {
    case "${TMOE_ARIA2_SETTINGS_MODEL}" in
    01) tmoe_aria2_settings_model_01 ;;
    02) tmoe_aria2_settings_model_02 ;;
    03) tmoe_aria2_settings_model_03 ;;
    esac
}
#############
tmoe_aria2_file() {
    TMOE_ARIA2_OPTION_01=true
    TMOE_ARIA2_OPTION_02=false
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_file'
    TMOE_OPTION=$(whiptail --title "File allocation" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "dir 文件的下载目录(可使用绝对路径或相对路径)" \
        "02" "disk-cache 磁盘缓存大小" \
        "03" "file-allocation 文件预分配方式,降低磁盘碎片" \
        "04" "allow-overwrite 允许覆盖" \
        "05" "allow-piece-length-change 允许分片大小变化" \
        "06" "auto-file-renaming 文件自动重命名" \
        "07" "conditional-get 条件下载" \
        "08" "content-disposition-default-utf8 使用UTF-8处理disposition内容" \
        "09" "rlimit-nofile 最多打开的文件描述符" \
        "10" "enable-mmap 启用 MMap" \
        "11" "save-not-found 保存未找到的文件" \
        "12" "hash-check-only 文件校验——仅检查哈希值" \
        "13" "keep-unfinished-download-result 保留未完成的任务" \
        "14" "max-download-result 最多下载结果" \
        "15" "max-mmap-limit MMap 最大限制" \
        "16" "piece-length 文件分片大小" \
        "17" "no-file-allocation-limit 文件分配限制" \
        "18" "no-conf 禁用配置文件" \
        "19" "parameterized-uri 启用参数化 URI 支持" \
        "20" "realtime-chunk-checksum 实时数据块验证" \
        "21" "remove-control-file 删除控制文件" \
        "22" "socket-recv-buffer-size Socket 接收缓冲区大小" \
        "23" "check-integrity 检查完整性" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_GREP_NAME='dir'
        TMOE_ARIA2_TIPS='默认: 当前启动位置'
        TMOE_ARIA2_OPTION_01="${HOME}/Downloads"
        TMOE_ARIA2_OPTION_02="${HOME}/sd/Download"
        ;;
    02)
        TMOE_ARIA2_GREP_NAME='disk-cache'
        TMOE_ARIA2_TIPS='启用磁盘缓存, 0为禁用缓存, 需1.16以上版本, 默认:16M\n此功能将下载的数据缓存在内存中, 最多占用此选项设置的字节数. 缓存存储由 aria2 实例创建并对所有下载共享. 由于数据以较大的单位写入并按文件的偏移重新排序, 所以磁盘缓存的一个优点是减少磁盘的 I/O. 如果调用哈希检查时并且数据缓存在内存中时, 将不需要从磁盘中读取. 大小可以包含 K 或 M (1K = 1024, 1M = 1024K).'
        TMOE_ARIA2_OPTION_01="32M"
        TMOE_ARIA2_OPTION_02="16M"
        ;;
    03)
        TMOE_ARIA2_GREP_NAME='file-allocation'
        TMOE_ARIA2_TIPS='默认:prealloc,预分配所需时间: none < falloc ? trunc < prealloc\nfalloc和trunc则需要文件系统和内核支持\n"none" 不会预先分配文件空间;"prealloc"会在下载开始前预先分配空间, 这将会根据文件的大小需要一定的时间。 如果您使用的是较新的文件系统, 例如 ext4 (带扩展支持)、 btrfs、 xfs 或 NTFS (仅 MinGW 构建), "falloc" 是最好的选择。其几乎可以瞬间分配大文件(数 GiB)。\n不要在旧的文件系统, 例如 ext3 和 FAT32 上使用 falloc, 因为该方式与 prealloc 花费的时间相同, 并且它还会在分配完成前阻塞 aria2。\n当您的系统不支持 posix_fallocate(3) 函数时, falloc 可能无法使用。 "trunc" 使用 ftruncate(2)  系统调用或平台特定的实现将文件截取到特定的长度。在多文件的 BitTorrent 下载中, 若某文件与其相邻的文件共享相同的分片时。 则相邻的文件也会被分配.\nwindows(非管理员运行)请勿将选项值改为falloc'
        TMOE_ARIA2_OPTION_01='none'
        TMOE_ARIA2_OPTION_02='falloc'
        TMOE_ARIA2_OPTION_03='trunc'
        TMOE_ARIA2_OPTION_04='prealloc'
        TMOE_ARIA2_SETTINGS_MODEL='02'
        ;;
    04)
        TMOE_ARIA2_GREP_NAME='allow-overwrite'
        TMOE_ARIA2_TIPS='如果相应的控制文件不存在时从头重新下载文件. 参见 --auto-file-renaming 选项.'
        ;;
    05)
        TMOE_ARIA2_GREP_NAME='allow-piece-length-change'
        TMOE_ARIA2_TIPS='如果设置为"false", 当分片长度与控制文件中的不同时, aria2 将会中止下载. 如果设置为"true", 您可以继续, 但部分下载进度将会丢失.'
        ;;
    06)
        TMOE_ARIA2_GREP_NAME='auto-file-renaming'
        TMOE_ARIA2_TIPS='重新命名已经存在的文件. 此选项仅对 HTTP(S)/FTP 下载有效. 新的文件名后会在文件名后、扩展名 (如果有) 前追加句点和数字(1..9999).'
        ;;
    07)
        TMOE_ARIA2_GREP_NAME='conditional-get'
        TMOE_ARIA2_TIPS='仅当本地文件比远程文件旧时才进行下载. 此功能仅适用于 HTTP(S) 下载. 如果在 Metalink 中文件大小已经被指定则功能无法生效. 同时此功能还将忽略 Content-Disposition 响应头. 如果存在控制文件, 此选项将被忽略. 此功能通过 If-Modified-Since 请求头获取较新的文件. 当获取到本地文件的修改时间时, 此功能将使用用户提供的文件名 (参见 --out 选项), 如果没有指定 --out 选项则使用 URI 中的文件名. 为了覆盖已经存在的文件, 需要使用 --allow-overwrite 参数.'
        ;;
    08)
        TMOE_ARIA2_GREP_NAME='content-disposition-default-utf8'
        TMOE_ARIA2_TIPS='处理 "Content-Disposition" 头中的字符串时使用 UTF-8 字符集来代替 ISO-8859-1, 例如, 文件名参数, 但不是扩展版本的文件名.'
        ;;
    09)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="99"
        TMOE_ARIA2_GREP_NAME='rlimit-nofile'
        TMOE_ARIA2_TIPS='设置打开的文件描述符的软限制 (soft limit). 此选项仅当满足如下条件时开放: a. 系统支持它 (posix). b. 限制没有超过硬限制 (hard limit). c. 指定的限制比当前的软限制高. 这相当于设置 ulimit, 除了其不能降低限制. 此选项仅当系统支持 rlimit API 时有效.'
        ;;
    10)
        TMOE_ARIA2_GREP_NAME='enable-mmap'
        TMOE_ARIA2_TIPS='内存中存放映射文件. 当文件空间没有预先分配时, 此选项无效. 参见 --file-allocation.'
        ;;
    11)
        TMOE_ARIA2_GREP_NAME='save-not-found'
        TMOE_ARIA2_TIPS='当使用 --save-session 选项时, 即使当任务中的文件不存在时也保存该下载任务. 此选项同时会将这种情况保存到控制文件中.'
        ;;
    12)
        TMOE_ARIA2_GREP_NAME='hash-check-only'
        TMOE_ARIA2_TIPS='如果设置为"true", 哈希检查完使用 --check-integrity 选项, 根据是否下载完成决定是否终止下载.'
        ;;
    13)
        TMOE_ARIA2_GREP_NAME='keep-unfinished-download-result'
        TMOE_ARIA2_TIPS='即使超过了 --max-download-result 选项设置的数量，仍保留所有未完成的下载结果,. 这将有助于在会话文件中保存所有的未完成的下载 (参考 --save-session 选项). 需要注意的是, 未完成任务的数量没有上限. 如果不希望这样, 请关闭此选项.'
        ;;
    14)
        TMOE_ARIA2_OPTION_01="1000"
        TMOE_ARIA2_OPTION_02="1"
        TMOE_ARIA2_GREP_NAME='max-download-result'
        TMOE_ARIA2_TIPS='设置内存中存储最多的下载结果数量. 下载结果包括已完成/错误/已删除的下载. 下载结果存储在一个先进先出的队列中, 因此其可以存储最多指定的下载结果的数量. 当队列已满且有新的下载结果创建时, 最早的下载结果将从队列的最前部移除, 新的将放在最后. 此选项设置较大的值后如果经过几千次的下载将导致较高的内存消耗. 设置为 0 表示不存储下载结果. 注意, 未完成的下载将始终保存在内存中, 不考虑该选项的设置. 参考 --keep-unfinished-download-result 选项.'
        ;;
    15)
        TMOE_ARIA2_OPTION_01="9223372036854775807"
        TMOE_ARIA2_OPTION_02="99999999999999"
        TMOE_ARIA2_GREP_NAME='max-mmap-limit'
        TMOE_ARIA2_TIPS='设置启用 MMap (参见 --enable-mmap 选项) 最大的文件大小. 文件大小由一个下载任务中所有文件大小的和决定. 例如, 如果一个下载包含 5 个文件, 那么文件大小就是这些文件的总大小. 如果文件大小超过此选项设置的大小时, MMap 将会禁用.'
        ;;
    16)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="10M"
        TMOE_ARIA2_GREP_NAME='piece-length'
        TMOE_ARIA2_TIPS='设置 HTTP/FTP 下载的分配大小. aria2 根据这个边界分割文件. 所有的分割都是这个长度的倍数. 此选项不适用于 BitTorrent 下载. 如果 Metalink 文件中包含分片哈希的结果此选项也不适用.'
        ;;
    17)
        TMOE_ARIA2_OPTION_01="5M"
        TMOE_ARIA2_OPTION_02="10M"
        TMOE_ARIA2_GREP_NAME='no-file-allocation-limit'
        TMOE_ARIA2_TIPS='不分配尺寸小于该参数值的文件. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    18)
        TMOE_ARIA2_GREP_NAME='no-conf'
        TMOE_ARIA2_TIPS='默认为false'
        ;;
    19)
        TMOE_ARIA2_GREP_NAME='parameterized-uri'
        TMOE_ARIA2_TIPS='启用参数化 URI 支持. 您可以指定部分的集合: http://{sv1,sv2,sv3}/foo.iso. 同时您也可以使用步进计数器指定数字化的序列: http://host/image[000-100:2].img. 步进计数器可以省略. 如果所有 URI 地址不指向同样的文件, 例如上述第二个示例, 需要使用 -Z 选项.'
        ;;
    20)
        TMOE_ARIA2_GREP_NAME='realtime-chunk-checksum'
        TMOE_ARIA2_TIPS='如果提供了数据块的校验和, 将在下载过程中通过校验和验证数据块.'
        ;;
    21)
        TMOE_ARIA2_GREP_NAME='remove-control-file'
        TMOE_ARIA2_TIPS='在下载前删除控制文件. 使用 --allow-overwrite=true 选项时, 总是从头开始下载文件. 此选项将有助于使用不支持断点续传代理服务器的用户.'
        ;;
    22)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="99999"
        TMOE_ARIA2_GREP_NAME='socket-recv-buffer-size'
        TMOE_ARIA2_TIPS='设置 Socket 接收缓冲区最大的字节数. 指定为 0 时将禁用此选项. 当使用 SO_RCVBUF 选项调用 setsockopt() 时此选项的值将设置到 Socket 的文件描述符中.'
        ;;
    23)
        TMOE_ARIA2_GREP_NAME='check-integrity'
        TMOE_ARIA2_TIPS='通过对文件的每个分块或整个文件进行哈希验证来检查文件的完整性. 此选项仅对BT、Metalink及设置了 --checksum 选项的 HTTP(S)/FTP 链接生效.'
        ;;
    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    tmoe_aria2_file
}
############
tmoe_aria2_connection_threads() {
    TMOE_ARIA2_OPTION_01=true
    TMOE_ARIA2_OPTION_02=false
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_connection_threads'
    TMOE_OPTION=$(whiptail --title "网络连接" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "max-concurrent-downloads 最大同时下载任务数" \
        "02" "min-split-size  最小文件分片大小" \
        "03" "max-connection-per-server 同一服务器连接数" \
        "04" "split 单个任务最大连接数" \
        "05" "max-overall-download-limit 整体(全局)下载速度限制" \
        "06" "max-download-limit  单个任务下载速度限制, 默认:0" \
        "07" "max-overall-upload-limit  整体(全局)上传速度限制" \
        "08" "max-upload-limit  单个任务上传速度限制, 默认:0" \
        "09" "disable-ipv6  禁用IPv6" \
        "10" "timeout  连接超时时间" \
        "11" "max-tries  最大尝试（重试）次数" \
        "12" "retry-wait  设置重试等待的秒数, 默认:0" \
        "13" "max-resume-failure-tries 最大断点续传尝试次数" \
        "14" "continue  断点续传:继续下载部分完成的文件" \
        "15" "always-resume 始终断点续传" \
        "16" "async-dns 异步 DNS" \
        "17" "dscp 差分服务代码点" \
        "18" "optimize-concurrent-downloads 优化并发下载" \
        "19" "input-file 从会话文件中读取下载任务" \
        "20" "save-session 状态保存文件" \
        "21" "save-session-interval  保存状态间隔(定时保存会话)" \
        "22" "auto-save-interval 自动保存间隔" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_OPTION_01="10"
        TMOE_ARIA2_OPTION_02="5"
        TMOE_ARIA2_GREP_NAME='max-concurrent-downloads'
        TMOE_ARIA2_TIPS='运行时可修改, 默认:5'
        ;;
    02)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="20M"
        TMOE_ARIA2_GREP_NAME='min-split-size'
        TMOE_ARIA2_TIPS=' 添加时可指定, 取值范围1M -1024M, 默认:20M。\n简易说明：假定size=10M, 文件为20MiB 则使用两个来源下载; 文件为15MiB 则使用一个来源下载。\n完整说明：aria2 不会分割小于 2*SIZE 字节的文件。例如, 文件大小为 20MiB, 如果 SIZE 为 10M, aria2 会把文件分成 2 段 [0-10MiB) 和 [10MiB-20MiB) , 并且使用 2 个源进行下载 (如果 --split >= 2)。如果 SIZE 为 15M, 由于 2*15M > 20MB, 因此 aria2 不会分割文件并使用 1 个源进行下载。 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K)。'
        ;;
    03)
        TMOE_ARIA2_OPTION_01="16"
        TMOE_ARIA2_OPTION_02="1"
        TMOE_ARIA2_GREP_NAME='max-connection-per-server'
        TMOE_ARIA2_TIPS='添加时可指定, 默认:1。\n原版可取最大值为16，自行编译的版本可以解除此限制.若出现兼容性问题，请调整该参数的值。'
        ;;
    04)
        TMOE_ARIA2_OPTION_01="16"
        TMOE_ARIA2_OPTION_02="5"
        TMOE_ARIA2_GREP_NAME='split'
        TMOE_ARIA2_TIPS='默认:5,下载时使用 N 个连接。如果提供超过 N 个 URI 地址, 则使用前 N 个地址, 剩余的地址将作为备用。 如果提供的 URI 地址不足 N 个, 这些地址多次使用以保证同时建立 N 个连接。 同一服务器的连接数会被 --max-connection-per-server 选项限制。'
        ;;
    05)
        TMOE_ARIA2_OPTION_01="2M"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-overall-download-limit'
        TMOE_ARIA2_TIPS='运行时可修改, 默认:0\n设置全局最大下载速度 (字节/秒). 0 表示不限制. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    06)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-download-limit'
        TMOE_ARIA2_TIPS='设置每个任务的最大下载速度 (字节/秒). 0 表示不限制. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    07)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-overall-upload-limit'
        TMOE_ARIA2_TIPS='运行时可修改, 默认:0\n设置全局最大上传速度 (字节/秒). 0 表示不限制. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    08)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-upload-limit'
        TMOE_ARIA2_TIPS='设置每个任务的最大上传速度 (字节/秒). 0 表示不限制. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    09)
        TMOE_ARIA2_GREP_NAME='disable-ipv6'
        TMOE_ARIA2_TIPS='默认:false'
        ;;
    10)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='timeout'
        TMOE_ARIA2_TIPS='默认:60。'
        ;;
    11)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="5"
        TMOE_ARIA2_GREP_NAME='max-tries'
        TMOE_ARIA2_TIPS='设置为0表示不限制重试次数, 默认:5'
        ;;
    12)
        TMOE_ARIA2_OPTION_01="1"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='retry-wait'
        TMOE_ARIA2_TIPS=' 当此选项的值大于 0 时, aria2 在 HTTP 服务器返回 503 响应时将会重试.'
        ;;
    13)
        TMOE_ARIA2_OPTION_01="1"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-resume-failure-tries'
        TMOE_ARIA2_TIPS='当 --always-resume 选项设置为"false"时, 如果 aria2 检测到有 N 个 URI 不支持断点续传时, 将从头开始下载文件. 如果 N 设置为 0, 当所有 URI 都不支持断点续传时才会从头下载文件. 参见 --always-resume 选项.'
        ;;
    14)
        TMOE_ARIA2_GREP_NAME='continue'
        TMOE_ARIA2_TIPS='启用此选项可以继续下载从浏览器或其他程序按顺序下载的文件. 此选项目前只支持 HTTP(S)/FTP 下载的文件。'
        ;;
    15)
        TMOE_ARIA2_GREP_NAME='always-resume'
        TMOE_ARIA2_TIPS='始终断点续传. 如果设置为"true", aria2 始终尝试断点续传, 如果无法恢复, 则中止下载. 如果设置为"false", 对于不支持断点续传的 URI 或 aria2 遇到 N 个不支持断点续传的 URI (N 为 --max-resume-failure-tries 选项设置的值), aria2 会从头下载文件. 参见 --max-resume-failure-tries 参数.'
        ;;
    16)
        TMOE_ARIA2_GREP_NAME='async-dns'
        TMOE_ARIA2_TIPS='默认为true'
        ;;
    17)
        TMOE_ARIA2_OPTION_01="63"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='dscp'
        TMOE_ARIA2_TIPS='为 QoS 设置 BT 上行 IP 包的 DSCP 值. 此参数仅设置 IP 包中 TOS 字段的 DSCP 位, 而不是整个字段. 如果您从 /usr/include/netinet/ip.h 得到的值, 需要除以 4 (否则值将不正确, 例如您的 CS1 类将会转为 CS4). 如果您从 RFC, 网络供应商的文档, 维基百科或其他来源采取常用的值, 可以直接使用.'
        ;;
    18)
        TMOE_ARIA2_GREP_NAME='optimize-concurrent-downloads'
        TMOE_ARIA2_TIPS='默认为false,根据可用带宽优化并发下载的数量. aria2 使用之前统计的下载速度通过规则 N = A + B Log10 (速度单位为 Mbps) 得到并发下载的数量. 其中系数 A 和 B 可以在参数中以冒号分隔自定义. 默认值 (A=5, B=25) 可以在 1Mbps 网络上使用通常 5 个并发下载, 在 100Mbps 网络上为 50 个. 并发下载的数量保持在 --max-concurrent-downloads 参数定义的最大之下.'
        ;;
    19)
        FILE_EXT_01='session'
        FILE_EXT_02='Session'
        START_DIR="${TMOE_ARIA2_PATH}"
        IMPORTANT_TIPS='您可以选择aria2.session会话文件'
        TMOE_ARIA2_SETTINGS_MODEL='03'
        TMOE_ARIA2_OPTION_01="${HOME}/.aria2/aria2.session"
        TMOE_ARIA2_OPTION_02="./aria2.session"
        TMOE_ARIA2_GREP_NAME='input-file'
        TMOE_ARIA2_TIPS='默认为./aria2.session'
        ;;
    20)
        TMOE_ARIA2_GREP_NAME='save-session'
        TMOE_ARIA2_TIPS=' 在Aria2退出时保存"错误/未完成"的下载任务到会话文件.\n当退出时保存错误及未完成的任务到指定的文件中. 您可以在重启 aria2 时使用 --input-file 选项重新加载. 如果您希望输出的内容使用 GZip 压缩, 您可以在文件名后增加 .gz 扩展名. 请注意, 通过 aria2.addTorrent() 和 aria2.addMetalink() RPC 方法添加的下载, 其元数据没有保存到文件的将不会保存. 通过 aria2.remove() 和 aria2.forceRemove() 删除的下载将不会保存.'
        ;;
    21)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='save-session-interval'
        TMOE_ARIA2_TIPS=' 需1.16.1以上版本, 默认:0,每隔此选项设置的时间(秒)后会保存错误或未完成的任务到 --save-session 选项指定的文件中. 如果设置为 0, 仅当 aria2 退出时才会保存.'
        ;;
    22)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='auto-save-interval'
        TMOE_ARIA2_TIPS='每隔设置的秒数自动保存控制文件(*.aria2). 如果设置为 0, 下载期间控制文件不会自动保存. 不论设置的值为多少, aria2 会在任务结束时保存控制文件. 可以设置的值为 0 到 600.'
        ;;
    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    tmoe_aria2_connection_threads
}
######################
tmoe_aria2_hook() {
    TMOE_ARIA2_OPTION_01="${TMOE_ARIA2_PATH}/auto_upload_onedrive.sh"
    TMOE_ARIA2_OPTION_02="${TMOE_ARIA2_PATH}/auto_move_media_files.sh"
    FILE_EXT_01='sh'
    FILE_EXT_02='py'
    START_DIR="${TMOE_ARIA2_PATH}"
    IMPORTANT_TIPS='您可以选择脚本文件'
    TMOE_ARIA2_SETTINGS_MODEL='03'
    RETURN_TO_WHERE='tmoe_aria2_hook'
    TMOE_OPTION=$(whiptail --title "钩子" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "on-download-complete:(全局)下载完成后执行的操作" \
        "02" "on-bt-download-complete:BT下载完成" \
        "03" "on-download-error:下载错误" \
        "04" "on-download-pause:下载暂停" \
        "05" "on-download-start:下载开始" \
        "06" "on-download-stop:下载停止" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_GREP_NAME='on-download-complete'
        TMOE_ARIA2_TIPS='您可以在下载完成后，执行特定脚本来实现高级功能。\n例如：配合第三方网盘的插件实现下载完成后自动上传的功能，或对下载完成后的文件进行自动分类。'
        ;;
    02)
        TMOE_ARIA2_GREP_NAME='on-bt-download-complete'
        TMOE_ARIA2_TIPS='如有做种将包含做种，如需调用请务必确定设定完成做种条件'
        ;;
    03)
        TMOE_ARIA2_GREP_NAME='on-download-error'
        TMOE_ARIA2_TIPS='下载错误时执行的脚本'
        ;;
    04)
        TMOE_ARIA2_GREP_NAME='on-download-pause'
        TMOE_ARIA2_TIPS='下载暂停时执行的脚本'
        ;;
    05)
        TMOE_ARIA2_GREP_NAME='on-download-start'
        TMOE_ARIA2_TIPS='下载开始时执行的脚本'
        ;;
    06)
        TMOE_ARIA2_GREP_NAME='on-download-stop'
        TMOE_ARIA2_TIPS='下载停止时执行的脚本'
        ;;
    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
##################
tmoe_aria2_port() {
    TMOE_ARIA2_OPTION_01=true
    TMOE_ARIA2_OPTION_02=false
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_port'
    TMOE_OPTION=$(whiptail --title "端口" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "RPC监听端口" \
        "02" "BT监听端口" \
        "03" "DHT网络监听端口" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_OPTION_01="2086"
        TMOE_ARIA2_OPTION_02="6800"
        TMOE_ARIA2_OPTION_03="8443"
        TMOE_ARIA2_OPTION_04="2096"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='rpc-listen-port'
        TMOE_ARIA2_TIPS='RPC监听端口, 端口被占用时可以修改, 默认:6800\n若您需要套Cloudflare CDN,则需要选用CF支持的端口'
        ;;
    02)
        TMOE_ARIA2_OPTION_01="36881-36999"
        TMOE_ARIA2_OPTION_02="6881-6999"
        TMOE_ARIA2_GREP_NAME='listen-port'
        TMOE_ARIA2_TIPS='BT监听端口, 当端口被屏蔽时使用, 默认:6881-6999'
        ;;
    03)
        TMOE_ARIA2_OPTION_01="56881-56999"
        TMOE_ARIA2_OPTION_02="6881-6999"
        TMOE_ARIA2_GREP_NAME='dht-listen-port'
        TMOE_ARIA2_TIPS='默认:6881-6999\n设置 BT 下载的 TCP 端口. 多个端口可以使用逗号 "," 分隔, 例如: 6881,6885. 您还可以使用短横线 "-" 表示范围: 6881-6999, 或可以一起使用: 6881-6889, 6999'
        ;;
    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
tmoe_aria2_proxy() {
    TMOE_ARIA2_OPTION_01='password'
    TMOE_ARIA2_OPTION_02='123456'
    TMOE_ARIA2_SETTINGS_MODEL='01'
    TMOE_ARIA2_TIPS=' 默认为空'
    RETURN_TO_WHERE='tmoe_aria2_proxy'
    TMOE_OPTION=$(whiptail --title "PROXY" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "all-proxy 所有协议的代理服务器" \
        "02" "all-proxy-user 代理服务器用户名" \
        "03" "all-proxy-passwd 代理服务器密码" \
        "04" "proxy-method 代理服务器请求方法" \
        "05" "no-proxy 不使用代理服务器列表" \
        "06" "https-proxy HTTPS 代理服务器" \
        "07" "https-proxy-user HTTPS 代理服务器用户名" \
        "08" "https-proxy-passwd HTTPS 代理服务器密码" \
        "09" "ftp-proxy FTP 代理服务器" \
        "10" "ftp-proxy-user FTP 代理服务器用户名" \
        "11" "ftp-proxy-passwd FTP 代理服务器密码" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_OPTION_01='http://192.168.1.1:7890'
        TMOE_ARIA2_OPTION_02='http://192.168.0.1:8088'
        TMOE_ARIA2_GREP_NAME='all-proxy'
        TMOE_ARIA2_TIPS='设置所有协议的代理服务器地址. 如果覆盖之前设置的代理服务器, 使用 "" 即可. 您还可以针对特定的协议覆盖此选项, 即使用 --http-proxy, --https-proxy 和 --ftp-proxy 选项. 此设置将会影响所有下载. 代理服务器地址的格式为 [http://][USER:PASSWORD@]HOST[:PORT].'
        ;;
    02)
        TMOE_ARIA2_GREP_NAME='all-proxy-user'
        TMOE_ARIA2_TIPS='设置所有协议的代理服务器用户名'
        ;;
    03)
        TMOE_ARIA2_GREP_NAME='all-proxy-passwd'
        TMOE_ARIA2_TIPS='设置所有协议的代理服务器密码'
        ;;
    04)
        TMOE_ARIA2_OPTION_01="tunnel"
        TMOE_ARIA2_OPTION_02="get"
        TMOE_ARIA2_GREP_NAME='proxy-method'
        TMOE_ARIA2_TIPS='设置用来请求代理服务器的方法. 方法可设置为 GET 或 TUNNEL. HTTPS 下载将忽略此选项并总是使用 TUNNEL.'
        ;;
    05)
        TMOE_ARIA2_OPTION_01='http://192.168.1.1'
        TMOE_ARIA2_OPTION_02='http://192.168.0.1'
        TMOE_ARIA2_GREP_NAME='no-proxy'
        TMOE_ARIA2_TIPS='设置不使用代理服务器的主机名, 域名, 包含或不包含子网掩码的网络地址, 多个使用逗号分隔.'
        ;;
    06)
        TMOE_ARIA2_OPTION_01='https://192.168.1.1:8443'
        TMOE_ARIA2_OPTION_02='https://192.168.0.1:443'
        TMOE_ARIA2_GREP_NAME='https-proxy'
        ;;
    07)
        TMOE_ARIA2_GREP_NAME='https-proxy-user'
        ;;
    08)
        TMOE_ARIA2_GREP_NAME='https-proxy-passwd'
        ;;
    09)
        TMOE_ARIA2_OPTION_01='192.168.1.1:8021'
        TMOE_ARIA2_OPTION_02='192.168.0.1:8821'
        TMOE_ARIA2_GREP_NAME='ftp-proxy'
        ;;
    10)
        TMOE_ARIA2_GREP_NAME='ftp-proxy-user'
        ;;
    11)
        TMOE_ARIA2_GREP_NAME='ftp-proxy-passwd'
        ;;
    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
###############
tmoe_aria2_logs() {
    TMOE_ARIA2_OPTION_01=true
    TMOE_ARIA2_OPTION_02=false
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_logs'
    TMOE_OPTION=$(whiptail --title "日志与输出信息" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "conf-path 配置文件路径" \
        "02" "daemon 后台运行" \
        "03" "log 日志文件" \
        "04" "console-log-level 控制台日志级别" \
        "05" "log-level 日志级别" \
        "06" "enable-color 终端输出使用颜色" \
        "07" "show-console-readout 显示控制台输出" \
        "08" "summary-interval 下载摘要输出间隔" \
        "09" "quiet 禁用控制台输出" \
        "10" "truncate-console-readout 缩短控制台输出内容" \
        "11" "stop 自动关闭时间" \
        "12" "deferred-input 延迟加载" \
        "13" "download-result 下载结果" \
        "14" "human-readable 控制台可读输出" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        FILE_EXT_01='conf'
        FILE_EXT_02='json'
        START_DIR="${TMOE_ARIA2_PATH}"
        IMPORTANT_TIPS='您可以选择aria2.conf配置文件'
        TMOE_ARIA2_SETTINGS_MODEL='03'
        TMOE_ARIA2_OPTION_01="/usr/local/etc/tmoe-linux/aria2/aria2.conf"
        TMOE_ARIA2_OPTION_02="${HOME}/.aria2/aria2.conf"
        TMOE_ARIA2_GREP_NAME='conf-path'
        TMOE_ARIA2_TIPS='默认为${HOME}/.aria2/aria2.conf'
        ;;
    02)
        TMOE_ARIA2_GREP_NAME='daemon'
        TMOE_ARIA2_TIPS='默认为false,建议保持false状态'
        ;;
    03)
        TMOE_ARIA2_OPTION_01='-'
        TMOE_ARIA2_OPTION_02=""
        TMOE_ARIA2_GREP_NAME='log'
        TMOE_ARIA2_TIPS='日志文件的路径. 如果设置为 "-", 日志则写入到 stdout. 如果设置为空字符串(""), 日志将不会记录到磁盘上.'
        ;;
    04)
        TMOE_ARIA2_OPTION_01="debug"
        TMOE_ARIA2_OPTION_02="info"
        TMOE_ARIA2_OPTION_03="notice"
        TMOE_ARIA2_OPTION_04="warn"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='console-log-level'
        TMOE_ARIA2_TIPS='默认为notice'
        ;;
    05)
        TMOE_ARIA2_OPTION_01="debug"
        TMOE_ARIA2_OPTION_02="info"
        TMOE_ARIA2_OPTION_03="notice"
        TMOE_ARIA2_OPTION_04="warn"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='log-level'
        TMOE_ARIA2_TIPS='可选值：debug, info, notice, warn , error. 默认: debug'
        ;;
    06)
        TMOE_ARIA2_GREP_NAME='enable-color'
        TMOE_ARIA2_TIPS='默认为true'
        ;;
    07)
        TMOE_ARIA2_GREP_NAME='show-console-readout'
        TMOE_ARIA2_TIPS='默认为true'
        ;;
    08)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='summary-interval'
        TMOE_ARIA2_TIPS='设置下载进度摘要的输出间隔(秒). 设置为 0 禁止输出.'
        ;;
    09)
        TMOE_ARIA2_GREP_NAME='quiet'
        TMOE_ARIA2_TIPS='默认为false'
        ;;
    10)
        TMOE_ARIA2_GREP_NAME='truncate-console-readout'
        TMOE_ARIA2_TIPS='缩短控制台输出的内容在一行中.'
        ;;
    11)
        TMOE_ARIA2_OPTION_01="60"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='stop'
        TMOE_ARIA2_TIPS='在此选项设置的时间(秒)后关闭应用. 如果设置为 0, 此功能将禁用.'
        ;;
    12)
        TMOE_ARIA2_GREP_NAME='deferred-input'
        TMOE_ARIA2_TIPS='如果设置为"true", aria2 在启动时不会读取 --input-file 选项设置的文件中的所有 URI 地址, 而是会在之后需要时按需读取. 如果输入文件中包含大量要下载的 URI, 此选项可以减少内存的使用. 如果设置为"false", aria2 会在启动时读取所有的 URI. 当 -save-session 使用时将会禁用 --deferred-input 选项.'
        ;;
    13)
        TMOE_ARIA2_OPTION_01="hide"
        TMOE_ARIA2_OPTION_02="default"
        TMOE_ARIA2_GREP_NAME='download-result'
        TMOE_ARIA2_TIPS='此选项将修改下载结果的格式. 如果设置为"default"(默认), 将打印 GID, 状态, 平均下载速度和路径/URI. 如果涉及多个文件, 仅打印第一个请求文件的路径/URI, 其余的将被忽略. 如果设置为"full"(完整), 将打印 GID, 状态, 平均下载速度, 下载进度和路径/URI. 其中, 下载进度和路径/URI 将会每个文件打印一行. 如果设置为"hide"(隐藏), 下载结果将会隐藏.'
        ;;
    14)
        TMOE_ARIA2_GREP_NAME='human-readable'
        TMOE_ARIA2_TIPS='在控制台输出可读格式的大小和速度 (例如, 1.2Ki, 3.4Mi).'
        ;;
    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
################
# cat http.conf| grep '^#2' | sed 's@#2@@' |sed "s@^@TMOE_ARIA2_TIPS='@" |sed "s@\$@\'\;\;@" >002
#paste -d ' ' 001 002 | sed 's@233@\n@g' >003
tmoe_aria2_rpc_server_and_tls() {
    TMOE_ARIA2_OPTION_01=true
    TMOE_ARIA2_OPTION_02=false
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_rpc_server_and_tls'
    TMOE_OPTION=$(whiptail --title "RPC & TLS" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "rpc-secret RPC 令牌密钥（token secret）" \
        "02" "enable-rpc 启用JSON-RPC/XML-RPC 服务器" \
        "03" "rpc-allow-origin-all 允许所有来源(接受所有远程请求)" \
        "04" "rpc-listen-all 在所有网卡上监听" \
        "05" "rpc-secure  启用SSL/TLS 加密" \
        "06" "rpc-certificate  在 RPC 服务中启用 SSL/TLS 加密时的证书文件" \
        "07" "rpc-private-key  在 RPC 服务中启用 SSL/TLS 加密时的私钥文件" \
        "08" "check-certificate  证书校验" \
        "09" "ca-certificate  ca证书路径" \
        "10" "min-tls-version 最低 TLS 版本" \
        "11" "event-poll  事件轮询方式,不同系统默认值不同" \
        "12" "rpc-max-request-size 最大请求大小" \
        "13" "rpc-save-upload-metadata 保存上传的种子文件" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        OPENSSL_RANDOM_KEY=$(openssl rand -base64 33)
        TMOE_ARIA2_OPTION_01="${OPENSSL_RANDOM_KEY}"
        TMOE_ARIA2_OPTION_02="123456"
        TMOE_ARIA2_GREP_NAME='rpc-secret'
        TMOE_ARIA2_TIPS='第一个选项为openssl随机生成的33位字符，v1.18.4新增功能, 取代 --rpc-user 和 --rpc-passwd 选项'
        ;;
    02)
        TMOE_ARIA2_GREP_NAME='enable-rpc'
        TMOE_ARIA2_TIPS='默认:false,web-gui控制需要开启此功能'
        ;;
    03)
        TMOE_ARIA2_GREP_NAME='rpc-allow-origin-all'
        TMOE_ARIA2_TIPS='默认:false,在 RPC 响应头增加 Access-Control-Allow-Origin 字段, 值为 *'
        ;;
    04)
        TMOE_ARIA2_GREP_NAME='rpc-listen-all'
        TMOE_ARIA2_TIPS='在所有网络适配器上监听 JSON-RPC/XML-RPC 的请求, 如果设置为"false", 仅监听本地网络的请求.'
        ;;
    05)
        TMOE_ARIA2_GREP_NAME='rpc-secure'
        TMOE_ARIA2_TIPS='经测试无法使用自签名证书，若启用此选项，则建议您使用Let’s Encrypt等组织签发的有效证书\n启用加密后 ，RPC 将通过 SSL/TLS 加密传输, RPC 服务需要使用 https 或者 wss 协议连接\nRPC 客户端需要使用 https 协议连接服务器. 对于 WebSocket 客户端, 使用 wss 协议. 使用 --rpc-certificate 和 --rpc-private-key 选项设置服务器的证书和私钥.'
        ;;
    06)
        FILE_EXT_01='pem'
        FILE_EXT_02='crt'
        START_DIR="/www/server/"
        IMPORTANT_TIPS='您可以选择TLS证书文件'
        TMOE_ARIA2_SETTINGS_MODEL='03'
        TMOE_ARIA2_OPTION_01="/www/server/ca-certificates.pem"
        TMOE_ARIA2_OPTION_02="./ca-certificates.pem"
        TMOE_ARIA2_GREP_NAME='rpc-certificate'
        TMOE_ARIA2_TIPS=' 使用 PEM 格式时，您必须通过 --rpc-private-key 指定私钥'
        ;;
    07)
        FILE_EXT_01='key'
        FILE_EXT_02='crt'
        START_DIR="/www/server/"
        IMPORTANT_TIPS='您可以选择证书私钥文件'
        TMOE_ARIA2_SETTINGS_MODEL='03'
        TMOE_ARIA2_OPTION_01="/www/server/ca-certificates.key"
        TMOE_ARIA2_OPTION_02="./ca-certificates.key"
        TMOE_ARIA2_GREP_NAME='rpc-private-key'
        TMOE_ARIA2_TIPS=' 默认未加载'
        ;;
    08)
        TMOE_ARIA2_GREP_NAME='check-certificate'
        TMOE_ARIA2_TIPS=' 默认为false'
        ;;
    09)
        FILE_EXT_01='crt'
        FILE_EXT_02='pem'
        START_DIR="/usr/share/ca-certificates/mozilla/"
        IMPORTANT_TIPS='您可以选择ca证书文件'
        TMOE_ARIA2_SETTINGS_MODEL='03'
        TMOE_ARIA2_OPTION_01="/usr/share/ca-certificates/mozilla/SecureTrust_CA.crt"
        TMOE_ARIA2_OPTION_02="./ca-certificates.crt"
        TMOE_ARIA2_GREP_NAME='ca-certificate'
        TMOE_ARIA2_TIPS=' 默认未启用'
        ;;
    10)
        TMOE_ARIA2_OPTION_01="TLSv1.3"
        TMOE_ARIA2_OPTION_02="TLSv1.2"
        TMOE_ARIA2_GREP_NAME='min-tls-version'
        TMOE_ARIA2_TIPS='指定启用的最低 SSL/TLS 版本.'
        ;;
    11)
        TMOE_ARIA2_OPTION_01="epoll"
        TMOE_ARIA2_OPTION_02="select"
        TMOE_ARIA2_OPTION_03="kqueue"
        TMOE_ARIA2_OPTION_04="port"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='event-poll'
        TMOE_ARIA2_TIPS='设置事件轮训的方法. 可选的值包括 epoll, kqueue, port, poll 和 select. 对于 epoll, kqueue, port 和 poll, 只有系统支持时才可用. 最新的 Linux 支持 epoll. 各种 *BSD 系统包括 Mac OS X 支持 kqueue. Open Solaris 支持 port. 默认值根据您使用的操作系统不同而不同.'
        ;;
    12)
        TMOE_ARIA2_OPTION_01="10M"
        TMOE_ARIA2_OPTION_02="2M"
        TMOE_ARIA2_GREP_NAME='rpc-max-request-size'
        TMOE_ARIA2_TIPS='设置 JSON-RPC/XML-RPC 最大的请求大小. 如果 aria2 检测到请求超过设定的字节数, 会直接取消连接.'
        ;;
    13)
        TMOE_ARIA2_GREP_NAME='rpc-save-upload-metadata'
        TMOE_ARIA2_TIPS='在 dir 选项设置的目录中保存上传的种子文件或 Metalink 文件. 文件名包括 SHA-1 哈希后的元数据和扩展名两部分. 对于种子文件, 扩展名为 '.torrent'. 对于 Metalink 为 '.meta4'. 如果此选项设置为"false", 通过 aria2.addTorrent() 或 aria2.addMetalink() 方法添加的下载将无法通过 --save-session 选项保存.'
        ;;
    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
tmoe_aria2_ftp_and_metalink() {
    TMOE_ARIA2_OPTION_01=true
    TMOE_ARIA2_OPTION_02=false
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_ftp_and_metalink'
    TMOE_OPTION=$(whiptail --title "FTP和metalink" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "ftp-user FTP默认用户名" \
        "02" "ftp-passwd FTP默认密码" \
        "03" "ftp-pasv 被动模式" \
        "04" "ftp-type 传输类型" \
        "05" "ftp-reuse-connection 连接复用" \
        "06" "ssh-host-key-md SSH 公钥校验和" \
        "07" "metalink-preferred-protocol 首选使用协议" \
        "08" "metalink-enable-unique-protocol 仅使用唯一协议" \
        "09" "follow-metalink 下载 Metalink 中的文件" \
        "10" "metalink-base-uri 基础 URI" \
        "11" "metalink-language 语言" \
        "12" "metalink-location 首选服务器位置" \
        "13" "metalink-os 操作系统" \
        "14" "metalink-version 版本号" \
        "15" "pause-metadata 种子文件下载完后暂停" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") tmoe_aria2_download_protocol ;;
    01)
        TMOE_ARIA2_OPTION_02="anonymous"
        TMOE_ARIA2_OPTION_01="admin"
        TMOE_ARIA2_GREP_NAME='ftp-user'
        TMOE_ARIA2_TIPS='默认为anonymous'
        ;;
    02)
        TMOE_ARIA2_OPTION_01="123456"
        TMOE_ARIA2_OPTION_02="password"
        TMOE_ARIA2_GREP_NAME='ftp-passwd'
        TMOE_ARIA2_TIPS='如果 URI 中包含用户名单不包含密码, aria2 首先会从 .netrc 文件中获取密码. 如果在 .netrc 文件中找到密码, 则使用该密码. 否则, 使用此选项设置的密码.'
        ;;
    03)
        TMOE_ARIA2_GREP_NAME='ftp-pasv'
        TMOE_ARIA2_TIPS='在 FTP 中使用被动模式. 如果设置为"false", 则使用主动模式. 此选项不适用于 SFTP 传输.'
        ;;
    04)
        TMOE_ARIA2_OPTION_01="ascii"
        TMOE_ARIA2_OPTION_02="binary"
        TMOE_ARIA2_GREP_NAME='ftp-type'
        TMOE_ARIA2_TIPS='默认为binary'
        ;;
    05)
        TMOE_ARIA2_GREP_NAME='ftp-reuse-connection'
        TMOE_ARIA2_TIPS='默认为true'
        ;;
    06)
        TMOE_ARIA2_OPTION_01="md5=7a27be7e19d2bc264707dc128b15faab"
        TMOE_ARIA2_OPTION_02="sha-1=b030503d4de4539dc7885e6f0f5e256704edf4c3"
        TMOE_ARIA2_GREP_NAME='ssh-host-key-md'
        TMOE_ARIA2_TIPS='设置 SSH 主机公钥的校验和. TYPE 为哈希类型. 支持的哈希类型为 sha-1 和 md5. DIGEST 是十六进制摘要. 例如: sha-1=b030503d4de4539dc7885e6f0f5e256704edf4c3. 此选项可以在使用 SFTP 时用来验证服务器的公钥. 如果此选项不设置, 即保留默认, 不会进行任何验证。'
        ;;
    07)
        TMOE_ARIA2_OPTION_01="http"
        TMOE_ARIA2_OPTION_02="https"
        TMOE_ARIA2_OPTION_03="ftp"
        TMOE_ARIA2_OPTION_04="none"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='metalink-preferred-protocol'
        TMOE_ARIA2_TIPS='指定首选使用的协议. 可以设置为 "http", "https", "ftp" 或"none". 设置为"none"时禁用此选项.'
        ;;
    08)
        TMOE_ARIA2_GREP_NAME='metalink-enable-unique-protocol'
        TMOE_ARIA2_TIPS='如果一个 Metalink 文件可用多种协议, 并且此选项设置为"true", aria2 将只会使用其中一种. 使用 --metalink-preferred-protocol 参数指定首选的协议.'
        ;;
    09)
        TMOE_ARIA2_OPTION_03="mem"
        TMOE_ARIA2_OPTION_04=""
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='follow-metalink'
        TMOE_ARIA2_TIPS='如果设置为"true"或"mem"(仅内存), 当后缀为 .meta4 或 .metalink 或内容类型为 application/metalink4+xml 或 application/metalink+xml 的文件下载完成时, aria2 将按 Metalink 文件读取并下载该文件中提到的文件. 如果设置为"mem", 该 Metalink 文件将不会写入到磁盘中, 而仅会存储在内存中. 如果设置为"false", 则 .metalink 文件会下载到磁盘中, 但不会按 Metalink 文件读取并且其中的文件不会进行下载.'
        ;;
    10)
        TMOE_ARIA2_OPTION_01="meta://"
        TMOE_ARIA2_OPTION_02="metalink://"
        TMOE_ARIA2_GREP_NAME='metalink-base-uri'
        TMOE_ARIA2_TIPS='指定基础 URI 以便解析本地磁盘中存储的 Metalink 文件里 metalink:url 和 metalink:metaurl 中的相对 URI 地址. 如果 URI 表示的为目录, 最后需要以 / 结尾.'
        ;;
    11)
        TMOE_ARIA2_OPTION_01="zh"
        TMOE_ARIA2_OPTION_02="en"
        TMOE_ARIA2_GREP_NAME='metalink-language'
        TMOE_ARIA2_TIPS='默认为空'
        ;;
    12)
        TMOE_ARIA2_OPTION_01="jp"
        TMOE_ARIA2_OPTION_02="cn"
        TMOE_ARIA2_GREP_NAME='metalink-location'
        TMOE_ARIA2_TIPS='首选服务器所在的位置. 可以使用逗号分隔的列表, 例如: jp,us.'
        ;;
    13)
        TMOE_ARIA2_OPTION_01="linux"
        TMOE_ARIA2_OPTION_02="windows"
        TMOE_ARIA2_GREP_NAME='metalink-os'
        TMOE_ARIA2_TIPS='下载文件的操作系统.'
        ;;
    14)
        TMOE_ARIA2_OPTION_01="latest"
        TMOE_ARIA2_OPTION_02=""
        TMOE_ARIA2_GREP_NAME='metalink-version'
        TMOE_ARIA2_TIPS='下载文件的版本号.'
        ;;
    15)
        TMOE_ARIA2_GREP_NAME='pause-metadata'
        TMOE_ARIA2_TIPS='当种子文件下载完成后暂停后续的下载. 在 aria2 中有 3 种种子文件的下载类型: (1) 下载 .torrent 文件. (2) 通过磁链下载的种子文件. (3) 下载 Metalink 文件. 这些种子文件下载完后会根据文件内容继续进行下载. 此选项会暂停这些后续的下载. 此选项仅当 --enable-rpc 选项启用时生效.'
        ;;
    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
tmoe_aria2_http() {
    TMOE_ARIA2_OPTION_01=true
    TMOE_ARIA2_OPTION_02=false
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_http'
    TMOE_OPTION=$(whiptail --title "HTTP" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "user-agent 自定义 User Agent" \
        "02" "http-accept-gzip 支持 GZip" \
        "03" "connect-timeout 连接超时时间" \
        "04" "dry-run 模拟运行" \
        "05" "lowest-speed-limit 最小速度限制" \
        "06" "max-file-not-found 文件未找到重试次数" \
        "07" "netrc-path .netrc 文件路径" \
        "08" "no-netrc 禁用 netrc" \
        "09" "out 文件名" \
        "10" "remote-time 获取服务器文件时间" \
        "11" "reuse-uri URI 复用" \
        "12" "server-stat-of 服务器状态保存文件" \
        "13" "server-stat-timeout 服务器状态超时" \
        "14" "stream-piece-selector 分片选择算法" \
        "15" "uri-selector URI 选择算法" \
        "16" "http-auth-challenge 认证质询" \
        "17" "http-no-cache 禁用缓存" \
        "18" "http-user HTTP 默认用户名" \
        "19" "http-passwd HTTP 默认密码" \
        "20" "referer 请求来源" \
        "21" "enable-http-keep-alive 启用持久连接" \
        "22" "enable-http-pipelining 启用 HTTP 管线化" \
        "23" "header 自定义请求头" \
        "24" "save-cookies Cookies 保存路径" \
        "25" "use-head 启用 HEAD 方法" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") tmoe_aria2_download_protocol ;;
    01)
        # TMOE_ARIA2_OPTION_01="netdisk;5.2.7;PC;PC-Windows；6.2.9200;WindowsBaiduYunGuanJia"
        TMOE_ARIA2_OPTION_01='netdisk;6.7.4.2;PC;PC-Windows;10.0.17763;WindowsBaiduYunGuanJia'
        TMOE_ARIA2_OPTION_02='Opera/9.80 (Windows NT 6.0) Presto/2.12.388 Version/12.14'
        TMOE_ARIA2_OPTION_03='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36'
        TMOE_ARIA2_OPTION_04='Mozilla/5.0 (Symbian/3; Series60/5.2 NokiaN8-00/012.002; Profile/MIDP-2.1 Configuration/CLDC-1.1 ) AppleWebKit/533.4 (KHTML, like Gecko) NokiaBrowser/7.3.0 Mobile Safari/533.4 3gpp-gba'
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='user-agent'
        TMOE_ARIA2_TIPS=' User Agent中文名为用户代理，简称 UA，它是一个特殊字符串头，使得服务器能够识别客户使用的操作系统及版本、CPU 类型、浏览器及版本、浏览器渲染引擎、浏览器语言、浏览器插件等'
        ;;
    02)
        TMOE_ARIA2_GREP_NAME='http-accept-gzip'
        TMOE_ARIA2_TIPS='如果远程服务器的响应头中包含 Content-Encoding: gzip 或 Content-Encoding: deflate , 将发送包含 Accept: deflate, gzip 的请求头并解压缩响应.'
        ;;
    03)
        TMOE_ARIA2_OPTION_01='0'
        TMOE_ARIA2_OPTION_02='60'
        TMOE_ARIA2_GREP_NAME='connect-timeout'
        TMOE_ARIA2_TIPS='设置建立 HTTP/FTP/代理服务器 连接的超时时间(秒). 当连接建立后, 此选项不再生效, 请使用 --timeout 选项.'
        ;;
    04)
        TMOE_ARIA2_GREP_NAME='dry-run'
        TMOE_ARIA2_TIPS='如果设置为"true", aria2 将仅检查远程文件是否存在而不会下载文件内容. 此选项仅对 HTTP/FTP 下载生效. 如果设置为 true, BT 下载将会直接取消.'
        ;;
    05)
        TMOE_ARIA2_OPTION_01='1K'
        TMOE_ARIA2_OPTION_02='0'
        TMOE_ARIA2_GREP_NAME='lowest-speed-limit'
        TMOE_ARIA2_TIPS='当下载速度低于此选项设置的值(B/s) 时将会关闭连接. 0 表示不设置最小速度限制. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K). 此选项不会影响 BT 下载.'
        ;;
    06)
        TMOE_ARIA2_OPTION_01='10'
        TMOE_ARIA2_OPTION_02='0'
        TMOE_ARIA2_GREP_NAME='max-file-not-found'
        TMOE_ARIA2_TIPS='如果 aria2 从远程 HTTP/FTP 服务器收到 "文件未找到" 的状态超过此选项设置的次数后下载将会失败. 设置为 0 将会禁用此选项. 此选项仅影响 HTTP/FTP 服务器. 重试时同时会记录重试次数, 所以也需要设置 --max-tries 这个选项.'
        ;;
    07)
        FILE_EXT_01='netrc'
        FILE_EXT_02='rc'
        START_DIR="${TMOE_ARIA2_PATH}"
        IMPORTANT_TIPS='您可以选择.netrc文件'
        TMOE_ARIA2_SETTINGS_MODEL='03'
        TMOE_ARIA2_OPTION_01="${HOME}/.aria2/.netrc"
        TMOE_ARIA2_OPTION_02='./.netrc'
        TMOE_ARIA2_GREP_NAME='netrc-path'
        TMOE_ARIA2_TIPS='.默认为./.netrc'
        ;;
    08)
        TMOE_ARIA2_GREP_NAME='no-netrc'
        TMOE_ARIA2_TIPS='默认为false'
        ;;
    09)
        TMOE_ARIA2_OPTION_01="不建议在配置文件中设定此参数"
        TMOE_ARIA2_OPTION_02=''
        TMOE_ARIA2_GREP_NAME='out'
        TMOE_ARIA2_TIPS='下载文件的文件名. 其总是相对于 --dir 选项中设置的路径. 当使用 --force-sequential 参数时此选项无效.'
        ;;
    10)
        TMOE_ARIA2_GREP_NAME='remote-time'
        TMOE_ARIA2_TIPS='从 HTTP/FTP 服务获取远程文件的时间戳, 如果可用将设置到本地文件'
        ;;
    11)
        TMOE_ARIA2_GREP_NAME='reuse-uri'
        TMOE_ARIA2_TIPS='当所有给定的 URI 地址都已使用, 继续使用已经使用过的 URI 地址.'
        ;;
    12)
        TMOE_ARIA2_OPTION_01=".server_stat"
        TMOE_ARIA2_OPTION_02=''
        TMOE_ARIA2_GREP_NAME='server-stat-of'
        TMOE_ARIA2_TIPS='指定用来保存服务器状态的文件名. 您可以使用 --server-stat-if 参数读取保存的数据.'
        ;;
    13)
        TMOE_ARIA2_OPTION_01="100"
        TMOE_ARIA2_OPTION_02='60'
        TMOE_ARIA2_GREP_NAME='server-stat-timeout'
        TMOE_ARIA2_TIPS='指定服务器状态的过期时间 (单位为秒).'
        ;;
    14)
        TMOE_ARIA2_OPTION_01="inorder"
        TMOE_ARIA2_OPTION_02="default"
        TMOE_ARIA2_OPTION_03="random"
        TMOE_ARIA2_OPTION_04="geom"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='stream-piece-selector'
        TMOE_ARIA2_TIPS='指定 HTTP/FTP 下载使用的分片选择算法. 分片表示的是并行下载时固定长度的分隔段. 如果设置为"default"(默认), aria2 将会按减少建立连接数选择分片. 由于建立连接操作的成本较高, 因此这是合理的默认行为. 如果设置为"inorder"(顺序), aria2 将选择索引最小的分片. 索引为 0 时表示为文件的第一个分片. 这将有助于视频的边下边播. --enable-http-pipelining 选项有助于减少重连接的开销. 请注意, aria2 依赖于 --min-split-size 选项, 所以有必要对 --min-split-size 选项设置一个合理的值. 如果设置为"random"(随机), aria2 将随机选择一个分片. 就像"inorder"(顺序)一样, 依赖于 --min-split-size 选项. 如果设置为"geom"(几何), aria2 会先选择索引最小的分片, 然后会为之前选择的分片保留指数增长的空间. 这将减少建立连接的次数, 同时文件开始部分将会先行下载. 这也有助于视频的边下边播.'
        ;;
    15)
        TMOE_ARIA2_OPTION_01="inorder"
        TMOE_ARIA2_OPTION_02=""
        TMOE_ARIA2_OPTION_03="feedback"
        TMOE_ARIA2_OPTION_04="adaptive"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='uri-selector'
        TMOE_ARIA2_TIPS='指定 URI 选择的算法. 可选的值包括"inorder"(按顺序), "feedback"(反馈） 和 "adaptive"(自适应). 如果设置为"inorder", URI 将按列表中出现的顺序使用. 如果设置为"feedback", aria2 将根据之前的下载速度选择 URI 列表中下载速度最快的服务器. 同时也将有效跳过无效镜像. 之前统计的下载速度将作为服务器状态文件的一部分, 参见 --server-stat-of 和 --server-stat-if 选项. 如果设置为"adaptive", 将从最好的镜像和保留的连接里选择一项. 补充说明, 其返回的镜像没有被测试过, 同时如果每个镜像都已经被测试过时, 返回的镜像还会被重新测试. 否则, 其将不会选择其他镜像. 例如"feedback", 其使用服务器状态文件.'
        ;;
    16)
        TMOE_ARIA2_GREP_NAME='http-auth-challenge'
        TMOE_ARIA2_TIPS='仅当服务器需要时才发送 HTTP 认证请求头. 如果设置为"false", 每次都会发送认证请求头. 例外: 如果用户名和密码包含在 URI 中, 将忽略此选项并且每次都会发送认证请求头.'
        ;;
    17)
        TMOE_ARIA2_GREP_NAME='http-no-cache'
        TMOE_ARIA2_TIPS='发送的请求头中将包含 Cache-Control: no-cache 和 Pragma: no-cache header 以避免内容被缓存. 如果设置为"false", 上述请求头将不会发送, 同时您也可以使用 --header 选项将 Cache-Control 请求头添加进去.'
        ;;
    18)
        TMOE_ARIA2_OPTION_01="root"
        TMOE_ARIA2_OPTION_02="user"
        TMOE_ARIA2_GREP_NAME='http-user'
        TMOE_ARIA2_TIPS='默认为空'
        ;;
    19)
        TMOE_ARIA2_OPTION_01="password"
        TMOE_ARIA2_OPTION_02="123456"
        TMOE_ARIA2_GREP_NAME='http-passwd'
        TMOE_ARIA2_TIPS='默认为空'
        ;;
    20)
        TMOE_ARIA2_OPTION_01=""
        TMOE_ARIA2_OPTION_02="*"
        TMOE_ARIA2_GREP_NAME='referer'
        TMOE_ARIA2_TIPS='设置 HTTP 请求来源 (Referer). 此选项将影响所有 HTTP/HTTPS 下载. 如果设置为 *, 请求来源将设置为下载链接. 此选项可以配合 --parameterized-uri 选项使用.'
        ;;
    21)
        TMOE_ARIA2_GREP_NAME='enable-http-keep-alive'
        TMOE_ARIA2_TIPS='启用 HTTP/1.1 持久连接.'
        ;;
    22)
        TMOE_ARIA2_GREP_NAME='enable-http-pipelining'
        TMOE_ARIA2_TIPS='启用 HTTP/1.1 管线化.'
        ;;
    23)
        TMOE_ARIA2_OPTION_01="X-B: 9J1"
        TMOE_ARIA2_OPTION_02="X-A: b78"
        TMOE_ARIA2_GREP_NAME='header'
        TMOE_ARIA2_TIPS='增加 HTTP 请求头内容.'
        ;;
    24)
        FILE_EXT_01='txt'
        FILE_EXT_02='sqlite'
        START_DIR="${HOME}/sd"
        IMPORTANT_TIPS='您可以选择cookie文件'
        TMOE_ARIA2_SETTINGS_MODEL='03'
        TMOE_ARIA2_OPTION_01="${HOME}/sd/Download/cookies.sqlite"
        TMOE_ARIA2_OPTION_02="${HOME}/sd/Download/cookies.txt"
        TMOE_ARIA2_GREP_NAME='save-cookies'
        TMOE_ARIA2_TIPS='以 Mozilla/Firefox(1.x/2.x)/Netscape 格式将 Cookies 保存到文件中. 如果文件已经存在, 将被覆盖. 会话过期的 Cookies 也将会保存, 其过期时间将会设置为 0.'
        ;;
    25)
        TMOE_ARIA2_GREP_NAME='use-head'
        TMOE_ARIA2_TIPS='第一次请求 HTTP 服务器时使用 HEAD 方法.'
        ;;
    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
tmoe_aria2_bt_and_pt() {
    TMOE_ARIA2_OPTION_01=true
    TMOE_ARIA2_OPTION_02=false
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_bt_and_pt'
    TMOE_OPTION=$(whiptail --title "BT AND PT" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "更新BT-tracker服务器" \
        "02" "follow-torrent 当下载的是一个种子(以.torrent结尾)时, 自动开始BT任务" \
        "03" "bt-max-peers 单个种子最大连接节点数" \
        "04" "enable-dht  打开ipv4 DHT功能" \
        "05" "enable-dht6  打开IPv6 DHT功能" \
        "06" "bt-enable-lpd  本地节点查找(LPD)" \
        "07" "enable-peer-exchange  种子（节点）交换" \
        "08" "bt-request-peer-speed-limit  期望下载速度（每个种子限速, 对少种的PT很有用）" \
        "09" "peer-id-prefix  节点 ID 前缀(客户端伪装), PT需要。" \
        "10" "peer-agent 指定 BT 扩展握手期间用于节点客户端版本的字符串" \
        "11" "bt-require-crypto  需要加密" \
        "12" "seed-ratio  种子分享率" \
        "13" "seed-time  最小做种时间" \
        "14" "force-save  强制保存会话, 即使任务已经完成, 默认:false" \
        "15" "bt-hash-check-seed  BT校验相关" \
        "16" "bt-seed-unverified  继续之前的BT任务时, 无需再次校验" \
        "17" "bt-save-metadata  保存种子文件" \
        "18" "bt-detach-seed-only  分离仅做种任务" \
        "19" "bt-enable-hook-after-hash-check  启用哈希检查完成事件" \
        "20" "bt-exclude-tracker  BT排除服务器地址" \
        "21" "bt-external-ip  外部 IP 地址" \
        "22" "bt-force-encryption  强制加密" \
        "23" "bt-load-saved-metadata  加载已保存的元数据文件" \
        "24" "bt-max-open-files  最多打开文件数" \
        "25" "bt-metadata-only  仅下载种子文件" \
        "26" "bt-min-crypto-level  最低加密级别" \
        "27" "bt-prioritize-piece  优先下载" \
        "28" "bt-remove-unselected-file  删除未选择的文件" \
        "29" "bt-stop-timeout  无速度时自动停止时间" \
        "30" "bt-tracker-connect-timeout  BT 服务器连接超时时间" \
        "31" "bt-tracker-interval  BT 服务器连接间隔时间" \
        "32" "bt-tracker-timeout  BT 服务器超时时间" \
        "33" "dht-file-path  DHT (IPv4) 文件" \
        "34" "dht-file-path6  DHT (IPv6) 文件" \
        "35" "dht-message-timeout  DHT 消息超时时间" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") tmoe_aria2_download_protocol ;;
    01)
        TMOE_ARIA2_GREP_NAME='bt-tracker'
        # TMOE_ARIA2_TIPS='如果服务器地址在 --bt-exclude-tracker 选项中, 其将不会生效.\nwiki: BitTorrent tracker（中文可称：BT服务器、tracker服务器等）是帮助BitTorrent协议在节点与节点之间做连接的服务器。\nBitTorrent客户端下载一开始就要连接到tracker，从tracker获得其他客户端IP地址后，才能连接到其他客户端下载。在传输过程中，也会一直与tracker通信，上传自己的信息，获取其它客户端的信息。\n一般BitTorrent客户端可以手动添加tracker。tracker也会提供很多端口。\n由于tracker对BT下载起到客户端协调和调控的重要作用，所以一旦被封锁会严重影响BT下载。'
        aria2_bt_tracker
        #此处需要写配置脚本
        ;;
    02)
        TMOE_ARIA2_OPTION_03="mem"
        TMOE_ARIA2_OPTION_04=""
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='follow-torrent'
        TMOE_ARIA2_TIPS='选项4为空，默认:true,如果设置为"true"或"mem", 当后缀为 .torrent 或内容类型为 application/x-bittorrent 的文件下载完成时, aria2 将按种子文件读取并下载该文件中提到的文件. 如果设置为"mem"(仅内存), 该种子文件将不会写入到磁盘中, 而仅会存储在内存中. 如果设置为"false"(否), 则 .torrent 文件会下载到磁盘中, 但不会按种子文件读取并且其中的文件不会进行下载.'
        ;;
    03)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="55"
        TMOE_ARIA2_GREP_NAME='bt-max-peers'
        TMOE_ARIA2_TIPS='默认:55，0为无限制。'
        ;;
    04)
        TMOE_ARIA2_GREP_NAME='enable-dht'
        TMOE_ARIA2_TIPS=' PT需要禁用, BT建议启用,默认:true\n启用 IPv4 DHT 功能. 此选项同时会启用 UDP 服务器支持. 如果种子设置为私有, 即使此选项设置为"true", aria2 也不会启用 DHT.'
        ;;
    05)
        TMOE_ARIA2_GREP_NAME='enable-dht6'
        TMOE_ARIA2_TIPS='PT需要禁用,默认:false\n启用 IPv6 DHT 功能. 如果种子设置为私有, 即使此选项设置为"true", aria2 也不会启用 DHT. 使用 --dht-listen-port 选项设置监听的端口.'
        ;;
    06)
        TMOE_ARIA2_GREP_NAME='bt-enable-lpd'
        TMOE_ARIA2_TIPS='PT需要禁用, 默认:false'
        ;;
    07)
        TMOE_ARIA2_GREP_NAME='enable-peer-exchange'
        TMOE_ARIA2_TIPS='PT需要禁用,BT建议启用,默认:true\n启用节点交换扩展. 如果种子设置为私有, 即使此选项设置为"true", aria2 也不会启用此功能.'
        ;;
    08)
        TMOE_ARIA2_OPTION_01="100K"
        TMOE_ARIA2_OPTION_02="50K"
        TMOE_ARIA2_GREP_NAME='bt-request-peer-speed-limit'
        TMOE_ARIA2_TIPS='默认:50K.如果一个 BT 下载的整体下载速度低于此选项设置的值, aria2 会临时提高连接数以提高下载速度. 在某些情况下, 设置期望下载速度可以提高您的下载速度. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    09)
        TMOE_ARIA2_OPTION_01="\-TR2940-"
        TMOE_ARIA2_OPTION_02='A2-1-35-0-'
        TMOE_ARIA2_GREP_NAME='peer-id-prefix'
        TMOE_ARIA2_TIPS='Tmoe-linux下的aria2配置默认伪装成Transmission 2.94\n指定节点 ID 的前缀. BT 中节点 ID 长度为 20 字节. 如果超过 20 字节, 将仅使用前 20 字节. 如果少于 20 字节, 将在其后不足随机的数据保证为 20 字节,默认:A2-1-35-0-'
        ;;
    10)
        TMOE_ARIA2_OPTION_01="Transmission/2.94"
        TMOE_ARIA2_OPTION_02="aria2/1.35.0"
        TMOE_ARIA2_GREP_NAME='peer-agent'
        TMOE_ARIA2_TIPS='默认:aria2/1.35.0'
        ;;
    11)
        TMOE_ARIA2_GREP_NAME='bt-require-crypto'
        TMOE_ARIA2_TIPS='如果设置为"true", aria 将不会接受以前的 BitTorrent 握手协议(\\19BitTorrent 协议)并建立连接. 因此 aria2 总是模糊握手.'
        ;;
    12)
        TMOE_ARIA2_OPTION_01="0.0"
        TMOE_ARIA2_OPTION_02="1.0"
        TMOE_ARIA2_OPTION_03="1.5"
        TMOE_ARIA2_OPTION_04="2.0"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='seed-ratio'
        TMOE_ARIA2_TIPS='当种子的分享率达到这个数时, 自动停止做种, 0为一直做种, 默认:1.0\n如果您想不限制分享比率, 可以设置为 0.0 \n如果同时设置了 --seed-time 选项, 当任意一个条件满足时将停止做种.\n指定更高的分享率意味着您将为P2P网络（生态）作出更大的贡献。'
        ;;
    13)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="1"
        TMOE_ARIA2_OPTION_03="5"
        TMOE_ARIA2_OPTION_04="10"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='seed-time'
        TMOE_ARIA2_TIPS='此选项设置为 0 时, 将在 BT 任务下载完成后不进行做种.'
        ;;
    14)
        TMOE_ARIA2_GREP_NAME='force-save'
        TMOE_ARIA2_TIPS='较新的版本开启后会在任务完成后依然保留.aria2文件\n即使任务完成或删除时使用 --save-session 选项时也保存该任务. 此选项在这种情况下还会保存控制文件. 此选项可以保存被认为已经完成但正在做种的 BT 任务.'
        ;;
    15)
        TMOE_ARIA2_GREP_NAME='bt-hash-check-seed'
        TMOE_ARIA2_TIPS='默认:true，做种前检查文件哈希\n如果设置为"true", 当使用 --check-integrity 选项完成哈希检查及文件完成后才继续做种. 如果您希望仅当文件损坏或未完成时检查文件, 请设置为"false". 此选项仅对 BT 下载有效'
        ;;
    16)
        TMOE_ARIA2_GREP_NAME='bt-seed-unverified'
        TMOE_ARIA2_TIPS='默认:false,不检查之前下载文件中每个分片的哈希值.'
        ;;
    17)
        TMOE_ARIA2_GREP_NAME='bt-save-metadata'
        TMOE_ARIA2_TIPS='保存磁力链接元数据为种子文件(.torrent文件), 默认:false\n保存种子文件为 ".torrent" 文件. 此选项仅对磁链生效. 文件名为十六进制编码后的哈希值及 ".torrent"后缀. 保存的目录与下载文件的目录相同. 如果相同的文件已存在, 种子文件将不会保存.'
        ;;
    18)
        TMOE_ARIA2_GREP_NAME='bt-detach-seed-only'
        TMOE_ARIA2_TIPS='统计当前活动下载任务(参见 -j 选项) 时排除仅做种的任务. 这意味着, 如果参数设置为 -j3, 此选项打开并且当前有 3 个正在活动的任务, 并且其中有 1 个进入做种模式, 那么其会从正在下载的数量中排除(即数量会变为 2), 在队列中等待的下一个任务将会开始执行. 但要知道, 在 RPC 方法中, 做种的任务仍然被认为是活动的下载任务.'
        ;;
    19)
        TMOE_ARIA2_GREP_NAME='bt-enable-hook-after-hash-check'
        TMOE_ARIA2_TIPS='允许 BT 下载哈希检查(参见 -V 选项) 完成后调用命令. 默认情况下, 当哈希检查成功后, 通过 --on-bt-download-complete 设置的命令将会被执行. 如果要禁用此行为, 请设置为"false".'
        ;;
    20)
        TMOE_ARIA2_OPTION_01="*"
        TMOE_ARIA2_OPTION_02=""
        TMOE_ARIA2_GREP_NAME='bt-exclude-tracker'
        TMOE_ARIA2_TIPS='逗号分隔的 BT 排除服务器地址. 您可以使用 * 匹配所有地址, 因此将排除所有服务器地址. 当在 shell 命令行使用 * 时, 需要使用转义符或引号.'
        ;;
    21)
        TMOE_ARIA2_OPTION_01="*"
        TMOE_ARIA2_OPTION_02=""
        TMOE_ARIA2_GREP_NAME='bt-external-ip'
        TMOE_ARIA2_TIPS='指定用在 BitTorrent 下载和 DHT 中的外部 IP 地址. 它可能被发送到 BitTorrent 服务器. 对于 DHT, 此选项将会报告本地节点正在下载特定的种子. 这对于在私有网络中使用 DHT 非常关键. 虽然这个方法叫外部, 但其可以接受各种类型的 IP 地址.'
        ;;
    22)
        TMOE_ARIA2_GREP_NAME='bt-force-encryption'
        TMOE_ARIA2_TIPS='BT 消息中的内容需要使用 arc4 加密. 此选项是设置 --bt-require-crypto --bt-min-crypto-level=arc4 这两个选项的快捷方式. 此选项不会修改上述两个选项的内容. 如果设置为"true", 将拒绝以前的 BT 握手, 并仅使用模糊握手及加密消息.'
        ;;
    23)
        TMOE_ARIA2_GREP_NAME='bt-load-saved-metadata'
        TMOE_ARIA2_TIPS='当使用磁链下载时, 在从 DHT 获取种子元数据之前, 首先尝试加载使用 --bt-save-metadata 选项保存的文件. 如果文件加载成功, 则不会从 DHT 下载元数据.'
        ;;
    24)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="100"
        TMOE_ARIA2_GREP_NAME='bt-max-open-files'
        TMOE_ARIA2_TIPS='设置 BT/Metalink 下载全局打开的最大文件数.'
        ;;
    25)
        TMOE_ARIA2_GREP_NAME='bt-metadata-only'
        TMOE_ARIA2_TIPS='仅下载种子文件. 种子文件中描述的文件将不会下载. 此选项仅对磁链生效.'
        ;;
    26)
        TMOE_ARIA2_OPTION_01="arc4"
        TMOE_ARIA2_OPTION_02="plain"
        TMOE_ARIA2_GREP_NAME='bt-min-crypto-level'
        TMOE_ARIA2_TIPS='设置加密方法的最小级别. 如果节点提供多种加密方法, aria2 将选择满足给定级别的最低级别.'
        ;;
    27)
        TMOE_ARIA2_OPTION_01="head=100K"
        TMOE_ARIA2_OPTION_02="tail=100K"
        TMOE_ARIA2_GREP_NAME='bt-prioritize-piece'
        TMOE_ARIA2_TIPS='尝试先下载每个文件开头或结尾的分片. 此选项有助于预览文件. 参数可以包括两个关键词: head 和 tail. 如果包含两个关键词, 需要使用逗号分隔. 每个关键词可以包含一个参数, SIZE. 例如, 如果指定 head=SIZE, 每个文件的最前 SIZE 数据将会获得更高的优先级. tail=SIZE 表示每个文件的最后 SIZE 数据. SIZE 可以包含 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    28)
        TMOE_ARIA2_GREP_NAME='bt-remove-unselected-file'
        TMOE_ARIA2_TIPS='当 BT 任务完成后删除未选择的文件. 要选择需要下载的文件, 请使用 --select-file 选项. 如果没有选择, 则所有文件都默认为需要下载. 此选项会从磁盘上直接删除文件, 请谨慎使用此选项.'
        ;;
    29)
        TMOE_ARIA2_OPTION_01="100"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='bt-stop-timeout'
        TMOE_ARIA2_TIPS='当 BT 任务下载速度持续为 0, 达到此选项设置的时间后停止下载. 如果设置为 0, 此功能将禁用.'
        ;;
    30)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='bt-tracker-connect-timeout'
        TMOE_ARIA2_TIPS='设置 BT 服务器的连接超时时间 (秒). 当连接建立后, 此选项不再生效, 请使用 --bt-tracker-timeout 选项.'
        ;;
    31)
        TMOE_ARIA2_OPTION_01="60"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='bt-tracker-interval'
        TMOE_ARIA2_TIPS='设置请求 BT 服务器的间隔时间 (秒). 此选项将完全覆盖服务器返回的最小间隔时间和间隔时间, aria2 仅使用此选项的值.如果设置为 0, aria2 将根据服务器的响应情况和下载进程决定时间间隔.'
        ;;
    32)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='bt-tracker-timeout'
        TMOE_ARIA2_TIPS='默认为60'
        ;;
    33)
        FILE_EXT_01='dat'
        FILE_EXT_02='dbt'
        START_DIR="${TMOE_ARIA2_PATH}"
        IMPORTANT_TIPS='您可以选择aria2的IPv4 DHT文件,支持dBase III DBT格式'
        TMOE_ARIA2_SETTINGS_MODEL='03'
        TMOE_ARIA2_OPTION_01="${HOME}/.aria2/dht.dat"
        TMOE_ARIA2_OPTION_02="./dht.dat"
        TMOE_ARIA2_GREP_NAME='dht-file-path'
        TMOE_ARIA2_TIPS='修改 IPv4 DHT 路由表文件路径.'
        ;;
    34)
        FILE_EXT_01='dat'
        FILE_EXT_02='dbt'
        START_DIR="${TMOE_ARIA2_PATH}"
        IMPORTANT_TIPS='您可以选择aria2的IPv6 DHT文件,支持dBase III DBT格式'
        TMOE_ARIA2_SETTINGS_MODEL='03'
        TMOE_ARIA2_OPTION_01="${HOME}/.aria2/dht6.dat"
        TMOE_ARIA2_OPTION_02="./dht6.dat"
        TMOE_ARIA2_GREP_NAME='dht-file-path6'
        TMOE_ARIA2_TIPS='修改 IPv6 DHT 路由表文件路径.'
        ;;
    35)
        TMOE_ARIA2_OPTION_01="60"
        TMOE_ARIA2_OPTION_02="10"
        TMOE_ARIA2_GREP_NAME='dht-message-timeout'
        TMOE_ARIA2_TIPS='默认为10'
        ;;

    esac
    ##############################
    case_tmoe_aria2_settings_model
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
aria2_bt_tracker() {
    cat <<-'EOF'
     如果服务器地址在 --bt-exclude-tracker 选项中, 其将不会生效.
     wiki: BitTorrent tracker（中文可称：BT服务器、tracker服务器等）是帮助BitTorrent协议在节点与节点之间做连接的服务器。
     BitTorrent客户端下载一开始就要连接到tracker，从tracker获得其他客户端IP地址后，才能连接到其他客户端下载。在传输过程中，也会一直与tracker通信，上传自己的信息，获取其它客户端的信息。一般BitTorrent客户端可以手动添加tracker。tracker也会提供很多端口。
     由于tracker对BT下载起到客户端协调和调控的重要作用，所以一旦被封锁会严重影响BT下载。
EOF
    update_aria2_bt_tracker
    check_tmoe_aria2_config_value
    printf "%s\n" "${TMOE_ARIA2_CONFIG_STATUS}"
    printf "%s\n" "更新完成，您可能需要重启aria2c进程才能生效"
    printf "%s\n" "如需自动更新，则请手动将${GREEN}aria2-i bt${RESET}添加至定时任务"
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
################
update_aria2_bt_tracker() {
    #此处环境变量并非多余
    TMOE_ARIA2_PATH='/usr/local/etc/tmoe-linux/aria2'
    TMOE_ARIA2_FILE='/usr/local/etc/tmoe-linux/aria2/aria2.conf'
    BT_TRACKER_URL='https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt'
    BT_TRACKER_REPO='https://github.com/ngosang/trackerslist'
    cd ${TMOE_ARIA2_PATH}
    printf "%s\n" "${BT_TRACKER_REPO}"
    if [ ! -d "trackerslist" ]; then
        git clone --depth=1 ${BT_TRACKER_REPO} trackerslist
        cd trackerslist
    else
        cd trackerslist
        git reset --hard
        git pull --rebase --stat --depth=1 --allow-unrelated-histories || git rebase --skip
    fi
    list=$(cat ./trackers_all.txt | awk NF | sed ":a;N;s/\n/,/g;ta")
    if grep -q 'bt-tracker=' "${TMOE_ARIA2_FILE}"; then
        sed -i "s@bt-tracker.*@bt-tracker=$list@g" ${TMOE_ARIA2_FILE}
        printf "%s\n" "更新中......"
    else
        sed -i '$a bt-tracker='${list} ${TMOE_ARIA2_FILE}
        printf "%s\n" "添加中......"
    fi
    # pkill aria2c&& systemctl start aria2
}
#######################
check_tmoe_aria2_config_value() {
    TMOE_ARIA2_CONFIG_VALUE=$(grep ${TMOE_ARIA2_GREP_NAME}= ${TMOE_ARIA2_FILE} | head -n 1 | cut -d '=' -f 2)
    TMOE_ARIA2_CONFIG_LINE=$(grep -n ${TMOE_ARIA2_GREP_NAME}= ${TMOE_ARIA2_FILE} | head -n 1 | awk '{print $1}' | cut -d ':' -f 1)
    if grep -q "^${TMOE_ARIA2_GREP_NAME}=" ${TMOE_ARIA2_FILE}; then
        TMOE_ARIA2_CONFIG_STATUS="检测到${TMOE_ARIA2_GREP_NAME}的值为${TMOE_ARIA2_CONFIG_VALUE}"
        TMOE_ARIA2_CONFIG_ENABLED=true
    elif grep -q "^#${TMOE_ARIA2_GREP_NAME}=" ${TMOE_ARIA2_FILE}; then
        TMOE_ARIA2_CONFIG_STATUS="检测到${TMOE_ARIA2_GREP_NAME}的值为默认"
        TMOE_ARIA2_CONFIG_ENABLED=false
    else
        TMOE_ARIA2_CONFIG_STATUS="检测到您未启用${TMOE_ARIA2_GREP_NAME}"
        TMOE_ARIA2_CONFIG_ENABLED='no'
    fi
}
######################
tmoe_aria2_settings_model_01() {
    #此处不要设置RETURN_TO_WHERE的变量
    check_tmoe_aria2_config_value
    RETURN_TO_MENU='tmoe_aria2_settings_model_01'
    TMOE_OPTION=$(whiptail --title "您想要将参数${TMOE_ARIA2_GREP_NAME}修改为哪个值" --menu "${TMOE_ARIA2_CONFIG_STATUS}\n${TMOE_ARIA2_TIPS}" 0 50 0 \
        "0" "Return to previous menu 返回上级菜单" \
        "1" "${TMOE_ARIA2_OPTION_01}" \
        "2" "${TMOE_ARIA2_OPTION_02}" \
        "3" "custom手动输入" \
        "4" "注释/隐藏${TMOE_ARIA2_GREP_NAME}(禁用该参数或使用默认值)" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") ${RETURN_TO_WHERE} ;;
    1) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_01} ;;
    2) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_02} ;;
    3) custom_aria2_config ;;
    4) TMOE_ARIA2_CONFIG_ENABLED='hide' ;;
    esac
    ##############################
    modify_aria2_config_value
    press_enter_to_return
    tmoe_aria2_settings_model_01
}
######################
tmoe_aria2_settings_model_02() {
    check_tmoe_aria2_config_value
    RETURN_TO_MENU='tmoe_aria2_settings_model_02'
    TMOE_OPTION=$(whiptail --title "您想要将参数${TMOE_ARIA2_GREP_NAME}修改为哪个值" --menu "${TMOE_ARIA2_CONFIG_STATUS}\n${TMOE_ARIA2_TIPS}" 0 50 0 \
        "0" "Return to previous menu 返回上级菜单" \
        "1" "${TMOE_ARIA2_OPTION_01}" \
        "2" "${TMOE_ARIA2_OPTION_02}" \
        "3" "${TMOE_ARIA2_OPTION_03}" \
        "4" "${TMOE_ARIA2_OPTION_04}" \
        "5" "custom手动输入" \
        "6" "注释/隐藏${TMOE_ARIA2_GREP_NAME}(禁用该参数或使用默认值)" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") ${RETURN_TO_WHERE} ;;
    1) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_01} ;;
    2) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_02} ;;
    3) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_03} ;;
    4) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_04} ;;
    5) custom_aria2_config ;;
    6) TMOE_ARIA2_CONFIG_ENABLED='hide' ;;
    esac
    ##############################
    modify_aria2_config_value
    press_enter_to_return
    tmoe_aria2_settings_model_02
}
#############
select_tmoe_aria2_file() {
    #where_is_tmoe_file_dir
    tmoe_file_manager
    if [ -z ${SELECTION} ]; then
        printf "%s\n" "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
        #${RETURN_TO_WHERE}
        ${RETURN_TO_MENU}
    else
        printf "%s\n" "您选择的文件为${TMOE_FILE_ABSOLUTE_PATH}"
        ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
        TMOE_ARIA2_OPTION_TARGET=${TMOE_FILE_ABSOLUTE_PATH}
    fi
}
######################
tmoe_aria2_settings_model_03() {
    #此处不要设置RETURN_TO_WHERE的变量
    RETURN_TO_MENU='tmoe_aria2_settings_model_03'
    check_tmoe_aria2_config_value
    TMOE_OPTION=$(whiptail --title "您想要将参数${TMOE_ARIA2_GREP_NAME}修改为哪个值" --menu "${TMOE_ARIA2_CONFIG_STATUS}\n${TMOE_ARIA2_TIPS}" 0 50 0 \
        "0" "Return to previous menu 返回上级菜单" \
        "1" "select选择文件" \
        "2" "${TMOE_ARIA2_OPTION_01}" \
        "3" "${TMOE_ARIA2_OPTION_02}" \
        "4" "custom手动输入" \
        "5" "注释/隐藏${TMOE_ARIA2_GREP_NAME}(禁用该参数或使用默认值)" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") ${RETURN_TO_WHERE} ;;
    1) select_tmoe_aria2_file ;;
    2) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_01} ;;
    3) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_02} ;;
    4) custom_aria2_config ;;
    5) TMOE_ARIA2_CONFIG_ENABLED='hide' ;;
    esac
    ##############################
    modify_aria2_config_value
    press_enter_to_return
    tmoe_aria2_settings_model_03
}
######################
modify_aria2_config_value() {
    case "${TMOE_ARIA2_CONFIG_ENABLED}" in
    true | false) #sed -i "s@${TMOE_ARIA2_CONFIG_VALUE}@${TMOE_ARIA2_OPTION_TARGET}@g" ${TMOE_ARIA2_FILE}
        sed -i "${TMOE_ARIA2_CONFIG_LINE} c ${TMOE_ARIA2_GREP_NAME}=${TMOE_ARIA2_OPTION_TARGET}" ${TMOE_ARIA2_FILE}
        ;;
        #false)
        #   sed -i "s@^#${TMOE_ARIA2_GREP_NAME}@${TMOE_ARIA2_GREP_NAME}@" ${TMOE_ARIA2_FILE}
        #  sed -i "s@${TMOE_ARIA2_CONFIG_VALUE}@${TMOE_ARIA2_OPTION_TARGET}@g" ${TMOE_ARIA2_FILE}
        # ;;
    no) sed -i "$ a ${TMOE_ARIA2_GREP_NAME}=${TMOE_ARIA2_OPTION_TARGET}" ${TMOE_ARIA2_FILE} ;;
    hide) sed -i "s@^${TMOE_ARIA2_GREP_NAME}=@#&@" ${TMOE_ARIA2_FILE} ;;
    esac
    check_tmoe_aria2_config_value
    printf "%s\n" "${TMOE_ARIA2_GREP_NAME} has been modified."
    #printf "%s\n" "${TMOE_ARIA2_GREP_NAME}的值已修改为${TMOE_ARIA2_CONFIG_VALUE}"
    printf "%s\n" "${TMOE_ARIA2_CONFIG_STATUS}"
}
###################
custom_aria2_config() {
    TMOE_ARIA2_OPTION_TARGET=$(whiptail --inputbox "请手动输入参数${TMOE_ARIA2_GREP_NAME}的值" 0 0 --title "${TMOE_ARIA2_GREP_NAME} conf" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        ${RETURN_TO_WHERE}
    elif [ -z "${TMOE_ARIA2_OPTION_TARGET}" ]; then
        printf "%s\n" "请输入有效的数值"
        printf "%s\n" "Please enter a valid value"
        printf "%s\n" "您输入了一个空数值，将自动切换为${TMOE_ARIA2_OPTION_02}"
        TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_02}
    fi
}
#############
#############
other_tmoe_aria2_conf() {
    TMOE_OPTION=$(whiptail --title "其它选项" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "1" "update 更新" \
        "2" "DEL conf删除配置文件" \
        "3" "DEL ariang删除AriaNG" \
        "0" "Back 返回" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") configure_aria2_rpc_server ;;
    1) upgrade_tmoe_aria2_tool ;;
    2) del_tmoe_aria2_conf ;;
    3) del_ariang ;;
    esac
    ##############################
    press_enter_to_return
    other_tmoe_aria2_conf
}
############
del_ariang() {
    rm -rv /usr/share/applications/ariang.desktop /usr/local/bin/startariang ${TMOE_ARIA2_PATH}/ariang_dark.html
}
###########
tmoe_aria2_faq() {
    TMOE_OPTION=$(whiptail --title "ARIA2_FAQ" --menu "您有哪些疑问？\nWhat questions do you have?" 0 50 0 \
        "1" "如何连接" \
        "2" "AriaNG地址与RPC服务地址的区别" \
        "3" "如何搭建属于自己的AriaNG网页" \
        "4" "查看文档" \
        "5" "Aria2是什么" \
        "6" "如何突破线程数" \
        "0" "Back 返回" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") configure_aria2_rpc_server ;;
    1) how_to_connect_to_aria2_rpc_server ;;
    2) what_is_the_different_of_ariang_and_rpc ;;
    3) how_to_build_an_aria_ng_page ;;
    4) view_aria2_man ;;
    5) what_is_the_aria2 ;;
    6) aria2_17_threads ;;
    esac
    ##############################
    press_enter_to_return
    tmoe_aria2_faq
}
############
view_aria2_man() {
    cat <<-EOF
   ① 您可以前往官网阅览详细文档资料
http://aria2.github.io/manual/en/html/aria2c.html
   ② 您亦可直接在终端下输man aria2c
EOF
    xdg-open http://aria2.github.io/manual/en/html/aria2c.html 2>/dev/null
    man aria2c
}
############
aria2_17_threads() {
    cat <<-EOF
Q:如何突破16线程数的限制？
A:请自行编译aria2

Q:更高的线程真的能带来更快的速度吗？
A：从理论上来说，应该没错。

我曾经也和你持有相同的看法，可是后来，我发现在更多情况下，这种做法弊大于利。

一是不道德(商业公司除外)，盲目且无节制地调高线程数，会增大服务器的负担。
服务器酱变得更容易坏掉了呢！笑ˋ( ° ▽、° ) 

二是你的ip可能会被服务器防火墙拉黑，反而导致下载速度缓慢，甚至无法下载，最终适得其反。

EOF
}
#############
what_is_the_aria2() {
    cat <<-EOF
  Aria2是一款优秀且强大的开源下载工具。
  在十多年的光阴中，集成了众多开发者的精华，是谓集大成者之作。
  若您此前对此工具不甚了解，则初次研读文档资料，或将花费数小时。
  我们不应该因她的文档中包含了某些晦涩难懂的术语而抛弃她，更不该就此否定了开发者们的努力。
  #此处用她，突显了aria2的可爱，希望大家能够喜欢她。😊
  也希望大家多给用爱发电的开发者们一点包容。 (。・ω・。)
  ------------------------------------
  Aria2本身就已经足够强大了，借助第三方插件更是如虎添翼。
  借助油猴脚本，你可以快速下载xx盘，爬取Pxx站，下载Bxx站视频等。
  利用HOOK功能+脚本，能实现下载完成后自动上传至网盘，并同时删除已下载的本地文件。
  利用第三方RSS插件，实现RSS订阅下载。
  举个例子：比如某部番剧名为《转生成为史莱姆第二季》,你订阅了某个B..啊◑﹏◐不对，你订阅了某个正版资源交流网站的rss链接。
  每当字幕组更新时，aria2就能开始自动下载。
  ------------------------------------
EOF
}
##############
how_to_build_an_aria_ng_page() {
    cat <<-EOF
   ${YELLOW}https://github.com/mayswind/AriaNg/releases${RESET}
   1.前往大魔王mAysWINd的AriaNG发布页面，下载文件，解压后得到${BLUE}index.html${RESET}
   新建一个gitee公开仓库，并上传index.html。
   2.点击“服务”，选择“gitee pages”,此时不要选择“强制使用https”。若您的Aria2 rpc服务未开启TLS加密，则有可能导致RPC服务无法正常连接。
   3.最后在AriaNG设置中输入Aria2的RPC服务地址，端口号以及密钥 
   图文说明${YELLOW}https://gitee.com/mo2/a2${RESET}
EOF
}
############
how_to_connect_to_aria2_rpc_server() {
    cat <<-'EOF'
    AriaNG网页地址
    http://mo2.gitee.io/a2
    http://aria2.me
    http://aria2.net
EOF
    printf "%s\n" "您可以使用浏览器来打开${YELLOW}AriaNG网页地址${RESET}，并在AriaNG设置页面中连接至${RESET}RPC服务${RESET}(需输入地址，端口和密钥)"
    printf "%s\n" "Q:为什么无法连接？明明RPC地址，密钥和端口都没错"
    printf "%s\n" "A:防火墙放行${ARIA2_RPC_PORT}端口"
    printf "%s\n" "UFW防火墙的用法为ufw allow ${ARIA2_RPC_PORT}"
    printf "%s\n" "-------------------------------"
    printf '%s\n' '若您为初次配置，则建议您前往“RPC服务器与TLS加密”-->“rpc-secret RPC 令牌密钥” 选项处，设定一个访问密码。'
    printf '%s\n' '在公网环境下，无密码是一件非常危险的事。'
    printf "%s\n" "-------------------------------"
    ARIA2_RPC_PORT=$(grep 'rpc-listen-port=' ${TMOE_ARIA2_FILE} | cut -d '=' -f 2)
    printf "%s\n" "本机默认RPC服务地址为ws://localhost:${ARIA2_RPC_PORT}/jsonrpc"
    echo The LAN RPC address 局域网RPC服务地址 ws://$(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2 | awk '{print $1}'):${ARIA2_RPC_PORT}/jsonrpc
    echo The WAN RPC address 外网RPC服务地址 ws://$(curl -sL ip.cip.cc | head -n 1):${ARIA2_RPC_PORT}/jsonrpc
    printf '%s\n' '若存在兼容问题，则可将websocket(ws)替换为http'

}
###########
what_is_the_different_of_ariang_and_rpc() {
    cat <<-EOF
    AriaNG是大魔王mAysWINd开发的Aria2 web前端，你也可以把它理解成客户端，而Aria2 RPC则是服务端。
    你可以通过客户端来访问服务端。
    也就是说，你在浏览器里输入了AriaNG地址，访问到了客户端，然后在客户端里输入RPC服务端地址，最后才连接到了服务端。
    
    在web服务器上搭建AriaNG网页，表面上看起来它同时具备了服务端和客户端两种属性。
    但从功能上来看，它仍然是客户端。

    举个例子：如果你想要喝水的话，那么你是直接到水源处去喝，还是去自来水厂喝，亦或是通过某样工具（比如说水龙头这种东西）去喝呢？
    相信你一定会有自己的见解。
EOF
}
##############
tmoe_aria2_download_protocol() {
    TMOE_OPTION=$(whiptail --title "RROTOCAL" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "1" "BT/磁力+PT种子" \
        "2" "HTTP" \
        "3" "FTP与metalink" \
        "0" "Back 返回" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") configure_aria2_rpc_server ;;
    1) tmoe_aria2_bt_and_pt ;;
    2) tmoe_aria2_http ;;
    3) tmoe_aria2_ftp_and_metalink ;;
    esac
    ##############################
    press_enter_to_return
    tmoe_aria2_download_protocol
}
########################
configure_aria2_rpc_server() {
    RETURN_TO_WHERE='configure_aria2_rpc_server'
    #进入aria2配置文件目录
    cd ${TMOE_ARIA2_PATH}
    TMOE_OPTION=$(whiptail --title "Tmoe-aria2-tool 2020071713" --menu "您想要修改哪项配置？输aria2-i启动本工具\nWhich conf do you want to modify?" 0 50 0 \
        "1" "One-key conf 初始化一键配置" \
        "2" "process进程管理" \
        "3" "FAQ常见问题" \
        "4" "file allocation文件保存与分配" \
        "5" "edit manually手动编辑" \
        "6" "connection网络连接与下载限制" \
        "7" "port端口" \
        "8" "RPC服务器与TLS加密" \
        "9" "HTTP/BT/FTP:下载协议" \
        "10" "logs & info日志与输出信息" \
        "11" "事件HOOK" \
        "12" "proxy代理" \
        "13" "other其它选项" \
        "0" "exit 退出" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") exit 0 ;;
    1) tmoe_aria2_onekey ;;
    2) tmoe_aria2_systemd ;;
    3) tmoe_aria2_faq ;;
    4) tmoe_aria2_file ;;
    5) edit_tmoe_aria2_config_manually ;;
    6) tmoe_aria2_connection_threads ;;
    7) tmoe_aria2_port ;;
    8) tmoe_aria2_rpc_server_and_tls ;;
    9) tmoe_aria2_download_protocol ;;
    10) tmoe_aria2_logs ;;
    11) tmoe_aria2_hook ;;
    12) tmoe_aria2_proxy ;;
    13) other_tmoe_aria2_conf ;;
    esac
    ##############################
    press_enter_to_return
    configure_aria2_rpc_server
}
##############
edit_tmoe_aria2_config_manually() {
    if [ $(command -v editor) ]; then
        editor ${TMOE_ARIA2_FILE}
    else
        nano ${TMOE_ARIA2_FILE}
    fi
}
##########
tmoe_aria2_systemd() {
    TMOE_DEPENDENCY_SYSTEMCTL='aria2'
    pgrep aria2 &>/dev/null
    if [ "$?" = "0" ]; then
        TMOE_ARIA2_STATUS='检测到aria2进程正在运行\nDetected that the aria2 process is running.'
    else
        TMOE_ARIA2_STATUS='检测到aria2进程未运行\nDetected that aria2 process is not running'
    fi
    ARIA2_SYSTEMD_OPTION=$(whiptail --title "你想要对这个小可爱做什么？" --menu \
        "${TMOE_ARIA2_STATUS}" 0 50 0 \
        "1" "start启动" \
        "2" "stop停止" \
        "3" "status状态" \
        "4" "systemctl enable开机自启" \
        "5" "systemctl disable禁用自启" \
        "0" "Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${ARIA2_SYSTEMD_OPTION}" in
    0 | "") configure_aria2_rpc_server ;;
    1)
        printf "%s\n" "您可以输${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} start${RESET}或${GREEN}systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}来启动"
        printf "%s\n" "${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} start${RESET}"
        printf "%s\n" "按回车键启动"
        do_you_want_to_continue
        systemctl daemon-reload 2>/dev/null
        service ${TMOE_DEPENDENCY_SYSTEMCTL} start || systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL}
        ;;
    2)
        printf "%s\n" "您可以输${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} stop${RESET}或${GREEN}systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}来停止"
        printf "%s\n" "${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} stop${RESET}"
        printf "%s\n" "按回车键停止"
        do_you_want_to_continue
        service ${TMOE_DEPENDENCY_SYSTEMCTL} stop || systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL}
        if [ $(pgrep aria2c) ]; then
            printf '%s\n' '正在强制停止aria2c'
            pkill aria2c
        fi
        ;;
    3)
        printf "%s\n" "您可以输${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} status${RESET}或${GREEN}systemctl status ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}来查看进程状态"
        printf "%s\n" "${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} status${RESET}"
        #printf "%s\n" "按回车键查看"
        #do_you_want_to_continue
        service ${TMOE_DEPENDENCY_SYSTEMCTL} status || systemctl status ${TMOE_DEPENDENCY_SYSTEMCTL}
        ;;
    4)
        printf "%s\n" "您可以输${GREEN}rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}或${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}来添加开机自启任务"
        printf "%s\n" "${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
        systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}
        if [ "$?" = "0" ]; then
            printf "%s\n" "已添加至自启任务"
        else
            printf "%s\n" "添加自启任务失败"
        fi
        ;;
    5)
        printf "%s\n" "您可以输${GREEN}rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}或${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}来禁止开机自启"
        printf "%s\n" "${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
        systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}
        if [ "$?" = "0" ]; then
            printf "%s\n" "已禁用开机自启"
        else
            printf "%s\n" "禁用自启任务失败"
        fi
        ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_aria2_systemd
}
#######################
##############
del_tmoe_aria2_conf() {
    pkill aria2c
    printf "%s\n" "正在停止aria2c进程..."
    printf "%s\n" "Stopping aria2c..."
    service aria2 stop 2>/dev/null || systemctl stop aria2
    printf '%s\n' '正在停用aria2开机自启动任务...'
    systemctl disable aria2
    rm -fv ${TMOE_ARIA2_FILE} /etc/systemd/system/aria2.service
    printf "%s\n" "${YELLOW}已删除aria2配置文件${RESET}"
}
###################
tmoe_aria2_onekey() {
    cd ${TMOE_ARIA2_PATH}
    if [ ! -e "aria2.session" ]; then
        printf "\n" >aria2.session
    fi
    if [ -e "aria2.conf" ]; then
        cp -vf aria2.conf aria2.conf.bak 2>/dev/null
    fi

    #cp -pvf ${HOME}/gitee/linux-gitee/.config/aria2.conf ./
    aria2c --console-log-level=warn --no-conf --allow-overwrite=true -o aria2.conf 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/.config/aria2.conf'
    case ${TMOE_PROOT} in
    true) printf "%s\n" "检测到您处于${BLUE}proot容器${RESET}环境下" ;;
    false) printf "%s\n" "检测到您处于${BLUE}chroot容器${RESET}环境下" ;;
    no) printf "%s\n" "检测到您可能处于${BLUE}proot容器${RESET}环境下" ;;
    esac
    cd /etc/systemd/system
    cat >aria2.service <<-EndOFaria
[Unit]
Description= aria2
After=network.target

[Service]
PIDFile=/run/aria2.pid
ExecStart=su - ${CURRENT_USER_NAME} -c  "cd /usr/local/etc/tmoe-linux/aria2 &&aria2c --conf-path=/usr/local/etc/tmoe-linux/aria2/aria2.conf"
ExecStop=/bin/kill \$MAINPID ;su - ${CURRENT_USER_NAME} -c "pkill aria2c"
RestartSec=always

[Install]
WantedBy=multi-user.target
	EndOFaria

    cd /etc/init.d
    cat >aria2 <<-EndOFaria
#!/usr/bin/env bash
### BEGIN INIT INFO
# Provides:          aria2
# Required-Start:    \$network \$local_fs \$remote_fs
# Required-Stop:     \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: High speed download utility
### END INIT INFO
PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/bin/aria2c
NAME="aria2"
DESC="High speed download utility"
PIDFILE=/run/aria2.pid


[ -x "\$DAEMON" ] || exit 0

. /lib/lsb/init-functions

DAEMON_OPTS=""


case "\$1" in
  start)
    printf "%s\n" "Starting aria2c... "
    su - ${CURRENT_USER_NAME} -c  "cd /usr/local/etc/tmoe-linux/aria2 && aria2c --conf-path=/usr/local/etc/tmoe-linux/aria2/aria2.conf & "
    ;;
  stop)
    printf "%s\n" "Stopping aria2c... "
    pkill aria2c
     log_daemon_msg "Stopping \$DESC" "\$NAME"
     start-stop-daemon --stop --quiet --oknodo --pidfile \$PIDFILE --remove-pidfile --exec \$DAEMON
     log_end_msg \$?
    ;;
  status)
  status_of_proc -p \$PIDFILE "\$DAEMON" "\$NAME" && exit 0 || exit \$?
    ;;
  *)
    printf "%s\n" "Usage: /etc/init.d/aria2 {start|stop|status}"
    exit 1
    ;;
esac
exit 0
	EndOFaria
    chmod +x aria2
    #############
    #if [ ! -e "/usr/local/bin/startariang" ]; then
    # create_ariang_script
    #fi

    #if [ ! -e "/usr/share/applications/ariang.desktop" ]; then
    create_ariang_script
    #create_aria_ng_desktop_link
    cd /usr/share/applications/
    create_aria_ng_desktop_link
    # fi
    ########################################
    cd ${TMOE_ARIA2_PATH}
    if [ ! -e "dht.dat" ]; then
        aria2c --console-log-level=warn --no-conf --allow-overwrite=true -o dht.dat https://raw.githubusercontent.com/2moe/tmoe-linux/master/.config/dht.dat
        chmod 666 dht.dat
    fi
    if [ ! -e "dht6.dat" ]; then
        aria2c --console-log-level=warn --no-conf --allow-overwrite=true -o dht6.dat https://raw.githubusercontent.com/2moe/tmoe-linux/master/.config/dht6.dat
        chmod 666 dht6.dat
    fi
    create_aria2_hook_script
    upgrade_tmoe_aria2_tool
    aria2_restart
    press_enter_to_return
    configure_aria2_rpc_server
    #此处的返回步骤并非多余
}
#########
aria2_restart() {
    pkill aria2c
    printf '%s\n' '正在启动aria2 rpc服务...'
    su - ${CURRENT_USER_NAME} -c "cd /usr/local/etc/tmoe-linux/aria2 && nohup aria2c --conf-path=/usr/local/etc/tmoe-linux/aria2/aria2.conf &>/dev/null &"
    if [ ! "$(pgrep aria2c)" ]; then
        service aria2 start
    fi
}
#############
create_aria2_hook_script() {
    cd ${TMOE_ARIA2_PATH}
    craet_aria2_auto_move_sh
    chmod +x auto_move_media_files.sh
    create_auto_upload_onedrive_sh
    chmod +x auto_upload_onedrive.sh
}
###############
create_auto_upload_onedrive_sh() {
    cat >auto_upload_onedrive.sh <<-'EOF'
    #!/usr/bin/env bash
    #https://github.com/MoeClub/OneList/tree/master/OneDriveUploader
    #https://www.moerats.com/archives/1006/
    #需配合萌咖大佬的OnedriveUploader使用
    GID="$1"
    FileNum="$2"
    File="$3"
    MaxSize="15728640"
    Thread="10"                             #默认3线程，自行修改，服务器配置不好的话，不建议太多
    Block="20"                              #默认分块20m，自行修改
    RemoteDIR="/share/Downloads/"           #上传到Onedrive的路径，默认为根目录
    LocalDIR="${HOME}/sd/Download/"         #Aria2下载目录，记得最后面加上/
    Uploader="/usr/bin/OneDriveUploader"    #上传的程序完整路径
    Config="${HOME}/.aria2/auth.json"  #初始化生成的配置auth.json绝对路径，参考第3步骤生成的路径

    if [[ -z $(printf "%s\n" "$FileNum" | grep -o '[0-9]*' | head -n1) ]]; then FileNum='0'; fi
    if [[ "$FileNum" -le '0' ]]; then exit 0; fi
    if [[ "$#" != '3' ]]; then exit 0; fi

    function LoadFile() {
        if [[ ! -e "${Uploader}" ]]; then return; fi
        IFS_BAK=$IFS
        IFS=$'\n'
        tmpFile="$(printf "%s\n" "${File/#$LocalDIR/}" | cut -f1 -d'/')"
        FileLoad="${LocalDIR}${tmpFile}"
        if [[ ! -e "${FileLoad}" ]]; then return; fi
        ItemSize=$(du -s "${FileLoad}" | cut -f1 | grep -o '[0-9]*' | head -n1)
        if [[ -z "$ItemSize" ]]; then return; fi
        if [[ "$ItemSize" -ge "$MaxSize" ]]; then
            echo -ne "\033[33m${FileLoad} \033[0mtoo large to spik.\n"
            return
        fi
        ${Uploader} -c "${Config}" -t "${Thread}" -b "${Block}" -s "${FileLoad}" -r "${RemoteDIR}"
        if [[ $? == '0' ]]; then
            rm -rf "${FileLoad}"
        fi
        IFS=$IFS_BAK
    }
    LoadFile
EOF
}
#################################
craet_aria2_auto_move_sh() {
    cat >auto_move_media_files.sh <<-'EOF'
        #!/usr/bin/env bash
        #https://github.com/liberize/liberize.github.com/blob/e9b48700c4457463a82e100d0df23df9ead16576/_posts/2015-07-26-turn-raspberry-pi-into-a-downloader.md
        if [ "$(ps -o comm= $PPID)" = 'aria2c' ]; then
            shift 2
        fi

        if [ "$1" = "" ]; then
            printf "%s\n" "usage: $(basename "$0") <file>"
            exit 0
        fi

        VIDEO_DIR=${HOME}/视频
        AUDIO_DIR=${HOME}/音乐
        IMAGE_DIR=${HOME}/图片

        FILE_PATH="$1"
        DIR_PATH="$(dirname "$FILE_PATH")"
        FILE_NAME="$(basename "$FILE_PATH")"
        FILE_NAME="${FILE_NAME%.*}"

        auto_move() {
            case "$1" in
            *.avi | *.mpg | *.wmv | *.mp4 | *.mov | *.mkv | *.rm | *.rmvb | *.3gp | *.flv | *.swf | *.srt | *.ass)
                printf "%s\n" "moving $1 to $VIDEO_DIR ..."
                mv "$1" "$VIDEO_DIR"
                ;;
            *.mp3 | *.wav | *.wma | *.mid | *.ape | *.flac)
                printf "%s\n" "moving $1 to $AUDIO_DIR ..."
                mv "$1" "$AUDIO_DIR"
                ;;
            *.jpg | *.jpeg | *.png | *.bmp | *.gif | *.tiff | *.psd | *.ico | *.svg)
                printf "%s\n" "moving $1 to $IMAGE_DIR ..."
                mv "$1" "$IMAGE_DIR"
                ;;
            esac
        }

        cd "$DIR_PATH"
        case "$FILE_PATH" in
        *.tar.bz2 | *.tbz2) tar -jxvf "$FILE_PATH" -C "$FILE_NAME" ;;
        *.tar.gz | *.tgz) tar -zxvf "$FILE_PATH" -C "$FILE_NAME" ;;
        *.tar.xz | *.txz) tar -Jxvf "$FILE_PATH" -C "$FILE_NAME" ;;
        *.bz2) bunzip2 -c "$FILE_PATH" >"$FILE_NAME" ;;
        *.rar) mkdir -pv "$FILE_NAME" && cd "$FILE_NAME" && unrar x "$FILE_PATH" && cd .. ;;
        *.gz) gunzip -c "$FILE_PATH" >"$FILE_NAME" ;;
        *.zip) unzip -d "$FILE_NAME" "$FILE_PATH" ;;
        *.7z) 7z x -o"$FILE_NAME" "$FILE_PATH" ;;
        *.tar*) tar xvf "$FILE_PATH" -C "$FILE_NAME" ;;
        *)
            auto_move "$FILE_PATH"
            exit 0
            ;;
        esac

        [ "$?" != 0 ] && exit 1

        rm -f "$FILE_PATH"
        for file in $(find "$FILE_NAME" -type f); do
            auto_move $file
        done
EOF
}
###############
create_ariang_script() {
    ARIANG_DARK_INDEX_FILE="${TMOE_ARIA2_PATH}/ariang_dark.html"
    if [ ! -e "${ARIANG_DARK_INDEX_FILE}" ]; then
        cd /tmp
        git clone -b dark --depth=1 https://gitee.com/mo2/a2.git .ARIA_NG_DARK_INDEX
        mv .ARIA_NG_DARK_INDEX/index.html ${ARIANG_DARK_INDEX_FILE}
        chmod +r ${ARIANG_DARK_INDEX_FILE}
        rm -rf .ARIA_NG_DARK_INDEX
    fi
    cd /usr/local/bin
    cat >startariang <<-'EOF'
#!/usr/bin/env bash
set -e
TMOE_ARIA2_PATH='/usr/local/etc/tmoe-linux/aria2'
if [ ! $(pgrep aria2c) ]; then
    systemctl start aria2 || sudo service aria2 start
    if [ ! $(pgrep aria2c) ]; then
        cd ${TMOE_ARIA2_PATH}
        aria2c --conf-path=${TMOE_ARIA2_PATH}/aria2.conf &
    fi    
fi
ARIANG_DARK_INDEX_FILE='/usr/local/etc/tmoe-linux/aria2/ariang_dark.html'
if [ -r ${ARIANG_DARK_INDEX_FILE} ]; then
    /usr/bin/sensible-browser ${ARIANG_DARK_INDEX_FILE}
fi
EOF
    chmod +x startariang
}
############
create_aria_ng_desktop_link() {
    ARIA_NG_ICON='/usr/local/etc/tmoe-linux/git/.mirror/ariang.png'
    if [ ! -e "/usr/share/icons/ariang.png" ]; then
        if [ -e "${ARIA_NG_ICON}" ]; then
            cp ${ARIA_NG_ICON} /usr/share/icons
        else
            aria2c --console-log-level=warn --no-conf --allow-overwrite=true -d /usr/share/icons -o ariang.png https://raw.githubusercontent.com/2moe/tmoe-linux/master/.mirror/ariang.png
        fi
    fi
    catimg "/usr/share/icons/ariang.png" 2>/dev/null
    cat >ariang.desktop <<-'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=AriaNg
Comment=AriaNg, a modern web frontend making aria2 easier to use.
Keywords=aria2;web-frontend;index;html;download;webgui;javascript;ui;ariang;web
Exec=/usr/local/bin/startariang
Icon=/usr/share/icons/ariang.png
Terminal=true
Categories=Network;
EOF
    chmod +r ariang.desktop
}
############
main "$@"
###########################################
