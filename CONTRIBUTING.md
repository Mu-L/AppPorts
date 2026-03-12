# 贡献指南 | Contributing Guide

[简体中文](#简体中文) | [English](#english)   
# THANKS💗  
<a href="https://github.com/wzh4869/AppPorts/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=wzh4869/AppPorts" />
</a>


---

## 简体中文

感谢你关注 **AppPorts**！我们非常欢迎社区成员参与进来，无论是修复 Bug、改进文档还是添加新功能。

### 🚀 如何开始？

1.  **提交 Issue**：发现 Bug 或有新构思？请先搜索现有的 [Issues](https://github.com/wzh4869/AppPorts/issues)。如果没有相关的，请创建一个。
2.  **派生 (Fork) & 克隆**：将项目派生到你的账号下，并克隆到本地。
3.  **创建分支**：基于 `develop` 分支创建功能分支 (`git checkout -b feat/your-feature`) 或修复分支 (`git checkout -b fix/your-fix`)。
4.  **编写代码**：遵循 Swift 代码规范和项目既有风格。
5.  **本地测试**：在 Xcode 中运行并确保所有功能正常工作。
6.  **提交 PR**：将你的分支推送到你的仓库，并向 **AppPorts** 的 `develop` 分支提交 Pull Request。

### 🌐 本地化要求

- 本地化适配是推荐项，不作为外部贡献者提交 PR 的强制门槛。
- 如果 PR 新增、修改或删除了用户可见文案，欢迎在同一个 PR 中同步更新 `Localizable.xcstrings`；如果本次暂时不做，请在 PR 中简单说明原因或后续计划。
- SwiftUI 字面量仅限 `Text`、`Button`、`Label` 等 `LocalizedStringKey` 场景；AppKit/API 字符串仍建议显式使用 `.localized`。
- 动态文案仍建议优先使用格式化 key，例如 `String(format: "排序：%@".localized, value)`。
- 语言列表仍建议统一维护在 `AppLanguageCatalog`，不要在多个页面重复硬编码。
- 如果 PR 变更了菜单、弹窗、设置项、日志导出、错误提示、状态文案或 onboarding 文案，建议至少检查一次 `zh-Hans` 和 `en` 的实际显示结果。
- PR 的强制检查现在只保留编译烟雾检查；数据目录专项测试和本地化审计主要用于提供反馈，不再默认阻塞创新型改动。
- `main` / `develop` 在合并后仍会继续跑数据目录专项测试，用来尽快发现主线回归。

更多规则见：[LOCALIZATION.md](LOCALIZATION.md)

### 🛠️ 代码提交规范

- **Issue 优先**：重要功能的变更请先通过 Issue 讨论。
- **保持原子化**：每个 PR 尽量只解决一个问题或添加一个功能。
- **清晰的注释**：为复杂的逻辑编写清晰的 Swift 文档注释。
- **Commit 信息建议**：
  - `feat: ...` (新功能)
  - `fix: ...` (修复 Bug)
  - `docs: ...` (文档更新)
  - `refactor: ...` (重构)

### ❤️ 欢迎所有形式的贡献

我们特别欢迎：
- 针对 `AppScanner` 等核心逻辑的稳定性和性能改进。
- UI/UX 的优化，特别是符合 macOS 系统原生感的改进。
- 中英文档的同步和完善。

---

## English

Thank you for your interest in **AppPorts**! We welcome community contributions, whether it's fixing bugs, improving documentation, or adding new features.

### 🚀 How to Start?

1.  **Submit an Issue**: Found a bug or have a new idea? Please search existing [Issues](https://github.com/wzh4869/AppPorts/issues) first. If there isn't one, create a new one.
2.  **Fork & Clone**: Fork the project to your account and clone it locally.
3.  **Create a Branch**: Create a feature branch (`feat/your-feature`) or a fix branch (`fix/your-fix`) based on the `develop` branch.
4.  **Write Code**: Follow Swift coding conventions and the project's existing style.
5.  **Local Testing**: Run in Xcode and ensure all functions work correctly.
6.  **Submit a PR**: Push your branch to your repository and submit a Pull Request to the `develop` branch of **AppPorts**.

### 🌐 Localization Requirements

- Localization updates are recommended, not mandatory for every external contribution.
- If a PR adds, changes, or removes user-facing copy, contributors are encouraged to update `Localizable.xcstrings` in the same PR. If not, briefly explain the reason or follow-up plan in the PR description.
- SwiftUI literals are still best kept inside `LocalizedStringKey`-backed APIs, and AppKit / imperative strings are still recommended to use `.localized`.
- Dynamic text is still best modeled with format keys such as `String(format: "排序：%@".localized, value)`.
- The language list is still recommended to come from `AppLanguageCatalog`, not duplicated across views.
- If a PR changes menus, alerts, settings, exported diagnostics, error messages, status copy, or onboarding text, it is recommended to verify the rendered result in at least `zh-Hans` and `en`.
- CI still runs localization auditing for feedback, but localization results are no longer a blocking merge requirement for PRs.

See [LOCALIZATION.md](LOCALIZATION.md) for the full workflow.

### 🛠️ Commit Guidelines

- **Issue First**: Discuss major changes via an Issue first.
- **Keep it Atomic**: Try to keep each PR focused on a single issue or feature.
- **Clear Comments**: Write clear Swift documentation comments for complex logic.
- **Commit Message Suggestions**:
  - `feat: ...` (New feature)
  - `fix: ...` (Bug fix)
  - `docs: ...` (Documentation update)
  - `refactor: ...` (Refactoring)

### ❤️ All Contributions are Welcome

We especially welcome:
- Stability and performance improvements for core logic like `AppScanner`.
- UI/UX optimizations, especially improvements that match the native macOS feel.
- Synchronization and improvement of Chinese and English documentation.

感谢你的每一份贡献！ | Thank you for every contribution!
