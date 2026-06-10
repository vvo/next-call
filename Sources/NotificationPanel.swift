import AppKit
import EventKit
import SwiftUI

private final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class NotificationPanelController {
    static let shared = NotificationPanelController()

    private var panel: NSPanel?
    private var autoDismissTimer: Timer?
    private var remindTimer: Timer?

    func show(event: EKEvent, link: MeetingLink) {
        show(model: .from(event: event, link: link))
    }

    // Your real next call when there is one, the sample otherwise.
    func showTest() {
        if let (event, link) = CalendarService.shared.upcomingMeetings(within: 7 * 24 * 3600).first {
            show(event: event, link: link)
        } else {
            show(model: .sample)
        }
    }

    func show(model: NotificationModel) {
        dismiss(animated: false)

        let view = NotificationView(
            model: model,
            onJoin: { [weak self] in
                NSWorkspace.shared.open(model.link.joinURL)
                self?.dismiss()
            },
            onRemindAtStart: { [weak self] in
                self?.scheduleRemind(model: model)
                self?.dismiss()
            },
            onCopyLink: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(model.link.url.absoluteString, forType: .string)
            },
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )

        let hosting = NSHostingView(rootView: view)
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize

        let panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = hosting

        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame
        // The SwiftUI view carries 28pt of internal padding for its shadow.
        // Insets are measured to the visible card edge; the top one also leaves
        // room for the hover close button that pokes 15pt above the card.
        let viewPadding: CGFloat = 44
        let rightInset: CGFloat = 16
        let topInset: CGFloat = 16
        // Window-frame animation via animator() silently no-ops, so the panel is
        // placed at its final position and the slide-in happens inside SwiftUI.
        panel.setFrameOrigin(NSPoint(
            x: frame.maxX - size.width + viewPadding - rightInset,
            y: frame.maxY - size.height + viewPadding - topInset
        ))
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        self.panel = panel

        if UserDefaults.standard.object(forKey: "playSound") as? Bool ?? true {
            let name = UserDefaults.standard.string(forKey: "notificationSound") ?? "Blow"
            NSSound(named: name)?.play()
        }

        let dismissAt = (model.startDate ?? Date()).addingTimeInterval(3 * 60)
        autoDismissTimer = Timer.scheduledTimer(
            withTimeInterval: max(30, dismissAt.timeIntervalSinceNow),
            repeats: false
        ) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss(animated: Bool = true) {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        NSCursor.arrow.set()
        guard let panel else { return }
        self.panel = nil
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                panel.animator().alphaValue = 0
            }, completionHandler: {
                panel.orderOut(nil)
            })
        } else {
            panel.orderOut(nil)
        }
    }

    private func scheduleRemind(model: NotificationModel) {
        guard let start = model.startDate, start > Date() else { return }
        remindTimer?.invalidate()
        remindTimer = Timer.scheduledTimer(
            withTimeInterval: start.timeIntervalSinceNow,
            repeats: false
        ) { [weak self] _ in
            self?.show(model: model)
        }
    }
}
