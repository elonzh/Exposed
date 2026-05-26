<show-structure for="chapter,procedure" depth="2"/>

# 迁移

<tldr>
    <p>
        <b>必需依赖</b>: <code>org.jetbrains.exposed:exposed-migration-core</code> 和
        <code>org.jetbrains.exposed:exposed-migration-jdbc</code>（JDBC）或 
        <code>org.jetbrains.exposed:exposed-migration-r2dbc</code>（R2DBC）
    </p>
    <include from="lib.topic" element-id="jdbc-supported"/>
    <include from="lib.topic" element-id="r2dbc-supported"/>
    <p>
        <b>代码示例</b>: <a href="https://github.com/JetBrains/Exposed/tree/main/documentation-website/Writerside/snippets/exposed-migrations">exposed-migrations</a>
    </p>
</tldr>

管理数据库模式变更 是应用程序开发的关键部分。Exposed 支持两种模式迁移方法：

* [Exposed Gradle 插件](Exposed-gradle-plugin.md)通过比较 Exposed 表定义与现有数据库模式来提供更高级别的迁移脚本生成工作流。
* `SchemaUtils` 和 `MigrationUtils` API 提供了较低级别的构建块，用于可在 Kotlin 代码中直接使用的自定义迁移和模式验证工作流。

> 本主题描述了 `SchemaUtils` 和 `MigrationUtils` 提供的迁移 API。
> 
> 有关自动生成迁移脚本的基于 Gradle 的工作流，请参见 [Exposed Gradle 插件](Exposed-gradle-plugin.md)。
> 
{style="tip"}

## 使用迁移 API

