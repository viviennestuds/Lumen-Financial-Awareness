//
//  ReviewTransactionView.swift
//  LumenFinance
//
//  Final confirmation before persisting. For uploaded sources it shows
//  parse metadata, confidence, and a duplicate warning. Nothing is ever
//  auto-saved — the user must explicitly Save.
//

import SwiftUI
import SwiftData

struct ReviewTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var draft: TransactionDraft
    var onSave: () -> Void

    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \PaymentMethod.name) private var paymentMethods: [PaymentMethod]
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Query private var allTransactions: [Transaction]

    @State private var editing = false
    @State private var saveError: String?
    @State private var hasSaved: Bool = false

    private var duplicate: Transaction? {
        Analytics.similarTransaction(to: draft, in: allTransactions)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.s4) {
                if let source = draft.source {
                    StubBanner(title: "Preview stub — not OCR", message: "These sample fields were not read from your photo. Check every field before confirming.")
                    sourceCard(source)
                }
                if let dup = duplicate {
                    duplicateWarning(dup)
                }

                if editing {
                    TransactionFormFields(
                        draft: draft,
                        categories: categories,
                        paymentMethods: paymentMethods,
                        tags: tags
                    )
                } else {
                    summaryCard
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, Theme.s5)
            .padding(.top, Theme.s3)
        }
        .background(Theme.canvas)
        .scrollIndicators(.hidden)
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .scrollDismissesKeyboard(.interactively)
        .alert("Transaction not saved", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) { Button("OK", role: .cancel) { saveError = nil } } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(spacing: Theme.s4) {
            VStack(spacing: Theme.s2) {
                CategoryGlyph(icon: draft.category?.icon ?? draft.transaction_type.symbol,
                              color: draft.category?.tint ?? draft.transaction_type.tint, size: 56)
                Text(draft.merchant_name.isEmpty ? "Untitled" : draft.merchant_name)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(formattedAmount)
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(draft.transaction_type.isOutflow ? Theme.ink : Theme.income)
                    .monospacedDigit()
                StatusBadge(status: draft.status)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.s3)

            Divider().background(Theme.hairline)

            VStack(spacing: Theme.s2) {
                DetailRow(label: "Type", value: draft.transaction_type.label)
                DetailRow(label: "Category", value: draft.category?.name ?? "—")
                DetailRow(label: "Payment method", value: draft.payment_method?.name ?? "—")
                DetailRow(label: "Date", value: draft.transaction_date.formatted(date: .abbreviated, time: .omitted))
                if let posted = draft.posted_date {
                    DetailRow(label: "Posted", value: posted.formatted(date: .abbreviated, time: .omitted))
                }
                if !draft.notes.isEmpty {
                    DetailRow(label: "Notes", value: draft.notes)
                }
                if !selectedTagNames.isEmpty {
                    DetailRow(label: "Tags", value: selectedTagNames)
                }
            }
        }
        .cardSurface()
    }

    private var selectedTagNames: String {
        tags.filter { draft.tagIDs.contains($0.id) }.map { "#\($0.name)" }.joined(separator: "  ")
    }

    private var formattedAmount: String {
        Money.format(draft.amount, currency: draft.currency)
    }

    // MARK: - Source / parse card

    private func sourceCard(_ source: TransactionSource) -> some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            HStack {
                Image(systemName: source.source_type.symbol)
                    .foregroundStyle(Theme.accent)
                Text(source.source_type.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                parseBadge(source.parse_status)
            }
            VStack(spacing: Theme.s2) {
                if let name = source.original_filename {
                    DetailRow(label: "Filename", value: name, mono: true)
                }
                if let uploaded = source.uploaded_at {
                    DetailRow(label: "Uploaded", value: uploaded.formatted(date: .abbreviated, time: .shortened))
                }
                if let confidence = draft.confidence_score, confidence.isFinite, (0...1).contains(confidence) {
                    confidenceRow(confidence)
                }
                if let raw = source.raw_extracted_text {
                    DetailRow(label: "Extracted", value: raw, mono: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func parseBadge(_ status: ParseStatus) -> some View {
        Text(status.label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(status.tint.opacity(0.14))
            .clipShape(.rect(cornerRadius: 8))
    }

    private func confidenceRow(_ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Parse confidence").font(.system(size: 14)).foregroundStyle(Theme.inkSecondary)
                Spacer()
                Text("\(Int(value * 100))%").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.canvasDeep)
                    Capsule().fill(value > 0.8 ? Theme.income : Theme.pending)
                        .frame(width: geo.size.width * value)
                }
            }
            .frame(height: 6)
        }
    }

    private func duplicateWarning(_ dup: Transaction) -> some View {
        HStack(spacing: Theme.s3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.expense)
            VStack(alignment: .leading, spacing: 2) {
                Text("Possible duplicate")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Similar to \(dup.merchant_name) on \(dup.transaction_date.formatted(date: .abbreviated, time: .omitted)).")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.expenseSoft.opacity(0.6))
        .clipShape(.rect(cornerRadius: 14))
    }

    // MARK: - Bottom actions

    private var bottomBar: some View {
        VStack(spacing: Theme.s2) {
            PrimaryButton(title: duplicate == nil ? "Save transaction" : "Save anyway", icon: "checkmark") {
                save()
            }
            .disabled(!draft.canConfirm || hasSaved)
            .opacity(draft.canConfirm && !hasSaved ? 1 : 0.5)
            .accessibilityIdentifier("confirmTransaction")
            if !draft.canConfirm {
                Text("Edit fields to choose a category, valid amount, and pending or posted status.")
                    .font(.footnote).foregroundStyle(Theme.inkSecondary)
            }

            HStack(spacing: Theme.s2) {
                secondaryButton(editing ? "Done editing" : "Edit fields", icon: "slider.horizontal.3") {
                    withAnimation { editing.toggle() }
                }
                secondaryButton("Discard draft", icon: "eye.slash") {
                    // Discard is not a canonical financial write.
                    onSave()
                }
            }
            Button("Cancel") { dismiss() }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, Theme.s5)
        .padding(.top, Theme.s3)
        .padding(.bottom, Theme.s3)
        .background(.ultraThinMaterial)
    }

    private func secondaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.accentSoft)
            .clipShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(PressableStyle())
    }

    private func save() {
        guard !hasSaved else { return }
        guard draft.canConfirm else {
            saveError = "Check the amount, merchant, currency, category, and financial status."
            return
        }
        let hasDuplicate = duplicate != nil
        do {
            try LedgerWrite.perform(in: modelContext) {
                let txn = try draft.makeTransaction(allTags: tags)
                if hasDuplicate { txn.duplicate_fingerprint = "soft-match" }
                modelContext.insert(txn)
            }
            hasSaved = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSave()
        } catch {
            saveError = (error as? LedgerWriteError)?.errorDescription
                ?? "The transaction could not be saved to this device. Your draft is still here. Check available storage and try again."
        }
    }
}
