import SwiftUI

struct BillsView: View {
    @EnvironmentObject var store: PaymentsStore

    // Add form state
    @State private var title: String = ""
    @State private var amountValue: Double = 0
    @State private var dueDate: Date = Date()
    @State private var repeatMonthly: Bool = false
    @State private var currency: String = "PLN"

    // Edit
    @State private var editing: PaymentTemplate? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bills").font(.title).bold()

            addSection

            existingSection

            Spacer()
        }
        .padding(16)
        .sheet(item: $editing) { tmpl in
            EditPaymentSheet(template: tmpl) { updated in
                store.updateTemplate(updated)
            } onDelete: { id in
                store.deleteTemplate(id: id)
            }
            .environmentObject(store)
        }
    }

    // MARK: - Sorting

    /// Returns a "next due date" for sorting:
    /// - once: exact dueDate
    /// - monthly: next occurrence (this month if day not passed; otherwise next month)
    private func sortDate(for tmpl: PaymentTemplate) -> Date {
        let cal = Calendar.app
        let now = Date()

        switch tmpl.recurrence {
        case .once:
            return tmpl.dueDate ?? .distantFuture

        case .monthly:
            let day = tmpl.dueDay ?? 1
            let comps = cal.dateComponents([.year, .month, .day], from: now)
            let year = comps.year ?? 1970
            let month = comps.month ?? 1

            // try this month
            if let thisMonth = cal.makeClampedDate(year: year, month: month, day: day) {
                // if it's still ahead (or today), use it; otherwise use next month
                if thisMonth >= startOfDay(now) {
                    return thisMonth
                }
            }

            // next month
            let next = cal.date(byAdding: .month, value: 1, to: now) ?? now
            let ny = cal.component(.year, from: next)
            let nm = cal.component(.month, from: next)
            return cal.makeClampedDate(year: ny, month: nm, day: day) ?? .distantFuture
        }
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.app.startOfDay(for: date)
    }

    /// Newest first (so old entries go to the bottom)
    private var sortedTemplatesNewestFirst: [PaymentTemplate] {
        store.templates.sorted { a, b in
            let da = sortDate(for: a)
            let db = sortDate(for: b)
            if da != db { return da > db }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    // MARK: - Add

    private var addSection: some View {
        GroupBox("Add bill") {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Title", text: $title)

                HStack(spacing: 10) {
                    TextField("Amount", value: $amountValue, format: .number.precision(.fractionLength(0...2)))
                        .frame(width: 160)

                    TextField("Currency", text: $currency)
                        .frame(width: 70)

                    DatePicker("Due", selection: $dueDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()

                    Spacer()

                    Button("Add") { addPayment() }
                        .disabled(!canAdd)
                }

                Toggle("Repeat monthly", isOn: $repeatMonthly)
                    .toggleStyle(.switch)
            }
            .padding(8)
        }
    }

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && amountValue > 0
        && !currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addPayment() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cur = currency.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, amountValue > 0, !cur.isEmpty else { return }

        if repeatMonthly {
            let day = Calendar.app.component(.day, from: dueDate)
            store.templates.append(.init(
                title: t,
                amount: Decimal(amountValue),
                currency: cur,
                dueDay: day,
                dueDate: nil,
                recurrence: .monthly
            ))
        } else {
            store.templates.append(.init(
                title: t,
                amount: Decimal(amountValue),
                currency: cur,
                dueDay: nil,
                dueDate: dueDate,
                recurrence: .once
            ))
        }

        // reset
        title = ""
        amountValue = 0
        dueDate = Date()
        repeatMonthly = false
        currency = "PLN"
    }

    // MARK: - Existing

    private var existingSection: some View {
        GroupBox("Your bills") {
            List {
                ForEach(sortedTemplatesNewestFirst) { tmpl in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tmpl.title)

                            Text(templateSubtitle(tmpl))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            editing = tmpl
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                        .help("Edit")

                        Button(role: .destructive) {
                            store.deleteTemplate(id: tmpl.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Delete")
                    }
                    .contextMenu {
                        Button("Edit") { editing = tmpl }
                        Divider()
                        Button("Delete", role: .destructive) {
                            store.deleteTemplate(id: tmpl.id)
                        }
                    }
                }
            }
            .frame(minHeight: 220)
        }
    }

    private func templateSubtitle(_ tmpl: PaymentTemplate) -> String {
        let amountStr = AppFormatters.formatAmount(tmpl.amount)

        let dueStr: String
        switch tmpl.recurrence {
        case .monthly:
            let d = tmpl.dueDay ?? 1
            dueStr = "monthly, day \(d)"
        case .once:
            let date = tmpl.dueDate ?? Date()
            dueStr = "once, \(AppFormatters.formatShortDate(date))"
        }

        return "\(amountStr) \(CurrencyDisplay.short(tmpl.currency)) • \(dueStr)"
    }
}

// MARK: - Edit Sheet

struct EditPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let template: PaymentTemplate
    let onSave: (PaymentTemplate) -> Void
    let onDelete: (UUID) -> Void

    @State private var title: String
    @State private var amountValue: Double
    @State private var currency: String
    @State private var dueDate: Date
    @State private var repeatMonthly: Bool

    init(template: PaymentTemplate, onSave: @escaping (PaymentTemplate) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.template = template
        self.onSave = onSave
        self.onDelete = onDelete

        _title = State(initialValue: template.title)
        _amountValue = State(initialValue: (template.amount as NSNumber).doubleValue)
        _currency = State(initialValue: template.currency)

        if template.recurrence == .once, let d = template.dueDate {
            _dueDate = State(initialValue: d)
            _repeatMonthly = State(initialValue: false)
        } else {
            let day = template.dueDay ?? Calendar.app.component(.day, from: Date())
            _dueDate = State(initialValue: Calendar.app.makeClampedDate(
                year: Calendar.app.component(.year, from: Date()),
                month: Calendar.app.component(.month, from: Date()),
                day: day
            ) ?? Date())
            _repeatMonthly = State(initialValue: true)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Edit bill").font(.title2).bold()

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Title", text: $title)

                    HStack(spacing: 10) {
                        TextField("Amount", value: $amountValue, format: .number.precision(.fractionLength(0...2)))
                            .frame(width: 160)

                        TextField("Currency", text: $currency)
                            .frame(width: 70)

                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()

                        Spacer()
                    }

                    Toggle("Repeat monthly", isOn: $repeatMonthly)
                        .toggleStyle(.switch)
                }
                .padding(8)
            }

            HStack {
                Button("Delete", role: .destructive) {
                    onDelete(template.id)
                    dismiss()
                }

                Spacer()

                Button("Cancel") { dismiss() }

                Button("Save") {
                    let updated = buildUpdatedTemplate()
                    onSave(updated)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 560, height: 260)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && amountValue > 0
        && !currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func buildUpdatedTemplate() -> PaymentTemplate {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cur = currency.trimmingCharacters(in: .whitespacesAndNewlines)

        var updated = template
        updated.title = t
        updated.amount = Decimal(amountValue)
        updated.currency = cur

        if repeatMonthly {
            updated.recurrence = .monthly
            updated.dueDay = Calendar.app.component(.day, from: dueDate)
            updated.dueDate = nil
        } else {
            updated.recurrence = .once
            updated.dueDate = dueDate
            updated.dueDay = nil
        }

        return updated
    }
}
