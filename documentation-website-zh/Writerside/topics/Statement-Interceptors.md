<show-structure for="chapter,procedure" depth="2"/>

# 语句拦截器

事务中的 DSL 操作会创建 SQL 语句，并在这些语句上发出 *Execute*、*Commit* 和 *Rollback* 等命令。Exposed 提供了
[`StatementInterceptor`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core.statements/-statement-interceptor/index.html)
接口，允许你在语句生命周期的这些特定步骤之前和之后实现自己的逻辑。

`registerInterceptor()` 和 `unregisterInterceptor()` 可用于在单个事务中启用和禁用自定义拦截器。

要使用作用于所有事务的自定义拦截器，请改为实现
[`GlobalStatementInterceptor`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core.statements/-global-statement-interceptor/index.html)
接口。Exposed 使用 Java SPI ServiceLoader 来发现和加载此接口的任何实现。
在这种情况下，应在 *resources* 文件夹中创建一个新文件，名为：
```
META-INF/services/org.jetbrains.exposed.v1.core.statements.GlobalStatementInterceptor
```
此文件的内容应为所有自定义实现的完全限定类名。

## 挂起操作

<tldr>
    <p>
        <b>必需依赖</b>: <code>org.jetbrains.exposed:exposed-r2dbc</code>
    </p>
    <include from="lib.topic" element-id="r2dbc-supported"/>
</tldr>

Exposed 还提供了
[`SuspendStatementInterceptor`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.statements/-suspend-statement-interceptor/index.html)
和 [`GlobalSuspendStatementInterceptor`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.statements/-global-suspend-statement-interceptor/index.html)
接口。

与上一节类似，这些接口允许你在语句生命周期的相同位置实现自己的逻辑，
但它们的方法允许使用挂起函数和 R2DBC 挂起事务特有的数据库操作方法。

这些自定义挂起拦截器可以与核心语句拦截器以相同的方式启用和禁用。
