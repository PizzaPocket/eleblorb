# China walkthrough corrections, 2026-10-17

The reported defects were real. The previous NPC pass also made a wrong design choice: its continuous jacket concealed the canonical thorax/abdomen separation. Neither that garment nor the previous traversal checks was sufficient for this platformer.

## Reproduced causes and corrections

- **Roof traps:** swept roof facets faced inward. Double-sided rendering hid the error while collision admitted the player into a shallow closed volume. Corrected facet winding, including undersides and opening edges. Substantial finials now have collision.
- **Collision after fitting buildings:** rotated box colliders under nonuniform building scale acquired shear that the physics primitive could not represent. Only those static boxes are converted to convex hulls using their actual transformed corners. Flat floors retain simple boxes. Moving doors are rebuilt in world dimensions after fitting, so their leaves rotate without shear.
- **Automatic stepping:** the player could be raised into an overhead obstruction. The existing step helper now checks walkable contact and upward body clearance before raising the body. Dirt-bike slope behavior is retained.
- **Stairs:** the high pavilion stair was fitted to the outer building dimensions and intersected its wall. It and its floor opening now share the interior frame. The inn bedroom partition has an open west end for the stair approach; the central bedroom door stays centered. Gatehouse footing trim no longer spans the west door.
- **Doorways and work routes:** small fitted buildings now retain actual 1.8 m paired clearances; Pandy’s shed has 2.2 m. Pen posts, hay and trough leave a continuous gate-to-shed axis. The kitchen’s paired doors swing inward to leave the service passage open.
- **Outdoor circulation:** the path generator now reserves bridge anchorage piers, corridor columns and the actual roof-yard stock/frame/rack footprints. Those workyard positions are shared data used by both planning and construction. Garden passage openings take priority over column positions. The market approach reaches the side of its well court. Arrival and workshop actors start beside the route rather than inside it.
- **Fields:** narrow field paths use the established earth stroke system. Retaining stone is embedded with a low exposed lip; it no longer makes a high obstacle across otherwise flat fields.
- **Chains:** forged terminal eyes and short tails connect the rail ends to their actual anchor plates.
- **Clothes:** chest and abdomen remain separate visible body volumes with separate closure trim. Ordinary jackets finish around the whole hip instead of hanging as detached front plates. Aprons belong only to apron-wearing occupations. Beard size, chin attachment and outward tilt now clear clothing through a head turn; shoes use the actual foot meshes.
- **Children:** the same five children now use affectionate doubled display names: Ting Ting, Xiu Xiu, Pei Pei, Rong Rong and Bao Bao. Household identities are unchanged.

## Verification

The platforming tool (`tools/validate_chinese_platforming.tscn`) samples every planned outdoor route, every passage opening, authored interior clear lanes and the pen-to-shed route with a character capsule. It also drops and jumps a physics body on all 21 principal building/pavilion roofs, trying four escape directions, and exercises the actual player step helper under a low ceiling. It does not exclude the owning building’s collision to make its stairs pass.

The character review checks beard vertices against garment bounds at head yaw -30, 0 and +30 degrees and renders the roster and gait poses. These checks are evidence for the tested poses, not a guarantee for every possible animation blend.

- Platforming survey: **9,533 samples, zero failures**; **21 roofs** exercised in four jump directions.
- Full China runtime: **PASS**, including bridge deck matching, real-water behavior, crop instances, moving doors, mount traversal, party/civic state and unload/reload.
- Character roster/gait rendering: **PASS**, all 20 named residents and Liang Zhen’s advisor outfit; garment bounds clear at all three tested head turns.
- Bake signature and model/runtime data agreement: **PASS**.
- Shared-code regression checks: Ohio **0 failures / 8 existing warnings**; Snow **0 failures / 5 existing warnings**.
- Body pose ownership, design language and power parity checks: **PASS**. The parity checker still reports the preexisting inline human FlightMode refactor debt.

Final roster and gait captures are in `wip/diagnostics/2026-10-17-china-walkthrough/`. In the corrected renders, the emperor and advisor retain a wrapped lower robe while ordinary short jackets finish around the hips; the chef and Hua Chen retain occupational aprons. Thorax and abdomen are visibly distinct. These are inspected renders, not just node-presence assertions.

## Quality judgment and remaining work

This repairs substantial construction errors rather than declaring the village finished. The floating-island mound and transitions into the palace terraces still need an art pass. A successful capsule sweep establishes clearance on authored routes; it does not prove every freeform jump, every party size, or every mount movement is perfect. Live QA should still include roof-to-roof play, running stair turns, closing and reopening doors, water entries and the full approach from Crossroads. The isolated village tool is the fast review target; the deprecated web snapshot is not updated.


## Final targeted visual review

The saved `china_chain_terminal.png` shows the rail eyes meeting the anchorage plates, with no dangling end gap. `china_pen_access.png` shows a clear central route between the gate and the shed’s paired opening; hay and trough sit to either side. `china_farm_routes.png` shows flat earth access instead of raised field path obstacles.

The captures also expose remaining visual weaknesses. The fields still read as repeated crop units on bare green ground, rather than convincing tended soil. The island surfaces remain sparse, and the large bridge anchorage roof is visually heavy compared with the delicate chainwork. These are art-quality shortcomings, not reasons to remove their substantial collision. They belong in the next art pass alongside the mound and terrace transitions. Do not treat the successful route sweep as approval of those visuals.

Ohio and Snow were checked in the same isolated imported copy after the shared door and player changes. The original project’s editor/import cache was not used. The current source bake was copied back; no web export, commit or push was performed.
