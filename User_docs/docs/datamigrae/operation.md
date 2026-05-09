---
outline: deep
---

# 数据迁移操作指南

本页面介绍数据目录迁移的实际操作流程。如需了解技术实现细节，请参阅[基础实现](/datamigrae/baseinfo)。

## 查找应用关联的数据目录

1. 在 AppPorts 主窗口切换到「数据目录」标签
2. 左侧面板显示所有已安装的应用列表
3. 点击某个应用，右侧面板会显示该应用在 `~/Library/` 下关联的数据目录

AppPorts 会自动扫描以下目录，按应用 Bundle ID 或名称匹配：

| 扫描路径 | 匹配方式 |
|----------|----------|
| `~/Library/Application Support/` | Bundle ID 或应用名称 |
| `~/Library/Preferences/` | Bundle ID 或应用名称 |
| `~/Library/Containers/` | Bundle ID |
| `~/Library/Group Containers/` | Bundle ID |
| `~/Library/Caches/` | Bundle ID 或应用名称 |
| `~/Library/WebKit/` | Bundle ID |
| `~/Library/HTTPStorages/` | Bundle ID |
| `~/Library/Application Scripts/` | Bundle ID |
| `~/Library/Logs/` | 应用名称 |
| `~/Library/Saved Application State/` | 应用名称 |

## 工具目录（Dot-Folder）

AppPorts 可自动识别常见开发工具在用户目录下创建的 dot-folder：

1. 在数据目录标签中切换到「工具目录」子标签
2. 页面会列出所有已识别的工具目录及其大小
3. 每个目录显示优先级徽章（推荐/可选）和状态

详细支持列表请参阅[工具目录识别](/datamigrae/tools)。

## 迁移操作

### 单个目录迁移

1. 在数据目录列表中找到要迁移的目录
2. 点击右侧的「迁移」按钮
3. AppPorts 会执行以下步骤：
   - 将目录复制到外部存储
   - 写入托管链接元数据
   - 删除本地原始目录
   - 创建符号链接

### 批量迁移

1. 在工具目录列表中勾选多个目录
2. 点击底部的「批量迁移」按钮
3. AppPorts 按顺序逐个执行迁移

::: tip 💡 优先级建议
数据目录按优先级分为三级：

- **重要**（`critical`）：迁移后必须正常工作，影响应用核心功能
- **推荐**（`recommended`）：占用空间大，迁移收益高
- **可选**（`optional`）：空间较小或可重建

建议优先迁移标记为「推荐」的目录。
:::

## 恢复操作

1. 在数据目录列表中找到已迁移的目录（状态为「已链接」）
2. 点击右侧的「恢复」按钮
3. AppPorts 会执行以下步骤：
   - 删除本地符号链接
   - 将数据从外部存储复制回本地
   - 删除外部目录（尽力而为）

## 处理异常状态

### 待规范

目录由 AppPorts 管理，但外部路径不在规范位置。点击「规范化」按钮，AppPorts 会将外部数据移动到规范路径并重建符号链接。

### 待接回

外部存储上的数据仍在，但本地符号链接已丢失。点击「重新链接」按钮，AppPorts 会重新创建符号链接。

### 现有软链

非 AppPorts 创建的用户自定义符号链接。可选择「接管」，AppPorts 会写入托管链接元数据，将其纳入管理。

## 树形视图

对于包含子目录的数据目录（如 `Application Support` 下的多个应用目录），AppPorts 提供树形分组视图：

- 父目录左侧显示展开/折叠箭头
- 子目录显示层级缩进
- 每个节点独立显示大小和状态
- 可对单个子目录执行迁移/恢复操作
