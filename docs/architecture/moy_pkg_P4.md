# Package P4: the Old Moy tower-house kit

## Latest user direction — 2026-10-21: playable city, Ohio/Snowhio detail

This is the controlling goal: a nice playable city environment that broadly
matches the provided plan models, about as sophisticated as the existing
Ohio and Snowhio villages. Earlier precision-manufacturing interpretations,
exhaustive part/join certification and blanket surface reachability gates
are superseded. Use the schedules as design references to preserve the
recognizable architecture, not as an obligation to perfect every small join.

Prioritize model silhouettes, proportions, facade rhythm, materials and major
features, with sound ordinary collision, usable streets/shops/passages and
intentional playable connections. No major visible holes, broken surfaces or
blocking circulation. Intended routes remain deliberate checks, not a demand
to reach every surface. No new climbing behavior or movement retuning.

Use existing village construction patterns and pragmatic model-consistent
geometry. Fix visible defects with proportionate solutions. A clean simplified
corner can meet the goal without millimetre-level cap certification. No new
geometry/test framework or exhaustive diagnostic histories.

Iterate with fast local representative previews, reusing an existing Godot
run where practical. No full-city bake/render/activation cycle for each edit.
Inspect a couple of changed views at ordinary resolution, then bake and do a
focused in-game smoke test when a coherent architecture batch is ready.
Final streamed integration is required; repeated integration runs during
small edits are not. Run required repository hooks at actual commit/push
boundaries, without repeatedly running the same broad suite beforehand.

The fresh implementation owner follows `moy_coping_repair_handoff.md`, whose
current content now covers this practical construction direction. Historical
test results remain factual records; they do not override this user decision.


2026-10-18. Build-session brief. Read `moy_build_roadmap.md` first.

- **Area:** Old Moy, the well town: the Well Quarter's blocks either side of
  West Street (`CityPlan.OLD_TOWN`, `CityPlan.OLD_HOUSES`) and the Old Moy
  lots on the grid round them (`old_moy()` in `tools/city_layout.py`).
- **Target level:** L2, built.
- **Depends on:**
  - P0 (the check suite) for its acceptance. It can be built before P0
    lands, but it is not *done* until the suite passes on its area.
  - P3's tile house, for the pencil infill (section 2.3). If P3 has not
    landed, build the tile house once, as P3's brief describes it, where
    both packages can share it.
- **Model:** `docs/drawings/moy_old_moy_3d.html`. Match it.

## Current acceptance clarification — user decision, 2026-10-21

Not every surface must be reachable. This overrides blanket reachability
requirements in earlier checks, milestone briefs and dated review fix lists.
It changes the review scope, not the recorded results of past trials.

- Substantial architecture retains correct physical collision and support
  where encountered. A `landing` collision role does not require a route to
  every instance, nor a direct jump from the street.
- Street doors, entered shops, court passages and intentional connecting
  roof links remain usable; collision defects, blocked circulation and traps
  in playable circulation remain actionable.
- Test explicitly authored parkour routes on representative geometry with
  both characters and their intended powers. Do not extrapolate those route
  examples into a climb/access requirement for every house or surface.
- Evaluate reach/audit findings against the actual route and owner. Preserve
  raw findings; classify irrelevant blanket reach findings with reasons.
  Do not weaken collision, ignore actual route defects or disable checks to
  obtain a pass.
- A construction milestone may pass its part/join/collision/visual scope
  while package-level authored route work remains open and separately named.
  Report construction and route acceptance separately.

