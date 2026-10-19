# Package P2: bake, rendered performance and streaming

2026-10-19. Build-session brief. Read `moy_build_roadmap.md` first.
Status: **fix** (second review, section 11). Performance acceptance remains open.

## 1. Area, target and dependencies

The whole city and its Crossroads approach, including the skyline, terrain,
baked packs, occupied trains and unload boundary. P0 and P1 are the baseline.
P2 runs alongside the district packages; repeat its measurements after each.
Target: a reproducible rendered benchmark, bounded loading and activation,
safe unloading, and the budgets below met on a named reference machine.
P16 remains final optimization after the city is dressed.

Keep the locked version-1 plan, all substantial collision, every building,
public routes, dimensions and silhouettes. No new lore, district dressing,
interior system or movement redesign. Geometry changes require the existing
parts/joins schedules and collision rules; never trade correctness for FPS.

## 2. Read first

- `moy_playable_prototype.md`, sections 5 and the performance proof/budgets.
- `moy_prototype_pass_4.md`, sections 4–5, for the RID/crash handoff.
- `../diagnostics/2026-10-18-moy-prototype-pass-4.md`, measured limits.
- `moy_pkg_P0.md`, the final baseline and solid-fill rule; the latest P1
  diagnostic named by the roadmap.
- `../../tools/moy_performance_probe.gd`, `validate_moy_runtime.gd`,
  `check_moy_bake.py`, `bake_moy_city.gd`.
- `../../scripts/city_generator.gd`, `moy_city_bake_builder.gd`,
  `settlement_bake.gd`, `static_merge.gd`; terrain loading called by them.
- Plan source `../../tools/city_layout.py` and generated
  `../../scripts/city_plan.gd` for bounds and routes, not new dimensions.
- Model atlas: `../drawings/moy_performance_3d.html`. It reuses the existing
  plan-driven city model; its views locate tests, not measured engine results.

## 3. Start by reproducing the owed failures

The pass-4 rendered launch exited 134 before a log. Its headless follow-up
reported wrong RID, null storage/mesh and unimplemented-base-type errors.
The full terrain/pack stream later hit signal 11; focused P1 checks do not
clear that failure. Reproduce on the current revision before assigning cause.

Capture engine version, OS, renderer/device, launch command, exit code,
stdout/stderr and a native crash backtrace when available. Separate real
renderer errors from dummy-renderer limitations. Fix lifetime/ownership or
activation ordering at the source; do not suppress diagnostics. If an engine
defect requires a version change, preserve the reproducer and test both
versions on the same machine. A crash, hung readiness wait, missing sample
or invalid renderer result must fail the benchmark.

Historical CPU-only context (not current baselines): startup 23.5 s;
approach 7.86 s; largest activation frame 92.69 ms; 30 samples over 50 ms;
185 packs in the full stream, 188 in isolated QA; two reload cycles around
11 s. Do not freeze those pack counts as acceptance: compare against the
current manifest's eligible packs and prove coverage.

## 4. Build the measurement contract

Extend the existing probe rather than introducing a parallel benchmark.
Keep ordinary Crossroads-to-Moy and isolated `--qa` modes. Add explicit
configuration, recorded in the output: fixed resolution, renderer, VSync/FPS
cap, warmup, sample duration, seed/time and route. Hold hardware and settings
constant across comparisons. Record GPU/driver, CPU, RAM and commit.

- A rendered run must verify a real rendering backend, visible geometry and
  completed frames. Reject headless/dummy runs as rendering evidence.
  Software rendering may diagnose correctness but cannot certify hardware
  budgets. An unavailable display/GPU is a reported blocker.
- Record raw frame intervals plus summaries, not only the current printed
  mean and one end-of-sample draw count. At least 30 seconds per stationary
  view after readiness and at least 5 seconds warmup; record sample counts.
  Use at least three fresh-process runs and three warm traversals.
- Measure p50/p95/p99/worst frame ms; draw/triangle distributions and peaks;
  static and video memory, nodes, collision bodies/shapes, active/requested
  packs; request, deserialize, instantiate, registration, activation and
  release timing. Mark unavailable monitors explicitly, never zero.
- Separate loading-transition time from player-controlled travel. Log maximum
  per-frame activation work and travel frames above 50/100 ms with their
  position, pack and phase. A 120-frame warmup must not hide activation stalls.
