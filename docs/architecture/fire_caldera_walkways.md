# Fire Caldera: the walkway system

Status: **proposed for review, 2026-10-17.** This replaces the piecemeal route
geometry in `FireCalderaPlan.routes()` and `fire_caldera_highline.gd` with one
system. Every public walk above the lava is designed here as a whole: the
Highline, its porches, the stairs and ramps, the lava promenade, the
forecourts, the service lanes, the Gate Terrace and the funicular. The
Heartworks' walks use the same system (`fire_caldera_heartworks.md`).

Sources:
- **Plan:** `tools/fire_caldera_walkways_layout.py`, which writes
  `scripts/fire_caldera_walkways_plan.gd` (`FireCalderaWalkwaysPlan`).
- **Geometry rules and checks:** `tools/walkway_kit.py`.
- **Model:** `docs/drawings/fire_caldera_3d.html`.

## 1. What was wrong

The built walks were assembled piece by piece, each with its own offsets, so
their joints never agreed:

- **Child walks sat on their parents.** A branch was laid as its own slab
  beside or on top of its parent. The floors met at a seam or overlapped, and
  the guards were cut and re-placed by hand at each joint.
- **Guards were drawn per piece.** Rails stopped, restarted and crossed at
  junctions, and stood across a building's porch.
- **Renewal's ramps** were 66 m switchbacks with 7 m returns, and their feet
  met the deck with a kink.
- **Oren's link** was a long spiral ramp, where what was asked for was a small
  stair.
- **The gate and the gallery's head floated** above the rim's coarse ground.
- **The rear service orbit (G2)** ran through the docked buildings' service
  piers.
- **Heights did not match.** The promenade (30.25), the Renewal deck (30.48)
  and the ground doors (29.90 to 30.00) were all slightly different, so every
  joint between them was a small step.

## 2. The system

### 2.1 Levels

The city's walks stand on **four tiers**, each **one surface at one height**:

| Tier | Height | Material | What stands on it |
|---|---:|---|---|
| Gate Terrace | 48.5 | cast basalt | the Tempering Gate, the inn's porch and its bridge, the funicular's top station |
| Highline | 42.5 | glass on steel | the ring, the porches of Nahl, Vara, Civic and Iren, Iren's glazed bridge to Civic, the refuge bridges and shelves, the heads of the Renewal and Oren stairs |
| Promenade | 30.0 | cast basalt (the Renewal deck is glass) | the lava promenade, the forecourts of Oren, Kel and Aro, the Renewal deck |
| Private levels | Oren's roof terrace 38.0; Oren's yard 31.35; Kel's yard 31.15 | | reached only by their own flights |

**A tier is one surface.** It is the union of everything at its height: the
ring, each porch, each forecourt, each landing. A child walk is not laid
beside its parent; it becomes part of the parent's surface, so the floor runs
through every junction without a seam.

**Buildings are cut out of the surface.** A building's walls are subtracted
from the tier it stands on. A docked building's porch and the Highline are one
floor, and the porch's guard is the Highline's guard.

**Corners.** Every concave corner of a tier's outline is rounded at 1 m, so a
porch flows into the ring with a curve, not a notch. Convex corners stay
square.

**One datum for the ground.** The ground tier is 30.0, the bank's shoulder
(`FireCalderaPlan.FLOOR_Y`). Oren, Kel and Aro's front floors, the promenade
and the Renewal deck all meet it exactly.

### 2.2 Flights

A **flight** is a ramp or a stair between two tiers. Every flight has three
parts:

1. **A level landing at its head**, which is part of the upper tier's surface.
   It juts at least 1.3 m beyond any concave corner, so no rounded corner ever
   roofs the slope.
2. **The slope:** a ramp of at most 18%, or a stair of at most 35°
   (rise 0.17 m).
3. **A level landing at its foot**, part of the lower tier. This is either a
   mouth cut in the lower tier's edge or a landing in the middle of its
   surface.

**The mouth** is where the landing ends and the slope begins: a straight line,
square to the flight and exactly as wide as it. The tier's guard follows the
landing's sides and stops at the mouth's two corners. The flight's own guards
start at those same two corners. Parent and child share one floor plane at the
mouth and one continuous guard line, with no fitting by hand.

### 2.3 The guard

There is one guard everywhere, on the surface and in the Heartworks:

- **Posts:** blackened steel flat bar, 60 × 15 mm, at no more than 1.6 m,
  divided evenly along each run, with one at each end and at each corner.
- **Infill:** clear refractory glass panels from 0.06 m to 1.0 m.
- **Handrail:** one stainless round rail, 50 mm across, at 1.09 m. It runs
  continuously round corners, along each run and down each flight, parallel
  to the slope.
- **Ends:** at each mouth, the rail curves down into the flight's rail over
  0.6 m.

