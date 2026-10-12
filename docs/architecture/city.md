# The City: settlement plan (first real pass)

Status: survey, community brief and settlement concept, for review
(2026-10-12). The current city is a prototype. This pass replaces it with a
city built at real building sizes. Coordinates follow once the concept is
approved (settlement-design stage 4).

## 1. What exists now (survey)

From `scripts/city_generator.gd`, `terrain_generator.gd`, `town_props.gd` and
the world bible.

- **Site.** Centred at world (−540, 0), off the main plateau on the gorge-floor
  wasteland at about −60 m. The flat pad has a radius of 78 m (18 m
  transition), about 156 m across. Beyond it the wasteland floor varies by
  only ±2.4 m. The nearest features:
  - the main plateau's rim, about 300 m east;
  - the Ice plateau, about 490 m away;
  - the Jungle plateau, about 470 m away;
  - the world's skirt, 870 m from the origin.
- **Streets.** Three avenues and two cross streets, each 8 m wide with 2.6 m
  sidewalks.
- **Buildings.** 24 towers in 12 blocks, 6 to 20 floors, on footprints of 2–4
  by 2–3 building cells: **6.4 to 12.8 m wide**. A real tower of that height
  stands on 25 to 40 m.
- **Other built features:**
  - six skybridges between paired towers;
  - fire escapes, balconies and AC units on the facades;
  - lit windows, room lights switched by distance;
  - a far "skyline" level of 24 plain boxes, visible from up to 720 m.
- **People.** 12 named residents with two lines each: Juno Rell, Kade Morrow,
  Suri Vale, Tomas Wren, Nia Calder, Orin Pike, Mara Quill, Venn Harlow,
  Iris Dune, Sol Brant, Pia Rowe and Dax Merrow. They are placed on a grid
  and have no homes or jobs.
- **Shop.** The **Helmsmith**, a helm vendor (shop category "city") in a
  painted ground-floor shop.
- **Bible.** "The outskirts city": a full-scale avenue grid. Wild **City
  blorbs** live in its streets, and a **City Gem** is hidden among them (placed
  by `wilderness_scatter.gd`). It has no gate, and the old City Kingdom gate
  was removed.
- **No rest point.**

### Non-regression requirements

- City blorbs and the City Gem in the streets.
- The Helmsmith and the "city" shop.
- The 12 residents' names (their roles and lines are revised below).
- The skyline seen from the plateau.
- The distance-based wake and sleep of the detailed city, which is a
  performance requirement.
- Skybridges and elevated routes, as traversal the prototype offers, unless
  the user drops them.

## 2. Lore introduced (user, 2026-10-12)

- **The Middle of Nowhere** will be a new location, its own scene: farmland,
  and a piece of the hero's backstory. It is where the hero, who woke with
  amnesia, finally learns where his hometown is.
  - His **grandmother** lives there.
  - His cousin **Jammer**, a little kid, is visiting her.
- **Jammer's parents live and work in the city.** His mother is a **lawyer**
  and his father is a **tech recruiter**.
- The city's **rest point** is a grand hotel.
  - **Interior:** a big atrium, a revolving door and a giant chandelier.
  - **Precedent:** the large hotels of China.
- The city will have the civic buildings a city has, starting with a
  **library**.
- **Scale and fidelity.** The city is built at real building sizes. Not every
  floor of every building is realised, but the architecture gains much
  better fidelity.

## 3. Scale and fidelity

### Real sizes, at the world's scale

The world is built at about 1.1 × real size: doors 2.4 m, storeys 3.25 m, the
hero about 1.9 m. City buildings follow the same rule: real dimensions × 1.1,
on the 3.2 m building cell.

| Element | Real | In the city (×1.1, rounded to the cell) |
|---|---|---|
| Residential storey | 3.0 m | 3.25 m |
| Office storey | 3.6 to 4.0 m | 4.0 m |
| Lobby, atrium base | 6 to 9 m | 6.5 to 9.75 m (two to three storeys) |
| Residential tower footprint | 22 × 32 m | 25.6 × 35.2 m (8 × 11 cells) |
| Office tower footprint | 32 × 32 m | 35.2 × 35.2 m (11 × 11 cells) |
| Mid-rise mixed-use block | 30 × 55 m | 32 × 60.8 m |
| City block, kerb to kerb | 80 × 100 m | 89.6 × 108.8 m |
| Avenue | 27 m (four lanes, two 5 m sidewalks) | 28.8 m |
| Street | 18 m (two lanes, two 4 m sidewalks) | 19.2 m |
| Sidewalk | 4 to 5 m | 4.8 to 5.6 m |

