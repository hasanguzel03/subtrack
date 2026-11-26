import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 1

    @State private var step = 1

    var body: some View {
        ZStack {
            AeroBackground()

            VStack(spacing: 32) {
                if step == 1 {
                    currencyStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    reminderStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 1: Currency

    private var currencyStep: some View {
        VStack(spacing: 24) {
            Text("Para Birimi")
                .font(.title2.bold())

            VStack(spacing: 12) {
                currencyButton(symbol: "₺", label: "TRY")
                currencyButton(symbol: "$", label: "USD")
                currencyButton(symbol: "€", label: "EUR")
                currencyButton(symbol: "£", label: "GBP")
            }
        }
    }

    private func currencyButton(symbol: String, label: String) -> some View {
        Button {
            currencySymbol = symbol
            withAnimation(.easeInOut(duration: 0.35)) {
                step = 2
            }
        } label: {
            HStack {
                Text(symbol)
                    .font(.title3.bold())
                    .frame(width: 32)
                Text(label)
                    .font(.body.weight(.medium))
                Spacer()
            }
            .aeroCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Reminder

    private var reminderStep: some View {
        VStack(spacing: 24) {
            Text("Ödemelerden ne kadar\nönce uyaralım?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                reminderButton(title: "Aynı Gün", days: 0)
                reminderButton(title: "1 Gün Önce", days: 1)
                reminderButton(title: "3 Gün Önce", days: 3)
                reminderButton(title: "1 Hafta Önce", days: 7)
            }
        }
    }

    private func reminderButton(title: String, days: Int) -> some View {
        Button {
            reminderDaysBefore = days
            withAnimation(.easeInOut(duration: 0.35)) {
                hasCompletedOnboarding = true
            }
        } label: {
            HStack {
                Text(title)
                    .font(.body.weight(.medium))
                Spacer()
            }
            .aeroCard()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
}
