//
//  InsightsView.swift
//  LumenFinance
//
//  Insights Lite — calm, derived-from-local-data summaries plus clearly
//  labeled placeholders for future radar & cashflow comparisons.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(AppState.self) private var appState
    @Environment(FeatureFlags.self) private var flags
    @Query private var transactions: [Transaction]

    private var summary: DashboardSummary { Analytics.summary(transactions, currency: appState.currencyCode) }
    private var categoryTotals: [CategoryTotal] {
        Analytics.categoryTotals(transactions.filter { Analytics.isInCurrentMonth($0.transaction_date) }, currency: appState.currencyCode)
    }
    private var maxCategory: Double { categoryTotals.first?.amount ?? 1 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.s5) {
                    statRow
                    Text("\(appState.currencyCode) only. Includes pending and legacy review-needed records; ignored and duplicate records are excluded. \(summary.excludedCurrencyCount) other-currency records and \(summary.invalidAmountCount) invalid amounts excluded. No currency conversion.")
                        .font(.footnote).foregroundStyle(Theme.inkSecondary)

                    SectionHeader(title: "Spending by category")
                    if categoryTotals.isEmpty {
                        EmptyStateView(icon: "chart.pie", title: "No spending yet", message: "Log a few transactions to see your patterns.")
                            .cardSurface()
                    } else {
                        categoryCard
                    }

                    if flags.enableCashflowPhasesStub { radarPlaceholder }
                    if flags.enableBudgetsStub { cashflowComparePlaceholder }

                    Color.clear.frame(height: 96)
                }
                .padding(.horizontal, Theme.s5)
                .padding(.top, Theme.s2)
            }
            .background(Theme.canvas)
            .scrollIndicators(.hidden)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var statRow: some View {
        HStack(spacing: Theme.s3) {
            insightStat(value: appState.format(summary.loggedThisWeek), label: "Expenses dated this week", tint: Theme.accent)
            insightStat(value: "\(summary.countThisWeek)", label: "Transactions", tint: Theme.info)
        }
    }

    private func insightStat(value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.system(size: 12)).foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.s4)
        .background(tint.opacity(0.10))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var categoryCard: some View {
        VStack(spacing: Theme.s4) {
            ForEach(categoryTotals) { total in
                VStack(spacing: 6) {
                    HStack {
                        Circle().fill(Color(hex: total.color)).frame(width: 10, height: 10)
                        Text(total.name).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(total.count)").font(.system(size: 12)).foregroundStyle(Theme.muted)
                        Text(appState.format(total.amount))
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink).monospacedDigit()
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.canvasDeep)
                            Capsule().fill(Color(hex: total.color))
                                .frame(width: max(6, geo.size.width * (total.amount / maxCategory)))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .cardSurface()
    }

    private var radarPlaceholder: some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            HStack {
                Text("Spending shape").font(.system(size: 16, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
                Spacer()
                SoftTag(text: "Radar soon", tint: Theme.pending)
            }
            RadarPreview(values: Analytics.groupTotals(transactions, currency: appState.currencyCode))
                .frame(height: 200)
            Text("A radar view of where your money flows across life areas. Coming in a later update.")
                .font(.system(size: 12)).foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var cashflowComparePlaceholder: some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            HStack {
                Text("Cashflow phase comparison").font(.system(size: 16, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
                Spacer()
                SoftTag(text: "Preview", tint: Theme.pending)
            }
            StubBanner(title: "Compare your phases over time", message: "See how this month compares to your typical rhythm. Arrives with budgets.", icon: "chart.bar.xaxis")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

/// Lightweight radar/spider chart preview drawn from group totals.
struct RadarPreview: View {
    let values: [(group: CategoryGroup, amount: Double)]

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 24
            let maxVal = max(values.map { $0.amount }.max() ?? 1, 1)
            let count = max(values.count, 3)

            ZStack {
                ForEach(1...3, id: \.self) { ring in
                    polygon(center: center, radius: radius * CGFloat(ring) / 3, count: count)
                        .stroke(Theme.hairline, lineWidth: 1)
                }
                dataPath(center: center, radius: radius, maxVal: maxVal, count: count)
                    .fill(Theme.accent.opacity(0.18))
                dataPath(center: center, radius: radius, maxVal: maxVal, count: count)
                    .stroke(Theme.accent, lineWidth: 2)
            }
        }
    }

    private func point(center: CGPoint, radius: CGFloat, index: Int, count: Int) -> CGPoint {
        let angle = (Double(index) / Double(count)) * 2 * .pi - .pi / 2
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

    private func polygon(center: CGPoint, radius: CGFloat, count: Int) -> Path {
        var path = Path()
        for i in 0..<count {
            let p = point(center: center, radius: radius, index: i, count: count)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    private func dataPath(center: CGPoint, radius: CGFloat, maxVal: Double, count: Int) -> Path {
        var path = Path()
        for i in 0..<count {
            let value = i < values.count ? values[i].amount : 0
            let r = radius * CGFloat(max(0.05, value / maxVal))
            let p = point(center: center, radius: r, index: i, count: count)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}
