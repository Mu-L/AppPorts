import Combine
import Foundation

/// 跨页面、跨窗口保留文件操作的生命周期，阻止重建视图或重复启动迁移。
@MainActor
final class AppOperationState: ObservableObject {
    static let shared = AppOperationState()

    @Published private var activeOperation: UUID?

    var isBusy: Bool { activeOperation != nil }

    func begin() -> UUID? {
        guard activeOperation == nil else { return nil }
        let token = UUID()
        activeOperation = token
        return token
    }

    func finish(_ token: UUID) {
        guard activeOperation == token else { return }
        activeOperation = nil
    }
}
