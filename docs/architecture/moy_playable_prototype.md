# Moy: playable layout prototype contract

> **Amended 2026-10-17 by plan iteration 2.** Read
> [the iteration-2 review](../diagnostics/2026-10-17-moy-plan-iteration-2.md)
> first: the lines are level (Spine and Wall Line at +13.2, Meridian +36),
> the Spine ends at gate interchanges inside the wall (no flyover, no
> tunnels, no interlock), platforms sit at the car's floor, escalators are
> pairs, scissors and the Crossing's double-helix spirals, and trains run to
> `TIMETABLE`. Where this contract says otherwise, the review wins.

2026-10-17. Implementation brief for the next chat. The owner authorized a rough,
playable reconstruction of the **existing city plan and 3D model**. This is not
permission to redesign Moy, build every interior, or deliver final art. The
repository spelling is **Moy** (the owner also says Moi).

Read this before `moy_build_handoff.md`. It narrows that earlier handoff to this
prototype and adds the performance and traversal requirements learned in China.
Do the implementation in the next chat, not in the planning/review chat.

## 1. Inputs and precedence

1. `AGENTS.md`, `CLAUDE.md`, and this prototype contract.
2. Latest measured values in `tools/city_layout.py`, generated
   `scripts/city_plan.gd`, and embedded model data, reconciled before building.
3. `docs/drawings/moy_city_3d.html`: the whole-city massing target. Read its
   construction code, not only its JSON. Its `PLACES` list supplies review views.
4. `docs/drawings/moy_grand_hotel_3d.html`: the hotel's actual section and void;
   the city overview intentionally simplifies it into a solid block.
5. `docs/drawings/moy_train_3d.html` and `moy_plan.html`: car construction,
   dimensioned plans, tower profiles, estate and hotel sections.
6. `docs/architecture/city.md`, `moy_tower_house.md`, `moy_market_lanes.md`, and
   the Moy sections of `docs/style_charters.md`: architectural intent.
7. `docs/architecture/settlement_backlog.md` and `moy_build_handoff.md`: history
   and later work. Older summaries do not override newer measured data.

Read `.claude/skills/settlement-design/SKILL.md` and the relevant architecture
skill sections. The owner's explicit rough-prototype scope takes precedence
over demands for complete finished buildings. Keep the SuperEgg language and
substantial collision; omit detail rather than constructing a second disposable
visual language. Do not introduce new lore, residents or progression.

Latest decisions that older prose sometimes contradicts:

- Cars remain absent. **Trains exist**, elevated on the wall and cross lines.
- Street datum is 0; Deck walking surface +6.5; Spine and Wall Line rails +13.2 m, level, platforms +14.2 (iteration 2);
  Meridian rails **+36**, with high platforms **+37**. A rail elevation is not
  a platform or train-roof elevation.
- Timekeeper is a full twelve-hour ring, centre +37.5, top +51, empty centre
  for the high line. No day ring or old roof slot.
- Meridian Arch **is the East Gate**. West Gate is its two-tower partner.
- Crossing is an **open ring**. Playground is in the south-east quarter,
  at its recorded scale; its tower heights are not reduced with its plan.
- Library Square is the smaller northern square. BLOCK has the inward folded,
  canted crown, not a flat roof, and no connection to the Deck.
- General lots do not replace the separately authored Well Quarter houses.

## 2. First gate: reconcile inputs without improvising a layout

Read `docs/diagnostics/2026-10-17-moy-prototype-readiness.md` for the observed
failures and limitations. Complete these small preparation fixes first:

- Make Godot's frontage check recognize `OLD_TOWN.lane_polys` and `squares`.
  Mara's building fronts Mara's Lane; moving it to appease the old grid-only
  validator would damage the plan.
- Investigate the legacy **Cinema Lane** rectangle: its centreline is outside
  the Rim Walk and its radius-203 clip is empty. Never turn reversed clipped
  bounds into an accidental road. Reconcile it explicitly in the authoring
  tool and validation: an unused empty template must be recorded as omitted,
  rather than counted as a connected built street. Do not invent a road or
  move buildings. If investigation reveals a needed route, report the exact
  discrepancy rather than guessing a new alignment.
- Export **`ESTATE`** from `tools/city_layout.py` into `CityPlan`. It is already
  authored and present in model JSON, but its linkways, courts and twin skybridge
  are missing from the GDScript export. Do not copy those numbers into a builder.
- Fix stale generated comments in the authoring tool (+26, day ring, no crown).
  Generate `CityPlan`; never hand-edit generated numbers.
