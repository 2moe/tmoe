# docker

- [1. GUI](#1-gui)
  - [1.1. Table](#11-table)
  - [1.2. For server](#12-for-server)
    - [1.2.1. install docker](#121-install-docker)
    - [1.2.2. test alpine + novnc](#122-test-alpine--novnc)
    - [1.2.3. vnc client](#123-vnc-client)
  - [1.3. For desktop](#13-for-desktop)
    - [1.3.1. xorg](#131-xorg)
    - [1.3.2. wayland](#132-wayland)
- [2. noGUI](#2-nogui)
  - [2.1. zsh](#21-zsh)
  - [2.2. Cross-Architecture](#22-cross-architecture)
- [3. Continuous integration](#3-continuous-integration)
  - [3.1. Github Actions](#31-github-actions)
    - [3.1.1. dockerfile](#311-dockerfile)
    - [3.1.2. workflow](#312-workflow)
- [4. Creation of container images](#4-creation-of-container-images)
  - [4.1. rust](#41-rust)

---

The following is only a cursory overview, there is much more to Docker that we have not covered in this chapter.

## 1. GUI

Q: Do I have to use a script to install it?  
A: No! No need at all.

Q: Oh god! This stupid thing is writing in my **~/.local/share** directory again. It's so annoying. How do I stop it?  
A: You can use a docker container with tmoe pre-installed. It will create the data files inside the container, not in the host.

### 1.1. Table

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

|        | cutefish          | lxde      |
| ------ | ----------------- | --------- |
| arch   | amd64,arm64,armv7 | None      |
| debian | None              | 386,armv7 |

style 1: **cake233/alpine-mate-386**, **cake233/debian-lxde-armv7**  
style 2: **cake233/xfce:kali**, **cake233/kde:fedora**

Note:
**cake233/alpine-mate-386** = **--platform=linux/386 cake233/mate:alpine**

### 1.2. For server

> For GUI containers, in order to reduce size and packaging time, the novnc and tigervnc services will probably be separated into separate containers, instead of having `vnc` built into each container.  
> At that point, 'docker-compose' may be preferable.

~~If you want to install a desktop on a linux server, then I would advise you not to do anything stupid.~~  
Just kidding. It probably wouldn't do much good to do so, but you might really consider `tmoe` gui container.

Assuming your host is a debian-based distribution (e.g. ubuntu, mint or kali)

#### 1.2.1. install docker

```sh
sudo apt update
sudo apt install docker.io

WHOAMI=$(id -un)
sudo adduser $WHOAMI docker
# then reboot
```

#### 1.2.2. test alpine + novnc

```sh
docker run \
    -it \
    --rm \
    --shm-size=512M \
    -p 36081:36080 \
    cake233/xfce:alpine
```

Run `tmoe` to select locale, then choose tools, and then exit.  
Run `novnc`,then open your browser on your host, and type "http://your_ip_address:36081"

Note: Exposing it to the public network is extremely risky, so consider using the **nginx reverse proxy** and adding an extra layer of authentication to it.  
If you have any doubts about nginx + novnc, then please go to github disscussion.

#### 1.2.3. vnc client

In addition to novnc + browser, you can also use the vnc client.

```sh
docker run \
    -it \
    --shm-size=1G \
    -p 5903:5902 \
    -u 1000:1000 \
    --name uuu-mate \
    cake233/mate:ubuntu
```

Run `su -`, and type the root password: root  
Run `adduser yourusername` to create a new user.  
Run `adduser yourusername sudo` to add **your user** to group sudo.

Run `exit` or `su - yourusername`  
Run `startvnc`, then open the vnc client and type "your_ip_address:5903"

### 1.3. For desktop

In this section, we will describe how desktop users can use these GUI containers.  
It is probably a mistake to use docker containers as virtual machines.  
In fact, for GUI desktop containers, I recommend using systemd-nspawn rather than docker.

The following is only a basic overview, additional changes are required.  
Note: Some fantastic projects, such as x11docker, can assist you in improving your performance.  
Perhaps you can combine the "tmoe" GUI images with those projects and use the GUI containers more comfortably without having to manually set environment variables like "WAYLAND DISPLAY" or worry about the minor details.

#### 1.3.1. xorg

For xorg host environment:  
In the host, allow the current user to access xhost.

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

Create a user with the same name as the host user within the container.
Finally, start dbus-daemon and run `/etc/X11/xinit/Xsession`

#### 1.3.2. wayland

For wayland host environment, you will need to do more with docker.  
Set the WAYLAND_DISPLAY variable：  
`-e WAYLAND_DISPLAY=$WAYLAND_DISPLAY`  
Set the XDG_RUNTIME_DIR variable：  
If UID is 1000, then default is /run/user/1000.  
`-e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR`  
binding the wayland socket of host  
`-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY`  
Set other environment variables related to wayland  
`-e QT_QPA_PLATFORM=wayland`

Note: If you want to run GUI app in a container or sandbox, you should consider using a mature solution like **flatpak**.

## 2. noGUI

### 2.1. zsh

Some of the nogui containers associated with tmoe are still considered separate projects at this time.  
This is due to the fact that they do not come pre-installed with tmoe tools.

If you don't want a desktop, simply replace xfce/kde/mate with zsh and you're done.

```sh,editable
# create container data volumes to store persistent data.
docker volume create sd
# sd: In this case, the sd is not a Secure Digital Memory Card, but rather a Shared Directory; in fact, it makes no difference what it is called.

docker run \
    -it \
    --name zsh \
    -v sd:/sd \
    cake233/zsh:kali
```

### 2.2. Cross-Architecture

Q: How do I run containers of other architectures?

A: install qemu-user-static

```sh
sudo apt install binfmt-support qemu-user-static
```

Take rust cross-compilation as an example.

> Note: The following containers are updated twice a week.  
> docker-hub repo: cake233/rust  
> nightly(gnu): amd64, arm64, armv7, riscv64, ppc64le, s390x, mips64le  
> nightly(musl): amd64, arm64

```sh
_UID="$(id -u)"
_GID="$(id -g)"
mkdir -p tmp

# This step can be skipped if the hello project already exists locally.
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

## 3. Continuous integration

> _En somme, la Beauté est partout. Ce n'est point elle qui manque à nos yeux, mais nos yeux qui manquent à l'apercevoir._  
> _In short, Beauty is everywhere. It is not she that is lacking to our eye, but our eyes which fail to perceive her._
> --- Auguste Rodin

We are not implying that "Tmoe" is beautiful, or it is attractive.

On the contrary, it is considered ugly and vulgar by some.  
But even if it's an ugly thing, it has its own worth.

If you approach things in a hurry, it may be difficult to find some fantastic uses for them.

In this section, we'll use the previously mentioned **rust container image** and combine it with CI to demonstrate its use.  
If one day someone releases some similar images that is more comprehensive and more aggressively updated than the Tmoe-related images, then the Tmoe-related images may be of little use.  
However, we would like you to take a look at it and point out the shortcomings of the following ideas.

### 3.1. Github Actions

What if you want to use github actions to compile `rust` programs for architectures like `riscv64`, `mips64el`, `arm64` and `armv7`?

Some people may look down on `qemu-user` and think it has too many segment faults (segfault).  
From an ease-of-use perspective, it is not necessarily easier to configure the cross-compilation toolchain manually than it is to configure `qemu-user`.

In this subsection, we will compile rust programs of different architectures with `qemu-user`.

> The following is for reference only and actually requires more modifications.

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

# Docker Multi-stage builds:

# For musl or statically compiled binary, you can replace the debian image with alpine:edge
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
    # This workflow will only be triggered when Cargo.toml of the main branch changes and is pushed
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
          # If you're using a "self-hosted server", change os to the appropriate name, such as self-hosted-debian.
          - os: ubuntu-latest
            arch: riscv64
            tag: nightly
            platform: "linux/riscv64"

          # By simply changing os, you can specify a different machine/system for this matrix.
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
          # You can refer to other repositories, the default is the repository where the current project is located
          # repository: "xxx/yyy"
          ref: "main"
          fetch-depth: 1

        # For x64(amd64) architecture devices, qemu is not required if the current architecture is amd64 or i386 architecture, otherwise it is required.
        # When you use it, you only need to configure the current platform; no other platforms need to be configured.
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
        # The compiled image is "${{ env.name }}:${{ env.arch }}", for x64 architectures, it is "hello:amd64" in this workflow; for arm64 architectures, it is "hello:arm64"
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

The above article does not go into detail about the Docker login and push process.

You can manually add the necessary processes.

> **secrets** (secret environment variables) need to be configured in **Actions secrets** in **Settings** of the current repository.

```yaml
- name: Login to DockerHub
  uses: docker/login-action@v2
  with:
    username: Your dockerhub user name
    password: ${{ secrets.DOCKER_TOKEN }}
- name: Push to DockerHub
  run: |
    docker push -a ${{ env.REPO }}
```

## 4. Creation of container images

Before you use a "Tmoe" image, you should be worried about what's in it, right?  
In this section, we will analyze the container dockerfile.  
In fact, you can find the relevant files in "2moe/build-container".

### 4.1. rust

Let's take the rust alpine (musl-libc) container as an example.

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
# **install_alpine_deps** will install the dependencies
# Related dependencies are sudo, tar, grep, curl, wget, bash, tzdata, newt, shadow
# In fact, only curl is a real dependency, bash is optional. For non-interactive environments, the default shell is ash, which is fine.
# The other dependencies are things that the tmoe manager needs to initialize the container.
# For docker, commands like grep and tar (built in with busybox) are sufficient.
RUN . /tmp/install_alpine_deps

# install musl-dev
RUN apk add openssl-dev \
    musl-dev \
    gcc \
    ca-certificates

# minimal, default, complete
ARG RUSTUP_PROFILE=minimal

# The value of MUSL_TARGET varies depending on the platform.
# e.g, linux arm64: "aarch64-unknown-linux-musl"
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

> Several new environment variables or files must be created inside the container to store information about container properties.

This dockerfile may be followed by changes, such as removing TMOE-related environment variables and renaming the directory "/usr/local/etc/tmoe-linux" to "/etc/tmoe".
