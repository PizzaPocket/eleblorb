# China Village: inn and building fidelity continuation

The owner authorized the next village correction and specifically requested a
structurally credible inn sign. The Three.js model and accepted settlement
program remain the reference, interpreted through Eleblorb's SuperEgg language.
This is a completed correction pass, not a declaration that every building has
reached final art quality.

## Changes

- The inn keeps its surveyed 17 × 11 m hall. A source shell of five by three
  cells replaces seven by five, reducing the oversized roof and restoring the
  internal ramp's width and grade. Beds stay within the hall. Chests, washing
  furniture, lamps, pegs and a runner give the guest rooms a usable program.
- The upper gallery meets the 3.25 m floor through a real central double door.
  Windows have fitted lattice; open return rails and collision guards close its
  ends. Exposed deck fascia, rails and structural members use softly squared
  parts rather than raw boxes.
- The bed-and-moon sign hangs from a bracket embedded in a mounting shoe beneath
  the gallery. The plaque bottom clears 2.2 m; the bracket stays below the deck.
  The crescent originally faced the wall and now faces the street. The central
  unlettered lacquer board has two actual hangers into the gallery structure.
- Household workyards now show their existing trades: lantern frames and drying
  paper, graded tile stacks, timber and tools, carrier's loading stock, bean
  sacks, and a covered bao counter with bamboo steamers. The west-end household
  has a modest seat rather than an invented business. Side-shed paired doorways
  have 1.8 m clear width rather than shrinking with the shell scale.
- Home and work anchors keep residents out of entrance routes. The farmer stands
  beside the working route and unrecruited Pandy occupies the existing pen,
  clear of its shed, trough and rails. No quest or recruitment state changed.
- The royal pond has more open water north/south. Both pond crossings retain
  1.5 m usable width with a lower, thinner stone section. Shared canonical pond
  radii drive water, floor cuts, swimming and basin collision.
- The high pavilion mound now has continuous recessed rock relief beneath its
  marble cap, replacing repeating brick texture. Its collision follows the
  surface, while the accepted bounds, ramps and garden clearances stay intact.
- Shared trade furnishing source is included in the bake signature. The final
  generated scene and signature have been copied back to the project.

## Verification

Final headless China runtime validator passes, including all 49 pine crown
checks, seven compound entrance/shed routes, gallery doorway clearance and
floor alignment, sign bracket/shoe/deck support, beds, water/swimming, bridges,
ramps, driven mount, state persistence and threaded region activation.

The plan validator agrees on 8 islands, 10 bridges, 54 items, 38 openings and
65 paths. Ohio: 0 failures / 8 existing spacing and schedule warnings. Snow:
0 failures / 5 existing schedule warnings. The plan-only validator retains its
exit-time object-leak warnings. The headless macOS certificate-store warning
also remains; final bake/runtime logs contain no script errors. Bake signature,
Three.js/runtime data agreement, JavaScript syntax, design-language check and
`git diff --check` pass.

Windowed Godot review covered the inn front, sign, guest room, seven household
workyards, palace garden, moon court and service area. The final mound received
an additional render after increasing relief. Images are in
`wip/diagnostics/2026-10-16-china-building-fidelity/`; `reference-inn.png` is the
actual browser-rendered Three.js model for comparison.

At 1600 × 1000, isolated village QA staged in 2.724 s and measured 59.7–60.0 FPS
at the palace view and 56.0–56.1 FPS at the field view. Static memory was
344.6–347.3 MiB, reported video memory 677.3 MiB, with 3648 / 4002 draw calls.
These are fixed-camera local measurements, not a fresh Crossroads startup or
long gameplay soak. The field view remains a rendering optimization target.

## Honest remaining assessment

The inn section, actual openings, sign support and workyard readability are
substantially better. They now have measurable architectural relationships
instead of relying on loosely scaled primitives. The guest rooms remain simple;
this pass is not an exhaustive review of every furnishing in every interior.

The mound is improved technically but still reads as a large, uniform battered
mass. Its silhouette and rock composition need a more deliberate art pass.
Household facade variety, garden shore composition, and the coarse island sides
and abyss backdrop also remain below the reference's presentation quality.
Passing clearance tests does not resolve those visual shortcomings.

Open `scenes/chinese_village_qa.tscn` with F6 for playable review. This work has
not been committed or pushed. The deprecated web snapshot was left untouched.
