---
title: feign-core v1 maven 迁移
layout: info
commentable: true
date: 2023-07-03
mathjax: true
mermaid: true
tags: [feign]
categories: feign
description: 
---


feign-core 迁移到 maven 的 `pom.xml` 文件

#### parent 
parent 模块的 pom.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.netflix.feign</groupId>
    <artifactId>feign-parent</artifactId>
    <version>${revision}</version>

    <packaging>pom</packaging>

    <name>feign</name>
    <description>feign</description>


    <properties>
        <revision>1.0</revision>
        
        <java.version>1.8</java.version>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
    </properties>

    <modules>
        <module>feign-core</module>
        <module>feign-ribbon</module>
    </modules>

</project>

```



#### feign-core

feign-core 模块的 pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.netflix.feign</groupId>
        <artifactId>feign-parent</artifactId>
        <version>${revision}</version>
    </parent>

    <packaging>jar</packaging>
    
    <artifactId>feign-core</artifactId>
    <name>feign-ribbon</name>
    <description>feign-ribbon</description>
    
    <dependencies>
        <dependency>
            <groupId>com.squareup.dagger</groupId>
            <artifactId>dagger-compiler</artifactId>
            <version>1.0.1</version>
        </dependency>
        <dependency>
            <groupId>com.google.code.gson</groupId>
            <artifactId>gson</artifactId>
            <version>2.2.4</version>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.2.2</version>
        </dependency>
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>6.8.1</version>
        </dependency>
        <dependency>
            <groupId>com.google.mockwebserver</groupId>
            <artifactId>mockwebserver</artifactId>
            <version>20130505</version>
        </dependency>
        <dependency>
            <groupId>com.google.guava</groupId>
            <artifactId>guava</artifactId>
            <version>14.0.1</version>
        </dependency>
        <dependency>
            <groupId>com.squareup.dagger</groupId>
            <artifactId>dagger</artifactId>
            <version>1.0.1</version>
        </dependency>
        <dependency>
            <groupId>javax.ws.rs</groupId>
            <artifactId>jsr311-api</artifactId>
            <version>1.1.1</version>
        </dependency>
    </dependencies>

</project>
```

#### feign-ribbon

feign-ribbon 模块的 pom.xml

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.netflix.feign</groupId>
        <artifactId>feign-parent</artifactId>
        <version>${revision}</version>
    </parent>

    <packaging>jar</packaging>

    <artifactId>feign-ribbon</artifactId>
    <name>feign-ribbon</name>
    <description>feign-ribbon</description>

    <dependencies>
        <dependency>
            <groupId>com.netflix.feign</groupId>
            <artifactId>feign-core</artifactId>
            <version>${revision}</version>
        </dependency>
        <dependency>
            <groupId>com.netflix.ribbon</groupId>
            <artifactId>ribbon-core</artifactId>
            <version>0.2.0</version>
        </dependency>
        <dependency>
            <groupId>com.squareup.dagger</groupId>
            <artifactId>dagger-compiler</artifactId>
            <version>1.0.1</version>
        </dependency>
        <dependency>
            <groupId>com.google.code.gson</groupId>
            <artifactId>gson</artifactId>
            <version>2.2.4</version>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.2.2</version>
        </dependency>
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>6.8.1</version>
        </dependency>
        <dependency>
            <groupId>com.google.mockwebserver</groupId>
            <artifactId>mockwebserver</artifactId>
            <version>20130505</version>
        </dependency>
        <dependency>
            <groupId>com.google.guava</groupId>
            <artifactId>guava</artifactId>
            <version>14.0.1</version>
        </dependency>
        <dependency>
            <groupId>com.squareup.dagger</groupId>
            <artifactId>dagger</artifactId>
            <version>1.0.1</version>
        </dependency>
        <dependency>
            <groupId>javax.ws.rs</groupId>
            <artifactId>jsr311-api</artifactId>
            <version>1.1.1</version>
        </dependency>
    </dependencies>
</project>
```

#### feign-example-cli

feign-example-cli 模块的 pom.xml

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>feign</groupId>
    <artifactId>feign-example-cli</artifactId>
    <version>${revision}</version>

    <packaging>jar</packaging>

    <name>feign-example-cli</name>
    <description>feign-example-cli</description>

    <properties>
        <revision>1.0</revision>
    </properties>

    <dependencies>
        <dependency>
            <groupId>com.netflix.feign</groupId>
            <artifactId>feign-core</artifactId>
            <version>${revision}</version>
        </dependency>
        <dependency>
            <groupId>com.netflix.ribbon</groupId>
            <artifactId>ribbon-core</artifactId>
            <version>0.2.0</version>
        </dependency>
        <dependency>
            <groupId>com.google.code.gson</groupId>
            <artifactId>gson</artifactId>
            <version>2.2.4</version>
        </dependency>
        <dependency>
            <groupId>com.squareup.dagger</groupId>
            <artifactId>dagger-compiler</artifactId>
            <version>1.0.1</version>
        </dependency>
    </dependencies>
</project>
```