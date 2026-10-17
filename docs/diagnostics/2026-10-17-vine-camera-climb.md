# Vine camera climb: stopping point, 2026-10-17

Implemented a small change in the existing shared vine system:

- Camera pitch starts requesting climb above 15 degrees and reaches full intent at 65 degrees.
- Anchor search adds one steeper ray per bearing while retaining the existing fan as fallback; rope range is unchanged.
- Looking up reels along a taut held vine at up to 3 world metres/second. The existing 12 m rope minimum remains. Level aim stops reeling; existing momentum is retained.
- Rope length decreases only by actual physics movement. A blocking ceiling stops the pull rather than allowing the rope clamp to drag the body through it.
- Xiao Hou Zi’s wrapper now supplies the active camera basis and camera aim to the same shared mode. The human already supplies these.

Verification: `tools/validate_vine_climb.tscn` passed with zero failures in the isolated imported scratch project. Both human and small-character profiles rose approximately 6 m in two seconds starting at 35 m above terrain, beyond the startup assist’s 30 m baseline. Checks also cover level/dead-zone aim, stopping reeling, ceiling blocking, the minimum rope length, higher anchor targeting within range, and keeping the current grip when a handover fails. Power parity, body pose ownership and diff whitespace checks pass. The parity checker retains its preexisting FlightMode debt warning.

Repeat with Godot headless in an isolated imported copy:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path SCRATCH_PROJECT tools/validate_vine_climb.tscn
```

Stopping at the owner’s request. No visual/live-controller feel review has been performed for this change; the next check is a brief human and Xiao Hou Zi swing/climb through real city buildings. No commit, push or web export. Other in-progress Moy changes were preserved.
