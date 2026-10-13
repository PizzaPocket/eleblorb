# The Sea Folk City: Civic Layout Plan

Status: dimensioned schematic for review (2026-10-06); **second pass,
code-ready, 2026-10-13** (section 9); **third pass, proposed 2026-10-13: the
vertical city** (section 10), which supersedes the earlier sections where they
differ. Read with
`ocean_sea_folk_city.md`, which owns the community, culture, air halls and
charter. This document places them on the seabed.

## 1. Survey

From `ocean_kingdom_terrain.gd` and `ocean_kingdom_city.gd`:

- Centre: world `(0, -540)`. The seabed is levelled to **-72 m** within 105 m of
  the centre, blending into the natural floor over a further 45 m. The water
  surface is at 0 m, so the city lies 72 m down.
- **Castle:** a 34 × 30 m base at the centre with walls, four corner towers
  with prism-green crowns, two entrance columns and an open audience hall. Its
  entrance faces local `-z`.
- **Homes:** sixteen 8 × 7 m shells with split front doorways, in two rings of
  eight at 49 m and 82 m, facing the centre.
- **Paths:** eight spokes of luminous stepping stones from 25 m to 73 m; 24 kelp
  plantings between 35 m and 83 m; pearl lamps on the castle and every home.
- **An inn already exists:** `VillageInn.create()` places the
  `seafolk_village_inn` at local `(24, 18)` with the keeper **Nerissa
  Stillwater** and a price of **25 Tokoins**, the kingdom's rate (other kingdoms'
  inns charge 15 to 25). She is the city's twenty-first adult resident and was
  missing from the brief's census.
- **Arrival:** visitors come from the islands and the arrival dock, 540 m away in
  the `+z` direction.
- **The Kraken's route** passes about 190 m from the city on the `+z` side.

Local frame: origin at the city centre; `x` and `z` follow world axes. Heights
are metres above the city floor (-72 m).

## 2. Decisions this plan makes

- **The city faces its visitors.** The rebuilt castle turns its entrance to
  `+z`, toward the islands, and the main avenue runs that way.
- **The inn becomes the guest hall.** The existing inn is rebuilt as an air hall
  at nearly the same place. **Nerissa Stillwater** is renamed **Isaro** and keeps
  it, at the existing price of 25 Tokoins. Pelaju stays the surface liaison.
- **Census:** twenty-three, adding Isaro.

## 3. Rings

| Ring | Radius | Contents |
|---|---|---|
| Central mound | 0 to 24 m | the castle (Tidehall) on a mound raised 2 m |
| Civic ring | 24 to 46 m | the Exchange and guest hall air halls, the Lamp House, the school court |
| Ring Current | 46 to 52 m | a channel 2 m below the civic ring, its water running clockwise at a strong swimming pace |
| Home ring | 52 to 90 m | sixteen homes in two rows, at 60 m and 82 m |
| Garden ring | 90 to 105 m | kelp gardens, sea-flower beds, the Reef House workshop |
| Edge | beyond 105 m | the Glassworks at a warm vent, Ikara's lookout |

The existing homes at 49 m move out to 60 m to clear the Ring Current. The
outer row stays at 82 m.

## 4. Avenues

The eight existing spokes become **sunken avenues** 4 m wide, lit by the
luminous stones, running from the castle mound to the edge. The **main avenue**
runs `+z` from the castle's new entrance, past the Exchange, over the Ring
Current and out to the Glassworks, the way visitors arrive. Avenues cross the
Ring Current as open water; the current carries a swimmer sideways across them.

## 5. Air halls and glass tunnels

Floors of air halls and tunnels stand on podiums **3 m above the city floor**,
so swimmers pass beneath the tunnels. Each air hall's moon pool drops through
its podium to open water underneath.

| Air hall | Centre `(x, z)` | Dome | Keeper | Program |
|---|---|---|---|---|
| **The Exchange** | `(0, 34)` | 18 m across | Maresa | trading floor and Nautilus Shell counter; Rodasu's Watering Can counter; Dakuro's chart room |
| **The guest hall** (rest point) | `(26, 22)` | 16 m across | Isaro | dry beds, a common room, the party's gathering floor; 25 Tokoins |
| **The Glassworks** | `(0, 118)` | 16 m across, over the vent's edge, on a socketed podium where the levelled floor gives way to natural slope | Kunei and Damaku | glass furnace heated by the vent, blowing floor, tunnel-segment workshop |

