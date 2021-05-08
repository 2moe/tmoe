#!/usr/bin/env bash
curl -LO https://github.com/tokland/arch-bootstrap/raw/master/arch-bootstrap.sh
if [[ ! -s arch-bootstrap.sh ]]; then
    git clone -b master --depth=1 https://github.com/2moe/arch-bootstrap
    cp -av arch-bootstrap/* .
fi
CUR=$(pwd)

if [[ -d "/tmp" ]]; then
    cd /tmp
else
    mkdir -pv ${HOME}/.cache/tmp
    cd ${HOME}/.cache/tmp
fi

sudo bash ${CUR}/arch-bootstrap.sh -a armv7h arch
sudo rm -rfv arch/usr/lib/tmpfiles.d/* arch/dev/*
cd arch
sudo tar -pcf ${CUR}/arch.tar ./*

cd ..
sudo rm -rf arch
cd ${CUR}
sudo chmod 666 -v arch.tar
ls -lah

#[[ ! -s ../bootstrap.sh ]] || bash ../bootstrap.sh
