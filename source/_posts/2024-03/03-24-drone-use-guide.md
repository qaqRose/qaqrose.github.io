---
title: 使用drone自动部署项目
layout: info
commentable: true
date: 2024-03-24
mathjax: true
mermaid: true
tags: [ CI ]
categories:  运维
description: 
---


现代开发项目无论是前端还是后端都离不开 CI （持续构建）工具，不仅可以解放生产，提高生产力，也非常方便管理，同类型的项目只需要编写构建规则，后续都可以复用

相信很多人使用的第一款 CI 工具应该都是 Jenkins ，Jenkins 非常强大，提供了用户权限和很多插件，可以非常灵活满足企业的需求

但是针对个人开发者或者小团队，可能并不需要那么复杂的功能，那么 Drone 可能是个更好的选择，无论是占用资源还是使用方式都非常的轻便，能够很容易上手

我们通过演示如何自动构建一个前端 vue 项目和后端 SpringBoot 项目来学习如何使用 Drone


## 安装Drone

首先需要准备 Docker 环境

可参考

准备好Docker后，我们需要安装 Drone Server
Drone Server 是一个独立的守护进程，它轮询服务器以获取待执行的 Pipeline

Drone 脚本一般需要与某个代码仓库平台集成并完成OAuth配置，之后才能够拉取项目代码

### 与Github集成

这里我们与Github集成

