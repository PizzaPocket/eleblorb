# Ocean Kingdom: Overview of Its Peoples

Status: first planning pass, in review (2026-10-06). The Ocean Kingdom holds
four populations with separate briefs:

| Population | Brief | Where |
|---|---|---|
| The sea folk (merfolk) | `ocean_sea_folk_city.md` | the deep-sea city at world `(0, -540)`, 72 m down |
| The pirates of two ships | `ocean_pirate_ships.md` | at sea, on the route around the kingdom's centre |
| Kai Mālie, the island village | `ocean_island_village.md` | the eastern shore of the main island, facing the arrival dock |
| The cage island's creatures (pending) | `ocean_cage_island.md` | the small island at `(112, 88)`, east-northeast of the dock |

## Survey (from the current code)

- **Terrain** (`ocean_kingdom_terrain.gd`): a 1,860 m square ocean with the
  water surface at 0 m, falling to 111 m at the edges. Seven islands; the main
  island at `(-118, 72)` rises to 10.5 m; its listed radius is 116 m, but its
  dry land reaches only about 55 m from the centre.
- **Arrival:** a stilted dock and the return gate at `(0, 0)`, about 83 m off
  the main island's nearest shore over deep water (`ocean_kingdom_dock.gd`).
  Kai Mālie's layout adds a reef flat and a pier to reach it.
- **Sea folk city:** centre `(0, -540)` on a levelled shelf at -72 m
  (`ocean_kingdom_city.gd`).
- **At sea** (`ocean_kingdom_denizens.gd`): the Kraken circles an elliptical
  route (430 × 350 m); one pirate ship circles a smaller route (350 × 285 m);
  Fish Goblins roam.

## How they relate: discord now, harmony later

When the hero arrives, every community is at odds with the others. The Demon
King has sown the discord; how is still open. Restoring harmony is the
kingdom's story, as it is in the Sky Kingdom.

| Between | Before the discord | Now |
|---|---|---|
| Island and sea folk | an old, friendly exchange at the shore | broken off; each blames the other for damage to its waters |
| Island and pirates | trade for water and food on the beach | the pirates are barred |
| Sea folk and pirates | avoidance | hatred; the sea folk say the ships foul the reef |
| The two ships | contempt | open war |
| The cage island and everyone | — | its creatures profit from the discord: each community sends a contender to the cage |
| Everyone and the Kraken | fear | fear |

## Shared decisions for the kingdom

- **Rest points:** two. Sam Okafor's guest house at Kai Mālie on the surface,
  and Pelaju's guest hall, an air hall in the sea folk city, below.
- **Air:** the sea folk's air halls and the glass tunnels between them give the
  hero a place to breathe and walk underwater without a helmet.
- **Boats:** once boat riding exists, the island's canoes and the ships are
  natural candidates.

## Order of work

1. Approve the three briefs.
2. Lay out the island village first: it is nearest the arrival dock and
   frames every visitor's first view. Done: `ocean_island_village_layout.md`
   (in review), including the terrain it needs and the cage island's
   enlargement.
3. Lay out the sea folk city's rings and air halls.
4. Build the second ship and the ship interiors.
5. Lay out the cage island and design the tournament.
6. The shared systems each needs: the generalised lexicon for Hawaiian, air
   halls in the liquid system, and a legged sea-folk rig.
