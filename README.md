# Lock In — macOS prototype

Native SwiftUI/AppKit focus app. Requires Apple Silicon and macOS 14 or newer. Built using the Swift compiler supplied with Apple's Command Line Tools; full Xcode is not required.

## Build and run

```sh
./build.sh
open 'build/Lock In.app'
```

The app stays in the menu bar when its window closes. Click its menu bar countdown to reopen it. Use the app menu or Command-Q to quit. Quitting an active session requires confirmation followed by typing `UNLOCK`.

## Use

1. Add domains such as `instagram.com`. Pasted URLs normalize to their host. Add the base domain to include all its subdomains and paths. Entries are never automatically reduced to their registrable domain: `www.instagram.com` does not also block `instagram.com`.
2. Choose hours, minutes, and seconds (1 second to 6 hours). To start later, turn on **Start after a countdown**, click the delay to choose minutes/seconds (1 second to 59 minutes 59 seconds), then click **Begin countdown**. Otherwise click **Start focus session**.
3. Allow macOS Automation requests for the supported browsers you want monitored. If denied, enable Lock In under System Settings → Privacy & Security → Automation. The app displays automation failures.
4. During a session, additions take effect on the next available browser scan. Existing entries cannot be removed.
5. To end early, confirm and type `UNLOCK` exactly.
6. Open the ⋯ menu at the top right, choose Session history, or export CSV from that view. Use Back to focus to return.

## Blocking scope — read before relying on it

This is **browser redirection**, not a network content filter. Once per second while a session is active, the app requests open-tab URLs from running supported browsers and redirects matching tabs to `about:blank`. Normal page loading may happen before redirection, media may briefly play, and downloaded or cached content is not erased. Existing matching tabs are redirected too. Tab addresses are processed in memory, not logged or persisted.

Targets: Safari, Google Chrome, Microsoft Edge, Brave, Vivaldi, and Arc. Browser-specific AppleScript support and permission determine actual coverage. Chrome incognito is included by its window/tab scripting model, but requires live verification. Safari private windows, Arc, and other browsers are **not certified** by this prototype. Firefox, embedded browsers, other native apps, alternate domains, non-web protocols, and network requests outside accessible tabs are not covered. A denied permission means that browser is not protected. A transient in-flight browser automation request can finish shortly after ending a session. No browser extensions, hosts-file edits, DNS changes, administrator privileges, or network configuration are used.

Automation timeout errors are surfaced, but a browser silently omitting private tabs cannot be detected reliably. Do not interpret a healthy monitoring status as verified universal coverage. Browser runtime integration requires manual testing on your machine.

## Timer and recovery

The countdown uses a scheduled wall-clock end time, so sleep counts toward the session. Changing the system clock can affect it. If the app remains running during sleep, a session that expires during sleep is completed at its scheduled end on wake. A force quit, crash, or power loss stops redirection. On relaunch, a saved active session becomes `interrupted` and is not resumed, even if its scheduled end passed while the app was closed. Its recorded end is the last saved activity, normally within five seconds while awake; after sleep it may be much earlier. Normal quitting while active requires both override gates. The app has no persistent network rules to clean up.

## Data

`~/Library/Application Support/Lock In/state.json`

The JSON stores your saved domains, active-session checkpoint, and history. History includes initial domains and timestamped additions, planned and elapsed seconds, dates, and outcomes. Writes are atomic. Unreadable saved data is preserved and further saves are disabled until it is repaired or moved. CSV timestamps include their timezone (UTC); the UI displays local time. There is no account, analytics, cloud sync, or browsing history collection. CSV includes completed/interrupted sessions; an active session is included after it ends.

## Validation

```sh
./test.sh
```

Automated checks cover domain normalization and boundary matching, second-level duration validation and the six-hour limit, removal restrictions, session snapshots, interruption recovery, persisted additions, and CSV escaping. See `Tests/manual-checklist.md` for permission and browser checks. This development build is ad-hoc signed, not notarized or App Store distributed.

## Source map

- `Sources/Session.swift`: domain rules, session data, CSV export.
- `Sources/AppModel.swift`: persistence, session transitions, countdown.
- `Sources/BrowserGuard.swift`: browser automation and redirects.
- `Sources/main.swift`: native window, menu bar, history, override gates.
- `Resources/Info.plist`: app identity and Automation permission explanation.
- `build.sh`, `test.sh`: reproducible local build and checks.

The app uses a bundled vector lock-and-focus icon at all standard Dock sizes. The build stages a new bundle before replacing the old one and retains the previous build under `build/previous.*`. Reopen the app after a build to use the updated version.

## Delayed start (0.3.0)

The optional pre-session countdown leaves websites available until it expires. The window and menu bar display the remaining delay separately from focus time. Cancel it with one click; the double confirmation remains required once blocking has started. Session duration is fixed when you schedule it. Block-list edits are allowed during the countdown, and the session uses the current list at activation. Removing the last website cancels the countdown with an explanation.

Keep the app running: closing the window is fine, but quitting cancels the countdown (with a confirmation). A crash, shutdown, or relaunch does not restore a pending countdown. Delay time passes during sleep; if the deadline passes while asleep, a full focus session starts on wake, when blocking can actually begin. Countdown time and cancelled countdowns are not recorded as focus sessions. The six-hour cap applies to focus time; the start delay is separate. Browser permissions are first requested when blocking starts, so allow those promptly the first time you use it.
