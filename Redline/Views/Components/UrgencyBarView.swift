import SwiftUI

struct UrgencyBarView: View {
    enum LabelPlacement { case left, center, right }

    let dueDate: Date
    let isPaid: Bool
    var windowDays: Double = 30
    var labelPlacement: LabelPlacement = .center

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let u = urgency()

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 6)
                    .fill(isPaid ? Color.gray.opacity(0.35) : u.color.opacity(0.95))
                    .frame(width: max(0, width * u.progress), height: 12)

                // ✅ days label overlay
                labelView
                    .frame(height: 12)
            }
        }
        .frame(height: 12)
        .accessibilityLabel("Urgency bar")
    }

    private var labelView: some View {
        let text = daysLabelText()

        return HStack {
            if labelPlacement == .left {
                labelPill(text)
                Spacer()
            } else if labelPlacement == .right {
                Spacer()
                labelPill(text)
            } else {
                Spacer()
                labelPill(text)
                Spacer()
            }
        }
        .padding(.horizontal, 6)
    }

    private func labelPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(.primary.opacity(0.85))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(.thinMaterial, in: Capsule())
    }

    private func daysLabelText() -> String {
        if isPaid { return "✓" }

        let cal = Calendar.app
        let today = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: dueDate)

        let diffDays = cal.dateComponents([.day], from: today, to: due).day ?? 0

        if diffDays == 0 { return "today" }
        if diffDays > 0 { return "\(diffDays)d" }
        return "\(diffDays)d" // negative => overdue, e.g. "-3d"
    }

    private func urgency() -> (progress: Double, color: Color) {
        if isPaid {
            return (1.0, .gray)
        }

        let now = Date()
        let daysLeft = dueDate.timeIntervalSince(now) / 86400.0
        let normalized = min(max(daysLeft / windowDays, 0.0), 1.0)

        // 1.0 far away (green), 0.0 urgent (red)
        let progress = normalized
        let t = 1.0 - normalized

        let color: Color
        if t < 0.5 {
            color = .lerp(.green, .yellow, t: t / 0.5)
        } else {
            color = .lerp(.yellow, .red, t: (t - 0.5) / 0.5)
        }
        return (progress, color)
    }
}
