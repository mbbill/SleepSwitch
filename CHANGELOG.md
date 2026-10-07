# Changelog

## 1.6.1.1

- Allow display idle sleep while awake mode continues to block system sleep.
- Physical closed-lid backlight behavior still requires verification on the target Mac.

## 1.6.1

- The lease is now written **before** the ban is armed rather than after. Recorded
  afterwards, a kill landing between the two calls left a ban with no lease — and a missing
  lease is what tells the agent "somebody else armed this, leave it alone", which is the one
  reading that must never apply to a crash of ours. A narrower window than 1.6.0 closed, but
  the same ending.
- Writing ahead costs a claim that can briefly exist with no ban behind it, so the app drops
  the claim as soon as the ban turns out not to be there, and the agent removes a stale claim
  it finds standing alone. Left lying around, such a claim would later attach itself to a ban
  somebody else armed and turn the honest "not ours" case into a wrong clear.
- Only stale orphan claims are removed, so a claim written a moment ago and not yet armed is
  never pulled out from under a live app.

## 1.6.0

- **The sleep ban can no longer be left armed by a crash.** Every recovery path lived
  inside the app: the quit handler, the logout handler and `SIGTERM`. None of them is
  reached by `SIGKILL`, a Force Quit or a kernel panic, and the setting outlives all three
  — so the Mac would keep skipping sleep with no menu bar icon to explain it, and with the
  battery guard gone as well, since that runs in the same process. The one failure that
  armed the setting was the one that removed its guard.
- A launch agent now reconciles it at login and every minute. While the ban is the app's,
  the app renews a lease file; a stale lease means it died holding the ban, and the agent
  clears it. **No lease means the ban was never ours** — armed by hand in a terminal, say —
  and the agent leaves it alone.
- A user agent, not a root daemon: it needs no privilege of its own and clears the ban
  through the same narrow sudo rule the app uses. Without that rule there is still nothing
  it can do quietly, which is one more reason the installer sets the rule up by default.

## 1.5.0

- **A cue when the lid moves** while the mode is on: a muted porcelain tone as it closes,
  a higher one as it opens. Off from the menu, and silent with the mode off — closing the
  lid then means sleep, which needs no announcing.
- Only on Macs that have a lid. An iMac has no `AppleClamshellState` to report, so neither
  the watcher nor the menu item exists there.
- The sounds are synthesised at build time like the icon, so no audio files live in the
  repository and nobody's sample is being borrowed.
- The clamshell, unlike the sleep ban, does arrive through the IOKit interest notification,
  so this needs no polling. Unrelated power messages share that channel, so the state is
  re-read and compared rather than trusting an undocumented message type.

## 1.4.0

- **Uninstall from the menu**, behind a confirmation. Anyone who installed the `.pkg` had no
  way to remove the app cleanly — `uninstall.sh` lives in the repository, not on their disk.
  It clears the sleep ban first, while the sudo rule is still there to make that quiet, then
  removes the app, the rule, the receipt and the settings, and quits.
- **A warning the first time the mode is switched on without the sudo rule.** The ban is a
  system setting: without the rule the app cannot clear it quietly at logout, and a modal
  password dialog there would block the shutdown — so it survived into the next boot, where
  the app might not even be running to show it. The warning offers to set the rule up on the
  spot, and is shown once rather than on every switch.

## 1.3.1

- The battery settings are hidden on a Mac with no built-in battery instead of sitting
  there inert.
- The battery is now identified by power-source type rather than by taking the first source
  the system lists. A UPS is a power source too, so on a desktop it could have passed for a
  battery — and on a laptop with a UPS attached the app could have read the wrong one.

## 1.3.0

- **Battery guard.** Keeping a Mac awake makes one mistake easy — mode on, lid shut, laptop
  in a bag, running hot until the battery is flat. The mode now switches itself off at a
  charge you choose, 20% by default, and optionally the moment the power adapter is
  unplugged. A notification says which of the two fired.
- Neither trips on a desktop Mac or when the battery reading is missing: dropping the mode
  for a reason the app cannot name would be worse than leaving it alone.
- Power source changes arrive as events rather than polling — `IOPSNotificationCreateRunLoopSource`
  is public, unlike anything covering the sleep ban.

## 1.2.1

- Notification permission is asked for once, the first time there is an update to report,
  instead of on every check. If notifications are denied the app falls back to a window,
  but only once per version — a daily popup would be exactly the interruption the
  notification was meant to avoid.
- The sleep-mode state machine now takes its privileged half as a dependency, so the paths
  that matter are covered by tests: a declined password leaves the mode partial rather than
  off, a ban the app did not set is never cleared on the way out, logging out never opens a
  password dialog, and partial mode is not mistaken for the mode being switched off.

## 1.2.0

- A background update now arrives as a system notification with **Download** and **Skip
  this version**, instead of a modal dialog thrown over whatever you were doing. A check
  you start from the menu still answers in a window — you are waiting for that one.
- Turning the mode on at launch no longer means a password dialog at every login. Without
  the sudo rule it comes up in partial mode instead, and ticking the checkbox now explains
  that and offers to set the rule up.
- State is re-read every 30 seconds rather than every 5, plus on wake and whenever the menu
  opens. macOS publishes no notification for this setting — the general IOKit interest
  notification on IOPMrootDomain does not fire for it and IOPMLib exposes nothing public —
  so polling stays, just far less of it.
- The sources are split by responsibility instead of living in one file, and all code,
  comments and script output are English.

## 1.1.2

- The menu now shows which version you are running. With an app that updates itself, the
  answer used to require Finder → Get Info.
- A failed update check no longer counts as a check. Being offline once used to postpone
  the next attempt by a full day.
- CI installs the built `.pkg` for real and inspects what it did: the `sudo` rule is
  validated with `visudo`, its mode and owner are asserted, and it must grant exactly the
  two `pmset` commands and nothing else. Then `uninstall.sh` runs and the removal is
  verified. These installer scripts run as root and had no test coverage at all.

## 1.1.1

- Removed the «Keep the screen on» checkbox. The screen now stays lit whenever the mode is
  on, and dims normally when it is off. The switch was confusing: its only effect showed up
  after the idle timer expired — tens of minutes later — so toggling it looked like it did
  nothing at all.

## 1.1.0

- English and Russian throughout: app menu, alerts, and the installer, following the
  system language.
- Update check against GitHub releases, once a day, switchable from the menu. The app
  downloads the `.pkg` and hands it to the system Installer instead of replacing itself;
  requests are pinned to `https` on GitHub hosts, redirects included.
- A missing translation now fails the build — `Tools/check-localization.sh` diffs the
  `L("…")` keys in the sources against every `Localizable.strings`.
- Tests for version comparison and download-source filtering, run in CI.

## 1.0.1

- App icon, drawn in code at build time.
- English README alongside the Russian one.

## 1.0.0

- Menu bar toggle: blocks lid-close sleep via `pmset -a disablesleep`, and idle sleep and
  display sleep via IOKit assertions.
- `.pkg` installer with an optional, narrowly scoped `sudo` rule so toggling never asks
  for a password.
- The sleep ban lifts itself on quit and on `SIGTERM`, and the real state is read back
  from `IOPMrootDomain` at launch.
- Universal binary, GitHub Actions build and release by tag.
