import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    func configureDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleNotification(
        for subscription: Subscription,
        defaultReminderDays: Int,
        currencySymbol: String,
        allowImmediateFallback: Bool = true
    ) {
        let snapshot = SubscriptionSnapshot(subscription: subscription, defaultReminderDays: defaultReminderDays)
        guard let payload = Self.makePayload(
            from: snapshot,
            currencySymbol: currencySymbol,
            allowImmediateFallback: allowImmediateFallback
        ) else {
            cancelNotification(for: snapshot.id)
            return
        }

        Task {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [payload.identifier])

            var settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = await requestAuthorization()
                settings = await center.notificationSettings()
            }

            guard Self.isAuthorized(settings.authorizationStatus) else {
                return
            }

            await Self.enqueue(payload, using: center)
        }
    }

    func cancelNotification(for subscription: Subscription) {
        cancelNotification(for: subscription.id)
    }

    func cancelNotification(for subscriptionId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [subscriptionId.uuidString])
    }

    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func rescheduleAll(
        subscriptions: [Subscription],
        defaultReminderDays: Int,
        currencySymbol: String
    ) {
        let items: [(identifier: String, payload: NotificationPayload?)] = subscriptions.map { sub in
            let snapshot = SubscriptionSnapshot(subscription: sub, defaultReminderDays: defaultReminderDays)
            let payload = Self.makePayload(
                from: snapshot,
                currencySymbol: currencySymbol,
                allowImmediateFallback: false
            )
            return (snapshot.id.uuidString, payload)
        }

        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard Self.isAuthorized(settings.authorizationStatus) else {
                return
            }

            for item in items {
                center.removePendingNotificationRequests(withIdentifiers: [item.identifier])
                if let payload = item.payload {
                    await Self.enqueue(payload, using: center)
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Private Types & Helpers

    private enum TriggerSpec: Sendable {
        case calendar(DateComponents)
        case timeInterval(TimeInterval)
    }

    private struct NotificationPayload: Sendable {
        let identifier: String
        let title: String
        let body: String
        let trigger: TriggerSpec
    }

    private struct SubscriptionSnapshot: Sendable {
        let id: UUID
        let name: String
        let price: Double
        let billingCycle: String
        let nextBillingDate: Date
        let isFreeTrial: Bool
        let daysBefore: Int

        init(subscription: Subscription, defaultReminderDays: Int) {
            self.id = subscription.id
            self.name = subscription.name.trimmingCharacters(in: .whitespacesAndNewlines)
            self.price = subscription.price
            self.billingCycle = subscription.billingCycle
            self.nextBillingDate = subscription.nextBillingDate
            self.isFreeTrial = subscription.isFreeTrial
            self.daysBefore = subscription.customReminderDays ?? defaultReminderDays
        }
    }

    private static func makePayload(
        from snapshot: SubscriptionSnapshot,
        currencySymbol: String,
        allowImmediateFallback: Bool
    ) -> NotificationPayload? {
        guard !snapshot.name.isEmpty,
              let trigger = makeTriggerSpec(
                  nextBillingDate: snapshot.nextBillingDate,
                  billingCycle: snapshot.billingCycle,
                  isFreeTrial: snapshot.isFreeTrial,
                  daysBefore: snapshot.daysBefore,
                  allowImmediateFallback: allowImmediateFallback
              ) else {
            return nil
        }

        let title = L10n.notificationTitle(name: snapshot.name, isFreeTrial: snapshot.isFreeTrial)
        let body = snapshot.isFreeTrial
            ? L10n.freeTrialNotificationBody
            : L10n.paymentNotificationBody(
                price: formatPrice(snapshot.price),
                currency: currencySymbol,
                daysBefore: snapshot.daysBefore
            )

        return NotificationPayload(
            identifier: snapshot.id.uuidString,
            title: title,
            body: body,
            trigger: trigger
        )
    }

    private static func enqueue(_ payload: NotificationPayload, using center: UNUserNotificationCenter) async {
        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default

        let trigger: UNNotificationTrigger
        switch payload.trigger {
        case .calendar(let components):
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .timeInterval(let seconds):
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: payload.identifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private static func isAuthorized(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func makeTriggerSpec(
        nextBillingDate: Date,
        billingCycle: String,
        isFreeTrial: Bool,
        daysBefore: Int,
        allowImmediateFallback: Bool
    ) -> TriggerSpec? {
        let calendar = Calendar.current
        let now = Date.now
        let startOfToday = calendar.startOfDay(for: now)
        var targetBillingDay = calendar.startOfDay(for: nextBillingDate)

        if !isFreeTrial && targetBillingDay < startOfToday {
            let component: Calendar.Component = billingCycle == "yearly" ? .year : .month
            var iterations = 0
            while targetBillingDay < startOfToday && iterations < 120 {
                guard let next = calendar.date(byAdding: component, value: 1, to: targetBillingDay) else {
                    return nil
                }
                targetBillingDay = next
                iterations += 1
            }
        }

        if isFreeTrial && targetBillingDay < startOfToday {
            return nil
        }

        guard let reminderDay = calendar.date(byAdding: .day, value: -daysBefore, to: targetBillingDay),
              var fireDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: reminderDay) else {
            return nil
        }

        if fireDate <= now {
            if isFreeTrial {
                if let trialMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetBillingDay),
                   trialMorning > now {
                    fireDate = trialMorning
                } else if allowImmediateFallback && targetBillingDay >= startOfToday {
                    return .timeInterval(10)
                } else {
                    return nil
                }
            } else {
                let component: Calendar.Component = billingCycle == "yearly" ? .year : .month
                var iterations = 0
                while fireDate <= now && iterations < 120 {
                    guard let nextBilling = calendar.date(byAdding: component, value: 1, to: targetBillingDay),
                          let nextReminderDay = calendar.date(byAdding: .day, value: -daysBefore, to: nextBilling),
                          let nextFireDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextReminderDay) else {
                        return nil
                    }
                    targetBillingDay = nextBilling
                    fireDate = nextFireDate
                    iterations += 1
                }
            }
        }

        guard fireDate > now else { return nil }
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        return .calendar(components)
    }

    private static func formatPrice(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }
}
