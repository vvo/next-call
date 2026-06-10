# AGENTS.md

Guidance for contributors, human or AI.

## Build and run

No Xcode project. Swift Package Manager plus a script that assembles the .app bundle:

```bash
./build.sh
open "Next Call.app"
```

Show the notification without waiting for a real call:

```bash
open "Next Call.app" --args --test-notification
```

Or use "Show Test Notification" in the menu bar menu. It only shows in debug builds or when the app is launched with `--dev`.

Calendar permission (TCC) is tied to the app bundle. Always run the built app, never `swift run`, or EventKit returns nothing.

## Layout

- `Sources/main.swift`: app entry, accessory activation policy (no Dock icon)
- `Sources/AppDelegate.swift`: status item and menu (today + rest of week)
- `Sources/CalendarService.swift`: EventKit access, calendar selection, accepted-only filter, declined detection
- `Sources/MeetingLink.swift`: provider detection (regex over url/location/notes) and deep links (`zoommtg://`, `msteams://`)
- `Sources/MeetingScheduler.swift`: 10s tick, fires 60s before start, dedupes per event occurrence
- `Sources/NotificationPanel.swift`: borderless floating NSPanel hosting the SwiftUI view, screen positioning
- `Sources/NotificationView.swift`: the pill UI, hover close button, 30s progress bar
- `Sources/SettingsView.swift`: calendar checkboxes, sound picker, launch at login
- `Sources/CursorSupport.swift`: private CGS call so the hand cursor shows while the app is in the background
- `Sources/MenuBarIcon.swift`: vector-drawn template version of the app icon for the status item
- `Sources/UpdateChecker.swift`: polls GitHub releases every 6h, surfaces an "Update available" menu item
- `scripts/icon.swift` + `scripts/make-icns.sh`: regenerate AppIcon.icns from code

## Gotchas, learned the hard way

- `panel.animator().setFrameOrigin()` silently does nothing. Place the panel at its final origin and animate inside SwiftUI instead.
- The SwiftUI card carries 44pt of transparent padding so its shadow isn't clipped into a hard rectangle. Panel positioning in NotificationPanel.swift compensates for it.
- `NSCursor.set()` is ignored for background apps. CursorSupport.swift enables it via the CGS `SetsCursorInBackground` connection property (same trick as iTerm2).
- Provider logos live in `Sources/Resources/logos` and ship via the SPM resource bundle, which build.sh copies into the app.

## Releases

Tag and push, CI does the rest: builds, zips, bumps the cask sha/version on main, creates the GitHub release.

```bash
git tag v0.2.0 && git push origin v0.2.0
```

## Conventions

- No dependencies. AppKit + SwiftUI + EventKit only.
- Few comments, one line each, only for non-obvious whys.
- macOS 14+.
