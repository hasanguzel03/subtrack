import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 1
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("appLanguage") private var appLanguage = "tr"
    @Environment(\.dismiss) private var dismiss
    @Query private var subscriptions: [Subscription]

    private let currencies = [
        ("₺", "TRY"),
        ("$", "USD"),
        ("€", "EUR"),
        ("£", "GBP"),
    ]

    private let reminderDays = [0, 1, 3, 7]

    private let languages = [
        ("Türkçe", "tr"),
        ("English", "en"),
    ]

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Language
                    settingsSection(title: L10n.languageLabel) {
                        ForEach(languages, id: \.1) { title, code in
                            settingsRow(title: title, selected: appLanguage == code) {
                                appLanguage = code
                            }
                        }
                    }

                    // Theme
                    settingsSection(title: L10n.theme) {
                        settingsRow(title: L10n.themeSystem, selected: appTheme == "system") {
                            withAnimation(.easeInOut(duration: 0.3)) { appTheme = "system" }
                        }
                        settingsRow(title: L10n.themeLight, selected: appTheme == "light") {
                            withAnimation(.easeInOut(duration: 0.3)) { appTheme = "light" }
                        }
                        settingsRow(title: L10n.themeDark, selected: appTheme == "dark") {
                            withAnimation(.easeInOut(duration: 0.3)) { appTheme = "dark" }
                        }
                    }

                    // Currency
                    settingsSection(title: L10n.currency) {
                        ForEach(currencies, id: \.0) { symbol, label in
                            Button {
                                currencySymbol = symbol
                            } label: {
                                HStack {
                                    Text(symbol)
                                        .font(.title3.bold())
                                        .frame(width: 32)
                                    Text(label)
                                        .font(.body.weight(.medium))
                                    Spacer()
                                    if currencySymbol == symbol {
                                        checkmark
                                    }
                                }
                                .aeroCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Reminder
                    settingsSection(title: L10n.reminder) {
                        ForEach(reminderDays, id: \.self) { days in
                            settingsRow(
                                title: L10n.reminderLabel(for: days),
                                selected: reminderDaysBefore == days
                            ) {
                                reminderDaysBefore = days
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .onChange(of: reminderDaysBefore) { _, _ in
            rescheduleNotifications()
        }
        .onChange(of: appLanguage) { _, _ in
            rescheduleNotifications()
        }
        .onChange(of: currencySymbol) { _, _ in
            rescheduleNotifications()
        }
    }

    // MARK: - Helpers

    private func rescheduleNotifications() {
        NotificationManager.shared.rescheduleAll(
            subscriptions: subscriptions,
            defaultReminderDays: reminderDaysBefore,
            currencySymbol: currencySymbol
        )
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
            VStack(spacing: 8) {
                content()
            }
        }
    }

    private func settingsRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body.weight(.medium))
                Spacer()
                if selected { checkmark }
            }
            .aeroCard()
        }
        .buttonStyle(.plain)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.green)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .preferredColorScheme(.dark)
}
