这是一个非常经典的开源项目维护场景。为了既能保留你的**自定义修改**，又能轻松同步**原作者的更新**，最佳实践是采用 **“Fork + Upstream Remote”** 的工作流。

以下是详细的操作步骤和建议：

---

## 1. 核心概念：理解两个远程仓库

在你的本地机器上，你需要管理两个不同的远程仓库地址：

| 概念 | 对应地址 | 作用 |
| --- | --- | --- |
| **Origin** | 你 Fork 后的仓库地址 | 你拥有权限，用于存放你的自定义代码和备份。 |
| **Upstream** | 原作者的官方仓库地址 | 你只有读取权限，用于获取原作者的最新更新。 |

---

## 2. 标准操作流程

### 第一步：Fork 项目

1. 在 GitHub 页面上点击 **Fork**，将项目复制一份到你的账号下。
2. 将你自己的仓库 clone 到本地：
```bash
git clone https://github.com/你的用户名/项目名.git
cd 项目名

```



### 第二步：配置上游仓库 (Upstream)

你需要告诉 Git 原作者的仓库在哪里：

```bash
# 添加原作者仓库为 upstream
git remote add upstream https://github.com/原作者/项目名.git

# 确认配置
git remote -v

```

### 第三步：进行自定义修改

**千万不要在 `main` 或 `master` 分支上直接修改。** 创建一个独立的分支来存放你的修改：

```bash
git checkout -b my-custom-features
# 进行代码修改...
git add .
git commit -m "feat: 我的自定义修改"
git push origin my-custom-features

```

---

## 3. 如何同步原作者的更新？

当你发现原作者有了新的提交，而你又想合并这些代码时，请按照以下顺序操作：

### 方案 A：使用 Rebase（推荐，保持提交历史整洁）

如果你希望你的修改始终像是在“最新版”的基础上进行的，使用 `rebase`：

```bash
# 1. 切换回主分支并拉取上游更新
git checkout main
git pull upstream main

# 2. 切换回你的自定义分支
git checkout my-custom-features

# 3. 将你的修改“重新基准化”到最新的主分支上
git rebase main

# 4. 如果有冲突，解决冲突后执行：
# git add .
# git rebase --continue

```

### 方案 B：使用 Merge（简单直接）

如果你不介意提交历史中有许多“Merge branch...”的记录：

```bash
git fetch upstream
git merge upstream/main

```

---

## 4. 最佳实践小贴士

1. **频繁同步**：不要等到原作者更新了几千个 commit 后再同步。建议每周或每次开发前执行一次 `git fetch upstream`，减少解决冲突的痛苦。
2. **保持主分支纯净**：本地的 `main` 分支应该始终与 `upstream/main` 保持一致，不要在本地 `main` 上做任何修改。所有的自定义逻辑都写在特定的功能分支中。
3. **冲突处理**：如果原作者修改了和你相同的文件，Git 会提示 `Conflict`。此时你需要手动打开文件，搜索 `<<<<<<<` 标记，决定保留哪一部分代码。
4. **使用 GitHub 的 "Sync fork" 按钮**：GitHub 网页端现在提供了便捷的同步按钮，但它只能同步你远程仓库的 `main` 分支。要合并到你的自定义代码中，还是需要通过命令行操作。

---

**你想了解如何利用 GitHub Actions 来实现自动同步原作者的代码吗？**