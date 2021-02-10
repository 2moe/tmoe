#!/usr/bin/env bash
curl -LO https://github.com/tokland/arch-bootstrap/raw/master/arch-bootstrap.sh
if [[ ! -s arch-bootstrap.sh ]]; then
    git clone --depth=1 https://github.com/2moe/arch-bootstrap
    cp -av arch-bootstrap/* .
fi
CUR=$(pwd)

if [[ -d "/tmp" ]]; then
    cd /tmp
else
    mkdir -pv ${HOME}/.cache/tmp
    cd ${HOME}/.cache/tmp
fi

sudo bash ${CUR}/arch-bootstrap.sh -a aarch64 arch
sudo rm -rfv arch/usr/lib/tmpfiles.d/* arch/dev/*
cd arch
sudo tar -pcf ${CUR}/arch.tar ./*

if grep -q 'Ubuntu 20\.04\.' /etc/issue; then
    git clone --depth=1 https://github.com/cu233/runc.git opencontainers-runc
    cp opencontainers-runc/*deb ./
    sudo apt install -y ./*.deb
fi

cd ..
sudo rm -rf arch
cd ${CUR}
sudo chmod 666 -v arch.tar
ls -lah

#[[ ! -s ../bootstrap.sh ]] || bash ../bootstrap.sh
