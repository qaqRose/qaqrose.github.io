---
title:  BACnet 快速上手
layout: info
commentable: true
date: 2024-07-26
mathjax: true
mermaid: true
tags: [ Java ]
categories: 开发
description: 
---



在开始学习 bacnet之前，我们先下载一个bacnet模拟器 Yabe

全拼是Yet Another BACnet Explorer 中文是又一个Bacnet探索者

下载链接是 [Yabe](https://sourceforge.net/projects/yetanotherbacnetexplorer/)  ，我的版本是 1.3.2 (尽量保持版本一直)

下载并安装

可以在导航栏看到

 ![image-20241112180256621](D:\u\blog\source\images\bacnet-quick-start\image-20241112180256621.png)

其中 Bacnet.Room.Simulator 是Bacnet设备仿真，可以让我们模拟现实设备和测试

![image-20241113110632048](D:\u\blog\source\images\bacnet-quick-start\image-20241113110632048.png)

打开软件可以看到是一个室内温度控制传感器

左下角是预定的三种模式，分别是Comfort(舒适)、Eco+（环境友好）、Vacancv（空缺）

其实就是对应着不同的温度，例如图中选了1 Comfort，对应的温度是21°，此时室外温度是12° （分别是上面2个温度）

其中20.7°C则表示当前室内温度



简单了解之后，我们使用Yabe来链接这个设备

右键点击Devices，然后选中 Add device

![image-20241113141007686](D:\u\blog\source\images\bacnet-quick-start\image-20241113141007686.png)

查看Bacnet的一些链接参数

![image-20241113141130708](D:\u\blog\source\images\bacnet-quick-start\image-20241113141130708.png)

我们通过Bacnet/IP V4方式连接

端口号使用即可，再选择一下IP地址（172.29.224.1 这是我本地的ip）

点击start，Yabe会在这个网段广播，扫描Bacnet 设备，我们可以启动多个仿真，对应不同房间的设备

![image-20241113142322713](D:\u\blog\source\images\bacnet-quick-start\image-20241113142322713.png)

每个Bacnet设备都有一个设备id

可以看到两台设备的设备id分别是 458942，458943

每个Bacnet设备有一些寄存器地址（Address Space）,用于存储不同的点位

![image-20241113143333547](D:\u\blog\source\images\bacnet-quick-start\image-20241113143333547.png)

Bacnet的设备字段根据类型可以分为

AI、AO、AV、BI、BO、BV、MI、MO、MV

| 类型 | 读写     | 描述               |
| ---- | -------- | ------------------ |
| AI   | 只读     | Analog Input       |
| AO   | 可读可写 | Analog Output      |
| AV   | 可读可写 | Analog Value       |
| BI   | 只读     | Binary Input       |
| BO   | 可读可写 | Binary Output      |
| BV   | 可读可写 | Binary Value       |
| MI   | 只读     | Multi State Input  |
| MO   | 可读可写 | Multi State Output |
| MV   | 可读可写 | Multi State Value  |

在RoomControl这个设备里，AI0  AI1 AI2 分别表示室内温度、热水温度、室外温度

室内温度

![image-20241113152302784](D:\u\blog\source\images\bacnet-quick-start\image-20241113152302784.png)

水温

![image-20241113152311636](D:\u\blog\source\images\bacnet-quick-start\image-20241113152311636.png)

是室外温度

![image-20241113152343365](D:\u\blog\source\images\bacnet-quick-start\image-20241113152343365.png)

可以看到AI类型有以上这些字段

| 字段              | 描述                                                     |
| ----------------- | -------------------------------------------------------- |
| Description       | BACnet对象的字段description，用于进一步描述对象          |
| Event State       |                                                          |
| Object Identifier | BACnet对象ID，格式为`object-type,object-instance-number` |
| Object Name       | BACnet对象的名称，用于描述对象的字段namedescription      |
| Object Type       | 对象的BACnet类型，例如`analog-input`                     |
| Out Of Service    |                                                          |
| Present Value     | 当前值属性                                               |
| Reliability       |                                                          |
| Status Flags      |                                                          |
| Units             |                                                          |



AV1 AV2 AV3 分别对应仿真的三个温度模式（Comfort/Eco+/Vacancv）的温度值

AV0 则允许设置一个温度，并通过设置

