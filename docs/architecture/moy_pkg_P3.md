# Package P3: the market lanes kit

2026-10-18. Build-session brief. Read `moy_build_roadmap.md` first.

- **Area:** the market lanes, south of Clinic Lane and west of South Street,
  as `market_lane()` in `tools/city_layout.py` defines them.
- **Target level:** L2, built.
- **Depends on:** P0 (the check suite) for its acceptance. It can be built
  before P0 lands, but it is not *done* until the suite passes on its area.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`, `moy_build_roadmap.md`.
2. `docs/architecture/moy_market_lanes.md`: the kit's design. Sections 3 to 5
   are the specification.
3. The market lanes charter in `docs/style_charters.md`.
4. The plan data: `CityPlan.LOT_KITS` (one entry per lot, `null` outside
   Old Moy and the market lanes), `CityPlan.BUILDING_KITS[34]` (the market
   flats) and `CityPlan.BUILDING_KITS[38]` (the Helmsmith).
   - There are 80 market-lane lots today: 58 tile houses, 15 boom houses and
     7 lock-ups.
   - The design doc's table predates the current layout. The data wins.
5. The plan drawing's kit sheets, `docs/drawings/moy_plan.html`:
   - *The market lanes*: the kit at true scale, the core-sharing pair, and
     South Street's west side drawn from the data.
   - Match these.

## 2. What to build

Today every lot is a plain block (L1). Replace each market-lane lot's block
with its kit house, built from its `LOT_KITS` entry. Build no house by hand.

**The kit is exterior only.** These houses are not entered.
- The ramp cores and the flats are not built inside.
- Each house's street door is a closed door with a lit fanlight.
- Its shopfront is glazed or shuttered, with a 1.5 m-deep dressed shop window
  behind the glass: shelves and goods by the trade, at L2 in plain shapes.
- Collision is the house's outer volume. Its parkour features (below) stand
  proud of it.

**Each piece, from the data:**
- **Boom house** (`gen: boom`, 4 or 5 storeys):
  - rendered front in palette colour `colour` (from the charter's five), on a
    0.6 m grey-tile plinth;
  - 1.1 m parapet; French windows (1.0 × 2.2 m) with timber shutters;
  - **if `veranda`:** square 0.5 m columns, 2.4 m out from the front,
    carrying a covered walkway at the ground and an open veranda with a
    timber balustrade on every floor above;
  - **otherwise:** a shallow balcony each floor.
- **Tile house** (`gen: tile`, 6 to 9 storeys):
  - mosaic-tile front in palette colour `colour`, a grey-tile plinth;
  - the shopfront canopy (1.5 m deep, 3.6 m up);
  - cantilevered 1.2 m balconies with steel rails; steel windows
    (2.0 × 1.4 m);
  - **if `corner`:** the rounded corner, a superellipse the full height, with
    curved balconies wrapping it;
  - **if `lift`:** a glass lift shaft on the back face.
- **Core** (`core`, `pair`): a pair sharing a core has one shared house door
  on the street between its two shopfronts. A house with its own core has
  its own door beside its shop. Doors only: nothing is built behind them.
- **Lock-up** (`kit: lockup`): two storeys, a roll-shuttered shop below, a
  small room above.
- **Roof** (`roof`): water tanks, laundry frames, a rooftop greenhouse or a
  garden, as the kit's drawings show.
- **Signs** (`signs`): 0 to 3 stacked picture signs on the front, never
  lettered (picture signs only: no in-game text). Some hang across the lanes.
- **The market flats** (`BUILDING_KITS[34]`): four tile houses built as one
  terrace, rounded at the corner, with laundry on the shared roof.

## 2a. The Helmsmith moves home

The live game still has the old Helmsmith stall standing in the middle of
Civic Plaza (`_add_moy_helmsmith()` in `scripts/city_generator.gd`, at world
(−470, −18)). It was kept there as a stopgap when the city was replaced. Its
real home is building 38, on Lamp Lane's south side (`CityPlan.BUILDINGS`
38, x −600 to −590, z 174 to 186; `CityPlan.BUILDING_KITS[38]`).

- **Build 38** as a lock-up (two storeys) facing north onto Lamp Lane: its
  shutter rolled up by day, a counter across the open front, helms on the
  back wall's racks and on stands either side of the opening (dressed at L2
  in plain shapes), one picture sign of a helm. His home is behind and above,
  not entered.
- **Move the vendor:** the same NPC, with the same name, looks, `shop_category`
  `"city"` and stock, standing behind the counter, facing the lane, on
  tested ground. Keep him stationary.
- **Remove the legacy stall from Civic Plaza** and its storefront node
  (`MoyHelmsmithShop`), and update `_remove_moy_actors()` to match. Nothing
  of the shop is left on the plaza.
- **Check:** the shop UI opens from Lamp Lane with both characters; the
  plaza is clear; `reach` finds the counter from the lane.
- **His lines.** His second line ("A core takes one head-shape at a time…")
  explains a mechanic, which the in-game text rule forbids. Replace it with
  an in-character remark that explains nothing, and flag the change in the
  diagnostic.
- Building 38 is still the Helmsmith's interior package (P13k) later; this
  move needs only its front.

**The streets they make:**
- **Arcade Street's roof** (section 3.5): steel arches carrying translucent
  panels 9 m up, over its full 8 m width, through the market lanes. Its
  arches are parkour landings; its panels are solid.
- **Lamp Lane's night market:** strings of lanterns hung house to house
  across the lane (decorative), and the stalls that open at dusk (the
  existing night-market schedule, if any; otherwise stalls as static props).

**Construction.**
- Build every piece from SuperEgg parts (`SuperEgg.build_part`), in the
  manner of the village kits.
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

## 3. Checks

1. **The plan validator** passes: `tools/validate_city_plan.gd`, with its kit
   checks:
   - each house's generation fits its storeys;
   - only boom houses have verandas;
   - every house under 6 m across shares a core;
   - core pairs are mutual;
   - lock-ups are two storeys.
2. **The check suite** (P0) on the area's bounds passes:
   - `overlap`, `buried`, `trap`, `underside`, `solid` and `guard`;
   - `reach`: every street door is reachable at its threshold, every veranda
     from the street.
   If P0 is not yet built, say so and list what you checked by hand instead.
3. **Parkour**, with both characters:
   - climb a boom house's veranda columns floor to floor;
   - balcony rail to rail up a tile house;
   - a blorb bounce onto a canopy;
   - along the arcade roof from a tile house's balcony;
   - swing on a sign across a lane.
4. **Performance:** report draw calls, triangles and frame time from the
   performance probe, at the viewpoints below, before and after.

## 4. Viewpoints

From `docs/drawings/moy_city_3d.html`'s places:
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
- every place the data and this brief disagreed.

## Decisions log

- 2026-10-18: the houses are exterior only; shop windows are dressed 1.5 m
  deep; no core or flat is built.
- 2026-10-18: the Helmsmith's legacy stall leaves Civic Plaza for building
  38 on Lamp Lane in this package (section 2a).
