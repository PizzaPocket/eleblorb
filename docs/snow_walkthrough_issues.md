# Snow Village walkthrough ledger (2026-10-04)

Items the user reported while walking the Snow Village. Same conventions as
`docs/ohio_walkthrough_issues.md`: "Fixed (code)" means changed in source and
checked by the validator or a probe on a scratch copy of the project, but not
yet seen in engine by the user.

| # | Report | Cause (if known) | Status |
| --- | --- | --- | --- |
| S1 | Interior furnishings clip through walls and block door passages everywhere | Placement by hand, no check | Partly fixed (code). Door and ramp clearance is now 0 FAIL in the scratch validator after moving the inn-wing table, rescue-store sleds and meeting furniture, and workshop table. A furniture-inside-wall audit and full `RoomLayout` conversion are still owed. |
| S2 | Interlocked log corners carry too far past the joint; the ends read as fingers | Corner log ends extend beyond the crossing log | Fixed (code), visual check owed. Courses now stop flush at the crossing joint. |
| S3 | Logs should be much more squarish SuperEggs, especially long ones, which otherwise get long pointed ends | Log epsilon too round | Fixed (code), visual check owed. Log SuperEgg exponent is 6.0. |
| S4 | Windows should be more squarish; drop the extra white box (casing slab) around them; course ends should run to touch the window frame | Casing slab and round window profile | Fixed (code), visual check owed. The opaque casing plate is no longer built and Snow passes the flatter opening exponent into its frames. |
| S5 | Doors should be more squarish | Round door profile | Fixed (code), visual check owed. Snow doors use the flatter opening exponent. |
| S6 | Double doors (everywhere): each leaf is half a SuperEgg, like window shutters, cut on its inside edge as well as the bottom | Each leaf is a whole SuperEgg | Fixed (code), visual check owed. `WorldDoor` now clips both leaves from one shared SuperEgg silhouette. |
| S7 | Astrid Snowrest faces the wrong way; know which way every resident faces | NPC facing authored by hand | Fixed (code), visual check owed. Her facing is derived from her position toward the room she serves rather than a typed angle. |
| S8 | Inn fireplace body is a rectangular prism; it should be a SuperEgg | Hearth mass is a box | Fixed (code), visual check owed. The peis is a soft SuperEgg masonry mass and Snow hearths use scheduled `HearthFire`. |
| S9 | Rooms and beds too cramped; the rooms cannot hold their furniture. Make the houses bigger. | House footprints set before furniture programs | Partly fixed (code). The lift workshop grew from 4x2 to 4x3 cells and its private-room furniture moved behind the inner-door landing. Remaining rooms need an eye-level audit before claiming the whole item. |
| S10 | A hut with stairs and a red door hovers above the ground and cannot be entered | To investigate | Open |
| S11 | Roof overhang comes down so close to an entry that the door cannot be used | Roof pitch and eave height do not account for the door | Open |
| S12 | A chairlift leg climbs so steeply that the chair clips into the mountain; wind the line where too steep. The chair must never clip the mountain. | Straight line between towers was only checked at its supports | Fixed (code), ride check owed. The lift now samples every cable span against the terrain and raises neighboring support heads over intervening crests while preserving terminal boarding heights. The same full-span clearance check is enforced by the Snow validator. |
| S13 | The planetary ocean shows inside the ice basin | Sea at -12 m, basin floor about -29 m | Fixed (code). The kingdom builds its own sea with a footprint cut-out over the lake, as the demo world does, and its DayNightCycle has the generic sea off. Probe: one sea; lowest ground on the hole's edge ring is -3.7 m, so no seam. |
| S14 | NPCs frozen | See Ohio ledger 27 | Fixed (code), shared script. |
| S15 | The yard's small open fire reads like a trash fire and the nearby symbol slab has no convincing civic role | The approved brief specified a literal fire ring with loose log seats plus an unrelated mound and marker | Fixed (code), visual check owed. The mound and slab are removed; a raised iron communal fire pan now anchors a snow-cleared flagstone court with three high-backed timber settles and open circulation between them. |
| S16 | New audits (2026-10-05) on the current Snow tree: 8 FAIL | Snow's interiors were never drawn as a stack or checked against walls | Open, measured. Stacking: Mountain Rescue Hall and Textile House each have two upper walls with nothing under them (interior walls at x=-3.4 z -4.5..4.5 and z=0 x -3.4..6.1, 8.9 m and 9.8 m unsupported). Furniture inside walls: two Snowrest Inn pieces (a 1.2 m shelf and a 3.6 m counter against walls at z=-1.8 and z=1.6), one bed in the Inn Wing (against x=4.0), one 3.0 m shelf in the Rescue Hall (against x=0.2). Fix by applying the architecture skill's stacking drill to each two-storey Snow building and placing through `RoomLayout`. |
