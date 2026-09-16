//
//  CodeSigner.swift
//  AppPorts
//

import Foundation

actor CodeSigner {

    enum SigningError: LocalizedError {
        case codesignFailed(String)
        case backupFailed(String)
        case restoreFailed(String)
        case noBackupFound
        case applicationUnavailable(URL)

        var errorDescription: String? {
            switch self {
            case .codesignFailed(let msg):
                return String(format: "签名失败: %@".localized, msg)
            case .backupFailed(let msg):
                return String(format: "备份签名失败: %@".localized, msg)
            case .restoreFailed(let msg):
                return String(format: "恢复签名失败: %@".localized, msg)
            case .noBackupFound:
                return "未找到原始签名备份".localized
            case .applicationUnavailable(let url):
                return String(format: "无法找到真实应用，无法重签名：%@".localized, url.path)
            }
        }
    }

    private static let backupDirectoryName = "signature-backups"

    private static var defaultBackupDirectoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("AppPorts/\(backupDirectoryName)")
    }

    private let fileManager = FileManager.default
    private let backupDirectoryURL: URL
    private let allowAdministratorPrompt: Bool

    init(backupDirectoryURL: URL? = nil, allowAdministratorPrompt: Bool = true) {
        self.backupDirectoryURL = backupDirectoryURL ?? Self.defaultBackupDirectoryURL
        self.allowAdministratorPrompt = allowAdministratorPrompt
    }

    static func ownershipRepairAppleScript(username: String, appPath: String) -> String {
        """
        set targetPath to \(AppMigrationService.appleScriptStringLiteral(appPath))
        set userName to \(AppMigrationService.appleScriptStringLiteral(username))
        do shell script "/usr/sbin/chown -R -P " & quoted form of userName & " " & quoted form of targetPath with administrator privileges
        """
    }

    // MARK: - Public API

    /// 解析真实应用包，不依赖可能已经过期的扫描状态，也不在目标缺失时退回签名本地入口。
    static func resolveAppURL(at appURL: URL) throws -> URL {
        let fileManager = FileManager.default
        var candidate = appURL.standardizedFileURL
        var visited = Set<String>()

        while visited.insert(candidate.path).inserted {
            candidate = candidate.resolvingSymlinksInPath().standardizedFileURL
            var isDirectory: ObjCBool = false
            guard candidate.pathExtension.lowercased() == "app",
                  fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                throw SigningError.applicationUnavailable(candidate)
            }

            let pathFile = candidate.appendingPathComponent("Contents/Resources/real_app_path.txt")
            if (try? fileManager.attributesOfItem(atPath: pathFile.path)) != nil {
                guard let path = try? String(contentsOf: pathFile, encoding: .utf8)
                    .trimmingCharacters(in: .whitespacesAndNewlines), path.hasPrefix("/") else {
                    throw SigningError.applicationUnavailable(candidate)
                }
                candidate = URL(fileURLWithPath: path).standardizedFileURL
                continue
            }

            // 兼容旧 bash Stub；只解析字面量，绝不执行脚本。
            let launcher = candidate.appendingPathComponent("Contents/MacOS/launcher")
            if let script = try? String(contentsOf: launcher, encoding: .utf8),
               let assignment = script.components(separatedBy: .newlines)
                .map({ $0.trimmingCharacters(in: .whitespaces) })
                .first(where: { $0.hasPrefix("REAL_APP=") }) {
                guard assignment.hasPrefix("REAL_APP='"), assignment.hasSuffix("'") else {
                    throw SigningError.applicationUnavailable(candidate)
                }
                let path = String(assignment.dropFirst("REAL_APP='".count).dropLast())
                    .replacingOccurrences(of: "'\\''", with: "'")
                guard path.hasPrefix("/") else {
                    throw SigningError.applicationUnavailable(candidate)
                }
                candidate = URL(fileURLWithPath: path).standardizedFileURL
                continue
            }

            // 旧 Deep Contents Wrapper 必须直接签外部包，不能签完临时 Contents 副本后丢弃。
            let contents = candidate.appendingPathComponent("Contents")
            if let target = try? fileManager.destinationOfSymbolicLink(atPath: contents.path) {
                candidate = URL(fileURLWithPath: target, relativeTo: candidate)
                    .standardizedFileURL.deletingLastPathComponent()
                continue
            }

            if bundleIdentifier(at: candidate)?.hasSuffix(".appports.stub") == true {
                throw SigningError.applicationUnavailable(candidate)
            }
            return candidate
        }

        throw SigningError.applicationUnavailable(candidate)
    }

    static func bundleIdentifier(at appURL: URL) -> String? {
        let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        return plist["CFBundleIdentifier"] as? String
    }

    /// 仅备份原始签名身份（不执行签名），用于迁移前预备份
    func backupOriginalSignature(appURL: URL, bundleIdentifier: String) throws {
        let appURL = try Self.resolveAppURL(at: appURL)
        try ensureBackupDirectory()
        try saveOriginalSignature(appURL: appURL, bundleIdentifier: Self.bundleIdentifier(at: appURL) ?? bundleIdentifier)
    }

    /// 临时解锁真实应用及其子项，完成深度重签和校验后恢复原有锁定状态。
    func sign(appURL: URL, bundleIdentifier: String?) async throws {
        let appURL = try Self.resolveAppURL(at: appURL)
        try ensureBackupDirectory()

        if let bundleID = Self.bundleIdentifier(at: appURL) ?? bundleIdentifier {
            try saveOriginalSignature(appURL: appURL, bundleIdentifier: bundleID)
        }

        try withUnlockedBundle(at: appURL) { items in
            try withOwnershipRepair(at: appURL) {
                try stripSigningDetritus(from: items)
                cleanBundleRoot(at: appURL)
                try runCodesign(arguments: ["--force", "--deep", "--sign", "-", appURL.path])
                try runCodesign(arguments: ["--verify", "--deep", "--strict", appURL.path], retries: 0)
            }
        }

        AppLogger.shared.logContext(
            "Ad-hoc 重签名完成",
            details: [("path", appURL.path)]
        )
    }

    /// 验证签名
    func verify(appURL: URL) async -> SignatureStatus {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--verify", "--deep", "--strict", appURL.path]

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return .unknown
        }

        if process.terminationStatus == 0 {
            return .valid
        }

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        if errorOutput.contains("code object is not signed at all") {
            return .unsigned
        }
        if errorOutput.contains("invalid signature") || errorOutput.contains("ad-hoc") {
            return .adHoc
        }

        return .invalid
    }

    /// 获取当前签名身份
    func getSigningIdentity(appURL: URL) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["-dvv", appURL.path]

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        for line in output.components(separatedBy: "\n") {
            if line.contains("Authority=") {
                return line
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "Authority=", with: "")
            }
        }
        return nil
    }

    /// 恢复原始签名
    ///
    /// 读取备份 plist，用原始签名身份重新签名。
    func restoreSignature(appURL: URL, bundleIdentifier: String) async throws {
        let appURL = try Self.resolveAppURL(at: appURL)
        let bundleIdentifier = Self.bundleIdentifier(at: appURL) ?? bundleIdentifier
        guard let backup = loadBackup(bundleIdentifier: bundleIdentifier) else {
            throw SigningError.noBackupFound
        }

        let identity = backup.signingIdentity
        try withUnlockedBundle(at: appURL) { items in
            try withOwnershipRepair(at: appURL) {
                try stripSigningDetritus(from: items)
                cleanBundleRoot(at: appURL)
                if identity.isEmpty || identity == "ad-hoc" {
                    try runCodesign(arguments: ["--remove-signature", appURL.path])
                    return
                }

                let signingIdentity: String
                if isIdentityAvailable(identity) {
                    signingIdentity = identity
                } else {
                    AppLogger.shared.logContext(
                        "原始签名身份不在钥匙串中，回退到 ad-hoc 签名",
                        details: [("identity", identity), ("path", appURL.path)],
                        level: "WARN"
                    )
                    signingIdentity = "-"
                }
                try runCodesign(arguments: ["--force", "--deep", "--sign", signingIdentity, appURL.path])
                try runCodesign(arguments: ["--verify", "--deep", "--strict", appURL.path], retries: 0)
            }
        }

        removeBackup(bundleIdentifier: bundleIdentifier)
        AppLogger.shared.logContext(
            "恢复原始签名完成",
            details: [
                ("path", appURL.path),
                ("identity", identity),
                ("bundle_id", bundleIdentifier)
            ]
        )
    }

    /// 检查是否有备份
    func hasBackup(bundleIdentifier: String) -> Bool {
        let backupURL = backupFileURL(for: bundleIdentifier)
        return fileManager.fileExists(atPath: backupURL.path)
    }

    // MARK: - Signature Status

    enum SignatureStatus: Equatable {
        case valid
        case adHoc
        case unsigned
        case invalid
        case unknown
    }

    // MARK: - Backup Management

    private struct SignatureBackup: Codable {
        let bundleIdentifier: String
        let signingIdentity: String
        let originalPath: String
        let backupDate: Date
    }

    private func saveOriginalSignature(appURL: URL, bundleIdentifier: String) throws {
        let backupURL = backupFileURL(for: bundleIdentifier)
        guard !fileManager.fileExists(atPath: backupURL.path) else { return }

        let identity = syncGetSigningIdentity(appURL: appURL)
        let backup = SignatureBackup(
            bundleIdentifier: bundleIdentifier,
            signingIdentity: identity ?? "ad-hoc",
            originalPath: appURL.path,
            backupDate: Date()
        )

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(backup)
        try data.write(to: backupURL)
        AppLogger.shared.logContext(
            "签名身份已备份",
            details: [
                ("bundle_id", bundleIdentifier),
                ("identity", backup.signingIdentity),
                ("backup_path", backupURL.path)
            ]
        )
    }

    private func loadBackup(bundleIdentifier: String) -> SignatureBackup? {
        let backupURL = backupFileURL(for: bundleIdentifier)
        guard let data = try? Data(contentsOf: backupURL) else { return nil }
        return try? PropertyListDecoder().decode(SignatureBackup.self, from: data)
    }

    private func removeBackup(bundleIdentifier: String) {
        let backupURL = backupFileURL(for: bundleIdentifier)
        try? fileManager.removeItem(at: backupURL)
    }

    private func backupFileURL(for bundleIdentifier: String) -> URL {
        backupDirectoryURL.appendingPathComponent("\(bundleIdentifier).plist")
    }

    private func ensureBackupDirectory() throws {
        let dir = backupDirectoryURL
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Immutable Handling

    /// 枚举包内所有子项（包括隐藏文件和嵌套 .app），不跟随符号链接。
    private func bundleItems(at appURL: URL) throws -> [URL] {
        var enumerationError: Error?
        guard let enumerator = fileManager.enumerator(
            at: appURL,
            includingPropertiesForKeys: nil,
            errorHandler: { _, error in
                enumerationError = error
                return false
            }
        ) else {
            throw CocoaError(.fileReadUnknown, userInfo: [NSFilePathErrorKey: appURL.path])
        }
        var items = [appURL]
        // DirectoryEnumerator 默认不跟随链接；对链接调用 skipDescendants()
        // 反而会跳过下一个真实目录（如框架的 Versions/A），漏掉其锁定文件。
        for case let url as URL in enumerator {
            items.append(url)
        }
        if let enumerationError { throw enumerationError }
        return items
    }

    private func fileInfo(at url: URL) throws -> stat {
        var info = stat()
        guard lstat(url.path, &info) == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSFilePathErrorKey: url.path])
        }
        return info
    }

    /// 仅修改 uchg 位，并用 lchflags 避免改到链接目标。
    private func setImmutable(_ immutable: Bool, at url: URL) throws {
        let info = try fileInfo(at: url)
        let flags = immutable ? info.st_flags | UInt32(UF_IMMUTABLE) : info.st_flags & ~UInt32(UF_IMMUTABLE)
        guard lchflags(url.path, flags) == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSFilePathErrorKey: url.path])
        }
    }

    private func restoreImmutableItems(_ items: [URL]) throws {
        var firstError: Error?
        for url in items.reversed() {
            do {
                // codesign 可以替换文件；按原路径恢复锁，保留新的其它 flags。
                // 清理掉的 .DS_Store 等项目无需重建。
                if (try? fileManager.attributesOfItem(atPath: url.path)) != nil {
                    try setImmutable(true, at: url)
                }
            } catch {
                firstError = firstError ?? error
            }
        }
        if let firstError { throw firstError }
    }

    private func withUnlockedBundle(at appURL: URL, operation: ([URL]) throws -> Void) throws {
        let items = try bundleItems(at: appURL)
        var unlocked: [URL] = []
        do {
            for url in items {
                if try fileInfo(at: url).st_flags & UInt32(UF_IMMUTABLE) != 0 {
                    try setImmutable(false, at: url)
                    unlocked.append(url)
                }
            }
            try operation(items)
            try restoreImmutableItems(unlocked)
        } catch {
            do {
                try restoreImmutableItems(unlocked)
            } catch let restoreError {
                AppLogger.shared.logError(
                    "恢复应用锁定状态失败",
                    error: restoreError,
                    relatedURLs: [("app", appURL)]
                )
            }
            throw error
        }
    }

    // MARK: - Identity Check

    /// 检查签名身份是否存在于钥匙串中（精确匹配，非子串）
    private func isIdentityAvailable(_ identity: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-identity", "-v", "-p", "codesigning"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // 解析 security find-identity 输出，格式：
        //   1) HASH "identity name"
        // 精确匹配引号内的身份名称
        for line in output.components(separatedBy: "\n") {
            guard let start = line.firstIndex(of: "\""),
                  let end = line[start...].dropFirst().firstIndex(of: "\"") else { continue }
            let found = String(line[line.index(after: start)..<end])
            if found == identity { return true }
        }
        return false
    }

    // MARK: - Codesign Execution

    @discardableResult
    private func runCodesign(arguments: [String], retries: Int = 2) throws -> String {
        var lastError: String = ""

        for attempt in 0...retries {
            if attempt > 0 {
                Thread.sleep(forTimeInterval: Double(attempt) * 1.0)
                AppLogger.shared.logContext(
                    "重试 codesign",
                    details: [("attempt", String(attempt)), ("arguments", arguments.joined(separator: " "))],
                    level: "WARN"
                )
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
            process.arguments = arguments

            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            try process.run()
            // 持续读取，避免深度签名产生大量输出时填满 pipe 而无法退出。
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let output = String(data: outputData, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                return output
            }

            lastError = output.isEmpty ? "exit code \(process.terminationStatus)" : output

            // 只对瞬态错误重试（internal error、SIGKILL 等）
            let isTransient = output.contains("internal error")
                || process.terminationStatus == 9
                || process.terminationStatus == 137
            if !isTransient { break }
        }

        throw SigningError.codesignFailed(lastError)
    }

    /// 仅清理 codesign 禁止的 resource fork/Finder 信息，保留其它元数据及脚本签名属性。
    private func stripSigningDetritus(from items: [URL]) throws {
        for url in items {
            for name in ["com.apple.ResourceFork", "com.apple.FinderInfo"] {
                let size = getxattr(url.path, name, nil, 0, 0, XATTR_NOFOLLOW)
                if size < 0 {
                    // 重试时，首次尝试可能已清理 .DS_Store 等杂散文件。
                    if errno == ENOATTR || errno == ENOTSUP || errno == ENOENT { continue }
                    throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSFilePathErrorKey: url.path])
                }
                if removexattr(url.path, name, XATTR_NOFOLLOW) != 0, errno != ENOATTR {
                    throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSFilePathErrorKey: url.path])
                }
            }
        }
    }

    /// codesign 可以替换只读可执行文件；只在实际操作报告权限错误时请求修复。
    private func withOwnershipRepair(at appURL: URL, operation: () throws -> Void) throws {
        do {
            try operation()
        } catch {
            guard allowAdministratorPrompt, isPermissionFailure(error) else { throw error }
            AppLogger.shared.logContext(
                "应用由 root 安装，尝试请求管理员权限修复",
                details: [("path", appURL.path)],
                level: "WARN"
            )
            try elevateAndFixOwnership(at: appURL)
            do {
                try operation()
            } catch {
                guard isPermissionFailure(error) else { throw error }
                throw SigningError.codesignFailed(
                    String(format: "应用不可写，无法完成重签名：%@".localized, appURL.path)
                        + "\n" + error.localizedDescription
                )
            }
        }
    }

    private func isPermissionFailure(_ error: Error) -> Bool {
        if case SigningError.codesignFailed(let message) = error {
            return message.localizedCaseInsensitiveContains("permission denied")
                || message.localizedCaseInsensitiveContains("operation not permitted")
        }
        let nsError = error as NSError
        if nsError.domain == NSPOSIXErrorDomain {
            return nsError.code == Int(EACCES) || nsError.code == Int(EPERM)
        }
        if nsError.domain == NSCocoaErrorDomain,
           nsError.code == CocoaError.fileReadNoPermission.rawValue
            || nsError.code == CocoaError.fileWriteNoPermission.rawValue {
            return true
        }
        return nsError.underlyingErrors.contains(where: isPermissionFailure)
    }

    /// 请求管理员权限，将 app bundle 的 owner 修改为当前用户
    ///
    /// 使用 NSAppleScript 弹出系统密码框，执行 chown -R 将 bundle 所有权改为当前用户。
    /// App Store 应用受 SIP 保护，chown 可能部分失败，不抛出错误仅记录日志。
    private func elevateAndFixOwnership(at appURL: URL) throws {
        let username = NSUserName()
        let script = Self.ownershipRepairAppleScript(username: username, appPath: appURL.path)

        let appleScript = NSAppleScript(source: script)
        var errorInfo: NSDictionary?
        appleScript?.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let number = errorInfo[NSAppleScript.errorNumber] as? Int ?? -1
            if number == -128 {
                throw SigningError.codesignFailed("用户取消了权限授权".localized)
            }
            // chown 失败（如 SIP 保护的文件），不抛出，仅记录日志
            let msg = errorInfo[NSAppleScript.errorMessage] as? String ?? "未知错误".localized
            AppLogger.shared.logContext(
                "权限修复部分失败（可能受 SIP 保护），继续尝试签名",
                details: [("path", appURL.path), ("error", msg)],
                level: "WARN"
            )
        } else {
            AppLogger.shared.logContext(
                "已通过管理员权限修复 bundle 所有权",
                details: [("path", appURL.path), ("new_owner", username)]
            )
        }
    }

    /// 清理 .app bundle 根目录中的杂散文件，避免 codesign 报 "unsealed contents present in the bundle root"
    private func cleanBundleRoot(at appURL: URL) {
        let strayNames: Set<String> = [".DS_Store", "__MACOSX", ".git", ".svn"]
        guard let items = try? fileManager.contentsOfDirectory(atPath: appURL.path) else { return }
        for item in items {
            guard strayNames.contains(item) else { continue }
            let itemURL = appURL.appendingPathComponent(item)
            try? fileManager.removeItem(at: itemURL)
        }
    }

    /// 同步获取签名身份（actor 内部用）
    private func syncGetSigningIdentity(appURL: URL) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["-dvv", appURL.path]

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        for line in output.components(separatedBy: "\n") {
            if line.contains("Authority=") {
                return line
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "Authority=", with: "")
            }
        }
        return nil
    }
}
