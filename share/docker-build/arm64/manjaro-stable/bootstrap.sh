#!/usr/bin/env bash

if grep -q 'Ubuntu 20\.04\.' /etc/issue; then
    git clone --depth=1 https://github.com/cu233/runc.git opencontainers-runc
    cp -vf opencontainers-runc/*deb ./
    sudo apt install -y ./runc*.deb
fi
