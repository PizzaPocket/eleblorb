# Moy prototype readiness review

2026-10-17, source revision `499a96e`. This was a preparation/review pass. No
city runtime implementation, geometry bake, terrain edit or web export was made.
The new execution contract is `docs/architecture/moy_playable_prototype.md`.

## Assessment

The planning is substantially stronger than the current runtime city. There is
enough measured information for a useful playable prototype without another
concept-design round. The transfer risk is interpreting a schematic massing
model as finished playable construction, or taking old prose as the latest plan.

Reviewed inputs: the existing build handoff; the settlement/site/census,
circulation, wall/rail, park/playground, tower/estate, hotel, city-hall/Timekeeper,
gate and library sections of `city.md`; the tower-house and market-lane briefs;
their style charters and backlog; all four drawing data sets and the whole-city
model's construction code; the authoring/export tool and Godot plan validator;
the old runtime city, terrain/scatter/enemy exclusions; the real vine anchor
search, static merge/bake, China streaming/QA/performance tools and diagnostics.

The reference pages are the repository's local HTML sources. Published links
were not fetched or treated as a newer revision. This review inspected source
and measured data; it did not re-render Moy in Godot or play an unbuilt city.

## Checked facts and defects to resolve first

| Finding | Evidence and implication |
|---|---|
| Latest layout is encoded | Stored whole-city, plan and hotel pages embed identical full JSON: 48 numbered records, 133 lots, 60 separate old houses, 24 street records, 9 general courts. Train page intentionally has a smaller schema. |
| Python succeeds | Ran a copied `city_layout.py` with `gd_plan.py` in `/private/tmp/eleblorb-moy-handoff`, Python 3.12/Shapely 2.2. It reports 24 streets, 48 buildings, 133 lots, 9 courts, no `PROBLEM`. Root generated data was not overwritten. |
| Regeneration is not byte-identical | Compared regenerated JSON to the stored model. Only `wall.centreline` differs, in tessellation. All other top-level fields agree. Refresh derived assets together after preparation fixes; do not silently mix snapshots or claim exact reproducibility yet. |
| Godot plan check currently fails twice | Ran `tools/validate_city_plan.tscn` against current source in the isolated imported scratch project. Reports: `building 28 Mara's building has no face on a street, square or the Rim Walk`; `Cinema Lane lies wholly outside the Rim Walk`. These failures remain unresolved in this review pass. |
| Mara's frontage check is incomplete | `_in_street_or_open()` recognizes grid rectangles and open-space rectangles, but not `OLD_TOWN.lane_polys`/`squares`. Mara's north face is served by the authored Mara's Lane. Teach validation the real route instead of moving her building. |
| Cinema Lane needs an explicit empty-clip decision | Its old rectangle is x -734..-730, z -220..-122, outside the city. The model's radius-203 clip produces reversed z bounds. A builder must not construct a reflected rectangle from those bounds. Reconcile this unused template in authoring/validation and report its omission; do not exempt all outside streets or invent an alignment. |
| Estate export is incomplete | The authoring tool and full model JSON contain `ESTATE`, including turned courts, linkways and the twins' skybridge. Generated `CityPlan` exposes `PRECINCTS` but no `ESTATE`. Export the existing data; do not hardcode a second copy. |
| Some summaries are stale | Earlier no-train direction, +26 Meridian comments, day-ring/roof-slot references, BLOCK “no crown”, playground-at-centre and old building totals conflict with later dated design/data. The execution contract states the current choices explicitly. |

The macOS headless certificate warning also appeared; it was not the source of
the two explicit validator failures. No runtime or performance pass for the new
city is claimed.

## Runtime risks the earlier handoff did not make concrete

**The old generator is not an adapter for the new data.** It still builds its
own 24-tower grid at (-540, 0), then materializes every block during startup
before distance sleep. The terrain pad is still radius 78; new Moy is at
(-560, 0), Rim Walk radius 200, wall radius 209.5 with works outside. Scatter
and skeleton protections still use old bounds. Simply enlarging the generator
or hiding it after construction would retain the startup problem and introduce
terrain/spawn conflicts.

**Use the model's intent and the detailed briefs together.** The overview
contains solid cylinders for access towers, a solid hotel court, solid estate
ground slabs and a simple pond surface. Those are drawing conventions. In play,
ramps, void decks, public passages, ring holes and train halls must actually be
open and water must use the game's liquid/swim system. The hotel detail model
provides its void and section. Existing final Level A interior ambitions do not
belong in this first layout pass.

**Physics batching can break vine handovers.** `VineAnchorSearch` raycasts on
layer 1 and excludes the previous anchor's RID. One district-wide StaticBody
could make neighboring building anchors unavailable after the first grip.
Keep collision bodies distinct per building even when merging visuals. Test
the real mode's handover, rather than only finding one anchor ray.

**Do not overstate the China fix.** Its recorded October 16 remediation removed
the severe distant startup/render bottleneck with baked statics, instances,
simple distant proxies and actual unloading. That report still measured a
929 ms worst activation frame: threaded loading alone did not amortize scene
instantiation/registration. Moy needs smaller activation units and measured
frame budgets. Those historical numbers are not current Moy measurements.

## Recommendation

Build a traversal skeleton of the entire plan: dimensions and landmark forms,
all public route levels, simple roofs and collision, real swing/handover and
basic rideable trains. Defer decorative shaders, detailed interiors and census
expansion. Keep a cheap city-wide prototype core resident while occupied if
measured affordable; activate it in bounded units and leave decorative block
streaming extensible. Do not spend this pass building a general interior engine.

The execution contract supplies a source-to-builder coverage table, named
preflight fixes, scope limits, loading rules, QA scene requirements, traversal
routes and measurement gates. A short starter prompt lives at
`docs/prompts/moy_playable_prototype_luna.md`. Use those with the actual model
and design documents, not a recollection of this chat.

**Fixed:** the owner's existing city plan/model and authorization for a rough
playable prototype in a separate chat.

**Proposed:** the bounded implementation contract and its initial budgets.

**Open:** the two recorded preflight issues and practical route/scale findings
from the first playable build. No new approval round for the whole plan is needed
to begin that authorized prototype.
