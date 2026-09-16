import Darwin
import Foundation
import Testing
@testable import AppPorts

@Suite("Code signing")
struct CodeSignerTests {
    enum PortalKind: CaseIterable {
        case native, legacyScript, wholeAppSymlink, contentsSymlink
    }

    @Test("Every supported portal resolves to the real application", arguments: PortalKind.allCases)
    func resolvesRealApplication(kind: PortalKind) throws {
        let workspace = try Workspace()
        defer { workspace.cleanup() }
        let realApp = workspace.root.appendingPathComponent("External/Chat's app.app")
        try makeBundle(at: realApp)
        let portal = workspace.root.appendingPathComponent("Chat.app")

        switch kind {
        case .native:
            try makeBundle(at: portal, identifier: "com.appports.tests.chat.appports.stub")
            try (realApp.path + "\n").write(
                to: portal.appendingPathComponent("Contents/Resources/real_app_path.txt"),
                atomically: true, encoding: .utf8
            )
        case .legacyScript:
            try makeBundle(at: portal, identifier: "com.appports.tests.chat.appports.stub")
            let quotedPath = realApp.path.replacingOccurrences(of: "'", with: "'\\''")
            try "#!/bin/bash\nREAL_APP='\(quotedPath)'\nopen \"$REAL_APP\"\n".write(
                to: portal.appendingPathComponent("Contents/MacOS/launcher"),
                atomically: true, encoding: .utf8
            )
        case .wholeAppSymlink:
            try FileManager.default.createSymbolicLink(atPath: portal.path, withDestinationPath: "External/Chat's app.app")
        case .contentsSymlink:
            try FileManager.default.createDirectory(at: portal, withIntermediateDirectories: true)
            try FileManager.default.createSymbolicLink(
                atPath: portal.appendingPathComponent("Contents").path,
                withDestinationPath: "../External/Chat's app.app/Contents"
            )
        }

        #expect(try CodeSigner.resolveAppURL(at: portal).path == realApp.path)
    }

    enum BrokenPortal: CaseIterable {
        case missingTarget, emptyPath, relativePath, missingMetadata, cycle, brokenMetadataLink
    }

    @Test("Broken portals fail before the stub or backups are modified", arguments: BrokenPortal.allCases)
    func refusesBrokenPortal(kind: BrokenPortal) async throws {
        let workspace = try Workspace()
        defer { workspace.cleanup() }
        let portal = workspace.root.appendingPathComponent("Chat.app")
        try makeBundle(at: portal, identifier: "com.appports.tests.chat.appports.stub")
        let pathFile = portal.appendingPathComponent("Contents/Resources/real_app_path.txt")
        switch kind {
        case .missingTarget:
            try workspace.root.appendingPathComponent("Missing.app").path.write(to: pathFile, atomically: true, encoding: .utf8)
        case .emptyPath:
            try "\n".write(to: pathFile, atomically: true, encoding: .utf8)
        case .relativePath:
            try "../Missing.app".write(to: pathFile, atomically: true, encoding: .utf8)
        case .missingMetadata:
            break
        case .cycle:
            try portal.path.write(to: pathFile, atomically: true, encoding: .utf8)
        case .brokenMetadataLink:
            try FileManager.default.createSymbolicLink(atPath: pathFile.path, withDestinationPath: "missing.txt")
        }
        let executable = portal.appendingPathComponent("Contents/MacOS/Fixture")
        let original = try Data(contentsOf: executable)
        let signer = CodeSigner(backupDirectoryURL: workspace.backups, allowAdministratorPrompt: false)

        do {
            try await signer.sign(appURL: portal, bundleIdentifier: nil)
            Issue.record("A broken portal must not be signed as a normal application")
        } catch CodeSigner.SigningError.applicationUnavailable {
            // Expected: fail before changing the local portal.
        }

        #expect(try Data(contentsOf: executable) == original)
        #expect(FileManager.default.fileExists(atPath: workspace.backups.path) == false)
    }

