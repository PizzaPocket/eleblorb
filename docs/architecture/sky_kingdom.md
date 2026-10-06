# Sky Kingdom: Courts of the Clouds

Status: concept brief, second pass, in review (2026-10-06). The dimensioned
layout and building programs are in `sky_kingdom_layout.md`. It replaces the
first-pass prototype's loose cluster of pavilions with a planned celestial
society, census, material system and architectural charter. No layout
coordinates are fixed yet; those follow approval of this brief.

## 1. What exists now

`scripts/sky_kingdom.gd` builds a prototype that the world bible calls a
deliberate first pass:

- four cloud islands: **Aethra** (radius 46 m) and three satellites, the
  **Chrysa**, the **Lyria** and the **Koinon** (radius 30 m);
- island positions as offsets from the Air Gem landing at the top of the town's
  cloud staircase, resolved at runtime from procedural cloud placement, along
  an "away from the village" direction;
- islands made from the same unshaded white puff recipe and altitude band
  (about 87 to 138 m) as the world's ordinary clouds, so a revealed island
  reads as an ordinary cloud turning out to be ground;
- one quartz-and-gold pavilion per island, plus seeded spires, obelisks and
  dwellings;
- six named Tempestars, with a humanoid upper body over a `TornadoTail`
  funnel, gold jewellery and pastel sky colouring;
- everything, the staircase included, invisible and without collision unless
  the hero wears a blorb carrying the **Bird Helm**. It is built lazily the
  first time the helm reveals it.

### Non-regression requirements

- The Bird Helm gate: the kingdom is completely absent without it, and the
  town staircase and Air Gem landing are its only entrance.
- Islands are the world's own clouds at the world's own altitude, not a
  separate higher layer or a new cloud material.
- The six existing Tempestars, their names, ruling arrangement and the tone of
  their lines: small proud rulers of single clouds, faintly lonely, missing
  the Air blorbs.
- The quartz, gold and pastel palette and the open, airy pavilion character.
- The missing Air blorbs as the kingdom's central plot premise.
- Lazy construction, so a run that never wears the helm pays nothing.

### What this pass replaces

- Placement resolved from procedural RNG. An authored settlement needs an
  authored position: the plan should fix the staircase landing and the islands
  in data, then let ambient clouds avoid them.
- Seeded scatter of spires, obelisks and dwellings with no owner or program.
- A population of six rulers and attendants with no economy, daily life or
  reason to live where they do.

## 2. Premise

The Tempestars are not gods. They are a people of the sky, as the merfolk are
of the sea and the lava people of the volcano. Their culture draws on the
human world's images of a heaven above the clouds. Greek and Roman heavens are
the stronger influence; the Chinese Celestial Court is a substantial second,
carrying Sun Wu Kong's story, since he is already part of the game:

- **The Chinese Celestial Court, as Journey to the West tells it:** Sun Wukong
  as king of the monkeys of Flower Fruit Mountain who rose to heaven, the Jade
  Emperor's palace beyond the Southern Heavenly Gate, audiences in the Hall of
  Miraculous Mist, a bureaucracy of offices and titles, the lowly post of
  keeper of the heavenly horses that Sun Wukong was given and resented, the
  empty title "Great Sage Equal to Heaven" granted to quiet him, the Queen
  Mother of the West's peaches that ripen once in an age, the Peach Banquet he
  was not invited to and wrecked, the Weaver Girl who wove the coloured
  clouds, and the Heavenly River.
- **Greek Olympus:** a court of immortals on a summit veiled in cloud, its
  gates of cloud kept by the Horai, feasts of nectar and ambrosia, Hephaestus's
  golden attendants and the self-moving golden tripods that wheeled themselves
  to the gods' assembly and back, the Muses' music, contests and games.
- **Roman heaven and civic religion:** colonnades, the council in the round,
  the triclinium banquet with diners reclining on couches, the eternal hearth.

These sources supply the feeling of a leisured heaven. They do not supply
religion, worship, real deities or a copied temple. Nobody in the game prays to
a Tempestar, and no sacred building from a living tradition is reproduced.

### Bodies and invisibility

