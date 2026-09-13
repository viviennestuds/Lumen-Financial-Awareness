import Foundation
import XCTest
@testable import LumenFinance

final class AppStatePersistenceTests: XCTestCase {
    // Run 6.2: compiled code-path sanity only, not UI-app domain or relaunch evidence.
    @MainActor
    func testOnboardingReadWriteWithinSameProcessRestoresOriginalPreference() {
        let defaults = UserDefaults.standard
        let key = "lumen_has_onboarded"
        let originalValue = defaults.object(forKey: key)
        let originallyExisted = originalValue != nil
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: key)
                XCTAssertEqual(defaults.object(forKey: key) as? NSObject, originalValue as? NSObject,
                               "Restore the original uncoerced preference value")
            } else {
                defaults.removeObject(forKey: key)
                XCTAssertNil(defaults.object(forKey: key), "Restore original preference absence")
            }
            XCTAssertEqual(defaults.object(forKey: key) != nil, originallyExisted)
        }

        defaults.removeObject(forKey: key)
        XCTAssertNil(defaults.object(forKey: key), "Probe requires an absent test-process key")
        let first = AppState()
        XCTAssertFalse(first.hasOnboarded, "Absent preference must initialize as not onboarded")
        first.hasOnboarded = true
        XCTAssertTrue(defaults.bool(forKey: key), "didSet must immediately update the same defaults environment")
        let second = AppState()
        XCTAssertTrue(second.hasOnboarded, "A second AppState must read the in-process write")
    }
}
