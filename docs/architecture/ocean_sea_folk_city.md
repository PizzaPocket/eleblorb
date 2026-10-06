# Ocean Kingdom: The Sea Folk City

Status: concept brief, first planning pass, in review (2026-10-06). Read with
`ocean_kingdom.md` (the kingdom overview) and the world bible's Ocean Kingdom
entry.

## 1. What exists now

`scripts/ocean_kingdom_city.gd` builds the merfolk settlement:

- centre at world `(0, -540)` on a levelled seabed shelf at `-72 m`, flat
  radius 105 m blending over 45 m into the ocean floor
  (`ocean_kingdom_terrain.gd`);
- a teal and prism-green castle with an open, traversable audience hall;
- sixteen enterable homes in two rings, at 49 m and 82 m from the centre;
- eight spokes of luminous stepping stones, kelp gardens and living pearl lamps
  in aqua, blue and violet;
- twenty named merfolk with one line each, among them **Tidekeeper Asaru**.

### Non-regression requirements

- The castle remains the brightest landmark, with its open, traversable
  audience hall and Asaru's nautilus crown.
- The existing twenty residents, names, looks and voices; every resident named.
- The luminous paths, pearl lamps and kelp gardens.
- The Nautilus Shell and Watering Can merchants.
- The Tidekeeper battle and the Nautilus Crown reward (premise still open).
- The two-ring plan around a central castle, which this brief formalises.

## 2. Premise: Atlantis, but modern

The sea folk draw on the human world's Atlantis, as told by Plato in the
*Critias* and *Timaeus*: a city of concentric rings around a central
palace, cut through by radial canals, rich in a red-gold metal called
**orichalcum**, with hot and cold springs and great harbours. Archaeology has
long linked the legend to Bronze Age Crete and Thera, so the Minoan world
supplies a second, older layer: columns that taper downward, light wells,
spiral bands and frescoes of dolphins and octopus.

Like the lava people, the sea folk are scientifically advanced. Their
architecture is modern rather than ruined or ancient: continuous nacre shells,
orichalcum structure, large curved glass, daylight piped down from the
surface, and pressurised **air halls** in which they walk on legs.

They are a people, not gods, and nothing in their city is a temple.

### Air halls and the change to legs

Some work cannot be done underwater: glass is blown in air, paper and charts
keep only when dry, and air-breathing visitors need somewhere to stand. The sea
folk build **air halls**, glass domes filled with compressed air.

- **Moon pool entry.** An air hall is entered from below, through an open pool
  in its floor. The air pressure holds the water down at the pool's surface, as
  in a diving bell, so there is no door to open. A swimmer rises through the
  pool and climbs out onto the floor by a broad ramp.
- **Tail to legs.** As a sea person climbs out of the pool, their tail parts
  into legs, and they walk the hall on foot. Re-entering the water, the legs
  close back into a tail. The change is part of their nature, not a magic
  item.
- **For the hero.** An air hall is the one place in the city where the hero
  can breathe and walk without a Diving Helmet, and talk to the sea folk face
  to face on dry ground.

## 3. Community

The census keeps the existing twenty residents and adds two children, for
**twenty-two** in seven households. Roles come from what each resident already
says. Every resident is renamed (section 3a).

| Household | Residents | Work |
|---|---|---|
| **Tidehall** (the palace) | **Tidekeeper Asaru**; **Ikara**; **Tudaro** | Asaru listens and judges; Ikara watches the Kraken; Tudaro keeps the city's edge and reads Fish Goblin trails |
| **The Glassworks** | **Kunei**; **Damaku** | Kunei blows the glass; Damaku engineers the air halls, chamber by chamber |
| **The Lamp House** | **Lunira**; **Korasi**; their daughter **Mira** (child) | Lunira grows and sings to the living pearl lamps; Korasi reads storms in them |
| **The Garden House** | **Nesaja**; **Rodasu**; **Kasuno**; Kasuno's son **Tami** (child) | Nesaja's sea flowers; Rodasu sells Watering Cans and tends the link to the Seed of Life; Kasuno braids the kelp that grows around the homes |
| **The Exchange** | **Maresa**; **Pelaju**; **Sujira** | Maresa keeps the trading hall and sells Nautilus Shells; Pelaju listens to the surface and deals with the island and the ships; Sujira makes scale clothing |
| **The Reef House** | **Talisa**; **Arimu**; **Kaluja** | Talisa studies the reef's smallest life; Arimu records the night reef; Kaluja keeps the light pipes that bring daylight down |
| **The Current House** | **Oruko**; **Dakuro**; **Sekira**; **Munaja** | Oruko carries messages on the ring current; Dakuro charts the deep edge; Sekira makes shell ornaments; Munaja teaches the young |

