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
| Raised civic decks: the Highline, porches, gallery, bridges, ramps | one clear sheet of laminated refractory glass, 0.22 m deep, in a blackened-steel frame; a slim opaque steel edge channel |
| Ground-borne surfaces: Gate Terrace, promenade, forecourts, yards, lanes, refuge shelves, the funicular's stations | cast basalt pavers on socketed plinths; a 0.22 m basalt kerb where unguarded |
| Supports | blackened-steel columns with a paired fork (the Highline's frames), the funicular's SuperEgg piers, steel stringers under every stair |
| Guard | glass panels between posts; posts and handrail in Renewal's blued steel (revised 2026-10-18) |

**The glass reads as glass** (2026-10-18). From above it read as an opaque pale
blue: every deck was drawn as two translucent layers, both seen at once, with
its normals facing down.
- A glass deck is now one clear sheet: its top face faces up and its bottom
  face faces down, each culled from behind, so no view looks through two
  layers.
- It has alpha 0.2, roughness 0.05 and no metallic.
- The values are in `SITE.materials`.

**Winding.** Every face of every deck, guard pane, post and handrail faces out
(Godot's front faces are clockwise seen from outside). The first build had the
decks, guard panes, posts and the handrail tube inside out.

**The guards are blued steel.** Their posts and handrail are Renewal's blued
steel (`CalderaShell.STEEL_BLUED`, metallic 0.9, roughness 0.2), everywhere,
after the user's walkthrough.

The rule of thumb is short: what steel carries is glass; what the ground
carries is basalt; one guard on both.

### 2.5 Joins and the ground (2026-10-18)

**One surface at one height.** A flight's landings are part of its levels'
surfaces, and are built only with them.
- A flight's deck is its slope alone, mouth to mouth: `FLIGHTS[...].deck`. The
  full centreline `profile` is kept only for reference.
- In the first build, every landing was built twice, by the level and by the
  flight, at the same height. The surfaces fought on screen at the gate
  ramp's head, the ring and the Renewal ramps' tops.
- The same rule applies to any piece at a level's height:
  - the Renewal deck's glass finish is gone;
  - the immersion tongue starts at the deck's lava edge, not on the deck;
  - the house's own floors are never covered by a walkway (below).

**A building's own floors are the building's.**
- Oren's roof terrace is the house's own, with its paving, parapet and lift
  stop. The walkway level `oren-roof` is marked `owner` and `build: false`. It
  exists so the spiral can land on it.
- The first build laid a glass deck and a second guard over the house's
  terrace, which sealed its lift.
- Oren's yard stops at the house's own ramp-foot landings instead of lying
  over them.

**Walks on the ground are cut into it.**
- The promenade's datum, 30.0, is the bowl's lowest point. The bowl rises
  outward, up to 1.4 m above the walk, so in the first build the promenade
  lay buried.
- Every walk that sits on the ground (the promenade, the yards, the foot of
  the funicular's ramp) now cuts the ground under it to its underside
  (`SITE.beds[...].cut_to`).
- A low basalt retaining edge holds back the ground beyond its edge wherever
  that ground stands higher (`retaining` runs, with the ground's height).
- Each refuge pad meets the rising bowl at its outer end and is cut in the
  same way.
- A flight is cut into the ground where it runs within 0.6 m of it
  (`SITE.flight_cuts`).
- Raised walks are checked to clear the ground.

## 3. The network

### 3.1 The Gate Terrace and the arrival gallery (revised 2026-10-18)

- **The Gate Terrace** is a superelliptic basalt terrace on the crater lip,
  28 × 10 m, at 48.5. It sits on its own plinth, socketed into the lowest live
  ground under it and under its station wing (down to 41.7), so nothing hovers.
- **The guards.** The terrace is guarded all round, however small the drop.
  Its two ends used to stand open onto nothing: the kit left a kerb wherever
  the drop was under 1 m. Its only openings are designed ones:
  - the arrival gallery's mouth;
  - the inn's bridge;
  - the funicular's platform gates;
  - the head of the track-side stair.
- **The Tempering Gate** keeps its new size: 6.8 m clear, 10 m high. It
  returns to the language of the first arrival threshold:
  - a squarish superellipse arch (exponent 6) of three ember-glazed refractory
    tubes, 0.42 m thick, one behind another at 0.48 m;
  - basalt SuperEgg feet;
  - a veil of four stained-glass SuperEgg fins hanging under the crown (teal,
    magenta, lime, cobalt), lit from within at night, their lowest tip 3.4 m
    or more above the terrace;
  - it is never boxes. Data: `SITE.tempering_gate`.
- **The inn's porch** is at 48.5, joined to the terrace by a 3 m level bridge.
- **The funicular's top station is part of the terrace** (section 4).
- **The arrival gallery (H0)**, 3.8 m wide, leaves the terrace's inner edge
  on the axis and runs straight down to the Highline's outer edge, 34 m at
  17.6%.

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

### 3.3 The Renewal grand ramps (revised 2026-10-18)

The user's double grand stair: two smooth ramps coming down either side of
Renewal and heading back up to the Highline.

- **Before.** The flights were 34° stairs, built as slopes. Near the bottom
  they straightened and aimed at the deck's front corners, an odd place to
  arrive.
- **The shared head.** A landing 8 m wide juts from the Highline's inner edge
  behind the canopy.
- **The ramps.** Two ramps 2.2 m wide each leave the landing outward, along
  the back of the canopy. Each then sweeps round a wide half-turn (radius 4.6
  m) toward the lava, outside the deck's side.
- **The landing.** Each straightens only for its last few metres, and enters
  the deck at the middle of its side, square to it.
- **The grade.** Each is 25.2 m long at 50% (27°). The grand ramps are the
  one exception to the 18% public-ramp limit, and the plan checks them at 55%.
- **Their guards** are blued steel, as every guard's now are.

The Renewal deck:
- **Its level:** 30.0, level with the promenade, and part of the same surface.
- **Its size:** 23.2 × 18.4 m.
- **The ground:** cut under it (section 2.5).
- **The immersion tongue:** 8 m wide, from the deck's lava edge 2.4 m down
  into the lava.
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

## 4. The funicular (revised 2026-10-18, at the user's direction)

In the first build:
- the track clipped into the flank;
- no car ran;
- the top station was a slab half-sunk in the terrace;
- the model's cars travelled sideways.

The flank was the cause. The plan assumed the smooth flank, but the live
ground there is the coarse mesh, with noise of up to ±6 m, and a straight
chord cuts through its shoulder. Data: `SITE.funicular`.

- **The graded corridor.** The terrain fades the flank's noise out within 25 m
  of the line, and back to full by 50 m (`corridor`; FireKingdomTerrain's
  height, as the gate's blend does). The ground under the track is then the
  smooth flank exactly, on the same coarse grid.
  - `tools/fire_kingdom_terrain_bounds.py` reproduces that ground in Python,
    so the plan sets the track over it to the centimetre.
  - Away from the corridor it bounds the live ground by the noise's ±6 m.
- **The line.** The line is unchanged in plan, from the terrace's south edge
  (7, −118) down the flank toward the south-east. It is 119 m long, ending at
  a lower station near the volcano's foot (about 95, −181).
- **The profile.** The flank is gentle at the lip, about 33° in the middle and
  flat at the foot. The track follows it at a constant clearance:
  - the bed's underside is 0.6 m or more over the ground;
  - it rides a basalt viaduct on SuperEgg piers socketed 1 m into the ground;
  - its vertical curves are eased (12 m or wider);
  - it is steepest at 65%.
  - Within the two stations the bed rests on their socketed plinths.
- **The cars.** After Lisbon's Glória:
  - two cars, counterbalanced on two tracks 3.4 m apart, one going up as the
    other comes down;
  - each is one SuperEgg cabin, 7 × 2.9 × 2.5 m, with a band of smoked glass:
    the ember car (red) and the ash car (white);
  - each cabin hangs level in a ring frame that tilts with the grade, as the
    Stoosbahn's do, so its floor stays flat all the way;
  - the cars ride along the track, never across it.
- **The top station is a wing of the Gate Terrace.** A superellipse along the
  track, unioned with the terrace, with a notch the two cars dock in.
  - Their floors are level with the terrace (48.5).
  - Riders board through a platform gate on each car's outer side.
  - A glass hood shelters the platforms.
- **The lower station is raised.** The track clears the ground right into it
  (the user's suggestion), so its plaza stands on a plinth at 3.84. A 14 m
  ramp at 16% runs down to a landing on the graded ground (1.59).
- **The track-side stair.** As Lisbon's Bica has stairs beside its track, a
  1.8 m stair is cantilevered off the viaduct on the south-west side, guarded
  both sides. It runs from the top station's platform down to the lower
  station: the way up for a walker.

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
- **the funicular misses:** it does not reach into the Gate Terrace;
- **the funicular touches the ground:** its bed comes within 0.6 m of the
  graded flank between its stations;
- **the funicular is too steep or kinked:** steeper than 68%, or a vertical
  curve tighter than 12 m;
- **the gate's veil hangs into the walk:** less than 3.4 m clear under it;
- **the Renewal ramps are too steep:** over 55%;
- **Oren's spiral lands on the lift's landing;**
- **a raised walk is in the ground:** the Highline (outside its refuges) comes
  within 0.3 m of the live ground.

It reports every flight's length and grade, and every level's guard runs.

## 7. Open

1. Should the refuge shelves (E1–E3) lead on up the crater wall to the rim, or
   stay as shelves?
2. Is the inn's 1 m drop to the Gate Terrace's level acceptable, or should the
   terrace rise to 49.5 instead?
3. The walk from the arrival portal to the funicular's foot is about 95 m.
   Should a paved path be laid along it?
