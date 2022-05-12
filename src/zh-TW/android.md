# android

天萌分為兩個部分，分別是“管理器”和“工具箱”。  
對於 android，您可以使用“天萌管理器”。

## 1. 關於 docker

實際上，android 也可以執行 docker。  
您如果想要使用原生 docker，那麼需要手動編譯核心，加上 docker 所需的一些特性。  
如果您的核心沒有開源，或者是您的裝置無法解鎖 bootloader, 那麼您可能需要透過虛擬機器來間接使用 docker 。

在本章中，我們並不會介紹以下內容：

- 如何為 android 重新編譯核心
- 如何在 android 上執行 docker

## 2. 天萌管理器

如果您想要使用 “天萌管理器”，那麼您可以使用指令碼進行安裝。

> 在 edition 2022 中，“天萌管理器” 叫做 `tmm`  
> 現階段，天萌的大部分內容仍處於 edition 2021  
> 為了與舊版本的相容，開發者之後會為 android 保留 `tmoe` 命令

對於 android, 您可以用 [termux](https://github.com/termux/termux-app/actions) 執行以下指令碼。  
之後“二萌”可能會把相關內容打成 deb 包，也可能會適配其他的終端。

> 之所以使用`curl`, 是因為 termux 預裝了它。  
> 如果它沒有被預裝的話，那麼您需要使用 `apt update; apt install -y curl` 來安裝。

| 方法 | 工具 | 條件                                          | 命令                               |
| ---- | ---- | --------------------------------------------- | ---------------------------------- |
| 1    | curl | 您已經安裝了 `curl`,</br> 並且可以訪問 github | `. <(curl -L l.tmoe.me/hub/sh)`    |
| 2    | curl | 您無法訪問 github                             | `. <(curl -L l.tmoe.me/m/sh)`      |
| 3    | curl | 以上方法都出錯了                              | `curl -Lo l l.tmoe.me/ee/sh; sh l` |

“tmoe-linux” 可能會改名, 也有可能因為某些原因而被封鎖。  
上面的連結實際上會自動重定向到對應的 git 倉庫。

## 3. chroot/unshare

您在 android 上使用天萌來安裝 unshare 容器前，它會讓你選擇“共享/掛載 sd 目錄”。  
對於 miui, 請不要選擇整個 "/data/media/0" 或 "/sdcard"  
 請選擇特定的子目錄，例如 "/data/media/0/Download"。  
掛載整個內建 sd 可能會導致它在 `umount` 時被一同解除安裝。  
[issue1](https://gitee.com/mo2/linux/issues/I5488U)  
[issue2](https://github.com/2moe/tmoe/discussions/166)

如果您堅持要做的話，那麼請在掛載整個內建 sd 前，手動做個小測試。

```sh,editable
cd $TMPDIR
mkdir -pv sd
su -c "/system/bin/mount -o bind /sdcard $PWD/sd"
sudo ls sd
su -c "/system/bin/umount -lvf $PWD/sd"
ls /sdcard
```

看看發生了什麼？

## 4. proot

| problem                | note                                                                           |
| ---------------------- | ------------------------------------------------------------------------------ |
| 無法繫結 1024 以下的埠 | see this [issue](https://github.com/2moe/tmoe/issues?q=is%3Aissue+is%3Aclosed) |

## 5. 命令

### 5.1. 在宿主環境中

#### 5.1.1. 對於 GUI 容器

- `startvnc`
  - 前提：您需要先安裝 vnc viewer 或其他 vnc 客戶端
  - 對於 android, 只有 vnc viewer 才會 “連攜”啟動
  - 作用：啟動預設的 vnc 服務（一般是 tigervnc）
  <!-- - 對於 wsl, 只有 tigervnc viewer 才會 -->
- `startx11vnc`
  - 前提：條件同上
  - 作用：啟動 x11vnc
- `stopvnc`
  - 此命令可以方便地幹掉 rootless 容器（包括它的 vnc 服務程序）
  - 對於 chroot/unshare（rootful）容器, 您需要單獨停止容器程序。
- `startxsdl`
  - 前提：您需要先在宿主環境中安裝 xserver app
  - 作用：啟動 xorg
- `novnc`
  - 前提：您無需安裝常規的 vnc 客戶端，只需有個瀏覽器就足夠了
  - 作用：同時啟動宿主的瀏覽器和容器內部的服務

#### 5.1.2. noGUI

對於 edition 2020:

- `debian`
  - 自動檢測預設容器名稱、型別和架構。在檢測完成後，啟動容器。

對於 edition 2021：

- `tmoe ls`
  - 自動判斷預設容器型別，並列出容器列表
- `tmoe p`
  - 啟動預設的 proot 容器
- `tmoe c`
  - 啟動預設的 chroot/unshare 容器
- `tmoe` 或 `tmoe m`
  - 啟動 tmoe manager

對於 edition 2022：

- `tmm r <容器名稱>`
  - 例如 `tmm r uuu`
- `tmm`
  - 啟動 tmoe manager

### 5.2. 在容器環境中

如果宿主支援“連攜”啟動，那麼您無需在容器內單獨啟動 vnc 服務

- `tmoe` 或 `tmoe t`
  - 啟動 tmoe tools
- `startvnc`
  - 啟動預設的 vnc 服務（一般是 tigervnc）
- `startx11vnc`
  - 啟動 x11vnc 服務
- `stopvnc`
  - 停止 vnc 服務
- `startxsdl`
  - 啟動 xorg
- `novnc`
  - 啟動 novnc

#### 對於 debian-based 發行版

- `tigervnc`
  - 啟動 tigervnc 服務
- `tightvnc`
  - 啟動 tightvnc 服務