House076's failed direct approach or incomplete floor-to-floor investigation
is not a blocker to completing its architecture representative. No new
climbing mode, movement retuning or equipment policy is authorized here.
Immediate work: `moy_p3_boom_construction_finish.md`.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`, `moy_build_roadmap.md`.
2. `docs/architecture/moy_tower_house.md`: the kit's design. Sections 3.1 to
   3.5 are the specification. Its section 4 (the Reese–Miller house) is
   for the house's outside only; its site sketch is superseded (section 6).
3. The Old Moy charter in `docs/style_charters.md`.
4. `docs/architecture/city.md` section 7, Old Moy: grep for "Old Moy" and
   "Well Quarter". Do not read the whole file.
5. The plan data. **The data wins** over every document:
   - `CityPlan.TOWER_HOUSE`: the kit's numbers (all in metres), and its
     `parts` and `joins` (section 2.7).
   - `CityPlan.OLD_HOUSES`: 60 houses. Each has `corners`, `storeys`,
     `front` (the road it was cut from), `door` (the road its door is on,
     or `court`, or `through`), `front_edge` (the index of the corner pair
     that faces that road, or −1) and `kit`.
   - `CityPlan.LOT_KITS`: the 30 Old Moy grid lots (27 tower, 3 infill),
     `front` as `n`, `s`, `e` or `w`.
   - `CityPlan.BUILDING_KITS` 25 to 32 and 52: the numbered tower houses.
   - `CityPlan.OLD_TOWN`: `courts` (8), `pockets` (38), `roof_links` (15),
     and `squares[0].first_well`.
6. The model: `docs/drawings/moy_old_moy_3d.html` (published:
   https://claude.ai/artifact/53om5eQsd5KvwUirnxrc7z). The kit sheet shows the three
   kinds of house at true size beside the hero.

## 2. What to build

Today every Old Moy house is a plain block (L1). Replace each one with its
kit house, from its data. Build no house by hand.

**The kit is exterior only.** These houses are not entered in P4.
- No core, ramp or flat is built inside. The house is solid to its outline.
- The house door is a closed door, painted (blue, green or ochre), in a
  gypsum surround, with the house mark painted above it.
- A shopfront is shuttered by day's end and open by day: a 1.5 m-deep
  dressed shop window behind it, in plain shapes at L2, as in P3.
- The Reese–Miller house's inside is P13h; Pinestein's lab is in P17.

**99 houses:**

| Where | Tower, stone base | Tower, earth base | Pencil infill |
|---|---|---|---|
| Well Quarter (`OLD_HOUSES`) | 40 | 13 | 7 |
| Grid lots (`LOT_KITS`) | 25 | 2 | 3 |
| Numbered (`BUILDING_KITS`) | 6 | 3 | 0 |

### 2.1 The tower house (`kit: tower`)

From `TOWER_HOUSE` and the house's `kit`, bottom to top:
- **Plinth** of basalt, `plinth` high.
- **Stone base** (`base_kind: stone`, `base` storeys): dark basalt, plumb,
  pale ashlar bands; a white frieze where the brick begins.
- **Earth base** (`base_kind: earth`): rammed earth in `lift` courses,
  battered `batter`° (the outer face steps in as it rises, the inner face
  plumb); its plan one superellipse (exponent `corner_exp`); lift ends
  turned up `horn` at its corners; the white gypsum band (`cornice`) on top,
  square like the brick above it. No corbels or squinches (user, 2026-10-18:
  it is a game; it must look clean).
- **On a leaning or curved face** (`on_surface`): every light, window, sill,
  door, shopfront, kishk and spout sits on the wall's real surface at its
  height (the earth's superellipse, stepped in by the batter), turned to that
  surface's normal, and only where the surface is flat to 3 cm across it. A
  door or shopfront moves toward the middle of its face until it is.
- **Brick storeys** to the roof, plumb, on the outline.
- **Friezes** at every brick floor, from `frieze.kinds` by `kit.frieze`;
  `polite` houses carry a second band and relief panels between windows.
- **Parapet** `parapet.h` high with merlons in pattern `kit.parapet`, and
  whitewashed horns at the corners.
- **Roof:** the kiosk over the core with the **wind tower**, its mouth to the
  west; the **manzar** where `kit.manzar` (20 houses); water tanks on some.
- **Openings** (section 3.2 of the kit): base lights; brick windows under a
  qamariya, outlined in white, paired on polite houses; the mafraj's low
  wide windows on the top floor; `kishk` box windows on the front.
- **The door** on `front_edge`; `shop` adds the shopfront beside it, never
  instead of it. A `door: court` house has its door on its court's side; a
  `door: through` house shows its door on its longest yard-side face.

**Turned plots.** Follow each Well Quarter house's `corners` at the base, and
square the tower above where the outline is irregular, as `moy_tower_house.md`
3.6 says. The front face stays on `front_edge` all the way up.

### 2.2 Holds

The houses are climbable by their own features, never by added rungs:
- string courses, sills and qamariya heads up every brick face, never more
  than `holds_max` apart (the plan checks the kit's spacing);
- the stone base's ashlar bands and lights;
- an earth base only at its rounded corners, where the turned-up lift ends
  give a hold every `lift`.

### 2.3 The pencil infill (`kit: infill`)

P3's tile house, built from the infill kit's `gen: tile`, `colour`, `lift`,
`signs` and `roof` fields: plumb, mosaic-tiled, a glass lift shaft on its back
face, no ramp core. These are the narrowest plots (under `infill_below`).
Its parts and joins are P3's schedule (`CityPlan.MARKET_HOUSE.parts` and
`.joins`, `moy_pkg_P3.md` 2b), not the tower house's.

### 2.4 The courts, the passages and the pockets

The middle of each block is open ground left by the houses
(`OLD_TOWN.courts` and `OLD_TOWN.pockets`).
- **Courts** (8, from 36 to 327 m²): paved, open to the sky, with a bench,
  a few pots and a washing line each (L2 plain shapes). The Reese–Miller
  court has the old capped well head and the bicycles of its section 4.
- **Passages:** a court with a `passage` is reached from its road through
  that house's ground floor: a covered passage `w` wide and `h` high, from
  `passage.court` to `passage.road`, with an arched opening at each end and
  a lamp inside. Cut it through the house's collision.
- A court marked `open` meets its road directly; leave that side open.
- **The grid blocks' courts** (`COURT_WAYS`, added in P3's data review): two
  courts behind Old Moy's grid lots, reached by passages through `LOTS[5]`
  (from West Street) and `LOTS[17]` (from Clinic Lane). Build them the same
  way.
- **The small slots** (`OLD_TOWN.pockets`, revised 2026-10-18, at the
  user's direction: **no blank blocks**). Nothing is filled solid:
  - `pocket` (25): a little open space off the lane, paved, with a bench,
    pots, and a small tree (kind `round`) where `tree` is true (15 of them);
  - `yard` (1): a family's yard, walled `pocket.wall` high along its open
    sides, with an open gateway `gate_w` wide at `gate`;
  - `alcove` (1): a narrow paved recess off the road, a few pots;
  - `paving` (11): slivers under 1 m between a house and the street: lay the
    street's paving over them, flush;
  - the slots with no opening on a road were folded into the houses beside
    them in the data (9 houses grew a little): nothing to build.

### 2.5 The roof route

Each `roof_links` entry is a timber ramp on the lower roof, `w` wide, from
`foot` at height `y[0]` to `head` at `y[1]`, along the party wall, through a
gap in the higher house's parapet. Keep the kiosk, wind tower and manzar
clear of every ramp. Shibam's bridges are not in this package.

### 2.6 The first well on Cinema Square

From `OLD_TOWN.squares[0].first_well`:
- the well head, round, capped with a stone lid (solid);
- its stone trough (solid; its top a landing);
- the old ghaf over it (`tree`, kind `round`, from the park's tree kit): the
  trunk solid, the crown decorative.

### 2.7 Parts and joins (binding)

**Build every piece from the schedule:** `CityPlan.TOWER_HOUSE.parts` (51
parts) and `.joins` (10 joins). The model's kit sheet draws the same schedule:
match it piece for piece. Nothing in the house is left to choose. If a piece
seems missing or wrong, say so in the diagnostic; do not invent one.

- **Shapes**, with the game's own code:
  - `egg`: `SuperEgg.build_part(semi, colour, eps[0], eps[1])`;
  - `clipped`: `SuperEgg.build_clipped_part(semi, planes, colour, eps…)`,
    with the planes its join names; every cut is capped;
  - `profile`: a superellipse outline of exponent `n`, extruded;
  - `wall`: a `SolidModel` solid of the outline, its openings punched;
  - `punched`: a `SolidModel` cutter of exponent `n` through its wall. The
    glazing is that cutter intersected with the wall, and the gypsum ring is
    the cutter grown by `ring` less the cutter, as the architecture skill
    says;
  - `box`: only the roof slab, for its stated reason;
  - `decal`: painted, not geometry.
- **Sizes:** `semi` is half-sizes across the face, up, and out from it;
  `fit` means the plot sets it. A seated part's centre is on its seat and
  its upper half is kept; a part against a wall is centred on the wall face
  and its outer half is kept.
- **Joins:**
  - **floor cut** (`floor_cut`), as `scripts/world_door.gd` builds every
    door in the game: the house door and the kiosk door are **one leaf on one
    hinge**, an egg reaching below the floor and cut flat at it, so its bottom
    stands square on the threshold and its top keeps its soft shoulders. Use
    the same construction (in P4 the houses stay shut, so the leaf is static,
    without the interaction or its lock message).
  - **split** (`shutter_set`): the shopfront's four shutter leaves are cut
    from one parent egg the size of the closed opening, by `cuts` and by the
    floor; each hinges at its outer edge and they fold back in pairs to the
    jambs by day.
  - **Openings to the floor** (the door, the shopfront, the court passages:
    `floor`) are flat at the floor.
  - **The frame is the door's own shape** (`outline`, `clear`): the door
    opening and the shopfront are cut from the outline of the leaf or shutter
    set that closes them, grown by `clear` (a hairline), and stand on the
    same spot and the same floor. The gypsum surround is that outline grown
    again by the ring width, less the opening. Never draw a frame as its own
    arch or rectangle: a frame that is not the door's shape shows a gap or
    an overlap.
  - **meet** (`cap_ridge`): the wind tower's two cap slabs both run past the
    ridge and are cut at its one plane.
  - **chain** (`band_chain`, `lift_stack`, `ramp_ends`): each frieze,
    cornice and ashlar band is one egg per face, cut at both corners'
    bisectors and at the wall face, so neighbouring runs meet on one mitre
    line. The ramps are cut at both roofs' tops from one datum.
  - **seated** (`seated`, `against_wall`): merlons, horns, posts, pots, the
    well head, the wind shaft; and sills, lintels, the kishk, its brackets,
    the spouts and the latrine shaft against their walls. Each is cut flat
    where it sits and capped. Nothing is buried whole.
  - **punched** (`punched`): every opening.
- **The test**, as the architecture skill sets it: look at every join from
  both sides. A gap, a step, a double thickness or a mismatched profile
  fails, however small.

### 2.8 Construction

- The rounded earth corners are the kit's superellipse (`corner_exp`).
- Share meshes and materials between houses; merge static pieces per bake
  cell by material, as the bake builder does.
- Bake everything into the Moy bake (`moy_city_bake_builder.gd`), with the
  kit's sources in the bake signature. Keep the silhouette multimesh working.

## 3. Collision

- **Solid** (`CollisionPolicy` blocking): every house to its outline; the
  earth base's batter as its stepped lifts; kiosks, wind towers, manzars,
  parapets; the well head, trough and tree trunk; the pockets' benches and
  tree trunks; the yard's wall.
- **Parkour landings:** plinths, cornices, string courses, sills, kishk tops,
  parapets, roofs, kiosk and manzar roofs, wind tower caps, roof ramps, the
  trough.
- **Decorative:** lattice, relief panels, drainpipes, lift ends beyond
  0.1 m, laundry, pots, the ghaf's crown.
- **Passages** are open: no collider across them.

## 4. Checks

1. `python3 tools/city_layout.py` passes. It now checks, among others: every
   tower house fits its core; every house has a door face, a court or a way
   through; every court of `court_min` or more has a way out at ground
   level; the first well stands clear in its square, under its tree.
2. **The check suite** (P0) on Old Moy's bounds, `x −790 to −637`:
   - `overlap`, `buried`, `underside`, `solid`, `guard`;
   - `trap`: no court, pocket, yard or roof you can get into and not out of;
   - `reach`: street doors, passage ends and the endpoints of intentional
     roof-ramp connections. This does not require street access to every roof.
   If P0 is not yet built, say so and list what you checked by hand.
3. **Authored parkour routes**, on representative geometry with both characters
   and intended powers (separate from individual construction milestones):
   - up a stone-based house by its holds, from the street to the parapet;
   - up an earth base by its rounded corner;
   - along the Old High Street by vine from Arcade Street to Clinic Lane;
   - roof to roof by a ramp, and across a court by a jump where the roofs
     are close;
   - into the big court by its passage, and out again.
4. **Performance:** draw calls, triangles and frame time from the
   performance probe at the viewpoints below, before and after. 99 houses
   share one kit: if it costs more than P3's area, say so.

## 5. Viewpoints

From `docs/drawings/moy_city_3d.html`'s places:
- `oldmoy` and `wellquarter` (overviews);
- `cinemasq` (Cinema Square and the first well, at eye height);
- `oldhigh` (up the Old High Street at 14 m);
- `oldcourt` (the court behind the Reese–Miller house);
- `oldroofs` (across the roofs).

Each at noon and dusk.

## 6. Report

Write `docs/diagnostics/<date>-moy-P4.md` with:
- **the schedule as built:** one line per part and per join in
  `TOWER_HOUSE.parts` and `.joins`, saying how it was built and naming the
  function used, with a close screenshot of each join kind (the door pair
  shut and open, a frieze mitre, the cap's ridge, a seated merlon, a punched
  window with its glass and ring);
- what was built, with counts by kind;
- the check results;
- the parkour runs;
- performance before and after;
- the screenshots;
- every place the data and this brief disagreed.

## First build review — 2026-10-19: fix

Reviewed `fdbc8f8`, `../diagnostics/2026-10-19-moy-P4.md`, its raw audit,
rendered before/after summaries, and Old High Street/court noon screenshots.
**Result: fix, not L2.** The report accurately describes a partial proxy pass.
Keep the 99-owner integration; complete the existing brief rather than
accepting approximations or writing a smaller replacement specification.

0. **Confirmed winding fault: fix before further facade work.** Reviewer
   inspection of actual baked ConcavePolygonShape3D arrays found 315 roof
   triangles facing down and zero facing up in 96 parsed P4 house bodies.
   Wall fronts were mixed: 288 inward, 726 outward. This scan is a verified
   subset, not a claim that all 99 bodies were parsed.
   `_polygon_building` reverses Geometry2D's triangulated roof order and
   emits walls without normalising the footprint orientation. The assigned
   UP/outward normals do not correct reversed vertex winding; wall normals
   can also disagree with the actual front. `_poly_floor` uses the same
   reversed top-face order and must be checked for court/pocket paving.
   Use Godot's clockwise convention: front = (c-a) cross (b-a). Normalise
   ring orientation or emit each face toward its explicit expected outside,
   including concave footprints. Re-bake all affected meshes/collision.
   Prove positive upward roof/floor fronts and exterior-facing walls on
   both CW and CCW rectangle/concave input fixtures, and representative
   final baked houses. Render from outside/above with default back-face
   culling and exercise top/support collision. Do not fix this by disabling
   culling, flipping only shading normals, or hiding a tiny BoxMesh cap.

1. **Finish the scheduled house forms.** Implement all 51 part templates and
   10 joins, including distinct stone/earth bases, battered superellipse lifts
   and horns, cornices, patterned friezes, surface-fitted openings and qamariya,
   kishks/brackets, service pieces, roof kiosk/wind mouth/cap and manzars.
   The screenshots show plain continuous masses and facade strips, not the
   authored kit. Use actual SuperEgg/profile/cut-and-cap construction; do not
   copy the browser model's pointed sampling artifacts. Complete P3's shared
   tile grammar before the ten pencil infills.
2. **Restore circulation first.** A single `_polygon_building` blocker currently
   spans court passages. Punch the real passage and collision, fit lamps,
   and retain solid private flats elsewhere. Build the specified yards,
   gateways, pockets, planting and the complete well/lid/trough/ghaf composition.
   A painted facade panel is not a passage or shop opening.
3. **Make the roof network usable.** Complete perimeter parapets/merlons with
   actual openings at roof-link ends. Cut both ends of each of the 15 ramps
   to the adjoining roof/landing planes and add side protection where
   specified. Prove continuous top surfaces and both directions of traversal;
   a collider on an inclined box is insufficient.
4. **Resolve geometry failures with a matched baseline.** The supplied area
   audit has 96 trap and 108 reach findings, with 14,769 trapped walk cells.
   Identify P4-owned failures by check/location/owner, compare the same area,
   start, grid and settings before/after, fix new blocking failures and
   separately list inherited surrounding-city debt. Do not pass the package
   from the generic runtime validator's 99-owner/15-ramp counts.
5. **Fix the unload correctness blocker with P3.** The final after probe's
   two cycles are unsettled: 34 then 36 requests remain despite zero active
   packs and pending exits. Trace path/status/lifetime, release safely, and
   prove settled cycles and actor uniqueness. This is correctness work;
   do not turn it into the deferred city-wide P2 optimization loop.
6. **Supply the missing movement and join evidence.** Run the five required
   hero/Xiao routes, with actual movement, supports and anchors. Include
   the door/opening pair, frieze miter, cap ridge, seated merlon and punched
   window/glass/ring close-ups. The current `oldhigh` noon shot is dominated by
   a nearby wall; reposition only the camera to show the intended street
   route, then record its pose. Keep the other useful district images.
7. **Report the final state honestly.** Re-bake, check freshness/coverage and
   plan/runtime checks, repeat the area P0 fixtures and before/after rendered
   samples. Keep performance numbers as observations while districts are
   replaced. No printed letters or numerals on architecture/signs; picture
   marks are allowed. List every part/join and any remaining failures.
   Write `docs/diagnostics/<date>-moy-P4-fixes.md` and stop for review.

**Handoff:** P3 first, then P4, using the existing binding schedules. Neither
package is accepted as a finished district by this review.

## Second build review — 2026-10-20: fix

Reviewed `../diagnostics/2026-10-20-moy-P4-fixes.md`, all twelve final-bake
noon/dusk images and their manifest, the final-rebake area JSON, rendered
probe, winding validator and current builder. **Result: fix; not L2.**
The 99 owners and 15 ramps remain useful integration work; the diagnostic
explicitly says the 51-part/10-join kit is still a proxy.

**Progress credited.** `check_moy_bake.py` passes with 248 current packs.
The reviewer reran `validate_moy_winding.tscn`: CW/CCW rectangle and concave
building/floor fixtures and twelve generated house representatives (eleven
towers, one infill), `failures=0`, exit 0. The roof images now show visible
top faces with the supplied default-culling capture. This resolves the
identified source winding defect. Important limit: `_check_baked_houses`
calls `BUILDER.build_packs()`, not `ResourceLoader` on the saved packs; its
name overstates its final-bake proof. Audit representative saved collision
and top support before acceptance. The run emits Dummy-renderer cleanup
errors; it is not a clean full-area rendering audit. Paired rail collision
is now present on the ramps; this alone does not make their ends walkable.
The final P3 and P4 probe JSONs both report settled unload cycles; the
previous 34/36-request symptom is closed for those samples, with controlled
re-entry/actor/support correctness still owed.

**Remaining fix list (after P3's shared tile grammar):**

1. Build all 51 parts and 10 joins from the unchanged plan: distinguish
   stone from battered superellipse earth bases, surface-fit openings and
   trim, complete friezes/qamariya/kishks, wind towers and manzars. Replace
   the proxy masses/strips with scheduled construction. Supply the missing
   part/function/status ledger and isolated join close-ups from both sides.
2. Cut passages through old houses 0, 10 and 44, including the colliders
   and plinths, with the scheduled arches and lamps. Complete courts,
   pockets, yard/gateway and planting; the current well is only a cylinder,
   without its complete lid/trough/ghaf composition. Prove entry and return
   through each court route with both playable controllers.
3. Finish all 15 roof links: actual gaps through the correct parapets,
   floor-plane end cuts, usable landings and clear kiosk/manzar positions.
   Rails leave 1.04 m between their inner faces on a 1.2 m ramp; report actual
   clear width and prove both controllers fit. Complete both-direction
   roof traversal and all five section 4 parkour routes with actual movement,
   supports and vine anchors. Counts and inclined-box collision do not pass.
4. Attribute and fix package-owned audit failures against a matched baseline.
   The latest report still has 1,220 findings (108 reach, 96 trap), with
   14,769 trapped cells. It includes surrounding stations and estate bodies;
   do not call that total all P4 debt or dismiss it all as inherited.
   Resolve the reported RID/mesh-access errors for a trustworthy underside
   result, or rerun the affected audit with a backend that can inspect it.
5. Fix the evidence views. `oldhigh` shows one isolated rooftop against
   empty space; it does not show the street corridor claimed in the report
   or the required route at +14 m. Verify subject/neighbour pack readiness
   and record loaded state before recapturing the route. `cinemasq` shows
   the bare well cylinder, without the specified composition. Keep useful
   overview/roof images, add street-height base/opening and passage views,
   and retain the six named noon/dusk views and exact camera poses.
6. Write the next fixes diagnostic after final rebake and freshness checks,
   with saved-pack winding/support proof, full schedule ledger, resolved
   owner findings and real-hero/Xiao runs. P4's partial rendered probe passed
   its sampled p95 budget but lacks controlled routes and uses different
   before viewpoints: it is not matched performance acceptance. City-wide
   performance optimization stays with P2.

## Third build review — 2026-10-20: fix

Reviewed `../diagnostics/2026-10-20-moy-P4-second-review.md`, all fourteen
noon/dusk captures and their manifest, the well builder and saved
`assets/generated/moy_city/cell_00_04.tscn`, the unchanged schedule and new
rendered probe. **Result: fix; not accepted at L2.**

**Progress credited.** The saved pack contains the added lid, hollow trough,
trunk collider and decorative crown. Fresh reviewer checks: bake freshness
passes (248 packs), plan validator exits 0 with 0 failures, and diff whitespace
passes. These are useful additions, but the claim that the composition is
complete from plan-owned dimensions is not supported by its forms or joins.

**New concrete fixes, in addition to the second review:**

1. **Fit the well composition to the plan and schedule.** The trough is
   `along: z` in the plan. Its saved identity transform and 3.2 m BoxMesh run
   along x: honour the authored orientation. Replace the five intersecting
   box pieces with the scheduled clipped, hollowed vessel and landing
   collision, and build the head/lid/trunk from their scheduled profiles.
   The crown is a single scaled SphereMesh, not the scheduled soft-egg
   cluster or shared round-tree kit. It also floats: for h=14, trunk top is
   +7.70 m and crown bottom is +9.14 m, leaving a 1.44 m gap. Join the crown
   to the trunk through the authored tree form. Verify the saved geometry
   from ground level and above, including top support and collision policy.
2. **Fix the well and route captures.** `cinemasq_close` shows the crown and
   surrounding walls but hides the well/trough. `oldhigh` now has surrounding
   rooftops visible, an improvement over the isolated rooftop, but remains
   a roof view rather than the required +14 m street/vine route. Capture
   readable ground-level well/passage views and the actual route, with loaded
   neighbour state and exact poses; retain the useful district overviews.
3. **Supply current verification.** There is no new full P4 area audit,
   saved-pack winding/support test or real-controller route proof in this
   pass. Historical checks cannot close the unchanged 108 reach/96 trap
   findings. Recover P0 mesh inspection from the reported renderer failures,
   attribute both owners of each intersection, and resolve P4-owned blockers
   with matched settings rather than requesting a pass from coverage counts.

**Still open.** The 51-part/10-join house kit and as-built ledger, passages
through old houses 0/10/44, court/yard/pocket work, all fifteen roof-link end
openings/landings, and both controllers' court/roof/parkour routes remain
unbuilt or unproved. The second-review requirements remain binding; adding
the well does not close the house kit or circulation.

**Performance scope.** The new compatibility-renderer probe's recorded
source hashes match current files and unload cycles settle. Its six P4
views have p95 39.745–70.099 ms; budget and repeated-stall gates fail and
controlled routes are absent. Its before route is unmatched. Keep this as
failed sampled performance evidence, with full city optimization in P2.

**Handoff:** complete P3's shared tile grammar first, then P4's existing
second-review list plus these corrections. Return with final saved-pack
checks, useful join/route captures and actual hero/Xiao movement evidence.

## Fourth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P3-P4-third-review-build.md`
and current builder SHA-256
`9a4327d0a5290916fab051238c84f0a2e67e8d9a35715b017e1489c71fd1531f`.
No new screenshots, controller routes or area audit were submitted.
Fresh reviewer bake check passes with 247 packs; targeted source whitespace
check passes. **Result: fix; not accepted at L2.**

