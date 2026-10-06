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

## Other kingdoms

Draft charters to be added from `references/cultures.md` grammars: Rock and Ground (earthen Pueblo/adobe), Ocean (stilt harbour), Plant (tree-borne and thatch), Sky (floating white-stone and bronze), the Chinese village (courtyard and tiled hip-and-gable), the Western city (concrete). The Fire Kingdom's draft volcanic-modern charter now lives in `docs/architecture/fire_caldera_city.md`. Each remaining kingdom needs the Ohio-style charter with a primary, one secondary, an accent, a kit of parts, hierarchy and exclusions.
