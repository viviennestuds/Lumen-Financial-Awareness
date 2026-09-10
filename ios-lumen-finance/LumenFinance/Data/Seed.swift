//
//  Seed.swift
//  LumenFinance
//
//  Initializes reference defaults without inventing financial history.
//  Sample transactions below are for explicitly isolated tests/diagnostics only.
//

import Foundation
import SwiftData

@MainActor
enum Seed {
    /// Fetch failures are never interpreted as an empty store. All defaults commit together.
    static func bootstrapIfNeeded(
        _ context: ModelContext,
        commit: ((ModelContext) throws -> Void)? = nil
    ) throws {
        let needsCategories = try context.fetchCount(FetchDescriptor<Category>()) == 0
        let needsMethods = try context.fetchCount(FetchDescriptor<PaymentMethod>()) == 0
        let needsTags = try context.fetchCount(FetchDescriptor<Tag>()) == 0
        guard needsCategories || needsMethods || needsTags else { return }
        try LedgerWrite.perform(in: context, commit: commit) {
            if needsCategories { seedCategories().forEach { context.insert($0) } }
            if needsMethods { seedPaymentMethods().forEach { context.insert($0) } }
            if needsTags { seedTags().forEach { context.insert($0) } }
        }
    }

    // MARK: - Categories

    static func seedCategories() -> [Category] {
        var result: [Category] = []
        func make(_ name: String, _ group: CategoryGroup, _ color: String, _ icon: String) {
            result.append(Category(name: name, group: group, color: color, icon: icon))
        }

        // Fixed Costs
        make("Rent/Mortgage", .fixed_costs, "#5C6E8A", "house")
        make("Utilities", .fixed_costs, "#5C6E8A", "bolt")
        make("Insurance", .fixed_costs, "#5C6E8A", "shield")
        make("Transportation", .fixed_costs, "#5C6E8A", "car")
        make("Debt Payments", .fixed_costs, "#5C6E8A", "creditcard.trianglebadge.exclamationmark")
        make("Groceries", .fixed_costs, "#5C6E8A", "cart")
        make("Phone", .fixed_costs, "#5C6E8A", "iphone")
        make("Subscriptions", .fixed_costs, "#5C6E8A", "repeat")

        // Investments
        make("Retirement", .investments, "#3F7D63", "chart.line.uptrend.xyaxis")
        make("Stocks", .investments, "#3F7D63", "chart.bar")

        // Savings Goals
        make("Emergency Fund", .savings_goals, "#C2943A", "umbrella")
        make("Vacation", .savings_goals, "#C2943A", "airplane")
        make("Gifts", .savings_goals, "#C2943A", "gift")

        // Guilt-Free Spending
        make("Dining", .guilt_free_spending, "#B65C3C", "fork.knife")
        make("Entertainment", .guilt_free_spending, "#B65C3C", "ticket")
        make("Shopping", .guilt_free_spending, "#B65C3C", "bag")
        make("Hobbies", .guilt_free_spending, "#B65C3C", "paintpalette")

        // Income
        make("Paycheck", .income, "#2F6B57", "banknote")
        make("Reimbursement", .income, "#2F6B57", "arrow.uturn.backward.circle")
        make("Other Income", .income, "#2F6B57", "plus.circle")

        // A couple custom ones referenced by seed data
        make("Household", .guilt_free_spending, "#B65C3C", "house.and.flag")
        make("Personal Care", .guilt_free_spending, "#B65C3C", "sparkles")
        make("Medical / HSA", .fixed_costs, "#5C6E8A", "cross.case")

        return result
    }

    // MARK: - Payment Methods

    static func seedPaymentMethods() -> [PaymentMethod] {
        [
            PaymentMethod(name: "Cash", method_type: .cash),
            PaymentMethod(name: "Debit Card", method_type: .debit_card, institution_name: "Everyday Bank", last_four: "4821"),
            PaymentMethod(name: "Credit Card", method_type: .credit_card, institution_name: "Aurora Card", last_four: "9023"),
            PaymentMethod(name: "Bank Transfer", method_type: .bank_transfer, institution_name: "Everyday Bank"),
            PaymentMethod(name: "HSA", method_type: .hsa, institution_name: "HealthSave"),
            PaymentMethod(name: "FSA", method_type: .fsa),
            PaymentMethod(name: "Gift Card", method_type: .gift_card),
        ]
    }

