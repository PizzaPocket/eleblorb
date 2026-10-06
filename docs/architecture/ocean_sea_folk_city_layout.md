# The Sea Folk City: Civic Layout Plan

Status: dimensioned schematic for review (2026-10-06). Read with
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
| Civic ring | 24 to 46 m | the Exchange and guest hall air halls, the Lamp House, the school court, the four light pipes |
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
| Light pipes | Kaluja | civic ring at 40 m, at bearings 0°, 65°, 180° and 300° (measured from `+x` toward `+z`), clear of the air halls and tunnels | 1.6 m shafts rising to floating glass collectors at the surface | daylight piped down; the collectors are visible from boats and the islands |
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

## Fixed, proposed and open

**Fixed:** the city centre, floor and flat radius; the castle, homes and
two-ring plan; the existing inn as the city's rest point at 25 Tokoins.

**Proposed:** the castle turned to face arrivals; the ring radii; the Ring
Current; homes moved from 49 m to 60 m; the three air halls and two tunnels;
the light pipes with surface collectors; Isaro as the inn's renamed keeper;
every footprint above.

**Open:** none blocking.
