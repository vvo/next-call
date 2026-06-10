import AppKit
import EventKit
import Foundation

enum MeetingProvider: String, CaseIterable {
    case zoom
    case meet
    case teams
    case webex

    var displayName: String {
        switch self {
        case .zoom: return "Zoom"
        case .meet: return "Google Meet"
        case .teams: return "Microsoft Teams"
        case .webex: return "Webex"
        }
    }

    var logo: NSImage? {
        guard let url = Self.resources.url(forResource: rawValue, withExtension: "png", subdirectory: "logos") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    // Bundle.module only checks the app root and the absolute path of the
    // machine that compiled the binary, so it crashes when the app is
    // installed elsewhere. Resolve Contents/Resources ourselves first.
    private static let resources: Bundle = {
        if let url = Bundle.main.url(forResource: "NextCall_NextCall", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return Bundle.module
    }()
}

struct MeetingLink {
    let provider: MeetingProvider
    let url: URL

    // Prefer the native app deep link when the app is installed, to skip the browser hop.
    var joinURL: URL {
        switch provider {
        case .zoom:
            if let deep = zoomDeepLink, appInstalled(forScheme: "zoommtg") {
                return deep
            }
            return url
        case .teams:
            if appInstalled(forScheme: "msteams"),
               var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                comps.scheme = "msteams"
                if let deep = comps.url { return deep }
            }
            return url
        case .meet, .webex:
            return url
        }
    }

    private func appInstalled(forScheme scheme: String) -> Bool {
        guard let probe = URL(string: "\(scheme)://") else { return false }
        return NSWorkspace.shared.urlForApplication(toOpen: probe) != nil
    }

    private var zoomDeepLink: URL? {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = comps.host else { return nil }
        let parts = comps.path.split(separator: "/").map(String.init)
        guard parts.count >= 2, parts[parts.count - 2] == "j",
              let confno = parts.last, !confno.isEmpty, confno.allSatisfy(\.isNumber) else { return nil }
        var out = URLComponents()
        out.scheme = "zoommtg"
        out.host = host
        out.path = "/join"
        var items = [URLQueryItem(name: "action", value: "join"), URLQueryItem(name: "confno", value: confno)]
        if let pwd = comps.queryItems?.first(where: { $0.name == "pwd" })?.value {
            items.append(URLQueryItem(name: "pwd", value: pwd))
        }
        out.queryItems = items
        return out.url
    }
}

enum MeetingLinkDetector {
    private static let patterns: [(MeetingProvider, String)] = [
        (.zoom, #"https?://(?:[a-zA-Z0-9.-]+\.)?(?:zoom\.us|zoomgov\.com|zoom\.com)/(?:j|my|s|w)/[^\s<>"']+"#),
        (.meet, #"https?://meet\.google\.com/[a-z0-9-]+(?:\?[^\s<>"']*)?"#),
        (.teams, #"https?://(?:teams\.microsoft\.com|teams\.live\.com)/(?:l/meetup-join|meet)/[^\s<>"']+"#),
        (.webex, #"https?://(?:[a-zA-Z0-9.-]+\.)?webex\.com/(?:meet|join|wbxmjs|webappng)[^\s<>"']*"#),
    ]

    static func detect(in event: EKEvent) -> MeetingLink? {
        var texts: [String] = []
        if let url = event.url?.absoluteString { texts.append(url) }
        if let location = event.location { texts.append(location) }
        if let notes = event.notes { texts.append(notes) }
        return detect(in: texts.joined(separator: "\n"))
    }

    static func detect(in text: String) -> MeetingLink? {
        for (provider, pattern) in patterns {
            guard let range = text.range(of: pattern, options: .regularExpression) else { continue }
            var match = String(text[range])
            while let last = match.last, ")>.,;!".contains(last) {
                match.removeLast()
            }
            if let url = URL(string: match) {
                return MeetingLink(provider: provider, url: url)
            }
        }
        return nil
    }
}
