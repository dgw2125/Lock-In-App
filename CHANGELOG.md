# Release notes

## 0.3.0 — November 2, 2026

- Added an optional countdown before a focus session starts, configurable in minutes and seconds.
- Show the delay in the window and menu bar; cancel it before blocking begins.
- Start a full focus session when the countdown finishes, using the current block list.
- If the Mac sleeps past the countdown, start the session on wake. Quitting or restarting cancels pending countdowns.
- Exclude countdown time from focus history. Existing double-confirmation overrides still apply to active sessions.

## 0.2.0

- Added a Dock icon.
- Added hours, minutes, and seconds controls with a six-hour session limit.
- Moved session history to the top-right More options menu.

## 0.1.0

- Initial native macOS prototype: saved block list, browser redirection, focus timer, menu bar countdown, two-step early exit, session history, and CSV export.
