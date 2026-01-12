import Foundation

struct PaymentsPersistence {
    struct Persisted: Codable {
        var templates: [PaymentTemplate]
        var statuses: [PaymentMonthStatus]
        var hidePaid: Bool
    }

    private let fileName = "payments.json"

    private var directoryName: String {
        // Use bundle id if available, fallback to app name
        Bundle.main.bundleIdentifier ?? "Redline"
    }

    private var fileURL: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    func load() -> Persisted? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Persisted.self, from: data)
    }

    func save(_ payload: Persisted) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