### Three levels of fidelity

Not every floor is built. Each building gets one of three levels.

| Level | What is built | Which buildings |
|---|---|---|
| **A. Realised** | Every floor that has a job in play: rooms, furniture, people and light, with full collision. Elevators run between the realised floors and the lobby. | The grand hotel (atrium, lobby, one guest corridor and the party's suite); the library (all public floors); the Helmsmith; the law firm's floor; the recruiting firm's floor; Jammer's family's apartment; the café; city hall's council chamber; the station hall |
| **B. Street** | The ground floor as a real room (a shop, lobby or café) or, where nothing happens, a shallow shopfront room 4 to 6 m deep behind glass. Upper floors are facade only, with lit windows that look like rooms. | Most of the city's ground floors |
| **C. Skyline** | Massing with real proportions and a real window grid; no interior. Collision on the base, and on roofs and ledges only where a traversal route uses them. | Towers behind the street wall, and the far skyline |

**Windows that look like rooms.** A lit window shows a room behind it without
modelling one: an "interior mapping" shader draws a room box (back wall,
floor, ceiling, a lamp and a silhouette) in the glass. This one technique
gives every facade believable depth at almost no cost. Prototype it first.

**Facade fidelity**, for every building:
- **Composition:** a base, a middle and a top. The base is a podium of shops
  and lobbies, two storeys high. The middle is the shaft of repeated floors.
  The top is a crown of plant screens, setbacks or a lit cap.
- **Real window grid:** about 1.6 m bays, mullions, spandrels and floor
  edges.
- **Entrances:** canopies, recessed entries, real door widths.
- **Corners:** rounded with superellipse radii, in the game's design language.

## 4. Community (proposed census)

A city has crowds. The census names the people who have a home, a job and
lines. Unnamed **passersby** walk the sidewalks for life and density: they
have no dialogue, live only near the player, and never stand in a doorway.

### Named residents

| Resident | Place | Role | From their existing lines |
|---|---|---|---|
| **Jammer's mother** (name open) | the law firm's floor; the family's apartment | **lawyer** | new |
| **Jammer's father** (name open) | the recruiting firm's floor; the apartment | **tech recruiter** | new |
| **Hotel manager** (name open) | the grand hotel | keeps the rest point | new |
| **Concierge** (name open) | the hotel's atrium desk | knows the city; points people places without explaining mechanics | new |
| **Doorman** (name open) | the revolving door | greets arrivals | new |
| **Head librarian** (name open) | the library | runs it | new |
| **The Helmsmith** | the helm shop | vendor (kept) | existing |
| **Nia Calder** | the library's map room | city archivist | counts the towers, reads old maps |
| **Juno Rell** | a residential tower | building superintendent; lives on the twentieth floor and takes the stairs | "Twenty floors and I still take the stairs" |
| **Kade Morrow** | city works | skybridge and structures inspector | knows every tower's creak |
| **Suri Vale** | the towers' facades | window cleaner on a gondola | loves the lit windows; "nobody looks up" |
| **Tomas Wren** | the streets | courier | runs deliveries floor to floor |
| **Orin Pike** | the city park | park keeper | the sky does what it wants |
| **Mara Quill** | the library's reading room, the café | novelist | "people say this place mirrors something" (keeps the mirror-world hint) |
| **Venn Harlow** | the law firm | paralegal, who works for Jammer's mother | same commute, same fifteen floors |
| **Iris Dune** | the hotel's lobby | florist with a flower stand | keeps a plant alive on the eleventh floor |
| **Sol Brant** | the café | runs the breakfast café; up before the sun | the towers block the sunrise |
| **Pia Rowe** | the plaza | busker | likes the noise at street level |
| **Dax Merrow** | a residential tower's lobby | leasing agent | moved six times, for the view and the rent |

That is 19 named residents. Lines that mention the removed gate (Juno's
second, Mara's first and Dax's second) are rewritten in the dialogue pass,
to the `npc-dialogue` skill. Jammer himself is in the Middle of Nowhere, not
the city.

### The needs, and who meets them

| Need | Who | Where |
|---|---|---|
| Hospitality and the rest point | the hotel manager, concierge and doorman | the grand hotel |
| Knowledge, records and maps | the head librarian, Nia Calder | the library |
| Governance | city hall (council and clerk; names open, or kept off-screen) | city hall |
| Maintenance | Juno Rell, Kade Morrow, Suri Vale | the towers, the skybridges, the facades |
| Food | Sol Brant's café, street food | Commerce Street, the plaza |
| Exchange | the Helmsmith; the shops | Commerce Street |
| Green space | Orin Pike | the city park |
| Work | the law firm, the recruiting firm, offices | the office towers |
| Homes | the residential towers; Jammer's family's apartment | the residential quarter |
| Arrival and departure | the station | the east edge |

## 5. Settlement concept

### Site and size: the city needs room

At real sizes, the present 156 m pad holds about one city block. The program
needs about **115,000 m²**:

| | m² |
|---|---|
| Grand hotel podium | 3,300 |
| Library | 4,400 |
| City hall | 3,500 |
| Central plaza | 6,000 |
| City park | 15,000 |
| Station | 3,000 |
| Six office towers | 7,400 |
| Ten residential towers | 9,000 |
| Ten mid-rise blocks | 18,000 |
| Market hall | 2,500 |
| Garage | 2,000 |
| **Sum** | **about 74,000** |

Divided by 0.65 for streets and the gaps between buildings, that is about
114,000 m².

**Proposal:** widen the flat pad to a radius of **240 m** (30 m transition),
about 480 m across, with about 160,000 m² usable inside a 10 m edge.
- The centre can move a little west, to about (−560, 0), so the east edge
  keeps 60 m clear of the plateau's rim.
- It stays inside the world's skirt, and clear of the Ice and Jungle
  plateaus.
- The gorge floor is already within ±2.4 m of flat there, so the terrain
  change is just the larger radius.

### Districts (schematic; dimensions follow approval)

```
                         N
     ┌──────────────── residential quarter ────────────────┐
     │  towers on podiums · Jammer's family · the park     │
     │      ┌─────── CITY PARK ───────┐                    │
     ├──────┤  lawns, trees, pond,    ├──── offices ───────┤
     │      │  playground, Orin       │  law firm tower    │
     │      └─────────────────────────┘  recruiting firm   │
W    │  Commerce St: Helmsmith,    ┌── CENTRAL PLAZA ──┐   │   E → station,
     │  café, market hall, shops   │ city hall (north) │   │   the road back
     │                             │ LIBRARY (west)    │◄──┼── to the plateau
     │                             │ GRAND HOTEL (east)│   │
     │                             └───────────────────┘   │
     └──── service edge: garage, depot, service lanes ─────┘
                         S
```

- **Arrival.** The way in comes from the east, the plateau's side. A
  **station** and its forecourt stand at the east edge. From there **Grand
  Avenue** (28.8 m) runs west to the central plaza, so the first view is
  down the avenue to the plaza, with the hotel's tower rising on its right.
- **The public heart: the central plaza**, about 75 × 80 m: paving, a
  fountain or water feature, trees, benches and the busker's spot.
  - **City hall** on its north side.
  - The **library** on its west side.
  - The **grand hotel** on its east side, facing the plaza and the avenue.
- **Offices** to the north-east: the law firm's tower and the glass tower
  of the recruiting firm.
- **The city park** to the north: lawns, tree groves, a pond, a playground
  and paths. It is the city's lung, kept by Orin Pike.
- **The residential quarter** to the north-west and west: towers on
  shop-lined podiums, mid-rise blocks, and Jammer's family's apartment
  overlooking the park.
- **Commerce Street** to the west and south-west: the Helmsmith, Sol's café,
  the market hall and shops. It is the street-life spine, with the most
  Level B ground floors.
- **The service edge** to the south: the garage, a depot, service lanes,
  deliveries.
- **Skybridges.** Proposed to join the hotel's podium to the office towers
  and two residential towers, as a deliberate elevated route rather than six
  scattered spans. Kade inspects them.

### Routes and edges

- Grand Avenue runs east–west into the plaza.
- Two north–south avenues frame the plaza.
- Streets complete blocks of about 90 × 110 m, and service lanes run behind
  the podiums.
- The city's edge is a ring road with the open wasteland beyond. The skyline
  reads from the plateau.
- Vehicles: see the open questions.

## 6. The grand hotel (rest point), outline

The full building brief follows the layout, through the architecture
skill.

- **Precedents, from great Chinese hotels:**
  - **White Swan Hotel, Guangzhou (1983):** a soaring atrium with an indoor
    rock garden, waterfall and pavilion, "Homeland Waters". It gives the
    atrium a landscape at its heart.
  - **Peace Hotel, Shanghai (1929, art deco):** an octagonal lobby under a
    great glass-and-bronze chandelier and lantern dome. It gives the
    chandelier and the deco finish.
  - **Grand Hyatt, Jin Mao Tower, Shanghai:** a vast cylindrical atrium rising
    through the hotel's floors, with ring galleries. It gives the guest
    floors looking down into the atrium.
- **Size:**
  - a podium about 66 × 50 m;
  - an **atrium about 33 × 26 m, rising about 26 m** (eight floors of guest
    galleries);
  - a guest tower above, about 33 × 55 m and some 25 floors.

  It is the city's tallest landmark after the office towers.
- **Arrival:**
  - a **revolving door** (a drum about 3.3 m across, world scale) flanked by
    swing doors for the party and big companions;
  - a porte-cochère canopy;
  - the doorman.
- **The atrium:**
  - a polished stone floor;
  - the **giant chandelier**, about 8 m across, hanging some 12 m down from
    the skylight;
  - a rock garden with a waterfall and a pavilion, after the White Swan;
  - the reception desk;
  - the concierge;
  - Iris's flower stand;
  - lounge seating;
  - a grand double ramp to the mezzanine instead of a staircase, by the
    world's ramp rule.
- **Realised floors:** the atrium, the mezzanine (a restaurant), and one
  guest gallery with the party's suite as the wake room. The suite has one
  bed, at the world's bed size. Elevators run between them.
- **Toilets:** a modern culture, so modern fixtures. Washrooms are off the
  atrium, and the suite has its own bathroom.

## 7. The library, outline

- **Precedents:**
  - **Tianjin Binhai Library (2017):** a white terraced atrium, its walls
    stepped bookshelves around a luminous sphere. The stepped shelves are
    also ideal parkour.
  - **The Rose Reading Room, New York Public Library:** a great double-height
    reading room with long tables and lamps.
- **Size:** about 66 × 66 m, five storeys.
- **Inside:**
  - a central terraced atrium of stepped shelving, climbable (parkour
    landings);
  - a great reading room on the top floor;
  - a children's library;
  - a map room for Nia Calder;
  - the librarian's desk.
- **Faces the plaza** on its west side.

## 8. Other city buildings (proposed list)

- **City hall:** a council chamber and a clerk's hall, with a clock tower on
  the plaza.
- **The station:** the arrival hall and forecourt.
- **The market hall:** food stalls, Commerce Street's anchor.
- **The law firm** and the **recruiting firm:** one realised office floor
  each.
- **Residential towers:** the lobby, Juno's office, Dax's leasing desk, and
  Jammer's family's apartment (realised).
- **The park:** the pond, a playground, a band shell for Pia.
- **Street furniture:** street lamps, benches, bins, bus shelters, trees in
  tree pits, newsstands, phone booths (pictures only, no text), and fire
  hydrants.

## 9. Engine and performance

- Keep the existing two levels: the skyline far away, the detailed city
  near. Stream the detailed city **block by block**.
- Merge each building's static parts (`StaticMerge`, as the fishing village
  did) and instance repeated windows, mullions and street furniture.
