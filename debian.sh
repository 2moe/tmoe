#!/usr/bin/env sh
# This is a posix sh file which will actually download an awk file and run it.
# You can download that awk file directly without running this posix sh file.
# ---------------
#
# Older versions of posix sh do not support setting local variables with `local`.
# So, for compatibility, please do not use `local`
#
# ---------------
# Get the uri of the awk file. You have to specify the source.
# Options: ee, m or gh
#
# Example
#
# ```sh
#   URI=$(get_awk_uri gh)
#
#   curl -v $URI
# ```
#
# get_awk_uri(_uri_src: string) -> string
get_awk_uri() {
    _uri_src=$1
    _uri_protocol="https://"
    _uri_gitee_base="gitee.com"
    _uri_gitmoe_base="gi.tmoe.me"
    _uri_gh_raw="raw.githubusercontent.com"
    _gitmoe_repo="m/tmoe"
    _gh_repo="2moe/tmoe"
    _gitee_repo="mo2/linux"
    _awk_file="2/2.awk"

    case $_uri_src in
    ee | gitee) pln "${_uri_protocol}${_uri_gitee_base}/${_gitee_repo}/raw/${_awk_file}" ;;
    m | moe | gitmoe) pln "${_uri_protocol}${_uri_gitmoe_base}/${_gitmoe_repo}/raw/branch/${_awk_file}" ;;
    gh | github | "") pln "${_uri_protocol}${_uri_gh_raw}/${_gh_repo}/${_awk_file}" ;;
    *) 
        panic "Error! Invalid arguments." \
            "Name: get_awk_uri()" \
            "Description: Takes a string and returns a uri (string)." \
            "Error analysis: Only the specified argument will be parsed."
            ;;
    esac
    unset _uri_src _uri_protocol _uri_gitee_base _uri_gitmoe_base _uri_gh_raw _gitmoe_repo _gh_repo _gitee_repo _awk_file
}
# ---------------
pln() {
    printf "%s\n" "$@"
}
# ---------------
# If the program has a non-recoverable error, a panic will occur and the error message will be output to stderr.
# After printing the error message, the program will exit abnormally.
#
# Example
# 
#```sh
#    panic "msg1" "msg2" "msg3"
#```
#
panic() {
    pln "$@" >/dev/stderr
    exit 1
}
# ---------------
# Options: xdg or bsd
# get_tmoe_dir(_dir_src: string) -> string 
get_tmoe_dir() {
    _dir_src=$1
    _xdg_data_home="${HOME}/.local/share"
    _bsd_cfg_dir="/usr/local/etc"
    _tmoe_dir_name="tmoe-linux/git"

    case $_dir_src in
    xdg) pln "${_xdg_data_home}/${_tmoe_dir_name}" ;;
    bsd) pln "${_bsd_cfg_dir}/${_tmoe_dir_name}" ;;
    esac
    unset _dir_src _xdg_data_home _bsd_cfg_dir _tmoe_dir_name
}
# ---------------
# If an older edition of the file is found, it will skip running the awk file.
# Note: this function will need to be removed after the new edition is released.
#
# run_old_file() -> int
run_old_file() {
    (is_cmd_exists bash) || return 1

    _tmoe_old_manager="share/old-version/share/app/manager"

    for i in xdg bsd; do
        _tmoe_dir=$(get_tmoe_dir $i)
        _tmoe_old_file="$_tmoe_dir/$_tmoe_old_manager"
        if [ -s "$_tmoe_old_file" ]; then
            bash "$_tmoe_old_file"
            return 0
        fi
    done

    unset _tmoe_old_manager _tmoe_dir _tmoe_old_file
    return 1
}
# ---------------
# Get temporary dir & file name
# 
get_temp_file() {
    # If `mktemp` exists => Use mktemp to generate the temporary file.
    (is_cmd_exists mktemp) && mktemp && return 0

    # `TMPDIR` from the environment variable
    for i in "${TMPDIR}" /tmp "${HOME}"; do
        [ -d "$i" ] && _tmp_dir="$i/.cache" && break
    done

    mkdir -p "$_tmp_dir"
    pln "$_tmp_dir/.tmoe-old.sh"
    unset _tmp_dir
}
# ---------------
# If the cmd exists -> 0
# Otherwise -> 1
#
# [[Arg, Usage]; [cmd_name, "(is_cmd_exists seq)&& pln 'seq exists'"]]
#
# ╭───┬──────────┬────────────────────────────────────────╮
# │ # │   Arg    │                 Usage                  │
# ├───┼──────────┼────────────────────────────────────────┤
# │ 0 │ cmd_name │ (is_cmd_exists seq)&& pln 'seq exists' │
# ╰───┴──────────┴────────────────────────────────────────╯
#
# is_cmd_exists(_cmd_name: string) -> int
is_cmd_exists() {
    _cmd_name=$1

    (command -v "$_cmd_name" >/dev/null) && return 0
    return 1
}
# ----------------
# ╭───┬──────╮
# │ # │ awk  │
# ├───┼──────┤
# │ 0 │ gawk │
# │ 1 │ mawk │
# │ 2 │ nawk │
# ╰───┴──────╯
#
get_awk_cmd() {
    # Priority: gawk > mawk > nawk
    # If `mawk` wasn't so problematic, then I would give it a higher priority. Because it runs faster.
    for i in gawk mawk nawk; do
        (is_cmd_exists $i) && pln $i && return 0
    done

    pln awk
}
# ----------------
# dl_file_with_curl(_connect_timeout: int, _tmp_uri: string) -> int
dl_file_with_curl() {
    _connect_timeout=$1
    _tmp_uri=$2

    pln "$_tmp_uri" "$_tmp_awk_file"

    curl \
        --connect-timeout "$_connect_timeout" \
        --compressed \
        -L \
        "$_tmp_uri" \
        -o "$_tmp_awk_file" || return 1
}
# ---------------
dl_file_with_wget() {
    _connect_timeout=$1
    _tmp_uri=$2
    # pln "$_tmp_uri" "$_tmp_awk_file"
    pln "$_tmp_awk_file"
    
    wget \
        --timeout="$_connect_timeout" \
        "$_tmp_uri" \
        -O "$_tmp_awk_file" || return 1
}
# ---------------
# Get(Download) the awk file
get_awk_file() {
    for _dler in wget curl; do
        if (is_cmd_exists $_dler); then
            if (! "dl_file_with_$_dler" 10 "$_tmp_awk_uri"); then
                for i in gh ee m; do
                    ("dl_file_with_$_dler" 20 "$(get_awk_uri $i)") && break
                done
            else
                break
            fi
        fi
    done
}
# ---------------
# If the awk file <= 4KiB after downloading, then the download may have failed.
check_file_size_with_stat() {
    _awk_file_size=$(stat --format=%s "$_tmp_awk_file")
}
check_file_size() {
    (is_cmd_exists stat) || return 1

    check_file_size_with_stat
    # For POSIX sh compatibility, use `[]` instead of `(())`
    if [ "$_awk_file_size" -le 4096 ]; then
        pln "file-size: $_awk_file_size"
        pln "Unfortunately, the file is less than or equal to 4 KiB." \
            "This means that the download may have failed." \
            "Trying again..."
        dl_file_with_curl 30 "$(get_awk_uri m)"
    else
        unset _awk_file_size
        return 0
    fi

    # check again
    check_file_size_with_stat
    pln "new-size: $_awk_file_size"
    [ "$_awk_file_size" -le 4096 ] && panic "You are unable to continue with the operation and are welcome to report an issue."
}
# ----------------
run_awk_program() {
    _awk_cmd=$(get_awk_cmd)
    "$_awk_cmd" -f "$_tmp_awk_file"
}
# ----------------
main() {
    if (! run_old_file); then
        _tmp_awk_file=$(get_temp_file)
        _tmp_awk_uri=$(get_awk_uri gh)
        get_awk_file
        check_file_size
        run_awk_program
    fi
}
#----------------
main "${@}"
