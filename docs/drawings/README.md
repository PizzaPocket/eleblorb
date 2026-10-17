# Drawings

Source pages for the published plan drawings and 3D models (claude.ai artifacts).
Each is a single self-contained HTML page; open it in a browser to view it.
Edit here and republish; the tools in `tools/*_layout.py` and
`tools/sea_folk_third_pass.py` generate the data some of them embed.

| Page | Published | What it shows |
|---|---|---|
| `moy_plan.html` | [link](https://claude.ai/artifact/9qeXfC1J9oGNUT8pFmLWi1) | Moy, the city: plan, estates, tower houses, market lanes, the Grand Hotel's plan and section. Rebuild with `python3 tools/city_layout.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/moy_plan.html data.json` |
| `moy_city_3d.html` | [link](https://claude.ai/artifact/YJq2qoeR9thJ67M5Xr23yd) | Moy in rough massing for assessment: every building and lot at its planned height, the landmark towers in their forms, the North Estate, the park and playground, the Deck with its skybridges, ramp towers and lifts, the wall with the Wall Line's trains running round it, the two straight lines on their portal frames and tree piers, the Timekeeper in its cradle with its turning rings, the Meridian Arch as the East Gate, the West Gate's towers and the open Crossing Ring with their station cores (2026-10-17), the Rim Walk and the wind farm. Drawn from the same data as `moy_plan.html` |
| `moy_grand_hotel_3d.html` | [link](https://claude.ai/artifact/HQ3yrpKk7SSaapbkDzmTWy) | Moy's Grand Hotel in 3D, after John Portman (proposed 2026-10-13): the atrium block and its leaning front, the ribbed cylinder tower and revolving drum, the glass capsule lifts in slots let into the tower, the one-pitch skylight, the chandelier's arm and the rain system, a cut-away into the atrium with its galleries, chandelier, rock garden, double ramp and the skybridge from the Deck, among its neighbours on Civic Plaza. Rebuilt from the same data as `moy_plan.html`: `python3 tools/city_layout.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/moy_grand_hotel_3d.html data.json` |
| `frontier_town.html` | [link](https://claude.ai/artifact/1uaqBWcuQsg7Qmu5vMaHWR) | Tennison, the frontier town |
| `saloon_plans.html` | [link](https://claude.ai/artifact/We2QCKiufaJUkrA9tCkf2x) | Dolma's saloon and hotel |
| `chinese_village_plan.html` | [link](https://claude.ai/artifact/TMfmsY6cUQie9bAdYb5b1X) | **superseded** (13 Oct): the Chinese village's 12 Oct island re-fit, kept for the record; the current plan is `chinese_gorge_3d.html` |
| `ohio_aqueduct.html` | [link](https://claude.ai/artifact/ADMGXKFuEhPmwfYNnwDArJ) | Ohio's water system |
| `ocean_plan.html` | [link](https://claude.ai/artifact/HxHfJhVN4zvSVGKfNLuTaJ) | the Ocean Kingdom chart, Kai Mālie, the pirate ships, and the sea folk city's second-pass seabed plan (superseded where it differs by `sea_plans.html` and `sea_city_3d.html`) |
| `sea_city_3d.html` | [link](https://claude.ai/artifact/Qxq7fwow8DvVukaPJ4mgdT) | the sea folk city in 3D: third pass with its walls, roof and fountain, the trunks, and the air (moon pools at the datum, lock chambers above it). Rebuild with `python3 tools/sea_folk_third_pass.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/sea_city_3d.html data.json` |
| `sea_plans.html` | [link](https://claude.ai/artifact/A3YDXxSxZVArYZrEL2tbRb) | the sea folk city third-pass floor plans, with the walls and roof; rebuilt the same way as `sea_city_3d.html` |
| `sky_kingdom_3d.html` | [link](https://claude.ai/artifact/KTgN7JLsZP8y8bsjAkfegQ) | the Sky Kingdom's six courts in 3D, planned and built today. Rebuild with `python3 tools/sky_kingdom_layout.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/sky_kingdom_3d.html data.json` |
| `chinese_gorge_3d.html` | [link](https://claude.ai/artifact/9Q72JNh5t8CLj9Em1x74we) | the Chinese village on its floating islands, the pieces of one broken plateau inside a ragged rim: every home, court, field and garden built by rank in the Shihu Yuan manner, proposed and built today. Rebuild with `python3 tools/chinese_village_plan.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/chinese_gorge_3d.html data.json` |
| `plant_village_3d.html` | [link](https://claude.ai/artifact/3FWoBcF6J3gH5WcP2mkxXx) | the Plant Kingdom and its village in 3D, planned and built today. Rebuild with `python3 tools/plant_village_layout.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/plant_village_3d.html data.json` |

Every drawing is updated whenever the plan it shows changes, and republished to the same link. The published copies are private to the owner until shared from the page's Share menu.
