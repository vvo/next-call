import EventKit
import Foundation

final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    let store = EKEventStore()

    @Published var authorized: Bool
    @Published private(set) var selectedCalendarIDs: Set<String>

    private static let defaultsKey = "selectedCalendarIDs"

    private init() {
        authorized = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        selectedCalendarIDs = Set(UserDefaults.standard.stringArray(forKey: Self.defaultsKey) ?? [])
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        store.requestFullAccessToEvents { granted, _ in
            DispatchQueue.main.async {
                self.authorized = granted
                completion(granted)
            }
        }
    }

    var allCalendars: [EKCalendar] {
        guard authorized else { return [] }
        return store.calendars(for: .event).sorted {
            ($0.source?.title ?? "", $0.title) < ($1.source?.title ?? "", $1.title)
        }
    }

    func isSelected(_ calendar: EKCalendar) -> Bool {
        selectedCalendarIDs.contains(calendar.calendarIdentifier)
    }

    func setSelected(_ calendar: EKCalendar, selected: Bool) {
        if selected {
            selectedCalendarIDs.insert(calendar.calendarIdentifier)
        } else {
            selectedCalendarIDs.remove(calendar.calendarIdentifier)
        }
        UserDefaults.standard.set(Array(selectedCalendarIDs), forKey: Self.defaultsKey)
    }

    func upcomingEvents(within interval: TimeInterval) -> [EKEvent] {
        guard authorized else { return [] }
        let calendars = store.calendars(for: .event).filter { selectedCalendarIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }
        let now = Date()
        let predicate = store.predicateForEvents(withStart: now, end: now.addingTimeInterval(interval), calendars: calendars)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay && $0.startDate > now && isAttending($0) }
            .sorted { $0.startDate < $1.startDate }
    }

    func upcomingMeetings(within interval: TimeInterval) -> [(EKEvent, MeetingLink)] {
        upcomingEvents(within: interval).compactMap { event in
            MeetingLinkDetector.detect(in: event).map { (event, $0) }
        }
    }

    // Yes and maybe count. Events without attendees (your own) always count.
    private func isAttending(_ event: EKEvent) -> Bool {
        guard let attendees = event.attendees, !attendees.isEmpty else { return true }
        if event.organizer?.isCurrentUser == true { return true }
        guard let me = attendees.first(where: { $0.isCurrentUser }) else { return true }
        return me.participantStatus == .accepted || me.participantStatus == .tentative
    }

    // Names of human attendees (besides you) when all of them declined.
    func othersWhoDeclined(_ event: EKEvent) -> [String] {
        guard let attendees = event.attendees else { return [] }
        let others = attendees.filter { $0.participantType == .person && !$0.isCurrentUser }
        guard !others.isEmpty, others.allSatisfy({ $0.participantStatus == .declined }) else { return [] }
        return others.compactMap(\.name)
    }

    private var refreshTimer: Timer?

    func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.store.refreshSourcesIfNecessary()
        }
        refreshTimer?.tolerance = 5
    }
}
