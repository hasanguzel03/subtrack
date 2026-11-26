import SwiftUI

struct SettingsView: View {
    @AppStorage("currencySymbol") private var currencySymbol = "₺"
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 1
    @Environment(\.dismiss) private var dismiss

    private let currencies = [
        ("₺", "TRY"),
        ("$", "USD"),
        ("€", "EUR"),
        ("£", "GBP"),
    ]

    private let reminderOptions = [
        ("Aynı Gün", 0),
        ("1 Gün Önce", 1),
        ("3 Gün Önce", 3),
        ("1 Hafta Önce", 7),
    ]

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Currency
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Para Birimi")
                            .font(.title3.bold())

                        VStack(spacing: 8) {
                            ForEach(currencies, id: \.0) { symbol, label in
                                Button {
                                    currencySymbol = symbol
                                } label: {
                                    HStack {
                                        Text(symbol)
                                            .font(.title3.bold())
                                            .frame(width: 32)
                                        Text(label)
                                            .font(.body.weight(.medium))
                                        Spacer()
                                        if currencySymbol == symbol {
                                            Image(systemName: "checkmark")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    .aeroCard()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Reminder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hatırlatma")
                            .font(.title3.bold())

                        VStack(spacing: 8) {
                            ForEach(reminderOptions, id: \.1) { title, days in
                                Button {
                                    reminderDaysBefore = days
                                } label: {
                                    HStack {
                                        Text(title)
                                            .font(.body.weight(.medium))
                                        Spacer()
                                        if reminderDaysBefore == days {
                                            Image(systemName: "checkmark")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    .aeroCard()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
