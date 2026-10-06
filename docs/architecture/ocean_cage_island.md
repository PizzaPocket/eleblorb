# Ocean Kingdom: The Cage Island

Status: concept brief, first planning pass (2026-10-06). **Build the
environment only:** the crater, cage, stands and landing. Do not build the
inhabitants or any tournament NPCs, and do not write fight mechanics or
scripting, until asked. Read with `ocean_kingdom.md`. The inhabitants' species
is now decided (2026-10-06): tall anthropomorphic mongooses (section 3).

## 1. Premise

A smaller island holds a fighting cage and a population of tall
anthropomorphic mongooses who make the hero fight their cage match tournament.

## 2. Site: a crescent crater

The island is the low satellite at world `(112, 88)`, about 140 m
east-northeast of the arrival dock and in plain view of the gate and Kai Mālie's
beach. Today it is a 3.8 m dome with only about 10 m of dry radius. It becomes
a young volcanic **crescent crater**, a tuff cone like Molokini off Maui: a ring
of rim open on one side to the sea, with a sheltered bay inside. The main island
is old and eroded (see `ocean_island_village_layout.md`); this one is young and
still crater-shaped.

Local frame: origin at the crater's centre, `w` pointing from the centre
toward the arrival dock (world direction `(-0.786, -0.618)`).

- **Rim:** a crescent of tuff about 64 m across, its crest rising to **16 m**
  at the far side (`w = -30`) and falling toward the two horns. Outer slopes
  are steep and dry; inner slopes step down in natural ledges.
- **Breach:** the rim is open for about 100° of arc facing the dock (`w > 0`),
  where the sea has broken in.
- **Crater floor:** a level floor of packed sand and tuff about 26 m across at
  +2.5 m, centred slightly away from the breach at `w = -4`.
- **Bay and beach:** inside the breach, a small sheltered bay shoals onto a
  landing beach between the horns, rising to the crater floor.
- **Terrain:** authored, replacing the generic dome. The rim, ledges, floor and
  beach need finer sampling or authored ground pieces with their own collision.

## 3. The inhabitants

**Anthropomorphic mongooses** (decided 2026-10-06), and **tall**: taller than
the humans, standing about 2.1 to 2.5 m (proposed) against a tall human man's
roughly 2 m. Upright, long-bodied and lean, with the mongoose's narrow pointed
face, small round ears, grizzled fur and long tapering tail, and the quick,
twitchy alertness of the real animal. They run the tournament and fill the
stands. (A hermit-crab proposal was rejected earlier.)

A note on the choice: in the real Hawaiian islands, the mongoose is the
best-known invasive animal, brought in the 1800s to kill rats in the cane
fields and instead devastating native birds. A people of outsiders who thrive
on everyone else's quarrels fits that history closely.

Still to design: their culture, census, names, dress and homes, and whether
they speak the common language or something of their own.

**Scale consequences for the environment:**
- Seats on the stands are sized for them: ledge seats about 0.6 m high, with
  1 m of knee room.
- Any doorway or shelter of theirs is at least 2.8 m high.
- The cage gate (3 m) and the 3.2 m route headroom already clear them.

## 3a. The chant

The inhabitants chant at every fight, from the stands and as the hero enters
the cage. The text is fixed by the user and is used exactly as written:

> Fight, fight.
> Fight or you'll die.
> And if you win,
> We'll eat you alive.

