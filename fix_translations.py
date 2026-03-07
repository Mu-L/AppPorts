import json

with open("AppPorts/Localizable.xcstrings", "r") as f:
    data = json.load(f)

# 核心翻译映射
updates = {
    "重要": {"en": "Critical", "zh-Hant": "重要"},
    "推荐": {"en": "Recommended", "zh-Hant": "推薦"},
    "可选": {"en": "Optional", "zh-Hant": "可選"},
    "应用核心数据（设置、数据库等）": {"en": "Application core data (settings, databases, etc.)", "zh-Hant": "應用程式核心資料（設定、資料庫等）"},
    "沙盒容器数据（App Store 应用）": {"en": "Sandbox container data (App Store apps)", "zh-Hant": "沙箱容器資料（App Store 應用程式）"},
    "应用组共享数据": {"en": "App group shared data", "zh-Hant": "應用程式組共享資料"},
    "应用缓存（可重建）": {"en": "App cache (rebuildable)", "zh-Hant": "應用程式快取（可重建）"},
    "窗口状态恢复数据": {"en": "Window state recovery data", "zh-Hant": "視窗狀態恢復資料"},
    "未发现已知工具目录": {"en": "No known tool directories found", "zh-Hant": "未發現已知工具目錄"},
    "无本地应用": {"en": "No local apps found", "zh-Hant": "無本地應用程式"},
    "选择应用": {"en": "Select App", "zh-Hant": "選擇應用程式"},
    "发现新版本": {"en": "New Version Found", "zh-Hant": "發現新版本"},
    "好的": {"en": "OK", "zh-Hant": "好的"},
    "前往下载": {"en": "Download Now", "zh-Hant": "前往下載"},
    "以后再说": {"en": "Later", "zh-Hant": "以後再說"},
    "App Store 应用": {"en": "App Store Apps", "zh-Hant": "App Store 應用程式"},
    "继续迁移": {"en": "Continue Migration", "zh-Hant": "繼續遷移"},
    "取消": {"en": "Cancel", "zh-Hant": "取消"}
}

# 格式化字符串翻译
fmt_updates = {
    "%@ 的数据目录": {
        "en": "%@'s Data Directory",
        "zh-Hans": "%@ 的数据目录",
        "zh-Hant": "%@ 的資料目錄",
        "ja": "%@ のデータディレクトリ",
        "ko": "%@의 데이터 디렉토리"
    },
    "%@ (%lld 个应用)": {
        "en": "%@ (%lld apps)",
        "zh-Hans": "%@ (%lld 个应用)",
        "zh-Hant": "%@ (%lld 個應用程式)"
    },
    "发现新版本 %@。\n%@": {
        "en": "New version found %@.\n%@",
        "zh-Hans": "发现新版本 %@。\n%@",
        "zh-Hant": "發現新版本 %@。\n%@"
    },
    "选中的 %lld 个应用均来自 App Store，迁移时会使用 Finder 删除，您会听到垃圾桶的声音。\n\n这是正常的，应用会被安全地移动到外部存储。": {
        "en": "The selected %lld apps are all from the App Store. They will be deleted using Finder during migration; you will hear the trash bin sound.\n\nThis is normal, as apps are securely moved to external storage.",
        "zh-Hans": "选中的 %lld 个应用均来自 App Store，迁移时会使用 Finder 删除，您会听到垃圾桶的声音。\n\n这是正常的，应用会被安全地移动到外部存储。",
        "zh-Hant": "選中的 %lld 個應用程式均來自 App Store，遷移時會使用 Finder 刪除，您會聽到垃圾桶的聲音。\n\n這正常，因為應用程式會被安全地移動到外部儲存。"
    },
    "选中的 %lld 个应用包含 %lld 个 App Store 应用，迁移时会使用 Finder 删除，您会听到垃圾桶的声音。\n\n这是正常的，应用会被安全地移动到外部存储。": {
        "en": "The selected %lld apps include %lld App Store apps. They will be deleted using Finder during migration; you will hear the trash bin sound.\n\nThis is normal, as apps are securely moved to external storage.",
        "zh-Hans": "选中的 %lld 个应用包含 %lld 个 App Store 应用，迁移时会使用 Finder 删除，您会听到垃圾桶的声音。\n\n这是正常的，应用会被安全地移动到外部存储。",
        "zh-Hant": "選中的 %lld 個應用程式包含 %lld 個 App Store 應用程式，遷移時會使用 Finder 刪除，您會聽到垃圾桶的聲音。\n\n這正常，因為應用程式會被安全地移動到外部儲存。"
    }
}

# 1. 更新现有键的 en 和 zh-Hant
for key, trans in updates.items():
    if key in data["strings"]:
        locs = data["strings"][key].get("localizations", {})
        if "en" in locs:
            locs["en"]["stringUnit"]["value"] = trans["en"]
        if "zh-Hant" in locs:
            locs["zh-Hant"]["stringUnit"]["value"] = trans["zh-Hant"]
        data["strings"][key]["localizations"] = locs

# 2. 添加/更新格式化字符串键
langs = ["ar", "br", "de", "en", "eo", "es", "fr", "hi", "id", "it", "ja", "ko", "nl", "pl", "pt", "ru", "th", "tr", "vi", "zh-Hans", "zh-Hant"]

for key, trans_map in fmt_updates.items():
    entry = data["strings"].get(key, {
        "extractionState": "manual",
        "localizations": {}
    })
    for lang in langs:
        val = trans_map.get(lang, trans_map.get("en", key))
        entry["localizations"][lang] = {
            "stringUnit": {
                "state": "translated",
                "value": val
            }
        }
    data["strings"][key] = entry

with open("AppPorts/Localizable.xcstrings", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Updated core translations with format strings successfully.")
