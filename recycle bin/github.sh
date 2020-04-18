#!/bin/bash
cd ..
sed -i 's/zh_CN/en_US/g' ./*sh
sed -i 's@en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/@zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/@' ./*sh
sed -i 's@en_US en_US@en_US zh_CN@g' ./installDebian.sh
sed -i 's@locale-gen en_US@locale-gen zh_CN@g' ./*sh
#sed -i 's/zh_CN/en_US/g' ./debian.sh
sed -i '/正在配置中文环境/d' ./installDebian.sh
sed -i 's@gitee.com/mo2/linux/raw/master/@raw.githubusercontent.com/2moe/tmoe-linux/master/@g' ./*sh
sed -i 's@gitee.com/mo2/powerlevel10k@github.com/romkatv/powerlevel10k@g' ./installDebian.sh
sed -i 's@gitee.com/mo2/zsh-syntax-highlighting@github.com/zsh-users/zsh-syntax-highlighting@g' ./installDebian.sh
sed -i 's@gitee.com/mo2/zsh-autosuggestions@github.com/zsh-users/zsh-autosuggestions@g' ./installDebian.sh
