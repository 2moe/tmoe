# docker

- [1. GUI 容器](#1-gui-容器)
  - [1.1. 表格](#11-表格)
  - [1.2. 伺服器使用者](#12-伺服器使用者)
    - [1.2.1. 安裝 docker](#121-安裝-docker)
    - [1.2.2. 測試 alpine](#122-測試-alpine)
    - [1.2.3. 關於 nginx 與 novnc 的安全問題](#123-關於-nginx-與-novnc-的安全問題)
    - [1.2.4. 普通 vnc](#124-普通-vnc)
  - [1.3. 桌面使用者](#13-桌面使用者)
    - [1.3.1. xorg](#131-xorg)
    - [1.3.2. wayland](#132-wayland)
- [2. noGUI](#2-nogui)
  - [2.1. zsh](#21-zsh)
  - [2.2. Cross-Architecture 跨架構](#22-cross-architecture-跨架構)
- [3. Continuous integration 持續整合](#3-continuous-integration-持續整合)
  - [3.1. Github Actions](#31-github-actions)
    - [3.1.1. dockerfile](#311-dockerfile)
    - [3.1.2. workflow](#312-workflow)
- [4. 容器映象是怎麼來的](#4-容器映象是怎麼來的)
  - [4.1. rust](#41-rust)

---

閱讀本節內容的要求：

- 瞭解 docker 的基礎知識
- 瞭解 nginx 中關於反向代理的配置
- 瞭解 CI/CD 的操作

## 1. GUI 容器

在一般情況下，對於更新頻繁的發行版，其對應的 GUI 容器每兩週會更新一次。

### 1.1. 表格

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

|        | mate                  | lxqt        |
| ------ | --------------------- | ----------- |
| alpine | 386,amd64,arm64,armv7 | None        |
| arch   | amd64,arm64           | None        |
| debian | amd64,arm64           | None        |
| fedora | amd64,arm64           | amd64,arm64 |
| ubuntu | amd64,arm64           | amd64,arm64 |

---

|        | lxde      |
| ------ | --------- |
| debian | 386,armv7 |

倉庫命名風格 1: **cake233/alpine-mate-386**, **cake233/debian-lxde-armv7**  
風格 2: **cake233/xfce:kali**, **cake233/kde:fedora**

注: **cake233/alpine-mate-386** = **--platform=linux/386 cake233/mate:alpine**

### 1.2. 伺服器使用者

對於 GUI 容器來說，為了減小體積和縮短打包時間，開發者之後可能會將 novnc 和 tigervnc 服務分離為單獨的容器，而不是每個容器都內建 `vnc`。  
屆時，使用 `docker run` 就不太合適了，換用 `docker-compose` 或許會更好。

> 本小節的內容可能會重寫。

~~你如果哪天想不開，想要幹傻事，在伺服器上安裝桌面環境，那可以考慮一下 tmoe 的 GUI 容器。~~

假設您的 host(宿主機)是 debian 系的發行版（例如 ubuntu, mint 或 kali）

#### 1.2.1. 安裝 docker

```sh,editable
sudo apt update
sudo apt install docker.io

WHOAMI=$(id -un)
sudo adduser $WHOAMI docker
# then reboot
```

#### 1.2.2. 測試 alpine

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

#### 1.2.3. 關於 nginx 與 novnc 的安全問題

如果需要將 novnc 容器暴露到公網的話，那麼不建議對其使用 `-p` 引數（暴露 36081 埠），建議走 nginx 的 443 埠。  
請新建一個網路，將 novnc 容器 與 nginx 容器置於同一網路，併為前者設定 `network-alias`(網路別名), 最後用 nginx 給它加上一層認證（例如`auth_basic_user_file pw_file;`）並配置 reverse proxy。  
注：proxy_pass 那裡要寫 `http://novnc容器的網路別名:36080;`  
如果 nginx 那裡套了 tls 證書，那麼訪問地址就是 `https://您在nginx中配置的novnc的域名:埠`。（若埠為 443，則無需加 **:埠** ）  
注 2： 若您在 nginx 中配置了 novnc 的域名，則處於相同網路環境下的 nginx 和 novnc 必須同時執行。 若 novnc 沒有執行，則 nginx 的配置會載入失敗，這可能會導致 nginx 無法正常執行。  
如果您對 nginx + novnc 這塊有疑問的話，請前往本專案的 [github disscussion](https://github.com/2moe/tmoe/discussions) 發表話題。

#### 1.2.4. 普通 vnc

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

### 1.3. 桌面使用者

接下來將介紹一下桌面使用者（非伺服器使用者）如何使用這些 GUI 容器。  
將 docker 容器當作虛擬機器來用或許是一種錯誤的用法。  
實際上，對於 GUI 桌面容器，開發者更推薦您使用 systemd-nspawn，而不是 docker。

以下只是簡單介紹，實際需要做更多的修改。  
注： 有一些優秀的專案，如 x11docker，它們可以幫你做得更好。  
或許，您可以將本專案相關的容器映象與那些專案結合在一起，無需手動設定 `WAYLAND_DISPLAY` 等環境變數，也無需在意具體的小細節，就能更舒心地去使用 GUI 容器了。

#### 1.3.1. xorg

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

#### 1.3.2. wayland

對於 宿主 為 wayland 的環境，您需要對 docker 執行更多的操作。
例如：設定 WAYLAND_DISPLAY 變數，`-e WAYLAND_DISPLAY=$WAYLAND_DISPLAY`  
設定 XDG_RUNTIME_DIR 環境變數  
`-e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR`  
繫結宿主的 wayland socket  
`-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY`  
設定其他與 wayland 相關的環境變數  
`-e QT_QPA_PLATFORM=wayland`

注：您如果想要在隔離環境（容器/沙盒）中執行 GUI 應用，那麼使用 `flatpak` 等成熟的方案可能會更簡單。

## 2. noGUI

### 2.1. zsh

現階段，對於與 tmoe 相關的 nogui 容器，從嚴格意義上來說，它們屬於另外的專案。  
因為它們並沒有預裝 tmoe tools。

您如果不想要 gui, 那麼將 xfce/kde/mate 替換為 zsh 就可以了。

```sh,editable
# 建立容器資料卷, 用於儲存持久化資料
docker volume create sd
# sd: 此處的 sd 並不是 Secure Digital Memory Card，而是 Shared Dir，其實叫什麼名字都無所謂

docker run \
    -it \
    --name zsh \
    -v sd:/sd \
    cake233/zsh:kali
```

### 2.2. Cross-Architecture 跨架構

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
# output: ELF 64-bit LSB pie executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-riscv64-lp64d.so.1 ...

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
# output: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
```

## 3. Continuous integration 持續整合

> _En somme, la Beauté est partout. Ce n'est point elle qui manque à nos yeux, mais nos yeux qui manquent à l'apercevoir._  
> _世界上並不缺少美,而是缺少發現美的眼睛_  
> --- 法國著名雕塑家: 羅丹

您如果抱著急功近利的心態去看待某些事物，那可能很難會發現它們的一些妙用。

在本節中，我們將會用到上文中提到的 **rust 映象**， 並將其與 CI 結合，為您展示相關的用法。

### 3.1. Github Actions

您如果想要使用 github actions 來編譯 "riscv64"、"mips64el"、"arm64" 和 "armv7" 等架構的 `rust` 應用，那會怎麼做呢？

在本小節中，我們將透過 `qemu-user` 來編譯不同架構的 rust 應用。

> 以下內容僅供參考，實際上需要做更多的修改。

```sh
mkdir -pv hello
cd hello
cargo init
```

#### 3.1.1. dockerfile

```sh
mkdir -p build
```

file: build/hello.dockerfile

```dockerfile,editable
# syntax=docker/dockerfile:1
#---------------------------
ARG HUB_USER
ARG TAG
FROM --platform=${TARGETPLATFORM} ${HUB_USER}/rust:${TAG} AS Builder

WORKDIR /app
COPY . .

RUN test -e Cargo.toml

RUN --mount=type=tmpfs,target=/usr/local/cargo/registry cargo b --release

# CMD [ "sh" ]

# 以下將用到 docker 的多階段構建（Multi-stage builds），實際上這是可選的。

# 對於 musl 或靜態編譯的 bin， 您可以將 debian 映象更換為 alpine:edge
FROM --platform=${TARGETPLATFORM} debian:sid-slim

COPY --from=Builder /app/target/release /app

WORKDIR /app
```

#### 3.1.2. workflow

```sh
mkdir -p .github/workflows
```

file: **.github/workflows/rs.yml**

```yaml
name: build rust app

on:
  push:
    branches: [main]
    # 只有當 main 分支的 Cargo.toml 發生變化並且 push 後，才會觸發此 workflow
    paths:
      - "Cargo.toml"

jobs:
  job1:
    runs-on: ${{ matrix.os }}
    env:
      name: hello
      user: cake233
      platform: ${{ matrix.platform }}
      arch: ${{ matrix.arch }}
      tag: ${{ matrix.tag }}

    strategy:
      fail-fast: true
      matrix:
        include:
          # 如果您使用的是“自託管伺服器”的話，那麼 os 需要改成相應的名稱， 例如： self-hosted-debian
          - os: ubuntu-latest
            arch: riscv64
            tag: nightly
            platform: "linux/riscv64"

          # 您可以為該矩陣指定不同的機器/系統，只需要修改 os 即可。
          - os: ubuntu-latest
            arch: mips64el
            tag: nightly
            platform: "linux/mips64le"

          - os: ubuntu-latest
            arch: amd64
            tag: musl
            platform: "linux/amd64"

          - os: ubuntu-latest
            arch: arm64
            tag: musl
            platform: "linux/arm64"

          - os: ubuntu-latest
            arch: armhf
            tag: nightly
            platform: "linux/arm/v7"

    steps:
      - uses: actions/checkout@v2
        with:
          # 您可以引用其他倉庫，預設為當前專案所在的倉庫
          # repository: "xxx/yyy"
          ref: "main"
          fetch-depth: 1

        # 對於 x64(amd64) 架構的裝置來說，如果當前架構是 amd64 或 i386 架構，那麼無需呼叫 qemu，否則需要呼叫。
        # 在呼叫時，只需要配置當前平臺即可，無需配置其他平臺。
      - name: set up qemu-user & binfmt
        id: qemu
        uses: docker/setup-qemu-action@v1
        if: matrix.arch != 'amd64' && matrix.arch != 'i386'
        with:
          image: tonistiigi/binfmt:latest
          platforms: ${{ matrix.platform }}

      - name: set global env
        run: |
          echo "REPO=${{ env.name }}:${{ matrix.arch }}" >> "$GITHUB_ENV"

      - name: build container
        env:
          file: "build/${{ env.name }}.dockerfile"
        run: |
          DOCKER_BUILDKIT=1 \
          docker build \
            --tag "${{ env.REPO }}" \
            --file "${{ env.file }}" \
            --build-arg HUB_USER=${{ env.user }} \
            --build-arg TAG=${{ env.tag }} \
            --build-arg BIN_NAME=${{ env.name }} \
            --platform=${{ env.platform }} \
            --pull \
            --no-cache \
            .
      #編譯完成的映象為 "${{ env.name }}:${{ env.arch }}"，對於 x64 架構，在本 workflow中，它是 "hello:amd64" ；對於 arm64 架構，則是 "hello:arm64"
      - name: test container
        run: |
          docker run \
            -t \
            --rm \
            "${{ env.REPO }}" \
            ls -lah --color=auto /app
```

<!--
        repo=hello;file=build/hello.dockerfile;repo=hello:amd64
        user=cake233;tag=musl;new_image=alpine:edge;name=hello;platform=linux/amd64
        DOCKER_BUILDKIT=1 \
          docker build \
            -t "$repo" \
            -f "$file" \
            --build-arg HUB_USER=$user \
            --build-arg TAG=$tag \
            --build-arg BIN_NAME=$name \
            --platform=$platform \
            --pull \
            .
-->

上文並沒有介紹到 docker 登入和推送的流程。  
您可以手動新增相應的流程

> **secrets** (私密環境變數) 需要在當前倉庫的 **Settings** 的 **Actions secrets** 裡配置。

```yaml
- name: Login to DockerHub
  uses: docker/login-action@v2
  with:
    username: 您的 dockerhub 使用者名稱
    password: ${{ secrets.DOCKER_TOKEN }}
- name: Push to DockerHub
  run: |
    docker push -a ${{ env.REPO }}
```

## 4. 容器映象是怎麼來的

在本節中，我們將會為您解析容器的 dockerfile。  
您可以從 "2moe/build-container" 中找到相關的檔案。

### 4.1. rust

下面我們以 rust alpine (musl-libc) 容器為例。

```dockerfile,editable
# syntax=docker/dockerfile:1
#---------------------------
FROM --platform=${TARGETPLATFORM} alpine:edge

WORKDIR /root
# PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG="C.UTF-8" \
    TMOE_CHROOT=true \
    TMOE_DOCKER=true \
    TMOE_DIR="/usr/local/etc/tmoe-linux" \
    RUSTUP_HOME="/usr/local/rustup" \
    CARGO_HOME="/usr/local/cargo" \
    PATH="/usr/local/cargo/bin:$PATH"

# install dependencies
COPY --chmod=755 install_alpine_deps /tmp
# install_alpine_deps 會安裝相關依賴
# 相關依賴指的是 sudo，tar，grep，curl，wget，bash，tzdata，newt，shadow
# 實際上，只有 curl 是真正的依賴，bash 為可選依賴。 對於非互動式環境來說，預設 shell 為 ash 也沒問題。
# 其他依賴是 tmoe manager 在初始化容器過程需要用到的東西。
# 對於 docker 來說，grep 和 tar 等命令使用 `busybox` 內建的精簡版本就夠了。
RUN . /tmp/install_alpine_deps

# install musl-dev
RUN apk add openssl-dev \
    musl-dev \
    gcc \
    ca-certificates

# minimal, default, complete
ARG RUSTUP_PROFILE=minimal

# 對於不同的平臺來說， MUSL_TARGET 是不一樣的。
# 比如說：linux arm64: "aarch64-unknown-linux-musl"
# linux amd64: "x86_64-unknown-linux-musl"
ARG MUSL_TARGET
RUN export RUSTUP_URL="https://static.rust-lang.org/rustup/dist/${MUSL_TARGET}/rustup-init"; \
    curl -LO ${RUSTUP_URL} || exit 1; \
    chmod +x rustup-init \
    && ./rustup-init \
    -y \
    --profile ${RUSTUP_PROFILE} \
    --no-modify-path \
    --default-toolchain \
    nightly \
    && rm rustup-init \
    && chmod -Rv a+w ${RUSTUP_HOME} ${CARGO_HOME}
# RUN rustup update

ARG OS
ARG TAG
ARG ARCH
COPY --chmod=755 set_container_txt /tmp
RUN . /tmp/set_container_txt

# export env to file
RUN cd ${TMOE_DIR}; \
    printf "%s\n" \
    'export PATH="/usr/local/cargo/bin${PATH:+:${PATH}}"' \
    'export RUSTUP_HOME="/usr/local/rustup"' \
    'export CARGO_HOME="/usr/local/cargo"' \
    > environment/container.env; \
    chmod -R a+rx environment/

# export version info to file
RUN cd /root; \
    printf "%s\n" \
    "" \
    '[version]' \
    "ldd = '$(ldd --version 2>&1 | head -n 2 | grep -vi copyright | sed ":a;N;s/\n/ /g;ta")'" \
    "rustup = '$(rustup --version)'" \
    "cargo = '$(cargo --version)'" \
    "rustc = '$(rustc --version)'" \
    "cc = '$(cc --version | head -n 1)'" \
    "cargo_verbose = '''" \
    "$(cargo -Vv)" \
    "'''" \
    "rustc_verbose = '''" \
    "$(rustc -Vv)" \
    "'''" \
    > version.toml; \
    cat version.toml

# clean: apk -v cache clean
RUN rm -rf /var/cache/apk/* \
    ~/.cache/* \
    2>/dev/null

CMD ["bash"]
```

> 為了保留容器屬性資訊，容器內部需要新建幾個環境變數或檔案。

這個 dockerfile 之後可能會發生變更，比如說：砍掉 TMOE 相關的環境變數，將 "/usr/local/etc/tmoe-linux" 目錄更改為 "/etc/tmoe"