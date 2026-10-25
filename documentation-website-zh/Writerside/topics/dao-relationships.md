<show-structure for="chapter" depth="2"/>

# 关系 {#relationships}

<link-summary>了解如何定义和使用数据库表及 DAO 实体之间的关系。</link-summary>

<tldr>

**必需的依赖**：`org.jetbrains.exposed:exposed-dao` (JDBC) 或 `org.jetbrains.exposed:exposed-dao-r2dbc` (R2DBC)

<include from="lib.topic" element-id="jdbc-supported"/>
<include from="lib.topic" element-id="r2dbc-limited-support"/>

**代码示例**：[`exposed-dao-relationships`](https://github.com/JetBrains/Exposed/tree/main/documentation-website/Writerside/snippets/exposed-dao-relationships/)、
[`exposed-dao-r2dbc-relationships`](https://github.com/JetBrains/Exposed/tree/main/documentation-website/Writerside/snippets/exposed-dao-r2dbc-relationships/)

</tldr>

关系定义了数据库模式中实体之间的关联方式，并提供了
查询和操作这些关联的机制。实体之间有四种引用方式：

* [多对一引用](#many-to-one-reference)
* [可选引用](#optional-reference)
* [多对多引用](#many-to-many-reference)
* [父子引用](#parent-child-reference)

<include from="lib.topic" element-id="r2dbc-dao-experimental-note"/>

## 多对一引用 {id="many-to-one-reference"}

<tldr>

**JDBC**: [`referencedOn()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/referenced-on.html)

**R2DBC**: [`referencedOn()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/referenced-on.html)

</tldr>

多对一引用是两个数据库表之间的一种关系，其中一个表
（“子”表）中的多行可以引用另一个表（“父”表）中的同一行。

请看下面的 `UsersTable` 及其对应的实体：

<tabs>
<tab id="users-table" title="UsersTable">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/tables/UsersTable.kt" include-symbol="UsersTable"}

</tab>
<tab id="user-entity" title="UserEntity">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/UserEntity.kt" include-lines="17-20,22"}

</tab>
</tabs>

假设您想添加另一个表 `UserRatingsTable`，用于存储用户对特定
电影的评分。每个评分都关联一个用户，但一个用户可以关联多个评分。这就是
多对一关系。

您可以在子表（`UserRatingsTable`）中使用引用列，
将其链接到父表（`UsersTable`），从而实现这种关系。

要创建引用列，请使用 [`reference()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/reference.html)
函数：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/tables/UserRatingsTable.kt" include-symbol="UserRatingsTable"}

在对应的实体类中，使用 `referencedOn()` 中缀函数注册引用：

<tabs group="connectivity">
<tab group-key="JDBC" id="user-ratings-entity" title="JDBC">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/UserRatingEntity.kt" include-symbol="UserRatingEntity"}

</tab>
<tab group-key="R2DBC" id="user-ratings-entity-jdbc" title="R2DBC">

```kotlin
```
{src="exposed-dao-r2dbc-relationships/src/main/kotlin/org/example/entities/UserRatingEntity.kt" include-symbol="UserRatingEntity"}

</tab>
</tabs>

* 使用 JDBC 时，`referencedOn()` 直接返回被引用的实体，因此属性声明为 `var`。
* 使用 R2DBC 时，`referencedOn()` 返回的是访问器，而非被引用的实体，因此属性声明为 `val`。

### 访问数据 {id="accessing-data"}

要从 `UserRatingEntity` 中获取所引用的电影，请使用与连接类型相应的语法：

<tabs group="connectivity">
<tab group-key="JDBC" id="accessing-data-jdbc" title="JDBC">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/examples/OneToManyExamples.kt" include-symbol="film"}

</tab>
<tab group-key="R2DBC" id="accessing-data-r2dbc" title="R2DBC">

```kotlin
```
{src="exposed-dao-r2dbc-relationships/src/main/kotlin/org/example/examples/OneToManyExamples.kt" include-symbol="film"}

</tab>
</tabs>

* 使用 JDBC 时，属性的 getter 直接返回被引用的电影。
* 使用 R2DBC 时，属性返回一个访问器。调用该访问器即可获取被引用的实体。

### 反向访问 {id="reverse-access"}

<tldr>

**JDBC**: [`referrersOn()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/referrers-on.html)

**R2DBC**: [`referrersOn()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/referrers-on.html)

</tldr>

虽然您可以使用实体类的 `.find()` 函数获取某部电影的所有评分，但更推荐在
表示电影的类上使用 `referrersOn()` 中缀函数：

<tabs group="connectivity">
<tab group-key="JDBC" id="reverse-access-jdbc" title="JDBC">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-lines="19-25,27"}

</tab>
<tab group-key="R2DBC" id="reverse-access-r2dbc" title="R2DBC">

```kotlin
```
{src="exposed-dao-r2dbc-relationships/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-lines="19-25,27"}

</tab>
</tabs>

然后，您就可以在实体对象上访问此字段：

<tabs group="connectivity">
<tab group-key="JDBC" id="reverse-access-field-jdbc" title="JDBC">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/examples/OneToManyExamples.kt" include-symbol="filmRatings"}

</tab>
<tab group-key="R2DBC" id="reverse-access-field-r2dbc" title="R2DBC">

```kotlin
```
{src="exposed-dao-r2dbc-relationships/src/main/kotlin/org/example/examples/OneToManyExamples.kt" include-symbol="filmRatings"}

</tab>
</tabs>

### 反向引用 {id="back-reference"}

<tldr>

**JDBC**: [`backReferencedOn()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/back-referenced-on.html)

**R2DBC**: [`backReferencedOn()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/back-referenced-on.html)

</tldr>

如果每个用户只对一部电影评分，您可以在实体类上使用 `backReferencedOn()` 中缀函数来访问
`UserRatingsTable` 中的数据：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/UserEntity.kt" include-symbol="UserWithSingleRatingEntity"}

然后，您就可以在 `UserWithSingleRatingEntity` 对象上访问此字段：

<tabs group="connectivity">
<tab group-key="JDBC" id="back-ref-jdbc" title="JDBC">

```kotlin
user1.rating
```

</tab>
<tab group-key="R2DBC" id="back-ref-r2dbc" title="R2DBC">

```kotlin
user1.rating()
```

</tab>
</tabs>

## 可选引用 {id="optional-reference"}

<tldr>

**JDBC**: [`optionalReferencedOn()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/optional-referenced-on.html)

**R2DBC**: [`optionalReferencedOn()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/optional-referenced-on.html)

</tldr>

在 Exposed 中，您还可以添加可选引用。

例如，如果您想在表中包含匿名用户的评分，可以将引用字段设置为可选，
方法是在表定义中使用
[`optReference()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/opt-reference.html)
函数：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/tables/UserRatingsTable.kt" include-symbol="UserRatingsWithOptionalUserTable"}

在实体定义中，使用 `optionalReferencedOn` 注册可选引用：

<tabs group="connectivity">
<tab group-key="JDBC" id="optional-ref-jdbc" title="JDBC">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/UserRatingEntity.kt" include-symbol="UserRatingWithOptionalUserEntity"}

</tab>
<tab group-key="R2DBC" id="optional-ref-r2dbc" title="R2DBC">

```kotlin
```
{src="exposed-dao-r2dbc-relationships/src/main/kotlin/org/example/entities/UserRatingEntity.kt" include-symbol="UserRatingWithOptionalUserEntity"}

</tab>
</tabs>

## 有序引用 {id="ordered-reference"}

<tldr>

**JDBC**: [`orderBy()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-referrers/order-by.html)

**R2DBC**: [`orderBy()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-referrers/order-by.html)

</tldr>

您可以使用 `orderBy()` 函数定义被引用实体的排列顺序：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/UserEntity.kt" include-symbol="UserEntity"}

在更复杂的场景中，您可以指定多个列，并为每一列设置相应的
排序顺序：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/UserEntity.kt" include-lines="23-27,37-41"}

如果不使用[中缀表示法](https://kotlinlang.org/docs/functions.html#infix-notation)，
则在 `referrersOn()` 之后链式调用 `orderBy()` 函数：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/UserEntity.kt" include-lines="23-27,32-35,41"}

## 多对多引用 {id="many-to-many-reference"}

<tldr>

**JDBC**: [`via()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity/via.html)

**R2DBC**: [`via()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao/-entity/via.html)

</tldr>

多对多引用是两个数据库表之间的一种关系，其中一个表中的多条记录
与另一个表中的多条记录相关联。这种关系通过
中间表连接两个表来建模。

请看下面的 `ActorsTable` 表及其对应的实体：

<tabs>
<tab id="actors-table" title="ActorsTable">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/tables/ActorsTable.kt" include-symbol="ActorsTable"}

</tab>
<tab id="actor-entity" title="ActorEntity">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/ActorEntity.kt" include-symbol="ActorEntity"}

</tab>
</tabs>

假设您现在想扩展此表，使其包含对 `StarWarsFilmEntity`
类的引用。为此，您可以创建一个额外的中间表来存储这些引用：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/tables/ActorsTable.kt" include-symbol="StarWarsFilmActorsTable"}

使用 `via()` 函数在 `StarWarsFilmEntity` 中添加对 `ActorEntity` 的引用：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-lines="26"}


最终的 `StarWarsFilmEntity` 如下所示：


```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-symbol="StarWarsFilmEntity"}

## 父子引用 {id="parent-child-reference"}

父子引用与多对多关系非常相似，但中间表中的两个引用
都指向同一个表。

父子关系可以表示层次结构数据，例如一系列电影及其导演。
例如，您可能想跟踪导演如何执导多部星球大战电影，包括续集或
衍生作品。为此，您可以创建一个自引用的中间表，定义
父电影（原作）与子电影（续集或衍生作品）之间的关系：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/tables/StarWarsFilmsTable.kt" include-symbol="StarWarsFilmRelationsTable"}

在此示例中，`parentFilm` 表示原作，而 `childFilm`
表示续集、前传或衍生作品。可以看到，`StarWarsFilmRelationsTable` 中的列
仅指向 `StarWarsFilmsWithDirectorTable`。

接下来，您需要更新实体类，使用 `via()` 函数
添加父电影与子电影之间的关系：

<tabs group="connectivity">
<tab group-key="JDBC" id="parent-child-jdbc" title="JDBC">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-symbol="StarWarsFilmWithParentAndChildEntity"}

</tab>
<tab group-key="R2DBC" id="parent-child-r2dbc" title="R2DBC">

```kotlin
```
{src="exposed-dao-r2dbc-relationships/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-symbol="StarWarsFilmWithParentAndChildEntity"}

</tab>
</tabs>

以下示例展示了如何为 `StarWarsFilmsTable` 创建和查询父子层次结构：

<tabs group="connectivity">
<tab group-key="JDBC" id="parent-child-query-jdbc" title="JDBC">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/examples/ParentChildExamples.kt" include-lines="16-40"}

</tab>
<tab group-key="R2DBC" id="parent-child-query-r2dbc" title="R2DBC">

```kotlin
```
{src="exposed-dao-r2dbc-relationships/src/main/kotlin/org/example/examples/ParentChildExamples.kt" include-lines="17-41"}

</tab>
</tabs>

## 复合主键引用 {id="composite-primary-key-reference"}

在某些数据库模式中，复合主键通过组合
多个列来唯一标识行。下面介绍如何引用复合 ID 表。

假设您有以下 `CompositeIdTable` 及其对应的实体：

<tabs>
<tab id="directors-table" title="DirectorsCompositeIdTable">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/tables/DirectorsTable.kt" include-symbol="DirectorsCompositeIdTable"}

</tab>
<tab id="director-entity" title="DirectorCompositeIDEntity">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/DirectorEntity.kt" include-lines="26-29,31"}

</tab>
</tabs>

您可以重构 `StarWarsFilmsTable` 表，通过添加列来保存
相应的主键值，并创建表级外键约束，从而引用此表：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/tables/StarWarsFilmsTable.kt" include-symbol="StarWarsFilmsWithCompositeRefTable"}

然后，使用 `referencedOn()` 函数将该字段添加到实体中：

<tabs group="connectivity">
<tab group-key="JDBC" id="comp-primary-key-jdbc" title="JDBC">

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-symbol="StarWarsFilmWithCompositeRefEntity"}

</tab>
<tab group-key="R2DBC" id="comp-primary-key-r2dbc" title="R2DBC">

```kotlin
```
{src="exposed-dao-r2dbc-relationships/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-symbol="StarWarsFilmWithCompositeRefEntity"}

</tab>
</tabs>

> 有关创建表外键约束的更多信息，请参阅
> [外键约束](Working-with-Tables.topic#foreign-key)一节。
>
{style="tip"}

使用 JDBC 时，您可以通过属性直接访问被引用的实体。使用 R2DBC 时，引用
属性使用访问器，因此您必须调用该访问器才能获取被引用的实体：

<tabs group="connectivity">
<tab group-key="JDBC" id="access-jdbc-field" title="JDBC">

```kotlin
movie.director
```

</tab>
<tab group-key="R2DBC" id="access-r2dbc-field" title="R2DBC">

```kotlin
movie.director()
```

</tab>
</tabs>

如果您想获取某位导演执导的所有电影，可以在 `DirectorCompositeIDEntity` 类中添加一个 `referrersOn`
字段：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/entities/DirectorEntity.kt" include-symbol="DirectorCompositeIDEntity"}

然后，您就可以在 `DirectorCompositeIDEntity` 对象 `director` 上访问此字段：

<tabs group="connectivity">
<tab group-key="JDBC" id="access-jdbc-field-2" title="JDBC">

```kotlin
director.films
```

</tab>
<tab group-key="R2DBC" id="access-r2dbc-field-2" title="R2DBC">

```kotlin
director.films()
```

</tab>
</tabs>


对于引用其他对象或被其他对象引用的 `CompositeEntity` 对象，也支持使用前面提到的其他[中缀函数](https://kotlinlang.org/docs/functions.html#infix-notation)，
例如 `optionalReferencedOn`、`backReferencedOn` 和 `optionalReferrersOn`，
只需使用
接受 `IdTable` 作为参数的相应重载即可。
这些重载会自动解析与复合主键关联的外键约束。

## 预先加载 {id="eager-loading"}

<tldr>

**JDBC**: [`load()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/load.html)

**R2DBC**: [`load()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/load.html)

</tldr>

Exposed 中的引用采用延迟加载，也就是说，只有在首次使用引用时
才会执行查询来获取引用的数据。如果您事先知道会用到这些引用，
Exposed 可以在执行父查询时预先加载它们。由于可以将引用汇总后
通过一次查询加载，这种方式能够避免经典的“N+1”问题。

要预先加载引用，请使用 `.load()` 函数，并将 DAO 的引用作为
`KProperty` 传入：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/examples/EagerLoadingExamples.kt" include-lines="11"}

这也适用于引用的引用。例如，如果 `UserRatingTable` 有一个 `film`
引用，您可以执行以下操作：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/examples/EagerLoadingExamples.kt" include-lines="14"}

> 预先加载的引用存储在事务缓存中。
> 这意味着它们在其他事务中不可用，
> 因此必须在同一事务中加载和引用。
> 在 `DatabaseConfig` 中启用 `keepLoadedReferencesOutOfTransaction`
> 即可在事务块之外获取被引用的值。
>
{style="note"}

### 加载集合 {id="eager-loading-collections"}

<tldr>

**JDBC**: [`.with()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/with.html)

**R2DBC**: [`.with()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/with.html)

</tldr>

要为 DAO 的 `Collections`（例如 `List`
和 `SizedIterable`）预先加载引用，请使用 `.with()` 函数，并将每个引用作为 `KProperty` 传入：

```kotlin
```
{src="exposed-dao-relationships/src/main/kotlin/org/example/examples/EagerLoadingExamples.kt" include-lines="17"}

`.with()` 会预先加载 `.all()` 返回的 `SizedIterable` 中
所有 `Entity` 实例的引用，并返回该集合。

> `SizedIterable` 执行任何方法都需要事务，因此，加载的
> 集合不能直接在 `transaction` 块之外使用，除非先将其
> 转换为标准集合，例如调用 `.toList()`。
>
{style="note"}

### 加载文本字段 {id="eager-loading-text-fields"}

出于性能和内存方面的考虑，某些数据库驱动程序不会立即加载文本内容。
这意味着您只能在尚未结束的事务中获取列值。

要使内容在事务之外可用，请在字段定义中使用
[`eagerLoading`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-text-column-type/eager-loading.html)
参数：

```kotlin
object StarWarsFilmsTable : Table() {
    //...
    val description = text("name", eagerLoading=true)
}
```
