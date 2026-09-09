//
//  TransactionRow.swift
//  LumenFinance
//
//  Compact transaction list row shared by Dashboard & Transactions.
//

import SwiftUI

struct TransactionRow: View {
    @Environment(AppState.self) private var appState
    let txn: Transaction

    private var icon: String { txn.category?.icon ?? txn.transaction_type.symbol }
    private var tint: Color { txn.category?.tint ?? txn.transaction_type.tint }

    var body: some View {
        HStack(spacing: Theme.s3) {
            CategoryGlyph(icon: icon, color: tint, size: 44)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: txn.source?.source_type.symbol ?? "square.and.pencil")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(3)
                        .background(Theme.surfaceRaised)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 0.5))
                        .offset(x: 3, y: 3)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(txn.merchant_name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(txn.category?.name ?? txn.transaction_type.label)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(1)
                    if txn.status == .pending {
                        Circle().fill(Theme.pending).frame(width: 4, height: 4)
                        Text("Pending")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.pending)
                    }
                }
            }

            Spacer(minLength: Theme.s2)

            VStack(alignment: .trailing, spacing: 3) {
                Text(appState.format(txn.signedAmount, signed: true))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(txn.transaction_type.isOutflow ? Theme.ink : Theme.income)
                    .monospacedDigit()
                Text(txn.transaction_date, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }
        }
        .contentShape(Rectangle())
    }
}
