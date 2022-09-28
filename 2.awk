#!/usr/bin/env -S awk -f
# POSIX awk
# -----------
# About awk distribution:
# [[Name, Compatible]; [oawk, "x ?"] [mawk, ✓] ["gawk(gnu awk)", ✓] [nawk, "✓ ?"] ["busybox awk", ✓]]
#
# ╭───┬───────────────┬────────────╮
# │ # │     Name      │ Compatible │
# ├───┼───────────────┼────────────┤
# │ 0 │ oawk          │ x ?        │
# │ 1 │ mawk          │ ✓          │
# │ 2 │ gawk(gnu awk) │ ✓          │
# │ 3 │ nawk          │ ✓ ?        │
# │ 4 │ busybox awk   │ ✓          │
# ╰───┴───────────────┴────────────╯
#
# On some systems, awk refers to oawk(1977).
# In fact, awk in the 1980s was very different from the 1970s.
# In this case, you should call (mawk, nawk, gawk or busybox awk) manually, e.g. nawk -f this-file.awk
# Or you can modify the shebang(line: 1)
#
# For compatibility, no gawk extensions have been introduced here.
#
# Although it is tested with mawk(1.3.4 20200120), theoretically any awk compatible with the new POSIX will work.
# Unfortunately, this version of mawk has some bugs.
# Even busybox awk doesn't have those bugs.
# Fortunately, you can still run it.
#
# Due to the special local variable declaration syntax of awk, if you find "_," in the declaration of a function, then don't panic.
# After this, the parameters(variables) are local.
# If the norm is followed, it should not be "_", but some spaces.
# -----------
function main() {
    set_const()
    get_system_info()
    add_repo()
    run_old_edition()
}
# -----------
#[test]
function test() {
    set_const()
    # test_cmd_exists()
    # test_check_cmd()
    # test_alice_s_fruit()
    test_file_existence()
}
# -----------
# Get system information.
#
# In this world, there exist are many operating systems.
# For example:
# [[OS]; ["Microsoft Windows"], ["Apple MacOS"], ["Linux distros"], ["*BSD$"], ["Redox"]]
#
# Q: Windows?
#    Are you serious?
# A: Yes, windows can also run awk.
#    As windows 8.1/10/11(22000.856) do not have `awk` pre-installed, it may be better to use other methods.
#
# Note: windows and mac are not supported at this time.
# But maybe one day I'll get it to support mac.
#
# ╭───┬───────────────╮
# │ # │      OS       │
# ├───┼───────────────┤
# │ 0 │ Windows       │
# │ 1 │ MacOS         │
# │ 2 │ Linux distros │
# │ 3 │ *BSD$         │
# │ 4 │ Redox         │
# ╰───┴───────────────╯
#
function get_system_info() {
    uname_cmd = check_uname_cmd()

    kernel_name = get_cmd_out(uname_cmd ",-s")

    # get os name and set OS["name"], OS["family"], etc.
    get_os_name(uname_cmd, kernel_name)

    # set I18N["lang"], I18N["region"], etc.
    get_os_language()

    # set ARCH["deb"] and ARCH["llvm"]
    # To be honest, there is little use in getting the architecture before the edition 2022 is completed.
    # There is always a need to look ahead and there is nothing wrong with being prepared in advance.
    get_architecture(uname_cmd)
}
# -----------
function check_uname_cmd(_, uname_cmd) {
    uname_cmd = (check_cmd("uname"))? "uname":      (check_cmd("busybox", "uname,-s"))? "busybox uname": NONE

    # [[OS, pkg]; ["Debian GNU/Linux", coreutils] [Windows, busybox]] 
    if (is_empty(uname_cmd)) {

        print sty["cyan"]
        print "╭───┬──────────────────┬───────────╮" 
        print "│ # │       OS         │    pkg    │" 
        print "├───┼──────────────────┼───────────┤" 
        print "│ 0 │ Debian GNU/Linux │ coreutils │" 
        print "│ 1 │ Windows          │ busybox   │" 
        print "╰───┴──────────────────┴───────────╯" sty[0]


        print sty["green"] "`uname`", sty["yellow"] "is used to detect kernel information.\n",
        sty["blue"] "For Linux distros such as", sty["magenta"] "Debian GNU/Linux" sty[0] ",", sty["cyan"] "you can install", sty["green"] "`coreutils`.\n",
        sty["yellow"] "For", sty["blue"] "Windows" sty[0] ",", sty["cyan"] "you can use", sty["green"] "busybox.\n" sty[0]
        exit 127
    }

    return uname_cmd
}
# -----------
# Get OS name
#
# Example
#
# ```awk
#     uu = "uname"
#     
#     kernel = get_cmd_out(uu ",-s")
#     get_os_name(uu, kernel)
#
#     print OS["name"], OS["family"]
# ```
#
function get_os_name(uname_cmd, kernel_name, _, k, os_name) {
#  [[OS, "uname -a"]; ["Windows", "Windows_NT MOE 10.0 22000 x86_64 MS/Windows"] ["Debian GNU/Linux", "Linux nuc 5.18.0-3-amd64 #1 SMP PREEMPT_DYNAMIC Debian 5.18.14-1 (2022-07-23) x86_64 GNU/Linux"]]
#
# ╭───┬──────────────────┬────────────────────────────────────╮
# │ # │        OS        │              uname -a              │
# ├───┼──────────────────┼────────────────────────────────────┤
# │ 0 │ Windows          │ Windows_NT MOE 10.0 22000 x86_64   │
# │   │                  │ MS/Windows                         │
# │ 1 │ Debian GNU/Linux │ Linux nuc 5.18.0-3-amd64 #1 SMP    │
# │   │                  │ PREEMPT_DYNAMIC Debian 5.18.14-1   │
# │   │                  │ (2022-07-23) x86_64 GNU/Linux      │
# ╰───┴──────────────────┴────────────────────────────────────╯
#
# [[OS,"Kernel Name"]; [linux, Linux] [mac, Darwin] [win, "Windows_NT|MINGW.*|MSYS.*|CYGWIN.*"] [freebsd, FreeBSD] [netbsd, NetBSD] [dragonfly, DragonFly] [sunos, SunOS]]
#
# ╭───┬───────────┬────────────────────────────────────╮
# │ # │    OS     │            Kernel Name             │
# ├───┼───────────┼────────────────────────────────────┤
# │ 0 │ linux     │ Linux                              │
# │ 1 │ mac       │ Darwin                             │
# │ 2 │ win       │ Windows_NT|MINGW.*|MSYS.*|CYGWIN.* │
# │ 3 │ freebsd   │ FreeBSD                            │
# │ 4 │ netbsd    │ NetBSD                             │
# │ 5 │ dragonfly │ DragonFly                          │
# │ 6 │ sunos     │ SunOS                              │
# ╰───┴───────────┴────────────────────────────────────╯
#
    # to lower case
    k = tolower(kernel_name)

    # os_name = (k ~ /linux/)?
    #         "linux":
    # (k ~ /darwin/)?
    #         "mac":
    # (k ~ /windows_nt|cygwin|m(ingw|sys)/)?
    #         "win":
    # (k ~ /dragonfly|(net|free)bsd|sunos/)?
    #         k:
    #     NONE
    # Warning: mawk(1.3.4 20200120) uses the above statement with a "syntax error at or near :", but busybox awk does not.
    # It needs to be combined into one line.

    if (k ~ /linux/)
        os_name = "linux"
    else if (k ~ /darwin/)
        os_name = "mac"
    else if (k ~ /windows_nt|cygwin|m(ingw|sys)/)
        os_name = "win"
    else if (k ~ /dragonfly|(net|free)bsd|sunos/)
        os_name = k
    
    if (is_empty(os_name)) {
        print sty["red"] "Unfortunately,", sty["yellow"] "it does", sty["magenta"] "not support", sty["blue"] "your system.", "\n",
        sty["cyan"] "kernel name:", sty["green"] kernel_name, "\n",
        sty["blue"] "Welcome to report this issue" sty[0]

        exit 1
    }

    # OS["family"] = "ubuntu"
    # OS["family2"] = "debian"
    # OS["env"] = gnu / musl

    OS["target-family"] = (os_name == "win")? "windows": "unix"
    
    OS["kernel"] = kernel_name
    OS["name"] = OS["family0"] = os_name
    parse_os_name(uname_cmd, os_name, OS)

    #[test]
    # for (i in OS)
    #     print "debug::get_os_name, key:", i, "v:", OS[i]
}
# -----------
# parse_os_name(os_name: string, os: array)
function parse_os_name(uname_cmd, os_name, os, _, os_lower, release, release_file) {
    # TODO: set OS["version"] & OS["code"]
    # debian: OS["version"] = 12, OS["code"] = "bookworm"
    # windows: OS["version"] = 11, OS["full_version"] = "22000.856"

    if (os_name ~ /sunos|linux/) {
        release_file = "/etc/os-release"
        os_lower = tolower(get_cmd_out(uname_cmd ",-o"))

        os["name"] = (os_lower == "android")? "android":    (os_lower == "illumos")? "illum": os_name
    }

    if (os_name == "linux" && is_file_exists(release_file)) {
        collect_to_arr(release_file, "=", release)
        #[test]
        # for (i in release)
        #     print "k:", i, "v:", release[i]
        # print dequotes(release["PRETTY_NAME"])

        if ("ID" in release)
            os["name"] = os["family"] = dequotes(release["ID"])
        # [["OS", ID_LIKE]; [kali, debian] [mint, ubuntu] [lmde, debian]]
        #
        # ╭───┬──────┬─────────╮
        # │ # │  OS  │ ID_LIKE │
        # ├───┼──────┼─────────┤
        # │ 0 │ kali │ debian  │
        # │ 1 │ mint │ ubuntu  │
        # │ 2 │ lmde │ debian  │
        # ╰───┴──────┴─────────╯
        #
        if ("ID_LIKE" in release)
            os["family2"] = dequotes(release["ID_LIKE"])
    }
}
# -----------
# Please do not declare `lang` local variables in this function
# It comes from the user passed in `-v lang=xx-yy`
#
function get_os_language(_, cmd, full, language) {
    cmd = "getprop"

    # Default locale: en_us
    I18N["lang"] = "en"
    I18N["region"] = "us"

    # `lang` from user incoming data
    # awk -f a.awk -v lang=en_us
    if (!is_empty(lang) && lang ~ /[_-]/)
        full = lang
    else if (OS["name"] == "android" && check_cmd(cmd))
        full = get_cmd_out(cmd ",persist.sys.locale")
    else if (OS["name"] == "win")
        full = get_cmd_out("powershell,-NoProfile,'Get-UICulture|select -ExpandProperty Name'")
    else
        full = ENVIRON["LANG"]

    language = trim(tolower(full))

    if (!is_empty(language))
        parse_os_language(language, I18N)
    
    #[test]
    # key: lang v: en
    # key: region v: us
    # key: encoding v: utf-8
    # a.awk -v lang=zh-cmn_hans_cn.utf-8
    # key: script     v: hans
    # key: ext        v: cmn
    # key: lang       v: zh
    # key: region     v: cn
    # key: encoding   v: utf-8
    #
    # for (i in I18N) {
    #     # print "debug::get_os_language",
    #     print "key:", i, "\tv:", I18N[i]
    # }
}
# -----------
# 
# [[src, result]; ["en_us.utf-8", 'lang: en, region: us, encoding: utf-8'],  ["en_us", 'lang: en, region: us'], ["en-US", 'lang: en, region: us'], ["zh-Hans-CN", 'lang: zh, script: hans, region: cn'] ["zh-yue-Hant_hk", 'lang: zh, ext: yue, script: hant, region: hk']]
#
# ╭───┬────────────────┬──────────────────────────────────────────────╮
# │ # │      src       │                    result                    │
# ├───┼────────────────┼──────────────────────────────────────────────┤
# │ 0 │ en_us.utf-8    │ lang: en, region: us, encoding: utf-8        │
# │ 1 │ en_us          │ lang: en, region: us                         │
# │ 2 │ en-US          │ lang: en, region: us                         │
# │ 3 │ zh-Hans-CN     │ lang: zh, script: hans, region: cn           │
# │ 4 │ zh-yue-Hant_hk │ lang: zh, ext: yue, script: hant, region: hk │
# ╰───┴────────────────┴──────────────────────────────────────────────╯
#
# parse_os_language(lang: string, i18n: array)
function parse_os_language(lang, i18n, _, lang_arr1, lang_arr1_len, lang_arr2, lang_arr2_len, lang_spec, v) {
    lang_arr1_len = split(lang, lang_arr1, ".")

    if (lang_arr1_len == 2)
        i18n["encoding"] = lang_arr1[2]

    lang_arr2_len = split(lang_arr1[1], lang_arr2, /[_-]/)
    
    i18n["lang"] = lang_arr2[1]

    # language-extlang-script-region-variant-extension-privateuse
    # [[Type, Construction, Standard]; [language, "(2 or 3) alpha[a-z]", "ISO639-[1,2,3,5]"], [extlang, "3 alpha", ISO639-3], [script, "4 alpha[A-Z]{1}[a-z]{3}", ISO15924], [region, "2 alpha[A-Z] or 3 digit", "ISO3166-1_alpha-2 or UNM.49"], [variant, "([5-8] alphanum) or (1 digit  3 alphanum)", "IANA language subtag registry?"]]
    # https://www.rfc-editor.org/info/bcp47
    # https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
#
# ╭───┬──────────┬──────────────────────────┬─────────────────────────╮
# │ # │   Type   │       Construction       │        Standard         │
# ├───┼──────────┼──────────────────────────┼─────────────────────────┤
# │ 0 │ language │ (2 or 3) alpha           │ ISO639-[1,2,3,5]        │
# │ 1 │ extlang  │ 3 alpha                  │ ISO639-3                │
# │ 2 │ script   │ 4 alpha                  │ ISO15924                │
# │ 3 │ region   │ 2 alpha or 3 digit       │ ISO3166-1_alpha-2 or    │
# │   │          │                          │ UNM.49                  │
# │ 4 │ variant  │ ([5-8] alphanum) or (1   │ IANA language subtag    │
# │   │          │ digit  3 alphanum)       │ registry?               │
# ╰───┴──────────┴──────────────────────────┴─────────────────────────╯

    # Language specification array
    split("lang,ext,script,region,variant,extension,privateuse", lang_spec, ",")

    # Note: Only the first 4 types are parsed. Since the first one is always lang, only [ext, script, region] are parsed next.
    # The hashmap or array of region code(UNM.49) is not defined in this awk program, so it does not automatically convert "UNM.49" to "ISO3166-1_alpha-2"

    for (i = 2; i <= lang_arr2_len; ++i) {
        v = lang_arr2[i]
        is_i18n_extlang(v, i18n) || is_i18n_script(v, i18n) || is_i18n_region(v, i18n)
    }

    # Do not use `(! "script" in i18n)` 
    if (("region" in i18n) && (i18n["lang"] == "zh") && (is_empty(i18n["script"])))
        i18n["script"] = (i18n["region"] ~ /cn|sg|my/)? "hans": "hant"
}
# -----------
# Warning: mawk (1.3.4 20200120) uses such regular expression (/[0-9a-z]{5,8}/) with error 

