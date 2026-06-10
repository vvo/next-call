import Foundation

final class UpdateChecker {
    static let shared = UpdateChecker()

    private(set) var availableVersion: String?
    private var timer: Timer?
    private var lastCheck: Date?

    func start() {
        check()
        timer = Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { [weak self] _ in
            self?.check()
        }
        timer?.tolerance = 600
    }

    // Cheap to call often (e.g. on menu open), real check at most every 15 min.
    func checkIfStale() {
        if Date().timeIntervalSince(lastCheck ?? .distantPast) > 15 * 60 {
            check()
        }
    }

    private func check() {
        lastCheck = Date()
        guard let url = URL(string: "https://api.github.com/repos/vvo/next-call/releases/latest") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String
            else { return }
            let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            DispatchQueue.main.async {
                self?.availableVersion = Self.isNewer(latest, than: Self.currentVersion) ? latest : nil
            }
        }.resume()
    }

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    static func isNewer(_ a: String, than b: String) -> Bool {
        let av = a.split(separator: ".").map { Int($0) ?? 0 }
        let bv = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0 ..< max(av.count, bv.count) {
            let x = i < av.count ? av[i] : 0
            let y = i < bv.count ? bv[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