A Tempestar's upper body is solid and humanoid; below the waist it is living
cloud, drawn into a slow turning vortex. The existing `TornadoTail` funnel is
this cloud body and stays. Tempestars are not hidden by distance or magic
doors: they live a little out of phase with ordinary sight, as the whole
kingdom does. The Bird Helm brings the wearer into that phase.

### Food without farming

The Tempestars barely work for food. Their cuisine arrives from sun, dew and
cloud, and its preparation is an art rather than a chore:

- **Nectar** condenses at dawn as golden dew inside shallow gold bowls set out
  on east-facing terraces. Gold is the only surface it gathers on. It is sweet,
  faintly effervescent and has to be collected before the sun burns it off.
- **Ambrosia** is a light bread made from the dense crown of a noon cumulus,
  kneaded with nectar and baked on gold plates in direct sunlight.
- **Golden peaches** grow on cloud-rooted trees. Each tree ripens a few fruit a
  season, and the first peach of the season is a matter of fierce precedence.
- **Sky-fruit, honey and rain-wines** follow the same pattern: sun, water and
  cloud do the growing; Tempestars choose, gather, compose and serve.

Food moves between rooms and clouds on **golden tripods**: small gilded,
self-moving serving stands that carry dishes to a table and return to their
alcove. They are animated objects with simple routes, not servants with minds.

### Leisure and its costs

With food and shelter given freely, Tempestars spend their long lives on music,
verse, games, gardens, conversation, stargazing, weather-shaping and fine
craft. This is the kingdom's beauty and its trouble:

- Nobody needs anybody. Without shared work there is little to bind one cloud
  to the next.
- Status replaces livelihood. Titles, precedence at feasts, whose music is
  admired and whose cloud stands tallest matter more than they should.
- Every court has a crown. Small rulers preside over small courts, each
  convinced its cloud is the true centre.
- Problems are always another court's problem. When the Air blorbs vanished,
  every court assumed someone else would see to it, and nobody did.

### Lifespans

Tempestars age and have children, but their lives are very long and children
are rare. Someone who looks young may have watched the courts drift apart; the
elders remember the Hall of Assembly full.

### Sun Wu Kong and the courts (proposed)

The Tempestars' long memory includes Sun Wu Kong, and their version of events
follows his legend closely:

1. **The Monkey King.** Long ago Sun Wu Kong was king of the monkeys of the
   Primate Kingdom's jungle. He rode the Jindouyun up into the courts uninvited
   and demanded to be received as a king among kings.
2. **The empty title.** The cloud rulers would not treat a jungle monkey as
   their equal. To quiet him they named him **Great Sage Equal to Aethra**, a
   title with no cloud, court or duties, and set him to guard Pantao's peaches
   to keep him busy. He took the title at its word until he learned what it was
   worth.
3. **The Peach Banquet.** Left off the guest list for Pantao's great
   Peach Banquet, he ate the season's golden peaches, drank the nectar,
   overturned the tables and Dromos's games, and fought the courts'
   champions to a standstill with the Jingu Bang.
4. **The sealing.** All six courts met in the Hall of Assembly on Koinon, the
   only time in living memory they acted together, and sealed him beneath a
   rock on the highest roof below them: the crown of the Emperor's castle in
   the Chinese village. They bound the seal so that only one of his own
   monkeys could lift it, sure that none would ever come looking for him. That
   is why Xiao Hou Zi can free him. The sealing decree, inscribed in gold, is the
   last decision on the Hall's walls. With their common trouble gone, the courts
   stopped meeting.

**Now.** The sealing was long ago, within the long memory of the eldest
Tempestars but before most ground-dwellers' grandparents were born. The Air
blorbs vanished only recently. The courts are furious with him, as heaven is
in his legend: he insulted their crowns, ate their peaches and ruined their
banquet, and they have never forgiven it. When he turns up alongside the hero,
freed by Xiao Hou Zi, every court is outraged that he is loose in their sky
again, and they blame him for the missing Air blorbs too. They are wrong; the
Demon King took them. He is not sorry about anything else.

