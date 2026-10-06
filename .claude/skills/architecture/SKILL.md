---
name: architecture
description: Design or revise Eleblorb buildings and their immediate plots after the settlement layout is fixed. Use for building programs, massing, facades, roofs, chimneys, openings, ramps, structural composition, and culturally coherent architectural style in the game's SuperEgg design language. For a whole village, census, economy, district, or civic layout, use settlement-design first.
---

# Architecture for Eleblorb: think like a planner and an architect, not a prop placer

Past rounds on Ohio and the Snow Village failed in one way: buildings were assembled as collections of props (a door here, a table there, a ramp wherever it fit) instead of being designed as places people use. The rules below are ordinary architectural practice, restated in this engine's units. Read the relevant sections before you place anything, and answer the "who uses this and how" questions in writing before touching code.

**Reference files (read the relevant one before designing).** `references/composition.md`: primary and secondary masses, roof types and when to use them, how to join roofs, dormers, facade design (plinth, pedestal, pilasters, quoins, string courses, entablature, pediment), openings and rhythm, chimneys, proportions. `references/features.md`: the catalogue of entrances (stoop, pent hood, porch, vestibule, portico, door case, veranda, loggia, arcade, cart hood), overhangs (eave, gable, jetty, cantilever, bellcast), balconies (Juliet, projecting, gallery, oriel, bay, hoist, external stair) and the roof, wall, plan, chimney and window variations that make houses siblings instead of clones; use it to give each building its own set. `references/glossary.md`: the architectural vocabulary (plan, structure, roofs, chimneys, facade, ornament, materials); use the real terms in briefs, code comments and reports. `references/styles.md`: real historic styles (English half-timber, Cotswold, Georgian, Arts and Crafts or Craftsman, Dutch, French Canadian, Alpine, Scandinavian log, Russian izba, Chinese, Japanese, Pueblo, stilt and tropical) with their signature features, what to leave out, and which blend. `references/cultures.md`: the method for designing a culture's architecture and a grammar for Ohio, the Snow Village, Rock and Ground, Fire, Ocean, Plant, Sky, the Chinese village and the Western city, plus how to invent a fantastical kingdom.

**Companion skills.** `interior-design` (furnishing and lighting rooms for the people who use them) and `landscaping` (gardens, hedges, trees, ground and water edges). Use this skill first for the plan, then those two for what fills the rooms and the grounds.

## 0a. Style charter: how a village stays cohesive

A settlement looks cohesive because its buildings share a **small closed vocabulary** used repeatedly, not because every building is identical. Before designing any building in a settlement, make sure a **style charter** exists for it in `docs/style_charters.md`. If one does not, write it first and get it approved.

