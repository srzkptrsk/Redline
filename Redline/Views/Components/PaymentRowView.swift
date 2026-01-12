import SwiftUI

struct PaymentRowView: View {
    @EnvironmentObject var store: PaymentsStore
    let occ: PaymentOccurrence

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

                Text("\(formatAmount(occ.template.amount)) \(occ.template.currency) • due \(formatDate(occ.dueDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            UrgencyBar(dueDate: occ.dueDate, isPaid: occ.isPaid)
                .frame(width: 110)
        }
        .padding(.vertical, 6)
    }

    private func formatAmount(_ value: Decimal) -> String {
        let ns = value as NSDecimalNumber
        return ns.stringValue
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}
