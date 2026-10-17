# Moy: the Old Moy tower house kit (proposed, 2026-10-13)

Read with `docs/architecture/city.md` (section 7, Old Moy) and the Old Moy
charter in `docs/style_charters.md`. The plan data is in
`tools/city_layout.py` (`TOWER_KIT`), emitted to `CityPlan.LOT_KITS` and
`CityPlan.BUILDING_KITS`.

## 1. Precedent

**The user's references (2026-10-13).** Two photographs:
- **A single tower** of the Wadi Dhahr and Sa'dah type, on a battered base of
  coursed earth with rounded corners. This is *one* kind of base, not the
  rule (user): in Old Moy it marks the oldest houses.
- **Old Sana'a**: the common type, and the model for most of Old Moy.
  Tower houses packed shoulder to shoulder, rectangular and plumb, on ground
  storeys of dark stone, with fired brick above, every storey banded in
  white gypsum friezes (zigzags, chevrons, roundels), paired qamariya
  windows, and modern water tanks and dishes on the roofs.

Reading the single tower from the ground up:

| Element | Term | What it does |
|---|---|---|
| Lower two-thirds: horizontal bands of mud, the wall leaning in as it rises, the corners rounded | **zabur**, coursed rammed earth laid in lifts; a **battered** wall | Thick, cool, cheap; the batter carries the weight |
| Small square openings low down, few of them | defensive lights and vents | Privacy and coolness at street level |
| A white projecting band where the mud stops | **gypsum (*nura*) cornice** | Sheds rain off the earth; marks where the brick begins |
| Upper storeys in fired brick, a little proud of the mud below | **corbelled** brick storeys | Lighter, finer walls for the rooms people live in |
| Arched windows outlined in white | rectangular window under a **qamariya** fanlight, gypsum surround | Light; the qamariya once held alabaster or coloured glass |
| A white box on the face | **kishk**, a projecting box window | A cool seat and a view down the street; once for cooling water jars |
| A lumpy white chute and a drainpipe | the old **latrine shaft** and a spout pipe | Services carried outside the living rooms |
| A crenellated top with raised corners | **parapet** with merlons and corner horns | Shelters the roof terrace |
| A low walled court with a painted door | the **court wall** | The household's own ground |

Reading old Sana'a:

| Element | Term | What it does |
|---|---|---|
| Ground storeys of dark basalt and pale squared stone, plumb, square corners | **stone base**, coursed rubble and ashlar | Hard, fireproof, defensive at street level |
| Brick storeys flush above, no batter | fired brick on the stone | Lighter walls for the living floors |
| White bands at every floor: zigzags, chevron chains, rows of roundels | **gypsum (*nura*) friezes** in relief | Each house's ornament; seals the joints; reads from far off |
| Windows in pairs under twin fanlights, white blind arches between them | paired **qamariya** | The living rooms' light |
| Tanks and dishes on the roofs | the modern layer | Today's services on old roofs |

Shibam adds the town plan: towers of 5 to 9 storeys packed shoulder to
shoulder, some linked by bridges between upper floors. Old Moy is that
town, kept tall (user, 2026-10-12).

## 2. How a tower house is lived in now (proposed)

Traditionally one tower housed one extended family: animals and grain at the
bottom, living floors above, the kitchen high up, the best room (the
**mafraj**) at the top and sometimes a rooftop room (the **manzar**).

**In Moy most are subdivided now.** The towers were built as single family
houses; as the city grew round them most were divided into a ground-floor
shop and a flat on each floor or two above, all sharing the ramp core and the
roof. A few remain whole houses of old families. This keeps the census as it
is (Felix above the bakery, Sol above his café, Pinestein on his top floor)
and gives every house a gap between how it was built and how it is used.
(Recommended to the user, 2026-10-13; awaiting confirmation.)

## 3. The kit

**Grid and storeys.** The world's 3.25 m storey. The kit fits the lot it is
given (6 to 14 m frontage, about 15 to 16 m deep) rather than a fixed grid.

**Which lots get a tower house.** A tower house needs its ramp core
(3.4 m wide) inside earth walls 0.9 m thick, so **lots whose short side is
6 m or more** take the tower house. The core runs along the long side and
the rooms fill the rest: in a 6 m house the core takes most of the width in
the middle of the plan and the rooms run full width at either end of it;
from about 10 m a room stands beside it as well. Narrower lots hold
the **later pencil infill**: tiled, plumb-walled, with a lift instead of a
ramp core (a separate kit, the pencil building already drawn in the street
section). The numbered old buildings (25 to 32, 52) are tower houses.

### 3.1 Base, middle and top

