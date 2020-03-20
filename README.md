# 🍭Tmoe-linux

原名（Termux-Debian）

## 介绍

在 **GNU/Linux** 上一键安装 **GNU/Linux chroot** 容器。
在 **Android Termux** 上一键安装 **GNU/Linux proot** 容器。  
🍸 目前支持：

- [x] **Debian buster/sid**
- [x] **Ubuntu 20.02**
- [x] **Kali rolling**
- [x] **Funtoo**
- [x] **Void**  
       ✨ 支持自动配置中文环境，并执行其它优化步骤。🍹  
       所有的配置和优化步骤仅适用于 deb 系！

![Capture__2020-02-16-02-23-49.png](https://gitee.com/mo2/pic_api/raw/test/2020/02/16/KtxgGq3bFSf4Uwvo.png)

支持一键安装图形界面。

![截图_2020-02-01_08-53-21.jpg](https://gitee.com/mo2/pic_api/raw/test/2020/02/16/yMgxSkGh0Tx4IJz0.jpg)

### 软件架构

支持 **arm64(aarch64)、armhf、armel、amd64(x86_64) 、i386(x86)、s390x 和 ppc64el**

不支持 **RISC-V**

可以支持，但不想支持的是 **mipsel**

### 不同平台的安装教程

**您不仅可以在 Android 手机上运行本工具，亦可在 GNU/Linux 上运行。**

1.Android-Termux

```shell
    apt install -y curl
    bash -c "$(curl -LfsS 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

2.Debian/Ubuntu/Mint/Kali/Deepin/Devuan/MX 等 deb 系发行版

```shell
if [ ! -f /usr/bin/wget ]; then
    apt update
    apt install -y wget || sudo apt install -y wget || su -c "apt install -y wget"
fi
bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

3.RedHat/Fedora/CentOS

```shell
    dnf install -y curl || yum install -y curl
    bash -c "$(curl -LfsS 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

4.Arch/Manjaro

```shell
    pacman -Syu --noconfirm curl
    bash -c "$(curl -LfsS 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

5.OpenWRT/Entware

```shell
    opkg update
    opkg install wget bash
    bash -c "$(wget --no-check-certificate -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

6.Alpine

```shell
    apk add -q wget
    busybox ash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

7.Void

```shell
    xbps-install -S
    xbps-install -y wget
    bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

8.其它 system 未测试,以下系统请自行解决依赖关系。  
例如:**Funtoo、Gentoo、OpenSuse**和**GuixSD**等发行版。  
还有 Unix 系统，例如：**MacOS、FreeBSD、OpenBSD、NetBSD**和**SunOS**等。  
相关依赖为 `git aria2 pv wget curl grep procps less tar xz newt(whiptail)`

---

### 使用说明

#### 简易版说明（萌新专用）

- 1.安装 Tmoe GNU/Linux 管理工具的命令(仅支持在原系统内输)

```shell
bash -c "$(curl -LfsS 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

> 进入工具后，按方向键和回车键进行操作，基本上所有操作都有提示。

[![Snipaste_2020-03-20_17-10-48.png](https://gitee.com/mo2/pic_api/raw/test/2020/03/20/0W0hSgimlmeXIBjO.png)](https://gitee.com/mo2/pic_api/raw/test/2020/03/20/0W0hSgimlmeXIBjO.png)

- 2.启动命令(仅支持在原系统内输)

```shell
debian
```

- 3.卸载命令(仅支持在原系统内输)

```shell
debian-rm
```

- 4.启动工具箱(同时支持，但管理的内容不同)

```shell
debian-i
```

- 5.启动 vnc 命令（同时支持）

```shell
startvnc
```

- 6.停止 vnc 命令（同时支持）

```shell
 stopvnc
```

---

### 完整版说明（Full description)

#### Step1. Install GNU/Linux container

##### 1-1. You can use the following command to install Tmoe GNU/Linux tool

安装 Tmoe GNU/Linux 管理工具的命令是

```shell
apt update
apt install -y wget
bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

**(旧版)视频教程**[链接](https://pan.baidu.com/s/1rh7Nkcd0gG9RPx77JyGqZA) 提取码: **debb**

##### 1-2.安装后的步骤

If you want to start GNU/Linux next time, you can just type `debian`.  
下次启动 GNU/Linux 的命令是  
`debian`

##### 关于 GNU/Linux 的重新安装与移除

输`debian-i` 启动工具箱，并自行选择重装和其它选项。
您也可以手动输`debian-rm`来移除已经安装的 GNU/Linux 容器。

#### Step2.安装图形化桌面环境

##### 2-1.安装前（关于桌面环境的安装与卸载）

进入 GNU/Linux 容器后，请从 _xfce、lxde、mate_ 中选择一种。

_gnome_ 和 _kde_ 是用来卖萌用的，不要安装。如需安装，请自行解决依赖关系和其它问题。
四选一！千万不要一下子装两个桌面！
后期注：_KDE_ 已经在 _chroot_ 环境中测试成功，但由于操作流畅度堪忧，且存在 bug，故和 _lxqt_ 一样移除了支持，但您仍然可以使用主目录下的脚本进行安装。

##### 2-2.安装中

安装过程会提示选择键盘布局，请直接按回车。
初次启动 vnc 服务，会提示输 6 至 8 位（**不可见**）的密码，输两遍。

> 当提示 _Would you like to enter a view-only password ？_ 时
> 输 **_n_**

##### 2-3.安装后

输`startvnc`启动 vnc 服务，
输`stopvnc`停止 vnc 服务。
完成后，打开 vnc viewer 客户端，输 `localhost:5901`

#### 其它说明

- 1.若无法退出 GNU/Linux 容器，则请在原系统内输`stopvnc`
- 2.若 zsh 配置失败，则请输`./zsh.sh`进行重新配置。
- 3.主目录下的 sh 文件可以删除，但 **sd、tf 和 termux** 三个目录**不要删**。
- 因为这三个目录挂载了设备存储空间，分别和内置存储、tf 卡(termux 专有目录)以及 termux 主目录联动。

#### 可选步骤

##### 1.修改 vnc 分辨率的方法

- 1-1.工具修改

在 GNU/Linux 容器内输`debian-i`打开工具箱，然后选择相关选项，需要注意的只有一点，x 为英文小写，不是乘号。

- 1-2.手动修改

```shell
apt install -y nano
nano /usr/bin/startvnc
```

> 将 **1440x720**（竖屏）改成你需要的分辨率，例如 **1920x10780**（横屏)
> 修改完成后，按`Ctrl+S` 保存，`Ctrl+X`退出。

##### 2.你可以装个浏览器来玩玩

~~输`./firefox.sh`安装 firefox 浏览器,输`./firefox.sh rm`卸载~~

~~chromium 浏览器的启动命令是 `chromium --no-sandbox`~~

相关软件的安装选项已经整合进**debian-i**内

##### 3.安装 Linux qq

```shell
wget -O linuxqq.deb https://qd.myapp.com/myapp/qqteam/linuxQQ/linuxqq_2.0.0-b1-1024_arm64.deb ; apt install -y ./linuxqq.deb
```

---

#### 更新日志

##### 2019-11、12 月

本文首发于酷安网@**萌系生物研究员**
旧版脚本部分命令借鉴了 atilo-cn 和 AnLinux，除此之外，大部分都是本人手打的。
可能会有出错的地方，欢迎指正。

##### 2020-02-15

> **完全重写脚本！**
> 和别人写的脚本已经完全不一样了，重点不在于安装的方式，而在于配置优化以及与安卓原系统的联动，难点在于一些鬼点子。

本来是不想维护的，但是我发现了一个很严重的 bug,所以干脆重写一遍。
本次更新的内容真的有点多，而且真的很强哦 ✨ ο(=•ω ＜=)ρ⌒☆，我自己都觉得太强了！
脚本文件已经达到了 40 多 KB 了。

##### 2020-02-15 更新内容

- 1.获取镜像途径依旧是清华镜像站，但把下载工具从 wget 换成了 aria2，从原本的单线程变成现在的 16 线程，加快了下载速度。

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

- ​ 14.vnc 支持自动获取本机局域网 ip，地址格式类似于 `192.168.123.3:5901`
  ​
