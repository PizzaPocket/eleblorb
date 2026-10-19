# Moy P2 section 11 handoff

**Status:** Paused at a safe stopping point. P2 continues alongside district
replacements. Its current performance readings are a baseline, not a gate for
those builds. The original P2 budgets remain unchanged.

## Changes in this pass

- Added bounded per-pack streaming distances, pack AABB distance estimates,
  controlled-body/held-anchor interest, train route look-ahead, and a cap on
  threaded load-status polling per frame.
- Added explicit controlled-route proof requirements and travel-frame budget
  reporting to the performance probe. QA and screenshot paths request the full
  city; screenshot cameras now record their clipping range.
- Corrected memory reporting to use observed values and retained telemetry.
- Reverted the static-mesh batching experiment and restored the checked-in 205
  pack bake. It removed semantically named visuals and failed runtime collision
  and support checks, so it is not part of this change.

## Checks and baseline

- `python3 tools/check_moy_bake.py` passed: 205 packs, 47 buildings, 133 lots,
  60 old houses, and 22 streets.
- `git diff --check` passed before final cleanup.
- The quick Godot contract check did not reach its test. A sandboxed launch
  crashed while opening a user log; a normal launch then reported missing
  global-class identifiers (`WorldState`, `LoadingScreen`, `PartyControl`,
  among others). Re-run after the project class cache is available.
- The earlier temporary batching run of `validate_moy_runtime` failed 55
  checks, including missing named visuals and collision/support mismatches.
  Batching was reverted. No collision geometry was edited by the streaming
  changes, but collision safety of the new activation/release behavior remains
  unproved.
- Exploratory run `p2-s11-opt-1` (30 seconds/view, Apple M5, Godot 4.7.1,
  Forward+, 1280x720, VSync off) recorded p95 frame times in milliseconds:
  Crossroads 20.201, Old street 28.722, rooftop 30.452, Downtown 31.593,
  Estate 55.939, Crossing 28.069, East gate 31.380. Estate exceeded the
  33.3 ms budget. Streaming cycles did not settle (25/36 residual requests).
  These measurements predate the final interest-point/poll-cap edits and are
  not acceptance evidence. The raw run is in
  `docs/diagnostics/raw/2026-10-19-moy-P2-p2-s11-opt-1.json` and its per-view
  JSONL files.

## Unfinished

- Resolve project class-cache loading and run the required source/runtime
  checks on the current changes.
- Prove controlled routes across train travel, gate entries, vine handover,
  support, Xiao, alternate body, hotel hold, and rapid re-entry, including
  three warm traversals and the existing travel-frame budget.
- Investigate residual load/unload requests and Estate performance. Do not
  treat performance as a prerequisite for district replacements.
- Revisit the historical exit-134 report with a reproducible backtrace; no
  native loading crash was reproduced in the exploratory run recorded here.

No further optimization or benchmark cycle was started for this handoff.
