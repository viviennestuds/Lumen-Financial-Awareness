//
//  ManualEntryView.swift
//  LumenFinance
//
//  Full manual transaction entry. On continue, routes to Review before
//  anything is persisted.
//

import SwiftUI
import SwiftData

struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \PaymentMethod.name) private var paymentMethods: [PaymentMethod]
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var draft = TransactionDraft()
    @State private var goReview = false
    @State private var didInitialize: Bool = false

    /// Optional dismissal hook so parent flows can close the whole stack on save.
    var onSaved: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.s4) {
                TransactionFormFields(
                    draft: draft,
                    categories: categories,
                    paymentMethods: paymentMethods,
                    tags: tags
                )
                Color.clear.frame(height: 80)
            }
            .padding(.horizontal, Theme.s5)
            .padding(.top, Theme.s3)
        }
        .background(Theme.canvas)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Manual Entry")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Review transaction", icon: "arrow.right") {
                goReview = true
            }
            .disabled(!draft.isValid)
            .opacity(draft.isValid ? 1 : 0.5)
            .padding(.horizontal, Theme.s5)
            .padding(.vertical, Theme.s3)
            .background(.ultraThinMaterial)
        }
        .navigationDestination(isPresented: $goReview) {
            ReviewTransactionView(draft: draft) {
                onSaved?()
                dismiss()
            }
        }
        .onAppear {
            if !didInitialize {
                draft.currency = appState.currencyCode
                didInitialize = true
            }
            if draft.category == nil {
                draft.category = categories.first { $0.group == .guilt_free_spending }
            }
        }
    }
}