Credit the trough orientation correction and removal of the floating single
sphere. Saved `cell_00_04.tscn` has the new three-mesh crown at world
(-746.5, -53.28, 24), matching the builder; its base is now below the trunk
top. This closes the prior 1.44 m air gap at source/placement level. The
five-box trough and cylinder head/lid/trunk still depart from the binding
scheduled forms. No new rendered tree/well or support proof was supplied.

**Next build round, after P3's shared grammar:**
1. Build the unchanged 51-part/10-join kit with its function/status ledger,
   the scheduled well vessel/profiles and a coherent authored tree form.
   Preserve the plan's dimensions; moving foliage to hide the gap is not
   itself acceptance of the tree silhouette.
2. Cut old-house passages 0/10/44 and finish all fifteen roof-link parapet
   openings/landings. Demonstrate both controllers through courts and roof
   links, plus all required stone/earth/vine/jump routes, on saved loaded packs.
3. Recover area/runtime inspection with a working rendered backend or the
   actual mesh lifecycle fix, not another identical failed Dummy run. Supply
   current owner attribution, saved-pack winding/top support and readable
   passage/roof/well/join captures. Existing historical totals remain open.

The build explicitly reports no controller or current audit proof; do not
repeat that partial submission as acceptance. Earlier performance evidence
is historical for this changed bake. Keep city-wide optimization with P2,
finish a coherent milestone, write separate package diagnostics and stop
editing so the automated reviewer can inspect a stable state.