| Part | Height | Construction |
|---|---|---|
| **Plinth** | 0 to 0.9 m | Basalt courses, the hard base at the street |
| **Base: stone** (most houses) | 1 to 3 storeys | Coursed dark basalt with pale ashlar quoins and bands, 0.7 m thick, plumb, square corners. The brick rises flush above it, with a white frieze at the joint |
| **Base: earth** (the oldest houses, about one in four, most of them round the first well on Cinema Square) | 2 to 4 storeys, at most two-thirds of the height | Zabur in 0.65 m lifts (five to a storey). Battered 1.5°: 0.9 m thick at the ground, about 0.6 m at its top. The outer face steps back about 0.26 m over three storeys. Corners free of a neighbour are rounded (superellipse plan, exponent about 4) and each lift's ends turn up slightly at the corner (the Sa'dah "horns") |
| **Cornice** (earth bases) | 0.5 m at the top of the base | White gypsum, projecting 0.3 m |
| **Brick storeys** | the rest | Fired brick, 0.45 m, plumb (over an earth base, corbelled out 0.3 m over the cornice so the face returns to the lot line) |
| **Friezes** | at every brick floor | White gypsum bands in relief, from a closed set: zigzag, chevron chain, a row of roundels, a dentil course. Polite houses carry two bands a floor and roundel panels between the windows; vernacular houses one band a floor, panels on the top storey only |
| **Parapet** | 1.2 m above the roof | Brick, crenellated in one of three family patterns, whitewashed horns at the corners |
| **Roof kiosk** | one storey over the core | Where the ramp arrives on the roof; carries the wind tower |
| **Wind tower** | 4 to 5 m above the roof | A one-sided catcher, mouth turned west to the steady wind, its shaft the ramp core itself |
| **Manzar** (one house in four) | one storey on the roof | A rooftop room with qamariya windows on three sides |

### 3.2 Openings

- **Base (stone or earth):** small square lights, 0.6 × 0.8 m, deep in
  the thick wall, splayed inside; vents under the cornice or frieze.
- **Brick storeys:** a tall window, 1.0 × 1.6 m, sill 0.9 m, under a
  **qamariya** (semicircle, 0.5 m radius), every one outlined in white
  gypsum; on polite houses often in pairs under twin fanlights with a
  white blind arch between. The qamariya is the kit's superellipse head.
- **The mafraj (top floor):** low wide windows, sill 0.4 m, in a row of two
  or three, for sitting on floor cushions.
- **The house door:** 1.2 × 2.4 m in a superellipse-headed opening with a
  gypsum surround; a carved timber leaf painted blue, green or ochre; the
  **house mark** painted above it.
- **The shopfront** (main and shopping streets only): a later opening cut
  in the base, 2.4 to 3.2 m wide, on a timber lintel, with folding
  timber shutters. It sits beside the house door, never instead of it.
- **Kishk:** 0 to 2 per house, on the brick storeys, 1.2 wide × 1.6 tall ×
  0.6 m deep on two brackets, plastered white, latticed panels.

### 3.3 Plan: the core, the floors, the services

- **The ramp core** stands against one party or side wall, along the long
  side of the house: a vestibule behind the house door, then a **switchback ramp**:
  two flights of 2.6 m (each rising 1.625 m at 32°, 1.4 m wide) either side
  of a 0.3 m spine wall, with 1.4 m landings at both ends. Core: 3.4 × 5.8 m
  plus the vestibule. Every floor lands at the street end of the core, where
  that floor's door opens. The spine wall is the traditional tower house's
  central stair pillar, turned into the world's ramp.
- **Air.** The wind tower drops the west wind into the core. A grille over
  each floor's door lets it into the rooms, and it leaves by the windows.
  The core is the house's air shaft as well as its way up.
- **Floors** are one flat each (or two floors for a larger one), entered
  from the core landing. Rooms face the street and the free sides; wet
  rooms stack on the service side.
- **Services.** The old latrine shaft, a plastered chute on a side or back
  face, carries the soil stack down to the sewer; every kitchen and bathroom
  stacks against it. The roof terrace drains by spouts (*mizab*) and white
  drainpipes.
- **Washrooms** are modern (Moy is a modern city): flush toilet, basin,
  shower.

### 3.4 Neighbours and the roofs

- **Party walls.** Stone-based houses stand wall to wall, plumb, and read
  as separate towers by their own frieze patterns and heights. Where an
  earth base meets a neighbour, its batter opens a slot of up to 0.3 m as it
  rises, and the corbelled brick closes it again.
- **The roof route** (city.md 6) crosses Old Moy on the terraces. Where two
  neighbours' roofs differ by **one storey**, the lower parapet carries a
  short timber ramp up to the higher one. Where they differ by more, **a
  timber bridge after Shibam's** links an upper floor's kishk or window of
  the taller house to the lower roof, or the climb goes by the holds below.
- **Holds.** Window sills, qamariya heads, string courses and the kishk
  brackets give holds at most 2.4 m apart up every brick face, within a blorb
  bounce. Stone bases give holds at their ashlar bands and lights. An earth
  base is smooth: it is climbed only at its rounded corners, where the
  turned-up lift ends give holds every 0.65 m.

### 3.5 Collision