- Compare the same revision and settings with Moy asleep, without changing
  source between samples. Validate the baseline state rather than assuming
  that an isolated empty scene has equivalent Crossroads costs.
- Write machine-readable raw data and a readable summary to uniquely named
  P2 diagnostic files. All requested views/routes/cycles must complete;
  timeouts and incomplete runs exit nonzero and retain partial evidence.
  Document every new flag and exact command in the diagnostic.

## 5. Budgets and verdicts

These retain the prototype's engineering targets; do not silently relax them.

| Measure | Acceptance / target |
|---|---|
| Sustained rendered frame time | Required p95 <=33.3 ms per view and travel segment; aim 60 FPS |
| Controlled travel | No repeated >100 ms activation stalls; report every >100 ms frame and cause |
| Main-thread activation work | Aim <=2 ms per frame; report p95, maximum and exceedance count |
| Rendered prototype complexity | Aim below ~1,500 draws and ~500,000 triangles; report peaks as well as distributions |
| Incremental static memory over Moy-asleep | Aim <=250 MiB, same state/settings |
| Loading correctness | No missing support, exposed unloaded collision, duplicated actors, crash or hang |
| Unload cycles | Two complete leave/re-enter cycles, no unexplained growth in retained packs/resources/nodes |

No invented startup time limit: report cold/control-ready and reload times,
then propose a justified bound if necessary. Give a pass/miss for each required
gate and a met/missed result for every aim. A missed aim requires measured
remediation or an explicit owner decision; it is not a quiet pass.
Keep P2 in build/fix while required rendered evidence or crash diagnosis is owed.

## 6. Baking and streaming work

- Preserve reproducible offline baking, source signatures and coverage.
  Missing/stale packs must give an authoring error; no expensive runtime
  fallback construction or whole-city static merging.
- Profile before changing pack size. Reduce tessellation/material overhead,
  share meshes/materials and spatially batch repeated pieces first. Keep
  merge/culling units local; do not hide the city in one giant mesh.
- Use bounds-based eligibility and load/unload hysteresis. Request early,
  poll completion, then activate in bounded frame work. Threaded resource
  loading alone does not bound instantiation or physics registration.
- Account for the active controlled body, player/party supports, occupied
  train, held vine anchor and open interaction. Prefetch beyond the 52 m rope
  reach plus measured travel distance during loading and a safety margin.
- Keep supports alive until no longer occupied or reachable. Cover a train's
  upcoming route; do not unload an anchor or a landing while in use.
  A cheap collision/massing core may remain while in Moy only if measured.
- On genuine unload release strong references, deferred work and callbacks
  safely. Never free a resource while a pending activation uses it. Show
  pending requests, active packs and retained resources settling after each
  cycle; explain intentional caches and distinguish them from leaks.
- Prevent double skyline/detail rendering and duplicate NPC/vendor spawns.
  Explicitly hold the loading transition before handing control to a body
  whose collision region is not ready.

## 7. Routes, viewpoints and collision proof

Use the actual built world/controllers. Record exact world-space camera,
target and controlled-body positions, FOV and frame settings with each result.
Atlas views are orientation aids; do not substitute browser rendering for Godot.

1. Ordinary Crossroads spawn with Moy asleep, then the real approach.
2. Dense Old Moy at street and rooftop/swing height, with market frontage.
3. Downtown looking up; test tall-bound eligibility above the footprint.
4. North Estate court and void-deck/linkway travel.
5. The Crossing and the East Gate train hall, where multiple tiers overlap.
6. A real moving train ride through a station, turn and city vertical crossing.
   The current probe's stationary `train_ride` camera does not prove this.
7. Fast flight/entry at each gate; a cross-pack vine handover; occupied roof,
   platform and train support near unload thresholds. Repeat representative
   routes with Xiao Hou Zi and entry while controlling another body.
8. Leave, wait for actual unload completion, return twice. Report actor,
   node, pack, resource and memory counts at equivalent settled states.

Capture noon/dusk images of Old Moy, downtown, estate court, Crossing and
train hall; add before/after images for changed pack boundaries or LOD.
Use P0's screenshot rig with unique P2 names. Test entry/exit, collision
readiness and geometry against the same build used for performance.

## 8. Checks and report

From repository root, use the installed Godot 4.7 executable (`$GODOT` below):

