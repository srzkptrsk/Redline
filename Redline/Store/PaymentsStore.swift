import Foundation
import Combine

@MainActor
final class PaymentsStore: ObservableObject {
    // Payment data
    @Published var templates: [PaymentTemplate] = []
    @Published var statuses: [PaymentMonthStatus] = []
    
    // Settings
    @Published var hidePaid: Bool = false
    @Published var alertDays: Int = 3
    @Published var backupRetentionDays: Int = 7
    
    /// Triggers view updates when the calendar day changes (at midnight).
    @Published private(set) var currentDay: Date = Calendar.app.startOfDay(for: Date())
    
    /// Returns true if any unpaid bill is due within `alertDays` from today
    var hasUrgentBills: Bool {
        let cal = Calendar.app
        let today = cal.startOfDay(for: currentDay)
        guard let threshold = cal.date(byAdding: .day, value: alertDays, to: today) else { return false }
        
        let currentMonthKey = today.monthKey(calendar: cal)
        let nextMonthKey = (cal.date(byAdding: .month, value: 1, to: today) ?? today).monthKey(calendar: cal)
        
        for tmpl in templates {
            for monthKey in [currentMonthKey, nextMonthKey] {
                guard !isPaid(templateId: tmpl.id, monthKey: monthKey) else { continue }
                
                let comps = cal.dateComponents([.year, .month], from: today)
                let year = comps.year ?? 1970
                let month = comps.month ?? 1
                let isNextMonth = monthKey == nextMonthKey
                let checkMonth = isNextMonth ? (month == 12 ? 1 : month + 1) : month
                let checkYear = isNextMonth && month == 12 ? year + 1 : year
                
                let dueDate: Date?
                switch tmpl.recurrence {
                case .monthly:
                    dueDate = cal.makeClampedDate(year: checkYear, month: checkMonth, day: tmpl.dueDay ?? 1)
                case .once:
                    if tmpl.dueDate?.monthKey(calendar: cal) == monthKey {
                        dueDate = tmpl.dueDate
                    } else {
                        dueDate = nil
                    }
                }
                
                if let due = dueDate, due >= today && due <= threshold {
                    return true
                }
            }
        }
        return false
    }

    private let paymentsPersistence = PaymentsPersistence()
    private let settingsPersistence = SettingsPersistence()
    private var cancellables: Set<AnyCancellable> = []
    private var isBootstrapping = true
    private var dayChangeObserver: NSObjectProtocol?

    init() {
        load()
        setupDayChangeObserver()

        // Auto-save payments on change (debounced)
        Publishers.CombineLatest($templates, $statuses)
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, !self.isBootstrapping else { return }
                self.savePayments()
            }
            .store(in: &cancellables)
        
        // Auto-save settings on change (debounced)
        Publishers.CombineLatest3($hidePaid, $alertDays, $backupRetentionDays)
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, !self.isBootstrapping else { return }
                self.saveSettings()
            }
            .store(in: &cancellables)

        isBootstrapping = false
    }
    
    deinit {
        if let observer = dayChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private nonisolated func setupDayChangeObserver() {
        let center = NotificationCenter.default
        
        let observer = center.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let store = self else { return }
            Task { @MainActor in
                store.currentDay = Calendar.app.startOfDay(for: Date())
            }
        }
        
        Task { @MainActor [weak self] in
            self?.dayChangeObserver = observer
        }
    }

    func setPaid(_ paid: Bool, templateId: UUID, monthKey: String) {
        if let idx = statuses.firstIndex(where: { $0.templateId == templateId && $0.monthKey == monthKey }) {
            statuses[idx].isPaid = paid
            statuses[idx].paidAt = paid ? Date() : nil
        } else {
            statuses.append(.init(
                monthKey: monthKey,
                templateId: templateId,
                isPaid: paid,
                paidAt: paid ? Date() : nil
            ))
        }
    }

    func isPaid(templateId: UUID, monthKey: String) -> Bool {
        statuses.first(where: { $0.templateId == templateId && $0.monthKey == monthKey })?.isPaid ?? false
    }

    func load() {
        // Load settings first
        let settings = settingsPersistence.load()
        hidePaid = settings.hidePaid
        alertDays = settings.alertDays
        backupRetentionDays = settings.backupRetentionDays
        
        // Load payments
        if let decoded = paymentsPersistence.load() {
            templates = decoded.templates
            statuses = decoded.statuses
        }
    }

    func savePayments() {
        let payload = PaymentsPersistence.Persisted(
            templates: templates,
            statuses: statuses
        )
        paymentsPersistence.save(payload, retentionDays: backupRetentionDays)
    }
    
    func saveSettings() {
        let settings = SettingsPersistence.Settings(
            hidePaid: hidePaid,
            alertDays: alertDays,
            backupRetentionDays: backupRetentionDays
        )
        settingsPersistence.save(settings)
    }
}

extension PaymentsStore {
    func updateTemplate(_ updated: PaymentTemplate) {
        if let idx = templates.firstIndex(where: { $0.id == updated.id }) {
            templates[idx] = updated
        }
    }

    func deleteTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        statuses.removeAll { $0.templateId == id }
    }
}
