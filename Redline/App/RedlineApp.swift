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
        if let icon = createMenuBarIcon() {
            Image(nsImage: icon)
        } else {
            // Fallback to system image
            Image(systemName: "polishzlotysign.arrow.trianglehead.counterclockwise.rotate.90")
                .foregroundColor(store.hasUrgentBills ? .red : .primary)
        }
    }
    
    // MARK: - Icon Generation
    
    private func createMenuBarIcon() -> NSImage? {
        let symbolName = "polishzlotysign.arrow.trianglehead.counterclockwise.rotate.90"
        
        // Use hierarchical rendering for two-tone coloring
        if store.hasUrgentBills {
            return createHierarchicalIcon(symbolName: symbolName, primaryColor: .labelColor, secondaryColor: .systemRed)
        } else {
            return createStandardIcon(symbolName: symbolName)
        }
    }
    
    private func createHierarchicalIcon(symbolName: String, primaryColor: NSColor, secondaryColor: NSColor) -> NSImage? {
        let paletteConfig = NSImage.SymbolConfiguration(paletteColors: [primaryColor, secondaryColor])
        let sizeConfig = NSImage.SymbolConfiguration(textStyle: .body, scale: .large)
        let combinedConfig = sizeConfig.applying(paletteConfig)
        
        guard let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "Bills"
        )?.withSymbolConfiguration(combinedConfig) else {
            return nil
        }
        
        image.isTemplate = false
        return image
    }
    
    private func createStandardIcon(symbolName: String) -> NSImage? {
        let config = NSImage.SymbolConfiguration(textStyle: .body, scale: .large)
        
        guard let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "Bills"
        )?.withSymbolConfiguration(config) else {
            return nil
        }
        
        image.isTemplate = true
        return image
    }
}
