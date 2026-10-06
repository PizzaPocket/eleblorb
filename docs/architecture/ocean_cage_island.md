# Ocean Kingdom: The Cage Island

Status: concept brief, first planning pass (2026-10-06). **Build the
environment only:** the crater, cage, stands and landing. Do not build the
inhabitants or any tournament NPCs, and do not write fight mechanics or
scripting, until the user confirms their direction. Read with
`ocean_kingdom.md`. The island's inhabitants are not yet designed: the user
will supply their direction.

## 1. Premise

A smaller island holds a fighting cage and a population of small creatures
who make the hero fight their cage match tournament.

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

Pending. They are small creatures who run the tournament. Their species,
culture, census and names wait on the user's direction. (A hermit-crab
proposal was rejected.)

## 3a. The chant

The inhabitants chant at every fight, from the stands and as the hero enters
the cage. The text is fixed by the user and is used exactly as written:

> Fight. Fight.
> You must fight.
> If you win, we kill you.
> If you lose, you die.

It is a crowd chant, not an explanation of the rules: winning does not
actually lead to the crowd killing the hero. Its menace is the joke.

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
| 4 | the island's champion | the cage island (pending) |

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
- **Homes:** wait on the inhabitants; the rim's outer ledges and the horns are
  the natural places for them.
- **Routes:** every public route, aisle and the cage gate meet the hero's and
  party's minimums (3 m on the floor and beach, 2 m on aisles, 3.2 m headroom).

## Fixed, proposed and open

**Fixed (from direction):** a smaller island with a battle cage; small creature
inhabitants who make the hero fight; a few opponents, with contenders from the
kingdom's communities, including an old pirate.

**Proposed:** the island at `(112, 88)` as a crescent crater with the rim as
natural stands; the four-fight order with Makoa, Tudaro
and Old Kelp; the cage and stands.

**Open:** the inhabitants; how fights work; the prizes; whether the Fortune's
Rag sends a contender too.
