# Plant Kingdom: Landscape, Planting and Jungle Density

Status: landscape plan for review (2026-10-06). Read with
`plant_kingdom_village.md`, `plant_kingdom_village_layout.md`,
`plant_kingdom_water_curtain_cave.md` and the palette in
`.claude/skills/landscaping/references/southeast_asian_rainforest_flora.md`.

## 1. The ecosystem

The jungle is modelled on the lowland rainforest of Borneo, Sumatra and the
Malay Peninsula: hot, wet and still all year. That is the forest the game's
existing durian, banana and strangler figs already belong to, and the one the
residents' names come from.

| Zone | Where | Character |
|---|---|---|
| **Lowland forest** | most of the kingdom | layered: emergents 42 to 85 m over a closed canopy at 15 to 35 m, palms and saplings beneath, gingers, aroids and ferns on the ground; rattan climbing through it all |
| **Riverbank** | both banks of the river | bamboo clumps, figs leaning over the water, *pandan*, torch ginger, ferns on boulders, sand bars on the inside of bends |
| **Clearings** | the four existing clearings | grass and flowers with *mahang* pioneers and wild banana at their edges, where giants once fell |
| **Rocky outcrops** | the three existing outcrops | grey limestone with figs rooting on it, pitcher plants and begonias in the cracks |
| **Gorge and falls** | the river's last 150 m below Flower Fruit Mountain | wet rock, moss, filmy ferns and begonias in the spray |
| **Flower Fruit Mountain** | the highland above the cliffs | an old orchard gone wild, under a lower, more open forest |
| **The village** | the flat disc round the gate | the residents' bananas, fruit trees, gardens and herbs |

### Changes to the existing species mix

- **Keep:**
  - durian;
  - banana;
  - strangler fig (the banyan builder);
  - the pink flowering tree, which reads as *bungur*;
  - the palms, read as forest palms rather than coconuts;
  - the wild emergents, read as *tualang*, *meranti* and *keruing*.
- **Replace the baobab.** It is African and Australian, not of this forest, and
  its fat trunk is a wall to anyone swinging. Use a **cempedak**: a native
  canopy tree with fruit on the trunk.
- **Add the understorey the forest lacks:** rattan, fan palms, torch ginger,
  elephant ears, tree ferns, and epiphytes on trunks (bird's nest ferns,
  staghorns, orchids).
- **Add a few rare landmarks:** two *Rafflesia* flowers in the deep forest, and
  pitcher plants on the outcrops.

## 2. Jungle density: parity with the demo world

### What the code does now

Both forests come from `jungle_kingdom_foliage.gd`. The demo world's plant
stretch is a window onto this same kingdom's jungle. But the two modes fill it
very differently, and the kingdom gets the thin version.

| | Demo plant window | Plant Kingdom |
|---|---|---|
| Area | 348 × 220 m = 76,600 m²; about 57,500 m² of forest once the titan's clearing is removed | a disc of radius 420 m; about 499,000 m² of forest once the village core, clearings, outcrops and river are removed |
| Ordinary trees | 250 **placed** (it keeps trying until it has them) | 600 **attempts**, fewer placed once spacing rejects some |
| Tall canopy tier | 28 percent of ordinary trees grown 24 to 36 m | none |
| Emergents (42 m and up) | about 65 laid first, so they get their room, plus a **chained vine route** of 58 to 84 m anchors every 28 to 44 m and a ring of 10 round the titan's clearing: about 85 in all | 26 percent of attempts, competing with smaller trees for room: at most about 156 |
| **Trees per 1,000 m²** | **about 5.8** | **at most 1.2** |
| **Emergents per 1,000 m²** | **about 1.5**, one per 680 m², typically 26 m apart | **at most 0.3**, one per 3,200 m², typically 57 m apart |
| Beyond 420 m | — | **nothing**: the terrain runs to 900 m, but Kova Kong at `(400, -280)` (488 m out) and Flower Fruit Mountain (640 m out) stand in bare ground |

The vine's longest rope is 52 m, and the demo route keeps anchors within 44 m
of each other. In the kingdom, typical emergents stand 57 m apart, beyond one
rope. That is why swinging peters out there.

### Target

At least the demo's density, across **all** of the kingdom's forest:

- **Emergents (vine anchors):** at least **1.5 per 1,000 m²**, laid before
  the canopy so they claim their room. From 98 percent of the forest floor
  there is an emergent within 30 m. Every emergent has another within 44 m,
  except across clearings, the river and the outcrops.
- **Trees overall:** at least **5.8 per 1,000 m²**, including the tall 24 to
  36 m canopy tier at 28 percent.
