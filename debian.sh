#!/usr/bin/env bash
if [ ! -z ${TMPDIR} ]; then
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
elif [ $(command -v ash) ]; then
	ash .tmoe-linux.sh
elif [ $(command -v zsh) ]; then
	zsh .tmoe-linux.sh
else
	sh .tmoe-linux.sh
fi
