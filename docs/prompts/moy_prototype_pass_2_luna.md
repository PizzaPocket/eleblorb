Build the second pass of the Moy city prototype in this repository. The first
pass is already built (`scripts/moy_city_bake_builder.gd`, baked by
`tools/bake_moy_city.tscn`). The plan has changed since then. Update the
prototype to the new plan. Do the implementation; do not write another plan.

Read, in order: `AGENTS.md`, `CLAUDE.md`, then
`docs/architecture/moy_prototype_pass_2.md`. That document lists exactly what
is wrong in the first pass, exactly what to build or change (with the data
keys and numbers), what to keep doing for performance, and how to prove it
works. Follow its steps in order.

The most important points:
- Read every number from `CityPlan` (`scripts/city_plan.gd`). Never edit it
  by hand; regenerate it with `python3 tools/city_layout.py`.
- Keep the first pass's fidelity, but be exact for everything people walk
  on, ride or climb: escalators, ramps, landings, platforms, passages,
  columns, parapets.
- Every escalator and ramp must have a way on and a way off at both ends.
- Place every tree and plant exactly where the data puts it, and nowhere
  else. No wind trees.
- Build railings only where `DECK.parapets` says.
- Keep the offline bake, the pack cells, separate collision bodies per
  building, tower and tree, shared meshes and MultiMesh for small repeats.
- "The High Line" in the owner's words means the Deck; in the data "the
  high line" is the Meridian Line.

Finish with the diagnostic and tests the document asks for, recording real
passes and failures. Report plan contradictions instead of redesigning. Do
not publish a web build, commit or push unless asked.
