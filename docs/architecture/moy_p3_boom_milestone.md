# P3 boom-house milestone: bounded build and review

> Superseded acceptance interpretation, 2026-10-21: the user clarified that
> not every surface must be reachable. Blanket house076 access blockers below
> are historical and no longer gate its construction milestone. Raw trial
> outcomes remain valid. Current work is `moy_p3_boom_construction_finish.md`;
> retain physical collision, usable circulation and explicit authored routes.

2026-10-21. Authorized by the user to automate the milestone workflow between
this review chat and the existing build chat. This replaces the open-ended
P3/P4 loop. The package briefs and their full L2 criteria remain binding.

## Scope and acceptance

Finish MarketHouse_076 as one complete, reusable, plan-driven boom-house
representative in the real city. Retain its actual plan dimensions, ownership,
neighbours and variant choices. No owner-specific geometry exception and no
layout redesign. This milestone is not package-wide P3 acceptance.

- Reconcile all 66 part rows and 15 join rows against the unchanged schedule.
  Every applicable row needs saved geometry/collision paths and measured
  dimensions or fit evidence. Explain each genuine variant exclusion from
  plan data. Presence, a node name or a passing count alone is insufficient.
- Complete the applicable facade, plinth, shop window dressing, floor-cut
  leaves/openings/frames, veranda, guards/returns, parapet/coping, roof and
  scheduled signs. Follow the shared shape, cap, seat and collision rules.
  Do not add an interior core or enterable flat; this house is exterior only.
- Show readable GPU views in city context with neighbours, front and roof,
  plus enough near views to assess the physical joins from both sides.
  Reuse capture tooling. Isolated pack images can supplement these views.
- Verify changed substantial surfaces and deliberate landings with hero and
  Xiao, including stationary support and relevant facade/roof access. Use
  the existing shared controllers and harness; no teleport-as-movement proof.
  Associate each test with its actual scope. Headless physics is not GPU proof.
- Check the representative and immediately affected neighbours for owned
  overlap, access, headroom and support problems, with current hashes and
  owner attribution. Reuse targeted audit filters; do not rerun the city
  suite just to produce a new total. If existing tooling cannot isolate the
  area, document the limit and stop rather than building a new audit platform.

P4, other P3 variants, all-owner rollout, second-owner replication and P2
performance are outside this milestone. Retain credited earlier evidence;
source changes invalidate only evidence whose dependencies they affect.
A representative pass does not close those package-level obligations.

## Work and review protocol

Builder owns implementation, tests, bake, capture and diagnostic files.
Reviewer owns this milestone record, package review sections and roadmap.
Builder reads the roadmap, AGENTS.md, CLAUDE.md, P3 brief and relevant shared
architecture rules. Use the existing tools and baseline; prioritize missing
construction. Add verification only to resolve a concrete acceptance gap.

For each submission, finish coherent work, stop editing and provide one short
diagnostic: changed files and construction delivered; source/plan/bake hashes;
part/join ledger; exact image/test paths; measured results and known gaps.
Use distinct evidence paths for each submission. Preserve unrelated local
changes. Do not commit the inherited working tree wholesale. Do not perform
Git index/commit/push work during review. Owner identity, configured hooks and
web deprecation remain binding.

Reviewer inspects a stable submission once, checks hashes and changed source,
looks at actual images and independently verifies material claims with
focused checks. Return one consolidated list tied to acceptance criteria.
Do not restart completed checks without a dependency change or new failure.

Initial submission plus at most TWO fix submissions. If the same blocker
returns unchanged, or the builder stops without a substantive submission,
pause for an actionable reassessment instead of issuing a vague continuation.
On acceptance, on the second fix review, or on a genuine blocker, record the
result and PAUSE automation. Do not automatically advance to another owner,
variant or P4. No model changes, new chats or archives.

## Durable coordination state

