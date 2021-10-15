#!/usr/bin/env bash
#----------------
set_env() {
    CUR=$(pwd)
    export ARCH=arm64
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
    if [ -d "/tmp" ]; then
        cd /tmp || return 1
    else
        TMP="${HOME}/.cache/tmp"
        mkdir -pv "${TMP}"
        cd "${TMP}" || return 1
    fi
}

install_deb() {
    URL="https://github.com/2moe/build-container/releases/download/0.0.1-alpha/get-arch-url_0.0.1_amd64.deb"
    curl -Lo get-url.deb "${URL}"
    sudo apt install ./get-url.deb
}

get_url() {
    get-arch-url
    URL=$(cat url.txt)
    curl -Lo arch.tar.xz $URL
}

extract_xz() {
    xz -dv arch.tar.xz
    mv arch.tar "${CUR}"
}

return_to_cur() {
    # cd ..
    # sudo rm -rf arch
    cd "${CUR}" || return 1
    sudo chmod 666 -v arch.tar
    ls -lah
}
#----------
main "$@"
