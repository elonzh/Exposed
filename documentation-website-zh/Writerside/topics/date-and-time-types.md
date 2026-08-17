[//]: # (title: 日期和时间类型)

<show-structure for="chapter,procedure" depth="2"/>
<var name="example_name" value="exposed-data-types"/>

<tldr>
    <p>
        <b>必需的依赖项</b>：<code>org.jetbrains.exposed:exposed-kotlin-datetime</code>、
        <code>org.jetbrains.exposed:exposed-java-time</code> 或
        <code>org.jetbrains.exposed:exposed-jodatime</code>
    </p>
    <include from="lib.topic" element-id="code_example"/>
    <include from="lib.topic" element-id="jdbc-supported"/>
    <include from="lib.topic" element-id="r2dbc-supported"/>
</tldr>

Exposed 通过专用[模块](#add-dependency)为日期和时间操作提供全面支持。每个模块都基于不同的日期时间库，
提供不同的功能和类型支持。

## 模块 {#modules}

| 模块                                                                                                                                        | 基于                                                                                      | 用途                                                                                 |
|-------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| [`exposed-kotlin-datetime`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/index.html) | [`kotlinx-datetime`](https://kotlinlang.org/api/kotlinx-datetime/)                      | 以 Kotlin 为先的现代方案，推荐用于新项目。                                                        |
| [`exposed-java-time`](https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/index.html)             | [Java 8 Time](https://docs.oracle.com/javase/8/docs/api/java/time/package-summary.html) | 与 Java 代码集成或需要兼容 Java 8 Time API 时的理想选择。                                         |
| [`exposed-jodatime`](https://jetbrains.github.io/Exposed/api/exposed-jodatime/org.jetbrains.exposed.v1.jodatime/index.html)               | [Joda-Time](https://www.joda.org/joda-time/)                                            | 用于遗留支持。新项目请考虑使用较新的模块。                                                          |

## 添加依赖项 {id="add-dependency"}

使用日期和时间列类型或函数之前，请将所选的日期时间模块添加到构建文件中：

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">
<var name="artifact_name" value="exposed-kotlin-datetime" />
<include from="lib.topic" element-id="add-dependency"/>
</tab>

<tab title="exposed-java-time" group-key="exposed-java-time">
<var name="artifact_name" value="exposed-java-time"/>
<include from="lib.topic" element-id="add-dependency"/>
</tab>

<tab title="exposed-jodatime" group-key="exposed-jodatime">
<var name="artifact_name" value="exposed-jodatime"/>
<include from="lib.topic" element-id="add-dependency"/>
</tab>
</tabs>

## 基本用法

要定义日期和时间列，请使用所选[日期时间模块](#modules)提供的列函数。
以下示例定义了常见日期和时间类型的列：

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

```kotlin
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.datetime.*

object Events : Table() {
    val id = integer("id").autoIncrement()
    val name = varchar("name", 50)
    val startDate = date("start_date")
    val startTime = time("start_time")
    val createdAt = datetime("created_at")
        .defaultExpression(CurrentDateTime)
    val lastModified = timestamp("last_modified")
    val scheduledAt = timestampWithTimeZone("scheduled_at")
    val period = duration("period")

    override val primaryKey = PrimaryKey(id)
}
```
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

```kotlin
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.javatime.*

object Events : Table() {
    val id = integer("id").autoIncrement()
    val name = varchar("name", 50)
    val startDate = date("start_date")
    val startTime = time("start_time")
    val createdAt = datetime("created_at")
        .defaultExpression(CurrentDateTime)
    val lastModified = timestamp("last_modified")
    val scheduledAt = timestampWithTimeZone("scheduled_at")
    val period = duration("period")

    override val primaryKey = PrimaryKey(id)
}
```

</tab>
<tab title="exposed-java-time" group-key="exposed-jodatime">

```kotlin
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.jodatime.*

object Events : Table() {
    val id = integer("id").autoIncrement()
    val name = varchar("name", 50)
    val startDate = date("start_date")
    val startTime = time("start_time")
    val createdAt = datetime("created_at")
        .defaultExpression(CurrentDateTime)
    val scheduledAt = timestampWithTimeZone("scheduled_at")

    override val primaryKey = PrimaryKey(id)
}
```
</tab>
</tabs>

## 支持的类型

每个日期时间模块都提供自己的类型集。选择一个模块，即可查看其支持的类型和 API 链接：

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

| 列类型                                                      | 数据库类型                      | Kotlin 类型                        | API                                                                                                                                                          |
|----------------------------------------------------------|----------------------------|----------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`date()`](#date-type)                                   | `DATE`                     | `kotlinx.datetime.LocalDate`     | [`date()`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/date.html)                                      |
| [`time()`](#time-type)                                   | `TIME`                     | `kotlinx.datetime.LocalTime`     | [`time()`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/time.html)                                      |
| [`datetime()`](#datetime-type)                           | `DATETIME`                 | `kotlinx.datetime.LocalDateTime` | [`datetime()`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/datetime.html)                              |
| [`timestamp()`](#timestamp-type)                         | `TIMESTAMP`                | `kotlin.time.Instant`            | [`timestamp()`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/timestamp.html)                            |
| [`timestampWithTimeZone()`](#timestampWithTimeZone-type) | `TIMESTAMP WITH TIME ZONE` | `java.time.OffsetDateTime`       | [`timestampWithTimeZone()`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/timestamp-with-time-zone.html) |
| [`duration()`](#duration-type)                           | `BIGINT`                   | `kotlin.time.Duration`           | [`duration()`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/duration.html)                              |

</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

| 列类型                                                      | 数据库类型                      | Java 类型                    | API                                                                                                                                                    |
|----------------------------------------------------------|----------------------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`date()`](#date-type)                                   | `DATE`                     | `java.time.LocalDate`      | [`date()`](https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/date.html)                                      |
| [`time()`](#time-type)                                   | `TIME`                     | `java.time.LocalTime`      | [`time()`](https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/time.html)                                      |
| [`datetime()`](#datetime-type)                           | `DATETIME`                 | `java.time.LocalDateTime`  | [`datetime()`](https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/datetime.html)                              |
| [`timestamp()`](#timestamp-type)                         | `TIMESTAMP`                | `java.time.Instant`        | [`timestamp()`](https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/timestamp.html)                            |
| [`timestampWithTimeZone()`](#timestampWithTimeZone-type) | `TIMESTAMP WITH TIME ZONE` | `java.time.OffsetDateTime` | [`timestampWithTimeZone()`](https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/timestamp-with-time-zone.html) |
| [`duration()`](#duration-type)                           | `BIGINT`                   | `java.time.Duration`       | [`duration()`](https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/duration.html)                              |

</tab>
<tab title="exposed-jodatime" group-key="exposed-jodatime">

| 列类型                                                      | 数据库类型                      | Joda-Time 类型              | API                                                                                                                                                   |
|----------------------------------------------------------|----------------------------|---------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`date()`](#date-type)                                   | `DATE`                     | `org.joda.time.DateTime`  | [`date()`](https://jetbrains.github.io/Exposed/api/exposed-jodatime/org.jetbrains.exposed.v1.jodatime/date.html)                                      |
| [`time()`](#time-type)                                   | `TIME`                     | `org.joda.time.LocalTime` | [`time()`](https://jetbrains.github.io/Exposed/api/exposed-jodatime/org.jetbrains.exposed.v1.jodatime/time.html)                                      |
| [`datetime()`](#datetime-type)                           | `DATETIME`                 | `org.joda.time.DateTime`  | [`datetime()`](https://jetbrains.github.io/Exposed/api/exposed-jodatime/org.jetbrains.exposed.v1.jodatime/datetime.html)                              |
| [`timestampWithTimeZone()`](#timestampWithTimeZone-type) | `TIMESTAMP WITH TIME ZONE` | `org.joda.time.DateTime`  | [`timestampWithTimeZone()`](https://jetbrains.github.io/Exposed/api/exposed-jodatime/org.jetbrains.exposed.v1.jodatime/timestamp-with-time-zone.html) |

</tab>
</tabs>

> 某些类型在特定数据库方言中可能有所不同。请参阅数据库文档了解确切的类型映射。
>
{style="note"}

### `date()` {id="date-type"}

`date()` 列类型映射到数据库的 `DATE` 类型。它用于存储不带时间
部分的日期值：

```kotlin
val startDate = date("start_date")
```

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

```kotlin
import kotlinx.datetime.LocalDate

Events.insert {
    it[startDate] = LocalDate(1990, 1, 1)
}
```
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

```kotlin
import java.time.LocalDate

Events.insert {
    it[startDate] = LocalDate.of(1990, 1, 1)
}
```
</tab>
<tab title="exposed-jodatime" group-key="exposed-jodatime">

```kotlin
import org.joda.time.DateTime

Events.insert {
    it[startDate] = DateTime(1990, 1, 1, 0, 0, 0)
}
```
</tab>
</tabs>

### `time()` {id="time-type"}

`time()` 列类型映射到数据库的 `TIME` 类型。它用于存储不带日期
部分的时间值。

```kotlin
val startTime = time("start_time")
```

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

```kotlin
import kotlinx.datetime.LocalTime

Events.insert {
    it[startTime] = LocalTime(9, 0) // 09:00
}
```
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

```kotlin
import java.time.LocalTime

Events.insert {
    it[startTime] = LocalTime.of(9, 0) // 09:00
}
```
</tab>
<tab title="exposed-jodatime" group-key="exposed-jodatime">

```kotlin
import org.joda.time.LocalTime

Events.insert {
    it[startTime] = LocalTime(9, 0) // 09:00
}
```
</tab>
</tabs>


### `datetime()` {id="datetime-type"}

`datetime()` 列类型映射到数据库的 `DATETIME` 类型。它用于存储日期和时间值。

以下示例会在插入新记录时设置当前日期/时间：

```kotlin
val createdAt = datetime("created_at").defaultExpression(CurrentDateTime)
```

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

```kotlin
import kotlinx.datetime.toLocalDateTime
import kotlinx.datetime.TimeZone
import kotlin.time.Clock

Events.insert {
    it[createdAt] = Clock.System.now().toLocalDateTime(TimeZone.UTC)
}
```
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

```kotlin
import java.time.LocalDateTime

Events.insert {
    it[createdAt] = LocalDateTime.now()
}
```
</tab>
<tab title="exposed-jodatime" group-key="exposed-jodatime">

```kotlin
import org.joda.time.DateTime

Events.insert {
    it[createdAt] = DateTime.now()
}
```
</tab>
</tabs>

### `timestamp()` {id="timestamp-type"}

`timestamp()` 列类型映射到数据库的 `TIMESTAMP` 类型。它用于存储日期和时间值。
> `exposed-jodatime` 不支持此类型。
>
{style="warning"}

```kotlin
val lastModified = timestamp("last_modified")
```

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

```kotlin
import kotlin.time.Clock

Events.insert {
    it[lastModified] = Clock.System.now()
}
```
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

```kotlin
import java.time.Instant

Events.insert {
    it[lastModified] = Instant.now()
}
```
</tab>
</tabs>


### `timestampWithTimeZone()` {id="timestampWithTimeZone-type"}

`timestampWithTimeZone()` 列类型映射到数据库的 `TIMESTAMP WITH TIME ZONE` 类型。它用于存储
日期和时间值，同时保留时区信息。

```kotlin
val scheduledAt = timestampWithTimeZone("scheduled_at")
```

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

```kotlin
import kotlin.time.Clock
import kotlin.time.toJavaInstant
import java.time.ZoneOffset

Events.insert {
    it[scheduledAt] = Clock.System.now().toJavaInstant().atOffset(ZoneOffset.UTC)
}
```
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

```kotlin
import java.time.OffsetDateTime
import java.time.ZoneOffset

Events.insert {
    it[scheduledAt] = OffsetDateTime.now(ZoneOffset.UTC)
}
```
</tab>
<tab title="exposed-jodatime" group-key="exposed-jodatime">

```kotlin
import org.joda.time.DateTime
import org.joda.time.DateTimeZone

Events.insert {
    it[scheduledAt] = DateTime.now().withZone(DateTimeZone.UTC)
}
```
</tab>
</tabs>


### `duration()` {id="duration-type"}

`duration()` 列类型映射到数据库的 `BIGINT` 类型。它用于存储两个
时刻之间的时长。
> `exposed-jodatime` 不支持此类型。
>
{style="warning"}

```kotlin
val period = duration("period")
```

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

```kotlin
import kotlin.time.Duration.Companion.hours

Events.insert {
    it[period] = 4.hours
}
```
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

```kotlin
import java.time.Duration

Events.insert {
    it[period] = Duration.ofHours(4)
}
```
</tab>
</tabs>

> 某些数据库提供特定的间隔类型（如 PostgreSQL 的 `INTERVAL`）来存储时间间隔。请参阅
> 数据库文档了解其支持的时间间隔类型。
>
> 有关处理自定义时间值的更多详情，请参阅
> [自定义日期和时间类型](Custom-data-types.topic#date-and-time-data)部分。
>
{style="tip"}

## 使用日期和时间表达式

### 提取日期和时间组成部分

Exposed 提供了用于从日期和时间表达式中提取各个组成部分的扩展函数。这些
函数返回可用于查询的 SQL 表达式，包括 `SELECT`、`WHERE`、`GROUP BY` 和 `ORDER BY`
子句。

每个 Exposed 日期时间模块所支持的日期和时间类型均可使用以下函数：

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">
<var name="date_time_api_module" value="exposed-kotlin-datetime"/>
<var name="date_time_api_package" value="org.jetbrains.exposed.v1.datetime"/>
<include from="lib.topic" element-id="date-time-components"/>
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">
<var name="date_time_api_module" value="exposed-java-time"/>
<var name="date_time_api_package" value="org.jetbrains.exposed.v1.javatime"/>
<include from="lib.topic" element-id="date-time-components"/>
</tab>
<tab title="exposed-jodatime" group-key="exposed-jodatime">
<var name="date_time_api_module" value="exposed-jodatime"/>
<var name="date_time_api_package" value="org.jetbrains.exposed.v1.jodatime"/>
<include from="lib.topic" element-id="date-time-components"/>
</tab>
</tabs>

例如，以下查询会选择所有在六月开始的事件：

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

```kotlin
import org.jetbrains.exposed.v1.datetime.month

Events.selectAll().where { Events.startDate.month() eq 6 }
```
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

```kotlin
import org.jetbrains.exposed.v1.javatime.month

Events.selectAll().where { Events.startDate.month() eq 6 }
```
</tab>
<tab title="exposed-jodatime" group-key="exposed-jodatime">

```kotlin
import org.jetbrains.exposed.v1.jodatime.month

Events.selectAll().where { Events.startDate.month() eq 6 }
```
</tab>
</tabs>


### 使用当前日期和时间

Exposed 提供以下表达式，用于从数据库服务器获取当前日期和时间：

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">
<deflist type="medium">
<def id="CurrentDateKotlinDatetime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/-current-date/index.html">
<code>CurrentDate</code>
</a>
</title>

返回 `kotlinx.datetime.LocalDate` 类型的当前日期。
</def>
<def id="CurrentDateTimeKotlinDatetime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/-current-date-time/index.html">
<code>CurrentDateTime</code>
</a>
</title>

返回 `kotlinx.datetime.LocalDateTime` 类型的当前日期和时间。
</def>
<def id="CurrentTimestampKotlinDatetime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/-current-timestamp/index.html">
<code>CurrentTimestamp</code>
</a>
</title>

返回 `kotlin.time.Instant` 类型的当前日期和时间。
</def>
<def id="CurrentTimestampWithTimeZoneKotlinDatetime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/-current-timestamp-with-time-zone/index.html">
<code>CurrentTimestampWithTimeZone</code>
</a>
</title>

返回 `java.time.OffsetDateTime` 类型的当前日期和时间（含时区信息）。
</def>
</deflist>
</tab>

<tab title="exposed-java-time" group-key="exposed-java-time">
<deflist type="medium">
<def id="CurrentDateJavaTime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/-current-date/index.html">
<code>CurrentDate</code>
</a>
</title>

返回 `java.time.LocalDate` 类型的当前日期。
</def>
<def id="CurrentDateTimeJavaTime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/-current-date-time/index.html">
<code>CurrentDateTime</code>
</a>
</title>

返回 `java.time.LocalDateTime` 类型的当前日期和时间。
</def>
<def id="CurrentTimestampJavaTime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/-current-timestamp/index.html">
<code>CurrentTimestamp</code>
</a>
</title>

返回 `java.time.Instant` 类型的当前日期和时间。
</def>
<def id="CurrentTimestampWithTimeZoneJavaTime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-java-time/org.jetbrains.exposed.v1.javatime/-current-timestamp-with-time-zone/index.html">
<code>CurrentTimestampWithTimeZone</code>
</a>
</title>

返回 `java.time.OffsetDateTime` 类型的当前日期和时间（含时区信息）。
</def>
</deflist>
</tab>

<tab title="exposed-jodatime" group-key="exposed-jodatime">
<deflist type="medium">
<def id="CurrentDateJodaTime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-jodatime/org.jetbrains.exposed.v1.jodatime/-current-date/index.html">
<code>CurrentDate</code>
</a>
</title>

返回 `org.joda.time.DateTime` 类型的当前日期。
</def>
<def id="CurrentDateTimeJodaTime">
<title>
<a href="https://jetbrains.github.io/Exposed/api/exposed-jodatime/org.jetbrains.exposed.v1.jodatime/-current-date-time/index.html">
<code>CurrentDateTime</code>
</a>
</title>

返回 `org.joda.time.DateTime` 类型的当前日期和时间。
</def>
</deflist>
</tab>
</tabs>

例如，可以在定义表列时将这些表达式用作默认表达式：

<tabs group="date-time-module">
<tab title="exposed-kotlin-datetime" group-key="exposed-kotlin-datetime">

```kotlin
import org.jetbrains.exposed.v1.datetime.CurrentDate

object Events : Table() {
    val startDate = date("start_date")
        .defaultExpression(CurrentDate)
}
```
</tab>
<tab title="exposed-java-time" group-key="exposed-java-time">

```kotlin
import org.jetbrains.exposed.v1.javatime.CurrentDate

object Events : Table() {
    val startDate = date("start_date")
        .defaultExpression(CurrentDate)
}
```
</tab>
<tab title="exposed-jodatime" group-key="exposed-jodatime">

```kotlin
import org.jetbrains.exposed.v1.jodatime.CurrentDate

object Events : Table() {
    val startDate = date("start_date")
        .defaultExpression(CurrentDate)
}
```
</tab>
</tabs>

对象 `CurrentDate` 将 SQL 函数 `CURRENT_DATE` 定义为创建表时的列默认值。具体使用的日期
函数可能会因数据库方言而异。

数据库会在执行 SQL 语句时计算这些表达式。因此，返回值反映的是
数据库服务器的当前日期和时间。
