# Moy: the market lanes street buildings (proposed, 2026-10-13)

Read with `docs/architecture/city.md` (sections 5 and 7, the market lanes)
and the market lanes charter in `docs/style_charters.md`. The plan data is
in `tools/city_layout.py` (`market_kit_for`), emitted to `CityPlan.LOT_KITS`
and `CityPlan.BUILDING_KITS`.

## 1. Precedent

- **Hong Kong's tenement shophouses (*tong lau*)**, in Sheung Wan, Wan Chai,
  Mong Kok and Sham Shui Po. They are narrow, deep houses with a shop at the
  ground and flats above, and they come in two generations:
  - **The veranda type** (to the 1930s): four storeys, rendered fronts, a
    veranda on square columns over the pavement, stacked verandas above.
  - **The post-war type** (1950s and 60s): six to nine storeys, mosaic tile,
    cantilevered balconies, and on corners the Streamline Moderne rounded
    corner with curved balconies (the corner tong lau of Prince Edward and
    Mong Kok).

  Pairs of tong lau often share one stair on their party wall.
- **Tokyo's covered shopping streets (*shōtengai*)**: an arched translucent
  roof over a shopping street, shopfronts with roll shutters and cloth door
  curtains (*noren*).

## 2. History (proposed)

The market lanes were Moy's first growth outside the well town. When the
Windworks came, its first workers needed homes near the work, and the
**boom houses** went up along the new streets south of Old Moy: four and
five storeys with verandas, built in the same boom as the Grand Hotel. As
the city grew the lanes filled in and built higher, with the **tile houses**
of six to nine storeys, mosaic-tiled, with balconies and lifts added later.
The wet market, the night market on Lamp Lane and the covered arcade on
Arcade Street grew up among them.

## 3. The kit

Every market-lane lot takes one of three things:

| Kit | Where | Count (plan) |
|---|---|---|
| **Boom house** | lots of 4 or 5 storeys | 21 |
| **Tile house** | lots of 6 to 9 storeys | 54 |
| **Lock-up shop** | slivers under 6 m across with no neighbour to share a core | 8 |

### 3.1 The boom house (4 or 5 storeys)

- **Front:** rendered, in one of the five palette colours, with a 0.6 m
  plinth of grey tile.
- **The veranda** (on main streets and squares only: South Street, the Park
  Ring and Market Square): square columns 0.5 m, 2.4 m out from the front,
  carrying a covered walkway over the pavement at the ground and an open
  veranda on every floor above. Each veranda is a deep balcony behind a
  timber balustrade. On lanes and shopping streets there is no veranda, and
  each floor has a shallow balcony instead.
- **Windows:** tall French windows (1.0 × 2.2 m) onto the veranda, with
  timber shutters (these are dwellings, and the shutters are narrow).
- **Roof:** a 1.1 m parapet, with a rooftop greenhouse on some (Sora's
  mother kept the first one; the census's rooftop greenhouses are here),
  laundry frames or water tanks on the rest.

### 3.2 The tile house (6 to 9 storeys)

- **Front:** mosaic tile in a palette colour, a grey tile plinth.
- **Canopy:** a cantilevered concrete canopy over the shopfront, 1.5 m
  deep, 3.6 m up.
- **Balconies:** cantilevered, 1.2 m deep, with a steel rail; later plant
  cages and enclosures on some.
- **Windows:** wide steel windows (2.0 × 1.4 m) behind the balconies.
- **The rounded corner:** on a corner lot (a street on two faces), the
  corner is a superellipse curve the full height, with curved balconies
  wrapping it: the city's signature silhouette (city.md 5) on its
  oldest-feeling streets.
- **Lift:** houses of 7 storeys or more add a lift in a glass shaft on the
  back face, against the core.

### 3.3 Plan: the shared core, the floors

- **The ramp core** is the tower house's switchback (3.4 × 5.8 m, two
  flights of 2.6 m either side of a spine wall, 1.4 m landings). In a pair
  of houses under 9 m across it **straddles the party wall**, 1.7 m in each
  house, at the front: **one shared house door** on the street between the
  two shopfronts opens straight onto the core's foot, as a tong lau pair's
  stair door does, and every landing has a door into each house. The plan
  pairs 52 houses into 26 pairs. A wider house has its own core, at the
  front against one side wall, with its own door beside the shop.
- **Area check:** a 6 m house sharing a core keeps 6 − 0.5 (walls) − 1.7 =
  3.8 m of width beside the core and the full width front and back of it.
- **Floors:** the ground is the shop, wrapping round the core and through
  to the back. Above, one flat a floor in a narrow house, two in a wide one
  (front and back), entered from the core landing.
- **Services:** kitchens and bathrooms at the back, on a soil stack in the
  back wall; AC units, laundry poles and water tanks where people would put
  them.

### 3.4 The lock-up shop

A sliver lot too narrow for a house (3 to 5 m across) with no neighbour to
share a core holds a **two-storey lock-up**: a shop with a roll shutter
below and its store or a small room above, reached by the shop's own short
ramp. They stand at the ends of rows, on Market Lane and at Lamp Lane's
corners, like the lane-side lock-ups of Hong Kong.

### 3.5 The streets they make

- **Arcade Street** through the market lanes (south of Market Street) is
  roofed in the shōtengai manner: steel arches carrying translucent panels,
  9 m up, the full 8 m width. No verandas here; the roof does their job.
- **Lamp Lane** (4 m) is the night market. At dusk stalls open along it and
  strings of lanterns are hung across it from house to house.
- **Signs:** every house carries 0 to 3 stacked picture signs; busier
  streets carry more, and some hang across the lanes. None is lettered.

### 3.6 Play

- **Veranda columns and stacked verandas** are a ladder up a boom house
  front, each floor a landing.
- **Balcony rails** give holds every storey; the canopy at 3.6 m is reached
  by a blorb bounce from a stall roof or a column top.
- **Signs and lantern strings** are low swing anchors across the lanes.
- **The arcade roof** is a 9 m high road along Arcade Street, reached from
  the tile houses' balconies.

### 3.7 Collision

The houses are solid (`CollisionPolicy` blocking). Parkour landings:
verandas, balconies, canopies, parapets, roofs, the arcade roof's arches.
Decorative: signs' faces (their frames are solid), lantern strings, plants,
laundry.

## 4. The market flats (number 34)

Four tile houses built together as one terrace, 28 × 24 m and 8 storeys,
rounded at the corner, with laundry on the shared roof. Mei and Lily Chan,
Rosa, Wen and Pia Rowe live here.

## 5. Plan data

`market_kit_for` gives every market-lane lot:
- `kit`: `tong_lau` or `lockup`;
- `gen` (`boom` or `tile`);
- `veranda` and `corner`;
- `colour` (0 to 4, never the same as a touching neighbour's);
- `signs` and `roof`;
- `core` (`own` or `shared`), `pair` (the lot it shares with) and `lift`.

The generator and the validator check that:
- each house's generation fits its storeys;
- only boom houses have verandas;
- every house under 6 m across shares a core;
- core pairs are mutual;
- lock-ups are two storeys.
