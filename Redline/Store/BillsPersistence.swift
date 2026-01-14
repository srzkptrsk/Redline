import Foundation

struct BillsPersistence {
    struct Persisted: Codable {
        var templates: [BillTemplate]
        var statuses: [BillMonthStatus]
        
        // Backwards compatibility: ignore settings fields from old JSON
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            templates = try container.decode([BillTemplate].self, forKey: .templates)
            statuses = try container.decode([BillMonthStatus].self, forKey: .statuses)
        }
        
        init(templates: [BillTemplate], statuses: [BillMonthStatus]) {
            self.templates = templates
            self.statuses = statuses
        }
        
        private enum CodingKeys: String, CodingKey {
            case templates, statuses
        }
    }
    
    private let fileName = "bills.json"
    private let legacyFileName = "payments.json"
    
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
    
    private var legacyFileURL: URL {
        directoryURL.appendingPathComponent(legacyFileName)
    }
    
    func load() -> Persisted? {
        print("[BillsPersistence] Loading from: \(fileURL.path)")
        
        // Try new file first
        if let data = try? Data(contentsOf: fileURL) {
            return decodeData(data)
        }
        
        // Fallback to legacy payments.json
        print("[BillsPersistence] Trying legacy file: \(legacyFileURL.path)")
        if let data = try? Data(contentsOf: legacyFileURL) {
            return decodeData(data)
        }
        
        print("[BillsPersistence] No data file found")
        return nil
    }
    
    private func decodeData(_ data: Data) -> Persisted? {
        do {
            let result = try JSONDecoder().decode(Persisted.self, from: data)
            print("[BillsPersistence] Loaded \(result.templates.count) templates")
            return result
        } catch {
            print("[BillsPersistence] Decode error: \(error)")
            let backupURL = directoryURL.appendingPathComponent("bills.legacy.json")
            try? data.write(to: backupURL, options: [.atomic])
            print("[BillsPersistence] Legacy backup saved to: \(backupURL.path)")
            return nil
        }
    }
    
    func save(_ payload: Persisted, retentionDays: Int) {
        let fm = FileManager.default
        
        createDailyBackup(fm: fm)
        cleanupOldBackups(fm: fm, retentionDays: retentionDays)
        
        guard let data = try? JSONEncoder().encode(payload) else {
            print("[BillsPersistence] Failed to encode payload")
            return
        }
        
        do {
            try data.write(to: fileURL, options: [.atomic])
            print("[BillsPersistence] Saved \(payload.templates.count) templates")
        } catch {
            print("[BillsPersistence] Save error: \(error)")
        }
    }
    
    private func createDailyBackup(fm: FileManager) {
        guard fm.fileExists(atPath: fileURL.path) else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let backupName = "bills.\(dateString).json"
        let backupURL = directoryURL.appendingPathComponent(backupName)
        
        if !fm.fileExists(atPath: backupURL.path) {
            try? fm.copyItem(at: fileURL, to: backupURL)
            print("[BillsPersistence] Daily backup created: \(backupName)")
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
                
                guard name.hasPrefix("bills.") && name.hasSuffix(".json") && name != "bills.json" && name != "bills.legacy.json" else {
                    continue
                }
                
                let dateString = name.replacingOccurrences(of: "bills.", with: "").replacingOccurrences(of: ".json", with: "")
                
                if let backupDate = dateFormatter.date(from: dateString), backupDate < cutoffDate {
                    try fm.removeItem(at: file)
                    print("[BillsPersistence] Removed old backup: \(name)")
                }
            }
        } catch {
            print("[BillsPersistence] Cleanup error: \(error)")
        }
    }
}
