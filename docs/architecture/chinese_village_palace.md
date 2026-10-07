# Chinese Village: The Palace and Its Civic Conversion

Status: building brief approved (2026-10-06); audited 2026-10-07 (levels and
ramps, access). It develops section 4.3 of
`chinese_village.md` (palace restructure, approved in outline) into a full
brief for both states. The story behind the two states is approved in
`chinese_village.md` sections 3.8 and 3.9.

## 1. Premise: one shell, two lives

The palace has two states, and both use **the same buildings**:

- **The imperial palace** is the default, before the Royal Chef is defeated.
  Only Emperor Liang Zhen and the Chef live in it. Villagers work there on rota
  by trade.
- **The civic centre** comes after the quest. Tian Bo, now village chief, opens
  its halls, gardens and grounds to everyone. Liang Zhen cooks for the whole
  village in the former Royal Kitchen.

The conversion is a **renovation, not a rebuild.** The walls, roofs, terraces,
openings and routes are identical in both states. Only furnishing, lighting,
doors left open or shut, and a few movable fixtures change. One shell keeps the
build cheap. It is also how real palaces became public: the Forbidden City
became a museum without moving a wall. The village keeps its palace and
changes what it is for.

**The sealing rock leaves the palace.** It is older than the palace and now
stands on Lantern Row (see `chinese_village.md` and the world bible). The
palace's highest point is now the high pavilion's roof finial.

## 2. Scale and character

Liang Zhen is a **small hereditary ruler** of a village of about twenty people,
not an emperor of China. His palace borrows the forms of a Chinese imperial
palace at village scale:
- a south gate;
- a processional axis;
- a hall on a white marble terrace;
- an inner court;
- a garden.

It is the grandest place in the village, but a walk from gate to garden takes a
minute.

### Charter (from `chinese_village.md` 4.2)

- **Roofs:** yellow-glazed tile on the gate, the Throne Hall, the Dining Hall,
  the inner apartments and the high pavilion. The kitchen and service yard use
  local grey tile, because the old yellow glaze stock is nearly gone and was
  only ever spent on the halls that show.
- **Walls:** vermilion.
- **Terraces:** white marble.
- **Structure:** red-lacquered columns on stone bases, and painted bracket sets
  (*dǒugǒng*) under the eaves, built from stacked squarish blocks.
- **Roof rank, highest to lowest:**
  1. double-eave hip (*wǔdiàn*): the Throne Hall only;
  2. double-eave pyramidal (*cuánjiān*): the high pavilion;
  3. single-eave hip-and-gable (*xiēshān*): the gate, the Dining Hall and the
     apartments;
  4. overhanging gable (*xuánshān*): the kitchen and the stores.
- **Swept eave corners:** use the swept-roof prototype planned for the Sky
  Kingdom (see the settlement backlog). If it fails, the fallback is a straight
  hip with raised corner finials.

## 3. Plan

Local frame: the palace island's centre is `(0, 0)`, radius 62 m. `+z` is
south, toward the gate island and the axial bridge. The axis runs along `x = 0`.

```
                       N (-z), over the Abyss
              ┌────────── royal garden ──────────┐
              │   moon-gate court   pond+pavilion │
              │          HIGH PAVILION (+9.8)     │
              │   rock garden    bamboo court     │
              ├───────────────────────────────────┤
  apartments  │        INNER COURT (+5.6)         │  ROYAL KITCHEN (0)
  (west wing) │                                   │  Chef's quarters
              ├────── THRONE HALL (+4.2) ─────────┤  service yard
              │     three-tier marble terrace     │  ─── bridge to B
              │        DINING HALL (east)         │
              ├────────── FRONT COURT (0) ────────┤
              │           GATE PAVILION           │
              └───────────────┬───────────────────┘
                              │ axial bridge, 5 m
                       S (+z), to the gate island
```

