import SwiftUI
import SwiftData

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
                    name = ""
                    iconName = "creditcard"
                    priceText = ""
                    billingCycle = "monthly"
                    nextBillingDate = .now
                    isFreeTrial = false
                    useCustomReminder = false
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

    // MARK: - Actions

    private func save() {
        let parsedPrice = parsePrice(priceText)
        let resolvedReminder: Int? = useCustomReminder ? customReminderDays : nil

        let targetSub: Subscription
        if let sub = subscriptionToEdit {
            sub.name = name.trimmingCharacters(in: .whitespaces)
            sub.price = parsedPrice
            sub.billingCycle = billingCycle
            sub.nextBillingDate = nextBillingDate
            sub.iconName = iconName
            sub.isFreeTrial = isFreeTrial
            sub.customReminderDays = resolvedReminder
            targetSub = sub
        } else {
            let newSub = Subscription(
                name: name.trimmingCharacters(in: .whitespaces),
                price: parsedPrice,
                billingCycle: billingCycle,
                nextBillingDate: nextBillingDate,
                iconName: iconName,
                isFreeTrial: isFreeTrial,
                customReminderDays: resolvedReminder
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
