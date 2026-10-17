# Moy: second prototype pass, build instructions

> **Next: [moy_prototype_pass_3.md](moy_prototype_pass_3.md)** reviews this pass and lists the changes since (2026-10-17).

2026-10-17. Instructions for the next implementation chat. They replace nothing
in `moy_playable_prototype.md` (the first pass's contract) except where they
say so: **read that contract's sections 4 to 8 (scope, loading, collision,
world fit, acceptance) and keep following them.** This document tells you
exactly what changed in the plan since the first prototype was built, and
exactly what to change in the prototype.

Follow the steps in order. Do not redesign anything. If the data and this
document disagree, the data (`scripts/city_plan.gd`) wins; report the
disagreement in your diagnostic.

## 0. Words used here

- **The Deck**: the walkway at +6.5 m (`DECK`). The owner sometimes calls it
  "the High Line" (after New York's). In the data, **"the high line" means
  the Meridian Line** at +36 m. Do not mix them up.
- **The Spine**: the north-south train line at +13.2 m rail.
- **The Wall Line**: the ring line on top of the wall at +13.2 m rail.
- **The Crossing**: the station in the middle of the park where the Spine
  and the Meridian cross.
- **Rail height** is the top of the rail. **Platform floor** is rail + 1.0.
- All x, z numbers are world coordinates. y numbers are metres above the
  city's ground datum (`DATUM` in the builder, about -60 world Y).

## 1. Read first, in this order

1. `AGENTS.md`, `CLAUDE.md`.
2. This document.
3. `docs/diagnostics/2026-10-17-moy-plan-iteration-2.md` (level lines,
   platforms, escalators, timetable).
4. `docs/diagnostics/2026-10-17-moy-plan-iteration-3.md` (the Crossing,
   the Deck's garden, the park's trees, the clock, the launch site).
5. `docs/architecture/moy_playable_prototype.md` sections 4 to 8.
6. `docs/drawings/moy_city_3d.html`: **read its construction code**. It
   draws every item in this document from the same data. When unsure how a
   value turns into geometry, copy what the model does.
7. `docs/architecture/city.md` sections 6 (the Deck), 6c, 6f, 6g, 7a, 7b,
   8a, 12, when you build each item.

## 2. What the first pass built, and why it is now wrong

The first pass (`scripts/moy_city_bake_builder.gd`, baked by
`tools/bake_moy_city.tscn`) was built from the plan **before** iterations 2
and 3. It works and its loading approach is good. Keep its structure (packs
per cell, offline bake, separate collision bodies per building). But these
parts of it are now wrong. Each must be removed or rebuilt as listed in
section 4:

| Builder code | What it does now | Why it is wrong now |
|---|---|---|
| `_needs_spine_portal` and the lot tunnel code in `build_packs` | Cuts a train tunnel (x -557, y 10.9 to 24) through lots | The Spine was moved to x -560 and is level; it no longer passes through any lot. No tunnels. |
| `_add_transit`: `service.profile` branch | Builds the Spine climbing to +20 m at the gates | There is no profile. The Spine is level at 13.2 everywhere. |
| `_add_transit`: `SpinePortalPier` at x ±5 every segment | Guesses frame positions | Use `CROSS.services[Spine].frames` exactly (section 4.6). |
| `_add_transit`: `MeridianTreePier` boxes | Piers at the old list, boxes only | Use the new `piers` list (8 piers; two removed) and add the Y branch and twin girders (section 4.7). |
| `_add_transit`: station platforms at rail + 0.1, centre ±5.2 | Wrong height and position | Floor at rail + 1.0, centre 4.4 m from the line, 3 m wide, 30 m long (section 4.5). |
| `_add_transit`: `SpineGateEscalator` and `SpineGateAccessWalk` at +20 | Gate flyover access | Delete. The gates are level interchanges. |
| `_add_station_core` for `PLAN.CROSSING.cores` | Old Crossing cores | `CROSSING.cores` is empty. Build the four garden towers instead (section 4.2). |
| `_add_gate_forms` (hardcoded numbers) | Arch legs at x -362..-340, West Gate towers 10 x 10 at x -790/-752, N/S gate posts and lintels at +26 | Rebuild from data: `ARCH.legs`, `WEST_GATE.towers`, `train_hall.arcs`; gate posts only from `WALL` (section 4.9). |
| `_add_deck`: columns as 0.9 m boxes; no parapets; no garden | | Columns are 0.6 m round (`DECK.col`), and there are now 164 of them; add parapets, beds and trees (section 4.3). |
| `_add_park`: no trees | | Plant every recorded tree and plant (section 4.4). |
| `_add_timekeeper`: three plain tori | | Add the arrows, ticks and bead; the minute ring is now outside the hour ring (section 4.8). |
| `moy_ride_train.gd` with 4 s dwell and junction conflict points | Simple shuttles | Run trains to `TIMETABLE` (section 4.10). |
| `tools/validate_moy_runtime.gd` | Expects 8 consists, 4 s dwell | Update to the timetable (section 6). |

## 3. Before you build

1. Run, from the repository root:
   ```sh
   python3 tools/city_layout.py --json /tmp/moy-plan.json
   ```
   It must print only `wrote scripts/city_plan.gd ...`. If it prints any
   `PROBLEM`, stop and report it. Never edit `scripts/city_plan.gd` by hand.
2. Run the Godot plan validator (`tools/validate_city_plan.tscn`) as in the
   first contract. Fix any failure caused by keys that changed (section 7
   lists them). Do not delete checks to make it pass.
3. Open `docs/drawings/moy_city_3d.html` in a browser and visit these
   places in its list: *The park and the Crossing*, *The Crossing's garden
   towers*, *A garden tower's landings*, *Changing lines at the Crossing*,
   *The Deck*, *The two lines and the Deck*, *The Timekeeper*, *The North
   Gate interchange*, *The launch site*. This is what you are building.

## 4. What to build or change

Build at the **same fidelity as the first pass** (simple SuperEgg or box
massing, plain materials), but **exact in position and size** for
everything people walk on, ride or climb: ramps, escalators, landings,
passages, platforms, columns, parapets, trees. Every walkable surface has
collision on layer 1. Every substantial object is solid. Foliage, blooms
and reeds are decorative (no collision) unless stated.

### 4.1 The lines are level; the gates are interchanges

- Spine rail 13.2, x = -560, from z -200 to +200. Wall Line rail 13.2.
  Meridian rail 36.0.
- Spine stations: North Gate (z -184), Estate Square (-100), The Crossing
  (0), Market Square (124), South Gate (184) (`CROSS.stations`).
- At North and South Gate, the two Spine platforms run on, level, onto the
  Wall Line's inner platform: build the slab `stations[...]._interchange`
  (gap and level are in the data; see the model's `_interchange` code).
- Buffer stops at both Spine ends.
- Delete every tunnel, flyover, gate escalator at +20 and interlock.

### 4.2 The Crossing (`CROSSING`)

Build exactly this, and nothing else, at the Crossing. The old halo, ring of
slender columns and spirals are gone.

1. **Four garden towers**, `CROSSING.towers[0..3]`, centres at (-547, -13),
   (-573, -13), (-547, 13), (-573, 13). Each tower:
   - a solid steel **trunk**, radius `tower.trunk` (1.2), from 0 to the
     roof (`roof.y` = 41);
   - **two escalator hands**, `towers[i].hands` (`up` and `down`). Each hand
     is a band from radius 1.4 to 4.0 (`tower.band`) following its
     `profile`: a list of `[bearing_from, bearing_to, y_from, y_to]` in
     degrees (0 = +x east, 90 = +z south). Where `y_from == y_to` the band
     is a **flat landing**; otherwise it climbs evenly. Bearings above 360
     wrap round (keep turning). Build each hand as a moving surface
     (`moy_escalator.gd`) that carries riders upward on `up` and downward on
     `down`. The landings do not move.
   - a **gallery** (an annulus from radius 4.0 to 5.8) at each level above 0
     (6.5, 14.2 and 37). Riders step off a hand onto its flat landing, then
     sideways onto the gallery. **The gallery's inner railing (1.1 m) is
     open only beside each hand's landing at that level**; everywhere else
     it is closed so no one falls onto the band. There is **no floor over
     the band** at the top: the top gallery is an annulus like the others.
   - **twelve ribs** (radius 0.22) on a circle of radius 6.0 (`tower.drum`),
     ground to roof, at bearings 15, 45, 75 ... degrees, with steel hoops
     every 4.1 m. Solid.
   - **climbers**: `CROSSING.climbers` rows `[tower index, bay bearing,
     y0, y1]`: a green panel on the outside of the ribs, 0.64 of a bay wide
     (about 23 degrees), centred on that bearing, from y0 to y1. Decorative.
     A planter (0.5 m) on the gallery's outer edge at the foot of each panel
     whose y0 > 0. Bays with no climber are open (that is where bridges and
     the ring connect).
   - **bridges**, 2.4 m wide, from the gallery's outer edge (5.8) straight
     to: the tower's Spine platform at +14.2 (toward x = -560) and its high
     line platform at +37 (toward z = 0). See `towers[i].opens`.
   - a **glass lift**, `towers[i].lift` (centre, radius 1.3), from 0 to
     37 + 3.4, stopping at 0, 6.5, 14.2 and 37, with a short landing to the
     Spine platform at 14.2 and to the high line platform at 37.
   - a **rain garden** (`CROSSING.rain_gardens`): a planted disc of radius
     `r` at the tower's foot and reed clumps at the listed points. Decorative.
2. **Head beams** (`CROSSING._beams`): the Spine's, east-west at z = -13 and
   +13, from tower face to tower face, y 10.4 to 12.0; the Meridian's,
   north-south at x = -573 and -547, y 30.6 to 32.6. The lines rest on these.
   No other column stands under either line inside the Crossing.
3. **The Crossing Ring**: a Deck run (`DECK.runs`, name `Crossing Ring`),
   8 m wide, centreline radius 28.7, 1.6 m deep (`ring_depth`), at +6.5. It
   stands on the towers and on the 8 columns in `CROSSING._ring_supports`
   (these are also in `DECK.columns`).
4. **Two cross-bridges** (`DECK.runs` `Crossing bridge north/south`), 6 m
   wide at +6.5, tower to tower at z = -13 and +13, hung from the Spine head
   beam by thin hangers. Low glass sides (1.3 m), no roof.
5. **The Spine walks** (`Spine walk north/south`) run from the Park Deck to
   the cross-bridges. **The middle (between the cross-bridges) is open**.
6. **The roof**: a superellipse slab, half-width 22, exponent 4, 0.6 thick,
   underside at +41, centred on (-560, 0), resting on the four tower tops;
   a 1.4 m planted rim. Solid (a landing).
7. **Platforms at the Crossing**: the Spine's two platforms (+14.2) get
   louvred canopies at +17.4; the Meridian's two platforms (+37) have no
   canopy of their own (the roof covers them).

### 4.3 The Deck (`DECK`)

- **Columns**: one round column (diameter 0.6) at every point in
  `DECK.columns` (164), from the ground to the Deck's underside (6.5 - 0.9).
  The first pass missed the whole Park Deck's columns (a data error, now
  fixed).
- **Runs**: unchanged method (centreline, width, 0.9 deep), but use the new
  run list (the Spine walk is two runs; new Crossing Ring and cross-bridges).
- **Parapets**: build **only** the segments in `DECK.parapets`, each
  `[x0, z0, x1, z1, height, kind]` on top of the Deck (+6.5): `rail` is a
  1.1 m steel railing, `glass` a bridge's glass side. Do **not** add a
  railing anywhere else. The gaps between segments are where other walks,
  ramps, lifts, escalators, towers and doors join; they must stay open.
- **Garden beds**: `DECK.beds` (50), each a centreline `pts` (points 1 m
  apart) and a width `w`. Build each as a raised bed 0.45 m tall (a solid,
  sittable edge) following the centreline, with two soft planting lumps on
  top (decorative).
- **Deck trees**: `DECK.trees` (9): a `round` kit tree (`NatureProps.build_round_tree`)
  of height `h` (6) at `c`, standing at y = `y` (6.95, the bed's top).
- Ramp towers, lifts and the four Deck escalators: as in the first pass,
  but check that the Deck's parapet is open at each head (it is, in the data).

### 4.4 The park's planting (`PARK`, `TREE_KIT`)

Place every item at its exact recorded point. Do not scatter, jitter or add.

- `PARK.trees` (23): `kind` and trunk point `c` and height `h`. Use the
  kit builders in `scripts/nature_props.gd`:
  `round` -> `build_round_tree(h, leaf colour)` (a ghaf: grey-green leaves);
  `flowering` -> `build_flowering_tree(h, leaf, blossom red-orange, rng)` (a flame tree);
  `palm` -> `build_palm_tree(h, 0.0, rng)` (a date palm, no lean);
  `banyan` -> `build_banyan_tree(h, rng)`.
  The kit already gives trunk collision and a walkable canopy top; keep it.
  Seed each `rng` from the tree's index so it is stable between bakes.
- `PARK.shrubs` (62): a low bush (`build_bush`, scaled to about 2.6 m
  across and 1.5 m tall) at each point. Decorative.
- `PARK.reeds` (28): a clump of `stems` reeds about `h` tall at `c`.
  Decorative.
- `PARK.rocks` (21): a rock at `c` with half-sizes `half` (x, y, z).
  Boulders (half y >= 1) are solid; smaller stones decorative.
- `PARK.agave` (6): an agave rosette (five leaves) at each point. Decorative.
- The four steel **wind trees are gone**. Do not build them.
- **Performance**: there are about 32 trees and about 120 small plants.
  Share meshes and materials between trees of the same kind (build one of
  each kind and height, then instance or duplicate it), and use one
  `MultiMesh` per small-plant type per pack cell. Trees go in the pack of
  the cell they stand in, like buildings.

### 4.5 Platforms (`PLATFORMS`, `CROSS`)

- Every platform: floor at rail + 1.0; its edge 1.4 m from the track's
  centre; 3 m wide; 30 m long (`CROSS.platform`); one beside each track.
  For a line with tracks 1.5 m either side of its centre, the platform's
  centre is 4.4 m from the line's centre. Canopy 3.2 m above the floor
  (except at the Crossing, section 4.2).
- Wall Line: platforms on both sides at every gate.
- **Spine station escalators** (new, `CROSS.stations[...]._access`, one
  per platform at North Gate, Estate Square, Market Square and South Gate):
  each is an escalator pair 2.8 m wide (two narrow escalators side by side,
  up and down), straight, in line with its platform **beyond the platform's
  end toward the city's centre**, landing on the platform's end. Build each
  flight from `flights[k].foot` `[x, z, y]` to `flights[k].head` `[x, z, y]`.
  - Over the Deck (Estate Square, Market Square): one flight from the
    Deck (+6.5) to the platform (+14.2); its foot lands on `apron` (a small
    Deck extension joining the Deck walk; build it as Deck).
  - At the gates: two flights from the street (0) to +7.1 and on to +14.2,
    with a 2 m landing between; a 2.5 m clear `runout` on the street at the
    foot.
  - The old scissor stacks under the platforms (`_stacks`) are **deleted**:
    they surfaced through the 3 m platform and cut it in two.
  - Leave the Spine's planter trough out alongside each escalator lane.

### 4.6 The Spine's frames

- Build a portal frame at **each point in `CROSS.services[Spine].frames`**:
  two square legs (0.9 m) at 3.2 m either side of the line's centre, from
  the ground to the underside of the track (13.2 - 1.2), and a crossbeam
  under the track. Nowhere else.
- Where the Spine rides the Deck, the Deck's columns within 4.5 m of the
  line (in `DECK.columns`) rise on through the Deck to the track's underside
  as its legs.
- Inside the Crossing the Spine rests on the head beams (section 4.2).

### 4.7 The Meridian (high line)

- Piers at x in `CROSS.services[Meridian].piers` (8), on z = 0: a stem 2.4 m
  across to +28, then a Y of two arms to the twin box girders under each
  track. The two piers nearest the Crossing are gone; at the Crossing the
  line rests on the Meridian head beams (section 4.2).
- Bougainvillea troughs on both edges and coral vine sleeves on the stems
  (`GREEN`): build as plain green solids hung on the edge, decorative vine.

### 4.8 The Timekeeper (`TIMEKEEPER`)

- Rings, from the centre out: **hour** (6 to 9 m), **minute** (9 to 12 m),
  bezel (12 to 13.5 m). (The hour and minute rings swapped places.) The
  existing `moy_timekeeper.gd` finds rings by name, so it keeps working.
- Each moving ring carries one **arrow**: a flat triangle across the ring's
  band, its base on the inner edge (width `markers[name].arc` degrees: 20
  for the hour, 10 for the minute) and its point on the outer edge,
  standing `proud` (0.4) out of both faces. Bright red, emissive.
- The bezel: 12 dark hour marks across its band (quarters 1.2 wide, others
  0.5) and 48 minute ticks (0.16 wide, 0.55 long) on its inner edge.
- A lit **seconds bead** (radius 0.6) runs round the rim at radius 14.1
  once a minute (add it to `moy_timekeeper.gd`).
- Keep the rings hollow. Keep real time.

### 4.9 The gates (rebuild from data)

- East Gate: the Meridian Arch, legs `ARCH.legs` (x -363.5 to -341.5), the
  Wall Line's train hall through each leg (`ARCH.train_hall.arcs`, y 12 to
  21), lower bridge (`ARCH.lower`), top bridge (`ARCH.top`), cascades
  `ARCH.cores` (their `flights`).
- West Gate: towers `WEST_GATE.towers` ((-782, -26, -757, -10) and
  (-782, 10, -757, 26)), bridge `WEST_GATE.bridge`, train hall arcs, cores.
- Build every core's flights in **two lanes side by side** (as the first
  pass already does, alternating lanes), never stacked in one lane.
