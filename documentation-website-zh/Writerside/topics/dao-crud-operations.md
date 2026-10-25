<show-structure for="chapter,procedure" depth="2"/>

# CRUD 操作 {#crud-operations}

<link-summary>了解如何使用 Exposed 的 DAO（数据访问对象）API 执行 SQL CRUD 操作。</link-summary>

<tldr>

**必需的依赖**：`org.jetbrains.exposed:exposed-dao` (JDBC) 或 `org.jetbrains.exposed:exposed-dao-r2dbc` (R2DBC)

<include from="lib.topic" element-id="jdbc-supported"/>
<include from="lib.topic" element-id="r2dbc-limited-support"/>

**代码示例**：[`exposed-dao`](https://github.com/JetBrains/Exposed/tree/main/documentation-website/Writerside/snippets/exposed-dao/)、
[`exposed-dao-r2dbc`](https://github.com/JetBrains/Exposed/tree/main/documentation-website/Writerside/snippets/exposed-dao-r2dbc/)

</tldr>

CRUD（创建、读取、更新、删除）是任何数据库都支持的四种基本操作。本节演示如何使用 Exposed 的 DAO（数据访问对象）API 执行 SQL CRUD 操作。

这些操作可以直接通过与表关联的
[`EntityClass`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/index.html)
的方法和属性来执行。有关更多信息，请参见[实体定义](dao-entity-definition.md)。

<include from="lib.topic" element-id="r2dbc-dao-experimental-note" />

## 创建 {#create}

### 创建并安排插入 {id="new"}

<tldr>

**JDBC**: [`.new()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/new.html)

**R2DBC**: [`.new()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/new.html)

</tldr>

要创建新的表行，请在与表关联的实体类上使用 `.new()` 函数：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/CreateExamples.kt" include-symbol="movie"}

在上面的示例中，`movie` 是与 `StarWarsFilmsTable` 表中新行关联的[实体实例](dao-entity-definition.md)。

`.new()` 函数会在事务缓存中将实体安排为待插入。当您显式调用 `flushCache()` 函数、在同一事务中执行另一条语句或提交事务时，插入操作会被刷新到数据库。

* 使用 JDBC 时，实体的 ID 和所有由数据库生成的列看似立即可用，但访问这些值会触发待处理的 `INSERT` 刷新，以获取生成的值。
* 使用 R2DBC 时，无法访问任何由数据库生成的列。在插入操作刷新之前尝试访问 `movie.id.value` 会抛出错误。

### 创建并自动插入 {#create-and-insert-automatically}

<primary-label ref="r2dbc" />

使用 R2DBC 时，如果需要在函数返回之前刷新插入操作，可以使用
[`.newSuspend()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/newSuspend.html) 函数：

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/examples/CreateExamples.kt" include-symbol="movie"}

`.newSuspend()` 函数会挂起，并在返回之前刷新 `INSERT`。因此，生成的 ID 和其他由数据库生成的值会立即可用。

由于 `.newSuspend()` 函数会挂起，其初始化代码块也会挂起，因此您可以在其中调用其他 DAO 操作。

如果可以延迟插入，包括希望创建多个实体并一起刷新它们的插入操作的情况，请改用 [`.new()`](#new) 函数。

### 使用指定 ID 创建 {#create-with-an-id}

要为新实体手动提供 `id` 值，请将该值作为实参传递给 `id` 参数：

<tabs group="connectivity">
<tab id="jdbc-new-with-id" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/CreateExamples.kt" include-symbol="movie2"}

</tab>
<tab id="r2dbc-new-with-id" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/examples/CreateExamples.kt" include-symbol="movie2"}

</tab>
</tabs>

如果实体是 `CompositeEntity`，可以使用
[`CompositeID`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core.dao.id/-composite-i-d/index.html)
类创建组成列与值之间的关联，以此构造 ID 值：

<tabs group="connectivity">
<tab id="jdbc-new-with-composite-id" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/CreateExamples.kt" include-symbol="directorId, director"}

</tab>
<tab id="r2dbc-new-with-composite-id" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/examples/CreateExamples.kt" include-symbol="directorId, director"}

</tab>
</tabs>

如果 `CompositeID` 包含自增或自动生成的列，则不需要在构建 `CompositeID` 的代码块中提供这些列的值。在这种情况下，它们由数据库生成。

### 批量插入 {id="batch-inserts"}

由于 `.new()` 函数会延迟插入，您可以创建多个实体并一起刷新它们。同一张表的待处理插入操作会作为一个批次发送：

<tabs group="connectivity">
<tab id="jdbc-batch-insert" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/CreateExamples.kt" include-symbol="batchInsert"}

</tab>
<tab id="r2dbc-batch-insert" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/examples/CreateExamples.kt" include-symbol="batchInsert"}

</tab>
</tabs>

`flushCache()` 函数用于显式控制何时将待处理的插入操作发送到数据库。在事务中执行另一条语句之前以及提交事务时，也会刷新待处理的插入操作。

要使插入操作保持在同一批次中，请避免在创建这些实体的过程中执行其他数据库语句。
再次调用 `.new()` 函数会将插入操作加入待处理的批次，而 `.newSuspend()` 会在返回之前刷新待处理的插入操作，因此会开始一个新批次。

> 丢弃实体不会取消已安排的插入操作。要在插入操作刷新之前移除实体，请使用 `Entity.delete()` 函数。这会移除已安排的插入操作，而不会执行数据库语句。
>
{style="note"}

## 读取 {#read}

要读取属性的值，只需像访问 Kotlin 类中的任何属性一样访问它：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="movieName"}

> 实体的 `id` 属性被包装为 `EntityID` 类的实例。要访问实际被包装的值，例如 `StarWarsFilm` 实体中存储的 `Int`，请使用 `EntityID.value`：
>
> ```kotlin
> ```
> {src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="movieId"}
>
{style="note"}

> 使用 R2DBC 的 `.new()` 函数在缓存中创建新实体时，读取 `id` 等值会抛出异常，因为它还不是数据库中的一行记录。
>
{style="note"}

### 检索全部 {#retrieve-all}

<tldr>

**JDBC**: [`.all()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/all.html)

**R2DBC**: [`.all()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/all.html)

</tldr>

要获取与此实体类关联的所有实体实例，请使用 `.all()` 函数：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="allMovies"}

调用 `.all()` 函数会刷新所有已安排的实体插入和更新操作。

### 按条件查找 {#find-by-condition}

<tldr>

**JDBC**: [`.find()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/find.html)

**R2DBC**: [`.find()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/find.html)

</tldr>

要获取所有符合条件表达式的实体实例，请使用 `.find()` 函数：

<tabs group="connectivity">
<tab id="jdbc-find" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="specificMovie"}

</tab>
<tab id="r2dbc-find" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="specificMovie"}

</tab>
</tabs>


### 按 ID 查找 {#find-by-id}

<tldr>

**JDBC**: [`.findById()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/find-by-id.html)

**R2DBC**: [`.findById()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/find-by-id.html)

</tldr>

要通过 ID 值获取实体，请使用 `.findById()` 函数：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="movie"}

`.findById()` 函数会先在事务的实体缓存中查找匹配的实体。如果未找到，它会查询数据库，并在执行查询之前刷新待处理的插入操作。

如果实体是 `CompositeEntity`，其 `id` 属性可用于引用所有复合列并获取实体，类似于其关联的 `CompositeIdTable` 的 `id` 列：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="directorId, director, directors"}

SQL 查询会产生类似以下的结果：

```sql
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-lines="74-77"}

> 有关可用谓词的列表，请参见 [DSL Where 表达式](DSL-Querying-data.topic#where-expression)。
>
{style="tip"}

### 通过联接读取实体 {#read-an-entity-with-a-join}

<tldr>

**JDBC**: [`.wrapRows()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/wrap-rows.html)

**R2DBC**: [`.wrapRows()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/wrap-rows.html)

</tldr>

要查找所有给第二部《星球大战》电影评分大于 `5` 的用户，请先使用 Exposed DSL 定义查询：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="query"}

要将结果作为 DAO 实体返回，请将查询传递给相应实体类的 `.wrapRows()` 函数：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="users"}

得到的 `users` 集合包含与查询所返回的行对应的 `UserEntity` 实例。

### 对结果排序 {#sort-results}

`.all()` 函数返回与调用它的实体类关联的所有实体实例。JDBC 和 R2DBC 中 `.all()` 的返回类型有所不同：

* 使用 JDBC 时，`.all()` 函数返回一个 [`SizedIterable`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/-sized-iterable/index.html)，
  它实现了 Kotlin 的 `Iterable` 接口，因此您可以直接调用 [Kotlin 标准库](https://kotlinlang.org/api/core/kotlin-stdlib/)中的任何排序方法。
* 使用 R2DBC 时，`.all()` 函数返回一个 [`SizedIterable`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc/-sized-iterable/index.html)，
  它扩展了 `kotlinx.coroutines.flow.Flow`，因此您需要先将结果收集到集合中，再使用排序操作符。

#### 升序 {#ascending-order}

要按升序对结果排序，请使用
[`.sortedBy()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/sorted-by.html) 函数：

<tabs group="connectivity">
<tab id="jdbc-sort-ascending" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="moviesByAscOrder"}

</tab>
<tab id="r2dbc-sort-ascending" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="moviesByAscOrder"}

</tab>
</tabs>

#### 降序 {#descending-order}

要按降序对结果排序，请使用
[`.sortedByDescending()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/sorted-by-descending.html) 函数：

<tabs group="connectivity">
<tab id="jdbc-sort-descending" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="moviesByDescOrder"}

</tab>
<tab id="r2dbc-sort-descending" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="moviesByDescOrder"}

