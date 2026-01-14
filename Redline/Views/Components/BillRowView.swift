import SwiftUI

struct BillRowView: View {
    @EnvironmentObject var store: BillsStore
    let occ: BillOccurrence

    var body: some View {
        HStack(spacing: 10) {
            Button {
                store.setPaid(!occ.isPaid, templateId: occ.template.id, monthKey: occ.monthKey)
            } label: {
                Image(systemName: occ.isPaid ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(occ.template.title)
                    .lineLimit(1)

                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            UrgencyBarView(dueDate: occ.dueDate, isPaid: occ.isPaid, currentDay: store.currentDay)
                .frame(width: 110)
        }
        .padding(.vertical, 6)
    }

    private var subtitleText: String {
        let amountStr = AppFormatters.formatAmount(occ.template.amount)
        let dateStr = AppFormatters.formatShortDate(occ.dueDate)
        return "\(amountStr) \(CurrencyDisplay.short(occ.template.currency)) • due \(dateStr)"
    }
}