function is_i18n_region(two_a_or_3d, a_map) {
    # [a-z]{2} | [0-9]{3}
    if (two_a_or_3d ~ /^[a-z][a-z]$|^[0-9][0-9][0-9]$/){
        a_map["region"] = two_a_or_3d
        return true
    }
    return false
}
function is_i18n_script(four_a, a_map){
    # [a-z]{4}
    if (four_a ~ /^[a-z][a-z][a-z][a-z]$/){
        a_map["script"] = four_a
        return true
    }
    return false
}
function is_i18n_extlang(three_a, a_map){
    # [a-z]{3}
    if (three_a ~ /^[a-z][a-z][a-z]$/){
        a_map["ext"] = three_a
        return true
    }
    return false
}
# -----------
function add_repo(_, gpgv_version) {
    if ((OS["family2"] ~ /debian|ubuntu/ || OS["family" == "debian"]) && check_cmd("gpgv")) {
        # [[sysver, "gpgv version"]; [bionic, "2.2.4-1ubuntu1.6"] [buster, "2.2.12-1+deb10u2"]]
        #
        # ╭───┬────────┬──────────────────╮
        # │ # │ sysver │   gpgv version   │
        # ├───┼────────┼──────────────────┤
        # │ 0 │ bionic │ 2.2.4-1ubuntu1.6 │
        # │ 1 │ buster │ 2.2.12-1+deb10u2 │
        # ╰───┴────────┴──────────────────╯
        #
        gpgv_version = parse_cmd_out("dpkg-query,-s,gpgv", "^Version", ":" SPACE)
        if (semver_comparator(gpgv_version, "<", "2.0.0")) {
            # TODO: if I18N["lang"] == "zh", then print Chinese
            print sty["cyan"] "gpgv version :", sty["green"] gpgv_version,
            sty["red"] "\nSorry,", sty["blue"] "the gpgv version is lower than", sty["yellow"] "2.0",
            sty["cyan"] "\nSupport for", sty["underline"] sty["yellow"] "Curve25519/Ed25519",sty["not underlined"] sty["magenta"] "may not be perfect" sty[0] "\n"

            print "Warning! Your system will not be able to add the related repo" > STDERR
        }
    }

    # TODO: download deb file and install pkg
    # [[Step, Command]; ["download deb", "curl -LO https://l.tmoe.me/neko.deb"] ["install deb as root", "sudo apt install ./neko.deb"] ["update index", "sudo apt update"] ["install tmm", "sudo apt install tmm"]]
#
# ╭───┬─────────────────────┬─────────────────────────────────────╮
# │ # │        Step         │               Command               │
# ├───┼─────────────────────┼─────────────────────────────────────┤
# │ 0 │ download deb        │ curl -LO https://l.tmoe.me/neko.deb │
# │ 1 │ install deb as root │ sudo apt install ./neko.deb         │
# │ 2 │ update  index       │ sudo apt update                     │
# ╰───┴─────────────────────┴─────────────────────────────────────╯

}
# -----------
# Comparison of version numbers.
#
# Example

# ```awk
#     a = "1.10.0"
#     b = "1.9.2"
#     op = ">"
#     aa = semver_comparator(a, op, b)

#     print_bool(aa)
#     # stdout: true

