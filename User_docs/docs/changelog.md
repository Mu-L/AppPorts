---
outline: deep
---

# 更新日志

## v1.5.5

当前版本。

## v1.5.0

- 新增 macOS 15.1+ App Store 应用外置安装支持
- 新增自动重签名功能（数据目录迁移后自动执行）
- 新增 `LocalizationAuditTests` 本地化审计测试
- 改进 Stub Portal 的 Info.plist 生成逻辑
- 修复部分应用迁移后 Launchpad 图标丢失的问题

## v1.4.0

- 新增数据目录树形视图
- 新增工具目录识别（30+ 种开发工具）
- 新增诊断包导出功能
- 改进自更新检测（Chrome、Edge 等自定义更新器）
- 修复迁移中断后的自动恢复机制

## v1.3.0

- 新增数据目录迁移功能
- 新增代码签名管理（备份/恢复原始签名）
- 新增 Sparkle 和 Electron 应用自动检测
- 改进锁定迁移保护（`chflags uchg`）
- 修复 Finder 中角标显示问题

## v1.2.0

- 新增 Stub Portal 迁移策略（替代 Deep Contents Wrapper）
- 新增 iOS 应用迁移支持（Mac 版 iOS 应用）
- 改进批量迁移性能
- 修复部分应用还原后无法启动的问题

## v1.1.0

- 新增多语言支持（20+ 种语言）
- 新增应用套件目录迁移（如 Microsoft Office）
- 改进外部存储离线检测
- 修复 Deep Contents Wrapper 策略的符号链接穿透问题

## v1.0.0

- 首个正式版本
- 支持应用迁移至外部存储（Deep Contents Wrapper / Whole App Symlink）
- 支持应用还原和链接管理
- 支持 FolderMonitor 实时监控文件系统变化