**The Primate Kingdom.** The jungle monkeys have had no king since he left for
the clouds. Their villagers still tell of the Monkey King who went up into the
sky and never came back; the youngest think it is only a story. Sun Wu Kong's
return, and Xiao Hou Zi's part in it, connect the two kingdoms' stories. Whether
he goes home to his people, and whether his long absence had any part in the
Primate Kingdom falling under the Demon King's curse, are open.

**Resolution.** The return of the Air blorbs restores harmony. Seeing the flocks
drift between the clouds again makes the courts realise how distant and
frivolous they had become: rulers who let a whole people's creatures vanish
while they argued over precedence and peaches. The courts meet in the Hall of
Assembly again, for the first time since the sealing, and this time for
something better. Koinon's empty seats fill, and the courts visit one another
again. How the quest stages that change is not yet designed.

Who remembers what:

- **Mnesia** keeps his offences in Aethra's ledger, itemised.
- **Chunlu** still counts the peaches he ate.
- **Nikandra** has never forgiven the ruined games.
- **Xiangyun** still refuses to say his name at her table.
- **Archeia** tends the sealing decree in the empty Hall.

## 3. Community

### Island names

The six cloud islands take mixed names that match each court's style:
Greek-rooted for the Greco-Roman courts and Chinese for the court of the Peach
Garden. They replace the prototype's Highcloud, Anvil Cloud, Drift Cloud and
Hollow Cloud.

| Island | Meaning | Court |
|---|---|---|
| **Aethra** | from *aether*, the bright upper air | state; the capital |
| **Chrysa** | from *chrysos*, gold | craft and weather; the goldsmiths |
| **Lyria** | from the lyre | music and verse |
| **Koinon** | "the common", what is shared by all | learning and the empty Hall of Assembly |
| **Pantao** | 蟠桃, the flat peaches of immortality in the Celestial Court | the feast and the Peach Garden |
| **Dromos** | racecourse | games |

Aethra's Hall of Mist and Pantao's Peach Garden carry the Chinese palace style;
the other courts are Greco-Roman. The old names remain in `sky_kingdom.gd`,
and Sophrona's existing line explains the name "Hollow Cloud"; both change when
the kingdom is rebuilt.

The census is **twenty-one Tempestars in six courts**: nineteen adults and two
children, in the four existing courts with added members and two new courts. Each court is a household-like group
around one ruler, and each corresponds to an office of the mythic heavenly
courts. Duties that were once one shared government are now split among rival
courts that rarely speak.

Names match the island names: invented Greek-rooted names for the Greco-Roman
courts and Chinese names for Pantao. Tempestars go by a single given name and
are known by their court ("Drosia of Aethra"). They replace every prototype
name; "(existing)" marks a renamed prototype resident, with the old name for
reference.

| Name | Root or meaning | Prototype name |
|---|---|---|
| Aristeon | *aristos*, best | Cumulus Highvane |
| Mnesia | memory | Squall Windrider |
| Alkis | strength, quickness | Breeze Suncrest |
| Drosia | *drosos*, dew | — |
| Aurelia | Latin *aurum*, gold | Nimbus Greywisp |
| Kallix | *kallos*, beauty | — |
| Keraunia | *keraunos*, thunderbolt | — |
| Elegon | elegy | Gale Stormwick |
| Aulia | *aulos*, the double flute | — |
| Rhapsos | the rhapsode, reciter of verse | — |
| Sophrona | *sophrosyne*, temperance and good sense | Cirro Ashveil |
| Astrion | star | — |
| Archeia | *archeion*, archive | — |
| Xiangyun | 祥云, auspicious cloud | — |
| Tianlu | 天禄, heavenly bounty | — |
| Chunlu | 春露, spring dew | — |
| Mingyue | 明月, bright moon | — |
| Nikandra | *nike*, victory | — |
| Tachys | swift | — |
| Stephane | *stephanos*, wreath | — |
| Dromeus | runner | — |

### Aethra: the court of state (capital, tallest)

The Olympian or Jade Emperor's throne room, reduced to one cloud.

- **Aristeon** (existing), ruler. Holds the tallest crown and gives
  audiences that nobody else attends. Proud of precedence; quietly misses the
  company the updrafts used to bring.
- **Mnesia** (existing), chamberlain and keeper of ledgers. Records
  titles, precedence and every slight between courts. Keeps the ruler's robes
  from blowing off the edge.
