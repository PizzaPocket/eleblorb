# P6 revision 2 — sites and supporting bases

User-authorized change following review of sliver buildings, touching tall
facades and the thin-post base model. Supersedes the original P6 handoff.
This is architectural planning verification; runtime P6 is not implemented.

## Revised plan

- Ten consolidated sites consume all 23 mid-rise source plots exactly once.
  LOTS and old owner IDs remain stable provenance for cross-package links;
  implementation must replace their old geometry and use DOWNTOWN.sites.
- Minimum shaft width 12 m; minimum mutual shaft gap 8 m. Landmark-shaft
  gaps also checked, except the deliberately preserved six-metre BLOCK climb
  interface. New shafts are contained in the exact merged site polygon.
- Shared/contiguous podiums can remain at street level. Narrow strips become
  part of a neighbouring low podium and roof terrace, not a thin tall tower.
- Continuous per-site cores, 1.4 m primary piers, maximum supported span
  7.2 m; 0.8 × 1.2 m girders below the +6.5 m podium slab. Enclosed street
  frontage and selected public openings replace the all-open perimeter posts.
- South landmark now also has a continuous 6 × 8 m core and 1.4 m primary
  frame on a 5.333 m grid, with girders below the +7.5 m first balcony.
- Binding schedule: 50 part templates, 17 joins. These establish a credible
  architectural load path for the game, not engineering certification.

## Preserved interfaces

Court 8's 2.4 × 3 m passage remains at x=−436, z=38 to 58. Primary piers
are checked against it; the base opening is drawn from its actual location.
P17's climb wall x=−443 at z=55, height +122.4 and six-metre gap are kept.
The approach site absorbs lot120 to the east. Source IDs are not renumbered.
Existing public courts, roads, hotel, Deck and other package geometry/data
remain unchanged. Compared exported JSON against pre-revision data:
all differences are confined to DOWNTOWN.

## Verification

- Plan generator and its new source-coverage, containment, minimum-width,
  separation, supported-grid-span, passage-pier and P17-interface checks pass.
  Existing capsule/terrace checks pass; south balcony minimum clear 1.5201 m.
- Chromium/software WebGL: updated P6 overview, three landmarks, street,
  base, passage and structural section captured without script errors.
  The section removes the front enclosure and half podium slab so the
  continuous core, aligned piers and transfer girders can be seen beside the
  exported game hero. Architecture has no printed letters or numerals.
- City model, top-down plan, hotel and BLOCK context now draw consolidated
  shafts over low podiums, rather than the 23 old towers. All five existing
  re-embedded model pages (including P5) load without script errors.
- Quick pose, power-parity and design-language checks pass. City validator
  reports 22 streets, 47 numbered buildings, 133 stable source lots, 0 FAIL.
  The source-lot count is not the new tall-building count.
- Headless bake/freshness verified for the planning-data update. Runtime
  builder does not consume the new sites yet; canonical scene packs retained
  after resource/node-ID churn, with generated source hashes refreshed.
  Existing headless dummy-renderer shutdown warnings remain.

Reference images are in `docs/drawings/references/`:
`moy_downtown_overview.png`, `moy_downtown_parts.png`,
`moy_downtown_base.png`, `moy_downtown_passage.png`,
`moy_downtown_street.png` and the three tower images.

Implementation still owes actual game collision and winding checks, two-rig
routes, working lifts, matched P0 audits, performance and unload/re-entry
proof. The old 23-tower build prompt is withdrawn. Pull revision 2 and build
from the revised P6 brief. External artifact publication remains pending;
this chat has no artifact-publishing tool.

## Mid-rise material refinement

User requested conventional skyscraper colours for the ten medium-sized
buildings only: muted smoke/blue-grey/silver-grey glazing, aluminium,
champagne metal or graphite frames, and neutral grey stone. Site material
keys and model now use those finishes. Landmark palette entries and all
wind/north/south parameters were compared with the previous commit and are
unchanged, as are site geometry, parts/joins and geometric checks. Updated
reference images replace the earlier bright-trim renders.

## Windspire crown and remaining trim correction

User reported remaining red trim and a disjointed crown. The old preview
reused the horizontal-axis wind-gap rotor at local z=−7.5 for the crown;
its axis and position were wrong. Nine struts also lacked frame ties.
Replaced this with closed base/mid/top ties, connected posts and diagonal
braces seated at shaft roof +262, and a central mast rooted on the core.
The separate vertical-axis rotor is centred at x=z=0, y=276.6, with radial
arms at both blade ends. New checks enforce level ordering, bearing,
centering and rotor clearance above the frame. Added a crown close-up.

Windspire fins, guard and crown use aluminium. South screens and pergola
use neutral metal. Capsule shells retain their accepted colours. The
schedule now has 50 part templates and 17 joins, including crown-ring,
brace and rotor-arm definitions. Crown geometry/appearance is verified in
the planning browser model; production collision, motion and mesh joins
remain implementation acceptance requirements.
