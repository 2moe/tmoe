# T Moe

Simplify and make the fun of gnu/linux at your fingertips.

## 1. Doc

### 1.1. lite

English | [简体中文](./share/doc/zh/lite.md)

This is a _lite doc_.

It's recommended that you read the [full documentation](./share/doc/readme.md).

> v1.4989.x may be the last version of edition 2021.

### 1.2. full

Note: These documents are temporarily unavailable.

The new version with improved multilingual support will be released before 2023.

| language                                     | note                                                                                                           | contributors   |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | -------------- |
| [English](./share/doc/en/readme.md)          | Making the future better together.                                                                             | \*             |
| [中文](./share/doc/zh/readme.md)             | 好耶！是完整的文档 <(=o ゜ ▽ ゜)o☆ <!-- 你好，謝謝，小籠包，再見 -->                                           | 2moe           |
| [Deutsch](./share/doc/de/readme.md)          | Eine Hand wäscht die andere. <!-- nicht verfügbar -->                                                          | \*             |
| [español](./share/doc/es/readme.md)          | Quien siembra vientos, recoge tempestades. <!-- no disponible-->                                               | \*             |
| [français](./share/doc/fr/readme.md)         | Si bien dire vaut, moult bien faire passe tout. <!-- non disponible -->                                        | \*             |
| [ру́сский](./share/doc/ru/readme.md)          | Наша величайшая слава не в отсутствии падений, но в том, чтобы каждый раз вновь подниматься<!-- недоступен --> | \*             |
| [português](./share/doc/pt/readme.md)        | Estando madura a pera e antes que ela apodreça, vem quem bem a mereça. <!-- não disponível   -->               | \*             |
| [čeština](./share/doc/cs/readme.md)          | Kdo chce kam, pomozme mu tam.<!-- není dostupný -->                                                            | \*             |
| [日本語](./share/doc/ja/readme.md)           | 君日本語本当上手(<(= ￣ y▽ ￣)╭ 笑)                                                                            | Σ<(=っ °Д °)っ |
| [한국어](./share/doc/ko/readme.md)           | 성공한 사람보다는 가치 있는 사람이 되라.                                                                       | \*             |
| [正體中文-臺灣](./share/doc/zh-TW/readme.md) | 裡面有“好康”的東西？是什麼呀？是新書哦？                                                                       | \*             |
| [繁體中文-香港](./share/doc/zh-HK/readme.md) | 裏面嘅嘢唔系粵語。For example, “我喜歡它”唔會被 converted to “我鍾意佢”。                                      | \*             |

<!--  -->

## 2. Quick start

### 2.1 container images

#### GUI

Q: Do I have to use a script to install it?  
A: No! No need at all.

Q: Oh god! This stupid thing is writing in my **~/.local/share** directory again. It's so annoying. How do I stop it?  
A: You can use a docker container with tmoe pre-installed. It will create the data files inside the container, not in the host.

|         | xfce              | kde               | mate                  | lxqt        | cutefish          | lxde      |
| ------- | ----------------- | ----------------- | --------------------- | ----------- | ----------------- | --------- |
| alpine  | amd64,arm64       | amd64,arm64       | 386,amd64,arm64,armv7 | None        | None              | None      |
| arch    | amd64,arm64,armv7 | amd64,arm64       | amd64,arm64           | None        | amd64,arm64,armv7 | None      |
| debian  | amd64,arm64       | amd64,arm64       | amd64,arm64           | None        | None              | 386,armv7 |
| fedora  | amd64,arm64       | amd64,arm64       | amd64,arm64           | amd64,arm64 | None              | None      |
| kali    | amd64,arm64,armv7 | None              | None                  | None        | None              | None      |
| manjaro | amd64,arm64       | None              | None                  | None        | None              | None      |
| ubuntu  | amd64,arm64       | amd64,arm64,armv7 | amd64,arm64           | amd64,arm64 | None              | None      |

style 1: **cake233/alpine-mate-386**, **cake233/debian-lxde-armv7**  
style 2: **cake233/xfce:kali**, **cake233/kde:fedora**

Note:
**cake233/alpine-mate-386** = **--platform=linux/386 cake233/mate:alpine**

<details>  
  <summary>Click ▶️ to expand</summary>

