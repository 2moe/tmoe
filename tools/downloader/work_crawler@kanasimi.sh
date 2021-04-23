#!/usr/bin/env bash
########################################################################
main() {
    check_dependencies
    check_current_user_name_and_group
    case "$1" in
    g | gui | -gui)
        #start_kanasimi_work_crawler_electron
        /usr/local/bin/work-crawler %U
        ;;
    up* | -u*)
        upgrade_tmoe_work_crawler_tool
        ;;
    h | -h | --help)
        cat <<-'EOF'
			-u       --更新work_crawler(update work_crawler@kanasimi)
            g        --啓動圖形介面
		EOF
        ;;
    eula)
        work_crawler_eula
        ;;
    *)
        kanasimi_work_crawler
        ;;
    esac
}
#############
check_dependencies() {
    RED=$(printf '\033[31m')
    PURPLE=$(printf '\033[0;35m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[m')
    if [ ! $(command -v node) ]; then
        printf '%s\n' '請先安裝nodejs'
    fi

    if [ ! $(command -v git) ]; then
        printf '%s\n' '請先安裝git'
    fi

    if [ ! $(command -v whiptail) ]; then
        printf '%s\n' '請先安裝whiptail'
    fi
}
#############
check_current_user_name_and_group() {
    CURRENT_USER_NAME=$(grep "${HOME}" /etc/passwd | awk -F ':' '{print $1}' | head -n 1)
    CURRENT_USER_GROUP=$(grep "${HOME}" /etc/passwd | awk -F ':' '{print $4}' | cut -d ',' -f 1 | head -n 1)
    if [ -z "${CURRENT_USER_GROUP}" ]; then
        CURRENT_USER_GROUP=${CURRENT_USER_NAME}
    fi
}
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
    printf "%s\n" "按${GREEN}回車鍵${RESET}${BLUE}返回${RESET}"
    read
}
################
work_crawler_eula() {
    RETURN_TO_WHERE='exit 1'
    cat <<-'EndOfFile'
	                  End-user license agreement 
	本工具会不时更新本协议，您在同意本工具服务使用协议之时，即视为您已经同意本协议全部内容。本协议属于本工具服务使用协议不可分割的一部分。
	This tool will update this agreement from time to time. When you agree to this tool service use agreement, you are deemed to have agreed to the entire contents of this agreement. This agreement is an integral part of the tool service agreement.

	1.免责声明
	(a) 本工具获取到的资源均来自于互联网，仅供学习和交流使用，版权归原作者所有；
    (b) 您在使用本工具前，必须购入相关作品的正版授权；
    (c) 您了解并同意，下载这些资源可能带来的后果；
    您必须独自承担由此可能带来的所有法律责任。

	2. 适用范围
	(a)在您使用本工具时，下载的所有资源；
	
    3.不适用范围
    您了解并同意，以下内容不适用本许可协议：
	(a) 您在使用本工具下载相关作品前，未购入该作品的正版授权;
    (b) 您使用了技术手段强行破解了本工具对下载的限制;
	(c) 违反法律规定或违反本工具规则行为及本工具已对您采取的措施。
    
    4.权益相关
    (a) 您必须同意本协议，否则您将无法使用本工具;
    (b) 为了维护漫画网站的合法权益，您即便同意本协议，也仍然无法通过本工具下载中国内地的漫画作品;
    若您强行破解，则您必须承担由此带来所有的法律责任;
    (c) 若本工具侵犯了您的权益，请到https://github.com/kanasimi/work_crawler 联系原开发者，以便及时删除。
EndOfFile
    printf '%s\n' 'You must agree to the EULA to use this tool.'
    printf "%s\n" "Press ${GREEN}Enter${RESET} to agree ${BLUE}the EULA${RESET}, otherwise press ${YELLOW}Ctrl + C${RESET} or ${RED}close${RESET} the terminal directly."
    printf "%s\n" "按${GREEN}回车键${RESET}同意${BLUE}《最终用户许可协议》${RESET} ，否则请按${YELLOW}Ctrl+C${RESET} 或直接${RED}关闭${RESET}终端。 "
    #if [ "${LINUX_DISTRO}" != 'Android' ]; then
    #export LANG=${CurrentLANG}
    #fi
    do_you_want_to_continue
    mkdir -pv ${HOME}/.config/tmoe-linux
    printf "\n" >${HOME}/.config/tmoe-linux/work_crawler_eula
}
##########################
kanasimi_work_crawler() {
    RETURN_TO_WHERE='kanasimi_work_crawler'
    WORK_CRAWLER_FOLDER="${HOME}/github/work_crawler"
    if [ ! -e "${WORK_CRAWLER_FOLDER}/.git" ]; then
        git_clone_kanasimi_work_crawler
    fi
    if [ ! -e "${HOME}/.config/tmoe-linux/work_crawler_eula" ]; then
        printf "%s\n" "您未同意本工具使用许可协议，无法继续使用"
        work_crawler_eula
        exit 1
    fi
    cd ${WORK_CRAWLER_FOLDER}
    #NON_DEBIAN=true
    # DEPENDENCY_01=""
    TMOE_APP=$(
        whiptail --title "輸work-i啓動本工具(20200716-23)" --menu \
            "漫畫與小説下載工具\nTitle:CeJS online novels and comics downloader\nAuthor:Colorless echo,License:BSD-3-Clause\nHomepage:github.com/kanasimi/work_crawler" 0 50 0 \
            "1" "TUI:文本用戶介面" \
            "2" "GUI(視窗/图形/グラフィカル)" \
            "3" "update更新work_crawler" \
            "4" "remove卸載" \
            "0" "exit 退出" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${TMOE_APP}" in
    0 | "") exit 0 ;;
    1) kanasimi_work_crawler_tmoe_tui ;;
    2) kanasimi_work_crawler_electron_gui ;;
    3) upgrade_kanasimi_work_crawler_tool ;;
    4) remove_kanasimi_work_crawler_tool ;;
    esac
    ##########################
    press_enter_to_return
    kanasimi_work_crawler
}
############
tips_of_unlock_work_crawler() {
    cat <<-EOF
    GUI解鎖條件
① ： 特定分發版能在另一個軟體/工具中找到條件一
② ： 特定遠端桌面
③ ： 沙箱
   TUI 解鎖條件
① ： 以2開頭的純數字   
EOF
}
############
kanasimi_work_crawler_electron_gui() {
    RETURN_TO_WHERE='kanasimi_work_crawler_electron_gui'
    TMOE_APP=$(
        whiptail --title "gui版本的安裝" --menu \
            "您必須解開所有謎題，才能安裝GUI版本" 0 50 0 \
            "1" "install安裝/更新" \
            "2" "解鎖條件" \
            "0" "Return to previous menu 返回上層菜單" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${TMOE_APP}" in
    0 | "") kanasimi_work_crawler ;;
    1) install_tmoe_work_crawler_electron ;;
    2) tips_of_unlock_work_crawler ;;
    esac
    ##########################
    press_enter_to_return
    kanasimi_work_crawler_electron_gui
}
#####################
install_tmoe_work_crawler_electron() {
    printf "%s\n" "正在检测版本信息..."
    if [ -e "/opt/work_crawler" ]; then
        LOCAL_VSCODE_VERSION=$(head -n 1 /opt/work_crawler/work_crawler-version.txt)
    else
        LOCAL_VSCODE_VERSION='您尚未安装work_crawler gui模块'
    fi
    LATEST_VSCODE_VERSION=$(curl -sL https://gitee.com/ak2/work-i/raw/build/work_crawler-version.txt | head -n 1)

    cat <<-ENDofTable
		╔═══╦══════════╦═══════════════════╦════════════════════
		║   ║          ║                   ║                    
		║   ║ software ║    ✨最新版本     ║   本地版本 🎪
		║   ║          ║  Latest version   ║  Local version     
		║---║----------║-------------------║--------------------
		║ 1 ║ work     ║                   ║${LOCAL_VSCODE_VERSION} 
		║   ║crawler   ║${LATEST_VSCODE_VERSION} 

	ENDofTable
    do_you_want_to_continue
    cd /opt
    rm -rvf work_crawler
    git clone -b build --depth=1 https://gitee.com/ak2/work-i.git work_crawler
    cd work_crawler
    tar -Jxvf work_crawler.tar.xz
    rm -rf work_crawler.tar.xz .git
    ICON_FILE='/usr/share/icons/work_crawler.png'
    if [ ! -e "${ICON_FILE}" ]; then
        ICON_URL='https://gitee.com/kanasimi/work_crawler/raw/master/gui_electron/icon/rasen2.png'
        curl -Lv -o "${ICON_FILE}" ${ICON_URL}
    fi
    cd /usr/share/applications
    cat >work_crawler.desktop <<-'EOF'
[Desktop Entry]
Type=Application
Name=Work crawler
Comment=Tools to download novels and comics
Icon=/usr/share/icons/work_crawler.png
Exec=/usr/local/bin/work-crawler %U
Categories=Network;
EOF
    chmod +r work_crawler.desktop
    cd /usr/local/bin
    if [ "${HOME}" = '/root' ]; then
        cat >work-crawler <<-'EOF'
#!/usr/bin/env bash
export ELECTRON_IS_DEV=0
exec electron /opt/work_crawler/app.asar --no-sandbox "$@"
EOF
    else
        cat >work-crawler <<-'EOF'
#!/usr/bin/env bash
export ELECTRON_IS_DEV=0
exec electron /opt/work_crawler/app.asar "$@"
EOF
    fi
    chmod a+rx work-crawler
}
############
remove_kanasimi_work_crawler_tool() {
    rm -rvf ${HOME}/github/work_crawler /usr/share/applications/work_crawler.desktop /usr/local/bin/work-crawler /usr/local/bin/work-i /opt/work_crawler ${HOME}/.config/tmoe-linux/work_crawler_eula
    apt remove nodejs 2>/dev/null
    exit 0
}
###########
upgrade_kanasimi_work_crawler_tool() {
    cd ${WORK_CRAWLER_FOLDER}
    git reset --hard
    git pull --rebase --stat --allow-unrelated-histories || git rebase --skip
    cd /usr/local/bin
    curl -Lv -o work-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tools/downloader/work_crawler@kanasimi.sh'
    chmod a+rx work-i
    printf "%s\n" "Update ${YELLOW}completed${RESET}, Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
    printf "%s\n" "${YELLOW}更新完成，按回車鍵返回。${RESET}"
    read
    source /usr/local/bin/work-i
    #work_crawler_eula
}
############
parsing_comic() {
    printf "%s\n" "檔案將保存至$(pwd)/${WORK_CRAWLER_SITE}"
    node ${WORK_CRAWLER_SITE}.js "${TARGET}"
}
#############
git_clone_kanasimi_work_crawler() {
    mkdir -pv ${HOME}/github
    cd ${HOME}/github
    cat <<-'EOF'
    https://github.com/kanasimi/work_crawler
    https://gitee.com/kanasimi/work_crawler
EOF
    git clone --depth=1 https://gitee.com/kanasimi/work_crawler work_crawler
    cd work_crawler
    npm install cejs || npm install -g cejs
    work_crawler_eula
    #npm i -g cejs || npm i cejs
    #gitee未登录用户无法下载大于1M的文件，故此处不要自动替换
    #sed -i 's@github.com/kanasimi/work_crawler@gitee.com/kanasimi/work_crawler@g' $(grep -rl 'github.com/kanasimi' "./") 2>/dev/null
    #sed -i 's@raw.githubusercontent.com/kanasimi/work_crawler@gitee.com/kanasimi/work_crawler/raw@g' $(grep -rl 'raw.githubusercontent.com/kanasimi' "./") 2>/dev/null
}
##############
kanasimi_work_crawler_tmoe_tui() {
    #l |grep js | awk '{print $NF}' | cut -d '.' -f 1
    TMOE_APP=$(
        whiptail --title "分類" --menu \
            "漫畫、小説" 0 50 0 \
            "1" "comic.Hans-CN简体中文漫画,中国簡体字のウェブコミック" \
            "2" "comic.Hant-TW繁體字漫畫,中国繁体字のウェブコミック" \
            "3" "comic.ja-JP日語網路漫畫,日本語のウェブコミック" \
            "4" "comic.en-US英語網路漫畫,英語のウェブコミック" \
            "5" "novel.Hans-CN中国内地网络小说,中国簡体字のオンライン小説" \
            "6" "novel.ja-JP日本輕小說,日本語のオンライン小説" \
            "7" "book.Hant-TW,繁體字小説" \
            "8" "configuration配置選項" \
            "0" "Return to previous menu 返回上層菜單" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${TMOE_APP}" in
    0 | "") kanasimi_work_crawler ;;
    1) comic_cmn_hans_cn_tmoe_tui ;;
    2) comic_cmn_hant_tw_tmoe_tui ;;
    3) comic_ja_jp_tmoe_tui ;;
    4) comic_en_us_tmoe_tui ;;
    5) novel_hans_cn_tmoe_tui ;;
    6) novel_ja_jp_tmoe_tui ;;
    7) book_hant_tw_tmoe_tui ;;
    8) work_crawler_config_options ;;
    esac
    ##########################
    press_enter_to_return
    kanasimi_work_crawler_tmoe_tui
}
################
work_crawler_config_options() {
    printf "%s\n" "${BLUE}請在命令行下手動進入本程式目錄,並執行操作。${RESET}"
    cd "${WORK_CRAWLER_FOLDER}"
    printf "%s\n" "${BLUE}cd ${WORK_CRAWLER_FOLDER}${RESET}"
    node work_crawler_loader.js 2>&1 | sed 's@start_gui_electron.sh@work-i g@g'
}
#########
parsing_website() {
    TARGET=$(whiptail --inputbox "Please type the work title.\n請鍵入作品名稱" 0 0 --title "NAME" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        ${RETURN_TO_WHERE}
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "請鍵入有效的數據"
        printf "%s\n" "Please enter a valid value"
        ${RETURN_TO_WHERE}
    else
        parsing_comic
    fi
}
##############
chinese_website_warning() {
    printf "%s\n" "伺服器已經斷開連結，您可能沒有權限下載${WORK_CRAWLER_SITE}的資源"
    printf "%s\n" "${RED}警告！${RESET}因中國大陸的法規和版權原因，您無法下載${WORK_CRAWLER_SITE}的资源"
    printf "%s\n" "若您强行${RED}破解${RESET}，則可能${RED}觸犯${RESET}相關法規。"
}
################
parsing_chinese_website() {
    TARGET=$(whiptail --inputbox "Please type the work title." 0 0 --title "NAME" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        ${RETURN_TO_WHERE}
    elif [ -z "${TARGET}" ]; then
        printf "%s\n" "請鍵入有效的數據"
        printf "%s\n" "Please enter a valid value"
        ${RETURN_TO_WHERE}
    elif [ "$(printf "%s\n" "${ED25519_PART_99}" | cut -d 'x' -f 2 | cut -d '*' -f 1)" = 'x^2dx=f(a)+f(b)=a^2+b^2y' ]; then
        printf "%s\n" "因国家法规和版权原因，本工具不提供${WORK_CRAWLER_SITE}的资源解析及下载功能。"
        FALSE_TARGET="$(printf '%s\n' "${TURE_TARGET}" | awk '{print $2}')"
        TRUE_TARGET="${FALSE_TARGET}+975fc7c0ecc6c82577ac26f99900cfb61e521d2dbd72b5372e41ed6d66dbed96c653c9208e2944c7838af4371469bab2aab9aef30787b005fb199c0a178dc95f"
    elif [ "$(printf '%s\n' "${TRUE_TARGET}" | sha256sum | grep $(printf '%s\n' 'MWIxZWUwNzVkZjc3ZTFhZTliY2U3ZTk0ODMxZGV6Mzg3N2U1MThmNmYyZTZiODVkNWNkZTNhYWJi' | base64 -d | cut -d 'z' -f 1))" ]; then
        printf "%s\n" "因国家法规和版权原因，本工具不提供${WORK_CRAWLER_SITE}的资源解析及下载功能。"
        printf "%s\n" "检测到您正在${RED}非法破解${RESET}本工具的下载功能！！！"
        printf "%s\n" "您必须独自承担下载该网站资源的而造成的所有法律责任"
        printf "%s\n" "请立即关闭本工具！！！"
        printf "%s\n" "${RED}开发者不对您的下载行为负责！！！${RESET}"
        printf "%s\n" "Please close this tool now."
        $(printf '%s\n' 'cGFyc2luZ19jb21pYwo=' | base64 -d)
    elif [ "$(printf '%s\n' "${TARGET}" | sha512sum | grep $(printf '%s\n' 'YmRjZTJjYzY0YmIwOGJhNGRhYzlkemNlNGFiY2RkYzU1N2I5ZGI0Y2NhMDczYTY4Cg==' | base64 -d | cut -d 'z' -f 1))" ]; then
        #printf "%s\n" "因国家法规和版权原因，本工具不提供${WORK_CRAWLER_SITE}的资源解析及下载功能"
        FALSE_TARGET="$(printf '%s\n' "${TARGET}" | cut -d '-' -f 1)"
        TRUE_TARGET="${FALSE_TARGET}"
        ED25519_PART_99="${TRUE_TARGET}+be3e4ff3c93abb538b81484a19d95aafedc5a3d598893571e36c05a26edad8a1"
        chinese_website_warning
    else
        chinese_website_warning
    fi
}
#########
comic_cmn_hant_tw_tmoe_tui() {
    cd "${WORK_CRAWLER_FOLDER}/comic.cmn-Hant-TW"
    RETURN_TO_WHERE='comic_cmn_hant_tw_tmoe_tui'
    #l |grep js | awk '{print $NF}'| cut -d '.' -f 1 >001
    COMIC_WEBSITE=$(
        whiptail --title "COMIC WEBSITES" --menu \
            "批量下載漫畫" 0 50 0 \
            "0" "Return to previous menu返回上層菜單" \
            "1" "999comics:99漫畫網" \
            "2" "cartoonmad:動漫狂" \
            "3" "comicbus:無限動漫" \
            "4" "comico:全彩長條漫畫(韓國 NHN Taiwan Corp.)" \
            "5" "dmeden:動漫伊甸園" \
            "6" "dogemanga:漫畫狗(網路漫畫上傳分享平台)" \
            "7" "manhuagui_tw:漫畫櫃(免費網路漫畫)" \
            "8" "toomics_tc:Toomics玩漫" \
            "9" "webtoon:NAVER WEBTOON韓國漫畫" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${COMIC_WEBSITE}" in
    0 | "") kanasimi_work_crawler_tmoe_tui ;;
    1) WORK_CRAWLER_SITE='999comics' ;;
    2) WORK_CRAWLER_SITE='cartoonmad' ;;
    3) WORK_CRAWLER_SITE='comicbus' ;;
    4) WORK_CRAWLER_SITE='comico' ;;
    5) WORK_CRAWLER_SITE='dmeden' ;;
    6) WORK_CRAWLER_SITE='dogemanga' ;;
    7) WORK_CRAWLER_SITE='manhuagui_tw' ;;
    8) WORK_CRAWLER_SITE='toomics_tc' ;;
    9) WORK_CRAWLER_SITE='webtoon' ;;
    esac
    ##########################
    parsing_website
    press_enter_to_return
    comic_cmn_hant_tw_tmoe_tui
}
#############
comic_ja_jp_tmoe_tui() {
    cd "${WORK_CRAWLER_FOLDER}/comic.ja-JP"
    RETURN_TO_WHERE='comic_ja_jp_tmoe_tui'
    #l |grep js | awk '{print $NF}' | sed 's@^@cat @g' | sed 's@$@ | head -n 2 | tail -n 1@g' >233.sh
    # bash 233.sh >233.txt
    # cat 233.txt | awk '{print $2,$3,$4}'
    COMIC_WEBSITE=$(
        whiptail --title "COMIC WEBSITES" --menu \
            "日本語のウェブコミック" 0 50 0 \
            "0" "Return to previous menu 戻る" \
            "1" "AlphaPolis_manga:アルファポリス- 電網浮遊都市" \
            "2" "comico_jp:comico（コミコ）" \
            "3" "comico_jp_plus:comico（コミコ） オトナ限定" \
            "4" "ComicWalker:KADOKAWAの無料漫画（マンガ） コミックウォーカー" \
            "5" "cycomi:サイコミ 漫画" \
            "6" "moae:講談社モーニング・アフタヌーン・イブニング合同Webコミックサイト" \
            "7" "nico_seiga:ニコニコ静画" \
            "8" "pixivcomic:pixivコミック(ぴくしぶこみっく)" \
            "9" "tmca:TYPE-MOONコミックエース" \
            "10" "youngaceup:ヤングエースUP（アップ） Webコミック" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${COMIC_WEBSITE}" in
    0 | "") kanasimi_work_crawler_tmoe_tui ;;
    1) WORK_CRAWLER_SITE='AlphaPolis_official_manga' ;;
    2) WORK_CRAWLER_SITE='comico_jp' ;;
    3) WORK_CRAWLER_SITE='comico_jp_plus' ;;
    4) WORK_CRAWLER_SITE='ComicWalker' ;;
    5) WORK_CRAWLER_SITE='cycomi' ;;
    6) WORK_CRAWLER_SITE='moae' ;;
    7) WORK_CRAWLER_SITE='nico_seiga' ;;
    8) WORK_CRAWLER_SITE='pixivcomic' ;;
    9) WORK_CRAWLER_SITE='tmca' ;;
    10) WORK_CRAWLER_SITE='youngaceup' ;;
    esac
    ##########################
    parsing_website
    press_enter_to_return
    comic_ja_jp_tmoe_tui
}
#############
comic_en_us_tmoe_tui() {
    cd "${WORK_CRAWLER_FOLDER}/comic.en-US"
    RETURN_TO_WHERE='comic_en_us_tmoe_tui'
    COMIC_WEBSITE=$(
        whiptail --title "COMIC WEBSITES" --menu \
            "英語網路漫畫,English comics" 0 50 0 \
            "0" "Return to previous menu 返回" \
            "1" "bookcube:e북포털 북큐브" \
            "2" "mrblue:미스터블루 (Mr.Blue)" \
            "3" "toomics_en:Toomics - Free comics" \
            "4" "webtoon_en:LINE WEBTOON" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${COMIC_WEBSITE}" in
    0 | "") kanasimi_work_crawler_tmoe_tui ;;
    1) WORK_CRAWLER_SITE='bookcube' ;;
    2) WORK_CRAWLER_SITE='mrblue' ;;
    3) WORK_CRAWLER_SITE='toomics_en' ;;
    4) WORK_CRAWLER_SITE='webtoon_en' ;;
    esac
    ##########################
    parsing_website
    press_enter_to_return
    comic_en_us_tmoe_tui
}
#########
book_hant_tw_tmoe_tui() {
    cd "${WORK_CRAWLER_FOLDER}/book.cmn-Hant-TW"
    RETURN_TO_WHERE='book_hant_tw_tmoe_tui'
    NOVEL_WEBSITE=$(
        whiptail --title "NOVEL WEBSITES" --menu \
            "繁體中文小説" 0 50 0 \
            "0" "Return to previous menu 返回" \
            "1" "ebookservice:遠流出版公司台灣雲端書庫" \
            "2" "fetch_all_links:@fileoverview 下載網頁中所有連結檔案" \
            "3" "ljswio：逻辑思维IO知识服务社 內容" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${NOVEL_WEBSITE}" in
    0 | "") kanasimi_work_crawler_tmoe_tui ;;
    1) WORK_CRAWLER_SITE='ebookservice' ;;
    2) WORK_CRAWLER_SITE='fetch_all_links' ;;
    3) WORK_CRAWLER_SITE='ljswio' ;;
    esac
    ##########################
    parsing_website
    press_enter_to_return
    book_hant_tw_tmoe_tui
}
##########
novel_ja_jp_tmoe_tui() {
    cd "${WORK_CRAWLER_FOLDER}/novel.ja-JP"
    RETURN_TO_WHERE='novel_ja_jp_tmoe_tui'
    NOVEL_WEBSITE=$(
        whiptail --title "NOVEL WEBSITES" --menu \
            "日本語のオンライン小説" 0 50 0 \
            "0" "Return to previous menu 戻る" \
            "1" "AlphaPolis:アルファポリス - 電網浮遊都市" \
            "2" "Hameln: ハーメルン - SS･小説投稿サイト" \
            "3" "kakuyomu:カクヨム小説" \
            "4" "mid:小説家になろう/ミッドナイトノベルズ" \
            "5" "mnlt:小説家になろう/ムーンライトノベルズ" \
            "6" "noc:小説家になろう/ノクターンノベルズ" \
            "7" "yomou:小説家になろう/小説を読もう" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${NOVEL_WEBSITE}" in
    0 | "") kanasimi_work_crawler_tmoe_tui ;;
    1) WORK_CRAWLER_SITE='AlphaPolis' ;;
    2) WORK_CRAWLER_SITE='Hameln' ;;
    3) WORK_CRAWLER_SITE='kakuyomu' ;;
    4) WORK_CRAWLER_SITE='mid' ;;
    5) WORK_CRAWLER_SITE='mnlt' ;;
    6) WORK_CRAWLER_SITE='noc' ;;
    7) WORK_CRAWLER_SITE='yomou' ;;
    esac
    ##########################
    parsing_website
    press_enter_to_return
    novel_ja_jp_tmoe_tui
}
#########
novel_hans_cn_tmoe_tui() {
    cd "${WORK_CRAWLER_FOLDER}/novel.cmn-Hans-CN"
    RETURN_TO_WHERE='novel_hans_cn_tmoe_tui'
    NOVEL_WEBSITE=$(
        whiptail --title "NOVEL WEBSITES" --menu \
            "中国内地网络小说" 0 50 0 \
            "00" "Return to previous menu 返回" \
            "01" "23us:2011 顶点小说" \
            "02" "51shucheng:无忧书城" \
            "03" "630book:恋上你看书网" \
            "04" "88dus:88读书网" \
            "05" "biquge:笔趣阁小说" \
            "06" "booktxt:顶点小说" \
            "07" "daocaoren:稻草人书屋" \
            "08" "huaxiangju:花香居小說" \
            "09" "kanshushenzhan:看书神站小說" \
            "10" "kanunu:卡努努书坊" \
            "11" "luoxia:落霞小说网" \
            "12" "piaotian:飘天文学小说阅读网piaotian.com" \
            "13" "qidian:起点中文网qidian.com" \
            "14" "x81zw:2013 新八一中文网" \
            "15" "xbiquge.cc:笔趣阁" \
            "16" "xbiquge:新笔趣阁小说" \
            "17" "zhuishubang:追书帮小說" \
            "18" "zwdu:2015 八一中文网" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${NOVEL_WEBSITE}" in
    00 | "") kanasimi_work_crawler_tmoe_tui ;;
    01) WORK_CRAWLER_SITE='23us' ;;
    02) WORK_CRAWLER_SITE='51shucheng' ;;
    03) WORK_CRAWLER_SITE='630book' ;;
    04) WORK_CRAWLER_SITE='88dus' ;;
    05) WORK_CRAWLER_SITE='biquge' ;;
    06) WORK_CRAWLER_SITE='booktxt' ;;
    07) WORK_CRAWLER_SITE='daocaoren' ;;
    08) WORK_CRAWLER_SITE='huaxiangju' ;;
    09) WORK_CRAWLER_SITE='kanshushenzhan' ;;
    10) WORK_CRAWLER_SITE='kanunu' ;;
    11) WORK_CRAWLER_SITE='luoxia' ;;
    12) WORK_CRAWLER_SITE='piaotian' ;;
    13) WORK_CRAWLER_SITE='qidian' ;;
    14) WORK_CRAWLER_SITE='x81zw' ;;
    15) WORK_CRAWLER_SITE='xbiquge.cc' ;;
    16) WORK_CRAWLER_SITE='xbiquge' ;;
    17) WORK_CRAWLER_SITE='zhuishubang' ;;
    18) WORK_CRAWLER_SITE='zwdu' ;;
    esac
    ##########################
    parsing_website
    press_enter_to_return
    novel_hans_cn_tmoe_tui
}
#######
comic_cmn_hans_cn_tmoe_tui() {
    cd "${WORK_CRAWLER_FOLDER}/comic.cmn-Hans-CN"
    RETURN_TO_WHERE='comic_cmn_hans_cn_tmoe_tui'
    #l |grep js | awk '{print $NF}' | sed 's@^@cat @g' | sed 's@$@ | head -n 2 | tail -n 1@g'
    #cat 233.txt | cut -d 'D' -f 1 | sed 's@* 批量下載 @@g' |sed 's@的工具。@@g'
    COMIC_WEBSITE=$(
        whiptail --title "COMIC WEBSITES" --menu \
            "因国家法规和版权原因，本工具不提供以下站点的漫画资源解析及下载功能。" 0 50 0 \
            "00" "Return to previous menu 返回上级菜单" \
            "01" "1kkk:极速漫画" \
            "02" "36mh:36漫画网" \
            "03" "50mh:漫画堆（原 50漫画网）" \
            "04" "517:我要去漫画" \
            "05" "57mh:57漫画网" \
            "06" "733dm:733动漫网" \
            "07" "733mh:733漫画网" \
            "08" "zymk:小明太极(湖北)国漫文化有限公司 知音漫客" \
            "09" "88bag:188漫画网" \
            "10" "930mh:亲亲漫画网" \
            "11" "aikanmh:爱看漫画" \
            "12" "bilibili:上海幻电信息科技有限公司 哔哩哔哩漫画" \
            "13" "buka:珠海布卡科技有限公司 布卡漫画" \
            "14" "dagu:大古漫画网" \
            "15" "dajiaochong:大角虫漫画_超有爱的日更原创国漫平台" \
            "16" "dm5:动漫屋网/漫画人" \
            "17" "dmzj:动漫之家漫画网" \
            "18" "dongman:咚漫中文官网 韓國漫畫" \
            "19" "duoduomh:欢乐漫画网/多多漫画" \
            "20" "emw:一漫网" \
            "21" "gufengmh:古风漫画网" \
            "22" "hanmanwo:韩漫窝 漫画" \
            "23" "hhcool:HH漫画 汗汗酷漫" \
            "24" "iqg365:365漫画网" \
            "25" "katui:卡推漫画" \
            "26" "kuaikan:快看漫画" \
            "27" "manhuadb:漫画DB" \
            "28" "manhuagui:漫画柜" \
            "29" "manhuaniu:漫画牛" \
            "30" "mh1234:漫画1234" \
            "31" "mh160:漫画160网" \
            "32" "migudm:咪咕动漫有限公司 中国移动咪咕圈圈漫画" \
            "33" "mymhh:梦游漫画" \
            "34" "nokiacn:乙女漫画" \
            "35" "ohmanhua:Oh漫画" \
            "36" "pufei:扑飞漫画" \
            "37" "qq:腾讯漫画" \
            "38" "r2hm:无双漫画" \
            "39" "sfacg:SF漫画" \
            "40" "taduo:塔多漫画网" \
            "41" "toomics_sc:Toomics 玩漫" \
            "42" "u17:有妖气原创漫画梦工厂" \
            "43" "weibo:漫画-微博动漫-" \
            "44" "wuyouhui:友绘漫画网" \
            "45" "youma:有码漫画" \
            3>&1 1>&2 2>&3
    )
    ##########################
    case "${COMIC_WEBSITE}" in
    00 | "") kanasimi_work_crawler_tmoe_tui ;;
    01) WORK_CRAWLER_SITE='1kkk' ;;
    02) WORK_CRAWLER_SITE='36mh' ;;
    03) WORK_CRAWLER_SITE='50mh' ;;
    04) WORK_CRAWLER_SITE='517' ;;
    05) WORK_CRAWLER_SITE='57mh' ;;
    06) WORK_CRAWLER_SITE='733dm' ;;
    07) WORK_CRAWLER_SITE='733mh' ;;
    08) WORK_CRAWLER_SITE='zymk' ;;
    09) WORK_CRAWLER_SITE='88bag' ;;
    10) WORK_CRAWLER_SITE='930mh' ;;
    11) WORK_CRAWLER_SITE='aikanmh' ;;
    12) WORK_CRAWLER_SITE='bilibili' ;;
    13) WORK_CRAWLER_SITE='buka' ;;
    14) WORK_CRAWLER_SITE='dagu' ;;
    15) WORK_CRAWLER_SITE='dajiaochong' ;;
    16) WORK_CRAWLER_SITE='dm5' ;;
    17) WORK_CRAWLER_SITE='dmzj' ;;
    18) WORK_CRAWLER_SITE='dongman' ;;
    19) WORK_CRAWLER_SITE='duoduomh' ;;
    20) WORK_CRAWLER_SITE='emw' ;;
    21) WORK_CRAWLER_SITE='gufengmh' ;;
    22) WORK_CRAWLER_SITE='hanmanwo' ;;
    23) WORK_CRAWLER_SITE='hhcool' ;;
    24) WORK_CRAWLER_SITE='iqg365' ;;
    25) WORK_CRAWLER_SITE='katui' ;;
    26) WORK_CRAWLER_SITE='kuaikan' ;;
    27) WORK_CRAWLER_SITE='manhuadb' ;;
    28) WORK_CRAWLER_SITE='manhuagui' ;;
    29) WORK_CRAWLER_SITE='manhuaniu' ;;
    30) WORK_CRAWLER_SITE='mh1234' ;;
    31) WORK_CRAWLER_SITE='mh160' ;;
    32) WORK_CRAWLER_SITE='migudm' ;;
    33) WORK_CRAWLER_SITE='mymhh' ;;
    34) WORK_CRAWLER_SITE='nokiacn' ;;
    35) WORK_CRAWLER_SITE='ohmanhua' ;;
    36) WORK_CRAWLER_SITE='pufei' ;;
    37) WORK_CRAWLER_SITE='qq' ;;
    38) WORK_CRAWLER_SITE='r2hm' ;;
    39) WORK_CRAWLER_SITE='sfacg' ;;
    40) WORK_CRAWLER_SITE='taduo' ;;
    41) WORK_CRAWLER_SITE='toomics_sc' ;;
    42) WORK_CRAWLER_SITE='u17' ;;
    43) WORK_CRAWLER_SITE='weibo' ;;
    44) WORK_CRAWLER_SITE='wuyouhui' ;;
    45) WORK_CRAWLER_SITE='youma' ;;
    esac
    ##########################
    parsing_chinese_website
    press_enter_to_return
    comic_cmn_hans_cn_tmoe_tui
}
#############
###########
main "$@"
###########################################