### 3a. Names

The prototype's names (Marella Shellwise, Corren Bluewake and so on) are
replaced. Sea folk now go by a single given name and are known by their
household ("Maresa of the Exchange"). The names use open syllables and the
sounds of Linear A, the undeciphered script of Minoan Crete, so they have no
translated meanings: a sound palette of *a*, *i* and *u*, with *k*, *d*, *t*,
*r*, *s*, *n*, *m* and *j*.

| New name | Role | Prototype name |
|---|---|---|
| Tidekeeper Asaru | ruler and judge | Tidekeeper Nerion |
| Ikara | Kraken watcher | Azura Ripplefin |
| Tudaro | edge warden | Tavio Reedtail |
| Kunei | glassblower | Nilo Tideglass |
| Damaku | air hall engineer | Brin Nautilus |
| Lunira | pearl lamp keeper | Luma Pearlsong |
| Korasi | storm reader | Corren Bluewake |
| Mira | child | — |
| Nesaja | sea flower gardener | Nerissa Bloomfin |
| Rodasu | Watering Can seller | Ronan Amberkelp |
| Kasuno | kelp braider | Caspian Kelpweaver |
| Tami | child | — |
| Maresa | keeper of the Exchange, Nautilus Shell seller | Marella Shellwise |
| Pelaju | surface liaison | Pelagos Drift |
| Sujira | scale clothier | Ondine Silvergill |
| Talisa | reef scientist | Thalina Foamcrest |
| Arimu | night reef recorder | Maris Coralglow |
| Kaluja | light pipe keeper | Calypso Sunkenstar |
| Oruko | courier on the Ring Current | Orin Redfin |
| Dakuro | deep edge cartographer | Delmar Deepcurrent |
| Sekira | shell jeweller | Selkie Seabloom |
| Munaja | teacher | Muirin Softcurrent |

`ocean_kingdom_city.gd` still uses the prototype names until the rebuild, and
several existing lines refer to them.

### Governance

The Tidekeeper rules, but as a listener and judge. Each household speaks for
itself in the audience hall. The hero fights the Tidekeeper because fighting to
test a visitor's mettle is part of sea folk culture: a challenge of respect,
not hostility.

### Relations: discord now, harmony later

When the hero arrives, every community in the kingdom is at odds with the
others. The Demon King has sown the discord; how is still open. Restoring
harmony between them is the kingdom's story, as it is in the Sky Kingdom.

- **The island village:** the shoreline exchange, generations old, has broken
  off. Each side blames the other for damage to its waters. Pelaju and the
  island's elders, who were friends, no longer speak; Talisa's work with the
  island's marine biologist has stopped.
- **The pirates:** heard overhead "like distant wooden thunder." The sea folk
  hate both crews and believe the ships are fouling the reef.
- **The Kraken and Fish Goblins:** a danger Ikara and Tudaro watch. The goblins
  serve the Kraken, not the city.

## 4. Settlement structure (pre-layout)

The existing two-ring plan becomes Plato's concentric city:

1. **The central mound:** the castle (Tidehall), with its open audience hall.
2. **The civic ring:** a raised terrace around the castle with the Exchange air
   hall, the Lamp House and the school court.
3. **The Ring Current:** a channel of fast-moving water circling the civic
   ring, a real swimming lane that carries a swimmer around the city. This is
   the "copper current" Oruko raced.
4. **The home ring:** the households on a second terrace, with braided kelp
   around their walls.
