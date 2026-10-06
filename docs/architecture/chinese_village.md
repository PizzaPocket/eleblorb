# Chinese Village: audit and rebuild proposal

Status: population, backstory, quest resolution and postquest civic use are
approved. The layout re-fit in section 4, with its courtyard charter and palace
restructure, was approved on 2026-10-06 but is not yet implemented. No building has moved for this pass.

Source of truth today is `scripts/chinese_village.gd` (1572 lines, no plan data
file, no validator). Measurements come from `tools/audit_china.tscn` (headless,
prints islands, NPC positions and non-island children relative to the village
centre at world (250, -650)).

## 1. Inventory

Islands (all at one shared surface y, about -61, over the Abyss):

| Island | Local centre | Radius | Contents now |
| --- | --- | --- | --- |
| Palace | (0, 0) | 62 | Four-level golden castle, Royal Kitchen annex at (0, -31), garden, 14 lanterns, 7 trees, Emperor, Chef |
| A | (-105, -58) | 21 | Kids' play hut with the Jingu Bang among loose sticks, 2 scattered houses, 6 kids, 4 adults |
| B | (108, -48) | 20 | Chen's stall, 2 scattered houses, 4 adults |
| Bamboo | (18, 116) | 25 | 34 stalks as multimesh, farmer Tian Bo and Pandy |
| C | (-118, 42) | 18 | 2 houses, no residents |
| D | (112, 48) | 19 | 2 houses, no residents |
| E | (-62, 124) | 17 | 1 house, the inn (innkeeper now 林静), no other residents |

Bridges (flat, 3.2 m wide, one deck and two rails each, no gate or landing):
Palace-A 44 m, Palace-B 44 m, A-C 65 m, B-D 61 m, C-E 67 m, E-Bamboo 42 m, plus
a 225 m sloped entry bridge running due south from the palace to the mainland.

Residents: Emperor, Royal Chef (hostile agent), farmer Tian Bo, Pandy, vendor
Chen, innkeeper 林静 (renamed from Lin Quiet-Reed), eight adult villagers (Mei Lian, Wen Zhao, Bo
Xiang, Hua Chen, Jin Wei, Lian Fu, Yun Tao, Shu Mei), six children (Ting, Xiu,
Pei, Rong, Bao). Sun Wu Kong is sealed on the castle crown (moving to Lantern
Row, section 4.6).

Quest chain (must survive any rebuild): Tian Bo's grievance, Liang Zhen's
audience, blorbs shrunk to buns on the kitchen counter, Chef fight without
blorbs, cleaver drop, Liang Zhen restored without an Emperor fight, Tian Bo
made village chief, Pandy joins, palace becomes a civic centre, and Liang Zhen
becomes the community chef. Jingu Bang hunt at the play hut, Sun Wu Kong freed
from the sealing rock.

## 2. Measured defects

1. **Entry bridge crosses the bamboo island.** The bridge runs along x = 0. The
   bamboo island is centred at x = 18 with radius 25, so the deck passes over
   its grass between y = 99 and y = 133, through the grove, and the farmer
   stands 18 m from the bridge's line. The approach to the palace, the one
   processional route, is the bamboo island's thoroughfare.
2. **The inn overlaps a house.** The inn is placed at E + (5, -5). A 2x2 house
   stands at E's origin. The inn lodge half width is 8 m on an island of radius
   17, so no placement on E fits both.
3. **Houses have no orientation or siting logic.** `_build_pagoda` rotates each
   house by a random angle and `_pick_building_position` scatters them with an
   RNG. Doors face nothing. C, D and E use hand-typed offsets with the same
   random rotation. No house relates to a bridge landing or a path.
4. **Houses are interchangeable single boxes.** One `TownProps.build_building`
   shell with a gable roof and two stacked ornamental slabs on top. No
   courtyard, no plinth, no hall hierarchy, no distinction between a dwelling,
   a workshop and a shop.
