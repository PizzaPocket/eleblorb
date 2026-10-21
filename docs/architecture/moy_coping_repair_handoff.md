# Fresh implementation handoff: house076 coping repair

2026-10-21. One local GPT-6.1 Sol build chat owns this pilot. The previous
builder and automatic review/fix loop are stopped. This file is the current
task; do not reconstruct the task from the accumulated review history.

## Outcome

Repair the visible jagged triangular seam at MarketHouse_076's coping mitres.
First reproduce and fix it locally, then verify the repaired saved result in
the city once. Deliver a clean capped physical joint, not merely a passing
boundary-distance metric. Keep the scheduled shape/size and locked layout.

## Read only what this repair needs

- AGENTS.md, CLAUDE.md and roadmap's current task/acceptance clarification.
- The relevant architecture skill section1a for part/join shape conventions;
  P3 brief section2b and CityPlan.MARKET_HOUSE's `coping`/`band_chain` entries.
  Full dated review histories are not prerequisites for this scoped repair.
- `scripts/moy_city_bake_builder.gd`: `_market_rep_coping_run` (around1282)
  and its four callers; `scripts/superegg.gd`: `build_clipped_mesh` (cap fan).
- `tools/validate_moy_p3_boom_sample.gd`: `_measure_coping_mitres` (around531),
  and `tools/validate_moy_winding.gd` for existing fixtures.

## Reproduction and known evidence

Current saved pack: `assets/generated/moy_city/cell_04_04_p04.tscn`, owner
MarketHouse_076, CopingFront/Rear/West/East. Caps are plan-derived45-degree
bisectors of scheduled clipped SuperEgg runs, half cross-section0.06/0.12m,
exponents5.5/5.5. Do not redesign these to evade the defect.

Look at the actual current screenshots before editing:
`docs/diagnostics/images/2026-10-21-P3-focus/boom76_coping_mitre_front_side.png`
and `boom76_coping_mitre_adjacent_side.png` in the same folder. Both show
jagged triangular seam artifacts with normal back-face culling. Current check
JSON `docs/diagnostics/raw/2026-10-21-moy-P3-house076-construction-finish-check.json`
reports340 records, zero failures, four boundary residuals about3.079mm and
support on both sides. Its projected boundary test and single-plane winding
fixture do not prove final multi-cut cap topology or a clean rendered seam.
Root cause is not established; inspect actual triangles/edges/normals rather
than assuming a particular fix. Shared cap generation currently collects
cut-boundary points, angle-sorts and fans about their mean.

## Efficient execution and finish line

1. Reproduce the actual paired corner in a minimal local scene using the same
   generator/planes. Inspect rendered geometry and saved triangle relationships.
   Diagnose whether the fault is skin/cap triangulation, overlap, normal/winding,
   mismatched profiles or something else. No city rebakes while experimenting.
2. Make the smallest reusable repair. Exercise relevant single/multiple-cut
   fixtures and deliberate bad geometry where useful. Do not disable culling,
   hide seams with filler, widen tolerances or rewrite unrelated systems.
3. Once the local corner is clean, integrate/bake once and inspect the saved
   affected copings from both sides plus one real local city-context view.
   Verify winding/caps and physical collision/support at the altered seam.
   Run required relevant checks; explain any necessary extra shared regression.
4. Write ONE concise diagnostic with root cause, changed files, targeted checks,
   actual image paths, source/bake hashes and remaining limitations. Deliver
   actual code and verification in this chat, then stop for milestone review.

Not every surface must be reachable. No street-to-veranda test, vine/climbing
work, new powers, movement tuning, P4 construction, performance probes, broad
area scans, unrelated routes or all-owner rollout. Geometry that should be
physical stays physical; usable circulation and deliberate routes remain valid.

Preserve the large inherited working tree. Do not stage/commit it wholesale,
reset it, stash it away, or overwrite prior evidence. Use new evidence paths.
Do not regenerate/stage deprecated build/web. Respect owner identity and hooks.
Any own-change commit must be separable from the inherited baseline; otherwise
leave the repair reviewable locally with exact changed regions. No broad push
of the unreviewed inherited implementation. Keep reports concise; no polling
other chats, automatic fix rounds, extra agents or new testing platform.

## Recovery and baseline

A verified local recovery ZIP, SHA256 file inventory, original HEAD/index state
and recovery README are saved outside the repo at:
/Users/leonard/.codex/visualizations/2026/10/20/01a1569d-4c37-7322-82f8-d90125bb4ae4/checkpoints/moy-before-sol61-icyooxou
This is a recovery snapshot, not an accepted source commit. Do not load the
archive into context. Work in the SAME local checkout so unfinished sources,
bake and useful existing tools remain available. The new chat starts fresh;
only its task context is reset.

Baseline hashes before this pilot:
- `scripts/moy_city_bake_builder.gd`: `ac10a5d6f22d81e761737e110ba24b28551946e40c9f4885993924d4bab41f62`.
- `scripts/superegg.gd`: `8b74ff709357d425a97e22c7cf3fcbd7ca45b81058a970e4153faa112055d571`.
- `scripts/city_plan.gd`: `5705a10f92e26fc2d51227aec025cbccf41c4095fd93a6b48e9587b4f50c4938`.
- `assets/generated/moy_city/manifest.json`: `125919bec5b51cbdcceeb20a90e8fd6d755f2230adcf0e7471a64ea148fa3475`.
