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
	if [ "${LANG}" = "$(echo 'emhfQ04uVVRGLTgK' | base64 -d)" ]; then
		CHINA_MIRROR='mirrors.huaweicloud.com'
		SOURCE_LIST=/etc/apt/sources.list
		sed -i "s@deb.debian.org@${CHINA_MIRROR}@g" ${SOURCE_LIST}
		sed -i "s@archive.ubuntu.com@${CHINA_MIRROR}@g" ${SOURCE_LIST}
	fi
}
#########
tmoe_locale_gen() {
	#if [ ! -z "${LANG}" ]; then
	TMOE_LANG_HALF=$(echo ${LANG} | cut -d '.' -f 1)
	TMOE_LANG_QUATER=$(echo ${LANG} | cut -d '.' -f 1 | cut -d '_' -f 1)
	if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
		if [ ! $(command -v locale-gen) ]; then
			apt update 2>/dev/null
			apt install -y locales 2>/dev/null
		fi
		apt install -y ^language-pack-${TMOE_LANG_QUATER} 2>/dev/null
		dnf install -y --skip-broken "glibc-langpack-${TMOE_LANG_QUATER}*" glibc-minimal-langpack 2>/dev/null || yum install -y --skip-broken "glibc-langpack-${TMOE_LANG_QUATER}*" glibc-minimal-langpack 2>/dev/null
		pacman -Sy glibc 2>/dev/null
		sed -i "s/^#.*${LANG} UTF-8/${LANG} UTF-8/" /etc/locale.gen
		locale-gen ${LANG}
		#用于docker容器自动配置区域与语言环境。
	fi
	if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen"; then
		cd /etc
		echo '' >>locale.gen
		sed -i 's@^@#&@g' locale.gen 2>/dev/null
		sed -i 's@##@#@g' locale.gen 2>/dev/null
		sed -i "$ a ${LANG} UTF-8" locale.gen
		locale-gen ${LANG}
		cd ${TMPDIR}
	fi
	#fi
}
############
if [ $(command -v curl) ]; then
	curl -Lvo .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
elif [ $(command -v aria2c) ]; then
	aria2c --allow-overwrite=true -o .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
elif [ $(command -v wget) ]; then
	wget -O .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
else
	###tuna_mirror
	DEPENDENCY_01='wget'
	install_dependency
	wget -O .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
fi

###tmoe_locale_gen
if [ $(command -v bash) ]; then
	bash .tmoe-linux.sh
else
	DEPENDENCY_01="bash"
	install_dependency
	bash .tmoe-linux.sh
fi
