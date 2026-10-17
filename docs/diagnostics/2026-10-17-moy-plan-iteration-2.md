# Moy plan, iteration 2: after the first playable prototype

2026-10-17. Plan-side revision made after reviewing the first prototype
(`2026-10-17-moy-prototype-design-iterations.md`, `-readiness.md`,
`-performance.md`) with the owner. It changes the **plan data**
(`tools/city_layout.py` → `scripts/city_plan.gd`), the drawings and the brief
(`city.md` 6c, 6e, 6f, 6g, 7a). It does **not** change the game: the next
prototype pass rebakes from this data. Read this before
`docs/architecture/moy_playable_prototype.md`, which it amends.

## Review of the first prototype's deviations

| Prototype change | Verdict | Why |
|---|---|---|
| Supports and Deck columns reaching the ground | **Keep** | They were bugs: supports started 4 m up; Deck columns were not built. |
| Estate blocks on open void decks; everything else on the ground | **Keep** | Correct reading of the plan (7d). Only the North Estate's blocks stand on stilts. |
| Station flights in alternating lanes | **Superseded** | Right instinct, but escalators come in up/down pairs; now scissor stacks of pairs (6f). |
| Cinema Lane omitted, `ESTATE` exported, Mara's frontage seen by the validator | **Keep** | Plan errors the prototype found. |
| Each car its own body, articulating | **Keep** | |
| Turbines facing the wind at 2 rpm, colour, offset surfaces, pond water | **Keep** | |
| Spine gate flyover to +20 m | **Remove** | It climbed 8 m in 28 m (29%); trains manage 4–7%. It also ran 38 m past the wall into the desert to come back down. |
| Train tunnels through the All-night Store, Hawker centre, Neighbourhood centre and lots | **Remove** | Misdiagnosed. The Spine's centreline was at x −557, 3 m east of its streets' centre (−560), so its trains cleared the east frontage by 0.17 m and any sweep margin hit it. Recentred, it clears both frontages by 3 m. |
| Block interlock at the gates | **Remove** | The lines no longer cross. (`city.md` also contradicted the summary on this.) |
| Four-second stops, even phasing | **Replaced** | By the timetable (6g). |

## What the plan now says

- **No track climbs.** Spine and Wall Line rail heads both at **+13.2**;
  Meridian at **+36**. `WALL.rail` = 13.2 (the wall's top, 12, plus a 1.2 m
  trackbed).
- **The Spine** runs on x = −560, from z −200 to +200, and ends at a
  terminus inside the wall at each gate (stations at z ±184). Its platforms
  run on, level, onto the Wall Line's inner platform 2.2 m away
  (`stations[...]._interchange`). Market Square's station is at z 124 (was
  138). Buffer stops at both ends.
- **The Deck's** Spine, Estate and Market walks moved to x −560 with it; the
  Neighbourhood centre is reached by a short bridge; the park's two gate ramp
  towers are retired (the Crossing's spirals and two new park-gate lifts take
  their place); the square escalators are 30° pairs, 11.3 m long; the park's
  two wing ramps to the Crossing are gone.
- **Platforms** (`PLATFORMS`): floor = rail + 1.0 (the car's floor): 14.2 and
  37.0; edge 1.4 m from track centre; 3 m wide; one beside each track; canopy
  3.2 m up. Wall Line platforms both sides at every gate.
- **The car** (`TRAIN`): 3.6 m tall (was 3.4), floor 1.0, 2.3 m clear inside,
  two doors a side per car (1.4 × 2.1 m) at ±2.4 m. `car_h` 3.6 everywhere.
- **Escalators** (`ESCALATORS`): pairs, scissors and double helices, always up
  and down. Spine stations have `_stacks` (a scissor under each platform:
  centre, direction, length, flights). Gate cores' flights from the scissor
  kit (max 7.2 m a flight).
- **The Crossing** (`CROSSING`): centre (−560, 0); halo at +18; `cores` is
  now empty; `spirals` holds two double helices at (−548, −10.6) and
  (−572, 10.6), eye 2 m, outer radius 4.6 m, 25°, levels 0 / 6.5 / 14.2 / 37,
  the bearings of their bridges in `opens`, `turns` and `rise_per_turn`
  derived. The halo has openings where they rise through.
- **The high line's piers:** −722 … −392 (set out ±18 from −560); the West
  Gate's tower carries the west end (the −755/−758 pier is gone).
- **The gate buildings:** the arch's legs moved 1.5 m west (x −363.5 to
  −341.5) and its cascades with them; the West Gate's towers are 25 m wide
  (to −757) and its cores sit in the outer piers (x −778.8). Both train halls
  follow the wall's curve: `train_hall.arcs` gives each leg's void polygon;
  `train_hall.v` is now (−9.0, 5.5) to hold both platforms.
- **The timetable** (`TIMETABLE`): a train every 60 real seconds on every
  line (every game hour on the same minute); 3 trains a line; 8 s stops, 12 s
  at interchanges; shuttles turn round at their termini (21 s Spine, 31 s
  Meridian) and cross over to the other track just outside them; service
  5:00–24:00, one Watch train each way on the Wall Line at night. `lines`
  holds each line's circuit: events (`stop`, `s` along the line, `dir`,
  `arr`, `dep`, `kind`: start/stop/end), `trains`, `circuit`, `offset`.
  A train j is at circuit time `(t − offset − j × 60) mod circuit`, where t
  is game minutes since midnight. `waits` lists the timed changes.

The city model (`docs/drawings/moy_city_3d.html`) runs its trains to this
timetable (look at `updateTrains` for a reference implementation of the
placement, including the crossover) and has a departure board, a 10× clock
and a night jump. New views: *The North Gate interchange* and *The
Crossing's spirals*.

## For the next prototype pass

**Rebake from the new data and delete:** the gate flyover geometry and its
approach ramps, the Spine's extension beyond z ±200, every train tunnel cut
into buildings and lots, the interlock, the old Crossing cores, the park gate
ramp towers, the 12° travelators, and the outer-only Wall Line hall
platforms.

**Build:** the recentred Spine and Deck walks; platforms at rail + 1.0 with
the 1.4 m edge on both sides of every track; the gate interchange slabs; the
scissor stacks under the Spine's platforms; the two double-helix spirals
(each hand a moving ramp: the up hand carries riders up, the down hand down,
with landings where each meets a level and short bridges per `opens`); the
glass lifts in their eyes and at the park gates; the curved train halls;
the 3.6 m car with door openings and an interior floor at +1.0; trains
driven by `TIMETABLE`.

**Accept when (in addition to the earlier contract):**
- a car-envelope sweep along the Spine reports no contact with any building
  or lot **without** any tunnel, and every line's rail stays at one height;
- the human and Xiao Hou Zi walk level from every platform into a stopped car
  through a door, and out again, at each line;
- trains stop with their doors at the marks, keep to the timetable for a full
  game day at 1× and 10×, cross over outside each terminus, and the Watch
  trains alone run between 0:00 and 5:00;
- both hands of each spiral and each flight of each scissor carry riders in
  their own direction, with headroom everywhere, and every level a spiral or
  stack lists can be reached from the street;
- changing at the North and South Gates takes a few level steps.

**Known risks:** the moving-ramp mechanics on a helix (riders on a curved
moving surface) are new; if the controller cannot ride one, build the
spiral's two hands as static ramps at 25° first and record that. The
validator `tools/validate_city_plan.gd` and the bake tools read `CROSS`,
`CROSSING`, `ARCH` and `WEST_GATE` keys that changed; update them with the
builder.
