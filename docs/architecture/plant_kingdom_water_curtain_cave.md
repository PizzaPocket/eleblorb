# Plant Kingdom: Flower Fruit Mountain and the Water Curtain Cave

Status: site plan and architecture brief for review (2026-10-06). Read with
`plant_kingdom_village.md`, `plant_kingdom_village_layout.md` and the Sun Wu
Kong entries in `docs/world_bible.md`.

## 1. Premise

In his legend, Sun Wu Kong was born from a stone egg on the summit of
**Flower Fruit Mountain** (*Huāguǒ Shān*). The monkeys of the mountain followed
their stream up to its source and found a waterfall. The stone monkey jumped
through it and found a dry cave behind it: an iron bridge over the stream, then
a great hall furnished entirely by nature, with stone stoves, pots, bowls,
beds and benches. He became king for finding it. The cave is the **Water
Curtain Cave** (*Shuǐlián Dòng*), and it was his seat.

In Eleblorb:

- Flower Fruit Mountain is the cliff-walled highland at the **west end of the
  Plant Kingdom**. The kingdom's river rises there: it pours off the cliff as a
  waterfall, and the cave is behind the falls.
- When the monkeys' king went up into the sky and never came back, the troop
  left the mountain and climbed into the giant trees downriver. Over the
  generations the cave was **forgotten**. No villager knows where it is, and
  the villagers' stories of the Monkey King never say where he lived.
- It stays forgotten **until Sun Wu Kong comes back and reclaims his seat**. The
  quest that brings him is deferred. This brief covers the place in both
  states: forgotten, and reclaimed.

## 2. Site: where the river begins

### What exists now

From `jungle_kingdom_terrain.gd`: the river runs the whole width of the kingdom
from `x = -900` to `x = 900`. Its centreline is at
`z = 150 + noise(x) × 60`. It is 16 m wide, its bed 14 m down, and its water
held at a constant -3 m. Distant mountains ring the kingdom at about 950 m. The
nearest content to the west is the clearing at `(-250, 90)`. The Wood Kingdom
reveal is at `(-250, -300)`.

### Proposed

- **The river now begins** at a plunge pool at the foot of the falls, at
  `x ≈ -640` on its own centreline. West of the pool there is no river. East of
  it, the river flows on as now, across the kingdom and out past the eastern
  ring. The village is about 650 m downriver: following the river upstream
  from the village's fishing landing leads to the falls.
- **The gorge.** For the last 150 m below the falls the banks steepen into
  rock walls, 8 to 15 m high, and the jungle thins to ferns, mossy boulders
  and fig roots on the rock. A walkable bank about 3 m wide runs along the north
  side of the gorge, so nobody has to swim to reach the falls.
- **The cliff.** A crescent escarpment about 300 m long curves round the head
  of the gorge. It is **38 m high** at the falls and 25 to 45 m along its
  length. Its rock is pale grey limestone in thick horizontal beds, with
  overhangs, ledges and vertical cracks. Vines and figs hang down the face, and
  ferns grow wherever the spray reaches.
- **The falls.** A curtain of water **14 m wide** pours from a notch in the
  cliff lip at **+30 m** into the pool. It is a curtain, not a jet: thin,
  sheeting and slightly translucent. Mist rises from the pool.
- **The plunge pool.** Round, about 36 m across, at the river's water level
  (-3 m), deep enough to dive into from the lip.
- **The mountain top.** West of the lip, the highland of Flower Fruit Mountain
  rises gently westward to the kingdom's edge. It is open jungle full of fruit
  trees gone wild: banana, durian, mango, jackfruit, and old peach trees, the
  only peaches in the kingdom. A spring-fed stream about 4 m wide runs across it
  to the lip and over as the falls.
- **The stone egg (proposed).** On the highest knoll of the mountain top stands
  a great stone egg about 4 m tall, split open long ago, with grass growing in
  the halves: Sun Wu Kong's birthplace. Nothing marks it but the shape.

### Getting there and up

- **Along the river:** the north bank of the gorge leads to a rock shelf at the
  foot of the cliff, beside the pool.
- **Into the cave:** see section 3.
- **Up the cliff:** a climbing route of ledges, cracks and hanging vines up the
  face north of the falls, for climbers and the Leaf Hat's swinging. For
  everyone else, a steep gully about 120 m north of the falls rises at no more
  than 32° to the mountain top.
- **From above:** the stream on the mountain top leads to the lip, and the
  hero can jump from the lip into the pool.

### Who comes here

Nobody, in the forgotten state. Ape skeleton NMEs may rise in the gorge as they
do anywhere in the wilds, but never inside the cave: it is a safe zone. Wild
blorbs roam the mountain top as they do elsewhere in the kingdom.

## 3. The cave

### Architectural character

