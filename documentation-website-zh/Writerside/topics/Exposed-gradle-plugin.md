<show-structure for="chapter,procedure" depth="2"/>

# Exposed Gradle 插件

<tldr>
    <p>
        <b>必需依赖</b>: <code>org.jetbrains.exposed.plugin</code>
    </p>
    <p>
        <b>代码示例</b>: <a href="https://github.com/JetBrains/Exposed/tree/main/documentation-website/Writerside/snippets/exposed-gradle-plugin">exposed-gradle-plugin</a>
    </p>
</tldr>

Exposed Gradle 插件提供了构建时工具，用于处理基于 Exposed 的数据库模式。

其主要功能是通过比较 Exposed 表定义与现有数据库模式来[生成 SQL 迁移脚本](#generate-migration-scripts)。

## 要求

* Kotlin 2.2 或更高版本
* Gradle 8.14 或更高版本（[Gradle 安装指南](https://docs.gradle.org/current/userguide/installation.html)）
* JVM 11 或更高版本
* [Docker](https://www.docker.com/)（仅在[使用 `Testcontainers`](#use-testcontainers) 时需要）

## 安装

要安装插件，请将其添加到 Gradle 构建脚本的 `plugins` 块中：

```kotlin
plugins {
  id("org.jetbrains.exposed.plugin") version "%exposed_version%"
}
```

## 生成迁移脚本

要基于现有数据库模式与 Exposed 表定义之间的差异生成迁移脚本，请使用 `generateMigrations` 任务：

```bash
./gradlew generateMigrations
```

生成的文件将写入[配置的输出目录](#file-directory)。

### 与构建生命周期集成

你可以配置迁移生成，使其在 Gradle 构建生命周期中自动运行。

例如，你可以在 `build` 或 `processResources` 任务之前生成迁移：

```kotlin
// Generate migration scripts before the build task
tasks.named("build") {
    dependsOn("generateMigrations")
}

// Generate migration scripts before the processResources task
tasks.named("processResources") {
    dependsOn("generateMigrations")
}
```

## 配置

在你的 <path>build.gradle.kts</path> 文件中使用 `exposed.migrations` 块配置插件。

至少需要配置以下属性：

* `tablesPackage` 作为 Exposed 表定义所在的包名。
* 数据库配置或 `Testcontainers` 配置。

### 配置数据库连接

要配置数据库连接，请设置 `databaseUrl`、`databaseUser` 和 `databasePassword` 属性：

```kotlin
exposed {
    migrations {
        tablesPackage.set("com.example.db.tables")
        databaseUrl.set("jdbc:postgresql://localhost:5432/mydb")
        databaseUser.set("postgres")
        databasePassword.set("password")
    }
}
```

### 配置 `Testcontainers` {id="testcontainers-config"}

要配置 `Testcontainers` 连接，请设置 `testContainersImageName` 属性：

```kotlin
exposed {
    migrations {
        tablesPackage.set("com.example.db.tables")
        testContainersImageName.set("postgres:latest")
    }
}
```
> 有关更多详情和支持的数据库容器镜像，请参见 [](#use-testcontainers)。
> 
{style="tip"}

> 当配置了 `testContainersImageName` 时，插件将使用 `Testcontainers` 而不是直接的数据库连接来生成模式。
>
{style="note"}

## 附加配置

你可以选择配置以下属性，以进一步控制迁移生成和文件命名：

<deflist type="medium">
<def>
<title><code>classpath</code></title>
扫描 Exposed 表定义的类路径。

默认为项目的运行时类路径。
</def>
<def id="file-directory">
<title><code>fileDirectory</code></title>

迁移脚本存储的目录。

默认为 `"src/main/resources/db/migration"`。

</def>
<def>
<title><code>filePrefix</code></title>

迁移脚本名称使用的前缀。

默认为 `"V"`。
</def>
<def>
<title><code>fileVersionFormat</code></title>

迁移脚本名称使用的版本格式。有关支持的值，请参见[版本格式](#version-formats)。

默认为 `yyyyMMddHHmmss` 格式的时间戳。
</def>
<def>
<title><code>fileSeparator</code></title>

迁移脚本名称中使用的分隔符。

默认为 `"__"`。
</def>
<def>
<title><code>useUpperCaseDescription</code></title>

迁移脚本名称的描述部分是否转换为大写。

默认为 `true`。
</def>
<def>
<title><code>fileExtension</code></title>

迁移脚本使用的文件扩展名。

默认为 `".sql"`。
</def>
</deflist>

示例：

```kotlin
exposed {
    migrations {
        // ...
        classpath = sourceSets.main.get().runtimeClasspath
        fileDirectory.set(layout.projectDirectory.dir("src/main/resources/db/migration"))
        filePrefix.set("V")
        fileVersionFormat.set(VersionFormat.TIMESTAMP_ONLY)
        fileSeparator.set("__")
        useUpperCaseDescription.set(true)
        fileExtension.set(".sql")
    }
}
```

## 版本格式

插件支持以下 `VersionFormat` 值：
<deflist>
<def>
<title><code>TIMESTAMP_ONLY</code></title>
仅包含时间戳。

示例: `V20260417195521__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>TIMESTAMP_WITHOUT_SECONDS</code></title>
仅包含不带秒的时间戳。

示例: `V202604171955__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>MAJOR_TIMESTAMP</code></title>
包含主版本号和时间戳。

示例: `V3_20260417195521__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>MAJOR_TIMESTAMP_WITHOUT_SECONDS</code></title>
包含主版本号和不带秒的时间戳。

示例: `V3_202604171955__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>MAJOR_MINOR</code></title>
包含主版本号和次版本号。

示例: `V3_1__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>MAJOR_ONLY</code></title>
仅包含主版本号。

示例: `V3__CREATE_TABLE_USERS.sql`
</def>
</deflist>

对于包含主版本号的版本格式，插件会扫描配置的 `fileDirectory` 以确定下一个可用版本。如果目录为空，或未找到兼容的迁移文件，则从 1 开始编号。

## 文件命名

默认情况下，迁移脚本使用以下命名模式：

```text
<prefix><version><separator><description><extension>
```

例如：

```text
V20260417195521__CREATE_TABLE_USERS.sql
```

生成的描述（`CREATE_TABLE_USERS`）源自生成的 SQL 语句，通常遵循以下格式：

```text
<OPERATION>_<OBJECT>_<IDENTIFIER>_<EXTRA>
```

当迁移包含多条 SQL 语句时，描述通常源自第一条重要语句。

* 创建两个相关表的迁移通常使用第一条 `CREATE TABLE` 语句的描述。
* 如果必须在创建表之前创建序列，生成的描述仍优先使用 `CREATE TABLE` 语句而不是 `CREATE SEQUENCE`。

如果插件无法推导出标准描述，则会回退到通用名称，例如 `CUSTOM_STATEMENT_12345`。

### 覆盖生成的文件名

你可以通过向 `generateMigrations` 任务传递 `--filename` 参数来覆盖生成的文件名：

```shell
./gradlew generateMigrations --filename=V0__initialize_schema.sql
```

> 当指定 `--filename` 时，即使模式差异影响多个表，插件也会生成包含所有迁移语句的单个迁移脚本。
> 
{style="note"}

## 使用 `Testcontainers` {id="use-testcontainers"}

[`Testcontainers`](https://java.testcontainers.org/) 是一个 Java 库，允许你在测试或构建任务期间运行临时 [Docker](https://www.docker.com/) 容器。你可以使用 `Testcontainers` 在生成迁移脚本时自动启动一个临时数据库实例。

> 要使用 `Testcontainers`，必须安装并运行 Docker。
>
{style="note"}

### `Testcontainers` 工作流程

使用 `Testcontainers` 时，Exposed Gradle 插件执行以下步骤：

1. 启动数据库容器。
2. 使用 [Flyway](https://documentation.red-gate.com/flyway) 应用现有迁移脚本。
3. 将生成的数据库模式与你的 Exposed 表定义进行比较。
4. 生成新的迁移脚本。
5. 停止容器。

如果配置的迁移目录包含现有迁移脚本，插件会在生成新迁移之前使用 Flyway 应用它们。

这确保新生成的迁移脚本基于最新的模式状态，包括先前迁移引入的更改。

### 支持的数据库

插件支持以下数据库容器镜像：

| 数据库      | 容器镜像                                                                                      |
|------------|-----------------------------------------------------------------------------------------------|
| MySQL      | `mysql`、`mysql:latest` 或其他标签                                                             |
| MariaDB    | `mariadb`、`mariadb:latest` 或其他标签                                                         |
| PostgreSQL | `postgres`、`postgres:latest` 或其他标签                                                       |
| SQL Server | `mcr.microsoft.com/mssql/server`、`mcr.microsoft.com/mssql/server:2025-latest` 或其他标签       |
| Oracle     | 以 `container-registry.oracle.com/`、`gvenzl/oracle-` 或 `oracle/` 开头的镜像                  |

## 后续步骤

Exposed Gradle 插件生成迁移脚本，但不会自动将其应用到你的数据库。

生成迁移脚本后，请使用现有的数据库迁移工作流程进行审查和应用。例如，你可以：

* 使用 [Flyway](https://www.red-gate.com/products/flyway/) 或 [Liquibase](https://www.liquibase.com/liquibase-secure) 等工具应用迁移。
* 使用数据库客户端手动执行脚本。
* 从 [IntelliJ IDEA 数据库工具窗口](https://www.jetbrains.com/help/idea/database-tool-window.html)运行脚本。
* 将迁移执行集成到你的 CI/CD 流水线中。

应用生成的脚本后，你的数据库模式应与当前的 Exposed 表定义匹配。
