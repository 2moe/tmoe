#!/usr/bin/env bash
#----------------
# curl -LO https://github.com/tokland/arch-bootstrap/raw/master/arch-bootstrap.sh
# if [[ ! -s arch-bootstrap.sh ]]; then
#     git clone -b master --depth=1 https://github.com/2moe/arch-bootstrap
#     cp -av arch-bootstrap/* .
# fi
set_env() {
    CUR=$(pwd)
    export ARCH=armhf
}

main() {
    set_env
    cd_tmp_dir
    install_deb
    get_url
    extract_xz
    return_to_cur
}

cd_tmp_dir() {
    if [[ -d "/tmp" ]]; then
        cd /tmp
    else
        TMP="${HOME}/.cache/tmp"
        mkdir -pv ${TMP}
        cd ${TMP}
    fi
}

install_deb() {
    URL="https://github.com/2moe/build-container/releases/download/0.0.1-alpha/get-arch-url_0.0.1_amd64.deb"
    curl -Lo get-url.deb $URL
    sudo apt install ./get-url.deb
}

get_url() {
    get-arch-url
    URL=$(cat url.txt)
    curl -Lo arch.tar.xz $URL
}

extract_xz() {
    xz -dv arch.tar.xz
    mv arch.tar ${CUR}
}

# sudo bash ${CUR}/arch-bootstrap.sh -a armv7h arch
# sudo rm -rfv arch/usr/lib/tmpfiles.d/* arch/dev/*
# cd arch
# sudo tar -pcf ${CUR}/arch.tar ./*
return_to_cur() {
    # cd ..
    # sudo rm -rf arch
    cd ${CUR}
    sudo chmod 666 -v arch.tar
    ls -lah
}
#[[ ! -s ../bootstrap.sh ]] || bash ../bootstrap.sh
#----------
main $@
