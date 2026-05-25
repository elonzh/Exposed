# Exposed DAO API 入门

<show-structure for="chapter,procedure" depth="2"/>
<tldr>
    <var name="example_name" value="get-started-with-exposed-dao"/>
    <include from="lib.topic" element-id="code_example"/>
</tldr>

<web-summary>
    在本教程中，你将学习如何使用 Exposed 的 DAO API 在 Kotlin 中创建和查询表。
</web-summary>
<link-summary>
    学习如何使用 Exposed 的 DAO API 在 Kotlin 中创建和查询表。
</link-summary>

在本教程中，你将学习如何使用 Exposed 的数据访问对象（DAO）API 通过构建一个简单的控制台应用程序来在关系数据库中存储和检索数据。

在本教程结束时，你将能够执行以下操作：

- 使用内存数据库配置数据库连接。
- 定义数据库表和相应的 DAO 实体。
- 使用面向对象风格执行基本的 CRUD（创建、读取、更新和删除）操作。

<include from="Get-Started-with-Exposed.topic" element-id="prerequisites"/>
<var name="project_name" value="exposed-dao-kotlin-app"/>
<include from="Get-Started-with-Exposed.topic" element-id="create-new-project"/>

## 添加依赖


<procedure>
在开始使用 Exposed 之前，你需要向项目添加依赖。
<step>

导航到 **gradle/libs.versions.toml** 文件并定义 Exposed 和 H2 版本及构件：

```kotlin
[versions]
//...
exposed = "%exposed_version%"
h2 = "%h2_db_version%"

[libraries]
//...
exposed-core = { module = "org.jetbrains.exposed:exposed-core", version.ref = "exposed" }
exposed-dao = { module = "org.jetbrains.exposed:exposed-dao", version.ref = "exposed" }
exposed-jdbc = { module = "org.jetbrains.exposed:exposed-jdbc", version.ref = "exposed" }
h2 = { module = "com.h2database:h2", version.ref = "h2" }
```

- `exposed-core` 模块提供了以类型安全方式与数据库交互所需的基础组件和抽象，包括 DSL API。
- `exposed-dao` 模块允许你使用数据访问对象（DAO）API。
- `exposed-jdbc` 模块是 <code>exposed-core</code> 模块的扩展，添加了对 Java 数据库连接（JDBC）的支持。

</step>
<step>

导航到 **app/build.gradle.kts** 文件并将 Exposed 和 H2 数据库模块添加到 `dependencies` 块中：

```kotlin
dependencies {
    //...
    implementation(libs.exposed.core)
    implementation(libs.exposed.dao)
    implementation(libs.exposed.jdbc)
    implementation(libs.h2)
    //...
}
```
</step>
<step>
    <include from="lib.topic" element-id="intellij_idea_load_gradle_changes"/>
</step>
</procedure>

## 配置数据库连接

每次使用 Exposed 访问数据库时，你都需要先获取连接并创建事务。要配置数据库连接，请使用 `Database.connect()` 函数。

<include from="Get-Started-with-Exposed.topic" element-id="config-db-connection-procedure"/>

至此，你已将 Exposed 添加到 Kotlin 项目并配置了数据库连接。现在你可以定义数据模型并使用 Exposed 的 DAO API 与数据库进行交互了。

## 定义表对象

Exposed 的 DAO API 提供了基础 `IdTable` 类及其子类，用于定义使用标准 `id` 列作为主键的表。
要定义表对象，请按照以下步骤操作。

<procedure id="define-table-object-procedure">
<step>

