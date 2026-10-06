# Sky Kingdom: Architecture Briefs

Status: building briefs for review (2026-10-06). Read with `sky_kingdom.md`
(people, materials, charter) and `sky_kingdom_layout.md` (positions,
footprints, programs). This document fixes each building's form. Interiors
and planting follow with the `interior-design` and `landscaping` skills.

## 1. Kit of parts

The charter's split between Greco-Roman (about 55 percent) and Chinese
celestial palace (about 35 percent) is held together by this closed kit. Every
building uses only these parts. No building combines both traditions' roof and
wall systems.

### Shared invariants (every building)

| Element | Term | Specification |
|---|---|---|
| Structural module | bay | 3.2 m (`TownProps.CELL_SIZE`) between column centres |
| Base | stepped podium (crepidoma in the Greco-Roman buildings, *taiji* platform in the Chinese) | set cloud with a gold edge band, 1.0 m per tier; tier count shows rank; one-way from below |
| Columns | pier with capital and base | squarish SuperEgg quartz shaft (`EPSILON_FLAT`), 0.7 m on halls, 0.45 m on tholoi and pavilions; gold capital and base blocks |
| Floating roof | — | roof hovers clear above its columns: 0.6 m on ordinary buildings, 1.0 m on a court's principal building, 1.6 m on the Hall of Mist |
| Roof anchor | gold pins | a short gold finial on each capital and a matching pendant under the roof, aligned, with a faint glow between them |
| Signature motif | gold binding ring | the ring that holds set cloud: at every column neck, every roof corner, every couch and every gate; never decoration alone |
| Openings | superellipse arch, oculus | punched through quartz screen walls and framed in gold on both faces |
| Enclosure | screen wall, cloud panel, curtain | quartz screen walls only where privacy or storage requires; translucent set-cloud panels in gold frames for light partitions; woven-cloud curtains for doorways and between columns |
| Floors | — | set cloud inside, on podiums, terraces and ramps; bank cloud outside; every floor one-way from below |
| Light | — | gold vessels and quartz that glow after dusk; no lanterns on posts |
| Palette | 60/30/10 | quartz and cloud white / sky pastels on woven cloud / gold |

### Greco-Roman parts (Aethra's minor buildings, Koinon, Chrysa, Lyria, Dromos)

| Element | Term | Specification |
|---|---|---|
| Roof, rectangular | low gable with pediment ends | one pitch band, 14° to 16°; quartz slab with a gold edge |
| Roof, round | dome | SuperEgg dome (epsilon about 2.0) floating over a ring of columns; open oculus where light or stars are needed |
| Roof, colonnade | flat cap (entablature slab) | thin quartz slab with a gold edge |
| Plan types | tholos, peristyle, stoa, exedra, odeon | |
| Entrance | prostyle porch, propylon | |

### Chinese parts (Dawn Gate, Hall of Mist and its propylon, Pantao)

| Element | Term | Specification |
|---|---|---|
| Roof | hip-and-gable (*xieshan*) with upturned corners | one pitch band, 28° to 32°, curved; a quartz slab roof with gold ridge and corner finials; a gold ring at each upturned corner |
| Double eave | *chongyan* | Hall of Mist only |
| Brackets | *dougong* | stacked squarish gold blocks under the eave, two tiers on the Hall of Mist, one elsewhere |
| Gate | gate hall, *pailou* | |
| Openings | moon gate | circular opening in set cloud bound by a gold ring |
| Plan types | gate hall, hall on podium, pavilion (*ting*), courtyard | |

### Heights for Tempestars

The prototype hovers a Tempestar 2.2 m above the cloud surface, and the upper
body adds about 1.2 m. Every opening a Tempestar uses therefore has at least
4.0 m clear, and every room they occupy at least 5.0 m to the roof's
underside. Doorways are generous by necessity, which suits the architecture.
The hero and party need the ordinary minimums (route 3 m, headroom 3.2 m).

### Exclusions

Hung timber doors, pitched timber roofs, chimneys, heavy masonry walls, solid
gold walls, round SuperEgg columns, copied temple forms, altars, statues of
gods, lanterns on posts, Buddhist imagery, banners carrying text.

### Upturned roof: a proof before any building

A SuperEgg is convex and symmetric, so it cannot make the concave sag and
lifted corners of a Chinese roof, and stacking SuperEgg pieces to fake the lift
would read as lumps with visible seams. The current Chinese village avoids the
problem with the ordinary town gable plus stacked eave tiers.

