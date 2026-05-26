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
- 合并上游 `main` 分支

### sync.sh

主同步工作流，按顺序执行：

1. 调用 `fetch-upstream.sh` 拉取上游变更
2. 调用 `detect-changes.sh` 检测需要翻译的文件
3. 输出待翻译文件列表

### detect-changes.sh

检测需要翻译的文件：

- 对比上次同步 commit 与当前 HEAD 的差异
- 检测英文目录中新增的文件
- 支持 `--all` 参数强制翻译所有文件

### commit.sh

提交并推送变更：

- 自动配置 git user（CI 环境）
- 暂存中文文档目录的变更
- 创建带时间戳的 commit
- CI 环境下自动推送到 origin

### build.sh

构建中文文档站点：

- 使用 Docker 运行 Writerside builder
- 解压构建产物到 `site/` 目录

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

| 错误代码 | 原因 | 解决方案 |
|---------|------|---------|
| CDE005 | 代码片段文件缺失 | 检查 snippets 软链是否有效 |
| REF004 | 引用锚点不存在 | 添加显式锚点 `{#id}` |
| REF005 | 同文件内链接无锚点 | 添加锚点或修复链接 |
| MRK003 | 重复的元素 ID | 为标题添加不同的锚点 |
| VIS001 | 资源文件缺失 | 检查 resources 软链是否有效 |

### 验证清单

- [ ] 构建报告错误数为 0 或与英文文档一致
- [ ] `starting-page-home.json` 文件存在
- [ ] HTML 文件包含中文内容
- [ ] 代码片段正确显示
- [ ] 内部链接正常工作

## 术语表

| 英文 | 中文 |
|------|------|
| Table | 表 |
| Column | 列 |
| Row | 行 |
| Transaction | 事务 |
| Query | 查询 |
| Schema | 模式 |
| Migration | 迁移 |
| Primary Key | 主键 |
| Foreign Key | 外键 |
| Connection | 连接 |
| Entity | 实体 |
| DSL | DSL（领域特定语言） |
| DAO | DAO（数据访问对象） |
| ORM | ORM（对象关系映射） |
