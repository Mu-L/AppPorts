## AppPorts v1.8.1 更新说明（[English](#english-release-notes)）· [直链下载](https://file.shimoko.com/AppPorts)

### 总结

这次主要让应用搬到外置硬盘后的使用更省心：修复了从 Dock 打开时多出一个相同图标的问题，已经迁移的应用也能直接修复，不用重新搬一遍。复制到 NAS 时减少了不必要的等待，迁移进度更清楚；迁移、还原和重签名遇到问题时，也会更明确地告诉你当前情况和下一步怎么处理。

另外，按钮、状态提示和多语言文案做了整理，排查问题时的日志也更可靠。新版“关于 AppPorts”窗口可以查看版本、贡献者和版权说明，还能手动检查更新。

### 新功能

**Dock 图标修复** — 在「Mac 本地应用」列表中右键点击已链接应用，可选择「修复 Dock 图标」，将原有固定项关联到外部真实应用，保留固定位置和其他 Dock 项目。适用于升级前已经迁移的应用，无需重新迁移。

**全新关于窗口与检查更新** — 重新设计「关于 AppPorts」，采用简洁的独立窗口，集中展示应用版本与构建号、项目链接、贡献者和版权许可。贡献者仅显示可点击的名字，不再显示头像。新增「检查更新」按钮，清楚区分正在检查、有新版本、已是最新和检查失败；发现更新后可前往 GitHub 或国内下载地址。

### 改进

