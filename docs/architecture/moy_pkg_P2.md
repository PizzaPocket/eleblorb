# Package P2: bake, rendered performance and streaming

2026-10-19. Build-session brief. Read `moy_build_roadmap.md` first.
Status: **ready for build**. No performance acceptance is claimed by this brief.

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