- **Alkis** (existing), herald. The youngest at Aethra and the only
  Tempestar who still floats between clouds carrying invitations and news,
  like Hermes or Iris. Chased Air blorbs as a child.
- **Drosia**, cupbearer. Sets the gold dew bowls out before dawn and
  gathers the nectar for Aethra's table. Knows precisely how much each court
  drinks, which makes Drosia the court's best source of gossip.

### Chrysa: the court of craft and weather

Hephaestus's forge and the thunderhead's anvil top.

- **Aurelia** (existing), ruler and goldsmith. The only court that
  makes things: gold pins, tripods, bowls and the anchors every building in
  the kingdom depends on. Resents that the other courts treat this as a service
  owed to them.
- **Kallix**, apprentice goldsmith. Brilliant at beginning pieces and
  rarely finishes one.
- **Keraunia**, weather-shaper. Herds storm cloud for the forge's heat
  and light and keeps Chrysa's own weather.

### Lyria: the court of music and verse

The Muses' choir in a court of three.

- **Elegon** (existing), ruler and poet. Feels the crown as an exile and
  would trade it for a neighbour.
- **Aulia**, musician. Plays wind harps strung between the
  colonnade's columns. Rehearses for audiences that have stopped coming.
- **Rhapsos**, keeper of songs. Holds the kingdom's verse in memory and
  on gold leaf.

### Koinon: the court of learning and the empty hall

The council of the heavens, now a scholar's observatory beside an empty
assembly.

- **Sophrona** (existing), ruler and philosopher. At the cloud's centre is the vacant
  Hall of Assembly, where all the courts once met. Sophrona
  thinks it is waiting to be filled.
- **Astrion**, stargazer. Keeps the observatory and the calendar of
  seasons, as the Horai once kept heaven's gates.
- **Archeia**, archivist. Tends the empty hall and the decisions
  inscribed in gold around it, the last of them very old.

### Pantao (new): the court of the feast

The Queen Mother of the West's peach garden and the golden fruit of the
Hesperides.

- **Xiangyun**, ruler and hostess. Holds the most lavish banquets in the
  kingdom, partly to outshine Aethra. The guest list is a weapon.
- **Tianlu**, master of the table. Composes the kingdom's cuisine:
  ambrosia, nectar wines, peach dishes, sky-fruit, and the order of courses.
- **Chunlu**, orchard keeper. Tends the cloud-rooted peach and fruit
  trees, and is the one who knows which peach is truly first.
- **Mingyue**, Xiangyun's daughter and the younger of the kingdom's two children.
  Raised at banquets, and openly bored by them.

### Dromos (new): the court of games

Olympian contests and the hippodrome.

- **Nikandra**, ruler and judge of contests. Presides over races and
  games around a ring-shaped cloud, and keeps the record of every victory.
- **Tachys**, racer. Young, fast and bored, and the court's champion
  because there is hardly anyone left to race.
- **Stephane**, keeper of the course and the prizes: gold rings,
  wreaths of woven cloud, laurels from Pantao when the two courts
  are speaking.
- **Dromeus**, Nikandra's son and the elder child. Races Tachys and loses,
  and would race anyone from any court if the rulers allowed it.

### Responsibility map

| Need | Who | Where |
|---|---|---|
| Ceremony, precedence, records of rank | Aristeon, Mnesia | Aethra |
| News and invitations between clouds | Alkis | everywhere |
| Nectar | Drosia (Aethra); each court sets its own bowls | east terraces |
| Ambrosia, fruit, banquets | Tianlu, Chunlu, Xiangyun | Pantao |
| Gold: anchors, pins, vessels, tripods | Aurelia, Kallix | Chrysa |
| Weather and cloud-shaping | Keraunia; every Tempestar a little | Chrysa |
| Music and verse | Aulia, Rhapsos, Elegon | Lyria |
| Calendar, seasons, stars | Astrion | Koinon |
| Shared law and archives | Archeia, Sophrona | Koinon hall |
| Games and contests | Nikandra, Tachys, Stephane | Dromos |

There is no labour of survival anywhere in this table. Everything listed is
either pleasure or a duty that only matters because other courts exist, which
is why so much of it has lapsed.

