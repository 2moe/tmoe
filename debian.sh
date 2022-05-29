#!/usr/bin/env sh
# POSIX sh
#-----------------
show_package_info() {
    get_uname
    set_extra_deps
    # Architecture: amd64, i386, arm64, armhf, mipsel, riscv64, ppc64el, s390x
    cat <<-EndOfShow
		Package: tmoe-linux-manager
		Version: 1.4989.45
		Priority: optional
		Section: admin
		Maintainer: 2moe <25324935+2moe@users.noreply.github.com>
		Depends: aria2 (>= 1.30.0), binutils (>= 2.28-5), coreutils (>= 8.26-3), curl (>= 7.52.1-5), findutils (>= 4.6.0), git (>= 1:2.11.0-3), grep, lsof (>= 4.89), micro (>= 2.0.6-2) | nano (>= 2.7.4-1), proot (>= 5.1.0), procps (>= 2:3.3.12), sed, sudo (>= 1.8.19p1-2.1), tar (>= 1.29b-1.1),  util-linux (>= 2.29.2-1), whiptail (>= 0.52.19), xz-utils (>= 5.2.2), zstd (>= 1.1.2)${EXTRA_DEPS}
		Recommends: bat, busybox, debootstrap, eatmydata, gzip, less, lz4, pulseaudio, pv, qemu-user-static, systemd-container
		Suggests: lolcat, zsh
		Homepage: https://github.com/2moe/linux
		Tag: interface::TODO, interface::text-mode, system::cloud, system::virtual, role::program, works-with::archive, works-with::software:package, works-with::text
		Description: Easily manage containers and system. Just type "tmoe" to enjoy it.
	EndOfShow
}
#-----------------
get_uname_o() {
    case "$(uname -o)" in
    Android) OS=android ;;
    illumos) OS=illum ;;
    esac
}

get_uname() {
    # todo: pub const OS :&'static str = "redox";
    case "$(uname -s)" in
    Darwin) OS=mac ;;
    *Linux | *linux)
        OS=linux
        get_uname_o
        ;;
    SunOS)
        OS=sun
        get_uname_o
        ;;
    FreeBSD) OS=freebsd ;;
    NetBSD) OS=netbsd ;;
    DragonFly) OS=dragonfly ;;
    MINGW* | MSYS* | CYGWIN*) OS=win ;;
    esac
}

set_extra_deps() {
    case $OS in
    android) EXTRA_DEPS=", dialog, termux-api, termux-tools" ;;
    esac
}
#-----------------
pln() {
    printf "%s\n" "$@"
}
#-----------------
set_colour() {
    RED="$(printf '\033[31m')"
    GREEN="$(printf '\033[32m')"
    YELLOW="$(printf '\033[33m')"
    BLUE="$(printf '\033[34m')"
    PURPLE="$(printf '\033[35m')"
    CYAN="$(printf '\033[36m')"
    RESET="$(printf '\033[m')"
    BOLD="$(printf '\033[1m')"
}

set_path_and_url() {
    TMOE_MANAGER="share/old-version/share/app/manager"
    TMOE_URL="https://raw.githubusercontent.com/2moe/tmoe/master/${TMOE_MANAGER}"
    TMOE_URL_02="https://cdn.jsdelivr.net/gh/2moe/tmoe@master/${TMOE_MANAGER}"
    TMOE_GIT_DIR="${HOME}/.local/share/tmoe-linux/git"
    TMOE_GIT_DIR_02="/usr/local/etc/tmoe-linux/git"
    TEMP_FILE=".tmoe-linux.sh"
}

set_tmp_dir() {
    if [ -z "${TMPDIR}" ]; then
        for i in /tmp "${HOME}"; do
            if [ -e "${i}" ]; then
                TMPDIR="${i}/.cache"
                mkdir -p "${TMPDIR}"
                break
            fi
        done
    fi
}

set_env() {
    set_colour
    set_path_and_url
    set_tmp_dir
    unset EXTRA_DEPS MANAGER_FILE
}
#-----------------
do_you_want_to_continue() {
    pln \
        "${YELLOW}Do you want to ${BLUE}continue?${PURPLE}[Y/n]${RESET}" \
        "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET}, type ${YELLOW}n${RESET} to ${PURPLE}exit${RESET}." \
        "按${GREEN}回车键${BLUE}继续${RESET}，输${YELLOW}n${PURPLE}退出${RESET}"

    case "$OS" in
    linux | android) ;;
    *)
        pln \
            "${RED}Unfortunately, ${GREEN}tmoe ${PURPLE}does not support ${CYAN}your ${BLUE}${OS} OS${YELLOW} at this time${RESET}." \
            "Please press ${GREEN}Ctrl + C${RESET} to ${RED}abort${RESET}"
        ;;
    esac

    read -r opt
    case "$opt" in
    n* | N*)
        pln "${PURPLE}skipped${RESET}."
        exit 1
        ;;
    *) ;;
    esac
}
#-----------
# fn check_command(cmd_name: &str, sleep_time: u8, exit_code: u8)
check_command() {
    cmd_name=$1
    sleep_time=$2
    exit_code=$3
    if [ -z "$(command -v "$cmd_name")" ]; then
        pln \
            "${RED}${BOLD}ERROR" \
            "${CYAN}Please install ${GREEN}""$cmd_name""${RESET} first"

        sleep "$sleep_time"
        exit "$exit_code"
    fi
}

# fn curl_file(timeout: u8, url: &str) -> bool
curl_file() {
    timeout_u8=$1
    url_str=$2

    curl \
        --connect-timeout "$timeout_u8" \
        -Lvo \
        "${TEMP_FILE}" \
        "$url_str" ||
        false
}

download_temp_file() {
    check_command curl 2 127
    cd "${TMPDIR}" || exit 1

    # todo: Allows different architectures & systems to obtain different URLs.
    if (! curl_file 7 "${TMOE_URL}"); then
        pln \
            "${BLUE}Connection ${RED}timeout" \
            "${GREEN}Retrying${RESET} ..."

        curl_file 20 "${TMOE_URL_02}" ||
            pln \
                "${PURPLE}Unfortunately, ${CYAN}download ${RED}failed${RESET}." \
                "Please ${YELLOW}press ${GREEN}Ctrl+C ${PURPLE}to abort${RESET}"
    fi
}

exec_temp_file() {
    check_command bash 3 127
    [ ! -s .tmoe-linux.sh ] || bash .tmoe-linux.sh
}
#-----------
show_info_and_run_the_temp_file() {
    show_package_info
    do_you_want_to_continue
    download_temp_file
    exec_temp_file
}
check_manager_file() {
    unset MANAGER_FILE
    for i in "${TMOE_GIT_DIR}/${TMOE_MANAGER}" "${TMOE_GIT_DIR_02}/${TMOE_MANAGER}"; do
        if [ -s "${i}" ]; then
            MANAGER_FILE="${i}"
            break
        fi
    done
    case "${MANAGER_FILE}" in
    "") show_info_and_run_the_temp_file ;;
    *) bash "${MANAGER_FILE}" ;;
    esac
}
#----------------
main() {
    set_env
    check_manager_file
}
#----------------
main "${@}"