A charter names:
1. **Primary style (70 to 80 percent)**: one real tradition from `references/styles.md` (or an invented one built with the method in `references/cultures.md`). It supplies the massing, roof form and pitch, and wall system.
2. **One secondary influence (15 to 20 percent)**, applied only to named elements (a door case, a gallery, a ridge ornament, a colour accent), never to roof form and wall system together.
3. **One accent (up to 5 percent)** reserved for landmarks.
4. **The closed kit of parts**: allowed roof types and a single pitch range, two or three wall materials in a fixed hierarchy, one window type family with fixed proportions, door types, chimney type, eave and gable details, one signature motif, a palette with a 60/30/10 split (walls, roof, trim and accent), the plinth height, the structural module.
5. **Hierarchy**: which buildings are polite (civic hall, inn, mill-owner's house) and which are vernacular, and which extra elements the polite ones may use.
6. **Exclusions**: elements that are explicitly forbidden because they belong to another tradition.

**Cohesion rules**
- One roof pitch band and one eave detail per settlement; variety comes from the roof type (gable, hip, lean-to) and size, not from random pitches.
- A detail must appear **at least three times** across the village to read as cultural; a detail that appears once is a landmark or a mistake.
- Variety comes from **program** (a smithy differs from a cottage because it works differently), not from style. Never differentiate buildings by giving each a different style.
- Mix only along **lines of shared ancestry** (see "Mixing styles without cacophony" in `references/styles.md`). Check every secondary influence against the conflicts list.
- Keep the colour palette and material set fixed; new buildings choose from it.
- Landmarks may break one rule, never three.

**Style audit (run on every design, and again on the finished render)**
1. For every visible element (roof form, chimney, window, door, porch, bracket, ornament, material, colour) name the **term** and the **tradition** it comes from. Write this as a short table in the design brief.
2. If an element is not in the charter's kit, either remove it or amend the charter on purpose.
3. Count the traditions on one building: more than two is a failure.
4. Squint at the village from the green: does the silhouette read as one people's work?
5. Compare two random buildings: do they share roof pitch, eave detail, window proportion, palette and motif, and do they also differ clearly in plan, porch, roof type, storeys, chimney and window arrangement? A village of identical boxes fails as surely as a village of mixed styles.

**Design brief (write before building anything)**: primary mass and its dimensions; secondary masses; roof types and pitch; plinth, middle and top; bays and openings (with terms); chimney type and position; porch or entrance type; materials and colours; ornament and where; which charter elements it uses. Use the glossary's real terms. Reports to the user use the same terms.

## 0b. Texture: shared language, individual houses

A village is made of **siblings, not clones**. The shared language (the charter) fixes what must stay the same; individuality comes from a controlled set of things that vary, each with a reason.

**Invariants (never vary within a settlement).** Roof pitch band, eave detail, plinth treatment, window proportions and frame style, material hierarchy, palette, structural module, signature motif.

**Variation axes (draw from these; see `references/features.md`).** Plan type (single range, L, T, outshut, attached workshop); footprint size and aspect; storeys (one, one and a half, two); ridge orientation relative to the lane (gable-on or side-on); roof type within the charter (gable, half-hip, cross-gable, catslide, lean-to); porch or entry type; balcony or bay type; chimney position and count; window grouping and rhythm; facade pattern (stone to plaster ratio, frame pattern, pargeting); age marks (an extension in a slightly different tone, a repaired patch, a settled lean of half a degree); colour chosen from the palette; plot placement (setback, angle within about 8 degrees of the lane, corner or mid-block); yard and garden layout; the occupant's own marks (a carved lintel, a trade sign, a planter, a laundry line).

**Rules**
- Each building differs **strongly on two or three axes and mildly on the rest**; no two neighbours share more than half their axes.
- Variety follows **program and story**: a smithy differs from a cottage because it works differently; a house has an extension because the family grew. Give each building a one-line history (core first, then extension) so its asymmetry has a reason.
- **Age gradient.** The oldest, most weathered, most irregular buildings stand near the green or the stream; newer, plainer ones toward the edges.
- **Silhouette lineup.** Draw or render the buildings side by side: each must be recognisable by outline alone, yet unmistakably from the same village.
- **Variation matrix.** Keep a matrix of buildings by axes in the charter (`docs/style_charters.md`) so differences are planned and checkable, not accidental.
- Landmarks may vary more; vernacular buildings stay inside the charter.

## 0. Process (do these in order)

For a whole settlement, use `settlement-design` first. Its approved civic
layout, route graph, plots, utilities, hazards, gameplay anchors, and building
programs are fixed inputs here.

1. **People and purposes.** For every building: who lives or works there, what
   happens through the day, who visits, what enters and leaves, and what is
   noisy, hazardous, public, private, or culturally important.
2. **Building program.** Write the room list, minimum sizes, adjacencies, access
   and privacy gradient. Confirm the settlement charter, then write the
   building's design brief in real architectural terms.
3. **Coordinated drawing set.** Draw every storey plan together, then at least
   one section, the roof plan, and the elevations. Check wall lines, floor and
   ceiling extents, voids, supports, ramps, services, roof bearings, ridges,
   valleys, drainage, and chimneys across all drawings. Never generate an upper
   floor or roof from dimensions unrelated to the walls below.
   On sloping ground, include a site section through the steepest axis and make
   the foundation, finished-floor datum, thresholds, retaining, and terrain
   cut part of that same drawing set.
4. **Details, interiors, and grounds.** Resolve joins and openings before using
   the companion interior and landscaping skills. Neither companion may move a
   route, doorway, service, hazard boundary, or room to rescue a weak plan.
5. **Validate and review.** Use the settlement validator plus targeted isolated
   renders at aerial, approach, eye, interior, traversal, and hazard levels.
   Do not require the whole world to stage merely to inspect one subsystem.

## 1. Engine units and hard constraints

- Grid cell 3.2 m (`TownProps.CELL_SIZE`). Storey height 3.25 m. Wall thickness 0.16 m (panel) or 0.45 m (mill masonry). Door 1.2 x 2.4 m, wide doors 2.0 to 2.8 m.
- Player and party bodies need **1.2 m minimum clear width** for a path, **1.5 m** where two people pass, **2.0 m clear in front of any door** on both sides. Blorbs and mounts are wider: treat 1.5 m as the real minimum in anything meant to be traversed.
- Interior ramps replace stairs (world convention): 32 degrees, 3.25 m rise = about 5.2 m run, 1.4 m wide, needs a **1.2 m clear landing at the foot and at the head**. The foot may not start against a wall or furniture.
- Design language: see section 1a. Every substantial solid also gets collision (see CLAUDE.md and `CollisionPolicy`).
- No in-game text that explains mechanics. Signs and boards carry carved symbols only.

### Foundations on sloping ground

- Survey the terrain at the footprint perimeter, center, doors, and route
  landings before choosing the floor elevation. Never place at center height and
  push the building down until it looks approximately grounded.
- The foundation is architecture: a plinth, stepped podium, basement or
  bedrock wall with a coherent material, section, and relationship to the
  facade. A thin masking skirt is forbidden.
- Extend the structural base below the lowest adjacent terrain by a documented
  embed margin. Cut or exclude terrain beneath the authored footprint so the
  building floor is the only collision there; two nearly coplanar walkable
  colliders produce hovering, snagging, and floor changes.
- Meet every public and service route at a level landing. If the slope is too
  great for one base, step the podium or split the mass rather than creating a
  giant blank wall or an arbitrary ramp.
- Use stilts only when the culture, material, and environmental logic call for
  a genuinely raised structure. A modern building on rock normally uses an
  embedded foundation, retaining wall, buttress, or engineered cantilever.
- Build visible foundation, collision, terrain exclusion, retaining edges, and
  drainage from the same authored footprint and site section.

## 1a. Design language: SuperEgg and the superellipse, everywhere it is practical

SuperEgg forms and superellipse outlines are the defining visual language of this game. Soft, rounded, slightly swollen solids with confident silhouettes are what make a settlement look like Eleblorb and not like a generic low-poly kit. The default answer to "what shape is this?" is **a SuperEgg** (`SuperEgg.build_part`) or a **superellipse outline**; plain boxes and flat slabs are the exception that needs a reason.

**Use SuperEgg or a superellipse for anything visible and freestanding:**
- Posts, columns, beams, rails, lintels, brackets, ridge caps, corner posts, sills, shutters, benches, tables, counters, beds, chests, barrels, sacks, stools, crates, stall parts, logs, stacked timber, roof slabs, dormers, canopies, chimney stacks and caps, steps, troughs, stone blocks, hedges, mounds, domes, bells.
- Every opening a person sees: doors (square foot, rounded head), windows, hatches, bays, arches, and **the hole in an upper floor for a stair or ramp** (a superellipse hole, not a rectangular notch). Frame them with piped superellipses (see `OpeningTrim`), embedded in the wall and visible on both faces.
- Outlines of yards, ponds, greens, platforms and paint patches: irregular rounded shapes, not rectangles, wherever the program allows.

**Choose the epsilon by role.** `EPSILON_FLAT` (5.5) for squarish structural members (posts, beams, rails, slabs) so they read as timber and stone yet keep a softened edge. `EPSILON_SOFT` (3.0) for rounded furniture and mounds. About 2.0 (an ellipsoid) for naturally round things: bells, barrels, domes, stools, sacks. Columns and posts always sit at the square end.

**Where SuperEgg is impractical, say so and use the next best thing.** A SuperEgg rounds its corners, so two of them never meet flush. Use a plain box, Boolean-cut solid or other fill only where a SuperEgg would leave a gap or a visible crack:
- **Floors and ceilings.** A rounded slab leaves open corners at the walls, so floors use plain slabs that fill to the wall.
- **Wall planes.** Walls are single solid slabs with Boolean-punched superellipse openings (`SolidModel`), so there is no tiled seam.
- **Seams between rounded solids** (the ridge of a gable, a wall corner, the joint of two rafters): do not leave the gap. Either **Boolean-subtract** the overlap so the cut faces meet in one solid line (roof slabs are cut where they reach the ridge so they meet along it with no gap and no overlap, then baked), or bury the seam under a square-edged SuperEgg cap (ridge beam, corner post) that spans it.
- **Free wall ends and T-junctions.** A slab wall that simply stops, or meets another wall at a T, shows a bare cut edge. Cap every such end with a small square-edged SuperEgg post the full height of the wall (`TownProps.build_interior_wall` does this for interior walls; exterior corners already use corner posts), so it reads as a pilaster or a post and never as a cut slab.
- **Gap-fillers and hidden structure:** collision proxies, ground fills, wedges of gable infill, anything the player cannot see.
- Large ground paint (worn paths, cobbles) is a decal, not geometry.

**The test.** Squint at any element more than a metre across. If a prominent edge is a hard rectangle and nothing structural forces it, rebuild it as a SuperEgg or superellipse. If a rounded element leaves a gap against its neighbour, fix the seam with a Boolean cut or a square cap. Never ship the middle ground of a rounded rectangle slab that merely looks like a box and does not join its neighbours. Never leave a wall ending bare.

## 2. Town planning principles

- **Hierarchy of ways.** One main road (arrival road), a few lanes off it, then service tracks and yard aprons. Widths: road 4 m, lane 2.5 to 3 m, service 2 m. Paths run along desire lines between real destinations: a door, a gate, a well, a bench, a stall, a yard, the green. **Every path ends at a destination, and wherever two worn areas lie close together they are joined**, because the people who made them walk between the two. Plan the circulation first (who goes from where to where, and by what route), then draw the worn ground along those flows. Never leave a small strip of unworn grass between a path and another path, a worn yard, a doorstep or a gate that traffic obviously crosses; and never run a path toward a destination and stop short of it. A path does not need to continue past its destination.
- **Public heart.** One green or square, irregular, with the well or fountain off-centre of the routes. Civic building and market face it. Nothing turns its back on it except service buildings.
- **Frontage.** A building's front door faces the way people arrive (road, green or lane), never a neighbour's wall or a fence. The rear faces the yard, garden or service lane and carries the back door where the program needs one.
- **Orientation of civic objects.** Notice boards, wells, benches and signs face the approach that reads them (the square, the road), standing beside circulation, not in it.
- **Spacing.** At least 4 m between neighbouring buildings where people must pass, never less than 3 m. Never overlap footprints. Eaves overhang adds 0.3 m each side: measure to the eave, not the wall. Leave 1.5 m behind a stall for the seller and 2 m in front for customers.
- **Market.** One continuous frontage along the green: stalls in a row, the steward's hall at the head, the noisy forge at one end, food near the inn. Stalls belong to a named seller whose shop or house is directly behind them. Orphan stalls with no seller are clutter.
- **Trade and provenance: the inventory tells a story.** Every purchasable item on a stall or shelf has a source the player could trace. Write the chain down before stocking anything: *who* makes or gathers it, *where* (a building that exists on the plan, with the tools and materials of that trade visible inside it), *from what* (named inputs: flour from the miller, pitch from the sawmill, wool from the textile house), and *who carries it* to the stall (a named runner, a handcart route, a schedule stop). A stall is the open sales face of a workshop or the commission shelf of a household, never a free-standing source of goods. A seller who sells something she does not make says so in the data (a commission, a barter, a carrier), and her dialogue or a neighbour's mentions it once, diegetically and without explaining mechanics. Keep the chain in a **trade ledger** in the settlement's plan file (`OhioPlan.TRADE`, `SnowPlan.TRADE`): vendor, shop category, and for every purchasable item `from`, `at` and `carried_by`. The validator fails when a stall sells an item the ledger does not explain, when the maker's building does not exist, or when an item arrives from outside the village with nobody to carry it in. The same ledger drives what is physically visible: a baker's shelves hold what her stall sells, a smith's rack what hers does. Check provenance whenever a shop catalog entry changes (`scripts/shop_catalog.gd`).
- **Industry and water.** Mills and timber yards sit on water; the race runs upstream to downstream and never uphill. Smoke and noise (forge, bakery oven) sit at the edge, ideally downwind. Fire hazards keep 6 m from granaries and timber stacks.
- **Agricultural edge.** Gardens, orchards and paddocks sit behind houses. A garden has a gate that lines up with the house's rear door. Rows in a garden make sense only as beds with paths between them and a reason (herbs, vegetables), never as scattered single plants.
- **Fences, hedges and gates.** A fence or hedge encloses something: a yard, a garden, a paddock. A yard that belongs to a house **abuts the house wall**: the side against the house is left open (the fence or hedge ends at the wall, the building is that side), so the back door opens straight into the yard with nothing to close on it. The **gate faces the path or lane** that serves the yard, on another side, never toward the house's own door, and always lines up with a worn path; it is 3.2 m clear for carts, 1.2 m for a garden wicket, with a hinge post and a latch post. Posts every 2 m, rails continuous, height 1.1 to 1.2 m. A yard whose only way in is through the house is a mistake.
- **Plots.** A plot is house plus yard plus access. Pick the plot first, then fit the building to it. Houses on a lane share a front line; do not scatter them at random angles.

## 3. Building programs by type

Sizes are interior, in metres. Keep every room at least the minimum.

**Cottage (1 to 3 people).** Hall/kitchen with the hearth (4 x 4.5, the room people live in), a sleeping room or sleeping loft (3 x 3), a store or pantry (2 x 2). Entry opens into the hall beside the hearth wall, never straight onto a bed. Hearth on a gable wall. One small window per room, a larger one in the hall.

**Family or two-storey house.** Ground: entry lobby or passage (1.5 wide), hall with hearth, kitchen or scullery at the rear, parlour or workroom. Stair/ramp next to the entry or the hearth stack. Upper: a **landing hall that opens into rooms** (never a cubicle maze): two or three bedrooms (3 x 3.5 each), the chimney stack passing through the room it warms. Roof space above is unused attic.

### Coordinating multiple storeys

- The upper floor plate is also the ceiling of the storey below. It reaches the
  inner face of the enclosing walls with no visible gap, except at deliberate
  double-height rooms, ramp wells, light wells, or shafts shown on both plans.
- A projecting upper storey is a named jetty, cantilever, bay, gallery, or other
  deliberate mass. Give it joists, brackets, beams, walls, and roof support. An
  unexplained floating oversize floor is not architectural variety.
- Heavy or load-bearing upper walls (masonry, log cross-walls, walls carrying
  a roof or floor) bear on walls, columns, or explicit transfer beams below.
  Light upper partitions may sit on the floor joists with no wall beneath, as
  they do in real buildings. Columns never end on empty ceiling unless the
  structure visibly explains the transfer.
- Cut openings once and use the same boundary for visible floor mesh,
  collision, railing, ramp or shaft clearance, and the room plan. Independent
  approximated holes produce ledges, gaps, and blocked heads.
- Coordinate chimneys, ducts, plumbing, and other vertical services through
  every storey and the roof. A stack cannot jump sideways between floors.
- Derive each floor and ceiling from the same authored footprint and wall
  boundaries used by the plan. Derive the roof bearing line from the
  top-storey walls. Do not maintain separate magic dimensions in furnishing or
  roof code.

### The stacking drill: draw the floors against each other before any room

A plan is one drawing of a stack, not a floor plan per floor. Do these in order,
on one grid, before placing a wall.

1. **Fix the shared lines.** Pick the structural lines (z and x positions) that
   both floors will use. A ground partition and the upper corridor wall above it
   stand on the same line; upper dividers stand over ground walls or over a
   named beam with posts. Write the lines down; do not let each floor invent its
   own numbers. (The Holt Inn's first plan had upper dividers at x = -2.0 and
   4.65 over ground walls at x = -3.4 and 2.6, so eleven upper walls stood on
   nothing.)
2. **Subtract the voids first.** A double-height hall, stairwell or light well
   removes floor area from the storey it opens into. Draw the void, then draw
   the rail, then the gallery or landing that surrounds it, and only then fit
   rooms in what is left. A void must lie wholly inside one ground room: **no
   ground wall may run under it**, because that wall's top would stand free in
   the opening (the inn's rear partition did, for 4.2 m). Size the void so the
   gallery between rail and the nearest wall is at least 1.4 m (1.2 m is the
   minimum, not a design target).
3. **Carry the heavy walls.** A light partition may stand on the floor joists.
   Where a heavy or load-bearing upper wall crosses an open ground room (a
   common room, a workshop), give it an exposed summer beam and posts at no
   more than 5 to 6 m, and draw the posts as obstacles on the lower plan. If
   that frame would ruin the lower room, move the wall to a line that is
   already carried instead.
4. **Check the program against what is left.** After the void, the gallery and
   the structural lines, count the rooms that still fit at their minimum sizes.
   If the program no longer fits, **change the program** (fewer rooms, a
   smaller dormitory, a shared washroom), never the minimums. A hall of rented
   rooms needs a corridor people can walk comfortably, doors they can reach, and
   no squeezing between a rail and a wall.
5. **Align the services.** Chimney, flue, ducts and plumbing run straight
   through every storey; place windows symmetrically about a centred stack and
   inside rooms, never across a partition.

`ClearZones.audit_stacking` (run by `tools/validate_village.gd`) fails a wall that
rises into the opening above it (its top would stand bare in the void) and a wall
standing over a hole in its own floor. It does not fail an upper partition with
no wall under it. TownProps registers walls and voids automatically; beams and
posts can still be recorded with `ClearZones.add_support`.

### Doors, swing and circulation widths

- **A door swings into the room it serves**, never into a corridor or gallery,
  and never onto furniture, a ramp foot or another door. In this engine a door in
  a wall opens toward the wall's local -Z, the left of the direction it is drawn:
  draw each partition so its left side is the room the doors belong to
  (`build_interior_wall` from the corridor side outward, or reversed). Check
  the swing arc, not only the clear zone.
- **Every door has a clear zone of about 1.25 m on both sides** (its leaf's
  swing plus a person standing to open it), registered with `ClearZones.add`;
  `TownProps` does this for every exterior and interior door and every window.
- **Widths.** A corridor, gallery or landing is 1.4 m (minimum 1.2 m: two people
  passing). A doorway is 1.0 m clear for a room, 1.2 m for a main room, 2.0 m or
  more for a public double door. Rails and rail posts count against a gallery's
  width. The validator walks registered routes with a person-sized cylinder:
  1.1 m wide along corridors (`ClearZones.add_lane` radius 0.55), a body's width
  through doorways.
- **Ramps**: 2.0 m of headroom along the whole run (a deck or beam over a ramp's
  upper half is the usual failure), a landing at each end, and nothing standing
  in either foot.
- **Door frames and jamb ends bury only in the floor they stand on.** An interior
  frame sinks 0.04 m; on an upper floor a deeper sink shows as pipes below the
  ceiling of the room underneath.

### Heat and air

Architects plan how a building keeps warm and breathes; do the same.

- A two-storey house has a fireplace on **each** floor, stacked on one flue
  (`"floor": 1` opening in `Hearth.build_chimney_wall`), never a bare chimney
  column through the bedroom. A workshop's fire is the trade's fire: a smith
  gets a raised hooded forge (`"kind": "forge"`), not a domestic grate. Corner
  (angled) fireplaces are part of the repertoire: a diagonal breast across a
  corner with the flue rising in the corner (planned, not yet built).
- The hearth is the building's stove. Put the chimney **on the shared wall** of
  the rooms it should warm, and let the flue pass through every storey so the
  masonry heats the rooms above as it rises. A double-height hearth hall lets
  warm air rise into the gallery; bedrooms on that gallery are the warm ones, so
  put the rooms people pay for beside the stack, and cold storage (larder,
  cache, privy) on the cold side.
- Keep a fire's surround free of timber and seating (`ClearZones` kind "fire",
  1.35 m deep); a fire that follows the clock (`HearthFire`) is lit when people
  need it, not all day.
- Doors that must stay shut for warmth (kitchen, bedrooms) are leaf doors; rooms
  that share a use and a fire are open to one another. A transom or grille above
  a door is the way to pass warm air into an enclosed room.
- Roof spaces vent at the ridge and eaves; kitchens and washrooms get a window or
  a vent to the outside wall; nothing vents into another room.


**Workshop-home (joiner, mason, smith, baker, miller).** The workshop takes the front or the side facing the working yard, with the largest opening (a cart or work bay). The living quarters sit behind or above, with their own quiet door. The hearth or oven is the heart of the trade. A rear yard holds materials and fuel. Visitors and customers meet the trade at the front; family uses the rear.

**Inn (hospitality).** Think of the guest's journey: arrival, being met, eating, sleeping, washing, leaving.
- Entry through a small vestibule or porch into the **common room**: big, warm, with the hearth on the gable wall, tables with benches arranged in groups with 1.2 m between, a clear route from the door to the counter and to the hearth.
- **Counter** at the side or rear of the common room, 2.5 m or more away from the door so the entry is never crowded, with the keeper's space behind it (1.0 m minimum) and an **office or keeper's room directly behind** for the books, keys and strongbox.
- **Kitchen and pantry** adjoin the common room with a serving hatch or door, and have their own door to a service yard (wood, water, deliveries). Cellar or stores off the kitchen.
- **Guest rooms upstairs** along a landing corridor (1.4 m), each 2.4 to 3.0 x 3.5 m with a bed, a chest and a window. The party room can be larger. Heads of beds against walls.
- **Toilet** in its own closet or washroom (see "Toilets at every resting place" below), against an outside wall, reached from the guest side without passing through a private room, with the seat's back to the wall. Never in the middle of a room.
- **Owner's room** upstairs or beside the office, small and private.
- Stable or yard to the side or rear. A bench or porch at the front for waiting.
- The inn stands on the arrival road, near the green, not on it.

**Toilets at every resting place.** Every rest point (an inn, guest house,
guest hall, houseboat, or anywhere the party sleeps and wakes) has at least one
toilet, without exception. The fixture belongs to the culture that built the
place:
- **A modern culture gets modern fixtures:** a flush toilet with its cistern, a
  washbasin with a tap, a mirror, and a shower where guests stay overnight.
- **A layered culture counts as modern.** Several settlements are old
  traditions living in the present day: quaint old-timey towns with old-timey
  trades whose people wear t-shirts and have today's comforts (Ohio, Kai Mālie,
  the Snow Village). Their buildings keep their historic style, and their
  bathrooms are modern: a porcelain flush toilet in a half-timbered inn is
  correct there, not an anachronism.
