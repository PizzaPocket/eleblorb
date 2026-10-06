# Ocean Kingdom: Ocean Floor Landscape

Status: landscape plan for review (2026-10-06). Read with `ocean_kingdom.md`,
`ocean_landscape.md` (the islands' dry land) and
`ocean_sea_folk_city_layout.md`.

## 1. What exists now

From `ocean_kingdom_terrain.gd`:

- **Floor:** about -42 m in the central sea, rolling gently, falling toward
  -110 m at the edges, with two trenches about 24 m deeper at world
  `(420, 250)` and `(-380, -330)`. Island skirts rise steeply from about 35 m
  deep to the shore.
- **Kelp meadows:** four irregular meadows of ribbon kelp and fan seaweed at
  `(-285, 95)`, `(245, 125)`, `(170, -235)` and `(-235, -240)`, between 2.5 m and
  55 m deep.
- **Coral reefs:** three patches of branching coral, fans and rock at
  `(-12, 205)`, `(205, 34)` and `(108, -178)`, between 2 m and 24 m deep.
- **The sea folk city** on its levelled shelf at `(0, -540)`, 72 m down.
- The world bible also names **luminous deposits** among the floor's features.

The meadows and reefs are good starting points but are placed as isolated
patches, with no reefs around the islands themselves, no wrecks, and nothing
leading a swimmer to the city.

## 2. Zones by depth

Modelled on Hawaiian marine ecology, with the kingdom's established kelp kept
in deeper, cooler water.

| Zone | Depth | Character |
|---|---|---|
| Reef flats | 0 to 3 m | around every island's shore: rubble, *limu* (seaweed) tufts, small coral heads; Kai Mālie's fishpond is built on one |
| Fringing reef and reef slope | 3 to 30 m | a continuous reef around each island: lobe and finger corals in mounds, cauliflower coral heads, plate corals on the slope, sand channels between spurs |
| Patch reefs | 2 to 24 m | the three existing reef patches, kept and enlarged into irregular reefs |
| Deep reef | 30 to 55 m | sparser corals, sponges and branching black coral in dark red and black, on rock outcrops |
| Kelp meadows | 30 to 55 m | the four existing meadows, kept: tall loose kelp in the cooler water rising from the trenches |
| Sand plains | 40 to 70 m | open rolling sand with scattered rock outcrops and sea flowers |
| Abyss | below 70 m | the trenches and the kingdom's edge: dark rock, glowing deposits, almost no growth |

## 3. Features

### The luminous trail

A line of softly glowing mineral outcrops (the "luminous deposits") runs along
the floor from the slope below the arrival dock, `(0, 0)`, toward the sea folk
city, `(0, -540)`, spaced about 25 to 40 m apart and growing brighter and
closer together as they near the city. A swimmer who follows the lights finds
the city without being told. The trail bends around the Kraken's usual water
rather than crossing it head on.

### Wreck sites

The pirates' daily salvage needs wrecks within reach of a diver, so all three
lie on island slopes, 24 to 36 m deep. They have no backstory yet; that is
deferred with the kingdom's history.

| Wreck | World position | Depth | Description | Who salvages it |
|---|---|---|---|---|
| **The brig** | `(200, -30)`, on the slope of the largest islet | about 24 m | a two-masted merchant brig on its side, masts fallen across the reef; cargo hatches open | the *Harbinger*, which claims it by right of patrol |
| **The galleon's stern** | `(70, 170)`, beside the *hala* islet | about 36 m | the broken high stern of an old treasure galleon in the style of the Spanish ships pirates once hunted, its gallery windows half buried; the richest site | both, and they fight over it |
| **The schooner** | `(-60, -190)`, beside the coastal-forest islet | about 35 m | a small fishing schooner, nearly intact, colonised by coral and fish | the *Belle Fortune* |

Each wreck is a real structure: collidable hull, swim-through gaps big enough
for the hero, scattered barrels and crates, and coral growth that shows its
age. Salvage lines and marker buoys from the ships appear over them while a
crew is hove to.

### Around the sea folk city

- **The garden ring** (90 to 105 m from the city centre): Kasuno's braided kelp,
  Nesaja's sea-flower beds on the warm east side, Talisa's tended coral beds.
  Planting in drifts; avenues, the Ring Current and tunnel clear zones kept
  clear.
- **The edge** (105 to 150 m): the levelled floor blends into natural reef and
  sand, with the edge posts on each avenue and the Glassworks' vent with its
  warm shimmering water and mineral crust.
- **Outside the edge:** natural deep reef and sand plain; Fish Goblins stay out
  here.

### Kai Mālie's reef

The reef flat in Kai Mālie's layout (0.5 to 2 m deep), with the fishpond wall,
*limu* on the rocks, coral heads at the reef edge, the surf break, and the sea
folk meeting rocks where the reef drops away.

### The cage island

A fringing reef around the crater's outer slopes; inside the breach, the
sheltered bay is clear sand with a few coral heads, so arrivals swim or wade in
over pale water.

## 4. Rules

- Plant in drifts and colonies, never one of each.
- Keep swimming routes clear around the arrival dock, the pier, the swim exits,
  the city's avenues and the wreck sites' entries.
- Corals, rocks, wreck hulls and outcrops are solid; kelp, seaweed, fans and
  *limu* are decorative and swum through.
- Build from the existing `NatureProps` builders (`build_ribbon_kelp`,
  `build_fan_seaweed`, `build_branching_coral`, `build_rock`) where they fit,
  adding new ones for coral mounds, plate coral, black coral, sponges, *limu*
  and the luminous outcrops.

## Fixed, proposed and open

**Fixed:** the existing floor shape, trenches, kelp meadows and reef patches;
the sea folk city's shelf.

**Proposed:** zonation by depth; fringing reefs around every island; the
luminous trail to the city; three wreck sites; the city's garden ring and edge;
the new builders.

**Open:** none blocking. The wrecks' histories are deferred with the kingdom's
backstory.