## Fifth build review — 2026-10-20: fix (automated loop)

Reviewed the package's `../diagnostics/2026-10-20-moy-PP4-fixes-final.md`,
its ledger, current controller/saved-pack harnesses, raw evidence and all noon
captures. Builder hash `6d736880bdf78f899e3648c89bfe5eaf75d781524faa9fedd9028afeb609545f`
and manifest hash `d6e88eaab2080b3b7629a978b9a3b601902dffba23accf1399e4650afb1891bb`
match the submission. Fresh bake freshness check passes (247 packs).
**Result: fix; no L2 acceptance.**

**Progress:** a fresh rendered audit and saved-pack subset are now available.
The owner-filtered audit records 18 overlaps and 372 guard warnings; it is
useful attribution, not proof that full-area reach/trap findings are unrelated.
No required P4 route passed; the ledger still marks every part partial.

**Next milestone, after the P3 shared grammar:**
1. Complete a representative stone/earth house and its scheduled joins,
   then replicate the actual 51-part/10-join kit. Build passages 0/10/44 and
   fifteen usable ramp ends/landings. The principal implementation blockers
   have remained open across reviews; another inventory or performance run
   does not replace the work.
2. Repair the shared controller harness as P3's fifth review specifies.
   The arbitrary three-route straight-z test does not implement the P4
   stone/earth/vine/ramp/jump/passage suite. Inspect the intended walk path
   and bench contact before moving `OldMoyCourtBench_00`; a camera/start
   inside a furnishing is a harness defect, not sufficient evidence that
   the locked city's walk route needs redesign. Run actual routes both ways
   on saved packs, with support and anchor assertions, using the rendered
   compatibility backend that already works for captures and P0.
