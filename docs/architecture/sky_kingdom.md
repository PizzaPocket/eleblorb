# Sky Kingdom: Courts of the Clouds

Status: concept brief, second pass, in review (2026-10-06). It replaces the
first-pass prototype's loose cluster of pavilions with a planned celestial
society, census, material system and architectural charter. No layout
coordinates are fixed yet; those follow approval of this brief.

## 1. What exists now

`scripts/sky_kingdom.gd` builds a prototype that the world bible calls a
deliberate first pass:

- four cloud islands: **Highcloud** (radius 46 m) and three satellites, the
  **Anvil Cloud**, the **Drift Cloud** and the **Hollow Cloud** (radius 30 m);
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
human world's images of a heaven above the clouds:

- **Greek Olympus:** a court of immortals on a summit veiled in cloud, its
  gates of cloud kept by the Horai, feasts of nectar and ambrosia, Hephaestus's
  golden attendants and the self-moving golden tripods that wheeled themselves
  to the gods' assembly and back, the Muses' music, contests and games.
- **Roman heaven and civic religion:** colonnades, the council in the round,
  the triclinium banquet with diners reclining on couches, the eternal hearth.
- **The Chinese Celestial Court:** the Jade Emperor's palace beyond the Southern
  Heavenly Gate, its many offices and titles, the Queen Mother of the West's
  orchard of peaches that ripen once in an age, the Weaver Girl who wove the
  coloured clouds, the Heavenly River, and the bridge of birds that once a year
  spans it.

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

### Why the courts drifted apart (proposed)

Wild Air blorbs once gathered in long drifting chains between the clouds,
the way the birds of the Chinese legend form a bridge across the Heavenly
River. Tempestars float on their own cloud bodies and never valued the bridges
much. Ordinary travellers, guests and tripods carrying feasts depended on them.
When the Demon King vaporised the Air blorbs into the clouds, the bridges went
with them. Visits stopped and banquets went unshared. The great Hall of
Assembly on the Hollow Cloud emptied, and pride turned the separation into
policy.

Restoring the Air blorbs therefore restores the bridges. That gives the
established central quest a civic result: the courts can meet again. Whether
they choose to is the second half of the story.

## 3. Community

The census is **nineteen Tempestars in six courts**: the four existing courts
with added members, and two new courts. Each court is a household-like group
around one ruler, and each corresponds to an office of the mythic heavenly
courts. Duties that were once one shared government are now split among rival
courts that rarely speak.

Names follow the existing convention: a weather word followed by a compound
surname.

### Highcloud: the court of state (capital, tallest)

The Olympian or Jade Emperor's throne room, reduced to one cloud.

- **Cumulus Highvane** (existing), ruler. Holds the tallest crown and gives
  audiences that nobody else attends. Proud of precedence; quietly misses the
  company the updrafts used to bring.
- **Squall Windrider** (existing), chamberlain and keeper of ledgers. Records
  titles, precedence and every slight between courts. Keeps the ruler's robes
  from blowing off the edge.
- **Breeze Suncrest** (existing), herald. The youngest at Highcloud and the only
  Tempestar who still floats between clouds carrying invitations and news,
  like Hermes or Iris. Chased Air blorbs as a child.
- **Dew Brightcup**, cupbearer. Sets the gold dew bowls out before dawn and
  gathers the nectar for Highcloud's table. Knows precisely how much each court
  drinks, which makes Dew the court's best source of gossip.

### The Anvil Cloud: the court of craft and weather

Hephaestus's forge and the thunderhead's anvil top.

- **Nimbus Greywisp** (existing), ruler and goldsmith. The only court that
  makes things: gold pins, tripods, bowls and the anchors every building in
  the kingdom depends on. Resents that the other courts treat this as a service
  owed to them.
- **Virga Brightanvil**, apprentice goldsmith. Brilliant at beginning pieces and
  rarely finishes one, as the rain that evaporates before it lands.
- **Graupel Stonebrow**, weather-shaper. Herds storm cloud for the forge's heat
  and light and keeps the Anvil's own weather.

### The Drift Cloud: the court of music and verse

The Muses' choir in a court of three.

- **Gale Stormwick** (existing), ruler and poet. Feels the crown as an exile and
  would trade it for a neighbour.
