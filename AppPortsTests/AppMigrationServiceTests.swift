import XCTest
@testable import AppPorts

final class AppMigrationServiceTests: XCTestCase {
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

    func testRegularAppRoundTripMoveDeleteRelinkAndRestore() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localAppURL = workspace.localAppsURL.appendingPathComponent("Foo.app")
        let externalAppURL = workspace.externalRootURL.appendingPathComponent("Foo.app")
        try createAppBundle(at: localAppURL)

        let service = AppMigrationService()
        let localItem = AppItem(name: "Foo.app", path: localAppURL, status: "本地")

        try await service.moveAndLink(
            appToMove: localItem,
            destinationURL: externalAppURL,
            isRunning: false,
            progressHandler: nil
        )

        try assertStubPortal(localAppURL, pointsTo: externalAppURL)

        try service.deleteLink(app: AppItem(name: "Foo.app", path: localAppURL, status: "已链接"))
        XCTAssertFalse(fileManager.fileExists(atPath: localAppURL.path))

        try service.linkApp(
            appToLink: AppItem(name: "Foo.app", path: externalAppURL, status: "未链接"),
            destinationURL: localAppURL
        )

        try assertStubPortal(localAppURL, pointsTo: externalAppURL)

        try await service.moveBack(
            app: AppItem(name: "Foo.app", path: externalAppURL, status: "已链接"),
            localDestinationURL: localAppURL,
            progressHandler: nil
        )

