# P7–P9 integrated model and builder handoff — 2026-10-22

Planning ready for a fresh builder conversation in the existing implementation
checkout. P7 first, then P8/P9 together, one integrated review. No new runtime
construction acceptance is claimed by this report.

## Full Crossing integration

The standalone P7 and combined park pages now build the exact same P7 scene
from `docs/drawings/moy_crossing_scene.js`. The scene is embedded identically
in each HTML by `tools/embed_moy_crossing_scene.py`; --check verifies the source
copies. HTML files remain single-file model downloads, with their existing
Three.js CDN libraries. No external local JS dependency is required to open one.

The old park proxy's primitive ribs, flat roof and wire-only dome are removed.
Full towers, helices, galleries, lifts, beams, ring, platforms, roof, dome/grid,
clocks, bell, Clock Room and interior gardens now appear together with P8/P9.
Dedicated Crossing/dome/interior/section cameras are available in the combined
model. Ground-plan/tea-section views hide the P7 layer deliberately; they do
not substitute any simpler station geometry. P7 owns all station components.

Verification:

- Both model pages pass browser load/view checks without script errors.
- Their pre-batching P7 scene fingerprints match exactly: **8f42d65d**,
  22,488 preview mesh instances and3,795,722 position-attribute vertices.
  These are authoring-model counts, not runtime/performance targets.
- The original P7 scene body is preserved verbatim, apart from its separate
  preview ground/context and viewer settings. No P7 architectural data changed.
- The six other drawing pages with refreshed DATA load without script errors.
- Original and integrated dome/interior/section, park overview, dry-garden
  eye/plan and other reference views were refreshed and inspected.

## Dry garden and interfaces

P8 now uses curved gravel lobes around the existing palms/boulders, with grass
fingers and low planted drifts. Its old rectangular search/allocation envelope
is explicitly not the material outline and must not be rebuilt as a gravel box.

The1.8m trail is routed through checked free space around source rocks, palm
trunks and seats; it meets the existing park approach. Twenty low shrubs form
three drifts. Seven benches include a new seat under the dry-garden palms.
Irregular dry area1,156.95m²; broad lawn patches7,055.06m². The shared schedules
remain P7 72/19, P8 41/12, P9 30/12 (parts/joins), all shown in the integrated
model's owner-labelled tables. No new species or game mechanic was introduced.

Authoring validates connected park paths, tree clearance, clear dry trail,
full pond bank2.025m inside park, and bridge max grade7.95°. The P7 ownership
contract records source/brief/renderer and ground+0.04 versus P8 path+0.08;
the builder must make real flush transitions and preserve station openings.

## Baseline and handoff risk resolved explicitly

Remote main was fetched; its P5 acceptance review states the actual P3/P4/P5
source/bake remain local and uncommitted, with recovery snapshots. User reports
P6 done; no published P6 completion source/report was found on main. The other
published branch is older planning work, not a completed P6 baseline. Do not
misrepresent a planning checkout/248-pack bake as those later local builds.

The new `moy_p7_p8_p9_build_handoff.md` therefore starts a fresh **conversation
in the same P5/P6 project working tree**. It requires a verified snapshot and
starting checkpoint before carefully integrating planner source/models. It
forbids resets, blanket replacement with upstream generated packs, rebuilding
old districts or indiscriminate staging of inherited work. If the completed
working tree is unavailable, obtain it or its verified recovery snapshot first.
The prior isolated P8/P9 handoff is a redirect to this one entry point.

Current practical village-level construction direction is explicit across the
three briefs: complete functional architecture/public circulation and real
close-up dome quality, with sensible collision, actual focused gameplay checks
and required repo validation. Historical exhaustive certificates/per-view
performance matrices do not override it. Final L4 remains honestly tracked.

## Other validation and remaining implementation work

Plan export/parts-and-joins checks pass. Comparison against preceding HEAD
confirms all existing plan data unchanged except PARK.kit. Source bake/freshness
passes at248 packs. Canonical runtime scene files are retained after resource-ID
churn because this revision changes planning metadata, not runtime construction.
The helper and CityPlan source hashes are updated through the real bake.
Required pre-push quick checks and scoped city validation run before push.

The actual game frame welding, structure/collision/route fixes, functioning
clocks/bell, full park/playground build and local P5/P6 source integration remain
the implementation owner's work. Browser parity is evidence of a single design,
not a runtime pass. External artifact publication remains unavailable; local
HTML and useful reference images are committed. No web-game export is required.
