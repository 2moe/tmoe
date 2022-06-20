# docker

- [1. GUI 容器](#1-gui-容器)
  - [1.1. 表格](#11-表格)
  - [1.2. 服务器用户](#12-服务器用户)
    - [1.2.1. 安装 docker](#121-安装-docker)
    - [1.2.2. 测试 alpine](#122-测试-alpine)
    - [1.2.3. 关于 nginx 与 novnc 的安全问题](#123-关于-nginx-与-novnc-的安全问题)
    - [1.2.4. 普通 vnc](#124-普通-vnc)
  - [1.3. 桌面用户](#13-桌面用户)
    - [1.3.1. xorg](#131-xorg)
    - [1.3.2. wayland](#132-wayland)
- [2. noGUI](#2-nogui)
  - [2.1. zsh](#21-zsh)
  - [2.2. Cross-Architecture 跨架构](#22-cross-architecture-跨架构)
- [3. Continuous integration 持续集成](#3-continuous-integration-持续集成)
  - [3.1. Github Actions](#31-github-actions)
    - [3.1.1. dockerfile](#311-dockerfile)
    - [3.1.2. workflow](#312-workflow)
- [4. 容器镜像是怎么来的](#4-容器镜像是怎么来的)
  - [4.1. rust](#41-rust)

---

阅读本节内容的要求：

- 了解 docker 的基础知识
- 了解 nginx 中关于反向代理的配置
- 了解 CI/CD 的操作

## 1. GUI 容器

在一般情况下，对于更新频繁的发行版，其对应的 GUI 容器每两周会更新一次。

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

仓库命名风格 1: **cake233/alpine-mate-386**, **cake233/debian-lxde-armv7**  
风格 2: **cake233/xfce:kali**, **cake233/kde:fedora**

注: **cake233/alpine-mate-386** = **--platform=linux/386 cake233/mate:alpine**

### 1.2. 服务器用户

对于 GUI 容器来说，为了减小体积和缩短打包时间，开发者之后可能会将 novnc 和 tigervnc 服务分离为单独的容器，而不是每个容器都内置 `vnc`。  
届时，使用 `docker run` 就不太合适了，换用 `docker-compose` 或许会更好。

> 本小节的内容可能会重写。

~~你如果哪天想不开，想要干傻事，在服务器上安装桌面环境，那可以考虑一下 tmoe 的 GUI 容器。~~

假设您的 host(宿主机)是 debian 系的发行版（例如 ubuntu, mint 或 kali）

#### 1.2.1. 安装 docker

```sh,editable
sudo apt update
sudo apt install docker.io

WHOAMI=$(id -un)
sudo adduser $WHOAMI docker
# then reboot
```

#### 1.2.2. 测试 alpine

```sh,editable
docker run \
    -it \
    --rm \
    --shm-size=512M \
    -p 36081:36080 \
    cake233/xfce:alpine
```

进入容器后，输入 `tmoe`，并按下回车，接着选择语言环境，再选择 tools，接着退出。  
然后运行 `novnc`, 最后打开浏览器，输入 `http://您的IP地址:36081`

#### 1.2.3. 关于 nginx 与 novnc 的安全问题

如果需要将 novnc 容器暴露到公网的话，那么不建议对其使用 `-p` 参数（暴露 36081 端口），建议走 nginx 的 443 端口。  
请新建一个网络，将 novnc 容器 与 nginx 容器置于同一网络，并为前者设置 `network-alias`(网络别名), 最后用 nginx 给它加上一层认证（例如`auth_basic_user_file pw_file;`）并配置 reverse proxy。  
注：proxy_pass 那里要写 `http://novnc容器的网络别名:36080;`  
如果 nginx 那里套了 tls 证书，那么访问地址就是 `https://您在nginx中配置的novnc的域名:端口`。（若端口为 443，则无需加 **:端口** ）  
注 2： 若您在 nginx 中配置了 novnc 的域名，则处于相同网络环境下的 nginx 和 novnc 必须同时运行。 若 novnc 没有运行，则 nginx 的配置会加载失败，这可能会导致 nginx 无法正常运行。  
如果您对 nginx + novnc 这块有疑问的话，请前往本项目的 [github disscussion](https://github.com/2moe/tmoe/discussions) 发表话题。

#### 1.2.4. 普通 vnc

您也可以使用普通的 vnc 客户端来连接，不过这时候 tcp 端口就不是 36081 了。

```sh,editable
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

### 1.3. 桌面用户

接下来将介绍一下桌面用户（非服务器用户）如何使用这些 GUI 容器。  
将 docker 容器当作虚拟机来用或许是一种错误的用法。  
实际上，对于 GUI 桌面容器，开发者更推荐您使用 systemd-nspawn，而不是 docker。

以下只是简单介绍，实际需要做更多的修改。  
注： 有一些优秀的项目，如 x11docker，它们可以帮你做得更好。  
或许，您可以将本项目相关的容器镜像与那些项目结合在一起，无需手动设置 `WAYLAND_DISPLAY` 等环境变量，也无需在意具体的小细节，就能更舒心地去使用 GUI 容器了。

#### 1.3.1. xorg

对于 宿主 为 xorg 的环境:  
在 宿主 中授予当前用户 xhost 权限。

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

在容器内部创建一个与宿主用户同名的用户。  
最后启动 dbus-daemon， 并运行特定 Xsession，例如 `/etc/X11/xinit/Xsession`

#### 1.3.2. wayland

对于 宿主 为 wayland 的环境，您需要对 docker 执行更多的操作。
例如：设置 WAYLAND_DISPLAY 变量，`-e WAYLAND_DISPLAY=$WAYLAND_DISPLAY`  
设置 XDG_RUNTIME_DIR 环境变量  
`-e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR`  
绑定宿主的 wayland socket  
`-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY`  
设置其他与 wayland 相关的环境变量  
`-e QT_QPA_PLATFORM=wayland`

注：您如果想要在隔离环境（容器/沙盒）中运行 GUI 应用，那么使用 `flatpak` 等成熟的方案可能会更简单。

## 2. noGUI

### 2.1. zsh

现阶段，对于与 tmoe 相关的 nogui 容器，从严格意义上来说，它们属于另外的项目。  
因为它们并没有预装 tmoe tools。

您如果不想要 gui, 那么将 xfce/kde/mate 替换为 zsh 就可以了。

```sh,editable
# 创建容器数据卷, 用于存储持久化数据
docker volume create sd
# sd: 此处的 sd 并不是 Secure Digital Memory Card，而是 Shared Dir，其实叫什么名字都无所谓

docker run \
    -it \
    --name zsh \
    -v sd:/sd \
    cake233/zsh:kali
```

### 2.2. Cross-Architecture 跨架构

Q: 如何运行其他架构的容器呢？

A: 安装 qemu-user-static

```sh
sudo apt install binfmt-support qemu-user-static
```

接下来轮到 tmoe 相关项目中，更新最积极的容器仓库登场了。

> 注：以下容器每周更新两次  
> docker-hub repo: cake233/rust  
> nightly(gnu): amd64, arm64, armv7, riscv64, ppc64le, s390x, mips64le  
> nightly(musl): amd64, arm64

```sh,editable
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

## 3. Continuous integration 持续集成

> _En somme, la Beauté est partout. Ce n'est point elle qui manque à nos yeux, mais nos yeux qui manquent à l'apercevoir._  
> _世界上并不缺少美,而是缺少发现美的眼睛_  
> --- 法国著名雕塑家: 罗丹

您如果抱着急功近利的心态去看待某些事物，那可能很难会发现它们的一些妙用。

在本节中，我们将会用到上文中提到的 **rust 镜像**， 并将其与 CI 结合，为您展示相关的用法。

### 3.1. Github Actions

您如果想要使用 github actions 来编译 "riscv64"、"mips64el"、"arm64" 和 "armv7" 等架构的 `rust` 应用，那会怎么做呢？

在本小节中，我们将通过 `qemu-user` 来编译不同架构的 rust 应用。

> 以下内容仅供参考，实际上需要做更多的修改。

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

# 以下将用到 docker 的多阶段构建（Multi-stage builds），实际上这是可选的。

# 对于 musl 或静态编译的 bin， 您可以将 debian 镜像更换为 alpine:edge
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
    # 只有当 main 分支的 Cargo.toml 发生变化并且 push 后，才会触发此 workflow
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
          # 如果您使用的是“自托管服务器”的话，那么 os 需要改成相应的名称， 例如： self-hosted-debian
          - os: ubuntu-latest
            arch: riscv64
            tag: nightly
            platform: "linux/riscv64"

          # 您可以为该矩阵指定不同的机器/系统，只需要修改 os 即可。
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
          # 您可以引用其他仓库，默认为当前项目所在的仓库
          # repository: "xxx/yyy"
          ref: "main"
          fetch-depth: 1

        # 对于 x64(amd64) 架构的设备来说，如果当前架构是 amd64 或 i386 架构，那么无需调用 qemu，否则需要调用。
        # 在调用时，只需要配置当前平台即可，无需配置其他平台。
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
      #编译完成的镜像为 "${{ env.name }}:${{ env.arch }}"，对于 x64 架构，在本 workflow中，它是 "hello:amd64" ；对于 arm64 架构，则是 "hello:arm64"
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

上文并没有介绍到 docker 登录和推送的流程。  
您可以手动添加相应的流程

> **secrets** (私密环境变量) 需要在当前仓库的 **Settings** 的 **Actions secrets** 里配置。

```yaml
- name: Login to DockerHub
  uses: docker/login-action@v2
  with:
    username: 您的 dockerhub 用户名
    password: ${{ secrets.DOCKER_TOKEN }}
- name: Push to DockerHub
  run: |
    docker push -a ${{ env.REPO }}
```

## 4. 容器镜像是怎么来的

在本节中，我们将会为您解析容器的 dockerfile。  
您可以从 "2moe/build-container" 中找到相关的文件。

### 4.1. rust

下面我们以 rust alpine (musl-libc) 容器为例。

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
# install_alpine_deps 会安装相关依赖
# 相关依赖指的是 sudo，tar，grep，curl，wget，bash，tzdata，newt，shadow
# 实际上，只有 curl 是真正的依赖，bash 为可选依赖。 对于非交互式环境来说，默认 shell 为 ash 也没问题。
# 其他依赖是 tmoe manager 在初始化容器过程需要用到的东西。
# 对于 docker 来说，grep 和 tar 等命令使用 `busybox` 内置的精简版本就够了。
RUN . /tmp/install_alpine_deps

# install musl-dev
RUN apk add openssl-dev \
    musl-dev \
    gcc \
    ca-certificates

# minimal, default, complete
ARG RUSTUP_PROFILE=minimal

# 对于不同的平台来说， MUSL_TARGET 是不一样的。
# 比如说：linux arm64: "aarch64-unknown-linux-musl"
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

> 为了保留容器属性信息，容器内部需要新建几个环境变量或文件。

这个 dockerfile 之后可能会发生变更，比如说：砍掉 TMOE 相关的环境变量，将 "/usr/local/etc/tmoe-linux" 目录更改为 "/etc/tmoe"
