---
outline: deep
---

# 數據遷移操作指南

本頁面介紹數據目錄遷移的實際操作流程。如需瞭解技術實現細節，請參閱[基礎實現](/datamigrae/baseinfo)。

## 查找應用關聯的數據目錄

1. 在 AppPorts 主窗口切換到「數據目錄」標籤
2. 左側面板顯示所有已安裝的應用列表
3. 點擊某個應用，右側面板會顯示該應用在 `~/Library/` 下關聯的數據目錄

AppPorts 會自動掃描以下目錄，按應用 Bundle ID 或名稱匹配：

| 掃描路徑 | 匹配方式 |
|----------|----------|
| `~/Library/Application Support/` | Bundle ID 或應用名稱 |
| `~/Library/Preferences/` | Bundle ID 或應用名稱 |
| `~/Library/Containers/` | Bundle ID |
| `~/Library/Group Containers/` | Bundle ID |
| `~/Library/Caches/` | Bundle ID 或應用名稱 |
| `~/Library/WebKit/` | Bundle ID |
| `~/Library/HTTPStorages/` | Bundle ID |
| `~/Library/Application Scripts/` | Bundle ID |
| `~/Library/Logs/` | 應用名稱 |
| `~/Library/Saved Application State/` | 應用名稱 |

## 工具目錄（Dot-Folder）

AppPorts 可自動識別常見開發工具在用戶目錄下創建的 dot-folder：

1. 在數據目錄標籤中切換到「工具目錄」子標籤
2. 頁面會列出所有已識別的工具目錄及其大小
3. 每個目錄顯示優先級徽章（推薦/可選）和狀態

詳細支持列表請參閱[工具目錄識別](/datamigrae/tools)。

## 遷移操作

### 單個目錄遷移

1. 在數據目錄列表中找到要遷移的目錄
2. 點擊右側的「遷移」按鈕
3. AppPorts 會執行以下步驟：
   - 將目錄複製到外部存儲
   - 寫入托管鏈接元數據
   - 刪除本地原始目錄
   - 創建符號鏈接

### 批量遷移

1. 在工具目錄列表中勾選多個目錄
2. 點擊底部的「批量遷移」按鈕
3. AppPorts 按順序逐個執行遷移

::: tip 💡 優先級建議
數據目錄按優先級分爲三級：

- **重要**（`critical`）：遷移後必須正常工作，影響應用核心功能
- **推薦**（`recommended`）：佔用空間大，遷移收益高
- **可選**（`optional`）：空間較小或可重建

建議優先遷移標記爲「推薦」的目錄。
:::

## 恢復操作

1. 在數據目錄列表中找到已遷移的目錄（狀態爲「已鏈接」）
2. 點擊右側的「恢復」按鈕
3. AppPorts 會執行以下步驟：
   - 刪除本地符號鏈接
   - 將數據從外部存儲複製回本地
   - 刪除外部目錄（盡力而爲）

## 處理異常狀態

### 待規範

目錄由 AppPorts 管理，但外部路徑不在規範位置。點擊「規範化」按鈕，AppPorts 會將外部數據移動到規範路徑並重建符號鏈接。

### 待接回

外部存儲上的數據仍在，但本地符號鏈接已丟失。點擊「重新鏈接」按鈕，AppPorts 會重新創建符號鏈接。

### 現有軟鏈

非 AppPorts 創建的用戶自定義符號鏈接。可選擇「接管」，AppPorts 會寫入托管鏈接元數據，將其納入管理。

## 樹形視圖

對於包含子目錄的數據目錄（如 `Application Support` 下的多個應用目錄），AppPorts 提供樹形分組視圖：

- 父目錄左側顯示展開/摺疊箭頭
- 子目錄顯示層級縮進
- 每個節點獨立顯示大小和狀態
- 可對單個子目錄執行遷移/恢復操作
