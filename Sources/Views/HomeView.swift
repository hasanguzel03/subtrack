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

    // MARK: - Totals

    private var totalMonthly: Double {
        subscriptions.reduce(0) { total, sub in
            if sub.billingCycle == "yearly" {
                return total + sub.price / 12
            }
            return total + sub.price
        }
    }

    private var totalYearly: Double {
        subscriptions.reduce(0) { total, sub in
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
                                rowContent(
                                    name: sub.name,
                                    date: sub.nextBillingDate,
                                    price: sub.price,
                                    cycle: sub.billingCycle
                                )
                                .aeroCard()
                            }
                            .buttonStyle(.plain)
                        }

                        // SubTrack Pro (not included in total)
                        Button { showProAlert = true } label: {
                            rowContent(
                                name: "SubTrack Pro",
                                date: proDate,
                                price: 59,
                                cycle: nil
                            )
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
        .alert("SubTrack Pro yakında", isPresented: $showProAlert) {
            Button("Tamam", role: .cancel) {}
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

    // MARK: - Row Content

    private func rowContent(name: String, date: Date, price: Double, cycle: String?) -> some View {
        HStack {
            Text(name)
                .font(.body.weight(.semibold))

            Text("•")
                .foregroundStyle(.secondary)

            Text(date, format: .dateTime.day().month(.abbreviated))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if let cycle, cycle == "yearly" {
                Text("\(currencySymbol)\(formattedPrice(price)) /y")
                    .font(.body.weight(.semibold))
            } else {
                Text("\(currencySymbol)\(formattedPrice(price))")
                    .font(.body.weight(.semibold))
            }
        }
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
                        Text("Toplam: \(currencySymbol)\(formattedPrice(totalYearly)) / yıl")
                    } else {
                        Text("Toplam: \(currencySymbol)\(formattedPrice(totalMonthly)) / ay")
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
