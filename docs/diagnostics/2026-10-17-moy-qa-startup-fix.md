# Moy QA blank-city repair

The escalator floor-contact fix changed `scripts/moy_escalator.gd`, which is a hashed input in `assets/generated/moy_city/manifest.json`. The city loader rejects every pack when any input hash differs. The script repair was correct, but its bake dependency was missed, so QA reached a terrain-only scene after the static-pack wait timed out.

Regenerated the complete 58-pack city in an isolated project with the corrected escalator script. Every generated scene was identical to its previous contents after excluding Godot's randomized node `unique_id` fields. Preserved the existing node IDs and scene contents; the regenerated manifest updates only the escalator source hash. `check_moy_bake.py` now passes. The city branch of `check_village_layout.sh`, already used by pre-push, now runs that freshness check before plan validation.

Verification:

- `validate_moy_runtime.tscn`: zero failures; all 58 static packs active, 2,385 city physics bodies, 46 numbered collision owners, all 60 old houses and 133 lots, train/lift checks and six vine handover routes pass.
- An isolated windowed smoke test invokes the real start screen's `_play_moy_qa()` method, goes through the normal Loading scene, reaches `moy_city_qa.tscn`, and finds all 58 active packs and 3,517 mesh instances. The observer waits for the loading overlay to close before capturing the arrival view.
- `check_moy_bake.py`, `validate_city_plan.tscn`, shell syntax and whitespace checks pass.

Headless terrain rendering emits the existing dummy-renderer warnings. These checks restore QA startup and do not constitute a new city-wide performance acceptance run. No web export, commit or push was performed.
