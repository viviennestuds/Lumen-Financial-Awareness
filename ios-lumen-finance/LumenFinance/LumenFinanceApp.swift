//
//  LumenFinanceApp.swift
//  LumenFinance
//

import SwiftUI
import SwiftData

@main
struct LumenFinanceApp: App {
    @State private var appState = AppState()
    @State private var flags = FeatureFlags()

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            TransactionSource.self,
            Category.self,
            PaymentMethod.self,
            Tag.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fall back to an in-memory store so the app still launches.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(flags)
                .tint(Theme.accent)
        }
        .modelContainer(sharedModelContainer)
    }
}
