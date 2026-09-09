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

    var amount: Double { Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var isValid: Bool {
        amount > 0 && !merchant_name.trimmingCharacters(in: .whitespaces).isEmpty && category != nil
    }

    init() {}

    /// Build a draft from an existing transaction (for editing).
    init(from txn: Transaction) {
        transaction_type = txn.transaction_type
        amountText = String(format: "%.2f", txn.amount)
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

    func makeTransaction(allTags: [Tag]) -> Transaction {
        Transaction(
            amount: abs(amount),
            currency: currency,
            transaction_type: transaction_type,
            merchant_name: merchant_name.trimmingCharacters(in: .whitespaces),
            transaction_date: transaction_date,
            posted_date: status == .posted ? (posted_date ?? .now) : posted_date,
            status: status,
            notes: notes.isEmpty ? nil : notes,
            confidence_score: confidence_score,
            source: source,
            category: category,
            payment_method: payment_method,
            tags: allTags.filter { tagIDs.contains($0.id) }
        )
    }

    func apply(to txn: Transaction, allTags: [Tag]) {
        txn.transaction_type = transaction_type
        txn.amount = abs(amount)
        txn.currency = currency
        txn.merchant_name = merchant_name.trimmingCharacters(in: .whitespaces)
        txn.transaction_date = transaction_date
        txn.posted_date = status == .posted ? (posted_date ?? .now) : posted_date
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

    var body: some View {
        VStack(spacing: Theme.s4) {
            typeAndAmount
            detailsCard
            classificationCard
            tagsCard
            notesCard
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
            pickerRow(label: "Status", value: draft.status.label, tint: draft.status.tint) {
                ForEach(TransactionStatus.allCases) { s in
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