**NAS 小文件复制优化** — 减少应用复制中的重复目录遍历和元数据读取，在网络存储上使用有上限的并发复制，降低大量小文件带来的网络往返开销。尚未计算出总大小时，也会持续显示当前文件与已复制字节。[#57](https://github.com/wzh4869/AppPorts/issues/57)

**数据迁移后的签名流程更可靠** — 选择迁移后重签名时，按顺序完成签名备份、数据迁移和重签名，并等待签名校验结束。如果数据已经迁移但签名失败，会明确提示当前状态，并提供重试或还原指引。[#59](https://github.com/wzh4869/AppPorts/issues/59)

**文件复制与恢复更完整** — 改进权限、时间戳和扩展属性的保留，完善只读目录、复制中断及取消后的清理与入口恢复。发生路径冲突或副本清理失败时，优先保留已有数据。

**日志与诊断更稳定** — 日志写入失败时退回控制台输出，避免因此导致应用退出；并发日志中的事件与详细字段保持对应。诊断信息收集增加超时和输出限制，完善文本及 JSON 中用户名、存储路径等信息的脱敏处理。

**迁移期间的操作保护** — 统一应用、数据目录和目录迁移页面的忙碌状态，避免重复执行操作；迁移期间限制页面和语言切换，并在执行前重新检查应用是否正在运行。

**界面与多语言体验完善** — 修正部分按钮和状态图标，调整列表图标尺寸与进度信息排版，完善辅助功能标签，并补齐新增提示的多语言翻译。

### 修复

- 修复应用固定到 Dock 后再迁移，启动时额外出现相同图标的问题；迁移、链接回本地和还原完成后会同步已有固定项，本地启动壳仍保留独立身份。
- 修复重签名可能作用于本地启动壳、遗漏嵌套代码组件，或因内部文件仍被锁定而失败的问题。[#59](https://github.com/wzh4869/AppPorts/issues/59)
- 修复数据目录还原和清理过程中，相对链接、父目录链接等情况可能导致目标解析错误或误删无关文件的问题。
- 修复迁移失败后重试时，可能采用外部旧副本而遗漏本地新增数据的问题；本地和外部同时存在真实目录时会提示冲突并保留两份数据。
- 修复从自定义目录迁移的部分应用还原时未回到原位置的问题，并加强应用套件入口的目标校验。
- 修复切换应用或扫描目录后，旧扫描结果可能覆盖当前列表，以及操作期间的目录变化未在完成后及时刷新的问题。
- 修复日志菜单开关状态、容量选项和清空后的大小显示不及时更新的问题。

### 升级提示

已经出现重复 Dock 图标的应用，可在升级后使用右键菜单中的「修复 Dock 图标」。修复时 Dock 会短暂刷新；修复后的固定项直接指向外部应用，从 Dock 启动时需要连接对应的外部存储。

### ⚠️ “AppPorts”已损坏，无法打开

如果从 AppPorts 官方发布渠道下载后遇到此提示，可能与 macOS 对未进行 Developer ID 签名和公证的应用进行隔离有关。

确认下载来源后，将 AppPorts 拖入「应用程序」文件夹，再在终端运行：

```shell
xattr -rd com.apple.quarantine /Applications/AppPorts.app
```

## English Release Notes

### Summary

This update makes apps easier to use after moving them to an external drive. It fixes the extra matching icon that could appear when launching a migrated app from the Dock, and lets you repair existing pins without moving the app again. NAS transfers do less unnecessary work, progress is clearer, and problems with migration, restoration, or re-signing come with a clearer explanation of what happened and what to do next.

Buttons, status messages, and translations have also been refined, and logs are more reliable when you need help troubleshooting. The redesigned “About AppPorts” window brings version details, contributors, copyright information, and manual update checking together.

### New Features

**Dock icon repair** — Right-click a linked app in the local apps list and choose “Repair Dock Icon” to point its existing pinned item to the real external app. Its position and other Dock items are preserved. This also works for apps migrated before this update, without moving them again.

**Redesigned About window and manual update checking** — “About AppPorts” is now a clean, standalone window with version and build details, project links, contributors, and copyright and license information. Contributors appear as clickable names without avatars. The new “Check for Updates” button shows whether a check is in progress, an update is available, the app is up to date, or the check failed. Available updates include links to GitHub and the China download site.

### Improvements

**Small-file transfers to NAS** — Reduced repeated directory traversal and metadata reads during app copying. Transfers involving network storage use bounded concurrency to reduce the overhead of copying many small files. The current file and copied bytes remain visible even when the total size is not yet known. [#57](https://github.com/wzh4869/AppPorts/issues/57)

**More reliable re-signing after data migration** — When re-signing is selected, signature backup, data migration, and re-signing now complete in sequence, including signature verification. If the data has moved but re-signing fails, AppPorts clearly reports that state and explains how to retry or restore the data. [#59](https://github.com/wzh4869/AppPorts/issues/59)

**Better file preservation and recovery** — Improved handling of permissions, timestamps, and extended attributes, along with cleanup and local entry recovery for read-only directories, interrupted copies, and cancellation. Existing data is preserved when paths conflict or copy cleanup fails.

**More reliable logging and diagnostics** — File logging failures fall back to console output instead of causing the app to exit. Concurrent log events keep their detail fields together. Diagnostic collection now has timeouts and output limits, with improved redaction of user names and storage paths in both text and JSON files.

**Operation safeguards** — Shared busy state across app, data directory, and custom directory migration prevents overlapping operations. Page and language switching are restricted during migration, and AppPorts checks again whether an app is running before starting an operation.

**Interface and localization refinements** — Corrected several button and status icons, refined list icon sizes and progress layouts, improved accessibility labels, and translated the new prompts across supported languages.

### Fixes

- Fixed an extra matching Dock icon appearing when launching an app that was pinned before migration. Existing pinned items are now updated after migration, relinking, and restoration, while the local Stub Portal keeps its separate identity.
- Fixed re-signing targeting the local Stub Portal, missing nested code components, or failing because files inside the app bundle remained locked. [#59](https://github.com/wzh4869/AppPorts/issues/59)
- Fixed incorrect target resolution and potential deletion of unrelated files during data restoration and cleanup when relative symlinks or symlinked parent directories were involved.
- Fixed migration retries potentially adopting an older external copy and missing newer local data. When real directories exist on both sides, AppPorts reports a conflict and preserves both copies.
- Fixed some apps migrated from custom directories being restored to the wrong location, and strengthened target validation for app suite entries.
- Fixed stale scan results overwriting the current list after switching apps or scan directories, and ensured directory changes detected during an operation are refreshed afterward.
- Fixed logging menu state, size limit selection, and log size displays not updating promptly after clearing logs.

### Upgrade Notes

For apps that already have duplicate Dock icons, use “Repair Dock Icon” from the context menu after upgrading. The Dock briefly refreshes during repair. Updated pinned items point directly to the external app, so the corresponding external storage must be connected when launching from the Dock.

### ⚠️ “AppPorts” is damaged and can’t be opened

If this appears after downloading AppPorts from an official release channel, it may be related to macOS quarantine checks for apps without Developer ID signing and notarization.

After confirming the download source, move AppPorts to the Applications folder and run:

```shell
xattr -rd com.apple.quarantine /Applications/AppPorts.app
```

**Full Changelog**: [1.8.0 → 1.8.1](https://github.com/wzh4869/AppPorts/compare/1.8.0...1.8.1)
