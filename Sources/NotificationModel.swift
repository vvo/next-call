import AppKit
import EventKit
import SwiftUI

struct NotificationModel {
    let title: String
    let timeRange: String
    let accentColor: Color
    let link: MeetingLink
    let startDate: Date?
    let participants: [String]

    var participantsLine: String? {
        guard !participants.isEmpty else { return nil }
        let shown = participants.prefix(3).joined(separator: ", ")
        let extra = participants.count - min(3, participants.count)
        return extra > 0 ? "With \(shown) +\(extra)" : "With \(shown)"
    }

    static func from(event: EKEvent, link: MeetingLink) -> NotificationModel {
        var range = TimeFormat.compact(event.startDate)
        if let end = event.endDate {
            range += " - " + TimeFormat.compact(end)
        }
        let nsColor = event.calendar?.color ?? .systemBlue
        let names = (event.attendees ?? [])
            .filter { $0.participantType == .person && !$0.isCurrentUser }
            .compactMap(\.name)
            .filter { !$0.contains("@") }
        return NotificationModel(
            title: event.title ?? "Untitled call",
            timeRange: range,
            accentColor: Color(nsColor: nsColor),
            link: link,
            startDate: event.startDate,
            participants: names
        )
    }

    static var sample: NotificationModel {
        let start = Date().addingTimeInterval(60)
        let end = start.addingTimeInterval(25 * 60)
        return NotificationModel(
            title: "💯 Disruptive Scrum-of-Scrums",
            timeRange: TimeFormat.compact(start) + " - " + TimeFormat.compact(end),
            accentColor: Color(nsColor: .systemTeal),
            link: MeetingLink(provider: .zoom, url: URL(string: "https://zoom.us/j/123456789")!),
            startDate: nil,
            participants: ["Ada Lovelace", "Grace Hopper", "Alan Turing", "Linus"]
        )
    }
}
