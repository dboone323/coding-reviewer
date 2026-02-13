import XCTest
@testable import CodingReviewer

final class IntegrationBaselineTests: XCTestCase {
    func testUserDefaultsIntegrationBaseline() {
        let key = "integration_baseline_CodingReviewer"
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: key)
        XCTAssertTrue(defaults.bool(forKey: key))
        defaults.removeObject(forKey: key)
    }
}
