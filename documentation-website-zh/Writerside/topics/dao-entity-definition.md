<show-structure for="chapter,procedure" depth="2"/>

# 实体定义 {#entity-definition}

<link-summary>了解如何定义 DAO 实体并将其映射到数据库表。</link-summary>

<tldr>

**必需的依赖**：`org.jetbrains.exposed:exposed-dao`（JDBC）或 `org.jetbrains.exposed:exposed-dao-r2dbc`（R2DBC）

<include from="lib.topic" element-id="jdbc-supported"/>
<include from="lib.topic" element-id="r2dbc-limited-support"/>
</tldr>

Exposed 中的 [`Entity`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity/index.html)
将数据库表记录映射到 Kotlin 对象。这确保了类型安全，让您能够像处理普通 Kotlin 对象一样处理数据库记录，
充分利用 Kotlin 的语言特性。

使用数据访问对象（DAO）方式时，`IdTable` 需要与 `Entity` 关联。这是因为
该表中的每条数据库记录都需要映射到一个由主键标识的 `Entity` 实例。

## 定义实体 {#defining-an-entity}

通过创建类来定义实体。

以下面的 `StarWarsFilmsTable` 表为例：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/tables/StarWarsFilmsTable.kt" include-lines="3-6,19-23"}

以下示例展示了与 `StarWarsFilmsTable` 表关联的实体类：

<tabs group="connectivity">
<tab id="StarWarsFilmEntity-jdbc" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt"}

</tab>
<tab id="StarWarsFilmEntity-r2dbc" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt"}

</tab>
</tabs>

> 在 IntelliJ IDEA Ultimate 中，您可以使用 [Exposed 插件](https://plugins.jetbrains.com/plugin/24367-exposed)
> 根据表定义生成实体。有关更多信息，请参阅
> [Exposed 插件文档](https://www.jetbrains.com/help/idea/exposed.html)。
>
{style="note"}

### 实体类型 {#entity-type}

实体类型决定了 `Entity` 类如何与表的主键交互。由于 `StarWarsFilmsTable` 是
`IntIdTable`，`StarWarsFilmsEntity` 类继承自
`IntEntity`，这表示 `StarWarsFilmsTable` 的 ID 和主键类型为 `Int`。

支持以下实体类型：

<tabs group="connectivity">
<tab id="entity-types-jdbc" title="JDBC" group-key="jdbc">

| 实体类型                                                                                                                        | 描述                                                                                                                                                          |
|------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`IntEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-int-entity/index.html)             | 实体实例的基类，其 ID 由包装的 `Int` 值组成。                                                                            |
| [`LongEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-long-entity/index.html)           | 实体实例的基类，其 ID 由包装的 `Long` 值组成。                                                                           |
| [`UIntEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-u-int-entity/index.html)          | 实体实例的基类，其 ID 由包装的 `UInt` 值组成。                                                                           |
| [`ULongEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-u-long-entity/index.html)        | 实体实例的基类，其 ID 由包装的 `ULong` 值组成。                                                                          |
| [`UuidEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-uuid-entity/index.html)           | 实体实例的基类，其 ID 由包装的 `kotlin.uuid.Uuid` 值组成。                                                               |
| [`UUIDEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao.java/-u-u-i-d-entity/index.html)   | 实体实例的基类，其 ID 由包装的 `java.util.UUID` 值组成。可从 `org.jetbrains.exposed.v1.dao.java` 包获取。 |
| [`CompositeEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-composite-entity/index.html) | 实体实例的基类，其 ID 由多个包装值组成。                                                                          |

</tab>
<tab id="entity-types-r2dbc" title="R2DBC" group-key="r2dbc">

| 实体类型                                                                                                                                    | 描述                                                                                                                                                          |
|------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`IntEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-int-entity/index.html)             | 实体实例的基类，其 ID 由包装的 `Int` 值组成。                                                                            |
| [`LongEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-long-entity/index.html)           | 实体实例的基类，其 ID 由包装的 `Long` 值组成。                                                                           |
| [`UIntEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-u-int-entity/index.html)          | 实体实例的基类，其 ID 由包装的 `UInt` 值组成。                                                                           |
| [`ULongEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-u-long-entity/index.html)        | 实体实例的基类，其 ID 由包装的 `ULong` 值组成。                                                                          |
| [`UuidEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-uuid-entity/index.html)           | 实体实例的基类，其 ID 由包装的 `kotlin.uuid.Uuid` 值组成。                                                               |
| [`UUIDEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc.java/-u-u-i-d-entity/index.html)   | 实体实例的基类，其 ID 由包装的 `java.util.UUID` 值组成。可从 `org.jetbrains.exposed.v1.dao.java` 包获取。 |
| [`CompositeEntity`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-composite-entity/index.html) | 实体实例的基类，其 ID 由多个包装值组成。                                                                          |

</tab>
</tabs>

### 实体类 {#entity-class}

<tldr>

**JDBC**: [`EntityClass`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/index.html)

**R2DBC**: [`EntityClass`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/index.html)

</tldr>

`companion object` 块中的 [`EntityClass`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/index.html)
负责管理 `Entity` 实例，例如创建、查询和删除记录。
它还维护实体类（本例中的 `StarWarsFilmEntity`）与数据库表
（`StarWarsFilmsTable`）之间的关系。

每种实体类型都有对应的 `EntityClass`，它接受以下参数：

| 参数    | 描述                                                                                                                                                                                                     |
|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `table`      | 包含映射到实体的行的 `IdTable`，这些实体由此类管理。                                                                                                                                |
| `entityType` | 可选。`Entity` 类的预期类型。如果它就是提供给此 `EntityClass` 实例的类型参数所对应的类，则可以省略。                                                         |
| `entityCtor` | 可选。使用提供的 `EntityID` 实例化 `Entity` 的函数。如果未提供，则在首次访问时通过反射确定主构造函数，这可能会影响性能。 |

在上面的示例中，伴生对象中指定了 `IntEntityClass`：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-lines="9"}

此设置使您能够使用 `IntEntityClass` 提供的函数
有效管理 `StarWarsFilmEntity` 的实例。

### 属性 {#properties}

表中的每一列在实体类中都表示为一个属性，其中 `by` 关键字确保
在访问属性时从相应列获取或更新数据。

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/StarWarsFilmEntity.kt" include-lines="10-13"}

定义实体类后，可以通过该类的实例操作相应表中的单条记录。
例如，[创建新记录](dao-crud-operations.md#create)、
[根据主键检索行](dao-crud-operations.md#read)、[更新值](dao-crud-operations.md#update)
或[删除记录](dao-crud-operations.md#delete)。

## 不可变实体 {#immutable-entities}

<primary-label ref="jdbc"/>

为定义不可变实体，Exposed 还提供了
[`ImmutableEntityClass`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-immutable-entity-class/index.html)
和
[`ImmutableCachedEntityClass`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-immutable-cached-entity-class/index.html)。

`ImmutableCachedEntityClass` 使用内部缓存，按关联的数据库存储实体加载状态。
这确保了实体更新以该类作为锁对象进行同步。

要创建不可变实体，请在实体类中使用 `ImmutableEntityClass` 或 `ImmutableCachedEntityClass`
作为伴生对象。例如，以下是定义 `CityEntity` 类的方式：

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/CityEntity.kt"}

* 使用 `val` 而不是 `var` 定义属性。这确保了不可变性，因为 `val` 属性在初次赋值后
不能重新赋值。
* 在此上下文中，实体类的主要功能是从关联表查询数据，而不是修改数据。
因此，只能使用 DSL [`.insert()`](DSL-CRUD-operations.topic#insert) 方法执行插入，而更新
可以通过 DSL [`.update()`](DSL-CRUD-operations.topic#update) 或
[`ImmutableEntityClass.forceUpdateEntity()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-immutable-entity-class/force-update-entity.html)
方法完成。

## 类方法重写 {#class-method-overrides}

您可以在 `Entity` 类和 `EntityClass` 伴生对象中重写方法，
以扩展功能或管理实体行为。

例如，以下是在 `User` 实体中重写 `.delete()` 方法的方式：

<tabs group="connectivity">
<tab group-key="jdbc" title="JDBC" id="entity-override">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/UserEntityWithOverride.kt"}

</tab>
<tab group-key="r2dbc" title="R2DBC" id="entity-override-r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/entities/UserEntityWithOverride.kt"}

