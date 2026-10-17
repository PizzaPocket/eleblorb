# Moy prototype verification and performance

2026-10-17. Results for the current source and regenerated 58-pack bake. Headless Godot 4.7.1 was used for plan/runtime checks. A rendered performance run did not complete; the windowed probe exited with status 134 before opening a log or saving new captures. The existing PNGs in `moy-prototype-captures/` are from an earlier revision and are not evidence for this revision.

## Verified

- `tools/check_moy_bake.py`: current, 58 packs; 23 streets, 48 numbered records, 133 lots and all 60 old houses. `tools/validate_city_plan.tscn`: 0 FAIL. `git diff --check`: clean at verification time.
- `tools/validate_moy_runtime.tscn`: exit 0, `failures=0`. It reports 72 runtime cells/packs ready, 2,385 physics bodies, full six-slot Plant suit and PartyControl handover, four gates, six Deck ramp tops, pond surface -59.6/depth 4.35, and four west-facing 2 rpm rotors with twelve independent moving collision blades.
- Train check: eight controllers and twenty independent rideable cars; Spine has five stops, Meridian three and Wall Line four, each with four-second dwell. Every station is individually exercised. The 40-second gate simulation reports no pairwise conflict. All 65 samples per Spine lane, 57 per Meridian lane and 232 per Wall lane clear the train-body envelope against building, old-house, lot, gate and Wall Line station-platform collision bodies. Six named vine-anchor routes and full human/Xiao handover pass.
- The All-night Store edge and the authored lots that overlap the Spine car envelope now have a continuous +12 m to +20 m train-height tunnel, with openings centered on the Spine and tall enough for the +20 m approach. Their recorded outer footprints and roofs remain. The North/South gate flyover supports sit outside the train envelopes; gate access escalators use a clear side approach and connect back by a raised walk. Ramp flights alternate lateral lanes with shared landings. A raised park lawn, animated pond shader, subdued building colors, and street/paving separation are baked.
- Headless activation log: 58 pack activations; maximum `instantiate_add_ms` 1.402 ms. Across 69 activation frames the maximum delta was 149.33 ms, with five above 33.3 ms and one above 50 ms. The first activation accounts for the largest spike; actor registration still produces later work. These are headless activation diagnostics, not rendered frame-rate measurements.
- `check_body_pose_owner.py`, `check_power_parity.py`, and `check_design_language.py` pass. Ohio: 0 FAIL / 8 existing warnings. Snow: 0 FAIL / 5 existing warnings. China runtime and platforming pass (9,533 samples, 0 failures); China plan reports 8 islands, 10 bridges, 54 placed items, 38 openings and 65 paths. The village wrapper's default log location is not writable in this sandbox and its first attempts crashed; the same validators were rerun sequentially with explicit `/private/tmp` log files and passed.

## Not verified / known limitation

- The current rendered probe could not be measured: Godot's windowed process exited 134 before producing output. Do not infer FPS, draw count, triangles, GPU memory, or rendered activation performance from the headless run. The bundled PNG captures are stale for the current revision.
- No sustained physical-player verification yet for every street/roof/gate/Deck route, actual vine swings across train handovers, boarding and riding through station dwell/turns, pond swimming, repeated city entry/unload, Helmsmith, or Gem interaction. Automated route-envelope and anchor-search checks are narrower than physical traversal.
- Turbine direction and motion are verified in the model/runtime checks; physical blade hazard tuning is not.
- Headless output includes dummy-renderer RID/mesh warnings while constructing unrelated terrain and one dummy mesh leak on exit. Runtime assertions still completed with exit 0 and zero Moy failures; a rendered run is needed to assess visual behavior.
- Hotel scope remains the public Deck-connection skeleton. Apartment floors, facade-window population, interior-mapping shader, NPC schedules and story remain deferred.

## Repeat commands

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tools/bake_moy_city.tscn
python3 tools/check_moy_bake.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tools/validate_city_plan.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tools/validate_moy_runtime.tscn
```

A new windowed capture and full performance table are still needed before claiming rendered-performance acceptance.
