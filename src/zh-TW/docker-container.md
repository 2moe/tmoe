# docker

以下內容只是簡單的介紹，實際上對於 docker ，還有更多的門道，我們沒有在本章中提到。

## GUI 容器

Q: 我必須要跑個指令碼才能安裝 tmoe tools 嗎？

A: 不！ 完全不需要。  
二萌之後會將"tmoe tools" 的部分功能打成 deb 包。  
現階段，您如果不想汙染宿主環境，那麼可以使用預裝本專案的 docker 容器映象。  
只是把它做出來可能並不難，最難能可貴的地方在於：以下容器映象會經常更新。

|         | xfce              | kde               |
| ------- | ----------------- | ----------------- |
| alpine  | amd64,arm64       | amd64,arm64       |
| arch    | amd64,arm64,armv7 | amd64,arm64       |
| debian  | amd64,arm64       | amd64,arm64       |
| fedora  | amd64,arm64       | amd64,arm64       |
| kali    | amd64,arm64,armv7 | None              |
| manjaro | amd64,arm64       | None              |
| ubuntu  | amd64,arm64       | amd64,arm64,armv7 |

---

|         | mate                  | lxqt        |
| ------- | --------------------- | ----------- |
| alpine  | 386,amd64,arm64,armv7 | None        |
| arch    | amd64,arm64           | None        |
| debian  | amd64,arm64           | None        |
| fedora  | amd64,arm64           | amd64,arm64 |
| kali    | None                  | None        |
| manjaro | None                  | None        |
| ubuntu  | amd64,arm64           | amd64,arm64 |

---

|         | cutefish          | lxde      |
| ------- | ----------------- | --------- |
| alpine  | None              | None      |
| arch    | amd64,arm64,armv7 | None      |
| debian  | None              | 386,armv7 |
| fedora  | None              | None      |
| kali    | None              | None      |
| manjaro | None              | None      |
| ubuntu  | None              | None      |

倉庫命名風格 1: **cake233/alpine-mate-386**, **cake233/debian-lxde-armv7**  
風格 2: **cake233/xfce:kali**, **cake233/kde:fedora**

注: **cake233/alpine-mate-386** = **--platform=linux/386 cake233/mate:alpine**

~~你如果哪天想不開，想要幹傻事，在伺服器上安裝桌面環境，那可以考慮一下 tmoe 的 GUI 容器。~~

假設您的 host(宿主機)是 debian 系的發行版（例如 ubuntu, mint 或 kali）

先安裝 docker

```sh,editable
sudo apt update
sudo apt install docker.io

WHOAMI=$(id -un)
sudo adduser $WHOAMI docker
# then reboot
```

然後用 alpine 試試水

```sh,editable
docker run \
    -it \
    --rm \
    --shm-size=512M \
    -p 36081:36080 \
    cake233/xfce:alpine
```

進入容器後，輸入 `tmoe`，並按下回車，接著選擇語言環境，再選擇 tools，接著退出。  
然後執行 `novnc`, 最後開啟瀏覽器，輸入 `http://您的IP地址:36081`