        try assertRealAppBundle(localAppURL)
        XCTAssertFalse(fileManager.fileExists(atPath: externalAppURL.path))
    }

    func testMoveAndLinkRollsBackWhenPortalCreationFails() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localAppURL = workspace.localAppsURL.appendingPathComponent("Rollback.app")
        let externalAppURL = workspace.externalRootURL.appendingPathComponent("Rollback.app")
        try createAppBundle(at: localAppURL)

        let service = AppMigrationService(portalCreationOverride: { _, _ in
            throw NSError(domain: "AppPortsTests", code: 99, userInfo: [NSLocalizedDescriptionKey: "forced failure"])
        })

        do {
            try await service.moveAndLink(
                appToMove: AppItem(name: "Rollback.app", path: localAppURL, status: "本地"),
                destinationURL: externalAppURL,
                isRunning: false,
                progressHandler: nil
            )
            XCTFail("Expected portal creation failure")
        } catch {
            XCTAssertFalse(fileManager.fileExists(atPath: externalAppURL.path))
            try assertRealAppBundle(localAppURL)
        }
    }

    func testFolderMoveAndRestoreUsesSingleFolderSymlink() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localSuiteURL = workspace.localAppsURL.appendingPathComponent("Office")
        let externalSuiteURL = workspace.externalRootURL.appendingPathComponent("Office")
        try fileManager.createDirectory(at: localSuiteURL, withIntermediateDirectories: true)
        try createAppBundle(at: localSuiteURL.appendingPathComponent("Word.app"))
        try createAppBundle(at: localSuiteURL.appendingPathComponent("Excel.app"))

        let service = AppMigrationService()
        let suiteItem = AppItem(
            name: "Office",
            path: localSuiteURL,
            status: "本地",
            isFolder: true,
            appCount: 2
        )

        try await service.moveAndLink(
            appToMove: suiteItem,
            destinationURL: externalSuiteURL,
            isRunning: false,
            progressHandler: nil
        )

        try assertWholeAppSymlink(localSuiteURL, pointsTo: externalSuiteURL)
        XCTAssertFalse(fileManager.fileExists(atPath: workspace.localAppsURL.appendingPathComponent("Word.app").path))
        XCTAssertFalse(fileManager.fileExists(atPath: workspace.localAppsURL.appendingPathComponent("Excel.app").path))

        try await service.moveBack(
            app: AppItem(
                name: "Office",
                path: externalSuiteURL,
                status: "已链接",
                isFolder: true,
                appCount: 2
            ),
            localDestinationURL: localSuiteURL,
            progressHandler: nil
        )

        XCTAssertFalse(fileManager.fileExists(atPath: workspace.localAppsURL.appendingPathComponent("Word.app").path))
        XCTAssertFalse(fileManager.fileExists(atPath: workspace.localAppsURL.appendingPathComponent("Excel.app").path))
        try assertRealAppBundle(localSuiteURL.appendingPathComponent("Word.app"))
        try assertRealAppBundle(localSuiteURL.appendingPathComponent("Excel.app"))
        XCTAssertFalse(fileManager.fileExists(atPath: externalSuiteURL.path))
    }

    func testIOSRelinkUsesStubPortal() throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let externalAppURL = workspace.externalRootURL.appendingPathComponent("Phone.app")
        let localAppURL = workspace.localAppsURL.appendingPathComponent("Phone.app")
        try createAppBundle(at: externalAppURL, wrappedBundle: true)

        try AppMigrationService().linkApp(
            appToLink: AppItem(name: "Phone.app", path: externalAppURL, status: "未链接"),
            destinationURL: localAppURL
        )

        try assertStubPortal(localAppURL, pointsTo: externalAppURL)
    }

    func testDeleteLinkRejectsRealLocalAppBundle() throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let localAppURL = workspace.localAppsURL.appendingPathComponent("Safe.app")
        try createAppBundle(at: localAppURL)

        XCTAssertThrowsError(
            try AppMigrationService().deleteLink(
                app: AppItem(name: "Safe.app", path: localAppURL, status: "已链接")
            )
        )
        try assertRealAppBundle(localAppURL)
    }

    func testExternalSuiteStatusPrefersFolderLevelSymlink() async throws {
        let workspace = try makeWorkspace()
        defer { cleanupWorkspace(workspace.rootURL) }

        let externalSuiteURL = workspace.externalRootURL.appendingPathComponent("Office")
        try fileManager.createDirectory(at: externalSuiteURL, withIntermediateDirectories: true)
        try createAppBundle(at: externalSuiteURL.appendingPathComponent("Word.app"))
        try createAppBundle(at: externalSuiteURL.appendingPathComponent("Excel.app"))

        try AppMigrationService().linkApp(
            appToLink: AppItem(
                name: "Office",
                path: externalSuiteURL,
                status: "未链接",
                isFolder: true,
                appCount: 2
            ),
            destinationURL: workspace.localAppsURL.appendingPathComponent("Office")
        )

        let scanner = AppScanner()
        let scannedItems = await scanner.scanExternalApps(at: workspace.externalRootURL, localAppsDir: workspace.localAppsURL)
        let officeItem = try XCTUnwrap(scannedItems.first(where: { $0.name == "Office" }))
        XCTAssertEqual(officeItem.status, "已链接")
    }

    private func makeWorkspace() throws -> (rootURL: URL, localAppsURL: URL, externalRootURL: URL) {
        let rootURL = fileManager.temporaryDirectory.appendingPathComponent("AppPortsTests-\(UUID().uuidString)")
        let localAppsURL = rootURL.appendingPathComponent("Applications")
        let externalRootURL = rootURL.appendingPathComponent("External")

        try fileManager.createDirectory(at: localAppsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: externalRootURL, withIntermediateDirectories: true)

        return (rootURL, localAppsURL, externalRootURL)
    }

    private func cleanupWorkspace(_ rootURL: URL) {
        try? fileManager.removeItem(at: rootURL)
    }

    private func createAppBundle(
        at appURL: URL,
        wrappedBundle: Bool = false
    ) throws {
        let macOSURL = appURL.appendingPathComponent("Contents/MacOS")
        let resourcesURL = appURL.appendingPathComponent("Contents/Resources")
        try fileManager.createDirectory(at: macOSURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

        let executableURL = macOSURL.appendingPathComponent(appURL.deletingPathExtension().lastPathComponent)
        try "echo test".write(to: executableURL, atomically: true, encoding: .utf8)
        try "resource".write(to: resourcesURL.appendingPathComponent("payload.txt"), atomically: true, encoding: .utf8)

        if wrappedBundle {
            try fileManager.createDirectory(at: appURL.appendingPathComponent("WrappedBundle"), withIntermediateDirectories: true)
        }
    }

    private func assertDeepPortal(_ localURL: URL, pointsTo externalURL: URL, file: StaticString = #filePath, line: UInt = #line) throws {
        let localValues = try localURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        XCTAssertEqual(localValues.isDirectory, true, file: file, line: line)
        XCTAssertNotEqual(localValues.isSymbolicLink, true, file: file, line: line)

        let localContentsURL = localURL.appendingPathComponent("Contents")
        let contentsValues = try localContentsURL.resourceValues(forKeys: [.isSymbolicLinkKey])
        XCTAssertEqual(contentsValues.isSymbolicLink, true, file: file, line: line)

        let destination = try fileManager.destinationOfSymbolicLink(atPath: localContentsURL.path)
        let resolvedDestination = URL(fileURLWithPath: destination, relativeTo: localContentsURL.deletingLastPathComponent()).standardizedFileURL
        XCTAssertEqual(
            resolvedDestination,
            externalURL.appendingPathComponent("Contents").standardizedFileURL,
            file: file,
            line: line
        )
    }

    private func assertStubPortal(_ localURL: URL, pointsTo externalURL: URL, file: StaticString = #filePath, line: UInt = #line) throws {
        let localValues = try localURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        XCTAssertEqual(localValues.isDirectory, true, "stub portal should be a directory", file: file, line: line)
        XCTAssertNotEqual(localValues.isSymbolicLink, true, "stub portal should not be a symlink", file: file, line: line)

        let launcherURL = localURL.appendingPathComponent("Contents/MacOS/launcher")
        XCTAssertTrue(fileManager.fileExists(atPath: launcherURL.path), "launcher script should exist", file: file, line: line)

        let script = try String(contentsOf: launcherURL, encoding: .utf8)
        XCTAssertTrue(script.contains(externalURL.path), "launcher should reference external app", file: file, line: line)
    }

    private func assertWholeAppSymlink(_ localURL: URL, pointsTo externalURL: URL, file: StaticString = #filePath, line: UInt = #line) throws {
        let localValues = try localURL.resourceValues(forKeys: [.isSymbolicLinkKey])
        XCTAssertEqual(localValues.isSymbolicLink, true, file: file, line: line)

        let destination = try fileManager.destinationOfSymbolicLink(atPath: localURL.path)
        let resolvedDestination = URL(fileURLWithPath: destination, relativeTo: localURL.deletingLastPathComponent()).standardizedFileURL
        XCTAssertEqual(resolvedDestination, externalURL.standardizedFileURL, file: file, line: line)
    }

    private func assertRealAppBundle(_ appURL: URL, file: StaticString = #filePath, line: UInt = #line) throws {
        let appValues = try appURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        XCTAssertEqual(appValues.isDirectory, true, file: file, line: line)
        XCTAssertNotEqual(appValues.isSymbolicLink, true, file: file, line: line)

        let contentsURL = appURL.appendingPathComponent("Contents")
        let contentsValues = try contentsURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        XCTAssertEqual(contentsValues.isDirectory, true, file: file, line: line)
        XCTAssertNotEqual(contentsValues.isSymbolicLink, true, file: file, line: line)
    }
}