5. **Bridge hierarchy does not exist.** Every bridge is the same width and
   flat. Landings are the island rim with no gate, no paving and no check that
   deck and island share clearance. The entry bridge slopes 225 m down to
   terrain with no gate at either end.
6. **Residents have no population design.** Islands C, D and E hold five houses and no one.
   Adults on A and B wander a disc at random, with no home, no work and no
   schedule. Their dialogue is atmospheric and generic, and does not name a
   trade, a household or the palace.
7. **Chen's stock has no provenance.** He sells Jungle Mushroom, Seed of Life,
   Blorb Slime, Paper Lantern and Steamed Bun. No household on the island
   steams buns or makes lanterns, and the plot has no bean field. Under the
   trade-provenance rule each item needs a maker or a forager in the village.
8. **Bamboo reads as regular poles.** 34 stalks, one radius band (0.05 to 0.09),
   six identical segments each, scattered in a disc with no clumps, no height
   variation by age and no clearings. Leaves sit at fixed offsets.
9. **The palace is a stack of four slabs.** Four shrinking boxes with interior
   ramps. No axis from the gate to the throne, no courtyard sequence, no Chinese
   roof language (hip-and-gable eaves, ridge ornaments, upturned corners). The
   golden colour is also used by the ordinary house trim, so imperial yellow
   is not exclusive.
10. **Kitchen delivery has no route.** The Royal Kitchen is a rear annex joined
    to the throne hall by one doorway. There is no service entrance, no yard
    and no path for deliveries from the bamboo island or the market.
11. **The farmer has no fields.** His grievance is about land, but the bamboo
    island has no beans, terraces or tool shed to make the claim visible.
12. **No plan data and no validator.** Positions are constants and RNG calls in
    the builder, so overlap, facing, landing and traversal checks that Ohio and
    Snow have do not exist for this village.

## 3. Population and backstory (authored first)

The people decide the buildings. Everything below that is not quoted from the
existing lines is a proposal and goes into `docs/world_bible.md` only once
approved.

### 3.1 What the existing text already says (canon to keep)

| Person | Established by their own lines |
| --- | --- |
| Mei Lian | Lanterns burn until midnight and nobody remembers who made that rule. Few visitors come on purpose. |
| Wen Zhao | His grandfather built half the roofs and no two angles match. He has stopped minding the walk to the well. |
| Bo Xiang | Walks the long southern road in good weather to trade (the line said "the town to the south"; geography makes that Ohio, 730 m due south). Has lived in three different village houses. |
| Hua Chen | No gate, no portal, nothing takes you elsewhere. Wind in the eaves unsettled them for years. |
| Jin Wei | Her mother hung the first lanterns on this row. Jin Wei only replaces the paper. |
| Lian Fu | On some nights every window is lit and the village seems awake together. Stopped asking travellers where they come from. |
| Yun Tao | The tile colour was shipped in long ago and nobody nearby can fire it now. Likes the hour before the lanterns are lit. |
| Shu Mei | Lives at the western end of a waste with no end. Has counted the lamp posts many times and never got the same number. |
| Ting | Pigtails, braves the bamboo, nearly. |
| Xiu | Counts every lantern. Her mother forbids going to the bamboo alone. |
| Pei | Races to the well. Catches crickets and lets them go. |
| Rong | Was shown a bean longer than his arm by the peddler. Adults say the roofs ring because of wind. |
| Bao | Wants to build a roof like Wen Zhao's. Collects stones. |
| Chen | Peddler. Beans from behind the bamboo, lanterns, buns, "whatever the road lacks". |
| Tian Bo | The Emperor takes more of his land every year. Pandy has followed him for years. |
| Emperor | Rules the whole valley and the islands. Lets the Chef decide that sternness makes people obey. |

Two things the lines refer to that do not exist in the world: a well, and a
bean field. The south town and the wasteland road exist only as the entry
bridge. These become requirements for the layout.

### 3.2 Settlement history (proposal)