### Governance

Each court is sovereign over its own cloud and nothing else. The Hall of
Assembly on Koinon is where shared decisions were once made; no
court has called it in living memory. Contact now runs through Alkis's
invitations, Drosia's gossip and banquets that are as much contests as meals.
Disputes are over precedence, over whose cloud shadows whose terrace, over the
first peach and over whose music is better.

## 4. Material system: cloud, gold and quartz

The kingdom is built from three materials with distinct roles. The rule that
connects them is simple enough to read on sight: **cloud gives volume, gold
holds it, quartz carries weight.**

### Cloud

Tempestars can coax cloud into three states:

1. **Bank cloud:** the natural island cloud. The ground of each court. Soft
   underfoot, slightly yielding, always the same white puff material as the
   world's ordinary clouds.
2. **Woven cloud:** drawn into threads and woven, as by the Weaver Girl, into
   translucent awnings, curtains, sails, cushions and robes. Light, moving,
   never structural.
3. **Set cloud:** cloud persuaded to hold a shape: floating couches, stools,
   tables, bowers, small floating rooms and steps. Set cloud holds its shape
   only where gold binds it. A couch is a cloud volume pinned by a gold frame;
   a floating room is a cloud shell held inside gold rings.

### Gold

Gold is the structural anchor of everything that defies gravity. It also
gathers nectar, carries dishes as tripods, and is the kingdom's jewellery.
Gold appears as rings, pins, filigree frames, column capitals and bases,
thin roof edges, chains and the hoops that moor set cloud. Gold is used
structurally and sparingly, not as general wall cladding.

### Quartz

Clear to milky-white sky quartz, the existing pavilion material, forms floors,
column shafts, stairs, platforms and anything a body must stand on reliably.
It takes light like marble and glass at once.

### Construction that defies gravity

The courts build as if weight were optional, within rules a player can learn:

- **Floating roofs:** a roof hovers a short, clear gap above its colonnade,
  held by gold pins of light, so sky shows between capital and eave.
- **Hanging columns:** some columns hang from a roof and stop short of the
  floor, ending in gold finials.
- **Drifting stairs:** stairs of separate quartz slabs float in sequence with
  open air between them.
- **Moored rooms:** small round rooms of set cloud float beside a building,
  held by gold rings and reached by a short gangway.
- **Undersides:** gardens and fruit trees grow downward from the underside of
  some clouds toward the light reflected up from the world below.

### Gameplay rules for the materials

These keep the fantasy physically honest for platforming, per the project's
collision policy:

- Anything a character is meant to stand on, climb or be blocked by has
  collision: quartz floors and stairs, gold frames, set-cloud couches, tables
  and steps. Woven cloud (awnings, curtains, sails) is decorative and is
  passed through.
- Floating furniture and slabs may bob, but slowly and by a few centimetres at
  most. Anything that moves farther is a real moving platform with carry
  behaviour, not a visual drift with static collision.
- A floating roof's gap and a hanging column's missing base are visual
  statements. Rooms under them still need full headroom and clear routes.
- Bank cloud keeps the current pad collision approach: the walkable surface is
  a simplified collider that matches the visible top.
- Everything, NPCs and tripods included, remains gated on the Bird Helm.

## 5. Flora: cloud-rooted plants

The kingdom grows no soil plants. Its trees and flowers root directly in bank
cloud and grow from the essence of cloud itself. Trunks, branches and leaves
use the same cloud material as the islands and the world's ordinary clouds:
soft, white and lit like cloud, taking the sky's dawn and dusk tints with it.
Only fruit and some blossoms carry their own colour.

| Species | Form | Colour beyond cloud | Where |
|---|---|---|---|
| Cloud peach | broad, low-spreading orchard tree | golden peaches | Pantao; one old tree at Aethra |
| Cloud willow | weeping crown whose long strands thin out and fade before they touch anything | none | beside nectar terraces and the odeon |
| Tier pine | flat, stacked layers like stratus decks | none | Koinon, framing the empty hall; Aethra's axis |
| Puff shrub | low, round cumulus bushes, clipped into hedges | none | court thresholds and garden edges |
| Cloud wisteria | trailing blossom over colonnades and floating roofs | faint dawn pink and lavender blossom | Lyria, Pantao |
| Undercloud vine | hangs from an island's underside toward the light reflected from below | pale gold berries | beneath the Orchard and Chrysas |
| Sky lily | flat leaves and cup flowers floating on shallow pools of set cloud | pale gold or white flowers | Koinon's empty hall, Aethra's forecourt |

