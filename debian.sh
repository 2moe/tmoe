#!/usr/bin/env bash
if [ -z ${TMPDIR} ]; then
	TMPDIR=/tmp
	mkdir -pv ${TMPDIR}
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
	if [ "${LANG}" = "$(printf '%s\n' 'emhfQ04uVVRGLTgK' | base64 -d)" ]; then
		#ALPINE_SOURCE_LIST=/etc/apk/repositories
		#cp ${ALPINE_SOURCE_LIST} ${ALPINE_SOURCE_LIST}.bak 2>/dev/null
		#sed -i "S@dl-cdn.alpinelinux.org@${CHINA_MIRROR}@g" ${ALPINE_SOURCE_LIST} 2>/dev/null
		CHINA_MIRROR='mirrors.huaweicloud.com'
		SOURCE_LIST=/etc/apt/sources.list
		if ! grep -q 'deb mirrors' ${SOURCE_LIST} 2>/dev/null; then
			cp ${SOURCE_LIST} ${SOURCE_LIST}.bak 2>/dev/null
			sed -i "s@deb.debian.org@${CHINA_MIRROR}@g" ${SOURCE_LIST} 2>/dev/null
			sed -i "s@archive.ubuntu.com@${CHINA_MIRROR}@g" ${SOURCE_LIST} 2>/dev/null
			sed -i "s@ports.ubuntu.com@${CHINA_MIRROR}@g" ${SOURCE_LIST} 2>/dev/null
			sed -i 's@^@#&@g' ${SOURCE_LIST}.bak 2>/dev/null
			sed -n p ${SOURCE_LIST}.bak >>${SOURCE_LIST} 2>/dev/null
		fi
	fi
	case ${TMOE_DOCKER} in
	true)
		if grep -q 'Gentoo' /etc/os-release 2>/dev/null; then
			emerge-webrsync
		elif grep -q 'openSUSE' /etc/os-release 2>/dev/null; then
			zypper in -y glibc-locale glibc-i18ndata
		fi
		;;
	esac
}
#########
tmoe_locale_gen() {
	#if [ ! -z "${LANG}" ]; then
	TMOE_LANG_HALF=$(printf '%s\n' "${LANG}" | cut -d '.' -f 1)
	TMOE_LANG_QUATER=$(printf '%s\n' "${LANG}" | cut -d '.' -f 1 | cut -d '_' -f 1)
	if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen" 2>/dev/null; then
		if [ ! $(command -v locale-gen) ]; then
			apt update 2>/dev/null
			apt install -y locales 2>/dev/null
		fi
		apt install -y ^language-pack-${TMOE_LANG_QUATER} 2>/dev/null
		dnf install -y --skip-broken "glibc-langpack-${TMOE_LANG_QUATER}*" glibc-minimal-langpack 2>/dev/null || yum install -y --skip-broken "glibc-langpack-${TMOE_LANG_QUATER}*" glibc-minimal-langpack 2>/dev/null
		pacman -Sy glibc 2>/dev/null
		sed -i "s/^#.*${LANG} UTF-8/${LANG} UTF-8/" /etc/locale.gen 2>/dev/null
		locale-gen ${LANG}
	fi
	if ! grep -qi "^${TMOE_LANG_HALF}" "/etc/locale.gen" 2>/dev/null; then
		cd /etc
		printf "\n" >>locale.gen
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
	aria2c --console-log-level=warn --no-conf --allow-overwrite=true -o .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
elif [ $(command -v wget) ]; then
	wget -O .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
else
	#带三个#为docker容器专用
	###tuna_mirror
	DEPENDENCY_01='wget'
	install_dependency
	wget -O .tmoe-linux.sh https://raw.githubusercontent.com/2moe/tmoe-linux/master/manager.sh
fi
#用于docker容器自动配置区域与语言环境。
###tmoe_locale_gen
if [ $(command -v bash) ]; then
	bash .tmoe-linux.sh
else
	DEPENDENCY_01="bash"
	install_dependency
	bash .tmoe-linux.sh
fi
