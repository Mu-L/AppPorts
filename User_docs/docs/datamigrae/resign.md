---
outline: deep
---

# 重签名与崩溃防护
![](https://pic.cdn.shimoko.com/appports/%E6%88%AA%E5%B1%8F2026-05-08%2008.38.37.png)
## 为什么迁移数据后应用可能崩溃

macOS 的代码签名机制（`codesign`）会验证应用包的完整性，包括文件路径结构。当 AppPorts 将应用的数据目录迁移至外部存储并替换为符号链接后，签名密封被破坏，导致以下问题：

- **Gatekeeper 拦截**：`codesign --verify --deep --strict` 检测到签名失效，系统弹出「已损坏」或「来自身份不明的开发者」对话框，阻止应用启动
- **Keychain 访问中断**：依赖 Keychain 访问组的应用因签名身份变更而无法读取存储的凭据
- **授权（Entitlements）失效**：部分应用的授权与签名身份绑定，签名变更后授权不匹配

### 高风险应用类型

| 应用类型 | 风险等级 | 原因 |
|----------|----------|------|
| Sparkle 自更新应用 | **高** | 更新器可能删除或替换应用，破坏符号链接 |
| Electron 自更新应用 | **高** | `electron-updater` 同样可能干扰外部存储上的应用 |
| 依赖 Keychain 的应用 | **高** | Ad-hoc 签名变更了签名身份，Keychain 访问组失效 |
| Mac App Store 应用 | **高** | SIP 保护，无法重签名 |
| 原生自更新应用（Chrome、Edge） | 中 | 自更新可能替换外部副本，使本地入口失效 |
| iOS 应用（Mac 版） | 低 | 使用 Stub Portal 或整体符号链接，签名问题较少 |

### 高风险数据目录类型

| 数据类型 | 风险等级 | 原因 |
|----------|----------|------|
| `~/Library/Application Support/` | 中 | 应用可能使用文件锁、SQLite WAL 日志或扩展属性，跨符号链接时可能异常 |
| `~/Library/Group Containers/` | 中 | 同一 Team 下多应用共享，符号链接可能干扰其他应用 |
| `~/Library/Preferences/` | 低-中 | `cfprefsd` 缓存 plist 文件，符号链接可能导致读取过期数据 |
| `~/Library/Caches/` | 低 | 缓存可重建，多数应用可优雅处理缓存缺失 |

## 重签名机制

### Ad-hoc 签名

AppPorts 使用 **Ad-hoc 签名**（无证书的本地签名）来修复迁移后的应用签名。执行命令：

```bash
codesign --force --deep --sign - <应用路径>
```

其中 `-` 表示 Ad-hoc 签名（不使用开发者证书）。

### 签名流程

```mermaid
flowchart TD
    A[开始重签名] --> B[备份原始签名身份]
    B --> C{应用是否被锁定?}
    C -->|是| D[临时解锁 uchg 标志]
    C -->|否| E{应用是否可写?}
    D --> E
    E -->|不可写且为 root 所有| F[尝试提权修改所有者]
    E -->|可写| G[清理扩展属性]
    F --> G
    F -->|失败且为 MAS 应用| H[跳过签名 - SIP 保护]
    G --> I[清理 Bundle 根目录杂物]
    I --> J{Contents 是否为符号链接?}
    J -->|是| K[临时替换为真实目录副本]
    J -->|否| L[执行深度签名]
    K --> L
    L -->|失败| M[回退为浅层签名]
    L -->|成功| N{Contents 是否被临时替换?}
    M --> N
    N -->|是| O[恢复符号链接]
    N -->|否| P[重新锁定 uchg 标志]
    O --> P
    P --> Q[签名完成]
```

### 关键步骤说明

1. **备份原始签名身份**：在签名前，读取应用当前的签名身份信息（通过 `codesign -dvv` 解析 `Authority=` 行），保存至 `~/Library/Application Support/AppPorts/signature-backups/<BundleID>.plist`

2. **清理扩展属性**：执行 `xattr -cr` 移除资源分支、Finder 信息等，避免签名时出现 "detritus not allowed" 错误

3. **清理 Bundle 根目录**：移除 `.DS_Store`、`__MACOSX`、`.git`、`.svn` 等杂物

4. **处理符号链接的 Contents**：若 `Contents/` 是符号链接（Deep Contents Wrapper 策略），临时将其替换为真实目录副本，签名完成后再恢复符号链接

5. **深度签名 → 浅层签名回退**：优先执行 `--deep` 签名（覆盖所有嵌套组件），若因权限或资源分支问题失败，回退为不带 `--deep` 的浅层签名

6. **重试机制**：`codesign` 出现 "internal error" 或被 SIGKILL 终止时，最多重试 2 次

## 签名备份与恢复

### 备份

备份文件保存在 `~/Library/Application Support/AppPorts/signature-backups/` 目录下，以 `BundleID.plist` 命名：

| 字段 | 说明 |
|------|------|
| `bundleIdentifier` | 应用的 Bundle ID |
| `signingIdentity` | 原始签名身份（如 `Developer ID Application: ...` 或 `ad-hoc`） |
| `originalPath` | 原始应用路径 |
| `backupDate` | 备份时间 |

备份在以下时机触发：

- 数据目录迁移前（若开启了自动重签名）
- 任何签名操作执行前（幂等，不会覆盖已有备份）

### 恢复

恢复签名时，AppPorts 根据备份的签名身份执行不同策略：

| 备份的签名身份 | 恢复行为 |
|---------------|----------|
| `ad-hoc` 或为空 | 执行 `codesign --remove-signature` 移除签名，删除备份 |
| 有效的开发者证书身份 | 检查钥匙串中是否存在该证书。若存在，使用原始身份重新签名 |
| 有效的开发者证书身份，但证书不在本机 | **回退为 Ad-hoc 签名**，原始签名无法完整恢复 |

### 恢复失败的情况

以下场景会导致签名恢复失败或不完整：

| 场景 | 结果 |
|------|------|
| 备份 plist 文件不存在 | 抛出 `noBackupFound` 错误，无法恢复 |
| 原始开发者证书不在本机钥匙串中 | 回退为 Ad-hoc 签名。应用可启动，但 Keychain 访问组和部分授权可能失效 |
| Mac App Store 应用（SIP 保护） | 静默跳过。SIP 阻止对系统应用签名的任何修改 |
| 应用目录不可写且为 root 所有 | 尝试通过管理员权限修改所有者。若用户取消授权提示则失败 |
| Contents 符号链接目标已丢失 | 临时替换步骤中 `copyItem` 失败，签名无法执行 |
| 用户取消管理员权限授权 | 抛出 `codesignFailed("用户取消了权限授权")` |
| 深度签名和浅层签名均失败 | 错误向上传播，签名操作失败 |

::: warning ⚠️ 关于开发者证书丢失
最常见的实际恢复失败场景是：原始应用由第三方开发者签名（如 `Developer ID Application: Google LLC`），但当前机器的钥匙串中没有对应的私钥。此时恢复操作只能生成 Ad-hoc 签名，**原始签名身份无法完整还原**。对于依赖特定签名身份的 Keychain 访问组或企业配置描述文件的应用，这可能导致功能异常。
:::
