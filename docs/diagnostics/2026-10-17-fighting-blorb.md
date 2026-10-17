# Fighting Type, 2026-10-17

Throwing Boxing Gloves into a regular unmerged Normal blorb now follows the existing transformation presentation. At its whiteout midpoint the blorb becomes Fighting Type, its core takes the Fighting Gem color, and Boxing Gloves are bound in its accessory equipment. The existing core-item and element fields preserve this through party reconstruction. Fighting Gem has a non-purchasable catalog entry so its equipment socket and item portrait resolve; no new loose-gem spawn or shop stock was added.

The free companion has two red floating gloves, with cuffs, padded fists and thumbs. No hands, arms or connecting limb meshes were added. A small shared glove builder supplies the held item and the free creature. The gloves alternate guard, extension and recovery poses. The fighter approaches the same NME group as the other blorbs, faces its opponent and punches rather than body-lunging. Damage occurs once on extension, uses existing Strength/variance/critical math and credits the attacking blorb through the existing take_damage API. Range and obstruction are rechecked at impact. Melting, wearing and exiting combat cancel queued punches. The follow-up suit implementation below adds the corresponding playable arm power.

Two details were corrected during proof: planar approach must stop inside the actual 3D punching radius, and the fighter's body tilt must preserve the same front as its eyes and gloves. These changes are restricted to Fighting Type.

Validation: `tools/validate_fighting_blorb.tscn` passed with zero failures and six credited punches, including a final windowed Metal run. It exercises the real thrown-item and transformation path (cached test portraits), real blorb approach/attack logic, one damage event per punch, cover/range rejection, restore reconstruction and melt/wear cancellation. The damage receiver is an NME stand-in recording the existing damage/attacker contract; a full Crossroads battle and XP payout were not replayed. Inspected guard and punch captures are in `wip/diagnostics/2026-10-17-fighting-blorb/`. The world bible records the new type; no elemental advantage was invented.

