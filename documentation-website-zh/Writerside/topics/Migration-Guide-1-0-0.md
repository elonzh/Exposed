<show-structure for="chapter,procedure" depth="3"/>

# 从 0.61.0 迁移到 1.0.0

本指南提供有关如何从 Exposed 版本 0.61.0 迁移到版本 1.0.0 的说明。
版本 1.0.0 在现有 JDBC 支持的基础上引入了 R2DBC 支持。此版本中的大多数更改是为了适应响应式数据库访问同时保留现有功能。

## 使用 Claude Code 迁移

如果您的项目使用 [Claude Code](https://claude.com/claude-code)，您可以自动应用此迁移的机械部分。

该技能专门针对 **0.61.0 → 1.0.0** 迁移——与本指南的范围相同。如果您的项目使用较旧的 0.x 版本（例如 0.55.x 或 0.41.x），该技能将在继续之前发出警告并要求确认。推荐的路径是先升级到 0.61.0，然后重新运行该技能。

### 安装

1. 从 Exposed 仓库下载技能文件夹：
   [`.claude/skills/migrate-to-1.0/`](https://github.com/JetBrains/Exposed/tree/main/.claude/skills/migrate-to-1.0)。
2. 将整个 `migrate-to-1.0/` 目录复制到您项目中的
   `<your-project>/.claude/skills/migrate-to-1.0/`。

### 运行

在 Claude Code 中，从项目根目录调用：

```
/migrate-to-1.0
```

该技能扫描您的代码，提出计划，要求您确认，然后应用机械更改（导入、包重命名、`SqlExpressionBuilder` lambda 导入、构建依赖升级）。任何需要人工判断的内容——自定义 `Transaction` 扩展、自定义语句或方言、`transaction()` 签名更改等——将在末尾的摘要中报告，以便您可以使用本指南的其余部分手动解决。

该技能仅在您的工作树上操作；它不会创建分支或提交。使用 `git diff` 检查更改并在满意时提交。

## 导入版本控制和包重命名

### 更新的导入 {#updated-imports}

所有依赖已更新为遵循 `org.jetbrains.exposed.v1.packageName.*` 的导入路径模式。这在包命名中引入了两个关键变化：每个模块和构件的唯一前缀，以及额外的 `v1` 前缀。

每个模块的唯一前缀使得更容易区分特定类、函数或其他元素来自哪个依赖。随着包数量的增长，这变得越来越重要。整个版本的唯一 `v1` 前缀帮助那些对 Exposed 的 `0.x` 版本有传递依赖的用户。

这意味着来自 `exposed-core` 的导入（例如以前位于 `org.jetbrains.exposed.sql.*` 下的）现在位于 `org.jetbrains.exposed.v1.core.*` 下。下表显示了示例更改：

| 0.61.0                                        | 1.0.0                                           |
|-----------------------------------------------|-------------------------------------------------|
| `org.jetbrains.exposed.sql.Table`             | `org.jetbrains.exposed.v1.core.Table`           |
| `org.jetbrains.exposed.sql.AbstractQuery`     | `org.jetbrains.exposed.v1.core.AbstractQuery`   |
| `org.jetbrains.exposed.sql.Expression`        | `org.jetbrains.exposed.v1.core.Expression`      |
| `org.jetbrains.exposed.dao.id.EntityID`       | `org.jetbrains.exposed.v1.core.dao.id.EntityID` |
| `org.jetbrains.exposed.dao.IntEntity`         | `org.jetbrains.exposed.v1.dao.IntEntity`        |
| `org.jetbrains.exposed.sql.javatime.datetime` | `org.jetbrains.exposed.v1.javatime.datetime`    |
| `org.jetbrains.exposed.sql.json.json`         | `org.jetbrains.exposed.v1.json.json`            |

有关导入更改的更多详情，请查看[破坏性变更 - 1.0.0-beta-1](https://www.jetbrains.com/help/exposed/breaking-changes.html#1-0-0-beta-1)。

### 移动的导入

允许 R2DBC 功能的主要设计变更涉及从 `exposed-core` 中提取一些类和接口并移至 `exposed-jdbc`，以便新的 R2DBC 变体也可以在 `exposed-r2dbc` 中创建。下表显示了示例更改：

| 0.61.0                                                      | 1.0.0                                                           |
|-------------------------------------------------------------|-----------------------------------------------------------------|
| `org.jetbrains.exposed.sql.Database`                        | `org.jetbrains.exposed.v1.jdbc.Database`                        |
| `org.jetbrains.exposed.sql.SchemaUtils`                     | `org.jetbrains.exposed.v1.jdbc.SchemaUtils`                     |
| `org.jetbrains.exposed.sql.Query`                           | `org.jetbrains.exposed.v1.jdbc.Query`                           |
| `org.jetbrains.exposed.sql.transactions.TransactionManager` | `org.jetbrains.exposed.v1.jdbc.transactions.TransactionManager` |

此外，需要 R2DBC 变体的顶层查询和语句函数已从 `exposed-core` 中移出。这也适用于执行元数据查询检查的某些类方法，即来自 `Table`、`Schema` 和 `Sequence` 类的 `exists()` 方法。下表显示了示例更改：

| 0.61.0                                | 1.0.0                                     |
|---------------------------------------|-------------------------------------------|
| `org.jetbrains.exposed.sql.select`    | `org.jetbrains.exposed.v1.jdbc.select`    |
| `org.jetbrains.exposed.sql.selectAll` | `org.jetbrains.exposed.v1.jdbc.selectAll` |
| `org.jetbrains.exposed.sql.andWhere`  | `org.jetbrains.exposed.v1.jdbc.andWhere`  |
| `org.jetbrains.exposed.sql.exists`    | `org.jetbrains.exposed.v1.jdbc.exists`    |
| `org.jetbrains.exposed.sql.insert`    | `org.jetbrains.exposed.v1.jdbc.insert`    |
| `org.jetbrains.exposed.sql.update`    | `org.jetbrains.exposed.v1.jdbc.update`    |

<note>
这意味着依赖于 <code>exposed-spring-boot-starter</code> 的项目现在很可能需要额外依赖 <code>exposed-jdbc</code>。
</note>

### `SqlExpressionBuilder` 方法导入 {id = sql-expression-builder-imports}

接口 `ISqlExpressionBuilder`（及其所有方法）已弃用，其实现对象 `SqlExpressionBuilder` 和 `UpsertSqlExpressionBuilder` 也已弃用。之前受此接口限制的所有方法现在应替换为其新的等效顶层函数。如果尚未存在 `org.jetbrains.exposed.v1.core.*`，则需要添加新的导入语句：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.SqlExpressionBuilder.less
import org.jetbrains.exposed.sql.selectAll
    
val amountIsLow = TableA.amount less 10
TableA
    .selectAll()
    .where(amountIsLow)
```

```kotlin
import org.jetbrains.exposed.v1.core.less
import org.jetbrains.exposed.v1.jdbc.selectAll

val amountIsLow = TableA.amount less 10
TableA
    .selectAll()
    .where(amountIsLow)
```

</compare>

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.greaterEq
import org.jetbrains.exposed.sql.SqlExpressionBuilder.isNotNull
    
val isValid = TableA.value.isNotNull() and
    (TableA.amount greaterEq 10)
TableA
    .selectAll()
    .where(isValid)
```

```kotlin
import org.jetbrains.exposed.v1.core.*
import org.jetbrains.exposed.v1.jdbc.selectAll

val isValid = TableA.value.isNotNull() and
    (TableA.amount greaterEq 10)
TableA
    .selectAll()
    .where(isValid)
```

</compare>

这意味着不再需要使用以 `SqlExpressionBuilder` 作为接收者的范围函数，因此构建器方法如 `Op.build()` 和 `Expression.build()` 也已弃用：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.concat
    
val calculatedAmount = Expression.build {
    (TableA.amount * 2) - 10
}

val detailsInvalid = Op.build {
    TableA.details like "% - N/A"
}

val newDetails = with(SqlExpressionBuilder) {
    Case()
        .When(TableA.amount eq 0, TableA.details + " - S/O")
        .When(TableA.warranty.isNull(), TableA.details + " - N/A")
        .Else(TableA.details)
}.alias("nl")

TableA.update {
    it[TableA.details] = concat(TableA.details.upperCase(), stringLiteral(" - UPDATED"))
    it.update(TableA.amount) { TableA.amount plus 3 }
}
```

```kotlin
import org.jetbrains.exposed.v1.core.*
import org.jetbrains.exposed.v1.jdbc.update

val calculatedAmount = (TableA.amount * 2) - 10

val detailsInvalid = TableA.details like "% - N/A"

val newDetails = Case()
    .When(TableA.amount eq 0, TableA.details + " - S/O")
    .When(TableA.warranty.isNull(), TableA.details + " - N/A")
    .Else(TableA.details)
    .alias("nl")

TableA.update {
    it[TableA.details] = concat(TableA.details.upperCase(), stringLiteral(" - UPDATED"))
    it[TableA.amount] = TableA.amount plus 3
}
```

</compare>

<note>
任何参数接受 <code>SqlExpressionBuilder</code> 作为接收者（或参数）的高阶函数也已更改，不再使用此对象，这意味着可能需要添加导入语句。
有关更多详情，请参见<a href="#sql-expression-builder-lambda">下面的部分</a>。
</note>

### IDE 自动导入辅助

上述导入路径的更改将在您的 IDE 中显示为多个未解析的错误，手动解决和添加可能很繁琐。

在 IntelliJ IDEA 中，解决这些导入错误的快捷方式可能是依赖[自动添加](https://www.jetbrains.com/help/idea/creating-and-optimizing-imports.html#automatically-add-import-statements)导入语句，方法是在 **Settings | Editor | General | Auto Import** 中临时启用 **Add unambiguous imports** 选项。勾选该选项后，删除任何未解析的导入语句应触发正确路径的自动添加，然后可以手动确认。

### 隐式导入和命名冲突

在 1.0.0 版本之前，可以创建与现有查询和语句函数同名的自定义扩展函数和类方法，如 `selectAll()` 和 `insert()`。在 1.0.0 版本中仍然可以这样做。但是，由于这些 Exposed 函数的导入路径，如果同时使用此类自定义函数，使用通配符导入可能会导致意外的调用行为。建议在重命名不可行的情况下显式导入这些自定义函数。

## Kotlin 版本

版本 1.0.0 使用 Kotlin 2.2，而 0.61.0 使用 Kotlin 2.0。

### 日期时间最低要求

作为核心重构的一部分，3 个可用的日期时间构件已重构，使其列类型类依赖于 `exposed-core` 中的通用抽象类。如果您依赖这些依赖中的任何一个，请参见[日期时间类重构](#datetime-column-type-refactor)了解完整详情。

这个新的核心日期时间 API 依赖于仅与 `kotlin-stdlib` 2.1.20 或更高版本兼容的 [`kotlinx.datetime` 功能](https://github.com/Kotlin/kotlinx-datetime?tab=readme-ov-file#using-in-your-projects)。尝试使用较旧的 Kotlin 版本和 Exposed 日期时间构件进行构建可能导致 `NoClassDefFoundError`，需要升级 Kotlin 版本。

## 迁移依赖

在 1.0.0 版本之前，`MigrationUtils` 可通过依赖 `exposed-migration` 构件获得。为了使其工具方法能够同时支持 JDBC 和 R2DBC，该构件现已被 `exposed-migration-core` 替代，并引入了驱动特定构件（带有 `-jdbc` 和 `-r2dbc` 等后缀）：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
dependencies {
    // ...
    implementation("org.jetbrains.exposed:exposed-migration:0.61.0")
}
```

```kotlin
dependencies {
    // ...
    implementation("org.jetbrains.exposed:exposed-migration-core:1.0.0")
    implementation("org.jetbrains.exposed:exposed-migration-jdbc:1.0.0")
}
```

</compare>

这意味着 `MigrationUtils` 的导入路径也已更新为遵循其他[包更改](#updated-imports)的模式：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.transactions.transaction

transaction {
    MigrationUtils.statementsRequiredForDatabaseMigration(
        TableA,
        withLogs = false
    )
}
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.migration.jdbc.MigrationUtils

transaction {
    MigrationUtils.statementsRequiredForDatabaseMigration(
        TableA,
        withLogs = false
    )
}
```

</compare>

## Spring 依赖

版本 1.0.0 通过原始的 `exposed-spring-boot-starter` 构件（及其 `spring-transaction` 依赖）保持与 Spring Framework 6 和 Spring Boot 3 的兼容性。

要迁移到 Spring Framework 7 和 Spring Boot 4，应将此依赖替换为新的版本化构件 `exposed-spring-boot4-starter`：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
dependencies {
    // ...
    implementation("org.jetbrains.exposed:exposed-spring-boot-starter:0.61.0")
}
```

```kotlin
dependencies {
    // Only if migrating from Spring Boot 3 to Spring Boot 4
    implementation("org.jetbrains.exposed:exposed-spring-boot4-starter:1.0.0")
}
```

</compare>

这意味着提供的 Spring Boot 4 兼容类的导入路径也已更新为遵循其他[包更改](#updated-imports)的模式：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.v1.spring.boot.autoconfigure.ExposedAutoConfiguration
import org.springframework.boot.autoconfigure.ImportAutoConfiguration
import org.springframework.boot.autoconfigure.SpringBootApplication

@SpringBootApplication
@ImportAutoConfiguration(ExposedAutoConfiguration::class)
class SpringApplication
```

```kotlin
// Only if migrating from Spring 6 to Spring 7
import org.jetbrains.exposed.v1.spring.boot4.autoconfigure.ExposedAutoConfiguration
import org.springframework.boot.autoconfigure.ImportAutoConfiguration
import org.springframework.boot.autoconfigure.SpringBootApplication

@SpringBootApplication
@ImportAutoConfiguration(ExposedAutoConfiguration::class)
class SpringApplication
```

</compare>

如果迁移到 Spring Framework 7 并直接使用 Exposed 的 `SpringTransactionManager`，应将 `spring-transaction` 构件的依赖替换为新的版本化 `spring7-transaction` 依赖。

## 事务

`Transaction` 类保留在 `exposed-core` 中，但现在是抽象的，其所有驱动特定属性和方法现在可从新的开放类 `JdbcTransaction` 和 `R2dbcTransaction` 访问。以下是一些所有权变更的示例：

| 0.61.0                    | 1.0.0                        |
|---------------------------|------------------------------|
| `Transaction.connection`  | `JdbcTransaction.connection` |
| `Transaction.db`          | `JdbcTransaction.db`         |
| `Transaction.exec()`      | `JdbcTransaction.exec()`     |
| `Transaction.rollback()`  | `JdbcTransaction.rollback()` |

### 自定义函数

任何自定义事务范围的扩展函数很可能需要将接收者从 `Transaction` 更改为 `JdbcTransaction`，任何以前接受 `Transaction` 作为参数的函数也是如此：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.Transaction

fun Transaction.getVersionString(): String {
    val alias = "VERSION"
    val sql = "SELECT H2VERSION() AS $alias"
    val result = exec(sql) {
        it.next()
        it.getString(alias)
    }
    return result ?: ""
}
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.JdbcTransaction

fun JdbcTransaction.getVersionString(): String {
    val alias = "VERSION"
    val sql = "SELECT H2VERSION() AS $alias"
    val result = exec(sql) {
        it.next()
        it.getString(alias)
    }
    return result ?: ""
}
```

</compare>

### 事务 `id` 重命名

属性 `Transaction.id` 已重命名为 `Transaction.transactionId` 以避免与用户代码的常见命名冲突。

### `addLogger()`

在 1.0.0 版本之前，`.addLogger()` 作为原始 `Transaction` 类上的扩展函数可用，需要导入语句才能使用。

在 1.0.0 版本中，`addLogger()` 仍然可用，但作为新基类 `Transaction` 的方法，在各自的 `JdbcTransaction` 和 `R2dbcTransaction` 类中有最终方法重写：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.StdOutSqlLogger
import org.jetbrains.exposed.sql.addLogger
import org.jetbrains.exposed.sql.transactions.transaction

transaction { // this: Transaction
    addLogger(StdOutSqlLogger)
}
```

```kotlin
import org.jetbrains.exposed.v1.core.StdOutSqlLogger
import org.jetbrains.exposed.v1.jdbc.transactions.transaction

transaction { // this: JdbcTransaction
    addLogger(StdOutSqlLogger)
}
```

</compare>

### `transaction()` 签名更改

函数 `transaction()` 和 `inTopLevelTransaction()` 的声明参数顺序已更改，类型为 `Database` 的 `db` 参数现在是第一个参数。

`transactionIsolation` 参数还提供了基于数据库事务管理器设置的值的默认参数，默认为 `Database.connect()` 上配置的值。

`readOnly` 参数的默认参数不再是 `false`，而是也默认为从数据库事务管理器配置派生的值。

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.transactions.*

inTopLevelTransaction(
    Connection.TRANSACTION_SERIALIZABLE
) { }

transaction(
    db.transactionManager.defaultIsolationLevel,
    db = db
) { }
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.transactions.*

inTopLevelTransaction(
    transactionIsolation = Connection.TRANSACTION_SERIALIZABLE
) { }

transaction(db) { }
```

</compare>

### 事务管理器

`TransactionManager` 接口经历了类似的重新设计，只是保留在 `exposed-core` 中的接口已重命名为 `TransactionManagerApi`。此接口仅包含 JDBC 和 R2DBC 驱动共有的属性和方法。

在 1.0.0 版本中，您仍然可以在 `TransactionManager` 上调用伴生对象方法，因为新的实现已引入到 `exposed-jdbc` 和 `exposed-r2dbc` 中。其中一些方法的返回类型可能已更改为反映确切的 `Transaction` 实现：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.Transaction
import org.jetbrains.exposed.sql.transactions.TransactionManager

val tx1: Transaction? = TransactionManager.currentOrNull()
val tx2: Transaction = TransactionManager.current()
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.JdbcTransaction
import org.jetbrains.exposed.v1.jdbc.transactions.TransactionManager

val tx1: JdbcTransaction? = TransactionManager.currentOrNull()
val tx2: JdbcTransaction = TransactionManager.current()
```

</compare>

#### 驱动特定事务管理器接口

为了使用户能够为 JDBC 或 R2DBC 操作创建自定义事务管理器，引入了新接口：
* [`exposed-jdbc`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.transactions/-jdbc-transaction-manager/index.html) 中的 [`JdbcTransactionManager`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.transactions/-jdbc-transaction-manager/index.html)
* [`exposed-r2dbc`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.transactions/-r2dbc-transaction-manager/index.html) 中的 [`R2dbcTransactionManager`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.transactions/-r2dbc-transaction-manager/index.html)

两个接口都扩展了 `TransactionManagerApi`，并需要实现返回关联数据库实例（`Database` 或 `R2dbcDatabase`）的 `db` 属性。

每个模块中的具体 `TransactionManager` 类现在实现了相应的接口。这意味着多个 API 签名已更改为使用类型化管理器而不是 `TransactionManagerApi`：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.Database
import org.jetbrains.exposed.sql.transactions.TransactionManager

// JDBC
val manager: TransactionManager =
    Database.connect("jdbc:h2:mem:test", "org.h2.Driver")
        .transactionManager

Database.connect(
    url = "jdbc:h2:mem:test",
    driver = "org.h2.Driver",
    manager = { db: Database ->
        object : TransactionManager {
            // defaultIsolationLevel, defaultReadOnly, ...
            
            override fun newTransaction(
                isolation: Int,
                readOnly: Boolean,
                outerTransaction: Transaction?
            ): Transaction { /* ... */ }
    
            override fun currentOrNull(): Transaction? { /* ... */ }
    
            override fun bindTransactionToThread(transaction: Transaction?) { /* ... */ }
        }
    }
)

TransactionManager.registerManager(database, manager)

// Getting manager
val tm: TransactionManager? =
    TransactionManager.managerFor(database)
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.transactions.JdbcTransactionManager
import org.jetbrains.exposed.v1.jdbc.transactions.TransactionManager

// JDBC
val manager: JdbcTransactionManager =
    Database.connect("jdbc:h2:mem:test", "org.h2.Driver")
        .transactionManager

Database.connect(
    url = "jdbc:h2:mem:test",
    driver = "org.h2.Driver",
    manager = { db: Database ->
        object : JdbcTransactionManager {
            override val db = db

            fun newTransaction(
                isolation: Int = defaultIsolationLevel,
                readOnly: Boolean = defaultReadOnly,
                outerTransaction: JdbcTransaction? = null
            ): JdbcTransaction { /* ... */ }
        }
    }
)

TransactionManager.registerManager(database, manager)

// Getting manager
val tm: JdbcTransactionManager =
    TransactionManager.managerFor(database)
```

</compare>

连接 `manager` 参数的默认参数不再是 `ThreadLocalTransactionManager`，该类现已被移除。新实现的 [`TransactionManager`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.transactions/-transaction-manager/index.html) 现在作为默认参数传递。

此外，`currentOrNull()` 方法已从 `TransactionManagerApi` 接口中移除。现在可用作：
* `JdbcTransactionManager` 和 `R2dbcTransactionManager` 上的扩展函数
* 两个模块中 `TransactionManager` 伴生对象上的静态方法

如果您在管理器实例上调用 `currentOrNull()`，请将其替换为静态方法或将管理器转换为适当的类型化接口：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.Database
import org.jetbrains.exposed.sql.transactions.TransactionManagerApi

val manager: TransactionManagerApi =
    Database.connect(...).transactionManager
val tx = manager.currentOrNull()
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.transactions.JdbcTransactionManager
import org.jetbrains.exposed.v1.jdbc.transactions.currentOrNull

val manager: JdbcTransactionManager =
    Database.connect(...).transactionManager
val tx = manager.currentOrNull()
```

</compare>

<compare first-title="0.61.0" second-title="1.0.0 (静态方法)">

```kotlin
import org.jetbrains.exposed.sql.Database
import org.jetbrains.exposed.sql.transactions.TransactionManagerApi

val manager: TransactionManagerApi =
    Database.connect(...).transactionManager
val tx = manager.currentOrNull()
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.transactions.TransactionManager

Database.connect(...)

val tx = TransactionManager.currentOrNull()
```

</compare>

#### 事务管理变更

作为重新设计的一部分，底层数据库事务管理逻辑和活动事务的切换已更改为不再依赖 `ThreadLocal`。这意味着属性 `TransactionManager.threadLocal` 以及方法 `TransactionManagerApi.bindTransactionToThread()` 和 `TransactionManager.resetCurrent()` 都已被移除。

`Database` 实例与其 `TransactionManager` 之间的关联也已精简，以确保更严格、更可靠的关系。因此，进行了以下更改：
* `TransactionManager.managerFor()` 的签名已更改为仅接受非空 `database` 参数，其返回类型现在是非空的 `JdbcTransactionManager`（或 R2DBC 的 `R2dbcTransactionManager`）。
* 顶层属性 `transactionManager` 不再接受可空的 `Database` 作为其接收者。
* `TransactionManager.isInitialized()` 也已被移除。

在 1.0.0 版本之前，`TransactionManager.defaultDatabase` 用于检索已设置为所有事务使用的默认 `Database` 实例，或者如果未设置默认值，则为最后创建的实例。在 1.0.0 中，此功能已拆分以简化：
* `TransactionManager.defaultDatabase`：获取和设置打开事务时要使用的默认数据库。除非在某个时刻显式设置，否则此值将保持为 null。
* `TransactionManager.primaryDatabase`：获取打开下一个事务时将使用的数据库。此值将从 `defaultDatabase` 或最后注册的 `Database` 实例（如果有）中检索。

在 1.0.0 版本之前，属性 `TransactionManager.manager` 从线程本地解析其值，如果未找到则返回未初始化的替代管理器。在 1.0.0 中，检索的管理器实例基于当前活动事务（如果有）解析；否则获取默认设置数据库或最后注册的数据库实例的管理器。如果无法解析管理器，此属性现在会抛出异常。

### JDBC `suspend` 函数弃用

原始的顶层挂起事务函数，即 `newSuspendedTransaction()`、`withSuspendTransaction()` 和 `suspendedTransactionAsync()`，已从 `exposed-core` 移至 `exposed-jdbc`。它们也已弃用，转而切换到 R2DBC 操作或使用新引入的 JDBC 函数 `suspendTransaction()` 和 `inTopLevelSuspendTransaction()`。

如果您想继续使用阻塞 JDBC 驱动，但能够在数据库事务操作旁边调用挂起函数，则应使用这些新函数。这些函数的行为与标准 `transaction()` 函数的行为完全一致，例如涉及嵌套逻辑和异常处理的部分。与原始挂起事务函数不同，`suspendTransaction()` 不接受 `CoroutineContext` 参数。相反，应使用协程构建器函数（如 `withContext()` 或 `async()`）来包装 `suspendTransaction()` 块。

> 要使用响应式驱动正确运行异步事务，
> `suspendTransaction()` 重载现在可从 `exposed-r2dbc` 依赖获取。
>
> {style="tip"}

## 语句构建器和可执行对象

抽象类 `Statement` 保留在 `exposed-core` 中，连同其所有原始实现（如 `InsertStatement`）。但从 1.0.0 版本开始，这些语句类不再持有任何与其在数据库中的特定执行相关的逻辑，也不存储任何关于创建它们的事务的知识。这些类现在仅负责 SQL 语法构建和参数绑定。

原始提取的逻辑现在由 `exposed-jdbc` 中新引入的接口 `BlockingExecutable` 拥有。R2DBC 变体是 `exposed-r2dbc` 中的 `SuspendExecutable`。每个核心语句实现现在都有一个关联的可执行实现，如 `InsertBlockingExecutable`，后者在其 `statement` 属性中存储前者。以下是一些所有权变更的示例：

| 0.61.0                                                       | 1.0.0                                                                     |
|--------------------------------------------------------------|---------------------------------------------------------------------------|
| `Statement.execute()`                                        | `BlockingExecutable.execute()`                                            |
| `Statement.prepared()`                                       | `BlockingExecutable.prepared()`                                           |
| `with(Statement) { PreparedStatementApi.executeInternal() }` | `with(BlockingExecutable) { JdbcPreparedStatementApi.executeInternal() }` |
| `Statement.isAlwaysBatch`                                    | `BlockingExecutable.isAlwaysBatch`                                        |

如果语句实现原始持有受保护的 `transaction` 属性，现在也由可执行实现拥有。

### 自定义语句

这种职责分离意味着任何自定义 `Statement` 实现现在需要一个关联的 `BlockingExecutable` 实现才能发送到数据库。此 `BlockingExecutable` 可以是自定义的，或者如果它提供足够的执行逻辑，您可以使用现有类，如下例所示：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.Transaction
import org.jetbrains.exposed.sql.statements.BatchInsertStatement
import org.jetbrains.exposed.sql.transactions.transaction

class BatchInsertOnConflictDoNothing(
    table: Table,
) : BatchInsertStatement(table) {
    override fun prepareSQL(
        transaction: Transaction,
        prepared: Boolean
    ) = buildString {
        val insertStatement = super.prepareSQL(transaction, prepared)
        append(insertStatement)
        append(" ON CONFLICT (id) DO NOTHING")
    }

    // optional custom execute logic
}

transaction {
    val insertedCount: Int? = BatchInsertOnConflictDoNothing(
        TableA
    ).run {
        addBatch()
        // set column values using this[columnName] = value

        addBatch()
        // set column values using this[columnName] = value

        execute(this@transaction)
    }
}
```

```kotlin
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.core.Transaction
import org.jetbrains.exposed.v1.core.statements.BatchInsertStatement
import org.jetbrains.exposed.v1.jdbc.statements.toExecutable
import org.jetbrains.exposed.v1.jdbc.transactions.transaction

class BatchInsertOnConflictDoNothing(
    table: Table,
) : BatchInsertStatement(table) {
    override fun prepareSQL(
        transaction: Transaction,
        prepared: Boolean
    ) = buildString {
        val insertStatement = super.prepareSQL(transaction, prepared)
        append(insertStatement)
        append(" ON CONFLICT (id) DO NOTHING")
    }

    // optional custom execute logic -> create custom Executable
}

transaction {
    val executable = BatchInsertOnConflictDoNothing(TableA).toExecutable()
    val insertedCount: Int? = executable.run {
        statement.addBatch()
        // set column values using statement[column] = value

        statement.addBatch()
        // set column values using statement[column] = value

        execute(this@transaction)
    }
}
```

</compare>

<note>
可以通过调用 <code>.toExecutable()</code>（
<a href="https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.statements/to-executable.html">JDBC</a>、
<a href="https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.statements/to-executable.html">R2DBC</a>）
为您解析适当的可执行类实例，只要自定义语句扩展了 Exposed API 中的现有子类。或者，自定义语句可以直接作为参数传递给已知可执行类的构造函数。
</note>

### `exec()` 参数类型更改

在 1.0.0 版本之前，可以使用内置或自定义实现创建 `Statement` 实例，并通过将其作为参数传递给 `exec()` 来发送到数据库。

在 1.0.0 版本中，由于语句不再负责执行，相同的 `exec()` 方法仅接受 `BlockingExecutable` 作为其参数：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.statements.DeleteStatement
import org.jetbrains.exposed.sql.transactions.transaction

transaction {
    val delete = DeleteStatement(
        targetsSet = TableA,
        where = null
    )
    val result = exec(delete) {
        // do something with deleted row count
    }
}
```

```kotlin
import org.jetbrains.exposed.v1.core.statements.DeleteStatement
import org.jetbrains.exposed.v1.jdbc.statements.toExecutable
import org.jetbrains.exposed.v1.jdbc.transactions.transaction

transaction {
    val deleteStmt = DeleteStatement(
        targetsSet = TableA,
        where = null
    )
    val delete = deleteStmt.toExecutable()
    val result = exec(delete) {
        // do something with deleted row count
    }
}
```

</compare>

<note>
可以通过调用 <code>.toExecutable()</code>（
<a href="https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.statements/to-executable.html">JDBC</a>、
<a href="https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.statements/to-executable.html">R2DBC</a>）为您解析适当的可执行类实例。
或者，语句可以直接作为参数传递给 <code>DeleteBlockingExecutable</code> 构造函数。
</note>

此签名更改不影响该方法与 `Query` 参数的使用，因为 `Query` 直接实现了 `BlockingExecutable`。但 Exposed 处理查询结果的方式更改会影响 lambda 块参数的类型。

在 1.0.0 版本之前，从数据库检索的 `java.sql.ResultSet` 直接作为参数传递。在 1.0.0 版本中，此结果由通用的 `ResultApi` 对象包装，如果要使用原始 `exec()` 直接处理底层 `ResultSet`，则需要转换为 `JdbcResult`：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction

transaction {
    val query = TablA
        .select(TableA.amount)
        .where { TableA.amount greater 100 }

    val result = exec(query) {
        val amounts = mutableListOf<Int>()
        while (it.next()) {
            amounts += it.getInt("amount") % 10
        }
        amounts
    }
}
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.statements.jdbc.JdbcResult
import org.jetbrains.exposed.v1.jdbc.transactions.transaction

transaction {
    val query = TablA
        .select(TableA.amount)
        .where { TableA.amount greater 100 }

    val result = exec(query) {
        val rs = (it as JdbcResult).result
        val amounts = mutableListOf<Int>()
        while (rs.next()) {
            amounts += rs.getInt("amount") % 10
        }
        amounts
    }
}
```

</compare>

您可以通过将 `exec()` 替换为 `execQuery()` 来避免此转换，并继续在 lambda 中使用原始的 1.0.0 之前代码。后者在底层自动执行必要的转换和解包，因此您可以像以前一样继续直接使用 `ResultSet`：

```kotlin
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.statements.jdbc.JdbcResult
import org.jetbrains.exposed.v1.jdbc.transactions.transaction

transaction {
    val query = TablA
        .select(TableA.amount)
        .where { TableA.amount greater 100 }

    val result = execQuery(query) {
        val amounts = mutableListOf<Int>()
        while (it.next()) {
            amounts += it.getInt("amount") % 10
        }
        amounts
    }
}
```

<note>
如果最初传递给 <code>exec()</code> 的语句是通过 <code>explain()</code> 或任何返回结果的 DML 函数（例如 <code>.insertReturning()</code>）获得的，也建议使用 <code>execQuery()</code>。
</note>

有关 Exposed 处理查询结果的更改背后的更多详情，请参见[结果包装器](#result-wrappers)。

### `ReturningStatement` 返回类型更改

在 1.0.0 版本之前，返回指定列值的表扩展函数（如 `insertReturning()` 和 `updateReturning()`）返回类型为 `ReturningStatement` 的值。此返回类型确保此类语句仅在终端操作尝试迭代结果时才发送到数据库。

在 1.0.0 版本中，由于所有执行逻辑已从核心 `ReturningStatement` 中移除，这些函数改为返回类型为 `ReturningBlockingExecutable` 的值。除了此返回类型更改外，返回值可以像以前一样迭代。

### `DeleteStatement` 伴生方法弃用

在 1.0.0 版本之前，`DeleteStatement` 的伴生对象提供了 `.all()` 和 `.where()` 方法作为调用 `Table.deleteAll()` 或 `Table.deleteWhere()` 的替代方案。

在 1.0.0 版本从 `exposed-core` 中移除语句执行逻辑后，这些伴生方法现已弃用。建议直接使用表扩展函数或将 `DeleteStatement` 构造函数与 `DeleteBlockingExecutable` 结合使用。

### `SqlExpressionBuilder` lambda 块 {id = sql-expression-builder-lambda}

如[上面的导入部分](#sql-expression-builder-imports)所述，`SqlExpressionBuilder` 对象已弃用。

在 1.0.0 版本之前，许多高阶函数使用此对象作为参数接收者，以允许访问其方法而无需为每个使用的方法添加导入语句。由于所有这些对象方法都已被顶层函数替代，此类接收者现在是多余的，已被移除。

传递给这些函数参数的所有表达式构建器方法现在将无法解析，除非已经存在 `import org.jetbrains.exposed.v1.core.*` 之类的语句，或者添加了提示的导入语句：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.and
import org.jetbrains.exposed.sql.count
import org.jetbrains.exposed.sql.longLiteral
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.update

TableA.update(
    where = { TableA.details like "%S/O" }
) {
    it.update(TableA.amount) { TableA.amount plus 3 }
}

TableA
    .selectAll()
    .where {
        TableA.details eq "N/A" and TableA.warranty.isNull()
    }
    .groupBy(TableA.label)
    .having {
        TableA.label.count() greaterEq longLiteral(1)
    }
```

```kotlin
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.count
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.greaterEq
import org.jetbrains.exposed.v1.core.isNull
import org.jetbrains.exposed.v1.core.like
import org.jetbrains.exposed.v1.core.longLiteral
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.update

TableA.update(
    where = { TableA.details like "%S/O" }
) {
    it.update(TableA.amount) { TableA.amount plus 3 }
}

TableA
    .selectAll()
    .where {
        TableA.details eq "N/A" and TableA.warranty.isNull()
    }
    .groupBy(TableA.label)
    .having {
        TableA.label.count() greaterEq longLiteral(1)
    }
```

</compare>

### `BaseBatchInsertStatement` 移除

抽象类 `BaseBatchInsertStatement` 已被移除。其所有元素已整合并替换为单一的开放类 `BatchInsertStatement`。`BaseBatchInsertStatement` 的任何自定义扩展都可以安全地替换为扩展 `BatchInsertStatement`。

## 查询

虽然 `AbstractQuery` 类保留在 `exposed-core` 中，但其 `Query` 实现现在在 `exposed-jdbc` 中，R2DBC 变体位于 `exposed-r2dbc` 中。此重构是必要的，以允许每个类的底层实现存在所需差异，JDBC `Query` 最终实现 `Iterable`，而 R2DBC `Query` 实现 `Flow`。

### `CommentPosition` 所有权更改

某些 `Query` 属性（如 `where` 和 `having`）及其关联的调整方法已从子类移至超类 `AbstractQuery`，以便它们对两个驱动保持通用。

这还包括 `comments` 属性及其相关的枚举类 `CommentPosition`，现在只能从 `AbstractQuery` 访问：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.Query
import org.jetbrains.exposed.sql.selectAll

val queryWithHint = TableA
    .selectAll()
    .comment(
        content = "+ MAX_EXECUTION_TIME(1000) ",
        position = Query.CommentPosition.AFTER_SELECT
    )
```

```kotlin
import org.jetbrains.exposed.v1.core.AbstractQuery
import org.jetbrains.exposed.v1.jdbc.selectAll

val queryWithHint = TableA
    .selectAll()
    .comment(
        content = "+ MAX_EXECUTION_TIME(1000) ",
        position = AbstractQuery.CommentPosition.AFTER_SELECT
    )
```

</compare>

### `Case` 属性 `value` 移除

在 1.0.0 版本之前，`Case` 类有一个 `value` 属性，链式条件可以与之进行比较，只要属性中存储的表达式是布尔类型。

此类现已拆分为没有此属性的通用 `Case` 类和具有 `ExpressionWithColumnType` 类型 `value` 属性的单独 `ValueCase` 类。这些表示表达式构建器实例，分别用于促进以下语法：`CASE WHEN <condition> THEN <result> END` 和 `CASE <value0> WHEN <value1> THEN <result> END`。

只要传递的参数是 `ExpressionWithColumnType` 类型，使用 `case(value)` 函数开始基于值的 CASE 表达式的任何用法保持不变（除了更新的导入语句）。任何直接使用 `Case(value)` 构造函数的情况必须替换为 `ValueCase(value)` 构造函数或 `case(value)` 函数：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.less
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentDate

val statusCase = Case(Books.isOverdue)
    .When(Books.dueDate less CurrentDate, booleanLiteral(true))
    .Else(booleanLiteral(false))
    .alias("status_valid")
```

```kotlin
import org.jetbrains.exposed.v1.core.*
import org.jetbrains.exposed.v1.datetime.CurrentDate

val statusCase = ValueCase(Books.isOverdue)
    .When(Books.dueDate less CurrentDate, booleanLiteral(true))
    .Else(booleanLiteral(false))
    .alias("status_valid")
```

</compare>

## 结果包装器 {#result-wrappers}

两个新的 `exposed-core` 接口 `ResultApi` 和 `RowApi` 已被引入，以表示 JDBC（`java.sql.ResultSet`）和 R2DBC（`io.r2dbc.spi.Result`）查询执行结果之间的共性。两者都由新的驱动特定包装类 `JdbcResult` 和 `R2dbcResult` 实现。

### `readObject()` 参数类型更改 {id = read-object}

由于驱动特定结果（如 `java.sql.ResultSet`）不再在 `exposed-core` 中支持，它们被通用接口（如 `RowApi`）包装。

`IColumnType` 接口有一个 `readObject()` 方法，用于在访问结果中特定索引的对象时执行任何特殊的读取或转换逻辑。此方法的签名已更改为使用 `RowApi` 而不是 `ResultSet`，这仍然允许通过 `getObject()` 访问底层的 JDBC `ResultSet` 或 R2DBC `Row`：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.TextColumnType
import java.sql.ResultSet

class ShortTextColumnType : TextColumnType() {
    override fun readObject(
        rs: ResultSet,
        index: Int
    ): Any? {
        return rs
            .getString(index)
            .take(MAX_CHARS)
    }

    companion object {
        private const val MAX_CHARS = 128
    }
}
```

```kotlin
import org.jetbrains.exposed.v1.core.TextColumnType
import org.jetbrains.exposed.v1.core.statements.api.RowApi

class ShortTextColumnType : TextColumnType() {
    override fun readObject(
        rs: RowApi,
        index: Int
    ): Any? {
        return rs
            .getObject(index, java.lang.String::class.java)
            ?.take(MAX_CHARS)
    }

    companion object {
        private const val MAX_CHARS = 128
    }
}
```

</compare>

除了切换到 `getObject()` 之外，原始在 `ResultSet` 上调用的代码仍然可以通过 `RowApi.origin` 访问底层包装的结果来使用：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.TextColumnType
import java.sql.ResultSet

class ShortTextColumnType : TextColumnType() {
    override fun readObject(
        rs: ResultSet,
        index: Int
    ): Any? {
        return rs
            .getString(index)
            .take(MAX_CHARS)
    }

    companion object {
        private const val MAX_CHARS = 128
    }
}
```

```kotlin
import org.jetbrains.exposed.v1.core.TextColumnType
import org.jetbrains.exposed.v1.core.statements.api.RowApi

class ShortTextColumnType : TextColumnType() {
    override fun readObject(
        rs: RowApi,
        index: Int
    ): Any? {
        return rs.origin
            .getString(index)
            .take(MAX_CHARS)
    }

    companion object {
        private const val MAX_CHARS = 128
    }
}
```

</compare>

### `ResultRow.create()` 参数类型更改

如 [`readObject()`](#read-object) 部分所述，所有 `java.sql.ResultSet` 的使用已从 `exposed-core` 中移除。直接从查询或语句执行结果创建 Exposed `ResultRow` 的伴生方法现在接受 `RowApi` 作为参数。

### `execute()` 返回类型更改

直接在 `Query` 上调用 `execute()` 不再返回 `ResultSet`。它改为返回 `ResultApi`，如果需要访问原始包装的结果类型，则必须进行转换：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import java.sql.ResultSet

transaction {
    val result: ResultSet? = TableA
        .selectAll()
        .where { TableA.amount greater 100 }
        .execute(this)
}
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.statements.jdbc.JdbcResult
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import java.sql.ResultSet

transaction {
    val result: ResultSet? = (TableA
        .selectAll()
        .where { TableA.amount greater 100 }
        .execute(this) as? JdbcResult)
        ?.result
}
```

</compare>

### `StatementResult.Object` 属性类型更改

`exposed-core` 密封类 `StatementResult` 中的 `Object` 类型不再具有 `java.sql.ResultSet` 类型的属性。其属性现在是 `ResultApi` 类型。

## 列类型

### 更新的 UUID 类型类 {id = uuid-column-type-refactor}

版本 1.0.0 通过新的 `UuidColumnType` 类支持在二进制列中存储 `kotlin.uuid.Uuid` 值。通过将 `UuidTable` 与 `UuidEntity` 和 `UuidEntityClass` 一起使用，还可以获得对 DAO API 元素的内置支持。现有的 `Table.uuid()` 方法现在将只接受 `kotlin.uuid.Uuid` 类型的值。

为了避免名称遮蔽和未解析错误，用于存储 `java.util.UUID` 值的原始类都已移至新的 `.java.*` 包：

| 0.61.0                                      | 1.0.0                                                 |
|---------------------------------------------|-------------------------------------------------------|
| `org.jetbrains.exposed.sql.UUIDColumnType`  | `org.jetbrains.exposed.v1.core.java.UUIDColumnType`   |
| `org.jetbrains.exposed.dao.id.UUIDTable`    | `org.jetbrains.exposed.v1.core.dao.id.java.UUIDTable` |
| `org.jetbrains.exposed.dao.UUIDEntity`      | `org.jetbrains.exposed.v1.dao.java.UUIDEntity`        |
| `org.jetbrains.exposed.dao.UUIDEntityClass` | `org.jetbrains.exposed.v1.dao.java.UUIDEntityClass`   |

要继续传递 `java.util.UUID` 值，应更新导入语句，任何使用 `Table.uuid()` 的情况都应替换为扩展函数 `.javaUUID()`，并添加 `import org.jetbrains.exposed.v1.core.java.javaUUID`。

虽然 `UuidColumnType` 和 `UUIDColumnType` 在客户端接受不同的 UUID 类型，但它们都映射到数据库端的相同数据类型。这意味着保持使用 `Table.uuid()`（或切换到新的 `UuidTable`）不会触发任何迁移 DDL 语句的生成。

假设版本 0.61.0 的以下表和实体对象：

```kotlin
import org.jetbrains.exposed.dao.id.*
import org.jetbrains.exposed.dao.*
import java.util.UUID

object TestTable : UUIDTable("tester") {
    val secondaryId = uuid("secondary_id").uniqueIndex()
}

class TestEntity(id: EntityID<UUID>) : UUIDEntity(id) {
    companion object : UUIDEntityClass<TestEntity>(TestTable)

    var secondaryId by TestTable.secondaryId
}
```

应根据所需的客户端类型进行以下更改：

<compare first-title="kotlin.uuid.Uuid" second-title="java.util.UUID">

```kotlin
import org.jetbrains.exposed.v1.core.dao.id.*
import org.jetbrains.exposed.v1.dao.*
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

object TestTable : UuidTable("tester") {
    @OptIn(ExperimentalUuidApi::class)
    val secondaryId = uuid("secondary_id").uniqueIndex()
}

@OptIn(ExperimentalUuidApi::class)
class TestEntity(id: EntityID<Uuid>) : UuidEntity(id) {
    companion object : UuidEntityClass<TestEntity>(TestTable)

    var secondaryId by TestTable.secondaryId
}
```

```kotlin
import org.jetbrains.exposed.v1.core.dao.id.java.UUIDTable
import org.jetbrains.exposed.v1.core.java.javaUUID
import org.jetbrains.exposed.v1.dao.java.*
import java.util.UUID

object TestTable : UUIDTable("tester") {
    val secondaryId = javaUUID("secondary_id").uniqueIndex()
}

class TestEntity(id: EntityID<UUID>) : UUIDEntity(id) {
    companion object : UUIDEntityClass<TestEntity>(TestTable)

    var secondaryId by TestTable.secondaryId
}
```

</compare>

<note>
在撰写本文时，标准库中的 <code>kotlin.uuid.Uuid</code> 支持是实验性的。要选择加入，可以使用
<code>@OptIn(ExperimentalUuidApi::class)</code> 注解，或添加文件级注解 <code>@file:OptIn(ExperimentalUuidApi::class)</code>，
或将编译器选项添加到您的<a href="https://kotlinlang.org/docs/opt-in-requirements.html#opt-in-a-module">构建文件</a>中。
</note>

### H2 DATETIME 数据类型

从 [H2 版本 2.4.240](https://github.com/h2database/h2database/releases/tag/version-2.4.240) 开始，`DATETIME(9)` 数据类型
[不再被接受](https://github.com/h2database/h2database/issues/4285)，除非使用某些兼容模式。这是以下 H2 模式的 `datetime()` 列映射到的数据类型：常规、MySQL 和 MariaDB。

展望未来，对于使用版本 2.4.240 或更高版本的任何 `Database` 实例，这些模式的 `datetime()` 列将改为映射到 `TIMESTAMP(9)`。
较旧版本的 H2 保留原始数据类型映射。

### `exposed-kotlin-datetime` `timestamp()` 映射类型

在 1.0.0 版本之前，`KotlinInstantColumnType` 和 `Table.timestamp()`（来自 `exposed-kotlin-datetime`）
映射为接受 `kotlinx.datetime.Instant` 值。现在它们只接受 `kotlin.time.Instant` 值。
这也适用于 `CurrentTimestamp`、`CustomTimeStampFunction` 以及任何将旧的
`kotlinx.datetime.Instant` 作为类型参数的提供函数。

<note>
<code>kotlin.time.Instant</code> 在标准库中的支持在 Kotlin 2.3 之前是实验性的。要选择加入，可以使用
<code>@OptIn(ExperimentalTime::class)</code> 注解，或添加文件级注解 <code>@file:OptIn(ExperimentalTime::class)</code>，
或将编译器选项添加到您的<a href="https://kotlinlang.org/docs/opt-in-requirements.html#opt-in-a-module">构建文件</a>中。
</note>

如果仍然需要 `kotlinx.datetime.Instant`，所有用法必须替换为带有 'X' 前缀的已弃用变体。例如，`XKotlinInstantColumnType`、`Table.xTimestamp()`、`XCurrentTimestamp` 和 `XCustomTimeStampFunction`。使用 `kotlinx.datetime.Instant` 作为类型参数的函数重载仍然可用，但已弃用。

### 日期时间列类型类重构 {id = datetime-column-type-refactor}

日期时间构件已重构为扩展 `exposed-core` 中的新抽象列类型类。`exposed-java-time` 和 `exposed-kotlin-datetime` 中的所有原始列类型类保持不变，只是它们现在扩展了这些基类核心类。

#### `exposed-jodatime` 中更新的类

在 `exposed-jodatime` 构件中，大多数原始类已被拆分和/或重命名以反映正在扩展的新超类。这主要影响这些类的直接使用，例如在自定义函数中。下表显示了类更改：

| 0.61.0                                                               | 1.0.0                                                               |
|----------------------------------------------------------------------|---------------------------------------------------------------------|
| `org.jetbrains.exposed.sql.jodatime.DateColumnType(time=false)`      | `org.jetbrains.exposed.v1.jodatime.JodaLocalDateColumnType`         |
| `org.jetbrains.exposed.sql.jodatime.DateColumnType(time=true)`       | `org.jetbrains.exposed.v1.jodatime.JodaLocalDateTimeColumnType`     |
| `org.jetbrains.exposed.sql.jodatime.LocalTimeColumnType`             | `org.jetbrains.exposed.v1.jodatime.JodaLocalTimeColumnType`         |
| `org.jetbrains.exposed.sql.jodatime.DateTimeWithTimeZoneColumnType ` | `org.jetbrains.exposed.v1.jodatime.DateTimeWithTimeZoneColumnType ` |

## `DatabaseDialect` 和 `VendorDialect`

`exposed-core` 接口 `DatabaseDialect` 中任何需要驱动特定元数据查询的方法都已被提取。如果已移除，该方法现在可从 `exposed-jdbc` 中的新抽象类 `DatabaseDialectMetadata` 访问。这也适用于核心 `VendorDialect` 实现中的此类方法和属性。以下是一些所有权变更的示例：

| 0.61.0                                              | 1.0.0                                       |
|-----------------------------------------------------|---------------------------------------------|
| `DatabaseDialect.allTablesNames()`                  | `DatabaseDialectMetadata.allTablesNames()`  |
| `DatabaseDialect.tableColumns()`                    | `DatabaseDialectMetadata.tableColumns()`    |
| `DatabaseDialect.catalog()`                         | `DatabaseDialectMetadata.catalog()`         |
| `DatabaseDialect.existingIndices()`                 | `DatabaseDialectMetadata.existingIndices()` |

<note>
上述 <code>DatabaseDialect</code> 方法最初调用的底层元数据查询函数的相应所有权变更也已引入。这意味着 <code>exposed-core</code> 中的抽象类 <code>ExposedDatabaseMetadata</code> 还将其部分方法提取到了 <code>exposed-jdbc</code> 和 <code>exposed-r2dbc</code> 中的驱动特定实现。
</note>

这些方法以前最常在顶层属性 `currentDialect` 上调用。为了遵循类似的模式，添加了相关属性 `currentDialectMetadata` 来替代原始调用：

<compare first-title="0.61.0" second-title="1.0.0">

```kotlin
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.vendors.currentDialect

transaction {
    val tableKeys = currentDialect.existingPrimaryKeys(TableA)[TableA]
    if (TableA.tableName in currentDialect.allTablesNames()) {
        // do something
    }
}
```

```kotlin
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.vendors.currentDialectMetadata

transaction {
    val tableKeys = currentDialectMetadata.existingPrimaryKeys(TableA)[TableA]
    if (TableA.tableName in currentDialectMetadata.allTablesNames()) {
        // do something
    }
}
```

</compare>

### H2 版本 1.x.x

对 H2 2.0.202 之前版本（即 1.4.200 及更早版本）的支持现已完全淘汰。此外，`H2Dialect.H2MajorVersion.One` 现已被移除，`H2Dialect` 特定属性（如 `majorVersion` 和 `isSecondVersion`）现在在检测到 H2 版本 1.x.x 时会抛出异常。

展望未来，新功能将不再在 H2 版本 1.x.x 上测试，因此不保证对这些版本的支持。根据这些较旧 H2 版本的内置支持，Exposed API 可能仍然大部分兼容，但在生成某些 SQL 子句时可能会抛出语法或不支持的异常。

### 自定义方言

就像 `exposed-core` 中有数据库特定实现用于进一步扩展（如 `H2Dialect`）一样，新类也带有用于元数据扩展的开放实现（如 `H2DialectMetadata`）。这些新类应被扩展以容纳任何已移除元数据方法的自定义覆盖。

任何自定义数据库方言实现都可以像以前一样通过 `Database.registerDialect()` 注册。在 1.0.0 版本中，应使用额外的 `Database.registerDialectMetadata()` 调用以确保新关联的元数据实现也被注册。

### `areEquivalentColumnTypes()` 弃用

`DatabaseDialect.areEquivalentColumnTypes()` 已弃用，转而使用在 `org.jetbrains.exposed.v1.core.statements.api.ExposedDatabaseMetadata` 下找到的驱动无关变体 `areEquivalentColumnTypes()`。驱动特定变体已在 `exposed-jdbc` 和 `exposed-r2dbc` 中引入，可通过调用 `currentDialectMetadata.areEquivalentColumnTypes()` 直接访问。

### `resolveRefOptionFromJdbc()` 移除

鉴于此方法的原始意图，`DatabaseDialect.resolveRefOptionFromJdbc()` 已被移除，并由在 `org.jetbrains.exposed.v1.core.statements.api.ExposedDatabaseMetadata` 下找到的驱动无关变体 `resolveReferenceOption()` 替代。驱动特定变体已在 `exposed-jdbc` 和 `exposed-r2dbc` 中引入。

### 属性 `supportsSelectForUpdate` 弃用

`DatabaseDialect.supportsSelectForUpdate` 已弃用，转而使用在 `exposed-jdbc` 和 `exposed-r2dbc` 中实现的驱动特定 `DatabaseApi` 属性。一旦数据库已注册连接，可以直接从它访问此属性，例如通过调用 `TransactionManager.current().db.supportsSelectForUpdate`。

### 属性 `ENABLE_UPDATE_DELETE_LIMIT` 移除

`SQLiteDialect()` 伴生对象中的此属性已被移除，并完全由 `DatabaseDialectMetadata.supportsLimitWithUpdateOrDelete()` 替代。

## 其他核心类重构

其他一些公共类已重构，以从 `exposed-core` 中移除任何驱动特定逻辑。

### `Database`

新的抽象类 `DatabaseApi` 已添加到 `exposed-core` 中，用于保存与 JDBC 和 R2DBC 数据库及其未来连接相关的所有属性和方法。原始的 `Database` 类及其伴生对象已移至 `exposed-jdbc`，新类 `R2dbcDatabase` 已引入到 `exposed-r2dbc`。

### `PreparedStatementApi`

`PreparedStatementApi` 接口不再持有执行任何语句执行逻辑的方法。

在 1.0.0 版本中，这些现在只能从新的驱动特定接口实现 `JdbcPreparedStatementApi` 访问。以下是一些所有权变更的示例：

| 0.61.0                                       | 1.0.0                                      |
|----------------------------------------------|--------------------------------------------|
| `PreparedStatementApi.executeQuery()`        | `JdbcPreparedStatementApi.executeQuery()`  |
| `PreparedStatementApi.executeUpdate()`       | `JdbcPreparedStatementApi.executeUpdate()` |
| `PreparedStatementApi.addBatch()`            | `JdbcPreparedStatementApi.addBatch()`      |
| `PreparedStatementApi.cancel()`              | `JdbcPreparedStatementApi.cancel()`        |

#### `set()` 移除

原始的 `operator fun set(index: Int, value: Any)` 已被移除。应替换为接受第三个参数的新变体，该参数用于与绑定到语句的值关联的列类型。如果直接实现接口，此新的 `set()` 方法将需要重写。

#### `setArray()` 移除

原始的 `setArray(index: Int, type: String, array: Array<*>)` 已被移除。应替换为接受与绑定到语句的数组值关联的实际 `ArrayColumnType` 作为第二个参数的新变体，而不是类型的字符串表示。如果直接实现接口，此新的 `setArray()` 方法将需要重写。
