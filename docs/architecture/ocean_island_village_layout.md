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

## 3. Terrain the village needs

All of it on the dock-facing side, so the rest of the island keeps its present
shape and dense forest.

1. **Coastal plain:** extend the dry land on the dock side to about `u = 66`
   across `v = -45..+58`, with a gentle 3 to 5 percent fall from +3.0 m at
   `u = 38` to +1.2 m at `u = 60`. This is where the village stands.
2. **Beach:** sand from `u = 60` to `u = 68`, falling from +1.2 m to the
   waterline at about `u = 66`.
3. **Reef flat:** a broad shallow shelf 0.5 to 2 m deep from the beach out to
   `u = 130`, across `v = -60..+45`, ending in a steep reef edge. Hawaiian
   fishponds were built on exactly this kind of reef flat, and it lets a short
   pier reach the dock on piles in shallow water.
4. **Taro terraces:** six level terraces cut into the slope between `u = 14` and
   `u = 38`, `v = -35..+5`, each about 4 m deep and 0.8 m above the one below,
   from +7.4 m down to +3.4 m. Low lava-rock walls hold each terrace.
5. **Spring:** a small spring pool at the edge of the crown forest, `(8, -18)`,
   +10 m.
6. **Local mesh detail:** the village area needs finer terrain sampling, or
   authored ground pieces with their own collision, so terraces, the beach edge
   and house platforms are not cut by the 10.3 m grid.

The dock stays where it is, now standing just beyond the reef edge in deep
water, so the portal and its return spawn do not move.

## 4. The ahupuaʻa, crown to reef

| Zone | Local extent | Use |
|---|---|---|
| Uplands | `u < 14`, the crown and the island's far side | dense forest left wild; the spring |
| *Loʻi kalo* | terraces `u = 14..38`, `v = -35..+5` | flooded taro, fed by the *ʻauwai* |
| Village | coastal plain `u = 38..60` | homes, green, civic buildings |
| Beach | `u = 60..68` | canoe launch, pier head, surf access |
| Reef flat | `u = 68..130` | the fishpond, Makoa's net fishing, the pier |
| Reef edge and sea | `u > 130` | the dock, the surf break, the sea folk meeting rocks |

**Water:** the spring feeds the *ʻauwai* (an earth-and-stone ditch 0.6 m wide)
along the contour to the top terrace. Water steps down through the six
terraces by small spillways, then runs in a second ditch to the fishpond's
inland side. The taro water brings nutrients into the pond, as it did in
traditional ahupuaʻa.

## 5. Plan

```
                         uplands forest (crown, 10.5 m)
                              spring ●
          ┌─────────── loʻi kalo, six terraces ───────────┐
          │  ▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤  │   ʻauwai ~~
          └──────────────────────┬───────────────────────────┘
      Kealoha   Kahananui     HĀLAU (head of green)      Medeiros   Kahale
                 ╲             │                       ╱
       Akana      ╲      ~ VILLAGE GREEN ~       ╱      Nakamura store
                   ╲           │             ╱            and shave ice
     Okafor guest   ╲          │          ╱             CANOE HOUSE
     house           ═════ PIER HEAD ═════                 launch
   ~~~~~~~~~~~~~~~~~~~~~~~~ beach ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FISHPOND (loko kuapā)  ║ pier, 3.6 m        pirates' beach (barred)
     curved lava wall,     ║                       surf break
     two mākāhā gates      ║
   sea folk meeting rocks  ║
   ─ ─ ─ ─ reef edge ─ ─ ─ ║ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                        ARRIVAL DOCK (u = 138)
```

The arrival view, looking inland from the dock: the pier running across the
reef flat to the beach, the canoe house to the right, the green and the
*hālau* framed by homes, and the taro terraces stepping up into the forest
behind.

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
- **Rest point:** Sam's guest house, 10 Tokoins, waking in its upstairs guest
  room; the party gathers on its *lānai*.
- **Shop:** the Nakamura store's *lānai* counter facing the pier head.
- **Discord state:** the meeting rocks stand empty and the pirates' beach is
  roped off; after harmony returns, sea folk visit the rocks and the pirates
  trade on their beach again.
- **Protected bounds:** the whole island and reef flat.

## 9. Cage island terrain (same pass)

The cage island at world `(112, 88)` has only about 10 m of dry radius, too
small for its 18 m cage and stands. Raising its `ISLANDS` entry from radius 31 m
and height 3.8 m to radius 70 m and height 5 m gives about 27 m of dry radius,
enough for the cage, stands and a landing beach. Its centre stays 140 m from
the arrival dock.

## Fixed, proposed and open

**Fixed:** the community and charter in `ocean_island_village.md`; the dock and
portal position.

**Proposed:** the corrected survey; the coastal plain, beach, reef flat, taro
terraces and spring; the ahupuaʻa water route from spring to fishpond; every
footprint and route above; the pier from the dock; Elena's cottage; the cage
island's enlargement.

**Open:** finer terrain sampling or authored ground pieces for the village
area; the store's stock.
