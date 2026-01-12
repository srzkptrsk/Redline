import Foundation

extension Calendar {
    static let app = Calendar.current
}

extension Date {
    /// Returns "YYYY-MM" in the user's current calendar/timezone.
    func monthKey(calendar: Calendar = .app) -> String {
        let comps = calendar.dateComponents([.year, .month], from: self)
        let y = comps.year ?? 1970
        let m = comps.month ?? 1
        return String(format: "%04d-%02d", y, m)
    }
}

extension Calendar {
    /// Last day number in a given month (28..31)
    func lastDayOfMonth(year: Int, month: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month

        // first day of month
        let first = self.date(from: comps) ?? Date(timeIntervalSince1970: 0)
        // add 1 month, subtract 1 day
        let next = self.date(byAdding: .month, value: 1, to: first) ?? first
        let last = self.date(byAdding: .day, value: -1, to: next) ?? first
        return self.component(.day, from: last)
    }

    /// Builds a valid date for (year, month, day), clamping day to the last day of that month.
    func makeClampedDate(year: Int, month: Int, day: Int) -> Date? {
        let clampedDay = min(max(day, 1), lastDayOfMonth(year: year, month: month))
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = clampedDay
        // noon avoids DST edge weirdness around midnight in some locales
        comps.hour = 12
        return self.date(from: comps)
    }
}
