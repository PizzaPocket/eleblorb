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

## 10. Third pass: the vertical city (proposed, 2026-10-13)

The user's direction: the sea folk are not bound to the seabed, and the city
should use their three-dimensional mobility. Its architecture should merge two
eras, the classical city preserved on the floor and the modern city of air
bells and pods risen into the water column. All of it stays in the SuperEgg
language. The concept is in `ocean_sea_folk_city.md` 2a; this section places
it. Heights are metres above the city floor (−72 m); the surface is at +72.

**Removed:** the four light pipes and their surface collectors. Kaluja becomes
the rigger of the stalks.

### Depth bands

| Band | Height | What is there | Era |
|---|---|---|---|
| The floor | 0 to 20 m | Tidehall (towers to 19 m), the Ring Current, the avenues, the Lamp House, the school court, the Current House homes, the Glassworks at the vent, kelp forests rising to 30 m | classical; the Glassworks is the hinge |
| The low column | 8 to 34 m | household stalks and their pods; the lamp-line ring at 20 m | modern |
| The air level | 30 to 40 m | the Exchange and the guest hall, air bells with their pools at 30 m, and the glass tunnel between them | modern |
| The high column | 40 to 64 m | crown floats; the Kraken lookout's watch pod at 56 m | modern |
| Above | 64 to 72 m | open water to the surface | — |

The open column: nothing modern stands over the mound (within 24 m of the
centre) at any height, so Tidehall's oculus looks up a clear well of water.

### Stalks

Every holdfast stands on the ring path (71 m) between avenues, at bearings
22.5° + 45° steps, except the lookout's at the edge. Pods hang 2.5 m off their
stalk, turned to face the open side.

| Stalk | Bearing, radius | Pods (height) | Crown float | Who |
|---|---|---|---|---|
| Garden House | 22.5°, 71 m | three double pods (10, 17, 24 m) | 38 m | Nesaja, Rodasu, Kasuno and Tami |
| Glassworks household | 67.5°, 71 m | two workshop pods (9, 15 m) | 26 m | Kunei, Damaku |
| Kraken lookout | 112.5°, 100 m | the watch pod (56 m), a glazed egg facing south over the Kraken's water | 64 m | Ikara |
| Exchange household | 157.5°, 71 m | three single pods (12, 18, 25 m) | 36 m | Maresa, Pelaju, Sujira |
| Reef House | 292.5°, 71 m | three single pods (10, 16, 22 m) and the Reef House workshop pod (30 m, 12 × 9 m) | 44 m | Talisa, Arimu, Kaluja |
| Lamp stalks | 112.5° (71 m), 202.5°, 247.5°, 337.5° | none; they carry the lamp-line ring | 26 m | Lunira's lamps; Kaluja rigs them |

Pod sizes are the second pass's home types (single 8 × 7 m, 5 m tall; double
two eggs of 6 × 6 m; workshop a 7 × 8 m resting egg and a 6 × 7 m work egg).
Pods on one stalk keep 3 m clear of one another vertically.

### On the floor

| Building | Where | Change from the second pass |
|---|---|---|
| Tidehall | centre | its oculus is open to the clear column above |
| Lamp House and the Lamp House family's home | 112.5° on the civic ring and inner terrace | stay on the floor: classical, the oldest craft |
| School court | 157.5° on the civic ring | stays: a classical colonnade |
| Current House homes (four) | outer terrace, 193° to 257° | stay on the floor beside the current they work: the city's oldest family, in classical homes |
| Glassworks | (0, 118) by the vent | stays; no longer joined by a tunnel |
| Garden, Exchange, Reef and Glassworks households' homes (eleven) | — | move up into pods on their stalks |
| Reef House workshop | — | moves up into a pod on the Reef House stalk |
| Avenue tunnel | — | removed: the Glassworks' pool lies 27 m deeper than the air level's |

### Air level

- **The Exchange** at `(12.2, 31.7)` and **the guest hall** at `(32.3, 13.4)`,
  as in the second pass, now buoyant bells with their open rims and pools at
  30 m.
- Each hangs on four cables to holdfasts on the civic ring floor.
- The **civic tunnel** joins them level, at 30.6 m floor height.
- The hero rests 42 m below the surface instead of 72 m.

### What the plan file gains when this is approved

`SeaFolkPlan` holds the second pass less the light pipes. On approval it gains
a height for every structure, the stalks with their holdfasts, pods and crown
floats, the air level, and the lamp-line ring. The validator then also
checks:

- the open column over the mound;
- that every holdfast stands on a classical ring or beside an avenue;
- 3 m clearance in three dimensions between pods, bells, cables and floats;
- that tunnel-joined bells share one pool depth;
- that nothing in the column stands on the floor except at a holdfast.

## Fixed, proposed and open

**Fixed:** the city centre, floor and flat radius; the castle, homes and
two-ring plan; the existing inn as the city's rest point at 25 Tokoins.

**Proposed:** the castle turned to face arrivals; the ring radii; the Ring
Current; homes moved from 49 m to 60 m; the three air halls and two tunnels;
Isaro as the inn's renamed keeper;
every footprint above.

**Proposed (third pass):** the two eras and the vertical city in section 10;
the light pipes removed.

**Open:** names for the two eras, if the sea folk have them.