- **Zephyr Lyremantle**, musician. Plays wind harps strung between the
  colonnade's columns. Rehearses for audiences that have stopped coming.
- **Haze Softquill**, keeper of songs. Holds the kingdom's verse in memory and
  on gold leaf.

### The Hollow Cloud: the court of learning and the empty hall

The council of the heavens, now a scholar's observatory beside an empty
assembly.

- **Cirro Ashveil** (existing), ruler and philosopher. The "hollow" is the vacant
  Hall of Assembly at the cloud's centre, where all the courts once met. Cirro
  thinks it is waiting to be filled.
- **Alto Starmantle**, stargazer. Keeps the observatory and the calendar of
  seasons, as the Horai once kept heaven's gates.
- **Mist Pallwhisper**, archivist. Tends the empty hall and the decisions
  inscribed in gold around it, the last of them very old.

### The Orchard Cloud (new): the court of the feast

The Queen Mother of the West's peach garden and the golden fruit of the
Hesperides.

- **Iris Dawnbloom**, ruler and hostess. Holds the most lavish banquets in the
  kingdom, partly to outshine Highcloud. The guest list is a weapon.
- **Mellow Honeymantle**, master of the table. Composes the kingdom's cuisine:
  ambrosia, nectar wines, peach dishes, sky-fruit, and the order of courses.
- **Rime Sweetbough**, orchard keeper. Tends the cloud-rooted peach and fruit
  trees, and is the one who knows which peach is truly first.

### The Ring Cloud (new): the court of games

Olympian contests and the hippodrome.

- **Corona Fairwind**, ruler and judge of contests. Presides over races and
  games around a ring-shaped cloud, and keeps the record of every victory.
- **Scud Quickwhirl**, racer. Young, fast and bored, and the court's champion
  because there is hardly anyone left to race.
- **Flurry Brightring**, keeper of the course and the prizes: gold rings,
  wreaths of woven cloud, laurels from the Orchard Cloud when the two courts
  are speaking.

### Responsibility map

| Need | Who | Where |
|---|---|---|
| Ceremony, precedence, records of rank | Cumulus, Squall | Highcloud |
| News and invitations between clouds | Breeze | everywhere |
| Nectar | Dew (Highcloud); each court sets its own bowls | east terraces |
| Ambrosia, fruit, banquets | Mellow, Rime, Iris | Orchard Cloud |
| Gold: anchors, pins, vessels, tripods | Nimbus, Virga | Anvil Cloud |
| Weather and cloud-shaping | Graupel; every Tempestar a little | Anvil Cloud |
| Music and verse | Zephyr, Haze, Gale | Drift Cloud |
| Calendar, seasons, stars | Alto | Hollow Cloud |
| Shared law and archives | Mist, Cirro | Hollow Cloud hall |
| Games and contests | Corona, Scud, Flurry | Ring Cloud |

There is no labour of survival anywhere in this table. Everything listed is
either pleasure or a duty that only matters because other courts exist, which
is why so much of it has lapsed.

### Governance

Each court is sovereign over its own cloud and nothing else. The Hall of
Assembly on the Hollow Cloud is where shared decisions were once made; no
court has called it in living memory. Contact now runs through Breeze's
invitations, Dew's gossip and banquets that are as much contests as meals.
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

## 5. Architectural charter (draft)

- **Primary, about 70 percent: Greco-Roman celestial classical.** Peristyle
  courts, round tholos pavilions, colonnades and exedrae, porches with
  pediments reduced to soft SuperEgg forms, an odeon for music, a hippodrome
  ring, triclinium banquet halls with floating couches. Quartz shafts, gold
  capitals and bases, floating roofs.
- **Secondary, about 25 percent: Chinese celestial court.** Limited to named
  elements: the kingdom's arrival gate (after the Southern Heavenly Gate), pailou
  gateways at each court's threshold, sweeping eave lines on the Orchard
  Cloud's banquet hall and Highcloud's throne hall, moon gates of set cloud, and
  the peach orchard's layout.
- **Accent, about 5 percent: woven-cloud textiles and drifting gold.** Awnings,
  sails, wind harps, nectar bowls and tripods: the moving, living layer.
