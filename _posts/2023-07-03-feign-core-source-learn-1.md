---
layout:     post
title:      "feign源码初探"
subtitle:   ""
date:       2023-07-03
author:     "qaqRose"
header-img: ""
tags:
    - 源码
---

## Feign介绍

> Feign 是一个声明式的、模板化的 HTTP 客户端库，它简化了通过 HTTP 协议进行服务间通信的开发   
Feign 提供了一种简洁的编程方式，使得开发者可以定义一个接口，通过注解来描述接口的方法以及与之对应的远程服务的调用。    
Feign 底层使用了基于 HTTP 的 RESTful 服务，并提供了一些默认的编码器和解码器，使得开发者无需手动编写大量的网络请求代码，而只需要关注业务逻辑即可    

以上来自chatGPT

feign使用起来非常简单，只需要定义接口，添加注解就可以实现http请求，spring将其封装在OpenFeign中，作为Spring Cloud体系比较重要的组件   

让我们来学习一下feign的底层是如何实现的吧

## feign 源码

注意：这里的OpenFeign开源是[Feign](https://github.com/OpenFeign/feign)项目， 而不是SpringCloud开源[spring-cloud-openfeign](https://github.com/spring-cloud/spring-cloud-openfeign)项目   
先clone项目   
```shell
git clone git@github.com:OpenFeign/feign.git
```  
项目当前版本是12.4-SNAPSHOT   
可以看到有很多模块，项目代码来到5w+了  

```
|-- core
|-- gson
|-- httpclient
|-- hc5
|-- hystrix
|-- jackson
|-- jackson-jaxb
|-- jackson-jr
|-- jaxb
|-- jaxb-jakarta
|-- jaxrs
|-- jaxrs2
|-- java11
|-- jakarta
|-- json
|-- okhttp
|-- googlehttpclient
|-- ribbon
|-- sax
|-- slf4j
|-- spring4
|-- soap
|-- soap-jakarta
|-- reactive
|-- dropwizard-metrics4
|-- dropwizard-metrics5
|-- kotlin
|-- micrometer
|-- mock
|-- apt-test-generator
|-- annotation-error-decoder
|-- example-github
|-- example-github-with-coroutine
|-- example-wikipedia
|-- example-wikipedia-with-springboot
|-- benchmark
```
为了方便学习，我们切换第一个分支`v1`, 后续都叫v1   
```shell
git checkout -b v1 origin/1.x  # 从1.x切出一个本地分支v1   
```
项目结构如下   
```
.
|-- LICENSE                // Apache2.0许可
|-- build.gradle           // gradle构建
|-- codequality            // checkstyle（忽略）
|-- examples               // 演示项目
|-- feign-core             // feign核心表（重点学习）
|-- feign-ribbon           // ribbon支持
|-- gradle                 // 一些gradle脚本
|-- gradle.properties      // 一些gradle配置
`-- settings.gradle        // gradle聚合项目配置
```
由于feign是16年才转成maven管理依赖   

### maven改造（可选）

gradle我用得不多，为了方便编译测试，所以改成了maven

篇幅问题，pom文件查看访问[feign-core 迁移到maven的pom文件](https://qaqrose.github.io/2023/07/03/feign-core-source-learn-1-maven-move/)

改造之后，结构如下

``` 
|-- examples             
|   `-- feign-example-cli
|-- feign-core           
|   |-- pom.xml
|   |-- src
|-- feign-ribbon
|   |-- pom.xml
|   |-- src
|-- pom.xml
```

### feign请求示例

在进入源码之前，我们通过官方一个简单例子学习一下

假设，我们想要查看某个github项目的贡献者有哪些

Github已经提供了[REST API]([Repositories - GitHub Docs](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-contributors))，所以我们可以直接获取

![获取Github仓库贡献者](/img/feign-core-1/get-github-contributor.png)

使用代码方式

新建代理接口Github类

file: GitHub.java
```java
public interface GitHub {
    @GET
    @Path("/repos/{owner}/{repo}/contributors")
    List<Contributor> contributors(@PathParam("owner") String owner, @PathParam("repo") String repo);
}
```

Contributor类

file: Contributor.java
``` java
public class Contributor {
    public String login;
    public int contributions;
}
```

测试类

file: GitHubExample.java
``` java
public class GitHubExample {

    public static void main(String... args) {
        // <1> 新建代理接口
        GitHub github = Feign.create(GitHub.class, "https://api.github.com", new GsonModule());

        // <2> 调用代理方法（获取netflix的feign项目的贡献者列表）
        List<Contributor> contributors = github.contributors("netflix", "feign");
        for (Contributor contributor : contributors) {
            // 打印输出
            System.out.println(contributor.login + " (" + contributor.contributions + ")");
        }
    }

    @Module(overrides = true, library = true)  // dagger模块
    static class GsonModule {
        @Provides
        @Singleton
        Map<String, Decoder> decoders() {   // <3> 提供http响应解码器 
            return ImmutableMap.of("GitHub", jsonDecoder);
        }
    
        //  gson实现的json解码器
        final Decoder jsonDecoder = new Decoder() {
            Gson gson = new Gson();

            @Override
            public Object decode(String methodKey, Reader reader, TypeToken<?> type) {
                return gson.fromJson(reader, type.getType());
            }
        };
    }
}
```

输出

![贡献者列表响应](/img/feign-core-1/contributor-response.png)

可以看到，我们通过像调用Java方法一样就可以实现远程调用

在`<1>`中，我们通过Feign创建了Github代理类，**下文都将入参类叫做代理类，返回对象叫做代理实例或feign实例**
指定了代理类的请求域名地址，并提供了自定义模块GsonModule，在`<3>`中，GsonModule给Feign提供了解码器Decoder

然后就可以在`<2>`直接调用方法，成功发送了请求和解析了响应

### 前置知识点 

#### dagger 学习

dagger是一个快速的依赖注入Java和Android框架

在feign的v1版本是使用dagger1来管理类的依赖和注入的

简单来说就是通过注解`@Inject`、`@Provides`和`@Module`这三个注解声明依赖关系

其中`@Inject`表示实例由框架注入,

`@Module`注解表名该类为依赖模块类， `@Provides`表示方法可以满足注入依赖的关系

`@Inject`用法类似Spring框架的`@Autowired`
`@Provides`用法类似Spring框架的`@Component`

可以通过[dagger 1 简单教程](https://qaqrose.github.io/2023/07/03/dagger-1-simple-guide/)学习一下


### feign-core  学习

feign-core项目现在还比较小巧，但是已经满足我们学习底层原理的需求了

看看结构

```
|-- main
|   `-- java
|       `-- feign
|           |-- Client.java                      // http客户端接口（内部类默认实现）
|           |-- Contract.java                    // contract协议层
|           |-- Feign.java                       // Feign抽象类，接口代理入口
|           |-- FeignException.java              // 异常
|           |-- MethodHandler.java               // 类方法处理器（代理方法的调用）
|           |-- MethodMetadata.java              // 方法元数据（地址、参数、返回类型等）
|           |-- ReflectiveFeign.java             // Feign的反射实现（唯一实现）
|           |-- Request.java                     // http请求封装
|           |-- RequestTemplate.java             // http请求模板（用于构建请求Request）
|           |-- Response.java                    // http响应封装
|           |-- RetryableException.java          // 重试异常
|           |-- Retryer.java                     // 重试器
|           |-- Target.java                      // 代理对象Target
|           |-- Wire.java                        // 日志封装
|           `-- codec                            // 编码和解码
|               |-- BodyEncoder.java             // http body编码器 
|               |-- Decoder.java                 // 解码器
|               |-- Decoders.java                // 匹配解码器实现
|               |-- ErrorDecoder.java            // 错误解码器
|               |-- FormEncoder.java             // 表单解码器
|               |-- SAXDecoder.java              // SAX解码器
|               `-- ToStringDecoder.java         // 字符串解码器
`-- test
    `-- java
        `-- feign
            |-- ContractTest.java
            |-- DefaultRetryerTest.java
            |-- FeignTest.java
            |-- RequestTemplateTest.java
            |-- TrustingSSLSocketFactory.java
            |-- codec
            `-- examples
```

可以看到v1版本的feign还是非常小巧的，只有3000行代码不到

非常推荐通过源码学习

我们来看看创建feign实例的过程和方法调用的过程发生了什么

#### 创建feign实例

首先是创建实例

![创建feign实例](/img/feign-core-1/create-feign-instance.png)

通过上图可以看出创建feign实例的过程就是解析代理并缓存的过程

其中Target是一个简单的泛型接口

file: Target.java
```java
public interface Target<T> extends Function<RequestTemplate, Request> {
    /**
     * 保存代理类类型
     */
    Class<T> type();

    /* 配置实例的名字，无特殊要求 */
    String name();

    /* 返回实例对象的http url */
    String url();

    /** 从请求模板生成一个请求 */
    @Override
    public Request apply(RequestTemplate input);
}

```
主要作用是保存代理类的类型，方便后面解析处理

通过`Contract`层将类方法解析成请求方法元数据MethodMetadata

file: MethodMetadata.java
```java
public final class MethodMetadata implements Serializable {

  /**
   * 方法的javadoc
   */
  private String configKey;

  /**
   * 方法的返回类型，使用TypeToken可以保存泛型类型
   */
  private transient TypeToken<?> returnType;

  /**
   * 方法参数支持 {@code URI}
   * urlIndex设置 URI在方法参数列表的下标位置
   * 没有则为空
   */
  private Integer urlIndex;
  /**
   * request body 在方法参数列表的下标位置
   * 没有则为空
   */
  private Integer bodyIndex;

  /**
   * 内置一个request模板，方便可以发起请求
   */
  private RequestTemplate template = new RequestTemplate();

  /**
   * 表单参数名称
   */
  private List<String> formParams = Lists.newArrayList();

  /**
   * 存储请求方法的一些参数的位置下标（顺序）和名称，蚕例如path或query
   * key表示位置下标，value表示 PathParam 的name 或 PathParam 的name
   */
  private SetMultimap<Integer, String> indexToName = LinkedHashMultimap.create();

  //省略getter/setter
}
```

思考一下，这里为什么不直接解析成MethodHandler，而是要加一层MethodMetadata

MethodMetadata本身只是一个pojo，并没有什么逻辑


我的理解是，这样可以把Contract和MethodHandler，因为Contract是解析方法的协议层，
为了扩展性，Contract层最好对接一个简单的对象（pojo），而MethodHandler已经耦合了很多组件了，
能尽量拆开还是拆开好

扩展一下，`spring-cloud-openfeign`就是通过扩展contract层让feign支持`spring-mvc`的注解
详情查看[SpringMvcContract](https://github.com/spring-cloud/spring-cloud-openfeign/blob/main/spring-cloud-openfeign-core/src/main/java/org/springframework/cloud/openfeign/support/SpringMvcContract.java)，还有[gitee](https://gitee.com/RemoteControl/spring-cloud-openfeign/blob/3.0.x/spring-cloud-openfeign-core/src/main/java/org/springframework/cloud/openfeign/support/SpringMvcContract.java)国内版的

Contract的代码主要直接一些判断，这里展示一部分

file: Contract.java
```java
  public static MethodMetadata parseAndValidatateMetadata(Method method) {
    MethodMetadata data = new MethodMetadata();
    // 保存方法返回的泛型类型
    data.returnType(TypeToken.of(method.getGenericReturnType()));
    // 解析方法的javadoc方法串
    data.configKey(Feign.configKey(method));

    // 方法解析
    for (Annotation methodAnnotation : method.getAnnotations()) {
      Class<? extends Annotation> annotationType = methodAnnotation.annotationType();
      HttpMethod http = annotationType.getAnnotation(HttpMethod.class);
      if (http != null) {
        // http方法重复校验
        checkState(data.template().method() == null,
            "Method %s contains multiple HTTP methods. Found: %s and %s", method.getName(), data.template()
            .method(), http.value());
        data.template().method(http.value());
      } else if (annotationType == RequestTemplate.Body.class) {
        String body = RequestTemplate.Body.class.cast(methodAnnotation).value();
        if (body.indexOf('{') == -1) {
          data.template().body(body);
        } else {
          data.template().bodyTemplate(body);  // 请求body模板
        }
      } else if (annotationType == Path.class) {
        // http 请求path, 追加到url
        data.template().append(Path.class.cast(methodAnnotation).value());
      } else if (annotationType == Produces.class) {
        // 解析http请求头  Content-Type
        data.template().header(CONTENT_TYPE, Joiner.on(',').join(((Produces) methodAnnotation).value()));
      } else if (annotationType == Consumes.class) {
        // 解析http请求头 Accept
        data.template().header(ACCEPT, Joiner.on(',').join(((Consumes) methodAnnotation).value()));
      }
    }

    // 省略 参数注解处理和参数处理的代码

    return data;
}
```
那么最重要的MethodHandler是在哪里构建的呢

MethodHandler内部有很多的组件

file: MethodHandler.java
```java
final class MethodHandler {
/**
   * 方法元数据，通过Contract层解析得到
   */
  private final MethodMetadata metadata;
  /**
   * 代理类实例
   */
  private final Target<?> target;
  /**
   * http客户端接口
   */
  private final Client client;
  /**
   * 重试组件，因为组件的实现是有状态的，每次请求都需要重新生成，
   * 所以使用Provider方式注入
   */
  private final Provider<Retryer> retryer;
  /**
   * 日志封装
   */
  private final Wire wire;
  /**
   * 处理方法参数，完善RequestTemplate
   */
  private final Function<Object[], RequestTemplate> buildTemplateFromArgs;
  /**
   * http请求配置
   */
  private final Options options;
  /**
   * 解码器
   */
  private final Decoder decoder;
  /**
   * 错误解码器
   */
  private final ErrorDecoder errorDecoder;  

  /**
   * 构造器是私有的
   */
  private MethodHandler(Target target, Client client, Provider<Retryer> retryer, Wire wire, MethodMetadata metadata,
                        Function<Object[], RequestTemplate> buildTemplateFromArgs, Options options, Decoder decoder, ErrorDecoder errorDecoder) {
    this.target = checkNotNull(target, "target");
    this.client = checkNotNull(client, "client for %s", target);
    this.retryer = checkNotNull(retryer, "retryer for %s", target);
    this.wire = checkNotNull(wire, "wire for %s", target);
    this.metadata = checkNotNull(metadata, "metadata for %s", target);
    this.buildTemplateFromArgs = checkNotNull(buildTemplateFromArgs, "metadata for %s", target);
    this.options = checkNotNull(options, "options for %s", target);
    this.decoder = checkNotNull(decoder, "decoder for %s", target);
    this.errorDecoder = checkNotNull(errorDecoder, "errorDecoder for %s", target);
  }

}
```
MethodHandler是方法调用的内部入口，依赖这些基础组件来实现功能，
通过Factory方法来创建，将组件作为参数传入

file: MethodHandler.java
```java
/**
* 内部类
*/
static class Factory {

    private final Client client;               // http请求客户端
    private final Provider<Retryer> retryer;   // 有状态的重试器
    private final Wire wire;                   // 日志封装

    /**
     * 通过容器注入
     */
    @Inject Factory(Client client, Provider<Retryer> retryer, Wire wire) {
      this.client = checkNotNull(client, "client");
      this.retryer = checkNotNull(retryer, "retryer");
      this.wire = checkNotNull(wire, "wire");
    }

    public MethodHandler create(Target<?> target, MethodMetadata md,
                                Function<Object[], RequestTemplate> buildTemplateFromArgs, Options options, Decoder decoder, ErrorDecoder errorDecoder) {
      return new MethodHandler(target, client, retryer, wire, md, buildTemplateFromArgs, options, decoder, errorDecoder);
    }
}

```
ReflectiveFeign.ParseHandlersByName类的apply方法调用了工厂方法creata来创建MethodHandler

file: ReflectiveFeign.java
```java
/**
 * 将代理类解析成MethodHandler映射
 */
@Override
public Map<String, MethodHandler> apply(Target key) {
  // 将代理类的方法解析成MethodMetadata元数据
  Set<MethodMetadata> metadata = parseAndValidatateMetadata(key.type());
  ImmutableMap.Builder<String, MethodHandler> builder = ImmutableMap.builder();
  // 将MethodMetadata转换成MethodHandler
  for (MethodMetadata md : metadata) {
    // options 是 http 一些配置
    Options options = forMethodOrClass(this.options, md.configKey());
    if (options == null) {
      options = new Options();
    }
    // 解码器
    Decoder decoder = forMethodOrClass(decoders, md.configKey());
    if (decoder == null
            && (md.returnType().getRawType() == void.class
            || md.returnType().getRawType() == Response.class)) {
      // 方法返回类型是 Void或者Response，使用默认ToStringDecoder解析器
      decoder = new ToStringDecoder();
    }
    if (decoder == null) {
      throw noConfig(md.configKey(), Decoder.class);
    }
    // 错误解码器
    ErrorDecoder errorDecoder = forMethodOrClass(errorDecoders, md.configKey());
    if (errorDecoder == null) {
      errorDecoder = ErrorDecoder.DEFAULT;
    }
    Function<Object[], RequestTemplate> buildTemplateFromArgs;
    if (!md.formParams().isEmpty() && !md.template().bodyTemplate().isPresent()) {
      FormEncoder formEncoder = forMethodOrClass(formEncoders, md.configKey());
      if (formEncoder == null) {
        throw noConfig(md.configKey(), FormEncoder.class);
      }
      // 表单编码模板
      buildTemplateFromArgs = new BuildFormEncodedTemplateFromArgs(md, formEncoder);
    } else if (md.bodyIndex() != null) {
      BodyEncoder bodyEncoder = forMethodOrClass(bodyEncoders, md.configKey());
      if (bodyEncoder == null) {
        throw noConfig(md.configKey(), BodyEncoder.class);
      }
      // body编码模板
      buildTemplateFromArgs = new BuildBodyEncodedTemplateFromArgs(md, bodyEncoder);
    } else {
      buildTemplateFromArgs = new BuildTemplateFromArgs(md);
    }
    // 用工程创建MethodHandler
    builder.put(md.configKey(),
        factory.create(key, md, buildTemplateFromArgs, options, decoder, errorDecoder));
  }
  return builder.build();
}
```
可以看到


#### 


#### 庖丁解牛

让我们带着问题去寻找答案吧  
```java
// <1> Feign的create方法创建了接口实例
GitHub github = Feign.create(GitHub.class, "https://api.github.com", new GsonModule());

// <2> 接口实例的方法执行
List<Contributor> contributors = github.contributors("netflix", "feign");
```
我们想知道`Feign.create`这个方法做了什么事情，返回的`github`实例有什么特殊的地方
为什么执行`contributors`就可以发送http请求，并解析响应的请求，如果发生异常怎么处理

让我们带着疑问与困惑进入源码，寻找答案吧


```java
/**
 * 创建一个http api 实例
 * @param apiType  实例类型
 * @param url      域名地址(直接合方法上的地址拼接)
 * @param modules  dagger模块（使用门槛还是比较高，提供了 GsonModule
 * @return
 * @param <T>
 */
public static <T> T create(Class<T> apiType, String url, Object... modules) {
    return create(new HardCodedTarget<T>(apiType, url), modules);
}


public static <T> T create(Target<T> target, Object... modules) {
    return create(modules).newInstance(target);
}   

public static Feign create(Object... modules) {
    Object[] modulesForGraph = ImmutableList.builder() //
      .add(new Defaults()) //  默认模块实现
      .add(new ReflectiveFeign.Module()) // 反射实现模块
      .add(Optional.fromNullable(modules).or(new Object[]{})).build().toArray();
    return ObjectGraph.create(modulesForGraph).get(Feign.class);
}

```
