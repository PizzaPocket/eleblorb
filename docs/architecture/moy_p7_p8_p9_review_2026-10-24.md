# P7–P9 combined practical review — 2026-10-24

Outcome: accepted at practical L2/L3 built-and-dressed milestone. Final L4 is
not claimed. User authorized ONE next ready local Luna build after acceptance:
P10 trains. Dispatch pending; record the created chat id here before ending.

Reviewed stopped builder turn `01a16d5a-1884-7ff3-8e7c-92f1dba8d11e`, chat
`01a162e9-f834-7da0-b5c2-1098044a9aaa`, based on main `5a5cd394`.
Report: `docs/diagnostics/2026-10-24-moy-P7-P8-P9.md`.

## Evidence and independent checks

All six source/bake hashes in each supplied final P7-routes30 and park/play26
result match current files, both have zero failures. Inspected test logic:
actual Player/Xiao input between locally placed route starts, saved geometry
loaded directly, real lift ride/exit/recall plus headroom/support probes.
These records do not certify one continuous whole-city journey or menu input.

Independently ran `tools/check_moy_bake.py`: current475 packs. Inspected relevant
Crossing/park builders, source integration, CollisionPolicy geometry, generated
surface freshness guard and raw controller records. Independently reran
Godot headless `tools/validate_moy_gardens.tscn -- --route=pond_arch_crossing`:
4/4 checks pass, zero failures. Both characters follow all73 pond-bridge
waypoints; all16 four-lift apron probes and shared-time clocks/bell scheduler
checks pass. Result:
`docs/diagnostics/raw/2026-10-24-moy-P7-P8-P9-gameplay-pond_arch_crossing.json`.
Engine/run logs: `/tmp/moy-p7-p9-review-pond-engine.log` and
`/tmp/moy-p7-p9-review-pond.log`. CA-store/dummy-renderer shutdown warning
retained as a limit, not a script/gameplay failure or resource certificate.

Independent triangle-edge check of the exact hashed garden-surface frame:
40,992 triangles, one connected component, zero boundary/non-manifold edges,
zero inconsistent directed shared edges (coordinates rounded1e-7). This
supports closed coordinated construction; it is not a precision fit ledger.
Shared pose-owner, power parity11 powers/3 characters and design checks pass.
No new broad suite, rebake, timing/capture project or implementation edit.

Viewed all7 actual saved-scene GPU images: overview, frame close-up, Clock
Room, station/park join, dry garden, pond arches and playground/net. They show
recognizable full station/landscape/play forms and useful ordinary viewpoints.
The image manifest's bake hash matches current manifest. Its actual roughly7m
supported GPU Clock Room walk is credited as supplied evidence, not a new
independent rendered walkthrough or full-city streaming test.

## Scope and retained limits

Accepted: coherent model-matching architecture/landscape, real public surfaces,
representative intentional lift/helix/park/bridge/play circulation and usable
net/trough contact at the user's practical Ohio/Snowhio standard. Newer closed
Old Fu tea-house scope is applied. No universal access requirement.

Retained: full-city cold streaming/retention and performance; complete station
platform-transfer journey; continuous approaches to every tested play feature;
complete tube/spiral slide descents and optional upper power routes. Small
frame fillets, training wires and station props remain polish. Low/submerged
outer pond arches are a documented design simplification, with usable deck
crossing independently verified. No complete L4 or all-green resource claim.
P6 hotel ingress and earlier loading debt stay separate, neither erased nor
repaired by this acceptance. P10 owns next station/train integration checks.

## Preservation and dispatch

Builder's final2233-file recovery checkpoint:
`/tmp/moy-P7-P8-P9-review-2026-10-24` (state.json and working-files.zip),
base5a5cd394. Do not extract over live work blindly. All inherited source/bake
remains local/uncommitted; this review publishes only review/workflow documents.
P11 planner was idle before review edits; its owned P11 documents are untouched.
No full new recovery archive was needed for this read-only review.

Reviewed hashes:

```json
{
  "scripts/moy_garden_builder.gd": "297130227c257c18dd1799bae70c785e17234120dc8e56ef3e74d1debab87939",
  "scripts/moy_park_builder.gd": "6efeb42f471e9656486e5e6b20ece2ceb2091a7516d6466a565732a30b9de71b",
  "scripts/moy_city_bake_builder.gd": "c919a85f2cd400c2ceaab81375c9cd1909b5559bdc989186b1e5821008df5c8c",
  "assets/generated/moy_garden_surfaces.json": "9cfcfb2ab16b60bc84ce7107d3108655333cecf747ec591392e30d610f04e916",
  "assets/generated/moy_city/manifest.json": "d8665950e0e0f79863a10b0cb8870e2a4fa94c87bdf43479d7dc7439a142fbe2"
}
```

Next entry: `moy_p10_build_handoff.md` and current `moy_pkg_P10.md`.
One new local Luna chat in this checkout; stop after coherent P10 for review.
No extra agents/chats, model changes to prior builders or P11 auto-start.
