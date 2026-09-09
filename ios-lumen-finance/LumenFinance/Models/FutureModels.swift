//
//  FutureModels.swift
//  LumenFinance
//
//  Phase 2+ entities. Defined now so the data layer and exports stay
//  Supabase-ready, but intentionally NOT wired into the active UI yet.
//  Kept as lightweight Codable DTOs rather than @Model classes so they
//  don't add migration weight before they're needed.
//

import Foundation

nonisolated struct Budget: Codable, Identifiable {
    var id: String = UUID().uuidString
    var user_id: String?
    var name: String
    var period: String           // e.g. "monthly"
    var amount: Double
    var currency: String = "USD"
    var created_at: Date = .now
}

nonisolated struct BudgetAllocation: Codable, Identifiable {
    var id: String = UUID().uuidString
    var budget_id: String
    var category_id: String
    var allocated_amount: Double
}

nonisolated struct CashflowPhase: Codable, Identifiable {
    var id: String = UUID().uuidString
    var user_id: String?
    var name: String             // e.g. "Stabilizing", "Building", "Thriving"
    var summary: String
    var starts_on: Date?
    var ends_on: Date?
}

nonisolated struct Goal: Codable, Identifiable {
    var id: String = UUID().uuidString
    var user_id: String?
    var name: String
    var target_amount: Double
    var saved_amount: Double = 0
    var target_date: Date?
}

nonisolated struct TransactionItem: Codable, Identifiable {
    var id: String = UUID().uuidString
    var transaction_id: String
    var description: String
    var quantity: Double = 1
    var unit_price: Double
}

nonisolated struct ExportRecord: Codable, Identifiable {
    var id: String = UUID().uuidString
    var user_id: String?
    var format: String           // "json" | "csv"
    var created_at: Date = .now
    var row_count: Int
}

nonisolated struct Attachment: Codable, Identifiable {
    var id: String = UUID().uuidString
    var transaction_id: String?
    var source_id: String?
    var file_uri: String
    var mime_type: String?
}
