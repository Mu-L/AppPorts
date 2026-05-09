---
outline: deep
---

# 更新日誌

## v1.5.5

當前版本。

## v1.5.0

- 新增 macOS 15.1+ App Store 應用外置安裝支持
- 新增自動重簽名功能（數據目錄遷移後自動執行）
- 新增 `LocalizationAuditTests` 本地化審計測試
- 改進 Stub Portal 的 Info.plist 生成邏輯
- 修復部分應用遷移後 Launchpad 圖標丟失的問題

## v1.4.0

- 新增數據目錄樹形視圖
- 新增工具目錄識別（30+ 種開發工具）
- 新增診斷包導出功能
- 改進自更新檢測（Chrome、Edge 等自定義更新器）
- 修復遷移中斷後的自動恢復機制

## v1.3.0

- 新增數據目錄遷移功能
- 新增代碼簽名管理（備份/恢復原始簽名）
- 新增 Sparkle 和 Electron 應用自動檢測
- 改進鎖定遷移保護（`chflags uchg`）
- 修復 Finder 中角標顯示問題

## v1.2.0

- 新增 Stub Portal 遷移策略（替代 Deep Contents Wrapper）
- 新增 iOS 應用遷移支持（Mac 版 iOS 應用）
- 改進批量遷移性能
- 修復部分應用還原後無法啓動的問題

## v1.1.0

- 新增多語言支持（20+ 種語言）
- 新增應用套件目錄遷移（如 Microsoft Office）
- 改進外部存儲離線檢測
- 修復 Deep Contents Wrapper 策略的符號鏈接穿透問題

## v1.0.0

- 首個正式版本
- 支持應用遷移至外部存儲（Deep Contents Wrapper / Whole App Symlink）
- 支持應用還原和鏈接管理
- 支持 FolderMonitor 實時監控文件系統變化
