# Style charters

**Moved.** Each settlement's charter now lives in its own file in `docs/architecture/` (see its README), next to the town plan, landscaping and interior briefs. This file keeps the cross-settlement notes and the draft variation matrix for Ohio until it is merged into `docs/architecture/ohio.md`.

One charter per settlement or kingdom. A charter fixes the architectural vocabulary so every building belongs to the same people. See the `architecture` skill (section 0a, `references/styles.md`, `references/glossary.md`). Status: **DRAFT** until the user approves; update in place, never append conflicting entries.

## Ohio (the starting village)

**Status: approved implementation charter.**

- **Primary style (about 75 percent): English medieval and early-modern village vernacular, half-timber and stone.** Rectangular hall-house massing with cross-wings and lean-to outshuts, jettied upper storeys, steep gables, clay-tile roofs, plastered walls over a stone plinth.
- **Secondary influence (about 20 percent): Georgian simplification, civic and polite buildings only.** The meeting hall, the inn and the miller's house carry a pedimented portico or door case, a more regular bay rhythm and a boxed eave. Cottages, workshops and outbuildings stay purely vernacular.
- **Accent (about 5 percent, landmarks only):** the windmill and the bell turret.
- **Kit of parts.**
  - Roof: gable (main), half-hip for small outbuildings, lean-to or catslide for outshuts and porches; **one pitch band, 38 to 45 degrees**; clay tile in warm red-brown; bargeboards on gables; deep-ish eaves (0.4 m).
  - Walls: **stone plinth (0.5 m) and ground storey, plastered upper storey on an exposed oak frame**, jettied 0.3 m on the street fronts; limewash.
  - Chimneys: **external gable-end stack built into the wall**, a visible breast stepping in as it rises, brick or stone, clearing the ridge by 0.8 m.
  - Windows: tall casements with mullions and a leaded pattern, superellipse frames, sill, shutters; wide casements only on the main room; sashes only on the polite buildings.
  - Doors: ledged and braced board doors for homes, double panelled door under a portico for the hall.
  - Signature motif: **carved bargeboards and a rolled bracket under every jetty and canopy**, repeated on every building.
  - Palette: walls cream and ochre limewash (60 percent), roofs clay red-brown (30 percent), trim oak brown with one accent per building (madder red, moss green or slate blue shutters, 10 percent).
- **Hierarchy.** Polite: meeting house and archive, Holt Inn, Fask and Prewitt house. Vernacular: all other homes and workshops, granary, sheds, stalls.
- **Exclusions.** No stacked-log walls (Snow Village), no Craftsman tapered porch columns, no pagoda or Alpine elements, no Georgian sash on cottages.
- **Note.** The user raised Craftsman as a possible influence. If chosen as the secondary instead of Georgian, restrict it to porch columns on stone piers and exposed rafter tails on the civic and inn buildings, and drop the pedimented portico.

### Ohio variation matrix (proposed; the shared language above is fixed)

| Building | Plan and mass | Roof | Entry | Upper feature | History |
|---|---|---|---|---|---|
| Fask and Prewitt house | Two-storey cross-wing, jettied front | Gable with cross-gable, tile | Open gabled porch on posts | Oriel window, hood moulds | The upper storey Dorran built himself; roofline not quite true |
| Ruskin mason's house | Low single range, stone storey, rear stone yard | Gable, side-on to the lane | Pent hood on stone corbels | None | Oldest building by the stream |
| Cray and Thorne cottage | L-plan, one and a half storeys, hedged garden | Half-hip on the cross-wing | Doorstep, climbing rose on a trellis | Two gabled dormers over the loft | Ivy's loft room added later |
| Meeting house | Long single range, double-height hall | Gable with belfry gablet | Pedimented portico | Belfry | Civic, built once |
| Barrow bakehouse | Single range with a rear brick oven outshut | Catslide over the oven | Shop awning and hatch | None | Oven added to an older house |
| Fask water sawmill | Long working range with a lean-to timber shed | Gable, a lean-to along the race | Cart door with a hoist | Gable hoist | Mill first, shed added |
| Vey house | Narrow tall two-storey, gable to the green | Gable end front | Door case with fanlight | **Juliet balcony** on the upper room | Newest; polite front over an older core |
| Kest smithy | Workshop bay below, home above | Gable with a large stack | Deep hood over the bay | Small external stair to the upper door | Forge first, rooms above added |
| Ferris millhouse | Long single range beside the windmill | Catslide to the yard | Cart door and a small door | Hoist beam | Grew with the mill |
| Sallow cottage | Small one-and-a-half-storey cottage | Half-hip, tile | Open porch with herb racks | A gablet | Nearest the hedge line |

