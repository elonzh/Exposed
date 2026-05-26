[//]: # (title: 添加依赖)

<show-structure for="chapter,procedure" depth="2"/>

Exposed 分为多个特定模块，让您可以灵活地只使用所需的模块。
在本主题中，您将了解这些模块是什么以及如何向现有的 Gradle/Maven 项目添加模块依赖。

## 配置仓库

Exposed 模块可从 [Maven Central 仓库](https://central.sonatype.com/namespace/org.jetbrains.exposed) 获取。
要使用它们，请将相应的依赖添加到您的仓库映射中：

<tabs>
  <tab title="Kotlin Gradle">
    <code-block lang="kotlin">
    repositories {
        mavenCentral()
    }
    </code-block>
  </tab>
  <tab title="Maven">
    Maven 用户默认已启用 Maven Central 仓库。
  </tab>
  <tab title="Groovy Gradle">
    <code-block lang="groovy">
    repositories {
        mavenCentral()
    }
    </code-block>
  </tab>
</tabs>

## 添加依赖

Exposed 应用程序至少需要 [核心模块](#core-module) 和一个
[传输模块](#transport-modules)。以下示例展示了常见配置的最小依赖集：

<tabs>
  <tab title="Kotlin Gradle">
    <code-block lang="kotlin">
    dependencies {
        implementation("org.jetbrains.exposed:exposed-core:%exposed_version%")
        implementation("org.jetbrains.exposed:exposed-jdbc:%exposed_version%")
        implementation("org.jetbrains.exposed:exposed-dao:%exposed_version%") // Optional
    }
    </code-block>
  </tab>
  <tab title="Maven">
    <code-block lang="xml"><![CDATA[
        <dependencies>
            <dependency>
                <groupId>org.jetbrains.exposed</groupId>
                <artifactId>exposed-core</artifactId>
                <version>%exposed_version%</version>
            </dependency>
            <dependency>
                <groupId>org.jetbrains.exposed</groupId>
                <artifactId>exposed-jdbc</artifactId>
                <version>%exposed_version%</version>
            </dependency>
            <dependency>
                <groupId>org.jetbrains.exposed</groupId>
                <artifactId>exposed-dao</artifactId>
                <version>%exposed_version%</version>
            </dependency>
        </dependencies>
    ]]>
    </code-block>
  </tab>
  <tab title="Groovy Gradle">
    <code-block lang="groovy">
    dependencies {
        implementation "org.jetbrains.exposed:exposed-core:%exposed_version%"
        implementation "org.jetbrains.exposed:exposed-jdbc:%exposed_version%"
        implementation "org.jetbrains.exposed:exposed-dao:%exposed_version%" //optional
    }
    </code-block>
  </tab>
</tabs>

## 模块

Exposed 由多个模块组成，分为以下几类：

- [核心模块](#core-module)
- [传输模块](#transport-modules)
- [数据库访问模块](#database-access-module)
- [扩展模块](#extension-modules)

### 核心模块 {#core-module}

要在应用程序中使用 Exposed，您需要以下核心模块：

| 模块          | 功能                                                                                                                                                         |
|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `exposed-core`  | 提供以类型安全方式处理数据库所需的基础组件和抽象，包括领域特定语言（DSL）API    |

### 传输模块 {#transport-modules}

传输模块定义了 Exposed 如何与数据库通信，它们是互斥的。

| 模块          | 功能                                                                                                                                                         |
|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `exposed-jdbc`  | 提供 Java 数据库连接（JDBC）支持，基于 Java JDBC API 的传输级实现                                          |
| `exposed-r2dbc` | 提供响应式关系数据库连接（R2DBC）支持                                                                                           |

> 您只需要一个传输模块——`exposed-jdbc` 或 `exposed-r2dbc`，而不是两者都用。
> {style="note"}

### 数据库访问模块 {#database-access-module}

Exposed 提供了一个可选的数据库访问模块，它建立在 `exposed-core` 之上，为处理数据库数据提供更高级别的抽象：

| 模块        | 功能                                                                                                            |
|---------------|---------------------------------------------------------------------------------------------------------------------|
| `exposed-dao` | 提供数据访问对象（DAO）API。<br/> 需要 `exposed-jdbc`，不兼容 `exposed-r2dbc`。 |

### 扩展模块 {#extension-modules}

以下模块扩展了 Exposed 的功能，允许您处理特定数据类型、加密和日期时间处理：

| 模块                         | 功能                                                                                                                                                                        |
|--------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `exposed-crypt`                | 提供额外的列类型，用于在数据库中存储加密数据并在客户端进行编码/解码                                                                |
| `exposed-java-time`            | 基于 [Java 8 Time API](https://docs.oracle.com/javase/8/docs/api/java/time/package-summary.html) 的日期时间扩展                                                   |
| `exposed-jodatime`             | 基于 [Joda-Time](https://www.joda.org/joda-time/) 库的日期时间扩展                                                                                          |
| `exposed-json`                 | JSON 和 JSONB 数据类型扩展                                                                                                                                             |
| `exposed-kotlin-datetime`      | 基于 [`kotlinx-datetime`](https://kotlinlang.org/api/kotlinx-datetime/) 库的日期时间扩展                                                                    |
| `exposed-money`                | 支持来自 [JavaMoney API](https://javamoney.github.io/) 的 [`MonetaryAmount`](https://javamoney.github.io/apidocs/java.money/javax/money/MonetaryAmount.html) 的扩展 |
| `exposed-spring-boot-starter`  | 用于 [Spring Boot 3](https://spring.io/projects/spring-boot) 的 starter，将 Exposed 用作 ORM                                                                             |
| `exposed-spring-boot4-starter` | 用于 [Spring Boot 4](https://spring.io/projects/spring-boot) 的 starter，将 Exposed 用作 ORM                                                                             |
| `spring-transaction`           | 建立在 Spring Framework 6 标准事务工作流之上的事务管理器                                                                             |
| `spring7-transaction`          | 建立在 Spring Framework 7 标准事务工作流之上的事务管理器                                                                             |
| `exposed-migration-core`       | 提供数据库 schema 迁移的核心通用功能                                                                                                               |
| `exposed-migration-jdbc`       | 提供支持数据库 schema 迁移的工具，依赖 JDBC 驱动                                                                                      |
| `exposed-migration-r2dbc`      | 提供支持数据库 schema 迁移的工具，依赖 R2DBC 驱动                                                                                     |


## 添加 JDBC/R2DBC 驱动

您还需要所使用数据库系统的 JDBC 或 R2DBC 驱动。例如，以下依赖为 H2 数据库添加了 JDBC 驱动：

<tabs>
  <tab title="Kotlin Gradle">
    <code-block lang="kotlin">
    dependencies {
        implementation("com.h2database:h2:%h2_db_version%")
    }
    </code-block>
  </tab>
  <tab title="Maven">
    <code-block lang="xml"><![CDATA[
    <dependencies>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <version>2.4.240</version>
        </dependency>
    </dependencies>
    ]]>
</code-block>
  </tab>
  <tab title="Groovy Gradle">
    <code-block lang="groovy">
    dependencies {
        implementation "com.h2database:h2:%h2_db_version%"
    }
    </code-block>
  </tab>
</tabs>

> 有关支持的数据库及其对应驱动依赖的完整列表，请参见 [](Working-with-Database.md)。

## 添加日志依赖

要查看来自 [`StdOutSqlLogger`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-std-out-sql-logger/index.html) 的日志，请添加日志依赖：

<tabs>
  <tab title="Kotlin Gradle">
    <code-block lang="kotlin">
    dependencies {
        // Minimal logging (no output)
        implementation("org.slf4j:slf4j-nop:%slf4j_version%")
        // Full-featured logging using Logback
        implementation("ch.qos.logback:logback-classic:%logback_version%")
    }
    </code-block>
  </tab>
  <tab title="Maven">
    <code-block lang="xml"><![CDATA[
        <!-- Minimal logging (no output) -->
        <dependencies>
            <dependency>
                <groupId>org.slf4j</groupId>
                <artifactId>slf4j-nop</artifactId>
                <version>%slf4j_version%</version>
            </dependency>
        </dependencies>
        <!-- Full-featured logging using Logback -->
        <dependency>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-classic</artifactId>
            <version>%logback_version%</version>
        </dependency>
        ]]>
    </code-block>
  </tab>
  <tab title="Groovy Gradle">
    <code-block lang="groovy">
        dependencies {
            // Minimal logging (no output)
            implementation("org.slf4j:slf4j-nop:%slf4j_version%")
            // Full-featured logging using Logback
            implementation("ch.qos.logback:logback-classic:%logback_version%")
        }
    </code-block>
  </tab>
</tabs>

> 有关为什么需要日志依赖的更多信息，
> 请参阅 [SLF4J 文档](https://www.slf4j.org/codes.html#StaticLoggerBinder)。
