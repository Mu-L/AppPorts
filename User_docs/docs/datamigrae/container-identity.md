---
outline: deep
---

# 容器数据与签名身份

这篇文档说明一类很容易误判的故障：**迁移过容器数据、并且执行过 Ad-hoc 重签名的应用，可能在一段时间内一直正常，却在某次 macOS 大版本升级后突然打不开**。典型表现是双击图标没反应、进程闪一下就消失、没有任何报错弹窗。

如果这次升级的目标系统是 macOS 27，可先看[macOS 27 升级说明](/macos-27)，那里有针对该版本的检查清单与处理流程。

如果你正在排查某个具体应用，可以直接跳到[自查步骤](#自查步骤)和[修复](#修复)。

## 结论速览

同时满足下面两个条件时就会出现这类问题：

1. 应用被 **Ad-hoc 重签名**过（迁移 `Containers` / `Group Containers` 数据后选择了「同意重签名」，或手动执行过重签名）。
2. 系统对 **应用数据（App Data）归属**的校验变严（常见于 macOS 大版本升级之后）。

关键点是：**重签名不会立刻出问题，它只是把应用变成了一颗定时炸弹。**

- 迁回数据**没用**——问题不在路径，在签名身份。
- 再次重签名**没用**——重签名本身就是病因，只会再抹一次授权。
- 从终端直接运行二进制可能**能看到窗口**——那是假象，见[为什么从终端启动能打开](#为什么从终端启动能打开)。

## 背景：容器是谁的

`~/Library/Containers/<Bundle ID>/Data` 和 `~/Library/Group Containers/` 是 macOS 的沙盒容器目录。系统需要回答一个问题：**当前进程有没有资格读写这个容器？**

对一个**正常签名的沙盒应用**来说，这个问题不需要 TCC 介入：沙盒在启动时就授予它访问自己容器的权限，应用拿到的路径就是容器内视角的路径。

而 Ad-hoc 重签名（`codesign --force --deep --sign -`）会丢掉这些内容：

| 丢失的授权 | 影响 |
|------------|------|
| `com.apple.security.app-sandbox` | 应用不再以沙盒身份运行 |
| `com.apple.security.application-groups` | 无法解析 app group / `Group Containers` |
| `keychain-access-groups` | 无法读取原有钥匙串条目（登录态、数据库密钥） |
| Team ID（`TeamIdentifier=not set`） | 容器归属校验时身份对不上 |

应用**仍然能启动**，但它不再以沙盒身份运行，而是以一个**普通进程**的身份去访问同样的路径。这时系统会按代码签名身份判断「这个容器是不是你的」，而 Ad-hoc 签名与容器里记录的归属对不上，于是拒绝访问。

权限被拒绝之后，应用往往读不到配置或数据库，随即自行退出。日志形态如下：

```
sandboxd rejected approval request from WeChat for kTCCServiceSystemPolicyAppData
  (/Users/<user>/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files): denied
runningboardd: termination reported by launchd (0, 0, 65280)   # 退出码 255
```

## 为什么 macOS 26 能用、27 不行

这是**系统行为差异**，不是 AppPorts 的回归，也不是数据被迁移坏了。

实测对比（同一台机器、同一个已被 Ad-hoc 重签名的应用）：

| 系统版本 | 应用状态 | `kTCCServiceSystemPolicyAppData` 拒绝次数 |
|----------|----------|:---:|
| macOS 26.6.2 | 连续运行 2 天以上，收发消息正常 | 0 |
| macOS 27.0 | 每次启动约 0.4 秒后退出 | 每次启动均有 |

也就是说：**在较旧的系统上，失去沙盒身份的应用访问自己的容器是被放行的**；系统升级后校验变严，同一个应用立刻被拒。

::: warning 不要用「以前一直没事」来判断风险
迁移 + 重签名后能用几个星期甚至几个月都很正常。风险会在下一次 macOS 大版本升级时暴露，而且**升级前后没有任何提示**。
:::

## 为什么从终端启动能打开

排查这一问题时很容易被误导。TCC 是按**责任进程（responsible process）**记账的：

- 从 Finder / Dock 启动时，应用自己是责任进程，用**它自己的身份**去申请权限 → 被拒绝。
- 从终端（或某个已经拿到完全磁盘访问权限的宿主应用）启动时，责任进程可能被归属到宿主，被启动的应用相当于**借用了宿主的权限** → 看起来一切正常。

所以「终端里能起来」不能当作已恢复的证据。判断是否修好，必须用 Finder / Dock 双击，或者用 `open` 命令验证。

## 自查步骤

把示例中的 `/Applications/WeChat.app` 换成你要检查的应用。

```bash
# 1. 签名身份与 Team ID
codesign -dv --verbose=4 /Applications/WeChat.app 2>&1 | grep -E "Authority|TeamIdentifier|Signature"

# 2. 授权（正常应输出一段 XML；只有 Executable= 一行说明授权已被抹掉）
codesign -d --entitlements - /Applications/WeChat.app

# 3. Gatekeeper 评估
spctl -a -vvv -t exec /Applications/WeChat.app

# 4. 复现一次并检查是否被系统拒绝
open -a /Applications/WeChat.app; sleep 3
log show --last 1m --style compact 2>/dev/null | grep -i "rejected approval request"
```

判定标准：

| 观察结果 | 含义 |
|----------|------|
| `Signature=adhoc` + `TeamIdentifier=not set` | 已被 Ad-hoc 重签名 |
| `codesign -d --entitlements` 没有 XML 输出 | 授权已被抹掉 |
| `spctl` 输出 `rejected` | 已无法通过签名校验 |
| 日志出现 `kTCCServiceSystemPolicyAppData ... denied` | 正在被拒绝访问自己的容器 |

四项同时命中即可确认属于本文描述的问题。

## 修复

**唯一可靠的修复方式是恢复应用原本的签名**，即从官方渠道重新安装：

1. 先确认容器数据完好（见下方[确认数据是否安全](#确认数据是否安全)），**不要删除容器目录**。
2. 完全退出该应用。
3. 删除本地副本后从官方渠道重新安装：App Store 应用用 App Store 安装，官网应用从官网下载。覆盖安装即可，`~/Library/Containers/`、`~/Library/Group Containers/` 中的数据会被新装的应用继续读取。
4. 用[自查步骤](#自查步骤)确认签名身份已恢复（应重新出现 `Authority=Developer ID Application: ...` 和完整的 entitlements）。
5. 重新安装后，**不要再对这个应用执行 AppPorts 的重签名**。

::: warning Ad-hoc 重签名无法还原
AppPorts 的「恢复原始签名」需要本机钥匙串中存在原始开发者证书。第三方应用的证书通常不在本机，此时该操作只会**退化为 Ad-hoc 重签名**，无法恢复授权。
:::

### 临时绕过（不保证有效）

如果暂时无法重新安装，可以尝试在 **系统设置 → 隐私与安全性 → 完全磁盘访问权限** 中把该应用加入并勾选。

即使它能绕过 App Data 校验，Keychain 访问组丢失导致的问题（登录态失效、需要重新登录）仍然存在，因此这只应作为临时手段。

### 确认数据是否安全

用下面的命令确认容器里的数据仍在本地，并且没有残留的迁移符号链接：

```bash
# 容器数据是否存在、体积是否正常
ls -la ~/Library/Containers/<Bundle ID>/Data/Documents/

# 列出容器内的符号链接及其指向（出现 /Volumes/... 即为迁移残留）
find ~/Library/Containers/<Bundle ID> -maxdepth 6 -type l -exec readlink {} \; 2>/dev/null
```

如果之前迁移过数据又执行过「恢复」，可以用 Finder 或 `ls -la` 确认原来的子目录已经是**真实目录**而不是指向外部存储的符号链接。

## 预防

- **对沙盒应用不要迁移 `~/Library/Containers/` 与 `~/Library/Group Containers/`**：微信、聊天工具、依赖 Keychain 的应用都属于这一类。要节省空间，优先迁移应用本体，而不是容器数据。
- 迁移这类目录时 AppPorts 会弹窗询问是否重签名，请选择 **「不同意，仅迁移」**。AppPorts 自己的[兼容性与限制](/limitations)也把这两类目录标为中等风险。
- 如果确实要迁移容器数据，迁移前先做独立备份，并记录原始签名身份（AppPorts 会写入 `~/Library/Application Support/AppPorts/signature-backups/<Bundle ID>.plist`，请保留该文件）。
- 大版本系统升级后如果应用突然失效，先按[自查步骤](#自查步骤)确认签名状态，再决定是否迁回数据。**迁回数据不会修复签名身份。**

## 真实案例

一次完整的时间线（2026 年 9 月，macOS 26.6.2 → macOS 27.0）：

| 时间 | 事件 |
|------|------|
| 9/15 04:46 | AppPorts 把微信的聊天数据目录迁移到外部存储，并在本地创建符号链接 |
| 9/15 04:47 | AppPorts 对 `/Applications/WeChat.app` 执行 Ad-hoc 重签名（迁移流程中的「同意重签名」） |
| 9/16 – 9/18 | macOS 26.6.2 下微信正常使用两天半，期间没有被系统拒绝过任何一次容器访问 |
| 9/18 04:46 | 系统升级到 macOS 27.0 (26A428) |
| 9/18 起 | 每次启动微信约 0.4 秒后退出，系统日志记录 `kTCCServiceSystemPolicyAppData ... denied` |
| 9/18 05:04 | 用户尝试「恢复数据」并再次重签名，问题依旧 |

这个案例说明了两点：

1. **数据迁移本身不是原因**——迁移后两天半一直正常，数据完好（恢复后容器内数据完整）。
2. **重签名是真正的埋伏**——它在升级前不产生任何可见症状，升级后才爆发，因此很容易被误判为「系统升级把应用搞坏了」。
