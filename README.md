# Termux-Debian

#### 介绍
在termux上一键安装debian proot容器，并自动配置中文环境。 
![Capture__2020-02-16-02-23-49.png](https://gitee.com/mo2/pic_api/raw/test/2020/02/16/KtxgGq3bFSf4Uwvo.png)

支持一键安装图形界面。

![截图_2020-02-01_08-53-21.jpg](https://gitee.com/mo2/pic_api/raw/test/2020/02/16/yMgxSkGh0Tx4IJz0.jpg)

#### 软件架构
软件架构说明

##### 支持arm64(aarch64)、armhf、armel、amd64(x86_64) 和 i386(x86)。




#### 安装教程

1.  ##### This script should be run via curl:
```shell
apt install -y curl ; bash -c "$(curl -fsSL 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```



2. ##### or wget:
```shell
apt install -y wget ; bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

#### 使用说明

##### ##简易版说明（萌新专用）

1.安装debian命令

```shell
pkg i -y wget && bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

2.启动命令

```shell
debian
```

3.卸载命令 

```shell
debian-rm
```

(仅支持在termux原系统内输)

4.安装xfce桌面的命令 

```shell
./xfce.sh
```

（仅支持在debian系统内输）

5.启动vnc命令 

```shell
startvnc
```

（同时支持）

6.停止vnc命令

```shell
 stopvnc
```

（同时支持）

-------------------------------------------------

##### ##完整版说明（Full description)

#### Step1.

##### 1-1. You can use the following command to install debian.

安装debian系统的命令是 

```shell
apt install -y wget && bash -c "$(wget -qO- 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh')"
```

#(旧版)视频教程[链接](https://pan.baidu.com/s/1rh7Nkcd0gG9RPx77JyGqZA)

: 提取码: debb

###### #可选步骤（Optional step）：

输`./kali.sh`更换为kali源，输`./kali.sh rm` 移除kali源。

#####  1-2.安装后的步骤。

#If you want to start debian next time, you can just type "debian".
#下次启动debian的命令是
`debian`

#关于debian的重新安装与移除

输`debian-i` 重装debian
输`debian-rm` 移除debian



#### Step2.安装图形化桌面环境。

##### 2-1.安装前（关于桌面环境的安装与卸载）

进入debian系统后，请从xfce、lxde、mate和lxqt中选择一种。

xfce的安装方法：
(至少有16种方法可以安装，下面列举8种)
              
				 

```shell
             ./xfce.sh
              
             ./xfce.sh i
			 
             ./xfce.sh in
			 
             ./xfce.sh install
			 
             ~/xfce.sh				 
			 
             bash xfce.sh
			 
             bash xfce.sh i
			 
			 bash ~/xfce.sh
```

xfce的卸载方法： 
               
				 
```shell
             ./xfce.sh rm
              
             ./xfce.sh remove
			 
             ./xfce.sh un
			 
             ./xfce.sh uninstall
			 
             ./xfce.sh purge				 
			 
             bash xfce.sh rm 
			 
			 bash ~/xfce.sh rm               
```

（下面相似，故省略）                 				
								
输`./mate.sh`或bash mate.sh安装mate; 输./mate.sh rm卸载
输.`/lxde.sh`安装lxde; 输 ./lxde.sh rm卸载
输.`/lxqt.sh`安装lxqt; 输 ./lxqt.sh rm卸载

gnome和kde是用来卖萌用的，不要安装。如需安装，请自行解决依赖关系和其它问题。
四选一！千万不要一下子装两个桌面！

##### 2-2.安装中

安装过程会提示选择键盘布局，请直接按回车。
初次启动vnc服务，会提示输6至8位（不可见）的密码，输两遍。
当提示Would you like to enter a view-only password ？时
输n

##### 2-3.安装后

输`startvnc`启动vnc服务，
输`stopvnc`停止vnc服务。
完成后，打开vnc viewer客户端，输localhost:5901

在termux原系统输startvnc将自动启动vnc客户端+debian系统+vnc服务端，若无启动提示，请在进入debian后，再输一遍startvnc

#### 其它说明：

1.若无法退出debian系统，请在termux原系统内输`stopvnc`
2.若zsh配置失败，请输入`./zsh.sh`进行重新配置。
3.主目录下的sh文件可以删除，但sd、tf和termux三个目录不要删。因为这三个目录挂载了设备存储空间，分别和内置存储、tf卡(termux专有目录)以及termux主目录联动。



#### #可选步骤

#修改分辨率的方法

```shell
apt install -y nano && nano /usr/bin/startvnc
```

#将1440x720（竖屏）改成你需要的分辨率，例如1920x10780（横屏）
修改完成后，按Ctrl+O保存，Ctrl+X退出。

#将1440x720（竖屏）改成你需要的分辨率，例如1920x10780（横屏）
修改完成后，按Ctrl+O保存，Ctrl+X退出。

#你可以装个浏览器来玩玩
输`./firefox.sh`安装firefox浏览器,输`./firefox.sh rm`卸载
输`./chromium.sh`安装chromium浏览器,输`./chromium.sh rm`卸载

#chromium浏览器的启动命令是 `chromium --no-sandbox`

#安装Linux qq

```shell
wget -O linuxqq.deb https://qd.myapp.com/myapp/qqteam/linuxQQ/linuxqq_2.0.0-b1-1024_arm64.deb ; apt install -y ./linuxqq.deb
```

#若链接失效，请前往https://im.qq.com/linuxqq/download.html

本文首发于酷安网@萌系生物研究员
2019-11、12月：旧版脚本部分命令借鉴了atilo-cn和AnLinux，除此之外，大部分都是本人手打的。
可能会有出错的地方，欢迎指正。

2020-02-15
完全重写脚本！
本来是不想维护的，但是我发现了一个很严重的bug,所以干脆重写一遍。
本次更新的内容真的有点多，而且真的很强哦ο(=•ω＜=)ρ⌒☆，我自己都觉得太强了！
脚本文件已经达到了40多KB了。

#### 优化内容：

​                 1.获取镜像途径依旧是清华镜像站，但把下载工具从wget换成了aria2，从原本的单线程变成现在的16线程，加快了下载速度。

​		 2.自动配置中文环境，默认就是中文，无需手动配置。

​		 3.修复旧版脚本中非xfce桌面的xstartup文件问题。

​		 4.新增自动配置zsh的功能，初次启动会出现提示，若在指定时间内无操作会自动开始安装并配置zsh。
​		 包含主题和语法高亮、语法历史记录插件。

​		 5.简化安装流程，且不再需要某种很神奇的internet工具。

​		 6.将debian 10 buster (stable)换成 sid bullseye(unstable)，滚动升级，一直都是新版。

​		 7.修复chromium浏览器的启动问题，使用sh chromium.sh安装的版本，可以直接点击图标启动，在root环境下无需加--no-sandbox参数。

​		 8.加入对armhf和x86_64(amd64)的支持。

​		 9.支持一键更换为kali源，debian变身kali就是这么简单！

​		10.简化卸载流程，安装脚本也可以执行卸载操作。		 

​		11.根据当前linux shell环境自动修改proot启动脚本。

​		12.修复启动vnc后，debian无法正常关闭的bug  ,(请在termux原系统内输stopvnc)

​		13.简化启动流程，你可以在termux原系统里输startvnc来启动debian+vnc客户端
​           
​		14.vnc支持自动获取本机局域网ip，地址格式类似于192.168.123.3:5901
​		 