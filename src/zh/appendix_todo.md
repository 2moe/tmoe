# TODO

## tmm

### config

运行以下命令

```sh
tmm new uuu ubuntu:kinetic
```

然后它会输出 "ubuntu:kinetic" 的容器属性信息（只读）， 接着会在当前目录下生成 uuu.toml 配置文件(可写)。

> 实际配置会比以下内容更加全面，以下内容仅供参考

```toml
name = "uuu"
arch = "arm64"
cmd = ["bash", "-l"]
# user = "root"
user = "0:0"
path = "/xxx/yyy/uuu"

[os]
name = "ubuntu"
code = "kinetic"

[image]
file = "/sdcard/Download/backup/ubuntu-22.10-rootfs.tar.zst"
name = "ubuntu"
tag = "kinetic"
sha256 = "2e72d56249c7b3894d9d5baef5f1fd8fd7aa0fcf8a5253d77ceb7bbfc40d660b"

[mount]
name = [
    "sd",
    "tf",
    "pic",
]

[mount.sd]
enabled = true
type = "bind"
src = "/data/media/0/Download"
dst = "/media/sd"

[mount.pic]
enabled = false

[mount.tf]
enabled = false

[env]
# PATH = ""
# 这是一个小细节，对普通用户和 root 用户使用不同的 PATH。
# 普通用户的 PATH 不应该包含 /sbin
ROOT_PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin"
NORMAL_PATH = "/usr/local/bin:/usr/games:/usr/bin:/bin"
```

手动修改这个配置  
用 set 子命令修改

```sh
tmm set uuu path "/data/data/xxx/yyy/uuu"
```

用 get 获取

```sh
tmm get uuu image.tag
# 输出 kinetic
```

也可以直接修改配置文件。  
最后运行`tmm r uuu` 或者是 `tmm run uuu`
