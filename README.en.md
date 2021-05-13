# 🍭Tmoe-linux

## Description

🍸 Support for installing GNU/Linux containers on termux and GNU/Linux.  
The following containers are now **supported**:

- [x] **Debian stable+sid**
- [x] **Ubuntu LTS+dev**
- [x] **Kali rolling**
- [x] **Arch**
- [x] **Fedora**
- [x] **CentOS**
- [x] **Gentoo**
- [x] **Alpine edge**
- [x] **OpenSUSE tumbleweed**
- [x] **Void**
- [x] **Raspios**
- [x] **Mint**
- [x] **Devuan**
- [x] **Armbian**

## Installation

If you are using Android, then you can go to Fdroid to install the latest version of Termux and Termux: api.

The script can automatically configure the Pulseaudio server for Android and Win10. Make everything very simple.

> Tmoe-linux is installed by running one of the following commands in your terminal. You can install this via the command-line with either curl or wget.

### **via curl**

```shell
    apt install -y curl
    bash -c "$(curl -Lv git.io/linux.sh)"
```

### **via wget**

```shell
    apt update
    apt install -y wget
    bash -c "$(wget -qO- https://git.io/linux.sh)"
```

After installing the container, you can type `debian` to start it.  
Whether in the container or the original system, you can start the toolbox by typing `debian-i`.  
If you want to list installed containers, then type `tmoe ls`.  

After installing the GUI, you can start vnc by typing `startvnc`, and you can start X by typing `startxsdl`.  

If you are using Android, it is recommended that you install a VNC client.  
[Google Play](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android)  
