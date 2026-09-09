//
//  AppState.swift
//  LumenFinance
//
//  Lightweight UI state: selected tab, onboarding completion, and the
//  active currency used for formatting. Persisted preferences live in
//  UserDefaults; transactional data lives in SwiftData.
//

import SwiftUI
import Observation

enum AppTab: Int, CaseIterable {
    case dashboard
    case transactions
    case insights
    case settings
}

@Observable
final class AppState {
    var selectedTab: AppTab = .dashboard
    var showUpload: Bool = false

    var hasOnboarded: Bool {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: "lumen_has_onboarded") }
    }

    var currencyCode: String {
        didSet { UserDefaults.standard.set(currencyCode, forKey: "lumen_currency") }
    }

    var timezoneIdentifier: String {
        didSet { UserDefaults.standard.set(timezoneIdentifier, forKey: "lumen_timezone") }
    }

    init() {
        self.hasOnboarded = UserDefaults.standard.bool(forKey: "lumen_has_onboarded")
        self.currencyCode = UserDefaults.standard.string(forKey: "lumen_currency") ?? "USD"
        self.timezoneIdentifier = UserDefaults.standard.string(forKey: "lumen_timezone")
            ?? TimeZone.current.identifier
    }

    func format(_ amount: Double, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        let value = signed ? amount : abs(amount)
        let base = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        if signed && amount > 0 { return "+\(base)" }
        return base
    }
}
