<show-structure for="chapter,procedure" depth="3"/>

# 为 Exposed 做贡献

我们很高兴您考虑为 Exposed 做贡献！

您可以通过多种方式做出贡献：

* 问题和功能请求
* 文档
* 代码
* 社区支持

本项目和相应的社区受
[JetBrains 开源和社区行为准则](https://confluence.jetbrains.com/display/ALL/JetBrains+Open+Source+and+Community+Code+of+Conduct)管辖。
无论您希望如何贡献，请确保您已阅读并遵守该准则。

## 问题和功能请求

如果您遇到错误或有新功能的想法，请通过 [YouTrack](https://youtrack.jetbrains.com/issues/EXPOSED)
提交给我们，这是我们的问题跟踪器。虽然问题对公众可见，但创建新问题或评论现有问题都需要登录 YouTrack。

在提交问题或功能请求之前，请搜索 YouTrack 的[现有问题](https://youtrack.jetbrains.com/issues/EXPOSED)以避免报告重复的问题。

提交问题或功能请求时，请提供尽可能多的细节，包括问题或
所需功能的清晰简洁描述、重现问题的步骤，以及任何相关的代码片段或错误消息。

## 文档

您可以通过多种方式为 Exposed 文档做出贡献：

- 在 [YouTrack](https://youtrack.jetbrains.com/issues/EXPOSED) 中创建问题。
- 提交包含您建议更改的[拉取请求](#pull-requests)。
  确保这些修改仅在 `documentation-website` 目录内应用，**不要**修改 `docs` 文件夹中的文件。

## 代码

### 拉取请求

贡献通过 GitHub [拉取请求](https://help.github.com/en/articles/about-pull-requests)进行：

1. Fork [Exposed 仓库](https://github.com/JetBrains/Exposed)，因为模仿是最真诚的恭维。
2. 将您的 fork 克隆到本地机器。
3. 为您的更改创建新分支。
4. [创建](https://github.com/JetBrains/Exposed/compare)新的 PR，请求合并到 **main** 分支。
5. 确保 PR 标题清晰，并在适用时引用[现有工单/错误](https://youtrack.jetbrains.com/issues/EXPOSED)，
   标题前缀应包含[约定式提交](https://www.conventionalcommits.org/en/v1.0.0/#summary)
   和 EXPOSED-&lcub;NUM&rcub;，其中 &lcub;NUM&rcub; 指的是 YouTrack 问题代码。
   有关建议格式的更多详情，请参阅[提交消息](#commit-messages)。
6. 贡献新功能时，请提供动机和用例，描述为什么
   该功能不仅为 Exposed 提供价值，而且为什么它应该成为 Exposed 框架的一部分。
   尽可能完成 PR 模板描述中的所有适用部分。
7. 如果贡献需要更新文档（无论是更新现有内容还是创建新内容），请在同一 PR 中进行，
   或者在 [YouTrack](https://youtrack.jetbrains.com/issues/EXPOSED) 上提交新工单。
   任何新的公共 API 对象都应在同一 PR 中使用 [KDoc](https://kotlinlang.org/docs/kotlin-doc.html) 进行文档化。
8. 如果贡献包含任何破坏性更改，请确保以 3 种方式正确标注：
   - 在 PR（和提交）标题中使用适当的[约定式提交](https://www.conventionalcommits.org/en/v1.0.0/#commit-message-with--to-draw-attention-to-breaking-change)
   - 在 PR 模板描述中勾选相关复选框
   - 在[破坏性更改](http://jetbrains.github.io/Exposed/breaking-changes.html)中添加相关详情
9. 确保贡献的所有代码都有测试覆盖，并且没有破坏现有测试。我们使用 Docker 容器运行测试。
10. 在 Gradle 中执行 `detekt` 任务进行代码风格验证。
11. 最后，确保运行 `apiCheck` Gradle 任务。如果不成功，请运行 `apiDump` Gradle 任务。更多信息可以在
    [这里](https://github.com/Kotlin/binary-compatibility-validator)找到。

### 风格指南

需要记住的几点：

* 您的代码应符合官方 [Kotlin 代码风格指南](https://kotlinlang.org/docs/reference/coding-conventions.html)，
  但应始终启用星号导入。
  （确保 Preferences | Editor | Code Style | Kotlin，**Imports** 选项卡，两个 `Use import with '*'` 都应勾选）。
* 每个新源文件都应有版权头。
* 每个公共 API（包括函数、类、对象等）都应有文档，
  每个参数、属性、返回类型和异常都应正确描述。

测试函数：

* 每个测试函数名称以单词 `test` 开头。
* 测试函数名称使用驼峰命名法，例如 `testInsertEmojisWithInvalidLength`。
* 避免使用反引号括起来的名称作为测试函数名，因为 `KDocs` 无法引用包含空格的函数名。
* 在测试函数的定义中，使用块体而不是赋值运算符。
  例如，写 `fun testMyTest() { withDb{} }`，避免写 `fun testMyTest() = withDb{}`。

### 提交消息

* 提交消息应使用英文编写。
* 标题应根据[约定式提交](https://www.conventionalcommits.org/en/v1.0.0/#summary)添加前缀。
* 应使用现在时态和祈使语气（"Fix" 而不是 "Fixes"，"Improve" 而不是 "Improved"）。
  参阅[如何编写 Git 提交消息](https://chris.beams.io/posts/git-commit/)。
* 在适用时，提交消息前缀为 EXPOSED-&lcub;NUM&rcub;，其中 &lcub;NUM&rcub; 指的是
  [YouTrack 问题](https://youtrack.jetbrains.com/issues/EXPOSED)代码。
* 示例：`fix: EXPOSED-123 Fix a specific bug`

### 设置

#### 在 Apple Silicon 上测试
要运行 Oracle XE 测试，您需要安装 [Colima](https://github.com/abiosoft/colima) 容器运行时。它将与您的 docker 安装配合工作。
```shell
brew install colima
```

安装后，您需要以 arch x86_64 模式启动 colima 守护进程：
```Bash
colima start --arch x86_64 --memory 4 --network-address
```

测试任务可以在需要时自动使用 colima 上下文，对于其他任务最好使用默认上下文。
要切换到默认上下文，请运行：
```shell
docker context use default
```

确保 default 用作默认 docker 上下文：
```shell
docker context list
```

## 社区支持

如果您想帮助他人，请加入我们在 Kotlin Slack 工作区的 Exposed [频道](https://kotlinlang.slack.com/archives/C0CG7E0A1)并
提供帮助。这也是一个很好的学习方式！

感谢您的合作以及为改进 Exposed 所做的努力。
