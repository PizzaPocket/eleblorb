# Caldera Heartworks: the lava vortex

Status: **proposed for review, 2026-10-17 (second version).** The user cut the
first two proposals back to their core idea: Jewel Changi's Rain Vortex, in
lava. This document replaces them. The only things to design down here are:

- the one great cascade;
- the levels round it;
- the crossings;
- the ramps that join them.

Sources:
- **Plan:** `tools/fire_caldera_heartworks_layout.py`, which writes
  `scripts/fire_caldera_heartworks_plan.gd` (`FireCalderaHeartworksPlan`).
- **Walks:** built with the same system as the surface
  (`fire_caldera_walkways.md`, `tools/walkway_kit.py`).
- **Model:** `docs/drawings/fire_caldera_3d.html`.

Depths are metres below the lava's surface (world height 29.2).

## 1. The idea

**The cascade.** In the middle of the reservoir, the lava turns into a vortex
and pours through a round oculus in the reservoir's floor. It falls as one
thick column, perpetually, through a great chamber into a collection pool at
the bottom. Something unseen returns the flow to the reservoir and keeps it
falling; it is not drawn.

**The use.** For the lava people the chamber is where the volcano's flow is
kept and watched. More than that, it is a public place: they come down to be
in the heat and the light of the lava. That is the whole program: a beautiful
public space round one cascade.

**The way in.** There is only one, through the lava. With the Lava Helm, a
swimmer dives to the oculus and goes down with the cascade, swimming or
falling, into the pool. To leave, they step into the pool and swim back up
the cascade to the reservoir. There are no dry entrances, lifts or service
shafts.

## 2. The section

| Element | Depth | Plan radius | What |
|---|---:|---:|---|
| Reservoir's surface | 0 | bank ≈ 52 | one continuous lava surface, turning into the vortex at its centre |
| Oculus | 7 | 7 | the opening in the reservoir's floor, with a refractory lip the lava pours over all round |
| Glass dome | 7 at the oculus to 18 at the wall | 7–48 | the reservoir's floor: refractory glass on a blackened-steel diagrid, carrying the lava on its back, so the whole ceiling glows |
| Rim wall | 18–48 | 48 | cast basalt |
| Upper terrace | 24 | 42–48 | |
| Middle terrace (Middle Bridge) | 32 | 37–48 | the Middle Bridge crosses on the far side |
| Lower terrace (Lower Bridge) | 40 | 32–48 | the Lower Bridge crosses on the gate's side |
| The Floor | 48 | 16–48 | the chamber's public room, round the cascade's opening |
| Pool gallery | 58 | 10.5–24 | under the Floor, ringing the pool |
| Collection pool | 58.8 | 0–10.5 | the cascade lands here |

- **The cascade** is a column 12 m across at the oculus, narrowing to 8.4 m as
  it falls 51.8 m to the pool. It passes through the Floor's 32 m opening,
  which is "mostly covered": the Floor surrounds it.
- **The terraces** step in toward the cascade as they go down, like Jewel's
  terraced valley. Each terrace's edge is carried on a colonnade over the
  level below, so the space under each terrace is a shaded arcade.
- **Heat.** Every walk is 5 m or more from the cascade.

## 3. Crossings and ramps

**Two bridges** cross the void on chords 14 m from the cascade's axis, 8 m
clear of it, so the cascade is seen face-on from each:

- the **Middle Bridge**, at the Middle terrace, on the far side;
- the **Lower Bridge**, at the Lower terrace, on the gate's side, 8 m lower.

**Double ramps** join each terrace to the next. From a balcony on the upper
terrace's edge, two ramps sweep apart in opposite directions along the void,
mirrored, and land on the terrace below. This is the Renewal deck's horseshoe
stair made gentle:

| Pair | From → to | Balcony at | Each ramp |
|---|---|---:|---|
| K32 | Upper → Middle terrace | −90° (gate side) | 48 m at 16.7%, sweeping 75° along a 39.5 m radius |
| K21 | Middle → Lower terrace | 90° (far side) | 48 m at 16.7%, sweeping 86° along 34.5 m |
| K1F | Lower terrace → the Floor | 90° | 48 m at 16.7%, sweeping 124° along 24 m, over the Floor |

**The double helix** joins the Floor to the pool gallery, after Chambord's
stair:

- two ramps, half a turn apart, wind round the cascade inside the Floor's
  opening;
- each leaves the Floor by a level gangway tangent to the helix, turns 270°
  at a 12.8 m radius, and lands on the pool gallery;
- each is 60 m long at 16.7%, and they pass about 6 m clear above one another.

**Every walk** uses the one guard of the surface's walkway system: glass
panels, steel posts, one stainless handrail at 1.09 m. The guard stands
wherever the drop is a metre or more. The pool gallery's edge is a kerb, so a
lava swimmer can step in.

## 4. Materials and light

- **Construction.**
  - The terraces, the Floor and the pool gallery are cast basalt: ground-borne.
  - The bridges, ramps and helix are glass decks on blackened steel: carried.
  - The guard is the same as on the surface.
- **Light** comes from the lava:
  - the dome glows with the reservoir's lava above it;
  - the cascade lights the chamber from within;
  - the pool glows at the bottom.

## 5. To build it

- **Read every number from `FireCalderaHeartworksPlan`;** never edit it by
  hand. Its `LEVELS` give each level's outline and guard lines. Its `FLIGHTS`
  give each ramp's profile and guard lines.
- **Retire the old constants.** When the review approves this, delete
  `FireCalderaPlan`'s `HEARTWORKS`, `HEART_LEVELS`, `HEART_FALLS`,
  `HEART_RISERS`, `LOWER_ROOMS`, `LOWER_PASSAGES`, `IMMERSION_SHELVES`,
  `LIFTS` and `THERMAL_BRANCHES`, and move `tools/validate_fire_plan.gd` onto
  this plan.
- **Replace the reservoir's bed.** `FireCalderaGround.height` inside the bank
  becomes the dome (with the oculus open), rising steeply outside the dome to
  the bank.
- **Make the cascade work.** It is a swimmable lava column: the lava surface
  and hazard API must treat it as lava, so the Lava Helm swimmer can descend
  and ascend in it.
- **Collision.** Substantial geometry is solid (`CollisionPolicy`):
  - the dome;
  - the rim wall;
  - every level and its guards;
  - the bridges and ramps;
  - the colonnades.

## 6. What this drops

The second proposal had a dry Crown Gallery, crown stairs, three falls, the
Renewal shelf, the Forge Arm, six rooms, three lava entries with race wells,
four service shafts and three return risers. All of it is gone.

The census places some residents' work in the old lower rooms (L1 to L5 in
`FireCalderaPlan.RESIDENTS`), and that now needs revising:
- Tovan and Miru's manifold (L1);
- Selka's observatory (L2);
- Aru's archive (L3);
- the Kel forge (L4);
- the materials bay (L5).

## 7. Open

1. Where do the residents who worked in the lower rooms work now? The likely
   answer is their surface buildings.
2. Are the sizes right? The chamber is 96 m across, the cascade falls 51.8 m
   to the pool, and the Floor is 48 m below the lava.
3. Is the name right: **Caldera Heartworks**, or something else?
