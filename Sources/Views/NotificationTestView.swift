// TEMPORARY DEBUG VIEW - SAFE TO DELETE

import SwiftUI
import UIKit
import UserNotifications

// MARK: - Trigger Button for Settings

struct NotificationTestTriggerButton: View {
    @AppStorage("appLanguage") private var appLanguage = "tr"
    @State private var showDebugSheet = false

    private var isTR: Bool { appLanguage == "tr" }

    var body: some View {
        Button {
            showDebugSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge")
                Text(isTR ? "Bildirim Test Menüsü (Debug)" : "Notification Test Menu (Debug)")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .aeroCard()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDebugSheet) {
            NotificationTestView()
                .presentationDetents([.large])
        }
    }
}

// MARK: - Debug View

struct NotificationTestView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "tr"

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingItems: [PendingNotificationItem] = []
    @State private var feedbackMessage: String?

    private var isTR: Bool { appLanguage == "tr" }

    private var isAuthorized: Bool {
        switch authStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    headerRow
                    permissionCard
                    quickTestsCard
                    pendingQueueCard
                    clearTestsButton
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .task {
            await refreshState()
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(isTR ? "Bildirim Test Menüsü" : "Notification Debug")
                .font(.title2.bold())

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 1. Permission Status

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isTR ? "İzin Durumu" : "Permission Status")
                .font(.headline.weight(.semibold))

            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                Text(statusText)
                    .font(.subheadline.weight(.medium))

                Spacer()

                if !isAuthorized {
                    Button {
                        handlePermissionRequest()
                    } label: {
                        Text(isTR ? "İzin İste" : "Request")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .aeroCard()
    }

    private var statusText: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral:
            return isTR ? "İzinli" : "Authorized"
        case .denied:
            return isTR ? "Reddedildi" : "Denied"
        case .notDetermined:
            return isTR ? "Sorulmadı" : "Not Determined"
        @unknown default:
            return isTR ? "Bilinmiyor" : "Unknown"
        }
    }

    private var statusColor: Color {
        switch authStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .secondary
        }
    }

    // MARK: - 2. Quick 5s Tests

    private var quickTestsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isTR ? "Hızlı Bildirim Testleri (5 sn)" : "Quick Notification Tests (5s)")
                .font(.headline.weight(.semibold))

            Button {
                scheduleQuickTest(isFreeTrial: false)
            } label: {
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundStyle(Color(hex: 0xE50914))
                    Text(isTR ? "Normal Ödeme Testi (5 sn)" : "Regular Payment Test (5s)")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                scheduleQuickTest(isFreeTrial: true)
            } label: {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundStyle(.orange)
                    Text(isTR ? "Ücretsiz Deneme Testi (5 sn)" : "Free Trial Test (5s)")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if let feedbackMessage {
                Text(feedbackMessage)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
        .aeroCard()
    }

    // MARK: - 3. Pending Queue

    private var pendingQueueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(
                    isTR
                        ? "Planlanmış Bildirimler (\(pendingItems.count))"
                        : "Scheduled Notifications (\(pendingItems.count))"
                )
                .font(.headline.weight(.semibold))

                Spacer()

                Button {
                    Task { await refreshState() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text(isTR ? "Yenile" : "Refresh")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if pendingItems.isEmpty {
                Text(isTR ? "Bekleyen bildirim yok." : "No pending notifications.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(pendingItems.enumerated()), id: \.element.id) { index, item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))

                                if item.isDebugTest {
                                    Text("TEST")
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.ultraThinMaterial, in: Capsule())
                                        .foregroundStyle(.orange)
                                }

                                Spacer()
                            }

                            Text(item.body)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let fireDate = item.fireDate {
                                Text(fireDate, format: .dateTime.day().month(.abbreviated).year().hour().minute().second().locale(L10n.locale))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if index < pendingItems.count - 1 {
                            Divider().opacity(0.25)
                        }
                    }
                }
            }
        }
        .aeroCard()
    }

    // MARK: - 4. Clear Test Notifications

    private var clearTestsButton: some View {
        Button(role: .destructive) {
            clearPendingTestNotifications()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                Text(isTR ? "Bekleyenleri Temizle" : "Clear Test Notifications")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .aeroCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func refreshState() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()

        let items = requests.map { request -> PendingNotificationItem in
            let fireDate: Date?
            if let cal = request.trigger as? UNCalendarNotificationTrigger {
                fireDate = cal.nextTriggerDate()
            } else if let interval = request.trigger as? UNTimeIntervalNotificationTrigger {
                fireDate = interval.nextTriggerDate()
            } else {
                fireDate = nil
            }

            return PendingNotificationItem(
                id: request.identifier,
                title: request.content.title,
                body: request.content.body,
                fireDate: fireDate,
                isDebugTest: request.identifier.hasPrefix(Self.testIdentifierPrefix)
            )
        }
        .sorted { ($0.fireDate ?? .distantFuture) < ($1.fireDate ?? .distantFuture) }

        authStatus = settings.authorizationStatus
        pendingItems = items
    }

    private func handlePermissionRequest() {
        if authStatus == .denied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            return
        }

        Task {
            _ = await NotificationManager.shared.requestAuthorization()
            await refreshState()
        }
    }

    private func scheduleQuickTest(isFreeTrial: Bool) {
        Task {
            let center = UNUserNotificationCenter.current()
            var settings = await center.notificationSettings()

            if settings.authorizationStatus == .notDetermined {
                _ = await NotificationManager.shared.requestAuthorization()
                settings = await center.notificationSettings()
            }

            guard settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || settings.authorizationStatus == .ephemeral else {
                await refreshState()
                feedbackMessage = isTR
                    ? "Bildirim izni verilmedi. Önce izin ver."
                    : "Notification permission denied. Please allow first."
                return
            }

            let identifier = isFreeTrial
                ? "\(Self.testIdentifierPrefix)trial"
                : "\(Self.testIdentifierPrefix)payment"

            center.removePendingNotificationRequests(withIdentifiers: [identifier])

            let content = UNMutableNotificationContent()
            if isFreeTrial {
                content.title = L10n.notificationTitle(name: "Netflix", isFreeTrial: true)
                content.body = L10n.freeTrialNotificationBody
            } else {
                content.title = "SubTrack"
                content.body = isTR
                    ? "Netflix • Ödeme hatırlatması: ₺229"
                    : "Netflix • Payment reminder: ₺229"
            }
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try? await center.add(request)
            await refreshState()

            withAnimation(.easeInOut(duration: 0.2)) {
                feedbackMessage = isTR
                    ? "5 sn içinde gelecek, uygulamayı arka plana al"
                    : "Will arrive in 5s, move app to background"
            }
        }
    }

    private func clearPendingTestNotifications() {
        let center = UNUserNotificationCenter.current()
        let testIdentifiers = pendingItems
            .filter(\.isDebugTest)
            .map(\.id)
        let fallbackIDs = ["\(Self.testIdentifierPrefix)payment", "\(Self.testIdentifierPrefix)trial"]
        center.removePendingNotificationRequests(withIdentifiers: Array(Set(testIdentifiers + fallbackIDs)))

        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackMessage = isTR ? "Test bildirimleri temizlendi." : "Test notifications cleared."
        }

        Task {
            await refreshState()
        }
    }

    // MARK: - Support

    private static let testIdentifierPrefix = "debug-test-"

    private struct PendingNotificationItem: Identifiable, Sendable {
        let id: String
        let title: String
        let body: String
        let fireDate: Date?
        let isDebugTest: Bool
    }
}

#Preview {
    NotificationTestView()
        .preferredColorScheme(.dark)
}