3. Make the saved-pack geometry test fail on real orientation/support defects
   and record coverage after merging. Current counts are not asserted and
   local triangle height is not a reliable roof classifier. Investigate
   flagged zero-area faces without discarding thin valid geometry.
4. Resolve owned overlap pairs and explain reach/trap attribution by plan
   ownership/location, including numbered buildings and both collision owners;
   an empty name-filter result does not close these checks. Keep valid new
   audit evidence and use focused reruns after each fix.
5. `oldhigh` and `oldhigh_route` are now dominated by a wall; well close is
   also blocked. Correct poses by visibility checks and self-inspection,
   retaining a real +14 m route view and readable ground-level composition.
   Do not recapture the entire city or rerun P2 to document unchanged failure.

Both packages remain fix. The next automated continuation prioritizes actual
construction and a valid harness; final acceptance still requires every
scheduled kit part/join, completed route suite and current geometry proof.

## Sixth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-PP4-second-third-review-completion.md`,
current source, saved-pack validators, route JSON and current noon captures.
Current builder SHA-256 is
`1c67f1ea3b88588f425ff97637e72a388761a0972ba0e3f0499393e2f0108ec8`;
manifest is `598ab4688a7503400b304a11a3f41cf38861b3d84ec6d25d4b55079e7f393002`.
Both route reports match these hashes and name gl_compatibility / Apple M5.
Reviewer bake freshness passes at 248 packs. **Result: fix, not L2.**

