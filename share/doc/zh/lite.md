# T Moe

化繁为简，让 gnu/linux 的乐趣触手可及。

## 1. 目录

### 1.1. 主要

| 章节                    | 简介                           | 文件      |
| ----------------------- | ------------------------------ | --------- |
| 序章前篇                | 用简短的说明带您领略其中的魅力 | lite.md   |
| [序章后篇](./readme.md) | 历史与发展                     | readme.md |
| [第一章](./1.md)        | 容器的安装与配置               | 1.md      |
| [第二章](./2.md)        | 错误处理                       | 2.md      |
| [第三章](./3.md)        | 介绍 vscode & haskell 等容器   | 3.md      |

### 1.2. 本章

中文 | [English](../../../Readme.md)

- [1. 目录](#1-目录)
  - [1.1. 主要](#11-主要)
  - [1.2. 本章](#12-本章)
- [2. 快速上手](#2-快速上手)
  - [2.1. 容器镜像](#21-容器镜像)
    - [GUI 容器](#gui-容器)
    - [noGUI](#nogui)
  - [2.2. 本地安装](#22-本地安装)
- [3. 有问题?](#3-有问题)
- [4. 许可证](#4-许可证)
- [5. 我可以干什么?](#5-我可以干什么)
- [6. 翻页](#6-翻页)

## 2. 快速上手

### 2.1. 容器镜像

#### GUI 容器

Q: 我必须要跑个脚本才能安装 tmoe 吗？

A: 不！ 完全不需要。  
您如果想在非移动平台上使用本项目，那么可以使用预装本项目的 docker 容器镜像。  
除特殊情况外，以下容器每周都会更新。

> 如果以下内容在移动端排版有问题的话，则请切换为桌面版视图。

|         | xfce              | kde               | mate                  | lxqt        | cutefish          | lxde      |
| ------- | ----------------- | ----------------- | --------------------- | ----------- | ----------------- | --------- |
| alpine  | amd64,arm64       | amd64,arm64       | 386,amd64,arm64,armv7 | None        | None              | None      |
| arch    | amd64,arm64,armv7 | amd64,arm64       | amd64,arm64           | None        | amd64,arm64,armv7 | None      |
| debian  | amd64,arm64       | amd64,arm64       | amd64,arm64           | None        | None              | 386,armv7 |
| fedora  | amd64,arm64       | amd64,arm64       | amd64,arm64           | amd64,arm64 | None              | None      |
| kali    | amd64,arm64,armv7 | None              | None                  | None        | None              | None      |
| manjaro | amd64,arm64       | None              | None                  | None        | None              | None      |
| ubuntu  | amd64,arm64       | amd64,arm64,armv7 | amd64,arm64           | amd64,arm64 | None              | None      |

仓库命名风格 1: **cake233/alpine-mate-386**, **cake233/debian-lxde-armv7**  
风格 2: **cake233/xfce:kali**, **cake233/kde:fedora**

注: **cake233/alpine-mate-386** = **--platform=linux/386 cake233/mate:alpine**

<details>  
  <summary>此内容已折叠，点击 ▶️ 展开。</summary>

~~你如果哪天想不开，想要干傻事，在服务器上安装桌面环境，那可以考虑一下 tmoe 的 GUI 容器。~~

假设您的 host(宿主机)是 debian 系的发行版（例如 ubuntu, mint 或 kali）

先安装 docker

```sh
sudo apt update
sudo apt install docker.io

WHOAMI=$(id -un)
sudo adduser $WHOAMI docker
# then reboot
```

然后用 alpine 试试水

```sh
docker run \
    -it \
    --rm \
    --shm-size=512M \
    -p 36081:36080 \
    cake233/xfce:alpine
```

进入容器后，输入 `tmoe`，并按下回车，接着选择语言环境，再选择 tools，接着退出。  
然后运行 `novnc`, 最后打开浏览器，输入 `http://您的IP地址:36081`

如果需要将 novnc 容器暴露到公网的话，那么不建议对其使用 `-p` 参数（暴露 36081 端口），建议走 nginx 的 443 端口。  
请新建一个网络，将 novnc 容器 与 nginx 容器置于同一网络，并为前者设置 `network-alias`(网络别名), 最后用 nginx 给它加上一层认证（例如`auth_basic_user_file pw_file;`）并配置 reverse proxy。  
注：proxy_pass 那里要写 `http://novnc容器的网络别名:36080;`  
如果 nginx 那里套了 tls 证书，那么访问地址就是 `https://您在nginx中配置的novnc的域名:端口`。（若端口为 443，则无需加 **:端口** ）  
注 2： 若您在 nginx 中配置了 novnc 的域名，则处于相同网络环境下的 nginx 和 novnc 必须同时运行。 若 novnc 没有运行，则 nginx 的配置会加载失败，这可能会导致 nginx 无法正常运行。  
如果您对 nginx + novnc 这块有疑问的话，请前往本项目的 [github disscussion](https://github.com/2moe/tmoe/discussions) 发表话题。

您也可以使用普通的 vnc 客户端来连接，不过这时候 tcp 端口就不是 36081 了。

```sh
docker run \
    -it \
    --shm-size=1G \
    -p 5903:5902 \
    -u 1000:1000 \
    --name uuu-mate \
    cake233/mate:ubuntu
```

对于 debian 系发行版，执行 `su -c "adduser yourusername"` 创建新用户，先输入默认 root 密码： **root**，然后设置新用户的密码。
设置完密码后，执行 `su -c "adduser yourusername sudo"` 将您的用户加入到 sudo 用户组。  
注 1：其他发行版与 debian 系不同。  
注 2：您可以手动安装并换用其他类似于 `sudo` 的工具，例如：`doas` 或 `calife`。  
注 3：不一定要在容器内部开 vnc, 您可以在宿主或另一个容器开 vnc 服务，不过这样做会稍微麻烦一点。

执行完 `startvnc` 命令后，打开 vnc 客户端，并输入 `您的IP:5903`

接下来将介绍一下桌面用户（非服务器用户）如何使用这些 GUI 容器。  
将 docker 容器当作虚拟机来用或许是一种错误的用法。  
实际上，对于 GUI 桌面容器，开发者更推荐您使用 systemd-nspawn，而不是 docker。

以下只是简单介绍，实际需要做更多的修改。
注： 有一些优秀的项目，如 x11docker，它们可以帮你做得更好。

对于 宿主 为 xorg 的环境:  
在 宿主 中授予当前用户 xhost 权限。

```sh
xhost +SI:localuser:$(id -un)
```

```sh
_UID="$(id -u)"
_GID="$(id -g)"

docker run \
    -it \
    --rm \
    -u $_UID:$_GID \
    --shm-size=1G \
    -v $XDG_RUNTIME_DIR/pulse/native:/run/pulse.sock \
    -e PULSE_SERVER=unix:/run/pulse.sock \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    cake233/kde:ubuntu
```

在容器内部创建一个与宿主用户同名的用户。  
最后启动 dbus-daemon， 并运行特定 Xsession，例如 `/etc/X11/xinit/Xsession`

对于 宿主 为 wayland 的环境，您需要对 docker 执行更多的操作。
例如：设置 WAYLAND_DISPLAY 变量，`-e WAYLAND_DISPLAY=$WAYLAND_DISPLAY`  
设置 XDG_RUNTIME_DIR 环境变量  
`-e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR`  
绑定宿主的 wayland socket  
`-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY`  
设置其他与 wayland 相关的环境变量  
`-e QT_QPA_PLATFORM=wayland`

注：您如果想要在隔离环境（容器/沙盒）中运行 GUI 应用，那么使用 `flatpak` 等成熟的方案可能会更好。

</details>

#### noGUI

现阶段，对于与 tmoe 相关的 nogui 容器，从严格意义上来说，它们属于另外的项目。  
因为它们并没有预装 tmoe tools。

您如果不想要 gui, 那么将 xfce/kde/mate 替换为 zsh 就可以了。

```sh
docker volume create zsh
docker run \
    -it \
    --name zsh \
    -v zsh:/shared_dir \
    cake233/zsh:kali
```

Q: 如何运行其他架构的容器呢？

<details>  
  <summary>因为内容太长了，所以就折叠了</summary>

A: 安装 qemu-user-static

```sh
sudo apt install binfmt-support qemu-user-static
```

接下来轮到 tmoe 相关项目中，更新最积极的容器仓库登场了。

> 注：以下容器每周更新两次  
> docker-hub repo: cake233/rust  
> nightly(gnu): amd64, arm64, armv7, riscv64, ppc64le, s390x, mips64le  
> nightly(musl): amd64, arm64

注：对于 rust 交叉编译，开发者更推荐使用 `cross-rs`, 而不是像下面的例子那样。

```sh
_UID="$(id -u)"
_GID="$(id -g)"
mkdir -p tmp

# 若本地存在 hello 项目，则可跳过这一步。
docker run \
    -t \
    --rm \
    -u "$_UID":"$_GID" \
    -v "$PWD"/tmp:/app \
    -w /app \
    cake233/rust-riscv64 \
    cargo new hello

# build
docker run \
    -t \
    --rm \
    -u "$_UID":"$_GID" \
    -v "$PWD"/tmp/hello:/app \
    -w /app \
    cake233/rust-riscv64 \
    cargo b --release

# check file

FILE="tmp/hello/target/release/hello"

file "$FILE"
# output: tmp/hello/target/release/hello: ELF 64-bit LSB pie executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-riscv64-lp64d.so.1 ...

cat >>tmp/hello/Cargo.toml<<-'EOF'
[profile.release]
lto = "fat"
debug = false
strip = true
panic = "abort"
opt-level = "z"
EOF

docker run \
    -t \
    --rm \
    -u "$_UID":"$_GID" \
    -v "$PWD"/tmp/hello:/app \
    -w /app \
    --platform linux/arm64 \
    cake233/rust:musl \
    cargo b --release

file "$FILE"
# output: tmp/hello/target/release/hello: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
```

</details>

### 2.2. 本地安装

如果您的环境无法运行 docker， 那么您可以在本地安装 tmoe。

| 方法  | 工具  | 条件                                                                                                   | 命令                               |
| ----- | ----- | ------------------------------------------------------------------------------------------------------ | ---------------------------------- |
| ~~1~~ | cargo | ~~you are using `rustc` **nightly**~~ </br>(暂时不可用, `tmm`(edition 2022) </br>将于 2023 年之前发布) | ~~`cargo install tmm`~~            |
| 2     | curl  | 您已经安装了 `curl`,</br> 并且可以访问 github                                                          | `. <(curl -L l.tmoe.me/hub/sh)`    |
| 3     | curl  | 您无法访问 github                                                                                      | `. <(curl -L l.tmoe.me/m/sh)`      |
| 4     | curl  | 以上方法都出错了                                                                                       | `curl -Lo l l.tmoe.me/ee/sh; sh l` |

> 1.4989.x 可能是 edition 2021 的 最后一个“大功能”更新的版本了。
> 之后，edition 2021 会进行一些小修复，可能会加一些小功能。

<!--  | 1     | cargo                                                                                                                                 | you have `cargo` installed                  | `cargo install tmoe` | -->

## 3. 有问题?

有问题一定要问哦！不能憋坏了。  
有 bug 也要及时反馈哦！（~~虽然开发者可能会咕很久，但是~~ bug 总归是要修的)  
您可以提 [issue](https://github.com/2moe/tmoe/issues/new/choose)，也可以在 **discussions** 里进行交流和讨论。

如果是与本项目自身无关的话题，那请发在 [discussions](https://github.com/2moe/tmoe/discussions) 里。

> 比如说你使用了 `startvnc`， 但是它出问题了，这属于与本项目自身有关的话题。  
> 您使用了自己配置的 vnc 服务，这属于与本项目自身无关的话题。

您如果看不起 `tmoe`，那可以离开。本项目开发者并没有强迫您使用它。  
如果您要骂本项目开发者，那请尽量使用友好的语气。  
希望大家不要做那种“通过‘恶意’贬低他人来显现自己有多么伟大”的人。  
😭 呜，希望大家不要让开发者太伤心了。

## 4. 许可证

TMOE LICENSE Version 1.2 中第 7 节的内容让本项目开发者感到很难受，之后开发者将修改许可证内相关内容。

## 5. 我可以干什么?

您可以在 arm64 设备上运行 gnome 或其它桌面。

![gnome40_p1](https://images.gitee.com/uploads/images/2021/0806/224412_07b5cd5b_5617340.png "Screenshot_20210806-221622.png")
![gnome40_p2](https://images.gitee.com/uploads/images/2021/0806/224423_fa8285a5_5617340.png "Screenshot_20210806-222714.png")

## 6. 翻页

| 章节                  | 简介                                               | 文件      |
| --------------------- | -------------------------------------------------- | --------- |
| [下一章](./readme.md) | 简单了解不同版本之间的区别，并进一步细化安装的过程 | readme.md |
