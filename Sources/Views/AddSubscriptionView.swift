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

    // Phase: catalog picker vs detail form
    @State private var showDetailForm: Bool = false

    // Form fields
    @State private var name: String = ""
    @State private var iconName: String = "creditcard"
    @State private var priceText: String = ""
    @State private var billingCycle: String = "monthly"
    @State private var nextBillingDate: Date = .now
    @State private var isFreeTrial: Bool = false
    @State private var useCustomReminder: Bool = false
    @State private var customReminderDays: Int = 1

    // Catalog search
    @State private var searchText: String = ""

    // OCR screenshot import
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isScanning: Bool = false
    @State private var ocrWarningMessage: String?

    private var isEditing: Bool { subscriptionToEdit != nil }

    private var filteredCatalog: [ServiceCatalogItem] {
        if searchText.isEmpty { return serviceCatalog }
        return serviceCatalog.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AeroBackground()

            if isEditing || showDetailForm {
                detailFormView
            } else {
                catalogPickerView
            }

            if isScanning {
                scanningOverlay
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            scanScreenshot(from: newItem)
        }
        .onAppear {
            if let sub = subscriptionToEdit {
                name = sub.name
                iconName = sub.iconName
                priceText = formatPrice(sub.price)
                billingCycle = sub.billingCycle
                nextBillingDate = sub.nextBillingDate
                isFreeTrial = sub.isFreeTrial
                if let custom = sub.customReminderDays {
                    useCustomReminder = true
                    customReminderDays = custom
                }
                showDetailForm = true
            }
        }
    }

    // MARK: - Catalog Picker

    private var catalogPickerView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Scan from screenshot (PhotosPicker)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title3)
                            .frame(width: 28)
                            .foregroundStyle(.secondary)
                        Text(L10n.scanFromScreenshot)
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                    .aeroCard()
                }
                .buttonStyle(.plain)
                .disabled(isScanning)

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(L10n.searchPlaceholder, text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .aeroCard()

                // Catalog grid
                VStack(spacing: 10) {
                    ForEach(filteredCatalog) { item in
                        Button {
                            selectCatalogItem(item)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.iconName)
                                    .font(.title3)
                                    .frame(width: 28)
                                    .foregroundStyle(.secondary)
                                Text(item.name)
                                    .font(.body.weight(.medium))
                                Spacer()
                            }
                            .aeroCard()
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Custom subscription button
                Button {
                    resetFormFields()
                    ocrWarningMessage = nil
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDetailForm = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(L10n.customSubscription)
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                    .aeroCard()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
    }

    private func selectCatalogItem(_ item: ServiceCatalogItem) {
        name = item.name
        iconName = item.iconName
        billingCycle = item.defaultCycle

        let price = currencySymbol == "$" ? item.defaultPriceUSD : item.defaultPriceTRY
        priceText = formatPrice(price)

        nextBillingDate = .now
        isFreeTrial = false
        useCustomReminder = false

        withAnimation(.easeInOut(duration: 0.3)) {
            showDetailForm = true
        }
    }

    // MARK: - Detail Form

    private var detailFormView: some View {
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

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.subscriptionName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField(L10n.namePlaceholder, text: $name)
                        .textInputAutocapitalization(.words)
                        .aeroCard()
                }

                // Price
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.amount)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("0", text: $priceText)
                        .keyboardType(.decimalPad)
                        .aeroCard()
                }

                // Billing Cycle
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

                // Free Trial Toggle
                VStack(alignment: .leading, spacing: 6) {
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
                }

                // Date
                VStack(alignment: .leading, spacing: 6) {
                    Text(isFreeTrial ? L10n.trialEndDate : L10n.nextBillingDate)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .animation(.easeInOut(duration: 0.25), value: isFreeTrial)

                    // Quick date shortcuts
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

                // Reminder
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.reminderLabel_field)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    reminderPicker
                }

                // Price History (edit mode when > 1 record)
                if let sub = subscriptionToEdit, sub.priceHistory.count > 1 {
                    priceHistorySection(records: sub.priceHistory)
                }

                // Save
                Button { save() } label: {
                    Text(L10n.save)
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .aeroCard()
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1)

                // Delete (edit mode)
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
            // Default option
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

            // Custom options
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
                    resetFormFields()
                    ocrWarningMessage = L10n.ocrNoDataFound
                }

                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailForm = true
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
        name = parsed.name ?? ""
        iconName = parsed.iconName ?? "creditcard"
        priceText = parsed.price.map { formatPrice($0) } ?? ""
        billingCycle = parsed.billingCycle
        nextBillingDate = parsed.nextBillingDate ?? .now
        isFreeTrial = parsed.isFreeTrial
        if parsed.isFreeTrial {
            useCustomReminder = true
            customReminderDays = 1
        } else {
            useCustomReminder = false
        }
        ocrWarningMessage = nil
    }

    private func resetFormFields() {
        name = ""
        iconName = "creditcard"
        priceText = ""
        billingCycle = "monthly"
        nextBillingDate = .now
        isFreeTrial = false
        useCustomReminder = false
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
        let parsedPrice = parsePrice(priceText)
        let resolvedReminder: Int? = useCustomReminder ? customReminderDays : nil

        let targetSub: Subscription
        if let sub = subscriptionToEdit {
            let previousPrice = sub.price
            sub.name = name.trimmingCharacters(in: .whitespaces)
            sub.price = parsedPrice
            sub.billingCycle = billingCycle
            sub.nextBillingDate = nextBillingDate
            sub.iconName = iconName
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
                name: name.trimmingCharacters(in: .whitespaces),
                price: parsedPrice,
                billingCycle: billingCycle,
                nextBillingDate: nextBillingDate,
                iconName: iconName,
                isFreeTrial: isFreeTrial,
                customReminderDays: resolvedReminder,
                priceHistory: initialHistory
            )
            modelContext.insert(newSub)
            targetSub = newSub
        }

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
        }
        dismiss()
    }

    // MARK: - Price Helpers

    private func parsePrice(_ text: String) -> Double {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
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
