import AppKit
import EventKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static let devMode: Bool = {
        #if DEBUG
            return true
        #else
            return CommandLine.arguments.contains("--dev")
        #endif
    }()

    private var statusItem: NSStatusItem!
    private let scheduler = MeetingScheduler()
    private var settingsController: SettingsWindowController?
    private var statusTitleTimer: Timer?

    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        CursorSupport.enableBackgroundCursorChanges()
        UpdateChecker.shared.start()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = MenuBarIcon.image
            button.imagePosition = .imageLeading
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        scheduler.onMeetingImminent = { event, link in
            NotificationPanelController.shared.show(event: event, link: link)
        }

        if CommandLine.arguments.contains("--test-notification") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                NotificationPanelController.shared.showTest()
            }
        }

        CalendarService.shared.requestAccess { [weak self] granted in
            if granted {
                if CalendarService.shared.selectedCalendarIDs.isEmpty {
                    self?.openSettings()
                }
                CalendarService.shared.startAutoRefresh()
                self?.scheduler.start()
                self?.startStatusTitleUpdates()
            } else {
                self?.openSettings()
            }
        }
    }

    private func startStatusTitleUpdates() {
        updateStatusTitle()
        statusTitleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateStatusTitle()
        }
        statusTitleTimer?.tolerance = 5
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: CalendarService.shared.store,
            queue: .main
        ) { [weak self] _ in
            self?.updateStatusTitle()
        }
    }

    private func updateStatusTitle() {
        guard let button = statusItem.button else { return }
        guard let (event, _) = CalendarService.shared.upcomingMeetings(within: 7 * 24 * 3600).first,
              let start = event.startDate
        else {
            button.title = ""
            return
        }
        let title = truncated(event.title ?? "Untitled", max: 18)
        button.title = " \(title) · \(relativeTime(to: start))"
    }

    private func truncated(_ text: String, max: Int) -> String {
        guard text.count > max else { return text }
        return String(text.prefix(max - 1)).trimmingCharacters(in: .whitespaces) + "…"
    }

    private func relativeTime(to date: Date) -> String {
        let minutes = Int((max(date.timeIntervalSinceNow, 0) / 60).rounded())
        if minutes < 1 { return "now" }
        if minutes < 60 { return "in \(minutes)m" }
        if minutes < 180 {
            return minutes % 60 == 0 ? "in \(minutes / 60)h" : "in \(minutes / 60)h \(minutes % 60)m"
        }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "in \(Int((Double(minutes) / 60).rounded()))h"
        }
        if calendar.isDateInTomorrow(date) {
            return "tomorrow \(TimeFormat.compact(date))"
        }
        return "\(weekdayFormatter.string(from: date)) \(TimeFormat.compact(date))"
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        UpdateChecker.shared.checkIfStale()
        menu.removeAllItems()

        let now = Date()
        let endOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: now)!.end

        let meetings = CalendarService.shared.upcomingMeetings(within: max(endOfWeek.timeIntervalSince(now), 0), includeOngoing: true)
            .prefix(8)

        if meetings.isEmpty {
            let empty = NSMenuItem(title: "No upcoming video calls", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for (event, link) in meetings {
                menu.addItem(meetingItem(event: event, link: link))
            }
        }

        menu.addItem(.separator())

        if let version = UpdateChecker.shared.availableVersion {
            let update = NSMenuItem(title: "Update available (v\(version))…", action: #selector(updateClicked), keyEquivalent: "")
            update.target = self
            menu.addItem(update)
            menu.addItem(.separator())
        }

        if Self.devMode {
            let test = NSMenuItem(title: "Show Test Notification", action: #selector(testNotification), keyEquivalent: "t")
            test.target = self
            menu.addItem(test)
        }

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let version = NSMenuItem(title: "Version \(UpdateChecker.currentVersion)", action: nil, keyEquivalent: "")
        version.isEnabled = false
        menu.addItem(version)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Next Call", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    private func menuTimeLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return TimeFormat.compact(date) }
        if calendar.isDateInTomorrow(date) { return "Tomorrow " + TimeFormat.compact(date) }
        return "\(weekdayFormatter.string(from: date)) \(TimeFormat.compact(date))"
    }

    private func meetingItem(event: EKEvent, link: MeetingLink) -> NSMenuItem {
        let now = Date()
        let inProgress = event.startDate <= now && event.endDate > now
        let time = inProgress ? "Now" : menuTimeLabel(for: event.startDate)
        let title = truncated(event.title ?? "Untitled", max: 36)
        let item = NSMenuItem(
            title: "\(time)   \(title)",
            action: #selector(joinFromMenu(_:)),
            keyEquivalent: ""
        )
        item.target = self

        let declined = CalendarService.shared.othersWhoDeclined(event)
        if !declined.isEmpty {
            item.attributedTitle = NSAttributedString(
                string: "\(time)   \(title)  ⚠︎",
                attributes: [.foregroundColor: NSColor.secondaryLabelColor]
            )
            item.toolTip = declined.count == 1
                ? "\(declined[0]) declined"
                : "Everyone else declined"
        }
        if let logo = link.provider.logo {
            let icon = logo.copy() as! NSImage
            icon.size = NSSize(width: 16, height: 16)
            item.image = icon
        }
        item.representedObject = link
        return item
    }

    @objc private func joinFromMenu(_ sender: NSMenuItem) {
        guard let link = sender.representedObject as? MeetingLink else { return }
        NSWorkspace.shared.open(link.joinURL)
    }

    @objc private func testNotification() {
        NotificationPanelController.shared.showTest()
    }

    @objc private func updateClicked() {
        guard let version = UpdateChecker.shared.availableVersion else { return }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Next Call v\(version) is available"
        alert.informativeText = "You have v\(UpdateChecker.currentVersion). Upgrade with:\n\nbrew update && brew upgrade --cask next-call"
        alert.addButton(withTitle: "Copy Command")
        alert.addButton(withTitle: "Open Releases")
        alert.addButton(withTitle: "Later")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("brew update && brew upgrade --cask next-call", forType: .string)
        case .alertSecondButtonReturn:
            NSWorkspace.shared.open(URL(string: "https://github.com/vvo/next-call/releases/latest")!)
        default:
            break
        }
    }

    @objc func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController()
        }
        settingsController?.present()
    }
}
