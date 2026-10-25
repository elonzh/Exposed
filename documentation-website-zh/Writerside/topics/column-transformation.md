# 列转换 {#column-transformation}

列转换允许您在数据库列类型与应用程序数据类型之间定义自定义转换。
当您需要以一种格式存储数据，却在应用程序中以另一种格式使用数据时，
这尤其有用。

## 基本用法 {#basic-usage}

要对表中的列应用自定义转换，请使用 [`.transform()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/transform.html)
函数。

转换包含两个操作：

* `wrap()` 函数将从数据库读取的值转换为应用程序使用的类型。
* `unwrap()` 函数将应用程序中的值转换为数据库存储时使用的类型。

在以下示例中，`Meals` 表以 `LocalTime` 值的形式存储用餐时间，但在应用程序中
将其表示为 `Meal` 值：

```kotlin
enum class Meal {
    BREAKFAST,
    LUNCH,
    DINNER
}

object Meals : Table() {
    val mealTime: Column<Meal> = time("meal_time")
        .transform(
            wrap = {
                when {
                    it.hour < 10 -> Meal.BREAKFAST
                    it.hour < 15 -> Meal.LUNCH
                    else -> Meal.DINNER
                }
            },
            unwrap = {
                when (it) {
                    Meal.BREAKFAST -> LocalTime(8, 0)
                    Meal.LUNCH -> LocalTime(12, 0)
                    Meal.DINNER -> LocalTime(18, 0)
                }
            }
        )
}
```

在 `.transform()` 函数中：

* `wrap()` 函数将存储的 `LocalTime` 值转换为 `Meal` 枚举。它会检查所存储时间的小时数，
  并返回相应的用餐类型。
* `unwrap()` 函数将 `Meal` 枚举转换回 `LocalTime` 值，以便存储到数据库中。

## 复用转换 {#reusing-a-transformation}

对于多个列共用或逻辑更复杂的转换，您可以定义自定义的 [`ColumnTransformer`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-column-transformer/index.html)，
并将其作为参数传递给 `.transform()` 函数：

```kotlin
class MealTimeTransformer : ColumnTransformer<LocalTime, Meal> {
    override fun wrap(value: LocalTime): Meal = when {
        value.hour < 10 -> Meal.BREAKFAST
        value.hour < 15 -> Meal.LUNCH
        else -> Meal.DINNER
    }

    override fun unwrap(value: Meal): LocalTime = when (value) {
        Meal.BREAKFAST -> LocalTime(8, 0)
        Meal.LUNCH -> LocalTime(12, 0)
        Meal.DINNER -> LocalTime(18, 0)
    }
}

fun Column<LocalTime>.mealTransform(): Column<Meal> =
    transform(MealTimeTransformer())

object Meals : Table() {
    val mealTime: Column<Meal> = time("meal_time").mealTransform()
}
```

> 每次访问表中的列时，都会应用列转换。为了保持性能，建议
> 避免在此处执行开销较大的转换。
>
{style="note"}

## 空值转换 {#null-transform}

[`.nullTransform()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/null-transform.html)
函数应用一种转换，允许将非空数据库列在 Kotlin 中表示为可空列。

此转换不会改变数据库中列的定义，该列仍然不允许为空。它允许
将数据库中特定的非空值映射为应用程序中的 `null`。这可用于
将非空文本列中的空字符串、空列表或负数 ID 转换为 `null`。

```kotlin
class MealTimeNullTransformer : ColumnTransformer<LocalTime, Meal?> {
    override fun wrap(value: LocalTime): Meal? = when {
        value.hour == 0 && value.minute == 0 -> null
        value.hour < 10 -> Meal.BREAKFAST
        value.hour < 15 -> Meal.LUNCH
        else -> Meal.DINNER
    }

    override fun unwrap(value: Meal?): LocalTime = when (value) {
        Meal.BREAKFAST -> LocalTime(8, 0)
        Meal.LUNCH -> LocalTime(12, 0)
        Meal.DINNER -> LocalTime(18, 0)
        else -> LocalTime(0, 0)
    }
}

object Meals : Table() {
    val mealTime: Column<Meal?> = time("meal_time").nullTransform(MealTimeNullTransformer())
}
```

* 从数据库读取 ` 00:00 ` 值时，该值会转换为 `null`。
* 写入 `Meal.BREAKFAST`、`Meal.LUNCH` 或 `Meal.DINNER` 时，该值会转换为
  相应的 `LocalTime`。
* 写入 `null` 时，该值会转换回 `00:00`。

## 非空转换 {#non-null-transform}

[`.nonNullTransform()`](https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-table/non-null-transform.html)
函数允许将可空数据库列表示为非空的 Exposed 列。

当数据库允许 `null`，但应用程序中有一个有意义的非空值可以表示它时，
此功能就很有用。该转换负责将数据库中的 `null` 值转换为适当的非空应用程序值，
并在写入数据库时将该值转换回去。

在以下示例中，向 `Meal` 枚举添加了一个 `UNSCHEDULED` 值，用于表示未指定用餐时间：

```kotlin
enum class Meal {
    BREAKFAST,
    LUNCH,
    DINNER,
    UNSCHEDULED
}

class MealTimeNonNullTransformer : ColumnTransformer<LocalTime?, Meal> {
    override fun wrap(value: LocalTime?): Meal = when {
        value == null -> Meal.UNSCHEDULED
        value.hour < 10 -> Meal.BREAKFAST
        value.hour < 15 -> Meal.LUNCH
        else -> Meal.DINNER
    }

    override fun unwrap(value: Meal): LocalTime? = when (value) {
        Meal.BREAKFAST -> LocalTime(8, 0)
        Meal.LUNCH -> LocalTime(12, 0)
        Meal.DINNER -> LocalTime(18, 0)
        Meal.UNSCHEDULED -> null
    }
}

object Meals : Table() {
    val mealTime: Column<Meal> = time("meal_time")
        .nullable()
        .nonNullTransform(MealTimeNonNullTransformer())
}
```

* 从数据库读取 `null` 时，该值会转换为 `Meal.UNSCHEDULED`。
* 写入 `Meal.BREAKFAST`、`Meal.LUNCH` 或 `Meal.DINNER` 时，该值会转换为
  相应的 `LocalTime`。
* 写入 `Meal.UNSCHEDULED` 时，该值会转换回 `null`。

数据库列仍然可空，而应用程序使用的是非空的 `Column<Meal>`。