5. **The garden ring:** kelp gardens, sea-flower beds and the reef workshops.
6. **Radial canals:** the existing eight luminous spokes become sunken avenues
   crossing the rings, joining the edge to the castle.
7. **The vent edge:** the Glassworks sits beside a warm vent at the city's
   edge, the "hot spring" of Plato's account, where its air hall has heat for
   glass.

Air halls: the Exchange (trade and the hero's meeting place), the guest hall
and the Glassworks. Homes stay wet.

### The guest hall: the city's rest point

The guest hall is an air hall kept by **Pelaju**, who deals with every visitor
from the surface. It is a rest point, one of two in the kingdom (the other is
Kai Mālie's guest house). Resting restores the party and melted blorbs,
advances to morning and plays the standard waking sequence in a dry bed inside
the hall; the party gathers on the hall's floor, never in the moon pool. A
night costs the ordinary rate of 10 Tokoins through the shared transaction
interface.

### Glass tunnels

Compressed-air **glass tunnels** join the air halls into one dry network, so
sea folk on legs and an unhelmeted hero can walk between them without
entering the water.

- **Form:** a superellipse tube of curved glass on orichalcum ribs, its floor
  flat and its walls clear, running a little above the seabed on slender
  supports. Fish, kelp and the city's lights pass on the other side of the
  glass.
- **Routes:** the Exchange to the guest hall around the civic ring; one tunnel
  out along a radial avenue to the Glassworks at the vent; short branches to
  any later air hall. Tunnels cross over the Ring Current and the avenues so
  swimmers pass beneath them.
- **Entry:** every junction has a moon pool, so a swimmer can come up into
  the network anywhere it branches.
- **Dimensions:** walking floor at least 3 m wide, headroom at least 3.2 m,
  gentle ramps only.
- **Air:** the whole network is one pressurised volume, as the spaceship's
  cabin and docking neck are.

## 5. Architectural charter (draft)

- **Primary, about 70 percent: Atlantean modern** (invented). Continuous
  superellipse shells finished in nacre, orichalcum ribs and frames, large
  curved glass, ring and crescent plans, sunken avenues.
- **Secondary, about 25 percent: Minoan Bronze Age.** Named elements only:
  columns tapering downward with cushion capitals, light wells, spiral and
  wave bands, and fresco bands of dolphins and octopus inside the air halls.
- **Accent, about 5 percent:** living pearl lamps and braided kelp.
- **Palette:** nacre white and teal 60 percent; prism green, ocean blue and
  violet light 30 percent; orichalcum red-gold 10 percent.
- **Exclusions:** Greek temple orders and pediments (which belong to the Sky
  Kingdom); Minoan horns of consecration, double axes and other sacred
  emblems; ruins and broken columns; anything that reads as a sunken human
  city.

## Fixed, proposed and open

**Fixed:** the castle, homes, paths, lamps, gardens and twenty residents
already built; merfolk bodies; the merchants; the Tidekeeper and Nautilus Crown.

**Proposed:** the Atlantis and Minoan influences with modern technology;
orichalcum; air halls entered by moon pool, where the sea folk walk on legs;
glass tunnels joining the air halls; Linear A-sounding names for every
resident; the Demon King's discord with the other communities;
the seven households, the residents' roles and two children; the concentric
plan with the Ring Current; the Glassworks at a warm vent.

**Settled:** the Tidekeeper's fight is a cultural test of mettle; the guest
hall charges 10 Tokoins.

**Deferred by the user:** the Ocean Kingdom's backstory, including how the
Demon King sowed the discord.

## Implementation notes

- **Air halls reuse the existing pressurised-volume idea.** The spaceship
  already registers in the `pressurized_volumes` group and answers
  `contains_breathable_point()`, which `AtmosphereLayer` consults. An air hall
  needs the same kind of query from the liquid system: inside the hall's air,
  a body is out of the water, stops swimming, breathes and walks. The moon pool
  surface is an ordinary water surface with swim exits.
- **Legs for sea folk.** Merfolk currently have no hip segment and no legs. The
  rig needs a legged variant and a transition at the pool edge. Use the
  `figure-rig` skill.
