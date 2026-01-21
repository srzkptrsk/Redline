import SwiftUI

struct BillsPopoverView: View {
    @EnvironmentObject var store: BillsStore
    @Environment(\.openSettings) private var openSettingsAction

    // MARK: - Quick Add state

    @State private var isQuickAddExpanded: Bool = false
    @State private var quickTitle: String = ""
    @State private var quickAmountText: String = ""
    @State private var quickDueDate: Date = Date()
    @State private var quickRepeatMonthly: Bool = false

    private enum QuickField: Hashable { case title, amount }
    @FocusState private var quickFocus: QuickField?

    // MARK: - Bring to front

    private func bringAppToFront() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)

            for w in NSApp.windows where w.isVisible {
                w.makeKeyAndOrderFront(nil)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        let now = Date()
        let currentDate = now
        let nextDate = Calendar.app.date(byAdding: .month, value: 1, to: now) ?? now

        VStack(alignment: .leading, spacing: 12) {
            header

            quickAddSection

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    monthSection(title: "This month", monthDate: currentDate)
                    monthSection(title: "Next month", monthDate: nextDate)
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: .infinity)

            footer
        }
        .padding(14)
        .frame(width: 420, height: 560)
        .onAppear {
            bringAppToFront()
        }
        .onChange(of: isQuickAddExpanded) { _, expanded in
            if expanded {
                bringAppToFront()
                DispatchQueue.main.async { quickFocus = .title }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Bills")
                .font(.title2)
                .bold()

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit")
        }
    }

    // MARK: - Quick Add

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isQuickAddExpanded.toggle()
                }
                if isQuickAddExpanded {
                    bringAppToFront()
                    DispatchQueue.main.async { quickFocus = .title }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isQuickAddExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.15), value: isQuickAddExpanded)

                    Text("Quick Add")
                        .font(.headline)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isQuickAddExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Title", text: $quickTitle)
                        .focused($quickFocus, equals: .title)
                        .onSubmit { quickFocus = .amount }

                    HStack(spacing: 10) {
                        TextField("Amount", text: $quickAmountText)
                            .focused($quickFocus, equals: .amount)
                            .frame(width: 140)
                            .onChange(of: quickFocus) { _, newValue in
                                guard newValue == .amount else { return }
                                let cleaned = normalizeAmountText(quickAmountText)
                                if cleaned == "0" || cleaned == "0.0" || cleaned == "0.00" {
                                    quickAmountText = ""
                                }
                            }
                            .onSubmit { addQuickBill() }

                        DatePicker("Due", selection: $quickDueDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()

                        Spacer()

                        Button("Add") { addQuickBill() }
                            .disabled(!canQuickAdd)
                    }

                    Toggle("Repeat monthly", isOn: $quickRepeatMonthly)
                        .toggleStyle(.switch)
                }
                .padding(.leading, 22)
                .padding(.top, 4)
            }
        }
    }

    private var canQuickAdd: Bool {
        let t = quickTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t.isEmpty && (parseAmount(quickAmountText) ?? 0) > 0
    }

    private func addQuickBill() {
        let title = quickTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        guard let amount = parseAmount(quickAmountText), amount > 0 else { return }

        if quickRepeatMonthly {
            let day = Calendar.app.component(.day, from: quickDueDate)
            store.templates.append(.init(
                title: title,
                amount: amount,
                currency: "PLN",
                dueDay: day,
                dueDate: nil,
                recurrence: .monthly
            ))
        } else {
            store.templates.append(.init(
                title: title,
                amount: amount,
                currency: "PLN",
                dueDay: nil,
                dueDate: quickDueDate,
                recurrence: .once
            ))
        }

        // reset
        quickTitle = ""
        quickAmountText = ""
        quickDueDate = Date()
        quickRepeatMonthly = false

        DispatchQueue.main.async { quickFocus = .title }
    }

    private func normalizeAmountText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
    }

    private func parseAmount(_ text: String) -> Decimal? {
        let normalized = normalizeAmountText(text)
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized)
    }

    // MARK: - Months list

    private func monthSection(title: String, monthDate: Date) -> some View {
        let all = buildOccurrences(forMonth: monthDate, ignoreHidePaid: true)
        let visible = buildOccurrences(forMonth: monthDate, ignoreHidePaid: false)

        let totals = totalsForMonth(occurrences: all)
        let titleWithAmounts = totals.total > 0
            ? "\(title) (\(formatMoney(totals.paid)) / \(formatMoney(totals.total)) \(CurrencyDisplay.short(totals.currency)))"
            : title

        return VStack(alignment: .leading, spacing: 8) {
            Text(titleWithAmounts).font(.headline)

            if visible.isEmpty {
                if all.isEmpty {
                    Text("No items").foregroundStyle(.secondary)
                } else {
                    Text("No bills in this month. \(all.count) bills are paid.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(visible) { occ in
                    BillRowView(occ: occ)
                }
            }
        }
    }

    private func buildOccurrences(forMonth date: Date, ignoreHidePaid: Bool) -> [BillOccurrence] {
        let cal = Calendar.app
        let comps = cal.dateComponents([.year, .month], from: date)
        let year = comps.year ?? 1970
        let month = comps.month ?? 1
        let monthKey = date.monthKey(calendar: cal)

        let all = store.templates.compactMap { tmpl -> BillOccurrence? in
            switch tmpl.recurrence {
            case .monthly:
                let day = tmpl.dueDay ?? 1
                guard let due = cal.makeClampedDate(year: year, month: month, day: day) else { return nil }
                let paid = store.isPaid(templateId: tmpl.id, monthKey: monthKey)
                return BillOccurrence(template: tmpl, monthKey: monthKey, dueDate: due, isPaid: paid)

            case .once:
                guard let exact = tmpl.dueDate else { return nil }
                guard exact.monthKey(calendar: cal) == monthKey else { return nil }
                let paid = store.isPaid(templateId: tmpl.id, monthKey: monthKey)
                return BillOccurrence(template: tmpl, monthKey: monthKey, dueDate: exact, isPaid: paid)
            }
        }
        .filter { occ in
            ignoreHidePaid ? true : !(store.hidePaid && occ.isPaid)
        }
        .sorted { a, b in
            if a.isPaid != b.isPaid { return !a.isPaid }
            return a.dueDate < b.dueDate
        }

        return all
    }

    private func totalsForMonth(occurrences: [BillOccurrence]) -> (paid: Decimal, total: Decimal, currency: String) {
        let currency = occurrences.first?.template.currency ?? "PLN"
        var total: Decimal = 0
        var paid: Decimal = 0

        for occ in occurrences {
            total += occ.template.amount
            if occ.isPaid { paid += occ.template.amount }
        }

        return (paid, total, currency)
    }

    private func formatMoney(_ value: Decimal) -> String {
        AppFormatters.formatAmount(value)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button {
                UserDefaults.standard.set(0, forKey: "selectedSettingsTab")
                openSettings()
            } label: {
                Label("Bills", systemImage: "calendar.badge.clock")
            }
            .font(.caption)
            
            Button {
                UserDefaults.standard.set(1, forKey: "selectedSettingsTab")
                openSettings()
            } label: {
                Label("Settings", systemImage: "gear")
            }
            .font(.caption)

            Spacer()

            Toggle("Hide paid", isOn: $store.hidePaid)
                .toggleStyle(.switch)
        }
    }
    
    private func openSettings() {
        openSettingsAction()
    }
}
