import SwiftUI

struct PaymentOccurrence: Identifiable, Hashable {
    var id: String { "\(template.id.uuidString)-\(monthKey)" }
    let template: PaymentTemplate
    let monthKey: String
    let dueDate: Date
    var isPaid: Bool
}