The whole tower is solid (`CollisionPolicy` blocking). Parkour landings: the
plinth, the cornice, string courses, sills, kishk tops, parapets, the roof,
the kiosk and manzar roofs, and the wind tower's cap. Decorative: lattice,
the relief panels, drainpipes, lifts' upturned ends beyond 0.1 m.

### 3.6 Plan data

**Turned houses (2026-10-16, revised 2026-10-17).** In the Well Quarter (`city.md` 7, Old Moy) the tower houses are not grid lots: `CityPlan.OLD_HOUSES` gives each house's outline (a plot cut square to its frontage, 6 to 10 m wide and up to 14 m deep, wedge-shaped where the old road bends or the Rim Walk curves), its storeys, the road, square or Rim Walk it fronts and its kit; the middle of each block is courtyards. The builder turns the house to its front, follows the outline at the base and squares the tower above where the plot is irregular.

`tools/city_layout.py` assigns every Old Moy lot a kit (`TOWER_KIT`) from
its size and street, and the numbered tower houses explicitly:

- `kit`: `tower` or `infill`;
- `storeys`, `base_kind` (`stone` or `earth`) and `base` (its storeys);
- `front`: the face on a street (`n`, `s`, `e` or `w`);
- `shop`: whether the ground floor has a shopfront;
- `kishk` (0 to 2), `manzar`, `parapet` (pattern 0 to 2), `polite`.

The variants come from a fixed hash of the lot, so the plan is the same on
every run, and each lot's variants are written into `CityPlan`. Two
neighbours never share both the parapet pattern and the base height.

## 4. The Reese–Miller house (number 52), the first of the kit

**Site.** 10 × 16 m on Arcade Street, its 16 m street face on the east. It
stands nearly free, as in the reference photo:
- a 3 m slot to the north, which leads from Arcade Street to the court gate;
- a walled **court** behind it, to the west, about 12 × 16 m;
- a narrow five-storey infill house against the south end.

**History.** Built as one family's house in the well town's first century,
three storeys of earth. The brick storeys were added a century later, and
the court wall is older than both. Subdivided when the Windworks came.

**Massing.** 7 storeys to the roof at +22.75 m: earth base of three
storeys (to +9.75), four brick storeys above, the parapet to +23.95. On the
roof: the core's kiosk with the wind tower to about +27.5, and a manzar.
Rounded corners on the three free sides. Polite: relief brick on every
storey, one kishk on the mafraj, stained-glass qamariya in the manzar.

**Lines that stack.** Across the 10 m depth: the walls (0.9 m at the base,
0.45 m in the brick), the core along the north wall (3.4 m), the rooms to
the south. Clear inside: 8.2 × 14.2 m at the ground, 9.1 × 15.1 m in the
brick. The core, the service shaft (back face, south end, into the court)
and the wind tower run straight through every storey.

| Level | Height | Who and what |
|---|---|---|
| **Ground** | 0 | The house door and vestibule (north end of the street face); the core; a **tailor's shop** behind a shopfront in the earth base (no one the hero meets); the house's store (bikes, Jammer's scooter); the back door to the court |
| **Floors 1 to 3** | +3.25 to +9.75 | Three flats, one a floor, let to neighbours (no one the hero meets): about 100 m² each |
| **Floor 4** | +13.0 | The Reese–Miller flat begins. Elizabeth and Dan's bedroom over the street; the bathroom on the shaft; Elizabeth's study at the back, its window on the court |
| **Floor 5** | +16.25 | The kitchen on the shaft, as tradition puts it high in the house; the dining room and living room over the street |
| **Floor 6** | +19.5 | The **mafraj**: the long best room along the street, low wide qamariya windows and the kishk, cushions round the walls. A WC on the shaft and a store at the back |
| **Roof** | +22.75 | The terrace behind the parapet, with summer sleeping mats, Elizabeth's potted lemon and herbs, and the laundry line. The core's kiosk carries the wind tower. **Jammer's room is the manzar** on the roof, about 5 × 6 m, with stained-glass qamariya on three sides and his farm drawings on the walls |

Jammer's room "at the top" (the brief) is literally the rooftop room, which
answers why a boy has the best view in the house: it was the only room left
when the family took the top of the tower.

The **court** behind: the old court wall with a painted blue door onto the
north slot (after the reference photo), the shared yard of all four
households, bicycles, a bench, an old well head, now capped.

**Audit.**
- **Areas:** the upper floors hold 9.1 × 15.1 = 137 m², less the core
  (about 31 m²), so about 106 m² a floor, enough for each flat or each
  Reese–Miller floor.
- **Access:** every floor is reached from the shared core, and no household
  passes through another's rooms.
- **Section:** the roof at +22.75 matches the plan height of 23 m.
- **Light:** the manzar's top at about +26.3 and the wind tower at +27.5
  stand clear of the parapet.

**Proposed decision (awaiting the user):** the family holds the top three
floors and the roof, with neighbours below, rather than the whole tower.
