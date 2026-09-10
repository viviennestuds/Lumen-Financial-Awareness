import Foundation

nonisolated enum LedgerWriteError: LocalizedError {
    case invalidDraft
    case uncommittedChanges

    var errorDescription: String? {
        switch self {
        case .invalidDraft:
            return "Enter a positive, finite amount, a currency, a merchant, and a category before saving."
        case .uncommittedChanges:
            return "There are unexpected unsaved changes. Close and reopen Lumen before trying again."
        }
    }
}