~~If you want to install a desktop on a linux server, then I would advise you not to do anything stupid.~~  
Just kidding. It probably wouldn't do much good to do so, but you might really consider `tmoe` gui container.

Assuming your host is a debian-based distribution (e.g. ubuntu, mint or kali)

install docker

```sh
sudo apt update
sudo apt install docker.io

WHOAMI=$(id -un)
sudo adduser $WHOAMI docker
# then reboot
```

test alpine

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

Run `startvnc`, then open the vnc client and type "your_ip_address:5903"

The next section describes how desktop users can use these GUI containers.  
It is probably a mistake to use docker containers as virtual machines.  
In fact, for GUI desktop containers, I recommend using systemd-nspawn rather than docker.

The following is only a basic overview, additional changes are required.  
Note: Some fantastic projects, such as x11docker, can assist you in improving your performance.

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

</details>

#### noGUI

Some of the nogui containers associated with tmoe are still considered separate projects at this time.  
This is due to the fact that they do not come pre-installed with tmoe tools.

If you don't want a desktop, simply replace xfce/kde/mate with zsh and you're done.

```sh
docker volume create zsh
docker run \
    -it \
    --name zsh \
    -v zsh:/shared_dir \
    cake233/zsh:kali
```

Q: How do I run containers of other architectures?

A:

<details>  
  <summary>Click ▶️ to expand</summary>

install qemu-user-static

```sh
sudo apt install binfmt-support qemu-user-static
```

Take rust cross-compilation as an example.

> Note: The following containers are updated twice a week.  
> docker-hub repo: cake233/rust  
> nightly(gnu): amd64, arm64, armv7, riscv64, ppc64le, s390x, mips64le  
> nightly(musl): amd64, arm64

Note: I prefer to use **cross-rs** instead of the example below for rust cross-compilation.

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

### 2.2. local installation

If you can't, or don't want to use docker, then you can install it locally.

| method | tool  | condition                                                                                                          | command                                    |
| ------ | ----- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| ~~1~~  | cargo | ~~you are using `rustc` **nightly**~~ (Temporarily unavailable, `tmm`(edition 2022) will be released before 2023.) | ~~`cargo install tmm`~~                    |
| 2      | curl  | you have `curl` installed, and can access github                                                                   | `. <(curl -L git.io/linux.sh)`             |
| 3      | curl  | you cannot access github                                                                                           | `. <(curl -L gitee.com/mo2/linux/raw/2/2)` |
| 4      | curl  | none of the above methods can be installed                                                                         | `curl -Lo l l.tmoe.me; sh l`               |

<!-- | 1      | cargo | you have `cargo` installed        | `cargo install tmoe`            | -->

## 3. have issue?

Please report an [issue](https://github.com/2moe/tmoe-linux/issues/new/choose).  
You can use čeština, Deutsch, español, français, português, ру́сский & 中文, etc.  
If you want to discuss topics unrelated to this project, then please go to github [discussions](https://github.com/2moe/tmoe-linux/discussions).

## 4. what can I do?

You can enjoy gnome or other desktops on arm64 device.

![Screenshot_20210806-222714](https://user-images.githubusercontent.com/25324935/128526315-02475932-7327-4a8b-8446-2d22e82a77b4.png)

## 5. Index

### 5.1. main

| chapter                                     | introduction                              | file                   |
| ------------------------------------------- | ----------------------------------------- | ---------------------- |
| prologue.part A                             | Some short notes                          | Readme.md              |
| [prologue.part B](./share/doc/en/readme.md) | Facing History, venturing into the future | share/doc/en/readme.md |
| [1](./share/doc/en/1.md)                    | Container Installation and Configuration  | share/doc/en/1.md      |
| [2](./share/doc/en/2.md)                    | Error handling                            | share/doc/en/2.md      |
| etc...                                      | \*                                        | \*                     |

### 5.2. current

- [1. Doc](#1-doc)
  - [1.1. lite](#11-lite)
  - [1.2. full](#12-full)
- [2. Quick start](#2-quick-start)
  - [2.1 container images](#21-container-images)
    - [GUI](#gui)
    - [noGUI](#nogui)
  - [2.2. local installation](#22-local-installation)
- [3. have issue?](#3-have-issue)
- [4. what can I do?](#4-what-can-i-do)
- [5. Index](#5-index)
  - [5.1. main](#51-main)
  - [5.2. current](#52-current)
