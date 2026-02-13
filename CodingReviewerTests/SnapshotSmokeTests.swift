import Foundation
import XCTest
@testable import CodingReviewer

final class SnapshotSmokeTests: XCTestCase {
    func testLineSnapshotIntegration() throws {
        let baseline = "codingreviewer|analysis|baseline-v1"
        try assertSnapshot(baseline, named: "testLineSnapshotIntegration.1")
    }

    private func assertSnapshot(
        _ snapshot: String,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let currentFile = URL(fileURLWithPath: String(describing: file))
        let snapshotURL = currentFile.deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent("SnapshotSmokeTests")
            .appendingPathComponent("\(name).txt")

        let expected = try String(contentsOf: snapshotURL, encoding: .utf8)
        XCTAssertEqual(
            snapshot,
            expected.trimmingCharacters(in: .whitespacesAndNewlines),
            line: line
        )
    }
}