- Build chat: Luna Build Moy P3 and p4
- Build thread: 01a153b7-0f75-7871-9324-bdd8efef7e6c (local).
- Automation: moy-p3-p4-review-fix-loop (reuse existing heartbeat).
- State: FINAL fix reviewed: milestone not accepted; automated process PAUSED for reassessment. No implementation continuation authorized.
- Fix submissions allocated and reviewed: 2 / 2. Budget exhausted; no third fix.
- Last reviewed submission: final fix turn 01a15bf0-06fe-7a91-9332-9eb5208c8dfe; completed, stopped editing; result fix.
- Prior baseline: final P3/P4 review commit 66c99f8, builder SHA-256
  5af1395374f6e414b90631d3cb0c05e813827e9cfc331dc07db754d8a268517b,
  bake manifest d28fd5d1ba31f4b6a101274f91b3832069e1b44ebf756c5caf90833f66b0a816.
- Latest observed build cursor: 7a55a42b-a1c8-42f5-878b-cbca088e7147:9.

Update this state only on dispatch, submission review or a meaningful blocker;
never commit status-only polling. Record reviewed source/evidence hashes and
fix count before dispatching the next round to prevent duplicate reviews.

## Economy rules

Compact wait_threads snapshots every 20 minutes, carrying the latest cursor.
While active or unchanged, stay quiet: no recent-turn history reads, repository
scans, extra prompts, validation or commits. Read recent turns only to locate a
new handoff or resolve a real blocker. Keep prompts specific and refer to this
file; do not resend the full history. One evidence bundle and one review per
submission. These are operational bounds, not a guaranteed token saving or a
hard account-token cap.

## Initial milestone review — 2026-10-21: fix

Reviewed stable turn 01a15ba4-4b34-75d3-a186-2795b1592ca3. Submission:
`../diagnostics/2026-10-21-moy-P3-second-third-review-fixes.md`, its P3
boom76 JSON/CSV, route JSON, audit, capture manifest and four noon GPU images. Scope drifted back
to broad P3/P4/P2 work; that is not evidence of completing this milestone.
No P4 acceptance review or additional implementation scope is opened here.

Independently verified the current 260-pack bake and matching sample/route
hashes. Builder: `eb946665d73b2ae5183ed6507c9acc58e130ac8a3b895c2c69fef18f112b2fb3`.
Manifest: `1105225cecff972e110937257aded41405576e3d58dbb01852f39c27e1496c04`.
Plan remains `5705a10f92e26fc2d51227aec025cbccf41c4095fd93a6b48e9587b4f50c4938`.
Saved sample contains the v5 grammar and MarketHouse_076. Source and saved
ledger contain facade, veranda, tank and coping pieces; presence is credited
without claiming their fit is accepted. Sample reports 213 records, zero
failures; its assertion names add no new representative fit criterion over
the prior evidence. The diagnostic confusingly describes this boom76 sample
as a Market Flats check; correct the scope in the next focused diagnostic.

Acceptance gaps and first-fix instructions:

1. Reconcile the applicable part/join ledger with the actual variant and saved
   geometry. The parts CSV excludes `canopy`, but source/saved scene contain
   `ShopCanopy` and the `party_cut` join row cites it. Resolve applicability
   from the binding plan/brief, then fix construction or ledger accordingly.
   Replace all 11 `geometry_present_check_fit_separately` join statuses with
   measured fit results and actual geometry/collision paths. N/A needs a
   concrete plan-field reason; do not convert missing work to exclusions.
2. Finish and verify physical construction revealed by those measurements,
   including band/corner fit, return guards, door/window/shutter clearances,
   seats and supporting surfaces. Counts and names alone cannot pass it.
   Reuse current tools; no new general validation framework.
3. Provide readable GPU views specifically of house076 with immediate city
   neighbours, front/roof and both sides of relevant joins. Actual overview
   images remain obstructed and the other cameras target arcade/Lamp Lane,
   not this representative. Their exact-cell metadata does not establish
   subject/neighbor construction or fit. Capture provenance must include
   builder, plan and bake hashes, not just runner/generator hashes.
4. Verify hero/Xiao access and stationary support on this representative's
   changed deliberate landings. The 12 recorded P3 routes visit LOT34/71 and
   the shop, not076. Do not rerun those or P4's 72 routes. Supply a scoped
   owner/neighbor audit with source/bake provenance and explain remaining
   relevant findings. The broad P3 audit has 146 blocking findings and three
   nonblocking guard findings naming076; neither proves matched local
   closure. Inspect those three guard locations rather than clearing them
   because the suite marks them nonblocking.

