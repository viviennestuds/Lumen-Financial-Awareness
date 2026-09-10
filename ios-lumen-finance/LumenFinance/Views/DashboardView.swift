//
//  DashboardView.swift
//  LumenFinance
//
//  Calm monthly overview derived entirely from stored transactions.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(FeatureFlags.self) private var flags
    @Query(sort: \Transaction.transaction_date, order: .reverse) private var transactions: [Transaction]

    private var summary: DashboardSummary { Analytics.summary(transactions, currency: appState.currencyCode) }

    private var recent: [Transaction] {
        Array(Analytics.active(transactions).prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.s5) {
                header

                netFlowCard
                aggregateNote

                statRow

                insightCard

                cashflowPhaseCard

                recentSection

                Color.clear.frame(height: 96) // tab bar clearance
            }
            .padding(.horizontal, Theme.s5)
            .padding(.top, Theme.s3)
        }
        .background(Theme.canvas)
        .scrollIndicators(.hidden)
    }

    private var aggregateNote: some View {
        Text("\(appState.currencyCode) only · includes pending and legacy review-needed records. In includes refunds; transfers do not affect flow. \(summary.excludedCurrencyCount) other-currency records and \(summary.invalidAmountCount) invalid amounts excluded. Weeks use transaction dates.")
            .font(.footnote).foregroundStyle(Theme.inkSecondary)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greeting)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.muted)
            Text(monthTitle)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.s2)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: .now)
    }

    // MARK: - Net flow hero

    private var netFlowCard: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            HStack {
                Text("Net flow this month")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: summary.netFlow >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(.white.opacity(0.18))
                    .clipShape(Circle())
            }

            Text(appState.format(summary.netFlow, signed: true))
                .font(.system(size: 40, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())

            HStack(spacing: Theme.s5) {
                miniFlow(label: "In", amount: summary.totalIncome, up: true)
                Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 32)
                miniFlow(label: "Out", amount: summary.totalSpending, up: false)
            }
        }
        .padding(Theme.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Theme.accent, Theme.accentDeep],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.accent.opacity(0.25), radius: 18, x: 0, y: 10)
    }

    private func miniFlow(label: String, amount: Double, up: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
            Text(appState.format(amount))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }

    // MARK: - Stat row

    private var statRow: some View {
        HStack(spacing: Theme.s3) {
            statTile(
                value: "\(summary.countThisWeek)",
                label: "Dated this week",
                icon: "calendar",
                tint: Theme.info
            )
            statTile(
                value: summary.topCategoryName ?? "—",
                label: "Top category",
                icon: "chart.pie.fill",
                tint: Color(hex: summary.topCategoryColor),
                isText: true
            )
        }
    }

    private func statTile(value: String, label: String, icon: String, tint: Color, isText: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14))
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: isText ? 17 : 24, weight: .semibold, design: isText ? .default : .serif))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: Theme.s4)
    }

    // MARK: - Insight

    private var insightCard: some View {
        HStack(spacing: Theme.s4) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.pending)
                .frame(width: 44, height: 44)
                .background(Theme.pendingSoft)
                .clipShape(.rect(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text("This week's rhythm")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                Text("\(appState.format(summary.loggedThisWeek)) in expenses dated this week.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .cardSurface()
    }

    // MARK: - Cashflow phase placeholder

    @ViewBuilder
    private var cashflowPhaseCard: some View {
        if flags.enableCashflowPhasesStub {
            VStack(alignment: .leading, spacing: Theme.s3) {
                HStack {
                    Text("Cashflow phase")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    SoftTag(text: "Preview", tint: Theme.pending)
                }
                Text("Stabilizing")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.accent)
                Text("A reflective read on where your money is flowing. Phases arrive in a later update.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                phaseTrack
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
        }
    }

    private var phaseTrack: some View {
        let phases = ["Steadying", "Stabilizing", "Building", "Thriving"]
        return HStack(spacing: 6) {
            ForEach(Array(phases.enumerated()), id: \.offset) { index, name in
                Capsule()
                    .fill(index <= 1 ? Theme.accent : Theme.canvasDeep)
                    .frame(height: 6)
                    .overlay(alignment: .bottomLeading) {
                        if index == 1 {
                            Text(name)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                                .offset(y: 16)
                        }
                    }
            }
        }
        .padding(.top, 2)
        .padding(.bottom, 14)
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            SectionHeader(title: "Recent activity") {
                appState.selectedTab = .transactions
            }

            if recent.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "Nothing logged yet",
                    message: "Tap the + button to add your first transaction."
                )
                .cardSurface()
            } else {
                VStack(spacing: 0) {
                    ForEach(recent) { txn in
                        NavigationStackLink(txn: txn)
                        if txn.id != recent.last?.id {
                            Divider().background(Theme.hairline).padding(.leading, 58)
                        }
                    }
                }
                .cardSurface(padding: Theme.s3)
            }
        }
    }
}

/// Small wrapper that pushes a detail view from the dashboard list.
private struct NavigationStackLink: View {
    let txn: Transaction
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            TransactionRow(txn: txn)
                .padding(.vertical, Theme.s2)
        }
        .buttonStyle(PressableStyle())
        .sheet(isPresented: $showDetail) {
            NavigationStack { TransactionDetailView(transaction: txn) }
        }
    }
}