    @Test("A backup records the real application's identity and location")
    func backupUsesRealApplication() async throws {
        let workspace = try Workspace()
        defer { workspace.cleanup() }
        let realApp = workspace.root.appendingPathComponent("External/Chat.app")
        let identifier = "com.appports.tests.real-chat"
        try makeBundle(at: realApp, identifier: identifier)
        let portal = workspace.root.appendingPathComponent("Chat.app")
        let stubIdentifier = identifier + ".appports.stub"
        try makeBundle(at: portal, identifier: stubIdentifier)
        try realApp.path.write(to: portal.appendingPathComponent("Contents/Resources/real_app_path.txt"), atomically: true, encoding: .utf8)

        let signer = CodeSigner(backupDirectoryURL: workspace.backups, allowAdministratorPrompt: false)
        try await signer.backupOriginalSignature(appURL: portal, bundleIdentifier: stubIdentifier)

        let backupData = try Data(contentsOf: workspace.backups.appendingPathComponent(identifier + ".plist"))
        let backup = try #require(PropertyListSerialization.propertyList(from: backupData, format: nil) as? [String: Any])
        #expect(backup["bundleIdentifier"] as? String == identifier)
        #expect(backup["originalPath"] as? String == realApp.path)
        #expect(FileManager.default.fileExists(atPath: workspace.backups.appendingPathComponent(stubIdentifier + ".plist").path) == false)
    }

    @Test("Signing unlocks nested files even when the bundle root is not locked")
    func signingPreservesMixedFlags() async throws {
        let workspace = try Workspace()
        defer { workspace.cleanup() }
        let app = workspace.root.appendingPathComponent("Mixed Locks.app")
        try makeBundle(at: app)
        let helper = app.appendingPathComponent("Contents/Helpers/Helper.app")
        try makeBundle(at: helper, identifier: "com.appports.tests.helper")
        try codesign(["--force", "--deep", "--sign", "-", app.path])
        let main = app.appendingPathComponent("Contents/MacOS/Fixture")
        let helperExecutable = helper.appendingPathComponent("Contents/MacOS/Fixture")
        try setFlags(UInt32(UF_IMMUTABLE | UF_HIDDEN), at: main)
        try setFlags(UInt32(UF_IMMUTABLE), at: helperExecutable)
        try setFlags(UInt32(UF_IMMUTABLE), at: app.appendingPathComponent("Contents/Helpers"))
        let before = try allFlags(in: app)
        try #require(before[app.path] == 0)

        let signer = CodeSigner(backupDirectoryURL: workspace.backups, allowAdministratorPrompt: false)
        try await signer.sign(appURL: app, bundleIdentifier: nil)

        #expect(await signer.verify(appURL: app) == .valid)
        #expect(await signer.verify(appURL: helper) == .valid)
        #expect(try allFlags(in: app) == before)
    }

