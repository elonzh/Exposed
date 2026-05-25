<show-structure for="chapter,procedure" depth="2"/>

# 构建 SQL 语句

Exposed DSL 提供了多种函数来执行数据库操作，例如 [](DSL-CRUD-operations.topic)。
如果您需要在不执行的情况下访问此 DSL 生成的 SQL，
Exposed 通过 [`Statement.prepareSQL()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core.statements/-statement/prepare-s-q-l.html) 提供了此功能。

以下示例引用了先前定义的 [`StarWarsFilmsTable`](DSL-Table-Types.topic)，所有生成的
SQL 均基于 H2 数据库的输出。

<note>
此功能仍然需要连接和事务上下文，因为 Exposed 会根据底层数据库动态调整其语句和查询
构建，主要用于标识符和语法特性。
</note>

## 读取操作

<tldr>
    <p>API 参考：<a href="https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/-query/index.html"><code>Query</code> (JDBC)</a>，
    <a href="https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc/-query/index.html"><code>Query</code> (R2DBC)</a>
    </p>
</tldr>

`Query` 实例在其结果被消费（例如通过迭代）之前不会执行。
因此，查询可以被构建并存储以供后续使用：

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-symbol="filmQuery"/>

然后您可以调用 `.prepareSQL()` 来检查将发送到数据库的查询的 SQL 字符串表示：

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-symbol="querySql"/>

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-lines="27-29"/>

默认情况下，会准备并返回一个参数化的 SQL 字符串。要生成不含参数占位符的 SQL 字符串，
请将 `prepared` 参数设置为 `false`：

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-symbol="fullQuerySql"/>

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-lines="38-40"/>

## 其他操作

当在表上调用 [`.insert()`](DSL-CRUD-operations.topic#insert) 等函数时，Exposed 会自动将生成的 SQL
发送到数据库以创建新行。为避免自动执行，您可以直接实例化底层语句类，即
[`InsertStatement`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core.statements/-insert-statement/index.html)。

从 1.0.0 版本开始，您可以在 [`buildStatement {}`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core.statements/build-statement.html) 块中使用相同的 DSL 创建这些底层语句的实例，而无需自动执行：

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-symbol="insertFilm"/>

与[查询](#read-operations)一样，您可以使用 `.prepareSQL()` 访问要执行的 SQL 字符串：

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-symbol="preparedSql"/>

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-lines="57"/>

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-symbol="fullSql"/>

<code-block lang="kotlin"
    src="exposed-dsl/src/main/kotlin/org/example/examples/BuildStatementExamples.kt"
    include-lines="64"/>

### 执行语句

<tldr>
    <p>API 参考：<a href="https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/-jdbc-transaction/exec.html"><code>exec</code> (JDBC)</a>，
    <a href="https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc/-r2dbc-transaction/exec.html"><code>exec</code> (R2DBC)</a>
    </p>
</tldr>

存储的 `Statement` 可以通过先传递给可执行类来发送到数据库，该类是
[`BlockingExecutable`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.statements/-blocking-executable/index.html) (JDBC)
或 [`SuspendExecutable`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.statements/-suspend-executable/index.html) (R2DBC) 的子类。
然后可以在事务块中使用 `exec()` 将可执行对象发送到数据库。

如果已知适当的类或正在使用自定义语句或可执行类，可以手动完成：

```kotlin
exec(InsertBlockingExecutable(insertFilm))
```

或者，如果语句是使用 Exposed API 创建的，您可以使用 `Statement.toExecutable()`
（[JDBC](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.statements/to-executable.html)、
[R2DBC](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.statements/to-executable.html)）
来为调用语句类型解析适当的可执行类实例：

```kotlin
exec(insertFilm.toExecutable())
```
