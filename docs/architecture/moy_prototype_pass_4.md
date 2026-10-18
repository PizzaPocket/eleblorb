# Moy: fourth prototype pass, build instructions

2026-10-17. Instructions for the next implementation chat. Keep following
`moy_prototype_pass_3.md` and the briefs it points to. **This document lists
only what changes.** If this document and the data disagree, the data wins:
report it.

## 0. Review of the third pass

Pushed late on 2026-10-17 (`a38fa97`, `2549ea4`); its diagnostic is
`docs/diagnostics/2026-10-17-moy-prototype-pass-3.md`.

Good, keep it:
- the flat annuli and continuous helix strips, with per-contact tangent travel;
- the open lower bridges at both gates;
- the moving tread belts with their closed returns;
- the call-post and destination-menu lifts;
- the honest list of what was not physically verified.

To settle:
1. **Platform edge.** The 7.5 cm boarding gap is authoritative. Keep your
   builder's offset (track, plus car half-width, plus 0.075, plus platform
   half-width). `PLATFORMS.edge` in the data is wrong by 0.475 m. Correcting
   it moves the station escalators, so it will be fixed in a later plan pass.
   Until then, your offset wins.
2. **Generated files.** `scripts/city_plan.gd` is generated. Never edit it by
   hand. If regenerating on your machine gives different rounding, say so in
   the diagnostic.
