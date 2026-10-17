# China Village: first construction finish pass

## Result

The gatehouse/bridge approach and pond garden have a substantially more resolved
construction kit. Shared fixes also reach palace halls, homes, terrace edges,
compound walls, island parapets, field banks and household yards. This is an
implemented and baked finish pass, not final art approval for the whole village.

The design brief is `docs/architecture/chinese_finish_pass.md`; the preceding
audit is `2026-10-16-china-visual-audit.md` in this directory. Authored settlement
positions and the route graph were preserved.

## Changes visible in Godot

- Roofs built by `chinese_architecture.gd` use a continuous flared section with
  shared seams, closed undersides and softly squared eave hems. The palace
  windows now share the actual wall aperture's profile, with fitted lattice,
  surrounds on both faces and reveal liners.
- The gatehouse has masonry corner piers, an embedded foot course, a weathering
  course, upper timber corners, a ridge cap and matching arch surrounds. Its
  four-metre public passage remains clear. Large masonry faces use restrained
  metre-scale coursing rather than separate brick instances.
- Terrace/platform edges have copings and full-height corner pieces. The high
  pavilion podium has a battered corner treatment, footing and weathering cap.
  Compound wall ends and island parapets are capped. Royal garden panels are
  vermilion on both faces over a pale dado with gold coping; domestic gardens
  retain grey brick and lime plaster.
- The pond crossing is a single rounded, joined footprint with a bevelled
  section, real supports and matching collision. Unequal shoreline groups
  replace the repeated stone necklace. Limestone and scholar stones have real
  cut-through apertures and silhouette notches. Lotus leaves are round.
- The real-water basin and shared swimming behavior remain. Pond material
  parameters give the existing water shader smaller ripples, clearer depth
  and a quieter green-blue surface. Other water retains the shader defaults.
- Palace paving uses herringbone, village brick uses grey running bond and
  garden paving uses lower-contrast pebble panels. Bridgehead paving has rounded
  corners and the flagstone material. Household earth yards and threshing/service
  earth courts join the island ground-paint atlas instead of using rectangles.
- Field bunds are continuous soil sections with flat walking tops, battered
  grass sides and ramped ends. An initial rounded-primitive version was rejected
  after rendering because it looked like stretched oval pads.
- Bridge deck edges are continuous sweeps. Corbel ends have finishing shoes.
  Chain guards use alternating open oval links in a shared MultiMesh; the
  simpler continuous guard collision remains behind those links.
- Seeded pines have continuous tapering leaders, unequal branch intervals,
  longer asymmetric reaches and thinner, varied SuperEgg canopy lobes.

## Validation

- China runtime passes after the final geometry changes: bridge aisle and
  support checks, ramps, mount clearance, doors, furniture support, region
  unload/reload, civic/party state and real-water/swimming checks.
- Added physical checks sample the pond crossing through every bend and cast
  through the limestone aperture. A decorative opening without an actual
  collision hole fails this check.
- China plan validation passes: 8 islands, 10 bridges, 54 placed items,
  38 openings and 65 paths. The bake signature and Three.js/runtime plan data
  match. The signature now includes the water shader.
- Ohio: 0 failures, 8 existing scheduling warnings. Snow: 0 failures, 5 existing
  scheduling warnings. Player-support probe: 0 failures. Those regressions ran
  after the shared tree, water and static-merge changes; subsequent changes were
  confined to the China builder/infrastructure.
- Body-pose ownership, power parity, design-language checks and whitespace
  validation pass. Power parity still reports the pre-existing FlightMode
  duplication notice. The headless tools emit the existing macOS certificate
  notice; plan/support probes also report two objects at shutdown.

The final 1600 × 1600 fixed-camera QA measurement on the local Apple M5 was
60 FPS in both three-second samples, 18 ms worst frame, 3,758 draw calls,
368 MiB static memory and 678 MiB GPU memory, with a 2.69-second scene build.
The crop-heavy field view measured 60.0 and 59.7 FPS, with a 21 ms worst frame,
4,127 draw calls, 371 MiB static memory and the same 678 MiB GPU allocation.
This remains playable at that viewpoint. The earlier readings in this pass and
its baseline undercounted content because of the headless instance-buffer bug;
they are not a valid complete-content performance comparison. The compressed
cache is about 60 MiB. Instancing the chain links avoided an intermediate
80 MiB cache. These are short, fixed-camera measurements under the frame cap,
not evidence of unlimited performance headroom.

The final visual check uncovered an existing bake defect: the headless renderer
serialized empty MultiMesh transforms while retaining instance counts. That
made crops/bamboo disappear, and initially affected the new chains. CPU-authored
transform buffers and bounds are now stored explicitly and restored at load.
The validator checks the saved buffers, and the rendered field/chain captures
confirm that the instances are visible. A count-only check was insufficient.

All Godot builds and captures used the isolated scratch project, with one Godot
process at a time. The current baked scene and source signature were copied
back to the repository. No web export, commit or push was performed.

## Review evidence and remaining work

Final captures are in `wip/diagnostics/2026-10-16-china-finish/`: gatehouse,
garden overview and eye level, palace, paving, chains, bridge underside,
service descent, earth lanes and the four-seed pine gallery. They were inspected
as rendered images; static geometry checks alone were not used for art approval.

The approved palace section deliberately separates the +5.6 m inner court from
the ground-level kitchen and deliveries. Keeping that separation is reasonable;
the descent's overall composition still merits a dedicated architectural review.
This pass finishes associated podium/edge details rather than changing levels.

The inn's detailed interior, remaining generic roof families, pavilion joinery,
finer garden composition, and village-wide material/lighting polish remain below
the desired final standard. In particular, the podium is less blank now but
still dominates the small garden. The current work establishes reusable details;
it does not certify every room or every building as finished.

The existing regional activation hitch and the need for district-level loading
before a Moy-sized city are unchanged by this art pass.
