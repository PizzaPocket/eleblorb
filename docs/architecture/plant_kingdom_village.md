# Plant Kingdom: The Primate Village

Status: concept brief, first full planning pass, in review (2026-10-06). The
dimensioned layout is in `plant_kingdom_village_layout.md`.

## 1. What exists now

From `jungle_kingdom_village.gd`, `jungle_kingdom_terrain.gd`,
`jungle_kingdom_foliage.gd` and `scenes/primate_kingdom.tscn`:

- **Site:** the village sits at the kingdom's origin, on ground levelled flat
  within 55 m and blending out over 22 m more. The jungle scatter keeps clear
  only within 24 m. A river winds about 150 m south (`+z`), 14 m deep with its
  water at -3 m. Four clearings and three rocky outcrops lie farther out;
  mountains ring the kingdom.
- **Arrival:** the return gate stands **in the middle of the village** at
  `(0, -3)`; arrivals appear at `(0, 4)`.
- **Trees:** three giant emergent trees, 56, 62 and 58 m tall, at `(14, 12)`,
  `(-16, 9)` and `(2, -18)`, with climbable branch-ramps spiralling up their
  trunks.
- **Treehouses:** on every fourth landing, a 3.6 × 3.6 m deck with an open
  treehouse (a central timber pillar, open sides, a broad green leaf roof) and
  one villager standing on it; thirteen in all.
- **Ground:** three villagers roam within 32 m; six "primate template"
  primates roam the clearing; Ossian Redbrow sits on Manchego at `(6, -4)`; the
  inn (kept by Bima Canopy, 15 Tokoins) stands at `(27, 22)`.
- **Beyond:** Kova Kong at `(400, -280)`; the hidden Wood Kingdom area at
  `(-250, -300)`; ape skeleton NMEs spawning outside the safe zone; training
  dummies "out past the clearing".
- **Performance:** a reported problem; the ground population was already cut
  for lag.

### Non-regression requirements

- The three giant trees with spiralling branch-ramps, and the treehouse
  character: open platforms, a central timber pillar, exposed sides, broad green
  leaf roofs, open climbing routes.
- Every named resident and their lines; the three primate classes and two rigs.
- The gate, the inn and its price, Ossian on Manchego and his quest, the
  Special Banana on Kova Kong, the curse, the Wood Kingdom reveal, the training
  dummies.
- No worse performance than today.

## 2. Premise

### Three classes, two rigs, one village

