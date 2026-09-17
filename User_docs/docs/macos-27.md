---
outline: deep
---

# macOS 27 升级说明

::: tip 一句话结论
macOS 27 收紧了「应用数据（App Data）」的访问校验。**曾经迁移过容器数据、并在迁移时执行过 Ad-hoc 重签名的应用，升级后可能无法启动。**

这**不是**数据被迁移坏了，也不需要重新迁移。迁回数据、再次重签名都无法修复，从官方渠道重新安装该应用即可恢复正常。
:::

## 影响范围

| 项目 | 说明 |
|------|------|
| 触发条件 | 从 macOS 26 升级到 macOS 27 |
| 受影响应用 | 迁移过 `~/Library/Containers/` 或 `~/Library/Group Containers/` 数据，且执行过 Ad-hoc 重签名的应用 |
| 典型表现 | Finder / Dock 双击无反应，进程约 0.4 秒后自行退出，没有报错弹窗或崩溃报告 |
| 数据安全 | **不受影响**，容器内的数据完好 |
| 已确认案例 | 微信（WeChat 4.1.13）、macOS 27.0 (26A428) |

如果你迁移容器数据时选择的是 **「不同意，仅迁移」**，应用不会受到影响。判断方法见[升级前先检查](#升级前先检查)。

## 现象

升级到 macOS 27 之后，应用无法启动，特征是：

- 在 Finder 或 Dock 中双击图标没有反应，Dock 上的图标闪一下就消失；
- 没有任何「已损坏」或「来自身份不明的开发者」弹窗；
- 系统日志显示进程启动后很快自行退出，退出码 255：

```
sandboxd rejected approval request from WeChat for kTCCServiceSystemPolicyAppData
  (/Users/<user>/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files): denied
runningboardd: termination reported by launchd (0, 0, 65280)
```

其中 `kTCCServiceSystemPolicyAppData` 那一行是核心：**系统拒绝了这个应用访问它自己的容器。**

## 原因

简要说，是两个条件叠加的结果。

**条件一：应用已经被 Ad-hoc 重签名过。**

AppPorts 在迁移 `~/Library/Containers/` 或 `~/Library/Group Containers/` 数据时会询问是否在迁移后重签名。执行 `codesign --force --deep --sign -` 会抹掉应用的以下内容：

- `com.apple.security.app-sandbox`（沙盒授权）
- `com.apple.security.application-groups`（app group 授权）
- `keychain-access-groups`（钥匙串访问组）
- Team ID（`TeamIdentifier=not set`）

应用不会立刻出问题，但它从此不再以**沙盒身份**运行，而是以**普通进程**身份去读写自己的容器。

**条件二：系统对容器归属的校验变严。**

`~/Library/Containers/<Bundle ID>/Data` 是沙盒容器。正常签名的沙盒应用由沙盒直接放行，不需要 TCC 介入；而失去沙盒身份的应用访问同一路径时，系统会按**代码签名身份**判断「这个容器是不是你的」。Ad-hoc 签名与容器记录的归属对不上，于是被拒绝。

macOS 26 会放行这种情况，macOS 27 不再放行。同一台机器、同一个应用的实测对比：

| 系统版本 | 应用状态 | `kTCCServiceSystemPolicyAppData` 拒绝次数 |
|----------|----------|:---:|
| macOS 26.6.2 | 连续运行 2 天以上，收发消息正常 | 0 |
| macOS 27.0 | 每次启动约 0.4 秒后退出 | 每次启动均有 |

::: warning 为什么之前一直没事
重签名后应用可能正常使用数周甚至数月，因此很难把它和「系统升级」联系起来。风险只在下一次 macOS 大版本升级时暴露，且升级前后没有任何提示。
:::

原理细节见[容器数据与签名身份](/datamigrae/container-identity)。

## 升级前先检查

下面的脚本会列出**原始签名被替换成 Ad-hoc 的应用**——这些就是升级后可能出问题的高危对象：

```bash
BACKUP_DIR="$HOME/Library/Application Support/AppPorts/signature-backups"
for plist in "$BACKUP_DIR"/*.plist; do
  [ -f "$plist" ] || continue
  original=$(/usr/libexec/PlistBuddy -c "Print :signingIdentity" "$plist" 2>/dev/null)
  app=$(/usr/libexec/PlistBuddy -c "Print :originalPath" "$plist" 2>/dev/null)
  case "$original" in ""|ad-hoc) continue ;; esac   # 本来就是 ad-hoc 的跳过
  [ -d "$app" ] || continue
  if codesign -dv "$app" 2>&1 | grep -q "Signature=adhoc"; then
    printf "%s\n    原始签名: %s\n" "$app" "$original"
  fi
done
```

有输出就说明这些应用的原始开发者签名已经被破坏。**升级 macOS 27 之前**，建议对它们逐个处理：

1. 从官方渠道重新安装该应用，恢复原始签名。
2. 用下方的[自查步骤](#升级后的自查步骤)确认 `Authority` 和 entitlements 已恢复。
3. 确认无误后再执行系统升级。

如果暂时不方便重装，至少要**记录这些应用的名单**，以便升级后快速定位问题。

## 升级后的自查步骤

把示例中的 `/Applications/WeChat.app` 换成实际应用。

```bash
# 1. 签名身份与 Team ID
codesign -dv --verbose=4 /Applications/WeChat.app 2>&1 | grep -E "Authority|TeamIdentifier|Signature"

# 2. 授权（正常会输出一段 XML；只有 Executable= 一行说明授权已被抹掉）
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

**唯一可靠的修复方式是从官方渠道重新安装该应用，恢复它原本的签名。**

1. 先确认容器数据完好——**不要删除容器目录**：

   ```bash
   ls -la ~/Library/Containers/<Bundle ID>/Data/Documents/

   # 列出容器内的符号链接及其指向（出现 /Volumes/... 即为迁移残留）
   find ~/Library/Containers/<Bundle ID> -maxdepth 6 -type l -exec readlink {} \; 2>/dev/null
   ```

2. 完全退出该应用。
3. 删除本地副本后从官方渠道重新安装：App Store 应用用 App Store 安装，官网应用从官网下载。覆盖安装即可，`~/Library/Containers/`、`~/Library/Group Containers/` 中的数据会被新装的应用继续读取，聊天记录、登录态等不会丢失。
4. 重新执行[自查步骤](#升级后的自查步骤)，确认重新出现 `Authority=Developer ID Application: ...` 和完整的 entitlements。
5. 重装后**不要再对这个应用执行重签名**。

::: warning 「恢复原始签名」不能代替重装
AppPorts 的「恢复原始签名」需要本机钥匙串中存在原始开发者证书。第三方应用的证书通常不在本机，此时该操作只会退化为 Ad-hoc 重签名，无法恢复授权。
:::

### 临时绕过（不保证有效）

如果暂时无法重新安装，可以尝试在 **系统设置 → 隐私与安全性 → 完全磁盘访问权限** 中把该应用加入并勾选。

即使能绕过 App Data 校验，Keychain 访问组丢失导致的问题（登录态失效、需要重新登录）仍然存在，因此这只应作为临时手段。

## 不要做的三件事

| 做法 | 为什么没用 |
|------|-----------|
| 把数据迁回本地 | 问题在签名身份，不在数据路径。数据迁回后应用仍然无法访问容器 |
| 再次执行重签名 | 重签名本身就是病因，只会再抹一次授权 |
| 用「终端里能打开」当作已修复 | TCC 按责任进程记账，从终端启动时会借用宿主进程的权限，属于假象。必须以 Finder / Dock 双击的结果为准 |

## 常见疑问

### 我把数据迁回本地了，为什么还是打不开？

因为问题不在数据。迁移只是让你选择了「同意重签名」，真正被破坏的是应用的签名身份。数据迁回本地不会改变签名身份，因此症状不变。

### 聊天记录会不会丢？

不会。容器数据（`~/Library/Containers/<Bundle ID>/Data`）不会因为重装应用而丢失，重新安装后应用会继续读取原有数据。

### 是 AppPorts 把数据搞坏了或弄丢了吗？

不是。数据本身是完好的，AppPorts 也没有删除数据。

但需要说明的是：**迁移流程中的「同意重签名」选项是这一次故障的直接来源**。它解决的问题是「迁移后签名失效导致 Gatekeeper 拦截」，代价是永久破坏沙盒应用的签名身份。对沙盒应用来说，这个代价是不可逆的——因此在迁移 `~/Library/Containers/` 或 `~/Library/Group Containers/` 时，建议选择「不同意，仅迁移」。

### 只有微信会这样吗？

只要满足「迁移过容器数据 + 执行过重签名 + 是沙盒应用或依赖 Keychain」这三个条件，任何应用都可能出现同样的症状。微信只是最容易被注意到的那个。用[升级前先检查](#升级前先检查)的脚本可以扫出完整名单。

## 附：本次案例时间线

2026 年 9 月，一台真实机器上的完整过程：

| 时间 | 事件 |
|------|------|
| 9/15 04:46 | AppPorts 把微信的聊天数据目录迁移到外部存储，并在本地创建符号链接 |
| 9/15 04:47 | AppPorts 对 `/Applications/WeChat.app` 执行 Ad-hoc 重签名 |
| 9/16 – 9/18 | macOS 26.6.2 下微信正常使用两天半，期间没有被系统拒绝过任何一次容器访问 |
| 9/18 04:46 | 系统升级到 macOS 27.0 (26A428) |
| 9/18 起 | 每次启动微信约 0.4 秒后退出，系统日志记录 `kTCCServiceSystemPolicyAppData ... denied` |
| 9/18 05:04 | 用户尝试「恢复数据」并再次重签名，问题依旧 |

这个时间线说明了两点：数据迁移本身不是原因（迁移后两天半一直正常）；重签名才是真正的埋伏（升级前没有任何症状，升级后才爆发）。

## 相关文档

- [容器数据与签名身份](/datamigrae/container-identity) —— 原理、自查与通用修复流程
- [重签名与崩溃防护](/datamigrae/resign) —— AppPorts 的重签名机制与风险
- [兼容性与限制](/limitations) —— 各类数据目录的迁移风险等级
