import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: PaymentsStore

    @State private var title: String = ""
    @State private var amountValue: Double = 0
    @State private var dueDay: Int = 20

    // macOS-friendly numeric formatter (supports comma in PL locale)
    private let amountFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        f.locale = Locale(identifier: "pl_PL") // comma decimal separator
        f.generatesDecimalNumbers = true
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings").font(.title).bold()

            GroupBox("Add payment") {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Title", text: $title)

                    // Variant B: numeric input via formatter (macOS)
                    TextField("Amount", value: $amountValue, formatter: amountFormatter)

                    Stepper("Due day: \(dueDay)", value: $dueDay, in: 1...31)

                    Button("Add") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        let dec = Decimal(amountValue)

                        store.templates.append(.init(title: trimmed, amount: dec, dueDay: dueDay))

                        // Reset form
                        title = ""
                        amountValue = 0
                        dueDay = 20
                    }
                }
                .padding(8)
            }

            GroupBox("Existing payments") {
                List {
                    ForEach(store.templates) { tmpl in
                        HStack {
                            Text(tmpl.title)
                            Spacer()
                            Text("\((tmpl.amount as NSDecimalNumber).stringValue) \(tmpl.currency)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { idx in store.templates.remove(atOffsets: idx) }
                }
            }

            Spacer()
        }
        .padding(16)
    }
}
