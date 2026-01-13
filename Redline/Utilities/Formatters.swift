import Foundation

enum AppFormatters {
    /// Modern Decimal format style for amounts (Polish locale)
    static func formatAmount(_ value: Decimal) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(0...2))
                .locale(Locale(identifier: "pl_PL"))
        )
    }
    
    /// Modern Date format style for short dates like "14 Jan"
    static func formatShortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }
}

enum CurrencyDisplay {
    static func short(_ code: String) -> String {
        switch code.uppercased() {
        case "PLN": return "zł"
        default: return code
        }
    }
}
