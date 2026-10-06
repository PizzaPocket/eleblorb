# Sky Kingdom: Civic Layout and Building Programs

Status: dimensioned schematic for review (2026-10-06). Read with
`sky_kingdom.md`, which owns the Tempestars, their courts, cuisine, flora,
materials and charter. This document places the six courts in the sky and
gives each building its program. Architecture briefs per building follow
approval.

## 1. Survey

From the current code:

- The town's cloud staircase starts on a hilltop 55 to 85 m from Ohio's town
  centre, in a random direction (`town_generator.gd`, `_build_sky_stairs`). It
  climbs to about 81.5 m (`CloudScatter.altitude_min - 6`), then a seven-step
  cloud course (`build_sky_course`) rises about 1 m per step and drifts on a
  random heading to the Air Gem landing, about 89 m up. The landing's position
  is recorded at runtime as `CloudScatter.last_sky_course_landing`.
- Ambient clouds fill 87.5 to 137.5 m (`altitude_min`, `altitude_max`) over a
  820 m spread. The prototype carves exclusion volumes around its islands.
- The prototype places four islands by offsets from the landing along an "away
  from the village" direction: Aethra (then Highcloud) at 45 m forward and
  22 m up, the others 93 to 195 m out, radius 46 m and 30 m.
- The Ohio plateau has a radius of about 245 to 265 m. Beyond it lie the gorge,
  the lake to the east and the volcano. The courts may extend past the plateau
  edge; there is no ground to collide with at this height.
- Everything is invisible and without collision until the Bird Helm is worn.

### Decision: an authored frame

The landing's world position depends on a long chain of procedural draws. An
authored settlement cannot depend on it. The rebuild should **fix the
staircase anchor** (hilltop, radius and heading) in plan data so the landing,
and with it the whole kingdom, is the same in every run. Until then, the frame
below remains valid relative to whatever landing is recorded.

**Frame:** origin at the Air Gem landing. Local `u` points forward along the
direction away from Ohio's town centre; `v` points to the right of `u`; `h` is
height above the landing (about 89 m). All coordinates below are `(u, v, h)` in
metres.

## 2. Composition

The courts form a loose ring around Koinon, the cloud of the common hall, with
Aethra placed between the gate and the ring so that it dominates the arrival
view.

- **Arrival axis.** Through the Dawn Gate, the visitor sees Aethra straight
  ahead and above. Its Hall of Mist stands on the axis. Koinon lies behind and
  below it, visible past Aethra's flank.
- **The ring.** Pantao, Chrysa, Lyria and Dromos stand around Koinon at roughly
  80 m from its centre, each at its own height. Spacing is generous: the hero
  flies and Tempestars float, so there are no bridges, and the distance between
  courts is part of the story.
- **Heights carry meaning.** Aethra is highest. Lyria floats high and apart.
  Pantao sits level with Aethra's foot, close enough to be seen to compete.
  Chrysa is lowest and darkest, under its own storm crown. Koinon sits low in
  the middle, its void looking down to the world.

```
                         u (away from Ohio) ↑

                 CHRYSA ·                     · LYRIA
                (230,-60, +2)              (230,+65,+20)
                 storm crown                  odeon

        PANTAO ·            ◯ KOINON             · DROMOS
       (150,-85,+16)       (170, 0, +6)         (140,+90,+8)
       peach garden        empty hall           racing ring

                         ▲ AETHRA
                        (70, 0, +28)
                        Hall of Mist

                         ⌂ DAWN GATE
                        (0, 0, 0) landing
                              ↓ staircase to Ohio
       ← −v                                            +v →
```

## 3. Islands

