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
corners), 10 lock-ups. 22 pairs share a door and a core; 11 houses have a
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
  - cantilevered balconies with steel rails (`tile.balcony`); steel
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
- every place the data and this brief disagreed.

## Decisions log

- 2026-10-18: the houses are exterior only; shop windows are dressed 1.5 m
  deep; no core or flat is built.
- 2026-10-18: the Helmsmith's legacy stall leaves Civic Plaza for building
  38 on Lamp Lane in this package (section 2a).
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
