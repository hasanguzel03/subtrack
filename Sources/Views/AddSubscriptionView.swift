import PhotosUI
import SwiftData
import SwiftUI
import UIKit

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
    @State private var useCustomReminder: Bool = false
    @State private var customReminderDays: Int = 1
    @State private var hasLoadedInitialData: Bool = false

    // OCR screenshot import & voice dictation
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isScanning: Bool = false
    @State private var showVoiceDictation: Bool = false
    @State private var ocrWarningMessage: String?

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
                VStack(spacing: 16) {
                    if let warning = ocrWarningMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.orange)
                            Text(warning)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .aeroCard()
                    }

                    // 1. Name (Top) + Compact OCR Button
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.subscriptionName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Image(systemName: iconName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color(hex: colorHex))
                                .frame(width: 22)

                            TextField(L10n.namePlaceholder, text: $name)
                                .textInputAutocapitalization(.words)
                        }
                        .aeroCard()

                        if !isEditing {
                            HStack(spacing: 10) {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "doc.text.viewfinder")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text(L10n.scanFromScreenshot)
                                            .font(.subheadline.weight(.medium))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.78)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .frame(maxWidth: .infinity)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(.white.opacity(0.14), lineWidth: 1)
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .disabled(isScanning)

                                Button {
                                    showVoiceDictation = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "mic.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(Color(hex: 0xA855F7))
                                        Text(L10n.dictate)
                                            .font(.subheadline.weight(.medium))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(.white.opacity(0.14), lineWidth: 1)
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .disabled(isScanning)
                            }
                        }
                    }

                    // 2. Compact Single-Row Preset Menu
                    presetMenuRow

                    // 3. Price
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.amount)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        TextField("0", text: $priceText)
                            .keyboardType(.decimalPad)
                            .aeroCard()
                    }

                    // 4. Billing Cycle
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.period)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Picker(L10n.period, selection: $billingCycle) {
                            Text(L10n.monthly).tag("monthly")
                            Text(L10n.yearly).tag("yearly")
                        }
                        .pickerStyle(.segmented)
                        .aeroCard()
                    }

                    // 5. Free Trial Toggle
                    Toggle(isOn: Binding(
                        get: { isFreeTrial },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isFreeTrial = newValue
                                if newValue && !useCustomReminder {
                                    useCustomReminder = true
                                    customReminderDays = 1
                                }
                            }
                        }
                    )) {
                        Text(L10n.freeTrial)
                            .font(.subheadline.weight(.medium))
                    }
                    .aeroCard()

                    // 6. Easy Date Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isFreeTrial ? L10n.trialEndDate : L10n.nextBillingDate)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .animation(.easeInOut(duration: 0.25), value: isFreeTrial)

                        HStack(spacing: 10) {
                            quickDateButton(title: L10n.today, date: .now)
                            quickDateButton(
                                title: L10n.oneWeek,
                                date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: .now)!
                            )
                            quickDateButton(
                                title: L10n.oneMonth,
                                date: Calendar.current.date(byAdding: .month, value: 1, to: .now)!
                            )
                        }

                        DatePicker(
                            "",
                            selection: $nextBillingDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .aeroCard()
                    }

                    // 7. Custom Reminder
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.reminderLabel_field)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        reminderPicker
                    }

                    // 8. Manual Color Picker Row
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.iconColor)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

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
                                            .frame(width: 26, height: 26)

                                        if colorHex.caseInsensitiveCompare(hex) == .orderedSame {
                                            Circle()
                                                .stroke(Color.primary, lineWidth: 2)
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .aeroCard()
                    }

                    // 9. Price History (edit mode when > 1 record)
                    if let sub = subscriptionToEdit, sub.priceHistory.count > 1 {
                        priceHistorySection(records: sub.priceHistory)
                    }

                    // 10. Save
                    Button { save() } label: {
                        Text(L10n.save)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .aeroCard()
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)

                    // 11. Delete (edit mode)
                    if isEditing {
                        Button(role: .destructive) { delete() } label: {
                            Text(L10n.delete)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .aeroCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            if isScanning {
                scanningOverlay
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            scanScreenshot(from: newItem)
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
                if let custom = sub.customReminderDays {
                    useCustomReminder = true
                    customReminderDays = custom
                }
            } else if let prefilled = prefilledData {
                applyParsedSubscription(prefilled)
            }
        }
    }

    // MARK: - Preset Popup Menu

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
            .aeroCard()
        }
        .buttonStyle(.plain)
    }

    private func selectCatalogItem(_ item: ServiceCatalogItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            name = item.name
            iconName = item.iconName
            colorHex = item.colorHex
            billingCycle = item.defaultCycle

            let price = currencySymbol == "$" ? item.defaultPriceUSD : item.defaultPriceTRY
            priceText = formatPrice(price)
            ocrWarningMessage = nil
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
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reminder Picker

    private var reminderPicker: some View {
        VStack(spacing: 8) {
            Button {
                useCustomReminder = false
            } label: {
                HStack {
                    Text(L10n.reminderDefaultLabel(days: globalReminderDays))
                        .font(.body.weight(.medium))
                        .opacity(useCustomReminder ? 1 : 0.9)
                    Spacer()
                    if !useCustomReminder {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
                .aeroCard()
                .opacity(useCustomReminder ? 0.55 : 1)
            }
            .buttonStyle(.plain)

            ForEach([0, 1, 3, 7], id: \.self) { days in
                Button {
                    useCustomReminder = true
                    customReminderDays = days
                } label: {
                    HStack {
                        Text(L10n.reminderLabel(for: days))
                            .font(.body.weight(.medium))
                        Spacer()
                        if useCustomReminder && customReminderDays == days {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    }
                    .aeroCard()
                    .opacity(useCustomReminder && customReminderDays == days ? 1 : 0.55)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - OCR Scanning

    private var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.regular)
                Text(L10n.scanningScreenshot)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 200)
            .aeroCard()
        }
        .transition(.opacity)
    }

    private func scanScreenshot(from item: PhotosPickerItem) {
        isScanning = true
        ocrWarningMessage = nil

        Task {
            var parsedResult: ParsedSubscription?
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                parsedResult = try? await SubscriptionOCRManager.shared.recognizeText(from: image)
            }

            await MainActor.run {
                selectedPhotoItem = nil
                isScanning = false

                if let parsed = parsedResult, hasDetectedData(parsed) {
                    applyParsedSubscription(parsed)
                } else {
                    ocrWarningMessage = L10n.ocrNoDataFound
                }
            }
        }
    }

    private func hasDetectedData(_ parsed: ParsedSubscription) -> Bool {
        parsed.name != nil
            || parsed.price != nil
            || parsed.nextBillingDate != nil
            || parsed.isFreeTrial
            || parsed.billingCycle == "yearly"
    }

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
        if parsed.isFreeTrial {
            useCustomReminder = true
            customReminderDays = 1
        }
        ocrWarningMessage = nil
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
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
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
            .aeroCard()
        }
    }

    // MARK: - Actions

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let parsedPrice = parsePrice(priceText)
        let resolvedReminder: Int? = useCustomReminder ? customReminderDays : nil

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
