import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 1
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("appLanguage") private var appLanguage = "tr"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]

    @State private var showResetAlert = false
    @State private var isResetting = false

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

                    // [TEMP_NOTIFICATION_TEST_START]
                    NotificationTestTriggerButton()
                        .padding(.top, 12)
                    // [TEMP_NOTIFICATION_TEST_END]

                    // Reset App
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text(L10n.resetApp)
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .aeroCard()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .alert(L10n.resetAlertTitle, isPresented: $showResetAlert) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.confirmReset, role: .destructive) {
                resetApp()
            }
        } message: {
            Text(L10n.resetAlertMessage)
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

    private func resetApp() {
        isResetting = true

        // 1. SwiftData cleanup
        try? modelContext.delete(model: Subscription.self)
        try? modelContext.save()

        // 2. Notification cleanup
        NotificationManager.shared.cancelAllNotifications()

        // 3. Reset AppStorage defaults
        currencySymbol = "₺"
        reminderDaysBefore = 1
        appTheme = "system"
        appLanguage = "tr"
        hasCompletedOnboarding = false

        // 4. Dismiss settings sheet
        dismiss()
    }

    private func rescheduleNotifications() {
        guard !isResetting else { return }
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
