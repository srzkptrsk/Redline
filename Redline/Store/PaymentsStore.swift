import Foundation
import Combine

@MainActor
final class PaymentsStore: ObservableObject {
    @Published var templates: [PaymentTemplate] = []
    @Published var statuses: [PaymentMonthStatus] = []
    @Published var hidePaid: Bool = false
    
    /// Triggers view updates when the calendar day changes (at midnight).
    /// Views can reference this to ensure they re-render with updated day counts.
    @Published private(set) var currentDay: Date = Calendar.app.startOfDay(for: Date())

    private let persistence = PaymentsPersistence()
    private var cancellables: Set<AnyCancellable> = []
    private var isBootstrapping = true
    private var dayChangeObserver: NSObjectProtocol?

    init() {
        load()
        setupDayChangeObserver()

        // Auto-save on change (debounced)
        Publishers.CombineLatest3($templates, $statuses, $hidePaid)
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.isBootstrapping { return }
                self.save()
            }
            .store(in: &cancellables)

        isBootstrapping = false
    }
    
    deinit {
        if let observer = dayChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// Observes system notification for calendar day changes and updates `currentDay`.
    private nonisolated func setupDayChangeObserver() {
        let center = NotificationCenter.default
        
        // NSCalendar.dayChangedNotification is posted at midnight when the day changes
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
        guard let decoded = persistence.load() else { return }
        templates = decoded.templates
        statuses = decoded.statuses
        hidePaid = decoded.hidePaid
    }

    func save() {
        let payload = PaymentsPersistence.Persisted(
            templates: templates,
            statuses: statuses,
            hidePaid: hidePaid
        )
        persistence.save(payload)
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
        // cleanup paid-statuses for deleted template
        statuses.removeAll { $0.templateId == id }
    }
}
