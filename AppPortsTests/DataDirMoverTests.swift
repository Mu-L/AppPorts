import XCTest
@testable import AppPorts

final class DataDirMoverTests: XCTestCase {
    private let fileManager = FileManager.default
    private var originalLogEnabledValue: Any?

    override func setUpWithError() throws {
        try super.setUpWithError()
        originalLogEnabledValue = UserDefaults.standard.object(forKey: "LogEnabled")
        UserDefaults.standard.set(false, forKey: "LogEnabled")
    }

    override func tearDownWithError() throws {
        if let originalLogEnabledValue {
            UserDefaults.standard.set(originalLogEnabledValue, forKey: "LogEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "LogEnabled")
        }

        try super.tearDownWithError()
    }

    func testMigrateAndRestoreRoundTripForApplicationSupportDirectory() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localDataURL = workspace.homeURL
            .appendingPathComponent("Library/Application Support/com.example.focus")
        let externalBaseURL = workspace.externalRootURL
            .appendingPathComponent("Library/Application Support")
        let externalDataURL = externalBaseURL.appendingPathComponent(localDataURL.lastPathComponent)

        try createDirectoryWithPayload(at: localDataURL, payload: "focus-state")

        let item = DataDirItem(
            name: "Focus",
            path: localDataURL,
            type: .applicationSupport,
            priority: .critical,
            description: "Test payload",
            isMigratable: true
        )

        let mover = DataDirMover(homeDir: workspace.homeURL)
        try await mover.migrate(item: item, to: externalBaseURL, progressHandler: nil)

        try assertSymlink(localDataURL, pointsTo: externalDataURL)
        XCTAssertTrue(fileManager.fileExists(atPath: markerURL(for: externalDataURL).path))
        XCTAssertEqual(try String(contentsOf: externalDataURL.appendingPathComponent("payload.txt")), "focus-state")

        try await mover.restore(
            item: DataDirItem(
                name: item.name,
                path: localDataURL,
                type: item.type,
                priority: item.priority,
                description: item.description,
                status: "已链接",
                isMigratable: true
            ),
            progressHandler: nil
        )

        try assertRealDirectory(localDataURL)
        XCTAssertEqual(try String(contentsOf: localDataURL.appendingPathComponent("payload.txt")), "focus-state")
        XCTAssertFalse(fileManager.fileExists(atPath: externalDataURL.path))
    }

    func testMigrateRollsBackWhenSymlinkCreationFails() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localDataURL = workspace.homeURL
            .appendingPathComponent("Library/Caches/com.example.rollback")
        let externalBaseURL = workspace.externalRootURL
            .appendingPathComponent("Library/Caches")
        let externalDataURL = externalBaseURL.appendingPathComponent(localDataURL.lastPathComponent)

        try createDirectoryWithPayload(at: localDataURL, payload: "rollback-safe")

        let item = DataDirItem(
            name: "Rollback",
            path: localDataURL,
            type: .caches,
            priority: .optional,
            description: "Test payload",
            isMigratable: true
        )

        let mover = DataDirMover(homeDir: workspace.homeURL, failSymlinkCreation: true)

        do {
            try await mover.migrate(item: item, to: externalBaseURL, progressHandler: nil)
            XCTFail("Expected migrate to fail when symlink creation is forced to fail")
        } catch let error as DataDirError {
            guard case .symlinkFailed = error else {
                return XCTFail("Expected symlinkFailed, got \(error)")
            }
        }

