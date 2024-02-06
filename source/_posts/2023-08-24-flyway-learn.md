---
layout:     post
title:      "Flyway 快速上手"
categories: [Flyway, 数据库版本]
subtitle:   ""
keywords: 
mermaid: false
sequence: false
flow: false
mathjax: false
mindmap: false
mindmap2: false
---

## 简介

Flyway 是一个开源的数据库版本管理工具，并且支持市面上大多数数据库
企业开发中，一般会使用 Git 来做代码版本管理，而数据库同样也是有版本的
例如新增表、增加索引、修改表结构等，为了确保项目多个环境的一致性
也可以避免版本发布时，由于忘发或漏发的情况导致 bug 的产生

## Spring Boot Demo
这里使用一个 Spring Boot 项目作为演示，项目代码见[github](https://github.com/qaqRose/flyway-learn)

项目版本
- spring boot 3.1.2
- jdk 17
- mysql 8.0

整个项目结构如下

```
├── pom.xml                                             //  maven pom文件
└── src
    └── main
        ├── java
        │   └── com
        │       └── example
        │           └── flywayboot3
        │               └── FlywayBoot3Application.java   // SpringBoot 启动文件
        └── resources
            ├── application.yml                           // SpringBoot 配置文件
            └── db
                └── migration                             // 迁移脚本          
                    ├── R__inc_user.sql                   // 可重复迁移脚本
                    ├── V1__test_ddl.sql                  // v1 脚本
                    └── V2__user_ddl.sql                  // v2 脚本

```

maven 依赖如下

```xml
 <dependencies>
    <!-- web 容器-->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>    
    </dependency>

    <!-- jdbc连接, flyway自动配置需要用到 JDBC连接 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-jdbc</artifactId>
    </dependency>
    
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>

    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-core</artifactId>
    </dependency>

    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-mysql</artifactId>
    </dependency>
</dependencies>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>3.1.2</version>
            <scope>import</scope>
            <type>pom</type>
        </dependency>
    </dependencies>
</dependencyManagement>
```

配置 MySQL 数据库连接

application.yml
```yml
spring:
  datasource:
    url: jdbc:mysql://192.168.1.83:3306/flyway?useUnicode=true&characterEncoding=utf8&serverTimezone=GMT
    username: root
    password: 123456
    driver-class-name: com.mysql.cj.jdbc.Driver
```

接着启动项目，就可以到 flyway 的一些日志信息， 如下

![控制台输出](/images/flyway/application-start.png)

也可以看到数据库新增一张表

![flyway表](/images/flyway/flyway-history-table.png)

### schame history 表
现在整个数据库之后一张 `flyway_schame_history` 的表，如果我们需要新增一张表，要怎么操作呢

因为我们使用的 MySQL 数据库，所以新增表脚本如下

V1.0__user_ddl.sql
```sql
CREATE TABLE `user`  (
     `id` bigint NOT NULL AUTO_INCREMENT ,
     `name` varchar(32) NULL ,
     PRIMARY KEY (`id`) USING BTREE
);
```

我们在项目的 `resources` 新增 `db/migration/V1.0__user_dll.sql`
然后启动项目
可以看到表 `flyway_schame_history` 增加一条版本为1.0的记录，同时数据库新增一张user表

![flyway表](/images/flyway/flyway_v1.png)

简单说明各个字段的含义

|  字段   | 描述 |
|  ----  | ----  |
| install_rank  | 主键，递增 |
| version  | 数据库版本 |
| description  | 描述 |
| type | 操作类型 | 
| script | 脚本文件名称 | 
| checksum | 校验哈希 |
| installed_by | 执行用户 | 
| installed_on | 执行日期 |
| execution_time | 执行耗时 |
| success | 是否已执行 |

可以看到我们的脚本名称被分隔成几部分 `V1.0__user_dll.sql`

以 V 开头，双下划线结束，最后文件，格式如下
`V{version}__{description}.{type}`
flyway 会忽略低于

flyway 默认会在从 `classpath:db/migration` 查找脚本

### flyway 一些常用配置

在 spring-boot 中已经帮我们自动配置了 flyway, 并抽出一些配置项
让我们可以自己管理 
这里只对比较常用的配置项目说明
详见 org.springframework.boot.autoconfigure.flyway.FlywayProperties
```java
@ConfigurationProperties(prefix = "spring.flyway")
public class FlywayProperties { 
    /**
     * 是否开启flyway, 默认开启
     */
    private boolean enabled = true;

    /**
     * sql脚本的位置，默认在db/migration目录下
     */
    private List<String> locations = new ArrayList<>(Collections.singletonList("classpath:db/migration"));

    /**
     * flyway history表名， 默认是flyway_schema_history
     * 支持占位符
     */
    private String table = "flyway_schema_history";

    /**
     * 基线版本，默认是1 
     * 即从V1开始，低于1的版本会忽略（前提是数据库已经存在schame）
     */
    private String baselineVersion = "1";

    /**
     * 基线版本的描述，用于插入基线行的 description 字段
     */
    private String baselineDescription = "<< Flyway Baseline >>";

    /**
     * 当 schame 非空时，是否自动调用 baseline
     * 如果配置为了 false，发现非空schame且找不到 flyway table 会直接报错
     */
    private boolean baselineOnMigrate;

    /**
     * 是否禁用清除数据库，默认禁用
     */
    private boolean cleanDisabled = true;

    /**
     * 是否允许不按顺序迁移
     */
    private boolean outOfOrder;
      
}
```

## 迁移

在 flyway 中，所有数据库的变化都叫迁移( Migrations )
迁移类型有两种，分别是**版本迁移（Versioned migrations）**，或**可重复迁移（Repeatable migrations）**
还有一种撤销迁移（Undo migrations）是企业版，这里不做说明

版本迁移（Versioned migrations）有一个 version, 一个 description 和 一个 checksum。
首先 version 必须是唯一的，description 方便用户了解迁移脚本的内容，checksum 是用于校验文件是否更改，
程序启动之后，如果发现 Versioned migrations 的文件内容发生更改，会抛出异常

命名规范如下，前缀V + 版本号（数字+下划线/点）+ 描述 + 分隔符（双下划线） + 文件类型（.sql)
![版本迁移](/images/flyway/versioned_migrations.png)

