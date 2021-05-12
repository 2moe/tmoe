#!/usr/bin/env bash
set -e
cd ..
SHELL_FILE=$(find ./* | grep sh | tr '\n' ' ' | cut -d '%' -f 1)
ALL_SHARE_FILE=$(find ./share/* | tr '\n' ' ' | cut -d '%' -f 1)
unset ALL_SHELL_FILE
for i in ${SHELL_FILE}; do
    if [ ! -d "${i}" ]; then
        ALL_SHELL_FILE="${ALL_SHELL_FILE} ${i}"
    fi
done
printf "%s\n" "$ALL_SHELL_FILE"
unset SHARE_FILE
for i in ${ALL_SHARE_FILE}; do
    if [ ! -d "${i}" ]; then
        SHARE_FILE="${SHARE_FILE} ${i}"
    fi
done
printf "%s\n" "$SHARE_FILE"

#sed -i 's/zh_CN/en_US/g' ./*sh
INSTALL_FILE=./share/container/install
sed -i 's/zh_CN/en_US/g' ${ALL_SHELL_FILE} ./tools/gui/start* ${SHARE_FILE} ${INSTALL_FILE}
#sed -i 's@en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/@zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/@' ./*sh tools/*/*
#########
#sed -i 's@en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/@zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/@' ${ALL_SHELL_FILE}
#sed -i 's@a\\\en_US.UTF-8 UTF-8@a\\\zh_CN.UTF-8 UTF-8@' ${ALL_SHELL_FILE}
############
#sed -i 's@a\\\en_US.UTF-8 UTF-8@a\\\zh_CN.UTF-8 UTF-8@' tool.sh tools/*/*

#gentoo_lang
sed -i 's@en_US en_US@en_US zh_CN@g' ${INSTALL_FILE}
#sed -i 's@translation-update-en_US@translation-update-zh_CN@' ${INSTALL_FILE}
#sed -i 's@\^en_US@\^zh_CN@' tool.sh tools/*/*
#sed -i 's@\^en_US@\^zh_CN@' ${ALL_SHELL_FILE}

#sed -i 's@locale-gen en_US@locale-gen zh_CN@g' ./*sh tools/*/*

sed -i 's/114.114.114.114/1.0.0.1/' ${INSTALL_FILE}
sed -i 's/240c::6666/2606:4700:4700::1111/' ${INSTALL_FILE}
# sed -i 's@gitee.com/mo2/fzf-tab@github.com/Aloxaf/fzf-tab@g' zsh.sh
sed -i 's@gitee.com/mirrors/neofetch/raw/master/neofetch@raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch@g' ${INSTALL_FILE}
sed -i 's@https://gitee.com/mirrors/neofetch/raw/2b559cb8c62088dcbe997f6bb5a27002a9c22e27/neofetch@https://raw.githubusercontent.com/dylanaraps/neofetch/2b559cb8c62088dcbe997f6bb5a27002a9c22e27/neofetch@g' ${INSTALL_FILE}
#zsh.sh
sed -i 's@gitee.com/mirrors/oh-my-zsh/raw/master/templates/zshrc.zsh-template@raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/templates/zshrc.zsh-template@g' ${INSTALL_FILE} #zsh.sh
sed -i 's@gitee.com/mirrors/oh-my-zsh.git@github.com/ohmyzsh/ohmyzsh.git@g' ${INSTALL_FILE}                                                                                    #zsh.sh
#sed -i 's@gitee.com/mo2/zsh/raw/master/@raw.githubusercontent.com/2moe/tmoe-zsh/master/@g' ./*sh
sed -i 's@gitee.com/mo2/zsh/raw/master/@raw.githubusercontent.com/2moe/tmoe-zsh/master/@g' ${ALL_SHELL_FILE} ${SHARE_FILE}
sed -i 's!cdn.jsdelivr.net/gh/2moe/tmoe-zsh@master/.mirror/zsh!raw.githubusercontent.com/2moe/tmoe-zsh/master/zsh.sh!g' ${ALL_SHELL_FILE} ${SHARE_FILE}
#sed -i 's@gitee.com/mo2/zsh/raw/master/@raw.githubusercontent.com/2moe/tmoe-zsh/master/@g'

sed -i 's!cdn.jsdelivr.net/gh/2moe/tmoe-linux@master/.mirror/manager!raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh!g' ${ALL_SHELL_FILE} ${SHARE_FILE}
sed -i 's!cdn.jsdelivr.net/gh/2moe/tmoe-linux@master/.mirror/tool!raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh!g' ${ALL_SHELL_FILE} ${SHARE_FILE}
#cdn.jsdelivr.net/gh/2moe/tmoe-linux@master/.mirror/tool

sed -i 's@gitee.com/mo2/linux/raw/master/@raw.githubusercontent.com/2moe/tmoe-linux/master/@g' ${ALL_SHELL_FILE} ${SHARE_FILE}

sed -i 's@gitee.com/mo2/linux.git@github.com/2moe/tmoe-linux.git@g' ${SHARE_FILE} ${ALL_SHELL_FILE}

sed -i '/正在配置中文环境/d' ${INSTALL_FILE}
sed -i 's@###tmoe-github@@g' ${INSTALL_FILE} #zsh.sh
#sed -i 's@gitee.com/mo2/linux/raw/master/@raw.githubusercontent.com/2moe/tmoe-linux/master/@g' ./*sh ./tool/*sh tools/*/* tools/environment.sh

sed -i 's@gitee.com/mo2/linux\"@github.com/2moe/tmoe-linux\"@' ${ALL_SHELL_FILE} ${SHARE_FILE}
#sed -i 's@https://gitee.com/mo2/linux/issues@https://github.com/2moe/tmoe-linux/issues@g' manager.sh
sed -i 's@gitee.com/romkatv/powerlevel10k@github.com/romkatv/powerlevel10k@g' ${INSTALL_FILE}                   #zsh.sh
sed -i 's@gitee.com/mo2/zsh-syntax-highlighting@github.com/zsh-users/zsh-syntax-highlighting@g' ${INSTALL_FILE} #zsh.sh
sed -i 's@gitee.com/mo2/zsh-autosuggestions@github.com/zsh-users/zsh-autosuggestions@g' ${INSTALL_FILE}         #zsh.sh
#sed -i 's@gitee.com/mo2/linux@github.com/2moe/tmoe-linux@g' ./*sh ./tool/*sh tools/*/*
sed -i "s@https://gitee.com/mo2/linux/issues/I2EAVQ@https://github.com/2moe/tmoe-linux/issues/22@" share/container/list