| Class | Rig | Who | Where they live |
|---|---|---|---|
| **Stuffed-animal monkeys** | the stuffed-animal monkey rig (`JungleVillager`, Xiao Hou Zi's kind) | eighteen villagers and the innkeeper | mostly in the trees; four on the clearing floor |
| **Monkeys** (tailed) | the primate rig with a tail (`ApeTemplate`) | Wick Thistledown, Fable Quickpaw, Doran Mossback | the clearing floor |
| **Apes** (no tail) | the primate rig without a tail | Torvin Oakjaw, Maddox Cindertusk, Perrin Vale, Ossian Redbrow | the clearing floor; too heavy for the treehouses |

The village's social shape comes from its residents' own words:

- **Canopy and floor.** The stuffed-animal monkeys climbed into the trees
  generations ago ("the trees got safer, somehow, and everyone climbed"). The
  floor-dwellers (the tailed monkeys, the apes and the few villagers who stayed
  down) feel looked down on, literally.
- **Elders keep to the tallest tree,** and nobody younger asks why anymore.
- **The curse.** Whenever a baby monkey is born, the kingdom's monkeys are
  reduced to ashes; their shadows survive. So there are **no children** in the
  village. "A cradle went up two trees over last month." Everyone is counting the
  days. Whether the apes, who are not monkeys, are touched by the curse is open.
- **No king.** If the Sky Kingdom's proposed history stands, the jungle monkeys'
  king was Sun Wu Kong, and they have had none since he left.

### Livelihood

- **The commons:** a large shared deck at 11.4 m spanning the three trees above
  the gate, with the gathering circle, shared kitchen, dining terrace, market,
  rain cistern and food store, reached by everyone (see the layout).
- **Foraging:** fruit (bananas and durian, both already in the game's catalogue
  and growing on its trees), nuts, shoots and honey, mostly gathered by the
  floor-dwellers.
- **River fishing** at the river's bank.
- **Vine, bark and rope work** for the ramps, bridges and treehouses.
- **The training grounds,** a business on the clearing's edge whose keeper is
  secretive.
- **The inn,** for rare travellers.

## 3. Community

Twenty-six named residents. Households follow the three trees and the floor.
Roles come from what each resident already says.

### The Elder Tree (62 m, the tallest, at `(-16, 9)`)

| Resident | Role |
|---|---|
| **Elden Barrow** | the eldest; keeper of what is known about the curse |
| **Corvin Ashwake** | the village's joker, whose family name is a bitter joke about the ashing |
| **Sable Hollow** | lost a neighbour's cradle last month; keeps count of the days |
| **Yarrow Dess** | listens to the vines, and has stopped asking which ones |
| **Wisha Fenlow** | prefers the quiet of the high landings; weaves |

### The East Tree (56 m, at `(14, 12)`)

| Resident | Role |
|---|---|
| **Rook Bramblewood** | carpenter; built or repaired most of the ramps |
| **Kesh Underbough** | ramp keeper; has climbed every rung |
| **Marlow Quist** | warns everyone about the loose third landing, which Rook calls character |
| **Bracken Solt** | wind reader; can find home blind by each trunk's creak |
| **Nettle Vray** | the youngest adult, curious, wants to meet the hero's slime |

### The North Tree (58 m, at `(2, -18)`)

| Resident | Role |
|---|---|
| **Tamsin Reedwalker** | fisher; watches the river every evening |
| **Tovik Greymoss** | knows where Xiao Hou Zi roams; the village's guide |
| **Pemberly Cade** | has noticed the training grounds going quiet |
| **Linnet Grove** | naturalist; studies the dawn birdsong |

### The clearing floor

| Resident | Class | Role |
|---|---|---|
| **Sedge Marrow** | stuffed monkey | forager; runs the fruit stall |
| **Ilva Bracken** | stuffed monkey | keeps the ground gardens |
| **Osmund Reave** | stuffed monkey | ground-dweller who has lost two cousins to the ashing |
| **Dune Sarrow** | stuffed monkey | friendly to outsiders; keeps the shared kitchen on the commons |
| **Wick Thistledown** | tailed monkey | rope and vine maker |
| **Fable Quickpaw** | tailed monkey | runner and gossip |
| **Doran Mossback** | tailed monkey | path keeper; knows every root |
| **Torvin Oakjaw** | ape | runs the training grounds, and does not say how |
| **Maddox Cindertusk** | ape | watches Kova Kong from the tree line |
| **Perrin Vale** | ape | old friend of Xiao Hou Zi |
| **Ossian Redbrow** | ape | newcomer, on Manchego, waiting for the Special Banana |

### The inn

| Resident | Class | Role |
|---|---|---|
| **Bima Canopy** | stuffed monkey | innkeeper |

### Governance

The elders of the Elder Tree decide for the village, meeting in the gathering
circle on the commons, where canopy and floor households meet; the
floor-dwellers still feel they are not asked. Ending the curse is the kingdom's plot quest; mending
the canopy and the floor is a smaller story the village tells on its own.

## 4. Architectural charter (draft)

- **Primary, about 70 percent: jungle canopy vernacular built by primates.**
  The existing treehouse character (an open platform, a central timber pillar,
  exposed sides, a broad green leaf roof) developed into household clusters:
  wrap-around decks lashed to the trunk, open pavilions on them, hammock nests,
  and rope-and-plank bridges between trees. Everything lashed with vine and rope
  rather than nailed ("bark doesn't hold a nail the way wood does").
- **Secondary, about 25 percent: ground lodges.** Low, wide, thatched lodges on
  short timber stilts for the floor-dwellers, built heavier for apes.
- **Accent, about 5 percent:** the commons, the village's one large deck, and
  carved trunk markers.
- **Structural precedents** (spatial only, not cultural costume): high
  rainforest treehouses lashed around living trunks, and canopy walkways of
  rope and plank.
- **Palette:** living bark and lashed timber, leaf-green roofs (keeping the
  prototype's varied roof colours as household accents), vine-rope, warm fruit
  colours at the stall.
- **Exclusions:** nailed carpentry, enclosed boxes, lights on poles, fire in the
  trees except the commons' single stone-based kitchen hearth.

## 5. Fixed, proposed and open

**Fixed:** everything in the non-regression list.

**Proposed:** the canopy and floor social shape; no children because of the
curse; households by tree; roles from existing lines; foraging, fishing, rope
work, the training grounds and the inn as livelihood; the fruit stall; the
charter.

**Open:**

- Whether the curse touches apes.
- Whether the surviving shadows of the ashed are visible in the village.
- Whether the residents' names should be reworked like the Sky Kingdom's and
  sea folk's.
- Whether Sun Wu Kong's old seat (in his legend, the Water Curtain Cave behind a
  waterfall on Flower Fruit Mountain) has a place in this kingdom.
