import AppKit

struct BrowserResult {
    var redirected = 0
    var messages: [String] = []
}
final class BrowserGuard {
    private let queue = DispatchQueue(label: "com.lockin.browser-guard")
    private var busy = false
    private let cancellationLock = NSLock()
    private var generation = 0
    func cancel() { cancellationLock.lock(); generation += 1; cancellationLock.unlock() }
    private func currentGeneration() -> Int { cancellationLock.lock(); defer { cancellationLock.unlock() }; return generation }
    static let browsers: [(String, String)] = [
        ("com.apple.Safari", "Safari"), ("com.google.Chrome", "Chrome"),
        ("com.microsoft.edgemac", "Edge"), ("com.brave.Browser", "Brave"),
        ("com.vivaldi.Vivaldi", "Vivaldi"), ("company.thebrowser.Browser", "Arc")
    ]
    func poll(domains: [String], completion: @escaping (BrowserResult) -> Void) {
        guard !busy else { return }
        busy = true
        let token = currentGeneration()
        let running = Self.browsers.filter { !NSRunningApplication.runningApplications(withBundleIdentifier: $0.0).isEmpty }
        queue.async {
            var result = BrowserResult()
            for (bundle, name) in running {
                guard self.currentGeneration() == token else { break }
                // Read URL descriptors first; match hosts in Swift, never by URL substring.
                let source = """
                with timeout of 3 seconds
                tell application id "\(bundle)"
                    set foundTabs to {}
                    repeat with w in windows
                        set n to 0
                        repeat with t in tabs of w
                            set n to n + 1
                            try
                                set end of foundTabs to {(id of w) as integer, n, (URL of t) as text}
                            end try
                        end repeat
                    end repeat
                    return foundTabs
                end tell
                end timeout
                """
                var error: NSDictionary?
                guard let script = NSAppleScript(source: source) else { continue }
                let records = script.executeAndReturnError(&error)
                if let error {
                    result.messages.append("\(name): \(error[NSAppleScript.errorMessage] ?? "Automation unavailable")")
                    continue
                }
                for index in 1..<(records.numberOfItems + 1) {
                    guard let row = records.atIndex(index), let url = row.atIndex(3)?.stringValue,
                          DomainRule.matches(url, domains: domains) else { continue }
                    guard self.currentGeneration() == token else { break }
                    let windowID = row.atIndex(1)?.int32Value ?? 0
                    let tabIndex = row.atIndex(2)?.int32Value ?? 0
                    let quotedURL = url.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "") .replacingOccurrences(of: "\r", with: "")
                    let redirect = """
                    with timeout of 3 seconds
                    tell application id "\(bundle)"
                        set t to tab \(tabIndex) of window id \(windowID)
                        if URL of t is "\(quotedURL)" then
                            set URL of t to "about:blank"
                            return true
                        end if
                        return false
                    end tell
                    end timeout
                    """
                    var redirectError: NSDictionary?
                    let response = NSAppleScript(source: redirect)?.executeAndReturnError(&redirectError)
                    if redirectError != nil { result.messages.append("\(name): could not redirect a matching tab.") }
                    else if response?.booleanValue == true { result.redirected += 1 }
                }
            }
            if running.isEmpty { result.messages.append("No supported browser is open. Firefox and other browsers are not covered.") }
            DispatchQueue.main.async {
                self.busy = false
                completion(result)
            }
        }
    }
}
