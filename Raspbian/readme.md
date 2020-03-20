# debian 更换为树莓派软件源的教程

- 1.安装 armhf 的 debian-buster 容器镜像。
- 2.将 etc/apt/sources.list 和 etc/apt/trusted.gpg.d 覆盖到 debian 系统内根目录下相应位置，建议覆盖前先执行 `tar -PpJcvf ~/sources.bak.tar.xz /etc/apt` 备份原文件。
  ![8giLlQ.png](https://s1.ax1x.com/2020/03/20/8giLlQ.png)
- 3.Raspbian 原系统更换 debian-buster 源也是相同的方法。
