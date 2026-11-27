import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 1
    @AppStorage("appLanguage") private var appLanguage = "tr"
    @Query(sort: \Subscription.nextBillingDate) private var subscriptions: [Subscription]

    @State private var showYearly = false
    @State private var showProAlert = false
    @State private var activeSheet: ActiveSheet?
    @State private var showVoiceDictation = false
    @State private var pendingDictationResult: ParsedSubscription?

    private enum ActiveSheet: Identifiable {
        case add
        case addPrefilled(ParsedSubscription)
        case edit(Subscription)
        case analytics
        case settings

        var id: String {
            switch self {
            case .add: return "add"
            case .addPrefilled: return "add-prefilled"
            case .edit(let sub): return "edit-\(sub.id.uuidString)"
            case .analytics: return "analytics"
            case .settings: return "settings"
            }
        }
    }

    // MARK: - Derived Lists & Totals (Active Only, Exclude Free Trials)

    private var activeSubscriptions: [Subscription] {
        subscriptions.filter(\.isActive)
    }

    private var inactiveSubscriptions: [Subscription] {
        subscriptions.filter { !$0.isActive }
    }

    private var paidSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive && !$0.isFreeTrial }
    }

    private var totalMonthly: Double {
        paidSubscriptions.reduce(0) { total, sub in
            if sub.billingCycle == "yearly" {
                return total + sub.price / 12
            }
            return total + sub.price
        }
    }

    private var totalYearly: Double {
        paidSubscriptions.reduce(0) { total, sub in
            if sub.billingCycle == "monthly" {
                return total + sub.price * 12
            }
            return total + sub.price
        }
    }

    private var proDate: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: .now)!
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AeroBackground()

            VStack(spacing: 0) {
                // Top bar
                HStack(spacing: 16) {
                    Spacer()

                    Button { activeSheet = .analytics } label: {
                        Image(systemName: "chart.pie")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    Button { activeSheet = .settings } label: {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Subscription list
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(activeSubscriptions) { sub in
                            subscriptionCardButton(for: sub)
                        }

                        ForEach(inactiveSubscriptions) { sub in
                            subscriptionCardButton(for: sub)
                        }

                        // SubTrack Pro (not included in total)
                        Button { showProAlert = true } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.body)
                                    .frame(width: 24)
                                    .foregroundStyle(.secondary)

                                Text("SubTrack Pro")
                                    .font(.body.weight(.semibold))

                                Text("•")
                                    .foregroundStyle(.secondary)

                                Text(proDate, format: .dateTime.day().month(.abbreviated).locale(L10n.locale))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("\(currencySymbol)59")
                                    .font(.body.weight(.semibold))
                            }
                            .aeroCard()
                            .opacity(0.45)
                        }
                        .buttonStyle(.plain)

                        // New + & Voice Dictation
                        HStack(spacing: 12) {
                            Button { activeSheet = .add } label: {
                                Text(L10n.newSubscription)
                                    .font(.subheadline.weight(.medium))
                                    .frame(minHeight: 20)
                                    .aeroCard()
                                    .frame(maxWidth: 160)
                                    .opacity(0.45)
                            }
                            .buttonStyle(.plain)

                            Button { showVoiceDictation = true } label: {
                                Image(systemName: "mic.fill")
                                    .font(.subheadline.weight(.medium))
                                    .frame(minHeight: 20)
                                    .aeroCard()
                                    .frame(width: 56)
                                    .opacity(0.45)
                            }
                            .buttonStyle(.plain)
                        }

                        RotatingTipView()
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }

                // Bottom total
                totalBar
            }
        }
        .alert(L10n.proComingSoon, isPresented: $showProAlert) {
            Button(L10n.ok, role: .cancel) {}
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                AddSubscriptionView(subscriptionToEdit: nil)
            case .addPrefilled(let parsed):
                AddSubscriptionView(subscriptionToEdit: nil, prefilledData: parsed)
            case .edit(let sub):
                AddSubscriptionView(subscriptionToEdit: sub)
            case .analytics:
                AnalyticsView()
                    .presentationDetents([.large])
            case .settings:
                SettingsView()
                    .presentationDetents([.large])
            }
        }
        .fullScreenCover(isPresented: $showVoiceDictation, onDismiss: {
            if let parsed = pendingDictationResult {
                pendingDictationResult = nil
                activeSheet = .addPrefilled(parsed)
            }
        }) {
            VoiceDictationView { parsed in
                pendingDictationResult = parsed
            }
        }
    }

    // MARK: - Subscription Row & Context Menu

    private func subscriptionCardButton(for sub: Subscription) -> some View {
        Button {
            activeSheet = .edit(sub)
        } label: {
            subscriptionRow(sub)
        }
        .buttonStyle(.plain)
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contextMenu {
            Button {
                toggleSubscriptionActive(sub)
            } label: {
                Label(
                    sub.isActive ? L10n.deactivate : L10n.activate,
                    systemImage: sub.isActive ? "pause.circle" : "play.circle"
                )
            }

            Button(role: .destructive) {
                deleteSubscription(sub)
            } label: {
                Label(L10n.delete, systemImage: "trash")
            }
        }
    }

    private func subscriptionRow(_ sub: Subscription) -> some View {
        HStack(spacing: 10) {
            Image(systemName: sub.iconName)
                .font(.body.weight(.semibold))
                .frame(width: 24)
                .foregroundStyle(sub.isActive ? Color(hex: sub.colorHex) : Color.secondary)

            Text(sub.name)
                .font(.body.weight(.semibold))

            if !sub.isActive {
                Text(L10n.inactive)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.secondary)
            } else if sub.isFreeTrial {
                Text(L10n.trial)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.orange)
            }

            Text("•")
                .foregroundStyle(.secondary)

            Text(sub.nextBillingDate, format: .dateTime.day().month(.abbreviated).locale(L10n.locale))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(
                sub.billingCycle == "yearly"
                    ? "\(currencySymbol)\(formattedPrice(sub.price)) /y"
                    : "\(currencySymbol)\(formattedPrice(sub.price))"
            )
            .font(.body.weight(.semibold))
            .strikethrough(!sub.isActive, color: .secondary)
        }
        .aeroCard()
        .opacity(sub.isActive ? 1 : 0.45)
    }

    // MARK: - Context Actions

    private func toggleSubscriptionActive(_ sub: Subscription) {
        withAnimation(.easeInOut(duration: 0.25)) {
            sub.isActive.toggle()

            if sub.isActive {
                advancePastDateIfNeeded(for: sub)
            }

            try? modelContext.save()
        }

        if sub.isActive {
            NotificationManager.shared.scheduleNotification(
                for: sub,
                defaultReminderDays: reminderDaysBefore,
                currencySymbol: currencySymbol
            )
        } else {
            NotificationManager.shared.cancelNotification(for: sub)
        }
    }

    private func deleteSubscription(_ sub: Subscription) {
        NotificationManager.shared.cancelNotification(for: sub)
        withAnimation(.easeInOut(duration: 0.25)) {
            modelContext.delete(sub)
            try? modelContext.save()
        }
    }

    private func advancePastDateIfNeeded(for sub: Subscription) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        var billingDay = calendar.startOfDay(for: sub.nextBillingDate)

        guard billingDay < startOfToday else { return }

        let component: Calendar.Component = sub.billingCycle == "yearly" ? .year : .month
        var iterations = 0
        while billingDay < startOfToday && iterations < 120 {
            guard let next = calendar.date(byAdding: component, value: 1, to: billingDay) else { break }
            billingDay = next
            iterations += 1
        }

        sub.nextBillingDate = billingDay
    }

    private func formattedPrice(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }

    private func formattedTotalPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: appLanguage == "tr" ? "tr_TR" : "en_US")
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = value == value.rounded() ? 0 : 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? formattedPrice(value)
    }

    // MARK: - Total Bar

    private var primaryTotalText: String {
        showYearly
            ? L10n.amountYearly(formattedTotalPrice(totalYearly), currencySymbol)
            : L10n.amountMonthly(formattedTotalPrice(totalMonthly), currencySymbol)
    }

    private var secondaryTotalText: String {
        showYearly
            ? L10n.amountMonthly(formattedTotalPrice(totalMonthly), currencySymbol)
            : L10n.amountYearly(formattedTotalPrice(totalYearly), currencySymbol)
    }

    private var totalBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("+")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary.opacity(0.65))

                Rectangle()
                    .fill(.secondary.opacity(0.35))
                    .frame(height: 1)
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showYearly.toggle()
                }
            } label: {
                HStack(alignment: .center) {
                    Text(L10n.totalLabel)
                        .font(.title3.weight(.semibold))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(primaryTotalText)
                            .font(.title3.weight(.bold))
                            .contentTransition(.numericText())

                        Text(secondaryTotalText)
                            .font(.caption.weight(.light))
                            .opacity(0.55)
                            .contentTransition(.numericText())
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .preferredColorScheme(.dark)
}
