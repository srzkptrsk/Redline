import SwiftUI
import AppKit

extension Color {
    /// Interpolates two colors in sRGB space.
    static func lerp(_ a: Color, _ b: Color, t: Double) -> Color {
        let t = min(max(t, 0), 1)

        let ca = NSColor(a).usingColorSpace(.sRGB) ?? .black
        let cb = NSColor(b).usingColorSpace(.sRGB) ?? .black

        var ra: CGFloat = 0, ga: CGFloat = 0, ba: CGFloat = 0, aa: CGFloat = 0
        var rb: CGFloat = 0, gb: CGFloat = 0, bb: CGFloat = 0, ab: CGFloat = 0
        ca.getRed(&ra, green: &ga, blue: &ba, alpha: &aa)
        cb.getRed(&rb, green: &gb, blue: &bb, alpha: &ab)

        let r = ra + (rb - ra) * CGFloat(t)
        let g = ga + (gb - ga) * CGFloat(t)
        let b = ba + (bb - ba) * CGFloat(t)
        let a = aa + (ab - aa) * CGFloat(t)

        return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}
