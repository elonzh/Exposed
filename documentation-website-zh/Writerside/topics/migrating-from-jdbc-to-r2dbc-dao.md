<show-structure for="chapter,procedure" depth="2"/>
<link-summary>
了解如何将基于 DAO 的应用程序从 JDBC 迁移到 R2DBC。
</link-summary>

# 从 JDBC DAO 迁移到 R2DBC DAO {id="migrating-from-jdbc-dao-to-r2dbc-dao"}

<primary-label ref="experimental"/>

Exposed 1.6.0 通过 `exposed-dao-r2dbc` 构件为 DAO API 引入了实验性的 R2DBC 支持。在本主题中，
您将了解如何将现有的 JDBC DAO 应用程序迁移到 R2DBC DAO。

迁移需要更换传输层和 DAO 构件，并修改源代码。

## 前提条件 {#prerequisites}

开始之前，请检查您的应用程序是否使用了 R2DBC DAO 中尚不支持的 JDBC DAO 功能。
如果使用了，则必须先修改应用程序的这些部分，才能完成迁移。

| JDBC DAO                                     | R2DBC DAO                                                                                |
|----------------------------------------------|------------------------------------------------------------------------------------------|
| `ImmutableEntityClass`                       | 不支持。                                                                           |
| `ImmutableCachedEntityClass`                 | 不支持。                                                                           |
| `EntityClass.view()` 和 `View`              | 不支持。请改用 `find()`。                                                     |
| `EntityClass.findWithCacheCondition()`       | 不支持。                                                                           |
| `EntityClass.testCache(predicate)`           | 不支持。请改用 `EntityClass.testCache(entityId)`。                            |
| `Entity.writeValues`、`storeWrittenValues()` | 不支持。待写入的值改由事务的 `EntityCache` 管理。         |
| `EntityCache.maxEntitiesToStore`             | 不支持。R2DBC 实体缓存不会逐出实体。                           |
| `EntityCache.invalidateGlobalCaches()`       | 不支持。此功能属于 `ImmutableCachedEntityClass` 的内部机制。 |
| `warmUpReferences()`                         | 支持，但不支持 `forUpdate` 参数。                               |

## 更新依赖 {#update-dependencies}

将 JDBC 传输层和 DAO 构件替换为对应的 R2DBC 构件：

<compare first-title="JDBC DAO" second-title="R2DBC DAO" type="top-bottom">

```kotlin
implementation("org.jetbrains.exposed:exposed-core:%exposed_version%")
implementation("org.jetbrains.exposed:exposed-jdbc:%exposed_version%")
implementation("org.jetbrains.exposed:exposed-dao:%exposed_version%")
```

```kotlin
implementation("org.jetbrains.exposed:exposed-core:%exposed_version%")
implementation("org.jetbrains.exposed:exposed-r2dbc:%exposed_version%")
implementation("org.jetbrains.exposed:exposed-dao-r2dbc:%exposed_version%")
```

</compare>

> 不要在同一个源集中同时保留 JDBC 和 R2DBC DAO 构件。它们定义了简单名称相同的类，例如 `Entity`、`EntityClass`
> 和 `EntityCache`。
>
{style="note"}

请使用与您的数据库对应的 R2DBC 驱动程序，例如：

<compare first-title="JDBC DAO" second-title="R2DBC DAO" type="top-bottom">

```kotlin
implementation("com.h2database:h2:%h2_db_version%")
```

```kotlin
implementation("io.r2dbc:r2dbc-h2:%h2_r2dbc_version%")
```

</compare>

> 有关支持的数据库及其对应驱动程序依赖的完整列表，请参阅 [](Working-with-Database.md)。
>
{style="tip"}

## 显式启用实验性 API {#opt-in-to-the-experimental-api}

R2DBC DAO API 处于实验阶段，需要显式启用。要为整个模块启用此 API，请将 `ExperimentalR2dbcDaoApi`
添加到 Kotlin 编译器选项中：

```kotlin
kotlin {
    compilerOptions {
        optIn.add("org.jetbrains.exposed.v1.dao.r2dbc.ExperimentalR2dbcDaoApi")
    }
}
```

要在更小的作用域内启用，请改用 `@OptIn(ExperimentalR2dbcDaoApi::class)`。

