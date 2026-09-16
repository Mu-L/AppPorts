import Foundation

/// 已授权的签名属于数据迁移流程：备份完成后才迁移，重签完成后才向调用方返回成功。
enum DataMigrationWorkflow {
    enum Failure: LocalizedError {
        case signingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .signingFailed(let error):
                return String(
                    format: "数据已迁移，但关联应用重签名失败：%@\n\n请在应用列表中重试重签名，或还原数据目录。".localized,
                    error.localizedDescription
                )
            }
        }
    }

    static func run(
        signingAppURL: URL?,
        backupSignature: (URL) async throws -> Void,
        migrate: () async throws -> Void,
        resignApp: (URL) async throws -> Void
    ) async throws {
        if let signingAppURL {
            try await backupSignature(signingAppURL)
        }

        try await migrate()

        if let signingAppURL {
            do {
                try await resignApp(signingAppURL)
            } catch {
                // 数据已经成功迁移；不要误报为迁移失败或自动再次搬运数据。
                throw Failure.signingFailed(error)
            }
        }
    }
}
