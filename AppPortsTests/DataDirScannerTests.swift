import XCTest
@testable import AppPorts

final class DataDirScannerTests: XCTestCase {
    private let fileManager = FileManager.default
    private var originalLogEnabledValue: Any?
    private var originalLogPath: String?

    override func setUpWithError() throws {
        try super.setUpWithError()
        originalLogEnabledValue = UserDefaults.standard.object(forKey: "LogEnabled")
        originalLogPath = UserDefaults.standard.string(forKey: "LogFilePath")
        UserDefaults.standard.set(false, forKey: "LogEnabled")
    }

    override func tearDownWithError() throws {
        if let originalLogEnabledValue {
            UserDefaults.standard.set(originalLogEnabledValue, forKey: "LogEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "LogEnabled")
        }

        if let originalLogPath {
            UserDefaults.standard.set(originalLogPath, forKey: "LogFilePath")
        } else {
            UserDefaults.standard.removeObject(forKey: "LogFilePath")
        }

        try super.tearDownWithError()
    }

    func testManagedLinkAtNormalizedDestinationIsReportedAsLinked() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "Focus.app", bundleID: "com.example.focus", in: workspace.appsURL)
        let localDataURL = workspace.homeURL
            .appendingPathComponent("Library/Application Support/com.example.focus")
        let externalRootURL = workspace.externalRootURL
        let externalDataURL = externalRootURL
            .appendingPathComponent("Application Support/com.example.focus")

