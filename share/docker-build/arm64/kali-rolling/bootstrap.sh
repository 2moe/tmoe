#!/usr/bin/env bash
#####################
CUR=$(pwd)
#SOURCES_LIST="${CUR}/../sources.list"
unset DISTRO_CODE
DEBIAN_CHROOT="kali"
ARCH_TYPE=arm64
KALI_URL="http://http.kali.org/kali/"
KALI_URL_02="https://mirrors.ustc.edu.cn/kali/"
DISTRO_CODE="kali-rolling"
#$echo ${DISTRO_CODE}
###################
sudo apt update
sudo apt install -y debootstrap
##################
cd /usr/share/debootstrap/scripts
if [[ ! -e ${DISTRO_CODE} ]]; then
    sudo ln -svf kali ${DISTRO_CODE}
fi

cd -

if [[ -d "/tmp" ]]; then
    cd /tmp
else
    mkdir -pv ${HOME}/.cache/tmp
    cd ${HOME}/.cache/tmp
fi

sudo debootstrap --no-check-gpg --arch ${ARCH_TYPE} --components=main,non-free,contrib --variant=minbase --include=init,locales,ca-certificates,openssl,curl ${DISTRO_CODE} ${DEBIAN_CHROOT} ${KALI_URL} || sudo debootstrap --no-check-gpg --arch ${ARCH_TYPE} --components=main,non-free,contrib --variant=minbase --include=init,locales,ca-certificates,openssl,curl ${DISTRO_CODE} ${DEBIAN_CHROOT} ${KALI_URL_02}

sudo mkdir -pv ${DEBIAN_CHROOT}/run/systemd
sudo su -c "echo 'docker' >${DEBIAN_CHROOT}/run/systemd/container"

#sed -i "s@hirsute@${DISTRO_CODE}@g" ${SOURCES_LIST}
#sudo cp -fv ${SOURCES_LIST} ${DEBIAN_CHROOT}/etc/apt/sources.list
sudo rm -rfv ${DEBIAN_CHROOT}/dev/*
cd ${DEBIAN_CHROOT}
pwd
sudo tar -cvf ${CUR}/kali.tar ./*
cd ..
sudo rm -rf ${DEBIAN_CHROOT}
cd ${CUR}
sudo chmod 666 -v kali.tar
ls -lah
