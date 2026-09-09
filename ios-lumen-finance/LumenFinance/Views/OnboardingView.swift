//
//  OnboardingView.swift
//  LumenFinance
//
//  Calm, optional-feeling welcome. One sentence of purpose plus three
//  gentle value cards. No long setup.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    private let values: [(icon: String, title: String, body: String)] = [
        ("square.and.pencil", "Manual logging", "Jot down what you spend in seconds — no bank login required."),
        ("camera.viewfinder", "Upload receipts", "Snap a screenshot or receipt and we'll draft the details for you."),
        ("checkmark.shield", "Review before saving", "Nothing is saved until you say so. Your data stays yours."),
    ]

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                Spacer(minLength: Theme.s8)

                VStack(spacing: Theme.s5) {
                    lantern
                        .scaleEffect(appeared ? 1 : 0.8)
                        .opacity(appeared ? 1 : 0)

                    VStack(spacing: Theme.s3) {
                        Text("Lumen")
                            .font(.system(size: 40, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("Track what you spend, understand your patterns, and keep your data yours.")
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.s6)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }

                Spacer(minLength: Theme.s6)

                VStack(spacing: Theme.s3) {
                    ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                        valueCard(value)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                    .delay(0.15 + Double(index) * 0.09),
                                value: appeared
                            )
                    }
                }
                .padding(.horizontal, Theme.s5)

                Spacer(minLength: Theme.s6)

                VStack(spacing: Theme.s3) {
                    PrimaryButton(title: "Get Started", icon: "arrow.right") {
                        let generator = UIImpactFeedbackGenerator(style: .soft)
                        generator.impactOccurred()
                        withAnimation { appState.hasOnboarded = true }
                    }
                    Text("No account needed. Everything stays on your device.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, Theme.s5)
                .padding(.bottom, Theme.s8)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Theme.canvas, Theme.accentSoft.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var lantern: some View {
        ZStack {
            Circle()
                .fill(Theme.accent.opacity(0.12))
                .frame(width: 110, height: 110)
            Circle()
                .fill(Theme.accent)
                .frame(width: 74, height: 74)
                .shadow(color: Theme.accent.opacity(0.4), radius: 18, x: 0, y: 8)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private func valueCard(_ value: (icon: String, title: String, body: String)) -> some View {
        HStack(spacing: Theme.s4) {
            CategoryGlyph(icon: value.icon, color: Theme.accent, size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(value.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(value.body)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .cardSurface()
    }
}
