import Foundation

/// 只统计可从本地迁出的目录；父子目录和已挂载到外置盘的数据不能重复计入。
struct DataDirSpaceSummary {
    let reclaimableBytes: Int64
    let isCalculating: Bool
    let isIncomplete: Bool

    init(items: [DataDirItem], allItems: [DataDirItem], hasReadIssues: Bool = false, hasIdentityIssue: Bool = false) {
        let nonLocalItems = allItems.filter { $0.status != DataDirStatus.local }
        let candidates = items.filter { item in
            item.status == DataDirStatus.local && item.isMigratable
                && !nonLocalItems.contains { Self.isDescendant(item, of: $0) }
        }
        let roots = Self.outermost(candidates)
        // DirectoryEnumerator 不跨挂载卷，也不跟随软链，父项的测量已经排除了外置子目录。
        reclaimableBytes = roots.reduce(0) { $0 + $1.sizeBytes }
        isCalculating = roots.contains { $0.size == nil }
        isIncomplete = hasReadIssues || hasIdentityIssue || roots.contains { $0.sizeIsIncomplete }
    }

    private static func isDescendant(_ item: DataDirItem, of ancestor: DataDirItem) -> Bool {
        item.id.hasPrefix(ancestor.id == "/" ? "/" : ancestor.id + "/") && item.id != ancestor.id
    }

    private static func outermost(_ items: [DataDirItem]) -> [DataDirItem] {
        var seen = Set<String>()
        let uniqueItems = items.filter { seen.insert($0.id).inserted }
        return uniqueItems.filter { item in
            !uniqueItems.contains { isDescendant(item, of: $0) }
        }
    }
}
