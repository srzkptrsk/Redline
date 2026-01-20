import SwiftUI

@main
struct RedlineApp: App {
    @StateObject private var store = BillsStore()
    @AppStorage("selectedSettingsTab") private var selectedTab: Int = 0

    var body: some Scene {
        MenuBarExtra {
            BillsPopoverView()
                .environmentObject(store)
                .frame(width: 420, height: 560)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        Settings {
            TabView(selection: $selectedTab) {
                BillsView()
                    .tabItem {
                        Label("Bills", systemImage: "calendar.badge.clock")
                    }
                    .tag(0)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(1)
            }
            .environmentObject(store)
            .frame(width: 640, height: 520)
        }
    }
    
    @ViewBuilder
    private var menuBarLabel: some View {
        if let icon = generateIcon(urgent: store.hasUrgentBills) {
            Image(nsImage: icon)
        } else {
            Image(systemName: "calendar")
        }
    }
    
    private func generateIcon(urgent: Bool) -> NSImage? {
        let config = NSImage.SymbolConfiguration(textStyle: .body, scale: .large)
        guard let baseImage = NSImage(systemSymbolName: "calendar", accessibilityDescription: nil)?.withSymbolConfiguration(config) else {
            return nil
        }
        
        // Define canvas size
        let size = baseImage.size
        
        let image = NSImage(size: size, flipped: false) { rect in
            baseImage.draw(in: rect)
            NSColor.labelColor.set()
            rect.fill(using: .sourceIn)
            let badgeSize: CGFloat = 9.0
            let x = size.width - badgeSize - 1
            let y = 0.0
            let badgeRect = NSRect(x: x, y: y, width: badgeSize, height: badgeSize)
            
            if urgent {
                NSColor.systemOrange.set()
                let path = NSBezierPath(ovalIn: badgeRect)
                path.fill()
            } else {
                if let clockImage = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil) {
                    let clockConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                    if let styledClock = clockImage.withSymbolConfiguration(clockConfig) {
                        styledClock.draw(in: badgeRect)
                        NSColor.labelColor.set()
                        badgeRect.fill(using: .sourceIn)
                    }
                }
            }
            return true
        }
        
        image.isTemplate = false
        return image
    }
}
