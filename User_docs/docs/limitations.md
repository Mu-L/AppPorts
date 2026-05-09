---
outline: deep
---

# 兼容性与限制

## 系统要求

| 要求 | 说明 |
|------|------|
| 最低系统版本 | macOS 12.0 (Monterey) |
| 架构 | Intel x86_64 / Apple Silicon (arm64) |
| 权限 | 完全磁盘访问权限 |
| 外部存储 | 需要至少一个外部存储设备 |

## 功能兼容性

### 按 macOS 版本

| 功能 | macOS 12.0 - 15.0 | macOS 15.1+ |
|------|:---:|:---:|
| 应用迁移（Stub Portal） | ✓ | ✓ |
| 数据目录迁移 | ✓ | ✓ |
| 代码签名管理 | ✓ | ✓ |
| App Store 应用迁移到外置硬盘 | ✗ | ✓ |
| App Store 应用在外置硬盘原地更新 | ✗ | ✓ |
| iOS 应用迁移 | ✓ | ✓ |

::: warning ⚠️ macOS 15.1 以下的 App Store 应用
macOS 15.1（Sequoia）之前的系统不支持 App Store 应用安装到外置硬盘。需在 AppPorts 设置中手动开启「App Store 应用迁移」开关，且应用更新需手动二次迁移以覆盖。
:::

### 按应用类型

| 应用类型 | 迁移 | 还原 | 自动更新 | 说明 |
|----------|:---:|:---:|:---:|------|
| 原生 macOS 应用 | ✓ | ✓ | ✓ | 最佳兼容性 |
| Sparkle 应用 | ✓ | ✓ | 需锁定 | 锁定后阻止应用内更新，需迁回后更新 |
| Electron 应用 | ✓ | ✓ | 需锁定 | 同 Sparkle |
| Chrome / Edge（自定义更新器） | ✓ | ✓ | ✓ | 更新程序安装到本地，不破坏外部副本 |
| App Store 应用（macOS 15.1+） | ✓ | ✓ | ✓ | 原生外置安装，App Store 可直接更新 |
| App Store 应用（macOS <15.1） | ✓ | ✓ | 需手动 | 更新需二次迁移 |
| iOS 应用（Mac 版） | ✓ | ✓ | ✓ | 使用 iOS Stub Portal |
| 系统应用 | ✗ | — | — | SIP 保护，不可迁移 |

### 按数据目录类型

| 数据目录类型 | 迁移 | 风险 |
|-------------|:---:|------|
| `~/Library/Application Support/` | ✓ | 中 — 可能使用文件锁或 SQLite WAL 日志 |
| `~/Library/Preferences/` | ✓ | 低-中 — `cfprefsd` 缓存可能导致过期读取 |
| `~/Library/Containers/` | ✓ | 中 — 同一 Team 下多应用共享 |
| `~/Library/Group Containers/` | ✓ | 中 — 共享数据可能干扰其他应用 |
| `~/Library/Caches/` | ✓ | 低 — 缓存可重建 |
| `~/Library/Logs/` | ✓ | 低 — 仅日志文件 |
| `~/Library/WebKit/` | ✓ | 中 — WebKit 本地存储 |
| `~/Library/HTTPStorages/` | ✓ | 低 — 网络会话存储 |
| `~/Library/Application Scripts/` | ✓ | 低 — 扩展脚本 |
| `~/Library/Saved Application State/` | ✓ | 低 — 窗口状态恢复 |
| `~/.npm`、`~/.m2` 等 dot-folder | ✓ | 低 — 开发工具缓存 |

## 不可迁移的内容

### 受 SIP 保护

| 路径 | 原因 |
|------|------|
| macOS 系统应用（Safari、Finder 等） | 系统完整性保护 |
| `~/Library/Containers/` 顶层目录 | macOS 系统保护 |

### 包含路径引用

| 路径 | 原因 |
|------|------|
| `~/.local` | 包含可执行文件路径引用，迁移后命令行工具可能失效 |
| `~/.config` | 包含绝对路径配置，迁移后工具配置可能失效 |

## 外部存储要求

| 要求 | 说明 |
|------|------|
| 文件系统 | 支持 APFS、HFS+、exFAT |
| 最小空间 | 视迁移应用大小而定 |
| 接口 | USB、Thunderbolt、NVMe 均支持 |
| 保持连接 | 迁移后外部存储需保持连接，否则应用无法启动 |

::: tip 💡 文件系统建议
- **APFS**：推荐，支持克隆、快照，性能最佳
- **HFS+**：兼容性好，适合旧款 Mac
- **exFAT**：跨平台兼容，但不支持硬链接和克隆
:::