- Interiors build only for realised (Level A) floors, and only when the
  player is in or near the building. Passersby simulate only near the
  player.
- `scene_cost_probe` targets for the city before any detail.

## 10. Fixed, proposed and open

**Fixed (user, 2026-10-12):**
- the city is rebuilt at real building sizes, with Levels A, B and C of
  fidelity, so not every floor is realised;
- the rest point is a grand hotel with an atrium, a revolving door and a
  giant chandelier, inspired by large Chinese hotels;
- a library;
- Jammer's parents live and work in the city: his mother a lawyer, his father
  a tech recruiter;
- the Middle of Nowhere as a future scene (farmland, the hero's grandmother
  and his cousin Jammer, the hero's hometown revealed).

**Proposed:**
- the site widened to a radius of 240 m;
- the scale table;
- the three fidelity levels and the window shader;
- the census of 19, with roles for the existing 12;
- unnamed passersby;
- the districts, Grand Avenue and the central plaza with city hall, the
  library and the hotel;
- the station as arrival;
- the skybridges consolidated into one elevated route;
- the hotel and library outlines and their precedents.

**Open:**
- **Names:** the city's name, Jammer's parents' names (and which of them is
  the hero's blood relative), the hotel staff's and the librarian's.
- **Vehicles:** parked cars only, moving traffic, or none. Roads 28.8 m wide
  with nothing on them read as empty.
- **What the station connects to:** the world has no trains yet.
- **The hotel's price** as a rest point.
- **How the city points toward the Middle of Nowhere:** for example, Jammer's
  parents mention their son is at his grandmother's.
- **Whether the skybridges stay.**
