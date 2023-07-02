---
layout:     post
title:      "随便叨叨"
subtitle:   ""
date:       2023-07-02
author:     "qaqRose"
header-img: ""
tags:
    - 写作
---

## 写点什么

一直都很喜欢写文章的感觉

小时候看三毛的散文，总感觉她的文字好简单，但是写出的文章又很好

所以就诞生一种“我上我也行的错觉”

从大学开始，陆陆续续搞过一些东西，但是感觉自己一方面文字功底不够，
写出来的文章总是不满意，另一方面又觉得自己写出的技术文章技术太浅，
类似的技术文章在互联网已经有了很多，自己只不过在制造一些互联网垃圾而已

幸好看的人并不多，也就逐渐放弃了

工作几年之后，心里越来越有种焦虑，现在不写点什么，以后更没机会写了

于是开始了准备

## 写作工具

首先，程序员写作，首选肯定是markdown

语法简洁，就算用不到复杂的数学公式，用用简单的标题，代码段等也能增加不少的阅读体验

市面上也有很多工具，插件可用，编写起来非常方便

之前写过公众号、CSDN，甚至搞过自己的服务器

但是我没有继续选择熟悉的方式，而是Github Pages

主要原因就是省心

首先是公众号，我认为公众号阅读者一般都是在移动端的，但是技术博客很多都需要代码片段和大图去辅助
写作，有时候受限于篇幅，不得不压缩表达或者删去片段，写作体验也不好，另外，本人审美太差了，所以
最后排版并不好看

自己搞有过云服务器，部署一个[halo](https://github.com/halo-dev/halo)博客，
上手非常快，一个小时就可以搞定了，但是感觉还是太重了，首先需要有自己的域名+服务器，
还是在管理后台操作，所以部署之后并没有写几篇文章

![Halo](/img/hello-world/halo.png)

至于在类似知乎、CSDN、掘金等网站写文章，我个人觉得从传播角度是有好处的，但是也不会是首选

所以选择了使用[Github Pages](https://pages.github.com/)的方式，
用Git工作量的方式来编写文章对于程序员来说，
可以说是非常舒服了，加上github提供了编译、部署和域名等能力，也可以节省一笔支出

![Github Pages](/img/hello-world/github-pages.png)

## 搭建博客

在网上找了一些Github Pages建站的教程

然后找到了[huxpro](https://github.com/huxpro)大神的[教程](https://github.com/Huxpro/huxpro.github.io/blob/master/_doc/README.zh.md)和[模板](https://github.com/Huxpro/huxblog-boilerplate)


这里简单描述我搭建过程和遇到的问题

### 建站

首先在github新增仓库，名为`<username>.github.io`

![新建仓库](/img/hello-world/create-repository.png)

然后克隆[模板](https://github.com/Huxpro/huxblog-boilerplate)仓库

```bash
git clone https://github.com/Huxpro/huxblog-boilerplate.git
```

![克隆仓库](/img/hello-world/clone-repository.png)


然后修改remote,替换成自己的github仓库地址
```bash
# 先删除origin
git remote rm origin 

# 再新增

git remote add origin git@github.com:qaqRose/qaqrose.github.io.git

```

发布即可在`<username>.github.io` (username就是github的账户名)查看到自己的Github Pages

详细可以参考[教程](https://keysaim.github.io/post/blog/2017-08-15-how-to-setup-your-github-io-blog/)

### 稍作调整

1. 首先删除_posts文件夹内所有文章
2. 删除img文件夹的所有图片（可以替换自己的favicon.ico和封面图等）
3. 修改about.html(关于作者)里面的介绍
4. 删除或修改index.html和tags.html的description
5. 删除_include/head.html的meta标签google-site-verification
6. 配置_config.yml, 参考[官网文档](https://jekyllrb.com/docs/configuration/default/)


### 问题

第一个问题是没有写入权限问题
在执行`gem install jekyll`出现如下错误
>  You don't have write permissions for the /System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/gems/2.6.0 directory.

这是系统级的Ruby目录，所以我使用rbenv（Ruby版本管理器）来管理Ruby安装和gems

```bash
## 安转rbenv(macos)
brew install rbenv

## 初始化（一般会要求添加初始化代码到bash管理）
rbenv init

## 下载ruby版本,这里使用3.0.2版本
rbenv install 3.0.2

## 全局使用3.0.2版本
rbenv global 3.0.2

## 查看ruby版本
ruby -v
```


