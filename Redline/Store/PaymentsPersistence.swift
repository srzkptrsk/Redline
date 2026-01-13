import Foundation

struct PaymentsPersistence {
    struct Persisted: Codable {
        var templates: [PaymentTemplate]
        var statuses: [PaymentMonthStatus]
        
        // Backwards compatibility: ignore settings fields from old JSON
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            templates = try container.decode([PaymentTemplate].self, forKey: .templates)
            statuses = try container.decode([PaymentMonthStatus].self, forKey: .statuses)
        }
        
        init(templates: [PaymentTemplate], statuses: [PaymentMonthStatus]) {
            self.templates = templates
            self.statuses = statuses
        }
        
        private enum CodingKeys: String, CodingKey {
            case templates, statuses
        }
    }
    
    private let fileName = "payments.json"
    
    private var directoryName: String {
        Bundle.main.bundleIdentifier ?? "Redline"
    }
    
    var directoryURL: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private var fileURL: URL {
        directoryURL.appendingPathComponent(fileName)
    }
    
    func load() -> Persisted? {
        print("[PaymentsPersistence] Loading from: \(fileURL.path)")
        guard let data = try? Data(contentsOf: fileURL) else {
            print("[PaymentsPersistence] No data file found")
            return nil
        }
        
        do {
            let result = try JSONDecoder().decode(Persisted.self, from: data)
            print("[PaymentsPersistence] Loaded \(result.templates.count) templates")
            return result
        } catch {
            print("[PaymentsPersistence] Decode error: \(error)")
            // Create backup of corrupted/legacy file for recovery
            let backupURL = directoryURL.appendingPathComponent("payments.legacy.json")
            try? data.write(to: backupURL, options: [.atomic])
            print("[PaymentsPersistence] Legacy backup saved to: \(backupURL.path)")
            return nil
        }
    }
    
    func save(_ payload: Persisted, retentionDays: Int) {
        let fm = FileManager.default
        
        // Create daily backup with date in filename
        createDailyBackup(fm: fm)
        
        // Cleanup old backups
        cleanupOldBackups(fm: fm, retentionDays: retentionDays)
        
        guard let data = try? JSONEncoder().encode(payload) else {
            print("[PaymentsPersistence] Failed to encode payload")
            return
        }
        
        do {
            try data.write(to: fileURL, options: [.atomic])
            print("[PaymentsPersistence] Saved \(payload.templates.count) templates")
        } catch {
            print("[PaymentsPersistence] Save error: \(error)")
        }
    }
    
    private func createDailyBackup(fm: FileManager) {
        guard fm.fileExists(atPath: fileURL.path) else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let backupName = "payments.\(dateString).json"
        let backupURL = directoryURL.appendingPathComponent(backupName)
        
        // Only create backup if it doesn't exist for today
        if !fm.fileExists(atPath: backupURL.path) {
            try? fm.copyItem(at: fileURL, to: backupURL)
            print("[PaymentsPersistence] Daily backup created: \(backupName)")
        }
    }
    
    private func cleanupOldBackups(fm: FileManager, retentionDays: Int) {
        guard retentionDays > 0 else { return }
        
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        do {
            let files = try fm.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            
            for file in files {
                let name = file.lastPathComponent
                
                // Match pattern: payments.YYYY-MM-DD.json
                guard name.hasPrefix("payments.") && name.hasSuffix(".json") && name != "payments.json" && name != "payments.legacy.json" else {
                    continue
                }
                
                // Extract date from filename
                let dateString = name.replacingOccurrences(of: "payments.", with: "").replacingOccurrences(of: ".json", with: "")
                
                if let backupDate = dateFormatter.date(from: dateString), backupDate < cutoffDate {
                    try fm.removeItem(at: file)
                    print("[PaymentsPersistence] Removed old backup: \(name)")
                }
            }
        } catch {
            print("[PaymentsPersistence] Cleanup error: \(error)")
        }
    }
}