## 更新导入 {#update-imports}

R2DBC DAO API 位于 `org.jetbrains.exposed.v1.dao.r2dbc` 包中。

对于 DAO，请将所有导入中的 `org.jetbrains.exposed.v1.dao.` 包替换为 `org.jetbrains.exposed.v1.dao.r2dbc.`。
例如：

| JDBC DAO                                      | R2DBC DAO                                           |
|-----------------------------------------------|-----------------------------------------------------|
| `org.jetbrains.exposed.v1.dao.IntEntity`      | `org.jetbrains.exposed.v1.dao.r2dbc.IntEntity`      |
| `org.jetbrains.exposed.v1.dao.IntEntityClass` | `org.jetbrains.exposed.v1.dao.r2dbc.IntEntityClass` |
| `org.jetbrains.exposed.v1.dao.entityCache`    | `org.jetbrains.exposed.v1.dao.r2dbc.entityCache`    |
| `org.jetbrains.exposed.v1.dao.load`           | `org.jetbrains.exposed.v1.dao.r2dbc.load`           |
| `org.jetbrains.exposed.v1.dao.with`           | `org.jetbrains.exposed.v1.dao.r2dbc.with`           |
| `org.jetbrains.exposed.v1.dao.Referrers`      | `org.jetbrains.exposed.v1.dao.r2dbc.Referrers`      |
| `org.jetbrains.exposed.v1.dao.InnerTableLink` | `org.jetbrains.exposed.v1.dao.r2dbc.InnerTableLink` |

表定义无需更改。它们由 `exposed-core` 模块提供，由 JDBC 和
R2DBC 驱动程序共用。

## 更新事务处理 {#update-transaction-handling}

R2DBC DAO 操作是挂起操作，因此包含这些操作的函数在需要时必须声明为 `suspend`。
将 `transaction()` 函数替换为 `suspendTransaction()`：

<compare first-title="JDBC DAO" second-title="R2DBC DAO">

```kotlin
import org.jetbrains.exposed.v1.jdbc.transactions.transaction

val client = transaction {
    Client.findById(id)
}
```

```kotlin
import org.jetbrains.exposed.v1.r2dbc.transactions.suspendTransaction

val client = suspendTransaction {
    Client.findById(id)
}
```

</compare>

> 对于 R2DBC DAO，请从 `org.jetbrains.exposed.v1.r2dbc.transactions` 导入 `suspendTransaction()`。
>
> `org.jetbrains.exposed.v1.jdbc.transactions` 中的 `suspendTransaction()` 函数用于通过阻塞式 JDBC 连接
> 执行挂起操作。
>
> 如果您正在从 JDBC 迁移到 R2DBC，请参阅 [](Migration-Guide-1-0-0.md) 指南，了解 Exposed 核心 API 和
> 数据库操作的变更。
>
{style="note"}

## 更新实体创建方式 {#update-entity-creation}

R2DBC DAO 提供了两个实体创建函数：

| 函数       | 是否挂起 | 发出 `INSERT` 的时机 | 调用后是否可获取 ID                                                    |
|----------------|----------|-----------------------------|--------------------------------------------------------------------------------|
| `new()`        | 否       | 下次刷新时           | 仅当 ID 已显式赋值，或无需插入即可通过其他方式获取时 |
| `newSuspend()` | 是      | 调用返回前     | 是，包括生成的 ID                                                   |

### 使用 `newSuspend()` 立即插入 {#use-newsuspend-for-immediate-inserts}

`newSuspend()` 函数会挂起，并在返回之前发出 `INSERT`，因此可以立即获取生成的 ID。

当实体必须在函数返回之前完成插入时，请使用 `newSuspend()`：

<compare first-title="JDBC DAO" second-title="R2DBC DAO">

```kotlin
val client = Client.new {
    name = "Alice Johnson"
}
val id = client.id.value
```

```kotlin
val client = Client.newSuspend {
    name = "Alice Johnson"
}
val id = client.id.value
```

</compare>

### 使用 `new()` 延迟插入和批量插入 {#use-new-for-deferred-and-batch-inserts}

`new()` 函数不会立即发出 `INSERT`，而是将插入操作安排到事务的
实体缓存中。
当您希望创建多个实体并一起刷新时，这种方式很有用：

