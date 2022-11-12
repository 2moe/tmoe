#!/usr/bin/env sh
# This is a POSIX-compliant sh file which will actually download an awk file and run it.
# You can download that awk file directly without running this posix sh file.
# ---------------
#
# In POSIX.1-2017(IEEE Std 1003.1-2017) sh, `local`, `declare` & `typeset` are undefined.
# So, for compatibility, please do not use them to set local vars.
#
# ---------------
# Convert variable type from 8-bit unsigned integer to bool
# Perhaps it would be more appropriate to call it `as_bool()`
#
# Example
#
# ```sh
# a=0
#
# # note: In POSIX.1-2017-compliant sh, we couldn't do this: if ((a + 1 > 0)) { echo a > -1 }
# # But via bif() function, we can do like this:
# bif $((a + 1 > 0)) && {
#    pln "ok, a > -1"
# }
#
# bif $a && pln "This message is not printed as the data for a is converted to the bool value: false"
# ```
#
# bif(parameter_1: u8) -> bool
bif() {
    case $1 in
    0) false ;;
    [1-9] | [0-9][0-9] | [0-2][0-5][0-5]) true ;;
    *)
        warning "The value is not in the 8-bit unsigned integer type range." \
            "Acceptable values range from 0 to 255." \
            "You have passed in an invalid value and it will return false."
        false
        ;;
    esac
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
    # Priority: gawk > mawk > nawk > awk.
    # On some systems, awk -> busybox. Don't panic, `busybox awk` is also supported.
    # If `mawk` wasn't so problematic, then I would give it a higher priority. Because it runs faster.
    for i in gawk mawk nawk awk; do
        is_cmd_exists $i && {
            pln $i
            return 0
        }
    done

    panic "Error!" \
        "Name: get_awk_cmd()" \
        "Description: The awk command was not found." \
        "Note: oawk(1977) is unsupported!" \
        "Please consider using awk that is compatible with POSIX.1-2008 or later."
}
# ----------------
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

    # struct GitUri {
    #     base: string,
    #     repo: string,
    # }

    _uri_base_m="gi.tmoe.me"
    _uri_base_gh="raw.githubusercontent.com"
    _uri_base_ee="gitee.com"

    _git_repo_m="m/tmoe"
    _git_repo_gh="2moe/tmoe"
    _git_repo_ee="mo2/linux"

    _awk_file="2/2.awk"

    case $_uri_src in
    ee | gitee) pln "${_uri_protocol}${_uri_base_ee}/${_git_repo_ee}/raw/${_awk_file}" ;;
    m | moe | gitmoe) pln "${_uri_protocol}${_uri_base_m}/${_git_repo_m}/raw/branch/${_awk_file}" ;;
    gh | github | "") pln "${_uri_protocol}${_uri_base_gh}/${_git_repo_gh}/${_awk_file}" ;;
    *)
        panic "Error! Invalid arguments." \
            "Name: get_awk_uri()" \
            "Description: Takes a string and returns a uri (string)." \
            "Error analysis: Only the specified argument will be parsed."
        ;;
    esac
    unset _uri_src _uri_protocol _uri_base_ee _uri_base_m _uri_base_gh _git_repo_m _git_repo_gh _git_repo_ee _awk_file
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
warning() {
    pln "Warning!" "$@" >/dev/stderr
}
# ---------------
# Options: xdg or bsd
# get_tmoe_dir(_dir_src: string) -> string
get_tmoe_dir() {
    _dir_src=$1
    _xdg_data_home="${HOME}/.local/share"
    _bsd_cfg_dir="/usr/local/etc"
    _dir_name="tmoe-linux/git"

    case $_dir_src in
    xdg) pln "${_xdg_data_home}/${_dir_name}" ;;
    bsd) pln "${_bsd_cfg_dir}/${_dir_name}" ;;
    esac

    unset _dir_src _xdg_data_home _bsd_cfg_dir _dir_name
}
# ---------------
# If the old-manger-file is found, it will skip running the awk file.
# Note: this function will need to be removed after the new edition is released.
#
# run_old_file() -> int
run_old_file() {
    _cmd="bash"
    is_cmd_exists "$_cmd" || return 1

    _tmoe_old_manager="share/old-version/share/app/manager"

    for i in xdg bsd; do
        _tmoe_dir=$(get_tmoe_dir $i)
        _tmoe_old_file="$_tmoe_dir/$_tmoe_old_manager"
        # if the old file exists, run it.
        [ -s "$_tmoe_old_file" ] && {
            "$_cmd" "$_tmoe_old_file"
            return 0
        }
    done

    unset _tmoe_old_manager _tmoe_dir _tmoe_old_file
    return 1
}
# ---------------
# Get temporary file: "dir/name"
get_temp_file() {
    # If `mktemp` exists => Use mktemp to generate the temporary file.
    is_cmd_exists mktemp && {
        mktemp && return 0
    }

    # `TMPDIR` from the environment variable
    for i in "${TMPDIR}" /tmp "${HOME}"; do
        [ -d "$i" ] && {
            _tmp_dir="$i/.cache/tmp"
            break
        }
    done

    mkdir -p "$_tmp_dir"
    pln "$_tmp_dir/.tmoe-old.sh"
    unset _tmp_dir
}
# ---------------
# If the cmd exists -> 0
# Otherwise -> 1
#
# [[Arg, Usage]; [cmd_name, "(is_cmd_exists awk) && pln 'awk exists'"]]
#
# ╭───┬──────────┬────────────────────────────────────────╮
# │ # │   Arg    │                 Usage                  │
# ├───┼──────────┼────────────────────────────────────────┤
# │ 0 │ cmd_name │ is_cmd_exists awk && pln 'awk exists'  │
# ╰───┴──────────┴────────────────────────────────────────╯
#
# is_cmd_exists(_cmd_name: string) -> int
is_cmd_exists() {
    _cmd_name=$1

    (command -v "$_cmd_name" >/dev/null) && return 0
    return 1
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
    pln "$_tmp_uri"

    wget \
        --timeout="$_connect_timeout" \
        "$_tmp_uri" \
        -O "$_tmp_awk_file" || return 1
}
# ---------------
# Get(Download) the awk file
get_awk_file() {
    for _dler in wget curl; do
        is_cmd_exists "$_dler" && {
            # if connect_timeout > 10:
            (! "dl_file_with_$_dler" 10 "$_tmp_awk_uri") && {
                # fallback to another uri
                # connect_timeout: 20
                for i in gh ee m; do
                    ("dl_file_with_$_dler" 20 "$(get_awk_uri $i)") && break
                done
            }
            break
        }
    done
    unset _dler
}
# ---------------
# If the awk file <= 4KiB after downloading, then the download may have failed.
check_file_size_with_stat() {
    _awk_file_size=$(eval "$_stat_cmd")
}

