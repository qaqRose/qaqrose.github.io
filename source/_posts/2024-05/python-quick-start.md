---
title:  python工作环境搭建
layout: info
commentable: true
date: 2024-05-08
mathjax: true
mermaid: true
tags: [ Python ]
categories: 开发
description: 
---

最近因为工作需要使用`Python`来开发和维护之前同事的代码
记录一下快速搭建python环境的过程



## 安装 Miniconda

`MiniConda`是`conda`的免费最小安装版，里面只有少量软件例如`pip`,`zlib`等

要求window10或以上， 目前`MiniConda`的最新版自带Python版本是`3.12`

我们可以使用`conda`来管理我们的依赖，并通过切换环境来使用不同版本的`Python`



从页面点击下载, 下载页面为[Minicondda download page](https://docs.anaconda.com/free/miniconda/#)

或者命令行 （window）

```powershell
curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe -o miniconda.exe
start /wait "" miniconda.exe /S
del miniconda.exe
```
默认安装即可

安装完成后打开`Anaconda Prompt`

输入`conda list`  测试安装环境是否成功

![image-20240508184630590](\images\python-quick-start\image-20240508184630590.png)

## 更新镜像源（可选）

执行一下命令使用清华源
```zsh
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
conda config --set show_channel_urls yes
```

执行完成后查看

```
conda config  --show
```



![image-20240509183446397](\images\python-quick-start\image-20240509183446397.png)



## 切换环境
默认的初始环境是`base`

![image-20240509181808047](\images\python-quick-start\image-20240509181808047.png)

### 创建环境
我们通过如下命令来创建一个环境
```zsh
conda create --name env1 python=3.10
```
创建了一个名称叫`env1`的python3.10版本的环境
创建的时候会创建一个环境目录（在安装目录的`env`文件夹下）
并下载一些依赖，例如`pip`, `zlib` 等

![image-20240509182306044](\images\python-quick-start\image-20240509182306044.png)

下载的依赖

![image-20240509182515021](\images\python-quick-start\image-20240509182515021.png)

### 切换环境

通过命令
```
conda activate env1
```
就可以切换到我们刚刚创建的`env1`环境



![image-20240509182729365](\images\python-quick-start\image-20240509182729365.png)



可以看到python版本是`3.10`


### 停用环境

通过如下来停用环境
```
conda deactivate
```


## 安装依赖
我们也可以使用`pip`来安装依赖
但是推荐使用`conda`来安装

### 搜索依赖

```zsh
conda search [-h] [--envs] [-i] [--subdir SUBDIR] [--skip-flexible-search] [-c CHANNEL] [--use-local]
                              [--override-channels] [--repodata-fn REPODATA_FNS] [--experimental {jlap,lock}]
                              [--no-lock] [--repodata-use-zst | --no-repodata-use-zst] [-C] [-k] [--offline] [--json]
                              [-v] [-q]
```
支持很多参数， 并且支持MatchSpec查询方式（conda查询语言）

普通查询
```zsh
conda search numpy

![image-20240508190855795](\images\python-quick-start\image-20240508190855795.png)

```
查询某个版本范围
```zsh
conda search "numpy>=1.26"
```
模糊搜索
```zsh
conda search "*mysql*"
```
支持`*`模糊匹配

查看某个版本的具体信息
```zsh
conda search pandas[build=py39h5da7b33_0]  -i
```

![image-20240508192428631](\images\python-quick-start\image-20240508192428631.png)

### 安装依赖

`conda install scipy`

下载`scipy`到当前环境

可以通过`-n` 或 `--name`来指定环境

```zsh
conda install -n env1 scipy
conda install --name env1 scipy
```
env1是环境名称

指定版本
```zsh
conda install numpy=1.21.5 -y
```
`-y` 是跳过询问，直接下载

### 查看依赖

```
conda list
```
可以查看环境的依赖包有哪些

![image-20240510115549385](\images\python-quick-start\image-20240510115549385.png)



## 安装 Pycharm

进过上面环境的安装之后

我们已经可以编写python代码啦

![image-20240510170958572](\images\python-quick-start\image-20240510170958572.png)

工欲善其事，必先利其器

世界上有家做`IDE`很牛逼的公司叫**JetBrains**

使用`PyCharm`来开发，[下载地址](https://www.jetbrains.com/pycharm/download)

使用免费的社区版就足矣了

![image-20240521110030043](\images\python-quick-start\image-20240521110030043.png)

### 配置环境
为了使不同项目的依赖不冲突，我们可以新建一个项目，并创建一个conda环境

进入到配置页面

![image-20241105164423729](\images\python-quick-start\image-20241105164423729.png)

依次点击  Project -> Python Interpreter  -> Add Interpreter -> Add Local Interpreter

然后新增一个conda环境，如下

![image-20241106095300670](\images\python-quick-start\image-20241106095300670.png)



接着我们就可以在这个环境开发了

### 开发一个最小WEB程序

创建一个新环境， `web-hello-world`

使用python版本为3.11

按照flasky依赖

```
pip install Flash
```

![image-20241105174900874](\images\python-quick-start\image-20241105174900874.png)

安装完成

编写一个Flask程序

文件`hello.py`

```python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"
```

启动项目

```
flask --app hello run
```

![image-20241105175206188](\images\python-quick-start\image-20241105175206188.png)

访问[127.0.0.1:5000](http://127.0.0.1:5000/)

![image-20241105175226110](\images\python-quick-start\image-20241105175226110.png)

运行成功

###  开发一个爬虫项目

我们根据上面的步骤创建一个新的环境

创建一个新的项目 `spider-demo`

![image-20241105180324772](\images\python-quick-start\image-20241105180324772.png)

安装依赖

```
pip install BeautifulSoup4 requests
```

编写一个爬虫抓取古诗

```python
from bs4 import BeautifulSoup
import requests

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.9999.999 Safari/537.36'
}
url = 'https://www.gushicimingju.com/gushi/shi/7.html'
response = requests.get(url, headers=headers)

soup = BeautifulSoup(response.text, 'html.parser')

contentList = soup.find(class_="gushi-info").find(class_="shici-content").select('p')

for item in contentList:
    print(item.getText())
```

运行如下

![image-20241105183428741](\images\python-quick-start\image-20241105183428741.png)



### 总结

结合`Pycharm`来使用可以大大提高开发的效率

针对不同的环境也自由切换成本也很低

依赖库的版本冲突问题也可以解决





## 参考

- [miniconda](https://docs.anaconda.com/free/miniconda/#)
- [switch-environment](https://docs.anaconda.com/free/working-with-conda/configurations/switch-environment/)
- [pycharm configure conda environment](https://www.jetbrains.com/help/pycharm/conda-support-creating-conda-virtual-environment.html#create-a-conda-environment)
