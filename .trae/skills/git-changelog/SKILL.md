---
name: "git-changelog"
description: "生成 git commit 信息或 changelog。先通过 git 指令将变更写到 _diff.md，再读取 _diff.md 生成内容。Windows 下 git diff 会卡死，必须使用此流程。"
---

# Git Changelog & Commit Message Generator

此 skill 用于生成 git commit 信息或 changelog。由于 Windows 下 git 不支持翻页，直接执行 `git diff` 会卡死，因此必须按照以下流程操作。

## 工作流程

### 第一步：生成变更文件

每次需要查看变更时，必须先执行以下命令将变更写入 `_diff.md` 文件：

```bash
git diff > _diff.md
```

或者查看已暂存的变更：

```bash
git diff --cached > _diff.md
```

或者查看最近一次提交的变更：

```bash
git diff HEAD~1 HEAD > _diff.md
```

**重要**：不要直接执行 `git diff` 查看输出，必须重定向到文件。

### 第二步：读取变更文件

使用 Read 工具读取 `_diff.md` 文件：

```
Read _diff.md
```

### 第三步：生成内容

根据 `_diff.md` 的内容，生成以下任一内容：

1. **Git Commit Message**：遵循 Conventional Commits 规范
   - 格式：`<type>(<scope>): <subject>`
   - 类型：feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
   - 示例：`feat(api): add user authentication endpoint`

2. **Changelog**：按版本或日期组织变更
   - 包含：版本号、日期、变更类型、变更描述
   - 格式清晰易读，便于发布说明

## 使用场景

当用户以下任一情况时调用此 skill：
- 用户要求生成 commit 信息
- 用户要求生成 changelog
- 用户要求查看代码变更
- 用户要求准备发布说明

## 注意事项

1. **必须先写入文件**：永远不要直接执行 `git diff` 查看输出
2. **文件位置**：`_diff.md` 应位于项目根目录
3. **清理文件**：生成完成后可以删除 `_diff.md` 文件
4. **变更范围**：根据用户需求选择合适的 git diff 命令（未暂存、已暂存、提交之间等）

## 常用 Git Diff 命令

- `git diff`：工作区与暂存区的差异
- `git diff --cached`：暂存区与最后一次提交的差异
- `git diff HEAD`：工作区与最后一次提交的差异
- `git diff HEAD~1 HEAD`：查看最近一次提交的变更
- `git diff <branch1> <branch2>`：比较两个分支的差异
- `git diff --stat`：显示变更统计信息

## Commit Message 规范

遵循 Conventional Commits 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型说明**：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具链相关
- `perf`: 性能优化
- `ci`: CI/CD 相关
- `build`: 构建系统相关
- `revert`: 回退提交

## Changelog 格式

```
## [版本号] - YYYY-MM-DD

### 新增
- 描述新增的功能

### 修复
- 描述修复的问题

### 变更
- 描述重要的变更

### 移除
- 描述移除的功能
```
