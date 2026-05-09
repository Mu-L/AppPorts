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
            }
        }
    }

    private static let backupDirectoryName = "signature-backups"

    private static var backupDirectoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("AppPorts/\(backupDirectoryName)")
    }

    private let fileManager = FileManager.default

    // MARK: - Public API

    /// Ad-hoc 重签名
    ///
    /// 临时解锁（如需）、签名、再重新锁定。
    /// 如果 app 已迁移（Contents 为符号链接），会临时替换为真实目录副本以通过 codesign 检查。
    /// 仅备份原始签名身份（不执行签名），用于迁移前预备份
    func backupOriginalSignature(appURL: URL, bundleIdentifier: String) throws {
        try ensureBackupDirectory()
        try saveOriginalSignature(appURL: appURL, bundleIdentifier: bundleIdentifier)
    }

    func sign(appURL: URL, bundleIdentifier: String?) async throws {
        try ensureBackupDirectory()

        if let bundleID = bundleIdentifier {
            try saveOriginalSignature(appURL: appURL, bundleIdentifier: bundleID)
        }

        let wasLocked = unlockIfImmutable(at: appURL)
        defer {
            if wasLocked {
                lockItem(at: appURL)
            }
        }

        // 检查 app bundle 是否可写（root 安装 / MAS 应用无法重签名）
        if !isBundleWritable(at: appURL) {
            AppLogger.shared.logContext(
                "应用由 root 安装，尝试请求管理员权限修复",
                details: [("path", appURL.path)],
                level: "WARN"
            )
            try elevateAndFixOwnership(at: appURL)
            // 修复后再次检查
            if !isBundleWritable(at: appURL) {
                // MAS 应用受 SIP 保护，即使 sudo chown 也无法修改
                if isMASApp(at: appURL) {
                    AppLogger.shared.logContext(
                        "MAS 应用受 SIP 保护，无法重签名，跳过",
                        details: [("path", appURL.path)],
                        level: "WARN"
                    )
                    return
                }
                throw SigningError.codesignFailed(
                    "权限修复失败，无法重签名。请手动执行: sudo chown -R $(whoami) \"\(appURL.path)\""
                )
            }
        }

        // 检查 Contents 是否为符号链接（已迁移的 Deep Contents Wrapper app）
        let contentsURL = appURL.appendingPathComponent("Contents")
        var symlinkTarget: URL? = nil
        if let attrs = try? fileManager.attributesOfItem(atPath: contentsURL.path),
           let fileType = attrs[.type] as? FileAttributeType,
           fileType == .typeSymbolicLink,
           let target = try? fileManager.destinationOfSymbolicLink(atPath: contentsURL.path) {
            symlinkTarget = URL(fileURLWithPath: target)
        }

        if let realContents = symlinkTarget {
            // 临时将 Contents 符号链接替换为真实目录副本，否则 codesign 会报
            // "unsealed contents present in the bundle root"
            try fileManager.removeItem(at: contentsURL)
            try fileManager.copyItem(at: realContents, to: contentsURL)
            // 对替换后的 Contents 也剥离扩展属性
            stripExtendedAttributes(at: contentsURL)
        }

        defer {
            // 恢复符号链接
            if let realContents = symlinkTarget {
                try? fileManager.removeItem(at: contentsURL)
                try? fileManager.createSymbolicLink(at: contentsURL, withDestinationURL: realContents)
            }
        }

        // 清理扩展属性和杂散文件（必须在确认可签名后执行，避免剥离签名后无法重签导致应用变未签名）
        stripExtendedAttributes(at: appURL)
        cleanBundleRoot(at: appURL)

        let deepArgs = ["--force", "--deep", "--sign", "-", appURL.path]
        let shallowArgs = ["--force", "--sign", "-", appURL.path]

        do {
            try runCodesign(arguments: deepArgs)
        } catch {
            let errorMsg = (error as? SigningError)?.errorDescription ?? error.localizedDescription
            // 权限错误或 detritus 错误 → 回退到不加 --deep 的表层签名
            if errorMsg.contains("Permission denied")
                || errorMsg.contains("detritus")
                || errorMsg.contains("resource fork") {
                AppLogger.shared.logContext(
                    "--deep 签名失败，回退到表层签名",
                    details: [("path", appURL.path), ("error", errorMsg)],
                    level: "WARN"
                )
                try runCodesign(arguments: shallowArgs)
            } else {
                throw error
            }
        }

        AppLogger.shared.logContext(
            "Ad-hoc 重签名完成",
            details: [("path", appURL.path), ("symlink_resolved", symlinkTarget != nil ? "true" : "false")]
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
        guard let backup = loadBackup(bundleIdentifier: bundleIdentifier) else {
            throw SigningError.noBackupFound
        }

        let wasLocked = unlockIfImmutable(at: appURL)
        defer {
            if wasLocked {
                lockItem(at: appURL)
            }
        }

        // 检查 Contents 是否为符号链接（已迁移的 app）
        let contentsURL = appURL.appendingPathComponent("Contents")
        var symlinkTarget: URL? = nil
        if let attrs = try? fileManager.attributesOfItem(atPath: contentsURL.path),
           let fileType = attrs[.type] as? FileAttributeType,
           fileType == .typeSymbolicLink,
           let target = try? fileManager.destinationOfSymbolicLink(atPath: contentsURL.path) {
            symlinkTarget = URL(fileURLWithPath: target)
        }

        if let realContents = symlinkTarget {
            try fileManager.removeItem(at: contentsURL)
            try fileManager.copyItem(at: realContents, to: contentsURL)
            stripExtendedAttributes(at: contentsURL)
        }

        defer {
            if let realContents = symlinkTarget {
                try? fileManager.removeItem(at: contentsURL)
                try? fileManager.createSymbolicLink(at: contentsURL, withDestinationURL: realContents)
            }
        }

        // 检查 app bundle 可写性（root 安装的应用需要修复权限）
        if !isBundleWritable(at: appURL) {
            AppLogger.shared.logContext(
                "恢复签名前检测到 root 安装，尝试修复权限",
                details: [("path", appURL.path)],
                level: "WARN"
            )
            try elevateAndFixOwnership(at: appURL)
            if !isBundleWritable(at: appURL) {
                if isMASApp(at: appURL) {
                    AppLogger.shared.logContext(
                        "MAS 应用受 SIP 保护，无法恢复签名，跳过",
                        details: [("path", appURL.path)],
                        level: "WARN"
                    )
                    return
                }
            }
        }

        let identity = backup.signingIdentity
        // 清理扩展属性和杂散文件（必须在确认可签名后执行，避免剥离签名后无法重签导致应用变未签名）
        stripExtendedAttributes(at: appURL)
        cleanBundleRoot(at: appURL)
        let deepArgs: [String]
        let shallowArgs: [String]
        if identity.isEmpty || identity == "ad-hoc" {
            _ = try runCodesign(arguments: ["--remove-signature", appURL.path])
            // 已移除签名，不需要后续重签
            removeBackup(bundleIdentifier: bundleIdentifier)
            AppLogger.shared.logContext("恢复原始签名完成（已移除签名）", details: [("path", appURL.path), ("bundle_id", bundleIdentifier)])
            return
        } else if isIdentityAvailable(identity) {
            deepArgs = ["--force", "--deep", "--sign", identity, appURL.path]
            shallowArgs = ["--force", "--sign", identity, appURL.path]
        } else {
            AppLogger.shared.logContext(
                "原始签名身份不在钥匙串中，回退到 ad-hoc 签名",
                details: [("identity", identity), ("path", appURL.path)],
                level: "WARN"
            )
            deepArgs = ["--force", "--deep", "--sign", "-", appURL.path]
            shallowArgs = ["--force", "--sign", "-", appURL.path]
        }

        do {
            _ = try runCodesign(arguments: deepArgs)
        } catch {
            let errorMsg = (error as? SigningError)?.errorDescription ?? error.localizedDescription
            if errorMsg.contains("Permission denied")
                || errorMsg.contains("detritus")
                || errorMsg.contains("resource fork") {
                AppLogger.shared.logContext(
                    "--deep 签名失败，回退到表层签名",
                    details: [("path", appURL.path), ("error", errorMsg)],
                    level: "WARN"
                )
                _ = try runCodesign(arguments: shallowArgs)
            } else {
                throw error
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

    enum SignatureStatus {
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
        Self.backupDirectoryURL.appendingPathComponent("\(bundleIdentifier).plist")
    }

    private func ensureBackupDirectory() throws {
        let dir = Self.backupDirectoryURL
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Immutable Handling

    /// 解锁文件（如被 AppMigrationService 锁定），返回之前是否锁定
    private func unlockIfImmutable(at url: URL) -> Bool {
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let immutable = attrs[.immutable] as? Bool, immutable else {
            return false
        }
        try? fileManager.setAttributes([.immutable: false], ofItemAtPath: url.path)
        return true
    }

    private func lockItem(at url: URL) {
        try? fileManager.setAttributes([.immutable: true], ofItemAtPath: url.path)
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
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: outputData, encoding: .utf8) ?? ""
            }

            lastError = errorOutput.isEmpty ? "exit code \(process.terminationStatus)" : errorOutput

            // 只对瞬态错误重试（internal error、SIGKILL 等）
            let isTransient = errorOutput.contains("internal error")
                || process.terminationStatus == 9
                || process.terminationStatus == 137
            if !isTransient { break }
        }

        throw SigningError.codesignFailed(lastError)
    }

    /// 递归剥离所有扩展属性（resource fork、Finder 信息等），避免 codesign 报 "detritus not allowed"
    private func stripExtendedAttributes(at url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-cr", url.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }

    /// 检查是否为 Mac App Store 应用（Contents 中存在 _MASReceipt 目录）
    private func isMASApp(at appURL: URL) -> Bool {
        let masReceiptURL = appURL.appendingPathComponent("Contents/_MASReceipt")
        return fileManager.fileExists(atPath: masReceiptURL.path)
    }

    /// 检查 app bundle 是否可写（排除 root 安装的情况）
    private func isBundleWritable(at appURL: URL) -> Bool {
        guard let attrs = try? fileManager.attributesOfItem(atPath: appURL.path),
              let owner = attrs[.ownerAccountName] as? String else {
            return false
        }
        // 如果 owner 是 root，当前用户可能无法写入
        if owner == "root" {
            return fileManager.isWritableFile(atPath: appURL.path)
        }
        return true
    }

    /// 请求管理员权限，将 app bundle 的 owner 修改为当前用户
    ///
    /// 使用 NSAppleScript 弹出系统密码框，执行 chown -R 将 bundle 所有权改为当前用户。
    /// App Store 应用受 SIP 保护，chown 可能部分失败，不抛出错误仅记录日志。
    private func elevateAndFixOwnership(at appURL: URL) throws {
        let username = NSUserName()
        let shellCmd = "/usr/sbin/chown -R \(username) '\(appURL.path)'"
        let script = "do shell script \"\(shellCmd)\" with administrator privileges"

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
