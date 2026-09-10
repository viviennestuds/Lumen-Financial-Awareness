//
//  TransactionForm.swift
//  LumenFinance
//
//  A shared editable draft + reusable form fields. Used by Manual Entry,
//  Review (pre-save), and the Detail editor so behavior stays consistent.
//

import SwiftUI

@Observable
final class TransactionDraft {
    var transaction_type: TransactionType = .expense
    var amountText: String = ""
    var currency: String = "USD"
    var merchant_name: String = ""
    var transaction_date: Date = .now
    var posted_date: Date? = nil
    var status: TransactionStatus = .pending
    var category: Category? = nil
    var payment_method: PaymentMethod? = nil
    var notes: String = ""
    var tagIDs: Set<String> = []

    // Source / parse context (used in Review for uploads).
    var source: TransactionSource? = nil
    var confidence_score: Double? = nil

    private(set) var isEditingExisting: Bool = false
    private var originalAmount: Double?
    private var originalAmountText: String?

    var amount: Double {
        if amountText == originalAmountText, let originalAmount { return originalAmount }
        return Double(amountText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var isValid: Bool {
        amount.isFinite && amount > 0 && Money.magnitude(amount) != nil
            && Locale.commonISOCurrencyCodes.contains(currency)
            && !merchant_name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && category != nil
    }

    var canConfirm: Bool { isValid && (status == .pending || status == .posted) }
    var availableStatuses: [TransactionStatus] {
        isEditingExisting ? TransactionStatus.allCases : [.pending, .posted]
    }

    init() {}

    /// Build a draft from an existing transaction (for editing).
    init(from txn: Transaction) {
        transaction_type = txn.transaction_type
        isEditingExisting = true
        amountText = String(txn.amount)
        originalAmount = txn.amount
        originalAmountText = amountText
        currency = txn.currency
        merchant_name = txn.merchant_name
        transaction_date = txn.transaction_date
        posted_date = txn.posted_date
        status = txn.status
        category = txn.category
        payment_method = txn.payment_method
        notes = txn.notes ?? ""
        tagIDs = Set(txn.tags.map(\.id))
        source = txn.source
        confidence_score = txn.confidence_score
    }

    /// Call only inside the confirmed write boundary: relationships may attach to a context.
    func makeTransaction(allTags: [Tag]) throws -> Transaction {
        guard canConfirm else { throw LedgerWriteError.invalidDraft }
        return Transaction(
            amount: abs(amount),
            currency: currency,
            transaction_type: transaction_type,
            merchant_name: merchant_name.trimmingCharacters(in: .whitespacesAndNewlines),
            transaction_date: transaction_date,
            posted_date: status == .posted ? (posted_date ?? .now) : posted_date,
            status: status,
            notes: notes.isEmpty ? nil : notes,
            confidence_score: nil,
            source: confirmationSource(),
            category: category,
            payment_method: payment_method,
            tags: allTags.filter { tagIDs.contains($0.id) }
        )
    }

    /// Copy transient upload metadata so a failed insert/rollback never invalidates the draft's source.
    private func confirmationSource() -> TransactionSource? {
        guard let source else { return nil }
        return TransactionSource(
            id: source.id, source_type: source.source_type,
            original_filename: source.original_filename, stored_file_uri: source.stored_file_uri,
            compressed_file_uri: source.compressed_file_uri, file_size_bytes: source.file_size_bytes,
            mime_type: source.mime_type, uploaded_at: source.uploaded_at, captured_at: source.captured_at,
            source_timezone: source.source_timezone, metadata_json: source.metadata_json,
            raw_extracted_text: source.raw_extracted_text, parse_status: source.parse_status,
            source_hash: source.source_hash, created_at: source.created_at
        )
    }

    func apply(to txn: Transaction, allTags: [Tag]) throws {
        guard isValid else { throw LedgerWriteError.invalidDraft }
        txn.transaction_type = transaction_type
        txn.amount = abs(amount)
        txn.currency = currency
        txn.merchant_name = merchant_name.trimmingCharacters(in: .whitespacesAndNewlines)
        txn.transaction_date = transaction_date
        txn.posted_date = status == .posted && txn.status != .posted ? (posted_date ?? .now) : posted_date
        txn.status = status
        txn.category = category
        txn.payment_method = payment_method
        txn.notes = notes.isEmpty ? nil : notes
        txn.tags = allTags.filter { tagIDs.contains($0.id) }
        txn.updated_at = .now
    }
}

// MARK: - Reusable field building blocks

struct FormCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Theme.muted)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

struct TransactionFormFields: View {
    @Bindable var draft: TransactionDraft
    let categories: [Category]
    let paymentMethods: [PaymentMethod]
    let tags: [Tag]
    @FocusState private var focusedField: String?