        try assertRealDirectory(localDataURL)
        XCTAssertEqual(try String(contentsOf: localDataURL.appendingPathComponent("payload.txt")), "rollback-safe")
        XCTAssertFalse(fileManager.fileExists(atPath: externalDataURL.path))
    }

    func testMigrateRemovesPartialExternalDirectoryWhenCopyFails() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localDataURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.example.permission")
        let externalBaseURL = workspace.externalRootURL
            .appendingPathComponent("Library/Containers")
        let externalDataURL = externalBaseURL.appendingPathComponent(localDataURL.lastPathComponent)
        let unreadableFileURL = localDataURL.appendingPathComponent(".com.apple.containermanagerd.metadata.plist")

        try fileManager.createDirectory(at: localDataURL, withIntermediateDirectories: true)
        try "ok".write(
            to: localDataURL.appendingPathComponent("payload.txt"),
            atomically: true,
            encoding: .utf8
        )
        try "blocked".write(
            to: unreadableFileURL,
            atomically: true,
            encoding: .utf8
        )
        try fileManager.setAttributes([.posixPermissions: 0], ofItemAtPath: unreadableFileURL.path)
        defer { try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: unreadableFileURL.path) }

        let item = DataDirItem(
            name: "PermissionDenied",
            path: localDataURL,
            type: .containers,
            priority: .critical,
            description: "Permission failure fixture",
            isMigratable: true
        )

        let mover = DataDirMover(homeDir: workspace.homeURL)

        do {
            try await mover.migrate(item: item, to: externalBaseURL, progressHandler: nil)
            XCTFail("Expected migrate to fail when source copy encounters an unreadable file")
        } catch let error as DataDirError {
            guard case .copyFailed = error else {
                return XCTFail("Expected copyFailed, got \(error)")
            }
        }

        try assertRealDirectory(localDataURL)
        XCTAssertTrue(fileManager.fileExists(atPath: localDataURL.path))
        XCTAssertFalse(fileManager.fileExists(atPath: externalDataURL.path))
        XCTAssertFalse(fileManager.fileExists(atPath: externalBaseURL.path))
        XCTAssertTrue(fileManager.fileExists(atPath: workspace.externalRootURL.path))
    }

    func testNormalizeManagedLinkMovesDataToNormalizedDestination() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localDataURL = workspace.homeURL
            .appendingPathComponent("Library/Application Support/com.example.normalize")
        let currentExternalURL = workspace.rootURL
            .appendingPathComponent("ManualStore/com.example.normalize")
        let normalizedExternalURL = workspace.externalRootURL
            .appendingPathComponent("Library/Application Support/com.example.normalize")

        try createDirectoryWithPayload(at: currentExternalURL, payload: "normalized")

        let mover = DataDirMover(homeDir: workspace.homeURL)
        try await mover.createLink(localPath: localDataURL, externalPath: currentExternalURL)

        try await mover.normalizeManagedLink(
            localPath: localDataURL,
            currentExternalPath: currentExternalURL,
            normalizedExternalPath: normalizedExternalURL
        )

        try assertSymlink(localDataURL, pointsTo: normalizedExternalURL)
        XCTAssertFalse(fileManager.fileExists(atPath: currentExternalURL.path))
        XCTAssertEqual(try String(contentsOf: normalizedExternalURL.appendingPathComponent("payload.txt")), "normalized")
        XCTAssertTrue(fileManager.fileExists(atPath: markerURL(for: normalizedExternalURL).path))
    }

    func testMigrateRejectsGroupContainerRootDirectory() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localGroupContainerURL = workspace.homeURL
            .appendingPathComponent("Library/Group Containers/5A4RE8SF68.com.tencent.xinWeChat")
        let externalBaseURL = workspace.externalRootURL
            .appendingPathComponent("Group Containers")
        let externalGroupContainerURL = externalBaseURL.appendingPathComponent(localGroupContainerURL.lastPathComponent)

        try createDirectoryWithPayload(at: localGroupContainerURL, payload: "group-state")

        let item = DataDirItem(
            name: "GroupContainer",
            path: localGroupContainerURL,
            type: .groupContainers,
            priority: .recommended,
            description: "Protected group container root",
            isMigratable: true
        )

        do {
            try await DataDirMover(homeDir: workspace.homeURL).migrate(item: item, to: externalBaseURL, progressHandler: nil)
            XCTFail("Expected group container root migration to be rejected")
        } catch let error as DataDirError {
            guard case .protectedPath = error else {
                return XCTFail("Expected protectedPath, got \(error)")
            }
        }

        try assertRealDirectory(localGroupContainerURL)
        XCTAssertEqual(try String(contentsOf: localGroupContainerURL.appendingPathComponent("payload.txt")), "group-state")
        XCTAssertFalse(fileManager.fileExists(atPath: externalGroupContainerURL.path))
    }

    func testCreateLinkRejectsGroupContainerRootDirectory() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localGroupContainerURL = workspace.homeURL
            .appendingPathComponent("Library/Group Containers/5A4RE8SF68.com.tencent.xinWeChat")
        let externalGroupContainerURL = workspace.externalRootURL
            .appendingPathComponent("Group Containers/5A4RE8SF68.com.tencent.xinWeChat")

        try createDirectoryWithPayload(at: externalGroupContainerURL, payload: "group-state")

        do {
            try await DataDirMover(homeDir: workspace.homeURL).createLink(
                localPath: localGroupContainerURL,
                externalPath: externalGroupContainerURL
            )
            XCTFail("Expected group container root link creation to be rejected")
        } catch let error as DataDirError {
            guard case .protectedPath = error else {
                return XCTFail("Expected protectedPath, got \(error)")
            }
        }

        XCTAssertFalse(fileManager.fileExists(atPath: localGroupContainerURL.path))
        XCTAssertEqual(try String(contentsOf: externalGroupContainerURL.appendingPathComponent("payload.txt")), "group-state")
    }

    private func makeWorkspace() throws -> (rootURL: URL, homeURL: URL, externalRootURL: URL) {
        let rootURL = fileManager.temporaryDirectory.appendingPathComponent("DataDirMoverTests-\(UUID().uuidString)")
        let homeURL = rootURL.appendingPathComponent("Home")
        let externalRootURL = rootURL.appendingPathComponent("External")

        try fileManager.createDirectory(at: homeURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: externalRootURL, withIntermediateDirectories: true)

        return (rootURL, homeURL, externalRootURL)
    }

    private func cleanupWorkspace(_ rootURL: URL) {
        try? fileManager.removeItem(at: rootURL)
    }

    private func createDirectoryWithPayload(at directoryURL: URL, payload: String) throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try payload.write(
            to: directoryURL.appendingPathComponent("payload.txt"),
            atomically: true,
            encoding: .utf8
        )
    }

    private func assertSymlink(
        _ localURL: URL,
        pointsTo destinationURL: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let destination = try fileManager.destinationOfSymbolicLink(atPath: localURL.path)
        let resolvedDestination = URL(
            fileURLWithPath: destination,
            relativeTo: localURL.deletingLastPathComponent()
        ).standardizedFileURL

        XCTAssertEqual(
            resolvedDestination,
            destinationURL.standardizedFileURL,
            file: file,
            line: line
        )
    }

    private func assertRealDirectory(
        _ directoryURL: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let values = try directoryURL.resourceValues(forKeys: [.isDirectoryKey])
        XCTAssertEqual(values.isDirectory, true, file: file, line: line)
        XCTAssertThrowsError(
            try fileManager.destinationOfSymbolicLink(atPath: directoryURL.path),
            file: file,
            line: line
        )
    }

    private func markerURL(for directoryURL: URL) -> URL {
        directoryURL.appendingPathComponent(".appports-link-metadata.plist")
    }

    // MARK: - 微信容器迁移策略测试

    func testWeChatApplicationSupportComTencentMigrationAllowed() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let weChatDataURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat")
        let externalBaseURL = workspace.externalRootURL
            .appendingPathComponent("WeChatAppSupport")
        let externalDataURL = externalBaseURL.appendingPathComponent(weChatDataURL.lastPathComponent)

        try createDirectoryWithPayload(at: weChatDataURL, payload: "wechat-core")

        let item = DataDirItem(
            name: "com.tencent.xinWeChat",
            path: weChatDataURL,
            type: .containers,
            priority: .critical,
            description: "微信核心数据",
            isMigratable: true
        )

        try await DataDirMover(homeDir: workspace.homeURL).migrate(
            item: item,
            to: externalBaseURL,
            progressHandler: nil
        )

        try assertSymlink(weChatDataURL, pointsTo: externalDataURL)
        XCTAssertTrue(fileManager.fileExists(atPath: markerURL(for: externalDataURL).path))
        XCTAssertEqual(try String(contentsOf: externalDataURL.appendingPathComponent("payload.txt")), "wechat-core")
    }

    func testWeChatXwechatFilesSubdirectoryMigrationAllowed() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let msgURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/msg")
        let externalBaseURL = workspace.externalRootURL
            .appendingPathComponent("WeChatXwechatFiles")
        let externalMsgURL = externalBaseURL.appendingPathComponent("msg")

        try createDirectoryWithPayload(at: msgURL, payload: "chat-messages")

        let item = DataDirItem(
            name: "msg",
            path: msgURL,
            type: .containers,
            priority: .critical,
            description: "微信消息目录",
            isMigratable: true
        )

        try await DataDirMover(homeDir: workspace.homeURL).migrate(
            item: item,
            to: externalBaseURL,
            progressHandler: nil
        )

        try assertSymlink(msgURL, pointsTo: externalMsgURL)
        XCTAssertTrue(fileManager.fileExists(atPath: markerURL(for: externalMsgURL).path))
        XCTAssertEqual(try String(contentsOf: externalMsgURL.appendingPathComponent("payload.txt")), "chat-messages")
    }

    func testNonWeChatContainerStillUsesUniversalStrategy() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let otherDataURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.example.focus/Data/SomeDataDir")
        let externalBaseURL = workspace.externalRootURL
            .appendingPathComponent("FocusData")
        let externalDataURL = externalBaseURL.appendingPathComponent("SomeDataDir")

        try createDirectoryWithPayload(at: otherDataURL, payload: "focus-stuff")

        let item = DataDirItem(
            name: "SomeDataDir",
            path: otherDataURL,
            type: .containers,
            priority: .critical,
            description: "普通应用数据",
            isMigratable: true
        )

        // 非微信容器不受微信策略影响
        try await DataDirMover(homeDir: workspace.homeURL).migrate(
            item: item,
            to: externalBaseURL,
            progressHandler: nil
        )

        try assertSymlink(otherDataURL, pointsTo: externalDataURL)
        XCTAssertEqual(try String(contentsOf: externalDataURL.appendingPathComponent("payload.txt")), "focus-stuff")
    }
}
