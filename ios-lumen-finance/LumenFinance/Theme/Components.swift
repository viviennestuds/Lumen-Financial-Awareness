//
//  Components.swift
//  LumenFinance
//
//  Reusable presentational building blocks used across screens.
//

import SwiftUI

// MARK: - Status / type badges

struct StatusBadge: View {
    let status: TransactionStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbol)
                .font(.system(size: 10, weight: .semibold))
            Text(status.label)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(status.tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(status.softTint)
        .clipShape(.rect(cornerRadius: 8))
    }
}

struct SoftTag: View {
    let text: String
    var tint: Color = Theme.accent

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .clipShape(.rect(cornerRadius: 8))
    }
}

// MARK: - Category glyph

struct CategoryGlyph: View {
    let icon: String
    let color: Color
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.14))
            .clipShape(.rect(cornerRadius: size * 0.32))
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)?
    var actionLabel: String = "See all"

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Spacer()
            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Preview / stub banner

struct StubBanner: View {
    let title: String
    var message: String = "Preview stub — fully wired in a later phase."
    var icon: String = "hammer"

    var body: some View {
        HStack(spacing: Theme.s3) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.pending)
                .frame(width: 34, height: 34)
                .background(Theme.pendingSoft)
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.pendingSoft.opacity(0.4))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.pending.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
    }
}

// MARK: - Primary button

struct PrimaryButton: View {
    let title: String
    var icon: String?
    var fill: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                }
                Text(title).font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(fill ? Color.white : Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(fill ? Theme.accent : Theme.accentSoft)
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(PressableStyle())
    }
}

/// Subtle press scale + haptic feel for interactive surfaces.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Key/value row used in detail screens

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.ink
    var mono: Bool = false

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
            Spacer(minLength: Theme.s4)
            Text(value)
                .font(.system(size: 14, weight: .medium, design: mono ? .monospaced : .default))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.s3) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.muted)
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.s10)
    }
}
