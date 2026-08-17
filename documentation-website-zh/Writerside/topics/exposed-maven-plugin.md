<show-structure for="chapter,procedure" depth="2"/>

# Exposed Maven 插件

<tldr>
    <p>
        <b>必需的依赖项</b>：<code>org.jetbrains.exposed.plugin:exposed-maven-plugin</code>
    </p>
    <p>
        <b>代码示例</b>：<a href="https://github.com/JetBrains/Exposed/tree/main/documentation-website/Writerside/snippets/exposed-maven-plugin">exposed-maven-plugin</a>
    </p>
</tldr>

Exposed Maven 插件提供构建时工具，用于在 Maven 项目中处理基于 Exposed 的数据库模式。

其主要功能是通过比较 Exposed 表定义与现有数据库模式来[生成 SQL 迁移脚本](#generate-migration-scripts)。

## 要求

* Kotlin 2.2 或更高版本
* Maven 3.9 或更高版本
* JVM 11 或更高版本
* [Docker](https://www.docker.com/)（仅在[使用 `Testcontainers`](#use-testcontainers) 时需要）

## 安装

要安装插件，请将其添加到 `<build><plugins>` 部分（位于你的 <path>pom.xml</path> 文件中）：

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.jetbrains.exposed.plugin</groupId>
            <artifactId>exposed-maven-plugin</artifactId>
            <version>%exposed_version%</version>
        </plugin>
    </plugins>
</build>
```

## 生成迁移脚本 {#generate-migration-scripts}

要根据现有数据库模式与 Exposed 表定义之间的差异生成迁移脚本，请调用 `generate-migration` 目标：

```bash
mvn exposed:generate-migrations
```

生成的文件将写入[配置的输出目录](#file-directory)。

### 与构建生命周期集成

你可以通过向插件配置添加 `<executions>` 块，将迁移生成绑定到 Maven 生命周期阶段。例如，要在 `process-classes` 阶段生成迁移：

```xml
<plugin>
    <groupId>org.jetbrains.exposed.plugin</groupId>
    <artifactId>exposed-maven-plugin</artifactId>
    <version>%exposed_version%</version>
    <executions>
        <execution>
            <id>generate-migrations</id>
            <phase>process-classes</phase>
            <goals>
                <goal>generate-migrations</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

## 配置

请使用 `<configuration>` 块配置插件；该块位于 <path>pom.xml</path> 文件的插件条目中。

至少需要配置以下参数：

* 将 `tablesPackage` 设置为 Exposed 表定义所在的包名。
* 数据库配置或 `Testcontainers` 配置。

### 配置数据库连接

要配置数据库连接，请设置 `databaseUrl`、`databaseUser` 和 `databasePassword` 参数：

```xml
<plugin>
    <groupId>org.jetbrains.exposed.plugin</groupId>
    <artifactId>exposed-maven-plugin</artifactId>
    <version>%exposed_version%</version>
    <configuration>
        <tablesPackage>com.example.db.tables</tablesPackage>
        <databaseUrl>jdbc:postgresql://localhost:5432/mydb</databaseUrl>
        <databaseUser>postgres</databaseUser>
        <databasePassword>password</databasePassword>
    </configuration>
</plugin>
```

### 配置 `Testcontainers` {id="testcontainers-config"}

要配置 `Testcontainers` 连接，请设置 `testContainersImageName` 参数：

```xml
<plugin>
    <groupId>org.jetbrains.exposed.plugin</groupId>
    <artifactId>exposed-maven-plugin</artifactId>
    <version>%exposed_version%</version>
    <configuration>
        <tablesPackage>com.example.db.tables</tablesPackage>
        <testContainersImageName>postgres:latest</testContainersImageName>
    </configuration>
</plugin>
```

> 有关更多详情和支持的数据库容器镜像，请参见 [](#use-testcontainers)。
>
{style="tip"}

> 当配置了 `testContainersImageName` 时，插件将使用 `Testcontainers`（而不是直接的数据库连接）生成数据库模式。
>
{style="note"}

### 从命令行覆盖参数

要从命令行覆盖任意插件参数，请使用对应的 `exposed.migrations.<name>` 系统属性：

```bash
mvn exposed:generate-migrations \
    -Dexposed.migrations.tablesPackage=com.example.db.tables \
    -Dexposed.migrations.databaseUrl=jdbc:postgresql://localhost:5432/mydb \
    -Dexposed.migrations.databaseUser=postgres \
    -Dexposed.migrations.databasePassword=password
```

## 附加配置

你可以选择配置以下参数，以进一步控制迁移生成和文件命名：

<deflist type="medium">
<def id="file-directory">
<title><code>fileDirectory</code></title>

迁移脚本存储的目录。

默认为项目基目录下的 `src/main/resources/db/migration`。

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

```xml
<plugin>
    <groupId>org.jetbrains.exposed.plugin</groupId>
    <artifactId>exposed-maven-plugin</artifactId>
    <version>%exposed_version%</version>
    <configuration>
        <tablesPackage>com.example.db.tables</tablesPackage>
        <databaseUrl>jdbc:postgresql://localhost:5432/mydb</databaseUrl>
        <databaseUser>postgres</databaseUser>
        <databasePassword>password</databasePassword>

        <fileDirectory>${project.basedir}/src/main/resources/db/migration</fileDirectory>
        <filePrefix>V</filePrefix>
        <fileVersionFormat>TIMESTAMP_ONLY</fileVersionFormat>
        <fileSeparator>__</fileSeparator>
        <useUpperCaseDescription>true</useUpperCaseDescription>
        <fileExtension>.sql</fileExtension>
    </configuration>
</plugin>
```

## 版本格式 {#version-formats}

插件支持以下 `fileVersionFormat` 值：

<deflist>
<def>
<title><code>TIMESTAMP_ONLY</code></title>
仅包含时间戳。

示例：`V20260417195521__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>TIMESTAMP_WITHOUT_SECONDS</code></title>
仅包含不带秒的时间戳。

示例：`V202604171955__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>MAJOR_TIMESTAMP</code></title>
包含主版本号和时间戳。

示例：`V3_20260417195521__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>MAJOR_TIMESTAMP_WITHOUT_SECONDS</code></title>
包含主版本号和不带秒的时间戳。

示例：`V3_202604171955__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>MAJOR_MINOR</code></title>
包含主版本号和次版本号。

示例：`V3_1__CREATE_TABLE_USERS.sql`
</def>
<def>
<title><code>MAJOR_ONLY</code></title>
仅包含主版本号。

示例：`V3__CREATE_TABLE_USERS.sql`
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

你可以传递 `exposed.migrations.filename` 系统属性，覆盖 `generate-migration` 目标生成的文件名：

```bash
mvn exposed:generate-migrations -Dexpose.migrations.filename=V0__initialize_schema.sql
```

> 当指定 `exposed.migrations.filename` 时，即使数据库模式差异影响多个表，插件也会生成包含所有迁移语句的单个迁移脚本。
>
{style="note"}

## 使用 `Testcontainers` {id="use-testcontainers"}

[`Testcontainers`](https://java.testcontainers.org/) 是一个 Java 库，允许你在测试或构建任务期间运行临时 [Docker](https://www.docker.com/) 容器。你可以使用 `Testcontainers` 在生成迁移脚本时自动启动一个临时数据库实例。

> 要使用 `Testcontainers`，必须安装并运行 Docker。
>
{style="note"}

### `Testcontainers` 工作流程

使用 `Testcontainers` 时，Exposed Maven 插件执行以下步骤：

1. 启动数据库容器。
2. 使用 [Flyway](https://documentation.red-gate.com/flyway) 应用现有迁移脚本。
3. 将生成的数据库模式与你的 Exposed 表定义进行比较。
4. 生成新的迁移脚本。
5. 停止容器。

如果配置的迁移目录包含现有迁移脚本，插件会在生成新迁移之前使用 Flyway 应用它们。

这确保新生成的迁移脚本基于最新的数据库模式状态，包括先前迁移引入的更改。

### 支持的数据库

插件支持以下数据库容器镜像：

| 数据库         | 容器镜像                                                                                      |
|-------------|-------------------------------------------------------------------------------------------|
| MySQL       | `mysql`、`mysql:latest` 或其他标签                                                             |
| MariaDB     | `mariadb`、`mariadb:latest` 或其他标签                                                         |
| PostgreSQL  | `postgres`、`postgres:latest` 或其他标签                                                       |
| SQL Server  | `mcr.microsoft.com/mssql/server`、`mcr.microsoft.com/mssql/server:2025-latest` 或其他标签       |
| Oracle      | 以 `container-registry.oracle.com/`、`gvenzl/oracle-` 或 `oracle/` 开头的镜像                  |

## 后续步骤

Exposed Maven 插件生成迁移脚本，但不会自动将其应用到你的数据库。

生成迁移脚本后，请使用现有的数据库迁移工作流程进行审查和应用。例如，你可以：

* 使用 [Flyway](https://www.red-gate.com/products/flyway/) 或 [Liquibase](https://www.liquibase.com/liquibase-secure) 等工具应用迁移。
* 使用数据库客户端手动执行脚本。
* 从 [IntelliJ IDEA 数据库工具窗口](https://www.jetbrains.com/help/idea/database-tool-window.html)运行脚本。
* 将迁移执行集成到你的 CI/CD 流水线中。

应用生成的脚本后，你的数据库模式应与当前的 Exposed 表定义匹配。