```sh
python3 tools/check_body_pose_owner.py
python3 tools/check_power_parity.py
python3 tools/check_design_language.py
python3 tools/city_layout.py --json /tmp/moy-P2-plan.json
python3 tools/check_moy_bake.py
"$GODOT" --headless --path . tools/validate_city_plan.tscn
"$GODOT" --headless --path . tools/validate_moy_runtime.tscn
"$GODOT" --headless --path . tools/world_checks.tscn -- --kingdom=moy --date=2026-10-19-P2
"$GODOT" --path . tools/moy_performance_probe.tscn
"$GODOT" --path . tools/moy_performance_probe.tscn -- --qa
```

The last two are existing entry points; report the final benchmark flags,
resolution and output paths after extending the probe. Headless checks cannot
replace them. Use a fresh unique date/run suffix for repeated P0 runs; never
overwrite the committed baseline. Run P0 fixtures and compare findings by
check/location against its latest baseline, including existing reach debt.
Do not claim the whole city has zero findings. Any new blocking geometry
finding introduced by P2 is a regression. Re-run Ohio/Snow/China if shared
terrain/collision/controller code changes. Keep bake freshness after final edits.

Write `docs/diagnostics/<date>-moy-P2.md`: failure reproduction and fix,
commands/exits, hardware/settings, complete raw sample links, per-view budget
table before/after, startup/activation/release breakdowns, two unload cycles,
geometry regressions, screenshots, remaining misses and repeat instructions.
No web export. Follow AGENTS.md for pushing; do not bypass hooks.

## 9. Decisions log

- 2026-10-19: P2 owns the rendered launch failure, RID follow-up and full-stream
  crash deferred from P1. Focused pack tests remain useful but insufficient.
- 2026-10-19: retain prototype budgets, distinguish required gates from aims,
  and require equivalent-state baselines and real moving-train coverage.
- 2026-10-19: no city geometry or new kit is designed here. The P2 atlas
  reuses the plan-driven city model and its existing sectional/place views;
  no new parts/joins schedule or plan regeneration is required for this brief.
- 2026-10-19: artifact publication must be performed through the owner's
  artifact tooling; this cloud session has no artifact publication capability.
  The local atlas and brief are usable independently; no published URL claimed.

## 10. First review — 2026-10-19: fix

Reviewed build `7bcbb09`, diagnostic
`../diagnostics/2026-10-19-moy-P2.md`, raw r2–r5 JSON/logs,
the streaming/probe source diff, P0 reports, and overview/civic screenshots.
**Result: fix.** Keep the instrumentation and raw evidence; do not mark P2 done.
The diagnostic correctly admits the missing routes and missed budgets.

Verified in review: r2/r3/r4 each contain seven 30-second samples and two cycles,
with identical source hashes; their city-generator hash differs from final source.
R5 matches the final recorded source hashes but has only one stationary sample.
The P0 category counts equal the baseline; bake freshness passes (205 packs).
This review does not independently reproduce the Apple M5 timings on Linux.

### Fix in this order

1. **Make evidence and acceptance explicit in the runner.**
   `accepted_rendering_evidence=true` is only a backend/sample flag today;
   r4 has four `travel_frame_over_100ms` errors but `failed=false`.
   Preserve a separate rendering-validity result and add required-gate verdicts.
   Exit nonzero for incomplete routes/cycles, required frame/stall misses and
   readiness failures. A focused `--route` run must say partial, never full-suite
   acceptance. Validate unknown/missing route names and expected sample counts.
   The unload wait stops after 45 seconds but never fails if packs remain:
   require actual settled unload completion and fail on timeout.
   Add meaningful negative cases showing each failure path returns nonzero.

2. **Fix benchmark overhead before trusting memory/stage attribution.**
   `city_generator.gd` now appends activation, frame and release dictionaries
   indefinitely in ordinary play, and recursively counts bodies in the timed
   streaming path even without a benchmark. Make detailed telemetry opt-in,
   bounded or drained; retain lightweight counters if needed.
   The probe holds all raw frames and serializes accumulated data between
   views, so later static-memory samples include growing benchmark storage.
   Stream raw records to disk or quantify/exclude observer allocation from the
   incremental-city memory verdict; compare equivalent settled states.
   Separate request completion from activation eligibility: current
   `request_to_ready_ms` is measured when an eligible pack is finally consumed
   and can include activation-queue delay. `add_child` measures synchronous
   tree insertion, not all deferred physics/GPU work. Name and correlate these
   measurements accurately; do not present them as isolated deserialize,
   registration or actual free-completion timings without proof.

