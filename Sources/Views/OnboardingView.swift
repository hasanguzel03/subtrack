import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = "tr"
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 1

    @State private var step = 1

    var body: some View {
        ZStack {
            AeroBackground()

            VStack(spacing: 32) {
                switch step {
                case 1:
                    languageStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case 2:
                    currencyStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                default:
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

    // MARK: - Step 1: Language

    private var languageStep: some View {
        VStack(spacing: 24) {
            Text("Dil / Language")
                .font(.title2.bold())

            VStack(spacing: 12) {
                languageButton(title: "Türkçe", code: "tr")
                languageButton(title: "English", code: "en")
            }
        }
    }

    private func languageButton(title: String, code: String) -> some View {
        Button {
            appLanguage = code
            withAnimation(.easeInOut(duration: 0.35)) {
                step = 2
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

    // MARK: - Step 2: Currency

    private var currencyStep: some View {
        VStack(spacing: 24) {
            Text(L10n.onboardingCurrencyTitle)
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
                step = 3
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

    // MARK: - Step 3: Reminder

    private var reminderStep: some View {
        VStack(spacing: 24) {
            Text(L10n.onboardingReminderTitle)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                reminderButton(title: L10n.reminderSameDay, days: 0)
                reminderButton(title: L10n.reminder1Day, days: 1)
                reminderButton(title: L10n.reminder3Days, days: 3)
                reminderButton(title: L10n.reminder1Week, days: 7)
            }
        }
    }

    private func reminderButton(title: String, days: Int) -> some View {
        Button {
            reminderDaysBefore = days
            Task {
                await NotificationManager.shared.requestAuthorization()
            }
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