- The islands are the pieces of one plateau that broke away over the Abyss.
  Families came three generations ago (Wen Zhao's grandfather's time), settled
  the pieces and bridged them. The first Emperor's family ruled from the
  largest piece from the start.
- The palace's yellow glaze is the old shipped stock Yun Tao mentions. It was
  reserved for the palace, which is why homes use local grey and green tile and
  why nobody can mend the yellow roofs any more.
- Ohio is the only other settlement in reach, due south across the wasteland.
  Bo Xiang walks there for flour and salt, which the village cannot grow, and
  carries lanterns, beans and bamboo goods back to sell. Ohio's mill (Cob Ferris)
  is where the bun flour begins.
- The Emperor is a hereditary small ruler. The palace's old bargain with the
  village: a modest share of beans, flour and bamboo shoots, in return for
  keeping the bridges and the lamp posts in repair.
- The Royal Chef arrived a few harvests ago with one recipe and rose to the
  Emperor's ear. Since then the Emperor has chased the perfect *rou bao* and
  the share has risen every year. The land taken falls first on the bamboo
  island, where Tian Bo farms.
- Nobody rebels because the palace still keeps the bridges, because the Emperor
  is distracted rather than cruel, and because the village is small and afraid
  of the drop. The Chef's hand in it is not known to anyone.

### 3.3 Households (proposal)

Children are placed in households first, then the adults around them.

