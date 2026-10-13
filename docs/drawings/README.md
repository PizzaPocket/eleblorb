# Drawings

Source pages for the published plan drawings and 3D models (claude.ai artifacts).
Each is a single self-contained HTML page; open it in a browser to view it.
Edit here and republish; the tools in `tools/*_layout.py` and
`tools/sea_folk_third_pass.py` generate the data some of them embed.

| Page | What it shows |
|---|---|
| `moy_plan.html` | Moy, the city: plan, estates, tower houses, market lanes |
| `frontier_town.html` | Tennison, the frontier town |
| `saloon_plans.html` | Dolma's saloon and hotel |
| `chinese_village_plan.html` | the Chinese village |
| `ohio_aqueduct.html` | Ohio's water system |
| `ocean_plan.html` | the Ocean Kingdom chart, Kai Mālie, the sea folk city, the pirate ships |
| `sea_city_3d.html` | the sea folk city in 3D: third pass with its walls, roof and fountain. Rebuild with `python3 tools/sea_folk_third_pass.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/sea_city_3d.html data.json` |
| `sea_plans.html` | the sea folk city third-pass floor plans, with the walls and roof; rebuilt the same way as `sea_city_3d.html` |
| `sky_kingdom_3d.html` | the Sky Kingdom's six courts in 3D, planned and built today. Rebuild with `python3 tools/sky_kingdom_layout.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/sky_kingdom_3d.html data.json` |
| `chinese_gorge_3d.html` | the Chinese village on its floating islands, the pieces of one broken plateau inside a ragged rim: every home, court, field and garden built by rank in the Shihu Yuan manner, proposed and built today. Rebuild with `python3 tools/chinese_village_plan.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/chinese_gorge_3d.html data.json` |
| `plant_village_3d.html` | the Plant Kingdom and its village in 3D, planned and built today. Rebuild with `python3 tools/plant_village_layout.py --json data.json` then `python3 tools/embed_drawing_data.py docs/drawings/plant_village_3d.html data.json` |

Every drawing is updated whenever the plan it shows changes.