**Credit and preserve:** sixteen rendered movement records now cover both
controllers through passages 0/10/44 both directions and roof ramp 00 both
ways. This closes the earlier uncut-passage source blocker for those three
owners and supplies limited usable-ramp evidence. It does not prove all
scheduled arch/lamp/threshold forms or all fifteen roof links. Check stable
landing holds using the hero's actual grounding/support resolver and a
measured support ray; do not discard useful route evidence solely because
his CharacterBody floor flag is false. Current helper samples proximity
support but does not assert a sustained final landing.

Saved-pack inspection now rejects selected degenerate faces and finds the
cut owners. It still uses local centre_y>0.5/downward triangles as a heuristic;
this cannot prove the correct outward direction or all landing planes.
Add targeted expected-plane/support assertions and preserve valid thin faces.

**Next build milestone, after P3 grammar:** complete a scheduled tower-house
representative with genuine stone/earth base distinctions, fitted openings,
friezes, wind tower/manzar, joins and part-level evidence; then replicate.
Finish all roof-link end openings/landings and their routes, courts/yards/
pockets, full stone/earth/vine/jump parkour and the well's scheduled vessel/
head/lid/trunk. Current diagnostics still explicitly call these incomplete.

**Evidence:** the roof-ramp overview is useful, but `old_passage_10` is
mostly wall and `oldhigh`/`oldhigh_route` are effectively blank brown frames.
The well close is an overhead composition rather than the required readable
ground-level form. Change only the failed poses, inspect them before keeping
them, and supply real +14 m route visibility plus both-side join captures.
No need for another full screenshot/performance sweep of unchanged geometry.

