import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var subscriptionToEdit: Subscription?

    @State private var name: String = ""
    @State private var priceText: String = ""
    @State private var billingCycle: String = "monthly"
    @State private var nextBillingDate: Date = .now

    private var isEditing: Bool { subscriptionToEdit != nil }

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView {
                VStack(spacing: 16) {
                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Abonelik Adı")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        TextField("Örn: Netflix", text: $name)
                            .textInputAutocapitalization(.words)
                            .aeroCard()
                    }

                    // Price
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tutar")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        TextField("0", text: $priceText)
                            .keyboardType(.decimalPad)
                            .aeroCard()
                    }

                    // Billing Cycle
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Periyot")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        Picker("Periyot", selection: $billingCycle) {
                            Text("Aylık").tag("monthly")
                            Text("Yıllık").tag("yearly")
                        }
                        .pickerStyle(.segmented)
                        .aeroCard()
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sonraki Ödeme Tarihi")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "",
                            selection: $nextBillingDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .aeroCard()
                    }

                    // Save
                    Button {
                        save()
                    } label: {
                        Text("Kaydet")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .aeroCard()
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1)

                    // Delete (edit mode only)
                    if isEditing {
                        Button(role: .destructive) {
                            delete()
                        } label: {
                            Text("Sil")
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
        .onAppear {
            if let sub = subscriptionToEdit {
                name = sub.name
                priceText = formatPrice(sub.price)
                billingCycle = sub.billingCycle
                nextBillingDate = sub.nextBillingDate
            }
        }
    }

    // MARK: - Actions

    private func save() {
        let parsedPrice = parsePrice(priceText)

        if let sub = subscriptionToEdit {
            sub.name = name.trimmingCharacters(in: .whitespaces)
            sub.price = parsedPrice
            sub.billingCycle = billingCycle
            sub.nextBillingDate = nextBillingDate
        } else {
            let newSub = Subscription(
                name: name.trimmingCharacters(in: .whitespaces),
                price: parsedPrice,
                billingCycle: billingCycle,
                nextBillingDate: nextBillingDate
            )
            modelContext.insert(newSub)
        }

        dismiss()
    }

    private func delete() {
        if let sub = subscriptionToEdit {
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
