# 哈希数据

<show-structure for="chapter,procedure" depth="2"/>
<var name="artifact_name" value="exposed-crypt"/>
<var name="example_name" value="exposed-hashing-data"/>

<tldr>
<include from="lib.topic" element-id="required_dependency"/>
<include from="lib.topic" element-id="code_example"/>
<include from="lib.topic" element-id="jdbc-supported"/>
<include from="lib.topic" element-id="r2dbc-supported"/>
</tldr>

Exposed 通过 `exposed-crypt` 模块支持对密码等敏感数据进行单向哈希。

与加密不同，哈希无法恢复原始值。你需要将明文值与存储的哈希值进行验证。

## 添加依赖 {id="add-dependencies"}

要在 Exposed 中使用哈希，请将 `%artifact_name%` 模块添加到构建脚本中：

<include from="lib.topic" element-id="add-dependency"/>

若要使用 `scrypt` 和 `Argon2` 哈希，还可以将 [Bouncy Castle](https://www.bouncycastle.org/) 库添加为运行时依赖：

<var name="external_artifact_groupId" value="org.bouncycastle"/>
<var name="external_artifact_name" value="bcprov-jdk18on"/>
<var name="external_artifact_version" value="%bouncy_castle_version%"/>
<include from="lib.topic" element-id="add-external-runtime-dependency"/>


## 基本用法

要创建哈希列，请对字符类型列应用 [`.hashed()`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/hashed.html)
函数：

```kotlin
object Users : IntIdTable() {
    val password = text("password").hashed()
}
```

`.hashed()` 函数会将列的 Kotlin 类型从 `String` 更改为 [`Hashed`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/-hashed/index.html)。

## 支持的算法

`.hashed()` 函数默认使用 `BCryptHasher`。你可以选择以下任一受支持的 `Hasher` 实现来更改默认哈希器：

| Hasher                                                                                                                            | 算法        |
|-----------------------------------------------------------------------------------------------------------------------------------|-----------|
| [`BCryptHasher`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/-b-crypt-hasher/index.html) | `bcrypt`  |
| [`Argon2Hasher`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/-argon2-hasher/index.html)  | `Argon2`  |
| [`Pbkdf2Hasher`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/-pbkdf2-hasher/index.html)  | `PBKDF2`  |
| [`SCryptHasher`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/-s-crypt-hasher/index.html) | `scrypt`  |

要使用其他哈希算法或自定义其参数，请创建一个 `Hasher` 并将其传给 `.hashed()` 函数：

```kotlin
```
{src="exposed-hashing-data/src/main/kotlin/org/example/tables/UsersTable.kt" include-symbol="hasher, Users"}

## 配置哈希器

每个哈希器都提供参数，用于配置生成和验证哈希值所需的工作量。例如，你可以配置 `BCryptHasher` 使用的强度：

```kotlin
```
{src="exposed-hashing-data/src/main/kotlin/org/example/tables/UsersTable.kt" include-symbol="bCryptHasher"}

对于 `Argon2Hasher`，你可以配置内存用量、迭代次数和并行度等参数：

```kotlin
```
{src="exposed-hashing-data/src/main/kotlin/org/example/tables/UsersTable.kt" include-symbol="argon2Hasher"}

> `Argon2Hasher` 需要将 [Bouncy Castle](https://www.bouncycastle.org/) 库作为运行时依赖。有关更多
> 信息，请参阅[](#add-dependencies)。
> 
{style="note"}

`Pbkdf2Hasher` 还允许你选择伪随机函数：

```kotlin
```
{src="exposed-hashing-data/src/main/kotlin/org/example/tables/UsersTable.kt" include-symbol="pbkdf2Hasher"}

> 有关所有可用配置选项的完整列表，请参阅 [API 文档](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/index.html)。
> 
{style="tip"}

## 使用 Spring Security 密码编码器

如果你的应用程序已经使用 [Spring Security `PasswordEncoder`](https://docs.spring.io/spring-security/reference/features/authentication/password-storage.html#authentication-password-storage)，
请使用 [`PasswordEncoderHasher`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/-password-encoder-hasher/index.html) 包装它，
使其适配 `Hasher` 类型：

```kotlin
val passwordEncoder = MyPasswordEncoder()
val hasher = PasswordEncoderHasher(passwordEncoder)

object Users : IntIdTable() { 
    val password = text("password").hashed(hasher)
}
```

`PasswordEncoderHasher` 将哈希和验证委托给所提供的 `PasswordEncoder`，同时公开标准的 Exposed `Hasher` API。

## 哈希并存储值

在存储明文值之前，使用已配置的 `Hasher` 对其进行哈希：

```kotlin
```
{src="exposed-hashing-data/src/main/kotlin/org/example/App.kt" include-lines="28,30-31"}

[`.hash()`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/hash.html) 函数
返回包含已编码哈希值的 [`Hashed`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/-hashed/index.html)
值。

> 哈希过程会[_加盐_](https://en.wikipedia.org/wiki/Salt_(cryptography))，因此多次对同一个明文值进行哈希可能会产生不同的编码值。
>
{style="note"}

## 验证值

要验证明文值，请对已存储的 `Hashed` 值使用 [`.matches()`](https://jetbrains.github.io/Exposed/api/exposed-crypt/org.jetbrains.exposed.v1.crypt/-hashed/matches.html)
函数：

```kotlin
```
{src="exposed-hashing-data/src/main/kotlin/org/example/App.kt" include-lines="32-38"}

如果明文值与存储的哈希值匹配，`.matches()` 函数将返回 `true`。