Shared by all: pitch 38 to 45 degrees, plinth 0.5 m, oak frames, cream and ochre walls, red-brown tile, carved bargeboards and rolled brackets.

## Snow Village (Ice Kingdom)

**Status: approved implementation charter. Option A is authoritative.**

### Option A (approved): Norwegian and Alpine log vernacular
- **Primary (about 75 percent): Norwegian log farm vernacular (tømmerhus, stabbur, laft).** Compact log houses, a stone foundation, a covered vestibule, farm buildings gathered around a common yard, a raised storehouse (stabbur) on stone piers.
- **Secondary (about 20 percent): French Canadian bellcast eave and gallery**, on the inn and the rescue hall only: the concave flare of the eave over a covered gallery gives a snow-shedding, sheltered front walkway.
- **Accent (about 5 percent):** a stave-style tiered bell roof on the rescue hall.
- **Kit of parts.**
  - Roof: **steep gable, 45 to 50 degrees**, wood shingle over birch bark or turf, deep eaves with cut-board edging, snow guards at the eave; bellcast flare on gallery roofs; catslide over wood stores.
  - Walls: laft log with projecting notched corners, left dark or tarred, stone foundation, vertical board in gables.
  - Chimneys: external gable-end stack built into the wall; steaming flue.
  - Windows: small, deep-set, white frames, shutters; a few larger on the south sides.
  - Doors: plank doors under a vestibule or gallery, carved door case.
  - Signature motif: **carved dragon-head or horse-head finials on gable peaks and a painted flower (rosemaling-like) band on the door case**.
  - Palette: weathered brown and tar-black logs (60 percent), snow-white and slate roofs (30 percent), oxide-red, ochre or blue-green accents (10 percent).
- **Hierarchy.** Polite: the inn and rescue hall (gallery, bellcast eave, tiered bell roof). Vernacular: homes, workshops, sheds, stabbur.
- **Exclusions.** No half-timber, no Georgian symmetry, no Alpine heart-cutout balconies (a separate tradition from the Norse one), no flat roofs.

### Rejected alternative: French Canadian primary
- Primary: Quebec stone and timber maison with bellcast eave and gallery, red or silver metal roofs, dormers (lucarnes). Secondary: Nordic carved gable ornament on the civic buildings. Exclude log-notched corners (a Nordic trait) on the primary buildings.

Both options keep the engine rule: SuperEgg solids, superellipse openings, soft epsilon for turf and snow, square-edged epsilon for logs and beams.

## Crossroads Fishing Village (the lake)

Detail and per-building forms: `docs/architecture/fishing_village_buildings.md`.

