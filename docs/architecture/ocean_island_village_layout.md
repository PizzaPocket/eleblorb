# Kai Mālie: Civic Layout Plan

Status: dimensioned schematic for review (2026-10-06). Read with
`ocean_island_village.md`, which owns the community, households, charter and
language. This document places them on the island.

## 1. Survey

Computed from `ocean_kingdom_terrain.gd`'s height function (`_raw_height`):

- The main island's `ISLANDS` entry gives a radius of 116 m, but most of that is
  underwater slope. **Dry land reaches only about 55 m from the centre** at
  world `(-118, 72)`, in every direction: an island about 110 m across.
- **Profile from the centre outward:** a broad crown at 10.5 m, then 10.1 m at
  10 m out, 9.0 m at 20 m, 7.3 m at 30 m, 5.0 m at 40 m, 2.2 m at 50 m and the
  waterline at about 55 m. The ground steepens toward the sea: about 17 percent
  at 20 to 30 m, 28 percent at 40 to 50 m and 32 percent at the shore. **There
  is no beach and no coastal flat.**
- Beyond the shore the seabed falls fast: 18 m deep 60 m from the centre on the
  dock side, 40 m deep at the dock.
- **The arrival dock** at world `(0, 0)` stands about **83 m off the nearest
  shore**, over 18 to 40 m of water. (The earlier briefs said 23 m; that was
  wrong.) Arrivals swim or fly.
- The terrain mesh samples every 10.3 m, too coarse for terraces, a beach edge
  or house platforms.

The village program does not fit this terrain as it stands. The plan below
starts with the terrain it needs.

## 2. Frame

Local `u` points from the island's centre toward the arrival dock (world
direction `(0.854, -0.521)`); `v` points to its right (world `(0.521, 0.854)`).
Local `(0, 0)` is the island centre, world `(-118, 72)`. Heights are metres above
sea level. In this frame the dock is at `u = 138`.

## 3. Geology and terrain

### An old, eroded volcano

Like the real Hawaiian islands, the main island is volcanic: an old shield
volcano, long extinct and worn down by rain. Its windward face has been cut
into a deep green valley, the kind of amphitheatre-headed valley where Hawaiians
built their taro terraces (Waipiʻo, Waiʻanae and many others). The young crater
belongs to the cage island instead (section 9), so the two islands tell one
geological story: an old island and a young one.

**Trade winds** blow from the world north-east. The dock-facing side (`+u`)
is windward: wet, lush and cut by the valley. The far side is leeward and drier.

### Terrain changes

The current dome (10.5 m high, dry land to about 55 m) cannot hold a valley.
Replace the main island's `ISLANDS` dome with an authored island shape:

1. **Crown and ridges:** raise the crown to about **28 m** at local `(0, 0)`,
   with two forested ridges running toward the sea on either side of the
   valley, falling to lava-rock **headlands** at the shore near `v = -60` and
   `v = +62`. Keep the far (leeward) side a broad, gentler slope to about 58 m
   from the centre.
2. **The valley:** cut into the windward face between the ridges, its axis along
   `v = -12`. The head is a steep, fern-hung amphitheatre wall at about
   `u = 6..12`, with a spring and a thin waterfall at `(8, -18)` dropping from
   +20 m to a pool at +11 m. The valley floor runs from the pool down to the
   coastal plain at `u = 38`, about 40 m wide at its mouth and 18 m at its
   head, its walls rising 10 to 15 m on each side.
3. **Taro terraces:** six level terraces across the valley floor between
   `u = 14` and `u = 38`, `v = -35..+5`, each about 4 m deep and 0.8 m above the
   one below, from +7.4 m down to +3.4 m, held by low lava-rock walls.
4. **Coastal plain:** at the valley mouth, from `u = 38` to about `u = 60`
   across `v = -45..+58`, falling gently (3 to 5 percent) from +3.0 m to
   +1.2 m. This is where the village stands.
5. **Beach:** sand from `u = 60` to `u = 68` between the two headlands, to the
   waterline at about `u = 66`.
