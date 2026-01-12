import Foundation

enum AppFormatters {
    static let amount: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        f.locale = Locale(identifier: "pl_PL")
        f.generatesDecimalNumbers = true
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()
}

enum CurrencyDisplay {
    static func short(_ code: String) -> String {
        switch code.uppercased() {
        case "PLN": return "zł"
        default: return code
        }
    }
}
