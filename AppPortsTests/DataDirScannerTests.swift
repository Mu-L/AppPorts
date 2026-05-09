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
}