    @Test("Read-only code and resources can be signed without changing their permissions or unrelated metadata")
    func signingAllowsReadOnlyFiles() async throws {
        let workspace = try Workspace()
        defer { workspace.cleanup() }
        let app = workspace.root.appendingPathComponent("Read Only.app")
        try makeBundle(at: app)
        let main = app.appendingPathComponent("Contents/MacOS/Fixture")
        let info = app.appendingPathComponent("Contents/Info.plist")
        let resources = app.appendingPathComponent("Contents/Resources")
        let payload = resources.appendingPathComponent("payload.txt")
        let detritusFile = resources.appendingPathComponent("metadata.bin")
        try Data("read-only resource".utf8).write(to: payload)
        try Data("resource with a fork".utf8).write(to: detritusFile)
        let metadata = Data("preserve this attribute".utf8)
        let attribute = "com.appports.tests.metadata"
        try #require(metadata.withUnsafeBytes {
            setxattr(app.path, attribute, $0.baseAddress, $0.count, 0, 0)
        } == 0)
        let resourceFork = Data("unsealed resource fork".utf8)
        try #require(resourceFork.withUnsafeBytes {
            setxattr(detritusFile.path, "com.apple.ResourceFork", $0.baseAddress, $0.count, 0, 0)
        } == 0)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: main.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: info.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: payload.path)

        let signer = CodeSigner(backupDirectoryURL: workspace.backups, allowAdministratorPrompt: false)
        try await signer.sign(appURL: app, bundleIdentifier: nil)

        #expect(await signer.verify(appURL: app) == .valid)
        #expect((try FileManager.default.attributesOfItem(atPath: main.path))[.posixPermissions] as? Int == 0o555)
        #expect((try FileManager.default.attributesOfItem(atPath: info.path))[.posixPermissions] as? Int == 0o444)
        #expect((try FileManager.default.attributesOfItem(atPath: payload.path))[.posixPermissions] as? Int == 0o444)
        #expect(getxattr(app.path, attribute, nil, 0, 0, 0) == metadata.count)
        #expect(getxattr(detritusFile.path, "com.apple.ResourceFork", nil, 0, 0, 0) == -1)
        #expect(errno == ENOATTR)
    }

    @Test("Signing failure restores locks and leaves linked external data untouched")
    func failureRestoresLocksWithoutFollowingLinks() async throws {
        let workspace = try Workspace()
        defer { workspace.cleanup() }
        let app = workspace.root.appendingPathComponent("Invalid.app")
        try makeBundle(at: app)
        let main = app.appendingPathComponent("Contents/MacOS/Fixture")
        try Data("invalid Mach-O".utf8).write(to: main)
        let outside = workspace.root.appendingPathComponent("ExternalData")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        let payload = outside.appendingPathComponent("payload.txt")
        let originalData = Data("unchanged external data".utf8)
        try originalData.write(to: payload)
        let attribute = "com.appports.tests.external-data"
        try #require(originalData.withUnsafeBytes {
            setxattr(payload.path, attribute, $0.baseAddress, $0.count, 0, 0)
        } == 0)
        try setFlags(UInt32(UF_IMMUTABLE), at: outside)
        try setFlags(UInt32(UF_IMMUTABLE | UF_HIDDEN), at: payload)
        try FileManager.default.createSymbolicLink(at: app.appendingPathComponent("Contents/Resources/external-data"), withDestinationURL: outside)
        try setFlags(UInt32(UF_IMMUTABLE), at: app)
        try setFlags(UInt32(UF_IMMUTABLE), at: main)
        let before = try allFlags(in: app)
        let outsideBefore = try allFlags(in: outside)

        let signer = CodeSigner(backupDirectoryURL: workspace.backups, allowAdministratorPrompt: false)
        do {
            try await signer.sign(appURL: app, bundleIdentifier: nil)
            Issue.record("Malformed code must fail signing")
        } catch CodeSigner.SigningError.codesignFailed {
            // Expected: even an actual codesign failure must restore the original flags.
        }

        for (path, flags) in before {
            #expect(try fileFlags(at: URL(fileURLWithPath: path)) == flags)
        }
        #expect(try allFlags(in: outside) == outsideBefore)
        #expect(try Data(contentsOf: payload) == originalData)
        #expect(getxattr(payload.path, attribute, nil, 0, 0, 0) == originalData.count)
    }

    private struct Workspace {
        let root: URL
        var backups: URL { root.appendingPathComponent("SignatureBackups") }

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appendingPathComponent("AppPortsCodeSignerTests-\(UUID().uuidString)")
                .resolvingSymlinksInPath()
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        }

        func cleanup() {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/chflags")
            process.arguments = ["-R", "nouchg", root.path]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            if (try? process.run()) != nil { process.waitUntilExit() }
            try? FileManager.default.removeItem(at: root)
        }
    }

    private func makeBundle(at url: URL, identifier: String = "com.appports.tests.fixture") throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: url.appendingPathComponent("Contents/MacOS"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: url.appendingPathComponent("Contents/Resources"), withIntermediateDirectories: true)
        let binary = try #require(Bundle.main.url(forResource: "StubLauncherBinary", withExtension: nil))
        let executable = url.appendingPathComponent("Contents/MacOS/Fixture")
        try fileManager.copyItem(at: binary, to: executable)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        let info = ["CFBundleIdentifier": identifier, "CFBundleExecutable": "Fixture",
                    "CFBundlePackageType": "APPL", "CFBundleVersion": "1"]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: url.appendingPathComponent("Contents/Info.plist"))
    }

    private func setFlags(_ flags: UInt32, at url: URL) throws {
        try #require(lchflags(url.path, flags) == 0)
    }

    private func fileFlags(at url: URL) throws -> UInt32 {
        var info = stat()
        try #require(lstat(url.path, &info) == 0)
        return info.st_flags
    }

    private func allFlags(in root: URL) throws -> [String: UInt32] {
        var result = [root.path: try fileFlags(at: root)]
        let enumerator = try #require(FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil))
        for case let url as URL in enumerator {
            result[url.path] = try fileFlags(at: url)
        }
        return result
    }

    private func codesign(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        try #require(process.terminationStatus == 0, "\(String(decoding: output, as: UTF8.self))")
    }
}

