<show-structure for="chapter,procedure" depth="2"/>

# 使用数据库

在 Exposed 中，[`Database`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/-database/index.html)
和 [`R2dbcDatabase`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc/-r2dbc-database/index.html)
类表示数据库实例，并封装了与特定数据库交互所需的连接详情和配置。

## 选择 JDBC 还是 R2DBC

Exposed 支持 JDBC 和 R2DBC 作为数据库连接的传输层。了解它们的差异将帮助你为应用程序选择合适的方式：

### JDBC

JDBC（Java 数据库连接）是传统的同步阻塞式 API，用于与关系数据库交互。Exposed 的 JDBC 集成非常成熟，具有广泛的数据库支持和丰富的工具链。它适用于：

- 优先考虑简单性而非可扩展性的传统应用程序。
- 在同步上下文中使用连接池和事务管理的项目。

JDBC 得到良好支持，可与大多数现有数据库驱动和工具无缝协作。

### R2DBC

R2DBC（响应式关系数据库连接）是 JDBC 的非阻塞、异步替代方案。Exposed 的 R2DBC 支持可与响应式框架和 Kotlin 协程集成。在以下情况下使用 R2DBC：

- 你正在构建高并发、I/O 密集型应用程序。
- 你希望避免线程阻塞并充分利用 Kotlin 协程。

R2DBC 仍在发展中，并非所有数据库或功能都像 JDBC 那样得到同等支持。

当你需要简单性、广泛的数据库兼容性，或正在构建具有中等并发需求的传统应用程序时，选择 JDBC。当构建响应式应用程序、使用 Kotlin 协程，或需要以有限资源高效处理大量并发连接时，选择 R2DBC。

## 连接数据库

在 Exposed 中，每次数据库访问都从建立连接和创建事务开始。

要连接数据库，首先需要告诉 Exposed 连接详情。你有两个选择：

