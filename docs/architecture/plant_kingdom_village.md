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
  inn (kept by Bima, 15 Tokoins) stands at `(27, 22)`.
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
| **Monkeys** (tailed) | the primate rig with a tail (`ApeTemplate`) | Rotan, Kilat, Akar | the clearing floor |
| **Apes** (no tail) | the primate rig without a tail | Batu, Sari, Teguh, Ossian Redbrow | the clearing floor; too heavy for the treehouses |

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
  king was Sun Wu Kong, and they have had none since he left. His seat, the
  Water Curtain Cave behind the falls where the river rises, about 650 m
  upriver, has been forgotten; no villager knows it is there
  (`plant_kingdom_water_curtain_cave.md`).

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

### Names (renamed 2026-10-06)

The jungle is a Southeast Asian rainforest of emergent trees, durian and
banana, so the residents take their names from Malay and Indonesian, the
languages of that forest, as in *orang hutan* ("person of the forest"). The
innkeeper Bima already had one. Each resident goes by **one name**, as many
Indonesians do, and the names are everyday words of the forest, sky and
household that are also used as given names. A resident is known by their
tree, not a family name.

- Each name fits its bearer's work or temperament, but nobody explains it in
  play. The exception is Abu ("ash"), whose own line makes the joke.
- Names only: the village speaks the common language. This is not a language
  system like Kai Mālie's Hawaiian or the Chinese village's.
- **Ossian Redbrow keeps his name.** He is a newcomer from somewhere else, and
  his foreign name is part of what marks him as one.

### The Elder Tree (62 m, the tallest, at `(-16, 9)`)

| Resident | Was | Meaning | Role |
|---|---|---|---|
| **Purnama** | Elden Barrow | full moon | the eldest; keeper of what is known about the curse |
| **Abu** | Corvin Ashwake | ash | the village's joker, whose name is a bitter joke about the ashing |
| **Senja** | Sable Hollow | dusk | lost a neighbour's cradle last month; keeps count of the days |
| **Rimba** | Yarrow Dess | deep forest | listens to the vines, and has stopped asking which ones |
| **Sekar** | Wisha Fenlow | flower (Javanese) | prefers the quiet of the high landings; weaves |

### The East Tree (56 m, at `(14, 12)`)

| Resident | Was | Meaning | Role |
|---|---|---|---|
| **Jati** | Rook Bramblewood | teak | carpenter; built or repaired most of the ramps |
| **Dahan** | Kesh Underbough | bough | ramp keeper; has climbed every rung |
| **Embun** | Marlow Quist | dew | warns everyone about the loose third landing, which Jati calls character |
| **Bayu** | Bracken Solt | wind | wind reader; can find home blind by each trunk's creak |
| **Tunas** | Nettle Vray | new shoot | the youngest adult, curious, wants to meet the hero's slime |

### The North Tree (58 m, at `(2, -18)`)

| Resident | Was | Meaning | Role |
|---|---|---|---|
| **Tirta** | Tamsin Reedwalker | water | fisher; watches the river every evening |
| **Bintang** | Tovik Greymoss | star | knows where Xiao Hou Zi roams; the village's guide |
| **Intan** | Pemberly Cade | diamond | has noticed the training grounds going quiet |
| **Murai** | Linnet Grove | magpie-robin, a songbird | naturalist; studies the dawn birdsong |

### The clearing floor

| Resident | Was | Meaning | Class | Role |
|---|---|---|---|---|
| **Delima** | Sedge Marrow | pomegranate | stuffed monkey | forager; runs the fruit stall |
| **Melati** | Ilva Bracken | jasmine | stuffed monkey | keeps the ground gardens |
| **Damar** | Osmund Reave | resin; a lamp | stuffed monkey | ground-dweller who has lost two cousins to the ashing |
| **Wangi** | Dune Sarrow | fragrant | stuffed monkey | friendly to outsiders; keeps the shared kitchen on the commons |
| **Rotan** | Wick Thistledown | rattan | tailed monkey | rope and vine maker |
| **Kilat** | Fable Quickpaw | lightning | tailed monkey | runner and gossip |
| **Akar** | Doran Mossback | root | tailed monkey | path keeper; knows every root |
| **Batu** | Torvin Oakjaw | stone | ape | runs the training grounds, and does not say how |
| **Sari** | Maddox Cindertusk | essence | ape | watches Kova Kong from the tree line |
| **Teguh** | Perrin Vale | steadfast | ape | old friend of Xiao Hou Zi |
| **Ossian Redbrow** | (unchanged) | | ape | newcomer, on Manchego, waiting for the Special Banana |

### The inn

| Resident | Class | Role |
|---|---|---|
| **Bima** (was Bima Canopy) | stuffed monkey | innkeeper |

### Lines that change with the names

Only one existing line names its speaker. Abu's first line becomes: "Abu. Yes,
it means ash, and no, I didn't choose it. Ask my grandmother about the joke."

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
- What the village makes of the Water Curtain Cave once Sun Wu Kong reclaims it.

**Resolved (2026-10-06):**

- The residents are renamed (section 3, Names).
- Sun Wu Kong's old seat, the Water Curtain Cave, stands behind the falls at
  the river's source on Flower Fruit Mountain, the cliffs at the kingdom's west
  end. It is long forgotten until he comes back and reclaims it. See
  `plant_kingdom_water_curtain_cave.md`.