No full P0, P4, P2, other-owner work or broad named-view capture batch in the
fix round. Deliver changed construction and the four scoped evidence items
in one short new diagnostic, then stop editing. If the scope drifts again or
there is no substantive milestone progress, pause instead of spending the
second fix allocation. A genuine capture/engine blocker should be reported
with exact evidence and stopped, not turned into a new tooling project.

## First focused fix review — 2026-10-21: fix; final fix allocated

Reviewed stopped turn 01a15bcb-aeca-7800-9c6e-5c9ef9b16283, diagnostic
`../diagnostics/2026-10-21-moy-house076-fix1.md`, focused saved check, route
JSON, local audit and all eight current GPU images. Independently rechecked
260-pack freshness, current source hashes, ledger logic and route loop.
Builder `03e7005c8dcb7dd637f20feac21daba39dd67964d367c21c875e9253d25b294b`;
manifest `7d564f967381411894e367a9f666b2703e49443bcf35cc6ca5c79629e8c8c6bc`;
plan remains unchanged. Route and capture source hashes match actual files.

Credit meaningful scoped construction: inapplicable canopy removed, veranda
floors extended to parcel/facade bounds and front/return rail supports revised.
Canopy applicability is now consistent. The saved check reports206 records,
zero failures, with useful party-plane measurements and specific rail/tank/
coping bounding checks. Front/roof GPU views now show076 beside neighbours;
inside/outside near views show the punched window/veranda. Retain this visual
progress without treating these four viewpoints as every join's proof.

The local audit supplies actual owner paths:150 findings, including125
blocking shared infrastructure findings and two nonblocking076 guard records.
No blocking finding names076. This does not close its guard warnings or prove
every non-owned blocker inherited. Raw audit JSON has no source-hash binding;
tie its next focused results to exact builder/plan/bake provenance.

Final fix list (no subsequent implementation round):

1. Demonstrate actual hero and Xiao access plus stationary support on076's
   deliberate elevated landings. Both first-fix attempts fail: hero reaches
   the horizontal target but stays at street y=-59.97; Xiao stops short and
   stays on street support. Their street holds are not elevated landings.
   The harness currently breaks on horizontal arrival before requiring target
   height/landing, even for this elevated route; diagnose that termination
   and whether jump/traversal inputs reach the actual shared controllers.
   Use a feasible existing parkour approach; do not lower the plan height,
   invent a stair/interior, teleport to the landing as access proof, or weaken
   support/arrival criteria. Separately distinguish isolated surface support
   checks from continuous access. If current geometry/movement cannot meet
   the brief, report the exact constraint and stop for reassessment.
2. Inspect and resolve or technically explain both076 guard records:
   (-493.5345,-43.6271,60.6034),29 edge samples; and
   (-493.5,-40.1900,72.0),one sample. Measure actual edge/guard geometry and
   collision with both bodies at the affected support surfaces. A finding
   being nonblocking in P0 is not itself a clearance. Do not add rails to
   every tank by reflex or change schedule semantics to suppress warnings.
3. Correct join-ledger acceptance. In `_join_ledger`, `measured_pass` is
   `count>0 && all_bounds_fit`, with a real schedule-plane gate only for
   `party_cut`. Most `measured_saved_fit_pass` rows therefore establish a
   part's visual/collider AABB agreement, not its joint with another part.
   Retain those measurements under their accurate scope. Bind each applicable
   joint result to the actual paired parts and scheduled planes/split/seat/
   surface relationships; AABB overlap alone cannot show a continuous capped
   seam or correct parent split. Existing split/topology checks can be reused
   and referenced where they establish that exact joint. Report unresolved
   relationships honestly, and fix actual construction they expose. No new
   general testing framework. Supply focused close images where needed.

Refresh only evidence dependent on changed source. Do not rerun unrelated
routes, broad P0/P4/P2 or all capture views if unchanged. Submit one concise
final-fix diagnostic, then stop editing. After its review, pause automation
whether it passes or fails; do not automatically advance to replication/P4.

## Final milestone review — 2026-10-21: not accepted; PAUSED

