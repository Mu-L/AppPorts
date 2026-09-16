import XCTest
@testable import AppPorts

@MainActor
final class AppOperationStateTests: XCTestCase {
    func testDuplicateOperationsAreRejectedAndStaleCompletionCannotUnlockANewerOperation() throws {
        let state = AppOperationState()
        let first = try XCTUnwrap(state.begin())
        XCTAssertTrue(state.isBusy)
        XCTAssertNil(state.begin())

        state.finish(UUID())
        XCTAssertTrue(state.isBusy)
        state.finish(first)
        XCTAssertFalse(state.isBusy)

        let second = try XCTUnwrap(state.begin())
        state.finish(first)
        XCTAssertTrue(state.isBusy)
        XCTAssertNil(state.begin())
        state.finish(second)
        XCTAssertFalse(state.isBusy)
    }
}
