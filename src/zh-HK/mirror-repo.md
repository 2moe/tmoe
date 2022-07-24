# 鏡像源

- [1. debian-based](#1-debian-based)
  - [1.1. 快速上手](#11-快速上手)
  - [1.2. 詳細解析](#12-詳細解析)
    - [1.2.1. set-src-list](#121-set-src-list)
    - [1.2.2. region-code-repo](#122-region-code-repo)
    - [1.2.3. 軟件包解析](#123-軟件包解析)
    - [1.2.4. set-src-link](#124-set-src-link)
      - [1.2.4.1. region & link](#1241-region--link)
      - [1.2.4.2. unlink](#1242-unlink)
    - [1.2.5. 源文件解析](#125-源文件解析)

---

您若在使用發行版的官方鏡像源時，體驗不佳，那不妨試試本項目的“更換髮行版鏡像源”功能。

## 1. debian-based

開發者為每一個鏡像源都打了一個 deb 包。

對於 debian 和 ubuntu 通用的源的 deb 包，開發者把它們放到了 neko 倉庫。

<div style="display:none">
```mermaid
graph TD
    A(debian) --> D(toy-repo)
    A(debian) --> C(neko-repo)
    B(ubuntu) --> C
    B(ubuntu) --> E(uuu-repo)
```
</div>

![mirror-repo_neko-toy-and-uuu.svg](assets/mirror-repo_neko-toy-and-uuu.svg)

缺陷：

- 儘管您可以在 kali 和 mint 上使用，但是並非所有鏡像源都支持它們，提供 ubuntu 鏡像源的網站不一定會同時提供 mint 源。
- 目前，由於 debian-ports 的鏡像源過於稀少，因此本功能未對 riscv64 等架構進行適配。

### 1.1. 快速上手

如果您不明白下面的命令的具體意義，那麼請不要直接運行。  
在下一小節中，我們將會對其進行解析。

```sh
sudo set-src-list dis
sudo apt update
sudo apt install ustc-linux-user-group-cn-repo
sudo apt update
```

### 1.2. 詳細解析

#### 1.2.1. set-src-list

> `set-src-list` 由 `neko-repo` 提供

首先，運行 `set-src-list`  
它輸出的內容為：

```sh
-d | dis | disable: disable src list
-e | en | enable: enable src list

Note: This is a dangerous operation.
If you run "set-src-list dis", then it will move your "/etc/apt/sources.list" to "/etc/apt/sources.list.bak"
If you run "set-src-list en", then it will move your "sources.list.bak" to "sources.list"
```

這個工具非常簡單，簡單到您會懷疑它是否能被稱為“工具”。

以 root 身份執行 `set-src-list dis` , 它將 **/etc/apt/** 目錄下的 "sources.list" 重命名為 "sources.list.bak"。  
`set-src-list en` 與上面執行相反的操作。

> 作用：在換源前禁用原來的軟件源。

#### 1.2.2. region-code-repo

> 如果您不知道具體區域代號是什麼，那麼請翻閲“附錄”中的“區域代號”章節。

使用 `apt` 搜索您所在國家或地區的鏡像倉庫。

"United States": US

```sh
apt search us-repo$
```

"Germany": DE

```sh
apt search de-repo$
```

"China": CN

```sh
apt search "cn-repo|tw-repo|hk-repo"
```

```log,editable
alibaba-cloud-computing-cn-repo/neko 0.0.1-2 all
  阿里雲鏡像源(China)

bjtu-cn-repo/neko 0.0.1-2 all
  北京交通大學鏡像源(China)

blendbyte-inc-tw-repo/neko 0.0.1-2 all
  Blendbyte Inc.(Taiwan)

capital-online-data-service-cn-repo/neko 0.0.1-2 all
  Capital Online Data Service(China)

china-open-source-mirror-alliance-cn-repo/neko 0.0.1-2 all
  China open source mirror Alliance(China)

chongqing-university-cn-repo/neko 0.0.1-2 all
  重慶大學鏡像源(China)

cn99-cn-repo/neko 0.0.1-2 all
  CN99(China)

dalian-university-of-technology-cn-repo/neko 0.0.1-2 all
  Dalian University of Technology 大連理工學院鏡像源(China)

debian-cs-nctu-edu-tw-repo/toy 0.0.1-3 all
  debian.cs.nctu.edu.tw(Taiwan)

debian-csie-ncku-edu-tw-repo/toy 0.0.1-3 all
  debian.csie.ncku.edu.tw(Taiwan)

debian-csie-ntu-edu-tw-repo/toy 0.0.1-3 all
  debian.csie.ntu.edu.tw(Taiwan)

dongguan-university-of-technology-gnu-linux-association-cn-repo/neko 0.0.1-2 all
  Dongguan University of Technology GNU/Linux Association 東莞理工學院鏡像源(China)

escience-center-nanjing-university-cn-repo/neko 0.0.1-2 all
  eScience Center, Nanjing University 南京大學鏡像源(China)

ftp-cn-debian-org-cn-repo/neko 0.0.1-2 all
  ftp.cn.debian.org(China)

ftp-hk-debian-org-hk-repo/neko 0.0.1-2 all
  ftp.hk.debian.org(Hong Kong)

ftp-tw-debian-org-tw-repo/neko 0.0.1-2 all
  ftp.tw.debian.org(Taiwan)

harbin-institute-of-technology-cn-repo/neko 0.0.1-2 all
  哈爾濱工業大學鏡像源 Harbin Institute of Technology(China)

huawei-cloud-cn-repo/neko 0.0.1-2 all
  Huawei Cloud 華為雲鏡像源(China)

institute-of-network-development-national-taiwan-ocean-university-tw-repo/neko 0.0.1-2 all
  Institute of Network Development, National Taiwan Ocean University(Taiwan)

lanzhou-university-open-source-society-cn-repo/neko 0.0.1-2 all
  Lanzhou University Open Source Society 蘭州大學鏡像源(China)

mirrors-163-com-cn-repo/neko 0.0.1-2 all
  網易鏡像源(China)

mirrors-bfsu-edu-cn-repo/neko 0.0.1-2 all
  北京外國語大學鏡像源(China)

mirrors-neusoft-edu-cn-repo/neko 0.0.1-2 all
  大連東軟信息學院鏡像源(China)

mirrors-pku-edu-cn-repo/neko 0.0.1-2 all
  北京大學鏡像源(China)

mirrors-tuna-tsinghua-edu-cn-repo/neko 0.0.1-2 all
  清華大學鏡像源(China)

nchc-taiwan-tw-repo/neko 0.0.1-2 all
  NCHC, Taiwan(Taiwan)

nic-beijing-university-of-posts-and-telecommunications-cn-repo/neko 0.0.1-2 all
  NIC, Beijing University of Posts and Telecommunications 北京郵電大學鏡像源(China)

njuptmirrorsgroup-cn-repo/neko 0.0.1-2 all
  南京郵電大學鏡像源(China)

opensource-nchc-org-tw-repo/neko 0.0.1-2 all
  opensource.nchc.org.tw(Taiwan)

opentuna-cn-repo/neko 0.0.1-2 all
  OpenTUNA(China)

shanghai-jiaotong-university-cn-repo/neko 0.0.1-2 all
  Shanghai Jiaotong University 上海交通大學鏡像源(China)

sohu-cn-repo/neko 0.0.1-2 all
  搜狐鏡像源(China)

tencent-cloud-cn-repo/neko 0.0.1-2 all
  Tencent Cloud 騰訊雲鏡像源(China)

tku-tamkanguniversity-tw-repo/neko 0.0.1-2 all
  TKU-TamKangUniversity(Taiwan)

ustc-linux-user-group-cn-repo/neko 0.0.1-2 all
  中國科學技術大學鏡像源(China)

xi-an-jiaotong-university-cn-repo/neko 0.0.1-2 all
  Xi'an Jiaotong University(China)

xtom-hk-repo/neko 0.0.1-2 all
  xTom(Hong Kong)
```

> 實際上，0.0.1-4 修復了 debian (old-stable) 的一些小細節問題，這裏還是 0.0.1-2  
> 在下文介紹源文件時，將會提到相關內容，因此不更新也沒關係。

然後我們以 root 權限運行 `apt` 來安裝軟件包。

```sh
apt install opentuna-cn-repo
```

#### 1.2.3. 軟件包解析

先拆開來看看

```log,editable
├── control
│   ├── conffiles
│   ├── control
│   ├── md5sums
│   ├── postinst
│   └── postrm
└── data
    ├── etc
    │   └── tmoe
    │       └── repo
    │           └── src
    │               ├── debian
    │               │   ├── opentuna-cn-repo_old.sources
    │               │   ├── opentuna-cn-repo_sid.sources
    │               │   └── opentuna-cn-repo_stable.sources
    │               └── ubuntu
    │                   ├── opentuna-cn-repo_ports.sources
    │                   └── opentuna-cn-repo.sources
    └── usr
        └── share
            └── doc
                └── opentuna-cn-repo
                    └── changelog.Debian.gz
```

`postinst` 調用了 `set-src-link` 去創建軟鏈接。  
`postrm` 調用了 `set-src-link` 的 `unlink` 子命令去刪除軟鏈接。  
假如您的系統是 ubuntu jammy (amd64), 那麼它會將 **opentuna-cn-repo.sources** 修改為 jammy 的源，並將其軟鏈接到 "/etc/apt/sources.list.d/cn-mirror.sources"。  
如果您用的是 linuxmint vanessa， 那麼它會自動合併 ubuntu 和 vanessa 的源，並將源文件軟鏈接到 "/etc/apt/sources.list.d/cn-mirror.sources"。

如果您使用的是 us-repo, 而不是 cn-repo, 那麼它就會將源文件軟鏈接到 "/etc/apt/sources.list.d/us-mirror.sources"。

相同區域的鏡像包會被上一個安裝的包覆蓋掉，不同區域的不會。

比如説，您現在安裝了 `mirrors-bfsu-edu-cn-repo`， 那麼現在的 cn 源是 bfsu。  
您再安裝了 `shanghai-jiaotong-university-cn-repo`，那麼 cn 源就變成了 sjtu。  
此時，您再安裝了 `xtom-de-repo`，**/etc/apt/sources.list.d/** 會多出一個 de 源，它跟 cn 源並不衝突。

在一般情況下，您只需要安裝您的服務器/pc 所在區域的鏡像源即可。  
除非您有充分的理由，否則請不要在一台設備上安裝不同區域的鏡像源。

#### 1.2.4. set-src-link

在上一小節中，我們提到了 `set-src-link`，在本小節中，我們將對其進行深入解析。

在您安裝或卸載鏡像源 的 deb 包時， `set-src-link` 會被自動調用，您無需手動去調用它。

簡單來説，`set-src-link` 只做兩件事。

- 1.創建軟鏈接
  - 在創建前，它會自動判斷您的發行版。對於 ubuntu, 它還會判斷您的架構。
- 2.刪除軟鏈接

運行 `set-src-link -h`  
輸出的內容是：

```sh,editable
set-src-link 0.0.1
Set the symbolic link for the mirror source.

Usage:
 set-src-link [flags]<string>
 set-src-link [flags] [flags]
 set-src-link <subcommand> [flags]<string>

Flags:
 -n, --name <mirror-name>      set the mirror name
 -r, --region <iso-code>       set the region <ISO 3166-1 Alpha-2 code>

 -h, --help                    display help information
 -V, --version                 display version

Subcommand:
    unlink

Example:
 set-src-link -n -h
 set-src-link --region --help
 set-src-link unlink -r us
```

> `set-src-link` 需要以 root 身份運行，否則將無法修改 `/etc/apt/sources.list.d/*-mirror.sources`

##### 1.2.4.1. region & link

獲取 region 的幫助信息

```sh
set-src-link -r -h
```

`-n` 後面接的是 deb 包的包名。

創建軟鏈接

```sh
set-src-link -r cn -n opentuna-cn-repo
# os: debian
# code: sid
# '/etc/apt/sources.list.d/cn-mirror.sources' -> '/etc/tmoe/repo/src/debian/opentuna-cn-repo_sid.sources'

set-src-link -r us -n opentuna-cn-repo
# os: debian
# code: sid
# '/etc/apt/sources.list.d/us-mirror.sources' -> '/etc/tmoe/repo/src/debian/opentuna-cn-repo_sid.sources'
```

##### 1.2.4.2. unlink

```sh
set-src-link unlink
```

輸出了以下內容

```sh
Error, you should add "--region" to specify your region
```

只要指定區域就能解決了

```sh
set-src-link unlink -r cn
# unlink /etc/apt/sources.list.d/cn-mirror.sources

set-src-link unlink -r de
# unlink /etc/apt/sources.list.d/de-mirror.sources

set-src-link unlink -r us
# unlink /etc/apt/sources.list.d/us-mirror.sources
```

#### 1.2.5. 源文件解析

您如果之前曾有過手動更換 debian/ubuntu 源的經歷，那麼應該會知道 debian 傳統的 one-line-style 源格式。

```list
deb http://mirrors.bfsu.edu.cn/debian/ sid main non-free contrib
```

與傳統的 one-line-style 不同，本項目的“鏡像源”功能使用的是更現代化的 deb822-style。  
此格式要求 apt 的版本 >= 1.1.0。  
因此它在默認情況下不兼容 debian 8(Jessie)。

讓我們來看看裏面有什麼吧！

以 debian buster （old-stable）為例。  
實際上，buster 的 suites 和 bullseye 是有區別的。  
除了 security 源的區別外，backports 也應該使用不同的源。  
不能簡單地將 "stable-backports" 替換為 "old-stabe-backports"

此外，如果這個鏡像源不包含 "debian-security" 鏡像，那麼它默認會啓用官方的 security 源，並禁用鏡像 security 源。  
如果它不支持 https, 那麼 uris 那裏顯示的是 **http://** 開頭的 uri 。  
在使用 neko-repo 的鏡像源 deb 包的情況下，您無需手動去判斷它支不支持 `https` 等東西。

```sh
cat /etc/apt/sources.list.d/cn-mirror.sources
```

```yaml
name: Debian
# yes or no
enabled: yes
# types: deb deb-src
types: deb
uris: https://mirrors.bfsu.edu.cn/debian/
suites: buster
components: main contrib non-free
# architectures: amd64 arm64 armhf i386 ppc64el s390x mipsel mips64el
# --------------------------------

name: Debian updates
enabled: yes
# types: deb deb-src
types: deb
uris: https://mirrors.bfsu.edu.cn/debian/
suites: buster-updates
components: main contrib non-free
# --------------------------------

name: Debian backports
enabled: yes
# types: deb deb-src
types: deb
uris: https://mirrors.bfsu.edu.cn/debian/
# For debian old-stable, you should use "old-stable-backports-sloppy", instead of "old-stable-backports".
# https://backports.debian.org/Instructions/#:~:text=Old-stable-sloppy
# suites: buster-backports
suites: buster-backports-sloppy
components: main contrib non-free
# --------------------------------

name: Debian security
enabled: yes
# types: deb deb-src
types: deb
uris: https://mirrors.bfsu.edu.cn/debian-security/
suites: buster/updates
components: main contrib non-free
# --------------------------------

name: Official security
enabled: no
# types: deb deb-src
types: deb
uris: https://deb.debian.org/debian-security/
suites: buster/updates
components: main contrib non-free
# --------------------------------

name: Proposed updates
enabled: no
# types: deb deb-src
types: deb
uris: https://mirrors.bfsu.edu.cn/debian/
suites: buster-proposed-updates
components: main contrib non-free
# --------------------------------
```

`enabled` ：是否需要啓用這個源，可選 yes 或 no  
`types`: 類型，一般情況下用 **deb**, 若有獲取源代碼的要求，就用 **deb deb-src**

除了上面介紹到的內容外，deb822-style 還支持其他的 keys(鍵)。

> key: value  
> 左為鍵，右為值  

例如:

使用 signed-by 指定 OpenPGP 公鑰。

```yaml
signed-by: /usr/share/keyrings/tmoe-archive-keyring.gpg
```
