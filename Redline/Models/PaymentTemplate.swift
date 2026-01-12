import SwiftUI
import Foundation

struct PaymentTemplate: Identifiable, Codable, Hashable {
    enum Recurrence: String, Codable { case monthly, once }

    var id: UUID = UUID()
    var title: String
    var amount: Decimal
    var currency: String = "PLN"

    /// monthly: which day of month (1...31)
    var dueDay: Int? = nil

    /// once: exact due date
    var dueDate: Date? = nil

    var recurrence: Recurrence = .monthly
}
