# China Village: continued architectural correction

The owner authorized continuing the correction across the village after finding
the garden pine still intersecting the tower. The accepted settlement, census,
plots, progression, water and route graph remain the inputs. This pass improves
the built translation; it does not constitute visual approval of the village.

## Placement and construction corrected

- Both garden pines now use surveyed positions in `ChinesePlan.GARDENS`, shared
  with the model. The royal specimen clears the battered tower foot; the inn
  specimen is inset from its enclosing walls.
- Every pine retains all fifteen actual canopy-lobe envelopes through merging
  and serialization. During baking, seeded rim candidates are checked against
  physical architecture, other trees, island bounds and route clearances.
  Sixteen rim specimens were repositioned; none were removed. Runtime validation
  independently checks the resulting crown boxes against the loaded scene.
- Royal covered corridors now have stone shoes, softly squared green columns,
  longitudinal beams, cross ties, swept hip roofs, rounded eave hems and ridge
  caps. The inn's covered connector keeps grey tile and also has a pitched roof.
- Both garden pavilions have structural columns, stone shoes and capitals.
  Closed swept roof bays replace the thin pyramid and detached upturn sticks.
- Rockery uses one leaning, perforated standing mass with weathering cuts and
  subordinate stones, rather than a pair of swollen stacked bulbs.
- The shared facade lattice had its horizontal bars rotated out of the wall.
  Laths now lie on both faces of the paper, fitted to the superellipse opening.
  This fixes the conspicuous projecting sticks on homes, the inn and outbuildings.
- Household stone walks formerly extended outside the front gate. Their ends
  now follow the actual main-room threshold and gate. A non-overlapping side
  run meets the shed doorway. Interior furnishing uses actual shell dimensions,
  rather than rounded construction-cell dimensions. Water jars and fuel baskets
  occupy the left yard margins, clear of those routes.
- Exposed market and arrival paving now has a flat superellipse perimeter.
  Walled courts retain precise infill. Rejected repeating patterns stay removed.
- The inn's lattice screen has actual openings, masonry end piers, a plinth and
  coping. A simplified invisible guard represents openings too small for bodies;
  the old visible solid backing has been removed.
- The inn pond crossing now connects two banks instead of ending in the basin.
  A regression check requires both crossings to reach outside their pond outlines.

## Review and limits

Windowed Godot views cover the royal garden, pavilion approach, inn front and
inn garden, household compounds, market, farm and arrival gate. The window bars,
court walk limits and tree clearance are visibly improved. This is a targeted
survey, not an exhaustive check of every interior and every decorative overlap.

Remaining art priorities are the overly large inn roof, more distinct trade
fronts and working yards, richer architectural treatment of the large tower
podium, more natural rockery and shoreline composition, and the royal crossing's
visual weight while retaining the minimum usable width. The underlying island
sides and abyss backdrop still look coarse in wide inspection views. These
should not be described as finished merely because collision checks pass.

## Verification

- China runtime: pass, including all 49 pine crown envelopes, crossing banks,
  water and swimming, bridge surfaces, ramp traversal, doors, instanced plants,
  state persistence and threaded region activation.
- Plan validator: 8 islands, 10 bridges, 54 items, 38 openings and 65 paths agree.
  The plan generator reports zero layout problems.
- Shared facade regression: Ohio has 0 failures / 8 spacing and schedule warnings;
  Snow has 0 failures / 5 schedule warnings. These warnings remain outside this
  correction. The plan-only validator also reports two exit-time object leaks.
- Bake source signature and runtime/Three.js plan data agree. JavaScript syntax,
  design-language and whitespace checks pass. Final bake logs have no script
  errors. Headless runs print the sandbox's macOS certificate-query warning.

Final screenshots are under
`wip/diagnostics/2026-10-16-china-village-continuation/`. The production static bake
and its signature are updated. Changes remain uncommitted; web build untouched.


## Final isolated performance sample

Apple M5, Godot Forward+, 1600×1000, fixed QA cameras, two 3-second samples
per view after warmup. This measures the isolated village, not full Crossroads
startup or a complete walking session.

| Measurement | Palace view | Field view |
|---|---:|---:|
| Frame rate | 60.0–60.03 FPS | 60.0–60.15 FPS |
| Worst sampled frame | 18 ms | 17 ms |
| Draw calls | 3,673 | 4,031 |
| Godot static memory | 344.5 MiB | 347.3 MiB |
| Reported graphics memory | 676.0 MiB | 676.0 MiB |

The isolated scene staged in 2.63 seconds, with 26,912 nodes. Geometry remains
baked; the new placement proof runs in the bake tool, not during normal loading.
Future dense districts still need stronger draw-call and culling budgets. These
measurements do not resolve the previously recorded region-activation hitch.
