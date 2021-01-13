# build docker image

For example
archlinux amd64 + kde plasma

```bash
cd amd64/arch/kde
docker build -t arch-kde .
```

Your image name is arch-kde

How to run it?

```bash
docker run -it -p 5903:5901 --name arch-amd64-kde --env LANG=en_US.UTF-8 arch-kde
docker exec -it arch-amd64-kde /bin/zsh
```

The default vnc port of container is 5901.
Because of `-p 5903:5901`,your vnc address is **localhost:5903**
