# android

天萌分为两个部分，分别是“管理器”和“工具箱”。  
对于 android，您可以使用“天萌管理器”。

## 1. 关于 docker

实际上，android 也可以运行 docker。  
您如果想要使用原生 docker，那么需要手动编译内核，加上 docker 所需的一些特性。  
如果您的内核没有开源，或者是您的设备无法解锁 bootloader, 那么您可能需要通过虚拟机来间接使用 docker 。

在本章中，我们并不会介绍以下内容：

- 如何为 android 重新编译内核
- 如何在 android 上运行 docker

## 2. 天萌管理器

如果您想要使用 “天萌管理器”，那么您可以使用脚本进行安装。

> 在 edition 2022 中，“天萌管理器” 叫做 `tmm`  
> 现阶段，天萌的大部分内容仍处于 edition 2021  
> 为了与旧版本的兼容，开发者之后会为 android 保留 `tmoe` 命令

对于 android, 您可以用 [termux](https://github.com/termux/termux-app/actions) 运行以下脚本。  
之后“二萌”可能会把相关内容打成 deb 包，也可能会适配其他的终端。

> 之所以使用`curl`, 是因为 termux 预装了它。  
> 如果它没有被预装的话，那么您需要使用 `apt update; apt install -y curl` 来安装。

| 方法 | 工具 | 条件                                          | 命令                               |
| ---- | ---- | --------------------------------------------- | ---------------------------------- |
| 1    | curl | 您已经安装了 `curl`,</br> 并且可以访问 github | `. <(curl -L l.tmoe.me/hub/sh)`    |
| 2    | curl | 您无法访问 github                             | `. <(curl -L l.tmoe.me/m/sh)`      |
| 3    | curl | 以上方法都出错了                              | `curl -Lo l l.tmoe.me/ee/sh; sh l` |

“tmoe-linux” 可能会改名, 也有可能因为某些原因而被封锁。  
上面的链接实际上会自动重定向到对应的 git 仓库。

## 3. chroot/unshare

您在 android 上使用天萌来安装 unshare 容器前，它会让你选择“共享/挂载 sd 目录”。  
对于 miui, 请不要选择整个 "/data/media/0" 或 "/sdcard"  
 请选择特定的子目录，例如 "/data/media/0/Download"。  
挂载整个内置 sd 可能会导致它在 `umount` 时被一同卸载。  
[issue1](https://gitee.com/mo2/linux/issues/I5488U)  
[issue2](https://github.com/2moe/tmoe-linux/discussions/166)

如果您坚持要做的话，那么请在挂载整个内置 sd 前，手动做个小测试。

```sh,editable
cd $TMPDIR
mkdir -pv sd
su -c "/system/bin/mount -o bind /sdcard $PWD/sd"
sudo ls sd
su -c "/system/bin/umount -lvf $PWD/sd"
ls /sdcard
```

看看发生了什么？

## 4. proot

| problem                  | note                                                                                 |
| ------------------------ | ------------------------------------------------------------------------------------ |
| 无法绑定 1024 以下的端口 | see this [issue](https://github.com/2moe/tmoe-linux/issues?q=is%3Aissue+is%3Aclosed) |

## 5. 命令

### 5.1. 在宿主环境中

#### 5.1.1. 对于 GUI 容器

- `startvnc`
  - 前提：您需要先安装 vnc viewer 或其他 vnc 客户端
  - 对于 android, 只有 vnc viewer 才会 “连携”启动
  - 作用：启动默认的 vnc 服务（一般是 tigervnc）
  <!-- - 对于 wsl, 只有 tigervnc viewer 才会 -->
- `startx11vnc`
  - 前提：条件同上
  - 作用：启动 x11vnc
- `stopvnc`
  - 此命令可以方便地干掉 rootless 容器（包含它的 vnc 服务进程）
  - 对于 chroot/unshare（rootful）容器, 您需要单独停止容器进程。
- `startxsdl`
  - 前提：您需要先在宿主环境中安装 xserver app
  - 作用：启动 xorg
- `novnc`
  - 前提：您无需安装常规的 vnc 客户端，只需有个浏览器就足够了
  - 作用：同时启动宿主的浏览器和容器内部的服务

#### 5.1.2. noGUI

对于 edition 2020:

- `debian`
  - 自动检测默认容器名称、类型和架构。在检测完成后，启动容器。

对于 edition 2021：

- `tmoe ls`
  - 自动判断默认容器类型，并列出容器列表
- `tmoe p`
  - 启动默认的 proot 容器
- `tmoe c`
  - 启动默认的 chroot/unshare 容器
- `tmoe` 或 `tmoe m`
  - 启动 tmoe manager

对于 edition 2022：

- `tmm r <容器名称>`
  - 例如 `tmm r uuu`
- `tmm`
  - 启动 tmoe manager

### 5.2. 在容器环境中

如果宿主支持“连携”启动，那么您无需在容器内单独启动 vnc 服务

- `tmoe` 或 `tmoe t`
  - 启动 tmoe tools
- `startvnc`
  - 启动默认的 vnc 服务（一般是 tigervnc）
- `startx11vnc`
  - 启动 x11vnc 服务
- `stopvnc`
  - 停止 vnc 服务
- `startxsdl`
  - 启动 xorg
- `novnc`
  - 启动 novnc

#### 对于 debian-based 发行版

- `tigervnc`
  - 启动 tigervnc 服务
- `tightvnc`
  - 启动 tightvnc 服务
