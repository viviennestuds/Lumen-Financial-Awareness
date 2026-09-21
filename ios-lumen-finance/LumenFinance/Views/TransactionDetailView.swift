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
    @State private var evidenceResolution: EvidenceAvailabilityResolution?
    @State private var evidenceResolutionFailed = false

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
        .task(id: evidenceResolutionKey) {
            refreshEvidenceAvailability()
        }
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
        let presentation = attachmentPresentation

        return FormCard(title: "Attachment") {
            HStack(spacing: Theme.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.canvasDeep)
                        .frame(width: 56, height: 56)
                    Image(systemName: presentation.systemImage)
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.muted)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(presentation.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var evidenceResolutionKey: String {
        [
            transaction.source?.id ?? "no-source",
            transaction.source?.stored_file_uri ?? "no-locator",
            String(transaction.updated_at.timeIntervalSince1970)
        ]
        .joined(separator: "|")
    }

    private var attachmentPresentation: AttachmentPresentation {
        if evidenceResolutionFailed {
            return AttachmentPresentation(
                systemImage: "exclamationmark.triangle",
                title: "Attachment status unavailable",
                detail: "Lumen couldn’t determine the retained attachment status right now."
            )
        }

        guard let evidenceResolution else {
            return AttachmentPresentation(
                systemImage: "hourglass",
                title: "Checking attachment",
                detail: "Lumen is checking the retained attachment on this device."
            )
        }

        switch evidenceResolution.state {
        case .noEvidenceExpected:
            return AttachmentPresentation(
                systemImage: "tray",
                title: "No attachment",
                detail: "No retained evidence is associated with this transaction."
            )

        case .noRetainedLocator:
            let isImageOrigin =
                transaction.source?.source_type == .screenshot
                || transaction.source?.source_type == .receipt_photo

            return AttachmentPresentation(
                systemImage: isImageOrigin ? "photo" : "tray",
                title: isImageOrigin
                    ? "Original image not retained"
                    : "No retained attachment",
                detail: "No retained-evidence locator was recorded for this source."
            )

        case .available:
            return AttachmentPresentation(
                systemImage: "doc.text.image",
                title: "Retained image available",
                detail: "The retained image is readable on this device."
            )

        case .expectedButUnavailable:
            return AttachmentPresentation(
                systemImage: "exclamationmark.triangle",
                title: "Retained image currently unavailable",
                detail: "Lumen can’t read the expected retained image on this device."
            )

        case .legacyOpaque:
            return AttachmentPresentation(
                systemImage: "clock.arrow.circlepath",
                title: "Historical source context",
                detail: "This source uses a historical attachment reference that Lumen does not interpret as retained v1 evidence."
            )

        case .unsupportedVersion(let version):
            return AttachmentPresentation(
                systemImage: "questionmark.folder",
                title: "Unsupported attachment format",
                detail: "This version of Lumen does not support retained-evidence locator version \(version)."
            )

        case .invalidLocator:
            return AttachmentPresentation(
                systemImage: "exclamationmark.triangle",
                title: "Attachment unavailable",
                detail: "The retained attachment reference is invalid."
            )

        case .invalidAssociation:
            return AttachmentPresentation(
                systemImage: "exclamationmark.triangle",
                title: "Attachment unavailable",
                detail: "The retained attachment reference does not match this source."
            )

        case .identityConflict:
            return AttachmentPresentation(
                systemImage: "exclamationmark.triangle",
                title: "Attachment unavailable",
                detail: "Lumen can’t safely determine the retained attachment for this record."
            )
        }
    }

    private func refreshEvidenceAvailability() {
        do {
            evidenceResolution = try EvidenceAvailabilityResolver
                .live()
                .resolve(
                    source: transaction.source,
                    in: modelContext
                )
            evidenceResolutionFailed = false
        } catch {
            evidenceResolution = nil
            evidenceResolutionFailed = true
        }
    }

    private struct AttachmentPresentation {
        let systemImage: String
        let title: String
        let detail: String
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