在 **app/src/main/kotlin/org/example/** 文件夹中，创建一个新的 **Task.kt** 文件。

</step>
<step>

打开 **Task.kt** 并添加以下表定义：

```kotlin
```
{src="get-started-with-exposed-dao/src/main/kotlin/org/example/Task.kt" include-lines="1-2,5,8,10-14"}

在 `IntIdTable` 构造函数中，传递名称 `tasks` 为表配置自定义名称。如果不提供名称，Exposed 将从对象名称派生，这可能会根据命名约定导致意外结果。

`Tasks` 对象定义了以下列：

- `title` 和 `description` 是 `String` 列，使用 `varchar()` 函数创建。每列最大长度为 128 个字符。
- `isCompleted` 是 `Boolean` 列，使用 `bool()` 函数定义。使用 `default(false)` 调用，将默认值配置为 `false`。

`IntIdTable` 类自动添加一个自增整数 `id` 列作为表的主键。至此，你已定义了一个包含列的表，这本质上创建了 `tasks` 表的蓝图。

</step>
</procedure>

## 定义实体

使用 DAO 方法时，使用 `IntIdTable` 定义的每个表都必须与相应的[实体类](DAO-Entity-definition.topic)关联。实体类表示表中的单个记录，由主键唯一标识。

要定义实体，请使用以下代码更新你的 **Task.kt** 文件：

```kotlin
```
{src="get-started-with-exposed-dao/src/main/kotlin/org/example/Task.kt" include-lines="3-4,6-8,15-28"}

- `Task` 继承 `IntEntity`，这是具有 `Int` 主键的实体的基类。
- `EntityID<Int>` 参数表示此实体映射到的数据库行的主键。
- `companion object` 继承 `IntEntityClass<Task>`，将实体类链接到 `Tasks` 表。
- 每个属性（`title`、`description` 和 `isCompleted`）使用 Kotlin 的 `by` 关键字委托给 `Tasks` 表中的相应列。
- `toString()` 函数自定义 `Task` 实例的字符串表示形式。这对于调试或日志记录特别有用。打印时，输出将包含实体的 ID、标题和完成状态。

## 创建和查询表

使用 Exposed 的 DAO API，你可以使用类似于处理常规 Kotlin 类的类型安全、面向对象语法与数据库交互。执行任何数据库操作时，必须在<emphasis>事务</emphasis>中运行它们。

<include from="Get-Started-with-Exposed.topic" element-id="transaction-definition"/>

打开你的 **App.kt** 文件并添加以下事务函数：

```kotlin
```
{src="get-started-with-exposed-dao/src/main/kotlin/org/example/App.kt" include-lines="1-2,4-11,16-33,42-43"}

首先，使用 `SchemaUtils.create()` 方法创建 tasks 表。`SchemaUtils` 对象包含用于创建、修改和删除数据库对象的实用方法。

表创建后，使用 `IntEntityClass` 扩展方法 `.new()` 添加两条新的 `Task` 记录：

```kotlin
```
{src="get-started-with-exposed-dao/src/main/kotlin/org/example/App.kt" include-symbol="task1,task2"}

在此示例中，`task1` 和 `task2` 是 `Task` 实例，每个代表 `Tasks` 表中的新行。在 `new` 块中，你设置每列的值。Exposed 将函数转换为以下 SQL 查询：

```sql
INSERT INTO TASKS ("name", DESCRIPTION, COMPLETED) VALUES ('Learn Exposed DAO', 'Follow the DAO tutorial', FALSE)
INSERT INTO TASKS ("name", DESCRIPTION, COMPLETED) VALUES ('Read The Hobbit', 'Read chapter one', TRUE)
```

使用 `.find()` 方法执行过滤查询，检索所有 `isCompleted` 为 `true` 的任务：

```kotlin
```
{src="get-started-with-exposed-dao/src/main/kotlin/org/example/App.kt" include-symbol="completed"}

在测试代码之前，能够检查 Exposed 发送到数据库的 SQL 语句和查询会很方便。为此，你需要添加日志记录器。

## 启用日志记录

在 `transaction` 块的开头，添加以下内容以启用 SQL 查询日志记录：

```kotlin
```
{src="get-started-with-exposed-dao/src/main/kotlin/org/example/App.kt" include-lines="3,7-8,11-14,42-43"}

## 运行应用程序

<include from="lib.topic" element-id="intellij_idea_start_application"/>

应用程序将在 IDE 底部的 **Run** 工具窗口中启动。你将能够看到 SQL 日志以及打印的结果：

```generic
SQL: SELECT SETTING_VALUE FROM INFORMATION_SCHEMA.SETTINGS WHERE SETTING_NAME = 'MODE'
SQL: CREATE TABLE IF NOT EXISTS TASKS (ID INT AUTO_INCREMENT PRIMARY KEY, "name" VARCHAR(128) NOT NULL, DESCRIPTION VARCHAR(128) NOT NULL, COMPLETED BOOLEAN DEFAULT FALSE NOT NULL)
SQL: INSERT INTO TASKS ("name", DESCRIPTION, COMPLETED) VALUES ('Learn Exposed DAO', 'Follow the DAO tutorial', FALSE)
SQL: INSERT INTO TASKS ("name", DESCRIPTION, COMPLETED) VALUES ('Read The Hobbit', 'Read chapter one', TRUE)
Created new tasks with ids 1 and 2
SQL: SELECT TASKS.ID, TASKS."name", TASKS.DESCRIPTION, TASKS.COMPLETED FROM TASKS WHERE TASKS.COMPLETED = TRUE
Completed tasks: 1
```

## 更新和删除任务

让我们通过更新和删除任务来扩展应用程序的功能。

<procedure>
<step>

在同一个 `transaction()` 函数中，向你的实现添加以下代码：

```kotlin
```
{src="get-started-with-exposed-dao/src/main/kotlin/org/example/App.kt" include-lines="11,13-15,34-42"}

你可以像更新 Kotlin 类中的任何属性一样更新属性值：

```kotlin
```
{src="get-started-with-exposed-dao/src/main/kotlin/org/example/App.kt" include-lines="35-36"}

同样，要删除任务，你在实体上使用 `.delete()` 方法：

```kotlin
```
{src="get-started-with-exposed-dao/src/main/kotlin/org/example/App.kt" include-lines="40"}

</step>
<step>
<include from="lib.topic" element-id="intellij_idea_restart_application"/>

你现在应该看到以下结果：

```generic
SQL: SELECT SETTING_VALUE FROM INFORMATION_SCHEMA.SETTINGS WHERE SETTING_NAME = 'MODE'
SQL: CREATE TABLE IF NOT EXISTS TASKS (ID INT AUTO_INCREMENT PRIMARY KEY, "name" VARCHAR(128) NOT NULL, DESCRIPTION VARCHAR(128) NOT NULL, COMPLETED BOOLEAN DEFAULT FALSE NOT NULL)
SQL: INSERT INTO TASKS ("name", DESCRIPTION, COMPLETED) VALUES ('Learn Exposed DAO', 'Follow the DAO tutorial', FALSE)
SQL: INSERT INTO TASKS ("name", DESCRIPTION, COMPLETED) VALUES ('Read The Hobbit', 'Read chapter one', TRUE)
Created new tasks with ids 1 and 2
SQL: SELECT TASKS.ID, TASKS."name", TASKS.DESCRIPTION, TASKS.COMPLETED FROM TASKS WHERE TASKS.COMPLETED = TRUE
Completed tasks: 1
Updated task1: Task(id=1, title=Try Exposed DAO, completed=true)
SQL: UPDATE TASKS SET COMPLETED=TRUE, "name"='Try Exposed DAO' WHERE ID = 1
SQL: DELETE FROM TASKS WHERE TASKS.ID = 2
SQL: SELECT TASKS.ID, TASKS."name", TASKS.DESCRIPTION, TASKS.COMPLETED FROM TASKS
Remaining tasks: [Task(id=1, title=Try Exposed DAO, completed=true)]
```

> 当你修改实体属性（如 `task1.title` 或 `task1.isCompleted`）时，Exposed 不会立即发出 `UPDATE` 语句。相反，它会将这些更改缓存在内存中，并在下一次读取操作之前或事务结束时将其刷新到数据库：
>
> ```generic
> SQL: UPDATE TASKS SET COMPLETED=TRUE, "name"='Try Exposed DAO' WHERE ID = 1
> ```
> 
{style="note"}

</step>
</procedure>
<include from="Get-Started-with-Exposed.topic" element-id="second-transaction-behaviour-tip"/>

## 后续步骤

干得好！你已使用 Exposed 的 DAO API 构建了一个简单的控制台应用程序，在内存数据库中创建、查询和操作任务数据。

既然你已经掌握了基础知识，现在可以深入了解 DAO API 提供的功能了。继续探索 [CRUD 操作](DAO-CRUD-Operations.topic)或学习如何[定义实体之间的关系](DAO-Relationships.topic)。
这些后续章节将帮助你使用 Exposed 的类型安全、面向对象方法构建更复杂的现实世界数据模型。
