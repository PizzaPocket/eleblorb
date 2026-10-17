Build the third pass of the Moy city prototype in this repository. Pull the
latest main first. Your second pass is in the repository and was reviewed;
the plan has also changed. Do the implementation; do not write another plan.

Read, in order: AGENTS.md, CLAUDE.md, then
docs/architecture/moy_prototype_pass_3.md. It reviews your second pass (what
to keep, what is wrong and exactly why, and how to fix each), lists the plan
changes (the city's clock is now a glass dome with four ring clocks and a
bell on the Crossing; City Hall is the Meridian Arch; the old city hall and
the Timekeeper are gone; a new Civic Plaza, Meridian Walk and three
commercial blocks), gives the new counts, and the tests. Keep following
docs/architecture/moy_prototype_pass_2.md where pass 3 does not change it.

The most important points:
- The garden towers' insides are a jumble because TorusMesh makes upright
  donut tubes, not flat rings, and the escalators are overlapping boxes.
  Build flat annulus meshes and one continuous strip per escalator hand,
  as the document says.
- The East Gate's lower bridge must be a hollow station the high line runs
  through, not a solid block.
- Test the routes with the real player and Xiao Hou Zi: every escalator and
  ramp end, changing lines, boarding a train, the clock and the bell.
- Run the rendered performance probe and report its numbers.
- Last, once the fixes pass, build the Grand Hotel's public interior with its four
  working capsule lifts (section 3.5), from HOTEL and the hotel's own 3D model.
- Read every number from CityPlan; never hand-edit scripts/city_plan.gd.

Finish with the diagnostic, recording real passes and failures. Report plan
contradictions instead of redesigning. Do not publish a web build, commit or
push unless asked.