| Element | Centre | Size | Level | Roof |
|---|---|---|---|---|
| Bridge landing apron | `(0, 58)` | 8 × 6 m | 0 | — |
| **Gate pavilion** | `(0, 50)` | 16 × 8 m, three bays, on a 1.2 m stone base with a ramp front and back | 0 / +1.2 | single-eave *xiēshān*, yellow |
| **Front court** | `(0, 34)` | 40 × 24 m, paved, axis of white stone | 0 | — |
| **Throne terrace** | `(0, 4)` | 46 × 36 m, three tiers of 1.4 m with marble balustrades; central ramp in three flights, 3.2 m wide, ≤32°, with a landing on each tier | +4.2 | — |
| **Throne Hall** | `(0, 2)` | 28 × 16 m, seven bays by five, 8 m to the eaves | +4.2 | double-eave *wǔdiàn*, yellow; the tallest roof on the island |
| **Dining Hall** | `(28, 34)` | 16 × 9 m, just east of the front court, facing west onto it | 0 | single-eave *xiēshān*, yellow |
| **Inner court** | `(0, -24)` | 36 × 14 m, paved, 1.4 m above the throne terrace (not "one step": revised by the audit, 2026-10-07): reached by a short ramp flight either side of the Throne Hall, 3.2 m wide, 32°, about 2.2 m of run with a 1.2 m landing at each end, inside the terrace's 8 m strip behind the hall | +5.6 | — |
| **Inner apartments** | `(-26, -24)` | 14 × 20 m, west wing on the inner court, door facing east | +5.6 | single-eave *xiēshān*, yellow |
| **Royal Kitchen** | `(32, -22)` | 18 × 12 m on the east, at ground level, reached from the inner court by a ramp down along the court's east edge (5.6 m rise in two flights: about 9 m of run, a 1.2 m mid landing and landings at both ends, about 12.6 m in all, within the court's 14 m depth), landing at the kitchen's west door; and from the service yard | 0 | *xuánshān*, grey |
| **Chef's quarters** | `(32, -34)` | 8 × 6 m, behind the kitchen | 0 | *xuánshān*, grey |
| **Service yard** | `(49, -6)` | 16 × 20 m, packed earth, a well, the levy store (10 × 6 m), a latrine closet, a cart turn; its own landing from island B's bridge on the east rim | 0 | store: *xuánshān*, grey |
| **High pavilion** | `(0, -42)` | 10 × 10 m, two storeys, on a rock-and-marble mound at the head of the axis, overlooking the Abyss, 4.2 m above the inner court, reached by a switchback ramp of two 2.1 m flights (about 3.4 m of run each, with landings) on the mound's south face; interior ramp 5.2 m run | +9.8 / +13.0 | double-eave *cuánjiān*, yellow, gilded finial |
| **Royal garden** | north and north-west, `z` -34 to -58 | the four framed views from `chinese_village.md` 4.4: moon-gate court with a pomegranate, pond with a zigzag bridge and a small pavilion, rock garden, bamboo screen and bench court | 0 to +5.6, stepped | small pavilion: *cuánjiān*, yellow |

Routes are wide enough for the party, Blorbus and a mount everywhere:
- the axis is 5 m;
- terrace and kitchen ramps are 3.2 m;
- garden paths are 2 m.

Every ramp has a 1.2 m landing at its foot and head.

## 4. Two states, room by room

| Space | Imperial palace (default) | Civic centre (after the quest) |
|---|---|---|
| **Gate pavilion** | Leaves shut except when an audience is granted. Lanterns lit by Lian Fu on the palace's schedule. | Leaves **always open**, pinned back. A painted notice board under the eave carries symbols only (market days, the next shared meal). Lanterns lit every night. |
| **Front court** | Bare and swept. Two bronze water vats for firefighting at the corners. The 14 lanterns in two ceremonial rows. | The village's square. The vats stay. Benches under the eaves; a chalk hopscotch grid near the gate where the children play; festival lantern strings across the court; on meal nights, tables spill out from the Dining Hall. |
| **Throne terrace** | Empty marble, too grand to linger on. | The same marble, now a place to sit on the balustrade steps and look south over the village. |
| **Throne Hall** | The **audience hall**. Liang Zhen's throne on a three-step dais under a carved screen; a long empty floor where petitioners kneel; censers and tall lanterns; doors kept half shut, so the hall is dim. Liang Zhen receives the hero here. | The **village hall**. The dais stays as a speaking platform, but the throne is gone and Tian Bo's plain chair stands at floor level in front of it. Long benches in a horseshoe for meetings, a table for the records under the windows, a vase of fresh bamboo culms from Tian Bo's grove. All doors open, so the hall is bright. The carved screen stays as the village's heritage. |
| **Dining Hall** | Liang Zhen's **private dining hall**: one table, one chair, the rejected bao trials sent back to Hua Chen, an empty hall for one diner. | The **communal dining hall**: long tables and benches for the whole village, a serving hatch through to the kitchen route, lanterns low over the tables. Liang Zhen serves here. |
| **Inner apartments** | The **Emperor's rooms**: bedchamber, study with the levy ledgers, robe room with the ceremonial crown on its stand. | **Records and meeting rooms.** The bedchamber becomes a small meeting room with a table and six chairs. The study becomes the **records room**: the old levy ledgers kept on a shelf as a lesson, beside the new village records. The robe room becomes a **reading and teaching room** for the five children, with low tables and slates. The crown stays on its stand in a niche, a relic nobody wears. |
| **Royal Kitchen** | The **Chef's kitchen**: working hearths, bronze pots, bamboo steamers, shelves and preparation counters around a **clear fight floor** of at least 12 × 8 m. The long counter where captured blorbs sit shrunk as buns. | The **community kitchen**: the same hearths and counters, busy. The long counter becomes the serving counter, piled with steamers. Hua Chen's bao on a rack, then (over later visits) her apron on a peg beside Liang Zhen's. The fight floor holds a long prep table, moved aside on the plan so its shell stays the same. |
| **Chef's quarters** | The Chef's sparse room: a narrow bed, a locked chest, nothing personal. | **Liang Zhen's home.** The former Emperor lives in the cook's room behind his kitchen: a bed, a shelf of recipe notes, a pot of herbs on the sill. |
| **Service yard** | Levy carts unloading flour and beans; the levy store full and locked; the well; the latrine closet. | The levy store becomes the **village store**, kept for lean seasons, its door unlocked. The well and latrine stay. Bo Xiang's cart still turns here. |
| **High pavilion** | The Emperor's **private viewing pavilion**: a single chair facing north over the Abyss, a tea table, closed to everyone else. | A **public lookout**. Benches on both floors facing out; children fly kites from the upper gallery. |
| **Royal garden** | Immaculate and empty; the moon gate shut. | Open, used and a little less immaculate: Tian Bo has planted a clump of bamboo in the bamboo court, and there is a bench where Liang Zhen and Hua Chen sit on later visits. |

