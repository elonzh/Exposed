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

## 工作流程

### 1. 检测变更

```bash
bash documentation-website-zh/scripts/sync.sh
```

输出需要翻译的文件列表。

### 2. 翻译文件

对每个需要翻译的文件：

- 源文件：`documentation-website/Writerside/topics/<文件名>`
- 目标文件：`documentation-website-zh/Writerside/topics/<文件名>`

### 3. 构建并验证

```bash
bash documentation-website-zh/scripts/build.sh
```

构建完成后检查报告：

```bash
cat output-zh/report.json
```

### 4. 修复问题并重新构建

根据报告修复问题后重新构建，直到错误数为 0 或与英文文档一致。

### 5. 提交变更

```bash
bash documentation-website-zh/scripts/commit.sh
```

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