6. **Reef flat:** a shallow shelf 0.5 to 2 m deep from the beach out to
   `u = 130`, across `v = -60..+45`, ending in a steep reef edge. Hawaiian
   fishponds were built on reef flats like this, and it lets a short pier reach
   the dock on piles in shallow water.
7. **Local mesh detail:** the valley and village need finer terrain sampling,
   or authored ground pieces with their own collision, so terraces, the beach
   edge, the stream and house platforms are not cut by the 10.3 m grid.

The dock stays where it is, now just beyond the reef edge in deep water, so the
portal and its return spawn do not move.

## 4. The ahupuaʻa, crown to reef

| Zone | Local extent | Use |
|---|---|---|
| Uplands | the crown, the ridges and the leeward side | forest left wild |
| Valley head | `u = 0..14` | the spring, the waterfall, the fern-hung wall |
| *Loʻi kalo* | valley floor `u = 14..38`, `v = -35..+5` | flooded taro, fed by the *ʻauwai* |
| Village | coastal plain `u = 38..60` | homes, green, civic buildings |
| Beach | `u = 60..68` | canoe launch, pier head, surf access |
| Reef flat | `u = 68..130` | the fishpond, Makoa's net fishing, the pier |
| Reef edge and sea | `u > 130` | the dock, the surf break, the sea folk meeting rocks |

**Water:** the spring and waterfall feed a stream that runs down the valley's
south side (`v ≈ -36`), crosses the plain at `v = -42` (south of the Kealoha and
Akana homes) and enters the fishpond's inland side at `(70, -42)`. At the valley
head, an *ʻauwai* (an earth-and-stone ditch 0.6 m wide) leaves the stream and
follows the contour to the top terrace. Water steps down through the six
terraces by small spillways and drains back into the stream, so taro water
carries nutrients into the pond, as in traditional ahupuaʻa. Small footbridges
cross the stream where the beach path and terrace paths meet it.

## 5. Plan

```
               crown ridge (28 m)                 crown ridge
                      ╲      valley head: waterfall ● pool     ╱
                       ╲     ┌─ loʻi kalo, six terraces ─┐    ╱
              forested  ╲    │ ▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤ │   ╱  forested
               ridge     ╲   │ ▤▤▤▤▤▤ stream ~~ ʻauwai ~~│  ╱    ridge
                          ╲  └──────────────┬────────────┘ ╱
      Kealoha   Kahananui     HĀLAU (head of green)      Medeiros   Kahale
       Akana      ╲      ~ VILLAGE GREEN ~       ╱      Nakamura store
   ~stream~        ╲           │             ╱            and shave ice
     Okafor guest   ╲          │          ╱             CANOE HOUSE
  lava    house      ═════ PIER HEAD ═════                 launch      lava
  headland ~~~~~~~~~~~~~~~~~~~ beach ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ headland
    FISHPOND (loko kuapā)  ║ pier, 3.6 m        pirates' beach (barred)
     curved lava wall,     ║                       surf break
     two mākāhā gates      ║
   sea folk meeting rocks  ║
   ─ ─ ─ ─ reef edge ─ ─ ─ ║ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                        ARRIVAL DOCK (u = 138)
```

The arrival view, looking inland from the dock: the pier across the reef flat,
the beach between two dark lava headlands, the village around its green, and
behind it the valley's taro terraces climbing between steep green walls to a
waterfall.

## 6. Footprints

Local `(u, v)` centres; footprints include *lānai* and eaves. The first size
figure runs along `v` (across the slope), the second along `u` (up and down
it). Buildings keep at least 3 m apart and stay off the taro terraces
(`u < 38`, `v = -35..+5`). Homes stand on
post-and-pier foundations over lava-rock piers, floors 0.8 m above the ground.

