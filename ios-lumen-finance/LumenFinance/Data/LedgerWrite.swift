import Foundation
import SwiftData

/// A synchronous commit boundary: drafts remain outside the context until confirmation.
/// The clean-context precondition makes rollback local to this operation, not other work.
@MainActor
enum LedgerWrite {
    static func perform<T>(
        in context: ModelContext,
        commit: ((ModelContext) throws -> Void)? = nil,
        mutation: () throws -> T
    ) throws -> T {
        guard !context.hasChanges else { throw LedgerWriteError.uncommittedChanges }
        context.autosaveEnabled = false
        do {
            let result = try mutation()
            if let commit { try commit(context) } else { try context.save() }
            return result
        } catch {
            context.rollback()
            throw error
        }
    }
}