| Island | Centre `(u, v, h)` | Radius | World altitude (approx.) | Character of the cloud |
|---|---|---|---|---|
| Dawn Gate cloud | `(0, 0, 0)` | 16 m | 89 m | the enlarged landing cloud |
| Aethra | `(70, 0, +28)` | 40 m | 117 m | broad, tall-crowned cumulus |
| Koinon | `(170, 0, +6)` | 36 m | 95 m | a ring of cloud around a 14 m open void |
| Pantao | `(150, -85, +16)` | 38 m | 105 m | broad and soft; orchard trees above and vines below |
| Chrysa | `(230, -60, +2)` | 28 m, crown to +18 m | 91 m | dense cloud under a storm-dark anvil crown that flickers |
| Lyria | `(230, +65, +20)` | 30 m | 109 m | light, drifting, sun-lit |
| Dromos | `(140, +90, +8)` | 46 m | 97 m | flat lenticular disc with a raised rim |

Every island stays inside the ambient band (87.5 to 137.5 m), so the courts
still read as the world's own clouds. Each island and a 20 m margin around it
are excluded from ambient cloud placement. Centre-to-centre distances between
neighbouring courts are 70 to 110 m.

## 4. Movement

- **Tempestars** float between clouds on their own bodies. Their schedules may
  cross open sky.
- **The hero** flies (Air Gem). Every court has a **landing forecourt** on the
  side that faces the approach from the gate, at least 12 × 12 m, clear of
  furniture, so a flier can land and the party can form up.
- **Walking party members** (Blorbus, Xiao Hou Zi and others) reach each court
  with the hero as they do any destination the hero flies to. Within a court,
  every public route is walkable: 3 m wide, headroom 3.2 m, level changes by
  ramp of at most 32° or by a drifting stair (below).
- **Drifting stairs** read as separate quartz slabs, but their walking line is
  continuous: horizontal gaps under 0.2 m, rises under 0.25 m, total grade no
  steeper than a ramp. They are public routes, not parkour.
- **Edges.** Cloud edges are open; a fall drops to the world below, and the hero
  can fly back. Balustrades are needed only where a public route runs within
  1.5 m of a drop beside a building.

## 5. The courts: plans and building programs

Island-local coordinates are `(x, z)` in metres from the island centre, with
`-z` facing the landing forecourt (toward the gate or the arrival direction).
Footprints include eaves. Buildings within a court keep at least 3 m apart and
stay inside the island radius.

### Dawn Gate cloud

- **Dawn Gate** (Chinese palace style, after the Southern Heavenly Gate): a
  three-bay gate hall on a single quartz podium, 14 m wide and 6 m deep, with a
  floating double eave. Its central bay frames Aethra. The side bays hold the
  empty posts where the gate's keepers once stood.
- **Forecourt** between the top of the course and the gate, 12 m deep. The Air
  Gem rests here as it does now.
- **Program:** threshold only. No resident.

### Aethra (state, capital)

| Building | Style | Footprint | Program |
|---|---|---|---|
| Hall of Mist | Chinese palace | 22 × 14 m on a triple quartz podium 3 m high, at `(0, 8)` | audience hall: Aristeon's throne dais at the rear, a floor for petitioners in front, side galleries; double floating eave, the kingdom's only one |
| Propylon and forecourt | Chinese gate pavilion | 10 × 5 m at `(0, -22)`; forecourt 16 × 14 m | landing forecourt and the court's threshold |
| Chamberlain's tholos | Greco-Roman | round, 7 m diameter, at `(-14, -4)` | Mnesia's ledger room and robe store, with a reading table |
| Herald's moored room | set cloud and gold | 5 m round room moored at `(18, -6)` | Alkis's room, the only one with a door facing outward to the sky |
| Nectar terrace | Greco-Roman colonnade | 18 × 5 m on the island's east-facing rim | gold dew bowls, Drosia's stand, the cupbearer's alcove |
| Residence tholoi | Greco-Roman | two 6 m tholoi behind the hall | Aristeon's and Drosia's rooms |

Ramps from the forecourt to the podium run on the axis, 4 m wide, in three
flights with landings at each podium tier.

### Koinon (learning, the empty hall)

