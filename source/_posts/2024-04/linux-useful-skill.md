---
title: Linux使用总结
layout: info
commentable: true
date: 2024-04-21
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



#### 本地复制 cp

用法 
```
Usage: cp [OPTION]... [-T] SOURCE DEST
  or:  cp [OPTION]... SOURCE... DIRECTORY
  or:  cp [OPTION]... -t DIRECTORY SOURCE...
Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.
```

一些参数

| 参数                 | 说明                                                         |
| -------------------- | ------------------------------------------------------------ |
| -a                   | 尽可能保留副本的属性和结构，递归复制，相当于 `-dR --preserve=all` |
| -d                   | 复制软链接为软链接，并保留硬链接，箱单于 `-P --preserve=links` |
| -debug                   | 输出复制过程的一些信息 |
| -i, --interactive    | 覆盖文件前询问（输入`Y`覆盖）                                |
| -l, --link           | 硬链接文件，不复制内容                                       |
| -n, --no-clobber     | 不覆盖一个存在的文件 ( 会被`-i`参数覆盖 )                    |
| -v, --verbose        | 显示复制过程                                                 |
| -P, --no-dereference | 复制软链接（符号链接）为软链接                               |
| --preserve=[ATTR]    | 配置保留执行的属性，例如`mode`, `timerstamps` 或直接 `all`   |
| -p                   | 保留权限、所有者、时间戳等信息， 相当于`--preserve=mode,ownership,timestamps` |
| -R, -r, --recursive  | 递归复制目录，复制目录时使用                                 |

例如

```zsh
## 递归复制source_dir目录到dest_dir
cp -R source_dir  dest_dir 

## 创建一个硬链接
cp -l dir/a.txt a1.txt

## 复制source_dir 比保留权限信息
cp --preserve=mode -R source_dir  dest_dir 
```



#### 远程复制 scp

`cp` 只能复制在同一台主机上的文件或目录，需要复制远程主机的文件或目录，需要使用`scp`

`scp` 叫做`OpenSSH secure file copy`,  通过ssh来传输数据

命令

```zsh
scp [-346ABCOpqRrsTv] [-c cipher] [-D sftp_server_path] [-F ssh_config] [-i identity_file] [-J destination] [-l limit] [-o ssh_option] [-P port]
         [-S program] source ... target
```



参数

| 参数 | 说明                                       |
| ---- | ------------------------------------------ |
| -C   | 开启压缩                                   |
| -l   | 限制传输带宽，单位 Kb/s                    |
| -P   | 指定链接的端口，否认为22 （ssh的默认端口） |
| -p   | 保留源文件的修改时间，访问时间、权限位     |
| -s   | 使用sftp协议                               |
| -r   | 递归复制目录                               |
| -v   | 详细模式，打印复制过程的内容               |



```zsh
## 递归复制server1主机上/home/reader/source_dir到当前目录 (使用reader用户)
scp -r reader@server1:/home/reader/source_dir .


## 通过22222端口链接主机并复制文件目录
scp -r -P '22222' root@server1:/root/dir .


## 打印复制过程
scp -v  root@server1:/root/dir/file .
```



### grep 文本匹配

命令

```
grep [OPTION...] PATTERNS [FILE...]
```

参数



| 参数                            | 描述                                                         |
| ------------------------------- | ------------------------------------------------------------ |
| -V                              | 输出grep版本并退出                                           |
| -F                              | 固定字符串匹配模式                                           |
| -G                              | 基础正则表达式模式，默认就是这种模式                         |
| -i, --ignore-case               | 忽略大小写                                                   |
| -v, --invert-match              | 反向匹配，选择不匹配的行                                     |
| -c, --count                     | 不输出匹配结果，只输出匹配的数量                             |
| -l, --files-with-matches        | 不输出匹配结果，只输出匹配上内容的文件名                     |
| -L, --files-without-match       | 不输出匹配结果，只输出未匹配上内容的文件名                   |
| -H, --with-filename             | 每行匹配的内容增加文件名,   当有多个文件时，默认输出         |
| -h, --no-filename               | 不是输出文件名， 当只有一个文件时                            |
| -n, --line-number               | 每行输出匹配的内容增加行数                                   |
| -A NUM, --after-context=NUM     | 打印匹配行后NUM行的内容                                      |
| -B NUM, --before-context=NUM    | 打印匹配行前NUM行的内容                                      |
| -C NUM, -NUM, --context=NUM     | 打印匹配行前后NUM行的内容                                    |
| -d ACTION, --directories=ACTION | 匹配目录，ACTION有`read` 像文件一样读，`skip` 跳过文件夹，`recurse` 递归读取，相当于`-r` |
| -r, --recursive                 | 递归匹配文件夹下的所有文件                                   |

例如

```zsh
## 管道匹配，输出hello字符串的个数
echo "hello world" | grep -n "hello"

## 递归匹配_posts目录下所有文件，忽略大小写
grep -ri "controller"  _posts

## 搜索"10:32"这一分钟内pool-12-thread-1线程的所有日志，匹配"biz func"并输出后10行的日志
grep "2024-04-21 10:32.*?pool-12-thread-1" info.log ｜ grep "biz func" -A 10
```



### head / tail / less / more文件操作

文本文件查看

#### head 

输出文件的头部内容

例如:

输出`info.log`文件的前10行内容

```zsh
head -n 10 info.log
```



#### tail

输出文件的尾部内容

例如

输出`info.log`文件的后10行内容

```zsh
tail -n 10 info.log
```

监听`info.log`后续添加的内容

```
## 一开始打印后10行数内容，然后不断输出新增的内容到控制台
tail -f -n 10 info.log
```



### find / locate 文件查找



#### find

从文件目录中查询文件

表达式

```
find [-H] [-L] [-P] [-D debugopts] [-Olevel] [starting-point...] [expression]
```

一些参数

```
-name 名称匹配，支持*通配符
```

过滤类型

```
-type 
	b  缓存块
	c  字符串
	d  目录
	p  命名管道(FIFO)
	f  普通文件
	l  软链接
	s  套接字socket
```

大小过滤

```
-size [cwbkMG]
b 512字节块
w 2字节
k kb
M 兆字节Mb
G Gb
使用 +（加号） -（减号） 大于或小于

例如
-size +10M 表示过滤大大于10M的文件
```

动作

```
-fls [file]  将内容输出到文件
-fprint file   将内容输出到文件
-ls 		  以`ls -dils`输出到控制台
```



例如 

```
## 搜索 /tmp目录下名字core的普通文件, 并删除
find /tmp -name core -type f -print | xargs /bin/rm -f

## 搜索权限位是664的文件
find . -perm -664
```



### 文件操作



## 工具篇


## 软件篇