import SwiftUI
import UniformTypeIdentifiers

struct BillsView: View {
    @EnvironmentObject var store: BillsStore

    // Add form state
    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var dueDate: Date = Date()
    @State private var repeatMonthly: Bool = false
    @State private var currency: String = "PLN"

    // Edit
    @State private var editing: BillTemplate? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bills").font(.title).bold()
                
                Spacer()
                
                Button {
                    exportToCSV()
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .disabled(store.templates.isEmpty)
            }

            addSection

            existingSection

            Spacer()
        }
        .padding(16)
        .sheet(item: $editing) { tmpl in
            EditBillSheet(template: tmpl) { updated in
                store.updateTemplate(updated)
            } onDelete: { id in
                store.deleteTemplate(id: id)
            }
            .environmentObject(store)
        }
    }

    // MARK: - Sorting

    private func sortDate(for tmpl: BillTemplate) -> Date {
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

            if let thisMonth = cal.makeClampedDate(year: year, month: month, day: day) {
                if thisMonth >= startOfDay(now) {
                    return thisMonth
                }
            }

            let next = cal.date(byAdding: .month, value: 1, to: now) ?? now
            let ny = cal.component(.year, from: next)
            let nm = cal.component(.month, from: next)
            return cal.makeClampedDate(year: ny, month: nm, day: day) ?? .distantFuture
        }
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.app.startOfDay(for: date)
    }

    private var sortedTemplatesNewestFirst: [BillTemplate] {
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
                    TextField("Amount", text: $amountText)
                        .frame(width: 160)

                    TextField("Currency", text: $currency)
                        .frame(width: 70)

                    DatePicker("Due", selection: $dueDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()

                    Spacer()

                    Button("Add") { addBill() }
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
        && parseDecimal(amountText) != nil && parseDecimal(amountText)! > 0
        && !currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func parseDecimal(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        return Decimal(string: normalized)
    }

    private func addBill() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cur = currency.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let amount = parseDecimal(amountText), amount > 0, !cur.isEmpty else { return }

        if repeatMonthly {
            let day = Calendar.app.component(.day, from: dueDate)
            store.templates.append(.init(
                title: t,
                amount: amount,
                currency: cur,
                dueDay: day,
                dueDate: nil,
                recurrence: .monthly
            ))
        } else {
            store.templates.append(.init(
                title: t,
                amount: amount,
                currency: cur,
                dueDay: nil,
                dueDate: dueDate,
                recurrence: .once
            ))
        }

        // reset
        title = ""
        amountText = ""
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

    private func templateSubtitle(_ tmpl: BillTemplate) -> String {
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
    
    // MARK: - CSV Export
    
    private func exportToCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let currentMonthKey = Date().monthKey(calendar: Calendar.app)
        
        // Using semicolon as delimiter (European format with comma decimals)
        var csv = "Title;Amount;Currency;Recurrence;Due Day;Due Date;Paid This Month;Paid At\n"
        
        for tmpl in store.templates {
            let title = escapeCSV(tmpl.title)
            // Use comma as decimal separator
            let amount = "\(tmpl.amount)".replacingOccurrences(of: ".", with: ",")
            let currency = tmpl.currency
            let recurrence = tmpl.recurrence.rawValue
            let dueDay = tmpl.dueDay.map { String($0) } ?? ""
            let dueDate = tmpl.dueDate.map { dateFormatter.string(from: $0) } ?? ""
            
            // Get payment status for current month
            let status = store.statuses.first { $0.templateId == tmpl.id && $0.monthKey == currentMonthKey }
            let isPaid = status?.isPaid == true ? "Yes" : "No"
            let paidAt = status?.paidAt.map { dateFormatter.string(from: $0) } ?? ""
            
            csv += "\(title);\(amount);\(currency);\(recurrence);\(dueDay);\(dueDate);\(isPaid);\(paidAt)\n"
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "bills.csv"
        panel.title = "Export Bills"
        panel.message = "Choose where to save the CSV file"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
                print("[BillsView] Exported \(store.templates.count) bills to: \(url.path)")
            } catch {
                print("[BillsView] Export error: \(error)")
            }
        }
    }
    
    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

// MARK: - Edit Sheet

struct EditBillSheet: View {
    @Environment(\.dismiss) private var dismiss

    let template: BillTemplate
    let onSave: (BillTemplate) -> Void
    let onDelete: (UUID) -> Void

    @State private var title: String
    @State private var amountText: String
    @State private var currency: String
    @State private var dueDate: Date
    @State private var repeatMonthly: Bool

    init(template: BillTemplate, onSave: @escaping (BillTemplate) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.template = template
        self.onSave = onSave
        self.onDelete = onDelete

        _title = State(initialValue: template.title)
        _amountText = State(initialValue: "\(template.amount)")
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
                        TextField("Amount", text: $amountText)
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
        && parseDecimal(amountText) != nil && parseDecimal(amountText)! > 0
        && !currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func parseDecimal(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        return Decimal(string: normalized)
    }

    private func buildUpdatedTemplate() -> BillTemplate {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cur = currency.trimmingCharacters(in: .whitespacesAndNewlines)

        var updated = template
        updated.title = t
        updated.amount = parseDecimal(amountText) ?? template.amount
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
