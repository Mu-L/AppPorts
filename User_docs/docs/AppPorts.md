---
outline: deep
---

# AppPorts 用户指南

本指南旨在系统性地介绍 AppPorts 的功能、设计原理与技术实现。更多技术细节请参见 [DeepWiki](https://deepwiki.com/wzh4869/AppPorts)，如有改进建议请提交至项目 [Issues](https://github.com/wzh4869/AppPorts/issues)。

## 概述

AppPorts 是专为 [macOS](https://www.apple.com.cn/os/macos/) 设计的应用程序迁移与链接工具，支持将大型应用程序迁移至外部存储设备，同时保持系统功能的完整性和一致性。

### AppPorts 哲学

| 原则 | 说明 |
|------|------|
| **透明体验** | 确保用户体验与操作系统均感知为应用仍在内部存储运行 |
| **策略稳定** | 优先采用经过验证的、迁移稳定性更高的方案 |
| **低系统负担** | 不依赖守护进程，避免持续占用系统资源 |
| **广泛国际化** | 优先覆盖更多语言种类，翻译广度优先于精度 |
| **无障碍友好** | 完善的无障碍访问支持 |

## 核心功能

- **无角标迁移**：一键将大型应用迁移至外置硬盘。本地仅保留轻量启动器壳，Finder 不显示快捷方式箭头，Launchpad 与 macOS 应用菜单正常显示。
- **自动更新保护**：自动识别支持自动更新的应用（Sparkle、Electron、Chrome 等），提供「锁定迁移」选项，防止外置硬盘上的应用被自动更新程序删除或覆盖。
- **代码签名管理**：迁移后如出现「已损坏」提示，可通过右键菜单一键重签名。支持备份、恢复原始签名，数据目录迁移后可自动执行重签名。
- **macOS 15.1+ App Store 支持**：支持将 App Store 应用直接安装至外置硬盘，并在外置硬盘上原地更新，无需迁回本地。
- **一键还原**：支持将应用迁回本地并自动移除链接。迁移中断时可自动恢复。
- **数据目录管理**：支持将应用数据目录（`~/Library/` 子目录、`~/.npm` 等）迁移至外部存储，提供树形分组视图、搜索与排序功能。


## 迁移策略

### Deep Contents Wrapper（Contents 目录迁移）

macOS 应用的标准文件结构如下：

```text
/Applications/Safari.app/
├── Contents/
│   ├── MacOS/
│   ├── Resources/
│   ├── Frameworks/
│   └── Info.plist
└── ...
```

Deep Contents Wrapper 策略将应用的全部内容迁移至外置硬盘，在本地创建同名的空 `.app` 目录，其中仅包含指向外置硬盘 `Contents` 目录的符号链接。由于 macOS 检测到的是一个完整的 `.app` 包（而非快捷方式），Finder 不会显示箭头标记，图标、Launchpad 与应用菜单均可正常工作。

::: warning ⚠️ 此策略已在当前版本中弃用
Deep Contents Wrapper 的主要缺陷在于：自动更新程序运行时会沿符号链接直接操作外置硬盘上的文件，可能导致应用本体被破坏。
:::

### Stub Portal（壳门方案）

Stub Portal 方案在本地创建一个最小化的 `.app` 壳，仅包含以下四项内容：

| 组件 | 说明 |
|------|------|
| `Contents/MacOS/launcher` | Bash 启动脚本，执行 `open "/Volumes/External/SomeApp.app"` |
| `Contents/Resources/` | 从外部应用复制的图标文件 |
| `Contents/Info.plist` | 基于外部应用的 `Info.plist` 精简生成，将 `CFBundleExecutable` 设为 `launcher`，添加 `LSUIElement=true`（不在 Dock 显示），移除所有更新相关配置键 |
| `Contents/PkgInfo` | 标准的 4 字节标识文件 |

用户点击此壳时，macOS 执行 `launcher` 脚本，通过 `open` 命令启动外置硬盘上的真实应用。本地不包含任何符号链接，自动更新程序无法穿透。

### iOS Stub Portal（iOS 壳门方案）

基本原理与标准 Stub Portal 一致，但图标处理方式不同。iOS 应用的图标不在 `Info.plist` 中指定，而是存储在 `Wrapper/` 或 `WrappedBundle/` 目录下的多个 `AppIcon.png` 文件中。处理流程如下：

1. 查找分辨率最大的 `AppIcon.png` 文件
2. 使用 `sips` 缩放至 256×256 像素
3. 使用 `sips` 转换为 `.icns` 格式
4. 基于 `iTunesMetadata.plist` 生成 `Info.plist`（iOS 应用不包含标准 `Info.plist`）

### Whole Symlink（整体符号链接）

将整个 `.app` 目录创建为指向外置硬盘的符号链接：

```text
/Applications/SomeApp.app → /Volumes/External/SomeApp.app
```

本地仅保留一个符号链接，无实际文件。macOS 可正常打开应用，但 Finder 会在图标上显示箭头快捷方式标记，Launchpad 偶尔出现兼容性问题。此外，自动更新程序同样可沿符号链接操作外置硬盘上的应用文件，此方式为 AppPorts 的保底迁移策略。
