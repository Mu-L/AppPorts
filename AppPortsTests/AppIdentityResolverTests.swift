import XCTest
@testable import AppPorts

final class AppIdentityResolverTests: XCTestCase {
    func testNativeAndRootPlistsSelectCorrectIdentity() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let native = try f.native("Native.app", id: "com.example.native")
        try f.plist(["CFBundleIdentifier": "com.example.other"], at: native.appendingPathComponent("Info.plist"))
        let nativeIdentity = try AppIdentityResolver.resolve(at: native).get()
        XCTAssertEqual(nativeIdentity.bundleIdentifier, "com.example.native")
        XCTAssertEqual(nativeIdentity.source, .macOSBundle)
        let root = try f.directory("Root.app")
        try f.plist(["CFBundleIdentifier": "com.example.ios"], at: root.appendingPathComponent("Info.plist"))
        let identity = try AppIdentityResolver.resolve(at: root).get()
        XCTAssertEqual(identity.bundleIdentifier, "com.example.ios")
        XCTAssertEqual(identity.source, .rootBundle)
    }

    func testWrappedBundleKeepsOuterApplicationSeparateFromIdentityBundle() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.ios("bh3.app")
        let identity = try AppIdentityResolver.resolve(at: outer).get()
        XCTAssertEqual(identity.realAppURL.path, outer.path)
        XCTAssertEqual(identity.identityBundleURL, outer.appendingPathComponent("Wrapper/bh3.app"))
        XCTAssertEqual(identity.bundleIdentifier, "com.miHoYo.bh3")
        XCTAssertEqual(identity.source, .wrappedBundle)
    }

    func testUniqueWrapperChildWithoutLinkIsSupported() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.ios("bh3.app", link: false)
        let identity = try AppIdentityResolver.resolve(at: outer).get()
        XCTAssertEqual(identity.bundleIdentifier, "com.miHoYo.bh3")
        XCTAssertEqual(identity.source, .wrapperChild)
    }

    func testWrappedBundleDirectoryWithoutSymlinkIsSupported() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.directory("bh3.app")
        try f.plist(["CFBundleIdentifier": "com.miHoYo.bh3"], at: outer.appendingPathComponent("WrappedBundle/Info.plist"))
        XCTAssertEqual(try AppIdentityResolver.resolve(at: outer).get().bundleIdentifier, "com.miHoYo.bh3")
    }

    func testExplicitWrappedBundleWinsOverOtherWrapperChildren() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.ios("bh3.app")
        _ = try f.native("bh3.app/Wrapper/Unrelated.app", id: "com.unrelated.other")
        XCTAssertEqual(try AppIdentityResolver.resolve(at: outer).get().bundleIdentifier, "com.miHoYo.bh3")
    }

    func testAmbiguousWrapperIsNotSelectedByDirectoryOrder() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.ios("bh3.app", link: false)
        _ = try f.native("bh3.app/Wrapper/Other.app", id: "com.other.app")
        assertIssue(outer, .ambiguousWrapper)
    }

    func testBrokenWrappedBundleDoesNotFallBackToAnotherChild() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.ios("bh3.app", link: false)
        try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("WrappedBundle").path, withDestinationPath: "missing.app")
        assertIssue(outer, .wrappedBundleUnavailable)
    }

    func testBrokenAppCandidateMakesWrapperAmbiguous() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.ios("bh3.app", link: false)
        try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("Wrapper/Missing.app").path, withDestinationPath: "absent.app")
        assertIssue(outer, .ambiguousWrapper)
    }

    func testNonAppAndRegularFilesDoNotCreateAmbiguity() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.ios("bh3.app", link: false)
        try Data().write(to: outer.appendingPathComponent("Wrapper/NotADirectory.app"))
        _ = try f.directory("bh3.app/Wrapper/Resources")
        XCTAssertEqual(try AppIdentityResolver.resolve(at: outer).get().bundleIdentifier, "com.miHoYo.bh3")
    }

    func testRelativeAndAbsoluteWholeAppLinksWorkForNativeAndIOS() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let native = try f.native("External/Native.app", id: "com.example.native")
        let ios = try f.ios("External/bh3.app")
        for (index, pair) in [(native, "com.example.native"), (ios, "com.miHoYo.bh3")].enumerated() {
            for absolute in [true, false] {
                let link = f.root.appendingPathComponent("Link\(index)-\(absolute).app")
                let target = absolute ? pair.0.path : "External/\(pair.0.lastPathComponent)"
                try f.fm.createSymbolicLink(atPath: link.path, withDestinationPath: target)
                let identity = try AppIdentityResolver.resolve(at: link).get()
                XCTAssertEqual(identity.bundleIdentifier, pair.1)
                XCTAssertEqual(identity.realAppURL.path, pair.0.path)
            }
        }
    }

    func testCurrentAndLegacyStubsResolveNativeAndIOSWithoutExecutingLaunchers() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let native = try f.native("External/Owner's Native.app", id: "com.example.native")
        let ios = try f.ios("External/Owner's bh3.app")
        for (index, pair) in [(native, "com.example.native"), (ios, "com.miHoYo.bh3")].enumerated() {
            for legacy in [true, false] {
                let portal = try f.stub("Stub\(index)-\(legacy).app", id: pair.1, target: pair.0, legacy: legacy)
                let identity = try AppIdentityResolver.resolve(at: portal).get()
                XCTAssertEqual(identity.bundleIdentifier, pair.1)
                XCTAssertEqual(identity.realAppURL.path, pair.0.path)
            }
        }
    }

    func testLegacyDeepContentsWrapperResolvesExternalBundle() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let real = try f.native("External/Native.app", id: "com.example.native")
        let portal = try f.directory("Portal.app")
        try f.fm.createSymbolicLink(atPath: portal.appendingPathComponent("Contents").path,
                                   withDestinationPath: "../External/Native.app/Contents")
        let identity = try AppIdentityResolver.resolve(at: portal).get()
        XCTAssertEqual(identity.realAppURL.path, real.path)
        XCTAssertEqual(identity.bundleIdentifier, "com.example.native")
    }

    func testUnavailableStubNeverUsesLauncherIdentifier() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let missing = f.root.appendingPathComponent("Missing.app")
        let portal = try f.stub("Portal.app", id: "com.example.real", target: missing)
        assertIssue(portal, .realAppUnavailable)
        assertIssue(missing, .realAppUnavailable)
    }

    func testPortalCycleReturnsFailure() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let first = f.root.appendingPathComponent("First.app")
        let second = f.root.appendingPathComponent("Second.app")
        _ = try f.stub("First.app", id: "com.example.first", target: second)
        _ = try f.stub("Second.app", id: "com.example.second", target: first)
        assertIssue(first, .realAppUnavailable)
    }

    func testWrapperSelfLinkAndAncestorCycleReturnFailure() throws {
        for target in ["WrappedBundle", "."] {
            let f = try IdentityFixture()
            defer { f.cleanup() }
            let outer = try f.directory("Cycle.app")
            try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("WrappedBundle").path, withDestinationPath: target)
            assertIssue(outer, .wrapperCycle)
        }
    }

    func testWrapperTwoLinkCycleReturnsFailure() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.directory("Cycle.app")
        try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("WrappedBundle").path, withDestinationPath: "Other")
        try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("Other").path, withDestinationPath: "WrappedBundle")
        assertIssue(outer, .wrapperCycle)
    }

    func testWrapperCannotEscapeIntoSiblingWithSamePathPrefix() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.directory("Game.app")
        let unrelated = try f.native("Game.app-other/Inner.app", id: "com.unrelated.app")
        try f.fm.createSymbolicLink(at: outer.appendingPathComponent("WrappedBundle"), withDestinationURL: unrelated)
        assertIssue(outer, .outsideWrapper)
    }

    func testWrapperDirectoryLinkCannotEscape() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.directory("Game.app")
        _ = try f.native("Other/Inner.app", id: "com.unrelated.app")
        try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("Wrapper").path, withDestinationPath: "../Other")
        assertIssue(outer, .outsideWrapper)
    }

    func testExcessiveNestingStopsButSupportedNestingResolves() throws {
        for depth in [8, 9] {
            let f = try IdentityFixture()
            defer { f.cleanup() }
            let outer = try f.directory("Nested.app")
            var inner = outer
            for _ in 0..<depth { inner.appendPathComponent("WrappedBundle") }
            try f.plist(["CFBundleIdentifier": "com.example.deep"], at: inner.appendingPathComponent("Info.plist"))
            if depth == 8 {
                XCTAssertEqual(try AppIdentityResolver.resolve(at: outer).get().bundleIdentifier, "com.example.deep")
            } else {
                assertIssue(outer, .wrapperDepthExceeded)
            }
        }
    }

    func testMalformedHigherPriorityPlistDoesNotChooseLowerIdentity() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.native("Invalid.app", id: "com.example.app")
        try Data("invalid plist".utf8).write(to: outer.appendingPathComponent("Contents/Info.plist"))
        try f.plist(["CFBundleIdentifier": "com.other.app"], at: outer.appendingPathComponent("Info.plist"))
        assertIssue(outer, .invalidInfoPlist)
    }

    func testInvalidIdentifiersAreNotUsedForMatching() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        for (index, value) in ["", " \n", "com.game.APPPORTS.STUB", 42].enumerated() {
            let outer = try f.directory("Invalid\(index).app")
            try f.plist(["CFBundleIdentifier": value], at: outer.appendingPathComponent("Info.plist"))
            assertIssue(outer, .invalidIdentifier)
        }
    }

    func testMissingIdentifierIsDifferentFromMissingPlist() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let empty = try f.directory("Empty.app")
        assertIssue(empty, .missingInfoPlist)
        try f.plist(["CFBundleName": "Empty"], at: empty.appendingPathComponent("Info.plist"))
        assertIssue(empty, .invalidIdentifier)
    }

    func testIdentifierSurroundingWhitespaceIsTrimmed() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let app = try f.native("Trim.app", id: "  com.example.trim\n")
        XCTAssertEqual(try AppIdentityResolver.resolve(at: app).get().bundleIdentifier, "com.example.trim")
    }

    func testUnreadablePlistDoesNotLookLikeMissingIdentity() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let app = try f.native("Locked.app", id: "com.example.locked")
        let plist = app.appendingPathComponent("Contents/Info.plist")
        try f.fm.setAttributes([.posixPermissions: 0], ofItemAtPath: plist.path)
        defer { try? f.fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: plist.path) }
        assertIssue(app, .unreadableInfoPlist)
    }

    func testDanglingInfoPlistDoesNotFallBackToRootPlist() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let app = try f.directory("Broken.app")
        _ = try f.directory("Broken.app/Contents")
        try f.fm.createSymbolicLink(atPath: app.appendingPathComponent("Contents/Info.plist").path,
                                   withDestinationPath: "absent.plist")
        try f.plist(["CFBundleIdentifier": "com.other.app"], at: app.appendingPathComponent("Info.plist"))
        assertIssue(app, .unreadableInfoPlist)
    }

    func testIdentityReadsLeavePortalAndOriginalFilesUntouched() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let real = try f.ios("External/bh3.app")
        let portal = try f.stub("Apps/bh3.app", id: "com.miHoYo.bh3", target: real, legacy: true)
        let paths = [real.appendingPathComponent("Wrapper/bh3.app/Info.plist"),
                     portal.appendingPathComponent("Contents/Info.plist"),
                     portal.appendingPathComponent("Contents/MacOS/launcher")]
        let before = try paths.map { try Data(contentsOf: $0) }
        _ = try AppIdentityResolver.resolve(at: portal).get()
        XCTAssertEqual(try paths.map { try Data(contentsOf: $0) }, before)
        XCTAssertEqual(try f.fm.destinationOfSymbolicLink(atPath: real.appendingPathComponent("WrappedBundle").path), "Wrapper/bh3.app")
    }

    func testWrappedMetadataLinksCannotReadExternalIdentity() throws {
        for linkContents in [true, false] {
            let f = try IdentityFixture()
            defer { f.cleanup() }
            let outer = try f.ios("Outer.app")
            let inner = outer.appendingPathComponent("Wrapper/bh3.app")
            try f.fm.removeItem(at: inner.appendingPathComponent("Info.plist"))
            let external = try f.native("Unrelated.app", id: "com.unrelated.external")
            let link = inner.appendingPathComponent(linkContents ? "Contents" : "Info.plist")
            let target = external.appendingPathComponent(linkContents ? "Contents" : "Contents/Info.plist")
            try f.fm.createSymbolicLink(at: link, withDestinationURL: target)
            assertIssue(outer, .outsideWrapper)
        }
    }

    func testInternalWrappedMetadataLinkAndNativeExternalMetadataRemainSupported() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.ios("Outer.app")
        let info = outer.appendingPathComponent("Wrapper/bh3.app/Info.plist")
        let metadata = outer.appendingPathComponent("Metadata/Identity.plist")
        try f.plist(["CFBundleIdentifier": "com.example.internal"], at: metadata)
        try f.fm.removeItem(at: info)
        try f.fm.createSymbolicLink(at: info, withDestinationURL: metadata)
        XCTAssertEqual(try AppIdentityResolver.resolve(at: outer).get().bundleIdentifier, "com.example.internal")
        let native = try f.directory("Native.app")
        _ = try f.directory("Native.app/Contents")
        try f.fm.createSymbolicLink(at: native.appendingPathComponent("Contents/Info.plist"), withDestinationURL: metadata)
        XCTAssertEqual(try AppIdentityResolver.resolve(at: native).get().bundleIdentifier, "com.example.internal")
    }

    func testDotDotAfterSymlinkCannotSelectWrongLocalIdentity() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.directory("Outer.app")
        _ = try f.native("Outer.app/Inner.app", id: "com.decoy.local")
        _ = try f.directory("External/Dir")
        _ = try f.native("External/Inner.app", id: "com.actual.external")
        try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("Alias").path,
                                   withDestinationPath: "../External/Dir")
        try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("WrappedBundle").path,
                                   withDestinationPath: "Alias/../Inner.app")
        assertIssue(outer, .outsideWrapper)
    }

    func testDotDotAfterInternalSymlinkFollowsFilesystemIdentity() throws {
        let f = try IdentityFixture()
        defer { f.cleanup() }
        let outer = try f.directory("Outer.app")
        _ = try f.native("Outer.app/Inner.app", id: "com.decoy.local")
        _ = try f.directory("Outer.app/Inside/Dir")
        _ = try f.native("Outer.app/Inside/Inner.app", id: "com.actual.internal")
        try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("Alias").path,
                                   withDestinationPath: "Inside/Dir")
        try f.fm.createSymbolicLink(atPath: outer.appendingPathComponent("WrappedBundle").path,
                                   withDestinationPath: "Alias/../Inner.app")
        XCTAssertEqual(try AppIdentityResolver.resolve(at: outer).get().bundleIdentifier, "com.actual.internal")
    }

    private func assertIssue(_ url: URL, _ reason: AppIdentityIssue.Reason,
                             file: StaticString = #filePath, line: UInt = #line) {
        switch AppIdentityResolver.resolve(at: url) {
        case .success(let identity): XCTFail("Unexpected identity: \(identity.bundleIdentifier)", file: file, line: line)
        case .failure(let issue): XCTAssertEqual(issue.reason, reason, file: file, line: line)
        }
    }
}
