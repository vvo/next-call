import AppKit
import EventKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @ObservedObject var service = CalendarService.shared
    @AppStorage("playSound") private var playSound = true
    @AppStorage("notificationSound") private var notificationSound = "Blow"
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private static let sounds = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
        "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if service.authorized {
                calendarList
            } else {
                permissionPrompt
            }
            Divider()
            options
            Divider()
            HStack {
                Spacer()
                Button("Done") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(width: 400, height: 520)
    }

    private var calendarList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Watch these calendars")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 14)
            Text("You'll be alerted 1 minute before events that contain a Zoom, Google Meet, Teams or Webex link.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 2)

            List {
                ForEach(groupedCalendars, id: \.0) { sourceTitle, calendars in
                    Section(sourceTitle) {
                        ForEach(calendars, id: \.calendarIdentifier) { calendar in
                            Toggle(isOn: binding(for: calendar)) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(nsColor: calendar.color ?? .systemBlue))
                                        .frame(width: 10, height: 10)
                                    Text(calendar.title)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var permissionPrompt: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Calendar access is required")
                .font(.headline)
            Text("Next Call needs to read your local calendars to alert you before calls. Enable it in System Settings → Privacy & Security → Calendars.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var options: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Play sound with notification", isOn: $playSound)
            Picker("Sound", selection: $notificationSound) {
                ForEach(Self.sounds, id: \.self) { Text($0) }
            }
            .frame(width: 200)
            .disabled(!playSound)
            .onChange(of: notificationSound) { _, name in
                NSSound(named: name)?.play()
            }
            Toggle("Start at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, on in
                    do {
                        if on {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
            Button("Show a test notification") {
                NotificationPanelController.shared.showTest()
            }
        }
        .padding(16)
    }

    private var groupedCalendars: [(String, [EKCalendar])] {
        let grouped = Dictionary(grouping: service.allCalendars) { $0.source?.title ?? "Other" }
        return grouped.sorted { $0.key < $1.key }
    }

    private func binding(for calendar: EKCalendar) -> Binding<Bool> {
        Binding(
            get: { service.isSelected(calendar) },
            set: { service.setSelected(calendar, selected: $0) }
        )
    }
}

final class SettingsWindowController: NSWindowController {
    convenience init() {
        let hosting = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hosting)
        window.title = "Next Call"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }

    func present() {
        NSApp.activate(ignoringOtherApps: true)
        if window?.isVisible != true {
            window?.center()
        }
        window?.makeKeyAndOrderFront(nil)
    }
}
