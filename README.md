# 🍭Tmoe-linux

```shell
  . <(curl -L git.io/linux.sh)
```

> If you do not understand the following readme, please give me an issue to explain the situation,or open [README.en.md](https://github.com/2moe/tmoe-linux/blob/master/README.en.md)  
> 化繁为简，让 GNU/Linux 的乐趣触手可及。

If you want to understand the extended usage of containers, then you can read this [document](https://github.com/2moe/tmoe-linux/blob/master/share/old-version/share/container/README.md).  
I'm really sorry, this is a document written in Chinese.

额外[文档](https://github.com/2moe/tmoe-linux/blob/master/share/old-version/share/container/README.md)

## 介绍 Introduction

在 **GNU/Linux**、**Android Termux** 和**Windows10 的 linux 子系统**上配置 **GNU/Linux chroot 或 proot** 容器环境，并 configure remote desktop、pulseaudio 音频服务和 system。

> **Support multiple systems and virtualized environments**

![map](https://images.gitee.com/uploads/images/2020/0807/015255_d4c64165_5617340.png "map.png")

### Preview

#### install alpine arm64 chroot container (Nihongo.ver)

![install alpine arm64 Nihongo.ver](https://images.gitee.com/uploads/images/2020/1012/134622_39d7beb0_5617340.gif)

#### Support multiple architectures

![arch](https://images.gitee.com/uploads/images/2020/1012/135642_01329768_5617340.png "截图_2020-10-12_13-55-33.png")

#### Support multiple languages

![tmoe-linux tool](https://images.gitee.com/uploads/images/2020/1012/135657_70831546_5617340.png "截图_2020-10-12_13-42-37.png")

![main menu English.ver](https://images.gitee.com/uploads/images/2020/1012/135918_eaccc0da_5617340.png "截图_2020-10-12_13-59-00.png")

#### Enjoy gnome40 on arm64 device

![Screenshot_20210806-221622](https://user-images.githubusercontent.com/25324935/128526303-9c644d80-8588-415e-b23b-fe905280352d.png)
![Screenshot_20210806-222714](https://user-images.githubusercontent.com/25324935/128526315-02475932-7327-4a8b-8446-2d22e82a77b4.png)

### 一. Installation

**You can run tmoe-linux manager not only on Android termux, but also on GNU/Linux.**

#### 1.Windows10

##### 第一章 WSL 篇

![001](https://gitee.com/mo2/tmoe-linux-comic/raw/master/001.png)  
**Welcome to the exchange club of Tmoe School.**  
![002](https://gitee.com/mo2/tmoe-linux-comic/raw/master/002.png)  
**How to use tmoe-linux tool on win10.**  
![003](https://gitee.com/mo2/tmoe-linux-comic/raw/master/003.png)  
**Run PowerShell as an administrator and type the following command.**

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

[![enable](https://i.loli.net/2020/04/03/I9zdphVgMc5Zky3.png)](https://sm.ms/image/I9zdphVgMc5Zky3)

重启系统后再次以管理员身份运行 _powershell_ ，然后输下面 wsl 开头的命令。  
After restarting the win10 system, run _powershell_ again as an administrator, then type the following command.

```powershell
wsl --set-default-version 2
```

![store](https://s1.ax1x.com/2020/04/23/JUW3eH.png)

If you cannot connect to _Microsoft Store_,then you can install it manually.  
[Ubuntu](https://aka.ms/wsl-ubuntu-1804)  
[Debian](https://aka.ms/wsl-debian-gnulinux)  
[Kali](https://aka.ms/wsl-kali-linux-new)

![004](https://gitee.com/mo2/tmoe-linux-comic/raw/master/004.png)  
**The operation is very simple, you only need to press the enter and arrow keys.**  
![005](https://gitee.com/mo2/tmoe-linux-comic/raw/master/005.png)  
**OK! Thanks.**  
![006](https://gitee.com/mo2/tmoe-linux-comic/raw/master/006.png)  
**You are welcome,this is my honor,and I think this is what I should do.**  
![007](https://gitee.com/mo2/tmoe-linux-comic/raw/master/007.png)
![008](https://gitee.com/mo2/tmoe-linux-comic/raw/master/008.png)
![009](https://gitee.com/mo2/tmoe-linux-comic/raw/master/009.png)

---

Open the subsystem and upgrade the Linux kernel of WSL2.
And then restart the subsystem.

_**If you are using zsh/bash, then type the following commands.**_

```shell
    sudo apt update
    sudo apt install -y curl
    bash -c "$(curl -L git.io/linux.sh)"
```

_**如果你住在中国,那么请输**_

```shell
    sudo apt update
    sudo apt install -y curl
    bash -c "$(curl -L l.tmoe.me)"
```

如果连接失败，那么请输

```shell
bash -c "$(curl -L https://gitee.com/mo2/linux/raw/2/2)"
```

> 注:前后两者调用的内容是不一样的，二选一即可。  
> 区别在于后者对国内的网络进行了优化。

最后按方向键和回车键进行操作。  
Finally, press Enter and arrow keys to operate.

> 注：WSL 请选择安装工具  
> When it prompted Tool/Manager, please choose Tool  
> 后期注：建议 WSL 用户直接安装 gui ，不要在里面先套娃安装 chroot 容器，再装 gui，因为这将导致 windows 程序调用失败。

#### 2.Android-Termux

> 1.Go to fdroid, then install [Termux](https://f-droid.org/packages/com.termux/) and [Termux:api](https://f-droid.org/packages/com.termux.api/)  
> 2.Open termux and enter the following command.
>
> 1.安装安卓版[Termux](https://apk.tmoe.me/termux) 和[Termux:api](https://apk.tmoe.me/termux-api)  
> 2.打开 termux，输入下面 bash 开头的命令

_**If you are using zsh/bash, then type**_

```shell
    . <(curl -L git.io/linux.sh)
```

_**If you are using fish, then type the following commands.**_

```bash
  apt update
  apt install -y curl
  curl -LO git.io/linux.sh
  bash linux.sh
```

_**如果你住在中国,那么请输**_

```shell
    . <(curl -L l.tmoe.me)
```

如果连接失败，那么请输

```shell
bash -c "$(curl -L https://gitee.com/mo2/linux/raw/2/2)"
```

> 3.When you are using the manager, you can use the touch screen to click.  
> When you are using the tool, you can use the touch screen to slide and press the Enter to confirm.  
> 4-EN.Goto Google Play,then install [VNC client](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android) or [X server](https://play.google.com/store/apps/details?id=x.org.server)
>
> 4-CN.如需使用 gui,可能还需要安装 VNC apk,您可以前往 Google play 或使用 Tmoe-linux 的 debian-i 来下载。  
> 注：web 端的 novnc 无需安装 apk,但触控操作体验不佳。

#### 3.Debian/Ubuntu/Mint/Kali

_**If you are using zsh/bash, then type the following commands.**_

```shell
    sudo apt update
    sudo apt install -y curl
    bash -c "$(curl -L git.io/linux.sh)"
```

_**如果你住在中国,那么请输**_

```shell
     sudo apt update
     sudo apt install -y curl
     bash -c "$(curl -L l.tmoe.me)"
```

如果连接失败，那么请输

```shell
bash -c "$(curl -L https://gitee.com/mo2/linux/raw/2/2)"
```

#### 4.Fedora/CentOS Stream

```shell
    sudo dnf install -y curl || sudo yum install -y curl
    bash -c "$(curl -L https://git.io/linux.sh)"
```

It is not compatible with CentOS 7/RHEL 7 and lower versions.

#### 5.Arch/Manjaro

```shell
    [[ $(command -v curl) ]] || sudo pacman -Syu --noconfirm curl
    bash -c "$(curl -L https://git.io/linux.sh)"
```

#### 6.~~OpenWRT/Entware~~

2020-10:No longer supports openwrt

```shell
    opkg update
    opkg install libustream-openssl ca-bundle ca-certificates wget bash
    bash -c "$(wget --no-check-certificate -O- https://git.io/linux.sh)"
```

#### 7.Alpine

```shell
    apk update
    apk add wget bash sudo
    wget -O /tmp/.tmoe-linux.sh https://git.io/linux.sh
    bash /tmp/.tmoe-linux.sh
```

#### 8.Void

```shell
    [[ $(command -v wget) ]] || sudo xbps-install -Sy wget
    bash -c "$(wget -O- https://git.io/linux.sh)"
```

#### 9.~~Gentoo/Funtoo~~

2020-10:No longer supports Gentoo

```shell
    [[ $(command -v sudo) ]] || emerge -avk app-admin/sudo
    [[ $(command -v curl) ]] || emerge -avk net-misc/curl
    bash -c "$(curl -L https://git.io/linux.sh)"
```

#### 10.OpenSUSE

```shell
    [[ $(command -v curl) ]] || sudo zypper in -y curl
    bash -c "$(curl -L https://git.io/linux.sh)"
```

#### 11.Other

I think you can resolve dependencies manually.

若您需手动克隆本仓库，则请自行解决依赖关系。

The dependencies of the old version before 2020-10(v1.10beta) are `git aria2 pv curl grep procps less tar xz(xz-utils) newt(whiptail) sudo`

In addition, the new version has more dependencies, please check the source code yourself to understand the dependencies.  
**After resolving the dependencies,you can git clone this repo manually**

```bash
case $(uname -o) in
Android) TMOE_LINUX_DIR="${HOME}/.local/share/tmoe-linux" ;;
*) TMOE_LINUX_DIR="/usr/local/etc/tmoe-linux" ;;
esac
TMOE_GIT_URL="https://github.com/2moe/tmoe-linux"
TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
[[ -e ${TMOE_GIT_DIR}/.git ]] || mkdir -pv ${TMOE_LINUX_DIR}
git clone -b master --depth=1 ${TMOE_GIT_URL} ${TMOE_GIT_DIR}
```

**After cloning the repo, you can type `bash ${TMOE_GIT_DIR}/share/old-version/share/app/manager` to start tmoe-linux manager.**

### 二：Container 篇

#### 1.debian and startvnc commands

> For the docker container, the command is docker, so I will not repeat it here.  
> The following will introduce the startup commands of proot and chroot containers.  
> The startup command of the most recently used container is `debian`
>
> 如果容器只有一个，或者您最近使用过那个容器，那么其启动命令为 `debian`  
> 不管是 kali rolling i386,还是 ubuntu focal arm64，只要您最近使用过它，那就是 `debian`  
> 在 v1.10 beta 中，加入了新命令 `tmoe`,支持启动特定的 GNU/Linux 容器版本。

You can type `startvnc` to start **tiger** vncserver.  
If your host system is **Android**,then the vnc viewer will be started at the same time.

在宿主系统下，输`startvnc`将启动容器 + **tiger** vncserver  
若宿主系统为 **Android**，则将同时启动 **Real** vncviewer  
在容器环境下，输`startvnc`仅启动 **tiger** vncserver

You can type `startx11vnc` to start **x11** vncserver.

在宿主系统下，输`startx11vnc`将启动容器 + **x11** vncserver  
在容器环境下，输`startx11vnc`仅启动 **x11** vncserver

You can type `stopvnc` to stop **VNC** server

在容器环境下，输`stopvnc`来停止启动 **VNC** server  
如需了解更多参数，例如`-no-stop-dbus`(不停止 dbus-daemon)，请输`stopvnc --help`  
如果您遇到了无法退出容器的情况，则请将 `stopvnc` 添加至 **~/.zlogout**

```zsh
[[ $(egrep '^[^#]*stopvnc' ~/.zlogout) ]] || printf "%s\n" "stopvnc" >> ~/.zlogout
```

You can type `startxsdl` to start **X** client & server.

在容器环境下，输`startxsdl`仅启动 **X** client  
若您的宿主系统为 **win10**，则输入`startxsdl` 将同时启动 **VcXsrv** X server

#### 2.tmoe command

For different distros and different architectures, the startup commands of the container are different.  
The complete command is similar to `tmoe chroot kali rolling arm64 x11`  
完整的启动命令类似于 `tmoe proot debian sid i386 vnc`  
Next, I will introduce the meaning of each parameter.

```bash
    The 1st parameter is the container-type.
    You can type "tmoe p" instead of "tmoe proot"
    在第一个参数中，chroot可以简化为c;proot可简化为p
    For example,"tmoe chroot"="tmoe c"

    "$1":
        "ls:list installed containers"
        "c:chroot:A chroot is an operation that changes the apparent root directory for the current running process and their children."
        "chroot:与宿主机共享相同的内核,硬件,进程空间和网络子系统"
        "p:proot - mount --bind and binfmt_misc without privilege/setupmount"
        "proot:能在用户空间内运行的程序,I/O性能弱于chroot"
        "ns:systemd-nspawn:It supports executing systemctl commands in the container."
        "nspawn:systemd容器,支持执行systemctl"
-------------
    The 2nd parameter is the distribution name.
    在第二个参数中，"arch"可以简化为"a";"debian"可简化为"d";"fedora"可简化为"f";"ubuntu"可简化为"u"
    例如:"tmoe p debian"="tmoe p d"

    "$2":
        "a:arch"
        "arch:simplicity,modernity,pragmatism,user centrality and versatility"
        "al:alpine"
        "ap:alpine"
        "alpine:Small. Simple. Secure. Alpine Linux is a security-oriented, lightweight Linux distribution based on musl libc and busybox"
        "arm:armbian"
        "armbian:香蕉派,香橙派,nanopi"
        "c:centos"
        "centos:CentOS is a community-driven free software effort focused on delivering a robust open source ecosystem around a Linux platform"
        "d:debian"
        "debian:Debian is a distro composed of free and open-source software"
        "devuan:Devuan is a fork of Debian that uses sysvinit or OpenRC instead of systemd"
        "f:fedora"
        "fedora:developed by the community-supported Fedora Project which is sponsored primarily by Red Hat"
        "g:gentoo"
        "gentoo:追求极限配置和极高自由"
        "k:kali"
        "kali:Kali is a Debian-derived distro designed for digital forensics and penetration testing"
        "m:manjaro"
        "manjaro:Free fast and secure Linux based operating system for everyone"
        "mi:mint"
        "mint:Elegant, easy to use, up to date and comfortable GNU/Linux desktop distribution."
        "o:opensuse"
        "suse:opensuse"
        "opensuse"
        "ow:openwrt"
        "openwrt:OpenWRT is a Linux OS targeting embedded devices"
        "r:raspios"
        "raspios:Raspberry Pi OS"
        "s:slackware"
        "slackware:Slackware is a distro created by Patrick Volkerding in 1993"
        "u:ubuntu"
        "ub:ubuntu"
        "ubuntu:Ubuntu is the modern, open source OS."
        "v:void"
        "void:Void is a general purpose operating system, based on the monolithic Linux kernel"
-------------
   The 3rd parameter is the distro version code.
   在第三个参数中，"sid"可以简化为"s";"无版本代号"既可以简化为"n"，也可以忽略，直接使用第四个参数。
   Note: The following list does not include all codes. If there is no version code, you can skip it.
    如果版本代号不为空，且参数列表中没有出现其具体代号名称，那么请手动输入完整代号。
    如果存在简化版代号，则可使用简化版代号来替代完整代号。
    例如ubuntu 21.04,您可以用"21.04"来代替"hirsute"，至于其他版本却不一定可以，故建议第三个参数使用完整的代号。

    We recommend that you type the complete code.
    For example, for Debian 12, you should use "tmoe c d bookworm" or "tmoe p d bookworm" instead of "tmoe c d 12".

   "$3":
        "s:debian sid"
        "sid"
        "n:none(Rolling releases like archlinux do not have a version code)"
        "none:諸如arch之類的發行版無代號"
        "r:kali rolling"
        "21.04:ubuntu hirsute"
        "20.10:ubuntu groovy"
        "20.04:ubuntu focal"
        "buster:debian10"
        "bullseye:debian11"
        "bookworm:debian12"
        "trixie:debian13"
        "18.04:ubuntu bionic"
        "32:fedora 32"
        "33:fedora 33"
        "34:fedora 34"
        "3.12:alpine 3.12"
        "3.13:alpine 3.13"
        "edge:alpine edge"
        "8s:CentOS 8-Stream"
        "tumbleweed:OpenSUSE tumbleweed"
-------------
    The 4th parameter is the architecture.
    在第四个参数中，"arm64"可以简化为"a";"amd64"可以简化为"x";"i386"可以简化为"i";"armhf"可以简化为"h"。
    If you are not using qemu-user for cross-architecture,then you can skip it.
    例如:"tmoe p arch arm64"="tmoe p a a"
    若您未选择跨架构运行，且当前架构为"arm64",则可去除 "arm64" 参数,直接输入"tmoe p a" 就能启动"proot archlinux arm64"容器

    "$4":
        "x:x64/amd64"
        "amd64:It defines a 64-bit virtual address format, of which the low-order 48 bits are used in current implementations.It defines a 64-bit virtual address format, of which the low-order 48 bits are used in current implementations."
        "a:aarch64/arm64"
        "arm64:64-bit extension of the ARM architecture"
        "h:armhf/arm"
        "armhf:32-bit arm hard float"
        "armel:32-bit arm soft float"
        "i:i386/x86/x32"
        "i386:x86 is a family of instruction set architectures initially developed by Intel based on the Intel 8086 microprocessor and its 8088 variant"
        "p:ppc64el"
        "ppc64el:a pure little-endian mode that has been introduced with the POWER8 as the prime target"
        "s390x:Linux on IBM Z is not generally appropriate on premises for small businesses that would have fewer than about 10 distributed Linux servers"
        "m:mipsel:Microprocessor without Interlocked Pipelined Stages little-endian"
        "riscv64:RISC-V is an open standard instruction set architecture (ISA) based on established reduced instruction set computer (RISC) principlesRISC-V is an open standard instruction set architecture (ISA) based on established reduced instruction set computer (RISC) principles"
-------------
        The 5th parameter can start a specific program of the container, such as vnc and x11.
        If it is empty, then zsh will be started.
        在第五个参数中，"vnc"可简化为"v"。
        启动chroot ubuntu-focal_arm64 tiger vncserver的命令:
        "tmoe c u focal arm64 vnc"
        可以简化为"tmoe c u focal a v"
        虽然"xsdl"在第五个参数中可以简化为"x"，但是在第四个参数中只能简化为"xs"。
        若第五个参数为空，则将启动zsh作为默认登录shell,并且不会启动远程服务。

    "$5":
        "v:vnc(startvnc)"
        "vnc:tight/tiger vnc server"
        "x11:x11 vnc server"
        "xs:xserver"
        "xsdl:xserver"
        "bash:GNU Bourne-Again SHell"
        "zsh:z shell(Default)"
        "ash:command interpreter (shell)"
-------------
```

According to the description of the above parameters, it can be deduced that the startup command of the _debian-sid_amd64_ systemd-nspawn container is

```bash
tmoe ns d s x
```

---

Assuming you have installed a kali-rolling container named **z** .  
When you type `t p k z`, you find that the **proot kali zsh** is started instead of **proot kali z**.  
In this case, you should type the full code: `t p kali-z` instead of `t p k-z`

The fourth and fifth parameters of `tmoe` allow the container to directly execute local scripts/binary files, see the README under the [_share/container_](https://github.com/2moe/tmoe-linux/blob/master/share/old-version/share/container/README.md) directory for details.

Note: The priority of local files is higher than that of the inside of the container.

---

#### SUMMARY

**Take the kali-rolling_arm64 chroot container as an example here**  
Full command:

```bash
tmoe chroot kali rolling arm64
```

Simplified command:

```bash
tmoe c k r a
```

Start kali-rolling_arm64 + tigervnc server:

```bash
tmoe c k r a v
```

Start kali-rolling_arm64 + x11vnc server:

```bash
tmoe c k r a x11
```

Start kali-rolling_arm64 + X client & server:

```bash
tmoe c k r a xs
```

The default login shell is zsh, if you want to start bash,then type

```bash
tmoe c k r a bash
```

Start ash as the login shell：

```bash
tmoe c k r a ash
```

---

**此处以 debian-sid_i386 proot 为例**  
启动 debian-sid_i386 proot 容器的完整命令为

```shell
tmoe proot debian sid i386
```

精简命令为

```shell
tmoe p d s i
```

若您使用的是 tmoe-zsh 配置的环境，则可以进一步简化为

```shell
t p d s i
```

同时启动 debian-sid_i386 容器+tigervnc server 的命令为

```shell
t p d s i v
```

同时启动 debian-sid_i386 容器+x11vnc server 的命令为

```shell
t p d s i x11
```

同时启动 debian-sid_i386 容器+x client + XSDL/VcXsrv 的命令为

```shell
t p d s i x
```

容器的默认登录 SHELL 为 zsh,若您需要使用其它 shell，则请使用以下命令  
临时使用 bash 作为登录 SHELL：

```shell
t p d s i bash
```

临时使用 ash 作为登录 SHELL：

```shell
t p d s i ash
```

---

#### 额外拓展功能

**(补全功能）说明**  
shell 环境要求：_**zsh**_

The completion function exists separately as a zsh plugin, so bash and other shells are not supported.  
仅支持 zsh,不支持 bash

tmoe-zsh 会**自动**加载 tmoe 补全插件，其他插件管理器需要手动加载。

zinit 插件管理器**手动**配置补全插件：

If you are using Android system,then type the following command.

```zsh
[[ $(egrep '^[^#]*zinit.*completion/_tmoe' ${HOME}/.zshrc) ]] || sed -i '$ a\zinit ice lucid wait=1 as"completion" && zinit snippet ${HOME}/.local/share/tmoe-linux/git/share/completion/_tmoe' ${HOME}/.zshrc
```

If you are using GNU/Linux system,then type the following command.

```zsh
[[ $(egrep '^[^#]*zinit.*completion/_tmoe' ${HOME}/.zshrc) ]] || sed -i '$ a\zinit ice lucid wait=1 as"completion" && zinit snippet /usr/local/etc/tmoe-linux/git/share/completion/_tmoe' ${HOME}/.zshrc
```

至于其他插件管理器，例如*oh-my-zsh*，因开发者并未进行测试，故请自行加载插件。

**TIPS OF TMOE COMPLETION PLUGIN**  
1.在 TMOE-ZSH 配置的环境下,输 `t`,按下空格,再按下 TAB 键 **⇄** 进行补全，输/进行连续补全，在该模式下支持搜索发行版名称。  
2.在其他插件管理器配置的环境下，输入 `tmoe`,不按回车,按下 TAB 键 **⇄** 进行补全.  
Type `tmoe`, then don't press enter, press Tab**⇄** to complete.

![zsh plugin](https://images.gitee.com/uploads/images/2020/1012/141644_b724913d_5617340.png "截图_2020-10-12_14-14-43.png")

**gif preview**  
以 alpine 3.12 arm64 proot 以例
![tmoe proot alpine 3.12 arm64 ash English.ver](https://images.gitee.com/uploads/images/2020/1012/134835_a575fc2e_5617340.gif)

---

#### 3.Debian Container

① arm64  
![debian arm64](https://images.gitee.com/uploads/images/2020/0721/190834_db02f784_5617340.png "截图_2020-07-15_13-48-40.png")  
![debian version](https://images.gitee.com/uploads/images/2020/0725/022931_5b2aa814_7793225.png "Capture+_2020-07-24-12-36-02.png")  
② cross-architecture  
Run x86 container on arm64 host.
![debian i386](https://images.gitee.com/uploads/images/2020/0721/192119_96d0b95d_5617340.png "Screenshot_20200721-173852.png")  
![arch](https://images.gitee.com/uploads/images/2020/0725/023007_2cb90736_7793225.png "Capture+_2020-07-24-12-40-59.png")

#### 4.Ubuntu Container

① scrcpy+adb  
![ubuntu arm64 scrcpy](https://images.gitee.com/uploads/images/2020/0721/192606_c10e724e_5617340.png "截图_2020-07-18_23-08-59.png")  
② Desktop beautification

- 1)十年 Mint 和 Ubuntu 壁纸包
- 2)主题链接解析功能  
   解析主题链接（gnome-look 和 xfce-look），并根据主题压缩包内容，自动生成删除/卸载的命令。  
  Mint and Ubuntu wallpaper packs for the past ten years.
  ![wallpaper01](https://images.gitee.com/uploads/images/2020/0721/193421_cb268a12_5617340.png "截图_2020-07-11_08-56-45.png")

### 番外篇 Extra

#### 🍸 Supported containers

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
- [x] **Armbian**

![gentoo](https://images.gitee.com/uploads/images/2020/0725/023040_88655e91_7793225.png "Capture+_2020-07-22-13-20-47.png")  
 配置和优化步骤仅适用于 Debian、Ubuntu、Kali、Arch、Fedora 和 Alpine。  
 🍹
All configuration and optimization steps only apply to Debian,Ubuntu,Kali,Fedora and Arch.

#### 部分功能预览 Preview

qemu-system manager  
![qemu虚拟机管理](https://images.gitee.com/uploads/images/2020/0725/023844_8d7d0eca_7793225.png "Capture+_2020-07-15-18-47-28.png")  
install and configure some apps  
![secret garden](https://images.gitee.com/uploads/images/2020/0721/221603_079fc8d5_5617340.png "Capture+_2020-07-21-22-12-33.png")  
![steam](https://images.gitee.com/uploads/images/2020/0721/221625_594e5123_5617340.png "Capture+_2020-07-21-22-13-13.png")  
部分软件因其已存在强大的第三方 GUI 配置工具,故仅提供安装,不提供配置脚本。  
![ATRI](https://images.gitee.com/uploads/images/2020/0725/015859_4b32d612_7793225.png "截图_2020-07-25_01-29-32.png")

### 三：System Configuration 系统配置篇

1.✨ 支持配置多国语言环境，并执行其它优化步骤。  
Support configuration of multi-language environment.  
多言語環境を構成する  
다국어 환경 구성  
Konfigurieren Sie die mehrsprachige Umgebung
![Screenshot_20200712-084151_1.png](https://i.loli.net/2020/07/12/cwFIHjgyimpd5QN.png)
在安装容器前选择相关选项，运行容器后会自动配置相应语言环境，以“日语\_日本”为例。  
Take "ja_JP" as an example.  
「日本語\_日本」を例にとろう  
![Screenshot_20200711-155224.png](https://i.loli.net/2020/07/12/pSwVqvWy7mH5LP1.png)
2-1.换源功能，全球镜像站  
worldwide mirror sites.
![全球镜像站](https://images.gitee.com/uploads/images/2020/0721/195617_ab223077_5617340.png "Capture+_2020-07-21-19-48-41.png")
除 debian 官方的全球镜像站外，更有 arch,alpine,fedora,kali 和 manjaro 国内镜像站。

2-2. 额外源功能：arch 添加 archlinux_cn 源，centos 添加 epel 源，debian 添加 kali 源，debian 添加 ubuntu ppa 源并自动解决公钥问题。  
![kali-rooling-terminal](https://s1.ax1x.com/2020/04/23/JUR15q.md.png)

3.sudo group management 用户组管理

![sudo用户组](https://images.gitee.com/uploads/images/2020/0721/200945_8b7bde03_5617340.png)

4.UEFI Startup item management 开机启动项管理

![uefi开机启动项](https://images.gitee.com/uploads/images/2020/0721/201713_0218fe60_5617340.png "Snipaste_2020-06-21_18-24-13.png")

### 四：Remote Desktop Configuration 远程桌面配置篇

1.支持一键安装图形界面。  
Support one-key graphical user interface installation.
![de&wm](https://images.gitee.com/uploads/images/2020/0721/202944_b98d0e7b_5617340.png "Capture+_2020-07-21-20-09-40.png")

2.TUI，便捷配置  
Convenient configuration  
![remote desktop configuration](https://images.gitee.com/uploads/images/2020/0722/143751_d5f4d9c4_5617340.png "Capture+_2020-07-22-14-36-25.png")  
![分辨率](https://images.gitee.com/uploads/images/2020/0721/203215_9823fc25_5617340.png "Capture+_2020-07-11-10-05-41.png")

3.对于不同系统，不同虚拟化环境进行适配  
This tool is adapted to different systems and different virtualization environments.

3-1.以 tightvnc/tigervnc 服务为例：  
对于 deb 系的虚拟机和实体机，启动 de/wm 的脚本中包含了 dbus-launch --exit-with-session,不加的话可能会出现无法连接至设置服务的错误，而 deb 系的 proot 容器加上这个会很容易闪退，所以对 proot 容器和虚拟机分别进行适配。  
而 arch 系虚拟机只需要 dbus-launch,不要加那个参数。  
3-2.自动修复 deb 系发行版+xfce4.14 在 tightvnc 下窗口标题栏丢失的问题。  
3-3. 对桌面的多启动命令问题进行修正。  
 举例：对于 KDE plasma 桌面来说，新版的启动命令为 startplasma-x11 和 startplasma-wayland，不再包含 startkde，而本工具同时兼顾了新版和旧版。  
3-4.自动解决非 root 用户在初次配置时可能出现的权限问题。  
3-5.对于 WSL2 的适配： 自动识别出 B 类内网动态的 NAT ip，并通过 pulseaudio 实现音频传输，通过调用宿主机（win10）进程来实现便捷式 X 转发。  
自动配置只是其中一个解决方案，还有一个是手动配置管理。

4.🍸 Supported GUI（DE)  
 目前支持的图形界面（桌面环境）：  
（仅部分系统支持）

- [x] **xfce4**
- [x] **lxde**
- [x] **mate**
- [x] **lxqt**
- [x] **kde plasma 5**
- [x] **cinnamon**
- [x] **gnome 3**
- [x] **deepin desktop**

> 注 1：Only some systems support desktop environment installation.  
> 仅部分系统支持  
> 注 2：Prioritize XFCE  
> 优先适配 xfce  
> 注 3： 未打勾的选项在容器/远程桌面环境下存在一些问题  
> **Some desktops may not display properly through the remote desktop**

4-1.Arch + Deepin desktop ~~在 VNC 下会黑屏~~  
下图的 Arch 是运行在 debian 里的 chroot 容器。  
Configure vnc for dde.
![Snipaste_2020-04-12_05-09-13.png](https://i.loli.net/2020/04/18/LQcrOqZxwU2svJ5.png)  
后期注：经测试 qemu 虚拟机下的 arch+dde+tigervncserver 没有问题，但是我没有再次测试 WSL2 的兼容性。  
4-2.如下图所示，Debian sid + KDE Plasma 5 转发 X11 后，窗口显示会出现问题。  
Configure vnc for plasma5.  
注：在 RDP 下此问题未复现  
注 2：qemu 虚拟机运行的 Debian+KDE+x11vnc 也没有问题。  
![Snipaste_2020-04-12_07-28-58.png](https://i.loli.net/2020/04/18/5g1Nn9DQpPqEhuz.png)  
4-3.Configure vnc for gnome3.  
![Screenshot_20200608-003126.png](https://images.gitee.com/uploads/images/2020/0718/103733_9b989b37_5617340.png)

### 五.Software configuration 软件配置篇

1.提供了某些官方软件源中不包含的软件包，例如 vscode。
![vscode_desktop_version](https://s1.ax1x.com/2020/04/23/JUWnW6.jpg)  
You can install vscode in the container.
你可以在手机的容器里安装 vscode。  
2.对于部分工具提供了配置管理功能，例如 arm64 的 vscode-server。  
3.对于特定虚拟化环境下运行报错的应用执行打补丁操作。  
4.对 aria2 上百个参数进行配置管理。
![aria2 ua](https://images.gitee.com/uploads/images/2020/0721/210921_a65d7e0e_5617340.png "Capture+_2020-07-21-21-06-15.png")
![aria2 bt](https://images.gitee.com/uploads/images/2020/0721/210908_43268dda_5617340.png "Capture+_2020-07-21-21-05-48.png") 5.对输入法进行安装和配置。

### 六.支持的架构 Supported architecture

Debian 容器支持 **arm64(aarch64)、armhf、armel、amd64(x86_64) 、i386(x86)、s390x 和 ppc64el**

~~可以支持，但不想支持的是 **mipsel**~~
In addition, the **mipsel** architecture is also supported! The developer has tested it on the router

2020-03-24 已经支持 **mipsel** 架构了！(已经在路由器上测试过了 🍥)

可能支持 **RISC-V** (未测试）

Containers other than debian may only support mainstream architectures, not s390x and ppc64el.
其它系统容器可能只支持主流的 amd64、arm64 等架构，不支持 s390x 和 ppc64el 等冷门架构。

> 下表中的所有系统均支持 x64 和 arm64
> All systems in the table below support x64 and arm64  
> \*表示仅旧版支持

| Distro |    x86    | armhf | ppc64el |
| ------ | :-------: | :---: | :-----: |
| Debian |     ✓     |   ✓   |    ✓    |
| Ubuntu | \*<=19.10 |   ✓   |    ✓    |
| Kali   |     ✓     |   ✓   |    X    |
| Arch   |     X     |   ✓   |    X    |
| Fedora |  \*<=29   |   ✓   |    ✓    |
| Alpine |     ✓     |   ✓   |    ✓    |
| CentOS |   \*<=7   | \*<=7 |    ✓    |

### 七.其他说明（旧版）

#### 简易版说明（萌新专用）

##### 1.安装 Tmoe GNU/Linux 管理工具的命令

You can use the following command to install Tmoe GNU/Linux manager

```shell
bash -c "$(curl -L https://gitee.com/mo2/linux/raw/2/2)"
```

~~**(旧版)视频教程**[链接](https://pan.baidu.com/s/1rh7Nkcd0gG9RPx77JyGqZA) 提取码: **debb**~~(已废弃)

> 进入工具后，按方向键和回车键进行操作，基本上所有操作都有提示。

[![Snipaste_2020-03-20_17-10-48.png](https://gitee.com/mo2/pic_api/raw/test/2020/03/20/0W0hSgimlmeXIBjO.png)](https://gitee.com/mo2/pic_api/raw/test/2020/03/20/0W0hSgimlmeXIBjO.png)

##### 2.启动命令

**如需了解完整命令，请看新版教程。**

- 启动最近使用的容器

```bash
 debian
```

If you want to start GNU/Linux next time, you can just type `debian`.

- 启动 tigervnc server  
  **若宿主机为 Android 设备，则将同时启动 VNC viewer**

  ```bash
  startvnc
  ```

- 启动 x11vnc server

  ```bash
  startx11vnc
  ```

- 启动 X client & server
  **若宿主系统为 win10，则将同时启动 VcXsrv**

  ```bash
  startxsdl
  ```

##### 3.卸载命令

~~debian-rm~~ #(已废弃)

请在管理菜单中单独选择容器名称及其 `umount & remove` 选项

```bash
bash ~/容器选择菜单.sh
```

> If your locale is not "zh\_.\*UTF-8" or "ja_JP.UTF-8", please type

```bash
bash ~/TMOE-CONTAINER-MENU.sh
```

##### 4.启动工具箱(同时支持，但管理的内容不同)

宿主系统将调用 tmoe-linux manager,容器将调用 tool.

```shell
debian-i
```

##### 5.停止 vnc 命令（同时支持）

```shell
 stopvnc
```

###### 不停止 x11vnc

```shell
 stopvnc -no-stop-x11vnc
```

###### 不停止 dbus-daemon

```shell
 stopvnc -no-stop-dbus
```

---

#### Step2.安装图形化桌面环境

##### 2-1.安装前（关于桌面环境的安装与卸载）

进入 GNU/Linux 容器后，您可以从 _xfce、lxde、mate、lxqt_ 中选择一种。

##### 2-3.安装后

输`startvnc`启动 vnc 服务，
输`stopvnc`停止 vnc 服务。
完成后，打开 vnc viewer 客户端，输 `localhost:5902`

#### 其它说明

- 1.若无法退出 GNU/Linux 容器，则请在原系统内输`stopvnc`
- 2.若 zsh 配置失败，则请输`./zsh.sh`进行重新配置。
- 3.主目录下的 sh 文件可以删除，但 **sd、tf 和 termux** 三个目录**不要删**。
- 因为这三个目录挂载了设备存储空间，分别和内置存储、tf 卡(termux 专有目录)以及 termux 主目录联动。

#### 可选步骤

##### 1.修改 vnc 分辨率的方法

- 1-1.工具修改

在 GNU/Linux 容器内输`debian-i`打开工具箱，然后选择相关选项，需要注意的只有一点，x 为英文小写，不是乘号。

- 1-2.亦可手动修改

```shell
apt install -y micro
micro $(command -v startvnc)
```

> 将 **1440x720**（竖屏）改成你需要的分辨率，例如 **1920x1080**（横屏)
> 修改完成后，按`Ctrl+S` 保存，`Ctrl+Q`退出。

---

### 八.相关项目

[termux/proot-distro](https://github.com/termux/proot-distro)  
[2cd/zsh](https://github.com/2cd/zsh)  
[coslyk/debianopt-repo](https://github.com/coslyk/debianopt-repo)

### 九.更新日志 logs

#### 2019 年

##### 11、12 月

~~旧版脚本部分命令借鉴了 [atilo-cn](https://github.com/YadominJinta/atilo) 和 [AnLinux](https://github.com/EXALAB/Anlinux-Resources)，除此之外，大部分都是本人手打的。
可能会有出错的地方，欢迎指正。~~

#### 2020 年

##### 02-15

> **完全重写脚本！**
> 和别人写的脚本已经**完全不一样**了，重点不在于安装的方式，而在于配置优化以及与安卓原系统的联动，难点在于一些鬼点子。

本来是不想维护的，但是我发现了一个很严重的 bug,所以干脆重写一遍。
本次更新的内容真的有点多，而且真的很强哦 ✨ ο(=•ω ＜=)ρ⌒☆，我自己都觉得太强了！

##### 2020-02-15 更新内容

- 1.获取镜像途径依旧是清华镜像站，但把下载工具从 wget 换成了 aria2，从原本的单线程变成现在的 16 线程，加快了下载速度。  
  后期注：盲目调大线程最终适得其反，后期已改为 5 线程。

- ​ 2.自动配置中文环境，默认就是中文，无需手动配置。

- ​ 3.修复旧版脚本中非 xfce 桌面的 xstartup 文件问题。

- ​ 4.新增自动配置 zsh 的功能，初次启动会出现提示，若在指定时间内无操作会自动开始安装并配置 zsh。
- ​ 包含主题和语法高亮、语法历史记录插件。

- ​ 5.简化安装流程，且不再需要某种很神奇的 internet 工具。

- ​ 6.将 debian 10 buster (stable)换成 sid bullseye(unstable)，滚动升级，一直都是新版。

- ​ 7.修复 chromium 浏览器的启动问题，使用 `./chromium.sh` 安装的版本，可以直接点击图标启动，在 root 环境下无需加`--no-sandbox` 参数。

- ​ 8.加入对 armhf 和 x86_64(amd64)的支持。

- ​ 9.支持一键更换为 kali 源，debian 变身 kali 就是这么简单！

- ​ 10.简化卸载流程，安装脚本也可以执行卸载操作。

- ​ 11.根据当前 linux shell 环境自动修改 proot 启动脚本。

- ​ 12.修复启动 vnc 后，debian 无法正常关闭的 bug ,(请在 termux 原系统内输 `stopvnc`)

- ​ 13.简化启动流程，你可以在 termux 原系统里输 startvnc 来启动 debian+vnc 客户端

- ​ 14.vnc 支持自动获取本机局域网 ip，地址格式类似于 `192.168.123.3:5902`

---

​
**之后的更新内容真的是太多了，有空的话会从酷安原帖搬过来的。其中最突出的更新内容是将安装 gui 和其它软件、管理远程桌面配置等内容整合在 GNU/Linux 容器内的 debian-i 里，以及修复了 VNC 音频传输中可能存在的一些问题。**
2020-04-29 注：包含更新日志的帖子已被酷安删除，由于超过 2 周时间，故无法恢复。

---

> 2020-02-16 至 2020-03-22 的更新日志待补

---

##### 2020-03-23 更新日志

本次更新专注于用户体验方面的优化。

- 1.zsh 加入新插件：[aloxaf](https://www.v2ex.com/member/aloxaf)开发的[fzf-tab](https://www.v2ex.com/t/653576#reply15)  
  这是一款非常出色的补全插件！
  ![Snipaste_2020-03-24_07-48-22.png](https://gitee.com/mo2/pic_api/raw/test/2020/03/24/yWAS2yAu19bhsyJs.png)

- 2.将默认主题更换为 powerlevel 10k，并同时修复 termux 和 xfce4 终端的字体显示问题。

- 3.加入 Command-not-found 插件。  
  当您未安装相关软件时，输入的是错误的命令。例如输 sshd 时，会出现`apt install openssh-server`的提示，而不是单纯的显示：`Command not found`.

> 后期注：宿主机为 OpenWRT 的路由器，不会加载上述**部分**插件，且默认主题非 p10k。

##### 2020-03-24 更新日志

- 1.支持 mipsel 架构，已在路由器上测试过了。

![Snipaste_2020-03-24_05-36-44.png](https://gitee.com/mo2/pic_api/raw/test/2020/03/24/1dc0XmN262GBr9QG.png)

- 2.尝试让 RISC-V 架构的设备能运行 debian 容器，需要宿主机原系统为 deb 系。  
  当检测到设备为 riscv 架构时，将下载其他架构的容器镜像。
  调用 qemu+chroot 来实现跨 CPU 架构运行容器，这是一个理论性操作，未实际测试。

  2020-10 注：勿需跨架构，支持直接运行 riscv64 容器。

##### 2020-03-25 更新日志

- 1.在 iOS 13.3 上发现致命 bug,不再对 iOS-iSH 提供支持。
- 请勿在苹果 iOS 设备上使用本脚本！
- 注：[iSH](https://ish.app/)为苹果 iOS 上的 Alpine Linux i686 模拟器。

##### 2020-03-26 更新日志

- 1.全面适配 WSL2 （第二代 windows 的 linux 子系统）
- 注：在 WSL1 中出现严重 bug,但在 WSL2 中却没有复现。
- 1-1.输`startxsdl`能同时启动 windows 的 X 服务
- 1-2.支持 WSL 的音频传输
- 2.修复 novnc 在非 Android 系统上重复安装的问题
- 3.在软件商店中加入了网易云音乐和百度网盘

##### 2020-03-27 至 2020-04-01 更新日志

- 1.加入测试功能，可在工具内手动安装输入法（如 sunpinyin 和 sogou-pinyin）、电子书阅读器、视频剪辑(openshot)、数字绘图(krita)、社交应用（如 Wechat 和 Telegram） 等等。
- 2.全面优化 Windows 平台的 pulseaudio(音频传输)服务
- 3.对于 WSL 的常见问题，给出了解决方案，部分内容还附有截图。
- 4.加入了修复度盘客户端无法打开的功能

> **对 WSL2 的支持已经称得上完善了!**  
> 最关键的地方在于脚本大量调用了 win10 原系统的程序。  
> **在 win10 2004 下同时运行 linux 和 windows 程序的预览截图**：
> ![GlyxZ8.png](https://images.gitee.com/uploads/images/2020/0718/103735_8403852b_5617340.png)  
> WSL2 与宿主机原系统（win10）的交互联动要比普通虚拟机强数倍，在 linux 子系统下可以直接调用 powershell.exe 等 windows 程序。  
> ~~如上图所示，目前已经可以接近完美地将 win10 和 GNU/Linux 融为一体。~~

##### 2020-04-02 更新日志

- 1.支持非 root 用户配置 vnc 服务
- 2.修复大量 bug

##### 2020-04-10 更新日志

- 1.加入测试版容器 arch,fedora,centos,raspbian,mint 等等

##### 2020-04-11 更新日志

- 1.加入测试版桌面 lxqt,kde,gnome 等。
- 2.除 deb 系外，还支持给其它发行版安装 gui。
- 3.支持修复 vnc 闪退。
- 注 1：由于在这几天的更新中给所有的桌面都加入了 dbus-launch，故在部分安卓设备的 Proot 容器上出现了兼容性问题，容易造成不稳定的状况。
- 注 2：该操作在 linux 虚拟机及 win10 子系统上没有任何问题
- 注 3：在最新更新的版本（容器安装方式）中已加入检测功能，理论上不会再出现此问题。你也可以在更新 debian-i 后，单独进行修复。

##### 2020-04-12 更新日志

- 1.支持切换 VNC 音频传输方式。

##### 2020-04-13 至 2020-04-19 更新日志

- 1.优化并适配 Arch,Fedrora 系统
- 2.Gentoo 和 OpenSUSE 仅优化 x64 版
- 3.加入更多发行版的容器，例如 Slackware,Armbian 等

##### 2020-04-20 更新日志

- 1.支持安装其它版本的 VSCode,包括 VS Codium,VS Code OSS,以及官方版的 VScode。
- 自动识别除 i\*86 外的主流架构，自动获取最新链接，对 deb 系和红帽系进行分别适配，其它发行版以 tar 压缩包形式进行安装，解压至/usr/local/bin 目录。
- 2.在服务器上实现了自动构建(获取最新版+重新打包配置) VSCode Server (web 版)。  
  每隔一两周，当检测到新版时，远程服务器就会自动更新，完成后将自动同步至国内的 gitee 仓库。因此远程始终都是新版，但是本地的话，得要根据你下载的时间而定，不会自动更新。

##### 2020-04-22 更新日志

- 1.修复赋予 proot 容器真实 root 权限后，vnc 出现的权限问题。

##### 2020-04-24 更新日志

- 1.给 ArchLinux 容器添加了 archlinuxcn 源，并将自动安装 yay

##### 2020-04-29 更新日志

- 1.应 gitee 的小伙伴要求，在测试功能中支持 WPS office 的安装。

##### 2020-05-01 更新日志

- 1.支持解析视频网站链接，与原版 [annie](https://github.com/iawia002/annie) 最大的区别是支持解析 b23.tv ，并且无需完整链接，就能直接解析 BV 号。

##### 2020-05-02 更新日志

- 1.支持搭建个人云网盘（来自 github 开源项目[filebrowser](https://github.com/filebrowser/filebrowser)），配合我写的配置脚本来实现简易化管理。

##### 2020-05-03 更新日志

- 1.支持搭建并配置 WebDAV(nginx)服务，可以非常方便地配置和管理端口号、访问目录、访问账号、日志和进程等内容。
- 2.支持在工具内配置 VSCode Server 的访问密码。

##### 2020-05-04 更新日志

- 1.增加 fedora 32 容器，由于在测试过程中发现某些问题，故保留了之前的 31，可以自由选择版本。

##### 2020-05-05 更新日志

- 1.优化代码，增加高亮提示。

- 2.在 beta_features 中支持 docker 和 virtualbox 的安装。
- 其中，当 deb 系发行版初次安装后者时，将会自动获取清华源的最新 deb 包。第二次才会提示是否将其添加至软件源列表。

- 3.对已支持的所有系统正式开放测试功能！但由于未做过多测试，故 gentoo 、opensuse 和 alpine 等发行版可能会出现未找到匹配软件的错误信息。

##### 2020-05-06 更新日志

- 1.自动修复 proot 容器环境下，安装 xfce4 桌面时 gvfs 和 udisks2 配置失败的问题，原先是需要在 FAQ 里手动修复的。
- 2.添加 xrdp 的配置选项，并适配更多桌面。

##### 2020-05-07 至 2020-05-08 更新日志

- 1.支持给所有已支持的桌面配置 xwayland！（仅支持 Android，不支持 win10）
- **说明**：
- 需要先在 termux 进行配置，并安装 wayland 服务端软件，再进入 GNU/Linux 容器内选择需要配置的桌面环境。
- 其中后者只是在我之前写的 xorg+xrdp 的配置方案的基础上进行了修改而已。
- 配置完成后，需要先打开 wayland 服务端，点击`start`,然后在容器内输`startw`启动。
- 特点：可以在 proot 环境下打开 kde 的某些应用（例如 plasma-discover），但是 bug 超级多。
- 由于 bug 实在过多，故我已经不想维护了。

  触控操作体验极差！建议使用蓝牙鼠标进行操作！  
  由于目前在 Android 手机上暂时无法使用 gpu 硬件渲染加速，故实际体验非常糟糕！
  不建议配置该服务!  
  等 wayland 完善之后，再来继续优化吧！

  2020-10 注：配置 xwayland 的功能已经被我砍掉了！！！请自行研究配置步骤。

##### 2020-05-09 至 2020-05-10 更新日志

- 1.全面升级备份与还原功能，支持自定义备份文件名称。自动检测备份文件路径，也可以手动选择路径，然后会自动将备份文件排成一个列表，你只需输选项数字并按回车即可恢复所选文件。
- 2.优化 cookie 文件选择功能，支持图形化文件浏览。
  因为改了太多内容了，也没有继续做兼容性测试，所以不确定路由器等嵌入式设备还能不能继续兼容。
- 3.修复 Android-Termux 赋予 proot 容器真实 root 权限的功能，原因是 termux 更新了 tsu，将 tsudo 切换至 sudo。
- 4.deb 系 Linux 现在也可以用 proot 容器啦！

  2020-10 注：第三个功能已经被我砍掉了。请不要先输`tsu`，再输`debian`。
  如果你要这样做的话，那么请使用`chown`来解决权限问题，再自行解决其他可能存在的问题。

##### 2020-05-11 更新日志

- 1.支持配置 X11vnc 服务。
- 输`startx11vnc`启动，输`stopvnc`停止。
- 2.支持安装窗口管理器
  ![Snipaste_2020-05-11_21-36-18.png](https://images.gitee.com/uploads/images/2020/0718/103736_846ae27a_5617340.png)
  在安装时会自动配置 vnc 服务，我没有为它们写单独的 rdp 配置步骤。

##### 2020-05-13 更新日志

- 1.修复大量 bug。
- 2.支持安装 linux arm64 版的 wechat 和搜狗拼音，不保证可以正常运行。
  ![arm64_wechat](https://images.gitee.com/uploads/images/2020/0513/212157_13da21ed_5617340.png "Capture+_2020-05-13-21-15-45.png")

##### 2020-05-14 更新日志

- 1.加入[debian-opt](https://github.com/coslyk/debianopt-repo)仓库，支持安装第三方音乐客户端，感谢仓库的维护者 coslyk，以及各个项目的原开发者。
- 我在部分基于 electron 的应用中，添加了是否关闭沙盒模式的提醒。简单来说，就是修复 root 用户无法启动的问题。
- 手机预览截图见下
  ![Screenshot_20200514-024023_1.png](https://i.loli.net/2020/05/14/T5wyZtisuJUIX3x.png)
  -2.加入最新的 ubuntu20.10 容器

##### 2020-05-20 更新日志

- 1.支持安装 wine、anbox 和 aqemu
- 2.增加 iso 镜像文件下载功能，支持自动获取 android_x86 镜像，支持下载各个架构的 debian iso 镜像(包含 non-free 固件)，以及各个 ubuntu 的衍生版
- 3.增加烧录 iso 文件至 U 盘的功能
- 4.支持安装 linux 版百度输入法，此前已经支持讯飞和搜狗输入法。
- 5.增加 tmoe-deb 软件包安装器，支持在脚本内选择并安装 deb 文件。
- 后期注：增加了 deb 批量安装功能(GUI)。

##### 2020-05-21 更新日志

- 1.全面升级换源功能，支持选择多个镜像站。debian,ubuntu,kali,arch,manjaro,fedora 和 alpine 可以单独使用换源功能。

##### 2020-05-22 更新日志

- 1.修复 Ubuntu20.10 存在的各种问题。
- 2.镜像站支持测延迟+测速，支持强制信任软件源，去除多余行，一键切换 http/https。
- 除了主要源外，还支持配置额外源。对于不同的发行版，显示的额外源是不同的。对于 debian,显示的是切换为 kali 源。对于 arch，显示的是配置 archlinux-cn 源。对于 centos，显示的是 epel 源。

##### 2020-05-23 更新日志

- 1.修复 code-server
- 由于上游发生变更，因此重写了配置脚本。

##### 2020 年 05 月末 更新日志

- 1.加入 qemu 配置功能，支持高度的自定义配置。
- 以 CPU 这一块为例，支持配置 cpu 核心数，cpu 类型，加速类型，多线程。
- 除了 x86_64 架构外，还适配了 arm64 架构。
- 除此之外，还支持运行内存分配，多虚拟机管理，磁盘文件管理，配置共享文件夹和端口映射等虚拟机常见功能。
- 支持自由选择声卡，显卡和网卡，以及 bios 文件。
- 支持下载 demo 镜像，能在宿主机为安卓的设备上快速运行 docker 容器。

-目前暂不支持的功能： 1.虚拟机显卡硬件直通（需要双显卡，我没有测试条件） 2.快照管理（请自行在 qemu monitor 里管理 snapshoots）

##### 2020-06-01 更新日志

- 1.支持修改 uefi 开机启动项,备份和恢复 efi 分区。

##### 2020-06-02 更新日志

- 1.qemu 虚拟机增加 virtio 磁盘的配置选项。

##### 2020-06-03 更新日志

- 1.修复 qemu 在 VNC 远程桌面环境下无法调用音频的问题
- 2.更新 Tmoe 文件选择器，自动重定向文件路径。

##### 2020-06-05 更新日志

- 1.支持配置显示管理器 (Display manager)

##### 2020 年 06 月上旬至中旬 更新日志

- 1.增加更多系统配置选项，例如配置时间同步服务，开机自启脚本和管理 sudo 用户组等。
- 2.增加 Debian 配置 Ubuntu ppa 软件源的功能。Debian 使用原版的 add-apt-repository 存在某些问题，例如添加 gpg 密钥失败，而此功能的目的就是解决这些问题。
- 填写完 ppa 源名称后，会自动检测 launchpad 中该软件描述页面的 gpg 密钥，并添加。接着，需要指定 ubuntu 版本代号，完成后会自动修改软件源列表。
- 此功能对于 ubuntu 同样有效，经测试部分 ppa 软件源不包含 ubuntu 20.10 groovy 的仓库，此功能可以帮你解决手动修改/etc/apt/sources.list.d/中相关软件源列表的烦恼。

##### 2020 年 07 月 更新日志

- 1.修复 qemu 模板仓库
- 2.支持更多的 debian 容器版本，自动检测 debian12 bookworm 等未发布版本。
- 3.多区域/语言环境配置
- 4.0711-0716:增加 aria2 配置工具
- 5.0720-0721:优化跨 cpu 架构运行容器的功能  
  ![Snipaste_2020-07-21_14-30-25.png](https://images.gitee.com/uploads/images/2020/0807/012632_c98e4bf0_5617340.png)
- 6.0723:配置 fcitx5
- 7.0730 更新教育类，增加高考和考研

##### 08 月 更新日志

- 1.08-11:更新 docker 配置选项
- 2.08-14:更新 termux 的换源功能，支持配置多个镜像站。
- 3.08-16:重构 proot 脚本，修复 deb 系发行版无法使用`ps`命令的问题。
- 4.08-21:对 archlinux 等非 deb 系发行版适配音乐 app
- 5.08-26:支持跨 CPU 架构运行 docker 容器
- 6.08-29:在恢复容器压缩包时，将根据系统对权限的限制自动判断特殊文件的挂载与否。(仅适用于 0816 之后的版本)

##### 10 月 更新日志

- 1.增加多容器管理
- 2.移除功能：xwayland,赋予 proot 容器真实 root 权限等等。  
  移除 vscode server 宿主机与容器的联动功能。  
  原功能介绍：在宿主机下执行指定命令将同时启动宿主机的浏览器并打开 code server 的 web 页面+容器的 code server。  
  此外，还有很多功能也被我砍了，此处不一一列举。  
  有些功能维护起来太累了，我不想管了。  
  还有的话，不再对 gentoo 和 openwrt 提供支持。

- 3.10-13:增加 vscode arm64/armhf 官方版，此前 arm 只有第三方编译版。

- 4.移除发行版: apertis，alt 和 raspbian。
- 5.新增 deepin v20 容器
- 6.修复 riscv64 架构容器的配置功能，arm64 可以跨架构运行 risv64。
- 7.新增 mips64el 架构的容器。

##### 11 月 更新日志

- 1.重构 qemu-system-x86_64 配置功能。
- 2.移除功能：qemu-system-aarch64 所有配置选项,烧录 iso 至 U 盘等。

##### 12 月 更新日志

- 1.修复容器环境下运行 fcitx/fcitx5/ibus 时，环境变量未正确配置的问题。

---

##### 2021 年 1 月 更新日志

- 1.增加 Dockerfile ,并为部分发行版+桌面提供每周自动构建镜像。
- 您现在可以直接下载包含 GUI 的容器镜像。