</tab>
</tabs>

在此示例中，父类（`IntEntity`）的 `.delete()` 函数完成删除之前，
会打印一条自定义消息。

## 字段转换 {#field-transformations}

<tldr>

**JDBC**: [`.transform()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/transform.html), [`.memoizedTransform()`](https://jetbrains.github.io/Exposed/api/exposed-dao/org.jetbrains.exposed.v1.dao/-entity-class/memoized-transform.html)

**R2DBC**: [`.transform()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/transform.html), [`.memoizedTransform()`](https://jetbrains.github.io/Exposed/api/exposed-dao-r2dbc/org.jetbrains.exposed.v1.dao.r2dbc/-entity-class/memoized-transform.html)

</tldr>

数据库通常只存储整数和字符串等基本类型，但在 DAO 层面维持同样简单的类型
并不总是方便的。

例如，您可能需要从 `VARCHAR` 列解析 JSON，或根据数据库中的数据从缓存中检索值。
在这些情况下，可以使用列转换。

### 定义无符号整数字段 {#defining-an-unsigned-integer-field}

假设您想在实体上定义一个无符号整数字段，但 Exposed 尚未提供这样的列类型。
您可以使用以下实现来达到目的：

<tabs group="connectivity">
<tab group-key="jdbc" title="JDBC" id="uint-jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/EntityWithUInt.kt"}

</tab>
<tab group-key="r2dbc" title="R2DBC" id="uint-r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/entities/EntityWithUInt.kt"}

</tab>
</tabs>

`.transform()` 函数接受两个 lambda，用于将原始列类型的值转换为目标类型的值，以及进行反向转换。
在此示例中，您确保仅将 `UInt` 实例存储在 `uint` 字段中。

尽管仍然可以通过 DAO 插入或更新负整数值，但这种方式
让业务逻辑更加清晰。

### 记忆化转换 {#memoized-transformations}

如果转换逻辑涉及影响性能的复杂操作，可以使用
`.memoizedTransform()` 函数来缓存转换结果。

<tabs group="connectivity">
<tab id="memoized-transform-jdbc" title="JDBC" group-key="jdbc">

```kotlin
```
{src="exposed-dao/src/main/kotlin/org/example/entities/EntityWithBase64.kt"}

</tab>
<tab id="memoized-transform-r2dbc" title="R2DBC" group-key="r2dbc">

```kotlin
```
{src="exposed-dao-r2dbc/src/main/kotlin/org/example/entities/EntityWithBase64.kt"}

</tab>
</tabs>

使用记忆化转换时，值只解包一次，然后缓存起来供后续读取。此缓存在实体的整个生命周期内
保持有效。如果事务的实体缓存被清除，或者实体在新事务中重新加载
（创建一个不包含现有值的新缓存），则会再次包装该值。但是，如果原始实体在事务外仍然
保持存活，缓存值就会一直保留，以避免重新包装。
