# Environment variables and automatic startup scripts

关于 tmoe container 环境变量选项与自启动脚本的说明:  
注：适用于 v1.4539.0（2021-04-23）及更新的版本安装的 proot/chroot 容器。  
注 2：部分新用法仅支持 v1.4767.0 及更新的版本。  
注 3：除了 **global env** 外，其他功能仅当 login shell 为 zsh/bash 时，才会生效。

## Global environment variables

(全局环境变量)

容器在启动前，会加载环境变量文件，并将其自动生成为容器的启动参数，因此修改环境变量文件理论上对大部分 login shell 都能生效。  
选择该选项，本质上是修改容器内部的 **/usr/local/etc/tmoe-linux/environment/container.env**

如何定义容器内部环境的变量并赋值？

是这个样子吗？

```shell
NAME="value"
```

虽然那样子也可以，但是考虑到种种原因，请写成这种形式。

```shell
export NAME="value"
```

例如：

```shell
export RUSTUP_HOME=/usr/local/rustup
export GOPATH=/go
```

有一个特殊变量需要注意，那就是 _PATH_  
如果需要自定义 PATH 为"/go/bin:/usr/local/go/bin", 那么请这样子写:

```shell
export PATH="/go/bin:/usr/local/go/bin${PATH:+:${PATH}}"
```

修改完 env 文件后，大部分 shell 都能生效，就算 login shell 是 **fish** 也可以。

注：若 login shell 为 bash，则它可能会在全局配置 /etc/profile 中覆盖掉 _PATH_ , 为了防止 env 文件定义的全局 PATH 变量失效，tmoe 在 /etc/profile.d 中创建了一个 000_env.sh 的软链接。

若 login shell 为 zsh, 则无需担心，默认情况下 **/etc/zsh/zshenv** 不会重新定义容器初始化的环境变量。  
注意是默认情况下，若为手动定义，则还是会覆盖掉初始变量的值的。

从优先级来考虑：

用户目录下的 .zshenv > 全局 /etc/zsh/zshenv > 容器初始化设置的环境变量

若为单一用户，则建议您优先考虑用户目录下配置文件。

## Temporary scripts

注：临时脚本的文件夹位于容器内部的 **/tmp/.tmoe_container_temporary**

### create a script

如果需要创建临时自启动脚本，那么建议您使用 `tmoe` 命令。

这里假设您选择了 ubuntu focal, 接着选了 create a new container(新建容器)，并自定义了文件名称为“下北澤紅茶”，最后成功新建了一个 ubuntu 容器。

这时候启动命令就不再是 `tmoe p u 20.04` 了，而是 `tmoe p u 下北澤紅茶`

`tmoe` 命令最后的两个参数可以使用命令、脚本、二进制文件或文件夹。

这里假设您在当前路径下新建了一个 ruby 脚本

```shell
cat >hello.rb <<-'RUBY'
#!/usr/bin/env ruby
50.times{p "hello"}
RUBY
```

文件名称为 hello.rb

那么我要怎么样才能让 **ubuntu-下北澤紅茶** 容器启动后自动执行 `hello.rb` 呢？

是这样子吗？

```shell
tmoe p u 下北澤紅茶 hello.rb
```

并不是，如果您这样做了，那么 tmoe 会认为您想要在容器内执行 `hello.rb` 命令，而不是本地的 `hello.rb` 脚本。

当前目录下的文件请使用 "./"

```shell
tmoe p u 下北澤紅茶 "./hello.rb"
```

若容器内部不存在 ruby, 那么您可以这样写。

```shell
tmoe p u 下北澤紅茶 "./hello.rb" "sudo apt update;
sudo apt install -y ruby;
./hello.rb
"
```

### multi files

关于使用多参数来执行多个脚本或多命令的说明。

目前仅支持最后两个参数。  
tmoe 对于本地文件的优先级要高于容器内部文件。  
若本地存在 **~/hello.rb**，而容器内部存在同名文件，则优先检测本地文件，仅当本地不存在相应文件时才会执行容器内部的文件。

---

假设您想要在本地编写程序，在容器内编译并执行。

来看一个示例吧！

````shell
mkdir -pv "example_1/src/模块_两个数" "example_1/benches"

cat >example_1/Cargo.toml<<-'TOML'
# cargo-features = ["edition2021"]

