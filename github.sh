#!/bin/bash
sed -i 's/zh_CN/en_US/g' ./debian-gui-install.bash
#sed -i 's/zh_CN/en_US/g' ./debian.sh
sed -i 's@raw.githubusercontent.com/2moe/tmoe-linux/master/@raw.githubusercontent.com/2moe/tmoe-linux/master/@g' ./*sh
sed -i 's@gitee.com/mo2/powerlevel10k@github.com/romkatv/powerlevel10k@g' ./installDebian.sh
sed -i 's@gitee.com/mo2/zsh-syntax-highlighting@github.com/zsh-users/zsh-syntax-highlighting@g' ./installDebian.sh
sed -i 's@gitee.com/mo2/zsh-autosuggestions@github.com/zsh-users/zsh-autosuggestions@g' ./installDebian.sh
