---
title: macOS 实用小技巧
layout: info
commentable: true
date: 2023-09-25
mathjax: true
mermaid: true
tags: [ MacOS ]
categories: 生活
description: 
---


## macOS

记录一些使用 macOS 的细节

方便新系统重新安装或者配置


## 软件

使用软件列表

|  软件   | 描述  | 链接 |
|  ----  | ----  |  ---- |
| iTerm2  | 非常好用macOS终端 | [官网](https://iterm2.com/) |
| uTools  | 效率工具平台，丰富的插件 | [官网](https://www.u.tools/) |
| Snipaste | 截图工具，截图+贴图 | [官网](https://www.snipaste.com/) |
| Tencent Lemon | 腾讯柠檬清理  | [官网](https://lemon.qq.com/) |
| Magnet   |  窗口分屏软件 | [官网](https://magnet.crowdcafe.com/) |
| ClashX   |  代理软件 | [Github地址](https://github.com/yichengchen/clashX) |

### iTerm2

比原生的终端更加好看，功能更加强大，支持超多的配置

可以定制化化程度非常高

有了 iTerm2 之后，我就没用过其他 ssh 连接工具了

直接多 tab 操作，非常丝滑

![多tab](/images//macos-useful/tab.png)

## 终端

### Homebrew
macOS 的软件管理工具

对 macOS 上的应用进行管理

官网 [中文](https://brew.sh/zh-cn/)


### Oh-MyZsh

[Github](https://github.com/ohmyzsh/ohmyzsh)地址

一个好看又好用的终端解释器，用上它之后就放弃掉 bash 了

#### 插件 

插件目录 `.oh-my-zsh/plugins`

开启插件

```sh
# 1. 编辑zsh配置 
vim ~/.zshrc

# 2. 开启插件plugins,注意换行
plugins=( 
    git       # 默认开启git插件
)

# 3.刷新
source ~/.zshrc
```

#### git 
默认开启了

里面预置了很多alias 和 方法，查看[Github](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)

一些好用的命令

| Alias   | Command  |
| ---- |   -----  |
|  glods  | git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short  |
| grba | git rebase --abort |
|  grhh | git reset --hard |
| gts | git tag -s |
| gl  | git pull |
| gfa | git fetch --all --prune |
| gdca | git diff --cached |
| gcb  | git checkout -b |
| gstp | git stash pop |
| gstaa | git stash apply |

#### zsh-autosuggestions
[下载安装说明](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#antigen)

记录你输过的命令，自动补全

需要手动下载和开启

Oh-My-Zsh
```zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

#### zsh-syntax-highlighting

[下载安装说明](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md)

语法高亮，正确命令绿色，错误命令红色

需要手动下载和开启

#### z

[Github](https://github.com/agkozak/zsh-z)

可以快速跳转到最近打开的目录

默认已下载，需要手动开启

[更多插件](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins)

## 配置










