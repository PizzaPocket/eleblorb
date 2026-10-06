# Snow Village (Ice Kingdom): architecture, plan, landscape and interiors

Status: APPROVED IMPLEMENTATION CHARTER. Bible entry: `docs/world_bible.md`, Ice Kingdom, "The snow village" and its residents.

## 1. Inhabitants and households (from the bible)

| Person | Role and home | Notes |
|---|---|---|
| **Astrid Snowrest** | Keeps the large village inn beside the lift approach | Covered porch, mudroom and equipment-drying room, vaulted common room with a gable hearth |
| **Elin** | Elected steward and head of mountain rescue; rescue and meeting hall by the lift base | Bell and broad equipment porch |
| **Niko** | Carpenter, roofer and chair-lift mechanic; workshop beside the lift machinery | Compact living room at the sheltered rear |
| **Anja** | Forester and trail keeper; home and wood yard at the outer edge | Windbreak fence, communal firewood |
| **Mara** and sister **Solveig Woolcap** | Tailor and leatherworker; spinner and knitter; shared workshop and home | Winter-goods frontage onto the common yard |
| **Tomas** and **Soren** | Lake-road warden; ice cutter and cold-store keeper; shared home with an attached icehouse | Lakeside edge |
| **Ivar** and niece **Freya** | Senior fisher and his apprentice; household on the village side of the lake trail | Fishing hut on the ice is a day shelter only |
| The communal bathhouse | Hot room, washing room, gable-end stove | Near the inn and wood supply |

## 1a. Relationships and life (bible, plus proposals)

Already in the bible: sisters Mara and Solveig; Tomas and Soren sharing a home; Ivar and Freya as uncle and apprentice; Elin coordinating rescue with Tomas's ice reports; Niko roofing the village and keeping the lift running; Anja supplying firewood to the communal stacks. Proposals (not canon until approved): a village table in the inn on rescue-return nights; Niko and Elin's shared watch of the lift in storms; Freya's smoked fish traded for Mara's mittens; the bathhouse as an evening meeting point. Apply the same rule as Ohio: no anonymous residents, children appear as named apprentices or visitors.

## 2. Architectural influences (draft charter)

**Approved grammar.** Primary: Norwegian and Alpine log vernacular (tømmerhus, stabbur, laft), a stone foundation, vestibules, farm buildings gathered around a common yard, a raised storehouse on stone piers. Secondary: French Canadian bellcast eave and gallery, on the inn and rescue hall only. Accent: a tiered bell roof on the rescue hall. Kit of parts: steep gable 45 to 50 degrees, wood shingle over bark or turf, deep eaves with cut-board edging, snow guards, bellcast flare on gallery roofs, catslide over wood stores; laft log with projecting notched corners left dark or tarred; external gable-end stack built into the wall; small deep-set windows with white frames, a few larger on the south side, shutters on dwellings only; plank doors in vestibules, carved door cases; signature motif: carved dragon-head finials on gable peaks and a painted flower band on door cases; palette weathered brown and tar-black logs (60), snow-white and slate roofs (30), oxide-red, ochre or blue-green accents (10). Polite: inn and rescue hall. Vernacular: homes, workshops, sheds, stabbur. Exclusions: half-timber, Georgian symmetry, Alpine heart-cutout balconies, flat roofs.
**Option B.** French Canadian primary (stone and timber maison, bellcast eave and gallery, metal roofs, lucarne dormers), Nordic carving as the secondary on civic buildings; exclude notched-log corners on the primary buildings.

## 2a. Direction from the user (2026-10-04): Scandinavian hearths and a Norse hamlet plan

**Hearths.** Scandinavian, replacing the Ohio breast-and-stack. The inn and rescue hall have a **peis**: a broad open hearth in a gable wall under a sloped, whitewashed or stone masonry hood, with a hearth bench and a built-in firewood niche, the hood narrowing to one flue. Homes and bedrooms use a tiled **kakelugn**-style stove (a tall rounded or square-shouldered tiled mass in a corner against an outer wall, glazed white or pale blue tile with a dark cap) whose flue passes through the wall. The bathhouse has a **kiuas**: a stone-pile sauna stove in the hot room behind a low stone kerb. Every stove is one mass built into or against an outer wall and one stack clears the ridge. The two-opening rule still holds for a building with a kitchen range and a hall fire.

