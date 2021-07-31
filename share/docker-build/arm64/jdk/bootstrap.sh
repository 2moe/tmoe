#!/usr/bin/env bash
#####################
# CUR=$(pwd)
url="https://github.com/docker-library/official-images/raw/master/library/openjdk"
JDK_VERSION="$(curl -L $url | grep '\-jdk\-slim,' | head -n 1 | awk -F '{print $NF}')"
[[ -z ${JDK_VERSION} ]] || sed -i -E "s@(/openjdk:)jdk-slim@\1${JDK_VERSION}@g" Dockerfile
# cp ${CUR}/../README.* ${CUR}
