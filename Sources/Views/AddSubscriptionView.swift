import SwiftData
import SwiftUI

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @AppStorage("reminderDaysBefore") private var globalReminderDays = 1

    var subscriptionToEdit: Subscription?
    var prefilledData: ParsedSubscription? = nil

    // Form fields
    @State private var name: String = ""
    @State private var iconName: String = "creditcard"
    @State private var colorHex: String = "#A855F7"
    @State private var priceText: String = ""
    @State private var billingCycle: String = "monthly"
    @State private var nextBillingDate: Date = .now
    @State private var isFreeTrial: Bool = false
    @State private var customReminderDays: Int? = nil
    @State private var hasLoadedInitialData: Bool = false

    // Voice dictation
    @State private var showVoiceDictation: Bool = false

    private var isEditing: Bool { subscriptionToEdit != nil }

    private static let colorPalette: [String] = [
        "#A855F7", // Purple (Default)
        "#E50914", // Red
        "#1DB954", // Green
        "#007AFF", // Blue
        "#00C4CC", // Cyan
        "#F5C518", // Yellow
        "#EC4899"  // Pink
    ]

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // 1. Subscription Name + Inline Dictation Icon
                    HStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: iconName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color(hex: colorHex))
                                .frame(width: 22)

                            TextField(L10n.namePlaceholder, text: $name)
                                .textInputAutocapitalization(.words)
                        }
                        .frame(minHeight: 24)
                        .aeroCard(verticalPadding: 14)

                        if !isEditing {
                            Button {
                                showVoiceDictation = true
                            } label: {
                                Image(systemName: "mic.fill")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color(hex: 0xA855F7))
                                    .frame(minHeight: 24)
                                    .aeroCard(verticalPadding: 14, horizontalPadding: 0)
                                    .frame(width: 52)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 2. Preset Popup Menu + Compact Color Dots Row
                    presetMenuRow
                    colorPickerRow

                    // 3. Price | Free Trial (Side by Side)
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Text(currencySymbol)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)

                            TextField("0", text: $priceText)
                                .keyboardType(.decimalPad)
                                .font(.body.weight(.medium))
                        }
                        .frame(minHeight: 26)
                        .aeroCard(verticalPadding: 13)
                        .opacity(isFreeTrial ? 0.45 : 1)

                        HStack(spacing: 8) {
                            Text(L10n.trial)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(isFreeTrial ? Color.orange : Color.primary)

                            Toggle("", isOn: Binding(
                                get: { isFreeTrial },
                                set: { newValue in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isFreeTrial = newValue
                                        if newValue && customReminderDays == nil {
                                            customReminderDays = 1
                                        }
                                    }
                                }
                            ))
                            .labelsHidden()
                            .tint(.orange)
                        }
                        .frame(minHeight: 26)
                        .aeroCard(verticalPadding: 13, horizontalPadding: 14)
                        .fixedSize(horizontal: true, vertical: false)
                    }

                    // 4. Billing Cycle
                    Picker(L10n.period, selection: $billingCycle) {
                        Text(L10n.monthly).tag("monthly")
                        Text(L10n.yearly).tag("yearly")
                    }
                    .pickerStyle(.segmented)
                    .aeroCard(verticalPadding: 10, horizontalPadding: 12)

                    // 5. Compact Date Picker + Shortcut Chips
                    VStack(spacing: 10) {
                        HStack {
                            Text(isFreeTrial ? L10n.trialEndDate : L10n.nextBillingDate)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .animation(.easeInOut(duration: 0.2), value: isFreeTrial)

                            Spacer()

                            DatePicker(
                                "",
                                selection: $nextBillingDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }

                        HStack(spacing: 8) {
                            quickDateButton(title: L10n.today, date: .now)
                            quickDateButton(
                                title: L10n.oneWeekShort,
                                date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: .now)!
                            )
                            quickDateButton(
                                title: L10n.oneMonthShort,
                                date: Calendar.current.date(byAdding: .month, value: 1, to: .now)!
                            )
                        }
                    }
                    .aeroCard(verticalPadding: 12)

                    // 6. Single-Row Reminder Menu
                    reminderMenuRow

                    // 7. Price History (edit mode when > 1 record)
                    if let sub = subscriptionToEdit, sub.priceHistory.count > 1 {
                        priceHistorySection(records: sub.priceHistory)
                    }

                    // 8. Save
                    Button { save() } label: {
                        Text(L10n.save)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .aeroCard(verticalPadding: 14)
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)

                    // 9. Delete (edit mode)
                    if isEditing {
                        Button(role: .destructive) { delete() } label: {
                            Text(L10n.delete)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .aeroCard(verticalPadding: 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .fullScreenCover(isPresented: $showVoiceDictation) {
            VoiceDictationView { parsed in
                applyParsedSubscription(parsed)
            }
        }
        .onAppear {
            guard !hasLoadedInitialData else { return }
            hasLoadedInitialData = true

            if let sub = subscriptionToEdit {
                name = sub.name
                iconName = sub.iconName
                colorHex = sub.colorHex
                priceText = formatPrice(sub.price)
                billingCycle = sub.billingCycle
                nextBillingDate = sub.nextBillingDate
                isFreeTrial = sub.isFreeTrial
                customReminderDays = sub.customReminderDays
            } else if let prefilled = prefilledData {
                applyParsedSubscription(prefilled)
            }
        }
    }

    // MARK: - Preset & Color Row

    private var presetMenuRow: some View {
        Menu {
            ForEach(serviceCatalog) { item in
                Button {
                    selectCatalogItem(item)
                } label: {
                    Label {
                        Text(item.name)
                    } icon: {
                        Image(systemName: item.iconName)
                            .foregroundStyle(Color(hex: item.colorHex))
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.grid.2x2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(L10n.choosePreset)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .aeroCard(verticalPadding: 13)
        }
        .buttonStyle(.plain)
    }

    private var colorPickerRow: some View {
        HStack(spacing: 0) {
            ForEach(Self.colorPalette, id: \.self) { hex in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        colorHex = hex
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 22, height: 22)

                        if colorHex.caseInsensitiveCompare(hex) == .orderedSame {
                            Circle()
                                .stroke(Color.primary, lineWidth: 2)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .aeroCard(verticalPadding: 10)
    }

    private func selectCatalogItem(_ item: ServiceCatalogItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            name = item.name
            iconName = item.iconName
            colorHex = item.colorHex
            billingCycle = item.defaultCycle

            let price = currencySymbol == "$" ? item.defaultPriceUSD : item.defaultPriceTRY
            priceText = formatPrice(price)
        }
    }

    // MARK: - Quick Date Button

    private func quickDateButton(title: String, date: Date) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                nextBillingDate = date
            }
        } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reminder Popup Menu

    private var reminderMenuRow: some View {
        Menu {
            Button {
                customReminderDays = nil
            } label: {
                if customReminderDays == nil {
                    Label(L10n.reminderDefaultLabel(days: globalReminderDays), systemImage: "checkmark")
                } else {
                    Text(L10n.reminderDefaultLabel(days: globalReminderDays))
                }
            }

            ForEach([0, 1, 3, 7], id: \.self) { days in
                Button {
                    customReminderDays = days
                } label: {
                    if customReminderDays == days {
                        Label(L10n.reminderLabel(for: days), systemImage: "checkmark")
                    } else {
                        Text(L10n.reminderLabel(for: days))
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(L10n.reminderLabel_field)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(
                    customReminderDays.map { L10n.reminderLabel(for: $0) }
                        ?? L10n.reminderDefaultLabel(days: globalReminderDays)
                )
                .font(.subheadline.weight(.medium))
                .opacity(customReminderDays == nil ? 0.55 : 1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .aeroCard(verticalPadding: 13)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dictation Prefill

    private func applyParsedSubscription(_ parsed: ParsedSubscription) {
        if let parsedName = parsed.name {
            name = parsedName
        }
        iconName = parsed.iconName ?? "creditcard"
        colorHex = parsed.colorHex ?? "#A855F7"
        if let parsedPrice = parsed.price {
            priceText = formatPrice(parsedPrice)
        }
        billingCycle = parsed.billingCycle
        if let parsedDate = parsed.nextBillingDate {
            nextBillingDate = parsedDate
        }
        isFreeTrial = parsed.isFreeTrial
        if parsed.isFreeTrial && customReminderDays == nil {
            customReminderDays = 1
        }
    }

    // MARK: - Price History Section

    private struct PriceTransition: Identifiable {
        let id: UUID
        let date: Date
        let oldPrice: Double
        let newPrice: Double

        var percentChange: Int? {
            guard oldPrice > 0 else { return nil }
            return Int((((newPrice - oldPrice) / oldPrice) * 100).rounded())
        }
    }

    private func priceHistorySection(records: [PriceRecord]) -> some View {
        let sorted = records.sorted { $0.date < $1.date }
        let transitions: [PriceTransition] = Array(
            zip(sorted, sorted.dropFirst()).map { prev, curr in
                PriceTransition(id: curr.id, date: curr.date, oldPrice: prev.price, newPrice: curr.price)
            }.reversed()
        )

        return VStack(alignment: .leading, spacing: 6) {
            Text(L10n.priceHistory)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(Array(transitions.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.date, format: .dateTime.day().month(.abbreviated).year())
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(currencySymbol)\(formatPrice(item.oldPrice)) → \(currencySymbol)\(formatPrice(item.newPrice))")
                                .font(.subheadline.weight(.medium))
                        }

                        Spacer()

                        if let pct = item.percentChange {
                            Text(L10n.percentageChange(pct))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(pct > 0 ? Color.red : (pct < 0 ? Color.green : Color.secondary))
                        }
                    }

                    if index < transitions.count - 1 {
                        Divider().opacity(0.3)
                    }
                }
            }
            .aeroCard(verticalPadding: 12)
        }
    }

    // MARK: - Actions

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let parsedPrice = parsePrice(priceText)
        let resolvedReminder: Int? = customReminderDays

        let targetSub: Subscription
        if let sub = subscriptionToEdit {
            let previousPrice = sub.price
            sub.name = trimmedName
            sub.price = parsedPrice
            sub.billingCycle = billingCycle
            sub.nextBillingDate = nextBillingDate
            sub.iconName = iconName
            sub.colorHex = colorHex
            sub.isFreeTrial = isFreeTrial
            sub.customReminderDays = resolvedReminder

            if abs(previousPrice - parsedPrice) > 0.0001 {
                if sub.priceHistory.isEmpty {
                    sub.priceHistory.append(PriceRecord(price: previousPrice, date: sub.createdAt))
                }
                sub.priceHistory.append(PriceRecord(price: parsedPrice, date: .now))
            }

            targetSub = sub
        } else {
            let initialHistory = [PriceRecord(price: parsedPrice, date: .now)]
            let newSub = Subscription(
                name: trimmedName,
                price: parsedPrice,
                billingCycle: billingCycle,
                nextBillingDate: nextBillingDate,
                iconName: iconName,
                colorHex: colorHex,
                isFreeTrial: isFreeTrial,
                customReminderDays: resolvedReminder,
                priceHistory: initialHistory
            )
            modelContext.insert(newSub)
            targetSub = newSub
        }

        try? modelContext.save()

        NotificationManager.shared.scheduleNotification(
            for: targetSub,
            defaultReminderDays: globalReminderDays,
            currencySymbol: currencySymbol
        )

        dismiss()
    }

    private func delete() {
        if let sub = subscriptionToEdit {
            NotificationManager.shared.cancelNotification(for: sub)
            modelContext.delete(sub)
            try? modelContext.save()
        }
        dismiss()
    }

    // MARK: - Price Helpers

    private func parsePrice(_ text: String) -> Double {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isNumber || $0 == "," || $0 == "." }

        guard !cleaned.isEmpty else { return 0 }

        let dotCount = cleaned.filter { $0 == "." }.count
        let commaCount = cleaned.filter { $0 == "," }.count

        let normalized: String
        if dotCount > 0 && commaCount > 0 {
            if let lastDot = cleaned.lastIndex(of: "."),
               let lastComma = cleaned.lastIndex(of: ",") {
                if lastComma > lastDot {
                    normalized = cleaned
                        .replacingOccurrences(of: ".", with: "")
                        .replacingOccurrences(of: ",", with: ".")
                } else {
                    normalized = cleaned.replacingOccurrences(of: ",", with: "")
                }
            } else {
                normalized = cleaned.replacingOccurrences(of: ",", with: ".")
            }
        } else {
            normalized = cleaned.replacingOccurrences(of: ",", with: ".")
        }

        return Double(normalized) ?? 0
    }

    private func formatPrice(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }
}

#Preview {
    AddSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .preferredColorScheme(.dark)
}
