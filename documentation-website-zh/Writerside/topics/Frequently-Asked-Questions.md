# 常见问题

### 什么是 Exposed？

Exposed 是一个基于 Kotlin 的 SQL 库，结合了用于构建查询的 DSL、对象关系映射（ORM）功能以及用于管理实体的 DAO 框架。它允许开发者编写类型安全的查询，并使用 Kotlin 表达性强且简洁的语法与数据库进行交互。
有关更详细的描述，请参见[关于](About.topic)部分。

### 可以使用多个数据库连接吗？

可以。你可以通过将数据库引用传递给 `transaction()` 函数来使用多个数据库连接。
有关更多详情和示例，请参见 [](Transactions.md#working-with-multiple-databases)。

### 支持哪些数据类型？

Exposed 支持多种数据类型，包括[基本数据类型](Numeric-Boolean-String-Types.topic)、[日期和时间](Date-and-time-types.topic)、[数组](Array-types.topic)、[二进制数据](Binary-types.topic)、[枚举](Enumeration-types.topic)以及 [](JSON-And-JSONB-types.topic)。你还可以扩展和创建新的[自定义数据类型](Custom-data-types.topic)以满足特定需求。

### 如何创建自定义列类型？

你可以使用 [`IColumnType`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-column-type/index.html) 接口实现自定义列类型，并使用 [`registerColumn()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/register-column.html) 将其注册到表。有关更多信息，请参阅[自定义数据类型](Custom-data-types.topic)文档。

### 是否可以在没有数据库连接的情况下生成 SQL？

不可以，Exposed 需要数据库连接才能生成 SQL。SQL 生成依赖于数据库方言和事务上下文，这两者都由活动数据库连接确定。由于 Exposed 会根据底层数据库动态调整查询，因此即使查询从未执行，也需要连接。

### 如何获取将要执行的原始 SQL 查询？

你可以使用 [`Statement.prepareSQL()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core.statements/-statement/prepare-s-q-l.html) 函数，以及可能的 [`buildStatement()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core.statements/build-statement.html) 函数。有关更多详情，请参见 [](DSL-Statement-Builder.md)。

### 是否可以相对于当前字段值更新字段？

可以。你可以通过使用 `.update()` 函数配合所需的 `Expression` 或直接设置字段值来实现。
有关更多信息，请参见[如何更新记录](DSL-CRUD-operations.topic#update-record)。

### 如何准备类似 `SELECT * FROM table WHERE (x,y) IN ((1, 2), (3, 4), (5, 6))` 的查询？

Exposed 提供了 [`inList()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/in-list.html) 函数，该函数支持列对。有关更多详情，请参见 [](DSL-Querying-data.topic#collection-condition-pairs-or-triples)。

### 如何将 DSL 查询结果转换为 DAO 实体？

要将 DSL 查询结果转换为实体，你可以使用 DAO 的 [`wrapRow()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/wrap-row.html) 函数，该函数允许你将行包装为 DAO 实体。

### 如何实现嵌套查询？

你可以使用 `alias()` 函数创建子查询，并将其与其他表或查询连接起来实现嵌套查询。有关更多信息，请参阅[别名](DSL-Querying-data.topic#alias)文档。

### 是否可以创建具有循环（环形）引用的表？

可以。要定义此类表，你可以使用 [`reference()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/reference.html) 或 [`optReference()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/opt-reference.html) 函数来建立表之间的外键关系。有关更多信息，请参见 [](DAO-Relationships.topic) 主题。

### 如何使用保存点？

你可以通过事务中的 `ExposedConnection.setSavepoint()` 方法设置保存点。有关更多详情，请参见 [](Transactions.md#using-savepoints)。

### 是否可以直接将底层 JDBC 连接与 Exposed 一起使用？

可以，通过访问事务块的 `connection` 属性包装的原始连接：

```Kotlin
transaction {
    val lowLevelCx = connection.connection as java.sql.Connection

    val stmt = lowLevelCx.prepareStatement("INSERT INTO TEST_TABLE (AMOUNT) VALUES (?)")
    stmt.setInt(1, 99)
    stmt.addBatch()
    stmt.setInt(1, 100)
    stmt.addBatch()
    stmt.executeBatch()

    val query = lowLevelCx.createStatement()
    val result = query.executeQuery("SELECT COUNT(*) FROM TEST_TABLE")
    result.next()
    val count = result.getInt(1)
    println(count) // 2
}
```

### 如何添加另一种数据库类型？

要添加 Exposed 当前不支持的另一种数据库类型，请实现 [`DatabaseDialect`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core.vendors/-database-dialect/index.html) 接口并使用 [`Database.registerDialect()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-database/-companion/register-dialect.html) 注册它。

如果该实现具有很大价值，请考虑将其[贡献](Contributing.md)给 Exposed。