| Building | Owner | Centre | Size | Faces |
|---|---|---|---|---|
| *Hālau* | the community; Puanani teaches here; kūpuna meet here | `(42.5, 0)` | 18 × 9 m, *hale* on a 0.8 m *paepae* | down the green to the sea |
| Village green | public | `(52.5, 0)` | 11 m deep × 16 m wide, irregular | — |
| Kahananui home | Kawika, Malia, Keoni | `(43, -18)` | 11 × 8 m | the green |
| Kealoha home | Leilani, Makoa, Noelani | `(43, -33)` | 12 × 8 m | the green and the *loʻi* behind |
| Akana home | Puanani | `(54, -34)` | 8 × 7 m | the beach path |
| Okafor guest house (rest point) | Sam | `(55, -20)` | 14 × 9 m, two storeys | the pier head |
| Medeiros home and ukulele workshop | Manny, Kahala | `(44, 18)` | 12 × 8 m; workshop wing toward the green | the green |
| Kahale home | Kahiau, Iolana | `(42, 32)` | 9 × 7 m | the canoe house |
| Varga cottage | Elena | `(52, 32)` | 7 × 6 m | the sea |
| Nakamura store and shave ice | Hiro, Grace | `(56, 16)` | 12 × 8 m with a *lānai* counter | the pier head |
| Nakamura home | Hiro, Grace | above the store, second storey | — | — |
| Canoe house (*hale waʻa*) | Kahiau; the village's canoes | `(64, 33)` | 16 × 7 m, *hale* on a low platform on the beach, open to the sea | the launch |
| Kahala's plant garden | Kahala | `(36, 12)` | 10 × 6 m beds | — |
| Pier | public | from `(64, 0)` to `(134, 0)` | 3.6 m wide on short piles over the reef flat | — |
| Fishpond (*loko kuapā*) | Kawika | wall arc on the reef flat, `u = 72..108`, `v = -58..-20` | about 30 × 36 m enclosed | — |
| Sea folk meeting rocks | shared | `(126, -40)` | a natural lava shelf at the reef edge | the deep water |
| Pirates' beach | (barred) | beach `v = +44..+58`, beyond the canoe house | — | the anchorage |
| Surf break | public | reef edge, `v = +20..+45` | — | — |

Elena's cottage (7 × 6 m) adds a home for her; the census brief gave the
newcomers a household but no building. Sam lives in the guest house.

## 7. Routes

| Route | Width | From → to |
|---|---|---|
| Pier | 3.6 m | dock → pier head on the beach |
| Main path | 3.0 m | pier head → green → *hālau* → *loʻi* stair-ramp to the top terrace |
| Beach path | 2.5 m | canoe house ← pier head → guest house → fishpond wall |
| House paths | 2.0 m | green to each home's *lānai* |
| Terrace paths | 1.5 m on bund tops; ramps 2.0 m between terraces | along the *loʻi* |
| Fishpond wall | 2.0 m along its crest | beach → the *mākāhā* gates |

All public routes take the hero, Blorbus, Xiao Hou Zi and a mount. Level
changes of more than 0.25 m use ramps no steeper than 1:6. Terrace bund paths
are narrow by nature; one 2 m ramp per terrace keeps the *loʻi* reachable.

## 8. Gameplay anchors

- **Arrival:** the pier gives the dock a walking route ashore. Swimming and
  flight still work.
- **Rest point:** Sam's guest house, 25 Tokoins (the kingdom's inn rate), waking in its upstairs guest
  room; the party gathers on its *lānai*.
- **Shop:** the Nakamura store's *lānai* counter facing the pier head.
- **Discord state:** the meeting rocks stand empty and the pirates' beach is
  roped off; after harmony returns, sea folk visit the rocks and the pirates
  trade on their beach again.
- **Protected bounds:** the whole island and reef flat.

## 9. Cage island terrain (same pass)

The cage island at world `(112, 88)` has only about 10 m of dry radius. It
becomes a young **crescent crater** (a tuff cone, after Molokini off Maui) with
its rim open toward Kai Mālie and the dock. See `ocean_cage_island.md` for its
shape. Its terrain is authored rather than the generic dome.

## Fixed, proposed and open

**Fixed:** the community and charter in `ocean_island_village.md`; the dock and
portal position.

**Proposed:** the corrected survey; the old eroded volcano raised to 28 m with a
windward valley, ridges and lava headlands; trade winds from the north-east;
the coastal plain, beach, reef flat, taro terraces, waterfall and stream; the ahupuaʻa water route from spring to fishpond; every
footprint and route above; the pier from the dock; Elena's cottage; the cage
island as a crescent crater.

**Open:** finer terrain sampling or authored ground pieces for the village
area; the store's stock.
