---
title: Feign 源码学习「1」
layout: info
commentable: true
date: 2023-07-03
mathjax: true
mermaid: true
tags: [Flyway]
categories: Flyway
description: 
---


## 什么是 Feign

> Feign 是一个声明式的、模板化的 HTTP 客户端库，它简化了通过 HTTP 协议进行服务间通信的开发   
Feign 提供了一种简洁的编程方式，使得开发者可以定义一个接口，通过注解来描述接口的方法以及与之对应的远程服务的调用。    
Feign 底层使用了基于 HTTP 的 RESTful 服务，并提供了一些默认的编码器和解码器，使得开发者无需手动编写大量的网络请求代码，而只需要关注业务逻辑即可    

以上来自 chatGPT

简单来说

Feign 的使用非常简单，只要定义接口，就可以实现 http 请求

让我们来学习一下 `Feign` 的底层是如何实现的吧

## 前置知识点 

### dagger 

dagger 是一个快速的依赖注入 Java 和 Android 框架

在 feign 的 v1 版本是使用 dagger1 来管理类的依赖和注入的

简单来说就是通过注解 `@Inject`、`@Provides` 和 `@Module` 这三个注解声明依赖关系

其中 `@Inject` 表示实例由框架注入,

`@Module` 注解表名该类为依赖模块类，`@Provides` 表示方法可以满足注入依赖的关系

`@Inject` 用法类似Spring框架的 `@Autowired`
`@Provides` 用法类似Spring框架的 `@Component`