如果需要將 novnc 容器暴露到公網的話，那麼不建議對其使用 `-p` 引數（暴露 36081 埠），建議走 nginx 的 443 埠。  
請新建一個網路，將 novnc 容器 與 nginx 容器置於同一網路，併為前者設定 `network-alias`(網路別名), 最後用 nginx 給它加上一層認證（例如`auth_basic_user_file pw_file;`）並配置 reverse proxy。  
注：proxy_pass 那裡要寫 `http://novnc容器的網路別名:36080;`  
如果 nginx 那裡套了 tls 證書，那麼訪問地址就是 `https://您在nginx中配置的novnc的域名:埠`。（若埠為 443，則無需加 **:埠** ）  
注 2： 若您在 nginx 中配置了 novnc 的域名，則處於相同網路環境下的 nginx 和 novnc 必須同時執行。 若 novnc 沒有執行，則 nginx 的配置會載入失敗，這可能會導致 nginx 無法正常執行。  
如果您對 nginx + novnc 這塊有疑問的話，請前往本專案的 [github disscussion](https://github.com/2moe/tmoe-linux/discussions) 發表話題。

您也可以使用普通的 vnc 客戶端來連線，不過這時候 tcp 埠就不是 36081 了。

```sh,editable
docker run \
    -it \
    --shm-size=1G \
    -p 5903:5902 \
    -u 1000:1000 \
    --name uuu-mate \
    cake233/mate:ubuntu
```

對於 debian 系發行版，執行 `su -c "adduser yourusername"` 建立新使用者，先輸入預設 root 密碼： **root**，然後設定新使用者的密碼。
設定完密碼後，執行 `su -c "adduser yourusername sudo"` 將您的使用者加入到 sudo 使用者組。  
注 1：其他發行版與 debian 系不同。  
注 2：您可以手動安裝並換用其他類似於 `sudo` 的工具，例如：`doas` 或 `calife`。  
注 3：不一定要在容器內部開 vnc, 您可以在宿主或另一個容器開 vnc 服務，不過這樣做會稍微麻煩一點。

執行完 `startvnc` 命令後，開啟 vnc 客戶端，並輸入 `您的IP:5903`

接下來將介紹一下桌面使用者（非伺服器使用者）如何使用這些 GUI 容器。  
將 docker 容器當作虛擬機器來用或許是一種錯誤的用法。  
實際上，對於 GUI 桌面容器，開發者更推薦您使用 systemd-nspawn，而不是 docker。

以下只是簡單介紹，實際需要做更多的修改。
注： 有一些優秀的專案，如 x11docker，它們可以幫你做得更好。

對於 宿主 為 xorg 的環境:  
在 宿主 中授予當前使用者 xhost 許可權。

```sh
xhost +SI:localuser:$(id -un)
```

```sh,editable
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

在容器內部建立一個與宿主使用者同名的使用者。  
最後啟動 dbus-daemon， 並執行特定 Xsession，例如 `/etc/X11/xinit/Xsession`

對於 宿主 為 wayland 的環境，您需要對 docker 執行更多的操作。
例如：設定 WAYLAND_DISPLAY 變數，`-e WAYLAND_DISPLAY=$WAYLAND_DISPLAY`  
設定 XDG_RUNTIME_DIR 環境變數  
`-e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR`  
繫結宿主的 wayland socket  
`-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY`  
設定其他與 wayland 相關的環境變數  
`-e QT_QPA_PLATFORM=wayland`

注：您如果想要在隔離環境（容器/沙盒）中執行 GUI 應用，那麼使用 `flatpak` 等成熟的方案可能會更好。

## noGUI

現階段，對於與 tmoe 相關的 nogui 容器，從嚴格意義上來說，它們屬於另外的專案。  
因為它們並沒有預裝 tmoe tools。

您如果不想要 gui, 那麼將 xfce/kde/mate 替換為 zsh 就可以了。

```sh,editable
docker volume create zsh
docker run \
    -it \
    --name zsh \
    -v zsh:/shared_dir \
    cake233/zsh:kali
```

Q: 如何執行其他架構的容器呢？

A: 安裝 qemu-user-static

```sh
sudo apt install binfmt-support qemu-user-static
```

接下來輪到 tmoe 相關專案中，更新最積極的容器倉庫登場了。

> 注：以下容器每週更新兩次  
> docker-hub repo: cake233/rust  
> nightly(gnu): amd64, arm64, armv7, riscv64, ppc64le, s390x, mips64le  
> nightly(musl): amd64, arm64

注：對於 rust 交叉編譯，開發者更推薦使用 `cross-rs`, 而不是像下面的例子那樣。

```sh,editable
_UID="$(id -u)"
_GID="$(id -g)"
mkdir -p tmp

# 若本地存在 hello 專案，則可跳過這一步。
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
