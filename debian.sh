#!/usr/bin/env bash
if [ -z ${TMPDIR} ]; then
	TMPDIR=/tmp
	mkdir -p ${TMPDIR}
fi
cd ${TMPDIR}
#############
install_dependency() {
	INSTALL_COMMAND="apt install -y ${DEPENDENCY_01} || apk add ${DEPENDENCY_01} || xbps-install -S -y ${DEPENDENCY_01} || port install ${DEPENDENCY_01} || guix package -i ${DEPENDENCY_01} || pkg install ${DEPENDENCY_01} || pkg_add ${DEPENDENCY_01} || pkgutil -i ${DEPENDENCY_01} || pacman -S ${DEPENDENCY_01} || dnf install ${DEPENDENCY_01} || eopkg install ${DEPENDENCY_01} || opkg install wget libustream-openssl ca-bundle ca-certificates bash || zypper in ${DEPENDENCY_01}"
	if [ $(command -v sudo) ]; then
		sudo su -c "apt update 2>/dev/null || apk update 2>/dev/null || opkg update 2>/dev/null"
		sudo su -c "${INSTALL_COMMAND}"
	elif [ $(command -v su) ]; then
		su -c "apt update 2>/dev/null || apk update 2>/dev/null || opkg update 2>/dev/null"
		su -c "${INSTALL_COMMAND}"
	else
		apt update 2>/dev/null || apk update 2>/dev/null || opkg update 2>/dev/null
		apt install -y ${DEPENDENCY_01} || apk add ${DEPENDENCY_01} || xbps-install -S -y ${DEPENDENCY_01} || port install ${DEPENDENCY_01} || guix package -i ${DEPENDENCY_01} || pkg install ${DEPENDENCY_01} || pkg_add ${DEPENDENCY_01} || pkgutil -i ${DEPENDENCY_01} || pacman -S ${DEPENDENCY_01} || dnf install ${DEPENDENCY_01} || eopkg install ${DEPENDENCY_01} || opkg install wget libustream-openssl ca-bundle ca-certificates bash || zypper in ${DEPENDENCY_01}
	fi
}
#########
tuna_mirror() {
	if [ "${LANG}" = "en_US.UTF-8" ]; then
		CHINA_MIRROR='mirrors.huaweicloud.com'
		sed -i "s@deb.debian.org@${CHINA_MIRROR}@g" /etc/apt/sources.list
		sed -i "s@archive.ubuntu.com@${CHINA_MIRROR}@g" /etc/apt/sources.list
	fi
	apt install -y locales 2>/dev/null
	dnf install -y glibc-langpack-zh 2>/dev/null
	sed -i "s/^#.*${LANG} UTF-8/${LANG} UTF-8/" /etc/locale.gen
	locale-gen ${LANG}
	###sed -i '/^apt install -y locales/d' /media/docker/.tmoe-linux-docker.sh
	#用于docker容器自动配置区域与语言环境。
}
#########
if [ $(command -v curl) ]; then
	curl -Lvo .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
elif [ $(command -v aria2c) ]; then
	aria2c --allow-overwrite=true -o .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
elif [ $(command -v wget) ]; then
	wget -O .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
else
	DEPENDENCY_01='wget'
	###tuna_mirror
	install_dependency
	wget -O .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
fi

if [ $(command -v bash) ]; then
	bash .tmoe-linux.sh
else
	DEPENDENCY_01="bash"
	install_dependency
	bash .tmoe-linux.sh
fi
