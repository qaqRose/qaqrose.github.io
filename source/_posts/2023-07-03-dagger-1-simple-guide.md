---
title: dagger1 简单教程
layout: info
commentable: true
date: 2023-07-03
mathjax: true
mermaid: true
tags: [Java]
categories: 开发
description: 
---


dagger 是有 `Square` 公司开源的一个 `Java` 和 `Android` 的依赖注入框架

dagger认为最好的类是那些做实事的类，像 `BarcodeDecoder`、`AudioStreamer`，而像 
`BarcodeDecoderFactory`，`MutableContextWrapper` 这些类是最没有用的类，却占用了大量空间， dagger可以替代掉一些工厂类，让你专注于实用类的编写，只需要声明类之间的依赖关系即可

dagger 实现了 `JSR-330` 的依赖注入标准   
[dagger1](https://github.com/square/dagger) 目前已经停止维护，[dagger2](https://github.com/google/dagger) 由 google 接手维护了   
由于 dagger1 已经废弃了，所以这里只做一个简单介绍，不过多深入分析   

## 使用dagger1

我们以一个打印机服务的例子来演示一下 dagger 依赖注入  
假设我们要开发一个打印服务

### 注入依赖

```java
public class PrintApp {
    private final Printer printer;              // 打印机
    private final PrintDriver printDriver;      // 打印机驱动
    
    @Inject   // 注入依赖
    PrintApp(PrintDriver printDriver, Printer printer) {
        this.printDriver = printDriver;
        this.printer = printer;
    }
}
```
打印程序依赖 `Printer` 和 `PrintDriver`   
```java
public interface Printer {
    /**
     * 打印
     */
    void print(Connection connect);
}
```
和   
```java
public interface PrintDriver {
    /**
     * 连接打印机
     */
    Connection connect();

}
```
我们使用 `@Inject` 注解来通过构造器注入依赖      
我们也可以通过字段注入
```java
public class PrintApp {
    @Inject
    Printer printer;

    @Inject
    PrintDriver printDriver;
}
```
注意字段不能是 private   
但是 dagger 不支持方法注入

`@Inject` 有几个限制   
- 无法构造接口类
- 无法注解第三方类
- 可配置对象必须配置   
如果配置类没有满足依赖，将无法通过编译

### 提供依赖

接着我们需要给 `Printer` 和 `PrintDriver` 提供实现

```java
@Module(injects = PrintApp.class, library = true)  // <1> injects表示注入类型， library表示可在外部依赖
public class PrintModule {

    @Provides       // <2> 方法注解，方法的返回值可用于满足依赖
    @Singleton      // 单例， 在所有注入的地方dagger都不会重新创建
    Printer providerPrinter() {
        return new ZebraPrinter();
    }

    @Provides
    PrintDriver providerDriver() {
        return new ZebraPrintDriver();
    }

}
```

我们新建一个打印模块 `PrintModule`， 注解 `@Module` 用于声明该是一个 dagger 依赖模块   
为了让dagger知道我们的模块要注入到那个依赖中，需要声明 `injects` 的属性，这个会在编译期验证   
我们在里面提供可选的依赖，例如在<2>中 我们提供了打印机的实现（`ZebraPrinter`） 

```java
public class ZebraPrinter implements Printer {
    @Override
    public void print(Connection connect) {
        if(connect.connected) {
            System.out.println("开始打印");
        } else {
            throw new RuntimeException("打印机未连接");
        }
    }
}
```

还有斑马打印驱动

```java
public class ZebraPrintDriver implements PrintDriver {
    @Override
    public Connection connect() {
        // 随机失败
        if(System.currentTimeMillis() % 2 > 0) {
            System.out.println("打印机连接失败");
            return new Connection(false);
        }
        System.out.println("打印机连接成功");
        return new Connection(true);
    }
}
```



### 构建依赖图

注入 `@inject` 和提供 `@provides` 结合可以表达成一个依赖注入图，我们通过 `ObjectGraph ` 来创建

```java
// 通过打印模块来构造一个依赖图
ObjectGraph objectGraph = ObjectGraph.create(new PrintModule());
```

然后就可以通过`get`方法实现对`PrintApp`打印程序的依赖注入

```java
// 通过打印模块来构造一个依赖图
ObjectGraph objectGraph = ObjectGraph.create(new PrintModule());
PrintApp printApp = objectGraph.get(PrintApp.class);
```

实现打印

```java
public class PrintApp {
    @Inject Printer printer;
    @Inject PrintDriver printDriver;
    
    void print() {
        Connection connect = printDriver.connect();
        printer.print(connect);
    }

    public static void main(String[] args) {
        // 通过打印模块来构造一个依赖图
        ObjectGraph objectGraph = ObjectGraph.create(new PrintModule());
        PrintApp printApp = objectGraph.get(PrintApp.class);
        printApp.print();
    }
}
```

运行输出

```
打印机连接成功
开始打印
```

## 结语

dagger1 还支持懒加载，但是由于是过时的技术，这里只做简单的演示

演示代码上传至 github 仓库 [dagger1-learn](https://github.com/qaqRose/dagger1-learn)


