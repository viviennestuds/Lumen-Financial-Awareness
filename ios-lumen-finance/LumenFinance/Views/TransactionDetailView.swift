//
//  TransactionDetailView.swift
//  LumenFinance
//
//  Inspect & edit a saved transaction. Supports status changes, including
//  confirm-as-posted / deny-as-ignored for pending items.
//

import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(FeatureFlags.self) private var flags

    @Bindable var transaction: Transaction

    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \PaymentMethod.name) private var paymentMethods: [PaymentMethod]
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var editing = false
    @State private var draft: TransactionDraft?
    @State private var showDeleteConfirm = false
    @State private var writeError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.s4) {
                hero

                if transaction.status == .pending && !editing {
                    pendingControls
                }

                if editing, let draft {
                    TransactionFormFields(
                        draft: draft,
                        categories: categories,
                        paymentMethods: paymentMethods,
                        tags: tags
                    )
                } else {
                    fieldsCard
                    if let source = transaction.source { sourceCard(source) }
                    attachmentCard
                    statusControls
                    deleteButton
                }

                Color.clear.frame(height: editing ? 100 : 40)
            }
            .padding(.horizontal, Theme.s5)
            .padding(.top, Theme.s3)
        }
        .background(Theme.canvas)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .alert("Change not saved", isPresented: Binding(
            get: { writeError != nil }, set: { if !$0 { writeError = nil } }
        )) { Button("OK", role: .cancel) { writeError = nil } } message: {
            Text(writeError ?? "Please try again.")
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if editing {
                    Button("Cancel edit") { draft = nil; editing = false }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(editing ? "Done" : "Edit") {
                    if editing { commitEdits() } else { startEditing() }
                }
                .fontWeight(.semibold)
                .disabled(editing && draft?.isValid != true)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if editing {
                PrimaryButton(title: "Save changes", icon: "checkmark") { commitEdits() }
                    .disabled(draft?.isValid != true)
                    .padding(.horizontal, Theme.s5)
                    .padding(.vertical, Theme.s3)
                    .background(.ultraThinMaterial)
            }
        }
        .confirmationDialog("Delete this transaction?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                do {
                    try LedgerWrite.perform(in: modelContext) { modelContext.delete(transaction) }
                    dismiss()
                } catch { reportWriteFailure(error) }
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: Theme.s2) {
            CategoryGlyph(icon: transaction.category?.icon ?? transaction.transaction_type.symbol,
                          color: transaction.category?.tint ?? transaction.transaction_type.tint, size: 60)
            Text(transaction.merchant_name)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(appState.format(transaction.signedAmount, signed: transaction.transaction_type != .transfer, currency: transaction.currency))
                .font(.system(size: 38, weight: .semibold, design: .serif))
                .foregroundStyle(transaction.transaction_type.isOutflow ? Theme.ink : Theme.income)
                .monospacedDigit()
            StatusBadge(status: transaction.status)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.s4)
        .cardSurface()
    }

    // MARK: - Pending confirm/deny

    private var pendingControls: some View {
        HStack(spacing: Theme.s3) {
            Button { setStatus(.posted) } label: {
                actionLabel("Confirm posted", icon: "checkmark.seal.fill", tint: Theme.income)
            }
            .buttonStyle(PressableStyle())
            Button { setStatus(.ignored) } label: {
                actionLabel("Deny / ignore", icon: "eye.slash.fill", tint: Theme.neutral)
            }
            .buttonStyle(PressableStyle())
        }
    }

    private func actionLabel(_ title: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold))
            Text(title).font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.s4)
        .background(tint.opacity(0.12))
        .clipShape(.rect(cornerRadius: 16))
    }

    // MARK: - Fields

    private var fieldsCard: some View {
        FormCard(title: "Details") {
            DetailRow(label: "Type", value: transaction.transaction_type.label, valueColor: transaction.transaction_type.tint)
            DetailRow(label: "Amount", value: appState.format(transaction.amount, currency: transaction.currency), mono: true)
            DetailRow(label: "Currency", value: transaction.currency)
            DetailRow(label: "Category", value: transaction.category?.name ?? "—")
            DetailRow(label: "Payment method", value: transaction.payment_method?.name ?? "—")
            DetailRow(label: "Transaction date", value: transaction.transaction_date.formatted(date: .abbreviated, time: .omitted))
            if let posted = transaction.posted_date {
                DetailRow(label: "Posted date", value: posted.formatted(date: .abbreviated, time: .omitted))
            }
            if let notes = transaction.notes, !notes.isEmpty {
                DetailRow(label: "Notes", value: notes)
            }
            if !transaction.tags.isEmpty {
                DetailRow(label: "Tags", value: transaction.tags.map { "#\($0.name)" }.joined(separator: "  "))
            }
        }
    }

    private func sourceCard(_ source: TransactionSource) -> some View {
        FormCard(title: "Source") {
            DetailRow(label: "Type", value: source.source_type.label)
            if let name = source.original_filename {
                DetailRow(label: "Filename", value: name, mono: true)
            }
            DetailRow(label: "Parse status", value: source.parse_status.label, valueColor: source.parse_status.tint)
            if let confidence = transaction.confidence_score, confidence.isFinite, (0...1).contains(confidence) {
                DetailRow(label: "Legacy parser confidence", value: "\(Int(confidence * 100))%")
            }
            if let uploaded = source.uploaded_at {
                DetailRow(label: "Uploaded", value: uploaded.formatted(date: .abbreviated, time: .shortened))
            }
            if let raw = source.raw_extracted_text {
                DetailRow(label: "Extracted text", value: raw, mono: true)
            }
        }
    }

    private var attachmentCard: some View {
        FormCard(title: "Attachment") {
            let isUpload = transaction.source?.source_type == .screenshot || transaction.source?.source_type == .receipt_photo
            HStack(spacing: Theme.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.canvasDeep)
                        .frame(width: 56, height: 56)
                    Image(systemName: isUpload ? "doc.text.image" : "tray")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.muted)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(isUpload ? "Original capture" : "No attachment")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(isUpload ? "Preview available in a later phase." : "Manual entries have no file.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var statusControls: some View {
        FormCard(title: "Status") {
            FlowLayout(spacing: Theme.s2) {
                ForEach(TransactionStatus.allCases) { s in
                    Button { setStatus(s) } label: {
                        Text(s.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(transaction.status == s ? .white : s.tint)
                            .padding(.horizontal, Theme.s3)
                            .padding(.vertical, 8)
                            .background(transaction.status == s ? s.tint : s.softTint)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) { showDeleteConfirm = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                Text("Delete transaction")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Theme.expense)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.s3)
        }
    }

    // MARK: - Actions

    private func startEditing() {
        draft = TransactionDraft(from: transaction)
        withAnimation { editing = true }
    }

    private func commitEdits() {
        guard let draft else { return }
        do {
            try LedgerWrite.perform(in: modelContext) { try draft.apply(to: transaction, allTags: tags) }
            withAnimation { editing = false }
            self.draft = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch { reportWriteFailure(error) }
    }

    private func setStatus(_ status: TransactionStatus) {
        guard !editing else { return }
        do {
            try LedgerWrite.perform(in: modelContext) {
                transaction.status = status
                if status == .posted && transaction.posted_date == nil { transaction.posted_date = .now }
                transaction.updated_at = .now
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch { reportWriteFailure(error) }
    }

    private func reportWriteFailure(_ error: Error) {
        writeError = (error as? LedgerWriteError)?.errorDescription
            ?? "The change could not be saved to this device. The previous saved record has been kept. Check available storage and try again."
    }
}
