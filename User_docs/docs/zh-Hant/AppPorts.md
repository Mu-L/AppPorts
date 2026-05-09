---
outline: deep
---

# AppPorts 用戶指南

本指南旨在系統性地介紹 AppPorts 的功能、設計原理與技術實現。更多技術細節請參見 [DeepWiki](https://deepwiki.com/wzh4869/AppPorts)，如有改進建議請提交至項目 [Issues](https://github.com/wzh4869/AppPorts/issues)。

## 概述

AppPorts 是專爲 [macOS](https://www.apple.com.cn/os/macos/) 設計的應用程序遷移與鏈接工具，支持將大型應用程序遷移至外部存儲設備，同時保持系統功能的完整性和一致性。

### AppPorts 哲學

| 原則 | 說明 |
|------|------|
| **透明體驗** | 確保用戶體驗與操作系統均感知爲應用仍在內部存儲運行 |
| **策略穩定** | 優先採用經過驗證的、遷移穩定性更高的方案 |
| **低系統負擔** | 不依賴守護進程，避免持續佔用系統資源 |
| **廣泛國際化** | 優先覆蓋更多語言種類，翻譯廣度優先於精度 |
| **無障礙友好** | 完善的無障礙訪問支持 |

## 核心功能

- **無角標遷移**：一鍵將大型應用遷移至外置硬盤。本地僅保留輕量啓動器殼，Finder 不顯示快捷方式箭頭，Launchpad 與 macOS 應用菜單正常顯示。
- **自動更新保護**：自動識別支持自動更新的應用（Sparkle、Electron、Chrome 等），提供「鎖定遷移」選項，防止外置硬盤上的應用被自動更新程序刪除或覆蓋。
- **代碼簽名管理**：遷移後如出現「已損壞」提示，可通過右鍵菜單一鍵重簽名。支持備份、恢復原始簽名，數據目錄遷移後可自動執行重簽名。
- **macOS 15.1+ App Store 支持**：支持將 App Store 應用直接安裝至外置硬盤，並在外置硬盤上原地更新，無需遷回本地。
- **一鍵還原**：支持將應用遷回本地並自動移除鏈接。遷移中斷時可自動恢復。
- **數據目錄管理**：支持將應用數據目錄（`~/Library/` 子目錄、`~/.npm` 等）遷移至外部存儲，提供樹形分組視圖、搜索與排序功能。

## 術語表

### 遷移策略

#### Deep Contents Wrapper（Contents 目錄遷移）

macOS 應用的標準文件結構如下：

```text
/Applications/Safari.app/
├── Contents/
│   ├── MacOS/
│   ├── Resources/
│   ├── Frameworks/
│   └── Info.plist
└── ...
```

Deep Contents Wrapper 策略將應用的全部內容遷移至外置硬盤，在本地創建同名的空 `.app` 目錄，其中僅包含指向外置硬盤 `Contents` 目錄的符號鏈接。由於 macOS 檢測到的是一個完整的 `.app` 包（而非快捷方式），Finder 不會顯示箭頭標記，圖標、Launchpad 與應用菜單均可正常工作。

::: warning ⚠️ 此策略已在當前版本中棄用
Deep Contents Wrapper 的主要缺陷在於：自動更新程序運行時會沿符號鏈接直接操作外置硬盤上的文件，可能導致應用本體被破壞。
:::

#### Stub Portal（殼門方案）

Stub Portal 方案在本地創建一個最小化的 `.app` 殼，僅包含以下四項內容：

| 組件 | 說明 |
|------|------|
| `Contents/MacOS/launcher` | Bash 啓動腳本，執行 `open "/Volumes/External/SomeApp.app"` |
| `Contents/Resources/` | 從外部應用複製的圖標文件 |
| `Contents/Info.plist` | 基於外部應用的 `Info.plist` 精簡生成，將 `CFBundleExecutable` 設爲 `launcher`，添加 `LSUIElement=true`（不在 Dock 顯示），移除所有更新相關配置鍵 |
| `Contents/PkgInfo` | 標準的 4 字節標識文件 |

用戶點擊此殼時，macOS 執行 `launcher` 腳本，通過 `open` 命令啓動外置硬盤上的真實應用。本地不包含任何符號鏈接，自動更新程序無法穿透。

##### iOS Stub Portal（iOS 殼門方案）

基本原理與標準 Stub Portal 一致，但圖標處理方式不同。iOS 應用的圖標不在 `Info.plist` 中指定，而是存儲在 `Wrapper/` 或 `WrappedBundle/` 目錄下的多個 `AppIcon.png` 文件中。處理流程如下：

1. 查找分辨率最大的 `AppIcon.png` 文件
2. 使用 `sips` 縮放至 256×256 像素
3. 使用 `sips` 轉換爲 `.icns` 格式
4. 基於 `iTunesMetadata.plist` 生成 `Info.plist`（iOS 應用不包含標準 `Info.plist`）

#### Whole Symlink（整體符號鏈接）

將整個 `.app` 目錄創建爲指向外置硬盤的符號鏈接：

```text
/Applications/SomeApp.app → /Volumes/External/SomeApp.app
```

本地僅保留一個符號鏈接，無實際文件。macOS 可正常打開應用，但 Finder 會在圖標上顯示箭頭快捷方式標記，Launchpad 偶爾出現兼容性問題。此外，自動更新程序同樣可沿符號鏈接操作外置硬盤上的應用文件，此方式爲 AppPorts 的保底遷移策略。
