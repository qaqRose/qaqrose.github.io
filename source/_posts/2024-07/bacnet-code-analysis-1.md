---
title:  BACnet4J源码分析（一）
layout: info
commentable: false
date: 2024-07-26
mathjax: false
mermaid: false
tags: [ Java ]
categories: 开发
description: 
---



BACnet是一种专为建筑自动化和控制系统设计的通信协议，在一些物联网的场景中都会使用Bacnet协议进行设备之间的通信



简单使用

```java
       LocalClient client = new LocalBacnetClient("192.168.0.220", 47808, 2605);

        Object read = client.read(2605, BacnetObjectTypeEnum.MULTI_STATE_VALUE, 648);
        System.out.println("read " + read);
```













