//
//  TransactionsView.swift
//  LumenFinance
//
//  Searchable, filterable list of all transactions. Tapping a row
//  opens the inspect/edit detail screen.
//

import SwiftUI
import SwiftData

enum TxnFilter: String, CaseIterable, Identifiable {
    case all, expenses, income, pending, posted, ignored
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "All"
        case .expenses: return "Expenses"
        case .income: return "Income"
        case .pending: return "Pending"
        case .posted: return "Posted"
        case .ignored: return "Ignored"
        }
    }
}

struct TransactionsView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Transaction.transaction_date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var search = ""
    @State private var filter: TxnFilter = .all
    @State private var categoryFilter: String? = nil
    @State private var sourceFilter: SourceType? = nil

    private var filtered: [Transaction] {
        transactions.filter { txn in
            switch filter {
            case .all: break
            case .expenses: if txn.transaction_type != .expense { return false }
            case .income: if !(txn.transaction_type == .income || txn.transaction_type == .refund) { return false }
            case .pending: if txn.status != .pending { return false }
            case .posted: if txn.status != .posted { return false }
            case .ignored: if txn.status != .ignored { return false }
            }
            if let categoryFilter, txn.category?.name != categoryFilter { return false }
            if let sourceFilter, txn.source?.source_type != sourceFilter { return false }
            if !search.isEmpty {
                let hay = "\(txn.merchant_name) \(txn.category?.name ?? "") \(txn.notes ?? "")"
                if !hay.localizedStandardContains(search) { return false }
            }
            return true
        }
    }

    private var grouped: [(date: Date, items: [Transaction])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.transaction_date) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.s4) {
                    searchField
                    filterRow
                    facetRow

                    if filtered.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No transactions found",
                            message: "Try a different filter or log something new."
                        )
                        .cardSurface()
                    } else {
                        ForEach(grouped, id: \.date) { group in
                            dayGroup(group.date, group.items)
                        }
                    }

                    Color.clear.frame(height: 96)
                }
                .padding(.horizontal, Theme.s5)
                .padding(.top, Theme.s2)
            }
            .background(Theme.canvas)
            .scrollIndicators(.hidden)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Transaction.self) { txn in
                TransactionDetailView(transaction: txn)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: Theme.s2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.muted)
            TextField("Search merchant, category, notes", text: $search)
                .font(.system(size: 15))
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.muted)
                }
            }
        }
        .padding(.horizontal, Theme.s4)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.s2) {
                ForEach(TxnFilter.allCases) { f in
                    chip(title: f.label, selected: filter == f) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { filter = f }
                    }
                }
            }
        }
        .contentMargins(.horizontal, Theme.s5)
        .padding(.horizontal, -Theme.s5)
    }

    private var facetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.s2) {
                Menu {
                    Button("All categories") { categoryFilter = nil }
                    Divider()
                    ForEach(categories) { c in
                        Button(c.name) { categoryFilter = c.name }
                    }
                } label: {
                    facetChip(icon: "square.grid.2x2", text: categoryFilter ?? "Category", active: categoryFilter != nil)
                }

                Menu {
                    Button("All sources") { sourceFilter = nil }
                    Divider()
                    ForEach(SourceType.allCases) { s in
                        Button(s.label) { sourceFilter = s }
                    }
                } label: {
                    facetChip(icon: "tray.and.arrow.down", text: sourceFilter?.label ?? "Source", active: sourceFilter != nil)
                }

                if categoryFilter != nil || sourceFilter != nil {
                    Button {
                        categoryFilter = nil; sourceFilter = nil
                    } label: {
                        facetChip(icon: "xmark", text: "Clear", active: false)
                    }
                }
            }
        }
        .contentMargins(.horizontal, Theme.s5)
        .padding(.horizontal, -Theme.s5)
    }

    private func chip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(selected ? .white : Theme.inkSecondary)
                .padding(.horizontal, Theme.s4)
                .padding(.vertical, 9)
                .background(selected ? Theme.accent : Theme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(selected ? .clear : Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private func facetChip(icon: String, text: String, active: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            Text(text).font(.system(size: 14, weight: .medium)).lineLimit(1)
        }
        .foregroundStyle(active ? Theme.accent : Theme.inkSecondary)
        .padding(.horizontal, Theme.s3)
        .padding(.vertical, 9)
        .background(active ? Theme.accentSoft : Theme.surface)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(active ? .clear : Theme.hairline, lineWidth: 1))
    }

    private func dayGroup(_ date: Date, _ items: [Transaction]) -> some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            Text(dayLabel(date))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .padding(.leading, Theme.s1)

            VStack(spacing: 0) {
                ForEach(items) { txn in
                    NavigationLink(value: txn) {
                        TransactionRow(txn: txn).padding(.vertical, Theme.s2)
                    }
                    .buttonStyle(PressableStyle())
                    if txn.id != items.last?.id {
                        Divider().background(Theme.hairline).padding(.leading, 58)
                    }
                }
            }
            .cardSurface(padding: Theme.s3)
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}