# If the rustc version is lower than 1.56, then it may not work properly.
# If you want to run it on rustc old version {
# 1.53 ..= 1.55 => change editon = "2021" to editon = "2018",
# v if v < 1.53 => replace all non-ascii characters with ascii characters (variable, function name, structure name, etc.)
# }

[package]
name = "example_1"
version = "0.0.1"
authors = ["test <test@xxx.com>"]
edition = "2021"

[dependencies]
bencher = "0.1.5"

[[bench]]
name = "bench"
harness = false
TOML

cat >example_1/src/main.rs<<-'RUST_MAIN_RS'
use example_1::{处理参数::取_参, 模块_两个数::数};
use std::time;

type 持续时间 = time::Duration;
type 即刻 = time::Instant;

fn main() {
    let 开始计时a = 即刻::now();
    let 向量 = 取_参();
    let 持续时间a: 持续时间 = 开始计时a.elapsed();

    println!("从命令行读取参数并进行错误处理, 耗时: {:?}", 持续时间a);

    let 两个数字 = 数::新(向量[0], 向量[1]);

    let 开始计时b = 即刻::now();

    let 值 = 两个数字.最大公倍数();
    println!("最大公倍数 = {}", 值);

    let 持续时间b: 持续时间 = 开始计时b.elapsed();
    println!("计算最大公倍数, 耗时: {:?}", 持续时间b);
    println!(
        "平均每次计算最大公倍数的时间为纳秒级别, 而非微秒级别, 您可以使用 `cargo bench` 进行基准(跑分)测试"
    );
}
RUST_MAIN_RS

cat >example_1/benches/bench.rs<<-'CARGO_BENCH'
use bencher::Bencher;
use example_1::模块_两个数::数;

#[macro_use]
extern crate bencher;

// benchmark_1
fn 基准_1(bencher: &mut Bencher) {
    let 两个数 = 数::新(407226421212, 14067601332);
    bencher.iter(|| 两个数.最大公倍数());
}

fn 基准_2(bencher: &mut Bencher) {
    let 两个数 = 数::新(25600000000, 6400000000);
    bencher.iter(|| 两个数.最大公倍数());
}

fn 基准_3(bencher: &mut Bencher) {
    let 两个数 = 数::新(407200, 1406760);
    bencher.iter(|| 两个数.最大公倍数());
}

fn 基准_4(bencher: &mut Bencher) {
    let 两个数 = 数::新(18326750243, 23484328165);
    bencher.iter(|| 两个数.最大公倍数());
}

benchmark_group!(基准_组1, 基准_1, 基准_2, 基准_3, 基准_4);
// benchmark_main!(基准_组1);

benchmark_group!(基准_组2, 基准_1, 基准_2, 基准_3);
benchmark_main!(基准_组1, 基准_组2);
CARGO_BENCH

cat >example_1/src/处理参数.rs<<-'GET_ARGS_RS'
use std::{env, process::exit, str::FromStr};