Collision follows the project policy: trunks and substantial branches block and
can be climbed or stood on where they visibly could bear weight; foliage, willow
strands, blossom and vines are decorative.

## 6. Architectural charter (draft)

This split is deliberately closer than the usual 75/20 charter. Cohesion comes
from shared invariants instead: quartz shafts, gold capitals and bases, the
floating roof gap, superellipse openings, the stepped quartz podium and the
palette. No single building uses both traditions' roof and wall systems.

- **Primary, about 55 percent: Greco-Roman celestial classical.** Peristyle
  courts, round tholos pavilions, colonnades and exedrae, porches with
  pediments reduced to soft SuperEgg forms, an odeon, a racing ring, banquet
  couches and colonnaded nectar terraces. Quartz shafts, gold capitals and
  bases, floating roofs. It governs Chrysa, Lyria, Koinon and Dromos,
  every residence and terrace, and the kingdom's overall feel.
- **Secondary, about 35 percent: the Chinese celestial palace.** It governs the
  places that carry Sun Wu Kong's story: the Dawn Gate after the Southern
  Heavenly Gate, Aethra's Hall of Mist on its stepped quartz podium with
  floating double eaves, and Pantao's Peach Garden and banquet hall.
  Elsewhere it appears only as named details: moon gates of set cloud and
  upturned eave corners on gate pavilions. Quartz replaces red-lacquered
  timber; gold replaces painted brackets.
- **Accent, about 10 percent: woven-cloud textiles and drifting gold.** Awnings,
  sails, wind harps, nectar bowls and tripods: the moving, living layer.
- **Palette:** 60 percent quartz white and cloud white, 30 percent pale sky
  pastels on woven cloud and Tempestar clothing (the prototype's sky blue,
  dawn pink, gold dawn, lavender, mint and peach), 10 percent gold.
- **Hierarchy:** podium height and the width of the floating gap between
  columns and roof show rank. Aethra's Hall of Mist stands highest and has
  the kingdom's only double floating eave. Ordinary residences are small
  tholoi or moored rooms.
- **Exclusions:** no copied real temple, shrine or sacred emblem; no altars,
  statues of gods or worship spaces; no Buddhist imagery from the legend's
  sealing (here the courts themselves sealed him); no heavy masonry walls; no solid gold
  buildings; no ordinary pitched timber roofs; no chimneys (there is no
  cooking fire: ambrosia bakes in sunlight).

### Each court's character within the shared language

| Court | Signature building | Character |
|---|---|---|
| Aethra | the Hall of Mist: audience hall on a triple quartz podium behind its own gate, double eaves floating highest | formal, axial, a little empty |
| Chrysa | open gold forge under a storm-dark cloud crown | the only working court; scorched gold, glowing, cluttered |
| Lyria | small odeon with wind harps between columns | musical, intimate, half-empty seats |
| Koinon | the Hall of Assembly: a ring of galleries around an empty central opening through the cloud to the world below, the gold sealing decree on its walls; observatory | grand and vacant; the void is the hall |
| Pantao | the Peach Garden and the banquet hall of the Peach Banquet, with floating couches; peach trees above and below the cloud | lavish, warm, overflowing |
| Dromos | racing ring around the cloud's rim, judges' tholos, prize pavilion | open, athletic, bright |

## 7. Exchange with the hero

Nobody in the kingdom is a merchant. Tempestars have everything they need and
no wish to work, and Tokoins mean nothing to them. Trade happens in the ways a
bored, proud, leisured people actually part with things:

