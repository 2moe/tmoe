# 🍭Tmoe-linux

## Description

🍸 Support for installing GNU/Linux containers on termux and GNU/Linux.  
The following containers are now **supported**:

- [x] **Debian buster/sid**
- [x] **Ubuntu 20.04**
- [x] **Kali rolling**
- [x] **Arch**
- [x] **Fedora 31**
- [x] **Funtoo**
- [x] **Void**

## Installation

If you are using Android, then you can go to Google Play to install the latest version of Termux and Termux: api.

The script can automatically configure the Pulseaudio server for Android and Win10. Make everything very simple.

> Tmoe-linux is installed by running one of the following commands in your terminal. You can install this via the command-line with either curl or wget.

### **via curl**

```shell
    apt install -y curl
    bash -c "$(curl -Lv 'https://git.io/linux.sh')"
```

### **via wget**

```shell
    apt update
    apt install -y wget
    bash -c "$(wget -O- 'https://git.io/linux.sh')"
```

After installing the container, you can type `debian` to start any system.  
I did not do multi-system configuration, all system startup commands are `debian`

After installing the GUI, you can start vnc by typing `startvnc`

It is recommended that you install a VNC client.  
[Google Play](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android)

If you are using WSL2, then it is recommended that you use the X service.
