import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @Query(sort: \Subscription.nextBillingDate) private var subscriptions: [Subscription]

    @State private var showYearly = false
    @State private var showProAlert = false
    @State private var showAddSheet = false
    @State private var showSettings = false
    @State private var selectedSubscription: Subscription?

    // MARK: - Totals (exclude free trials)

    private var paidSubscriptions: [Subscription] {
        subscriptions.filter { !$0.isFreeTrial }
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
                HStack {
                    Spacer()
                    Button { showSettings = true } label: {
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
                        ForEach(subscriptions) { sub in
                            Button {
                                selectedSubscription = sub
                            } label: {
                                subscriptionRow(sub)
                            }
                            .buttonStyle(.plain)
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

                                Text(proDate, format: .dateTime.day().month(.abbreviated))
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

                        // New +
                        Button { showAddSheet = true } label: {
                            Text("New +")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: 160)
                                .aeroCard()
                                .opacity(0.45)
                        }
                        .buttonStyle(.plain)
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
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionView(subscriptionToEdit: nil)
        }
        .sheet(item: $selectedSubscription) { sub in
            AddSubscriptionView(subscriptionToEdit: sub)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.large])
        }
    }

    // MARK: - Subscription Row

    private func subscriptionRow(_ sub: Subscription) -> some View {
        HStack(spacing: 10) {
            Image(systemName: sub.iconName)
                .font(.body)
                .frame(width: 24)
                .foregroundStyle(.secondary)

            Text(sub.name)
                .font(.body.weight(.semibold))

            if sub.isFreeTrial {
                Text(L10n.trial)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.orange)
            }

            Text("•")
                .foregroundStyle(.secondary)

            Text(sub.nextBillingDate, format: .dateTime.day().month(.abbreviated))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if sub.billingCycle == "yearly" {
                Text("\(currencySymbol)\(formattedPrice(sub.price)) /y")
                    .font(.body.weight(.semibold))
            } else {
                Text("\(currencySymbol)\(formattedPrice(sub.price))")
                    .font(.body.weight(.semibold))
            }
        }
        .aeroCard()
    }

    private func formattedPrice(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }

    // MARK: - Total Bar

    private var totalBar: some View {
        VStack(spacing: 10) {
            Line()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                .foregroundStyle(.secondary.opacity(0.5))
                .frame(height: 1)
                .padding(.horizontal, 32)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showYearly.toggle()
                }
            } label: {
                Group {
                    if showYearly {
                        Text(L10n.totalYearly(formattedPrice(totalYearly), currencySymbol))
                    } else {
                        Text(L10n.totalMonthly(formattedPrice(totalMonthly), currencySymbol))
                    }
                }
                .font(.title3.weight(.bold))
                .contentTransition(.numericText())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .padding(.top, 4)
    }
}

// MARK: - Dashed Line Shape

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .preferredColorScheme(.dark)
}
