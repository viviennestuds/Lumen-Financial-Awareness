//
//  RootView.swift
//  LumenFinance
//
//  Hosts onboarding gating, the four primary tabs, and the custom
//  bottom bar with a centered primary Upload action.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(FeatureFlags.self) private var flags
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            Theme.canvas.ignoresSafeArea()

            if flags.enableOnboarding && !appState.hasOnboarded {
                OnboardingView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                mainShell
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: appState.hasOnboarded)
        .sheet(isPresented: $appState.showUpload) {
            UploadView()
        }
    }

    private var mainShell: some View {
        @Bindable var appState = appState
        return ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .dashboard: DashboardView()
                case .transactions: TransactionsView()
                case .insights: InsightsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            LumenTabBar(
                selected: $appState.selectedTab,
                onUpload: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    appState.showUpload = true
                }
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom tab bar

struct LumenTabBar: View {
    @Binding var selected: AppTab
    let onUpload: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.dashboard, icon: "square.grid.2x2", label: "Home")
            tabButton(.transactions, icon: "list.bullet.rectangle", label: "Activity")

            uploadButton

            tabButton(.insights, icon: "chart.pie", label: "Insights")
            tabButton(.settings, icon: "gearshape", label: "Settings")
        }
        .padding(.horizontal, Theme.s4)
        .padding(.top, Theme.s3)
        .padding(.bottom, Theme.s2)
        .background(
            Theme.surfaceRaised
                .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: -6)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
                .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
        }
    }

    private func tabButton(_ tab: AppTab, icon: String, label: String) -> some View {
        Button {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: selected == tab ? .semibold : .regular))
                    .symbolVariant(selected == tab ? .fill : .none)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selected == tab ? Theme.accent : Theme.muted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var uploadButton: some View {
        Button(action: onUpload) {
            ZStack {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 58, height: 58)
                    .shadow(color: Theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .offset(y: -14)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Add activity")
        .accessibilityIdentifier("addActivity")
        .frame(maxWidth: .infinity)
    }
}