The upturned roof is therefore its own swept-surface primitive, as the
codebase already does for the spaceship deck, the dinosaur's swept pipe and the
Nautilus Crown's shell:

- the plan outline is a superellipse, keeping the design language;
- each slope carries a gentle concave sag;
- corner lift grows with how far an eave point lies toward the superellipse's
  corner, so the upturn comes from the outline rather than added pieces;
- the slab has real thickness with softened edges;
- collision is a simplified set of convex pieces, since the hero lands on
  roofs.

**Proof first.** Before the Hall of Mist, build one isolated roof (a single
eave over a 4 × 3 bay pavilion) and judge it from the Dawn Gate arrival view,
at eye level and from above in flight. It passes if the eave line reads as one
continuous curve, the corners lift without kinks or seams, its thickness and
edge softness match the SuperEgg buildings, and a flier can land on it without
snagging.

**Fallback if the proof fails:** a straight hip-and-gable floating roof with a
raised gold ring and finial at each corner to suggest the lift. Only the Dawn
Gate, the Hall of Mist and its propylon, and Pantao's buildings use this roof,
so the fallback changes five buildings and nothing else.

## 2. Style audit of the kit

| Element | Term | Tradition |
|---|---|---|
| Stepped cloud base with gold band | crepidoma / *taiji* | both: the shared invariant |
| Gable with pediment, 15° | pediment | Greco-Roman |
| Dome over columns | tholos | Greco-Roman |
| Hip-and-gable with upturned corners, 30° | *xieshan* | Chinese |
| Gold bracket blocks | *dougong* | Chinese |
| Circular gold-ringed opening | moon gate | Chinese |
| Floating roof gap, gold pins | — | invented, Sky Kingdom |
| Set-cloud panels and couches | — | invented, Sky Kingdom |
| Gold binding ring | — | invented, Sky Kingdom (signature motif) |

Each building below uses one tradition plus the invented Sky Kingdom layer:
two traditions at most, as the skill requires.

## 3. Building briefs

Each brief gives: masses, roof, base, bays and openings, entrance, enclosure,
interior program, materials and ornament, history and variation.

### Dawn Gate

- **Masses:** one gate hall, 14 × 6 m, three bays (central 5 m, sides 4.5 m).
- **Roof:** *xieshan* with a single eave; 1.0 m floating gap (principal
  building of its cloud).
- **Base:** single tier, 1.0 m, with a 6 m wide axial ramp.
- **Openings:** all three bays open; the central bay frames Aethra.
- **Program:** threshold only. The side bays hold two empty bases where gate
  keepers once stood.
- **Ornament:** gold rings at the four upturned corners; one tier of *dougong*.
- **History:** the kingdom's front door, unattended for longer than anyone
  admits.
- **Variation:** the only Chinese building that is open on all sides.

### Aethra

**Hall of Mist** (principal; Chinese)

- **Masses:** main hall 22 × 14 m (7 × 4 bays); rear throne bay one bay deeper.
- **Roof:** *xieshan* with double eave (*chongyan*), the only one in the
  kingdom; 1.6 m floating gap to the lower eave, a further 1.0 m between the
  two eaves.
- **Base:** triple podium, 3.0 m, with gold-railed balustrades; an axial ramp 4
  m wide in three flights with landings at each tier.
- **Openings:** front fully colonnaded; sides screened by quartz screen walls
  with tall superellipse arches; rear solid behind the throne.
- **Enclosure:** woven-cloud curtains between front columns, drawn open by day.
- **Interior:** a petitioners' floor 14 × 9 m; Aristeon's throne dais at the rear
  on one further 0.6 m step; side galleries 2.4 m wide for courtiers; Mnesia's
  standing desk at the dais foot.
- **Ornament:** two tiers of gold *dougong*; gold rings at eight corners.
- **History:** built for an assembly of courts and now used for audiences
  nobody attends.
- **Variation:** largest, tallest, double eave; the reference for rank.

**Propylon** (Chinese gate pavilion): 10 × 5 m, three bays, single *xieshan*,
0.6 m gap, single-tier base. Frames the hall from the landing forecourt.

**Chamberlain's tholos** (Greco-Roman): 7 m diameter, eight columns, dome with
a 0.6 m gap. Enclosed by quartz screen walls between five columns for the
ledger room; three open bays face the forecourt. Interior: a long reading
table, ledger shelves on the screen walls, a robe press. Mnesia's sleeping
alcove behind a cloud panel.

**Herald's moored room** (Sky Kingdom invented): a 5 m round set-cloud room
held in two gold rings, moored by a gold chain to a quartz pier at the
island's edge and reached by a 2 m gangway. One curtained opening toward the
court and one toward open sky. Alkis's couch and a rack of gold invitation
tubes.

