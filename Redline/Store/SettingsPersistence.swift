import Foundation

struct SettingsPersistence {
    struct Settings: Codable {
        var hidePaid: Bool
        var alertDays: Int
        var backupRetentionDays: Int
        
        init(hidePaid: Bool = false, alertDays: Int = 3, backupRetentionDays: Int = 7) {
            self.hidePaid = hidePaid
            self.alertDays = alertDays
            self.backupRetentionDays = backupRetentionDays
        }
    }
    
    private let fileName = "settings.json"
    
    private var directoryName: String {
        Bundle.main.bundleIdentifier ?? "Redline"
    }
    
    private var directoryURL: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private var fileURL: URL {
        directoryURL.appendingPathComponent(fileName)
    }
    
    func load() -> Settings {
        print("[SettingsPersistence] Loading from: \(fileURL.path)")
        guard let data = try? Data(contentsOf: fileURL) else {
            print("[SettingsPersistence] No settings file, using defaults")
            return Settings()
        }
        
        do {
            let result = try JSONDecoder().decode(Settings.self, from: data)
            print("[SettingsPersistence] Loaded settings")
            return result
        } catch {
            print("[SettingsPersistence] Decode error: \(error), using defaults")
            return Settings()
        }
    }
    
    func save(_ settings: Settings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            print("[SettingsPersistence] Failed to encode settings")
            return
        }
        
        do {
            try data.write(to: fileURL, options: [.atomic])
            print("[SettingsPersistence] Saved settings")
        } catch {
            print("[SettingsPersistence] Save error: \(error)")
        }
    }
}