#     bb = semver_comparator("1.5.12-alpha.2", "<", "1.5.12-beta.1")
#     if (bb)
#         print "1.5.12-alpha.2 is lower than 1.5.12-beta.1"
# ```
# semver_comparator(lhs: string, op: string, rhs: string) -> bool
function semver_comparator(lhs, op, rhs, _, m_arr, m_arr_len, arr_len, n_arr, n_arr_len, i) {
    m_arr_len = split(lhs , m_arr, "[-.]")
    n_arr_len = split(rhs, n_arr, "[-.]")
    arr_len = (m_arr_len > n_arr_len)? m_arr_len: n_arr_len

    for (i = 1; i <= arr_len; ++i) {

        m_arr["op"] = (m_arr[i] > n_arr[i])? ">": (m_arr[i] < n_arr[i])? "<": "="

        if (m_arr["op"] != "=")
            break
    }

    op_clone = op
    sub("=", NONE, op_clone)

    #[test]
    # print a_arr["op"], op, op_clone
    return (op == m_arr["op"])? true: (op_clone == m_arr["op"])? true: false
}
# -----------
function set_git_uri(git, uri, _, a_map, opt) {
    git["hub"] = "2moe/tmoe"
    git["ee"] = "mo2/linux"
    git["branch"] = "master"
    git["manager_file"] = "share/old-version/share/app/manager"

    uri["branch"] = git["branch"] "/"
    uri["protocol"] = "https://"

    uri["ee_base"] = "gitee.com/"
    uri["ee_raw"] = "/raw/"

    uri["gh_raw"] = "raw.githubusercontent.com/"
    uri["js_gh_base"] = "gcore.jsdelivr.net/gh/"

    uri["gitee"] = uri["protocol"] uri["ee_base"] git["ee"] uri["ee_raw"] uri["branch"] git["manager_file"]

    uri["github"] = uri["protocol"] uri["gh_raw"] git["hub"] "/" uri["branch"] git["manager_file"]

    uri["jscdn"] = uri["protocol"] uri["js_gh_base"] git["hub"] "@" uri["branch"] git["manager_file"]

    y_n = coloured_y_n(true)

    # mawk -f ./a.awk -v net_node=gh => net_node 
    if (is_empty(net_node)) {
        # print I18N["region"]
        print sty["_"] "gitee" sty["/_"] " or " sty["_"] "github" sty["/_"] ":"
        if (I18N["region"] ~ /cn|tw|hk|mo/) {
                a_map["ext", "zh"] = "script"
                a_map["fallback", "zh"] = "hans"
                a_map["choose_gitee", "zh" "hans"] = "直接按回车键选择 gitee"
                a_map["choose_gitee", "zh" "hant"] = "直接按回車鍵選擇 gitee"

                a_map["choose_github", "zh" "hans"] = "输入n 再按回车选择 github"
                a_map["choose_github", "zh" "hant"] = "輸入n 再按回車選擇 github"
            # get_i18n("choose_gitee", a_map)

            # ╭───┬───────┬────────┬───────────────────────────╮
            # │ # │ Opt   │  Src   │      Description          │
            # ├───┼───────┼────────┼───────────────────────────┤
            # │ 0 │ y     │ gitee  │ 直接按回車鍵選擇 gitee    │
            # │ 1 │ n     │ github │ 輸入n 再按回車選擇 github │
            # ╰───┴───────┴────────┴───────────────────────────╯
            # 地區: hk/mo/tw
            # 是否從 gitee 獲取相關檔案? [Y/n]

            # ╭───┬───────┬────────┬───────────────────────────╮
            # │ # │ Opt   │  Src   │      Description          │
            # ├───┼───────┼────────┼───────────────────────────┤
            # │ 0 │ y     │ gitee  │ 直接按回车键选择 gitee    │
            # │ 1 │ n     │ github │ 输入n 再按回车选择 github │
            # ╰───┴───────┴────────┴───────────────────────────╯

            # 地区: cn
            # 是否从 gitee 获取相关文件? [Y/n]

            print sty["cyan"] "╭───┬" sty["blue"]    "──────" sty ["cyan"]    "─┬─" sty["cyan"]    "──────" sty["cyan"] "─┬" sty["yellow"]   "───────────────────────────" sty["yellow"]   "╮"
            print sty["cyan"] "│ # │" sty["blue"]    " Opt  " sty ["cyan"]    " │ " sty["cyan"]    " Src  " sty["cyan"] " │" sty["yellow"]     "      Description          " sty["yellow"]   "│"
            print sty["cyan"] "├───┼" sty["blue"]    "──────" sty ["cyan"]    "─┼─" sty["cyan"]    "──────" sty["cyan"] "─┼" sty["yellow"]   "───────────────────────────" sty["yellow"]   "┤"
            print sty["cyan"] "│ 0 │" sty["green"]   " y    " sty ["cyan"]    " │ " sty["green"]   "gitee " sty["cyan"] " │" sty["green"]    " "get_i18n("choose_gitee", a_map)"    " sty["yellow"]   "│"
            print sty["cyan"] "│ 1 │" sty["magenta"] " n    " sty ["cyan"]    " │ " sty["magenta"] "github" sty["cyan"] " │" sty["magenta"]  " "get_i18n("choose_github", a_map)" " sty["yellow"]   "│"
            print sty["cyan"] "╰───┴" sty["blue"]    "──────" sty ["cyan"]    "─┴─" sty["cyan"]    "──────" sty["cyan"] "─┴" sty["yellow"]   "───────────────────────────" sty["yellow"]   "╯"
            print sty[0]

            a_map["region", "zh" "hans"] = "地区"
            a_map["region", "zh" "hant"] = "地區"

            a_map["from", "zh" "hans"] = "是否从"
            a_map["from", "zh" "hant"] = "是否從"

            a_map["get_file", "zh" "hans"] = "获取相关文件"
            a_map["get_file", "zh" "hant"] = "獲取相關檔案"

            # print get_i18n("region", a_map)

            print sty["yl"] get_i18n("region", a_map) ": " sty["b"] sty["green"] I18N["region"] sty["/b"]

            print sty["bu"] get_i18n("from", a_map) SPACE sty["u"] sty["cyan"] "gitee" sty[0]  sty["yellow"] SPACE get_i18n("get_file", a_map) sty["default"] "?", y_n
            
            print sty["bu"] "Do you want to" sty["yl"] " get it" sty["bu"] " from " sty["u"] sty["cyan"]"gitee" sty[0] "?", y_n
            opt = tolower(read_to_string(STDIN))
            uri["current"] = (opt ~ /^n/)? uri["github"]: uri["gitee"]
        } else {
            # [[Input, Src, Description]; ["y", github, "Press Enter or type y to choose github"] ["n", gitee, "Type n to choose gitee"]]
            # ╭───┬───────┬────────┬────────────────────────────────────────╮
            # │ # │ Opt   │  Src   │              Description               │
            # ├───┼───────┼────────┼────────────────────────────────────────┤
            # │ 0 │ y     │ github │ Press Enter or type y to choose github │
            # │ 1 │ n     │ gitee  │ Type n to choose gitee                 │
            # ╰───┴───────┴────────┴────────────────────────────────────────╯
            #
            print sty["cyan"] "╭───┬" sty["blue"]     "───────" sty["cyan"]     "┬" sty["cyan"]  "────────" sty["yellow"] "┬" sty["yellow"] "────────────────────────────────────────" sty["yellow"] "╮"
            print sty["cyan"] "│ # │" sty["blue"]     " Opt   " sty["cyan"]     "│" sty["cyan"]  "  Src   " sty["yellow"] "│" sty["yellow"] "              Description               " sty["yellow"] "│"
            print sty["cyan"] "├───┼" sty["blue"]     "───────" sty["cyan"]     "┼" sty["cyan"]  "────────" sty["yellow"] "┼" sty["yellow"] "────────────────────────────────────────" sty["yellow"] "┤"
            print sty["cyan"] "│ 0 │" sty["green"]    " y     " sty["cyan"]    "│" sty["green"]  " github " sty["yellow"] "│"  sty["green"] " Press Enter or type y to choose github " sty["yellow"] "│"
            print sty["cyan"] "│ 1 │" sty["magenta"]  " n     " sty["cyan"]  "│" sty["magenta"]  " gitee  " sty["yellow"] "│"sty["magenta"] " Type n to choose gitee                 " sty["yellow"] "│"
            print sty["cyan"] "╰───┴" sty["blue"]     "───────" sty["cyan"]     "┴" sty["cyan"]  "────────" sty["yellow"] "┴" sty["yellow"] "────────────────────────────────────────" sty["yellow"] "╯"
            print sty[0] "Do you want to" sty["yellow"] " get it" sty["blue"] " from " sty["underline"] sty["cyan"]"github" sty[0] "?", y_n
            opt = read_to_string(STDIN)
            uri["current"] = (opt ~ /^n/)? uri["gitee"]: uri["github"]
        }
    } else {
        uri["current"] = (net_node ~ /github|hub|gh/)? uri["github"]: uri["gitee"]
    }

    # uri["num_of_fallback"] = 1
    uri["fallback"] = uri["jscdn"]
    
}
# -----------
# This function was written before I wrote `get_i18n()`.
# To rewrite it, call `get_i18n()`
function about_y_or_n(_, amap) {
    # Not yet ready to support i18n, so only `en` and `zh` are available.
    #
    # amap["option", "en"] = "Options"
    amap["option", "zh", "hans"] = "选项"
    amap["option", "zh", "hant"] = "選項"

    # amap["desc", "en"] = "Description"
    amap["desc", "zh", "hans"] = amap["desc", "zh", "hant"] = "描述"

    # amap["default_is_yes", "en"] = "Default is yes"
    # amap["default_is_no", "en"] = "Default is no"

    amap["default_is_yes", "zh", "hans"] = "默认为yes"
    amap["default_is_yes", "zh", "hant"] = "默認爲yes"

    amap["default_is_no", "zh", "hans"] = "默认为no"
    amap["default_is_no", "zh", "hant"] = "默認爲no"

    # amap["press_enter", "en"] = "Press Enter"
    # amap["type_n_press_enter", "en"] = "Type n and press Enter"
    # amap["type_y_press_enter", "en"] = "Type y and press Enter"

    amap["press_enter", "zh", "hans"] = "直接按回车键"
    amap["type_n_press_enter", "zh", "hans"] = "先输入n,再按回车"
    amap["type_y_press_enter", "zh", "hans"] = "先输入y,再按回车"

    amap["press_enter", "zh", "hant"] = "直接按回車鍵"
    amap["type_n_press_enter", "zh", "hant"] = "先輸入n,再按回車"
    amap["type_y_press_enter", "zh", "hant"] = "先輸入y,再按回車"

    # style:
    # [[index, A, B, C] [cn, blue, cyan, yellow]]
    # [[Option, Description, yes, no]; ["[Y/n]","Default is yes", "Press Enter", "Type n and press Enter" ] , ["[y/N]","Default is no", "Type y and press Enter", "Press Enter"]]
    # [[选项, 描述, yes, no]; ["[Y/n]","默认是yes", "直接按回车键", "先输入n,再按回车" ] , ["[y/N]","默认是no", "先输入y,再按回车", "直接按回车键"]]
    # amap["type_n_press_enter", I18N["lang"], I18N["script"]]
    #
    # ╭───┬────────┬────────────────┬────────────────────────┬────────────────────────╮
    # │ # │ Options│  Description   │          yes           │           no           │
    # ├───┼────────┼────────────────┼────────────────────────┼────────────────────────┤
    # │ 0 │ [Y/n]  │ Default is yes │ Press Enter            │ Type n and press Enter │
    # │ 1 │ [y/N]  │ Default is no  │ Type y and press Enter │ Press Enter            │
    # ╰───┴────────┴────────────────┴────────────────────────┴────────────────────────╯
    #
    if (I18N["lang"] == "zh") {
        print sty["blue"] "关于 " coloured_y_n(true) ":"
        print sty["blue"] "關於 " coloured_y_n(false) ":"
        

        print sty["cn"] "╭───┬" sty["bu"] "───────┬" sty["yl"] "───────────┬" sty["cn"] "──────────────────┬" sty["mn"] "───────────────────╮"
        print sty["cn"] "│ # │" sty["bu"] " "amap["option", I18N["lang"], I18N["script"]]"  │" sty["yl"] "   " amap["desc", I18N["lang"], I18N["script"]]"    │" sty["cn"] "       yes        │" sty["mn"] "        no         │"
        print sty["cn"] "├───┼" sty["bu"] "───────┼" sty["yl"] "───────────┼" sty["cn"] "──────────────────┼" sty["mn"] "───────────────────┤"
        print sty["cn"] "│ 0 │" sty["bu"] " " coloured_y_n(true) " │" sty["gn"] " " amap["default_is_yes", I18N["lang"], I18N["script"]] sty["yl"] " │" sty["gn"] " " amap["press_enter", I18N["lang"], I18N["script"]] sty["cn"]"     │" sty["mn"] " " amap["type_n_press_enter", I18N["lang"], I18N["script"]] "  │"
        print sty["cn"] "│ 1 │" sty["bu"] " " coloured_y_n(false) " │" sty["yl"] " " amap["default_is_no", I18N["lang"], I18N["script"]] sty["yl"] "  │" sty["mn"] " " amap["type_y_press_enter", I18N["lang"], I18N["script"]] sty["cn"]" │" sty["gn"] " " amap["press_enter", I18N["lang"], I18N["script"]] sty["mn"]"      │"
        print sty["cn"] "╰───┴" sty["bu"] "───────┴" sty["yl"] "───────────┴" sty["cn"] "──────────────────┴" sty["mn"] "───────────────────╯"
    } else {
        print sty["cyan"] "About " coloured_y_n(true) " & " coloured_y_n(false) ":"
        print sty["cn"] "╭───┬" sty["bu"] "────────┬" sty["yl"] "───────────────┬" sty["cn"] "───────────────┬" sty["mn"] "──────────────╮"
        print sty["cn"] "│ # │" sty["bu"] " Options│" sty["yl"] "  Description  │" sty["cn"] "      yes      │" sty["mn"] "      no      │"
        print sty["cn"] "├───┼" sty["bu"] "────────┼" sty["yl"] "───────────────┼" sty["cn"] "───────────────┼" sty["mn"] "──────────────┤"
        print sty["cn"] "│ 0 │" sty["bu"] " " coloured_y_n(true) "  │" sty["gn"] " Default is    │" sty["gn"] " Press Enter   │" sty["mn"] " Type n and   │"
        print sty["cn"] "│   │" sty["bu"] "        │" sty["gn"] " yes           │" sty["cn"] "               │" sty["mn"] " press Enter  │"
        print sty["cn"] "│ 1 │" sty["bu"] " " coloured_y_n(false) "  │" sty["yl"] " Default is no │" sty["mn"] " Type y and    │" sty["gn"] " Press Enter  │"
        print sty["cn"] "│   │" sty["bu"] "        │" sty["yl"] "               │" sty["mn"] " press Enter   │" sty["mn"] "              │"
        print sty["cn"] "╰───┴" sty["bu"] "────────┴" sty["yl"] "───────────────┴" sty["cn"] "───────────────┴" sty["mn"] "──────────────╯"
    }
}
function coloured_y_n(y) {
    if (y)
        return sty["0"] sty["cn"] "[" sty["gn"] sty["b"] sty["u"] "Y" sty["/u"] sty["/b"] sty["bu"] sty["faint"] "/" sty["/b"] sty["_"] sty["mn"] "n" sty["/_"] sty["cn"] "]" sty["0"]
    else
        return sty["0"] sty["cn"] "[" sty["mn"] sty["_"] "y" sty["/_"] sty["bu"] sty["faint"] "/" sty["/b"] sty["gn"] sty["b"] sty["u"] "N" sty["/u"] sty["/b"] sty["cn"] "]" sty["0"]
}
# -----------
function run_old_edition(_, home_dir, dl_status, file1, file2) {
    # net_node: gitee, github
    # -v lang=zh-cn \
    # -v net_node="gh" \
    # -v tmp_dir="/tmp" \

    home_dir = ENVIRON["HOME"]

    if (is_empty(home_dir))
        home_dir = ENVIRON["HOMEPATH"]

    GIT["manager_file"] = "share/old-version/share/app/manager"
    GIT["dir"] = home_dir "/.local/share/tmoe-linux/git"
    GIT["dir2"] = "/usr/local/etc/tmoe-linux/git"
    
    file1 = GIT["dir"] "/" GIT["manager_file"]
    file2 = GIT["dir2"] "/" GIT["manager_file"]

    run_old_file(file1, file2)

    print_sys_info()
    about_y_or_n()

    if (!do_you_want_to_continue(true))
        exit 0

    about_new_and_old_edition()
    set_git_uri(GIT, URI)
    #[test]
    # print "debug::run_old_version,", URI["gitee"], "\n", URI["github"], "\n", URI["jscdn"], "\n"
    # print net_node, tmp_dir

    # default
    TMP["file"] = NONE
    set_tmp_dir(TMP, home_dir)

    print sty["yl"] TMP["file"] "\n"
    dl_status = get_file(URI["current"], URI["fallback"], TMP["file"])
    # print_bool(dl_status())
    if (dl_status) {
        run_old_file(TMP["file"], file1)
        exit 0
    } else {
        exit 1
    }
}
# -----------
function about_new_and_old_edition() {
    # [[Step, Command]; ["download neko repo", "wget https://l.tmoe.me/neko.deb"] ["install deb as root", "sudo apt install ./neko.deb"] ["update index", "sudo apt update"] ["install tmm", "sudo apt install tmm"] ["remove deb file", "rm neko.deb"] ]

    print sty["de"] sty[1] "Perphaps one day, the new edition will be installed by the following steps below:" sty[0]

    print sty["cn"] "╭───┬─"sty["cn"] "───────────────────" sty["cn"] "─┬" sty["yl"] "─────────────────────────────────" sty["yl"]"╮"
    print sty["cn"] "│ # │ "sty["cn"] "       Step        " sty["cn"] " │" sty["yl"] "             Command             " sty["yl"]"│"
    print sty["cn"] "├───┼─"sty["cn"] "───────────────────" sty["cn"] "─┼" sty["yl"] "─────────────────────────────────" sty["yl"]"┤"
    print sty["cn"] "│ 0 │ "sty["gn"] "download neko repo " sty["cn"] " │" sty["gn"] " wget https://l.tmoe.me/neko.deb " sty["yl"]"│"
    print sty["cn"] "│ 1 │ "sty["mn"] "install deb as root" sty["cn"] " │" sty["mn"] " sudo apt install ./neko.deb     " sty["yl"]"│"
    print sty["cn"] "│ 2 │ "sty["bu"] "update index       " sty["cn"] " │" sty["bu"] " sudo apt update                 " sty["yl"]"│"
    print sty["cn"] "│ 3 │ "sty["yl"] "install tmm        " sty["cn"] " │" sty["yl"] " sudo apt install tmm            " sty["yl"]"│"
    print sty["cn"] "│ 4 │ "sty["de"] "remove deb file    " sty["cn"] " │" sty["de"] " rm neko.deb                     " sty["yl"]"│"
    print sty["cn"] "╰───┴─"sty["cn"] "───────────────────" sty["cn"] "─┴" sty["yl"] "─────────────────────────────────" sty["yl"]"╯"
    print sty[0]

    print "However, it is still " sty["rd"] "the old edition." sty[0]
    print "There are many, many illogical designs in the old edition. To be honest, I don't particularly recommend it."
    print "You may have heard of it before, and I will rewrite it."
    print "Before, you probably installed it with `master/debian.sh` or `2/2`. Now it's `2/2.awk`."
    print "What you see now is written in awk."
    print "This file is just used to guide you through the installation of tmm."
    print "For the other tools, I should write it in another language."
    print "To be honest, I really like rust."
    print "But due to my poor knowledge of the underlying operating system, and my lack of familiarity with rust asynchronous and unsafe. So I'm not ready yet."
    print sty["~"]"Perhaps I should rewrite it quickly in `nu` and then rewrite it again in `rust`." sty["/~"]
    print "In fact, I don't have that much time."
    print "I am sorry that I did not fulfil your expectations."
    print "\n"
    print "Enough about the new edition, let's get to know", sty["yl"]"the old one!"
    print sty["bu"] sty["_"]"Section:", sty[0] "admin"
    print sty["bu"] sty["_"]"Depends:", sty[0] "aria2 (>= 1.30.0), binutils (>= 2.28-5), coreutils (>= 8.26-3), curl (>= 7.52.1-5), findutils (>= 4.6.0), git (>= 1:2.11.0-3), grep, lsof (>= 4.89), micro (>= 2.0.6-2) | nano (>= 2.7.4-1), proot (>= 5.1.0), procps (>= 2:3.3.12), sed, sudo (>= 1.8.19p1-2.1), tar (>= 1.29b-1.1),  util-linux (>= 2.29.2-1), whiptail (>= 0.52.19), xz-utils (>= 5.2.2), zstd (>= 1.1.2)"
    print sty["bu"] sty["_"]"Recommends:", sty[0] "bat, debootstrap, eatmydata, gzip, less, lz4, pulseaudio, pv, qemu-user-static, systemd-container"
    print sty["bu"] sty["_"]"Suggests:", sty[0] " busybox, zsh"
    print sty["bu"] sty["_"]"Homepage:", sty[0] " https://github.com/2moe/tmoe"
    print sty["bu"] sty["_"]"Tag:", sty[0] "interface::TODO, interface::text-mode, system::cloud, system::virtual, role::program, works-with::archive, works-with::software:package, works-with::text"
    print sty["bu"] sty["_"]"Description:", sty[0] "Easily manage containers and system. Just type `tmoe` to enjoy it."

    print "\n" 
    print  sty["gn"] "With this, I offer my " sty["bu"]"best wishes."
    print sty["yl"] "Thank you for your choice and for running it."
    print sty["yl"] "Thank you for being kind and lovely." sty["0"]
    # print "\n" 
    print "I wish I could offer you a better service but unfortunately there are some current problems."
    print "You can choose " sty["gn"] sty["u"]"no"sty[0] ", and I look forward to seeing you next time."


    if (!do_you_want_to_continue(false)) {
        print sty["cn"] "See you next time" sty[0]
        exit 0
    }
}
function print_sys_info() {
    print sty["b"] sty["cn"] "OS info:" sty[0]
    for (i in OS) {
        if (!is_empty(OS[i]))
            print sty["_"] sty["bu"] i ":", sty["/_"] sty["yl"] OS[i]
    }
    print "\n" sty["b"] sty["cn"] "Architecture:" sty[0]
    for (i in ARCH)
        print sty["_"] sty["gn"] i ":", sty["/_"] sty["yl"] ARCH[i]

    print "\n" sty["b"] sty["cn"] "Locale:" sty[0]
    for (i in I18N)
        print sty["_"] sty["mn"] i ":", sty["/_"] sty["yl"] I18N[i]

    print "\n"
}
# -----------
# do_you_want_to_continue(b: bool) -> bool
function do_you_want_to_continue(b, _, opt, a_map, y_n, language) {

    language = I18N["lang"]
    a_map["ext", language] = NONE

    # English
    a_map["do_you", "en"] = "Do you want to" SPACE
    a_map["cont", "en"] = "continue?"

    # Español
    a_map["do_you", "es"] = "¿Quieres "
    a_map["cont", "es"] = "continuar?"

    # Português
    a_map["ext", "pt"] = "region"
    a_map["fallback", "pt"] = "pt"
    # Portugal
    a_map["do_you", "pt" "pt"] = "Quer "
    a_map["cont", "pt" "pt"] = "continuar?"
    # Brasil
    a_map["do_you", "pt" "br"] = "Você quer "

    # Deutsch
    a_map["do_you", "de"] = "Möchten Sie "
    a_map["cont", "de"] = "fortfahren?"

    # polski
    a_map["do_you", "pl"] = "Czy chcesz "
    a_map["cont", "pl"] = "kontynuować?"

    # 日本語
    a_map["cont", "ja"] = "継続"
    a_map["do_you", "ja"] = "しますか?"

    # 한국어
    a_map["cont", "ko"] = "계속하"
    a_map["do_you", "ko"] = "시겠습니까?"

    # čeština
    a_map["do_you", "cs"] = "Chcete "
    a_map["cont", "cs"] = "pokračovat?"
    
    # eesti
    a_map["do_you", "et"] = "Kas soovite "
    a_map["cont", "et"] = "jätkata?"

    # български
    a_map["do_you", "bg"] = "Искате ли да "
    a_map["cont", "bg"] = "продължите?"

    # dansk
    a_map["do_you", "da"] = "Ønsker du at "
    a_map["cont", "da"] = "fortsætte?"

    # latviešu
    a_map["do_you", "lv"] = "Vai vēlaties "
    a_map["cont", "lv"] = "turpināt?"

    # română
    a_map["do_you", "ro"] = "Vrei să "
    a_map["cont", "ro"] = "continui?"

    # magyar 
    a_map["do_you", "hu"] = "Akarod "
    a_map["cont", "hu"] = "folytatni?"

    # Tiếng Việt
    a_map["do_you", "vi"] = "Bạn có muốn "
    a_map["cont", "vi"] = "tiếp tục?"

    # Indonesia
    a_map["do_you", "id"] = "Apakah Anda ingin "
    a_map["cont", "id"] = "melanjutkan?"

    # українська
    a_map["do_you", "uk"] = "Ви хочете "
    a_map["cont", "uk"] = "продовжити?"
    
    # ру́сский язы́к
    a_map["do_you", "ru"] = "Вы хотите "
    a_map["cont", "ru"] = "продолжить?"

    # français
    a_map["do_you", "fr"] = "Voulez-vous "
    a_map["cont", "fr"] = "continuer?"
    
    # বাংলা
    a_map["do_you", "bn"] = "আপনি কি "
    a_map["cont", "bn"] = "অবিরত করতে চান?"

    # italiano
    a_map["do_you", "it"] = "Vuoi "
    a_map["cont", "it"] = "continuare?"

    # svenska
    a_map["do_you", "sv"] = "Vill du "
    a_map["cont", "sv"] = "fortsätta?"

    # suomi
    a_map["do_you", "fi"] = "Haluatko "
    a_map["cont", "fi"] = "jatkaa?"

    # Nederlands
    a_map["do_you", "nl"] = "Wil je "
    a_map["cont", "nl"] = "doorgaan?"

    # slovenčina
    a_map["do_you", "sk"] = "Chcete "
    a_map["cont", "sk"] = "pokračovať?"

    # slovenščina
    a_map["do_you", "sl"] = "Ali želite "
    a_map["cont", "sl"] = "nadaljevati?"

    # Türkçe
    a_map["cont", "tr"] = "Devam "
    a_map["do_you", "tr"] = "etmek istiyor musun?"
    
    # Ελληνικά
    a_map["do_you", "el"] = "Θέλετε να "
    a_map["cont", "el"] = "συνεχίσετε;"

    # 中文
    a_map["ext", "zh"] = "script"
    a_map["fallback", "zh"] = "hans"
    a_map["do_you", "zh" "hans"] = "您要"
    a_map["cont", "zh" "hant"] = "繼續嗎?"
    a_map["cont", "zh" "hans"] = "继续吗?"

    y_n = coloured_y_n(b)

    # This message should not be printed in i18n, but in English.
    # print sty["bu"] a_map["do_you", "en"] sty["yl"] a_map["cont", "en"], y_n

    # print i18n data
    # if (language != "en" && (!is_empty(get_i18n("do_you", a_map))))
    # Now, if the relevant data does not exist, it will automatically fallback

    if (language ~ /ja|ko|tr/)
        print sty["yl"] get_i18n("cont", a_map) sty["bu"] get_i18n("do_you", a_map), y_n
    else
        print sty["bu"] get_i18n("do_you", a_map) sty["yl"] get_i18n("cont", a_map), y_n

    opt = read_to_string(STDIN)
    if (b)
        return (opt ~ /^n|^N/)? false: true
    else
        return (opt ~ /^y|^Y/)? true: false
}
# -----------
# Get i18n data
#
# Example
#
# ```awk
#     # set lang ext, of course, it can be empty.
#     # You can set it to "region" or "script"
#     a_map["ext", "en"] = "region"
#
#     # Basic structure: [key, language ext]
#     a_map["clr", "en" "gb"] = "colour"
#     a_map["clr", "en" "us"] = "color"
#     # Great, we've set up gb and us.
#
#     # Let's see how get_i18n() works!
#     key = "clr"
#     value = get_i18n(key, a_map)
#     print value
#     # If your region is the GB, then it will print the word "colour"
#
#     # Q: But my region is au, and we haven't set it up yet. 
#     #    What should I do?
#     # A: You need to set the fallback.
#
#     # More commonly, you can think of it as having a default value stored inside.
#     a_map["fallback", "en"] = "us"
#
#     # If a_map["clr", "en" "au"] is empty, then it will get a_map["clr", "en" "us"]
#     # Note: Prerequisite is a call to the get_i18n()
#
#     # We can set a fallback for each language
#     # e.g. a_map["fallback", "de"] = "de"
#
#     # You can even set fallback for specific regional languages
#     # e.g. Fallback for ca is us, and fallback for hk is gb
#     a_map["fallback", "en" "ca"] = "us"
#     a_map["fallback", "en" "hk"] = "gb"
# ```
# 
function get_i18n(key, a_map, _, ext, language, value, fallback, region, fallback2, fallback0, map_ext) {
    language = I18N["lang"]

    map_ext = a_map["ext", language]
    ext = a_map["ext"] = is_empty(map_ext)? NONE: I18N[map_ext]

    value = a_map[key, language ext]

    # Priority: fallback2 > fallback > fallback0
    # [[fallback2, fallback, fallback0]; ["zh my => zh sg", "zh => zh cn", "zh cn => en"], ["If the key is pineapple. MY cannot find the value corresponding to this key, then it will fall back to SG. If found, return '黄梨'. If not found, fallback2 => fallback", "If fallback is cn for the zh language. hk => cn, mo => cn, tw => cn. If fallback2 has no value, then it is '菠萝' in fallback. If fallback has no value, fallback => fallback0", "At fallback0 there is no way back. Here, it is neither '黄梨' nor '菠萝', but pineapple"] ]
    #
    # ╭───┬─────────────────────┬────────────────────┬────────────────────╮
    # │ # │      fallback2      │      fallback      │     fallback0      │
    # ├───┼─────────────────────┼────────────────────┼────────────────────┤
    # │ 0 │ zh my => zh sg      │ zh => zh cn        │ zh cn => en        │
    # │ 1 │ If the key is       │ If fallback is cn  │ At fallback0 there │
    # │   │ pineapple. MY       │ for the zh         │ is no way back.    │
    # │   │ cannot find the     │ language. hk =>    │ Here, it is        │
    # │   │ value corresponding │ cn, mo => cn, tw   │ neither '黄梨' nor │
    # │   │ to this key, then   │ => cn. If          │ '菠萝', but        │
    # │   │ it will fall back   │ fallback2 has no   │ pineapple          │
    # │   │ to SG. If found,    │ value, then it is  │                    │
    # │   │ return '黄梨'. If   │ '菠萝' in          │                    │
    # │   │ not found,          │ fallback. If       │                    │
    # │   │ fallback2 =>        │ fallback has no    │                    │
    # │   │ fallback            │ value, fallback => │                    │
    # │   │                     │ fallback0          │                    │
    # ╰───┴─────────────────────┴────────────────────┴────────────────────╯
    #
    if (is_empty(value)) {
        fallback = a_map["fallback", language]
        region = I18N["region"]
        fallback2 = a_map["fallback", language region]
        fallback0 = a_map["fallback"]

        if (!is_empty(fallback2)) {
            value = a_map[key, language fallback2]
            if (!is_empty(value))
                return value
        }

        if (!is_empty(fallback)) {
            value = a_map[key, language fallback]
            if (!is_empty(value))
                return value
        }

        if (is_empty(fallback0))
            fallback0 = "en"

        return a_map[key, fallback0]
    }
    return value
}
# -----------
function run_old_file(file1, file2) {
    if (!check_cmd("bash")) {
        print sty["mn"] "Unfortunately, the new edition is not out yet.\n",
        sty["yl"] "The old edition depends on bash, which I think was a mistake.\n",
        sty["gn"] "Let's look forward to the new edition! See you soon."
        exit 1
    }

    # print "debug::run_old_file" file1, file2

    if (is_file_exists(file1)) {
        if (!(match(read_to_string(file1), /TUI_BIN/))) {
            git_dir = GIT["dir"]
            if (match(git_dir, "/tmoe-linux/git") && is_file_exists(git_dir)) {
                print "You have already installed an older version, which has serious problems and will be removed automatically. You will need to re-run this awk file."

                print "Press enter to remove the old git dir"

                rm_cmd = "rm -rfv" SPACE git_dir
                print sty["rd"] rm_cmd sty[0]
                if (do_you_want_to_continue(true)) {
                    system(rm_cmd)
                    print sty["mn"] "Please re-run this awk file" sty[0]
                }
                exit 1
            }
        }
        if (system("bash" SPACE file1))
            exit 1
        else
            exit 0
    }

    if (is_file_exists(file2)) {
        if (system("bash" SPACE file2))
            exit 1
        else
            exit 0
    }
}
# -----------
function set_tmp_dir(tmp, home, _, tmp_env, cache_dir, tmp_arr, tmp_arr_len) {
    if (check_cmd("mktemp")) {
        tmp["file"] = get_cmd_out("mktemp")
        tmp_arr_len = split(tmp["file"], tmp_arr, "/")
        tmp["file0"] = tmp_arr[tmp_arr_len]
        for (i = 2; i<= (tmp_arr_len - 1); ++i)
            tmp["dir"] = (i == 2)? "/" tmp_arr[i]: tmp["dir"] "/" tmp_arr[i]
    } else {
        tmp_env = ENVIRON["TMPDIR"]
        cache_dir = home "/.cache"
        tmp["dir"] = (!is_empty(tmp_env))? tmp_env:     (is_file_exists("/tmp"))? "/tmp":    cache_dir

        if (tmp["dir"] == cache_dir && (!is_file_exists(cache_dir))) {
            if (system("mkdir -p" SPACE cache_dir)) {
                print sty["red"] "Error!", sty["yellow"] "Since the", sty["blue"] "TMPDIR" sty["yellow"] "environment variable does not exist, the temporary directory is", sty["green"] cache_dir sty["magenta"] ", but it failed to be created." sty[0]

                exit 1
            }
        }
        tmp["file0"] = ".tmoe-old-version.sh"
        tmp["file"] = tmp["dir"] "/" tmp["file0"]
    }

    # awk -f ./a.awk -v tmp_dir=/tmp
    # `tmp_dir` from `-v` arg
    if (!is_empty(tmp_dir) && tmp_dir ~ "/") {
        tmp["dir"] = tmp_dir
        tmp["file"] = (tmp_dir ~ "/$")? tmp["dir"] tmp["file0"]:        tmp["dir"] "/" tmp["file0"]
        # print "tmp_file:" tmp["file"]
    }
}
# -----------
function get_file(uri, fallback, file) {
    if (is_empty(DOWNLOADER)) {
        print sty["red"] "Error!" sty["mn"] "No compatible downloader found" > STDERR
        print sty["bu"] "Unfortunately, we did not find curl or wget on your system."
        exit 1
    }

    if (DOWNLOADER == "curl") {
        # If the exit status of the program is true, the loop is exited.
        for (i = 0; i < 30; ++i) {
            # !system => !(0) => true
            if (!system("curl --compressed -L" SPACE uri SPACE "-o" SPACE file) > 0) {
                return true
                # break
            } else {
                print sty["red"] "Unknown curl Error! " > STDERR
                print sty["yl"] "Trying again..." sty[0]
                uri = fallback
            }
        }
    }

    if (DOWNLOADER == "wget") {
        # !system => !(0) => true
        for (i = 0; i < 20; ++i) {
            if (!system("wget" SPACE uri SPACE "-O" SPACE file) > 0) {
                return true
                # break
            } else {
                print sty["red"] "wget is downloading files with errors, please check your ca-certificates." > STDERR
                print sty["blue"] "The manual fix is a better solution than `-no-check-certificate`."
                print sty["yl"] "Trying again..." sty[0]
                uri = fallback
            }
        }
    }

    # (is_empty(downloader)): 
    return false
}
# -----------
# Check if the command exists with `WHICH_CMD`.
#
# [["Cmd Name", Usage, Result]; [uname, 'check_cmd("uname")', "true or false"]]
#
# ╭───┬──────────┬────────────────────┬───────────────╮
# │ # │ Cmd Name │       Usage        │    Result     │
# ├───┼──────────┼────────────────────┼───────────────┤
# │ 0 │ uname    │ check_cmd("uname") │ true or false │
# ╰───┴──────────┴────────────────────┴───────────────╯
#
# What is the difference between check_cmd() and is_cmd_exists()?
#
# `A` and `B` are the former and `C` is the latter.
# A: check_cmd(n) => is_cmd_exists("command", ["-v", n]) -> bool
# B: check_cmd(n) => is_cmd_exists("which", [n]) -> bool
# C: is_cmd_exists(cmd, arg) -> bool
#
# Example
#
# ```awk
#    WHICH_CMD = get_which_cmd()
#    s = check_cmd("uname")
#    if (s)
#       print "Congratulations, `uname` already exists in your system"
#
#    u = check_cmd("unknown_cmd", "--help")
#    print_bool(u)
#    # stdout: false
# ```
#
# opt_arg is optional, and it is not an array, but a string
# If the value is "-d,2,-b,3", and it will automatically slice into an array: 
# ["-d", "2", "-b", "3"]
# i.e. arg[1] = "-d", arg[2] = "2"
# Note: It starts at 1, not 0
#
# check_cmd(cmd: string, opt_arg: string) -> bool
function check_cmd(cmd_name, opt_arg, _, cmd, arr_len, arg) {
    # Is there a constant `WHICH_CMD`?
    # cmd = 
    #   No => cmd_name (it comes from the parameter)
    #   Yes, but opt_arg is not empty => cmd_name
    #   Yes => WHICH_CMD (and cmd_name => arg)
    cmd = (is_empty(WHICH_CMD))? cmd_name: WHICH_CMD

# [[Cmd, Arg]; [command, "-v cmd_name"] [which, cmd_name] [type, cmd_name] [cmd_name, opt_arg]]
#
# ╭───┬──────────┬─────────────╮
# │ # │   Cmd    │     Arg     │
# ├───┼──────────┼─────────────┤
# │ 0 │ command  │ -v cmd_name │
# │ 1 │ which    │ cmd_name    │
# │ 2 │ type     │ cmd_name    │
# │ 3 │ cmd_name │ opt_arg     │
# ╰───┴──────────┴─────────────╯
#
    arr_len = 0
    # If opt_arg is empty and WHICH_CMD is not empty, then set the arg. e.g. (command, ["-v", cmd_name]), (type, [cmd_name])
    if (is_empty(opt_arg)) {
        opt_arg = "--help"
        # set arg(array).
        if (WHICH_CMD == "command")
            arr_len = split("-v" SPACE cmd_name, arg, SPACE)
        else if (WHICH_CMD ~ /type|which/)
            arr_len = split(cmd_name, arg, ",")
    }

    # An implicit condition is included here (!is_empty(opt_arg))
    # i.e. opt_arg is not empty and arr_len is 0
    # [[Var, Value, Empty]; [arr_len, 0, false] [opt_arg, "?", false]]
# ╭───┬─────────┬───────┬───────╮
# │ # │   Var   │ Value │ Empty │
# ├───┼─────────┼───────┼───────┤
# │ 0 │ arr_len │ 0     │ false │
# │ 1 │ opt_arg │ ?     │ false │
# ╰───┴─────────┴───────┴───────╯
#
    if (arr_len == 0) {
        # The cmd variable will be forced to be overwritten.
        cmd = cmd_name
        arr_len = split(opt_arg, arg, ",")
    }

    # if arr_len is still 0, then there is an error.
    if (arr_len == 0) {
        print sty["red"] "Error!\n",
        sty["yellow"] "{\n",
        sty["magenta"] "Name:", sty["cyan"] "check_cmd()\n",
        sty["magenta"] "Reason:", sty["cyan"] "The arr_len is 0.\n",
        sty["magenta"] "Analysis:", sty["cyan"] "When you call check_cmd(), you may have passed in the wrong arguments.\n",
        sty["yellow"] "}" sty[0] > STDERR
        exit 1
    }

    # print "debug::check_cmd", "cmd_name:", cmd_name, "opt_arg:", opt_arg
    # print "debug::check_cmd", "cmd:", cmd, "arg[1]:", arg[1], "arg[2]", arg[2]

    return is_cmd_exists(cmd, arg, arr_len)
}
# -----------
# Use `!system()` to determine if the command exists.
#
# Compared to `check_cmd()`, `is_cmd_exists()` is more low-level.
#
# Some special awk distributions do not have `length(array)`
# So, `arr_len` is used here.
#
# is_cmd_exists(cmd: string, arg: array, arg_len: usize) -> bool
function is_cmd_exists(cmd, arg, arr_len, _, i) {
    if (arr_len >= 1) {
        # Since `split()` is used, it starts at 1 instead of 0 (i = 0; i < arg_len)
        for (i = 1; i <= arr_len; ++i) {
            # print "debug::is_cmd_exists, cmd: ", cmd, "arg: ", arg[i]
            cmd = cmd SPACE arg[i]
        }
    }
    # It's (!system()) not (system())
    return (!system(cmd TO_NULL))
}
# -----------
# [[Name]; [command] [type] [which]]
#
# ╭───┬─────────╮
# │ # │  Name   │
# ├───┼─────────┤
# │ 0 │ command │
# │ 1 │ type    │
# │ 2 │ which   │
# ╰───┴─────────╯
#
function get_which_cmd(_, i, cmd, arg, arr_len, cmd_arr1, cmd_arr1_len, cmd_arr2) {

    cmd_arr1_len = split("command,type,which", cmd_arr1, ",") 

    # The value of cmd_arr1 becomes the key of cmd_arr2. This is an intentional design.
    cmd_arr2[cmd_arr1[1]] = "-v,command"

    # Assign value to cmd_arr2
    for (i = 2; i <= cmd_arr1_len; ++i) 
        cmd_arr2[cmd_arr1[i]] = cmd_arr1[i]

    # Generate a new array based on cmd_arr2 and call `is_cmd_exists()`
    # [[Cmd, Arg]; [command, "-v command"] [type, type] [which, which]]
# 
# ╭───┬─────────┬────────────╮
# │ # │   Cmd   │    Arg     │
# ├───┼─────────┼────────────┤
# │ 0 │ command │ -v command │
# │ 1 │ type    │ type       │
# │ 2 │ which   │ which      │
# ╰───┴─────────┴────────────╯
#
#  Note: if (command -v command) has no errors, then return `command`, otherwise check `type` and `which`
#
    for (i = 1; i <= cmd_arr1_len; ++i) {
        cmd = cmd_arr1[i]

        arr_len = split(cmd_arr2[cmd], arg, ",")
        # print "debug::get_which_cmd, cmd: ", cmd, "arg[1]: ", arg[1]
            if (is_cmd_exists(cmd, arg, arr_len)) {
                return cmd
                # break
            }
    }
    # !(command|type|which):
    return NONE
}
# -----------
# Use the output of the command as the return value
#
# Example
#
# ```awk
#     b = get_cmd_out("mawk,-W,version")
#     print b
#     # stdout: mawk 1.3.4 20200120
# ```
#
# get_cmd_out(full_cmd: string) -> string
function get_cmd_out(full_cmd, _, arr, arr_len, out, cmd, i, v) {
    arr_len = split(full_cmd, arr, ",")

    for (i = 1; i <= arr_len; ++i)
        cmd = cmd SPACE arr[i]

    for (i = 0; (cmd | getline v) > 0; ++i)
        out = (i != 0)? out "\n" v:  v

    close(cmd)
    return out
}
# -----------
# Match the output of the command, and parse
#
# This is read on a row-by-row basis and if a match is made, subsequent content is not parsed further.
# If you want to parse all rows, use `collect_to_arr()`. 
# Note: `parse_cmd_out()` will return a string, but `collect_to_arr()` will collect the parsed contents into an array.
#
# Example
#
# ```awk
#     # arg1: full_cmd(comma separated), arg2: regex_str, arg3: field_separator
#
#     ver = parse_cmd_out("dpkg-query,-s,gpgv", "^(V|v)er.*ion", ":" SPACE)
#     print ver
#     # stdout: 2.2.35-3