**Where the guard runs.** A level's guard runs along its surface's outline,
except along a building's wall, along an edge deliberately left open, and
across a mouth. It stands only where the drop beside the edge is **a metre or
more**. Elsewhere the edge is a 0.22 m kerb, the same height as the deck's
edge. The lava promenade and the Renewal deck are kerbed, not railed: lava
people step into the lava there. A spiral stair's inner side is its newel.

**Build the guards from the plan.** `FireCalderaWalkwaysPlan.LEVELS[...]
["guards"]` gives each guard line exactly, and `FLIGHTS[...]["guards"]` gives
each flight's. A builder draws guards along these lines and never derives its
own offsets.

### 2.4 Materials: one family

| Element | Material |
|---|---|
| Raised civic decks: the Highline, porches, gallery, bridges, stairs, Renewal deck | laminated refractory glass in 0.22 m cassettes, in a blackened-steel frame; a slim steel edge channel the same 0.22 m deep |
| Ground-borne surfaces: Gate Terrace, promenade, forecourts, yards, lanes, refuge shelves | cast basalt pavers on socketed plinths; a 0.22 m basalt kerb where unguarded |
| Supports | blackened-steel columns with a paired fork (the Highline's frames), the concave service piers of the docked platforms, steel stringers under every stair |
| Stairs | glass treads with a fritted, slip-resistant band at each nosing, on twin steel stringers. The horseshoe flights' undersides are closed where they are lower than 2.1 m |
| Guard | as 2.3, everywhere |

The rule of thumb is short: what steel carries is glass; what the ground
carries is basalt; one guard on both.

## 3. The network

### 3.1 The Gate Terrace and the arrival gallery

- **The Gate Terrace** is a superelliptic basalt terrace on the crater lip,
  28 × 10 m, at 48.5. It sits on its own plinth, socketed down to 45.3 into the
  rim (1.5 m below the lowest ground under it), so nothing hovers.
- **The Tempering Gate** stands on it across the gate-to-Civic axis. Its
  pylons are 6.8 m apart and 10 m high, with mineral glass in the lintel.
- **The inn's porch** drops 1 m to 48.5 (it was 49.5). A 3 m level bridge
  joins it to the terrace, so the gate and the inn share one level.
- **The funicular's top station** meets the terrace's outer edge.
- **The arrival gallery (H0)**, 3.8 m wide, leaves the terrace's inner edge
  square, on the axis. It runs straight down to the Highline's outer edge, 34 m
  at 17.6%, with level landings at both ends. Nothing stands on the
  arrival-to-Civic sightline.

### 3.2 The Highline

- **The ring:** 4.8 m wide at 42.5. The porches of Nahl, Vara, Civic and Iren
  are part of its deck; each building's walls are cut out, and the guard runs
  round each porch and back to the ring.
- **Iren's bridge to Civic** is an enclosed glazed corridor at the same level:
  its sides are glazing, not guards.
- **Refuges:** three 3.5 m level bridges (E1 at −175°, E2 at 65°, E3 at 155°)
  run to basalt refuge shelves on the crater wall 103.5 m out, where the
  ground reaches 42.5.
- **Frames:** twelve paired-fork frames carry the ring. They now stand at
  21.5° + 30k, turned so each is clear of every walk, building and pier on the
  ground.

### 3.3 The Renewal horseshoe stair

The classic double grand staircase:

- **The shared head.** A landing 8 m wide juts from the Highline's inner edge
  directly behind the canopy.
- **The two flights.** From its two ends, two flights 2.2 m wide sweep
  outward. Each turns a quarter circle of 6 m radius round the canopy's back
  corner, then runs straight toward the lava. They pass over the canopy with
  room to spare and land on the deck's two sides, facing the reservoir.
- **Why a stair.** The drop is 12.5 m, so the flights are stairs at 34°, each
  18.4 m long. A ramp of the same shape would be 68% steep. A ramp at a
  walkable grade needs about 70 m per arm: the switchbacks this replaces.

The Renewal deck:
- **Its level:** 30.0, level with the promenade. The promenade passes across
  it as part of one surface.
- **Its size:** it grows slightly, to 23.2 × 18.4 m, so the flights' feet land
  on it.
- **The immersion tongue:** 8 m wide, it leaves the deck's lava edge and
  slopes 2.4 m down into the lava.
- **Its edges:** kerbed, not railed.

### 3.4 Oren's spiral stair

A small spiral stair:

- **The head:** a 4.3 m level landing from the Highline's inner edge.
- **The turn:** about 300° round a steel newel, at a walkline radius of 1.55 m,
  4.5 m down to Oren's roof terrace.
- **The foot:** it lands inside the terrace's own guard, which is part of the
  same system.
- **Clearances:** it stands on the terrace away from the lift's landing, and
  clear under the ring's deck.

### 3.5 The lava promenade and the frontages

- **The promenade** is 4 m wide and level at 30.0 the whole way round the
  bank. Its lava-side kerb stands 0.6 m beyond the bank.
- **In front of a ground building** it eases inward so that at least 1.5 m
  remains in front of the facade. Where a building stands well back, a
  **forecourt** fills the space between its front and the promenade, square to
  the facade and 1.5 m wider than it on each side, with the door's threshold
  flush.
- **Kel's front stands close to the lava,** so its stretch of promenade is a
  quay cantilevered over the bank's edge.
- **Joins** are rounded, so the promenade and forecourts read as one paved
  surface.

### 3.6 Service yards and lanes (the back doors)

- **Behind Oren and Kel** is a basalt yard level with the receiving door: 31.35
  for Oren's workshop, 31.15 for Kel's dock.
- **From each yard**, a 2.4 m service lane runs down the building's flank to
  its forecourt: Oren's at 13%, Kel's at 9%.
- **Sides:** Oren's lane is on the side toward Kel; Kel's is on the side away
  from Oren.
- **Where goods go:** from a lane straight to the promenade, never across a
  shop front or through a porch.
- **Edges:** the lanes are ground-borne, so their edges are kerbs.
- **The retired orbit:** the rear service orbit (G2) is retired. It served
  only these two doors and ran through the docked buildings' piers.

## 4. The funicular

The funicular brings people from the volcano's foot up to the Gate Terrace.

- **The line.** From a lower station at the kingdom's level (local 92, −181),
  where the flank meets the plain, a straight line runs 113 m at 48% (25°) up
  to the Gate Terrace's outer edge (9, −122).
- **The track bed.** The line runs on a basalt bed:
  - a low viaduct on paired piers where the flank dips below it (up to 4 m);
  - a short cutting with retaining walls where the flank stands above it (up
    to 1.2 m).
- **Tracks and cars.** Two parallel 1 m-gauge tracks, 3.4 m apart, carry two
  counterbalanced cars, one going up as the other comes down.
- **The cars.** After Lisbon's Glória and Budapest's Sikló, each car is
  stepped: three cabins in a row on an inclined chassis.
  - Each cabin has a level floor.
  - Each cabin is a SuperEgg body: a superellipsoid 3.1 × 2.7 × 2.5 m,
    epsilon 0.28, in amber enamel, with a band of smoked glass.
  - Each cabin sits 1.5 m above the next.
- **Stations.** At each end, a stepped basalt platform runs beside the tracks
  under a glass roof.
- **Terrain.** The live kingdom's terrain is coarse. The track's corridor must
  be socketed like a foundation: the ground below the bed cut where it is
  higher, and the piers founded where it is lower.

## 5. What changes in the built city

- **The ground datum.** `FireCalderaPlan.GROUND_PROMENADE_DATUM` goes from
  30.25 to 30.0. The Renewal plot's datum goes to 30.0. Oren, Kel and Aro's
  floors go to exactly 30.0, from the 29.90–30.00 their surveys give.
- **The inn.** `GUEST_GATE_DATUM` goes from 49.5 to 48.5.
- **The Renewal deck** grows to half sizes of 11.6 × 9.2 m (it was 10.8 × 8.8).
- **Replaced routes.** H2W and H2E become the horseshoe stair (RSE, RSW). H4
  becomes the spiral stair (OS). HG becomes the inn bridge, on the Gate
  Terrace level.
- **Retired routes.** G2 and the S_ spurs are retired; the yards and lanes LO
  and LK replace them.
- **Frames.** The Highline's frames turn by 6.5°.
- **The builder.** `fire_caldera_highline.gd` stops deriving deck edges,
  guards and junctions itself. It reads `FireCalderaWalkwaysPlan.LEVELS` and
  `FLIGHTS` instead:
  - each level is a slab of its outline, with collision from the same
    outline;
  - each flight is a deck or stepped stair along its profile;
  - each guard is built along its line.
- **New:** the Gate Terrace's plinth and the funicular.

## 6. Checks

`tools/fire_caldera_walkways_layout.py` fails when:

- **a guard ends in mid-air:** one of its ends meets neither another guard,
  a wall, an open edge, nor the floor a flight lands on;
- **a landing is not flush:** a flight's landing is not part of its level's
  surface;
- **a rounded corner roofs a slope:** a level's surface covers the head of a
  flight;
- **a slope is too steep:** a ramp over 18% or a stair over 35°;
- **the Renewal stair hits the canopy:** a flight comes within 0.4 m of it;
- **a Highline frame crowds something:** it stands within 0.6 m of a walk, a
  building or a pier;
- **the funicular misses:** it does not reach the Gate Terrace.

It reports every flight's length and grade, and every level's guard runs.

## 7. Open

1. Should the refuge shelves (E1–E3) lead on up the crater wall to the rim, or
   stay as shelves?
2. Is the inn's 1 m drop to the Gate Terrace's level acceptable, or should the
   terrace rise to 49.5 instead?
3. Where exactly is the funicular's foot? It is placed where the flank meets
   the plain south-east of the gate. A probe of the live terrain should
   confirm the lava rivers stay clear of it.