**Nectar terrace** (Greco-Roman stoa): 18 × 5 m single colonnade, flat cap,
0.6 m gap, facing world east. Gold dew bowls on low quartz stands between the
columns; Drosia's pouring table in the end bay.

**Residence tholoi** (Greco-Roman): two tholoi behind the hall.
Aristeon's is 9 m with ten columns, a 1.0 m gap and fully screened walls
pierced by arches; Drosia's is 6 m with six columns and half screened. Each
has a sleeping couch of set cloud, a robe press and a gold dew bowl of its own.

### Koinon

**Hall of Assembly** (principal; Greco-Roman)

- **Masses:** a ring colonnade, inner diameter 16 m, outer 30 m; two concentric
  rings of columns (16 inner, 24 outer).
- **Roof:** a ring-shaped flat cap between the column rings, 1.0 m gap; open to
  the sky over the void.
- **Base:** single tier, 1.0 m, around the void.
- **The void:** 14 m round opening through the cloud to the world below,
  balustrade of quartz posts with a gold top rail at its rim.
- **Interior:** six seat platforms of set cloud, one per court, each under a gold
  ring bearing that court's emblem (an abstract shape, never text). The gold
  sealing decree and older decisions are inscribed on the inner face of the
  outer ring.
- **History:** the kingdom's shared hall, silent since the sealing.
- **Variation:** the only ring plan; the only building open in the middle.

**Observatory** (Greco-Roman tholos): 9 m diameter, eight columns, on a 4 m
podium of four tiers reached by a spiral ramp around the podium at 30°, 2 m
wide with balustrade. Dome with a large oculus and a 1.0 m gap. Astrion's gold
armillary and star tables inside.

**Archive** (Greco-Roman, closed): 10 × 7 m; quartz screen walls on all sides
pierced only by small high oculi; low gable with pediment, 0.6 m gap. One
doorway with a gold lattice gate, the kingdom's only hung leaf. Shelves of gold
leaf records.

**Philosopher's residence** (Greco-Roman peristyle house): 12 × 8 m around a
small cloud court with a sky lily pool; low gable, 0.6 m gap. Three rooms:
Sophrona's study and sleeping room, Astrion's room, Archeia's room.

### Pantao

**Banquet hall** (principal; Chinese)

- **Masses:** main hall 20 × 12 m (6 × 3 bays); a 2.4 m serving passage behind,
  enclosed.
- **Roof:** *xieshan*, single eave, 1.0 m gap; deep eaves of 2 m over the front.
- **Base:** single tier, 1.5 m, with three ramps (one axial, two side ramps
  from the garden).
- **Openings:** front and both sides open between columns; woven-cloud curtains
  in dawn pink.
- **Interior:** floating couches in two arcs facing Xiangyun's dais; tripod
  alcoves in the serving passage wall; a clear central floor 6 m wide for
  serving and dancing.
- **Ornament:** cloud wisteria trained along the eave; gold rings at the
  corners; peach motif cut in the gold capitals.
- **History:** built for the Peach Banquet, scene of Sun Wu Kong's ruin of it,
  and rebuilt grander out of spite.
- **Variation:** open on three sides; the warmest colour in the kingdom.

**Kitchen pavilion** (Chinese *ting*): 8 × 6 m, single *xieshan*, 0.6 m gap,
open on all sides so sun reaches the gold baking plates. Tianlu's composing
table and nectar jars; no fire.

**Open table** (Greco-Roman stoa, a deliberate exception in Pantao): 12 × 3 m
colonnade, flat cap. The one Greco-Roman element on Pantao, because the open
table is a shared civic gesture; it uses no Chinese parts. Gold tripods carry
the leftovers along it.

**Residence** (Chinese pavilion court): 14 × 10 m; three single-*xieshan*
pavilions around a small court entered by a moon gate. Xiangyun and Mingyue in
the principal pavilion; Tianlu and Chunlu in the side pavilions.

**Landing moon gate:** a 4.5 m moon gate of set cloud bound by a gold ring,
standing alone at the forecourt edge.

### Chrysa

**Forge hall** (principal; Greco-Roman, open-sided)

