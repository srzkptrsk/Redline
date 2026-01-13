import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings").font(.title).bold()
            
            GroupBox("General") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No settings available yet")
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .padding(16)
    }
}
