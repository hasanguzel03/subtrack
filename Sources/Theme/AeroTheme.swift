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
    var verticalPadding: CGFloat = 16
    var horizontalPadding: CGFloat = 16

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        content
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    shape
                        .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.72 : 0.78))

                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.06 : 0.28),
                                    Color.white.opacity(0.01)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                shape
                    .stroke(specularBorder, lineWidth: 1)
            }
            .contentShape(shape)
    }

    private var specularBorder: LinearGradient {
        let topLeadingOpacity = colorScheme == .dark ? 0.35 : 0.75
        return LinearGradient(
            stops: [
                .init(color: .white.opacity(topLeadingOpacity), location: 0.0),
                .init(color: .white.opacity(0.05), location: 0.5),
                .init(color: .white.opacity(0.15), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    func aeroCard(verticalPadding: CGFloat = 16, horizontalPadding: CGFloat = 16) -> some View {
        modifier(AeroCardModifier(verticalPadding: verticalPadding, horizontalPadding: horizontalPadding))
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

    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        if cleaned.count == 6, let hexValue = UInt(cleaned, radix: 16) {
            self.init(hex: hexValue)
        } else {
            self.init(hex: 0xA855F7)
        }
    }
}
