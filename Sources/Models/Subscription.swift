import Foundation
import SwiftData

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

    init(
        id: UUID = UUID(),
        name: String = "",
        price: Double = 0,
        billingCycle: String = "monthly",
        nextBillingDate: Date = .now,
        createdAt: Date = .now,
        iconName: String = "creditcard",
        isFreeTrial: Bool = false,
        customReminderDays: Int? = nil
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
    }
}
