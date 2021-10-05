# 1. Contents

[Home](../../../Readme.md)

## 1.1. main

| Chapter                                                    | Introduction                                                    | Documents |
| ---------------------------------------------------------- | --------------------------------------------------------------- | --------- |
| [Prologue.part A](../../../Readme.md)                      | \*                                                              | lite.md   |
| Prologue.part B: Facing History, Venturing into the Future | Compare the different editions and extend the previous section. | readme.md |
| [Chapter 1](./1.md)                                        | \*                                                              | 1.md      |
| [Chapter 2](./2.md)                                        | \*                                                              | 2.md      |
| [Chapter 3](./3.md)                                        | \*                                                              | 3.md      |

## 1.2. current

English | [Chinese](../中文/readme.md)

- [1. Contents](#1-contents)
  - [1.1. main](#11-main)
  - [1.2. current](#12-current)
- [2. Editons](#2-editons)
  - [2.1. 2019](#21-2019)
  - [2.2. 2020](#22-2020)
  - [2.3. 2021](#23-2021)
  - [2.4. 2022 (unreleased)](#24-2022-unreleased)
  - [2.5. Comparison of details](#25-comparison-of-details)
    - [2.5.1. note 1](#251-note-1)
    - [2.5.2. note 2](#252-note-2)
  - [2.6. future](#26-future)
- [3. Installation](#3-installation)
  - [3.1. How to install](#31-how-to-install)
  - [3.2. Dependencies](#32-dependencies)
  - [3.3. Older dependencies](#33-older-dependencies)
    - [3.3.1. curl](#331-curl)
  - [3.4. Compile and install](#34-compile-and-install)
- [4. Turn the page](#4-turn-the-page)

# 2. Editons

We may not distinguish between versions and editions.

## 2.1. 2019

The edition no one uses.

| edition | lifecycle         |
| ------- | ----------------- |
| 2019    | before 2020-03-22 |

| What it does                | Commands |
| --------------------------- | -------- |
| Start the default container | debian   |
| Start tmoe tools/manager    | debian-i |

In edition 2022, they are now optional (not required) commands.

## 2.2. 2020

| edition | lifecycle                     |
| ------- | ----------------------------- |
| 2020    | late 2020-03 to early 2020-10 |

The developers have added a large number of new features to the project during this period, with some new features added almost every week.  
~~The developers have become a relentless feature-adding machine.~~  
Note: quite a few features have since been cut.

## 2.3. 2021

| edition | lifecycle                   |
| ------- | --------------------------- |
| 2021    | mid 2020-10 to ~~2022-01~~? |

compare 2020 & 2021

| edition | main work                              |
| ------- | -------------------------------------- |
| 2020    | enhances the ecology of the gnu/linux  |
| 2021    | enhances the ecology of the containers |

milestone

| milestone in 2021       | note                                             |
| ----------------------- | ------------------------------------------------ |
| **Weekly build images** | You can download the image with the built-in GUI |

The developers spent a lot of time, effort and money on maintenance.

| test                            | time         |
| ------------------------------- | ------------ |
| about 300 automated build tasks | half a month |

> Things you may not know.  
> The distro that most often goes wrong during automated builds is **fedora-rawhide**

## 2.4. 2022 (unreleased)

| feature                       | note                       |
| ----------------------------- | -------------------------- |
| Difficult to develop          | Takes a lot of time        |
| Incompatible with old edition | Edition migration required |
| Rewrite in rust               | Work in progress           |

## 2.5. Comparison of details

| Introduction                 | 2019-2020 | 2021                          | 2022                               |
| ---------------------------- | --------- | ----------------------------- | ---------------------------------- |
| The importance of config     | Low       | Medium [(note1)](#251-note-1) | Dominant [(note2)](#252-note-2)    |
| Exception handling mechanism | Very poor | Poor                          | Elaborate, see [Chapter 2](./2.md) |

### 2.5.1. note 1

In edition 2021, basically most of the important features can be modified via configuration files.  
For example `startvnc` and the base configuration of the container.  
The developers have worked on the details with the aim of making the configuration more intuitive and comprehensive.

### 2.5.2. note 2

Edition 2022 will extend the coverage of configuration files.  
From storing basic program configuration, to data indexing, to some special data content.

## 2.6. future

Often people compare tmoe with other projects and then berate the developers.  
This makes the developers sad.

At this stage, tmoe doesn't need to do better than anyone else, it just needs to do well for itself.  
The developers are already planning a new edition! I'm sure it will get better in the future.

> Things you may not know.  
> From February to September 2021, tmoe was much more popular in Germany than in the USA and China.

# 3. Installation

## 3.1. How to install

See [Prologue.part A](../../../Readme.md)

## 3.2. Dependencies

## 3.3. Older dependencies

For edition 2021 and earlier (hereinafter: older versions), look at **~/.local/share/tmoe-linux/MANAGER_DEPENDENCIES.txt** or **/usr/local/etc/tmoe-linux/TOOL_DEPENDENCIES. txt**.  
The txt file contains information about the dependencies required during the installation process.  
Some functions cannot be run without the relevant dependencies.  
As an example.  
If you want to run zsh, then install zsh.  
You want a plugin to run properly, so you install a dependency on a plugin.  
In the absence of an external dependency, there are two solutions: either implement it manually yourself or do not enable the relevant functionality.  
The old version did have a lot of dependencies and I would like to apologise to all tmoe users for that.

This is not the case in the 2022 edition.  
For example: `git`  
Developers can call `git2-rs` to manually implement a simple `git` client, which eliminates the need to install git.  
Of course, it is easier to just statically compile the original `git`.

### 3.3.1. curl

Editions 2021 and earlier require curl.  
The 2022 edition is not required.

## 3.4. Compile and install

Edition 2022+ only.  
You will have to wait a long time as the developers are still developing.

# 4. Turn the page

| chapter                       | introduction                                           | documentation |
| ----------------------------- | ------------------------------------------------------ | ------------- |
| [previous chapter](./lite.md) | Some short notes to get you started quickly            | lite.md       |
| [next chapter](./1.md)        | In conjunction with section 2 of this chapter, further | 1.md          |