- **Extent:** the scatter covers the whole playable kingdom, not a 420 m disc.
  It includes Kova Kong's ground, the river to its source and the top of
  Flower Fruit Mountain. Each zone keeps its own character (section 1).
- **Vine routes**, laid as chains like the demo's, with anchors at the top of
  the emergent range:
  - village to Kova Kong;
  - village upriver to the gorge below the falls;
  - village to the Wood Kingdom ground.

  Each route stays near the target density all along. The routes guarantee a
  good run; the general density makes swinging work anywhere.

### What that costs, and how to afford it

Reaching parity over about 500,000 m² means about **2,900 trees and 750
emergents** inside the present disc, and more once the scatter reaches the
kingdom's edge. That is five times today's count. Today's count was halved
from 1,200 because **building** every tree when the scene loads was too slow.
Rendering was not the problem: the distance limits already cap what is drawn.
So the way the forest is built has to change before its counts can rise:

1. **Stream the forest by cell.**
   - Divide the kingdom into cells about 64 m square, each with its own fixed
     seed, so a cell always grows the same trees.
   - Build only the cells within about 300 m of the player, a few props per
     frame, and free cells beyond about 400 m.
   - At load, build only the cells round the arrival.
2. **Share meshes.**
   - Build each species at a handful of sizes once, and reuse those meshes for
     every tree.
   - Draw the ground layer (grass, flowers, ferns, gingers) as multimesh
     instances rather than separate nodes.
   - Emergent trunks and limbs keep real collision, because they are what the
     vine catches.
3. **Lay the emergents first in each cell,** then the canopy round them, as the
   demo window already does.
4. **Keep the demo identical.** The demo window should run the same per-cell
   code over its rectangle and get what it gets now.

This is a code project, recorded in the settlement backlog. It does not change
the village layout.

## 3. The village grounds

The village stands on its flat disc, about 55 m in radius. The jungle's clear
radius grows from 24 m to **60 m**, as the layout asks. At the disc's edge, the
forest returns as a soft wall of torch ginger, wild banana, *mahang* and ferns
under the first emergents. So swinging can begin as soon as anyone steps off
the edge.

### The three giants

The village trees read as **tualang**:

