# P3 boom-house milestone: bounded build and review

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
- State: initial submission authorized; dispatch after this checkpoint.
- Fix submissions dispatched: 0 / 2.
- Last reviewed submission: none for this milestone.
- Prior baseline: final P3/P4 review commit 66c99f8, builder SHA-256
  5af1395374f6e414b90631d3cb0c05e813827e9cfc331dc07db754d8a268517b,
  bake manifest d28fd5d1ba31f4b6a101274f91b3832069e1b44ebf756c5caf90833f66b0a816.
- Latest observed build cursor: 7a55a42b-a1c8-42f5-878b-cbca088e7147:2.

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
