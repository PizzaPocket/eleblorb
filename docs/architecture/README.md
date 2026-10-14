# Settlement architecture files

One file per settlement or kingdom (`ohio.md`, `snow_village.md`, ...). Each is the single place that says how that settlement is built, planned, planted and furnished, and it is **derived from the world bible**: people, trades and relationships come from `docs/world_bible.md`, never invented here. If a design decision needs a new fact about a person or place, add it to the bible first, then reflect it here.

Skills (`.claude/skills/architecture`, `interior-design`, `landscaping`) hold general knowledge. These files hold what is true of one settlement. Always read the settlement's file and its bible entry before designing anything in it.

Use `_template.md` for a new settlement. Status of each file is stated at its top (DRAFT until approved).

## Index (2026-10-14)

What to build next, and what is waiting on whom, is in one place:
`settlement_backlog.md` (its implementation index). Each file's own status
line says whether it is approved or in review. Plan tools write the data the
drawings embed and run the checks; the drawings are in `docs/drawings/`
(see its README for the published links).

| Settlement | Briefs | Plan tool and checks | Drawings |
|---|---|---|---|
| Ohio (starting village) | `ohio.md` | `scripts/ohio_plan.gd` | `ohio_aqueduct.html` |
| Snowhio (Ice Kingdom) | `snow_village.md` | `scripts/snow_plan.gd` | |
| Crossroads fishing village | `fishing_village.md`, `_layout.md`, `_buildings.md`, `_building_designs.md`, `_interiors.md` | `scripts/fishing_village_plan.gd` | |
| Fire Kingdom caldera city | `fire_caldera_city.md`, `fire_caldera_layout.md`, `fire_caldera_buildings.md` | `scripts/fire_caldera_plan.gd` | |
| Chinese village | `chinese_village.md` (4.0 and 4.0a are the current islands and placements; 4.1 is the 12 Oct re-fit, superseded where it differs), `chinese_village_palace.md` | `tools/chinese_village_gorge.py` (islands, bridges, abutments), `tools/chinese_village_plan.py` (placements, openings, paths), writing `scripts/chinese_plan.gd` | `chinese_gorge_3d.html` (current); `chinese_village_plan.html` (superseded) |
| Sky Kingdom | `sky_kingdom.md`, `sky_kingdom_layout.md`, `sky_kingdom_buildings.md`, `sky_kingdom_interiors.md` | `tools/sky_kingdom_layout.py`, writing `scripts/sky_kingdom_plan.gd` | `sky_kingdom_3d.html` |
| Ocean Kingdom | `ocean_kingdom.md` (overview), `ocean_landscape.md`, `ocean_floor_landscape.md` | | `ocean_plan.html` (the chart) |
| · Kai Mālie | `ocean_island_village.md`, `_layout.md`, `_buildings.md` | `tools/kai_malie_layout.py`, writing `scripts/kai_malie_plan.gd` | `ocean_plan.html` |
| · Sea folk city | `ocean_sea_folk_city.md` (section 2a is the third pass), `_layout.md`, `_buildings.md` | `tools/sea_folk_third_pass.py` (third pass, with the air), writing `scripts/sea_folk_city_plan.gd`; `tools/sea_folk_layout.py` (second pass) | `sea_city_3d.html`, `sea_plans.html` |
| · Pirate ships | `ocean_pirate_ships.md`, `ocean_pirate_ships_design.md` | `tools/pirate_ships_layout.py`, writing `scripts/pirate_ships_plan.gd` | `ocean_plan.html` |
| · Cage island | `ocean_cage_island.md` | | `ocean_plan.html` |
| Plant Kingdom | `plant_kingdom_village.md`, `_layout.md`, `_buildings.md`, `plant_kingdom_landscape.md`, `plant_kingdom_water_curtain_cave.md` | `tools/plant_village_layout.py`, writing `scripts/plant_village_plan.gd` | `plant_village_3d.html` |
| Rock and Ground (Tennison) | `rock_ground_town.md`, `rock_ground_saloon.md` | | `frontier_town.html`, `saloon_plans.html` |
| Moy, the city | `city.md` (8 the Grand Hotel, 8a city hall, 9 the library), `moy_tower_house.md`, `moy_market_lanes.md` | `tools/city_layout.py` (writes `scripts/city_plan.gd`) | `moy_plan.html`, `moy_grand_hotel_3d.html` |

**From model to game.** The 3D drawings are pictures of the plan tools' data, not game assets. Each tool writes its settlement's plan as a generated GDScript class of constants (`tools/gd_plan.py` writes them in one format); the game's builder and validator read that, and each brief says how every piece is constructed. Edit the tool and rerun it, never the generated file. Build one structure in isolation, then compare the engine's render with the model's named views.

Older handoff notes in `docs/handoff_*.md` are dated snapshots; where they
differ from the briefs and the backlog, the briefs and the backlog win.