- **Known gap (record it, do not invent geometry):** the data does not yet
  give the passages from each core's landings through the leg or tower wall
  to the Wall Line's platforms (+14.2) and to the bridges (+37, +43).
  Build each passage as a straight 3 m wide, 3 m high opening from the
  landing to the nearest point of its destination, inside the leg or tower,
  and list every passage you made (from, to, level, length) in your
  diagnostic so the plan can adopt it.

### 4.10 The trains (`TRAIN`, `TIMETABLE`)

- The car: 9.6 m long, 3.6 m tall, floor at +1.0 above the rail, two doors
  a side (1.4 x 2.1 m) at ±2.4 m; consists from `TRAIN.consists`.
- Run every line to `TIMETABLE`: a train every 60 s on every line, three
  trains per line (`lines[...].trains`), stops of 8 s and 12 s at
  interchanges, turn-backs at the Spine and Meridian termini, the Watch
  train on the Wall Line at night. Place a train exactly as the model's
  `updateTrains` does (copy its maths).
- Riders walk level from a platform into a car through a door.

### 4.11 The launch site (`LAUNCH_SITE`, optional, last)

Only if time allows, and only as static massing with collision: the mount,
the upright ship (the Demo World ship's parts under a parent rotated -90
degrees about X, origin at y 52), the tower, hangar, rails, firing room,
landing pads, fence and track. No boarding, no launch.