| Building | Style | Footprint | Program |
|---|---|---|---|
| Hall of Assembly | Greco-Roman | ring colonnade with an inner diameter of 16 m around the 14 m void and an outer diameter of 30 m | six seat platforms, one per court, around the void; the gold sealing decree and older decisions on the inner wall; a balustrade around the void |
| Observatory | Greco-Roman tholos with an open dome | 9 m diameter at `(0, 26)`, raised on a 4 m podium | Astrion's instruments and calendar of seasons |
| Archive | Greco-Roman | 10 × 7 m at `(-24, 8)` | Archeia's gold-leaf records; few openings |
| Philosopher's residence | Greco-Roman | 12 × 8 m peristyle house at `(22, 10)` | Sophrona's rooms around a small cloud court |
| Landing forecourt | — | 14 × 12 m at `(0, -28)` | arrival, facing Aethra |

The void is the hall's floor plan: a 14 m round opening through the cloud to
the world below. It has collision at its rim and a balustrade, and nothing in
it.

### Pantao (the feast, the Peach Garden)

| Building | Style | Footprint | Program |
|---|---|---|---|
| Banquet hall | Chinese palace | 20 × 12 m on a 1.5 m podium at `(0, 6)` | the Peach Banquet hall: floating couches in two arcs, Xiangyun's dais, tripod alcoves along the side walls, a serving passage behind |
| Peach Garden | landscape | 28 × 20 m at `(0, 23)`, behind the hall | cloud peach orchard in loose groves, Chunlu's path, the first-peach tree on a low mound |
| Kitchen pavilion | Chinese pavilion (ting) | 8 × 6 m at `(-16, -2)` | Tianlu's sun-baking terrace with gold plates in full sun, nectar store; no fire |
| Open table | colonnade | 12 × 3 m along the forecourt | the leftover table on gold tripods, facing the landing |
| Residence | Chinese pavilion court | 14 × 10 m at `(22, -6)` | Xiangyun's and Mingyue's rooms around a small court, Tianlu's and Chunlu's rooms |
| Undercloud vines | landscape | the island's underside | hanging vines with pale gold berries, seen from Koinon and Chrysa |
| Landing forecourt | moon gate of set cloud | 14 × 12 m at `(0, -28)` | arrival, facing Aethra |

### Chrysa (craft and weather)

| Building | Style | Footprint | Program |
|---|---|---|---|
| Forge hall | Greco-Roman, open-sided | 16 × 10 m at `(0, 4)` | Aurelia's gold forge: a working floor lit by Keraunia's storm crown rather than fire, anvils, cooling basins, racks of pins, rings and tripods in progress |
| Storm terrace | open platform | 10 × 8 m at `(0, 18)`, under the crown | Keraunia's weather station; lightning arcs down into the forge's gold collector |
| Apprentice's bench | lean-to | 6 × 4 m at `(14, 4)`, beside the forge hall | Kallix's unfinished pieces |
| Residence | Greco-Roman | 10 × 8 m at `(-16, -10)` | three rooms; scorched gold trim |
| Landing forecourt | — | 12 × 12 m at `(0, -20)` | arrival; the court's only clean surface |

Chrysa is the only court with working clutter. Its crown rises 18 m above the
island; lightning stays within the crown and the collector and never reaches a
route.

### Lyria (music and verse)

| Building | Style | Footprint | Program |
|---|---|---|---|
| Odeon | Greco-Roman | semicircular, 24 m across, at `(0, 6)` | stepped seating of set cloud facing a stage, wind harps strung between the stage columns, many empty seats |
| Poet's residence | Greco-Roman | 10 × 8 m at `(-14, -8)` | Elegon's rooms and writing room |
| Song room | Greco-Roman tholos | 7 m diameter at `(15, -8)` | Rhapsos keeps the gold-leaf verse here; Aulia rehearses |
| Landing forecourt | — | 12 × 12 m at `(0, -22)` | arrival |

The odeon's seating steps are ramped at the aisles so walking party members
can reach every tier.

### Dromos (games)

