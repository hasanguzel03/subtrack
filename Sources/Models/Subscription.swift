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

    init(
        id: UUID = UUID(),
        name: String = "",
        price: Double = 0,
        billingCycle: String = "monthly",
        nextBillingDate: Date = .now,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.billingCycle = billingCycle
        self.nextBillingDate = nextBillingDate
        self.createdAt = createdAt
    }
}
