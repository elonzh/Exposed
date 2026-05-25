<show-structure for="chapter,procedure" depth="2"/>

# 使用事务

Exposed 中的 CRUD 操作必须在_事务_内调用。事务封装了一组 DSL 操作。

## 创建事务

要使用默认参数创建和执行事务，只需将函数块传递给
[`transaction()`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.transactions/transaction.html)
函数：

```kotlin
import org.jetbrains.exposed.v1.jdbc.transactions.transaction

transaction {
    // DSL/DAO 操作放在这里
}
```

事务在当前线程上同步执行。这意味着如果不仔细管理，它们可能会阻塞应用的其他部分。

如果你需要在协程中异步执行事务，请改用
[基于挂起的事务](#suspend-based-transaction)。

## 基于挂起的事务

使用 `exposed-r2dbc` 中的 [`suspendTransaction()`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.transactions/suspend-transaction.html)
在基于协程的应用中执行非阻塞操作：

```kotlin
import org.jetbrains.exposed.v1.r2dbc.transactions.suspendTransaction

suspendTransaction {
    // DSL/DAO 操作放在这里
}
```

为了与 JDBC 驱动程序兼容，还有一个 [`suspendTransaction()`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.transactions/suspend-transaction.html)
可用于在阻塞数据库操作旁边调用挂起函数。

这两个函数的行为与 `transaction()` 匹配，但它们的 `statement` 参数接受挂起函数。
要向 `suspendTransaction()` 传递额外的上下文，请将其包装在协程构建器函数中，如
[`withContext()`](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/with-context.html)
或 [`async()`](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/async.html)。


## 访问返回值

虽然你可以在事务块中修改代码中的变量，但它也支持直接返回值，从而实现不可变性。

在以下示例中，`jamesList` 是一个包含 `UsersTable` 数据的 `List<ResultRow>`：

<tabs group="connectivity">
    <tab id="jdbc-connect" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin"
                    src="exposed-databases-jdbc/src/main/kotlin/org/example/App.kt"
                    include-symbol="jamesList" />
    </tab>
    <tab id="r2dbc-connect" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin"
                    src="exposed-databases-r2dbc/src/main/kotlin/org/example/App.kt"
                    include-symbol="jamesList" />
    </tab>
</tabs>



> 如果你没有直接加载 `Blob` 和 `text` 字段，它们在事务外将不可用。对于 `text`
> 字段，你还可以在定义表时使用 `eagerLoading` 参数使文本字段在事务外可用。
{style="note"}

```kotlin
// 不使用 eagerLoading
val idsAndContent = transaction {
   Documents.selectAll().limit(10).map { it[Documents.id] to it[Documents.content] }
}

// 对 text 字段使用 eagerLoading
object Documents : Table() {
  //...
  val content = text("content", eagerLoading = true)
}

val documentsWithContent = transaction {
   Documents.selectAll().limit(10)
}
```

## 使用多个数据库


如果你想要使用不同的数据库，你必须存储 `.connect()` 函数返回的数据库引用，并将其作为第一个参数提供给事务函数。

不带参数的事务块将使用最近连接的数据库。

```kotlin
val db1 = connect("jdbc:h2:mem:db1;DB_CLOSE_DELAY=-1;", "org.h2.Driver", "root", "")
val db2 = connect("jdbc:h2:mem:db2;DB_CLOSE_DELAY=-1;", "org.h2.Driver", "root", "")
transaction(db1) {
   //...
   val result = transaction(db2) {
      Table1.selectAll().where { }.map { it[Table1.name] }
   }
   
   val count = Table2.selectAll().where { Table2.name inList result }.count()
}
```

实体会"粘附"到用于加载该实体的事务。这意味着所有更改都持久化到同一个数据库，并且跨数据库引用是被禁止的，将会抛出异常。

## 设置默认数据库

要显式设置默认数据库，请使用 `TransactionManager.defaultDatabase` 属性：

```kotlin
val db = Database.connect()
TransactionManager.defaultDatabase = db
```

检索此 `defaultDatabase` 属性将返回设置的值，如果未提供值则返回 `null`。

不带参数的事务块使用默认数据库或最近_连接的_数据库。
要检索和检查在这种情况下事务块将使用的 `Database` 实例，请获取
`TransactionManager.primaryDatabase` 属性。

## 使用嵌套事务

默认情况下，嵌套事务块共享其父事务块的事务资源。这意味着嵌套事务中的任何更改都会影响外部事务。如果在嵌套块中发生回滚，它也会回滚父事务中的更改：

```kotlin
val db = Database.connect()
db.useNestedTransactions = false // 默认设置

transaction {
    println("Transaction # ${this.id}") // Transaction # 1
    FooTable.insert{ it[id] = 1 }
    println(FooTable.selectAll().count()) // 1
    
    transaction {
        println("Transaction # ${this.id}") // Transaction # 1
        FooTable.insert{ it[id] = 2 }
        println(FooTable.selectAll().count()) // 2
    
        rollback() 
    }

    println(FooTable.selectAll().count()) // 0
}
```

### 独立嵌套事务

要允许嵌套事务独立运行，请将 `Database` 实例上的 `useNestedTransactions` 属性设置为 `true`：

```kotlin
val db = Database.connect(
    // 连接参数
)
db.useNestedTransactions = true

transaction {
    println("Transaction # ${this.id}") // Transaction # 1
    FooTable.insert{ it[id] = 1 }
    println(FooTable.selectAll().count()) // 1
    
    transaction {
        println("Transaction # ${this.id}") // Transaction # 2
        FooTable.insert{ it[id] = 2 }
        println(FooTable.selectAll().count()) // 2
    
        rollback() 
    }

    println(FooTable.selectAll().count()) // 1
}
```
这样，嵌套事务中的任何回滚或异常只影响该块，不会回滚外部事务。

Exposed 通过在每个事务块开始时使用 SQL `SAVEPOINT` 标记事务状态，并在退出时释放它们来实现这一点。

> 使用 `SAVEPOINT` 可能会影响性能。有关详细信息，请参阅你的数据库文档。

<note>
<code>exposed-jdbc</code> 中的 <code>suspendTransaction()</code> 使用与本节上述 <code>transaction()</code> 相同的嵌套行为逻辑。
</note>

## 使用保存点

要回滚到特定点而不影响整个事务，你可以通过事务的 `connection` 属性设置保存点。

`connection` 属性提供对
[`ExposedConnection`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.statements.api/-exposed-connection/index.html)
或 [`R2dbcExposedConnection`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.statements.api/-r2dbc-exposed-connection/index.html) 的访问，
它分别作为底层 JDBC 或 R2DBC 连接的包装器。

要在事务中手动创建保存点，请使用 `.setSavepoint()` 方法：

```Kotlin
```
{src="exposed-transactions/src/main/kotlin/org/example/examples/SavepointExample.kt" include-lines="39,41-50"}


## 高级参数和用法

对于特定功能，事务可以使用额外的
参数创建：`db`、`transactionIsolation`、`readOnly`、`maxAttempts` 和 `queryTimeout`：

<tabs group="connectivity">
    <tab id="transaction" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin">
        transaction(
            db = h2Db,
            transactionIsolation = Connection.TRANSACTION_READ_COMMITTED,
            readOnly = true,
        ) {
            maxAttempts = 5
            queryTimeout = 5
            // DSL/DAO 操作放在这里
        }
        </code-block>
    </tab>
    <tab id="suspend-transaction" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin">
        suspendTransaction(
            db = h2Db,
            transactionIsolation = IsolationLevel.READ_COMMITTED,
            readOnly = true,
        ) {
            maxAttempts = 5
            queryTimeout = 5
            // DSL/DAO 操作放在这里
        }
        </code-block>
    </tab>
</tabs>

### `db`

`db` 参数是可选的，用于选择事务应在哪个数据库中结算。这在[使用多个数据库](#working-with-multiple-databases)时很有用。

### `transactionIsolation`

`transactionIsolation` 参数指定当多个事务在数据库上并发执行时应该发生什么。此值会发送到数据库并被考虑。默认情况下，它设置为使用数据库事务管理器配置提供的值。

JDBC 连接的允许值定义在 `java.sql.Connection` 中，
R2DBC 连接的允许值定义在 `io.r2dbc.spi.IsolationLevel` 中。

<tabs group="connectivity">
<tab id="jdbc-transaction-isolation" title="JDBC" group-key="jdbc">

`TRANSACTION_NONE`
: 不支持事务。

`TRANSACTION_READ_UNCOMMITTED`
: 允许一个事务中的未提交更改影响另一个事务中的读取（"脏读"）。

`TRANSACTION_READ_COMMITTED`（默认，MySQL 和 SQLite 除外）
: 此设置防止脏读发生，但仍允许不可重复读发生。_不可重复读_是指一个事务（"事务 A"）从数据库读取一行，另一个事务（"事务 B"）更改该行，然后事务 A 再次读取该行，导致不一致。

`TRANSACTION_REPEATABLE_READ`（MySQL 的默认值）
: 防止脏读和不可重复读，但仍允许幻读。_幻读_是指一个事务（"事务 A"）通过 `WHERE` 子句选择一组行，另一个事务（"事务 B"）执行满足事务 A 的 `WHERE` 子句的行的 `INSERT` 或 `DELETE`，然后事务 A 使用相同的 WHERE 子句再次选择，导致不一致。

`TRANSACTION_SERIALIZABLE`（SQLite 的默认值）
: 防止脏读、不可重复读和幻读。

{type="wide"}

</tab>
<tab id="r2dbc-transaction-isolation" title="R2DBC" group-key="r2dbc">

`READ_UNCOMMITTED`
: 允许一个事务中的未提交更改影响另一个事务中的读取（"脏读"）。

`READ_COMMITTED`（默认，MySQL 除外）
: 此设置防止脏读发生，但仍允许不可重复读发生。_不可重复读_是指一个事务（"事务 A"）从数据库读取一行，另一个事务（"事务 B"）更改该行，然后事务 A 再次读取该行，导致不一致。

`REPEATABLE_READ`（MySQL 的默认值）
: 防止脏读和不可重复读，但仍允许幻读。_幻读_是指一个事务（"事务 A"）通过 `WHERE` 子句选择一组行，另一个事务（"事务 B"）执行满足事务 A 的 `WHERE` 子句的行的 `INSERT` 或 `DELETE`，然后事务 A 使用相同的 WHERE 子句再次选择，导致不一致。

`SERIALIZABLE`
: 防止脏读、不可重复读和幻读。

{type="wide"}

</tab>
</tabs>

### `readOnly`

`readOnly` 参数指示事务使用的任何数据库连接是否处于只读模式。默认情况下，它设置为使用数据库事务管理器配置提供的值。此值不被 Exposed 直接使用，而是传递给数据库。

### `maxAttempts`

使用 `maxAttempts` 属性设置执行事务块的最大尝试次数。

如果此值设置为 `1` 并且在事务块中发生 `SQLException`，则将抛出异常而不执行重试。

如果设置为大于 1 的值，还可以在事务块中设置 `minRetryDelay` 和 `maxRetryDelay`，以指示重试前等待的最小和最大毫秒数。

如果未设置，则将使用
[`DatabaseConfig`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-database-config/index.html)
中提供的任何默认值：

```kotlin
val db = Database.connect(
    datasource = datasource,
    databaseConfig = DatabaseConfig {
        defaultMaxAttempts = 3
    }
)

// 事务块中设置的属性覆盖默认的 DatabaseConfig
transaction(db = db) {
    maxAttempts = 25
    // 可能需要多次尝试的操作
}
```

### `queryTimeout`

使用 `queryTimeout` 设置在超时之前等待块中每个语句执行的秒数：

```kotlin
transaction {
    queryTimeout = 3
    try {
        // 可能运行超过 3 秒的操作
    } catch (cause: ExposedSQLException) {
        // 如果执行超时则执行的逻辑
    }
}
```

此值不由 Exposed 直接管理，而是传递给 JDBC 或 R2DBC 驱动程序。

>某些驱动程序可能不支持实现此限制。有关更多信息，请参阅相关驱动程序文档。
{style="note"}