| Glass tunnel | Route | Length | Moon pools |
|---|---|---|---|
| Civic tunnel | the Exchange to the guest hall, following the civic ring at 34 m | about 26 m | at both halls |
| Avenue tunnel | the Exchange along the main avenue to the Glassworks | about 67 m | at both halls and a junction at 70 m, between the home rows |

Tunnels have a 3 m walking floor, 3.2 m headroom inside a superellipse glass
tube about 4.5 m across, on orichalcum ribs every 3.2 m and slender supports.
Ramps are no steeper than 1:6. The avenue tunnel crosses over the Ring Current
on a short span.

## 6. Other buildings

| Building | Household | Centre `(x, z)` | Size | Notes |
|---|---|---|---|---|
| Castle (Tidehall) | Asaru, Ikara, Tudaro | `(0, 0)` | 34 × 30 m on a 48 m mound | entrance turned to `+z`; audience hall unchanged in character |
| Lamp House | Lunira, Korasi, Mira | `(-26, 22)` | 12 × 10 m | living pearl lamps cultivated in open trays |
| School court | Munaja | `(-30, -18)` | 16 × 12 m open court | where the young learn balance before the open sea |
| Reef House workshop | Talisa, Arimu, Kaluja | `(-70, -70)` | 12 × 9 m | specimens, night-reef records |
| Kraken lookout | Ikara | `(-30, 100)` | slender tower 14 m tall | faces the Kraken's route |
| Edge posts | Tudaro | the 105 m edge on each avenue | — | markers where the city ends |

### Homes (sixteen, by household)

| Household | Homes | Row and bearing |
|---|---|---|
| Garden House (Nesaja, Rodasu, Kasuno, Tami) | 3 | inner row, bearings 0° to 45° (`+x` side) |
| Exchange (Maresa, Pelaju, Sujira) | 3 | inner row, bearings 135° to 180° |
| Current House (Oruko, Dakuro, Sekira, Munaja) | 4 | outer row, bearings 180° to 270° |
| Reef House (Talisa, Arimu, Kaluja) | 3 | outer row, bearings 270° to 315° |
| Glassworks (Kunei, Damaku) | 2 | outer row, nearest the main avenue |
| Lamp House family | 1 | inner row, beside the Lamp House |

Homes face the avenue or ring path nearest them, not all toward the centre.

## 7. Landscape

- **Kelp:** tall loose kelp in the garden ring, braided around the homes by
  Kasuno; none in avenues, tunnels' clear zones or the Ring Current.
- **Sea flowers:** Nesaja's beds along the garden ring's warm east side.
- **Coral:** natural reef along the edge beyond 105 m; inside the city only in
  tended beds.
- **Light:** pearl lamps at every door and junction; luminous avenue stones;
  the Glassworks' glow at the head of the main avenue as the first thing
  arrivals see.

## 8. Gameplay requirements

- Swimming routes: avenues 4 m clear, the Ring Current 6 m, and every door
  reachable by swimming.
- Air: the halls and tunnels form one pressurised network (see
  `ocean_sea_folk_city.md`); inside it the hero breathes and walks without a
  helmet.
- The Tidekeeper's audience hall stays open and traversable.
- Protected bounds: the whole city out to 120 m; Fish Goblins stay outside.

## 9. Second pass: the plan file (2026-10-13)

The layout now lives in one plan file. `tools/sea_folk_layout.py` holds the
rings, avenues, air halls, tunnels, every building and home, and the guest
hall's rooms, checks them and writes `scripts/sea_folk_plan.gd`
(`SeaFolkPlan`). `tools/validate_sea_folk_plan.tscn` checks the plan before
the city is rebuilt and runs in the pre-push hook (`VILLAGE=sea_folk`). The
audit found three faults in the first pass, now fixed:

- **The Exchange stood on the main avenue.** At `(0, 34)`, its 18 m dome sat
  across the avenue the castle's new door looks down, blocking both. It moves
  beside the avenue, at bearing 69° on the civic ring, `(12.2, 31.7)`, and the
  castle looks straight down the avenue to the arrivals.
