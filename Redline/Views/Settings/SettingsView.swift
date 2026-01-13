import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: PaymentsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings").font(.title).bold()
            
            GroupBox("Notifications") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Alert when bill is due within")
                        
                        Stepper("\(store.alertDays) days", value: $store.alertDays, in: 1...14)
                            .frame(width: 120)
                    }
                    
                    Text("Menu bar icon shows alert when unpaid bill is due within this period.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            GroupBox("Backups") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Keep backups for")
                        
                        Stepper("\(store.backupRetentionDays) days", value: $store.backupRetentionDays, in: 1...30)
                            .frame(width: 120)
                    }
                    
                    Text("Daily backups older than this will be automatically deleted.")
                        .font(.caption)
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
