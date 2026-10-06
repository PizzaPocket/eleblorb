# Handoff: Snow Village (Ice Kingdom)

Status (2026-10-04): rebuilt from one authored plan. `VILLAGE=snow
tools/check_village_layout.sh` reports 0 failures. Nothing is committed. Same
publishing and attribution rules as `docs/handoff_ohio_village.md`, same Godot
ground rules (editor closed, one process at a time, capture tool needs a window,
new `class_name` needs `--import`).

## Where things live

- `scripts/snow_plan.gd`: layout, ways, schedules, `TRADE` ledger.
- `scripts/log_house.gd`: laft log shell (whole courses, notched corners, true
  gaps at openings, casing, bellcast roof, rakes).
- `scripts/nordic_hearth.gd`: peis, kakelugn, kiuas.
- `scripts/snow_buildings.gd`: programme openings, gallery, lean-to, stabbur,
  bell turret. `scripts/snow_interiors.gd`: interiors with flat 3.12 m ceilings.
- `scripts/snow_grounds.gd`: landscape pass (snow banks, cold frames, windbreaks).
- `scripts/ice_kingdom_village.gd`: generator, layout report, inn rest function.
- `scripts/ice_kingdom_terrain.gd`: heightfield; bunny run end and chair lift
  lower station moved onto the village pad; ice-break notch.
- `scripts/ice_lake_features.gd`: Penguin Helm chest on a sunken skiff, fallen
  cedar breaking the ice at the rim as the way out.
- Docs: `docs/architecture/snow_village.md` (the working document),
  `docs/world_bible.md`, `docs/architecture/settlement_backlog.md` section 2.
- Probes: `tools/probe_snow.gd`, `tools/ice_lake_probe.gd`,
  `tools/log_house_preview.gd`.

## Done

Plan, shells, hearths, interiors, inn rest function, trade ledger, resident
schedules and dialogue (no-ai-slop pass), landscape pass, lake feature, sounds
for doors and chests.

## Not yet verified

1. Snow banks (chunked version) visually.
2. Eye-level interior checks (several capture cameras landed inside furniture;
   use top-down `--cut=3.05` cutaways or move the camera).
3. A walked play-test with the human and Blorbus.
4. Sound audibility (doors, chests, special-find sting).
5. Tuning: snow caps on roofs read pillowy.

After these checks, move to the Crossroads Fishing Village planning and rebuild
in `docs/architecture/fishing_village.md`. Chinese Village implementation is
held until that settlement pass is approved.

## Snow walkthrough (2026-10-04): current work

The user's list is in `docs/snow_walkthrough_issues.md` (S1 to S14). Fixed in
code: S2 to S8 and S12 to S14. S1 and S9 are partly fixed. The current scratch
validator result is 0 FAIL, 5 schedule-overlap warnings. The construction and
interior changes still need visual and walked checks. Remaining order:

1. **S1/S9 visual interior audit.** Add a furniture-inside-walls check and move
   remaining hand-authored furniture through `RoomLayout` where the eye-level
   audit exposes a problem. Enlarge only buildings whose actual programme still
   cannot fit.
2. **S2 to S8 visual audit.** Check the flush corner joints, squarer logs and
   openings, clipped double doors, Astrid's orientation, and all three scheduled
   hearth types in isolated lightweight scenes.
3. **S10 floating hut with red door and S11 roofs over entries.** Identify the
   reported hut in an isolated view, then verify its ground connection, stair
   landing, entry headroom and every roof-to-door clearance.
4. **S12 walked ride check.** Full-span terrain sampling is now in the validator
   and the cable raises adjacent supports over intervening crests while terminal
   heights remain fixed. Ride both lanes to confirm the adjusted support profile
   reads naturally and no chair, rider or hanger meets the mountain.

## New audit findings (2026-10-05)

The stacking, furniture-inside-wall, door-frame and chest-orientation audits now run
on Snow and report 8 FAIL (see ledger S16): two upper walls with nothing below in each
of the Rescue Hall and the Textile House, and four pieces standing inside walls (Inn
shelf and counter, Inn Wing bed, Rescue Hall shelf). Run
`Godot --headless --path <scratch copy> tools/validate_village.tscn -- --village=snow`.
