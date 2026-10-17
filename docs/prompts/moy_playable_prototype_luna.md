Build the first playable prototype of the new Moy city layout in this repository.
The owner calls it Moi too; the existing source and documents use Moy. Implement
the pass, rather than writing another plan or stopping after the first checkpoint.

Start with `AGENTS.md`, `CLAUDE.md`, and
`docs/architecture/moy_playable_prototype.md`. That execution contract defines
the scope, current decisions, exact input files, construction order and tests.
Read `docs/diagnostics/2026-10-17-moy-prototype-readiness.md` for the verified
input defects, and `docs/architecture/moy_build_handoff.md` for the original handoff.

Recreate the existing model at its actual dimensions and placements. Use
`tools/city_layout.py` / `CityPlan` and **inspect the construction code in
`docs/drawings/moy_city_3d.html`**, plus `moy_plan.html`, the hotel model and the
train model. Consult the relevant `city.md`, tower-house, market-lane and style
charter sections as you implement each family. Do not invent a replacement
layout, shrink buildings, flatten landmark silhouettes, or omit the 60 irregular
old houses. Fix the documented export/validator mismatches before building.

The result must be explorable with the real player, party controls and existing
Leaf Hat vine swing/handover. Include all building massing, open public routes,
roofs, gates, Deck access, station-core ramps, real pond water and simple rideable
trains. Preserve the game's SuperEgg language. No detailed apartment floors,
facade-window population, interior-mapping shader, new NPC schedules or story
implementation in this pass. Build only the public hotel skeleton needed for
its real Deck connections; the rest of the final interior program is deferred.

Keep it playable: no runtime CSG or mass construction at Crossroads startup.
Use baked static resources, cheap distant silhouettes, bounded activation over
frames, resource release and existing collision policies. China-style background
loading alone is insufficient; measure activation spikes too. Keep separate
physics bodies per building so the vine's previous-anchor RID exclusion does
not hide every neighboring tower after the first grip. Do not change traversal
range or character mechanics to hide geometry defects.

Provide `scenes/moy_city_qa.tscn` with the real controls and documented QA-only
traversal access. Also integrate the one new city path into Crossroads, retaining
the Helmsmith, existing residents and external City blorbs/Gem. Test coverage,
walking/roof routes, actual swing handovers, moving platforms, reload cycles and
rendered performance as specified in the execution contract. Save captures and
a concise measured diagnostic, distinguishing actual passes from untested work.

Continue autonomously through the authorized prototype. Report genuine plan
contradictions with precise evidence; do not redesign them silently. Do not
publish a web build, commit or push unless separately requested.
