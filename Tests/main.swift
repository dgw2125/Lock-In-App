import Foundation

@MainActor func runTests() throws {
    func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() { fatalError(message) }
    }
    expect(DomainRule.normalize(" HTTPS://Instagram.com/person ") == "instagram.com", "URL normalization")
    expect(DomainRule.normalize("bad host.com") == nil, "Reject spaces")
    expect(DomainRule.normalize("https://user@instagram.com") == nil, "Reject credentials")
    expect(DomainRule.normalize("-bad.com") == nil, "Reject malformed label")
    expect(DomainRule.matches("https://a.b.instagram.com/person", domains: ["instagram.com"]), "Subdomains")
    expect(DomainRule.matches("https://instagram.com:443/person", domains: ["instagram.com"]), "Ports")
    expect(!DomainRule.matches("https://notinstagram.com", domains: ["instagram.com"]), "Domain boundary")
    expect(!DomainRule.matches("https://instagram.com.evil.org", domains: ["instagram.com"]), "Suffix spoof")
    expect(!DomainRule.matches("https://example.com/instagram.com", domains: ["instagram.com"]), "Path spoof")
    expect(!DomainRule.matches("https://instagram.com@evil.org", domains: ["instagram.com"]), "Userinfo spoof")
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("lockin-test-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let model = AppModel(directory: dir, ticking: false)
    expect(model.add("instagram.com"), "Add domain")
    model.start(minutes: 0)
    expect(model.active == nil, "Reject zero duration")
    // Persist an active session directly to avoid triggering real browser automation in tests.
    let start = Date().addingTimeInterval(-30)
    model.state.active = FocusSession(start: start, scheduledEnd: start.addingTimeInterval(1500), lastSeen: Date(), initialDomains: model.state.domains)
    model.remove("instagram.com")
    expect(model.state.domains == ["instagram.com"], "No active removal")
    model.state.active?.additions.append(Addition(domain: "reddit.com", date: Date()))
    expect(model.active?.domains == ["instagram.com", "reddit.com"], "Session additions")
    expect(model.save(), "Persist")
    let restored = AppModel(directory: dir, ticking: false)
    expect(restored.active == nil, "No silent resumption")
    expect(restored.state.history.count == 1, "Recover history")
    expect(restored.state.history[0].outcome == "interrupted", "Interrupted outcome")
    expect(restored.state.history[0].actualSeconds >= 29, "Elapsed recovery")
    expect(restored.state.history[0].additions.count == 1, "Persist additions")
    model.finish("ended early")
    model.remove("instagram.com")
    expect(model.state.domains.isEmpty, "Allow removal after ending")
    expect(model.state.history[0].initialDomains == ["instagram.com"], "History snapshot immutable")
    var expired = FocusSession(start: start, scheduledEnd: start.addingTimeInterval(10), lastSeen: start, initialDomains: [])
    expired.finish(at: Date(), outcome: "completed")
    expect(expired.actualSeconds == 10, "Cap completion at scheduled end")
    let csv = exportCSV(restored.state.history)
    expect(csv.contains("interrupted") && csv.contains("reddit.com @"), "CSV history and additions")
    expect(csvField("=SUM(1)") == "\"'=SUM(1)\"", "CSV formula protection")
    print("All 25 domain, session, persistence and CSV checks passed.")
}
try MainActor.assumeIsolated { try runTests() }
