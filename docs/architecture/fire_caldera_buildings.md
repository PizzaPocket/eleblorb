# Fire Caldera City: Architecture Briefs

Status: approved by the user (2026-10-07); written 2026-10-06, audited against the
architecture skill's brief audit on 2026-10-07 (sizes, sections, access and
pass-throughs, frames, headroom, ramps). Foundations come from the plot survey
(`FireCalderaGround.survey()`, socketed plinths in `SocketPlinth`). Read with
`fire_caldera_city.md` (people, physiology, charter, interiors in principle)
and `fire_caldera_layout.md` (approved layout: plots, routes, lower city,
foundations). Plot ids, centres, footprints and routes come from the layout,
in its local frame (`+Y` from the gate into the city, `+X` to the visitor's
right, origin at the reservoir's centre). Every building must stay inside its
reserved plot, canopies and terraces included.

## 1. Kit of parts

The charter (volcanic modernism about 75 percent, Gaudí-informed metal and
glass craft about 20 percent, living volcanic light about 5 percent) applies
unchanged. These are its invariants in buildable terms.

| Element | Specification |
|---|---|
| Frame | **exposed structural steel** (revised 2026-10-07): squarish SuperEgg columns, I-section and box beams, portal frames and trusses in heat-blued or blackened steel, welded joints left visible; the frame carries roofs and glass |
| Glass | **full glass panels**: each wall bay between blued-steel posts is either one full-height glass panel (floor channel to transom, no sill, no punched window) or a continuous stone panel; above the transom runs the building's two-tone stained clerestory band, round the outside and through its partitions |
| Shell | continuous asymmetric SuperEgg shells and extruded superellipse plans in **cast basalt composite**, matte charcoal, for plinths, heat walls round hot work, and the curved landmark volumes (Civic, Renewal canopy base); never a box with a lid |
| Foundation | a **cut-and-fill cast-basalt platform** on the same superellipse plan: embedded footing and exposed downhill base, uphill ground cut back beyond the usable apron, one unobstructed finished floor with no enclosing lip; a recessed metal control joint between base and shell |
| Storey | 3.5 m floor to floor; public halls 5 to 7 m |
| Glazing | broad superellipse panes, clear, smoky or faintly warm, in blackened-steel frames; every occupied room has one strong outlook; glass never runs below grade |
| Stained glass | abstract mineral and molten-flow patterns only; clear or smoky glass plus **two** stained colours per building, **three** for landmarks (see the matrix) |
| Forged metal | blackened iron and dark steel, branching like cooled lava veins, for the structure that holds glass, canopies, rails and bridges; heat-blued and enamelled accents; bright steel only on instruments and controls; gold and silver only as thin inlays on cool surfaces |
| Roofs | restrained low-pitch slabs, shallow walkable shells and folded or catenary canopies with integrated ash gutters to concealed downpipes; glass SuperEgg shells may be clipped and fitted over matching roof apertures as skylights; no gables, no pediments |
| Doors | broad superellipse openings, at least 2.0 m clear on public routes, with pivoting or sliding metal-and-glass leaves; public thresholds 3 m or more; front and interior doors alike are a superellipse cut in their stone panel with a piped stainless frame of the same outline (`CalderaShell.door_opening`); Oren's compact secure gem store uses a 1.6 m surface slider rather than spending its lobby on a swing arc |
| Thermal services | concealed in walls and floors; visible only as **service manifolds**, **inspection hatches** (on service terraces, never in a walkway), **glowing seams** and **temperature controls** where someone uses them |
| Thermal room types | **immersion well** (a shallow lava pool fed by the duct network, 2 to 3 m across, with a cool perimeter ledge for tools and adornments); **radiant platform** (a hot basalt slab to lie on); **molten-floor room** (the whole floor a thin molten layer, for deep rejuvenation) |
| Light | **architectural, not fittings** (revised 2026-10-07): concealed LED coves on the transom bar washing up through the stained band, LED lines under counters, sideboards and shelf edges and behind bed heads and mirrors, a few real lights hidden at cove height; no visible lamps or brackets. Set against that, **open flame and lava light** in the working and thermal buildings, plus the arrival beacons, path capsules and mineral lenses below the lava |
| Ventilation | every dwelling and workshop has a gas vent stack and a pressure-relief path, venting outward and uphill toward the west and far shelves |
| Glazed fronts and doors | bays of about 2 m between posts, one panel per bay; never a superellipse cut-out window or a domestic window grid; a door has at least 2.0 m clear, its own bay, and a stone lintel to the transom so no glass rests on its frame; interior doors keep 0.6 m of stone between their head and the stained glass above |
| Headroom | every canopy, bridge roof, gallery or upper floor a route passes under clears 2.4 m; public halls are taller by program, not by accident |
| Vertical circulation | ramps, never stairs: 32 degrees at most, 1.4 m wide (2.0 m on public routes), a 1.2 m landing at foot and head; one storey of 3.5 m needs about 5.6 m of run, so about 8 m with landings. Every upper floor names its ramp or lift in its brief |
| Furniture and textiles | **no wood anywhere**: a lava person would burn it by touching it (`CalderaFurniture`). Cast basalt and stone, blued and stainless steel, glass. Textiles follow real heat-proof cloth: basalt fibre (bronze-gold, used for fire blankets) for guest bedding and mats, silica cloth (to about 1000 °C) for mattresses and anything a lava person touches, mineral-coated glass-fibre cloth for coloured upholstery, ceramic fibre (about 1260 °C) for the hottest work, stainless mesh for drapery; never asbestos or aramid |
| SuperEgg language | roofs, floor slabs, landings and canopies are soft SuperEgg slabs, squarish but rounded at every edge and corner, overhanging their walls a little; `CalderaShell.soft_epsilon` picks the lowest exponent whose corners still cover the walls beneath (`soft_slab`, and the shell's roof). Where two visible SuperEgg slabs join, both extend through and are clipped at one shared plane and section datum so their complete cut profiles are identical: height, width and both side-edge endpoints meet on one exact line. Equal maximum widths are insufficient because each rounded solid narrows at its own cut position. Hard boxes only for hidden fills and continuous wall or floor planes where a rounded edge would leave a gap |
| Against lava | nothing of steel or iron touches lava; whatever stands in or contains it is refractory: dark magnesia-chrome on the quays and in the ghat, pale forsterite where a pale interior wants it (Nahl's lava bed); metal near it bears on refractory shoes |
| Collision | shells, plinths, terraces, rails, bridges, counters and instruments solid; molten wells and floors use the hazard and liquid API; sparks and seams decorative |

### A culture of original buildings (2026-10-07)

The lava people treat every structure as a chance to express themselves.
Their city holds together through its shared ground (the socket plinth, the
superellipse door, the city's materials and crafts: cast basalt, steel and
forged iron, poured and fused glass) and through their heat culture, not
through a repeated motif. Each household and institution invents its own use
of these, and a stranger should be able to tell who built what from a single
facade. When designing a building here, look for an original idea grounded
in its program and its makers' craft, drawing on the full range of modern
coloured glass (cast glass bricks, dichroic SuperEgg lenses, fused and slumped panels,
graded and fritted glass, lenses, mosaics), and never copy another
building's signature.

### The guest house's signature

**The forked post and the stained band** (restored 2026-10-07 from the first
iteration, at the user's walkthrough) belong to the guest house alone. Every
post meets the transom with a forged fork, two short branches like a vein of
cooled lava splitting, and above the transom runs a two-tone stained band in
its colours. The entry sculpture uses the same steel and the same two glass
colours. Full glass panels, never subdivided, fill the bays below.
`CalderaShell` builds it by default; other buildings pass `"transom": false`.

### Oren's glass (2026-10-07)

A gem dealer's front, made by pouring. The shop's front is a wall of
hand-cast solid glass bricks (after MVRDV's Crystal Houses), each a little
different, clear at eye level and deepening toward amethyst at the top like
the colour zoning in a geode, teal over the assay room; larger cast blocks set
into it are the display cells, each holding one lit stone. The home above
looks out through clear glass behind a two-row screen of broad, shallow,
squarish dichroic glass SuperEggs whose colour turns teal, violet and gold with
the angle, like labradorite or opal.

### Families by program (2026-10-07)

Buildings differ by what they are for, and the kit has two families:

- **Commercial and public: the glass pavilion** (the guest house, Oren).
  Sleek, inviting people to look in and out: glass on a blued-steel frame, a
  dark basalt plinth, concealed LED light; each building its own glass (the
  guest house's stained band, Oren's cast bricks and dichroic SuperEgg screen).
- **Care and restoration: the tuff house** (Nahl first). Soothing and light
  rather than sleek: thick walls of pale cream tuff with a few deep
  superellipse openings, floors of white hot-spring sinter, pumice caps and
  sills, pale roofs; no stained band and no amber or cobalt. Its accents are
  the caldera's soft minerals (pale olivine, sulphur cream, rose rhyolite) and
  trencadis of broken mineral tile. Its character is hand-forged ironwork:
  branching window grilles, clerestory tracery, screens and branching
  columns. Lava is the only strong colour. Openings here are punched windows,
  so the "never a superellipse cut-out window" rule applies to the pavilion
  family only.

Both share the plinth, the superellipse door, the forged-iron vocabulary and
the raked clerestory roof where a tall room wants daylight.

### Exclusions

From the charter: classical columns and pediments, timber gables, shutters,
textile awnings, ordinary beds and fireplaces in lava homes, flower beds,
open-bowl braziers, fake exposed pipes, decorative lava containers with no use;
Christian, Catalan or classical symbols; copied Gaudí buildings.

## 2. Arrival and public works

### Arrival forecourt and pylons (`ARRIVAL`, `(0, -46)`)

> **Superseded by the built public-realm revision (2026-10-09).** The original
> inner forecourt and paired flame pylons below are retained as design history.
> The actual threshold is the full-scale multicolour Tempering Gate on the
> crater lip at local `(0, -112)`, joined to the Highline by its curved arrival
> gallery. It keeps the clear passage and wayfinding purpose without adding a
> second ceremonial gate inside the city.

- **Forecourt:** open 16 × 14 m of fitted basalt paving within a 24 × 20 m
  plot, the `R0` axis held 6 m clear through it. It splits visibly west (`R3`
  to the guest house and Nahl) and east (`R4` to Oren and Kel), with the view
  straight on across the reservoir to `CIVIC`.
- **Pylons:** two forged-metal-and-glass pylons, about 11 m tall, rising from
  basalt sockets either side of the axis, their branches curving inward to frame
  a superellipse of open air **6 m wide** at the base. They are related but not
  mirrored: the west pylon's branches split twice, the east pylon's three times.
- **Glass:** amber and cobalt panes fused between the branches, catching
  daylight from above and lava light from below.
- **Beacons:** one slim vertical flame in a glass cell in each pylon, fed from
  the service network.
- **Seam:** a low glowing seam crosses the paving between the pylons.
- **Party pad:** a dry gathering terrace 8 × 6 m on the forecourt's west side,
  clear of the axis, where party members who cannot enter lava wait.

### Kel–Vara cove bridge

> **Superseded by the built Highline (2026-10-09).** Kel and Vara now connect
> through the shared annular public route and their authored docks; a second
> dry bridge across the cove would duplicate that network and cut the natural
> bowl. The original brief below is retained as design history.

- A single short span across the narrow eastern cove between `KEL` and `VARA`,
  4 m wide, about 14 m long.
- A shallow catenary of forged steel ribs carrying a cast-basalt deck, with
  branching balustrades and amber glass panels between them.
- The deck is cooled and insulated over the lava. It is the city's only dry
  bridge and stays clear of the arrival sightline.

## 3. Hospitality and care

### Guest house (`GUEST`, `(-27, -51)`; Eris Nahl; rest point, 25 Tokoins)

The only building in the city designed for cool bodies.

- **Mass:** a 15.5 × 12 m glass pavilion on a socket plinth, its glazed long
  side facing the forecourt, a shallow dry terrace in front, within the 17 ×
  14 m plot. Blued-steel posts on a 2 m bay, full glass panels or stone in
  each bay, a cobalt and amber clerestory band, a 2-degree metal roof slab
  with fitted glass SuperEgg skylights. No thermal services beneath; the
  floor is cooled; no open fire.
- **Rooms** (revised after the third walkthrough, 2026-10-07: each room fitted
  to its use rather than four copies):

| Room | Size | Description |
|---|---|---|
| Receiving lounge | 15.5 × 5.75 m | the door from the forecourt; Eris's counter facing arrivals; cool stone bench; visitor table; six full glass panels onto the forecourt and the largest clear skylight |
| Keeper's room | 3 × 6.25 m | Eris's working room behind her counter: the sealed provisions wall (imported food and water), her desk at one tall glass slot with the guest ledger in thin cast plates, hooks for travellers' gear; stone, no skylight |
| Rim room | 5 × 6.25 m | the larger guest room: two beds for the party, heads to the lounge wall, feet toward full rear glass and the crater rim; a cool stone ledge; amber band and amber-tinted dome (warm light); the wake marker |
| Washroom | 3.5 × 6.25 m | the lava people's way with water and heat (below); stone walls, a small frosted dome |
| Lake room | 4 × 6.25 m | one bed along the east glass toward the reservoir's glow; a reading chair; cobalt band and cobalt-tinted dome (cool light) |

- **Washroom, culturally specific.** To the lava people water is an imported
  curiosity and heat is how anything is disposed of:
  - the sealed water supply is a squared glass cylinder between steel bands,
    displayed like a specimen;
  - the shower drains into an **evaporation channel**: a stainless grille over
    a glowing heat seam where spent water flashes to steam;
  - the **incinerating toilet** stands in a basalt plinth with a small amber
    inspection port onto its heat, and a vent stack to the roof;
  - a gently warmed **radiant stone bench** dries a bather instead of towels
    (the city's radiant-platform room type, at a cool body's temperature);
  - the basin is a carved basalt bowl; the mirror is polished obsidian.
- **Partitions:** stone to 3.0 m, each door a superellipse opening with a
  piped frame and a 0.6 m stone lintel, then stained glass to the roof in the
  room's colour.
- **Colour rule** (2026-10-07): amber is welcome and warmth, cobalt is cooling
  and water, and each band takes the colour of the room behind it. The west
  half (keeper's room, rim room) is amber and the east half (washroom, lake
  room) cobalt. A divider between a warm and a cool room takes the warm
  side's amber, so the rim room is amber all round; only the wall between
  the washroom and lake room is cobalt. The front band reads amber at the door, interleaves over the
  dining table, then turns cobalt toward the lake end, so the building warms
  you in and cools toward the water.
- **Skylights at full reach:** each dome fills its room's share of the roof:
  a long clear dome over the whole hall, amber over the keeper's and rim
  rooms, frosted over the washroom, cobalt over the lake room.
- **Hall program** (hospitality, west to east): arrival bench and pack rack
  beside the door; Eris's counter facing arrivals with water and the ledger
  plates; a provisions sideboard under the hall's art, a basalt relief of the
  caldera with the reservoir as a glowing seam; a stone table with six chairs
  at the glass; a rest corner of two armchairs and a low table at the cool
  end.
- **Art, one piece per room**, made by the city's own craftsmen. The hall's
  is a commission from the Vara studio: Omi's kiln-formed glass, hung frameless
  on Talen's concealed steel pins, the caldera in section as fused strata from
  basalt black through cooling reds to amber and smoke, their boundaries
  flowing as slumped glass does, with the reservoir as a flat cobalt lens
  edged in stainless. Three small studies for it hang on the hall's free wall lengths,
  following the colour rule: amber by the door, mixed by the table, cobalt
  at the rest corner. The rooms: three mineral discs,
  gifts from the city (keeper's room); a forged skyline of the rim set with
  amber glass (rim room); a cobalt glass ripple roundel (lake room); a panel of
  banded vent crust (washroom).
- **Furniture placement:** beds head to a solid wall, feet toward the glass,
  each with a chest at its foot, back to the bed; the lake room's armchair
  faces the water; nothing stands in a door's clear zone.
- **Pass-throughs:** none. All four rooms open from the lounge; the keeper's
  room opens behind Eris's counter.
- **Glass:** clear panels to the forecourt and lounge sides; warm-tinted panels
  in the rim room, cool-tinted in the lake room; cobalt (cooling) and amber
  (welcome) in the band, the partitions and the entry fin.
- **Variation:** the only cool building; the only beds and the only imported
  food in the city.

### Nahl tempering hall and Eris's suite (`NAHL`, `(-38, -28)`)

**As built (first pass, 2026-10-07; the tuff-house family).** A tempering
hall under a roof raked up toward the promenade, its wedge of clerestory glass
behind iron tracery, carried inside by two branching iron columns; the
molten-floor bay behind forged screens, three radiant platforms, the mineral
cabinet and two glass-enclosed flames. The wing was swapped after the survey:
the ground along its back and east sides stands 0.5 to 1.2 m above the floor,
so **Eris's suite takes the front**, with its own door at the east end where
R3 meets the promenade (immersion well, cooler resting niche, obsidian
shaping glass, keepsake shelves), and **the mediation room sits behind** as a
conversation pit dug 0.5 m into the plinth on the uphill side, its bench clad
in trencadis with pale olivine cushions, an LED line under its lip and a pale
dome for its only window. The plan's pit data cuts the plinth, drops the
hidden ground below it and sets the height query. Its heart is heated stone: a low
sinter slab, not lava. Eris rests in a
**lava bed**, between a bed and a bath: a raised superellipse of cast
forsterite (the refractory made from olivine) with a deep superellipse hollow
that lava fills from a duct beneath, head to the party wall, a ceramic-fibre
mat beside it. The alcove holds a day couch under silica cloth with a
basalt-fibre throw. The house has no stainless steel: its metal is wrought
iron (a silvered glass in an iron frame for shaping, iron dials, iron shelf
rails), its textiles undyed heat-proof cloth (silica, ceramic fibre,
weathered basalt fibre), kept pale and low in contrast.


- **Mass:** a 16 × 12 m shell on a stepped podium. Its public face looks onto
  the promenade (`R1`); a separate guest-side approach runs from `R3`. The hall
  and the suite are two volumes under one folded roof, joined by a short
  glazed link.
- **Rooms:**

| Room | Size | Description |
|---|---|---|
| Tempering hall | 10 × 12 m, 6 m high | three radiant platforms for cooled or cracked residents; one molten-floor bay screened by forged panels for deep treatment; a mineral cabinet of corrective samples; Eris's work stool; daylight from a long clerestory |
| Mediation room | 6 × 5 m | a ring of warm basalt seats for disagreements that have become personal; one window onto the reservoir |
| Eris's suite | 6 × 7 m | its own outside door from `R3` into a 1.5 m entry, then a receiving and shaping room, a private immersion well, a cooler resting niche, her shelf of objects from seventy years; a staff door to the hall's link |

- **Glass:** amber and cobalt (the guest house's family, for one household).
- **Link:** the suite connects toward the guest house only by Eris's own
  service door, so **a visitor never passes through treatment rooms to reach a
  bed**.
- **Audit (2026-10-07):**
  - **Sizes:** the 10 m hall plus a 6 m column (mediation 6 × 5 above the
    suite 6 × 7) make 16 × 12 m.
  - **Access, revised:** Eris's private suite was reached only through the
    treatment hall and its link, a home reached through a room patients use.
    The suite now has its own outside door from `R3`, and the link to the hall
    becomes her staff door.
  - **Pass-throughs:** the mediation room opens off the hall. Both are care
    rooms used the same way, which is legitimate.

### Renewal terrace (`RENEWAL`, `(-43, -4)`; landmark)

The surface of the communal renewal chamber (`L0`) and the first immersion
shelf.

- **Form:** a broad basalt terrace 18 × 14 m stepping down to the reservoir.
  Over it rises a catenary canopy on branching forged supports, open on the
  reservoir side.
- **Parts:**
  - tiers of warm basalt seating facing the water;
  - the **immersion shelf**: a wide shallow ramp of cooled basalt sinking into
    the lava toward `L0`, the gentlest and most social way below;
  - a ring of cast-basalt memory sculptures (casts recording people and
    shared decisions);
  - glass windbreak screens on the landward side.
- **Glass:** amber, garnet and teal: a landmark's three, in the canopy's
  inset panels, throwing coloured light on the seats.
- **Links:** linked to Nahl and Aro along `R6` without passing through either
  home.
- **As built, its own idea: a catenary canopy of slumped glass** (2026-10-07).
  The lava people hang molten glass over chains and let it settle into its
  own curve, so the roof is drawn by heat and gravity: forged iron ribs on the
  same catenary (17 m span, 6.2 m crown) on branching supports, the panels
  shading from teal at the springing through garnet to amber at the crown,
  with coloured light under it.
- **Revised 2026-10-08: the city's ghat.** The first revision piled up moves
  (a pool, a glass walkway, an inland channel and basin, flanking tiers) with
  no single purpose; the user asked for a rethink of use and flow. As on a
  river ghat, a broad flight of steps runs from the street down into the
  lava, and the steps are the use:
  1. **Arrival:** the promenade runs along a level landing at the top, flush
     with it (plan keys `quay`, `crossed`, `datum_at`).
  2. **The flight:** seven refractory steps between two arms. The dry upper
     steps are seats for resting, talking and watching; on the waterline step
     people sit half immersed together; the lower steps carry on under the
     lava as the immersion shelf. A cool-bodied player can sit on the dry
     steps; with the Lava Helm they walk on down.
  3. **The threshold arch:** dark refractory, half sunk at the foot of the
     central flight: the way down to the renewal chamber `L0` and the place
     of the coming-of-age descent.
  4. **The memory stones** stand along the landing's back facing the water,
     the backdrop to every gathering.
  5. **Eris's tempering slab** at the landing's east end under a veiled glass
     windbreak, for those too cracked or cooled to walk straight in.
  6. **The canopy** covers the whole ghat; its supports stand on the landing
     and the arms, never over lava, on refractory shoes.
- **Its own foundation** (`foundation_kind: "ghat"`), not a plinth: a U-shaped
  deck level with the promenade, cut to the plot's outline and open at the
  front to the flight, its walls running down into ground and lava; a
  retaining wall only where the ground behind stands higher; the ground cut
  away beneath (`sink`); each step a level for the height query.
- **Materials against lava:** nothing of steel or iron touches lava. What
  contains or stands in it (the steps, the arch, the shoes under the
  supports, the flight's side walls) is magnesia-chrome refractory, the
  near-black brick that lines furnaces against molten slag, so it reads as
  part of the basalt quay.

## 4. Exchange and craft

### Oren mineral house (`OREN`, `(30, -34)`; Pela and Savi)

- **Mass:** a two-storey shell 17 × 12 m. The ground floor is the business,
  with the home above under a walkable roof terrace.
- **Ground floor:**

| Room | Size | Description |
|---|---|---|
| Mineral counter | 7 × 5 m | faces the arrival crescent through a broad glazed front; separated display cells of gems and crystals; the counter |
| Assay room | 5 × 5 m | Pela's assay bench, hand lenses, a heat cell, sample trays; behind the counter |
| Secure gem store | 3 × 4 m | a vault with a forged door; story-gated gems kept apart |
| Preparation studio | 7 × 5 m | Savi's crushing, grading, heating, alloying, cooling and presentation stations, separated from untested ore by a wall |
| Receiving bay | 5 × 4 m | on the outer service loop (`R2`), Pela's way in with raw material, never through the counter |

- **Upper floor:** a receiving and shaping room, a shared immersion well, two
  resting niches, and the material pantry.
- **Plan (audited 2026-10-07).** The first brief listed the rooms without a
  plan, left the upper home with no way up, and could have reached the home
  only through the shop. As revised, the 17 × 12 m ground floor has three
  bands:
  1. **Front band, 5 m deep, facing the arrival crescent:**
     - the counter, 7 m;
     - the secure gem store, 3 × 3 m, between the counter and the assay room,
       with a 1.7 m clear lobby in front of its surface slider;
     - the assay room, 5 m;
     - a 2 m bay at the east end, the full 12 m depth, open to the air, which
      holds the home's ramp (see below).
  2. **A 2.0 m staff passage** across the width. It joins the assay room,
     the receiving bay and the preparation studio. Customers never enter it.
  3. **Back band, 5.6 m deep, facing `R2`:**
     - the preparation studio, 7 × 5.6 m, west;
     - a 3 m tested-stock store between the studio and the receiving bay;
     - the receiving bay, 5 × 5.6 m.

  Pela's route is receiving bay → corridor → assay room → gem store. Untested
  ore never enters the studio. Savi takes only assayed material from the
  passage. The assay, receiving and studio connections are framed open
  passages because their work route does not need three swing leaves; the
  tested-stock store keeps the one secure hinged door, opening into the store.
  The raised receiving bay uses a sectional overhead door parked beneath the
  ceiling, never one broad leaf swinging across its loading apron.
- **The way up:** an **open-air ramp** 2 m wide in the east bay, outside the
  shop's walls, climbs from the service side (`R2`) to the upper floor at
  +3.5 m: 5.6 m of run, with 1.2 m landings, inside the 12 m depth. The home therefore has its own door and
  is never reached through the shop.
- **Pass-throughs:** the gem store is reached only through the assay room and
  counter lobby, and the receiving bay leads through the corridor to the
  assay room. All are one workshop's own rooms, which is legitimate.
- **Glass:** see "Oren's glass": cast-glass bricks deepening to amethyst (teal
  over the assay room), cast display cells, and the original close-spaced
  vertical fin screen on the home. Each fin is a narrow, thin, squarish
  dichroic-glass SuperEgg slab with alternating cant—not a grid of thick blocks.
- **As built (2026-10-07):** split level as approved; the counter faces the
  shop door with a glass case of finished stones; the vault's strongbox; the
  assay lens, balance and heat cell; Savi's stations in working order along
  the studio's back wall (mortar, sieves, crucible, heat cell, cooling rack,
  presentation trays); above, a lava bed each (registered as lava), seats
  round a low table, the pantry, and a split amethyst geode. **The roof
  terrace** is reached by a lift (the circulation rules allow ramps or
  lifts): a ramp would need about 6.4 m of run the plot cannot spare, so an
  open platform with dichroic cheeks runs on four steel masts at the east
  bay's north end between three stations: the bay's ground, the home's door
  landing and the roof. It waits where it last stopped; its control on the
  platform offers the other stations, and a call post at each station brings
  it there (`CalderaLift`). The terrace has pale pavers and is ringed by a
  cast upstand with a dichroic glass balustrade, open where the lift arrives,
  with seats round two low tables and flames in glass toward the reservoir.
- **Variation:** the only two-storey home over a shop; the most glass at
  ground level.

### Kel foundry, armory and residence (`KEL`, `(44, -4)`; Daro, Vesa, Ruun)

- **Mass:** a long-span industrial shell 19 × 15 m with the residence as a
  separate small volume on the plot's quiet outer edge, joined by a covered
  bridge.
- **Foundry:**

| Room | Size | Description |
|---|---|---|
| Armory gallery | 10 × 8 m | faces `R4` and the promenade; finished armour on stands and weapons on forged racks behind glass; Daro's fitting stool; the counter |
| Receiving bay | 6 × 7 m | on `R2`, an overhead handling rail, ore and alloy stock |
| Surface workshop | 9 × 7 m | Vesa's fabrication bay: power hammer, hydraulic press, welding and fixture table, grinder bank and belt sander, oil quench tank; Ruun's finishing bench with polishing wheels and an engraving vise; Daro's alloy lab bench with crucibles and grain-test etching |
| Secure alloy store | 4 × 4 m | forged door |
| Descent | lift shaft and protected ramp | to the high-temperature forge `L4`; the third immersion shelf leaves from a protected hot-work landing outside, kept off the visitor gallery |

- **Residence** (8 × 7 m): a receiving and shaping room, one shared immersion
  well, three resting niches, and a bench where Ruun returns tools to the
  wrong sibling's place.
- **Plan (audited 2026-10-07):**
  - **Front row, 8 m deep:** the armory gallery (10 m), then a descent hall
    (9 m) holding the lift (3 × 3) and the head of the protected ramp to
    `L4`.
  - **Back row, 7 m deep:** the workshop (9 m), the receiving bay (6 m) and
    the alloy store (4 m).
  - Totals: 10 + 9 = 19 m and 9 + 6 + 4 = 19 m wide, by 8 + 7 = 15 m deep.
  - **Pass-throughs:** the alloy store and descent hall are reached through
    the workshop and receiving bay, all the foundry's own work rooms, which is
    legitimate. Customers stay in the gallery.
  - **Headroom:** the covered bridge to the residence clears 2.4 m.
- **Glass:** garnet and amber, the forge colours, in the gallery's high
  clerestory.
- **As built (approved 2026-10-08), its own idea: a temper-colour facade.**
  Heated steel takes oxide colours (straw, bronze, purple, blue) that a smith
  reads to judge its temper; Kel is clad in heat-tinted steel panels graded
  along the building from straw at the west to blue at the east, banded by
  height and shifting with the angle of view. A sawtooth north-light roof of
  cast rolled glass, garnet to amber, over the front row and the workshop.
  The overhead handling rail runs from the yard through the back wall over
  the dock on two columns, with its travelling bridge and hook. The receiving
  bay is a **loading dock** at the service loop's level (the site rises 1.25
  m), with a ramp to its lower strip; the alloy store at the dock's level.
  The gallery shows armour in cast-glass vitrines lit from below. The
  workshop has a refractory forge, power hammer, press, welding table,
  grinder bank, oil quench tank, Ruun's finishing bench and Daro's alloy
  bench. The descent hall holds the lift cage and a refractory portal with a
  forged gate to the deep forge.
- **Residence, revised:** the plot leaves no room for a separate house beside
  the 19 x 15 m hall, so the home (8 x 6.5 m) stands on the back row's roof,
  reached by a covered ramp-bridge from the uphill ground on the east: three
  lava beds, a receiving room with Ruun's bench and the three tool racks (one
  tool on the wrong sibling's rack).
- **Variation:** the longest span; the overhead handling rail; the only
  covered bridge between two masses on one plot.

### Vara glass and metal studio and home (`VARA`, `(28, 37)`; Omi and Talen)

- **Mass:** studio and home round a shared **daylight court**, with separate
  entrances. The clean assembly floor faces the promenade; the hot forming bay
  and deliveries face Kel and the cove bridge.
- **Studio:**

| Room | Size | Description |
|---|---|---|
| Clean assembly floor | 8 × 7 m | finished panes, frames and screens assembled under daylight, with a design wall of coloured samples |
| Hot forming bay | 5 × 6 m | the hot shop: glass furnace on the high-temperature branch, a glory hole for reheating, a marver table, Omi's blowing bench, a lampworking torch bench |
| Annealing chamber | 3 × 6 m | the lehr, a long annealing oven for big panes, and smaller annealers |
| Metal bench | 4 × 5 m | Talen's cold shop and metal bench: fusing kiln, cutting table and lightbox, leading and soldering bench, her forge and bending table for frames and branching supports |
| Glass rack | along the court | panes stored on edge |

- **Home:** a receiving and shaping room and a private immersion well, behind
  a **curved clear-glass wall** overlooking the reservoir.
- **Plan (audited 2026-10-07):**
  - **West wing, the studio, 8 m wide:** the clean assembly floor (8 × 7 m)
    at the promenade end, then the hot forming bay (5 × 6, narrowed from 6 so
    it and the annealing chamber fit the 8 m wing) with the annealing chamber
    (3 × 6) beside it. The metal bench (4 × 5) is at the court's
    north side.
  - **Centre:** the daylight court, 5 × 8 m, with the glass rack along its
    west wall.
  - **East wing, the home, 5 × 14 m:** an entry, the receiving and shaping
    room, the immersion well, and two resting niches.
  - Totals: 8 + 5 + 5 = 18 m wide.
  - **Separate entrances:** the studio's from the promenade, the home's from
    the east path. The court is shared but entered from the studio, and the
    home has a glazed door onto it.
- **Glass:** emerald-teal and amber. Talen holds the building to two colours,
  even here.
- **As built (2026-10-08):** the 18 × 14 m plan is three exact bands: the
  8 m studio wing, a 5 m centre band, and the 5 m home. The centre band is an
  open 5 × 8 m daylight court in front and Talen's enclosed 5 × 5 m metal shop
  behind. Finished structural panes stand in a working A-frame inspection rack
  along the court's west side, where direct daylight and reservoir glow reveal
  colour and distortion; it is storage and quality control, not unexplained
  decorative glazing. The clean assembly room has a cutting/light table and
  full-size colour samples. Behind it, the hot shop has the furnace, glory hole,
  marver and blowing bench; the annealing room has the long lehr and smaller
  annealers. The metal shop has cutting, leading, soldering and frame-bending
  stations. The home has its own east-path entrance, a receiving/shaping room,
  two lava resting niches and a private immersion well, all using the canonical
  architectural lava fixture.
- **Site correction from the isolated build:** the assumed rear loading doors
  faced directly into the plot's two-metre uphill cut. Deliveries now enter one
  overhead door on the Kel-facing side, serving both connected hot-work rooms;
  the rear remains the retaining wall. Studio, home and court connections use
  separate wide sliding openings, and the player capsule passes every approach.
- **Variation:** the only daylight court; the finest glass in the city.

## 5. Civic, science and thermal works

### Civic complex (`CIVIC`, `(0, 43)`; landmark; Aru, Selka and the council)

The council, school, archive and observatory share one open civic court. Its
landmark front faces the reservoir and the arrival view. The design begins with
public use and procession rather than a row of enclosed rooms: Highline,
threshold, terrarium, council forum and reservoir outlook lie on one legible
axis.

#### 2026-10-09 redesign brief: the Terrarium Court

**People and purpose.** Residents gather here for council, teaching, public
records and volcanic observation. Visitors may enter the forum without crossing
a classroom or secure archive. Pupils can gather around the living collection;
Selka can move between instruments and council; Aru can supervise the school and
archive from the same public court. The archive alone must close. The rest is an
open civic interior with shaded outdoor-room edges.

**Precedents translated, not copied.** Austin Central Library contributes the
daylit central atrium, bridges and stairs as social circulation, reading
porches, and a public building that opens toward landscape rather than sealing
itself off. Calgary Central Library contributes the civic portal and sky-facing
atrium as the building's wayfinding heart. The British Museum Great Court
contributes a lightweight glazed roof that turns a court into a luminous public
room while leaving a singular object at its centre. The Fire Kingdom translates
these into SuperEgg geometry, forged branching ribs and mineral glass; it does
not reproduce any facade or motif.

- Austin sources: [City sustainability study](https://www.austintexas.gov/sites/default/files/files/Sustainability/Austin_s_Central_Library_White_Paper_-_FORMATTED.pdf), [Austin Public Library program](https://library.austintexas.gov/library/document/about_library_book.pdf).
- Daylight-roof sources: [Calgary Central Library / Snøhetta](https://www.snohetta.com/projects/calgary-central-library), [British Museum Great Court](https://www.britishmuseum.org/about-us/british-museum-story/architecture/great-court).

**Coordinated plan and section.** The footprint remains 24 × 15 m on the
approved 30 × 21 m Highline platform. A five-metre-wide central superellipse
portal occupies the middle bay of a symmetrical reservoir facade. It opens
directly into a 6 m-deep arrival loggia and frames the terrarium; there is no
door leaf across this public threshold. The sealed terrarium is an 8.8 × 7.0 m
glass lantern at the centre of the plan, leaving at least 1.6 m clear around its
sides and a much broader forecourt and rear outlook. The west perimeter is the
open council forum. The east-front perimeter is the school gallery. The east-
rear perimeter is the secure archive, separated by a full-height glazed screen
and a surface slider. A broad rear overlook keeps the reservoir visible around
the terrarium. The upper observation walk is a rear mezzanine, reached by one
clear two-flight ramp on the west; it never caps the central court.

**Terrarium.** The living archive is the building's largest object, not a case
against a wall: 8.8 × 7.0 m in plan and about 8.2 m to the crown. A tall clipped
SuperEgg glass shell rises well above the five-metre specimen tree. Its clear
lower field makes earth, rock and plants readable at eye level; a restrained
amber, garnet, cobalt, violet, emerald and teal belt marks the canopy spring.
Seating, council positions and both gallery routes face it.

**Roof plan and section.** A shallow double-curved glass-and-steel saddle canopy
spans the whole court at 8.8 to 10.2 m, rising toward the long sides and the
central front/rear axes. It is not a dome and is not a second terrarium. Clear
and lightly smoky panes provide the principal daylight; a sparse set of colored
glass baffles hangs below selected ribs and throws color through the court.
Continuous perimeter channels drain to the four outer corners, away from the
central portal. Branching SuperEgg columns at the facade shoulders and rear
corners visibly carry the canopy.

**Facade and hierarchy.** The front is bilaterally composed: a tall central
portal, two glass wings, and paired branching piers. The portal is the focal
point and the terrarium crown is visible through it. Colored glass is an accent,
not the wall material. The base is the existing cool refractory/composite
platform; the middle is mostly clear glass and open air; the top is the floating
gridshell.

**Material/style audit.** Primary Fire volcanic modernism supplies the flowing
SuperEgg plan, cast-basalt service cores, blackened/heat-blued structure, broad
mineral glass and concealed lava services. The restrained Gaudi-informed craft
layer appears only in branching canopy ribs and suspended colored baffles. The
landmark exception is the building-scale terrarium. There is no classical
portico, domestic gable, copied Austin facade, or repeated inn dome.

**Program:**

| Room | Size | Description |
|---|---|---|
| Central terrarium court | 12 × 15 m, double height | principal public room, circulation and living archive; the terrarium occupies the centre rather than the route |
| Council forum | west perimeter, about 6 × 8 m | five warm basalt seats and standing room facing the terrarium and reservoir |
| School gallery | east-front perimeter, about 6 × 6 m | low benches and shaping tables, visually joined to the court through glass |
| Archive | east-rear perimeter, about 6 × 5 m | the only closed ground room; dry records, metal pattern plates and future lift to `L3` |
| Observation walk | rear mezzanine, 3 m deep | instruments, reservoir outlook and visual circuit around the terrarium crown |
- **Lower observation landing:** against the reservoir wall below the council
  chamber; the second immersion shelf leaves from here, descending to the deep
  observatory `L2`. It is reached by an **outside ramp** from the `R5`
  landing, down about 4 m along the reservoir-edge foundation, not through the
  chamber.
- **Variation:** the only building-scale terrarium, the broadest open civic
  portal, and the only full-building saddle gridshell.

### Iren residence (`IREN`, `(-26, 50)`; Selka, Aru, Mena)

- **Mass:** a compact 12 × 9 m home joined to the civic complex by a short
  glazed passage, but acoustically separate.
- **Rooms:**
  - a receiving and shaping room;
  - a family immersion well;
  - three resting niches;
  - Mena's corner with her collection of coloured glass fragments from the
    studio;
  - a glazed outlook over the reservoir.
- **Glass:** cobalt and amber, the civic pair, in small fields.
- **As built (2026-10-08):** the 12 × 9 m shell has a reservoir-facing
  receiving/shaping room and a closable rear molten room with three individual
  lava resting niches and a central family immersion well. Mena's backlit
  colour-fragment case sits in the receiving room beside, not inside, the
  circulation. A second surface slider opens to a 2.3 m wide sealed glass
  bridge. The bridge runs diagonally to the matching slider in Civic's ramp
  hall and slopes continuously across the 1.02 m difference between the two
  surveyed floor datums; it therefore lands flush at both buildings instead of
  floating or ending against Civic's wall. All three doors and the bridge pass
  the player-capsule proof.

### Aro thermal works and household (`ARO`, `(-39, 22)`; Tovan, Miru, Kes)

- **Mass:** a 17 × 13 m shell on a surveyed stepped, embedded podium. The
  expected bedrock-spine condition did not survive the real site section: the
  measured grade is moderate, not steep. The geological-spine idea instead
  appears where it is true, as the protected dry cut for the service descent.
  The thermal works is to the reservoir side, the home to the outer side. The
  public entrance is on the terrace loop, and a service descent leads to the
  primary manifold `L1`.
- **Thermal works:**

| Room | Size | Description |
|---|---|---|
| Control gallery | 9 × 7 m | the duct network's valve wall, pressure gauges, a reservoir-height window, the council's emergency bell; bright steel controls; a valve and duct workshop at one end (pipe bender, welding bay, pressure-test rig, spare valve bodies) where Miru and Kes work |
| Service descent | shaft and ramp | to `L1`; inspection hatches on the service terrace outside |

- **Home:** a receiving and shaping room, a shared immersion room, three
  personal resting niches, a sample shelf, and a protected glazed outlook
  toward the entrance beacons. A short service passage reaches the control
  gallery, and the public door faces the annular route.
- **Glass:** cobalt and teal, the cool colours of instruments.
- **Variation:** the excavated service descent; the valve wall.

- **As built (2026-10-08):** the 9 m works band and 8 m home band share one
  low, flat SuperEgg roof but have separate outside sliders. Five cobalt/teal
  valve stations and gauges anchor Tovan's 9 × 7 m control gallery; the rear
  workshop has Miru and Kes's pipe bender, welding and pressure-test benches,
  spare valve bodies, and two exterior inspection hatches. A private slider is
  the only works-to-home connection. The home has a receiving/shaping room,
  sample shelf, three canonical lava beds and one shared immersion well. A
  real 2.4 m-deep pit in the authored podium carries a railed SuperEgg ramp to
  a sealed future-`L1` bulkhead. The ramp uses its true sloping length so its
  ends meet both landings; all five doors/passages, the ramp grade, clear zones
  and lava fixtures pass the isolated physics proof.

### Audit notes for Iren and Aro (2026-10-07)

- **Iren:** single storey; the niches open off the family's own receiving
  room, which is legitimate in their own home. The glazed passage to Civic has
  a door the family can close, so the public complex never runs through the
  home.
- **Aro:**
  - **Sizes:** the control gallery is 9 × 7 m, with the home in the
    remaining 8 × 13 m.
  - **Separate doors:** the works' public door and the home's door are
    separate, and the service passage between them is the family's own.

### Foundations: audit step 5 completed by the survey

The localized caldera terrain and plot survey (`FireCalderaPlan` fields:
corner and door heights, floor datum, foundation type) are live. The survey is
authoritative over the expected labels in the brief: notably, Aro measured as
a moderate-grade stepped podium rather than a steep-site bedrock spine. Each
built shell is checked against that measured section in the isolated proof.

## 6. The Caldera Heartworks (after the Lava Helm)

The lower rooms occupy three rings of the proposed 84 m diameter spherical
Heartworks and are reached by swimming in the Lava Helm. They are cast-basalt
and refractory shells socketed into the chamber's structural webs, lit by
mineral lenses, controlled falls and molten return seams, with openings at
least 3 m clear so swimmers move in three dimensions. Every occupied room has
two ways out (`fire_caldera_layout.md` section 7). The full section and lava
cycle are in `fire_caldera_heartworks.md`.

| Room | Character |
|---|---|
| `L0` Renewal chamber | a broad bowl of tiered basalt ledges on the Steward Ring beside the gentler Renewal Fall; where youths make their first full immersion |
| `L1` Primary manifold | the north-west Steward Ring's great valves, fall gates and return controls |
| `L2` Deep observatory | a Civic Ring chamber with instruments in steel cages and a protected lens looking across the Heartfall |
| `L3` Fired archive | vaulted bays of cast and engraved records in heat-proof niches |
| `L4` High-temperature forge | the hottest Works Ring floor beside the Forge Fall, open crucibles, an alloy handling rail, the lift to Kel |
| `L5` Experimental materials bay | Works Ring test rigs shared by Kel and Vara, separate from the clean assembly floor above |

## 7. Variation matrix

| Building | Foundation (expected) | Storeys | Roof | Stained glass | Signature |
|---|---|---|---|---|---|
| Pylons | sockets | — | — | amber, cobalt | framed air, beacons |
| Guest house | socket plinth | 1 | shallow shell | cobalt, amber | the cool house |
| Nahl | socket plinth | 1 | raked clerestory | none (tuff house) | ironwork, conversation pit |
| Renewal | reservoir edge | open | catenary canopy | amber, garnet, teal | immersion shelf |
| Oren | socket plinth | 2 | walkable terrace | teal, violet | display cells |
| Kel | stepped podium | 1 + lift | long span | garnet, amber | handling rail, bridge |
| Vara | socket plinth | 1 | shell round a court | teal, amber | daylight court |
| Civic | reservoir edge | 2 + dome | shell and dome | cobalt, amber, teal | the dome |
| Iren | stepped podium | 1 | shell | cobalt, amber | glazed link |
| Aro | stepped podium + excavated descent | 1 + descent | shell | cobalt, teal | valve wall |
| Cove bridge | bank sockets | — | — | amber | catenary ribs |

The plot survey confirms or changes each foundation type before any shell is
built.

## 8. Style audit

| Element | Term | Tradition |
|---|---|---|
| Shells, terraces, cantilevers | continuous cast shells | invented volcanic modernism (primary) |
| Branching mullions, rails, supports | organic forged metalwork | Gaudí-informed craft (secondary, named elements only) |
| Catenary canopies and bridge | catenary structure | Gaudí-informed (secondary) |
| Stained glass | abstract mineral glazing | the city's own palette |
| Seams, lenses, beacons | living volcanic light | accent |

At most two traditions on any building: the modernist shell plus the forged
metal and glass craft on named elements.

## Fixed, proposed and open

**Fixed:**
- the approved layout's plots, routes, lower rooms and foundation system;
- the charter;
- the guest house as the rest point at 25 Tokoins, with a cool envelope and the
  incinerating toilet;
- no visitor through treatment rooms;
- the canonical lava systems.

**Proposed:**
- the kit and signature motif;
- every building's form, rooms and glass colours;
- the pylons' asymmetry;
- the Civic dome;
- Kel's separate residence volume with its covered bridge;
- the lower rooms as lava-filled shells.

**Open:**
- the final shop stock;
- the submerged story encounters.


## Walkthrough fixes (2026-10-18, at the user's direction)

The user walked the built caldera. Each fix below is a rule for every building
in it, not only the one where it was seen.

- **The inn's sign** keeps its cobalt and amber stained-glass leaves and adds
  the shared inn symbol: the bed under the crescent moon
  (`VillageInn.build_bed_and_moon_sign`, as every other inn has), leaded into
  the leaves in stained glass. It carries no lettering.
- **Skylights are clean cuts.** A SuperEgg roof slab is cut by its skylights
  the way the spaceship's hull is cut by its windows:
  - a high-resolution slab (56 rings, 76 segments, not 12);
  - closed cutter profiles, subtracted;
  - the result baked (`SolidModel.bake_when_ready`, crease normals rebuilt);
  - each glass dome built from the same cutter, intersected with the slab's
    outer shell, as `_glaze_windows` does.
  The glass is never a child of the roof's CSG, and never shares its
  collision. The roofs were left live and unbaked, so they shaded smeared and
  slivered.
- **A building's own terrace is the building's.** Oren's roof keeps only its
  own paving, its parapet with the lift's gap, and the spiral stair landing on
  it. The glass terrace and second guard laid over it are removed; they
  blocked the lift.
- **No two surfaces at one height.** Oren's yard and his ramp's foot landing
  overlapped, and so did others. A surface stops at the edge of another at
  its height, or is cut out of it.
- **City Hall:**
  - **The terrarium** cannot be entered. Its glass is a solid convex collider
    (its hull), not a trimesh shell the player can pass through and be
    trapped inside.
  - **The way up.** The glass switchback ramp ran under the solid west
    gallery slab, so its upper half had no headroom. The ramp now rises in the
    open hall, clear of every slab overhead by 2.4 m, and arrives on the
    gallery through the opening already left in the gallery's guard
    (x −5.4, z 0.85 to 3.25 in its frame). Alternatively, the gallery slab
    above it is cut open as a well. The council's chairs stay clear of the
    ramp.
- **Raised buildings' supports are solid.** The supertoroidal pier under each
  raised building collides as it looks, stacked convex shapes following its
  waist and flare, so the player can never walk inside it. Its four vertical
  orange poles are removed: they carried nothing.
- **The rule for the player:** no part of the caldera can be entered that is
  not meant to be. Every closed visual has the collision of its outside.