- Regenerate JSON and update the three full-data drawings using
  `tools/embed_drawing_data.py`. The train drawing has a smaller schema
  (`train`, `platforms`, `r_min`, `speeds`): preserve it when refreshing it.
  Inspect diffs. A review run found wall centreline tessellation differences
  between regenerated and stored data, not different building positions.

Run Python's layout checks and Godot's plan validator. Neither replaces a
runtime collision test. Do not suppress failures or mark broken routes passed.

Authoring commands, from the repository root in the chosen working copy (use
a Python environment with Shapely; the runtime game must not depend on Python):

```sh
python3 tools/city_layout.py --json /private/tmp/moy-plan.json
python3 tools/embed_drawing_data.py docs/drawings/moy_plan.html /private/tmp/moy-plan.json
python3 tools/embed_drawing_data.py docs/drawings/moy_city_3d.html /private/tmp/moy-plan.json
python3 tools/embed_drawing_data.py docs/drawings/moy_grand_hotel_3d.html /private/tmp/moy-plan.json
```

For the train page, construct its small payload from the current authoring
export and existing schema; do not embed the whole-city object into it.
Run Godot against the isolated imported copy, sequentially:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path SCRATCH_PROJECT tools/validate_city_plan.tscn
```

`SCRATCH_PROJECT` stands for the actual absolute scratch project directory.
Inspect logs for script errors as well as the exit code. Keep failed evidence in
the diagnostic until the corrected check has actually run.

## 3. Exact layout coverage

At review, the snapshot contains **48 numbered records**, **133 lots**, **60
Well Quarter houses**, **24 street records**, **9 general courts**, and **6 open
space records**. These are input counts, not a promise of 241 separate buildings:
number 11 is a null-footprint playground handled by `PARK`, and some numbered
buildings have multiple masses. Recompute counts after the explicit input fixes.

| Source | Build for this prototype | Avoid |
|---|---|---|
| `STREETS`, `OPENS`, `COURTS` | Exact extents, clipped ends, park/plazas, continuous level public ground | New carriageways, raised kerbs across walking routes, patterned paving |
| `LOTS`, `LOT_KITS`, `STOREY` | Actual footprint and `storeys * STOREY[kind]`, modest rounded silhouette; coarse accessible roof | Using 3.25 for mid-rise lots (3.6), instantiating a furnished room per floor |
| `BUILDINGS` | Every non-null record at recorded height and `CityPlan.corners(b)` | Replacing turned estate blocks with axis-aligned bounds |
| `OLD_HOUSES`, `OLD_TOWN` | Exact polygon bases, heights, lanes/square and internal yards; coarse tower-house massing | Bounding-box extrusions that fill lanes/courts; randomized replots |
| `TOWER_SITE` and building `form` | Shaft on its own footprint, surrounding public ground, distinct twist/capsule/dune/monolith silhouettes | Filling the entire tower plot with a box |
| `HOTEL` | Court/tower/drum proportions; hollow public atrium/mezzanine skeleton, entry and both Deck connections | Copying the overview's solid hotel block and blocking the through-route |
| `ESTATE` | Open void decks where circulation passes; linkways and twins' roof bridge/sky garden | A solid ground-storey box across the court route |
| `DECK` | Runs, supports, junctions, access towers/ramps, public lifts and landings | Rails across branch mouths; solid cylinders masquerading as usable ramp towers |
| `WALL`, `ARCH`, `WEST_GATE` | Wall/watch walk, four open gates, train halls, posts, Line House, court and gate silhouettes | A continuous wall collider across gates or a full box across train halls |
| `CROSS`, `CROSSING` | Both tracks, supports, stations, open ring, actual station-core flights and platform holes | Solid station cores, unreachable high platforms, piers in walking lanes |
| `TIMEKEEPER` | Open rings and cradle, accurate opening and height; rings driven in physics if moving | A disk/solid convex hull across its hole |
| `PARK` | Quarter layout, real pond, playable tower/platform skeleton, wind-tree anchors | A blue solid slab; shrinking tower heights with playground plan scale |
| `TURBINES` | Four correctly sized/placed silhouettes, solid towers/nacelle landings | High-speed blades or unvalidated hazard tuning |

Preserve landmark construction intent from the model. Low fidelity can reduce
fins, relief, glazing and planting; it cannot replace an arch, void deck or ring
with an impassable solid. Soft edges use low-resolution shared SuperEgg meshes;
plain wall/floor infill and hidden collision boxes remain appropriate. Capped
custom polygon extrusions retain the authored shape. Do not round a plot so
aggressively that its usable roof or street edge changes.

Build a coverage ledger keyed `building:<n>`, `lot:<index>`,
`old_house:<index>`, plus infrastructure keys. Record each built node, source
footprint, top elevation, collision owner and any intentional composite owner.
This lets a validator catch omissions and double construction. Do not put QA
labels into the shipping world.

## 4. Scope limits that keep this inexpensive

Included: the complete layout and recognizable landmark massing, all public
circulation across its vertical levels, collision, ordinary platforming, Leaf
Hat swing/handover, and simple moving rideable trains on the three lines. A
train may have a solid closed body and a rideable roof in this pass; built
passenger interiors and automatic platform doors are later work. Use the
recorded car sizes, consists, track paths, speed/dwell values and platform gaps.
Keep Timekeeper time behavior simple and use real time as specified.

The public hotel skeleton needs only the floor, actual void, simple side masses,
mezzanine, ramps/landings, outside terraces, tower and drum. Detailed galleries,
suite, lifts inside slots, revolving lounge and chandelier crystals are later
work. Library interiors and other Level A interiors are also later work. A
closed facade door can remain closed; a required public passage cannot.

### Accepted prototype extensions (2026-10-17)

The owner subsequently requested train articulation and station dwell, moving
windmill blades with windward orientation, city color, non-flickering streets,
and actual pond water. These directions supersede the corresponding deferrals
above for this prototype. Keep the original plan geometry and SuperEgg style.

- Trains use independent pivoting rideable car bodies, station stops with a
  stops and service from `TIMETABLE` (iteration 2), separate Spine and Wall Line tracks meeting at level gate interchanges. Car-envelope
  collision sweeps verify the constructed passages through buildings/lots and
  station platforms; do not solve clearance by changing player range.
- Four turbine rotors face west into the authored wind and turn at 2 rpm with
  independent moving blade collision bodies. Hazard tuning still needs
  physical play verification.
- Use restrained building palettes, green park lawn, offset road surfaces to
  prevent ground flicker, and the animated water shader over the pond bed.
- The public hotel skeleton remains the only hotel interior scope.

Defer the interior-mapping shader, individual windows, detailed facades,
thousands of planters/crystals, crowds, new NPC schedules, story implementation,
train depot simulation and searchlights, and
wind-farm moving-blade mechanics. Ramps and escalators must work; escalators carry both playable characters uphill and downhill.
Turbine blades can be stationary solids for this pass; record that limitation.
No new rest-point service is claimed until the guest provision is actually built.
Retain the Helmsmith's existing city shop and the existing residents if replacing
the live city; put them on tested ground beside routes, not inside solid masses.
Do not expand to the full proposed census during this geometry pass.

## 5. Construction and loading contract

Use `scripts/city_generator.gd` as the live integration point. Extract small
reusable geometry/bake helpers as needed; do not leave two city generators in
Crossroads. The old `_rebuild()` materializes every old block before sleeping it.
That is **not streaming** and must not survive the replacement path.

1. **Build expensive geometry offline.** No runtime CSG, Boolean solving,
   Shapely, per-floor building-kit construction or static mesh merging. Use a
   reproducible tool that writes a signature/manifest and a few bounded static
   building/block resources. Missing/stale caches must give a useful authoring
   error, not silently rebuild the detailed city at play time.
2. **Use two tiers.** A very cheap silhouette preserves all landmark shapes
   from the plateau. The playable prototype is the next tier; final interiors
   are a future third tier. Do not load all detailed packs with `preload()` in
   an always-present script. Apply the same rule to arrays/manifests of resources.
3. **Threaded loading is only half the job.** Request resources early, poll for
   readiness, then activate small building/block units across frames. Never
   assume `load_threaded_request` makes `instantiate()` or physics registration
   incremental. China still had a large activation spike after this change.
4. **Start with small, bounded units.** A cheap all-city collision/massing core
   may remain resident while the player is in Moy if measured within budget.
   Activate it incrementally before use. Keep future decorative detail split
   by block. Do not build a complicated interior streaming system for this pass.
5. **Measure distance to bounds**, including tall towers and large slabs, not
   just plot centres. Consider the active controlled body, player, party support,
   occupied trains and any current vine anchor. Prefetch beyond the 52 m rope
   reach plus distance traveled during loading and a safety margin. Fast flight,
   rooftop travel and gate approaches must not outrun collision readiness.
6. **Retain collision while occupied or reachable.** Do not unload a standing
   surface, a held anchor, a moving train's upcoming track or an open interaction.
   Use separate load/unload thresholds. No skyline/prototype double rendering,
   double NPC/vendor spawn, repeated callbacks, or retained cached resources
   after a genuine unload. Do not keep the whole city alive through a manifest
   full of strong resource references.
7. **Keep costs proportional.** Share mesh/material resources; use
   `StaticMerge.merge()` for opaque static visuals per building/small block,
   spatial MultiMesh batches for repeated details, a small palette of ordinary
   materials, emissive color instead of room lights, no transparent tower walls.
   No giant whole-city merged mesh that defeats spatial culling.

Read `scripts/settlement_bake.gd`, `scripts/static_merge.gd`, the streaming
section of `scripts/chinese_village.gd`, and
`docs/diagnostics/2026-10-16-china-remediation.md` as precedents. **Do not copy
China's entire-settlement activation or its distance constants unchanged.**
If a required chunk is not ready, hold the explicit QA loading transition before
control starts; never expose missing collision and let the player fall through.

## 6. Collision and swinging: important implementation details

- Ground/blocking architecture and parkour landings must be hittable on physics
  **layer 1**. Vine anchor search queries that layer; a visual mesh or a group
  named “anchor” alone does nothing.
- **Keep different buildings on distinct physics bodies/RIDs.**
  `VineAnchorSearch.best(..., skip)` excludes the body holding the previous
  anchor. Combining district collision into one body can make the next tower
  disappear from the handover search. Merge visuals; preserve collision identity.
- Use existing `VineSwingMode`/`VineAnchorSearch`, `TraversalContext` and real
  playable controllers. Current search range 78 m; rope accepts 12–52 m;
  anchor must be at least 7 m above the swinger. These are 3D distances, not
  street width alone. Do not increase the rope range to make a bad prototype pass.
- Ordinary buildings can use simple blocking convex/box bodies. Roof contacts
  must agree with the visible usable top. Hollow rings, gates, wind gaps,
  viaduct openings and irregular concave polygons need decomposed shapes; one
  convex hull must not seal their openings or invade a lane.
- Build dimensions at final size. Avoid rotated collision primitives under
  inherited nonuniform scale. China needed
  `CollisionPolicy.fit_sheared_static_boxes()` and `WorldDoor.fit_to_parent()`
  to repair that mismatch. Prefer not to create it here.
  The fitted-box helper groups replacement bodies under the root passed to it;
  call it per building, never over the whole city if that combines anchor RIDs.
- Check winding/normals and the roof's underside. Rendering both sides is not
  proof that collision faces outward. Drop, land, jump and leave every roof family.
- Ramps, landings and floor holes share one section/datum. Measure the entire
  swept player volume, both edges and the headroom; do not exclude the owning
  building during a clearance test. No “visual stairs” over an impassable box.
- Trains and turning rings use physics-synchronized `AnimatableBody3D` solids.
  Retain moving-platform support, open holes and capped non-damaging push. Test
  a rider through stops, turns and reversals; do not teleport riders with a
  prototype-only character hack. Test existing small-character and mount support.
- Use the game's real liquid surface/swim APIs for the pond with bed, banks
  and exits. A shaded plane with no water behavior repeats the China failure.

## 7. World fit and preservation

City-plan X/Z numbers are already **world coordinates**. The Three.js `W()`
function subtracts (-560, 0) for its viewer only. Either keep a zero-origin Godot
root and use world X/Z, or subtract the centre once and put the root there.
Never apply both transforms. Heights are relative to one surveyed basin datum,
approximately -60 world Y, not absolute world Y=0. Align terrain, streets,
foundations, doors and all vertical systems with that same datum.

Current terrain still flattens only radius 78 at (-540, 0), whereas the new
Rim Walk is radius 200 at (-560, 0), with wall, gates and works beyond it.
Survey perimeter, gate and works sites. Update the terrain pad/transition and
matching placement exclusions coherently; do not lay a floating city-wide slab
over unsuitable terrain or report built floors through `get_mesh_height()`.

Audit at least `terrain_generator.gd`, `wilderness_scatter.gd` (old 78 m blorb
disk and Gem, old 105 m exclusion), and `skeleton_spawner.gd` (old centre and
110 m exclusion). Keep wild City blorbs/Gem outside the new bounds on supported,
accessible desert; constrain roaming too. Preserve their identities and pickup
behavior. Do not create party bans or story gates. Keep the city protected from
enemy spawns/encounter groups. No roads to other settlements are authorized.

## 8. Delivery sequence and acceptance

Finish the entire pass; these are verification checkpoints, not invitations to
stop and ask permission after each one.

1. Reconcile inputs. Produce coverage ledger and a small rendering/collision
   proof: one ordinary building, irregular house, rotated estate slab, ramp,
   open ring and two neighboring swingable bodies. Confirm design language.
2. Add **`scenes/moy_city_qa.tscn`** and its small driver. Reuse real terrain,
   player, party controls and traversal. Use the China QA pattern: remove other
   generators **before** they enter the tree. Keep F6/start predictable and
   provide documented QA-only access to the existing Leaf Hat and small body.
   Do not reset progression or grant inventory in the normal game.
3. Bake/build the complete ground and building massing from the data; compare
   plan-view coverage and skyline to the existing 3D model before detailing.
4. Add vertical routes, public hotel skeleton, gates, pond, station cores and
   rideable trains. Fix joins, headroom and solid openings before adding props.
5. Integrate the one city path into Crossroads with the cheap distant skyline,
   bounded activation and the corrected terrain/spawn bounds.
6. Run runtime/platforming and performance checks; fix failures. Save a short
   diagnostic with captures, measured limits and explicit remaining omissions.

Required proof, using actual built geometry/controllers:

- Coverage: every record/composite accounted for; footprint/rotation, heights
  and crown tops agree with plan; no duplicated old city or filled courtyard.
- Walk all four gates, Rim Walk, old roads, plaza connections, estate void-deck
  links and every Deck branch/access; test station landings and train-hall
  clearance. Sweep a real player capsule at corners as well as route centres.
- Land and jump off each roof type; cross representative neighbor roofs;
  test no under-roof trap, invisible wall, false floor or headroom blockage.
- Swing and **handover** through Old High Street, market/main streets,
  estate courts, downtown and the park anchors with the real search/mode.
  Test at least one chain across distinct buildings and one near a chunk edge.
  Repeat representative routes with Xiao Hou Zi. Record intended gaps that
  genuinely exceed current movement; do not redesign the plan silently.
- Ride a train roof across stations/turns and the city's vertical crossings;
  test gate halls, Timekeeper aperture and platform approach. Check the moving
  rings retain open centres. Swim in and exit the pond.
- Enter/leave/re-enter Moy twice, including fast aerial entry and entry while
  controlling another body. No missing supports, duplicated actors or growing
  retained resource counts. Verify the Helmsmith/shop and external Gem/blorbs.

Performance proof must use a **windowed rendered run**, fixed hardware,
resolution and renderer, after cold startup and again after warmup. Adapt
`tools/chinese_performance_probe.gd`; do not claim FPS from headless runs.
Record startup/control-ready time, individual activation/physics-registration
spikes, p50/p95/p99 and worst frame time, draws, visible triangles, static/video
memory, node/body counts and memory after two unload cycles. Include ordinary
Crossroads spawn, city approach, dense Old Moy, downtown looking up, an estate
court and a train ride. Compare against the same revision with Moy asleep.

Initial engineering targets, **not measurements or guarantees**: aim for 60 FPS;
at minimum sustained playable 30 FPS (p95 frame <=33.3 ms), no repeated >100 ms
activation stalls during travel. Aim to keep activation work within ~2 ms per
frame, rendered prototype views below ~1,500 draws and ~500,000 triangles, and
the prototype's incremental static memory within ~250 MiB. If these are missed,
reduce tessellation/material/scene overhead or pack size first. Never remove
substantial collision, omit buildings, or shrink their dimensions to meet a budget.
Report measured misses openly rather than silently changing acceptance.

Run `check_body_pose_owner.py`, `check_power_parity.py`, `check_design_language.py`,
the city plan check and the new runtime proof. Run Ohio/Snow/China regressions
if shared terrain/collision/controller code changes. Use the scratch-copy workflow
from `docs/handoff_ohio_village.md`; never race Godot instances or editor imports.
For any requested push, follow `AGENTS.md` and let hooks run. **No web export.**

Deliver the QA scene above, a reproducible bake tool with a stale-source check,
a runtime/platforming proof scene and a rendered performance probe. Use clear
Moy-specific names, for example `tools/bake_moy_city.tscn`,
`tools/check_moy_bake.py`, `tools/validate_moy_runtime.tscn` and
`tools/moy_performance_probe.tscn`. These are **requested future artifacts**,
not tools already present. Record their actual commands in the completion
report so the owner can repeat the checks. Reuse the small patterns in the
China tools, not their entire settlement builder.

**Fixed:** existing layout, dimensional scale, recognizable model silhouettes,
public circulation, real collision and existing traversal mechanics.

**Proposed for this prototype:** the scope reductions and initial measurement
budgets above; lightweight city core retained while occupied, bounded loading
and future detail packs by block.

**Open for review in play:** whether planned gaps, heights, routes and landmark
proportions are enjoyable; documented genuine data contradictions. Final art,
full interiors, story behavior and census expansion remain later work.