Repeat in an isolated imported scratch copy, with other test runs kept separate:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path SCRATCH_PROJECT tools/validate_fighting_blorb.tscn
```

For rendered captures omit `--headless` and append `-- --capture`. Body pose ownership, power parity, design-language and whitespace checks pass. The parity tool still reports the preexisting FlightMode refactor debt. No commit, push or web export was performed.


## Worn gloves and arm punches

Loose Boxing Gloves now use ordinary aimed throwing, with the catalog's handheld-weapon flag removed. Their punch damage is a separate accessory stat, shared with the free fighter. Existing swords, staff and cleaver retain their weapon controls.

A Fighting blorb carrying Boxing Gloves on either arm slot now fits an oversized padded glove over that suit hand. The reusable mesh is positioned from the same bulged wrist and fingertip stations as the goo sleeve, follows animation without rebuilding glove geometry, and is owned by the suit piece for unequip and portrait cleanup. Rendered QA caught a compact-rig fingertip poking through the first fit; coverage was corrected around the measured hand span, and a geometric regression guards it.

`FightingPunchMode` implements the shared attack for both TraversalContext drivers. Each anatomical arm has its own chamber, extension, recovery and repeat delay. Q/E activate their existing matching arm powers; holding repeats punches. Movement remains free. A hand with an independently articulated wrist uses that joint even when its hand name is an alias. Human hand rotation preserves its real wrist anchor. Damage lands once at extension, checks the target's actual primitive collision surface near the fist, respects solid cover and uses the contributing worn blorb's Strength and attacker/XP identity. Busy hands, modal state, loss of equipment, switching control and vine swinging cancel pending attacks.

`tools/validate_fighting_suit.tscn` checks both real procedural rigs, independent left/right and simultaneous strikes, impact timing, damage credit, occupied hands, removal, reset, glove coverage, cover and melee reach. The Metal render proof includes rest and each arm's extension for both rigs. Captures: `wip/diagnostics/2026-10-17-fighting-suit/`. This is an isolated mechanics/visual proof, not a full Crossroads gameplay session. The existing thrown-transformation/free-fighter regression also passes; its dummy headless renderer reports six ObjectDB instances at exit, while the suit's windowed run exits cleanly.


## Glove orientation and punch-motion correction

Playtesting exposed gaps in the first proof: it exercised isolated pose targets but did not run the competing generic palm-forward gesture or compare successive held punches. Both playable drivers now explicitly exclude Fighting/Boxing Gloves arms from that gesture, including its wrist recovery. The punch holds a chambered guard between repeated strikes and drives the shoulder from behind the ribs to horizontal while unfolding the elbow. Its wrist target is a fixed forearm-relative rotation, blended from RigAdapter's captured rest transform; it never projects against world-up or interpolates from an accumulated hand orientation. The logical wrist anchor is reconstructed from rest each frame.

Suit gloves now mirror their thumb mesh for the anatomical arm. At impact thumbs point inward and sit on the palm side below the glove back. The shared glove geometry puts its thumb on that palm side; free blorb gloves use the corresponding fixed forward-facing frame and mirror their thumbs inward as well. Their resting height was lowered from 0.65 to 0.28 in body-local space, placing the padded fist near the eyes.

Expanded suit validation calls each real driver's generic gesture with an already-raised blend, checks that it leaves boxing wrists untouched, compares repeated impact bases through a turned-body five-strike sequence on both rigs, checks thumb direction/palm-side placement, and requires measurable whole-arm chamber-to-impact travel. Existing impact, cover, range, cancellation and glove-coverage checks remain. Final Metal suit validation and the free-blorb throw/combat regression pass with zero failures. Updated captures include rest, left/right impact and the chambered guard; this remains an isolated mechanics/render proof, not a full scene walkthrough.


Glove sizing follow-up: the overall glove and thumb now follow the wearer's suit rig scale directly. The compact rig's arm-wrist fit multiplier no longer enlarges the complete glove. Only cuff width and padding clearance are adjusted to enclose measured hand thickness and its rounded tip. The regression checks the root scale against the character profile, while retaining fingertip coverage. Updated Metal renders and the expanded suit proof pass. The free fighter's windowed proof passes with six credited punches and reports four ObjectDB objects at shutdown; the suit proof exits cleanly.


## Chamber refinement

The worn punch now chambers with the thumb upward and a slight outward shoulder yaw/spread, then pronates the fist and closes that additional shoulder angle as it extends. Extension retains the previous wrist roll and shoulder target exactly. The mirrored twist is driven by the same authored extension phase, so successive held punches remain reproducible. Free Fighting blorbs now chamber their floating gloves slightly farther outward/back, with thumbs upward, and twist into their established inward-thumb impact orientation as they reach forward. No physical arms were added.

Regression coverage now checks thumb-up chambers on both playable rigs, outward shoulder/elbow position, zero added yaw and the unchanged lateral shoulder angle at impact, stable repeated impact orientation, and equivalent chamber/impact glove frames on the free creature. Suit and free-fighter tests pass; the suit Metal render check also passes with chamber and impact captures refreshed.


Thumb silhouette refinement: the shared glove thumb is slightly smaller, seated closer to the padded fist, and shifted subtly toward the palm. This applies to loose gloves, free fighters and both suit rigs. The rendered suit proof passes with zero failures; refreshed impact captures were inspected.


## Responsive playable punches

The playable strike now reaches impact at 60 ms instead of 160 ms, with a 260 ms animation and a 320 ms automatic hold cadence. A fresh button press bypasses the hold-repeat cooldown and interrupts an already-landed strike's recovery. A press during the brief pre-impact phase is retained until that strike lands so neither tap is lost. Each arm keeps its own pending input. Both real drivers capture non-echo action-press events, preserving taps that are pressed and released between rendered updates; the held-state rising edge remains a fallback for direct/synthetic drivers. Busy hands, modal/control changes, unequip and reset discard buffered taps. Free-blorb AI timing is unchanged.

The expanded proof invokes each driver's real input callback, verifies six taps at 10 Hz on each arm, checks one impact within four 60 Hz frames per tap, verifies short press/release pairs survive frame boundaries, retains a second tap during wind-up, and confirms release/reset cause no extra punches. Existing held-repeat, chamber/twist consistency, impact, cover, range, ownership and cancellation checks remain. The headless and Metal-rendered proofs pass with zero failures, along with source parity/design/pose checks.


Fighting body palette refinement: Fighting blorbs and their reshaped suit pieces now share a warm dobok white through ElementPalette.FIGHTING_BODY. The Fighting Gem and boxing gloves keep their red palette.