3. **Close the unload/lifetime regression.**
   R5 has 0 active/requested/cached-manifest packs after unload, but node counts
   increase 18,611 → 18,666 and reload counts 42,661 → 42,716.
   Identify the +55 nodes by class/path/owner and include actor-group identities,
   unique residents/vendor counts and pending/deferred work in equivalent states.
   Do not assume the growth is duplicate actors until inspected.
   Verify pending ResourceLoader jobs are consumed/released, rather than only
   erasing `_moy_requested`; test leaving during requests and rapid re-entry.
   In the 72–140 m hotel annulus, the same stream tick now requests hotel
   paths and then erases their tracking state in the release branch. Keep
   prefetched requests tracked until their intended release threshold, and
   demonstrate no repeated request/reset loop while standing in that annulus.
   Hotel request radius 140 m / activation 48 m gives 92 m lead; prove the
   remaining 40 m beyond rope reach covers measured travel/load latency.
   Keep occupancy/anchor/train supports until safe release, including when the
   controlled body differs from `../Player`. Current city-wide eligibility
   still uses that player's XZ distance to CITY_CENTER, so it does not itself
   demonstrate the required tall-bounds/multiple-body streaming contract.

4. **Optimize the measured bottlenecks, then remeasure.**
   Estate p95 is 58.116 / 58.844 / 58.558 ms; around 7,500 draws and 13 million
   primitives. Activation p95 is around 81–83 ms; synchronous activation stages
   reach about 29 ms. Profile the heavy packs/materials/meshes and split or
   simplify allowed local work without changing locked dimensions, collision
   or coverage. Bound per-frame activation work and preserve spatial culling.
   The Crossroads baseline itself peaks near 901k triangles: the diagnostic's
   statement that Crossroads meets both complexity aims is incorrect.
   Only the Crossing meets both in this dataset. Correct the summary and keep
   Crossroads cost distinct from incremental Moy cost.
   The recorded `crossing_east_gate` camera is at world x=-560 (the Crossing);
   capture a separate actual East Gate train-hall view identified from plan data.

5. **Implement the required real routes and repeatability proof.**
   Add an actual moving-train ride through station, turn and vertical crossing;
   controlled fast entry at all four gates; a cross-pack vine handover; occupied
   roof/platform/train boundaries; Xiao Hou Zi and alternate-body entry.
   Record support readiness and controller/anchor/train state, not teleports
   or stationary camera labels. Run at least three warm traversals as well as
   three fresh processes on final source, one Godot process per checkout.
   R5 overlapped another validator, so use it only for its stated release-state
   diagnosis, not final performance comparison. Repeat full and isolated QA
   runtime checks; retain a reproducer/backtrace for any returning native crash.
   Successful hardware runs establish non-reproduction of exit 134 there, not
   its original cause; classify that limitation honestly.

6. **Complete and correct the visual/check report.**
   The 112 saved images are overview, civic/crossing streets, and underside/
   escalator fixtures. They do not include the claimed dedicated Old Moy,
   Downtown, Estate Court and train-hall benchmark shots. Add named noon/dusk
   images at the actual benchmark cameras with matching run/source metadata.
   Keep existing useful P0/P1 images. Re-run P0 fixtures (not documented in this
   submission) and compare changed findings by location/path, preserving the
   committed baseline and its existing debt. Re-run bake freshness and required
   validators after final edits. Report command exits and every remaining miss.

Deliver `docs/diagnostics/<date>-moy-P2-fixes.md` with each numbered item,
final-source raw runs, gate table, node/actor lifetime evidence, route proofs,
and correctly named screenshots. Do not loosen the original budgets or claim
completion from a runner's rendering-evidence flag.

**Handoff to Luna:** Build the P2 fixes in section 10 of
`docs/architecture/moy_pkg_P2.md`, keeping the original acceptance contract.

## 11. Second review — 2026-10-19: fix

Reviewed `b4de2b2`, `../diagnostics/2026-10-19-moy-P2-fixes.md`,
the three final-clean raw runs, streaming/probe/screenshot changes, and
Estate Court/East Gate noon screenshots. **Result: fix.**
This pass closes useful instrumentation work; it does not close P2.

### Keep / closed for this review

- All three final-clean runs match the submitted source hashes. Each contains
  seven stationary samples and two settled cycles; all correctly record
  `acceptance_passed=false`.