3. **Still owed from pass 3:**
   - the rendered performance probe;
   - a physical walk and ride of every escalator, ramp and lift end, by both
     characters;
   - all four clock faces at 3:00, 9:15 and 12:00.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`.
2. This document.
3. `city.md` 8a.1 (Civic Plaza, the grand square), 8b.1 (City Hall's city
   front) and 7a (the city's clock and the Clock Room).
4. `docs/drawings/moy_city_3d.html`. New places to visit: *Civic Plaza*,
   *City Hall's city front*, *On Civic Plaza*, *The city's clock*, *The Clock
   Room*, *In a clock's eye*.

## 2. What changes

1. **Civic Plaza is one grand square.** Remove the two blocks of shops and
   offices (buildings 54 to 56), Meridian Walk, Hotel Passage, and the civic
   walks on the Deck. Build the square from `CityPlan.CIVIC_SQUARE`:
   - paving over its `rect`;
   - the reflecting pool (`mirror`; hazard policy, water surface API);
   - two lawns split by the paved cross-axis, with a fountain on each;
   - the tree rows along the north and south edges (kit trees; trunks solid);
   - the statues on the lawns and the two monuments, as plinths with simple
     massing for now (subjects are open);
   - the flagstaffs.
   The Grand Hotel's skybridge now runs west to the Park Deck
   (`DECK['runs']`, *Hotel skybridge*).
2. **City Hall's city front replaces the cascades.** `ARCH['cores']` is empty.
   Build `ARCH['front']`:
   - the **Rostrum** at the hall's level, with its bay and portals;
   - the **City Steps**, two flights, each with a stair between an up and a
     down escalator, and a half-landing;
   - the **scissor escalators** up each leg. Each flight lies in the band
     its data names (A or B). Consecutive flights alternate bands, so no
     flight runs into the next;
   - the galleries at each platform level, which lead to the platforms'
     west ends;
   - the over-track walk, the outer pair, and the lifts at their stops.
3. **Every escalator has moving handrails** (`ESCALATORS['handrail']`): a
   rubber handrail on a glass balustrade on both sides of every lane, straight
   and spiral, moving at the treads' speed in the lane's direction, with a
   newel at each end. The handrail is decorative; the balustrade is solid.
4. **Nothing structural enters a helix's band.** On the Crossing's double
   helices, the train's support crossbeams cut the riders' headroom. The
   Spine's head beams must end at the drum's ring girder, outside the band.
   Keep at least 1.6 m (checked in `tools/city_layout.py`) between any beam and the
   band. Check it in the validator: no collider other than the hand itself
   may enter the band's volume up to 2.6 m above the treads.

5. **City Hall's landings, guards and lifts.**
   - **New landings.** Build the new landings `L37o`, `L37i` and `L43`, and
     each leg's `outer_landing`.
   - **Guards.** Build every run in `ARCH['front_guard']['runs']`: 1.1 m
     glass on a bronze shoe, with a bronze rail. Each guard is solid
     (collision); its top rail is decorative.
   - **Lifts.** Move the front lifts to their new places, in front of each
     leg and flanking the gate. Drop their +21.8 stop. Move the outer lifts
     onto the walk over the tracks.
   - **Check:** walk every landing's edge with both characters. You must not
     be able to fall except where a flight, a stair, a lift or a platform
     meets the edge.
6. **The clock dome (rebuild it).** Data: `CROSSING.dome`.
   - **Remove** the drum's posts and the steel ring beam.
   - **Build one glass shell**, drum and cupola together. Put a triangulated
     grid of slender white members on it (`lattice`: 72 panes round, rows
     every 2.2 m up the shell, 7 cm members), meeting a crown ring at
     3 m radius. The drawing's code builds it. The glass and the grid are
     solid; the grid has no separate collider.
   - **The eyes.** Cut each clock's hollow centre out of the glass
     (`clocks.eye`), line it with the bronze sleeve, and lay the sill. Leave
     each eye open: no glass, no guard, no collider across it. A glider or
     flier must be able to pass through.
   - **Hang the bell** from the crown ring.
7. **The Clock Room.** Data: `CROSSING.dome.room`.
   - **The helices end at +37.** They do not continue into the dome.
   - **The floor:** terrazzo at the roof's top, with the compass rose under
     the bell.
   - **The arrivals.** Build the `widenings` on the high-line platforms.
     Build the four `arrivals` as escalator pairs from 37 to 41.6. Cut their
     `well`s in the floor, and guard each well on three sides, open at the
     head.
   - **The lifts.** Run the four tower lifts on to 41.6, each with a glass
     lantern whose door faces the bell (`lifts`, `door`). Add the stop to
     their destination menus.
   - **No way up to the eyes.** There are no escalators or landings to the
     eyes (revised 2026-10-18): an eye is reached only by flying or gliding,
     onto its sill.
   - **Check:** ride every way in and out, with both characters:
     - each arrival, both ways;
     - each lift to the room and back;
     - out through an eye with the Leaf Hat, and back in.
8. **The garden towers' ways out.** The third pass's hoops and ribs block
   them.
   - Rebuild each tower's rib cage with **eight** ribs at 22.5° + 45k.
   - Put hoops only at each tower's `hoops` heights: never from a level's
     floor to 2.8 m over it.
   - Check every `ways_out` entry: walk out of each tower at each level, and
     onto the ring and the bridges, with both characters. No rib or hoop is
     in the way, and none collides inside the clear width and height.
9. **The escalators are closed boxes** (`ESCALATORS.section`). In the third
   pass the helices' undersides were invisible and had no collision from
   below. Every flight, straight and spiral:
   - **Top:** the moving treads, unchanged.
   - **Return belt:** inside the box, hidden.
   - **Skirts:** solid side skirts.
   - **Soffit:** a hard brushed-stainless soffit closing it underneath, its
     faces outward.
   - **Collision:** the top and the soffit both solid, as closed convex
     pieces per segment.
   - **Check:** stand under each helix and each straight flight and look up.
     Jump up into its underside: it is solid.
10. **The Grand Hotel stays as built.** The city model draws it as massing
    only, and points to the detailed model, `docs/drawings/moy_grand_hotel_3d.html`.
    Its data is `CityPlan.HOTEL`, which both models read. Keep building the
    hotel from `HOTEL` and the detailed model, as in pass 3; nothing about it
    changes in this pass.

11. **The reed pond is real water** (`PARK.pond`).
    - **The fault.** In the third pass its water stood 0.4 m above the park's
      ground (`MOY_POND_SURFACE` −59.6 over a datum of −60), on a bespoke,
      nearly opaque shader (`moy_pond_water.gdshader`, alpha 0.88), so it
      hovered over its banks and could not be seen into.
    - **The water's surface** is `surface` (0.3 m) below the park's ground.
    - **The bank** shelves down from the ground at `bank_top` (× r) to the
      waterline at r.
    - **The bed** follows `bed`, a reed shelf round the edge and 2.1 m below the ground at
      the middle. Set `terrain_generator.gd`'s `MOY_POND_SURFACE` and
      `_moy_pond_bed` from these values. The paving and lawn stop at the bank's
      top.
    - **The water** is the world's one water, as every village pond is:
      - `VillageWorks.water_material()` on a flat disc at the surface;
      - marked with `CollisionPolicy.mark_hazard`;
      - meta `water_surface_y` and `water_depth`.
      Delete the bespoke shader. The liquid queries (`is_water_area`,
      `get_water_surface_height`, `get_water_floor_height`) read the same
      surface and bed.
    - **Check:**
      - stand on the bank and look in: the water is translucent, below the
        ground;
      - wade in from the shelf and swim at the middle with both characters;
      - from underwater, look up through the surface.

## 3. Checks

- The building count drops from 50 to 47 (buildings 54 to 56 are gone).
  Update `check_moy_bake.py` and the validators, then rebake.

- `python3 tools/city_layout.py` passes (it checks the square, the front's
  bands, its headroom and the beams' clearance).
- Ride every flight of the front from the forecourt to the sky garden and
  back, both legs. Then do the same on each helix and look up the whole way.
- Walk from the square to each platform by the steps and the scissors, and
  again by the lifts.

## 4. Review of the build, and fixes (2026-10-18)

Reviewed: `03a9d7a`, diagnostic `docs/diagnostics/2026-10-18-moy-prototype-pass-4.md`.
**Result: fix.** Most of the pass is good; three faults in the geometry stop it.

Good, keep it:
- the grand square, the reflecting pool, lawns, trees and flagstaffs;
- the closed helix sections, the handrails and the glass balustrades;
- the dome shell and lattice with open eyes, the bell, the Clock Room floor,
  arrivals, wells and lantern lifts;
- the eight towers' ribs at 22.5° + 45k, and hoops only at `hoops`;
- the pond on the world's water, with its liquid queries;
- the clock-angle checks, and the honest list of what was not verified.

**Fix these:**
1. **The head beams still cross the helices** (section 2, item 4).
   `CrossingSpineHeadBeam_*` and `CrossingMeridianHeadBeam_*` are 26 m long,
   so they run from tower centre to tower centre, through both drums and
   both helix bands. Build each beam as two pieces, one from each tower's
   ring girder towards the middle: each end at
   `offset − drum + 0.4` (7.4 m) from the Crossing's centre line, as
   `city_layout.py` checks. Nothing between the drums.
2. **City Hall's galleries and landings ignore their band.** Every entry in
   `leg.galleries` is built over band A at 2.8 m wide. Build each over the
   band its data names: `A`, `B`, or `AB` (both bands and the gap between).
   So G37 and G43 move to band B, and L37o, L37i and L43 span both bands.
   Put each deck's top surface at its `y` (today the box is centred on it).
3. **The band check in the validator.** Add the check item 4 asked for: no
   collider other than the helix's own section may enter a helix band
   (radius 1.4 to 4.0) up to 2.6 m above the treads. Fix 1 must make it
   pass; it must have failed on `03a9d7a`.
4. **The ways out, checked.** Add a validator check over every tower's
   `ways_out`: a 2.4 m wide, 2.8 m high clear box from the gallery out past
   the drum, with no collider in it.
5. **Delete `moy_pond_water.gdshader`** and its `.uid`. Nothing uses it.

**Settled from the diagnostic:**
- **Pond depth:** the data wins. The bed is 2.1 m below the park's ground
  and the water 0.3 m below it, so 1.8 m of water at the middle. Item 11
  now says so.
- **Generated plan drift:** regenerating with Shapely 2.x here gives the
  committed `scripts/city_plan.gd` exactly. No change.
- **Rendered performance** and the engine's RID errors go to P2.
- **The hotel's gaps** (revolving door, the Windrose, the chandelier's
  crystals) go to P13a.
- **Walking and riding by hand** is owed at milestone M1. Until P0's rig
  lands, the scripted checks above stand in for it.

**Report:** a short follow-up diagnostic,
`docs/diagnostics/<date>-moy-P1-fixes.md`: each fix, the new checks' output
(and that check 3 failed before fix 1), and the bake and validator counts.

## 5. Second review, and fixes (2026-10-18)

Reviewed: `948e1bf` (builder), `802cb65` (validator, shader), diagnostic
`docs/diagnostics/2026-10-18-moy-P1-fixes.md`. No screenshots.
**Result: fix.** The galleries and the shader are done. The head beams are
still wrong, and the new checks were never run.

Good, keep it:
- City Hall's galleries over their own bands (A, B, AB), tops at `y`;
- the gallery band check in the validator;
- `moy_pond_water.gdshader` and its `.uid` deleted;
- the honest report that the runtime validator did not finish.

**Our error first.** Section 4, fix 1 said "nothing between the drums". That
was wrong, and it contradicts the numbers in the same line. The plan
(`city_layout.py`, the head-beam check and `_beam_clear`) puts each beam's
ends at ±7.4 m from the Crossing's centre line: 0.4 m into the inner edge of
each drum (drum r 6.0 round a tower at offset 13). The beam spans *between*
the drums and carries the line there. Nothing of it is inside a drum
beyond its ring girder.

**Fix these:**
1. **The head beams.** Each of the four is one piece, 14.8 m long, from −7.4
   to +7.4 about the centre line (Spine: along x at each `_beams.spine.z`;
   high line: along z at each `_beams.high.x`). Today each half runs from
   7.4 to 13.0, into the tower's centre: through the helix band (r 1.4 to
   4.0, so 9.0 to 11.6 from the centre line), on all four towers. Fix the
   builder's comment too.
2. **The band check follows the treads.** Today it samples a box only for
   2.6 m above each *level*, so a beam between levels is never seen. Walk
   every hand's `profile` (`[a0, a1, y0, y1]`, degrees and heights) in steps
   of at most 5°. At each step, test the band (r 1.4 to 4.0) from the tread's
   height + 0.05 to + 2.6. Exempt only `CrossingHand_*`. Use slices no wider
   than 0.4 m at r = 4.0.
3. **The way-out check tests the right box.** Today the box runs from the
   tower's centre to r = 5.0. So it starts in the trunk and the helix (it
   can never pass) and stops short of the ribs (r 6.0), the thing it is for.
   Test from the band's outer edge, r 4.0, to the drum + 1.0 (r 7.0), 2.4 m
   wide, from the floor + 0.05 to + 2.8.
4. **No hard-coded results.** `MOY_PASS4_CLEARANCE` prints `collider_hits=0`
   and `MOY_CITY_HALL_GALLERIES` prints `surface_y=PASS` whatever happened.
   Print the real counts.
5. **The validator must finish.** A check that never runs proves nothing.
   If the full stream crashes (signal 11 in terrain and pack streaming), add
   a mode that loads only the Crossing's and civic core's cells and the
   collision, and run the P1 checks there. Report the crash's cause, or hand
   it to P2 with its backtrace.
6. **Show it failing, then passing.** Run checks 2 and 3 on `948e1bf`: the
   band check must fail on all four towers (the half beams). Then on the fix:
   both pass.
7. **Label commits by package.** P1's builder fixes went out under "Add P0
   Moy world-check fixes". Name the package each commit serves.

**Report:** `docs/diagnostics/<date>-moy-P1-fixes-2.md`:
- each fix;
- the checks' output before and after;
- the bake and validator counts;
- three screenshots: under the Spine's head beam from a tower's gallery,
  looking along the line; looking up the helix band past it; and City Hall's
  L37o and G37 from the forecourt.

## 6. Third review, and fixes (2026-10-18)

Reviewed: `ec3abd5` (builder, validator), `e83fc68` (bake), diagnostic
`docs/diagnostics/2026-10-18-moy-P1-fixes-2.md`. No screenshots (rightly held
back until the checks pass).
**Result: fix, small.** The head beams are right, and the checks now run and
tell the truth. What they find is centimetres of geometry, plus two
mistakes of ours.

Good, keep it:
- four single 14.8 m head beams, ends at ±7.4 (the band check's unique
  colliders fell from 312 to 304: the eight half-beams are gone);
- `--p1-only`, which finishes, and real counts in every line;
- the band check walking every hand's profile in 5° steps;
- City Hall's galleries: 14 checked, 0 failures;
- no exemptions added to make a check pass.

**What the checks found.** Planning rebuilt your collision from the baked
cells and repeated both checks. The ~304 band colliders per run are, on
each tower:
- 72 `CrossingGalleryInnerRail_*`: the rails are centred on r = 4.0, so
  half of each 0.12 m rail, and every chord's middle, stands in the band;
- 3 `CrossingGallery_*`: the 48-sided annulus has its *vertices* on r = 4.0,
  so its chords cut 9 mm into the band, and its 1.0 m depth reaches the
  headroom of the climb below;
- `Open_park` and `CrossingRainGarden_*` at the helix's foot: the lawn stands
  0.07 m and the rain garden 0.05 to 0.22 m above the ground landing (tread
  0.0), and the garden is a full disc over the tower's foot.

**Our errors (fixed in the plan, 2026-10-18).**
- **Two ways out faced the lift.** The plan put a way out at the Deck and on
  the lawn at the inner corner's bearing, where the tower's lift stands (r
  6.1 to 8.7). At the Deck that way led into the open middle; on the lawn,
  into the shaft. Now each tower has the Deck's two (the ring, outward, and
  the cross-bridge) and three on the lawn (outward, and the two sides facing
  the open middle). `city_layout.py` checks that no way out meets the lift.
- **The way-out box began on the rail.** Section 5 said to test from r = 4.0,
  the line of the gallery's inner guard, which stays closed except at a
  landing: so it could never pass. Test from r = 4.2.
- **The rain garden** is now a ring, `r_in` (the drum, 6.0) to `r` (9.5),
  with a paved path along each way out on the lawn (`paths`, `path_width`)
  and clear of the lift; no reed stands in a path. The city model draws it so.

**Fix these:**
1. **Nothing of a gallery inside r = 4.0.** Put the inner rail's inner face
   at r ≥ 4.02, chords included (vertices on r / cos(π/n)). Do the same for
   the gallery annulus's inner edge. Keep the rail open along each landing,
   as now.
2. **The ground landing is flush with the lawn** (within 0.01 m), or the
   lawn is cut round the drum. Nothing stands above the tread inside the
   drum on the lawn.
3. **Build the rain garden from the new data:** a ring from `r_in` to `r`,
   cut by a 2.4 m paved path along each bearing in `paths`, clear of the
   lift by `lift_clear`. The reeds are the data's (fewer now).
4. **Build the new ways out.** Rebake from the regenerated
   `scripts/city_plan.gd`. Leave bays open at the new bearings; the climbers
   already follow them.
5. **The way-out check runs from r = 4.2 to 7.0** (it is 4.0 today).
6. **Print the colliders by kind** in the band and way-out lines (as
   `CrossingGalleryInnerRail ×72`), so a review can read them.

Planning's rebuild of the checks on `e83fc68` with the new plan found
nothing else: no beam, rib, hoop, lift or guide in any band or way out
once fixes 1 to 3 are made.

**Report:** `docs/diagnostics/<date>-moy-P1-fixes-3.md`:
- each fix, and the P1 checks' output, all passing;
- the bake and validator counts;
- the three screenshots from section 5, and a fourth: a tower's foot on the
  lawn, from the middle, showing the garden's paths.

## 7. Fourth review, and fixes (2026-10-19)

Reviewed: the uncommitted builder and validator changes
(`scripts/moy_city_bake_builder.gd`, `tools/validate_moy_runtime.gd`), the
rebaked packs, diagnostic `docs/diagnostics/2026-10-19-moy-P1-fixes-3.md`, and
two of its four shots (the helix band and the tower foot). Planning also ran
the P0 suite on the Crossing (`--area=-600,-40,-520,40`, 27 s) and compared it
with the pre-fix audit `checks/moy-2026-10-19.*` over the same box.
**Result: fix, small.** Section 6's fixes 1 to 6 are built and the P1 checks
pass. The build chat marked P1 *done* in the roadmap; that call is planning's,
and it is not yet earned: the garden mesh is wrong, and the suite still fails
on the Crossing.

Good, keep it:
- the gallery rail's inner face at r = 4.0244 on a chord's middle, the annulus
  at 4.02 / cos(π/48), bays open at the new ways out;
- the lawn cut round each drum, the rain garden as a ring with a path along
  each bearing and clear of the lift, the reeds from the data;
- the way-out box from r = 4.2 to 7.0, and collider kinds in the lines;
- the checks shown failing (30 failures before) and then passing (0), on the
  same plan, with nothing exempted;
- `check_moy_bake.py` passes (198 packs).

**What the review found.**
- **The rain garden mesh is wrong.** `_crossing_rain_garden` emits four quads
  per cell on a 0.25 m by 1° grid (5,040 cells a garden): the top, a bottom,
  and a wall at both the inner and outer radius of every cell. It never emits
  the walls at a cell's angular ends.
  - Beside each path the bed is open: the shot shows the 14 concentric inner
    walls as dark fins down each cut edge.
  - Every interior radius carries two coincident, opposed walls that can
    never be seen.
  - The bottom lies on the terrain. The suite reads its back face as a walk
    cell flush with terrain: 12 new blocking `overlap` findings (the four
    gardens), where the old discs gave 8 against the helix hands.
  - Size: `cell_03_03_p14.tscn` went from 2.7 MB to 18.6 MB, and the Moy bake
    from 69.7 MB to 88.0 MB. A ring bed of this size needs a few hundred
    triangles.
- **The suite fails on the Crossing, and the diagnostic does not run it.**
  The roadmap says a package is not done until it passes. Over this box, 152
  blocking `overlap`, 8 blocking `headroom` and 151 blocking `underside`
  findings. All but the garden's 12 `overlap` findings were there before
  this build, so the fix list below holds P1 to what it owns, not to the
  whole baseline.
  - `underside`: 95 `HelixMovingTread`, 56 anonymous meshes. This is P0's
    open follow-up (section 11 of `moy_pkg_P0.md`), inside P1's helices.
  - `headroom`: one per hand, 8 in all, at r = 3.02 on the ground inside the
    drum, under the first turn (tower 00 up hand at bearing 114°, y −60.0),
    blocking because the hand carries the `flight` meta. The band check
    exempts `CrossingHand_*` and tests only above the tread, so it cannot
    see this. It is the walk-under a stair makes, with 2.2 to 2.4 m of
    clearance. Plan data gives the headroom as 2.64.
  - `overlap`: the roof, the lift landings and the meridian bridges are the
    old findings, P7's and P1's earlier work; not new.
- **The shot cannot show fix 2.** Rendered from the focused pack scenes, the
  tower-foot shot has no terrain and no lawn: only the garden and its paths
  stand on a flat background.
- **Constants and labels.**
  - The rail radius 4.1, the way-out bay's `4.0` in `_crossing_way_out_open`,
    the lawn height DATUM + 0.04 (the whole park's lawn drops from +0.07) and
    the 4.02 clearance are literals in the builder, not plan data.
  - `MOY_P1_WAYS_OUT` prints `r=4.2..7.0 width=2.4 height=2.8` as a literal;
    the box it tests is `way.width` by `way.clear` (floor + 0.05 to + 2.85).

**Fix these, in order:**
1. **Rebuild the rain garden.** For each run of the ring between two paths,
   one wedge: top, inner wall, outer wall and the two end walls; two radial
   vertices; no bottom face. Collision as boxes or convex pieces along the arc
   (CLAUDE.md prefers them to a mesh), not a copy of the visual. Hold
   `cell_03_03_p14.tscn` to its old size plus a few hundred KB, and say the
   new triangle count in the report.
2. **The P0 suite on the Crossing, with P1 held to what it owns.** Run it on
   the area above and the civic core (`--area` per package, as P0 allows).
   - No new blocking finding against `checks/moy-2026-10-19.*`: the garden's
     12 go with fix 1.
   - The 8 `headroom` findings under each hand's first turn: either a guard
     or planter keeps people out of the low zone (the plan's walk-under), or
     the check tags it as an accepted stair underside with a reason in the
     plan data. Decide with planning; do not exempt by name.
   - `underside` on the helices is P0's fix 2 (section 11 of `moy_pkg_P0.md`).
     P1 is *done* when that triage says whether the treads are visuals or
     real faults.
3. **Plan data, not literals.** Put the gallery rail radius, the 4.02
   clearance, the lawn's height and the bay half-angle margin in
   `PLAN.CROSSING` (checked in `city_layout.py`), and read them in the
   builder and the validator. The bay uses the rail's radius, not 4.0.
4. **The way-out line prints the box it tested** (`shape.size` and the
   origin's height), and the box runs from floor + 0.05 to + 2.8 as section 5
   says.
5. **The shot shows the ground.** Render the tower foot, and the lawn round a
   drum, with the park pack and the terrain in the scene (or from the full
   world). Show the garden from the side of a path cut.
6. **Commit by package.** The P1 builder, validator and bake go in one commit
   named for P1; the P0.1 tools in another; `build/web` is not touched (the
   web build is deprecated, `CLAUDE.md`). The roadmap's P1 row is set by
   planning.

**Report:** `docs/diagnostics/<date>-moy-P1-fixes-4.md`:
- each fix, with the garden's triangle count and the bake sizes before and
  after;
- the suite's output on the Crossing and civic core, as a delta against
  `checks/moy-2026-10-19.*`, and every P1-owned finding triaged;
- the P1 validator's output;
- the tower-foot shot with the ground in it, and one along a path's cut edge.

**Decisions:**
- 2026-10-19: P1 stays *fix*. The build's own *done* is reverted.
- 2026-10-19: P1's gate is "no new blocking suite findings and every
  finding on its own elements triaged", not the whole city's baseline.
