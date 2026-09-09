//
//  Models.swift
//  LumenFinance
//
//  SwiftData models. Property names mirror the planned Supabase schema
//  (ids, foreign keys, timestamps) so a future sync layer maps 1:1.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class UserProfile {
    var id: String
    var display_name: String
    var default_currency: String
    var timezone: String
    var local_first_enabled: Bool
    var created_at: Date
    var updated_at: Date

    init(
        id: String = UUID().uuidString,
        display_name: String = "You",
        default_currency: String = "USD",
        timezone: String = TimeZone.current.identifier,
        local_first_enabled: Bool = true,
        created_at: Date = .now,
        updated_at: Date = .now
    ) {
        self.id = id
        self.display_name = display_name
        self.default_currency = default_currency
        self.timezone = timezone
        self.local_first_enabled = local_first_enabled
        self.created_at = created_at
        self.updated_at = updated_at
    }
}

@Model
final class Category {
    var id: String
    var name: String
    var group: CategoryGroup
    var color: String
    var icon: String
    var is_default: Bool
    var created_at: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        group: CategoryGroup,
        color: String,
        icon: String,
        is_default: Bool = true,
        created_at: Date = .now
    ) {
        self.id = id
        self.name = name
        self.group = group
        self.color = color
        self.icon = icon
        self.is_default = is_default
        self.created_at = created_at
    }

    var tint: Color { Color(hex: color) }
}

@Model
final class PaymentMethod {
    var id: String
    var name: String
    var method_type: PaymentMethodType
    var institution_name: String?
    var last_four: String?
    var notes: String?
    var is_active: Bool
    var created_at: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        method_type: PaymentMethodType,
        institution_name: String? = nil,
        last_four: String? = nil,
        notes: String? = nil,
        is_active: Bool = true,
        created_at: Date = .now
    ) {
        self.id = id
        self.name = name
        self.method_type = method_type
        self.institution_name = institution_name
        self.last_four = last_four
        self.notes = notes
        self.is_active = is_active
        self.created_at = created_at
    }
}

@Model
final class Tag {
    var id: String
    var name: String
    var color: String
    var created_at: Date

    @Relationship(inverse: \Transaction.tags) var transactions: [Transaction] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        color: String = "#2F6B57",
        created_at: Date = .now
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.created_at = created_at
    }

    var tint: Color { Color(hex: color) }
}

@Model
final class TransactionSource {
    var id: String
    var source_type: SourceType
    var original_filename: String?
    var stored_file_uri: String?
    var compressed_file_uri: String?
    var file_size_bytes: Int?
    var mime_type: String?
    var uploaded_at: Date?
    var captured_at: Date?
    var source_timezone: String?
    var metadata_json: String?
    var raw_extracted_text: String?
    var parse_status: ParseStatus
    var source_hash: String?
    var created_at: Date

    init(
        id: String = UUID().uuidString,
        source_type: SourceType,
        original_filename: String? = nil,
        stored_file_uri: String? = nil,
        compressed_file_uri: String? = nil,
        file_size_bytes: Int? = nil,
        mime_type: String? = nil,
        uploaded_at: Date? = nil,
        captured_at: Date? = nil,
        source_timezone: String? = nil,
        metadata_json: String? = nil,
        raw_extracted_text: String? = nil,
        parse_status: ParseStatus = .not_parsed,
        source_hash: String? = nil,
        created_at: Date = .now
    ) {
        self.id = id
        self.source_type = source_type
        self.original_filename = original_filename
        self.stored_file_uri = stored_file_uri
        self.compressed_file_uri = compressed_file_uri
        self.file_size_bytes = file_size_bytes
        self.mime_type = mime_type
        self.uploaded_at = uploaded_at
        self.captured_at = captured_at
        self.source_timezone = source_timezone
        self.metadata_json = metadata_json
        self.raw_extracted_text = raw_extracted_text
        self.parse_status = parse_status
        self.source_hash = source_hash
        self.created_at = created_at
    }
}

@Model
final class Transaction {
    var id: String
    var user_id: String?
    var amount: Double
    var currency: String
    var transaction_type: TransactionType
    var merchant_name: String
    var transaction_date: Date
    var posted_date: Date?
    var status: TransactionStatus
    var notes: String?
    var confidence_score: Double?
    var duplicate_fingerprint: String?
    // Future-ready foreign keys (kept nullable for Phase 1).
    var cashflow_phase_id: String?
    var budget_id: String?
    var created_at: Date
    var updated_at: Date

    @Relationship var source: TransactionSource?
    @Relationship var category: Category?
    @Relationship var payment_method: PaymentMethod?
    @Relationship var tags: [Tag] = []

    init(
        id: String = UUID().uuidString,
        user_id: String? = nil,
        amount: Double,
        currency: String = "USD",
        transaction_type: TransactionType = .expense,
        merchant_name: String,
        transaction_date: Date = .now,
        posted_date: Date? = nil,
        status: TransactionStatus = .pending,
        notes: String? = nil,
        confidence_score: Double? = nil,
        duplicate_fingerprint: String? = nil,
        cashflow_phase_id: String? = nil,
        budget_id: String? = nil,
        created_at: Date = .now,
        updated_at: Date = .now,
        source: TransactionSource? = nil,
        category: Category? = nil,
        payment_method: PaymentMethod? = nil,
        tags: [Tag] = []
    ) {
        self.id = id
        self.user_id = user_id
        self.amount = amount
        self.currency = currency
        self.transaction_type = transaction_type
        self.merchant_name = merchant_name
        self.transaction_date = transaction_date
        self.posted_date = posted_date
        self.status = status
        self.notes = notes
        self.confidence_score = confidence_score
        self.duplicate_fingerprint = duplicate_fingerprint
        self.cashflow_phase_id = cashflow_phase_id
        self.budget_id = budget_id
        self.created_at = created_at
        self.updated_at = updated_at
        self.source = source
        self.category = category
        self.payment_method = payment_method
        self.tags = tags
    }

    /// Signed value for cashflow math (expenses negative, income/refund positive).
    var signedAmount: Double {
        transaction_type.isOutflow ? -abs(amount) : abs(amount)
    }
}