| Building | Style | Footprint | Program |
|---|---|---|---|
| Racing ring | landscape and structure | a 6 m track around the island rim, inner radius 34 m | Tempestar wind races; gold ring markers; a flier can race it too |
| Judges' tholos | Greco-Roman | 8 m diameter at `(0, -29)`, inside the track at the finish line | Nikandra's seat and the record of victories |
| Prize pavilion | Greco-Roman | 8 × 6 m at `(14, -20)` | Stephane's rings and woven-cloud wreaths |
| Residence | Greco-Roman | 12 × 10 m at `(0, 18)`, inside the ring | Nikandra's, Dromeus's, Tachys's and Stephane's rooms around a small court |
| Inner field | landscape | the ring's centre | puff-shrub hedges, a practice ground |
| Landing forecourt | — | 12 × 12 m at `(-16, -12)`, inside the ring | arrival by flight; walkers cross the track at one marked crossing beside the judges' tholos |

## 6. Shared requirements

- **Nectar terraces.** Every court has gold dew bowls on a terrace facing
  world east, whatever its local orientation.
- **Tripods.** Tripod routes run inside a court only, between alcoves and
  tables. They stay off ramps and landing forecourts and move slowly enough to
  read as objects.
- **Water and waste.** None needed: food is taken from dew, cloud and sun, and
  nothing is cooked over fire.
- **Light at night.** Gold vessels and quartz hold a soft glow after dusk. There
  are no lanterns on posts.
- **Schedule anchors.** Drosia at Aethra's nectar terrace at dawn; Aristeon in
  the Hall of Mist by day; Alkis travelling between courts; Aurelia, Kallix and
  Keraunia at the forge; Elegon, Aulia and Rhapsos at the odeon and song room;
  Sophrona and Archeia at Koinon's hall and archive; Astrion at the observatory
  at night; Xiangyun, Tianlu, Chunlu and Mingyue at Pantao's garden, kitchen
  and hall; Nikandra, Tachys, Stephane and Dromeus at the ring. Two residents
  never share a stop.
- **Protected bounds.** The whole kingdom is peaceful; no NMEs appear in it.

## 7. Implementation constraints

1. **One plan source.** `SkyKingdomPlan` (`scripts/sky_kingdom_plan.gd`) holds
   the frame, islands, buildings, routes, residents, schedules and exchange
   data. `sky_kingdom.gd` consumes it and invents nothing. The seeded scatter of
   spires, obelisks and dwellings is removed.
2. **Fixed landing.** The staircase anchor becomes authored data so the frame is
   identical every run.
3. **Bird Helm gate and lazy build** stay exactly as they are.
4. **Collision:** bank cloud keeps the simplified pad collider; quartz, gold and
   set-cloud furniture get primitive colliders; woven cloud, foliage and
   lightning are decorative.
5. **Validator mode** (`--village=sky`): overlapping footprints; islands outside
   the ambient band or closer than 60 m centre to centre; a court without a
   landing forecourt of at least 12 × 12 m; a public route narrower than 3 m,
   under 3.2 m headroom or steeper than 32°; a drifting stair with a gap over
   0.2 m or a rise over 0.25 m; a building or resident without an owner and
   program; a void without a rim collider and balustrade; two residents sharing
   a stop.
6. **Order:** plan data and validator, island clouds, landing forecourts and
   routes, one proof building of each style (the Hall of Mist and a tholos),
   then the courts, interiors, flora, residents and schedules.

## Fixed, proposed and open

**Fixed:** the Bird Helm gate and staircase entrance; islands within the
ordinary cloud band; flight between courts; the courts, residents and styles in
`sky_kingdom.md`.

**Proposed here:** the authored frame and fixed landing; the ring composition
around Koinon with Aethra on the arrival axis; island sizes, heights and
positions; every building, footprint and program above; the movement and
validator rules.

**Open:** what Tempestar food and gifts do for the hero; how much of Sun Wu
Kong's history becomes quest content; whether the courts meet again once the
Air blorbs return. None of these changes the layout.