- **The guest hall was too small for its rooms.** Under a 16 m dome, the
  party room, three guest rooms, Isaro's room and the washroom at world scale
  (2.3 m beds) left no floor round the moon pool. It grows to **20 m across,
  8.5 m high**, at bearing 22.5°, `(32.3, 13.4)`, near the old inn's place:
  a ring of rooms 3.4 m deep under the shell, and between them and the 4 m
  moon pool, 4.1 m of common-room floor for the ramp out of the pool and its
  landing.
- **Three light pipes stood in avenues.** (The light pipes were removed in
  the third pass.)

Other placements, all checked:
- the Lamp House at bearing 112.5° and the school court at 157.5° on the civic
  ring, each between avenues;
- the Reef House workshop at 202.5° in the garden ring;
- the Kraken lookout at bearing 112°, 104 m out;
- the Glassworks at the head of the main avenue, 118 m out, beside the warm
  vent at 124 m;
- the sixteen homes in their households' sectors, between avenues, each
  facing the ring path between the rows (the inner row outward, the outer
  row inward);
- the civic tunnel along the ring from the Exchange to the guest hall;
- the avenue tunnel from the Exchange out alongside the main avenue to the
  Glassworks, with its junction moon pool between the rows.

The rings stay circles: Plato's concentric plan is Atlantis's deliberate
civic geometry. Everything beyond the homes is organic: kelp groves and
sea-flower beds as irregular patches in the garden ring, and the city's edge,
where the levelled shelf meets the natural floor and the reef, as a wandering
line.

### What the rebuild changes in `ocean_kingdom_city.gd`

