import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 1

    var body: some View {
        if hasCompletedOnboarding {
            homeView
        } else {
            OnboardingView()
        }
    }

    // MARK: - Temporary Home

    private var homeView: some View {
        ZStack {
            AeroBackground()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)

                    Text("Kurulum Tamamlandı")
                        .font(.title2.bold())

                    Text("\(currencySymbol) / \(reminderLabel)")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .aeroCard()

                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasCompletedOnboarding = false
                    }
                } label: {
                    Text("Sıfırla")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                        .aeroCard()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
        }
    }

    private var reminderLabel: String {
        switch reminderDaysBefore {
        case 0: return "Aynı gün"
        case 1: return "1 gün önce"
        case 3: return "3 gün önce"
        case 7: return "1 hafta önce"
        default: return "\(reminderDaysBefore) gün önce"
        }
    }
}

#Preview {
    ContentView()
}