| Household | Members (ages are bands) | Work | Tie to the palace | Hidden or unspoken |
| --- | --- | --- | --- | --- |
| Lantern | Mei Lian (elder), her daughter Jin Wei (adult), Xiu (child, Jin Wei's daughter) | Lantern maker and lamp paper | Lanterns for the palace halls, paper changed on set days | Nobody can say who set the midnight rule |
| Tile | Yun Tao (adult), Bao (child) | Tiler, keeps the last yellow glaze | Palace roof repairs | The glaze stock is nearly gone |
| Bao house | Hua Chen (adult, single mother), Ting (child, her daughter) | Bao kitchen and shopfront | Hua Chen has sent bao trials to the palace kitchen, all rejected | She cannot account for Liang Zhen's changing demands |
| Lamp keeper | Lian Fu (adult) | Tends the entry bridge and public lamps; keeps his own small home | Lights and inspects the palace approach | He sees who crosses after dark but does not know the Chef's secret |
| Carrier | Bo Xiang (adult), Rong (child) | Carrier to the south town | Moves the palace's levy flour and beans to the service yard, and the village's goods south | The only resident who regularly leaves |
| West end | Shu Mei (elder), Pei (child, her grandchild) | Waymarker, trims the entry bridge lamps | None directly | Counts posts to stay occupied |
| Roofer | Wen Zhao (adult) | Roofer, finishes his grandfather's work | Palace roof upkeep | Single, the children follow him around |
| Farm | Tian Bo (elder), Pandy | Beans and bamboo shoots | The land levy | Fears for the island's last terraces |
| Inn | 林静 (adult), born on the island, the Lin family's inn kept for three generations; Chen lodges here | Innkeeper | None | Few guests, mostly Chen's trade and Bo Xiang's contacts |
| Stall | Chen (adult) | Peddler and vendor, lives at the inn | Pays nothing, sells only what the village makes | Keeps the village's route open to outsiders |
| Palace | Liang Zhen (Emperor before the quest), the Royal Chef | Rulership and kitchen before the quest; civic centre and community kitchen after it | The centre of the levy and later the village's shared house | The Chef's secret; Liang Zhen's buried love of cooking |

The five children and their households are the heart of the population, so the
play hut, the well and the island with most children are where the village's
daily noise should sit.

Palace staff: none added for now. Villagers rotate through palace work by trade
(Jin Wei with paper, Lian Fu with night lamps, Yun Tao and Wen Zhao with roofs,
Bo Xiang with deliveries). The near-empty court is part of the Chef's hold over
Liang Zhen. After the quest, Tian Bo holds village business there and Liang
Zhen runs the community kitchen; neither role requires adding a palace servant.

### 3.4 Trade provenance for Chen's stall

- Paper Lantern: Mei Lian's workshop. Steamed Bun: Hua Chen's bun house. Seed of
  Life and bamboo shoots: Tian Bo's terraces. Jungle Mushroom: foraged in the
  grove by the children and Tian Bo. Blorb Slime: foraged wild, never made.
- Flour and salt: Ohio's mill, carried by Bo Xiang. Carrier: Bo Xiang for
  anything that crosses the entry bridge, Chen for the stall.

### 3.5 A day (schedule skeleton)

Dawn: steam in the bun house, Tian Bo to the terraces, Bo Xiang to the entry
gate. Morning: workshop and roof work, children to the play hut and well.
Midday: market at the stall, the carrier's loads cross. Afternoon: roof and tile
work, Shu Mei's lamp round on the entry bridge. Dusk: Lian Fu and Jin Wei light
lanterns, children called in. Night: lamps burn until midnight, windows lit, the
inn lamp last. Concrete times and paths go in the plan data.

### 3.6 Civic program the population requires

- Eight dwellings (Lantern, Tile, Bao house, Lamp keeper, Carrier, West end,
  Roofer, Farm)
  with their trade fronts: lantern workshop, bun house shopfront, tile and roof
  yard, carrier's loading frame, farm shed and bean terraces.
- The inn, the market stall, the play hut, a shared well or rain cistern.
- Palace: service yard (levy deliveries and kitchen) separate from the public
  axis.
- Bridges with lamp posts that Shu Mei and Lian Fu actually tend.
- Total eleven or twelve buildings against nine houses now. The layout in section 4
  is to be re-fitted to this, including how many houses D should hold.

### 3.7 Dialogue consequence

The present Chinese lines are generic village mood and carry almost no trade,
family or levy. After approval each adult gets four to six lines tied to work,
household and the palace, each child two to three in a child's voice, all in
Chinese and written under the no-ai-slop rules. Nothing may spell out the
quest. The Chef is never named as the cause by an ordinary resident.

### 3.8 Decisions (approved 2026-10-04)

0. (2026-10-06) The village is classical rather than present-day: unlike
   Ohio and Kai Mālie, no modern layer. Dress, fixtures and comforts follow
   older China.

1. The southern town is Ohio, the starting town. The old line named no one, so
   it now names Ohio. Trade is flour and salt in, lanterns and beans out.
2. The history in 3.2 stands (broken plateau, three generations, yellow glaze
   reserved for the palace, Chef a few harvests ago).
3. The innkeeper is 林静, a native resident of the island whose family has
   kept the inn for three generations. Everyone here speaks Chinese.
4. Palace staff: deferred. Nobody is added for now.
5. Still open: villagers other than the Emperor, farmer and Chef still carry
   Latin display names (Mei Lian, Wen Zhao and so on) while their dialogue is
   Chinese. Converting them to characters belongs in the dialogue pass.
6. Emperor Liang Zhen's name is **梁臻**. The hero never fights him. Defeating
   the Royal Chef breaks the Chef's influence and ends the imperial office.
7. Tian Bo becomes village chief, not Emperor. The palace and gardens become a
   civic centre open to everyone, while Tian Bo continues tending the bamboo.
8. Hua Chen is a single mother and the village's bao maker. Lian Fu is a
   separate lamp keeper with his own home. After the quest, Liang Zhen becomes
   community chef and his relationship with Hua Chen develops over revisits.

### 3.9 Quest and postquest state (approved 2026-10-04)

1. The hero hears Tian Bo's grievance, then seeks an audience with Liang Zhen.
2. Under the Royal Chef's influence, Liang Zhen mistakes the party's blorbs for
   perfect *rou bao*. They are taken to the kitchen, shrink to hand-sized bun
   scale, and the blorb suit is disabled.
3. The hero returns to the kitchen. The Chef reveals himself as an agent of the
   Demon Lord, assumes his demon form and attacks with the Royal Meat Cleaver.
4. The hero defeats the Chef without blorbs. Ordinary traversal, inventory
   items, weapons and non-blorb companions remain available.
5. The Chef drops the Royal Meat Cleaver and retreats to the underworld. Liang
   Zhen is freed from the influence. There is no combat with Liang Zhen.
6. Liang Zhen relinquishes the imperial title. The hero entrusts Tian Bo with
   the village; he becomes village chief and Pandy joins the party.
7. On subsequent visits the palace is a public civic centre. Tian Bo divides
   his time between civic duties and the bamboo grove. Liang Zhen cooks communal
   meals in the former Royal Kitchen. His affection for Hua Chen grows in
   visible stages across revisits rather than resolving in one scene.

## 4. Layout (provisional, derived from section 3)

### 4.1 Island roles and network

Island roles below are a first guess from the buildings. They are to be
re-fitted to the households and civic program in section 3.6 once that is
approved. The first sketch keeps the seven islands and the Abyss, adds one small
gate island and reroutes the bamboo island so the palace approach is a clear
axis.

```
                 Palace (0,0)
                    |  axial bridge, 44 m
 A -- C             |             B -- D
                    |
        E (inn) --- Gate (0,170) --- Bamboo (95,125)
                    |
              entry bridge to mainland
```

- **Gate island** (new, radius 12, centre (0, 170)): a roofed bridge gate, a
  notice post and a lantern pair. The entry bridge lands here. Forks lead to E,
  to the bamboo island and straight north to the palace's south door.
- **E, the guest island:** inn, a small tea stall, the one landing a visitor
  sees first on the left.
- **Bamboo island moved to (95, 125):** off the axis, reached from the gate
  island and from D. It becomes the working island: bean terraces, a tool shed,
  the farmer's cottage and Pandy's pen on the south half, the clumping grove on
  the north half with a path through it.
- **A, Lantern Row:** lantern workshop, two homes, the play hut stays, and
  Sun Wu Kong's sealing rock on the island's north rim (section 4.6).
- **B, Market Island:** Chen's stall, Hua Chen's bao house and shopfront, two
  homes. Lian Fu's home must be assigned separately, close enough to the entry
  bridge for his lamp round to read clearly.
- **C and D, residential:** two courtyard homes each. C holds the roofer's
  yard.
- **Palace island:** axial complex (section 4.3) with a service yard.

Bridge hierarchy: entry and palace axis 5 m wide with gate posts, island to
island 3.2 m, farm and grove path 2.4 m. Every landing gets a paved apron and
paired deck and apron heights that the validator checks.

### 4.2 Courtyard and hall charter (needs approval)

- Ordinary homes: white plastered walls on a low stone plinth, red timber
  columns and eave brackets, grey or green clay tile, hip-and-gable roof with
  a modest upturn at the corners, door on the south face onto a small
  courtyard, a wall or screen closing the yard.
- Shops and workshops: the same vocabulary, open front on a timber shopfront,
  ridge ornaments omitted.
- The inn: two-storey hall with gallery, red lacquer sign, the one ordinary
  building allowed a green-glazed ridge. Sanitation is traditional: a lidded
  wooden commode (*mǎtǒng*) behind a screen in each guest room, and a latrine
  closet off the back courtyard with a door, a bench seat over a removable vat
  and a water jar and basin for washing hands. Night soil is collected each
  morning and carried to the village fields, as Chinese villages did.
- Palace: imperial yellow glazed tile, double-eave hip roof, white marble
  terraces, vermilion walls. Yellow is not used anywhere else.
- Everything built from SuperEgg parts, with `CollisionPolicy` on plinths,
  walls, terraces and screens. Fine bracket detail is decorative.

### 4.3 Palace

- A south gate and processional paved axis from the gate island.
- Public sequence on the axis: gate court, audience hall (ground floor), steps
  to the throne terrace, throne hall. The existing four stepped levels become
  terraces with roofed halls instead of flat slabs.
- Service circulation on the east side: a service yard with its own bridge
  landing from B, the Royal Kitchen at its end, a store and a well. The Chef
  fight room keeps a clear, generous floor.
- Before the quest, private and administrative rooms sit behind the throne
  hall on the west side. Their structure must support conversion after the
  quest into meeting rooms, records storage and public gathering space rather
  than remaining an imperial apartment.
- The Royal Kitchen must support two states without rebuilding its shell: the
  Chef encounter with a clear fight floor and captive-blorb counter, then
  Liang Zhen's welcoming community kitchen with communal preparation and meal
  service.
- Sun Wu Kong's sealing rock leaves the palace (section 4.6). Full brief for
  both the imperial and the civic state: `chinese_village_palace.md`.

### 4.4 Royal garden

Four framed views along the axis: a moon-gate court with a pomegranate tree, a
pond with a zigzag bridge and a pavilion, a rock garden of weathered stones, a
bamboo screen and bench court. Stone paths link them, with one pause each.

### 4.5 Bamboo

Clumping groves: 6 to 10 clumps of 5 to 12 culms each, culm height 7 to 14 m
by age, radius 0.04 to 0.1 m, slight lean away from clump centre, nodes
closer together near the base, branching and leaf sprays only in the upper
third, small young shoots at clump edges. A path, two clearings (the
farmer's and a resting spot) and sparse understory.

### 4.6 Sun Wu Kong's sealing rock (approved 2026-10-06)

The rock is older than the palace, older than the village, and older than the
plateau's breaking. The courts sealed him under it long ago, when the islands
were still one high plateau. When the first families settled three generations
ago, the rock was already there, grown over with moss, and they built round it.
A crown of a palace roof was the wrong place for it.

- **Where:** on the north rim of island A, Lantern Row, facing out over the
  Abyss, clear of the bridge landings, the lantern workshop's yard and the two
  homes' doors.
- **What:** a weathered grey boulder about 5 × 3.5 m and 3 m high, half sunk
  in the turf, with moss and grass on its top. Sun Wu Kong is pinned beneath its
  overhang with his head and shoulders free, as in his legend. The courts' seal
  is a thin gold band bound round the rock, with six small abstract emblems
  for the six courts and no lettering.
- **The play hut** stands in the rock's lee. The children built it there
  because he is the best company on the islands. The Jingu Bang lies among the
  hut's loose sticks, where it fell when he was sealed, and nobody has noticed
  it.
- **The adults** leave the rock alone. Mei Lian, the lantern maker, ties a
  fresh red cord round it each New Year, a habit from her grandmother that
  nobody explains.
- **When he is freed,** the rock splits in two and the gold band falls. The
  halves stay where they fell, and the children climb on them.

## 5. Build order after approval

0. Approve and record the population (section 3), then update the world bible.
1. `ChinesePlan` data file (islands, bridges, gates, houses with doors and
   facing, strokes, residents, schedules, ledger) and extend
   `tools/validate_village.gd` to read it: overlaps, facing, door-front paths,
   bridge landing height and clearance, ledger, schedules.
2. Island and bridge rebuild (gate island, relocated bamboo island, hierarchy).
3. Courtyard homes, workshops, inn.
4. Palace axis, service yard, kitchen route, garden.
5. Bamboo groves.
6. Residents, homes, schedules, quest-state placements and rewritten Chinese
   dialogue, including staged postquest exchanges between Liang Zhen and Hua
   Chen.
7. Traversal validation for the player, Blorbus and a mount on every
   bridge, landing, residence entrance, palace level and kitchen door.
8. Visual audit by aerial and eye-level capture.

## 6. Decisions needed

1. Population and story state are approved (sections 3.8 and 3.9). Next
   decision: the layout re-fit to them.
2. After that: the gate island and bamboo island move, the courtyard charter
   (4.2), and the palace restructure (4.3), which moves the Royal Kitchen
   entrance and adds a service yard.
