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
        if store.hasUrgentBills {
            Image(systemName: "calendar.badge.exclamationmark")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.orange, .primary)
        } else {
            Image(systemName: "calendar.badge.clock")
        }
    }
}
