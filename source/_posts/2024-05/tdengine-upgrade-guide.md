---
title:  tdengine升级
layout: info
commentable: true
date: 2024-05-21
mathjax: true
mermaid: true
tags: [  ]
categories: 运维
description: 
---

tdengine2.4升到 tdengine3.0

## 代码改动

### 依赖升级

需要将taos的驱动包升级到3以上

```xml
<dependency>
    <groupId>com.taosdata.jdbc</groupId>
    <artifactId>taos-jdbcdriver</artifactId>
    <version>3.1.0</version>
</dependency>
```

然后处理代码



公司使用 `mybatis` 作为 `tdengine` 的 `ORM` 框架，所以 sql 编写在 `XML` 文件中
需要调整一下 sql 来兼容tdengine3

### 关键字处理
在字段上，我们使用到了 tdengine 的一些关键字，例如 value, index 等
需要在关键字前后添加反引号(`)

修改前

```sql
select last(value) from t_xxx;
```
修改后
```sql
select last(`value`) from t_xxx;
```

### 时间窗口
时间窗口函数`interval`在时序数据库的场景中用得比较频繁，
升级到 tdengine3 之后，无法与 `group by` 关键字一起使用，
需要替换成`partition by`
`partition by`在使用上与`group by`一样
partition语句放在where语句之后，interval语句之前

修改前
```sql
SELECT last(value), c_time, sensor_id 
FROM iot_table 
interval(1m)
gorup by sensor_id
```
修改后
```sql
SELECT last(`value`), c_time, sensor_id 
FROM iot_table 
partition by sensor_id
interval(1m)
```



## 数据迁移

使用 taos 自动的导入导出工具，可以很方便实现数据的迁移，[下载链接](https://docs.taosdata.com/releases/tools/)

### 导出 
在2.x版本，建议安装`taosTools`官方安装包，避免导出格式无法兼容3.x版本而出现一些错误
通过以下命令

```zsh
taosdump -o export -D iot_db -T 8
```
`-o`  指定导出目录，需要先建立，不指定导出到当前目录，如果导出目录不为空，则会报错
`-D`指定导出的数据库，可以使用`-A`导出所有数据库
`-T` 指定线程大小，默认是8个线程

### 恢复数据

```zsh
taosdump -i export
```
`-i` 指定导入目录

### 

## 参考
- [特色查询](https://docs.taosdata.com/taos-sql/distinguished/)
- [taosdump](https://docs.taosdata.com/reference/taosdump/)