# Handoff: Ohio starting village

Status (2026-10-04): validated and visually audited. The guarded validator
(`tools/check_village_layout.sh`) reports 0 FAIL and 2 WARN (Vey house to
storehouse 2.9 m, Sallow cottage to drying shed 2.9 m, both usable maintenance
passages). Nothing is committed. The working tree holds many unrelated modified
files, so review `git status` before staging. Follow `AGENTS.md` and `CLAUDE.md`
for publishing (regenerate and validate `build/web` before any push, never
credit an AI as author or co-author).

## Next (read this first)

State at the end of the 2026-10-04 session: the user's live walkthrough produced
28 items, logged with causes in `docs/ohio_walkthrough_issues.md`. Most are
"Fixed (code)": changed and validated (0 FAIL) but NOT yet seen in engine. The
first job next session is a second walkthrough to confirm them by eye, especially
the new hearth and chimney, house interiors, the windmill, the bell (listen to
it), the granary roof and the corner posts. Then, in priority order:

1. **Roofs as SuperEggs cut at the ridge (ledger 15, OPEN).** Roof panels are a
   hand-built mesh (`TownProps._roof_panel_mesh`). Build `SuperEgg.build_clipped_part`
   (a superellipsoid clipped by planes with a flat cap and correct normals), use
   it for each slope cut at the ridge, and use the same builder for double-door
   leaves (each leaf half a SuperEgg, cut on the inside edge as well as the
   bottom, like the shutters) in `TownProps._build_door_leaves`/`WorldDoor`.
2. **Overlook path and stonework (ledger 23, 24, OPEN).** The way to the cliff is
   broken (path paint fades off steep ground; strokes end early). The terrace
   pavers follow the terrain normal, which at the cliff is nearly horizontal, so
   they tilt over the edge; the walking surface slides like ice. Use a flat
   walking slab at terrace level with the existing stones as dressing, skip or
   clamp pavers on steep ground, make the path continuous to the terrace, and
   add coping stones along the edge so it reads as stonework.
3. **Ledger 17:** give Snow's `NordicHearth` and the other kingdoms' inn hearths
   the same treatment (`HearthFire` schedule, firebox floor, logs, surround).
4. **Ledger 28:** ask which inn room and piece shows feet through the ceiling.
5. Walked play-test with the human and Blorbus.

## Tools you now have

- **Scratch-copy workflow (safe while the editor is open).** Never run Godot on
  the live project. Mirror it and run there: `rsync -a --delete --exclude build
  --exclude wip --exclude .git --exclude .godot ./ <scratch>/proj/`, run
  `--import` once there after adding any `class_name`, then
  `Godot --headless --path <scratch>/proj tools/validate_village.tscn -- --village=ohio|snow`.
  The session used `scratchpad/sync.sh` and `validate.sh` (not committed).
- **`tools/validate_village.gd`** now also fails: lanterns pointing away from
  what they serve; furniture inside a door, ramp, window or fire clear zone;
  ramp lanes too low or blocked for a person; pieces `RoomLayout` could not place.
  It warns on residents stationed at the same spot and hour.
- **`scripts/clear_zones.gd`** (`ClearZones`): `add()` zones and `add_lane()` walking
  lines on a building body; `Furnishings.piece` tags solid furniture;
  `audit()` is the check. **`scripts/room_layout.gd`** (`RoomLayout`) places
  furniture so it cannot block these. **`scripts/ohio_interiors.gd`** furnishes
  each house from its household; **`scripts/trade_furnishings.gd`** has the trade
  pieces. **`scripts/hearth_fire.gd`** schedules fires.
- **Probes:** `tools/npc_motion_probe.tscn` (`-- --world=snow` for Snow),
  `tools/house_probe.tscn` (`-- --house=<Name>`), `tools/ice_ocean_probe.tscn`.

## Added 2026-10-05: stacking, swing, heat, frames, chests

