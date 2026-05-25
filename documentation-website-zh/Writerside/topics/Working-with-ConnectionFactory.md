# 使用 ConnectionFactory

<primary-label ref="r2dbc"/>

在 R2DBC 中，来自 `io.r2dbc.spi` 包的 [`ConnectionFactory`](https://javadoc.io/doc/io.r2dbc/r2dbc-spi/latest/io/r2dbc/spi/ConnectionFactory.html)
是 JDBC 中 [`DataSource`](Working-with-DataSource.md) 的响应式等价物。
它负责生成支持响应式和基于协程的数据库访问的非阻塞 `Connection` 实例。

在 Exposed 中，`exposed-r2dbc` 模块通过允许你使用 `ConnectionFactory` 连接到数据库来集成 R2DBC 支持。每当传递 URL 时，这会通过 `R2dbcDatabase.connect()` 函数隐式完成：

```kotlin
```
{src="exposed-databases-r2dbc/src/main/kotlin/org/example/R2DBCDatabases.kt" include-symbol="database" }

这等同于使用仅接受配置块的 `R2dbcDatabase.connect()` 重载：

```kotlin
import io.r2dbc.spi.IsolationLevel
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabase

val database = R2dbcDatabase.connect {
    defaultMaxAttempts = 1
    defaultR2dbcIsolationLevel = IsolationLevel.READ_COMMITTED

    setUrl("r2dbc:h2:mem:///test;DB_CLOSE_DELAY=-1;")
}
```

## 使用 `ConnectionFactoryOptions`

当 URL 传递给 `R2dbcDatabase.connect()` 时，字符串会被解析以构建一个新的
[`ConnectionFactoryOptions`](https://r2dbc.io/spec/0.8.1.RELEASE/api/io/r2dbc/spi/ConnectionFactoryOptions.html) 对象，
该对象保存与 `ConnectionFactory` 相关的配置状态的详细信息。

此状态可以使用 `R2dbcDatabaseConfig.connectionFactoryOptions` 构建器手动配置，可以与提供的 URL 一起使用：

```kotlin
import io.r2dbc.spi.ConnectionFactoryOptions
import io.r2dbc.spi.IsolationLevel
import io.r2dbc.spi.Option
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabase
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabaseConfig

val database = R2dbcDatabase.connect(
    url = "r2dbc:h2:mem:///test;",
    databaseConfig = R2dbcDatabaseConfig {
        defaultMaxAttempts = 1
        defaultR2dbcIsolationLevel = IsolationLevel.READ_COMMITTED

        connectionFactoryOptions {
            option(Option.valueOf("DB_CLOSE_DELAY"), "-1")
        }
    }
)
```

或者通过从头开始完全构建状态持有者：

```kotlin
import io.r2dbc.spi.ConnectionFactoryOptions
import io.r2dbc.spi.IsolationLevel
import io.r2dbc.spi.Option
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabase

val database = R2dbcDatabase.connect {
    defaultMaxAttempts = 1
    defaultR2dbcIsolationLevel = IsolationLevel.READ_COMMITTED

    connectionFactoryOptions {
        option(ConnectionFactoryOptions.DRIVER, "h2")
        option(ConnectionFactoryOptions.PROTOCOL, "mem")
        option(ConnectionFactoryOptions.DATABASE, "test")
        option(Option.valueOf("DB_CLOSE_DELAY"), "-1")
    }
}
```

你还可以预先构建 `ConnectionFactoryOptions` 对象，并使用它来初始化自定义 `R2dbcDatabaseConfig` 实例。然后可以在稍后将两者直接传递给 `R2dbcDatabase.connect()`：

```kotlin
import io.r2dbc.spi.ConnectionFactoryOptions
import io.r2dbc.spi.IsolationLevel
import io.r2dbc.spi.Option
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabase
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabaseConfig

val options = ConnectionFactoryOptions.builder()
    .option(ConnectionFactoryOptions.DRIVER, "h2")
    .option(ConnectionFactoryOptions.PROTOCOL, "mem")
    .option(ConnectionFactoryOptions.DATABASE, "test")
    .option(Option.valueOf("DB_CLOSE_DELAY"), "-1")
    .build()

val databaseConfig = R2dbcDatabaseConfig {
    defaultMaxAttempts = 1
    defaultR2dbcIsolationLevel = IsolationLevel.READ_COMMITTED
    connectionFactoryOptions = options
}

val database = R2dbcDatabase.connect(databaseConfig = databaseConfig)
```

## 使用 `ConnectionFactory`

要使用 R2DBC 将 Exposed 连接到数据库，你可以选择通过提供显式的 `ConnectionFactory` 来依赖手动编程式连接工厂发现。然后可以将此连接源传递给 `R2dbcDatabase.connect()` 函数：

```kotlin
import io.r2dbc.spi.ConnectionFactories
import io.r2dbc.spi.ConnectionFactoryOptions
import io.r2dbc.spi.IsolationLevel
import io.r2dbc.spi.Option
import org.jetbrains.exposed.v1.core.vendors.H2Dialect
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabase
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabaseConfig

val options = ConnectionFactoryOptions.builder()
    .option(ConnectionFactoryOptions.DRIVER, "h2")
    .option(ConnectionFactoryOptions.PROTOCOL, "mem")
    .option(ConnectionFactoryOptions.DATABASE, "test")
    .option(Option.valueOf("DB_CLOSE_DELAY"), "-1")
    .build()

val connectionFactory = ConnectionFactories.get(options)

val database = R2dbcDatabase.connect(
    connectionFactory = connectionFactory,
    databaseConfig = R2dbcDatabaseConfig {
        defaultMaxAttempts = 1
        defaultR2dbcIsolationLevel = IsolationLevel.READ_COMMITTED
        explicitDialect = H2Dialect()
    }
)
```

<note>
如果使用显式 <code>ConnectionFactory</code>，在此情况下需要为 <code>R2dbcDatabaseConfig.explicitDialect</code> 设置值。
这避免了无法从 <code>ConnectionFactory</code> 或其配置选项解析数据库方言的可能性。
</note>

为了简化或进行更精细的连接自定义，你可以通过编程式配置使用特定于数据库的连接工厂和配置构建器。这些特定于数据库的对象可以以与通用 R2DBC SPI 对象相同的方式创建和传递：

```kotlin
import io.r2dbc.h2.H2ConnectionConfiguration
import io.r2dbc.h2.H2ConnectionFactory
import io.r2dbc.h2.H2ConnectionOption
import io.r2dbc.spi.IsolationLevel
import org.jetbrains.exposed.v1.core.vendors.H2Dialect
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabase
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabaseConfig

val connectionFactory = H2ConnectionFactory(
    H2ConnectionConfiguration.builder()
        .inMemory("test")
        .property(H2ConnectionOption.DB_CLOSE_DELAY, "-1")
        .build()
)

val database = R2dbcDatabase.connect(
    connectionFactory = connectionFactory,
    databaseConfig = R2dbcDatabaseConfig {
        defaultMaxAttempts = 1
        defaultR2dbcIsolationLevel = IsolationLevel.READ_COMMITTED
        explicitDialect = H2Dialect()
    }
)
```

这两种方式都会注册连接源，以便你可以使用 [`suspendTransaction`](Transactions.md#suspend-based-transaction) 执行基于协程的数据库操作。