可以通过 [dagger 1 简单教程](https://qaqrose.github.io/2023/07/03/dagger-1-simple-guide/)学习一下


## 获取 Feign 源码

注意：这里的 `Feign` 是 `OpenFeign` 开源的 [feign](https://github.com/OpenFeign/feign) 项目， 而不是 `Spring-Cloud` 开源 [spring-cloud-openfeign](https://github.com/spring-cloud/spring-cloud-openfeign) 项目   

先 clone 项目   

```shell
git clone git@github.com:OpenFeign/feign.git
```  

项目当前版本是 `12.4-SNAPSHOT`
可以看到有很多模块，且项目代码量已经来到 5w+ 了  

为了方便学习，我们从1.x切出一个本地分支 `v1`，下文的代码来自 `v1`

```shell
git checkout -b v1 origin/1.x   
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

由于 `feign` 是16年才转成 `Maven` 管理依赖   

### Maven 改造（可选）

gradle 用得不多，为了方便编译测试，所以改成了 maven

篇幅问题，pom文件查看访问 [feign-core 迁移到maven的pom文件](https://qaqrose.github.io/2023/07/03/feign-core-source-learn-1-maven-move/)

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

## Feign 简单例子

在进入源码之前，我们通过官方一个 demo 学习一下

假设，我们想要查看某个 github 项目的贡献者有哪些

Github 已经提供了 <a href="https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-contributors" target="_blank">REST API</a> ，可以直接请求，如下图

![获取Github仓库贡献者](/images/feign-core-1/get-github-contributor.png)

我们使用 Feign 方式来完成这次请求

新建 Github 类

```java
public interface GitHub {
    @GET
    @Path("/repos/{owner}/{repo}/contributors")
    List<Contributor> contributors(@PathParam("owner") String owner, @PathParam("repo") String repo);
}
```

新建Contributor类

``` java
public class Contributor {
    public String login;
    public int contributions;
}
```

新建GitHubExample类

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

    @Module(overrides = true, library = true)  
    static class GsonModule {                       // <3> GsonModule 模块
        @Provides       // 方法的返回可作为注入实例
        @Singleton      // 单例，全局唯一
        Map<String, Decoder> decoders() {   // 提供http响应解码器 
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

![贡献者列表响应](/images/feign-core-1/contributor-response.png)

可以看到，我们像调用 Java 方法一样就可以实现远程调用

下面分析代码

在 `<1>` 中，通过 Feign 创建了 `Github` 代理类，**下文都将将参数（如Github.class）叫做代理类，返回对象叫做代理实例或 feign 实例**
，指定了代理类的请求域名地址（`https://api.github.com`），这样就可以不用在方法声明地址参数 `Uri`，
并提供了自定义模块 GsonModule 

在 `<2>`中，`github.contributors` 方法的底层是执行了Feign的动态代理类的方法，所以可以通过 http 发送了请求并将 json 响应解析到 `List<Contributor>`

在 `<3>` 将 `GsonModule` 类声明为一个 dagger module，并提供了一个 可处理 json 响应的 `Decoder` 覆盖 feign 提供的默认解码器，由于使用这个 dagger module，不在同一个包下，所以配置 `library = true`， 而
`overrides = true` 则允许覆盖其他 `@Module` 的方法


## feign-core 的结构

feign-core 项目（`v1`）现在还比较小巧，代码只有3千行不到，但是各个核心划分都比较成熟

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
```

梳理一下

### feign-core 架构图

![feign-core架构图](/images/feign-core-1/feign-architecture.png)

这里我只是按照我自己的理解将 feign 画出分层架构（只是为了更好理解和行文，如果有不同意见，欢迎评论区讨论）

tip: 下面源码解析都是围绕架构图来进行的，建议边阅读边回顾 feign-core 架构图

### feign 接口层

feign 接口层有两个组件，`Target` 和 `Feign` 

`Feign` 是一个抽象接口，主要作用就创建 Feign实例，可以理解是一个 Builder 工厂，把内部复杂的逻辑封装起来，暴露几个简单的方法，让用户可以很轻易就构建 Feign 实例

```java
public abstract class Feign {

  /**
   * 新建代理实例
   */
  public abstract <T> T newInstance(Target<T> target);

  /**
   * 创建一个代理类实例
   * @param apiType  实例类型
   * @param url      域名地址(直接合方法上的地址拼接)
   * @param modules  dagger模块（使用门槛还是比较高，提供了 GsonModule
   */
  public static <T> T create(Class<T> apiType, String url, Object... modules) {
    return create(new HardCodedTarget<T>(apiType, url), modules);    
  }

  public static <T> T create(Target<T> target, Object... modules) {
    return create(modules).newInstance(target);
  }

  public static Feign create(Object... modules) {
    Object[] modulesForGraph = ImmutableList.builder() 
        .add(new Defaults())                    // 默认模块实现
        .add(new ReflectiveFeign.Module())      // 反射实现模块
        .add(Optional.fromNullable(modules).or(new Object[]{}))
        .build().toArray();
    return ObjectGraph.create(modulesForGraph).get(Feign.class);  // dagger 对象依赖图
  }
}
```

在前面的例子中, 我们调用了 `create(Class<T>, String, Object)` 方法，

最终来到了 `create(Object... modules)`方法，通过 dagger 框架获取 Feign 的实例，

可以看到，feign 给我们提供了两个默认的模块，Defaults 模块都是一些简单的实现

```java
@dagger.Module(complete = false, injects = Feign.class, library = true)
  public static class Defaults {

    @Provides SSLSocketFactory sslSocketFactory() {
      return SSLSocketFactory.class.cast(SSLSocketFactory.getDefault());
    }

    @Provides Client httpClient(Client.Default client) { return client; }

    @Provides Retryer retryer() { return new Retryer.Default(); }

    @Provides Wire noOp() { return new NoOpWire(); }

    @Provides Map<String, Options> noOptions() { return ImmutableMap.of(); }

    @Provides Map<String, BodyEncoder> noBodyEncoders() { return ImmutableMap.of(); }

    @Provides Map<String, FormEncoder> noFormEncoders() { return ImmutableMap.of(); }

    @Provides Map<String, Decoder> noDecoders() { return ImmutableMap.of(); }

    @Provides Map<String, ErrorDecoder> noErrorDecoders() { return ImmutableMap.of();}
  }
```
基本都是空实现，所以需要我们的自定义模块 `GsonModule`

另一个 `ReflectiveFeign.Module` 静态类就提供了 Feign 实例依赖

```java
public class ReflectiveFeign extends Feign {

  @dagger.Module(complete = false,// Config
      injects = Feign.class, library = true// provides Feign
  )
  public static class Module {

    @Provides Feign provideFeign(ReflectiveFeign in) {
      return in;
    }
  }
}
```

可以看到 ReflectiveFeign 提供了自身做为 Feign 的实例

Target 作为 `newInstance(Target<T> target)`方法的参数，其实就只是保存了代理类类型而已
方便后面解析代理类

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

    // 内部类，硬编码Target，只是保存了代理类类型
    public static class HardCodedTarget<T> implements Target<T> {
        private final Class<T> type;
        private final String name;
        private final String url;

        public HardCodedTarget(Class<T> type, String url) {
            this(type, url, url);
        }

        public HardCodedTarget(Class<T> type, String name, String url) {
            this.type = checkNotNull(type, "type");
            this.name = checkNotNull(Strings.emptyToNull(name), "name");
            this.url = checkNotNull(Strings.emptyToNull(url), "url");
        }

        @Override
        public Class<T> type() {
            return type;
        }

        @Override
        public String name() {
            return name;
        }

        @Override
        public String url() {
            return url;
        }

        @Override
        public Request apply(RequestTemplate input) {
            if (input.url().indexOf("http") != 0)
                input.insert(0, url());
            return input.request();
        }
    }
}
```

### contract 层

contract 层就一个组件 `Contract`，单独把它划分一个层次是因为感觉它比较独立，

它实现了 `JSR-311` 部分注解的功能，例如 `@Path`、`@Get`、`@Post`、`@PathParam` 等

![JSR-311](/images/feign-core-1/jsr311.png)

`Contract` 的主要作用是将类方法解析成请求方法元数据 `MethodMetadata`

```java
public final class Contract {   
    // 解析method
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

        Class<?>[] parameterTypes = method.getParameterTypes();
        
         // 参数注解
        Annotation[][] parameterAnnotationArrays = method.getParameterAnnotations();
        int count = parameterAnnotationArrays.length;  // 参数个数
        for (int i = 0; i < count; i++) {
          boolean hasHttpAnnotation = false;

          Class<?> parameterType = parameterTypes[i];
          Annotation[] parameterAnnotations = parameterAnnotationArrays[i];
          if (parameterAnnotations != null) {
            for (Annotation parameterAnnotation : parameterAnnotations) {
                // 省略处理参数注解的代码
            }
    
          }

          if (parameterType == URI.class) {
            data.urlIndex(i);   // 表示url参数的下标（方法的url参数优先级最高）
          } else if (!hasHttpAnnotation) {
            data.bodyIndex(i);     // json body的参数下标
          }
        }

        return data;
    }
}
```

MethodMetadata 只是一个简单的 pojo，作用是将contract 层和方法处理层隔离来

减少核心业务逻辑的耦合，代码如下（主要是以下字段组成）

```java
public final class MethodMetadata implements Serializable {
  MethodMetadata() {}

  private String configKey;    // 方法全限定名称

  private transient TypeToken<?> returnType;  // 方法的返回类型

  private Integer urlIndex;  // url参数的下标，没有则为空

  private Integer bodyIndex;   // json实体类的下标，没有则为空
 
  private RequestTemplate template = new RequestTemplate();  // 请求模板

  private List<String> formParams = Lists.newArrayList();  //表单参数字段名

  /**
   * 存储请求方法的一些参数的位置下标（顺序）和名称，蚕例如path或query
   * key表示位置下标，value表示 PathParam 的name 或 PathParam 的name
   */
  private SetMultimap<Integer, String> indexToName = LinkedHashMultimap.create();

  // 省略getter setter
}
```

### 方法处理层

这一层有三个组件，其中 `MethodHandler` 是整个框架的核心，它聚合了许多其他组件来完成方法的执行

```java
final class MethodHandler {
  private final MethodMetadata metadata;  // 方法元数据，通过Contract层解析得到
  private final Target<?> target;   // 代理类实例
  private final Client client;   // http客户端接口
  /**
   * 重试组件，因为组件的实现是有状态的，每次请求都需要重新生成，
   * 所以使用Provider方式注入
   */
  private final Provider<Retryer> retryer;
  private final Wire wire;   // 日志扩展
  private final Function<Object[], RequestTemplate> buildTemplateFromArgs;  // 处理方法参数
  private final Options options;   // http请求配置
  private final Decoder decoder;   // 解码器
  private final ErrorDecoder errorDecoder;    // 错误解码器
}
```
MethodHandler 包含了这么多东西，都是通过构造方法传入的

而且外部的入参则是通过依赖注入框架来获取

MethodHandler 对象实例的构造过程如下（ `ReflectiveFeign.ParseHandlersByName` 的 apply 方法）

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

其中的 decoders、errorDecoders、options 等都是使用注入方式构造

可由内部提供默认的实例或外部 Module 注入

```java
static final class ParseHandlersByName {
   @Inject
    ParseHandlersByName(Map<String, Options> options,
                        Map<String, BodyEncoder> bodyEncoders,
                        Map<String, FormEncoder> formEncoders,
                        Map<String, Decoder> decoders,
                        Map<String, ErrorDecoder> errorDecoders,
                        Factory factory) {
      this.options = options;
      this.bodyEncoders = bodyEncoders;
      this.formEncoders = formEncoders;
      this.decoders = decoders;
      this.factory = factory;
      this.errorDecoders = errorDecoders;
    }
}
```


首先通过 JDK 动态代理，让代理类最终执行方法走 `MethodHandler` 的 `invoke` 方法

```java
public Object invoke(Object[] argv) throws Throwable {
    // 通过方法参数构建请求模板
    RequestTemplate template = buildTemplateFromArgs.apply(argv);
    // 重试器是有状态的，所以这里需要重新get (内部是new)
    Retryer retryer = this.retryer.get();  
    while (true) {
      try {
        // 执行http请求并解码响应
        return executeAndDecode(metadata.configKey(), template, metadata.returnType());
      } catch (RetryableException e) {
        retryer.continueOrPropagate(e);
        continue;
      }
    }
}
```

其中，比较重要的 `executeAndDecode` 方法，直接看代码

```java 
/**
 * 执行请求并解码
 */
public Object executeAndDecode(String configKey, RequestTemplate template, TypeToken<?> returnType)
      throws Throwable {
    // 经过target包一层，其实RequestTemplate就内置一个Request
    Request request = target.apply(new RequestTemplate(template));
    // 日志扩展
    wire.wireRequest(target, request);
    // http 请求
    Response response = execute(request);
    try {
      response = wire.wireAndRebufferResponse(target, response);
      // 正常http响应
      if (response.status() >= 200 && response.status() < 300) {
        if (returnType.getRawType().equals(Response.class)) {
            // 直接返回原生
          return response;
        } else if (returnType.getRawType() == URI.class && !response.body().isPresent()) {
          ImmutableList<String> location = response.headers().get(LOCATION);
          if (!location.isEmpty())
            return URI.create(location.get(0));
        } else if (returnType.getRawType() == void.class) {
          return null;
        }
        // 解码器
        return decoder.decode(configKey, response, returnType);
      } else {
        // 错误解码器
        return errorDecoder.decode(configKey, response, returnType);
      }
    } catch (Throwable e) {
      ensureBodyClosed(response);  // 关闭响应流
      if (IOException.class.isInstance(e))
        throw errorReading(request, response, IOException.class.cast(e));
      throw e;
    }
  }

```

通过依赖下层http处理层和 `Retryer` 和 `Decoder` 的能力来完成方法调用

这里的组件都是可以接口形式，所以扩展性都比价好

### http 处理层

http 处理层主要是对 HTTP 请求做了一层简单的封装

对外提供了一个简单的接口

```java
public interface Client {
  /**
   * 执行http请求
   */
   Response execute(Request request, Options options) throws IOException;
}

```
Request 是一个 pojo 类，定义了 http 请求的基本字段

```java
public final class Request {
  private final String method;      // 请求方法, 例如 GET/POST/PUT/DELETE 等
  private final String url;         // 请求地址, 完整链接，包含参数等
  private final ImmutableListMultimap<String, String> headers;  // http 请求头
  private final Optional<String> body;   // http request body
}
```

Options 可以配置 http 的请求超时参数

```java
public static class Options {
    private final int connectTimeoutMillis;  // 连接超时
    private final int readTimeoutMillis;     // 响应超时  
}
```
在 v1 版本的 `Client` 是 jdk net 包来实现 http 请求功能

第一步先是初始化连接实例，配置一些请求参数

```java
HttpURLConnection convertAndSend(Request request, Options options) throws IOException {
  // 连接实例
  final HttpURLConnection connection = (HttpURLConnection) new URL(request.url()).openConnection();
  if (connection instanceof HttpsURLConnection) {
    HttpsURLConnection sslCon = (HttpsURLConnection) connection;
    sslCon.setSSLSocketFactory(sslContextFactory.get());   // http 支持
  }
  // 一些http请求参数
  connection.setConnectTimeout(options.connectTimeoutMillis());
  connection.setReadTimeout(options.readTimeoutMillis());
  connection.setAllowUserInteraction(false);
  connection.setInstanceFollowRedirects(true);
  connection.setRequestMethod(request.method());

  Integer contentLength = null;
  for (Entry<String, String> header : request.headers().entries()) {
    if (header.getKey().equals(CONTENT_LENGTH))
      contentLength = Integer.valueOf(header.getValue());
    connection.addRequestProperty(header.getKey(), header.getValue());
  }

  if (request.body().isPresent()) {
    if (contentLength != null) {
      connection.setFixedLengthStreamingMode(contentLength);
    } else {
      connection.setChunkedStreamingMode(8196);
    }
    connection.setDoOutput(true);
    // 将输出流写入到body中
    new ByteSink() {
      public OutputStream openStream() throws IOException {
        return connection.getOutputStream();
      }
    }.asCharSink(UTF_8).write(request.body().get());
  }
  return connection;
}
```

然后发送请求

```java
Response convertResponse(HttpURLConnection connection) throws IOException {
    int status = connection.getResponseCode();
    String reason = connection.getResponseMessage();

    ImmutableListMultimap.Builder<String, String> headers = ImmutableListMultimap.builder();
    for (Map.Entry<String, List<String>> field : connection.getHeaderFields().entrySet()) {
      // response message
      if (field.getKey() != null)
        headers.putAll(field.getKey(), field.getValue());
    }

    Integer length = connection.getContentLength();
    if (length == -1)
      length = null;
    InputStream stream;
    if (status >= 400) {
      stream = connection.getErrorStream();
    } else {
      // 获取响应输入流
      stream = connection.getInputStream();
    }
    Reader body = stream != null ? new InputStreamReader(stream) : null;
    // 从reader中创建Response
    return Response.create(status, reason, headers.build(), body, length);
  }

```

至此 http 请求完成，返回的 Response 由外部决定由什么 `Decoder` 来解码处理

在上面的例子，我们使用 Gson 将响应 body 解析成 返回类型


## 结语

通过阅读源码，我们了解到 feign-core 就是通过 JDK 的动态代理和 Java 反射实现了远程过程调用，主要流程就是类方法解析、构造请求模板、生成请求、执行 http 方法、http 响应解码等过程，当然更重要是学习如何编写一个扩展性更好的软件，在软件迭代初期，怎么去更好得架构和设计

就我个人的理解，应该还是得从简洁出发（最小实现），当然简洁不意味着简单，而是让功能恰到好处，在封装和复杂之间做出取舍，在实现和定义之间也要慎重衡量

feign-core 第一版本已经是10年前的事情了，目前的版本已经来到 `12.4-SNAPSHOT` 了
而且 `spring-cloud-feign` 也变得非常复杂，源码解析需要花费更多时间

日拱一卒，功不唐捐

