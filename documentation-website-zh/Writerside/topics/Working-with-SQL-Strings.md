<show-structure for="chapter,procedure" depth="2"/>

# 使用 SQL 字符串

在事务块中，可以使用 [`.exec()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-transaction/exec.html) 来执行 SQL 字符串以进行数据库操作。
此函数接受并执行一个 `String` 值参数，当需要特定数据库命令时可能很有用：

<code-block lang="kotlin"
            src="exposed-transactions/src/main/kotlin/org/example/examples/ExecExamples.kt"
            include-lines="26-28"/>

## 转换结果

发送到数据库的 SQL 字符串可能会返回结果，在这种情况下可以选择性地提供一个转换块。
以下示例检索当前数据库版本的单个结果：

<code-block lang="kotlin"
            src="exposed-transactions/src/main/kotlin/org/example/examples/ExecExamples.kt"
            include-lines="29-32"/>

此示例遍历结果并返回数据库 schema 信息的集合：

<code-block lang="kotlin"
            src="exposed-transactions/src/main/kotlin/org/example/examples/ExecExamples.kt"
            include-lines="35-45"/>

或者，可以创建一个便捷的扩展函数来直接使用 SQL 字符串，例如：

<code-block lang="kotlin"
            src="exposed-transactions/src/main/kotlin/org/example/examples/ExecAndMapFunction.kt"/>

然后可以按以下方式调用此函数：

<code-block lang="kotlin"
            src="exposed-transactions/src/main/kotlin/org/example/examples/ExecExamples.kt"
            include-lines="69-72"/>

## 参数化语句

SQL 字符串可以通过将值替换为字符串中的 `?` 占位符并为每个参数提供关联的列类型来进行参数化：

<code-block lang="kotlin"
            src="exposed-transactions/src/main/kotlin/org/example/examples/ExecExamples.kt"
            include-lines="80-90"/>

## 显式语句类型

默认情况下，`.exec()` 使用 SQL 字符串的第一个关键字来确定应如何执行该字符串以及数据库是否期望返回结果。该函数尝试将此关键字与
[`StatementType`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.sql.statements/-statement-type/index.html)
枚举常量之一进行匹配。

可以始终向参数 `explicitStatementType` 传递参数，以避免搜索匹配并承担意外行为的风险：

<code-block lang="kotlin"
            src="exposed-transactions/src/main/kotlin/org/example/examples/ExecExamples.kt"
            include-lines="47-50"/>

在所有已定义的 `StatementType` 中，只有四种会提示函数以期望返回结果的方式执行语句。这些类型是：
* `StatementType.SELECT`
* `StatementType.EXEC`
* `StatementType.SHOW`
* `StatementType.PRAGMA`

所有其他类型只期望返回受影响的行数。这意味着可以向 `explicitStatementType` 提供参数以覆盖默认行为。

例如，以 `EXPLAIN ` 开头的 SQL 字符串默认为 `StatementType.OTHER`，因为找不到匹配项。
这会导致 `.exec()` 失败，因为此类操作会提示数据库返回查询的执行计划。
只有提供了期望结果的语句类型覆盖（如 `StatementType.EXEC`），`.exec()` 才能成功：

<code-block lang="kotlin"
            src="exposed-transactions/src/main/kotlin/org/example/examples/ExecExamples.kt"
            include-lines="98-110"/>

## 多个 SQL 字符串

某些数据库允许在单个预处理语句中一起执行多个不同操作类型的 SQL 字符串，
这可以通过选择 `StatementType.MULTI` 来启用。

以下示例使用 MySQL 数据库执行插入操作，然后立即执行一个查询，返回最后插入行的 `id` 列值：

<code-block lang="kotlin"
            src="exposed-transactions/src/main/kotlin/org/example/examples/ExecMySQLExamples.kt"
            include-lines="25-40"/>

<note>
多个分组语句一起执行返回的确切结果（和结果数量）各不相同，具体取决于所使用的数据库。

某些数据库还需要特定的连接参数来启用这些操作。例如，
MySQL 需要在连接 url 字符串中添加 <code>allowMultiQueries=true</code>。
</note>