import Foundation

struct DashboardSummary {
    var totalSpending: Double = 0
    var totalIncome: Double = 0
    var netFlow: Double = 0
    var countThisWeek: Int = 0
    var loggedThisWeek: Double = 0
    var excludedCurrencyCount: Int = 0
    var invalidAmountCount: Int = 0
    var topCategoryName: String?
    var topCategoryAmount: Double = 0
    var topCategoryColor: String = "#2F6B57"
}

struct CategoryTotal: Identifiable {
    let id: String
    let name: String
    let color: String
    let amount: Double
    let count: Int
}

enum Analytics {
    /// Compatibility policy: legacy review_needed records may already have been user-confirmed.
    /// Preserve their inclusion until an authentic-store-tested status migration is available.
    static func active(_ txns: [Transaction]) -> [Transaction] {
        txns.filter { $0.status != .ignored && $0.status != .duplicate }
    }

    static func scoped(_ txns: [Transaction], currency: String) -> [Transaction] {
        active(txns).filter { $0.currency == currency && Money.magnitude($0.amount) != nil }
    }

    static func isInCurrentMonth(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, equalTo: now, toGranularity: .month)
    }

    static func isInCurrentWeek(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
    }

    private static func sum(_ txns: [Transaction]) -> Decimal {
        txns.reduce(Decimal.zero) { $0 + (Money.magnitude($1.amount) ?? .zero) }
    }

    private static func displayValue(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    /// Expenses are gross spending. Income includes refunds. Transfers affect neither total.
    /// Weekly activity uses transaction_date, not the time the record was created.
    static func summary(_ txns: [Transaction], currency: String, now: Date = .now,
                        calendar: Calendar = .current) -> DashboardSummary {
        var result = DashboardSummary()
        let active = active(txns)
        result.excludedCurrencyCount = active.filter { $0.currency != currency }.count
        result.invalidAmountCount = active.filter { Money.magnitude($0.amount) == nil }.count
        let eligible = scoped(txns, currency: currency)
        let monthly = eligible.filter { isInCurrentMonth($0.transaction_date, now: now, calendar: calendar) }
        let spending = sum(monthly.filter { $0.transaction_type == .expense })
        let incoming = sum(monthly.filter { $0.transaction_type == .income || $0.transaction_type == .refund })
        result.totalSpending = displayValue(spending)
        result.totalIncome = displayValue(incoming)
        result.netFlow = displayValue(incoming - spending)
        let weekly = eligible.filter { isInCurrentWeek($0.transaction_date, now: now, calendar: calendar) }
        result.countThisWeek = weekly.count
        result.loggedThisWeek = displayValue(sum(weekly.filter { $0.transaction_type == .expense }))
        if let top = categoryTotals(monthly, currency: currency).first {
            result.topCategoryName = top.name
            result.topCategoryAmount = top.amount
            result.topCategoryColor = top.color
        }
        return result
    }

    static func categoryTotals(_ txns: [Transaction], currency: String) -> [CategoryTotal] {
        let expenses = scoped(txns, currency: currency).filter { $0.transaction_type == .expense }
        let groups = Dictionary(grouping: expenses) { $0.category?.id ?? "uncategorized" }
        return groups.map { id, records in
            CategoryTotal(id: id, name: records.first?.category?.name ?? "Uncategorized",
                          color: records.first?.category?.color ?? "#94A09A",
                          amount: displayValue(sum(records)), count: records.count)
        }.sorted { $0.amount == $1.amount ? $0.id < $1.id : $0.amount > $1.amount }
    }

    static func groupTotals(_ txns: [Transaction], currency: String) -> [(group: CategoryGroup, amount: Double)] {
        let expenses = scoped(txns, currency: currency).filter { $0.transaction_type == .expense }
        return CategoryGroup.allCases.filter { $0 != .income }.map { group in
            (group, displayValue(sum(expenses.filter { ($0.category?.group ?? .custom) == group })))
        }
    }

    /// Advisory financial-event similarity, not evidence identity. No models are created here.
    static func similarTransaction(to candidate: TransactionDraft, in txns: [Transaction],
                                   excludingID: String? = nil) -> Transaction? {
        guard let amount = Money.magnitude(candidate.amount), candidate.amount > 0 else { return nil }
        let merchant = candidate.merchant_name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !merchant.isEmpty else { return nil }
        return active(txns).filter { other in
            other.id != excludingID
                && other.currency == candidate.currency
                && other.transaction_type == candidate.transaction_type
                && other.merchant_name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == merchant
                && Money.magnitude(other.amount) == amount
                && (other.payment_method == nil || candidate.payment_method == nil
                    || other.payment_method?.id == candidate.payment_method?.id)
                && abs(other.transaction_date.timeIntervalSince(candidate.transaction_date)) < 3 * 24 * 60 * 60
        }.sorted {
            let a = abs($0.transaction_date.timeIntervalSince(candidate.transaction_date))
            let b = abs($1.transaction_date.timeIntervalSince(candidate.transaction_date))
            return a == b ? $0.id < $1.id : a < b
        }.first
    }
}