    var body: some View {
        VStack(spacing: Theme.s4) {
            typeAndAmount
            detailsCard
            classificationCard
            tagsCard
            notesCard
            if !draft.isValid {
                Text("Enter a positive finite amount, a currency, a merchant, and a category. Use a decimal separator, not thousands separators.")
                    .font(.footnote).foregroundStyle(Theme.inkSecondary)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    private var typeAndAmount: some View {
        FormCard(title: "Amount") {
            HStack(spacing: Theme.s2) {
                ForEach(TransactionType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            draft.transaction_type = type
                        }
                    } label: {
                        Text(type.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(draft.transaction_type == type ? .white : Theme.inkSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(draft.transaction_type == type ? type.tint : Theme.canvasDeep)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                    .buttonStyle(PressableStyle())
                }
            }

            HStack(spacing: Theme.s2) {
                Text(draft.currency == "USD" ? "$" : draft.currency)
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.inkSecondary)
                TextField("0.00", text: $draft.amountText)
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: "amount")
                    .accessibilityLabel("Amount")
                    .accessibilityIdentifier("transactionAmount")
            }
            .padding(.top, 4)
        }
    }

    private var detailsCard: some View {
        FormCard(title: "Details") {
            labeledField("Merchant / source") {
                TextField("e.g. DoorDash", text: $draft.merchant_name)
                    .font(.system(size: 16))
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: "merchant")
                    .accessibilityIdentifier("transactionMerchant")
            }
            Divider().background(Theme.hairline)
            DatePicker("Transaction date", selection: $draft.transaction_date, displayedComponents: .date)
                .font(.system(size: 15))
                .tint(Theme.accent)
            Divider().background(Theme.hairline)
            HStack {
                Text("Posted date")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if draft.posted_date != nil {
                    DatePicker("", selection: Binding(
                        get: { draft.posted_date ?? .now },
                        set: { draft.posted_date = $0 }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .tint(Theme.accent)
                    Button { draft.posted_date = nil } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.muted)
                    }
                } else {
                    Button("Add") { draft.posted_date = .now }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private var classificationCard: some View {
        FormCard(title: "Classification") {
            pickerRow(label: "Currency", value: draft.currency, tint: Theme.inkSecondary) {
                ForEach(["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "KWD"], id: \.self) { currency in
                    Button(currency) { draft.currency = currency }
                }
            }
            Divider().background(Theme.hairline)
            pickerRow(label: "Status", value: draft.status.label, tint: draft.status.tint) {
                ForEach(draft.availableStatuses) { s in
                    Button(s.label) { draft.status = s }
                }
            }
            Divider().background(Theme.hairline)
            pickerRow(label: "Category", value: draft.category?.name ?? "Choose", tint: draft.category?.tint ?? Theme.muted) {
                ForEach(CategoryGroup.allCases) { group in
                    let groupCats = categories.filter { $0.group == group }
                    if !groupCats.isEmpty {
                        Section(group.label) {
                            ForEach(groupCats) { c in
                                Button(c.name) { draft.category = c }
                            }
                        }
                    }
                }
            }
            Divider().background(Theme.hairline)
            pickerRow(label: "Payment method", value: draft.payment_method?.name ?? "Choose", tint: Theme.inkSecondary) {
                Button("None") { draft.payment_method = nil }
                ForEach(paymentMethods) { pm in
                    Button(pm.name) { draft.payment_method = pm }
                }
            }
        }
    }

    private var tagsCard: some View {
        FormCard(title: "Tags") {
            if tags.isEmpty {
                Text("No tags yet.").font(.system(size: 14)).foregroundStyle(Theme.muted)
            } else {
                FlowLayout(spacing: Theme.s2) {
                    ForEach(tags) { tag in
                        let selected = draft.tagIDs.contains(tag.id)
                        Button {
                            if selected { draft.tagIDs.remove(tag.id) } else { draft.tagIDs.insert(tag.id) }
                        } label: {
                            Text("#\(tag.name)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(selected ? .white : tag.tint)
                                .padding(.horizontal, Theme.s3)
                                .padding(.vertical, 7)
                                .background(selected ? tag.tint : tag.tint.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
    }

    private var notesCard: some View {
        FormCard(title: "Notes") {
            TextField("Add a gentle note for context…", text: $draft.notes, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(2...5)
                .focused($focusedField, equals: "notes")
        }
    }

    // MARK: helpers

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 13)).foregroundStyle(Theme.inkSecondary)
            content()
        }
    }

    private func pickerRow<MenuContent: View>(
        label: String, value: String, tint: Color,
        @ViewBuilder menu: () -> MenuContent
    ) -> some View {
        Menu {
            menu()
        } label: {
            HStack {
                Text(label).font(.system(size: 15)).foregroundStyle(Theme.ink)
                Spacer()
                Text(value).font(.system(size: 15, weight: .medium)).foregroundStyle(tint)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundStyle(Theme.muted)
            }
        }
    }
}

// MARK: - Simple flow layout for tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [CGFloat] = [0]
        var rowHeights: [CGFloat] = [0]
        var x: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                rows.append(0); rowHeights.append(0); x = 0
            }
            x += size.width + spacing
            rows[rows.count - 1] = x
            rowHeights[rowHeights.count - 1] = max(rowHeights[rowHeights.count - 1], size.height)
        }
        let totalHeight = rowHeights.reduce(0, +) + spacing * CGFloat(max(0, rowHeights.count - 1))
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
