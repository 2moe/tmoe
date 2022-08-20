# TMOE

TMOE, More Optional Environments.

## Documentation

[doc.tmoe.me](https://doc.tmoe.me)

## Preview

![locale](assets/preview/2022-05-12_16-29-43.png)  
![container menu](assets/preview/2022-05-12_16-31-26.png)  
![debian-xfce](assets/preview/2022-05-12_16-32-09.png)

## Quick Start

Just focus on steps 1 and 2.

| Step          | Description           | command                                        |
| ------------- | --------------------- | ---------------------------------------------- |
| 0(optional)   | access to tmp dir     | `cd /tmp` or `cd $TMPDIR`                      |
| 1             | get awk file          | `curl -LO https://l.tmoe.me/2.awk`             |
| 2             | run it                | `awk -f 2.awk`                                 |
| 2.5(optional) | pass in specific vars | `awk -f 2.awk -v lang=zh-mo -v tmp_dir="/tmp"` |

If you can't remember, then you can use this.

```sh
rm 2.awk; wget l.tmoe.me/2.awk; awk -f 2.awk
```

Although it will automatically redirect `http` to `https`.  
However, in theory you need to worry about http **hijacking** if you don't add `https`.  
So, it's better to add it!

Q: Is this the only uri?

A: No, because it is hosted on the git platform.  
Therefore, you can get it from github or gitee.

github:

```sh
curl -LO --compressed https://raw.githubusercontent.com/2moe/tmoe/2/2.awk
awk -f 2.awk
```

Great, but slightly long.

gitee:

```sh
curl -LO https://gitee.com/mo2/linux/raw/2/2.awk
awk -f 2.awk
```

In practice, the choice of uri depends on the state of your network.  
If you have good internet. Just pick the one you like.
