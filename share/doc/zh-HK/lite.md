# T Moe

化繁為簡，讓 gnu/linux 的樂趣觸手可及。

## 1. 目錄

### 1.1. 主要

| 章節                    | 簡介                           | 文件      |
| ----------------------- | ------------------------------ | --------- |
| 序章前篇                | 用簡短的説明帶您領略其中的魅力 | lite.md   |
| [序章後篇](./readme.md) | 歷史與發展                     | readme.md |
| [第一章](./1.md)        | 容器的安裝與配置               | 1.md      |
| [第二章](./2.md)        | 錯誤處理                       | 2.md      |
| [第三章](./3.md)        | 介紹 vscode & haskell 等容器   | 3.md      |

### 1.2. 本章

中文 | [English](../../../Readme.md)

- [1. 目錄](#1-目錄)
  - [1.1. 主要](#11-主要)
  - [1.2. 本章](#12-本章)
- [2. 快速上手](#2-快速上手)
  - [2.1. 容器鏡像](#21-容器鏡像)
    - [GUI 容器](#gui-容器)
    - [nogui](#nogui)
  - [2.2. 本地安裝](#22-本地安裝)
  - [2.3. 有問題?](#23-有問題)
  - [2.4. 我可以幹什麼?](#24-我可以幹什麼)
- [3. 翻頁](#3-翻頁)

## 2. 快速上手

### 2.1. 容器鏡像

#### GUI 容器

Q: 我必須要跑個腳本才能安裝 tmoe 嗎？

A: 不！ 完全不需要。  
您如果想在非移動平台上使用本項目，那麼可以使用預裝本項目的 docker 容器鏡像。  
除特殊情況外，以下容器每週都會更新。

|         | xfce              | kde               | mate                  | lxqt        | cutefish          | lxde      |
| ------- | ----------------- | ----------------- | --------------------- | ----------- | ----------------- | --------- |
| alpine  | amd64,arm64       | amd64,arm64       | 386,amd64,arm64,armv7 | None        | None              | None      |
| arch    | amd64,arm64,armv7 | amd64,arm64       | amd64,arm64           | None        | amd64,arm64,armv7 | None      |
| debian  | amd64,arm64       | amd64,arm64       | amd64,arm64           | None        | None              | 386,armv7 |
| fedora  | amd64,arm64       | amd64,arm64       | amd64,arm64           | amd64,arm64 | None              | None      |
| kali    | amd64,arm64,armv7 | None              | None                  | None        | None              | None      |
| manjaro | amd64,arm64       | None              | None                  | None        | None              | None      |
| ubuntu  | amd64,arm64       | amd64,arm64,armv7 | amd64,arm64           | amd64,arm64 | None              | None      |

倉庫命名風格 1: **cake233/alpine-mate-386**, **cake233/debian-lxde-armv7**  
風格 2: **cake233/xfce:kali**, **cake233/kde:fedora**

注: **cake233/alpine-mate-386** = **--platform=linux/386 cake233/mate:alpine**

<details>  
  <summary>此內容已摺疊，點擊 ▶️ 展開。</summary>

~~你如果哪天想不開，想要幹傻事，在服務器上安裝桌面環境，那可以考慮一下 tmoe 的 GUI 容器。~~

假設您的 host(宿主機)是 debian 系的發行版（例如 ubuntu, mint 或 kali）

先安裝 docker

```sh
sudo apt update
sudo apt install docker.io
```

然後用 alpine 試試水

```sh
docker run \
    -it \
    --rm \
    --shm-size=512M \
    -p 36081:36080 \
    cake233/xfce:alpine
```

進入容器後，執行 `tmoe` 選擇語言環境，再選擇 tools，接着退出。  
然後運行 `novnc`, 最後回到宿主環境，打開瀏覽器，輸入 `http://您的IP地址:36081`

您也可以使用 vnc 客户端，不過這時候 tcp 端口就不是 5903:5902 了。

```sh
docker run \
    -it \
    --shm-size=1G \
    -p 5903:5902 \
    -u 1000:1000 \
    --name uuu-mate \
    cake233/mate:ubuntu
```

對於 debian 系發行版，執行 `su -c "adduser yourusername"` 創建新用户，先輸入默認 root 密碼： **root**，然後設置新用户的密碼。
設置完密碼後，執行 `su -c "adduser yourusername sudo"` 將當前用户加入到 sudo 用户組。  
注 1：其他發行版與 debian 系不同。  
注 2：您可以手動安裝並換用其他類似於 `sudo` 的工具，例如：`doas` 或 `calife`。  
注 3：不一定要在容器內部開 vnc, 您可以在宿主或另一個容器開 vnc 服務，不過這樣做會稍微麻煩一點。

執行完 `startvnc` 命令後，打開 vnc 客户端，並輸入 `您的IP:5903`

接下來將介紹一下桌面用户（非服務器用户）如何使用這些 GUI 容器。  
將 docker 容器當作虛擬機來用或許是一種錯誤的用法。  
實際上，對於 GUI 桌面容器，開發者更推薦您使用 systemd-nspawn，而不是 docker。

以下只是簡單介紹，實際需要做更多的修改。
注： 有一些優秀的項目，如 x11docker，它們可以幫你做得更好。

對於 宿主 為 xorg 的環境:  
在 宿主 中授予當前用户 xhost 權限。

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
    -e PULSE_SERVER=unix:/run/pulse.sock
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    cake233/kde:ubuntu
```

在容器內部創建一個與宿主用户同名的用户。  
最後執行特定 session 命令，例如 `/etc/X11/xinit/Xsession`

對於 宿主 為 wayland 的環境，您需要對 docker 執行更多的操作。
例如：設置 WAYLAND_DISPLAY 變量，`-e WAYLAND_DISPLAY=$WAYLAND_DISPLAY`  
設置 XDG_RUNTIME_DIR 環境變量  
`-e XDG_RUNTIME_DIR=/run/user/1000`  
綁定宿主的 wayland socket  
`-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/run/user/1000/$WAYLAND_DISPLAY`  
設置其他與 wayland 相關的環境變量  
`-e QT_QPA_PLATFORM=wayland`

注：您如果想要在隔離環境（容器/沙盒）中運行 GUI 應用，那麼使用 `flatpak` 等成熟的方案可能會更好。

</details>

#### nogui

現階段，對於與 tmoe 相關的 nogui 容器，從嚴格意義上來説，它們屬於另外的項目。  
因為它們並沒有預裝 tmoe tools。

您如果不想要 gui, 那麼將 xfce/kde/mate 替換為 zsh 就可以了。

```sh
docker volume create zsh
docker run \
    -it \
    --name zsh \
    -v zsh:/shared_dir \
    cake233/zsh:kali
```

Q: 如何運行其他架構的容器呢？

<details>  
  <summary>因為內容太長了，所以就摺疊了</summary>

A: 安裝 qemu-user-static

```sh
sudo apt install binfmt-support qemu-user-static
```

接下來輪到 tmoe 相關項目中，更新最積極的容器倉庫登場了。

> 注：以下容器每週更新兩次  
> docker-hub repo: cake233/rust  
> nightly(gnu): amd64, arm64, armv7, riscv64, ppc64le, s390x, mips64le  
> nightly(musl): amd64, arm64

注：對於 rust 交叉編譯，開發者更推薦使用 `cross-rs`, 而不是像下面的例子那樣。

```sh
_UID="$(id -u)"
_GID="$(id -g)"
mkdir -p tmp

# 若本地存在 hello 項目，則可跳過這一步。
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

### 2.2. 本地安裝

如果您的環境無法運行 docker， 那麼也可以在本地安裝 tmoe。

| 方法  | 工具  | 條件                                                                                                   | 命令                                           |
| ----- | ----- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------- |
| ~~1~~ | cargo | ~~you are using `rustc` **nightly**~~ </br>(暫時不可用, `tmm`(edition 2022) </br>將於 2023 年之前發佈) | ~~`cargo install tmm`~~                        |
| 2     | curl  | 您已經安裝了 `curl`,</br> 並且可以訪問 github                                                          | `. <(curl -L git.io/linux.sh)`                 |
| 3     | curl  | 您無法訪問 github                                                                                      | `. <(curl -L l.tmoe.me)`                       |
| 4     | curl  | 以上方法都出錯了                                                                                       | `curl -Lo l gitee.com/mo2/linux/raw/2/2; sh l` |

> 1.4989.x 可能是 edition 2021 的 最後一個“大功能”更新的版本了。
> 之後，edition 2021 會進行一些小修復，可能會加一些小功能。

<!--  | 1     | cargo                                                                                                                                 | you have `cargo` installed                  | `cargo install tmoe` | -->

### 2.3. 有問題?

有問題一定要問哦！不能憋壞了。
您可以提 [issue](https://github.com/2moe/tmoe-linux/issues/new/choose)，也可以在 **discussions** 裏進行交流和討論。

您如果無法訪問 GitHub 的話，那就前往 [gitee](https://gitee.com/mo2/linux/issues) 反饋吧！

### 2.4. 我可以幹什麼?

您可以在 arm64 設備上運行 gnome 或其它桌面。

![gnome40_p1](https://images.gitee.com/uploads/images/2021/0806/224412_07b5cd5b_5617340.png "Screenshot_20210806-221622.png")
![gnome40_p2](https://images.gitee.com/uploads/images/2021/0806/224423_fa8285a5_5617340.png "Screenshot_20210806-222714.png")

## 3. 翻頁

| 章節                  | 簡介                                               | 文件      |
| --------------------- | -------------------------------------------------- | --------- |
| [下一章](./readme.md) | 簡單瞭解不同版本之間的區別，並進一步細化安裝的過程 | readme.md |
