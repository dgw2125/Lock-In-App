import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor final class AppModel: ObservableObject {
    @Published var state = SavedState()
    @Published var now = Date()
    @Published var error: String?
    @Published var guardMessage = "Browser permissions are requested when a session starts."
    @Published var redirects = 0
    @Published private(set) var scheduled: ScheduledFocus?
    private let guardService = BrowserGuard()
    private var timer: Timer?
    private var loadFailed = false
    private var lastSave = Date.distantPast
    private let file: URL
    private let clock: () -> Date
    private let browserMonitoring: Bool
    var active: FocusSession? { state.active }
    var remaining: Int { max(0, Int(ceil((active?.scheduledEnd ?? now).timeIntervalSince(now)))) }
    var countdown: String { FocusDuration.countdown(remaining) }
    var delayRemaining: Int { max(0, Int(ceil((scheduled?.startsAt ?? now).timeIntervalSince(now)))) }
    var delayCountdown: String { FocusDuration.countdown(delayRemaining) }
    var menuTitle: String {
        if active != nil { return "◎ \(countdown)" }
        if scheduled != nil { return "Starts in \(delayCountdown)" }
        return "◎ Lock In"
    }
    init(directory: URL? = nil, ticking: Bool = true, browserMonitoring: Bool = true, clock: @escaping () -> Date = Date.init) {
        self.clock = clock
        self.browserMonitoring = browserMonitoring
        now = clock()
        let folder = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Lock In", isDirectory: true)
        file = folder.appendingPathComponent("state.json")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: file.path) {
                state = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: file))
            }
            if var session = state.active {
                session.finish(at: session.lastSeen, outcome: "interrupted")
                state.history.insert(session, at: 0)
                state.active = nil
                save()
            }
        } catch { self.loadFailed = true; self.error = "Could not load saved data: \(error.localizedDescription). Your file has not been overwritten." }
        if ticking {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
        }
    }
    @discardableResult func save() -> Bool {
        guard !loadFailed else { error = "Saved data could not be loaded. Close the app and restore or move state.json before continuing."; return false }
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(state).write(to: file, options: .atomic)
            return true
        } catch { self.error = "Could not save your session: \(error.localizedDescription)"; return false }
    }
    func add(_ input: String) -> Bool {
        guard let domain = DomainRule.normalize(input) else { error = "Enter a valid domain, such as instagram.com. International domains must use their ASCII (punycode) form."; return false }
        if state.domains.contains(domain) { error = "That domain is already on your list."; return false }
        let before = state
        state.domains.append(domain); state.domains.sort()
        if state.active != nil { state.active?.additions.append(Addition(domain: domain, date: clock())) }
        guard save() else { state = before; return false }
        if active != nil { poll() }
        return true
    }
    func remove(_ domain: String) {
        guard active == nil else { return }
        let before = state
        state.domains.removeAll { $0 == domain }
        if !save() { state = before; return }
        if state.domains.isEmpty, scheduled != nil {
            cancelScheduled()
            error = "Countdown cancelled because the block list is empty. Add a website before scheduling another session."
        }
    }
    func schedule(seconds: Int, after delay: Int) {
        guard active == nil, scheduled == nil, !state.domains.isEmpty,
              FocusDuration.isValid(seconds), (0...ScheduledFocus.maximumDelay).contains(delay) else { return }
        if delay == 0 { start(seconds: seconds); return }
        guard save() else { return }
        now = clock()
        scheduled = ScheduledFocus(startsAt: now.addingTimeInterval(Double(delay)), durationSeconds: seconds)
        guardMessage = "Countdown running. Websites remain available until your session starts. Keep Lock In open."
    }
    func cancelScheduled() {
        guard scheduled != nil else { return }
        scheduled = nil
        guardMessage = "Countdown cancelled. No focus session was recorded."
    }
    func start(seconds: Int) {
        guard active == nil, scheduled == nil, !state.domains.isEmpty, FocusDuration.isValid(seconds) else { return }
        now = clock(); redirects = 0
        state.active = FocusSession(start: now, scheduledEnd: now.addingTimeInterval(Double(seconds)), lastSeen: now, initialDomains: state.domains)
        guard save() else { state.active = nil; return }
        guardMessage = "Checking browser permissions…"
        poll()
    }
    func finish(_ outcome: String) {
        guard var session = active else { return }
        guardService.cancel()
        session.finish(at: clock(), outcome: outcome)
        state.history.insert(session, at: 0); state.active = nil
        _ = save()
        guardMessage = "Session ended. Browser monitoring is off."
    }
    func tick() {
        now = clock()
        if let pending = scheduled, now >= pending.startsAt {
            scheduled = nil
            start(seconds: pending.durationSeconds)
        }
        guard active != nil else { return }
        if remaining == 0 { finish("completed"); return }
        state.active?.lastSeen = now
        if now.timeIntervalSince(lastSave) >= 5 { _ = save(); lastSave = now }
        poll()
    }
    private func poll() {
        guard browserMonitoring, let session = active else { return }
        guardService.poll(domains: session.domains) { [weak self] result in
            guard let self, self.active?.id == session.id else { return }
            self.redirects += result.redirected
            self.guardMessage = result.messages.isEmpty ? "Monitoring supported browsers • \(self.redirects) tabs redirected" : result.messages.joined(separator: "\n")
        }
    }
    func export() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Lock-In-History.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try exportCSV(state.history).write(to: url, atomically: true, encoding: .utf8) }
        catch { self.error = "Export failed: \(error.localizedDescription)" }
    }
}
