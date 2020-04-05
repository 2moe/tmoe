# 🍭Tmoe-linux

> 若无法加载 readme，则请手动打开[使用说明](https://gitee.com/mo2/linux/blob/master/README.md)

## 介绍

在 **GNU/Linux** 上一键安装 **GNU/Linux chroot** 容器。  
在 **Android Termux** 上一键安装 **GNU/Linux proot** 容器。  
🍸 目前支持：

- [x] **Debian buster/sid**
- [x] **Ubuntu 20.04**
- [x] **Kali rolling**
- [x] **Funtoo**
- [x] **Void**  
       ✨ 支持自动配置中文环境，并执行其它优化步骤。🍹  
       所有的配置和优化步骤仅适用于 deb 系！

![Capture__2020-02-16-02-23-49.png](https://gitee.com/mo2/pic_api/raw/test/2020/02/16/KtxgGq3bFSf4Uwvo.png)

支持一键安装图形界面。

![截图_2020-02-01_08-53-21.jpg](https://gitee.com/mo2/pic_api/raw/test/2020/02/16/yMgxSkGh0Tx4IJz0.jpg)

### 软件架构

Debian 容器支持 **arm64(aarch64)、armhf、armel、amd64(x86_64) 、i386(x86)、s390x 和 ppc64el**

~~可以支持，但不想支持的是 **mipsel**~~

2020-03-24 已经支持 **mipsel** 架构了！(已经在路由器上测试过了 🍥)

可能支持 **RISC-V** (靠理论知识写出来的，未实际测试。由于现在暂时无法构建 risc-v 的基础容器镜像，故只能靠 qemu 在 risc-v 的设备上模拟其它架构的系统。）

这可能是你见过的为数不多的，全架构 ~~、全平台~~ 项目。 ~~（win10 仅支持 wsl，不是全平台)~~

其它系统容器可能只支持主流的 amd64、arm64 等架构，不支持 s390x 和 ppc64el 等冷门架构。

### 不同平台的安装教程

**您不仅可以在 Android 手机上运行本工具，亦可在 GNU/Linux 上运行。**

#### 1.Windows10

教程：  
![我不知道怎么用](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/247f4fvoKnj56MwN.png)  
![以admin身份运行powershell](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/h4IrTwyx4AaC8joE.png)

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

重启系统后再次以管理员身份运行 _powershell_ ，然后输

```powershell
wsl --set-default-version 2
```

[![enable](https://i.loli.net/2020/04/03/I9zdphVgMc5Zky3.png)](https://sm.ms/image/I9zdphVgMc5Zky3)  
![store](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/FLpQu0i7LbIP2K9L.png)  
若无法连接 _Microsoft Store_,那么也可以手动安装。  
请从以下三者中选择：  
[Debian](https://aka.ms/wsl-debian-gnulinux)  
[Kali](https://aka.ms/wsl-kali-linux-new)  
[Ubuntu](https://aka.ms/wsl-ubuntu-1804)

打开子系统，然后根据提示更新 WSL2 的 linux 内核。更新完成后，当提示输普通账号用户名时，直接关掉窗口。

> 注：这样子默认就是 root 账号，可以省下输 sudo 密码的步骤，之后可以使用 adduser 命令来单独增加普通账号。默认以非管理员身份运行的子系统 root 账号并没有 windows 管理员权限哦！只拥有 linux 的 root 权限而已，要是以管理员身份运行子系统的话，就真的要谨慎操作了。PC 用 root 账号的问题不大，又不是服务器。

重新打开子系统，然后输

_**精简命令**_

```shell
    wget -qO- l.tmoe.me | bash
```

> 注：精简命令和长命令调用的内容是一样的，二选一即可。  
> 区别在于长命令重复安装了 wget。  
> 建议使用精简命令，除非 wget 被您不慎卸载掉了。

_**长命令**_

```shell
    apt update
    apt install -y wget
    bash -c "$(wget -qO- 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
```

最后按方向键和回车键进行操作。

> 注：WSL 请选择安装工具

![你这个小可爱](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/EOErMiCMvxKOTUI1.png)  
![不可以骂人家](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/WJRMr0Gk64p5D2eJ.png)  
![并没有在说你](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/b2oKdVCvZmlx9aZI.png)  
![01](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/kGTCjub8kg4WbMU6.png)  
![02](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/5B20sqYFe0ZV15Hg.png)  
![03](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/UvqZWPa3XSkEEprK.png)
![04](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/CLvZ5AQaslZDZHWu.png)  
![05](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/gXWDvCibdouH6IqX.png)

> 后期注：建议 WSL 用户直接安装 gui ，不要在里面先套娃安装 chroot 容器，再装 gui，因为这将导致 windows 程序调用失败。

![停止VNC](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/KvMfXNGnHKbspTNs.png)  
![stopvnc](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/buq1rhY6i55M2Dv4.png)  
![06](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/6CDOlyOZb6qDbYqb.png)  
![07](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/GrPC2ckH7KavXw0p.png)  
![08](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/DZNjgwyVIrUjd3TH.png)  
![09](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/ACPJKw4lYfedt9D6.png)  
![10](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/nqvK1beXuKXsrljA.png)  
![11](https://gitee.com/mo2/pic_api/raw/test/2020/03/24/3luF9hHGPnPuhwHu.png)  
![12](https://gitee.com/mo2/pic_api/raw/test/2020/03/24/YsZou4mIXZUFUYdZ.png)

![14](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/56LaqsyefesPOa2t.png)  
![perfect](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/ILwcxdCOYVCS3lB6.png)

#### 2.Android-Termux

> 1.安装安装安卓版[Termux](https://apk.tmoe.me/termux) 和[Termux:api](https://mirrors.tuna.tsinghua.edu.cn/fdroid/repo/com.termux.api_41.apk)  
> 2.打开 termux，输入以下命令

_**精简命令**_

```shell
    curl -sL l.tmoe.me | bash -
```

> 注：精简命令和长命令调用的内容是一样的，二选一即可。

_**长命令**_

```shell
    apt install -y curl
    bash -c "$(curl -LfsS 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
```

> 3.如需使用 gui,可能还需安装 VNC apk  
> 注：web 端的 novnc 无需安装 apk,但触控操作体验不佳。

#### 3.Debian/Ubuntu/Mint/Kali/Deepin/Devuan/MX 等 deb 系发行版

_**精简命令**_

```shell
    wget -qO- l.tmoe.me | bash
```

> 注：精简命令和长命令调用的内容是一样的，二选一即可。  
> 区别在于长命令增加了 wget 的检测。  
> 超精简的 debian 容器镜像内可能无 wget 和 sudo。  
> 尽管大部分 deb 系列发行版使用 apt 安装软件时都需要 root 权限，但却有极少部分系统禁止以 root 权限运行，故并非一开始就调用 su -c  
> 例如：使用 apt 包管理的 Android Termux，禁止以 root 权限运行 apt install

_**长命令**_

```shell
if [ ! -f /usr/bin/wget ]; then
    apt update || sudo apt update || su -c "apt update"
    apt install -y wget || sudo apt install -y wget || su -c "apt install -y wget"
fi
bash -c "$(wget -qO- 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
```

#### 4.RedHat/Fedora/CentOS

```shell
    dnf install -y curl || yum install -y curl
    bash -c "$(curl -LfsS 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
```

#### 5.Arch/Manjaro

```shell
    pacman -Syu --noconfirm curl
    bash -c "$(curl -LfsS 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
```

#### 6.OpenWRT/Entware

```shell
    opkg update
    opkg install wget bash
    bash -c "$(wget --no-check-certificate -qO- 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
```

#### 7.Alpine

```shell
    apk add -q wget
    wget -qO- 'https://gitee.com/mo2/linux/raw/master/debian.sh' | ash
```

#### 8.Void

```shell
    xbps-install -S
    xbps-install -y wget
    bash -c "$(wget -qO- 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
```

#### 9.Gentoo/Funtoo

```shell
    emerge -av net-misc/wget
    bash -c "$(wget -qO- 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
```

#### 10.其它 system 未测试,以下系统请自行解决依赖关系

例如:**OpenSuse**和**GuixSD**等发行版。

相关依赖为 `git aria2 pv wget curl grep procps less tar xz newt(whiptail)`

---

### 使用说明

#### 简易版说明（萌新专用）

- 1.安装 Tmoe GNU/Linux 管理工具的命令(仅支持在原系统内输)

```shell
bash -c "$(curl -LfsS 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
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
bash -c "$(wget -qO- 'https://gitee.com/mo2/linux/raw/master/debian.sh')"
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

> 后期注：_KDE_ 已经在 _chroot_ 环境中测试成功，但由于操作流畅度堪忧，且存在 bug，故和 _lxqt_ 一样移除了支持，但您仍然可以使用主目录下的脚本进行安装。

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

---

#### 更新日志

##### 2019-11、12 月

本文首发于酷安网@**萌系生物研究员**
旧版脚本部分命令借鉴了 atilo-cn 和 AnLinux，除此之外，大部分都是本人手打的。
可能会有出错的地方，欢迎指正。

> ~~后期注:Anlinux 的脚本有些地方写得并不好，并且我知道它存在的某些缺陷。反正原作者也看不到，所以我在这里调侃也没事。😹
> 你去了解更本质的东西就知道哪些地方写得不好了！`(_>﹏<_)′
> 相比之下，Linux Deploy 的开发者写的东西要比他强很多。~~

##### 2020-02-15

> **完全重写脚本！**
> 和别人写的脚本已经**完全不一样**了，重点不在于安装的方式，而在于配置优化以及与安卓原系统的联动，难点在于一些鬼点子。

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

---

​
**之后的更新内容真的是太多了，有空的话会从酷安原帖搬过来的。其中最突出的更新内容是将安装 gui 和其它软件、管理远程桌面配置等内容整合在 GNU/Linux 容器内的 debian-i 里，以及修复了 VNC 音频传输中可能存在的一些问题。**

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
  当检测到设备为 riscv 架构时，将下载 arm64 架构版的容器镜像。
  调用 qemu+chroot 来实现跨 CPU 架构运行容器，这是一个理论性操作，未实际测试。

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
> ![GlyxZ8.png](https://s1.ax1x.com/2020/04/01/GlyxZ8.png)  
> WSL2 与宿主机原系统（win10）的交互联动要比普通虚拟机强数倍，在 linux 子系统下可以直接调用 powershell.exe 等 windows 程序。  
> ~~如上图所示，目前已经可以接近完美地将 win10 和 GNU/Linux 融为一体。~~

##### 2020-04-02 更新日志

- 1.支持非 root 用户配置 vnc 服务
- 2.修复大量 bug
