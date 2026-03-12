import XCTest
@testable import AppPorts

final class AppLoggerTests: XCTestCase {
    private let fileManager = FileManager.default
    private let logPathKey = "LogFilePath"
    private var originalLogPath: String?
    private var tempRootURL: URL?

    override func setUpWithError() throws {
        try super.setUpWithError()
        originalLogPath = UserDefaults.standard.string(forKey: logPathKey)
        tempRootURL = fileManager.temporaryDirectory.appendingPathComponent("AppLoggerTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: XCTUnwrap(tempRootURL), withIntermediateDirectories: true)
        AppLogger.shared.resetDiagnosticStateForTesting()
    }

    override func tearDownWithError() throws {
        AppLogger.shared.resetDiagnosticStateForTesting()

        if let originalLogPath {
            AppLogger.shared.setLogPath(URL(fileURLWithPath: originalLogPath))
        } else {
            UserDefaults.standard.removeObject(forKey: logPathKey)
        }

        if let tempRootURL {
            try? fileManager.removeItem(at: tempRootURL)
        }

        try super.tearDownWithError()
    }

    func testRedactedDiagnosticTextMasksUserAndVolumePaths() {
        let raw = """
        home=/Users/alice/Library/Application Support/AppPorts
        volume=/Volumes/CaseSSD/Apps/Foo.app
        """

        let redacted = AppLogger.shared.redactedDiagnosticText(from: raw)

        XCTAssertFalse(redacted.contains("/Users/alice"))
        XCTAssertTrue(redacted.contains("/Users/<redacted-user>/Library/Application Support/AppPorts"))
        XCTAssertFalse(redacted.contains("/Volumes/CaseSSD"))
        XCTAssertTrue(redacted.contains("/Volumes/<redacted-volume>/Apps/Foo.app"))
    }

    func testBuildDiagnosticPackageIncludesRedactedLogAndFailureSummary() throws {
        let tempRootURL = try XCTUnwrap(tempRootURL)
        let logURL = tempRootURL.appendingPathComponent("AppPorts_Log.txt")
        try """
        [2026-03-12 20:00:00] [ERROR] [session:TEST1234] [pid:1] source=/Users/alice/Library/Containers/com.example
        [2026-03-12 20:00:00] [ERROR] [session:TEST1234] [pid:1] volume=/Volumes/CaseSSD/AppPorts/Foo.app
        """.write(to: logURL, atomically: true, encoding: .utf8)
        AppLogger.shared.setLogPath(logURL)

        AppLogger.shared.logOperationSummary(
            category: "app_move",
            operationID: "app-move-1234",
            result: "failed",
            startedAt: Date().addingTimeInterval(-1),
            errorCode: "APP-MOVE-PORTAL-CREATE-FAILED",
            details: [("app_name", "Foo.app")]
        )

        let exportRootURL = tempRootURL.appendingPathComponent("ExportRoot", isDirectory: true)
        try fileManager.createDirectory(at: exportRootURL, withIntermediateDirectories: true)

        let packageURL = try AppLogger.shared.buildDiagnosticPackage(in: exportRootURL)

        let redactedLog = try String(
            contentsOf: packageURL.appendingPathComponent("AppPorts_Log.share-safe.txt"),
            encoding: .utf8
        )
        XCTAssertFalse(redactedLog.contains("/Users/alice"))
        XCTAssertFalse(redactedLog.contains("/Volumes/CaseSSD"))

        let summaryText = try String(
            contentsOf: packageURL.appendingPathComponent("diagnostic-summary.txt"),
            encoding: .utf8
        )
        XCTAssertTrue(summaryText.contains("app-move-1234"))
        XCTAssertTrue(summaryText.contains("APP-MOVE-PORTAL-CREATE-FAILED"))

        let failuresData = try Data(contentsOf: packageURL.appendingPathComponent("recent-failures.json"))
        let failures = try JSONDecoder().decode([AppLogger.OperationSummaryRecord].self, from: failuresData)
        XCTAssertEqual(failures.last?.operationID, "app-move-1234")
        XCTAssertEqual(failures.last?.errorCode, "APP-MOVE-PORTAL-CREATE-FAILED")
    }
}
