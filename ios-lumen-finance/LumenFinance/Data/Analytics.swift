//
//  Analytics.swift
//  LumenFinance
//
//  Pure, derived computations over local transactions. Everything here
//  is computed on demand from SwiftData — no separate persisted totals.
//

import Foundation

/// A small bundle of dashboard figures derived from stored transactions.
struct DashboardSummary {
    var totalSpending: Double = 0
    var totalIncome: Double = 0
    var netFlow: Double = 0
    var countThisWeek: Int = 0
    var loggedThisWeek: Double = 0
    var topCategoryName: String?
    var topCategoryAmount: Double = 0
    var topCategoryColor: String = "#2F6B57"
}

struct CategoryTotal: Identifiable {
    var id: String { name }
    let name: String
    let color: String
    let amount: Double
    let count: Int
}

enum Analytics {
    /// Transactions that count toward spending/insights — exclude ignored & duplicate.
    static func active(_ txns: [Transaction]) -> [Transaction] {
        txns.filter { $0.status != .ignored && $0.status != .duplicate }
    }

    static func isInCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: .now, toGranularity: .month)
    }

    static func isInCurrentWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: .now, toGranularity: .weekOfYear)
    }

    static func summary(_ txns: [Transaction]) -> DashboardSummary {
        var s = DashboardSummary()
        let active = active(txns)

        let monthly = active.filter { isInCurrentMonth($0.transaction_date) }
        s.totalSpending = monthly
            .filter { $0.transaction_type == .expense }
            .reduce(0) { $0 + abs($1.amount) }
        s.totalIncome = monthly
            .filter { $0.transaction_type == .income || $0.transaction_type == .refund }
            .reduce(0) { $0 + abs($1.amount) }
        s.netFlow = s.totalIncome - s.totalSpending

        let weekly = active.filter { isInCurrentWeek($0.transaction_date) }
        s.countThisWeek = weekly.count
        s.loggedThisWeek = weekly
            .filter { $0.transaction_type == .expense }
            .reduce(0) { $0 + abs($1.amount) }

        let totals = categoryTotals(monthly.filter { $0.transaction_type == .expense })
        if let top = totals.first {
            s.topCategoryName = top.name
            s.topCategoryAmount = top.amount
            s.topCategoryColor = top.color
        }
        return s
    }

    /// Expense totals grouped by category, sorted high → low.
    static func categoryTotals(_ txns: [Transaction]) -> [CategoryTotal] {
        var buckets: [String: (color: String, amount: Double, count: Int)] = [:]
        for t in txns where t.transaction_type == .expense {
            let name = t.category?.name ?? "Uncategorized"
            let color = t.category?.color ?? "#94A09A"
            let existing = buckets[name] ?? (color, 0, 0)
            buckets[name] = (color, existing.amount + abs(t.amount), existing.count + 1)
        }
        return buckets
            .map { CategoryTotal(name: $0.key, color: $0.value.color, amount: $0.value.amount, count: $0.value.count) }
            .sorted { $0.amount > $1.amount }
    }

    /// Spending per group (Fixed, Investments, etc.) for the radar placeholder.
    static func groupTotals(_ txns: [Transaction]) -> [(group: CategoryGroup, amount: Double)] {
        var buckets: [CategoryGroup: Double] = [:]
        for t in active(txns) where t.transaction_type == .expense {
            let group = t.category?.group ?? .custom
            buckets[group, default: 0] += abs(t.amount)
        }
        return CategoryGroup.allCases
            .filter { $0 != .income }
            .map { ($0, buckets[$0] ?? 0) }
    }

    /// Naive duplicate detection used for the review warning placeholder.
    static func similarTransaction(to candidate: Transaction, in txns: [Transaction]) -> Transaction? {
        txns.first { other in
            other.id != candidate.id
                && other.merchant_name.lowercased() == candidate.merchant_name.lowercased()
                && abs(other.amount - candidate.amount) < 0.01
                && abs(other.transaction_date.timeIntervalSince(candidate.transaction_date)) < 60 * 60 * 24 * 3
        }
    }
}
