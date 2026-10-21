# Package P3: the market lanes kit

2026-10-18 (revised the same day after a data review). Build-session brief.
Read `moy_build_roadmap.md` first.

- **Area:** the market lanes, south of Clinic Lane and west of South Street,
  as `market_lane()` in `tools/city_layout.py` defines them.
- **Target level:** L2, built.
- **Depends on:** P0 (the check suite) for its acceptance. It can be built
  before P0 lands, but it is not *done* until the suite passes on its area.
- **Model:** `docs/drawings/moy_market_lanes_3d.html` (published:
  https://claude.ai/artifact/B4d92cjYsy6TMBUCar7gRT). The lanes from the
  data, and a kit sheet of the six kinds of house beside the hero. Match it.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`, `moy_build_roadmap.md`.
2. `docs/architecture/moy_market_lanes.md`: the kit's design. Sections 3 and
   4 describe each piece; where its numbers and the data differ, the data
   wins.
3. The market lanes charter in `docs/style_charters.md`.
4. The plan data. **The data wins** over every document:
   - `CityPlan.MARKET_HOUSE`: the kit's numbers, in metres.
   - `CityPlan.LOT_KITS`: one entry per lot (`null` outside Old Moy and the
     market lanes). Market-lane houses carry `gen`, `veranda`, `corner`,
     `colour` (index into `MARKET_HOUSE.palette`), `signs`, `blade`, `roof`,
     `core` (`own`, `shared` or `lift`), `pair`, `lift` and `door` (the
     door's world x, z on the front; `null` for a lock-up).
   - `CityPlan.BUILDING_KITS[34]` (the market flats) and `[38]` (the
     Helmsmith).
   - `CityPlan.ARCADE_ROOF`, `CityPlan.LAMP_LANE`, `CityPlan.COURT_WAYS`.
5. The model (above).

## 2. What to build

Today every lot is a plain block (L1). Replace each market-lane lot's block
with its kit house, from its `LOT_KITS` entry. Build no house by hand.

**80 houses:** 15 boom houses (5 with a veranda), 55 tile houses (9 on
corners), 10 lock-ups; and the Helmsmith's shop (section 2a). 22 pairs share a door and a core; 11 houses have a
lift for a core; 15 have a core of their own.

**The kit is exterior only.** These houses are not entered.
- No core, ramp or flat is built inside.
- The door is a closed door with a lit fanlight, at `door`.
- The shopfront fills the rest of the ground floor's front, glazed or
  shuttered, with a `shop.depth`-deep dressed shop window behind the glass:
  shelves and goods by the trade, at L2 in plain shapes.
- Collision is the house's outer volume. Its parkour features (below) stand
  proud of it.

**Each piece, from the data:**
- **Boom house** (`gen: boom`, 4 or 5 storeys):
  - rendered front in palette colour `colour`, on a `plinth` of grey tile;
  - `parapet`; French windows (`boom.window`) with timber shutters;
  - **if `veranda`:** square columns (`boom.veranda.col`), `out` from the
    front, carrying a covered walkway at the ground and an open veranda
    with a timber balustrade on every floor above;
  - **otherwise:** a shallow balcony (`boom.balcony`) each floor.
- **Tile house** (`gen: tile`, 6 to 9 storeys):
  - mosaic-tile front in palette colour `colour`, a grey-tile plinth;
  - the shopfront canopy (`tile.canopy`);
  - cantilevered balconies with steel rails (`tile.balcony`) from the
    second storey (`first`): the canopy stands in for the first's; steel
    windows (`tile.window`);
  - **if `corner`:** the corner where the front meets the second street is
    rounded the full height (superellipse, `tile.corner_exp`), with curved
    balconies wrapping it.
- **`lift`:** a glass lift shaft (`tile.lift`) on the back face.
- **The door and the core:**
  - `core: shared`: the pair's **one** house door straddles their party
    wall at the front (both lots carry the same `door`), between their two
    shopfronts;
  - `core: own`: the door at one end of the front, beside the shop;
  - `core: lift`: the same, with the lift shaft behind; these houses are too
    shallow for a ramp core.
  Doors only: nothing is built behind them.
- **Lock-up** (`kit: lockup`): two storeys, a roll shutter across the whole
  front, a small window above.
- **Roof** (`roof`): water tanks, laundry frames, a rooftop greenhouse or a
  garden, as the model shows.
- **Signs:** `signs` stacked picture signs on the front from `sign.y`, never
  lettered. **`blade`:** one more sign hung out `sign.out` over the lane,
  clear above the canopy (the plan checks it).
- **The market flats** (`BUILDING_KITS[34]`): four tile houses built as one
  terrace, rounded at the corner, with laundry on the shared roof.

## 2a. The Helmsmith's shop (revised 2026-10-18, at the user's direction)

The live game still has the Helmsmith's old shop standing in the middle of
Civic Plaza (`_add_moy_helmsmith()` in `scripts/city_generator.gd`, at world
(−470, −18)): a walk-in room with wide entrances, a counter, and the real
helms from `ShopCatalog` on a back-wall display, in teal, coral and gold
(`_build_helmsmith_storefront()` and `_build_helmsmith_room()`). It was kept
there as a stopgap when the city was replaced. Its real home is building 38,
on Lamp Lane's south side (`CityPlan.BUILDINGS` 38, x −600 to −590, z 174 to
186; `CityPlan.BUILDING_KITS[38]`, `kit: shop`).

**It stays a proper shop, not a lock-up.** The earlier brief made it a
shutter with a counter across the open front, a stall served from the lane.
That was a downgrade. Build it as a shop you walk into:
- **The house:** two storeys facing north onto Lamp Lane, in the lanes'
  render (`colour`), with a parapet.
- **The shopfront:** a glazed front the full width, with the wide open
  entrance (`shop_floor.entrance`) in the middle; one picture sign of a
  helm above it (no lettering); warm light spilling out at dusk.
- **The shop floor** (`shop_floor`: `h` high, `depth` deep, the house's full
  width) is **entered**, built at L2:
  - the counter across the room, Gideon behind it, facing the entrance;
  - his helms on the back wall's display, the catalogue's own models, as
    the old shop shows them (`ShopCatalog.get_items_for_shop("city")` and
    each item's `build_visual`); more on stands either side of the room;
  - the old shop's teal, coral and gold, carried over;
  - lit inside;
  - collision as built; the entrance has no threshold.
- **The workshop** behind (the rest of the depth): a doorway behind the
  counter shows his bench, a grinder and helms half made. Seen, not entered.
- **His home** upstairs: windows, not entered.
- **Move the vendor:** the same NPC, with the same name, looks,
  `shop_category` `"city"` and stock, behind the counter on tested ground.
  Keep him stationary.
- **Remove the old shop from Civic Plaza** and its storefront node
  (`MoyHelmsmithShop`), and update `_remove_moy_actors()` to match. Nothing
  of the shop is left on the plaza.
- **Reuse** the old shop's room and display code (moved into a shared place
  the bake or the city generator both can call) rather than writing a third.
- **Check:** walk in from Lamp Lane with both characters; the shop UI opens
  at the counter; the plaza is clear; `reach` finds the counter.
- **His lines.** His second line ("A core takes one head-shape at a time…")
  explains a mechanic, which the in-game text rule forbids. Replace it with
  an in-character remark that explains nothing, and flag the change in the
  diagnostic.
- P13k finishes the shop (dressing, lighting, the workshop) to L3 later.

**The streets they make:**
- **Arcade Street's roof** (`ARCADE_ROOF`): steel arches at each `arches`
  z, springing from posts at the street's edges and rising to `h`, carrying
  translucent panels over the street's full width, from Market Street to
  clear of the Rim Walk. It is short here (about 19 m), between the vertical
  farm and two tile houses. The arches are parkour landings; the panels are
  solid.
- **Lamp Lane** (`LAMP_LANE`):
  - a lantern string across the lane at each `lanterns` x, at `lantern_y`,
    house to house (decorative; lit at dusk);
  - the night market's `stalls` (`stall` size), one side at a time and
    never in front of a door. The game has no night-market schedule yet:
    build them as static props, open (awnings out, goods out) from dusk to
    midnight by the game clock if that is simple, otherwise always open.
- **The courts** (`COURT_WAYS`): the ground each block really leaves open.
  - A court with `passage`: a covered passage `w` by `h` through that lot's
    ground floor, from `court_end` to `road_end`, with an arched opening at
    each end and a lamp inside. Cut it through the house's collision.
  - `open`: the court meets its street directly; leave that side open.
  - Pave each court; a bench, pots and a washing line (L2 plain shapes).
  - In the market lanes: the court behind the market flats (by a passage
    through `LOTS[34]`) and the large court east of the museum (through
    `LOTS[71]`).
    The others are P4's, P6's or a landmark's (`within`).

**Construction.**
- Build every piece from the schedule (section 2b), with the game's own
  SuperEgg code.
- Share meshes and materials between houses, and merge static pieces per bake
  cell by material (as the bake builder already does).
- Bake everything into the Moy bake (`moy_city_bake_builder.gd`), with the
  kit's sources in the bake signature.

**Collision** (section 3.7):
- **Solid:** houses, verandas' columns and floors, balconies, canopies,
  parapets, roofs, the arcade's arches.
- **Parkour landings (`CollisionPolicy`):** veranda floors, balconies,
  canopies, parapets, roofs, arches.
- **Decorative:** sign faces (their frames are solid), lantern strings,
  plants and laundry.

## 2b. Parts and joins (binding)

**Build every piece from the schedule:** `CityPlan.MARKET_HOUSE.parts` (66
parts) and `.joins` (15 joins). It covers the boom house, the tile house, the
lock-up, the Helmsmith's shop, the arcade roof, Lamp Lane's lanterns and
stalls, and the courts. The model's kit sheet draws it piece for piece, and
its tables list it. Nothing is left to choose. If a piece seems missing or
wrong, say so in the diagnostic; do not invent one. The vocabulary is the
tower house's (`moy_pkg_P4.md` 2.7), with one more shape.

- **Shapes:**
  - `egg`: `SuperEgg.build_part(semi, colour, eps[0], eps[1])`;
  - `clipped`: `SuperEgg.build_clipped_part(semi, planes, colour, eps…)`,
    cut by the planes its join names, every cut capped;
  - `profile`: a superellipse outline of exponent `n`, extruded (the
    plinth; the curved balcony round a rounded corner);
  - `wall`: a `SolidModel` solid of the outline, its openings punched;
  - `punched`: a `SolidModel` cutter through its wall. The glass is the
    cutter intersected with the wall; a ring is the cutter grown by `ring`,
    less the cutter;
  - `arch`: a half superellipse of exponent `n` across Arcade Street, swept
    with its `section` (the steel arch; the panels between them);
  - `box`: only the roof slab, for its stated reason;
  - `decal`: painted, not geometry (sign pictures, rail bars, laundry).
- **Sizes:** `semi` is half-sizes across the face, up, and out from it;
  `fit` means the house sets it. A seated part's centre is on its seat, its
  upper half kept; a part against a wall is centred on the wall face, its
  outer half kept; a hung part (the blade sign) is centred on the underside
  of its bracket, its lower half kept.
- **Leaves and their openings:**
  - **floor cut** (`floor_cut`), as `scripts/world_door.gd` builds a door:
    the house door is **one leaf on one hinge**, on the side away from the
    shop. A pair's one door straddles their party wall, and is built once.
    The French windows' leaves and shutters and the roll shutters are cut
    the same way at their floor. The houses stay shut: build the leaves
    static, without the door's interaction or its lock message.
  - **split** (`french_set`, `shutter_pair`): a French window's two glazed
    leaves are cut from one parent egg; so are its two timber shutters.
    Shut, the shutters are the window's own outline. Open by day, each lies
    flat on the wall beside it, so a window needs 2 m of front.
  - **The frame is the leaf's shape** (`outline`, `clear`): the doorway,
    the French window, the shopfront and the lock-up's front are each cut
    from the silhouette of what closes it, grown by `clear`, on the same
    spot and flat at the same floor. The door's grey-tile frame is that
    outline grown again by its `ring`. The fanlight is its own opening
    above the frame.
  - Openings reached from the floor without a leaf (the passages, the
    Helmsmith's entrance and workshop door: `floor`) are flat at the floor.
- **Joins of the fronts:**
  - **party cut** (`party_cut`): the canopy and the veranda floors run
    past both party walls and are cut at them, so neighbours' canopies and
    walkways meet flush.
  - **balcony ends** (`balcony_ends`): every balcony is cut square at both
    ends and capped, so its rail posts stand on its corners.
  - **corner wrap** (`corner_wrap`): on a rounded corner, the straight
    balcony is cut where the curve begins, and the curved balcony (the
    corner's own superellipse, grown by the balcony's depth) runs on at the
    same height, depth and thickness. Its rail follows it, each run cut at
    the bisector it shares with the next.
  - **rail bays** (`rail_bays`): each handrail and top bar is cut at the
    faces of the columns or posts that carry it.
  - **column ends** (`col_ends`): columns, balusters, rail posts, the
    arcade's posts, the stalls' posts and the lift shaft are cut flat at
    both ends, standing on their floor and stopping under what they carry.
  - **seated, hung, against the wall** as in P4: nothing is buried whole,
    nothing sunk into a wall.
  - **arcade bays** (`arcade_bays`): each panel spans from one arch's
    middle plane to the next and is cut at both; each arch springs flush
    from its posts' tops.
  - **On the surface** (`on_surface`): openings, signs and shutter boxes
    stand only on a flat run of a face. The rounded corner carries only the
    balconies, the coping and the plinth.
- **The test**, as the architecture skill sets it: look at every join from
  both sides. A gap, a step, a double thickness or a mismatched profile
  fails, however small.

## 3. Checks

1. **The plan validator** passes: `tools/validate_city_plan.gd`, with its kit
   checks (each house's generation fits its storeys; only boom houses have
   verandas; no house under 6 m has a core of its own; a `lift` core has a
   lift; core pairs are mutual; lock-ups are two storeys), and
   `python3 tools/city_layout.py` reports no problem (it checks the doors,
   the pairs' fronts, the courts' ways in, the arcade roof and Lamp Lane).
2. **The check suite** (P0) on the area's bounds passes:
   - `overlap`, `buried`, `trap`, `underside`, `solid` and `guard`;
   - `reach`: every street door is reachable at its threshold, every veranda
     from the street, every passage end;
   - `trap`: no court you can get into and not out of.
   If P0 is not yet built, say so and list what you checked by hand instead.
3. **Parkour**, with both characters:
   - climb a boom house's veranda columns floor to floor;
   - balcony rail to rail up a tile house;
   - a blorb bounce onto a canopy;
   - along the arcade roof from a tile house's balcony;
   - swing on a blade sign or a lantern string across a lane;
   - into each market court by its passage, and out again.
4. **Performance:** report draw calls, triangles and frame time from the
   performance probe, at the viewpoints below, before and after.

## 4. Viewpoints

From `docs/drawings/moy_city_3d.html`'s places (the P3 model has the same
views and more):
- `market` (overview);
- `southst` (South Street at eye height);
- `arcade` (under Arcade Street's roof);
- `lamplane` (Lamp Lane at dusk).

Each at noon and dusk.

## 5. Report

Write `docs/diagnostics/<date>-moy-P3.md` with:
- what was built;
- the check results;
- the parkour runs;
- performance before and after;
- the screenshots;
- every place the data and this brief disagreed;
- the schedule as built: each part and join, and where the build departs
  from it.

## First build review — 2026-10-19: fix

Reviewed the P3 implementation inside `fdbc8f8` (the commit titled P4),
including `_market_house`, `_add_market_streets` and the live Lamp Lane
Helmsmith. No separate P3 diagnostic, area audit, required viewpoint set or
66-part/15-join as-built table is present on main. **P3 is not accepted at L2.**

Keep the market owner coverage and the Helmsmith's move to building 38;
do not replace this with another massing pass. The following work is required:

1. Implement the binding 66-part/15-join schedule and the P3 reference model.
   The current whole-house blockers, box balconies/rails, rectangular facade
   overlays and straight arcade ribs are proxies, not the specified kit.
   Build the boom/tile/lock-up distinctions, fitted openings/trim, gallery
   details, shop bays, roof variants, arcade arch profiles and Lamp Lane from
   the authored parts. Preserve exact footprints, heights, paired cores and
   the real Helmsmith shop/service; no lettering or printed numerals in-world.
2. Fix market passages as actual clear geometry. In `_market_house`,
   passage lots split the ground wall, then a full-footprint 0.6 m plinth
   fills the bottom of that opening. Cut the foundation/plinth consistently;
   prove threshold level, width and headroom with actual controller sweeps.
   Do not fix this by tagging the shell as a way out or disabling collision.
3. Prove all court approaches and the walk-in Helmsmith: no blocking shell or
   duplicate vendor, catalog models/service retained, entry/exit from Lamp Lane,
   and appropriate room/upper-house/parapet form. Preserve closed private
   homes; public shop bays and passages must genuinely be open.
4. Complete the P3 diagnostic: every scheduled part and join, noon/dusk
   market/South Street/arcade/Lamp Lane views, isolated join close-ups,
   package-area P0 findings against a matching pre-build baseline, and each
   required parkour route with the real hero and Xiao Hou Zi. Coverage counts
   alone do not validate forms or traversability.
5. Resolve the current pending-pack unload failure shared by this combined
   submission before calling either package complete. The final P4 probe has
   zero active packs but 34 then 36 tracked requests after both unload waits.
   Diagnose and drain the actual requests safely; do not raise timeouts or
   hide the failure. Recheck two cycles and actor/vendor uniqueness.
6. Record comparable rendered before/after samples for P3's own area.
   City-wide performance targets and optimization remain deferred; loading
   correctness, unsafe support loss and new blocking geometry remain blockers.

**Shared geometry priority:** P4's first-review item 0 records confirmed
roof/wall winding faults. Correct shared polygon/floor helpers before final
P3/P4 baking and traversal proof; this does not waive either kit schedule.

**Next build order:** finish P3 properly first (P4's pencil infill shares its
tile-house grammar), then finish P4 from its first-review section. Keep
separate commits/diagnostics and do not redesign the locked layout.
Write `docs/diagnostics/<date>-moy-P3-fixes.md`; stop if a shared blocker
prevents useful P4 progress, otherwise continue to P4 sequentially.

## Second build review — 2026-10-20: fix

Reviewed `../diagnostics/2026-10-20-moy-P3-fixes.md`, all eight supplied
noon/dusk images and their manifest, the final area JSON and rendered probe,
and the current builder/shop code. **Result: fix; not accepted at L2.**
The diagnostic honestly identifies a proxy pass; listing the schedule's IDs
is not an as-built ledger or completion of the 66 parts and 15 joins.

**Progress credited.** The reviewer reran `check_moy_bake.py`: 248 current
packs. `validate_moy_passages.tscn` exited 0: lots 34 and 71 each clear a
0.4 m radius / 1.8 m capsule both ways (four fractions 1.0). This closes the
isolated plinth-obstruction regression, not the approaches in the loaded
city or either playable controller's route. The shared winding fixture also
exited 0. Both final district probe JSONs report
`cycles_complete_and_settled: true`; close the earlier 34/36-request symptom
for those sampled unload cycles. Actor uniqueness, rapid re-entry and
occupied support safety remain unproved. Do not repeat the deferred full
P2 optimization loop to finish this kit.

**Remaining fix list (build P3 before P4):**

1. Complete the existing 66-part/15-join schedule, including the market
   flats, boom verandas and French leaves/shutters, rounded tile corners and
   balcony joins, dressed shop windows, roof variants, picture signs and
   genuine arcade arches/panels. Report each part and join with its builder
   function and status; include close views from both sides of each join.
   Preserve the locked layout and private solid homes.
2. Prove both court approaches and every section 3 parkour route with the
   actual hero and Xiao Hou Zi: movement, supports and anchors, not camera
   teleportation or the isolated capsule fixture. Test the Helmsmith from
   Lamp Lane through entry, counter service UI and exit; confirm his stock,
   counter reach, one vendor after reload, clear former plaza, and dusk light.
   Keep the shared room/display code and the revised atmospheric second line.
3. Attribute the area failures by check/location/both owners and compare
   matched settings. The supplied audit has 1,230 findings, including 83
   reach and 221 trap findings; do not assign its 98.50% trapped-cell rate
   entirely to P3 without attribution. There are concrete kit intersections:
   overlap between `MarketHouse_049` and `_050` at (-600, -40.30, 188.88),
   plus other market-house overlap findings. Resolve package-owned blocking
   geometry and explain inherited debt individually.
4. Recapture useful acceptance views after the kit is built. `arcade` shows
   posts and nearby blank walls, without a readable roof/arch run; `southst`
   is dominated by transport structure; `lamplane` does not demonstrate the
   entered shop. Keep district context but add clear kit, roof and shop
   views. Ensure visible packs around the subject are loaded, record poses
   and loaded-state evidence, and retain the named noon/dusk set.
5. Supply a new fixes diagnostic with the as-built ledger, real movement
   routes, join close-ups and final area checks. The partial rendered P2
   sample passes its stationary p95 budget but has `acceptance_passed: false`
   and no controlled-route proof; it supports observations, not acceptance.

**Verification limits.** Fresh fixture runs used an explicit `/tmp` log
path because default user-log access crashed Godot in this sandbox. They
returned 0 but emitted Dummy-renderer/resource-cleanup errors. The winding
validator calls `BUILDER.build_packs()`; its twelve representatives are
rebuilt source geometry, not independently loaded committed `.tscn` packs.
Freshness and supplied rendered roofs support the correction; final baked
support/collision and loaded-city controller proof are still required.

## Third build review — 2026-10-20: fix

Reviewed `../diagnostics/2026-10-20-moy-P3-second-review.md`, all twelve
noon/dusk captures and their manifest, the changed builder, unchanged plan
schedule and new rendered probe. **Result: fix; not accepted at L2.**
The submission is incremental work, not completion of the second-review list.

**Progress credited.** The ordinary plinth now stays within the parcel, and
curved ribs/panels replace the straight arcade roof proxies. Fresh reviewer
checks: `check_moy_bake.py` passes (248 packs), `validate_city_plan.tscn`
exits 0 with 0 failures, and `git diff --check` passes. The plan run emits a
system-certificate error and an ObjectDB cleanup warning. No new successful
P0 overlap result exists: the builder's attempted focused rerun crashed.
Therefore the plinth change is credited as a source correction, not closure
of the MarketHouse_049/_050 audited intersection. The new probe's recorded
source hashes match the current files and its unload cycles settle.

**New concrete fixes, in addition to the second review:**

1. **Make the arcade one fitted vault.** `_market_arch_mesh` samples
   `x = mid + half_width * sign(cos(theta)) * abs(cos(theta))^(2/n)`;
   `_market_arch_panel_mesh` instead uses linear x and
   `y = base + rise * sin(PI*x_fraction)^(2/n)`. These are different curves.
   At rib path vertex 8 of 32, x fraction 0.920448, the current 8 m rise
   gives a rib centreline 2.764 m above the interpolated panel surface.
   The thick turquoise silhouette in `arcade` is not a fitted rib/panel
   assembly. Derive both meshes from one profile and shared station samples;
   use the scheduled exponent 2.5, not hard-coded 4.0. Close the panel's
   longitudinal bay ends: its current faces omit the z-end caps and instead
   add internal x-strip end faces. Fit and cap the post/spring joins, verify
   winding/collision on the saved arcade pack, and show both sides of joins.
2. **Put each window grammar on its correct generation.** The new French
   leaves/timber shutters are inside `if tile`. Tile houses require steel
   windows; French windows and their split leaves/shutters belong to boom
   houses. Restore that distinction from `MARKET_HOUSE.parts`, including
   the scheduled cut-and-cap profiles, rather than rectangular visual overlays.
3. **Repair the evidence pipeline before another acceptance submission.**
   `arcade_close` is almost entirely a nearby wall; `helmsmith_front` is
   dominated by foreground sign/trim and does not show entry, room or counter.
   Inspect each capture and reposition until its subject is readable; record
   loaded subject/neighbour packs and add isolated joins. Recover the P0
   `_world_aabb`/RID crash on a supported renderer, then supply a fresh matched
   owner-attributed audit. Historical totals cannot establish the new result.

**Still open.** Finish all 66 parts/15 joins and their function/status ledger,
market flats and remaining variants. Run both real controllers through court
approaches, the required parkour routes and the Helmsmith's service/exit;
prove counter reach, vendor uniqueness and plaza clearance. No such runs
were supplied. Keep the remaining second-review requirements binding.

**Performance scope.** The new compatibility-renderer sample records p95
45.090–94.012 ms across P3's four views, fails its stationary budget and
repeated-stall gates, and lacks controlled routes. Record these failures;
do not claim a passing rendered budget. Full city optimization remains P2,
while occupied-support and re-entry correctness remain package blockers.

**Handoff:** finish P3's existing second-review list plus these corrections,
then P4; supply a complete as-built diagnostic rather than another ID list.

## Fourth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P3-P4-third-review-build.md`
and current builder SHA-256
`9a4327d0a5290916fab051238c84f0a2e67e8d9a35715b017e1489c71fd1531f`.
No new screenshots, controller routes or area audit were submitted.
Fresh reviewer bake check passes with 247 packs; targeted source whitespace
check passes. **Result: fix; not accepted at L2.**

Credit the source corrections: ribs/panels now consume the same 32-segment
profile at exponent 2.5, panel z-end caps were added, and steel versus French
window details now follow tile versus boom generation. Close the previous
curve-formula and generation-selection regressions at source level. Final
saved-pack join/winding/support and readable rendered evidence remain owed;
these source fixes do not complete the kit.

**Next build round:**
1. Complete the existing 66-part/15-join kit and function/status ledger,
   with one representative boom, tile and lock-up verified before replication.
   Do not spend another round only correcting the latest isolated regression.
2. Recover the verification path: stop retrying the same Dummy-renderer
   runtime/audit failure. Use the already working rendered compatibility
   backend for affected checks, or fix the actual mesh lifetime/inspection
   fault. A generic runtime validator is not a controller-route harness.
   Add actual hero/Xiao input-driven movement with support/anchor traces,
   assertions and artifacts for the brief's required routes and shop service.
3. Finish readable, self-inspected kit/join/shop captures and the current
   owner-attributed area audit. Fix owned blockers. Reuse successful bake/plan
   checks but do not substitute them for missing routes or schedule coverage.

City-wide P2 optimization remains deferred. Earlier performance JSONs predate
this source: keep them historical, not current performance evidence. Return
separate package diagnostics when a coherent milestone is complete, with
source/bake hashes and remaining failures; stop editing for review.

## Fifth build review — 2026-10-20: fix (automated loop)

Reviewed the package's `../diagnostics/2026-10-20-moy-PP3-fixes-final.md`,
its ledger, current controller/saved-pack harnesses, raw evidence and all noon
captures. Builder hash `6d736880bdf78f899e3648c89bfe5eaf75d781524faa9fedd9028afeb609545f`
and manifest hash `d6e88eaab2080b3b7629a978b9a3b601902dffba23accf1399e4650afb1891bb`
match the submission. Fresh bake freshness check passes (247 packs).
**Result: fix; no L2 acceptance.**

**Progress:** the rendered audit now runs, its package subset identifies
17 overlaps and seven disconnected market-door targets, and actual input
traces plus saved-pack inspection exist. `arcade_close` now shows a readable
repeated arch run. The per-part ledger honestly marks everything partial;
function-name mapping does not establish any scheduled part as complete.

**Prioritized next milestone (not another whole-city report round):**
1. Build and verify one complete boom-house representative from the existing
   schedule, with part-level construction and both-side joins. Then complete
   tile/lock-up representatives and replicate the kit. Do not stop after
   transcription, isolated surface tweaks or another performance sample.
2. Correct the route harness before diagnosing world geometry: LOT34 spans
   z=155..167 with front=s, so the labelled street-to-court start z=155 is
   not the street-side exterior. The current pass threshold permits stopping
   at z=165, inside the parcel. Use COURT_WAYS endpoints extended outside
   both openings, run both directions, assert continuous corridor clearance
   and actual arrival. Reset velocity, inputs and traversal state between
   teleports; wait for stable support on loaded geometry. Two physics frames
   after placing the body 0.5 m high do not establish a grounded start.
   Identify a floor contact by normal, not the last slide collision, which
   may be a wall. Run with the working rendered backend and assert active
   controller identity. Keep failure diagnostics; do not loosen tolerances.
3. Expand beyond simple z walks: LOT71, required parkour/anchors, shop UI,
   vendor reach/stock/uniqueness and entry/exit for both characters. A hero
   room-arrival record is not service proof. Diagnose Xiao's shop obstruction
   with collider/contact and room/threshold measurements after harness reset.
4. Resolve attributed overlaps and disconnected doors, and make the shop
   capture readable. Existing `helmsmith_front` still shows foreground trim.
   Keep useful arcade evidence; add required isolated joins.

**Saved-pack test limits:** its exit status ignores degenerate/downward-face
counts, only matching vertex normals cannot establish exterior orientation,
and its hard-coded local centre_y>0.5 heuristic is not a roof-plane test.
Assert expected outward/top planes with transforms, nonempty inspected mesh
coverage after StaticMerge, material override culling and real support. Do
not remove nondegenerate faces by increasing a triangle-area threshold.

Do not repeat full P2 samples while these failures remain unchanged. Finish
a coherent implementation milestone with narrowly scoped fresh checks and
stable evidence, then return for review. All prior acceptance requirements
remain binding.

## Sixth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-PP3-second-third-review-completion.md`,
current source, saved-pack validators, route JSON and current noon captures.
Current builder SHA-256 is
`1c67f1ea3b88588f425ff97637e72a388761a0972ba0e3f0499393e2f0108ec8`;
manifest is `598ab4688a7503400b304a11a3f41cf38861b3d84ec6d25d4b55079e7f393002`.
Both route reports match these hashes and name gl_compatibility / Apple M5.
Reviewer bake freshness passes at 248 packs. **Result: fix, not L2.**

**Credit and preserve:** the corrected harness supplies twelve passing
movement records: both controllers through LOT34/71 both ways and shop
entry/exit. Both service records open the stocked city shop through its
actual dialog action, report four catalogue/stock entries, one vendor and
clean modal closure. This is useful service integration evidence. The hero's
custom grounding is now supplemented by a short support ray; a false
CharacterBody floor flag alone does not invalidate his route. Add a stationary
landing hold that proves support distance and bounded vertical drift, rather
than simply requiring a flag his controller does not use. Rapid re-entry,
occupied-support retention and former-plaza clearance remain separate work.

**Representative 76 is an improvement, not a complete binding house.** Its
saved-pack check establishes named parts and four sampled collision hits.
The inside-window image visibly shows two independently rounded leaf heads
inside a rectangular opening/frame. `_market_rep_french_window` builds two
whole clipped eggs, not halves split from one parent outline. The same
problem applies to independently built shutters. The door surround is
separate box jambs/lintel rather than the leaf outline grown by clearance.
The hard-coded `_market_boom_house_076` and `_market_rep_box` still choose
box walls, slabs, rails/coping and dimensions instead of the scheduled
profiles/joins. The brief only permits a box for its justified roof slab.
Presence/count/ray assertions do not establish fitted joins or compliance.

**Next build milestone:** finish this representative properly, without
replicating the hard-coded exception. Introduce a reusable boom builder driven
by the schedule/owner data. Split leaves/shutters from one parent; derive
openings and rings from those same outlines. Seat/cut/cap the scheduled
members; close every visible gap and overlap. Verify silhouette, clearances
and collision from both sides and produce a part/function/status ledger for
this representative. Only then apply the grammar to other boom owners and
complete tile/lock-up representatives, market flats and remaining variants.
Keep route/service proof and do not repeat P2 captures of unchanged places.

**Other blockers:** actual veranda/balcony/bounce/arcade/swing parkour;
current owner audit after source changes; full saved-pack orientation/support;
readable Helmsmith street composition. Interior capture is now useful. The
front capture still hides the threshold behind foreground geometry.

**Plan reproducibility:** despite the report's unchanged-plan claim,
`scripts/city_plan.gd` differs from committed generation in WALL, CROSSING,
OLD_TOWN and OLD_HOUSES while `tools/city_layout.py` is unchanged. Several
house differences are ring-order only, but house 16's polygon symmetric
difference is 0.019 m² and some door/front fields also differ. Trace the
regeneration environment/order and reconcile against canonical plan output;
do not hand-edit the generated file, quietly accept footprint drift or undo
unrelated owner changes. Record semantic equivalence and remaining differences.

## Seventh build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P3-sixth-review-milestone.md`, current
split-leaf code, focused saved-pack check, inside-window capture, rendered
route/hold JSON and source hashes. Builder
`4bfc40a7f2385f1d2f8f1900db0d4e097bbec7f4a46c87c032c78669e78bcf3c`
and manifest `5f4add48b4ddd47b8410b87004e18ec082febc8d9f3958202b9a94f176fb3c6c`
match the evidence; bake freshness passes (248 packs). **P3 remains fix.**

**Accepted progress:** the shared parent is now actually split and floor-cut
for leaf/shutter pairs with fitted convex collision. The close image shows
one common rounded outline; the earlier two-head and wrong clip-side faults
are corrected for these representative parts. The 53 assertions are focused
supporting evidence, not approval of all house parts. Twelve rendered routes
and both stocked service records remain valid; their new 30-frame endpoint
holds have walkable rays, real grounding resolution and zero drift. Close
the previously missing stationary-support proof for these tested endpoints.
Do not repeat these checks without a change that could affect them.

**Next implementation milestone:** finish the SAME common-outline chain
through its opening and ring, plus door leaf/opening/surround, using actual
scheduled silhouettes. The current rectangle frame visibly leaves space
outside the rounded shoulders; reducing its bar width does not make its
shape match. Replace the remaining representative box proxies with scheduled
forms, make the builder owner/schedule-driven, and supply evidence for the
complete boom representative. Then replicate and finish tile/lock-up grammar.
The existing representative ledger identifies the remaining work; do not
return another broad partial report after only a leaf tweak or harness rerun.

The full kit, parkour/anchors, owned audit, remaining joins and failed shop
street composition remain open under earlier reviews. Preserve the now
useful interior and split-leaf evidence. P4 cannot substitute for finishing
P3's shared grammar.

**Plan reconciliation remains actionable:** reproducibility of current source
is now established, but equivalence to the locked saved plan is not. Owner 43
changes from five to four storeys; owner 16 changes shop true to false and
front-edge index as well as a small polygon difference. Trace source/history
and any environment-dependent geometry ordering to explain those exact
changes and propose the smallest reconciliation through `city_layout.py`.
Do not silently choose a new design or hand-edit `city_plan.gd`; bring the
concrete reconciliation back for planning review while independent kit work
continues. Both the source-data precedence and locked-plan rules still apply.

## Eighth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P3-seventh-build-diagnostic.md`,
paired plan-drift report, owner-76 ledger, current profile/mesh construction,
65-record focused check and both noon window captures. Builder
`a2a7ca1acc2b08b573a17f2a268a86bd238906d111744935f8437ecc2e27ed27`
and manifest `65def0cd6c8a4d40a836de7e6bd68a328fff3cebcaae82a394deffbd34d285ec`
identify the inspected submission. Fresh bake check passes (248 packs).
**P3 remains fix; the representative and package are incomplete.**

Credit the common-profile front aperture/window ring and door aperture/
leaf/surround source changes. The current inside view now shows the rounded
ring following the leaves, and the facade contains actual profile cuts.
Keep the prior rendered routes/holds as retained scoped evidence: this
representative-only change does not justify redoing unrelated route suites.

Finish all remaining applicable representative parts/joins before the next
handoff: actual shop shutter, fanlight opening, side/rear/plinth construction,
parapet/coping corner closures, rail bays, column/rail/floor seat and chain
joins, picture motif and tank seats/caps. The 66-row ledger still marks
numerous applicable items partial/missing; 41 rows belong to other variants.
Make the grammar owner/schedule driven, then replicate boom variants and
complete tile/lock-up/market flats. Do not stop again after one outline tweak.
Verify capped watertight solids and outward winding: the current ring is a
flat decorative mesh and `_market_rep_wall_prism` emits side/front/back
faces, not a complete end-cap proof. Presence/rays and auto-generated shading
normals are not enough. Preserve decorative trim policy where appropriate.

**Planning decision — preserve the locked choices, not numerical drift.**
The unchanged source hashes unquantized GEOS centroids before rounding its
published polygons; the supplied diagnosis identifies an unstable selection
mechanism. Accept a narrowly scoped reconciliation in `city_layout.py` that
retains owner 16's locked shop=true and world-facing edge, and owner 43's
five storeys, anchored to stable parcel/quantized geometry identities with
explicit checks. Preserve owner 16's locked published outline through the
source if needed to remove the 0.019 m² drift. Canonicalize ring/edge identity
without changing world-facing sides; do not reseed/reassign all houses or
hand-edit generated data. Inventory WALL/CROSSING/OLD_TOWN differences for
semantic equivalence too; reproducibility alone is not equivalence. Regenerate
and check the plan and dependent data/models as required; report exact semantic
before/after changes. This preserves existing design, not a new layout choice.

Full 66/15 kit, required parkour, current owned audit and readable remaining
joins/shop composition are still binding acceptance work. No new P2 runs.

## Ninth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P3-second-third-review-fixes.md`,
current generated source, route/pack JSON and mesh/validation code. Builder
`216dfc8579db6aa06737d70d396a1e2a449e7a4f63cdd59c9c83a26ab9c9f7eb`
and manifest `d21450a1138cddaa758fc3b66477e0eea331dbdec368f856891841d147080ff4`
match the submission. Reviewer bake check passes (259 packs).
**P3 remains fix; fresh topology and readiness checks fail.**

**Priority 0 — confirmed winding regression in new representative helpers.**
`_market_rep_triangle` orients `(b-a).cross(c-a)` toward the expected exterior.
Godot's clockwise front is `(c-a).cross(b-a)`, as the existing
`_add_facing_triangle` correctly implements. These normals have opposite
signs. New representative faces are therefore wound inward even when their
assigned shading normal says outside. `_mesh_topology` then requires positive
`a.dot(b.cross(c))/6` volume, rewarding that opposite convention. Its passing
side-wall/parapet orientation claims are invalid. Correct both helper and
validator against Godot front normals and independently expected outside
planes; prove a known outward cube and its deliberately reversed fixture,
then saved front/back/side/roof meshes under ordinary back-face culling.
Do not fix only shading normals, disable culling or change expected volume
sign without a fixture establishing the convention.

**Priority 1 — close actual topology faults.** Even under the current flawed
orientation check, ground facade has 197 bad edges, French floor 123, and
door/window rings four each. Duplicate reveal/interior faces and T-junctions
must be removed from the actual boundary mesh. Emit connected front/back
surfaces and only external reveals/caps, sharing exact sample vertices at
opening extrema. Keep edge incidence, nondegenerate-face and signed volume
checks separate so a winding change cannot conceal closure errors. Finish
and verify these on the representative before mass replication.

**Priority 2 — restore truthful readiness and captures.** All 28 movements
and endpoint holds pass, but their combined reports contain two explicit
local-pack timeout failures. Do not describe overall route acceptance as
passing. `moy_packs_ready` checks every required pack around all interest
points; identify exact missing paths, request/load/activation states, stale
interest points and actor/resource lifetime errors. Focused capture readiness
may assert a documented subject/neighbor pack set for a view, but must not
hide a global timeout or bypass gameplay loading. Fix the underlying stalled
required path; no longer timeout, disabled gate or silhouette-only success.
Fresh screenshots were not produced; historical images remain historical.

**Plan preservation credited:** independent comparison confirms owner 16's
polygon symmetric difference is now zero, shop=true and world-facing edge
match the locked plan; owner 43 is five storeys with the same polygon/edge.
Source anchors and generation checks implement the planning decision.
Remaining WALL/CROSSING/OLD_TOWN changes still need a semantic inventory.

The complete scheduled kit, parkour, owned area audit and readable joins remain
open. Work the geometry and readiness faults before more broad reports;
performance optimization stays deferred. Preserve successful unchanged scoped
movement/service evidence without treating readiness failures as unrelated.

## Tenth build review — 2026-10-20: fix (automated loop)

Reviewed `../diagnostics/2026-10-20-moy-P3.md`, current mesh helper/101-check
validator, route JSON, actual run commands and plan/bake hashes. Builder
`77df0a47f8df9bde5ba5552fa7420729042d86427ffaec749174882ef9038810`
and manifest `1b914823addc99c91fe3793c5c5336d8e54795da7ed8cafe27f38ec1c6859bd8`
match the evidence; fresh bake check passes (260 packs). **P3 remains fix.**

**Credit:** the helper again uses Godot's clockwise front. The validator now
separates edge incidence/direction, Godot-front volume and independent cube
exterior signs, rejecting the reversed cube. The 101-record saved sample
reports zero failures, closing the ninth review's sampled topology/winding
regression. Keep ordinary-culling visual proof open until images exist.
Twelve controller routes, service and holds now pass with local readiness.

**Evidence correction:** the actual successful invocation was `--headless
--rendering-driver opengl3`; both final route JSONs have an empty adapter.
The configured `renderer: gl_compatibility` does not make this GPU-rendered
proof. Credit actual controller/physics movement on saved packs with clear
headless metadata; do not repeat it merely to change its label. Capture the
visual side separately and add actual command line/display-server/backend
metadata so future reports cannot conflate configuration with rendering.

**Next deliverable: finish the full P3 grammar.** Successful regression tests
are no longer the work blocking construction. Complete all applicable boom
parts/joins and replicate; finish tile/lock-up variants and market flats,
with a current as-built ledger replacing the all-partial historical CSVs.
Then run the missing parkour/anchor routes and a current owner-attributed
area audit, fixing owned geometry. Avoid another round spent only on already
passing passage/shop tests or forced all-city loading.

**Capture recovery:** diagnose the exact normal-process exit134 log before
calling it an unavailable renderer environment. Use an explicit writable log
path, close conflicting editor/QA instances and use the tool's scoped sandbox
escalation for necessary WindowServer/GPU access if supported. Keep permission
and crash diagnostics precise. A focused saved representative capture can
isolate renderer access from streaming; then capture its real district with
subject/neighbour readiness. Do not substitute blank/historical views.

**Plan remains unresolved:** restoring `city_plan.gd` from HEAD before bake
keeps the locked snapshot but does not reconcile the generator. The unchanged
locked hash is confirmed; `city_layout.py` still emits different tables.
Finish semantic inventory/source correction so running the canonical generator
preserves approved layout/variants without restoring generated output by hand.
Equivalent ring order/triangulation need not be byte-identical, but every
changed world polygon/height/front/kit choice needs explicit equivalence or
planning review; preserve the eighth-review approved owner16/43 decisions.

The forced all-pack hotel failure remains recorded city loading debt. Do not
hide invalid_resource, but it is not a reason to postpone independent P3 kit
construction or rerun P2 optimization. Link it to the owning scope and keep
local gameplay-readiness/occupied-support requirements intact.

## Eleventh build review — 2026-10-20: fix (automated loop)

Reviewed the fresh continuation sections in `../diagnostics/2026-10-20-moy-P3.md`,
current 259-pack bake, hashes, route/audit artifacts and all six isolated GPU
captures across P3/P4. Builder remains
`77df0a47f8df9bde5ba5552fa7420729042d86427ffaec749174882ef9038810`;
manifest is `a659891e27f948b64acc90597813198e17c740e7fc18dc1788cfa2df0289854b`.
Fresh bake check passes. **P3 remains fix.**

Credit explicit headless/Dummy route metadata and 12 passing local-ready
court/shop movements/holds, and successful isolated Apple M5 Metal captures.
The isolated boom/arcade views now make their assets visible; the market-flat
view confirms a largely plain proxy facade. Isolation is not district,
noon/dusk, street/shop or two-sided join acceptance. It removes the earlier
claim that no GPU captures are possible; finish focused real-city views with
subject/neighbour readiness using that working graphics path.

The current area snapshot is useful: 315 findings, 267 blocking. Attribution
is a path heuristic, not full plan ownership or matched baseline evidence.
Fix owned overlap/reach/headroom findings with actual owner ids and both
bodies, then targeted checks. Do not keep replacing snapshots without fixing
construction. The full 66/15 grammar and parkour suite remain incomplete;
no representative or full kit completion was delivered in this round.

Plan generation now runs through source without restoring the generated file.
The report says all old-house polygons/semantic fields match the locked plan;
remaining wall/crossing/open-space differences need their semantic inventory
retained as explicit evidence. The reported wall-centreline Hausdorff delta
is 0.0361 m, not byte identity. Do not broaden this into layout redesign.

**Next substantive build:** finish a complete scheduled boom grammar across
applicable owners, then tile/lock-up/flats, with current part/join evidence.
Do not rerun all already-passing passage/shop routes for metadata-only changes.
Target tests to changed geometry, preserve prior scoped evidence and keep
performance work deferred. Historical leading sections in the diagnostic
still describe older hashes/results; rewrite the report around the final
submission instead of accumulating contradictory superseded paragraphs.

## Twelfth build review — 2026-10-21: fix; paused for reassessment

Reviewed the stable final build turn `01a158c0-4dc2-7b32-9318-8bdfde9d840d`
after it stopped editing. Evidence is the package's
`../diagnostics/2026-10-20-moy-P3-current-fixes-pass.md`, current route JSON,
saved-pack checks, source and actual focused GPU screenshots. Independently
rechecked bake freshness: 259 packs. Builder SHA-256 is
`5af1395374f6e414b90631d3cb0c05e813827e9cfc331dc07db754d8a268517b`;
manifest is `d28fd5d1ba31f4b6a101274f91b3832069e1b44ebf756c5caf90833f66b0a816`.
Source/evidence hashes match. **P3 remains fix; L2 is not accepted.**

Credit the representative boom's split leaves/shutters, matching doorway,
tank seats/vessels/caps and veranda returns. The saved MarketHouse_076 ledger
has 211 passing assertions: 23 present parts, two represented by the shared
punched wall and 41 not applicable to that variant; 11 present joins and four
not applicable. This is useful scoped evidence, not a completed 66-part,
15-join market kit across all applicable owners and variants.

Current JSON reports 12/12 court/shop movements and both controllers' service
interactions passing. Source checks include support rays, custom grounding,
30-frame landing holds and bounded drift. These are headless/Dummy physics
results with mesh/RID noise, not clean rendered runtime acceptance. Retain
that credit without conflating it with the six required parkour/anchor tasks.

Inspected all four current GPU images. Boom front and arcade are visible;
the veranda-return crop does not show the return's two-sided fit clearly,
and the market-flat facade remains largely proxy. Saved-pack isolation does
not supply the required streamed noon/dusk district, shop/counter and readable
join evidence. Complete applicable scheduled variants, flats, signs, stalls
and court construction; verify physical joins and the remaining parkour and
service/re-entry/occupied-support requirements. A current matched audit with
actual owner attribution is still required: the prior 267-blocking snapshot
predates this bake and is neither a current count nor proof of closure.

The user requested one final review, then reassessment. **Automated build/fix
rounds stop here; no implementation continuation is authorized by this review.**
Across the loop, route tooling, evidence provenance and a boom representative
improved more than full kit completion. Preserve that progress, but focus any
future authorized work on complete scheduled construction before another
broad validation round. City-wide P2 optimization and final performance
acceptance remain deferred. The implementation working tree is preserved;
this checkpoint commits review documents only.

## Bounded boom-house initial review — 2026-10-21: fix

The initial milestone handoff (turn 01a15ba4-4b34-75d3-a186-2795b1592ca3)
is reviewed in `moy_p3_boom_milestone.md`. Fresh 260-pack bake and matching
sample/route hashes are credited. The 213-record sample, 12 unrelated local
routes and obstructed district images do not accept MarketHouse_076's fits,
landings or city-context appearance. Reconcile the canopy applicability
contradiction, replace geometry-presence join rows with measured fits,
provide076-specific GPU/physics evidence and a current owned local audit.
One focused fix round is allocated; P4/P2 and full-area reruns stay excluded.
Package P3 remains fix at its unchanged full L2 criteria.

## Decisions log

- 2026-10-18: the houses are exterior only; shop windows are dressed 1.5 m
  deep; no core or flat is built.
- 2026-10-18: the Helmsmith's legacy stall leaves Civic Plaza for building
  38 on Lamp Lane in this package (section 2a).
- 2026-10-18 (user): the Helmsmith keeps a proper walk-in shop, not a
  lock-up: the shop floor is built and entered in P3; his workshop is seen,
  his home upstairs is not entered.
- 2026-10-18 (data review): every house faces a street, a square or the
  Rim Walk; the twelve at the south edge face the Rim Walk.
- 2026-10-18: a pair shares one door, so pairs need fronts on one line; a
  house under 4 m across is a lock-up; a house too shallow for a ramp core
  and a room (`core.l + core.room`) keeps its height and takes a lift
  (`core: lift`), as Old Moy's pencil houses do. Lots 37, 41 and 69 became
  lock-ups (they were 7, 8 and 9 storeys on slivers 3 to 5 m across).
- 2026-10-18: `COURTS` is the first grid layout's block middles; the open
  ground is each one less its buildings and lots (`COURT_WAYS`), and every
  piece has a way in or belongs to a landmark.
- 2026-10-18: some houses hang a blade sign over their lane (`blade`),
  never two within 4 m.
- 2026-10-18 (user): the plan decides the parts. The market house's parts
  and joins are a binding schedule in the data (`MARKET_HOUSE.parts`,
  `.joins`; section 2b), checked by the plan, drawn by the model. Doors are
  one leaf on one hinge, cut at the floor; every frame is its leaf's own
  shape.
