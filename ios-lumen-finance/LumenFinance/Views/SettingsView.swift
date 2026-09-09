//
//  SettingsView.swift
//  LumenFinance
//
//  Preferences, privacy posture, export stub, and a debug feature-flag
//  panel gated by enableDebugDataPanel.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(FeatureFlags.self) private var flags
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]

    @State private var showExport = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY"]
    private let timezones = ["America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles", "Europe/London", "UTC"]

    var body: some View {
        @Bindable var appState = appState
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.s4) {
                    preferencesCard
                    privacyCard
                    if flags.enableExportStub { exportCard }
                    if flags.enableDebugDataPanel { debugCard }
                    footer
                    Color.clear.frame(height: 96)
                }
                .padding(.horizontal, Theme.s5)
                .padding(.top, Theme.s2)
            }
            .background(Theme.canvas)
            .scrollIndicators(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showExport) { ExportStubView(count: transactions.count) }
        }
    }

    private var preferencesCard: some View {
        FormCard(title: "Preferences") {
            menuRow(label: "Default currency", value: appState.currencyCode) {
                ForEach(currencies, id: \.self) { c in Button(c) { appState.currencyCode = c } }
            }
            Divider().background(Theme.hairline)
            menuRow(label: "Timezone", value: shortTimezone(appState.timezoneIdentifier)) {
                ForEach(timezones, id: \.self) { tz in Button(tz) { appState.timezoneIdentifier = tz } }
            }
        }
    }

    private var privacyCard: some View {
        FormCard(title: "Privacy") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local-first mode").font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.ink)
                    Text("Data stays on this device.").font(.system(size: 12)).foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                SoftTag(text: "On", tint: Theme.income)
            }
            Divider().background(Theme.hairline)
            HStack(alignment: .top, spacing: Theme.s2) {
                Image(systemName: "lock.shield").foregroundStyle(Theme.accent)
                Text("Your data is structured so it can be exported.")
                    .font(.system(size: 13)).foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    private var exportCard: some View {
        Button { showExport = true } label: {
            FormCard(title: "Your data") {
                HStack(spacing: Theme.s3) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18)).foregroundStyle(Theme.accent)
                        .frame(width: 44, height: 44).background(Theme.accentSoft).clipShape(.rect(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export data").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                        Text("\(transactions.count) transactions ready to export").font(.system(size: 12)).foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    SoftTag(text: "Preview", tint: Theme.pending)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }

    private var debugCard: some View {
        FormCard(title: "Feature flags · debug") {
            ForEach(flags.all, id: \.0) { item in
                Toggle(isOn: flags.binding(for: item.0)) {
                    Text(item.0).font(.system(size: 13, design: .monospaced)).foregroundStyle(Theme.inkSecondary)
                }
                .tint(Theme.accent)
            }
            Divider().background(Theme.hairline)
            Button(role: .destructive) { resetData() } label: {
                Label("Reset & reseed sample data", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.expense)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Lumen").font(.system(size: 15, weight: .semibold, design: .serif)).foregroundStyle(Theme.ink)
            Text("Financial awareness, not restriction.").font(.system(size: 12)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.s4)
    }

    private func menuRow<Content: View>(label: String, value: String, @ViewBuilder menu: () -> Content) -> some View {
        Menu { menu() } label: {
            HStack {
                Text(label).font(.system(size: 15)).foregroundStyle(Theme.ink)
                Spacer()
                Text(value).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.accent)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundStyle(Theme.muted)
            }
        }
    }

    private func shortTimezone(_ id: String) -> String {
        id.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? id
    }

    private func resetData() {
        for txn in transactions { modelContext.delete(txn) }
        try? modelContext.delete(model: Category.self)
        try? modelContext.delete(model: PaymentMethod.self)
        try? modelContext.delete(model: Tag.self)
        try? modelContext.delete(model: TransactionSource.self)
        try? modelContext.save()
        Seed.bootstrapIfNeeded(modelContext)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Export stub

struct ExportStubView: View {
    @Environment(\.dismiss) private var dismiss
    let count: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.s4) {
                    StubBanner(
                        title: "Export preview",
                        message: "Your data is already structured for export. File generation lands in a later phase.",
                        icon: "square.and.arrow.up"
                    )
                    FormCard(title: "Export formats") {
                        formatRow("JSON", subtitle: "Full structured records", icon: "curlybraces")
                        Divider().background(Theme.hairline)
                        formatRow("CSV", subtitle: "Spreadsheet-friendly rows", icon: "tablecells")
                    }
                    FormCard(title: "Summary") {
                        DetailRow(label: "Transactions", value: "\(count)")
                        DetailRow(label: "Schema", value: "Supabase-ready")
                        DetailRow(label: "Destination", value: "On-device")
                    }
                }
                .padding(.horizontal, Theme.s5)
                .padding(.top, Theme.s3)
            }
            .background(Theme.canvas)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.semibold) }
            }
        }
    }

    private func formatRow(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: Theme.s3) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40).background(Theme.accentSoft).clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                Text(subtitle).font(.system(size: 12)).foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            SoftTag(text: "Soon", tint: Theme.pending)
        }
    }
}
