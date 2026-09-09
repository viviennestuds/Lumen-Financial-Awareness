//
//  FeatureFlags.swift
//  LumenFinance
//
//  Central gate for partial / future features. Stubbed surfaces read
//  these flags so they can show clear "preview" states instead of
//  breaking. Debug panel in Settings can toggle them at runtime.
//

import SwiftUI
import Observation

@Observable
final class FeatureFlags {
    var enableOnboarding: Bool = true
    var enableUploadFlow: Bool = true
    var enableOCRStub: Bool = true
    var enableManualEntry: Bool = true
    var enableCSVJSONImportStub: Bool = true
    var enableInsightsLite: Bool = true
    var enableBudgetsStub: Bool = true
    var enableCashflowPhasesStub: Bool = true
    var enableTransactionDetail: Bool = true
    var enableExportStub: Bool = true
    var enableReceiptItemizationStub: Bool = true
    var enableDebugDataPanel: Bool = true

    /// Ordered list for rendering the debug toggle panel.
    var all: [(String, Bool)] {
        [
            ("enableOnboarding", enableOnboarding),
            ("enableUploadFlow", enableUploadFlow),
            ("enableOCRStub", enableOCRStub),
            ("enableManualEntry", enableManualEntry),
            ("enableCSVJSONImportStub", enableCSVJSONImportStub),
            ("enableInsightsLite", enableInsightsLite),
            ("enableBudgetsStub", enableBudgetsStub),
            ("enableCashflowPhasesStub", enableCashflowPhasesStub),
            ("enableTransactionDetail", enableTransactionDetail),
            ("enableExportStub", enableExportStub),
            ("enableReceiptItemizationStub", enableReceiptItemizationStub),
            ("enableDebugDataPanel", enableDebugDataPanel),
        ]
    }

    func binding(for key: String) -> Binding<Bool> {
        Binding(
            get: { self.value(for: key) },
            set: { self.set(key, $0) }
        )
    }

    private func value(for key: String) -> Bool {
        switch key {
        case "enableOnboarding": return enableOnboarding
        case "enableUploadFlow": return enableUploadFlow
        case "enableOCRStub": return enableOCRStub
        case "enableManualEntry": return enableManualEntry
        case "enableCSVJSONImportStub": return enableCSVJSONImportStub
        case "enableInsightsLite": return enableInsightsLite
        case "enableBudgetsStub": return enableBudgetsStub
        case "enableCashflowPhasesStub": return enableCashflowPhasesStub
        case "enableTransactionDetail": return enableTransactionDetail
        case "enableExportStub": return enableExportStub
        case "enableReceiptItemizationStub": return enableReceiptItemizationStub
        case "enableDebugDataPanel": return enableDebugDataPanel
        default: return false
        }
    }

    private func set(_ key: String, _ newValue: Bool) {
        switch key {
        case "enableOnboarding": enableOnboarding = newValue
        case "enableUploadFlow": enableUploadFlow = newValue
        case "enableOCRStub": enableOCRStub = newValue
        case "enableManualEntry": enableManualEntry = newValue
        case "enableCSVJSONImportStub": enableCSVJSONImportStub = newValue
        case "enableInsightsLite": enableInsightsLite = newValue
        case "enableBudgetsStub": enableBudgetsStub = newValue
        case "enableCashflowPhasesStub": enableCashflowPhasesStub = newValue
        case "enableTransactionDetail": enableTransactionDetail = newValue
        case "enableExportStub": enableExportStub = newValue
        case "enableReceiptItemizationStub": enableReceiptItemizationStub = newValue
        case "enableDebugDataPanel": enableDebugDataPanel = newValue
        default: break
        }
    }
}
