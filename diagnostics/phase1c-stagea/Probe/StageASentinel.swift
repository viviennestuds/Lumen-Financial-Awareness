import Foundation
import SwiftData

/// A deliberately minimal model, unrelated to Lumen's production financial schema.
@Model
final class StageASentinel {
    var runID: String
    var token: String

    init(runID: String, token: String) {
        self.runID = runID
        self.token = token
    }

    static let fixedToken = "STAGE_A_SYNTHETIC_SENTINEL_V1"
}