需要在[github-setting](https://github.com/settings/developers) 新增一个 OAuth App

![image-20240324221648745](/image/03-24-drone-use-guide/image-20240324221648745.png)

这里的`192.168.64.2`是本地虚拟机的 ip

如果有云服务器，可以替换成云服务器的公网 ip 地址

注意回调url的路径是`/login` 

![image-20240324212126843](/image/03-24-drone-use-guide/image-20240324212126843.png)

这个`Client ID`和`Client secret`需要在下面使用 （密钥需要手动点击生成）


生成一个密钥来验证`Drone Server`和`Runner`之间的 RPC 通信

```sh
> openssl rand -hex 16
19e111caff5871dceba3440a17cba196
```

### 启动Drone Server

使用如下的命令启动
```sh
docker run \
  --volume=/var/lib/drone:/data \
  --env=DRONE_GITHUB_CLIENT_ID=23d9347147e27b327c7c \
  --env=DRONE_GITHUB_CLIENT_SECRET=b04520f2d429cfc641264c0f96198834e7fb8afc \
  --env=DRONE_RPC_SECRET=19e111caff5871dceba3440a17cba196 \
  --env=DRONE_SERVER_HOST=192.168.64.2 \
  --env=DRONE_SERVER_PROTO=http \
  --env=DRONE_USER_CREATE=username:qaqRose,admin:true \
  --publish=80:80 \
  --publish=443:443 \
  --restart=always \
  --detach=true \
  --name=drone \
  drone/drone:2
```
挂载`/var/lib/drone:/data`， 这样容器重启之后数据不会丢失

环境参数说明

DRONE_GITHUB_CLIENT_ID是github oauth app的`Client ID`

DRONE_GITHUB_CLIENT_SECRET是github oauth app的`Client secret`

DRONE_RPC_SECRET 是 RPC通信的密钥，前面手动生成

DRONE_SERVER_HOST 是 drone服务的域名

DRONE_USER_CREATE可以指定github账号为admin，admin账号拥有最高的权限


### 启动Runner
有多种方式可以启动Runner
这里通过docker方式启动
```sh
docker run --detach \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --env=DRONE_RPC_PROTO=http \
  --env=DRONE_RPC_HOST=192.168.64.2 \
  --env=DRONE_RPC_SECRET=19e111caff5871dceba3440a17cba196 \
  --env=DRONE_RUNNER_CAPACITY=2 \
  --env=DRONE_RUNNER_NAME=my-first-runner \
  --publish=3000:3000 \
  --restart=always \
  --name=runner \
  drone/drone-runner-docker:1
```
解释参数的作用
这里挂载`/var/run/docker.sock`到 Runner容器的`/var/run/docker.sock`
让Runner可以操作外部的docker容器

DRONE_RPC_HOST 让Runner连接指定主机Server

### 登录Server后台

Drone Server和Runner都启动之后，查看

![image-20240324222353884](/image/03-24-drone-use-guide/image-20240324222353884.png)

通过`http://192.168.64.2:80`访问到Drone Server的后台

![image-20240324222646815](/image/03-24-drone-use-guide/image-20240324222646815.png)

点击 CONTINUE，跳转到Github授权登录

然后会跳转到注册页面，不用管，直接 SUBMIT 即可

![image-20240326001456056](/image/03-24-drone-use-guide/image-20240326001456056.png)

进入主页面

左下侧边栏可以配置新增用户，但是需要`admin`权限

![image-20240326001323732](/image/03-24-drone-use-guide/image-20240326001323732.png)

到这里 Drone 搭建好，我们开始尝试部署前后端项目



## 构建前端 Vue 项目

我们在 Github 新建一个 [Vue 项目](https://github.com/qaqRose/drone-test-vue)

### 初始化项目

首先新建一个测试项目
```
# 安装 vue-cli
sudo npm install -g @vue/cli

# 新建一个vue项目
vue create drone-test-vue
```

### 编写 drone 流水线

在项目主目录下编写`.drone.yml`

```yml
kind: pipeline # 定义对象类型，还有secret和signature两种类型
type: docker # 定义流水线类型，还有kubernetes、exec、ssh等类型
name: drone-test-vue  

## 平台，系统与预设不一致的话会在build会一直pending
## 预设是 linux / amd64
platform:
  os: linux
  arch: arm64

## 克隆代码时，depth=1只获取最后一次提交，速度更快
clone:
  depth: 1

steps:
  - name: build # 流水线名称
    image: node:lts-alpine3.19
    commands:
      - npm config set registry https://registry.npmmirror.com
      - npm install
      - npm run build

  - name: build-docker
    image: plugins/docker
    volumes: # 将容器内目录挂载到宿主机，仓库需要开启Trusted设置
      - name: docker
        path: /var/run/docker.sock # 挂载宿主机的docker
    settings:
      context: /drone/src
    commands: # 定义在Docker容器中执行的shell命令
      # 后续执行需要开启 stop 跟 remove
      #- echo stop container
      #- docker stop `docker ps -a | grep drone-test-vue | awk '{print $1}'` 
      #- echo remove image
      #- docker rm -f `docker ps -a | grep drone-test-vue | awk '{print $1}'` 
      - echo build new images
      - docker build -t drone-test-vue .
      - echo run container
      - docker run -p 8080:80 --name drone-test-vue -d drone-test-vue

# 定义流水线挂载目录
volumes: 
  - name: docker
    host:
      path: /var/run/docker.sock
```
steps 将流水线执行过程分成多个步骤

默认第一个步骤是 clone， 会从代码仓库中获取代码， 配置`depth=1`可以提高拉取速度

第二步是自定义的`build`步骤，主要是配置了npm国内源，执行了npm命令打包前端项目

第三步也是自定义步骤`build-docker`， 需要挂载宿主机的docker进程文件，这样可以在容器内启动一个宿主机的docker容器，主要是容器生命周期的流程

### Dockerfile 

前端项目的docker构建脚本如下

```dockerfile 
FROM nginx:1.25.2

COPY ./dist /usr/share/nginx/html/dist
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### nginx 配置

nginx的配置文件如下

```lua
server {
  listen 80;
  root  /usr/share/nginx/html/dist;

  location ~ .*\.(js|css)?$ {
    expires 7d;
    access_log off;
  }
  location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|mp4|ico)$ {
    expires 30d;
    access_log off;
  }
  location / {
    root   /usr/share/nginx/html/dist;
    index  index.html index.htm;
    try_files $uri $uri/ /index.html;
  }
  error_page   500 502 503 504  /50x.html;

  location = /50x.html {
    root   /usr/share/nginx/html;
  }
}
```

### 构建流程

提交代码，到 Drone 执行构建

![image-20240407112821596](/image/03-24-drone-use-guide/image-20240407112821596.png)

激活仓库

![image-20240407112859345](/image/03-24-drone-use-guide/image-20240407112859345.png)

由于我们挂载宿主机的docker，所以需要激活特权容器

![image-20240407113203076](/image/03-24-drone-use-guide/image-20240407113203076.png)

然后点击构建，等待容器构建

![image-20240404205332971](/image/03-24-drone-use-guide/image-20240404205332971.png)

构建页面

![image-20240407113435820](/image/03-24-drone-use-guide/image-20240407113435820.png)

等待构建完成，第一次一般久一点

![image-20240407124127127](/image/03-24-drone-use-guide/image-20240407124127127.png)

构建成功，访问页面，可以看到

![image-20240404205231508](/image/03-24-drone-use-guide/image-20240404205231508.png)


## 构建后端 SpringBoot 项目

新建一个[SpringBoot项目](https://github.com/qaqRose/drone-test-springboot)

### 新建项目

在`start.spring.io`新建一个springboot项目，然后导入到本地

增加一个简单的接口，方便测试

```java
@RestController
@SpringBootApplication
public class SpringbootDroneTestApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringbootDroneTestApplication.class, args);
    }
    @GetMapping
    public String hello() {
        return "hello drone";
    }
}
```

### 编写 dockerfile

增加Dockerfile
```docerfile 
FROM arm64v8/openjdk:17-ea-16-jdk

