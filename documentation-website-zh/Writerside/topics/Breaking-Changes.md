# 破坏性变更

## 1.0.0

* 接口 `R2dbcPreparedStatementApi` 不再包含未使用的方法 `closeIfPossible()` 或 `cancel()`，
  因为 `io.r2dbc.spi.Statement` 没有相关的匹配方法，不像 JDBC 的 `java.sql.PreparedStatement` 那样。任何可能通过这些方法实现的资源清理逻辑仍然可以通过 `GlobalStatementInterceptor.afterStatementPrepared()` 实现。
* `R2dbcTransaction.closeExecutedStatements()` 已重命名为 `.clearExecutedStatements()` 以更好地传达其实际行为。它不再调用现已移除的方法 `R2dbcPreparedStatementApi.closeIfPossible()`，也不再挂起。
* 当 SQLite 与 `jsonb()` 一起使用时，这些 JSONB 列现在在查询的 `SELECT` 子句中包含时会自动包装在 SQL 函数 `JSON()` 中。这有助于更轻松地读取并在多个数据库之间使用相同的查询，但可以通过设置新的 `jsonb()` 参数 `castToJsonFormat=false` 来禁用此自动包装行为。如果禁用，仍然可以使用新的 `.castToJson()` 函数包装单个 SQLite JSONB 列以获取更易读的格式。作为此更改的一部分，`exposed-core` 接口 `JsonColumnMarker` 获得了一个新属性 `needsBinaryFormatCast`。
* **事务管理器类型变更**：引入了新接口 `JdbcTransactionManager` 和 `R2dbcTransactionManager`，多个公共 API 返回类型已相应更新。以下签名已更改：
    * `Database.transactionManager` 现在返回 `JdbcTransactionManager` 而不是 `TransactionManager`
    * `R2dbcDatabase.transactionManager` 现在返回 `R2dbcTransactionManager` 而不是 `TransactionManager`
    * `JdbcTransaction.transactionManager` 属性类型更改为 `JdbcTransactionManager`
    * `R2dbcTransaction.transactionManager` 属性类型更改为 `R2dbcTransactionManager`
    * `TransactionManager.manager` 现在返回 `JdbcTransactionManager` 或 `R2dbcTransactionManager` 而不是 TransactionManager
    * `TransactionManager.managerFor()` 现在返回 `JdbcTransactionManager` 或 `R2dbcTransactionManager` 而不是 TransactionManager
    * `TransactionManager.registerManager()` 现在接受 `JdbcTransactionManager` 或 `R2dbcTransactionManager` 而不是 `TransactionManagerApi`
    * `Database.connect()` 方法的 `manager` 参数现在期望 `(Database) -> JdbcTransactionManager` 而不是 `(Database) -> TransactionManager`
    * `R2dbcDatabase.connect()` 方法的 `manager` 参数现在期望 `(R2dbcDatabase) -> R2dbcTransactionManager` 而不是 `(R2dbcDatabase) -> TransactionManager`
    * `TransactionManagerApi.currentOrNull()` 方法已从接口中移除，并作为扩展函数添加到 `JdbcTransactionManager.currentOrNull()` 和 `R2dbcTransactionManager.currentOrNull()`。

  如果您有扩展 `TransactionManager` 的自定义实现，请更新它们以实现适当的接口（`JdbcTransactionManager` 或 `R2dbcTransactionManager`）并确保实现了 `db` 属性。如果您将自定义事务管理器传递给 `connect()` 或 `registerManager()`，请确保类型与新签名匹配。将对实例方法 `transactionManager.currentOrNull()` 的任何调用替换为静态 `TransactionManager.currentOrNull()` 或类型化管理器上的扩展函数。这些更改不影响伴生对象方法，如 `current()`、`currentOrNull()` 或 `closeAndUnregister()`。
* **事务日志级别变更**：事务重试延迟和可在用户端捕获的回滚失败的日志级别已从 `WARN` 更改为 `DEBUG`。这影响 JDBC 和 R2DBC 事务处理中的以下日志消息：
    * `"Wait $retryDelay milliseconds before retrying"` - 现在在事务重试期间以 DEBUG 级别记录
    * SQL 异常消息和原因 - 现在在事务失败时以 DEBUG 级别记录
    * `"Transaction rollback failed: ${it.message}. See previous log line for statement"` - 现在以 DEBUG 级别记录
* 已添加对 `kotlin.uuid.Uuid` 的支持，导致新旧列类型类在包中发生名称冲突。
  接受 `java.util.UUID` 值的原始类已移至新包以进行区分：

