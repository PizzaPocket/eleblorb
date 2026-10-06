# Ocean Kingdom: Overview of Its Peoples

Status: first planning pass, in review (2026-10-06). The Ocean Kingdom holds
three populations with separate briefs:

| Population | Brief | Where |
|---|---|---|
| The sea folk (merfolk) | `ocean_sea_folk_city.md` | the deep-sea city at world `(0, -540)`, 72 m down |
| The pirates of two ships | `ocean_pirate_ships.md` | at sea, on the route around the kingdom's centre |
| Kai Mālie, the island village | `ocean_island_village.md` | the eastern shore of the main island, facing the arrival dock |

## Survey (from the current code)

- **Terrain** (`ocean_kingdom_terrain.gd`): a 1,860 m square ocean with the
  water surface at 0 m, falling to 111 m at the edges. Seven islands; the main
  island at `(-118, 72)` has a radius of about 116 m and rises to 10.5 m.
- **Arrival:** a stilted dock and the return gate at `(0, 0)`, about 23 m off
  the main island's eastern shore (`ocean_kingdom_dock.gd`).
- **Sea folk city:** centre `(0, -540)` on a levelled shelf at -72 m
  (`ocean_kingdom_city.gd`).
- **At sea** (`ocean_kingdom_denizens.gd`): the Kraken circles an elliptical
  route (430 × 350 m); one pirate ship circles a smaller route (350 × 285 m);
  Fish Goblins roam.

## How the three relate

- **Island and sea folk:** an old, friendly exchange at the shore.
- **Island and pirates:** trade on the beach, and no further.
- **Sea folk and pirates:** avoidance and mistrust.
- **The two ships:** contempt for each other.
- **Everyone and the Kraken:** fear and avoidance.

## Shared decisions for the kingdom

- **Rest point:** proposed at Kai Mālie's guest house, so the sea folk city
  does not need one unless a second is wanted below.
- **Air:** the sea folk's air halls give the hero a place to breathe and walk
  underwater without a helmet.
- **Boats:** once boat riding exists, the island's canoes and the ships are
  natural candidates.

## Order of work

1. Approve the three briefs.
2. Lay out the island village first: it is nearest the arrival dock and
   frames every visitor's first view.
3. Lay out the sea folk city's rings and air halls.
4. Build the second ship and the ship interiors.
5. The shared systems each needs: the generalised lexicon for Hawaiian, air
   halls in the liquid system, and a legged sea-folk rig.