check_file_size() {
    _stat_cmd="stat -c %s \"$_tmp_awk_file\""

    # If the `stat` command is not available, then skip the following process.
    is_cmd_exists stat || return 1

    eval "$_stat_cmd" || {
        pln "Syntax error, skip the file size detection."
        return 1
    }

    check_file_size_with_stat
    # if awk_file_size > 4096 -> 0
    bif $((_awk_file_size > 4096)) && {
        unset _awk_file_size
        return 0
    }

    pln "file-size: $_awk_file_size" \
        "Unfortunately, the file is less than or equal to 4 KiB." \
        "This means that the download may have failed." \
        "Trying again..."
    dl_file_with_curl 30 "$(get_awk_uri m)"

    # check again
    check_file_size_with_stat
    pln "new-size: $_awk_file_size"
    bif $((_awk_file_size <= 4096)) && {
        panic "Error! The file size is much smaller than the source file." \
            "Name: check_file_size()" \
            "Description: The download may have failed, this file may be broken." \
            "You are unable to continue with the operation." \
            "If this is not related to the file system's compression mechanism, you are welcome to report the bug."
    }
}
# ----------------
run_awk_program() {
    _awk_cmd=$(get_awk_cmd)
    "$_awk_cmd" -f "$_tmp_awk_file"
}
# ----------------
main() {
    run_old_file || {
        _tmp_awk_file=$(get_temp_file)
        _tmp_awk_uri=$(get_awk_uri ee)
        get_awk_file
        check_file_size
        run_awk_program
    }
}
#----------------
main "${@}"
