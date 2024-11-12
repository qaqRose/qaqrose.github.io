---
title:  安装 docker 环境
layout: info
commentable: true
date: 2024-03-24
mathjax: true
mermaid: true
tags: [ Docker ]
categories:  运维
description: 
---

云计算如日中间，容器化也十分火热，这些可能离我们日常比较遥远

但是使用容器化还是能够给我们的开发工作带来非常大的便利，只需要一分钟就可以在本地开启一个或多个MySQL实例或Redis实例，或者当我们想要去验证某个功能时，都以非常快速搭建一个基础环境

而这些都因为我们站在了巨人的肩膀上

本篇简单记录下 Docker 在 Linux 版本上的安装过程

## 安装方式

###  使用便利脚本安装（推荐）

```sh
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```
该命令从 `get.docker.com` 下载一个 linux 快速安装 docker 的脚本
这个脚本需要是 `root` 用户或者 `sudo`权限执行，会自动根据 Linux 发行版和版本来自动安装对应的 Docker Engine 、Docker Compose 和其他一些组件

支持一些参数
```
--version <VERSION>
```
可以指定一个特定的版本，例如
```
curl -fsSL https://get.docker.com | bash --version 23.0
```
指定通道
```
--channel <stable|test>
```
可以下载 stable 稳定版或着 test 测试版本

使用不同的镜像
```
--mirror <Aliyun|AzureChinaCloud>
```
Aliyun 阿里云镜像
AzureChinaCloud  微软镜像

比较推荐使用这种方式，方便快速，不用关心linux的版本，依赖等问题

### apt 方式

这里使用 Ubuntu 22.04的环境来演示，这是 Ubuntu 一个长期支持的版本

查看版本
```
ubuntu@vm1:~$ lsb_release --all
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.4 LTS
Release:	22.04
Codename:	jammy
```
在 Ubuntu 下，一般都是使用 apt-get 来安装软件

先设置一下 Docker 仓库到 apt 源

```sh
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

安装最新版本的 Docker

```sh
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```



### 离线安装

在一些情况，无法使用在线安装时，可以使用离线方式安装

首先查看系统的版本

```sh
root@vm2:~# lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.4 LTS
Release:	22.04
Codename:	jammy
```
可以看到是 Ubuntu 发行版，代号是 jammy


从 [ubuntu-download](https://download.docker.com/linux/ubuntu/dists/) 点击进入下载页，其他 Linux 发行版点击[Linux-download](https://download.docker.com/linux/)

![image-20240324154359573](/images/2024-03/docker-install/image-20240324154359573.png)

选择ubuntu的版本 jammy （其他）

然后选择 pool/stable

![image-20240324154250533](/images/2024-03/docker-install/image-20240324154250533.png)

看看系统架构
```
root@vm2:~# uname -a
Linux vm2 5.15.0-101-generic #111-Ubuntu SMP Wed Mar 6 18:01:01 UTC 2024 aarch64 aarch64 aarch64 GNU/Linux

root@vm2:~# dpkg --print-architecture
arm64
```
aarch64是 ARM64 架构的一种变体

所以选择 arm64

然后下载如下安装包
```
1. containerd.io_<version>_<arch>.deb
2. docker-ce_<version>_<arch>.deb
3. docker-ce-cli_<version>_<arch>.deb
4. docker-buildx-plugin_<version>_<arch>.deb
5. docker-compose-plugin_<version>_<arch>.deb
```

如图

![image-20240324155504680](/images/2024-03/docker-install/image-20240324155504680.png)

命令行安装
```
sudo dpkg -i ./containerd.io_1.6.28-2_arm64.deb \
  ./docker-ce_26.0.0-1~ubuntu.22.04~jammy_arm64.deb \
  ./docker-ce-cli_26.0.0-1~ubuntu.22.04~jammy_arm64.deb \
  ./docker-buildx-plugin_0.13.1-1~ubuntu.22.04~jammy_arm64.deb \
  ./docker-compose-plugin_2.6.0~ubuntu-jammy_arm64.deb
```

docker 守护程序会自动启动

## 验证

### hello world

hello world是用来验证 docker 是否正常运行的一个镜像(image) 

运行如下命令
```
docker run hello-world
```
如果有打印 `Hello from Docker!` 信息并退出

说明docker正常运行


## 卸载 docker 



卸载安装包

```sh
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
```

删除镜像、容器、挂载卷等数据

```sh
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```



## 使用MySQL容器

安装完 Docker 环境之后，我们以安装一个 MySQL8.0作为实战，简单使用一下

编写docker-compose.yml

```yml
version: '3.8'

services:
  mysql:
    image: mysql:8
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: 123456
    ports:
      - "23306:3306"
    volumes:
      - /data/mysql/data:/var/lib/mysql
      - /data/mysql/config:/etc/mysql/conf.d
```

以上将拉取 MySQL8 的镜像

在本地启动一个MySQL容器设置密码为`123456`, 

映射本地端口23306到容器的3306端口

并挂载了两个目录

需要创建两个文件夹用于挂载数据和配置

```
mkdir -p /data/mysql/data
mkdir -p /data/mysql/config
```

启动

```
docker compose up -d
```

查看运行实例

![image-20240324170820647](/images/2024-03/docker-install/image-20240324170820647.png)

使用客户端连接

![image-20240324163628180](/images/2024-03/docker-install/image-20240324163628180.png)



## 配置镜像仓库

直接从中央仓库拉取镜像有时候很慢

可以通过配置国内的镜像仓库来加快速度

### 阿里云仓库

登录阿里云账号，进入[容器镜像服务](https://cr.console.aliyun.com/cn-shenzhen/instances/mirrors)

复制自己的加速器地址

例如
```
https://xxxx.mirror.aliyuncs.com
```
执行下面语句（ubuntu 系统）
```zsh
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://xxxx.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```





## 参考

1. [docker-install](https://github.com/docker/docker-install)

2. [ubuntu-docker-install](https://docs.docker.com/engine/install/ubuntu/)
