# The following are no longer applicable in the new version

## gui

### xfce

#### 安装方法

(至少有 16 种方法可以安装，下面列举 8 种)

```shell
       ./xfce.sh

       ./xfce.sh i

       ./xfce.sh in

       ./xfce.sh install

       ~/xfce.sh

       bash xfce.sh

       bash xfce.sh i

       bash ~/xfce.sh
```

#### xfce 的卸载方法

```shell
       ./xfce.sh rm

       ./xfce.sh remove

       ./xfce.sh un

       ./xfce.sh uninstall

       ./xfce.sh purge

       bash xfce.sh rm

      bash ~/xfce.sh rm
```

（下面相似，故省略）
输`./mate.sh`或 bash mate.sh 安装 mate; 输./mate.sh rm 卸载
输.`/lxde.sh`安装 lxde; 输 ./lxde.sh rm 卸载
输.`/lxqt.sh`安装 lxqt; 输 ./lxqt.sh rm 卸载

gnome 和 kde 是用来卖萌用的，不要安装。如需安装，请自行解决依赖关系和其它问题。
四选一！千万不要一下子装两个桌面！

在 termux 原系统输 startvnc 将自动启动 vnc 客户端+debian 系统+vnc 服务端，若无启动提示，请在进入 debian 后，再输一遍 startvnc

## 其它

### 可选步骤（Optional step）

输`./kali.sh`更换为 kali 源，输`./kali.sh rm` 移除 kali 源。

#### 1.This script should be run via curl

```shell
apt install -y curl
bash -c "$(curl -fsSL 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

#### 2. or wget

```shell
apt update
apt install -y wget
bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```
