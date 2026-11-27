import Charts
import SwiftData
import SwiftUI

struct AnalyticsView: View {
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @AppStorage("appLanguage") private var appLanguage = "tr"
    @Query(sort: \Subscription.nextBillingDate) private var subscriptions: [Subscription]

    // MARK: - Derived Data (Free Trials Excluded from Cost)

    private var paidSubscriptions: [Subscription] {
        subscriptions.filter { !$0.isFreeTrial }
    }

    private var trialSubscriptions: [Subscription] {
        subscriptions.filter { $0.isFreeTrial }
    }

    private var totalMonthly: Double {
        paidSubscriptions.reduce(0) { $0 + monthlyCost(of: $1) }
    }

    private var totalYearly: Double {
        paidSubscriptions.reduce(0) { total, sub in
            total + (sub.billingCycle == "monthly" ? sub.price * 12 : sub.price)
        }
    }

    private var chartSlices: [ChartSlice] {
        let sortedPaid = paidSubscriptions
            .filter { monthlyCost(of: $0) > 0 }
            .sorted { monthlyCost(of: $0) > monthlyCost(of: $1) }

        let total = totalMonthly
        guard total > 0 else { return [] }

        return sortedPaid.map { sub in
            let monthly = monthlyCost(of: sub)
            let share = Int(((monthly / total) * 100).rounded())
            return ChartSlice(
                id: sub.id,
                name: sub.name,
                monthlyAmount: monthly,
                sharePercent: share,
                color: Color(hex: sub.colorHex)
            )
        }
    }

    private var priceChangedSubscriptions: [PriceChangeSummary] {
        subscriptions
            .filter { $0.priceHistory.count > 1 }
            .compactMap { sub -> PriceChangeSummary? in
                let sorted = sub.priceHistory.sorted { $0.date < $1.date }
                guard let first = sorted.first, let last = sorted.last else { return nil }
                let percent: Int? = first.price > 0
                    ? Int((((last.price - first.price) / first.price) * 100).rounded())
                    : nil
                return PriceChangeSummary(
                    id: sub.id,
                    name: sub.name,
                    iconName: sub.iconName,
                    colorHex: sub.colorHex,
                    firstPrice: first.price,
                    lastPrice: last.price,
                    lastDate: last.date,
                    percentChange: percent
                )
            }
            .sorted { $0.lastDate > $1.lastDate }
    }

    private var monthlyPlans: [Subscription] {
        paidSubscriptions.filter { $0.billingCycle != "yearly" }
    }

    private var yearlyPlans: [Subscription] {
        paidSubscriptions.filter { $0.billingCycle == "yearly" }
    }

    private var monthlyPlansLoad: Double {
        monthlyPlans.reduce(0) { $0 + monthlyCost(of: $1) }
    }

    private var yearlyPlansMonthlyLoad: Double {
        yearlyPlans.reduce(0) { $0 + monthlyCost(of: $1) }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(L10n.analyticsTitle)
                        .font(.title2.bold())

                    summaryRow
                    breakdownCard
                    priceChangesCard
                    planDistributionCard
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - 1. Summary Row

    private var summaryRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.analyticsMonthlyTotal)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("\(currencySymbol)\(formattedTotalPrice(totalMonthly))")
                    .font(.title3.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(L10n.activeSubscriptionsCount(paidSubscriptions.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .aeroCard()

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.analyticsYearlyTotal)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("\(currencySymbol)\(formattedTotalPrice(totalYearly))")
                    .font(.title3.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(
                    trialSubscriptions.isEmpty
                        ? L10n.noFreeTrials
                        : L10n.freeTrialsCount(trialSubscriptions.count)
                )
                .font(.caption)
                .foregroundStyle(trialSubscriptions.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(.orange))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .aeroCard()
        }
    }

    // MARK: - 2. Spending Breakdown Donut Chart

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.spendingBreakdown)
                .font(.headline.weight(.semibold))

            if chartSlices.isEmpty {
                Text(L10n.analyticsNoSpendingData)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart(chartSlices) { slice in
                    SectorMark(
                        angle: .value(L10n.amount, slice.monthlyAmount),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .cornerRadius(6)
                    .foregroundStyle(slice.color)
                }
                .chartLegend(.hidden)
                .frame(height: 190)
                .chartBackground { proxy in
                    GeometryReader { geometry in
                        if let plotFrame = proxy.plotFrame {
                            let frame = geometry[plotFrame]
                            VStack(spacing: 2) {
                                Text(L10n.monthly)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(currencySymbol)\(formattedTotalPrice(totalMonthly))")
                                    .font(.headline.weight(.bold))
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }

                VStack(spacing: 10) {
                    ForEach(Array(chartSlices.prefix(5).enumerated()), id: \.element.id) { index, slice in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 8, height: 8)

                            Text(slice.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)

                            Spacer()

                            Text("\(currencySymbol)\(formattedTotalPrice(slice.monthlyAmount))")
                                .font(.subheadline.weight(.semibold))

                            Text(L10n.percentage(slice.sharePercent))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 38, alignment: .trailing)
                        }

                        if index < min(chartSlices.count, 5) - 1 {
                            Divider().opacity(0.25)
                        }
                    }
                }
            }
        }
        .aeroCard()
    }

    // MARK: - 3. Price Changes

    private var priceChangesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.priceChanges)
                .font(.headline.weight(.semibold))

            if priceChangedSubscriptions.isEmpty {
                Text(L10n.noPriceChanges)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(priceChangedSubscriptions.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 8) {
                            Image(systemName: item.iconName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(hex: item.colorHex))
                                .frame(width: 20)

                            Text("\(item.name) • \(currencySymbol)\(formattedPrice(item.firstPrice)) → \(currencySymbol)\(formattedPrice(item.lastPrice))")
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer()

                            if let pct = item.percentChange {
                                Text("(\(L10n.percentageChange(pct)))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(pct > 0 ? Color.red : (pct < 0 ? Color.green : Color.secondary))
                            }
                        }

                        if index < priceChangedSubscriptions.count - 1 {
                            Divider().opacity(0.25)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aeroCard()
    }

    // MARK: - 4. Plan Distribution

    private var planDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.planDistribution)
                .font(.headline.weight(.semibold))

            VStack(spacing: 10) {
                planRow(
                    title: L10n.monthlyPlans,
                    count: monthlyPlans.count,
                    monthlyLoad: monthlyPlansLoad
                )

                Divider().opacity(0.25)

                planRow(
                    title: L10n.yearlyPlans,
                    count: yearlyPlans.count,
                    monthlyLoad: yearlyPlansMonthlyLoad
                )
            }
        }
        .aeroCard()
    }

    private func planRow(title: String, count: Int, monthlyLoad: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(L10n.planCount(count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(L10n.amountMonthly(formattedTotalPrice(monthlyLoad), currencySymbol))
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Helpers

    private func monthlyCost(of sub: Subscription) -> Double {
        sub.billingCycle == "yearly" ? (sub.price / 12) : sub.price
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

    // MARK: - Supporting Types

    private struct ChartSlice: Identifiable {
        let id: UUID
        let name: String
        let monthlyAmount: Double
        let sharePercent: Int
        let color: Color
    }

    private struct PriceChangeSummary: Identifiable {
        let id: UUID
        let name: String
        let iconName: String
        let colorHex: String
        let firstPrice: Double
        let lastPrice: Double
        let lastDate: Date
        let percentChange: Int?
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .preferredColorScheme(.dark)
}