**The cave is not built; it is found.** Every element of the legend's
furnishing is natural rock that happens to serve a household. The beds are rock
shelves, the stoves are hollows in the rock with natural flues, and the bowls
and basins are water-worn hollows in fallen stone. The monkeys only adapted it:
a few vine ladders, woven mats, and smoke-blackened hollows.

The design rules follow from that:

- **No masonry, no carpentry, no straight lines.** All forms are SuperEgg rock
  masses at soft epsilons (2.0 to 3.0), with limestone beds expressed as
  stacked, slightly offset lobes. Flowstone and stalactites are ellipsoid drips.
- **The one made thing is the iron bridge,** in the legend a single plate of
  iron. Here it is a slab of dark rust-brown iron, slightly arched, on two rock
  abutments: the only hard-edged object in the cave (`EPSILON_FLAT`).
- **Furniture is in the walls.** Beds, benches, stoves and shelves are rock
  shelves and niches modelled as part of the cave wall, not props standing in
  the room.
- **Light comes from outside:** daylight through the falls, shifting with the
  water, and one shaft from a natural chimney over the hall.

### Plan

All floor heights are above the river's datum, where the pool's water is at
-3 m.

```
            W (mountain)
   ┌───────────────────────────────────────────┐
   │  spring pool        THRONE DAIS           │
   │   (back of hall)    + stone seat          │
   │      ╲  stream                            │
   │  sleeping   ╲      THE GREAT HALL         │
   │  niches      ╲     32 × 24 m, vault       │
   │  (north      │╲    to 14 m; light shaft   │
   │   wall)      │ ╲   over the centre        │
   │              │  ╲                stoves,   │
   │  stone benches    ╲              basins   │
   │  round the floor   ╲            (south    │
   │                    ═══ iron bridge  wall) │
   │                     │ stream channel      │
   │      ENTRANCE CHAMBER 10 × 8 m            │
   │      stele ▪                              │
   └─────────── mouth 6 × 5 m ─────────────────┘
       ledge ▒▒▒▒  ║║║║ falls ║║║║   E (pool)
```

| Space | Size | Floor | Description |
|---|---|---|---|
| **Ledge** | 2 m wide, 24 m long | rising from +1 m at the shelf to +4 m at the mouth | a natural ledge along the cliff foot, passing **behind the falling water** with about 3 m between the curtain and the rock; wet, mossy, rimmed with ferns |
| **Mouth** | 6 m wide, 5 m high | +4 m | a rounded natural arch in the cliff directly behind the centre of the falls, invisible from the pool except as a dark shape through the water |
| **Entrance chamber** | 10 × 8 m, 6 m high | +4 m | lit green-white through the curtain; the **stele** stands on the right |
| **Stream channel and iron bridge** | channel 3 m wide, 1.5 m below the floor; bridge 2.4 m wide, 6 m span | bridge deck at +4.3 m | the cave's inner stream runs from the spring at the back of the hall, across the hall's front and under the bridge, and drains out through a cleft beside the mouth into the pool; the bridge is the only way across dry-footed |
| **Great hall** | about 32 × 24 m, vaulted to 14 m | +4.5 m, gently uneven | the household; described below |
| **Throne dais** | 6 × 5 m, 1.2 m high | +5.7 m | a natural rock dais at the back of the hall under the light shaft, reached by a broad rock ramp at no more than 32°; on it, the **stone seat** |
| **Spring pool** | about 5 m across | water at +3.5 m | at the hall's back corner, clear and cold, where the inner stream rises |

The whole cave stays within 40 m of the cliff face, so it sits under the
mountain top with at least 15 m of rock overhead. The light shaft rises through
that rock to a fern-hung opening on the mountain top, about 60 m back from the
lip.

### The great hall

Arranged as the legend describes: a natural household for a troop of monkeys,
around an open floor.

- **The open floor** at the centre, under the light shaft: where the troop
  gathered round their king. Smooth, water-worn rock.
- **Stone benches**, ledges at sitting height, curving round the open floor
  in three broken arcs.
- **Sleeping niches** along the north wall: about twelve rock shelves at three
  levels, from the floor to 4 m up, the upper ones reached by vine ladders and
  handholds. Some are big enough for one monkey, some for a family.
- **The kitchen** along the south wall: three **stone stoves** (hollows in the
  rock with natural flues to cracks in the vault, soot-blackened), a long
  shelf, **stone pots** and **stone bowls** (round water-worn stones, hollowed),
  and **stone basins** fed by a trickle from the wall.
- **The throne dais** at the back, facing the bridge and the mouth, so whoever
  sits on the seat looks out through the hall and the falls toward his
  kingdom.
- **The banner pole:** a socket in the rock beside the dais, where Sun Wu Kong
  raised his banner when he declared himself Great Sage Equal to Aethra.

### Sizes and clearances

- Every route (ledge, mouth, bridge, hall floor, dais ramp) is at least 2 m
  wide, wider than the 1.5 m minimum, so blorbs and the party pass easily.
  Manchego cannot reach the cave: the ledge is too narrow for a horse.