**Plan.** The settlement is a Norse farm-hamlet (**tun**) grown into a small modern mountain town. The inn is the long hall (skáli): the largest building, ridge along the contour, door onto the yard. Houses and workshops stand in an irregular ring round the open yard (the tun), each turning a gable to the wind and its door to the yard or a lane. A raised **stabbur** storehouse on stone piers stands at the yard's edge. A boat and net house (**naust**) stands toward the lake at the end of the lake road, which is the settlement's main axis. The smithy-like noisy trades (Niko's workshop) sit at the edge by the lift. The bathhouse stays near water, wood and the inn. The yard's social landmark is a permanent raised iron **bålpanne** on three stout legs, standing in a snow-cleared flagstone court with three high-backed timber settles. Broad gaps between the settles keep every approach open. The former symbol slab and thing mound are removed rather than competing with the hearth as unexplained ornaments; the stone-curbed cistern remains a separate working feature.

**Modern layer.** The chair lift, lamp standards, insulated roofs, glazed stoves and string lights give a medieval root in a living present, not a museum.

## 3. Town plan (authored in `scripts/snow_plan.gd`)

The settlement lives on the Ice Kingdom's flat village pad (radius 62 m, ground at 0). Three terrain facts drive it: the pad is the only flat ground, the mountain and its pistes lie west and north-west, and the lake lies east and south-east with the kingdom's arrival point at the end of the lake road.

**Terrain change.** The bunny run used to end on a raised shelf 70 m from the yard and the chair lift started 140 m north-west of it, so no building could stand "beside the lift base" without skiers sliding into it. The run's last point and the lift's lower station now sit on the pad's north-west corner (`LIFT_LOWER` (-30,-56), `BUNNY_RUNOUT` (-30,-40)). The run ends in a base plaza between Niko's workshop and Elin's hall, clear of every wall.

**Hierarchy of ways.** The lake road (3.4 m) is the main axis from the yard to the arrival point. The lift lane (3.6 m) joins the plaza to the yard between the rescue hall and the inn. Lanes of 2.4 to 3.0 m serve each door, the service yard east of the inn, the wood store and the bathhouse. Aprons of 2.2 to 3.0 m reach each remaining door. Paths are worn light earth under trodden snow, never paved, and every one ends at a door, gate, yard or plaza.

**The tun.** The common snow yard (an irregular oval about 38 by 24 m) remains open through its middle for movement and gathering. Its southern social court holds the raised communal fire pan and backed settles, close enough to warm the yard without occupying the lake-road sightline or any principal route. The working cistern sits apart from the fire. The inn, the long hall, forms the north side with its ridge along the contour and its door onto the yard. The textile house closes the east side and faces west across the yard. The stabbur and the forester's lane lie on the south-west, the fisher's lane and lake road on the south-east. The west side is left open to the plaza lane and the windbreak pines. Every house turns a gable to the mountain wind where its door allows, and every door faces the yard or a lane.

| Building | At (local) | Faces | Resident |
|---|---|---|---|
| Snowrest Inn (long hall) and its sleeping wing | (12,-28) and (14,-36) | south, onto the yard | Astrid Snowrest |
| Mountain Rescue Hall | (-14,-30) | east, onto the lift lane | Elin |
| Lift workshop | (-14,-54) | south, onto the plaza | Niko |
| Textile house and winter-goods hatch | (40,-2) | west, onto the yard | Mara and Solveig Woolcap |
| Communal bathhouse | (48,-26) | west, onto the inn east lane | everyone |
| Warden house and attached ice house | (46,30) and (46,20.4) | west, onto the lake road | Tomas and Soren |
| Fisher home, smokehouse, net shed (naust) | (24,40), (24,50), (36,52) | east, onto the lake road | Ivar and Freya |
| Forester home and wood yard | (-28,28) | east, onto the forester lane | Anja |
| Village stabbur (raised store) | (-12,10) | east, onto the yard | held by Astrid and Elin |
| Communal wood store | (30,-39) | south, onto the service yard | Anja supplies it |

Separation: 4 m between neighbours where people pass, never under 3 m, measured to the eave. The communal hearth, cistern and weather mast are solids for the validator, and the sightline from the lake road mouth to the yard stays open.

## 4. Building programs (who uses it, and the rooms it needs)

- **Snowrest Inn.** Arrival: a gallery under a bellcast eave onto a mudroom and an equipment-drying room (benches, boot racks, pegs, a warm stove), then a wide archway into the vaulted common room. The common room is double height under the roof and gathered round a peis on the west gable, with settles either side, grouped tables with 1.2 m between, a service counter on the north wall at least 2.5 m from the door with Astrid's space behind it, and a serving hatch to the kitchen and pantry. The kitchen has its own door to the east service yard. A rear passage from the common room leads into the sleeping wing (one storey, flat insulated ceiling with a storage loft above): a corridor, three guest rooms, the party dormitory, Astrid's own room, and the dry-toilet room at the corridor's end. The dry toilet is an insulated seat over a sealed masonry vault, vented by its own stack. Every room has a window and a framed door.
- **Mountain Rescue Hall.** A deep gallery (the broad equipment porch) with sled racks, a bell in a stave-style tiered bell roof, a large meeting room with benches and a table under a weather board, a peis, a rescue store (sleds, rope, stretchers, lamps) and, above, Elin's small steward's room and a radio and map room. A ramp rises through a superellipse hole.
- **Lift workshop.** A wide plank door (2.8 m) into the working bay: bench, timber rack, chair frames, cable drum; a timber lean-to along the terminal side; behind a partition Niko's compact living room with a kakelugn, bed, table and chest.
- **Textile house.** Ground floor: Solveig's sales hatch and fitting space at the front, Mara's cutting table and leather bench, a spinning corner and wool store, a stove; upper floor: two private bedrooms and a landing. A ramp, rails and a vestibule.
- **Bathhouse (badstu).** Changing vestibule, washing room with a drain, hot room with a kiuas (stone-pile stove) behind a low stone kerb and two tiers of benches, a water barrel, a wood-box accessible from outside.
- **Warden house and ice house.** Tomas and Soren share a living room, kitchen, and two sleeping alcoves. The ice house is a separate turf-roofed, earth-banked store beside it with its own door and no fire.
- **Fisher home.** Ivar and Freya: living room with a kakelugn, kitchen corner, two sleeping alcoves, a drying rack for nets by the stove. The smokehouse (low, stone base, no windows) and the net shed (naust: open front onto the lake road, nets, floats, a small sled-boat) belong to the same yard.
- **Forester home.** One room and a loft, kakelugn, tools on pegs, a wood yard with chopping block and stacks behind a windbreak fence.
- **Stabbur.** A raised log store on stone piers with an outside stair or ladder, holding the village's winter provisions; carved door.
- **Communal wood store.** Open-fronted long shed with split-log stacks facing the service yard.

## 5. Charter application and variation matrix (Option A stands; amendments in section 2a)

Invariants: roof pitch 45 to 50 degrees, snow-bearing eaves with snow guards, stone foundation, laft corners with projecting notched ends, white-framed small windows, plank doors, finial motif, palette 60/30/10.

| Building | Plan and mass | Roof | Entry | Hearth | Distinguishing feature |
|---|---|---|---|---|---|
| Inn | Long hall, one storey under a vaulted roof; rear wing | Gable with bellcast gallery roof | Gallery onto mudroom | Peis, west gable | Dormers on the wing; dragon-head finials |
| Rescue hall | Square-ish, two storeys | Gable with tiered bell roof | Broad gallery | Peis | Bell in a stave-style tower |
| Workshop | Long low range with timber lean-to | Gable, catslide over the lean-to | Wide plank door | Kakelugn | Cable drum and chair frames outside |
| Textile house | Two storeys, ridge across the yard | Gable | Small vestibule plus hatch | Kakelugn | Dormer; hatch counter |
| Bathhouse | Squat single cell | Gable | Changing vestibule | Kiuas | Steam vent, wood-box |
| Warden house | Single range | Gable | Vestibule | Kakelugn | Attached turf ice house |
| Fisher home | Small range | Gable | Vestibule | Kakelugn | Net drying rack, smokehouse, naust |
| Forester home | Small cabin with loft | Gable | Vestibule | Kakelugn | Windbreak fence, wood yard |
| Stabbur | Raised cube on piers | Steep gable | Outside ladder | none | Overhanging upper course |

## 6. Landscaping

Windbreak pine belts to the west and north (never on a way), snow banks shaped against the windward walls of houses and fences (soft SuperEgg mounds, low), stacked firewood as a facade pattern on south and east walls and under lean-tos, hardy kitchen plots under glass cold-frames behind the textile house, the warden house and the forester's yard, a lamp standard at each lane junction and at the plaza, pine edges at the pad rim. The social court uses a fixed iron fire pan, local flagstone, and backed timber settles as one designed ensemble rather than a campfire surrounded by loose logs. The cistern retains its capped stone curb.

## 7. Interiors

Same rules as Ohio (see the interior-design skill): circulation first, partitions to the rafters, framed doorways, every room reachable, beds with head to the wall and 0.6 m access, a lamp or window for each activity. Furniture comes from `Furnishings`; Nordic pieces (bench-bed, settle, loom, sled rack, boot rack) are added there. Every occupied room has light and a stove.

## 8. Data and validation

`scripts/snow_plan.gd` (`SnowPlan`) is the single source. `IceKingdomVillage` builds from it and reports `layout_report()`; `tools/validate_village.gd --village=snow` checks overlaps, door clearance and reach on the walk grid, facing, paths and the yard sightline. Interior and exterior renders use `tools/village_aerial_capture.gd --village=snow`.
