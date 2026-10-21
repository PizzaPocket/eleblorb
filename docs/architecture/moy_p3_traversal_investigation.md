# P3 house076 traversal investigation — one submission

> Superseded acceptance interpretation, 2026-10-21: the user clarified that
> not every surface must be reachable. Blanket house076 access blockers below
> are historical and no longer gate its construction milestone. Raw trial
> outcomes remain valid. Current work is `moy_p3_boom_construction_finish.md`;
> retain physical collision, usable circulation and explicit authored routes.

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
- State: one investigation reviewed; first-floor access demonstrated only for Xiao with special loadout. Root cause of Hero/floor-to-floor failure unresolved; monitor PAUSED, no implementation continuation.
- Last reviewed investigation: 01a15cc1-1e9f-70f3-804e-c2d5f935c055; completed and stopped editing. Review result: useful evidence, incomplete route/root-cause proof.
- Prior cursor: 7a55a42b-a1c8-42f5-878b-cbca088e7147:11.
- Full P3 and house076 milestone remain unaccepted; P4 remains fix.

Keep the construction-fix loop paused. Reuse its heartbeat only as a quiet
20-minute monitor for this one investigation: compact status while active,
no duplicate prompts or repeated history scans; review once then pause.

## Investigation review — 2026-10-21: evidence credited; route unresolved; paused

Reviewed stopped turn 01a15cc1-1e9f-70f3-804e-c2d5f935c055 once, against this
brief and P3's existing column/floor-to-floor requirement. Report:
`../diagnostics/2026-10-21-moy-house076-traversal-investigation.md`.
Trace: `../diagnostics/raw/2026-10-21-moy-house076-traversal.json`, SHA-256
`d982fe4c38d74c480c3ad96f15e9ea59b72863b41d456c8b582e058794ac4468`.
Frame manifest: `../diagnostics/images/2026-10-21-house076-traversal/shot-manifest.json`,
SHA-256 `6ef1291dce9b005497a4933908daa24b6261338df9300d74abc327648a42c5b8`.
Verified trace binding and all16 image hashes; visually inspected frames
0/60/120/540 for both characters. These are genuine windowed GPU attempts,
though camera/slab occlusion limits visual clarity at some points. They do
not show a completed repeated climb.

Plan/builder/bake hashes still match the pre-investigation frozen baseline:
`5705a10f92e26fc2d51227aec025cbccf41c4095fd93a6b48e9587b4f50c4938`,
`61f0c6b3f55db0471856db95a8b8da191ed45819505600685a65ee9e168038bf`,
`e23fbd7fe58cd4a2462cfe40d4720c5015cd5055de895717b62e6bd780f1bcf5`.
Current controller/mode and instrumentation hashes match those in the report.
Inspection of the capture runner shows real input through actual drivers,
initial placement on the street and no subsequent forced body trajectory.
The fixture supplies six Plant blorbs and Leaf Hat: availability is debug
fixture evidence, not demonstrated normal progression or unequipped access.

**Observed outcome:** both verified active controllers attach a vine to the
house and rise above first-veranda level. Xiao reaches the named first floor
and holds it30/30 frames with zero drift. Hero returns to street support and
has0/30 named first-floor support frames. Inputs are one fixed camera aim,
forward0–59, cast0–2 and release60–62; each sampled trace has only one active
anchor position. This is not an ordinary-jump reach limit. It demonstrates
Xiao first-floor access under the stated loadout, not Hero access or climbing
from floor to floor. Neither column-specific contact nor repeated handoff is
demonstrated. Existing isolated support credit remains separate.

**Root-cause qualification:** the report classifies a controller/mode gap and
proposes a new shared column-climbing behavior. That proposed correction is
not yet justified as the smallest necessary fix. Existing `VineSwingMode`
already implements `_pull_for_climb`, camera-driven climb intent, and upward
re-gripping through `_catch_next(..., true)`; source lines around365–409 show
the conditions. It is more than a release-only rope arc. One fixed cast/
release sequence with different outcomes for different bodies does not
establish defective character parity, impossible geometry, or absence of an
existing viable route. Failure to demonstrate the prescribed path is real;
the cause between approach/aim/release choice, mode/contact conditions and
geometry remains unresolved. Do not label a new movement feature approved.

**Decision for reassessment:** determine whether P3's climb is intended to
require this equipment, and whether existing upward pull/re-grip can support
a controlled landing and repeated ascent. Any later authorized experiment
should expose those states and target Hero's landing/handoff, not repeat the
same fixed sequence or ordinary jump. If evidence then identifies a missing
behavior, propose the minimum shared correction with both-character parity
before implementing it. Current geometry, movement settings, coping and P4
remain unchanged by this investigation; full P3 acceptance remains open.

One-submission investigation is finished and monitoring is PAUSED. No second
investigation, implementation fix, new mode or package advancement has been
dispatched. This checkpoint preserves builder evidence and commits only
review-owned documents.
