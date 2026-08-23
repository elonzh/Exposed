[//]: # (title: JSON 和 JSONB 类型)

<show-structure for="chapter" depth="3" />
<var name="artifact_name" value="exposed-json"/>

<tldr>

**必需依赖**：`org.jetbrains.exposed:exposed-json`

<include from="lib.topic" element-id="jdbc-supported"/>
<include from="lib.topic" element-id="r2dbc-supported"/>
</tldr>

Exposed 可与您选择的 JSON 序列化库协同工作，通过
[`json()`](https://jetbrains.github.io/Exposed/api/exposed-json/org.jetbrains.exposed.v1.json/json.html)
和
[`jsonb()`](https://jetbrains.github.io/Exposed/api/exposed-json/org.jetbrains.exposed.v1.json/jsonb.html)
函数，您可以定义接受泛型序列化器和反序列化器参数的列。

数据库以文本或二进制格式存储 JSON 值，因此 Exposed 为每种格式分别提供了一种类型。

## 添加依赖 {id="add-dependency"}

使用 JSON 和 JSONB 列类型或函数之前，请将 `%artifact_name%` 模块添加到构建文件中：

<include from="lib.topic" element-id="add-dependency"/>

## 基本用法 {id="basic-usage"}

以下示例将 [`kotlinx.serialization`](https://github.com/Kotlin/kotlinx.serialization)
与 `@Serializable` 类配合使用。此 `json()` 重载接受 `Json` 配置，并使用指定类型的 `KSerializer`：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="7-9,21,29-40"}

您也可以直接提供序列化器和反序列化器函数。例如，以下定义将
[Jackson](https://github.com/FasterXML/jackson) 与 `jackson-module-kotlin` 依赖及完整版的
`json()` 配合使用：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="5-6,9,21,43-53"}

### 插入和更新 JSON 数据 {id="insert-update-json"}

以下示例使用 `kotlinx.serialization` 示例中的 `TeamsTable` 定义。

要存储 JSON 值，请将可序列化类的实例赋给该列。Exposed 会使用传给 [`json()`](#json) 的
`jsonConfig` 参数的 `Json` 实例来序列化该值：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="64-68"}

要修改已存储的值，请在 `update()` 语句中将该列赋值为一个新实例：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="69-71"}

读取该列时，Exposed 会将存储的 JSON 反序列化回该类的实例：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="73-77"}

### 存储数组 {id="json-arrays"}

JSON 列也可以存储数组。将相应的 Kotlin 数组类型传给 `json()`，例如使用 `IntArray` 表示
整数数组，或使用 `Array<Project>` 表示对象数组：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-symbol="TeamProjectsTable"}

要向这些列插入值，请使用标准 Kotlin 集合：

<tabs>
<tab title="Exposed">

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="145-151"}

</tab>
<tab title="SQL">

```sql
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="141-142"}

</tab>
</tabs>

## 支持的类型 {id="supported-types"}

`exposed-json` 模块提供以下列类型：

| 列类型               | PostgreSQL | MySQL / MariaDB / H2 | SQLite | SQLServer       | Oracle           |
|---------------------|------------|----------------------|--------|-----------------|------------------|
| [`json()`](#json)   | `JSON`     | `JSON`               | `TEXT` | `NVARCHAR(MAX)` | `VARCHAR2(4000)` |
| [`jsonb()`](#jsonb) | `JSONB`    | `JSON`               | `BLOB` | 不支持             | 不支持              |

确切的 SQL 类型取决于数据库方言。例如，在 MySQL 和 H2 中，`jsonb()` 映射到 `JSON`，而不是
名为 `JSONB` 的类型。

### `json()` {id="json"}

使用 [`json()`](https://jetbrains.github.io/Exposed/api/exposed-json/org.jetbrains.exposed.v1.json/json.html) 定义
以基于文本的表示形式存储 JSON 数据的列。

使用 `kotlinx.serialization` 时，请将 `Json` 实例传给 `jsonConfig` 参数：

```kotlin
val project = json<Project>("project", jsonConfig = format)
```

### `jsonb()` {id="jsonb"}

使用 [`jsonb()`](https://jetbrains.github.io/Exposed/api/exposed-json/org.jetbrains.exposed.v1.json/jsonb.html)
定义用于存储 JSON 数据的列；如果数据库支持，则可以采用二进制表示形式存储。

使用 `kotlinx.serialization` 时，请将 `Json` 实例传给 `jsonConfig` 参数：

```kotlin
val project = jsonb<Project>("project", jsonConfig = Json.Default)
```

#### SQLite 中的 JSONB 支持 {id="sqlite-jsonb"}

SQLite 从 3.45.0.0 版本开始支持以二进制 `JSONB` 格式存储 JSON 数据。Exposed 将 `jsonb()`
列映射到 `BLOB`，并使用 SQLite 的 `JSONB()` 函数包装写入其中的值。

这适用于 DDL 默认子句中的值：

<tabs>
<tab title="Exposed">

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="196-200"}

</tab>
<tab title="SQL">

```sql
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="191-194"}

