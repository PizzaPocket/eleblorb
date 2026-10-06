---
name: interior-design
description: Furnishing, dressing and lighting the inside of any Eleblorb building (homes, inn, hall, workshops, mills, shops). Use AFTER the architecture skill has fixed the plan and BEFORE placing furniture, props, lights or decor. Makes interiors feel lived in, specific to the people who live or work there, and pleasant where they should be, using SuperEgg parts and the engine's clearance rules.
---

# Interior design for Eleblorb: rooms that belong to someone

An interior is evidence of a person. Before placing a single prop, decide whose room it is, what they do in it, what their body actually needs, what they own, what they love, how much they have, and what a stranger would learn by walking through. Two sad tables in a big room tell the stranger nothing. Read the `architecture` skill first: the settlement plan, room program, circulation, services, hazards, and clearances are fixed inputs here, not suggestions. Record any new fact about a person in `docs/world_bible.md`.

## 0. Process

1. **Occupant brief.** Who lives or works here (the bible names them): trade, wealth, age, habits, quirks, who else uses the room, what they would be doing right now.
2. **Room function.** What happens in this room, in what order, at what hours.
   Do not assume human furniture or domestic rituals for a non-human resident;
   derive rest, nourishment, hygiene, work, storage, and comfort from the
   approved physiology and culture brief.
3. **Anchors.** The hearth, the window light, the door. Furniture groups form around these.
4. **Layers** (section 2), placed in order: structure, necessities, work, personal, wear, light.
5. **Walk it.** Render eye-level shots (`tools/village_aerial_capture.gd --shots=`). Can you read who lives here? Is the route from door to hearth clear? Does it feel warm and a little crowded, or empty and staged?

## 1. Principles

- **Doors are doors.** Interior doorways are framed superellipse openings in full-height walls with a hung leaf (see the architecture skill); dress both sides of a door (a hook for a coat, a mat, a lamp) and keep its swing clear.
- **Specific over generic.** Every room has at least three items that only this occupant would own (Halda's ledgers, Dorran's clamps and a crooked-roof sketch, Wren's drying bundles, Cob's flour-dusted sacks).
- **Lived in, not cluttered.** Aim for roughly a third of the floor covered by furniture and rugs, walls dressed to eye height, nothing in the circulation lanes. Dense in the zones people use, clear in the paths between them.
- **Wall-anchored first.** Large pieces (beds, cupboards, shelving, chests, benches) stand against walls; free-standing pieces (a table, a work bench) form groups with 0.8 m clear around them. Never leave one piece stranded in the middle of a big room.
- **Group by activity.** Eat (table, benches, hearth), cook (hearth, pot rack, pantry), sleep (bed, chest, hooks), work (bench, tools, stock), receive (counter, chairs, ledgers). Each group has its own small light and its own small clutter.
- **Asymmetry and overlap.** A lived-in room is never mirrored. Vary heights (a jug on a shelf, a hanging pan, a stool), overlap items slightly (a blanket over a chest lid, a cloth on a table edge), lean things on walls.
- **Wealth and age tell.** A well-off inn keeper has glazed lamps, a good rug, a carved sideboard; a retired hedger has a patched blanket, a worn chair, a pipe, and a stack of neatly kept tools. Newcomers keep little; long residents accumulate.
- **Pleasant means warm.** Warm light low in the room, a focal hearth, textiles (rugs, blankets, cushions, curtains), natural materials, a view out of a window, a place to sit by the fire, no bare dark corners. A sparse stone box is not "cozy" however many tables it holds.
- **Diegetic only.** No text, no instruction. Books, ledgers and signs show shape and colour, not words.
- **Services are lived architecture.** Heat, water, ventilation, drainage,
  pressure relief, molten material, or other civic systems appear where people
  inspect and use them. Do not add fake exposed pipes, controls, or machinery
  merely to imply technology.

## 1a. Circulation, swing and facing come before furniture

Interior designers draw the routes and the door swings first, because the
furniture is what is left. Past rounds shipped furniture standing in doorways,
on ramp feet and in front of fires; the checks below now fail those, so work to
them.