(Updated by the user on 2026-10-06; it replaces the earlier "Fight. Fight. /
You must fight. / If you win, we kill you. / If you lose, you die.")

It is a crowd chant, not an explanation of the rules: winning does not
actually lead to the crowd eating the hero. Its menace is the joke.

## 4. The tournament

A short tournament of a few opponents. The hero fights contenders sent by the
kingdom's feuding communities, then the island's own champion. The creatures
thrive on the Demon King's discord, which sends each community to settle its
scores in the cage; beating the contenders is part of how the hero breaks the
cycle of grievance, though the reconciliation itself happens elsewhere.

| Order | Contender | From |
|---|---|---|
| 1 | **Makoa Kealoha**, the net fisher | Kai Mālie |
| 2 | **Tudaro**, the edge warden | the sea folk |
| 3 | **Old Kelp**, the *Harbinger*'s aged sailing master, the oldest pirate at sea | the pirates |
| 4 | the island's champion, a mongoose | the cage island (pending) |

The sea folk contender fights in a half-flooded or flooded cage. How fights
work (the hero alone, with the party or through bonded blorbs) and the prizes
are open.

## 5. Settlement structure (pre-layout)

The crater is the arena; little has to be built.

- **The cage:** an octagonal cage about 18 m across on the crater floor, its
  gate facing the breach and the landing beach.
- **The stands:** the rim's inner ledges, around about 260° of the crater,
  improved with salvaged timber where a ledge needs a seat or an edge. Three
  ramped aisles (2 m wide, no steeper than 1:4 on the natural slope) climb from
  the floor to the crest.
- **Announcer's perch:** on the rim crest opposite the gate, the highest point
  of the island and visible from the sea.
- **Board of rankings:** on a flat tuff face beside the gate (pictures and
  marks, never words).
- **Landing:** the beach inside the breach; arrivals walk straight up the
  floor to the cage gate, under the eyes of the whole rim.
- **Homes:** wait on the mongooses' design; the rim's outer ledges and the horns are
  the natural places for them.
- **Routes:** every public route, aisle and the cage gate meet the hero's and
  party's minimums (3 m on the floor and beach, 2 m on aisles, 3.2 m headroom).

## 6. Environment dimensions

Environment only; no inhabitants, NPCs or fight scripting (see status). Local
frame as in section 2: origin at the crater centre, `w` toward the arrival dock,
`p` to its right, heights above sea level.

| Element | Dimensions |
|---|---|
| Crater at the waterline | about 70 m across (radius 35 m) |
| Rim crest | 16 m high at the far side (`w = -30`), falling smoothly to about 4 m at the two horns |
| Breach | about 100° of arc centred on `+w`, between the horns at roughly `(w, p) = (20, ±25)` |
| Bay | inside the breach, 0 to 2 m deep over pale sand, shoaling onto the beach |
| Landing beach | `w = +12..+20`, rising from the waterline to the crater floor at +2.5 m |
| Crater floor | level packed sand and tuff, 26 m across, at +2.5 m, centred at `w = -4` |
| Stands | three natural ledges on the rim's inner face, at +5, +7.5 and +10 m, each about 2.5 m deep, running about 260° around the crater; timber edges and seats where a ledge needs them |
| Aisles | three ramped aisles 2 m wide, at bearings 90°, 180° and 270° from `+w`, no steeper than 1:4, from the floor to the top ledge and on to the crest |
| Announcer's perch | a flat tuff platform 4 × 3 m on the crest at `w = -30`, +16 m, facing the gate |
| Cage | a regular octagon 18 m across the flats, on the crater floor; walls of salvaged spars and lashed net 4.5 m high; a net roof at 6 m so no fighter leaves by air; one gate 3 m wide facing `+w` and the beach; a sand floor ringed in timber |
| Board of rankings | a flat tuff face beside the gate, outside the cage |

### Collision and traversal

- The rim, ledges, aisles, perch, floor and beach are solid ground; the outer
  slopes are steep enough to discourage climbing but not walled.
- The cage's spars, net walls and net roof are solid; the gate opens and closes.
- Routes: 3 m on the beach and floor, 2 m on the aisles, 3.2 m headroom
  everywhere except inside the cage (6 m to the net).
- The terrain needs finer sampling or authored ground pieces for the rim, ledges
  and aisles; the generic dome is replaced.

### Planting

As in `ocean_landscape.md`: *pili* and *ʻaʻaliʻi* on the outer slopes, lichen
and whisk fern on the ledges, one young *ʻōhiʻa* high on the rim, beach plants
at the horns, nothing where people sit.

## Fixed, proposed and open

**Fixed (from direction):** a smaller island with a battle cage; tall
anthropomorphic mongooses, taller than humans, who make the hero fight; the
chant; a few opponents, with contenders from the
kingdom's communities, including an old pirate.

**Proposed:** the island at `(112, 88)` as a crescent crater with the rim as
natural stands; the four-fight order with Makoa, Tudaro
and Old Kelp; the cage and stands.

**Open:** the mongooses' culture, census, names, dress and homes; how fights work; the prizes; whether the Fortune's
Rag sends a contender too.
