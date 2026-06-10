import Foundation

enum TimeFormat {
    // "9am", "9:30am", "4pm"
    static func compact(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let suffix = hour < 12 ? "am" : "pm"
        var hour12 = hour % 12
        if hour12 == 0 { hour12 = 12 }
        return minute == 0 ? "\(hour12)\(suffix)" : "\(hour12):\(String(format: "%02d", minute))\(suffix)"
    }
}