可重复迁移（Repeatable migrations）一个 description 和 一个 checksum，没有version
当checksum改变时（相当于脚本变化），就是插入一条记录，并执行一次

命名规范如下，前缀R + 描述 + 分隔符（双下划线） + 文件类型（.sql)
![可重复迁移](/images/flyway/repeatable_migrations.png)


详见[Migraions](https://documentation.red-gate.com/fd/migrations-184127470.html)

## 脚本位置
flyway 通过 locations 配置脚本位置

- 默认配置Java的classpath, `classpath:db/migration`
- 支持系统文件，例如 `filesystem:/my-project/my-other-folder`
- 支持aws s3, 前缀`s3:`, 需要依赖 AWS SDK
- 支持 google gcs, 前缀`gcs:`, 需要依赖 GCS 的 SDK

## 基线

baseline 是 flyway 中叫做基线的东西，通过配置 `baselineVersion` 来设置基线值，
主要是为了兼容非空 schame 的数据库，例如数据库已经存在一些表，可能并不需要执行所有的 Migrate 脚本，
那么，就可以通过设置基线，让 flyway 自动忽略一些脚本

例如，现在有两个脚本   

![迁移脚本](/images/flyway/migrate_script.png)

flyway 的配置如下
设置了 `baseline-version` = 1, flyway 会自动忽略V1版本（和更小版本）
且  `baseline-on-migrate` = true, 在非空 schame 执行一次 baseline

![flyway配置](/images/flyway/flyway_config1.png)

启动项目，flyway_schema_history 表如下

![基线初始化](/images/flyway/baseline_db.png)

可以看到在非空 schame 的数据库设置 baseline 后，flyway_schema_history会自动生成一条基线数据
并自动忽略对应版本的迁移脚本

