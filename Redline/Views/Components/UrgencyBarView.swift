import SwiftUI

struct UrgencyBar: View {
    let dueDate: Date
    let isPaid: Bool

    // Config: how many days counts as "safe green"
    private let windowDays: Double = 30

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let (progress, color) = urgency()

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 10)

                RoundedRectangle(cornerRadius: 6)
                    .fill(isPaid ? Color.gray.opacity(0.35) : color.opacity(0.9))
                    .frame(width: max(0, width * progress), height: 10)
            }
        }
        .frame(height: 10)
        .accessibilityLabel("Urgency bar")
    }

    private func urgency() -> (Double, Color) {
        if isPaid { return (1.0, .gray) }

        let now = Date()
        let daysLeft = dueDate.timeIntervalSince(now) / 86400.0 // seconds -> days
        let clamped = min(max(daysLeft / windowDays, 0.0), 1.0)

        // progress: 1 = far (green), 0 = urgent (red)
        let progress = clamped

        // Color blend: green -> yellow -> red
        let t = 1.0 - clamped // 0 far, 1 urgent
        let color: Color
        if t < 0.5 {
            // green -> yellow
            color = blend(.green, .yellow, t / 0.5)
        } else {
            // yellow -> red
            color = blend(.yellow, .red, (t - 0.5) / 0.5)
        }
        return (progress, color)
    }

    private func blend(_ a: Color, _ b: Color, _ t: Double) -> Color {
        // SwiftUI Color blending is limited; for MVP this is OK.
        // If you want perfect blending, use NSColor and RGBA interpolation.
        return t < 0.5 ? a : b
    }
}
