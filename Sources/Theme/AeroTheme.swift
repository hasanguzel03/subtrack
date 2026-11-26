import SwiftUI

// MARK: - Aero Background

struct AeroBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? darkColors : lightColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: colorScheme)
    }

    private var darkColors: [Color] {
        [
            Color(hex: 0x12071F),
            Color(hex: 0x240E40),
            Color(hex: 0x150826)
        ]
    }

    private var lightColors: [Color] {
        [
            Color(hex: 0xF3EEFA),
            Color(hex: 0xE4D7F5),
            Color(hex: 0xEDE5F8)
        ]
    }
}

// MARK: - Aero Card Modifier

struct AeroCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.15)
                            : Color.black.opacity(0.08),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func aeroCard() -> some View {
        modifier(AeroCardModifier())
    }
}

// MARK: - Color Hex Helper

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
