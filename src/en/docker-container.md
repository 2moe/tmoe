# docker

- [1. GUI](#1-gui)
- [2. noGUI](#2-nogui)

---

The following is only a cursory overview, there is much more to Docker that we have not covered in this chapter.

## 1. GUI

Q: Do I have to use a script to install it?  
A: No! No need at all.

Q: Oh god! This stupid thing is writing in my **~/.local/share** directory again. It's so annoying. How do I stop it?  
A: You can use a docker container with tmoe pre-installed. It will create the data files inside the container, not in the host.

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

style 1: **cake233/alpine-mate-386**, **cake233/debian-lxde-armv7**  
style 2: **cake233/xfce:kali**, **cake233/kde:fedora**

Note:
**cake233/alpine-mate-386** = **--platform=linux/386 cake233/mate:alpine**

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

Run `exit` or `su - yourusername`  
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

## 2. noGUI

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
