import SwiftUI

@main
struct RedlineApp: App {
    @StateObject private var store = PaymentsStore()

    var body: some Scene {
        MenuBarExtra("Redline", systemImage: "calendar.badge.clock") {
            PaymentsPopoverView()
                .environmentObject(store)
                .frame(width: 420, height: 560)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(store)
                .frame(width: 640, height: 520)
        }
    }
}
