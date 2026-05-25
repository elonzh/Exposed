<show-structure for="chapter,procedure" depth="2"/>

# 使用数据源

<primary-label ref="jdbc"/>

也可以向 `Database.connect()` 函数提供 `javax.sql.DataSource`。这允许你使用更高级的功能，如连接池，并让你设置配置选项，如最大连接数、连接超时等。

```kotlin
val db = Database.connect(dataSource)
```

### HikariCP 示例

要使用像 [HikariCP](https://github.com/brettwooldridge/HikariCP) 这样的 JDBC 连接池，首先设置一个 `HikariConfig` 类。
此示例使用 MySQL JDBC 驱动（有关详细信息，请参阅 [MySQL 配置](https://github.com/brettwooldridge/HikariCP/wiki/MySQL-Configuration)的官方参考）：
```kotlin
val config = HikariConfig().apply {
    jdbcUrl = "jdbc:mysql://localhost/dbname"
    driverClassName = "com.mysql.cj.jdbc.Driver"
    username = "username"
    password = "password"
    maximumPoolSize = 6
    // as of version 0.46.0, if these options are set here, they do not need to be duplicated in DatabaseConfig
    isReadOnly = false
    transactionIsolation = "TRANSACTION_SERIALIZABLE"
}

// Gradle
implementation "mysql:mysql-connector-java:8.0.33"
implementation "com.zaxxer:HikariCP:4.0.3"
```
然后使用此配置类实例化一个 `HikariDataSource` 并将其提供给 `Database.connect()`：
```kotlin
val dataSource = HikariDataSource(config)

Database.connect(
    datasource = dataSource,
    databaseConfig = DatabaseConfig {
        // set other parameters here
    }
)
```

>从 0.46.0 版本开始，当直接在 `HikariConfig` 类中配置时，
>像 `transactionIsolation` 和 `isReadOnly` 这样的值将被 Exposed 在创建事务时使用。
>如果它们在 `DatabaseConfig` 中重复设置或设置了新值，
>后者将被视为覆盖，其方式与在单个事务块上设置这些参数覆盖默认设置的方式相同。
>因此，除非新值的目的是覆盖 Hikari 设置，否则不建议在 `DatabaseConfig` 中设置这些值。
{style="note"}