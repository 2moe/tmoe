#!/bin/bash
cd ..
ALL_SHELL_FILE=$(find ./* | grep sh | tr '\n' ' ' | cut -d '%' -f 1)
#sed -i 's/zh_CN/en_US/g' ./*sh
sed -i 's/zh_CN/en_US/g' ${ALL_SHELL_FILE}
#sed -i 's@en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/@zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/@' ./*sh tools/*/*
#########
#sed -i 's@en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/@zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/@' ${ALL_SHELL_FILE}
#sed -i 's@a\\\en_US.UTF-8 UTF-8@a\\\zh_CN.UTF-8 UTF-8@' ${ALL_SHELL_FILE}
############
#sed -i 's@a\\\en_US.UTF-8 UTF-8@a\\\zh_CN.UTF-8 UTF-8@' tool.sh tools/*/*

#gentoo_lang
sed -i 's@en_US en_US@en_US zh_CN@g' install.sh
#sed -i 's@translation-update-en_US@translation-update-zh_CN@' install.sh
#sed -i 's@\^en_US@\^zh_CN@' tool.sh tools/*/*
#sed -i 's@\^en_US@\^zh_CN@' ${ALL_SHELL_FILE}

#sed -i 's@locale-gen en_US@locale-gen zh_CN@g' ./*sh tools/*/*

sed -i 's/114.114.114.114/1.0.0.1/' install.sh
sed -i 's/240c::6666/2606:4700:4700::1111/' install.sh
sed -i 's@gitee.com/mo2/fzf-tab@github.com/Aloxaf/fzf-tab@g' zsh.sh
sed -i 's@gitee.com/mirrors/neofetch/raw/master/neofetch@raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch@g' install.sh zsh.sh
sed -i 's@gitee.com/mirrors/oh-my-zsh/raw/master/templates/zshrc.zsh-template@raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/templates/zshrc.zsh-template@g' install.sh zsh.sh
sed -i 's@gitee.com/mirrors/oh-my-zsh.git@github.com/ohmyzsh/ohmyzsh.git@g' install.sh zsh.sh
#sed -i 's@gitee.com/mo2/zsh/raw/master/@raw.githubusercontent.com/2moe/tmoe-zsh/master/@g' ./*sh
sed -i 's@gitee.com/mo2/zsh/raw/master/@raw.githubusercontent.com/2moe/tmoe-zsh/master/@g' ${ALL_SHELL_FILE}
sed -i 's@gitee.com/mo2/linux/raw/master/@raw.githubusercontent.com/2moe/tmoe-linux/master/@g' ${ALL_SHELL_FILE}
sed -i 's@gitee.com/mo2/linux.git@github.com/2moe/tmoe-linux.git@g' ${ALL_SHELL_FILE}
sed -i '/正在配置中文环境/d' install.sh
sed -i 's@###tmoe-github@@' install.sh zsh.sh
#sed -i 's@gitee.com/mo2/linux/raw/master/@raw.githubusercontent.com/2moe/tmoe-linux/master/@g' ./*sh ./tool/*sh tools/*/* tools/environment.sh

sed -i "s@URL='gitee.com/mo2/linux'@URL=='github.com/2moe/tmoe-linux'@" ${ALL_SHELL_FILE}

sed -i 's@gitee.com/mo2/powerlevel10k@github.com/romkatv/powerlevel10k@g' install.sh zsh.sh
sed -i 's@gitee.com/mo2/zsh-syntax-highlighting@github.com/zsh-users/zsh-syntax-highlighting@g' install.sh zsh.sh
sed -i 's@gitee.com/mo2/zsh-autosuggestions@github.com/zsh-users/zsh-autosuggestions@g' install.sh zsh.sh
#sed -i 's@gitee.com/mo2/linux@github.com/2moe/tmoe-linux@g' ./*sh ./tool/*sh tools/*/*