**Area and plan:** current matched owner-attributed P0 remains owed after
these changes. Reconcile the generated-plan drift described in P3's sixth
review before claiming the locked plan is unchanged; some ring reordering
is equivalent, but that does not establish every changed polygon/front is.
Preserve unrelated work and regenerate through `city_layout.py` only.

Both remain fix. Continue with construction rather than another broad report
round, preserve credited passage/service progress and stop at a substantial
verifiable milestone for the next automated review.

## Seventh build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P4-sixth-review-milestone.md` and its
rendered route/hold report against the same current builder/manifest hashes
recorded in P3's seventh review. **P4 remains fix.**

Credit sixteen movement records and their new 30-frame stationary holds for
both controllers through passages 0/10/44 and ramp 00 both ways. The ray,
nearby capsule and real grounding resolver supply stable support with zero
drift even where CharacterBody's floor flag is false. This closes endpoint
hold evidence for those tested routes, not all roofs or parkour. Preserve it;
rerun only when geometry or relevant controller/harness changes justify it.

The 51-part/10-join house kit, fourteen other roof-link route proofs and full
roof-end geometry, stone/earth/vine/jump routes, courts/yards/pockets, well
forms and current owner audit remain unfinished. The oldhigh and passage
retakes still fail visibility; do not keep rerunning identical bad poses.
Once P3 grammar is complete, build a true scheduled tower representative and
finish roof links in one coherent implementation round, with focused evidence.
The plan reproducibility report confirms current generation but does not
resolve owner 43's height or owner 16's front/shop drift; follow P3's seventh
review reconciliation requirement before claiming unchanged locked data.

Neither package passes L2. All earlier full-kit, physical collision and
readable both-side join/route requirements remain binding; new performance
sampling and city-wide optimization stay deferred.

## Eighth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P4-seventh-build-diagnostic.md` and
paired P3/plan diagnosis. No P4 geometry or relevant controller changes were
submitted; do not repeat the unchanged review or its credited sixteen
route/hold proofs. **P4 remains fix** pending its full 51/10 kit, other roof
links, parkour, courts/well, current owner audit and readable failed views.

The P3 eighth-review planning decision authorizes source-only preservation
of the locked owner 16 shop/front/outline and owner 43 five-storey choices,
with stable identity and explicit generation checks. It does not authorize
new layouts or city-wide variant reassignment. Finish the P3 representative
and shared grammar, then implement the outstanding P4 kit and routes in a
coherent build round. Preserve tested passages/ramp00 and avoid unrelated
performance or repeated full screenshot sweeps.

## Ninth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P4-second-third-review-fixes.md` and
current route report against the same source/manifest identity as P3's ninth
review. **P4 remains fix.** Sixteen movement/hold records pass, but the shared
run explicitly fails neighborhood readiness twice, including the OldHouse10
street approach. Movement scope remains credited; readiness/safety is not.
No fresh screenshot or matched owned audit closes the other package blockers.

Preserve corrected locked owner16/43 decisions. Finish P3's winding/topology
and readiness recovery before extending its shared grammar: the current new
representative mesh helper and signed-volume test use the opposite front
convention from Godot. Never propagate that helper into the tower kit.
Then complete the actual 51/10 tower forms and fourteen remaining roof-link
proofs, all parkour/courts/well work and current owned audit. Retake failed
views only after subject/neighbor packs are demonstrably active; do not use a
narrow capture set to conceal unresolved required gameplay packs.

No L2 or clean saved-pack orientation claim follows from the current reports.
The earlier scoped route/service progress stands; full acceptance criteria
remain unchanged and city-wide P2 work stays deferred.

## Tenth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P4.md`, final 72-record route report,
local readiness snapshots, sampled pack report and run command metadata on
the same source/bake as P3's tenth review. **P4 remains fix.**

Credit both controllers through passages 0/10/44 and every roof link 00..14
both ways (72 records, no failures), with local-pack waits and endpoint holds.
This is valuable headless engine/controller physics evidence; the successful
command used headless OpenGL configuration and adapter is empty, so it is not
GPU-rendered proof. Keep the scoped movement and repaired ramp05/manzar
clearance, and do not rerun the full passing suite until relevant geometry
changes. All fifteen route-traversal requirements now have supplied records;
actual end geometry/clear width, scheduled forms and visual joins still need
acceptance evidence.

The 51/10 house kit, five parkour routes, courts/pockets/yard/well, current
owned audit and fresh readable captures remain the main build work. Complete
P3 shared grammar, then build the actual tower kit. Do not use all-partial
historical ledgers as current as-built completion or let repeated full-world
hotel loading checks consume each construction round.

The forced all-city test still fails five hotel pack states (including one
invalid_resource) and is not accepted. Record that shared/city loading defect
with exact paths and attribution; it does not cancel credited local passage/
roof movement or prevent independent scheduled construction. Preserve
required local streaming/support safety. Capture actual rendered views by
the diagnosis/escalation path in P3's tenth review. Source/generator and locked
output still disagree; follow that review's semantic reconciliation before
claiming the plan pipeline is repaired. No city-wide optimization is requested.

## Eleventh build review — 2026-10-20: fix (automated loop)

Reviewed the fresh continuation in `../diagnostics/2026-10-20-moy-P4.md`,
current source/manifest and failed route/audit artifacts. **P4 remains fix.**
The current generated plan/259-pack bake supersedes the tenth-review snapshot.
Xiao passes 36/36; hero passes 32/36. Four hero traversals fail on ramps 01/02
against OldHouse08/12. Withdraw the current all-ramp success claim for the
hero; retain the older 72-pass report only as historical evidence on its old
plan/bake. Stable holds at a blocked endpoint do not make a route pass.