WORKDIR /app

COPY ./target/springboot-drone-test-0.0.1-SNAPSHOT.jar /app/app.jar

ENTRYPOINT ["java","-jar","app.jar"]
```
这里的jdk17版本适用的是arm64的架构


### 编写 drone 流水线

增加`.drone.yml`

```yml
kind: pipeline # 定义对象类型，还有secret和signature两种类型
type: docker # 定义流水线类型，还有kubernetes、exec、ssh等类型
name: drone-test-springboot

## 执行系统平台，不然在build会一直pending
## 预设是 linux / amd64
platform:
  os: linux
  arch: arm64

## 自定义clone流程，这里手动关闭掉
clone:
  disable: true
  #depth: 1

steps:
  - name: my-clone
    image: drone/git
    commands:
      ## 使用http1 (不知道为什么一直报错)
      - git config --global http.version HTTP/1.1
      - git clone https://github.com/qaqRose/drone-test-springboot.git --depth=1 .

  - name: build # 流水线名称
    image: maven:3.8.5-openjdk-17
    volumes:
      - name: maven-repository
        path: /root/.m2   # 将maven下载依赖的目录挂载出来，复用jar和修改配置
    commands:
      - mvn clean package -DskipTests=true

  - name: build-docker
    image: plugins/docker
    volumes: # 将容器内目录挂载到宿主机，仓库需要开启Trusted设置
      - name: docker
        path: /var/run/docker.sock # 挂载宿主机的docker
    settings:
      context: /drone/src
    commands: # 定义在Docker容器中执行的shell命令
      # 第一次执行注释 stop 跟 remove
      # - echo stop container
      # - docker stop `docker ps -a | grep drone-test-springboot | awk '{print $1}'`
      # - echo remove image
      # - docker rm -f `docker ps -a | grep drone-test-springboot | awk '{print $1}'`
      - echo build new images
      - docker build -t drone-test-springboot .
      - echo run container
      - docker run -p 8080:8080 --name drone-test-springboot -d drone-test-springboot

# 定义流水线挂载目录
volumes:
  - name: docker
    host:
      path: /var/run/docker.sock
  - name: maven-repository
    host:
      path: /data/.m2