Reviewed stable final turn01a15bf0-06fe-7a91-9332-9eb5208c8dfe once.
Submission: `../diagnostics/2026-10-21-moy-house076-fix2.md`; its focused
saved-check JSON, controller routes and hash-bound guard audit; and all four
actual images in `../diagnostics/images/2026-10-21-house076-fix2b-P3-P3/`.
Independently verified 260-pack bake freshness, current builder/plan/manifest
hashes, route and capture provenance, trace outcomes, relevant source gates
and recorded joint relations. No repeated broad suite or further build prompt.

- Builder: `61f0c6b3f55db0471856db95a8b8da191ed45819505600685a65ee9e168038bf`.
- Plan: `5705a10f92e26fc2d51227aec025cbccf41c4095fd93a6b48e9587b4f50c4938`.
- Manifest: `e23fbd7fe58cd4a2462cfe40d4720c5015cd5055de895717b62e6bd780f1bcf5`.
- Saved check: `../diagnostics/raw/2026-10-21-moy-P3-house076-fix2-check.json`.
- Routes: `../diagnostics/raw/2026-10-21-moy-P3-house076-fix2-controller-routes.json`.
- Audit: `../diagnostics/checks/moy-house076-fix2-2026-10-21.json`.

Credit construction: scheduled balusters now continue over the structural
column interruptions in the veranda guard; earlier corrected canopy,
party-plane floors and rail-return work remain. Joint reporting now separates
own visual/collider bounds from paired/scheduled relationships. The347-record
saved sample reports zero assertion failures; ten applicable relations report
passes, four variant exclusions are explicit, and `band_chain` is honestly
unproven. Source gates no longer promote own AABB agreement to joint acceptance.
Selected split/floor-plane, rail/post and tank-seat relations carry paired
paths and measured errors. This is progress, not a completed kit certificate.

**Continuous access remains unaccepted for both characters.** The updated
route runs beyond horizontal arrival and requires elevated height, named
support and a stationary hold. Both fail the tested street-to-first-veranda
approach. The diagnostic reports maximum rises1.45 m and1.66 m versus a3.375 m
street-to-floor rise; sampled trace rises independently confirm the shortfall
(about1.40 m and1.66 m). These are results for that attempted direct approach,
not proof that every existing traversal power or alternate approach is
infeasible. No valid continuous alternative was submitted. Isolated first
veranda and tank support probes pass for both but begin by placement and do
not establish access. All are headless physics results, not rendered gameplay.

Credit the selected fifth-floor guard-edge probe: both bodies stop short of
the outward destination and retain named veranda support for30 frames. The
repaired geometry and this local result address the reported opening for
that tested path. The tank-apex probe likewise holds30 frames on the scheduled
landing collider. The guard-only scan still reports25 warnings, including
the same two076 records; inspection confirms `_edge_has_guard` excludes the whole
source body RID, so same-owner child guards are not seen by that ray. Record
this as targeted behavioral evidence plus a known scan limitation, not a
zero-warning or whole-perimeter acceptance claim. The guard scan now includes
source/bake provenance. It does not refresh other area checks.

GPU front views show076 and neighbours; the dusk outside close view shows
the guard/window construction. **The corresponding noon outside close-up
misses the subject**, despite subject-cell-loaded metadata. Do not accept it
as a matched near-view pair. Remaining coping mitre/45-degree plane relations
have neither measured acceptance nor sufficient dedicated close proof.

**Reassessment required, no third automated fix:** identify and demonstrate
a feasible continuous approach using the existing shared traversal system,
or bring a concrete movement/architecture conflict to the user before any
design change. Finish the coping's scheduled mitre and readable joint proof;
repair the misdirected close view. Keep current scoped support/guard credit
and recognize full P3 owner/variant/parkour/audit work remains open. P4/P2 and
other owners were not advanced. No acceptance criterion is relaxed.

The bounded workflow delivered actual guard/floor construction and clearer
joint evidence rather than indefinite broad reruns. It also exposed an access
feasibility question that should be settled before replication. Automation is
PAUSED after the agreed initial submission plus two fix submissions. Builder
implementation/evidence remains preserved in the working tree; this review
checkpoint commits review-owned documents only.
