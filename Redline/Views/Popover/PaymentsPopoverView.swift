import SwiftUI

struct PaymentsPopoverView: View {
    @EnvironmentObject var store: PaymentsStore

    var body: some View {
        let now = Date()
        let current = MonthContext(date: now)
        let next = MonthContext(date: Calendar.current.date(byAdding: .month, value: 1, to: now)!)

        VStack(alignment: .leading, spacing: 12) {
            header

            Toggle("Hide paid", isOn: $store.hidePaid)
                .toggleStyle(.switch)

            monthSection(title: "This month", month: current)
            monthSection(title: "Next month", month: next)

            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private var header: some View {
        HStack {
            Text("Payments").font(.title2).bold()
            Spacer()
            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
        }
    }

    private func monthSection(title: String, month: MonthContext) -> some View {
        let occurrences = buildOccurrences(for: month)

        return VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)

            if occurrences.isEmpty {
                Text("No items").foregroundStyle(.secondary)
            } else {
                ForEach(occurrences) { occ in
                    PaymentRowView(occ: occ)
                }
            }
        }
    }

    private func buildOccurrences(for month: MonthContext) -> [PaymentOccurrence] {
        let cal = Calendar.current

        return store.templates
            .filter { tmpl in
                switch tmpl.recurrence {
                case .monthly: return true
                case .once:
                    // for MVP: show once items always in current+next;
                    // later: add specific month/year for once items.
                    return true
                }
            }
            .compactMap { tmpl -> PaymentOccurrence? in
                guard let due = month.makeDate(day: tmpl.dueDay) else { return nil }
                let paid = store.isPaid(templateId: tmpl.id, monthKey: month.key)
                return PaymentOccurrence(template: tmpl, monthKey: month.key, dueDate: due, isPaid: paid)
            }
            .filter { occ in
                !(store.hidePaid && occ.isPaid)
            }
            .sorted(by: { $0.dueDate < $1.dueDate })
    }
}

private struct MonthContext {
    let year: Int
    let month: Int
    let key: String // "YYYY-MM"

    init(date: Date) {
        let cal = Calendar.current
        year = cal.component(.year, from: date)
        month = cal.component(.month, from: date)
        key = String(format: "%04d-%02d", year, month)
    }

    func makeDate(day: Int) -> Date? {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = min(max(day, 1), 31)
        // If day doesn't exist (e.g., 31 in Feb), Calendar will return nil -> you can clamp to last day later.
        return cal.date(from: comps)
    }
}
