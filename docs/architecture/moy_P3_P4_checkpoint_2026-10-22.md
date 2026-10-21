# P3/P4 practical construction checkpoint — 2026-10-22

The user approved moving on from P3/P4 construction under the practical
Ohio/Snowhio-quality, model-matching playable-environment bar. This is not an
all-green cold-start QA certificate. Current implementation was saved before
shutdown; the old builder and review/fix automation remain stopped.

## Preserved work

A fresh verified local recovery snapshot of current modified tracked files
and nonignored untracked files, including source, generated bake and evidence:
/Users/leonard/.codex/visualizations/2026/10/20/01a1569d-4c37-7322-82f8-d90125bb4ae4/checkpoints/moy-P3-P4-before-P5-lp_7eelo

`working-files.zip` passed CRC verification for all1911 entries. Its manifest
records each file SHA256, original HEAD, deleted/missing paths and exclusions;
`index.patch` preserves staged state. No reset, stash or broad source commit
was performed. Archive excludes ignored files, .git and deprecated build/web.
Use README instructions to recover into a separate baseline checkout; do not
extract blindly over later work. The live source/bake changes remain local
and uncommitted, available to P5 in the same checkout.

## Built and carried forward

Market facade/roof variants and Old City tower/shared-space forms were built,
the visible coping defect repaired, and the silhouette visibility corrected.
`docs/diagnostics/2026-10-21-moy-P3-P4-finish.md` records actual work/evidence.
Fresh `python3 tools/check_moy_bake.py` passes:386 packs,47 buildings,133 lots,
60 Old Houses,22 streets. Plan remains locked and unchanged.

Carry forward: three Hero smoke checks were skipped by slow local activation
(7/10 completed checks passed); no claim those three passed. A short gameplay
walkthrough, streaming follow-up and minor decorative/visual polish remain.
The final market photo was obstructed; the useful local market preview and
streamed Old City picture remain available. These follow-ups do not restart
precision-part certification or block P5 construction.

## Baseline source identities

- `scripts/moy_city_bake_builder.gd`: `e9cefb056aca24380f6554cf3bfe716fcf11cfb19d55b6959f2212961f3d86ea`.
- `scripts/superegg.gd`: `0b46f0274af48d8c0b9924481ed7a90563254c75c68ee3c91258daafed0b0af7`.
- `scripts/city_generator.gd`: `c61f9096ae2a9d686fd40539955a41855e8af35e937ec40a9eb1027b45c7be01`.
- `scripts/city_plan.gd`: `5705a10f92e26fc2d51227aec025cbccf41c4095fd93a6b48e9587b4f50c4938`.
- `assets/generated/moy_city/manifest.json`: `b2ee9ab216ddf887de4aab012757fc0db9060f52095dd0cf5c9e006f7bf18966`.
