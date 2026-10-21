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