#     # The source data are as follows:
#     # Package: gpgv
#     # Status: install ok installed
#     # Section: utils
#     # Source: gnupg2
#     # Version: 2.2.35-3
# ```
#
# parse_cmd_out(full_cmd: string, regex_str: string, field_separator: string) -> string
function parse_cmd_out(full_cmd, regex_str, field_separator, _, arr, arr_len, out, cmd, i) {

    # print "debug::parse_cmd_out,", "regex:", regex_str

    arr_len = split(full_cmd, arr, ",")

    for (i = 1; i <= arr_len; ++i)
        cmd = cmd SPACE arr[i]

    # Set FS, and `getline` will use it
    old_fs = FS
    FS = field_separator

    while ((cmd | getline) > 0) {
        if ($1 ~ regex_str) {
            out = $2
            break
        }
    }

    FS = old_fs

    close(cmd)
    return out
}
# -----------
# Get data from stdin or text, and return string.
#
# If `f` is standard input (stdin) data, then this fn will automatically trim the extra spaces on the left and right sides, and return it.
# If `f` is a file, then this fn will collect it to a string.
#
# Example
#
# ```awk
#     b = read_to_string("/etc/os-release")
#     print b
# ```
#
# input(from stdin/file) -> output(string)
function read_to_string(f, _, v, i, out) {
    if (f == STDIN) {
        # print "Please input a string"
        if ((getline out < f) <= 0) {
            print "IO Error, unknown input data" > STDERR
            exit 1
        }
    } else {
        for (i = 0; (getline v < f) > 0; ++i)
            out = (i != 0)? out "\n" v:  v

        # Do not `close("/dev/null")` manually. In mawk(1.3.4 20200120), it gets a segmentation fault.
        close(f)
    }

    return (f == STDIN)? trim(out): out
}
# -----------
# Parsing text data and collecting data into array.
#
# If "a.txt" has "Key" = "Value", "aa" = "bb".
# After using `collect_to_arr("a.txt", "=", a_map)`
# array: a_map["Key"] = "Value", a_map["aa"] = "bb"
#
# opt_ignore_str (regex str) is an optional argument.
# You can exclude specific string.
# Excluded string will not be parsed.
# 
# Example
#
# ```awk
#     collect_to_arr("/etc/os-release", "=", release)
#
#     for (i in release)
#         print "k:", i, "v:", release[i]
# ```
#
function collect_to_arr(file, field_separator, arr, opt_ignore_str, _, i) {

    # Set FS, and `getline` will use it.
    old_fs = FS
    FS = field_separator

    for (i = 0; (getline < file) > 0; ++i) {
        if (!is_empty(opt_ignore_str) && match($0, opt_ignore_str))
            ""
        else if (match($0, FS))
            arr[$1] = $2
        else
            arr[i] = $0
    }
    FS = old_fs

    #[test]
    # for (i in arr) {
    #     print "k =", i
    #     print "v =", arr[i]
    #     print "------------"
    # }

    close(file)
}
# -----------
# Set ANSI escape code
#
# For outputting fancy text to the terminal.
# When you call `print()` or `printf()`, you can print coloured text or special effects
#
# [[Colour, Foregroud, Backgroud]; [black,30,40] [red, 31, 41] [green, 32, 42] [yellow, 33, 43] [blue, 34, 44] [magenta, 35, 45] [cyan, 36, 46] [white, 37, 47] [default, 39, 49]]
#
# ╭───┬─────────┬───────────┬───────────╮
# │ # │ Colour  │ Foregroud │ Backgroud │
# ├───┼─────────┼───────────┼───────────┤
# │ 0 │ black   │        30 │        40 │
# │ 1 │ red     │        31 │        41 │
# │ 2 │ green   │        32 │        42 │
# │ 3 │ yellow  │        33 │        43 │
# │ 4 │ blue    │        34 │        44 │
# │ 5 │ magenta │        35 │        45 │
# │ 6 │ cyan    │        36 │        46 │
# │ 7 │ white   │        37 │        47 │
# │ 8 │ default │        39 │        49 │
# ╰───┴─────────┴───────────┴───────────╯
#
# Example
#
# ```awk
#     set_ansi_style()
#     print sty["green"] sty["~"] "hello", sty[0] sty["_"] sty["u"] sty["red"] "world" sty[0]
# ```
#
function set_ansi_style(_, colour_arr1, colour_arr1_len, i, colour_arr2) {
    colour_arr1_len = split("black,red,green,yellow,blue,magenta,cyan,white", colour_arr1, ",") 
    # "black,red,green,yellow,blue,magenta,cyan,white"
    # "bk,rd,gn,yl,bu,mn,cn,wh"
    # [[Colour, Abbr]; [black, bk],[red, rd] [green, gn], [yellow, yl],[blue, bu], [magenta, mn], [cyan, cn], [white, wh]]
    #
    # ╭───┬─────────┬──────╮
    # │ # │ Colour  │ Abbr │
    # ├───┼─────────┼──────┤
    # │ 0 │ black   │ bk   │
    # │ 1 │ red     │ rd   │
    # │ 2 │ green   │ gn   │
    # │ 3 │ yellow  │ yl   │
    # │ 4 │ blue    │ bu   │
    # │ 5 │ magenta │ mn   │
    # │ 6 │ cyan    │ cn   │
    # │ 7 │ white   │ wh   │
    # ╰───┴─────────┴──────╯
    #
    # note: sty["bk"] = sty["black"]
    split("bk,rd,gn,yl,bu,mn,cn,wh", colour_arr2, ",") 

    for (i = 1; i <= colour_arr1_len; ++i) {
        # note: Since i starts at 1, this is 29, not 30.
        # print "debug::set_ansi_style", "\33[" (29 + i) "m" 
        sty[colour_arr1[i]] = sty[colour_arr2[i]] = "\33[" (29 + i) "m"
    }


    # default foreground colour
    sty["default"] = sty["de"] = "\33[39m"

    # reset
    sty[0] = "\33[0m"

    # increased intensity 
    sty[1] = sty["bold"] = sty["b"] = "\33[1m"
    # decreased intensity
    sty[2] = sty["faint"] = "\33[2m"
    # neither bold nor faint
    sty["/b"] ="\33[22m"


    sty["italic"] = sty["_"] = "\33[3m"
    # Neither italic, nor blackletter 
    sty["/_"] = "\33[23m"


    sty["strike"] = sty["~"] = "\33[9m"
    # Not striked(crossed out)
    sty["/~"] = "\33[29m"

    sty["underline"] = sty["u"] = "\33[4m"
    sty["not underlined"] = sty["/u"] = "\33[24m"

    sty["background"] = sty["bg"] = "\33[7m"
    sty["foreground"] = sty["fg"] = "\33[27m"
}
# -----------
# Set constants
#
# About stdin:
# Some systems do not have "/dev/tty" or "/proc/self/fd/0"
# Some awk distros do not support "-"
# Interestingly, for busybox awk on windows (busybox: v1.36.0-FRP-4621-gf3c5e8bc3 (2022-02-28 07:17:58 GMT)), it automatically converts "/dev/stdin" to the windows interface, but neither "/dev/tty" or "-" will work.
# In mawk(1.3.4 20200120), an explicit call to `close("/dev/stdin")` will result in a segmentation fault.
#
function set_const() {
    STDIN = "/dev/stdin"
    NONE = ""
    SPACE = " "

    TO_NULL = " >/dev/null"
    STDERR = "/dev/stderr"

    # true and false are not keywords in the current awk
    false = 0
    true = 1

    # for outputting fancy text to the terminal
    set_ansi_style()

    # Get constant at runtime
    WHICH_CMD = get_which_cmd()
    
    # set downloader
    DOWNLOADER = (check_cmd("curl"))? "curl": (check_cmd("wget"))? "wget": NONE
}
# -----------
# Print true or else , instead of 1 or 0
#
# ╭───┬──────┬───────╮
# │ # │  Ok  │  Err  │
# ├───┼──────┼───────┤
# │   │ true │ false │
# ╰───┴──────┴───────╯
#
# Example
#
# ```awk
#    m = 1
#    print_bool(m)
#    # stdout: true
#
#    n = 0
#    print_bool(n)
#    # stdout: false
#    # note: this is stdout, not stderr
# ```
#
# print_bool(b: bool)
function print_bool(b) {
    print (b)? "true": "false"
}
# -----------
# If the string is empty -> true
# If not empty -> false
#
# Note: If you want to remove spaces or other invisible characters, you need to call `trim()` first
#
# [[s_type, Usage, Result]; ["string", "is_empty(s)", "true or false"]]
#
# ╭───┬────────┬─────────────┬───────────────╮
# │ # │ s_type │    Usage    │    Result     │
# ├───┼────────┼─────────────┼───────────────┤
# │ 0 │ string │ is_empty(s) │ true or false │
# ╰───┴────────┴─────────────┴───────────────╯
#
# Example
#
# ```awk
#     s = ""
#
#     if (is_empty(s))
#         print "Ok, s is empty"
# ```
#
# is_empty(s: string) -> bool
function is_empty(s) {
    # Unfortunately, busybox awk(1.35.0-1) does not have `typeof()`
    ## type: "array", "number", "regexp", "string", "strnum", "unassigned", or "undefined".
    # (typeof(s) ~ /unassigned|undefined/)? true: ...

    # The `length()` of some awk distributions may only support the string type.
    # gawk and mawk also support the array and number types. i.e. They can use `length(array)`
    return (length(s) == 0 || s == NONE)? true : false
}
# -----------
# Trim off whitespace characters on the left and right sides of the string.
# whitespace chars: [ \t\n\r\f\v]
#
# [[Usage, Trim, "Result(a new str)"]; ["trim(\"  aa bb  \")", "whitespace chars(left and right)", "\"aa bb\""]]
#
# ╭───┬───────────────────┬──────────────────────────────────┬───────────────────╮
# │ # │       Usage       │               Trim               │ Result(a new str) │
# ├───┼───────────────────┼──────────────────────────────────┼───────────────────┤
# │ 0 │ trim("  aa bb  ") │ whitespace chars(left and right) │ "aa bb"           │
# ╰───┴───────────────────┴──────────────────────────────────┴───────────────────╯
#
# Example
#
# ```awk
#     s = "  \t \t foo"
#
#     n = trim(s)
#     print n
#     # stdout: foo
#
#     print s
#     # This will output spaces, tabs and foo
# ```
#
# trim(s: string) -> string
function trim(s) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
    return s
}
# -----------
# Remove the quotation marks on the left and right sides.
#
# Example
# 
# ```awk
#     s = "\"\"awk\"\""
#
#     print s
#     # stdout: ""awk""
#
#     print dequotes(s)
#     # stdout: awk
# ```
#
# dequotes(s: string) -> string
function dequotes(s) {
    gsub(/^("|')+|("|')+$/, NONE, s)
    return s
}
# -----------
# If the file exists -> true
# Otherwise -> false
#
# [[Arg, Usage, Result]; [file, "is_file_exists(file)", "true or false"]]
#
# ╭───┬──────┬──────────────────────┬───────────────╮
# │ # │ Arg  │        Usage         │    Result     │
# ├───┼──────┼──────────────────────┼───────────────┤
# │ 0 │ file │ is_file_exists(file) │ true or false │
# ╰───┴──────┴──────────────────────┴───────────────╯
#
# Example
#
# ```awk
#     file = "/usr/lib/os-release"
#
#     if (is_file_exists(file))
#         printf("Ok, %s exists\n", file)"
#
#
#    f = "/tmp/a_non-existent_file.txt"
#    b = is_file_exists(f)
#
#    print_bool(b)
#    # stdout: false
# ```
#
# is_file_exists(f: string) -> bool
function is_file_exists(f) {
    # it's (!system()), not (system())
    return !system("test -e" SPACE f)
}
# -----------
#[test]
function test_cmd_exists(_, cmd, arg, arr_len, i) {
    cmd = "command"
    arr_len= split("-v type aa bb cc dd 1.2e-3 ff 0x09", arg, SPACE)

    print "arr.len(): " arr_len

    for (i in arg)
        print i, ":", arg[i]
    status = is_cmd_exists(cmd, arg, arr_len)
    print_bool(status)
}
# -----------
#[test]
function test_check_cmd() {
    WHICH_CMD = get_which_cmd()
    print "WHICH_CMD:", WHICH_CMD
    s = check_cmd("uname", "-m")
    print_bool(s)
}
# -----------
#[test]
function test_alice_s_fruit(_, s, fruit, my, alice) {
    s = ""
    fruit = "lychees"

    if (is_empty(s)) {
        print "s is empty\n",
            "OK, I knew there was nothing there."
    }
    # note: my[fruit] is my["lychees"], not my["fruit"]
    my[fruit] = 2

    if (is_empty(my[fruit])) {
        printf("Since the value of `my[fruit]` has already been defined earlier, don't be too sad.\n",
            "The `if` will not go through this branch.\n")
    } else {
        printf("Please note that there is a difference between a variable that is empty and has the value \"\" and a variable that is not empty and has the value 0.\n",
            "But in awk, if an int variable is uninitialized, it will automatically be set to 0.\n",
            "Fortunately, mawk/gawk can call `typeof()` to check the type of a variable. We can determine (unassigned|undefined). Unfortunately, some awk distros do not have `typeof()`\n")

        print (my[fruit] == 0)? "The sad thing is that I don't have any "                               fruit: (my[fruit] == 1)? "Only one, but no bad":                                                                                        "Woo-hoo! It's so exciting. I have many many", fruit
    }

    alice[fruit] = 5

    # note: (!false) = (true)
    if (!is_empty(alice[fruit]) && alice[fruit] > my[fruit])
        printf("Oh, no! Alice has %d %s.\nThis is unfair.\n", alice[fruit], fruit)
}
# -----------
#[test]
function test_file_existence() {
    if (is_file_exists("/usr/lib/os-release"))
        print "Ok, it exists."

    if (!is_file_exists("/etc/lib-release"))
        print "Oh no, it doesn't exist"
}
# -----------
function get_architecture(uname, _, a) {
    if (check_cmd("apt-cache") && check_cmd("dpkg-query"))
        a = get_cmd_out("dpkg,--print-architecture")
    else
        a = get_cmd_out(uname ",-m")

    # global 
    # Key: "llvm", Value: "x86_64"
    # Key: "deb", Value: "amd64"
    ARCH["llvm"] = "x86_64"

    parse_architecture(a, ARCH)
    #[test]
    # print "debug::get_architecture,\n", sty["green"] "llvm_arch:", sty["yellow"], arch["llvm"] "\n",
    # sty["blue"] "deb_arch:", sty["cyan"] arch["deb"]
}
# -----------
function parse_architecture(a, arch) {
    # While gawk supports `switch case` statements, some other `awk` distributions do not.

    # [[llvm_arch, deb_arch]; [x86_64, amd64], [aarch64, arm64], [armv7, "armhf or armel"], [arm, "armel"], [armv5te, armel], [i686, i386], [riscv64gc, riscv64], [powerpc64le, ppc64el], [s390x, s390x], [mips64el, mips64el], [mipsel, mipsel]]

    # note: It doesn't support all architectures.

    # `x86_64` must precede `i386` 
    
    # x86_64|amd64|x64
    if (a ~ /(x(86_)?|amd)64/) {
        arch["deb"] = "amd64"
        arch["llvm"] = "x86_64"

        # aarch64|armv8a|armv9|arm64
    } else if (a ~ /a(arch64|rm(v(8a|9)|64))/) {
        # aarch64-apple-darwin
        # aarch64-linux-android
        # aarch64-pc-windows-msvc
        # aarch64-unknown-linux-musl
        # aarch64-unknown-linux-gnu

        arch["llvm"] = "aarch64"
        arch["deb"] = "arm64"

        # armv7|armv8l|armhf|^arm$
    } else if (a ~ /arm(v(7|8l)|hf)|^arm$/) {
        # armv7-unknown-linux-gnueabihf
        # armv7-unknown-linux-musleabihf

        # android abi: https://developer.android.com/ndk/guides/abis.html
        # armv7-linux-androideabi, armeabi-v7a
        # https://developer.android.com/ndk/guides/cpu-arm-neon
        # thumbv7neon-linux-androideabi, Thumb2-mode ARMv7a Android with NEON

        arch["llvm"] = "armv7"
        arch["deb"] = "armhf"

        # armel|armv6
    } else if (a ~ /arm(el|v6)/) {
        arch["llvm"] = "arm"
        # On some systems, arm-unknown-linux-gnueabihf might be "armhf"
        # note: arm-unknown-linux-gnueabi and arm-unknown-linux-musleabi are "armel"
        arch["deb"] = "armel"

        # To be honest, I don't want to support the armv6 and v5 architectures.
        # Maybe one day I will remove or comment out these `else if`
    } else if (a ~ /arm(el|v5)/) {
        arch["llvm"] = "armv5te"
        arch["deb"] = "armel"
    } else if (a ~ /arm/) {
        # armv4 or older architectures are not supported, if none of the above arm architectures are matched then the default will be to fall back to arm64
        arch["llvm"] = "aarch64"
        arch["deb"] = "arm64"

        # i386 i486 i586 x86 x32 x86_32
    } else if (a ~ /x((86_)?32|86)|i[3-5]86/) {
        # note: On some systems it will output i386 even if it is i686.
        print "It does not support i386 and i486, only i586 and i686"
        arch["llvm"] = "i586"
        arch["deb"] = "i386"
    } else if (a ~ /i686/) {
        arch["llvm"] = "i686"
        arch["deb"] = "i386"

    } else if (a ~ /riscv64/) {
        arch["llvm"] = "riscv64gc"
        arch["deb"] = "riscv64"

    } else if (a ~ /powerpc64(el|le)?|ppc64(el|le)?/) {
        print "It does not support ppc64, only ppc64el"
        arch["llvm"] = "powerpc64le"
        arch["deb"] = "ppc64el"

    } else if (a ~ /s390/) {
        # regex: Use /s390/, not /s390x/

        arch["llvm"] = arch["deb"] = "s390x"

    } else if (a ~ /mips64/) {
        arch["llvm"] = arch["deb"] = "mips64el"

    } else if (a ~ /mips/) {
        # note: On mipsel devices, the output of `uname -m` may not be mipsle/mispel, but mips
        arch["llvm"] = arch["deb"] = "mipsel"

    } else {
        print sty["cyan"]
        print "╭────┬─────────────┬────────────────╮"
        print "│  # │  llvm_arch  │    deb_arch    │"
        print "├────┼─────────────┼────────────────┤"
        print "│  0 │ x86_64      │ amd64          │"
        print "│  1 │ aarch64     │ arm64          │"
        print "│  2 │ armv7       │ armhf or armel │"
        print "│  3 │ arm         │ armel          │"
        print "│  4 │ armv5te     │ armel          │"
        print "│  5 │ i686        │ i386           │"
        print "│  6 │ riscv64gc   │ riscv64        │"
        print "│  7 │ powerpc64le │ ppc64el        │"
        print "│  8 │ s390x       │ s390x          │"
        print "│  9 │ mips64el    │ mips64el       │"
        print "│ 10 │ mipsel      │ mipsel         │"
        print "╰────┴─────────────┴────────────────╯"
        print sty["green"] "Note: There is a difference between", sty["blue"] "arm-unknown-linux-gnueabi", sty["cyan"] "and", sty["yellow"] "arm-unknown-linux-gnueabihf." sty[0]
        print "On some systems, the latter may be", sty["yellow"] "armhf", sty[0] "instead of", sty["blue"] "armel."
        print sty["yellow"] "---------------------"
        # print "Adapting to different architectures is hard work. To be honest, I don't want to be that tired."        
        print sty["red"] "Unfortunately!\n",
        sty["blue"] "It does not support the", sty["magenta"] a, sty["cyan"] "architecture." sty[0] > STDERR
        exit 1
    }
}
# -----------
# Please do not remove the test function.
BEGIN {
    main()
    # test()
}
# -----------
