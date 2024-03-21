基于js脚本的逻辑控制引擎

## 前言

由于公司业务需求原先在边缘控制柜编写的控制逻辑需要迁移到管理系统来

现在需要在后台实现一套逻辑控制引擎，提供给硬件运维人员编写逻辑控制

经过选型和制定方案之后

决定使用JS脚本引擎来作为逻辑控制的引擎

JS语法对于运维人员来说上手也非常快

我们选用Nashorn JavaScript引擎，这个在Java8到14都内置了，可以直接使用，更高版本的JDK需要使用依赖引入

## 需求分析

简单对对业务进行分析

从使用者角度

```
1. 能编写脚本对设备进行控制和告警等
2. 支持传感器点位变量直接操作
3. 友好报错信息
4. 可测试
5. 可复用一些功能函数和业务函数
6. 执行日志，包含自定义变量的变更
```

从开发者的角度

``` 
1. 支持以上功能
2. 后续好扩展、对于修改比较方便
3. 引擎的功能与业务解耦，通过代理等方式实现
4. 方便单元测试，方便功能重构
```

简单来说就是需要考虑一些需求变更的问题

在开发前期就需要考虑到后面对设备监控可能会更换协议的问题，尽量小依赖协议相关的交互

## Nashorn引擎介绍

在实现之前，我们现了解一下Nashorn JavaScript引擎

JDK内置jjs工具，可以直接在命令行使用jjs执行js脚本

例如，编写一个js脚本

```js
print("hello jjs")
```

保存为hello.js，然后执行

```
$ jjs hello.js
hello jjs
```

如果是编写Java代码

```java
// 获取js 引擎
ScriptEngine engine = new ScriptEngineManager().getEngineByName("nashorn");
// 执行
engine.eval("print('Hello World!');");
```

如果是用高版本的JDK，可以通过依赖引入，[仓库地址](https://central.sonatype.com/artifact/org.openjdk.nashorn/nashorn-core)

不同版本使用nashorn，可以查看[Using-Nashorn-with-different-Java-versions ](https://github.com/szegedi/nashorn/wiki/Using-Nashorn-with-different-Java-versions)

```
<dependency>
    <groupId>org.openjdk.nashorn</groupId>
    <artifactId>nashorn-core</artifactId>
    <version>15.4</version>
</dependency>
```

目前最高版本是15.4

然后在代码中使用

```java
// 通过Nashorn API 创建脚本引擎
NashornScriptEngineFactory nashornScriptEngineFactory = new NashornScriptEngineFactory();

ScriptEngine scriptEngine = nashornScriptEngineFactory.getScriptEngine();
```

nashorn支持ES5，使用ES5也已经完全足够我们业务使用了

### 在JS中调用java方法

有三种方式，第一种是定义Java静态方法

```java
public static int incr(int num) {
	return num+1;
}
```

js脚本调用

```js
var SimpleClazz = Java.type('demo.SimpleClazz');
var num = SimpleClazz.incr(1);
print(num);

// 输出
// 2
```

第二种是实例化类

注意只能调用普通public方法

```java
public int incr2(int num) {
	return num + 2;
}
```

js脚本如下

```js
var SimpleClazz = Java.type('demo.SimpleClazz');
var clazz = new SimpleClazz();
var num = clazz.incr2(1);
print(num);

// 输出
// 3
```

第三种是使用Java的API 

```java
// bindings是一个Map接口
Bindings bindings = new SimpleBindings();
bindings.put("clazz", new SimpleClazz());

String script = "var num = clazz.incr2(1);" +
"print(num);";

// bindings作为执行参数，
engine.eval(script, bindings);

// 输出
// 3
```

通过这种方式也可以类实例传递到js脚本（传递其他值属性也是可以的）

## 开始实现

一开始觉得需要做语法树分析，还简单了解了下antlr4
后面发现简单的正则就够用，不过有些小限制，但是实现目前的需求完全没问题

### 函数支持
后台需要提供一些业务函数，对于使用者来说，可以直接使用
例如设备告警、和发送消息


### 变量拦截
我们的也

### 基础类库

### 递归调用