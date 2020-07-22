# 🍭Tmoe-linux

```shell
. <(curl -L git.io/linux.sh)
```

> If you do not understand the following readme, please give me an issue to explain the situation,or open [README.en.md](https://github.com/2moe/tmoe-linux/blob/master/README.en.md)  
> 化繁为简，让 GNU/Linux 的乐趣触手可及。

## 介绍 Introduction

🍭Without any basic knowledge of linux shell,🍹 you can run GNU/Linux on your android phone and windows PC, and you can easily install a graphical desktop environment and configure pulseaudio server.✨
You can also run Gentoo, Arch and other systems in WSL.

在 **GNU/Linux**、**Android Termux** 和**Windows10 的 linux 子系统**上配置 **GNU/Linux chroot 或 proot** 容器环境，并 configure remote desktop、pulseaudio 音频服务和 system。

### 一：Android 篇

1.Debian container  
① 在 Android 系统上运行 debian GNU/Linux arm64 应用。  
Running debian GNU/Linux arm64 container application on Android system.
![debian arm64](https://images.gitee.com/uploads/images/2020/0721/190834_db02f784_5617340.png "截图_2020-07-15_13-48-40.png")  
② 跨架构支持，在 Qualcomm 高通 arm64 cpu 的手机上借助 qemu-user 来模拟运行 x86(i686)架构的 Debian GNU/Linux，并通过 pulseaudio 来传输音频。  
Support cross-architecture running containers, use qemu-user-static on Qualcomm arm64 phone to simulate Debian GNU/Linux x86 architecture, and transmit audio through termux pulseaudio server.
![debian i386](https://images.gitee.com/uploads/images/2020/0721/192119_96d0b95d_5617340.png "Screenshot_20200721-173852.png")  
2.Ubuntu container  
在 Android 设备上运行的 Ubuntu 容器，你可以通过 VNC 来连接自己；  
通过 adb 远程来调试自己(Android)；  
还能通过 scrcpy+adb 调试来实现自己投屏给自己，将手机中 VNC 的画面投屏给手机中的 VNC。  
For Ubuntu containers running on Android devices, you can connect to the desktop through a VNC client. And remotely debug this device (Android) through adb.  
You can also use scrcpy+adb to cast screen.  
![ubuntu arm64 scrcpy](https://images.gitee.com/uploads/images/2020/0721/192606_c10e724e_5617340.png "截图_2020-07-18_23-08-59.png")  
3.美化功能 Desktop environment beautification function  
十年 Mint 和 Ubuntu 壁纸包+主题解析功能。  
Mint and Ubuntu wallpaper packs for the past ten years.
![wallpaper01](https://images.gitee.com/uploads/images/2020/0721/193421_cb268a12_5617340.png "截图_2020-07-11_08-56-45.png")

### 番外篇 Extra

🍸 目前支持的容器：
Supported containers:

- [x] **Debian stable+sid**
- [x] **Ubuntu LTS+dev**
- [x] **Kali rolling**
- [x] **Arch**
- [x] **Fedora**
- [x] **CentOS**
- [x] **Gentoo**
- [x] **Funtoo**
- [x] **Alpine edge**
- [x] **OpenSUSE tumbleweed**
- [x] **Void**
- [x] **Raspbian**
- [x] **Mint**
- [x] **Devuan**
- [x] **Slackware**
- [x] **Armbian**

  配置和优化步骤仅适用于 Debian、Ubuntu、Kali、Arch、Fedora 和 Gentoo(x64)。  
  🍹
  All configuration and optimization steps only apply to Debian,Ubuntu,Kali,Fedora and Arch.

部分功能预览 Preview：
![secret garden](https://images.gitee.com/uploads/images/2020/0721/221603_079fc8d5_5617340.png "Capture+_2020-07-21-22-12-33.png")  
![steam](https://images.gitee.com/uploads/images/2020/0721/221625_594e5123_5617340.png "Capture+_2020-07-21-22-13-13.png")

### 二：System Configuration 系统配置篇

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

### 三：Remote Desktop Configuration 远程桌面配置篇

1.支持一键安装图形界面。  
Support one-key graphical user interface installation.
![de&wm](https://images.gitee.com/uploads/images/2020/0721/202944_b98d0e7b_5617340.png "Capture+_2020-07-21-20-09-40.png")

2.TUI 式界面，便捷配置  
Convenient configuration  
![remote-desktop](https://images.gitee.com/uploads/images/2020/0721/203123_33c2b6ac_5617340.png "Capture+_2020-07-11-10-01-26.png")  
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
- [ ] **lxqt**
- [ ] **kde plasma 5**
- [ ] **cinnamon**
- [ ] **gnome 3**
- [ ] **deepin desktop**

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
4-3.GNOME3 的 VNC 配置脚本也没有问题。  
Configure vnc for gnome3.  
虽然在 Proot 容器上跑可能会出问题，但是换 qemu-system 虚拟机后就没问题了。
![Screenshot_20200608-003126.png](https://images.gitee.com/uploads/images/2020/0718/103733_9b989b37_5617340.png)

### 四：Software configuration 软件配置篇

1.提供了某些官方软件源中不包含的软件包，例如 vscode。
![vscode_desktop_version](https://s1.ax1x.com/2020/04/23/JUWnW6.jpg)  
You can install vscode in the container of your phone.
你可以在手机的容器里安装 vscode。  
2.对于部分工具提供了配置管理功能，例如 arm64 的 vscode-server。  
3.对于特定虚拟化环境下运行报错的应用执行打补丁操作。  
4.对 aria2 上百个参数进行配置管理。
![aria2 ua](https://images.gitee.com/uploads/images/2020/0721/210921_a65d7e0e_5617340.png "Capture+_2020-07-21-21-06-15.png")
![aria2 bt](https://images.gitee.com/uploads/images/2020/0721/210908_43268dda_5617340.png "Capture+_2020-07-21-21-05-48.png") 5.对输入法进行安装和配置。

### 五 .支持的架构 Supported architecture

Debian 容器支持 **arm64(aarch64)、armhf、armel、amd64(x86_64) 、i386(x86)、s390x 和 ppc64el**

~~可以支持，但不想支持的是 **mipsel**~~
In addition, the **mipsel** architecture is also supported! The developer has tested it on the router

2020-03-24 已经支持 **mipsel** 架构了！(已经在路由器上测试过了 🍥)

可能支持 **RISC-V** (靠理论知识写出来的，未实际测试。由于现在暂时无法构建 risc-v 的基础容器镜像，故只能靠 qemu 在 risc-v 的设备上模拟其它架构的系统。）

这可能是你见过的为数不多的，全架构 ~~、全平台~~ 项目。 ~~（win10 仅支持 wsl，不是全平台)~~

Containers other than debian may only support mainstream architectures, not s390x and ppc64el.
其它系统容器可能只支持主流的 amd64、arm64 等架构，不支持 s390x 和 ppc64el 等冷门架构。

    	下表中的所有系统均支持x64和arm64
      All systems in the table below support x64 and arm64
    	*表示仅旧版支持
    		╔═══╦════════════╦════════╦════════╦═════════╦
    		║   ║Architecture║        ║        ║         ║
    		║   ║----------- ║ x86    ║armhf   ║ppc64el  ║
    		║   ║System      ║        ║        ║         ║
    		║---║------------║--------║--------║---------║
    		║ 1 ║  Debian    ║  ✓     ║    ✓  ║   ✓     ║
    		║   ║            ║        ║        ║         ║
    		║---║------------║--------║--------║---------║
    		║   ║            ║        ║        ║         ║
    		║ 2 ║  Ubuntu    ║  ✓     ║  ✓    ║   ✓     ║
    		║---║------------║--------║--------║---------║
    		║   ║            ║        ║        ║         ║
    		║ 3 ║ Kali       ║  ✓     ║   ✓   ║    X    ║
    		║---║------------║--------║--------║---------║
    		║   ║            ║        ║        ║         ║
    		║ 4 ║ Arch       ║  X     ║   ✓    ║   X     ║
    		║---║------------║--------║--------║---------║
    		║   ║            ║        ║        ║         ║
    		║ 5 ║ Fedora     ║ *<=29  ║ *<=29  ║  ✓      ║
    		║---║------------║--------║--------║---------║
    		║   ║            ║        ║        ║         ║
    		║ 6 ║  Alpine    ║  ✓     ║    ✓  ║   ✓     ║
    		║---║------------║--------║--------║---------║
    		║   ║            ║        ║        ║         ║
    		║ 7 ║ Centos     ║ *<=7   ║ *<=7   ║   ✓     ║

### 六.不同平台的安装教程 Installation tutorials for different platforms

**You can run this tool not only on Android, but also on GNU/Linux.**

**您不仅可以在 Android 手机上运行本工具，亦可在 GNU/Linux 上运行。**

#### 1.Windows10

Tutorial（教程）：  
![我不知道怎么用](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/247f4fvoKnj56MwN.png)  
Q:I don't know how to use it?  
![以admin身份运行powershell](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/h4IrTwyx4AaC8joE.png)  
A:Run PowerShell as an administrator and enter the following command.

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

重启系统后再次以管理员身份运行 _powershell_ ，然后输下面 wsl 开头的命令。  
After restarting the system, run _powershell_ again as an administrator, then press the following command.

```powershell
wsl --set-default-version 2
```

[![enable](https://i.loli.net/2020/04/03/I9zdphVgMc5Zky3.png)](https://sm.ms/image/I9zdphVgMc5Zky3)  
![store](https://s1.ax1x.com/2020/04/23/JUW3eH.png)  
When you download the subsystem from the Microsoft Store, be sure to choose Ubuntu, Kali and Debian.  
若无法连接 _Microsoft Store_,那么也可以手动安装。  
请从以下三者中选择：  
[Debian](https://aka.ms/wsl-debian-gnulinux)  
[Kali](https://aka.ms/wsl-kali-linux-new)  
[Ubuntu](https://aka.ms/wsl-ubuntu-1804)

Open the subsystem and update the Linux kernel of WSL2 according to the prompt. After the update is complete, when prompted to enter the user name of the UNIX account, if you do not care about security issues, then you can close the window directly. The advantage of this is that you do not need to enter the sudo password.  
打开子系统，然后根据提示更新 WSL2 的 linux 内核。更新完成后，当提示输普通账号用户名时，直接关掉窗口。

> 注：这样子默认就是 root 账号，可以省下输 sudo 密码的步骤，之后可以使用 adduser 命令来单独增加普通账号。默认以非管理员身份运行的子系统 root 账号并没有 windows 管理员权限哦！只拥有 linux 的 root 权限而已，要是以管理员身份运行子系统的话，就真的要谨慎操作了。PC 用 root 账号的问题不大，又不是服务器。

Restart the subsystem
重新打开子系统

_**If you do not live in China, please enter**_

```shell
    sudo apt update
    sudo apt install -y curl
    bash -c "$(curl -L git.io/linux.sh)"
```

_**如果你在国内,那么请输**_

```shell
    sudo apt update
    sudo apt install -y curl
    bash -c "$(curl -L l.tmoe.me)"
```

> 注:前后两者调用的内容是不一样的，二选一即可。  
> 区别在于后者对国内的网络进行了优化。

最后按方向键和回车键进行操作。  
Finally, press Enter and arrow keys to operate.

> 注：WSL 请选择安装工具  
> When prompted Tool/Manager, please select Tool

![000](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/EOErMiCMvxKOTUI1.png)  
**Just press enter and arrow keys, it's so simple, you are really adorkable!**  
![001](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/WJRMr0Gk64p5D2eJ.png)  
**How can you scold me?**  
![002](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/b2oKdVCvZmlx9aZI.png)  
**I'm not talking about you!**  
![01](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/kGTCjub8kg4WbMU6.png)  
**How to start the X server?**  
![02](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/5B20sqYFe0ZV15Hg.png)  
**Just enter `startxsdl`, it should be ok**  
![03](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/UvqZWPa3XSkEEprK.png)  
**How to start the VNC?**  
![04](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/CLvZ5AQaslZDZHWu.png)  
**Just enter `startvnc`**  
**And you can also enter `debian-i` to start the tmoe-linux tool**  
![05](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/gXWDvCibdouH6IqX.png)

> 后期注：建议 WSL 用户直接安装 gui ，不要在里面先套娃安装 chroot 容器，再装 gui，因为这将导致 windows 程序调用失败。

![停止VNC](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/KvMfXNGnHKbspTNs.png)  
**How to stop VNC?**  
![stopvnc](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/buq1rhY6i55M2Dv4.png)  
**Oh,I know,enter `stopvnc`**  
![06](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/6CDOlyOZb6qDbYqb.png)  
**Can anyone tell me how to modify the resolution?**  
![07](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/GrPC2ckH7KavXw0p.png)  
**Nobody answered, only read the [readme](https://github.com/2moe/tmoe-linux/blob/master/README.en.md) written by the developer.**  
![08](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/DZNjgwyVIrUjd3TH.png)  
![09](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/ACPJKw4lYfedt9D6.png)  
**Wow! This is too complicated, I can't remember the order at all.**  
![10](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/nqvK1beXuKXsrljA.png)  
**WSL users only need to remember `startxsdl`**  
**Android users only need to remember `startvnc`.**  
![11](https://gitee.com/mo2/pic_api/raw/test/2020/03/24/3luF9hHGPnPuhwHu.png)  
![12](https://gitee.com/mo2/pic_api/raw/test/2020/03/24/YsZou4mIXZUFUYdZ.png)

![14](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/56LaqsyefesPOa2t.png)  
**I think the script you wrote is garbage, I don’t want to use it!**  
![perfect](https://gitee.com/mo2/pic_api/raw/test/2020/04/03/ILwcxdCOYVCS3lB6.png)

**If you don’t like it, you don’t have to use it.But few peope integrate win10 and linux so perfectly.**

#### 2.Android-Termux

> 1.Go to google play, then install [Termux](https://play.google.com/store/apps/details?id=com.termux) and [Termux:api](https://play.google.com/store/apps/details?id=com.termux.api)  
> 2.Open termux and enter the following command.
>
> 1.安装安卓版[Termux](https://apk.tmoe.me/termux) 和[Termux:api](https://mirrors.tuna.tsinghua.edu.cn/fdroid/repo/com.termux.api_41.apk)  
> 2.打开 termux，输入下面 bash 开头的命令

_**If you do not live in China, please enter**_

```shell
    . <(curl -L git.io/linux.sh)
```

_**如果你在国内,那么请输**_

```shell
    . <(curl -L l.tmoe.me)
```

> 3-EN.Goto Google Play,then install [VNC client](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android) or [X server](https://play.google.com/store/apps/details?id=x.org.server)
>
> 3-CN.如需使用 gui,可能还需要安装 VNC apk,您可以前往 Google play 或使用 Tmoe-linux 的 debian-i 来下载。  
> 注：web 端的 novnc 无需安装 apk,但触控操作体验不佳。

#### 3.Debian/Ubuntu/Mint/Kali/Deepin/Devuan/MX 等 deb 系发行版

_**If you do not live in China, please enter**_

```shell
    sudo apt update
    sudo apt install -y wget
    bash -c "$(wget -O- https://git.io/linux.sh)"
```

_**如果你在国内,那么请输**_

```shell
     sudo apt update
     sudo apt install -y wget
     bash -c "$(wget -O- l.tmoe.me)"
```

#### 4.RedHat/Fedora/CentOS

```shell
    dnf install -y curl || yum install -y curl
    bash -c "$(curl -L https://git.io/linux.sh)"
```

#### 5.Arch/Manjaro

```shell
    pacman -Syu --noconfirm curl
    bash -c "$(curl -L https://git.io/linux.sh)"
```

#### 6.OpenWRT/Entware

```shell
    opkg update
    opkg install libustream-openssl ca-bundle ca-certificates wget bash
    bash -c "$(wget --no-check-certificate -O- https://git.io/linux.sh)"
```

#### 7.Alpine

```shell
    apk update
    apk add wget bash
    wget -O /tmp/.tmoe-linux.sh https://git.io/linux.sh
    bash /tmp/.tmoe-linux.sh
```

#### 8.Void

```shell
    xbps-install -S
    xbps-install -y wget
    bash -c "$(wget -O- https://git.io/linux.sh)"
```

#### 9.Gentoo/Funtoo

```shell
    emerge -avk net-misc/wget
    bash -c "$(wget -O- https://git.io/linux.sh)"
```

#### 10.其它 system 未测试,以下系统请自行解决依赖关系

例如:**OpenSuse**和**GuixSD**等发行版。

相关依赖为 `git aria2 pv wget curl grep procps less tar xz newt(whiptail)`

---

### 七.使用说明

#### 简易版说明（萌新专用）Novice tutorial

- 1.安装 Tmoe GNU/Linux 管理工具的命令(仅支持在原系统内输)
- Enter the following command in the terminal.

```shell
bash -c "$(curl -L https://git.io/linux.sh)"
```

> After executing the command, press the enter and arrow keys to operate, basically all operations have prompts.  
> 进入工具后，按方向键和回车键进行操作，基本上所有操作都有提示。

[![Snipaste_2020-03-20_17-10-48.png](https://gitee.com/mo2/pic_api/raw/test/2020/03/20/0W0hSgimlmeXIBjO.png)](https://s1.ax1x.com/2020/04/23/JUWw6S.md.png)

- 2.Command to enter the container
- 启动命令(仅支持在原系统内输)

```shell
debian
```

- 3.Command to remove the container
- 卸载命令(仅支持在原系统内输)

```shell
debian-rm
```

- 4.Start the toolbox, which can be executed in the original system and container, but the management content is different.
- 启动工具箱(同时支持，但管理的内容不同)

```shell
debian-i
```

- 5.Command to start vnc
- 启动 vnc 命令（同时支持）

```shell
startvnc
```

- 6.Command to stop vnc
- 停止 vnc 命令（同时支持）

```shell
 stopvnc
```

---

#### 完整版说明（Full description)

#### Step1. Install GNU/Linux container

##### 1-1. You can use the following command to install Tmoe GNU/Linux tool

安装 Tmoe GNU/Linux 管理工具的命令是

```shell
apt update
apt install -y wget
bash -c "$(wget -O- https://git.io/linux.sh)"
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
nano $(command -v startvnc)
```

> 将 **1440x720**（竖屏）改成你需要的分辨率，例如 **1920x10780**（横屏)
> 修改完成后，按`Ctrl+S` 保存，`Ctrl+X`退出。

##### 2.你可以装个浏览器来玩玩

~~输`./firefox.sh`安装 firefox 浏览器,输`./firefox.sh rm`卸载~~

~~chromium 浏览器的启动命令是 `chromium --no-sandbox`~~

相关软件的安装选项已经整合进**debian-i**内

---

### 八.更新日志 logs

##### 2019-11、12 月

本文首发于酷安网@**萌系生物研究员**
旧版脚本部分命令借鉴了 atilo-cn 和 AnLinux，除此之外，大部分都是本人手打的。
可能会有出错的地方，欢迎指正。

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

![Snipaste_2020-03-24_05-36-44.png](https://s1.ax1x.com/2020/04/23/JUWsTs.png)

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

##### 2020-04-10 更新日志

- 1.加入测试版容器 arch,fedora,centos.raspbian,mint 等等

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
- 注：我仅测试了 xfce4。未测试的桌面可以配置，但可能存在无法连接的问题。
- 特点：可以打开 X11VNC 无法打开的某些应用，但是 bug 超级多。
- 由于 bug 实在过多，故我已经不想维护了。
  ![Screenshot_20200507-193422_1.png](https://i.loli.net/2020/05/08/JhLxPTor1GiDgtY.png)
  ![Screenshot_20200507-222532.png](https://i.loli.net/2020/05/08/QJp8LelVakxyqA5.png)
  触控操作体验极差！建议使用蓝牙鼠标进行操作！  
  由于目前在 Android 手机上暂时无法使用 gpu 硬件渲染加速，故实际体验非常糟糕！
  不建议配置该服务!  
  等 wayland 完善之后，再来继续优化吧！

##### 2020-05-09 至 2020-05-10 更新日志

- 1.全面升级备份与还原功能，支持自定义备份文件名称。自动检测备份文件路径，也可以手动选择路径，然后会自动将备份文件排成一个列表，你只需输选项数字并按回车即可恢复所选文件。
- 2.优化 cookie 文件选择功能，支持图形化文件浏览。
  因为改了太多内容了，也没有继续做兼容性测试，所以不确定路由器等嵌入式设备还能不能继续兼容。
- 3.修复 Android-Termux 赋予 proot 容器真实 root 权限的功能，原因是 termux 更新了 tsu，将 tsudo 切换至 sudo。
- 4.deb 系 Linux 现在也可以用 proot 容器啦！

##### 2020-05-11 更新日志

- 1.支持配置 X11vnc 服务, 比 XSDL 强太多。
- 输`startx11vnc`启动，输`stopx11vnc`停止。
- 2.支持安装窗口管理器
  ![Snipaste_2020-05-11_21-36-18.png](https://i.loli.net/2020/05/11/ZIF7G9jApySEDeV.png)
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
- 5.增加 tmoe-deb 软件包安装器，支持在脚本内选择并安装 deb 文件。deb 系发行版使用此功能会自动解决依赖关系，但非 deb 系不会。

##### 2020-05-21 更新日志

- 1.全面升级换源功能，支持选择多个镜像站。debian,ubuntu,kali,arch,manjaro,fedora 和 alpine 可以单独使用换源功能。

##### 2020-05-22 更新日志

- 1.修复 Ubuntu20.10 存在的各种问题。
- 2.修复 arm64 架构上的[Rocket1184/electron-netease-cloud-music](https://github.com/Rocket1184/electron-netease-cloud-music)
- ![163music](https://images.gitee.com/uploads/images/2020/0522/221902_3490dfd0_5617340.png "截图_2020-05-22_21-43-28.png")

- 3.镜像站支持测延迟+测速，支持强制信任软件源，去除多余行，一键切换 http/https。
- 除了主要源外，还支持配置额外源。对于不同的发行版，显示的额外源是不同的。对于 debian,显示的是切换为 kali 源。对于 arch，显示的是配置 archlinux-cn 源。对于 centos，显示的是 epel 源。

##### 2020-05-23 更新日志

- 1.修复 code-server

##### 2020 年 05 月末 更新日志

- 1.加入 qemu 配置功能，支持高度的自定义配置。
- 以 CPU 这一块为例，支持配置 cpu 核心数，cpu 类型，加速类型，多线程。
- 其中仅 x86_64 架构就可选 200 多种 CPU 类型。
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
  ![Snipaste_2020-07-21_14-30-25.png](https://i.loli.net/2020/07/21/3imujvP19gnHqLh.png)
