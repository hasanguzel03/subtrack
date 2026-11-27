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
    static var totalLabel: String { isTR ? "Toplam" : "Total" }

    static func amountMonthly(_ amount: String, _ currency: String) -> String {
        isTR ? "\(currency)\(amount) / ay" : "\(currency)\(amount) / mo"
    }
    static func amountYearly(_ amount: String, _ currency: String) -> String {
        isTR ? "\(currency)\(amount) / yıl" : "\(currency)\(amount) / yr"
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
    static var scanFromScreenshot: String { isTR ? "Ekran Görüntüsünden Tara" : "Scan from Screenshot" }
    static var scanningScreenshot: String { isTR ? "Taranıyor..." : "Scanning..." }
    static var ocrNoDataFound: String {
        isTR
            ? "Bilgi okunamadı, elle girebilirsin"
            : "Couldn't detect details, you can enter manually"
    }
    static var priceHistory: String { isTR ? "Fiyat Geçmişi" : "Price History" }

    static func percentageChange(_ percent: Int) -> String {
        if percent > 0 { return isTR ? "+%\(percent)" : "+\(percent)%" }
        if percent < 0 { return isTR ? "-%\(abs(percent))" : "-\(abs(percent))%" }
        return isTR ? "%0" : "0%"
    }

    static func percentage(_ value: Int) -> String {
        isTR ? "%\(value)" : "\(value)%"
    }

    // MARK: - Analytics

    static var analyticsTitle: String { isTR ? "Harcama Analizi" : "Spending Analytics" }
    static var analyticsMonthlyTotal: String { isTR ? "Aylık Toplam" : "Monthly Total" }
    static var analyticsYearlyTotal: String { isTR ? "Yıllık Toplam" : "Yearly Total" }
    static var spendingBreakdown: String { isTR ? "Harcama Dağılımı" : "Spending Breakdown" }
    static var analyticsNoSpendingData: String {
        isTR
            ? "Grafiği görmek için aktif bir abonelik ekle."
            : "Add an active subscription to see your breakdown."
    }
    static var priceChanges: String { isTR ? "Fiyat Değişimleri" : "Price Changes" }
    static var noPriceChanges: String {
        isTR
            ? "Bir aboneliğin fiyatını güncellediğinde zam geçmişi burada görünür."
            : "Price change history will appear here once you update a subscription's price."
    }
    static var planDistribution: String { isTR ? "Plan Dağılımı" : "Plan Distribution" }
    static var monthlyPlans: String { isTR ? "Aylık Planlar" : "Monthly Plans" }
    static var yearlyPlans: String { isTR ? "Yıllık Planlar" : "Yearly Plans" }
    static var noFreeTrials: String { isTR ? "Deneme yok" : "No trials" }

    static func activeSubscriptionsCount(_ count: Int) -> String {
        isTR ? "\(count) aktif" : "\(count) active"
    }

    static func freeTrialsCount(_ count: Int) -> String {
        if isTR {
            return "\(count) deneme"
        } else {
            return count == 1 ? "1 trial" : "\(count) trials"
        }
    }

    static func planCount(_ count: Int) -> String {
        if isTR {
            return "\(count) plan"
        } else {
            return count == 1 ? "1 plan" : "\(count) plans"
        }
    }

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
    static var resetApp: String { isTR ? "Uygulamayı Sıfırla" : "Reset App" }
    static var resetAlertTitle: String { isTR ? "Emin misin?" : "Are you sure?" }
    static var resetAlertMessage: String {
        isTR
            ? "Tüm aboneliklerin, fiyat geçmişin, bildirimlerin ve ayarların kalıcı olarak silinecek ve kurulum ekranına döneceksin."
            : "All your subscriptions, price history, notifications, and settings will be permanently deleted, and you will return to setup."
    }
    static var cancel: String { isTR ? "Vazgeç" : "Cancel" }
    static var confirmReset: String { isTR ? "Evet, Sıfırla" : "Yes, Reset" }

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

    // MARK: - Tips

    static var tips: [String] {
        if isTR {
            return [
                "Toplam tutara dokunarak aylık ve yıllık görünüm arasında geçiş yapabilirsin.",
                "Yıllık planlar çoğu serviste %15–20 tasarruf sağlar.",
                "Ücretsiz denemeleri bitmeden 1 gün önce kontrol etmeyi unutma.",
                "Son 30 gündür açmadığın bir aboneliği iptal etmek en hızlı tasarruftur.",
                "Kartlara dokunarak her abonelik için özel hatırlatma günü seçebilirsin.",
                "Benzer servisleri dönüşümlü kullanmak aylık giderini ciddi oranda azaltır.",
                "Ayarlar'dan para birimini, dili ve temayı dilediğin zaman değiştirebilirsin."
            ]
        } else {
            return [
                "Tap the total amount to switch between monthly and yearly views.",
                "Annual plans save 15–20% on most subscription services.",
                "Remember to check free trials 1 day before they renew.",
                "Canceling a subscription you haven't used in 30 days is the fastest way to save.",
                "Tap any card to set a custom reminder day for that subscription.",
                "Rotating similar services month-to-month can cut your monthly bill significantly.",
                "You can change your currency, language, and theme anytime in Settings."
            ]
        }
    }
}
