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
                        Label("Bills", systemImage: "polishzlotysign.arrow.trianglehead.counterclockwise.rotate.90")
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
    
    // MARK: - Menu Bar Label
    
    @ViewBuilder
    private var menuBarLabel: some View {
        Image(nsImage: createMenuBarIcon())
    }
    
    // MARK: - Icon Generation
    
    private func createMenuBarIcon() -> NSImage {
        let symbolName = "polishzlotysign.circle.fill"
        let cleanRed = NSColor(red: 0.93, green: 0.26, blue: 0.31, alpha: 1.0)
        let cleanGreen = NSColor(red: 0.16, green: 0.75, blue: 0.47, alpha: 1.0)
        let color = store.hasUrgentBills ? cleanRed : cleanGreen

        let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            .applying(.init(paletteColors: [.white, color]))

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Bills")?
            .withSymbolConfiguration(config) ?? NSImage()
        image.isTemplate = false
        return image
    }
}
