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
Roles come from what each resident already says; relationships fit their
existing lines (Abu's grandmother, Embun's "carpenters", Senja's cradle).

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

| Name | Was | Meaning |
|---|---|---|
| Purnama | Elden Barrow | full moon |
| Sekar | Wisha Fenlow | flower (Javanese) |
| Abu | Corvin Ashwake | ash |
| Senja | Sable Hollow | dusk |
| Rimba | Yarrow Dess | deep forest |
| Jati | Rook Bramblewood | teak |
| Embun | Marlow Quist | dew |
| Dahan | Kesh Underbough | bough |
| Tunas | Nettle Vray | new shoot |
| Bayu | Bracken Solt | wind |
| Tirta | Tamsin Reedwalker | water |
| Bintang | Tovik Greymoss | star |
| Intan | Pemberly Cade | diamond |
| Murai | Linnet Grove | magpie-robin, a songbird |
| Delima | Sedge Marrow | pomegranate |
| Melati | Ilva Bracken | jasmine |
| Damar | Osmund Reave | resin; a lamp |
| Wangi | Dune Sarrow | fragrant |
| Akar | Doran Mossback | root |
| Kilat | Fable Quickpaw | lightning |
| Rotan | Wick Thistledown | rattan |
| Sari | Maddox Cindertusk | essence |
| Teguh | Perrin Vale | steadfast |
| Batu | Torvin Oakjaw | stone |
| Bima | Bima Canopy | a hero of the wayang epics |
| Laras | (new) | harmony |
| Gilang | (new) | shining |

### Households, genders and relationships (proposed 2026-10-06)

Twenty-six residents in fourteen households: 12 women and 14 men. Genders are
identity only: monkey and ape bodies are never shaped by gender. There are
couples in every part of the village, but **no children**: nobody has dared a
cradle since the last one, and the couples live with that.

**The lost household.** Last month a young couple on the North Tree,
**Laras** (woman) and **Gilang** (man), had a baby, and the curse took them.
Their pavilion on the North Tree's 34.2 m ring stands as they left it:
- hammocks still slung;
- a cradle hanging from the roof beam;
- blinds tied down by the neighbours.

Nobody goes in. This is the "cradle two trees over" that Senja counts the days
from.

#### The Elder Tree (62 m, the tallest, at `(-16, 9)`)

| Resident | Gender | Household | Relationships | Role |
|---|---|---|---|---|
| **Purnama** | woman | crown deck, with her sister | Sekar's elder sister; Abu's grandmother, who raised him | the eldest; keeper of what is known about the curse; presides at the gathering circle |
| **Sekar** | woman | crown deck, with her sister | Purnama's younger sister; never married; Abu's great-aunt | weaver; looks after Purnama and the crown deck's quiet |
| **Abu** | man | his own pavilion, 22.8 m, at the bridge head | Purnama's grandson; his parents were lost to the ashing when he was small, and Purnama raised him; best friend of Kilat on the floor | the joker; climbs to the crown deck every evening with his grandmother's supper |
| **Senja** | woman | a couple's pavilion, 34.2 m | married to Rimba; Laras's closest friend | keeps count of the days since the cradle |
| **Rimba** | man | a couple's pavilion, 34.2 m | married to Senja | listens to the vines |

#### The East Tree (56 m, at `(14, 12)`)

| Resident | Gender | Household | Relationships | Role |
|---|---|---|---|---|
| **Jati** | man | a couple's pavilion, 22.8 m | married to Embun; Dahan's elder brother; raised his niece Tunas; old friend of Teguh, both once pestered by Xiao Hou Zi | carpenter; workshop on the commons |
| **Embun** | woman | a couple's pavilion, 22.8 m | married to Jati; Tunas's aunt by marriage, who raised her | warns everyone about the loose third landing, which "the carpenters", her husband and his brother, call character |
| **Dahan** | man | his own pavilion, 22.8 m, at the ramp head | Jati's younger brother; Tunas's uncle | ramp keeper |
| **Tunas** | woman | her own new pavilion, 34.2 m, just above her aunt and uncle | Jati and Dahan's niece, daughter of their late sister; raised by Jati and Embun; has just moved out on her own | the youngest adult; curious about everything, the hero's slime most of all |
| **Bayu** | man | his own pavilion, 34.2 m, the wind corner | lives alone; old friend of Jati's family; teaches Tunas to read the wind | wind reader |

#### The North Tree (58 m, at `(2, -18)`)

| Resident | Gender | Household | Relationships | Role |
|---|---|---|---|---|
| **Tirta** | woman | a couple's pavilion, 22.8 m, facing the river | married to Bintang | fisher; at the river every evening |
| **Bintang** | man | a couple's pavilion, 22.8 m | married to Tirta; friendly rival of Akar over the best way through the forest (Bintang by the canopy, Akar by the roots) | guide; knows where Xiao Hou Zi roams |
| **Intan** | woman | siblings' pavilions, 34.2 m, joined by a shared deck | Murai's sister; Laras and Gilang's neighbour | the watcher: notices everything, the training grounds most of all |
| **Murai** | man | siblings' pavilions, 34.2 m | Intan's brother | naturalist; the dawn birdsong |
| *(Laras and Gilang)* | | the empty pavilion, 34.2 m | lost to the curse last month | |

#### The clearing floor

| Resident | Gender | Class | Household | Relationships | Role |
|---|---|---|---|---|---|
| **Delima** | woman | stuffed monkey | garden house | Melati's partner; supplies Wangi's kitchen with fruit | forager; the fruit stall |
| **Melati** | woman | stuffed monkey | garden house | Delima's partner; the two chose the ground together when the others climbed | gardens and the nursery |
| **Damar** | man | stuffed monkey | floor hut | married to Wangi; lost two cousins to the ashing | resin tapper; keeps the village's lamp fuel |
| **Wangi** | woman | stuffed monkey | floor hut | married to Damar; Bima's sister | the shared kitchen on the commons |
| **Akar** | man | tailed monkey | the tailed monkeys' house | married to Kilat; Rotan's younger brother; Bintang's friendly rival | path keeper; knows every root |
| **Kilat** | woman | tailed monkey | the tailed monkeys' house | married to Akar; Abu's best friend across the canopy and floor | runner and gossip |
| **Rotan** | man | tailed monkey | the tailed monkeys' house | Akar's elder brother; unmarried | rope and vine maker |
| **Sari** | woman | ape | the ape lodge | married to Teguh; Batu's sister | watches Kova Kong from the tree line |
| **Teguh** | man | ape | the ape lodge | married to Sari; old friend of Xiao Hou Zi and of Jati | the apes' steady one |
| **Batu** | man | ape | the ape lodge | Sari's elder brother; keeps his own counsel even with her | runs the training grounds, and does not say how |
| **Ossian Redbrow** | man | ape | his lean-to by the stable | a newcomer; Kilat's favourite subject | waiting for the Special Banana |

#### The inn

| Resident | Gender | Class | Household | Relationships | Role |
|---|---|---|---|---|---|
| **Bima** | man | stuffed monkey | the inn, his own room | Wangi's brother; his guests eat at her kitchen | innkeeper |

### Households summary

| Household | Members | Home |
|---|---|---|
| The sisters of the crown | Purnama, Sekar | Elder Tree crown deck |
| Abu | Abu | Elder Tree 22.8 m |
| Senja and Rimba | Senja, Rimba | Elder Tree 34.2 m |
| Jati and Embun | Jati, Embun | East Tree 22.8 m |
| Dahan | Dahan | East Tree 22.8 m |
| Tunas | Tunas | East Tree 34.2 m |
| Bayu | Bayu | East Tree 34.2 m |
| Tirta and Bintang | Tirta, Bintang | North Tree 22.8 m |
| Intan and Murai | Intan, Murai | North Tree 34.2 m |
| *(the empty pavilion)* | *(Laras and Gilang)* | North Tree 34.2 m |
| The garden house | Delima, Melati | ground |
| The floor hut | Damar, Wangi | ground |
| The tailed monkeys' house | Akar, Kilat, Rotan | ground |
| The ape lodge | Sari, Teguh, Batu | ground |
| Ossian | Ossian | lean-to |
| The inn | Bima | commons |

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

- What the village makes of the Water Curtain Cave once Sun Wu Kong reclaims it.

**Deferred to the storyline (2026-10-06):** whether the curse touches apes,
and whether the surviving shadows of the ashed are visible in the village.

**Resolved (2026-10-06):**

- The inn moves up to the commons' edge beside the East Tree.
- Landscape and planting: `plant_kingdom_landscape.md`.

- The residents are renamed (section 3, Names).
- Sun Wu Kong's old seat, the Water Curtain Cave, stands behind the falls at
  the river's source on Flower Fruit Mountain, the cliffs at the kingdom's west
  end. It is long forgotten until he comes back and reclaims it. See
  `plant_kingdom_water_curtain_cave.md`.