        try createDirectoryWithPayload(at: externalDataURL)
        try await DataDirMover(homeDir: workspace.homeURL).createLink(
            localPath: localDataURL,
            externalPath: externalDataURL
        )

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "Focus.app", path: appURL, status: "本地"),
            externalRootURL: externalRootURL
        )

        let item = try XCTUnwrap(items.first(where: { $0.path.standardizedFileURL == localDataURL.standardizedFileURL }))
        XCTAssertEqual(item.status, "已链接")
        XCTAssertEqual(item.linkedDestination?.standardizedFileURL, externalDataURL.standardizedFileURL)
    }

    func testManagedLinkOutsideNormalizedRootIsReportedAsNeedsNormalization() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "Focus.app", bundleID: "com.example.focus", in: workspace.appsURL)
        let localDataURL = workspace.homeURL
            .appendingPathComponent("Library/Application Support/com.example.focus")
        let currentExternalURL = workspace.rootURL
            .appendingPathComponent("ManualStore/com.example.focus")
        let externalRootURL = workspace.externalRootURL

        try createDirectoryWithPayload(at: currentExternalURL)
        try await DataDirMover(homeDir: workspace.homeURL).createLink(
            localPath: localDataURL,
            externalPath: currentExternalURL
        )

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "Focus.app", path: appURL, status: "本地"),
            externalRootURL: externalRootURL
        )

        let item = try XCTUnwrap(items.first(where: { $0.path.standardizedFileURL == localDataURL.standardizedFileURL }))
        XCTAssertEqual(item.status, "待规范")
        XCTAssertEqual(item.linkedDestination?.standardizedFileURL, currentExternalURL.standardizedFileURL)
    }

    func testUnmanagedSymlinkIsReportedAsExistingLink() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "Focus.app", bundleID: "com.example.focus", in: workspace.appsURL)
        let localDataURL = workspace.homeURL
            .appendingPathComponent("Library/Application Support/com.example.focus")
        let externalDataURL = workspace.rootURL
            .appendingPathComponent("ManualStore/com.example.focus")

        try createDirectoryWithPayload(at: externalDataURL)
        try fileManager.createDirectory(at: localDataURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.createSymbolicLink(at: localDataURL, withDestinationURL: externalDataURL)

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "Focus.app", path: appURL, status: "本地")
        )

        let item = try XCTUnwrap(items.first(where: { $0.path.standardizedFileURL == localDataURL.standardizedFileURL }))
        XCTAssertEqual(item.status, "现有软链")
        XCTAssertEqual(item.linkedDestination?.standardizedFileURL, externalDataURL.standardizedFileURL)
    }

    func testHistoricalLogMatchDoesNotUpgradeUnmanagedSymlinkToManagedLink() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "Focus.app", bundleID: "com.example.focus", in: workspace.appsURL)
        let localDataURL = workspace.homeURL
            .appendingPathComponent("Library/Application Support/com.example.focus")
        let externalDataURL = workspace.externalRootURL
            .appendingPathComponent("Application Support/com.example.focus")
        let logURL = workspace.rootURL.appendingPathComponent("AppPorts_Log.txt")

        try createDirectoryWithPayload(at: externalDataURL)
        try fileManager.createDirectory(at: localDataURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.createSymbolicLink(at: localDataURL, withDestinationURL: externalDataURL)
        try "步骤3: 符号链接创建成功: \(localDataURL.path) -> \(externalDataURL.path)\n".write(
            to: logURL,
            atomically: true,
            encoding: .utf8
        )
        UserDefaults.standard.set(logURL.path, forKey: "LogFilePath")

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "Focus.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        let item = try XCTUnwrap(items.first(where: { $0.path.standardizedFileURL == localDataURL.standardizedFileURL }))
        XCTAssertEqual(item.status, "现有软链")
        XCTAssertEqual(item.linkedDestination?.standardizedFileURL, externalDataURL.standardizedFileURL)
    }

    func testMirroredExternalDirectoryWithoutLocalPathIsReportedAsPendingRelink() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "Focus.app", bundleID: "com.example.focus", in: workspace.appsURL)
        let localDataURL = workspace.homeURL
            .appendingPathComponent("Library/Application Support/com.example.focus")
        let externalRootURL = workspace.externalRootURL
        let externalDataURL = externalRootURL
            .appendingPathComponent("Library/Application Support/com.example.focus")

        try createDirectoryWithPayload(at: externalDataURL)

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "Focus.app", path: appURL, status: "本地"),
            externalRootURL: externalRootURL
        )

        let item = try XCTUnwrap(items.first(where: { $0.path.standardizedFileURL == localDataURL.standardizedFileURL }))
        XCTAssertEqual(item.status, "待接回")
        XCTAssertEqual(item.linkedDestination?.standardizedFileURL, externalDataURL.standardizedFileURL)
    }

    func testLocalGroupContainerRootIsNotOfferedAsMigratableData() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let localGroupContainerURL = workspace.homeURL
            .appendingPathComponent("Library/Group Containers/5A4RE8SF68.com.tencent.xinWeChat")

        try createDirectoryWithPayload(at: localGroupContainerURL)

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        XCTAssertNil(items.first(where: { $0.path.standardizedFileURL == localGroupContainerURL.standardizedFileURL }))
    }

    func testManagedGroupContainerRootLinkIsReportedButNotMigratable() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let localGroupContainerURL = workspace.homeURL
            .appendingPathComponent("Library/Group Containers/5A4RE8SF68.com.tencent.xinWeChat")
        let externalGroupContainerURL = workspace.externalRootURL
            .appendingPathComponent("Group Containers/5A4RE8SF68.com.tencent.xinWeChat")

        try createDirectoryWithPayload(at: externalGroupContainerURL)
        try writeManagedLinkMetadata(
            sourcePath: localGroupContainerURL,
            destinationPath: externalGroupContainerURL,
            dataDirType: DataDirType.groupContainers.rawValue
        )
        try fileManager.createDirectory(
            at: localGroupContainerURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fileManager.createSymbolicLink(at: localGroupContainerURL, withDestinationURL: externalGroupContainerURL)

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        let item = try XCTUnwrap(items.first(where: { $0.path.standardizedFileURL == localGroupContainerURL.standardizedFileURL }))
        XCTAssertEqual(item.status, "已链接")
        XCTAssertEqual(item.linkedDestination?.standardizedFileURL, externalGroupContainerURL.standardizedFileURL)
        XCTAssertFalse(item.isMigratable)
        XCTAssertNotNil(item.nonMigratableReason)
    }

    private func makeWorkspace() throws -> (rootURL: URL, homeURL: URL, appsURL: URL, externalRootURL: URL) {
        let rootURL = fileManager.temporaryDirectory.appendingPathComponent("DataDirScannerTests-\(UUID().uuidString)")
        let homeURL = rootURL.appendingPathComponent("Home")
        let appsURL = rootURL.appendingPathComponent("Applications")
        let externalRootURL = rootURL.appendingPathComponent("External")

        try fileManager.createDirectory(at: homeURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: appsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: externalRootURL, withIntermediateDirectories: true)

        return (rootURL, homeURL, appsURL, externalRootURL)
    }

    private func cleanupWorkspace(_ rootURL: URL) {
        try? fileManager.removeItem(at: rootURL)
    }

    private func createAppBundle(named name: String, bundleID: String, in appsURL: URL) throws -> URL {
        let appURL = appsURL.appendingPathComponent(name)
        let contentsURL = appURL.appendingPathComponent("Contents")
        let macOSURL = contentsURL.appendingPathComponent("MacOS")
        try fileManager.createDirectory(at: macOSURL, withIntermediateDirectories: true)

        let executableURL = macOSURL.appendingPathComponent(name.replacingOccurrences(of: ".app", with: ""))
        try "echo test".write(to: executableURL, atomically: true, encoding: .utf8)

        let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
        let plist: [String: Any] = [
            "CFBundleIdentifier": bundleID,
            "CFBundleName": name.replacingOccurrences(of: ".app", with: "")
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try plistData.write(to: infoPlistURL)

        return appURL
    }

    private func createDirectoryWithPayload(at directoryURL: URL) throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try "payload".write(
            to: directoryURL.appendingPathComponent("payload.txt"),
            atomically: true,
            encoding: .utf8
        )
    }

    private func writeManagedLinkMetadata(
        sourcePath: URL,
        destinationPath: URL,
        dataDirType: String
    ) throws {
        let metadata: [String: Any] = [
            "schemaVersion": 1,
            "managedBy": "com.shimoko.AppPorts",
            "sourcePath": sourcePath.standardizedFileURL.path,
            "destinationPath": destinationPath.standardizedFileURL.path,
            "dataDirType": dataDirType
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: metadata, format: .binary, options: 0)
        try data.write(
            to: destinationPath.appendingPathComponent(".appports-link-metadata.plist"),
            options: .atomic
        )
    }

    // MARK: - 微信容器扫描策略测试

    func testWeChatContainerOnlySurfacesDocumentsAndLibraryAtDataLevel() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let containerURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat")
        let dataURL = containerURL.appendingPathComponent("Data")

        try createDirectoryWithPayload(at: dataURL.appendingPathComponent("Documents"))
        try createDirectoryWithPayload(at: dataURL.appendingPathComponent("Library"))
        try createDirectoryWithPayload(at: dataURL.appendingPathComponent("SystemData"))

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        // 仅 Documents 和 Library 出现（作为不可迁移父节点）
        let dataLevelItems = items.filter { $0.path.deletingLastPathComponent().lastPathComponent == "Data" }
        let dataLevelNames = Set(dataLevelItems.map { $0.path.lastPathComponent })
        XCTAssertEqual(dataLevelNames, ["Documents", "Library"])
        for item in dataLevelItems {
            XCTAssertFalse(item.isMigratable)
        }
    }

    func testWeChatXwechatFilesSubdirectoriesAreIndividuallyMigratable() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let xwechatFilesURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files")

        try createDirectoryWithPayload(at: xwechatFilesURL.appendingPathComponent("msg"))
        try createDirectoryWithPayload(at: xwechatFilesURL.appendingPathComponent("file"))
        try createDirectoryWithPayload(at: xwechatFilesURL.appendingPathComponent("video"))

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        let xChildren = items.filter { $0.path.path.contains("xwechat_files/") }
        XCTAssertEqual(xChildren.count, 3)
        for child in xChildren {
            XCTAssertTrue(child.isMigratable)
            XCTAssertEqual(child.status, "本地")
        }
    }

    func testWeChatXwechatFilesItselfIsNotMigratable() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let xwechatFilesURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files")
        try createDirectoryWithPayload(at: xwechatFilesURL)

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        let xDir = try XCTUnwrap(items.first(where: { $0.path.standardizedFileURL == xwechatFilesURL.standardizedFileURL }))
        XCTAssertFalse(xDir.isMigratable)
        XCTAssertNotNil(xDir.nonMigratableReason)
    }

    func testWeChatApplicationSupportComTencentXinWeChatIsMigratable() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let weChatDataURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat")
        try createDirectoryWithPayload(at: weChatDataURL)

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        let weChatItem = try XCTUnwrap(items.first(where: { $0.path.standardizedFileURL == weChatDataURL.standardizedFileURL }))
        XCTAssertTrue(weChatItem.isMigratable)
        XCTAssertEqual(weChatItem.status, "本地")
    }

    func testWeChatOtherDocumentsChildrenAreNotSurfaced() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let documentsURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat/Data/Documents")
        try createDirectoryWithPayload(at: documentsURL.appendingPathComponent("OtherStuff"))
        try createDirectoryWithPayload(at: documentsURL.appendingPathComponent("RandomDir"))

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        for item in items {
            XCTAssertFalse(item.path.path.contains("OtherStuff"))
            XCTAssertFalse(item.path.path.contains("RandomDir"))
        }
    }

    func testWeChatOtherLibraryChildrenAreNotSurfaced() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let libraryURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat/Data/Library")
        try createDirectoryWithPayload(at: libraryURL.appendingPathComponent("Caches"))
        try createDirectoryWithPayload(at: libraryURL.appendingPathComponent("Preferences"))

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        for item in items {
            XCTAssertFalse(item.path.path.contains("Data/Library/Caches"))
            XCTAssertFalse(item.path.path.contains("Data/Library/Preferences"))
        }
    }

    func testWeChatOtherApplicationSupportChildrenAreNotSurfaced() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let appSupportURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support")
        try createDirectoryWithPayload(at: appSupportURL.appendingPathComponent("com.other.App"))
        try createDirectoryWithPayload(at: appSupportURL.appendingPathComponent("RandomSupport"))

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        for item in items {
            XCTAssertFalse(item.path.path.contains("com.other.App"))
            XCTAssertFalse(item.path.path.contains("RandomSupport"))
        }
    }

    func testWeChatNonDocumentsNonLibraryDataChildrenAreNotSurfaced() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let appURL = try createAppBundle(named: "WeChat.app", bundleID: "com.tencent.xinWeChat", in: workspace.appsURL)
        let dataURL = workspace.homeURL
            .appendingPathComponent("Library/Containers/com.tencent.xinWeChat/Data")
        try createDirectoryWithPayload(at: dataURL.appendingPathComponent("SystemData"))

        let items = await DataDirScanner(homeDir: workspace.homeURL).scanLibraryDirs(
            for: AppItem(name: "WeChat.app", path: appURL, status: "本地"),
            externalRootURL: workspace.externalRootURL
        )

        for item in items {
            XCTAssertFalse(item.path.path.contains("SystemData"))
        }
    }
}
