# android

Tmoe is divided into two parts, the "Manager" and the "Tools".  
For android, you can use the "Tmoe Manager".

## 1. About docker

Actually, android can also run docker.  
If you want to use native docker, you need to manually compile the kernel with some of the features required for docker.  
If your kernel is not open source, or if your device is not bootloader unlocked, then you may need to use docker indirectly through a virtual machine.

In this chapter, we do not cover the following.

- How to recompile the kernel for android
- How to run docker on android

## 2. Tmoe Manager

If you want to use the "Tmoe Manager", then you can install it using the script.

> In edition 2022, the "Tmoe manager" is called `tmm`.  
> At this stage, most of Tmoe's content is still in edition 2021  
> For compatibility with older versions, the developers will keep the `tmoe` command for android

For android, you can run the following script with [termux](https://github.com/termux/termux-app/actions).  
Afterwards "2moe" may make a deb package of the content, or it may adapt it to other terminals.

> The reason why `curl` is used is that termux pre-installs it.  
> If it is not pre-installed, then you need to install it with `apt update; apt install -y curl`

| method | tool | condition                                             | command                            |
| ------ | ---- | ----------------------------------------------------- | ---------------------------------- |
| 1      | curl | You have `curl` installed,</br> and can access github | `. <(curl -L l.tmoe.me/hub/sh)`    |
| 2      | curl | You cannot access github                              | `. <(curl -L l.tmoe.me/m/sh)`      |
| 3      | curl | None of the above methods work                        | `curl -Lo l l.tmoe.me/ee/sh; sh l` |

"tmoe-linux" could be renamed or blocked for some reason.  
The above link will automatically take you to the corresponding git repository.

## 3. chroot/unshare

Before you use Tmoe to install unshare container on android, it will ask you to select "share/mount sd directory".  
For miui, please do not select the whole "/data/media/0" or "/sdcard"  
 Please select a specific subdirectory, such as "/data/media/0/Download".  
Mounting the whole internal sd may cause it to be unmounted together when `umount`.

[issue1](https://gitee.com/mo2/linux/issues/I5488U)  
[issue2](https://github.com/2moe/tmoe/discussions/166)

If you insist, perform a little manual test before mounting the whole internal sd.

```sh,editable
cd $TMPDIR
mkdir -pv sd
su -c "/system/bin/mount -o bind /sdcard $PWD/sd"
sudo ls sd
su -c "/system/bin/umount -lvf $PWD/sd"
ls /sdcard
```

See what's going on?

## 4. proot

| problem                                 | note                                                                           |
| --------------------------------------- | ------------------------------------------------------------------------------ |
| Unable to bind ports between 0 and 1023 | see this [issue](https://github.com/2moe/tmoe/issues?q=is%3Aissue+is%3Aclosed) |

## 5. Command

### 5.1. In host environment

#### 5.1.1. For GUI containers

- `startvnc`
  - Prerequisite: You need to install vnc viewer or other vnc client first
  - For android, only vnc viewer will be started "simultaneously"
  - Function: Start the default vnc server (usually tigervnc)
- `startx11vnc`
  - Prerequisite: same conditions as above
  - Function: Start x11vnc server
- `stopvnc`
  - This command makes it simple to kill the rootless container (its vnc server process)
  - For the chroot/unshare (rootful) container, you must stop the container process separately.
- `startxsdl`
  - Prerequisite: You must first install the xserver application in your host environment.
  - Function: Start Xorg
- `novnc`
  - Prerequisite: you don't need to install a regular vnc client, just a browser is enough
  - Function: Start the host browser, and the novnc inside the container

#### 5.1.2. noGUI

For edition 2020:

- `debian`
  - Automatically detects the default container name, type, and architecture. Start the container after the detection is complete.

For edition 2021：

- `tmoe ls`
  - Automatically determine the default container type and list the containers
- `tmoe p`
  - Start the default proot container
- `tmoe c`
  - Start the default chroot/unshare container
- `tmoe` 或 `tmoe m`
  - Start tmoe manager

For edition 2022：

- `tmm r <Container name>`
  - For example, `tmm r uuu`
- `tmm`
  - start tmoe manager

### 5.2. In container environment

If the host supports "simultaneous" startup, then you do not need to start the vnc server in the container

- `tmoe` 或 `tmoe t`
  - start tmoe tools
- `startvnc`
  - Start the default vnc server (usually tigervnc)
- `startx11vnc`
  - start x11vnc server
- `stopvnc`
  - stop vnc server
- `startxsdl`
  - start xorg
- `novnc`
  - start novnc

#### For debian-based distros

- `tigervnc`
  - start tigervnc server
- `tightvnc`
  - start tightvnc server