- **A culture that genuinely lives in the past gets its own tradition's
  fixture,** named by its real term in the brief: a privy or earth closet, a lidded commode, a composting
  vault, a ship's head. It is never a generic modern bowl dropped into a
  genuinely historic culture, nor a porcelain pedestal in a hut. Check the
  settlement's brief and the world bible for which kind it is.
- **A people who do not need toilets themselves** (lava people, cloud people,
  merfolk in water) still give their guests one, built in their own materials
  and technology.

Placement and services:
- The toilet stands in an enclosed closet or washroom with a hung door, at
  least 1.2 × 1.6 m for a closet, and has somewhere to wash hands.
- Guests reach it from their rooms or the common room without passing through
  the keeper's private rooms or the kitchen.
- Waste goes somewhere believable: a sewer, septic tank or holding tank for
  modern places; a removable pail, vault or vat emptied to compost or fields for
  traditional ones. Nothing ever discharges into water near homes, swimmers,
  fishing grounds or drinking water, or drops from a height onto a place people
  walk.
- Write the fixture, its term, its enclosure and where the waste goes into
  every rest point's brief.

**Civic hall (meeting house and archive).** One tall hall, double height under the roof, benches along the walls, a raised end with the reeve's table, a hearth, a porch with a pediment to signal civic dignity. Beside it: records room (strongroom, dry, few windows), a clerk's or teacher's room, perhaps a small school corner. The bell sits in a proper belfry or turret (open frame, visible bell shape, pull rope), not a disc on the roof. It faces the green on its long side. A church would have a nave and chancel on an east-west axis and a tower; this world has a meeting house.

