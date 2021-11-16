#!/usr/bin/env bash
#####################
CUR=$(pwd)
cp "${CUR}"/../README.* "${CUR}"

URL="https://github.com/docker-library/official-images/raw/master/library/golang"
# https://github.com/docker-library/docs/raw/master/golang/README.md
GO_VERSION="$(curl -L ${URL} | grep 'Tags: ' | head -n 1 | awk '{print $NF}')"
[[ -z ${GO_VERSION} ]] || sed -i -E "s@(/golang:)rc-buster@\1${GO_VERSION}@g" Dockerfile
