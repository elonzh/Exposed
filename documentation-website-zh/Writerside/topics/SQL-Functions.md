<show-structure for="chapter,procedure" depth="2"/>

# SQL 函数

Exposed 提供了对经典 SQL 函数的基本支持。本主题包含这些函数的定义及其用法示例。还解释了如何定义[自定义函数](#custom-functions)。

对于下面的函数示例，请参考以下表：

<code-block lang="kotlin"
            src="exposed-sql-functions/src/main/kotlin/org/example/tables/FilmBoxOfficeTable.kt"/>

## 如何使用函数
要使用 `.select()` 从查询中获取 SQL 函数的结果，请先将函数声明为变量：

<code-block lang="kotlin"
            src="exposed-sql-functions/src/main/kotlin/org/example/examples/StringFuncExamples.kt"
            include-lines="35-36"/>

你可以像[为表或查询设置别名](DSL-Querying-data.topic#alias)一样为此函数设置别名：

<code-block lang="kotlin"
            src="exposed-sql-functions/src/main/kotlin/org/example/examples/StringFuncExamples.kt"
            include-lines="39-40"/>

SQL 函数可以根据需要进行链接和组合。以下示例生成的 SQL 将两个列中存储的字符串值连接起来，然后将函数包装在 `TRIM()` 和 `LOWER()` 中：

<code-block lang="kotlin"
            src="exposed-sql-functions/src/main/kotlin/org/example/examples/StringFuncExamples.kt"
            include-lines="43-46"/>

## 字符串函数
### 小写和大写
要将字符串表达式转换为小写或大写，请分别使用 [`.lowerCase()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/lower-case.html)
和
[`.upperCase()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/upper-case.html)
函数。

<code-block lang="kotlin"
            src="exposed-sql-functions/src/main/kotlin/org/example/examples/StringFuncExamples.kt"
            include-lines="35-36"/>

### 子字符串
[`.substring()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/substring.html)
函数从指定的起始位置返回指定长度的子字符串值。

<code-block lang="kotlin"
            src="exposed-sql-functions/src/main/kotlin/org/example/examples/StringFuncExamples.kt"
            include-lines="49-50"/>

### 连接
[`concat()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/concat.html)
函数返回一个字符串值，该值连接所有非空输入值的文本表示，以可选的分隔符分隔。

<code-block lang="kotlin"
            src="exposed-sql-functions/src/main/kotlin/org/example/examples/StringFuncExamples.kt"
            include-lines="53-57"/>

### 定位
[`.locate()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/locate.html)
函数返回指定子字符串第一次出现的索引，如果未找到该子字符串则返回 0。

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/StringFuncExamples.kt" include-lines="60-61"/>

### 字符长度
[`.charLength()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/char-length.html)
函数返回以字符为单位的长度，如果字符串值为 null 则返回 `null`。

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/StringFuncExamples.kt" include-lines="64-65"/>

## 聚合函数
这些函数最可能在带有 [`.groupBy()`](DSL-Querying-data.topic#group-by) 的查询中使用。
### 最小值/最大值/平均值
要获取最小值、最大值和平均值，请分别使用
[`.min()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/min.html)
[`.max()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/max.html)
和 [`.avg()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/avg.html) 函数。
这些函数可以应用于任何可比较的表达式：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/AggregateFuncExamples.kt" include-lines="20-28"/>

### 求和/计数
你可以直接对列表达式使用 `SUM()` 和 `COUNT()` 等 SQL 函数：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/AggregateFuncExamples.kt" include-lines="31-38"/>

### 统计
某些数据库专门提供用于统计的聚合函数，Exposed 支持其中四种：
[`.stdDevPop()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/std-dev-pop.html)、
[`.stdDevSamp()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/std-dev-samp.html)、
[`.varPop()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/var-pop.html)、
[`.varSamp()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/var-samp.html)。
以下示例检索存储在 `revenue` 列中的值的总体标准差：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/AggregateFuncExamples.kt" include-lines="41-45"/>

## 自定义函数
如果你找不到数据库中最常用的函数（因为 Exposed 仅提供对经典 SQL 函数的基本支持），你可以定义自己的函数。

定义自定义函数有多种选择：

1. [无参数函数](#functions-without-parameters)
2. [带额外参数的函数](#functions-with-additional-parameters)
3. [需要更复杂查询构建的函数](#functions-that-require-more-complex-query-building)

### 无参数函数

[`.function()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/function.html) 简单地将列表达式
包装在括号中，以字符串参数作为函数名：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/CustomFuncExamples.kt" include-lines="29-34"/>

### 带额外参数的函数

[`CustomFunction`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-custom-function/index.html) 类接受
函数名作为第一个参数，用于处理结果的列类型作为第二个参数。
之后，你可以提供任意数量的以逗号分隔的额外参数：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/CustomFuncExamples.kt" include-lines="37-43"/>

还有 `String`、`Long` 和 `DateTime` 函数的快捷方式：
* [`CustomStringFunction`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-custom-string-function.html)
* [`CustomLongFunction`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-custom-long-function.html)
* [`CustomDateTimeFunction`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/-custom-date-time-function.html)

使用这些快捷方式之一，上面的示例可以简化为：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/CustomFuncExamples.kt" include-lines="46-48"/>

在以下示例中，[`CustomDateFunction`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/-custom-date-function.html)
在 H2 数据库中用于模拟其 `DATEADD()` 函数，以计算当前日期前三个月的日期。
然后将其与 Exposed 内置的 [`.month()`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/month.html)
函数链接以返回找到的日期的月份，以便在查询中使用：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/CustomFuncExamples.kt" include-lines="55-65"/>

### 需要更复杂查询构建的函数

Exposed 中的所有函数都扩展了抽象类 [`Function`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-function/index.html)，
该类接受列类型并允许重写 `toQueryBuilder()`。这实际上是 `CustomFunction` 所做的，
可以利用它来创建更复杂的查询。

例如，Exposed 提供了 [`.trim()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/trim.html)
函数，用于移除字符串的前导和尾随空格。在某些数据库中（如 H2 和 MySQL），
这只是默认行为，因为可以提供说明符来将修剪限制为前导或尾随。这些数据库还允许你
提供除空格之外的特定子字符串来移除。下面的自定义函数支持这种扩展行为：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/CustomTrimFunction.kt" />

<note>
确保使用正确的导入语句：<code>import org.jetbrains.exposed.v1.core.Function</code>。否则，<code>kotlin-stdlib</code> 中的 <code>Function</code>
可能会被解析并导致编译错误。
</note>

然后可以使用此自定义函数来实现所需的精确修剪：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/CustomFuncExamples.kt" include-lines="72-81,83-85"/>

## 窗口函数

窗口函数允许对与当前行相关的一组表行进行计算。

可以使用现有的聚合函数（如 `sum()`、`avg()`），以及新的排名和值函数：
* [`cumeDist()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/cume-dist.html)
* [`denseRank()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/dense-rank.html)
* [`firstValue()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/first-value.html)
* [`lag()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/lag.html)
* [`lastValue()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/last-value.html)
* [`lead()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/lead.html)
* [`nthValue()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/nth-value.html)
* [`nTile()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/ntile.html)
* [`percentRank()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/percent-rank.html)
* [`rank()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/rank.html)
* [`rowNumber()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-i-sql-expression-builder/row-number.html)

要使用窗口函数，请在函数调用后链接
[`.over()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-function/over.html) 以包含 `OVER` 子句。
可以使用
[`.partitionBy()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-function-definition/partition-by.html)
和 [`.orderBy()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-function-definition/order-by.html) 可选地链接 `PARTITION BY` 和 `ORDER BY` 子句，
接受多个参数：

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/WindowFuncExamples.kt" include-lines="18-22,24-29,31-35"/>

帧子句函数，如 [`rows()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-function-definition/rows.html)、
[`range()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-function-definition/range.html) 和
[`groups()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-function-definition/groups.html)，
也受支持，并根据预期结果接受 [`WindowFrameBound`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-frame-bound/index.html) 选项：
* [`WindowFrameBound.currentRow()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-frame-bound/-companion/current-row.html)
* [`WindowFrameBound.unboundedPreceding()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-frame-bound/-companion/unbounded-preceding.html)
* [`WindowFrameBound.unboundedFollowing()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-frame-bound/-companion/unbounded-following.html)
* [`WindowFrameBound.offsetPreceding()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-frame-bound/-companion/offset-preceding.html)
* [`WindowFrameBound.offsetFollowing()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-window-frame-bound/-companion/offset-following.html)

<code-block lang="kotlin" src="exposed-sql-functions/src/main/kotlin/org/example/examples/WindowFuncExamples.kt" include-lines="38-43"/>

<note>
如果多个帧子句函数链接在一起，只有最后一个会被使用。
</note>