**Smithy.** Open bay to the street. The forge, anvil and quench trough form a triangle with 1.2 m between. Stone floor and a large masonry stack; no timber near the hearth. Fuel and iron stores beside it. The seller's frontage is the working bay, not a detached stall.

**Bakehouse.** The oven is a masonry mass against an outer or gable wall with the chimney above. Dry flour store, a work table, a shop hatch or counter to the street, a rear loading door to the yard, a handcart.

**Mill.** Water mill: wheel on one wall, race beneath, the machinery in the dry half, the miller's living space separate. Windmill: round or octagonal tower, the entry on the lee side, grinding floor at the base, stone floor above, the cap and sails above that; sails are lattice frames with canvas, pitched about 17 degrees. Granary beside it, raised on staddles, with a cart shelter and yard.

**Outbuildings.** Granary (raised, vented, secure), storehouse (strong door, no windows to the road), drying shed (open slatted sides), barn (large cart door, hayloft), privy (back to a wall, away from wells). Each sits where its job puts it, not wherever there was space.

## 4. Roofs, walls and chimneys (summary; the full vocabulary is in `references/composition.md`)

- **Gable roof** at about 30 degrees here. The two SuperEgg slabs are Boolean-cut where they reach the ridge so their cut faces meet in one solid line, with no gap and no overlap (see section 1a); then cap the ridge with a square-edged SuperEgg beam in the roof's own colour. Eaves overhang 0.3 m.
- **Cross-gables and dormers** exist only where a room beneath needs light or headroom. A dormer above an unoccupied attic is a lie.
- **Chimney and fireplace: one mass, built into the wall.** A fireplace is not a hearth set in front of a stack. It is a single masonry mass in the gable wall (`Hearth.build_chimney_wall`): inside, a breast projecting from the wall with a **large superellipse opening** (three sides, clipped by the floor, wider than 1.6 m so the fire uses the height of the room), rising and narrowing like a funnel toward the flue; passing **through** the wall as the same masonry; continuing outside as a stepped stack with set-offs that clears the ridge by 0.8 m. One building has **one chimney**: a hall fire and a kitchen range or a bread oven share one breast and one stack as two openings in it, over the pier where the partition meets the wall. Never two separate fireplaces in two rooms of one small house.
- **Hearth bay.** Where a great hall or inn has the hearth, let that bay run double height up into the roof, with the upper floor stopping short of it.
- **Second floors** do not have to cover the whole footprint. Leave voids for tall spaces and the hearth bay.
- **Roof plan is mandatory.** Draw the outline from the actual top-storey wall
  bearing lines, then add the charter's eave overhang. Locate every ridge, hip,
  valley, low point, drain, chimney penetration, dormer, and junction with a
  secondary mass. If these lines cannot be drawn cleanly in plan and section,
  the roof form is unresolved and should not be generated yet.