1. **Take the plan as given** (see the `architecture` skill's stacking drill):
   the walls, door swings, ramp, stair hole and chimney are fixed inputs.
2. **Draw the routes and door swings** on the plan before any piece: door to
   hearth, door to stairs, door to each room, kitchen to common room. A route is
   1.1 m wide (two people passing) in a corridor, a body's width through a door.
   Each door's swing arc plus a standing person (about 1.25 m on both sides) is a
   keep-clear rectangle. A fire's keep-clear is 1.35 m in front of the opening.
3. **Place pieces through `RoomLayout`**, which refuses any pose that overlaps a
   door, ramp, window, fire, wall, post or another piece, and records what it
   could not place. If a piece will not fit, shrink the program or enlarge the room
   (the architecture skill allows replanning); never push a piece into a zone.
   Tall pieces keep off windows; low ones (beds, chests, benches) may stand
   beneath a sill.
4. **Face every piece deliberately.** Back is local +Z, front local -Z: a settle,
   shelf, chest, desk or peg rail puts its back to the wall; a chair faces its
   task; a hearth group faces the fire. A chest's hinge is on its back, so a chest
   at the foot of a bed has its back toward the bed (the lid lifts away from the
   person at the foot); a bed is built head toward -Z.
5. **Leave the middle clear.** Furniture against walls and in groups; benches and
   shelves in a gallery or corridor stand on the wide stretches, never in a
   passage that is already near its minimum.
6. **Walk it.** The validator's lanes are the minimum; also walk each route at
   eye level, open and close each door, and look up for anything poking through a
   ceiling.

## 2. The layers

1. **Structure.** Floor finish (boards, flagstones, packed earth in service rooms), skirting, beams, lintels, window seats, alcoves, shelving niches, the hearth surround with a mantel.
2. **Necessities.** What the room needs to function: hearth tools (poker, bellows, log basket), table and seating, bed with bedding, storage (chest, cupboard, shelves), a water jug or bucket, a lamp.
3. **Work.** Evidence of the trade: tools on pegs, stock, half-finished work on the bench, sacks, ledgers, shavings, a scale.
4. **Personal.** Things that tell stories: a keepsake on the mantel, a child's drawing, a map, a musical instrument, dried flowers, a trophy, a cat bed, a framed sketch, a hat on a peg.
5. **Wear.** Soot above the hearth, a worn patch on the rug, a stool pushed back, a door left ajar, a pot left to cool. Use slightly varied colours rather than perfect repeats.
6. **Light.** Hearth glow, a candle or lamp per activity group, window light falling on the main table, hanging lantern over the entry.

## 3. Rooms and what belongs in them

**Hall or living room.** Hearth with mantel and log basket; a table with benches or chairs; a chair or settle by the fire; wall shelves with crockery; hooks by the door for coats, hats and tools; a rug under the table; hanging herbs or sausages from the beams; a window seat if there is a deep wall.

**Kitchen or scullery.** Work table, pot rack, shelves with jars, crocks and baskets, a water barrel and a tub, a bread bin, strings of onions and herbs, a broom. The hearth or oven gets a trivet, tongs and a kettle.

**Bedroom.** Bed with head to the wall and a clear side, bedding in the occupant's colours, a chest at the foot, a night table or shelf with a candle, pegs for clothes, a small rug, a window with a curtain. Children get toys and a smaller bed; the elderly a warm blanket and a close chair.

**Inn common room.** Hearth as the heart with a settle either side. Tables of varied size, some with benches and some with stools, arranged in groups. A long counter with the keeper's space behind: rows of mugs, barrels, a ledger, a cash box, a lamp. A noticeboard of local news (symbols only), antlers or a carved sign over the hearth, lanterns on beams, a rug near the fire, a dart or game board, a window table for travellers. Keeper's office behind the counter: desk, ledger shelf, strongbox, a chair, a lamp, a window onto the yard. Kitchen with an open hearth, pot rack and long prep table; pantry with barrels and hanging meat. Guest rooms: a bed, chest, washstand with jug and bowl, peg rail, a candle, a window; the party room has several beds with a table and a rug. Privy: closet with the seat against the wall, a bucket and a lamp.

**Civic hall.** Long benches along the walls, a raised end with the reeve's table and a carved chair, a ledger stand, a map or village symbol on the wall, a hearth, lamps, a bell rope in the corner, a lectern. Records room: shelves of boxes and rolled documents, a strongbox, a clerk's desk by the window. Teacher's corner: a long table, slate board, small stools, a chest of readers.

**Workshops.** The trade owns the room. Forge: forge hearth with bellows, anvil on a stump, quench trough, tool rack, fuel and iron stock, an apron on a peg. Bakehouse: oven mouth with peel and rakes, floured table, bread racks, flour bins, a scale, sacks. Joinery: bench with vice, planes and saws on a rack, clamps, offcuts, a half-built chair, shavings. Mason: stone samples, mallets, a string line, lime bucket, a drawing table. Mill: sacks, the hopper and stone, a hoist rope, a lantern, a broom.

**Shops and stalls.** Stock arranged for selling: wares in rows and stacks, a price board of symbols, a scale, a stool for the seller, a lamp, a spare crate behind. The seller's house and storeroom stand directly behind.

## 3a. Stock and provenance: what is on the shelves and why

A room's contents are evidence of an economy. What a shop, workshop or stall sells must match what its people make, gather or are given to sell, and the chain must be readable in the rooms themselves:
- A baker's workroom holds flour sacks, a peel, cooling racks and rye loaves; her stall sells those loaves. A smith's rack holds the swords and breastplates his stall sells, with pitch cans from the sawmill beside the forge. A textile house has wool, a loom and finished toboggans on a peg.
- Goods that arrive from outside (cheese from a farm, berries from a family) appear as crates, baskets or sacks by the door where the carrier delivers them, and the carrier's schedule passes that door.
- A commission (a naturalist's jars sold on the baker's board) is shown by the jars standing in a different style from the seller's own stock, at the end of the counter.
- Never stock a shelf with items nobody here makes or buys. Never leave a stall holding goods that appear nowhere else in the world of the village.
- The trade ledger in the plan file (`OhioPlan.TRADE`, `SnowPlan.TRADE`) is the contract; write it before furnishing, and furnish to it.

## 4. Persona sheets for Ohio (extend as the bible grows)

- **Mira Holt (inn).** Practical, warm, an early riser, frank. A well-kept public room, a broom by the door, a tally of bread on the shelf, a good lantern, a small tidy upstairs room with a window onto the green and a few keepsakes of the road.
- **Halda Prewitt and Dorran Fask.** Her ledgers, seals and stamps; his joinery tools, a model of the roofline he is dissatisfied with, offcuts. A crooked beam they never mention.
- **Cob Ferris.** Flour dust, grain sacks, weather lore: a barometer or charm on a nail, a grandmother's chair by the fire.
- **Oswin Cray and Ivy Thorne.** His worn chair, tools on a rack, a pipe; her sketches pinned in the loft, jars and a notebook, a cushion where a wild blorb sometimes sleeps.
- **Wren Sallow.** Herb bundles, a gathering basket, boots by the door, a map of the hedge line, a small lamp that stays low.
- **Tam Ruskin.** Stone samples, a lime bucket, drawings of the fountain carvings, an hourglass that no longer runs.
- **Aldren Vey.** Cabinets of curios, labelled boxes, a good chair, a locked strongbox; a house a bit too tidy.
- **Brinna Kest.** Tools and tack mending, a rack of tested blades, a cot above the workshop, a caravan guard's old cloak.
- **Nell Barrow.** Flour bins, a long table, loaves cooling, a handcart parked by the door.
- **Petra Voss.** Slates, copied pages, a stack of local histories, a candle burning late.

## 5. Constraints specific to Eleblorb

- Build every prop from `SuperEgg` parts, with epsilons by role (squarish for tables, benches, chests, shelves; soft for cushions, sacks, bedding; round for pots, barrels, stools). Use `TownProps` and `VillageWorks` builders where one exists; add a reusable builder rather than a one-off.
- Substantial pieces get collision (`CollisionPolicy`). Small clutter (mugs, books, herbs, cloth) is decorative.
- Keep to the clearances in the `architecture` skill: 1.2 m on routes, nothing in the foot of a ramp or in front of a door.
- Light: hearths carry a flickering warm omni light; add a few soft lamps by activity group, never one per prop. Warm window glow at dusk. Respect the Compatibility renderer's light limits (see the interior-lighting plan: emissive materials first, a handful of real lights per room).
- Plants indoors are purposeful: a pot on a sill, herbs hanging to dry, a vase on a table. Never a stray bush standing beside a person.
- No text in the world.

## 6. Review checklist

1. I can say in one sentence whose room this is and what they were just doing.
2. At least three items in each room are specific to its occupant.
3. Large furniture is against walls; free-standing pieces form groups; nothing is stranded.
4. Routes (door to hearth, to stairs, to each room) are clear at 1.2 m, door swings and ramp feet are clear.
5. Every activity group has its own light and its own small clutter.
6. Textiles, warm light and a focal hearth make the room pleasant rather than bare.
7. Props are SuperEgg builds with sensible epsilons, collision where substantial.
8. Eye-level renders read as a real, lived-in room.