- **Primary (70 to 80 percent): Southeast Asian stilt and jetty vernacular**, from the working timber jetty settlement (George Town's Clan Jetties) and Ko Panyi's siting. Light post-and-beam frames on piles, broad hip and gable roofs with deep eaves, open walls of infill panels, and shade as the organising idea. Houseboats are the same vocabulary on a hull.
- **Secondary (15 to 20 percent): Thai and Malay shutter and veranda joinery**, applied only to the named elements: top-hung prop-open shutters, the deep veranda, carved ridge ends and fascias. Not to roof form and wall system together.
- **Accent (up to 5 percent): the household colour**, applied to wall panels, shutters, ridge caps and the household's boat, so the village keeps its varied terracotta, teal, ochre, violet, coral and green.
- **Kit of parts.**
  - Structural module: the 3.0 m bay, posts on every bay line, ring beam at 4.0 m (revised 2026-10-07 so Ohio-thick roofs and veranda pents clear 2.4 m).
  - Roofs: hip or gable only, one pitch band (30 to 34 degrees), eaves 0.9 m, pent roofs on verandas (15 to 18 degrees). Built with `StiltRoofs` on `TownProps.roof_slab`/`build_ridge_slab` (the shared Ohio construction: squarish shoulders, ridge cut), never plain slabs. Every building is assembled from `StiltKit` (`scripts/stilt_kit.gd`).
  - Walls, in order: light timber boards, woven rattan basket-weave panels, shutters. No sealed boxes.
  - Shutters (2026-10-07): the top-hung awning shutter of the secondary joinery, one panel hinged at the window head and propped out as a sunshade (`StiltKit` builds it), never side-hung pairs, which reached the posts and neighbouring openings. Windows already shaded by a veranda, porch or eave have none.
  - Interior doors: between a home's own rooms, a cloth curtain (langsir) in a framed opening; hard leaves only where something must close (outside doors, toilets, the clinic, stores). Every doorway is 2.45 m tall.
  - Headroom: every eave or roof a route passes under clears at least 2.4 m (ring beam 4.0 m on houses, pents 3.15 m at the wall); `tools/fishing_building_proof.tscn` fails a route under 2.35 m.
  - Roof slabs are Ohio-thick (0.24 m), so the SuperEgg shoulder reads at the eave; pents are cut flush where they meet their wall.
  - Every rest point hangs the shared bed-and-moon sign (`VillageInn.build_bed_and_moon_sign`).
  - Windows and doors: superellipse openings, piped frames with the reveal in the frame colour (`OpeningTrim`).
  - Foundation: squarish timber piles 0.3 m with caps, braced in pairs, on the shelves only. Floating hulls are moored by lines to pile clusters, never to the lake bed.
  - Signature motif: **rope-bound posts at every threshold and work deck**, seen at least three times in the village.
  - Palette: natural timber and sun-faded shingle (60), household wall colour (30), accent shutters and ridge caps (10).
  - Decks (2026-10-07): planks, never slabs. Squarish SuperEgg boards 0.2 m wide with 15 mm gaps, laid across the way of travel on joists, staggered joints on wide decks (`StiltKit.plank_surface`, one MultiMesh per deck, one smooth collider). Ramps, thresholds, swim exits and slipways are planked the same way on two stringers.
  - Timber tones: open decks are tropical hardwood (chengal, belian) bleached by sun and water to a silvery grey-brown, each plank a little greyer or warmer, the odd replaced board paler; house floors a warmer mid brown out of the sun; only wet timber (piles, beam undersides) is dark. Not the near-black of creosoted or tarred timber.
  - Lights: oil lamps hung from rope-bound junction posts with a bracket arm, and under eaves (`StiltKit.lamp_post`).
- **Hierarchy.** Polite: the communal pavilion and the Mor guest houseboat (largest roofs, ridge vents, fascia carving). Vernacular: homes, work decks, sheds.
- **Exclusions.** Sealed boxes; Peranakan shophouse facades; clan temples or sacred roofs; brick or masonry walls; lights on poles; uniform brown; plain unclipped roof slabs; SuperEgg props standing in for rock.
- **Doors and openings face the route that serves them** (the layout's route ledger), the veranda faces the water court or landing, and service sides face outward.

## Moy: Old Moy (the well town)

**Status: proposed, 2026-10-13.** Brief: `docs/architecture/moy_tower_house.md`.
Precedent: the highland Yemeni tower house (old Sana'a, Wadi Dhahr, Sa'dah's
coursed-earth houses) and Shibam's close-packed towers (user's reference
photos, 2026-10-13: a single Wadi Dhahr tower and a view of old Sana'a).

- **Primary (about 75 percent): highland Yemeni tower house.** Narrow towers
  of 4 to 9 storeys on a base of dark stone (most) or of battered,
  round-cornered rammed earth (*zabur*, the oldest), with upper storeys of
  fired brick banded at every floor in white gypsum friezes, with white-outlined windows under semicircular
  fanlights (*qamariya*), and a flat roof terrace behind a crenellated
  parapet with horned corners.
- **Secondary (about 20 percent): the Persian wind tower (*badgir*), on the
  roof only.** One-sided catchers turned to the steady west wind, standing
  over each house's ramp core, which serves as the house's air shaft.
- **Accent (about 5 percent, landmarks only):** stained-glass qamariya lit
  from within at night, on the oldest houses facing squares (the first-well
  house on Cinema Square, Pinestein's building, Sol's café).
- **Kit of parts.**
  - Roof: **flat terrace only**, drained by projecting spouts (*mizab*);
    parapet 1.2 m, crenellated, whitewashed horns at the corners; a roof
    kiosk over the ramp core; optionally a *manzar* (rooftop room).
  - Walls: **stone plinth 0.9 m**, then one of two bases: **stone** (most
    houses), coursed dark basalt with pale ashlar bands, 0.7 m, plumb,
    square corners, 1 to 3 storeys; or **zabur** (the oldest, about one in
    five), 0.65 m lifts battered about 1.5 degrees, 0.9 m thick at the
    ground, free corners rounded (superellipse) with each lift's ends turned
    up, 2 to 4 storeys, under a white gypsum cornice. **Fired brick above**,
    0.45 m, plumb.
  - Bands: white gypsum (*nura*) friezes at every brick floor from a closed
    set (zigzag, chevron chain, roundel row, dentil course); roundel panels
    between windows on polite houses.
  - Windows: small deep square lights in the base; in the brick, a
    tall window (1.0 × 1.6 m) under a qamariya fanlight (0.5 m radius), every
    one outlined in white gypsum; the top floor (*mafraj*) has low wide
    windows, sills at 0.4 m, for sitting on floor cushions.
  - Projections: the *kishk*, a plastered box window on brackets
    (1.2 × 1.6 × 0.6 m); the old latrine shaft, a plastered chute up a side
    or back face, now carrying the soil stack; white drainpipes from the
    spouts.
  - Doors: a heavy carved timber house door in a superellipse-headed
    opening with a gypsum surround and the **house mark** painted above it;
    painted leaves in blue, green or ochre. Shopfronts cut into the base
    later: a wide opening on a timber lintel with folding shutters.
  - Signature motif: **white gypsum outlines on every opening and band,
    and the painted house mark over every door.**
  - Palette: basalt grey-brown, earth ochre and brick red-brown (60 percent), gypsum white
    (30 percent), accents (10 percent): painted doors, coloured fanlight
    glass, the house marks.
- **Hierarchy.** Polite: the old merchant houses on squares and main
  streets (brick relief panels on every storey, a kishk, stained glass).
  Vernacular: the rest (relief on the top storey only, plain glass).
- **Exclusions.** No pitched roofs or roof tiles (tiles belong to the later
  pencil infill, a separate kit), no domes or horseshoe arches, no Cairene
  timber mashrabiya, no lettering on any sign or house.

### Old Moy variation matrix (the shared language above is fixed)

| Axis | Range | Reason it varies |
|---|---|---|
| Storeys | 4 to 9 | how much the family built, and when |
| Base | stone, 1 to 3 storeys (most); earth, 2 to 4 storeys and never above two-thirds of the height (about one in four) | the oldest houses, round the first well, were raised in earth; later ones on stone |
| Corner | rounded only on earth bases where two faces are free; square on stone | how each material is built |
| Friezes | four band patterns, one or two a floor | each family's ornament |
| Kishk | 0 to 2, upper floors only | wealth and which rooms face the street |
| Wind tower | on the core, mouth west; at the front or back of the roof | follows where the core stands |
| Manzar | about one house in four | a later rooftop room |
| Parapet | three crenellation patterns | each builder's family pattern |
| Ground floor | shopfront on main and shopping streets, house door only on lanes | the modern layer |
| Kit | tower house on lots 6 m or more across; the tiled pencil infill on narrower ones | the narrowest lots were filled last |
| Age marks | fresh or faded whitewash, a brick storey added in a different brick, an infilled window | each house's history |

## Moy: the market lanes

**Status: proposed, 2026-10-13.** Brief: `docs/architecture/moy_market_lanes.md`.
Precedent: Hong Kong's tenement shophouses (*tong lau*) in Sheung Wan, Mong
Kok and Sham Shui Po, and Tokyo's covered shopping streets (*shōtengai*).

- **Primary (about 75 percent): the Hong Kong tong lau,** in two
  generations:
  - **Boom houses** (4 and 5 storeys), built for the Windworks' first
    workers: rendered walls, a **veranda** on square columns over the
    pavement on main streets and squares, stacked verandas above it, tall
    French windows.
  - **Tile houses** (6 to 9 storeys), built as the city grew: mosaic tile,
    cantilevered balconies, a concrete canopy over the shopfront, and on
    corner lots the rounded **Streamline Moderne corner** with curved
    balconies wrapping it.
- **Secondary (about 20 percent): the Tokyo shōtengai,** at street level
  only: the arched translucent roof over Arcade Street through the market
  lanes, roll shutters and cloth door curtains (*noren*) on the shopfronts.
- **Accent (about 5 percent):** the night market's lantern strings over
  Lamp Lane; Wing Fat Mansion as the district's one tall landmark.
- **Kit of parts.**
  - Roof: **flat**, a 1.1 m parapet; on it water tanks on stands, laundry
    frames, a rooftop greenhouse (the boom houses), or a roof garden.
  - Walls: **render** on boom houses, **mosaic tile** on tile houses, both
    from one palette; a plinth of granite-grey tile 0.6 m.
  - Windows: boom houses, tall French windows (1.0 × 2.2 m) onto the
    verandas; tile houses, wide steel windows (2.0 × 1.4 m) behind the
    balconies; superellipse corners on all.
  - Balconies: the veranda (boom), the cantilevered balcony with a steel
    rail (tile), later enclosures and plant cages on some.
  - Ground: a shopfront the full width but for the house door; roll
    shutter, noren or a counter to the pavement.
  - Signs, the signature motif: **lit picture signs stacked up the facades
    and hung across the lanes, never lettered** (Zara's).
  - Exterior life: AC units, laundry poles, potted plants, each where a
    person would put it.
  - Circulation: a switchback **ramp core shared by two houses** on their
    party wall, as tong lau pairs share a stair; houses of 7 or more
    storeys add a lift in a glass shaft at the back.
  - Palette: tile and render in cream, mint, salmon, pale blue or grey (60
    percent); white and grey trim, rails and canopies (30 percent); sign
    colour, noren and lanterns (10 percent).
- **Hierarchy.** Polite: houses on Market Square and the main streets
  (verandas, rounded corners, more signs). Vernacular: the lanes.
- **Exclusions.** No pitched roofs, no Old Moy gypsum friezes or qamariya
  (they belong to the well town), no glass curtain walls, no lettering.

### Market lanes variation matrix

| Axis | Range | Reason it varies |
|---|---|---|
| Generation | boom house (4 to 5 storeys) or tile house (6 to 9) | when it was built |
| Veranda | boom houses on main streets and squares | the boom streets had them by rule |
| Corner | rounded Streamline corner on tile houses with two street faces | corner lots |
| Colour | five tile and render colours; neighbours differ | each owner's choice |
| Signs | 0 to 3 stacked picture signs | busier streets carry more |
| Roof | tanks, laundry, greenhouse or garden | how the residents use it |
| Core | shared with a neighbour or the house's own | narrow lots share |

## Plant Kingdom: the primate village (canopy vernacular; approved 2026-10-06, kit revised 2026-10-14)

The full kit, hierarchy and briefs are in
`docs/architecture/plant_kingdom_village_buildings.md` (sections 1 and 4a).
In brief:
- **Primary, about 70 percent: canopy vernacular built by primates.** Open
  pavilions on decks lashed to living trunks, round a central pillar, under
  *atap* thatch roofs on a lashed wall plate.
- **Secondary, about 25 percent: ground lodges on short stilts.** Long houses
  with front galleries, after Borneo's longhouses, as structure only. The inn
  and the food store borrow it.
- **Accent, about 5 percent:** the commons and the carved trunk markers.
- **Invariants:**
  - one roof pitch (40°) and one eave (1.0 m, its underside at 2.46 m);
  - a 3.3 m wall plate;
  - the 1.9 m module;
  - lashed joints, with the dark wrap at every post head as the signature motif;
  - woven walls and blinds, round posts and the central pillar;
  - nothing driven into a living tree.
- **Exclusions:** nails, sawn boards, glass, lights on poles, Chinese or Greek
  forms, and copies of real sacred carvings.

## 临渊村: northern Chinese courtyard village (approved implementation charter, 2026-10-15)

Full building and garden brief: `docs/architecture/chinese_village.md`
sections 4.1–4.4. The authored `ChinesePlan` fixes the site geometry and
openings; this charter fixes how that geometry is expressed in the game.

- **Primary (about 75 percent): northern Chinese courtyard vernacular.**
  Axial household compounds, grey tile, white plaster over a brick plinth,
  plain dark timber, restrained eaves, and homes organized around a kang and
  its stove.
- **Secondary (about 20 percent): late-Qing Shihu Yuan garden architecture.**
  Used for the inn and palace garden: moon gates, lattice screens, covered
  corridors, pebble courts, rockery, small pavilions, and painted beams.
- **Accent (about 5 percent): imperial palace.** Vermilion walls and columns,
  marble terraces, and yellow glazed tile are reserved for the palace.
- **Kit of parts.**
  - Roofs: ordinary homes use flush or overhanging gables in grey tile; the
    inn may use its green ridge; important halls use hip or hip-and-gable
    forms. One shared pitch and restrained, gently upturned eave treatment.
  - Walls: grey brick plinth, brick piers, white plaster infill; brick lattice
    where a courtyard wall should screen without closing the view.
  - Structure: squarish SuperEgg columns on stone bases carry SuperEgg beams;
    bracket sets are stacked squarish members under the eaves. Walls read as
    infill between the frame, not as unsupported ornament.
  - Openings: superellipse-framed doors and windows; round lattice windows;
    moon, square, and octagonal garden passages with level thresholds.
  - Palette: white plaster, grey tile and brick, dark timber; green and blue
    painted beams and restrained red lacquer. Yellow remains imperial.
- **SuperEgg rule.** Use clipped SuperEgg slabs for roof planes and their
  shaped free edges; squarish SuperEggs for plinths, piers, columns, beams,
  brackets, and opening trim; soft SuperEggs for garden rocks and cloud-pruned
  forms. Pair substantial pieces with `CollisionPolicy`. Keep continuous
  ground, water, and polygonal landforms as purpose-built surfaces, and use
  simple collision primitives where they give dependable traversal.
- **Hierarchy.** Vernacular: household compounds, shops, and sheds. Polite:
  the inn and public halls. Imperial: palace and its garden.
- **Exclusions.** No generic pagoda trim on every house, no yellow tile beyond
  the palace, no southern garden excess, and no ornament without a structural
  or cultural role.

## Other kingdoms

Draft charters to be added from `references/cultures.md` grammars: Rock and Ground (earthen Pueblo/adobe), Ocean (stilt harbour), Sky (drafted in `docs/architecture/sky_kingdom.md` as celestial classical in quartz, gold and cloud: Greco-Roman about 55 percent, Chinese celestial palace about 35 percent by deliberate choice rather than the usual 75/20 split, with the rule that no single building mixes both traditions), and the Western city (concrete). The Fire Kingdom's draft volcanic-modern charter now lives in `docs/architecture/fire_caldera_city.md`. Each remaining kingdom needs the Ohio-style charter with a primary, one secondary, an accent, a kit of parts, hierarchy and exclusions.

## Moy: Downtown (P6)

2026-10-19. P6 develops the already approved city.md section 7c concepts;
locked plots, routes, heights and the three tower identities remain binding.

- **Primary, about 75 percent:** tropical modern podium-and-tower fabric:
  flat roofs, recessed modular glazing, concrete/ceramic structure, deep
  shade, public colonnades and inhabited roof gardens. The shared Western
  city grammar supplies the street blocks, podiums and horizontal bands.
- **Secondary, about 20 percent:** desert shading, applied to terracotta
  fins, balcony screens and pale ceramic reveals. No imported pitched roofs,
  historic ornament or unrelated wall system.
- **Landmark accent, about 5 percent:** the already planned tower systems:
  wind-driven twisting triangle, plug-in capsules and dune balcony profiles.
  These distinguish the three towers; ordinary mid-rises do not copy them.
- **Palette:** pale ceramic/stone structure about 60 percent; recessed dark
  blue-green glass and shade about 30; jade, terracotta, cobalt and restrained
  gold/coral about 10. The north tower's capsules deliberately concentrate
  colour. Use `DOWNTOWN.palette`, not an unrelated rainbow per building.
- **Kit:** flat 0.24 m slabs, 1.2 m parapets; fitted 3.6 m nominal facade
  bays; 0.36 m piers and 0.24 m shade heads; 0.6 m recess; square-ended
  exponent-5.5 SuperEgg structure; rounded modular openings from shared
  cutters. All parts and bearing/cutting joins live in `DOWNTOWN`.
- **Hierarchy:** mid-rises form a repeated shaded base; Windspire is tallest
  with terracotta verticals and open wind slots; north is stepped coloured
  ceramic; south is pale, horizontal and rippled. BLOCK stays P17's dark
  exception. Gardens/colonnades retain a public life at each tower's foot.
- **Variation:** mid-rise owner data fixes single-pier, paired-pier or
  recessed-bay rhythm and one accent; narrow infill receives fewer fitted
  bays. Upper heights and frontage dimensions vary with the locked lots.
- **Exclusions:** printed letters/words/numerals; market tile-house balconies
  pasted onto offices; Old Moy gypsum or crenellations; generic box towers
  with decorative grids; pinched stretched meshes; unsupported capsules or
  transfer gaps; rooftop props standing in for structural form.

| Element | Tradition / source | Application |
|---|---|---|
| Podium, colonnade, recessed bay | tropical modern city fabric | all mid-rises |
| Deep fin and screen | desert climate adaptation | named shading members |
| Twisted triangle and transfer slot | existing Windspire concept, city.md 7c | building 12 only |
| Plug-in studio and open garden floor | existing capsule-tower concept | building 14 only |
| Continuous rippling balcony | existing dune-tower concept | building 15 only |
