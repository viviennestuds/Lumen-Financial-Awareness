//
//  Enums.swift
//  LumenFinance
//
//  Domain enums. Raw values are snake_case so they map cleanly to
//  future Supabase columns/check-constraints.
//

import SwiftUI

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    case transfer
    case refund

    var id: String { rawValue }

    var label: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .transfer: return "Transfer"
        case .refund: return "Refund"
        }
    }

    var symbol: String {
        switch self {
        case .expense: return "arrow.up.right"
        case .income: return "arrow.down.left"
        case .transfer: return "arrow.left.arrow.right"
        case .refund: return "arrow.uturn.backward"
        }
    }

    /// True when this type reduces available cash.
    var isOutflow: Bool { self == .expense }

    var tint: Color {
        switch self {
        case .expense: return Theme.expense
        case .income: return Theme.income
        case .transfer: return Theme.info
        case .refund: return Theme.accent
        }
    }
}

enum TransactionStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case posted
    case ignored
    case duplicate
    case review_needed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pending: return "Pending"
        case .posted: return "Posted"
        case .ignored: return "Ignored"
        case .duplicate: return "Duplicate"
        case .review_needed: return "Review needed"
        }
    }

    var tint: Color {
        switch self {
        case .pending: return Theme.pending
        case .posted: return Theme.income
        case .ignored: return Theme.neutral
        case .duplicate: return Theme.expense
        case .review_needed: return Theme.info
        }
    }

    var softTint: Color {
        switch self {
        case .pending: return Theme.pendingSoft
        case .posted: return Theme.incomeSoft
        case .ignored: return Theme.neutralSoft
        case .duplicate: return Theme.expenseSoft
        case .review_needed: return Theme.infoSoft
        }
    }

    var symbol: String {
        switch self {
        case .pending: return "clock"
        case .posted: return "checkmark.seal"
        case .ignored: return "eye.slash"
        case .duplicate: return "doc.on.doc"
        case .review_needed: return "exclamationmark.bubble"
        }
    }
}

enum SourceType: String, Codable, CaseIterable, Identifiable {
    case manual_entry
    case screenshot
    case receipt_photo
    case csv_import
    case json_import
    case paystub
    case fallback_manual

    var id: String { rawValue }

    var label: String {
        switch self {
        case .manual_entry: return "Manual entry"
        case .screenshot: return "Screenshot"
        case .receipt_photo: return "Receipt photo"
        case .csv_import: return "CSV import"
        case .json_import: return "JSON import"
        case .paystub: return "Paystub"
        case .fallback_manual: return "Manual (fallback)"
        }
    }

    var symbol: String {
        switch self {
        case .manual_entry: return "square.and.pencil"
        case .screenshot: return "camera.viewfinder"
        case .receipt_photo: return "doc.text.image"
        case .csv_import: return "tablecells"
        case .json_import: return "curlybraces"
        case .paystub: return "banknote"
        case .fallback_manual: return "hand.point.up.left"
        }
    }
}

enum ParseStatus: String, Codable, CaseIterable {
    case not_parsed
    case parsed
    case failed
    case manual_review

    var label: String {
        switch self {
        case .not_parsed: return "Not parsed"
        case .parsed: return "Parsed"
        case .failed: return "Parse failed"
        case .manual_review: return "Manual review"
        }
    }

    var tint: Color {
        switch self {
        case .not_parsed: return Theme.neutral
        case .parsed: return Theme.income
        case .failed: return Theme.expense
        case .manual_review: return Theme.pending
        }
    }
}

enum CategoryGroup: String, Codable, CaseIterable, Identifiable {
    case fixed_costs
    case investments
    case savings_goals
    case guilt_free_spending
    case income
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fixed_costs: return "Fixed Costs"
        case .investments: return "Investments"
        case .savings_goals: return "Savings Goals"
        case .guilt_free_spending: return "Guilt-Free Spending"
        case .income: return "Income"
        case .custom: return "Custom"
        }
    }

    var tint: Color {
        switch self {
        case .fixed_costs: return Color(hex: "#5C6E8A")
        case .investments: return Color(hex: "#3F7D63")
        case .savings_goals: return Color(hex: "#C2943A")
        case .guilt_free_spending: return Color(hex: "#B65C3C")
        case .income: return Theme.accent
        case .custom: return Theme.neutral
        }
    }
}

enum PaymentMethodType: String, Codable, CaseIterable, Identifiable {
    case cash
    case debit_card
    case credit_card
    case bank_transfer
    case hsa
    case fsa
    case gift_card
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cash: return "Cash"
        case .debit_card: return "Debit Card"
        case .credit_card: return "Credit Card"
        case .bank_transfer: return "Bank Transfer"
        case .hsa: return "HSA"
        case .fsa: return "FSA"
        case .gift_card: return "Gift Card"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .cash: return "banknote"
        case .debit_card: return "creditcard"
        case .credit_card: return "creditcard.fill"
        case .bank_transfer: return "building.columns"
        case .hsa: return "cross.case"
        case .fsa: return "cross.case.fill"
        case .gift_card: return "giftcard"
        case .other: return "ellipsis.circle"
        }
    }
}
