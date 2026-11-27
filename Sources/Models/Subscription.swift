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
    var iconName: String
    var isFreeTrial: Bool
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
        isFreeTrial: Bool = false,
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
        self.isFreeTrial = isFreeTrial
        self.customReminderDays = customReminderDays
        self.priceHistory = priceHistory
    }
}