## 5. Keep doing (performance and fidelity)

Everything in `moy_playable_prototype.md` section 5 still applies. In short:

- Bake offline; no runtime construction, CSG or merging.
- Packs per cell; activate a few per frame; keep the cheap silhouette.
- `StaticMerge.merge()` visuals per building or small block; **keep a
  separate collision body per building, per tower and per tree** (vine
  anchors need distinct bodies).
- Share meshes and materials; `MultiMesh` for repeated small things
  (shrubs, reeds, agave, bed lumps, parapet posts, climber panels).
- No transparent walls except the lift glass.
- Same simple materials and colours as the first pass.

## 6. Acceptance: test each, with the real player and Xiao Hou Zi

Update `tools/validate_moy_runtime.gd` and `tools/check_moy_bake.py`, then
prove each item below. Record pass or fail and numbers in a diagnostic,
`docs/diagnostics/<date>-moy-prototype-pass-2.md`. Do not mark untested
items as passed.

1. **Counts**: 4 towers; 164 Deck columns; 131 parapet segments; 50 beds;
   9 Deck trees; 23 park trees; 62 shrubs; 28 reed clumps; 21 rocks;
   6 agave; 104 climber panels; 8 Meridian piers; one Spine frame per
   `frames` entry; 8 station escalator sets (`_access`); no tunnel, flyover
   or wind tree.
