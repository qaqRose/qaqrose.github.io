---

title: Spring Boot 轻量级部署
layout: info
commentable: true
date: 2025-05-28
mathjax: true
mermaid: true
tags: [Java]
categories: 开发
description: 
---

Spring Boot 项目打包之后一般都比较大，远程部署过程速度慢，而且浪费很多的资源

通过轻量化部署，将项目依赖分开打包，实际代码 jar 就会变得很小，可以快速部署到服务器上

## 使用assembly插件构建依赖

`maven-assembly-plugin` 是一个 Maven 插件，用于将项目及其依赖打包成一个可分发的归档文件（如 ZIP、TAR、JAR 等）。它通常用于创建包含所有依赖、配置文件和资源的完整发布包

### 添加依赖

```xml
<plugin>
    <artifactId>maven-assembly-plugin</artifactId>
    <version>3.3.0</version>
    <configuration>
        <appendAssemblyId>false</appendAssemblyId>
        <descriptors>
            <descriptor>src/assembly/assembly.xml</descriptor>
        </descriptors>
    </configuration>
    <executions>
        <execution>
            <id>make-jar-with-dependencies</id>
            <phase>package</phase>
            <goals>
                <goal>single</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### 创建描述文件

在`src/assembly/assembly.xml`中定义打包的规则

```xml
<assembly xmlns="http://maven.apache.org/ASSEMBLY/2.1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.1.0 http://maven.apache.org/xsd/assembly-2.1.0.xsd">
    <!-- 定义构建的id，这个id会添加到生成文件名称的后缀符 -->
    <id>make-jar-with-dependencies</id>

    <!-- 定义打包格式，例如zip或tar.gz -->
    <formats>
        <format>zip</format>
<!--        &lt;!&ndash; 可以添加多个格式 &ndash;&gt;-->
<!--        <format>tar.gz</format>-->
    </formats>

    <!-- 依赖集，用于定义如何处理项目的依赖 -->
    <dependencySets>
        <dependencySet>
            <!-- 依赖输出的目录 -->
            <outputDirectory>lib</outputDirectory>
            <!-- 是否包含项目本身的artifact -->
            <useProjectArtifact>false</useProjectArtifact>
            <!-- 是否解压缩依赖 -->
            <unpack>false</unpack>
            <!-- 第三方的依赖打包到lib目录下 -->
            <excludes>
                <exclude>
                    com.example*
                </exclude>
            </excludes>
        </dependencySet>
    </dependencySets>
</assembly>
```

### 多模块项目打包

如果项目是多模块项目，那么对于项目自身模块的jar包, 直接到 include打到打包后的jar中

```XML
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <mainClass>com.example.demo.DemoApplication</mainClass>
        <layout>ZIP</layout>
        <includes>
            <include>
                <groupId>com.example</groupId>
                <artifactId>base</artifactId>
            </include>
        </includes>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>repackage</goal>
                <goal>build-info</goal>
            </goals>
        </execution>
    </executions>
</plugin>


```

### 项目打包

示例项目为拥有2个模块的maven项目，base模块为基础模块，business模块为业务模块，启动业务模块引用了基础模块

打包时候需要将base模块打包到jar中

项目目录如下

![image-20250528160425863](images/2025-05-28-spring-boot-lightweight-deploy/image-20250528160425863.png)

demo模块的pom如下

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.5.0</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <groupId>com.example</groupId>
    <artifactId>demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>pom</packaging>
    <name>demo</name>
    <description>demo</description>

    <modules>
        <module>base</module>
        <module>business</module>
    </modules>

    <properties>
        <java.version>17</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>

```

base模块的pom如下
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.example</groupId>
        <artifactId>demo</artifactId>
        <version>0.0.1-SNAPSHOT</version>
    </parent>

    <artifactId>base</artifactId>
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

</project>
```

business模块的pom文件如下

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.example</groupId>
        <artifactId>demo</artifactId>
        <version>0.0.1-SNAPSHOT</version>
    </parent>

    <artifactId>business</artifactId>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>com.example</groupId>
            <artifactId>base</artifactId>
            <version>0.0.1-SNAPSHOT</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.3.0</version>
                <configuration>
                    <appendAssemblyId>false</appendAssemblyId>
                    <descriptors>
                        <descriptor>src/assembly/assembly.xml</descriptor>
                    </descriptors>
                </configuration>
                <executions>
                    <execution>
                        <id>make-jar-with-dependencies</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <mainClass>com.example.demo.DemoApplication</mainClass>
                    <layout>ZIP</layout>
                    <includes>
                        <include>
                            <groupId>com.example</groupId>
                            <artifactId>base</artifactId>
                        </include>
                    </includes>
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                            <goal>build-info</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

        </plugins>
    </build>
</project>
```



## 项目打包

```
mvn clean package
```

business模块打包后如下

![image-20250528160718025](images/2025-05-28-spring-boot-lightweight-deploy/image-20250528160718025.png)



`business-0.0.1-SNAPSHOT.zip` 压缩包里面包含了项目的依赖

![image-20250528160801613](images/2025-05-28-spring-boot-lightweight-deploy/image-20250528160801613.png)

构建之后的`business-0.0.1-SNAPSHOT.jar`也包含了base模块

![image-20250528161725111](images/2025-05-28-spring-boot-lightweight-deploy/image-20250528161725111.png)

`spring-boot-jarmode-tools`使用springboot优化分层结构的hjar包（在一些版本可能没有）


## 项目运行

需要执行项目依赖库

```
-Dloader.path=lib
```

启动命令如下

```
java "-Dloader.path=lib" -jar business-0.0.1-SNAPSHOT.jar
```

启动成功

![image-20250528163154335](images/2025-05-28-spring-boot-lightweight-deploy/image-20250528163154335.png)

## Docker 支持

可以将项目的依赖库目录lib挂载到docker容器目录，

### Dockerfile文件

```
# 使用官方 OpenJDK 17 作为基础镜像
FROM openjdk:17-jdk-alpine

# 设置工作目录
WORKDIR /app

# 将构建的 JAR 文件复制到容器中
COPY *.jar app.jar

# 暴露应用程序的端口（假设 Spring Boot 应用使用 8080 端口）
EXPOSE 8080

# 设置 JVM 参数（指定目录为/app/lib）
ENV JAVA_OPTS="-Xmx512m -Xms256m -Dloader.path=/app/lib"

# 启动应用程序
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```



### 运行脚本

docker容器的启动如下

```
docker run -p 8080:8080 -v /data/lib:/app/lib my-spring-boot-app
```

`-v /data/lib:/app/lib` 将系统目录`/data/lib`映射到容器的`/app/lib` 

只需要将依赖的jar解压到`/data/lib`即可