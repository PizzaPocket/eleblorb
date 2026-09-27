#!/usr/bin/env python3
"""Fail if a traversal power is wired to some playable characters but not all.

Every suit power, accessory and traversal mode in this game is meant to be
available to every playable character, on a rig of any size or shape (see
docs/traversal_powers_architecture.md). The mechanism is a shared
TraversalMode: written once, named by no character, driven by each one.

The failure this catches is the easy one to make and the hard one to notice.
A power gets built inside whichever character was being played at the time,
or lifted into a shared mode and then wired to only that one character. It
works, it ships, and the other characters silently do not have it. Vine
swinging was written entirely inside player.gd this way; before it, the
skate, penguin, snowboard and mermaid foot poses were all no-ops on Xiao Hou
Zi without anyone noticing.

So this measures rather than trusts. A "driver" is any script that builds a
TraversalContext, which is what driving a body through the shared powers
requires, so a third playable character counts the moment it exists without
this file needing to learn its name. A power referenced by one driver and not
another is reported with the driver that is missing it.

Run from the repository root: python3 tools/check_power_parity.py
"""

import re
import sys
from pathlib import Path

SCRIPTS = Path("scripts")
## A power not yet driven by every character belongs here, with the reason. An
## empty allowance is the intended state, and an entry here is debt rather than
## a design decision unless it says otherwise.
EXEMPT: dict[str, str] = {
    "FlightMode": (
        "player.gd still flies on its own inline attitude code; moving it onto the"
        " shared mode is the remaining slice of the traversal refactor. The human"
        " can fly, so this is duplication rather than a missing power."
    ),
}


def main() -> int:
    if not SCRIPTS.is_dir():
        print("check_power_parity: run me from the repository root", file=sys.stderr)
        return 2

    sources = {path: path.read_text(encoding="utf-8") for path in sorted(SCRIPTS.glob("*.gd"))}

    drivers = [p for p, text in sources.items() if "TraversalContext.new(" in text]
    modes: dict[str, Path] = {}
    for path, text in sources.items():
        if not re.search(r"^extends TraversalMode\s*$", text, re.M):
            continue
        name = re.search(r"^class_name\s+(\w+)", text, re.M)
        if name:
            modes[name.group(1)] = path

    if len(drivers) < 2:
        print(f"check_power_parity: only {len(drivers)} driver found, nothing to compare")
        return 0

    failures: list[str] = []
    for mode, mode_path in sorted(modes.items()):
        word = re.compile(rf"\b{re.escape(mode)}\b")
        wired = [d for d in drivers if word.search(sources[d])]
        if not wired:
            # Nobody drives it yet. That is a power under construction, not a
            # power one character has and another does not.
            continue
        missing = [d for d in drivers if d not in wired]
        if not missing:
            continue
        if mode in EXEMPT:
            print(f"  {mode}: limited to {len(wired)} of {len(drivers)} drivers ({EXEMPT[mode]})")
            continue
        failures.append(
            f"{mode} ({mode_path}) is driven by "
            + ", ".join(p.name for p in wired)
            + " but not by "
            + ", ".join(p.name for p in missing)
        )

    if failures:
        print("check_power_parity: a traversal power is not available to every character:\n", file=sys.stderr)
        for line in failures:
            print(f"  - {line}", file=sys.stderr)
        print(
            "\nEvery power belongs to every playable character. Drive it from each"
            "\ncharacter's own frame the way the others are driven, or, if it truly"
            "\nhas to be limited, record the reason in EXEMPT in this file.",
            file=sys.stderr,
        )
        return 1

    print(
        f"Power parity check passed: {len(modes)} powers across "
        f"{len(drivers)} playable characters."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