2. **Positions**: every tree, bed, shrub, rock, column and frame within
   0.05 m of its recorded point.
3. **Every escalator and ramp has a way on and a way off at both ends**:
   for each Crossing tower hand, each station escalator, each Deck
   escalator, each ramp tower and each core flight, walk a capsule on at
   the foot, ride to the head, and step off onto the landing and onward
   (gallery, platform, Deck, street) without hitting a railing, a floor
   above, or a wall. Both hands of each tower, up and down.
4. **Changing lines**: from each Spine platform to each high-line platform
   through its tower, by escalator and by lift.
5. **Headroom**: no ceiling or underside lower than 2.3 m above any walking
   surface on these routes (helix hands pass 3.0 m apart; the cross-bridges
   have 3.9 m under the head beams).
6. **No railing across a junction**: walk every Deck junction, every tower
   connection and every ramp, lift and escalator head.
7. **Trains** keep the timetable for a game day at 1x and 10x; riders
   board level through a door.
8. **Clock**: arrows point at the right hour and minute; the bead moves.
9. **Performance**: the rendered probe from the first contract (it did
   not complete last time). Same targets. Report misses; never remove
   collision or buildings to meet them.

Also run `tools/check_power_parity.py`, `tools/check_body_pose_owner.py`
and `tools/check_design_language.py`.

