import SwiftUI

struct PaymentMonthStatus: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var monthKey: String // "YYYY-MM"
    var templateId: UUID
    var isPaid: Bool
    var paidAt: Date?
}
