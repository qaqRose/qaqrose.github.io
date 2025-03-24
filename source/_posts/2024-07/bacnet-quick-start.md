---
title:  BACnet快速上手
layout: info
commentable: true
date: 2024-07-26
mathjax: true
mermaid: true
tags: [ Java、BACnet ]
categories: 开发
description: 
---



## BACnet仿真

在开始学习 BACnet之前，我们先下载一个BACnet模拟器 Yabe （Yet Another BACnet Explorer）

下载地址可以[点击此处](https://sourceforge.net/projects/yetanotherBACnetexplorer/)  ，文章版本是 1.3.2 

下载并安装

可以在导航栏看到

 ![image-20241112180256621](images\bacnet-quick-start\image-20241112180256621.png)

其中 BACnet.Room.Simulator 是BACnet设备仿真，可以让模拟现实中一个室内控制设备

![image-20241113110632048](images\bacnet-quick-start\image-20241113110632048.png)

打开软件，可以看到是一个温度控制传感器

左下角是预定的三种模式，分别是Comfort(舒适)、Eco+（环境友好）、Vacancv（空缺）

其实就是对应着不同的温度，例如图中选了1 Comfort，对应的温度是21°，此时室外温度是12° （分别是上面2个温度）

其中20.7°C则表示当前室内温度

底下是BACnet的设备Id：458942 

### Yabe扫描BACnet设备

简单了解之后，我们使用Yabe来扫描这个设备

右键点击Devices，然后选中 Add device

![image-20241113141007686](images\bacnet-quick-start\image-20241113141007686.png)

查看BACnet的一些链接参数

![image-20241113141130708](images\bacnet-quick-start\image-20241113141130708.png)

我们通过BACnet/IP V4方式连接

端口号使用即可，再选择一下IP地址（172.29.224.1 这是我本地的ip）

点击start，Yabe会在这个网段广播，扫描BACnet 设备

我们可以启动多个仿真，对应不同房间的设备

![image-20241113142322713](images\bacnet-quick-start\image-20241113142322713.png)

每个BACnet设备都有一个设备id

可以看到两台设备的设备id分别是 458942，458943

每个BACnet设备有一些寄存器地址（Address Space）,用于存储不同的点位

![image-20241113143333547](images\bacnet-quick-start\image-20241113143333547.png)

### BACnet基础对象类型

BACnet的设备字段根据类型可以分为

AI、AO、AV、BI、BO、BV、MI、MO、MV

| 类型 | 读   | 写   | 描述               |
| ---- | ---- | ---- | ------------------ |
| AI   | 可读 | 不可 | Analog Input       |
| AO   | 可读 | 可写 | Analog Output      |
| AV   | 可读 | 可写 | Analog Value       |
| BI   | 可读 | 不可 | Binary Input       |
| BO   | 可读 | 可写 | Binary Output      |
| BV   | 可读 | 可写 | Binary Value       |
| MI   | 可读 | 不可 | Multi State Input  |
| MO   | 可读 | 可写 | Multi State Output |
| MV   | 可读 | 可写 | Multi State Value  |

除了 `Input` 为只读之外，其他都是可读可写

在 RoomControl 这个设备里，AI0  AI1 AI2 分别表示室内温度、热水温度、室外温度

室内温度

![image-20241113152302784](images\bacnet-quick-start\image-20241113152302784.png)

水温

![image-20241113152311636](images\bacnet-quick-start\image-20241113152311636.png)

室外温度

![image-20241113152343365](images\bacnet-quick-start\image-20241113152343365.png)

可以看到AI类型有以上这些字段

| 字段              | 描述                                                     |
| ----------------- | -------------------------------------------------------- |
| Description       | BACnet对象的字段description，用于进一步描述对象          |
| Event State       | 事件状态                                                 |
| Object Identifier | BACnet对象ID，格式为`object-type,object-instance-number` |
| Object Name       | BACnet对象的名称，用于描述对象的字段namedescription      |
| Object Type       | 对象的BACnet类型，例如`analog-input`                     |
| Out Of Service    | 不可使用                                                 |
| Present Value     | 当前值属性                                               |
| Reliability       | 可靠性                                                   |
| Status Flags      | 状态位                                                   |
| Units             | 单位                                                     |

AV1 AV2 AV3 分别对应仿真的三个温度模式（Comfort/Eco+/Vacancv）的温度值

可以通过修改`Present Value`来改变仿真终端的数值

例如修改 `SetPoint 1`的值为31.1 ，可以看到终端上的温度也变成31.1

![image-20250321103332794](images\bacnet-quick-start\image-20250321103332794.png)



我们还可以将BACnet Object 拖拽到监听点位，在下方就可以数值变化的曲线，方便我们观察指标的变化

![image-20250321103015129](images\bacnet-quick-start\image-20250321103015129.png)



## 使用Java代码控制BACnet

我们本地使用迅绕的[自控网关]([BACnet网关,上海迅饶自动化科技有限公司](http://www.bacnetchina.com/news.asp?cl_id=85))

在网关配置了BACnet IP 转发

![image-20250321133954142](images\bacnet-quick-start\image-20250321133954142.png)

点位如下

![image-20250321133925301](images\bacnet-quick-start\image-20250321133925301.png)

我们使用Java代码来读写点位

### Maven 依赖

首先引入依赖

```xml
<dependency>
	<groupId>org.code-house.BACnet4j</groupId>
	<artifactId>ip</artifactId>
	<version>1.3.0</version>
</dependency>
```

### 快速开始

编写一个简单测试方式来测试 

这个例子使用IP直连的方式，而不是上面使用Yabe时用的广播方式

````java
public class BACnetClientTest {
    public static void main(String[] args) {
        IpNetwork network = new IpNetworkBuilder()
                .withSubnet("255.255.255.0", 24)
                .withPort(47809)
                .withReuseAddress(true)
                .build();
        int localDeviceId = RandomUtil.randomInt(10000);

        LocalDevice localDevice = new LocalDevice(localDeviceId, new DefaultTransport(network));
        BACnetClient client = new BACnetXClient(localDevice);
        client.start();

        int deviceId = 2605;

        localDevice.send(IpNetworkUtils.toAddress("192.168.0.220", 47808), new WhoIsRequest(deviceId, deviceId));
        RemoteDeviceFinder.RemoteDeviceFuture future = localDevice.getRemoteDevice(deviceId);

        RemoteDevice remoteDevice = null;
        try {
             remoteDevice = future.get(3000L);
        } catch (BACnetException e) {
            e.printStackTrace();
        }

        DefaultDeviceFactory defaultDeviceFactory = new DefaultDeviceFactory();
        Device device = defaultDeviceFactory.createDevice(remoteDevice);
        
        BACnetObject BACnetObject = new BACnetObject(device, 0,  BACnetObjectTypeEnum.ANALOG_INPUT.getType());
        Object read =  client.getPresentValue(BACnetObject, (BACnetToJavaConverter<Object>) encodable -> Double.parseDouble(encodable.toString()));
        System.out.println("read " + read);
    }
}
````

上面的程序主要是通过BACnet与远程设备通行，并读取对象的属性值

**代码解释**

- 创建本地BACnet设备

```java
IpNetwork network = new IpNetworkBuilder()
        .withSubnet("255.255.255.0", 24)   // 设置子网掩码和前缀长度
        .withPort(47809)				// 设置本地设备的端口号
        .withReuseAddress(true)			// 允许重用地址
        .build();
int localDeviceId = RandomUtil.randomInt(10000); // 使用随机id

LocalDevice localDevice = new LocalDevice(localDeviceId, new DefaultTransport(network));
```

- 启动BACnet客户端

```java
BACnetClient client = new BACnetXClient(localDevice);
client.start();			// 启动客户端
```

这里`BACnetXClient` 是自己重新封装的，因为类库提供的没有提供`LocalDevice`，所以重新封装一个，源码在**附录1**

- 发送WhoIsRequest发现远程设备

```java
int deviceId = 2605;
localDevice.send(IpNetworkUtils.toAddress("192.168.0.220", 47808), new WhoIsRequest(deviceId, deviceId));   

RemoteDeviceFinder.RemoteDeviceFuture future = localDevice.getRemoteDevice(deviceId);

RemoteDevice remoteDevice = null;
try {
    remoteDevice = future.get(3000L);  //  等待 3000 毫秒以获取远程设备
} catch (BACnetException e) {
    e.printStackTrace();
}
```

这里提供远程设备的ip、端口和设备id

- 创建Device对象

创建一个Device对象工厂，使用远程设备创建一个Device，用于读写操作

```java
DefaultDeviceFactory defaultDeviceFactory = new DefaultDeviceFactory();
Device device = defaultDeviceFactory.createDevice(remoteDevice);
```

- 读取远程设备的属性值

```java
BACnetObject BACnetObject = new BACnetObject(device, 0, BACnetObjectTypeEnum.ANALOG_INPUT.getType());	// 创建一个BACnet的数据类型	
Object read = client.getPresentValue(BACnetObject, (BACnetToJavaConverter<Object>) encodable -> Double.parseDouble(encodable.toString()));		// 读取属性值
System.out.println("read " + read);
```

本地使用`BACnetObjectTypeEnum`封装BACnet的数据类型

- 写入远程设备的属性值

```java
        BACnetObject BACnetObject = new BACnetObject(device, 0,  BACnetObjectTypeEnum.ANALOG_OUTPUT.getType());				// 创建 AO 0 点
        client.setPresentValue(BACnetObject, 3.0D, (JavaToBACnetConverter<Object>) e -> new Real((float) ((Double)e).doubleValue()));		// 设置点位值为 3.0

```

设置之后

![image-20250324113229771](images\bacnet-quick-start\image-20250324113229771.png)

可以看到点位值变成3

说明点位写入成功

### 原理分析

代码原理如下图

![image-20250324165444792](images\bacnet-quick-start\image-20250324165444792.png)

在启动客户端 `client.start()` 之后，底层还先后执行transport和network两个实体的初始化方法 `initialize` ，并启动各自的内置线程

LocalDevice 的 `initialize`  方法

``` java
public synchronized LocalDevice initialize(RestartReason lastRestartReason) throws Exception {
        this.deviceObject.writePropertyInternal(PropertyIdentifier.lastRestartReason, lastRestartReason);
        this.timer = this.createScheduledExecutorService();
        this.transport.initialize();   // 初始化 transport
        this.initialized = true;
    
    // 省略其他
}
```

Transport 的 `initialize`  方法

```
    public void initialize() throws Exception {
        this.servicesSupported = this.localDevice.getServicesSupported();
        this.running = true;
        this.network.initialize(this);
        // 启动内置线程
        this.thread = new Thread(this, "BACnet4J transport for device " + this.localDevice.getInstanceNumber());
        this.thread.start();
        // 向本地网络广播WhoIsRouter消息
        this.network.sendNetworkMessage(this.getLocalBroadcastAddress(), (OctetString)null, 0, (byte[])null, true, false);
    }
```

在 Transport 的 run 方法内处理 数据报文的出入 （Transport 实现 `Runnable` 接口 ）

```java
public void run() {
        while(this.running) {
            boolean pause = true;
            Outgoing out = (Outgoing)this.outgoing.poll();
            if (out != null) {
                try {
                    out.send();	  // 最终使用network发送请求
                } catch (Exception var8) {}
                pause = false;
            }

            NPDU in = (NPDU)this.incoming.poll();
            if (in != null) {
                try {
                    this.receiveImpl(in);
                } catch (Exception var7) {}
                pause = false;
            }

            // 省略部分代码
            if (pause && this.running) {
                ThreadUtils.waitSync(this.pauseLock, 50L);  // 等待
            }
        }

    }

```

Network 的 `initialize`  方法

```java
public void initialize(Transport transport) throws Exception {
        super.initialize(transport);
    	// 初始化 用户数据包套接字 UDP
        this.localBindAddress = InetAddrCache.get(this.localBindAddressStr, this.port);
    
        if (this.reuseAddress) {
            this.socket = new DatagramSocket((SocketAddress)null);
            this.socket.setReuseAddress(true);
            if (!this.socket.getReuseAddress()) {
                LOG.warn("reuseAddress was set, but not supported by the underlying platform");
            }

            this.socket.bind(this.localBindAddress);
        } else {
            this.socket = new DatagramSocket(this.localBindAddress);
        }

		// 启动线程
        this.thread = new Thread(this, "BACnet4J IP socket listener for " + transport.getLocalDevice().getId());
        this.thread.start();
    }
```

在 Network 里面接收并处理数据报文

```java
public void run() {
        byte[] buffer = new byte[2048];		// 2M的缓存区
        DatagramPacket p = new DatagramPacket(buffer, buffer.length);

        while(!this.socket.isClosed()) {
            try {
                this.socket.receive(p);		// 接收数据
                this.bytesIn += (long)p.getLength();
                ByteQueue queue = new ByteQueue(p.getData(), 0, p.getLength());
                OctetString link = IpNetworkUtils.toOctetString(p.getAddress().getAddress(), p.getPort());
                this.handleIncomingData(queue, link);  // 处理数据
                p.setData(buffer);
            } catch (IOException var5) {
            }
        }

}

/**
 * 将数据转成NPDU在放置到incoming队列
 */
protected void handleIncomingData(ByteQueue queue, OctetString linkService) {
        try {
            // 根据不同ip协议有不同实现来处理数据
            NPDU npdu = this.handleIncomingDataImpl(queue, linkService);
            if (npdu != null) {
                this.getTransport().incoming(npdu);
            }
        } catch (Exception var4) {}

}
```

## 结论

通过本文学习，可以简单了解 `BACnet` 进行设备仿真、扫码设备、读写设备属性等基本操。通过 Java 代码进行于 `BACnet`设备进行交互，以及简单了解`bacnet4j` 基础类库的基本原理

## 附录1 

`BacNetXClient` 实体类

```java
import com.serotonin.bacnet4j.LocalDevice;
import com.serotonin.bacnet4j.type.constructed.ReadAccessResult;
import com.serotonin.bacnet4j.type.constructed.SequenceOf;
import org.code_house.bacnet4j.wrapper.api.BacNetClientBase;
import org.code_house.bacnet4j.wrapper.api.BacNetObject;
import org.code_house.bacnet4j.wrapper.api.Device;
import org.code_house.bacnet4j.wrapper.api.Type;


public class BacNetXClient extends BacNetClientBase {

    public BacNetXClient(LocalDevice localDevice) {
        super(localDevice);
    }

    @Override
    protected BacNetObject createObject(Device device, int instance, Type type, SequenceOf<ReadAccessResult> readAccessResults) {

        if (readAccessResults.size() == 1) {
            SequenceOf<ReadAccessResult.Result> results = readAccessResults.get(0).getListOfResults();
            if (results.size() == 4) {
                String name = results.get(2).toString();
                String units = results.get(1).toString();
                String description = results.get(3).toString();
                return new BacNetObject(device, instance, type, name, description, units);
            }
            throw new IllegalStateException("Unsupported response structure " + readAccessResults);
        }
        String name = getReadValue(readAccessResults.get(2));
        String units = getReadValue(readAccessResults.get(1));
        String description = getReadValue(readAccessResults.get(3));
        return new BacNetObject(device, instance, type, name, description, units);
    }

    private String getReadValue(ReadAccessResult readAccessResult) {
        // first index contains 0 value.. I know it is weird, but that's how bacnet4j works
        return readAccessResult.getListOfResults().get(0).getReadResult().toString();
    }

}
```

参考 `org.code_house.bacnet4j.wrapper.ip.BacNetIpClient` 开发的一个客户端，增加一个  `BacNetXClient（LocalDevice localDevice)` 的构造参数