- smooth pale grey bark and broad plank buttresses at their feet;
- wild honeycombs hanging under their high limbs (the village's honey);
- bird's nest ferns, staghorns and orchids on the trunks between the rings.

Each tree carries its own epiphytes:

- **Elder Tree:** old, heavy ferns and moss.
- **East Tree:** kept trimmed by the carpenters round the ramps.
- **North Tree:** the most orchids. Murai, the naturalist, encourages them.

Buttresses keep out of the ramp footprints and the commons posts.

### Gate plaza, under the commons

- Too shaded under the 11 m deck for grass. The ground is **packed red-brown
  earth**, worn smooth where everyone crosses, with moss in the shade.
- Ferns and elephant ears ring the bases of the six support posts.
- The ground keeps clear in front of the gate and along the foot of the grand
  ramp.

### The commons

The commons is a deck, so its plants grow in containers and on the trees:

| Where | Planting | Tended by |
|---|---|---|
| Kitchen | pots of lemongrass, *pandan*, ginger and turmeric along the rail beside the hearth | Wangi |
| Dining terrace | hanging baskets of orchids from the leaf roof | everyone |
| Market | baskets and crates of fruit (bananas, durian, rambutan, mangosteen, *cempedak*); one pomegranate bush in a big pot at Delima's stall | Delima |
| Gathering circle | open to the sky, no planting | — |
| Trunk corners | bird's nest ferns and staghorns where the deck wraps each trunk | — |
| Inn (on the commons' edge beside the East Tree) | a jasmine in a pot at the door; orchid baskets on its leaf-roofed veranda | Bima |

### The ground camp

| Place | Planting and ground | Tended by |
|---|---|---|
| **Garden house and gardens** `(-38, 14)` | Raised, woven-edged beds west of the house, one crop each: taro, ginger, turmeric and galangal, lemongrass, yams climbing bamboo poles. A wet bed of water spinach fed from a rain barrel. A low hedge of jasmine along the house front. A bamboo fence round the beds, with its gate on the path to the plaza. Compost heap and rain barrels at the corner. | Melati |
| **Fruit-tree nursery** beside the garden | rows of seedlings in leaf pots under a woven-leaf shade frame: durian, rambutan, mangosteen, *cempedak* | Melati and Delima |
| **Banana grove** between the garden house and the floor hut | five clumps of bananas, cut stems and fallen leaves beneath | Delima |
| **Stable and paddock** `(24, -30)` | Short grazed grass in the paddock, with trampled mud round the trough and the gate. One big mango at the paddock's corner for the horse's shade. A bamboo rail fence. Hay (grass cut from the clearings) on the rack. | Ossian |
| **Ape lodge** `(38, -14)` | A beaten-earth yard with fallen-log seats under a fig. Long grass and elephant ears at the margins. | the apes |
| **Tailed monkeys' house** `(-34, -16)` | Drying racks of split rattan, coils of vine rope under the floor. Rattan rambling up the nearest trees at the forest edge, where Rotan harvests it. | Rotan |
| **Floor hut** `(-24, 34)` | A *damar* tree beside the hut, its trunk scored and weeping resin, and resin cups on it (Damar's namesake and the village lamp fuel). Pots of herbs at the step. | Damar, Wangi |
| **Training grounds** `(-48, -48)` | Trampled bare earth with *mahang* saplings crowding the edges. The shed's door stays shut. | Batu |
| **River trail and fishing landing** | The trail is worn earth, 2.5 m, through gingers and ferns. At the river: bamboo clumps, a fig leaning over the water, flat stones, a sand bar, Tirta's fish-trap rack. | Tirta |

### Worn ground

Worn paths run from the plaza to every ground building, to the foot of the
grand ramp, to the river trail and to the training grounds. There is mud at
the trough and the paddock gate, bare earth at every doorstep, and long grass
along the fences.

## 4. Flower Fruit Mountain and the falls

### The gorge (forgotten state)

- The north bank carries only a faint animal trail through ferns and moss.
  Nobody comes here.
- Boulders lie in groups of three to five, mossed on their shaded sides.
- Strangler figs root in the rock walls, and tree ferns lean over the water.
- Begonias and filmy ferns grow in the spray zone nearest the falls.

### The cliff and the pool

- **Cliff face:** rattan and liana curtains hang from the lip (the existing
  hanging-vine builder) along the climbing route north of the falls. There are
  ferns in every crack, bright moss in the spray, and pitcher plants on the
  dry ledges.
- **The ledge behind the falls:** ferns and fig roots hide it from the gorge.
  They are cleared in the reclaimed state.
- **The pool:** fast water, so no reeds. Flat stones line it, with a gravel
  spit where the river leaves.

### The mountain top

- **An old orchard gone wild.** Groves of durian, mango, rambutan, mangosteen,
  *cempedak* and banana stand in glades of long grass. The troop that lived in
  the cave fed from them, and they were never tended after it left. Fallen
  fruit lies under every grove.
- **The old peach trees:** a single grove of gnarled peach trees round the
  knoll of the stone egg, in pink blossom and fruit at once. They are the only
  peaches in the kingdom, growing where no peach should. The proposed story:
  Sun Wu Kong brought down the stones of the golden peaches he ate in the sky.
- **Forest:** lower and more open than the lowlands. The emergents keep to the
  deeper soil away from the cliff, but meet the density target at the plateau's
  edge so a swing up from the gorge has somewhere to go.
- **The stream:** stony, with ferns and bamboo on its banks, running to the
  lip.
- **The light shaft's opening:** a ring of ferns and fig roots round a hole in
  the limestone. Nobody would notice it without looking.

## 5. Rules

- Plant in drifts and clumps, never one of each; bananas, gingers and bamboo
  are clumping plants anyway.
- Keep the village routes, the plaza, the gate, the grand ramp foot, door
  clear zones and the commons' posts clear.
- **Solid:** trunks, buttresses, boulders, the bamboo fence and the bed edges.
  **Decorative:** foliage, ferns, gingers, flowers, orchids and hanging lianas.
- **Builders:**
  - Use the existing `NatureProps` builders where they fit.
  - Add new ones for: *tualang* bark and buttresses, *cempedak*, rattan, fan
    palm, torch ginger, elephant ear, tree fern, the epiphyte sets, bamboo
    clump, *mahang*, rambutan, mangosteen, mango, the peach, pitcher plants and
    *Rafflesia*.
- No text, no instruction.

## Fixed, proposed and open

**Fixed (user direction, 2026-10-06):**
- the inn moves up to the commons;
- the kingdom's jungle reaches at least the demo world's density for vine
  swinging.

**Proposed:**
- the rainforest model and zones;
- replacing the baobab;
- the new understorey;
- the density targets, the vine routes and the streamed, shared-mesh build;
- the village planting;
- the tualang giants;
- the gorge, cliff and mountain-top planting;
- the peach grove's origin.

**Open:** none blocking.
