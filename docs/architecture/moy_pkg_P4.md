# Package P4: the Old Moy tower-house kit

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
   - `reach`: every street door, every passage end and every roof ramp foot.
   If P0 is not yet built, say so and list what you checked by hand.
3. **Parkour**, with both characters:
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

## Decisions log

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
