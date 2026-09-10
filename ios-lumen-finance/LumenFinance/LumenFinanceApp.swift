import SwiftUI
import SwiftData

@main
struct LumenFinanceApp: App {
    @State private var appState: AppState = AppState()
    @State private var flags: FeatureFlags = FeatureFlags()
    @State private var container: ModelContainer?
    @State private var didFailToOpen: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    RootView()
                        .modelContainer(container)
                        .environment(appState)
                        .environment(flags)
                } else if didFailToOpen {
                    ContentUnavailableView {
                        Label("Your ledger couldn’t open", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text("Lumen hasn’t replaced or reset your ledger. Free up device storage if needed, then retry. Do not delete the app to recover your data.")
                    } actions: {
                        Button("Retry opening ledger") { openLedger() }
                    }
                } else {
                    ProgressView("Opening your local ledger…")
                }
            }
            .tint(Theme.accent)
            .task { if container == nil && !didFailToOpen { openLedger() } }
        }
    }

    private func openLedger() {
        do {
            let opened = try LedgerStore.open()
            try Seed.bootstrapIfNeeded(opened.mainContext)
            container = opened
            didFailToOpen = false
        } catch {
            // Do not expose file paths or private financial content in errors.
            didFailToOpen = true
        }
    }
}
