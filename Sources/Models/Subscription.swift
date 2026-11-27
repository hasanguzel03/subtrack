import Foundation
import SwiftData

struct PriceRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var price: Double
    var date: Date

    init(id: UUID = UUID(), price: Double, date: Date = .now) {
        self.id = id
        self.price = price
        self.date = date
    }
}

@Model
final class Subscription {
    var id: UUID
    var name: String
    var price: Double
    var billingCycle: String   // "monthly" or "yearly"
    var nextBillingDate: Date
    var createdAt: Date
    var iconName: String = "creditcard"
    var colorHex: String = "#A855F7"
    var isFreeTrial: Bool = false
    var isActive: Bool = true
    var customReminderDays: Int?
    var priceHistory: [PriceRecord] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        price: Double = 0,
        billingCycle: String = "monthly",
        nextBillingDate: Date = .now,
        createdAt: Date = .now,
        iconName: String = "creditcard",
        colorHex: String = "#A855F7",
        isFreeTrial: Bool = false,
        isActive: Bool = true,
        customReminderDays: Int? = nil,
        priceHistory: [PriceRecord] = []
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.billingCycle = billingCycle
        self.nextBillingDate = nextBillingDate
        self.createdAt = createdAt
        self.iconName = iconName
        self.colorHex = colorHex
        self.isFreeTrial = isFreeTrial
        self.isActive = isActive
        self.customReminderDays = customReminderDays
        self.priceHistory = priceHistory
    }
}