- **Curiosities from below.** Novelty is the one thing the courts lack. Each
  court will exchange its own goods for things from the ground world that suit
  its taste, presented through the shared transaction interface as a swap
  rather than a sale:
  - Pantao wants foods it has never tasted (rye bread, cheese,
    dried berries, smoked fish, lake clams) and gives nectar, ambrosia and,
    rarely, a golden peach;
  - Koinon wants old, unexplained objects (the kind Aldren Vey deals
    in) and gives gold-leaf verse and star charts;
  - Chrysa wants metals and minerals it has never worked, such as
    Fire Kingdom ores, and gives small gold pieces;
  - Lyria wants news and stories of the world below, delivered in
    conversation, and gives woven-cloud goods.
- **Prizes.** Dromos's races and Lyria's contests award gold
  rings, wreaths of woven cloud and the occasional rarer object to whoever
  wins, the hero included.
- **The open table.** What Pantao's banquets leave over is set out
  on gold tripods for anyone to take. It is the kingdom's only free food, and
  a quiet boast.
- **Gifts of favour.** A ruler pleased or flattered gives a gift, and a
  courtier sent with one is the closest thing the kingdom has to a delivery.

What these items do for the hero (healing, restoring melted blorbs, equipment)
is still open.

## 8. Settlement structure (pre-layout)

- **Arrival:** the town staircase tops out at the Air Gem landing, which becomes
  the forecourt of the **Dawn Gate**, the kingdom's arrival gate after the
  Southern Heavenly Gate. Its keepers are long gone; the gate stands open.
- **Hierarchy of clouds:** Aethra is the nearest large court, visible through
  the gate. The other five courts are arranged around it at varying heights and
  distances so each looks toward or away from the others in a way that says
  something about their relationship. Koinon stands at the
  geometric centre of the group, which is why its empty hall matters.
- **Between the clouds:** open sky. Tempestars float across it on their own
  cloud bodies, and the hero flies, having already used the Air Gem to reach
  this height. There are no bridges; the gaps can be generous, and each court's
  separateness should read from a distance.
- **Inside each court:** a threshold gateway, a forecourt, the signature
  building, residences as small tholoi or moored rooms, an east-facing nectar
  terrace, and the court's characteristic outdoor room (forge yard, odeon,
  orchard, racing ring, empty hall).
- **Island sizes:** the six courts need more ground than the prototype's 30 m
  satellites provide. The layout pass should size each cloud from its program.

## Fixed, proposed and open

**Fixed (from the world bible, the prototype and direction):** Bird Helm gate
and the town staircase entrance; the hero flies here, having used the Air Gem;
Tempestars float between clouds, so there are no bridges; Tempestars age and
have children over very long lives; nobody is a merchant; plants are rooted in
cloud and rendered in cloud material; islands as ordinary clouds at the ordinary altitude;
Tempestar bodies with a humanoid upper half and a cloud vortex below; the six
existing names and their courts; many small rulers and no single monarch;
quartz, gold and pastel; the missing Air blorbs as the central quest.

**Proposed in this brief:**

- the Tempestars as a leisured people out of phase with ordinary sight, with
  cloud lower bodies;
- the cuisine: dawn nectar on gold, ambrosia baked in sunlight, golden
  peaches, self-moving golden tripods;
- Sun Wu Kong's history with the courts: the Monkey King of the Primate
  Kingdom's jungle, the empty title,
  the Peach Banquet and the sealing as the Hall of Assembly's last act;
- Greco-Roman classical as the primary style, with the Chinese celestial palace
  a strong second where Sun Wu Kong's story is set;
- the census of twenty-one in six courts, including the two new courts,
  thirteen new adults and two children;
- the empty Hall of Assembly on Koinon;
- the cloud-rooted flora;
- exchange through curiosities, prizes, the open table and gifts, with no
  merchants and no Tokoins;
- the cloud, gold and quartz material system and its gameplay rules;
- the architectural charter, the Dawn Gate and the per-court signature
  buildings;
- replacing runtime-resolved island placement with an authored layout.

**Open:**

- What Tempestar food and gifts do for the hero.
- How much of the Sun Wu Kong history is quest content, and how the courts'
  anger shows when he travels in the party.
- Whether the courts ever admit they were wrong to blame him for the Air
  blorbs.
- Whether Sun Wu Kong returns to rule the Primate Kingdom's monkeys, and
  whether his absence had any part in the kingdom falling under the curse.