    static func seedTags() -> [Tag] {
        [
            Tag(name: "recurring", color: "#5C6E8A"),
            Tag(name: "treat", color: "#B65C3C"),
            Tag(name: "essential", color: "#2F6B57"),
            Tag(name: "reimbursable", color: "#C2943A"),
        ]
    }

    // MARK: - Transactions

    static func seedTransactions(
        categories: [Category],
        methods: [PaymentMethod],
        tags: [Tag],
        context: ModelContext
    ) {
        func cat(_ name: String) -> Category? { categories.first { $0.name == name } }
        func pm(_ type: PaymentMethodType) -> PaymentMethod? { methods.first { $0.method_type == type } }
        func tag(_ name: String) -> Tag? { tags.first { $0.name == name } }

        let cal = Calendar.current
        func daysAgo(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: .now) ?? .now }

        struct SeedSpec {
            let merchant: String
            let amount: Double
            let type: TransactionType
            let status: TransactionStatus
            let category: String
            let pm: PaymentMethodType
            let source: SourceType
            let day: Int
            let confidence: Double?
            let tags: [String]
            let notes: String?
        }

        let specs: [SeedSpec] = [
            .init(merchant: "DoorDash", amount: 28.74, type: .expense, status: .pending, category: "Dining", pm: .credit_card, source: .screenshot, day: 1, confidence: 0.82, tags: ["treat"], notes: "Friday dinner"),
            .init(merchant: "Temu", amount: 41.20, type: .expense, status: .pending, category: "Shopping", pm: .credit_card, source: .screenshot, day: 2, confidence: 0.71, tags: [], notes: nil),
            .init(merchant: "Dollar Tree", amount: 13.46, type: .expense, status: .pending, category: "Household", pm: .debit_card, source: .receipt_photo, day: 3, confidence: 0.88, tags: ["essential"], notes: nil),
            .init(merchant: "Sunrise Nails", amount: 45.00, type: .expense, status: .pending, category: "Personal Care", pm: .debit_card, source: .manual_entry, day: 4, confidence: nil, tags: ["treat"], notes: "Self-care day"),
            .init(merchant: "OpenAI", amount: 20.00, type: .expense, status: .posted, category: "Subscriptions", pm: .credit_card, source: .manual_entry, day: 6, confidence: nil, tags: ["recurring"], notes: "ChatGPT Plus"),
            .init(merchant: "Paycheck Direct Deposit", amount: 2180.00, type: .income, status: .posted, category: "Paycheck", pm: .bank_transfer, source: .manual_entry, day: 7, confidence: nil, tags: ["recurring"], notes: "Bi-weekly"),
            .init(merchant: "HSA Pharmacy Purchase", amount: 34.18, type: .expense, status: .posted, category: "Medical / HSA", pm: .hsa, source: .receipt_photo, day: 5, confidence: 0.93, tags: ["reimbursable"], notes: "Prescription refill"),
        ]

        for spec in specs {
            let source = TransactionSource(
                source_type: spec.source,
                original_filename: spec.source == .screenshot ? "IMG_\(Int.random(in: 1000...9999)).png"
                    : (spec.source == .receipt_photo ? "receipt_\(Int.random(in: 100...999)).jpg" : nil),
                uploaded_at: spec.source == .manual_entry ? nil : daysAgo(spec.day),
                captured_at: spec.source == .manual_entry ? nil : daysAgo(spec.day),
                raw_extracted_text: spec.source == .manual_entry ? nil : "\(spec.merchant)  $\(String(format: "%.2f", spec.amount))",
                parse_status: spec.source == .manual_entry ? .not_parsed : .parsed
            )
            context.insert(source)

            let selectedTags = spec.tags.compactMap { tag($0) }
            let txn = Transaction(
                amount: spec.amount,
                transaction_type: spec.type,
                merchant_name: spec.merchant,
                transaction_date: daysAgo(spec.day),
                posted_date: spec.status == .posted ? daysAgo(spec.day) : nil,
                status: spec.status,
                notes: spec.notes,
                confidence_score: spec.confidence,
                source: source,
                category: cat(spec.category),
                payment_method: pm(spec.pm),
                tags: selectedTags
            )
            context.insert(txn)
        }
    }
}
