import Foundation

struct Addition: Codable, Equatable {
    var domain: String
    var date: Date
}
struct FocusSession: Codable, Identifiable {
    var id = UUID()
    var start: Date
    var scheduledEnd: Date
    var end: Date?
    var lastSeen: Date
    var outcome: String = "active"
    var initialDomains: [String]
    var additions: [Addition] = []
    var domains: [String] { Array(Set(initialDomains + additions.map(\.domain))).sorted() }
    var plannedSeconds: Int { Int(scheduledEnd.timeIntervalSince(start)) }
    var actualSeconds: Int { max(0, Int((end ?? lastSeen).timeIntervalSince(start))) }
    mutating func finish(at date: Date, outcome: String) {
        end = min(date, scheduledEnd)
        lastSeen = end!
        self.outcome = outcome
    }
}
struct SavedState: Codable {
    var domains: [String] = []
    var active: FocusSession?
    var history: [FocusSession] = []
}
enum FocusDuration {
    static let maximum = 6 * 60 * 60
    static func isValid(_ seconds: Int) -> Bool { (1...maximum).contains(seconds) }
    static func seconds(hours: Int, minutes: Int, seconds: Int) -> Int {
        min(maximum, max(0, hours) * 3600 + max(0, minutes) * 60 + max(0, seconds))
    }
    static func countdown(_ seconds: Int) -> String {
        let value = max(0, seconds)
        if value >= 3600 { return String(format: "%d:%02d:%02d", value / 3600, value / 60 % 60, value % 60) }
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}

enum DomainRule {
    static func normalize(_ input: String) -> String? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !raw.isEmpty, let url = URLComponents(string: raw.contains("://") ? raw : "https://" + raw),
              ["https", "http"].contains(url.scheme ?? ""), url.user == nil, url.password == nil,
              let host = url.host?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")),
              host.count <= 253, host.contains("."), host.utf8.allSatisfy({ $0 < 128 }) else { return nil }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.allSatisfy({ label in
            !label.isEmpty && label.count <= 63 && label.first != "-" && label.last != "-" &&
            label.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
        }), !labels.allSatisfy({ Int($0) != nil }) else { return nil }
        return host
    }
    static func matches(_ url: String, domains: [String]) -> Bool {
        guard let parts = URLComponents(string: url), ["http", "https"].contains(parts.scheme?.lowercased() ?? ""),
              let host = parts.host?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) else { return false }
        return domains.contains { host == $0 || host.hasSuffix("." + $0) }
    }
}
func csvField(_ value: String) -> String {
    let safe = ["=", "+", "-", "@", "\t", "\r"].contains(where: value.hasPrefix) ? "'" + value : value
    return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
}
func exportCSV(_ sessions: [FocusSession]) -> String {
    let format = ISO8601DateFormatter()
    let header = "id,start,end,planned_seconds,actual_seconds,outcome,initial_websites,added_websites_with_times\r\n"
    var rows: [String] = []
    for session in sessions {
        let additions = session.additions.map { addition in
            addition.domain + " @ " + format.string(from: addition.date)
        }.joined(separator: "; ")
        let fields: [String] = [
            session.id.uuidString,
            format.string(from: session.start),
            session.end.map { format.string(from: $0) } ?? "",
            String(session.plannedSeconds), String(session.actualSeconds),
            session.outcome, session.initialDomains.joined(separator: "; "), additions
        ]
        rows.append(fields.map { csvField($0) }.joined(separator: ","))
    }
    return header + rows.joined(separator: "\r\n")
}
