import os, json, re

# 1. 扫描所有 Swift 文件，提取所有包含中文的字符串常量
swift_files = []
for root, dirs, files in os.walk("AppPorts"):
    for file in files:
        if file.endswith(".swift"):
            swift_files.append(os.path.join(root, file))

strings = set()
pattern = re.compile(r'\"([^\"]*[\u4e00-\u9fa5]+[^\"]*)\"')
for sf in swift_files:
    with open(sf, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("//"): continue
            if "AppLogger" in line or "print(" in line or ".log(" in line or "level:" in line: continue
            
            matches = pattern.findall(line)
            for m in matches:
                # 排除带有字符串插值的，这些我们在代码里改用 String(format: )
                if "\\(" in m: continue
                strings.add(m)

# 2. 读取 Localizable.xcstrings
with open("AppPorts/Localizable.xcstrings", "r") as f:
    data = json.load(f)

existing_keys = set(data["strings"].keys())
missing_keys = strings - existing_keys

print(f"找到 {len(missing_keys)} 个完全缺失的键")

# 简单繁体替换词典
hant_map = {
    "数据": "資料", "缓存": "快取", "设置": "設定", "运行": "執行",
    "推荐": "推薦", "可选": "可選", "应用": "應用程式", "目录": "目錄",
    "文件夹": "資料夾", "文件": "檔案", "全局": "全域", "环境": "環境",
    "网络": "網路", "识别": "辨識", "预": "預", "编程": "程式設計",
    "国内": "國內", "模型": "模型", "存储": "儲存", "浏览器": "瀏覽器",
    "内存": "記憶體", "测试": "測試", "配置": "設定", "失败": "失敗",
    "错误": "錯誤", "发现": "發現", "版本": "版本", "工具": "工具",
    "自定义": "自訂", "附加": "附加", "包含": "包含", "状态": "狀態",
    "恢复": "恢復", "共享": "共享"
}

def to_hant(text):
    res = text
    for k, v in hant_map.items():
        res = res.replace(k, v)
    return res

langs = ["ar", "br", "de", "en", "eo", "es", "fr", "hi", "id", "it", "ja", "ko", "nl", "pl", "pt", "ru", "th", "tr", "vi", "zh-Hans", "zh-Hant"]

added = 0
for mk in missing_keys:
    # 过滤掉明显的非 UI 文本
    if mk.startswith("====="): continue
    
    entry = {
        "extractionState": "manual",
        "localizations": {}
    }
    
    for lang in langs:
        val = mk
        if lang == "zh-Hant":
            val = to_hant(mk)
        elif lang != "zh-Hans" and lang != "zh-Hant":
            val = mk # Fallback to origin
            
        entry["localizations"][lang] = {
            "stringUnit": {
                "state": "translated",
                "value": val
            }
        }
    data["strings"][mk] = entry
    added += 1

with open("AppPorts/Localizable.xcstrings", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"成功添加 {added} 个键到 Localizable.xcstrings")