虽然 Exposed 通过 `SchemaUtils` 提供基本的迁移支持，但来自 `exposed-migration-jdbc` 或 `exposed-migration-r2dbc` 包的 `MigrationUtils` 方法提供了更结构化且可用于生产的方式来管理模式变更。它们允许你执行以下操作：
* [检查当前数据库状态与定义的表模式之间的差异](#aligning-the-database-schema)。
* [生成 SQL 迁移语句](#generate-all-required-statements)。
* [生成迁移脚本](#generate-a-migration-script)。
* [验证数据库模式状态](#validating-the-database-schema)。

## 添加依赖

要使用 `MigrationUtils` 提供的方法，请在构建脚本中包含以下依赖：

* `exposed-migration-core`，包含数据库模式迁移的核心通用功能。
* 用于 JDBC 或 R2DBC 驱动程序迁移支持的依赖。

<tabs group="connectivity">
   <tab id="jdbc-dependencies" title="JDBC" group-key="jdbc">
     <code-block lang="kotlin">
         implementation("org.jetbrains.exposed:exposed-migration-core:%exposed_version%")
         implementation("org.jetbrains.exposed:exposed-migration-jdbc:%exposed_version%")
     </code-block>
   </tab>
   <tab id="r2dbc-dependencies" title="R2DBC" group-key="r2dbc">
      <code-block lang="kotlin">
         implementation("org.jetbrains.exposed:exposed-migration-core:%exposed_version%")
         implementation("org.jetbrains.exposed:exposed-migration-r2dbc:%exposed_version%")
      </code-block>
    </tab>
</tabs>

<note>
在 1.0.0 版本之前，支持 JDBC 的 <code>MigrationUtils</code> 可通过单个依赖 <code>exposed-migration</code> 构件获得。
</note>

## 对齐数据库模式 {#aligning-the-database-schema}

当你需要使数据库模式与当前 Exposed 表定义保持一致时，有三个选项：

1. [仅生成缺失的列语句](#generate-missing-column-statements){summary="使用此方法可精确控制要对齐模式的哪个部分"}
2. [生成数据库迁移所需的所有语句](#generate-all-required-statements){summary="将此方法用作实际迁移前的验证检查"}
3. [生成迁移脚本](#generate-a-migration-script){summary="使用此方法可采用更自动化的方式，同时允许你在集成自己的迁移之前控制脚本内容"}

### 生成缺失的列语句 {#generate-missing-column-statements}

<tldr>
    <p>API 参考：
        <a href="https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/-schema-utils/add-missing-columns-statements.html">
            <code>addMissingColumnsStatements</code>（JDBC）
        </a>、
        <a href="https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc/-schema-utils/add-missing-columns-statements.html">
            <code>addMissingColumnsStatements</code>（R2DBC）
        </a>
    </p>
</tldr>

如果你只需要创建数据库中现有表缺失列的 SQL 语句，请使用 `SchemaUtils.addMissingColumnsStatements()` 函数：

```Kotlin
```
{src="exposed-migrations/src/main/kotlin/org/example/App.kt" include-symbol="missingColStatements"}

此函数返回字符串 SQL 语句集合，确保任何列关联的约束都得到对齐。在添加缺失列的同时，它会同步添加任何可能缺失的关联约束，如主键、索引和外键。

> 有关数据库特定约束，请参见[限制](#limitations)部分。

### 生成所有必需的语句 {#generate-all-required-statements}

<tldr>
    <p>API 参考：
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-jdbc/org.jetbrains.exposed.v1.migration.jdbc/-migration-utils/statements-required-for-database-migration.html">
            <code>statementsRequiredForDatabaseMigration</code>（JDBC）
        </a>、
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-r2dbc/org.jetbrains.exposed.v1.migration.r2dbc/-migration-utils/statements-required-for-database-migration.html">
            <code>statementsRequiredForDatabaseMigration</code>（R2DBC）
        </a>
    </p>
</tldr>

要将实际数据库模式与当前 Exposed 表定义进行比较并生成对齐两者所需的所有语句，请使用 `MigrationUtils.statementsRequiredForDatabaseMigration()` 函数：

```Kotlin
```
{src="exposed-migrations/src/main/kotlin/org/example/App.kt" include-symbol="statements"}

返回的字符串 SQL 语句集合可能包括 `CREATE`、`ALTER` 和 `DROP` 操作——包括可能具有破坏性的操作（如 `DROP COLUMN` 或 `DELETE`），因此在选择执行之前请仔细审查。

> 有关数据库特定约束，请参见[限制](#limitations)部分。

### 生成迁移脚本 {#generate-a-migration-script}

<tldr>
    <p>API 参考：
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-jdbc/org.jetbrains.exposed.v1.migration.jdbc/-migration-utils/generate-migration-script.html">
            <code>generateMigrationScript</code>（JDBC）
        </a>、
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-r2dbc/org.jetbrains.exposed.v1.migration.r2dbc/-migration-utils/generate-migration-script.html">
            <code>generateMigrationScript</code>（R2DBC）
        </a>
    </p>
</tldr>

要基于数据库与当前 Exposed 模型之间的模式差异生成迁移脚本，请使用 `MigrationUtils.generateMigrationScript()` 函数：

```Kotlin
```
{src="exposed-migrations/src/main/kotlin/org/example/GenerateMigrationScript.kt" include-lines="36-40"}

此方法允许你在应用迁移之前查看迁移脚本的内容。如果同名的迁移脚本已存在，其内容将被覆盖。

### 重置元数据缓存

<tldr>
    <p>API 参考：
        <a href="https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.vendors/-database-dialect-metadata/reset-caches.html">
            <code>resetCaches</code>（JDBC）
        </a>、
        <a href="https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.vendors/-database-dialect-metadata/reset-caches.html">
            <code>resetCaches</code>（R2DBC）
        </a>
    </p>
</tldr>

一些模式对齐方法依赖于数据库元数据查询，这些查询可能会针对所有要迁移的表多次运行。Exposed 内部使用多个元数据缓存来避免这些不必要的冗余查询调用。为确保准确的元数据检索，每当调用改变模式的方法（如 `SchemaUtils.create()`、`SchemaUtils.drop()` 或 `SchemaUtils.setSchema()`）时，这些缓存会自动清除和重置。缓存也会在事务块终止时重置。

仅生成对齐模式所需的 SQL 语句不会触发缓存重置。这意味着如果你手动执行 SQL 语句，然后尝试在同一事务中执行模式验证方法等操作，结果可能因缓存过时而不准确。建议将执行改变模式的 SQL 语句与后续可能使用元数据缓存的方法放在不同的事务块中。否则，应立即手动调用 `.resetCaches()` 以确保稍后检索到更新的数据库元数据：

```Kotlin
transaction(db) {
    println(UsersTable.exists()) // true

    val statements: List<String> = UsersTable.dropStatement()
    execInBatch(statements)
    db.dialectMetadata.resetCaches()

    println(UsersTable.exists()) // false
}
```

在上面的示例中，如果使用 `SchemaUtils.drop(UsersTable)`，则无需调用 `.resetCaches()`。

## 验证数据库模式 {#validating-the-database-schema}

在应用任何迁移之前，验证 Exposed 模式定义与数据库的实际状态是否匹配非常有用。虽然模式对齐方法的主要用途是生成 SQL 语句和迁移脚本，但这些方法也可以用作预检查——特别是在用于检测意外变更时。

Exposed 提供了多个支持模式验证的底层 API，可集成到自定义迁移或部署流水线中。这些方法也被 Exposed 内部用于生成迁移语句，但你也可以将它们用于更精确的检查。

### 检查数据库对象是否存在

<tldr>
    <p>API 参考：
        <a href="https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/exists.html">
            <code>exists</code>（JDBC）
        </a>
        <a href="https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc/exists.html">
            <code>exists</code>（R2DBC）
        </a>
    </p>
</tldr>

要确定特定数据库对象是否已存在，请在 `Table`、`Sequence` 或 `Schema` 上使用 `.exists()` 方法。

### 结构完整性检查

要评估表是否有过多的索引或外键（这可能表示模式漂移或重复），请使用以下 `SchemaUtils` 方法之一：

- `SchemaUtils.checkExcessiveIndices()`（[JDBC](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/-schema-utils/check-excessive-indices.html)、[R2DBC](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc/-schema-utils/check-excessive-indices.html)）
- `SchemaUtils.checkExcessiveForeignKeyConstraints()`（[JDBC](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/-schema-utils/check-excessive-foreign-key-constraints.html)、[R2DBC](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc/-schema-utils/check-excessive-foreign-key-constraints.html)）

### 数据库元数据检查

要从当前方言检索元数据以与定义的 Exposed 模式进行比较，请使用以下 `currentDialectMetadata` 方法之一：

- `currentDialectMetadata.tableColumns()`（[JDBC](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.vendors/-database-dialect-metadata/table-columns.html)、[R2DBC](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.vendors/-database-dialect-metadata/table-columns.html)）
- `currentDialectMetadata.existingIndices()`（[JDBC](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.vendors/-database-dialect-metadata/existing-indices.html)、[R2DBC](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.vendors/-database-dialect-metadata/existing-indices.html)）
- `currentDialectMetadata.existingPrimaryKeys()`（[JDBC](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc.vendors/-database-dialect-metadata/existing-primary-keys.html)、[R2DBC](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.vendors/-database-dialect-metadata/existing-primary-keys.html)）

## 旧列清理

<tldr>
    <p>API 参考：
        <code>dropUnmappedColumnsStatements</code>（
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-jdbc/org.jetbrains.exposed.v1.migration.jdbc/-migration-utils/drop-unmapped-columns-statements.html">
             JDBC
        </a>、
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-r2dbc/org.jetbrains.exposed.v1.migration.r2dbc/-migration-utils/drop-unmapped-columns-statements.html">
            R2DBC
        </a>）、
        <code>dropUnmappedIndices</code>（
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-jdbc/org.jetbrains.exposed.v1.migration.jdbc/-migration-utils/drop-unmapped-indices.html">
             JDBC
        </a>、
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-r2dbc/org.jetbrains.exposed.v1.migration.r2dbc/-migration-utils/drop-unmapped-indices.html">
            R2DBC
        </a>）、
        <code>dropUnmappedSequences</code>（
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-jdbc/org.jetbrains.exposed.v1.migration.jdbc/-migration-utils/drop-unmapped-sequences.html">
             JDBC
        </a>、
        <a href="https://jetbrains.github.io/Exposed/api/exposed-migration-r2dbc/org.jetbrains.exposed.v1.migration.r2dbc/-migration-utils/drop-unmapped-sequences.html">
            R2DBC
        </a>）
    </p>
</tldr>

随着模式的发展，在表定义中删除或重命名列是很常见的。但是，除非显式删除，旧列可能仍然存在于数据库中。

`MigrationUtils.dropUnmappedColumnsStatements()` 函数帮助识别当前表定义中不再存在的列，并返回删除它们的 SQL 语句：

```Kotlin
```
{src="exposed-migrations/src/main/kotlin/org/example/App.kt" include-symbol="dropStatements"}

对于索引和序列，你可以使用 `MigrationUtils.dropUnmappedIndices()` 和 `MigrationUtils.dropUnmappedSequences()` 方法。

## 日志记录

默认情况下，`MigrationUtils` 提供的每个方法都会记录每个中间步骤的描述和执行时间。这些日志以 `INFO` 级别发出，可以通过将 `withLogs` 设置为 `false` 来禁用：

```Kotlin
```
{src="exposed-migrations/src/main/kotlin/org/example/App.kt" include-lines="57-60"}

## 限制 {#limitations}

虽然 Exposed 的迁移工具很强大，但存在一些限制：

* Exposed 不会自动将生成的迁移脚本应用到目标数据库。你必须将迁移执行集成到现有工作流中，如 Flyway、Liquibase 或手动执行。
> 有关使用 Flyway 手动执行的示例，请参见 [`exposed-migrations` 示例项目](https://github.com/JetBrains/Exposed/tree/main/documentation-website/Writerside/snippets/exposed-migrations)。
> 
{style="tip"}
* 一些数据库特定行为，如 SQLite 有限的 `ALTER TABLE` 支持，如果未仔细审查可能导致部分或失败的迁移。
* 可能包含破坏性操作（如 `DROP COLUMN` 或 `DROP SEQUENCE`）——请谨慎操作。

我们建议你在将生成的差异或脚本应用到实际数据库之前始终手动审查。

### SQLite

SQLite 对 `ALTER TABLE ADD COLUMN` 语句有严格限制。例如，在某些条件下它不允许添加没有默认值的新列。由于 Exposed 无法解释 SQLite 的所有特定约束，它仍会生成预期的 SQL 语句。由你来审查生成的 SQL 并避免尝试与 SQLite 规则不兼容的迁移。如果执行此类语句，将在运行时失败。

> 有关此限制的更多信息，请参阅 [SQLite 文档](https://www.sqlite.org/lang_altertable.html#alter_table_add_column)。
>
{style="tip"}

### PostgreSQL

在 PostgreSQL 上运行时，对齐数据库模式的函数还会检查表定义与序列之间的不一致性（特别是那些与 `IdTable` 上的 `SERIAL` 列关联的序列）。

使用 `CREATE SEQUENCE` 手动创建且未链接到表的序列将被忽略。不会为此类序列生成 `DROP` 语句。

### 约束变更检测

检测到的表和列约束的任何变更通常会导致生成 `DROP` 和 `CREATE` / `ALTER` 语句对。生成这些迁移语句的变更类型取决于约束类型：

- [`ForeignKeyConstraint`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-foreign-key-constraint/index.html) 检测名称、更新规则或删除规则的不匹配。
- [`Index`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-index/index.html) 检测名称、唯一性或涉及列的不匹配。不会检测索引类型、索引函数或过滤条件的差异。
- [`CheckConstraint`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-check-constraint/index.html) 仅检测名称的不匹配。不会检测此约束使用的布尔表达式或条件的差异。

### 列变更检测

表的列可能有多个需要 Exposed 迁移工具评估的定义属性。列变更由 [`ColumnDiff`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-column-diff/index.html) 确定。

列属性（如可空性、自增状态和注释）会被直接比较并生成相应的迁移语句。

以下列属性在变更检测方面存在限制：

* [名称](#column-name)
* [默认值](#default-values)
* [类型](#type)
* [大小和精度](#size-and-scale)

####  名称 {id="column-name"}

重命名列通常会导致一对语句：添加新列和删除旧列。

除非数据库不自动折叠标识符或名称被引用，否则名称的大小写变更通常会被忽略。

例如，SQLite 是一个如果发现大小写差异会专门生成 `ALTER... RENAME` 语句的数据库。

#### 默认值 {id="default-values"}

只有原始默认值能被可靠检测。对默认表达式或函数变更的检测可能无法保证。

此外，任何标记了 [`.databaseGenerated()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/database-generated.html) 的列将从检查中排除其默认值，以确保不会错误地移除潜在的数据库端默认值。

#### 类型 {id="type"}

列类型变更的完整支持目前仅在使用 H2 时可用。

#### 大小和精度 {id="size-and-scale"}

检测仅适用于支持这些值的列类型，如 `DECIMAL` 和 `CHAR`。

#### 自定义列定义

也可以通过使用 [`.withDefinition()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/with-definition.html) 标记列来配置表创建时的列定义，该方法接受字符串和表达式的任意组合以附加到 SQL 列语法。

但是，在将 Exposed 表对象与数据库元数据进行比较时不会使用这些自定义定义。为了更可靠的迁移工作流，请尽可能使用更明确的列方法。

例如，如果你的数据库支持表创建时的列注释，使用 `.withDefinition("COMMENT '...'")` 标记表列然后在将来更改编字符串值将不会触发迁移语句。如果你改用 [`.comment("...")`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/comment.html) 方法，字符串值将与从数据库检索的注释进行正确比较。

## 功能请求

### Maven 和 Liquibase 集成

Exposed 目前不提供 Maven 插件或 Liquibase 集成——请分享你的兴趣以帮助塑造未来的支持：

- [为 Maven 插件功能请求投票或评论](https://youtrack.jetbrains.com/issue/EXPOSED-758/Create-a-migration-plugin-for-Maven-build-tool)
- [加入 Liquibase 扩展支持的讨论](https://youtrack.jetbrains.com/issue/EXPOSED-757/Allow-use-of-migration-plugin-with-Liquibase)