Fix the actual corridor obstruction/roof-end collision with the unchanged
plan and whole hero capsule, then run only the failing directions first and
regression-test other changed roofs. No tolerance relaxation or arbitrary
controller teleport target change to hide the collision. Keep the successful
local readiness and other passage/ramp evidence at its exact source scope.

The fresh area snapshot has 123 blocking findings (23 overlap, 100 reach);
path attribution remains heuristic and needs actual plan owner/both-body
resolution. GPU isolation now works, but the well is plainly simple proxy
forms, and the passage capture is almost entirely wall. These do not pass the
51/10 kit or district/join/route visual acceptance. Finish the scheduled kit,
five parkour tasks, courts/yard/well and current owned fixes after P3 shared
grammar. Rewrite final diagnostics around current results instead of leaving
72/72/old-bake claims above superseding failure paragraphs.

The construction backlog has persisted while verification tools improved.
The next handoff must deliver actual complete scheduled construction and
repair the four current route failures, not another report-only round.
Full L2 criteria remain unchanged; P2 optimization remains deferred.

## Twelfth build review — 2026-10-21: fix; paused for reassessment

Reviewed the stable final build turn `01a158c0-4dc2-7b32-9318-8bdfde9d840d`
after it stopped editing. Evidence is the package's
`../diagnostics/2026-10-20-moy-P4-current-fixes-pass.md`, current route JSON,
saved-pack checks, source and actual focused GPU screenshots. Independently
rechecked bake freshness: 259 packs. Builder SHA-256 is
`5af1395374f6e414b90631d3cb0c05e813827e9cfc331dc07db754d8a268517b`;
manifest is `d28fd5d1ba31f4b6a101274f91b3832069e1b44ebf756c5caf90833f66b0a816`.
Source/evidence hashes match. **P4 remains fix; L2 is not accepted.**

Credit the repaired hero ramps 01/02: the current JSON reports 72/72 input-driven
passage/roof movements for both controllers, including all 15 roof links in
both directions and three court passages. Landing/support assertions retain
the custom controller grounding distinction. Headless/Dummy execution and
mesh/RID noise limit this to measured physics evidence. Do not reopen the
four earlier failures on the basis of the superseded report, or treat these
routes as the five required stone/earth/jump/vine parkour tasks.

The eight-pack audit's zero failures are sampled heuristic checks, not a
51-part/10-join as-built ledger or acceptance of all 99 houses. Complete the
scheduled tower forms and court/pocket/yard/well details; verify each roof
opening, clear width, landing and physical join, plus remaining parkour,
re-entry and occupied-support behavior. Current owner-attributed matched
audit evidence is still missing; the old 123-blocking snapshot is historical.

Inspected all three current GPU images: the ramp is visible in isolation,
the passage crop is wall-dominated, and the well/trough/tree remain visibly
separate proxy forms. Required readable street-height, elevated route and
both-side join views remain outstanding. These isolated saved-pack captures
are genuine GPU evidence but do not establish district visual acceptance.

The user requested one final review, then reassessment. **Automated build/fix
rounds stop here; no implementation continuation is authorized by this review.**
Across the loop, route tooling, evidence provenance and a boom representative
improved more than full kit completion. Preserve that progress, but focus any
future authorized work on complete scheduled construction before another
broad validation round. City-wide P2 optimization and final performance
acceptance remain deferred. The implementation working tree is preserved;
this checkpoint commits review documents only.

## Decisions log

- 2026-10-21 (user): not every surface needs to be reachable. Keep physical
  collision, usable circulation and authored routes; remove blanket access
  requirements from construction acceptance. See the current clarification.


- 2026-10-18 (user): a house door is one leaf on one hinge, and every door
  leaf, shutter and doorway is cut flat at the floor, as Ohio's and Snowhio's
  doors are (`world_door.gd`).
- 2026-10-18 (user): the earth base keeps its whole-plan superellipse; the
  white band and the square brick sit on it as before; no corbels or
  squinches. It must look clean, not argue its structure. Openings and trim
  go on the curved surface (`on_surface`).
- 2026-10-18 (user): every piece and every join is decided in the plan
  (`TOWER_HOUSE.parts`, `.joins`), not left to the build; the model draws
  the same schedule; the diagnostic reports it part by part.

- 2026-10-18: the houses are exterior only, as in P3; the Reese–Miller
  house's inside is P13h.
- 2026-10-18: a Well Quarter plot is a tower house only if it is at least
  `infill_below` (6 m) across once turned; nine narrower plots are pencil
  infill. The kit had judged them by their square bounds.
- 2026-10-18: a house's door goes on the road it was cut from; where only a
  corner touches that road, on its longest face on another road. Four back
  houses touch no road: two open on their court, two are reached through a
  neighbour.
- 2026-10-18: every larger court has a ground-level way out: a passage
  (sabat) through a house or an open side on a road.
- 2026-10-18 (user): no blank blocks. The first pass filled every slot under
  25 m² solid; most open onto a road and were no trap. Slivers under 1 m are
  folded into the house beside them or paved; slots with no opening are
  folded into a neighbour; the rest stay open as pockets off the lanes, one
  walled yard and one alcove.
- 2026-10-18: the roof route gets timber ramps where touching neighbours are
  one storey apart. Shibam's bridges wait for a later round.
- 2026-10-18: the first well's tree is an old ghaf, the desert's shade tree.
- 2026-10-18: the Reese–Miller house's site in `moy_tower_house.md` 4 (a 3 m
  slot north, an infill to the south, a 12 × 16 m court) predates the Well
  Quarter's plots. The data wins: a four-storey house stands at its north
  end and its court is the block's big shared court behind it.
- 2026-10-18: door frames match their doors. Each opening and its surround
  are grown from the silhouette of the leaf or shutter set that closes it,
  on the same spot, flat at the floor.
