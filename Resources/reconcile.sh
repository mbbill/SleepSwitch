#!/bin/bash
# Clears a sleep ban that SleepSwitch armed and then died still holding.
#
# The app can only clear the ban from inside its own process, and SIGKILL, a force quit and
# a kernel panic never reach those handlers. The setting outlives all three, so the Mac
# would keep skipping sleep with no menu bar icon left to explain it — and with the battery
# guard gone too, since that lives in the same process. This runs at login and every minute
# to catch exactly that.
set -u

LEASE="$HOME/Library/Application Support/SleepSwitch/ban.lease"
STALE_AFTER=300

/usr/sbin/ioreg -n IOPMrootDomain -r -d 1 | grep -q '"SleepDisabled" = Yes' || exit 0

# No lease means the ban was never ours — somebody armed it by hand, and undoing another
# party's setting is not this script's business.
[ -f "$LEASE" ] || exit 0

MODIFIED="$(/usr/bin/stat -f %m "$LEASE" 2>/dev/null)" || exit 0
AGE=$(( $(/bin/date +%s) - MODIFIED ))

# Renewed within the window: the app is alive and still wants the ban. The margin over the
# app's 30-second renewal is deliberate — a background app can be throttled, and switching
# the mode off under someone who is using it would be worse than reacting a minute late.
[ "$AGE" -ge "$STALE_AFTER" ] || exit 0

if /usr/bin/sudo -n /usr/bin/pmset -a disablesleep 0 2>/dev/null; then
	/bin/rm -f "$LEASE"
	echo "SleepSwitch: cleared a sleep ban left behind ${AGE}s ago."
else
	# Without the sudo rule there is nothing this can do quietly, and prompting from a
	# background agent is not an option. Leave the lease so the next run tries again.
	echo "SleepSwitch: the ban is stale but cannot be cleared without the sudo rule." >&2
fi
