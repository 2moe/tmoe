bash -c "$(curl -Lv 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
if [ ! $(command -v curl) ]; then
    bash -c "$(wget -O- 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
fi