## 7. Data keys that changed (for the validators)

- `CROSSING`: removed `halo`, `columns`, `spirals`; added `towers` (with
  `hands`, `lift`, `opens`, `levels`), `tower`, `roof`, `ring_depth`,
  `ring_max_span`, `_beams`, `_ring_supports`, `climbers`, `rain_gardens`;
  `ring` is now (24.7, 32.7); `cores` stays empty.
- `ESCALATORS`: `helix` (angle 30, eye 1.4, landing 50); new `station`.
- `DECK`: new runs; new `garden`, `parapets`, `beds`, `trees`;
  `spiral_ways` now the four towers.
- `CROSS`: Spine `frames`; Meridian `piers` (8) and `bearers`; stations
  `_access` replaces `_stacks`.
- `PARK`: `trees`, `shrubs`, `reeds`, `rocks`, `agave` replace
  `wind_trees` and `wind_tree_height`. New `TREE_KIT`.
- `TIMEKEEPER`: rings reordered; `markers`, `marks.minute`, `seconds`.
- New `LAUNCH_SITE`.

## 8. Do not

- Do not hand-edit `scripts/city_plan.gd`, or copy plan numbers into the
  builder. Read them from `CityPlan`.
- Do not add railings, columns, trees or plants that are not in the data.
- Do not shrink, move or simplify anything people walk on to make a test
  pass; report it.
- Do not change the player's or the vine's movement ranges.
- No in-game text explaining anything.
- No web build. Do not commit or push unless asked; if asked, follow
  `AGENTS.md` and `CLAUDE.md` (the owner's identity, no AI credit).

## 9. Open items you may meet (report, do not solve)

- The passages through the gate legs and towers (section 4.9).
- The plan page's section drawing of the Spine stations still shows no
  escalators (it drew the old stacks); use the 3D model.
- Accessibility at the Spine stations: no lift reaches their platforms
  yet; the escalators are the only way up.
- The playground's swing anchors and cloud run moved with the wind trees
  (`city.md` 7b, proposed); test them and report.