</tab>
</tabs>

Exposed 也会在 DML 操作中使用 `JSONB()` 包装值：

<tabs>
<tab title="Exposed">

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="161-163"}

</tab>
<tab title="SQL">

```sql
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="157-158"}

</tab>
</tabs>


SQLite 会以二进制 `JSONB` 表示形式存储该值。需要 `JSON` 文本的序列化器无法直接解码
原始存储值。

要使该值能够作为 `JSON` 文本使用，SQLite 提供了 `JSON()` SQL 函数。默认情况下，Exposed 从
SQLite 读取 `jsonb()` 列时会应用此函数。

<tabs>
<tab title="Exposed">

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="172-173"}

</tab>
<tab title="SQL">

```sql
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="169"}

</tab>
</tabs>

要禁用此行为，请在定义列时将 `castToJsonFormat` 参数设置为 `false`：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="202-204"}

对于 SQLite 之外的数据库，Exposed 会忽略 `castToJsonFormat`。要将单个 JSONB 表达式转换为 JSON，
请使用 [`.castToJson()`](#cast-to-json)。

## JSON 函数 {id="json-functions"}

### 提取数据

使用 [`.extract()`](https://jetbrains.github.io/Exposed/api/exposed-json/org.jetbrains.exposed.v1.json/extract.html)
函数可从 JSON 表达式的特定路径中提取值。您可以将结果提取为 JSON，也可以提取为指定类型的标量值。

例如，以下查询会提取项目名称，并选择使用 Kotlin 语言的项目：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="88-94"}

对于使用 `$` 作为 JSON 路径根的数据库，Exposed 会自动将其添加到生成的路径表达式中，因此
传给 `.extract()` 的路径中不要包含 `$`。例如，在 MySQL 中，请传入 `.name` 而不是 `$.name`。

### 检查数据是否存在

要检查 JSON 表达式中是否存在数据，请使用
[`.exists()`](https://jetbrains.github.io/Exposed/api/exposed-json/org.jetbrains.exposed.v1.json/exists.html)
函数：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="98-99"}

一些数据库还支持 JSON 路径中的过滤表达式和可选变量：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="106-114"}

### 检查 JSON 是否包含表达式 {id="check-if-json-contains-an-expression"}

要检查 JSON 表达式是否包含某个值，请使用
[`.contains()`](https://jetbrains.github.io/Exposed/api/exposed-json/org.jetbrains.exposed.v1.json/contains.html)
函数：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="119-120"}

在支持的数据库中，您还可以将检查范围限定到特定的 JSON 路径：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="127-134"}

### 将数据转换为 JSON 类型 {id="cast-to-json"}

使用 [`.castToJson()`](https://jetbrains.github.io/Exposed/api/exposed-json/org.jetbrains.exposed.v1.json/cast-to-json.html)
函数可将其他受支持的类型（例如 JSONB）转换为 JSON：

```kotlin
```
{src="exposed-data-types/src/main/kotlin/org/example/examples/JSONandJSONBExamples.kt" include-lines="178-184"}

如上例所示，在支持的数据库中，您还可以将存储有效 JSON 字符串的文本列转换为
可序列化类。
