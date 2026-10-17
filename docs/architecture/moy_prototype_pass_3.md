# Moy: third prototype pass, build instructions

2026-10-17. Instructions for the next implementation chat, after the second
pass (`docs/diagnostics/2026-10-17-moy-prototype-pass-2.md`). Keep following
`moy_prototype_pass_2.md` (sections 0, 4 to 8) and `moy_playable_prototype.md`
(sections 4 to 8). **This document lists only what changes.** Do the steps
in order. If this document and the data disagree, the data wins: report it.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`.
2. This document.
3. `moy_prototype_pass_2.md` (you built from it last time).
4. `docs/drawings/moy_city_3d.html`: its construction code draws everything
   below from the same data. New places to visit: *The city's clock*,
   *Civic Plaza and City Hall*, *City Hall, the Meridian Arch*, *On Meridian
   Walk*, *A garden tower's landings*.
5. `city.md` 7 (plazas), 7a (the city's clock), 8a (superseded note), 8b
   (City Hall).

## 2. Review of the second pass

Good, keep it: the plan-driven builder; placement within 0.05 m for 911
records; the timetable (12 trains, 30 cars, correct stops and dwell); the
MultiMesh planting; separate bodies per building, tower and tree; the
clock arrows; the honest diagnostic.

Wrong, fix it (each with its cause):

1. **The garden towers' insides are a jumble.**
   - Cause A: `_annulus_body` and `_annulus_visual` use Godot's `TorusMesh`.
     A TorusMesh is a **donut tube** whose thickness is `outer - inner`
     (here 1.8 m), not a flat ring; rotating it by `rotation.x = PI/2`
     stands it **upright**. So every gallery and hoop is a vertical
     1.8 m-thick donut through the escalators.
     Fix: build a flat annulus yourself: an `ArrayMesh` of quads between
     two circles (inner and outer radius, 48 segments) for the top and
     bottom faces and the two edges, lying flat (in x and z). Collision: a
     `ConcavePolygonShape3D` from the same triangles, or 24 to 36 short box
     segments round the ring. Use it for the galleries (radius 4.0 to 5.8,
     0.35 thick, top at each level) and the hoops (radius 5.9 to 6.1, 0.16
     thick, flat, every 4.1 m).
   - Cause B: each escalator hand is a chain of flat 2.6 m-wide boxes about
     1 m long. On a 2.7 m radius, neighbouring boxes overlap on the inside
     and gape on the outside, and each box is tilted to the whole
     segment's slope, so the band is saw-toothed.
     Fix: build each hand as **one continuous strip mesh** following its
     `profile`, exactly as `helixPath` does in the model: for every 5
     degrees of bearing, two vertices (radius 1.4 and 4.0) at that height;
     triangles between consecutive pairs. Collision: a
     `ConcavePolygonShape3D` from the same triangles, one per flight (one
     per profile segment that climbs) and one per landing. Moving surface:
     keep `moy_escalator.gd` but set the travel direction **per contact**
     to the tangent of the helix at the contact point (bearing from the
     tower's centre, rising at the hand's slope), not one direction per
     box. Landings do not move.
   - Check: walk on at the foot, ride, step off onto each landing, then
     onto the gallery; both hands; all four towers (pass 2, section 6.3).
2. **The East Gate's lower bridge is solid.** `MeridianArchLowerBridge` is
   a 24 x 10 x 6 m solid box across the line. `ARCH.lower` (32 to 42) is the
   **station level that the high line runs inside**: build a floor slab at
   +32 (0.8 thick) under the whole bridge (between the legs: x -363.5 to
   -341.5, z -12 to +12), a roof slab at +42 (0.6 thick), glass sides, the
   two high-line platforms inside at +37, and **open ends** where the
   tracks enter. The same for the West Gate's bridge (`WEST_GATE.bridge`).
3. **Train clearance test samples where no train goes.** At North Gate the
   test put a car beyond the Spine's last stop, into the Wall Line's
   platform. Sample car envelopes only at positions trains actually occupy
   in the timetable (the model's `updateTrains`): a Spine train never goes
   further out than its terminus stop (North Gate z -184, South Gate +184)
   plus half its length. If a real overlap remains after that, report it.
   Build the Wall Line's platforms following the wall's curve (a segment
   every 2 degrees or less), so straight segments do not cut inside the
   curve.
4. **Untested**: walking every escalator, ramp and lift end; changing lines;
   boarding a train through a door; the rendered performance probe. These
   are the main job of this pass's tests (section 5).
5. **The passages through the gate legs and towers** (pass 2, 4.9) were not
   built. Build them as that section says, and list each one.

## 3. Plan changes since the second pass (2026-10-17, the owner's direction)

Regenerate first: `python3 tools/city_layout.py --json /tmp/moy-plan.json`
(it must print only `wrote scripts/city_plan.gd: 24 streets, 50 buildings,
133 lots, 9 courts`).

### 3.1 The Timekeeper and the old city hall are removed

- Delete `_add_timekeeper` and its arrows. `TIMEKEEPER` no longer exists.
- Building 2 (the old city hall) no longer exists. Remove anything built for
  it (its massing, canopies, Deck doors).
- `scripts/moy_timekeeper.gd` drives the new clocks instead (3.2).

### 3.2 The city's clock: a glass dome on the Crossing (`CROSSING.dome`)

Build on top of the Crossing's roof (`CROSSING.roof`, top at `dome.base`
= 41.6):

- **Drum**: a superellipse in plan, centre (-560, 0), half-width
  `drum.half` (19), exponent `drum.n` (4, the roof's shape), from `base` to
  `base + drum.h` (17). Glass walls (thin, transparent), 24 steel ribs
  (`ribs`) round it, a steel ring at its top. Solid glass walls (collision),
  so nobody walks off the roof's edge into the drum; the roof inside the
  drum is the floor.
- **Cupola**: a glass superellipsoid on the drum: same plan shape, height
  `cupola.h` (11), top at `dome.top` (69.6). Solid (a landing on top).
- **Four clocks**, one flush in each side of the drum at the bearings in
  `clocks.bearings` (0 east, 90 south, 180 west, 270 north), centre
  `clocks.centre` (8.5) above `base`, facing outward. Each is a ring clock,
  built in the plane of that side:
  - rings from `clocks.rings`: `hour` 3 to 5 m, `minute` 5 to 7 m, `bezel`
    7 to 8 m. **The centre (radius < 3) is open (hollow).** Flat rings, not
    TorusMesh.
  - each moving ring carries one lit arrow (base on its inner edge,
    `markers[name].arc` degrees wide; point on its outer edge), standing
    `proud` (0.3) out of the face.
  - bezel: 12 hour marks across it (quarters `marks.quarter` wide, others
    `marks.hour`) and 48 minute ticks (`marks.minute`) on its inner edge.
  - a lit seconds bead (`seconds.bead`) running round at `seconds.r`.
  - **Time: the game's clock** (`clocks.time` = game), not real time, so
    the dial and the bell agree. Clockwise as seen from outside each face.
- **The bell**: a bronze bell `bell.mouth` (4.4) across and `bell.height`
  (4.6) tall, its bottom at `bell.bottom` (64.0), hung on a chain from the
  cupola's crown, centred over (-560, 0). Solid.
- **The bell rings** (`bell.rings`), on the game's clock: 5:00 (dawn),
  12:00 (noon) and 19:30 (evening), with the stroke patterns given there.
  Add a small scheduler (in `moy_timekeeper.gd`) that strikes the bell
  (sound and a small swing) at those times. **Never on the hour.** Use an
  existing bell or chime sound if the project has one; otherwise leave a
  clearly named placeholder and report it.

### 3.3 City Hall is the Meridian Arch (`ARCH.program`)

- No new geometry is required for the program. Give the arch's ground
  floor a **public hall** at the foot of each leg, opening on Civic Plaza
  beside the station hall (a simple open room, 6 m high, with doors on the
  plaza). The council chamber in the top bridge is not built inside.

### 3.4 Civic Plaza, Meridian Walk and the commercial blocks

- `OPENS`: **Civic Plaza** is now x -431 to -359, z -30 to +30 (the old
  city hall's site, Clock Street and Meridian Court). Meridian Court and
  Clock Street are gone. Build it as open paved ground.
- `STREETS`: new **Meridian Walk** (x -483 to -431, z -6 to +6) under the
  high line, and **Hotel Passage** (x -464 to -452, z -30 to -6). Meridian
  Avenue now starts at x -359.
- `BUILDINGS` 54, 55, 56: three commercial blocks (12 storeys, 45 m):
  54 (-483, -30, -464, -6), 55 (-452, -30, -431, -6), 56 (-483, 6, -431,
  30). Same fidelity as the other downtown buildings.
- `DECK`: the two old civic walks, the Civic ramp towers and the two Civic
  Plaza escalators are gone. New runs: **Civic walk** (4 m wide, z -4, x
  -489 to -431, along Meridian Walk's north side), **Hotel walk** (6 m,
  x -461, z -4 to -30, over Hotel Passage) and **Hotel skybridge** (x -461,
  z -30 to -38, into the hotel). New escalator pair **Civic Plaza** (foot
  (-419.7, -4) in the plaza, head (-431, -4) at the civic walk's end).
  `DECK.columns` (158), `parapets` (127), `beds` (41) and `trees` (9) have
  been regenerated: rebuild them from the data.
- The high line's pier at x -392 now stands in Civic Plaza: unchanged.

## 4. Counts after this change

50 buildings (48 + 3 new - 1 removed), 24 streets, 133 lots, 60 old houses;
4 towers; 158 Deck columns; 127 parapet segments; 41 beds; 9 Deck trees;
23 park trees; 62 shrubs; 28 reed clumps; 21 rocks; 6 agave; 104 climber
panels; 8 Meridian piers; 8 station escalator sets; 3 Deck escalator pairs;
2 Deck ramp towers; 4 clocks; 1 bell; 0 Timekeeper.

Update `tools/check_moy_bake.py` and `tools/validate_moy_runtime.gd` to
these counts (e.g. 50 numbered building records).

## 5. Acceptance (in addition to pass 2, section 6)

1. Every count in section 4.
2. **The towers**: with the real player and with Xiao Hou Zi, in each of the
   four towers, ride both hands from 0 to 37 and back down, stepping off at
   each landing onto the gallery and back on. No vertical rings, no gaps,
   no saw-teeth: record a screenshot of one tower's inside.
3. **Changing lines** at the Crossing by escalator and by lift, each
   direction.
4. **The East Gate**: a Meridian train runs into the lower bridge and stops
   at its platforms; walk from the platform out through a passage.
5. **Train clearance**: 0 overlaps with the sampling of section 2.3.
6. **The clock**: each face shows the game's time (check at 3:00, 9:15 and
   12:00 game time); the centres are open; the bell strikes at 5:00, 12:00
   and 19:30 and at no other time in a full game day.
7. **Civic Plaza and Meridian Walk**: walk from the park along Meridian Walk
   to the arch, and along the Deck's civic walk, down its escalator into
   the plaza; along the Hotel walk and skybridge into the hotel.
8. **Rendered performance probe** (not run in passes 1 or 2): run it and
   report the numbers. Do not claim it from headless runs.

Write `docs/diagnostics/<date>-moy-prototype-pass-3.md` with real passes and
failures. Do not mark untested items as passed.

## 6. Do not

Everything in pass 2, section 8, still applies. Also: do not use
`TorusMesh` for any flat ring; do not build any surface people walk on from
overlapping boxes where a strip mesh is called for.