- **Palette:** 60 percent quartz white and cloud white, 30 percent pale sky
  pastels on woven cloud and Tempestar clothing (the prototype's sky blue,
  dawn pink, gold dawn, lavender, mint and peach), 10 percent gold.
- **Hierarchy:** height and the width of the floating gap show rank. Highcloud
  stands tallest and its throne hall's roof floats highest. Ordinary residences
  are small tholoi or moored rooms.
- **Exclusions:** no copied real temple, shrine or sacred emblem; no altars,
  statues of gods or worship spaces; no heavy masonry walls; no solid gold
  buildings; no ordinary pitched timber roofs; no chimneys (there is no
  cooking fire: ambrosia bakes in sunlight).

### Each court's character within the shared language

| Court | Signature building | Character |
|---|---|---|
| Highcloud | throne hall on a stepped quartz podium, roof floating highest | formal, axial, a little empty |
| Anvil Cloud | open gold forge under a storm-dark cloud crown | the only working court; scorched gold, glowing, cluttered |
| Drift Cloud | small odeon with wind harps between columns | musical, intimate, half-empty seats |
| Hollow Cloud | ring colonnade around an empty central opening through the cloud to the world below; observatory | grand and vacant; the void is the hall |
| Orchard Cloud | banquet hall with floating couches; peach trees above and below the cloud | lavish, warm, overflowing |
| Ring Cloud | racing ring around the cloud's rim, judges' tholos, prize pavilion | open, athletic, bright |

## 6. Settlement structure (pre-layout)

- **Arrival:** the town staircase tops out at the Air Gem landing, which becomes
  the forecourt of the **Dawn Gate**, the kingdom's arrival gate after the
  Southern Heavenly Gate. Its keepers are long gone; the gate stands open.
- **Hierarchy of clouds:** Highcloud is the nearest large court, visible through
  the gate. The other five courts are arranged around it at varying heights and
  distances so each looks toward or away from the others in a way that says
  something about their relationship. The Hollow Cloud stands at the
  geometric centre of the group, which is why its empty hall matters.
- **Between the clouds:** today, gaps that only Tempestars cross easily. After
  the Air blorbs return, their chains form the bridges.
- **Inside each court:** a threshold gateway, a forecourt, the signature
  building, residences as small tholoi or moored rooms, an east-facing nectar
  terrace, and the court's characteristic outdoor room (forge yard, odeon,
  orchard, racing ring, empty hall).
- **Island sizes:** the six courts need more ground than the prototype's 30 m
  satellites provide. The layout pass should size each cloud from its program.

## Fixed, proposed and open

**Fixed (from the world bible and prototype):** Bird Helm gate and the town
staircase entrance; islands as ordinary clouds at the ordinary altitude;
Tempestar bodies with a humanoid upper half and a cloud vortex below; the six
existing names and their courts; many small rulers and no single monarch;
quartz, gold and pastel; the missing Air blorbs as the central quest.

**Proposed in this brief:**

- the Tempestars as a leisured people out of phase with ordinary sight, with
  cloud lower bodies;
- the cuisine: dawn nectar on gold, ambrosia baked in sunlight, golden
  peaches, self-moving golden tripods;
- the census of nineteen in six courts, including the two new courts and
  thirteen new names;
- the Air blorbs as the old bridges between clouds, and the empty Hall of
  Assembly on the Hollow Cloud;
- the cloud, gold and quartz material system and its gameplay rules;
- the architectural charter, the Dawn Gate and the per-court signature
  buildings;
- replacing runtime-resolved island placement with an authored layout.

**Open:**

- How the hero crosses between clouds before the Air blorbs return: drifting
  stepping clouds Breeze shepherds, wingsuit and hover routes, or one court
  reachable at first with the rest opening later.
- Whether Tempestars age and have children. This brief leaves no children in
  the census and treats Breeze, Virga and Scud as the young.
- Whether any court trades or sells to the hero, and what: nectar, ambrosia or
  golden peaches as food items; gold work from the Anvil Cloud.
- Whether the hero can eat Tempestar food, and what it does.
- How Sun Wu Kong, who once kept the Celestial Court's stables in legend and
  rides his own cloud, relates to the Tempestars, if at all.
- The second half of the quest: whether the courts choose to meet again once
  the bridges return.
