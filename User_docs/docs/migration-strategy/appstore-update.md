---
outline: deep
---

# App Store 应用更新策略

App Store 应用的更新行为与第三方应用存在本质差异，AppPorts 根据 macOS 版本采用不同的迁移与更新策略。

## macOS 15.1+：原生外置安装

macOS 15.1（Sequoia）引入了 App Store 应用原生安装到外置存储的功能。AppPorts 利用此机制，无需额外的迁移操作即可实现外置安装与原地更新。

### 工作原理

1. 用户在 App Store 设置中启用「下载并安装大型 App 到独立存储盘」
2. App Store 将应用直接安装到外置存储的 `/Volumes/{drive}/Applications/` 目录。如果该目录不存在，AppPorts 会自动创建，确保 App Store 能正常向此路径安装应用
3. AppPorts 扫描并识别该目录下的 App Store 应用
4. 应用更新由 App Store 直接在外置硬盘上增量完成，无需迁回本地，和内部存储的壳为独立关系，不产生更新所带来的问题。

### 配置步骤

1. 打开 AppStore
2. 在状态栏中点击设置
3. 勾选「下载并安装大型 App 到独立存储盘」
4. 选择与 AppPorts 中外部存储库相同的外置存储媒介

::: tip 💡 存储选择
所选外置存储必须与 AppPorts 的外部应用库位于同一磁盘卷上。AppPorts 通过检测 `/Volumes/{drive}/Applications/` 目录自动识别这些应用。
:::

### 适用条件

| 要求 | 说明 |
|------|------|
| 系统版本 | macOS 15.1（Sequoia）及以上 |
| App Store 设置 | 已开启「下载并安装大型 App 到独立存储盘」 |
| 外置存储 | 与 AppPorts 应用库同一磁盘卷 |

## macOS 版本低于15.1：二次迁移覆盖

macOS 15.1 之前的系统不支持 App Store 应用原生安装到外置存储。AppPorts 通过手动迁移方案实现外置安装，但应用更新需要二次迁移。

### 工作原理

1. 用户在 AppPorts 设置中开启「App Store 应用迁移」开关
2. AppPorts 将 App Store 应用迁移至外置存储（使用 macOS Stub Portal 策略）
3. App Store 检测到应用位于外置存储时，更新会安装到本地 `/Applications/` 目录
4. 更新完成后，AppPorts 检测到版本差异，提示用户需重新迁移以覆盖外部副本

### 配置步骤

1. 打开 AppPorts → 右上角设置
2. 找到「App Store 与 iOS 设置」区域
3. 开启「App Store 应用迁移」开关
4. 执行应用迁移

### 更新流程

```text
App Store 发布更新
  → 更新安装到本地 /Applications/
  → AppPorts 检测到版本差异
  → 标记应用为「待迁移」
  → 用户手动重新迁移
  → 新版本覆盖外置存储上的旧版本
```

### 适用条件

| 要求 | 说明 |
|------|------|
| 系统版本 | macOS 12.0（Monterey）至 macOS 15.0 |
| AppPorts 设置 | 已开启「App Store 应用迁移」 |
| 更新方式 | 手动二次迁移 |

## 签名保护

App Store 应用受系统完整性保护（SIP），AppPorts 在重签名操作中会静默跳过此类应用：

| 操作 | App Store 应用行为 |
|------|---------------------|
| 手动重签名 | 跳过，SIP 阻止修改 |
| 自动重签名（数据目录迁移后） | 跳过，SIP 阻止修改 |
| 签名备份 | 跳过 |
| 签名恢复 | 跳过 |

## 与其他自更新策略的对比

| 应用类型 | 更新策略 | 锁定保护 | 外置存储更新方式 |
|----------|----------|:---:|------|
| App Store 应用（macOS 15.1+） | 原生外置安装 | 否 | App Store 原地增量更新 |
| App Store 应用（macOS <15.1） | Stub Portal | 否 | 二次迁移覆盖 |
| Sparkle / Electron 应用 | Stub Portal | **是** | 锁定后阻止，需迁回本地更新 |
| Chrome / Edge（自定义更新器） | Stub Portal | 否 | 更新到本地，AppPorts 检测后标记「待迁移」 |

::: warning ⚠️ 关于锁定保护
App Store 应用不支持锁定保护（`chflags uchg`）。macOS 15.1+ 由 App Store 原生管理更新，无需锁定；macOS <15.1 的二次迁移流程本身即为覆盖更新方式，锁定会阻碍 App Store 更新安装到本地。
:::