- 使用 [`Database.connect()`](https://jetbrains.github.io/Exposed/api/exposed-jdbc/org.jetbrains.exposed.v1.jdbc/-database/-companion/connect.html) 进行基于 JDBC 的传统访问。
- 使用 [`R2dbcDatabase.connect()`](https://jetbrains.github.io/Exposed/api/exposed-r2dbc/org.jetbrains.exposed.v1.r2dbc/-r2dbc-database/-companion/connect.html) 进行基于 R2DBC 的响应式非阻塞访问。

这些函数不会立即建立连接。相反，它们提供一个描述符供将来使用。实际连接仅在[事务](Transactions.md)启动时才建立。

要使用简单连接参数获取数据库实例，请使用以下方法：

<tabs group="connectivity">
    <tab id="jdbc-connect" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin"
                    src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt"
                    include-symbol="h2db" />
    </tab>
    <tab id="r2dbc-connect" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin"
                    src="exposed-databases-r2dbc/src/main/kotlin/org/example/R2DBCDatabases.kt"
                    include-symbol="h2db" />
    </tab>
</tabs>

<note>每个数据库多次执行此代码会导致应用程序中出现连接泄漏，因此建议将其存储以供后续使用：
<code-block lang="kotlin"
            src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt"
            include-symbol="DbSettings"/>
</note>

<note>
    默认情况下，Exposed 使用 <code>ServiceLoader</code> 获取
    <a href="https://jetbrains.github.io/Exposed/api/exposed-core/org.jetbrains.exposed.v1.core/-database-connection-auto-registration/index.html">
        <code>DatabaseConnectionAutoRegistration</code>
    </a>
    接口的实现，该接口表示 <code>Database</code> 实例访问的连接。
    这可以在调用 <code>Database.connect()</code> 方法时通过在参数列表中为 <code>connectionAutoRegistration</code> 提供参数来修改。
</note>

### H2

要使用 H2，你需要添加 H2 驱动依赖：

<tabs group="connectivity">
    <tab id="jdbc-h2-db" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin">
            implementation("com.h2database:h2:%h2_db_version%")
        </code-block>
    </tab>
    <tab id="r2dbc-h2-db" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin">
            implementation("io.r2dbc:r2dbc-h2:%h2_r2dbc_version%")
        </code-block>
    </tab>
</tabs>

然后连接到数据库：

<tabs group="connectivity">
    <tab id="jdbc-h2-driver-connect" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin"
                    src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt"
                    include-symbol="h2dbFromFile" />
    </tab>
    <tab id="r2dbc-h2-driver-connect" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin"
                    src="exposed-databases-r2dbc/src/main/kotlin/org/example/R2DBCDatabases.kt" 
                    include-symbol="h2dbFromFile" />
        </tab>
</tabs>

或内存数据库：

<tabs group="connectivity">
    <tab id="jdbc-h2-db-in-memory" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin"
                    src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt"
                    include-symbol="h2db" />
    </tab>
    <tab id="r2dbc-h2-db-in-memory" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin"
                    src="exposed-databases-r2dbc/src/main/kotlin/org/example/R2DBCDatabases.kt"
                    include-symbol="h2db" />
    </tab>
</tabs>

默认情况下，H2 在最后一个连接关闭时会关闭数据库。如果你想保持数据库打开，可以使用 `DB_CLOSE_DELAY=-1`
选项：

```kotlin
Database.connect("jdbc:h2:mem:regular;DB_CLOSE_DELAY=-1;", "org.h2.Driver")
```

### MariaDB

添加所需依赖：

<tabs group="connectivity">
    <tab id="jdbc-maria-db" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin">
            implementation("org.mariadb.jdbc:mariadb-java-client:%mariadb%")
        </code-block>
    </tab>
    <tab id="r2dbc-maria-db" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin">
            implementation("org.mariadb:r2dbc-mariadb:%mariadb_r2dbc%")
        </code-block>
    </tab>
</tabs>

连接到数据库：

<tabs group="connectivity">
    <tab id="jdbc-maria-db-connect" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin"
                    src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt"
                    include-symbol="mariadb" />
    </tab>
    <tab id="r2dbc-maria-db-connect" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin"
                    src="exposed-databases-r2dbc/src/main/kotlin/org/example/R2DBCDatabases.kt"
                    include-symbol="mariadb" />
    </tab>
</tabs>

### MySQL

添加所需依赖：

<tabs group="connectivity">
    <tab id="jdbc-mysql" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin">
            implementation("mysql:mysql-connector-java:%mysql%")
        </code-block>
    </tab>
    <tab id="r2dbc-mysql" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin">
            implementation("io.asyncer:r2dbc-mysql:%mysql_r2dbc%")
        </code-block>
    </tab>
</tabs>

连接到数据库：

<tabs group="connectivity">
    <tab id="jdbc-mysql-connect" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin"
                    src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt"
                    include-symbol="mysqldb" />
    </tab>
    <tab id="r2dbc-mysql-connect" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin"
                    src="exposed-databases-r2dbc/src/main/kotlin/org/example/R2DBCDatabases.kt"
                    include-symbol="mysqldb" />
    </tab>
</tabs>

### Oracle

添加所需依赖：

<tabs group="connectivity">
    <tab id="jdbc-oracle" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin">
            implementation("com.oracle.database.jdbc:ojdbc8:%oracle%")
        </code-block>
    </tab>
    <tab id="r2dbc-oracle" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin">
            implementation("com.oracle.database.r2dbc:oracle-r2dbc:%oracle_r2dbc%")
        </code-block>
    </tab>
</tabs>

连接到数据库：

<tabs group="connectivity">
    <tab id="jdbc-oracle-connect" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin"
                    src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt"
                    include-symbol="oracledb" />
    </tab>
    <tab id="r2dbc-oracle-connect" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin"
                    src="exposed-databases-r2dbc/src/main/kotlin/org/example/R2DBCDatabases.kt"
                    include-symbol="oracledb" />
    </tab>
</tabs>

### PostgreSQL

添加所需依赖：

<tabs group="connectivity">
    <tab id="jdbc-postgresql" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin">
            implementation("org.postgresql:postgresql:%postgresql%")
        </code-block>
    </tab>
    <tab id="r2dbc-postgresql" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin">
            implementation("org.postgresql:r2dbc-postgresql:%postgresql_r2dbc%")
        </code-block>
    </tab>
</tabs>

连接到数据库：

<tabs group="connectivity">
    <tab id="jdbc-postgresql-connect" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin"
                    src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt"
                    include-symbol="postgresqldb" />
    </tab>
    <tab id="r2dbc-postgresql-connect" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin"
                    src="exposed-databases-r2dbc/src/main/kotlin/org/example/R2DBCDatabases.kt"
                    include-symbol="postgresqldb" />
    </tab>
</tabs>

### 使用 pgjdbc-ng JDBC 驱动的 PostgreSQL

添加所需依赖：

```kotlin
implementation("com.impossibl.pgjdbc-ng:pgjdbc-ng:%postgreNG%")
```

连接到数据库：

```kotlin
```
{src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt" include-symbol="postgresqldbNG"}

### SQL Server

添加所需依赖：

<tabs group="connectivity">
    <tab id="jdbc-sqlserver" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin">
            implementation("com.microsoft.sqlserver:mssql-jdbc:%sqlserver%")
        </code-block>
    </tab>
    <tab id="r2dbc-sqlserver" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin">
            implementation("io.r2dbc:r2dbc-mssql:%sqlserver_r2dbc%")
        </code-block>
    </tab>
</tabs>

连接到数据库：

<tabs group="connectivity">
    <tab id="jdbc-sqlserver-connect" title="JDBC" group-key="jdbc">
        <code-block lang="kotlin"
                    src="exposed-databases-jdbc/src/main/kotlin/org/example/Databases.kt"
                    include-symbol="sqlserverdb" />
    </tab>
    <tab id="r2dbc-sqlserver-connect" title="R2DBC" group-key="r2dbc">
        <code-block lang="kotlin"
                    src="exposed-databases-r2dbc/src/main/kotlin/org/example/R2DBCDatabases.kt"
                    include-symbol="sqlserverdb" />
    </tab>
</tabs>

### SQLite

添加所需依赖：

```kotlin
implementation("org.xerial:sqlite-jdbc:%sqlite%")
```

连接到数据库：

```kotlin
Database.connect("jdbc:sqlite:/data/data.db", "org.sqlite.JDBC")  
```

或内存数据库：

```kotlin
Database.connect("jdbc:sqlite:file:test?mode=memory&cache=shared", "org.sqlite.JDBC")  
```  

设置 SQLite 兼容的[隔离级别](https://www.sqlite.org/isolation.html)：

```kotlin
TransactionManager.manager.defaultIsolationLevel = Connection.TRANSACTION_SERIALIZABLE
// or Connection.TRANSACTION_READ_UNCOMMITTED
```