#!/usr/bin/env bash
if [ $(command -v curl) ]; then
    curl -Lvo /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
else
    wget -O /usr/local/bin/debian-i 'https://raw.githubusercontent.com/2moe/tmoe-linux/master/tool.sh'
fi
chmod +x /usr/local/bin/debian-i
echo "The developer of this tool changed the script name on May 4th, please update it again."
echo "2020-05-04更换了脚本名称，请再更新一遍"
