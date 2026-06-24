---
title:  在 Jenkins 上部署 Python 项目
layout: info
commentable: true
date: 2026-06-24
mathjax: true
mermaid: true
tags: [ Jenkins ]
categories: 运维
description:  使用流水线部署 Python 项目
---

## 前言

第一次在Jenkins上部署项目 Python项目，在网上没有找到比较好的资料，所以在此记录一下简单的过程

## Jenkins 安装插件

这里使用到2个插件，如下图

分别是 [ShiningPanda](https://plugins.jenkins.io/shiningpanda/)  和 [pyenv-pipeline](https://plugins.jenkins.io/pyenv-pipeline)

![image-20260624140932273](/images/2026-06-24-deploy-python-project-by-jenkins/image-20260624140932273.png)

ShiningPanda是专为 **自由风格项目（Freestyle）** 设计，给 Jenkins 完整 Python 构建、虚拟环境、多版本测试能力，是早期 Jenkins Python CI 标配插件。

Pyenv Pipeline则是**流水线（Pipeline）**专用，提供了`withPythonEnv`语法块，是现代流水线的首先方案，还可以复用ShiningPanda注册的全局Python名称

我们的CI都是使用流水线的方式，所以使用Pyenv + ShiningPanda的混合方式，后续支持多版本支持改动比较小，兼顾流水线的便捷性

## 全局Python注册
安装完ShiningPanda插件之后，重启，在系统管理 > 全局工具配置 可以找到 `Python 安装`

![image-20260624142955351](/images/2026-06-24-deploy-python-project-by-jenkins/image-20260624142955351.png)

这里填写的名称是全局注册的Python名称，以图片为例，我这里使用Python的版本是3.11，所以取名python311，路径是 `/var/jenkins_home/tools/python/miniconda3/envs/py311/bin/python` 这个根据实际情况配置

我这里的jenkins是部署docker容器里面，miniconda是安装在宿主机上，创建环境之后将目录挂载到jenkins容器上即可

这里需要注意的是，Python的路径直接覆盖到python执行文件，而不是目录（在python执行文件的同目录下的pip执行文件可以被识别到并执行）

## 编写流水线

安装环境之后就可以编写流水线了，这一部分比较固定，我们的流程是更新代码、下载依赖、打包、推送镜像（docker）、企微通知

```groovy
import java.time.LocalDate
import groovy.json.JsonSlurper

def currentYear = LocalDate.now().getYear()
def currentMonth = LocalDate.now().getMonthValue()
def currentDay = LocalDate.now().getDayOfMonth()
def Date = "${currentYear}.${currentMonth}.${currentDay}"
pipeline {

    agent any

    environment {
        GITLAB_MANAGER = 'http://192.168.0.213:3000'
        // Harbor Registry的地址
        DOCKER_REGISTRY = '172.16.0.2:9990'
        // Harbor library
        HARBOR_LIBRARY = 'library'
        GITLAB_CREDENTIALS = 'gitea-git-id'
        HARBOR_CREDENTIALS = 'xxxxx'

        WECHAT_WEBHOOK_URL = 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxxxxx'
    }

    stages {

        stage('Init') {
            steps {
                script {
                    // 记录构建开始时间
                    env.START_TIME = System.currentTimeMillis()
                }
            }
        }

        stage('Checkout') {

            steps {
                // 使用自定义证书进行Git仓库的checkout
                checkout([$class: 'GitSCM',
                          branches: [[name: '*/main']],
                          userRemoteConfigs: [[
                              url: env.GITLAB_MANAGER + '/python/devicePerfModel.git',
                              credentialsId: env.GITLAB_CREDENTIALS
                          ]]
                ])

                dir('script') {
                    checkout([$class: 'GitSCM',
                              branches: [[name: '*/main']],
                              userRemoteConfigs: [[
                                      url: env.GITLAB_MANAGER + '/script/docker-script.git',
                                      credentialsId: env.GITLAB_CREDENTIALS
                              ]]
                    ])
                }

            }
        }

        stage('Install') {
            steps {
                script {
                    // 安装依赖项
                    withPythonEnv('python311') {
                        sh 'pip install -r requirements.txt'
                    }
                }
            }
        }

        stage('Push Image') {

            steps {
                script {
                    env.IMAGE_TAG = "${Date}_${env.BUILD_ID}"
                    env.SERVICE_NAME = env.JOB_NAME
                    env.DEPLOY_IMAGE_TAG = env.IMAGE_TAG
                    currentBuild.displayName = env.DEPLOY_IMAGE_TAG

                    // 登录Harbor Registry
                    withCredentials([usernamePassword(credentialsId: env.HARBOR_CREDENTIALS, passwordVariable: 'HARBOR_PASSWORD', usernameVariable: 'HARBOR_USERNAME')]) {
                        sh "docker login -u ${HARBOR_USERNAME} -p ${HARBOR_PASSWORD} ${DOCKER_REGISTRY}"
                    }

                    // 构建Docker镜像并标记为Harbor镜像
                    sh "docker build -t ${DOCKER_REGISTRY}/${HARBOR_LIBRARY}/${SERVICE_NAME}:${IMAGE_TAG} -f Dockerfile ."

                    // 推送镜像到Harbor Registry
                    sh "docker push ${DOCKER_REGISTRY}/${HARBOR_LIBRARY}/${SERVICE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Notify WeChat') {
            steps {
                script {
                    // 记录构建结束时间
                    env.END_TIME = System.currentTimeMillis()
                    // 计算构建时长（单位：秒）
                    def durationSeconds = (env.END_TIME.toLong() - env.START_TIME.toLong()) / 1000
                    // 构建消息内容
                    def message = """
**Jenkins 生产版本打包通知**
- 服务名称: ${env.SERVICE_NAME}
- Docker 镜像: ${DOCKER_REGISTRY}/${HARBOR_LIBRARY}/${SERVICE_NAME}:${IMAGE_TAG}
- 耗时: ${durationSeconds} 秒
"""

                    // 调用企业微信 Webhook API
                    def payload = """
                    {
                        "msgtype": "markdown",
                        "markdown": {
                            "content": "${message}"
                        }
                    }
                    """

                    // 发送 HTTP 请求
                    sh """
                        curl -X POST ${env.WECHAT_WEBHOOK_URL} \\
                        -H 'Content-Type: application/json' \\
                        -d '${payload}'
                    """
                }
            }
        }
    }

    post {
        failure {
            echo 'Sending failure notification...'
            script {
                // 构建消息内容
                def errorMessage = """生产任务打包失败
- 服务名称: ${env.JOB_NAME}
- Docker 镜像: ${DOCKER_REGISTRY}/${HARBOR_LIBRARY}/${env.JOB_NAME}:${Date}_${env.BUILD_ID}
请及时处理失败任务
"""
                // 调用企业微信 Webhook API
                def errorPayload = """
                {
                    "msgtype": "text",
                    "text": {
                        "content": "${errorMessage}",
                        "mentioned_list":["@all"]
                    }
                }
                """

                // 发送 HTTP 请求
                sh """
                 curl -X POST ${env.WECHAT_WEBHOOK_URL} \\
                -H 'Content-Type: application/json' \\
                -d '${errorPayload}'
        """
            }
        }
    }


}
```

下载依赖

```
stage('Install') {
            steps {
                script {
                    // 安装依赖项
                    withPythonEnv('python311') {
                        sh 'pip install -r requirements.txt'
                    }
                }
            }
        }
```

`python311`就是我们使用ShiningPanda注册的全局Python版本的名称，通过withPythonEnv语法块可以直接使用

![image-20260624150107893](/images/2026-06-24-deploy-python-project-by-jenkins/image-20260624150107893.png)

这样就把镜像推送到生产的harbor，剩下就生产部署的问题了，不在过多赘述

 
