- **Masses:** 16 × 10 m (5 × 3 bays), open on all sides.
- **Roof:** low gable with pediments, 1.0 m gap, scorched gold edges.
- **Base:** single tier, 1.0 m.
- **Interior:** a working floor: three anvils in a line, cooling basins, gold
  stock racks, a lightning collector (a gold mast through the roof gap that
  draws arcs from Keraunia's storm crown down to a quartz crucible).
- **History:** the only building in the kingdom that has been extended for
  work rather than pride; one bay added, its gold slightly paler.
- **Variation:** the only cluttered interior; scorch marks; the age mark of the
  newer bay.

**Storm terrace:** open set-cloud platform 10 × 8 m with a balustrade, under the
crown. Keraunia's weather instruments.

**Apprentice's bench:** 6 × 4 m lean-to with a single-slope flat cap against no
wall: freestanding on four columns with a 0.6 m gap. Kallix's unfinished
pieces on every surface.

**Residence** (Greco-Roman): 10 × 8 m, low gable, 0.6 m gap; three rooms; gold
trim darkened by scorch.

### Lyria

**Odeon** (principal; Greco-Roman)

- **Masses:** semicircular auditorium 24 m across; a stage 10 × 5 m with a
  colonnaded back wall (scaenae frons) of six columns.
- **Roof:** flat cap over the stage only, 1.0 m gap; the seating is open sky.
- **Seating:** six tiers of set-cloud benches, 0.8 m rise each, with two
  ramped aisles for walking party members.
- **Wind harps:** strings of woven cloud stretched between the stage columns;
  they sound in the breeze.
- **History:** built for an audience of every court; most seats have not been
  sat in for an age.
- **Variation:** the only auditorium; the only open-sky principal building.

**Poet's residence** (Greco-Roman): 10 × 8 m, low gable, 0.6 m gap; three
rooms, one for each of Elegon, Aulia and Rhapsos, and a writing room on the
side facing the odeon.

**Song room** (Greco-Roman tholos): 7 m, six columns, dome with 0.6 m gap;
gold-leaf verse in niches; Aulia's practice floor.

### Dromos

**Racing ring:** a 6 m track of firmed bank cloud around the rim, inner radius
34 m; gold ring markers at quarter points; a finish line inlaid in gold.

**Judges' tholos** (principal; Greco-Roman): 8 m, eight columns, dome with a
1.0 m gap, on a 2 m podium overlooking the finish; Nikandra's seat and the gold
record of victories on the screen wall.

**Prize pavilion** (Greco-Roman, prostyle): 8 × 6 m, low gable with a
four-column porch, 0.6 m gap; Stephane's rings and woven-cloud wreaths on
stands.

**Residence** (Greco-Roman peristyle house): 12 × 10 m around a small court;
four rooms for Nikandra, Dromeus, Tachys and Stephane.

## 4. Variation matrix

Residences and minor buildings, by axis. No two buildings on the same court
share more than half their axes.

| Building | Plan | Roof | Gap | Base | Enclosure | Entrance | Age or mark |
|---|---|---|---|---|---|---|---|
| Aristeon's tholos | round | dome | 1.0 | 1 tier | fully screened | arch | oldest residence |
| Drosia's tholos | round | dome | 0.6 | none | half screened | open bays | dew bowls at every column |
| Mnesia's tholos | round | dome | 0.6 | none | five screened bays | open bays | ledger shelves visible |
| Alkis's room | moored sphere | none | — | gangway | cloud shell | curtain | the only room facing open sky |
| Philosopher's house | peristyle | gable | 0.6 | none | screened outer walls | porch | sky lily court |
| Archive | rectangle | gable | 0.6 | 1 tier | fully closed | gold lattice gate | the only hung leaf |
| Pantao residence | courtyard of three pavilions | *xieshan* | 0.6 | none | cloud panels | moon gate | wisteria |
| Chrysa residence | rectangle | gable | 0.6 | none | screened | open porch | scorched gold |
| Poet's residence | rectangle with side wing | gable | 0.6 | none | half screened | porch toward odeon | verse on gold leaf |
| Dromos residence | peristyle | gable | 0.6 | none | screened | porch to the inner field | trophy rings |

## 5. Validation notes

- Every opening Tempestars use is at least 4.0 m clear; every room at least 5.0 m
  to the roof's underside.
- Every podium has a ramp at most 32° with landings at each tier; every drop over
  1 m beside a route has a balustrade.
- Roofs are collidable: the hero flies and may land on them.
- Every floor, podium, ramp, terrace and island surface is cloud and one-way:
  passable rising from below, solid from above.
- Woven-cloud curtains, wind harp strings and glow between gold pins are
  decorative; columns, podiums, couches, panels and roofs are solid.
- Each court's emblem on its Koinon seat is an abstract shape. No building carries
  text.