```kotlin
suspendTransaction {
    val tags = listOf("tech", "finance", "energy").map {
        name -> Tag.new {
            this.name = name
        }
    }
    
    flushCache()
    
    val ids = tags.map {
        it.id.value
    }
}
```

待执行的插入操作会在后续数据库操作需要时或事务提交时刷新。如果需要显式控制何时将待执行的插入操作发送到数据库，
请调用 `flushCache()`。

> 尽管 JDBC 和 R2DBC DAO 都提供 `new()` 函数，且两者都会安排插入操作，但新实体的属性 getter
> 的行为有所不同。迁移时，请检查每一个期望数据行或其生成的 ID
> 立即可用的 `new()` 调用。在这些情况下继续使用 `new()` 会抛出异常，
> 因此应将其替换为 `newSuspend()`。
>
{style="note"}

## 更新引用属性 {#update-reference-properties}

R2DBC 引用属性使用访问器，因为读取引用可能需要执行挂起的数据库操作。

将 `referencedOn` 和 `optionalReferencedOn` 属性从 `var` 改为 `val`。通过调用访问器
读取引用，并使用 `.set()` 函数更新引用：

<compare first-title="JDBC DAO" second-title="R2DBC DAO" type="top-bottom">

```kotlin
var broker by Broker referencedOn Clients.broker
var portfolio by Portfolio optionalReferencedOn Trades.portfolio

val name = client.broker.name
client.broker = otherBroker
trade.portfolio = null
```

```kotlin
val broker by Broker referencedOn Clients.broker
val portfolio by Portfolio optionalReferencedOn Trades.portfolio

val name = client.broker().name
client.broker.set(otherBroker)
trade.portfolio.set(null)
```

</compare>

> 将属性保留为 `var` 会导致编译错误，因为 R2DBC 引用访问器不提供
> 所需的 `setValue()` 运算符。
>
{style="note"}

> `client.broker` 返回的是引用访问器，而不是 `Broker` 实体。请使用 `client.broker()` 获取
> 被引用的实体。
>
{style="note"}

`backReferencedOn` 和 `optionalBackReferencedOn` 属性保持不变。`via` 属性仍为 `var`，
并接受 `SizedCollection`。

## 收集 DAO 流 {#collect-dao-flows}

在 R2DBC DAO 中，`SizedIterable` 继承自 `Flow`。因此，DAO 集合以流的形式表示，而不是 Kotlin
集合。

这适用于引用方、`via` 关系、`all()` 和 `find()` 等 DAO 集合。

<compare first-title="JDBC DAO" second-title="R2DBC DAO" type="top-bottom">

```kotlin
val names = client.portfolios.map { it.name }
```

```kotlin
val names = client.portfolios.toList().map { it.name }
```

</compare>

`count()`、`first()`、`firstOrNull()` 和 `single()` 等终端操作无需额外更改。

> 如果 `kotlinx.coroutines.flow.map` 在作用域内，`client.portfolios.map()` 仍可编译，但
> 返回的是 `Flow` 而不是 `List`。对于任何预期生成集合的操作符，
> 请在其前面添加 `.toList()`。
>
{style="warning"}

## 跨事务附加实体 {#attach-entities-across-transactions}

与 JDBC DAO 不同，在 R2DBC DAO 中，在一个事务中加载或创建的实体不会自动注册到
另一个 R2DBC 事务中。这是因为该过程需要检查数据库，而属性 setter 无法挂起。

要跨事务复用实体，请在修改来自另一个事务的实体之前调用 `attach()` 函数：

<compare first-title="JDBC DAO" second-title="R2DBC DAO">

```kotlin
val item = transaction {
    Item.new {
        name = "foo"
    }
}

transaction {
    item.name = "bar"
}
```

```kotlin
val item = suspendTransaction {
    Item.newSuspend {
        name = "foo"
    }
}

suspendTransaction {
    Item.attach(item)
    item.name = "bar"
}
```

</compare>

如果数据行已不存在，`attach()` 函数会抛出 `EntityNotFoundException`。如果当前事务已经
缓存了同一数据行的另一个实例，且该实例包含尚未刷新的更改，`attach()` 会抛出 `IllegalStateException`。

要替换缓存的实例并丢弃其尚未刷新的更改，请使用 `attach(item, force = true)`。

