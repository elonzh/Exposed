# 自定义类型映射

<primary-label ref="r2dbc"/>

自定义 PostgreSQL 类型（如 `citext` 或 `int4range`）可以在 Exposed 的 R2DBC 模块中使用自定义
[`TypeMapper`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc.mappers/-type-mapper/index.html)
实现来支持。这使得能够准确地绑定值和生成 SQL，而不依赖于仅限 JDBC 的功能（如 `PGobject`）。

为此，您需要执行以下操作：

1. [定义自定义列类型](#defining-a-custom-column-type)。
2. [实现自定义 `TypeMapper`](#implementing-a-typemapper) 以绑定这些列类型的值。
3. [注册您的映射器](#registering-the-type-mapper) 使其在内置的 `PostgresSpecificTypeMapper` 之前生效。

## 定义自定义列类型

自定义列类型负责生成适当的 SQL 类型以及在数据库表示和值之间进行转换。

例如，以下 `CitextR2dbcColumnType` 生成 `CITEXT` 作为其 SQL 类型，可以在列定义中使用：

```kotlin
class CitextR2dbcColumnType(
    colLength: Int
) : VarCharColumnType(colLength) {
    override fun sqlType(): String = "CITEXT"
}
```

类似地，要支持范围类型（如 `int4range`），您可以创建一个抽象基类型：

```kotlin
abstract class RangeR2dbcColumnType<T : Comparable<T>, R : ClosedRange<T>>(
    val subType: ColumnType<T>,
) : ColumnType<R>() {
    abstract fun List<String>.toRange(): R

    override fun nonNullValueToString(value: R): String =
        toPostgresqlValue(value)

    override fun nonNullValueAsDefaultString(value: R): String =
        "'${nonNullValueToString(value)}'"

    override fun valueFromDB(value: Any): R = when (value) {
        is String -> value.trim('[', ')').split(',').toRange()
        else -> error("Unexpected DB value type: ${value::class.simpleName}")
    }

    companion object {
        fun <T : Comparable<T>, R : ClosedRange<T>> toPostgresqlValue(range: R): String =
            "[${range.start},${range.endInclusive}]"
    }
}
```

具体子类（如 `IntRangeColumnType`）可以实现 `.toRange()` 来处理解析。更多信息请参阅 [](Custom-data-types.topic#ranges-of-data)。

## 实现 `TypeMapper`

`TypeMapper` 负责根据方言和列类型将 Kotlin 值绑定到 R2DBC `Statement` 参数。

以下是支持 `citext` 和 `int4range` 的 `CustomTypeMapper` 示例：

```kotlin
class CustomTypeMapper : TypeMapper {
    override val priority: Double = 1.9

    override val dialects = listOf(PostgreSQLDialect::class)

    override val columnTypes = listOf(
        CitextR2dbcColumnType::class,
        IntRangeColumnType::class
    )

    override fun setValue(
        statement: Statement,
        dialect: DatabaseDialect,
        typeMapping: R2dbcTypeMapping,
        columnType: IColumnType<*>,
        value: Any?,
        index: Int
    ): Boolean {
        if (value == null) return false

        return when (columnType) {
            is CitextR2dbcColumnType -> {
                statement.bind(index - 1, Parameters.`in`(PostgresqlObjectId.UNSPECIFIED, value))
                true
            }
            is IntRangeColumnType -> {
                statement.bind(
                    index - 1,
                    Parameters.`in`(
                        PG_INT_RANGE_TYPE,
                        RangeR2dbcColumnType.toPostgresqlValue(value as IntRange)
                    )
                )
                true
            }
            else -> false
        }
    }

    private val PG_INT_RANGE_TYPE = PostgresTypes.PostgresType(
        3904, 3904, 3905, 3905, "int4range", "R"
    )
}
```

此实现确保 Exposed 能够在运行时正确序列化这些自定义类型。

## 注册类型映射器

Exposed 使用 Java SPI `ServiceLoader` 来发现和加载此接口的任何实现。
要注册您的映射器，应在 **resources** 文件夹中创建一个新文件。

1. 在您的项目中创建以下文件：

    ```generic
    src/main/resources/META-INF/services/org.jetbrains.exposed.v1.r2dbc.mappers.TypeMapper
    ```

2. 将您的类型映射器的完全限定类名添加到文件中：

    ```generic
    com.example.mapper.CustomTypeMapper
    ```

当 Exposed 初始化时，您的自定义映射器将被加载并添加到 `R2dbcRegistryTypeMapping` 中。
