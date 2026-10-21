# P3 house076 traversal investigation — one submission

2026-10-21. User authorized this investigation after the bounded build loop
paused. This is a diagnostic task, not a third construction-fix round.

## Question

Can hero and Xiao reach MarketHouse_076's first veranda and continue floor to
floor using the intended approach and the existing shared traversal system?
P3 brief section3 requires climbing boom-house columns floor to floor;
`moy_market_lanes.md` section3.6 calls columns/stacked verandas a ladder.
A direct street jump is not sufficient to test that intention. Last review:
`moy_p3_boom_milestone.md`, final review at a0cbeaa.

## Bounds

- Preserve plan, bake geometry, controller/mode code and movement settings.
  No retuning jump height, enabling unrelated flight to bypass the route,
  adding stairs/interiors, moving supports or implementing a new climbing
  system. Discover the actual current mode, eligibility, equipment and input
  contract from source; distinguish missing behavior from an uninvoked mode.
- Trace the intended column/hold approach on this actual owner with its local
  neighbours. Record normal prerequisites explicitly. Do not imply a special
  test loadout is generally available. If no relevant existing climbing mode
  exists, identify the exact missing link and report that finding.
- Attempt the intended route with both active playable controllers using real
  input, local loaded collision, named contact/support and continuous traces.
  A placed start may initialize the trial on the street; no subsequent
  teleport or forced body trajectory counts as access. Separate isolated
  support probes from continuous traversal, retaining their existing credit.
- Use the existing harness/capture tools. Small, scoped instrumentation fixes
  are allowed to deliver genuine inputs or observe mode/contact/camera state;
  record them separately from immutable game/source hashes. Do not alter
  acceptance conditions to obtain a pass or build a new test framework.
- Capture a short GPU-rendered demonstration for each character (video when
  available; otherwise an ordered timed frame sequence tied to input/state
  traces). Static posed shots and headless traces alone are not rendered
  traversal demonstrations. If rendered capture is blocked, record the exact
  limitation and stop; do not start an extended capture-tool rewrite.
- One focused attempt set, one concise report, then STOP. No P4, performance,
  broad area audit, coping repair, all-owner rollout or unrelated route work.
  Preserve all inherited working-tree work. No Git index/commit/push or edits
  to reviewer-owned documents during the investigation.

## Handoff and decision

Write `docs/diagnostics/<date>-moy-house076-traversal-investigation.md` with:
actual intended path and mode/prerequisites; changed instrumentation files;
source/plan/bake hashes; trial inputs, trajectory, named surfaces and landing
hold for each character; exact rendered evidence paths; and root cause.
Classify the result as demonstrated route, geometry obstruction/reach gap,
controller/mode availability or behavior gap, harness/input error, or still
unresolved (with precise reason). Avoid declaring all traversal infeasible
from one failed ordinary jump.

If blocked, provide the smallest proposed correction and its implications,
without implementing it. Any change to movement/design follows a separate
user decision. Reviewer will assess this one stable submission and report;
there is no automatic implementation continuation or second investigation.
Monitoring pauses after the review, including on an incomplete/blocked result.

## Coordination state

- Build chat: Luna Build Moy P3 and p4, local.
- Build thread: 01a153b7-0f75-7871-9324-bdd8efef7e6c.
- State: authorized for one investigation; dispatch after this checkpoint.
- Last observed completed build: 01a15bf0-06fe-7a91-9332-9eb5208c8dfe,
  already reviewed; never restart/review it as a new submission.
- Prior cursor: 7a55a42b-a1c8-42f5-878b-cbca088e7147:9.
- Full P3 and house076 milestone remain unaccepted; P4 remains fix.

Keep the construction-fix loop paused. Reuse its heartbeat only as a quiet
20-minute monitor for this one investigation: compact status while active,
no duplicate prompts or repeated history scans; review once then pause.