The Holt Inn is replanned as a stack (`docs/architecture/ohio.md` 7a); new audits
`ClearZones.audit_stacking`, furniture-inside-wall, route widths, door-frame depth and
chest orientation all pass on Ohio (0 FAIL) and each was proved by re-introducing its
bug in the scratch copy. Still to look at by eye: the inn's new upper plan, the
summer beam and posts in the common room, the gallery widths, and the transom
grilles (planned, not built). Apply the same stacking drill to every other two-storey
Ohio building and to Snow (`audit_stacking` already runs there).

## Standing rules learned this session

- A directional fixture's yaw is always derived from the point it serves
  (`VillageWorks.yaw_facing`), never typed.
- Furniture is placed through `RoomLayout`, never by hand coordinates, and every
  door, ramp, window and fire registers a clear zone.
- A hearth is one masonry body through the wall, centred on its gable.
- An NPC stop's wander distance scales with its range.
- Roof posts end under the slab on its slope; walls under a pent roof are cut to it.

## Ground rules

- Never run headless Godot while the user's editor is open, and never run two
  Godot processes at once. Both corrupt the `.godot/` cache. Check
  `pgrep -fl Godot` first. `tools/check_village_layout.sh` refuses to run while
  the editor is open. Do not bypass it.
- A new `class_name` script needs `Godot --headless --path . --import` first.
- `tools/village_aerial_capture.gd` needs a window (it hangs under `--headless`).
- Build props from SuperEgg parts. Posts and logs are squarish SuperEggs.
- No in-game text that explains a mechanic or nudges the player.
- The inn keeps its toilet (ground floor, back right, behind its own partition),
  reachable.
- No masking dressings: no shore band on the tarn (polygon shore is fine), no
  hedge ring, no rim wall, no walls around the town.
- Prose: no em dashes as a clause joiner, no hollow intensifiers.
- Every stall item needs a maker in `OhioPlan.TRADE`.

## Where things live

- `scripts/ohio_plan.gd` (`OhioPlan`): the single authored layout (buildings,
  ways, yards, gardens, water works, schedules, `upper_beds`, `TRADE` ledger).
  `TownGenerator` builds only from it.
- `scripts/town_generator.gd`: builds from the plan (`_build_building`,
  `_dress_ohio_building`, `_build_ohio_entrance`, `_build_overlook`, waterworks,
  sawmill drive, `_furnish_upper_floor`).
- `scripts/town_props.gd`: shell, panel walls, roofs, stair and ramp holes,
  interior walls, shutters.
- `scripts/village_inn.gd`: inn ground plan, upper guest rooms, furnishings,
  toilet.
- `scripts/hearth.gd`, `furnishings.gd`, `facade_features.gd`, `roof_forms.gd`,
  `entry_dressing.gd`, `village_works.gd`, `terrain_generator.gd` (tarn, mill
  pad, overlook pad).
- Docs: `docs/architecture/ohio.md`, `docs/world_bible.md`,
  `.claude/skills/architecture/SKILL.md`.
- Tools: `tools/validate_village.gd`, `tools/check_village_layout.sh`,
  `tools/village_aerial_capture.gd` (`--shots=name:fx,fz,tx,tz,height[,target_height]`,
  `--cut=H`; renders to `wip/village_audit/`).

## What is built

Holt Inn with open two-post porch, double entrance, planned upper floor and
toilet. Civic hall (5x3, cross-gable, belfry, dais, archive, bell rope).
Cray and Fask & Prewitt houses enlarged for ramp heads. Mill on the village
side of the leat, wheel on the north wall, door south. Bakehouse with rear shed
and oven. Kitchen and physic gardens with raised beds. Overlook pad, graded
stone paving and slope-coloured cliff. Every two-storey house has a furnished
sleeping floor. Residents and vendors have schedules and dialogue shaped by the
bible's social ties. Pip, Tess and Wick are scaled NPCs at their work areas.
Shutters, trellis, woodstack and bench placement cleared of windows.
