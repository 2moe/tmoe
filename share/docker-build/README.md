# build podman image

## archlinux amd64 + kde plasma

```bash
cd amd64/arch/kde
[[ ! -r ../bootstrap.sh ]] || bash ../bootstrap.sh
podman build -t arch-kde .
```

Your image name is arch-kde:latest

How to run it?

```bash
podman run \
    -it \
    -p 5903:5902 \
    --name arch-amd64-kde \
    --env LANG=en_US.UTF-8 \
    arch-kde
```

How to attach it?

```bash
podman start arch-amd64-kde

podman exec \
    -it \
    arch-amd64-kde \
    /bin/zsh
```

or

```bash
podman attach arch-amd64-kde
```

How to start vnc server?

```
startvnc
```

The default vnc port of container is 5902.
Because of `-p 5903:5902`,your vnc address is **localhost:5903**

## debian sid arm64 + xfce

```bash
sudo apt update
sudo apt install qemu-user-static
cd arm64/debian-sid/xfce
[[ ! -r ../bootstrap.sh ]] || bash ../bootstrap.sh
podman build -t debian-xfce .
```

How to run it?

```bash
podman run \
    -it \
    -p 5903:5902 \
    -p 36081:36080 \
    --name debian-arm64-xfce \
    --env LANG=en_US.UTF-8 \
    debian-xfce \
    /bin/bash
```

How to start novnc?

```
podman exec \
    -it \
    debian-arm64-xfce \
    /bin/bash
novnc
```

How to connect to it?

Open your browser, and type the address:

```
localhost:36081
```

How to attach it?

```bash
podman start debian-arm64-xfce
podman attach debian-arm64-xfce
```
