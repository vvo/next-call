import EventKit
import Foundation

final class MeetingScheduler {
    static let leadTime: TimeInterval = 60

    var onMeetingImminent: ((EKEvent, MeetingLink) -> Void)?

    private var timer: Timer?
    private var notifiedKeys = Set<String>()

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer?.tolerance = 2
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: CalendarService.shared.store,
            queue: .main
        ) { [weak self] _ in
            self?.tick()
        }
        tick()
    }

    private func tick() {
        let now = Date()
        for (event, link) in CalendarService.shared.upcomingMeetings(within: 30 * 60) {
            guard let start = event.startDate, start.timeIntervalSince(now) <= Self.leadTime else { continue }
            let key = "\(event.calendarItemIdentifier)-\(start.timeIntervalSince1970)"
            guard !notifiedKeys.contains(key) else { continue }
            notifiedKeys.insert(key)
            onMeetingImminent?(event, link)
        }
    }
}
