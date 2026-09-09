//
//  Theme.swift
//  LumenFinance
//
//  Calm, privacy-first design system. Warm paper canvas, sage ink,
//  editorial serif headings. Built to feel reflective, not restrictive.
//

import SwiftUI

extension Color {
    /// Create a color from a hex string like "#2F6B57" or "2F6B57".
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&value)
        let r, g, b, a: Double
        switch trimmed.count {
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

/// Centralized palette + spacing tokens so the whole app stays cohesive.
enum Theme {
    // Surfaces
    static let canvas = Color(hex: "#F4F1EA")        // warm paper
    static let canvasDeep = Color(hex: "#EDE8DD")    // recessed wells
    static let surface = Color(hex: "#FCFBF7")       // cards
    static let surfaceRaised = Color(hex: "#FFFFFF")

    // Ink
    static let ink = Color(hex: "#1F2E29")           // primary text
    static let inkSecondary = Color(hex: "#566660")  // secondary text
    static let muted = Color(hex: "#94A09A")         // tertiary/labels
    static let hairline = Color(hex: "#E6E0D4")      // separators

    // Brand
    static let accent = Color(hex: "#2F6B57")        // sage forest
    static let accentDeep = Color(hex: "#234F40")
    static let accentSoft = Color(hex: "#DEEAE2")    // tint backgrounds

    // Semantic
    static let expense = Color(hex: "#B65C3C")       // terracotta
    static let expenseSoft = Color(hex: "#F2E0D6")
    static let income = Color(hex: "#2F6B57")
    static let incomeSoft = Color(hex: "#DEEAE2")
    static let pending = Color(hex: "#C2943A")       // amber
    static let pendingSoft = Color(hex: "#F3E8CC")
    static let neutral = Color(hex: "#8A938F")
    static let neutralSoft = Color(hex: "#E9E4DA")
    static let info = Color(hex: "#3E6E8E")
    static let infoSoft = Color(hex: "#DCE7EE")

    // Spacing scale
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40

    static let cardRadius: CGFloat = 22
    static let chipRadius: CGFloat = 12
}

extension Font {
    /// Editorial serif display for headline amounts & screen titles.
    static func serifDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

extension View {
    /// Standard soft card container used across the app.
    func cardSurface(padding: CGFloat = Theme.s5, radius: CGFloat = Theme.cardRadius) -> some View {
        self
            .padding(padding)
            .background(Theme.surface)
            .clipShape(.rect(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 8)
    }
}