- **Shutters** belong on narrow casements only, on dwellings and inns, never on halls, workshops, sheds or wide windows. By default they are drawn open, lying flat against the wall either side of the window like the covers of an open book, never swung out into the street, each with a raised panel and a small cut (a diamond) so the visible face has life. A wide window gets mullions, a hood mould and a window box instead; a pair of giant shutters is absurd and hides signs.
- **Openings** are punched through thick walls and framed on both faces. Windows serve rooms: large windows on the front main room, small ones to service rooms and the rear, one gable light for an occupied upper room. Never put a window where furniture, a flue or a sign covers it. No windows on the hearth wall.
- **Entries by purpose:** pent canopy for homes, a gabled portico with pediment for the hall, a deep awning over a forge, a hooded cart bay for mills, a shop awning for a bakery, a veranda for an inn. Every roof falls away from the wall. Posts are square, reach their beam and never stand in front of a door.

## 5. Interior planning

- **Walls and partitions run floor to ceiling.** If a partition stops short it reads as a cubicle. Prefer a few big rooms with real doorways over many small partitioned ones.
- **Doorways are framed openings, and a door only where one is needed.** Every opening between rooms is a superellipse-headed opening punched through a full-height wall (`TownProps.build_interior_wall`), with piped frames on both faces: 1.0 m wide and 2.3 m high for a door, clear of the corner by at least 0.6 m. It gets a **hung leaf** where something needs closing: privacy (bedrooms, office, privy), heat, noise or smell (kitchen), security (strongroom, larder). It stays an **open archway** (`archways`, 1.7 m wide) where the spaces share a use: a vestibule into the room it serves, a passage between two parts of one room, a hearth bay. A bare gap, a lintel floating over nothing, or a partition that stops short is never acceptable. Plan each leaf's swing so it never opens onto furniture, ramp feet or another door.
- **Partitions under a pitched roof.** A partition on an upper floor with an open roof above runs **up to the rafters**: a wall that runs along the ridge rises to the roof's underside where it stands, a cross wall is gable-shaped following both slopes (pass `roof` to `build_interior_wall`). A wall that stops at storey height under an open roof is a cubicle wall and always wrong. The alternative is a flat ceiling at storey height with the roof space above; never both half-done.
- **Every room is reachable.** No door opens onto a wall, a bench, a bed or another room's door; every room has a door from a circulation space (hall, landing, corridor, or the room it belongs to); check each door's 1.2 m by 2 m clear zone on both sides before placing furniture.
- **Circulation first, furniture second.** Draw the routes (door to hearth, door to stairs, door to each room) and keep 1.2 m clear on them; then place furniture around the routes against the walls. Nothing blocks a door swing or the foot of a ramp.
- **Furniture rules.** Beds: head to the wall, 0.6 m access on at least one long side. Toilets: back to a wall, 0.6 m clear either side and in front. Tables: 0.8 m clear all round. Counters: 1.0 m behind, 1.2 m in front. Hearth: 1.2 m clear in front. A chest or shelf stands against a wall.
- **A ramp needs the depth for its run.** A 32 degree ramp climbing 3.25 m runs 5.2 m, plus 0.9 m before it and a clear landing of at least 1.2 m (prefer 3 m) at its head, where you step off onto the floor with nothing in the way: a house with a stair is at least three cells (9.6 m) deep. Rails are balustrades (a top rail on slender posts), never slabs, along the sides that are open, **not** across the head; the ramp never ends against a wall.
- **Stair or ramp placement.** Near the entry or the hearth stack, entered from a hall or lobby, with clear landings. It opens into the upper floor through a **superellipse hole**, rails on the open sides, headroom 2.0 m.
- **Light.** Every occupied room has a window. Work surfaces sit near light.
- **Privacy gradient.** Public (common room, workshop, hall), then semi-private (kitchen, office), then private (bedrooms, owner's room).

## 6. Quick dimension reference

| Element | Value |
|---|---|
| Door, clear | 1.2 x 2.4 m (double 2.0, cart 2.8 x 3.0) |
| Corridor or landing | 1.4 m |
| Bed | 1.6 x 2.4 m footprint |
| Table for four | 1.7 x 1.0 m, benches 0.4 m |
| Counter | 0.5 to 1.0 m deep |
| Hearth opening | 1.05 m wide, breast 1.9 m |
| Ramp | 32 degrees, 1.4 m wide, 5.2 m run per storey |
| Roof pitch | 30 degrees |

## 7. Mistakes that have actually shipped

Buildings overlapping or sitting 1 m apart; a door facing a neighbour's wall; a back door opening into another building's only door; a notice board facing a building; a stall jammed between two buildings; a path that stops a few metres short of a worn yard or doorstep, leaving a strip of unworn grass in the line of traffic; a garden of scattered single flowers; a toilet in the middle of a room; a ramp starting against the wall; a counter beside the entry; partitions that stop short of the ceiling; doorways that are bare gaps in a wall or a slab floating over a gap instead of a proper door; rectangular floor holes; a free-standing slab posing as a chimney; round columns; rounded rectangles standing in for SuperEggs, or SuperEgg slabs left with a gap at the ridge; a rectangular stair hole; a roof ornament that does not read as a belfry; an enclosure with no gate or a gate that does not line up with the door. A ground wall running up into a double-height opening so its top stands free in the void; a heavy upper wall standing on nothing; upper floors planned without the void, so the gallery beside it is a 1.0 m gap between rail and wall; doors that swing into the corridor; furniture standing in a doorway, a ramp foot or the heat of a fire; door-frame pipes sunk through an upper floor into the room below; a chest at a bed's foot with its hinge turned away from the bed.

## 7a. Placement of outside props

Every outside prop (woodstack, bench, trellis, barrel, handcart) stands **clear of the wall it belongs to**, never intersecting it: measure the prop's real extent (a log pile lies along its local Z) against the wall's outer face. Props never cover a window, a door's clear zone or a sign. Props along a wall sit beside windows, not across them.

## 7b. Siting a mill

A mill sits **on the settlement's side of the water it uses**, along the course of the leat or aqueduct, and its door faces the way people arrive; nothing (a bridge, the race) lies between the road and the door. Run the water from its source toward the point on the rim nearest the settlement, and place the mill along that run, as close to the settlement as the fall allows.

## 8. Review checklist

0. The building reads as a hierarchy of masses (one dominant primary mass, secondary masses lower or set back), its roofs join correctly with one pitch, its facade has a base, middle and top, and its entrance is the focal point (see `references/composition.md`). In a kingdom with its own culture, the culture's grammar is applied (see `references/cultures.md`).
0a. Every storey plan, the building section, elevations, and roof plan agree:
upper floor plates form the ceilings below, intentional voids share one exact
boundary across mesh and collision, upper walls have support, and the roof
bears on the actual top-storey walls.
1. Footprints (including eaves) do not overlap; every pair of neighbours leaves at least 3 m, or 1.5 m where only maintenance passes.
2. Every door can be walked up to and through from a path, on both sides, with 2 m clear; every enclosure has a gate that lines up with what it serves.
3. Circulation is planned first: every path runs to a destination (door, gate, well, bench, stall, yard), and wherever worn areas lie close together they are connected, so no gap of unworn grass interrupts a flow of traffic.
4. Civic objects face the space that reads them.
5. Every interior doorway is a framed, leaf-hung superellipse opening in a full-height wall, never a gap or a stub partition. Each room matches its program (size, adjacency, privacy), and the inn, hall and workshops each have the rooms in section 3.
6. Circulation: 1.2 m clear on every route; ramp feet and heads have 1.2 m landings; furniture is against walls and does not block swings.
7. Openings are superellipse, framed in the building's own timber and stone (accent colour only on shutters and door leaf), shuttered only where the building is a dwelling or inn, and placed to light rooms; none is covered.
8. Roof slabs are Boolean-cut to meet along the ridge with no gap, the chimney is built into the gable wall and clears the ridge, columns are square-edged SuperEggs that reach their beams.
8a. Design language: freestanding visible parts are SuperEggs, every opening a person sees is a superellipse, and any plain box has a stated reason (floor, wall plane, seam fill, hidden structure).
8b. Every roof ridge, hip, valley, dormer, chimney penetration, and secondary
roof junction appears in the roof plan and drains away from walls and openings;
no roof volume is positioned independently of its supporting mass.
9. Render interior shots of each building type and read them as plans: can you tell what each room is for?
10. Record any new fact about a person, place or building in `docs/world_bible.md`.
11a. Every rest point has a toilet in an enclosed closet or washroom, with a fixture true to its culture and era (modern fixtures for a modern culture) and a believable place for the waste to go.
11. Trade provenance: every stall and shop item is in the settlement's trade ledger with a maker, a building, inputs and a carrier, and the validator passes the ledger check.


## Standing rules from the Ohio and Snow walkthroughs (2026-10-04 and 05)

Each is enforced by `tools/validate_village.gd`; run it on a scratch copy of the
project (`docs/handoff_ohio_village.md`, "Tools you now have") before reporting.

- Never author a yaw for a lantern, sign or door; derive it from the point it
  serves (`VillageWorks.yaw_facing`). A piece's back is local +Z and its front
  local -Z (settles, shelves, chests with their hinge, desks, peg rails); a bed
  is built head toward -Z, so a bed placed head to the wall is built at yaw + PI
  and a chest at its foot has its back (hinge) toward the bed.
- Register a clear zone (`ClearZones.add`) for every door, ramp, window and fire,
  and a lane (`add_lane`) for every route; place furniture through `RoomLayout`;
  the audit fails furniture in a zone, inside a wall, and routes that are too
  narrow, too low or blocked.
- Draw the floors against each other (the stacking drill above); the audit fails
  walls that rise into a void or stand on nothing.
- A hearth is one masonry body that passes through the wall, centred on its gable,
  with a real firebox floor and a fire that follows the clock (`HearthFire`).
- A roof post ends under the slab on the slope; walls under a pent roof are cut to
  it; door-frame jambs bury only in their own slab.
- People stand where they can be seen to be doing something: a stop's wander range
  scales with its size, and two residents never share a stop.
