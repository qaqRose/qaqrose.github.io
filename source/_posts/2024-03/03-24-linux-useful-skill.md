---
title: Linux使用总结
layout: info
commentable: true
date: 2024-03-24
mathjax: true
mermaid: true
tags: [ Linux ]
categories:  Linux
description: 
---

在日常的开发中，经过需要使用Linux的命令行来完成一些工作
但是每次都需要去搜索引擎或GPT搜索

所以这里主要是记录一些工作使用频率较高的命令或工具的用法

## 命令篇

### alias 别名

别名可以让我们更便捷使用一些常用的命令，提高使用效率

用法

```sh
alias [-p] [name[=value] ... ]
```
定义或展示系统别名，-p 参数可以打印可重用的 alias

例如 
```sh
alias ll="ls -alh"
```
使用ll可以以列表方式展示当前目录下的文件和目录，并以友好格式展示文件大小


这里一些方便好用的alias

展示服务器所有ip
```sh
alias ips="ifconfig -a | grep inet"
```
匹配文本着色
```sh
alias grep='grep --color'
alias egrep='grep -E --color=auto
alias fgrep='grep -F --color=auto 
```
启动一个http服务
```
alias http="python3 -m http.server 80"
```
node版本
```
# 安装http-server
sudo npm install -g http-server

alias http="http-server -p 80"
```

使用

![image-20240324181048329](/image/03-24-linux-useful-skill/image-20240324181048329.png)



### cp / scp 复制 / 远程复制



### top / htop 系统监控



### grep 文本匹配



### head / tail 文件操作



### find / locate 文件查找



### 文件操作



## 工具篇


## 软件篇