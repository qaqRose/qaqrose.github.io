---
title:  k8s 快速体验
layout: info
commentable: true
date: 2024-05-03
mathjax: true
mermaid: true
tags: [ K8s ]
categories: 运维
description: 
---

为了快速体验一下K8S，使用 `minikube` 在 linux 云服务器上搭建 `K8S` 集群

`minikube` 是一个本地化单节点的K8S，可以让我们更方便学习和开发 `K8S`， 我们这里采用`Docker` 作为它的容器环境

## 安装 minikube

需要先安装好docker环境，参考[docker环境安装](https://qaqrose.github.io/2024-03/03-24-install-docker-env/)

使用一下命令安装`minikube`
```zsh
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

完成之后
```zsh
# 查看版本
minikube version

# 输出如下说明成功
# minikube version: v1.33.0
# commit: 86fc9d54fca63f295d8737c8eacdbb7987e89c67
```

##  启动 minikube

启动命令
```zsh
minikube start \
--registry-mirror=https://registry.docker-cn.com \
--image-mirror-country=cn \
--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
--kubernetes-version=v1.23.3 \
--force \
--memory=1690mb \
--driver=docker
```
一些参数说明
`--registry-mirror`使用国内镜像仓库
`--image-mirror-country` 使用镜像的国家代码，国内使用 cn
`--image-repository` 使用国内的镜像仓库
`--kubernetes-version` 使用 K8S 的版本， 默认使用`stable`版本（目前是v1.30.0）
`--force` 强制让minikube允许一些危险的操作（避免各种问题起不起来, 例如使用root）
`--driver` 设置驱动为docker
`--memory` 表示内存的大小，如果服务器内存比较大，可以给多一点

启动之后查看状态

```zsh
minikube status
```

输出如下， 说明启动完成
```zsh
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

## 使用 kubectl 工具

K8S集群一般都是使用CLI工具来操作的，也就是 `kubectl`

可以让我们更加熟悉K8S的一些命令

### 别名方式（推荐）

`minikube` 已经自带了kubectl工具
我们可以通过
```zsh
alias kubectl="minikube kubectl --"
```
来获得使用原生工具一样的体验

tips：只对当前会话有效，可以通过写到`~/.bashrc`让所有会话都生效

```zsh
echo 'alias kubectl="minikube kubectl --"' >> ~/.bashrc
source ~/.bashrc
```

### 下载方式

通过以下命令安装
```
curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.23.3/bin/linux/amd64/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
```
这里的`v1.23.3`版本与上面的`kubernetes-version`对应

### 验证
```zsh
kubectl version --output=yaml
```
输出如下

![image-20240503123552234](/images/k8s-quick-start/image-20240503123552234.png)

## 控制台 Dashboard

minikube集成 `K8S` 的控制台 `Dashboard`

启动
```
minikube dashboard
```
通过以上命令启动一个dashboard来管理minikube集群

会得到一个类型的url
```
http://127.0.0.1:40417/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```
只能在宿主机上访问，想要在外网访问，需要开启代理
```
kubectl proxy --port=8080 --address='172.22.223.75' --accept-hosts='^.*' &
```
`--port`是代理的端口
`--address`是内网ip

如下，可以看到有一个`minikube`的节点

![image-20240503151530873](/images/k8s-quick-start/image-20240503151530873.png)



## 官网例子项目

使用官网的来测试一下

```zsh
kubectl create deployment hello-minikube --image=kicbase/echo-server:1.0
kubectl expose deployment hello-minikube --type=NodePort --port=8080
```
上面创建了一个deployment并将8080端口暴露出来

但是此时还是无妨访问
```zsh
kubectl port-forward --address 0.0.0.0 service/hello-minikube 31302:8080
```
我们通过端口转发，将service的端口暴露到本地，这样就可以在公网访问到

![image-20240503135148043](/images/k8s-quick-start/image-20240503135148043.png)

在dashboard看到有一个 `NodePort`类型的服务`hello-minikube`

![image-20240503151243111](/images/k8s-quick-start/image-20240503151243111.png)



## 部署Node后端项目

这里通过部署一个本地项目来演示一下

我们快速编写一个node后端项目

第一步安装环境
```zsh
sudo apt update
sudo apt install nodejs npm
```
第二步初始化项目
```zsh
## 初始化项目，使用默认值即可
npm init
## 配置镜像加速
npm config set registry https://registry.npmmirror.com
## 安装 express
npm install express
```
然后编写app.js
```js
const express = require('express')
const app = express()

app.all('*', (req, res) => {
   res.json({
    method: req.method,
    protocol: req.protocol,
    query: req.query,
  })
})

app.listen(3000, () => {
  console.log(`Example app listening on port 3000`)
})
```
编写package.json

```json
{
  "name": "backend",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "node app.js"
  },
  "author": "",
  "dependencies": {
    "express": "^4.19.2"
  }
}
```
编写Dockerfile
```Dockerfile
FROM node:20.11.1-alpine3.19
## copy package.json app.js 
COPY . /app
WORKDIR /app
RUN npm config set registry https://registry.npmmirror.com
RUN npm install
CMD npm start
```

### 测试

构建镜像
```zsh
docker build -t test/simple-backend:v1.0 .
```

启动项目
```zsh
docker run -d -p 30000:3000 --name backend test/simple-backend:v1.0
```

使用url请求(注意云服务开放3000端口)

```
http://localhost:30000/?a=1
```

响应如下

![image-20240503160916921](/images/k8s-quick-start/image-20240503160916921.png)




### K8S集群部署

想要部署本地的项目到minikube上，需要执行如下命令

```zsh
eval $(minikube docker-env)
```
执行之后，当前会话的的`docker`命令当前终端会话指定minikube内部的docker

然后再重新执行build （**十分重要**）
```zsh
docker build -t test/simple-backend:v1.0 .
```


编写 deployment.yaml

```yaml
apiVersion: apps/v1 # 指定Kubernetes API的版本，apps/v1是常用于Deployment的版本
kind: Deployment # 指定资源类型为Deployment，用于部署应用
metadata:
  name: backend-deployment # Deployment的名称
  labels:
    app: backend # 为Deployment添加标签，用于标识和选择性地过滤资源
spec: # Deployment的规格说明
  replicas: 1 # 指定副本数量为1，即运行一个Pod的实例
  selector: # 选择器，用于确定哪些Pod应该由这个Deployment管理
    matchLabels:
      app: backend # 选择标签为app=backend的Pod
  template: # Pod模板，定义Pod的标签和容器规格
    metadata:
      labels:
        app: backend # Pod的标签，与上面的selector匹配，确保Deployment可以管理这个Pod
    spec: # 定义Pod中容器的规格
      containers: # Pod中容器的定义列表
      - name: backend # 容器的名称
        image: test/simple-backend:v1.0 # 容器使用的镜像
        ports: # 容器暴露的端口列表
        - containerPort: 3000 # 容器内部监听的端口号
```

这里的`image`就是上面发布



编写

```yaml
apiVersion: v1 # 指定Kubernetes API的版本，v1是Service的标准版本
kind: Service # 指定资源类型为Service，用于暴露应用
metadata:
  name: backend-service # Service的名称
spec: # Service的规格说明
  selector: # 选择器，用于确定哪些Pod应该由这个Service管理
    app: backend # 选择标签为app=backend的Pod
  type: NodePort # Service的类型为NodePort，使得可以通过集群的节点IP和静态端口访问Service
  ports: # 定义Service暴露的端口和目标Pod的端口的映射
  - protocol: TCP # 使用的协议，这里是TCP
    port: 80 # Service对外暴露的端口
    targetPort: 3000 # Pod内部的目标端口，Service将流量转发到这个端口
    nodePort: 30080 # 集群外部访问Service的端口，通过<节点IP>:<nodePort>的形式访问
```



部署deployment

```
kubectl apply -f deployment.yaml
```

查看deployment和pod的状态（如下所示

![image-20240503190542614](/images/k8s-quick-start/image-20240503190542614.png)

部署service

```
kubectl apply -f service.yaml
```

查看service

![image-20240503190457779](/images/k8s-quick-start/image-20240503190457779.png)

增加端口转发

```
kubectl port-forward --address 0.0.0.0 service/backend-service 38080:80
```

到浏览器验证一下

![image-20240503190819562](/images/k8s-quick-start/image-20240503190819562.png)

说明项目部署成功

由于minikube不能直接讲k8s集群的端口绑定到宿主机，所以需要通过端口转发的方式

模拟单节点的k8s，还是推荐使用kubeadm




##  参考

- [minikube-start](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl工具](https://kubernetes.io/docs/tasks/tools/)
- [Minikube 部署安装](https://icyfenix.cn/appendix/deployment-env-setup/setup-kubernetes/setup-minikube.html)
- [push image to minikube](https://minikube.sigs.k8s.io/docs/handbook/pushing/#1-pushing-directly-to-the-in-cluster-docker-daemon-docker-env)
