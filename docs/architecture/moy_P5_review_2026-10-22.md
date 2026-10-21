# P5 sense-check and P6 checkpoint — 2026-10-22

P5 accepted at practical L2; detailed outcome is in the dated P5 brief review.
Submission: build chat `01a160ae-eee3-7e90-ad55-7d10527e581c`, completed turn
`01a160ae-f07e-75d2-abb6-20766ea7de89`.
Report: `docs/diagnostics/2026-10-22-moy-P5.md`.

Verified all submitted source and image hashes, read targeted source and test
logic, and inspected actual saved-pack images. Independent civic rerun passed
12/12, including both actual characters and 276 landing probes. Original
submission evidence preserved; independent rerun output is in
`/tmp/p5-sense-check.log` and `/tmp/moy-p5-civic-review-result.json`.
Main110/roof18 results were inspected, not independently replayed.
Pre-pull400-pack freshness and shared pose/parity/design checks pass.
This is construction acceptance with known cold-activation limits, not L4.

## Recoverable local source and bake

Verified ZIP recovery snapshot (1991 files, all entry CRCs passed):

`/Users/leonard/.codex/visualizations/2026/10/20/01a1569d-4c37-7322-82f8-d90125bb4ae4/checkpoints/moy-P5-before-pull-P6-x_v8nb9p`

Contains modified tracked and nonignored untracked files, SHA256 manifest and
index/status record against base `7b05b9ffab9864a5de71cd97c2f267c6b008323d`.
Ignored files, .git and deprecated build/web excluded. Restore into a separate
checkout, not blindly over live work. Implementation remains uncommitted;
this review does not stage or publish the inherited game source/bake.

Submitted source/evidence hashes:

```json
{
  "scripts/moy_estate_builder.gd": "3a59779f987ff94147a90837aab757b84813b95f4da97786f58dec49b112d8bc",
  "scripts/moy_estate_lift.gd": "f1e19f974d1b0f8b5b09b6a5af4c8a1edd4563aa5a4acc96c1c5c559b674c2ad",
  "scripts/moy_estate_lift_landing.gd": "baa4322da90011957cc1680e0c8c68d9f3b85909cc09ffd674e7e584a458713c",
  "tools/validate_moy_estate.gd": "d9333a590aa061ae3135b3eac40a218a368e4716595e2c5bd6fd1723c6520828",
  "tools/validate_moy_estate.tscn": "854059230f5795b12e1b95733aec21b19c6c130e25fbe98c96135e703b4ecdfd",
  "scripts/moy_city_bake_builder.gd": "50d972b96d3ccfe0115875aba9b547c5b80fee7a923f372d4e0a25ea9007e657",
  "tools/bake_moy_city.gd": "b794d4e675436247196275e7770ad059617f12acd7966ea77186e4f4b5adfc15",
  "assets/generated/moy_city/manifest.json": "2b2f1713ffde4ef91789377ca20d02fab010a8e9e68d6d290929379d0335d6b8"
}
```

## Latest upstream integrated

Fast-forwarded main through `8a7eb8df` (P7 garden/vine and clock/model revisions).
Three-way merged local roadmap and Crossing zero-area triangle fix. Regenerated
CityPlan from combined authoring rather than resolving generated data by hand.
Retained the local400-pack manifest as provenance of actual P3/P4/P5 geometry;
upstream's hash-only manifest describes an older different bake. The updated
Crossing plan/source makes the current bake stale until the next real batch
bake. Do not rewrite provenance hashes to claim a rebuild. P6's final integration
must regenerate a current bake, without expanding into P7 implementation.
The pre-pull snapshot retains the previously current P5 submission.

Proceed to P6 in the existing Sol implementation chat. No old automation restart.
