#!/usr/bin/env bash
if [ -z ${TMPDIR} ]; then
	TMPDIR=/tmp
	mkdir -p ${TMPDIR}
fi
cd ${TMPDIR}
#############
install_dependency() {
	INSTALL_COMMAND="apt install -y ${DEPENDENCY_01} || apk add ${DEPENDENCY_01} || port install ${DEPENDENCY_01} || guix package -i ${DEPENDENCY_01} || pkg install ${DEPENDENCY_01} || pkg_add ${DEPENDENCY_01} || pkgutil -i ${DEPENDENCY_01} || pacman -S ${DEPENDENCY_01} || dnf install ${DEPENDENCY_01} || eopkg install ${DEPENDENCY_01} || opkg install ${DEPENDENCY_01} || zypper in ${DEPENDENCY_01}"
	if [ $(command -v sudo) ]; then
		sudo su -c "apt update 2>/dev/null || apk update 2>/dev/null || opkg update 2>/dev/null"
		sudo su -c "${INSTALL_COMMAND}"
	elif [ $(command -v su) ]; then
		su -c "apt update 2>/dev/null || apk update 2>/dev/null || opkg update 2>/dev/null"
		su -c "${INSTALL_COMMAND}"
	else
		apt update 2>/dev/null || apk update 2>/dev/null || opkg update 2>/dev/null
		apt install -y ${DEPENDENCY_01} || apk add ${DEPENDENCY_01} || port install ${DEPENDENCY_01} || guix package -i ${DEPENDENCY_01} || pkg install ${DEPENDENCY_01} || pkg_add ${DEPENDENCY_01} || pkgutil -i ${DEPENDENCY_01} || pacman -S ${DEPENDENCY_01} || dnf install ${DEPENDENCY_01} || eopkg install ${DEPENDENCY_01} || opkg install ${DEPENDENCY_01} || zypper in ${DEPENDENCY_01}
	fi
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
