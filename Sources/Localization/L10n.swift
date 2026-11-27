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
    static var choosePreset: String { isTR ? "Hazır Servis Seç" : "Choose Preset" }
    static var iconColor: String { isTR ? "İkon Rengi" : "Icon Color" }
    static var scanFromScreenshot: String { isTR ? "Ekran Görüntüsünden Tara" : "Scan from Screenshot" }
    static var dictate: String { isTR ? "Dikte" : "Dictate" }
    static var scanningScreenshot: String { isTR ? "Taranıyor..." : "Scanning..." }
    static var ocrNoDataFound: String {
        isTR
            ? "Bilgi okunamadı, elle girebilirsin"
            : "Couldn't detect details, you can enter manually"
    }
    static var speechPermissionDenied: String {
        isTR
            ? "Konuşma tanıma izni gerekli. Ayarlar'dan izin verebilirsin."
            : "Speech recognition permission is required. You can enable it in Settings."
    }
    static var microphonePermissionDenied: String {
        isTR
            ? "Mikrofon izni gerekli. Ayarlar'dan izin verebilirsin."
            : "Microphone permission is required. You can enable it in Settings."
    }
    static var speechRecognizerUnavailable: String {
        isTR
            ? "Konuşma tanıma şu anda kullanılamıyor."
            : "Speech recognition is currently unavailable."
    }
    static var speechAudioError: String {
        isTR
            ? "Ses kaydı başlatılamadı."
            : "Could not start audio recording."
    }
    static var dictationFormatHint: String {
        isTR ? "Abonelik, Tarih, Ücret" : "Subscription, Date, Price"
    }
    static var done: String { isTR ? "Tamam" : "Done" }
    static var listening: String { isTR ? "Dinleniyor..." : "Listening..." }

    static var dictationExamples: [(text: String, colorHex: String)] {
        if isTR {
            return [
                ("Spotify, 24 Kasım, 10.99", "#1DB954"),
                ("YouTube, 15 Aralık, 79.99", "#FF0000"),
                ("Netflix, 12 Ocak, 229.99", "#E50914")
            ]
        } else {
            return [
                ("Spotify, Nov 24, 10.99", "#1DB954"),
                ("YouTube, Dec 15, 79.99", "#FF0000"),
                ("Netflix, Jan 12, 229.99", "#E50914")
            ]
        }
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
                "Ücretsiz denemeleri iptal etmek için çoğunlukla son günü beklemene gerek yok.",
                "Bu uygulama açık kaynaklıdır ve yerel olarak çalışmaktadır. Yani verileriniz güvende.",
                "Hızlı abonelik eklemek için dikteyi kullanabilirsin.",
                "Küçük aylık ödemeler yıl sonunda büyük masraflara dönüşebilir.",
                "Ayarlar'dan para birimini, dili ve temayı dilediğin zaman değiştirebilirsin.",
                "Unuttuğun abonelikleri bulmak için banka hesap hareketlerini kontrol et.",
                "İptal ettiğin her gereksiz abonelik, tasarruf edebileceğin yeni bir fırsattır.",
                "Öğrenci ve Aile indirimleri için biraz yaratıcı düşünmek gerekebilir."
            ]
        } else {
            return [
                "Tap the total amount to switch between monthly and yearly views.",
                "Annual plans save 15–20% on most subscription services.",
                "You usually don't need to wait until the last day to cancel a free trial.",
                "This app is open source and runs locally, so your data stays safe.",
                "You can use dictation to add subscriptions quickly.",
                "Small monthly payments can add up to major expenses by the end of the year.",
                "You can change your currency, language, and theme anytime in Settings.",
                "Check your bank statements to spot subscriptions you may have forgotten.",
                "Every unnecessary subscription you cancel is a new opportunity to save.",
                "Getting student and family discounts might take a little creative thinking."
            ]
        }
    }
}
