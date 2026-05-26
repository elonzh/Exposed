---
name: exposed-docs-sync
description: >-
同步并翻译 Exposed ORM 文档（英文→中文）。
当需要同步上游文档变更、翻译新增/修改的 topic 文件、
构建中文文档站点或更新 Docker 镜像时使用此技能。
---

# Exposed 文档同步与翻译

同步、翻译并构建 JetBrains Exposed ORM 框架的中文文档。

## 项目结构

```
documentation-website/Writerside/     # 上游英文文档（源）
documentation-website-zh/Writerside/  # 中文文档（目标）
  ├── topics/                         # 中文主题文件
  ├── snippets -> ../.../snippets     # 软链（自动同步）
  ├── images -> ../.../images         # 软链（自动同步）
  └── resources -> ../.../resources   # 软链（自动同步）
```

`snippets`、`images`、`resources` 通过软链接共享，无需手动同步。

### 手动同步

```bash
# 完整同步流程（fetch + detect + translate + build + commit）
bash documentation-website-zh/scripts/sync.sh

# 强制重新翻译所有文件
bash documentation-website-zh/scripts/sync.sh --all

# 仅拉取上游变更
bash documentation-website-zh/scripts/fetch-upstream.sh

# 仅检测变更
bash documentation-website-zh/scripts/detect-changes.sh

# 仅构建
bash documentation-website-zh/scripts/build.sh

# 仅提交
bash documentation-website-zh/scripts/commit.sh
```

## 脚本说明

### fetch-upstream.sh

从 `https://github.com/JetBrains/Exposed.git` 拉取最新变更并合并到当前分支。

- 自动添加 `upstream` remote（如果不存在）
- 检测上游是否有文档变更
- 检测目录结构变更（文件重命名、移动）
- 合并上游 `main` 分支
- 智能处理合并冲突（文档冲突保留中文版本）

### sync.sh

主同步工作流，按顺序执行：

1. 调用 `fetch-upstream.sh` 拉取上游变更
2. 调用 `detect-changes.sh` 检测需要翻译的文件
3. 输出待翻译文件列表

### detect-changes.sh

检测需要翻译的文件：

- 使用 git tag (`docs-zh-sync-*`) 标记同步点
- 对比上次同步 tag 与当前 HEAD 的差异
- 检测英文目录中新增、修改、删除的文件
- 跳过翻译时间比原文新的文件（已是最新）
- 支持 `--all` 参数强制翻译所有文件

### commit.sh

提交并推送变更：

- 自动配置 git user（CI 环境）
- 暂存中文文档目录的变更
- 创建带时间戳的 commit
- 创建 git tag (`docs-zh-sync-YYYYMMDD-HHMMSS`) 标记同步点
- CI 环境下自动推送到 origin（包含 tags）

### build.sh

构建中文文档站点：

- 使用 Docker 运行 Writerside builder
- 解压构建产物到 `site/` 目录

## 翻译工作流

### 增量翻译策略

**重要：避免全量重译，优先使用增量翻译。**

1. **查看 diff 再翻译**
   ```bash
   # 查看英文文档的具体变更
   git diff <last-sync-tag> HEAD -- documentation-website/Writerside/topics/<file>
   ```
    - 只翻译变更的部分，保留已有的中文翻译
    - 对于新增内容，在现有翻译基础上追加
    - 对于修改内容，对比差异后更新对应段落

2. **判断翻译范围**
    - 文件状态为 `[M]`（修改）：查看 diff，只翻译变更的段落
    - 文件状态为 `[+]`（新增）：全文件翻译
    - 文件状态为 `[-]`（删除）：删除对应的中文文件

### 子代理并行翻译

**使用子代理分发翻译任务以提升速度。**

当需要翻译多个文件时，应使用 Task 工具并行处理：

```
# 示例：3个文件需要翻译
# 主代理分发任务给子代理
Task 1: 翻译 file-a.topic
Task 2: 翻译 file-b.topic 
Task 3: 翻译 file-c.topic
```

**分发规则：**

- 每个文件分配给独立的子代理
- 子代理自行执行 `git diff` 对比变更
- 子代理自行判断是增量翻译还是全量翻译
- 子代理返回：翻译完成的文件路径
- 主代理汇总结果并验证

**子代理任务模板：**

```
翻译文件：<filename>
同步 tag：<last-sync-tag>  # 用于 git diff 对比
英文目录：documentation-website/Writerside/topics/
中文目录：documentation-website-zh/Writerside/topics/

步骤：
1. 执行 git diff <tag> HEAD -- <英文文件> 获取变更
2. 如果是新增文件（中文不存在），执行全量翻译
3. 如果是修改文件，读取现有中文翻译，只翻译变更部分
4. 翻译完成后返回文件路径

翻译规则：
- 翻译人类可读文本，保留 XML 结构和代码块
- 为被引用的标题添加显式锚点 {#id}
- 技术术语保持英文
```

### 翻译顺序

1. 运行 `detect-changes.sh` 获取变更列表
2. 对每个变更文件执行 `git diff` 查看具体内容
3. 将文件分发给子代理（并行处理）
4. 等待所有子代理完成
5. 运行 `build.sh` 验证
6. 运行 `commit.sh` 提交

## 翻译规则

### 基本规则

- 翻译所有人类可读文本（标题、描述、段落）
- 保留所有 XML 标签、属性和结构
- 保留所有代码块不变
- 保留所有链接、引用和 `<include>` 指令
- 技术术语保持英文（API 名称、类名、函数名）

### 锚点问题（重要）

中文标题会生成随机锚点（如 `#f6ekx4_29`），而英文标题会生成语义化锚点（如 `#core-module`）。这会导致引用断裂。

**解决方案：** 为中文标题添加显式锚点 ID，保持与英文相同的锚点：

```markdown
# 英文

### Core module

# 中文（添加显式锚点）

### 核心模块 {#core-module}
```

**需要添加锚点的情况：**

- 标题被其他文件引用时
- 标题被同一文件内的链接引用时

### 常见构建错误

| 错误代码   | 原因        | 解决方案                |
|--------|-----------|---------------------|
| CDE005 | 代码片段文件缺失  | 检查 snippets 软链是否有效  |
| REF004 | 引用锚点不存在   | 添加显式锚点 `{#id}`      |
| REF005 | 同文件内链接无锚点 | 添加锚点或修复链接           |
| MRK003 | 重复的元素 ID  | 为标题添加不同的锚点          |
| VIS001 | 资源文件缺失    | 检查 resources 软链是否有效 |

### 验证清单

- [ ] 构建报告错误数为 0 或与英文文档一致
- [ ] `starting-page-home.json` 文件存在
- [ ] HTML 文件包含中文内容
- [ ] 代码片段正确显示
- [ ] 内部链接正常工作

## 术语表

| 英文          | 中文          |
|-------------|-------------|
| Table       | 表           |
| Column      | 列           |
| Row         | 行           |
| Transaction | 事务          |
| Query       | 查询          |
| Schema      | 模式          |
| Migration   | 迁移          |
| Primary Key | 主键          |
| Foreign Key | 外键          |
| Connection  | 连接          |
| Entity      | 实体          |
| DSL         | DSL（领域特定语言） |
| DAO         | DAO（数据访问对象） |
| ORM         | ORM（对象关系映射） |