```
相比前端项目的流水线，这里第一个步骤没有采用通用的`clone`
而是自定义了一个`my-clone`的克隆源代码的步骤
这样可以自定义一些clone的配置

然后就是编译、打包、管理docker生命周期，跟前端项目大同小异

### maven 配置

使用maven中央仓库会比较慢，有些包也拉不到

我们可以配置一下阿里的maven镜像仓库

挂载仓库目录也可以提高后续的编译速度

在`/data/.m2` 创建一个 `repository`文件夹  和 一个`settings.xml`文件

```zsh
mkdir -p /data/.m2/repository
vim /data/.m2/settings.xml
```
maven仓库配置如下
```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                          https://maven.apache.org/xsd/settings-1.0.0.xsd">

    <localRepository>/.m2/repository</localRepository>
    <mirrors>
        <!-- 阿里云仓库 -->
        <mirror>
            <id>z_alimaven</id>
            <mirrorOf>*</mirrorOf>
            <name>aliyun maven</name>
            <url>http://maven.aliyun.com/nexus/content/repositories/central/</url>
        </mirror>
    </mirrors>
</settings>
```

### 构建流程

在drone 点击构建

![image-20240407163923006](/image/03-24-drone-use-guide/image-20240407163923006.png)

构建完成，测试一下是否可以访问接口

![image-20240407164028818](/image/03-24-drone-use-guide/image-20240407164028818.png)

可以正常访问

## 问题处理


### 访问github失败

这里我是使用 multipass 开的 Ubuntu 22.04 虚拟机
在虚拟机里面出现了无法访问 github.com 的情况

最后通过增加dns解析解决
执行命令

```
vim /etc/systemd/resolved.conf.d/dns_servers.conf
```
写入一下内容
```
[Resolve]
DNS=8.8.8.8 1.1.1.1
```

### 服务器行为不当

![image-20240407112516197](/image/03-24-drone-use-guide/image-20240407112516197.png)

同样也是访问github失败，在docker容器的 `/etc/resolv.conf`

```
nameserver 192.168.64.1
search .

# Based on host file: '/run/systemd/resolve/resolv.conf' (legacy)
```

将`192.168.64.1`修改成`8.8.8.8` 即可

### Clone仓库失败

克隆github仓库失败，出现`Could not resolve host: github.com`

![image-20240407113938359](/image/03-24-drone-use-guide/image-20240407113938359.png)

在Ubuntu系统中， 修改`/etc/resolv.conf`之后还是会复原，需要使用netplan工具来配置网络

例如`vim /etc/netplan/50-cloud-init.yaml`

```yaml
network:
    ethernets:
        enp0s1:
            dhcp4: true
            match:
                macaddress: 52:54:00:89:d6:83
            set-name: enp0s1
            nameservers:
                addresses:
                - "8.8.8.8"
    version: 2
```

添加

```yaml
nameservers:
  addresses:
  - "8.8.8.8"
```

然后执行来使DNS生效

```zsh
netplan apply
```

### 在build的时候一直 pending

点击构建之后，一直在pendind
通过

```
docker logs <container_id>
```
也看不到什么错误日志

最后发现是platform的问题

调整一下即可

```
platform:
  os: linux
  arch: arm64
```
os应该都是linux
arch 可以通过`uname -a` 查看

![image-20240325235508153](/image/03-24-drone-use-guide/image-20240325235508153.png)

这里是`aarch64` 是 `arm64`

如果是 `amd64`或者其他，需要重新配置



## 参考
1. [drone-sever-github](https://drone.cool/server/provider/github/)
1. [drone-clone](https://docs.drone.io/pipeline/docker/syntax/cloning/)
1. [如何排查网络故障 |多通道文档 (multipass.run)](https://multipass.run/docs/troubleshoot-networking#heading--dns-problems)
1. [systemd-resolved - Arch Linux 中文维基 (archlinuxcn.org)](https://wiki.archlinuxcn.org/wiki/Systemd-resolved#DNS)
1. [成功解决git clone遇到的error: RPC failed； curl 16 Error in the HTTP2 framing layer fatal](https://blog.csdn.net/qq_45934285/article/details/131736984)