| 1.0.0-rc-4                                       | 1.0.0                                            |
|--------------------------------------------------|--------------------------------------------------|
| `org.jetbrains.exposed.v1.core.dao.id.UUIDTable` | `org.jetbrains.exposed.v1.core.dao.id.java.UUIDTable` |
| `org.jetbrains.exposed.v1.core.UUIDColumnType`   | `org.jetbrains.exposed.v1.core.java.UUIDColumnType` |
| `org.jetbrains.exposed.v1.dao.UUIDEntity`        | `org.jetbrains.exposed.v1.dao.java.UUIDEntity`   |
| `org.jetbrains.exposed.v1.dao.UUIDEntityClass`   | `org.jetbrains.exposed.v1.dao.java.UUIDEntityClass` |

  方法 `Table.uuid()` 现在只接受 `kotlin.uuid.Uuid` 值。因此，应使用扩展函数 `Table.javaUUID()`（来自包 `org.jetbrains.exposed.v1.core.java`）来继续传递 `java.util.UUID` 值。
  有关完整详情，请参见[迁移指南](https://www.jetbrains.com/help/exposed/migration-guide-1-0-0.html#uuid-column-type-refactor)。

## 1.0.0-rc-4

* 如果检测到 H2 版本 2.4.240+，`datetime()` 列类型现在将在以下模式中映射到类型 `TIMESTAMP(9)`：常规、MySQL 和 MariaDB。对于早期版本，`datetime()` 继续映射到原始的 `DATETIME(9)` 类型。这样做是为了避免在此数据库版本强制执行更严格的类型更改后抛出异常，并且不会影响 Exposed 内置 schema 迁移方法，因为这些 H2 模式一直将 `DATETIME` 类型视为 `TIMESTAMP` 类型。
* 如果使用 `sqlite-jdbc` 驱动版本 3.50.2.0+，schema 迁移方法生成的 SQL 语句或其关联的 schema 验证方法的结果可能会发生变化。`SchemaUtils` 和 `MigrationUtils` 方法现在可能会生成潜在 `DROP` 未映射列的语句。此驱动版本包含其元数据属性 `supportsAlterTableWithAddColumn` 和 `supportsAlterTableWithDropColumn` 的布尔值更改，Exposed 会自动检查这些值。这意味着 schema 迁移方法实际上可能会返回将数据库表与 Exposed 表对象对齐所需的任何额外有效语句，例如 `ALTER TABLE ADD COLUMN`、`ALTER TABLE DROP COLUMN` 和 `ALTER TABLE RENAME COLUMN`。请在这种情况下考虑在运行前检查生成的 SQL 列表。
* 字段 `Transaction.id` 已重命名为 `Transaction.transactionId` 以避免与用户代码冲突和遮蔽。

## 1.0.0-rc-3

* 移除的 API
    * **`TransactionManagerApi.bindTransactionToThread()`** - 从接口和所有实现中移除
    * **`ThreadLocalTransactionManager`** 类 - 完全移除（已标记为错误级别的弃用）
    * **`CoreTransactionManager`** 对象 - 替换为顶层函数 `currentTransaction()`、`currentTransactionOrNull()`
    * **`TransactionManager.resetCurrent(manager)`** - 从伴生对象中移除
    * **`TransactionManager.isInitialized()`** - 从伴生对象中移除
    * 带有 `CoroutineContext` 参数的实验性挂起事务函数 - 从 JDBC 模块中移除

* 更改的方法签名
    * `transaction()`、`inTopLevelTransaction()`、`suspendTransaction()`、`inTopLevelSuspendTransaction()` - isolation 和 readOnly 参数现在可空（`Int?`、`Boolean?`）
    * `Database.transactionManager` - 从 `Database?.transactionManager` 更改为 `Database.transactionManager`（非空接收者）
    * `R2dbcDatabase.transactionManager` - 从 `R2dbcDatabase?.transactionManager` 更改为 `R2dbcDatabase.transactionManager`（非空接收者）
    * `TransactionManager.newTransaction()` - readOnly 参数从 `Boolean` 更改为 `Boolean?`

* 更改的行为
    * **事务管理器解析**：现在从当前事务 → 当前线程本地解析；如果不可用则抛出 `IllegalStateException`
    * **`TransactionManager.manager`**：现在如果找不到事务管理器则抛出异常（之前返回 `NotInitializedTransactionManager`）
    * **`TransactionManager.defaultDatabase`**：现在可以为 `null`；使用 `TransactionManager.primaryDatabase` 获取默认或最后创建的行为
    * **事务上下文管理**：内部架构从线程本地更改为基于堆栈的协程上下文元素

## 1.0.0-rc-2

* `transaction()`、`inTopLevelTransaction()`、`suspendTransaction()` 和 `inTopLevelSuspendTransaction()` 函数现在将 `db` 作为第一个参数而不是 `transactionIsolation`，并且 `transactionIsolation` 和 `readOnly` 参数现在具有从数据库事务管理器配置派生的默认值。
* `R2dbcTransaction.globalInterceptors` 属性现在存储 `GlobalSuspendStatementInterceptor` 实例的集合。任何加载的 `GlobalStatementInterceptor` 实现都会自动包装为与新的拦截器类型兼容，因此不需要更改 `resources` 文件夹中任何现有自定义拦截器的声明方式。

## 1.0.0-rc-1

* `exposed-migration` 构件已被 `exposed-migration-core` 替代，用于保存跨两种可用驱动的核心通用 schema 迁移功能。已添加新的驱动特定构件以支持 JDBC 和 R2DBC，因此需要调整您的依赖块：

<compare title-before="1.0.0-beta-5" title-after="1.0.0-rc-1">

```kotlin
dependencies {
    implementation("org.jetbrains.exposed:exposed-migration:$exposedVersion")
}
```

```kotlin
dependencies {
    implementation("org.jetbrains.exposed:exposed-migration-core:$exposedVersion")
    implementation("org.jetbrains.exposed:exposed-migration-jdbc:$exposedVersion")
}
```

</compare>

  这也意味着依赖的导入路径模式已相应更新：

<compare title-before="1.0.0-beta-5" title-after="1.0.0-rc-1">

```kotlin
import org.jetbrains.exposed.v1.migration.MigrationUtils
```

```kotlin
import org.jetbrains.exposed.v1.migration.jdbc.MigrationUtils
```

</compare>

  有关[迁移依赖](https://www.jetbrains.com/help/exposed/migration-guide-1-0-0.html#migration-dependencies)的完整详情，请参见迁移指南。

* 接口 `ISqlExpressionBuilder`（及其所有方法）已弃用，其实现对象 `SqlExpressionBuilder` 和 `UpsertSqlExpressionBuilder` 也已弃用。之前受此接口限制的所有方法现在应替换为其新的等效顶层函数。如果尚未存在 `org.jetbrains.exposed.v1.core.*`，则需要添加新的导入语句。这意味着任何使用这些对象作为接收者（或参数）的高阶函数已更改为不再依赖这些对象。在这种情况下，除非添加适当的导入，否则函数参数块中的表达式构建器方法将无法解析。
  有关 `SqlExpressionBuilder` [导入](https://www.jetbrains.com/help/exposed/migration-guide-1-0-0.html#sql-expression-builder-imports)和[高阶函数](https://www.jetbrains.com/help/exposed/migration-guide-1-0-0.html#sql-expression-builder-lambda)的完整详情，请参见迁移指南。
* 我们通过将通用逻辑提取到核心模块来重构了日期时间模块，其中每个日期时间列类型现在都扩展了基类（例如，`JavaLocalDateColumnType` 扩展 `LocalDateColumnType`，`JavaLocalDateTimeColumnType` 扩展 `LocalDateTimeColumnType` 等），将 `exposed-jodatime` 中的 `DateColumnType` 拆分为 `JodaLocalDateColumnType`（以前的 `time: false`）和 `JodaLocalDateTimeColumnType`（以前的 `time: true`），并将 `LocalTimeColumnType` 重命名为 `JodaLocalTimeColumnType`。这些更改仅影响直接使用这些类进行自定义函数或自定义列类型的人。通过扩展函数创建列不受影响。
* 上述通用 `exposed-core` 日期时间 API 依赖于仅与 kotlin-stdlib 2.1.20+ 兼容的 `kotlinx.datetime` [功能](https://github.com/Kotlin/kotlinx-datetime?tab=readme-ov-file#using-in-your-projects)。尝试使用较旧的 Kotlin 版本和日期时间模块依赖进行构建可能导致 `NoClassDefFoundError`，需要升级 Kotlin 版本。
* 弃用 API 的级别已提升。有关完整详情，请参见 [PR #2588](https://github.com/JetBrains/Exposed/pull/2588) 和[迁移指南](https://www.jetbrains.com/help/exposed/migration-guide-1-0-0.html)。
* `DatabaseDialect` 中的参数 `supportsSelectForUpdate` 已弃用，不应使用。该参数已移至 `JdbcExposedDatabaseMetadata`/`R2dbcExposedDatabaseMetadata` 类。现在可以通过调用 `TransactionManager.current().db.supportsSelectForUpdate` 来使用。
* `R2dbcPreparedStatementApi.executeUpdate()` 不再返回值。之前它被定义为返回受影响行数的整数（如 JDBC 变体），但由于 R2DBC 结果处理的性质，它总是返回零值。如果您希望在调用 `executeUpdate()` 后手动检索受影响的行数（并且之后不再需要语句结果），可以通过调用 `RdbcPreparedStatementApi.getResultRow()?.rowsUpdated()?.singleOrNull()` 来实现。
* `R2DBCRow`（`RowApi` 的 R2DBC 实现，用于包装语句结果的元素）已重命名为 `R2dbcRow`。
* `R2dbcTransactionInterface.connection` 属性已被同名的挂起函数替代：

<compare title-before="1.0.0-beta-5" title-after="1.0.0-rc-1">

```kotlin
TransactionManager.current().connection.rollback()
TransactionManager.current().connection.metadata { existingPrimaryKeys(TableA) }
```

```kotlin
TransactionManager.current().connection().rollback()
TransactionManager.current().connection().metadata { existingPrimaryKeys(TableA) }
```

</compare>

* 接受 `CoroutineContext?` 参数的 `suspendTransaction()` 重载已弃用，转而使用参数和行为更符合 JDBC `transaction()` 的重载。可以使用 `withContext()` 将手动上下文传递给方法。同样，返回 `Deferred` 的 `suspendTransactionAsync()` 也已弃用，转而直接使用标准 `suspendTransaction()` 调用 `async()`。
* 接受字符串 `url` 参数的 `R2dbcDatabase.connect()` 重载的 `databaseConfig` 参数类型已更改为直接接受 `R2dbcDatabaseConfig.Builder` 参数。这代替了以构建器作为接收者的函数参数，使其更符合相应的 JDBC `Database.connect()` 变体：

<compare title-before="1.0.0-beta-5" title-after="1.0.0-rc-1">

```kotlin
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabase

R2dbcDatabase.connect(
    "r2dbc:h2:mem:///test;DB_CLOSE_DELAY=-1;",
    databaseConfig = {
        defaultMaxAttempts = 1
        defaultR2dbcIsolationLevel = IsolationLevel.READ_COMMITTED
    }
)
```

```kotlin
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabase
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabaseConfig

R2dbcDatabase.connect(
    "r2dbc:h2:mem:///test;DB_CLOSE_DELAY=-1;",
    databaseConfig = R2dbcDatabaseConfig {
        defaultMaxAttempts = 1
        defaultR2dbcIsolationLevel = IsolationLevel.READ_COMMITTED
    }
)
```

</compare>

## 1.0.0-beta-5

* kotlinx-datetime 从版本 6 迁移到版本 7。唯一受影响的包是 `exposed-kotlin-datetime`。`KotlinInstantColumnType` 和 `Table.timestamp(name: String)` 现在使用 `kotlin.time.Instant` 类参数化。如果您需要将 `kotlinx.datetime.Instant` 与 Exposed 一起使用，必须将 `KotlinInstantColumnType` 和 `Table.timestamp(name: String)` 的用法分别替换为 `XKotlinInstantColumnType` 和 `Table.xTimestamp(name: String)`，还应将 `CurrentTimestamp` 常量更改为 `XCurrentTimestamp`，`CustomTimeStampFunction` 更改为 `XCustomTimeStampFunction`。
* 新引入的 `IStatementBuilder` 接口已重命名并弃用，转而使用 `StatementBuilder`，后者包含所有原始且未更改的方法。其关联函数 `buildStatement()` 不再接受弃用的接口作为其 `body` 参数的接收者；该参数期望新的 `StatementBuilder`。相同的参数类型更改适用于函数 `explain()`。
* 对 H2 2.0.202 之前版本（即 1.4.200 及更早版本）的支持现已完全淘汰。此外，`H2Dialect.H2MajorVersion.One` 现已弃用，`H2Dialect` 特定属性（如 `majorVersion` 和 `isSecondVersion`）现在在检测到 H2 版本 1.x.x 时会抛出异常。展望未来，新功能将不再在 H2 版本 1.0.0+ 上测试，因此不保证对这些版本的支持。根据这些较旧 H2 版本的内置支持，Exposed API 可能仍然大部分兼容，但在生成某些 SQL 子句时可能会抛出语法或不支持的异常。
* `Case` 已拆分为 `Case()` 和 `ValueCase()`，分别表示 `case when <condition> then <result> end` 和 `case <value0> when <value1> then <result> end`。`Case` 类的 `value` 参数已移除，因此如果直接使用 `value`，应替换为 `case(value)` 或 `ValueCase(value)`。类 `CaseWhen` 和 `CaseWhenElse` 也已更改，两者现在都扩展 `BaseCaseWhen` 类，可以用作表达式（`CaseWhen` 之前未扩展 `Expression`）。此外，`CaseWhenElse` 在主构造函数中期望案例列表而不是 `CaseWhen` 实例。

## 1.0.0-beta-4

* `ThreadLocalMap` 已限制为内部使用，基于其在已内部类中的有限使用。它与 `MappedTransactionContext` 一起移至子包：`org.jetbrains.exposed.v1.r2dbc.transactions.mtc`。
* `addLogger()` 已转换为 `Transaction` 方法（而不是 `JdbcTransaction` 和 `R2dbcTransaction` 的扩展方法），因此其逻辑可以在 `exposed-core` 中保持通用。任何显式导入（如 `import org.jetbrains.exposed.v1.jdbc.addLogger`）将不再编译，应予以移除。

## 1.0.0-beta-3

* `exposed-core` 接口 `PreparedStatementApi` 有一个新的 `set()` 方法，如果已实现则需要重写。此方法接受第三个参数，用于与绑定到语句的值关联的列类型，旨在替代现有的 `operator fun set(index: Int, value: Any)`，后者现已弃用。
* `exposed-core` 接口 `PreparedStatementApi` 有一个新的 `setArray()` 方法，如果已实现则需要重写。此方法接受与绑定到语句的数组值关联的实际 `ArrayColumnType` 作为第二个参数，而不是类型的字符串表示。它旨在替代现有的 `setArray(index: Int, type: String, array: Array<*>)`，后者现已弃用。
* 类 `BatchInsertStatement` 和 `BaseBatchInsertStatement` 已合并为一个开放类 `BatchInsertStatement`。`BaseBatchInsertStatement` 的用法可以安全地替换为 `BatchInsertStatement`。
* `TypeMapper::getValue()` 方法中的 `type` 参数现在是可选的。方法签名已更新为 `fun <T> getValue(row: Row, type: Class<T>?, ...): ValueContainer<T?>`。

## 1.0.0-beta-1

1.0.0-beta-1 版本引入了对 R2DBC 的支持，并包含对导入路径的破坏性变更。

在通往 Exposed 1.0 的过程中，对包名进行了若干更改。包命名有两个关键变化：每个模块和构件的唯一前缀，以及为所有包添加 `v1` 前缀。

每个模块的唯一前缀使得更容易区分特定类、函数或其他元素来自哪个依赖。随着包数量的增长，这变得更加重要。

整个版本的唯一 `v1` 前缀将帮助那些对 Exposed 的 `0.x` 版本有传递依赖的用户。预计每个主要版本都会更改该前缀。

### 更新的 JDBC 导入

之前位于 `org.jetbrains.exposed.sql.*` 下的 `exposed-jdbc` 包的导入现在位于 `org.jetbrains.exposed.v1.jdbc.*` 下。下表显示了示例更改：

| 0.61.0                                   | 1.0.0-beta-1                                 |
|------------------------------------------|----------------------------------------------|
| `org.jetbrains.exposed.sql.Database`     | `org.jetbrains.exposed.v1.jdbc.Database`     |
| `org.jetbrains.exposed.sql.SchemaUtils`  | `org.jetbrains.exposed.v1.jdbc.SchemaUtils`  |
| `org.jetbrains.exposed.sql.Query`        | `org.jetbrains.exposed.v1.jdbc.Query`        |
| `org.jetbrains.exposed.sql.transactions` | `org.jetbrains.exposed.v1.jdbc.transactions` |
| `org.jetbrains.exposed.sql.vendors`      | `org.jetbrains.exposed.v1.jdbc.vendors`      |
| `org.jetbrains.exposed.sql.select`       | `org.jetbrains.exposed.v1.jdbc.select`       |
| `org.jetbrains.exposed.sql.selectAll`    | `org.jetbrains.exposed.v1.jdbc.selectAll`    |
| `org.jetbrains.exposed.sql.andWhere`     | `org.jetbrains.exposed.v1.jdbc.andWhere`     |


### 更新的核心导入

之前位于 `org.jetbrains.exposed.sql.*` 下的 `exposed-core` 包的导入现在位于 `org.jetbrains.exposed.v1.core.*` 下。下表显示了示例更改：

| 0.61.0                                           | 1.0.0-beta-1                                         |
|--------------------------------------------------|------------------------------------------------------|
| `org.jetbrains.exposed.sql.Table`                | `org.jetbrains.exposed.v1.core.Table`                |
| `org.jetbrains.exposed.sql.SqlExpressionBuilder` | `org.jetbrains.exposed.v1.core.SqlExpressionBuilder` |
| `org.jetbrains.exposed.sql.innerJoin`            | `org.jetbrains.exposed.v1.core.innerJoin`            |
| `org.jetbrains.exposed.sql.SortOrder`            | `org.jetbrains.exposed.v1.core.SortOrder`            |
| `org.jetbrains.exposed.sql.Op`                   | `org.jetbrains.exposed.v1.core.Op`                   |
| `org.jetbrains.exposed.sql.alias`                | `org.jetbrains.exposed.v1.core.alias`                |
| `org.jetbrains.exposed.sql.anyFrom`              | `org.jetbrains.exposed.v1.core.anyFrom`              |
| `org.jetbrains.exposed.sql.count`                | `org.jetbrains.exposed.v1.core.count`                |
| `org.jetbrains.exposed.sql.sum`                  | `org.jetbrains.exposed.v1.core.sum`                  |


### 更新的 DAO 导入

与实体 ID 相关的类，如 `EntityID`、`CompositeEntityID` 和其他 ID 相关类型，现在位于 `org.jetbrains.exposed.v1.core.dao.id` 包中。

其余 DAO 类型保留其原始结构，但其导入现在包含 `v1` 命名空间：

| 0.61.0                                           | 1.0.0-beta-1                                        |
|--------------------------------------------------|-----------------------------------------------------|
| `org.jetbrains.exposed.dao.CompositeEntity`      | `org.jetbrains.exposed.v1.dao.CompositeEntity`      |
| `org.jetbrains.exposed.dao.IntEntity`            | `org.jetbrains.exposed.v1.dao.IntEntity`            |
| `org.jetbrains.exposed.dao.LongEntity`           | `org.jetbrains.exposed.v1.dao.LongEntity`           |
| `org.jetbrains.exposed.dao.UIntEntity`           | `org.jetbrains.exposed.v1.dao.UIntEntity`           |
| `org.jetbrains.exposed.dao.ULongEntity`          | `org.jetbrains.exposed.v1.dao.ULongEntity`          |
| `org.jetbrains.exposed.dao.UUIDEntity`           | `org.jetbrains.exposed.v1.dao.UUIDEntity`           |
| `org.jetbrains.exposed.dao.CompositeEntityClass` | `org.jetbrains.exposed.v1.dao.CompositeEntityClass` |
| `org.jetbrains.exposed.dao.IntEntityClass`       | `org.jetbrains.exposed.v1.dao.IntEntityClass`       |
| `org.jetbrains.exposed.dao.LongEntityClass`      | `org.jetbrains.exposed.v1.dao.LongEntityClass`      |
| `org.jetbrains.exposed.dao.UIntEntityClass`      | `org.jetbrains.exposed.v1.dao.UIntEntityClass`      |
| `org.jetbrains.exposed.dao.ULongEntityClass`     | `org.jetbrains.exposed.v1.dao.ULongEntityClass`     |
| `org.jetbrains.exposed.dao.UUIDEntityClass`      | `org.jetbrains.exposed.v1.dao.UUIDEntityClass`      |
| `org.jetbrains.exposed.dao.id.EntityID`          | `org.jetbrains.exposed.v1.core.dao.id.EntityID`     |
| `org.jetbrains.exposed.dao.id.CompositeID`       | `org.jetbrains.exposed.v1.core.dao.id.CompositeID`  |


## 0.60.0
* 在 H2 中，`timestamp()` 列现在映射到数据类型 `TIMESTAMP(9)` 而不是 `DATETIME(9)`。
* 为 `ushort()` 和 `uinteger()` 列创建的 CHECK 约束的名称已修改以保持一致。有关此更改的详情，请查看此[拉取请求](https://github.com/JetBrains/Exposed/pull/2426)。

## 0.59.0
* [PostgreSQL] `MigrationUtils.statementsRequiredForDatabaseMigration(*tables)` 以前可能会为任何未映射到 Exposed 表对象的数据库序列返回 `DROP` 语句。现在它只检查与任何指定表有关系依赖的数据库序列（例如，任何自动关联到注册到 `IdTable` 的 `SERIAL` 列的序列）。通过 `CREATE SEQUENCE` 命令手动创建的未绑定序列将不再被检查，也不会生成 `DROP` 语句。
* 在 H2 Oracle 中，`long()` 列现在映射到数据类型 `BIGINT` 而不是 `NUMBER(19)`。在 Oracle 中，在表中使用 long 列现在还会创建 CHECK 约束以确保不会插入超出范围的值。Exposed 不确保 SQLite 的此行为。如果您想这样做，请使用以下 CHECK 约束：

```kotlin
val long = long("long_column").check { column ->
    fun typeOf(value: String) = object : ExpressionWithColumnType<String>() {
        override fun toQueryBuilder(queryBuilder: QueryBuilder) = queryBuilder { append("typeof($value)") }
        override val columnType: IColumnType<String> = TextColumnType()
    }
    Expression.build { typeOf(column.name) eq stringLiteral("integer") }
}

val long = long("long_column").nullable().check { column ->
    fun typeOf(value: String) = object : ExpressionWithColumnType<String>() {
        override fun toQueryBuilder(queryBuilder: QueryBuilder) = queryBuilder { append("typeof($value)") }
        override val columnType: IColumnType<String> = TextColumnType()
    }

    val typeCondition = Expression.build { typeOf(column.name) eq stringLiteral("integer") }
    column.isNull() or typeCondition
}
```
* 在 MariaDB 中，`timestamp()` 列现在映射到数据类型 `TIMESTAMP` 而不是 `DATETIME`。

## 0.57.0
* Insert、Upsert 和 Replace 语句将不再隐式发送所有默认值（客户端默认值除外）。此更改将减少 Exposed 发送到数据库的数据量，并使 Exposed 更多地依赖数据库的默认值。但是，这可能会暴露以前被 Exposed 的 insert/upsert 语句掩盖的与实际数据库默认值相关的隐藏问题。此外，`InsertStatement` 中的受保护方法 `isColumnValuePreferredFromResultSet()` 已被移除，方法 `valuesAndDefaults()` 已标记为弃用。

  假设您有一个包含具有默认值的列的表，并且使用如下插入语句：
  ```kotlin
  object TestTable : IntIdTable("test") { 
    val number = integer("number").default(100)
    val expression = integer("exp")
        .defaultExpression(intLiteral(100) + intLiteral(200))
  }
  
  TestTable.insert { }
  ```
  此插入语句将在 H2 数据库中生成以下 SQL：
  ```sql
  -- For versions before 0.57.0
  INSERT INTO TEST ("number", "exp") VALUES (100, (100 + 200))
  
  -- Starting from version 0.57.0
  INSERT INTO TEST DEFAULT VALUES
  ```
* `OptionalReferrers` 类现已弃用，因为它是 `Referrers` 类的完全重复；因此应使用后者。

## 0.56.0
* 如果 `groupConcat()` 的 `distinct` 参数设置为 `true`，在使用 Oracle 或 SQL Server 时，现在将立即失败并抛出 `UnsupportedByDialectException`。之前该设置会被忽略，SQL 函数生成不会包含 `DISTINCT` 子句。
* 在 Oracle 和 H2 Oracle 中，`ubyte()` 列现在映射到数据类型 `NUMBER(3)` 而不是 `NUMBER(4)`。
* 在 Oracle 和 H2 Oracle 中，`ushort()` 列现在映射到数据类型 `NUMBER(5)` 而不是 `NUMBER(6)`。
* 在 Oracle 和 H2 Oracle 中，`uinteger()` 列现在映射到数据类型 `NUMBER(10)` 而不是 `NUMBER(13)`。
* 在 Oracle 和 H2 Oracle 中，`integer()` 列现在分别映射到数据类型 `NUMBER(10)` 和 `INTEGER`，而不是 `NUMBER(12)`。在 Oracle 和 SQLite 中，在表中使用 integer 列现在还会创建 CHECK 约束以确保不会插入超出范围的值。
* `ArrayColumnType` 现在支持多维数组并包含额外的泛型参数。如果以前将其用于一维数组，参数为 `T`，如 `ArrayColumnType<T>`，现在应定义为 `ArrayColumnType<T, List<T>>`。例如，`ArrayColumnType<Int>` 现在应为 `ArrayColumnType<Int, List<Int>>`。
* `EntityID` 和 `CompositeID` 不再自己实现 `Comparable`，以允许其包装的标识值可以是不一定是 `Comparable` 的类型，如 `kotlin.uuid.Uuid`。

  任何将实体的 `id` 与 Kotlin 比较运算符或 `compareTo()` 一起使用的情况现在需要直接使用包装值：`entity1.id < entity2.id` 需要变为 `entity1.id.value < entity2.id.value`。任何将实体的 `id` 与同样受 `Comparable` 类型限制的 Exposed 函数（例如 `avg()`）一起使用的情况也需要定义新函数。在这种情况下，请在 [YouTrack](https://youtrack.jetbrains.com/issue/EXPOSED-577) 上留下用例评论，以便可以重新评估原始函数签名。

## 0.55.0
* `DeleteStatement` 属性 `table` 现已弃用，转而使用 `targetsSet`，后者持有可以是 `Table` 或 `Join` 的 `ColumnSet`。这使得可以使用新的 `Join.delete()` 函数，该函数对联接关系中的特定表执行删除操作。原始语句类构造函数也已弃用，转而使用接受 `targetsSet` 的构造函数，以及另一个额外参数 `targetTables`（用于指定要从联接关系中的哪个表删除，如果适用）。
* `DeleteStatement` 属性 `offset` 未被使用，现已弃用，具有 `offset` 参数的扩展函数也已弃用。`deleteWhere()` 和 `deleteIgnoreWhere()` 以及原始语句类构造函数不再接受 `offset` 参数。
* `SizedIterable.limit(n, offset)` 现已弃用，转而使用两个独立方法 `limit()` 和 `offset()`。在支持的数据库中，这允许在 SELECT 语句中生成 OFFSET 子句而无需任何 LIMIT 子句。任何具有 `limit()` 重写的 `SizedIterable` 接口的自定义实现现在将显示警告，声明重写了已弃用的成员。此重写应拆分为两个新成员的实现。

  原始的 `FunctionProvider.queryLimit()` 也已弃用，转而使用 `queryLimitAndOffset()`，后者接受可空的 `size` 参数以允许排除 LIMIT 子句。后一种弃用仅影响在创建自定义 `VendorDialect` 类时 `FunctionProvider` 类的扩展。
* 在 Oracle 中，`short` 列现在映射到数据类型 `NUMBER(5)` 而不是 `SMALLINT`，因为 `SMALLINT` 在数据库中存储为 `NUMBER(38)` 并占用不必要的存储。在 Oracle 和 SQLite 中，在表中使用 `short` 列现在还会创建检查约束以确保不会插入超出范围的值。
* 在 Oracle 中，`byte` 列现在映射到数据类型 `NUMBER(3)` 而不是 `SMALLINT`，因为 `SMALLINT` 在数据库中存储为 `NUMBER(38)` 并占用不必要的存储。在 SQL Server 中，`byte` 列现在映射到数据类型 `SMALLINT` 而不是 `TINYINT`，因为 `TINYINT` [允许 0 到 255 的值](https://learn.microsoft.com/en-us/sql/t-sql/data-types/int-bigint-smallint-and-tinyint-transact-sql?view=sql-server-ver16#:~:text=2%20bytes-,tinyint,-0%20to%20255)。在 SQL Server、SQLite、Oracle、PostgreSQL 和 H2 PostgreSQL 中，在表中使用 `byte` 列现在还会创建检查约束以确保不会插入超出范围的值。
* 可空列的转换（`Column<Unwrapped?>.transform()`）需要处理空值。这使得可以从 `null` 转换为非空值，反之亦然。
* 在 H2 中，具有默认值的 json 列的定义从 `myColumn JSON DEFAULT '{"key": "value"}'` 更改为 `myColumn JSON DEFAULT JSON '{"key": "value"}'`

## 0.54.0

* 属于密封类 `ForUpdateOption` 的所有对象现在都转换为 `data object`。
* `upsert()`、`upsertReturning()` 和 `batchUpsert()` 中的 `onUpdate` 参数将不再接受列值对列表作为参数。该参数现在接受以 `UpdateStatement` 作为参数的 lambda 块，以便可以像 `update()` 一样设置 UPDATE 子句的列值赋值。
  这使得可以在表达式中使用 `insertValue(column)` 来指定在更新时应使用要插入列的相同值。
```kotlin
// before
TestTable.upsert(
    onUpdate = listOf(Words.count to Words.count.plus(1))
) {
    it[word] = "Kotlin"
    it[count] = 3
}

// after
TestTable.upsert(
    onUpdate = {
        it[Words.count] = Words.count + 1
    }
) {
    it[word] = "Kotlin"
    it[count] = 3
}

// after - with new value from insert used in update expression
TestTable.upsert(
    onUpdate = {
        it[Words.count] = Words.count + insertValue(Words.count)
    }
) {
    it[word] = "Kotlin"
    it[count] = 3
}
```
* 函数 `statementsRequiredForDatabaseMigration` 已从 `SchemaUtils` 移至 `exposed-migration` 模块中的 `MigrationUtils`。
* 嵌套事务（使用 `useNestedTransactions = true`）抛出任何异常现在将回滚自上次保存点以来的任何提交。这确保嵌套事务被正确配置为与顶层事务或 `inTopLevelTransaction()` 完全相同的方式运行。

  内部事务（使用 `useNestedTransactions = false`）抛出任何异常也将回滚自上次保存点以来的任何提交。这确保从内部事务传播到外部事务的任何异常在被包装内部事务的某些异常处理程序捕获时不会被吞掉，并且任何内部提交都不会被保存。在版本 0.55.0 中，此更改将减少为只有从数据库抛出 `SQLException` 的内部事务才会触发此类回滚。

## 0.53.0

* DAO 实体转换更改
  * **参数重命名**：`transform()` 和 `memoizedTransform()` 现在使用 `wrap` 和 `unwrap` 而不是 `toColumn` 和 `toReal`。
    ```kotlin
    // Old:
    var name by EmployeeTable.name.transform(toColumn = { it.uppercase() }, toReal = { it.lowercase() })
    // New:
    var name by EmployeeTable.name.transform(wrap = { it.uppercase() }, unwrap = { it.lowercase() })
    ```
  * **类重命名**：`ColumnWithTransform` 现在是 `EntityFieldWithTransform`，将属性合并为单个 `transformer`。
    ```kotlin
    EntityFieldWithTransform(column, object : ColumnTransformer<String, Int> {
            override fun unwrap(value: Int): String = value.toString()
            override fun wrap(value: String): Int = value.toInt()
        })
    ``` 
  * 通过 DAO 进行的实体转换已弃用，应替换为 DSL 转换。
    ```kotlin
    val tester = object : Table() {
            val value = integer("value")
                .transform(wrap = { ... }, unwrap = { ... })
        }
    ```
    

## 0.51.0

* `exposed-spring-boot-starter` 模块不再提供整个 [spring-boot-starter-data-jdbc](https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-data-jdbc) 模块。现在只提供 [spring-boot-starter-jdbc](https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-jdbc)。如果有对此传递依赖的依赖，请直接在构建文件中包含对 Spring Data JDBC 的依赖。
* `ulong` 列类型对于 H2（不包括 H2_PSQL）、SQLite 和 SQL Server 现在是 NUMERIC(20) 而不是 BIGINT，以允许存储完整的 `ULong` 范围，包括 `ULong.MAX_VALUE`。

## 0.50.0

* `Transaction` 类属性 `repetitionAttempts` 已弃用，转而使用 `maxAttempts`。此外，属性 `minRepetitionDelay` 应替换为 `minRetryDelay`，`maxRepetitionDelay` 替换为 `maxRetryDelay`。这些更改也影响 `DatabaseConfig` 中这些属性的默认变体。
* 属性 `maxAttempts` 表示执行事务块的最大尝试次数。将其或现已弃用的 `repetitionAttempts` 设置为小于 1 的值现在会抛出 `IllegalArgumentException`。
* `IColumnType` 和 `ColumnType` 现在期望类型参数。`IColumnType.valueFromDB()` 也不再有默认实现，因此在任何自定义列类型实现中必须提供此方法的重写。有关此更改的详情，请查看此[拉取请求](https://github.com/JetBrains/Exposed/pull/2027)。

## 0.49.0

* 对于 SQLite 数据库，Exposed 现在要求将 SQLite JDBC 驱动版本提升到最低 3.45.0.0。

## 0.48.0

* 在 `KotlinInstantColumnType` 和 `JavaDateColumnType` 的 `nonNullValueToString` 中，MySQL 的格式化字符串在 `isFractionDateTimeSupported` 为 true 时与元数据接收的格式不匹配，因此现在使用特定的新格式化器。
* 在 `KotlinLocalDateTimeColumnType` 的 `nonNullValueToString` 中，MySQL 的格式化字符串在 `isFractionDateTimeSupported` 为 true 时与元数据接收的格式不匹配，因此现在使用特定于 MySQL 的新格式化器。
* 在 `DateColumnType`、`JavaLocalDateTimeColumnType`、`JavaLocalTimeColumnType`、`JavaInstantColumnType`、`KotlinLocalDateTimeColumnType`、`KotlinLocalTimeColumnType` 和 `KotlinInstantColumnType` 的 `nonNullValueToString` 中，当版本（低于 5.6）不支持小数秒时，使用正确的 MySQL 格式化器。
* 在 `DateColumnType` 和 `DateTimeWithTimeZoneColumnType` 的 `nonNullValueToString` 中，使用的格式化器已更改以反映 Joda-Time 仅存储日期/时间值到毫秒（最多 SSS 而不是 SSSSSS）的事实。
* 函数 `anyFrom(array)` 和 `allFrom(array)` 现在在查询构建时使用 `ArrayColumnType` 处理提供的数组参数。`ArrayColumnType` 需要基础列类型才能正确处理内容，Exposed 会尝试根据数组内容类型在内部解析最佳匹配。如果内容需要不支持的或自定义的列类型，或者 `exposed-core` 模块中未定义的列类型，应向函数参数 `delegateType` 提供特定的列类型参数。
* `exposed-crypt` 模块现在使用 Spring Security Crypto 6.+，需要 Java 17 作为最低版本。

## 0.47.0

* 函数 `SchemaUtils.checkExcessiveIndices` 用于检查过多的索引和过多的外键约束。它现在有不同的行为，仅处理过多的索引。此外，其返回类型现在是 `List<Index>` 而不是 `Unit`。新函数 `SchemaUtils.checkExcessiveForeignKeyConstraints` 处理过多的外键约束，返回类型为 `List<ForeignKeyConstraint>`。

## 0.46.0

* 当使用关键字标识符（表或列名）创建 Exposed 表对象时，它现在在生成的 SQL 中自动加引号之前保留使用的确切大小写。这主要影响 H2 和 Oracle（两者都支持将标识符折叠为大写）以及 PostgreSQL（将标识符折叠为小写）。

  如果之前在 `DatabaseConfig` 中设置了 `preserveKeywordCasing = true` 以移除有关任何关键字标识符的已记录警告，现在可以移除该设置，因为该属性默认为 `true`。

  要暂时退出此行为并保留关键字标识符的定义大小写，请在 `DatabaseConfig` 中设置 `preserveKeywordCasing = false`：
```kotlin
object TestTable : Table("table") {
    val col = integer("select")
}

// default behavior (preserveKeywordCasing is by default set to true)
// H2 generates SQL -> CREATE TABLE IF NOT EXISTS "table" ("select" INT NOT NULL)

// with opt-out
Database.connect(
    url = "jdbc:h2:mem:test",
    driver = "org.h2.Driver",
    databaseConfig = DatabaseConfig {
        @OptIn(ExperimentalKeywordApi::class)
        preserveKeywordCasing = false
    }
)
// H2 generates SQL -> CREATE TABLE IF NOT EXISTS "TABLE" ("SELECT" INT NOT NULL)
```

<note>
`preserveKeywordCasing` 是一个实验性标志，需要 `@OptIn`。在未来的版本中可能会弃用。
</note>

## 0.44.0

* `SpringTransactionManager` 不再扩展 `DataSourceTransactionManager`；而是直接扩展 `AbstractPlatformTransactionManager`，同时保留以前的基本功能。该类也不再实现 Exposed 接口 `TransactionManager`，因为事务操作改为委托给 Spring。这些更改确保 Exposed 的底层事务管理不再干扰 Spring 事务管理的预期行为，例如在使用嵌套事务或带有 `propagation` 或 `isolation` 等 `@Transactional` 元素时。

  如果集成仍然需要 `DataSourceTransactionManager`，请在配置中添加两个 bean 声明：一个用于 `SpringTransactionManager`，一个用于 `DataSourceTransactionManager`。然后定义一个组合事务管理器来组合这两个管理器。

  如果 `TransactionManager` 函数是通过 `SpringTransactionManager` 实例调用的，请将这些调用替换为适当的 Spring 注解，或者如有必要，直接使用 `TransactionManager` 的伴生对象（例如 `TransactionManager.currentOrNull()`）。
* `spring-transaction` 和 `exposed-spring-boot-starter` 模块现在使用 Spring Framework 6.0 和 Spring Boot 3.0，需要 Java 17 作为最低版本。
* 使用关键字标识符（表或列名）创建的表现在会记录警告，标识符的大小写在生成的 SQL 中自动加引号时可能会丢失。这主要影响 H2 和 Oracle（两者都支持将标识符折叠为大写）和 PostgreSQL（将标识符折叠为小写）。

  要移除这些警告并确保发送到数据库的关键字标识符与 Exposed 表对象中使用的确切大小写匹配，请在 `DatabaseConfig` 中设置 `preserveKeywordCasing = true`：
```kotlin
object TestTable : Table("table") {
    val col = integer("select")
}

// without opt-in (default set to false)
// H2 generates SQL -> CREATE TABLE IF NOT EXISTS "TABLE" ("SELECT" INT NOT NULL)

// with opt-in
Database.connect(
    url = "jdbc:h2:mem:test",
    driver = "org.h2.Driver",
    databaseConfig = DatabaseConfig {
        @OptIn(ExperimentalKeywordApi::class)
        preserveKeywordCasing = true
    }
)
// H2 generates SQL -> CREATE TABLE IF NOT EXISTS "table" ("select" INT NOT NULL)
```

<note>
`preserveKeywordCasing` 是一个实验性标志，需要 `@OptIn`。在未来的版本中可能会弃用，设置为 `true` 时的行为可能会成为默认行为。
</note>

## 0.43.0

* 在除 MySQL、MariaDB 和 SQL Server 之外的所有数据库中，`ubyte()` 列现在映射到数据类型 `SMALLINT` 而不是 `TINYINT`，这允许插入完整的 `UByte` 值范围而不会溢出。在表上注册该列还会创建一个检查约束，将插入的数据限制在 0 和 `UByte.MAX_VALUE` 之间的范围内。如果需要仅使用 1 字节存储但不允许插入任何非负值的列，请改用有符号的 `byte()` 列并手动创建检查约束：
```kotlin
byte("number").check { it.between(0, Byte.MAX_VALUE) }
// OR
byte("number").check { (it greaterEq 0) and (it lessEq Byte.MAX_VALUE) }
```
* 在除 MySQL 和 MariaDB 之外的所有数据库中，`uint()` 列现在映射到数据类型 `BIGINT` 而不是 `INT`，这允许插入完整的 `UInt` 值范围而不会溢出。在表上注册该列还会创建一个检查约束，将插入的数据限制在 0 和 `UInt.MAX_VALUE` 之间的范围内。如果需要仅使用 4 字节存储但不允许插入任何非负值的列，请改用有符号的 `integer()` 列并手动创建检查约束：
```kotlin
integer("number").check { it.between(0, Int.MAX_VALUE) }
// OR
integer("number").check { (it greaterEq 0) and (it lessEq Int.MAX_VALUE) }
```

## 0.42.0

* __SQLite__ 使用 `date()` 创建的表列现在使用 TEXT 数据类型而不是 DATE（数据库在内部将其映射到 NUMERIC 类型）。这适用于所有 3 个日期/时间模块中的特定 `DateColumnType`，意味着现在可以直接进行 `LocalDate` 比较而无需转换。
* __H2, PostgreSQL__ 使用 `replace()` 现在会抛出异常，因为这些数据库不支持 REPLACE 命令。如果 `replace()` 被用于执行插入或更新操作，所有用法应改为 `upsert()`。[有关 UPSERT 详情请参见文档](DSL-CRUD-operations.topic#insert-or-update)
* 运算符类 `exists` 和 `notExists` 已重命名为 `Exists` 和 `NotExists`。已引入函数 `exists()` 和 `notExists()` 来返回其各自命名类的实例并避免未解析的引用问题。这些类的任何用法都应重命名为其大写形式。
* `customEnumeration()` 现在注册 `CustomEnumerationColumnType` 以允许被另一列引用。`customEnumeration()` 的签名没有更改，使用它初始化的表列仍然是 `Column<DataClass>` 类型。
* `Transaction.suspendedTransaction()` 已重命名为 `Transaction.withSuspendTransaction()`。请使用 `suspendedTransaction(` 和 `suspendedTransaction ` 作为搜索选项运行两次 `Edit -> Find -> Replace in files...`，以确保两种变体都被替换而不影响 `suspendedTransactionAsync()`（如果在代码中使用）。
* `transaction()` 中的 `repetitionAttempts` 参数已被移除，并替换为 `Transaction` 类中的可变属性。请移除此参数的任何参数并直接为属性赋值：
```kotlin
// before
transaction(Connection.TRANSACTION_READ_COMMITTED, repetitionAttempts = 10) {
    // statements
}

// after
transaction(Connection.TRANSACTION_READ_COMMITTED) {
    repetitionAttempts = 10
    // statements
}
```
* 在除 MySQL 和 MariaDB 之外的所有数据库中，`ushort()` 列现在映射到数据类型 `INT` 而不是 `SMALLINT`，这允许插入完整的 `UShort` 值范围而不会溢出。在表上注册该列还会创建一个检查约束，将插入的数据限制在 0 和 `UShort.MAX_VALUE` 之间的范围内。如果需要仅使用 2 字节存储但不允许插入任何非负值的列，请改用有符号的 `short()` 列并手动创建检查约束：
```kotlin
short("number").check { it.between(0, Short.MAX_VALUE) }
// OR
short("number").check { (it greaterEq 0) and (it lessEq Short.MAX_VALUE) }
```