</tab>
</tabs>

## 更新 {#update}

您可以像更新 Kotlin 类中的任何属性一样更新属性的值：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/UpdateExamples.kt" include-lines="16"}

设置新的属性值时，Exposed 会将更改存储在实体的状态中，而不是立即更新数据库。更改会在事务结束时或下一条 `SELECT *` 语句执行之前刷新到数据库。

> 如果更新实体的事务与创建或加载该实体的事务不同，使用 R2DBC 时必须先调用 `attach()`。有关更多信息，请参见 [](#update-later)。
>
{style="note"}

### 按 ID 更新 {#update-by-id}

<tldr>

**JDBC**: [`.findByIdAndUpdate()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/find-by-id-and-update.html)

**R2DBC**: [`.findByIdAndUpdate()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/find-by-id-and-update.html)

</tldr>

要按 ID 查找实体并应用更新，请使用 `.findByIdAndUpdate()` 函数：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/UpdateExamples.kt" include-symbol="updatedMovie"}

### 使用查询更新 {#update-using-a-query}

<tldr>

**JDBC**: [`.findSingleByAndUpdate()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/find-single-by-and-update.html)

**R2DBC**: [`.findSingleByAndUpdate()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/find-single-by-and-update.html)

</tldr>

要通过查询查找单个实体并应用更新，请使用 `.findSingleByAndUpdate()` 函数：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/UpdateExamples.kt" include-symbol="updatedMovie2"}

### 在后续事务中更新实体 {id="update-later"}

<primary-label ref="r2dbc"/>

如果更新实体的事务不是创建或加载该实体的事务，则必须在修改实体之前将其附加到新事务。

使用 JDBC 时，当您首次在新事务中更新实体时，DAO 会自动将实体重新注册到新事务的缓存中。
它会先检查实体是否已被缓存；如果未找到，则查询数据库，以获取最准确的、表示该实体的行数据。

使用 R2DBC 时，属性委托的 setter 无法挂起，因此实体不会被重新注册到新事务的缓存中。
您必须使用 `attach()` 函数手动请求此行为：

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/examples/UpdateExamples.kt" include-lines="35-45"}

如果对应的行已不存在，`attach()` 函数会抛出 `EntityNotFoundException`。

如果事务中已缓存了对应同一行的另一个实体实例，且该实例有尚未刷新的更改，`attach()` 会抛出 `IllegalStateException`。

要明确丢弃现有更改并附加指定的实体，请使用 `attach(movie, force = true)`。

## 删除 {#delete}

<tldr>

**JDBC**: [`.delete()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity/delete.html)

**R2DBC**: [`.delete()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity/delete.html)

</tldr>

要删除记录并从事务缓存中移除对应的实体，请使用 `.delete()` 函数：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/DeleteExamples.kt" include-lines="16"}

## 将查询用作表达式 {#use-queries-as-expressions}

假设您想按每个城市的用户数对城市进行排序。为此，您可以编写一个子查询来统计每个城市的用户数，然后按该计数对结果排序。
但要做到这一点，需要将
[`Query`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/-query/index.html) 转换为
[`Expression`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-expression/index.html)。

这可以使用
[`wrapAsExpression()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/wrap-as-expression.html)
函数来完成：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="expression, cities"}

## 向实体类添加计算字段 {#add-computed-fields-to-entity-class}

<tldr>

**JDBC**: [`searchQuery()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/search-query.html)

**R2DBC**: [`searchQuery()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/search-query.html)

</tldr>

假设您想在每次获取实体时使用窗口函数对电影进行排名。实体类的伴生对象可以重写 `EntityClass` 中的任何开放函数。
但要实现此功能，只需重写 `searchQuery()` 函数。然后便可以通过实体类的属性访问该函数的结果：

<tabs group="connectivity">
<tab id="jdbc-computed-fields" title="JDBC" group-key="jdbc">

<tabs>
<tab id="jdbc-entity-class" title="StarWarsFilmWithRankEntity">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/StarWarsFilmWithRankEntity.kt"}

</tab>
<tab id="jdbc-table-definition" title="StarWarsFilmsWithRankTable">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/tables/StarWarsFilmsWithRankTable.kt"}

</tab>
</tabs>
</tab>
<tab id="r2dbc-computed-fields" title="R2DBC" group-key="r2dbc">

<tabs>
<tab id="r2dbc-entity-class" title="StarWarsFilmWithRankEntity">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/entities/StarWarsFilmWithRankEntity.kt"}

</tab>
<tab id="r2dbc-table-definition" title="StarWarsFilmsWithRankTable">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/tables/StarWarsFilmsWithRankTable.kt"}

</tab>
</tabs>
</tab>
</tabs>


然后，创建和获取实体的方式如下：

<tabs group="connectivity">
<tab id="jdbc-fetch-entity" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="readComputedField"}

</tab>
<tab id="r2dbc-fetch-entity" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/examples/ReadExamples.kt" include-symbol="readComputedField"}

</tab>
</tabs>

## 实体变更时自动填充列 {#auto-fill-columns-on-entity-change}

假设您需要所有表对象至少有两列，用于存储记录创建和修改的日期及时间。
您可以定义一个 `BaseTable`，自动将这些列注册到任何继承此抽象类的表中：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/tables/BaseTable.kt"}

然后可以定义一个抽象的 `BaseEntity`，自动将字段关联到相应的列：

<tabs group="connectivity">
<tab id="jdbc-base-entity" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/BaseEntity.kt"}

</tab>
<tab id="r2dbc-base-entity" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/entities/BaseEntity.kt"}

</tab>
</tabs>

实例化新实体时，`created` 列会被填充为
[`CurrentDateTime`](https://jetbrains.github.io/Exposed/api/exposed-kotlin-datetime/org.jetbrains.exposed.v1.datetime/-current-date-time/index.html)
定义的数据库默认值，而 `modified` 列会被填充为 `null` 值。

要在更新现有实体时自动填充 `modified` 字段，可以为实体订阅实体生命周期拦截器
[`EntityHook`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-hook/index.html)：

<tabs group="connectivity">
<tab id="jdbc-base-entity-class" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/BaseEntityClass.kt"}

</tab>
<tab id="r2dbc-base-entity-class" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/entities/BaseEntityClass.kt"}

</tab>
</tabs>


上面的示例在抽象的 `BaseEntityClass` 中调用 `EntityHook.subscribe()`，该类可用作任何 `BaseEntity` 实现的伴生对象。
也可以在事务级别订阅和取消订阅该拦截器。

订阅仅在记录更新时执行操作（通过 `EntityChangeType.Updated` 检测）。

> 您还可以在实体创建时检测 `EntityChangeType.Created`，在实体移除时检测 `EntityChangeType.Removed`。
>
{style="tip"}

发生更新时，会使用 `nowUTC()` 方法将当前 UTC 时间填充到 `modified` 列。

使用 JDBC 时，可以通过 `Entity.writeValues` 检查 `modified` 字段是否已设置。
它保存实体实例在刷新到数据库之前的列与值的映射。执行此检查可确保填充 `modified` 列不会触发拦截器本身。

使用 R2DBC 时，待处理的更改在实体缓存内部跟踪，不会通过对等的公共 API 暴露。
因此，无法使用 `Entity.writeValues` 对 `modified` 字段执行额外检查。

此外，每次更改（创建、更新或删除）都会使用
[`exposedLogger`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/exposed-logger.html) 记录日志。

> 有关使用语句拦截器的更多详细信息，请参见
> [DSL 语句拦截器](Statement-Interceptors.md)。
>
{style="tip"}
