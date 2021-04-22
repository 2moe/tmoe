# Environment variables and automatic startup scripts

关于菜单内环境变量选项与自启动脚本的说明:  

## Global environment variables

(全局环境变量)  
注：适用于v1.4526及更新的版本安装的proot容器。  
容器在启动前，会加载环境变量文件，并将其自动生成为容器的启动参数，因此修改环境变量文件理论上对大部分login shell都能生效。  
选择该选项，本质上是修改容器内部的 **/usr/local/etc/tmoe-linux/environment/container.env**  

如何定义变量并赋值？  

是这个样子吗？  

```go
var NAME string = "value"
```

还是这个样子？  

```go
NAME := "vaule"
```

其实都不是，只需要这样子就可以了。  

```shell
NAME="vaule"
```

考虑到种种原因，请写成这种形式。  

```shell
export NAME="vaule"
```

例如：  

```shell
export RUSTUP_HOME=/usr/local/rustup
export GOPATH=/go
```

有一个特殊变量需要注意，那就是 _PATH_  
如果需要自定义PATH为"/go/bin:/usr/local/go/bin",那么请这样写:  

```shell
export PATH="/go/bin:/usr/local/go/bin${PATH:+:${PATH}}"
```

修改完env文件后，大部分shell都能生效，就算login shell是 **fish** 也可以。  

注：若login shell为bash，则它可能会在全局配置 /etc/profile 中覆盖掉_PATH_ , 为了防止env文件定义的全局PATH变量失效，tmoe在 /etc/profile.d 中创建了一个 000_env.sh的软链接。  

若 login shell为zsh, 则无需担心，默认情况下 **/etc/zsh/zshenv** 不会重新定义容器初始化的环境变量。  
注意是默认情况下，若为手动定义，则还是会覆盖掉初始变量的值的。  

从优先级来考虑：  

用户目录下的 .zshenv > 全局 /etc/zsh/zshenv > 容器初始化设置的环境变量  

若为单一用户，则建议您优先考虑用户目录下配置文件。  

## Temporary scripts

### create  

如果需要创建临时自启动脚本，那么建议您使用 `tmoe` 命令。  

这里假设您选择了ubuntu focal,接着选了beta公测(新建容器)，并自定义了文件名称为“下北澤紅茶”，最后成功新建了一个ubuntu容器，  

这时候启动命令就不再是 `t p u 20.04` 了，而是 `t p u 下北澤紅茶`  

`tmoe`命令的第四和第五个参数可以使用命令、脚本、二进制文件或文件夹。  

这里假设您新建了一个ruby脚本  

```ruby
#!/usr/bin/env ruby
p "hello"
```

文件名称为hello.rb  

那么我要怎么样才能让 **ubuntu-下北澤紅茶** 容器启动后自动执行 `hello.rb`呢？  

是这样子吗？  

```shell
t p u 下北澤紅茶 hello.rb
```

并不是，如果您这样做了，那么tmoe会认为您想要在容器内执行 `hello.rb` 命令。  

当前目录下的文件请使用 "./"  

```shell
t p u 下北澤紅茶 "./hello.rb"
```

### multi files  

关于使用多参数来执行多个脚本或多命令的说明。  

临时脚本可以是一个，也可以是多个。  
当个数在两个以内，直接使用参数即可。  
注：不支持数组形式。  
当个数大于两个时，那么最后一个参数请使用文件夹。  

tmoe对于本地文件的优先级要高于容器内部文件。  
若本地存在 **~/hello.rb**，而容器内部存在同名文件，则优先检测本地文件，若本地不存在才会执行容器内部的文件。  

本地的脚本或者二进制文件可以没有可执行权限，但是容器内部的文件必须要有可执行权限，除非您使用了命令去调用另一个脚本。    

假设本地存在一个文件夹，名为“My-Rust-Project”  

来看一个简单的示例吧！  

```shell
t p u 下北澤紅茶 "ls -lah My-Rust-Project" "./My-Rust-Project"
```

注意：以上操作没有多大的意义，ls文件夹的话，在本地执行就可以了。  

我原本的设想是这样子的：  

```shell
t p u 下北澤紅茶 "cd My-Rust-Project; cargo build --release" "./My-Rust-Project"
```

由于temporary文件夹会在执行完成后自动清空，因此不适用于编译型的任务。  
接下来，开发者可能会优化Permanent scripts选项。  

## Entrypoint

（入口点）  

本选项与Permanent scripts存在相似且重合的功能。
若您使用的是服务型容器，则建议使用Entrypoint。  

## 碎碎念  

那么问题来了，自启动容器相关进程有什么用？  
这里引用我在内测期间写的几句话。  

> If it is a temporary script, it will only be executed once and will not take effect next time.If it is a permanent script, it will be executed every time you enter the container.  
> For example, if you need a container to automatically execute ruby -run -e httpd /sd/Download -p 8080, after you create the script, the container will automatically start the ruby httpd service.  

如果您拉了一个ruby容器，只想要让它开httpd, 那么只需要编辑 entrypoint 文件，并且输入 `ruby -run -e httpd /sd/Download -p 48080`  
注：48080为端口，浏览器输入 **localhost:48080** 即可访问服务。  
之后每次启动这个容器，无需执行任何额外操作，都会自动自动执行这条命令。  
这个容器有一个最主要的作用，那就是提供服务。  
也就是说，一个服务就是一个容器，一个配置好的环境也是一个容器。  