// get_args
pub fn 取_参() -> Vec<u64> {
    // vector
    let mut 向量 = Vec::with_capacity(2);
    env::args().skip(1).for_each(|arg| {
        向量.push(u64::from_str(&arg).unwrap_or_else(|err| {
            // 0 ..= 18446744073709551615
            eprintln!(r#"无法将参数解析为Vec<u64>，请检查您输入的参数是否为数字，并且数字的范围是否在64位无符号整数类型的区间内。Failed to parse args, maybe both numbers you entered are not in the u64 range ("[0 ..= {}]")"#, u64::MAX);
            eprintln!("Error parsing uint: {}",err);
            exit(1)
        })
    )});

    println!("向量: {:?}", 向量);

    检测实参长度(&向量);
    向量
}

// check_args_len
fn 检测实参长度<泛型>(切片: &[泛型]) {
    match 切片.len() {
        len @ 0..=1 => {
            eprintln!(
                "Not enough arguments.\n\
                要求: 2, 当前: {}.",
                len,
            );
            exit(1)
        }
        2 => (),
        _ => eprintln!("仅接收前两个参数！\nOnly the first two arguments are accepted."),
    }
}
GET_ARGS_RS



cat >example_1/src/lib.rs<<-'RUST_LIB_RS'
//！ 求两个数的最大公倍数

// mod_two_nums
#[path = "模块_两个数.rs"]
pub mod 模块_两个数;

// handle_args
#[path = "处理参数.rs"]
pub mod 处理参数;
RUST_LIB_RS

cat >example_1/src/模块_两个数.rs<<-'RUST_MOD_RS'
// Nums
#[derive(Debug)]
pub struct 数 {
    pub(crate) 甲: u64,
    pub(crate) 乙: u64,
}

// normal impl
#[path = "模块_两个数/普通实现.rs"]
pub mod 普通实现;

// test
#[path = "模块_两个数/测试.rs"]
#[cfg(test)]
mod 测试;
RUST_MOD_RS

cat >example_1/src/模块_两个数/测试.rs<<-'RUST_TEST_RS'
// use super::*;

use crate::模块_两个数::*;

#[test]
fn 测试最大公倍数() {
    let 两个数 = 数::新(40722, 1406760);
    assert_eq!(3702, 两个数.最大公倍数())
}
RUST_TEST_RS

cat >example_1/src/模块_两个数/普通实现.rs<<-'RUST_IMPL_RS'
use crate::模块_两个数::*;

use std::{cmp::min, mem::swap};

impl 数 {
    pub fn 新(m: u64, n: u64) -> Self {
        Self { 甲: m, 乙: n }
    }

    pub fn 最大公倍数(&self) -> u64 {
        let a = self.甲;
        let b = self.乙;

        match (a, b) {
            (_, 0) => a,
            (0, _) => b,
            _ => self.求最大公倍数的算法(),
        }
    }

    /**
    计算两个数的最大公倍数

    gcd: Greatest Common Divisor

    可半者半之，不可半者，副置分母、子之数，以少减多，更相减损，求其等也。以等数约之。
    —— 《九章算术》更相减损术

    # Example
    ```
    use example_1::模块_两个数::数;
    let 两个数 = 数::新(1024, 96);
    assert_eq!(32, 两个数.最大公倍数())
    ```
    */
    pub fn 求最大公倍数的算法(&self) -> u64 {
        let mut y = self.甲;
        let mut x = self.乙;

        let y_0b_0 = y.trailing_zeros();
        let x_0b_0 = x.trailing_zeros();

        // 二进制移位运算
        y >>= y_0b_0;
        x >>= x_0b_0;

        let min_0b_0 = min(x_0b_0, y_0b_0);

        // assert!(x % 2 != 0);
        // x为奇数
        loop {
            if x > y {
                swap(&mut x, &mut y)
            };

            y -= x;
            if y == 0 {
                break x << min_0b_0;
            }
            y >>= y.trailing_zeros();
        }
    }
}
RUST_IMPL_RS


cat >cargo_run<<-'CARGO_RUN'
#!/usr/bin/env bash
#------------------
cd example_1

# test
cargo t

# run
# 运行，并接收两个64位无符号整数类型作为参数
cargo r 40722 1406760

# benchmark
cargo bench

CARGO_RUN
````

接着，我们让容器在启动时调用当前目录下的这些文件，最后看一下运行的结果吧！

```shell
tmoe p u 下北澤紅茶 ./example_1 ./cargo_run
```

如果程序成功运行的话，那么终端会输出以下内容

```plaintext
running 1 test
test 模块_两个数::测试::测试最大公倍数 ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running unittests (target/debug/deps/example_1-c0eccc29aa1bec6b)

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests example_1

running 1 test
test src/模块_两个数/普通实现.rs - 模块_两个数::普通实现::数::求最大公倍数的算法 (line 29) ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.18s

向量: [40722, 1406760]
从命令行读取参数并进行错误处理, 耗时: 19.911µs
最大公倍数 = 3702
计算最大公倍数, 耗时: 5.066µs

running 7 tests
test 基准_1 ... bench:          63 ns/iter (+/- 4)
test 基准_1 ... bench:          63 ns/iter (+/- 2)
test 基准_2 ... bench:           3 ns/iter (+/- 1)
test 基准_2 ... bench:           3 ns/iter (+/- 1)
test 基准_3 ... bench:          19 ns/iter (+/- 1)
test 基准_3 ... bench:          20 ns/iter (+/- 2)
test 基准_4 ... bench:          52 ns/iter (+/- 1)
```

## Permanent scripts & ln argument

注：永久性脚本的文件夹位于容器内部的 **/etc/profile.d/permanent**

建议将该功能配合 ln 参数使用。

当 ln 位于最后一个参数时，后面没有接任何路径，此时将创建容器内部的 **/etc/profile.d/permanent** 的软链接到当前路径的 "container*link_permanent*随机数值"

```shell
tmoe p u 下北澤紅茶 ln
```

将本地脚本 copy 到软链接里去, 这时候启动容器时会自动调用 **/etc/profile.d/permanent** 里的脚本或二进制文件。

您如果需要将容器目录下的 **/tmp** 软链接到当前目录, 那么可以这样做。

```shell
tmoe p u 下北澤紅茶 ln /tmp
```

假设随机数值为**114514**，那么当前目录下就会生成一个软链接文件：**container_link_tmp_114514**  
该链接指向容器内部的/tmp

如需删除该文件，那么请输入 `unlink container_link_tmp_114514` , 或者是 `rm container_link_tmp_114514` , 而不要输 `rm container_link_tmp_114514/*`

## Entrypoint

选择该选项，本质上是修改容器内部的 **/usr/local/etc/tmoe-linux/environment/entrypoint**  
（入口点）

本选项与 Permanent scripts 存在相似且重合的功能。  
若您使用的是服务型容器，则建议使用 Entrypoint。

您可以输入以下命令快速创建 entrypoint 文件的软链接。

```shell
tmoe p u 下北澤紅茶 ln en
```

或者是

```shell
tmoe p u 下北澤紅茶 ln entrypoint
```

您如果需要在执行完指定操作后就退出容器，那么可以将 `exit` 写进 entrypoint。

```shell
echo "exit 0" >> container_link_entrypoint_*
```

如需清空 entrypoint，那就输

```shell
echo "" > container_link_entrypoint_*
```

## summary

在大致了解完以上功能的用法后，让我们用几个例子来做个总结吧！

示例 1：  
进入容器后执行特定命令，并于完成后自动退出：

```shell
rm -fv container_link_entrypoint_*
tmoe p u 下北澤紅茶 ln en
echo "exit 0" > container_link_entrypoint_*
tmoe p u 下北澤紅茶 '
for i in toilet lolcat; do
    if [[ ! $(command -v ${i}) ]]; then
        sudo apt update
        sudo apt install -y ${i}
    fi
done
echo hello world | toilet | lolcat
'
```

注意：上述代码块中包含单引号。

示例 2:  
在容器内编译本地的 hello 项目，完成后自动退出。

> 注：使用容器来编译本地项目时，默认会将本地项目复制进容器内部的临时文件夹，因此您无需担心本地项目文件夹的所有权被破坏。  
> 在 v1.4539.0 版本中，默认会立即清空临时文件夹。  
> 而在 v1.4767.0 版本中，每次启动容器且未检测到锁文件(.container.lock)时，才会自动清空。

为了简化操作，此处假设您的宿主机和容器都安装了 **rust** 和 **cargo** 。

```shell
cargo new hello
rm -fv container_link_entrypoint_*
tmoe p u 下北澤紅茶 ln en
echo 'exit 0' > container_link_entrypoint_*
cat>build<<-'EOF'
#!/usr/bin/env bash
cd hello
cargo b --release
mv -v target/release/ /tmp
EOF
tmoe p u 下北澤紅茶 ./hello ./build
tmoe p u 下北澤紅茶 ln /tmp/release
echo '' > container_link_entrypoint_*
```

最后执行一下 `ls -lah container_link_release_*` 或者是 `exa -lTabgh --icons container_link_release_*`

看看里面有什么好东西吧！

## 其它说明

那么问题来了，自启动容器相关进程有什么用？  
这里引用我在内测期间写的几句话。

> If it is a temporary script, it will only be executed once and will not take effect next time. If it is a permanent script, it will be executed every time you enter the container.  
> For example, if you need a container to automatically execute ruby -run -e httpd /sd/Download -p 8080, after you create the script, the container will automatically start the ruby webrick http server.

您如果拉了一个 ruby 容器，只想要让它开 webrick http 服务器, 那么只需要编辑 entrypoint 文件，然后输入 `ruby -run -e httpd /media/sd/Download -p 48080` ， 最后保存并重进容器。  
注 1：**/media/sd/Download** 为容器内部的目录，可自定义更改。  
注 2：48080 为端口，浏览器输入 **localhost:48080** 即可访问服务。 若启动失败，则执行 `gem install webrick`

之后每次启动这个容器，无需执行任何额外操作，都会自动自动执行这条命令。  
这个容器有一个最主要的作用，那就是提供服务。  
也就是说，一个服务就是一个容器，一个配置好的环境也是一个容器。