- Telemetry is opt-in and its arrays capped. Hotel requests have separate
  release hysteresis and loaded requests are consumed before discard.
- The +55-node observation is explained by the distant skeleton encounter.
  In the final runs, both unloads return to 18,639 nodes and both reloads to
  42,606; city actor counts are stable. Do not keep calling this a proven
  city actor leak. Rapid re-entry/support retention still need route proof.
- Named benchmark screenshots and their manifest now exist, including the
  separate East Gate view. Rendering validity and static benchmark acceptance
  are distinct, with negative contract fixtures.
- Reviewer quick checks and 205-pack bake freshness pass. The contract success
  and frame-budget failure processes returned 0 and 1 respectively locally.
  Apple M5 performance is assessed from submitted evidence, not rerun on Linux.

### Remaining work for Luna

1. **Do the performance work before another full acceptance review.**
   The diagnostic explicitly says no asset/material/tessellation optimization
   or bounded activation queue was completed. Estate p95 is
   63.762 / 60.483 / 59.629 ms (median 60.483), around 7,430 peak draws and
   12.84 million primitives; synchronous activation p95 is 4.747 ms and
   maximum 25.413 ms. Each process still has 2–3 transition stalls over 100 ms.
   Profile the expensive packs, apply the allowed local batching/sharing/
   tessellation and activation scheduling changes, then provide before/after
   evidence on identical hardware/settings. Preserve dimensions, collision,
   routes, source signatures and spatial culling. No budget relaxation.

2. **Implement and measure the missing controlled route suite.**
   Moving train through station/turn/vertical crossing; four-gate fast entry;
   cross-pack vine handover; occupied roof/platform/train threshold support;
   Xiao Hou Zi and alternate-body entry; hotel annulus hold and rapid re-entry
   while requests are pending. Prove bounds/multiple-body eligibility rather
   than leaving it tied only to Player XZ distance to CITY_CENTER. Repeat
   three warm controlled traversals, then three final-source fresh processes.
   Capture support readiness and state with the actual controllers.

3. **Prevent static-only success from implying full P2 acceptance.**
   `_finalize_acceptance` currently calls seven camera samples plus two cycles
   the full suite. Add explicit required traversal/support coverage and results
   to the gate table and machine-readable acceptance before it can pass P2.
   Until implemented, label this stationary benchmark scope and keep the
   missing route gates unrun/failing. Test the incomplete-route result.

4. **Correct the remaining measurement/report details.**
   - `_summarize` divides total frame-buffer bytes by frame count, subtracting
     just 104 bytes from every memory sample. It does not remove accumulated
     buffer storage. Track actual allocated capacity at capture time, or report
     unadjusted memory with a quantified observer-error bound. Also account for
     retained telemetry, summaries and lifetime inventories where relevant.
     This is a small correction here, not an explanation for Estate's FPS miss.
   - Correct the summary sentence saying median East Gate p95 remains over
     budget: its median is 33.089 ms, below 33.3; one run is 33.727, so the
     all-runs gate still misses. Crossroads median is 18.450 with actual range
     17.499–18.876, not 18.181–18.876. Keep raw runs unchanged.
   - Screenshot camera far is left at the engine default while the probe uses
     1,800 m. Set and record matching clipping planes and ensure each view's
     actual current camera/readiness matches the benchmark. Existing images
     establish that the named views render; they do not establish a train ride.
   - Distinguish observed completion-poll time from exact loader completion,
     and tree exit from complete resource/GPU destruction as already requested.

5. **Finish the owed correctness checks on the optimized final build.**
   Re-run isolated QA after final edits, P0 fixtures and the location/path
   comparison against the preserved committed baseline, full runtime/plan
   checks and bake freshness. Document exact commands/exits. Keep existing
   geometry debt distinct from any P2 regression; no new blocking regression.
   Preserve native-crash evidence if one returns; current non-reproduction
   remains an acknowledged limitation.

Deliver `docs/diagnostics/<date>-moy-P2-fixes-2.md` with each remaining item,
measured optimization results, complete route gates, final-source repeated runs,
and checks. Preserve the completed instrumentation rather than replacing it.

**Handoff to Luna:** Continue P2 from section 11 of
`docs/architecture/moy_pkg_P2.md`. Prioritize actual performance remediation
and controlled-route proof; the original budgets remain binding.
