#!/usr/bin/env bash
if [ -z ${TMPDIR} ]; then
	TMPDIR=/tmp
	mkdir -p ${TMPDIR}
fi
cd ${TMPDIR}
if [ $(command -v curl) ]; then
	curl -Lvo .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
elif [ $(command -v aria2c) ]; then
	aria2c --allow-overwrite=true -o .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
else
	wget -O .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
fi
if [ $(command -v bash) ]; then
	bash .tmoe-linux.sh
else
	DEPENDENCY_01='bash'
	sudo su -c "apk add ${DEPENDENCY_01} || apt install -y ${DEPENDENCY_01} || port install ${DEPENDENCY_01} || guix package -i ${DEPENDENCY_01} || pkg install ${DEPENDENCY_01} || pkg_add ${DEPENDENCY_01} || pkgutil -i ${DEPENDENCY_01} || pacman -S ${DEPENDENCY_01} || dnf install ${DEPENDENCY_01} || eopkg install ${DEPENDENCY_01}"
	bash .tmoe-linux.sh
fi
