[//]: # (title: Spring Boot 集成)

<show-structure for="chapter,procedure" depth="2"/>
<var name="artifact_name" value="exposed-spring-boot4-starter"/>
<var name="artifact2_name" value="exposed-spring-boot-starter"/>
<var name="example_name" value="exposed-spring"/>
<tldr>
    <p>
        <b>必需依赖</b>: <code>org.jetbrains.exposed:%artifact_name%</code> 或
        <code>org.jetbrains.exposed:%artifact2_name%</code>
    </p>
    <include from="lib.topic" element-id="jdbc-supported"/>
    <include from="lib.topic" element-id="r2dbc-not-supported"/>
    <include from="lib.topic" element-id="code_example"/>
</tldr>

Exposed 通过 [Exposed Spring Boot starter](#add-dependencies) 提供 Spring Boot 3 和 Spring Boot 4 集成。

该 starter 将 Exposed 与 Spring Boot 的自动配置模型和事务基础设施集成。它注册了一个 Exposed 专用的事务管理器，并允许你使用标准的 Spring Boot 配置属性来[配置 Exposed](#configure-exposed)。

它还为 [GraalVM 原生镜像支持](#graalvm-support)提供了必要的运行时提示，因此在大多数情况下无需额外配置即可构建原生可执行文件。

## 要求

要在 Spring Boot 中使用 Exposed，你的项目必须满足以下要求：

* Kotlin 2.1.x
* JDK 17 或更高版本

Spring Boot 3 和 Spring Boot 4 都需要 JDK 17 或更高版本。请确保你的构建工具（Gradle 或 Maven）和 IDE 使用兼容的 JDK 版本。

如果使用 Gradle，请相应配置 JVM 工具链：

```kotlin
java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}
```

## 添加依赖

### Spring Boot 4

要在 Spring Boot 4 中使用 Exposed，请将 `%artifact_name%` 构件添加到你的构建脚本中：

<include from="lib.topic" element-id="add-dependency"/>

此 starter 包含最新版本的 Exposed 及其来自 `spring7-transaction` 库的自定义 [`SpringTransactionManager`](https://jetbrains.github.io/Exposed/api/spring7-transaction/org.jetbrains.exposed.v1.spring7.transaction/-spring-transaction-manager/index.html)
类，以及 [Spring Boot Starter JDBC](http://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-jdbc)。

### Spring Boot 3

对于使用 Spring Boot 3 的应用，请使用 `%artifact2_name%` 构件：

<var name="artifact_name" value="exposed-spring-boot-starter"/>
<include from="lib.topic" element-id="add-dependency"/>

> Spring Boot 3 的支持将在下一个主要 Exposed 版本中移除。
> 
{style="warning"}

## 配置数据库连接 {id="configure-db"}

该 starter 依赖于 [`spring-boot-starter-jdbc`](https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-jdbc)，
因此可以使用[所有标准的 Spring Boot 数据源属性](https://docs.spring.io/spring-boot/appendix/application-properties/index.html#appendix.application-properties.data)来配置数据库连接。

要配置数据源，请将所需属性添加到你的
<path>src/resources/application.properties</path> 文件中。以下示例配置了 H2 内存数据库的连接：

```generic
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=password
```

## 配置 Exposed {id="configure-exposed"}

要将 Exposed 与 Spring 的事务基础设施集成，你需要执行以下操作：

1. [启用 Exposed 自动配置](#auto-config)。
2. 可选地，通过注册数据库配置 bean 来[自定义 Exposed 的默认行为](#custom-config)。

### 启用 Exposed 自动配置 {id="auto-config"}

为确保使用 Exposed 的事务管理器，你需要先启用它并禁用 Spring Boot 默认的
`DataSourceTransactionManager` 自动配置。

你可以将自动配置直接应用于带有 `@SpringBootApplication` 注解的类：

```kotlin
```
{src="exposed-spring/src/main/kotlin/com/example/exposedspring/ExposedSpringApplication.kt" include-symbol="ExposedSpringApplication,main"}

> 有关排除自动配置类的其他选项，请参阅 [Spring Boot 官方文档](https://docs.spring.io/spring-boot/reference/using/auto-configuration.html#using.auto-configuration.disabling-specific)。
> 
{style="tip"}

### 自定义 Exposed 行为 {id="custom-config"}

要自定义默认的 Exposed 行为，请注册一个 [`DatabaseConfig`](https://jetbrains.github.io/Exposed/api/exposed-spring-boot4-starter/org.jetbrains.exposed.v1.spring.boot4.autoconfigure/-exposed-auto-configuration/database-config.html)
bean：

```kotlin
@Configuration
@ImportAutoConfiguration(
    value = [ExposedAutoConfiguration::class],
    exclude = [DataSourceTransactionManagerAutoConfiguration::class]
)
class ExposedConfig {
    @Bean
    fun databaseConfig() = DatabaseConfig {
        useNestedTransactions = true
    }
}
```

> `ExposedAutoConfiguration` 使用默认属性值注册 `@EnableTransactionManagement`。具体来说：
> ```generic
> mode = AdviceMode.PROXY
> proxyTargetClass = false
> ```
> 如果你需要不同的代理设置（例如基于类的代理），请在主配置类上声明单独的 `@EnableTransactionManagement`
> 注解，或在你的 <path>application.properties</path> 文件中配置 `spring.aop.proxy-target-class` 属性。
>
{style="note"}


### 启用自动 Schema 创建

要在启动时从 Exposed 表定义生成数据库 schema，请在你的 <path>application.properties</path> 文件中设置 `spring.exposed.generate-ddl`
属性：

```none
spring.exposed.generate-ddl=true
```

启用后，starter 会检测所有扩展 `org.jetbrains.exposed.v1.core.Table` 的类，并在应用启动期间创建 schema。

### 排除包

要从自动生成 schema 中排除特定包，请在你的 <path>application.properties</path> 文件中使用 `spring.exposed.excluded-packages` 属性：

```none
spring.exposed.excluded-packages=com.example.models.ignore,com.example.utils
```

这对于共享模块或在应用生命周期之外管理的表非常有用。

### 启用 SQL 日志

要记录 Exposed 执行的 SQL 语句，请在你的
<path>application.properties</path> 文件中启用 `spring.exposed.show-sql` 属性：

```none
spring.exposed.show-sql=true
```

这取代了在事务中手动调用 `addLogger()` 的需要，并与 Spring Boot 的日志系统集成。

## 管理事务

Exposed Spring Boot starter 直接与 Spring 的声明式事务模型集成。

### 使用 `@Transactional` {id="transactional"}

通过使用 Spring 的 [`@Transactional`](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html) 注解服务类或方法，
Spring 会为你打开和关闭事务。
在方法内部，你可以自由使用 Exposed DSL 或 DAO API，无需将代码包装在 `transaction {}` 块中：

```kotlin
@Transactional
class MessageService {
    fun findMessageById(id: MessageId): Message? {
        return MessageEntity.selectAll().where { MessageEntity.id eq id.value }.firstOrNull()?.let {
            Message(
                id = MessageId(it[MessageEntity.id].value),
                text = it[MessageEntity.text]
            )
        }
    }
}
```

Spring 在调用方法之前打开事务，在方法完成时提交或回滚事务。

### 注册额外的事务管理器

配置 Exposed 后，你可能仍想注册额外的事务管理器（例如，普通的 JDBC 或 JPA 管理器）。

像往常一样在单独的 `@Configuration` 类中定义它们：

```kotlin
@Configuration
class JdbcTransactionManagerConfig {
    @Bean(name = ["jdbcTransactionManager"])
    fun jdbcTransactionManager(
        dataSource: DataSource
    ): PlatformTransactionManager =
        DataSourceTransactionManager(dataSource)
}
```

使用 `@Transactional` 的 `transactionManager` 属性选择特定的事务管理器：

```kotlin
@Transactional(transactionManager = "jdbcTransactionManager")
fun doSomething() {
    // ...
}
```

### 定义组合注解

为了减少重复，你可以定义组合注解：

```kotlin
@Transactional(transactionManager = "springTransactionManager")
annotation class ExposedTransactional

@ExposedTransactional
fun doSomething() {
    // ...
}
```

### 配置主事务管理器

如果你注册了多个事务管理器，请使用 `@Primary` 注解默认的事务管理器 bean。当 `@Transactional` 未指定管理器时，Spring 将默认使用它。

## GraalVM 原生镜像支持 {id="graalvm-support"}

你可以在无需额外配置的情况下构建使用 Exposed Spring starter 的 Spring Boot 应用的 GraalVM 原生镜像。

该 starter 通过 [`ExposedAotContribution`](https://jetbrains.github.io/Exposed/api/exposed-spring-boot4-starter/org.jetbrains.exposed.v1.spring.boot4/-exposed-aot-contribution/index.html)
类提供必要的运行时提示，该类使 Spring Boot 的 AOT（Ahead-of-Time）处理兼容。

### AOT 限制

当你构建原生镜像时，Spring Boot 会应用 AOT 处理。AOT 限制了运行时的动态配置。

特别是，使用 `@ConditionalOnProperty` 声明的 bean 不能在运行时改变其行为。因此，
设置 `spring.exposed.generate-ddl=true` 不会在原生镜像中启用自动 schema 创建。

相反，请以编程方式创建数据库 schema。例如：

```kotlin
@Component
@Transactional
class SchemaInitialize : ApplicationRunner {
    override fun run(args: ApplicationArguments) {
        SchemaUtils.create(MessageEntity)
    }
}
```

### 解决 `KotlinReflectionInternalError: Unresolved class`

如果原生镜像构建或运行时出现 `KotlinReflectionInternalError: Unresolved class` 错误，应用可能缺少反射所需的运行时提示。

要解决此问题，请实现 `RuntimeHintsRegistrar` 并显式注册缺失的类型：

```kotlin
class ExposedHints : RuntimeHintsRegistrar {
    override fun registerHints(hints: RuntimeHints, classLoader: ClassLoader?) {
        hints.reflection().registerType(IntegerColumnType::class.java, *MemberCategory.entries.toTypedArray())
    }
}
```

要注册你的实现，请使用以下方法之一：
* 使用 `@ImportRuntimeHints` 注解配置类：
  ```kotlin
  @Configuration
  @ImportRuntimeHints(ExposedHints::class)
  class NativeHintsConfiguration
  ```
* 在 `META-INF/spring.factories` 文件中注册实现：
  ```generic
  org.springframework.aot.hint.RuntimeHintsRegistrar=com.example.ExposedHints
  ```
  将 `com.example.ExposedHints` 替换为你的实现的完全限定名。

> 有关更多信息，请参阅 [Spring Boot 关于 GraalVM 原生镜像的文档](https://docs.spring.io/spring-boot/reference/packaging/native-image/index.html)。
>
{style="tip"}
