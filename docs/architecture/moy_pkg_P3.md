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
