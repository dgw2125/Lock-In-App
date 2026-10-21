import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var domain = ""
    @State private var minutes = 25
    @State private var selected = 0
    @State private var gateOne = false
    @State private var gateTwo = false
    @State private var unlock = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "scope").font(.system(size: 30)).foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text("Lock In").font(.largeTitle.bold())
                    Text("Make room for what matters.").foregroundStyle(.secondary)
                }
                Spacer()
                Text("PROTOTYPE").font(.caption.bold()).foregroundStyle(.secondary)
            }
            Picker("Section", selection: $selected) {
                Text("Focus").tag(0); Text("History").tag(1)
            }.pickerStyle(.segmented)
            if selected == 0 { focus } else { history }
        }
        .padding(26).frame(minWidth: 640, idealWidth: 680, minHeight: 680)
        .alert("End your focus session?", isPresented: $gateOne) {
            Button("Keep focusing", role: .cancel) {}
            Button("Continue", role: .destructive) { unlock = ""; gateTwo = true }
        } message: { Text("Your remaining focus time will be lost. There is one more confirmation step.") }
        .sheet(isPresented: $gateTwo) {
            VStack(alignment: .leading, spacing: 18) {
                Text("One deliberate decision.").font(.title2.bold())
                Text("Type UNLOCK to end this session early.")
                TextField("UNLOCK", text: $unlock).textFieldStyle(.roundedBorder)
                HStack {
                    Button("Keep focusing") { gateTwo = false }.keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("End session", role: .destructive) {
                        model.finish("ended early"); gateTwo = false
                    }.disabled(unlock != "UNLOCK")
                }
            }.padding(28).frame(width: 380)
        }
        .alert("Lock In needs attention", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
    }
    private var focus: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(spacing: 12) {
                    Text(model.active == nil ? "YOUR NEXT FOCUS SESSION" : "YOU’RE LOCKED IN").font(.caption.bold()).foregroundStyle(.secondary)
                    if model.active != nil {
                        Text(model.countdown).font(.system(size: 62, weight: .medium, design: .monospaced))
                        Button("End session early…") { gateOne = true }
                    } else {
                        HStack {
                            ForEach([25, 50, 90], id: \.self) { value in
                                Button("\(value) min") { minutes = value }.tint(minutes == value ? .green : .gray)
                            }
                        }
                        HStack {
                            Text("Duration")
                            TextField("Minutes", value: $minutes, format: .number).frame(width: 65).textFieldStyle(.roundedBorder)
                            Text("minutes (1–1440)").foregroundStyle(.secondary)
                        }.fixedSize()
                        Button("Start focus session") { model.start(minutes: minutes) }
                            .buttonStyle(.borderedProminent).tint(.green)
                            .disabled(model.state.domains.isEmpty || !(1...1440).contains(minutes))
                    }
                }.frame(maxWidth: .infinity).padding(14)
            }
            HStack {
                Text("Blocked websites").font(.headline)
                Spacer()
                if model.active != nil { Label("Additions only", systemImage: "lock").font(.caption).foregroundStyle(.secondary) }
            }
            HStack {
                TextField("instagram.com", text: $domain).textFieldStyle(.roundedBorder).onSubmit(addDomain)
                Button("Add", action: addDomain).disabled(domain.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    if model.state.domains.isEmpty { Text("Add your first distracting website.").foregroundStyle(.secondary).padding(22) }
                    ForEach(model.state.domains, id: \.self) { site in
                        HStack {
                            Image(systemName: "globe").foregroundStyle(.secondary)
                            Text(site); Spacer()
                            Button { model.remove(site) } label: { Image(systemName: "minus.circle") }
                                .buttonStyle(.plain).disabled(model.active != nil).accessibilityLabel("Remove \(site)")
                        }.padding(.vertical, 9)
                        Divider()
                    }
                }
            }.frame(minHeight: 80, maxHeight: .infinity)
            Text("Includes all paths and subdomains. To block both instagram.com and www.instagram.com, add instagram.com.")
                .font(.caption).foregroundStyle(.secondary)
            GroupBox("Browser guard · lightweight blocking") {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Matching tabs redirect to a blank page after a short delay. Content can load first. Allow macOS Automation permission for each browser when prompted.")
                    Text("Targets Safari, Chrome, Edge, Brave, Vivaldi and Arc. Chrome incognito is targeted too; private windows and each browser still need manual verification. Firefox is not covered.")
                    Text(model.guardMessage).foregroundStyle(model.guardMessage.contains(":") ? .orange : .secondary).textSelection(.enabled)
                }.font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(6)
            }
        }
    }
    private func addDomain() { if model.add(domain) { domain = "" } }
    private var history: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Session history").font(.headline); Spacer()
                Button("Export CSV…") { model.export() }.disabled(model.state.history.isEmpty)
            }
            if model.state.history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath").font(.largeTitle)
                    Text("Your focus sessions will appear here.")
                }.foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(model.state.history) { session in
                            GroupBox {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(session.start.formatted(date: .abbreviated, time: .omitted)).bold()
                                        Spacer(); Text(session.outcome.capitalized).foregroundStyle(.secondary)
                                    }
                                    Text("\(session.start.formatted(date: .omitted, time: .standard)) – \((session.end ?? session.lastSeen).formatted(date: .omitted, time: .standard))")
                                    Text("Planned: \(session.plannedSeconds / 60) min · Elapsed: \(session.actualSeconds / 60)m \(session.actualSeconds % 60)s")
                                    Text(session.initialDomains.joined(separator: ", "))
                                    ForEach(Array(session.additions.enumerated()), id: \.offset) { _, addition in
                                        Text("+ \(addition.domain) at \(addition.date.formatted(date: .omitted, time: .standard))").font(.caption)
                                    }
                                    if session.outcome == "interrupted" { Text("End time is the last saved activity, not an exact shutdown time.").font(.caption).foregroundStyle(.secondary) }
                                }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
                            }
                        }
                    }
                }
            }
        }.frame(maxHeight: .infinity)
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    var window: NSWindow!
    var status: NSStatusItem!
    var refresh: Timer?
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 740), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Lock In"; window.center(); window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView(model: model))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.target = self; status.button?.action = #selector(showWindow)
        refresh = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateStatus() }
        }
        updateStatus()
        let menu = NSMenu()
        let appMenu = NSMenu(); let appItem = NSMenuItem(); appItem.submenu = appMenu; menu.addItem(appItem)
        appMenu.addItem(withTitle: "Show Lock In", action: #selector(showWindow), keyEquivalent: "0").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Lock In", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = menu
    }
    func updateStatus() {
        status.button?.title = model.active == nil ? "◎ Lock In" : "◎ \(model.countdown)"
        status.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        status.button?.toolTip = "Open Lock In"
    }
    @objc func showWindow() { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard model.active != nil else { return .terminateNow }
        showWindow()
        let first = NSAlert(); first.messageText = "Quit and end your focus session?"
        first.informativeText = "Quitting stops browser blocking. There is one more confirmation step."
        first.addButton(withTitle: "Keep focusing"); first.addButton(withTitle: "Continue")
        guard first.runModal() == .alertSecondButtonReturn else { return .terminateCancel }
        let second = NSAlert(); second.messageText = "Type UNLOCK to quit"
        second.addButton(withTitle: "Keep focusing"); second.addButton(withTitle: "End session and quit")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 26)); field.placeholderString = "UNLOCK"; second.accessoryView = field
        guard second.runModal() == .alertSecondButtonReturn, field.stringValue == "UNLOCK" else { return .terminateCancel }
        model.finish("ended early"); return .terminateNow
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
MainActor.assumeIsolated {
    let application = NSApplication.shared
    application.setActivationPolicy(.regular)
    let delegate = AppDelegate()
    application.delegate = delegate
    withExtendedLifetime(delegate) { application.run() }
}
