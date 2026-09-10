import Foundation
import SwiftData

/// Keeps the baseline unversioned schema and default store location unchanged.
/// Versioned schema adoption requires an authentic baseline-store compatibility test first.
@MainActor
enum LedgerStore {
    static func schema() -> Schema {
        Schema([Transaction.self, TransactionSource.self, Category.self,
                PaymentMethod.self, Tag.self, UserProfile.self])
    }

    static func open(
        factory: (Schema, ModelConfiguration) throws -> ModelContainer = {
            try ModelContainer(for: $0, configurations: [$1])
        }
    ) throws -> ModelContainer {
        let schema = schema()
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try factory(schema, configuration)
        container.mainContext.autosaveEnabled = false
        return container
    }
}