@Suite("Data migration signing workflow")
struct DataMigrationWorkflowTests {
    private let appURL = URL(fileURLWithPath: "/test/Chat.app")

    @Test("Migration waits for backup, and completion waits for signing")
    func awaitsEveryStage() async throws {
        let events = Events()
        let backupStarted = Gate()
        let finishBackup = Gate()
        let signingStarted = Gate()
        let finishSigning = Gate()
        let operation = Task {
            try await DataMigrationWorkflow.run(
                signingAppURL: appURL,
                backupSignature: { _ in
                    await events.append("backup-started")
                    await backupStarted.open()
                    await finishBackup.wait()
                    await events.append("backup-finished")
                },
                migrate: { await events.append("migrate") },
                resignApp: { _ in
                    await events.append("signing-started")
                    await signingStarted.open()
                    await finishSigning.wait()
                    await events.append("signing-finished")
                }
            )
            await events.append("completed")
        }

        await backupStarted.wait()
        #expect(await events.values == ["backup-started"])
        await finishBackup.open()
        await signingStarted.wait()
        #expect(await events.values == ["backup-started", "backup-finished", "migrate", "signing-started"])
        await finishSigning.open()
        try await operation.value
        #expect(await events.values == ["backup-started", "backup-finished", "migrate", "signing-started", "signing-finished", "completed"])
    }

    enum Stage: CaseIterable { case backup, migration, signing }
    private enum TestFailure: Error { case expected }

    @Test("Failures propagate at the correct stage", arguments: Stage.allCases)
    func propagatesFailure(stage: Stage) async throws {
        let events = Events()
        do {
            try await DataMigrationWorkflow.run(
                signingAppURL: appURL,
                backupSignature: { _ in
                    await events.append("backup")
                    if stage == .backup { throw TestFailure.expected }
                },
                migrate: {
                    await events.append("migration")
                    if stage == .migration { throw TestFailure.expected }
                },
                resignApp: { _ in
                    await events.append("signing")
                    throw TestFailure.expected
                }
            )
            Issue.record("Failure must reach the caller")
        } catch DataMigrationWorkflow.Failure.signingFailed(let underlying) {
            #expect(stage == .signing)
            #expect(underlying is TestFailure)
        } catch TestFailure.expected {
            #expect(stage != .signing)
        }
        let expectedEvents: [String]
        switch stage {
        case .backup: expectedEvents = ["backup"]
        case .migration: expectedEvents = ["backup", "migration"]
        case .signing: expectedEvents = ["backup", "migration", "signing"]
        }
        #expect(await events.values == expectedEvents)
    }

    @Test("Declining signing runs only the data migration")
    func respectsSigningChoice() async throws {
        let events = Events()
        try await DataMigrationWorkflow.run(
            signingAppURL: nil,
            backupSignature: { _ in Issue.record("Backup must not run when signing is disabled") },
            migrate: { await events.append("migration") },
            resignApp: { _ in Issue.record("Signing must not run when disabled") }
        )
        #expect(await events.values == ["migration"])
    }

    private actor Events {
        private(set) var values: [String] = []
        func append(_ value: String) { values.append(value) }
    }

    private actor Gate {
        private var isOpen = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        func wait() async {
            guard !isOpen else { return }
            await withCheckedContinuation { waiters.append($0) }
        }

        func open() {
            isOpen = true
            for waiter in waiters { waiter.resume() }
            waiters.removeAll()
        }
    }
}
