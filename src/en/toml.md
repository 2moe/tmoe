# toml

- [1. Read-only configuration](#1-read-only-configuration)
  - [1.1. The concept of read-only configuration](#11-the-concept-of-read-only-configuration)
  - [1.2. Analysing read-only configurations](#12-analysing-read-only-configurations)
- [2. toml](#2-toml)
  - [2.1. What is toml](#21-what-is-toml)
  - [2.2. toml and json](#22-toml-and-json)
  - [2.3. Simple usage of toml](#23-simple-usage-of-toml)
    - [2.3.1. Table arrays](#231-table-arrays)
    - [2.3.2. Strings](#232-strings)
    - [2.3.3. Integers](#233-integers)
    - [2.3.4. Floating point numbers](#234-floating-point-numbers)
    - [2.3.5. Boolean](#235-boolean)
    - [2.3.6. rfc3339](#236-rfc3339)
    - [2.3.7. Arrays](#237-arrays)
    - [2.3.8. Standard tables](#238-standard-tables)
    - [2.3.9. Inline tables](#239-inline-tables)
- [3. Writable configuration](#3-writable-configuration)
  - [3.1. Explanation of concepts](#31-explanation-of-concepts)

---

When 2moe originally wrote this chapter, it was intended for edition 2022.  
In fact, some of the content has already been backported to edition 2021.

In subsequent releases, toml will appear more frequently for user-oriented configurations.

---

In tmoe, there are two kinds of configuration files.  
One is read-only and the other is writable.

| read-only                                                       | read-writeable                   |
| --------------------------------------------------------------- | -------------------------------- |
| Generally package release information or data index information | True program configuration files |

## 1. Read-only configuration

### 1.1. The concept of read-only configuration

The "container property information" is read-only configuration.  
The read-only configuration referred to here is not "read only" in terms of file permissions, but is logically read-only.  
In fact, you can modify the contents of the file directly, you just shouldn't do it manually.  
As an example.  
Say you see the version: "1.57.0".  
You think : "That's a very low version number! Let's change it to 114514.999.9!"  
So, you happily change its properties.  
From a subjective point of view: you've had fun. That's great! Because happiness is a positive attitude to life.  
From an objective point of view: you have fixed the problem of the low version number. That's good too!  
From the original developer's point of view: Dear me, what the xxx (ó﹏ò.)

Note: The above changes will not take effect.  
For read-only configurations, if the changes do take effect, then the container may have problems during installation or use.  
I am sure you can find out why in the next subsection.

### 1.2. Analysing read-only configurations

This section analyses the "container property information" that appears in [Section 2 (Hello rust)](#2-Hello-rust) of this chapter.

The read-only configuration of the output of the weekly build container of tmoe is as follows.  
(subject to change afterwards)

```toml
[main]
name = "rust"
tag = ["nightly", "unstable"]
os = "debian"
release = "sid"
arch = "arm64"
syntax_version = "0.0.1"

[file]
name = "rust-nightly-arm64_2021-09-17_20-39.tar.zst"

# This value can be used to verify the integrity of the file
# For example, suppose there are two files with the same name, both called a.tar.zst and the same size, but in different directories: A/a.tar.zst, B/a.tar.zst
# You may not be able to tell directly if they are the same file
# At this point you can check if they are the same file by comparing their sha256 values, if the sha256 is the same, the files are the same, otherwise they are different.
# Note: Hash collisions etc. are ignored here.
sha256 = "acc668db456e94053322f7049469995ba20e9fe6dcb297367226dca4553b633e"

# [1-22]
zstd-level = 19

[file.size]
# Installed size ≈ tar-size
# Installed size is approximately equal to the size of the tar file
# The tar size is the size of the container image after packaging, the unpacked space may be slightly larger than the tar itself
# The exact size is related to file clusters, which in turn are related to the file system.
tar = "1.6G"
tar-bytes = 1717986919

# Space occupied ≈ tar-size + zstd-size
# You will need to prepare a large enough space before installation.
# Download size: zstd-size
# After the tar is packed, the image is also compressed.
# The size of the file you need to download is the size of zstd, the tar.zst file to be exact
# Before installing a container, you need to consider reserving some space for.
# 1. the size of the zip file, 2. the size of the zip after decompression, 3. the initialisation process of the container also takes up a little space.
zstd = "216M"
zstd-bytes = 226492416

# For edition 2022, the user only needs to look at the version number to know the order of the mirrors, and to know which is newer and which is older.
# It occurred to the developer that there is a feature in tmoe that automatically determines the time order, even if it is an older version.
# Actually time is for developers to see, ordinary users don't need to know how much time the server has spent on a certain process in the build process.
# If you are interested, then I can explain the process.
# 1. once the server has built the image, it needs to package and compress it.
# 2. the zstd below should be exactly "start-zstd", i.e. the point at which zstd compression starts, not the point at which I compressed a file that took dozens of hours!
# 3. After the compression is complete, the file needs to be transferred to another node.
# 3-1. For tmoe's weekly build, instead of all nodes building from scratch, one of the nodes completes the build and then syncs the relevant files to another node.
[time]
format = "rfc-3339"
zone = "UTC"
begin = 2021-09-17T20:08:33.801113258Z
start-zstd = 20:14:20
start-sync_0 = 20:39:22
start-sync_1 = 20:41:33
end = 2021-09-17T20:44:32.392018144Z

[server]
name = "tmoe-us"
node = 2
# available = [1, 2, 3, 4]

# Environment variables  (●＞ω＜●)
[env]
LANG = "en_US.UTF-8"
PATH = "/usr/local/cargo/bin${PATH:+:${PATH}}"
RUSTUP_HOME = "/usr/local/rustup"
CARGO_HOME = "/usr/local/cargo"

[version]
rustup = 'rustup 1.24.3 (ce5817a94 2021-05-31)'
cargo = 'cargo 1.56.0-nightly (e515c3277 2021-09-08)'
rustc = 'rustc 1.57.0-nightly (e4828d5b7 2021-09-16)'
```

**toml** is an excellent format for configuration files.  
Next, we will introduce the concept of **toml** and its common usage.  
Finally, we will take a brief look at the concept and usage of "writable configuration".

## 2. toml

### 2.1. What is toml

> Tom's Obvious, Minimal Language.  
> TOML aims to be a minimal configuration file format that's easy to read due to obvious semantics.  
> TOML is designed to map unambiguously to a hash table.  
> TOML should be easy to parse into data structures in a wide variety of languages.

The above description is taken from toml's [official website](https://toml.io), where you can find some detailed instructions.

### 2.2. toml and json

When talking about **toml**, many people refer to **json**  
Why not use **json**? Does it have any advantages over **json**?

The 2nd issue of toml-lang/toml on github is related to this topic.

> ["No, JSON doesn't count. You know why."](https://github.com/toml-lang/toml/issues/2)

But I don't know why too.  
So why exactly?

### 2.3. Simple usage of toml

The content of this section will provide the basis for [(#3.3-Writable configuration)](#33-writable-configuration).  
In the configuration of the toml container, the following points may be covered.

- strings
- integers
- floating point numbers
- Boolean
- rfc3339
- Arrays
- Standard Tables
- Inline Tables

These are actually common value types in **toml** itself.

A rarely covered point of knowledge is :

- Table arrays

#### 2.3.1. Table arrays

Table arrays are nice to use, ~~but the developers of tmoe (trying to be lazy)~~.

In fact, table arrays are a little bit more complicated to parse.  
As a simple example.

```toml
[[bin]]
name = "tmm"

[[bin]]
name = "value"

[[bin]]
name = "tmoe"
```

It's easy to delete all the `[[bin]]` or to append and write a new `[[bin]]`.  
But to modify the data containing the specified `value`, you have to do a bit more processing.

#### 2.3.2. Strings

Strings are probably the most common type in the configuration file of the tmoe container.

For example

```toml
str = "value"
```

The string type in toml can be either double-quoted or single-quoted.  
This is different from rust, where if you use single quotes and do not specify the type, then the compiler will infer by default that the value is of type char (a single character).

```rust
let c = 'c';
```

Back to toml, if you need to enter more than one inverted comma, then write it like this!

```toml
str = """I have '''''5 single quotes, and two ""double quotes""""
```

There are three inverted commas before and after.

#### 2.3.3. Integers

For integers, there is no need for inverted commas!  
As an example for strings.

```toml
int1 = "233"
```

In the above equation, the value of int will be recognised as a string, not as an integer.  
Another integer example.

```toml
int2 = 233
```

As an example of a negative integer.

```toml
int3 = -233
```

The range of integers that toml can accept is i64 (from -2^63 to 2^63-1).  
As with rust, for particularly large numbers you can use **\_** to enhance readability.

```toml
int4 = 114_514_233
```

The above equation is equivalent to the following one

```toml
int4 = 114514233
```

An example of a binary, octal and hexadecimal integer:

```toml
# 0b11011111101010010 in binary equals 114514 in decimal
bin = 0b11011111101010010
# Values starting with 0o are octal numbers, guess which number this is
oct1 = 0o337522
# Values starting with 0x are in hexadecimal
hex1 = 0x1BF52
```

#### 2.3.4. Floating point numbers

You can't put inverted commas around floating point numbers either!

Here are some examples in decimal and exponential form!

```toml
f1 = 3.14159265
f2 = -3.14159265
f3 = 314e-2
f4 = 0.1145e+4
```

#### 2.3.5. Boolean

Boolean values have only two values: **true** and **false**.

true is true, false is false  
true ✓  
false X

```toml
bool = true
bool2 = false
```

#### 2.3.6. rfc3339

rfc3339 is a time format.

```toml
# You can write just the time
time1 = 01:25:57
time2 = 01:25:00.247810421

# You can also write just the date
date1 = 2021-09-29

# You can also write both
time3 = 2021-09-29T01:25:57Z

# You can split the one above
time4 = 2021-09-29 01:25:57Z
# The Z at the end is UTC, you can replace it with +00:00

# UTC+08:00
time5 = 2021-09-29 01:29:13.598811802+08:00
```

#### 2.3.7. Arrays

```toml
# You can write in a new line
array1 = [233,
22,
33]
# You can also write it without a line break
array2 = [ "hello", "world" ]
```

#### 2.3.8. Standard tables

A standard table is also known as a hash table.

Take an example from Cargo

```toml
[dependencies]
nom = "7.0.0"
```

You can write the above table in the following format

```toml
[dependencies.nom]
version = "7.0.0"
```

#### 2.3.9. Inline tables

Inline tables can write multiple rows into a single row.

Let's start with an example of a standard table

```toml
[dependencies.tokio]
version = "1.11.0"
features = ["macros", "tcp", "dns", "io-util"]
```

Another example of an inline table

```toml
[dependencies]
tokio = { version = "1.11.0", features = ["macros", "tcp", "dns", "io-util"] }
```

## 3. Writable configuration

### 3.1. Explanation of concepts

This part hasn't even been written yet!
