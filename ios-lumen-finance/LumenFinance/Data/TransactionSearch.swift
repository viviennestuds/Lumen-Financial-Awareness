import Foundation

/// Shared predicate so composable Activity filters can be tested without UI automation.
enum TransactionSearch {
    static func matches(_ txn: Transaction, text: String, filter: TxnFilter,
                        category: String?, source: SourceType?) -> Bool {
        switch filter {
        case .all: break
        case .expenses: if txn.transaction_type != .expense { return false }
        case .income: if txn.transaction_type != .income && txn.transaction_type != .refund { return false }
        case .pending: if txn.status != .pending { return false }
        case .posted: if txn.status != .posted { return false }
        case .ignored: if txn.status != .ignored { return false }
        }
        if let category, txn.category?.name != category { return false }
        if let source, (txn.source?.source_type ?? .manual_entry) != source { return false }
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let haystack = "\(txn.merchant_name) \(txn.category?.name ?? "") \(txn.notes ?? "")"
        return query.isEmpty || haystack.localizedStandardContains(query)
    }
}
