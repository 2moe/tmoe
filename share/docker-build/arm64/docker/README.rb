#!/usr/bin/env ruby
#ruby README.rb

puts "
	You can use this image to run docker on Android system.
	The password of the root account is empty. After starting the qemu virtual machine, open the vnc client and enter localhost:5905. 
	The default root passwd is empty.
	After entering the system,you should type \033[32m passwd \033[0m to change your password.
	If you want to use ssh connection, please create a new termux session, and then install openssh client. Finally, you can type \033[32m ssh -p 2888 root@localhost \033[m
	If you can not connect to it, please run \033[36m ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:2888'\033[m

	您可以使用本镜像在宿主机为Android系统的设备上运行aline_x64并使用docker
	您可以直接使用vnc客户端连接，默认访问地址为localhost:5905
	默认root密码为空。
	请在登录完成后，输入\033[32m passwd \033[0m修改root密码。
	如果您想要使用ssh连接，那么请新建一个termux会话窗口，并输入\033[33m apt update ;apt install -y openssh\033[m
	您也可以直接在linux容器里安装并使用ssh客户端，输入 apt install openssh-client
	在安装完ssh客户端后，使用\033[32m ssh -p 2888 root@localhost \033[m连接
	"