| Today | The plan |
|---|---|
| castle door faces `-z` | faces `+z`, down the main avenue to the arrivals |
| inner homes at 49 m (in the Ring Current's place) | at 60 m; the outer row stays at 82 m |
| homes all face the centre | each faces the ring path between the rows |
| sixteen identical box homes | three home types (single, double, workshop), each household's own |
| eight spokes of stepping stones | eight sunken avenues, 4 m wide, lit by the stones |
| `seafolk_village_inn` at `(24, 18)`, keeper Nerissa Stillwater | the guest hall air hall at `(32.3, 13.4)`, keeper Isaro, still 25 Tokoins |
| prototype names | the Linear A-sounding names (`ocean_sea_folk_city.md` 3a) |
| no Ring Current, air halls or tunnels | all of them (third pass: section 10) |

## 10. Third pass: two eras, heritage under glass, and the column (proposed, 2026-10-13)

The user's direction:
- the sea folk are not bound to the seabed, and the city should use their
  three-dimensional mobility;
- the architecture merges two eras, the classical city preserved and the
  modern city of glass;
- the glass should take up the heritage in considered ways, after the British
  Museum's Great Court and the Singapore National Gallery;
- the bubbles in the water are whole SuperEggs with floors: no domes on
  cables, no legs, no bird-cage ribs, no stalks;
- more glass tunnels, organised as circulation.

The concept is in `ocean_sea_folk_city.md` 2a; this section is the floor plan.
The data and its checks are in `tools/sea_folk_third_pass.py`. The drawings
(key plans, the circulation, building plans and sections) are the Sea Folk
City Floor Plans artifact. Heights are metres above the city floor (−72 m).

**Removed:** the light pipes, and the first draft of this pass (stalks on
cables, air bells moored on cables, lamp lines).

### The floor (classical, with glass brought to the heritage)

| Place | Where | What it is |
|---|---|---|
| Tidehall | centre, on the mound | the palace, wet and unwrapped; nothing modern over the mound at any height |
| The Exchange (wrap) | 67.5°, 33 m | a glass bubble 17.6 × 17 m, 12 m high, over the preserved **Hall of Records** (10 × 6 m), now dry: the archive and Dakuro's charts. Trading floor at 0.6 m round it, gallery at 4.4 m joining the ring tunnel, a ramp between them, a pool lock |
| The guest hall (join) | either side of the 0° avenue, 36 m | the **West** and **East Strangers' Houses** (8.2 × 9.2 m each), preserved and each wrapped in glass, joined by a glass **common room** bridging the avenue at 4.4 m. A swimmer rises into the common room from the avenue below by its pool lock |
| Lamp House | 112.5°, 31 m | classical, wet |
| School court | 157.5°, 30 m | classical colonnade, wet |
| Current House homes (4) and the Lamp House family's home | outer terrace 193° to 257°; 124° at 60 m | classical, wet |
| Ring-tower stumps (4) | 22.5°, 112.5°, 202.5°, 292.5° on the ring path (71 m) | preserved bases of the old ring towers; each holds a trunk's foot and a pool lock |
| The Glassworks | (0, 118) by the vent | the first glass bubble, socketed in the slope, smoked glass, the furnace over the vent |

**Rooms in the Strangers' Houses** (world scale, inside the old walls):

| House | Rooms |
|---|---|
| East | three guest rooms, 3.8 × 3.6 m; Isaro's room, 3.8 × 3.6 m; a central corridor 1.5 m |
| West | the party room, 7.7 × 5.45 m; the washroom, 2.85 × 1.85 m, with a flush toilet, basin and shower (waste to a sealed tank, as before); a linen store |

Each house's wrap holds a switchback ramp (two flights at 32°, 1.4 m wide)
from the old floor at 0.6 m up to the tunnels' level at 4.4 m.

### The glass network

| Tunnel | Route | Level | Carried by |
|---|---|---|---|
| Civic ring | round the open column at 40 m, threading the Exchange and the guest hall | 4.4 m | the classical ring arcade; arches over every avenue |
| Spokes (4) | from the ring out over the Ring Current to the four trunk feet | 4.4 m | the arcade and the old bridges |
| Avenue tunnel | beside the main avenue, from the ring to the Glassworks | 4.4 m | the classical avenue colonnade |
| Trunks (4) | vertical glass shafts 8 m across with a spiral ramp (11.8 m a turn) | 4.4 to 33 m (the lookout's to 57 m) | the ring-tower stumps |
| Crown ring | joining the trunk tops at 71 m from the centre | 30 m | braced between the trunks |

Swimmers pass under every floor-level tunnel with 3.75 m clear. Total tunnel
length about 770 m.

### The column

| Trunk | Bearing | Landing hall and the homes docked to it | Crown hall, 30 m |
|---|---|---|---|
| Garden House | 22.5°, 71 m | 16 m: Nesaja (double), Rodasu (double), Kasuno and Tami (double) | the Walking Room: where Munaja teaches the young to walk on new legs |
| Glassworks household | 112.5°, 71 m | 15 m: Kunei (workshop), Damaku (workshop) | the trunk climbs on to the Kraken lookout, 54 m |
| Exchange household | 202.5°, 71 m | 18 m: Maresa (single), Pelaju (single), Sujira (single) | the Listening Room: Pelaju listens up toward the surface and the ships |
| Reef House | 292.5°, 71 m | 20 m: Talisa (single), Arimu (single), Kaluja (single), Reef House workshop (reef) | the Reef House laboratory: Talisa's specimens, dry |

A landing hall is a glass SuperEgg 14 m across and 8 m tall, threaded on its
trunk, with a walkable ring at least 1.6 m wide round the trunk. Each home is a
wet SuperEgg docked to the hall's rim with a pool lock between them; the Reef
House workshop docks the same way. Crown halls are 12 m across.

### Checks (`tools/sea_folk_third_pass.py`)

- nothing modern over the mound;
- the avenues and the Ring Current open at the floor, with swimmers' clearance
  under tunnels;
- 3 m between volumes that are not joined;
- every tunnel reaches what it joins, at 1:6 or gentler;
- one connected dry network;
- heritage at least 1.5 m inside its glass, with headroom over it;
- every room at its minimum size and inside the old walls;
- every ramp fitting with 2.4 m headroom and clear of the heritage;
- landing halls' walkable rings;
- the trunk ramps' headroom;
- sixteen homes and every resident housed;
- pool locks where swimmers arrive.

On approval this data replaces the second pass in `tools/sea_folk_layout.py`
and `SeaFolkPlan`, and the validator takes the same checks.

## Fixed, proposed and open

**Fixed:** the city centre, floor and flat radius; the castle, homes and
two-ring plan; the existing inn as the city's rest point at 25 Tokoins.

**Proposed:** the castle turned to face arrivals; the ring radii; the Ring
Current; homes moved from 49 m to 60 m; the three air halls and two tunnels;
Isaro as the inn's renamed keeper;
every footprint above.

**Proposed (third pass):**
- the two eras and the heritage moves (wrap, join, graft);
- the glass network and the four trunks in section 10;
- the light pipes removed.

**Open:**
- names for the two eras and the Strangers' Houses;
- the crown halls' programs.
