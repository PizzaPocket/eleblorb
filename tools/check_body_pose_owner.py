#!/usr/bin/env python3
"""Fail if anything but the body-pose owner writes the player's rendered body.

player.gd places `visuals` (the rendered body) in exactly one pass,
_compose_body_pose(), plus the helpers it calls and two exclusive cinematic
owners. Several independent writers once each "fixed" a landmark and the last
one each frame silently won; that is how flight's skull pin was overwritten.
This check keeps new writers from creeping back in: route new behaviour
through _body_yaw, _body_base_height() or a _pose_body_* mode instead.

Run from the repository root: python3 tools/check_body_pose_owner.py
"""

import re
import sys
from pathlib import Path

PLAYER = Path("scripts/player.gd")

# Functions allowed to assign to visuals' transform.
ALLOWED = {
    # The owner and its placement modes.
    "_compose_body_pose",
    "_pose_body_ground",
    "_pose_body_foot_hover",
    "_pose_body_skull_anchored",
    "_pose_body_flight_exit",
    "_pose_body_dirtbike",
    # Helpers called only from the placement modes.
    "_apply_dirtbike_wheelie_pitch",
    "_settle_dirtbike_rear_wheel_on_terrain",
    "_apply_snowboard_surface_orientation",
    # Exclusive owners: mounted riding and the wake-up cinematic.
    "_apply_manchego_seated_pose",
    "_update_manchego_dismount",
    "_finish_manchego_dismount",
    "_apply_wake_intro_pose",
    "_finish_wake_intro",
    # One-off placement.
    "_ready",
    "set_body_heading",
}

WRITE = re.compile(
    r"\bvisuals\.(position|rotation|global_position|global_rotation|"
    r"global_transform|transform|basis|global_basis)\b[.\w]*\s*[-+*/]?=(?!=)"
)
FUNC = re.compile(r"^(?:static\s+)?func\s+(\w+)")


def main() -> int:
    current = None
    violations = []
    for number, line in enumerate(PLAYER.read_text().splitlines(), start=1):
        match = FUNC.match(line)
        if match:
            current = match.group(1)
        code = line.split("#", 1)[0]
        if WRITE.search(code) and current not in ALLOWED:
            violations.append(f"{PLAYER}:{number} in {current}(): {line.strip()}")
    if violations:
        print("Body transform written outside _compose_body_pose():")
        print("\n".join(violations))
        print("Route it through _body_yaw, _body_base_height() or a _pose_body_* mode.")
        return 1
    print("Body pose owner check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
