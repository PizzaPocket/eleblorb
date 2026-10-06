#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot

# The project's import cache is shared with the editor. A simultaneous editor
# and headless process has corrupted it before, so validation fails closed and
# tells the human what to do instead of racing the editor during a push.
if pgrep -f 'Godot.app/Contents/MacOS/[G]odot' >/dev/null 2>&1; then
	echo "ERROR: Close the Godot editor before village validation."
	exit 1
fi
if [ ! -x "$GODOT_BIN" ]; then
	echo "ERROR: Godot was not found at $GODOT_BIN"
	exit 1
fi

# The fishing village is validated from its plan alone, before anything is built.
if [ "${VILLAGE:-ohio}" = "fishing" ]; then
	"$GODOT_BIN" --headless --path "$ROOT" tools/validate_fishing_plan.tscn
	exit $?
fi

"$GODOT_BIN" --headless --path "$ROOT" tools/validate_village.tscn -- --village="${VILLAGE:-ohio}"
