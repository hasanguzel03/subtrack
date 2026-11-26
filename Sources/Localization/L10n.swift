import SwiftUI

struct L10n {
    @AppStorage("appLanguage") static var language = "tr"

    static var isTR: Bool { language == "tr" }

    // MARK: - Onboarding

    static var onboardingLanguageTitle: String { isTR ? "Dil" : "Language" }
    static var onboardingCurrencyTitle: String { isTR ? "Para Birimi" : "Currency" }
    static var onboardingReminderTitle: String {
        isTR ? "Ödemelerden ne kadar\nönce uyaralım?" : "How early should\nwe remind you?"
    }

    // MARK: - Reminder Options

    static var reminderSameDay: String { isTR ? "Aynı Gün" : "Same Day" }
    static var reminder1Day: String { isTR ? "1 Gün Önce" : "1 Day Before" }
    static var reminder3Days: String { isTR ? "3 Gün Önce" : "3 Days Before" }
    static var reminder1Week: String { isTR ? "1 Hafta Önce" : "1 Week Before" }
    static var reminderDefault: String { isTR ? "Varsayılan" : "Default" }

    static func reminderLabel(for days: Int) -> String {
        switch days {
        case 0: return reminderSameDay
        case 1: return reminder1Day
        case 3: return reminder3Days
        case 7: return reminder1Week
        default: return isTR ? "\(days) gün önce" : "\(days) days before"
        }
    }

    static func reminderDefaultLabel(days: Int) -> String {
        let label = reminderLabel(for: days)
        return isTR ? "Varsayılan (\(label))" : "Default (\(label))"
    }

    // MARK: - Home

    static var proComingSoon: String { isTR ? "SubTrack Pro yakında" : "SubTrack Pro coming soon" }
    static var ok: String { isTR ? "Tamam" : "OK" }
    static var trial: String { isTR ? "Deneme" : "Trial" }

    static func totalMonthly(_ amount: String, _ currency: String) -> String {
        isTR ? "Toplam: \(currency)\(amount) / ay" : "Total: \(currency)\(amount) / mo"
    }
    static func totalYearly(_ amount: String, _ currency: String) -> String {
        isTR ? "Toplam: \(currency)\(amount) / yıl" : "Total: \(currency)\(amount) / yr"
    }

    // MARK: - Add / Edit Subscription

    static var subscriptionName: String { isTR ? "Abonelik Adı" : "Subscription Name" }
    static var namePlaceholder: String { isTR ? "Örn: Netflix" : "e.g. Netflix" }
    static var amount: String { isTR ? "Tutar" : "Amount" }
    static var period: String { isTR ? "Periyot" : "Period" }
    static var monthly: String { isTR ? "Aylık" : "Monthly" }
    static var yearly: String { isTR ? "Yıllık" : "Yearly" }
    static var nextBillingDate: String { isTR ? "Sonraki Ödeme Tarihi" : "Next Billing Date" }
    static var trialEndDate: String { isTR ? "Deneme Bitiş Tarihi" : "Trial Ends" }
    static var save: String { isTR ? "Kaydet" : "Save" }
    static var delete: String { isTR ? "Sil" : "Delete" }
    static var freeTrial: String { isTR ? "Ücretsiz Deneme" : "Free Trial" }
    static var reminderLabel_field: String { isTR ? "Hatırlatıcı" : "Reminder" }
    static var customSubscription: String { isTR ? "+ Özel Abonelik Ekle" : "+ Custom Subscription" }
    static var searchPlaceholder: String { isTR ? "Ara..." : "Search..." }

    // MARK: - Quick Date Shortcuts

    static var today: String { isTR ? "Bugün" : "Today" }
    static var oneWeek: String { isTR ? "1 Hafta" : "1 Week" }
    static var oneMonth: String { isTR ? "1 Ay" : "1 Month" }

    // MARK: - Settings

    static var theme: String { isTR ? "Tema" : "Theme" }
    static var themeSystem: String { isTR ? "Sistem" : "System" }
    static var themeLight: String { isTR ? "Aydınlık" : "Light" }
    static var themeDark: String { isTR ? "Karanlık" : "Dark" }
    static var languageLabel: String { isTR ? "Dil" : "Language" }
    static var currency: String { isTR ? "Para Birimi" : "Currency" }
    static var reminder: String { isTR ? "Hatırlatma" : "Reminder" }

    // MARK: - Notifications

    static var freeTrialNotificationBody: String {
        isTR
            ? "Ücretsiz deneme bitiyor! Ücret kesilmeden iptal etmeyi unutma."
            : "Free trial ending soon! Remember to cancel before being charged."
    }

    static func notificationTitle(name: String, isFreeTrial: Bool) -> String {
        isFreeTrial ? "\(name) (\(trial))" : name
    }

    static func paymentNotificationBody(price: String, currency: String, daysBefore: Int) -> String {
        switch daysBefore {
        case 0:
            return isTR
                ? "\(currency)\(price) tutarındaki ödemeniz bugün."
                : "Your \(currency)\(price) payment is due today."
        case 1:
            return isTR
                ? "\(currency)\(price) tutarındaki ödemeniz yarın."
                : "Your \(currency)\(price) payment is due tomorrow."
        default:
            return isTR
                ? "\(currency)\(price) tutarındaki ödemenize \(daysBefore) gün kaldı."
                : "Your \(currency)\(price) payment is due in \(daysBefore) days."
        }
    }
}