### Movable fixtures that differ between states

The doors and gates (open or shut), the throne, the hall's furnishing, the
dining tables, the kitchen counter dressing, the apartment furnishing, the
notice board, the benches, the kite and festival lanterns, and the moon gate
leaf. Every one is a prop placed by quest state. **No wall, roof, terrace or
opening changes.**

### Audit (2026-10-07)

Checked against the architecture skill's brief audit.

- **Levels and ramps.** Every change of level now names its ramp:
  - the gate base: 1.2 m, front and back;
  - the throne terrace: three 1.4 m flights. At 32° each needs about 2.2 m of
    run plus a landing, about 11.5 m in all, which fits the 12 m between the
    terrace's front edge and the hall.
  - the inner court: 1.4 m, previously called "one step";
  - the kitchen descent: 5.6 m;
  - the high pavilion's mound: 4.2 m.
- **Sizes.** The kitchen (18 × 12 m) holds its 12 × 8 m fight floor with
  counters round it. The footprints were already moved apart in the first
  pass.
- **Access and pass-throughs:**
  - The inner court is reached by the side ramps round the Throne Hall, not
    through it.
  - The Chef's quarters, later Liang Zhen's room, open off the kitchen: a
    cook's room off his own kitchen, which is legitimate.
  - The Emperor's bedchamber, study and robe room open into one another. They
    are his own suite, which is legitimate. For the civic state, each of the
    three rooms has its own door onto the inner court's gallery **in both
    states**, because openings never change between states. In the imperial
    state the Emperor keeps the outer doors shut and uses the doors between
    the rooms; in the civic state the outer doors stand open, so the public
    never passes through one room to reach another.
  - The Dining Hall is entered from the front court.
- **Headroom and frames.**
  - Gallery and eave heights follow the hall storeys, at 2.4 m or more.
  - Door leaves sit in full bays between columns, never in a bay with a
    window.

## 5. Systems

- **Fire:** the kitchen hearths only, on a stone floor, with a masonry chimney
  through the grey roof. The bronze water vats in the front court are for
  firefighting, as in real palaces.
- **Water:** a well in the service yard; rain from the roofs drains to the
  garden pond.
- **Sanitation:** a latrine closet in the service yard: a bench seat over a
  removable vat, emptied to the fields. The inner apartments have a lidded
  commode (*mǎtǒng*) behind a screen in the imperial state.
- **Light:** lanterns along the axis and in the halls. In the civic state more
  of them are lit, and longer into the night.
- **Collision:** walls, columns, terraces, balustrades, vats and the pavilion
  are solid. The terraces' tops and the balustrade caps are parkour surfaces.
  Bracket sets and roof ornaments are decorative.

## 6. Style audit

| Element | Term | Tradition |
|---|---|---|
| Gate, halls, pavilion | timber-frame halls on stone bases, bays between columns | Chinese palace architecture |
| Roofs | *wǔdiàn*, *xiēshān*, *cuánjiān*, *xuánshān* | Chinese roof hierarchy |
| Terrace | three-tier white marble podium with balustrades | Chinese palace terrace (*xūmízuò*) |
| Brackets | *dǒugǒng* | Chinese |
| Garden | moon gate, zigzag bridge, rock garden | Chinese garden |
| Vats | bronze fire-water vats | Chinese palace |

One tradition throughout.

**Exclusions:** the sealing rock (now on Lantern Row); Buddhist or Daoist
shrines, altars and statues; dragons on anything but the throne screen; legible
inscriptions; a copied real building.

## Fixed, proposed and open

**Fixed:**
- the island, the axial bridge and the service bridge from B;
- the palace's two states and their story (approved);
- Liang Zhen's audience, the kitchen fight with its clear floor and bun
  counter, and the community kitchen;
- the yellow glaze reserved for the palace.

**Proposed:**
- the plan;
- the Dining Hall;
- the four levels (gate court, throne terrace, inner court, high pavilion);
- the roof hierarchy, including grey tile on the service buildings;
- every room's use in both states;
- Liang Zhen living in the Chef's quarters afterward;
- the children's reading and teaching room.

**Open:** none blocking.
