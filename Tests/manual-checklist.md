# Manual acceptance checks

Do not use real work tabs to test: matching tabs navigate away and may lose unsaved content.

- Launch app, add `example.com`, and start a one-minute session.
- Grant Automation permission. Visit `https://example.com` and a path in a disposable Chrome normal tab; verify redirection to a blank page and an incremented redirect count.
- Repeat in a Chrome incognito tab, and repeat normal/private checks separately in Safari. Do not assume private coverage from normal-window results.
- Add a subdomain you control or can load, then verify blocking by a base-domain entry. Confirm unrelated suffixes are not redirected.
- Deny permission in a supported browser; verify an actionable error is visible. Grant it in Settings and verify recovery.
- Test Edge, Brave, Vivaldi, and Arc individually if installed; they are targets, not verified integrations.
- Add another domain while active; verify its tab redirects and history records the addition time.
- Verify removal is disabled while active.
- Cancel each override gate; verify the session continues. Incorrect `UNLOCK` must not end it.
- Close the window; verify menu bar time continues and clicking it reopens the window.
- Sleep and wake within a session; verify time elapsed. Sleep beyond scheduled end; verify completed history on wake.
- Quit during an active session; verify both gates. Force quit/reopen; verify interrupted history and no resumed monitoring.
- Complete a session, edit saved domains, and verify past history stays unchanged.
- Export CSV and inspect timestamps, durations, outcome, initial domains, and additions.
- Confirm no redirection after session completion (allow an already in-flight automation call to finish).

## Delayed start

- Enable Start after a countdown, open its time picker, and select 10 seconds. Choose a one-minute focus session. Verify zero delay disables Begin countdown until a positive delay is chosen (or turn the option off for immediate start).
- Start the countdown. Confirm matching tabs remain available, the window and menu bar both show the delay, and closing/reopening the window preserves it.
- When it reaches zero, confirm blocking starts automatically and a full one-minute focus session begins. Previously approved browser permissions should apply; first-use requests must be allowed at activation.
- Cancel a pending countdown. Confirm there is no later blocking and no history entry. Confirm the active-session override still requires both gates after activation.
- Edit the block list during the delay; verify the active session uses that list. Removing the last site must cancel the countdown with an explanation.
- Quit while pending: Keep countdown should cancel quitting; Cancel countdown and quit should exit. Reopen and verify no countdown resumes.
- Sleep past the deadline and wake; verify a full session starts at wake and history excludes the delay/sleep interval before activation.
