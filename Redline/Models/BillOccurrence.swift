import SwiftUI

struct BillOccurrence: Identifiable, Hashable {
    var id: String { "\(template.id.uuidString)-\(monthKey)" }
    let template: BillTemplate
    let monthKey: String
    let dueDate: Date
    var isPaid: Bool
}