- Headroom is at least 4 m everywhere a route runs. Stalactites hang only over
  the niches and the spring pool, never over a route.
- The stoves' hearths keep 1.35 m clear in front.

## 4. The two states

### Forgotten (from the start of the game)

- **The falls** look like any waterfall, and the mouth is only a dark shape
  through the water.
- **The ledge** is overgrown with ferns and draped in fig roots and moss, so
  from the gorge it reads as part of the cliff.
- **The stele** is crusted with moss and flowstone, its carving worn smooth.
- **The iron bridge** is rusted dark, but sound.
- **The hall:** woven mats rotted to fibre in the niches; the stoves cold, with
  old ash in their hollows; stone bowls still set out on the shelf, one fallen
  and broken; roots hanging from the vault; moss and seedlings in the light
  shaft's pool of daylight; a few fallen stones on the floor, none on a route.
- **The banner pole** stands bare in its socket, with a scrap of faded cloth
  knotted at the top.
- **The seat** is empty, with leaves drifted across it.
- **No text and no hint.** Nothing tells the player the cave is there. They
  find it by following the river to its source, as the monkeys of the legend
  did, or by jumping through the falls, as the stone monkey did.

### Reclaimed (after Sun Wu Kong returns)

The quest that brings him back is deferred. When he reclaims his seat:

- The ferns on the ledge are cleared, and the mouth stands open behind the
  water.
- The stoves are lit and the stone bowls are full of fruit from the mountain
  top.
- New woven mats lie in the niches.
- A new banner flies from the pole: deep red and gold, with no lettering.
- Sun Wu Kong sits on the stone seat when he is not travelling with the party.

Whether the village's monkeys come back to the mountain, and whether he rules
them again, stays open.

## 5. Style audit

| Element | Term | Tradition |
|---|---|---|
| Cliff, cave, vault, flowstone | limestone karst escarpment and solution cave | natural |
| Beds, benches, stoves, shelves | rock shelves and niches | the legend's naturally furnished cave |
| Bridge | iron plate bridge (*tiěbǎn qiáo*) | the legend |
| Stele | a standing stone tablet (*bēi*), carving worn away | Chinese commemorative stele, without legible text |
| Mats, vine ladders | woven and lashed vine | the Plant Kingdom's lashed vine kit |
| Banner | a long pole banner | the legend |

Two traditions at most in any one view: nature and the legend's few objects.
**Exclusions:** carved temple architecture, statues of Sun Wu Kong, Buddhist
shrines, roofs, timber framing, lanterns, legible inscriptions, and anything
built by the Chinese village's people.

## 6. Systems and collision

- **Terrain:** the river's coverage ends in a rounded pool at the falls instead
  of at the kingdom's edge. The water sheet stops there too. West of the cliff
  the terrain rises to the mountain-top plateau, a gentle rise of about 35 to
  50 m. The terrain grid is about 18 m a cell, too coarse for a cliff, so the
  **cliff face, gorge walls and the cave** are authored rock geometry built over
  a terrain ramp, with the terrain excluded from under the cave's footprint so
  the cave floor is the only walkable surface there.
- **Collision:**
  - Solid (`CollisionPolicy` blocking): the cliff, gorge walls, cave walls and
    vault, and the stele.
  - Parkour (deliberate landing tops): the ledge, the benches, sleeping niches,
    the dais, the bridge and the boulders in the gorge.
  - Decorative: ferns, roots, moss, mats and the banner cloth.
- **The falls:** a translucent animated water curtain with no collision, so the
  hero passes straight through it. Passing through briefly plays the wet
  splash. The pool is ordinary river water.
- **The mountain-top stream:** a separate small water volume at plateau height,
  shallow enough to wade, ending at the lip.
- **Light:** daylight through the falls (an animated caustic on the entrance
  chamber's walls) and the shaft over the hall. In the reclaimed state, the
  three stoves' fires add warm light.
- **Safe zone:** the cave and its ledge.
- **Performance:** the cave is a small set of large rock masses. Hall detail
  loads only when the player is near the falls.

## Fixed, proposed and open

**Fixed (user direction, 2026-10-06):** the Water Curtain Cave appears in the
Plant Kingdom; it is behind a waterfall on a cliff at the river's source; it
is long forgotten until Sun Wu Kong returns and reclaims his seat.

**Proposed:**
- the west-end site at `x ≈ -640`, with the gorge, the cliff and the falls;
- the river beginning at the plunge pool;
- the cave's plan, its natural furnishing and the iron bridge;
- the stone egg;
- the old peach trees on the mountain top;
- the forgotten and reclaimed states.

**Open:**
- the quest that brings Sun Wu Kong back to the cave;
- whether the monkeys return to the mountain, and whether he rules them again;
- what, if anything, the cave holds for the player.
