# 从 0.45.0 迁移到 0.46.0

虽然 Exposed 在代码本身中提供了迁移支持（通过使用 `@Deprecated` 注解和 `ReplaceWith` 快速修复），
本文档作为切换到新查询 DSL 所需迁移步骤的参考点。

### SELECT 查询 DSL

Exposed 的查询 DSL 已被重构，使其更接近标准 SQL `SELECT` 语句的语法。

`slice()` 函数已弃用，转而使用新的 `select()` 函数，该函数接受相同的可变数量的列并创建 `Query` 实例。
如果应选择所有列，请使用 `selectAll()` 创建 `Query` 实例。

`Query` 类现在有 `where()` 方法，可以链式调用以替代旧版本的 `select { }`。

[转到迁移步骤](#migration-steps)

将这些更改组合在一起产生了以下新 DSL：

```kotlin
// Example 1
// before
TestTable
    .slice(TestTable.columnA)
    .select { TestTable.columnA eq 1 }

// after
TestTable
    .select(TestTable.columnA)
    .where { TestTable.columnA eq 1 }

// Example 2
// before
TestTable
    .slice(TestTable.columnA)
    .selectAll()

// after
TestTable
    .select(TestTable.columnA)

// Example 3
// before
TestTable
    .select { TestTable.columnA eq 1 }

// after
TestTable
    .selectAll()
    .where { TestTable.columnA eq 1 }

// Example 4 - no change
TestTable.selectAll()
```

为了与这些更改保持一致，函数 `selectBatched()` 和 `selectAllBatched()` 也已弃用。
新的 `Query` 方法 `fetchBatchedResults()` 应作为现有 `Query` 上的终端操作使用：

```kotlin
// Example 1
// before
TestTable
    .selectBatched(50) { TestTable.columnA eq 1 }

// after
TestTable
    .selectAll()
    .where { TestTable.columnA eq 1 }
    .fetchBatchedResults(50)

// Example 2
// before
TestTable
    .slice(TestTable.columnA)
    .selectAllBatched(50)

// after
TestTable
    .select(TestTable.columnA)
    .fetchBatchedResults(50)
```

最后，`adjustSlice()` 已重命名为 `adjustSelect()`：

```kotlin
// before
val originalQuery = TestTable.select { TestTable.columnA eq 1 }
originalQuery.adjustSlice { slice(TestTable.columnA) }

// after
val originalQuery = TestTable.selectAll().where { TestTable.columnA eq 1 }
originalQuery.adjustSelect { select(TestTable.columnA) }
```

### 迁移步骤

1. 使用 *Edit > Find > Find in Files...* 查找 `adjustSlice` 的任何用法，然后使用 `Alt+Enter` 快速修复并选择"Replace usages of '...' in whole project"。
2. 对以下列表中的所有弃用方法重复步骤 1：
    * `slice`
    * `Query.select`：在搜索栏中输入 `select\((\s*.+\s*)\)(\s*)\.select`（启用正则表达式选项卡）以轻松找到此方法
    * `select`
    * `selectBatched`
    * `selectAllBatched`
3. 使用 *Edit > Find > Replace in Files...* 解决任何冗余/不兼容的 `selectAll()` 用法：
    * 在搜索栏中输入 `select\((\s*.+\s*)\)(\s*)\.selectAll\(\)`（启用正则表达式选项卡）
    * 在替换栏中输入 `select\($1\)`
    * 确认结果并选择"Replace All"
4. 重新构建项目
