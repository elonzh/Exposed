<show-structure for="chapter,procedure" depth="2"/>

# Exposed 1.6.0 新特性 {#what-s-new-in-exposed-1-6-0}

## R2DBC DAO 支持 {#r2dbc-dao-support}

<primary-label ref="experimental"/>

Exposed 1.6.0 通过 `exposed-dao-r2dbc` 构件为 DAO API 引入了实验性 R2DBC 支持。现在，你可以
将 Exposed DAO 与 R2DBC 结合使用，实现非阻塞数据库访问，同时保留 DAO 实体模型以及熟悉的
查询和关系 API。

R2DBC DAO 提供了与 JDBC DAO 相同的核心 DAO 概念，包括[实体](dao-entity-definition.md)、
[引用](dao-relationships.md)、[查询](dao-crud-operations.md)和[事务](Transactions.md)，
并对 API 进行了适配，以支持挂起式数据库操作。

例如，要使用 R2DBC DAO 创建并插入实体，可以在 `suspendTransaction {}` 块中使用 `newSuspend()`
函数：

```kotlin
suspendTransaction {
    val film = StarWarsFilmEntity.newSuspend {
        name = "The Last Jedi"
    }
    println(film.id.value)
}
```

> 对于 R2DBC DAO，请从 `org.jetbrains.exposed.v1.r2dbc.transactions` 导入 `suspendTransaction()`。
>
> `org.jetbrains.exposed.v1.jdbc.transactions` 中的 `suspendTransaction()` 函数用于通过阻塞式 JDBC 连接执行挂起操作。
>
{style="note"}

由于采用挂起式操作，R2DBC DAO 的 API 存在以下差异：

* `new()` 函数会将插入操作推迟到下一次刷新时执行，而 `newSuspend()` 函数
  则会创建并立即插入实体，然后再返回该实体。如果需要在计划的刷新操作执行之前
  访问所返回实体的 ID 或其他由数据库生成的值，应使用 `newSuspend()` 函数。如果继续
  使用 `new()` 并访问这些字段，则会抛出异常。
* 引用属性（例如 `referencedOn`）使用访问器，因此需要[通过调用来获取被引用的实体](dao-relationships.md#accessing-data)，
  例如 `filmRating.film()`。设置被引用的实体时，则需调用 `.set()` 函数。
* DAO 集合以 Kotlin `Flow` 的形式提供，因此在需要集合时，应使用 `.toList()` 等终结操作。
* 在一个事务中创建或加载的实体，[必须使用 `attach()` 函数进行附加](dao-crud-operations.md#update-later)，
  才能在另一个 R2DBC 事务中修改。

> 有关所需更改的完整概述，请参阅 [R2DBC DAO 迁移指南](migrating-from-jdbc-to-r2dbc-dao.md)。
>
{style="tip"}

## 非空列转换 {#non-null-column-transformations}

现在，你可以使用新的 [`.nonNullTransform()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/non-null-transform.html)
函数，将可空的数据库列表示为非空的 Exposed 列。

如果数据库列允许 `null`，但应用程序可以使用一个有意义的非空值来表示该值，
就可以使用此函数。

在以下示例中，`UNSCHEDULED` 枚举项表示未指定用餐时间：

```kotlin
enum class Meal {
    BREAKFAST,
    LUNCH,
    DINNER,
    UNSCHEDULED
}

class MealTimeNonNullTransformer : ColumnTransformer<LocalTime?, Meal> {
    override fun wrap(value: LocalTime?): Meal = when {
        value == null -> Meal.UNSCHEDULED
        value.hour < 10 -> Meal.BREAKFAST
        value.hour < 15 -> Meal.LUNCH
        else -> Meal.DINNER
    }

    override fun unwrap(value: Meal): LocalTime? = when (value) {
        Meal.BREAKFAST -> LocalTime(8, 0)
        Meal.LUNCH -> LocalTime(12, 0)
        Meal.DINNER -> LocalTime(18, 0)
        Meal.UNSCHEDULED -> null
    }
}

object Meals : Table() {
    val mealTime: Column<Meal> = time("meal_time")
        .nullable()
        .nonNullTransform(MealTimeNonNullTransformer())
}
```

> 更多信息，请参阅 [](column-transformation.md)。
>
{style="tip"}

## 无表 SELECT 查询 {#tableless-select-queries}

Exposed 1.6.0 引入了无表 `SELECT` 查询，允许你在不指定表或
`FROM` 子句的情况下选择表达式。

使用顶层 `select()` 函数创建查询，默认情况下会返回一行。`WHERE` 条件可以
过滤掉这一行，从而得到空结果：

```kotlin
val numberOne = intLiteral(1)
val query: Query = select(numberOne, CurrentTimestamp)
val one: Int = query.single()[numberOne]

val query2 = select(listOf(intLiteral(1), stringLiteral("ready")))

val noRows = select(intLiteral(1)).where { Op.FALSE }
```

对于只选择单个表达式的查询，可以使用 `selectValue()` 函数立即执行查询并返回
具有相应类型的结果，无需将表达式用作结果行的键。此函数还可以直接接受受支持的 Kotlin 标量值，
并将其包装为 SQL 字面量：

```kotlin
val one: Int = selectValue(1)
val ready = selectValue("ready")
val serverTime = selectValue(CurrentTimestamp)
```

无表查询是普通的 `Query` 对象，支持现有的查询操作，例如过滤、集合操作、
派生表别名以及从查询结果插入数据的操作。

> 更多信息，请参阅 [](DSL-Querying-data.topic#tableless-select)。
>
{style="tip"}

## 在迁移插件中配置多个表所在的包 {#configure-multiple-table-packages-in-migration-plugins}

你可以配置 [Exposed Gradle](Exposed-gradle-plugin.md) 和 [Maven](exposed-maven-plugin.md) 插件，在生成
迁移时使用多个表所在的包。当表定义分散在不同的包中时，这一功能很有用。

例如，在 Gradle 配置中，使用 `tablesPackage` 属性指定单个包，或使用
`tablesPackages` 属性指定多个包：

```kotlin
exposed {
    migrations {
        tablesPackage = "com.example.db.tables"
        // or
        tablesPackages = listOf(
            "com.example.db.auth",
            "com.example.db.billing",
        )
        // ...
    }
}
```

> 更多信息，请参阅 [Exposed Gradle 插件](Exposed-gradle-plugin.md#configuration)和 [Exposed Maven 插件](exposed-maven-plugin.md#configuration)
> 文档。
>
{style="tip"}
